#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "usage: $0 <sqlite-db> <backup-dir> [objects-dir]" >&2
  exit 2
fi

DB_PATH=$1
BACKUP_DIR=$2
OBJECTS_DIR=${3:-$(dirname "$DB_PATH")/objects}
STAMP=$(date -u +%Y%m%dT%H%M%SZ)
OUT_DIR="$BACKUP_DIR/fcb-backup-$STAMP"

mkdir -p "$OUT_DIR"

if command -v sqlite3 >/dev/null 2>&1; then
  sqlite3 "$DB_PATH" ".backup '$OUT_DIR/fcb.sqlite'"
else
  cp "$DB_PATH" "$OUT_DIR/fcb.sqlite"
fi

if [[ -d "$OBJECTS_DIR" ]]; then
  mkdir -p "$OUT_DIR/objects"
  rsync -a "$OBJECTS_DIR/" "$OUT_DIR/objects/"
fi

cat > "$OUT_DIR/manifest.txt" <<MANIFEST
created_at=$STAMP
source_db=$DB_PATH
source_objects=$OBJECTS_DIR
MANIFEST

echo "$OUT_DIR"
