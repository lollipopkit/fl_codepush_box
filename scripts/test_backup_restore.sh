#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
WORKDIR=$(mktemp -d /tmp/fcb_backup_restore_test_XXXXXX)

cleanup() {
  if [[ "${FCB_KEEP_BACKUP_RESTORE_TEST:-}" = "1" ]]; then
    echo "keeping backup/restore test workdir: $WORKDIR"
    return
  fi
  rm -rf "$WORKDIR"
}
trap cleanup EXIT INT TERM

SRC_DB="$WORKDIR/src/fcb.sqlite"
SRC_OBJECTS="$WORKDIR/src/objects"
BACKUPS="$WORKDIR/backups"
RESTORE_DB="$WORKDIR/restore/fcb.sqlite"
RESTORE_OBJECTS="$WORKDIR/restore/objects"

mkdir -p "$(dirname "$SRC_DB")" "$SRC_OBJECTS/patches/app/1/android/arm64-v8a/1"
sqlite3 "$SRC_DB" "create table apps(id text primary key, name text); insert into apps values('app-a','App A');"
printf 'payload-data' >"$SRC_OBJECTS/patches/app/1/android/arm64-v8a/1/payload.bin"

BACKUP_DIR=$("$ROOT_DIR/scripts/server_backup.sh" "$SRC_DB" "$BACKUPS" "$SRC_OBJECTS")
rm -rf "$(dirname "$SRC_DB")"
"$ROOT_DIR/scripts/server_restore.sh" "$BACKUP_DIR" "$RESTORE_DB" "$RESTORE_OBJECTS" >/dev/null

ROW=$(sqlite3 "$RESTORE_DB" "select id || ':' || name from apps")
PAYLOAD=$(cat "$RESTORE_OBJECTS/patches/app/1/android/arm64-v8a/1/payload.bin")

if [[ "$ROW" != "app-a:App A" ]]; then
  echo "restore sqlite row mismatch: $ROW" >&2
  exit 1
fi
if [[ "$PAYLOAD" != "payload-data" ]]; then
  echo "restore object payload mismatch: $PAYLOAD" >&2
  exit 1
fi

echo "backup/restore drill passed: backup=$BACKUP_DIR"
