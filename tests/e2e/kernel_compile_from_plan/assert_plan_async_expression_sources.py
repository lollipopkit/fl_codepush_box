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
