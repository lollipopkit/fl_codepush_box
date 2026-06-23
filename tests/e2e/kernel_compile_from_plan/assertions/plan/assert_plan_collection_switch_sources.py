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


def assert_switch_try_catch_finally_await(member, params, required, min_awaits):
    source = source_for(member)
    source_json = json.dumps(source)
    if (
        source.get("async_future") is not True
        or source.get("params") != params
        or '"try_finally"' not in source_json
        or '"try_catch"' not in source_json
        or source_json.count('"await"') < min_awaits
        or ("list_add_all" not in source_json and "map_add_all" not in source_json)
        or any(item not in source_json for item in required)
    ):
        raise SystemExit(f"expected {member} switch try/catch/finally await source, got {source}")


def returned_arg(source):
    return source.get("body", {}).get("new_object", {}).get("args", [{}])[0]


def require_switch_spread(spread, premium_key, premium_value):
    conditional = spread.get("conditional", {})
    if conditional.get("condition", {}).get("right", {}).get("string") != "gold":
        raise SystemExit(f"expected first switch case to compare gold, got {spread}")
    text = json.dumps(spread)
    for token in ["vip", premium_value]:
        if token not in text:
            raise SystemExit(f"expected switch spread token {token}, got {spread}")
    if premium_key and premium_key not in text:
        raise SystemExit(f"expected switch spread key {premium_key}, got {spread}")


def require_guarded_switch_spread(spread, premium_key, gold_value, vip_value):
    first = spread.get("conditional", {})
    second = first.get("else", {}).get("conditional", {})
    text = json.dumps(spread)
    for condition, value, token in [
        (first.get("condition", {}), gold_value, "gold"),
        (second.get("condition", {}), vip_value, "vip"),
    ]:
        guard = condition.get("conditional", {})
        match = guard.get("condition", {})
        if (
            match.get("op") != "=="
            or match.get("right", {}).get("string") != token
            or guard.get("then", {}).get("arg") != "premium"
            or guard.get("else", {}).get("bool") is not False
            or value not in text
        ):
            raise SystemExit(f"expected guarded switch spread for {token}, got {spread}")
    if premium_key and premium_key not in text:
        raise SystemExit(f"expected guarded switch spread key {premium_key}, got {spread}")


def assert_list(member, prefix, has_finally=False):
    source = source_for(member)
    arg = returned_arg(source)
    if has_finally:
        try_finally = arg.get("try_finally", {})
        body = try_finally.get("body", {})
        if "patched-collection-switch-try-finally-list-cleanup" not in json.dumps(
            try_finally.get("finally", {})
        ):
            raise SystemExit(f"expected finalizer cleanup for {member}, got {source}")
    else:
        body = arg
    conditional = body.get("conditional", {})
    then_for = conditional.get("then", {}).get("list_for_in", {})
    else_for = conditional.get("else", {}).get("list_for_in", {})
    then_add_all = then_for.get("receiver", {}).get("list_add_all", {})
    if (
        source.get("async_future") is not True
        or conditional.get("condition", {}).get("await", {}).get("arg") != "ready"
        or then_for.get("local", {}).get("name") != "value"
        or then_for.get("item", {}).get("concat", [{}])[0].get("string") != prefix
        or then_for.get("source", {}).get("arg") != "extra"
        or else_for.get("source", {}).get("arg") != "extra"
        or else_for.get("item", {}).get("concat", [{}])[0].get("string") != prefix
    ):
        raise SystemExit(f"expected mapped list_for_in chain for {member}, got {source}")
    require_switch_spread(
        then_add_all.get("spread", {}),
        None,
        f"{prefix.replace('-for-', '-premium')}",
    )


def assert_guarded_list(member, prefix, await_then=False):
    source = source_for(member)
    arg = returned_arg(source)
    if await_then:
        let = arg.get("let", {})
        locals = let.get("locals", [])
        if (
            len(locals) != 1
            or locals[0].get("name") != "enabled"
            or locals[0].get("value", {}).get("await", {}).get("arg") != "ready"
        ):
            raise SystemExit(f"expected await-then enabled local for {member}, got {source}")
        body = let.get("body", {})
        expected_condition = {"let_local": 0}
    else:
        body = arg
        expected_condition = {"await": {"arg": "ready"}}
    conditional = body.get("conditional", {})
    then_for = conditional.get("then", {}).get("list_for_in", {})
    else_for = conditional.get("else", {}).get("list_for_in", {})
    then_add_all = then_for.get("receiver", {}).get("list_add_all", {})
    if (
        source.get("async_future") is not True
        or conditional.get("condition") != expected_condition
        or then_for.get("local", {}).get("name") != "value"
        or then_for.get("item", {}).get("concat", [{}])[0].get("string") != prefix
        or then_for.get("source", {}).get("arg") != "extra"
        or else_for.get("source", {}).get("arg") != "extra"
        or else_for.get("item", {}).get("concat", [{}])[0].get("string") != prefix
    ):
        raise SystemExit(f"expected guarded mapped list_for_in chain for {member}, got {source}")
    base = prefix.replace("-for-", "-")
    require_guarded_switch_spread(
        then_add_all.get("spread", {}),
        None,
        f"{base}gold",
        f"{base}vip",
    )


def assert_await_then_list(member, prefix, has_finally=False):
    source = source_for(member)
    arg = returned_arg(source)
    let = arg.get("let", {})
    locals = let.get("locals", [])
    if (
        len(locals) != 1
        or locals[0].get("name") != "enabled"
        or locals[0].get("value", {}).get("await", {}).get("arg") != "ready"
    ):
        raise SystemExit(f"expected await-then enabled local for {member}, got {source}")
    body = let.get("body", {})
    if has_finally:
        seq = body.get("seq", [])
        try_finally = seq[0].get("try_finally", {}) if seq else {}
        body = try_finally.get("body", {})
        if f"{prefix.replace('-for-', '-cleanup')}" not in json.dumps(
            try_finally.get("finally", {})
        ):
            raise SystemExit(f"expected finalizer cleanup for {member}, got {source}")
    conditional = body.get("conditional", {})
    then_for = conditional.get("then", {}).get("list_for_in", {})
    else_for = conditional.get("else", {}).get("list_for_in", {})
    then_add_all = then_for.get("receiver", {}).get("list_add_all", {})
    if (
        source.get("async_future") is not True
        or conditional.get("condition", {}).get("let_local") != 0
        or then_for.get("local", {}).get("name") != "value"
        or then_for.get("item", {}).get("concat", [{}])[0].get("string") != prefix
        or then_for.get("source", {}).get("arg") != "extra"
        or else_for.get("source", {}).get("arg") != "extra"
        or else_for.get("item", {}).get("concat", [{}])[0].get("string") != prefix
    ):
        raise SystemExit(
            f"expected await-then mapped list_for_in chain for {member}, got {source}"
        )
    require_switch_spread(
        then_add_all.get("spread", {}),
        None,
        f"{prefix.replace('-for-', '-premium')}",
    )


def assert_double_await_list(member, prefix, has_finally=False):
    source = source_for(member)
    arg = returned_arg(source)
    let = arg.get("let", {})
    locals = let.get("locals", [])
    if (
        len(locals) != 2
        or locals[0].get("name") != "enabled"
        or locals[0].get("value", {}).get("await", {}).get("arg") != "ready"
        or locals[1].get("name") != "selectedTier"
        or locals[1].get("value", {}).get("await", {}).get("arg") != "tierReady"
    ):
        raise SystemExit(f"expected double-await locals for {member}, got {source}")
    body = let.get("body", {})
    if has_finally:
        seq = body.get("seq", [])
        try_finally = seq[0].get("try_finally", {}) if seq else {}
        body = try_finally.get("body", {})
        if f"{prefix.replace('-for-', '-cleanup')}" not in json.dumps(
            try_finally.get("finally", {})
        ):
            raise SystemExit(f"expected finalizer cleanup for {member}, got {source}")
    conditional = body.get("conditional", {})
    then_for = conditional.get("then", {}).get("list_for_in", {})
    else_for = conditional.get("else", {}).get("list_for_in", {})
    then_add_all = then_for.get("receiver", {}).get("list_add_all", {})
    switch_text = json.dumps(then_add_all.get("spread", {}))
    if (
        source.get("async_future") is not True
        or conditional.get("condition", {}).get("let_local") != 0
        or '"let_local": 1' not in switch_text
        or then_for.get("local", {}).get("name") != "value"
        or then_for.get("item", {}).get("concat", [{}])[0].get("string") != prefix
        or then_for.get("source", {}).get("arg") != "extra"
        or else_for.get("source", {}).get("arg") != "extra"
        or else_for.get("item", {}).get("concat", [{}])[0].get("string") != prefix
    ):
        raise SystemExit(
            f"expected double-await mapped list_for_in chain for {member}, got {source}"
        )
    require_switch_spread(
        then_add_all.get("spread", {}),
        None,
        f"{prefix.replace('-for-', '-premium')}",
    )


def assert_double_await_guarded_list(member, prefix):
    source = source_for(member)
    arg = returned_arg(source)
    let = arg.get("let", {})
    locals = let.get("locals", [])
    if (
        len(locals) != 2
        or locals[0].get("name") != "enabled"
        or locals[0].get("value", {}).get("await", {}).get("arg") != "ready"
        or locals[1].get("name") != "selectedTier"
        or locals[1].get("value", {}).get("await", {}).get("arg") != "tierReady"
    ):
        raise SystemExit(f"expected double-await locals for {member}, got {source}")
    conditional = let.get("body", {}).get("conditional", {})
    then_for = conditional.get("then", {}).get("list_for_in", {})
    else_for = conditional.get("else", {}).get("list_for_in", {})
    then_add_all = then_for.get("receiver", {}).get("list_add_all", {})
    switch_text = json.dumps(then_add_all.get("spread", {}))
    if (
        source.get("async_future") is not True
        or conditional.get("condition", {}).get("let_local") != 0
        or '"let_local": 1' not in switch_text
        or then_for.get("local", {}).get("name") != "value"
        or then_for.get("item", {}).get("concat", [{}])[0].get("string") != prefix
        or then_for.get("source", {}).get("arg") != "extra"
        or else_for.get("source", {}).get("arg") != "extra"
        or else_for.get("item", {}).get("concat", [{}])[0].get("string") != prefix
    ):
        raise SystemExit(
            f"expected double-await guarded mapped list_for_in chain for {member}, got {source}"
        )
    base = prefix.replace("-for-", "-")
    require_guarded_switch_spread(
        then_add_all.get("spread", {}),
        None,
        f"{base}gold",
        f"{base}vip",
    )


def assert_map(member, prefix, has_catch=False):
    source = source_for(member)
    arg = returned_arg(source)
    if has_catch:
        try_catch = arg.get("try_catch", {})
        body = try_catch.get("body", {})
        if "patched-collection-switch-try-catch-map-caught-" not in json.dumps(
            try_catch.get("catch", {})
        ):
            raise SystemExit(f"expected catch map for {member}, got {source}")
    else:
        body = arg
    conditional = body.get("conditional", {})
    then_for = conditional.get("then", {}).get("map_for_in", {})
    else_for = conditional.get("else", {}).get("map_for_in", {})
    then_add_all = then_for.get("receiver", {}).get("map_add_all", {})
    key_concat = then_for.get("key", {}).get("concat", [])
    value_get = then_for.get("value", {}).get("get_field", {})
    if (
        source.get("async_future") is not True
        or conditional.get("condition", {}).get("await", {}).get("arg") != "ready"
        or then_for.get("local", {}).get("name") != "entry"
        or key_concat[0].get("string") != prefix
        or value_get.get("field") != "value"
        or then_for.get("source", {}).get("call_dynamic", {}).get("method")
        != "get:entries"
        or else_for.get("source", {}).get("call_dynamic", {}).get("method")
        != "get:entries"
    ):
        raise SystemExit(f"expected mapped map_for_in chain for {member}, got {source}")
    require_switch_spread(
        then_add_all.get("spread", {}),
        "state",
        f"{prefix.replace('-for-', '-premium')}",
    )


def assert_guarded_map(member, prefix, await_then=False):
    source = source_for(member)
    arg = returned_arg(source)
    if await_then:
        let = arg.get("let", {})
        locals = let.get("locals", [])
        if (
            len(locals) != 1
            or locals[0].get("name") != "enabled"
            or locals[0].get("value", {}).get("await", {}).get("arg") != "ready"
        ):
            raise SystemExit(f"expected await-then enabled local for {member}, got {source}")
        body = let.get("body", {})
        expected_condition = {"let_local": 0}
    else:
        body = arg
        expected_condition = {"await": {"arg": "ready"}}
    conditional = body.get("conditional", {})
    then_for = conditional.get("then", {}).get("map_for_in", {})
    else_for = conditional.get("else", {}).get("map_for_in", {})
    then_add_all = then_for.get("receiver", {}).get("map_add_all", {})
    key_concat = then_for.get("key", {}).get("concat", [])
    value_get = then_for.get("value", {}).get("get_field", {})
    if (
        source.get("async_future") is not True
        or conditional.get("condition") != expected_condition
        or then_for.get("local", {}).get("name") != "entry"
        or key_concat[0].get("string") != prefix
        or value_get.get("field") != "value"
        or then_for.get("source", {}).get("call_dynamic", {}).get("method")
        != "get:entries"
        or else_for.get("source", {}).get("call_dynamic", {}).get("method")
        != "get:entries"
    ):
        raise SystemExit(f"expected guarded mapped map_for_in chain for {member}, got {source}")
    base = prefix.replace("-for-", "-")
    require_guarded_switch_spread(
        then_add_all.get("spread", {}),
        "state",
        f"{base}gold",
        f"{base}vip",
    )


def assert_await_then_map(member, prefix, has_catch=False):
    source = source_for(member)
    arg = returned_arg(source)
    let = arg.get("let", {})
    locals = let.get("locals", [])
    if (
        len(locals) != 1
        or locals[0].get("name") != "enabled"
        or locals[0].get("value", {}).get("await", {}).get("arg") != "ready"
    ):
        raise SystemExit(f"expected await-then enabled local for {member}, got {source}")
    body = let.get("body", {})
    if has_catch:
        seq = body.get("seq", [])
        try_catch = seq[0].get("try_catch", {}) if seq else {}
        body = try_catch.get("body", {})
        if f"{prefix.replace('-for-', '-caught-')}" not in json.dumps(
            try_catch.get("catch", {})
        ):
            raise SystemExit(f"expected catch map for {member}, got {source}")
    conditional = body.get("conditional", {})
    then_for = conditional.get("then", {}).get("map_for_in", {})
    else_for = conditional.get("else", {}).get("map_for_in", {})
    then_add_all = then_for.get("receiver", {}).get("map_add_all", {})
    key_concat = then_for.get("key", {}).get("concat", [])
    value_get = then_for.get("value", {}).get("get_field", {})
    if (
        source.get("async_future") is not True
        or conditional.get("condition", {}).get("let_local") != 0
        or then_for.get("local", {}).get("name") != "entry"
        or key_concat[0].get("string") != prefix
        or value_get.get("field") != "value"
        or then_for.get("source", {}).get("call_dynamic", {}).get("method")
        != "get:entries"
        or else_for.get("source", {}).get("call_dynamic", {}).get("method")
        != "get:entries"
    ):
        raise SystemExit(
            f"expected await-then mapped map_for_in chain for {member}, got {source}"
        )
    require_switch_spread(
        then_add_all.get("spread", {}),
        "state",
        f"{prefix.replace('-for-', '-premium')}",
    )


def assert_double_await_map(member, prefix, has_catch=False):
    source = source_for(member)
    arg = returned_arg(source)
    let = arg.get("let", {})
    locals = let.get("locals", [])
    if (
        len(locals) != 2
        or locals[0].get("name") != "enabled"
        or locals[0].get("value", {}).get("await", {}).get("arg") != "ready"
        or locals[1].get("name") != "selectedTier"
        or locals[1].get("value", {}).get("await", {}).get("arg") != "tierReady"
    ):
        raise SystemExit(f"expected double-await locals for {member}, got {source}")
    body = let.get("body", {})
    if has_catch:
        seq = body.get("seq", [])
        try_catch = seq[0].get("try_catch", {}) if seq else {}
        body = try_catch.get("body", {})
        if f"{prefix.replace('-for-', '-caught-')}" not in json.dumps(
            try_catch.get("catch", {})
        ):
            raise SystemExit(f"expected catch map for {member}, got {source}")
    conditional = body.get("conditional", {})
    then_for = conditional.get("then", {}).get("map_for_in", {})
    else_for = conditional.get("else", {}).get("map_for_in", {})
    then_add_all = then_for.get("receiver", {}).get("map_add_all", {})
    key_concat = then_for.get("key", {}).get("concat", [])
    value_get = then_for.get("value", {}).get("get_field", {})
    switch_text = json.dumps(then_add_all.get("spread", {}))
    if (
        source.get("async_future") is not True
        or conditional.get("condition", {}).get("let_local") != 0
        or '"let_local": 1' not in switch_text
        or then_for.get("local", {}).get("name") != "entry"
        or key_concat[0].get("string") != prefix
        or value_get.get("field") != "value"
        or then_for.get("source", {}).get("call_dynamic", {}).get("method")
        != "get:entries"
        or else_for.get("source", {}).get("call_dynamic", {}).get("method")
        != "get:entries"
    ):
        raise SystemExit(
            f"expected double-await mapped map_for_in chain for {member}, got {source}"
        )
    require_switch_spread(
        then_add_all.get("spread", {}),
        "state",
        f"{prefix.replace('-for-', '-premium')}",
    )


def assert_double_await_guarded_map(member, prefix):
    source = source_for(member)
    arg = returned_arg(source)
    let = arg.get("let", {})
    locals = let.get("locals", [])
    if (
        len(locals) != 2
        or locals[0].get("name") != "enabled"
        or locals[0].get("value", {}).get("await", {}).get("arg") != "ready"
        or locals[1].get("name") != "selectedTier"
        or locals[1].get("value", {}).get("await", {}).get("arg") != "tierReady"
    ):
        raise SystemExit(f"expected double-await locals for {member}, got {source}")
    conditional = let.get("body", {}).get("conditional", {})
    then_for = conditional.get("then", {}).get("map_for_in", {})
    else_for = conditional.get("else", {}).get("map_for_in", {})
    then_add_all = then_for.get("receiver", {}).get("map_add_all", {})
    key_concat = then_for.get("key", {}).get("concat", [])
    value_get = then_for.get("value", {}).get("get_field", {})
    switch_text = json.dumps(then_add_all.get("spread", {}))
    if (
        source.get("async_future") is not True
        or conditional.get("condition", {}).get("let_local") != 0
        or '"let_local": 1' not in switch_text
        or then_for.get("local", {}).get("name") != "entry"
        or key_concat[0].get("string") != prefix
        or value_get.get("field") != "value"
        or then_for.get("source", {}).get("call_dynamic", {}).get("method")
        != "get:entries"
        or else_for.get("source", {}).get("call_dynamic", {}).get("method")
        != "get:entries"
    ):
        raise SystemExit(
            f"expected double-await guarded mapped map_for_in chain for {member}, got {source}"
        )
    base = prefix.replace("-for-", "-")
    require_guarded_switch_spread(
        then_add_all.get("spread", {}),
        "state",
        f"{base}gold",
        f"{base}vip",
    )


assert_list(
    "asyncCollectionSwitchSpreadNames",
    "patched-collection-switch-list-for-",
)
assert_map(
    "asyncCollectionSwitchSpreadLabels",
    "patched-collection-switch-map-for-",
)
assert_guarded_list(
    "asyncCollectionGuardedSwitchSpreadNames",
    "patched-collection-guarded-switch-list-for-",
)
assert_guarded_map(
    "asyncCollectionGuardedSwitchSpreadLabels",
    "patched-collection-guarded-switch-map-for-",
)
assert_list(
    "asyncCollectionSwitchTryFinallyNames",
    "patched-collection-switch-try-finally-list-for-",
    has_finally=True,
)
assert_map(
    "asyncCollectionSwitchTryCatchLabels",
    "patched-collection-switch-try-catch-map-for-",
    has_catch=True,
)
assert_switch_try_catch_finally_await(
    "asyncCollectionSwitchTryCatchFinallyAwaitNames",
    ["ready", "tier", "recovery", "cleanup", "extra"],
    [
        "patched-collection-switch-try-catch-finally-await-list-head",
        "patched-collection-switch-try-catch-finally-await-list-caught-",
        "patched-collection-switch-try-catch-finally-await-list-cleanup-",
        '"await": {"arg": "ready"}',
        '"await": {"arg": "recovery"}',
        '"await": {"arg": "cleanup"}',
    ],
    3,
)
assert_switch_try_catch_finally_await(
    "asyncCollectionSwitchTryCatchFinallyAwaitLabels",
    ["ready", "tier", "recovery", "cleanup", "extra"],
    [
        "patched-collection-switch-try-catch-finally-await-map-head",
        "patched-collection-switch-try-catch-finally-await-map-caught-",
        "patched-collection-switch-try-catch-finally-await-map-cleanup-",
        '"await": {"arg": "ready"}',
        '"await": {"arg": "recovery"}',
        '"await": {"arg": "cleanup"}',
    ],
    3,
)
assert_await_then_list(
    "asyncAwaitThenCollectionSwitchSpreadNames",
    "patched-await-then-collection-switch-list-for-",
)
assert_await_then_map(
    "asyncAwaitThenCollectionSwitchSpreadLabels",
    "patched-await-then-collection-switch-map-for-",
)
assert_guarded_list(
    "asyncAwaitThenCollectionGuardedSwitchSpreadNames",
    "patched-await-then-collection-guarded-switch-list-for-",
    await_then=True,
)
assert_guarded_map(
    "asyncAwaitThenCollectionGuardedSwitchSpreadLabels",
    "patched-await-then-collection-guarded-switch-map-for-",
    await_then=True,
)
assert_await_then_list(
    "asyncAwaitThenCollectionSwitchTryFinallyNames",
    "patched-await-then-collection-switch-try-finally-list-for-",
    has_finally=True,
)
assert_await_then_map(
    "asyncAwaitThenCollectionSwitchTryCatchLabels",
    "patched-await-then-collection-switch-try-catch-map-for-",
    has_catch=True,
)
assert_double_await_list(
    "asyncDoubleAwaitCollectionSwitchSpreadNames",
    "patched-double-await-collection-switch-list-for-",
)
assert_double_await_map(
    "asyncDoubleAwaitCollectionSwitchSpreadLabels",
    "patched-double-await-collection-switch-map-for-",
)
assert_double_await_guarded_list(
    "asyncDoubleAwaitCollectionGuardedSwitchSpreadNames",
    "patched-double-await-collection-guarded-switch-list-for-",
)
assert_double_await_guarded_map(
    "asyncDoubleAwaitCollectionGuardedSwitchSpreadLabels",
    "patched-double-await-collection-guarded-switch-map-for-",
)
assert_double_await_list(
    "asyncDoubleAwaitCollectionSwitchTryFinallyNames",
    "patched-double-await-collection-switch-try-finally-list-for-",
    has_finally=True,
)
assert_double_await_map(
    "asyncDoubleAwaitCollectionSwitchTryCatchLabels",
    "patched-double-await-collection-switch-try-catch-map-for-",
    has_catch=True,
)
assert_switch_try_catch_finally_await(
    "asyncDoubleAwaitCollectionSwitchTryCatchFinallyAwaitNames",
    ["ready", "tierReady", "recovery", "cleanup", "extra"],
    [
        "patched-double-await-collection-switch-try-catch-finally-await-list-head",
        "patched-double-await-collection-switch-try-catch-finally-await-list-caught-",
        "patched-double-await-collection-switch-try-catch-finally-await-list-cleanup-",
        '"name": "enabled"',
        '"name": "selectedTier"',
        '"await": {"arg": "ready"}',
        '"await": {"arg": "tierReady"}',
        '"await": {"arg": "recovery"}',
        '"await": {"arg": "cleanup"}',
    ],
    4,
)
assert_switch_try_catch_finally_await(
    "asyncDoubleAwaitCollectionSwitchTryCatchFinallyAwaitLabels",
    ["ready", "tierReady", "recovery", "cleanup", "extra"],
    [
        "patched-double-await-collection-switch-try-catch-finally-await-map-head",
        "patched-double-await-collection-switch-try-catch-finally-await-map-caught-",
        "patched-double-await-collection-switch-try-catch-finally-await-map-cleanup-",
        '"name": "enabled"',
        '"name": "selectedTier"',
        '"await": {"arg": "ready"}',
        '"await": {"arg": "tierReady"}',
        '"await": {"arg": "recovery"}',
        '"await": {"arg": "cleanup"}',
    ],
    4,
)
