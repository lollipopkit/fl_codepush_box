#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FLUTTER_DIR="$ROOT_DIR/vendor/flutter"
ENGINE_DIR="$FLUTTER_DIR/engine"
ENGINE_SRC_DIR="$ENGINE_DIR/src"
DEPOT_TOOLS_DIR="$ROOT_DIR/vendor/depot_tools"

FCB_IOS_CPU="${FCB_IOS_CPU:-arm64}"          # arm64 (device/simulator) | x64 (simulator)
FCB_RUNTIME_MODE="${FCB_RUNTIME_MODE:-release}"
FCB_IOS_SIMULATOR="${FCB_IOS_SIMULATOR:-0}"
FCB_SKIP_SYNC="${FCB_SKIP_SYNC:-0}"
FCB_SKIP_GN="${FCB_SKIP_GN:-0}"
FCB_SKIP_NINJA="${FCB_SKIP_NINJA:-0}"
FCB_UPDATER_STATICLIB="${FCB_UPDATER_STATICLIB:-}"

OUT_DIR_NAME="ios_${FCB_RUNTIME_MODE}"
if [ "$FCB_IOS_SIMULATOR" = "1" ]; then
  OUT_DIR_NAME="${OUT_DIR_NAME}_sim"
  if [ "$FCB_IOS_CPU" != "x64" ]; then
    OUT_DIR_NAME="${OUT_DIR_NAME}_${FCB_IOS_CPU}"
  fi
fi
OUT_DIR="$ENGINE_SRC_DIR/out/$OUT_DIR_NAME"

usage() {
  cat <<USAGE
Usage: $0 [options]

Build the FCB iOS Engine with bytecode patch support.

Environment:
  FCB_IOS_CPU          arm64 (device/simulator) or x64 (simulator). Default: arm64
  FCB_IOS_SIMULATOR    Build simulator engine when set to 1. Default: 0
  FCB_RUNTIME_MODE     release | profile | debug. Default: release
  FCB_SKIP_SYNC        Skip sync_dart_vm_patch.sh when set to 1. Default: 0
  FCB_SKIP_GN          Skip GN generation. Default: 0
  FCB_SKIP_NINJA       Skip ninja build. Default: 0
  FCB_UPDATER_STATICLIB  Path to pre-built libfcb_updater.a for iOS.
                         Auto-built if empty.

Output:
  $OUT_DIR/Flutter.framework  (or similar)
USAGE
}

die() { echo "error: $*" >&2; exit 1; }
run() { echo "+ $*" >&2; "$@"; }

build_updater_staticlib() {
  if [ -n "$FCB_UPDATER_STATICLIB" ]; then
    echo "Using pre-built updater: $FCB_UPDATER_STATICLIB"
    return
  fi

  local rust_target
  if [ "$FCB_IOS_CPU" = "x64" ]; then
    rust_target="x86_64-apple-ios"
  elif [ "$FCB_IOS_SIMULATOR" = "1" ]; then
    rust_target="aarch64-apple-ios-sim"
  else
    rust_target="aarch64-apple-ios"
  fi

  echo "Building libfcb_updater.a for $rust_target..."
  run cargo build --target "$rust_target" --release -p fcb_updater \
      --manifest-path "$ROOT_DIR/Cargo.toml"

  FCB_UPDATER_STATICLIB="$ROOT_DIR/target/$rust_target/release/libfcb_updater.a"
  echo "Updater staticlib: $FCB_UPDATER_STATICLIB"
}

main() {
  if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
    usage; exit 0
  fi

  [ -d "$ENGINE_SRC_DIR" ] || die "Engine src missing: $ENGINE_SRC_DIR. Run scripts/sync_flutter_engine_deps.sh first."
  [ -x "$DEPOT_TOOLS_DIR/gclient" ] || die "depot_tools missing: $DEPOT_TOOLS_DIR"

  if [ "$FCB_SKIP_SYNC" != "1" ]; then
    echo "Syncing Dart VM patch..."
    run "$ROOT_DIR/scripts/sync_dart_vm_patch.sh"
  fi

  build_updater_staticlib

  if [ "$FCB_SKIP_GN" != "1" ]; then
    local gn_ios_args=(--ios)
    if [ "$FCB_IOS_SIMULATOR" = "1" ]; then
      gn_ios_args+=(--simulator --simulator-cpu "$FCB_IOS_CPU")
    fi

    echo "Running GN for iOS $FCB_IOS_CPU $FCB_RUNTIME_MODE..."
    run env PATH="$DEPOT_TOOLS_DIR:$PATH" \
      "$ENGINE_SRC_DIR/flutter/tools/gn" \
        "${gn_ios_args[@]}" \
        --runtime-mode "$FCB_RUNTIME_MODE" \
        --gn-args "fcb_enable_code_push=true" \
        --gn-args "fcb_updater_staticlib=\"$FCB_UPDATER_STATICLIB\""
  fi

  if [ "$FCB_SKIP_NINJA" != "1" ]; then
    echo "Building iOS Engine with ninja..."
    run env PATH="$DEPOT_TOOLS_DIR:$PATH" \
      ninja -C "$OUT_DIR" flutter/shell/platform/darwin/ios:flutter_framework
  fi

  echo ""
  echo "iOS Engine build complete: $OUT_DIR"
}

main "$@"
