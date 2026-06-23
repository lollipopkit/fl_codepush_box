# Merged assertion group. Keep this file below the fixture size limit.


# ---- assert_generator_object_call_type_chains.py ----
import json
import sys

patch = json.load(open(sys.argv[1]))
patch_by_member = {f.get("member_name"): f for f in patch["functions"]}


def assert_generator_object_chain(
    name,
    constants,
    args,
    *,
    min_awaits,
    min_move_next,
    min_cancel,
    min_new_objects=0,
    has_catch=False,
    min_lists=0,
    min_maps=0,
    min_for_in=0,
    requires_dynamic_call=False,
    requires_static_call=False,
    requires_type_ops=False,
):
    function = patch_by_member.get(name)
    if function is None:
        raise SystemExit(f"missing inventory entry for {name}")
    source = function.get("bytecode_source")
    source_json = json.dumps(source)
    if (
        function.get("unsupported_reasons") != []
        or not isinstance(source, dict)
        or source.get("async_kind") != "async_star"
        or '"try_finally"' not in source_json
        or source_json.count('"await"') < min_awaits
        or source_json.count('"method": "moveNext"') < min_move_next
        or source_json.count('"method": "cancel"') < min_cancel
        or source_json.count('"new_object"') < min_new_objects
        or source_json.count('"list"') < min_lists
        or source_json.count('"map"') < min_maps
        or source_json.count('"list_for_in"') + source_json.count('"map_for_in"') < min_for_in
        or (has_catch and '"try_catch"' not in source_json)
        or (requires_dynamic_call and '"call_dynamic"' not in source_json)
        or (requires_static_call and '"call_static"' not in source_json)
        or (requires_type_ops and '"is_type"' not in source_json)
        or (requires_type_ops and '"as_type"' not in source_json)
        or any(f'"arg": "{arg}"' not in source_json for arg in args)
        or any(f'"string": "{constant}"' not in source_json for constant in constants)
    ):
        raise SystemExit(f"expected {name} async* object/call/type source, got {function}")


assert_generator_object_chain(
    "asyncGeneratedObjectDynamicTypeAwaitForCleanup",
    [
        "patched-stream-object-dynamic-type-user",
        "patched-stream-object-dynamic-type-body-",
        "patched-stream-object-dynamic-type-cleanup-",
    ],
    ["body", "cleanup", "ready", "candidate", "greeter", "extra"],
    min_awaits=5,
    min_move_next=2,
    min_cancel=2,
    min_new_objects=2,
    min_lists=2,
    min_for_in=1,
    requires_dynamic_call=True,
    requires_type_ops=True,
)
assert_generator_object_chain(
    "asyncGeneratedNamedObjectStaticYieldStarRecovery",
    [
        "patched-stream-named-object-static-name",
        "patched-stream-named-object-static-caught-",
    ],
    ["body", "recovery", "cleanup", "ready", "labels"],
    min_awaits=5,
    min_move_next=3,
    min_cancel=3,
    min_new_objects=2,
    min_maps=2,
    min_for_in=1,
    has_catch=True,
    requires_static_call=True,
)
assert_generator_object_chain(
    "asyncGeneratedObjectCallAwaitForYieldStarFinally",
    [
        "patched-stream-object-call-await-for-",
        "patched-stream-object-call-await-for-cleanup-",
    ],
    ["body", "tail", "cleanup", "ready", "greeter"],
    min_awaits=5,
    min_move_next=3,
    min_cancel=3,
    requires_dynamic_call=True,
)

# ---- assert_generator_object_switch_collection_chains.py ----
import json
import sys

patch = json.load(open(sys.argv[1]))
patch_by_member = {f.get("member_name"): f for f in patch["functions"]}


def assert_generator_object_switch(
    name,
    constants,
    args,
    *,
    min_awaits,
    min_move_next,
    min_cancel,
    min_new_objects=0,
    has_catch=False,
    min_lists=0,
    min_maps=0,
    min_for_in=0,
    min_conditionals=0,
    requires_dynamic_call=False,
    requires_static_call=False,
    requires_type_ops=False,
):
    function = patch_by_member.get(name)
    if function is None:
        raise SystemExit(f"missing inventory entry for {name}")
    source = function.get("bytecode_source")
    source_json = json.dumps(source)
    if (
        function.get("unsupported_reasons") != []
        or not isinstance(source, dict)
        or source.get("async_kind") != "async_star"
        or '"try_finally"' not in source_json
        or source_json.count('"await"') < min_awaits
        or source_json.count('"method": "moveNext"') < min_move_next
        or source_json.count('"method": "cancel"') < min_cancel
        or source_json.count('"new_object"') < min_new_objects
        or source_json.count('"list"') < min_lists
        or source_json.count('"map"') < min_maps
        or source_json.count('"list_for_in"') + source_json.count('"map_for_in"') < min_for_in
        or source_json.count('"conditional"') < min_conditionals
        or (has_catch and '"try_catch"' not in source_json)
        or (requires_dynamic_call and '"call_dynamic"' not in source_json)
        or (requires_static_call and '"call_static"' not in source_json)
        or (requires_type_ops and '"is_type"' not in source_json)
        or (requires_type_ops and '"as_type"' not in source_json)
        or any(f'"arg": "{arg}"' not in source_json for arg in args)
        or any(f'"string": "{constant}"' not in source_json for constant in constants)
    ):
        raise SystemExit(f"expected {name} async* object switch source, got {function}")


assert_generator_object_switch(
    "asyncGeneratedObjectSwitchListRecoveryCleanup",
    [
        "patched-stream-object-switch-list-user",
        "patched-stream-object-switch-list-gold-",
        "patched-stream-object-switch-list-blocked",
        "patched-stream-object-switch-list-caught-",
        "patched-stream-object-switch-list-cleanup-",
    ],
    ["body", "cleanupStream", "tierReady", "enabled", "ready", "recovery", "cleanup", "candidate", "greeter", "extra"],
    min_awaits=7,
    min_move_next=2,
    min_cancel=2,
    min_new_objects=2,
    has_catch=True,
    min_lists=4,
    min_for_in=1,
    min_conditionals=4,
    requires_dynamic_call=True,
    requires_type_ops=True,
)
assert_generator_object_switch(
    "asyncGeneratedNamedObjectSwitchMapYieldStarCleanup",
    [
        "patched-stream-object-switch-map-name",
        "patched-stream-object-switch-map-blocked",
        "patched-stream-object-switch-map-caught-",
        "patched-stream-object-switch-map-cleanup-",
    ],
    ["body", "recoveryStream", "cleanupStream", "tierReady", "enabled", "ready", "recovery", "cleanup", "labels"],
    min_awaits=7,
    min_move_next=3,
    min_cancel=3,
    min_new_objects=4,
    has_catch=True,
    min_maps=4,
    min_for_in=1,
    min_conditionals=3,
    requires_static_call=True,
)
assert_generator_object_switch(
    "asyncGeneratedObjectSwitchAwaitForYieldStarFinally",
    [
        "patched-stream-object-switch-await-for-gold-",
        "patched-stream-object-switch-await-for-other-",
        "patched-stream-object-switch-await-for-cleanup-",
    ],
    ["body", "tail", "cleanupStream", "tierReady", "enabled", "ready", "cleanup", "greeter"],
    min_awaits=6,
    min_move_next=3,
    min_cancel=3,
    min_conditionals=3,
    requires_dynamic_call=True,
)

# ---- assert_generator_sync_nested_loop_switch_collection_chains.py ----
import json
import sys

patch = json.load(open(sys.argv[1]))
patch_by_member = {f.get("member_name"): f for f in patch["functions"]}


def assert_sync_nested_loop_switch(
    name,
    constants,
    args,
    *,
    min_yields,
    min_yield_for_in,
    min_new_objects=0,
    min_lists=0,
    min_maps=0,
    min_for_in=0,
    requires_dynamic_call=False,
    requires_static_call=False,
    requires_type_ops=False,
):
    function = patch_by_member.get(name)
    if function is None:
        raise SystemExit(f"missing inventory entry for {name}")
    source = function.get("bytecode_source")
    source_json = json.dumps(source)
    if (
        function.get("unsupported_reasons") != []
        or not isinstance(source, dict)
        or source.get("async_kind") != "sync_star"
        or '"while_loop"' not in source_json
        or '"try_catch"' not in source_json
        or '"try_finally"' not in source_json
        or source_json.count('"yield"') < min_yields
        or source_json.count('"yield_for_in"') < min_yield_for_in
        or source_json.count('"new_object"') < min_new_objects
        or source_json.count('"list"') < min_lists
        or source_json.count('"map"') < min_maps
        or source_json.count('"list_for_in"') + source_json.count('"map_for_in"') < min_for_in
        or (requires_dynamic_call and '"call_dynamic"' not in source_json)
        or (requires_static_call and '"call_static"' not in source_json)
        or (requires_type_ops and '"is_type"' not in source_json)
        or (requires_type_ops and '"as_type"' not in source_json)
        or any(f'"arg": "{arg}"' not in source_json for arg in args)
        or any(f'"string": "{constant}"' not in source_json for constant in constants)
    ):
        raise SystemExit(f"expected {name} sync* nested loop switch source, got {function}")


assert_sync_nested_loop_switch(
    "syncGeneratedWhileForInObjectSwitchCollectionCleanup",
    [
        "patched-iterable-nested-loop-switch-list-user",
        "patched-iterable-nested-loop-switch-list-blocked",
        "patched-iterable-nested-loop-switch-list-caught-",
        "patched-iterable-nested-loop-switch-list-cleanup-",
    ],
    ["limit", "body", "recoveryItems", "cleanupItems", "tier", "enabled", "candidate", "greeter", "extra"],
    min_yields=5,
    min_yield_for_in=3,
    min_new_objects=2,
    min_lists=4,
    min_for_in=1,
    requires_dynamic_call=True,
    requires_type_ops=True,
)
assert_sync_nested_loop_switch(
    "syncGeneratedForForInNamedMapYieldStarCleanup",
    [
        "patched-iterable-nested-loop-switch-map-name",
        "patched-iterable-nested-loop-switch-map-blocked",
        "patched-iterable-nested-loop-switch-map-caught-",
        "patched-iterable-nested-loop-switch-map-cleanup-head",
    ],
    ["limit", "body", "recoveryItems", "cleanupItems", "tier", "enabled", "labels"],
    min_yields=4,
    min_yield_for_in=3,
    min_new_objects=3,
    min_maps=4,
    min_for_in=1,
    requires_static_call=True,
)

# ---- assert_generator_sync_object_loop_finalizer_chains.py ----
import json
import sys

patch = json.load(open(sys.argv[1]))
patch_by_member = {f.get("member_name"): f for f in patch["functions"]}


def assert_sync_generator_object_loop(
    name,
    constants,
    args,
    *,
    min_yields,
    min_yield_for_in,
    min_new_objects=0,
    has_catch=False,
    requires_dynamic_call=False,
    requires_static_call=False,
    requires_type_ops=False,
):
    function = patch_by_member.get(name)
    if function is None:
        raise SystemExit(f"missing inventory entry for {name}")
    source = function.get("bytecode_source")
    source_json = json.dumps(source)
    if (
        function.get("unsupported_reasons") != []
        or not isinstance(source, dict)
        or source.get("async_kind") != "sync_star"
        or '"while_loop"' not in source_json
        or '"try_finally"' not in source_json
        or source_json.count('"yield"') < min_yields
        or source_json.count('"yield_for_in"') < min_yield_for_in
        or source_json.count('"new_object"') < min_new_objects
        or (has_catch and '"try_catch"' not in source_json)
        or (requires_dynamic_call and '"call_dynamic"' not in source_json)
        or (requires_static_call and '"call_static"' not in source_json)
        or (requires_type_ops and '"is_type"' not in source_json)
        or (requires_type_ops and '"as_type"' not in source_json)
        or any(f'"arg": "{arg}"' not in source_json for arg in args)
        or any(f'"string": "{constant}"' not in source_json for constant in constants)
    ):
        raise SystemExit(f"expected {name} sync* object loop source, got {function}")


assert_sync_generator_object_loop(
    "syncGeneratedWhileObjectDynamicTypeFinalizerChain",
    [
        "patched-iterable-object-loop-while-user",
        "patched-iterable-object-loop-while-premium-",
        "patched-iterable-object-loop-while-cleanup-head-",
    ],
    ["limit", "cleanupItems", "tier", "candidate", "greeter", "extra"],
    min_yields=5,
    min_yield_for_in=2,
    min_new_objects=2,
    requires_dynamic_call=True,
    requires_type_ops=True,
)
assert_sync_generator_object_loop(
    "syncGeneratedForNamedObjectStaticMapCatchFinallyChain",
    [
        "patched-iterable-object-loop-for-name",
        "patched-iterable-object-loop-for-blocked",
        "patched-iterable-object-loop-for-caught-",
        "patched-iterable-object-loop-for-cleanup-head-",
    ],
    ["limit", "recoveryItems", "cleanupItems", "tier", "enabled", "fail", "labels"],
    min_yields=3,
    min_yield_for_in=2,
    min_new_objects=3,
    has_catch=True,
    requires_static_call=True,
)
assert_sync_generator_object_loop(
    "syncGeneratedDoWhileObjectCallCollectionRecoveryCleanupChain",
    [
        "patched-iterable-object-loop-do-error",
        "patched-iterable-object-loop-do-is-",
        "patched-iterable-object-loop-do-caught-",
        "patched-iterable-object-loop-do-cleanup-head-",
    ],
    ["limit", "recoveryItems", "cleanupItems", "fail", "candidate", "greeter", "extra"],
    min_yields=4,
    min_yield_for_in=3,
    has_catch=True,
    requires_dynamic_call=True,
    requires_type_ops=True,
)

# ---- assert_generator_sync_object_switch_collection_chains.py ----
import json
import sys

patch = json.load(open(sys.argv[1]))
patch_by_member = {f.get("member_name"): f for f in patch["functions"]}


def assert_sync_generator_object_switch(
    name,
    constants,
    args,
    *,
    min_yield_for_in,
    min_new_objects=0,
    has_catch=False,
    min_lists=0,
    min_maps=0,
    min_for_in=0,
    min_conditionals=0,
    requires_throw=True,
    requires_dynamic_call=False,
    requires_static_call=False,
    requires_type_ops=False,
):
    function = patch_by_member.get(name)
    if function is None:
        raise SystemExit(f"missing inventory entry for {name}")
    source = function.get("bytecode_source")
    source_json = json.dumps(source)
    if (
        function.get("unsupported_reasons") != []
        or not isinstance(source, dict)
        or source.get("async_kind") != "sync_star"
        or '"try_finally"' not in source_json
        or (requires_throw and '"throw"' not in source_json)
        or source_json.count('"yield_for_in"') < min_yield_for_in
        or source_json.count('"new_object"') < min_new_objects
        or source_json.count('"list"') < min_lists
        or source_json.count('"map"') < min_maps
        or source_json.count('"list_for_in"') + source_json.count('"map_for_in"') < min_for_in
        or source_json.count('"conditional"') < min_conditionals
        or (has_catch and '"try_catch"' not in source_json)
        or (requires_dynamic_call and '"call_dynamic"' not in source_json)
        or (requires_static_call and '"call_static"' not in source_json)
        or (requires_type_ops and '"is_type"' not in source_json)
        or (requires_type_ops and '"as_type"' not in source_json)
        or any(f'"arg": "{arg}"' not in source_json for arg in args)
        or any(f'"string": "{constant}"' not in source_json for constant in constants)
    ):
        raise SystemExit(f"expected {name} sync* object switch source, got {function}")


assert_sync_generator_object_switch(
    "syncGeneratedObjectSwitchListRecoveryCleanup",
    [
        "patched-iterable-object-switch-list-user",
        "patched-iterable-object-switch-list-gold-",
        "patched-iterable-object-switch-list-blocked",
        "patched-iterable-object-switch-list-caught-",
        "patched-iterable-object-switch-list-cleanup-head",
    ],
    ["body", "cleanupItems", "tier", "enabled", "candidate", "greeter", "extra"],
    min_yield_for_in=2,
    min_new_objects=2,
    has_catch=True,
    min_lists=4,
    min_for_in=1,
    min_conditionals=3,
    requires_dynamic_call=True,
    requires_type_ops=True,
)
assert_sync_generator_object_switch(
    "syncGeneratedNamedObjectSwitchMapYieldStarCleanup",
    [
        "patched-iterable-object-switch-map-name",
        "patched-iterable-object-switch-map-blocked",
        "patched-iterable-object-switch-map-caught-",
        "patched-iterable-object-switch-map-cleanup-head",
    ],
    ["body", "recoveryItems", "cleanupItems", "tier", "enabled", "labels"],
    min_yield_for_in=2,
    min_new_objects=3,
    has_catch=True,
    min_maps=4,
    min_for_in=1,
    min_conditionals=3,
    requires_static_call=True,
)
assert_sync_generator_object_switch(
    "syncGeneratedObjectSwitchForInYieldStarFinally",
    [
        "patched-iterable-object-switch-for-in-gold-",
        "patched-iterable-object-switch-for-in-other-",
        "patched-iterable-object-switch-for-in-cleanup-head",
    ],
    ["body", "tail", "cleanupItems", "tier", "enabled", "greeter"],
    min_yield_for_in=3,
    min_conditionals=2,
    requires_throw=False,
    requires_dynamic_call=True,
)
