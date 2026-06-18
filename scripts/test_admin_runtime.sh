#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
WORKDIR=${FCB_ADMIN_RUNTIME_WORKDIR:-$(mktemp -d "${TMPDIR:-/tmp}/fcb-admin-runtime.XXXXXX")}
SERVER_ADDR=${FCB_ADMIN_RUNTIME_ADDR:-127.0.0.1:18081}
SERVER_PID=

cleanup() {
  if [[ -n "${SERVER_PID:-}" ]] && kill -0 "$SERVER_PID" >/dev/null 2>&1; then
    kill "$SERVER_PID" >/dev/null 2>&1 || true
    wait "$SERVER_PID" >/dev/null 2>&1 || true
  fi
  if [[ "${FCB_ADMIN_RUNTIME_KEEP_WORKDIR:-0}" != "1" ]]; then
    rm -rf "$WORKDIR"
  else
    echo "kept workdir: $WORKDIR"
  fi
}
trap cleanup EXIT

need() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "missing required command: $1" >&2
    exit 2
  fi
}

json_get() {
  node -e "let d=''; process.stdin.on('data', c => d += c); process.stdin.on('end', () => { const v = JSON.parse(d); console.log($1); });"
}

sha256_text() {
  if command -v shasum >/dev/null 2>&1; then
    printf '%s' "$1" | shasum -a 256 | awk '{print $1}'
  elif command -v sha256sum >/dev/null 2>&1; then
    printf '%s' "$1" | sha256sum | awk '{print $1}'
  else
    echo "missing required command: shasum or sha256sum" >&2
    exit 2
  fi
}

base64_text() {
  printf '%s' "$1" | base64 | tr -d '\n'
}

wait_http() {
  local url=$1
  local timeout=${2:-30}
  local start
  start=$(date +%s)
  until curl -fsS "$url" >/dev/null 2>&1; do
    if (( $(date +%s) - start > timeout )); then
      echo "timed out waiting for $url" >&2
      return 1
    fi
    sleep 0.5
  done
}

curl_json() {
  local method=$1
  local url=$2
  local body=${3:-'{}'}
  local auth=${4:-}
  local cookie_jar=${5:-}
  local response_file
  response_file=$(mktemp "$WORKDIR/curl-response.XXXXXX")
  local args=(-sS -o "$response_file" -w '%{http_code}' -X "$method" "$url" -H "Content-Type: application/json" --data-binary "$body")
  if [[ -n "$auth" ]]; then
    args+=(-H "Authorization: Bearer $auth")
  fi
  if [[ -n "$cookie_jar" ]]; then
    args+=(-b "$cookie_jar")
  fi
  local status
  status=$(curl "${args[@]}")
  if [[ "$status" -lt 200 || "$status" -ge 300 ]]; then
    echo "$method $url returned HTTP $status:" >&2
    cat "$response_file" >&2
    echo >&2
    return 22
  fi
  cat "$response_file"
}

need curl
need go
need node
need base64

mkdir -p "$WORKDIR"
COOKIE_JAR="$WORKDIR/cookies.txt"

if [[ ! -f "$ROOT_DIR/server/webui/dist/index.html" ]]; then
  (cd "$ROOT_DIR/server/webui" && npm run build)
fi

(
  cd "$ROOT_DIR/server"
  FCB_SERVER_DB="$WORKDIR/fcb.sqlite" \
  FCB_SERVER_ADDR="$SERVER_ADDR" \
  FCB_WEBUI_DIST="$ROOT_DIR/server/webui/dist" \
  go run . >"$WORKDIR/server.log" 2>&1
) &
SERVER_PID=$!

wait_http "http://$SERVER_ADDR/healthz" 60

setup_response=$(curl_json POST "http://$SERVER_ADDR/api/auth/setup" '{"username":"admin","password":"password123","token_name":"runtime-default"}')
default_token=$(printf '%s' "$setup_response" | json_get 'v.token')
if [[ -z "$default_token" ]]; then
  echo "setup did not return a token" >&2
  exit 1
fi

login_status=$(curl -sS -o "$WORKDIR/login.json" -w '%{http_code}' -c "$COOKIE_JAR" \
  -X POST "http://$SERVER_ADDR/api/auth/login" \
  -H "Content-Type: application/json" \
  --data-binary '{"username":"admin","password":"password123"}')
if [[ "$login_status" != "200" ]]; then
  echo "login returned HTTP $login_status:" >&2
  cat "$WORKDIR/login.json" >&2
  exit 1
fi

for org in acme widgets; do
  curl_json POST "http://$SERVER_ADDR/api/admin/orgs" "{\"id\":\"$org\",\"name\":\"$org\"}" "" "$COOKIE_JAR" >/dev/null
done

acme_token=$(curl_json POST "http://$SERVER_ADDR/api/admin/orgs/acme/cli-tokens" '{"name":"acme-runtime"}' "" "$COOKIE_JAR" | json_get 'v.token')
widgets_token=$(curl_json POST "http://$SERVER_ADDR/api/admin/orgs/widgets/cli-tokens" '{"name":"widgets-runtime"}' "" "$COOKIE_JAR" | json_get 'v.token')

create_patch() {
  local org=$1
  local token=$2
  local payload=$3
  local app_id="shared-app"
  local release_version="1.0.0+1"
  local platform="android"
  local arch="arm64-v8a"
  local patch_number=1
  local payload_hash
  payload_hash=$(sha256_text "$payload")
  local payload_size=${#payload}
  local payload_b64
  payload_b64=$(base64_text "$payload")
  local payload_key="patches/$app_id/$release_version/$platform/$arch/$patch_number/payload.bin"

  curl_json POST "http://$SERVER_ADDR/v1/apps" "{\"id\":\"$app_id\",\"name\":\"$org shared\"}" "$token" >/dev/null
  curl_json POST "http://$SERVER_ADDR/v1/releases" \
    "{\"schema_version\":1,\"app_id\":\"$app_id\",\"release_version\":\"$release_version\",\"channel\":\"stable\",\"platform\":\"$platform\",\"arch\":\"$arch\",\"backend\":\"bytecode\",\"artifact_hash\":\"artifact-$org\",\"artifact_size\":1}" \
    "$token" >/dev/null

  patch_body=$(APP_ID="$app_id" RELEASE_VERSION="$release_version" PATCH_NUMBER="$patch_number" PLATFORM="$platform" ARCH="$arch" PAYLOAD_HASH="$payload_hash" PAYLOAD_SIZE="$payload_size" PAYLOAD_KEY="$payload_key" PAYLOAD_B64="$payload_b64" node -e '
const body = {
  manifest: {
    schema_version: 1,
    app_id: process.env.APP_ID,
    release_version: process.env.RELEASE_VERSION,
    patch_number: Number(process.env.PATCH_NUMBER),
    channel: "stable",
    created_at: "1970-01-01T00:00:00Z",
    backend: "bytecode",
    platform: process.env.PLATFORM,
    arch: process.env.ARCH,
    payload: {
      kind: "opaque_payload",
      compression: "none",
      hash: process.env.PAYLOAD_HASH,
      size: Number(process.env.PAYLOAD_SIZE),
      download_url: process.env.PAYLOAD_KEY
    },
    policy: { rollout_percentage: 100, allow_downgrade: false },
    signature: { algorithm: "ed25519", key_id: "dev", value: "signature" }
  },
  payload_b64: process.env.PAYLOAD_B64
};
process.stdout.write(JSON.stringify(body));
')
  curl_json POST "http://$SERVER_ADDR/v1/patches" "$patch_body" "$token" >/dev/null
  curl_json POST "http://$SERVER_ADDR/v1/patches/promote" \
    "{\"app_id\":\"$app_id\",\"release_version\":\"$release_version\",\"platform\":\"$platform\",\"arch\":\"$arch\",\"patch_number\":$patch_number,\"channel\":\"stable\",\"rollout_percentage\":100}" \
    "$token" >/dev/null
}

create_patch acme "$acme_token" "acme-payload"
create_patch widgets "$widgets_token" "widgets-payload"

curl_json POST "http://$SERVER_ADDR/v1/events" '{"org_id":"acme","app_id":"shared-app","release_version":"1.0.0+1","platform":"android","arch":"arm64-v8a","patch_number":1,"event_type":"install","client_id_hash":"acme-client"}' >/dev/null
curl_json POST "http://$SERVER_ADDR/v1/events" '{"org_id":"widgets","app_id":"shared-app","release_version":"1.0.0+1","platform":"android","arch":"arm64-v8a","patch_number":1,"event_type":"launch_failure","client_id_hash":"widgets-client","payload":{"error_message":"widgets-only"}}' >/dev/null

acme_stats=$(curl_json GET "http://$SERVER_ADDR/api/admin/orgs/acme/apps/shared-app/patches/1/stats?release_version=1.0.0%2B1&platform=android&arch=arm64-v8a" '{}' "" "$COOKIE_JAR")
widgets_stats=$(curl_json GET "http://$SERVER_ADDR/api/admin/orgs/widgets/apps/shared-app/patches/1/stats?release_version=1.0.0%2B1&platform=android&arch=arm64-v8a" '{}' "" "$COOKIE_JAR")

ACME_STATS="$acme_stats" WIDGETS_STATS="$widgets_stats" node -e '
const acme = JSON.parse(process.env.ACME_STATS);
const widgets = JSON.parse(process.env.WIDGETS_STATS);
if ((acme.totals.install || 0) !== 1 || (acme.totals.launch_failure || 0) !== 0) {
  throw new Error(`unexpected acme stats ${JSON.stringify(acme.totals)}`);
}
if ((widgets.totals.install || 0) !== 0 || (widgets.totals.launch_failure || 0) !== 1) {
  throw new Error(`unexpected widgets stats ${JSON.stringify(widgets.totals)}`);
}
'

check_acme=$(curl -fsS "http://$SERVER_ADDR/v1/patches/check?org_id=acme&app_id=shared-app&release_version=1.0.0%2B1&platform=android&arch=arm64-v8a&channel=stable&current_patch_number=0&client_id=runtime")
check_widgets=$(curl -fsS "http://$SERVER_ADDR/v1/patches/check?org_id=widgets&app_id=shared-app&release_version=1.0.0%2B1&platform=android&arch=arm64-v8a&channel=stable&current_patch_number=0&client_id=runtime")

ACME_CHECK="$check_acme" WIDGETS_CHECK="$check_widgets" node -e '
const acme = JSON.parse(process.env.ACME_CHECK);
const widgets = JSON.parse(process.env.WIDGETS_CHECK);
if (!acme.patch_available || !widgets.patch_available) {
  throw new Error("expected both orgs to have an active patch");
}
if (!decodeURIComponent(acme.patch.payload_url).includes("orgs/acme/")) {
  throw new Error(`acme payload url is not org-scoped: ${acme.patch.payload_url}`);
}
if (!decodeURIComponent(widgets.patch.payload_url).includes("orgs/widgets/")) {
  throw new Error(`widgets payload url is not org-scoped: ${widgets.patch.payload_url}`);
}
'

html=$(curl -fsS "http://$SERVER_ADDR/")
if [[ "$html" != *"FCB Admin"* && "$html" != *"fcb-webui"* && "$html" != *"/assets/"* ]]; then
  echo "webui root did not look like the built admin UI" >&2
  exit 1
fi

metrics=$(curl -fsS "http://$SERVER_ADDR/metrics")
if [[ "$metrics" != *"fcb_patch_event_writes_total 2"* ]]; then
  echo "metrics did not include two event writes:" >&2
  echo "$metrics" >&2
  exit 1
fi

{
  echo "FCB admin runtime drill passed"
  echo "workdir: $WORKDIR"
  echo "server: http://$SERVER_ADDR"
  echo "verified:"
  echo "- built WebUI is served by the Go server"
  echo "- same app id can upload patch payloads in two orgs without object-key collision"
  echo "- admin stats stay org-scoped for same app id and patch number"
  echo "- patch check returns org-scoped payload URLs"
  echo "- metrics count patch event writes"
} >"$WORKDIR/summary.txt"

echo "admin runtime drill passed: $WORKDIR/summary.txt"
