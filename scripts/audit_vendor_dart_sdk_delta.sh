#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SDK_DIR="${FCB_VENDOR_SDK_DIR:-$ROOT_DIR/vendor/flutter/engine/src/flutter/third_party/dart}"
FORBIDDEN_ASYNC_PATCH="sdk/lib/_internal/vm/lib/async_patch.dart"

usage() {
  cat <<USAGE
Usage:
  $0

Audits the vendor Dart SDK delta boundary for Phase E. FCB implementation and
test files are allowed; official Dart SDK files are allowed only when they are
the small registration, generated-offset, or lifecycle-hook surfaces needed to
wire FCB in.

Environment:
  FCB_VENDOR_SDK_DIR  Dart SDK checkout. Default: vendor/flutter/engine/src/flutter/third_party/dart
USAGE
}

die() {
  echo "error: $*" >&2
  exit 1
}

is_fcb_owned_path() {
  case "$1" in
    runtime/lib/fcb_*) return 0 ;;
    runtime/vm/fcb_*) return 0 ;;
    sdk/lib/_internal/vm/lib/fcb_*) return 0 ;;
  esac
  return 1
}

is_allowed_official_path() {
  case "$1" in
    runtime/lib/async_sources.gni) return 0 ;;
    runtime/vm/bootstrap_natives.h) return 0 ;;
    runtime/vm/compiler/runtime_offsets_extracted.h) return 0 ;;
    runtime/vm/isolate.cc) return 0 ;;
    runtime/vm/vm_sources.gni) return 0 ;;
    sdk/lib/_internal/vm/lib/vm_internal.gni) return 0 ;;
    sdk/lib/libraries.json) return 0 ;;
    sdk/lib/libraries.yaml) return 0 ;;
  esac
  return 1
}

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
  usage
  exit 0
fi

[ -d "$SDK_DIR/.git" ] || die "missing Dart SDK git checkout: $SDK_DIR"

tmp="$(mktemp "${TMPDIR:-/tmp}/fcb_sdk_delta_XXXXXX")"
trap 'rm -f "$tmp"' EXIT

git -C "$SDK_DIR" status --porcelain --untracked-files=all \
  | sed 's/^...//' \
  | sort -u >"$tmp"

if grep -Fxq "$FORBIDDEN_ASYNC_PATCH" "$tmp"; then
  die "$FORBIDDEN_ASYNC_PATCH must not carry FCB delta; use fcb_async_patch.dart"
fi

unexpected=0
while IFS= read -r path; do
  [ -n "$path" ] || continue
  if is_fcb_owned_path "$path"; then
    continue
  fi
  if is_allowed_official_path "$path"; then
    continue
  fi
  echo "unexpected Dart SDK delta: $path" >&2
  unexpected=1
done <"$tmp"

if [ "$unexpected" -ne 0 ]; then
  die "unexpected official Dart SDK delta found"
fi

echo "vendor Dart SDK delta audit passed"
echo "sdk_dir: $SDK_DIR"
echo "fcb_or_allowed_delta_count: $(wc -l <"$tmp" | tr -d '[:space:]')"
