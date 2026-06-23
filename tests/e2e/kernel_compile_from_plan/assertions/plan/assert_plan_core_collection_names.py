def assert_core_collection_name_sources(source_for):
    async_dynamic_names_source = source_for("asyncDynamicNames")
    async_dynamic_names_arg = async_dynamic_names_source.get("body", {}).get("new_object", {}).get("args", [{}])[0]
    async_dynamic_names_add_all = async_dynamic_names_arg.get("list_add_all", {})
    if (
        async_dynamic_names_source.get("async_future") is not True
        or async_dynamic_names_source.get("body", {}).get("new_object", {}).get("type_args") != ["List<String>"]
        or async_dynamic_names_add_all.get("receiver", {}).get("list", [{}])[0].get("string") != "patched-async"
        or async_dynamic_names_add_all.get("spread", {}).get("arg") != "extra"
    ):
        raise SystemExit(f"expected asyncDynamicNames async list_add_all source, got {async_dynamic_names_source}")

    async_await_dynamic_names_source = source_for("asyncAwaitThenDynamicNames")
    async_await_dynamic_names_arg = async_await_dynamic_names_source.get("body", {}).get("new_object", {}).get(
        "args", [{}]
    )[0]
    async_await_dynamic_names_let = async_await_dynamic_names_arg.get("let", {})
    async_await_dynamic_names_locals = async_await_dynamic_names_let.get("locals", [])
    async_await_dynamic_names_add_all = async_await_dynamic_names_let.get("body", {}).get("list_add_all", {})
    async_await_dynamic_names_receiver = async_await_dynamic_names_add_all.get("receiver", {}).get("list", [])
    if (
        async_await_dynamic_names_source.get("async_future") is not True
        or async_await_dynamic_names_source.get("body", {}).get("new_object", {}).get("type_args") != ["List<String>"]
        or async_await_dynamic_names_source.get("params") != ["ready", "extra"]
        or len(async_await_dynamic_names_locals) != 1
        or async_await_dynamic_names_locals[0].get("name") != "value"
        or async_await_dynamic_names_locals[0].get("value", {}).get("await", {}).get("arg") != "ready"
        or async_await_dynamic_names_receiver != [{"string": "patched-await-dynamic"}]
        or async_await_dynamic_names_add_all.get("spread", {}).get("arg") != "extra"
    ):
        raise SystemExit(
            "expected asyncAwaitThenDynamicNames await/list_add_all source, "
            f"got {async_await_dynamic_names_source}"
        )

    async_names_source = source_for("asyncNames")
    async_names_arg = async_names_source.get("body", {}).get("new_object", {}).get("args", [{}])[0]
    async_names_premium = async_names_arg.get("conditional", {})
    async_names_premium_then = async_names_premium.get("then", {}).get("conditional", {}).get("then", {}).get(
        "list", []
    )
    async_names_premium_else = async_names_premium.get("else", {}).get("conditional", {}).get("else", {}).get(
        "list", []
    )
    if (
        async_names_source.get("async_future") is not True
        or async_names_source.get("body", {}).get("new_object", {}).get("type_args") != ["List<String>"]
        or async_names_premium.get("condition", {}).get("arg") != "premium"
        or len(async_names_premium_then) != 8
        or async_names_premium_then[0].get("string") != "patched-async-static"
        or async_names_premium_then[3].get("string") != "async-for-a"
        or async_names_premium_then[5].get("string") != "async-live"
        or async_names_premium_then[6].get("string") != "async-pro"
        or len(async_names_premium_else) != 7
        or async_names_premium_else[5].get("string") != "async-off"
    ):
        raise SystemExit(f"expected asyncNames async static collection source, got {async_names_source}")

    async_await_names_source = source_for("asyncAwaitThenNames")
    async_await_names_arg = async_await_names_source.get("body", {}).get("new_object", {}).get("args", [{}])[0]
    async_await_names_let = async_await_names_arg.get("let", {})
    async_await_names_locals = async_await_names_let.get("locals", [])
    async_await_names_list = async_await_names_let.get("body", {}).get("list", [])
    if (
        async_await_names_source.get("async_future") is not True
        or async_await_names_source.get("body", {}).get("new_object", {}).get("type_args") != ["List<String>"]
        or async_await_names_source.get("params") != ["ready"]
        or len(async_await_names_locals) != 1
        or async_await_names_locals[0].get("name") != "value"
        or async_await_names_locals[0].get("value", {}).get("await", {}).get("arg") != "ready"
        or async_await_names_list != [
            {"string": "patched-await-list"},
            {"let_local": 0},
            {"string": "patched-await-tail"},
        ]
    ):
        raise SystemExit(
            "expected asyncAwaitThenNames await/static list source, "
            f"got {async_await_names_source}"
        )

    async_await_conditional_names_source = source_for("asyncAwaitThenConditionalNames")
    async_await_conditional_names_arg = async_await_conditional_names_source.get("body", {}).get("new_object", {}).get(
        "args", [{}]
    )[0]
    async_await_conditional_names_let = async_await_conditional_names_arg.get("let", {})
    async_await_conditional_names_locals = async_await_conditional_names_let.get("locals", [])
    async_await_conditional_names_conditional = async_await_conditional_names_let.get("body", {}).get(
        "conditional", {}
    )
    async_await_conditional_names_then = async_await_conditional_names_conditional.get("then", {}).get("list", [])
    async_await_conditional_names_else = async_await_conditional_names_conditional.get("else", {}).get("list", [])
    if (
        async_await_conditional_names_source.get("async_future") is not True
        or async_await_conditional_names_source.get("body", {}).get("new_object", {}).get("type_args")
        != ["List<String>"]
        or async_await_conditional_names_source.get("params") != ["ready"]
        or len(async_await_conditional_names_locals) != 1
        or async_await_conditional_names_locals[0].get("name") != "enabled"
        or async_await_conditional_names_locals[0].get("value", {}).get("await", {}).get("arg") != "ready"
        or async_await_conditional_names_conditional.get("condition", {}).get("let_local") != 0
        or async_await_conditional_names_then != [
            {"string": "patched-await-if-head"},
            {"string": "patched-await-if-live"},
            {"string": "patched-await-if-tail"},
        ]
        or async_await_conditional_names_else != [
            {"string": "patched-await-if-head"},
            {"string": "patched-await-if-off"},
            {"string": "patched-await-if-tail"},
        ]
    ):
        raise SystemExit(
            "expected asyncAwaitThenConditionalNames await/collection-if source, "
            f"got {async_await_conditional_names_source}"
        )

    async_await_conditional_dynamic_names_source = source_for("asyncAwaitThenConditionalDynamicNames")
    async_await_conditional_dynamic_names_arg = async_await_conditional_dynamic_names_source.get("body", {}).get(
        "new_object", {}
    ).get("args", [{}])[0]
    async_await_conditional_dynamic_names_let = async_await_conditional_dynamic_names_arg.get("let", {})
    async_await_conditional_dynamic_names_locals = async_await_conditional_dynamic_names_let.get("locals", [])
    async_await_conditional_dynamic_names_conditional = async_await_conditional_dynamic_names_let.get("body", {}).get(
        "conditional", {}
    )
    async_await_conditional_dynamic_names_then = async_await_conditional_dynamic_names_conditional.get(
        "then", {}
    ).get("list_add_all", {})
    async_await_conditional_dynamic_names_else = async_await_conditional_dynamic_names_conditional.get(
        "else", {}
    ).get("list_add_all", {})
    if (
        async_await_conditional_dynamic_names_source.get("async_future") is not True
        or async_await_conditional_dynamic_names_source.get("body", {}).get("new_object", {}).get("type_args")
        != ["List<String>"]
        or async_await_conditional_dynamic_names_source.get("params") != ["ready", "extra"]
        or len(async_await_conditional_dynamic_names_locals) != 1
        or async_await_conditional_dynamic_names_locals[0].get("name") != "enabled"
        or async_await_conditional_dynamic_names_locals[0].get("value", {}).get("await", {}).get("arg") != "ready"
        or async_await_conditional_dynamic_names_conditional.get("condition", {}).get("let_local") != 0
        or async_await_conditional_dynamic_names_then.get("receiver", {}).get("list") != [
            {"string": "patched-await-if-dynamic-head"},
            {"string": "patched-await-if-dynamic-live"},
        ]
        or async_await_conditional_dynamic_names_then.get("spread", {}).get("arg") != "extra"
        or async_await_conditional_dynamic_names_else.get("receiver", {}).get("list") != [
            {"string": "patched-await-if-dynamic-head"},
            {"string": "patched-await-if-dynamic-off"},
        ]
        or async_await_conditional_dynamic_names_else.get("spread", {}).get("arg") != "extra"
    ):
        raise SystemExit(
            "expected asyncAwaitThenConditionalDynamicNames await/collection-if/list_add_all source, "
            f"got {async_await_conditional_dynamic_names_source}"
        )

    async_await_conditional_runtime_names_source = source_for("asyncAwaitThenConditionalRuntimeNames")
    async_await_conditional_runtime_names_arg = async_await_conditional_runtime_names_source.get("body", {}).get(
        "new_object", {}
    ).get("args", [{}])[0]
    async_await_conditional_runtime_names_let = async_await_conditional_runtime_names_arg.get("let", {})
    async_await_conditional_runtime_names_locals = async_await_conditional_runtime_names_let.get("locals", [])
    async_await_conditional_runtime_names_conditional = async_await_conditional_runtime_names_let.get("body", {}).get(
        "conditional", {}
    )
    async_await_conditional_runtime_names_then = async_await_conditional_runtime_names_conditional.get(
        "then", {}
    ).get("list_for_in", {})
    async_await_conditional_runtime_names_else = async_await_conditional_runtime_names_conditional.get(
        "else", {}
    ).get("list_for_in", {})
    if (
        async_await_conditional_runtime_names_source.get("async_future") is not True
        or async_await_conditional_runtime_names_source.get("body", {}).get("new_object", {}).get("type_args")
        != ["List<String>"]
        or async_await_conditional_runtime_names_source.get("params") != ["ready", "extra"]
        or len(async_await_conditional_runtime_names_locals) != 1
        or async_await_conditional_runtime_names_locals[0].get("name") != "enabled"
        or async_await_conditional_runtime_names_locals[0].get("value", {}).get("await", {}).get("arg") != "ready"
        or async_await_conditional_runtime_names_conditional.get("condition", {}).get("let_local") != 0
        or async_await_conditional_runtime_names_then.get("receiver", {}).get("list") != [
            {"string": "patched-await-if-runtime-head"},
            {"string": "patched-await-if-runtime-live"},
        ]
        or async_await_conditional_runtime_names_then.get("source", {}).get("arg") != "extra"
        or async_await_conditional_runtime_names_else.get("receiver", {}).get("list") != [
            {"string": "patched-await-if-runtime-head"},
            {"string": "patched-await-if-runtime-off"},
        ]
        or async_await_conditional_runtime_names_else.get("source", {}).get("arg") != "extra"
    ):
        raise SystemExit(
            "expected asyncAwaitThenConditionalRuntimeNames await/collection-if/list_for_in source, "
            f"got {async_await_conditional_runtime_names_source}"
        )

    async_await_condition_names_source = source_for("asyncAwaitConditionNames")
    async_await_condition_names_arg = async_await_condition_names_source.get("body", {}).get("new_object", {}).get(
        "args", [{}]
    )[0]
    async_await_condition_names_conditional = async_await_condition_names_arg.get("conditional", {})
    async_await_condition_names_then = async_await_condition_names_conditional.get("then", {}).get("list", [])
    async_await_condition_names_else = async_await_condition_names_conditional.get("else", {}).get("list", [])
    if (
        async_await_condition_names_source.get("async_future") is not True
        or async_await_condition_names_source.get("body", {}).get("new_object", {}).get("type_args")
        != ["List<String>"]
        or async_await_condition_names_source.get("params") != ["ready"]
        or async_await_condition_names_conditional.get("condition", {}).get("await", {}).get("arg") != "ready"
        or async_await_condition_names_then != [
            {"string": "patched-await-condition-head"},
            {"string": "patched-await-condition-live"},
            {"string": "patched-await-condition-tail"},
        ]
        or async_await_condition_names_else != [
            {"string": "patched-await-condition-head"},
            {"string": "patched-await-condition-off"},
            {"string": "patched-await-condition-tail"},
        ]
    ):
        raise SystemExit(
            "expected asyncAwaitConditionNames collection-if direct await source, "
            f"got {async_await_condition_names_source}"
        )

    async_await_condition_dynamic_names_source = source_for("asyncAwaitConditionDynamicNames")
    async_await_condition_dynamic_names_arg = async_await_condition_dynamic_names_source.get("body", {}).get(
        "new_object", {}
    ).get("args", [{}])[0]
    async_await_condition_dynamic_names_conditional = async_await_condition_dynamic_names_arg.get("conditional", {})
    async_await_condition_dynamic_names_then = async_await_condition_dynamic_names_conditional.get("then", {}).get(
        "list_add_all", {}
    )
    async_await_condition_dynamic_names_else = async_await_condition_dynamic_names_conditional.get("else", {}).get(
        "list_add_all", {}
    )
    if (
        async_await_condition_dynamic_names_source.get("async_future") is not True
        or async_await_condition_dynamic_names_source.get("body", {}).get("new_object", {}).get("type_args")
        != ["List<String>"]
        or async_await_condition_dynamic_names_source.get("params") != ["ready", "extra"]
        or async_await_condition_dynamic_names_conditional.get("condition", {}).get("await", {}).get("arg") != "ready"
        or async_await_condition_dynamic_names_then.get("receiver", {}).get("list") != [
            {"string": "patched-await-condition-dynamic-head"},
            {"string": "patched-await-condition-dynamic-live"},
        ]
        or async_await_condition_dynamic_names_then.get("spread", {}).get("arg") != "extra"
        or async_await_condition_dynamic_names_else.get("receiver", {}).get("list") != [
            {"string": "patched-await-condition-dynamic-head"},
            {"string": "patched-await-condition-dynamic-off"},
        ]
        or async_await_condition_dynamic_names_else.get("spread", {}).get("arg") != "extra"
    ):
        raise SystemExit(
            "expected asyncAwaitConditionDynamicNames collection-if direct await/list_add_all source, "
            f"got {async_await_condition_dynamic_names_source}"
        )

    async_await_condition_runtime_names_source = source_for("asyncAwaitConditionRuntimeNames")
    async_await_condition_runtime_names_arg = async_await_condition_runtime_names_source.get("body", {}).get(
        "new_object", {}
    ).get("args", [{}])[0]
    async_await_condition_runtime_names_conditional = async_await_condition_runtime_names_arg.get("conditional", {})
    async_await_condition_runtime_names_then = async_await_condition_runtime_names_conditional.get("then", {}).get(
        "list_for_in", {}
    )
    async_await_condition_runtime_names_else = async_await_condition_runtime_names_conditional.get("else", {}).get(
        "list_for_in", {}
    )
    if (
        async_await_condition_runtime_names_source.get("async_future") is not True
        or async_await_condition_runtime_names_source.get("body", {}).get("new_object", {}).get("type_args")
        != ["List<String>"]
        or async_await_condition_runtime_names_source.get("params") != ["ready", "extra"]
        or async_await_condition_runtime_names_conditional.get("condition", {}).get("await", {}).get("arg") != "ready"
        or async_await_condition_runtime_names_then.get("receiver", {}).get("list") != [
            {"string": "patched-await-condition-runtime-head"},
            {"string": "patched-await-condition-runtime-live"},
        ]
        or async_await_condition_runtime_names_then.get("source", {}).get("arg") != "extra"
        or async_await_condition_runtime_names_else.get("receiver", {}).get("list") != [
            {"string": "patched-await-condition-runtime-head"},
            {"string": "patched-await-condition-runtime-off"},
        ]
        or async_await_condition_runtime_names_else.get("source", {}).get("arg") != "extra"
    ):
        raise SystemExit(
            "expected asyncAwaitConditionRuntimeNames collection-if direct await/list_for_in source, "
            f"got {async_await_condition_runtime_names_source}"
        )
