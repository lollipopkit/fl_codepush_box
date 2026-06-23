# Merged assertion group. Keep this file below the fixture size limit.


# ---- assert_plan_async_awaited_runtime_collection_sources.py ----
import json
import sys

patch = json.load(open(sys.argv[1]))
patch_by_member = {f.get("member_name"): f for f in patch["functions"]}


def assert_awaited_runtime_collection_source(
    name,
    constants,
    args,
    *,
    min_awaits,
    min_list_for_in=0,
    min_map_for_in=0,
    min_list_add_all=0,
    min_map_add_all=0,
    min_conditionals=0,
    has_try_catch=False,
    has_try_finally=False,
):
    function = patch_by_member.get(name)
    if function is None:
        raise SystemExit(f"missing inventory entry for {name}")
    source = function.get("bytecode_source")
    source_json = json.dumps(source)
    if (
        function.get("unsupported_reasons") != []
        or not isinstance(source, dict)
        or source.get("async_future") is not True
        or source_json.count('"await"') < min_awaits
        or source_json.count('"list_for_in"') < min_list_for_in
        or source_json.count('"map_for_in"') < min_map_for_in
        or source_json.count('"list_add_all"') < min_list_add_all
        or source_json.count('"map_add_all"') < min_map_add_all
        or source_json.count('"conditional"') < min_conditionals
        or (has_try_catch and '"try_catch"' not in source_json)
        or (has_try_finally and '"try_finally"' not in source_json)
        or any(f'"arg": "{arg}"' not in source_json for arg in args)
        or any(f'"string": "{constant}"' not in source_json for constant in constants)
    ):
        raise SystemExit(
            f"expected {name} async awaited runtime collection source, got {function}"
        )


assert_awaited_runtime_collection_source(
    "asyncListAwaitedRuntimeSourcesSuperChain",
    ["patched-async-awaited-list-source-head"],
    ["items", "tail", "label"],
    min_awaits=3,
    min_list_for_in=1,
    min_list_add_all=1,
)
assert_awaited_runtime_collection_source(
    "asyncMapEntriesAwaitedRuntimeSourcesSuperChain",
    ["patched-async-awaited-map-source-head"],
    ["items", "tail", "label", "enabled"],
    min_awaits=5,
    min_map_for_in=1,
    min_map_add_all=1,
    min_conditionals=1,
)
assert_awaited_runtime_collection_source(
    "asyncListAwaitedRuntimeSourcesTryCatchSwitchSuperChain",
    [
        "patched-async-awaited-list-try-premium",
        "patched-async-awaited-list-try-standard",
        "patched-async-awaited-list-try-caught-",
    ],
    ["tier", "primary", "recovery", "tail", "label"],
    min_awaits=5,
    min_list_for_in=2,
    min_list_add_all=1,
    min_conditionals=2,
    has_try_catch=True,
)
assert_awaited_runtime_collection_source(
    "asyncMapAwaitedEntriesTryCatchSwitchSuperChain",
    [
        "patched-async-awaited-map-try-label",
        "patched-async-awaited-map-try-caught",
    ],
    ["enabled", "primary", "recovery", "tail", "label"],
    min_awaits=6,
    min_map_for_in=2,
    min_map_add_all=1,
    min_conditionals=1,
    has_try_catch=True,
)
assert_awaited_runtime_collection_source(
    "asyncListAwaitedRuntimeSourcesFinallyCleanupSuperChain",
    [
        "patched-async-awaited-list-finally-enabled",
        "patched-async-awaited-list-finally-disabled",
        "patched-async-awaited-list-finally-caught-",
        "patched-async-awaited-list-finally-cleanup",
    ],
    ["enabled", "primary", "recovery", "cleanup", "label"],
    min_awaits=7,
    min_list_for_in=3,
    min_list_add_all=1,
    min_conditionals=1,
    has_try_catch=True,
    has_try_finally=True,
)
assert_awaited_runtime_collection_source(
    "asyncMapAwaitedRuntimeSourcesFinallyCleanupSuperChain",
    [
        "patched-async-awaited-map-finally-premium",
        "patched-async-awaited-map-finally-caught",
        "patched-async-awaited-map-finally-cleanup",
    ],
    ["tier", "primary", "recovery", "cleanup", "label"],
    min_awaits=8,
    min_map_for_in=3,
    min_conditionals=1,
    has_try_catch=True,
    has_try_finally=True,
)

# ---- assert_plan_async_collection_control_super_chains.py ----
import json
import sys

patch = json.load(open(sys.argv[1]))
patch_by_member = {f.get("member_name"): f for f in patch["functions"]}


def assert_super_chain(
    name,
    constants,
    *,
    min_awaits,
    make_kind,
    add_all_kind,
    for_in_kind,
    min_add_all,
    min_for_in,
    has_loop=False,
    has_catch=False,
    has_finally=False,
    has_switch=False,
):
    function = patch_by_member.get(name)
    if function is None:
        raise SystemExit(f"missing inventory entry for {name}")
    source = function.get("bytecode_source")
    source_json = json.dumps(source)
    if (
        function.get("unsupported_reasons") != []
        or not isinstance(source, dict)
        or source.get("async_future") is not True
        or source_json.count('"await"') < min_awaits
        or f'"{make_kind}"' not in source_json
        or source_json.count(f'"{add_all_kind}"') < min_add_all
        or source_json.count(f'"{for_in_kind}"') < min_for_in
        or (has_loop and '"while_loop"' not in source_json)
        or (has_catch and '"try_catch"' not in source_json)
        or (has_finally and '"try_finally"' not in source_json)
        or (has_switch and '"conditional"' not in source_json)
        or any(f'"string": "{constant}"' not in source_json for constant in constants)
    ):
        raise SystemExit(f"expected {name} async collection super source, got {function}")


assert_super_chain(
    "asyncListAwaitConditionSpreadForStaticSuperChain",
    [
        "patched-async-list-super-head",
        "patched-async-list-super-for-",
        "patched-async-list-super-static-spread",
    ],
    min_awaits=3,
    make_kind="list",
    add_all_kind="list_add_all",
    for_in_kind="list_for_in",
    min_add_all=3,
    min_for_in=1,
)
assert_super_chain(
    "asyncListLoopCollectionRecoveryCleanupSuperChain",
    [
        "patched-async-list-loop-super-head",
        "patched-async-list-loop-super-premium-",
        "patched-async-list-loop-super-cleanup-",
    ],
    min_awaits=5,
    make_kind="list",
    add_all_kind="list_add_all",
    for_in_kind="list_for_in",
    min_add_all=3,
    min_for_in=1,
    has_loop=True,
    has_catch=True,
    has_finally=True,
    has_switch=True,
)
assert_super_chain(
    "asyncMapAwaitConditionSpreadForStaticSuperChain",
    [
        "patched-async-map-super-head",
        "patched-async-map-super-for-",
        "patched-async-map-super-static-spread",
    ],
    min_awaits=3,
    make_kind="map",
    add_all_kind="map_add_all",
    for_in_kind="map_for_in",
    min_add_all=3,
    min_for_in=1,
)
assert_super_chain(
    "asyncMapLoopCollectionRecoveryCleanupSuperChain",
    [
        "patched-async-map-loop-super-head",
        "patched-async-map-loop-super-premium-",
        "patched-async-map-loop-super-cleanup-",
    ],
    min_awaits=5,
    make_kind="map",
    add_all_kind="map_add_all",
    for_in_kind="map_for_in",
    min_add_all=3,
    min_for_in=1,
    has_loop=True,
    has_catch=True,
    has_finally=True,
    has_switch=True,
)

# ---- assert_plan_async_collection_deep_spread_for_chains.py ----
import json
import sys

patch = json.load(open(sys.argv[1]))
patch_by_member = {f.get("member_name"): f for f in patch["functions"]}


def assert_deep_collection_chain(
    name,
    constants,
    *,
    min_awaits,
    make_kind,
    add_all_kind,
    for_in_kind,
    min_add_all,
    min_for_in,
    has_catch=False,
    has_finally=False,
):
    function = patch_by_member.get(name)
    if function is None:
        raise SystemExit(f"missing inventory entry for {name}")
    source = function.get("bytecode_source")
    source_json = json.dumps(source)
    if (
        function.get("unsupported_reasons") != []
        or not isinstance(source, dict)
        or source.get("async_future") is not True
        or source_json.count('"await"') < min_awaits
        or f'"{make_kind}"' not in source_json
        or source_json.count(f'"{add_all_kind}"') < min_add_all
        or source_json.count(f'"{for_in_kind}"') < min_for_in
        or (has_catch and '"try_catch"' not in source_json)
        or (has_finally and '"try_finally"' not in source_json)
        or any(f'"string": "{constant}"' not in source_json for constant in constants)
    ):
        raise SystemExit(f"expected {name} async deep collection source, got {function}")


assert_deep_collection_chain(
    "asyncListDynamicSpreadRuntimeForDeepChain",
    [
        "patched-async-list-deep-spread-head",
        "patched-async-list-deep-spread-extra-live-",
        "patched-async-list-deep-spread-tail-",
    ],
    min_awaits=3,
    make_kind="list",
    add_all_kind="list_add_all",
    for_in_kind="list_for_in",
    min_add_all=2,
    min_for_in=2,
)
assert_deep_collection_chain(
    "asyncListDeepSpreadTryCatchFinallyChain",
    [
        "patched-async-list-deep-spread-catch-head",
        "patched-async-list-deep-spread-caught-",
        "patched-async-list-deep-spread-cleanup-",
    ],
    min_awaits=5,
    make_kind="list",
    add_all_kind="list_add_all",
    for_in_kind="list_for_in",
    min_add_all=3,
    min_for_in=1,
    has_catch=True,
    has_finally=True,
)
assert_deep_collection_chain(
    "asyncMapDynamicSpreadRuntimeForDeepChain",
    [
        "patched-async-map-deep-spread-head",
        "patched-async-map-deep-spread-live-",
        "patched-async-map-deep-spread-tail-",
    ],
    min_awaits=3,
    make_kind="map",
    add_all_kind="map_add_all",
    for_in_kind="map_for_in",
    min_add_all=2,
    min_for_in=2,
)
assert_deep_collection_chain(
    "asyncMapDeepSpreadTryCatchFinallyChain",
    [
        "patched-async-map-deep-spread-catch-head",
        "patched-async-map-deep-spread-caught-",
        "patched-async-map-deep-spread-cleanup-",
    ],
    min_awaits=5,
    make_kind="map",
    add_all_kind="map_add_all",
    for_in_kind="map_for_in",
    min_add_all=3,
    min_for_in=1,
    has_catch=True,
    has_finally=True,
)

# ---- assert_plan_async_list_for_chains.py ----
import json
import sys

patch = json.load(open(sys.argv[1]))
patch_by_member = {f.get("member_name"): f for f in patch["functions"]}


def assert_async_list_for_chain(
    name,
    constants,
    *,
    min_awaits,
    min_list_for_in,
    min_list_add_all,
    min_conditionals=0,
    has_try_catch=False,
    has_try_finally=False,
):
    function = patch_by_member.get(name)
    if function is None:
        raise SystemExit(f"missing inventory entry for {name}")
    source = function.get("bytecode_source")
    source_json = json.dumps(source)
    if (
        function.get("unsupported_reasons") != []
        or not isinstance(source, dict)
        or source.get("async_future") is not True
        or source_json.count('"await"') < min_awaits
        or source_json.count('"list_for_in"') < min_list_for_in
        or source_json.count('"list_add_all"') < min_list_add_all
        or source_json.count('"conditional"') < min_conditionals
        or (has_try_catch and '"try_catch"' not in source_json)
        or (has_try_finally and '"try_finally"' not in source_json)
        or any(f'"string": "{constant}"' not in source_json for constant in constants)
    ):
        raise SystemExit(f"expected {name} async list-for chain source, got {function}")


assert_async_list_for_chain(
    "asyncListForSourceDoubleAwaitSwitchChain",
    [
        "patched-async-list-for-source-switch-head",
        "patched-async-list-for-source-switch-premium",
        "patched-async-list-for-source-switch-extra-",
    ],
    min_awaits=2,
    min_list_for_in=2,
    min_list_add_all=1,
    min_conditionals=2,
)
assert_async_list_for_chain(
    "asyncListForSourceWhileTryFinallyLoop",
    [
        "patched-async-list-for-source-while-tier-",
        "patched-async-list-for-source-while-cleanup-",
    ],
    min_awaits=3,
    min_list_for_in=1,
    min_list_add_all=2,
    min_conditionals=1,
    has_try_finally=True,
)
assert_async_list_for_chain(
    "asyncListForSourceForTryCatchFinallyRecovery",
    [
        "patched-async-list-for-source-for-premium",
        "patched-async-list-for-source-for-caught-",
        "patched-async-list-for-source-for-cleanup-",
    ],
    min_awaits=4,
    min_list_for_in=2,
    min_list_add_all=2,
    min_conditionals=2,
    has_try_catch=True,
    has_try_finally=True,
)
assert_async_list_for_chain(
    "asyncListForSourceDoWhileCatchFinallyChain",
    [
        "patched-async-list-for-source-do-tier-",
        "patched-async-list-for-source-do-caught-",
        "patched-async-list-for-source-do-cleanup-",
    ],
    min_awaits=5,
    min_list_for_in=2,
    min_list_add_all=2,
    min_conditionals=1,
    has_try_catch=True,
    has_try_finally=True,
)
assert_async_list_for_chain(
    "asyncListForSourceNestedBranchRecovery",
    [
        "patched-async-list-for-source-branch-head",
        "patched-async-list-for-source-branch-premium",
        "patched-async-list-for-source-branch-caught-",
    ],
    min_awaits=3,
    min_list_for_in=2,
    min_list_add_all=0,
    min_conditionals=2,
    has_try_catch=True,
)

# ---- assert_plan_async_map_for_chains.py ----
import json
import sys

patch = json.load(open(sys.argv[1]))
patch_by_member = {f.get("member_name"): f for f in patch["functions"]}


def assert_async_map_for_chain(
    name,
    constants,
    *,
    min_awaits,
    min_map_for_in,
    min_map_add_all,
    min_conditionals=0,
    has_try_catch=False,
    has_try_finally=False,
):
    function = patch_by_member.get(name)
    if function is None:
        raise SystemExit(f"missing inventory entry for {name}")
    source = function.get("bytecode_source")
    source_json = json.dumps(source)
    if (
        function.get("unsupported_reasons") != []
        or not isinstance(source, dict)
        or source.get("async_future") is not True
        or source_json.count('"await"') < min_awaits
        or source_json.count('"map_for_in"') < min_map_for_in
        or source_json.count('"map_add_all"') < min_map_add_all
        or source_json.count('"conditional"') < min_conditionals
        or (has_try_catch and '"try_catch"' not in source_json)
        or (has_try_finally and '"try_finally"' not in source_json)
        or any(f'"string": "{constant}"' not in source_json for constant in constants)
    ):
        raise SystemExit(f"expected {name} async map-for chain source, got {function}")


assert_async_map_for_chain(
    "asyncMapForListSourceSwitchChain",
    [
        "patched-async-map-for-list-source-switch-head",
        "patched-async-map-for-list-source-switch-premium",
        "patched-async-map-for-list-source-switch-extra-",
    ],
    min_awaits=2,
    min_map_for_in=2,
    min_map_add_all=1,
    min_conditionals=2,
)
assert_async_map_for_chain(
    "asyncMapForListSourceTryFinallyCleanup",
    [
        "patched-async-map-for-list-source-finally-head",
        "patched-async-map-for-list-source-finally-value-",
        "patched-async-map-for-list-source-finally-extra-",
        "patched-async-map-for-list-source-finally-cleanup-",
    ],
    min_awaits=3,
    min_map_for_in=2,
    min_map_add_all=2,
    has_try_finally=True,
)
assert_async_map_for_chain(
    "asyncMapForListSourceTryCatchFinallyRecovery",
    [
        "patched-async-map-for-list-source-catch-head",
        "patched-async-map-for-list-source-catch-premium",
        "patched-async-map-for-list-source-catch-extra-",
        "patched-async-map-for-list-source-catch-caught-",
        "patched-async-map-for-list-source-catch-cleanup-",
    ],
    min_awaits=4,
    min_map_for_in=2,
    min_map_add_all=2,
    min_conditionals=2,
    has_try_catch=True,
    has_try_finally=True,
)
assert_async_map_for_chain(
    "asyncMapForListSourceWhileTryFinallyLoop",
    [
        "patched-async-map-for-list-source-while-premium",
        "patched-async-map-for-list-source-while-cleanup-",
    ],
    min_awaits=3,
    min_map_for_in=1,
    min_map_add_all=2,
    min_conditionals=2,
    has_try_finally=True,
)
assert_async_map_for_chain(
    "asyncMapForListSourceForSwitchFinallyChain",
    [
        "patched-async-map-for-list-source-for-value-",
        "patched-async-map-for-list-source-for-extra-",
        "patched-async-map-for-list-source-for-cleanup-",
    ],
    min_awaits=2,
    min_map_for_in=2,
    min_map_add_all=2,
    has_try_finally=True,
)
assert_async_map_for_chain(
    "asyncMapForListSourceDoWhileCatchFinallyChain",
    [
        "patched-async-map-for-list-source-do-premium",
        "patched-async-map-for-list-source-do-caught-",
        "patched-async-map-for-list-source-do-cleanup-",
    ],
    min_awaits=5,
    min_map_for_in=2,
    min_map_add_all=1,
    min_conditionals=2,
    has_try_catch=True,
    has_try_finally=True,
)
assert_async_map_for_chain(
    "asyncMapForListSourceNestedBranchRecovery",
    [
        "patched-async-map-for-list-source-branch-head",
        "patched-async-map-for-list-source-branch-premium",
        "patched-async-map-for-list-source-branch-caught-",
    ],
    min_awaits=3,
    min_map_for_in=2,
    min_map_add_all=0,
    min_conditionals=2,
    has_try_catch=True,
)

# ---- assert_plan_async_not_await_collection_chains.py ----
import json
import sys

patch = json.load(open(sys.argv[1]))
patch_by_member = {f.get("member_name"): f for f in patch["functions"]}


def assert_not_await_collection_chain(
    name,
    constants,
    *,
    min_awaits,
    min_conditionals,
    min_list_for_in=0,
    min_list_add_all=0,
    min_map_for_in=0,
    min_map_add_all=0,
    has_try_catch=False,
    has_try_finally=False,
):
    function = patch_by_member.get(name)
    if function is None:
        raise SystemExit(f"missing inventory entry for {name}")
    source = function.get("bytecode_source")
    source_json = json.dumps(source)
    if (
        function.get("unsupported_reasons") != []
        or not isinstance(source, dict)
        or source.get("async_future") is not True
        or source_json.count('"await"') < min_awaits
        or source_json.count('"conditional"') < min_conditionals
        or source_json.count('"list_for_in"') < min_list_for_in
        or source_json.count('"list_add_all"') < min_list_add_all
        or source_json.count('"map_for_in"') < min_map_for_in
        or source_json.count('"map_add_all"') < min_map_add_all
        or (has_try_catch and '"try_catch"' not in source_json)
        or (has_try_finally and '"try_finally"' not in source_json)
        or any(f'"string": "{constant}"' not in source_json for constant in constants)
    ):
        raise SystemExit(f"expected {name} async not-await collection source, got {function}")


assert_not_await_collection_chain(
    "asyncNotAwaitCollectionIfListChain",
    [
        "patched-async-not-await-list-head",
        "patched-async-not-await-list-live-",
    ],
    min_awaits=1,
    min_conditionals=1,
    min_list_for_in=1,
    min_list_add_all=2,
)
assert_not_await_collection_chain(
    "asyncNotAwaitCollectionIfMapChain",
    [
        "patched-async-not-await-map-head",
        "patched-async-not-await-map-live-",
    ],
    min_awaits=1,
    min_conditionals=1,
    min_map_for_in=1,
    min_map_add_all=2,
)
assert_not_await_collection_chain(
    "asyncNotAwaitCollectionIfTryFinallyListCleanup",
    [
        "patched-async-not-await-list-finally-head",
        "patched-async-not-await-list-finally-fallback-",
        "patched-async-not-await-list-finally-cleanup-",
    ],
    min_awaits=2,
    min_conditionals=1,
    min_list_for_in=1,
    min_list_add_all=3,
    has_try_finally=True,
)
assert_not_await_collection_chain(
    "asyncNotAwaitCollectionIfTryCatchFinallyMapRecovery",
    [
        "patched-async-not-await-map-try-head",
        "patched-async-not-await-map-fallback-",
        "patched-async-not-await-map-caught-",
        "patched-async-not-await-map-cleanup-",
    ],
    min_awaits=4,
    min_conditionals=2,
    min_map_for_in=1,
    min_map_add_all=3,
    has_try_catch=True,
    has_try_finally=True,
)

# ---- assert_plan_async_not_await_control_chains.py ----
import json
import sys

patch = json.load(open(sys.argv[1]))
patch_by_member = {f.get("member_name"): f for f in patch["functions"]}


def assert_not_await_control_chain(
    name,
    constants,
    *,
    min_awaits,
    min_conditionals,
    has_try_catch=False,
    has_try_finally=False,
    has_while=False,
):
    function = patch_by_member.get(name)
    if function is None:
        raise SystemExit(f"missing inventory entry for {name}")
    source = function.get("bytecode_source")
    source_json = json.dumps(source)
    if (
        function.get("unsupported_reasons") != []
        or not isinstance(source, dict)
        or source.get("async_future") is not True
        or source_json.count('"await"') < min_awaits
        or source_json.count('"conditional"') < min_conditionals
        or (has_try_catch and '"try_catch"' not in source_json)
        or (has_try_finally and '"try_finally"' not in source_json)
        or (has_while and '"while_loop"' not in source_json)
        or any(f'"string": "{constant}"' not in source_json for constant in constants)
    ):
        raise SystemExit(f"expected {name} async not-await control source, got {function}")


assert_not_await_control_chain(
    "asyncNotAwaitIfTryFinallyTail",
    [
        "patched-async-not-await-if-finally",
        "-body",
        "-cleanup-",
        "-tail",
    ],
    min_awaits=2,
    min_conditionals=1,
    has_try_finally=True,
)
assert_not_await_control_chain(
    "asyncNotAwaitIfElseTryCatchFinallyTail",
    [
        "patched-async-not-await-ifelse",
        "-body-",
        "-caught-",
        "-cleanup-",
        "-ready",
        "-tail",
    ],
    min_awaits=4,
    min_conditionals=1,
    has_try_catch=True,
    has_try_finally=True,
)
assert_not_await_control_chain(
    "asyncNotAwaitWhileTryFinallyLoop",
    [
        "patched-async-not-await-while",
        "-body-",
        "-cleanup-",
    ],
    min_awaits=2,
    min_conditionals=1,
    has_try_finally=True,
    has_while=True,
)
assert_not_await_control_chain(
    "asyncNotAwaitForTryCatchLoop",
    [
        "patched-async-not-await-for",
        "-body-",
        "-caught-",
    ],
    min_awaits=3,
    min_conditionals=2,
    has_try_catch=True,
    has_while=True,
)
assert_not_await_control_chain(
    "asyncNotAwaitDoWhileFinallyCondition",
    [
        "patched-async-not-await-do",
        "-body-",
        "-cleanup-",
    ],
    min_awaits=2,
    min_conditionals=1,
    has_while=True,
)

# ---- assert_plan_async_not_await_guarded_switch_chains.py ----
import json
import sys

patch = json.load(open(sys.argv[1]))
patch_by_member = {f.get("member_name"): f for f in patch["functions"]}


def assert_not_await_guarded_switch(
    name,
    constants,
    *,
    min_awaits,
    min_conditionals,
    has_try_catch=False,
    has_try_finally=False,
):
    function = patch_by_member.get(name)
    if function is None:
        raise SystemExit(f"missing inventory entry for {name}")
    source = function.get("bytecode_source")
    source_json = json.dumps(source)
    if (
        function.get("unsupported_reasons") != []
        or not isinstance(source, dict)
        or source.get("async_future") is not True
        or source_json.count('"await"') < min_awaits
        or source_json.count('"conditional"') < min_conditionals
        or (has_try_catch and '"try_catch"' not in source_json)
        or (has_try_finally and '"try_finally"' not in source_json)
        or any(f'"string": "{constant}"' not in source_json for constant in constants)
    ):
        raise SystemExit(f"expected {name} async not-await guarded switch source, got {function}")


assert_not_await_guarded_switch(
    "asyncNotAwaitGuardedSwitchExprLabel",
    [
        "patched-not-await-guarded-switch-expr-gold",
        "patched-not-await-guarded-switch-expr-vip",
        "patched-not-await-guarded-switch-expr-other",
    ],
    min_awaits=2,
    min_conditionals=4,
)
assert_not_await_guarded_switch(
    "asyncNotAwaitGuardedSwitchExprAwaitScrutinee",
    [
        "patched-not-await-guarded-switch-await-expr-gold",
        "patched-not-await-guarded-switch-await-expr-vip",
        "patched-not-await-guarded-switch-await-expr-other",
    ],
    min_awaits=3,
    min_conditionals=4,
)
assert_not_await_guarded_switch(
    "asyncNotAwaitGuardedSwitchStatementLabel",
    [
        "patched-not-await-guarded-switch-stmt-gold",
        "patched-not-await-guarded-switch-stmt-vip",
        "patched-not-await-guarded-switch-stmt-other",
    ],
    min_awaits=2,
    min_conditionals=4,
)
assert_not_await_guarded_switch(
    "asyncNotAwaitGuardedSwitchStatementAwaitScrutinee",
    [
        "patched-not-await-guarded-switch-await-stmt-gold",
        "patched-not-await-guarded-switch-await-stmt-vip",
        "patched-not-await-guarded-switch-await-stmt-other",
    ],
    min_awaits=3,
    min_conditionals=4,
)
assert_not_await_guarded_switch(
    "asyncNotAwaitGuardedSwitchTryFinallyCleanup",
    [
        "patched-not-await-guarded-switch-finally-head",
        "patched-not-await-guarded-switch-finally-gold",
        "patched-not-await-guarded-switch-finally-vip",
        "patched-not-await-guarded-switch-finally-other",
        "-cleanup-",
    ],
    min_awaits=3,
    min_conditionals=4,
    has_try_finally=True,
)
assert_not_await_guarded_switch(
    "asyncNotAwaitGuardedSwitchTryCatchFinallyRecovery",
    [
        "patched-not-await-guarded-switch-catch-finally-head",
        "patched-not-await-guarded-switch-catch-finally-gold",
        "patched-not-await-guarded-switch-catch-finally-vip",
        "patched-not-await-guarded-switch-catch-finally-other",
        "patched-not-await-guarded-switch-caught-",
        "-cleanup-",
    ],
    min_awaits=4,
    min_conditionals=4,
    has_try_catch=True,
    has_try_finally=True,
)
