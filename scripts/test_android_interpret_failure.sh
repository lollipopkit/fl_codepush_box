#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORKDIR="${FCB_WORKDIR:-$ROOT_DIR/target/fcb/android-interpret-failure}"
TEST_ANDROID_SCRIPT="${FCB_TEST_ANDROID_SCRIPT:-$ROOT_DIR/scripts/test_android.sh}"
ADB="${FCB_ADB:-$ROOT_DIR/vendor/flutter/engine/src/flutter/third_party/android_tools/sdk/platform-tools/adb}"
ADB_TIMEOUT_SECONDS="${FCB_ADB_TIMEOUT_SECONDS:-30}"
MAX_INTERPRETER_RATIO="${FCB_MAX_INTERPRETER_RATIO:-0.01}"
PKG="${FCB_ANDROID_PACKAGE:-com.example.fcb_counter_app}"
PATCH_NUMBER="${FCB_PATCH_NUMBER:-1}"
SUMMARY_FILE="$WORKDIR/summary.txt"
STATE_FILE="$WORKDIR/state-after-failure.json"
SERVER_DB="${FCB_SERVER_DB:-}"
SERVER_EVENT_FILE="$WORKDIR/server-crash-rollback-event.json"
SERVER_URL="${FCB_SERVER_URL:-}"
APP_ID="${FCB_APP_ID:-}"
PUBLIC_KEY="${FCB_PUBLIC_KEY:-}"
RELEASE_VERSION="${FCB_RELEASE_VERSION:-1.0.0+1}"
CHANNEL="${FCB_CHANNEL:-stable}"
PLATFORM="${FCB_PLATFORM:-android}"
ARCH="${FCB_ARCH:-arm64-v8a}"

case "$WORKDIR" in
  /*) ;;
  *) WORKDIR="$ROOT_DIR/$WORKDIR" ;;
esac

usage() {
  cat <<USAGE
Usage:
  $0

Runs an Android arm64 VM interpret-failure drill:
  1. builds/installs counter_app through scripts/test_android.sh
  2. installs a bytecode patch whose initialCounterValue function returns from
     an empty stack at interpretation time
  3. verifies the app does not crash and falls back to baseline results
  4. verifies device state marks the patch as bad

Environment:
  FCB_WORKDIR              Drill output root. Default: target/fcb/android-interpret-failure
  FCB_TEST_ANDROID_SCRIPT  Android test script. Default: scripts/test_android.sh
  FCB_ADB                  adb path. Default: Engine Android SDK adb
  FCB_ADB_TIMEOUT_SECONDS  adb command timeout in seconds. Default: 30
  FCB_ANDROID_PACKAGE      Android package. Default: com.example.fcb_counter_app
  FCB_PATCH_NUMBER         Patch number to install. Default: 1
  FCB_SKIP_BUILD           Passed through to scripts/test_android.sh. Default: 0
  FCB_FLUTTER_CLEAN        Passed through to scripts/test_android.sh. Default: 1
  FCB_SERVER_URL           Optional server URL passed to counter_app.
  FCB_APP_ID               Optional app id passed to counter_app.
  FCB_PUBLIC_KEY           Optional Ed25519 public key passed to counter_app.
  FCB_RELEASE_VERSION      Release version passed to counter_app. Default: 1.0.0+1
  FCB_CHANNEL              Channel passed to counter_app. Default: stable
  FCB_PLATFORM             Platform passed to counter_app. Default: android
  FCB_ARCH                 Arch passed to counter_app. Default: arm64-v8a
  FCB_MAX_INTERPRETER_RATIO
                            Max interpreter ratio for the failing patch launch. Default: 0.01
  FCB_SERVER_DB            Optional sqlite DB path; when set, verifies patch_events has crash_rollback.
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

require_file() {
  [ -f "$1" ] || die "missing file: $1"
}

adb_cmd() {
  if command -v timeout >/dev/null 2>&1; then
    timeout "$ADB_TIMEOUT_SECONDS" "$ADB" "$@"
  elif command -v python3 >/dev/null 2>&1; then
    python3 - "$ADB" "$ADB_TIMEOUT_SECONDS" "$@" <<'PY'
import subprocess
import sys

adb = sys.argv[1]
timeout = float(sys.argv[2])
cmd = [adb] + sys.argv[3:]
try:
    result = subprocess.run(cmd, timeout=timeout)
except subprocess.TimeoutExpired:
    print(
        "error: adb command timed out after %gs: %s" %
        (timeout, " ".join(cmd)),
        file=sys.stderr,
    )
    sys.exit(124)
sys.exit(result.returncode)
PY
  else
    "$ADB" "$@"
  fi
}

read_device_state() {
  local cache_dir="/data/user/0/$PKG/code_cache/fcb"
  adb_cmd root >/dev/null 2>&1 || true
  adb_cmd wait-for-device
  adb_cmd shell "cat '$cache_dir/state.json'" | tr -d '\r' >"$STATE_FILE"
}

assert_state_bad_patch() {
  python3 - "$STATE_FILE" "$PATCH_NUMBER" <<'PY'
import json
import sys

state_path = sys.argv[1]
patch_number = int(sys.argv[2])
with open(state_path, "r", encoding="utf-8") as f:
    state = json.load(f)
bad = state.get("bad_patches", [])
if patch_number not in bad:
    raise SystemExit(f"patch {patch_number} missing from bad_patches: {bad}")
if state.get("pending_patch_number") == patch_number:
    raise SystemExit(f"patch {patch_number} is still pending: {state}")
last = state.get("last_launch") or {}
if last.get("patch_number") != patch_number:
    raise SystemExit(f"last_launch did not record patch {patch_number}: {last}")
status = last.get("status", "")
if "interpret_failure:" not in status:
    raise SystemExit(f"last_launch status is not an interpret failure: {status}")
PY
}

assert_server_crash_rollback_event() {
  [ -n "$SERVER_DB" ] || return 0
  require_file "$SERVER_DB"
  [ -n "$APP_ID" ] || die "FCB_SERVER_DB verification requires FCB_APP_ID"

  local attempt
  for attempt in $(seq 1 30); do
    if python3 - "$SERVER_DB" "$SERVER_EVENT_FILE" "$APP_ID" "$RELEASE_VERSION" "$PLATFORM" "$ARCH" "$PATCH_NUMBER" <<'PY'
import json
import sqlite3
import sys

db_path, out_path, app_id, release_version, platform, arch, patch_number = sys.argv[1:]
conn = sqlite3.connect(db_path)
conn.row_factory = sqlite3.Row
row = conn.execute(
    """
    select app_id, release_version, platform, arch, patch_number, event_type,
           client_id_hash, payload, created_at
      from patch_events
     where app_id = ?
       and release_version = ?
       and platform = ?
       and arch = ?
       and patch_number = ?
       and event_type = 'crash_rollback'
     order by id desc
     limit 1
    """,
    (app_id, release_version, platform, arch, int(patch_number)),
).fetchone()
conn.close()
if row is None:
    raise SystemExit(1)
event = dict(row)
payload = event.get("payload")
if payload:
    event["payload"] = json.loads(payload)
with open(out_path, "w", encoding="utf-8") as f:
    json.dump(event, f, ensure_ascii=False, indent=2, sort_keys=True)
    f.write("\n")
PY
    then
      return 0
    fi
    sleep 0.5
  done
  die "server patch_events did not record crash_rollback for app=$APP_ID patch=$PATCH_NUMBER"
}

main() {
  if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
    usage
    exit 0
  fi

  require_file "$TEST_ANDROID_SCRIPT"
  require_file "$ADB"
  mkdir -p "$WORKDIR"

  FCB_WORKDIR="$WORKDIR/device" \
  FCB_ADB="$ADB" \
  FCB_ADB_TIMEOUT_SECONDS="$ADB_TIMEOUT_SECONDS" \
  FCB_ANDROID_PACKAGE="$PKG" \
  FCB_INSTALL_BYTECODE_PATCH=1 \
  FCB_PATCH_NUMBER="$PATCH_NUMBER" \
  FCB_PATCH_CODE_KIND=return_underflow \
  FCB_MAX_INTERPRETER_RATIO="$MAX_INTERPRETER_RATIO" \
  FCB_INCLUDE_ARG_FUNCTION_PATCH=0 \
  FCB_INCLUDE_STATIC_METHOD_PATCH=0 \
  FCB_INCLUDE_STRING_FUNCTION_PATCH=0 \
  FCB_INCLUDE_FIELD_FUNCTION_PATCH=0 \
  FCB_INCLUDE_QUAD_FUNCTION_PATCH=0 \
  FCB_EXPECTED_INITIAL_COUNTER=1 \
  FCB_EXPECTED_ADJUSTED_COUNTER=8 \
  FCB_EXPECTED_STATIC_COUNTER=7 \
  FCB_EXPECTED_STATUS_LABEL=base \
  FCB_EXPECTED_WIDGET_TREE_LABEL="baseline widget tree" \
  FCB_EXPECTED_FIELD_STATUS_LABEL=base-field \
  FCB_EXPECTED_QUAD_COUNTER=10 \
  FCB_SERVER_URL="$SERVER_URL" \
  FCB_APP_ID="$APP_ID" \
  FCB_PUBLIC_KEY="$PUBLIC_KEY" \
  FCB_RELEASE_VERSION="$RELEASE_VERSION" \
  FCB_CHANNEL="$CHANNEL" \
  FCB_PLATFORM="$PLATFORM" \
  FCB_ARCH="$ARCH" \
  run "$TEST_ANDROID_SCRIPT"

  read_device_state
  assert_state_bad_patch
  assert_server_crash_rollback_event

  {
    echo "FCB Android interpret-failure drill passed"
    echo "workdir: $WORKDIR"
    echo "device_result: $WORKDIR/device/result.txt"
    echo "device_logcat: $WORKDIR/device/logs/logcat.txt"
    echo "state_after_failure: $STATE_FILE"
    echo "patch_number: $PATCH_NUMBER"
    echo "baseline_observed_after_failure: 1/8/7/base/baseline widget tree/base-field/10"
    echo "bad_patch_recorded: true"
    if [ -n "$SERVER_DB" ]; then
      echo "server_events_evidence: $SERVER_EVENT_FILE"
      echo "server_crash_rollback_recorded: true"
    fi
  } >"$SUMMARY_FILE"
  echo "summary: $SUMMARY_FILE"
}

main "$@"
