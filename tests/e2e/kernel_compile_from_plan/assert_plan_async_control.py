import json
import sys

from assert_plan_async_branch_sources import assert_async_branch_sources
from assert_plan_async_expression_sources import assert_async_expression_sources
from assert_plan_async_loop_sources import assert_async_loop_sources

patch = json.load(open(sys.argv[1]))
patch_by_member = {f.get("member_name"): f for f in patch["functions"]}

assert_async_branch_sources(patch_by_member)
assert_async_expression_sources(patch_by_member)

async_guard_tail = patch_by_member.get("asyncGuardAwaitTail", {}).get("bytecode_source", {})
async_guard_conditional = async_guard_tail.get("body", {}).get("new_object", {}).get("args", [{}])[0].get("conditional", {})
async_guard_else_seq = async_guard_conditional.get("else", {}).get("seq", [])
if (
    async_guard_conditional.get("condition", {}).get("arg") != "enabled"
    or async_guard_conditional.get("then", {}).get("string") != "patched-guard-fast"
    or len(async_guard_else_seq) != 2
    or async_guard_else_seq[0].get("await", {}).get("arg") != "ready"
    or async_guard_else_seq[1].get("string") != "patched-guard-tail"
):
    raise SystemExit(f"expected asyncGuardAwaitTail guard if + await tail source, got {async_guard_tail}")
planned_async = patch_by_member.get("plannedAsyncAwait", {}).get("bytecode_source", {})
planned_arg = planned_async.get("body", {}).get("new_object", {}).get("args", [{}])[0]
planned_let = planned_arg.get("let", {})
planned_locals = planned_let.get("locals", [])
planned_conditional = planned_let.get("body", {}).get("conditional", {})
if (
    len(planned_locals) != 1
    or planned_locals[0].get("value", {}).get("await", {}).get("call_static") is None
    or planned_conditional.get("condition", {}).get("op") != ">"
    or planned_conditional.get("then", {}).get("op") != "+"
):
    raise SystemExit(f"expected plannedAsyncAwait local await + if-return source, got {planned_async}")
assert_async_loop_sources(patch_by_member)
