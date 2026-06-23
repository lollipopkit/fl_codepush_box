import json


def assert_async_expression_sources(patch_by_member):
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
        raise SystemExit(
            f"expected asyncIfElseSideEffectTail side-effect if/else + tail source, got {async_ifelse_side_effect}"
        )

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

    async_conditional_both_await = patch_by_member.get("asyncConditionalBothAwaitExpr", {}).get(
        "bytecode_source", {}
    )
    async_conditional_both_arg = async_conditional_both_await.get("body", {}).get("new_object", {}).get(
        "args", [{}]
    )[0]
    async_conditional_both = async_conditional_both_arg.get("conditional", {})
    if (
        async_conditional_both_await.get("async_future") is not True
        or async_conditional_both_await.get("body", {}).get("new_object", {}).get("type_args") != ["String"]
        or async_conditional_both.get("condition", {}).get("arg") != "enabled"
        or async_conditional_both.get("then", {}).get("await", {}).get("arg") != "ready"
        or async_conditional_both.get("else", {}).get("await", {}).get("arg") != "fallback"
    ):
        raise SystemExit(
            f"expected asyncConditionalBothAwaitExpr conditional both-await source, got {async_conditional_both_await}"
        )

    async_await_condition_conditional_both = patch_by_member.get(
        "asyncAwaitConditionConditionalBothAwaitExpr", {}
    ).get("bytecode_source", {})
    async_await_condition_arg = async_await_condition_conditional_both.get("body", {}).get(
        "new_object", {}
    ).get("args", [{}])[0]
    async_await_condition_conditional = async_await_condition_arg.get("conditional", {})
    if (
        async_await_condition_conditional_both.get("async_future") is not True
        or async_await_condition_conditional_both.get("body", {}).get("new_object", {}).get("type_args") != [
            "String"
        ]
        or async_await_condition_conditional.get("condition", {}).get("await", {}).get("arg") != "enabled"
        or async_await_condition_conditional.get("then", {}).get("await", {}).get("arg") != "ready"
        or async_await_condition_conditional.get("else", {}).get("await", {}).get("arg") != "fallback"
    ):
        raise SystemExit(
            "expected asyncAwaitConditionConditionalBothAwaitExpr await-condition both-await source, got "
            f"{async_await_condition_conditional_both}"
        )

    async_nested_conditional_await = patch_by_member.get("asyncNestedConditionalAwaitExpr", {}).get(
        "bytecode_source", {}
    )
    async_nested_arg = async_nested_conditional_await.get("body", {}).get("new_object", {}).get("args", [{}])[0]
    async_nested = async_nested_arg.get("conditional", {})
    async_nested_then = async_nested.get("then", {}).get("conditional", {})
    if (
        async_nested_conditional_await.get("async_future") is not True
        or async_nested_conditional_await.get("body", {}).get("new_object", {}).get("type_args") != ["String"]
        or async_nested.get("condition", {}).get("arg") != "enabled"
        or async_nested_then.get("condition", {}).get("arg") != "premium"
        or async_nested_then.get("then", {}).get("await", {}).get("arg") != "ready"
        or async_nested_then.get("else", {}).get("await", {}).get("arg") != "fallback"
        or async_nested.get("else", {}).get("await", {}).get("arg") != "disabled"
    ):
        raise SystemExit(
            f"expected asyncNestedConditionalAwaitExpr nested conditional await source, got {async_nested_conditional_await}"
        )

    async_await_condition_nested_conditional = patch_by_member.get(
        "asyncAwaitConditionNestedConditionalAwaitExpr", {}
    ).get("bytecode_source", {})
    async_await_condition_nested_arg = async_await_condition_nested_conditional.get("body", {}).get(
        "new_object", {}
    ).get("args", [{}])[0]
    async_await_condition_nested = async_await_condition_nested_arg.get("conditional", {})
    async_await_condition_nested_then = async_await_condition_nested.get("then", {}).get("conditional", {})
    if (
        async_await_condition_nested_conditional.get("async_future") is not True
        or async_await_condition_nested_conditional.get("body", {}).get("new_object", {}).get("type_args") != [
            "String"
        ]
        or async_await_condition_nested.get("condition", {}).get("await", {}).get("arg") != "enabled"
        or async_await_condition_nested_then.get("condition", {}).get("arg") != "premium"
        or async_await_condition_nested_then.get("then", {}).get("await", {}).get("arg") != "ready"
        or async_await_condition_nested_then.get("else", {}).get("await", {}).get("arg") != "fallback"
        or async_await_condition_nested.get("else", {}).get("await", {}).get("arg") != "disabled"
    ):
        raise SystemExit(
            "expected asyncAwaitConditionNestedConditionalAwaitExpr await-condition nested conditional source, got "
            f"{async_await_condition_nested_conditional}"
        )

    async_logical_and_left = patch_by_member.get("asyncLogicalAndAwaitLeft", {}).get("bytecode_source", {})
    async_logical_and_left_arg = async_logical_and_left.get("body", {}).get("new_object", {}).get("args", [{}])[0]
    async_logical_and_left_condition = async_logical_and_left_arg.get("conditional", {})
    if (
        async_logical_and_left.get("async_future") is not True
        or async_logical_and_left.get("body", {}).get("new_object", {}).get("type_args") != ["bool"]
        or async_logical_and_left_condition.get("condition", {}).get("await", {}).get("arg") != "ready"
        or async_logical_and_left_condition.get("then", {}).get("arg") != "fallback"
        or async_logical_and_left_condition.get("else", {}).get("bool") is not False
    ):
        raise SystemExit(f"expected asyncLogicalAndAwaitLeft logical await source, got {async_logical_and_left}")

    async_logical_and_right = patch_by_member.get("asyncLogicalAndAwaitRight", {}).get("bytecode_source", {})
    async_logical_and_right_arg = async_logical_and_right.get("body", {}).get("new_object", {}).get("args", [{}])[0]
    async_logical_and_right_condition = async_logical_and_right_arg.get("conditional", {})
    if (
        async_logical_and_right.get("async_future") is not True
        or async_logical_and_right.get("body", {}).get("new_object", {}).get("type_args") != ["bool"]
        or async_logical_and_right_condition.get("condition", {}).get("arg") != "enabled"
        or async_logical_and_right_condition.get("then", {}).get("await", {}).get("arg") != "ready"
        or async_logical_and_right_condition.get("else", {}).get("bool") is not False
    ):
        raise SystemExit(f"expected asyncLogicalAndAwaitRight logical await source, got {async_logical_and_right}")

    async_logical_or_left = patch_by_member.get("asyncLogicalOrAwaitLeft", {}).get("bytecode_source", {})
    async_logical_or_left_arg = async_logical_or_left.get("body", {}).get("new_object", {}).get("args", [{}])[0]
    async_logical_or_left_condition = async_logical_or_left_arg.get("conditional", {})
    if (
        async_logical_or_left.get("async_future") is not True
        or async_logical_or_left.get("body", {}).get("new_object", {}).get("type_args") != ["bool"]
        or async_logical_or_left_condition.get("condition", {}).get("await", {}).get("arg") != "ready"
        or async_logical_or_left_condition.get("then", {}).get("bool") is not True
        or async_logical_or_left_condition.get("else", {}).get("arg") != "fallback"
    ):
        raise SystemExit(f"expected asyncLogicalOrAwaitLeft logical await source, got {async_logical_or_left}")

    async_nested_logical = patch_by_member.get("asyncNestedLogicalAwait", {}).get("bytecode_source", {})
    async_nested_logical_arg = async_nested_logical.get("body", {}).get("new_object", {}).get("args", [{}])[0]
    async_nested_logical_condition = async_nested_logical_arg.get("conditional", {})
    async_nested_logical_then = async_nested_logical_condition.get("then", {}).get("conditional", {})
    if (
        async_nested_logical.get("async_future") is not True
        or async_nested_logical.get("body", {}).get("new_object", {}).get("type_args") != ["bool"]
        or async_nested_logical_condition.get("condition", {}).get("arg") != "enabled"
        or async_nested_logical_condition.get("else", {}).get("bool") is not False
        or async_nested_logical_then.get("condition", {}).get("await", {}).get("arg") != "ready"
        or async_nested_logical_then.get("then", {}).get("bool") is not True
        or async_nested_logical_then.get("else", {}).get("await", {}).get("arg") != "fallback"
    ):
        raise SystemExit(f"expected asyncNestedLogicalAwait nested logical await source, got {async_nested_logical}")

    def assert_logical_control(member, type_args, min_conditionals, min_awaits, constants):
        function = patch_by_member.get(member)
        if function is None:
            raise SystemExit(f"missing inventory entry for {member}")
        source = function.get("bytecode_source")
        source_json = json.dumps(source)
        if (
            function.get("unsupported_reasons") != []
            or not isinstance(source, dict)
            or source.get("async_future") is not True
            or source.get("body", {}).get("new_object", {}).get("type_args") != type_args
            or source_json.count('"conditional"') < min_conditionals
            or source_json.count('"await"') < min_awaits
            or any(f'"string": "{constant}"' not in source_json for constant in constants)
        ):
            raise SystemExit(f"expected {member} logical await control-flow source, got {function}")

    assert_logical_control(
        "asyncIfLogicalAndAwaitTail",
        ["String"],
        min_conditionals=2,
        min_awaits=1,
        constants=["patched-if-logical-and-await", "-on", "-tail"],
    )
    assert_logical_control(
        "asyncIfElseLogicalOrAwaitTail",
        ["String"],
        min_conditionals=2,
        min_awaits=1,
        constants=["patched-ifelse-logical-or-await", "-on", "-off", "-tail"],
    )
    assert_logical_control(
        "asyncIfNestedLogicalAwaitReturn",
        ["String"],
        min_conditionals=3,
        min_awaits=2,
        constants=["patched-if-nested-logical-await-on", "patched-if-nested-logical-await-off"],
    )
    assert_logical_control(
        "asyncWhileLogicalAwaitCondition",
        ["String"],
        min_conditionals=1,
        min_awaits=1,
        constants=["patched-while-logical-await-condition"],
    )
    assert_logical_control(
        "asyncDoWhileLogicalAwaitCondition",
        ["String"],
        min_conditionals=1,
        min_awaits=1,
        constants=["patched-do-logical-await-condition"],
    )
    assert_logical_control(
        "asyncForLogicalAwaitCondition",
        ["String"],
        min_conditionals=1,
        min_awaits=1,
        constants=["patched-for-logical-await-condition"],
    )
    assert_logical_control(
        "asyncIfTryFinallyLogicalAwaitTail",
        ["String"],
        min_conditionals=2,
        min_awaits=2,
        constants=["patched-if-try-finally-logical-await", "-cleanup-", "-tail"],
    )
    assert_logical_control(
        "asyncIfTryCatchLogicalAwaitTail",
        ["String"],
        min_conditionals=2,
        min_awaits=3,
        constants=["patched-if-try-catch-logical-await", "-caught-", "-tail"],
    )
    assert_logical_control(
        "asyncLogicalCollectionSpreadNames",
        ["List<String>"],
        min_conditionals=2,
        min_awaits=1,
        constants=[
            "patched-logical-collection-list-head",
            "patched-logical-collection-list-off",
            "patched-logical-collection-list-tail",
        ],
    )
    assert_logical_control(
        "asyncLogicalCollectionSpreadLabels",
        ["Map<String,String>"],
        min_conditionals=2,
        min_awaits=1,
        constants=[
            "patched-logical-collection-map-head",
            "patched-logical-collection-map-off",
            "patched-logical-collection-map-tail",
        ],
    )
    assert_logical_control(
        "asyncLogicalCollectionForNames",
        ["List<String>"],
        min_conditionals=2,
        min_awaits=1,
        constants=[
            "patched-logical-collection-for-list-head",
            "patched-logical-collection-for-list-",
            "patched-logical-collection-for-list-off",
        ],
    )
    assert_logical_control(
        "asyncLogicalCollectionForLabels",
        ["Map<String,String>"],
        min_conditionals=2,
        min_awaits=1,
        constants=[
            "patched-logical-collection-for-map-head",
            "patched-logical-collection-for-map-",
            "patched-logical-collection-for-map-off",
        ],
    )
    assert_logical_control(
        "asyncLogicalCollectionTryFinallyNames",
        ["List<String>"],
        min_conditionals=2,
        min_awaits=2,
        constants=[
            "patched-logical-collection-try-finally-list-head",
            "patched-logical-collection-try-finally-list-off",
            "patched-logical-collection-try-finally-list-cleanup-",
        ],
    )
    assert_logical_control(
        "asyncLogicalCollectionTryFinallyLabels",
        ["Map<String,String>"],
        min_conditionals=2,
        min_awaits=2,
        constants=[
            "patched-logical-collection-try-finally-map-head",
            "patched-logical-collection-try-finally-map-off",
            "patched-logical-collection-try-finally-map-cleanup-",
        ],
    )
    assert_logical_control(
        "asyncLogicalCollectionTryCatchNames",
        ["List<String>"],
        min_conditionals=2,
        min_awaits=2,
        constants=[
            "patched-logical-collection-try-catch-list-head",
            "patched-logical-collection-try-catch-list-",
            "patched-logical-collection-try-catch-list-caught-",
        ],
    )
    assert_logical_control(
        "asyncLogicalCollectionTryCatchLabels",
        ["Map<String,String>"],
        min_conditionals=2,
        min_awaits=2,
        constants=[
            "patched-logical-collection-try-catch-map-head",
            "patched-logical-collection-try-catch-map-",
            "patched-logical-collection-try-catch-map-caught-",
        ],
    )
    assert_logical_control(
        "asyncLogicalCollectionTryCatchFinallyNames",
        ["List<String>"],
        min_conditionals=2,
        min_awaits=3,
        constants=[
            "patched-logical-collection-try-catch-finally-list-head",
            "patched-logical-collection-try-catch-finally-list-",
            "patched-logical-collection-try-catch-finally-list-caught-",
            "patched-logical-collection-try-catch-finally-list-cleanup-",
        ],
    )
    assert_logical_control(
        "asyncLogicalCollectionTryCatchFinallyLabels",
        ["Map<String,String>"],
        min_conditionals=2,
        min_awaits=3,
        constants=[
            "patched-logical-collection-try-catch-finally-map-head",
            "patched-logical-collection-try-catch-finally-map-off",
            "patched-logical-collection-try-catch-finally-map-caught-",
            "patched-logical-collection-try-catch-finally-map-cleanup-",
        ],
    )

    async_less_than_await = patch_by_member.get("asyncLessThanAwaitTail", {}).get("bytecode_source", {})
    async_less_than_conditional = (
        async_less_than_await.get("body", {}).get("new_object", {}).get("args", [{}])[0].get("conditional", {})
    )
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
    async_less_equal_conditional = (
        async_less_equal_await.get("body", {}).get("new_object", {}).get("args", [{}])[0].get("conditional", {})
    )
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
    async_greater_equal_conditional = (
        async_greater_equal_await.get("body", {}).get("new_object", {}).get("args", [{}])[0].get("conditional", {})
    )
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
    async_not_equal_conditional = (
        async_not_equal_await.get("body", {}).get("new_object", {}).get("args", [{}])[0].get("conditional", {})
    )
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
