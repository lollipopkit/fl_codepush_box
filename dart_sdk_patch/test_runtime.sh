#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="${TMPDIR:-/tmp}/fcb_patch_runtime_test"

c++ -std=c++17 -Wall -Wextra -Werror \
  -I"$ROOT_DIR/dart_sdk_patch/runtime" \
  "$ROOT_DIR/dart_sdk_patch/runtime/fcb_patch_runtime.cc" \
  "$ROOT_DIR/dart_sdk_patch/runtime/fcb_patch_runtime_test.cc" \
  -o "$OUT"
"$OUT"
