#!/usr/bin/env bash
# Unit-style checks for Phase B Android preflight logic.

set -euo pipefail

REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
WORKDIR=$(mktemp -d /tmp/fcb_phase_b_preflight_test_XXXXXX)
ORIGINAL_JNILIB="$REPO_ROOT/packages/fcb_code_push/android/src/main/jniLibs/arm64-v8a/libfcb_updater.so"
BACKUP_JNILIB=""

cleanup() {
    if [ -n "$BACKUP_JNILIB" ] && [ -f "$BACKUP_JNILIB" ]; then
        mkdir -p "$(dirname "$ORIGINAL_JNILIB")"
        mv "$BACKUP_JNILIB" "$ORIGINAL_JNILIB"
    else
        rm -f "$ORIGINAL_JNILIB"
    fi
    rm -rf "$WORKDIR"
}
trap cleanup EXIT INT TERM

if [ -f "$ORIGINAL_JNILIB" ]; then
    BACKUP_JNILIB="$WORKDIR/libfcb_updater.so.backup"
    mv "$ORIGINAL_JNILIB" "$BACKUP_JNILIB"
fi

mkdir -p "$WORKDIR/bin"
cat > "$WORKDIR/bin/flutter" <<'SH'
#!/usr/bin/env sh
exit 0
SH
cat > "$WORKDIR/bin/adb" <<'SH'
#!/usr/bin/env sh
if [ "$1" = "get-state" ]; then
  if [ "${FCB_FAKE_ADB_FAIL:-0}" = "1" ]; then
    echo "no devices/emulators found" >&2
    exit 1
  fi
  echo device
fi
if [ "$1" = "devices" ]; then
  echo "List of devices attached"
fi
exit 0
SH
cat > "$WORKDIR/bin/fcb" <<'SH'
#!/usr/bin/env sh
exit 0
SH
cat > "$WORKDIR/bin/fcb_server" <<'SH'
#!/usr/bin/env sh
exit 0
SH
cat > "$WORKDIR/bin/unzip" <<'SH'
#!/usr/bin/env sh
exit 0
SH
chmod +x "$WORKDIR/bin/flutter" "$WORKDIR/bin/adb" "$WORKDIR/bin/fcb" "$WORKDIR/bin/fcb_server" "$WORKDIR/bin/unzip"

mkdir -p "$(dirname "$ORIGINAL_JNILIB")"
printf '\177ELFfake updater so\n' > "$ORIGINAL_JNILIB"

run_preflight() {
    PATH="$WORKDIR/bin:$PATH" \
    FCB_BIN=fcb \
    SERVER_BIN=fcb_server \
    ADB_BIN=adb \
    FLUTTER_BIN=flutter \
    TARGET_PLATFORM="${TARGET_PLATFORM:-android-arm64}" \
    FLUTTER_BUILD_EXTRA_ARGS="$1" \
    "$REPO_ROOT/tests/e2e/phase_b_preflight.sh"
}

make_engine_out() {
    mkdir -p "$WORKDIR/engine/out/android_release_arm64"
    mkdir -p "$WORKDIR/engine/out/host_release"
}

echo "=== Preflight rejects missing --local-engine ==="
if PATH="$WORKDIR/bin:$PATH" \
    FCB_BIN=fcb \
    SERVER_BIN=fcb_server \
    ADB_BIN=adb \
    FLUTTER_BIN=flutter \
    FLUTTER_BUILD_EXTRA_ARGS="--local-engine-src-path $WORKDIR/engine" \
    "$REPO_ROOT/tests/e2e/phase_b_preflight.sh" >/tmp/fcb_preflight_missing_engine.log 2>&1; then
    echo "FAIL: preflight accepted missing --local-engine" >&2
    exit 1
fi
grep -q -- '--local-engine' /tmp/fcb_preflight_missing_engine.log

echo "=== Preflight rejects missing local Engine source path ==="
if PATH="$WORKDIR/bin:$PATH" \
    FCB_BIN=fcb \
    SERVER_BIN=fcb_server \
    ADB_BIN=adb \
    FLUTTER_BIN=flutter \
    FLUTTER_BUILD_EXTRA_ARGS="--local-engine android_release_arm64 --local-engine-host host_release" \
    "$REPO_ROOT/tests/e2e/phase_b_preflight.sh" >/tmp/fcb_preflight_missing_engine_src.log 2>&1; then
    echo "FAIL: preflight accepted missing local Engine source path" >&2
    exit 1
fi
grep -q 'requires a patched local Flutter Engine source tree' \
    /tmp/fcb_preflight_missing_engine_src.log

echo "=== Preflight rejects missing --local-engine-host ==="
if PATH="$WORKDIR/bin:$PATH" \
    FCB_BIN=fcb \
    SERVER_BIN=fcb_server \
    ADB_BIN=adb \
    FLUTTER_BIN=flutter \
    FLUTTER_BUILD_EXTRA_ARGS="--local-engine-src-path $WORKDIR/engine --local-engine android_release_arm64" \
    "$REPO_ROOT/tests/e2e/phase_b_preflight.sh" >/tmp/fcb_preflight_missing_engine_host.log 2>&1; then
    echo "FAIL: preflight accepted missing --local-engine-host" >&2
    exit 1
fi
grep -q -- '--local-engine-host' /tmp/fcb_preflight_missing_engine_host.log

echo "=== Preflight rejects ABI / target-platform mismatch ==="
if PATH="$WORKDIR/bin:$PATH" \
    FCB_BIN=fcb \
    SERVER_BIN=fcb_server \
    ADB_BIN=adb \
    FLUTTER_BIN=flutter \
    ABI=x86_64 \
    TARGET_PLATFORM=android-arm64 \
    FLUTTER_BUILD_EXTRA_ARGS="--local-engine-src-path $WORKDIR/engine --local-engine android_release_arm64 --local-engine-host host_release" \
    "$REPO_ROOT/tests/e2e/phase_b_preflight.sh" >/tmp/fcb_preflight_bad_target.log 2>&1; then
    echo "FAIL: preflight accepted mismatched ABI and target platform" >&2
    exit 1
fi
grep -q 'TARGET_PLATFORM=android-arm64 does not match ABI=x86_64' \
    /tmp/fcb_preflight_bad_target.log

echo "=== Preflight rejects invalid adb reverse mode ==="
if PATH="$WORKDIR/bin:$PATH" \
    FCB_BIN=fcb \
    SERVER_BIN=fcb_server \
    ADB_BIN=adb \
    FLUTTER_BIN=flutter \
    USE_ADB_REVERSE=maybe \
    FLUTTER_BUILD_EXTRA_ARGS="--local-engine-src-path $WORKDIR/engine --local-engine android_release_arm64 --local-engine-host host_release" \
    "$REPO_ROOT/tests/e2e/phase_b_preflight.sh" >/tmp/fcb_preflight_bad_reverse.log 2>&1; then
    echo "FAIL: preflight accepted invalid USE_ADB_REVERSE" >&2
    exit 1
fi
grep -q 'USE_ADB_REVERSE must be auto, 0, or 1' \
    /tmp/fcb_preflight_bad_reverse.log

echo "=== Preflight rejects loopback URL without adb reverse ==="
if PATH="$WORKDIR/bin:$PATH" \
    FCB_BIN=fcb \
    SERVER_BIN=fcb_server \
    ADB_BIN=adb \
    FLUTTER_BIN=flutter \
    DEVICE_SERVER_URL=http://127.0.0.1:18097 \
    USE_ADB_REVERSE=0 \
    FLUTTER_BUILD_EXTRA_ARGS="--local-engine-src-path $WORKDIR/engine --local-engine android_release_arm64 --local-engine-host host_release" \
    "$REPO_ROOT/tests/e2e/phase_b_preflight.sh" >/tmp/fcb_preflight_loopback_no_reverse.log 2>&1; then
    echo "FAIL: preflight accepted loopback URL without adb reverse" >&2
    exit 1
fi
grep -q 'uses a loopback host but USE_ADB_REVERSE=0' \
    /tmp/fcb_preflight_loopback_no_reverse.log

echo "=== Preflight rejects hook copied without AOT integration ==="
mkdir -p "$WORKDIR/engine/shell/platform/android/fcb"
cp "$REPO_ROOT/engine_patch/android/fcb_engine_hook.cc" \
    "$WORKDIR/engine/shell/platform/android/fcb/fcb_engine_hook.cc"
cat > "$WORKDIR/engine/shell/platform/android/fcb/BUILD.gn" <<'GN'
source_set("fcb_engine_hook") {
  sources = [ "fcb_engine_hook.cc" ]
}
GN
mkdir -p "$WORKDIR/engine/shell/platform/android/shell"
cat > "$WORKDIR/engine/shell/platform/android/shell/BUILD.gn" <<'GN'
source_set("android_shell") {
  deps = [ "//shell/platform/android/fcb:fcb_engine_hook" ]
}
GN
if run_preflight "--local-engine-src-path $WORKDIR/engine --local-engine android_release_arm64 --local-engine-host host_release" \
    >/tmp/fcb_preflight_unwired.log 2>&1; then
    echo "FAIL: preflight accepted unwired Engine hook" >&2
    exit 1
fi
grep -q 'does not call fcb_apply_android_snapshot_replace_with_config' \
    /tmp/fcb_preflight_unwired.log

echo "=== Preflight accepts wired Engine hook ==="
cat > "$WORKDIR/engine/shell/platform/android/shell/fcb_integration.cc" <<'CC'
void FcbIntegration() {
  fcb_apply_android_snapshot_replace_with_config(nullptr, nullptr);
}
CC
rm "$WORKDIR/engine/shell/platform/android/shell/BUILD.gn"
if run_preflight "--local-engine-src-path $WORKDIR/engine --local-engine android_release_arm64 --local-engine-host host_release" \
    >/tmp/fcb_preflight_unlinked.log 2>&1; then
    echo "FAIL: preflight accepted hook call without BUILD.gn dependency" >&2
    exit 1
fi
grep -q 'do not depend on //shell/platform/android/fcb:fcb_engine_hook' \
    /tmp/fcb_preflight_unlinked.log

cat > "$WORKDIR/engine/shell/platform/android/shell/BUILD.gn" <<'GN'
source_set("android_shell") {
  deps = [ "//shell/platform/android/fcb:fcb_engine_hook" ]
}
GN
echo "=== Preflight rejects missing local Engine out directory ==="
if run_preflight "--local-engine-src-path $WORKDIR/engine --local-engine android_release_arm64 --local-engine-host host_release" \
    >/tmp/fcb_preflight_missing_engine_out.log 2>&1; then
    echo "FAIL: preflight accepted missing local Engine out directory" >&2
    exit 1
fi
grep -q 'local Flutter Engine build output does not exist' \
    /tmp/fcb_preflight_missing_engine_out.log

mkdir -p "$WORKDIR/engine/out/android_release_arm64"

echo "=== Preflight rejects missing local Engine host out directory ==="
if run_preflight "--local-engine-src-path $WORKDIR/engine --local-engine android_release_arm64 --local-engine-host host_release" \
    >/tmp/fcb_preflight_missing_engine_host_out.log 2>&1; then
    echo "FAIL: preflight accepted missing local Engine host out directory" >&2
    exit 1
fi
grep -q 'local Flutter Engine host build output does not exist' \
    /tmp/fcb_preflight_missing_engine_host_out.log

make_engine_out

echo "=== Preflight accepts wired Engine hook and built out directory ==="
run_preflight "--local-engine-src-path $WORKDIR/engine --local-engine android_release_arm64 --local-engine-host host_release" \
    >/tmp/fcb_preflight_wired.log 2>&1
grep -q 'Phase B Android preflight passed' /tmp/fcb_preflight_wired.log

echo "=== Preflight rejects missing adb device ==="
if PATH="$WORKDIR/bin:$PATH" \
    FCB_BIN=fcb \
    SERVER_BIN=fcb_server \
    ADB_BIN=adb \
    FLUTTER_BIN=flutter \
    FCB_FAKE_ADB_FAIL=1 \
    FLUTTER_BUILD_EXTRA_ARGS="--local-engine-src-path $WORKDIR/engine --local-engine android_release_arm64 --local-engine-host host_release" \
    "$REPO_ROOT/tests/e2e/phase_b_preflight.sh" >/tmp/fcb_preflight_no_device.log 2>&1; then
    echo "FAIL: preflight accepted missing adb device" >&2
    exit 1
fi
grep -q 'no Android device is available through adb' \
    /tmp/fcb_preflight_no_device.log

echo "=== Preflight rejects non-ELF updater library ==="
printf 'not an elf library\n' > "$ORIGINAL_JNILIB"
if run_preflight "--local-engine-src-path $WORKDIR/engine --local-engine android_release_arm64 --local-engine-host host_release" \
    >/tmp/fcb_preflight_bad_updater.log 2>&1; then
    echo "FAIL: preflight accepted non-ELF updater library" >&2
    exit 1
fi
grep -q 'not an ELF shared object' /tmp/fcb_preflight_bad_updater.log

echo "=== Phase B preflight tests passed ==="
