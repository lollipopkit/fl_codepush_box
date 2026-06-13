#!/usr/bin/env bash
# Unit-style checks for test_phase_b_android.sh helper logic.

set -euo pipefail

REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
TEST_WORKDIR=$(mktemp -d /tmp/fcb_phase_b_android_helpers_XXXXXX)

cleanup() {
    rm -rf "$TEST_WORKDIR" "${WORKDIR:-}"
}
trap cleanup EXIT INT TERM

cat > "$TEST_WORKDIR/flutter" <<'SH'
#!/usr/bin/env sh
printf '%s\n' "$@" > "$FCB_FAKE_FLUTTER_ARGS"
SH
cat > "$TEST_WORKDIR/adb" <<'SH'
#!/usr/bin/env sh
case "$1" in
  devices)
    echo "List of devices attached"
    echo "fake-device device"
    ;;
  shell)
    shift
    if [ "$1" = "pm" ] && [ "$2" = "path" ]; then
      echo "package:/data/app/$3/base.apk"
    elif [ "$1" = "cat" ]; then
      echo '<hierarchy><node text="unexpected"/></hierarchy>'
    fi
    ;;
  logcat)
    echo "fake logcat line"
    ;;
esac
SH
chmod +x "$TEST_WORKDIR/flutter" "$TEST_WORKDIR/adb"

export FLUTTER_BIN="$TEST_WORKDIR/flutter"
export ADB_BIN="$TEST_WORKDIR/adb"
export FCB_FAKE_FLUTTER_ARGS="$TEST_WORKDIR/flutter_args.txt"
export FLUTTER_BUILD_EXTRA_ARGS='--local-engine-src-path /tmp/fcb-engine/src --local-engine android_release_arm64 --local-engine-host host_release'
export FCB_PHASE_B_ANDROID_SOURCE_ONLY=1

# shellcheck source=tests/e2e/test_phase_b_android.sh
source "$REPO_ROOT/tests/e2e/test_phase_b_android.sh"
trap cleanup EXIT INT TERM

APP_ID=test-app
PUBLIC_KEY=test-key

echo "=== build_apk forwards Phase B local Engine args ==="
build_apk 7
grep -qx -- 'build' "$FCB_FAKE_FLUTTER_ARGS"
grep -qx -- 'apk' "$FCB_FAKE_FLUTTER_ARGS"
grep -qx -- '--release' "$FCB_FAKE_FLUTTER_ARGS"
grep -qx -- '--target-platform' "$FCB_FAKE_FLUTTER_ARGS"
grep -qx -- 'android-arm64' "$FCB_FAKE_FLUTTER_ARGS"
grep -qx -- '--dart-define' "$FCB_FAKE_FLUTTER_ARGS"
grep -qx -- 'FCB_INITIAL_COUNTER=7' "$FCB_FAKE_FLUTTER_ARGS"
grep -qx -- '--local-engine-src-path' "$FCB_FAKE_FLUTTER_ARGS"
grep -qx -- '/tmp/fcb-engine/src' "$FCB_FAKE_FLUTTER_ARGS"
grep -qx -- '--local-engine' "$FCB_FAKE_FLUTTER_ARGS"
grep -qx -- 'android_release_arm64' "$FCB_FAKE_FLUTTER_ARGS"
grep -qx -- '--local-engine-host' "$FCB_FAKE_FLUTTER_ARGS"
grep -qx -- 'host_release' "$FCB_FAKE_FLUTTER_ARGS"

echo "=== wait_for_text emits Android diagnostics on failure ==="
if (UI_WAIT_SECONDS=1 wait_for_text 'never-present') >/tmp/fcb_wait_for_text.log 2>&1; then
    echo "FAIL: wait_for_text accepted missing text" >&2
    exit 1
fi
grep -q 'Android diagnostics: missing UI text: never-present' /tmp/fcb_wait_for_text.log
grep -q 'package:/data/app/com.example.fcb_phase_b_counter/base.apk' /tmp/fcb_wait_for_text.log
grep -q 'fake logcat line' /tmp/fcb_wait_for_text.log

echo "=== Phase B Android helper tests passed ==="
