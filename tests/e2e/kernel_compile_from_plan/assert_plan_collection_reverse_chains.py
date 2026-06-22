def assert_direct_reverse_collection_chains(source_for):
    reverse_list_source = source_for("asyncAwaitConditionRuntimeDynamicNames")
    reverse_list_arg = reverse_list_source.get("body", {}).get("new_object", {}).get("args", [{}])[0]
    reverse_list_conditional = reverse_list_arg.get("conditional", {})
    reverse_list_then = reverse_list_conditional.get("then", {}).get("list_add_all", {})
    reverse_list_else = reverse_list_conditional.get("else", {}).get("list_add_all", {})
    reverse_list_then_receiver = reverse_list_then.get("receiver", {}).get("list_for_in", {})
    reverse_list_else_receiver = reverse_list_else.get("receiver", {}).get("list_for_in", {})
    if (
        reverse_list_source.get("async_future") is not True
        or reverse_list_source.get("body", {}).get("new_object", {}).get("type_args") != ["List<String>"]
        or reverse_list_source.get("params") != ["ready", "extra", "tail"]
        or reverse_list_conditional.get("condition", {}).get("await", {}).get("arg") != "ready"
        or reverse_list_then.get("spread", {}).get("arg") != "tail"
        or reverse_list_else.get("spread", {}).get("arg") != "tail"
        or reverse_list_then_receiver.get("source", {}).get("arg") != "extra"
        or reverse_list_else_receiver.get("source", {}).get("arg") != "extra"
        or reverse_list_then_receiver.get("receiver", {}).get("list") != [
            {"string": "patched-await-condition-reverse-chain-head"},
            {"string": "patched-await-condition-reverse-chain-live"},
        ]
        or reverse_list_else_receiver.get("receiver", {}).get("list") != [
            {"string": "patched-await-condition-reverse-chain-head"},
            {"string": "patched-await-condition-reverse-chain-off"},
        ]
    ):
        raise SystemExit(
            "expected asyncAwaitConditionRuntimeDynamicNames direct await/list_for_in/list_add_all chain, "
            f"got {reverse_list_source}"
        )

    reverse_list_spread_source = source_for("asyncAwaitConditionRuntimeDynamicStaticSpreadNames")
    reverse_list_spread_arg = reverse_list_spread_source.get("body", {}).get("new_object", {}).get("args", [{}])[0]
    reverse_list_spread_conditional = reverse_list_spread_arg.get("conditional", {})
    reverse_list_spread_then = reverse_list_spread_conditional.get("then", {}).get("list_add_all", {})
    reverse_list_spread_else = reverse_list_spread_conditional.get("else", {}).get("list_add_all", {})
    reverse_list_spread_then_receiver = reverse_list_spread_then.get("receiver", {}).get("list_add_all", {})
    reverse_list_spread_else_receiver = reverse_list_spread_else.get("receiver", {}).get("list_add_all", {})
    reverse_list_spread_then_head = reverse_list_spread_then_receiver.get("receiver", {}).get("list_for_in", {})
    reverse_list_spread_else_head = reverse_list_spread_else_receiver.get("receiver", {}).get("list_for_in", {})
    reverse_list_spread_tail = [
        {"string": "patched-await-condition-reverse-chain-static-spread-tail-a"},
        {"string": "patched-await-condition-reverse-chain-static-spread-tail-b"},
    ]
    if (
        reverse_list_spread_source.get("async_future") is not True
        or reverse_list_spread_source.get("body", {}).get("new_object", {}).get("type_args") != ["List<String>"]
        or reverse_list_spread_source.get("params") != ["ready", "extra", "tail"]
        or reverse_list_spread_conditional.get("condition", {}).get("await", {}).get("arg") != "ready"
        or reverse_list_spread_then.get("spread", {}).get("list") != reverse_list_spread_tail
        or reverse_list_spread_else.get("spread", {}).get("list") != reverse_list_spread_tail
        or reverse_list_spread_then_receiver.get("spread", {}).get("arg") != "tail"
        or reverse_list_spread_else_receiver.get("spread", {}).get("arg") != "tail"
        or reverse_list_spread_then_head.get("source", {}).get("arg") != "extra"
        or reverse_list_spread_else_head.get("source", {}).get("arg") != "extra"
        or reverse_list_spread_then_head.get("receiver", {}).get("list") != [
            {"string": "patched-await-condition-reverse-chain-static-spread-head"},
            {"string": "patched-await-condition-reverse-chain-static-spread-live"},
        ]
        or reverse_list_spread_else_head.get("receiver", {}).get("list") != [
            {"string": "patched-await-condition-reverse-chain-static-spread-head"},
            {"string": "patched-await-condition-reverse-chain-static-spread-off"},
        ]
    ):
        raise SystemExit(
            "expected asyncAwaitConditionRuntimeDynamicStaticSpreadNames "
            "direct await/list_for_in/list_add_all/static spread chain, "
            f"got {reverse_list_spread_source}"
        )

    reverse_list_tail_source = source_for("asyncAwaitConditionRuntimeDynamicTailNames")
    reverse_list_tail_arg = reverse_list_tail_source.get("body", {}).get("new_object", {}).get("args", [{}])[0]
    reverse_list_tail_conditional = reverse_list_tail_arg.get("conditional", {})
    reverse_list_tail_then = reverse_list_tail_conditional.get("then", {}).get("list_add_all", {})
    reverse_list_tail_else = reverse_list_tail_conditional.get("else", {}).get("list_add_all", {})
    reverse_list_tail_then_receiver = reverse_list_tail_then.get("receiver", {}).get("list_add_all", {})
    reverse_list_tail_else_receiver = reverse_list_tail_else.get("receiver", {}).get("list_add_all", {})
    reverse_list_tail_then_head = reverse_list_tail_then_receiver.get("receiver", {}).get("list_for_in", {})
    reverse_list_tail_else_head = reverse_list_tail_else_receiver.get("receiver", {}).get("list_for_in", {})
    reverse_list_tail = [{"string": "patched-await-condition-reverse-chain-tail-tail"}]
    if (
        reverse_list_tail_source.get("async_future") is not True
        or reverse_list_tail_source.get("body", {}).get("new_object", {}).get("type_args") != ["List<String>"]
        or reverse_list_tail_source.get("params") != ["ready", "extra", "tail"]
        or reverse_list_tail_conditional.get("condition", {}).get("await", {}).get("arg") != "ready"
        or reverse_list_tail_then.get("spread", {}).get("list") != reverse_list_tail
        or reverse_list_tail_else.get("spread", {}).get("list") != reverse_list_tail
        or reverse_list_tail_then_receiver.get("spread", {}).get("arg") != "tail"
        or reverse_list_tail_else_receiver.get("spread", {}).get("arg") != "tail"
        or reverse_list_tail_then_head.get("source", {}).get("arg") != "extra"
        or reverse_list_tail_else_head.get("source", {}).get("arg") != "extra"
        or reverse_list_tail_then_head.get("receiver", {}).get("list") != [
            {"string": "patched-await-condition-reverse-chain-tail-head"},
            {"string": "patched-await-condition-reverse-chain-tail-live"},
        ]
        or reverse_list_tail_else_head.get("receiver", {}).get("list") != [
            {"string": "patched-await-condition-reverse-chain-tail-head"},
            {"string": "patched-await-condition-reverse-chain-tail-off"},
        ]
    ):
        raise SystemExit(
            "expected asyncAwaitConditionRuntimeDynamicTailNames "
            "direct await/list_for_in/list_add_all/static tail chain, "
            f"got {reverse_list_tail_source}"
        )

    reverse_list_runtime_source = source_for("asyncAwaitConditionRuntimeDynamicRuntimeNames")
    reverse_list_runtime_arg = reverse_list_runtime_source.get("body", {}).get("new_object", {}).get("args", [{}])[0]
    reverse_list_runtime_conditional = reverse_list_runtime_arg.get("conditional", {})
    reverse_list_runtime_then = reverse_list_runtime_conditional.get("then", {}).get("list_for_in", {})
    reverse_list_runtime_else = reverse_list_runtime_conditional.get("else", {}).get("list_for_in", {})
    reverse_list_runtime_then_receiver = reverse_list_runtime_then.get("receiver", {}).get("list_add_all", {})
    reverse_list_runtime_else_receiver = reverse_list_runtime_else.get("receiver", {}).get("list_add_all", {})
    reverse_list_runtime_then_head = reverse_list_runtime_then_receiver.get("receiver", {}).get("list_for_in", {})
    reverse_list_runtime_else_head = reverse_list_runtime_else_receiver.get("receiver", {}).get("list_for_in", {})
    if (
        reverse_list_runtime_source.get("async_future") is not True
        or reverse_list_runtime_source.get("body", {}).get("new_object", {}).get("type_args") != ["List<String>"]
        or reverse_list_runtime_source.get("params") != ["ready", "extra", "middle", "tail"]
        or reverse_list_runtime_conditional.get("condition", {}).get("await", {}).get("arg") != "ready"
        or reverse_list_runtime_then.get("source", {}).get("arg") != "tail"
        or reverse_list_runtime_else.get("source", {}).get("arg") != "tail"
        or reverse_list_runtime_then_receiver.get("spread", {}).get("arg") != "middle"
        or reverse_list_runtime_else_receiver.get("spread", {}).get("arg") != "middle"
        or reverse_list_runtime_then_head.get("source", {}).get("arg") != "extra"
        or reverse_list_runtime_else_head.get("source", {}).get("arg") != "extra"
        or reverse_list_runtime_then_head.get("receiver", {}).get("list") != [
            {"string": "patched-await-condition-reverse-chain-runtime-head"},
            {"string": "patched-await-condition-reverse-chain-runtime-live"},
        ]
        or reverse_list_runtime_else_head.get("receiver", {}).get("list") != [
            {"string": "patched-await-condition-reverse-chain-runtime-head"},
            {"string": "patched-await-condition-reverse-chain-runtime-off"},
        ]
    ):
        raise SystemExit(
            "expected asyncAwaitConditionRuntimeDynamicRuntimeNames "
            "direct await/list_for_in/list_add_all/list_for_in chain, "
            f"got {reverse_list_runtime_source}"
        )

    reverse_list_double_runtime_source = source_for("asyncAwaitConditionRuntimeRuntimeDynamicNames")
    reverse_list_double_runtime_arg = reverse_list_double_runtime_source.get("body", {}).get("new_object", {}).get(
        "args", [{}]
    )[0]
    reverse_list_double_runtime_conditional = reverse_list_double_runtime_arg.get("conditional", {})
    reverse_list_double_runtime_then = reverse_list_double_runtime_conditional.get("then", {}).get("list_add_all", {})
    reverse_list_double_runtime_else = reverse_list_double_runtime_conditional.get("else", {}).get("list_add_all", {})
    reverse_list_double_runtime_then_middle = reverse_list_double_runtime_then.get("receiver", {}).get("list_for_in", {})
    reverse_list_double_runtime_else_middle = reverse_list_double_runtime_else.get("receiver", {}).get("list_for_in", {})
    reverse_list_double_runtime_then_extra = reverse_list_double_runtime_then_middle.get("receiver", {}).get(
        "list_for_in", {}
    )
    reverse_list_double_runtime_else_extra = reverse_list_double_runtime_else_middle.get("receiver", {}).get(
        "list_for_in", {}
    )
    if (
        reverse_list_double_runtime_source.get("async_future") is not True
        or reverse_list_double_runtime_source.get("body", {}).get("new_object", {}).get("type_args") != ["List<String>"]
        or reverse_list_double_runtime_source.get("params") != ["ready", "extra", "middle", "tail"]
        or reverse_list_double_runtime_conditional.get("condition", {}).get("await", {}).get("arg") != "ready"
        or reverse_list_double_runtime_then.get("spread", {}).get("arg") != "tail"
        or reverse_list_double_runtime_else.get("spread", {}).get("arg") != "tail"
        or reverse_list_double_runtime_then_middle.get("source", {}).get("arg") != "middle"
        or reverse_list_double_runtime_else_middle.get("source", {}).get("arg") != "middle"
        or reverse_list_double_runtime_then_extra.get("source", {}).get("arg") != "extra"
        or reverse_list_double_runtime_else_extra.get("source", {}).get("arg") != "extra"
        or reverse_list_double_runtime_then_extra.get("receiver", {}).get("list") != [
            {"string": "patched-await-condition-double-runtime-dynamic-head"},
            {"string": "patched-await-condition-double-runtime-dynamic-live"},
        ]
        or reverse_list_double_runtime_else_extra.get("receiver", {}).get("list") != [
            {"string": "patched-await-condition-double-runtime-dynamic-head"},
            {"string": "patched-await-condition-double-runtime-dynamic-off"},
        ]
    ):
        raise SystemExit(
            "expected asyncAwaitConditionRuntimeRuntimeDynamicNames "
            "direct await/list_for_in/list_for_in/list_add_all chain, "
            f"got {reverse_list_double_runtime_source}"
        )

    reverse_list_triple_runtime_source = source_for("asyncAwaitConditionRuntimeRuntimeRuntimeNames")
    reverse_list_triple_runtime_arg = reverse_list_triple_runtime_source.get("body", {}).get("new_object", {}).get(
        "args", [{}]
    )[0]
    reverse_list_triple_runtime_conditional = reverse_list_triple_runtime_arg.get("conditional", {})
    reverse_list_triple_runtime_then_tail = reverse_list_triple_runtime_conditional.get("then", {}).get(
        "list_for_in", {}
    )
    reverse_list_triple_runtime_else_tail = reverse_list_triple_runtime_conditional.get("else", {}).get(
        "list_for_in", {}
    )
    reverse_list_triple_runtime_then_middle = reverse_list_triple_runtime_then_tail.get("receiver", {}).get(
        "list_for_in", {}
    )
    reverse_list_triple_runtime_else_middle = reverse_list_triple_runtime_else_tail.get("receiver", {}).get(
        "list_for_in", {}
    )
    reverse_list_triple_runtime_then_extra = reverse_list_triple_runtime_then_middle.get("receiver", {}).get(
        "list_for_in", {}
    )
    reverse_list_triple_runtime_else_extra = reverse_list_triple_runtime_else_middle.get("receiver", {}).get(
        "list_for_in", {}
    )
    if (
        reverse_list_triple_runtime_source.get("async_future") is not True
        or reverse_list_triple_runtime_source.get("body", {}).get("new_object", {}).get("type_args") != ["List<String>"]
        or reverse_list_triple_runtime_source.get("params") != ["ready", "extra", "middle", "tail"]
        or reverse_list_triple_runtime_conditional.get("condition", {}).get("await", {}).get("arg") != "ready"
        or reverse_list_triple_runtime_then_tail.get("source", {}).get("arg") != "tail"
        or reverse_list_triple_runtime_else_tail.get("source", {}).get("arg") != "tail"
        or reverse_list_triple_runtime_then_middle.get("source", {}).get("arg") != "middle"
        or reverse_list_triple_runtime_else_middle.get("source", {}).get("arg") != "middle"
        or reverse_list_triple_runtime_then_extra.get("source", {}).get("arg") != "extra"
        or reverse_list_triple_runtime_else_extra.get("source", {}).get("arg") != "extra"
        or reverse_list_triple_runtime_then_extra.get("receiver", {}).get("list") != [
            {"string": "patched-await-condition-triple-runtime-head"},
            {"string": "patched-await-condition-triple-runtime-live"},
        ]
        or reverse_list_triple_runtime_else_extra.get("receiver", {}).get("list") != [
            {"string": "patched-await-condition-triple-runtime-head"},
            {"string": "patched-await-condition-triple-runtime-off"},
        ]
    ):
        raise SystemExit(
            "expected asyncAwaitConditionRuntimeRuntimeRuntimeNames "
            "direct await/list_for_in/list_for_in/list_for_in chain, "
            f"got {reverse_list_triple_runtime_source}"
        )

    reverse_map_source = source_for("asyncAwaitConditionRuntimeDynamicLabels")
    reverse_map_arg = reverse_map_source.get("body", {}).get("new_object", {}).get("args", [{}])[0]
    reverse_map_conditional = reverse_map_arg.get("conditional", {})
    reverse_map_then = reverse_map_conditional.get("then", {}).get("map_add_all", {})
    reverse_map_else = reverse_map_conditional.get("else", {}).get("map_add_all", {})
    reverse_map_then_receiver = reverse_map_then.get("receiver", {}).get("map_for_in", {})
    reverse_map_else_receiver = reverse_map_else.get("receiver", {}).get("map_for_in", {})
    if (
        reverse_map_source.get("async_future") is not True
        or reverse_map_source.get("body", {}).get("new_object", {}).get("type_args") != ["Map<String,String>"]
        or reverse_map_source.get("params") != ["ready", "extra", "tail"]
        or reverse_map_conditional.get("condition", {}).get("await", {}).get("arg") != "ready"
        or reverse_map_then.get("spread", {}).get("arg") != "tail"
        or reverse_map_else.get("spread", {}).get("arg") != "tail"
        or reverse_map_then_receiver.get("source", {}).get("call_dynamic", {}).get("method") != "get:entries"
        or reverse_map_then_receiver.get("source", {}).get("call_dynamic", {}).get("receiver", {}).get("arg")
        != "extra"
        or reverse_map_else_receiver.get("source", {}).get("call_dynamic", {}).get("method") != "get:entries"
        or reverse_map_else_receiver.get("source", {}).get("call_dynamic", {}).get("receiver", {}).get("arg")
        != "extra"
        or reverse_map_then_receiver.get("receiver", {}).get("map") != [
            {"key": {"string": "mode"}, "value": {"string": "patched-await-condition-reverse-chain-map"}},
            {"key": {"string": "state"}, "value": {"string": "patched-await-condition-reverse-chain-live"}},
        ]
        or reverse_map_else_receiver.get("receiver", {}).get("map") != [
            {"key": {"string": "mode"}, "value": {"string": "patched-await-condition-reverse-chain-map"}},
            {"key": {"string": "state"}, "value": {"string": "patched-await-condition-reverse-chain-off"}},
        ]
    ):
        raise SystemExit(
            "expected asyncAwaitConditionRuntimeDynamicLabels direct await/map_for_in/map_add_all chain, "
            f"got {reverse_map_source}"
        )

    reverse_map_spread_source = source_for("asyncAwaitConditionRuntimeDynamicStaticSpreadLabels")
    reverse_map_spread_arg = reverse_map_spread_source.get("body", {}).get("new_object", {}).get("args", [{}])[0]
    reverse_map_spread_conditional = reverse_map_spread_arg.get("conditional", {})
    reverse_map_spread_then = reverse_map_spread_conditional.get("then", {}).get("map_add_all", {})
    reverse_map_spread_else = reverse_map_spread_conditional.get("else", {}).get("map_add_all", {})
    reverse_map_spread_then_receiver = reverse_map_spread_then.get("receiver", {}).get("map_add_all", {})
    reverse_map_spread_else_receiver = reverse_map_spread_else.get("receiver", {}).get("map_add_all", {})
    reverse_map_spread_then_head = reverse_map_spread_then_receiver.get("receiver", {}).get("map_for_in", {})
    reverse_map_spread_else_head = reverse_map_spread_else_receiver.get("receiver", {}).get("map_for_in", {})
    reverse_map_spread_tail = [
        {
            "key": {"string": "tail"},
            "value": {"string": "patched-await-condition-reverse-chain-static-spread-tail"},
        }
    ]
    if (
        reverse_map_spread_source.get("async_future") is not True
        or reverse_map_spread_source.get("body", {}).get("new_object", {}).get("type_args") != ["Map<String,String>"]
        or reverse_map_spread_source.get("params") != ["ready", "extra", "tail"]
        or reverse_map_spread_conditional.get("condition", {}).get("await", {}).get("arg") != "ready"
        or reverse_map_spread_then.get("spread", {}).get("map") != reverse_map_spread_tail
        or reverse_map_spread_else.get("spread", {}).get("map") != reverse_map_spread_tail
        or reverse_map_spread_then_receiver.get("spread", {}).get("arg") != "tail"
        or reverse_map_spread_else_receiver.get("spread", {}).get("arg") != "tail"
        or reverse_map_spread_then_head.get("source", {}).get("call_dynamic", {}).get("method") != "get:entries"
        or reverse_map_spread_then_head.get("source", {}).get("call_dynamic", {}).get("receiver", {}).get("arg")
        != "extra"
        or reverse_map_spread_else_head.get("source", {}).get("call_dynamic", {}).get("method") != "get:entries"
        or reverse_map_spread_else_head.get("source", {}).get("call_dynamic", {}).get("receiver", {}).get("arg")
        != "extra"
        or reverse_map_spread_then_head.get("receiver", {}).get("map") != [
            {"key": {"string": "mode"}, "value": {"string": "patched-await-condition-reverse-chain-static-spread-map"}},
            {"key": {"string": "state"}, "value": {"string": "patched-await-condition-reverse-chain-static-spread-live"}},
        ]
        or reverse_map_spread_else_head.get("receiver", {}).get("map") != [
            {"key": {"string": "mode"}, "value": {"string": "patched-await-condition-reverse-chain-static-spread-map"}},
            {"key": {"string": "state"}, "value": {"string": "patched-await-condition-reverse-chain-static-spread-off"}},
        ]
    ):
        raise SystemExit(
            "expected asyncAwaitConditionRuntimeDynamicStaticSpreadLabels "
            "direct await/map_for_in/map_add_all/static spread chain, "
            f"got {reverse_map_spread_source}"
        )

    reverse_map_tail_source = source_for("asyncAwaitConditionRuntimeDynamicTailLabels")
    reverse_map_tail_arg = reverse_map_tail_source.get("body", {}).get("new_object", {}).get("args", [{}])[0]
    reverse_map_tail_conditional = reverse_map_tail_arg.get("conditional", {})
    reverse_map_tail_then = reverse_map_tail_conditional.get("then", {}).get("map_add_all", {})
    reverse_map_tail_else = reverse_map_tail_conditional.get("else", {}).get("map_add_all", {})
    reverse_map_tail_then_receiver = reverse_map_tail_then.get("receiver", {}).get("map_add_all", {})
    reverse_map_tail_else_receiver = reverse_map_tail_else.get("receiver", {}).get("map_add_all", {})
    reverse_map_tail_then_head = reverse_map_tail_then_receiver.get("receiver", {}).get("map_for_in", {})
    reverse_map_tail_else_head = reverse_map_tail_else_receiver.get("receiver", {}).get("map_for_in", {})
    reverse_map_tail = [
        {
            "key": {"string": "tail"},
            "value": {"string": "patched-await-condition-reverse-chain-tail-tail"},
        }
    ]
    if (
        reverse_map_tail_source.get("async_future") is not True
        or reverse_map_tail_source.get("body", {}).get("new_object", {}).get("type_args") != ["Map<String,String>"]
        or reverse_map_tail_source.get("params") != ["ready", "extra", "tail"]
        or reverse_map_tail_conditional.get("condition", {}).get("await", {}).get("arg") != "ready"
        or reverse_map_tail_then.get("spread", {}).get("map") != reverse_map_tail
        or reverse_map_tail_else.get("spread", {}).get("map") != reverse_map_tail
        or reverse_map_tail_then_receiver.get("spread", {}).get("arg") != "tail"
        or reverse_map_tail_else_receiver.get("spread", {}).get("arg") != "tail"
        or reverse_map_tail_then_head.get("source", {}).get("call_dynamic", {}).get("method") != "get:entries"
        or reverse_map_tail_then_head.get("source", {}).get("call_dynamic", {}).get("receiver", {}).get("arg")
        != "extra"
        or reverse_map_tail_else_head.get("source", {}).get("call_dynamic", {}).get("method") != "get:entries"
        or reverse_map_tail_else_head.get("source", {}).get("call_dynamic", {}).get("receiver", {}).get("arg")
        != "extra"
        or reverse_map_tail_then_head.get("receiver", {}).get("map") != [
            {"key": {"string": "mode"}, "value": {"string": "patched-await-condition-reverse-chain-tail-map"}},
            {"key": {"string": "state"}, "value": {"string": "patched-await-condition-reverse-chain-tail-live"}},
        ]
        or reverse_map_tail_else_head.get("receiver", {}).get("map") != [
            {"key": {"string": "mode"}, "value": {"string": "patched-await-condition-reverse-chain-tail-map"}},
            {"key": {"string": "state"}, "value": {"string": "patched-await-condition-reverse-chain-tail-off"}},
        ]
    ):
        raise SystemExit(
            "expected asyncAwaitConditionRuntimeDynamicTailLabels "
            "direct await/map_for_in/map_add_all/static tail chain, "
            f"got {reverse_map_tail_source}"
        )

    reverse_map_runtime_source = source_for("asyncAwaitConditionRuntimeDynamicRuntimeLabels")
    reverse_map_runtime_arg = reverse_map_runtime_source.get("body", {}).get("new_object", {}).get("args", [{}])[0]
    reverse_map_runtime_conditional = reverse_map_runtime_arg.get("conditional", {})
    reverse_map_runtime_then = reverse_map_runtime_conditional.get("then", {}).get("map_for_in", {})
    reverse_map_runtime_else = reverse_map_runtime_conditional.get("else", {}).get("map_for_in", {})
    reverse_map_runtime_then_receiver = reverse_map_runtime_then.get("receiver", {}).get("map_add_all", {})
    reverse_map_runtime_else_receiver = reverse_map_runtime_else.get("receiver", {}).get("map_add_all", {})
    reverse_map_runtime_then_head = reverse_map_runtime_then_receiver.get("receiver", {}).get("map_for_in", {})
    reverse_map_runtime_else_head = reverse_map_runtime_else_receiver.get("receiver", {}).get("map_for_in", {})
    if (
        reverse_map_runtime_source.get("async_future") is not True
        or reverse_map_runtime_source.get("body", {}).get("new_object", {}).get("type_args") != ["Map<String,String>"]
        or reverse_map_runtime_source.get("params") != ["ready", "extra", "middle", "tail"]
        or reverse_map_runtime_conditional.get("condition", {}).get("await", {}).get("arg") != "ready"
        or reverse_map_runtime_then.get("source", {}).get("call_dynamic", {}).get("method") != "get:entries"
        or reverse_map_runtime_then.get("source", {}).get("call_dynamic", {}).get("receiver", {}).get("arg") != "tail"
        or reverse_map_runtime_else.get("source", {}).get("call_dynamic", {}).get("method") != "get:entries"
        or reverse_map_runtime_else.get("source", {}).get("call_dynamic", {}).get("receiver", {}).get("arg") != "tail"
        or reverse_map_runtime_then_receiver.get("spread", {}).get("arg") != "middle"
        or reverse_map_runtime_else_receiver.get("spread", {}).get("arg") != "middle"
        or reverse_map_runtime_then_head.get("source", {}).get("call_dynamic", {}).get("method") != "get:entries"
        or reverse_map_runtime_then_head.get("source", {}).get("call_dynamic", {}).get("receiver", {}).get("arg")
        != "extra"
        or reverse_map_runtime_else_head.get("source", {}).get("call_dynamic", {}).get("method") != "get:entries"
        or reverse_map_runtime_else_head.get("source", {}).get("call_dynamic", {}).get("receiver", {}).get("arg")
        != "extra"
        or reverse_map_runtime_then_head.get("receiver", {}).get("map") != [
            {"key": {"string": "mode"}, "value": {"string": "patched-await-condition-reverse-chain-runtime-map"}},
            {"key": {"string": "state"}, "value": {"string": "patched-await-condition-reverse-chain-runtime-live"}},
        ]
        or reverse_map_runtime_else_head.get("receiver", {}).get("map") != [
            {"key": {"string": "mode"}, "value": {"string": "patched-await-condition-reverse-chain-runtime-map"}},
            {"key": {"string": "state"}, "value": {"string": "patched-await-condition-reverse-chain-runtime-off"}},
        ]
    ):
        raise SystemExit(
            "expected asyncAwaitConditionRuntimeDynamicRuntimeLabels "
            "direct await/map_for_in/map_add_all/map_for_in chain, "
            f"got {reverse_map_runtime_source}"
        )

    reverse_map_double_runtime_source = source_for("asyncAwaitConditionRuntimeRuntimeDynamicLabels")
    reverse_map_double_runtime_arg = reverse_map_double_runtime_source.get("body", {}).get("new_object", {}).get(
        "args", [{}]
    )[0]
    reverse_map_double_runtime_conditional = reverse_map_double_runtime_arg.get("conditional", {})
    reverse_map_double_runtime_then = reverse_map_double_runtime_conditional.get("then", {}).get("map_add_all", {})
    reverse_map_double_runtime_else = reverse_map_double_runtime_conditional.get("else", {}).get("map_add_all", {})
    reverse_map_double_runtime_then_middle = reverse_map_double_runtime_then.get("receiver", {}).get("map_for_in", {})
    reverse_map_double_runtime_else_middle = reverse_map_double_runtime_else.get("receiver", {}).get("map_for_in", {})
    reverse_map_double_runtime_then_extra = reverse_map_double_runtime_then_middle.get("receiver", {}).get(
        "map_for_in", {}
    )
    reverse_map_double_runtime_else_extra = reverse_map_double_runtime_else_middle.get("receiver", {}).get(
        "map_for_in", {}
    )
    if (
        reverse_map_double_runtime_source.get("async_future") is not True
        or reverse_map_double_runtime_source.get("body", {}).get("new_object", {}).get("type_args")
        != ["Map<String,String>"]
        or reverse_map_double_runtime_source.get("params") != ["ready", "extra", "middle", "tail"]
        or reverse_map_double_runtime_conditional.get("condition", {}).get("await", {}).get("arg") != "ready"
        or reverse_map_double_runtime_then.get("spread", {}).get("arg") != "tail"
        or reverse_map_double_runtime_else.get("spread", {}).get("arg") != "tail"
        or reverse_map_double_runtime_then_middle.get("source", {}).get("call_dynamic", {}).get("method")
        != "get:entries"
        or reverse_map_double_runtime_then_middle.get("source", {}).get("call_dynamic", {}).get("receiver", {}).get(
            "arg"
        )
        != "middle"
        or reverse_map_double_runtime_else_middle.get("source", {}).get("call_dynamic", {}).get("method")
        != "get:entries"
        or reverse_map_double_runtime_else_middle.get("source", {}).get("call_dynamic", {}).get("receiver", {}).get(
            "arg"
        )
        != "middle"
        or reverse_map_double_runtime_then_extra.get("source", {}).get("call_dynamic", {}).get("method")
        != "get:entries"
        or reverse_map_double_runtime_then_extra.get("source", {}).get("call_dynamic", {}).get("receiver", {}).get(
            "arg"
        )
        != "extra"
        or reverse_map_double_runtime_else_extra.get("source", {}).get("call_dynamic", {}).get("method")
        != "get:entries"
        or reverse_map_double_runtime_else_extra.get("source", {}).get("call_dynamic", {}).get("receiver", {}).get(
            "arg"
        )
        != "extra"
        or reverse_map_double_runtime_then_extra.get("receiver", {}).get("map") != [
            {"key": {"string": "mode"}, "value": {"string": "patched-await-condition-double-runtime-dynamic-map"}},
            {"key": {"string": "state"}, "value": {"string": "patched-await-condition-double-runtime-dynamic-live"}},
        ]
        or reverse_map_double_runtime_else_extra.get("receiver", {}).get("map") != [
            {"key": {"string": "mode"}, "value": {"string": "patched-await-condition-double-runtime-dynamic-map"}},
            {"key": {"string": "state"}, "value": {"string": "patched-await-condition-double-runtime-dynamic-off"}},
        ]
    ):
        raise SystemExit(
            "expected asyncAwaitConditionRuntimeRuntimeDynamicLabels "
            "direct await/map_for_in/map_for_in/map_add_all chain, "
            f"got {reverse_map_double_runtime_source}"
        )

    reverse_map_triple_runtime_source = source_for("asyncAwaitConditionRuntimeRuntimeRuntimeLabels")
    reverse_map_triple_runtime_arg = reverse_map_triple_runtime_source.get("body", {}).get("new_object", {}).get(
        "args", [{}]
    )[0]
    reverse_map_triple_runtime_conditional = reverse_map_triple_runtime_arg.get("conditional", {})
    reverse_map_triple_runtime_then_tail = reverse_map_triple_runtime_conditional.get("then", {}).get("map_for_in", {})
    reverse_map_triple_runtime_else_tail = reverse_map_triple_runtime_conditional.get("else", {}).get("map_for_in", {})
    reverse_map_triple_runtime_then_middle = reverse_map_triple_runtime_then_tail.get("receiver", {}).get(
        "map_for_in", {}
    )
    reverse_map_triple_runtime_else_middle = reverse_map_triple_runtime_else_tail.get("receiver", {}).get(
        "map_for_in", {}
    )
    reverse_map_triple_runtime_then_extra = reverse_map_triple_runtime_then_middle.get("receiver", {}).get(
        "map_for_in", {}
    )
    reverse_map_triple_runtime_else_extra = reverse_map_triple_runtime_else_middle.get("receiver", {}).get(
        "map_for_in", {}
    )
    if (
        reverse_map_triple_runtime_source.get("async_future") is not True
        or reverse_map_triple_runtime_source.get("body", {}).get("new_object", {}).get("type_args") != ["Map<String,String>"]
        or reverse_map_triple_runtime_source.get("params") != ["ready", "extra", "middle", "tail"]
        or reverse_map_triple_runtime_conditional.get("condition", {}).get("await", {}).get("arg") != "ready"
        or reverse_map_triple_runtime_then_tail.get("source", {}).get("call_dynamic", {}).get("method") != "get:entries"
        or reverse_map_triple_runtime_then_tail.get("source", {}).get("call_dynamic", {}).get("receiver", {}).get(
            "arg"
        )
        != "tail"
        or reverse_map_triple_runtime_else_tail.get("source", {}).get("call_dynamic", {}).get("method") != "get:entries"
        or reverse_map_triple_runtime_else_tail.get("source", {}).get("call_dynamic", {}).get("receiver", {}).get(
            "arg"
        )
        != "tail"
        or reverse_map_triple_runtime_then_middle.get("source", {}).get("call_dynamic", {}).get("method")
        != "get:entries"
        or reverse_map_triple_runtime_then_middle.get("source", {}).get("call_dynamic", {}).get("receiver", {}).get(
            "arg"
        )
        != "middle"
        or reverse_map_triple_runtime_else_middle.get("source", {}).get("call_dynamic", {}).get("method")
        != "get:entries"
        or reverse_map_triple_runtime_else_middle.get("source", {}).get("call_dynamic", {}).get("receiver", {}).get(
            "arg"
        )
        != "middle"
        or reverse_map_triple_runtime_then_extra.get("source", {}).get("call_dynamic", {}).get("method") != "get:entries"
        or reverse_map_triple_runtime_then_extra.get("source", {}).get("call_dynamic", {}).get("receiver", {}).get(
            "arg"
        )
        != "extra"
        or reverse_map_triple_runtime_else_extra.get("source", {}).get("call_dynamic", {}).get("method") != "get:entries"
        or reverse_map_triple_runtime_else_extra.get("source", {}).get("call_dynamic", {}).get("receiver", {}).get(
            "arg"
        )
        != "extra"
        or reverse_map_triple_runtime_then_extra.get("receiver", {}).get("map") != [
            {"key": {"string": "mode"}, "value": {"string": "patched-await-condition-triple-runtime-map"}},
            {"key": {"string": "state"}, "value": {"string": "patched-await-condition-triple-runtime-live"}},
        ]
        or reverse_map_triple_runtime_else_extra.get("receiver", {}).get("map") != [
            {"key": {"string": "mode"}, "value": {"string": "patched-await-condition-triple-runtime-map"}},
            {"key": {"string": "state"}, "value": {"string": "patched-await-condition-triple-runtime-off"}},
        ]
    ):
        raise SystemExit(
            "expected asyncAwaitConditionRuntimeRuntimeRuntimeLabels "
            "direct await/map_for_in/map_for_in/map_for_in chain, "
            f"got {reverse_map_triple_runtime_source}"
        )

