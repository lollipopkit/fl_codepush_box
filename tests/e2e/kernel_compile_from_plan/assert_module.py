import json
import sys

from assert_module_async_generators import assert_async_generators
from assert_module_core_calls import assert_core_calls

module = json.load(open(sys.argv[1]))
assert module["version"] == 3, module
assert len(module["functions"]) == 184, module
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

assert_async_generators(module)
assert_core_calls(module)
print("kernel compile-from-plan drill passed")
