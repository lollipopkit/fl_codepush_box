#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VENDOR_DIR="$ROOT_DIR/vendor"
FLUTTER_DIR="$VENDOR_DIR/flutter"
ENGINE_DIR="$FLUTTER_DIR/engine"
ENGINE_SRC_DIR="$ENGINE_DIR/src/flutter"
ENGINE_VERSION_FILE="$FLUTTER_DIR/bin/internal/engine.version"

if [ ! -d "$FLUTTER_DIR/.git" ]; then
  echo "missing Flutter checkout: $FLUTTER_DIR" >&2
  exit 1
fi

if [ "${FCB_FLUTTER_UPDATE:-0}" = "1" ]; then
  (
    cd "$FLUTTER_DIR"
    git remote add upstream https://github.com/flutter/flutter 2>/dev/null ||
      git remote set-url upstream https://github.com/flutter/flutter
    git fetch upstream stable --tags
    git switch stable
    git reset --hard upstream/stable
  )
fi

if [ ! -f "$ENGINE_VERSION_FILE" ]; then
  echo "missing Engine revision file: $ENGINE_VERSION_FILE" >&2
  exit 1
fi

ENGINE_REV="$(tr -d '[:space:]' < "$ENGINE_VERSION_FILE")"
if [ -z "$ENGINE_REV" ]; then
  echo "empty Engine revision in $ENGINE_VERSION_FILE" >&2
  exit 1
fi

if [ ! -d "$ENGINE_SRC_DIR" ]; then
  echo "missing embedded Engine source directory: $ENGINE_SRC_DIR" >&2
  echo "update vendor/flutter to a modern stable checkout first" >&2
  exit 1
fi

if [ ! -d "$ENGINE_SRC_DIR/shell/platform/android" ]; then
  echo "missing Android Engine source directory: $ENGINE_SRC_DIR/shell/platform/android" >&2
  exit 1
fi

echo "Flutter checkout:"
echo "  dir:      $FLUTTER_DIR"
echo "  revision: $(git -C "$FLUTTER_DIR" rev-parse HEAD)"
echo "  branch:   $(git -C "$FLUTTER_DIR" branch --show-current)"
echo "  version:  $(git -C "$FLUTTER_DIR" describe --tags --exact-match 2>/dev/null || git -C "$FLUTTER_DIR" describe --tags --always)"
echo
echo "Embedded Flutter Engine:"
echo "  dir:      $ENGINE_SRC_DIR"
echo "  revision: $ENGINE_REV"
echo "  android:  $ENGINE_SRC_DIR/shell/platform/android"
