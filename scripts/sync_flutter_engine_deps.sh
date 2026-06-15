#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEPOT_TOOLS_DIR="$ROOT_DIR/vendor/depot_tools"
ENGINE_DIR="$ROOT_DIR/vendor/flutter/engine"
ENGINE_SRC_DIR="$ENGINE_DIR/src/flutter"
DEPOT_HOME="${FCB_DEPOT_HOME:-$ROOT_DIR/target/fcb/depot-home}"
VPYTHON_ROOT="${FCB_VPYTHON_ROOT:-$DEPOT_HOME/vpython-root}"
GCLIENT_JOBS="${FCB_GCLIENT_JOBS:-8}"
GCLIENT_DEPS="${FCB_GCLIENT_DEPS:-android}"

usage() {
  cat <<USAGE
Usage:
  $0 [extra gclient sync args...]

Environment:
  FCB_DEPOT_HOME          HOME used for depot_tools/vpython cache.
                          Default: $DEPOT_HOME
  FCB_VPYTHON_ROOT        vpython virtualenv root.
                          Default: $VPYTHON_ROOT
  FCB_GCLIENT_JOBS        gclient parallel jobs. Default: $GCLIENT_JOBS
  FCB_GCLIENT_DEPS        --deps value. Default: android
  FCB_GCLIENT_NOHOOKS     Add --nohooks when set to 1. Default: 0

The script intentionally does not pass --reset, --force, or
--delete_unversioned_trees so local Engine/Dart VM changes are preserved.
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

main() {
  if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
    usage
    exit 0
  fi

  [ -x "$DEPOT_TOOLS_DIR/gclient" ] || die "missing executable: $DEPOT_TOOLS_DIR/gclient"
  [ -f "$ENGINE_DIR/.gclient" ] || die "missing gclient config: $ENGINE_DIR/.gclient"
  [ -d "$ENGINE_SRC_DIR" ] || die "missing Engine source: $ENGINE_SRC_DIR"

  mkdir -p "$DEPOT_HOME" "$VPYTHON_ROOT"

  local sync_cmd=(
    "$DEPOT_TOOLS_DIR/gclient"
    sync
    --jobs "$GCLIENT_JOBS"
    --deps "$GCLIENT_DEPS"
  )

  if [ "${FCB_GCLIENT_NOHOOKS:-0}" = "1" ]; then
    sync_cmd+=(--nohooks)
  fi

  sync_cmd+=("$@")

  (
    cd "$ENGINE_DIR"
    PATH="$DEPOT_TOOLS_DIR:$PATH" \
      HOME="$DEPOT_HOME" \
      VPYTHON_VIRTUALENV_ROOT="$VPYTHON_ROOT" \
      run "${sync_cmd[@]}"
  )
}

main "$@"
