def assert_async_loop_switch_sources(patch_by_member):
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

    def contains(value, predicate):
        if predicate(value):
            return True
        if isinstance(value, dict):
            return any(contains(item, predicate) for item in value.values())
        if isinstance(value, list):
            return any(contains(item, predicate) for item in value)
        return False

    def has_string(value, text):
        return contains(
            value,
            lambda item: isinstance(item, dict) and item.get("string") == text,
        )

    def has_switch_assign(value, text):
        return contains(
            value,
            lambda item: isinstance(item, dict)
            and item.get("set_local", {}).get("value", {}).get("string") == text,
        )

    def has_while_loop(value):
        return contains(value, lambda item: isinstance(item, dict) and "while_loop" in item)

    def has_node(value, key):
        return contains(value, lambda item: isinstance(item, dict) and key in item)

    def assert_common(member, assigned_gold):
        source = source_for(member)
        arg = source.get("body", {}).get("new_object", {}).get("args", [{}])[0]
        if (
            source.get("async_future") is not True
            or not has_while_loop(arg)
            or not has_switch_assign(arg, assigned_gold)
            or not contains(
                arg,
                lambda item: isinstance(item, dict)
                and item.get("conditional", {}).get("condition", {}).get("op") == "==",
            )
        ):
            raise SystemExit(f"expected {member} loop + switch assignment source, got {source}")
        return source, arg

    assert_common("asyncWhileSwitchAssignedLabel", "patched-while-switch-gold")

    _, await_condition_arg = assert_common(
        "asyncWhileAwaitConditionSwitchAssignedLabel",
        "patched-while-await-switch-gold",
    )
    if not contains(
        await_condition_arg,
        lambda item: isinstance(item, dict)
        and item.get("while_loop", {}).get("condition", {}).get("await", {}).get("arg")
        == "keepGoing",
    ):
        raise SystemExit(
            "expected asyncWhileAwaitConditionSwitchAssignedLabel await condition source, "
            f"got {await_condition_arg}"
        )

    assert_common("asyncForSwitchAssignedLabel", "patched-for-switch-gold")

    _, await_update_arg = assert_common(
        "asyncForAwaitUpdateSwitchAssignedLabel",
        "patched-for-await-update-switch-gold",
    )
    if not contains(
        await_update_arg,
        lambda item: isinstance(item, dict)
        and item.get("set_local", {}).get("value", {}).get("await", {}).get("arg")
        == "next",
    ):
        raise SystemExit(
            "expected asyncForAwaitUpdateSwitchAssignedLabel await update source, "
            f"got {await_update_arg}"
        )

    list_source, list_arg = assert_common(
        "asyncForSwitchAssignedListNames",
        "patched-for-switch-list-gold",
    )
    if (
        list_source.get("body", {}).get("new_object", {}).get("type_args")
        != ["List<String>"]
        or not contains(list_arg, lambda item: isinstance(item, dict) and "list" in item)
        or not has_string(list_arg, "patched-for-switch-list-tail")
    ):
        raise SystemExit(f"expected asyncForSwitchAssignedListNames list tail source, got {list_source}")

    map_source, map_arg = assert_common(
        "asyncForSwitchAssignedMapLabels",
        "patched-for-switch-map-seven",
    )
    if (
        map_source.get("body", {}).get("new_object", {}).get("type_args")
        not in (["Map<String, String>"], ["Map<String,String>"])
        or not contains(map_arg, lambda item: isinstance(item, dict) and "map" in item)
    ):
        raise SystemExit(f"expected asyncForSwitchAssignedMapLabels map tail source, got {map_source}")

    assert_common("asyncDoWhileSwitchAssignedLabel", "patched-do-while-switch-gold")

    _, nested_arg = assert_common(
        "asyncWhileNestedBranchSwitchAssignedLabel",
        "patched-while-nested-switch-gold",
    )
    if not contains(
        nested_arg,
        lambda item: isinstance(item, dict)
        and item.get("conditional", {}).get("condition", {}).get("arg") == "enabled",
    ):
        raise SystemExit(
            "expected asyncWhileNestedBranchSwitchAssignedLabel nested branch source, "
            f"got {nested_arg}"
        )

    _, for_try_catch_arg = assert_common(
        "asyncForTryCatchSwitchAssignedLabel",
        "patched-for-try-catch-switch-gold",
    )
    if not has_node(for_try_catch_arg, "try_catch") or not has_string(
        for_try_catch_arg,
        "patched-for-try-catch-switch-other-",
    ):
        raise SystemExit(
            "expected asyncForTryCatchSwitchAssignedLabel try/catch source, "
            f"got {for_try_catch_arg}"
        )

    _, for_try_finally_arg = assert_common(
        "asyncForAwaitUpdateTryFinallySwitchAssignedLabel",
        "patched-for-await-update-try-finally-switch-gold",
    )
    if (
        not has_node(for_try_finally_arg, "try_finally")
        or not has_string(for_try_finally_arg, "patched-for-await-update-try-finally-switch-gold")
        or not contains(
            for_try_finally_arg,
            lambda item: isinstance(item, dict)
            and item.get("set_local", {}).get("value", {}).get("await", {}).get("arg")
            == "next",
        )
        or not contains(
            for_try_finally_arg,
            lambda item: isinstance(item, dict)
            and item.get("locals", [{}])[-1].get("value", {}).get("await", {}).get("arg")
            == "cleanup",
        )
    ):
        raise SystemExit(
            "expected asyncForAwaitUpdateTryFinallySwitchAssignedLabel await update "
            f"+ try/finally source, got {for_try_finally_arg}"
        )

    _, while_try_catch_arg = assert_common(
        "asyncWhileAwaitConditionTryCatchSwitchAssignedLabel",
        "patched-while-await-condition-try-catch-switch-gold",
    )
    if (
        not has_node(while_try_catch_arg, "try_catch")
        or not has_string(
            while_try_catch_arg,
            "patched-while-await-condition-try-catch-switch-other-",
        )
        or not contains(
            while_try_catch_arg,
            lambda item: isinstance(item, dict)
            and item.get("while_loop", {}).get("condition", {}).get("await", {}).get("arg")
            == "keepGoing",
        )
    ):
        raise SystemExit(
            "expected asyncWhileAwaitConditionTryCatchSwitchAssignedLabel await condition "
            f"+ try/catch source, got {while_try_catch_arg}"
        )

    _, do_try_finally_arg = assert_common(
        "asyncDoWhileTryFinallySwitchAssignedLabel",
        "patched-do-while-try-finally-switch-gold",
    )
    if not has_node(do_try_finally_arg, "try_finally") or not contains(
        do_try_finally_arg,
        lambda item: isinstance(item, dict)
        and item.get("locals", [{}])[-1].get("value", {}).get("await", {}).get("arg")
        == "cleanup",
    ):
        raise SystemExit(
            "expected asyncDoWhileTryFinallySwitchAssignedLabel try/finally source, "
            f"got {do_try_finally_arg}"
        )
