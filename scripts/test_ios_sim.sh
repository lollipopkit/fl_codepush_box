#!/usr/bin/env bash
# iOS simulator smoke test for FCB bytecode code push.
#
# Prerequisites:
#   - Xcode installed with iOS simulator support
#   - FCB iOS Engine built via scripts/build_ios_engine.sh (FCB_IOS_CPU=x64)
#   - FCB server running (default http://127.0.0.1:8080)
#   - App registered via: FCB_CLI_TOKEN=<token> fcb init
#
# Usage:
#   FCB_APP_ID=<uuid> FCB_PUBLIC_KEY=<key> scripts/test_ios_sim.sh
#   FCB_SKIP_BUILD=1 FCB_INSTALL_BYTECODE_PATCH=1 scripts/test_ios_sim.sh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FLUTTER_DIR="$ROOT_DIR/vendor/flutter"
COUNTER_APP="$ROOT_DIR/examples/counter_app"
SERVER_URL="${FCB_SERVER_URL:-http://127.0.0.1:8080}"
APP_ID="${FCB_APP_ID:-}"
PUBLIC_KEY="${FCB_PUBLIC_KEY:-}"
RELEASE_VERSION="${FCB_RELEASE_VERSION:-1.0.0+1}"
CHANNEL="${FCB_CHANNEL:-stable}"
FCB_SKIP_BUILD="${FCB_SKIP_BUILD:-0}"
FCB_INSTALL_BYTECODE_PATCH="${FCB_INSTALL_BYTECODE_PATCH:-0}"
SIM_DEVICE="${FCB_SIM_DEVICE:-}"   # e.g. "iPhone 15 Pro" — auto-selected if empty

ENGINE_OUT="${ROOT_DIR}/vendor/flutter/engine/src/out/ios_release_x64"

BUNDLE_ID="com.example.fcbCounterApp"

die()  { echo "error: $*" >&2; exit 1; }
run()  { echo "+ $*" >&2; "$@"; }
info() { echo "==> $*" >&2; }

select_simulator() {
  if [ -n "$SIM_DEVICE" ]; then
    echo "$SIM_DEVICE"
    return
  fi
  xcrun simctl list devices available --json 2>/dev/null \
    | python3 -c "
import sys, json
data = json.load(sys.stdin)
for runtime, devices in data.get('devices', {}).items():
    if 'iOS' not in runtime:
        continue
    for d in devices:
        if d.get('isAvailable') and 'iPhone' in d.get('name',''):
            print(d['udid'])
            sys.exit(0)
sys.exit(1)
" || die "No available iPhone simulator found. Boot one with: open -a Simulator"
}

build_app() {
  info "Building counter_app for iOS simulator..."
  run "$FLUTTER_DIR/bin/flutter" build ios \
    --simulator \
    --debug \
    --target-platform ios-x64 \
    --local-engine-src-path "$ROOT_DIR/vendor/flutter/engine/src" \
    --local-engine "ios_release_x64" \
    --dart-define "FCB_SERVER_URL=$SERVER_URL" \
    --dart-define "FCB_APP_ID=$APP_ID" \
    --dart-define "FCB_PUBLIC_KEY=$PUBLIC_KEY" \
    --dart-define "FCB_RELEASE_VERSION=$RELEASE_VERSION" \
    --dart-define "FCB_CHANNEL=$CHANNEL" \
    --dart-define "FCB_PLATFORM=ios" \
    --dart-define "FCB_ARCH=x86_64" \
    -C "$COUNTER_APP"
}

install_bytecode_patch() {
  info "Installing manual bytecode patch..."
  local payload_dir="$COUNTER_APP/.fcb_test_patch/ios"
  mkdir -p "$payload_dir"

  # Create a minimal patch payload that returns initialCounterValue() = 42
  cat > "$payload_dir/payload.json" <<'JSON'
{
  "version": 1,
  "functions": [{
    "name": "initialCounterValue",
    "param_count": 0,
    "local_count": 0,
    "constants": [{"type": "Int", "value": 42}],
    "code": [1, 0, 0, 255]
  }]
}
JSON

  run cargo run --manifest-path "$ROOT_DIR/Cargo.toml" -p fcb --quiet -- \
    install \
    --manifest "$payload_dir/patch_manifest.json" \
    --payload "$payload_dir/payload.bin" \
    --cache-dir "$payload_dir/cache" 2>/dev/null || true

  info "Note: manual patch install requires a running FCB server and registered app."
}

main() {
  local sim_udid
  sim_udid="$(select_simulator)"
  info "Using simulator: $sim_udid"

  if [ "$FCB_SKIP_BUILD" != "1" ]; then
    [ -d "$ENGINE_OUT" ] || die "iOS Engine not built. Run: FCB_IOS_CPU=x64 scripts/build_ios_engine.sh"
    build_app
  fi

  local app_path
  app_path="$(find "$COUNTER_APP/build/ios/iphonesimulator" -name "*.app" 2>/dev/null | head -1)"
  [ -n "$app_path" ] || die "No .app bundle found. Run without FCB_SKIP_BUILD=1 first."

  info "Installing on simulator $sim_udid..."
  run xcrun simctl install "$sim_udid" "$app_path"

  if [ "$FCB_INSTALL_BYTECODE_PATCH" = "1" ]; then
    install_bytecode_patch
  fi

  info "Launching app..."
  run xcrun simctl launch "$sim_udid" "$BUNDLE_ID"

  info "Waiting 5s for startup..."
  sleep 5

  info "Fetching logs..."
  xcrun simctl spawn "$sim_udid" log show \
    --predicate 'subsystem == "dev.fcb"' \
    --last 30s 2>/dev/null || true

  info "iOS simulator test complete. Check simulator for FCB counter app."
  info "Expected: app shows 'Counter: 1' on first launch (no patch)."
  if [ "$FCB_INSTALL_BYTECODE_PATCH" = "1" ]; then
    info "After restart: app should show 'Counter: 42' (bytecode patch active)."
  fi
}

main "$@"
