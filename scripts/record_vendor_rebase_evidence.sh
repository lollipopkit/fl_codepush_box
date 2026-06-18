#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STAMP="${FCB_VENDOR_REBASE_ARCHIVE_STAMP:-$(date +%Y%m%d_%H%M%S)}"
ARCHIVE_DIR="${FCB_VENDOR_REBASE_ARCHIVE_DIR:-$ROOT_DIR/tests/e2e/vendor_rebase_$STAMP}"
STATUS="${FCB_VENDOR_REBASE_STATUS:-}"
SOURCE_REF="${FCB_VENDOR_REBASE_SOURCE_REF:-}"
TARGET_REF="${FCB_VENDOR_REBASE_TARGET_REF:-}"
FLUTTER_COMMIT="${FCB_VENDOR_REBASE_FLUTTER_COMMIT:-}"
DART_COMMIT="${FCB_VENDOR_REBASE_DART_COMMIT:-}"
REBASE_LOG="${FCB_VENDOR_REBASE_REBASE_LOG:-}"
ENGINE_BUILD_EVIDENCE="${FCB_VENDOR_REBASE_ENGINE_BUILD_EVIDENCE:-}"
CARGO_TEST_EVIDENCE="${FCB_VENDOR_REBASE_CARGO_TEST_EVIDENCE:-}"
E2E_X64_EVIDENCE="${FCB_VENDOR_REBASE_E2E_X64_EVIDENCE:-}"
ARM64_DRILL_EVIDENCE="${FCB_VENDOR_REBASE_ARM64_DRILL_EVIDENCE:-}"
NOTES="${FCB_VENDOR_REBASE_NOTES:-}"

usage() {
  cat <<USAGE
Usage:
  FCB_VENDOR_REBASE_STATUS=passed \\
  FCB_VENDOR_REBASE_SOURCE_REF=<old-ref> \\
  FCB_VENDOR_REBASE_TARGET_REF=<new-ref> \\
  FCB_VENDOR_REBASE_FLUTTER_COMMIT=<commit> \\
  FCB_VENDOR_REBASE_DART_COMMIT=<commit> \\
  FCB_VENDOR_REBASE_REBASE_LOG=<file> \\
  FCB_VENDOR_REBASE_ENGINE_BUILD_EVIDENCE=<file> \\
  FCB_VENDOR_REBASE_CARGO_TEST_EVIDENCE=<file> \\
  FCB_VENDOR_REBASE_E2E_X64_EVIDENCE=<file> \\
  FCB_VENDOR_REBASE_ARM64_DRILL_EVIDENCE=<file> \\
    $0

Records Phase H5 vendor rebase validation evidence into
tests/e2e/vendor_rebase_<timestamp>. This script does not rebase vendor
checkouts. It only writes the completion marker consumed by
make audit-plan-completion after a real rebase has been performed and
validated.

Environment:
  FCB_VENDOR_REBASE_ARCHIVE_DIR             Archive dir override.
  FCB_VENDOR_REBASE_ARCHIVE_STAMP           Timestamp suffix for default dir.
  FCB_VENDOR_REBASE_STATUS                  Must be exactly "passed".
  FCB_VENDOR_REBASE_SOURCE_REF              Required old Flutter/Dart base ref.
  FCB_VENDOR_REBASE_TARGET_REF              Required new Flutter/Dart base ref.
  FCB_VENDOR_REBASE_FLUTTER_COMMIT          Required rebased vendor/flutter commit.
  FCB_VENDOR_REBASE_DART_COMMIT             Required pinned Engine embedded Dart SDK commit.
  FCB_VENDOR_REBASE_REBASE_LOG              Required rebase command/conflict log.
  FCB_VENDOR_REBASE_ENGINE_BUILD_EVIDENCE   Required engine build evidence.
  FCB_VENDOR_REBASE_CARGO_TEST_EVIDENCE     Required cargo test evidence.
  FCB_VENDOR_REBASE_E2E_X64_EVIDENCE        Required e2e_x64 evidence.
  FCB_VENDOR_REBASE_ARM64_DRILL_EVIDENCE    Required arm64 drill evidence.
  FCB_VENDOR_REBASE_NOTES                   Optional notes or issue URL.
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

[ "$STATUS" = "passed" ] || die "FCB_VENDOR_REBASE_STATUS must be exactly 'passed'"
require_value "FCB_VENDOR_REBASE_SOURCE_REF" "$SOURCE_REF"
require_value "FCB_VENDOR_REBASE_TARGET_REF" "$TARGET_REF"
require_value "FCB_VENDOR_REBASE_FLUTTER_COMMIT" "$FLUTTER_COMMIT"
require_value "FCB_VENDOR_REBASE_DART_COMMIT" "$DART_COMMIT"
require_value "FCB_VENDOR_REBASE_REBASE_LOG" "$REBASE_LOG"
require_value "FCB_VENDOR_REBASE_ENGINE_BUILD_EVIDENCE" "$ENGINE_BUILD_EVIDENCE"
require_value "FCB_VENDOR_REBASE_CARGO_TEST_EVIDENCE" "$CARGO_TEST_EVIDENCE"
require_value "FCB_VENDOR_REBASE_E2E_X64_EVIDENCE" "$E2E_X64_EVIDENCE"
require_value "FCB_VENDOR_REBASE_ARM64_DRILL_EVIDENCE" "$ARM64_DRILL_EVIDENCE"

require_file "$REBASE_LOG"
require_file "$ENGINE_BUILD_EVIDENCE"
require_file "$CARGO_TEST_EVIDENCE"
require_file "$E2E_X64_EVIDENCE"
require_file "$ARM64_DRILL_EVIDENCE"
require_file_contains "$REBASE_LOG" "replayed FCB hook commits"
require_file_contains "$ENGINE_BUILD_EVIDENCE" "engine build passed"
require_file_contains "$CARGO_TEST_EVIDENCE" "cargo test --workspace passed"
require_file_contains "$E2E_X64_EVIDENCE" "e2e_x64 passed"
require_file_contains "$ARM64_DRILL_EVIDENCE" "arm64 drill passed"

if [ -e "$ARCHIVE_DIR" ]; then
  die "archive dir already exists: $ARCHIVE_DIR"
fi
mkdir -p "$ARCHIVE_DIR/evidence"

rebase_copy="$(copy_evidence "$REBASE_LOG" "rebase")"
engine_copy="$(copy_evidence "$ENGINE_BUILD_EVIDENCE" "engine-build")"
cargo_copy="$(copy_evidence "$CARGO_TEST_EVIDENCE" "cargo-test")"
e2e_copy="$(copy_evidence "$E2E_X64_EVIDENCE" "e2e-x64")"
arm64_copy="$(copy_evidence "$ARM64_DRILL_EVIDENCE" "arm64-drill")"

{
  echo "FCB vendor rebase evidence"
  echo "Vendor rebase validation passed"
  echo "status: $STATUS"
  echo "source_ref: $SOURCE_REF"
  echo "target_ref: $TARGET_REF"
  echo "flutter_commit: $FLUTTER_COMMIT"
  echo "dart_commit: $DART_COMMIT"
  echo "rebase_log: $rebase_copy"
  echo "engine_build_evidence: $engine_copy"
  echo "cargo_test_evidence: $cargo_copy"
  echo "e2e_x64_evidence: $e2e_copy"
  echo "arm64_drill_evidence: $arm64_copy"
  if [ -n "$NOTES" ]; then
    echo "notes: $NOTES"
  fi
} >"$ARCHIVE_DIR/summary.txt"

echo "vendor rebase evidence recorded: $ARCHIVE_DIR/summary.txt"
