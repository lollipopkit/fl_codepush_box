#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CHECK_ONLY=0
DEPTH="${FCB_VENDOR_DEPTH:-1}"
FLUTTER_REMOTE="${FCB_FLUTTER_REMOTE:-https://github.com/lollipopkit/flutter.git}"
FLUTTER_REF="${FCB_FLUTTER_REF:-stable}"
ENGINE_REMOTE="${FCB_ENGINE_REMOTE:-https://github.com/lollipopkit/flutter.git}"
ENGINE_REF="${FCB_ENGINE_REF:-stable}"
DART_REMOTE="${FCB_DART_REMOTE:-https://github.com/lollipopkit/dartsdk.git}"
DART_REF="${FCB_DART_REF:-stable}"
DEPOT_TOOLS_REMOTE="${FCB_DEPOT_TOOLS_REMOTE:-https://chromium.googlesource.com/chromium/tools/depot_tools.git}"
DEPOT_TOOLS_REF="${FCB_DEPOT_TOOLS_REF:-main}"

usage() {
  cat <<USAGE
Usage:
  $0 [--check]

Bootstraps or validates the local vendor checkouts required by Phase H.

Options:
  --check              Validate only.

Environment:
  FCB_VENDOR_DEPTH       Clone depth for missing vendor checkouts. Default: 1.
  FCB_FLUTTER_REMOTE     Flutter framework checkout remote.
  FCB_FLUTTER_REF        Flutter framework ref. Default: stable.
  FCB_ENGINE_REMOTE      Flutter Engine checkout remote.
  FCB_ENGINE_REF         Flutter Engine ref. Default: stable.
  FCB_DART_REMOTE        Embedded Dart SDK checkout remote.
  FCB_DART_REF           Embedded Dart SDK ref. Default: stable.
  FCB_DEPOT_TOOLS_REMOTE depot_tools checkout remote.
  FCB_DEPOT_TOOLS_REF    depot_tools ref. Default: main.

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

vendor_commit() {
  local path="$1"
  git -C "$ROOT_DIR/$path" rev-parse --short=12 HEAD 2>/dev/null || true
}

clone_vendor() {
  local path="$1"
  local remote="$2"
  local ref="$3"
  local existing="$ROOT_DIR/$path"
  if [ -d "$ROOT_DIR/$path/.git" ]; then
    return
  fi
  if [ -e "$ROOT_DIR/$path" ]; then
    case "$path" in
      vendor/flutter/engine/src/flutter|vendor/flutter/engine/src/flutter/third_party/dart)
        echo "+ replace non-git checkout placeholder $path" >&2
        rm -rf "$existing"
        ;;
      *)
        die "$path exists but is not a git checkout"
        ;;
    esac
  fi
  mkdir -p "$(dirname "$ROOT_DIR/$path")"
  run git clone --depth "$DEPTH" --branch "$ref" "$remote" "$ROOT_DIR/$path"
}

validate_vendor() {
  local path="$1"
  local marker="$2"

  [ -d "$ROOT_DIR/$path/.git" ] || die "$path is missing or is not a git checkout"
  [ -e "$ROOT_DIR/$path/$marker" ] || die "$path is missing expected marker: $marker"

  local commit
  commit="$(vendor_commit "$path")"
  [ -n "$commit" ] || die "could not resolve HEAD for $path"
  printf '%-20s %s checkout\n' "$path" "$commit"
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --check)
      CHECK_ONLY=1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      die "unknown argument: $1"
      ;;
  esac
  shift
done

cd "$ROOT_DIR"

if [ "$CHECK_ONLY" != "1" ]; then
  clone_vendor vendor/flutter "$FLUTTER_REMOTE" "$FLUTTER_REF"
  clone_vendor vendor/flutter/engine/src/flutter "$ENGINE_REMOTE" "$ENGINE_REF"
  clone_vendor vendor/flutter/engine/src/flutter/third_party/dart "$DART_REMOTE" "$DART_REF"
  clone_vendor vendor/depot_tools "$DEPOT_TOOLS_REMOTE" "$DEPOT_TOOLS_REF"
fi

echo "Vendor status:"
validate_vendor vendor/flutter bin/flutter
validate_vendor vendor/flutter/engine/src/flutter DEPS
validate_vendor vendor/flutter/engine/src/flutter/third_party/dart runtime
validate_vendor vendor/depot_tools gclient
