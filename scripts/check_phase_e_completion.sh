#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="${FCB_PHASE_E_COMPLETION_DIR:-$ROOT_DIR/target/fcb/phase-e-completion}"
HOST_EVIDENCE_CHECK="${FCB_PHASE_E_HOST_EVIDENCE_CHECK:-$ROOT_DIR/scripts/check_phase_e_host_evidence.sh}"
ANDROID_DEVICE_CHECK="${FCB_PHASE_E_ANDROID_DEVICE_CHECK:-$ROOT_DIR/scripts/check_android_arm64_device.sh}"
ANDROID_SUMMARY="${FCB_PHASE_E_ANDROID_SUMMARY:-$ROOT_DIR/target/fcb/android-arm64-acceptance/summary.txt}"
DESKTOP_SUMMARY="${FCB_PHASE_E_DESKTOP_SUMMARY:-$ROOT_DIR/target/fcb/desktop-embedder-full/summary.txt}"
MAX_INTERPRETER_RATIO="${FCB_PHASE_E_MAX_INTERPRETER_RATIO:-1.0}"
SUMMARY="$OUT_DIR/summary.txt"

usage() {
  cat <<USAGE
Usage:
  $0

Audits the full Phase E completion evidence. This is stricter than the host
evidence gate: it requires current Android device availability, Android
counter_app acceptance evidence, fallback/interpret-failure evidence, and the
full desktop embedder target evidence. It writes a status summary even when
completion is still pending.

Summary fields:
  host_evidence              Host VM/Kernel evidence gate status.
  android_device_preflight   Current adb/device availability status.
  android_acceptance         counter_app Android acceptance evidence status.
  android_interpret_failure  interpret-failure fallback evidence status.
  android_interpreter_ratio  Android patch interpreter ratio threshold status.
  desktop_embedder_full      Full desktop embedder target evidence status.

Environment:
  FCB_PHASE_E_COMPLETION_DIR      Output dir. Default: target/fcb/phase-e-completion
  FCB_PHASE_E_HOST_EVIDENCE_CHECK Host evidence check script.
  FCB_PHASE_E_ANDROID_DEVICE_CHECK Android arm64 preflight script.
  FCB_PHASE_E_ANDROID_SUMMARY     Android acceptance summary.
  FCB_PHASE_E_DESKTOP_SUMMARY     Desktop embedder full summary.
  FCB_PHASE_E_MAX_INTERPRETER_RATIO
                                      Max accepted Android patch interpreter ratio. Default: 1.0.
USAGE
}

require_line_silent() {
  local file="$1"
  local pattern="$2"
  [ -s "$file" ] && grep -Fq "$pattern" "$file"
}

summary_value() {
  local file="$1"
  local key="$2"
  [ -s "$file" ] || return 1
  awk -v key="$key" '
    index($0, key ": ") == 1 {
      value = substr($0, length(key) + 3)
    }
    END {
      if (value == "") exit 1
      print value
    }
  ' "$file"
}

interpreter_stats_from_logcat() {
  local file="$1"
  [ -s "$file" ] || return 1
  awk '
    index($0, "FCB interpreterStats result: ") {
      value = substr($0, index($0, "FCB interpreterStats result: ") + length("FCB interpreterStats result: "))
    }
    END {
      if (value == "") exit 1
      print value
    }
  ' "$file"
}

ratio_from_interpreter_stats() {
  local stats="$1"
  awk -F/ 'NF >= 3 && $3 != "" { print $3; exit }' <<<"$stats"
}

interpreter_stats_has_samples() {
  local stats="$1"
  awk -F/ 'NF >= 3 && $1 ~ /^[0-9]+$/ && $2 ~ /^[0-9]+$/ { exit ($2 > 0) ? 0 : 1 } { exit 1 }' <<<"$stats"
}

ratio_lte() {
  local ratio="$1"
  local max="$2"
  awk -v ratio="$ratio" -v max="$max" 'BEGIN {
    if (ratio !~ /^[0-9]+([.][0-9]+)?$/ || max !~ /^[0-9]+([.][0-9]+)?$/) exit 2;
    exit (ratio <= max) ? 0 : 1;
  }'
}

write_summary() {
  {
    if [ "$FAILED" -eq 0 ]; then
      echo "Phase E completion evidence passed"
    else
      echo "Phase E completion evidence pending"
    fi
    echo "host_evidence: $HOST_STATUS"
    echo "android_device_preflight: $ANDROID_DEVICE_STATUS"
    echo "android_acceptance: $ANDROID_ACCEPTANCE_STATUS"
    echo "android_interpret_failure: $ANDROID_INTERPRET_FAILURE_STATUS"
    echo "android_interpreter_ratio: $ANDROID_INTERPRETER_RATIO_STATUS"
    echo "android_interpreter_ratio_value: $ANDROID_INTERPRETER_RATIO_VALUE"
    echo "android_interpreter_ratio_max: $MAX_INTERPRETER_RATIO"
    echo "android_interpreter_stats: $ANDROID_INTERPRETER_STATS"
    echo "android_patch_logcat: $ANDROID_PATCH_LOGCAT"
    echo "desktop_embedder_full: $DESKTOP_STATUS"
    echo "host_log: $HOST_LOG"
    echo "android_device_log: $ANDROID_DEVICE_LOG"
    echo "android_summary: $ANDROID_SUMMARY"
    echo "desktop_summary: $DESKTOP_SUMMARY"
    if [ "${#REASONS[@]}" -gt 0 ]; then
      echo "pending_reasons:"
      local reason
      for reason in "${REASONS[@]}"; do
        echo "- $reason"
      done
    fi
  } >"$SUMMARY"
}

mark_failed() {
  FAILED=1
  REASONS+=("$1")
}

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
  usage
  exit 0
fi

mkdir -p "$OUT_DIR"
HOST_LOG="$OUT_DIR/host-evidence.log"
ANDROID_DEVICE_LOG="$OUT_DIR/android-device-preflight.log"
FAILED=0
REASONS=()
HOST_STATUS="fail"
ANDROID_DEVICE_STATUS="fail"
ANDROID_ACCEPTANCE_STATUS="fail"
ANDROID_INTERPRET_FAILURE_STATUS="fail"
ANDROID_INTERPRETER_RATIO_STATUS="fail"
ANDROID_INTERPRETER_RATIO_VALUE="unavailable"
ANDROID_INTERPRETER_STATS="unavailable"
ANDROID_PATCH_LOGCAT="unavailable"
DESKTOP_STATUS="fail"

if [ ! -x "$HOST_EVIDENCE_CHECK" ]; then
  mark_failed "missing host evidence check: $HOST_EVIDENCE_CHECK"
else
  if "$HOST_EVIDENCE_CHECK" >"$HOST_LOG" 2>&1; then
    HOST_STATUS="pass"
  else
    mark_failed "host evidence check failed: $HOST_LOG"
  fi
fi

if [ ! -x "$ANDROID_DEVICE_CHECK" ]; then
  mark_failed "missing Android device check: $ANDROID_DEVICE_CHECK"
else
  if "$ANDROID_DEVICE_CHECK" >"$ANDROID_DEVICE_LOG" 2>&1; then
    ANDROID_DEVICE_STATUS="pass"
  else
    mark_failed "Android device preflight failed: $ANDROID_DEVICE_LOG"
  fi
fi

if require_line_silent "$ANDROID_SUMMARY" "FCB Android arm64 acceptance passed" &&
   require_line_silent "$ANDROID_SUMMARY" "abi_mode: primary" &&
   require_line_silent "$ANDROID_SUMMARY" "nopatch_observed: 1/8/7/base/baseline widget tree/base-field/10" &&
   require_line_silent "$ANDROID_SUMMARY" "patch_observed: 42/42/42/patched/patched widget tree/patched-field/42" &&
   require_line_silent "$ANDROID_SUMMARY" "patch_setState_observed: true"; then
  ANDROID_ACCEPTANCE_STATUS="pass"
else
  mark_failed "Android acceptance summary missing required counter_app evidence: $ANDROID_SUMMARY"
fi

if require_line_silent "$ANDROID_SUMMARY" "interpret_failure_summary:" &&
   require_line_silent "$ANDROID_SUMMARY" "interpret_failure_FCB Android interpret-failure drill passed"; then
  ANDROID_INTERPRET_FAILURE_STATUS="pass"
else
  mark_failed "Android interpret-failure fallback evidence missing: $ANDROID_SUMMARY"
fi

if ANDROID_PATCH_LOGCAT="$(summary_value "$ANDROID_SUMMARY" "patch_logcat")"; then
  if [ ! -s "$ANDROID_PATCH_LOGCAT" ]; then
    mark_failed "Android patch logcat missing: $ANDROID_PATCH_LOGCAT"
  elif ANDROID_INTERPRETER_STATS="$(interpreter_stats_from_logcat "$ANDROID_PATCH_LOGCAT")" &&
       ANDROID_INTERPRETER_RATIO_VALUE="$(ratio_from_interpreter_stats "$ANDROID_INTERPRETER_STATS")" &&
       [ -n "$ANDROID_INTERPRETER_RATIO_VALUE" ]; then
    if ! interpreter_stats_has_samples "$ANDROID_INTERPRETER_STATS"; then
      mark_failed "Android interpreter stats has no samples: $ANDROID_INTERPRETER_STATS"
    elif ratio_lte "$ANDROID_INTERPRETER_RATIO_VALUE" "$MAX_INTERPRETER_RATIO"; then
      ANDROID_INTERPRETER_RATIO_STATUS="pass"
    else
      mark_failed "Android interpreter ratio $ANDROID_INTERPRETER_RATIO_VALUE exceeds max $MAX_INTERPRETER_RATIO"
    fi
  else
    mark_failed "Android interpreter stats missing in patch logcat: $ANDROID_PATCH_LOGCAT"
  fi
else
  mark_failed "Android acceptance summary missing patch_logcat: $ANDROID_SUMMARY"
fi

if require_line_silent "$DESKTOP_SUMMARY" "FCB desktop embedder full target validation passed"; then
  DESKTOP_STATUS="pass"
else
  mark_failed "desktop embedder full target evidence missing or failed: $DESKTOP_SUMMARY"
fi

write_summary
cat "$SUMMARY"

if [ "$FAILED" -ne 0 ]; then
  exit 1
fi
