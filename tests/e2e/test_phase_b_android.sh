#!/usr/bin/env bash
# Real Android Phase B validation for snapshot_replace.
#
# Requires:
#   - flutter and adb on PATH
#   - fcb CLI built and available via FCB_BIN or PATH
#   - fcb server built and available via SERVER_BIN or PATH
#   - a patched Flutter Engine wired with engine_patch/android
#
# Optional:
#   FLUTTER_BUILD_EXTRA_ARGS='--local-engine-src-path ... --local-engine ... --local-engine-host ...'
#   FCB_AUTO_BUILD_ANDROID_UPDATER=1
#   ADB_DEVICE=<device serial>
#   ABI=arm64-v8a
#   TARGET_PLATFORM=android-arm64
#   DEVICE_SERVER_URL=http://host-or-forwarded-port:18097

set -euo pipefail

REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
FCB="${FCB_BIN:-fcb}"
SERVER="${SERVER_BIN:-fcb_server}"
FLUTTER="${FLUTTER_BIN:-flutter}"
ADB="${ADB_BIN:-adb}"
ABI="${ABI:-arm64-v8a}"
TARGET_PLATFORM="${TARGET_PLATFORM:-android-arm64}"
SERVER_ADDR="${SERVER_ADDR:-127.0.0.1:18097}"
SERVER_HOST="${SERVER_ADDR%:*}"
SERVER_PORT="${SERVER_ADDR##*:}"
DEVICE_SERVER_URL="${DEVICE_SERVER_URL:-http://127.0.0.1:${SERVER_PORT}}"
USE_ADB_REVERSE="${USE_ADB_REVERSE:-auto}"
PHASE_B_EVIDENCE_DIR="${PHASE_B_EVIDENCE_DIR:-$REPO_ROOT/.phase_b_evidence}"
PACKAGE_NAME="com.example.fcb_phase_b_counter"
ACTIVITY_NAME="$PACKAGE_NAME/.MainActivity"
WORKDIR=$(mktemp -d /tmp/fcb_phase_b_android_XXXXXX)
APPDIR="$WORKDIR/app"
STORE_FILE="$WORKDIR/server/store.json"
SERVER_PID=""
EMULATOR_PID=""
FLUTTER_EXTRA_ARGS=()

if [ -n "${FLUTTER_BUILD_EXTRA_ARGS:-}" ]; then
    # shellcheck disable=SC2206
    FLUTTER_EXTRA_ARGS=($FLUTTER_BUILD_EXTRA_ARGS)
fi

cleanup() {
    if [ -n "$SERVER_PID" ]; then
        kill "$SERVER_PID" 2>/dev/null || true
        wait "$SERVER_PID" 2>/dev/null || true
    fi
    if [ -n "$EMULATOR_PID" ]; then
        kill "$EMULATOR_PID" 2>/dev/null || true
        wait "$EMULATOR_PID" 2>/dev/null || true
    fi
    rm -rf "$WORKDIR"
}
trap cleanup EXIT INT TERM

dump_diagnostics() {
    local reason="${1:-unknown}"
    echo "=== Android diagnostics: $reason ===" >&2
    echo "--- adb devices ---" >&2
    "$ADB" devices >&2 || true
    echo "--- package path ---" >&2
    adb_cmd shell pm path "$PACKAGE_NAME" >&2 || true
    echo "--- window dump ---" >&2
    adb_cmd shell uiautomator dump /sdcard/window.xml >/dev/null 2>&1 || true
    adb_cmd shell cat /sdcard/window.xml >&2 || true
    echo "--- recent logcat ---" >&2
    adb_cmd logcat -d -t 300 >&2 || true
}

need_tool() {
    command -v "$1" >/dev/null 2>&1 || {
        echo "FAIL: required tool not found: $1" >&2
        exit 1
    }
}

adb_cmd() {
    local attempts=0
    local status=0
    local timeout_seconds="${ADB_COMMAND_TIMEOUT_SECONDS:-180}"
    while [ "$attempts" -lt 5 ]; do
        if [ -n "${ADB_DEVICE:-}" ]; then
            timeout "$timeout_seconds" "$ADB" -s "$ADB_DEVICE" "$@" && return 0
            status=$?
        else
            timeout "$timeout_seconds" "$ADB" "$@" && return 0
            status=$?
        fi
        attempts=$((attempts + 1))
        sleep 2
    done
    return "$status"
}

configure_adb_reverse() {
    if [ "$USE_ADB_REVERSE" = "1" ] || {
        [ "$USE_ADB_REVERSE" = "auto" ] &&
        [ "$DEVICE_SERVER_URL" = "http://127.0.0.1:${SERVER_PORT}" ];
    }; then
        echo "=== Configuring adb reverse tcp:$SERVER_PORT ==="
        adb_cmd reverse "tcp:$SERVER_PORT" "tcp:$SERVER_PORT"
    fi
}

wait_for_device_boot() {
    local attempts=0
    local state
    local boot
    while [ "$attempts" -lt "${ADB_BOOT_WAIT_ATTEMPTS:-120}" ]; do
        state=$(adb_cmd get-state 2>/dev/null || true)
        boot=$(adb_cmd shell getprop sys.boot_completed 2>/dev/null | tr -d '\r' || true)
        if [ "$state" = "device" ] && [ "$boot" = "1" ]; then
            adb_cmd shell service check package | grep -q 'found' && return 0
        fi
        sleep 5
        attempts=$((attempts + 1))
    done
    echo "FAIL: Android device did not finish booting" >&2
    "$ADB" devices >&2 || true
    return 1
}

stop_emulator_for_host_build() {
    if [ -z "${PHASE_B_RESTART_EMULATOR_CMD:-}" ]; then
        return 0
    fi
    echo "=== Stopping emulator during host patch build ==="
    adb_cmd emu kill >/dev/null 2>&1 || true
    sleep 5
}

restart_emulator_for_device_phase() {
    if [ -z "${PHASE_B_RESTART_EMULATOR_CMD:-}" ]; then
        return 0
    fi
    echo "=== Restarting emulator for device validation ==="
    bash -lc "$PHASE_B_RESTART_EMULATOR_CMD" &
    EMULATOR_PID=$!
    wait_for_device_boot
    configure_adb_reverse
    adb_cmd logcat -c >/dev/null 2>&1 || true
}

wait_for_server() {
    local attempts=0
    while [ "$attempts" -lt 60 ]; do
        if (echo > /dev/tcp/"$SERVER_HOST"/"$SERVER_PORT") 2>/dev/null; then
            return 0
        fi
        if [ -n "$SERVER_PID" ] && ! kill -0 "$SERVER_PID" 2>/dev/null; then
            echo "FAIL: server process exited before becoming ready" >&2
            wait "$SERVER_PID" 2>/dev/null || true
            exit 1
        fi
        sleep 0.5
        attempts=$((attempts + 1))
    done
    echo "FAIL: server did not become ready at $SERVER_ADDR" >&2
    exit 1
}

wait_for_text() {
    local expected="$1"
    local elapsed=0
    local timeout="${UI_WAIT_SECONDS:-60}"
    while [ "$elapsed" -lt "$timeout" ]; do
        adb_cmd shell uiautomator dump /sdcard/window.xml >/dev/null 2>&1 || true
        local dump
        dump=$(adb_cmd shell cat /sdcard/window.xml 2>/dev/null || true)
        if printf '%s' "$dump" | grep -q "$expected"; then
            return 0
        fi
        sleep 1
        elapsed=$((elapsed + 1))
    done
    echo "FAIL: UI text not found: $expected" >&2
    dump_diagnostics "missing UI text: $expected"
    exit 1
}

assert_app_process_exited() {
    local reason="$1"
    if adb_cmd shell pidof "$PACKAGE_NAME" >/tmp/fcb_phase_b_pidof.log 2>/dev/null; then
        echo "FAIL: app process is still running after $reason" >&2
        cat /tmp/fcb_phase_b_pidof.log >&2 || true
        dump_diagnostics "$reason"
        exit 1
    fi
}

find_libapp() {
    local path
    path="$APPDIR/build/app/intermediates/stripped_native_libs/release/out/lib/$ABI/libapp.so"
    if [ -f "$path" ]; then
        printf '%s\n' "$path"
        return 0
    fi
    path="$APPDIR/build/app/outputs/flutter-apk/libapp.so"
    if [ -f "$path" ]; then
        printf '%s\n' "$path"
        return 0
    fi
    echo "FAIL: libapp.so not found for ABI $ABI" >&2
    exit 1
}

assert_files_differ() {
    local left="$1"
    local right="$2"
    local description="$3"
    if cmp -s "$left" "$right"; then
        echo "FAIL: $description are identical; patch would not change the Android AOT artifact" >&2
        echo "Left: $left" >&2
        echo "Right: $right" >&2
        exit 1
    fi
}

force_extract_native_libs() {
    local manifest="$APPDIR/android/app/src/main/AndroidManifest.xml"
    if [ ! -f "$manifest" ]; then
        echo "FAIL: AndroidManifest.xml not found: $manifest" >&2
        exit 1
    fi
    "$REPO_ROOT/tests/e2e/force_extract_native_libs.py" "$manifest"
    grep -q 'android:extractNativeLibs="true"' "$manifest" || {
        echo "FAIL: failed to force android:extractNativeLibs=true in $manifest" >&2
        exit 1
    }
}

disable_android_impeller() {
    local manifest="$APPDIR/android/app/src/main/AndroidManifest.xml"
    python3 - "$manifest" <<'PY'
import re
import sys
from pathlib import Path

path = Path(sys.argv[1])
data = path.read_text(encoding="utf-8")
entry = (
    '        <meta-data\n'
    '            android:name="io.flutter.embedding.android.EnableImpeller"\n'
    '            android:value="false" />\n'
)
pattern = r'<meta-data\s+[^>]*android:name="io\.flutter\.embedding\.android\.EnableImpeller"[^>]*/>'
if re.search(pattern, data, flags=re.S):
    data = re.sub(pattern, entry.rstrip(), data, count=1, flags=re.S)
else:
    match = re.search(r"<application\b[^>]*>", data)
    if not match:
        raise SystemExit(f"FAIL: missing <application> tag in {path}")
    data = data[:match.end()] + "\n" + entry + data[match.end():]
path.write_text(data, encoding="utf-8")
PY
    grep -q 'io.flutter.embedding.android.EnableImpeller' "$manifest" || {
        echo "FAIL: failed to disable Impeller in $manifest" >&2
        exit 1
    }
}

set_android_min_sdk() {
    local gradle="$APPDIR/android/app/build.gradle"
    local gradle_kts="$APPDIR/android/app/build.gradle.kts"
    if [ -f "$gradle" ]; then
        sed -i \
            -e 's/minSdk = flutter\.minSdkVersion/minSdk = 23/' \
            -e 's/minSdkVersion flutter\.minSdkVersion/minSdkVersion 23/' \
            "$gradle"
        grep -Eq 'minSdk(Version)?[ =]+23' "$gradle" || {
            echo "FAIL: failed to set minSdk 23 in $gradle" >&2
            exit 1
        }
        return 0
    fi
    if [ -f "$gradle_kts" ]; then
        sed -i 's/minSdk = flutter\.minSdkVersion/minSdk = 23/' "$gradle_kts"
        grep -Eq 'minSdk[ =]+23' "$gradle_kts" || {
            echo "FAIL: failed to set minSdk 23 in $gradle_kts" >&2
            exit 1
        }
        return 0
    fi
    echo "FAIL: Android app Gradle file not found under $APPDIR/android/app" >&2
    exit 1
}

verify_apk_native_libs() {
    local apk="$1"
    unzip -l "$apk" | grep -q "lib/$ABI/libapp.so" || {
        echo "FAIL: APK does not contain lib/$ABI/libapp.so: $apk" >&2
        exit 1
    }
    unzip -l "$apk" | grep -q "lib/$ABI/libfcb_updater.so" || {
        echo "FAIL: APK does not contain lib/$ABI/libfcb_updater.so: $apk" >&2
        exit 1
    }
}

build_apk() {
    local counter="$1"
    "$FLUTTER" build apk \
        --release \
        --target-platform "$TARGET_PLATFORM" \
        --dart-define "FCB_APP_ID=$APP_ID" \
        --dart-define "FCB_PUBLIC_KEY=$PUBLIC_KEY" \
        --dart-define "FCB_SERVER_URL=$DEVICE_SERVER_URL" \
        --dart-define "FCB_RELEASE_VERSION=1.0.0+1" \
        --dart-define "FCB_CHANNEL=stable" \
        --dart-define "FCB_PLATFORM=android" \
        --dart-define "FCB_ARCH=$ABI" \
        --dart-define "FCB_CHECK_ON_STARTUP=true" \
        --dart-define "FCB_INITIAL_COUNTER=$counter" \
        "${FLUTTER_EXTRA_ARGS[@]}"
}

flutter_extra_arg_value() {
    local name="$1"
    local index=0
    while [ "$index" -lt "${#FLUTTER_EXTRA_ARGS[@]}" ]; do
        case "${FLUTTER_EXTRA_ARGS[$index]}" in
          "$name")
            index=$((index + 1))
            if [ "$index" -lt "${#FLUTTER_EXTRA_ARGS[@]}" ]; then
                printf '%s\n' "${FLUTTER_EXTRA_ARGS[$index]}"
                return 0
            fi
            ;;
          "$name"=*)
            printf '%s\n' "${FLUTTER_EXTRA_ARGS[$index]#*=}"
            return 0
            ;;
        esac
        index=$((index + 1))
    done
    return 1
}

write_phase_b_evidence() {
    mkdir -p "$PHASE_B_EVIDENCE_DIR"
    local evidence
    local engine_src
    local local_engine
    local local_engine_host
    local adb_state
    local android_release
    local android_api
    local android_abi
    local flutter_devices
    evidence="$PHASE_B_EVIDENCE_DIR/phase_b_android_${ABI}_$(date -u +%Y%m%dT%H%M%SZ).json"
    engine_src="${FCB_ENGINE_SRC:-}"
    if [ -z "$engine_src" ]; then
        engine_src=$(flutter_extra_arg_value --local-engine-src-path || true)
    fi
    local_engine=$(flutter_extra_arg_value --local-engine || true)
    local_engine_host=$(flutter_extra_arg_value --local-engine-host || true)
    adb_state=$(adb_cmd get-state 2>/dev/null || true)
    android_release=$(adb_cmd shell getprop ro.build.version.release 2>/dev/null | tr -d '\r' || true)
    android_api=$(adb_cmd shell getprop ro.build.version.sdk 2>/dev/null | tr -d '\r' || true)
    android_abi=$(adb_cmd shell getprop ro.product.cpu.abi 2>/dev/null | tr -d '\r' || true)
    flutter_devices=$("$FLUTTER" devices 2>/dev/null || true)
    PHASE_B_EVIDENCE_APP_ID="$APP_ID" \
    PHASE_B_EVIDENCE_ABI="$ABI" \
    PHASE_B_EVIDENCE_TARGET_PLATFORM="$TARGET_PLATFORM" \
    PHASE_B_EVIDENCE_ADB_DEVICE="${ADB_DEVICE:-}" \
    PHASE_B_EVIDENCE_DEVICE_SERVER_URL="$DEVICE_SERVER_URL" \
    PHASE_B_EVIDENCE_USE_ADB_REVERSE="$USE_ADB_REVERSE" \
    PHASE_B_EVIDENCE_ADB_STATE="$adb_state" \
    PHASE_B_EVIDENCE_ANDROID_RELEASE="$android_release" \
    PHASE_B_EVIDENCE_ANDROID_API="$android_api" \
    PHASE_B_EVIDENCE_ANDROID_ABI="$android_abi" \
    PHASE_B_EVIDENCE_FLUTTER_DEVICES="$flutter_devices" \
    PHASE_B_EVIDENCE_FLUTTER_ARGS="${FLUTTER_BUILD_EXTRA_ARGS:-}" \
    PHASE_B_EVIDENCE_ENGINE_SRC="$engine_src" \
    PHASE_B_EVIDENCE_LOCAL_ENGINE="$local_engine" \
    PHASE_B_EVIDENCE_LOCAL_ENGINE_HOST="$local_engine_host" \
    PHASE_B_EVIDENCE_DRY_RUN="${FCB_PHASE_B_ANDROID_DRY_RUN:-0}" \
    PHASE_B_EVIDENCE_BASE_APK="$BASE_APK" \
    PHASE_B_EVIDENCE_BASE_LIBAPP="$BASE_LIBAPP_COPY" \
    PHASE_B_EVIDENCE_PATCH_LIBAPP="$PATCH_LIBAPP" \
    python3 - "$evidence" <<'PY'
import datetime
import hashlib
import json
import os
import pathlib
import sys

def sha256(path):
    if not path:
        return None
    p = pathlib.Path(path)
    if not p.exists():
        return None
    h = hashlib.sha256()
    with p.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()

out = pathlib.Path(sys.argv[1])
data = {
    "schema_version": 1,
    "passed": True,
    "created_at": datetime.datetime.now(datetime.timezone.utc).isoformat(),
    "script": "tests/e2e/test_phase_b_android.sh",
    "dry_run": os.environ["PHASE_B_EVIDENCE_DRY_RUN"] == "1",
    "app_id": os.environ["PHASE_B_EVIDENCE_APP_ID"],
    "abi": os.environ["PHASE_B_EVIDENCE_ABI"],
    "target_platform": os.environ["PHASE_B_EVIDENCE_TARGET_PLATFORM"],
    "adb_device": os.environ["PHASE_B_EVIDENCE_ADB_DEVICE"],
    "device": {
        "adb_state": os.environ["PHASE_B_EVIDENCE_ADB_STATE"],
        "android_release": os.environ["PHASE_B_EVIDENCE_ANDROID_RELEASE"],
        "android_api": os.environ["PHASE_B_EVIDENCE_ANDROID_API"],
        "android_abi": os.environ["PHASE_B_EVIDENCE_ANDROID_ABI"],
        "flutter_devices": os.environ["PHASE_B_EVIDENCE_FLUTTER_DEVICES"],
    },
    "device_server_url": os.environ["PHASE_B_EVIDENCE_DEVICE_SERVER_URL"],
    "use_adb_reverse": os.environ["PHASE_B_EVIDENCE_USE_ADB_REVERSE"],
    "flutter_build_extra_args": os.environ["PHASE_B_EVIDENCE_FLUTTER_ARGS"],
    "local_engine": {
        "src_path": os.environ["PHASE_B_EVIDENCE_ENGINE_SRC"],
        "target": os.environ["PHASE_B_EVIDENCE_LOCAL_ENGINE"],
        "host": os.environ["PHASE_B_EVIDENCE_LOCAL_ENGINE_HOST"],
    },
    "artifacts": {
        "base_apk": os.environ["PHASE_B_EVIDENCE_BASE_APK"],
        "base_apk_sha256": sha256(os.environ["PHASE_B_EVIDENCE_BASE_APK"]),
        "base_libapp": os.environ["PHASE_B_EVIDENCE_BASE_LIBAPP"],
        "base_libapp_sha256": sha256(os.environ["PHASE_B_EVIDENCE_BASE_LIBAPP"]),
        "patch_libapp": os.environ["PHASE_B_EVIDENCE_PATCH_LIBAPP"],
        "patch_libapp_sha256": sha256(os.environ["PHASE_B_EVIDENCE_PATCH_LIBAPP"]),
    },
    "validations": [
        "preflight passed with patched local Engine source and out directories",
        "baseline APK contained libapp.so and libfcb_updater.so",
        "Counter app v1 displayed Counter: 1",
        "release was published from baseline libapp.so",
        "patch libapp.so differed from baseline libapp.so",
        "patch was generated and promoted",
        "installed baseline app downloaded the patch",
        "restart loaded patched AOT artifact and displayed Counter: 2",
        "intentionally crashing patch caused process exit",
        "next launch rolled back to the previous active patch",
        "server stopped and local active patch still displayed Counter: 2",
    ],
}
out.write_text(json.dumps(data, indent=2, sort_keys=True) + "\n", encoding="utf-8")
print(out)
PY
}

main() {
    "$REPO_ROOT/tests/e2e/phase_b_preflight.sh"

    configure_adb_reverse
    adb_cmd logcat -c >/dev/null 2>&1 || true

    mkdir -p "$(dirname "$STORE_FILE")"

    echo "=== Starting FCB server ==="
    FCB_SERVER_ADDR="$SERVER_ADDR" FCB_SERVER_STORE="$STORE_FILE" "$SERVER" &
    SERVER_PID=$!
    wait_for_server

    echo "=== Creating FCB app config ==="
    cd "$WORKDIR"
    "$FCB" init
    APP_ID=$(grep 'app_id' fcb.yaml | sed 's/app_id: "\(.*\)"/\1/')
    PUBLIC_KEY=$(cat .fcb/keys/dev-ed25519.public)
    curl -fsS -X POST "http://$SERVER_ADDR/v1/apps" \
        -H 'Content-Type: application/json' \
        -d "{\"id\":\"$APP_ID\",\"name\":\"Phase B Android\"}" >/dev/null || {
            echo "FAIL: failed to create Phase B app on FCB server at http://$SERVER_ADDR" >&2
            exit 1
        }

    echo "=== Creating temporary Flutter app ==="
    "$FLUTTER" create --platforms=android --project-name fcb_phase_b_counter "$APPDIR"
    force_extract_native_libs
    disable_android_impeller
    set_android_min_sdk
    cp "$REPO_ROOT/examples/counter_app/lib/main.dart" "$APPDIR/lib/main.dart"
    cat > "$APPDIR/pubspec.yaml" <<EOF
name: fcb_phase_b_counter
description: FCB Phase B Android validation app.
publish_to: none
version: 1.0.0+1

environment:
  sdk: ">=3.0.0 <4.0.0"

dependencies:
  flutter:
    sdk: flutter
  fcb_code_push:
    path: $REPO_ROOT/packages/fcb_code_push
  fcb_annotations:
    path: $REPO_ROOT/packages/fcb_annotations
  fcb_interpreter:
    path: $REPO_ROOT/packages/fcb_interpreter

flutter:
  uses-material-design: true
EOF

    cd "$APPDIR"
    "$FLUTTER" pub get

    stop_emulator_for_host_build

    echo "=== Building baseline APK (Counter: 1) ==="
    build_apk 1
    BASE_LIBAPP=$(find_libapp)
    BASE_LIBAPP_COPY="$WORKDIR/baseline-libapp.so"
    cp "$BASE_LIBAPP" "$BASE_LIBAPP_COPY"
    BASE_APK="$APPDIR/build/app/outputs/flutter-apk/app-release.apk"
    test -f "$BASE_APK" || { echo "FAIL: baseline APK not found"; exit 1; }
    verify_apk_native_libs "$BASE_APK"

    cd "$WORKDIR"
    "$FCB" --server "http://$SERVER_ADDR" release android \
        --release-version 1.0.0+1 \
        --arch "$ABI" \
        --artifact "$BASE_LIBAPP"

    restart_emulator_for_device_phase

    echo "=== Removing any stale installed app data ==="
    adb_cmd uninstall "$PACKAGE_NAME" >/dev/null 2>&1 || true

    echo "=== Installing baseline APK ==="
    adb_cmd install -r "$BASE_APK"
    adb_cmd shell am force-stop "$PACKAGE_NAME" || true
    adb_cmd shell am start -n "$ACTIVITY_NAME"
    wait_for_text 'Counter: 1'

    stop_emulator_for_host_build

    echo "=== Building patch artifact (Counter: 2) ==="
    cd "$APPDIR"
    "$FLUTTER" clean
    "$FLUTTER" pub get
    build_apk 2
    PATCH_LIBAPP=$(find_libapp)
    assert_files_differ "$BASE_LIBAPP_COPY" "$PATCH_LIBAPP" "baseline and patch libapp.so"

    cd "$WORKDIR"
    "$FCB" --server "http://$SERVER_ADDR" patch android \
        --release-version 1.0.0+1 \
        --patch-number 1 \
        --arch "$ABI" \
        --artifact "$PATCH_LIBAPP"
    "$FCB" --server "http://$SERVER_ADDR" promote \
        --release-version 1.0.0+1 \
        --patch-number 1 \
        --arch "$ABI" \
        --rollout-percentage 100

    restart_emulator_for_device_phase

    echo "=== Starting baseline app to download patch ==="
    adb_cmd shell am force-stop "$PACKAGE_NAME" || true
    adb_cmd shell am start -n "$ACTIVITY_NAME"
    wait_for_text 'installed'

    echo "=== Restarting app; patched Engine should load Counter: 2 ==="
    adb_cmd shell am force-stop "$PACKAGE_NAME" || true
    adb_cmd shell am start -n "$ACTIVITY_NAME"
    wait_for_text 'Counter: 2'

    echo "=== Publishing intentionally crashing patch ==="
    printf 'not a valid Android libapp.so\n' > "$WORKDIR/crash-libapp.so"
    "$FCB" --server "http://$SERVER_ADDR" patch android \
        --release-version 1.0.0+1 \
        --patch-number 2 \
        --arch "$ABI" \
        --artifact "$WORKDIR/crash-libapp.so"
    "$FCB" --server "http://$SERVER_ADDR" promote \
        --release-version 1.0.0+1 \
        --patch-number 2 \
        --arch "$ABI" \
        --rollout-percentage 100

    echo "=== Running active app to download crashing patch ==="
    adb_cmd shell am force-stop "$PACKAGE_NAME" || true
    adb_cmd shell am start -n "$ACTIVITY_NAME"
    wait_for_text 'installed'

    echo "=== Restarting into crashing patch; next launch should roll back ==="
    adb_cmd shell am force-stop "$PACKAGE_NAME" || true
    adb_cmd shell am start -n "$ACTIVITY_NAME" || true
    sleep 5
    assert_app_process_exited "starting intentionally crashing patch"
    adb_cmd shell am force-stop "$PACKAGE_NAME" || true
    adb_cmd shell am start -n "$ACTIVITY_NAME"
    wait_for_text 'Counter: 2'

    echo "=== Stopping server; active local patch should still launch ==="
    kill "$SERVER_PID" 2>/dev/null || true
    wait "$SERVER_PID" 2>/dev/null || true
    SERVER_PID=""
    adb_cmd shell am force-stop "$PACKAGE_NAME" || true
    adb_cmd shell am start -n "$ACTIVITY_NAME"
    wait_for_text 'Counter: 2'

    echo "=== Writing Phase B evidence ==="
    write_phase_b_evidence

    echo "=== Phase B Android device validation passed ==="
}

if [ "${FCB_PHASE_B_ANDROID_SOURCE_ONLY:-0}" != "1" ]; then
    main "$@"
fi
