import json
import sys

patch = json.load(open(sys.argv[1]))
patch_by_member = {f.get("member_name"): f for f in patch["functions"]}


def assert_finalizer_chain(
    name,
    constants,
    args,
    *,
    min_try_catch=1,
    min_try_finally=1,
    min_awaits=1,
    min_move_next=1,
    min_cancel=1,
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
        or source_json.count('"try_catch"') < min_try_catch
        or source_json.count('"try_finally"') < min_try_finally
        or source_json.count('"await"') < min_awaits
        or source_json.count('"method": "moveNext"') < min_move_next
        or source_json.count('"method": "cancel"') < min_cancel
        or source_json.count('"list"') < min_lists
        or source_json.count('"map"') < min_maps
        or source_json.count('"list_for_in"') + source_json.count('"map_for_in"') < min_for_in
        or source_json.count('"conditional"') < min_conditionals
        or any(f'"arg": "{arg}"' not in source_json for arg in args)
        or any(f'"string": "{constant}"' not in source_json for constant in constants)
    ):
        raise SystemExit(f"expected {name} async* finalizer chain source, got {function}")


assert_finalizer_chain(
    "asyncGeneratedCatchAwaitForRecoveryFinallyYieldStarCleanup",
    [
        "patched-stream-catch-await-for-recovery-finally-yield-star-body-",
        "patched-stream-catch-await-for-recovery-finally-yield-star-caught-",
    ],
    ["body", "recovery", "cleanup"],
    min_awaits=4,
    min_move_next=3,
    min_cancel=3,
)
assert_finalizer_chain(
    "asyncGeneratedCatchYieldStarRecoveryFinallyAwaitForCleanup",
    [
        "patched-stream-catch-yield-star-recovery-finally-await-for-caught-",
        "patched-stream-catch-yield-star-recovery-finally-await-for-cleanup-",
    ],
    ["body", "recovery", "cleanup"],
    min_awaits=4,
    min_move_next=3,
    min_cancel=3,
)
assert_finalizer_chain(
    "asyncGeneratedStreamCollectionSwitchFinallyYieldStar",
    [
        "patched-stream-collection-switch-finally-yield-star-head",
        "patched-stream-collection-switch-finally-yield-star-premium",
        "patched-stream-collection-switch-finally-yield-star-body-",
    ],
    ["body", "cleanup", "tier"],
    min_try_catch=0,
    min_awaits=3,
    min_move_next=2,
    min_cancel=2,
    min_lists=3,
    min_conditionals=2,
)
assert_finalizer_chain(
    "asyncGeneratedStreamMapSwitchCatchAwaitForFinallyCleanup",
    [
        "patched-stream-map-switch-catch-await-for-finally-head",
        "patched-stream-map-switch-catch-await-for-finally-premium",
        "patched-stream-map-switch-catch-await-for-finally-caught-",
        "patched-stream-map-switch-catch-await-for-finally-cleanup-",
    ],
    ["body", "recovery", "cleanup", "tier"],
    min_awaits=4,
    min_move_next=2,
    min_cancel=2,
    min_maps=6,
    min_conditionals=2,
)
assert_finalizer_chain(
    "asyncGeneratedNestedCatchAwaitForFinallyYieldStarCleanup",
    [
        "patched-stream-nested-catch-await-for-finally-yield-star-first-",
        "patched-stream-nested-catch-await-for-finally-yield-star-inner-",
        "skip-nested-finalizer",
    ],
    ["first", "second", "recovery", "cleanup"],
    min_try_catch=1,
    min_try_finally=3,
    min_awaits=6,
    min_move_next=4,
    min_cancel=4,
)
assert_finalizer_chain(
    "asyncGeneratedYieldStarNestedCatchFinallyAwaitForCleanup",
    [
        "patched-stream-yield-star-nested-catch-finally-await-for-inner-",
        "patched-stream-yield-star-nested-catch-finally-await-for-cleanup-",
        "skip-cleanup-finalizer",
    ],
    ["first", "second", "cleanup"],
    min_try_catch=1,
    min_try_finally=3,
    min_awaits=6,
    min_move_next=3,
    min_cancel=3,
    min_conditionals=1,
)
assert_finalizer_chain(
    "asyncGeneratedAwaitForCatchCollectionFinallyAwaitFor",
    [
        "patched-stream-await-for-catch-collection-finally-body-",
        "patched-stream-await-for-catch-collection-finally-extra-",
        "patched-stream-await-for-catch-collection-finally-caught-",
        "patched-stream-await-for-catch-collection-finally-cleanup-",
    ],
    ["body", "recovery", "cleanup", "extra"],
    min_awaits=5,
    min_move_next=3,
    min_cancel=3,
    min_lists=3,
    min_for_in=1,
)
assert_finalizer_chain(
    "asyncGeneratedYieldStarCatchMapCollectionFinallyYieldStar",
    [
        "patched-stream-yield-star-catch-map-finally-caught-",
        "patched-stream-yield-star-catch-map-finally-extra-",
    ],
    ["body", "recovery", "cleanup", "extra"],
    min_awaits=6,
    min_move_next=3,
    min_cancel=3,
    min_maps=1,
    min_for_in=1,
)
assert_finalizer_chain(
    "asyncGeneratedSequentialAwaitForFinallyTwoCleanups",
    [
        "patched-stream-sequential-finally-two-cleanups-first-",
        "patched-stream-sequential-finally-two-cleanups-second-",
        "patched-stream-sequential-finally-two-cleanups-cleanup-",
        "skip-second-cleanup-chain",
    ],
    ["first", "second", "cleanup", "tail"],
    min_try_catch=0,
    min_awaits=6,
    min_move_next=4,
    min_cancel=4,
)
assert_finalizer_chain(
    "asyncGeneratedYieldStarCatchAwaitForSwitchRecoveryFinallyYieldStar",
    [
        "patched-stream-yield-star-catch-switch-recovery-premium-",
        "patched-stream-yield-star-catch-switch-recovery-standard-",
    ],
    ["body", "recovery", "cleanup", "tier"],
    min_awaits=5,
    min_move_next=3,
    min_cancel=3,
    min_conditionals=2,
)
assert_finalizer_chain(
    "asyncGeneratedNestedAwaitForCatchFinallyCollectionCleanup",
    [
        "patched-stream-nested-await-for-collection-cleanup-body-",
        "patched-stream-nested-await-for-collection-cleanup-extra-",
        "patched-stream-nested-await-for-collection-cleanup-caught-",
        "patched-stream-nested-await-for-collection-cleanup-cleanup-",
    ],
    ["outer", "inner", "recovery", "cleanup", "extra"],
    min_awaits=6,
    min_move_next=4,
    min_cancel=4,
    min_lists=3,
    min_for_in=1,
)
assert_finalizer_chain(
    "asyncGeneratedYieldStarCatchFinallyMapCleanup",
    [
        "patched-stream-yield-star-catch-finally-map-caught-",
        "patched-stream-yield-star-catch-finally-map-extra-",
    ],
    ["body", "recovery", "cleanup", "extra"],
    min_awaits=5,
    min_move_next=3,
    min_cancel=3,
    min_maps=1,
    min_for_in=1,
)
assert_finalizer_chain(
    "asyncGeneratedAwaitForCatchYieldStarFinallyAwaitForTail",
    [
        "patched-stream-await-for-catch-yield-star-finally-tail-body-",
        "patched-stream-await-for-catch-yield-star-finally-tail-caught-",
        "patched-stream-await-for-catch-yield-star-finally-tail-cleanup-",
        "stop-body-tail-chain",
    ],
    ["body", "recovery", "cleanup", "tail"],
    min_awaits=6,
    min_move_next=4,
    min_cancel=4,
)
assert_finalizer_chain(
    "asyncGeneratedYieldStarThenNestedAwaitForFinallyCollection",
    [
        "patched-stream-yield-star-nested-await-for-finally-collection-body-",
        "patched-stream-yield-star-nested-await-for-finally-collection-extra-",
        "patched-stream-yield-star-nested-await-for-finally-collection-cleanup-",
        "skip-nested-tail-chain",
    ],
    ["first", "outer", "inner", "cleanup", "extra"],
    min_try_catch=0,
    min_awaits=6,
    min_move_next=4,
    min_cancel=4,
    min_lists=2,
    min_for_in=1,
    min_conditionals=1,
)
assert_finalizer_chain(
    "asyncGeneratedTripleYieldStarCatchFinallyAwaitForCleanup",
    [
        "patched-stream-triple-yield-star-catch-finally-cleanup-caught-",
        "patched-stream-triple-yield-star-catch-finally-cleanup-",
        "skip-triple-cleanup",
    ],
    ["first", "second", "third", "recovery", "cleanup"],
    min_awaits=8,
    min_move_next=5,
    min_cancel=5,
    min_conditionals=1,
)
assert_finalizer_chain(
    "asyncGeneratedAwaitForSwitchCatchMapFinallyYieldStarCleanup",
    [
        "patched-stream-await-for-switch-catch-map-finally-premium-",
        "patched-stream-await-for-switch-catch-map-finally-standard-",
        "patched-stream-await-for-switch-catch-map-finally-caught-",
    ],
    ["body", "recovery", "cleanup", "tier"],
    min_awaits=5,
    min_move_next=3,
    min_cancel=3,
    min_maps=3,
    min_conditionals=2,
)
assert_finalizer_chain(
    "asyncGeneratedAwaitForCatchYieldStarFinallyDoubleAwaitForCleanup",
    [
        "patched-stream-await-for-catch-yield-star-double-cleanup-body-",
        "patched-stream-await-for-catch-yield-star-double-cleanup-caught-",
        "patched-stream-await-for-catch-yield-star-double-cleanup-cleanup-",
        "patched-stream-await-for-catch-yield-star-double-cleanup-tail-",
        "skip-double-await-for-cleanup",
    ],
    ["body", "recovery", "cleanup", "tail"],
    min_awaits=6,
    min_move_next=4,
    min_cancel=4,
    min_conditionals=1,
)
assert_finalizer_chain(
    "asyncGeneratedYieldStarCatchAwaitForFinallyListCleanupTail",
    [
        "patched-stream-yield-star-catch-await-for-list-cleanup-caught-",
        "patched-stream-yield-star-catch-await-for-list-cleanup-extra-",
        "patched-stream-yield-star-catch-await-for-list-cleanup-cleanup-",
        "patched-stream-yield-star-catch-await-for-list-cleanup-tail-",
    ],
    ["body", "recovery", "cleanup", "extra"],
    min_awaits=5,
    min_move_next=3,
    min_cancel=3,
    min_lists=2,
    min_for_in=1,
)
assert_finalizer_chain(
    "asyncGeneratedNestedAwaitForInnerCatchFinallyYieldStarCleanup",
    [
        "patched-stream-nested-inner-catch-yield-star-cleanup-body-",
        "patched-stream-nested-inner-catch-yield-star-cleanup-caught-",
        "stop-inner-finalizer-chain",
    ],
    ["outer", "inner", "recovery", "cleanup"],
    min_awaits=6,
    min_move_next=4,
    min_cancel=4,
)
assert_finalizer_chain(
    "asyncGeneratedYieldStarCatchMapRecoveryFinallyAwaitForCleanupTail",
    [
        "patched-stream-yield-star-map-recovery-await-cleanup-caught-",
        "patched-stream-yield-star-map-recovery-await-cleanup-extra-",
        "patched-stream-yield-star-map-recovery-await-cleanup-cleanup-",
        "patched-stream-yield-star-map-recovery-await-cleanup-tail-",
    ],
    ["body", "recovery", "cleanup", "extra"],
    min_awaits=5,
    min_move_next=3,
    min_cancel=3,
    min_maps=2,
    min_for_in=1,
)
assert_finalizer_chain(
    "asyncGeneratedSequentialYieldStarAwaitForFinallyYieldStarTail",
    [
        "patched-stream-sequential-yield-star-await-for-tail-body-",
        "skip-sequential-yield-star-await-for",
    ],
    ["first", "second", "cleanup", "tail"],
    min_try_catch=0,
    min_awaits=6,
    min_move_next=4,
    min_cancel=4,
    min_conditionals=1,
)
assert_finalizer_chain(
    "asyncGeneratedAwaitForSwitchCatchFinallyListCleanupTail",
    [
        "patched-stream-await-for-switch-list-cleanup-premium-",
        "patched-stream-await-for-switch-list-cleanup-standard-",
        "patched-stream-await-for-switch-list-cleanup-extra-",
        "patched-stream-await-for-switch-list-cleanup-caught-",
        "patched-stream-await-for-switch-list-cleanup-cleanup-",
    ],
    ["body", "recovery", "cleanup", "tier", "extra"],
    min_awaits=5,
    min_move_next=3,
    min_cancel=3,
    min_lists=3,
    min_for_in=1,
    min_conditionals=2,
)
