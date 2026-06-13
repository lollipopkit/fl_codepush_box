#!/usr/bin/env bash
# Dry-run the full Phase B Android device script with fake tools.
#
# This validates script orchestration and arguments without requiring Flutter,
# adb, a local Engine build, or an Android device. It does not prove that the
# Engine loads a patched libapp.so; tests/e2e/test_phase_b_android.sh must still
# run on a real device or emulator for final Phase B acceptance.

set -euo pipefail

REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
WORKDIR=$(mktemp -d /tmp/fcb_phase_b_android_dry_run_XXXXXX)
BIN="$WORKDIR/bin"
LOG="$WORKDIR/commands.log"
ADB_STATE="$WORKDIR/adb_state"
ENGINE_SRC="$WORKDIR/engine/src"
UPDATER_JNILIB="$WORKDIR/libfcb_updater.so"
DRY_RUN_ABI="${ABI:-arm64-v8a}"
DRY_RUN_TARGET_PLATFORM="${TARGET_PLATFORM:-android-arm64}"
DRY_RUN_SERVER_ADDR="${SERVER_ADDR:-127.0.0.1:18197}"
DRY_RUN_SERVER_PORT="${DRY_RUN_SERVER_ADDR##*:}"
DRY_RUN_LOCAL_ENGINE_HOST="${LOCAL_ENGINE_HOST:-host_release}"
case "$DRY_RUN_ABI" in
  arm64-v8a) DRY_RUN_LOCAL_ENGINE="${LOCAL_ENGINE:-android_release_arm64}" ;;
  armeabi-v7a) DRY_RUN_LOCAL_ENGINE="${LOCAL_ENGINE:-android_release_arm}" ;;
  x86_64) DRY_RUN_LOCAL_ENGINE="${LOCAL_ENGINE:-android_release_x64}" ;;
  x86) DRY_RUN_LOCAL_ENGINE="${LOCAL_ENGINE:-android_release_x86}" ;;
  *) DRY_RUN_LOCAL_ENGINE="${LOCAL_ENGINE:-android_release_arm64}" ;;
esac

cleanup() {
    rm -rf "$WORKDIR"
}
trap cleanup EXIT INT TERM

mkdir -p "$BIN" "$ENGINE_SRC/shell/platform/android/fcb" \
    "$ENGINE_SRC/shell/platform/android/shell" \
    "$ENGINE_SRC/out/$DRY_RUN_LOCAL_ENGINE" \
    "$ENGINE_SRC/out/$DRY_RUN_LOCAL_ENGINE_HOST"
cp "$REPO_ROOT/engine_patch/android/fcb_engine_hook.cc" \
    "$ENGINE_SRC/shell/platform/android/fcb/fcb_engine_hook.cc"
cat > "$ENGINE_SRC/shell/platform/android/fcb/BUILD.gn" <<'GN'
source_set("fcb_engine_hook") {
  sources = [ "fcb_engine_hook.cc" ]
}
GN
cat > "$ENGINE_SRC/shell/platform/android/shell/fcb_integration.cc" <<'CC'
void FcbIntegration() {
  fcb_apply_android_snapshot_replace_with_config(nullptr, nullptr);
}
CC
cat > "$ENGINE_SRC/shell/platform/android/shell/BUILD.gn" <<'GN'
source_set("android_shell") {
  deps = [ "//shell/platform/android/fcb:fcb_engine_hook" ]
}
GN
printf '\177ELFfake updater so\n' > "$UPDATER_JNILIB"

cat > "$BIN/fcb_server" <<'PY'
#!/usr/bin/env python3
from http.server import BaseHTTPRequestHandler, HTTPServer
import os

host, port = os.environ["FCB_SERVER_ADDR"].rsplit(":", 1)

class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.end_headers()
        self.wfile.write(b"{}")

    def do_POST(self):
        length = int(self.headers.get("Content-Length", "0"))
        if length:
            self.rfile.read(length)
        self.send_response(200)
        self.end_headers()
        self.wfile.write(b'{"status":"ok"}')

    def log_message(self, fmt, *args):
        return

HTTPServer((host, int(port)), Handler).serve_forever()
PY

cat > "$BIN/fcb" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
printf 'fcb %s\n' "$*" >> "$FCB_DRY_RUN_LOG"

args=("$@")
if [ "${args[0]:-}" = "--server" ]; then
    args=("${args[@]:2}")
fi

case "${args[0]:-}" in
  init)
    mkdir -p .fcb/keys
    printf 'app_id: "00000000-0000-0000-0000-000000000001"\nchannel: "stable"\n' > fcb.yaml
    printf 'dry-run-public-key\n' > .fcb/keys/dev-ed25519.public
    ;;
  release|patch|promote)
    ;;
  *)
    echo "unexpected fcb command: ${args[*]}" >&2
    exit 1
    ;;
esac
SH

cat > "$BIN/flutter" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
printf 'flutter %s\n' "$*" >> "$FCB_DRY_RUN_LOG"

if [ "$1" = "create" ]; then
    appdir="${@: -1}"
    mkdir -p "$appdir/lib" "$appdir/android/app/src/main"
    cat > "$appdir/android/app/src/main/AndroidManifest.xml" <<'XML'
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
  <application android:label="dry_run" />
</manifest>
XML
    exit 0
fi

if [ "$1" = "pub" ] && [ "${2:-}" = "get" ]; then
    exit 0
fi

if [ "$1" = "clean" ]; then
    rm -rf build
    exit 0
fi

if [ "$1" = "devices" ]; then
    printf 'Android SDK built for dry run • emulator-5558 • %s • Android 16\n' "${FCB_DRY_RUN_TARGET_PLATFORM:-android-arm64}"
    exit 0
fi

if [ "$1" = "build" ] && [ "${2:-}" = "apk" ]; then
    counter=""
    abi=""
    previous=""
    for arg in "$@"; do
        if [ "$previous" = "--dart-define" ]; then
            case "$arg" in
              FCB_INITIAL_COUNTER=*) counter="${arg#FCB_INITIAL_COUNTER=}" ;;
              FCB_ARCH=*) abi="${arg#FCB_ARCH=}" ;;
            esac
        fi
        previous="$arg"
    done
    : "${counter:?missing FCB_INITIAL_COUNTER}"
    : "${abi:?missing FCB_ARCH}"
    mkdir -p "build/app/intermediates/stripped_native_libs/release/out/lib/$abi" \
        "build/app/outputs/flutter-apk"
    printf 'libapp counter %s\n' "$counter" \
        > "build/app/intermediates/stripped_native_libs/release/out/lib/$abi/libapp.so"
    python3 - "$abi" "$counter" <<'PY'
import sys
import zipfile
from pathlib import Path

abi, counter = sys.argv[1], sys.argv[2]
apk = Path("build/app/outputs/flutter-apk/app-release.apk")
with zipfile.ZipFile(apk, "w") as zf:
    zf.writestr(f"lib/{abi}/libapp.so", f"libapp counter {counter}\n")
    zf.writestr(f"lib/{abi}/libfcb_updater.so", "fake updater\n")
PY
    exit 0
fi

echo "unexpected flutter command: $*" >&2
exit 1
SH

cat > "$BIN/adb" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
printf 'adb %s\n' "$*" >> "$FCB_DRY_RUN_LOG"

case "${1:-}" in
  get-state)
    echo device
    ;;
  reverse|install|uninstall)
    ;;
  logcat)
    ;;
  shell)
    shift
    case "${1:-}" in
      am)
        if [ "${2:-}" = "start" ]; then
            count=0
            if [ -f "$FCB_DRY_RUN_ADB_STATE" ]; then
                count=$(cat "$FCB_DRY_RUN_ADB_STATE")
            fi
            count=$((count + 1))
            printf '%s\n' "$count" > "$FCB_DRY_RUN_ADB_STATE"
        fi
        ;;
      uiautomator)
        ;;
      getprop)
        case "${2:-}" in
          ro.build.version.release) echo "16" ;;
          ro.build.version.sdk) echo "36" ;;
          ro.product.cpu.abi) echo "${FCB_DRY_RUN_ABI:-arm64-v8a}" ;;
        esac
        ;;
      pm)
        if [ "${2:-}" = "path" ]; then
            printf 'package:/data/app/%s/base.apk\n' "${3:-unknown}"
        fi
        ;;
      pidof)
        count=0
        if [ -f "$FCB_DRY_RUN_ADB_STATE" ]; then
            count=$(cat "$FCB_DRY_RUN_ADB_STATE")
        fi
        if [ "$count" = "5" ]; then
            exit 1
        fi
        echo 12345
        ;;
      cat)
        count=0
        if [ -f "$FCB_DRY_RUN_ADB_STATE" ]; then
            count=$(cat "$FCB_DRY_RUN_ADB_STATE")
        fi
        case "$count" in
          1) text='Counter: 1' ;;
          2|4) text='installed' ;;
          *) text='Counter: 2' ;;
        esac
        printf 'ui %s %s\n' "$count" "$text" >> "$FCB_DRY_RUN_LOG"
        printf '<hierarchy><node text="%s"/></hierarchy>\n' "$text"
        ;;
      *)
        ;;
    esac
    ;;
  *)
    echo "unexpected adb command: $*" >&2
    exit 1
    ;;
esac
SH

chmod +x "$BIN/fcb_server" "$BIN/fcb" "$BIN/flutter" "$BIN/adb"

echo "=== Dry-running full Phase B Android script ==="
PATH="$BIN:$PATH" \
FCB_BIN="$BIN/fcb" \
SERVER_BIN="$BIN/fcb_server" \
FLUTTER_BIN="$BIN/flutter" \
ADB_BIN="$BIN/adb" \
FCB_DRY_RUN_LOG="$LOG" \
FCB_DRY_RUN_ADB_STATE="$ADB_STATE" \
FCB_UPDATER_JNILIB="$UPDATER_JNILIB" \
FCB_PHASE_B_ANDROID_DRY_RUN=1 \
FCB_DRY_RUN_ABI="$DRY_RUN_ABI" \
FCB_DRY_RUN_TARGET_PLATFORM="$DRY_RUN_TARGET_PLATFORM" \
PHASE_B_EVIDENCE_DIR="$WORKDIR/evidence" \
ABI="$DRY_RUN_ABI" \
TARGET_PLATFORM="$DRY_RUN_TARGET_PLATFORM" \
SERVER_ADDR="$DRY_RUN_SERVER_ADDR" \
FLUTTER_BUILD_EXTRA_ARGS="--local-engine-src-path $ENGINE_SRC --local-engine $DRY_RUN_LOCAL_ENGINE --local-engine-host $DRY_RUN_LOCAL_ENGINE_HOST" \
"$REPO_ROOT/tests/e2e/test_phase_b_android.sh"

echo "=== Verifying dry-run command flow ==="
assert_log() {
    local pattern="$1"
    if ! grep -Eq -- "$pattern" "$LOG"; then
        echo "FAIL: command log missing pattern: $pattern" >&2
        cat "$LOG" >&2
        exit 1
    fi
}

assert_log "adb reverse tcp:${DRY_RUN_SERVER_PORT} tcp:${DRY_RUN_SERVER_PORT}"
assert_log 'adb logcat -c'
assert_log 'flutter create --platforms=android --project-name fcb_phase_b_counter'
assert_log 'flutter build apk'
assert_log "--target-platform ${DRY_RUN_TARGET_PLATFORM}"
assert_log "FCB_ARCH=${DRY_RUN_ABI}"
assert_log "--local-engine ${DRY_RUN_LOCAL_ENGINE}"
assert_log "--local-engine-host ${DRY_RUN_LOCAL_ENGINE_HOST}"
assert_log "fcb .*release android .*--arch ${DRY_RUN_ABI}"
assert_log "fcb .*patch android .*--patch-number 1 .*--arch ${DRY_RUN_ABI}"
assert_log "fcb .*patch android .*--patch-number 2 .*--arch ${DRY_RUN_ABI}"
assert_log "fcb .*promote .*--arch ${DRY_RUN_ABI} .*--rollout-percentage 100"
assert_log 'adb uninstall com.example.fcb_phase_b_counter'
assert_log 'adb install -r'
assert_log 'adb shell pidof com.example.fcb_phase_b_counter'
assert_log 'ui 1 Counter: 1'
assert_log 'ui 2 installed'
assert_log 'ui 3 Counter: 2'
assert_log 'ui 4 installed'
assert_log 'ui 6 Counter: 2'
assert_log 'ui 7 Counter: 2'

EVIDENCE_FILE=$(find "$WORKDIR/evidence" -type f -name 'phase_b_android_*.json' | head -n 1)
if [ -z "$EVIDENCE_FILE" ]; then
    echo "FAIL: Phase B evidence file was not written" >&2
    exit 1
fi
python3 - "$EVIDENCE_FILE" "$DRY_RUN_ABI" "$DRY_RUN_TARGET_PLATFORM" <<'PY'
import json
import sys

path, abi, target_platform = sys.argv[1:4]
data = json.load(open(path, encoding="utf-8"))
assert data["passed"] is True
assert data["dry_run"] is True
assert data["abi"] == abi
assert data["target_platform"] == target_platform
assert data["device"]["adb_state"] == "device"
assert data["device"]["android_release"] == "16"
assert data["device"]["android_api"] == "36"
assert data["device"]["android_abi"] == abi
assert data["local_engine"]["src_path"]
assert data["local_engine"]["target"]
assert data["local_engine"]["host"]
assert data["artifacts"]["base_libapp_sha256"] != data["artifacts"]["patch_libapp_sha256"]
assert "restart loaded patched AOT artifact and displayed Counter: 2" in data["validations"]
assert "server stopped and local active patch still displayed Counter: 2" in data["validations"]
PY
FCB_ALLOW_DRY_RUN_EVIDENCE=1 \
    "$REPO_ROOT/tests/e2e/verify_phase_b_evidence.sh" "$EVIDENCE_FILE" >/dev/null
if "$REPO_ROOT/tests/e2e/verify_phase_b_evidence.sh" "$EVIDENCE_FILE" \
    >/tmp/fcb_verify_dry_run_evidence.log 2>&1; then
    echo "FAIL: verifier accepted dry-run evidence without opt-in" >&2
    exit 1
fi
grep -q 'dry-run evidence is not valid Phase B completion evidence' \
    /tmp/fcb_verify_dry_run_evidence.log

echo "=== Phase B Android dry-run passed ==="
