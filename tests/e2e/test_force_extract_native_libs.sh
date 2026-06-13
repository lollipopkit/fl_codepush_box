#!/usr/bin/env bash
# Tests for force_extract_native_libs.py.

set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
WORKDIR=$(mktemp -d /tmp/fcb_manifest_patch_test_XXXXXX)

cleanup() {
    rm -rf "$WORKDIR"
}
trap cleanup EXIT INT TERM

echo "=== Adds extractNativeLibs when missing ==="
cat > "$WORKDIR/AndroidManifest.xml" <<'XML'
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
  <application android:label="app" />
</manifest>
XML
"$SCRIPT_DIR/force_extract_native_libs.py" "$WORKDIR/AndroidManifest.xml"
grep -q 'android:extractNativeLibs="true"' "$WORKDIR/AndroidManifest.xml"

echo "=== Replaces extractNativeLibs=false ==="
cat > "$WORKDIR/AndroidManifest.xml" <<'XML'
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
  <application android:extractNativeLibs="false" android:label="app" />
</manifest>
XML
"$SCRIPT_DIR/force_extract_native_libs.py" "$WORKDIR/AndroidManifest.xml"
grep -q 'android:extractNativeLibs="true"' "$WORKDIR/AndroidManifest.xml"
if grep -q 'android:extractNativeLibs="false"' "$WORKDIR/AndroidManifest.xml"; then
    echo "FAIL: stale extractNativeLibs=false remains" >&2
    exit 1
fi

echo "=== Fails when application tag is missing ==="
cat > "$WORKDIR/AndroidManifest.xml" <<'XML'
<manifest xmlns:android="http://schemas.android.com/apk/res/android" />
XML
if "$SCRIPT_DIR/force_extract_native_libs.py" "$WORKDIR/AndroidManifest.xml" >/tmp/fcb_manifest_patch.log 2>&1; then
    echo "FAIL: missing application tag was accepted" >&2
    exit 1
fi
grep -q 'missing <application> tag' /tmp/fcb_manifest_patch.log

echo "=== Manifest patch tests passed ==="
