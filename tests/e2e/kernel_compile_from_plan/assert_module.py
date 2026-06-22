import json
import sys

from assert_module_async_generators import assert_async_generators
from assert_module_core_calls import assert_core_calls

module = json.load(open(sys.argv[1]))
assert module["version"] == 3, module
assert len(module["functions"]) == 478, module
function = next(
    item for item in module["functions"] if item["name"].endswith("::mainValue")
)
assert function["code"][-1] == 255, function
assert 0x50 in function["code"], function
source_map = function.get("source_map")
assert isinstance(source_map, list) and len(source_map) == 1, function
assert source_map[0]["bytecode_offset"] == 0, source_map
assert isinstance(source_map[0]["source_location"], str), source_map
assert source_map[0]["source_location"].strip(), source_map
assert any(
    constant.get("type") == "String" and "helper" in constant.get("value", "")
    for constant in function["constants"]
), function
main = next(item for item in module["functions"] if item["name"].endswith("::main"))
assert main["async_kind"] == "sync", main
assert main["param_count"] == 0, main
assert main["code"].count(0x50) == 2, main
assert main["code"].count(0x05) == 2, main
assert main["code"][-1] == 255, main
assert any(
    constant.get("type") == "String" and constant.get("value", "").endswith("::mainValue")
    for constant in main["constants"]
), main
assert any(
    constant.get("type") == "String" and constant.get("value", "").endswith("::helper")
    for constant in main["constants"]
), main
sync_local_mutation = next(
    item for item in module["functions"] if item["name"].endswith("::syncLocalMutation")
)
assert sync_local_mutation["async_kind"] == "sync", sync_local_mutation
assert sync_local_mutation["param_count"] == 1, sync_local_mutation
assert 0x04 in sync_local_mutation["code"], sync_local_mutation
assert 0x03 in sync_local_mutation["code"], sync_local_mutation
assert 0x50 not in sync_local_mutation["code"], sync_local_mutation
assert any(
    constant.get("type") == "String" and constant.get("value") == "patched-local"
    for constant in sync_local_mutation["constants"]
), sync_local_mutation
assert any(
    constant.get("type") == "String" and constant.get("value") == "-"
    for constant in sync_local_mutation["constants"]
), sync_local_mutation
async_local_mutation = next(
    item for item in module["functions"] if item["name"].endswith("::asyncLocalMutation")
)
assert async_local_mutation["async_kind"] == "async_future", async_local_mutation
assert async_local_mutation["param_count"] == 1, async_local_mutation
assert 0x04 in async_local_mutation["code"], async_local_mutation
assert 0x03 in async_local_mutation["code"], async_local_mutation
assert any(
    constant.get("type") == "String" and constant.get("value") == "patched-async-local"
    for constant in async_local_mutation["constants"]
), async_local_mutation
async_await_local_mutation = next(
    item
    for item in module["functions"]
    if item["name"].endswith("::asyncAwaitThenLocalMutation")
)
assert async_await_local_mutation["async_kind"] == "async_future", async_await_local_mutation
assert async_await_local_mutation["param_count"] == 2, async_await_local_mutation
assert 0x62 in async_await_local_mutation["code"], async_await_local_mutation
assert 0x04 in async_await_local_mutation["code"], async_await_local_mutation
assert 0x03 in async_await_local_mutation["code"], async_await_local_mutation
assert 0x55 in async_await_local_mutation["code"], async_await_local_mutation
assert 0x63 in async_await_local_mutation["code"], async_await_local_mutation
assert any(
    constant.get("type") == "String" and constant.get("value") == "patched-await-local:"
    for constant in async_await_local_mutation["constants"]
), async_await_local_mutation
async_update_config_label = next(
    item for item in module["functions"] if item["name"].endswith("::asyncUpdateConfigLabel")
)
assert async_update_config_label["async_kind"] == "async_future", async_update_config_label
assert async_update_config_label["param_count"] == 2, async_update_config_label
assert 0x44 in async_update_config_label["code"], async_update_config_label
assert 0x43 in async_update_config_label["code"], async_update_config_label
assert any(
    constant.get("type") == "String" and constant.get("value") == "-async-patched"
    for constant in async_update_config_label["constants"]
), async_update_config_label
async_await_update_config_label = next(
    item
    for item in module["functions"]
    if item["name"].endswith("::asyncAwaitThenUpdateConfigLabel")
)
assert async_await_update_config_label["async_kind"] == "async_future", async_await_update_config_label
assert async_await_update_config_label["param_count"] == 2, async_await_update_config_label
assert 0x62 in async_await_update_config_label["code"], async_await_update_config_label
assert 0x03 in async_await_update_config_label["code"], async_await_update_config_label
assert 0x44 in async_await_update_config_label["code"], async_await_update_config_label
assert 0x43 in async_await_update_config_label["code"], async_await_update_config_label
assert 0x55 in async_await_update_config_label["code"], async_await_update_config_label
assert 0x63 in async_await_update_config_label["code"], async_await_update_config_label
assert any(
    constant.get("type") == "String" and constant.get("value") == "-await-patched"
    for constant in async_await_update_config_label["constants"]
), async_await_update_config_label
sync_switch_label = next(
    item for item in module["functions"] if item["name"].endswith("::syncSwitchLabel")
)
assert sync_switch_label["async_kind"] == "sync", sync_switch_label
assert sync_switch_label["param_count"] == 1, sync_switch_label
assert 0x21 in sync_switch_label["code"], sync_switch_label
assert 0x31 in sync_switch_label["code"], sync_switch_label
assert any(
    constant.get("type") == "String" and constant.get("value") == "patched-switch-gold"
    for constant in sync_switch_label["constants"]
), sync_switch_label
async_switch_label = next(
    item for item in module["functions"] if item["name"].endswith("::asyncSwitchLabel")
)
assert async_switch_label["async_kind"] == "async_future", async_switch_label
assert async_switch_label["param_count"] == 1, async_switch_label
assert 0x21 in async_switch_label["code"], async_switch_label
assert 0x31 in async_switch_label["code"], async_switch_label
assert any(
    constant.get("type") == "String" and constant.get("value") == "patched-async-switch-gold"
    for constant in async_switch_label["constants"]
), async_switch_label
await_switch_label = next(
    item
    for item in module["functions"]
    if item["name"].endswith("::asyncAwaitThenSwitchLabel")
)
assert await_switch_label["async_kind"] == "async_future", await_switch_label
assert await_switch_label["param_count"] == 1, await_switch_label
assert 0x62 in await_switch_label["code"], await_switch_label
assert 0x21 in await_switch_label["code"], await_switch_label
assert any(
    constant.get("type") == "String" and constant.get("value") == "patched-await-switch-gold"
    for constant in await_switch_label["constants"]
), await_switch_label
switch_score = next(
    item for item in module["functions"] if item["name"].endswith("::syncSwitchScore")
)
assert switch_score["return_convention"] == "unboxed_int64", switch_score
assert switch_score["param_count"] == 1, switch_score
assert 0x21 in switch_score["code"], switch_score
sync_switch_statement = next(
    item
    for item in module["functions"]
    if item["name"].endswith("::syncSwitchStatementLabel")
)
assert sync_switch_statement["async_kind"] == "sync", sync_switch_statement
assert sync_switch_statement["param_count"] == 1, sync_switch_statement
assert 0x21 in sync_switch_statement["code"], sync_switch_statement
assert 0x31 in sync_switch_statement["code"], sync_switch_statement
assert any(
    constant.get("type") == "String"
    and constant.get("value") == "patched-switch-stmt-gold"
    for constant in sync_switch_statement["constants"]
), sync_switch_statement
async_switch_statement = next(
    item
    for item in module["functions"]
    if item["name"].endswith("::asyncSwitchStatementLabel")
)
assert async_switch_statement["async_kind"] == "async_future", async_switch_statement
assert async_switch_statement["param_count"] == 1, async_switch_statement
assert 0x21 in async_switch_statement["code"], async_switch_statement
assert any(
    constant.get("type") == "String"
    and constant.get("value") == "patched-async-switch-stmt-gold"
    for constant in async_switch_statement["constants"]
), async_switch_statement
await_switch_statement = next(
    item
    for item in module["functions"]
    if item["name"].endswith("::asyncAwaitThenSwitchStatementLabel")
)
assert await_switch_statement["async_kind"] == "async_future", await_switch_statement
assert await_switch_statement["param_count"] == 1, await_switch_statement
assert 0x62 in await_switch_statement["code"], await_switch_statement
assert 0x21 in await_switch_statement["code"], await_switch_statement
assert any(
    constant.get("type") == "String"
    and constant.get("value") == "patched-await-switch-stmt-gold"
    for constant in await_switch_statement["constants"]
), await_switch_statement
switch_statement_score = next(
    item
    for item in module["functions"]
    if item["name"].endswith("::syncSwitchStatementScore")
)
assert switch_statement_score["return_convention"] == "unboxed_int64", switch_statement_score
assert switch_statement_score["param_count"] == 1, switch_statement_score
assert 0x21 in switch_statement_score["code"], switch_statement_score
assigned_switch_statement = next(
    item
    for item in module["functions"]
    if item["name"].endswith("::syncSwitchStatementAssignedLabel")
)
assert assigned_switch_statement["async_kind"] == "sync", assigned_switch_statement
assert assigned_switch_statement["param_count"] == 1, assigned_switch_statement
assert 0x04 in assigned_switch_statement["code"], assigned_switch_statement
assert 0x21 in assigned_switch_statement["code"], assigned_switch_statement
assert any(
    constant.get("type") == "String"
    and constant.get("value") == "patched-switch-stmt-assigned-gold"
    for constant in assigned_switch_statement["constants"]
), assigned_switch_statement
async_assigned_switch_statement = next(
    item
    for item in module["functions"]
    if item["name"].endswith("::asyncSwitchStatementAssignedLabel")
)
assert async_assigned_switch_statement["async_kind"] == "async_future", async_assigned_switch_statement
assert 0x04 in async_assigned_switch_statement["code"], async_assigned_switch_statement
assert 0x21 in async_assigned_switch_statement["code"], async_assigned_switch_statement
assert any(
    constant.get("type") == "String"
    and constant.get("value") == "patched-async-switch-stmt-assigned-gold"
    for constant in async_assigned_switch_statement["constants"]
), async_assigned_switch_statement
await_assigned_switch_statement = next(
    item
    for item in module["functions"]
    if item["name"].endswith("::asyncAwaitThenSwitchStatementAssignedLabel")
)
assert await_assigned_switch_statement["async_kind"] == "async_future", await_assigned_switch_statement
assert 0x62 in await_assigned_switch_statement["code"], await_assigned_switch_statement
assert 0x04 in await_assigned_switch_statement["code"], await_assigned_switch_statement
assert any(
    constant.get("type") == "String"
    and constant.get("value") == "patched-await-switch-stmt-assigned-gold"
    for constant in await_assigned_switch_statement["constants"]
), await_assigned_switch_statement
assigned_switch_score = next(
    item
    for item in module["functions"]
    if item["name"].endswith("::syncSwitchStatementAssignedScore")
)
assert assigned_switch_score["return_convention"] == "unboxed_int64", assigned_switch_score
assert 0x04 in assigned_switch_score["code"], assigned_switch_score
assert 0x21 in assigned_switch_score["code"], assigned_switch_score
switch_throw = next(
    item
    for item in module["functions"]
    if item["name"].endswith("::syncSwitchStatementThrowLabel")
)
assert switch_throw["async_kind"] == "sync", switch_throw
assert 0x21 in switch_throw["code"], switch_throw
assert 0x60 in switch_throw["code"], switch_throw
assert any(
    constant.get("type") == "String"
    and constant.get("value") == "patched-switch-stmt-throw-blocked"
    for constant in switch_throw["constants"]
), switch_throw
async_switch_throw = next(
    item
    for item in module["functions"]
    if item["name"].endswith("::asyncSwitchStatementThrowLabel")
)
assert async_switch_throw["async_kind"] == "async_future", async_switch_throw
assert 0x21 in async_switch_throw["code"], async_switch_throw
assert 0x60 in async_switch_throw["code"], async_switch_throw
await_switch_throw = next(
    item
    for item in module["functions"]
    if item["name"].endswith("::asyncAwaitThenSwitchStatementThrowLabel")
)
assert await_switch_throw["async_kind"] == "async_future", await_switch_throw
assert 0x62 in await_switch_throw["code"], await_switch_throw
assert 0x21 in await_switch_throw["code"], await_switch_throw
assert 0x60 in await_switch_throw["code"], await_switch_throw
switch_sequence = next(
    item
    for item in module["functions"]
    if item["name"].endswith("::syncSwitchStatementSequenceLabel")
)
assert switch_sequence["async_kind"] == "sync", switch_sequence
assert 0x21 in switch_sequence["code"], switch_sequence
assert 0x60 in switch_sequence["code"], switch_sequence
assert 0x03 in switch_sequence["code"], switch_sequence
async_switch_sequence = next(
    item
    for item in module["functions"]
    if item["name"].endswith("::asyncSwitchStatementSequenceLabel")
)
assert async_switch_sequence["async_kind"] == "async_future", async_switch_sequence
assert 0x21 in async_switch_sequence["code"], async_switch_sequence
assert 0x60 in async_switch_sequence["code"], async_switch_sequence
await_switch_sequence = next(
    item
    for item in module["functions"]
    if item["name"].endswith("::asyncAwaitThenSwitchStatementSequenceLabel")
)
assert await_switch_sequence["async_kind"] == "async_future", await_switch_sequence
assert 0x62 in await_switch_sequence["code"], await_switch_sequence
assert 0x21 in await_switch_sequence["code"], await_switch_sequence
assert 0x60 in await_switch_sequence["code"], await_switch_sequence
switch_side_effect = next(
    item
    for item in module["functions"]
    if item["name"].endswith("::syncSwitchStatementSideEffectTail")
)
assert switch_side_effect["async_kind"] == "sync", switch_side_effect
assert 0x21 in switch_side_effect["code"], switch_side_effect
assert switch_side_effect["code"].count(0x04) >= 4, switch_side_effect
async_switch_side_effect = next(
    item
    for item in module["functions"]
    if item["name"].endswith("::asyncSwitchStatementSideEffectTail")
)
assert async_switch_side_effect["async_kind"] == "async_future", async_switch_side_effect
assert 0x21 in async_switch_side_effect["code"], async_switch_side_effect
assert async_switch_side_effect["code"].count(0x04) >= 4, async_switch_side_effect
await_switch_side_effect = next(
    item
    for item in module["functions"]
    if item["name"].endswith("::asyncAwaitThenSwitchStatementSideEffectTail")
)
assert await_switch_side_effect["async_kind"] == "async_future", await_switch_side_effect
assert 0x62 in await_switch_side_effect["code"], await_switch_side_effect
assert 0x21 in await_switch_side_effect["code"], await_switch_side_effect
assert await_switch_side_effect["code"].count(0x04) >= 4, await_switch_side_effect
async_switch_await_case = next(
    item
    for item in module["functions"]
    if item["name"].endswith("::asyncSwitchStatementAwaitCaseLabel")
)
assert async_switch_await_case["async_kind"] == "async_future", async_switch_await_case
assert async_switch_await_case["code"].count(0x62) >= 3, async_switch_await_case
assert 0x21 in async_switch_await_case["code"], async_switch_await_case
assert 0x60 in async_switch_await_case["code"], async_switch_await_case
await_switch_await_case = next(
    item
    for item in module["functions"]
    if item["name"].endswith("::asyncAwaitThenSwitchStatementAwaitCaseLabel")
)
assert await_switch_await_case["async_kind"] == "async_future", await_switch_await_case
assert await_switch_await_case["code"].count(0x62) >= 4, await_switch_await_case
assert 0x21 in await_switch_await_case["code"], await_switch_await_case
assert 0x60 in await_switch_await_case["code"], await_switch_await_case

assert_async_generators(module)
assert_core_calls(module)
print("kernel compile-from-plan drill passed")
