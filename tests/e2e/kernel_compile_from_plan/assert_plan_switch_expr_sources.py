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


def nested_switch(expr):
    first = expr.get("conditional", {})
    second = first.get("else", {}).get("conditional", {})
    return first, second, second.get("else", {})


sync_source = source_for("syncSwitchLabel")
first, second, fallback = nested_switch(sync_source.get("body", {}))
if (
    sync_source.get("async_kind") not in (None, "sync")
    or sync_source.get("params") != ["tier"]
    or first.get("condition", {}).get("op") != "=="
    or first.get("condition", {}).get("left", {}).get("arg") != "tier"
    or first.get("condition", {}).get("right", {}).get("string") != "gold"
    or first.get("then", {}).get("string") != "patched-switch-gold"
    or second.get("condition", {}).get("right", {}).get("string") != "silver"
    or second.get("then", {}).get("string") != "patched-switch-silver"
    or fallback.get("string") != "patched-switch-other"
):
    raise SystemExit(f"expected syncSwitchLabel nested conditional switch source, got {sync_source}")

async_source = source_for("asyncSwitchLabel")
async_value = async_source.get("body", {}).get("new_object", {}).get("args", [{}])[0]
first, second, fallback = nested_switch(async_value)
if (
    async_source.get("async_future") is not True
    or async_source.get("params") != ["tier"]
    or first.get("condition", {}).get("left", {}).get("arg") != "tier"
    or first.get("then", {}).get("string") != "patched-async-switch-gold"
    or second.get("then", {}).get("string") != "patched-async-switch-silver"
    or fallback.get("string") != "patched-async-switch-other"
):
    raise SystemExit(f"expected asyncSwitchLabel async switch source, got {async_source}")

await_source = source_for("asyncAwaitThenSwitchLabel")
await_value = await_source.get("body", {}).get("new_object", {}).get("args", [{}])[0]
await_let = await_value.get("let", {})
await_local = await_let.get("locals", [{}])[0]
first, second, fallback = nested_switch(await_let.get("body", {}))
if (
    await_source.get("async_future") is not True
    or await_local.get("name") != "tier"
    or await_local.get("value", {}).get("await", {}).get("arg") != "ready"
    or first.get("condition", {}).get("left", {}).get("let_local") != 0
    or first.get("then", {}).get("string") != "patched-await-switch-gold"
    or second.get("then", {}).get("string") != "patched-await-switch-silver"
    or fallback.get("string") != "patched-await-switch-other"
):
    raise SystemExit(f"expected asyncAwaitThenSwitchLabel await-local switch source, got {await_source}")

score_source = source_for("syncSwitchScore")
first, second, fallback = nested_switch(score_source.get("body", {}))
if (
    score_source.get("return_type") != "int"
    or first.get("condition", {}).get("left", {}).get("arg") != "code"
    or first.get("condition", {}).get("right", {}).get("int") != 7
    or first.get("then", {}).get("int") != 70
    or second.get("condition", {}).get("right", {}).get("int") != 9
    or second.get("then", {}).get("int") != 90
    or fallback.get("int") != 10
):
    raise SystemExit(f"expected syncSwitchScore int switch source, got {score_source}")

list_source = source_for("switchListNames")
items = list_source.get("body", {}).get("list", [])
first, second, fallback = nested_switch(items[1] if len(items) > 1 else {})
if (
    list_source.get("params") != ["tier"]
    or items[0].get("string") != "patched-switch-list-head"
    or first.get("then", {}).get("string") != "patched-switch-list-gold"
    or second.get("then", {}).get("string") != "patched-switch-list-silver"
    or fallback.get("string") != "patched-switch-list-other"
    or items[2].get("string") != "patched-switch-list-tail"
):
    raise SystemExit(f"expected switchListNames list-embedded switch source, got {list_source}")

map_source = source_for("switchMapLabels")
entries = map_source.get("body", {}).get("map", [])
state_value = entries[1].get("value", {}) if len(entries) > 1 else {}
first, second, fallback = nested_switch(state_value)
if (
    map_source.get("params") != ["code"]
    or entries[0].get("key", {}).get("string") != "mode"
    or entries[0].get("value", {}).get("string") != "patched-switch-map"
    or first.get("then", {}).get("string") != "patched-switch-map-seven"
    or second.get("then", {}).get("string") != "patched-switch-map-nine"
    or fallback.get("string") != "patched-switch-map-other"
):
    raise SystemExit(f"expected switchMapLabels map-embedded switch source, got {map_source}")

guarded = patch_by_member.get("unchangedGuardedSwitchLabel")
if guarded is None:
    raise SystemExit("missing inventory entry for unchangedGuardedSwitchLabel")
if guarded.get("bytecode_source") is not None:
    raise SystemExit(f"guarded switch must stay fail-closed: {guarded}")
if guarded.get("unsupported_reasons") != ["unsupported_kernel_node"]:
    raise SystemExit(f"expected guarded switch unsupported_kernel_node, got {guarded}")
