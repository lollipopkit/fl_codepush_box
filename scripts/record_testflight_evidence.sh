#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STAMP="${FCB_TESTFLIGHT_ARCHIVE_STAMP:-$(date +%Y%m%d_%H%M%S)}"
ARCHIVE_DIR="${FCB_TESTFLIGHT_ARCHIVE_DIR:-$ROOT_DIR/target/fcb/evidence/testflight_$STAMP}"
BUILD_NUMBER="${FCB_TESTFLIGHT_BUILD_NUMBER:-}"
BUNDLE_ID="${FCB_BUNDLE_ID:-com.example.fcbCounterApp}"
STATUS="${FCB_TESTFLIGHT_STATUS:-}"
EXTERNAL_TESTING_EVIDENCE="${FCB_TESTFLIGHT_EXTERNAL_TESTING_EVIDENCE:-}"
UPLOAD_EVIDENCE="${FCB_TESTFLIGHT_UPLOAD_EVIDENCE:-}"
REVIEW_NOTES="${FCB_TESTFLIGHT_REVIEW_NOTES:-}"

usage() {
  cat <<USAGE
Usage:
  FCB_TESTFLIGHT_BUILD_NUMBER=<build> \\
  FCB_TESTFLIGHT_STATUS="External Testing" \\
  FCB_TESTFLIGHT_EXTERNAL_TESTING_EVIDENCE=<file> \\
    $0

Records Phase H4 TestFlight evidence into target/fcb/evidence/testflight_<timestamp>.
This script does not upload builds or query App Store Connect. It only writes
the completion marker consumed by make audit-plan-completion after a human has
provided evidence that the build entered External Testing.

Environment:
  FCB_TESTFLIGHT_ARCHIVE_DIR                 Archive dir override.
  FCB_TESTFLIGHT_ARCHIVE_STAMP               Timestamp suffix for default dir.
  FCB_TESTFLIGHT_BUILD_NUMBER                Required TestFlight build number.
  FCB_TESTFLIGHT_STATUS                      Must be exactly "External Testing".
  FCB_TESTFLIGHT_EXTERNAL_TESTING_EVIDENCE   Required file proving status. Must contain
                                             "External Testing", bundle id, and build number.
  FCB_TESTFLIGHT_UPLOAD_EVIDENCE             Optional upload/processing evidence file.
                                             Must contain "accepted" and build number.
  FCB_TESTFLIGHT_REVIEW_NOTES                Optional reviewer notes or issue URL.
  FCB_BUNDLE_ID                              Bundle id. Default: com.example.fcbCounterApp.
USAGE
}

die() {
  echo "error: $*" >&2
  exit 1
}

require_file() {
  [ -f "$1" ] || die "missing file: $1"
}

require_file_contains() {
  local file="$1"
  local pattern="$2"
  grep -Fq "$pattern" "$file" || die "evidence file $file must contain: $pattern"
}

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
  usage
  exit 0
fi

[ -n "$BUILD_NUMBER" ] || die "FCB_TESTFLIGHT_BUILD_NUMBER is required"
[ "$STATUS" = "External Testing" ] || die "FCB_TESTFLIGHT_STATUS must be exactly 'External Testing'"
[ -n "$EXTERNAL_TESTING_EVIDENCE" ] || die "FCB_TESTFLIGHT_EXTERNAL_TESTING_EVIDENCE is required"
require_file "$EXTERNAL_TESTING_EVIDENCE"
require_file_contains "$EXTERNAL_TESTING_EVIDENCE" "External Testing"
require_file_contains "$EXTERNAL_TESTING_EVIDENCE" "$BUNDLE_ID"
require_file_contains "$EXTERNAL_TESTING_EVIDENCE" "$BUILD_NUMBER"
if [ -n "$UPLOAD_EVIDENCE" ]; then
  require_file "$UPLOAD_EVIDENCE"
  require_file_contains "$UPLOAD_EVIDENCE" "accepted"
  require_file_contains "$UPLOAD_EVIDENCE" "$BUILD_NUMBER"
fi

if [ -e "$ARCHIVE_DIR" ]; then
  die "archive dir already exists: $ARCHIVE_DIR"
fi
mkdir -p "$ARCHIVE_DIR/evidence"

external_basename="$(basename "$EXTERNAL_TESTING_EVIDENCE")"
cp "$EXTERNAL_TESTING_EVIDENCE" "$ARCHIVE_DIR/evidence/$external_basename"
upload_basename=""
if [ -n "$UPLOAD_EVIDENCE" ]; then
  upload_basename="$(basename "$UPLOAD_EVIDENCE")"
  cp "$UPLOAD_EVIDENCE" "$ARCHIVE_DIR/evidence/$upload_basename"
fi

{
  echo "FCB TestFlight evidence"
  echo "TestFlight External Testing entered"
  echo "bundle_id: $BUNDLE_ID"
  echo "build_number: $BUILD_NUMBER"
  echo "status: $STATUS"
  echo "external_testing_evidence: evidence/$external_basename"
  if [ -n "$upload_basename" ]; then
    echo "upload_evidence: evidence/$upload_basename"
  fi
  if [ -n "$REVIEW_NOTES" ]; then
    echo "review_notes: $REVIEW_NOTES"
  fi
} >"$ARCHIVE_DIR/summary.txt"

echo "TestFlight evidence recorded: $ARCHIVE_DIR/summary.txt"
