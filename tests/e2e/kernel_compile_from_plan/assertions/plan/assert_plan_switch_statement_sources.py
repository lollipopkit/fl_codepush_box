import json
import sys

patch = json.load(open(sys.argv[1]))
patch_by_member = {f.get("member_name"): f for f in patch["functions"]}


def source_for(member):
    function = patch_by_member.get(member)
    if function is None:
        raise SystemExit(f"missing inventory entry for {member}")
    source = function.get("bytecode_source")
    if not isinstance(source, dict):
        raise SystemExit(f"{member} should produce bytecode source: {function}")
    if function.get("unsupported_reasons") != []:
        raise SystemExit(f"{member} should now be supported, got {function}")
    return source


def nested_switch(expr):
    first = expr.get("conditional", {})
    second = first.get("else", {}).get("conditional", {})
    return first, second, second.get("else", {})


def contains(value, predicate):
    if predicate(value):
        return True
    if isinstance(value, dict):
        return any(contains(item, predicate) for item in value.values())
    if isinstance(value, list):
        return any(contains(item, predicate) for item in value)
    return False


def assert_guarded_condition(condition, left_key, left_value, right_value):
    guard = condition.get("conditional", {})
    match = guard.get("condition", {})
    if (
        match.get("op") != "=="
        or match.get("left", {}).get(left_key) != left_value
        or match.get("right", {}).get("string") != right_value
        or guard.get("then", {}).get("arg") != "enabled"
        or guard.get("else", {}).get("bool") is not False
    ):
        raise SystemExit(f"expected guarded switch statement condition, got {condition}")


sync_source = source_for("syncSwitchStatementLabel")
first, second, fallback = nested_switch(sync_source.get("body", {}))
if (
    sync_source.get("params") != ["tier"]
    or first.get("condition", {}).get("left", {}).get("arg") != "tier"
    or first.get("condition", {}).get("right", {}).get("string") != "gold"
    or first.get("then", {}).get("string") != "patched-switch-stmt-gold"
    or second.get("condition", {}).get("right", {}).get("string") != "silver"
    or second.get("then", {}).get("string") != "patched-switch-stmt-silver"
    or fallback.get("string") != "patched-switch-stmt-other"
):
    raise SystemExit(f"expected syncSwitchStatementLabel switch statement source, got {sync_source}")

async_source = source_for("asyncSwitchStatementLabel")
async_value = async_source.get("body", {}).get("new_object", {}).get("args", [{}])[0]
first, second, fallback = nested_switch(async_value)
if (
    async_source.get("async_future") is not True
    or first.get("condition", {}).get("left", {}).get("arg") != "tier"
    or first.get("then", {}).get("string") != "patched-async-switch-stmt-gold"
    or second.get("then", {}).get("string") != "patched-async-switch-stmt-silver"
    or fallback.get("string") != "patched-async-switch-stmt-other"
):
    raise SystemExit(f"expected asyncSwitchStatementLabel async switch statement source, got {async_source}")

await_source = source_for("asyncAwaitThenSwitchStatementLabel")
await_value = await_source.get("body", {}).get("new_object", {}).get("args", [{}])[0]
await_let = await_value.get("let", {})
await_local = await_let.get("locals", [{}])[0]
first, second, fallback = nested_switch(await_let.get("body", {}))
if (
    await_source.get("async_future") is not True
    or await_local.get("name") != "tier"
    or await_local.get("value", {}).get("await", {}).get("arg") != "ready"
    or first.get("condition", {}).get("left", {}).get("let_local") != 0
    or first.get("then", {}).get("string") != "patched-await-switch-stmt-gold"
    or second.get("then", {}).get("string") != "patched-await-switch-stmt-silver"
    or fallback.get("string") != "patched-await-switch-stmt-other"
):
    raise SystemExit(f"expected asyncAwaitThenSwitchStatementLabel await switch statement source, got {await_source}")

score_source = source_for("syncSwitchStatementScore")
first, second, fallback = nested_switch(score_source.get("body", {}))
if (
    score_source.get("return_type") != "int"
    or first.get("condition", {}).get("left", {}).get("arg") != "code"
    or first.get("condition", {}).get("right", {}).get("int") != 7
    or first.get("then", {}).get("int") != 700
    or second.get("condition", {}).get("right", {}).get("int") != 9
    or second.get("then", {}).get("int") != 900
    or fallback.get("int") != 100
):
    raise SystemExit(f"expected syncSwitchStatementScore int switch statement source, got {score_source}")

list_source = source_for("switchStatementListNames")
first, second, fallback = nested_switch(list_source.get("body", {}))
if (
    first.get("then", {}).get("list", [{}])[1].get("string") != "patched-switch-stmt-list-gold"
    or second.get("then", {}).get("list", [{}])[1].get("string") != "patched-switch-stmt-list-silver"
    or fallback.get("list", [{}])[1].get("string") != "patched-switch-stmt-list-other"
):
    raise SystemExit(f"expected switchStatementListNames list switch statement source, got {list_source}")

map_source = source_for("switchStatementMapLabels")
first, second, fallback = nested_switch(map_source.get("body", {}))
if (
    first.get("then", {}).get("map", [{}])[0].get("value", {}).get("string") != "patched-switch-stmt-map-seven"
    or second.get("then", {}).get("map", [{}])[0].get("value", {}).get("string") != "patched-switch-stmt-map-nine"
    or fallback.get("map", [{}])[0].get("value", {}).get("string") != "patched-switch-stmt-map-other"
):
    raise SystemExit(f"expected switchStatementMapLabels map switch statement source, got {map_source}")

guarded_statement = source_for("unchangedGuardedSwitchStatementLabel")
first, second, fallback = nested_switch(guarded_statement.get("body", {}))
if (
    guarded_statement.get("params") != ["tier", "enabled"]
    or first.get("then", {}).get("string") != "patched-guarded-switch-stmt-gold"
    or second.get("then", {}).get("string") != "patched-guarded-switch-stmt-vip"
    or fallback.get("string") != "patched-guarded-switch-stmt-other"
):
    raise SystemExit(f"expected guarded switch statement source, got {guarded_statement}")
assert_guarded_condition(first.get("condition", {}), "arg", "tier", "gold")
assert_guarded_condition(second.get("condition", {}), "arg", "tier", "vip")

async_guarded_statement = source_for("asyncGuardedSwitchStatementLabel")
async_guarded_value = async_guarded_statement.get("body", {}).get("new_object", {}).get("args", [{}])[0]
first, second, fallback = nested_switch(async_guarded_value)
if (
    async_guarded_statement.get("async_future") is not True
    or async_guarded_statement.get("params") != ["tier", "enabled"]
    or first.get("then", {}).get("string") != "patched-async-guarded-switch-stmt-gold"
    or second.get("then", {}).get("string") != "patched-async-guarded-switch-stmt-vip"
    or fallback.get("string") != "patched-async-guarded-switch-stmt-other"
):
    raise SystemExit(
        f"expected async guarded switch statement source, got {async_guarded_statement}"
    )
assert_guarded_condition(first.get("condition", {}), "arg", "tier", "gold")
assert_guarded_condition(second.get("condition", {}), "arg", "tier", "vip")

await_guarded_statement = source_for("asyncAwaitThenGuardedSwitchStatementLabel")
await_guarded_value = await_guarded_statement.get("body", {}).get("new_object", {}).get("args", [{}])[0]
await_guarded_let = await_guarded_value.get("let", {})
await_guarded_local = await_guarded_let.get("locals", [{}])[0]
first, second, fallback = nested_switch(await_guarded_let.get("body", {}))
if (
    await_guarded_statement.get("async_future") is not True
    or await_guarded_statement.get("params") != ["ready", "enabled"]
    or await_guarded_local.get("name") != "tier"
    or await_guarded_local.get("value", {}).get("await", {}).get("arg") != "ready"
    or first.get("then", {}).get("string") != "patched-await-guarded-switch-stmt-gold"
    or second.get("then", {}).get("string") != "patched-await-guarded-switch-stmt-vip"
    or fallback.get("string") != "patched-await-guarded-switch-stmt-other"
):
    raise SystemExit(
        "expected await guarded switch statement source, "
        f"got {await_guarded_statement}"
    )
assert_guarded_condition(first.get("condition", {}), "let_local", 0, "gold")
assert_guarded_condition(second.get("condition", {}), "let_local", 0, "vip")


def assigned_switch_parts(source, local_name):
    body = source.get("body", {})
    let_body = body.get("let", {})
    if let_body:
        local = let_body.get("locals", [{}])[-1]
        seq = let_body.get("body", {}).get("seq", [])
    else:
        local = {}
        seq = body.get("seq", [])
    if (local and local.get("name") != local_name) or len(seq) != 2:
        raise SystemExit(f"expected let local {local_name} with switch/tail seq, got {source}")
    first, second, fallback = nested_switch(seq[0])
    return local, first, second, fallback, seq[1]


assigned_source = source_for("syncSwitchStatementAssignedLabel")
local, first, second, fallback, tail = assigned_switch_parts(assigned_source, "label")
if (
    local.get("value", {}).get("string") != "patched-switch-stmt-assigned-head"
    or first.get("then", {}).get("set_local", {}).get("value", {}).get("string") != "patched-switch-stmt-assigned-gold"
    or second.get("then", {}).get("set_local", {}).get("value", {}).get("string") != "patched-switch-stmt-assigned-silver"
    or fallback.get("set_local", {}).get("value", {}).get("string") != "patched-switch-stmt-assigned-other"
    or tail.get("concat", [{}, {}])[1].get("let_local") != 0
):
    raise SystemExit(f"expected syncSwitchStatementAssignedLabel assignment switch source, got {assigned_source}")

async_assigned_source = source_for("asyncSwitchStatementAssignedLabel")
async_assigned_value = async_assigned_source.get("body", {}).get("new_object", {}).get("args", [{}])[0]
local, first, second, fallback, tail = assigned_switch_parts({"body": async_assigned_value}, "label")
if (
    async_assigned_source.get("async_future") is not True
    or first.get("then", {}).get("set_local", {}).get("value", {}).get("string") != "patched-async-switch-stmt-assigned-gold"
    or second.get("then", {}).get("set_local", {}).get("value", {}).get("string") != "patched-async-switch-stmt-assigned-silver"
    or fallback.get("set_local", {}).get("value", {}).get("string") != "patched-async-switch-stmt-assigned-other"
    or tail.get("concat", [{}, {}])[1].get("let_local") != 0
):
    raise SystemExit(f"expected asyncSwitchStatementAssignedLabel assignment switch source, got {async_assigned_source}")

await_assigned_source = source_for("asyncAwaitThenSwitchStatementAssignedLabel")
await_assigned_value = await_assigned_source.get("body", {}).get("new_object", {}).get("args", [{}])[0]
outer_let = await_assigned_value.get("let", {})
outer_local = outer_let.get("locals", [{}])[0]
assigned_local = outer_let.get("locals", [{}, {}])[1]
inner = outer_let.get("body", {})
local, first, second, fallback, tail = assigned_switch_parts({"body": inner}, "label")
if (
    outer_local.get("name") != "tier"
    or outer_local.get("value", {}).get("await", {}).get("arg") != "ready"
    or assigned_local.get("name") != "label"
    or assigned_local.get("value", {}).get("string") != "patched-await-switch-stmt-assigned-head"
    or first.get("condition", {}).get("left", {}).get("let_local") != 0
    or first.get("then", {}).get("set_local", {}).get("value", {}).get("string") != "patched-await-switch-stmt-assigned-gold"
    or second.get("then", {}).get("set_local", {}).get("value", {}).get("string") != "patched-await-switch-stmt-assigned-silver"
    or fallback.get("set_local", {}).get("value", {}).get("string") != "patched-await-switch-stmt-assigned-other"
    or tail.get("concat", [{}, {}])[1].get("let_local") != 1
):
    raise SystemExit(f"expected asyncAwaitThenSwitchStatementAssignedLabel await assignment switch source, got {await_assigned_source}")

assigned_score = source_for("syncSwitchStatementAssignedScore")
local, first, second, fallback, tail = assigned_switch_parts(assigned_score, "score")
if (
    assigned_score.get("return_type") != "int"
    or first.get("then", {}).get("set_local", {}).get("value", {}).get("int") != 7000
    or second.get("then", {}).get("set_local", {}).get("value", {}).get("int") != 9000
    or fallback.get("set_local", {}).get("value", {}).get("int") != 1000
    or tail.get("op") != "+"
    or tail.get("left", {}).get("let_local") != 0
):
    raise SystemExit(f"expected syncSwitchStatementAssignedScore assignment switch source, got {assigned_score}")

assigned_list = source_for("switchStatementAssignedListNames")
_, first, second, fallback, tail = assigned_switch_parts(assigned_list, "label")
if (
    first.get("then", {}).get("set_local", {}).get("value", {}).get("string") != "patched-switch-stmt-assigned-list-gold"
    or second.get("then", {}).get("set_local", {}).get("value", {}).get("string") != "patched-switch-stmt-assigned-list-silver"
    or fallback.get("set_local", {}).get("value", {}).get("string") != "patched-switch-stmt-assigned-list-other"
    or tail.get("list", [{}])[0].get("let_local") != 0
):
    raise SystemExit(f"expected switchStatementAssignedListNames assignment switch source, got {assigned_list}")

assigned_map = source_for("switchStatementAssignedMapLabels")
_, first, second, fallback, tail = assigned_switch_parts(assigned_map, "label")
if (
    first.get("then", {}).get("set_local", {}).get("value", {}).get("string") != "patched-switch-stmt-assigned-map-seven"
    or second.get("then", {}).get("set_local", {}).get("value", {}).get("string") != "patched-switch-stmt-assigned-map-nine"
    or fallback.get("set_local", {}).get("value", {}).get("string") != "patched-switch-stmt-assigned-map-other"
    or tail.get("map", [{}])[0].get("value", {}).get("let_local") != 0
):
    raise SystemExit(f"expected switchStatementAssignedMapLabels assignment switch source, got {assigned_map}")

throw_source = source_for("syncSwitchStatementThrowLabel")
first, second, fallback = nested_switch(throw_source.get("body", {}))
if (
    first.get("then", {}).get("string") != "patched-switch-stmt-throw-gold"
    or second.get("condition", {}).get("right", {}).get("string") != "blocked"
    or second.get("then", {}).get("throw", {}).get("string") != "patched-switch-stmt-throw-blocked"
    or fallback.get("string") != "patched-switch-stmt-throw-other"
):
    raise SystemExit(f"expected syncSwitchStatementThrowLabel switch throw source, got {throw_source}")

async_throw_source = source_for("asyncSwitchStatementThrowLabel")
async_throw_value = async_throw_source.get("body", {}).get("new_object", {}).get("args", [{}])[0]
first, second, fallback = nested_switch(async_throw_value)
if (
    async_throw_source.get("async_future") is not True
    or first.get("then", {}).get("string") != "patched-async-switch-stmt-throw-gold"
    or second.get("then", {}).get("throw", {}).get("string") != "patched-async-switch-stmt-throw-blocked"
    or fallback.get("string") != "patched-async-switch-stmt-throw-other"
):
    raise SystemExit(f"expected asyncSwitchStatementThrowLabel switch throw source, got {async_throw_source}")

await_throw_source = source_for("asyncAwaitThenSwitchStatementThrowLabel")
await_throw_value = await_throw_source.get("body", {}).get("new_object", {}).get("args", [{}])[0]
await_throw_let = await_throw_value.get("let", {})
await_throw_local = await_throw_let.get("locals", [{}])[0]
first, second, fallback = nested_switch(await_throw_let.get("body", {}))
if (
    await_throw_source.get("async_future") is not True
    or await_throw_local.get("name") != "tier"
    or await_throw_local.get("value", {}).get("await", {}).get("arg") != "ready"
    or first.get("condition", {}).get("left", {}).get("let_local") != 0
    or first.get("then", {}).get("string") != "patched-await-switch-stmt-throw-gold"
    or second.get("then", {}).get("throw", {}).get("string") != "patched-await-switch-stmt-throw-blocked"
    or fallback.get("string") != "patched-await-switch-stmt-throw-other"
):
    raise SystemExit(
        "expected asyncAwaitThenSwitchStatementThrowLabel await switch throw source, "
        f"got {await_throw_source}"
    )


def assert_sequence_branch(branch, label, prefix, throws=False, local_id=0):
    branch_let = branch.get("let", {})
    branch_local = branch_let.get("locals", [{}])[0]
    branch_body = branch_let.get("body", {})
    value = branch_body
    if throws:
        value = branch_body.get("throw", {})
        if not value:
            value = branch_body.get("seq", [{}])[0].get("throw", {})
    if (
        branch_local.get("name") != "label"
        or branch_local.get("value", {}).get("string") != label
        or value.get("concat", [{}, {}])[0].get("string") != prefix
        or value.get("concat", [{}, {}])[1].get("let_local") != local_id
    ):
        raise SystemExit(
            f"expected switch sequence branch label={label} prefix={prefix}, got {branch}"
        )


sequence_source = source_for("syncSwitchStatementSequenceLabel")
first, second, fallback = nested_switch(sequence_source.get("body", {}))
assert_sequence_branch(
    first.get("then", {}),
    "patched-switch-stmt-seq-gold",
    "patched-switch-stmt-seq-",
)
assert_sequence_branch(
    second.get("then", {}),
    "patched-switch-stmt-seq-blocked",
    "patched-switch-stmt-seq-",
    throws=True,
)
assert_sequence_branch(
    fallback,
    "patched-switch-stmt-seq-other",
    "patched-switch-stmt-seq-",
)

async_sequence_source = source_for("asyncSwitchStatementSequenceLabel")
async_sequence_value = async_sequence_source.get("body", {}).get("new_object", {}).get("args", [{}])[0]
first, second, fallback = nested_switch(async_sequence_value)
if async_sequence_source.get("async_future") is not True:
    raise SystemExit(f"expected asyncSwitchStatementSequenceLabel async source, got {async_sequence_source}")
assert_sequence_branch(
    first.get("then", {}),
    "patched-async-switch-stmt-seq-gold",
    "patched-async-switch-stmt-seq-",
)
assert_sequence_branch(
    second.get("then", {}),
    "patched-async-switch-stmt-seq-blocked",
    "patched-async-switch-stmt-seq-",
    throws=True,
)
assert_sequence_branch(
    fallback,
    "patched-async-switch-stmt-seq-other",
    "patched-async-switch-stmt-seq-",
)

await_sequence_source = source_for("asyncAwaitThenSwitchStatementSequenceLabel")
await_sequence_value = await_sequence_source.get("body", {}).get("new_object", {}).get("args", [{}])[0]
await_sequence_let = await_sequence_value.get("let", {})
await_sequence_local = await_sequence_let.get("locals", [{}])[0]
first, second, fallback = nested_switch(await_sequence_let.get("body", {}))
if (
    await_sequence_source.get("async_future") is not True
    or await_sequence_local.get("name") != "tier"
    or await_sequence_local.get("value", {}).get("await", {}).get("arg") != "ready"
    or first.get("condition", {}).get("left", {}).get("let_local") != 0
):
    raise SystemExit(
        "expected asyncAwaitThenSwitchStatementSequenceLabel await switch sequence source, "
        f"got {await_sequence_source}"
    )
assert_sequence_branch(
    first.get("then", {}),
    "patched-await-switch-stmt-seq-gold",
    "patched-await-switch-stmt-seq-",
    local_id=1,
)
assert_sequence_branch(
    second.get("then", {}),
    "patched-await-switch-stmt-seq-blocked",
    "patched-await-switch-stmt-seq-",
    throws=True,
    local_id=1,
)
assert_sequence_branch(
    fallback,
    "patched-await-switch-stmt-seq-other",
    "patched-await-switch-stmt-seq-",
    local_id=1,
)


def assert_side_effect_source(source, name, prefix, await_local=False):
    body = source.get("body", {})
    if source.get("async_future"):
        body = body.get("new_object", {}).get("args", [{}])[0]
    side_let = body.get("let", {})
    locals_ = side_let.get("locals", [])
    label_id = 1 if await_local else 0
    suffix_id = 2 if await_local else 1
    if await_local:
        if (
            len(locals_) != 3
            or locals_[0].get("name") != "tier"
            or locals_[0].get("value", {}).get("await", {}).get("arg") != "ready"
        ):
            raise SystemExit(f"expected {name} await local before side-effect switch, got {source}")
    elif len(locals_) != 2:
        raise SystemExit(f"expected {name} label/suffix locals, got {source}")
    seq = side_let.get("body", {}).get("seq", [])
    first, second, fallback = nested_switch(seq[0] if seq else {})
    tail = seq[1] if len(seq) > 1 else {}
    for branch, tier in [
        (first.get("then", {}), "gold"),
        (second.get("then", {}), "silver"),
        (fallback, "other"),
    ]:
        items = branch.get("seq", [])
        if (
            len(items) != 2
            or items[0].get("set_local", {}).get("id") != label_id
            or items[0].get("set_local", {}).get("value", {}).get("string") != f"{prefix}-{tier}"
            or items[1].get("set_local", {}).get("id") != suffix_id
            or items[1].get("set_local", {}).get("value", {}).get("string")
            != f"{prefix}-suffix-{tier}"
        ):
            raise SystemExit(f"expected {name} {tier} branch side-effect seq, got {source}")
    tail_concat = tail.get("concat", [])
    if (
        tail_concat[0].get("string") != f"{prefix}-"
        or tail_concat[1].get("let_local") != label_id
        or tail_concat[3].get("let_local") != suffix_id
    ):
        raise SystemExit(f"expected {name} shared tail concat, got {source}")


assert_side_effect_source(
    source_for("syncSwitchStatementSideEffectTail"),
    "syncSwitchStatementSideEffectTail",
    "patched-switch-stmt-side",
)
assert_side_effect_source(
    source_for("asyncSwitchStatementSideEffectTail"),
    "asyncSwitchStatementSideEffectTail",
    "patched-async-switch-stmt-side",
)
assert_side_effect_source(
    source_for("asyncAwaitThenSwitchStatementSideEffectTail"),
    "asyncAwaitThenSwitchStatementSideEffectTail",
    "patched-await-switch-stmt-side",
    await_local=True,
)


def assert_await_case_branch(branch, await_arg, prefix, local_id=0, throws=False):
    branch_let = branch.get("let", {})
    branch_local = branch_let.get("locals", [{}])[0]
    branch_body = branch_let.get("body", {})
    value = branch_body.get("seq", [{}])[0].get("throw", {}) if throws else branch_body
    if (
        branch_local.get("name") != "label"
        or branch_local.get("value", {}).get("await", {}).get("arg") != await_arg
        or value.get("concat", [{}, {}])[0].get("string") != prefix
        or value.get("concat", [{}, {}])[1].get("let_local") != local_id
    ):
        raise SystemExit(
            f"expected await case branch await_arg={await_arg} prefix={prefix}, got {branch}"
        )


await_case_source = source_for("asyncSwitchStatementAwaitCaseLabel")
await_case_value = await_case_source.get("body", {}).get("new_object", {}).get("args", [{}])[0]
first, second, fallback = nested_switch(await_case_value)
if await_case_source.get("async_future") is not True:
    raise SystemExit(f"expected asyncSwitchStatementAwaitCaseLabel async source, got {await_case_source}")
assert_await_case_branch(
    first.get("then", {}),
    "ready",
    "patched-async-switch-stmt-await-case-gold-",
)
assert_await_case_branch(
    second.get("then", {}),
    "ready",
    "patched-async-switch-stmt-await-case-blocked-",
    throws=True,
)
assert_await_case_branch(
    fallback,
    "ready",
    "patched-async-switch-stmt-await-case-other-",
)

await_switch_await_case_source = source_for("asyncAwaitThenSwitchStatementAwaitCaseLabel")
await_switch_await_case_value = (
    await_switch_await_case_source.get("body", {}).get("new_object", {}).get("args", [{}])[0]
)
await_switch_await_case_let = await_switch_await_case_value.get("let", {})
await_switch_await_case_local = await_switch_await_case_let.get("locals", [{}])[0]
first, second, fallback = nested_switch(await_switch_await_case_let.get("body", {}))
if (
    await_switch_await_case_source.get("async_future") is not True
    or await_switch_await_case_local.get("name") != "tier"
    or await_switch_await_case_local.get("value", {}).get("await", {}).get("arg") != "tierReady"
):
    raise SystemExit(
        "expected asyncAwaitThenSwitchStatementAwaitCaseLabel outer await source, "
        f"got {await_switch_await_case_source}"
    )
assert_await_case_branch(
    first.get("then", {}),
    "labelReady",
    "patched-await-switch-stmt-await-case-gold-",
    local_id=1,
)
assert_await_case_branch(
    second.get("then", {}),
    "labelReady",
    "patched-await-switch-stmt-await-case-blocked-",
    local_id=1,
    throws=True,
)
assert_await_case_branch(
    fallback,
    "labelReady",
    "patched-await-switch-stmt-await-case-other-",
    local_id=1,
)


def has_case_value(source, value):
    return contains(
        source,
        lambda item: isinstance(item, dict)
        and item.get("condition", {}).get("right", {}).get("string") == value,
    )


multi_source = source_for("syncSwitchStatementMultiCaseLabel")
if (
    not has_case_value(multi_source, "gold")
    or not has_case_value(multi_source, "vip")
    or not contains(
        multi_source,
        lambda item: isinstance(item, dict)
        and item.get("then", {}).get("string") == "patched-switch-stmt-multi-premium",
    )
):
    raise SystemExit(f"expected syncSwitchStatementMultiCaseLabel multi-label source, got {multi_source}")

multi_assigned_source = source_for("asyncSwitchStatementMultiCaseAssignedLabel")
multi_assigned_value = multi_assigned_source.get("body", {}).get("new_object", {}).get("args", [{}])[0]
if (
    multi_assigned_source.get("async_future") is not True
    or not has_case_value(multi_assigned_value, "gold")
    or not has_case_value(multi_assigned_value, "vip")
    or not contains(
        multi_assigned_value,
        lambda item: isinstance(item, dict)
        and item.get("set_local", {}).get("value", {}).get("string")
        == "patched-async-switch-stmt-multi-premium",
    )
):
    raise SystemExit(
        "expected asyncSwitchStatementMultiCaseAssignedLabel multi-label assignment source, "
        f"got {multi_assigned_source}"
    )

multi_await_case_source = source_for("asyncSwitchStatementMultiCaseAwaitCaseLabel")
multi_await_case_value = multi_await_case_source.get("body", {}).get("new_object", {}).get("args", [{}])[0]
if (
    multi_await_case_source.get("async_future") is not True
    or not has_case_value(multi_await_case_value, "gold")
    or not has_case_value(multi_await_case_value, "vip")
    or not contains(
        multi_await_case_value,
        lambda item: isinstance(item, dict)
        and item.get("locals", [{}])[0].get("value", {}).get("await", {}).get("arg") == "ready",
    )
    or not contains(
        multi_await_case_value,
        lambda item: isinstance(item, dict)
        and item.get("throw", {}).get("concat", [{}])[0].get("string")
        == "patched-async-switch-stmt-multi-await-blocked-",
    )
):
    raise SystemExit(
        "expected asyncSwitchStatementMultiCaseAwaitCaseLabel multi-label await case source, "
        f"got {multi_await_case_source}"
    )

or_pattern_source = source_for("syncSwitchStatementOrPatternLabel")
if (
    not has_case_value(or_pattern_source, "gold")
    or not has_case_value(or_pattern_source, "vip")
    or not has_case_value(or_pattern_source, "trial")
    or not has_case_value(or_pattern_source, "guest")
    or not contains(
        or_pattern_source,
        lambda item: isinstance(item, dict)
        and item.get("then", {}).get("string") == "patched-switch-stmt-or-premium",
    )
    or not contains(
        or_pattern_source,
        lambda item: isinstance(item, dict)
        and item.get("then", {}).get("string") == "patched-switch-stmt-or-limited",
    )
):
    raise SystemExit(
        f"expected syncSwitchStatementOrPatternLabel OR-pattern source, got {or_pattern_source}"
    )

or_assigned_source = source_for("asyncSwitchStatementOrPatternAssignedLabel")
or_assigned_value = or_assigned_source.get("body", {}).get("new_object", {}).get("args", [{}])[0]
if (
    or_assigned_source.get("async_future") is not True
    or not has_case_value(or_assigned_value, "gold")
    or not has_case_value(or_assigned_value, "vip")
    or not has_case_value(or_assigned_value, "trial")
    or not has_case_value(or_assigned_value, "guest")
    or not contains(
        or_assigned_value,
        lambda item: isinstance(item, dict)
        and item.get("set_local", {}).get("value", {}).get("string")
        == "patched-async-switch-stmt-or-premium",
    )
    or not contains(
        or_assigned_value,
        lambda item: isinstance(item, dict)
        and item.get("set_local", {}).get("value", {}).get("string")
        == "patched-async-switch-stmt-or-limited",
    )
):
    raise SystemExit(
        "expected asyncSwitchStatementOrPatternAssignedLabel OR-pattern assignment source, "
        f"got {or_assigned_source}"
    )

or_await_case_source = source_for("asyncSwitchStatementOrPatternAwaitCaseLabel")
or_await_case_value = or_await_case_source.get("body", {}).get("new_object", {}).get("args", [{}])[0]
if (
    or_await_case_source.get("async_future") is not True
    or not has_case_value(or_await_case_value, "gold")
    or not has_case_value(or_await_case_value, "vip")
    or not has_case_value(or_await_case_value, "blocked")
    or not has_case_value(or_await_case_value, "denied")
    or not contains(
        or_await_case_value,
        lambda item: isinstance(item, dict)
        and item.get("locals", [{}])[0].get("value", {}).get("await", {}).get("arg") == "ready",
    )
    or not contains(
        or_await_case_value,
        lambda item: isinstance(item, dict)
        and item.get("throw", {}).get("concat", [{}])[0].get("string")
        == "patched-async-switch-stmt-or-await-blocked-",
    )
):
    raise SystemExit(
        "expected asyncSwitchStatementOrPatternAwaitCaseLabel OR-pattern await case source, "
        f"got {or_await_case_source}"
    )

await_or_pattern_source = source_for("asyncAwaitThenSwitchStatementOrPatternLabel")
await_or_pattern_value = await_or_pattern_source.get("body", {}).get("new_object", {}).get("args", [{}])[0]
await_or_pattern_let = await_or_pattern_value.get("let", {})
await_or_pattern_local = await_or_pattern_let.get("locals", [{}])[0]
await_or_pattern_body = await_or_pattern_let.get("body", {})
if (
    await_or_pattern_source.get("async_future") is not True
    or await_or_pattern_local.get("name") != "tier"
    or await_or_pattern_local.get("value", {}).get("await", {}).get("arg") != "ready"
    or not has_case_value(await_or_pattern_body, "gold")
    or not has_case_value(await_or_pattern_body, "vip")
    or not has_case_value(await_or_pattern_body, "trial")
    or not has_case_value(await_or_pattern_body, "guest")
    or not contains(
        await_or_pattern_body,
        lambda item: isinstance(item, dict)
        and item.get("then", {}).get("string") == "patched-await-switch-stmt-or-premium",
    )
):
    raise SystemExit(
        "expected asyncAwaitThenSwitchStatementOrPatternLabel await OR-pattern source, "
        f"got {await_or_pattern_source}"
    )


def assert_async_switch_statement_try_source(
    member,
    *,
    await_args,
    strings,
    has_catch=False,
    has_finally=False,
):
    source = source_for(member)
    if source.get("async_future") is not True:
        raise SystemExit(f"expected {member} async_future source, got {source}")
    for await_arg in await_args:
        if not contains(
            source,
            lambda item: isinstance(item, dict)
            and item.get("await", {}).get("arg") == await_arg,
        ):
            raise SystemExit(f"expected {member} await arg {await_arg}, got {source}")
    for string in strings:
        if not contains(
            source,
            lambda item: isinstance(item, dict) and item.get("string") == string,
        ):
            raise SystemExit(f"expected {member} string {string}, got {source}")
    if has_catch and not contains(
        source,
        lambda item: isinstance(item, dict) and "try_catch" in item,
    ):
        raise SystemExit(f"expected {member} try_catch source, got {source}")
    if has_finally and not contains(
        source,
        lambda item: isinstance(item, dict) and "try_finally" in item,
    ):
        raise SystemExit(f"expected {member} try_finally source, got {source}")


assert_async_switch_statement_try_source(
    "asyncAwaitConditionSwitchStatementTryCatchRecoveryLabel",
    await_args=["ready", "recovery"],
    strings=[
        "patched-await-condition-switch-stmt-try-catch-gold",
        "patched-await-condition-switch-stmt-try-catch-blocked",
        "patched-await-condition-switch-stmt-try-catch-caught-",
    ],
    has_catch=True,
)
assert_async_switch_statement_try_source(
    "asyncAwaitConditionSwitchStatementTryFinallyCleanupLabel",
    await_args=["ready", "cleanup"],
    strings=[
        "patched-await-condition-switch-stmt-try-finally-gold",
        "patched-await-condition-switch-stmt-try-finally-silver",
    ],
    has_finally=True,
)
assert_async_switch_statement_try_source(
    "asyncAwaitThenSwitchStatementTryCatchRecoveryLabel",
    await_args=["ready", "recovery"],
    strings=[
        "patched-await-then-switch-stmt-try-catch-gold",
        "patched-await-then-switch-stmt-try-catch-blocked",
        "patched-await-then-switch-stmt-try-catch-caught-",
    ],
    has_catch=True,
)
assert_async_switch_statement_try_source(
    "asyncAwaitThenSwitchStatementTryFinallyCleanupLabel",
    await_args=["ready", "cleanup"],
    strings=[
        "patched-await-then-switch-stmt-try-finally-gold",
        "patched-await-then-switch-stmt-try-finally-silver",
    ],
    has_finally=True,
)
assert_async_switch_statement_try_source(
    "asyncDoubleAwaitSwitchStatementTryCatchFinallyRecoveryLabel",
    await_args=["ready", "recovery", "cleanup"],
    strings=[
        "patched-double-await-switch-stmt-try-catch-finally-gold",
        "patched-double-await-switch-stmt-try-catch-finally-blocked",
        "patched-double-await-switch-stmt-try-catch-finally-caught-",
    ],
    has_catch=True,
    has_finally=True,
)
assert_async_switch_statement_try_source(
    "asyncDoubleAwaitSwitchStatementTryFinallyCleanupLabel",
    await_args=["ready", "cleanup"],
    strings=[
        "patched-double-await-switch-stmt-try-finally-gold",
        "patched-double-await-switch-stmt-try-finally-silver",
    ],
    has_finally=True,
)
assert_async_switch_statement_try_source(
    "asyncSwitchStatementAwaitGuardLabel",
    await_args=["enabled"],
    strings=[
        "patched-switch-stmt-await-guard-gold",
        "patched-switch-stmt-await-guard-vip",
    ],
)
assert_async_switch_statement_try_source(
    "asyncAwaitThenSwitchStatementAwaitGuardLabel",
    await_args=["ready", "enabled"],
    strings=[
        "patched-await-switch-stmt-await-guard-gold",
        "patched-await-switch-stmt-await-guard-vip",
    ],
)
