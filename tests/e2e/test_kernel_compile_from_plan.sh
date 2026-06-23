#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
if [ -z "${DART_BIN:-}" ] && [ -x "/Users/lk/env/flutter/bin/cache/dart-sdk/bin/dart" ]; then
  DART_BIN="/Users/lk/env/flutter/bin/cache/dart-sdk/bin/dart"
else
  DART_BIN="${DART_BIN:-dart}"
fi
FCB_RUN_VM_TESTS="${FCB_RUN_VM_TESTS:-$ROOT_DIR/vendor/flutter/engine/src/out/host_release_arm64/run_vm_tests}"
EVIDENCE_DIR="${FCB_KERNEL_COMPILE_EVIDENCE_DIR:-$ROOT_DIR/target/fcb/kernel-compile-from-plan}"
SUMMARY="$EVIDENCE_DIR/summary.txt"
WORKDIR="$(mktemp -d /tmp/fcb_kernel_compile_from_plan_XXXXXX)"
ASSERT_DIR="$ROOT_DIR/tests/e2e/kernel_compile_from_plan/assertions"

cleanup() {
  if [ "${FCB_KEEP_KERNEL_COMPILE_TEST:-0}" = "1" ]; then
    echo "keeping workdir: $WORKDIR" >&2
  else
    rm -rf "$WORKDIR"
  fi
}
trap cleanup EXIT

mkdir -p "$WORKDIR/project/lib" "$WORKDIR/project/.dart_tool" "$WORKDIR/wrappers" "$EVIDENCE_DIR"

compose_fixture() {
  local source_dir="$1"
  local output="$2"
  : >"$output"
  local part
  local found=0
  while IFS= read -r part; do
    cat "$part" >>"$output"
    printf '\n' >>"$output"
    found=1
  done < <(find "$source_dir" -type f -name '*.dart' | sort)
  [ "$found" -eq 1 ] || {
    echo "missing Kernel compile fixture part in $source_dir" >&2
    exit 1
  }
}

cat >"$WORKDIR/project/pubspec.yaml" <<'YAML'
name: fcb_kernel_compile_test
YAML

cat >"$WORKDIR/project/.dart_tool/package_config.json" <<JSON
{
  "configVersion": 2,
  "packages": [{
    "name": "fcb_kernel_compile_test",
    "rootUri": "$WORKDIR/project",
    "packageUri": "lib/",
    "languageVersion": "3.12"
  }]
}
JSON

compose_fixture "$ROOT_DIR/tests/e2e/kernel_compile_from_plan/fixtures/release_main_parts" "$WORKDIR/project/lib/main.dart"

"$DART_BIN" "$ROOT_DIR/tool/fcb_kernel_manifest.dart" \
  --project "$WORKDIR/project" \
  --target lib/main.dart \
  >"$WORKDIR/release_inventory.json"

compose_fixture "$ROOT_DIR/tests/e2e/kernel_compile_from_plan/fixtures/patch_main_parts" "$WORKDIR/project/lib/main.dart"

cat >"$WORKDIR/wrappers/fcb_entry.dart" <<'DART'
import 'package:fcb_kernel_compile_test/main.dart';
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

python3 "$ASSERT_DIR/plan/assert_plan_inventory.py" \
  "$WORKDIR/release_inventory.json" "$WORKDIR/patch_inventory.json" "$WORKDIR/plan.json"
python3 "$ASSERT_DIR/plan/assert_plan_core_calls.py" \
  "$WORKDIR/patch_inventory.json"
python3 "$ASSERT_DIR/plan/assert_plan_collection_chains.py" \
  "$WORKDIR/patch_inventory.json"
python3 "$ASSERT_DIR/plan/assert_plan_collection_switch_sources.py" \
  "$WORKDIR/patch_inventory.json"
python3 "$ASSERT_DIR/plan/assert_plan_switch_expr_sources.py" \
  "$WORKDIR/patch_inventory.json"
python3 "$ASSERT_DIR/plan/assert_plan_switch_statement_sources.py" \
  "$WORKDIR/patch_inventory.json"
python3 "$ASSERT_DIR/plan/assert_plan_async_control.py" \
  "$WORKDIR/patch_inventory.json"
python3 "$ASSERT_DIR/plan/assert_plan_async_loop_finalizer_guards.py" \
  "$WORKDIR/patch_inventory.json"
python3 "$ASSERT_DIR/plan/assert_plan_async_collection_chains.py" \
  "$WORKDIR/patch_inventory.json"
python3 "$ASSERT_DIR/plan/assert_plan_async_object_generator_chains.py" \
  "$WORKDIR/patch_inventory.json"
python3 "$ASSERT_DIR/generator/assert_generator_sources.py" \
  "$WORKDIR/patch_inventory.json"
python3 "$ASSERT_DIR/generator/assert_generator_stream_chains.py" \
  "$WORKDIR/patch_inventory.json"
python3 "$ASSERT_DIR/generator/assert_generator_collection_chains.py" \
  "$WORKDIR/patch_inventory.json"
python3 "$ASSERT_DIR/generator/assert_generator_finalizer_chains.py" \
  "$WORKDIR/patch_inventory.json"
python3 "$ASSERT_DIR/generator/assert_generator_object_sync_chains.py" \
  "$WORKDIR/patch_inventory.json"
python3 "$ASSERT_DIR/generator/assert_generator_async_chains.py" \
  "$WORKDIR/patch_inventory.json"

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

python3 "$ASSERT_DIR/module/assert_module.py" "$WORKDIR/module.fcbm"

python3 "$ASSERT_DIR/binary/assert_binary.py" "$WORKDIR/module.bin"

if [ -x "$FCB_RUN_VM_TESTS" ]; then
  FCB_SOURCE_ASYNC_STAR_MODULE="$WORKDIR/module.bin" \
    "$FCB_RUN_VM_TESTS" FcbPatchRuntimeAsyncStarSourceModuleStreamListen
  FCB_SOURCE_ASYNC_STAR_MODULE="$WORKDIR/module.bin" \
    "$FCB_RUN_VM_TESTS" FcbPatchRuntimeAsyncStarSourceModuleDeepNestedAwaitFor
else
  echo "skipping source async* runtime e2e: missing run_vm_tests at $FCB_RUN_VM_TESTS" >&2
fi

{
  echo "kernel_compile_from_plan passed"
  echo "workdir: $WORKDIR"
  echo "workdir_kept: ${FCB_KEEP_KERNEL_COMPILE_TEST:-0}"
  echo "dart_bin: $DART_BIN"
  echo "run_vm_tests: $FCB_RUN_VM_TESTS"
  echo "source_runtime_filters: FcbPatchRuntimeAsyncStarSourceModuleStreamListen FcbPatchRuntimeAsyncStarSourceModuleDeepNestedAwaitFor"
  echo "triple_nested_runtime_cases: normal cancel outer-error middle-error inner-error"
} >"$SUMMARY"

echo "kernel compile-from-plan summary: $SUMMARY"
