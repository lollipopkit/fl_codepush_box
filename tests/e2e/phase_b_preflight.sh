#!/usr/bin/env bash
# Shared preflight for Phase B Android snapshot_replace validation.

set -euo pipefail

REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
FCB="${FCB_BIN:-fcb}"
SERVER="${SERVER_BIN:-fcb_server}"
FLUTTER="${FLUTTER_BIN:-flutter}"
ADB="${ADB_BIN:-adb}"
ABI="${ABI:-arm64-v8a}"
TARGET_PLATFORM="${TARGET_PLATFORM:-android-arm64}"
DEVICE_SERVER_URL="${DEVICE_SERVER_URL:-http://127.0.0.1:18097}"
USE_ADB_REVERSE="${USE_ADB_REVERSE:-auto}"

need_tool() {
    command -v "$1" >/dev/null 2>&1 || {
        echo "FAIL: required tool not found: $1" >&2
        return 1
    }
}

adb_cmd() {
    if [ -n "${ADB_DEVICE:-}" ]; then
        "$ADB" -s "$ADB_DEVICE" "$@"
    else
        "$ADB" "$@"
    fi
}

validate_abi() {
    case "$ABI" in
      arm64-v8a|armeabi-v7a|x86|x86_64)
        ;;
      *)
        echo "FAIL: unsupported Android ABI: $ABI" >&2
        return 1
        ;;
    esac
}

validate_target_platform() {
    local expected
    case "$ABI" in
      arm64-v8a) expected="android-arm64" ;;
      armeabi-v7a) expected="android-arm" ;;
      x86) expected="android-x86" ;;
      x86_64) expected="android-x64" ;;
      *) return 0 ;;
    esac
    if [ "$TARGET_PLATFORM" != "$expected" ]; then
        echo "FAIL: TARGET_PLATFORM=$TARGET_PLATFORM does not match ABI=$ABI; expected $expected" >&2
        return 1
    fi
}

validate_local_engine_args() {
    if [ -z "${FLUTTER_BUILD_EXTRA_ARGS:-}" ]; then
        echo "FAIL: FLUTTER_BUILD_EXTRA_ARGS is required for Phase B snapshot_replace device validation." >&2
        echo "Pass a patched local Engine, for example:" >&2
        echo "  FLUTTER_BUILD_EXTRA_ARGS='--local-engine-src-path /path/to/engine/src --local-engine android_release_arm64 --local-engine-host host_release'" >&2
        return 1
    fi
    case " $FLUTTER_BUILD_EXTRA_ARGS " in
      *" --local-engine "*|*" --local-engine="*)
        ;;
      *)
        echo "FAIL: FLUTTER_BUILD_EXTRA_ARGS must include --local-engine for patched Engine validation." >&2
        return 1
        ;;
    esac
    case " $FLUTTER_BUILD_EXTRA_ARGS " in
      *" --local-engine-host "*|*" --local-engine-host="*)
        ;;
      *)
        echo "FAIL: FLUTTER_BUILD_EXTRA_ARGS must include --local-engine-host for local Engine validation." >&2
        return 1
        ;;
    esac
}

validate_device_server_url() {
    case "$USE_ADB_REVERSE" in
      auto|0|1)
        ;;
      *)
        echo "FAIL: USE_ADB_REVERSE must be auto, 0, or 1; got $USE_ADB_REVERSE" >&2
        return 1
        ;;
    esac

    local host
    host=$(python3 - "$DEVICE_SERVER_URL" <<'PY'
import sys
from urllib.parse import urlparse

parsed = urlparse(sys.argv[1])
if parsed.scheme not in ("http", "https") or not parsed.hostname:
    raise SystemExit(2)
print(parsed.hostname)
PY
) || {
        echo "FAIL: DEVICE_SERVER_URL must be an http(s) URL with a host: $DEVICE_SERVER_URL" >&2
        return 1
    }

    case "$host" in
      127.*|localhost|::1)
        if [ "$USE_ADB_REVERSE" = "0" ]; then
            echo "FAIL: DEVICE_SERVER_URL=$DEVICE_SERVER_URL uses a loopback host but USE_ADB_REVERSE=0." >&2
            echo "Use USE_ADB_REVERSE=1/auto or set DEVICE_SERVER_URL to an address reachable from the device." >&2
            return 1
        fi
        ;;
    esac
}

arg_value() {
    local name="$1"
    local args="${FLUTTER_BUILD_EXTRA_ARGS:-}"
    local words
    # shellcheck disable=SC2206
    words=($args)
    local index=0
    while [ "$index" -lt "${#words[@]}" ]; do
        case "${words[$index]}" in
          "$name")
            index=$((index + 1))
            if [ "$index" -lt "${#words[@]}" ]; then
                printf '%s\n' "${words[$index]}"
                return 0
            fi
            ;;
          "$name"=*)
            printf '%s\n' "${words[$index]#*=}"
            return 0
            ;;
        esac
        index=$((index + 1))
    done
    return 1
}

local_engine_name() {
    arg_value --local-engine
}

local_engine_host_name() {
    arg_value --local-engine-host
}

validate_engine_source_patch() {
    local engine_src
    engine_src="${FCB_ENGINE_SRC:-}"
    if [ -z "$engine_src" ]; then
        engine_src=$(arg_value --local-engine-src-path || true)
    fi
    if [ -z "$engine_src" ]; then
        echo "FAIL: Phase B requires a patched local Flutter Engine source tree." >&2
        echo "Set FCB_ENGINE_SRC=/path/to/engine/src or include --local-engine-src-path in FLUTTER_BUILD_EXTRA_ARGS." >&2
        return 1
    fi
    if ! "$REPO_ROOT/engine_patch/android/verify_engine_patch.sh" "$engine_src"; then
        echo "Run: FLUTTER_ENGINE_SRC=$engine_src $REPO_ROOT/engine_patch/android/apply_engine_patch.sh $ABI" >&2
        return 1
    fi

    local engine_name
    engine_name=$(local_engine_name || true)
    if [ -z "$engine_name" ]; then
        echo "FAIL: FLUTTER_BUILD_EXTRA_ARGS must include a --local-engine value." >&2
        return 1
    fi
    if [ ! -d "$engine_src/out/$engine_name" ]; then
        echo "FAIL: local Flutter Engine build output does not exist: $engine_src/out/$engine_name" >&2
        echo "Build the patched Engine output named by --local-engine before running Phase B device validation." >&2
        return 1
    fi
    local engine_host_name
    engine_host_name=$(local_engine_host_name || true)
    if [ -z "$engine_host_name" ]; then
        echo "FAIL: FLUTTER_BUILD_EXTRA_ARGS must include a --local-engine-host value." >&2
        return 1
    fi
    if [ ! -d "$engine_src/out/$engine_host_name" ]; then
        echo "FAIL: local Flutter Engine host build output does not exist: $engine_src/out/$engine_host_name" >&2
        echo "Build the host Engine output named by --local-engine-host before running Phase B device validation." >&2
        return 1
    fi
}

validate_updater_jnilib() {
    local updater_jnilib
    updater_jnilib="${FCB_UPDATER_JNILIB:-$REPO_ROOT/packages/fcb_code_push/android/src/main/jniLibs/$ABI/libfcb_updater.so}"
    if [ -z "${FCB_UPDATER_JNILIB:-}" ] && [ ! -f "$updater_jnilib" ] && [ "${FCB_AUTO_BUILD_ANDROID_UPDATER:-0}" = "1" ]; then
        "$REPO_ROOT/packages/fcb_code_push/tool/build_android_native.sh" "$ABI"
    fi
    if [ ! -f "$updater_jnilib" ]; then
        echo "FAIL: missing Android updater native library for $ABI: $updater_jnilib" >&2
        echo "Build it with: $REPO_ROOT/packages/fcb_code_push/tool/build_android_native.sh $ABI" >&2
        echo "Or set FCB_AUTO_BUILD_ANDROID_UPDATER=1 when cargo-ndk and the Android NDK are installed." >&2
        return 1
    fi
    if ! python3 -c 'import sys; data=open(sys.argv[1], "rb").read(4); sys.exit(0 if data == b"\x7fELF" else 1)' "$updater_jnilib"; then
        echo "FAIL: Android updater native library is not an ELF shared object: $updater_jnilib" >&2
        return 1
    fi
}

validate_device() {
    if ! adb_cmd get-state >/dev/null 2>&1; then
        echo "FAIL: no Android device is available through adb" >&2
        if [ -n "${ADB_DEVICE:-}" ]; then
            echo "Requested ADB_DEVICE=$ADB_DEVICE" >&2
        fi
        "$ADB" devices >&2 || true
        return 1
    fi
}

main() {
    validate_abi
    validate_target_platform
    need_tool "$FLUTTER"
    need_tool "$ADB"
    need_tool "$FCB"
    need_tool "$SERVER"
    need_tool curl
    need_tool python3
    need_tool unzip
    validate_local_engine_args
    validate_device_server_url
    validate_engine_source_patch
    validate_updater_jnilib
    validate_device
    echo "Phase B Android preflight passed for ABI=$ABI"
}

main "$@"
