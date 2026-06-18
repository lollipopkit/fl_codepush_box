#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

usage() {
  cat <<USAGE
Usage:
  $0

Checks that the local GitHub Actions workflow inventory still matches the
Phase H2 evidence gate. This is a local, offline check; it does not query
GitHub and does not prove that remote runs have passed.

Environment:
  FCB_GITHUB_WORKFLOWS_DIR     Override workflows dir for parser self-tests.
  FCB_GITHUB_EVIDENCE_SCRIPT   Override evidence script for parser self-tests.
USAGE
}

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
  usage
  exit 0
fi

python3 - "$ROOT_DIR" <<'PY'
from __future__ import annotations

import re
import sys
from pathlib import Path

root = Path(sys.argv[1])
import os

workflows_dir = Path(os.environ.get("FCB_GITHUB_WORKFLOWS_DIR", root / ".github" / "workflows"))
evidence_script = Path(os.environ.get("FCB_GITHUB_EVIDENCE_SCRIPT", root / "scripts" / "check_github_actions_evidence.sh"))

required = {
    ("Workflow Lint", "push"),
    ("Rust", "push"),
    ("Server", "push"),
    ("E2E x64", "push"),
    ("Flutter Package", "push"),
    ("Android Emulator Nightly", "schedule"),
    ("iOS Simulator Nightly", "schedule"),
    ("Server S3 Storage", "schedule"),
}

def parse_workflow(path: Path) -> tuple[str | None, set[str]]:
    name: str | None = None
    events: set[str] = set()
    in_on_block = False
    on_indent = 0
    for raw in path.read_text(encoding="utf-8").splitlines():
        if not raw.strip() or raw.lstrip().startswith("#"):
            continue
        if name is None:
            match = re.match(r"^name:\s*(.+?)\s*$", raw)
            if match:
                name = match.group(1).strip().strip("\"'")
                continue
        if re.match(r"^on:\s*$", raw):
            in_on_block = True
            on_indent = 0
            continue
        scalar = re.match(r"^on:\s*([A-Za-z_]+)\s*$", raw)
        if scalar:
            events.add(scalar.group(1))
            continue
        inline = re.match(r"^on:\s*\[(.+)\]\s*$", raw)
        if inline:
            events.update(item.strip().strip("\"'") for item in inline.group(1).split(","))
            continue
        if in_on_block:
            indent = len(raw) - len(raw.lstrip(" "))
            if indent <= on_indent:
                in_on_block = False
                continue
            list_item = re.match(r"^\s*-\s*([A-Za-z_]+)\s*$", raw)
            if list_item:
                events.add(list_item.group(1))
                continue
            match = re.match(r"^\s*([A-Za-z_]+):", raw)
            if match:
                events.add(match.group(1))
    return name, events

inventory: dict[tuple[str, str], Path] = {}
errors: list[str] = []

if not workflows_dir.is_dir():
    errors.append(f"missing workflows dir: {workflows_dir}")
else:
    workflow_files = sorted({*workflows_dir.glob("*.yml"), *workflows_dir.glob("*.yaml")})
    for path in workflow_files:
        name, events = parse_workflow(path)
        if not name:
            errors.append(f"{path.relative_to(root)} is missing workflow name")
            continue
        for event in events:
            key = (name, event)
            if key in inventory:
                first = inventory[key].relative_to(root)
                second = path.relative_to(root)
                errors.append(f"duplicate workflow {name!r} with event {event!r}: {first} and {second}")
            else:
                inventory[key] = path

script_text = evidence_script.read_text(encoding="utf-8")
for workflow, event in required:
    if (workflow, event) not in inventory:
        errors.append(f"missing local workflow {workflow!r} with event {event!r}")
    expected_call = f'run_list "{workflow}" "{event}"'
    if expected_call not in script_text:
        errors.append(f"evidence script missing {expected_call}")

extra_queries = set(re.findall(r'run_list "([^"]+)" "([^"]+)"', script_text)) - required
for workflow, event in sorted(extra_queries):
    errors.append(f"evidence script queries unexpected workflow {workflow!r} ({event!r})")

if errors:
    for error in errors:
        print(f"error: {error}", file=sys.stderr)
    raise SystemExit(1)

print("GitHub Actions inventory matches Phase H2 evidence gate.")
PY
