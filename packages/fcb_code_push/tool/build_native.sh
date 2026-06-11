#!/usr/bin/env sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
PACKAGE_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
REPO_DIR=$(CDPATH= cd -- "$PACKAGE_DIR/../.." && pwd)

cargo build --manifest-path "$REPO_DIR/Cargo.toml" -p fcb_updater

case "$(uname -s)" in
  Darwin)
    LIB_NAME=libfcb_updater.dylib
    ;;
  Linux)
    LIB_NAME=libfcb_updater.so
    ;;
  MINGW*|MSYS*|CYGWIN*)
    LIB_NAME=fcb_updater.dll
    ;;
  *)
    echo "unsupported host OS: $(uname -s)" >&2
    exit 1
    ;;
esac

mkdir -p "$PACKAGE_DIR/native"
cp "$REPO_DIR/target/debug/$LIB_NAME" "$PACKAGE_DIR/native/$LIB_NAME"
echo "$PACKAGE_DIR/native/$LIB_NAME"
