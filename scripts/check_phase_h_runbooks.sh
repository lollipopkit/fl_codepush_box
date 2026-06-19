#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORKDIR="${FCB_PHASE_H_RUNBOOK_WORKDIR:-$(mktemp -d "${TMPDIR:-/tmp}/fcb-phase-h-runbooks.XXXXXX")}"
KEEP_WORKDIR="${FCB_PHASE_H_RUNBOOK_KEEP_WORKDIR:-0}"

case "$WORKDIR" in
  /*) ;;
  *) WORKDIR="$ROOT_DIR/$WORKDIR" ;;
esac

cleanup() {
  if [ "$KEEP_WORKDIR" != "1" ]; then
    rm -rf "$WORKDIR"
  else
    echo "kept workdir: $WORKDIR"
  fi
}
trap cleanup EXIT

die() {
  echo "error: $*" >&2
  exit 1
}

fake_script() {
  local path="$1"
  local label="$2"
  cat >"$path" <<EOF
#!/usr/bin/env bash
set -euo pipefail
mkdir -p "\${FCB_WORKDIR:-$WORKDIR/$label}"
echo "$label passed" >"\${FCB_WORKDIR:-$WORKDIR/$label}/summary.txt"
EOF
  chmod +x "$path"
}

assert_contains() {
  local file="$1"
  local pattern="$2"
  grep -Fq -- "$pattern" "$file" || die "$file does not contain: $pattern"
}

assert_not_contains() {
  local file="$1"
  local pattern="$2"
  if grep -Fq -- "$pattern" "$file"; then
    die "$file still contains obsolete pattern: $pattern"
  fi
}

mkdir -p "$WORKDIR"

FAKE_ACCEPT="$WORKDIR/fake_accept_android_arm64.sh"
FAKE_CRASH="$WORKDIR/fake_crash_rollback.sh"
FAKE_IOS_BUILD="$WORKDIR/fake_build_ios_engine.sh"
FAKE_IOS_SIM="$WORKDIR/fake_test_ios_sim.sh"

fake_script "$FAKE_ACCEPT" "device-acceptance"
fake_script "$FAKE_CRASH" "host-crash-rollback"
fake_script "$FAKE_IOS_BUILD" "ios-build"
fake_script "$FAKE_IOS_SIM" "ios-sim-preflight"

ARM_WORKDIR="$WORKDIR/arm64"
FCB_WORKDIR="$ARM_WORKDIR" \
FCB_ARCHIVE_DIR="$WORKDIR/arm64-archive" \
FCB_ACCEPT_SCRIPT="$FAKE_ACCEPT" \
FCB_HOST_CRASH_ROLLBACK_SCRIPT="$FAKE_CRASH" \
FCB_SKIP_ARCHIVE=1 \
FCB_SERVER_URL="https://updates.example.invalid" \
FCB_APP_ID="00000000-0000-0000-0000-0000000000a1" \
FCB_CLI_TOKEN="test-token" \
FCB_FLUTTER="/opt/flutter/bin/flutter" \
  "$ROOT_DIR/scripts/full_arm64_drill.sh" >/dev/null

ARM_COMMANDS="$ARM_WORKDIR/remote-release-rollback-commands.sh"
test -f "$ARM_WORKDIR/summary.txt" || die "missing H3 summary"
test -x "$ARM_COMMANDS" || die "missing H3 remote command log"
assert_contains "$ARM_COMMANDS" "--rollout-percentage 100"
assert_contains "$ARM_COMMANDS" "--project \"\$APP_DIR\""
assert_contains "$ARM_COMMANDS" 'FLUTTER_ARG=(--flutter "$FLUTTER")'
assert_not_contains "$ARM_COMMANDS" "--rollout 100"
assert_not_contains "$ARM_COMMANDS" "--artifact"
assert_contains "$ARM_WORKDIR/summary.txt" "Manual Phase H3 gap:"
assert_not_contains "$ARM_WORKDIR/summary.txt" "H3 Android arm64 drill passed"

H3_CRASH_EVIDENCE="$WORKDIR/h3-crash-rollback.log"
H3_EVENTS_EVIDENCE="$WORKDIR/h3-server-events.json"
echo "device rolled back to LKG" >"$H3_CRASH_EVIDENCE"
echo '{"event_type":"crash_rollback"}' >"$H3_EVENTS_EVIDENCE"
ARM_COMPLETE_WORKDIR="$WORKDIR/arm64-complete"
FCB_WORKDIR="$ARM_COMPLETE_WORKDIR" \
FCB_ARCHIVE_DIR="$WORKDIR/arm64-complete-archive" \
FCB_ACCEPT_SCRIPT="$FAKE_ACCEPT" \
FCB_HOST_CRASH_ROLLBACK_SCRIPT="$FAKE_CRASH" \
FCB_SKIP_ARCHIVE=1 \
FCB_H3_CRASH_ROLLBACK_EVIDENCE="$H3_CRASH_EVIDENCE" \
FCB_H3_SERVER_EVENTS_EVIDENCE="$H3_EVENTS_EVIDENCE" \
  "$ROOT_DIR/scripts/full_arm64_drill.sh" >/dev/null
assert_contains "$ARM_COMPLETE_WORKDIR/summary.txt" "H3 Android arm64 drill passed"
assert_contains "$ARM_COMPLETE_WORKDIR/summary.txt" "crash_rollback_evidence: evidence/h3-crash-rollback-"
assert_contains "$ARM_COMPLETE_WORKDIR/summary.txt" "server_events_evidence: evidence/h3-server-events-"
test -f "$ARM_COMPLETE_WORKDIR/evidence/h3-crash-rollback-$(basename "$H3_CRASH_EVIDENCE")" || die "missing staged H3 crash evidence"
test -f "$ARM_COMPLETE_WORKDIR/evidence/h3-server-events-$(basename "$H3_EVENTS_EVIDENCE")" || die "missing staged H3 server events evidence"
assert_not_contains "$ARM_COMPLETE_WORKDIR/summary.txt" "Manual Phase H3 gap:"

ARM_ARCHIVE_ONLY_WORKDIR="$WORKDIR/arm64-archive-only"
FCB_WORKDIR="$ARM_ARCHIVE_ONLY_WORKDIR" \
FCB_ARCHIVE_DIR="$WORKDIR/arm64-archive-only-archive" \
FCB_ACCEPT_SCRIPT="$FAKE_ACCEPT" \
FCB_HOST_CRASH_ROLLBACK_SCRIPT="$FAKE_CRASH" \
FCB_SKIP_ARCHIVE=1 \
FCB_SKIP_DEVICE_ACCEPTANCE=1 \
FCB_H3_CRASH_ROLLBACK_EVIDENCE="$H3_CRASH_EVIDENCE" \
FCB_H3_SERVER_EVENTS_EVIDENCE="$H3_EVENTS_EVIDENCE" \
  "$ROOT_DIR/scripts/full_arm64_drill.sh" >/dev/null
assert_contains "$ARM_ARCHIVE_ONLY_WORKDIR/summary.txt" "H3 Android arm64 drill passed"
assert_contains "$ARM_ARCHIVE_ONLY_WORKDIR/summary.txt" "skip_device_acceptance: 1"
test ! -e "$ARM_ARCHIVE_ONLY_WORKDIR/device-acceptance/summary.txt" || die "H3 archive-only reran device acceptance"

H3_BAD_CRASH_EVIDENCE="$WORKDIR/h3-bad-crash.log"
echo "device crashed repeatedly" >"$H3_BAD_CRASH_EVIDENCE"
if FCB_WORKDIR="$WORKDIR/arm64-bad-evidence" \
FCB_ARCHIVE_DIR="$WORKDIR/arm64-bad-evidence-archive" \
FCB_ACCEPT_SCRIPT="$FAKE_ACCEPT" \
FCB_HOST_CRASH_ROLLBACK_SCRIPT="$FAKE_CRASH" \
FCB_SKIP_ARCHIVE=1 \
FCB_H3_CRASH_ROLLBACK_EVIDENCE="$H3_BAD_CRASH_EVIDENCE" \
FCB_H3_SERVER_EVENTS_EVIDENCE="$H3_EVENTS_EVIDENCE" \
  "$ROOT_DIR/scripts/full_arm64_drill.sh" >/dev/null 2>&1; then
  die "H3 bad completion evidence unexpectedly passed"
fi

IOS_WORKDIR="$WORKDIR/ios"
FCB_WORKDIR="$IOS_WORKDIR" \
FCB_ARCHIVE_DIR="$WORKDIR/ios-archive" \
FCB_IOS_BUILD_SCRIPT="$FAKE_IOS_BUILD" \
FCB_IOS_SIM_SCRIPT="$FAKE_IOS_SIM" \
FCB_SKIP_IOS_SIM_PREFLIGHT=1 \
FCB_SKIP_ARCHIVE=1 \
FCB_TEAM_ID="TEAMID1234" \
  "$ROOT_DIR/scripts/full_ios_drill.sh" >/dev/null

test -f "$IOS_WORKDIR/summary.txt" || die "missing H4 summary"
test -x "$IOS_WORKDIR/iphone-device-commands.sh" || die "missing H4 device command log"
test -x "$IOS_WORKDIR/testflight-upload-commands.sh" || die "missing H4 TestFlight command log"
assert_contains "$IOS_WORKDIR/summary.txt" "Manual Phase H4 evidence still required:"
assert_not_contains "$IOS_WORKDIR/summary.txt" "H4 iPhone device drill passed"
assert_contains "$IOS_WORKDIR/iphone-device-commands.sh" "xcrun devicectl device install app"
assert_contains "$IOS_WORKDIR/testflight-upload-commands.sh" "xcodebuild -exportArchive"

H4_DEVICE_EVIDENCE="$WORKDIR/h4-device.log"
H4_EVENTS_EVIDENCE="$WORKDIR/h4-server-events.json"
echo "iPhone baseline patched restart passed" >"$H4_DEVICE_EVIDENCE"
echo '{"event_type":"launch_success"}' >"$H4_EVENTS_EVIDENCE"
IOS_COMPLETE_WORKDIR="$WORKDIR/ios-complete"
FCB_WORKDIR="$IOS_COMPLETE_WORKDIR" \
FCB_ARCHIVE_DIR="$WORKDIR/ios-complete-archive" \
FCB_IOS_BUILD_SCRIPT="$FAKE_IOS_BUILD" \
FCB_IOS_SIM_SCRIPT="$FAKE_IOS_SIM" \
FCB_SKIP_IOS_SIM_PREFLIGHT=1 \
FCB_SKIP_ARCHIVE=1 \
FCB_TEAM_ID="TEAMID1234" \
FCB_H4_DEVICE_EVIDENCE="$H4_DEVICE_EVIDENCE" \
FCB_H4_SERVER_EVENTS_EVIDENCE="$H4_EVENTS_EVIDENCE" \
  "$ROOT_DIR/scripts/full_ios_drill.sh" >/dev/null
assert_contains "$IOS_COMPLETE_WORKDIR/summary.txt" "H4 iPhone device drill passed"
assert_contains "$IOS_COMPLETE_WORKDIR/summary.txt" "device_evidence: evidence/h4-device-"
assert_contains "$IOS_COMPLETE_WORKDIR/summary.txt" "server_events_evidence: evidence/h4-server-events-"
test -f "$IOS_COMPLETE_WORKDIR/evidence/h4-device-$(basename "$H4_DEVICE_EVIDENCE")" || die "missing staged H4 device evidence"
test -f "$IOS_COMPLETE_WORKDIR/evidence/h4-server-events-$(basename "$H4_EVENTS_EVIDENCE")" || die "missing staged H4 server events evidence"
assert_not_contains "$IOS_COMPLETE_WORKDIR/summary.txt" "Manual Phase H4 evidence still required:"

H4_BAD_EVENTS_EVIDENCE="$WORKDIR/h4-bad-server-events.json"
echo '{"event_type":"download"}' >"$H4_BAD_EVENTS_EVIDENCE"
if FCB_WORKDIR="$WORKDIR/ios-bad-evidence" \
FCB_ARCHIVE_DIR="$WORKDIR/ios-bad-evidence-archive" \
FCB_IOS_BUILD_SCRIPT="$FAKE_IOS_BUILD" \
FCB_IOS_SIM_SCRIPT="$FAKE_IOS_SIM" \
FCB_SKIP_IOS_SIM_PREFLIGHT=1 \
FCB_SKIP_ARCHIVE=1 \
FCB_TEAM_ID="TEAMID1234" \
FCB_H4_DEVICE_EVIDENCE="$H4_DEVICE_EVIDENCE" \
FCB_H4_SERVER_EVENTS_EVIDENCE="$H4_BAD_EVENTS_EVIDENCE" \
  "$ROOT_DIR/scripts/full_ios_drill.sh" >/dev/null 2>&1; then
  die "H4 bad completion evidence unexpectedly passed"
fi

TESTFLIGHT_EVIDENCE="$WORKDIR/testflight-external-testing.txt"
TESTFLIGHT_UPLOAD="$WORKDIR/testflight-upload.txt"
echo "App Store Connect shows External Testing" >"$TESTFLIGHT_EVIDENCE"
echo "altool upload accepted" >"$TESTFLIGHT_UPLOAD"
TESTFLIGHT_ARCHIVE="$WORKDIR/testflight-archive"
FCB_TESTFLIGHT_ARCHIVE_DIR="$TESTFLIGHT_ARCHIVE" \
FCB_TESTFLIGHT_BUILD_NUMBER="42" \
FCB_TESTFLIGHT_STATUS="External Testing" \
FCB_TESTFLIGHT_EXTERNAL_TESTING_EVIDENCE="$TESTFLIGHT_EVIDENCE" \
FCB_TESTFLIGHT_UPLOAD_EVIDENCE="$TESTFLIGHT_UPLOAD" \
FCB_TESTFLIGHT_REVIEW_NOTES="fake runbook check" \
  "$ROOT_DIR/scripts/record_testflight_evidence.sh" >/dev/null
assert_contains "$TESTFLIGHT_ARCHIVE/summary.txt" "TestFlight External Testing entered"
assert_contains "$TESTFLIGHT_ARCHIVE/summary.txt" "build_number: 42"

TESTFLIGHT_BAD_EVIDENCE="$WORKDIR/testflight-internal-only.txt"
echo "App Store Connect shows Internal Testing" >"$TESTFLIGHT_BAD_EVIDENCE"
if FCB_TESTFLIGHT_ARCHIVE_DIR="$WORKDIR/testflight-bad-archive" \
FCB_TESTFLIGHT_BUILD_NUMBER="43" \
FCB_TESTFLIGHT_STATUS="External Testing" \
FCB_TESTFLIGHT_EXTERNAL_TESTING_EVIDENCE="$TESTFLIGHT_BAD_EVIDENCE" \
FCB_TESTFLIGHT_UPLOAD_EVIDENCE="$TESTFLIGHT_UPLOAD" \
  "$ROOT_DIR/scripts/record_testflight_evidence.sh" >/dev/null 2>&1; then
  die "TestFlight bad External Testing evidence unexpectedly passed"
fi

REBASE_LOG="$WORKDIR/vendor-rebase.log"
REBASE_ENGINE="$WORKDIR/vendor-rebase-engine.txt"
REBASE_CARGO="$WORKDIR/vendor-rebase-cargo.txt"
REBASE_E2E="$WORKDIR/vendor-rebase-e2e.txt"
REBASE_ARM64="$WORKDIR/vendor-rebase-arm64.txt"
echo "replayed FCB hook commits onto Flutter stable" >"$REBASE_LOG"
echo "engine build passed" >"$REBASE_ENGINE"
echo "cargo test --workspace passed" >"$REBASE_CARGO"
echo "e2e_x64 passed" >"$REBASE_E2E"
echo "arm64 drill passed" >"$REBASE_ARM64"
REBASE_ARCHIVE="$WORKDIR/vendor-rebase-archive"
FCB_VENDOR_REBASE_ARCHIVE_DIR="$REBASE_ARCHIVE" \
FCB_VENDOR_REBASE_STATUS="passed" \
FCB_VENDOR_REBASE_SOURCE_REF="flutter-3.12.2-fcb" \
FCB_VENDOR_REBASE_TARGET_REF="flutter-stable-2026q2" \
FCB_VENDOR_REBASE_FLUTTER_COMMIT="87c1bc51504" \
FCB_VENDOR_REBASE_DART_COMMIT="1b88776798d" \
FCB_VENDOR_REBASE_REBASE_LOG="$REBASE_LOG" \
FCB_VENDOR_REBASE_ENGINE_BUILD_EVIDENCE="$REBASE_ENGINE" \
FCB_VENDOR_REBASE_CARGO_TEST_EVIDENCE="$REBASE_CARGO" \
FCB_VENDOR_REBASE_E2E_X64_EVIDENCE="$REBASE_E2E" \
FCB_VENDOR_REBASE_ARM64_DRILL_EVIDENCE="$REBASE_ARM64" \
FCB_VENDOR_REBASE_NOTES="fake runbook check" \
  "$ROOT_DIR/scripts/record_vendor_rebase_evidence.sh" >/dev/null
assert_contains "$REBASE_ARCHIVE/summary.txt" "Vendor rebase validation passed"
assert_contains "$REBASE_ARCHIVE/summary.txt" "target_ref: flutter-stable-2026q2"

REBASE_BAD_ARM64="$WORKDIR/vendor-rebase-bad-arm64.txt"
echo "arm64 drill skipped" >"$REBASE_BAD_ARM64"
if FCB_VENDOR_REBASE_ARCHIVE_DIR="$WORKDIR/vendor-rebase-bad-archive" \
FCB_VENDOR_REBASE_STATUS="passed" \
FCB_VENDOR_REBASE_SOURCE_REF="flutter-3.12.2-fcb" \
FCB_VENDOR_REBASE_TARGET_REF="flutter-stable-2026q2" \
FCB_VENDOR_REBASE_FLUTTER_COMMIT="87c1bc51504" \
FCB_VENDOR_REBASE_DART_COMMIT="1b88776798d" \
FCB_VENDOR_REBASE_REBASE_LOG="$REBASE_LOG" \
FCB_VENDOR_REBASE_ENGINE_BUILD_EVIDENCE="$REBASE_ENGINE" \
FCB_VENDOR_REBASE_CARGO_TEST_EVIDENCE="$REBASE_CARGO" \
FCB_VENDOR_REBASE_E2E_X64_EVIDENCE="$REBASE_E2E" \
FCB_VENDOR_REBASE_ARM64_DRILL_EVIDENCE="$REBASE_BAD_ARM64" \
  "$ROOT_DIR/scripts/record_vendor_rebase_evidence.sh" >/dev/null 2>&1; then
  die "Vendor rebase bad arm64 evidence unexpectedly passed"
fi

VM_BASELINE="$WORKDIR/vm-patch-baseline.txt"
VM_PATCHED_UI="$WORKDIR/vm-patch-patched-ui.txt"
VM_RESTART="$WORKDIR/vm-patch-restart.txt"
VM_LOG="$WORKDIR/vm-patch-vm.log"
VM_PAYLOAD="$WORKDIR/vm-patch-payload-inspect.txt"
VM_EVENTS="$WORKDIR/vm-patch-server-events.json"
echo "baseline counter_app release rendered" >"$VM_BASELINE"
{
  echo "patched widget tree"
  echo "widgetTreeLabel_observed: patched widget tree"
  echo "setState"
  echo "setState_observed: true"
  echo "method channel"
  echo "methodChannelCacheDir_observed: /data/user/0/app/code_cache/fcb"
} >"$VM_PATCHED_UI"
echo "restart kept patch active" >"$VM_RESTART"
echo "FCB VM interpreter executed patch function" >"$VM_LOG"
echo 'FCBM source_map entries present, "uses_call_static": true, "uses_get_field": true' >"$VM_PAYLOAD"
echo '{"event_type":"launch_success","interpreter_ratio":0.009}' >"$VM_EVENTS"
VM_PATCH_ARCHIVE="$WORKDIR/vm-patch-archive"
FCB_VM_PATCH_ARCHIVE_DIR="$VM_PATCH_ARCHIVE" \
FCB_VM_PATCH_STATUS="passed" \
FCB_VM_PATCH_PLATFORM="android-arm64" \
FCB_VM_PATCH_PATCH_NUMBER="7" \
FCB_VM_PATCH_SCENARIO="widget_tree_setState_method_channel" \
FCB_VM_PATCH_BASELINE_EVIDENCE="$VM_BASELINE" \
FCB_VM_PATCH_PATCHED_UI_EVIDENCE="$VM_PATCHED_UI" \
FCB_VM_PATCH_RESTART_EVIDENCE="$VM_RESTART" \
FCB_VM_PATCH_VM_LOG_EVIDENCE="$VM_LOG" \
FCB_VM_PATCH_PAYLOAD_INSPECT_EVIDENCE="$VM_PAYLOAD" \
FCB_VM_PATCH_SERVER_EVENTS_EVIDENCE="$VM_EVENTS" \
FCB_VM_PATCH_NOTES="fake runbook check" \
  "$ROOT_DIR/scripts/record_vm_patch_evidence.sh" >/dev/null
assert_contains "$VM_PATCH_ARCHIVE/summary.txt" "Counter app real VM patch passed"
assert_contains "$VM_PATCH_ARCHIVE/summary.txt" "scenario: widget_tree_setState_method_channel"

VM_BAD_PAYLOAD="$WORKDIR/vm-patch-bad-payload-inspect.txt"
echo "FCBM source_map entries present but no call_static coverage" >"$VM_BAD_PAYLOAD"
if FCB_VM_PATCH_ARCHIVE_DIR="$WORKDIR/vm-patch-bad-archive" \
FCB_VM_PATCH_STATUS="passed" \
FCB_VM_PATCH_PLATFORM="android-arm64" \
FCB_VM_PATCH_PATCH_NUMBER="8" \
FCB_VM_PATCH_SCENARIO="widget_tree_setState_method_channel" \
FCB_VM_PATCH_BASELINE_EVIDENCE="$VM_BASELINE" \
FCB_VM_PATCH_PATCHED_UI_EVIDENCE="$VM_PATCHED_UI" \
FCB_VM_PATCH_RESTART_EVIDENCE="$VM_RESTART" \
FCB_VM_PATCH_VM_LOG_EVIDENCE="$VM_LOG" \
FCB_VM_PATCH_PAYLOAD_INSPECT_EVIDENCE="$VM_BAD_PAYLOAD" \
FCB_VM_PATCH_SERVER_EVENTS_EVIDENCE="$VM_EVENTS" \
  "$ROOT_DIR/scripts/record_vm_patch_evidence.sh" >/dev/null 2>&1; then
  die "VM patch bad payload evidence unexpectedly passed"
fi

VM_BAD_EVENTS="$WORKDIR/vm-patch-bad-server-events.json"
echo '{"event_type":"launch_success","interpreter_ratio":0.01}' >"$VM_BAD_EVENTS"
if FCB_VM_PATCH_ARCHIVE_DIR="$WORKDIR/vm-patch-bad-ratio-archive" \
FCB_VM_PATCH_STATUS="passed" \
FCB_VM_PATCH_PLATFORM="android-arm64" \
FCB_VM_PATCH_PATCH_NUMBER="9" \
FCB_VM_PATCH_SCENARIO="widget_tree_setState_method_channel" \
FCB_VM_PATCH_BASELINE_EVIDENCE="$VM_BASELINE" \
FCB_VM_PATCH_PATCHED_UI_EVIDENCE="$VM_PATCHED_UI" \
FCB_VM_PATCH_RESTART_EVIDENCE="$VM_RESTART" \
FCB_VM_PATCH_VM_LOG_EVIDENCE="$VM_LOG" \
FCB_VM_PATCH_PAYLOAD_INSPECT_EVIDENCE="$VM_PAYLOAD" \
FCB_VM_PATCH_SERVER_EVENTS_EVIDENCE="$VM_BAD_EVENTS" \
  "$ROOT_DIR/scripts/record_vm_patch_evidence.sh" >/dev/null 2>&1; then
  die "VM patch bad interpreter_ratio evidence unexpectedly passed"
fi

VM_PATCH_GOOD_AUDIT="$WORKDIR/vm-patch-good-audit"
FCB_PLAN_AUDIT_DIR="$VM_PATCH_GOOD_AUDIT" \
FCB_PLAN_AUDIT_GITHUB_EVIDENCE=0 \
FCB_PLAN_AUDIT_VM_PATCH_SUMMARY="$VM_PATCH_ARCHIVE/summary.txt" \
  "$ROOT_DIR/scripts/audit_plan_completion.sh" >/dev/null 2>&1 || true
assert_contains "$VM_PATCH_GOOD_AUDIT/summary.txt" "E end-to-end VM patch: counter_app real VM patch evidence passed"

VM_PATCH_SYMLINK_ARCHIVE="$WORKDIR/vm-patch-symlink-archive"
cp -R "$VM_PATCH_ARCHIVE" "$VM_PATCH_SYMLINK_ARCHIVE"
PAYLOAD_REL="$(awk 'index($0, "payload_inspect_evidence: ") == 1 { print substr($0, 27); exit }' "$VM_PATCH_SYMLINK_ARCHIVE/summary.txt")"
rm "$VM_PATCH_SYMLINK_ARCHIVE/$PAYLOAD_REL"
ln -s "$VM_PAYLOAD" "$VM_PATCH_SYMLINK_ARCHIVE/$PAYLOAD_REL"
VM_PATCH_SYMLINK_AUDIT="$WORKDIR/vm-patch-symlink-audit"
FCB_PLAN_AUDIT_DIR="$VM_PATCH_SYMLINK_AUDIT" \
FCB_PLAN_AUDIT_GITHUB_EVIDENCE=0 \
FCB_PLAN_AUDIT_VM_PATCH_SUMMARY="$VM_PATCH_SYMLINK_ARCHIVE/summary.txt" \
  "$ROOT_DIR/scripts/audit_plan_completion.sh" >/dev/null 2>&1 || true
assert_contains "$VM_PATCH_SYMLINK_AUDIT/summary.txt" "E end-to-end VM patch: missing evidence with marker 'Counter app real VM patch passed'"

INVENTORY_WORKFLOWS="$WORKDIR/inventory-workflows"
INVENTORY_SCRIPT="$WORKDIR/inventory-evidence.sh"
mkdir -p "$INVENTORY_WORKFLOWS"
cat >"$INVENTORY_WORKFLOWS/workflows_lint.yaml" <<'EOF'
name: Workflow Lint
on: push
EOF
cat >"$INVENTORY_WORKFLOWS/rust.yml" <<'EOF'
name: Rust
on: [push]
EOF
cat >"$INVENTORY_WORKFLOWS/server.yml" <<'EOF'
name: Server
on:
  push:
EOF
cat >"$INVENTORY_WORKFLOWS/e2e_x64.yml" <<'EOF'
name: E2E x64
on:
  - push
EOF
cat >"$INVENTORY_WORKFLOWS/flutter_package.yml" <<'EOF'
name: Flutter Package
on:
  push:
EOF
cat >"$INVENTORY_WORKFLOWS/android_emulator.yml" <<'EOF'
name: Android Emulator Nightly
on:
  schedule:
EOF
cat >"$INVENTORY_WORKFLOWS/ios_simulator.yml" <<'EOF'
name: iOS Simulator Nightly
on:
  schedule:
EOF
cat >"$INVENTORY_WORKFLOWS/server_s3.yml" <<'EOF'
name: Server S3 Storage
on:
  schedule:
EOF
cat >"$INVENTORY_SCRIPT" <<'EOF'
run_list "Workflow Lint" "push"
run_list "Rust" "push"
run_list "Server" "push"
run_list "E2E x64" "push"
run_list "Flutter Package" "push"
run_list "Android Emulator Nightly" "schedule"
run_list "iOS Simulator Nightly" "schedule"
run_list "Server S3 Storage" "schedule"
EOF
FCB_GITHUB_WORKFLOWS_DIR="$INVENTORY_WORKFLOWS" \
FCB_GITHUB_EVIDENCE_SCRIPT="$INVENTORY_SCRIPT" \
  "$ROOT_DIR/scripts/check_github_actions_inventory.sh" >/dev/null

S3_GOOD="$WORKDIR/s3-good-summary.txt"
S3_BAD="$WORKDIR/s3-bad-summary.txt"
S3_HASH="0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"
cat >"$S3_GOOD" <<EOF
S3 storage drill passed
bucket: fcb-payloads
key: patches/s3-drill-app/1.0.0+1/android/arm64-v8a/1/payload.bin
hash: $S3_HASH
downloaded_hash: $S3_HASH
payload_url_has_signature: 1
object_stat: passed
EOF
cat >"$S3_BAD" <<EOF
S3 storage drill passed
bucket: fcb-payloads
key: patches/s3-drill-app/1.0.0+1/android/arm64-v8a/1/payload.bin
hash: $S3_HASH
downloaded_hash: fedcba9876543210fedcba9876543210fedcba9876543210fedcba9876543210
payload_url_has_signature: 1
object_stat: passed
EOF
S3_GOOD_AUDIT="$WORKDIR/s3-good-audit"
S3_BAD_AUDIT="$WORKDIR/s3-bad-audit"
FCB_PLAN_AUDIT_DIR="$S3_GOOD_AUDIT" \
FCB_PLAN_AUDIT_GITHUB_EVIDENCE=0 \
FCB_PLAN_AUDIT_S3_SUMMARY="$S3_GOOD" \
  "$ROOT_DIR/scripts/audit_plan_completion.sh" >/dev/null 2>&1 || true
assert_contains "$S3_GOOD_AUDIT/summary.txt" "F S3 drill: summary passed"
FCB_PLAN_AUDIT_DIR="$S3_BAD_AUDIT" \
FCB_PLAN_AUDIT_GITHUB_EVIDENCE=0 \
FCB_PLAN_AUDIT_S3_SUMMARY="$S3_BAD" \
  "$ROOT_DIR/scripts/audit_plan_completion.sh" >/dev/null 2>&1 || true
assert_contains "$S3_BAD_AUDIT/summary.txt" "F S3 drill: missing complete passing S3 storage drill summary"

echo "Phase H runbook generation checks passed."
