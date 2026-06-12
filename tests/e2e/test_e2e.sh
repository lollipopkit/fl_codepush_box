#!/usr/bin/env bash
# Phase A end-to-end test for FCB
# Requires: fcb (built), fcb_server (built), curl
set -euo pipefail

SERVER_ADDR="127.0.0.1:18095"
SERVER_HOST="127.0.0.1"
SERVER_PORT="18095"
WORKDIR=$(mktemp -d /tmp/fcb_e2e_test_XXXXXX)
STORE_FILE="$WORKDIR/store.json"
OBJECTS_DIR="$WORKDIR/objects"
FCB="${FCB_BIN:-fcb}"
SERVER="${SERVER_BIN:-fcb_server}"
SERVER_PID=""

cleanup() {
    if [ -n "$SERVER_PID" ]; then
        kill "$SERVER_PID" 2>/dev/null || true
        wait "$SERVER_PID" 2>/dev/null || true
    fi
    rm -rf "$WORKDIR"
}
trap cleanup EXIT INT TERM

mkdir -p "$OBJECTS_DIR"

echo "=== Starting server ==="
FCB_SERVER_ADDR="$SERVER_ADDR" "$SERVER" -store "$STORE_FILE" -objects "$OBJECTS_DIR" &
SERVER_PID=$!

# Poll until server port is accepting connections (max 10 seconds)
TIMEOUT=10
ELAPSED=0
while [ "$ELAPSED" -lt "$TIMEOUT" ]; do
    if (echo > /dev/tcp/"$SERVER_HOST"/"$SERVER_PORT") 2>/dev/null; then
        break
    fi
    sleep 0.5
    ELAPSED=$((ELAPSED + 1))
done
if [ "$ELAPSED" -ge "$TIMEOUT" ]; then
    echo "FAIL: server did not become ready within ${TIMEOUT}s"
    exit 1
fi

echo "=== Init ==="
cd "$WORKDIR"
"$FCB" init
APP_ID=$(grep 'app_id' fcb.yaml | sed 's/app_id: "\(.*\)"/\1/')
curl -s -X POST "http://$SERVER_ADDR/v1/apps" \
    -H 'Content-Type: application/json' \
    -d "{\"id\":\"$APP_ID\",\"name\":\"E2E Test App\"}"

echo "=== Release ==="
echo "baseline: counter 1" > baseline.bin
"$FCB" --server "http://$SERVER_ADDR" release android --release-version 1.0.0+1 --example baseline.bin

echo "=== Patch ==="
echo "patched: counter 2" > patched.bin
"$FCB" --server "http://$SERVER_ADDR" patch android --release-version 1.0.0+1 --patch-number 1 --payload patched.bin

echo "=== Promote ==="
"$FCB" --server "http://$SERVER_ADDR" promote --release-version 1.0.0+1 --patch-number 1 --rollout-percentage 100

echo "=== Check (should find patch) ==="
CHECK_RESULT=$("$FCB" --server "http://$SERVER_ADDR" check --release-version 1.0.0+1 --current-patch-number 0 --client-id e2e-test)
echo "$CHECK_RESULT"
echo "$CHECK_RESULT" | grep -q '"patch_available": true' || { echo "FAIL: patch not available after promote"; exit 1; }

echo "=== Check --install ==="
"$FCB" --server "http://$SERVER_ADDR" check --release-version 1.0.0+1 --current-patch-number 0 --client-id e2e-test --install --cache-dir .fcb/cache
test -f .fcb/cache/patches/1/libapp.so || { echo "FAIL: patched artifact not found"; exit 1; }
echo "Installed patch successfully"

echo "=== Mark failure (should work) ==="
"$FCB" mark-failure 1 --reason "e2e test" --cache-dir .fcb/cache
STATE=$(cat .fcb/cache/state.json)
echo "$STATE" | grep -q '"patch_number": 1' || { echo "FAIL: bad patch not recorded"; exit 1; }
echo "Bad patch blocklisted"

echo "=== Rollback ==="
"$FCB" --server "http://$SERVER_ADDR" rollback --release-version 1.0.0+1 --patch-number 1

echo "=== Check after rollback (should find no patch) ==="
CHECK2=$("$FCB" --server "http://$SERVER_ADDR" check --release-version 1.0.0+1 --current-patch-number 0 --client-id e2e-test)
echo "$CHECK2"
echo "$CHECK2" | grep -q '"patch_available": false' || { echo "FAIL: patch still available after rollback"; exit 1; }

echo "=== Invalid signature rejection ==="
cp .fcb/cache/patches/1/manifest.json /tmp/corrupt_manifest.json
python3 -c "
import json
with open('/tmp/corrupt_manifest.json') as f:
    m = json.load(f)
m['signature']['value'] = 'AAAA' + m['signature']['value'][4:]
with open('/tmp/corrupt_manifest.json', 'w') as f:
    json.dump(m, f)
"
if "$FCB" install --manifest /tmp/corrupt_manifest.json --payload .fcb/cache/patches/1/payload.bin --cache-dir .fcb/cache2 2>/dev/null; then
    echo "FAIL: corrupt signature was accepted"
    exit 1
else
    echo "Corrupt signature correctly rejected"
fi

echo "=== All e2e tests passed ==="
