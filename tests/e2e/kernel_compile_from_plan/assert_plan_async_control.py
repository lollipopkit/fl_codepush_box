import json
import sys

patch = json.load(open(sys.argv[1]))
patch_by_member = {f.get("member_name"): f for f in patch["functions"]}

async_branch_local = patch_by_member.get("asyncBranchLocal", {}).get("bytecode_source", {})
async_branch_conditional = async_branch_local.get("body", {}).get("new_object", {}).get("args", [{}])[0].get("conditional", {})
if (
    async_branch_conditional.get("condition", {}).get("arg") != "enabled"
    or async_branch_conditional.get("then", {}).get("let", {}).get("locals", [{}])[0].get("name") != "status"
    or async_branch_conditional.get("else", {}).get("let", {}).get("locals", [{}])[0].get("name") != "status"
):
    raise SystemExit(f"expected asyncBranchLocal branch-local conditional source, got {async_branch_local}")
async_nested_branch_local = patch_by_member.get("asyncNestedBranchLocal", {}).get("bytecode_source", {})
async_nested_arg = async_nested_branch_local.get("body", {}).get("new_object", {}).get("args", [{}])[0]
async_nested_outer = async_nested_arg.get("conditional", {})
async_nested_then_let = async_nested_outer.get("then", {}).get("let", {})
async_nested_then_inner = async_nested_then_let.get("body", {}).get("conditional", {})
async_nested_then_pro = async_nested_then_inner.get("then", {}).get("let", {})
async_nested_then_basic = async_nested_then_inner.get("else", {}).get("let", {})
async_nested_else_let = async_nested_outer.get("else", {}).get("let", {})
async_nested_else_inner = async_nested_else_let.get("body", {}).get("conditional", {})
async_nested_else_pro = async_nested_else_inner.get("then", {}).get("let", {})
async_nested_else_basic = async_nested_else_inner.get("else", {}).get("let", {})
if (
    async_nested_outer.get("condition", {}).get("arg") != "enabled"
    or async_nested_then_let.get("locals", [{}])[0].get("name") != "state"
    or async_nested_then_let.get("locals", [{}])[0].get("value", {}).get("string") != "patched-nested-enabled"
    or async_nested_then_inner.get("condition", {}).get("arg") != "premium"
    or async_nested_then_pro.get("locals", [{}])[0].get("name") != "tier"
    or async_nested_then_pro.get("locals", [{}])[0].get("value", {}).get("string") != "patched-nested-pro"
    or async_nested_then_basic.get("locals", [{}])[0].get("value", {}).get("string") != "patched-nested-basic"
    or async_nested_else_let.get("locals", [{}])[0].get("name") != "state"
    or async_nested_else_let.get("locals", [{}])[0].get("value", {}).get("string") != "patched-nested-disabled"
    or async_nested_else_inner.get("condition", {}).get("arg") != "premium"
    or async_nested_else_pro.get("locals", [{}])[0].get("value", {}).get("string") != "patched-nested-disabled-pro"
    or async_nested_else_basic.get("locals", [{}])[0].get("value", {}).get("string") != "patched-nested-disabled-basic"
    or async_nested_then_pro.get("body", {}).get("concat", [{}, {}, {}])[0].get("let_local") != 0
    or async_nested_then_pro.get("body", {}).get("concat", [{}, {}, {}])[2].get("let_local") != 1
):
    raise SystemExit(f"expected asyncNestedBranchLocal nested branch-local source, got {async_nested_branch_local}")
async_nested_await_branch_local = patch_by_member.get("asyncNestedAwaitBranchLocal", {}).get("bytecode_source", {})
async_nested_await_arg = async_nested_await_branch_local.get("body", {}).get("new_object", {}).get("args", [{}])[0]
async_nested_await_outer = async_nested_await_arg.get("conditional", {})
async_nested_await_then_let = async_nested_await_outer.get("then", {}).get("let", {})
async_nested_await_then_inner = async_nested_await_then_let.get("body", {}).get("conditional", {})
async_nested_await_then_pro = async_nested_await_then_inner.get("then", {}).get("let", {})
async_nested_await_then_basic = async_nested_await_then_inner.get("else", {}).get("let", {})
async_nested_await_else_let = async_nested_await_outer.get("else", {}).get("let", {})
async_nested_await_else_inner = async_nested_await_else_let.get("body", {}).get("conditional", {})
async_nested_await_else_pro = async_nested_await_else_inner.get("then", {}).get("let", {})
async_nested_await_else_basic = async_nested_await_else_inner.get("else", {}).get("let", {})
if (
    async_nested_await_outer.get("condition", {}).get("arg") != "enabled"
    or async_nested_await_then_let.get("locals", [{}])[0].get("name") != "state"
    or async_nested_await_then_let.get("locals", [{}])[0].get("value", {}).get("await", {}).get("arg") != "ready"
    or async_nested_await_then_inner.get("condition", {}).get("arg") != "premium"
    or async_nested_await_then_pro.get("locals", [{}])[0].get("value", {}).get("string") != "patched-nested-await-pro"
    or async_nested_await_then_basic.get("locals", [{}])[0].get("value", {}).get("string") != "patched-nested-await-basic"
    or async_nested_await_else_let.get("locals", [{}])[0].get("value", {}).get("string") != "patched-nested-await-disabled"
    or async_nested_await_else_inner.get("condition", {}).get("arg") != "premium"
    or async_nested_await_else_pro.get("locals", [{}])[0].get("name") != "tier"
    or async_nested_await_else_pro.get("locals", [{}])[0].get("value", {}).get("await", {}).get("arg") != "ready"
    or async_nested_await_else_basic.get("locals", [{}])[0].get("value", {}).get("string") != "patched-nested-await-disabled-basic"
    or async_nested_await_else_pro.get("body", {}).get("concat", [{}, {}, {}])[0].get("let_local") != 0
    or async_nested_await_else_pro.get("body", {}).get("concat", [{}, {}, {}])[2].get("let_local") != 1
):
    raise SystemExit(f"expected asyncNestedAwaitBranchLocal nested await branch-local source, got {async_nested_await_branch_local}")
async_ifelse_side_effect = patch_by_member.get("asyncIfElseSideEffectTail", {}).get("bytecode_source", {})
async_ifelse_arg = async_ifelse_side_effect.get("body", {}).get("new_object", {}).get("args", [{}])[0]
async_ifelse_let = async_ifelse_arg.get("let", {})
async_ifelse_conditional = async_ifelse_let.get("body", {}).get("conditional", {})
async_ifelse_then = async_ifelse_conditional.get("then", {}).get("let", {})
async_ifelse_then_body = async_ifelse_then.get("body", {}).get("seq", [])
async_ifelse_then_tail = async_ifelse_then_body[1].get("seq", []) if len(async_ifelse_then_body) > 1 else []
async_ifelse_else = async_ifelse_conditional.get("else", {}).get("let", {})
async_ifelse_else_body = async_ifelse_else.get("body", {}).get("seq", [])
async_ifelse_else_tail = async_ifelse_else_body[1].get("seq", []) if len(async_ifelse_else_body) > 1 else []
if (
    async_ifelse_side_effect.get("async_future") is not True
    or async_ifelse_side_effect.get("body", {}).get("new_object", {}).get("type_args") != ["String"]
    or async_ifelse_let.get("locals", [{}])[0].get("name") != "out"
    or async_ifelse_let.get("locals", [{}])[0].get("value", {}).get("string") != "patched-ifelse-side-effect"
    or async_ifelse_conditional.get("condition", {}).get("arg") != "enabled"
    or async_ifelse_then.get("locals", [{}])[0].get("name") != "state"
    or async_ifelse_then.get("locals", [{}])[0].get("value", {}).get("await", {}).get("arg") != "ready"
    or async_ifelse_then_body[0].get("set_local", {}).get("id") != 0
    or async_ifelse_then_tail[0].get("set_local", {}).get("id") != 0
    or async_ifelse_then_tail[1].get("let_local") != 0
    or async_ifelse_else.get("locals", [{}])[0].get("name") != "state"
    or async_ifelse_else.get("locals", [{}])[0].get("value", {}).get("string") != "patched-ifelse-disabled"
    or async_ifelse_else_body[0].get("set_local", {}).get("id") != 0
    or async_ifelse_else_tail[0].get("set_local", {}).get("id") != 0
    or async_ifelse_else_tail[1].get("let_local") != 0
):
    raise SystemExit(f"expected asyncIfElseSideEffectTail side-effect if/else + tail source, got {async_ifelse_side_effect}")
async_if_side_effect = patch_by_member.get("asyncIfSideEffectTail", {}).get("bytecode_source", {})
async_if_arg = async_if_side_effect.get("body", {}).get("new_object", {}).get("args", [{}])[0]
async_if_let = async_if_arg.get("let", {})
async_if_conditional = async_if_let.get("body", {}).get("conditional", {})
async_if_then = async_if_conditional.get("then", {}).get("let", {})
async_if_then_body = async_if_then.get("body", {}).get("seq", [])
async_if_then_tail = async_if_then_body[1].get("seq", []) if len(async_if_then_body) > 1 else []
async_if_else_tail = async_if_conditional.get("else", {}).get("seq", [])
if (
    async_if_side_effect.get("async_future") is not True
    or async_if_side_effect.get("body", {}).get("new_object", {}).get("type_args") != ["String"]
    or async_if_let.get("locals", [{}])[0].get("name") != "out"
    or async_if_let.get("locals", [{}])[0].get("value", {}).get("string") != "patched-if-side-effect"
    or async_if_conditional.get("condition", {}).get("arg") != "enabled"
    or async_if_then.get("locals", [{}])[0].get("name") != "state"
    or async_if_then.get("locals", [{}])[0].get("value", {}).get("await", {}).get("arg") != "ready"
    or async_if_then_body[0].get("set_local", {}).get("id") != 0
    or async_if_then_tail[0].get("set_local", {}).get("id") != 0
    or async_if_then_tail[1].get("let_local") != 0
    or async_if_else_tail[0].get("set_local", {}).get("id") != 0
    or async_if_else_tail[1].get("let_local") != 0
):
    raise SystemExit(f"expected asyncIfSideEffectTail side-effect if + tail source, got {async_if_side_effect}")
async_conditional_await = patch_by_member.get("asyncConditionalAwaitExpr", {}).get("bytecode_source", {})
async_conditional_arg = async_conditional_await.get("body", {}).get("new_object", {}).get("args", [{}])[0]
async_conditional = async_conditional_arg.get("conditional", {})
if (
    async_conditional_await.get("async_future") is not True
    or async_conditional_await.get("body", {}).get("new_object", {}).get("type_args") != ["String"]
    or async_conditional.get("condition", {}).get("arg") != "enabled"
    or async_conditional.get("then", {}).get("await", {}).get("arg") != "ready"
    or async_conditional.get("else", {}).get("string") != "patched-conditional-disabled"
):
    raise SystemExit(f"expected asyncConditionalAwaitExpr conditional await source, got {async_conditional_await}")
async_less_than_await = patch_by_member.get("asyncLessThanAwaitTail", {}).get("bytecode_source", {})
async_less_than_conditional = async_less_than_await.get("body", {}).get("new_object", {}).get("args", [{}])[0].get("conditional", {})
async_less_than_condition = async_less_than_conditional.get("condition", {})
if (
    async_less_than_await.get("async_future") is not True
    or async_less_than_await.get("body", {}).get("new_object", {}).get("type_args") != ["String"]
    or async_less_than_condition.get("op") != "<"
    or async_less_than_condition.get("left", {}).get("arg") != "limit"
    or async_less_than_condition.get("right", {}).get("int") != 2
    or async_less_than_conditional.get("then", {}).get("await", {}).get("arg") != "ready"
    or async_less_than_conditional.get("else", {}).get("string") != "patched-less-than-tail"
):
    raise SystemExit(f"expected asyncLessThanAwaitTail less-than await source, got {async_less_than_await}")
async_less_equal_await = patch_by_member.get("asyncLessEqualAwaitTail", {}).get("bytecode_source", {})
async_less_equal_conditional = async_less_equal_await.get("body", {}).get("new_object", {}).get("args", [{}])[0].get("conditional", {})
async_less_equal_condition = async_less_equal_conditional.get("condition", {}).get("conditional", {})
if (
    async_less_equal_await.get("async_future") is not True
    or async_less_equal_await.get("body", {}).get("new_object", {}).get("type_args") != ["String"]
    or async_less_equal_condition.get("condition", {}).get("op") != ">"
    or async_less_equal_condition.get("condition", {}).get("left", {}).get("arg") != "limit"
    or async_less_equal_condition.get("condition", {}).get("right", {}).get("int") != 2
    or async_less_equal_conditional.get("then", {}).get("await", {}).get("arg") != "ready"
    or async_less_equal_conditional.get("else", {}).get("string") != "patched-less-equal-tail"
    or async_less_equal_condition.get("then", {}).get("bool") is not False
    or async_less_equal_condition.get("else", {}).get("bool") is not True
):
    raise SystemExit(f"expected asyncLessEqualAwaitTail less-equal source, got {async_less_equal_await}")
async_greater_equal_await = patch_by_member.get("asyncGreaterEqualAwaitTail", {}).get("bytecode_source", {})
async_greater_equal_conditional = async_greater_equal_await.get("body", {}).get("new_object", {}).get("args", [{}])[0].get("conditional", {})
async_greater_equal_condition = async_greater_equal_conditional.get("condition", {}).get("conditional", {})
async_greater_equal_else = async_greater_equal_condition.get("else", {})
if (
    async_greater_equal_await.get("async_future") is not True
    or async_greater_equal_await.get("body", {}).get("new_object", {}).get("type_args") != ["String"]
    or async_greater_equal_condition.get("condition", {}).get("op") != ">"
    or async_greater_equal_condition.get("condition", {}).get("left", {}).get("arg") != "limit"
    or async_greater_equal_condition.get("condition", {}).get("right", {}).get("int") != 2
    or async_greater_equal_condition.get("then", {}).get("bool") is not True
    or async_greater_equal_else.get("op") != "=="
    or async_greater_equal_else.get("left", {}).get("arg") != "limit"
    or async_greater_equal_else.get("right", {}).get("int") != 2
    or async_greater_equal_conditional.get("then", {}).get("await", {}).get("arg") != "ready"
    or async_greater_equal_conditional.get("else", {}).get("string") != "patched-greater-equal-tail"
):
    raise SystemExit(f"expected asyncGreaterEqualAwaitTail greater-equal source, got {async_greater_equal_await}")
async_not_equal_await = patch_by_member.get("asyncNotEqualAwaitTail", {}).get("bytecode_source", {})
async_not_equal_conditional = async_not_equal_await.get("body", {}).get("new_object", {}).get("args", [{}])[0].get("conditional", {})
async_not_equal_condition = async_not_equal_conditional.get("condition", {}).get("conditional", {})
async_not_equal_equal = async_not_equal_condition.get("condition", {})
if (
    async_not_equal_await.get("async_future") is not True
    or async_not_equal_await.get("body", {}).get("new_object", {}).get("type_args") != ["String"]
    or async_not_equal_equal.get("op") != "=="
    or async_not_equal_equal.get("left", {}).get("arg") != "marker"
    or async_not_equal_equal.get("right", {}).get("string") != "skip"
    or async_not_equal_condition.get("then", {}).get("bool") is not False
    or async_not_equal_condition.get("else", {}).get("bool") is not True
    or async_not_equal_conditional.get("then", {}).get("await", {}).get("arg") != "ready"
    or async_not_equal_conditional.get("else", {}).get("string") != "patched-not-equal-tail"
):
    raise SystemExit(f"expected asyncNotEqualAwaitTail not-equal source, got {async_not_equal_await}")
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
async_while_local = patch_by_member.get("asyncWhileLocal", {}).get("bytecode_source", {})
async_while_arg = async_while_local.get("body", {}).get("new_object", {}).get("args", [{}])[0]
async_while_outer_let = async_while_arg.get("let", {})
async_while_locals = async_while_outer_let.get("locals", [])
async_while_seq = async_while_outer_let.get("body", {}).get("seq", [])
async_while_loop = async_while_seq[0].get("while_loop", {}) if async_while_seq else {}
async_while_loop_body = async_while_loop.get("body", {}).get("seq", [])
if (
    async_while_local.get("async_future") is not True
    or len(async_while_locals) != 2
    or async_while_locals[0].get("name") != "i"
    or async_while_locals[1].get("name") != "out"
    or async_while_loop.get("condition", {}).get("op") != ">"
    or len(async_while_loop_body) != 2
    or async_while_loop_body[0].get("set_local", {}).get("id") != 1
    or async_while_loop_body[1].get("seq", [{}])[0].get("set_local", {}).get("id") != 0
):
    raise SystemExit(f"expected asyncWhileLocal while_loop + set_local source, got {async_while_local}")
async_while_break = patch_by_member.get("asyncWhileBreak", {}).get("bytecode_source", {})
async_while_break_arg = async_while_break.get("body", {}).get("new_object", {}).get("args", [{}])[0]
async_while_break_outer_let = async_while_break_arg.get("let", {})
async_while_break_locals = async_while_break_outer_let.get("locals", [])
async_while_break_seq = async_while_break_outer_let.get("body", {}).get("seq", [])
async_while_break_loop = async_while_break_seq[0].get("while_loop", {}) if async_while_break_seq else {}
async_while_break_body = async_while_break_loop.get("body", {}).get("seq", [])
async_while_break_before = async_while_break_loop.get("before_break", {}).get("seq", [])
if (
    async_while_break.get("async_future") is not True
    or len(async_while_break_locals) != 2
    or async_while_break_locals[0].get("name") != "i"
    or async_while_break_locals[1].get("name") != "out"
    or not async_while_break_before
    or async_while_break_before[0].get("set_local", {}).get("id") != 1
    or async_while_break_loop.get("break_condition", {}).get("op") != "=="
    or len(async_while_break_body) != 2
    or async_while_break_body[0].get("set_local", {}).get("id") != 0
):
    raise SystemExit(f"expected asyncWhileBreak before_break + break_condition source, got {async_while_break}")
async_while_continue = patch_by_member.get("asyncWhileContinue", {}).get("bytecode_source", {})
async_while_continue_arg = async_while_continue.get("body", {}).get("new_object", {}).get("args", [{}])[0]
async_while_continue_outer_let = async_while_continue_arg.get("let", {})
async_while_continue_locals = async_while_continue_outer_let.get("locals", [])
async_while_continue_seq = async_while_continue_outer_let.get("body", {}).get("seq", [])
async_while_continue_loop = async_while_continue_seq[0].get("while_loop", {}) if async_while_continue_seq else {}
async_while_continue_body = async_while_continue_loop.get("body", {}).get("seq", [])
async_while_continue_before = async_while_continue_loop.get("before_continue", {}).get("seq", [])
async_while_continue_continue_body = async_while_continue_loop.get("continue_body", {}).get("seq", [])
if (
    async_while_continue.get("async_future") is not True
    or len(async_while_continue_locals) != 2
    or async_while_continue_locals[0].get("name") != "i"
    or async_while_continue_locals[1].get("name") != "out"
    or not async_while_continue_before
    or async_while_continue_before[0].get("set_local", {}).get("id") != 1
    or async_while_continue_loop.get("continue_condition", {}).get("op") != "=="
    or not async_while_continue_continue_body
    or async_while_continue_continue_body[0].get("set_local", {}).get("id") != 0
    or len(async_while_continue_body) != 2
    or async_while_continue_body[0].get("set_local", {}).get("id") != 1
):
    raise SystemExit(f"expected asyncWhileContinue before_continue + continue_condition source, got {async_while_continue}")
async_while_continue_break = patch_by_member.get("asyncWhileContinueBreak", {}).get("bytecode_source", {})
async_while_continue_break_arg = async_while_continue_break.get("body", {}).get("new_object", {}).get("args", [{}])[0]
async_while_continue_break_outer_let = async_while_continue_break_arg.get("let", {})
async_while_continue_break_locals = async_while_continue_break_outer_let.get("locals", [])
async_while_continue_break_seq = async_while_continue_break_outer_let.get("body", {}).get("seq", [])
async_while_continue_break_loop = async_while_continue_break_seq[0].get("while_loop", {}) if async_while_continue_break_seq else {}
async_while_continue_break_body = async_while_continue_break_loop.get("body", {}).get("seq", [])
async_while_continue_break_before_continue = async_while_continue_break_loop.get("before_continue", {}).get("seq", [])
async_while_continue_break_continue_body = async_while_continue_break_loop.get("continue_body", {}).get("seq", [])
async_while_continue_break_before_break = async_while_continue_break_loop.get("before_break", {}).get("seq", [])
if (
    async_while_continue_break.get("async_future") is not True
    or len(async_while_continue_break_locals) != 2
    or async_while_continue_break_locals[0].get("name") != "i"
    or async_while_continue_break_locals[1].get("name") != "out"
    or not async_while_continue_break_before_continue
    or async_while_continue_break_before_continue[0].get("set_local", {}).get("id") != 1
    or async_while_continue_break_loop.get("continue_condition", {}).get("op") != "=="
    or not async_while_continue_break_continue_body
    or async_while_continue_break_continue_body[0].get("set_local", {}).get("id") != 0
    or not async_while_continue_break_before_break
    or async_while_continue_break_before_break[0].get("set_local", {}).get("id") != 1
    or async_while_continue_break_loop.get("break_condition", {}).get("op") != "=="
    or len(async_while_continue_break_body) != 2
    or async_while_continue_break_body[0].get("set_local", {}).get("id") != 1
):
    raise SystemExit(f"expected asyncWhileContinueBreak continue+break source, got {async_while_continue_break}")
async_while_await_continue_break = patch_by_member.get("asyncWhileAwaitContinueBreak", {}).get("bytecode_source", {})
async_while_await_continue_break_arg = async_while_await_continue_break.get("body", {}).get("new_object", {}).get("args", [{}])[0]
async_while_await_continue_break_outer_let = async_while_await_continue_break_arg.get("let", {})
async_while_await_continue_break_locals = async_while_await_continue_break_outer_let.get("locals", [])
async_while_await_continue_break_seq = async_while_await_continue_break_outer_let.get("body", {}).get("seq", [])
async_while_await_continue_break_loop = async_while_await_continue_break_seq[0].get("while_loop", {}) if async_while_await_continue_break_seq else {}
async_while_await_continue_break_before_continue = async_while_await_continue_break_loop.get("before_continue", {}).get("seq", [])
async_while_await_continue_break_continue_body = async_while_await_continue_break_loop.get("continue_body", {}).get("seq", [])
async_while_await_continue_break_before_break = async_while_await_continue_break_loop.get("before_break", {}).get("seq", [])
async_while_await_continue_break_body = async_while_await_continue_break_loop.get("body", {}).get("seq", [])
if (
    async_while_await_continue_break.get("async_future") is not True
    or len(async_while_await_continue_break_locals) != 2
    or async_while_await_continue_break_locals[0].get("name") != "i"
    or async_while_await_continue_break_locals[1].get("name") != "out"
    or async_while_await_continue_break_loop.get("continue_condition", {}).get("await", {}).get("arg") != "skip"
    or async_while_await_continue_break_loop.get("break_condition", {}).get("await", {}).get("arg") != "stop"
    or not async_while_await_continue_break_before_continue
    or async_while_await_continue_break_before_continue[0].get("set_local", {}).get("id") != 1
    or not async_while_await_continue_break_continue_body
    or async_while_await_continue_break_continue_body[0].get("set_local", {}).get("id") != 0
    or not async_while_await_continue_break_before_break
    or async_while_await_continue_break_before_break[0].get("set_local", {}).get("id") != 1
    or len(async_while_await_continue_break_body) != 2
    or async_while_await_continue_break_body[0].get("set_local", {}).get("id") != 1
):
    raise SystemExit(f"expected asyncWhileAwaitContinueBreak await guarded continue+break source, got {async_while_await_continue_break}")
async_while_await_condition = patch_by_member.get("asyncWhileAwaitCondition", {}).get("bytecode_source", {})
async_while_await_arg = async_while_await_condition.get("body", {}).get("new_object", {}).get("args", [{}])[0]
async_while_await_let = async_while_await_arg.get("let", {})
async_while_await_locals = async_while_await_let.get("locals", [])
async_while_await_seq = async_while_await_let.get("body", {}).get("seq", [])
async_while_await_loop = async_while_await_seq[0].get("while_loop", {}) if async_while_await_seq else {}
async_while_await_before_break = async_while_await_loop.get("before_break", {}).get("seq", [])
async_while_await_body = async_while_await_loop.get("body", {}).get("seq", [])
if (
    async_while_await_condition.get("async_future") is not True
    or [item.get("name") for item in async_while_await_locals] != ["i", "out"]
    or async_while_await_loop.get("condition", {}).get("await", {}).get("arg") != "keepGoing"
    or not async_while_await_before_break
    or async_while_await_before_break[0].get("set_local", {}).get("id") != 1
    or async_while_await_loop.get("break_condition", {}).get("op") != "=="
    or len(async_while_await_body) != 2
    or async_while_await_body[0].get("set_local", {}).get("id") != 0
):
    raise SystemExit(f"expected asyncWhileAwaitCondition await condition + break source, got {async_while_await_condition}")
async_do_while_local = patch_by_member.get("asyncDoWhileLocal", {}).get("bytecode_source", {})
async_do_while_arg = async_do_while_local.get("body", {}).get("new_object", {}).get("args", [{}])[0]
async_do_while_let = async_do_while_arg.get("let", {})
async_do_while_locals = async_do_while_let.get("locals", [])
async_do_while_outer_seq = async_do_while_let.get("body", {}).get("seq", [])
async_do_while_seq = async_do_while_outer_seq[0].get("seq", []) if async_do_while_outer_seq else []
async_do_while_first = async_do_while_seq[0].get("seq", []) if async_do_while_seq else []
async_do_while_loop = async_do_while_seq[1].get("while_loop", {}) if len(async_do_while_seq) > 1 else {}
async_do_while_loop_body = async_do_while_loop.get("body", {}).get("seq", [])
async_do_while_first_update = async_do_while_first[1].get("seq", []) if len(async_do_while_first) > 1 else []
async_do_while_loop_update = async_do_while_loop_body[1].get("seq", []) if len(async_do_while_loop_body) > 1 else []
if (
    async_do_while_local.get("async_future") is not True
    or [item.get("name") for item in async_do_while_locals] != ["i", "out"]
    or len(async_do_while_seq) != 2
    or len(async_do_while_first) != 2
    or async_do_while_first[0].get("set_local", {}).get("id") != 1
    or async_do_while_first_update[0].get("set_local", {}).get("id") != 0
    or async_do_while_loop.get("condition", {}).get("op") != ">"
    or len(async_do_while_loop_body) != 2
    or async_do_while_loop_body[0].get("set_local", {}).get("id") != 1
    or async_do_while_loop_update[0].get("set_local", {}).get("id") != 0
):
    raise SystemExit(f"expected asyncDoWhileLocal seq + while_loop source, got {async_do_while_local}")
async_do_while_await = patch_by_member.get("asyncDoWhileAwaitCondition", {}).get("bytecode_source", {})
async_do_while_await_arg = async_do_while_await.get("body", {}).get("new_object", {}).get("args", [{}])[0]
async_do_while_await_let = async_do_while_await_arg.get("let", {})
async_do_while_await_locals = async_do_while_await_let.get("locals", [])
async_do_while_await_outer_seq = async_do_while_await_let.get("body", {}).get("seq", [])
async_do_while_await_seq = async_do_while_await_outer_seq[0].get("seq", []) if async_do_while_await_outer_seq else []
async_do_while_await_first = async_do_while_await_seq[0].get("seq", []) if async_do_while_await_seq else []
async_do_while_await_loop = async_do_while_await_seq[1].get("while_loop", {}) if len(async_do_while_await_seq) > 1 else {}
async_do_while_await_loop_body = async_do_while_await_loop.get("body", {}).get("seq", [])
async_do_while_await_first_update = async_do_while_await_first[1].get("seq", []) if len(async_do_while_await_first) > 1 else []
async_do_while_await_loop_update = async_do_while_await_loop_body[1].get("seq", []) if len(async_do_while_await_loop_body) > 1 else []
if (
    async_do_while_await.get("async_future") is not True
    or [item.get("name") for item in async_do_while_await_locals] != ["i", "out"]
    or len(async_do_while_await_seq) != 2
    or async_do_while_await_loop.get("condition", {}).get("await", {}).get("arg") != "keepGoing"
    or async_do_while_await_first[0].get("set_local", {}).get("id") != 1
    or async_do_while_await_first_update[0].get("set_local", {}).get("id") != 0
    or async_do_while_await_loop_body[0].get("set_local", {}).get("id") != 1
    or async_do_while_await_loop_update[0].get("set_local", {}).get("id") != 0
):
    raise SystemExit(f"expected asyncDoWhileAwaitCondition await condition source, got {async_do_while_await}")
async_do_while_branch = patch_by_member.get("asyncDoWhileBranchLocal", {}).get("bytecode_source", {})
async_do_while_branch_arg = async_do_while_branch.get("body", {}).get("new_object", {}).get("args", [{}])[0]
async_do_while_branch_let = async_do_while_branch_arg.get("let", {})
async_do_while_branch_locals = async_do_while_branch_let.get("locals", [])
async_do_while_branch_outer_seq = async_do_while_branch_let.get("body", {}).get("seq", [])
async_do_while_branch_seq = async_do_while_branch_outer_seq[0].get("seq", []) if async_do_while_branch_outer_seq else []
async_do_while_branch_first = async_do_while_branch_seq[0].get("let", {}) if async_do_while_branch_seq else {}
async_do_while_branch_first_tail = async_do_while_branch_first.get("body", {}).get("seq", [])
async_do_while_branch_loop = async_do_while_branch_seq[1].get("while_loop", {}) if len(async_do_while_branch_seq) > 1 else {}
async_do_while_branch_loop_body = async_do_while_branch_loop.get("body", {}).get("let", {})
async_do_while_branch_loop_tail = async_do_while_branch_loop_body.get("body", {}).get("seq", [])
if (
    async_do_while_branch.get("async_future") is not True
    or [item.get("name") for item in async_do_while_branch_locals] != ["i", "out"]
    or len(async_do_while_branch_seq) != 2
    or async_do_while_branch_first.get("locals", [{}])[0].get("name") != "segment"
    or async_do_while_branch_first.get("locals", [{}])[0].get("value", {}).get("conditional", {}).get("condition", {}).get("op") != "=="
    or async_do_while_branch_first_tail[0].get("set_local", {}).get("id") != 1
    or async_do_while_branch_first_tail[0].get("set_local", {}).get("value", {}).get("concat", [{}, {}, {}, {}, {}])[2].get("let_local") != 2
    or async_do_while_branch_first_tail[1].get("seq", [])[0].get("set_local", {}).get("id") != 0
    or async_do_while_branch_loop.get("condition", {}).get("op") != ">"
    or async_do_while_branch_loop_body.get("locals", [{}])[0].get("name") != "segment"
    or async_do_while_branch_loop_tail[0].get("set_local", {}).get("id") != 1
    or async_do_while_branch_loop_tail[1].get("seq", [])[0].get("set_local", {}).get("id") != 0
):
    raise SystemExit(f"expected asyncDoWhileBranchLocal branch local source, got {async_do_while_branch}")
async_do_while_break = patch_by_member.get("asyncDoWhileBreak", {}).get("bytecode_source", {})
async_do_while_break_arg = async_do_while_break.get("body", {}).get("new_object", {}).get("args", [{}])[0]
async_do_while_break_let = async_do_while_break_arg.get("let", {})
async_do_while_break_locals = async_do_while_break_let.get("locals", [])
async_do_while_break_outer_seq = async_do_while_break_let.get("body", {}).get("seq", [])
async_do_while_break_seq = async_do_while_break_outer_seq[0].get("seq", []) if async_do_while_break_outer_seq else []
async_do_while_break_before = async_do_while_break_seq[0].get("seq", []) if async_do_while_break_seq else []
async_do_while_break_cond = async_do_while_break_seq[1].get("conditional", {}) if len(async_do_while_break_seq) > 1 else {}
async_do_while_break_else = async_do_while_break_cond.get("else", {}).get("seq", [])
async_do_while_break_loop = async_do_while_break_else[2].get("while_loop", {}) if len(async_do_while_break_else) > 2 else {}
async_do_while_break_loop_body = async_do_while_break_loop.get("body", {}).get("seq", [])
async_do_while_break_loop_before = async_do_while_break_loop.get("before_break", {}).get("seq", [])
if (
    async_do_while_break.get("async_future") is not True
    or [item.get("name") for item in async_do_while_break_locals] != ["i", "out"]
    or len(async_do_while_break_seq) != 2
    or not async_do_while_break_before
    or async_do_while_break_before[0].get("set_local", {}).get("id") != 1
    or async_do_while_break_cond.get("condition", {}).get("op") != "=="
    or async_do_while_break_cond.get("then", {}).get("null") is not True
    or len(async_do_while_break_else) != 3
    or async_do_while_break_else[0].get("set_local", {}).get("id") != 1
    or async_do_while_break_else[1].get("seq", [])[0].get("set_local", {}).get("id") != 0
    or async_do_while_break_loop.get("condition", {}).get("op") != ">"
    or not async_do_while_break_loop_before
    or async_do_while_break_loop_before[0].get("set_local", {}).get("id") != 1
    or async_do_while_break_loop.get("break_condition", {}).get("op") != "=="
    or len(async_do_while_break_loop_body) != 2
):
    raise SystemExit(f"expected asyncDoWhileBreak guarded do-while source, got {async_do_while_break}")
async_do_while_continue = patch_by_member.get("asyncDoWhileContinue", {}).get("bytecode_source", {})
async_do_while_continue_arg = async_do_while_continue.get("body", {}).get("new_object", {}).get("args", [{}])[0]
async_do_while_continue_let = async_do_while_continue_arg.get("let", {})
async_do_while_continue_locals = async_do_while_continue_let.get("locals", [])
async_do_while_continue_outer_seq = async_do_while_continue_let.get("body", {}).get("seq", [])
async_do_while_continue_seq = async_do_while_continue_outer_seq[0].get("seq", []) if async_do_while_continue_outer_seq else []
async_do_while_continue_before = async_do_while_continue_seq[0].get("seq", []) if async_do_while_continue_seq else []
async_do_while_continue_cond = async_do_while_continue_seq[1].get("conditional", {}) if len(async_do_while_continue_seq) > 1 else {}
async_do_while_continue_then = async_do_while_continue_cond.get("then", {}).get("seq", [])
async_do_while_continue_else = async_do_while_continue_cond.get("else", {}).get("seq", [])
async_do_while_continue_loop = async_do_while_continue_then[2].get("while_loop", {}) if len(async_do_while_continue_then) > 2 else {}
async_do_while_continue_loop_before = async_do_while_continue_loop.get("before_continue", {}).get("seq", [])
async_do_while_continue_loop_continue = async_do_while_continue_loop.get("continue_body", {}).get("seq", [])
async_do_while_continue_loop_body = async_do_while_continue_loop.get("body", {}).get("seq", [])
if (
    async_do_while_continue.get("async_future") is not True
    or [item.get("name") for item in async_do_while_continue_locals] != ["i", "out"]
    or len(async_do_while_continue_seq) != 2
    or not async_do_while_continue_before
    or async_do_while_continue_before[0].get("set_local", {}).get("id") != 1
    or async_do_while_continue_cond.get("condition", {}).get("op") != "=="
    or len(async_do_while_continue_then) != 3
    or async_do_while_continue_then[0].get("set_local", {}).get("id") != 0
    or async_do_while_continue_loop.get("condition", {}).get("op") != ">"
    or not async_do_while_continue_loop_before
    or async_do_while_continue_loop_before[0].get("set_local", {}).get("id") != 1
    or async_do_while_continue_loop.get("continue_condition", {}).get("op") != "=="
    or not async_do_while_continue_loop_continue
    or async_do_while_continue_loop_continue[0].get("set_local", {}).get("id") != 0
    or len(async_do_while_continue_loop_body) != 2
    or async_do_while_continue_loop_body[0].get("set_local", {}).get("id") != 1
    or len(async_do_while_continue_else) != 3
    or async_do_while_continue_else[0].get("set_local", {}).get("id") != 1
    or async_do_while_continue_else[1].get("seq", [])[0].get("set_local", {}).get("id") != 0
):
    raise SystemExit(f"expected asyncDoWhileContinue guarded do-while source, got {async_do_while_continue}")
async_do_while_continue_break = patch_by_member.get("asyncDoWhileContinueBreak", {}).get("bytecode_source", {})
async_do_while_continue_break_arg = async_do_while_continue_break.get("body", {}).get("new_object", {}).get("args", [{}])[0]
async_do_while_continue_break_let = async_do_while_continue_break_arg.get("let", {})
async_do_while_continue_break_locals = async_do_while_continue_break_let.get("locals", [])
async_do_while_continue_break_outer_seq = async_do_while_continue_break_let.get("body", {}).get("seq", [])
async_do_while_continue_break_seq = async_do_while_continue_break_outer_seq[0].get("seq", []) if async_do_while_continue_break_outer_seq else []
async_do_while_continue_break_before = async_do_while_continue_break_seq[0].get("seq", []) if async_do_while_continue_break_seq else []
async_do_while_continue_break_cond = async_do_while_continue_break_seq[1].get("conditional", {}) if len(async_do_while_continue_break_seq) > 1 else {}
async_do_while_continue_break_then = async_do_while_continue_break_cond.get("then", {}).get("seq", [])
async_do_while_continue_break_else = async_do_while_continue_break_cond.get("else", {}).get("seq", [])
async_do_while_continue_break_else_cond = async_do_while_continue_break_else[1].get("conditional", {}) if len(async_do_while_continue_break_else) > 1 else {}
async_do_while_continue_break_after_break = async_do_while_continue_break_else_cond.get("else", {}).get("seq", [])
async_do_while_continue_break_loop = async_do_while_continue_break_after_break[2].get("while_loop", {}) if len(async_do_while_continue_break_after_break) > 2 else {}
async_do_while_continue_break_loop_before_continue = async_do_while_continue_break_loop.get("before_continue", {}).get("seq", [])
async_do_while_continue_break_loop_continue = async_do_while_continue_break_loop.get("continue_body", {}).get("seq", [])
async_do_while_continue_break_loop_before_break = async_do_while_continue_break_loop.get("before_break", {}).get("seq", [])
async_do_while_continue_break_loop_body = async_do_while_continue_break_loop.get("body", {}).get("seq", [])
if (
    async_do_while_continue_break.get("async_future") is not True
    or [item.get("name") for item in async_do_while_continue_break_locals] != ["i", "out"]
    or len(async_do_while_continue_break_seq) != 2
    or not async_do_while_continue_break_before
    or async_do_while_continue_break_before[0].get("set_local", {}).get("id") != 1
    or async_do_while_continue_break_cond.get("condition", {}).get("op") != "=="
    or len(async_do_while_continue_break_then) != 3
    or async_do_while_continue_break_then[0].get("set_local", {}).get("id") != 0
    or len(async_do_while_continue_break_else) != 2
    or async_do_while_continue_break_else[0].get("seq", [])[0].get("set_local", {}).get("id") != 1
    or async_do_while_continue_break_else_cond.get("condition", {}).get("op") != "=="
    or async_do_while_continue_break_else_cond.get("then", {}).get("null") is not True
    or len(async_do_while_continue_break_after_break) != 3
    or async_do_while_continue_break_after_break[0].get("set_local", {}).get("id") != 1
    or async_do_while_continue_break_after_break[1].get("seq", [])[0].get("set_local", {}).get("id") != 0
    or async_do_while_continue_break_loop.get("condition", {}).get("op") != ">"
    or not async_do_while_continue_break_loop_before_continue
    or async_do_while_continue_break_loop_before_continue[0].get("set_local", {}).get("id") != 1
    or async_do_while_continue_break_loop.get("continue_condition", {}).get("op") != "=="
    or not async_do_while_continue_break_loop_continue
    or async_do_while_continue_break_loop_continue[0].get("set_local", {}).get("id") != 0
    or not async_do_while_continue_break_loop_before_break
    or async_do_while_continue_break_loop_before_break[0].get("set_local", {}).get("id") != 1
    or async_do_while_continue_break_loop.get("break_condition", {}).get("op") != "=="
    or len(async_do_while_continue_break_loop_body) != 2
    or async_do_while_continue_break_loop_body[0].get("set_local", {}).get("id") != 1
):
    raise SystemExit(f"expected asyncDoWhileContinueBreak guarded do-while source, got {async_do_while_continue_break}")
async_do_while_await_guard_continue_break = patch_by_member.get("asyncDoWhileAwaitGuardContinueBreak", {}).get("bytecode_source", {})
async_do_while_await_guard_continue_break_arg = async_do_while_await_guard_continue_break.get("body", {}).get("new_object", {}).get("args", [{}])[0]
async_do_while_await_guard_continue_break_let = async_do_while_await_guard_continue_break_arg.get("let", {})
async_do_while_await_guard_continue_break_locals = async_do_while_await_guard_continue_break_let.get("locals", [])
async_do_while_await_guard_continue_break_outer_seq = async_do_while_await_guard_continue_break_let.get("body", {}).get("seq", [])
async_do_while_await_guard_continue_break_seq = async_do_while_await_guard_continue_break_outer_seq[0].get("seq", []) if async_do_while_await_guard_continue_break_outer_seq else []
async_do_while_await_guard_continue_break_cond = async_do_while_await_guard_continue_break_seq[1].get("conditional", {}) if len(async_do_while_await_guard_continue_break_seq) > 1 else {}
async_do_while_await_guard_continue_break_then = async_do_while_await_guard_continue_break_cond.get("then", {}).get("seq", [])
async_do_while_await_guard_continue_break_else = async_do_while_await_guard_continue_break_cond.get("else", {}).get("seq", [])
async_do_while_await_guard_continue_break_else_cond = async_do_while_await_guard_continue_break_else[1].get("conditional", {}) if len(async_do_while_await_guard_continue_break_else) > 1 else {}
async_do_while_await_guard_continue_break_after_break = async_do_while_await_guard_continue_break_else_cond.get("else", {}).get("seq", [])
async_do_while_await_guard_continue_break_loop = async_do_while_await_guard_continue_break_after_break[2].get("while_loop", {}) if len(async_do_while_await_guard_continue_break_after_break) > 2 else {}
if (
    async_do_while_await_guard_continue_break.get("async_future") is not True
    or [item.get("name") for item in async_do_while_await_guard_continue_break_locals] != ["i", "out"]
    or async_do_while_await_guard_continue_break_cond.get("condition", {}).get("await", {}).get("arg") != "skip"
    or async_do_while_await_guard_continue_break_then[0].get("set_local", {}).get("id") != 0
    or async_do_while_await_guard_continue_break_else_cond.get("condition", {}).get("await", {}).get("arg") != "stop"
    or async_do_while_await_guard_continue_break_else_cond.get("then", {}).get("null") is not True
    or async_do_while_await_guard_continue_break_loop.get("condition", {}).get("op") != ">"
    or async_do_while_await_guard_continue_break_loop.get("continue_condition", {}).get("await", {}).get("arg") != "skip"
    or async_do_while_await_guard_continue_break_loop.get("break_condition", {}).get("await", {}).get("arg") != "stop"
    or async_do_while_await_guard_continue_break_loop.get("continue_body", {}).get("seq", [{}])[0].get("set_local", {}).get("id") != 0
    or async_do_while_await_guard_continue_break_loop.get("before_break", {}).get("seq", [{}])[0].get("set_local", {}).get("id") != 1
    or async_do_while_await_guard_continue_break_loop.get("body", {}).get("seq", [{}])[0].get("set_local", {}).get("id") != 1
):
    raise SystemExit(f"expected asyncDoWhileAwaitGuardContinueBreak await guarded do-while source, got {async_do_while_await_guard_continue_break}")
async_do_while_await_guard_continue_break_await_condition = patch_by_member.get("asyncDoWhileAwaitGuardContinueBreakAwaitCondition", {}).get("bytecode_source", {})
async_do_while_await_guard_continue_break_await_condition_arg = async_do_while_await_guard_continue_break_await_condition.get("body", {}).get("new_object", {}).get("args", [{}])[0]
async_do_while_await_guard_continue_break_await_condition_let = async_do_while_await_guard_continue_break_await_condition_arg.get("let", {})
async_do_while_await_guard_continue_break_await_condition_locals = async_do_while_await_guard_continue_break_await_condition_let.get("locals", [])
async_do_while_await_guard_continue_break_await_condition_outer_seq = async_do_while_await_guard_continue_break_await_condition_let.get("body", {}).get("seq", [])
async_do_while_await_guard_continue_break_await_condition_seq = async_do_while_await_guard_continue_break_await_condition_outer_seq[0].get("seq", []) if async_do_while_await_guard_continue_break_await_condition_outer_seq else []
async_do_while_await_guard_continue_break_await_condition_cond = async_do_while_await_guard_continue_break_await_condition_seq[1].get("conditional", {}) if len(async_do_while_await_guard_continue_break_await_condition_seq) > 1 else {}
async_do_while_await_guard_continue_break_await_condition_then = async_do_while_await_guard_continue_break_await_condition_cond.get("then", {}).get("seq", [])
async_do_while_await_guard_continue_break_await_condition_else = async_do_while_await_guard_continue_break_await_condition_cond.get("else", {}).get("seq", [])
async_do_while_await_guard_continue_break_await_condition_else_cond = async_do_while_await_guard_continue_break_await_condition_else[1].get("conditional", {}) if len(async_do_while_await_guard_continue_break_await_condition_else) > 1 else {}
async_do_while_await_guard_continue_break_await_condition_after_break = async_do_while_await_guard_continue_break_await_condition_else_cond.get("else", {}).get("seq", [])
async_do_while_await_guard_continue_break_await_condition_loop = async_do_while_await_guard_continue_break_await_condition_after_break[2].get("while_loop", {}) if len(async_do_while_await_guard_continue_break_await_condition_after_break) > 2 else {}
if (
    async_do_while_await_guard_continue_break_await_condition.get("async_future") is not True
    or [item.get("name") for item in async_do_while_await_guard_continue_break_await_condition_locals] != ["i", "out"]
    or async_do_while_await_guard_continue_break_await_condition_cond.get("condition", {}).get("await", {}).get("arg") != "skip"
    or async_do_while_await_guard_continue_break_await_condition_then[0].get("set_local", {}).get("id") != 0
    or async_do_while_await_guard_continue_break_await_condition_else_cond.get("condition", {}).get("await", {}).get("arg") != "stop"
    or async_do_while_await_guard_continue_break_await_condition_else_cond.get("then", {}).get("null") is not True
    or async_do_while_await_guard_continue_break_await_condition_loop.get("condition", {}).get("await", {}).get("arg") != "keepGoing"
    or async_do_while_await_guard_continue_break_await_condition_loop.get("continue_condition", {}).get("await", {}).get("arg") != "skip"
    or async_do_while_await_guard_continue_break_await_condition_loop.get("break_condition", {}).get("await", {}).get("arg") != "stop"
    or async_do_while_await_guard_continue_break_await_condition_loop.get("continue_body", {}).get("seq", [{}])[0].get("set_local", {}).get("id") != 0
    or async_do_while_await_guard_continue_break_await_condition_loop.get("before_break", {}).get("seq", [{}])[0].get("set_local", {}).get("id") != 1
    or async_do_while_await_guard_continue_break_await_condition_loop.get("body", {}).get("seq", [{}])[0].get("set_local", {}).get("id") != 1
):
    raise SystemExit(f"expected asyncDoWhileAwaitGuardContinueBreakAwaitCondition await guarded do-while source, got {async_do_while_await_guard_continue_break_await_condition}")
async_for_local = patch_by_member.get("asyncForLocal", {}).get("bytecode_source", {})
async_for_arg = async_for_local.get("body", {}).get("new_object", {}).get("args", [{}])[0]
async_for_outer_let = async_for_arg.get("let", {})
async_for_outer_seq = async_for_outer_let.get("body", {}).get("seq", [])
async_for_inner_let = async_for_outer_seq[0].get("let", {}) if async_for_outer_seq else {}
async_for_loop = async_for_inner_let.get("body", {}).get("while_loop", {})
async_for_loop_body = async_for_loop.get("body", {}).get("seq", [])
if (
    async_for_local.get("async_future") is not True
    or async_for_outer_let.get("locals", [{}])[0].get("name") != "out"
    or async_for_inner_let.get("locals", [{}])[0].get("name") != "i"
    or async_for_loop.get("condition", {}).get("op") != ">"
    or len(async_for_loop_body) != 3
    or async_for_loop_body[0].get("set_local", {}).get("id") != 0
    or async_for_loop_body[2].get("set_local", {}).get("id") != 1
):
    raise SystemExit(f"expected asyncForLocal for->while_loop + update source, got {async_for_local}")
async_for_continue = patch_by_member.get("asyncForContinue", {}).get("bytecode_source", {})
async_for_continue_arg = async_for_continue.get("body", {}).get("new_object", {}).get("args", [{}])[0]
async_for_continue_outer_let = async_for_continue_arg.get("let", {})
async_for_continue_outer_seq = async_for_continue_outer_let.get("body", {}).get("seq", [])
async_for_continue_inner_let = async_for_continue_outer_seq[0].get("let", {}) if async_for_continue_outer_seq else {}
async_for_continue_loop = async_for_continue_inner_let.get("body", {}).get("while_loop", {})
async_for_continue_body = async_for_continue_loop.get("body", {}).get("seq", [])
async_for_continue_before = async_for_continue_loop.get("before_continue", {}).get("seq", [])
async_for_continue_continue_body = async_for_continue_loop.get("continue_body", {}).get("seq", [])
if (
    async_for_continue.get("async_future") is not True
    or async_for_continue_outer_let.get("locals", [{}])[0].get("name") != "out"
    or async_for_continue_inner_let.get("locals", [{}])[0].get("name") != "i"
    or async_for_continue_loop.get("condition", {}).get("op") != ">"
    or not async_for_continue_before
    or async_for_continue_before[0].get("set_local", {}).get("id") != 0
    or async_for_continue_loop.get("continue_condition", {}).get("op") != "=="
    or len(async_for_continue_continue_body) != 2
    or async_for_continue_continue_body[1].get("set_local", {}).get("id") != 1
    or len(async_for_continue_body) != 3
    or async_for_continue_body[0].get("set_local", {}).get("id") != 0
    or async_for_continue_body[2].get("set_local", {}).get("id") != 1
):
    raise SystemExit(f"expected asyncForContinue guarded continue + update source, got {async_for_continue}")
async_for_break = patch_by_member.get("asyncForBreak", {}).get("bytecode_source", {})
async_for_break_arg = async_for_break.get("body", {}).get("new_object", {}).get("args", [{}])[0]
async_for_break_outer_let = async_for_break_arg.get("let", {})
async_for_break_outer_seq = async_for_break_outer_let.get("body", {}).get("seq", [])
async_for_break_inner_let = async_for_break_outer_seq[0].get("let", {}) if async_for_break_outer_seq else {}
async_for_break_loop = async_for_break_inner_let.get("body", {}).get("while_loop", {})
async_for_break_body = async_for_break_loop.get("body", {}).get("seq", [])
async_for_break_before = async_for_break_loop.get("before_break", {}).get("seq", [])
if (
    async_for_break.get("async_future") is not True
    or async_for_break_outer_let.get("locals", [{}])[0].get("name") != "out"
    or async_for_break_inner_let.get("locals", [{}])[0].get("name") != "i"
    or async_for_break_loop.get("condition", {}).get("op") != ">"
    or not async_for_break_before
    or async_for_break_before[0].get("set_local", {}).get("id") != 0
    or async_for_break_loop.get("break_condition", {}).get("op") != "=="
    or len(async_for_break_body) != 3
    or async_for_break_body[0].get("set_local", {}).get("id") != 0
    or async_for_break_body[2].get("set_local", {}).get("id") != 1
):
    raise SystemExit(f"expected asyncForBreak guarded break + update source, got {async_for_break}")
async_for_continue_break = patch_by_member.get("asyncForContinueBreak", {}).get("bytecode_source", {})
async_for_continue_break_arg = async_for_continue_break.get("body", {}).get("new_object", {}).get("args", [{}])[0]
async_for_continue_break_outer_let = async_for_continue_break_arg.get("let", {})
async_for_continue_break_outer_seq = async_for_continue_break_outer_let.get("body", {}).get("seq", [])
async_for_continue_break_inner_let = async_for_continue_break_outer_seq[0].get("let", {}) if async_for_continue_break_outer_seq else {}
async_for_continue_break_loop = async_for_continue_break_inner_let.get("body", {}).get("while_loop", {})
async_for_continue_break_body = async_for_continue_break_loop.get("body", {}).get("seq", [])
async_for_continue_break_before_continue = async_for_continue_break_loop.get("before_continue", {}).get("seq", [])
async_for_continue_break_continue_body = async_for_continue_break_loop.get("continue_body", {}).get("seq", [])
async_for_continue_break_before_break = async_for_continue_break_loop.get("before_break", {}).get("seq", [])
if (
    async_for_continue_break.get("async_future") is not True
    or async_for_continue_break_outer_let.get("locals", [{}])[0].get("name") != "out"
    or async_for_continue_break_inner_let.get("locals", [{}])[0].get("name") != "i"
    or async_for_continue_break_loop.get("condition", {}).get("op") != ">"
    or not async_for_continue_break_before_continue
    or async_for_continue_break_before_continue[0].get("set_local", {}).get("id") != 0
    or async_for_continue_break_loop.get("continue_condition", {}).get("op") != "=="
    or len(async_for_continue_break_continue_body) != 2
    or async_for_continue_break_continue_body[1].get("set_local", {}).get("id") != 1
    or not async_for_continue_break_before_break
    or async_for_continue_break_before_break[0].get("set_local", {}).get("id") != 0
    or async_for_continue_break_loop.get("break_condition", {}).get("op") != "=="
    or len(async_for_continue_break_body) != 3
    or async_for_continue_break_body[0].get("set_local", {}).get("id") != 0
    or async_for_continue_break_body[2].get("set_local", {}).get("id") != 1
):
    raise SystemExit(f"expected asyncForContinueBreak guarded continue+break + update source, got {async_for_continue_break}")
async_for_await_guard_continue_break = patch_by_member.get("asyncForAwaitGuardContinueBreak", {}).get("bytecode_source", {})
async_for_await_guard_continue_break_arg = async_for_await_guard_continue_break.get("body", {}).get("new_object", {}).get("args", [{}])[0]
async_for_await_guard_continue_break_outer_let = async_for_await_guard_continue_break_arg.get("let", {})
async_for_await_guard_continue_break_outer_seq = async_for_await_guard_continue_break_outer_let.get("body", {}).get("seq", [])
async_for_await_guard_continue_break_inner_let = async_for_await_guard_continue_break_outer_seq[0].get("let", {}) if async_for_await_guard_continue_break_outer_seq else {}
async_for_await_guard_continue_break_loop = async_for_await_guard_continue_break_inner_let.get("body", {}).get("while_loop", {})
async_for_await_guard_continue_break_before_continue = async_for_await_guard_continue_break_loop.get("before_continue", {}).get("seq", [])
async_for_await_guard_continue_break_continue_body = async_for_await_guard_continue_break_loop.get("continue_body", {}).get("seq", [])
async_for_await_guard_continue_break_before_break = async_for_await_guard_continue_break_loop.get("before_break", {}).get("seq", [])
async_for_await_guard_continue_break_body = async_for_await_guard_continue_break_loop.get("body", {}).get("seq", [])
if (
    async_for_await_guard_continue_break.get("async_future") is not True
    or async_for_await_guard_continue_break_outer_let.get("locals", [{}])[0].get("name") != "out"
    or async_for_await_guard_continue_break_inner_let.get("locals", [{}])[0].get("name") != "i"
    or async_for_await_guard_continue_break_loop.get("condition", {}).get("op") != ">"
    or async_for_await_guard_continue_break_loop.get("continue_condition", {}).get("await", {}).get("arg") != "skip"
    or async_for_await_guard_continue_break_loop.get("break_condition", {}).get("await", {}).get("arg") != "stop"
    or not async_for_await_guard_continue_break_before_continue
    or async_for_await_guard_continue_break_before_continue[0].get("set_local", {}).get("id") != 0
    or len(async_for_await_guard_continue_break_continue_body) != 2
    or async_for_await_guard_continue_break_continue_body[1].get("set_local", {}).get("id") != 1
    or not async_for_await_guard_continue_break_before_break
    or async_for_await_guard_continue_break_before_break[0].get("set_local", {}).get("id") != 0
    or len(async_for_await_guard_continue_break_body) != 3
    or async_for_await_guard_continue_break_body[0].get("set_local", {}).get("id") != 0
    or async_for_await_guard_continue_break_body[2].get("set_local", {}).get("id") != 1
):
    raise SystemExit(f"expected asyncForAwaitGuardContinueBreak await guarded continue+break + update source, got {async_for_await_guard_continue_break}")
async_for_await_guard_continue_break_await_update = patch_by_member.get("asyncForAwaitGuardContinueBreakAwaitUpdate", {}).get("bytecode_source", {})
async_for_await_guard_continue_break_await_update_arg = async_for_await_guard_continue_break_await_update.get("body", {}).get("new_object", {}).get("args", [{}])[0]
async_for_await_guard_continue_break_await_update_outer_let = async_for_await_guard_continue_break_await_update_arg.get("let", {})
async_for_await_guard_continue_break_await_update_outer_seq = async_for_await_guard_continue_break_await_update_outer_let.get("body", {}).get("seq", [])
async_for_await_guard_continue_break_await_update_inner_let = async_for_await_guard_continue_break_await_update_outer_seq[0].get("let", {}) if async_for_await_guard_continue_break_await_update_outer_seq else {}
async_for_await_guard_continue_break_await_update_loop = async_for_await_guard_continue_break_await_update_inner_let.get("body", {}).get("while_loop", {})
async_for_await_guard_continue_break_await_update_continue_body = async_for_await_guard_continue_break_await_update_loop.get("continue_body", {}).get("seq", [])
async_for_await_guard_continue_break_await_update_body = async_for_await_guard_continue_break_await_update_loop.get("body", {}).get("seq", [])
if (
    async_for_await_guard_continue_break_await_update.get("async_future") is not True
    or async_for_await_guard_continue_break_await_update_outer_let.get("locals", [{}])[0].get("name") != "out"
    or async_for_await_guard_continue_break_await_update_inner_let.get("locals", [{}])[0].get("name") != "i"
    or async_for_await_guard_continue_break_await_update_loop.get("condition", {}).get("op") != ">"
    or async_for_await_guard_continue_break_await_update_loop.get("continue_condition", {}).get("await", {}).get("arg") != "skip"
    or async_for_await_guard_continue_break_await_update_loop.get("break_condition", {}).get("await", {}).get("arg") != "stop"
    or len(async_for_await_guard_continue_break_await_update_continue_body) != 2
    or async_for_await_guard_continue_break_await_update_continue_body[1].get("set_local", {}).get("value", {}).get("await", {}).get("arg") != "next"
    or len(async_for_await_guard_continue_break_await_update_body) != 3
    or async_for_await_guard_continue_break_await_update_body[2].get("set_local", {}).get("value", {}).get("await", {}).get("arg") != "next"
):
    raise SystemExit(f"expected asyncForAwaitGuardContinueBreakAwaitUpdate await guarded continue+break + await update source, got {async_for_await_guard_continue_break_await_update}")
async_for_await_update = patch_by_member.get("asyncForAwaitUpdate", {}).get("bytecode_source", {})
async_for_await_update_arg = async_for_await_update.get("body", {}).get("new_object", {}).get("args", [{}])[0]
async_for_await_update_outer_let = async_for_await_update_arg.get("let", {})
async_for_await_update_outer_seq = async_for_await_update_outer_let.get("body", {}).get("seq", [])
async_for_await_update_inner_let = async_for_await_update_outer_seq[0].get("let", {}) if async_for_await_update_outer_seq else {}
async_for_await_update_loop = async_for_await_update_inner_let.get("body", {}).get("while_loop", {})
async_for_await_update_body = async_for_await_update_loop.get("body", {}).get("seq", [])
if (
    async_for_await_update.get("async_future") is not True
    or async_for_await_update_outer_let.get("locals", [{}])[0].get("name") != "out"
    or async_for_await_update_inner_let.get("locals", [{}])[0].get("name") != "i"
    or async_for_await_update_loop.get("condition", {}).get("op") != ">"
    or len(async_for_await_update_body) != 3
    or async_for_await_update_body[0].get("set_local", {}).get("id") != 0
    or async_for_await_update_body[2].get("set_local", {}).get("id") != 1
    or async_for_await_update_body[2].get("set_local", {}).get("value", {}).get("await", {}).get("arg") != "next"
):
    raise SystemExit(f"expected asyncForAwaitUpdate for update await source, got {async_for_await_update}")
async_for_await_update_branch = patch_by_member.get("asyncForAwaitUpdateBranchLocal", {}).get("bytecode_source", {})
async_for_await_update_branch_arg = async_for_await_update_branch.get("body", {}).get("new_object", {}).get("args", [{}])[0]
async_for_await_update_branch_outer_let = async_for_await_update_branch_arg.get("let", {})
async_for_await_update_branch_outer_seq = async_for_await_update_branch_outer_let.get("body", {}).get("seq", [])
async_for_await_update_branch_inner_let = async_for_await_update_branch_outer_seq[0].get("let", {}) if async_for_await_update_branch_outer_seq else {}
async_for_await_update_branch_loop = async_for_await_update_branch_inner_let.get("body", {}).get("while_loop", {})
async_for_await_update_branch_body = async_for_await_update_branch_loop.get("body", {}).get("seq", [])
async_for_await_update_branch_segment = async_for_await_update_branch_body[0].get("let", {}) if async_for_await_update_branch_body else {}
async_for_await_update_branch_segment_tail = async_for_await_update_branch_segment.get("body", {}).get("seq", [])
async_for_await_update_branch_update = async_for_await_update_branch_body[1].get("set_local", {}) if len(async_for_await_update_branch_body) > 1 else {}
if (
    async_for_await_update_branch.get("async_future") is not True
    or async_for_await_update_branch_outer_let.get("locals", [{}])[0].get("name") != "out"
    or async_for_await_update_branch_inner_let.get("locals", [{}])[0].get("name") != "i"
    or async_for_await_update_branch_loop.get("condition", {}).get("op") != ">"
    or len(async_for_await_update_branch_body) != 2
    or async_for_await_update_branch_segment.get("locals", [{}])[0].get("name") != "segment"
    or async_for_await_update_branch_segment.get("locals", [{}])[0].get("value", {}).get("conditional", {}).get("condition", {}).get("op") != "=="
    or async_for_await_update_branch_segment_tail[0].get("set_local", {}).get("id") != 0
    or async_for_await_update_branch_segment_tail[0].get("set_local", {}).get("value", {}).get("concat", [{}, {}, {}, {}, {}])[2].get("let_local") != 2
    or async_for_await_update_branch_update.get("id") != 1
    or async_for_await_update_branch_update.get("value", {}).get("await", {}).get("arg") != "next"
):
    raise SystemExit(f"expected asyncForAwaitUpdateBranchLocal branch local + await update source, got {async_for_await_update_branch}")

async_while_nested_branch = patch_by_member.get("asyncWhileNestedAwaitBranchLocal", {}).get("bytecode_source", {})
async_while_nested_branch_arg = async_while_nested_branch.get("body", {}).get("new_object", {}).get("args", [{}])[0]
async_while_nested_branch_let = async_while_nested_branch_arg.get("let", {})
async_while_nested_branch_seq = async_while_nested_branch_let.get("body", {}).get("seq", [])
async_while_nested_branch_loop = async_while_nested_branch_seq[0].get("while_loop", {}) if async_while_nested_branch_seq else {}
async_while_nested_branch_body = async_while_nested_branch_loop.get("body", {}).get("conditional", {})
async_while_nested_branch_then = async_while_nested_branch_body.get("then", {}).get("let", {})
async_while_nested_branch_nested = async_while_nested_branch_then.get("body", {}).get("conditional", {})
async_while_nested_branch_nested_then = async_while_nested_branch_nested.get("then", {}).get("let", {})
async_while_nested_branch_else = async_while_nested_branch_body.get("else", {}).get("let", {})
if (
    async_while_nested_branch.get("async_future") is not True
    or async_while_nested_branch.get("body", {}).get("new_object", {}).get("type_args") != ["String"]
    or [item.get("name") for item in async_while_nested_branch_let.get("locals", [])] != ["i", "out"]
    or async_while_nested_branch_loop.get("condition", {}).get("op") != ">"
    or async_while_nested_branch_body.get("condition", {}).get("op") != "=="
    or async_while_nested_branch_then.get("locals", [{}])[0].get("name") != "state"
    or async_while_nested_branch_then.get("locals", [{}])[0].get("value", {}).get("await", {}).get("arg") != "ready"
    or async_while_nested_branch_nested.get("condition", {}).get("arg") != "premium"
    or async_while_nested_branch_nested_then.get("locals", [{}])[0].get("name") != "tier"
    or async_while_nested_branch_nested_then.get("locals", [{}])[0].get("value", {}).get("string") != "patched-while-nested-pro"
    or async_while_nested_branch_else.get("locals", [{}])[0].get("name") != "state"
    or async_while_nested_branch_else.get("locals", [{}])[0].get("value", {}).get("string") != "patched-while-nested-tail"
    or async_while_nested_branch_seq[1].get("let_local") != 1
):
    raise SystemExit(f"expected asyncWhileNestedAwaitBranchLocal nested branch local while source, got {async_while_nested_branch}")
async_for_nested_branch = patch_by_member.get("asyncForNestedAwaitBranchLocal", {}).get("bytecode_source", {})
async_for_nested_branch_arg = async_for_nested_branch.get("body", {}).get("new_object", {}).get("args", [{}])[0]
async_for_nested_branch_outer_let = async_for_nested_branch_arg.get("let", {})
async_for_nested_branch_outer_seq = async_for_nested_branch_outer_let.get("body", {}).get("seq", [])
async_for_nested_branch_inner_let = async_for_nested_branch_outer_seq[0].get("let", {}) if async_for_nested_branch_outer_seq else {}
async_for_nested_branch_loop = async_for_nested_branch_inner_let.get("body", {}).get("while_loop", {})
async_for_nested_branch_body_seq = async_for_nested_branch_loop.get("body", {}).get("seq", [])
async_for_nested_branch_body = async_for_nested_branch_body_seq[0].get("conditional", {}) if async_for_nested_branch_body_seq else {}
async_for_nested_branch_update = async_for_nested_branch_body_seq[1].get("set_local", {}) if len(async_for_nested_branch_body_seq) > 1 else {}
async_for_nested_branch_then = async_for_nested_branch_body.get("then", {}).get("let", {})
async_for_nested_branch_nested = async_for_nested_branch_then.get("body", {}).get("conditional", {})
async_for_nested_branch_nested_then = async_for_nested_branch_nested.get("then", {}).get("let", {})
async_for_nested_branch_else = async_for_nested_branch_body.get("else", {}).get("let", {})
if (
    async_for_nested_branch.get("async_future") is not True
    or async_for_nested_branch.get("body", {}).get("new_object", {}).get("type_args") != ["String"]
    or async_for_nested_branch_outer_let.get("locals", [{}])[0].get("name") != "out"
    or async_for_nested_branch_inner_let.get("locals", [{}])[0].get("name") != "i"
    or async_for_nested_branch_loop.get("condition", {}).get("op") != ">"
    or async_for_nested_branch_body.get("condition", {}).get("op") != "=="
    or async_for_nested_branch_then.get("locals", [{}])[0].get("name") != "state"
    or async_for_nested_branch_then.get("locals", [{}])[0].get("value", {}).get("await", {}).get("arg") != "ready"
    or async_for_nested_branch_nested.get("condition", {}).get("arg") != "premium"
    or async_for_nested_branch_nested_then.get("locals", [{}])[0].get("name") != "tier"
    or async_for_nested_branch_nested_then.get("locals", [{}])[0].get("value", {}).get("string") != "patched-for-nested-pro"
    or async_for_nested_branch_else.get("locals", [{}])[0].get("name") != "state"
    or async_for_nested_branch_else.get("locals", [{}])[0].get("value", {}).get("string") != "patched-for-nested-tail"
    or async_for_nested_branch_update.get("id") != 1
    or async_for_nested_branch_outer_seq[1].get("let_local") != 0
):
    raise SystemExit(f"expected asyncForNestedAwaitBranchLocal nested branch local for source, got {async_for_nested_branch}")
async_for_await_update_nested_branch = patch_by_member.get("asyncForAwaitUpdateNestedBranchLocal", {}).get("bytecode_source", {})
async_for_await_update_nested_branch_arg = async_for_await_update_nested_branch.get("body", {}).get("new_object", {}).get("args", [{}])[0]
async_for_await_update_nested_branch_outer_let = async_for_await_update_nested_branch_arg.get("let", {})
async_for_await_update_nested_branch_outer_seq = async_for_await_update_nested_branch_outer_let.get("body", {}).get("seq", [])
async_for_await_update_nested_branch_inner_let = async_for_await_update_nested_branch_outer_seq[0].get("let", {}) if async_for_await_update_nested_branch_outer_seq else {}
async_for_await_update_nested_branch_loop = async_for_await_update_nested_branch_inner_let.get("body", {}).get("while_loop", {})
async_for_await_update_nested_branch_body_seq = async_for_await_update_nested_branch_loop.get("body", {}).get("seq", [])
async_for_await_update_nested_branch_body = async_for_await_update_nested_branch_body_seq[0].get("conditional", {}) if async_for_await_update_nested_branch_body_seq else {}
async_for_await_update_nested_branch_update = async_for_await_update_nested_branch_body_seq[1].get("set_local", {}) if len(async_for_await_update_nested_branch_body_seq) > 1 else {}
async_for_await_update_nested_branch_then = async_for_await_update_nested_branch_body.get("then", {}).get("let", {})
async_for_await_update_nested_branch_nested = async_for_await_update_nested_branch_then.get("body", {}).get("conditional", {})
async_for_await_update_nested_branch_nested_then = async_for_await_update_nested_branch_nested.get("then", {}).get("let", {})
async_for_await_update_nested_branch_else = async_for_await_update_nested_branch_body.get("else", {}).get("let", {})
if (
    async_for_await_update_nested_branch.get("async_future") is not True
    or async_for_await_update_nested_branch.get("body", {}).get("new_object", {}).get("type_args") != ["String"]
    or async_for_await_update_nested_branch_outer_let.get("locals", [{}])[0].get("name") != "out"
    or async_for_await_update_nested_branch_inner_let.get("locals", [{}])[0].get("name") != "i"
    or async_for_await_update_nested_branch_loop.get("condition", {}).get("op") != ">"
    or async_for_await_update_nested_branch_body.get("condition", {}).get("op") != "=="
    or async_for_await_update_nested_branch_then.get("locals", [{}])[0].get("name") != "state"
    or async_for_await_update_nested_branch_then.get("locals", [{}])[0].get("value", {}).get("await", {}).get("arg") != "ready"
    or async_for_await_update_nested_branch_nested.get("condition", {}).get("arg") != "premium"
    or async_for_await_update_nested_branch_nested_then.get("locals", [{}])[0].get("name") != "tier"
    or async_for_await_update_nested_branch_nested_then.get("locals", [{}])[0].get("value", {}).get("string") != "patched-for-await-update-nested-pro"
    or async_for_await_update_nested_branch_else.get("locals", [{}])[0].get("name") != "state"
    or async_for_await_update_nested_branch_else.get("locals", [{}])[0].get("value", {}).get("string") != "patched-for-await-update-nested-tail"
    or async_for_await_update_nested_branch_update.get("id") != 1
    or async_for_await_update_nested_branch_update.get("value", {}).get("await", {}).get("arg") != "next"
    or async_for_await_update_nested_branch_outer_seq[1].get("let_local") != 0
):
    raise SystemExit(f"expected asyncForAwaitUpdateNestedBranchLocal nested branch local + await update source, got {async_for_await_update_nested_branch}")
async_for_multi_update = patch_by_member.get("asyncForMultiUpdate", {}).get("bytecode_source", {})
async_for_multi_update_arg = async_for_multi_update.get("body", {}).get("new_object", {}).get("args", [{}])[0]
async_for_multi_update_outer_let = async_for_multi_update_arg.get("let", {})
async_for_multi_update_outer_seq = async_for_multi_update_outer_let.get("body", {}).get("seq", [])
async_for_multi_update_inner_let = async_for_multi_update_outer_seq[0].get("let", {}) if async_for_multi_update_outer_seq else {}
async_for_multi_update_locals = async_for_multi_update_inner_let.get("locals", [])
async_for_multi_update_loop = async_for_multi_update_inner_let.get("body", {}).get("while_loop", {})
async_for_multi_update_body = async_for_multi_update_loop.get("body", {}).get("seq", [])
if (
    async_for_multi_update.get("async_future") is not True
    or async_for_multi_update_outer_let.get("locals", [{}])[0].get("name") != "out"
    or [item.get("name") for item in async_for_multi_update_locals] != ["i", "j"]
    or async_for_multi_update_loop.get("condition", {}).get("op") != ">"
    or len(async_for_multi_update_body) != 4
    or async_for_multi_update_body[0].get("set_local", {}).get("id") != 0
    or async_for_multi_update_body[1].get("null") is not True
    or async_for_multi_update_body[2].get("set_local", {}).get("id") != 1
    or async_for_multi_update_body[3].get("set_local", {}).get("id") != 2
):
    raise SystemExit(f"expected asyncForMultiUpdate multi-update source, got {async_for_multi_update}")
