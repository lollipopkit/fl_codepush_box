#!/usr/bin/env bash
# Unit-style tests for verify_engine_patch.sh.

set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
WORKDIR=$(mktemp -d /tmp/fcb_verify_engine_patch_XXXXXX)
ENGINE="$WORKDIR/engine/src"

cleanup() {
    rm -rf "$WORKDIR"
}
trap cleanup EXIT INT TERM

mkdir -p "$ENGINE/shell/platform/android/fcb" \
    "$ENGINE/shell/platform/android/shell"
cp "$SCRIPT_DIR/fcb_engine_hook.cc" "$ENGINE/shell/platform/android/fcb/fcb_engine_hook.cc"
cat > "$ENGINE/shell/platform/android/fcb/BUILD.gn" <<'GN'
source_set("fcb_engine_hook") {
  sources = [ "fcb_engine_hook.cc" ]
}
GN

echo "=== Verifier rejects missing Android BUILD.gn dependency ==="
cat > "$ENGINE/shell/platform/android/shell/fcb_integration.cc" <<'CC'
void FcbIntegration() {
  fcb_apply_android_snapshot_replace_with_config(nullptr, nullptr);
}
CC
if "$SCRIPT_DIR/verify_engine_patch.sh" "$ENGINE" >/tmp/fcb_verify_engine_unlinked.log 2>&1; then
    echo "FAIL: verifier accepted unlinked hook" >&2
    exit 1
fi
grep -q 'do not depend on //shell/platform/android/fcb:fcb_engine_hook' \
    /tmp/fcb_verify_engine_unlinked.log

echo "=== Verifier rejects missing startup call ==="
cat > "$ENGINE/shell/platform/android/shell/BUILD.gn" <<'GN'
source_set("android_shell") {
  deps = [ "//shell/platform/android/fcb:fcb_engine_hook" ]
}
GN
rm "$ENGINE/shell/platform/android/shell/fcb_integration.cc"
if "$SCRIPT_DIR/verify_engine_patch.sh" "$ENGINE" >/tmp/fcb_verify_engine_uncalled.log 2>&1; then
    echo "FAIL: verifier accepted uncalled hook" >&2
    exit 1
fi
grep -q 'does not call fcb_apply_android_snapshot_replace_with_config' \
    /tmp/fcb_verify_engine_uncalled.log

echo "=== Verifier accepts linked and called hook ==="
cat > "$ENGINE/shell/platform/android/shell/fcb_integration.cc" <<'CC'
void FcbIntegration() {
  fcb_apply_android_snapshot_replace_with_config(nullptr, nullptr);
}
CC
"$SCRIPT_DIR/verify_engine_patch.sh" "$ENGINE" >/tmp/fcb_verify_engine_ok.log
grep -q 'FCB Android Engine patch verification passed' \
    /tmp/fcb_verify_engine_ok.log

echo "=== Engine patch verifier tests passed ==="
