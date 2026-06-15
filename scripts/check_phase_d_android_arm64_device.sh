#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENGINE_SRC_DIR="${FCB_ENGINE_SRC_DIR:-$ROOT_DIR/vendor/flutter/engine/src}"
ADB="${FCB_ADB:-$ENGINE_SRC_DIR/flutter/third_party/android_tools/sdk/platform-tools/adb}"
ADB_TIMEOUT_SECONDS="${FCB_ADB_TIMEOUT_SECONDS:-30}"
TARGET_ABI="${FCB_TARGET_ABI:-arm64-v8a}"
ALLOW_SECONDARY_ABI="${FCB_ALLOW_SECONDARY_ABI:-0}"

usage() {
  cat <<USAGE
Usage:
  $0

Checks that the current adb device supports the Phase D Android arm64 target ABI.
This is a fast preflight: it does not build, install, or launch the app.

Environment:
  FCB_ADB                  adb path. Default: Engine Android SDK adb
  FCB_ENGINE_SRC_DIR       Engine src root. Default: vendor/flutter/engine/src
  FCB_ADB_TIMEOUT_SECONDS  adb command timeout. Default: 30
  FCB_TARGET_ABI           Required ABI. Default: arm64-v8a
  FCB_ALLOW_SECONDARY_ABI  Accept target ABI as secondary (native-bridge). Default: 0
USAGE
}

die() {
  echo "error: $*" >&2
  exit 1
}

require_file() {
  [ -f "$1" ] || die "missing file: $1"
}

adb_cmd() {
  if command -v timeout >/dev/null 2>&1; then
    timeout "$ADB_TIMEOUT_SECONDS" "$ADB" "$@"
  else
    "$ADB" "$@"
  fi
}

main() {
  if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
    usage
    exit 0
  fi

  require_file "$ADB"
  adb_cmd start-server >/dev/null
  adb_cmd wait-for-device

  local serial primary_abi abi_list
  serial="$(adb_cmd get-serialno | tr -d '\r[:space:]')"
  primary_abi="$(adb_cmd shell getprop ro.product.cpu.abi | tr -d '\r[:space:]')"
  abi_list="$(adb_cmd shell getprop ro.product.cpu.abilist | tr -d '\r[:space:]')"

  if [ -z "$primary_abi" ]; then
    die "could not read device primary ABI"
  fi

  if [ "$primary_abi" = "$TARGET_ABI" ]; then
    echo "Phase D Android arm64 device preflight passed (primary ABI)"
    echo "serial: ${serial:-unknown}"
    echo "primary_abi: $primary_abi"
    echo "abilist: ${abi_list:-unknown}"
  elif [ "$ALLOW_SECONDARY_ABI" = "1" ]; then
    case ",$abi_list," in
      *",$TARGET_ABI,"*)
        echo "warning: device primary ABI is $primary_abi; $TARGET_ABI present as secondary ABI — native-bridge mode"
        echo "Phase D Android arm64 device preflight passed (secondary ABI)"
        echo "serial: ${serial:-unknown}"
        echo "primary_abi: $primary_abi"
        echo "abilist: ${abi_list:-unknown}"
        ;;
      *)
        die "device does not support $TARGET_ABI at all (primary: $primary_abi, abilist: ${abi_list:-unknown})"
        ;;
    esac
  else
    die "device primary ABI is $primary_abi, but Phase D arm64 acceptance requires $TARGET_ABI (serial: ${serial:-unknown}, abilist: ${abi_list:-unknown}); set FCB_ALLOW_SECONDARY_ABI=1 to accept native-bridge mode"
  fi
}

main "$@"
