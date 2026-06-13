#!/usr/bin/env bash
# Verify a Phase B Android evidence JSON produced by test_phase_b_android.sh.

set -euo pipefail

REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
EVIDENCE="${1:-}"

if [ -z "$EVIDENCE" ]; then
    EVIDENCE=$(find "$REPO_ROOT/.phase_b_evidence" -type f -name 'phase_b_android_*.json' 2>/dev/null | sort | tail -n 1 || true)
fi

if [ -z "$EVIDENCE" ] || [ ! -f "$EVIDENCE" ]; then
    echo "FAIL: Phase B evidence JSON not found" >&2
    echo "Run tests/e2e/test_phase_b_android.sh with a patched local Engine on a real Android device/emulator." >&2
    exit 1
fi

python3 - "$EVIDENCE" <<'PY'
import json
import os
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
data = json.loads(path.read_text(encoding="utf-8"))

def fail(message):
    raise SystemExit(f"FAIL: {message}")

if data.get("schema_version") != 1:
    fail("unsupported evidence schema_version")
if data.get("passed") is not True:
    fail("evidence did not pass")
if data.get("script") != "tests/e2e/test_phase_b_android.sh":
    fail("evidence was not produced by the real Android Phase B script")
if data.get("dry_run") is True and os.environ.get("FCB_ALLOW_DRY_RUN_EVIDENCE") != "1":
    fail("dry-run evidence is not valid Phase B completion evidence")

for field in ("app_id", "abi", "target_platform", "device_server_url", "flutter_build_extra_args"):
    if not data.get(field):
        fail(f"missing evidence field: {field}")
device = data.get("device") or {}
if device.get("adb_state") != "device":
    fail("evidence was not captured from an adb device state")
for field in ("android_release", "android_api", "android_abi", "flutter_devices"):
    if not device.get(field):
        fail(f"missing device evidence field: {field}")

args = data["flutter_build_extra_args"]
for required_arg in ("--local-engine-src-path", "--local-engine", "--local-engine-host"):
    if required_arg not in args:
        fail(f"missing local Engine argument in evidence: {required_arg}")
local_engine = data.get("local_engine") or {}
for field in ("src_path", "target", "host"):
    if not local_engine.get(field):
        fail(f"missing local_engine evidence field: {field}")

artifacts = data.get("artifacts") or {}
for field in ("base_apk_sha256", "base_libapp_sha256", "patch_libapp_sha256"):
    value = artifacts.get(field)
    if not isinstance(value, str) or len(value) != 64:
        fail(f"missing or invalid artifact hash: {field}")
if artifacts["base_libapp_sha256"] == artifacts["patch_libapp_sha256"]:
    fail("baseline and patch libapp.so hashes are identical")

validations = set(data.get("validations") or [])
required_validations = {
    "preflight passed with patched local Engine source and out directories",
    "baseline APK contained libapp.so and libfcb_updater.so",
    "Counter app v1 displayed Counter: 1",
    "release was published from baseline libapp.so",
    "patch libapp.so differed from baseline libapp.so",
    "patch was generated and promoted",
    "installed baseline app downloaded the patch",
    "restart loaded patched AOT artifact and displayed Counter: 2",
    "intentionally crashing patch caused process exit",
    "next launch rolled back to the previous active patch",
    "server stopped and local active patch still displayed Counter: 2",
}
missing = sorted(required_validations - validations)
if missing:
    fail("missing required validation(s): " + ", ".join(missing))

print(f"Phase B evidence verified: {path}")
PY
