#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STAMP="${FCB_VM_PATCH_ARCHIVE_STAMP:-$(date +%Y%m%d_%H%M%S)}"
ARCHIVE_DIR="${FCB_VM_PATCH_ARCHIVE_DIR:-$ROOT_DIR/tests/e2e/vm_patch_$STAMP}"
STATUS="${FCB_VM_PATCH_STATUS:-}"
PLATFORM="${FCB_VM_PATCH_PLATFORM:-}"
APP_ID="${FCB_VM_PATCH_APP_ID:-counter_app}"
PATCH_NUMBER="${FCB_VM_PATCH_PATCH_NUMBER:-}"
SCENARIO="${FCB_VM_PATCH_SCENARIO:-}"
BASELINE_EVIDENCE="${FCB_VM_PATCH_BASELINE_EVIDENCE:-}"
PATCHED_UI_EVIDENCE="${FCB_VM_PATCH_PATCHED_UI_EVIDENCE:-}"
RESTART_EVIDENCE="${FCB_VM_PATCH_RESTART_EVIDENCE:-}"
VM_LOG_EVIDENCE="${FCB_VM_PATCH_VM_LOG_EVIDENCE:-}"
PAYLOAD_INSPECT_EVIDENCE="${FCB_VM_PATCH_PAYLOAD_INSPECT_EVIDENCE:-}"
SERVER_EVENTS_EVIDENCE="${FCB_VM_PATCH_SERVER_EVENTS_EVIDENCE:-}"
NOTES="${FCB_VM_PATCH_NOTES:-}"

usage() {
  cat <<USAGE
Usage:
  FCB_VM_PATCH_STATUS=passed \\
  FCB_VM_PATCH_PLATFORM=<android-arm64|ios-arm64|...> \\
  FCB_VM_PATCH_PATCH_NUMBER=<number> \\
  FCB_VM_PATCH_SCENARIO=widget_tree_setState_method_channel \\
  FCB_VM_PATCH_BASELINE_EVIDENCE=<file> \\
  FCB_VM_PATCH_PATCHED_UI_EVIDENCE=<file> \\
  FCB_VM_PATCH_RESTART_EVIDENCE=<file> \\
  FCB_VM_PATCH_VM_LOG_EVIDENCE=<file> \\
  FCB_VM_PATCH_PAYLOAD_INSPECT_EVIDENCE=<file> \\
  FCB_VM_PATCH_SERVER_EVENTS_EVIDENCE=<file> \\
    $0

Records Phase E counter_app real VM patch evidence into
tests/e2e/vm_patch_<timestamp>. This script does not run devices or build
patches. It only writes the completion marker consumed by
make audit-plan-completion after a real VM interpreted patch has passed.

Environment:
  FCB_VM_PATCH_ARCHIVE_DIR             Archive dir override.
  FCB_VM_PATCH_ARCHIVE_STAMP           Timestamp suffix for default dir.
  FCB_VM_PATCH_STATUS                  Must be exactly "passed".
  FCB_VM_PATCH_PLATFORM                Required platform label.
  FCB_VM_PATCH_APP_ID                  App id. Default: counter_app.
  FCB_VM_PATCH_PATCH_NUMBER            Required patch number.
  FCB_VM_PATCH_SCENARIO                Must be widget_tree_setState_method_channel.
  FCB_VM_PATCH_BASELINE_EVIDENCE       Required baseline/release evidence.
  FCB_VM_PATCH_PATCHED_UI_EVIDENCE     Required patched widget tree evidence.
  FCB_VM_PATCH_RESTART_EVIDENCE        Required restart/LKG evidence.
  FCB_VM_PATCH_VM_LOG_EVIDENCE         Required VM interpreter/engine log.
  FCB_VM_PATCH_PAYLOAD_INSPECT_EVIDENCE Required payload inspect/source map/call_static/get_field evidence.
  FCB_VM_PATCH_SERVER_EVENTS_EVIDENCE  Required server event evidence with interpreter_ratio < 0.01.
  FCB_VM_PATCH_NOTES                   Optional notes or issue URL.
USAGE
}

die() {
  echo "error: $*" >&2
  exit 1
}

require_value() {
  local name="$1"
  local value="$2"
  [ -n "$value" ] || die "$name is required"
}

require_file() {
  local path="$1"
  [ -f "$path" ] || die "missing file: $path"
  [ -s "$path" ] || die "empty file: $path"
}

require_file_contains() {
  local file="$1"
  local pattern="$2"
  grep -Fq "$pattern" "$file" || die "evidence file $file must contain: $pattern"
}

require_interpreter_ratio_below_one_percent() {
  local file="$1"
  local ratio
  ratio="$(grep -Eo '"interpreter_ratio"[[:space:]]*:[[:space:]]*[0-9]+(\.[0-9]+)?' "$file" \
    | head -1 \
    | sed -E 's/.*:[[:space:]]*//')"
  [ -n "$ratio" ] || die "evidence file $file must contain a numeric interpreter_ratio"
  awk -v ratio="$ratio" 'BEGIN { exit !(ratio >= 0 && ratio < 0.01) }' \
    || die "evidence file $file must show interpreter_ratio < 0.01, got $ratio"
}

copy_evidence() {
  local source="$1"
  local label="$2"
  local basename
  basename="$(basename "$source")"
  cp "$source" "$ARCHIVE_DIR/evidence/$label-$basename"
  echo "evidence/$label-$basename"
}

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
  usage
  exit 0
fi

[ "$STATUS" = "passed" ] || die "FCB_VM_PATCH_STATUS must be exactly 'passed'"
require_value "FCB_VM_PATCH_PLATFORM" "$PLATFORM"
require_value "FCB_VM_PATCH_PATCH_NUMBER" "$PATCH_NUMBER"
[ "$SCENARIO" = "widget_tree_setState_method_channel" ] \
  || die "FCB_VM_PATCH_SCENARIO must be exactly 'widget_tree_setState_method_channel'"
require_value "FCB_VM_PATCH_BASELINE_EVIDENCE" "$BASELINE_EVIDENCE"
require_value "FCB_VM_PATCH_PATCHED_UI_EVIDENCE" "$PATCHED_UI_EVIDENCE"
require_value "FCB_VM_PATCH_RESTART_EVIDENCE" "$RESTART_EVIDENCE"
require_value "FCB_VM_PATCH_VM_LOG_EVIDENCE" "$VM_LOG_EVIDENCE"
require_value "FCB_VM_PATCH_PAYLOAD_INSPECT_EVIDENCE" "$PAYLOAD_INSPECT_EVIDENCE"
require_value "FCB_VM_PATCH_SERVER_EVENTS_EVIDENCE" "$SERVER_EVENTS_EVIDENCE"

require_file "$BASELINE_EVIDENCE"
require_file "$PATCHED_UI_EVIDENCE"
require_file "$RESTART_EVIDENCE"
require_file "$VM_LOG_EVIDENCE"
require_file "$PAYLOAD_INSPECT_EVIDENCE"
require_file "$SERVER_EVENTS_EVIDENCE"
require_file_contains "$BASELINE_EVIDENCE" "baseline counter_app release rendered"
require_file_contains "$PATCHED_UI_EVIDENCE" "patched widget tree"
require_file_contains "$PATCHED_UI_EVIDENCE" "widgetTreeLabel_observed: patched widget tree"
require_file_contains "$PATCHED_UI_EVIDENCE" "setState"
require_file_contains "$PATCHED_UI_EVIDENCE" "setState_observed: true"
require_file_contains "$PATCHED_UI_EVIDENCE" "method channel"
require_file_contains "$PATCHED_UI_EVIDENCE" "methodChannelCacheDir_observed:"
require_file_contains "$RESTART_EVIDENCE" "restart kept patch active"
require_file_contains "$VM_LOG_EVIDENCE" "FCB VM interpreter executed patch function"
require_file_contains "$PAYLOAD_INSPECT_EVIDENCE" "FCBM"
require_file_contains "$PAYLOAD_INSPECT_EVIDENCE" "source_map"
require_file_contains "$PAYLOAD_INSPECT_EVIDENCE" "uses_call_static"
require_file_contains "$PAYLOAD_INSPECT_EVIDENCE" "uses_get_field"
require_file_contains "$PAYLOAD_INSPECT_EVIDENCE" "true"
require_file_contains "$SERVER_EVENTS_EVIDENCE" "launch_success"
require_file_contains "$SERVER_EVENTS_EVIDENCE" "interpreter_ratio"
require_interpreter_ratio_below_one_percent "$SERVER_EVENTS_EVIDENCE"

if [ -e "$ARCHIVE_DIR" ]; then
  die "archive dir already exists: $ARCHIVE_DIR"
fi
mkdir -p "$ARCHIVE_DIR/evidence"

baseline_copy="$(copy_evidence "$BASELINE_EVIDENCE" "baseline")"
patched_ui_copy="$(copy_evidence "$PATCHED_UI_EVIDENCE" "patched-ui")"
restart_copy="$(copy_evidence "$RESTART_EVIDENCE" "restart")"
vm_log_copy="$(copy_evidence "$VM_LOG_EVIDENCE" "vm-log")"
payload_copy="$(copy_evidence "$PAYLOAD_INSPECT_EVIDENCE" "payload-inspect")"
events_copy="$(copy_evidence "$SERVER_EVENTS_EVIDENCE" "server-events")"

{
  echo "FCB counter_app real VM patch evidence"
  echo "Counter app real VM patch passed"
  echo "status: $STATUS"
  echo "platform: $PLATFORM"
  echo "app_id: $APP_ID"
  echo "patch_number: $PATCH_NUMBER"
  echo "scenario: $SCENARIO"
  echo "baseline_evidence: $baseline_copy"
  echo "patched_ui_evidence: $patched_ui_copy"
  echo "restart_evidence: $restart_copy"
  echo "vm_log_evidence: $vm_log_copy"
  echo "payload_inspect_evidence: $payload_copy"
  echo "server_events_evidence: $events_copy"
  if [ -n "$NOTES" ]; then
    echo "notes: $NOTES"
  fi
} >"$ARCHIVE_DIR/summary.txt"

echo "VM patch evidence recorded: $ARCHIVE_DIR/summary.txt"
