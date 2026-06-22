def assert_direct_static_tail_chains(source_for):
    tail_list_source = source_for("asyncAwaitConditionDynamicTailNames")
    tail_list_arg = tail_list_source.get("body", {}).get("new_object", {}).get("args", [{}])[0]
    tail_list_conditional = tail_list_arg.get("conditional", {})
    tail_list_then = tail_list_conditional.get("then", {}).get("list_add_all", {})
    tail_list_else = tail_list_conditional.get("else", {}).get("list_add_all", {})
    tail_list_then_receiver = tail_list_then.get("receiver", {}).get("list_add_all", {})
    tail_list_else_receiver = tail_list_else.get("receiver", {}).get("list_add_all", {})
    if (
        tail_list_source.get("async_future") is not True
        or tail_list_source.get("body", {}).get("new_object", {}).get("type_args") != ["List<String>"]
        or tail_list_source.get("params") != ["ready", "extra"]
        or tail_list_conditional.get("condition", {}).get("await", {}).get("arg") != "ready"
        or tail_list_then_receiver.get("spread", {}).get("arg") != "extra"
        or tail_list_else_receiver.get("spread", {}).get("arg") != "extra"
        or tail_list_then.get("spread", {}).get("list") != [{"string": "patched-await-condition-tail-chain-tail"}]
        or tail_list_else.get("spread", {}).get("list") != [{"string": "patched-await-condition-tail-chain-tail"}]
        or tail_list_then_receiver.get("receiver", {}).get("list") != [
            {"string": "patched-await-condition-tail-chain-head"},
            {"string": "patched-await-condition-tail-chain-live"},
        ]
        or tail_list_else_receiver.get("receiver", {}).get("list") != [
            {"string": "patched-await-condition-tail-chain-head"},
            {"string": "patched-await-condition-tail-chain-off"},
        ]
    ):
        raise SystemExit(
            "expected asyncAwaitConditionDynamicTailNames direct await/list_add_all/static tail chain, "
            f"got {tail_list_source}"
        )

    tail_map_source = source_for("asyncAwaitConditionDynamicTailLabels")
    tail_map_arg = tail_map_source.get("body", {}).get("new_object", {}).get("args", [{}])[0]
    tail_map_conditional = tail_map_arg.get("conditional", {})
    tail_map_then = tail_map_conditional.get("then", {}).get("map_add_all", {})
    tail_map_else = tail_map_conditional.get("else", {}).get("map_add_all", {})
    tail_map_then_receiver = tail_map_then.get("receiver", {}).get("map_add_all", {})
    tail_map_else_receiver = tail_map_else.get("receiver", {}).get("map_add_all", {})
    tail_entry = {
        "key": {"string": "tail"},
        "value": {"string": "patched-await-condition-tail-chain-tail"},
    }
    if (
        tail_map_source.get("async_future") is not True
        or tail_map_source.get("body", {}).get("new_object", {}).get("type_args") != ["Map<String,String>"]
        or tail_map_source.get("params") != ["ready", "extra"]
        or tail_map_conditional.get("condition", {}).get("await", {}).get("arg") != "ready"
        or tail_map_then_receiver.get("spread", {}).get("arg") != "extra"
        or tail_map_else_receiver.get("spread", {}).get("arg") != "extra"
        or tail_map_then.get("spread", {}).get("map") != [tail_entry]
        or tail_map_else.get("spread", {}).get("map") != [tail_entry]
        or tail_map_then_receiver.get("receiver", {}).get("map") != [
            {"key": {"string": "mode"}, "value": {"string": "patched-await-condition-tail-chain-map"}},
            {"key": {"string": "state"}, "value": {"string": "patched-await-condition-tail-chain-live"}},
        ]
        or tail_map_else_receiver.get("receiver", {}).get("map") != [
            {"key": {"string": "mode"}, "value": {"string": "patched-await-condition-tail-chain-map"}},
            {"key": {"string": "state"}, "value": {"string": "patched-await-condition-tail-chain-off"}},
        ]
    ):
        raise SystemExit(
            "expected asyncAwaitConditionDynamicTailLabels direct await/map_add_all/static tail chain, "
            f"got {tail_map_source}"
        )

    runtime_tail_list_source = source_for("asyncAwaitConditionRuntimeTailNames")
    runtime_tail_list_arg = runtime_tail_list_source.get("body", {}).get("new_object", {}).get("args", [{}])[0]
    runtime_tail_list_conditional = runtime_tail_list_arg.get("conditional", {})
    runtime_tail_list_then = runtime_tail_list_conditional.get("then", {}).get("list_add_all", {})
    runtime_tail_list_else = runtime_tail_list_conditional.get("else", {}).get("list_add_all", {})
    runtime_tail_list_then_receiver = runtime_tail_list_then.get("receiver", {}).get("list_for_in", {})
    runtime_tail_list_else_receiver = runtime_tail_list_else.get("receiver", {}).get("list_for_in", {})
    if (
        runtime_tail_list_source.get("async_future") is not True
        or runtime_tail_list_source.get("body", {}).get("new_object", {}).get("type_args") != ["List<String>"]
        or runtime_tail_list_source.get("params") != ["ready", "extra"]
        or runtime_tail_list_conditional.get("condition", {}).get("await", {}).get("arg") != "ready"
        or runtime_tail_list_then_receiver.get("source", {}).get("arg") != "extra"
        or runtime_tail_list_else_receiver.get("source", {}).get("arg") != "extra"
        or runtime_tail_list_then.get("spread", {}).get("list")
        != [{"string": "patched-await-condition-runtime-tail-tail"}]
        or runtime_tail_list_else.get("spread", {}).get("list")
        != [{"string": "patched-await-condition-runtime-tail-tail"}]
        or runtime_tail_list_then_receiver.get("receiver", {}).get("list") != [
            {"string": "patched-await-condition-runtime-tail-head"},
            {"string": "patched-await-condition-runtime-tail-live"},
        ]
        or runtime_tail_list_else_receiver.get("receiver", {}).get("list") != [
            {"string": "patched-await-condition-runtime-tail-head"},
            {"string": "patched-await-condition-runtime-tail-off"},
        ]
    ):
        raise SystemExit(
            "expected asyncAwaitConditionRuntimeTailNames direct await/list_for_in/static tail chain, "
            f"got {runtime_tail_list_source}"
        )

    runtime_tail_map_source = source_for("asyncAwaitConditionRuntimeTailLabels")
    runtime_tail_map_arg = runtime_tail_map_source.get("body", {}).get("new_object", {}).get("args", [{}])[0]
    runtime_tail_map_conditional = runtime_tail_map_arg.get("conditional", {})
    runtime_tail_map_then = runtime_tail_map_conditional.get("then", {}).get("map_add_all", {})
    runtime_tail_map_else = runtime_tail_map_conditional.get("else", {}).get("map_add_all", {})
    runtime_tail_map_then_receiver = runtime_tail_map_then.get("receiver", {}).get("map_for_in", {})
    runtime_tail_map_else_receiver = runtime_tail_map_else.get("receiver", {}).get("map_for_in", {})
    runtime_tail_entry = {
        "key": {"string": "tail"},
        "value": {"string": "patched-await-condition-runtime-tail-tail"},
    }
    if (
        runtime_tail_map_source.get("async_future") is not True
        or runtime_tail_map_source.get("body", {}).get("new_object", {}).get("type_args") != ["Map<String,String>"]
        or runtime_tail_map_source.get("params") != ["ready", "extra"]
        or runtime_tail_map_conditional.get("condition", {}).get("await", {}).get("arg") != "ready"
        or runtime_tail_map_then_receiver.get("source", {}).get("call_dynamic", {}).get("method") != "get:entries"
        or runtime_tail_map_then_receiver.get("source", {}).get("call_dynamic", {}).get("receiver", {}).get("arg")
        != "extra"
        or runtime_tail_map_else_receiver.get("source", {}).get("call_dynamic", {}).get("method") != "get:entries"
        or runtime_tail_map_else_receiver.get("source", {}).get("call_dynamic", {}).get("receiver", {}).get("arg")
        != "extra"
        or runtime_tail_map_then.get("spread", {}).get("map") != [runtime_tail_entry]
        or runtime_tail_map_else.get("spread", {}).get("map") != [runtime_tail_entry]
        or runtime_tail_map_then_receiver.get("receiver", {}).get("map") != [
            {"key": {"string": "mode"}, "value": {"string": "patched-await-condition-runtime-tail-map"}},
            {"key": {"string": "state"}, "value": {"string": "patched-await-condition-runtime-tail-live"}},
        ]
        or runtime_tail_map_else_receiver.get("receiver", {}).get("map") != [
            {"key": {"string": "mode"}, "value": {"string": "patched-await-condition-runtime-tail-map"}},
            {"key": {"string": "state"}, "value": {"string": "patched-await-condition-runtime-tail-off"}},
        ]
    ):
        raise SystemExit(
            "expected asyncAwaitConditionRuntimeTailLabels direct await/map_for_in/static tail chain, "
            f"got {runtime_tail_map_source}"
        )

    static_spread_list_source = source_for("asyncAwaitConditionDynamicStaticSpreadNames")
    static_spread_list_arg = static_spread_list_source.get("body", {}).get("new_object", {}).get("args", [{}])[0]
    static_spread_list_conditional = static_spread_list_arg.get("conditional", {})
    static_spread_list_then = static_spread_list_conditional.get("then", {}).get("list_add_all", {})
    static_spread_list_else = static_spread_list_conditional.get("else", {}).get("list_add_all", {})
    static_spread_list_then_receiver = static_spread_list_then.get("receiver", {}).get("list_add_all", {})
    static_spread_list_else_receiver = static_spread_list_else.get("receiver", {}).get("list_add_all", {})
    static_spread_list_tail = [
        {"string": "patched-await-condition-static-spread-tail-a"},
        {"string": "patched-await-condition-static-spread-tail-b"},
    ]
    if (
        static_spread_list_source.get("async_future") is not True
        or static_spread_list_source.get("body", {}).get("new_object", {}).get("type_args") != ["List<String>"]
        or static_spread_list_source.get("params") != ["ready", "extra"]
        or static_spread_list_conditional.get("condition", {}).get("await", {}).get("arg") != "ready"
        or static_spread_list_then_receiver.get("spread", {}).get("arg") != "extra"
        or static_spread_list_else_receiver.get("spread", {}).get("arg") != "extra"
        or static_spread_list_then.get("spread", {}).get("list") != static_spread_list_tail
        or static_spread_list_else.get("spread", {}).get("list") != static_spread_list_tail
        or static_spread_list_then_receiver.get("receiver", {}).get("list") != [
            {"string": "patched-await-condition-static-spread-head"},
            {"string": "patched-await-condition-static-spread-live"},
        ]
        or static_spread_list_else_receiver.get("receiver", {}).get("list") != [
            {"string": "patched-await-condition-static-spread-head"},
            {"string": "patched-await-condition-static-spread-off"},
        ]
    ):
        raise SystemExit(
            "expected asyncAwaitConditionDynamicStaticSpreadNames direct await/list_add_all/static spread chain, "
            f"got {static_spread_list_source}"
        )

    static_spread_map_source = source_for("asyncAwaitConditionDynamicStaticSpreadLabels")
    static_spread_map_arg = static_spread_map_source.get("body", {}).get("new_object", {}).get("args", [{}])[0]
    static_spread_map_conditional = static_spread_map_arg.get("conditional", {})
    static_spread_map_then = static_spread_map_conditional.get("then", {}).get("map_add_all", {})
    static_spread_map_else = static_spread_map_conditional.get("else", {}).get("map_add_all", {})
    static_spread_map_then_receiver = static_spread_map_then.get("receiver", {}).get("map_add_all", {})
    static_spread_map_else_receiver = static_spread_map_else.get("receiver", {}).get("map_add_all", {})
    static_spread_map_tail = [
        {
            "key": {"string": "tail"},
            "value": {"string": "patched-await-condition-static-spread-tail"},
        }
    ]
    if (
        static_spread_map_source.get("async_future") is not True
        or static_spread_map_source.get("body", {}).get("new_object", {}).get("type_args") != ["Map<String,String>"]
        or static_spread_map_source.get("params") != ["ready", "extra"]
        or static_spread_map_conditional.get("condition", {}).get("await", {}).get("arg") != "ready"
        or static_spread_map_then_receiver.get("spread", {}).get("arg") != "extra"
        or static_spread_map_else_receiver.get("spread", {}).get("arg") != "extra"
        or static_spread_map_then.get("spread", {}).get("map") != static_spread_map_tail
        or static_spread_map_else.get("spread", {}).get("map") != static_spread_map_tail
        or static_spread_map_then_receiver.get("receiver", {}).get("map") != [
            {"key": {"string": "mode"}, "value": {"string": "patched-await-condition-static-spread-map"}},
            {"key": {"string": "state"}, "value": {"string": "patched-await-condition-static-spread-live"}},
        ]
        or static_spread_map_else_receiver.get("receiver", {}).get("map") != [
            {"key": {"string": "mode"}, "value": {"string": "patched-await-condition-static-spread-map"}},
            {"key": {"string": "state"}, "value": {"string": "patched-await-condition-static-spread-off"}},
        ]
    ):
        raise SystemExit(
            "expected asyncAwaitConditionDynamicStaticSpreadLabels direct await/map_add_all/static spread chain, "
            f"got {static_spread_map_source}"
        )

    runtime_static_spread_list_source = source_for("asyncAwaitConditionRuntimeStaticSpreadNames")
    runtime_static_spread_list_arg = runtime_static_spread_list_source.get("body", {}).get("new_object", {}).get(
        "args", [{}]
    )[0]
    runtime_static_spread_list_conditional = runtime_static_spread_list_arg.get("conditional", {})
    runtime_static_spread_list_then = runtime_static_spread_list_conditional.get("then", {}).get("list_add_all", {})
    runtime_static_spread_list_else = runtime_static_spread_list_conditional.get("else", {}).get("list_add_all", {})
    runtime_static_spread_list_then_receiver = runtime_static_spread_list_then.get("receiver", {}).get(
        "list_for_in", {}
    )
    runtime_static_spread_list_else_receiver = runtime_static_spread_list_else.get("receiver", {}).get(
        "list_for_in", {}
    )
    runtime_static_spread_list_tail = [
        {"string": "patched-await-condition-runtime-static-spread-tail-a"},
        {"string": "patched-await-condition-runtime-static-spread-tail-b"},
    ]
    if (
        runtime_static_spread_list_source.get("async_future") is not True
        or runtime_static_spread_list_source.get("body", {}).get("new_object", {}).get("type_args") != ["List<String>"]
        or runtime_static_spread_list_source.get("params") != ["ready", "extra"]
        or runtime_static_spread_list_conditional.get("condition", {}).get("await", {}).get("arg") != "ready"
        or runtime_static_spread_list_then_receiver.get("source", {}).get("arg") != "extra"
        or runtime_static_spread_list_else_receiver.get("source", {}).get("arg") != "extra"
        or runtime_static_spread_list_then.get("spread", {}).get("list") != runtime_static_spread_list_tail
        or runtime_static_spread_list_else.get("spread", {}).get("list") != runtime_static_spread_list_tail
        or runtime_static_spread_list_then_receiver.get("receiver", {}).get("list") != [
            {"string": "patched-await-condition-runtime-static-spread-head"},
            {"string": "patched-await-condition-runtime-static-spread-live"},
        ]
        or runtime_static_spread_list_else_receiver.get("receiver", {}).get("list") != [
            {"string": "patched-await-condition-runtime-static-spread-head"},
            {"string": "patched-await-condition-runtime-static-spread-off"},
        ]
    ):
        raise SystemExit(
            "expected asyncAwaitConditionRuntimeStaticSpreadNames direct await/list_for_in/static spread chain, "
            f"got {runtime_static_spread_list_source}"
        )

    runtime_static_spread_map_source = source_for("asyncAwaitConditionRuntimeStaticSpreadLabels")
    runtime_static_spread_map_arg = runtime_static_spread_map_source.get("body", {}).get("new_object", {}).get(
        "args", [{}]
    )[0]
    runtime_static_spread_map_conditional = runtime_static_spread_map_arg.get("conditional", {})
    runtime_static_spread_map_then = runtime_static_spread_map_conditional.get("then", {}).get("map_add_all", {})
    runtime_static_spread_map_else = runtime_static_spread_map_conditional.get("else", {}).get("map_add_all", {})
    runtime_static_spread_map_then_receiver = runtime_static_spread_map_then.get("receiver", {}).get("map_for_in", {})
    runtime_static_spread_map_else_receiver = runtime_static_spread_map_else.get("receiver", {}).get("map_for_in", {})
    runtime_static_spread_map_tail = [
        {
            "key": {"string": "tail"},
            "value": {"string": "patched-await-condition-runtime-static-spread-tail"},
        }
    ]
    if (
        runtime_static_spread_map_source.get("async_future") is not True
        or runtime_static_spread_map_source.get("body", {}).get("new_object", {}).get("type_args")
        != ["Map<String,String>"]
        or runtime_static_spread_map_source.get("params") != ["ready", "extra"]
        or runtime_static_spread_map_conditional.get("condition", {}).get("await", {}).get("arg") != "ready"
        or runtime_static_spread_map_then_receiver.get("source", {}).get("call_dynamic", {}).get("method")
        != "get:entries"
        or runtime_static_spread_map_then_receiver.get("source", {}).get("call_dynamic", {}).get("receiver", {}).get(
            "arg"
        )
        != "extra"
        or runtime_static_spread_map_else_receiver.get("source", {}).get("call_dynamic", {}).get("method")
        != "get:entries"
        or runtime_static_spread_map_else_receiver.get("source", {}).get("call_dynamic", {}).get("receiver", {}).get(
            "arg"
        )
        != "extra"
        or runtime_static_spread_map_then.get("spread", {}).get("map") != runtime_static_spread_map_tail
        or runtime_static_spread_map_else.get("spread", {}).get("map") != runtime_static_spread_map_tail
        or runtime_static_spread_map_then_receiver.get("receiver", {}).get("map") != [
            {"key": {"string": "mode"}, "value": {"string": "patched-await-condition-runtime-static-spread-map"}},
            {"key": {"string": "state"}, "value": {"string": "patched-await-condition-runtime-static-spread-live"}},
        ]
        or runtime_static_spread_map_else_receiver.get("receiver", {}).get("map") != [
            {"key": {"string": "mode"}, "value": {"string": "patched-await-condition-runtime-static-spread-map"}},
            {"key": {"string": "state"}, "value": {"string": "patched-await-condition-runtime-static-spread-off"}},
        ]
    ):
        raise SystemExit(
            "expected asyncAwaitConditionRuntimeStaticSpreadLabels direct await/map_for_in/static spread chain, "
            f"got {runtime_static_spread_map_source}"
        )
