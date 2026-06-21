def _function(module, name):
    return next(
        item for item in module["functions"] if item["name"].endswith(f"::{name}")
    )


def _has_debug(function, name):
    return any(entry.get("name") == name for entry in function.get("debug_locals", []))


def _assert_dynamic_case(module, name, async_kind, spec):
    function = _function(module, name)
    assert function.get("async_kind") == async_kind, function
    assert function["code"].count(0x64) == spec["yield_count"], function
    for opcode in spec.get("opcodes", ()):
        assert opcode in function["code"], function
    for opcode, count in spec.get("min_counts", {}).items():
        assert function["code"].count(opcode) >= count, function
    for local in spec.get("locals", ()):
        assert _has_debug(function, local), function


def assert_dynamic_for_in(module):
    cases = {
        "GeneratedDynamicForIn": {
            "yield_count": 2,
            "opcodes": (0x51, 0x31),
        },
        "GeneratedDynamicForInMapped": {
            "yield_count": 1,
            "opcodes": (0x42, 0x51),
            "locals": ("prefix", "value"),
        },
        "GeneratedDynamicForInMany": {
            "yield_count": 2,
            "opcodes": (0x51,),
            "min_counts": {0x42: 2},
            "locals": ("prefix", "value"),
        },
        "GeneratedDynamicForInIf": {
            "yield_count": 2,
            "opcodes": (0x31, 0x42, 0x51),
            "locals": ("prefix", "value"),
        },
        "GeneratedDynamicForInIfElse": {
            "yield_count": 2,
            "opcodes": (0x31, 0x42, 0x51),
            "locals": ("prefix", "value"),
        },
        "GeneratedDynamicForInLocal": {
            "yield_count": 1,
            "opcodes": (0x42, 0x51),
            "min_counts": {0x04: 3},
            "locals": ("prefix", "value", "marker"),
        },
        "GeneratedDynamicForInContinue": {
            "yield_count": 1,
            "opcodes": (0x31, 0x42, 0x51),
            "locals": ("prefix", "value"),
        },
        "GeneratedDynamicForInContinueAfterYield": {
            "yield_count": 2,
            "opcodes": (0x31, 0x42, 0x51),
            "locals": ("prefix", "value"),
        },
        "GeneratedDynamicForInBreak": {
            "yield_count": 1,
            "opcodes": (0x31, 0x42, 0x51),
            "min_counts": {0x30: 2},
            "locals": ("prefix", "value"),
        },
        "GeneratedDynamicForInBreakAfterYield": {
            "yield_count": 2,
            "opcodes": (0x31, 0x42, 0x51),
            "min_counts": {0x30: 2},
            "locals": ("prefix", "value"),
        },
        "GeneratedDynamicForInBreakAtEnd": {
            "yield_count": 1,
            "opcodes": (0x31, 0x42, 0x51),
            "min_counts": {0x30: 2},
            "locals": ("prefix", "value"),
        },
        "GeneratedDynamicForInContinueThenBreak": {
            "yield_count": 1,
            "opcodes": (0x30, 0x42, 0x51),
            "min_counts": {0x31: 2},
            "locals": ("prefix", "value"),
        },
        "GeneratedDynamicForInContinueYieldBreak": {
            "yield_count": 2,
            "opcodes": (0x30, 0x42, 0x51),
            "min_counts": {0x31: 3},
            "locals": ("prefix", "value"),
        },
        "GeneratedDynamicForInNested": {
            "yield_count": 1,
            "opcodes": (0x42,),
            "min_counts": {0x51: 2, 0x31: 2},
            "locals": ("prefix", "value", "suffix"),
        },
    }
    for suffix, spec in cases.items():
        _assert_dynamic_case(module, f"sync{suffix}", "sync_star", spec)
        _assert_dynamic_case(module, f"async{suffix}", "async_star", spec)
