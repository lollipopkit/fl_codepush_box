import json
import sys

from assert_module_async_generators import assert_async_generators
from assert_module_async_chain_groups import (
    assert_async_awaited_runtime_collection_sources,
    assert_async_collection_control_super_chains,
    assert_async_collection_deep_spread_for_chains,
    assert_async_generator_guarded_switch_chains,
    assert_async_generator_switch_statement_chains,
    assert_async_generator_switch_stream_chains,
    assert_async_list_for_chains,
    assert_async_loop_guarded_switch_chains,
    assert_async_loop_update_chains,
    assert_async_map_for_chains,
    assert_async_not_await_collection_chains,
    assert_async_not_await_control_chains,
    assert_async_not_await_guarded_switch_chains,
    assert_async_object_call_type_collection_chains,
    assert_async_object_loop_finalizer_chains,
    assert_async_switch_statement_collection_chains,
)
from assert_module_async_loop_finalizer_guards import assert_async_loop_finalizer_guards
from assert_module_collection_switch import assert_collection_switch
from assert_module_core_calls import assert_core_calls
from assert_module_generator_collection_chains import assert_generator_collection_chains
from assert_module_generator_finalizer_chains import assert_generator_finalizer_chains
from assert_module_generator_object_call_type_chains import (
    assert_generator_object_call_type_chains,
)
from assert_module_generator_object_switch_collection_chains import (
    assert_generator_object_switch_collection_chains,
)
from assert_module_generator_async_chain_groups import (
    assert_generator_async_await_for_await_stream_chains,
    assert_generator_async_awaited_runtime_collection_sources,
    assert_generator_async_collection_stream_finalizer_chains,
    assert_generator_async_nested_loop_switch_collection_chains,
    assert_generator_async_object_loop_finalizer_chains,
    assert_generator_async_pending_guard_super_chains,
    assert_generator_async_stream_guarded_super_chains,
    assert_generator_async_stream_super_chains,
    assert_generator_async_switch_selected_stream_chains,
    assert_generator_async_switch_selected_stream_finalizer_chains,
    assert_generator_async_triple_switch_stream_finalizer_chains,
    assert_generator_async_yield_await_collection_for_chains,
    assert_generator_async_yield_await_value_chains,
    assert_generator_async_yield_star_await_stream_chains,
)
from assert_module_generator_stream_chains import assert_generator_stream_chains
from assert_module_generator_sync_object_switch_collection_chains import (
    assert_generator_sync_object_switch_collection_chains,
)
from assert_module_generator_sync_object_loop_finalizer_chains import (
    assert_generator_sync_object_loop_finalizer_chains,
)
from assert_module_generator_sync_nested_loop_switch_collection_chains import (
    assert_generator_sync_nested_loop_switch_collection_chains,
)
from assert_module_sync_generator_switch_iterable_chains import (
    assert_sync_generator_switch_iterable_chains,
)

module = json.load(open(sys.argv[1]))
assert module["version"] == 3, module
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
sync_switch_multi_value = next(
    item
    for item in module["functions"]
    if item["name"].endswith("::syncSwitchMultiValueLabel")
)
assert sync_switch_multi_value["async_kind"] == "sync", sync_switch_multi_value
assert sync_switch_multi_value["param_count"] == 1, sync_switch_multi_value
assert sync_switch_multi_value["code"].count(0x21) >= 4, sync_switch_multi_value
assert 0x31 in sync_switch_multi_value["code"], sync_switch_multi_value
assert any(
    constant.get("type") == "String"
    and constant.get("value") == "patched-switch-premium"
    for constant in sync_switch_multi_value["constants"]
), sync_switch_multi_value
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
async_switch_multi_value = next(
    item
    for item in module["functions"]
    if item["name"].endswith("::asyncSwitchMultiValueLabel")
)
assert async_switch_multi_value["async_kind"] == "async_future", async_switch_multi_value
assert async_switch_multi_value["param_count"] == 1, async_switch_multi_value
assert async_switch_multi_value["code"].count(0x21) >= 4, async_switch_multi_value
assert any(
    constant.get("type") == "String"
    and constant.get("value") == "patched-async-switch-premium"
    for constant in async_switch_multi_value["constants"]
), async_switch_multi_value
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
await_switch_multi_value = next(
    item
    for item in module["functions"]
    if item["name"].endswith("::asyncAwaitThenSwitchMultiValueLabel")
)
assert await_switch_multi_value["async_kind"] == "async_future", await_switch_multi_value
assert await_switch_multi_value["param_count"] == 1, await_switch_multi_value
assert 0x62 in await_switch_multi_value["code"], await_switch_multi_value
assert await_switch_multi_value["code"].count(0x21) >= 4, await_switch_multi_value
assert any(
    constant.get("type") == "String"
    and constant.get("value") == "patched-await-switch-premium"
    for constant in await_switch_multi_value["constants"]
), await_switch_multi_value
guarded_switch_label = next(
    item
    for item in module["functions"]
    if item["name"].endswith("::unchangedGuardedSwitchLabel")
)
assert guarded_switch_label["async_kind"] == "sync", guarded_switch_label
assert guarded_switch_label["param_count"] == 2, guarded_switch_label
assert guarded_switch_label["code"].count(0x21) >= 2, guarded_switch_label
assert guarded_switch_label["code"].count(0x31) >= 4, guarded_switch_label
assert any(
    constant.get("type") == "Bool" and constant.get("value") is False
    for constant in guarded_switch_label["constants"]
), guarded_switch_label
assert any(
    constant.get("type") == "String"
    and constant.get("value") == "patched-guarded-switch-gold"
    for constant in guarded_switch_label["constants"]
), guarded_switch_label
async_guarded_switch_label = next(
    item
    for item in module["functions"]
    if item["name"].endswith("::asyncGuardedSwitchLabel")
)
assert async_guarded_switch_label["async_kind"] == "async_future", async_guarded_switch_label
assert async_guarded_switch_label["param_count"] == 2, async_guarded_switch_label
assert async_guarded_switch_label["code"].count(0x21) >= 2, async_guarded_switch_label
assert async_guarded_switch_label["code"].count(0x31) >= 4, async_guarded_switch_label
assert any(
    constant.get("type") == "String"
    and constant.get("value") == "patched-async-guarded-switch-gold"
    for constant in async_guarded_switch_label["constants"]
), async_guarded_switch_label
await_guarded_switch_label = next(
    item
    for item in module["functions"]
    if item["name"].endswith("::asyncAwaitThenGuardedSwitchLabel")
)
assert await_guarded_switch_label["async_kind"] == "async_future", await_guarded_switch_label
assert await_guarded_switch_label["param_count"] == 2, await_guarded_switch_label
assert 0x62 in await_guarded_switch_label["code"], await_guarded_switch_label
assert await_guarded_switch_label["code"].count(0x21) >= 2, await_guarded_switch_label
assert await_guarded_switch_label["code"].count(0x31) >= 4, await_guarded_switch_label
assert any(
    constant.get("type") == "String"
    and constant.get("value") == "patched-await-guarded-switch-gold"
    for constant in await_guarded_switch_label["constants"]
), await_guarded_switch_label
switch_score = next(
    item for item in module["functions"] if item["name"].endswith("::syncSwitchScore")
)
assert switch_score["return_convention"] == "unboxed_int64", switch_score
assert switch_score["param_count"] == 1, switch_score
assert 0x21 in switch_score["code"], switch_score
switch_multi_score = next(
    item
    for item in module["functions"]
    if item["name"].endswith("::syncSwitchMultiValueScore")
)
assert switch_multi_score["return_convention"] == "unboxed_int64", switch_multi_score
assert switch_multi_score["param_count"] == 1, switch_multi_score
assert switch_multi_score["code"].count(0x21) >= 4, switch_multi_score

await_condition_switch_try_catch = next(
    item
    for item in module["functions"]
    if item["name"].endswith("::asyncAwaitConditionSwitchTryCatchRecoveryLabel")
)
assert await_condition_switch_try_catch["async_kind"] == "async_future", await_condition_switch_try_catch
assert await_condition_switch_try_catch["code"].count(0x62) >= 2, await_condition_switch_try_catch
assert 0x21 in await_condition_switch_try_catch["code"], await_condition_switch_try_catch
assert 0x61 in await_condition_switch_try_catch["code"], await_condition_switch_try_catch
assert any(
    constant.get("type") == "String"
    and constant.get("value") == "patched-await-condition-switch-try-catch-blocked"
    for constant in await_condition_switch_try_catch["constants"]
), await_condition_switch_try_catch
await_condition_switch_try_finally = next(
    item
    for item in module["functions"]
    if item["name"].endswith("::asyncAwaitConditionSwitchTryFinallyCleanupLabel")
)
assert await_condition_switch_try_finally["async_kind"] == "async_future", await_condition_switch_try_finally
assert await_condition_switch_try_finally["code"].count(0x62) >= 2, await_condition_switch_try_finally
assert 0x21 in await_condition_switch_try_finally["code"], await_condition_switch_try_finally
assert 0x63 in await_condition_switch_try_finally["code"], await_condition_switch_try_finally
await_then_switch_try_catch = next(
    item
    for item in module["functions"]
    if item["name"].endswith("::asyncAwaitThenSwitchTryCatchRecoveryLabel")
)
assert await_then_switch_try_catch["async_kind"] == "async_future", await_then_switch_try_catch
assert await_then_switch_try_catch["code"].count(0x62) >= 2, await_then_switch_try_catch
assert 0x21 in await_then_switch_try_catch["code"], await_then_switch_try_catch
assert 0x61 in await_then_switch_try_catch["code"], await_then_switch_try_catch
await_then_switch_try_finally = next(
    item
    for item in module["functions"]
    if item["name"].endswith("::asyncAwaitThenSwitchTryFinallyCleanupLabel")
)
assert await_then_switch_try_finally["async_kind"] == "async_future", await_then_switch_try_finally
assert await_then_switch_try_finally["code"].count(0x62) >= 2, await_then_switch_try_finally
assert 0x21 in await_then_switch_try_finally["code"], await_then_switch_try_finally
assert 0x63 in await_then_switch_try_finally["code"], await_then_switch_try_finally
double_await_switch_try_catch_finally = next(
    item
    for item in module["functions"]
    if item["name"].endswith("::asyncDoubleAwaitSwitchTryCatchFinallyRecoveryLabel")
)
assert double_await_switch_try_catch_finally["async_kind"] == "async_future", double_await_switch_try_catch_finally
assert double_await_switch_try_catch_finally["code"].count(0x62) >= 3, double_await_switch_try_catch_finally
assert 0x21 in double_await_switch_try_catch_finally["code"], double_await_switch_try_catch_finally
assert 0x61 in double_await_switch_try_catch_finally["code"], double_await_switch_try_catch_finally
assert 0x63 in double_await_switch_try_catch_finally["code"], double_await_switch_try_catch_finally
double_await_switch_try_finally = next(
    item
    for item in module["functions"]
    if item["name"].endswith("::asyncDoubleAwaitSwitchTryFinallyCleanupLabel")
)
assert double_await_switch_try_finally["async_kind"] == "async_future", double_await_switch_try_finally
assert double_await_switch_try_finally["code"].count(0x62) >= 2, double_await_switch_try_finally
assert 0x21 in double_await_switch_try_finally["code"], double_await_switch_try_finally
assert 0x63 in double_await_switch_try_finally["code"], double_await_switch_try_finally
switch_await_guard = next(
    item
    for item in module["functions"]
    if item["name"].endswith("::asyncSwitchAwaitGuardLabel")
)
assert switch_await_guard["async_kind"] == "async_future", switch_await_guard
assert 0x62 in switch_await_guard["code"], switch_await_guard
assert 0x21 in switch_await_guard["code"], switch_await_guard
assert any(
    constant.get("type") == "String"
    and constant.get("value") == "patched-switch-await-guard-gold"
    for constant in switch_await_guard["constants"]
), switch_await_guard
await_switch_await_guard = next(
    item
    for item in module["functions"]
    if item["name"].endswith("::asyncAwaitThenSwitchAwaitGuardLabel")
)
assert await_switch_await_guard["async_kind"] == "async_future", await_switch_await_guard
assert await_switch_await_guard["code"].count(0x62) >= 2, await_switch_await_guard
assert 0x21 in await_switch_await_guard["code"], await_switch_await_guard
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
guarded_switch_statement = next(
    item
    for item in module["functions"]
    if item["name"].endswith("::unchangedGuardedSwitchStatementLabel")
)
assert guarded_switch_statement["async_kind"] == "sync", guarded_switch_statement
assert guarded_switch_statement["param_count"] == 2, guarded_switch_statement
assert guarded_switch_statement["code"].count(0x21) >= 2, guarded_switch_statement
assert guarded_switch_statement["code"].count(0x31) >= 4, guarded_switch_statement
assert any(
    constant.get("type") == "Bool" and constant.get("value") is False
    for constant in guarded_switch_statement["constants"]
), guarded_switch_statement
assert any(
    constant.get("type") == "String"
    and constant.get("value") == "patched-guarded-switch-stmt-gold"
    for constant in guarded_switch_statement["constants"]
), guarded_switch_statement
async_guarded_switch_statement = next(
    item
    for item in module["functions"]
    if item["name"].endswith("::asyncGuardedSwitchStatementLabel")
)
assert async_guarded_switch_statement["async_kind"] == "async_future", async_guarded_switch_statement
assert async_guarded_switch_statement["param_count"] == 2, async_guarded_switch_statement
assert async_guarded_switch_statement["code"].count(0x21) >= 2, async_guarded_switch_statement
assert async_guarded_switch_statement["code"].count(0x31) >= 4, async_guarded_switch_statement
assert any(
    constant.get("type") == "String"
    and constant.get("value") == "patched-async-guarded-switch-stmt-gold"
    for constant in async_guarded_switch_statement["constants"]
), async_guarded_switch_statement
await_guarded_switch_statement = next(
    item
    for item in module["functions"]
    if item["name"].endswith("::asyncAwaitThenGuardedSwitchStatementLabel")
)
assert await_guarded_switch_statement["async_kind"] == "async_future", await_guarded_switch_statement
assert await_guarded_switch_statement["param_count"] == 2, await_guarded_switch_statement
assert 0x62 in await_guarded_switch_statement["code"], await_guarded_switch_statement
assert await_guarded_switch_statement["code"].count(0x21) >= 2, await_guarded_switch_statement
assert await_guarded_switch_statement["code"].count(0x31) >= 4, await_guarded_switch_statement
assert any(
    constant.get("type") == "String"
    and constant.get("value") == "patched-await-guarded-switch-stmt-gold"
    for constant in await_guarded_switch_statement["constants"]
), await_guarded_switch_statement
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
multi_case = next(
    item
    for item in module["functions"]
    if item["name"].endswith("::syncSwitchStatementMultiCaseLabel")
)
assert multi_case["async_kind"] == "sync", multi_case
assert multi_case["code"].count(0x21) >= 3, multi_case
multi_assigned = next(
    item
    for item in module["functions"]
    if item["name"].endswith("::asyncSwitchStatementMultiCaseAssignedLabel")
)
assert multi_assigned["async_kind"] == "async_future", multi_assigned
assert multi_assigned["code"].count(0x21) >= 3, multi_assigned
assert 0x04 in multi_assigned["code"], multi_assigned
multi_await_case = next(
    item
    for item in module["functions"]
    if item["name"].endswith("::asyncSwitchStatementMultiCaseAwaitCaseLabel")
)
assert multi_await_case["async_kind"] == "async_future", multi_await_case
assert multi_await_case["code"].count(0x21) >= 3, multi_await_case
assert multi_await_case["code"].count(0x62) >= 3, multi_await_case
assert 0x60 in multi_await_case["code"], multi_await_case
or_pattern = next(
    item
    for item in module["functions"]
    if item["name"].endswith("::syncSwitchStatementOrPatternLabel")
)
assert or_pattern["async_kind"] == "sync", or_pattern
assert or_pattern["code"].count(0x21) >= 4, or_pattern
or_pattern_assigned = next(
    item
    for item in module["functions"]
    if item["name"].endswith("::asyncSwitchStatementOrPatternAssignedLabel")
)
assert or_pattern_assigned["async_kind"] == "async_future", or_pattern_assigned
assert or_pattern_assigned["code"].count(0x21) >= 4, or_pattern_assigned
assert 0x04 in or_pattern_assigned["code"], or_pattern_assigned
or_pattern_await_case = next(
    item
    for item in module["functions"]
    if item["name"].endswith("::asyncSwitchStatementOrPatternAwaitCaseLabel")
)
assert or_pattern_await_case["async_kind"] == "async_future", or_pattern_await_case
assert or_pattern_await_case["code"].count(0x21) >= 4, or_pattern_await_case
assert or_pattern_await_case["code"].count(0x62) >= 5, or_pattern_await_case
assert 0x60 in or_pattern_await_case["code"], or_pattern_await_case
await_or_pattern = next(
    item
    for item in module["functions"]
    if item["name"].endswith("::asyncAwaitThenSwitchStatementOrPatternLabel")
)
assert await_or_pattern["async_kind"] == "async_future", await_or_pattern
assert await_or_pattern["code"].count(0x21) >= 4, await_or_pattern
assert 0x62 in await_or_pattern["code"], await_or_pattern

await_condition_switch_stmt_try_catch = next(
    item
    for item in module["functions"]
    if item["name"].endswith("::asyncAwaitConditionSwitchStatementTryCatchRecoveryLabel")
)
assert await_condition_switch_stmt_try_catch["async_kind"] == "async_future", await_condition_switch_stmt_try_catch
assert await_condition_switch_stmt_try_catch["code"].count(0x62) >= 2, await_condition_switch_stmt_try_catch
assert 0x21 in await_condition_switch_stmt_try_catch["code"], await_condition_switch_stmt_try_catch
assert 0x61 in await_condition_switch_stmt_try_catch["code"], await_condition_switch_stmt_try_catch
await_condition_switch_stmt_try_finally = next(
    item
    for item in module["functions"]
    if item["name"].endswith("::asyncAwaitConditionSwitchStatementTryFinallyCleanupLabel")
)
assert await_condition_switch_stmt_try_finally["async_kind"] == "async_future", await_condition_switch_stmt_try_finally
assert await_condition_switch_stmt_try_finally["code"].count(0x62) >= 2, await_condition_switch_stmt_try_finally
assert 0x21 in await_condition_switch_stmt_try_finally["code"], await_condition_switch_stmt_try_finally
assert 0x63 in await_condition_switch_stmt_try_finally["code"], await_condition_switch_stmt_try_finally
await_then_switch_stmt_try_catch = next(
    item
    for item in module["functions"]
    if item["name"].endswith("::asyncAwaitThenSwitchStatementTryCatchRecoveryLabel")
)
assert await_then_switch_stmt_try_catch["async_kind"] == "async_future", await_then_switch_stmt_try_catch
assert await_then_switch_stmt_try_catch["code"].count(0x62) >= 2, await_then_switch_stmt_try_catch
assert 0x21 in await_then_switch_stmt_try_catch["code"], await_then_switch_stmt_try_catch
assert 0x61 in await_then_switch_stmt_try_catch["code"], await_then_switch_stmt_try_catch
await_then_switch_stmt_try_finally = next(
    item
    for item in module["functions"]
    if item["name"].endswith("::asyncAwaitThenSwitchStatementTryFinallyCleanupLabel")
)
assert await_then_switch_stmt_try_finally["async_kind"] == "async_future", await_then_switch_stmt_try_finally
assert await_then_switch_stmt_try_finally["code"].count(0x62) >= 2, await_then_switch_stmt_try_finally
assert 0x21 in await_then_switch_stmt_try_finally["code"], await_then_switch_stmt_try_finally
assert 0x63 in await_then_switch_stmt_try_finally["code"], await_then_switch_stmt_try_finally
double_await_switch_stmt_try_catch_finally = next(
    item
    for item in module["functions"]
    if item["name"].endswith("::asyncDoubleAwaitSwitchStatementTryCatchFinallyRecoveryLabel")
)
assert double_await_switch_stmt_try_catch_finally["async_kind"] == "async_future", double_await_switch_stmt_try_catch_finally
assert double_await_switch_stmt_try_catch_finally["code"].count(0x62) >= 3, double_await_switch_stmt_try_catch_finally
assert 0x21 in double_await_switch_stmt_try_catch_finally["code"], double_await_switch_stmt_try_catch_finally
assert 0x61 in double_await_switch_stmt_try_catch_finally["code"], double_await_switch_stmt_try_catch_finally
assert 0x63 in double_await_switch_stmt_try_catch_finally["code"], double_await_switch_stmt_try_catch_finally
double_await_switch_stmt_try_finally = next(
    item
    for item in module["functions"]
    if item["name"].endswith("::asyncDoubleAwaitSwitchStatementTryFinallyCleanupLabel")
)
assert double_await_switch_stmt_try_finally["async_kind"] == "async_future", double_await_switch_stmt_try_finally
assert double_await_switch_stmt_try_finally["code"].count(0x62) >= 2, double_await_switch_stmt_try_finally
assert 0x21 in double_await_switch_stmt_try_finally["code"], double_await_switch_stmt_try_finally
assert 0x63 in double_await_switch_stmt_try_finally["code"], double_await_switch_stmt_try_finally
switch_stmt_await_guard = next(
    item
    for item in module["functions"]
    if item["name"].endswith("::asyncSwitchStatementAwaitGuardLabel")
)
assert switch_stmt_await_guard["async_kind"] == "async_future", switch_stmt_await_guard
assert 0x62 in switch_stmt_await_guard["code"], switch_stmt_await_guard
assert 0x21 in switch_stmt_await_guard["code"], switch_stmt_await_guard
assert any(
    constant.get("type") == "String"
    and constant.get("value") == "patched-switch-stmt-await-guard-gold"
    for constant in switch_stmt_await_guard["constants"]
), switch_stmt_await_guard
await_switch_stmt_await_guard = next(
    item
    for item in module["functions"]
    if item["name"].endswith("::asyncAwaitThenSwitchStatementAwaitGuardLabel")
)
assert await_switch_stmt_await_guard["async_kind"] == "async_future", await_switch_stmt_await_guard
assert await_switch_stmt_await_guard["code"].count(0x62) >= 2, await_switch_stmt_await_guard
assert 0x21 in await_switch_stmt_await_guard["code"], await_switch_stmt_await_guard

assert_async_generators(module)
assert_async_collection_deep_spread_for_chains(module)
assert_async_collection_control_super_chains(module)
assert_async_generator_guarded_switch_chains(module)
assert_async_generator_switch_statement_chains(module)
assert_async_generator_switch_stream_chains(module)
assert_async_list_for_chains(module)
assert_async_loop_finalizer_guards(module)
assert_async_loop_guarded_switch_chains(module)
assert_async_loop_update_chains(module)
assert_async_map_for_chains(module)
assert_async_not_await_collection_chains(module)
assert_async_not_await_control_chains(module)
assert_async_not_await_guarded_switch_chains(module)
assert_async_object_call_type_collection_chains(module)
assert_async_object_loop_finalizer_chains(module)
assert_async_switch_statement_collection_chains(module)
assert_async_awaited_runtime_collection_sources(module)
assert_collection_switch(module)
assert_core_calls(module)
assert_generator_collection_chains(module)
assert_generator_finalizer_chains(module)
assert_generator_object_call_type_chains(module)
assert_generator_object_switch_collection_chains(module)
assert_generator_async_object_loop_finalizer_chains(module)
assert_generator_async_nested_loop_switch_collection_chains(module)
assert_generator_async_stream_super_chains(module)
assert_generator_async_stream_guarded_super_chains(module)
assert_generator_async_pending_guard_super_chains(module)
assert_generator_async_yield_await_value_chains(module)
assert_generator_async_yield_await_collection_for_chains(module)
assert_generator_async_yield_star_await_stream_chains(module)
assert_generator_async_await_for_await_stream_chains(module)
assert_generator_async_switch_selected_stream_chains(module)
assert_generator_async_switch_selected_stream_finalizer_chains(module)
assert_generator_async_triple_switch_stream_finalizer_chains(module)
assert_generator_async_collection_stream_finalizer_chains(module)
assert_generator_async_awaited_runtime_collection_sources(module)
assert_generator_stream_chains(module)
assert_generator_sync_object_switch_collection_chains(module)
assert_generator_sync_object_loop_finalizer_chains(module)
assert_generator_sync_nested_loop_switch_collection_chains(module)
assert_sync_generator_switch_iterable_chains(module)
print("kernel compile-from-plan drill passed")
