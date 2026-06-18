#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORKDIR="${FCB_WORKDIR:-$ROOT_DIR/target/fcb/crash-rollback-drill}"
CARGO="${CARGO:-cargo}"

case "$WORKDIR" in
  /*) ;;
  *) WORKDIR="$ROOT_DIR/$WORKDIR" ;;
esac

usage() {
  cat <<USAGE
Usage:
  $0

Runs the host-side crash rollback drill used as the Phase G/H3 preflight.
The drill executes the updater FFI test that simulates a pending patch failing
to call mark_success for three launches, then verifies that launch selection
rolls back to the last-known-good patch and records a crash_rollback event.

Environment:
  FCB_WORKDIR  Drill output root. Default: target/fcb/crash-rollback-drill
  CARGO        Cargo binary. Default: cargo
USAGE
}

run() {
  echo "+ $*" >&2
  "$@"
}

write_summary() {
  local out="$WORKDIR/summary.txt"
  {
    echo "FCB host crash rollback drill passed"
    echo "workdir: $WORKDIR"
    echo "test: updater::tests::get_launch_patch_rolls_back_to_lkg_after_three_failed_launches"
    echo "log: $WORKDIR/cargo-test.log"
    echo
    echo "Verified contract:"
    echo "- pending patch is selected for the first two failed launches"
    echo "- third launch rolls back to the last-known-good patch"
    echo "- failed patch is marked bad"
    echo "- local crash_rollback history records boot_attempts=3"
  } >"$out"
  echo "summary: $out"
}

main() {
  if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
    usage
    exit 0
  fi

  mkdir -p "$WORKDIR"
  local log="$WORKDIR/cargo-test.log"

  cd "$ROOT_DIR"
  run "$CARGO" test -p fcb_updater --no-default-features \
    get_launch_patch_rolls_back_to_lkg_after_three_failed_launches >"$log" 2>&1 || {
      cat "$log" >&2
      exit 1
    }
  if ! grep -Fq "test tests::get_launch_patch_rolls_back_to_lkg_after_three_failed_launches ... ok" "$log"; then
    cat "$log" >&2
    echo "error: crash rollback drill did not run the expected updater FFI test" >&2
    exit 1
  fi

  write_summary
  echo "FCB host crash rollback drill passed."
}

main "$@"
