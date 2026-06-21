#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENGINE_SRC_DIR="$ROOT_DIR/vendor/flutter/engine/src/flutter"
DEPOT_TOOLS_DIR="$ROOT_DIR/vendor/depot_tools"
OUT_DIR="${FCB_DESKTOP_EMBEDDER_TEST_DIR:-$ROOT_DIR/target/fcb/desktop-embedder-bridge}"
TARGET_DIR="${FCB_DESKTOP_EMBEDDER_TARGET_DIR:-host_release_fcb_embedder_arm64}"
STATICLIB="${FCB_UPDATER_STATICLIB:-$ROOT_DIR/target/release/libfcb_updater.a}"
VPYTHON_ROOT="${FCB_VPYTHON_ROOT:-$ROOT_DIR/target/fcb/vpython-root}"

usage() {
  cat <<USAGE
Usage:
  $0

Generates a host desktop Engine GN out dir with FCB embedder code-push enabled,
then compiles the key bridge translation units from compile_commands.json:

  - shell/platform/embedder/fcb/fcb_embedder_vm_patch_bridge.cc
  - shell/platform/android/fcb/fcb_engine_hook.cc
  - shell/platform/embedder/embedder.cc

This is intentionally narrower than the full embedder target so it can validate
the bridge wiring even when a host lacks optional SDK components such as the
macOS Metal Toolchain.

Environment:
  FCB_UPDATER_STATICLIB               Static libfcb_updater archive.
                                      Default: target/release/libfcb_updater.a
  FCB_DESKTOP_EMBEDDER_TARGET_DIR     Engine out target dir name.
                                      Default: host_release_fcb_embedder_arm64
  FCB_DESKTOP_EMBEDDER_TEST_DIR       Evidence output dir.
                                      Default: target/fcb/desktop-embedder-bridge
  FCB_VPYTHON_ROOT                    vpython virtualenv root.
                                      Default: target/fcb/vpython-root
USAGE
}

die() {
  echo "error: $*" >&2
  exit 1
}

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
  usage
  exit 0
fi

[ -x "$ROOT_DIR/scripts/bootstrap.sh" ] || die "missing scripts/bootstrap.sh"
[ -x "$ENGINE_SRC_DIR/tools/gn" ] || die "missing Engine GN wrapper: $ENGINE_SRC_DIR/tools/gn"
[ -x "$ENGINE_SRC_DIR/third_party/gn/gn" ] || die "missing Engine GN binary"
[ -d "$DEPOT_TOOLS_DIR" ] || die "missing depot_tools checkout: $DEPOT_TOOLS_DIR"
[ -f "$STATICLIB" ] || die "missing updater staticlib: $STATICLIB (run scripts/build_desktop_updater.sh)"
command -v python3 >/dev/null 2>&1 || die "missing python3"

case "$(uname -s)" in
  Darwin)
    TARGET_ARGS=(--mac --mac-cpu arm64)
    ;;
  Linux)
    TARGET_ARGS=(--linux --linux-cpu "$(uname -m | sed 's/aarch64/arm64/; s/x86_64/x64/')")
    ;;
  *)
    die "unsupported host for this validation script: $(uname -s)"
    ;;
esac

mkdir -p "$OUT_DIR"
GN_LOG="$OUT_DIR/gn.log"
COMPILE_LOG="$OUT_DIR/compile-key-units.log"
SUMMARY="$OUT_DIR/summary.txt"
ENGINE_OUT_DIR="$ROOT_DIR/vendor/flutter/engine/src/out/$TARGET_DIR"

"$ROOT_DIR/scripts/bootstrap.sh" --check >"$OUT_DIR/bootstrap-check.log" 2>&1

PATH="$DEPOT_TOOLS_DIR:$PATH" \
VPYTHON_VIRTUALENV_ROOT="$VPYTHON_ROOT" \
"$ENGINE_SRC_DIR/tools/gn" \
  --runtime-mode release \
  "${TARGET_ARGS[@]}" \
  --target-dir "$TARGET_DIR" \
  --gn-args "fcb_enable_code_push=true" \
  --gn-args "fcb_updater_staticlib=\"$STATICLIB\"" \
  >"$GN_LOG" 2>&1 || {
    cat "$GN_LOG" >&2
    die "GN generation failed; log: $GN_LOG"
  }

COMPILE_COMMANDS="$ENGINE_OUT_DIR/compile_commands.json"
[ -f "$COMPILE_COMMANDS" ] || die "missing compile_commands.json: $COMPILE_COMMANDS"

python3 - "$COMPILE_COMMANDS" "$ENGINE_OUT_DIR" >"$COMPILE_LOG" 2>&1 <<'PY' || {
import json
import os
import shlex
import subprocess
import sys

compile_commands_path, cwd = sys.argv[1], sys.argv[2]
with open(compile_commands_path, encoding="utf-8") as f:
    commands = json.load(f)

targets = [
    (
        "../../flutter/shell/platform/embedder/fcb/fcb_embedder_vm_patch_bridge.cc",
        "obj/flutter/shell/platform/embedder/fcb/embedder.fcb_embedder_vm_patch_bridge.o",
    ),
    (
        "../../flutter/shell/platform/android/fcb/fcb_engine_hook.cc",
        "obj/flutter/shell/platform/android/fcb/embedder.fcb_engine_hook.o",
    ),
    (
        "../../flutter/shell/platform/embedder/embedder.cc",
        "obj/flutter/shell/platform/embedder/embedder.embedder.o",
    ),
]

def find_command(source, output_marker):
    matches = [
        entry["command"]
        for entry in commands
        if entry.get("file") == source and output_marker in entry.get("command", "")
    ]
    if len(matches) != 1:
        raise SystemExit(
            f"expected one compile command for {source} -> {output_marker}, found {len(matches)}"
        )
    return matches[0]

def output_path(command):
    parts = shlex.split(command)
    if "-o" not in parts:
        raise SystemExit(f"compile command has no -o output: {command}")
    index = parts.index("-o")
    if index + 1 >= len(parts):
        raise SystemExit(f"compile command has empty -o output: {command}")
    return parts[index + 1]

for source, marker in targets:
    command = find_command(source, marker)
    out = output_path(command)
    os.makedirs(os.path.dirname(os.path.join(cwd, out)), exist_ok=True)
    print(f"+ compile {source}")
    subprocess.run(command, cwd=cwd, shell=True, check=True)

print("desktop embedder bridge key compile units passed")
PY
  cat "$COMPILE_LOG" >&2
  die "key compile unit validation failed; log: $COMPILE_LOG"
}

cat >"$SUMMARY" <<EOF
FCB desktop embedder bridge validation passed
engine_src_dir: $ENGINE_SRC_DIR
engine_out_dir: $ENGINE_OUT_DIR
target_dir: $TARGET_DIR
updater_staticlib: $STATICLIB
gn_log: $GN_LOG
compile_log: $COMPILE_LOG
compiled_units:
- shell/platform/embedder/fcb/fcb_embedder_vm_patch_bridge.cc
- shell/platform/android/fcb/fcb_engine_hook.cc
- shell/platform/embedder/embedder.cc
EOF

cat "$SUMMARY"
