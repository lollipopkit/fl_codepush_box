#!/usr/bin/env bash
# Static contract tests for the counter example used by Phase B Android e2e.

set -euo pipefail

REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
MAIN="$REPO_ROOT/examples/counter_app/lib/main.dart"

need() {
    local pattern="$1"
    local description="$2"
    if ! grep -qF "$pattern" "$MAIN"; then
        echo "FAIL: counter example missing $description" >&2
        echo "Pattern: $pattern" >&2
        exit 1
    fi
}

need_order() {
    local first="$1"
    local second="$2"
    local description="$3"
    local first_line
    local second_line
    first_line=$(grep -nF "$first" "$MAIN" | head -n 1 | cut -d: -f1 || true)
    second_line=$(grep -nF "$second" "$MAIN" | head -n 1 | cut -d: -f1 || true)
    if [ -z "$first_line" ] || [ -z "$second_line" ] || [ "$first_line" -ge "$second_line" ]; then
        echo "FAIL: counter example order contract failed: $description" >&2
        echo "First pattern: $first" >&2
        echo "Second pattern: $second" >&2
        exit 1
    fi
}

for define in \
    FCB_SERVER_URL \
    FCB_APP_ID \
    FCB_PUBLIC_KEY \
    FCB_RELEASE_VERSION \
    FCB_CHANNEL \
    FCB_PLATFORM \
    FCB_ARCH \
    FCB_CACHE_DIR \
    FCB_BASELINE_ARTIFACT \
    FCB_CHECK_ON_STARTUP \
    FCB_INITIAL_COUNTER
do
    need "'$define'" "dart define $define"
done

need "bool.fromEnvironment(" "boolean startup-check dart define"
need "int.fromEnvironment(" "initial counter dart define"
need "_codePush.configure(" "FCB configure call"
need "appId: _appId" "app id passed to configure"
need "releaseVersion: _releaseVersion" "release version passed to configure"
need "publicKey: _publicKey" "public key passed to configure"
need "serverUrl: _serverUrl" "server URL passed to configure"
need "channel: _channel" "channel passed to configure"
need "platform: _platform" "platform passed to configure"
need "arch: _arch" "arch passed to configure"
need "cacheDir: _cacheDir" "cache dir passed to configure"
need "baselineArtifactPath:" "baseline artifact passed to configure"
need "_baselineArtifactPath.isEmpty ? null : _baselineArtifactPath" "empty baseline artifact normalized to null"

need "Completer<void>()" "first-frame completer"
need "WidgetsBinding.instance.addPostFrameCallback" "post-frame callback"
need "_firstFrameRendered.complete();" "first-frame completion"
need "await _firstFrameRendered.future;" "launch success waits for first frame"
need "await _codePush.markLaunchSuccessful();" "launch success marker"
need "if (_configured && _checkOnStartup)" "startup check gated by configure and dart define"
need "_check = await _codePush.checkForUpdate();" "startup checkForUpdate call"
need "_download = await _codePush.downloadUpdate();" "startup downloadUpdate call"

need_order "await _firstFrameRendered.future;" "await _codePush.markLaunchSuccessful();" "mark launch success must wait for the first frame"
need_order "await _codePush.markLaunchSuccessful();" "if (_configured && _checkOnStartup)" "startup update check must happen after launch success is marked"
need_order "_check = await _codePush.checkForUpdate();" "_download = await _codePush.downloadUpdate();" "download must follow check"

need "int _counter = _initialCounter;" "initial counter state"
need 'Text('\''Counter: $_counter'\''' "Counter UI text used by Android e2e"
need "? 'installed'" "installed download status text used by Android e2e"
need "const Text('Check')" "manual check button"
need "const Text('Download')" "manual download button"
need "const Text('Mark success')" "manual launch-success button"

echo "Counter app Phase B contract tests passed"
