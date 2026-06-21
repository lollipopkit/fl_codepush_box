import json
import sys

from assert_module_async_generators import assert_async_generators
from assert_module_core_calls import assert_core_calls

module = json.load(open(sys.argv[1]))
assert module["version"] == 3, module
assert len(module["functions"]) == 263, module
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

assert_async_generators(module)
assert_core_calls(module)
print("kernel compile-from-plan drill passed")
