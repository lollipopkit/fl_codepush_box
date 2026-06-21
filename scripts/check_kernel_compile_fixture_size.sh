#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MAX_LINES="${FCB_KERNEL_COMPILE_MAX_LINES:-1500}"

usage() {
  cat <<USAGE
Usage:
  scripts/check_kernel_compile_fixture_size.sh

Checks that the Kernel compile-from-plan e2e stays split into maintainable
files, and that Kernel reader/compiler tool files stay under the same
per-file size budget. Override the per-file line limit with
FCB_KERNEL_COMPILE_MAX_LINES.
USAGE
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

case "$MAX_LINES" in
  ''|*[!0-9]*)
    echo "invalid FCB_KERNEL_COMPILE_MAX_LINES: $MAX_LINES" >&2
    exit 2
    ;;
esac

paths=(
  "$ROOT_DIR/tests/e2e/test_kernel_compile_from_plan.sh"
)

for assert_file in "$ROOT_DIR"/tests/e2e/kernel_compile_from_plan/assert_*.py; do
  [ -f "$assert_file" ] || continue
  paths+=("$assert_file")
done

for tool_file in "$ROOT_DIR"/tool/fcb_kernel_*.dart; do
  [ -f "$tool_file" ] || continue
  paths+=("$tool_file")
done

for fixture_dir in \
  "$ROOT_DIR/tests/e2e/kernel_compile_from_plan/fixtures/release_main_parts" \
  "$ROOT_DIR/tests/e2e/kernel_compile_from_plan/fixtures/patch_main_parts"; do
  [ -d "$fixture_dir" ] || {
    echo "missing Kernel compile-from-plan fixture directory: $fixture_dir" >&2
    exit 1
  }
  found=0
  for part in "$fixture_dir"/*.dart; do
    [ -f "$part" ] || continue
    paths+=("$part")
    found=1
  done
  [ "$found" -eq 1 ] || {
    echo "missing Kernel compile-from-plan fixture parts in: $fixture_dir" >&2
    exit 1
  }
done

for path in "${paths[@]}"; do
  [ -f "$path" ] || {
    echo "missing Kernel compile-from-plan fixture/check file: $path" >&2
    exit 1
  }
done

failed=0
for path in "${paths[@]}"; do
  lines="$(wc -l <"$path" | tr -d '[:space:]')"
  rel="${path#"$ROOT_DIR/"}"
  echo "$rel: $lines/$MAX_LINES"
  if [ "$lines" -gt "$MAX_LINES" ]; then
    echo "file exceeds Kernel compile-from-plan line limit: $rel ($lines > $MAX_LINES)" >&2
    failed=1
  fi
done

[ "$failed" -eq 0 ] || exit 1
echo "Kernel compile-from-plan size check passed"
