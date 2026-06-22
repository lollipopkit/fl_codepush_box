import json
import sys

from assert_plan_inventory_async_await import assert_inventory_async_await_sources
from assert_plan_inventory_callbacks import assert_inventory_callback_sources
from assert_plan_inventory_escaping import assert_inventory_escaping_sources
from assert_plan_inventory_local_mutation import assert_inventory_local_mutation_sources

release = json.load(open(sys.argv[1]))
patch = json.load(open(sys.argv[2]))
release_by_id = {f["function_id"]: f for f in release["functions"]}
plan = {"unchanged": [], "interpret": [], "reject": []}

for function in patch["functions"]:
    old = release_by_id.get(function["function_id"])
    if old is None:
        continue
    entry = {
        "function_id": function["function_id"],
        "source_location": function.get("source_location"),
    }
    if old["body_hash"] == function["body_hash"]:
        plan["unchanged"].append(entry)
    elif function.get("unsupported_reasons"):
        plan["reject"].append({
            **entry,
            "reject_reason": function["unsupported_reasons"][0],
        })
    else:
        plan["interpret"].append(entry)

if len(plan["interpret"]) != 508:
    raise SystemExit(f"expected 508 interpreted functions, got {len(plan['interpret'])}")
if len(plan["reject"]) != 2:
    raise SystemExit(f"expected two rejected functions, got {plan['reject']}")

patch_by_member = {f.get("member_name"): f for f in patch["functions"]}

assert_inventory_local_mutation_sources(patch_by_member)

assert_inventory_escaping_sources(patch)

assert_inventory_callback_sources(patch_by_member)

main_function = patch_by_member.get("main")
if main_function is None:
    raise SystemExit("missing inventory entry for main")
main_source = main_function.get("bytecode_source")
if not isinstance(main_source, dict):
    raise SystemExit(f"main should produce bytecode source: {main_function}")
main_seq = main_source.get("body", {}).get("seq", [])
if (
    main_function.get("unsupported_reasons") != []
    or len(main_seq) != 3
    or not main_seq[0].get("call_static", "").endswith("::mainValue")
    or not main_seq[1].get("call_static", "").endswith("::helper")
    or main_seq[2].get("null") is not True
):
    raise SystemExit(f"expected main sync expression statement sequence source, got {main_source}")

expected_rejects = {
    "isCallable": "function_type_unsupported",
    "isRecord": "record_type_unsupported",
}

expected_unchanged_async_rejects = {
    "asyncFutureCallbackTypeArg": "async_await_unsupported",
    "asyncFutureRecordTypeArg": "async_await_unsupported",
}

def contains_key(value, key):
    if isinstance(value, dict):
        return key in value or any(contains_key(item, key) for item in value.values())
    if isinstance(value, list):
        return any(contains_key(item, key) for item in value)
    return False

for function in patch["functions"]:
    source = function.get("bytecode_source")
    if source is not None and contains_key(source, "_uses_continue"):
        raise SystemExit(f"internal generator metadata leaked into bytecode_source: {function}")

plan_rejects = {item["function_id"]: item["reject_reason"] for item in plan["reject"]}
plan_reject_members = {
    function.get("member_name")
    for function in patch["functions"]
    if function.get("function_id") in plan_rejects
}
if plan_reject_members != set(expected_rejects):
    raise SystemExit(f"expected only {set(expected_rejects)} rejects, got {plan_reject_members}: {plan['reject']}")
for member, reason in expected_rejects.items():
    function = patch_by_member.get(member)
    if function is None:
        raise SystemExit(f"missing inventory entry for {member}")
    if function.get("bytecode_source") is not None:
        raise SystemExit(f"{member} must not produce bytecode source: {function}")
    if function.get("unsupported_reasons") != [reason]:
        raise SystemExit(f"expected {member} reason {reason}, got {function}")
    if plan_rejects.get(function["function_id"]) != reason:
        raise SystemExit(f"expected plan reject {member}={reason}, got {plan['reject']}")

for member, reason in expected_unchanged_async_rejects.items():
    function = patch_by_member.get(member)
    if function is None:
        raise SystemExit(f"missing inventory entry for {member}")
    if function.get("bytecode_source") is not None:
        raise SystemExit(f"{member} must not produce bytecode source: {function}")
    if function.get("unsupported_reasons") != [reason]:
        raise SystemExit(f"expected {member} reason {reason}, got {function}")
    if function["function_id"] in plan_rejects:
        raise SystemExit(f"{member} is unchanged and must not enter plan rejects: {plan['reject']}")

assert_inventory_async_await_sources(patch_by_member)

sync_generated = patch_by_member.get("syncGenerated", {}).get("bytecode_source", {})
if sync_generated.get("async_kind") != "sync_star":
    raise SystemExit(f"expected syncGenerated sync_star source, got {sync_generated}")
if sync_generated.get("body", {}).get("yield", {}).get("string") != "patched-iterable":
    raise SystemExit(f"expected syncGenerated yield source, got {sync_generated}")
async_generated = patch_by_member.get("asyncGenerated", {}).get("bytecode_source", {})
if async_generated.get("async_kind") != "async_star":
    raise SystemExit(f"expected asyncGenerated async_star source, got {async_generated}")
if async_generated.get("body", {}).get("yield", {}).get("string") != "patched-stream":
    raise SystemExit(f"expected asyncGenerated yield source, got {async_generated}")
async_generated_await = patch_by_member.get("asyncGeneratedAwait", {}).get("bytecode_source", {})
async_generated_await_body = async_generated_await.get("body", {}).get("let", {})
async_generated_await_value = async_generated_await_body.get("locals", [{}])[0].get("value", {})
async_generated_await_yield = async_generated_await_body.get("body", {}).get("yield", {})
if (
    async_generated_await.get("async_kind") != "async_star"
    or async_generated_await_value.get("await", {}).get("arg") != "ready"
    or async_generated_await_yield.get("concat") is None
):
    raise SystemExit(f"expected asyncGeneratedAwait async* await local source, got {async_generated_await}")
async_generated_try_finally = patch_by_member.get("asyncGeneratedTryFinally", {}).get("bytecode_source", {})
async_try_finally = async_generated_try_finally.get("body", {}).get("try_finally", {})
async_try_finally_body = async_try_finally.get("body", {}).get("yield", {})
async_try_finally_finalizer = async_try_finally.get("finally", {}).get("let", {})
if (
    async_generated_try_finally.get("async_kind") != "async_star"
    or async_try_finally_body.get("await", {}).get("arg") != "ready"
    or async_try_finally_finalizer.get("locals", [{}])[0].get("name") != "cleanup"
):
    raise SystemExit(f"expected asyncGeneratedTryFinally try_finally source, got {async_generated_try_finally}")
async_generated_finally_yield = patch_by_member.get("asyncGeneratedFinallyYield", {}).get("bytecode_source", {})
async_finally_yield = async_generated_finally_yield.get("body", {}).get("try_finally", {})
async_finally_yield_body = async_finally_yield.get("body", {}).get("yield", {})
async_finally_yield_finalizer = async_finally_yield.get("finally", {}).get("yield", {})
if (
    async_generated_finally_yield.get("async_kind") != "async_star"
    or async_finally_yield_body.get("await", {}).get("arg") != "ready"
    or async_finally_yield_finalizer.get("string") != "patched-stream-finally-yield-cleanup"
):
    raise SystemExit(f"expected asyncGeneratedFinallyYield try_finally yield source, got {async_generated_finally_yield}")
async_generated_catch_await = patch_by_member.get("asyncGeneratedCatchAwait", {}).get("bytecode_source", {})
async_catch_await = async_generated_catch_await.get("body", {}).get("try_catch", {})
async_catch_await_body = async_catch_await.get("body", {}).get("yield", {})
async_catch_await_catch = async_catch_await.get("catch", {}).get("yield", {})
if (
    async_generated_catch_await.get("async_kind") != "async_star"
    or async_catch_await.get("catch_local") != 0
    or async_catch_await_body.get("await", {}).get("arg") != "ready"
    or async_catch_await_catch.get("concat", [{}, {}])[1].get("let_local") != 0
):
    raise SystemExit(f"expected asyncGeneratedCatchAwait try_catch await source, got {async_generated_catch_await}")
sync_generated_many = patch_by_member.get("syncGeneratedMany", {}).get("bytecode_source", {})
sync_many_body = sync_generated_many.get("body", {}).get("let", {}).get("body", {}).get("seq", [])
if (
    sync_generated_many.get("async_kind") != "sync_star"
    or len(sync_many_body) != 3
    or sync_many_body[1].get("conditional") is None
):
    raise SystemExit(f"expected syncGeneratedMany let + seq + conditional yield source, got {sync_generated_many}")
async_generated_many = patch_by_member.get("asyncGeneratedMany", {}).get("bytecode_source", {})
async_many_body = async_generated_many.get("body", {}).get("let", {}).get("body", {}).get("seq", [])
if (
    async_generated_many.get("async_kind") != "async_star"
    or len(async_many_body) != 3
    or async_many_body[1].get("conditional") is None
):
    raise SystemExit(f"expected asyncGeneratedMany let + seq + conditional yield source, got {async_generated_many}")
sync_generated_while = patch_by_member.get("syncGeneratedWhile", {}).get("bytecode_source", {})
sync_while_let = sync_generated_while.get("body", {}).get("let", {})
sync_while = sync_while_let.get("body", {}).get("while_loop", {})
sync_while_body = sync_while.get("body", {}).get("seq", [])
if (
    sync_generated_while.get("async_kind") != "sync_star"
    or sync_while_let.get("locals", [{}])[0].get("name") != "i"
    or sync_while_let.get("locals", [{}])[0].get("value", {}).get("int") != 0
    or sync_while.get("condition", {}).get("op") != ">"
    or len(sync_while_body) != 2
    or sync_while_body[0].get("yield", {}).get("concat") is None
    or sync_while_body[1].get("set_local", {}).get("id") != 0
    or sync_while_body[1].get("set_local", {}).get("value", {}).get("op") != "+"
):
    raise SystemExit(f"expected syncGeneratedWhile let + while_loop source, got {sync_generated_while}")
async_generated_while = patch_by_member.get("asyncGeneratedWhile", {}).get("bytecode_source", {})
async_while_let = async_generated_while.get("body", {}).get("let", {})
async_while = async_while_let.get("body", {}).get("while_loop", {})
async_while_body = async_while.get("body", {}).get("seq", [])
if (
    async_generated_while.get("async_kind") != "async_star"
    or async_while_let.get("locals", [{}])[0].get("name") != "i"
    or async_while_let.get("locals", [{}])[0].get("value", {}).get("int") != 0
    or async_while.get("condition", {}).get("op") != ">"
    or len(async_while_body) != 2
    or async_while_body[0].get("yield", {}).get("concat") is None
    or async_while_body[1].get("set_local", {}).get("id") != 0
    or async_while_body[1].get("set_local", {}).get("value", {}).get("op") != "+"
):
    raise SystemExit(f"expected asyncGeneratedWhile let + while_loop source, got {async_generated_while}")
sync_generated_while_break = patch_by_member.get("syncGeneratedWhileBreak", {}).get("bytecode_source", {})
sync_while_break_let = sync_generated_while_break.get("body", {}).get("let", {})
sync_while_break = sync_while_break_let.get("body", {}).get("while_loop", {})
sync_while_break_body = sync_while_break.get("body", {}).get("seq", [])
if (
    sync_generated_while_break.get("async_kind") != "sync_star"
    or sync_while_break_let.get("locals", [{}])[0].get("name") != "i"
    or sync_while_break.get("condition", {}).get("op") != ">"
    or sync_while_break.get("before_break", {}).get("yield", {}).get("concat") is None
    or sync_while_break.get("break_condition", {}).get("op") != "=="
    or len(sync_while_break_body) != 2
    or sync_while_break_body[0].get("yield", {}).get("concat") is None
    or sync_while_break_body[1].get("set_local", {}).get("id") != 0
):
    raise SystemExit(f"expected syncGeneratedWhileBreak guarded while break source, got {sync_generated_while_break}")
async_generated_while_break = patch_by_member.get("asyncGeneratedWhileBreak", {}).get("bytecode_source", {})
async_while_break_let = async_generated_while_break.get("body", {}).get("let", {})
async_while_break = async_while_break_let.get("body", {}).get("while_loop", {})
async_while_break_body = async_while_break.get("body", {}).get("seq", [])
if (
    async_generated_while_break.get("async_kind") != "async_star"
    or async_while_break_let.get("locals", [{}])[0].get("name") != "i"
    or async_while_break.get("condition", {}).get("op") != ">"
    or async_while_break.get("before_break", {}).get("yield", {}).get("concat") is None
    or async_while_break.get("break_condition", {}).get("op") != "=="
    or len(async_while_break_body) != 2
    or async_while_break_body[0].get("yield", {}).get("concat") is None
    or async_while_break_body[1].get("set_local", {}).get("id") != 0
):
    raise SystemExit(f"expected asyncGeneratedWhileBreak guarded while break source, got {async_generated_while_break}")
sync_generated_while_continue = patch_by_member.get("syncGeneratedWhileContinue", {}).get("bytecode_source", {})
sync_while_continue_let = sync_generated_while_continue.get("body", {}).get("let", {})
sync_while_continue = sync_while_continue_let.get("body", {}).get("while_loop", {})
sync_while_continue_body = sync_while_continue.get("body", {}).get("seq", [])
if (
    sync_generated_while_continue.get("async_kind") != "sync_star"
    or sync_while_continue_let.get("locals", [{}])[0].get("name") != "i"
    or sync_while_continue.get("condition", {}).get("op") != ">"
    or sync_while_continue.get("before_continue", {}).get("yield", {}).get("concat") is None
    or sync_while_continue.get("continue_condition", {}).get("op") != "=="
    or sync_while_continue.get("continue_body", {}).get("set_local", {}).get("id") != 0
    or sync_while_continue.get("continue_body", {}).get("set_local", {}).get("value", {}).get("op") != "+"
    or len(sync_while_continue_body) != 2
    or sync_while_continue_body[0].get("yield", {}).get("concat") is None
    or sync_while_continue_body[1].get("set_local", {}).get("id") != 0
):
    raise SystemExit(f"expected syncGeneratedWhileContinue guarded while continue source, got {sync_generated_while_continue}")
async_generated_while_continue = patch_by_member.get("asyncGeneratedWhileContinue", {}).get("bytecode_source", {})
async_while_continue_let = async_generated_while_continue.get("body", {}).get("let", {})
async_while_continue = async_while_continue_let.get("body", {}).get("while_loop", {})
async_while_continue_body = async_while_continue.get("body", {}).get("seq", [])
if (
    async_generated_while_continue.get("async_kind") != "async_star"
    or async_while_continue_let.get("locals", [{}])[0].get("name") != "i"
    or async_while_continue.get("condition", {}).get("op") != ">"
    or async_while_continue.get("before_continue", {}).get("yield", {}).get("concat") is None
    or async_while_continue.get("continue_condition", {}).get("op") != "=="
    or async_while_continue.get("continue_body", {}).get("set_local", {}).get("id") != 0
    or async_while_continue.get("continue_body", {}).get("set_local", {}).get("value", {}).get("op") != "+"
    or len(async_while_continue_body) != 2
    or async_while_continue_body[0].get("yield", {}).get("concat") is None
    or async_while_continue_body[1].get("set_local", {}).get("id") != 0
):
    raise SystemExit(f"expected asyncGeneratedWhileContinue guarded while continue source, got {async_generated_while_continue}")
sync_generated_while_continue_break = patch_by_member.get("syncGeneratedWhileContinueBreak", {}).get("bytecode_source", {})
sync_while_continue_break_let = sync_generated_while_continue_break.get("body", {}).get("let", {})
sync_while_continue_break = sync_while_continue_break_let.get("body", {}).get("while_loop", {})
sync_while_continue_break_body = sync_while_continue_break.get("body", {}).get("seq", [])
if (
    sync_generated_while_continue_break.get("async_kind") != "sync_star"
    or sync_while_continue_break_let.get("locals", [{}])[0].get("name") != "i"
    or sync_while_continue_break.get("condition", {}).get("op") != ">"
    or sync_while_continue_break.get("before_continue", {}).get("yield", {}).get("concat") is None
    or sync_while_continue_break.get("continue_condition", {}).get("op") != "=="
    or sync_while_continue_break.get("continue_body", {}).get("set_local", {}).get("id") != 0
    or sync_while_continue_break.get("before_break", {}).get("yield", {}).get("concat") is None
    or sync_while_continue_break.get("break_condition", {}).get("op") != "=="
    or len(sync_while_continue_break_body) != 2
    or sync_while_continue_break_body[0].get("yield", {}).get("concat") is None
    or sync_while_continue_break_body[1].get("set_local", {}).get("id") != 0
):
    raise SystemExit(f"expected syncGeneratedWhileContinueBreak guarded while continue+break source, got {sync_generated_while_continue_break}")
async_generated_while_continue_break = patch_by_member.get("asyncGeneratedWhileContinueBreak", {}).get("bytecode_source", {})
async_while_continue_break_let = async_generated_while_continue_break.get("body", {}).get("let", {})
async_while_continue_break = async_while_continue_break_let.get("body", {}).get("while_loop", {})
async_while_continue_break_body = async_while_continue_break.get("body", {}).get("seq", [])
if (
    async_generated_while_continue_break.get("async_kind") != "async_star"
    or async_while_continue_break_let.get("locals", [{}])[0].get("name") != "i"
    or async_while_continue_break.get("condition", {}).get("op") != ">"
    or async_while_continue_break.get("before_continue", {}).get("yield", {}).get("concat") is None
    or async_while_continue_break.get("continue_condition", {}).get("op") != "=="
    or async_while_continue_break.get("continue_body", {}).get("set_local", {}).get("id") != 0
    or async_while_continue_break.get("before_break", {}).get("yield", {}).get("concat") is None
    or async_while_continue_break.get("break_condition", {}).get("op") != "=="
    or len(async_while_continue_break_body) != 2
    or async_while_continue_break_body[0].get("yield", {}).get("concat") is None
    or async_while_continue_break_body[1].get("set_local", {}).get("id") != 0
):
    raise SystemExit(f"expected asyncGeneratedWhileContinueBreak guarded while continue+break source, got {async_generated_while_continue_break}")
sync_generated_do_while = patch_by_member.get("syncGeneratedDoWhile", {}).get("bytecode_source", {})
sync_do_while_let = sync_generated_do_while.get("body", {}).get("let", {})
sync_do_while_seq = sync_do_while_let.get("body", {}).get("seq", [])
sync_do_while_first = sync_do_while_seq[0].get("seq", []) if len(sync_do_while_seq) > 0 else []
sync_do_while_loop = sync_do_while_seq[1].get("while_loop", {}) if len(sync_do_while_seq) > 1 else {}
sync_do_while_loop_body = sync_do_while_loop.get("body", {}).get("seq", [])
if (
    sync_generated_do_while.get("async_kind") != "sync_star"
    or sync_do_while_let.get("locals", [{}])[0].get("name") != "i"
    or len(sync_do_while_seq) != 2
    or len(sync_do_while_first) != 2
    or sync_do_while_first[0].get("yield", {}).get("concat") is None
    or sync_do_while_first[1].get("set_local", {}).get("id") != 0
    or sync_do_while_loop.get("condition", {}).get("op") != ">"
    or len(sync_do_while_loop_body) != 2
    or sync_do_while_loop_body[0].get("yield", {}).get("concat") is None
    or sync_do_while_loop_body[1].get("set_local", {}).get("id") != 0
):
    raise SystemExit(f"expected syncGeneratedDoWhile seq + while_loop source, got {sync_generated_do_while}")
async_generated_do_while = patch_by_member.get("asyncGeneratedDoWhile", {}).get("bytecode_source", {})
async_do_while_let = async_generated_do_while.get("body", {}).get("let", {})
async_do_while_seq = async_do_while_let.get("body", {}).get("seq", [])
async_do_while_first = async_do_while_seq[0].get("seq", []) if len(async_do_while_seq) > 0 else []
async_do_while_loop = async_do_while_seq[1].get("while_loop", {}) if len(async_do_while_seq) > 1 else {}
async_do_while_loop_body = async_do_while_loop.get("body", {}).get("seq", [])
if (
    async_generated_do_while.get("async_kind") != "async_star"
    or async_do_while_let.get("locals", [{}])[0].get("name") != "i"
    or len(async_do_while_seq) != 2
    or len(async_do_while_first) != 2
    or async_do_while_first[0].get("yield", {}).get("concat") is None
    or async_do_while_first[1].get("set_local", {}).get("id") != 0
    or async_do_while_loop.get("condition", {}).get("op") != ">"
    or len(async_do_while_loop_body) != 2
    or async_do_while_loop_body[0].get("yield", {}).get("concat") is None
    or async_do_while_loop_body[1].get("set_local", {}).get("id") != 0
):
    raise SystemExit(f"expected asyncGeneratedDoWhile seq + while_loop source, got {async_generated_do_while}")
sync_generated_do_while_break = patch_by_member.get("syncGeneratedDoWhileBreak", {}).get("bytecode_source", {})
sync_do_while_break_let = sync_generated_do_while_break.get("body", {}).get("let", {})
sync_do_while_break_seq = sync_do_while_break_let.get("body", {}).get("seq", [])
sync_do_while_break_cond = sync_do_while_break_seq[1].get("conditional", {}) if len(sync_do_while_break_seq) > 1 else {}
sync_do_while_break_else = sync_do_while_break_cond.get("else", {}).get("seq", [])
sync_do_while_break_loop = sync_do_while_break_else[2].get("while_loop", {}) if len(sync_do_while_break_else) > 2 else {}
sync_do_while_break_loop_body = sync_do_while_break_loop.get("body", {}).get("seq", [])
if (
    sync_generated_do_while_break.get("async_kind") != "sync_star"
    or sync_do_while_break_let.get("locals", [{}])[0].get("name") != "i"
    or len(sync_do_while_break_seq) != 2
    or sync_do_while_break_seq[0].get("yield", {}).get("concat") is None
    or sync_do_while_break_cond.get("condition", {}).get("op") != "=="
    or sync_do_while_break_cond.get("then", {}).get("null") is not True
    or len(sync_do_while_break_else) != 3
    or sync_do_while_break_else[0].get("yield", {}).get("concat") is None
    or sync_do_while_break_else[1].get("set_local", {}).get("id") != 0
    or sync_do_while_break_loop.get("condition", {}).get("op") != ">"
    or sync_do_while_break_loop.get("before_break", {}).get("yield", {}).get("concat") is None
    or sync_do_while_break_loop.get("break_condition", {}).get("op") != "=="
    or len(sync_do_while_break_loop_body) != 2
):
    raise SystemExit(f"expected syncGeneratedDoWhileBreak guarded do-while source, got {sync_generated_do_while_break}")
async_generated_do_while_break = patch_by_member.get("asyncGeneratedDoWhileBreak", {}).get("bytecode_source", {})
async_do_while_break_let = async_generated_do_while_break.get("body", {}).get("let", {})
async_do_while_break_seq = async_do_while_break_let.get("body", {}).get("seq", [])
async_do_while_break_cond = async_do_while_break_seq[1].get("conditional", {}) if len(async_do_while_break_seq) > 1 else {}
async_do_while_break_else = async_do_while_break_cond.get("else", {}).get("seq", [])
async_do_while_break_loop = async_do_while_break_else[2].get("while_loop", {}) if len(async_do_while_break_else) > 2 else {}
async_do_while_break_loop_body = async_do_while_break_loop.get("body", {}).get("seq", [])
if (
    async_generated_do_while_break.get("async_kind") != "async_star"
    or async_do_while_break_let.get("locals", [{}])[0].get("name") != "i"
    or len(async_do_while_break_seq) != 2
    or async_do_while_break_seq[0].get("yield", {}).get("concat") is None
    or async_do_while_break_cond.get("condition", {}).get("op") != "=="
    or async_do_while_break_cond.get("then", {}).get("null") is not True
    or len(async_do_while_break_else) != 3
    or async_do_while_break_else[0].get("yield", {}).get("concat") is None
    or async_do_while_break_else[1].get("set_local", {}).get("id") != 0
    or async_do_while_break_loop.get("condition", {}).get("op") != ">"
    or async_do_while_break_loop.get("before_break", {}).get("yield", {}).get("concat") is None
    or async_do_while_break_loop.get("break_condition", {}).get("op") != "=="
    or len(async_do_while_break_loop_body) != 2
):
    raise SystemExit(f"expected asyncGeneratedDoWhileBreak guarded do-while source, got {async_generated_do_while_break}")
sync_generated_do_while_continue = patch_by_member.get("syncGeneratedDoWhileContinue", {}).get("bytecode_source", {})
sync_do_while_continue_let = sync_generated_do_while_continue.get("body", {}).get("let", {})
sync_do_while_continue_seq = sync_do_while_continue_let.get("body", {}).get("seq", [])
sync_do_while_continue_cond = sync_do_while_continue_seq[1].get("conditional", {}) if len(sync_do_while_continue_seq) > 1 else {}
sync_do_while_continue_else = sync_do_while_continue_cond.get("else", {}).get("seq", [])
sync_do_while_continue_loop = sync_do_while_continue_seq[2].get("while_loop", {}) if len(sync_do_while_continue_seq) > 2 else {}
sync_do_while_continue_loop_body = sync_do_while_continue_loop.get("body", {}).get("seq", [])
if (
    sync_generated_do_while_continue.get("async_kind") != "sync_star"
    or sync_do_while_continue_let.get("locals", [{}])[0].get("name") != "i"
    or len(sync_do_while_continue_seq) != 3
    or sync_do_while_continue_seq[0].get("yield", {}).get("concat") is None
    or sync_do_while_continue_cond.get("condition", {}).get("op") != "=="
    or sync_do_while_continue_cond.get("then", {}).get("set_local", {}).get("id") != 0
    or len(sync_do_while_continue_else) != 2
    or sync_do_while_continue_else[0].get("yield", {}).get("concat") is None
    or sync_do_while_continue_else[1].get("set_local", {}).get("id") != 0
    or sync_do_while_continue_loop.get("condition", {}).get("op") != ">"
    or sync_do_while_continue_loop.get("before_continue", {}).get("yield", {}).get("concat") is None
    or sync_do_while_continue_loop.get("continue_condition", {}).get("op") != "=="
    or sync_do_while_continue_loop.get("continue_body", {}).get("set_local", {}).get("id") != 0
    or len(sync_do_while_continue_loop_body) != 2
):
    raise SystemExit(f"expected syncGeneratedDoWhileContinue guarded do-while source, got {sync_generated_do_while_continue}")
async_generated_do_while_continue = patch_by_member.get("asyncGeneratedDoWhileContinue", {}).get("bytecode_source", {})
async_do_while_continue_let = async_generated_do_while_continue.get("body", {}).get("let", {})
async_do_while_continue_seq = async_do_while_continue_let.get("body", {}).get("seq", [])
async_do_while_continue_cond = async_do_while_continue_seq[1].get("conditional", {}) if len(async_do_while_continue_seq) > 1 else {}
async_do_while_continue_else = async_do_while_continue_cond.get("else", {}).get("seq", [])
async_do_while_continue_loop = async_do_while_continue_seq[2].get("while_loop", {}) if len(async_do_while_continue_seq) > 2 else {}
async_do_while_continue_loop_body = async_do_while_continue_loop.get("body", {}).get("seq", [])
if (
    async_generated_do_while_continue.get("async_kind") != "async_star"
    or async_do_while_continue_let.get("locals", [{}])[0].get("name") != "i"
    or len(async_do_while_continue_seq) != 3
    or async_do_while_continue_seq[0].get("yield", {}).get("concat") is None
    or async_do_while_continue_cond.get("condition", {}).get("op") != "=="
    or async_do_while_continue_cond.get("then", {}).get("set_local", {}).get("id") != 0
    or len(async_do_while_continue_else) != 2
    or async_do_while_continue_else[0].get("yield", {}).get("concat") is None
    or async_do_while_continue_else[1].get("set_local", {}).get("id") != 0
    or async_do_while_continue_loop.get("condition", {}).get("op") != ">"
    or async_do_while_continue_loop.get("before_continue", {}).get("yield", {}).get("concat") is None
    or async_do_while_continue_loop.get("continue_condition", {}).get("op") != "=="
    or async_do_while_continue_loop.get("continue_body", {}).get("set_local", {}).get("id") != 0
    or len(async_do_while_continue_loop_body) != 2
):
    raise SystemExit(f"expected asyncGeneratedDoWhileContinue guarded do-while source, got {async_generated_do_while_continue}")
sync_generated_do_while_continue_break = patch_by_member.get("syncGeneratedDoWhileContinueBreak", {}).get("bytecode_source", {})
sync_do_while_continue_break_let = sync_generated_do_while_continue_break.get("body", {}).get("let", {})
sync_do_while_continue_break_seq = sync_do_while_continue_break_let.get("body", {}).get("seq", [])
sync_do_while_continue_break_cond = sync_do_while_continue_break_seq[1].get("conditional", {}) if len(sync_do_while_continue_break_seq) > 1 else {}
sync_do_while_continue_break_then = sync_do_while_continue_break_cond.get("then", {}).get("seq", [])
sync_do_while_continue_break_else = sync_do_while_continue_break_cond.get("else", {}).get("seq", [])
sync_do_while_continue_break_else_cond = sync_do_while_continue_break_else[1].get("conditional", {}) if len(sync_do_while_continue_break_else) > 1 else {}
sync_do_while_continue_break_after_break = sync_do_while_continue_break_else_cond.get("else", {}).get("seq", [])
sync_do_while_continue_break_loop = sync_do_while_continue_break_after_break[2].get("while_loop", {}) if len(sync_do_while_continue_break_after_break) > 2 else {}
sync_do_while_continue_break_loop_body = sync_do_while_continue_break_loop.get("body", {}).get("seq", [])
if (
    sync_generated_do_while_continue_break.get("async_kind") != "sync_star"
    or sync_do_while_continue_break_let.get("locals", [{}])[0].get("name") != "i"
    or len(sync_do_while_continue_break_seq) != 2
    or sync_do_while_continue_break_seq[0].get("yield", {}).get("concat") is None
    or sync_do_while_continue_break_cond.get("condition", {}).get("op") != "=="
    or len(sync_do_while_continue_break_then) != 2
    or sync_do_while_continue_break_then[0].get("set_local", {}).get("id") != 0
    or sync_do_while_continue_break_then[1].get("while_loop", {}).get("condition", {}).get("op") != ">"
    or len(sync_do_while_continue_break_else) != 2
    or sync_do_while_continue_break_else[0].get("yield", {}).get("concat") is None
    or sync_do_while_continue_break_else_cond.get("condition", {}).get("op") != "=="
    or sync_do_while_continue_break_else_cond.get("then", {}).get("null") is not True
    or len(sync_do_while_continue_break_after_break) != 3
    or sync_do_while_continue_break_after_break[0].get("yield", {}).get("concat") is None
    or sync_do_while_continue_break_after_break[1].get("set_local", {}).get("id") != 0
    or sync_do_while_continue_break_loop.get("before_continue", {}).get("yield", {}).get("concat") is None
    or sync_do_while_continue_break_loop.get("continue_condition", {}).get("op") != "=="
    or sync_do_while_continue_break_loop.get("continue_body", {}).get("set_local", {}).get("id") != 0
    or sync_do_while_continue_break_loop.get("before_break", {}).get("yield", {}).get("concat") is None
    or sync_do_while_continue_break_loop.get("break_condition", {}).get("op") != "=="
    or len(sync_do_while_continue_break_loop_body) != 2
):
    raise SystemExit(f"expected syncGeneratedDoWhileContinueBreak guarded do-while continue+break source, got {sync_generated_do_while_continue_break}")
async_generated_do_while_continue_break = patch_by_member.get("asyncGeneratedDoWhileContinueBreak", {}).get("bytecode_source", {})
async_do_while_continue_break_let = async_generated_do_while_continue_break.get("body", {}).get("let", {})
async_do_while_continue_break_seq = async_do_while_continue_break_let.get("body", {}).get("seq", [])
async_do_while_continue_break_cond = async_do_while_continue_break_seq[1].get("conditional", {}) if len(async_do_while_continue_break_seq) > 1 else {}
async_do_while_continue_break_then = async_do_while_continue_break_cond.get("then", {}).get("seq", [])
async_do_while_continue_break_else = async_do_while_continue_break_cond.get("else", {}).get("seq", [])
async_do_while_continue_break_else_cond = async_do_while_continue_break_else[1].get("conditional", {}) if len(async_do_while_continue_break_else) > 1 else {}
async_do_while_continue_break_after_break = async_do_while_continue_break_else_cond.get("else", {}).get("seq", [])
async_do_while_continue_break_loop = async_do_while_continue_break_after_break[2].get("while_loop", {}) if len(async_do_while_continue_break_after_break) > 2 else {}
async_do_while_continue_break_loop_body = async_do_while_continue_break_loop.get("body", {}).get("seq", [])
if (
    async_generated_do_while_continue_break.get("async_kind") != "async_star"
    or async_do_while_continue_break_let.get("locals", [{}])[0].get("name") != "i"
    or len(async_do_while_continue_break_seq) != 2
    or async_do_while_continue_break_seq[0].get("yield", {}).get("concat") is None
    or async_do_while_continue_break_cond.get("condition", {}).get("op") != "=="
    or len(async_do_while_continue_break_then) != 2
    or async_do_while_continue_break_then[0].get("set_local", {}).get("id") != 0
    or async_do_while_continue_break_then[1].get("while_loop", {}).get("condition", {}).get("op") != ">"
    or len(async_do_while_continue_break_else) != 2
    or async_do_while_continue_break_else[0].get("yield", {}).get("concat") is None
    or async_do_while_continue_break_else_cond.get("condition", {}).get("op") != "=="
    or async_do_while_continue_break_else_cond.get("then", {}).get("null") is not True
    or len(async_do_while_continue_break_after_break) != 3
    or async_do_while_continue_break_after_break[0].get("yield", {}).get("concat") is None
    or async_do_while_continue_break_after_break[1].get("set_local", {}).get("id") != 0
    or async_do_while_continue_break_loop.get("before_continue", {}).get("yield", {}).get("concat") is None
    or async_do_while_continue_break_loop.get("continue_condition", {}).get("op") != "=="
    or async_do_while_continue_break_loop.get("continue_body", {}).get("set_local", {}).get("id") != 0
    or async_do_while_continue_break_loop.get("before_break", {}).get("yield", {}).get("concat") is None
    or async_do_while_continue_break_loop.get("break_condition", {}).get("op") != "=="
    or len(async_do_while_continue_break_loop_body) != 2
):
    raise SystemExit(f"expected asyncGeneratedDoWhileContinueBreak guarded do-while continue+break source, got {async_generated_do_while_continue_break}")
sync_generated_for_loop = patch_by_member.get("syncGeneratedForLoop", {}).get("bytecode_source", {})
sync_for_loop_let = sync_generated_for_loop.get("body", {}).get("let", {})
sync_for_loop = sync_for_loop_let.get("body", {}).get("while_loop", {})
sync_for_loop_body = sync_for_loop.get("body", {}).get("seq", [])
if (
    sync_generated_for_loop.get("async_kind") != "sync_star"
    or sync_for_loop_let.get("locals", [{}])[0].get("name") != "i"
    or sync_for_loop_let.get("locals", [{}])[0].get("value", {}).get("int") != 0
    or sync_for_loop.get("condition", {}).get("op") != ">"
    or len(sync_for_loop_body) != 2
    or sync_for_loop_body[0].get("yield", {}).get("concat") is None
    or sync_for_loop_body[1].get("set_local", {}).get("id") != 0
    or sync_for_loop_body[1].get("set_local", {}).get("value", {}).get("op") != "+"
):
    raise SystemExit(f"expected syncGeneratedForLoop lowered for source, got {sync_generated_for_loop}")
async_generated_for_loop = patch_by_member.get("asyncGeneratedForLoop", {}).get("bytecode_source", {})
async_for_loop_let = async_generated_for_loop.get("body", {}).get("let", {})
async_for_loop = async_for_loop_let.get("body", {}).get("while_loop", {})
async_for_loop_body = async_for_loop.get("body", {}).get("seq", [])
if (
    async_generated_for_loop.get("async_kind") != "async_star"
    or async_for_loop_let.get("locals", [{}])[0].get("name") != "i"
    or async_for_loop_let.get("locals", [{}])[0].get("value", {}).get("int") != 0
    or async_for_loop.get("condition", {}).get("op") != ">"
    or len(async_for_loop_body) != 2
    or async_for_loop_body[0].get("yield", {}).get("concat") is None
    or async_for_loop_body[1].get("set_local", {}).get("id") != 0
    or async_for_loop_body[1].get("set_local", {}).get("value", {}).get("op") != "+"
):
    raise SystemExit(f"expected asyncGeneratedForLoop lowered for source, got {async_generated_for_loop}")
sync_generated_for_loop_postinc = patch_by_member.get("syncGeneratedForLoopPostIncrement", {}).get("bytecode_source", {})
sync_for_loop_postinc_let = sync_generated_for_loop_postinc.get("body", {}).get("let", {})
sync_for_loop_postinc = sync_for_loop_postinc_let.get("body", {}).get("while_loop", {})
sync_for_loop_postinc_body = sync_for_loop_postinc.get("body", {}).get("seq", [])
if (
    sync_generated_for_loop_postinc.get("async_kind") != "sync_star"
    or sync_for_loop_postinc_let.get("locals", [{}])[0].get("name") != "i"
    or sync_for_loop_postinc.get("condition", {}).get("op") != ">"
    or len(sync_for_loop_postinc_body) != 2
    or sync_for_loop_postinc_body[0].get("yield", {}).get("concat") is None
    or sync_for_loop_postinc_body[1].get("set_local", {}).get("id") != 0
    or sync_for_loop_postinc_body[1].get("set_local", {}).get("value", {}).get("op") != "+"
):
    raise SystemExit(f"expected syncGeneratedForLoopPostIncrement lowered post-increment source, got {sync_generated_for_loop_postinc}")
async_generated_for_loop_postinc = patch_by_member.get("asyncGeneratedForLoopPostIncrement", {}).get("bytecode_source", {})
async_for_loop_postinc_let = async_generated_for_loop_postinc.get("body", {}).get("let", {})
async_for_loop_postinc = async_for_loop_postinc_let.get("body", {}).get("while_loop", {})
async_for_loop_postinc_body = async_for_loop_postinc.get("body", {}).get("seq", [])
if (
    async_generated_for_loop_postinc.get("async_kind") != "async_star"
    or async_for_loop_postinc_let.get("locals", [{}])[0].get("name") != "i"
    or async_for_loop_postinc.get("condition", {}).get("op") != ">"
    or len(async_for_loop_postinc_body) != 2
    or async_for_loop_postinc_body[0].get("yield", {}).get("concat") is None
    or async_for_loop_postinc_body[1].get("set_local", {}).get("id") != 0
    or async_for_loop_postinc_body[1].get("set_local", {}).get("value", {}).get("op") != "+"
):
    raise SystemExit(f"expected asyncGeneratedForLoopPostIncrement lowered post-increment source, got {async_generated_for_loop_postinc}")
sync_generated_for_loop_multi = patch_by_member.get("syncGeneratedForLoopMultiUpdate", {}).get("bytecode_source", {})
sync_for_loop_multi_let = sync_generated_for_loop_multi.get("body", {}).get("let", {})
sync_for_loop_multi = sync_for_loop_multi_let.get("body", {}).get("while_loop", {})
sync_for_loop_multi_body = sync_for_loop_multi.get("body", {}).get("seq", [])
sync_for_loop_multi_locals = sync_for_loop_multi_let.get("locals", [])
if (
    sync_generated_for_loop_multi.get("async_kind") != "sync_star"
    or [item.get("name") for item in sync_for_loop_multi_locals] != ["i", "j"]
    or sync_for_loop_multi_locals[0].get("value", {}).get("int") != 0
    or sync_for_loop_multi_locals[1].get("value", {}).get("int") != 10
    or sync_for_loop_multi.get("condition", {}).get("op") != ">"
    or len(sync_for_loop_multi_body) != 3
    or sync_for_loop_multi_body[0].get("yield", {}).get("concat") is None
    or sync_for_loop_multi_body[1].get("set_local", {}).get("id") != 0
    or sync_for_loop_multi_body[2].get("set_local", {}).get("id") != 1
):
    raise SystemExit(f"expected syncGeneratedForLoopMultiUpdate multi-update source, got {sync_generated_for_loop_multi}")
async_generated_for_loop_multi = patch_by_member.get("asyncGeneratedForLoopMultiUpdate", {}).get("bytecode_source", {})
async_for_loop_multi_let = async_generated_for_loop_multi.get("body", {}).get("let", {})
async_for_loop_multi = async_for_loop_multi_let.get("body", {}).get("while_loop", {})
async_for_loop_multi_body = async_for_loop_multi.get("body", {}).get("seq", [])
async_for_loop_multi_locals = async_for_loop_multi_let.get("locals", [])
if (
    async_generated_for_loop_multi.get("async_kind") != "async_star"
    or [item.get("name") for item in async_for_loop_multi_locals] != ["i", "j"]
    or async_for_loop_multi_locals[0].get("value", {}).get("int") != 0
    or async_for_loop_multi_locals[1].get("value", {}).get("int") != 10
    or async_for_loop_multi.get("condition", {}).get("op") != ">"
    or len(async_for_loop_multi_body) != 3
    or async_for_loop_multi_body[0].get("yield", {}).get("concat") is None
    or async_for_loop_multi_body[1].get("set_local", {}).get("id") != 0
    or async_for_loop_multi_body[2].get("set_local", {}).get("id") != 1
):
    raise SystemExit(f"expected asyncGeneratedForLoopMultiUpdate multi-update source, got {async_generated_for_loop_multi}")
sync_generated_for_loop_external = patch_by_member.get("syncGeneratedForLoopExternalLocal", {}).get("bytecode_source", {})
sync_for_loop_external_let = sync_generated_for_loop_external.get("body", {}).get("let", {})
sync_for_loop_external = sync_for_loop_external_let.get("body", {}).get("while_loop", {})
sync_for_loop_external_body = sync_for_loop_external.get("body", {}).get("seq", [])
if (
    sync_generated_for_loop_external.get("async_kind") != "sync_star"
    or sync_for_loop_external_let.get("locals", [{}])[0].get("name") != "i"
    or sync_for_loop_external.get("condition", {}).get("op") != ">"
    or len(sync_for_loop_external_body) != 2
    or sync_for_loop_external_body[0].get("yield", {}).get("concat") is None
    or sync_for_loop_external_body[1].get("set_local", {}).get("id") != 0
):
    raise SystemExit(f"expected syncGeneratedForLoopExternalLocal no-init source, got {sync_generated_for_loop_external}")
async_generated_for_loop_external = patch_by_member.get("asyncGeneratedForLoopExternalLocal", {}).get("bytecode_source", {})
async_for_loop_external_let = async_generated_for_loop_external.get("body", {}).get("let", {})
async_for_loop_external = async_for_loop_external_let.get("body", {}).get("while_loop", {})
async_for_loop_external_body = async_for_loop_external.get("body", {}).get("seq", [])
if (
    async_generated_for_loop_external.get("async_kind") != "async_star"
    or async_for_loop_external_let.get("locals", [{}])[0].get("name") != "i"
    or async_for_loop_external.get("condition", {}).get("op") != ">"
    or len(async_for_loop_external_body) != 2
    or async_for_loop_external_body[0].get("yield", {}).get("concat") is None
    or async_for_loop_external_body[1].get("set_local", {}).get("id") != 0
):
    raise SystemExit(f"expected asyncGeneratedForLoopExternalLocal no-init source, got {async_generated_for_loop_external}")
sync_generated_for_loop_body_update = patch_by_member.get("syncGeneratedForLoopBodyUpdate", {}).get("bytecode_source", {})
sync_for_loop_body_update_let = sync_generated_for_loop_body_update.get("body", {}).get("let", {})
sync_for_loop_body_update = sync_for_loop_body_update_let.get("body", {}).get("while_loop", {})
sync_for_loop_body_update_body = sync_for_loop_body_update.get("body", {}).get("seq", [])
if (
    sync_generated_for_loop_body_update.get("async_kind") != "sync_star"
    or sync_for_loop_body_update_let.get("locals", [{}])[0].get("name") != "i"
    or sync_for_loop_body_update.get("condition", {}).get("op") != ">"
    or len(sync_for_loop_body_update_body) != 2
    or sync_for_loop_body_update_body[0].get("yield", {}).get("concat") is None
    or sync_for_loop_body_update_body[1].get("set_local", {}).get("id") != 0
):
    raise SystemExit(f"expected syncGeneratedForLoopBodyUpdate no-update source, got {sync_generated_for_loop_body_update}")
async_generated_for_loop_body_update = patch_by_member.get("asyncGeneratedForLoopBodyUpdate", {}).get("bytecode_source", {})
async_for_loop_body_update_let = async_generated_for_loop_body_update.get("body", {}).get("let", {})
async_for_loop_body_update = async_for_loop_body_update_let.get("body", {}).get("while_loop", {})
async_for_loop_body_update_body = async_for_loop_body_update.get("body", {}).get("seq", [])
if (
    async_generated_for_loop_body_update.get("async_kind") != "async_star"
    or async_for_loop_body_update_let.get("locals", [{}])[0].get("name") != "i"
    or async_for_loop_body_update.get("condition", {}).get("op") != ">"
    or len(async_for_loop_body_update_body) != 2
    or async_for_loop_body_update_body[0].get("yield", {}).get("concat") is None
    or async_for_loop_body_update_body[1].get("set_local", {}).get("id") != 0
):
    raise SystemExit(f"expected asyncGeneratedForLoopBodyUpdate no-update source, got {async_generated_for_loop_body_update}")
sync_generated_for_loop_continue = patch_by_member.get("syncGeneratedForLoopContinue", {}).get("bytecode_source", {})
sync_for_loop_continue_let = sync_generated_for_loop_continue.get("body", {}).get("let", {})
sync_for_loop_continue = sync_for_loop_continue_let.get("body", {}).get("while_loop", {})
sync_for_loop_continue_body = sync_for_loop_continue.get("body", {}).get("seq", [])
sync_for_loop_continue_guard = sync_for_loop_continue_body[1].get("conditional", {}) if len(sync_for_loop_continue_body) > 1 else {}
if (
    sync_generated_for_loop_continue.get("async_kind") != "sync_star"
    or sync_for_loop_continue_let.get("locals", [{}])[0].get("name") != "i"
    or sync_for_loop_continue.get("condition", {}).get("op") != ">"
    or len(sync_for_loop_continue_body) != 3
    or sync_for_loop_continue_body[0].get("yield", {}).get("concat") is None
    or sync_for_loop_continue_guard.get("condition", {}).get("op") != "=="
    or sync_for_loop_continue_guard.get("then", {}).get("null") is not True
    or sync_for_loop_continue_guard.get("else", {}).get("yield", {}).get("concat") is None
    or sync_for_loop_continue_body[2].get("set_local", {}).get("id") != 0
):
    raise SystemExit(f"expected syncGeneratedForLoopContinue lowered continue source, got {sync_generated_for_loop_continue}")
async_generated_for_loop_continue = patch_by_member.get("asyncGeneratedForLoopContinue", {}).get("bytecode_source", {})
async_for_loop_continue_let = async_generated_for_loop_continue.get("body", {}).get("let", {})
async_for_loop_continue = async_for_loop_continue_let.get("body", {}).get("while_loop", {})
async_for_loop_continue_body = async_for_loop_continue.get("body", {}).get("seq", [])
async_for_loop_continue_guard = async_for_loop_continue_body[1].get("conditional", {}) if len(async_for_loop_continue_body) > 1 else {}
if (
    async_generated_for_loop_continue.get("async_kind") != "async_star"
    or async_for_loop_continue_let.get("locals", [{}])[0].get("name") != "i"
    or async_for_loop_continue.get("condition", {}).get("op") != ">"
    or len(async_for_loop_continue_body) != 3
    or async_for_loop_continue_body[0].get("yield", {}).get("concat") is None
    or async_for_loop_continue_guard.get("condition", {}).get("op") != "=="
    or async_for_loop_continue_guard.get("then", {}).get("null") is not True
    or async_for_loop_continue_guard.get("else", {}).get("yield", {}).get("concat") is None
    or async_for_loop_continue_body[2].get("set_local", {}).get("id") != 0
):
    raise SystemExit(f"expected asyncGeneratedForLoopContinue lowered continue source, got {async_generated_for_loop_continue}")
sync_generated_for_loop_continue_break = patch_by_member.get("syncGeneratedForLoopContinueBreak", {}).get("bytecode_source", {})
sync_for_loop_continue_break_let = sync_generated_for_loop_continue_break.get("body", {}).get("let", {})
sync_for_loop_continue_break = sync_for_loop_continue_break_let.get("body", {}).get("while_loop", {})
sync_for_loop_continue_break_body = sync_for_loop_continue_break.get("body", {}).get("seq", [])
if (
    sync_generated_for_loop_continue_break.get("async_kind") != "sync_star"
    or sync_for_loop_continue_break_let.get("locals", [{}])[0].get("name") != "i"
    or sync_for_loop_continue_break.get("condition", {}).get("op") != ">"
    or sync_for_loop_continue_break.get("before_continue", {}).get("yield", {}).get("concat") is None
    or sync_for_loop_continue_break.get("continue_condition", {}).get("op") != "=="
    or sync_for_loop_continue_break.get("continue_body", {}).get("set_local", {}).get("id") != 0
    or sync_for_loop_continue_break.get("before_break", {}).get("yield", {}).get("concat") is None
    or sync_for_loop_continue_break.get("break_condition", {}).get("op") != "=="
    or len(sync_for_loop_continue_break_body) != 2
    or sync_for_loop_continue_break_body[0].get("yield", {}).get("concat") is None
    or sync_for_loop_continue_break_body[1].get("set_local", {}).get("id") != 0
):
    raise SystemExit(f"expected syncGeneratedForLoopContinueBreak lowered continue+break source, got {sync_generated_for_loop_continue_break}")
async_generated_for_loop_continue_break = patch_by_member.get("asyncGeneratedForLoopContinueBreak", {}).get("bytecode_source", {})
async_for_loop_continue_break_let = async_generated_for_loop_continue_break.get("body", {}).get("let", {})
async_for_loop_continue_break = async_for_loop_continue_break_let.get("body", {}).get("while_loop", {})
async_for_loop_continue_break_body = async_for_loop_continue_break.get("body", {}).get("seq", [])
if (
    async_generated_for_loop_continue_break.get("async_kind") != "async_star"
    or async_for_loop_continue_break_let.get("locals", [{}])[0].get("name") != "i"
    or async_for_loop_continue_break.get("condition", {}).get("op") != ">"
    or async_for_loop_continue_break.get("before_continue", {}).get("yield", {}).get("concat") is None
    or async_for_loop_continue_break.get("continue_condition", {}).get("op") != "=="
    or async_for_loop_continue_break.get("continue_body", {}).get("set_local", {}).get("id") != 0
    or async_for_loop_continue_break.get("before_break", {}).get("yield", {}).get("concat") is None
    or async_for_loop_continue_break.get("break_condition", {}).get("op") != "=="
    or len(async_for_loop_continue_break_body) != 2
    or async_for_loop_continue_break_body[0].get("yield", {}).get("concat") is None
    or async_for_loop_continue_break_body[1].get("set_local", {}).get("id") != 0
):
    raise SystemExit(f"expected asyncGeneratedForLoopContinueBreak lowered continue+break source, got {async_generated_for_loop_continue_break}")
sync_generated_for_loop_break = patch_by_member.get("syncGeneratedForLoopBreak", {}).get("bytecode_source", {})
sync_for_loop_break_let = sync_generated_for_loop_break.get("body", {}).get("let", {})
sync_for_loop_break = sync_for_loop_break_let.get("body", {}).get("while_loop", {})
sync_for_loop_break_body = sync_for_loop_break.get("body", {}).get("seq", [])
if (
    sync_generated_for_loop_break.get("async_kind") != "sync_star"
    or sync_for_loop_break_let.get("locals", [{}])[0].get("name") != "i"
    or sync_for_loop_break.get("condition", {}).get("op") != ">"
    or sync_for_loop_break.get("before_break", {}).get("yield", {}).get("concat") is None
    or sync_for_loop_break.get("break_condition", {}).get("op") != "=="
    or len(sync_for_loop_break_body) != 2
    or sync_for_loop_break_body[0].get("yield", {}).get("concat") is None
    or sync_for_loop_break_body[1].get("set_local", {}).get("id") != 0
):
    raise SystemExit(f"expected syncGeneratedForLoopBreak lowered break source, got {sync_generated_for_loop_break}")
async_generated_for_loop_break = patch_by_member.get("asyncGeneratedForLoopBreak", {}).get("bytecode_source", {})
async_for_loop_break_let = async_generated_for_loop_break.get("body", {}).get("let", {})
async_for_loop_break = async_for_loop_break_let.get("body", {}).get("while_loop", {})
async_for_loop_break_body = async_for_loop_break.get("body", {}).get("seq", [])
if (
    async_generated_for_loop_break.get("async_kind") != "async_star"
    or async_for_loop_break_let.get("locals", [{}])[0].get("name") != "i"
    or async_for_loop_break.get("condition", {}).get("op") != ">"
    or async_for_loop_break.get("before_break", {}).get("yield", {}).get("concat") is None
    or async_for_loop_break.get("break_condition", {}).get("op") != "=="
    or len(async_for_loop_break_body) != 2
    or async_for_loop_break_body[0].get("yield", {}).get("concat") is None
    or async_for_loop_break_body[1].get("set_local", {}).get("id") != 0
):
    raise SystemExit(f"expected asyncGeneratedForLoopBreak lowered break source, got {async_generated_for_loop_break}")

json.dump(plan, open(sys.argv[3], "w"))
