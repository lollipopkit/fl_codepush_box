#!/usr/bin/env bash
# Local Phase B gate for Android snapshot_replace.
#
# This intentionally excludes the real Android device/emulator test. It proves
# the repository-side pieces are coherent before running
# tests/e2e/test_phase_b_android.sh in a Flutter/ADB/local-Engine environment.

set -euo pipefail

REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
CARGO_HOME="${CARGO_HOME:-/tmp/fcb-cargo-home}"
CARGO_TARGET_DIR="${CARGO_TARGET_DIR:-/tmp/fcb-target}"
GOPATH="${GOPATH:-/tmp/fcb-go-path}"
GOCACHE="${GOCACHE:-/tmp/fcb-go-cache}"
GOTMPDIR="${GOTMPDIR:-/tmp}"
FCB_BIN="$CARGO_TARGET_DIR/debug/fcb"
SERVER_BIN="/tmp/fcb_server"

export CARGO_HOME CARGO_TARGET_DIR GOPATH GOCACHE GOTMPDIR

cd "$REPO_ROOT"

echo "=== Phase B shell syntax ==="
bash -n engine_patch/android/apply_engine_patch.sh
bash -n engine_patch/android/test_apply_engine_patch.sh
bash -n engine_patch/android/verify_engine_patch.sh
bash -n engine_patch/android/test_verify_engine_patch.sh
bash -n tests/e2e/phase_b_preflight.sh
bash -n tests/e2e/test_phase_b_preflight.sh
bash -n tests/e2e/test_phase_b_android.sh
bash -n tests/e2e/test_phase_b_android_helpers.sh
bash -n tests/e2e/test_phase_b_android_dry_run.sh
bash -n tests/e2e/verify_phase_b_evidence.sh
bash -n tests/e2e/test_counter_app_phase_b_contract.sh
bash -n tests/e2e/test_android_plugin_paths.sh
bash -n tests/e2e/test_android_native_packaging.sh
bash -n tests/e2e/test_force_extract_native_libs.sh
bash -n tests/e2e/test_e2e.sh

echo "=== Rust format and tests ==="
cargo fmt --check
cargo test
cargo build -p fcb

echo "=== Go server tests and build ==="
(
    cd server
    go test ./...
    go build -o "$SERVER_BIN" .
)

echo "=== Engine hook tests ==="
c++ -std=c++17 -Wall -Wextra -Werror -Iengine_patch/android \
    engine_patch/android/fcb_engine_hook.cc \
    engine_patch/android/fcb_engine_hook_test.cc \
    -o /tmp/fcb_engine_hook_test
/tmp/fcb_engine_hook_test
engine_patch/android/test_apply_engine_patch.sh
engine_patch/android/test_verify_engine_patch.sh

echo "=== Phase B local script tests ==="
tests/e2e/test_android_plugin_paths.sh
tests/e2e/test_android_native_packaging.sh
tests/e2e/test_force_extract_native_libs.sh
tests/e2e/test_counter_app_phase_b_contract.sh
tests/e2e/test_phase_b_android_helpers.sh
tests/e2e/test_phase_b_preflight.sh
tests/e2e/test_phase_b_android_dry_run.sh
ABI=x86_64 TARGET_PLATFORM=android-x64 SERVER_ADDR=127.0.0.1:18198 \
    tests/e2e/test_phase_b_android_dry_run.sh

echo "=== Local CLI/server e2e ==="
FCB_BIN="$FCB_BIN" SERVER_BIN="$SERVER_BIN" tests/e2e/test_e2e.sh

echo "=== Phase B local gate passed ==="
