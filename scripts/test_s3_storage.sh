#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
WORK_DIR=${FCB_S3_DRILL_WORK_DIR:-$(mktemp -d "${TMPDIR:-/tmp}/fcb-s3-drill.XXXXXX")}
SUMMARY_DIR=${FCB_S3_DRILL_SUMMARY_DIR:-$ROOT_DIR/target/fcb/s3-storage}
MINIO_CONTAINER=${FCB_MINIO_CONTAINER:-fcb-minio-drill}
MINIO_IMAGE=${FCB_MINIO_IMAGE:-minio/minio:RELEASE.2025-02-28T09-55-16Z}
MINIO_API_PORT=${FCB_MINIO_API_PORT:-19000}
MINIO_CONSOLE_PORT=${FCB_MINIO_CONSOLE_PORT:-19001}
SERVER_ADDR=${FCB_DRILL_SERVER_ADDR:-127.0.0.1:18080}
BUCKET=${FCB_S3_BUCKET:-fcb-payloads}
ACCESS_KEY=${FCB_S3_ACCESS_KEY_ID:-minioadmin}
SECRET_KEY=${FCB_S3_SECRET_ACCESS_KEY:-minioadmin}
SERVER_PID=

cleanup() {
  if [[ -n "${SERVER_PID:-}" ]] && kill -0 "$SERVER_PID" >/dev/null 2>&1; then
    kill "$SERVER_PID" >/dev/null 2>&1 || true
    wait "$SERVER_PID" >/dev/null 2>&1 || true
  fi
  docker rm -f "$MINIO_CONTAINER" >/dev/null 2>&1 || true
  if [[ "${FCB_S3_DRILL_KEEP_WORK_DIR:-0}" != "1" ]]; then
    rm -rf "$WORK_DIR"
  else
    echo "kept work dir: $WORK_DIR"
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
  local body='{}'
  local token=''
  if [[ $# -ge 3 ]]; then
    body=$3
  fi
  if [[ $# -ge 4 ]]; then
    token=$4
  fi
  local response_file
  response_file=$(mktemp "$WORK_DIR/curl-response.XXXXXX")
  local status
  if [[ -n "$token" ]]; then
    status=$(curl -sS -o "$response_file" -w '%{http_code}' -X "$method" "$url" \
      -H "Authorization: Bearer $token" \
      -H "Content-Type: application/json" \
      --data-binary "$body")
  else
    status=$(curl -sS -o "$response_file" -w '%{http_code}' -X "$method" "$url" \
      -H "Content-Type: application/json" \
      --data-binary "$body")
  fi
  if [[ "$status" -lt 200 || "$status" -ge 300 ]]; then
    echo "$method $url returned HTTP $status:" >&2
    cat "$response_file" >&2
    echo >&2
    return 22
  fi
  cat "$response_file"
}

need curl
need docker
need go
need node
need base64

sha256_file() {
  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$1" | awk '{print $1}'
  elif command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  else
    echo "missing required command: shasum or sha256sum" >&2
    exit 2
  fi
}

mkdir -p "$WORK_DIR"

docker rm -f "$MINIO_CONTAINER" >/dev/null 2>&1 || true
docker run -d --name "$MINIO_CONTAINER" \
  -p "$MINIO_API_PORT:9000" \
  -p "$MINIO_CONSOLE_PORT:9001" \
  -e "MINIO_ROOT_USER=$ACCESS_KEY" \
  -e "MINIO_ROOT_PASSWORD=$SECRET_KEY" \
  "$MINIO_IMAGE" server /data --console-address ":9001" >/dev/null

wait_http "http://127.0.0.1:$MINIO_API_PORT/minio/health/ready" 60
docker exec "$MINIO_CONTAINER" mc alias set local http://127.0.0.1:9000 "$ACCESS_KEY" "$SECRET_KEY" >/dev/null
docker exec "$MINIO_CONTAINER" mc mb --ignore-existing "local/$BUCKET" >/dev/null

(
  cd "$ROOT_DIR/server"
  FCB_SERVER_DB="$WORK_DIR/fcb.sqlite" \
  FCB_SERVER_ADDR="$SERVER_ADDR" \
  FCB_STORAGE_DRIVER=s3 \
  FCB_S3_BUCKET="$BUCKET" \
  FCB_S3_REGION=us-east-1 \
  FCB_S3_ENDPOINT="http://127.0.0.1:$MINIO_API_PORT" \
  FCB_S3_ACCESS_KEY_ID="$ACCESS_KEY" \
  FCB_S3_SECRET_ACCESS_KEY="$SECRET_KEY" \
  go run . >"$WORK_DIR/server.log" 2>&1
) &
SERVER_PID=$!

wait_http "http://$SERVER_ADDR/healthz" 60

setup_response=$(curl_json POST "http://$SERVER_ADDR/api/auth/setup" '{"username":"admin","password":"password123","token_name":"s3-drill"}')
token=$(printf '%s' "$setup_response" | json_get 'v.token')

payload_file="$WORK_DIR/payload.bin"
printf 'fcb-s3-payload-drill' > "$payload_file"
payload_hash=$(sha256_file "$payload_file")
payload_size=$(wc -c < "$payload_file" | tr -d ' ')
payload_b64=$(base64 < "$payload_file" | tr -d '\n')
app_id="s3-drill-app"
release_version="1.0.0+1"
platform="android"
arch="arm64-v8a"
patch_number=1
payload_key="patches/$app_id/$release_version/$platform/$arch/$patch_number/payload.bin"

curl_json POST "http://$SERVER_ADDR/v1/apps" \
  "{\"id\":\"$app_id\",\"name\":\"S3 Drill\"}" \
  "$token" >/dev/null

curl_json POST "http://$SERVER_ADDR/v1/releases" \
  "{\"schema_version\":1,\"app_id\":\"$app_id\",\"release_version\":\"$release_version\",\"channel\":\"stable\",\"platform\":\"$platform\",\"arch\":\"$arch\",\"backend\":\"bytecode\",\"artifact_hash\":\"$payload_hash\",\"artifact_size\":$payload_size}" \
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
    policy: { rollout_percentage: 0, allow_downgrade: false },
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

check_url="http://$SERVER_ADDR/v1/patches/check?app_id=$app_id&release_version=1.0.0%2B1&platform=$platform&arch=$arch&channel=stable&current_patch_number=0&client_id=s3-drill"
check_response=$(curl -fsS "$check_url")
patch_available=$(printf '%s' "$check_response" | json_get 'v.patch_available')
if [[ "$patch_available" != "true" ]]; then
  echo "expected patch_available=true, got: $check_response" >&2
  exit 1
fi
payload_url=$(printf '%s' "$check_response" | json_get 'v.patch.payload_url')
if [[ "$payload_url" != http://127.0.0.1:$MINIO_API_PORT/* ]]; then
  echo "expected S3 presigned payload URL, got: $payload_url" >&2
  exit 1
fi
if [[ "$payload_url" != *X-Amz-Signature=* ]]; then
  echo "payload URL is missing X-Amz-Signature: $payload_url" >&2
  exit 1
fi
payload_url_has_signature=1

downloaded="$WORK_DIR/downloaded-payload.bin"
curl -fsS "$payload_url" -o "$downloaded"
downloaded_hash=$(sha256_file "$downloaded")
if [[ "$downloaded_hash" != "$payload_hash" ]]; then
  echo "downloaded payload hash mismatch: got $downloaded_hash want $payload_hash" >&2
  exit 1
fi

docker exec "$MINIO_CONTAINER" mc stat "local/$BUCKET/$payload_key" >/dev/null
object_stat=passed

mkdir -p "$SUMMARY_DIR"
{
  echo "S3 storage drill passed"
  echo "bucket: $BUCKET"
  echo "key: $payload_key"
  echo "hash: $payload_hash"
  echo "downloaded_hash: $downloaded_hash"
  echo "payload_url_has_signature: $payload_url_has_signature"
  echo "object_stat: $object_stat"
  echo "server: http://$SERVER_ADDR"
  echo "work_dir: $WORK_DIR"
} >"$SUMMARY_DIR/summary.txt"

echo "S3 storage drill passed: bucket=$BUCKET key=$payload_key hash=$payload_hash"
