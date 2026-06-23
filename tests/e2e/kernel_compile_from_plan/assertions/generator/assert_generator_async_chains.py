# Merged assertion group. Keep this file below the fixture size limit.


# ---- assert_generator_async_await_for_await_stream_chains.py ----
import json
import sys

patch = json.load(open(sys.argv[1]))
patch_by_member = {f.get("member_name"): f for f in patch["functions"]}


def assert_await_for_await_stream_chain(
    name,
    constants,
    args,
    *,
    min_awaits,
    min_move_next,
    min_cancel,
    min_yields,
    min_conditionals=0,
    requires_catch=False,
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
        or (requires_catch and '"try_catch"' not in source_json)
        or source_json.count('"await"') < min_awaits
        or source_json.count('"method": "moveNext"') < min_move_next
        or source_json.count('"method": "cancel"') < min_cancel
        or source_json.count('"yield"') < min_yields
        or source_json.count('"conditional"') < min_conditionals
        or any(f'"arg": "{arg}"' not in source_json for arg in args)
        or any(f'"string": "{constant}"' not in source_json for constant in constants)
    ):
        raise SystemExit(f"expected {name} async* await-for await stream source, got {function}")


assert_await_for_await_stream_chain(
    "asyncGeneratedAwaitForAwaitStreamFutureSuperChain",
    [
        "patched-stream-await-for-await-stream-first-",
        "patched-stream-await-for-await-stream-second-",
        "patched-stream-await-for-await-stream-cleanup-",
    ],
    ["first", "second", "cleanup", "skip", "stop"],
    min_awaits=8,
    min_move_next=3,
    min_cancel=3,
    min_yields=3,
    min_conditionals=1,
)
assert_await_for_await_stream_chain(
    "asyncGeneratedAwaitForAwaitStreamFutureCatchFinallySuperChain",
    [
        "patched-stream-await-for-await-stream-catch-body-",
        "patched-stream-await-for-await-stream-catch-recovery-",
        "patched-stream-await-for-await-stream-catch-cleanup-",
    ],
    ["body", "recovery", "cleanup"],
    min_awaits=9,
    min_move_next=3,
    min_cancel=3,
    min_yields=3,
    requires_catch=True,
)

# ---- assert_generator_async_awaited_runtime_collection_sources.py ----
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
    min_move_next,
    min_cancel,
    min_yields,
    min_lists=0,
    min_maps=0,
    min_for_in=0,
    min_conditionals=0,
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
        or source_json.count('"yield"') < min_yields
        or source_json.count('"list"') < min_lists
        or source_json.count('"map"') < min_maps
        or (
            source_json.count('"list_for_in"') +
            source_json.count('"map_for_in"')
        ) < min_for_in
        or source_json.count('"conditional"') < min_conditionals
        or any(f'"arg": "{arg}"' not in source_json for arg in args)
        or any(f'"string": "{constant}"' not in source_json for constant in constants)
    ):
        raise SystemExit(
            f"expected {name} async* awaited runtime collection source, got {function}"
        )


assert_awaited_runtime_collection_source(
    "asyncGeneratedListRuntimeForAwaitSourceCleanupSuperChain",
    [
        "patched-stream-awaited-list-source-head-",
        "patched-stream-awaited-list-source-cleanup-",
    ],
    ["items", "extras", "tail", "label", "cleanup"],
    min_awaits=7,
    min_move_next=2,
    min_cancel=2,
    min_yields=2,
    min_lists=2,
    min_for_in=2,
)
assert_awaited_runtime_collection_source(
    "asyncGeneratedMapEntriesAwaitSourceCleanupSuperChain",
    [
        "patched-stream-awaited-map-source-item",
        "patched-stream-awaited-map-source-label",
        "patched-stream-awaited-map-source-cleanup",
    ],
    ["items", "extras", "tail", "label", "enabled"],
    min_awaits=7,
    min_move_next=1,
    min_cancel=1,
    min_yields=2,
    min_maps=2,
    min_for_in=2,
    min_conditionals=1,
)

# ---- assert_generator_async_collection_stream_finalizer_chains.py ----
import json
import sys

patch = json.load(open(sys.argv[1]))
patch_by_member = {f.get("member_name"): f for f in patch["functions"]}


def assert_collection_stream_finalizer_chain(
    name,
    constants,
    args,
    *,
    min_awaits,
    min_move_next,
    min_cancel,
    min_yields,
    min_lists=0,
    min_maps=0,
    min_conditionals=0,
    needs_try_catch=False,
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
        or (needs_try_catch and '"try_catch"' not in source_json)
        or source_json.count('"await"') < min_awaits
        or source_json.count('"method": "moveNext"') < min_move_next
        or source_json.count('"method": "cancel"') < min_cancel
        or source_json.count('"yield"') < min_yields
        or source_json.count('"list"') < min_lists
        or source_json.count('"map"') < min_maps
        or source_json.count('"conditional"') < min_conditionals
        or any(f'"arg": "{arg}"' not in source_json for arg in args)
        or any(f'"string": "{constant}"' not in source_json for constant in constants)
    ):
        raise SystemExit(
            f"expected {name} async* collection stream source, got {function}"
        )


assert_collection_stream_finalizer_chain(
    "asyncGeneratedListCollectionAwaitForFinalizerSuperChain",
    [
        "patched-stream-collection-finalizer-head",
        "patched-stream-collection-finalizer-cleanup",
    ],
    ["items", "enabled", "label", "extras", "cleanup"],
    min_awaits=6,
    min_move_next=2,
    min_cancel=2,
    min_yields=2,
    min_lists=2,
    min_conditionals=1,
)
assert_collection_stream_finalizer_chain(
    "asyncGeneratedMapCollectionCatchFinallySuperChain",
    [
        "patched-stream-map-finalizer-item",
        "patched-stream-map-finalizer-label",
        "patched-stream-map-finalizer-caught",
        "patched-stream-map-finalizer-cleanup",
    ],
    ["items", "enabled", "label", "keys", "cleanup"],
    min_awaits=6,
    min_move_next=1,
    min_cancel=1,
    min_yields=3,
    min_maps=3,
    min_conditionals=1,
    needs_try_catch=True,
)

# ---- assert_generator_async_nested_loop_switch_collection_chains.py ----
import json
import sys

patch = json.load(open(sys.argv[1]))
patch_by_member = {f.get("member_name"): f for f in patch["functions"]}


def assert_async_nested_loop_switch(
    name,
    constants,
    args,
    *,
    min_awaits,
    min_move_next,
    min_cancel,
    min_yields,
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
        or source.get("async_kind") != "async_star"
        or '"while_loop"' not in source_json
        or '"try_catch"' not in source_json
        or '"try_finally"' not in source_json
        or source_json.count('"await"') < min_awaits
        or source_json.count('"method": "moveNext"') < min_move_next
        or source_json.count('"method": "cancel"') < min_cancel
        or source_json.count('"yield"') < min_yields
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
        raise SystemExit(f"expected {name} async* nested loop switch source, got {function}")


assert_async_nested_loop_switch(
    "asyncGeneratedWhileAwaitForObjectSwitchCollectionCleanup",
    [
        "patched-stream-nested-loop-switch-list-user",
        "patched-stream-nested-loop-switch-list-blocked",
        "patched-stream-nested-loop-switch-list-caught-",
        "patched-stream-nested-loop-switch-list-cleanup-",
    ],
    ["limit", "body", "recovery", "cleanup", "ready", "tier", "enabled", "candidate", "greeter", "extra"],
    min_awaits=8,
    min_move_next=3,
    min_cancel=3,
    min_yields=5,
    min_new_objects=4,
    min_lists=4,
    min_for_in=1,
    requires_dynamic_call=True,
    requires_type_ops=True,
)
assert_async_nested_loop_switch(
    "asyncGeneratedForAwaitForNamedMapYieldStarCleanup",
    [
        "patched-stream-nested-loop-switch-map-name",
        "patched-stream-nested-loop-switch-map-blocked",
        "patched-stream-nested-loop-switch-map-caught-",
        "patched-stream-nested-loop-switch-map-cleanup-head",
    ],
    ["limit", "body", "recovery", "cleanup", "ready", "tier", "enabled", "labels"],
    min_awaits=8,
    min_move_next=3,
    min_cancel=3,
    min_yields=4,
    min_new_objects=5,
    min_maps=4,
    min_for_in=1,
    requires_static_call=True,
)

# ---- assert_generator_async_object_loop_finalizer_chains.py ----
import json
import sys

patch = json.load(open(sys.argv[1]))
patch_by_member = {f.get("member_name"): f for f in patch["functions"]}


def assert_async_generator_object_loop(
    name,
    constants,
    args,
    *,
    min_awaits,
    min_move_next,
    min_cancel,
    min_yields,
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
        or source.get("async_kind") != "async_star"
        or '"while_loop"' not in source_json
        or '"try_finally"' not in source_json
        or source_json.count('"await"') < min_awaits
        or source_json.count('"method": "moveNext"') < min_move_next
        or source_json.count('"method": "cancel"') < min_cancel
        or source_json.count('"yield"') < min_yields
        or source_json.count('"new_object"') < min_new_objects
        or (has_catch and '"try_catch"' not in source_json)
        or (requires_dynamic_call and '"call_dynamic"' not in source_json)
        or (requires_static_call and '"call_static"' not in source_json)
        or (requires_type_ops and '"is_type"' not in source_json)
        or (requires_type_ops and '"as_type"' not in source_json)
        or any(f'"arg": "{arg}"' not in source_json for arg in args)
        or any(f'"string": "{constant}"' not in source_json for constant in constants)
    ):
        raise SystemExit(f"expected {name} async* object loop source, got {function}")


assert_async_generator_object_loop(
    "asyncGeneratedWhileObjectDynamicTypeFinalizerChain",
    [
        "patched-stream-object-loop-while-user",
        "patched-stream-object-loop-while-premium-",
        "patched-stream-object-loop-while-cleanup-",
    ],
    ["limit", "cleanup", "ready", "tier", "candidate", "greeter", "extra"],
    min_awaits=3,
    min_move_next=1,
    min_cancel=1,
    min_yields=5,
    min_new_objects=2,
    requires_dynamic_call=True,
    requires_type_ops=True,
)
assert_async_generator_object_loop(
    "asyncGeneratedForNamedObjectStaticMapCatchFinallyChain",
    [
        "patched-stream-object-loop-for-name",
        "patched-stream-object-loop-for-blocked",
        "patched-stream-object-loop-for-caught-",
        "patched-stream-object-loop-for-cleanup-head-",
    ],
    ["limit", "recovery", "cleanup", "ready", "tier", "enabled", "fail", "labels"],
    min_awaits=5,
    min_move_next=2,
    min_cancel=2,
    min_yields=3,
    min_new_objects=3,
    has_catch=True,
    requires_static_call=True,
)
assert_async_generator_object_loop(
    "asyncGeneratedDoWhileObjectCallCollectionRecoveryCleanupChain",
    [
        "patched-stream-object-loop-do-error",
        "patched-stream-object-loop-do-is-",
        "patched-stream-object-loop-do-caught-",
        "patched-stream-object-loop-do-cleanup-",
    ],
    ["limit", "recovery", "cleanup", "fail", "ready", "candidate", "greeter", "extra"],
    min_awaits=6,
    min_move_next=2,
    min_cancel=2,
    min_yields=4,
    has_catch=True,
    requires_dynamic_call=True,
    requires_type_ops=True,
)

# ---- assert_generator_async_pending_guard_super_chains.py ----
import json
import sys

patch = json.load(open(sys.argv[1]))
patch_by_member = {f.get("member_name"): f for f in patch["functions"]}


def assert_pending_guard_super_chain(
    name,
    constants,
    args,
    *,
    min_awaits,
    min_move_next,
    min_cancel,
    min_yields,
    min_lists=0,
    min_maps=0,
    min_for_in=0,
    min_conditionals=0,
    requires_break=False,
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
        or '"try_catch"' not in source_json
        or '"try_finally"' not in source_json
        or '"await"' not in source_json
        or (requires_break and '"break_condition"' not in source_json)
        or source_json.count('"await"') < min_awaits
        or source_json.count('"method": "moveNext"') < min_move_next
        or source_json.count('"method": "cancel"') < min_cancel
        or source_json.count('"yield"') < min_yields
        or source_json.count('"list"') < min_lists
        or source_json.count('"map"') < min_maps
        or source_json.count('"list_for_in"') + source_json.count('"map_for_in"') < min_for_in
        or source_json.count('"conditional"') < min_conditionals
        or any(f'"arg": "{arg}"' not in source_json for arg in args)
        or any(f'"string": "{constant}"' not in source_json for constant in constants)
    ):
        raise SystemExit(f"expected {name} async* pending guard source, got {function}")


assert_pending_guard_super_chain(
    "asyncGeneratedStreamPendingContinueRecoveryCleanupSuperChain",
    [
        "patched-stream-pending-continue-premium-",
        "patched-stream-pending-continue-caught-",
        "patched-stream-pending-continue-cleanup-",
    ],
    ["body", "recovery", "cleanup", "skip", "tier", "extra"],
    min_awaits=6,
    min_move_next=3,
    min_cancel=3,
    min_yields=3,
    min_lists=3,
    min_for_in=1,
    min_conditionals=3,
)
assert_pending_guard_super_chain(
    "asyncGeneratedStreamPendingBreakRecoveryCleanupSuperChain",
    [
        "patched-stream-pending-break-premium-",
        "patched-stream-pending-break-caught-",
    ],
    ["body", "recovery", "cleanup", "stop", "tier", "labels"],
    min_awaits=7,
    min_move_next=3,
    min_cancel=3,
    min_yields=4,
    min_maps=2,
    min_for_in=1,
    min_conditionals=2,
    requires_break=True,
)
assert_pending_guard_super_chain(
    "asyncGeneratedNestedStreamPendingGuardSuperChain",
    [
        "patched-stream-pending-nested-premium-",
        "patched-stream-pending-nested-tail-",
        "patched-stream-pending-nested-cleanup-",
    ],
    ["outer", "inner", "recovery", "cleanup", "skip", "stop", "tier", "extra"],
    min_awaits=10,
    min_move_next=5,
    min_cancel=5,
    min_yields=4,
    min_lists=4,
    min_for_in=1,
    min_conditionals=3,
    requires_break=True,
)

# ---- assert_generator_async_stream_guarded_super_chains.py ----
import json
import sys

patch = json.load(open(sys.argv[1]))
patch_by_member = {f.get("member_name"): f for f in patch["functions"]}


def assert_async_stream_guarded_super_chain(
    name,
    constants,
    args,
    *,
    min_awaits,
    min_move_next,
    min_cancel,
    min_yields,
    min_lists=0,
    min_maps=0,
    min_for_in=0,
    min_conditionals=0,
    has_loop=False,
    requires_break_condition=True,
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
        or '"try_catch"' not in source_json
        or '"try_finally"' not in source_json
        or (requires_break_condition and '"break_condition"' not in source_json)
        or (has_loop and '"while_loop"' not in source_json)
        or source_json.count('"await"') < min_awaits
        or source_json.count('"method": "moveNext"') < min_move_next
        or source_json.count('"method": "cancel"') < min_cancel
        or source_json.count('"yield"') < min_yields
        or source_json.count('"list"') < min_lists
        or source_json.count('"map"') < min_maps
        or source_json.count('"list_for_in"') + source_json.count('"map_for_in"') < min_for_in
        or source_json.count('"conditional"') < min_conditionals
        or any(f'"arg": "{arg}"' not in source_json for arg in args)
        or any(f'"string": "{constant}"' not in source_json for constant in constants)
    ):
        raise SystemExit(f"expected {name} async* guarded stream super source, got {function}")


assert_async_stream_guarded_super_chain(
    "asyncGeneratedStreamGuardedContinueBreakRecoveryCleanupSuperChain",
    [
        "patched-stream-guarded-super-premium-",
        "patched-stream-guarded-super-caught-",
        "patched-stream-guarded-super-cleanup-",
    ],
    ["body", "recovery", "cleanup", "tier", "extra"],
    min_awaits=6,
    min_move_next=3,
    min_cancel=3,
    min_yields=3,
    min_lists=3,
    min_for_in=1,
    min_conditionals=3,
)
assert_async_stream_guarded_super_chain(
    "asyncGeneratedNestedStreamGuardedRecoveryCleanupSuperChain",
    [
        "patched-stream-nested-guarded-super-premium-",
        "patched-stream-nested-guarded-super-caught-",
    ],
    ["outer", "inner", "recovery", "cleanup", "tier", "labels"],
    min_awaits=8,
    min_move_next=4,
    min_cancel=4,
    min_yields=4,
    min_maps=2,
    min_for_in=1,
    min_conditionals=3,
)
assert_async_stream_guarded_super_chain(
    "asyncGeneratedWhileStreamGuardedDoubleCleanupSuperChain",
    [
        "patched-stream-while-guarded-super-first-",
        "patched-stream-while-guarded-super-premium-",
        "patched-stream-while-guarded-super-cleanup-",
    ],
    ["limit", "first", "second", "recovery", "cleanup", "tier", "extra"],
    min_awaits=7,
    min_move_next=4,
    min_cancel=4,
    min_yields=4,
    min_lists=4,
    min_for_in=1,
    min_conditionals=3,
    has_loop=True,
    requires_break_condition=False,
)

# ---- assert_generator_async_stream_super_chains.py ----
import json
import sys

patch = json.load(open(sys.argv[1]))
patch_by_member = {f.get("member_name"): f for f in patch["functions"]}


def assert_async_stream_super_chain(
    name,
    constants,
    args,
    *,
    min_awaits,
    min_move_next,
    min_cancel,
    min_yields,
    min_lists=0,
    min_maps=0,
    min_for_in=0,
    min_conditionals=0,
    has_loop=False,
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
        or '"try_catch"' not in source_json
        or '"try_finally"' not in source_json
        or (has_loop and '"while_loop"' not in source_json)
        or source_json.count('"await"') < min_awaits
        or source_json.count('"method": "moveNext"') < min_move_next
        or source_json.count('"method": "cancel"') < min_cancel
        or source_json.count('"yield"') < min_yields
        or source_json.count('"list"') < min_lists
        or source_json.count('"map"') < min_maps
        or source_json.count('"list_for_in"') + source_json.count('"map_for_in"') < min_for_in
        or source_json.count('"conditional"') < min_conditionals
        or any(f'"arg": "{arg}"' not in source_json for arg in args)
        or any(f'"string": "{constant}"' not in source_json for constant in constants)
    ):
        raise SystemExit(f"expected {name} async* stream super source, got {function}")


assert_async_stream_super_chain(
    "asyncGeneratedNestedAwaitForRecoveryDoubleCleanupSuperChain",
    [
        "patched-stream-super-nested-premium-",
        "patched-stream-super-nested-caught-",
        "patched-stream-super-nested-cleanup-",
    ],
    ["outer", "inner", "recovery", "cleanup", "tail", "tier", "extra"],
    min_awaits=7,
    min_move_next=5,
    min_cancel=5,
    min_yields=4,
    min_lists=3,
    min_for_in=1,
    min_conditionals=2,
)
assert_async_stream_super_chain(
    "asyncGeneratedYieldStarAwaitForMapRecoveryCleanupTailSuperChain",
    [
        "patched-stream-super-map-body-",
        "patched-stream-super-map-caught-",
        "patched-stream-super-map-cleanup-",
    ],
    ["first", "body", "recovery", "cleanup", "tail", "labels"],
    min_awaits=8,
    min_move_next=5,
    min_cancel=5,
    min_yields=5,
    min_maps=3,
    min_for_in=1,
)
assert_async_stream_super_chain(
    "asyncGeneratedWhileYieldStarAwaitForSwitchCleanupSuperChain",
    [
        "patched-stream-super-while-premium-",
        "patched-stream-super-while-caught-",
        "patched-stream-super-while-cleanup-",
    ],
    ["limit", "first", "second", "recovery", "cleanup", "tier", "extra"],
    min_awaits=8,
    min_move_next=4,
    min_cancel=4,
    min_yields=4,
    min_lists=3,
    min_for_in=1,
    min_conditionals=2,
    has_loop=True,
)

# ---- assert_generator_async_switch_selected_stream_chains.py ----
import json
import sys

patch = json.load(open(sys.argv[1]))
patch_by_member = {f.get("member_name"): f for f in patch["functions"]}


def assert_switch_selected_stream_chain(
    name,
    constants,
    args,
    *,
    min_awaits,
    min_move_next,
    min_cancel,
    min_yields,
    min_conditionals,
    min_yield_star_iterators=0,
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
        or source_json.count('"yield"') < min_yields
        or source_json.count('"conditional"') < min_conditionals
        or source_json.count('":yield-star-iterator"') < min_yield_star_iterators
        or any(f'"arg": "{arg}"' not in source_json for arg in args)
        or any(f'"string": "{constant}"' not in source_json for constant in constants)
    ):
        raise SystemExit(f"expected {name} async* switch-selected stream source, got {function}")


assert_switch_selected_stream_chain(
    "asyncGeneratedYieldStarSwitchSelectedAwaitStreamSuperChain",
    ["patched-stream-switch-selected-yield-star-cleanup-"],
    ["tier", "premium", "standard", "cleanup"],
    min_awaits=6,
    min_move_next=2,
    min_cancel=2,
    min_yields=2,
    min_conditionals=2,
    min_yield_star_iterators=1,
)
assert_switch_selected_stream_chain(
    "asyncGeneratedAwaitForSwitchSelectedAwaitStreamSuperChain",
    [
        "patched-stream-switch-selected-await-for-body-",
        "patched-stream-switch-selected-await-for-cleanup-",
    ],
    ["tier", "premium", "standard", "cleanup", "skip"],
    min_awaits=7,
    min_move_next=2,
    min_cancel=2,
    min_yields=2,
    min_conditionals=3,
)

# ---- assert_generator_async_switch_selected_stream_finalizer_chains.py ----
import json
import sys

patch = json.load(open(sys.argv[1]))
patch_by_member = {f.get("member_name"): f for f in patch["functions"]}


def assert_switch_selected_finalizer_chain(
    name,
    constants,
    args,
    *,
    min_awaits,
    min_move_next,
    min_cancel,
    min_yields,
    min_conditionals,
    min_yield_star_iterators=0,
    needs_try_catch=False,
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
        or (needs_try_catch and '"try_catch"' not in source_json)
        or source_json.count('"await"') < min_awaits
        or source_json.count('"method": "moveNext"') < min_move_next
        or source_json.count('"method": "cancel"') < min_cancel
        or source_json.count('"yield"') < min_yields
        or source_json.count('"conditional"') < min_conditionals
        or source_json.count('":yield-star-iterator"') < min_yield_star_iterators
        or any(f'"arg": "{arg}"' not in source_json for arg in args)
        or any(f'"string": "{constant}"' not in source_json for constant in constants)
    ):
        raise SystemExit(
            f"expected {name} async* switch-selected finalizer source, got {function}"
        )


assert_switch_selected_finalizer_chain(
    "asyncGeneratedSwitchSelectedYieldStarThenAwaitForFinallySuperChain",
    ["patched-stream-switch-selected-finalizer-body-"],
    ["tier", "primary", "fallback", "tail", "cleanup", "stop"],
    min_awaits=8,
    min_move_next=2,
    min_cancel=3,
    min_yields=3,
    min_conditionals=2,
    min_yield_star_iterators=2,
)
assert_switch_selected_finalizer_chain(
    "asyncGeneratedNestedSwitchSelectedAwaitForFinallySuperChain",
    [
        "patched-stream-switch-selected-finalizer-nested-",
        "patched-stream-switch-selected-finalizer-caught-",
        "patched-stream-switch-selected-finalizer-cleanup-",
    ],
    [
        "outerTier",
        "innerTier",
        "outerPrimary",
        "outerFallback",
        "innerPrimary",
        "innerFallback",
        "cleanup",
        "skip",
    ],
    min_awaits=10,
    min_move_next=3,
    min_cancel=3,
    min_yields=3,
    min_conditionals=5,
    needs_try_catch=True,
)

# ---- assert_generator_async_triple_switch_stream_finalizer_chains.py ----
import json
import sys

patch = json.load(open(sys.argv[1]))
patch_by_member = {f.get("member_name"): f for f in patch["functions"]}


def assert_triple_switch_stream_finalizer_chain(
    name,
    constants,
    args,
    *,
    min_awaits,
    min_move_next,
    min_cancel,
    min_yields,
    min_conditionals,
    min_yield_star_iterators=0,
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
        or '"try_catch"' not in source_json
        or '"try_finally"' not in source_json
        or source_json.count('"await"') < min_awaits
        or source_json.count('"method": "moveNext"') < min_move_next
        or source_json.count('"method": "cancel"') < min_cancel
        or source_json.count('"yield"') < min_yields
        or source_json.count('"conditional"') < min_conditionals
        or source_json.count('":yield-star-iterator"') < min_yield_star_iterators
        or any(f'"arg": "{arg}"' not in source_json for arg in args)
        or any(f'"string": "{constant}"' not in source_json for constant in constants)
    ):
        raise SystemExit(
            f"expected {name} async* triple switch stream source, got {function}"
        )


assert_triple_switch_stream_finalizer_chain(
    "asyncGeneratedTripleSwitchSelectedAwaitForFinalizerSuperChain",
    [
        "patched-stream-triple-switch-finalizer-body-",
        "patched-stream-triple-switch-finalizer-caught-",
    ],
    [
        "outerTier",
        "middleTier",
        "innerTier",
        "outerPrimary",
        "outerFallback",
        "middlePrimary",
        "middleFallback",
        "innerPrimary",
        "innerFallback",
        "cleanup",
        "skipOuter",
        "stopInner",
    ],
    min_awaits=15,
    min_move_next=4,
    min_cancel=4,
    min_yields=3,
    min_conditionals=7,
    min_yield_star_iterators=1,
)
assert_triple_switch_stream_finalizer_chain(
    "asyncGeneratedTripleSwitchSelectedYieldStarRecoverySuperChain",
    [
        "patched-stream-triple-switch-recovery-body-",
        "patched-stream-triple-switch-recovery-cleanup-",
    ],
    [
        "firstTier",
        "secondTier",
        "cleanupTier",
        "firstPrimary",
        "firstFallback",
        "secondPrimary",
        "secondFallback",
        "cleanupPrimary",
        "cleanupFallback",
        "tail",
        "skip",
    ],
    min_awaits=13,
    min_move_next=3,
    min_cancel=4,
    min_yields=4,
    min_conditionals=7,
    min_yield_star_iterators=2,
)

# ---- assert_generator_async_yield_await_collection_for_chains.py ----
import json
import sys

patch = json.load(open(sys.argv[1]))
patch_by_member = {f.get("member_name"): f for f in patch["functions"]}


def assert_collection_for_chain(
    name,
    constants,
    args,
    *,
    min_awaits,
    min_yields,
    min_conditionals,
    collection_key,
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
        or source_json.count('"yield"') < min_yields
        or source_json.count('"conditional"') < min_conditionals
        or f'"{collection_key}"' not in source_json
        or any(f'"arg": "{arg}"' not in source_json for arg in args)
        or any(f'"string": "{constant}"' not in source_json for constant in constants)
    ):
        raise SystemExit(f"expected {name} async* yield await collection-for source, got {function}")


assert_collection_for_chain(
    "asyncGeneratedYieldAwaitListCollectionForSuperChain",
    [
        "patched-stream-yield-await-list-for-head-",
        "patched-stream-yield-await-list-for-",
        "patched-stream-yield-await-list-for-cleanup-",
    ],
    ["body", "cleanup", "label", "includeExtra", "extra", "tail"],
    min_awaits=6,
    min_yields=2,
    min_conditionals=1,
    collection_key="list_for_in",
)
assert_collection_for_chain(
    "asyncGeneratedYieldAwaitMapCollectionForSuperChain",
    [
        "patched-stream-yield-await-map-for-body-",
        "patched-stream-yield-await-map-for-",
        "patched-stream-yield-await-map-for-cleanup-",
    ],
    ["body", "cleanup", "label", "includeExtra", "extra", "tail"],
    min_awaits=6,
    min_yields=2,
    min_conditionals=1,
    collection_key="map_for_in",
)

# ---- assert_generator_async_yield_await_value_chains.py ----
import json
import sys

patch = json.load(open(sys.argv[1]))
patch_by_member = {f.get("member_name"): f for f in patch["functions"]}


def assert_yield_await_value_chain(
    name,
    constants,
    args,
    *,
    min_awaits,
    min_yields,
    min_conditionals,
    requires_list=False,
    requires_map=False,
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
        or source_json.count('"yield"') < min_yields
        or source_json.count('"conditional"') < min_conditionals
        or (requires_list and '"list"' not in source_json)
        or (requires_map and '"map"' not in source_json)
        or any(f'"arg": "{arg}"' not in source_json for arg in args)
        or any(f'"string": "{constant}"' not in source_json for constant in constants)
    ):
        raise SystemExit(f"expected {name} async* yield await value source, got {function}")


assert_yield_await_value_chain(
    "asyncGeneratedYieldAwaitListValueSuperChain",
    [
        "patched-stream-yield-await-list-premium-",
        "patched-stream-yield-await-list-cleanup-",
    ],
    ["body", "cleanup", "label", "premium"],
    min_awaits=6,
    min_yields=2,
    min_conditionals=1,
    requires_list=True,
)
assert_yield_await_value_chain(
    "asyncGeneratedYieldAwaitMapSwitchValueSuperChain",
    [
        "patched-stream-yield-await-map-premium-",
        "patched-stream-yield-await-map-cleanup-",
    ],
    ["body", "cleanup", "label", "tier"],
    min_awaits=6,
    min_yields=2,
    min_conditionals=2,
    requires_map=True,
)
assert_yield_await_value_chain(
    "asyncGeneratedYieldAwaitStringValueSuperChain",
    [
        "patched-stream-yield-await-string-",
        "patched-stream-yield-await-string-cleanup-",
    ],
    ["body", "cleanup", "label", "enabled"],
    min_awaits=6,
    min_yields=2,
    min_conditionals=1,
)

# ---- assert_generator_async_yield_star_await_stream_chains.py ----
import json
import sys

patch = json.load(open(sys.argv[1]))
patch_by_member = {f.get("member_name"): f for f in patch["functions"]}


def assert_yield_star_await_stream_chain(
    name,
    constants,
    args,
    *,
    min_awaits,
    min_move_next,
    min_cancel,
    min_yields,
    min_yield_star_iterators,
    requires_catch=False,
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
        or (requires_catch and '"try_catch"' not in source_json)
        or source_json.count('"await"') < min_awaits
        or source_json.count('"method": "moveNext"') < min_move_next
        or source_json.count('"method": "cancel"') < min_cancel
        or source_json.count('"yield"') < min_yields
        or source_json.count('":yield-star-iterator"') < min_yield_star_iterators
        or any(f'"arg": "{arg}"' not in source_json for arg in args)
        or any(f'"string": "{constant}"' not in source_json for constant in constants)
    ):
        raise SystemExit(f"expected {name} async* yield* await stream source, got {function}")


assert_yield_star_await_stream_chain(
    "asyncGeneratedYieldStarAwaitStreamFutureSuperChain",
    [
        "patched-stream-yield-star-await-stream-body-",
        "patched-stream-yield-star-await-stream-cleanup-",
    ],
    ["first", "body", "tail", "cleanup", "useTail"],
    min_awaits=9,
    min_move_next=4,
    min_cancel=4,
    min_yields=4,
    min_yield_star_iterators=2,
)
assert_yield_star_await_stream_chain(
    "asyncGeneratedYieldStarAwaitStreamFutureCatchFinallySuperChain",
    ["patched-stream-yield-star-await-stream-caught-"],
    ["first", "recovery", "cleanup"],
    min_awaits=7,
    min_move_next=3,
    min_cancel=3,
    min_yields=3,
    min_yield_star_iterators=2,
    requires_catch=True,
)
