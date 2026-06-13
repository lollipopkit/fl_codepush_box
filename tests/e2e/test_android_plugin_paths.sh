#!/usr/bin/env bash
# Static contract checks for the Android path bridge used by Phase B.

set -euo pipefail

REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
PLUGIN="$REPO_ROOT/packages/fcb_code_push/android/src/main/java/dev/fcb/code_push/FcbCodePushPlugin.java"
DART="$REPO_ROOT/packages/fcb_code_push/lib/fcb_code_push.dart"

echo "=== Android plugin exposes Phase B path channel ==="
grep -q 'dev.fcb.code_push/android_paths' "$PLUGIN"
grep -q "MethodChannel('dev.fcb.code_push/android_paths')" "$DART"

echo "=== Android plugin exposes cache dir for shared updater state ==="
grep -q 'case "getCacheDir"' "$PLUGIN"
grep -q 'getCacheDir().getAbsolutePath()' "$PLUGIN"
grep -q "invokeMethod<String>('getCacheDir')" "$DART"
grep -Fq "return '\$value/fcb';" "$DART"

echo "=== Android plugin exposes baseline libapp.so path ==="
grep -q 'case "getBaselineArtifactPath"' "$PLUGIN"
grep -q 'getApplicationInfo().nativeLibraryDir' "$PLUGIN"
grep -q 'new File(nativeLibraryDir, "libapp.so").getAbsolutePath()' "$PLUGIN"
grep -q "invokeMethod<String>('getBaselineArtifactPath')" "$DART"
grep -q 'fcb_set_baseline_artifact_path' "$DART"

echo "=== Android plugin path contract tests passed ==="
