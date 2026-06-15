#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

export FCB_ENGINE_OUT_NAME="${FCB_ENGINE_OUT_NAME:-android_release_arm64}"
export FCB_ANDROID_TARGET_PLATFORM="${FCB_ANDROID_TARGET_PLATFORM:-android-arm64}"
export FCB_REQUIRE_PRIMARY_ABI="${FCB_REQUIRE_PRIMARY_ABI:-1}"
export FCB_WORKDIR="${FCB_WORKDIR:-$ROOT_DIR/target/fcb/phase-d-android-arm64}"

exec "$ROOT_DIR/scripts/test_phase_d_android.sh" "$@"
