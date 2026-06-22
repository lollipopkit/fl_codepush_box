from assert_plan_collection_await_then_runtime_chains import assert_await_then_runtime_collection_chains


def assert_await_then_collection_chains(source_for):
    await_then_tail_list_source = source_for("asyncAwaitThenConditionalDynamicTailNames")
    await_then_tail_list_arg = await_then_tail_list_source.get("body", {}).get("new_object", {}).get("args", [{}])[0]
    await_then_tail_list_let = await_then_tail_list_arg.get("let", {})
    await_then_tail_list_locals = await_then_tail_list_let.get("locals", [])
    await_then_tail_list_conditional = await_then_tail_list_let.get("body", {}).get("conditional", {})
    await_then_tail_list_then = await_then_tail_list_conditional.get("then", {}).get("list_add_all", {})
    await_then_tail_list_else = await_then_tail_list_conditional.get("else", {}).get("list_add_all", {})
    await_then_tail_list_then_receiver = await_then_tail_list_then.get("receiver", {}).get("list_add_all", {})
    await_then_tail_list_else_receiver = await_then_tail_list_else.get("receiver", {}).get("list_add_all", {})
    await_then_tail_list_tail = [{"string": "patched-await-if-dynamic-tail-tail"}]
    if (
        await_then_tail_list_source.get("async_future") is not True
        or await_then_tail_list_source.get("body", {}).get("new_object", {}).get("type_args") != ["List<String>"]
        or await_then_tail_list_source.get("params") != ["ready", "extra"]
        or len(await_then_tail_list_locals) != 1
        or await_then_tail_list_locals[0].get("name") != "enabled"
        or await_then_tail_list_locals[0].get("value", {}).get("await", {}).get("arg") != "ready"
        or await_then_tail_list_conditional.get("condition", {}).get("let_local") != 0
        or await_then_tail_list_then_receiver.get("spread", {}).get("arg") != "extra"
        or await_then_tail_list_else_receiver.get("spread", {}).get("arg") != "extra"
        or await_then_tail_list_then.get("spread", {}).get("list") != await_then_tail_list_tail
        or await_then_tail_list_else.get("spread", {}).get("list") != await_then_tail_list_tail
        or await_then_tail_list_then_receiver.get("receiver", {}).get("list") != [
            {"string": "patched-await-if-dynamic-tail-head"},
            {"string": "patched-await-if-dynamic-tail-live"},
        ]
        or await_then_tail_list_else_receiver.get("receiver", {}).get("list") != [
            {"string": "patched-await-if-dynamic-tail-head"},
            {"string": "patched-await-if-dynamic-tail-off"},
        ]
    ):
        raise SystemExit(
            "expected asyncAwaitThenConditionalDynamicTailNames await local/list_add_all/static tail chain, "
            f"got {await_then_tail_list_source}"
        )

    await_then_tail_map_source = source_for("asyncAwaitThenConditionalDynamicTailLabels")
    await_then_tail_map_arg = await_then_tail_map_source.get("body", {}).get("new_object", {}).get("args", [{}])[0]
    await_then_tail_map_let = await_then_tail_map_arg.get("let", {})
    await_then_tail_map_locals = await_then_tail_map_let.get("locals", [])
    await_then_tail_map_conditional = await_then_tail_map_let.get("body", {}).get("conditional", {})
    await_then_tail_map_then = await_then_tail_map_conditional.get("then", {}).get("map_add_all", {})
    await_then_tail_map_else = await_then_tail_map_conditional.get("else", {}).get("map_add_all", {})
    await_then_tail_map_then_receiver = await_then_tail_map_then.get("receiver", {}).get("map_add_all", {})
    await_then_tail_map_else_receiver = await_then_tail_map_else.get("receiver", {}).get("map_add_all", {})
    await_then_tail_map_tail = [
        {
            "key": {"string": "tail"},
            "value": {"string": "patched-await-if-dynamic-tail-tail"},
        }
    ]
    if (
        await_then_tail_map_source.get("async_future") is not True
        or await_then_tail_map_source.get("body", {}).get("new_object", {}).get("type_args") != ["Map<String,String>"]
        or await_then_tail_map_source.get("params") != ["ready", "extra"]
        or len(await_then_tail_map_locals) != 1
        or await_then_tail_map_locals[0].get("name") != "enabled"
        or await_then_tail_map_locals[0].get("value", {}).get("await", {}).get("arg") != "ready"
        or await_then_tail_map_conditional.get("condition", {}).get("let_local") != 0
        or await_then_tail_map_then_receiver.get("spread", {}).get("arg") != "extra"
        or await_then_tail_map_else_receiver.get("spread", {}).get("arg") != "extra"
        or await_then_tail_map_then.get("spread", {}).get("map") != await_then_tail_map_tail
        or await_then_tail_map_else.get("spread", {}).get("map") != await_then_tail_map_tail
        or await_then_tail_map_then_receiver.get("receiver", {}).get("map") != [
            {"key": {"string": "mode"}, "value": {"string": "patched-await-if-dynamic-tail-map"}},
            {"key": {"string": "state"}, "value": {"string": "patched-await-if-dynamic-tail-live"}},
        ]
        or await_then_tail_map_else_receiver.get("receiver", {}).get("map") != [
            {"key": {"string": "mode"}, "value": {"string": "patched-await-if-dynamic-tail-map"}},
            {"key": {"string": "state"}, "value": {"string": "patched-await-if-dynamic-tail-off"}},
        ]
    ):
        raise SystemExit(
            "expected asyncAwaitThenConditionalDynamicTailLabels await local/map_add_all/static tail chain, "
            f"got {await_then_tail_map_source}"
        )

    await_then_spread_list_source = source_for("asyncAwaitThenConditionalDynamicStaticSpreadNames")
    await_then_spread_list_arg = await_then_spread_list_source.get("body", {}).get("new_object", {}).get("args", [{}])[0]
    await_then_spread_list_let = await_then_spread_list_arg.get("let", {})
    await_then_spread_list_locals = await_then_spread_list_let.get("locals", [])
    await_then_spread_list_conditional = await_then_spread_list_let.get("body", {}).get("conditional", {})
    await_then_spread_list_then = await_then_spread_list_conditional.get("then", {}).get("list_add_all", {})
    await_then_spread_list_else = await_then_spread_list_conditional.get("else", {}).get("list_add_all", {})
    await_then_spread_list_then_receiver = await_then_spread_list_then.get("receiver", {}).get("list_add_all", {})
    await_then_spread_list_else_receiver = await_then_spread_list_else.get("receiver", {}).get("list_add_all", {})
    await_then_spread_list_tail = [
        {"string": "patched-await-if-dynamic-static-spread-tail-a"},
        {"string": "patched-await-if-dynamic-static-spread-tail-b"},
    ]
    if (
        await_then_spread_list_source.get("async_future") is not True
        or await_then_spread_list_source.get("body", {}).get("new_object", {}).get("type_args") != ["List<String>"]
        or await_then_spread_list_source.get("params") != ["ready", "extra"]
        or len(await_then_spread_list_locals) != 1
        or await_then_spread_list_locals[0].get("name") != "enabled"
        or await_then_spread_list_locals[0].get("value", {}).get("await", {}).get("arg") != "ready"
        or await_then_spread_list_conditional.get("condition", {}).get("let_local") != 0
        or await_then_spread_list_then_receiver.get("spread", {}).get("arg") != "extra"
        or await_then_spread_list_else_receiver.get("spread", {}).get("arg") != "extra"
        or await_then_spread_list_then.get("spread", {}).get("list") != await_then_spread_list_tail
        or await_then_spread_list_else.get("spread", {}).get("list") != await_then_spread_list_tail
        or await_then_spread_list_then_receiver.get("receiver", {}).get("list") != [
            {"string": "patched-await-if-dynamic-static-spread-head"},
            {"string": "patched-await-if-dynamic-static-spread-live"},
        ]
        or await_then_spread_list_else_receiver.get("receiver", {}).get("list") != [
            {"string": "patched-await-if-dynamic-static-spread-head"},
            {"string": "patched-await-if-dynamic-static-spread-off"},
        ]
    ):
        raise SystemExit(
            "expected asyncAwaitThenConditionalDynamicStaticSpreadNames await local/list_add_all/static spread chain, "
            f"got {await_then_spread_list_source}"
        )

    await_then_spread_map_source = source_for("asyncAwaitThenConditionalDynamicStaticSpreadLabels")
    await_then_spread_map_arg = await_then_spread_map_source.get("body", {}).get("new_object", {}).get("args", [{}])[0]
    await_then_spread_map_let = await_then_spread_map_arg.get("let", {})
    await_then_spread_map_locals = await_then_spread_map_let.get("locals", [])
    await_then_spread_map_conditional = await_then_spread_map_let.get("body", {}).get("conditional", {})
    await_then_spread_map_then = await_then_spread_map_conditional.get("then", {}).get("map_add_all", {})
    await_then_spread_map_else = await_then_spread_map_conditional.get("else", {}).get("map_add_all", {})
    await_then_spread_map_then_receiver = await_then_spread_map_then.get("receiver", {}).get("map_add_all", {})
    await_then_spread_map_else_receiver = await_then_spread_map_else.get("receiver", {}).get("map_add_all", {})
    await_then_spread_map_tail = [
        {
            "key": {"string": "tail"},
            "value": {"string": "patched-await-if-dynamic-static-spread-tail"},
        }
    ]
    if (
        await_then_spread_map_source.get("async_future") is not True
        or await_then_spread_map_source.get("body", {}).get("new_object", {}).get("type_args") != ["Map<String,String>"]
        or await_then_spread_map_source.get("params") != ["ready", "extra"]
        or len(await_then_spread_map_locals) != 1
        or await_then_spread_map_locals[0].get("name") != "enabled"
        or await_then_spread_map_locals[0].get("value", {}).get("await", {}).get("arg") != "ready"
        or await_then_spread_map_conditional.get("condition", {}).get("let_local") != 0
        or await_then_spread_map_then_receiver.get("spread", {}).get("arg") != "extra"
        or await_then_spread_map_else_receiver.get("spread", {}).get("arg") != "extra"
        or await_then_spread_map_then.get("spread", {}).get("map") != await_then_spread_map_tail
        or await_then_spread_map_else.get("spread", {}).get("map") != await_then_spread_map_tail
        or await_then_spread_map_then_receiver.get("receiver", {}).get("map") != [
            {"key": {"string": "mode"}, "value": {"string": "patched-await-if-dynamic-static-spread-map"}},
            {"key": {"string": "state"}, "value": {"string": "patched-await-if-dynamic-static-spread-live"}},
        ]
        or await_then_spread_map_else_receiver.get("receiver", {}).get("map") != [
            {"key": {"string": "mode"}, "value": {"string": "patched-await-if-dynamic-static-spread-map"}},
            {"key": {"string": "state"}, "value": {"string": "patched-await-if-dynamic-static-spread-off"}},
        ]
    ):
        raise SystemExit(
            "expected asyncAwaitThenConditionalDynamicStaticSpreadLabels await local/map_add_all/static spread chain, "
            f"got {await_then_spread_map_source}"
        )

    await_then_chain_list_source = source_for("asyncAwaitThenConditionalDynamicRuntimeNames")
    await_then_chain_list_arg = await_then_chain_list_source.get("body", {}).get("new_object", {}).get("args", [{}])[0]
    await_then_chain_list_let = await_then_chain_list_arg.get("let", {})
    await_then_chain_list_locals = await_then_chain_list_let.get("locals", [])
    await_then_chain_list_conditional = await_then_chain_list_let.get("body", {}).get("conditional", {})
    await_then_chain_list_then = await_then_chain_list_conditional.get("then", {}).get("list_for_in", {})
    await_then_chain_list_else = await_then_chain_list_conditional.get("else", {}).get("list_for_in", {})
    await_then_chain_list_then_receiver = await_then_chain_list_then.get("receiver", {}).get("list_add_all", {})
    await_then_chain_list_else_receiver = await_then_chain_list_else.get("receiver", {}).get("list_add_all", {})
    if (
        await_then_chain_list_source.get("async_future") is not True
        or await_then_chain_list_source.get("body", {}).get("new_object", {}).get("type_args") != ["List<String>"]
        or await_then_chain_list_source.get("params") != ["ready", "extra", "tail"]
        or len(await_then_chain_list_locals) != 1
        or await_then_chain_list_locals[0].get("name") != "enabled"
        or await_then_chain_list_locals[0].get("value", {}).get("await", {}).get("arg") != "ready"
        or await_then_chain_list_conditional.get("condition", {}).get("let_local") != 0
        or await_then_chain_list_then.get("source", {}).get("arg") != "tail"
        or await_then_chain_list_else.get("source", {}).get("arg") != "tail"
        or await_then_chain_list_then_receiver.get("spread", {}).get("arg") != "extra"
        or await_then_chain_list_else_receiver.get("spread", {}).get("arg") != "extra"
        or await_then_chain_list_then_receiver.get("receiver", {}).get("list") != [
            {"string": "patched-await-if-dynamic-runtime-head"},
            {"string": "patched-await-if-dynamic-runtime-live"},
        ]
        or await_then_chain_list_else_receiver.get("receiver", {}).get("list") != [
            {"string": "patched-await-if-dynamic-runtime-head"},
            {"string": "patched-await-if-dynamic-runtime-off"},
        ]
    ):
        raise SystemExit(
            "expected asyncAwaitThenConditionalDynamicRuntimeNames await local/list_add_all/list_for_in chain, "
            f"got {await_then_chain_list_source}"
        )

    await_then_chain_map_source = source_for("asyncAwaitThenConditionalDynamicRuntimeLabels")
    await_then_chain_map_arg = await_then_chain_map_source.get("body", {}).get("new_object", {}).get("args", [{}])[0]
    await_then_chain_map_let = await_then_chain_map_arg.get("let", {})
    await_then_chain_map_locals = await_then_chain_map_let.get("locals", [])
    await_then_chain_map_conditional = await_then_chain_map_let.get("body", {}).get("conditional", {})
    await_then_chain_map_then = await_then_chain_map_conditional.get("then", {}).get("map_for_in", {})
    await_then_chain_map_else = await_then_chain_map_conditional.get("else", {}).get("map_for_in", {})
    await_then_chain_map_then_receiver = await_then_chain_map_then.get("receiver", {}).get("map_add_all", {})
    await_then_chain_map_else_receiver = await_then_chain_map_else.get("receiver", {}).get("map_add_all", {})
    if (
        await_then_chain_map_source.get("async_future") is not True
        or await_then_chain_map_source.get("body", {}).get("new_object", {}).get("type_args") != ["Map<String,String>"]
        or await_then_chain_map_source.get("params") != ["ready", "extra", "tail"]
        or len(await_then_chain_map_locals) != 1
        or await_then_chain_map_locals[0].get("name") != "enabled"
        or await_then_chain_map_locals[0].get("value", {}).get("await", {}).get("arg") != "ready"
        or await_then_chain_map_conditional.get("condition", {}).get("let_local") != 0
        or await_then_chain_map_then.get("source", {}).get("call_dynamic", {}).get("method") != "get:entries"
        or await_then_chain_map_then.get("source", {}).get("call_dynamic", {}).get("receiver", {}).get("arg") != "tail"
        or await_then_chain_map_else.get("source", {}).get("call_dynamic", {}).get("method") != "get:entries"
        or await_then_chain_map_else.get("source", {}).get("call_dynamic", {}).get("receiver", {}).get("arg") != "tail"
        or await_then_chain_map_then_receiver.get("spread", {}).get("arg") != "extra"
        or await_then_chain_map_else_receiver.get("spread", {}).get("arg") != "extra"
        or await_then_chain_map_then_receiver.get("receiver", {}).get("map") != [
            {"key": {"string": "mode"}, "value": {"string": "patched-await-if-dynamic-runtime-map"}},
            {"key": {"string": "state"}, "value": {"string": "patched-await-if-dynamic-runtime-live"}},
        ]
        or await_then_chain_map_else_receiver.get("receiver", {}).get("map") != [
            {"key": {"string": "mode"}, "value": {"string": "patched-await-if-dynamic-runtime-map"}},
            {"key": {"string": "state"}, "value": {"string": "patched-await-if-dynamic-runtime-off"}},
        ]
    ):
        raise SystemExit(
            "expected asyncAwaitThenConditionalDynamicRuntimeLabels await local/map_add_all/map_for_in chain, "
            f"got {await_then_chain_map_source}"
        )

    await_then_chain_tail_list_source = source_for("asyncAwaitThenConditionalDynamicRuntimeTailNames")
    await_then_chain_tail_list_arg = await_then_chain_tail_list_source.get("body", {}).get("new_object", {}).get(
        "args", [{}]
    )[0]
    await_then_chain_tail_list_let = await_then_chain_tail_list_arg.get("let", {})
    await_then_chain_tail_list_locals = await_then_chain_tail_list_let.get("locals", [])
    await_then_chain_tail_list_conditional = await_then_chain_tail_list_let.get("body", {}).get("conditional", {})
    await_then_chain_tail_list_then = await_then_chain_tail_list_conditional.get("then", {}).get("list_add_all", {})
    await_then_chain_tail_list_else = await_then_chain_tail_list_conditional.get("else", {}).get("list_add_all", {})
    await_then_chain_tail_list_then_receiver = await_then_chain_tail_list_then.get("receiver", {}).get("list_for_in", {})
    await_then_chain_tail_list_else_receiver = await_then_chain_tail_list_else.get("receiver", {}).get("list_for_in", {})
    await_then_chain_tail_list_then_head = await_then_chain_tail_list_then_receiver.get("receiver", {}).get(
        "list_add_all", {}
    )
    await_then_chain_tail_list_else_head = await_then_chain_tail_list_else_receiver.get("receiver", {}).get(
        "list_add_all", {}
    )
    await_then_chain_tail_list_tail = [{"string": "patched-await-if-dynamic-runtime-tail-tail"}]
    if (
        await_then_chain_tail_list_source.get("async_future") is not True
        or await_then_chain_tail_list_source.get("body", {}).get("new_object", {}).get("type_args") != ["List<String>"]
        or await_then_chain_tail_list_source.get("params") != ["ready", "extra", "tail"]
        or len(await_then_chain_tail_list_locals) != 1
        or await_then_chain_tail_list_locals[0].get("name") != "enabled"
        or await_then_chain_tail_list_locals[0].get("value", {}).get("await", {}).get("arg") != "ready"
        or await_then_chain_tail_list_conditional.get("condition", {}).get("let_local") != 0
        or await_then_chain_tail_list_then.get("spread", {}).get("list") != await_then_chain_tail_list_tail
        or await_then_chain_tail_list_else.get("spread", {}).get("list") != await_then_chain_tail_list_tail
        or await_then_chain_tail_list_then_receiver.get("source", {}).get("arg") != "tail"
        or await_then_chain_tail_list_else_receiver.get("source", {}).get("arg") != "tail"
        or await_then_chain_tail_list_then_head.get("spread", {}).get("arg") != "extra"
        or await_then_chain_tail_list_else_head.get("spread", {}).get("arg") != "extra"
        or await_then_chain_tail_list_then_head.get("receiver", {}).get("list") != [
            {"string": "patched-await-if-dynamic-runtime-tail-head"},
            {"string": "patched-await-if-dynamic-runtime-tail-live"},
        ]
        or await_then_chain_tail_list_else_head.get("receiver", {}).get("list") != [
            {"string": "patched-await-if-dynamic-runtime-tail-head"},
            {"string": "patched-await-if-dynamic-runtime-tail-off"},
        ]
    ):
        raise SystemExit(
            "expected asyncAwaitThenConditionalDynamicRuntimeTailNames await local/list_add_all/list_for_in/static tail chain, "
            f"got {await_then_chain_tail_list_source}"
        )

    await_then_chain_tail_map_source = source_for("asyncAwaitThenConditionalDynamicRuntimeTailLabels")
    await_then_chain_tail_map_arg = await_then_chain_tail_map_source.get("body", {}).get("new_object", {}).get(
        "args", [{}]
    )[0]
    await_then_chain_tail_map_let = await_then_chain_tail_map_arg.get("let", {})
    await_then_chain_tail_map_locals = await_then_chain_tail_map_let.get("locals", [])
    await_then_chain_tail_map_conditional = await_then_chain_tail_map_let.get("body", {}).get("conditional", {})
    await_then_chain_tail_map_then = await_then_chain_tail_map_conditional.get("then", {}).get("map_add_all", {})
    await_then_chain_tail_map_else = await_then_chain_tail_map_conditional.get("else", {}).get("map_add_all", {})
    await_then_chain_tail_map_then_receiver = await_then_chain_tail_map_then.get("receiver", {}).get("map_for_in", {})
    await_then_chain_tail_map_else_receiver = await_then_chain_tail_map_else.get("receiver", {}).get("map_for_in", {})
    await_then_chain_tail_map_then_head = await_then_chain_tail_map_then_receiver.get("receiver", {}).get(
        "map_add_all", {}
    )
    await_then_chain_tail_map_else_head = await_then_chain_tail_map_else_receiver.get("receiver", {}).get(
        "map_add_all", {}
    )
    await_then_chain_tail_map_tail = [
        {
            "key": {"string": "tail"},
            "value": {"string": "patched-await-if-dynamic-runtime-tail-tail"},
        }
    ]
    if (
        await_then_chain_tail_map_source.get("async_future") is not True
        or await_then_chain_tail_map_source.get("body", {}).get("new_object", {}).get("type_args")
        != ["Map<String,String>"]
        or await_then_chain_tail_map_source.get("params") != ["ready", "extra", "tail"]
        or len(await_then_chain_tail_map_locals) != 1
        or await_then_chain_tail_map_locals[0].get("name") != "enabled"
        or await_then_chain_tail_map_locals[0].get("value", {}).get("await", {}).get("arg") != "ready"
        or await_then_chain_tail_map_conditional.get("condition", {}).get("let_local") != 0
        or await_then_chain_tail_map_then.get("spread", {}).get("map") != await_then_chain_tail_map_tail
        or await_then_chain_tail_map_else.get("spread", {}).get("map") != await_then_chain_tail_map_tail
        or await_then_chain_tail_map_then_receiver.get("source", {}).get("call_dynamic", {}).get("method")
        != "get:entries"
        or await_then_chain_tail_map_then_receiver.get("source", {}).get("call_dynamic", {}).get("receiver", {}).get(
            "arg"
        )
        != "tail"
        or await_then_chain_tail_map_else_receiver.get("source", {}).get("call_dynamic", {}).get("method")
        != "get:entries"
        or await_then_chain_tail_map_else_receiver.get("source", {}).get("call_dynamic", {}).get("receiver", {}).get(
            "arg"
        )
        != "tail"
        or await_then_chain_tail_map_then_head.get("spread", {}).get("arg") != "extra"
        or await_then_chain_tail_map_else_head.get("spread", {}).get("arg") != "extra"
        or await_then_chain_tail_map_then_head.get("receiver", {}).get("map") != [
            {"key": {"string": "mode"}, "value": {"string": "patched-await-if-dynamic-runtime-tail-map"}},
            {"key": {"string": "state"}, "value": {"string": "patched-await-if-dynamic-runtime-tail-live"}},
        ]
        or await_then_chain_tail_map_else_head.get("receiver", {}).get("map") != [
            {"key": {"string": "mode"}, "value": {"string": "patched-await-if-dynamic-runtime-tail-map"}},
            {"key": {"string": "state"}, "value": {"string": "patched-await-if-dynamic-runtime-tail-off"}},
        ]
    ):
        raise SystemExit(
            "expected asyncAwaitThenConditionalDynamicRuntimeTailLabels await local/map_add_all/map_for_in/static tail chain, "
            f"got {await_then_chain_tail_map_source}"
        )

    await_then_chain_spread_list_source = source_for("asyncAwaitThenConditionalDynamicRuntimeStaticSpreadNames")
    await_then_chain_spread_list_arg = await_then_chain_spread_list_source.get("body", {}).get("new_object", {}).get(
        "args", [{}]
    )[0]
    await_then_chain_spread_list_let = await_then_chain_spread_list_arg.get("let", {})
    await_then_chain_spread_list_locals = await_then_chain_spread_list_let.get("locals", [])
    await_then_chain_spread_list_conditional = await_then_chain_spread_list_let.get("body", {}).get("conditional", {})
    await_then_chain_spread_list_then = await_then_chain_spread_list_conditional.get("then", {}).get("list_add_all", {})
    await_then_chain_spread_list_else = await_then_chain_spread_list_conditional.get("else", {}).get("list_add_all", {})
    await_then_chain_spread_list_then_receiver = await_then_chain_spread_list_then.get("receiver", {}).get(
        "list_for_in", {}
    )
    await_then_chain_spread_list_else_receiver = await_then_chain_spread_list_else.get("receiver", {}).get(
        "list_for_in", {}
    )
    await_then_chain_spread_list_then_head = await_then_chain_spread_list_then_receiver.get("receiver", {}).get(
        "list_add_all", {}
    )
    await_then_chain_spread_list_else_head = await_then_chain_spread_list_else_receiver.get("receiver", {}).get(
        "list_add_all", {}
    )
    await_then_chain_spread_list_tail = [
        {"string": "patched-await-if-dynamic-runtime-static-spread-tail-a"},
        {"string": "patched-await-if-dynamic-runtime-static-spread-tail-b"},
    ]
    if (
        await_then_chain_spread_list_source.get("async_future") is not True
        or await_then_chain_spread_list_source.get("body", {}).get("new_object", {}).get("type_args")
        != ["List<String>"]
        or await_then_chain_spread_list_source.get("params") != ["ready", "extra", "tail"]
        or len(await_then_chain_spread_list_locals) != 1
        or await_then_chain_spread_list_locals[0].get("name") != "enabled"
        or await_then_chain_spread_list_locals[0].get("value", {}).get("await", {}).get("arg") != "ready"
        or await_then_chain_spread_list_conditional.get("condition", {}).get("let_local") != 0
        or await_then_chain_spread_list_then.get("spread", {}).get("list") != await_then_chain_spread_list_tail
        or await_then_chain_spread_list_else.get("spread", {}).get("list") != await_then_chain_spread_list_tail
        or await_then_chain_spread_list_then_receiver.get("source", {}).get("arg") != "tail"
        or await_then_chain_spread_list_else_receiver.get("source", {}).get("arg") != "tail"
        or await_then_chain_spread_list_then_head.get("spread", {}).get("arg") != "extra"
        or await_then_chain_spread_list_else_head.get("spread", {}).get("arg") != "extra"
        or await_then_chain_spread_list_then_head.get("receiver", {}).get("list") != [
            {"string": "patched-await-if-dynamic-runtime-static-spread-head"},
            {"string": "patched-await-if-dynamic-runtime-static-spread-live"},
        ]
        or await_then_chain_spread_list_else_head.get("receiver", {}).get("list") != [
            {"string": "patched-await-if-dynamic-runtime-static-spread-head"},
            {"string": "patched-await-if-dynamic-runtime-static-spread-off"},
        ]
    ):
        raise SystemExit(
            "expected asyncAwaitThenConditionalDynamicRuntimeStaticSpreadNames "
            "await local/list_add_all/list_for_in/static spread chain, "
            f"got {await_then_chain_spread_list_source}"
        )

    await_then_chain_spread_map_source = source_for("asyncAwaitThenConditionalDynamicRuntimeStaticSpreadLabels")
    await_then_chain_spread_map_arg = await_then_chain_spread_map_source.get("body", {}).get("new_object", {}).get(
        "args", [{}]
    )[0]
    await_then_chain_spread_map_let = await_then_chain_spread_map_arg.get("let", {})
    await_then_chain_spread_map_locals = await_then_chain_spread_map_let.get("locals", [])
    await_then_chain_spread_map_conditional = await_then_chain_spread_map_let.get("body", {}).get("conditional", {})
    await_then_chain_spread_map_then = await_then_chain_spread_map_conditional.get("then", {}).get("map_add_all", {})
    await_then_chain_spread_map_else = await_then_chain_spread_map_conditional.get("else", {}).get("map_add_all", {})
    await_then_chain_spread_map_then_receiver = await_then_chain_spread_map_then.get("receiver", {}).get(
        "map_for_in", {}
    )
    await_then_chain_spread_map_else_receiver = await_then_chain_spread_map_else.get("receiver", {}).get(
        "map_for_in", {}
    )
    await_then_chain_spread_map_then_head = await_then_chain_spread_map_then_receiver.get("receiver", {}).get(
        "map_add_all", {}
    )
    await_then_chain_spread_map_else_head = await_then_chain_spread_map_else_receiver.get("receiver", {}).get(
        "map_add_all", {}
    )
    await_then_chain_spread_map_tail = [
        {
            "key": {"string": "tail"},
            "value": {"string": "patched-await-if-dynamic-runtime-static-spread-tail"},
        }
    ]
    if (
        await_then_chain_spread_map_source.get("async_future") is not True
        or await_then_chain_spread_map_source.get("body", {}).get("new_object", {}).get("type_args")
        != ["Map<String,String>"]
        or await_then_chain_spread_map_source.get("params") != ["ready", "extra", "tail"]
        or len(await_then_chain_spread_map_locals) != 1
        or await_then_chain_spread_map_locals[0].get("name") != "enabled"
        or await_then_chain_spread_map_locals[0].get("value", {}).get("await", {}).get("arg") != "ready"
        or await_then_chain_spread_map_conditional.get("condition", {}).get("let_local") != 0
        or await_then_chain_spread_map_then.get("spread", {}).get("map") != await_then_chain_spread_map_tail
        or await_then_chain_spread_map_else.get("spread", {}).get("map") != await_then_chain_spread_map_tail
        or await_then_chain_spread_map_then_receiver.get("source", {}).get("call_dynamic", {}).get("method")
        != "get:entries"
        or await_then_chain_spread_map_then_receiver.get("source", {}).get("call_dynamic", {}).get("receiver", {}).get(
            "arg"
        )
        != "tail"
        or await_then_chain_spread_map_else_receiver.get("source", {}).get("call_dynamic", {}).get("method")
        != "get:entries"
        or await_then_chain_spread_map_else_receiver.get("source", {}).get("call_dynamic", {}).get("receiver", {}).get(
            "arg"
        )
        != "tail"
        or await_then_chain_spread_map_then_head.get("spread", {}).get("arg") != "extra"
        or await_then_chain_spread_map_else_head.get("spread", {}).get("arg") != "extra"
        or await_then_chain_spread_map_then_head.get("receiver", {}).get("map") != [
            {"key": {"string": "mode"}, "value": {"string": "patched-await-if-dynamic-runtime-static-spread-map"}},
            {"key": {"string": "state"}, "value": {"string": "patched-await-if-dynamic-runtime-static-spread-live"}},
        ]
        or await_then_chain_spread_map_else_head.get("receiver", {}).get("map") != [
            {"key": {"string": "mode"}, "value": {"string": "patched-await-if-dynamic-runtime-static-spread-map"}},
            {"key": {"string": "state"}, "value": {"string": "patched-await-if-dynamic-runtime-static-spread-off"}},
        ]
    ):
        raise SystemExit(
            "expected asyncAwaitThenConditionalDynamicRuntimeStaticSpreadLabels "
            "await local/map_add_all/map_for_in/static spread chain, "
            f"got {await_then_chain_spread_map_source}"
        )

    assert_await_then_runtime_collection_chains(source_for)
