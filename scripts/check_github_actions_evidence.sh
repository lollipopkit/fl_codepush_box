#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BRANCH="${FCB_CI_EVIDENCE_BRANCH:-main}"
MAX_MAIN_MINUTES="${FCB_CI_EVIDENCE_MAX_MAIN_MINUTES:-5}"
MAX_ANDROID_MINUTES="${FCB_CI_EVIDENCE_MAX_ANDROID_MINUTES:-60}"
MAX_IOS_MINUTES="${FCB_CI_EVIDENCE_MAX_IOS_MINUTES:-90}"
OUT_DIR="${FCB_CI_EVIDENCE_DIR:-$ROOT_DIR/target/fcb/github-actions-evidence}"

usage() {
  cat <<USAGE
Usage:
  $0

Checks real GitHub Actions evidence for Phase H2 without triggering workflows.
The script reads the latest completed workflow runs from GitHub, requires them
to be successful, and writes a summary under target/fcb/github-actions-evidence
by default.

Environment:
  FCB_CI_EVIDENCE_BRANCH              Branch to inspect. Default: main
  FCB_CI_EVIDENCE_MAX_MAIN_MINUTES    Max duration for push workflows. Default: 5
  FCB_CI_EVIDENCE_MAX_ANDROID_MINUTES Max duration for Android nightly. Default: 60
  FCB_CI_EVIDENCE_MAX_IOS_MINUTES     Max duration for iOS nightly. Default: 90
  FCB_CI_EVIDENCE_DIR                 Output directory.
USAGE
}

need() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "missing required command: $1" >&2
    exit 2
  fi
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

need gh
need python3

mkdir -p "$OUT_DIR"
RAW_JSON="$OUT_DIR/runs.json"
SUMMARY="$OUT_DIR/summary.txt"

run_list() {
  local workflow="$1"
  local event="$2"
  local output="$OUT_DIR/${workflow// /_}.${event}.json"
  local error_output="$OUT_DIR/${workflow// /_}.${event}.err"
  local args=(run list --workflow "$workflow" --branch "$BRANCH" --event "$event" --status completed --limit 1 --json databaseId,workflowName,name,event,headBranch,headSha,status,conclusion,createdAt,startedAt,updatedAt,url)
  local query_error=""
  if ! gh "${args[@]}" >"$output" 2>"$error_output"; then
    query_error="$(tr '\n' ' ' <"$error_output" | sed 's/[[:space:]]*$//')"
    printf '[]' >"$output"
  fi
  python3 - "$workflow" "$event" "$output" "$query_error" <<'PY'
import json
import sys

workflow, event, path, query_error = sys.argv[1:5]
with open(path, encoding="utf-8") as f:
    runs = json.load(f)
record = {
    "workflow": workflow,
    "event": event,
    "query_error": query_error or None,
    "run": runs[0] if runs else None,
}
print(json.dumps(record, separators=(",", ":")))
PY
}

{
  run_list "Workflow Lint" "push"
  run_list "Rust" "push"
  run_list "Server" "push"
  run_list "E2E x64" "push"
  run_list "Flutter Package" "push"
  run_list "Android Emulator Nightly" "schedule"
  run_list "iOS Simulator Nightly" "schedule"
  run_list "Server S3 Storage" "schedule"
} >"$RAW_JSON"

python3 - "$RAW_JSON" "$SUMMARY" "$BRANCH" "$MAX_MAIN_MINUTES" "$MAX_ANDROID_MINUTES" "$MAX_IOS_MINUTES" <<'PY'
from __future__ import annotations

import datetime as dt
import json
import sys
from pathlib import Path

raw_path, summary_path, branch, max_main_text, max_android_text, max_ios_text = sys.argv[1:7]
max_main = float(max_main_text)
max_android = float(max_android_text)
max_ios = float(max_ios_text)


def parse_time(value: str | None) -> dt.datetime | None:
    if not value:
        return None
    return dt.datetime.fromisoformat(value.replace("Z", "+00:00"))


def duration_minutes(run: dict) -> float | None:
    started = parse_time(run.get("startedAt") or run.get("createdAt"))
    updated = parse_time(run.get("updatedAt"))
    if not started or not updated:
        return None
    return (updated - started).total_seconds() / 60.0


records = [json.loads(line) for line in Path(raw_path).read_text(encoding="utf-8").splitlines() if line.strip()]
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
seen = {(record["workflow"], record["event"]) for record in records}
errors: list[str] = []
lines: list[str] = []
push_head_shas: set[str] = set()

for missing in sorted(required - seen):
    errors.append(f"missing query result for {missing[0]} ({missing[1]})")

for record in records:
    workflow = record["workflow"]
    event = record["event"]
    run = record["run"]
    if record.get("query_error"):
        errors.append(f"failed to query {workflow} ({event}): {record['query_error']}")
        continue
    if run is None:
        errors.append(f"no completed run found for {workflow} ({event}) on branch {branch}")
        continue
    if run.get("status") != "completed" or run.get("conclusion") != "success":
        errors.append(f"{workflow} latest run is not successful: status={run.get('status')} conclusion={run.get('conclusion')}")
    if run.get("headBranch") != branch:
        errors.append(f"{workflow} latest run branch mismatch: {run.get('headBranch')} != {branch}")
    head_sha = run.get("headSha") or ""
    if event == "push" and head_sha:
        push_head_shas.add(head_sha)
    minutes = duration_minutes(run)
    duration = "unknown" if minutes is None else f"{minutes:.1f}m"
    short_sha = head_sha[:12] if head_sha else "unknown"
    lines.append(f"- {workflow} [{event}]: run #{run.get('databaseId')} sha {short_sha} {duration} {run.get('url')}")
    if event == "push" and minutes is not None and minutes > max_main:
        errors.append(f"{workflow} push run took {minutes:.1f}m, expected <= {max_main:.1f}m")
    if workflow == "Android Emulator Nightly" and minutes is not None and minutes > max_android:
        errors.append(f"{workflow} took {minutes:.1f}m, expected <= {max_android:.1f}m")
    if workflow == "iOS Simulator Nightly" and minutes is not None and minutes > max_ios:
        errors.append(f"{workflow} took {minutes:.1f}m, expected <= {max_ios:.1f}m")

if len(push_head_shas) > 1:
    errors.append("push workflow runs do not share one head SHA: " + ", ".join(sorted(push_head_shas)))

summary = [
    "FCB GitHub Actions evidence",
    f"branch: {branch}",
    f"max_main_minutes: {max_main:.1f}",
    f"max_android_minutes: {max_android:.1f}",
    f"max_ios_minutes: {max_ios:.1f}",
    "",
    "runs:",
    *lines,
]
if len(push_head_shas) == 1:
    summary.insert(2, f"push_head_sha: {next(iter(push_head_shas))}")
if errors:
    summary.extend(["", "failures:", *[f"- {error}" for error in errors]])
else:
    summary.extend(["", "status: passed"])
Path(summary_path).write_text("\n".join(summary) + "\n", encoding="utf-8")
print(f"GitHub Actions evidence summary: {summary_path}")
if errors:
    raise SystemExit(1)
PY
