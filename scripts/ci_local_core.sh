#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG_DIR="${FCB_LOCAL_CI_LOG_DIR:-$ROOT_DIR/target/fcb/local-ci-core}"
CARGO="${CARGO:-cargo}"
GO="${GO:-go}"
NPM="${NPM:-npm}"
DART_BIN="${DART_BIN:-dart}"
FLUTTER="${FLUTTER:-flutter}"

RUN_KERNEL="${FCB_LOCAL_CI_KERNEL:-auto}"
RUN_E2E="${FCB_LOCAL_CI_E2E:-auto}"
RUN_FLUTTER="${FCB_LOCAL_CI_FLUTTER:-auto}"
RUN_S3="${FCB_LOCAL_CI_S3:-0}"
RUN_NPM_CI="${FCB_LOCAL_CI_NPM_CI:-auto}"
COMPLETED_STEPS=()
SKIPPED_STEPS=()

mkdir -p "$LOG_DIR"

usage() {
  cat <<USAGE
Usage:
  $0

Runs the local core CI gate for checks that do not require vendor checkout
changes, real devices, TestFlight, or GitHub-hosted runners.

Environment:
  FCB_LOCAL_CI_LOG_DIR  Log output directory. Default: target/fcb/local-ci-core
  FCB_LOCAL_CI_KERNEL   Run Kernel compile drill: 1|0|auto. Default: auto
  FCB_LOCAL_CI_E2E      Run fake Flutter e2e: 1|0|auto. Default: auto
  FCB_LOCAL_CI_FLUTTER  Run packages/fcb_code_push tests: 1|0|auto. Default: auto
  FCB_LOCAL_CI_S3       Run Docker/MinIO S3 drill: 1|0. Default: 0
  FCB_LOCAL_CI_NPM_CI   Run npm ci before WebUI checks: 1|0|auto. Default: auto
  DART_BIN              Dart binary. Default: dart
  FLUTTER               Flutter binary. Default: flutter
USAGE
}

have() {
  command -v "$1" >/dev/null 2>&1
}

enabled() {
  local value="$1"
  local command_name="${2:-}"
  case "$value" in
    1|true|yes) return 0 ;;
    0|false|no) return 1 ;;
    auto)
      if [[ -z "$command_name" ]]; then
        return 0
      fi
      have "$command_name"
      ;;
    *)
      echo "invalid enable value: $value" >&2
      exit 2
      ;;
  esac
}

run_step() {
  local name="$1"
  shift
  local log="$LOG_DIR/$name.log"
  echo "==> $name"
  (
    cd "$ROOT_DIR"
    "$@"
  ) >"$log" 2>&1 || {
    cat "$log" >&2
    echo "step failed: $name" >&2
    exit 1
  }
  echo "step passed: $name" >>"$log"
  COMPLETED_STEPS+=("$name")
}

run_shell_step() {
  local name="$1"
  local script="$2"
  local log="$LOG_DIR/$name.log"
  echo "==> $name"
  (
    cd "$ROOT_DIR"
    bash -lc "$script"
  ) >"$log" 2>&1 || {
    cat "$log" >&2
    echo "step failed: $name" >&2
    exit 1
  }
  echo "step passed: $name" >>"$log"
  COMPLETED_STEPS+=("$name")
}

skip_step() {
  echo "==> $1 (skipped: $2)"
  SKIPPED_STEPS+=("$1: $2")
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

run_step check-workflows make check-workflows
run_step github-actions-inventory make check-github-actions-inventory
run_step cargo-fmt "$CARGO" fmt --check
run_step cargo-clippy "$CARGO" clippy --workspace --no-default-features --all-targets -- -D warnings
run_step cargo-test "$CARGO" test --workspace --no-default-features
run_step crash-rollback make test-crash-rollback
run_step phase-h-runbooks make check-phase-h-runbooks
run_shell_step server-vet "cd server && $GO vet ./..."
run_shell_step server-test "cd server && $GO test -count=1 ./..."

if [[ "$RUN_NPM_CI" == "1" || "$RUN_NPM_CI" == "true" || "$RUN_NPM_CI" == "yes" || ( "$RUN_NPM_CI" == "auto" && ! -d "$ROOT_DIR/server/webui/node_modules" ) ]]; then
  run_shell_step webui-npm-ci "cd server/webui && $NPM ci"
fi
run_shell_step webui-check "cd server/webui && $NPM run check"
run_shell_step webui-build "cd server/webui && $NPM run build"
run_step admin-runtime make test-admin-runtime
run_step backup-restore scripts/test_backup_restore.sh

if enabled "$RUN_KERNEL" "$DART_BIN"; then
  run_step kernel-compile make test-kernel-compile
else
  skip_step kernel-compile "Dart not available or disabled"
fi

if enabled "$RUN_E2E" "$DART_BIN"; then
  # The e2e exercises both backends incl. snapshot_replace, so build with default
  # features. Store-config (no snapshot_replace) compile + unit tests are already
  # covered by the cargo-clippy / cargo-test --no-default-features steps above.
  run_step build-cli "$CARGO" build -p fcb
  run_shell_step build-server "cd server && $GO build -o ../target/debug/fcb_server ."
  run_shell_step fake-flutter-e2e "FCB_BIN=\"$ROOT_DIR/target/debug/fcb\" SERVER_BIN=\"$ROOT_DIR/target/debug/fcb_server\" DART_BIN=\"$DART_BIN\" bash tests/e2e/test_e2e.sh"
else
  skip_step fake-flutter-e2e "Dart not available or disabled"
fi

if enabled "$RUN_FLUTTER" "$FLUTTER"; then
  run_step flutter-package make test-flutter-package
else
  skip_step flutter-package "Flutter not available or disabled"
fi

if enabled "$RUN_S3"; then
  run_step s3-storage make test-s3-storage
else
  skip_step s3-storage "set FCB_LOCAL_CI_S3=1 to run Docker/MinIO drill"
fi

{
  echo "FCB local core CI passed"
  echo "log_dir: $LOG_DIR"
  echo "kernel: $RUN_KERNEL"
  echo "e2e: $RUN_E2E"
  echo "flutter: $RUN_FLUTTER"
  echo "s3: $RUN_S3"
  echo
  echo "completed_steps:"
  for step in "${COMPLETED_STEPS[@]}"; do
    echo "- $step"
  done
  if [ "${#SKIPPED_STEPS[@]}" -gt 0 ]; then
    echo
    echo "skipped_steps:"
    for step in "${SKIPPED_STEPS[@]}"; do
      echo "- $step"
    done
  fi
} >"$LOG_DIR/summary.txt"

echo "Local core CI passed. Summary: $LOG_DIR/summary.txt"
