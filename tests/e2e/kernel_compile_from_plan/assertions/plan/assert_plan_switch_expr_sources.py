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


def nested_switch4(expr):
    first = expr.get("conditional", {})
    second = first.get("else", {}).get("conditional", {})
    third = second.get("else", {}).get("conditional", {})
    fourth = third.get("else", {}).get("conditional", {})
    return first, second, third, fourth, fourth.get("else", {})


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
        raise SystemExit(f"expected guarded switch condition, got {condition}")


sync_source = source_for("syncSwitchLabel")
first, second, fallback = nested_switch(sync_source.get("body", {}))
if (
    sync_source.get("async_kind") not in (None, "sync")
    or sync_source.get("params") != ["tier"]
    or first.get("condition", {}).get("op") != "=="
    or first.get("condition", {}).get("left", {}).get("arg") != "tier"
    or first.get("condition", {}).get("right", {}).get("string") != "gold"
    or first.get("then", {}).get("string") != "patched-switch-gold"
    or second.get("condition", {}).get("right", {}).get("string") != "silver"
    or second.get("then", {}).get("string") != "patched-switch-silver"
    or fallback.get("string") != "patched-switch-other"
):
    raise SystemExit(f"expected syncSwitchLabel nested conditional switch source, got {sync_source}")

sync_multi = source_for("syncSwitchMultiValueLabel")
first, second, third, fourth, fallback = nested_switch4(sync_multi.get("body", {}))
if (
    sync_multi.get("async_kind") not in (None, "sync")
    or sync_multi.get("params") != ["tier"]
    or first.get("condition", {}).get("right", {}).get("string") != "gold"
    or first.get("then", {}).get("string") != "patched-switch-premium"
    or second.get("condition", {}).get("right", {}).get("string") != "vip"
    or second.get("then", {}).get("string") != "patched-switch-premium"
    or third.get("condition", {}).get("right", {}).get("string") != "trial"
    or third.get("then", {}).get("string") != "patched-switch-limited"
    or fourth.get("condition", {}).get("right", {}).get("string") != "guest"
    or fourth.get("then", {}).get("string") != "patched-switch-limited"
    or fallback.get("string") != "patched-switch-standard"
):
    raise SystemExit(
        f"expected syncSwitchMultiValueLabel four-way switch source, got {sync_multi}"
    )

async_source = source_for("asyncSwitchLabel")
async_value = async_source.get("body", {}).get("new_object", {}).get("args", [{}])[0]
first, second, fallback = nested_switch(async_value)
if (
    async_source.get("async_future") is not True
    or async_source.get("params") != ["tier"]
    or first.get("condition", {}).get("left", {}).get("arg") != "tier"
    or first.get("then", {}).get("string") != "patched-async-switch-gold"
    or second.get("then", {}).get("string") != "patched-async-switch-silver"
    or fallback.get("string") != "patched-async-switch-other"
):
    raise SystemExit(f"expected asyncSwitchLabel async switch source, got {async_source}")

async_multi = source_for("asyncSwitchMultiValueLabel")
async_multi_value = async_multi.get("body", {}).get("new_object", {}).get("args", [{}])[0]
first, second, third, fourth, fallback = nested_switch4(async_multi_value)
if (
    async_multi.get("async_future") is not True
    or async_multi.get("params") != ["tier"]
    or first.get("condition", {}).get("left", {}).get("arg") != "tier"
    or first.get("then", {}).get("string") != "patched-async-switch-premium"
    or second.get("then", {}).get("string") != "patched-async-switch-premium"
    or third.get("then", {}).get("string") != "patched-async-switch-limited"
    or fourth.get("then", {}).get("string") != "patched-async-switch-limited"
    or fallback.get("string") != "patched-async-switch-standard"
):
    raise SystemExit(
        f"expected asyncSwitchMultiValueLabel async switch source, got {async_multi}"
    )

await_source = source_for("asyncAwaitThenSwitchLabel")
await_value = await_source.get("body", {}).get("new_object", {}).get("args", [{}])[0]
await_let = await_value.get("let", {})
await_local = await_let.get("locals", [{}])[0]
first, second, fallback = nested_switch(await_let.get("body", {}))
if (
    await_source.get("async_future") is not True
    or await_local.get("name") != "tier"
    or await_local.get("value", {}).get("await", {}).get("arg") != "ready"
    or first.get("condition", {}).get("left", {}).get("let_local") != 0
    or first.get("then", {}).get("string") != "patched-await-switch-gold"
    or second.get("then", {}).get("string") != "patched-await-switch-silver"
    or fallback.get("string") != "patched-await-switch-other"
):
    raise SystemExit(f"expected asyncAwaitThenSwitchLabel await-local switch source, got {await_source}")

await_multi = source_for("asyncAwaitThenSwitchMultiValueLabel")
await_multi_value = await_multi.get("body", {}).get("new_object", {}).get("args", [{}])[0]
await_multi_let = await_multi_value.get("let", {})
await_multi_local = await_multi_let.get("locals", [{}])[0]
first, second, third, fourth, fallback = nested_switch4(await_multi_let.get("body", {}))
if (
    await_multi.get("async_future") is not True
    or await_multi_local.get("name") != "tier"
    or await_multi_local.get("value", {}).get("await", {}).get("arg") != "ready"
    or first.get("condition", {}).get("left", {}).get("let_local") != 0
    or first.get("then", {}).get("string") != "patched-await-switch-premium"
    or second.get("then", {}).get("string") != "patched-await-switch-premium"
    or third.get("then", {}).get("string") != "patched-await-switch-limited"
    or fourth.get("then", {}).get("string") != "patched-await-switch-limited"
    or fallback.get("string") != "patched-await-switch-standard"
):
    raise SystemExit(
        f"expected asyncAwaitThenSwitchMultiValueLabel await-local switch source, got {await_multi}"
    )

score_source = source_for("syncSwitchScore")
first, second, fallback = nested_switch(score_source.get("body", {}))
if (
    score_source.get("return_type") != "int"
    or first.get("condition", {}).get("left", {}).get("arg") != "code"
    or first.get("condition", {}).get("right", {}).get("int") != 7
    or first.get("then", {}).get("int") != 70
    or second.get("condition", {}).get("right", {}).get("int") != 9
    or second.get("then", {}).get("int") != 90
    or fallback.get("int") != 10
):
    raise SystemExit(f"expected syncSwitchScore int switch source, got {score_source}")

multi_score = source_for("syncSwitchMultiValueScore")
first, second, third, fourth, fallback = nested_switch4(multi_score.get("body", {}))
if (
    multi_score.get("return_type") != "int"
    or first.get("condition", {}).get("left", {}).get("arg") != "code"
    or first.get("condition", {}).get("right", {}).get("int") != 7
    or first.get("then", {}).get("int") != 80
    or second.get("condition", {}).get("right", {}).get("int") != 8
    or second.get("then", {}).get("int") != 80
    or third.get("condition", {}).get("right", {}).get("int") != 9
    or third.get("then", {}).get("int") != 100
    or fourth.get("condition", {}).get("right", {}).get("int") != 10
    or fourth.get("then", {}).get("int") != 100
    or fallback.get("int") != 10
):
    raise SystemExit(f"expected syncSwitchMultiValueScore int switch source, got {multi_score}")

list_source = source_for("switchListNames")
items = list_source.get("body", {}).get("list", [])
first, second, fallback = nested_switch(items[1] if len(items) > 1 else {})
if (
    list_source.get("params") != ["tier"]
    or items[0].get("string") != "patched-switch-list-head"
    or first.get("then", {}).get("string") != "patched-switch-list-gold"
    or second.get("then", {}).get("string") != "patched-switch-list-silver"
    or fallback.get("string") != "patched-switch-list-other"
    or items[2].get("string") != "patched-switch-list-tail"
):
    raise SystemExit(f"expected switchListNames list-embedded switch source, got {list_source}")

map_source = source_for("switchMapLabels")
entries = map_source.get("body", {}).get("map", [])
state_value = entries[1].get("value", {}) if len(entries) > 1 else {}
first, second, fallback = nested_switch(state_value)
if (
    map_source.get("params") != ["code"]
    or entries[0].get("key", {}).get("string") != "mode"
    or entries[0].get("value", {}).get("string") != "patched-switch-map"
    or first.get("then", {}).get("string") != "patched-switch-map-seven"
    or second.get("then", {}).get("string") != "patched-switch-map-nine"
    or fallback.get("string") != "patched-switch-map-other"
):
    raise SystemExit(f"expected switchMapLabels map-embedded switch source, got {map_source}")

guarded_source = source_for("unchangedGuardedSwitchLabel")
first, second, fallback = nested_switch(guarded_source.get("body", {}))
if (
    guarded_source.get("async_kind") not in (None, "sync")
    or guarded_source.get("params") != ["tier", "enabled"]
    or first.get("then", {}).get("string") != "patched-guarded-switch-gold"
    or second.get("then", {}).get("string") != "patched-guarded-switch-vip"
    or fallback.get("string") != "patched-guarded-switch-other"
):
    raise SystemExit(f"expected guarded switch source, got {guarded_source}")
assert_guarded_condition(first.get("condition", {}), "arg", "tier", "gold")
assert_guarded_condition(second.get("condition", {}), "arg", "tier", "vip")

async_guarded = source_for("asyncGuardedSwitchLabel")
async_guarded_value = async_guarded.get("body", {}).get("new_object", {}).get("args", [{}])[0]
first, second, fallback = nested_switch(async_guarded_value)
if (
    async_guarded.get("async_future") is not True
    or async_guarded.get("params") != ["tier", "enabled"]
    or first.get("then", {}).get("string") != "patched-async-guarded-switch-gold"
    or second.get("then", {}).get("string") != "patched-async-guarded-switch-vip"
    or fallback.get("string") != "patched-async-guarded-switch-other"
):
    raise SystemExit(f"expected async guarded switch source, got {async_guarded}")
assert_guarded_condition(first.get("condition", {}), "arg", "tier", "gold")
assert_guarded_condition(second.get("condition", {}), "arg", "tier", "vip")

await_guarded = source_for("asyncAwaitThenGuardedSwitchLabel")
await_guarded_value = await_guarded.get("body", {}).get("new_object", {}).get("args", [{}])[0]
await_guarded_let = await_guarded_value.get("let", {})
await_guarded_local = await_guarded_let.get("locals", [{}])[0]
first, second, fallback = nested_switch(await_guarded_let.get("body", {}))
if (
    await_guarded.get("async_future") is not True
    or await_guarded.get("params") != ["ready", "enabled"]
    or await_guarded_local.get("name") != "tier"
    or await_guarded_local.get("value", {}).get("await", {}).get("arg") != "ready"
    or first.get("then", {}).get("string") != "patched-await-guarded-switch-gold"
    or second.get("then", {}).get("string") != "patched-await-guarded-switch-vip"
    or fallback.get("string") != "patched-await-guarded-switch-other"
):
    raise SystemExit(f"expected await guarded switch source, got {await_guarded}")
assert_guarded_condition(first.get("condition", {}), "let_local", 0, "gold")
assert_guarded_condition(second.get("condition", {}), "let_local", 0, "vip")


def assert_async_switch_try_source(
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


assert_async_switch_try_source(
    "asyncAwaitConditionSwitchTryCatchRecoveryLabel",
    await_args=["ready", "recovery"],
    strings=[
        "patched-await-condition-switch-try-catch-gold",
        "patched-await-condition-switch-try-catch-blocked",
        "patched-await-condition-switch-try-catch-caught-",
    ],
    has_catch=True,
)
assert_async_switch_try_source(
    "asyncAwaitConditionSwitchTryFinallyCleanupLabel",
    await_args=["ready", "cleanup"],
    strings=[
        "patched-await-condition-switch-try-finally-gold",
        "patched-await-condition-switch-try-finally-silver",
    ],
    has_finally=True,
)
assert_async_switch_try_source(
    "asyncAwaitThenSwitchTryCatchRecoveryLabel",
    await_args=["ready", "recovery"],
    strings=[
        "patched-await-then-switch-try-catch-gold",
        "patched-await-then-switch-try-catch-blocked",
        "patched-await-then-switch-try-catch-caught-",
    ],
    has_catch=True,
)
assert_async_switch_try_source(
    "asyncAwaitThenSwitchTryFinallyCleanupLabel",
    await_args=["ready", "cleanup"],
    strings=[
        "patched-await-then-switch-try-finally-gold",
        "patched-await-then-switch-try-finally-silver",
    ],
    has_finally=True,
)
assert_async_switch_try_source(
    "asyncDoubleAwaitSwitchTryCatchFinallyRecoveryLabel",
    await_args=["ready", "recovery", "cleanup"],
    strings=[
        "patched-double-await-switch-try-catch-finally-gold",
        "patched-double-await-switch-try-catch-finally-blocked",
        "patched-double-await-switch-try-catch-finally-caught-",
    ],
    has_catch=True,
    has_finally=True,
)
assert_async_switch_try_source(
    "asyncDoubleAwaitSwitchTryFinallyCleanupLabel",
    await_args=["ready", "cleanup"],
    strings=[
        "patched-double-await-switch-try-finally-gold",
        "patched-double-await-switch-try-finally-silver",
    ],
    has_finally=True,
)
assert_async_switch_try_source(
    "asyncSwitchAwaitGuardLabel",
    await_args=["enabled"],
    strings=[
        "patched-switch-await-guard-gold",
        "patched-switch-await-guard-vip",
    ],
)
assert_async_switch_try_source(
    "asyncAwaitThenSwitchAwaitGuardLabel",
    await_args=["ready", "enabled"],
    strings=[
        "patched-await-switch-await-guard-gold",
        "patched-await-switch-await-guard-vip",
    ],
)
