# Merged assertion group. Keep this file below the fixture size limit.


# ---- assert_plan_async_object_call_type_collection_chains.py ----
import json
import sys

patch = json.load(open(sys.argv[1]))
patch_by_member = {f.get("member_name"): f for f in patch["functions"]}


def assert_async_object_chain(
    name,
    constants,
    *,
    min_awaits,
    requires_list_for_in=False,
    requires_map_for_in=False,
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
        or source.get("async_future") is not True
        or source_json.count('"await"') < min_awaits
        or source_json.count('"new_object"') < 2
        or source_json.count('"conditional"') < 4
        or '"try_catch"' not in source_json
        or '"try_finally"' not in source_json
        or '"throw"' not in source_json
        or (requires_list_for_in and '"list_for_in"' not in source_json)
        or (requires_map_for_in and '"map_for_in"' not in source_json)
        or (requires_dynamic_call and '"call_dynamic"' not in source_json)
        or (requires_static_call and '"call_static"' not in source_json)
        or (requires_type_ops and '"is_type"' not in source_json)
        or (requires_type_ops and '"as_type"' not in source_json)
        or any(f'"string": "{constant}"' not in source_json for constant in constants)
    ):
        raise SystemExit(f"expected {name} async object/call/type collection source, got {function}")


assert_async_object_chain(
    "asyncObjectCallTypeCollectionSwitchRecoveryCleanup",
    [
        "patched-async-object-call-type-head",
        "patched-async-object-call-type-user",
        "patched-async-object-call-type-blocked",
        "patched-async-object-call-type-caught-",
        "patched-async-object-call-type-cleanup-",
    ],
    min_awaits=5,
    requires_list_for_in=True,
    requires_dynamic_call=True,
    requires_type_ops=True,
)
assert_async_object_chain(
    "asyncNamedObjectStaticCallMapRecoveryCleanup",
    [
        "patched-async-named-object-map-head",
        "patched-async-named-object-map-name",
        "patched-async-named-object-map-blocked",
        "patched-async-named-object-map-caught-",
        "patched-async-named-object-map-cleanup-",
    ],
    min_awaits=5,
    requires_map_for_in=True,
    requires_static_call=True,
)

# ---- assert_plan_async_object_loop_finalizer_chains.py ----
import json
import sys

patch = json.load(open(sys.argv[1]))
patch_by_member = {f.get("member_name"): f for f in patch["functions"]}


def assert_async_object_loop(
    name,
    constants,
    *,
    min_awaits,
    min_new_objects=0,
    has_catch=False,
    requires_list_for_in=False,
    requires_map_for_in=False,
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
        or source.get("async_future") is not True
        or '"while_loop"' not in source_json
        or '"try_finally"' not in source_json
        or source_json.count('"await"') < min_awaits
        or source_json.count('"new_object"') < min_new_objects
        or (has_catch and '"try_catch"' not in source_json)
        or (requires_list_for_in and '"list_for_in"' not in source_json)
        or (requires_map_for_in and '"map_for_in"' not in source_json)
        or (requires_dynamic_call and '"call_dynamic"' not in source_json)
        or (requires_static_call and '"call_static"' not in source_json)
        or (requires_type_ops and '"is_type"' not in source_json)
        or (requires_type_ops and '"as_type"' not in source_json)
        or any(f'"string": "{constant}"' not in source_json for constant in constants)
    ):
        raise SystemExit(f"expected {name} async object loop source, got {function}")


assert_async_object_loop(
    "asyncWhileObjectDynamicTypeFinalizerChain",
    [
        "patched-async-object-loop-while-head",
        "patched-async-object-loop-while-user",
        "patched-async-object-loop-while-cleanup-",
    ],
    min_awaits=5,
    min_new_objects=2,
    requires_list_for_in=True,
    requires_dynamic_call=True,
    requires_type_ops=True,
)
assert_async_object_loop(
    "asyncForNamedObjectStaticMapCatchFinallyChain",
    [
        "patched-async-object-loop-for-head",
        "patched-async-object-loop-for-name",
        "patched-async-object-loop-for-blocked",
        "patched-async-object-loop-for-caught-",
        "patched-async-object-loop-for-cleanup-",
    ],
    min_awaits=6,
    min_new_objects=4,
    has_catch=True,
    requires_map_for_in=True,
    requires_static_call=True,
)
assert_async_object_loop(
    "asyncDoWhileObjectCallCollectionRecoveryCleanupChain",
    [
        "patched-async-object-loop-do-head",
        "patched-async-object-loop-do-error",
        "patched-async-object-loop-do-caught-",
        "patched-async-object-loop-do-cleanup-",
    ],
    min_awaits=5,
    has_catch=True,
    requires_list_for_in=True,
    requires_dynamic_call=True,
)

# ---- assert_plan_async_switch_statement_collection_chains.py ----
import json
import sys

patch = json.load(open(sys.argv[1]))
patch_by_member = {f.get("member_name"): f for f in patch["functions"]}


def assert_async_switch_collection(
    name,
    constants,
    *,
    min_awaits,
    requires_list_for_in=False,
    requires_map_for_in=False,
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
        or source_json.count('"conditional"') < 6
        or '"try_catch"' not in source_json
        or '"try_finally"' not in source_json
        or '"throw"' not in source_json
        or (requires_list_for_in and '"list_for_in"' not in source_json)
        or (requires_map_for_in and '"map_for_in"' not in source_json)
        or any(f'"string": "{constant}"' not in source_json for constant in constants)
    ):
        raise SystemExit(f"expected {name} async switch collection source, got {function}")


assert_async_switch_collection(
    "asyncSwitchStatementAwaitScrutineeCollectionRecoveryCleanup",
    [
        "patched-async-switch-stmt-collection-head",
        "patched-async-switch-stmt-collection-gold",
        "patched-async-switch-stmt-collection-blocked",
        "patched-async-switch-stmt-collection-caught-",
        "patched-async-switch-stmt-collection-cleanup-",
    ],
    min_awaits=6,
    requires_list_for_in=True,
)
assert_async_switch_collection(
    "asyncSwitchStatementMapRecoveryCleanup",
    [
        "patched-async-switch-stmt-map-head",
        "patched-async-switch-stmt-map-gold",
        "patched-async-switch-stmt-map-blocked",
        "patched-async-switch-stmt-map-caught-",
        "patched-async-switch-stmt-map-cleanup-",
    ],
    min_awaits=4,
    requires_map_for_in=True,
)


# ---- assert_plan_async_generator_guarded_switch_chains.py ----
import json
import sys

patch = json.load(open(sys.argv[1]))
patch_by_member = {f.get("member_name"): f for f in patch["functions"]}


def assert_guarded_stream(
    name,
    constants,
    *,
    min_awaits,
    min_conditionals,
    has_catch=False,
    requires_list_for_in=False,
    requires_map_for_in=False,
    min_move_next=1,
    min_cancel=1,
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
        or source_json.count('"method": "moveNext"') < min_move_next
        or source_json.count('"method": "cancel"') < min_cancel
        or source_json.count('"await"') < min_awaits
        or source_json.count('"conditional"') < min_conditionals
        or (has_catch and '"try_catch"' not in source_json)
        or '"try_finally"' not in source_json
        or (requires_list_for_in and '"list_for_in"' not in source_json)
        or (requires_map_for_in and '"map_for_in"' not in source_json)
        or any(f'"string": "{constant}"' not in source_json for constant in constants)
    ):
        raise SystemExit(f"expected {name} async* guarded switch source, got {function}")


assert_guarded_stream(
    "asyncGeneratedGuardedSwitchYieldFor",
    [
        "patched-stream-guarded-switch-yield-for-gold-",
        "patched-stream-guarded-switch-yield-for-vip-",
        "patched-stream-guarded-switch-yield-for-cleanup-",
    ],
    min_awaits=4,
    min_conditionals=3,
)
assert_guarded_stream(
    "asyncGeneratedGuardedSwitchListCleanup",
    [
        "patched-stream-guarded-switch-list-gold-",
        "patched-stream-guarded-switch-list-vip-",
        "patched-stream-guarded-switch-list-cleanup-",
    ],
    min_awaits=4,
    min_conditionals=3,
    requires_list_for_in=True,
)
assert_guarded_stream(
    "asyncGeneratedGuardedSwitchMapRecoveryCleanup",
    [
        "patched-stream-guarded-switch-map-gold-",
        "patched-stream-guarded-switch-map-vip-",
        "patched-stream-guarded-switch-map-caught-",
        "patched-stream-guarded-switch-map-cleanup-",
    ],
    min_awaits=4,
    min_conditionals=3,
    has_catch=True,
    requires_map_for_in=True,
)
assert_guarded_stream(
    "asyncGeneratedGuardedSwitchAwaitScrutineeYieldStar",
    [
        "patched-stream-guarded-switch-await-scrutinee-gold-",
        "patched-stream-guarded-switch-await-scrutinee-vip-",
        "patched-stream-guarded-switch-await-scrutinee-caught-",
        "patched-stream-guarded-switch-await-scrutinee-cleanup-",
    ],
    min_awaits=7,
    min_conditionals=3,
    has_catch=True,
    min_move_next=2,
    min_cancel=2,
)
assert_guarded_stream(
    "asyncGeneratedNestedGuardedSwitchAwaitForCollection",
    [
        "patched-stream-nested-guarded-switch-gold-",
        "patched-stream-nested-guarded-switch-vip-",
        "patched-stream-nested-guarded-switch-cleanup-",
        "stop-guarded-switch-inner",
    ],
    min_awaits=6,
    min_conditionals=4,
    requires_list_for_in=True,
    min_move_next=2,
    min_cancel=2,
)

# ---- assert_plan_async_generator_switch_statement_chains.py ----
import json
import sys

patch = json.load(open(sys.argv[1]))
patch_by_member = {f.get("member_name"): f for f in patch["functions"]}

function = patch_by_member.get(
    "asyncGeneratedGuardedSwitchStatementMapRecoveryCleanup"
)
if function is None:
    raise SystemExit(
        "missing inventory entry for asyncGeneratedGuardedSwitchStatementMapRecoveryCleanup"
    )

source = function.get("bytecode_source")
source_json = json.dumps(source)
constants = [
    "patched-stream-guarded-switch-stmt-map-gold-",
    "patched-stream-guarded-switch-stmt-map-vip-",
    "patched-stream-guarded-switch-stmt-map-blocked",
    "patched-stream-guarded-switch-stmt-map-caught-",
    "patched-stream-guarded-switch-stmt-map-cleanup-",
]
if (
    function.get("unsupported_reasons") != []
    or not isinstance(source, dict)
    or source.get("async_kind") != "async_star"
    or source_json.count('"method": "moveNext"') < 1
    or source_json.count('"method": "cancel"') < 1
    or source_json.count('"await"') < 4
    or source_json.count('"conditional"') < 3
    or '"try_catch"' not in source_json
    or '"try_finally"' not in source_json
    or '"map_for_in"' not in source_json
    or '"throw"' not in source_json
    or any(f'"string": "{constant}"' not in source_json for constant in constants)
):
    raise SystemExit(
        "expected asyncGeneratedGuardedSwitchStatementMapRecoveryCleanup "
        f"async* guarded switch statement source, got {function}"
    )


# ---- assert_plan_async_generator_switch_stream_chains.py ----
import json
import sys

patch = json.load(open(sys.argv[1]))
patch_by_member = {f.get("member_name"): f for f in patch["functions"]}


def assert_stream_switch(
    name,
    constants,
    *,
    min_move_next,
    min_cancel,
    min_awaits,
    min_try_finally,
    min_conditionals,
    has_catch=False,
    requires_list_for_in=False,
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
        or source_json.count('"method": "moveNext"') < min_move_next
        or source_json.count('"method": "cancel"') < min_cancel
        or source_json.count('"await"') < min_awaits
        or source_json.count('"try_finally"') < min_try_finally
        or source_json.count('"conditional"') < min_conditionals
        or '"throw"' not in source_json
        or (has_catch and '"try_catch"' not in source_json)
        or (requires_list_for_in and '"list_for_in"' not in source_json)
        or any(f'"string": "{constant}"' not in source_json for constant in constants)
    ):
        raise SystemExit(f"expected {name} async* switch stream source, got {function}")


assert_stream_switch(
    "asyncGeneratedSwitchStatementYieldStarRecoveryCleanup",
    [
        "patched-stream-switch-stmt-yield-star-gold-head",
        "patched-stream-switch-stmt-yield-star-vip-",
        "patched-stream-switch-stmt-yield-star-blocked",
        "patched-stream-switch-stmt-yield-star-caught-",
        "patched-stream-switch-stmt-yield-star-cleanup-tail-",
    ],
    min_move_next=4,
    min_cancel=4,
    min_awaits=12,
    min_try_finally=4,
    min_conditionals=6,
    has_catch=True,
)
assert_stream_switch(
    "asyncGeneratedNestedSwitchStatementYieldStarListCleanup",
    [
        "patched-stream-nested-switch-stmt-yield-star-list-gold-",
        "patched-stream-nested-switch-stmt-yield-star-list-vip-",
        "patched-stream-nested-switch-stmt-yield-star-list-blocked",
        "patched-stream-nested-switch-stmt-yield-star-list-cleanup-tail-",
    ],
    min_move_next=3,
    min_cancel=3,
    min_awaits=10,
    min_try_finally=3,
    min_conditionals=6,
    requires_list_for_in=True,
)


# ---- assert_plan_sync_generator_switch_iterable_chains.py ----
import json
import sys

patch = json.load(open(sys.argv[1]))
patch_by_member = {f.get("member_name"): f for f in patch["functions"]}


def assert_iterable_switch(
    name,
    constants,
    *,
    min_yield_for_in,
    min_conditionals,
    has_catch=False,
    requires_list_for_in=False,
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
        or source_json.count('"yield_for_in"') < min_yield_for_in
        or source_json.count('"conditional"') < min_conditionals
        or '"try_finally"' not in source_json
        or '"throw"' not in source_json
        or (has_catch and '"try_catch"' not in source_json)
        or (requires_list_for_in and '"list_for_in"' not in source_json)
        or any(f'"string": "{constant}"' not in source_json for constant in constants)
    ):
        raise SystemExit(f"expected {name} sync* switch iterable source, got {function}")


assert_iterable_switch(
    "syncGeneratedSwitchStatementYieldStarRecoveryCleanup",
    [
        "patched-iterable-switch-stmt-yield-star-gold-head",
        "patched-iterable-switch-stmt-yield-star-vip-",
        "patched-iterable-switch-stmt-yield-star-blocked",
        "patched-iterable-switch-stmt-yield-star-caught-",
        "patched-iterable-switch-stmt-yield-star-cleanup-head",
    ],
    min_yield_for_in=4,
    min_conditionals=5,
    has_catch=True,
)
assert_iterable_switch(
    "syncGeneratedNestedSwitchStatementListCleanup",
    [
        "patched-iterable-nested-switch-stmt-list-gold-",
        "patched-iterable-nested-switch-stmt-list-vip-",
        "patched-iterable-nested-switch-stmt-list-blocked",
        "patched-iterable-nested-switch-stmt-list-cleanup-tail-",
    ],
    min_yield_for_in=3,
    min_conditionals=4,
    requires_list_for_in=True,
)


# ---- assert_plan_async_loop_update_chains.py ----
import json
import sys

patch = json.load(open(sys.argv[1]))
patch_by_member = {f.get("member_name"): f for f in patch["functions"]}


def assert_loop_update_chain(
    name,
    constants,
    awaits,
    *,
    has_catch=False,
    has_finally=False,
    has_break_body=False,
    min_conditionals=0,
    min_list_add_all=0,
    min_map_add_all=0,
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
        or '"while_loop"' not in source_json
        or '"name": "i"' not in source_json
        or '"name": "j"' not in source_json
        or source_json.count('"await"') < len(awaits)
        or any(f'"await": {{"arg": "{arg}"}}' not in source_json for arg in awaits)
        or source_json.count('"set_local"') < 4
        or source_json.count('"conditional"') < min_conditionals
        or source_json.count('"list_add_all"') < min_list_add_all
        or source_json.count('"map_add_all"') < min_map_add_all
        or (has_catch and '"try_catch"' not in source_json)
        or (has_finally and '"try_finally"' not in source_json)
        or (has_break_body and '"break_body"' not in source_json)
        or any(f'"string": "{constant}"' not in source_json for constant in constants)
    ):
        raise SystemExit(f"expected {name} async loop update chain source, got {function}")


assert_loop_update_chain(
    "asyncForAwaitConditionMultiAwaitUpdateTryFinallyBranchLocal",
    [
        "patched-for-await-condition-multi-await-update-try-finally-branch",
        "patched-for-await-condition-multi-await-update-try-finally-pro",
        "patched-for-await-condition-multi-await-update-try-finally-basic",
        "-finally-",
    ],
    ["keepGoing", "ready", "cleanup", "nextI", "nextJ"],
    has_finally=True,
)
assert_loop_update_chain(
    "asyncForAwaitConditionMultiAwaitUpdateTryCatchBranchLocal",
    [
        "patched-for-await-condition-multi-await-update-try-catch-branch",
        "patched-for-await-condition-multi-await-update-try-catch-error-",
        "patched-for-await-condition-multi-await-update-try-catch-pro",
        "patched-for-await-condition-multi-await-update-try-catch-basic",
        "-caught-",
    ],
    ["keepGoing", "fail", "ready", "nextI", "nextJ"],
    has_catch=True,
)
assert_loop_update_chain(
    "asyncForMultiAwaitUpdateTryFinallyNestedBranchLocal",
    [
        "patched-for-multi-await-update-try-finally-nested",
        "-patched-for-multi-await-update-try-finally-nested-pro-",
        "-patched-for-multi-await-update-try-finally-nested-basic-",
        "-patched-for-multi-await-update-try-finally-nested-tail-",
        "-finally-",
    ],
    ["ready", "cleanup", "nextI", "nextJ"],
    has_finally=True,
)
assert_loop_update_chain(
    "asyncForMultiAwaitUpdateTryCatchNestedBranchLocal",
    [
        "patched-for-multi-await-update-try-catch-nested",
        "patched-for-multi-await-update-try-catch-nested-error-",
        "-patched-for-multi-await-update-try-catch-nested-pro-",
        "-patched-for-multi-await-update-try-catch-nested-basic-",
        "-patched-for-multi-await-update-try-catch-nested-tail-",
        "-caught-",
    ],
    ["fail", "ready", "nextI", "nextJ"],
    has_catch=True,
)
assert_loop_update_chain(
    "asyncForAwaitConditionMultiAwaitUpdateSwitchExprBranchLocal",
    [
        "patched-for-await-condition-multi-await-update-switch-expr",
        "patched-for-await-condition-multi-await-update-switch-expr-pro",
        "patched-for-await-condition-multi-await-update-switch-expr-standard",
        "-patched-for-await-condition-multi-await-update-switch-expr-basic-",
    ],
    ["keepGoing", "tierReady", "nextI", "nextJ"],
    min_conditionals=3,
)
assert_loop_update_chain(
    "asyncForAwaitConditionMultiAwaitUpdateSwitchTryFinally",
    [
        "patched-for-await-condition-multi-await-update-switch-finally",
        "patched-for-await-condition-multi-await-update-switch-finally-pro",
        "patched-for-await-condition-multi-await-update-switch-finally-basic",
        "-finally-",
    ],
    ["keepGoing", "tierReady", "cleanup", "nextI", "nextJ"],
    has_finally=True,
    min_conditionals=2,
)
assert_loop_update_chain(
    "asyncForAwaitConditionMultiAwaitUpdateSwitchTryCatch",
    [
        "patched-for-await-condition-multi-await-update-switch-catch",
        "patched-for-await-condition-multi-await-update-switch-catch-error-",
        "patched-for-await-condition-multi-await-update-switch-catch-pro",
        "patched-for-await-condition-multi-await-update-switch-catch-basic",
        "-caught-",
    ],
    ["keepGoing", "fail", "tierReady", "nextI", "nextJ"],
    has_catch=True,
    min_conditionals=2,
)
assert_loop_update_chain(
    "asyncForMultiAwaitUpdateSwitchStatementNestedBranchLocal",
    [
        "patched-for-multi-await-update-switch-stmt-nested",
        "-patched-for-multi-await-update-switch-stmt-pro-",
        "-patched-for-multi-await-update-switch-stmt-standard-",
        "-patched-for-multi-await-update-switch-stmt-basic-",
        "-patched-for-multi-await-update-switch-stmt-tail-",
    ],
    ["tierReady", "nextI", "nextJ"],
    min_conditionals=3,
)
assert_loop_update_chain(
    "asyncForMultiAwaitUpdateSwitchStatementTryFinallyNested",
    [
        "patched-for-multi-await-update-switch-stmt-finally",
        "-patched-for-multi-await-update-switch-stmt-finally-pro-",
        "-patched-for-multi-await-update-switch-stmt-finally-basic-",
        "-finally-",
    ],
    ["tierReady", "cleanup", "nextI", "nextJ"],
    has_finally=True,
    min_conditionals=2,
)
assert_loop_update_chain(
    "asyncForMultiAwaitUpdateSwitchStatementTryCatchNested",
    [
        "patched-for-multi-await-update-switch-stmt-catch",
        "patched-for-multi-await-update-switch-stmt-catch-error-",
        "-patched-for-multi-await-update-switch-stmt-catch-pro-",
        "-patched-for-multi-await-update-switch-stmt-catch-basic-",
        "-caught-",
    ],
    ["fail", "tierReady", "nextI", "nextJ"],
    has_catch=True,
    min_conditionals=2,
)
assert_loop_update_chain(
    "asyncForAwaitConditionMultiAwaitUpdateNestedBranchTryFinally",
    [
        "patched-for-await-condition-multi-await-update-nested-finally",
        "-patched-for-await-condition-multi-await-update-nested-finally-special-",
        "-patched-for-await-condition-multi-await-update-nested-finally-premium-",
        "-patched-for-await-condition-multi-await-update-nested-finally-basic-",
        "-finally-",
    ],
    ["keepGoing", "ready", "cleanup", "nextI", "nextJ"],
    has_finally=True,
    min_conditionals=2,
)
assert_loop_update_chain(
    "asyncForMultiAwaitUpdateTryCatchFinallyNestedBranchLocal",
    [
        "patched-for-multi-await-update-try-catch-finally-nested",
        "patched-for-multi-await-update-try-catch-finally-error-",
        "-patched-for-multi-await-update-try-catch-finally-pro-",
        "-patched-for-multi-await-update-try-catch-finally-basic-",
        "-patched-for-multi-await-update-try-catch-finally-tail-",
        "-caught-",
        "-finally-",
    ],
    ["fail", "ready", "cleanup", "nextI", "nextJ"],
    has_catch=True,
    has_finally=True,
    min_conditionals=2,
)
assert_loop_update_chain(
    "asyncForAwaitConditionMultiAwaitUpdateSwitchExprNestedTryFinally",
    [
        "patched-for-await-condition-multi-await-update-switch-expr-nested-finally",
        "patched-for-await-condition-multi-await-update-switch-expr-nested-finally-pro",
        "patched-for-await-condition-multi-await-update-switch-expr-nested-finally-standard",
        "-patched-for-await-condition-multi-await-update-switch-expr-nested-finally-basic-",
        "-finally-",
    ],
    ["keepGoing", "tierReady", "cleanup", "nextI", "nextJ"],
    has_finally=True,
    min_conditionals=3,
)
assert_loop_update_chain(
    "asyncForMultiAwaitUpdateSwitchStatementTryCatchFinallyNestedBranchLocal",
    [
        "patched-for-multi-await-update-switch-stmt-catch-finally-nested",
        "patched-for-multi-await-update-switch-stmt-catch-finally-error-",
        "-patched-for-multi-await-update-switch-stmt-catch-finally-pro-",
        "-patched-for-multi-await-update-switch-stmt-catch-finally-basic-",
        "-caught-",
        "-finally-",
    ],
    ["fail", "tierReady", "cleanup", "nextI", "nextJ"],
    has_catch=True,
    has_finally=True,
    min_conditionals=2,
)
assert_loop_update_chain(
    "asyncForAwaitConditionMultiAwaitUpdateContinueBreakTryFinally",
    [
        "patched-for-await-condition-multi-await-update-continue-break",
        "-body-",
        "-finally-",
    ],
    ["keepGoing", "skip", "stop", "cleanup", "nextI", "nextJ"],
    has_finally=True,
    has_break_body=True,
)
assert_loop_update_chain(
    "asyncForMultiAwaitUpdateNestedSwitchExprTryCatchBranchLocal",
    [
        "patched-for-multi-await-update-nested-switch-expr-catch",
        "patched-for-multi-await-update-nested-switch-expr-catch-error-",
        "patched-for-multi-await-update-nested-switch-expr-catch-pro",
        "patched-for-multi-await-update-nested-switch-expr-catch-standard",
        "-patched-for-multi-await-update-nested-switch-expr-catch-basic-",
        "-caught-",
    ],
    ["fail", "tierReady", "nextI", "nextJ"],
    has_catch=True,
    min_conditionals=3,
)
assert_loop_update_chain(
    "asyncForAwaitConditionMultiAwaitUpdateCollectionTryFinallyList",
    [
        "patched-for-await-condition-multi-await-update-collection-list-head",
        "patched-for-await-condition-multi-await-update-collection-list-premium",
        "patched-for-await-condition-multi-await-update-collection-list-extra-",
        "patched-for-await-condition-multi-await-update-collection-list-cleanup-",
    ],
    ["keepGoing", "tierReady", "cleanup", "nextI", "nextJ"],
    has_finally=True,
    min_conditionals=2,
    min_list_add_all=2,
)
assert_loop_update_chain(
    "asyncForMultiAwaitUpdateCollectionTryCatchFinallyMap",
    [
        "patched-for-multi-await-update-collection-map-head",
        "patched-for-multi-await-update-collection-map-premium",
        "patched-for-multi-await-update-collection-map-extra-",
        "patched-for-multi-await-update-collection-map-caught-",
        "patched-for-multi-await-update-collection-map-cleanup-",
    ],
    ["fail", "tierReady", "recovery", "cleanup", "nextI", "nextJ"],
    has_catch=True,
    has_finally=True,
    min_conditionals=2,
    min_map_add_all=2,
)

# ---- assert_plan_async_loop_guarded_switch_chains.py ----
import json
import sys

patch = json.load(open(sys.argv[1]))
patch_by_member = {f.get("member_name"): f for f in patch["functions"]}


def assert_loop_guarded_switch(
    name,
    constants,
    *,
    min_awaits,
    min_conditionals,
    has_catch=False,
    requires_list_for_in=False,
    requires_map_for_in=False,
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
        or '"while_loop"' not in source_json
        or '"try_finally"' not in source_json
        or source_json.count('"await"') < min_awaits
        or source_json.count('"conditional"') < min_conditionals
        or (has_catch and '"try_catch"' not in source_json)
        or (requires_list_for_in and '"list_for_in"' not in source_json)
        or (requires_map_for_in and '"map_for_in"' not in source_json)
        or any(f'"string": "{constant}"' not in source_json for constant in constants)
    ):
        raise SystemExit(f"expected {name} async loop guarded switch source, got {function}")


assert_loop_guarded_switch(
    "asyncWhileNotAwaitGuardedSwitchCollectionFinalizer",
    [
        "patched-loop-not-await-guarded-switch-list-head",
        "patched-loop-not-await-guarded-switch-list-gold",
        "patched-loop-not-await-guarded-switch-list-vip",
        "patched-loop-not-await-guarded-switch-list-cleanup-",
    ],
    min_awaits=5,
    min_conditionals=4,
    requires_list_for_in=True,
)
assert_loop_guarded_switch(
    "asyncDoWhileNotAwaitGuardedSwitchMapTryCatchFinally",
    [
        "patched-loop-not-await-guarded-switch-map-head",
        "patched-loop-not-await-guarded-switch-map-gold",
        "patched-loop-not-await-guarded-switch-map-vip",
        "patched-loop-not-await-guarded-switch-map-caught-",
        "patched-loop-not-await-guarded-switch-map-cleanup-",
    ],
    min_awaits=5,
    min_conditionals=4,
    has_catch=True,
    requires_map_for_in=True,
)
assert_loop_guarded_switch(
    "asyncForAwaitScrutineeNotAwaitGuardedSwitchFinally",
    [
        "patched-for-await-scrutinee-not-await-guarded-switch-head",
        "patched-for-await-scrutinee-not-await-guarded-switch-gold-",
        "patched-for-await-scrutinee-not-await-guarded-switch-vip-",
        "patched-for-await-scrutinee-not-await-guarded-switch-cleanup-",
    ],
    min_awaits=4,
    min_conditionals=4,
    requires_list_for_in=True,
)
assert_loop_guarded_switch(
    "asyncWhileAwaitScrutineeNotAwaitGuardedMapRecoveryCleanup",
    [
        "patched-while-await-scrutinee-not-await-guarded-map-head",
        "patched-while-await-scrutinee-not-await-guarded-map-gold",
        "patched-while-await-scrutinee-not-await-guarded-map-vip",
        "patched-while-await-scrutinee-not-await-guarded-map-caught-",
        "patched-while-await-scrutinee-not-await-guarded-map-cleanup-",
    ],
    min_awaits=5,
    min_conditionals=4,
    has_catch=True,
    requires_map_for_in=True,
)
