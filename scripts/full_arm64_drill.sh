#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORKDIR="${FCB_WORKDIR:-$ROOT_DIR/target/fcb/full-arm64-drill}"
ARCHIVE_STAMP="${FCB_ARCHIVE_STAMP:-$(date +%Y%m%d_%H%M%S)}"
ARCHIVE_DIR="${FCB_ARCHIVE_DIR:-$ROOT_DIR/target/fcb/evidence/arm64_drill_$ARCHIVE_STAMP}"
ACCEPT_SCRIPT="${FCB_ACCEPT_SCRIPT:-$ROOT_DIR/scripts/accept_android_arm64.sh}"
HOST_CRASH_ROLLBACK_SCRIPT="${FCB_HOST_CRASH_ROLLBACK_SCRIPT:-$ROOT_DIR/scripts/test_crash_rollback.sh}"
SERVER_URL="${FCB_SERVER_URL:-}"
FCB_CLI="${FCB_CLI:-$ROOT_DIR/target/debug/fcb}"
FCB_FLUTTER="${FCB_FLUTTER:-}"
FCB_SERVER_BIN="${FCB_SERVER_BIN:-$ROOT_DIR/target/debug/fcb_server}"
APP_DIR="${FCB_APP_DIR:-$ROOT_DIR/examples/counter_app}"
KEEP_SERVER="${FCB_KEEP_SERVER:-0}"
SKIP_HOST_CRASH_ROLLBACK="${FCB_SKIP_HOST_CRASH_ROLLBACK:-0}"
SKIP_DEVICE_ACCEPTANCE="${FCB_SKIP_DEVICE_ACCEPTANCE:-0}"
SKIP_ARCHIVE="${FCB_SKIP_ARCHIVE:-0}"
H3_CRASH_ROLLBACK_EVIDENCE="${FCB_H3_CRASH_ROLLBACK_EVIDENCE:-}"
H3_SERVER_EVENTS_EVIDENCE="${FCB_H3_SERVER_EVENTS_EVIDENCE:-}"
H3_CRASH_ROLLBACK_EVIDENCE_SUMMARY=""
H3_SERVER_EVENTS_EVIDENCE_SUMMARY=""

case "$WORKDIR" in
  /*) ;;
  *) WORKDIR="$ROOT_DIR/$WORKDIR" ;;
esac

usage() {
  cat <<USAGE
Usage:
  $0

Runs the Android arm64 production drill entrypoint required by Phase H3.
It always executes the device acceptance phases through accept_android_arm64.sh:
  1. baseline app launch, no patch
  2. bytecode patch install + restart + patched launch

If FCB_SERVER_URL, FCB_APP_ID, and FCB_CLI_TOKEN are provided, the script also
records the remote release/rollback commands that should be run against the same
server for the full release -> patch -> promote -> rollback audit. Device crash
rollback still requires a crash-producing VM patch and is marked as manual until
Phase E exposes that payload from the VM/compiler path.

Environment:
  FCB_WORKDIR       Drill output root. Default: target/fcb/full-arm64-drill
  FCB_ARCHIVE_DIR   Evidence archive root. Default: target/fcb/evidence/arm64_drill_<timestamp>
  FCB_ARCHIVE_STAMP Timestamp suffix used by the default archive dir.
  FCB_ACCEPT_SCRIPT Android acceptance script. Default: scripts/accept_android_arm64.sh
  FCB_HOST_CRASH_ROLLBACK_SCRIPT
                    Host-side crash rollback preflight. Default: scripts/test_crash_rollback.sh
  FCB_SKIP_HOST_CRASH_ROLLBACK
                    Skip the host crash rollback preflight. Default: 0
  FCB_SKIP_DEVICE_ACCEPTANCE
                    Skip rerunning accept_android_arm64.sh when archiving
                    already-recorded device evidence. Default: 0
  FCB_SKIP_ARCHIVE  Skip copying final evidence into the archive dir. Default: 0
  FCB_SERVER_URL    Optional server URL for remote command log.
  FCB_CLI_TOKEN     Optional CLI token for remote command log.
  FCB_APP_ID        Optional app id for remote command log.
  FCB_CLI           CLI path. Default: target/debug/fcb
  FCB_FLUTTER       Optional Flutter binary passed to generated release/patch commands.
  FCB_SERVER_BIN    Server path for local preflight metadata.
  FCB_KEEP_SERVER   Reserved for future local server orchestration. Default: 0
  FCB_H3_CRASH_ROLLBACK_EVIDENCE
                    File proving device crash patch rolled back to LKG.
  FCB_H3_SERVER_EVENTS_EVIDENCE
                    File proving server patch_events contains crash_rollback.
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

require_file_contains() {
  local file="$1"
  local pattern="$2"
  grep -Fq "$pattern" "$file" || die "evidence file $file must contain: $pattern"
}

validate_completion_evidence() {
  if [ -n "$H3_CRASH_ROLLBACK_EVIDENCE" ] || [ -n "$H3_SERVER_EVENTS_EVIDENCE" ]; then
    [ -n "$H3_CRASH_ROLLBACK_EVIDENCE" ] || die "FCB_H3_CRASH_ROLLBACK_EVIDENCE is required when writing the H3 completion marker"
    [ -n "$H3_SERVER_EVENTS_EVIDENCE" ] || die "FCB_H3_SERVER_EVENTS_EVIDENCE is required when writing the H3 completion marker"
    require_file "$H3_CRASH_ROLLBACK_EVIDENCE"
    require_file "$H3_SERVER_EVENTS_EVIDENCE"
    require_file_contains "$H3_CRASH_ROLLBACK_EVIDENCE" "rolled back to LKG"
    require_file_contains "$H3_SERVER_EVENTS_EVIDENCE" "crash_rollback"
  fi
}

stage_completion_evidence() {
  if [ -z "$H3_CRASH_ROLLBACK_EVIDENCE" ] && [ -z "$H3_SERVER_EVENTS_EVIDENCE" ]; then
    return 0
  fi
  mkdir -p "$WORKDIR/evidence"
  local crash_basename
  local events_basename
  crash_basename="$(basename "$H3_CRASH_ROLLBACK_EVIDENCE")"
  events_basename="$(basename "$H3_SERVER_EVENTS_EVIDENCE")"
  cp "$H3_CRASH_ROLLBACK_EVIDENCE" "$WORKDIR/evidence/h3-crash-rollback-$crash_basename"
  cp "$H3_SERVER_EVENTS_EVIDENCE" "$WORKDIR/evidence/h3-server-events-$events_basename"
  H3_CRASH_ROLLBACK_EVIDENCE_SUMMARY="evidence/h3-crash-rollback-$crash_basename"
  H3_SERVER_EVENTS_EVIDENCE_SUMMARY="evidence/h3-server-events-$events_basename"
}

write_remote_command_log() {
  local out="$WORKDIR/remote-release-rollback-commands.sh"
  cat >"$out" <<EOF
#!/usr/bin/env bash
set -euo pipefail

# Generated by scripts/full_arm64_drill.sh.
# Run after the local device acceptance passes and the server is reachable.

FCB_CLI="\${FCB_CLI:-$FCB_CLI}"
SERVER="\${FCB_SERVER_URL:-$SERVER_URL}"
APP_ID="\${FCB_APP_ID:-${FCB_APP_ID:-}}"
TOKEN="\${FCB_CLI_TOKEN:-${FCB_CLI_TOKEN:-}}"
APP_DIR="\${FCB_APP_DIR:-$APP_DIR}"
FLUTTER="\${FCB_FLUTTER:-$FCB_FLUTTER}"
FLUTTER_ARG=()
if [ -n "\$FLUTTER" ]; then
  FLUTTER_ARG=(--flutter "\$FLUTTER")
fi

test -n "\$SERVER"
test -n "\$APP_ID"
test -n "\$TOKEN"

cd "\$APP_DIR"

"\$FCB_CLI" --server "\$SERVER" --token "\$TOKEN" --app "\$APP_ID" \\
  release android --arch arm64-v8a --project "\$APP_DIR" "\${FLUTTER_ARG[@]}"

"\$FCB_CLI" --server "\$SERVER" --token "\$TOKEN" --app "\$APP_ID" \\
  patch android --arch arm64-v8a --patch-number 1 --project "\$APP_DIR" "\${FLUTTER_ARG[@]}"

"\$FCB_CLI" --server "\$SERVER" --token "\$TOKEN" --app "\$APP_ID" \\
  promote --release-version 1.0.0+1 --patch-number 1 --platform android --arch arm64-v8a --rollout-percentage 100

# After validating the patched app on device, verify server events in the admin UI
# or via the stats API, then roll back the patch:
"\$FCB_CLI" --server "\$SERVER" --token "\$TOKEN" --app "\$APP_ID" \\
  rollback --release-version 1.0.0+1 --patch-number 1 --platform android --arch arm64-v8a
EOF
  chmod +x "$out"
}

write_summary() {
  local out="$WORKDIR/summary.txt"
  {
    echo "FCB Android arm64 full drill"
    echo "workdir: $WORKDIR"
    echo "host_crash_rollback_summary: $WORKDIR/host-crash-rollback/summary.txt"
    echo "acceptance_summary: $WORKDIR/device-acceptance/summary.txt"
    echo "remote_commands: $WORKDIR/remote-release-rollback-commands.sh"
    if [ "$SKIP_ARCHIVE" = "1" ]; then
      echo "archive_dir: skipped"
    else
      echo "archive_dir: $ARCHIVE_DIR"
    fi
    echo "server_url: ${SERVER_URL:-not-set}"
    echo "cli: $FCB_CLI"
    echo "flutter: ${FCB_FLUTTER:-not-set}"
    echo "server_bin: $FCB_SERVER_BIN"
    echo "app_dir: $APP_DIR"
    echo "keep_server: $KEEP_SERVER"
    echo "skip_host_crash_rollback: $SKIP_HOST_CRASH_ROLLBACK"
    echo "skip_device_acceptance: $SKIP_DEVICE_ACCEPTANCE"
    echo
    if [ -n "$H3_CRASH_ROLLBACK_EVIDENCE" ] && [ -n "$H3_SERVER_EVENTS_EVIDENCE" ]; then
      echo "H3 Android arm64 drill passed"
      echo "crash_rollback_evidence: $H3_CRASH_ROLLBACK_EVIDENCE_SUMMARY"
      echo "server_events_evidence: $H3_SERVER_EVENTS_EVIDENCE_SUMMARY"
    else
      echo "Manual Phase H3 gap:"
      echo "- crash-producing VM/compiler patch is still required for the intentional-crash rollback leg."
      echo "- once available, run it after patch 1 succeeds and verify crash_rollback in patch_events."
    fi
  } >"$out"
  echo "summary: $out"
}

archive_evidence() {
  if [ "$SKIP_ARCHIVE" = "1" ]; then
    echo "archive: skipped"
    return 0
  fi
  if [ -e "$ARCHIVE_DIR" ]; then
    die "archive dir already exists: $ARCHIVE_DIR"
  fi
  mkdir -p "$(dirname "$ARCHIVE_DIR")"
  cp -R "$WORKDIR" "$ARCHIVE_DIR"
  {
    echo
    echo "Archived Phase H3 evidence:"
    echo "- source_workdir: $WORKDIR"
    echo "- archive_dir: $ARCHIVE_DIR"
    echo "- known_issues: docs/known_issues.md"
  } >>"$ARCHIVE_DIR/summary.txt"
  echo "archive: $ARCHIVE_DIR"
}

main() {
  if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
    usage
    exit 0
  fi

  require_file "$ACCEPT_SCRIPT"
  require_file "$HOST_CRASH_ROLLBACK_SCRIPT"
  validate_completion_evidence
  mkdir -p "$WORKDIR"
  stage_completion_evidence

  if [ "$SKIP_HOST_CRASH_ROLLBACK" != "1" ]; then
    FCB_WORKDIR="$WORKDIR/host-crash-rollback" run "$HOST_CRASH_ROLLBACK_SCRIPT"
  fi
  if [ "$SKIP_DEVICE_ACCEPTANCE" != "1" ]; then
    FCB_WORKDIR="$WORKDIR/device-acceptance" run "$ACCEPT_SCRIPT"
  fi
  write_remote_command_log
  write_summary
  archive_evidence
  echo "FCB Android arm64 full drill entrypoint completed."
}

main "$@"
