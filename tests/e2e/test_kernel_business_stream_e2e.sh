#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
if [ -z "${DART_BIN:-}" ] && [ -x "/Users/lk/env/flutter/bin/cache/dart-sdk/bin/dart" ]; then
  DART_BIN="/Users/lk/env/flutter/bin/cache/dart-sdk/bin/dart"
else
  DART_BIN="${DART_BIN:-dart}"
fi
FCB_RUN_VM_TESTS="${FCB_RUN_VM_TESTS:-$ROOT_DIR/vendor/flutter/engine/src/out/host_release_arm64/run_vm_tests}"
WORKDIR="$(mktemp -d /tmp/fcb_kernel_business_stream_XXXXXX)"

cleanup() {
  if [ "${FCB_KEEP_KERNEL_BUSINESS_STREAM_TEST:-0}" = "1" ]; then
    echo "keeping workdir: $WORKDIR" >&2
  else
    rm -rf "$WORKDIR"
  fi
}
trap cleanup EXIT

mkdir -p "$WORKDIR/project/lib" "$WORKDIR/project/.dart_tool" "$WORKDIR/wrappers"

cat >"$WORKDIR/project/pubspec.yaml" <<'YAML'
name: fcb_business_probe
YAML

cat >"$WORKDIR/project/.dart_tool/package_config.json" <<JSON
{
  "configVersion": 2,
  "packages": [{
    "name": "fcb_business_probe",
    "rootUri": "$WORKDIR/project",
    "packageUri": "lib/",
    "languageVersion": "3.12"
  }]
}
JSON

cat >"$WORKDIR/wrappers/fcb_entry.dart" <<'DART'
import 'package:fcb_business_probe/main.dart';
void main() {}
DART

cat >"$WORKDIR/project/lib/main.dart" <<'DART'
Stream<String> asyncBusinessPipeline(
  Future<String> ready,
  Stream<String> extra,
  Stream<String> delegated,
) async* {
  yield 'release';
}

void main() {}
DART

"$DART_BIN" compile kernel \
  --no-link-platform \
  --packages="$WORKDIR/project/.dart_tool/package_config.json" \
  -o "$WORKDIR/release.dill" \
  "$WORKDIR/wrappers/fcb_entry.dart" >/dev/null

"$DART_BIN" "$ROOT_DIR/tool/fcb_kernel_manifest.dart" \
  --project "$WORKDIR/project" \
  --target lib/main.dart \
  --dill "$WORKDIR/release.dill" \
  >"$WORKDIR/release_inventory.json"

cat >"$WORKDIR/project/lib/main.dart" <<'DART'
Stream<String> asyncBusinessPipeline(
  Future<String> ready,
  Stream<String> extra,
  Stream<String> delegated,
) async* {
  try {
    final head = await ready;
    yield 'patched-business-head-$head';
    await for (final item in extra) {
      if (item == 'skip') continue;
      yield 'patched-business-item-$item';
      await for (final detail in Stream.value('detail-$item')) {
        yield 'patched-business-$detail';
      }
      if (item == 'stop') break;
    }
    yield* delegated;
    yield* Stream.value('patched-business-tail');
  } finally {
    yield 'patched-business-cleanup';
  }
}

void main() {}
DART

"$DART_BIN" compile kernel \
  --no-link-platform \
  --packages="$WORKDIR/project/.dart_tool/package_config.json" \
  -o "$WORKDIR/patch.dill" \
  "$WORKDIR/wrappers/fcb_entry.dart" >/dev/null

"$DART_BIN" "$ROOT_DIR/tool/fcb_kernel_manifest.dart" \
  --project "$WORKDIR/project" \
  --target lib/main.dart \
  --dill "$WORKDIR/patch.dill" \
  >"$WORKDIR/patch_inventory.json"

python3 - "$WORKDIR/release_inventory.json" "$WORKDIR/patch_inventory.json" "$WORKDIR/plan.json" <<'PY'
import json
import sys

release = json.load(open(sys.argv[1]))
patch = json.load(open(sys.argv[2]))
release_by_id = {f["function_id"]: f for f in release["functions"]}
target = next(f for f in patch["functions"] if f.get("member_name") == "asyncBusinessPipeline")
old = release_by_id.get(target["function_id"])
assert old is not None, target
assert old["body_hash"] != target["body_hash"], target
assert target.get("bytecode_source"), target
assert target.get("unsupported_reasons") == [], target
source = target["bytecode_source"]
assert source.get("async_kind") == "async_star", source
body = source.get("body", {}).get("try_finally", {})
assert body, source
text = json.dumps(source)
assert '"await"' in text and '"yield"' in text and "_StreamIterator" in text, source
json.dump({
    "unchanged": [],
    "interpret": [{
        "function_id": target["function_id"],
        "source_location": target.get("source_location"),
    }],
    "reject": [],
}, open(sys.argv[3], "w"))
PY

"$DART_BIN" "$ROOT_DIR/tool/fcb_kernel_manifest.dart" \
  --project "$WORKDIR/project" \
  --target lib/main.dart \
  --compile-from-plan "$WORKDIR/plan.json" \
  --patch "$WORKDIR/patch.dill" \
  -o "$WORKDIR/module.fcbm"

"$DART_BIN" "$ROOT_DIR/tool/fcb_kernel_manifest.dart" \
  --project "$WORKDIR/project" \
  --target lib/main.dart \
  --compile-from-plan "$WORKDIR/plan.json" \
  --patch "$WORKDIR/patch.dill" \
  --format binary \
  -o "$WORKDIR/module.bin"

python3 - "$WORKDIR/module.fcbm" <<'PY'
import json
import sys

module = json.load(open(sys.argv[1]))
assert len(module["functions"]) == 1, module
function = module["functions"][0]
assert function["name"].endswith("::asyncBusinessPipeline"), function
assert function.get("async_kind") == "async_star", function
assert function["code"].count(0x62) >= 3, function
assert function["code"].count(0x64) >= 5, function
assert function["code"].count(0x65) >= 3, function
assert function["code"].count(0x66) >= 3, function
constants = json.dumps(function["constants"])
assert "patched-business-head-" in constants, function
assert "patched-business-tail" in constants, function
assert "patched-business-cleanup" in constants, function
PY

if [ -x "$FCB_RUN_VM_TESTS" ]; then
  FCB_SOURCE_BUSINESS_STREAM_MODULE="$WORKDIR/module.bin" \
    "$FCB_RUN_VM_TESTS" FcbPatchRuntimeBusinessStreamSourceE2e
else
  echo "skipping business stream runtime e2e: missing run_vm_tests at $FCB_RUN_VM_TESTS" >&2
fi
