#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ACTIONLINT_VERSION="${ACTIONLINT_VERSION:-v1.7.12}"
GOCACHE="${GOCACHE:-$ROOT_DIR/.tmp/go-cache}"
GOMODCACHE="${GOMODCACHE:-$ROOT_DIR/.tmp/go-mod}"
GOPATH="${GOPATH:-$ROOT_DIR/.tmp/go}"

if [ "$#" -eq 0 ]; then
  set -- "$ROOT_DIR"/.github/workflows/*.yml
fi

mkdir -p "$GOCACHE" "$GOMODCACHE" "$GOPATH"

GOCACHE="$GOCACHE" \
GOMODCACHE="$GOMODCACHE" \
GOPATH="$GOPATH" \
  go run "github.com/rhysd/actionlint/cmd/actionlint@$ACTIONLINT_VERSION" "$@"
