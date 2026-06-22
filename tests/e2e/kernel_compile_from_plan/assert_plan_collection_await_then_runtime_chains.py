def assert_await_then_runtime_collection_chains(source_for):
    await_then_runtime_tail_list_source = source_for("asyncAwaitThenConditionalRuntimeTailNames")
    await_then_runtime_tail_list_arg = await_then_runtime_tail_list_source.get("body", {}).get("new_object", {}).get(
        "args", [{}]
    )[0]
    await_then_runtime_tail_list_let = await_then_runtime_tail_list_arg.get("let", {})
    await_then_runtime_tail_list_locals = await_then_runtime_tail_list_let.get("locals", [])
    await_then_runtime_tail_list_conditional = await_then_runtime_tail_list_let.get("body", {}).get("conditional", {})
    await_then_runtime_tail_list_then = await_then_runtime_tail_list_conditional.get("then", {}).get("list_add_all", {})
    await_then_runtime_tail_list_else = await_then_runtime_tail_list_conditional.get("else", {}).get("list_add_all", {})
    await_then_runtime_tail_list_then_receiver = await_then_runtime_tail_list_then.get("receiver", {}).get(
        "list_for_in", {}
    )
    await_then_runtime_tail_list_else_receiver = await_then_runtime_tail_list_else.get("receiver", {}).get(
        "list_for_in", {}
    )
    await_then_runtime_tail_list_tail = [{"string": "patched-await-if-runtime-tail-tail"}]
    if (
        await_then_runtime_tail_list_source.get("async_future") is not True
        or await_then_runtime_tail_list_source.get("body", {}).get("new_object", {}).get("type_args")
        != ["List<String>"]
        or await_then_runtime_tail_list_source.get("params") != ["ready", "extra"]
        or len(await_then_runtime_tail_list_locals) != 1
        or await_then_runtime_tail_list_locals[0].get("name") != "enabled"
        or await_then_runtime_tail_list_locals[0].get("value", {}).get("await", {}).get("arg") != "ready"
        or await_then_runtime_tail_list_conditional.get("condition", {}).get("let_local") != 0
        or await_then_runtime_tail_list_then_receiver.get("source", {}).get("arg") != "extra"
        or await_then_runtime_tail_list_else_receiver.get("source", {}).get("arg") != "extra"
        or await_then_runtime_tail_list_then.get("spread", {}).get("list") != await_then_runtime_tail_list_tail
        or await_then_runtime_tail_list_else.get("spread", {}).get("list") != await_then_runtime_tail_list_tail
        or await_then_runtime_tail_list_then_receiver.get("receiver", {}).get("list") != [
            {"string": "patched-await-if-runtime-tail-head"},
            {"string": "patched-await-if-runtime-tail-live"},
        ]
        or await_then_runtime_tail_list_else_receiver.get("receiver", {}).get("list") != [
            {"string": "patched-await-if-runtime-tail-head"},
            {"string": "patched-await-if-runtime-tail-off"},
        ]
    ):
        raise SystemExit(
            "expected asyncAwaitThenConditionalRuntimeTailNames await local/list_for_in/static tail chain, "
            f"got {await_then_runtime_tail_list_source}"
        )

    await_then_runtime_tail_map_source = source_for("asyncAwaitThenConditionalRuntimeTailLabels")
    await_then_runtime_tail_map_arg = await_then_runtime_tail_map_source.get("body", {}).get("new_object", {}).get(
        "args", [{}]
    )[0]
    await_then_runtime_tail_map_let = await_then_runtime_tail_map_arg.get("let", {})
    await_then_runtime_tail_map_locals = await_then_runtime_tail_map_let.get("locals", [])
    await_then_runtime_tail_map_conditional = await_then_runtime_tail_map_let.get("body", {}).get("conditional", {})
    await_then_runtime_tail_map_then = await_then_runtime_tail_map_conditional.get("then", {}).get("map_add_all", {})
    await_then_runtime_tail_map_else = await_then_runtime_tail_map_conditional.get("else", {}).get("map_add_all", {})
    await_then_runtime_tail_map_then_receiver = await_then_runtime_tail_map_then.get("receiver", {}).get(
        "map_for_in", {}
    )
    await_then_runtime_tail_map_else_receiver = await_then_runtime_tail_map_else.get("receiver", {}).get(
        "map_for_in", {}
    )
    await_then_runtime_tail_map_tail = [
        {
            "key": {"string": "tail"},
            "value": {"string": "patched-await-if-runtime-tail-tail"},
        }
    ]
    if (
        await_then_runtime_tail_map_source.get("async_future") is not True
        or await_then_runtime_tail_map_source.get("body", {}).get("new_object", {}).get("type_args")
        != ["Map<String,String>"]
        or await_then_runtime_tail_map_source.get("params") != ["ready", "extra"]
        or len(await_then_runtime_tail_map_locals) != 1
        or await_then_runtime_tail_map_locals[0].get("name") != "enabled"
        or await_then_runtime_tail_map_locals[0].get("value", {}).get("await", {}).get("arg") != "ready"
        or await_then_runtime_tail_map_conditional.get("condition", {}).get("let_local") != 0
        or await_then_runtime_tail_map_then_receiver.get("source", {}).get("call_dynamic", {}).get("method")
        != "get:entries"
        or await_then_runtime_tail_map_then_receiver.get("source", {}).get("call_dynamic", {}).get("receiver", {}).get(
            "arg"
        )
        != "extra"
        or await_then_runtime_tail_map_else_receiver.get("source", {}).get("call_dynamic", {}).get("method")
        != "get:entries"
        or await_then_runtime_tail_map_else_receiver.get("source", {}).get("call_dynamic", {}).get("receiver", {}).get(
            "arg"
        )
        != "extra"
        or await_then_runtime_tail_map_then.get("spread", {}).get("map") != await_then_runtime_tail_map_tail
        or await_then_runtime_tail_map_else.get("spread", {}).get("map") != await_then_runtime_tail_map_tail
        or await_then_runtime_tail_map_then_receiver.get("receiver", {}).get("map") != [
            {"key": {"string": "mode"}, "value": {"string": "patched-await-if-runtime-tail-map"}},
            {"key": {"string": "state"}, "value": {"string": "patched-await-if-runtime-tail-live"}},
        ]
        or await_then_runtime_tail_map_else_receiver.get("receiver", {}).get("map") != [
            {"key": {"string": "mode"}, "value": {"string": "patched-await-if-runtime-tail-map"}},
            {"key": {"string": "state"}, "value": {"string": "patched-await-if-runtime-tail-off"}},
        ]
    ):
        raise SystemExit(
            "expected asyncAwaitThenConditionalRuntimeTailLabels await local/map_for_in/static tail chain, "
            f"got {await_then_runtime_tail_map_source}"
        )

    await_then_runtime_spread_list_source = source_for("asyncAwaitThenConditionalRuntimeStaticSpreadNames")
    await_then_runtime_spread_list_arg = await_then_runtime_spread_list_source.get("body", {}).get("new_object", {}).get(
        "args", [{}]
    )[0]
    await_then_runtime_spread_list_let = await_then_runtime_spread_list_arg.get("let", {})
    await_then_runtime_spread_list_locals = await_then_runtime_spread_list_let.get("locals", [])
    await_then_runtime_spread_list_conditional = await_then_runtime_spread_list_let.get("body", {}).get("conditional", {})
    await_then_runtime_spread_list_then = await_then_runtime_spread_list_conditional.get("then", {}).get(
        "list_add_all", {}
    )
    await_then_runtime_spread_list_else = await_then_runtime_spread_list_conditional.get("else", {}).get(
        "list_add_all", {}
    )
    await_then_runtime_spread_list_then_receiver = await_then_runtime_spread_list_then.get("receiver", {}).get(
        "list_for_in", {}
    )
    await_then_runtime_spread_list_else_receiver = await_then_runtime_spread_list_else.get("receiver", {}).get(
        "list_for_in", {}
    )
    await_then_runtime_spread_list_tail = [
        {"string": "patched-await-if-runtime-static-spread-tail-a"},
        {"string": "patched-await-if-runtime-static-spread-tail-b"},
    ]
    if (
        await_then_runtime_spread_list_source.get("async_future") is not True
        or await_then_runtime_spread_list_source.get("body", {}).get("new_object", {}).get("type_args")
        != ["List<String>"]
        or await_then_runtime_spread_list_source.get("params") != ["ready", "extra"]
        or len(await_then_runtime_spread_list_locals) != 1
        or await_then_runtime_spread_list_locals[0].get("name") != "enabled"
        or await_then_runtime_spread_list_locals[0].get("value", {}).get("await", {}).get("arg") != "ready"
        or await_then_runtime_spread_list_conditional.get("condition", {}).get("let_local") != 0
        or await_then_runtime_spread_list_then_receiver.get("source", {}).get("arg") != "extra"
        or await_then_runtime_spread_list_else_receiver.get("source", {}).get("arg") != "extra"
        or await_then_runtime_spread_list_then.get("spread", {}).get("list") != await_then_runtime_spread_list_tail
        or await_then_runtime_spread_list_else.get("spread", {}).get("list") != await_then_runtime_spread_list_tail
        or await_then_runtime_spread_list_then_receiver.get("receiver", {}).get("list") != [
            {"string": "patched-await-if-runtime-static-spread-head"},
            {"string": "patched-await-if-runtime-static-spread-live"},
        ]
        or await_then_runtime_spread_list_else_receiver.get("receiver", {}).get("list") != [
            {"string": "patched-await-if-runtime-static-spread-head"},
            {"string": "patched-await-if-runtime-static-spread-off"},
        ]
    ):
        raise SystemExit(
            "expected asyncAwaitThenConditionalRuntimeStaticSpreadNames await local/list_for_in/static spread chain, "
            f"got {await_then_runtime_spread_list_source}"
        )

    await_then_runtime_spread_map_source = source_for("asyncAwaitThenConditionalRuntimeStaticSpreadLabels")
    await_then_runtime_spread_map_arg = await_then_runtime_spread_map_source.get("body", {}).get("new_object", {}).get(
        "args", [{}]
    )[0]
    await_then_runtime_spread_map_let = await_then_runtime_spread_map_arg.get("let", {})
    await_then_runtime_spread_map_locals = await_then_runtime_spread_map_let.get("locals", [])
    await_then_runtime_spread_map_conditional = await_then_runtime_spread_map_let.get("body", {}).get("conditional", {})
    await_then_runtime_spread_map_then = await_then_runtime_spread_map_conditional.get("then", {}).get(
        "map_add_all", {}
    )
    await_then_runtime_spread_map_else = await_then_runtime_spread_map_conditional.get("else", {}).get(
        "map_add_all", {}
    )
    await_then_runtime_spread_map_then_receiver = await_then_runtime_spread_map_then.get("receiver", {}).get(
        "map_for_in", {}
    )
    await_then_runtime_spread_map_else_receiver = await_then_runtime_spread_map_else.get("receiver", {}).get(
        "map_for_in", {}
    )
    await_then_runtime_spread_map_tail = [
        {
            "key": {"string": "tail"},
            "value": {"string": "patched-await-if-runtime-static-spread-tail"},
        }
    ]
    if (
        await_then_runtime_spread_map_source.get("async_future") is not True
        or await_then_runtime_spread_map_source.get("body", {}).get("new_object", {}).get("type_args")
        != ["Map<String,String>"]
        or await_then_runtime_spread_map_source.get("params") != ["ready", "extra"]
        or len(await_then_runtime_spread_map_locals) != 1
        or await_then_runtime_spread_map_locals[0].get("name") != "enabled"
        or await_then_runtime_spread_map_locals[0].get("value", {}).get("await", {}).get("arg") != "ready"
        or await_then_runtime_spread_map_conditional.get("condition", {}).get("let_local") != 0
        or await_then_runtime_spread_map_then_receiver.get("source", {}).get("call_dynamic", {}).get("method")
        != "get:entries"
        or await_then_runtime_spread_map_then_receiver.get("source", {}).get("call_dynamic", {}).get("receiver", {}).get(
            "arg"
        )
        != "extra"
        or await_then_runtime_spread_map_else_receiver.get("source", {}).get("call_dynamic", {}).get("method")
        != "get:entries"
        or await_then_runtime_spread_map_else_receiver.get("source", {}).get("call_dynamic", {}).get("receiver", {}).get(
            "arg"
        )
        != "extra"
        or await_then_runtime_spread_map_then.get("spread", {}).get("map") != await_then_runtime_spread_map_tail
        or await_then_runtime_spread_map_else.get("spread", {}).get("map") != await_then_runtime_spread_map_tail
        or await_then_runtime_spread_map_then_receiver.get("receiver", {}).get("map") != [
            {"key": {"string": "mode"}, "value": {"string": "patched-await-if-runtime-static-spread-map"}},
            {"key": {"string": "state"}, "value": {"string": "patched-await-if-runtime-static-spread-live"}},
        ]
        or await_then_runtime_spread_map_else_receiver.get("receiver", {}).get("map") != [
            {"key": {"string": "mode"}, "value": {"string": "patched-await-if-runtime-static-spread-map"}},
            {"key": {"string": "state"}, "value": {"string": "patched-await-if-runtime-static-spread-off"}},
        ]
    ):
        raise SystemExit(
            "expected asyncAwaitThenConditionalRuntimeStaticSpreadLabels await local/map_for_in/static spread chain, "
            f"got {await_then_runtime_spread_map_source}"
        )

    await_then_reverse_list_source = source_for("asyncAwaitThenConditionalRuntimeDynamicNames")
    await_then_reverse_list_arg = await_then_reverse_list_source.get("body", {}).get("new_object", {}).get(
        "args", [{}]
    )[0]
    await_then_reverse_list_let = await_then_reverse_list_arg.get("let", {})
    await_then_reverse_list_locals = await_then_reverse_list_let.get("locals", [])
    await_then_reverse_list_conditional = await_then_reverse_list_let.get("body", {}).get("conditional", {})
    await_then_reverse_list_then = await_then_reverse_list_conditional.get("then", {}).get("list_add_all", {})
    await_then_reverse_list_else = await_then_reverse_list_conditional.get("else", {}).get("list_add_all", {})
    await_then_reverse_list_then_receiver = await_then_reverse_list_then.get("receiver", {}).get("list_for_in", {})
    await_then_reverse_list_else_receiver = await_then_reverse_list_else.get("receiver", {}).get("list_for_in", {})
    if (
        await_then_reverse_list_source.get("async_future") is not True
        or await_then_reverse_list_source.get("body", {}).get("new_object", {}).get("type_args") != ["List<String>"]
        or await_then_reverse_list_source.get("params") != ["ready", "extra", "tail"]
        or len(await_then_reverse_list_locals) != 1
        or await_then_reverse_list_locals[0].get("name") != "enabled"
        or await_then_reverse_list_locals[0].get("value", {}).get("await", {}).get("arg") != "ready"
        or await_then_reverse_list_conditional.get("condition", {}).get("let_local") != 0
        or await_then_reverse_list_then.get("spread", {}).get("arg") != "tail"
        or await_then_reverse_list_else.get("spread", {}).get("arg") != "tail"
        or await_then_reverse_list_then_receiver.get("source", {}).get("arg") != "extra"
        or await_then_reverse_list_else_receiver.get("source", {}).get("arg") != "extra"
        or await_then_reverse_list_then_receiver.get("receiver", {}).get("list") != [
            {"string": "patched-await-if-runtime-dynamic-head"},
            {"string": "patched-await-if-runtime-dynamic-live"},
        ]
        or await_then_reverse_list_else_receiver.get("receiver", {}).get("list") != [
            {"string": "patched-await-if-runtime-dynamic-head"},
            {"string": "patched-await-if-runtime-dynamic-off"},
        ]
    ):
        raise SystemExit(
            "expected asyncAwaitThenConditionalRuntimeDynamicNames await local/list_for_in/list_add_all chain, "
            f"got {await_then_reverse_list_source}"
        )

    await_then_reverse_map_source = source_for("asyncAwaitThenConditionalRuntimeDynamicLabels")
    await_then_reverse_map_arg = await_then_reverse_map_source.get("body", {}).get("new_object", {}).get("args", [{}])[
        0
    ]
    await_then_reverse_map_let = await_then_reverse_map_arg.get("let", {})
    await_then_reverse_map_locals = await_then_reverse_map_let.get("locals", [])
    await_then_reverse_map_conditional = await_then_reverse_map_let.get("body", {}).get("conditional", {})
    await_then_reverse_map_then = await_then_reverse_map_conditional.get("then", {}).get("map_add_all", {})
    await_then_reverse_map_else = await_then_reverse_map_conditional.get("else", {}).get("map_add_all", {})
    await_then_reverse_map_then_receiver = await_then_reverse_map_then.get("receiver", {}).get("map_for_in", {})
    await_then_reverse_map_else_receiver = await_then_reverse_map_else.get("receiver", {}).get("map_for_in", {})
    if (
        await_then_reverse_map_source.get("async_future") is not True
        or await_then_reverse_map_source.get("body", {}).get("new_object", {}).get("type_args") != ["Map<String,String>"]
        or await_then_reverse_map_source.get("params") != ["ready", "extra", "tail"]
        or len(await_then_reverse_map_locals) != 1
        or await_then_reverse_map_locals[0].get("name") != "enabled"
        or await_then_reverse_map_locals[0].get("value", {}).get("await", {}).get("arg") != "ready"
        or await_then_reverse_map_conditional.get("condition", {}).get("let_local") != 0
        or await_then_reverse_map_then.get("spread", {}).get("arg") != "tail"
        or await_then_reverse_map_else.get("spread", {}).get("arg") != "tail"
        or await_then_reverse_map_then_receiver.get("source", {}).get("call_dynamic", {}).get("method")
        != "get:entries"
        or await_then_reverse_map_then_receiver.get("source", {}).get("call_dynamic", {}).get("receiver", {}).get(
            "arg"
        )
        != "extra"
        or await_then_reverse_map_else_receiver.get("source", {}).get("call_dynamic", {}).get("method")
        != "get:entries"
        or await_then_reverse_map_else_receiver.get("source", {}).get("call_dynamic", {}).get("receiver", {}).get(
            "arg"
        )
        != "extra"
        or await_then_reverse_map_then_receiver.get("receiver", {}).get("map") != [
            {"key": {"string": "mode"}, "value": {"string": "patched-await-if-runtime-dynamic-map"}},
            {"key": {"string": "state"}, "value": {"string": "patched-await-if-runtime-dynamic-live"}},
        ]
        or await_then_reverse_map_else_receiver.get("receiver", {}).get("map") != [
            {"key": {"string": "mode"}, "value": {"string": "patched-await-if-runtime-dynamic-map"}},
            {"key": {"string": "state"}, "value": {"string": "patched-await-if-runtime-dynamic-off"}},
        ]
    ):
        raise SystemExit(
            "expected asyncAwaitThenConditionalRuntimeDynamicLabels await local/map_for_in/map_add_all chain, "
            f"got {await_then_reverse_map_source}"
        )

    await_then_reverse_tail_list_source = source_for("asyncAwaitThenConditionalRuntimeDynamicTailNames")
    await_then_reverse_tail_list_arg = await_then_reverse_tail_list_source.get("body", {}).get("new_object", {}).get(
        "args", [{}]
    )[0]
    await_then_reverse_tail_list_let = await_then_reverse_tail_list_arg.get("let", {})
    await_then_reverse_tail_list_locals = await_then_reverse_tail_list_let.get("locals", [])
    await_then_reverse_tail_list_conditional = await_then_reverse_tail_list_let.get("body", {}).get("conditional", {})
    await_then_reverse_tail_list_then = await_then_reverse_tail_list_conditional.get("then", {}).get("list_add_all", {})
    await_then_reverse_tail_list_else = await_then_reverse_tail_list_conditional.get("else", {}).get("list_add_all", {})
    await_then_reverse_tail_list_then_receiver = await_then_reverse_tail_list_then.get("receiver", {}).get(
        "list_add_all", {}
    )
    await_then_reverse_tail_list_else_receiver = await_then_reverse_tail_list_else.get("receiver", {}).get(
        "list_add_all", {}
    )
    await_then_reverse_tail_list_then_head = await_then_reverse_tail_list_then_receiver.get("receiver", {}).get(
        "list_for_in", {}
    )
    await_then_reverse_tail_list_else_head = await_then_reverse_tail_list_else_receiver.get("receiver", {}).get(
        "list_for_in", {}
    )
    await_then_reverse_tail_list_tail = [{"string": "patched-await-if-runtime-dynamic-tail-tail"}]
    if (
        await_then_reverse_tail_list_source.get("async_future") is not True
        or await_then_reverse_tail_list_source.get("body", {}).get("new_object", {}).get("type_args") != ["List<String>"]
        or await_then_reverse_tail_list_source.get("params") != ["ready", "extra", "tail"]
        or len(await_then_reverse_tail_list_locals) != 1
        or await_then_reverse_tail_list_locals[0].get("name") != "enabled"
        or await_then_reverse_tail_list_locals[0].get("value", {}).get("await", {}).get("arg") != "ready"
        or await_then_reverse_tail_list_conditional.get("condition", {}).get("let_local") != 0
        or await_then_reverse_tail_list_then.get("spread", {}).get("list") != await_then_reverse_tail_list_tail
        or await_then_reverse_tail_list_else.get("spread", {}).get("list") != await_then_reverse_tail_list_tail
        or await_then_reverse_tail_list_then_receiver.get("spread", {}).get("arg") != "tail"
        or await_then_reverse_tail_list_else_receiver.get("spread", {}).get("arg") != "tail"
        or await_then_reverse_tail_list_then_head.get("source", {}).get("arg") != "extra"
        or await_then_reverse_tail_list_else_head.get("source", {}).get("arg") != "extra"
        or await_then_reverse_tail_list_then_head.get("receiver", {}).get("list") != [
            {"string": "patched-await-if-runtime-dynamic-tail-head"},
            {"string": "patched-await-if-runtime-dynamic-tail-live"},
        ]
        or await_then_reverse_tail_list_else_head.get("receiver", {}).get("list") != [
            {"string": "patched-await-if-runtime-dynamic-tail-head"},
            {"string": "patched-await-if-runtime-dynamic-tail-off"},
        ]
    ):
        raise SystemExit(
            "expected asyncAwaitThenConditionalRuntimeDynamicTailNames await local/list_for_in/list_add_all/static tail chain, "
            f"got {await_then_reverse_tail_list_source}"
        )

    await_then_reverse_tail_map_source = source_for("asyncAwaitThenConditionalRuntimeDynamicTailLabels")
    await_then_reverse_tail_map_arg = await_then_reverse_tail_map_source.get("body", {}).get("new_object", {}).get(
        "args", [{}]
    )[0]
    await_then_reverse_tail_map_let = await_then_reverse_tail_map_arg.get("let", {})
    await_then_reverse_tail_map_locals = await_then_reverse_tail_map_let.get("locals", [])
    await_then_reverse_tail_map_conditional = await_then_reverse_tail_map_let.get("body", {}).get("conditional", {})
    await_then_reverse_tail_map_then = await_then_reverse_tail_map_conditional.get("then", {}).get("map_add_all", {})
    await_then_reverse_tail_map_else = await_then_reverse_tail_map_conditional.get("else", {}).get("map_add_all", {})
    await_then_reverse_tail_map_then_receiver = await_then_reverse_tail_map_then.get("receiver", {}).get(
        "map_add_all", {}
    )
    await_then_reverse_tail_map_else_receiver = await_then_reverse_tail_map_else.get("receiver", {}).get(
        "map_add_all", {}
    )
    await_then_reverse_tail_map_then_head = await_then_reverse_tail_map_then_receiver.get("receiver", {}).get(
        "map_for_in", {}
    )
    await_then_reverse_tail_map_else_head = await_then_reverse_tail_map_else_receiver.get("receiver", {}).get(
        "map_for_in", {}
    )
    await_then_reverse_tail_map_tail = [
        {
            "key": {"string": "tail"},
            "value": {"string": "patched-await-if-runtime-dynamic-tail-tail"},
        }
    ]
    if (
        await_then_reverse_tail_map_source.get("async_future") is not True
        or await_then_reverse_tail_map_source.get("body", {}).get("new_object", {}).get("type_args")
        != ["Map<String,String>"]
        or await_then_reverse_tail_map_source.get("params") != ["ready", "extra", "tail"]
        or len(await_then_reverse_tail_map_locals) != 1
        or await_then_reverse_tail_map_locals[0].get("name") != "enabled"
        or await_then_reverse_tail_map_locals[0].get("value", {}).get("await", {}).get("arg") != "ready"
        or await_then_reverse_tail_map_conditional.get("condition", {}).get("let_local") != 0
        or await_then_reverse_tail_map_then.get("spread", {}).get("map") != await_then_reverse_tail_map_tail
        or await_then_reverse_tail_map_else.get("spread", {}).get("map") != await_then_reverse_tail_map_tail
        or await_then_reverse_tail_map_then_receiver.get("spread", {}).get("arg") != "tail"
        or await_then_reverse_tail_map_else_receiver.get("spread", {}).get("arg") != "tail"
        or await_then_reverse_tail_map_then_head.get("source", {}).get("call_dynamic", {}).get("method")
        != "get:entries"
        or await_then_reverse_tail_map_then_head.get("source", {}).get("call_dynamic", {}).get("receiver", {}).get("arg")
        != "extra"
        or await_then_reverse_tail_map_else_head.get("source", {}).get("call_dynamic", {}).get("method")
        != "get:entries"
        or await_then_reverse_tail_map_else_head.get("source", {}).get("call_dynamic", {}).get("receiver", {}).get("arg")
        != "extra"
        or await_then_reverse_tail_map_then_head.get("receiver", {}).get("map") != [
            {"key": {"string": "mode"}, "value": {"string": "patched-await-if-runtime-dynamic-tail-map"}},
            {"key": {"string": "state"}, "value": {"string": "patched-await-if-runtime-dynamic-tail-live"}},
        ]
        or await_then_reverse_tail_map_else_head.get("receiver", {}).get("map") != [
            {"key": {"string": "mode"}, "value": {"string": "patched-await-if-runtime-dynamic-tail-map"}},
            {"key": {"string": "state"}, "value": {"string": "patched-await-if-runtime-dynamic-tail-off"}},
        ]
    ):
        raise SystemExit(
            "expected asyncAwaitThenConditionalRuntimeDynamicTailLabels await local/map_for_in/map_add_all/static tail chain, "
            f"got {await_then_reverse_tail_map_source}"
        )

    await_then_reverse_spread_list_source = source_for("asyncAwaitThenConditionalRuntimeDynamicStaticSpreadNames")
    await_then_reverse_spread_list_arg = await_then_reverse_spread_list_source.get("body", {}).get(
        "new_object", {}
    ).get("args", [{}])[0]
    await_then_reverse_spread_list_let = await_then_reverse_spread_list_arg.get("let", {})
    await_then_reverse_spread_list_locals = await_then_reverse_spread_list_let.get("locals", [])
    await_then_reverse_spread_list_conditional = await_then_reverse_spread_list_let.get("body", {}).get(
        "conditional", {}
    )
    await_then_reverse_spread_list_then = await_then_reverse_spread_list_conditional.get("then", {}).get(
        "list_add_all", {}
    )
    await_then_reverse_spread_list_else = await_then_reverse_spread_list_conditional.get("else", {}).get(
        "list_add_all", {}
    )
    await_then_reverse_spread_list_then_receiver = await_then_reverse_spread_list_then.get("receiver", {}).get(
        "list_add_all", {}
    )
    await_then_reverse_spread_list_else_receiver = await_then_reverse_spread_list_else.get("receiver", {}).get(
        "list_add_all", {}
    )
    await_then_reverse_spread_list_then_head = await_then_reverse_spread_list_then_receiver.get("receiver", {}).get(
        "list_for_in", {}
    )
    await_then_reverse_spread_list_else_head = await_then_reverse_spread_list_else_receiver.get("receiver", {}).get(
        "list_for_in", {}
    )
    await_then_reverse_spread_list_tail = [
        {"string": "patched-await-if-runtime-dynamic-static-spread-tail-a"},
        {"string": "patched-await-if-runtime-dynamic-static-spread-tail-b"},
    ]
    if (
        await_then_reverse_spread_list_source.get("async_future") is not True
        or await_then_reverse_spread_list_source.get("body", {}).get("new_object", {}).get("type_args")
        != ["List<String>"]
        or await_then_reverse_spread_list_source.get("params") != ["ready", "extra", "tail"]
        or len(await_then_reverse_spread_list_locals) != 1
        or await_then_reverse_spread_list_locals[0].get("name") != "enabled"
        or await_then_reverse_spread_list_locals[0].get("value", {}).get("await", {}).get("arg") != "ready"
        or await_then_reverse_spread_list_conditional.get("condition", {}).get("let_local") != 0
        or await_then_reverse_spread_list_then.get("spread", {}).get("list") != await_then_reverse_spread_list_tail
        or await_then_reverse_spread_list_else.get("spread", {}).get("list") != await_then_reverse_spread_list_tail
        or await_then_reverse_spread_list_then_receiver.get("spread", {}).get("arg") != "tail"
        or await_then_reverse_spread_list_else_receiver.get("spread", {}).get("arg") != "tail"
        or await_then_reverse_spread_list_then_head.get("source", {}).get("arg") != "extra"
        or await_then_reverse_spread_list_else_head.get("source", {}).get("arg") != "extra"
        or await_then_reverse_spread_list_then_head.get("receiver", {}).get("list") != [
            {"string": "patched-await-if-runtime-dynamic-static-spread-head"},
            {"string": "patched-await-if-runtime-dynamic-static-spread-live"},
        ]
        or await_then_reverse_spread_list_else_head.get("receiver", {}).get("list") != [
            {"string": "patched-await-if-runtime-dynamic-static-spread-head"},
            {"string": "patched-await-if-runtime-dynamic-static-spread-off"},
        ]
    ):
        raise SystemExit(
            "expected asyncAwaitThenConditionalRuntimeDynamicStaticSpreadNames "
            "await local/list_for_in/list_add_all/static spread chain, "
            f"got {await_then_reverse_spread_list_source}"
        )

    await_then_reverse_spread_map_source = source_for("asyncAwaitThenConditionalRuntimeDynamicStaticSpreadLabels")
    await_then_reverse_spread_map_arg = await_then_reverse_spread_map_source.get("body", {}).get(
        "new_object", {}
    ).get("args", [{}])[0]
    await_then_reverse_spread_map_let = await_then_reverse_spread_map_arg.get("let", {})
    await_then_reverse_spread_map_locals = await_then_reverse_spread_map_let.get("locals", [])
    await_then_reverse_spread_map_conditional = await_then_reverse_spread_map_let.get("body", {}).get(
        "conditional", {}
    )
    await_then_reverse_spread_map_then = await_then_reverse_spread_map_conditional.get("then", {}).get(
        "map_add_all", {}
    )
    await_then_reverse_spread_map_else = await_then_reverse_spread_map_conditional.get("else", {}).get(
        "map_add_all", {}
    )
    await_then_reverse_spread_map_then_receiver = await_then_reverse_spread_map_then.get("receiver", {}).get(
        "map_add_all", {}
    )
    await_then_reverse_spread_map_else_receiver = await_then_reverse_spread_map_else.get("receiver", {}).get(
        "map_add_all", {}
    )
    await_then_reverse_spread_map_then_head = await_then_reverse_spread_map_then_receiver.get("receiver", {}).get(
        "map_for_in", {}
    )
    await_then_reverse_spread_map_else_head = await_then_reverse_spread_map_else_receiver.get("receiver", {}).get(
        "map_for_in", {}
    )
    await_then_reverse_spread_map_tail = [
        {
            "key": {"string": "tail"},
            "value": {"string": "patched-await-if-runtime-dynamic-static-spread-tail"},
        }
    ]
    if (
        await_then_reverse_spread_map_source.get("async_future") is not True
        or await_then_reverse_spread_map_source.get("body", {}).get("new_object", {}).get("type_args")
        != ["Map<String,String>"]
        or await_then_reverse_spread_map_source.get("params") != ["ready", "extra", "tail"]
        or len(await_then_reverse_spread_map_locals) != 1
        or await_then_reverse_spread_map_locals[0].get("name") != "enabled"
        or await_then_reverse_spread_map_locals[0].get("value", {}).get("await", {}).get("arg") != "ready"
        or await_then_reverse_spread_map_conditional.get("condition", {}).get("let_local") != 0
        or await_then_reverse_spread_map_then.get("spread", {}).get("map") != await_then_reverse_spread_map_tail
        or await_then_reverse_spread_map_else.get("spread", {}).get("map") != await_then_reverse_spread_map_tail
        or await_then_reverse_spread_map_then_receiver.get("spread", {}).get("arg") != "tail"
        or await_then_reverse_spread_map_else_receiver.get("spread", {}).get("arg") != "tail"
        or await_then_reverse_spread_map_then_head.get("source", {}).get("call_dynamic", {}).get("method")
        != "get:entries"
        or await_then_reverse_spread_map_then_head.get("source", {}).get("call_dynamic", {}).get("receiver", {}).get(
            "arg"
        )
        != "extra"
        or await_then_reverse_spread_map_else_head.get("source", {}).get("call_dynamic", {}).get("method")
        != "get:entries"
        or await_then_reverse_spread_map_else_head.get("source", {}).get("call_dynamic", {}).get("receiver", {}).get(
            "arg"
        )
        != "extra"
        or await_then_reverse_spread_map_then_head.get("receiver", {}).get("map") != [
            {"key": {"string": "mode"}, "value": {"string": "patched-await-if-runtime-dynamic-static-spread-map"}},
            {"key": {"string": "state"}, "value": {"string": "patched-await-if-runtime-dynamic-static-spread-live"}},
        ]
        or await_then_reverse_spread_map_else_head.get("receiver", {}).get("map") != [
            {"key": {"string": "mode"}, "value": {"string": "patched-await-if-runtime-dynamic-static-spread-map"}},
            {"key": {"string": "state"}, "value": {"string": "patched-await-if-runtime-dynamic-static-spread-off"}},
        ]
    ):
        raise SystemExit(
            "expected asyncAwaitThenConditionalRuntimeDynamicStaticSpreadLabels "
            "await local/map_for_in/map_add_all/static spread chain, "
            f"got {await_then_reverse_spread_map_source}"
        )
