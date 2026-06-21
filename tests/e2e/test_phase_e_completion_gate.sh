#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT="$ROOT_DIR/scripts/check_phase_e_completion.sh"
WORKDIR="$(mktemp -d /tmp/fcb_phase_e_completion_gate_XXXXXX)"

cleanup() {
  if [ "${FCB_KEEP_PHASE_E_COMPLETION_GATE_TEST:-0}" = "1" ]; then
    echo "keeping workdir: $WORKDIR" >&2
  else
    rm -rf "$WORKDIR"
  fi
}
trap cleanup EXIT

die() {
  echo "error: $*" >&2
  exit 1
}

require_line() {
  local file="$1"
  local pattern="$2"
  grep -Fq "$pattern" "$file" || die "$file missing: $pattern"
}

write_common_evidence() {
  local android_summary="$1"
  local patch_logcat="$2"
  local desktop_summary="$3"

  mkdir -p "$(dirname "$android_summary")" "$(dirname "$patch_logcat")" "$(dirname "$desktop_summary")"
  cat >"$android_summary" <<EOF
FCB Android arm64 acceptance passed
abi_mode: primary
nopatch_observed: 1/8/7/base/baseline widget tree/base-field/10
patch_observed: 42/42/42/patched/patched widget tree/patched-field/42
patch_setState_observed: true
patch_logcat: $patch_logcat
interpret_failure_summary: $WORKDIR/android/interpret-failure/summary.txt
interpret_failure_FCB Android interpret-failure drill passed
EOF
  echo "FCB desktop embedder full target validation passed" >"$desktop_summary"
}

run_case() {
  local name="$1"
  local expected_exit="$2"
  local expected_line="$3"
  local stats_line="${4:-}"

  local case_dir="$WORKDIR/$name"
  local android_summary="$case_dir/android-summary.txt"
  local patch_logcat="$case_dir/patch/logcat.txt"
  local desktop_summary="$case_dir/desktop-summary.txt"
  local out_dir="$case_dir/out"
  local host_check="$case_dir/host-check.sh"
  local device_check="$case_dir/device-check.sh"

  mkdir -p "$case_dir"
  cat >"$host_check" <<'SH'
#!/usr/bin/env bash
exit 0
SH
  cat >"$device_check" <<'SH'
#!/usr/bin/env bash
exit 0
SH
  chmod +x "$host_check" "$device_check"
  write_common_evidence "$android_summary" "$patch_logcat" "$desktop_summary"
  if [ -n "$stats_line" ]; then
    echo "I/flutter: FCB interpreterStats result: $stats_line" >"$patch_logcat"
  else
    : >"$patch_logcat"
  fi

  set +e
  FCB_PHASE_E_COMPLETION_DIR="$out_dir" \
  FCB_PHASE_E_HOST_EVIDENCE_CHECK="$host_check" \
  FCB_PHASE_E_ANDROID_DEVICE_CHECK="$device_check" \
  FCB_PHASE_E_ANDROID_SUMMARY="$android_summary" \
  FCB_PHASE_E_DESKTOP_SUMMARY="$desktop_summary" \
  FCB_PHASE_E_MAX_INTERPRETER_RATIO=0.01 \
    "$SCRIPT" >"$case_dir/stdout.txt" 2>"$case_dir/stderr.txt"
  local status=$?
  set -e

  if [ "$status" -ne "$expected_exit" ]; then
    echo "stdout:" >&2
    cat "$case_dir/stdout.txt" >&2 || true
    echo "stderr:" >&2
    cat "$case_dir/stderr.txt" >&2 || true
    die "$name exited $status, expected $expected_exit"
  fi
  require_line "$out_dir/summary.txt" "$expected_line"
}

run_case ratio_pass 0 "android_interpreter_ratio: pass" "0/100/0.000000"
run_case ratio_no_samples 1 "Android interpreter stats has no samples: 0/0/0.000000" "0/0/0.000000"
run_case ratio_too_high 1 "Android interpreter ratio 0.020000 exceeds max 0.01" "2/100/0.020000"
run_case ratio_missing 1 "Android interpreter stats missing in patch logcat" "unavailable"

echo "Phase E completion gate test passed"
echo "workdir: $WORKDIR"
