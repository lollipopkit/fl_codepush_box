#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENGINE_DART_DIR="$ROOT_DIR/vendor/flutter/engine/src/flutter/third_party/dart"

if [ ! -d "$ENGINE_DART_DIR/.git" ]; then
  echo "missing Engine Dart SDK checkout: $ENGINE_DART_DIR" >&2
  exit 1
fi

git -C "$ENGINE_DART_DIR" pull origin stable
echo "synced Engine Dart SDK to: $(git -C "$ENGINE_DART_DIR" rev-parse HEAD)"
