import json
import sys

from assert_plan_collection_await_then_chains import assert_await_then_collection_chains
from assert_plan_collection_try_await_sources import assert_collection_try_await_sources
from assert_plan_collection_try_sources import assert_collection_try_sources
from assert_plan_collection_reverse_chains import assert_direct_reverse_collection_chains
from assert_plan_collection_static_tail_chains import assert_direct_static_tail_chains

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


list_source = source_for("asyncAwaitConditionDynamicRuntimeNames")
list_arg = list_source.get("body", {}).get("new_object", {}).get("args", [{}])[0]
list_conditional = list_arg.get("conditional", {})
list_then = list_conditional.get("then", {}).get("list_for_in", {})
list_else = list_conditional.get("else", {}).get("list_for_in", {})
list_then_receiver = list_then.get("receiver", {}).get("list_add_all", {})
list_else_receiver = list_else.get("receiver", {}).get("list_add_all", {})
if (
    list_source.get("async_future") is not True
    or list_source.get("body", {}).get("new_object", {}).get("type_args") != ["List<String>"]
    or list_source.get("params") != ["ready", "extra", "tail"]
    or list_conditional.get("condition", {}).get("await", {}).get("arg") != "ready"
    or list_then.get("source", {}).get("arg") != "tail"
    or list_else.get("source", {}).get("arg") != "tail"
    or list_then_receiver.get("receiver", {}).get("list") != [
        {"string": "patched-await-condition-chain-head"},
        {"string": "patched-await-condition-chain-live"},
    ]
    or list_else_receiver.get("receiver", {}).get("list") != [
        {"string": "patched-await-condition-chain-head"},
        {"string": "patched-await-condition-chain-off"},
    ]
    or list_then_receiver.get("spread", {}).get("arg") != "extra"
    or list_else_receiver.get("spread", {}).get("arg") != "extra"
):
    raise SystemExit(
        "expected asyncAwaitConditionDynamicRuntimeNames direct await/list_add_all/list_for_in chain, "
        f"got {list_source}"
    )

list_spread_source = source_for("asyncAwaitConditionDynamicRuntimeStaticSpreadNames")
list_spread_arg = list_spread_source.get("body", {}).get("new_object", {}).get("args", [{}])[0]
list_spread_conditional = list_spread_arg.get("conditional", {})
list_spread_then = list_spread_conditional.get("then", {}).get("list_add_all", {})
list_spread_else = list_spread_conditional.get("else", {}).get("list_add_all", {})
list_spread_then_receiver = list_spread_then.get("receiver", {}).get("list_for_in", {})
list_spread_else_receiver = list_spread_else.get("receiver", {}).get("list_for_in", {})
list_spread_then_head = list_spread_then_receiver.get("receiver", {}).get("list_add_all", {})
list_spread_else_head = list_spread_else_receiver.get("receiver", {}).get("list_add_all", {})
list_spread_tail = [
    {"string": "patched-await-condition-chain-static-spread-tail-a"},
    {"string": "patched-await-condition-chain-static-spread-tail-b"},
]
if (
    list_spread_source.get("async_future") is not True
    or list_spread_source.get("body", {}).get("new_object", {}).get("type_args") != ["List<String>"]
    or list_spread_source.get("params") != ["ready", "extra", "tail"]
    or list_spread_conditional.get("condition", {}).get("await", {}).get("arg") != "ready"
    or list_spread_then.get("spread", {}).get("list") != list_spread_tail
    or list_spread_else.get("spread", {}).get("list") != list_spread_tail
    or list_spread_then_receiver.get("source", {}).get("arg") != "tail"
    or list_spread_else_receiver.get("source", {}).get("arg") != "tail"
    or list_spread_then_head.get("spread", {}).get("arg") != "extra"
    or list_spread_else_head.get("spread", {}).get("arg") != "extra"
    or list_spread_then_head.get("receiver", {}).get("list") != [
        {"string": "patched-await-condition-chain-static-spread-head"},
        {"string": "patched-await-condition-chain-static-spread-live"},
    ]
    or list_spread_else_head.get("receiver", {}).get("list") != [
        {"string": "patched-await-condition-chain-static-spread-head"},
        {"string": "patched-await-condition-chain-static-spread-off"},
    ]
):
    raise SystemExit(
        "expected asyncAwaitConditionDynamicRuntimeStaticSpreadNames "
        "direct await/list_add_all/list_for_in/static spread chain, "
        f"got {list_spread_source}"
    )

list_tail_source = source_for("asyncAwaitConditionDynamicRuntimeTailNames")
list_tail_arg = list_tail_source.get("body", {}).get("new_object", {}).get("args", [{}])[0]
list_tail_conditional = list_tail_arg.get("conditional", {})
list_tail_then = list_tail_conditional.get("then", {}).get("list_add_all", {})
list_tail_else = list_tail_conditional.get("else", {}).get("list_add_all", {})
list_tail_then_receiver = list_tail_then.get("receiver", {}).get("list_for_in", {})
list_tail_else_receiver = list_tail_else.get("receiver", {}).get("list_for_in", {})
list_tail_then_head = list_tail_then_receiver.get("receiver", {}).get("list_add_all", {})
list_tail_else_head = list_tail_else_receiver.get("receiver", {}).get("list_add_all", {})
list_tail = [{"string": "patched-await-condition-chain-tail-tail"}]
if (
    list_tail_source.get("async_future") is not True
    or list_tail_source.get("body", {}).get("new_object", {}).get("type_args") != ["List<String>"]
    or list_tail_source.get("params") != ["ready", "extra", "tail"]
    or list_tail_conditional.get("condition", {}).get("await", {}).get("arg") != "ready"
    or list_tail_then.get("spread", {}).get("list") != list_tail
    or list_tail_else.get("spread", {}).get("list") != list_tail
    or list_tail_then_receiver.get("source", {}).get("arg") != "tail"
    or list_tail_else_receiver.get("source", {}).get("arg") != "tail"
    or list_tail_then_head.get("spread", {}).get("arg") != "extra"
    or list_tail_else_head.get("spread", {}).get("arg") != "extra"
    or list_tail_then_head.get("receiver", {}).get("list") != [
        {"string": "patched-await-condition-chain-tail-head"},
        {"string": "patched-await-condition-chain-tail-live"},
    ]
    or list_tail_else_head.get("receiver", {}).get("list") != [
        {"string": "patched-await-condition-chain-tail-head"},
        {"string": "patched-await-condition-chain-tail-off"},
    ]
):
    raise SystemExit(
        "expected asyncAwaitConditionDynamicRuntimeTailNames "
        "direct await/list_add_all/list_for_in/static tail chain, "
        f"got {list_tail_source}"
    )

list_dynamic_source = source_for("asyncAwaitConditionDynamicRuntimeDynamicNames")
list_dynamic_arg = list_dynamic_source.get("body", {}).get("new_object", {}).get("args", [{}])[0]
list_dynamic_conditional = list_dynamic_arg.get("conditional", {})
list_dynamic_then = list_dynamic_conditional.get("then", {}).get("list_add_all", {})
list_dynamic_else = list_dynamic_conditional.get("else", {}).get("list_add_all", {})
list_dynamic_then_for = list_dynamic_then.get("receiver", {}).get("list_for_in", {})
list_dynamic_else_for = list_dynamic_else.get("receiver", {}).get("list_for_in", {})
list_dynamic_then_head = list_dynamic_then_for.get("receiver", {}).get("list_add_all", {})
list_dynamic_else_head = list_dynamic_else_for.get("receiver", {}).get("list_add_all", {})
if (
    list_dynamic_source.get("async_future") is not True
    or list_dynamic_source.get("body", {}).get("new_object", {}).get("type_args") != ["List<String>"]
    or list_dynamic_source.get("params") != ["ready", "extra", "middle", "tail"]
    or list_dynamic_conditional.get("condition", {}).get("await", {}).get("arg") != "ready"
    or list_dynamic_then.get("spread", {}).get("arg") != "tail"
    or list_dynamic_else.get("spread", {}).get("arg") != "tail"
    or list_dynamic_then_for.get("source", {}).get("arg") != "middle"
    or list_dynamic_else_for.get("source", {}).get("arg") != "middle"
    or list_dynamic_then_head.get("spread", {}).get("arg") != "extra"
    or list_dynamic_else_head.get("spread", {}).get("arg") != "extra"
    or list_dynamic_then_head.get("receiver", {}).get("list") != [
        {"string": "patched-await-condition-chain-dynamic-head"},
        {"string": "patched-await-condition-chain-dynamic-live"},
    ]
    or list_dynamic_else_head.get("receiver", {}).get("list") != [
        {"string": "patched-await-condition-chain-dynamic-head"},
        {"string": "patched-await-condition-chain-dynamic-off"},
    ]
):
    raise SystemExit(
        "expected asyncAwaitConditionDynamicRuntimeDynamicNames "
        "direct await/list_add_all/list_for_in/dynamic spread chain, "
        f"got {list_dynamic_source}"
    )

list_double_dynamic_source = source_for("asyncAwaitConditionDynamicDynamicRuntimeNames")
list_double_dynamic_arg = list_double_dynamic_source.get("body", {}).get("new_object", {}).get("args", [{}])[0]
list_double_dynamic_conditional = list_double_dynamic_arg.get("conditional", {})
list_double_dynamic_then = list_double_dynamic_conditional.get("then", {}).get("list_for_in", {})
list_double_dynamic_else = list_double_dynamic_conditional.get("else", {}).get("list_for_in", {})
list_double_dynamic_then_middle = list_double_dynamic_then.get("receiver", {}).get("list_add_all", {})
list_double_dynamic_else_middle = list_double_dynamic_else.get("receiver", {}).get("list_add_all", {})
list_double_dynamic_then_head = list_double_dynamic_then_middle.get("receiver", {}).get("list_add_all", {})
list_double_dynamic_else_head = list_double_dynamic_else_middle.get("receiver", {}).get("list_add_all", {})
if (
    list_double_dynamic_source.get("async_future") is not True
    or list_double_dynamic_source.get("body", {}).get("new_object", {}).get("type_args") != ["List<String>"]
    or list_double_dynamic_source.get("params") != ["ready", "extra", "middle", "tail"]
    or list_double_dynamic_conditional.get("condition", {}).get("await", {}).get("arg") != "ready"
    or list_double_dynamic_then.get("source", {}).get("arg") != "tail"
    or list_double_dynamic_else.get("source", {}).get("arg") != "tail"
    or list_double_dynamic_then_middle.get("spread", {}).get("arg") != "middle"
    or list_double_dynamic_else_middle.get("spread", {}).get("arg") != "middle"
    or list_double_dynamic_then_head.get("spread", {}).get("arg") != "extra"
    or list_double_dynamic_else_head.get("spread", {}).get("arg") != "extra"
    or list_double_dynamic_then_head.get("receiver", {}).get("list") != [
        {"string": "patched-await-condition-double-dynamic-runtime-head"},
        {"string": "patched-await-condition-double-dynamic-runtime-live"},
    ]
    or list_double_dynamic_else_head.get("receiver", {}).get("list") != [
        {"string": "patched-await-condition-double-dynamic-runtime-head"},
        {"string": "patched-await-condition-double-dynamic-runtime-off"},
    ]
):
    raise SystemExit(
        "expected asyncAwaitConditionDynamicDynamicRuntimeNames "
        "direct await/list_add_all/list_add_all/list_for_in chain, "
        f"got {list_double_dynamic_source}"
    )

list_triple_dynamic_source = source_for("asyncAwaitConditionDynamicDynamicDynamicNames")
list_triple_dynamic_arg = list_triple_dynamic_source.get("body", {}).get("new_object", {}).get("args", [{}])[0]
list_triple_dynamic_conditional = list_triple_dynamic_arg.get("conditional", {})
list_triple_dynamic_then_tail = list_triple_dynamic_conditional.get("then", {}).get("list_add_all", {})
list_triple_dynamic_else_tail = list_triple_dynamic_conditional.get("else", {}).get("list_add_all", {})
list_triple_dynamic_then_middle = list_triple_dynamic_then_tail.get("receiver", {}).get("list_add_all", {})
list_triple_dynamic_else_middle = list_triple_dynamic_else_tail.get("receiver", {}).get("list_add_all", {})
list_triple_dynamic_then_extra = list_triple_dynamic_then_middle.get("receiver", {}).get("list_add_all", {})
list_triple_dynamic_else_extra = list_triple_dynamic_else_middle.get("receiver", {}).get("list_add_all", {})
if (
    list_triple_dynamic_source.get("async_future") is not True
    or list_triple_dynamic_source.get("body", {}).get("new_object", {}).get("type_args") != ["List<String>"]
    or list_triple_dynamic_source.get("params") != ["ready", "extra", "middle", "tail"]
    or list_triple_dynamic_conditional.get("condition", {}).get("await", {}).get("arg") != "ready"
    or list_triple_dynamic_then_tail.get("spread", {}).get("arg") != "tail"
    or list_triple_dynamic_else_tail.get("spread", {}).get("arg") != "tail"
    or list_triple_dynamic_then_middle.get("spread", {}).get("arg") != "middle"
    or list_triple_dynamic_else_middle.get("spread", {}).get("arg") != "middle"
    or list_triple_dynamic_then_extra.get("spread", {}).get("arg") != "extra"
    or list_triple_dynamic_else_extra.get("spread", {}).get("arg") != "extra"
    or list_triple_dynamic_then_extra.get("receiver", {}).get("list") != [
        {"string": "patched-await-condition-triple-dynamic-head"},
        {"string": "patched-await-condition-triple-dynamic-live"},
    ]
    or list_triple_dynamic_else_extra.get("receiver", {}).get("list") != [
        {"string": "patched-await-condition-triple-dynamic-head"},
        {"string": "patched-await-condition-triple-dynamic-off"},
    ]
):
    raise SystemExit(
        "expected asyncAwaitConditionDynamicDynamicDynamicNames "
        "direct await/list_add_all/list_add_all/list_add_all chain, "
        f"got {list_triple_dynamic_source}"
    )

map_source = source_for("asyncAwaitConditionDynamicRuntimeLabels")
map_arg = map_source.get("body", {}).get("new_object", {}).get("args", [{}])[0]
map_conditional = map_arg.get("conditional", {})
map_then = map_conditional.get("then", {}).get("map_for_in", {})
map_else = map_conditional.get("else", {}).get("map_for_in", {})
map_then_receiver = map_then.get("receiver", {}).get("map_add_all", {})
map_else_receiver = map_else.get("receiver", {}).get("map_add_all", {})
if (
    map_source.get("async_future") is not True
    or map_source.get("body", {}).get("new_object", {}).get("type_args") != ["Map<String,String>"]
    or map_source.get("params") != ["ready", "extra", "tail"]
    or map_conditional.get("condition", {}).get("await", {}).get("arg") != "ready"
    or map_then.get("source", {}).get("call_dynamic", {}).get("method") != "get:entries"
    or map_then.get("source", {}).get("call_dynamic", {}).get("receiver", {}).get("arg") != "tail"
    or map_else.get("source", {}).get("call_dynamic", {}).get("method") != "get:entries"
    or map_else.get("source", {}).get("call_dynamic", {}).get("receiver", {}).get("arg") != "tail"
    or map_then_receiver.get("receiver", {}).get("map") != [
        {"key": {"string": "mode"}, "value": {"string": "patched-await-condition-chain-map"}},
        {"key": {"string": "state"}, "value": {"string": "patched-await-condition-chain-live"}},
    ]
    or map_else_receiver.get("receiver", {}).get("map") != [
        {"key": {"string": "mode"}, "value": {"string": "patched-await-condition-chain-map"}},
        {"key": {"string": "state"}, "value": {"string": "patched-await-condition-chain-off"}},
    ]
    or map_then_receiver.get("spread", {}).get("arg") != "extra"
    or map_else_receiver.get("spread", {}).get("arg") != "extra"
):
    raise SystemExit(
        "expected asyncAwaitConditionDynamicRuntimeLabels direct await/map_add_all/map_for_in chain, "
        f"got {map_source}"
    )

map_spread_source = source_for("asyncAwaitConditionDynamicRuntimeStaticSpreadLabels")
map_spread_arg = map_spread_source.get("body", {}).get("new_object", {}).get("args", [{}])[0]
map_spread_conditional = map_spread_arg.get("conditional", {})
map_spread_then = map_spread_conditional.get("then", {}).get("map_add_all", {})
map_spread_else = map_spread_conditional.get("else", {}).get("map_add_all", {})
map_spread_then_receiver = map_spread_then.get("receiver", {}).get("map_for_in", {})
map_spread_else_receiver = map_spread_else.get("receiver", {}).get("map_for_in", {})
map_spread_then_head = map_spread_then_receiver.get("receiver", {}).get("map_add_all", {})
map_spread_else_head = map_spread_else_receiver.get("receiver", {}).get("map_add_all", {})
map_spread_tail = [
    {
        "key": {"string": "tail"},
        "value": {"string": "patched-await-condition-chain-static-spread-tail"},
    }
]
if (
    map_spread_source.get("async_future") is not True
    or map_spread_source.get("body", {}).get("new_object", {}).get("type_args") != ["Map<String,String>"]
    or map_spread_source.get("params") != ["ready", "extra", "tail"]
    or map_spread_conditional.get("condition", {}).get("await", {}).get("arg") != "ready"
    or map_spread_then.get("spread", {}).get("map") != map_spread_tail
    or map_spread_else.get("spread", {}).get("map") != map_spread_tail
    or map_spread_then_receiver.get("source", {}).get("call_dynamic", {}).get("method") != "get:entries"
    or map_spread_then_receiver.get("source", {}).get("call_dynamic", {}).get("receiver", {}).get("arg") != "tail"
    or map_spread_else_receiver.get("source", {}).get("call_dynamic", {}).get("method") != "get:entries"
    or map_spread_else_receiver.get("source", {}).get("call_dynamic", {}).get("receiver", {}).get("arg") != "tail"
    or map_spread_then_head.get("spread", {}).get("arg") != "extra"
    or map_spread_else_head.get("spread", {}).get("arg") != "extra"
    or map_spread_then_head.get("receiver", {}).get("map") != [
        {"key": {"string": "mode"}, "value": {"string": "patched-await-condition-chain-static-spread-map"}},
        {"key": {"string": "state"}, "value": {"string": "patched-await-condition-chain-static-spread-live"}},
    ]
    or map_spread_else_head.get("receiver", {}).get("map") != [
        {"key": {"string": "mode"}, "value": {"string": "patched-await-condition-chain-static-spread-map"}},
        {"key": {"string": "state"}, "value": {"string": "patched-await-condition-chain-static-spread-off"}},
    ]
):
    raise SystemExit(
        "expected asyncAwaitConditionDynamicRuntimeStaticSpreadLabels "
        "direct await/map_add_all/map_for_in/static spread chain, "
        f"got {map_spread_source}"
    )

map_tail_source = source_for("asyncAwaitConditionDynamicRuntimeTailLabels")
map_tail_arg = map_tail_source.get("body", {}).get("new_object", {}).get("args", [{}])[0]
map_tail_conditional = map_tail_arg.get("conditional", {})
map_tail_then = map_tail_conditional.get("then", {}).get("map_add_all", {})
map_tail_else = map_tail_conditional.get("else", {}).get("map_add_all", {})
map_tail_then_receiver = map_tail_then.get("receiver", {}).get("map_for_in", {})
map_tail_else_receiver = map_tail_else.get("receiver", {}).get("map_for_in", {})
map_tail_then_head = map_tail_then_receiver.get("receiver", {}).get("map_add_all", {})
map_tail_else_head = map_tail_else_receiver.get("receiver", {}).get("map_add_all", {})
map_tail = [
    {
        "key": {"string": "tail"},
        "value": {"string": "patched-await-condition-chain-tail-tail"},
    }
]
if (
    map_tail_source.get("async_future") is not True
    or map_tail_source.get("body", {}).get("new_object", {}).get("type_args") != ["Map<String,String>"]
    or map_tail_source.get("params") != ["ready", "extra", "tail"]
    or map_tail_conditional.get("condition", {}).get("await", {}).get("arg") != "ready"
    or map_tail_then.get("spread", {}).get("map") != map_tail
    or map_tail_else.get("spread", {}).get("map") != map_tail
    or map_tail_then_receiver.get("source", {}).get("call_dynamic", {}).get("method") != "get:entries"
    or map_tail_then_receiver.get("source", {}).get("call_dynamic", {}).get("receiver", {}).get("arg") != "tail"
    or map_tail_else_receiver.get("source", {}).get("call_dynamic", {}).get("method") != "get:entries"
    or map_tail_else_receiver.get("source", {}).get("call_dynamic", {}).get("receiver", {}).get("arg") != "tail"
    or map_tail_then_head.get("spread", {}).get("arg") != "extra"
    or map_tail_else_head.get("spread", {}).get("arg") != "extra"
    or map_tail_then_head.get("receiver", {}).get("map") != [
        {"key": {"string": "mode"}, "value": {"string": "patched-await-condition-chain-tail-map"}},
        {"key": {"string": "state"}, "value": {"string": "patched-await-condition-chain-tail-live"}},
    ]
    or map_tail_else_head.get("receiver", {}).get("map") != [
        {"key": {"string": "mode"}, "value": {"string": "patched-await-condition-chain-tail-map"}},
        {"key": {"string": "state"}, "value": {"string": "patched-await-condition-chain-tail-off"}},
    ]
):
    raise SystemExit(
        "expected asyncAwaitConditionDynamicRuntimeTailLabels "
        "direct await/map_add_all/map_for_in/static tail chain, "
        f"got {map_tail_source}"
    )

map_dynamic_source = source_for("asyncAwaitConditionDynamicRuntimeDynamicLabels")
map_dynamic_arg = map_dynamic_source.get("body", {}).get("new_object", {}).get("args", [{}])[0]
map_dynamic_conditional = map_dynamic_arg.get("conditional", {})
map_dynamic_then = map_dynamic_conditional.get("then", {}).get("map_add_all", {})
map_dynamic_else = map_dynamic_conditional.get("else", {}).get("map_add_all", {})
map_dynamic_then_for = map_dynamic_then.get("receiver", {}).get("map_for_in", {})
map_dynamic_else_for = map_dynamic_else.get("receiver", {}).get("map_for_in", {})
map_dynamic_then_head = map_dynamic_then_for.get("receiver", {}).get("map_add_all", {})
map_dynamic_else_head = map_dynamic_else_for.get("receiver", {}).get("map_add_all", {})
if (
    map_dynamic_source.get("async_future") is not True
    or map_dynamic_source.get("body", {}).get("new_object", {}).get("type_args") != ["Map<String,String>"]
    or map_dynamic_source.get("params") != ["ready", "extra", "middle", "tail"]
    or map_dynamic_conditional.get("condition", {}).get("await", {}).get("arg") != "ready"
    or map_dynamic_then.get("spread", {}).get("arg") != "tail"
    or map_dynamic_else.get("spread", {}).get("arg") != "tail"
    or map_dynamic_then_for.get("source", {}).get("call_dynamic", {}).get("method") != "get:entries"
    or map_dynamic_then_for.get("source", {}).get("call_dynamic", {}).get("receiver", {}).get("arg") != "middle"
    or map_dynamic_else_for.get("source", {}).get("call_dynamic", {}).get("method") != "get:entries"
    or map_dynamic_else_for.get("source", {}).get("call_dynamic", {}).get("receiver", {}).get("arg") != "middle"
    or map_dynamic_then_head.get("spread", {}).get("arg") != "extra"
    or map_dynamic_else_head.get("spread", {}).get("arg") != "extra"
    or map_dynamic_then_head.get("receiver", {}).get("map") != [
        {"key": {"string": "mode"}, "value": {"string": "patched-await-condition-chain-dynamic-map"}},
        {"key": {"string": "state"}, "value": {"string": "patched-await-condition-chain-dynamic-live"}},
    ]
    or map_dynamic_else_head.get("receiver", {}).get("map") != [
        {"key": {"string": "mode"}, "value": {"string": "patched-await-condition-chain-dynamic-map"}},
        {"key": {"string": "state"}, "value": {"string": "patched-await-condition-chain-dynamic-off"}},
    ]
):
    raise SystemExit(
        "expected asyncAwaitConditionDynamicRuntimeDynamicLabels "
        "direct await/map_add_all/map_for_in/dynamic spread chain, "
        f"got {map_dynamic_source}"
    )

map_double_dynamic_source = source_for("asyncAwaitConditionDynamicDynamicRuntimeLabels")
map_double_dynamic_arg = map_double_dynamic_source.get("body", {}).get("new_object", {}).get("args", [{}])[0]
map_double_dynamic_conditional = map_double_dynamic_arg.get("conditional", {})
map_double_dynamic_then = map_double_dynamic_conditional.get("then", {}).get("map_for_in", {})
map_double_dynamic_else = map_double_dynamic_conditional.get("else", {}).get("map_for_in", {})
map_double_dynamic_then_middle = map_double_dynamic_then.get("receiver", {}).get("map_add_all", {})
map_double_dynamic_else_middle = map_double_dynamic_else.get("receiver", {}).get("map_add_all", {})
map_double_dynamic_then_head = map_double_dynamic_then_middle.get("receiver", {}).get("map_add_all", {})
map_double_dynamic_else_head = map_double_dynamic_else_middle.get("receiver", {}).get("map_add_all", {})
if (
    map_double_dynamic_source.get("async_future") is not True
    or map_double_dynamic_source.get("body", {}).get("new_object", {}).get("type_args") != ["Map<String,String>"]
    or map_double_dynamic_source.get("params") != ["ready", "extra", "middle", "tail"]
    or map_double_dynamic_conditional.get("condition", {}).get("await", {}).get("arg") != "ready"
    or map_double_dynamic_then.get("source", {}).get("call_dynamic", {}).get("method") != "get:entries"
    or map_double_dynamic_then.get("source", {}).get("call_dynamic", {}).get("receiver", {}).get("arg") != "tail"
    or map_double_dynamic_else.get("source", {}).get("call_dynamic", {}).get("method") != "get:entries"
    or map_double_dynamic_else.get("source", {}).get("call_dynamic", {}).get("receiver", {}).get("arg") != "tail"
    or map_double_dynamic_then_middle.get("spread", {}).get("arg") != "middle"
    or map_double_dynamic_else_middle.get("spread", {}).get("arg") != "middle"
    or map_double_dynamic_then_head.get("spread", {}).get("arg") != "extra"
    or map_double_dynamic_else_head.get("spread", {}).get("arg") != "extra"
    or map_double_dynamic_then_head.get("receiver", {}).get("map") != [
        {"key": {"string": "mode"}, "value": {"string": "patched-await-condition-double-dynamic-runtime-map"}},
        {"key": {"string": "state"}, "value": {"string": "patched-await-condition-double-dynamic-runtime-live"}},
    ]
    or map_double_dynamic_else_head.get("receiver", {}).get("map") != [
        {"key": {"string": "mode"}, "value": {"string": "patched-await-condition-double-dynamic-runtime-map"}},
        {"key": {"string": "state"}, "value": {"string": "patched-await-condition-double-dynamic-runtime-off"}},
    ]
):
    raise SystemExit(
        "expected asyncAwaitConditionDynamicDynamicRuntimeLabels "
        "direct await/map_add_all/map_add_all/map_for_in chain, "
        f"got {map_double_dynamic_source}"
    )

map_triple_dynamic_source = source_for("asyncAwaitConditionDynamicDynamicDynamicLabels")
map_triple_dynamic_arg = map_triple_dynamic_source.get("body", {}).get("new_object", {}).get("args", [{}])[0]
map_triple_dynamic_conditional = map_triple_dynamic_arg.get("conditional", {})
map_triple_dynamic_then_tail = map_triple_dynamic_conditional.get("then", {}).get("map_add_all", {})
map_triple_dynamic_else_tail = map_triple_dynamic_conditional.get("else", {}).get("map_add_all", {})
map_triple_dynamic_then_middle = map_triple_dynamic_then_tail.get("receiver", {}).get("map_add_all", {})
map_triple_dynamic_else_middle = map_triple_dynamic_else_tail.get("receiver", {}).get("map_add_all", {})
map_triple_dynamic_then_extra = map_triple_dynamic_then_middle.get("receiver", {}).get("map_add_all", {})
map_triple_dynamic_else_extra = map_triple_dynamic_else_middle.get("receiver", {}).get("map_add_all", {})
if (
    map_triple_dynamic_source.get("async_future") is not True
    or map_triple_dynamic_source.get("body", {}).get("new_object", {}).get("type_args") != ["Map<String,String>"]
    or map_triple_dynamic_source.get("params") != ["ready", "extra", "middle", "tail"]
    or map_triple_dynamic_conditional.get("condition", {}).get("await", {}).get("arg") != "ready"
    or map_triple_dynamic_then_tail.get("spread", {}).get("arg") != "tail"
    or map_triple_dynamic_else_tail.get("spread", {}).get("arg") != "tail"
    or map_triple_dynamic_then_middle.get("spread", {}).get("arg") != "middle"
    or map_triple_dynamic_else_middle.get("spread", {}).get("arg") != "middle"
    or map_triple_dynamic_then_extra.get("spread", {}).get("arg") != "extra"
    or map_triple_dynamic_else_extra.get("spread", {}).get("arg") != "extra"
    or map_triple_dynamic_then_extra.get("receiver", {}).get("map") != [
        {"key": {"string": "mode"}, "value": {"string": "patched-await-condition-triple-dynamic-map"}},
        {"key": {"string": "state"}, "value": {"string": "patched-await-condition-triple-dynamic-live"}},
    ]
    or map_triple_dynamic_else_extra.get("receiver", {}).get("map") != [
        {"key": {"string": "mode"}, "value": {"string": "patched-await-condition-triple-dynamic-map"}},
        {"key": {"string": "state"}, "value": {"string": "patched-await-condition-triple-dynamic-off"}},
    ]
):
    raise SystemExit(
        "expected asyncAwaitConditionDynamicDynamicDynamicLabels "
        "direct await/map_add_all/map_add_all/map_add_all chain, "
        f"got {map_triple_dynamic_source}"
    )

assert_direct_reverse_collection_chains(source_for)
assert_direct_static_tail_chains(source_for)
assert_await_then_collection_chains(source_for)
assert_collection_try_sources(source_for)
assert_collection_try_await_sources(source_for)
