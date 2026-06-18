#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "usage: $0 <backup-dir> <sqlite-db> [objects-dir]" >&2
  exit 2
fi

BACKUP_DIR=$1
DB_PATH=$2
OBJECTS_DIR=${3:-$(dirname "$DB_PATH")/objects}

if [[ ! -f "$BACKUP_DIR/fcb.sqlite" ]]; then
  echo "backup sqlite not found: $BACKUP_DIR/fcb.sqlite" >&2
  exit 1
fi

mkdir -p "$(dirname "$DB_PATH")"
cp "$BACKUP_DIR/fcb.sqlite" "$DB_PATH"

if [[ -d "$BACKUP_DIR/objects" ]]; then
  mkdir -p "$OBJECTS_DIR"
  rsync -a --delete "$BACKUP_DIR/objects/" "$OBJECTS_DIR/"
fi

echo "restored db=$DB_PATH objects=$OBJECTS_DIR"
