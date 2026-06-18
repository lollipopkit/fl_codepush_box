#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEPTH="${FCB_SUBMODULE_DEPTH:-100}"
STRICT_SUBMODULES=0
CHECK_ONLY=0

usage() {
  cat <<USAGE
Usage:
  $0 [--check] [--strict-submodules]

Bootstraps or validates the vendor checkouts required by Phase H.

Options:
  --check              Validate only; do not run git submodule update.
  --strict-submodules  Require vendor entries to be registered in .gitmodules.

Environment:
  FCB_SUBMODULE_DEPTH  Depth for git submodule update. Default: 100.
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

has_submodule() {
  local path="$1"
  [ -f "$ROOT_DIR/.gitmodules" ] &&
    git -C "$ROOT_DIR" config -f .gitmodules --get-regexp '^submodule\..*\.path$' |
      awk '{print $2}' |
      grep -Fxq "$path"
}

vendor_commit() {
  local path="$1"
  git -C "$ROOT_DIR/$path" rev-parse --short=12 HEAD 2>/dev/null || true
}

validate_vendor() {
  local path="$1"
  local marker="$2"
  local submodule="$3"
  local strict_required="${4:-1}"

  if [ "$STRICT_SUBMODULES" = "1" ] && [ "$strict_required" = "1" ] && [ "$submodule" != "1" ]; then
    die "$path is not registered as a git submodule"
  fi
  [ -d "$ROOT_DIR/$path/.git" ] || die "$path is missing or is not a git checkout"
  [ -e "$ROOT_DIR/$path/$marker" ] || die "$path is missing expected marker: $marker"

  local commit
  commit="$(vendor_commit "$path")"
  [ -n "$commit" ] || die "could not resolve HEAD for $path"
  printf '%-20s %s %s\n' "$path" "$commit" "$(if [ "$submodule" = "1" ]; then echo submodule; else echo checkout; fi)"
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --check)
      CHECK_ONLY=1
      ;;
    --strict-submodules)
      STRICT_SUBMODULES=1
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

if [ "$CHECK_ONLY" != "1" ] && [ -f .gitmodules ]; then
  run git submodule update --init --recursive --depth "$DEPTH"
fi

flutter_submodule=0
depot_tools_submodule=0
has_submodule vendor/flutter && flutter_submodule=1
has_submodule vendor/depot_tools && depot_tools_submodule=1

if [ "$STRICT_SUBMODULES" = "1" ] && [ ! -f .gitmodules ]; then
  die ".gitmodules is missing; vendor submodule registration is not complete"
fi

echo "Vendor status:"
validate_vendor vendor/flutter bin/flutter "$flutter_submodule"
validate_vendor vendor/flutter/engine/src/flutter/third_party/dart runtime 0 0
validate_vendor vendor/depot_tools gclient "$depot_tools_submodule"
