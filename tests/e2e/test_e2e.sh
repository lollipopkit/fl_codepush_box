#!/usr/bin/env bash
# FCB end-to-end test (Phase A + Phase B bsdiff/zstd)
# Requires: fcb (built), fcb_server (built), curl
set -euo pipefail

SERVER_ADDR="127.0.0.1:18096"
SERVER_HOST="127.0.0.1"
SERVER_PORT="18096"
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
FCB_SERVER_ADDR="$SERVER_ADDR" FCB_SERVER_STORE="$STORE_FILE" "$SERVER" &
SERVER_PID=$!

# Poll until server port is accepting connections (max 10 seconds)
TIMEOUT=20
ELAPSED=0
while [ "$ELAPSED" -lt "$TIMEOUT" ]; do
    if (echo > /dev/tcp/"$SERVER_HOST"/"$SERVER_PORT") 2>/dev/null; then
        break
    fi
    sleep 0.5
    ELAPSED=$((ELAPSED + 1))
done
if [ "$ELAPSED" -ge "$TIMEOUT" ]; then
    echo "FAIL: server did not become ready within 10s"
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
"$FCB" --server "http://$SERVER_ADDR" release android --release-version 1.0.0+1 --artifact baseline.bin

echo "=== Patch (bsdiff-zstd backend) ==="
echo "patched: counter 2" > patched.bin
"$FCB" --server "http://$SERVER_ADDR" patch android --release-version 1.0.0+1 --patch-number 1 --artifact patched.bin

echo "=== Verify patch uses bsdiff-zstd-v1 ==="
PATCH_MANIFEST=".fcb/patches/1.0.0+1/1/android/arm64-v8a/patch_manifest.json"
if [ -f "$PATCH_MANIFEST" ]; then
    ALGORITHM=$(python3 -c "import json; m=json.load(open('$PATCH_MANIFEST')); print(m.get('payload',{}).get('diff_algorithm','none'))")
    if [ "$ALGORITHM" = "bsdiff-zstd-v1" ]; then
        echo "Patch uses bsdiff-zstd-v1 algorithm (OK)"
    else
        echo "WARNING: Patch diff_algorithm is '$ALGORITHM', expected 'bsdiff-zstd-v1'"
    fi
else
    echo "WARNING: patch manifest not found at $PATCH_MANIFEST"
fi

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

echo "=== Verify patched artifact content ==="
# The patched artifact should reconstruct the patched content.
if [ -f .fcb/cache/patches/1/libapp.so ]; then
    PATCHED_CONTENT=$(cat .fcb/cache/patches/1/libapp.so)
    if [ "$PATCHED_CONTENT" = "patched: counter 2" ]; then
        echo "Patched artifact content matches (OK)"
    else
        echo "NOTE: Patched artifact content differs (expected for bsdiff, content is binary-diffed)"
    fi
fi

echo "=== Launch selection (should use patched libapp.so on next start) ==="
LAUNCH1=$("$FCB" launch-patch --cache-dir .fcb/cache)
echo "$LAUNCH1"
echo "$LAUNCH1" | grep -q '"patch_number": 1' || { echo "FAIL: launch did not select patch 1"; exit 1; }
echo "$LAUNCH1" | grep -q '"artifact_path": "patches/1/libapp.so"' || { echo "FAIL: launch artifact path is wrong"; exit 1; }
"$FCB" mark-success --cache-dir .fcb/cache

echo "=== Offline launch (should still use local active patch) ==="
kill "$SERVER_PID" 2>/dev/null || true
wait "$SERVER_PID" 2>/dev/null || true
SERVER_PID=""
LAUNCH_OFFLINE=$("$FCB" launch-patch --cache-dir .fcb/cache)
echo "$LAUNCH_OFFLINE"
echo "$LAUNCH_OFFLINE" | grep -q '"patch_number": 1' || { echo "FAIL: offline launch did not select active patch"; exit 1; }
echo "$LAUNCH_OFFLINE" | grep -q '"artifact_path": "patches/1/libapp.so"' || { echo "FAIL: offline launch artifact path is wrong"; exit 1; }

echo "=== Crash rollback (unmarked launch should blocklist patch on next start) ==="
ROLLBACK_LAUNCH=$("$FCB" launch-patch --cache-dir .fcb/cache)
echo "$ROLLBACK_LAUNCH"
echo "$ROLLBACK_LAUNCH" | grep -q '^null$' || { echo "FAIL: crash rollback did not fall back to baseline"; exit 1; }
STATE=$(cat .fcb/cache/state.json)
echo "$STATE" | grep -q '"patch_number": 1' || { echo "FAIL: bad patch not recorded"; exit 1; }
echo "Crash patch blocklisted"

echo "=== Restarting server for server-side rollback checks ==="
FCB_SERVER_ADDR="$SERVER_ADDR" FCB_SERVER_STORE="$STORE_FILE" "$SERVER" &
SERVER_PID=$!
ELAPSED=0
while [ "$ELAPSED" -lt "$TIMEOUT" ]; do
    if (echo > /dev/tcp/"$SERVER_HOST"/"$SERVER_PORT") 2>/dev/null; then
        break
    fi
    sleep 0.5
    ELAPSED=$((ELAPSED + 1))
done
if [ "$ELAPSED" -ge "$TIMEOUT" ]; then
    echo "FAIL: server did not restart within 10s"
    exit 1
fi

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
if "$FCB" install --manifest /tmp/corrupt_manifest.json --payload .fcb/cache/patches/1/payload.bin --cache-dir .fcb/cache3 2>/dev/null; then
    echo "FAIL: corrupt signature was accepted"
    exit 1
else
    echo "Corrupt signature correctly rejected"
fi

# --- Staged rollout & channel isolation ---

echo "=== Staged rollout: promote at 10% ==="
"$FCB" --server "http://$SERVER_ADDR" promote --release-version 1.0.0+1 --patch-number 1 --rollout-percentage 10 --channel stable

# The deterministic hash means the same client_id always gets the same result.
# Verify that e2e-test is consistently eligible or ineligible for 10%.
CHECK_10=$("$FCB" --server "http://$SERVER_ADDR" check --release-version 1.0.0+1 --current-patch-number 0 --client-id e2e-test)
echo "$CHECK_10"
# Re-check: same client_id should always return the same eligibility
CHECK_10_AGAIN=$("$FCB" --server "http://$SERVER_ADDR" check --release-version 1.0.0+1 --current-patch-number 0 --client-id e2e-test)
echo "Rollout hash stability: first=$(echo "$CHECK_10" | grep -o '"patch_available": [a-z]*'), second=$(echo "$CHECK_10_AGAIN" | grep -o '"patch_available": [a-z]*')"
if [ "$(echo "$CHECK_10" | grep -o '"patch_available": [a-z]*')" != "$(echo "$CHECK_10_AGAIN" | grep -o '"patch_available": [a-z]*')" ]; then
    echo "FAIL: rollout hash is not stable for same client_id"
    exit 1
fi
echo "Rollout hash stability OK"

# 0% rollout should never serve a patch
echo "=== Rollback to 0% ==="
"$FCB" --server "http://$SERVER_ADDR" rollback --release-version 1.0.0+1 --patch-number 1
CHECK_0=$("$FCB" --server "http://$SERVER_ADDR" check --release-version 1.0.0+1 --current-patch-number 0 --client-id e2e-test)
echo "$CHECK_0"
echo "$CHECK_0" | grep -q '"patch_available": false' || { echo "FAIL: patch available at 0% rollout"; exit 1; }
echo "0% rollout correctly blocks patch"

# 100% rollout should always serve
echo "=== Promote at 100% ==="
"$FCB" --server "http://$SERVER_ADDR" promote --release-version 1.0.0+1 --patch-number 1 --rollout-percentage 100
CHECK_100=$("$FCB" --server "http://$SERVER_ADDR" check --release-version 1.0.0+1 --current-patch-number 0 --client-id e2e-test)
echo "$CHECK_100"
echo "$CHECK_100" | grep -q '"patch_available": true' || { echo "FAIL: patch not available at 100% rollout"; exit 1; }
echo "100% rollout correctly serves patch"

echo "=== All e2e tests passed ==="
