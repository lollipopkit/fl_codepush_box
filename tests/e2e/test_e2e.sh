#!/usr/bin/env bash
# Phase A end-to-end test for FCB
# Requires: fcb (built), fcb_server (built), curl
set -euo pipefail

REPO_ROOT=$(pwd)
SERVER_ADDR="127.0.0.1:18095"
SERVER_HOST="127.0.0.1"
SERVER_PORT="18095"
WORKDIR=$(mktemp -d /tmp/fcb_e2e_test_XXXXXX)
STORE_FILE="$WORKDIR/store.json"
OBJECTS_DIR="$WORKDIR/objects"
PROJECT_DIR="$WORKDIR/counter_project"
FAKE_FLUTTER="$WORKDIR/fake_flutter_sdk/bin/flutter"
FCB="${FCB_BIN:-fcb}"
SERVER="${SERVER_BIN:-fcb_server}"
SERVER_PID=""
FCB_CLI_TOKEN=""
COOKIE_JAR="$WORKDIR/cookies.txt"

if [[ "$FCB" == */* ]]; then
    FCB=$(cd "$(dirname "$FCB")" && pwd)/$(basename "$FCB")
fi
if [[ "$SERVER" == */* ]]; then
    SERVER=$(cd "$(dirname "$SERVER")" && pwd)/$(basename "$SERVER")
fi

cleanup() {
    if [ "${FCB_E2E_KEEP_WORKDIR:-}" = "1" ]; then
        echo "keeping e2e workdir: $WORKDIR"
        return
    fi
    if [ -n "$SERVER_PID" ]; then
        kill "$SERVER_PID" 2>/dev/null || true
        wait "$SERVER_PID" 2>/dev/null || true
    fi
    rm -rf "$WORKDIR"
}
trap cleanup EXIT INT TERM

mkdir -p "$OBJECTS_DIR"
mkdir -p "$PROJECT_DIR/lib"
mkdir -p "$(dirname "$FAKE_FLUTTER")"
mkdir -p "$WORKDIR/fake_flutter_sdk/bin/cache/dart-sdk/bin"
if [ -x "$REPO_ROOT/vendor/flutter/bin/cache/dart-sdk/bin/dart" ]; then
    DEFAULT_DART_BIN="$REPO_ROOT/vendor/flutter/bin/cache/dart-sdk/bin/dart"
else
    DEFAULT_DART_BIN="$(command -v dart)"
fi
DART_BIN="${DART_BIN:-$DEFAULT_DART_BIN}"
ln -s "$DART_BIN" "$WORKDIR/fake_flutter_sdk/bin/cache/dart-sdk/bin/dart"
cat >"$PROJECT_DIR/pubspec.yaml" <<'YAML'
name: fcb_e2e_counter
version: 1.0.0+1
YAML
cat >"$PROJECT_DIR/lib/main.dart" <<'DART'
int mainValue() {
  return 1;
}

void main() {
  mainValue();
}
DART
cat >"$FAKE_FLUTTER" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
if [ "${1:-}" = "--version" ]; then
  echo "Flutter fake-e2e"
  exit 0
fi
if [ "${1:-}" = "--no-version-check" ]; then
  shift
fi
if [ "${1:-}" != "build" ]; then
  echo "unexpected fake flutter command: $*" >&2
  exit 2
fi
shift
case "${1:-}" in
  apk)
    mkdir -p build/app/intermediates/flutter/release/arm64-v8a
    mkdir -p build/app/intermediates/flutter/release/flutter_assets
    mkdir -p build/app/intermediates/merged_native_libs/release/out/lib/arm64-v8a
    cp lib/main.dart build/app/intermediates/flutter/release/arm64-v8a/app.so
    cp lib/main.dart build/app/intermediates/merged_native_libs/release/out/lib/arm64-v8a/libapp.so
    echo '{"assets":[]}' > build/app/intermediates/flutter/release/flutter_assets/AssetManifest.bin.json
    echo '{}' > build/app/intermediates/flutter/release/flutter_assets/AssetManifest.json
    echo native > build/app/intermediates/merged_native_libs/release/out/lib/arm64-v8a/libfake.so
    ;;
  ios)
    mkdir -p build/ios/iphoneos/Runner.app/Frameworks/App.framework/flutter_assets
    echo '{"assets":[]}' > build/ios/iphoneos/Runner.app/Frameworks/App.framework/flutter_assets/AssetManifest.bin.json
    echo '{}' > build/ios/iphoneos/Runner.app/Frameworks/App.framework/flutter_assets/AssetManifest.json
    ;;
  bundle)
    mkdir -p build/flutter_assets
    BUILD_ID=$(cksum lib/main.dart | awk '{print $1}')
    mkdir -p ".dart_tool/flutter_build/$BUILD_ID"
    echo '{"assets":[]}' > build/flutter_assets/AssetManifest.bin.json
    "$(dirname "$0")/cache/dart-sdk/bin/dart" compile kernel --no-link-platform -o ".dart_tool/flutter_build/$BUILD_ID/app.dill" lib/main.dart >/dev/null
    ;;
  *)
    echo "unexpected fake flutter build target: ${1:-}" >&2
    exit 2
    ;;
esac
SH
chmod +x "$FAKE_FLUTTER"

INVENTORY_PROJECT="$WORKDIR/inventory_project"
mkdir -p "$INVENTORY_PROJECT/lib"
cat >"$INVENTORY_PROJECT/pubspec.yaml" <<'YAML'
name: fcb_inventory_fixture
version: 1.0.0
YAML
cat >"$INVENTORY_PROJECT/lib/main.dart" <<'DART'
mixin PriceMixin {
  int mixinValue() {
    return 1;
  }
}

class BasePrice {}
class CombinedPrice = BasePrice with PriceMixin;

class ConstructedPrice {
  ConstructedPrice(this.value);
  final int value;
}

extension PriceExtension on int {
  int addOne() {
    return this + 1;
  }
}

T genericIdentity<T>(T value) {
  return value;
}

int usesClosure(int value) {
  final add = (int x) {
    return x + 1;
  };
  return add(value);
}
DART
echo "=== Kernel inventory stability ==="
"$DART_BIN" "$REPO_ROOT/tool/fcb_kernel_manifest.dart" --project "$INVENTORY_PROJECT" --target lib/main.dart >"$WORKDIR/inventory1.json"
"$DART_BIN" "$REPO_ROOT/tool/fcb_kernel_manifest.dart" --project "$INVENTORY_PROJECT" --target lib/main.dart >"$WORKDIR/inventory2.json"
cmp "$WORKDIR/inventory1.json" "$WORKDIR/inventory2.json" || { echo "FAIL: kernel inventory is not stable"; exit 1; }
python3 - "$WORKDIR/inventory1.json" <<'PY'
import json, sys
with open(sys.argv[1]) as f:
    data = json.load(f)
assert data["inventory_source"] == "kernel_ast"
members = {fn["member_name"]: fn for fn in data["functions"]}
classes = json.dumps(data["classes"])
assert any("PriceMixin" in key for key in classes.split('"'))
assert any("CombinedPrice" in key for key in classes.split('"'))
assert any("ConstructedPrice" in key for key in classes.split('"'))
assert any("genericIdentity" == name for name in members)
assert any("addOne" in name for name in members)
assert members["usesClosure"]["unsupported_reasons"] == ["unsupported_kernel_node"]
assert any(fn["enclosing"] == "class:ConstructedPrice" and fn["unsupported_reasons"] == ["unsupported_kernel_node"] for fn in data["functions"])
PY

echo "=== Starting server ==="
FCB_SERVER_ADDR="$SERVER_ADDR" "$SERVER" -store "$STORE_FILE" -objects "$OBJECTS_DIR" &
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

echo "=== Server setup ==="
SETUP_RESULT=$(curl -s -X POST "http://$SERVER_ADDR/api/auth/setup" \
    -H 'Content-Type: application/json' \
    -d '{"username":"admin","password":"e2e-password","token_name":"e2e"}')
FCB_CLI_TOKEN=$(python3 -c 'import json,sys; print(json.load(sys.stdin)["token"])' <<<"$SETUP_RESULT")
export FCB_CLI_TOKEN
LOGIN_STATUS=$(curl -s -o "$WORKDIR/login.json" -w '%{http_code}' -c "$COOKIE_JAR" \
    -X POST "http://$SERVER_ADDR/api/auth/login" \
    -H 'Content-Type: application/json' \
    -d '{"username":"admin","password":"e2e-password"}')
if [ "$LOGIN_STATUS" != "200" ]; then
    echo "FAIL: admin login returned HTTP $LOGIN_STATUS"
    cat "$WORKDIR/login.json"
    exit 1
fi

echo "=== Init ==="
cd "$WORKDIR"
INIT_OUTPUT=$("$FCB" --server "http://$SERVER_ADDR" init)
echo "$INIT_OUTPUT"
APP_ID=$(printf '%s\n' "$INIT_OUTPUT" | awk -F= '$1 == "APP_ID" { print $2; exit }')

echo "=== Release ==="
"$FCB" --server "http://$SERVER_ADDR" release android --release-version 1.0.0+1 --project "$PROJECT_DIR" --flutter "$FAKE_FLUTTER"
test -f .fcb/apps/"$APP_ID"/releases/1.0.0+1/android/arm64-v8a/app.so || { echo "FAIL: release app.so not found"; exit 1; }
test -f .fcb/apps/"$APP_ID"/releases/1.0.0+1/android/arm64-v8a/build_info.json || { echo "FAIL: release build_info.json not found"; exit 1; }

echo "=== Patch ==="
cat >"$PROJECT_DIR/lib/main.dart" <<'DART'
int mainValue() {
  return 2;
}

void main() {
  mainValue();
}
DART
"$FCB" --server "http://$SERVER_ADDR" patch android --release-version 1.0.0+1 --patch-number 1 --project "$PROJECT_DIR" --flutter "$FAKE_FLUTTER"
grep -q '"diff_algorithm"[[:space:]]*:[[:space:]]*"bsdiff-zstd-v1"' .fcb/patches/1.0.0+1/1/android/arm64-v8a/patch_manifest.json || {
    echo "FAIL: patch did not use bsdiff-zstd-v1"
    exit 1
}
test -f .fcb/patches/1.0.0+1/1/android/arm64-v8a/patch_report.json || { echo "FAIL: patch_report.json not found"; exit 1; }

echo "=== iOS bytecode release ==="
cat >"$PROJECT_DIR/lib/main.dart" <<'DART'
int mainValue() {
  return 3;
}

void main() {
  mainValue();
}
DART
"$FCB" --server "http://$SERVER_ADDR" release ios --release-version 1.0.0+1 --arch arm64 --project "$PROJECT_DIR" --flutter "$FAKE_FLUTTER"
test -f .fcb/apps/"$APP_ID"/releases/1.0.0+1/ios/arm64/kernel_inventory.json || { echo "FAIL: iOS kernel_inventory.json not found"; exit 1; }
test -f .fcb/apps/"$APP_ID"/releases/1.0.0+1/ios/arm64/build_info.json || { echo "FAIL: iOS build_info.json not found"; exit 1; }

echo "=== iOS bytecode patch ==="
cat >"$PROJECT_DIR/lib/main.dart" <<'DART'
int mainValue() {
  return 4;
}

void main() {
  mainValue();
}
DART
"$FCB" --server "http://$SERVER_ADDR" patch ios --release-version 1.0.0+1 --patch-number 1 --arch arm64 --project "$PROJECT_DIR" --flutter "$FAKE_FLUTTER"
grep -q '"kind"[[:space:]]*:[[:space:]]*"bytecode_module"' .fcb/patches/1.0.0+1/1/ios/arm64/patch_manifest.json || {
    echo "FAIL: iOS patch did not use bytecode_module"
    exit 1
}
grep -q '"interpret"' .fcb/patches/1.0.0+1/1/ios/arm64/patch_report.json || {
    echo "FAIL: iOS patch_report missing linker interpret list"
    exit 1
}
python3 - <<'PY'
from pathlib import Path
payload = Path(".fcb/patches/1.0.0+1/1/ios/arm64/payload.bin")
if payload.read_bytes()[:4] != b"FCBM":
    raise SystemExit("FAIL: iOS bytecode payload is not binary FCBM")
PY

echo "=== Promote iOS bytecode ==="
"$FCB" --server "http://$SERVER_ADDR" promote --release-version 1.0.0+1 --patch-number 1 --platform ios --arch arm64 --rollout-percentage 100

echo "=== Check --install iOS bytecode ==="
"$FCB" --server "http://$SERVER_ADDR" check --release-version 1.0.0+1 --platform ios --arch arm64 --current-patch-number 0 --client-id e2e-ios-bytecode --install --cache-dir .fcb/cache-ios-bytecode
test -f .fcb/cache-ios-bytecode/patches/1/payload.bin || { echo "FAIL: iOS bytecode payload not installed"; exit 1; }
python3 - <<'PY'
import json
from pathlib import Path
cache = Path(".fcb/cache-ios-bytecode")
payload = cache / "patches/1/payload.bin"
if payload.read_bytes()[:4] != b"FCBM":
    raise SystemExit("FAIL: installed iOS bytecode payload is not binary FCBM")
state = json.loads((cache / "state.json").read_text())
installed = state["installed"][0]
if installed["backend"] != "bytecode":
    raise SystemExit("FAIL: installed iOS patch backend is not bytecode")
if installed.get("artifact_path") is not None:
    raise SystemExit("FAIL: bytecode install should not materialize artifact_path")
PY

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
CORRUPT_MANIFEST="$WORKDIR/corrupt_manifest.json"
cp .fcb/cache/patches/1/manifest.json "$CORRUPT_MANIFEST"
python3 -c "
import json
path = '$CORRUPT_MANIFEST'
with open(path) as f:
    m = json.load(f)
m['signature']['value'] = 'AAAA' + m['signature']['value'][4:]
with open(path, 'w') as f:
    json.dump(m, f)
"
if "$FCB" install --manifest "$CORRUPT_MANIFEST" --payload .fcb/cache/patches/1/payload.bin --cache-dir .fcb/cache2 2>/dev/null; then
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

echo "=== Multi-app isolation ==="
SECOND_APP_ID="00000000-0000-0000-0000-0000000000e2"
"$FCB" app add E2ESecond --id "$SECOND_APP_ID"
cat >"$PROJECT_DIR/lib/main.dart" <<'DART'
int mainValue() {
  return 10;
}

void main() {
  mainValue();
}
DART
"$FCB" --server "http://$SERVER_ADDR" release android --release-version 1.0.0+1 --project "$PROJECT_DIR" --flutter "$FAKE_FLUTTER"
cat >"$PROJECT_DIR/lib/main.dart" <<'DART'
int mainValue() {
  return 20;
}

void main() {
  mainValue();
}
DART
"$FCB" --server "http://$SERVER_ADDR" patch android --release-version 1.0.0+1 --patch-number 1 --project "$PROJECT_DIR" --flutter "$FAKE_FLUTTER"
"$FCB" --server "http://$SERVER_ADDR" promote --release-version 1.0.0+1 --patch-number 1 --rollout-percentage 100
SECOND_CHECK=$("$FCB" --server "http://$SERVER_ADDR" check --release-version 1.0.0+1 --current-patch-number 0 --client-id e2e-test)
echo "$SECOND_CHECK"
echo "$SECOND_CHECK" | grep -q "$SECOND_APP_ID" || { echo "FAIL: second app check did not use second app id"; exit 1; }
FIRST_CHECK=$("$FCB" --app "$APP_ID" --server "http://$SERVER_ADDR" check --release-version 1.0.0+1 --current-patch-number 0 --client-id e2e-test)
echo "$FIRST_CHECK"
echo "$FIRST_CHECK" | grep -q "$APP_ID" || { echo "FAIL: first app check did not stay isolated"; exit 1; }

echo "=== Org-scoped CLI check ==="
curl -fsS -b "$COOKIE_JAR" -X POST "http://$SERVER_ADDR/api/admin/orgs" \
    -H 'Content-Type: application/json' \
    -d '{"id":"acme","name":"Acme"}' >/dev/null
ACME_TOKEN_RESULT=$(curl -fsS -b "$COOKIE_JAR" -X POST "http://$SERVER_ADDR/api/admin/orgs/acme/cli-tokens" \
    -H 'Content-Type: application/json' \
    -d '{"name":"acme-e2e"}')
ACME_TOKEN=$(python3 -c 'import json,sys; print(json.load(sys.stdin)["token"])' <<<"$ACME_TOKEN_RESULT")
ACME_DIR="$WORKDIR/acme_cli"
mkdir -p "$ACME_DIR"
cd "$ACME_DIR"
ACME_INIT_OUTPUT=$(FCB_CLI_TOKEN="$ACME_TOKEN" "$FCB" --server "http://$SERVER_ADDR" init --name SharedOrgApp)
echo "$ACME_INIT_OUTPUT"
ACME_APP_ID=$(printf '%s\n' "$ACME_INIT_OUTPUT" | awk -F= '$1 == "APP_ID" { print $2; exit }')
cat >"$PROJECT_DIR/lib/main.dart" <<'DART'
int mainValue() {
  return 30;
}

void main() {
  mainValue();
}
DART
FCB_CLI_TOKEN="$ACME_TOKEN" "$FCB" --server "http://$SERVER_ADDR" release android --release-version 2.0.0+1 --project "$PROJECT_DIR" --flutter "$FAKE_FLUTTER"
cat >"$PROJECT_DIR/lib/main.dart" <<'DART'
int mainValue() {
  return 31;
}

void main() {
  mainValue();
}
DART
FCB_CLI_TOKEN="$ACME_TOKEN" "$FCB" --server "http://$SERVER_ADDR" patch android --release-version 2.0.0+1 --patch-number 1 --project "$PROJECT_DIR" --flutter "$FAKE_FLUTTER"
FCB_CLI_TOKEN="$ACME_TOKEN" "$FCB" --server "http://$SERVER_ADDR" promote --release-version 2.0.0+1 --patch-number 1 --rollout-percentage 100
ACME_CHECK=$(FCB_CLI_TOKEN="$ACME_TOKEN" "$FCB" --server "http://$SERVER_ADDR" check --release-version 2.0.0+1 --current-patch-number 0 --client-id acme-e2e)
echo "$ACME_CHECK"
echo "$ACME_CHECK" | grep -q '"patch_available": true' || { echo "FAIL: org-scoped CLI check did not find acme patch"; exit 1; }
echo "$ACME_CHECK" | grep -q "$ACME_APP_ID" || { echo "FAIL: org-scoped CLI check did not return acme app"; exit 1; }

echo "=== All e2e tests passed ==="
