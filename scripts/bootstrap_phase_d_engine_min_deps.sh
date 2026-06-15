#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENGINE_SRC_DIR="$ROOT_DIR/vendor/flutter/engine/src/flutter"
ENGINE_ROOT_DIR="$ROOT_DIR/vendor/flutter/engine/src"
FLUTTER_DEPS_FILE="$ROOT_DIR/vendor/flutter/DEPS"
ENGINE_DEPS_FILE="$ENGINE_SRC_DIR/DEPS"
DEPS_FILE="${FCB_ENGINE_DEPS_FILE:-}"
DEPOT_TOOLS_DIR="$ROOT_DIR/vendor/depot_tools"
DEPOT_HOME="${FCB_DEPOT_HOME:-$ROOT_DIR/target/fcb/depot-home}"
CIPD_CACHE_DIR="${FCB_CIPD_CACHE_DIR:-$DEPOT_HOME/cipd-cache}"

usage() {
  cat <<USAGE
Usage:
  $0

Bootstraps the minimum Engine dependencies needed for Phase D Android GN smoke
when full gclient sync is blocked by local Engine modifications:

  - third_party/skia from the pinned DEPS skia_revision
  - third_party/gn from the pinned CIPD package
  - third_party/ninja from the pinned CIPD package

The script refuses to overwrite a non-git skia directory and does not reset the
Engine source checkout.

By default it reads vendor/flutter/DEPS, which is the authoritative DEPS file
for the Flutter stable checkout. Set FCB_ENGINE_DEPS_FILE to override.
USAGE
}

die() {
  echo "error: $*" >&2
  exit 1
}

run() {
  echo "+ $*" >&2
  "$@"
}

deps_value() {
  local key="$1"
  python3 - "$DEPS_FILE" "$key" <<'PY'
import re
import sys
from pathlib import Path

text = Path(sys.argv[1]).read_text()
key = re.escape(sys.argv[2])
match = re.search(rf"'{key}'\s*:\s*'([^']+)'", text)
if not match:
    raise SystemExit(f"missing DEPS var: {sys.argv[2]}")
print(match.group(1))
PY
}

git_dep_revision() {
  local dep_path="$1"
  python3 - "$DEPS_FILE" "$dep_path" <<'PY'
import re
import sys
from pathlib import Path

text = Path(sys.argv[1]).read_text()
dep_path = re.escape(sys.argv[2])
vars_block = re.search(r"vars\s*=\s*\{(?P<block>.*?)\n\}", text, re.S)
vars = {}
if vars_block:
    for key, value in re.findall(r"'([^']+)'\s*:\s*'([^']+)'", vars_block.group("block")):
        vars[key] = value
block_match = re.search(rf"'{dep_path}'\s*:\s*(?P<block>.*?)(?:,\n\n|,\n\s*')", text, re.S)
if not block_match:
    raise SystemExit(f"missing DEPS git revision for {sys.argv[2]}")
block = block_match.group("block")
match = re.search(r"@\s*'\s*\+\s*'([^']+)'", block)
if not match:
    var_match = re.search(r"@\s*'\s*\+\s*Var\('([^']+)'\)", block)
    if var_match:
        var_name = var_match.group(1)
        if var_name not in vars:
            raise SystemExit(f"missing DEPS var: {var_name}")
        print(vars[var_name])
        raise SystemExit(0)
if not match:
    match = re.search(r"@\s*([^'\s]+)", block)
if not match:
    match = re.search(r"@([0-9a-fA-F]{20,40})", block)
if not match:
    raise SystemExit(f"missing git revision in DEPS block for {sys.argv[2]}")
print(match.group(1))
PY
}

git_dep_url() {
  local dep_path="$1"
  python3 - "$DEPS_FILE" "$dep_path" <<'PY'
import re
import sys
from pathlib import Path

text = Path(sys.argv[1]).read_text()
dep_path = re.escape(sys.argv[2])
vars_block = re.search(r"vars\s*=\s*\{(?P<block>.*?)\n\}", text, re.S)
vars = {}
if vars_block:
    for key, value in re.findall(r"'([^']+)'\s*:\s*'([^']+)'", vars_block.group("block")):
        vars[key] = value

block_match = re.search(rf"'{dep_path}'\s*:\s*(?P<block>.*?)(?:,\n\n|,\n\s*')", text, re.S)
if not block_match:
    raise SystemExit(f"missing DEPS git URL for {sys.argv[2]}")
block = " ".join(block_match.group("block").split())

match = re.search(r"Var\('([^']+)'\)\s*\+\s*'([^']+)'\s*\+\s*'@'", block)
if match:
    var_name, suffix = match.groups()
    if var_name not in vars:
        raise SystemExit(f"missing DEPS var: {var_name}")
    print(vars[var_name] + suffix)
    raise SystemExit(0)

match = re.search(r"Var\('([^']+)'\)\s*\+\s*'([^'@]+)@[^']+'", block)
if match:
    var_name, suffix = match.groups()
    if var_name not in vars:
        raise SystemExit(f"missing DEPS var: {var_name}")
    print(vars[var_name] + suffix)
    raise SystemExit(0)

match = re.search(r"'(https?://[^']+)'\s*\+\s*'@'", block)
if match:
    print(match.group(1))
    raise SystemExit(0)

raise SystemExit(f"unsupported DEPS git URL expression for {sys.argv[2]}")
PY
}

cipd_dep() {
  local field="$1"
  shift
  python3 - "$DEPS_FILE" "$field" "$@" <<'PY'
import re
import sys
from pathlib import Path

text = Path(sys.argv[1]).read_text()
field = re.escape(sys.argv[2])
block = None
vars_block = re.search(r"vars\s*=\s*\{(?P<block>.*?)\n\}", text, re.S)
vars = {}
if vars_block:
    for key, value in re.findall(r"'([^']+)'\s*:\s*'([^']+)'", vars_block.group("block")):
        vars[key] = value

def dep_block_for(path):
    marker = f"'{path}'"
    start = text.find(marker)
    if start == -1:
        return None
    colon = text.find(":", start + len(marker))
    if colon == -1:
        return None
    brace = text.find("{", colon)
    if brace == -1:
        return None
    depth = 0
    quote = None
    escape = False
    for index in range(brace, len(text)):
        char = text[index]
        if quote:
            if escape:
                escape = False
            elif char == "\\":
                escape = True
            elif char == quote:
                quote = None
            continue
        if char in ("'", '"'):
            quote = char
        elif char == "{":
            depth += 1
        elif char == "}":
            depth -= 1
            if depth == 0:
                return text[brace + 1:index]
    return None

for dep_path_arg in sys.argv[3:]:
    block = dep_block_for(dep_path_arg)
    if block is not None:
        break
if block is None:
    raise SystemExit(f"missing DEPS cipd block; tried: {', '.join(sys.argv[3:])}")

concat_var_match = re.search(rf"'{field}'\s*:\s*'([^']*)'\s*\+\s*Var\('([^']+)'\)", block)
if concat_var_match:
    prefix, var_name = concat_var_match.groups()
    if var_name not in vars:
        raise SystemExit(f"missing DEPS var: {var_name}")
    print(prefix + vars[var_name])
    raise SystemExit(0)

match = re.search(rf"'{field}'\s*:\s*'([^']+)'", block)
if not match:
    var_match = re.search(rf"'{field}'\s*:\s*Var\('([^']+)'\)", block)
    if var_match:
        var_name = var_match.group(1)
        if var_name not in vars:
            raise SystemExit(f"missing DEPS var: {var_name}")
        print(vars[var_name])
        raise SystemExit(0)
if not match:
    raise SystemExit(f"missing field {sys.argv[2]} in selected DEPS block")
print(match.group(1))
PY
}

cipd_ensure_one() {
  local root="$1"
  local package="$2"
  local version="$3"
  mkdir -p "$root" "$CIPD_CACHE_DIR"
  printf '%s %s\n' "$package" "$version" |
    PATH="$DEPOT_TOOLS_DIR:$PATH" \
    HOME="$DEPOT_HOME" \
    CIPD_CACHE_DIR="$CIPD_CACHE_DIR" \
    run "$DEPOT_TOOLS_DIR/cipd" ensure -root "$root" -ensure-file -
}

bootstrap_skia() {
  local skia_dir="$ENGINE_SRC_DIR/third_party/skia"
  local skia_revision
  skia_revision="$(deps_value skia_revision)"

  if [ -d "$skia_dir/.git" ]; then
    run git -C "$skia_dir" fetch origin "$skia_revision" --depth 1
    run git -C "$skia_dir" checkout --detach "$skia_revision"
    return 0
  fi

  if [ -e "$skia_dir" ]; then
    die "refusing to overwrite non-git skia directory: $skia_dir"
  fi

  run git clone --no-checkout --filter=blob:none https://skia.googlesource.com/skia.git "$skia_dir"
  run git -C "$skia_dir" fetch origin "$skia_revision" --depth 1
  run git -C "$skia_dir" checkout --detach "$skia_revision"
}

bootstrap_git_dep() {
  local dep_path="$1"
  local url="$2"
  local checkout_dir="$3"
  local revision
  revision="$(git_dep_revision "$dep_path")"

  if [ -d "$checkout_dir/.git" ]; then
    run git -C "$checkout_dir" fetch origin "$revision" --depth 1
    run git -C "$checkout_dir" checkout --detach "$revision"
  elif [ -e "$checkout_dir" ]; then
    die "refusing to overwrite non-git dependency directory: $checkout_dir"
  else
    run git clone --no-checkout --filter=blob:none "$url" "$checkout_dir"
    run git -C "$checkout_dir" fetch origin "$revision" --depth 1
    run git -C "$checkout_dir" checkout --detach "$revision"
  fi
}

checkout_dir_for_dep() {
  local dep_path="$1"
  case "$dep_path" in
    engine/src/flutter/*)
      echo "$ENGINE_SRC_DIR/${dep_path#engine/src/flutter/}"
      ;;
    engine/src/*)
      echo "$ENGINE_ROOT_DIR/${dep_path#engine/src/}"
      ;;
    *)
      die "unsupported dependency path for minimal bootstrap: $dep_path"
      ;;
  esac
}

bootstrap_git_dep_path() {
  local dep_path="$1"
  local url checkout_dir
  url="$(git_dep_url "$dep_path")"
  checkout_dir="$(checkout_dir_for_dep "$dep_path")"
  bootstrap_git_dep "$dep_path" "$url" "$checkout_dir"
}

bootstrap_vulkan_deps() {
  local vulkan_dir="$ENGINE_SRC_DIR/third_party/vulkan-deps"
  bootstrap_git_dep \
    "engine/src/flutter/third_party/vulkan-deps" \
    "https://chromium.googlesource.com/vulkan-deps" \
    "$vulkan_dir"
  run git -C "$vulkan_dir" submodule update --init --recursive --depth 1
}

bootstrap_android_gn_core_deps() {
  local deps=(
    engine/src/flutter/third_party/boringssl/src
    engine/src/flutter/third_party/dart/third_party/binaryen/src
    engine/src/flutter/third_party/dart/third_party/pkg/ai
    engine/src/flutter/third_party/dart/third_party/pkg/core
    engine/src/flutter/third_party/dart/third_party/pkg/dart_style
    engine/src/flutter/third_party/dart/third_party/pkg/dartdoc
    engine/src/flutter/third_party/dart/third_party/pkg/ecosystem
    engine/src/flutter/third_party/dart/third_party/pkg/http
    engine/src/flutter/third_party/dart/third_party/pkg/i18n
    engine/src/flutter/third_party/dart/third_party/pkg/leak_tracker
    engine/src/flutter/third_party/dart/third_party/pkg/native
    engine/src/flutter/third_party/dart/third_party/pkg/protobuf
    engine/src/flutter/third_party/dart/third_party/pkg/pub
    engine/src/flutter/third_party/dart/third_party/pkg/shelf
    engine/src/flutter/third_party/dart/third_party/pkg/sync_http
    engine/src/flutter/third_party/dart/third_party/pkg/tar
    engine/src/flutter/third_party/dart/third_party/pkg/test
    engine/src/flutter/third_party/dart/third_party/pkg/tools
    engine/src/flutter/third_party/dart/third_party/pkg/vector_math
    engine/src/flutter/third_party/dart/third_party/pkg/web
    engine/src/flutter/third_party/dart/third_party/pkg/webdev
    engine/src/flutter/third_party/dart/third_party/pkg/webdriver
    engine/src/flutter/third_party/dart/third_party/pkg/webkit_inspection_protocol
    engine/src/flutter/third_party/dart/third_party/perfetto/src
    engine/src/flutter/third_party/inja
    engine/src/flutter/third_party/json
    engine/src/flutter/third_party/shaderc
    engine/src/flutter/third_party/harfbuzz
    engine/src/flutter/third_party/libcxx
    engine/src/flutter/third_party/libcxxabi
    engine/src/flutter/third_party/llvm_libc
    engine/src/flutter/third_party/flatbuffers
    engine/src/flutter/third_party/icu
    engine/src/flutter/third_party/benchmark
    engine/src/flutter/third_party/googletest
    engine/src/flutter/third_party/expat
    engine/src/flutter/third_party/freetype2
    engine/src/flutter/third_party/libjpeg-turbo/src
    engine/src/flutter/third_party/libpng
    engine/src/flutter/third_party/libwebp
    engine/src/flutter/third_party/wuffs
    engine/src/flutter/third_party/zlib
    engine/src/flutter/third_party/cpu_features/src
    engine/src/flutter/third_party/swiftshader
    engine/src/flutter/third_party/angle
    engine/src/flutter/third_party/vulkan_memory_allocator
    engine/src/third_party/abseil-cpp
  )

  local dep_path
  for dep_path in "${deps[@]}"; do
    bootstrap_git_dep_path "$dep_path"
  done
}

bootstrap_cipd_tool() {
  local root="$1"
  shift
  local package version
  package="$(cipd_dep package "$@")"
  package="${package//\$\{\{platform\}\}/\$\{platform\}}"
  version="$(cipd_dep version "$@")"
  cipd_ensure_one "$root" "$package" "$version"
}

main() {
  if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
    usage
    exit 0
  fi

  if [ -z "$DEPS_FILE" ]; then
    if [ -f "$FLUTTER_DEPS_FILE" ]; then
      DEPS_FILE="$FLUTTER_DEPS_FILE"
    else
      DEPS_FILE="$ENGINE_DEPS_FILE"
    fi
  fi

  [ -f "$DEPS_FILE" ] || die "missing DEPS file: $DEPS_FILE"
  [ -x "$DEPOT_TOOLS_DIR/cipd" ] || die "missing executable: $DEPOT_TOOLS_DIR/cipd"

  echo "using DEPS: $DEPS_FILE"
  bootstrap_skia
  bootstrap_vulkan_deps
  bootstrap_android_gn_core_deps
  bootstrap_cipd_tool \
    "$ENGINE_SRC_DIR/third_party/gn" \
    "engine/src/flutter/third_party/gn" \
    "src/flutter/third_party/gn"
  bootstrap_cipd_tool \
    "$ENGINE_SRC_DIR/third_party/ninja" \
    "engine/src/flutter/third_party/ninja" \
    "src/flutter/third_party/ninja" \
    "third_party/ninja"
  bootstrap_cipd_tool \
    "$ENGINE_SRC_DIR/buildtools/linux-x64/clang" \
    "engine/src/flutter/buildtools/linux-x64/clang"
  bootstrap_cipd_tool \
    "$ENGINE_SRC_DIR/third_party/android_tools" \
    "engine/src/flutter/third_party/android_tools"
  bootstrap_cipd_tool \
    "$ENGINE_SRC_DIR/third_party/android_embedding_dependencies" \
    "engine/src/flutter/third_party/android_embedding_dependencies"
  bootstrap_cipd_tool \
    "$ENGINE_SRC_DIR/third_party/java/openjdk" \
    "engine/src/flutter/third_party/java/openjdk"
  bootstrap_cipd_tool \
    "$ENGINE_SRC_DIR/third_party/dart/tools/sdks/dart-sdk" \
    "engine/src/flutter/third_party/dart/tools/sdks/dart-sdk"
  bootstrap_cipd_tool \
    "$ENGINE_SRC_DIR/third_party/dart/third_party/devtools" \
    "engine/src/flutter/third_party/dart/third_party/devtools"
  bootstrap_cipd_tool \
    "$ENGINE_SRC_DIR/prebuilts/linux-x64/dart-sdk" \
    "engine/src/flutter/prebuilts/linux-x64/dart-sdk"

  [ -d "$ENGINE_SRC_DIR/third_party/skia" ] || die "skia bootstrap failed"
  [ -f "$ENGINE_SRC_DIR/third_party/vulkan-deps/vulkan-headers/src/BUILD.gn" ] ||
    die "vulkan-deps bootstrap failed"
  [ -x "$ENGINE_SRC_DIR/third_party/gn/gn" ] || die "gn bootstrap failed"
  [ -x "$ENGINE_SRC_DIR/third_party/ninja/ninja" ] || die "ninja bootstrap failed"
  [ -f "$ENGINE_SRC_DIR/third_party/android_embedding_dependencies/lib/activity-1.8.1.jar" ] ||
    die "android embedding dependencies bootstrap failed"
  [ -x "$ENGINE_SRC_DIR/third_party/java/openjdk/bin/javac" ] ||
    die "openjdk bootstrap failed"
  [ -x "$ENGINE_SRC_DIR/third_party/dart/tools/sdks/dart-sdk/bin/dart" ] ||
    die "dart bootstrap SDK failed"
  [ -f "$ENGINE_SRC_DIR/third_party/dart/third_party/devtools/devtools_shared/pubspec.yaml" ] ||
    die "dart devtools bootstrap failed"
  [ -x "$ENGINE_SRC_DIR/prebuilts/linux-x64/dart-sdk/bin/dart" ] ||
    die "flutter prebuilt Dart SDK failed"

  echo "Phase D minimum Engine dependencies are present:"
  echo "  $ENGINE_SRC_DIR/third_party/skia"
  echo "  $ENGINE_SRC_DIR/third_party/vulkan-deps"
  echo "  $ENGINE_SRC_DIR/third_party/gn/gn"
  echo "  $ENGINE_SRC_DIR/third_party/ninja/ninja"
  echo "  $ENGINE_SRC_DIR/third_party/android_embedding_dependencies"
  echo "  $ENGINE_SRC_DIR/third_party/java/openjdk"
  echo "  $ENGINE_SRC_DIR/third_party/dart/tools/sdks/dart-sdk"
  echo "  $ENGINE_SRC_DIR/third_party/dart/third_party/devtools"
  echo "  $ENGINE_SRC_DIR/prebuilts/linux-x64/dart-sdk"
}

main "$@"
