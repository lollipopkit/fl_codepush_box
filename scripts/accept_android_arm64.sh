#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEVICE_CHECK_SCRIPT="$ROOT_DIR/scripts/check_android_arm64_device.sh"
TEST_SCRIPT="${FCB_TEST_SCRIPT:-$ROOT_DIR/scripts/test_android_arm64.sh}"
APP_DIR="${FCB_APP_DIR:-$ROOT_DIR/examples/counter_app}"
ENGINE_SRC_DIR="${FCB_ENGINE_SRC_DIR:-$ROOT_DIR/vendor/flutter/engine/src}"
ENGINE_OUT_NAME="${FCB_ENGINE_OUT_NAME:-android_release_arm64}"
ADB="${FCB_ADB:-$ENGINE_SRC_DIR/flutter/third_party/android_tools/sdk/platform-tools/adb}"
ADB_TIMEOUT_SECONDS="${FCB_ADB_TIMEOUT_SECONDS:-30}"
ALLOW_SECONDARY_ABI="${FCB_ALLOW_SECONDARY_ABI:-0}"
WORKDIR="${FCB_WORKDIR:-$ROOT_DIR/target/fcb/android-arm64-acceptance}"
case "$WORKDIR" in
  /*) ;;
  *) WORKDIR="$ROOT_DIR/$WORKDIR" ;;
esac

usage() {
  cat <<USAGE
Usage:
  $0

Runs the FCB Android arm64 acceptance suite against the current adb device:
  1. device primary ABI must be arm64-v8a
  2. no-patch launch must return 1/8/7/base/10
  3. bytecode-patch launch must return 42/42/42/patched/42

By default this script requires the device primary ABI to be arm64-v8a.
Set FCB_ALLOW_SECONDARY_ABI=1 to also accept x86_64 emulators that support
arm64-v8a as a secondary ABI via native-bridge. The functional contracts
(1/8/7/base/10 and 42/42/42/patched/42) remain identical; the summary will
record abi_mode: secondary to distinguish from a real arm64 device.

Environment:
  FCB_WORKDIR             Acceptance root. Default: target/fcb/android-arm64-acceptance
  FCB_APP_DIR             Flutter app directory. Default: examples/counter_app
  FCB_ENGINE_SRC_DIR      Engine src root. Default: vendor/flutter/engine/src
  FCB_ENGINE_OUT_NAME     Local Engine output. Default: android_release_arm64
  FCB_FLUTTER_CLEAN       Run flutter clean for the first build. Default: 0
  FCB_SKIP_BUILD          Skip all Flutter builds. Default: 0
  FCB_ADB                 adb path, passed through to the underlying test script.
  FCB_ALLOW_SECONDARY_ABI Accept arm64-v8a as secondary ABI (native-bridge). Default: 0
USAGE
}

adb_cmd() {
  if command -v timeout >/dev/null 2>&1; then
    timeout "$ADB_TIMEOUT_SECONDS" "$ADB" "$@"
  else
    "$ADB" "$@"
  fi
}

run_phase() {
  local name="$1"
  local install_patch="$2"
  local skip_build="$3"
  local flutter_clean="$4"
  local expected_initial="$5"
  local expected_adjusted="$6"
  local expected_static="$7"
  local expected_status="$8"
  local expected_quad="$9"
  local phase_workdir="$WORKDIR/$name"

  echo "== FCB arm64 acceptance: $name =="
  local require_primary=1
  local allow_secondary=0
  if [ "$ALLOW_SECONDARY_ABI" = "1" ]; then
    require_primary=0
    allow_secondary=1
  fi
  FCB_WORKDIR="$phase_workdir" \
    FCB_INSTALL_BYTECODE_PATCH="$install_patch" \
    FCB_SKIP_BUILD="$skip_build" \
    FCB_FLUTTER_CLEAN="$flutter_clean" \
    FCB_REQUIRE_PRIMARY_ABI="$require_primary" \
    FCB_ALLOW_SECONDARY_ABI="$allow_secondary" \
    FCB_EXPECTED_INITIAL_COUNTER="$expected_initial" \
    FCB_EXPECTED_ADJUSTED_COUNTER="$expected_adjusted" \
    FCB_EXPECTED_STATIC_COUNTER="$expected_static" \
    FCB_EXPECTED_STATUS_LABEL="$expected_status" \
    FCB_EXPECTED_QUAD_COUNTER="$expected_quad" \
    FCB_PATCH_RETURN_VALUE=42 \
    FCB_PATCH_STRING_VALUE=patched \
    FCB_INCLUDE_ARG_FUNCTION_PATCH=1 \
    FCB_INCLUDE_STATIC_METHOD_PATCH=1 \
    FCB_INCLUDE_STRING_FUNCTION_PATCH=1 \
    FCB_INCLUDE_QUAD_FUNCTION_PATCH=1 \
    "$TEST_SCRIPT"
  echo "logcat: $phase_workdir/logs/logcat.txt"
}

file_summary() {
  local label="$1"
  local path="$2"
  [ -f "$path" ] || {
    echo "${label}_path: $path"
    echo "${label}_missing: true"
    return 1
  }
  echo "${label}_path: $path"
  echo "${label}_sha256: $(sha256sum "$path" | awk '{print $1}')"
  echo "${label}_file: $(file "$path")"
}

log_result_value() {
  local log_file="$1"
  local label="$2"
  local line
  line="$(grep -F "FCB $label result:" "$log_file" | tail -n 1)"
  [ -n "$line" ] || return 1
  printf '%s\n' "${line##*FCB $label result: }"
}

result_field() {
  local result_file="$1"
  local key="$2"
  local line
  line="$(grep -F "$key: " "$result_file" | tail -n 1)"
  [ -n "$line" ] || return 1
  printf '%s\n' "${line#"$key: "}"
}

assert_result_field() {
  local result_file="$1"
  local key="$2"
  local expected="$3"
  local actual
  actual="$(result_field "$result_file" "$key")" || {
    echo "error: missing '$key' in $result_file" >&2
    return 1
  }
  if [ "$actual" != "$expected" ]; then
    echo "error: $result_file has $key '$actual', expected '$expected'" >&2
    return 1
  fi
}

assert_phase_result() {
  local phase="$1"
  local expected_mode="$2"
  local expected_initial="$3"
  local expected_adjusted="$4"
  local expected_static="$5"
  local expected_status="$6"
  local expected_quad="$7"
  local result_file="$WORKDIR/$phase/result.txt"

  [ -f "$result_file" ] || {
    echo "error: missing phase result file: $result_file" >&2
    return 1
  }

  assert_result_field "$result_file" mode "$expected_mode"
  assert_result_field "$result_file" initialCounterValue_expected "$expected_initial"
  assert_result_field "$result_file" initialCounterValue_observed "$expected_initial"
  assert_result_field "$result_file" adjustedCounterValue_expected "$expected_adjusted"
  assert_result_field "$result_file" adjustedCounterValue_observed "$expected_adjusted"
  assert_result_field "$result_file" staticCounterValue_expected "$expected_static"
  assert_result_field "$result_file" staticCounterValue_observed "$expected_static"
  assert_result_field "$result_file" statusLabel_expected "$expected_status"
  assert_result_field "$result_file" statusLabel_observed "$expected_status"
  assert_result_field "$result_file" quadCounterValue_expected "$expected_quad"
  assert_result_field "$result_file" quadCounterValue_observed "$expected_quad"
}

phase_observed_summary() {
  local phase="$1"
  local log_file="$WORKDIR/$phase/logs/logcat.txt"
  [ -f "$log_file" ] || {
    echo "${phase}_logcat_missing: true"
    return 1
  }
  echo "${phase}_observed: $(log_result_value "$log_file" initialCounterValue)/$(log_result_value "$log_file" adjustedCounterValue)/$(log_result_value "$log_file" staticCounterValue)/$(log_result_value "$log_file" statusLabel)/$(log_result_value "$log_file" quadCounterValue)"
}

phase_result_summary() {
  local phase="$1"
  local result_file="$WORKDIR/$phase/result.txt"
  [ -f "$result_file" ] || {
    echo "${phase}_result_missing: true"
    return 1
  }
  echo "${phase}_result: $result_file"
  while IFS= read -r line; do
    echo "${phase}_${line}"
  done <"$result_file"
}

write_summary() {
  local summary="$WORKDIR/summary.txt"
  local serial primary_abi abi_list
  local apk="$APP_DIR/build/app/outputs/flutter-apk/app-release.apk"
  local app_so="$APP_DIR/build/app/intermediates/flutter/release/arm64-v8a/app.so"
  local libflutter_so="$ENGINE_SRC_DIR/out/$ENGINE_OUT_NAME/libflutter.so"
  serial="$(adb_cmd get-serialno | tr -d '\r[:space:]')"
  primary_abi="$(adb_cmd shell getprop ro.product.cpu.abi | tr -d '\r[:space:]')"
  abi_list="$(adb_cmd shell getprop ro.product.cpu.abilist | tr -d '\r[:space:]')"

  local abi_mode="primary"
  if [ "$ALLOW_SECONDARY_ABI" = "1" ] && [ "${primary_abi:-}" != "arm64-v8a" ]; then
    abi_mode="secondary"
  fi

  {
    echo "FCB Android arm64 acceptance passed"
    echo "serial: ${serial:-unknown}"
    echo "primary_abi: ${primary_abi:-unknown}"
    echo "abilist: ${abi_list:-unknown}"
    echo "abi_mode: $abi_mode"
    echo "nopatch_expected: 1/8/7/base/10"
    echo "nopatch_logcat: $WORKDIR/nopatch/logs/logcat.txt"
    phase_observed_summary "nopatch"
    phase_result_summary "nopatch"
    echo "patch_expected: 42/42/42/patched/42"
    echo "patch_logcat: $WORKDIR/patch/logs/logcat.txt"
    phase_observed_summary "patch"
    phase_result_summary "patch"
    file_summary "apk" "$apk"
    file_summary "app_so" "$app_so"
    file_summary "libflutter_so" "$libflutter_so"
  } >"$summary"

  echo "summary: $summary"
}

main() {
  if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
    usage
    exit 0
  fi

  mkdir -p "$WORKDIR"
  FCB_ALLOW_SECONDARY_ABI="$ALLOW_SECONDARY_ABI" "$DEVICE_CHECK_SCRIPT"

  local skip_build="${FCB_SKIP_BUILD:-0}"
  local first_clean="${FCB_FLUTTER_CLEAN:-0}"
  local second_skip_build=1
  if [ "$skip_build" = "1" ]; then
    second_skip_build=1
  fi

  run_phase "nopatch" 0 "$skip_build" "$first_clean" "1" "8" "7" "base" "10"
  assert_phase_result "nopatch" "nopatch" "1" "8" "7" "base" "10"
  run_phase "patch" 1 "$second_skip_build" 0 "42" "42" "42" "patched" "42"
  assert_phase_result "patch" "patch" "42" "42" "42" "patched" "42"

  write_summary
  echo "FCB Android arm64 acceptance passed."
  echo "workdir: $WORKDIR"
}

main "$@"
