import json
import sys

patch = json.load(open(sys.argv[1]))
patch_by_member = {f.get("member_name"): f for f in patch["functions"]}


def assert_stream_chain(
    name,
    args,
    constants,
    min_move_next,
    min_cancel,
    *,
    min_try_catch=1,
    min_try_finally=1,
    min_awaits=1,
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
        or source_json.count('"method": "moveNext"') < min_move_next
        or source_json.count('"method": "cancel"') < min_cancel
        or source_json.count('"await"') < min_awaits
        or source_json.count('"conditional"') < min_conditionals
        or any(f'"arg": "{arg}"' not in source_json for arg in args)
        or any(f'"string": "{constant}"' not in source_json for constant in constants)
    ):
        raise SystemExit(f"expected {name} async* stream chain source, got {function}")


assert_stream_chain(
    "asyncGeneratedYieldStarNestedCatchFinallyAwaitRecovery",
    ["first", "second", "recovery", "cleanup"],
    [
        "patched-stream-yield-star-nested-catch-finally-inner-",
        "patched-stream-yield-star-nested-catch-finally-outer-",
        "patched-stream-yield-star-nested-catch-finally-cleanup-",
    ],
    2,
    2,
    min_try_catch=2,
    min_try_finally=3,
    min_awaits=6,
)
assert_stream_chain(
    "asyncGeneratedYieldStarNestedFinallyAwaitCleanup",
    ["first", "second", "cleanup"],
    [
        "patched-stream-yield-star-nested-finally-inner-cleanup-",
        "patched-stream-yield-star-nested-finally-outer-cleanup-",
    ],
    2,
    2,
    min_try_catch=0,
    min_try_finally=4,
    min_awaits=6,
)
assert_stream_chain(
    "asyncGeneratedAwaitForNestedCatchFinallyAwaitRecovery",
    ["outer", "inner", "recovery", "cleanup"],
    [
        "patched-stream-await-for-nested-catch-finally-await-body-",
        "patched-stream-await-for-nested-catch-finally-await-caught-",
        "patched-stream-await-for-nested-catch-finally-await-cleanup-",
    ],
    2,
    2,
    min_try_catch=1,
    min_try_finally=3,
    min_awaits=6,
)
assert_stream_chain(
    "asyncGeneratedAwaitForTripleNestedCatchFinallyAwaitRecovery",
    ["outer", "middle", "inner", "recovery", "cleanup"],
    [
        "patched-stream-await-for-triple-nested-catch-finally-await-body-",
        "patched-stream-await-for-triple-nested-catch-finally-await-caught-",
        "patched-stream-await-for-triple-nested-catch-finally-await-cleanup-",
        "skip",
        "stop-middle",
    ],
    3,
    3,
    min_try_catch=1,
    min_try_finally=4,
    min_awaits=8,
)
assert_stream_chain(
    "asyncGeneratedYieldStarTripleNestedCatchFinallyAwaitRecovery",
    ["first", "second", "third", "recovery", "cleanup"],
    [
        "patched-stream-yield-star-triple-nested-catch-finally-inner-",
        "patched-stream-yield-star-triple-nested-catch-finally-outer-",
        "patched-stream-yield-star-triple-nested-catch-finally-cleanup-",
    ],
    3,
    3,
    min_try_catch=2,
    min_try_finally=4,
    min_awaits=8,
)
assert_stream_chain(
    "asyncGeneratedYieldStarTripleNestedFinallyAwaitCleanup",
    ["first", "second", "third", "cleanup"],
    [
        "patched-stream-yield-star-triple-nested-finally-inner-cleanup-",
        "patched-stream-yield-star-triple-nested-finally-outer-cleanup-",
    ],
    3,
    3,
    min_try_catch=0,
    min_try_finally=5,
    min_awaits=8,
)
assert_stream_chain(
    "asyncGeneratedAwaitForNestedBreakContinueCatchFinallyAwaitRecovery",
    ["outer", "inner", "recovery", "cleanup"],
    [
        "patched-stream-await-for-nested-break-continue-catch-finally-await-body-",
        "patched-stream-await-for-nested-break-continue-catch-finally-await-caught-",
        "patched-stream-await-for-nested-break-continue-catch-finally-await-cleanup-",
        "skip",
        "stop",
    ],
    2,
    2,
    min_try_catch=1,
    min_try_finally=3,
    min_awaits=6,
)
assert_stream_chain(
    "asyncGeneratedAwaitForTripleNestedFinallyAwaitCleanup",
    ["outer", "middle", "inner", "cleanup"],
    [
        "patched-stream-await-for-triple-nested-finally-await-body-",
        "patched-stream-await-for-triple-nested-finally-await-cleanup-",
        "skip",
        "stop-middle",
    ],
    3,
    3,
    min_try_catch=0,
    min_try_finally=4,
    min_awaits=7,
    min_conditionals=1,
)
assert_stream_chain(
    "asyncGeneratedAwaitForSequentialCatchFinallyAwaitRecovery",
    ["first", "second", "recovery", "cleanup"],
    [
        "patched-stream-await-for-sequential-catch-finally-first-",
        "patched-stream-await-for-sequential-catch-finally-second-",
        "patched-stream-await-for-sequential-catch-finally-caught-",
        "patched-stream-await-for-sequential-catch-finally-cleanup-",
    ],
    2,
    2,
    min_try_catch=1,
    min_try_finally=2,
    min_awaits=5,
)
assert_stream_chain(
    "asyncGeneratedAwaitForSequentialBreakContinueFinallyAwaitCleanup",
    ["first", "second", "cleanup"],
    [
        "patched-stream-await-for-sequential-break-continue-first-",
        "patched-stream-await-for-sequential-break-continue-second-",
        "patched-stream-await-for-sequential-break-continue-cleanup-",
        "skip-first",
        "stop-second",
    ],
    2,
    2,
    min_try_catch=0,
    min_try_finally=2,
    min_awaits=5,
    min_conditionals=1,
)
assert_stream_chain(
    "asyncGeneratedAwaitForNestedInnerCatchOuterFinallyAwaitRecovery",
    ["outer", "inner", "recovery", "cleanup"],
    [
        "patched-stream-await-for-nested-inner-catch-outer-finally-body-",
        "patched-stream-await-for-nested-inner-catch-outer-finally-inner-caught-",
        "patched-stream-await-for-nested-inner-catch-outer-finally-cleanup-",
        "stop-inner",
    ],
    2,
    2,
    min_try_catch=1,
    min_try_finally=3,
    min_awaits=6,
)
assert_stream_chain(
    "asyncGeneratedYieldStarThenAwaitForCatchFinallyAwaitRecovery",
    ["first", "second", "recovery", "cleanup"],
    [
        "patched-stream-yield-star-then-await-for-catch-finally-body-",
        "patched-stream-yield-star-then-await-for-catch-finally-caught-",
        "patched-stream-yield-star-then-await-for-catch-finally-cleanup-",
        "skip-second",
    ],
    2,
    2,
    min_try_catch=1,
    min_try_finally=3,
    min_awaits=6,
    min_conditionals=1,
)
assert_stream_chain(
    "asyncGeneratedAwaitForThenYieldStarFinallyAwaitCleanup",
    ["first", "second", "cleanup"],
    [
        "patched-stream-await-for-then-yield-star-finally-body-",
        "patched-stream-await-for-then-yield-star-finally-cleanup-",
        "skip-first",
    ],
    2,
    2,
    min_try_catch=0,
    min_try_finally=3,
    min_awaits=4,
    min_conditionals=1,
)
assert_stream_chain(
    "asyncGeneratedYieldStarAwaitForNestedCatchFinallyAwaitRecovery",
    ["first", "middle", "inner", "recovery", "cleanup"],
    [
        "patched-stream-yield-star-await-for-nested-catch-finally-body-",
        "patched-stream-yield-star-await-for-nested-catch-finally-caught-",
        "patched-stream-yield-star-await-for-nested-catch-finally-cleanup-",
        "skip-middle",
        "stop-inner",
    ],
    3,
    3,
    min_try_catch=1,
    min_try_finally=4,
    min_awaits=8,
)
assert_stream_chain(
    "asyncGeneratedAwaitForSequentialNestedCatchFinallyAwaitRecovery",
    ["first", "middle", "inner", "recovery", "cleanup"],
    [
        "patched-stream-await-for-sequential-nested-catch-finally-first-",
        "patched-stream-await-for-sequential-nested-catch-finally-inner-",
        "patched-stream-await-for-sequential-nested-catch-finally-caught-",
        "patched-stream-await-for-sequential-nested-catch-finally-cleanup-",
        "skip-first-deep",
        "stop-middle-deep",
    ],
    3,
    3,
    min_try_catch=1,
    min_try_finally=4,
    min_awaits=8,
)
assert_stream_chain(
    "asyncGeneratedAwaitForNestedThenYieldStarCatchFinallyAwaitRecovery",
    ["outer", "inner", "tail", "recovery", "cleanup"],
    [
        "patched-stream-await-for-nested-then-yield-star-body-",
        "patched-stream-await-for-nested-then-yield-star-caught-",
        "patched-stream-await-for-nested-then-yield-star-cleanup-",
        "stop-nested-tail",
    ],
    3,
    3,
    min_try_catch=1,
    min_try_finally=4,
    min_awaits=8,
)
assert_stream_chain(
    "asyncGeneratedYieldStarThenAwaitForThenYieldStarCatchFinallyAwaitRecovery",
    ["first", "middle", "last", "recovery", "cleanup"],
    [
        "patched-stream-yield-star-await-for-yield-star-middle-",
        "patched-stream-yield-star-await-for-yield-star-caught-",
        "patched-stream-yield-star-await-for-yield-star-cleanup-",
        "skip-middle-deep",
    ],
    3,
    3,
    min_try_catch=1,
    min_try_finally=4,
    min_awaits=8,
)
assert_stream_chain(
    "asyncGeneratedYieldStarNestedAwaitForThenYieldStarCatchFinallyAwaitRecovery",
    ["first", "outer", "inner", "last", "recovery", "cleanup"],
    [
        "patched-stream-yield-star-nested-await-for-yield-star-body-",
        "patched-stream-yield-star-nested-await-for-yield-star-caught-",
        "patched-stream-yield-star-nested-await-for-yield-star-cleanup-",
        "skip-outer-deep",
        "stop-inner-deep",
    ],
    4,
    4,
    min_try_catch=1,
    min_try_finally=5,
    min_awaits=10,
)
assert_stream_chain(
    "asyncGeneratedAwaitForFinallyAwaitForCleanup",
    ["body", "cleanupStream"],
    [
        "patched-stream-await-for-finally-await-for-body-",
        "patched-stream-await-for-finally-await-for-cleanup-",
        "skip-body-finally",
    ],
    2,
    2,
    min_try_catch=0,
    min_try_finally=3,
    min_awaits=4,
    min_conditionals=1,
)
assert_stream_chain(
    "asyncGeneratedYieldStarFinallyYieldStarCleanup",
    ["body", "cleanupStream"],
    [
        "patched-stream-yield-star-finally-yield-star-head",
        "patched-stream-yield-star-finally-yield-star-cleanup-head",
    ],
    2,
    2,
    min_try_catch=0,
    min_try_finally=3,
    min_awaits=4,
)
assert_stream_chain(
    "asyncGeneratedAwaitForCatchFinallyAwaitForCleanup",
    ["body", "cleanupStream", "recovery"],
    [
        "patched-stream-await-for-catch-finally-await-for-body-",
        "patched-stream-await-for-catch-finally-await-for-caught-",
        "patched-stream-await-for-catch-finally-await-for-cleanup-",
        "stop-body-finally",
    ],
    2,
    2,
    min_try_catch=1,
    min_try_finally=3,
    min_awaits=5,
)
assert_stream_chain(
    "asyncGeneratedYieldStarAwaitForFinallyYieldStarCleanup",
    ["first", "middle", "cleanupStream"],
    [
        "patched-stream-yield-star-await-for-finally-yield-star-middle-",
        "skip-middle-finally",
    ],
    3,
    3,
    min_try_catch=0,
    min_try_finally=4,
    min_awaits=6,
    min_conditionals=1,
)
assert_stream_chain(
    "asyncGeneratedAwaitForYieldStarFinallyAwaitForCleanup",
    ["first", "delegated", "cleanupStream", "recovery"],
    [
        "patched-stream-await-for-yield-star-finally-body-",
        "patched-stream-await-for-yield-star-finally-caught-",
        "patched-stream-await-for-yield-star-finally-cleanup-",
        "skip-await-for-yield-star-finally",
        "stop-await-for-yield-star-finally-cleanup",
    ],
    3,
    3,
    min_try_catch=1,
    min_try_finally=4,
    min_awaits=7,
    min_conditionals=1,
)
assert_stream_chain(
    "asyncGeneratedYieldStarFinallyAwaitForYieldStarCleanup",
    ["body", "cleanupHead", "cleanupTail", "cleanup"],
    [
        "patched-stream-yield-star-finally-await-for-yield-star-head",
        "patched-stream-yield-star-finally-await-for-yield-star-cleanup-",
        "patched-stream-yield-star-finally-await-for-yield-star-middle-",
        "skip-yield-star-finally-await-for-yield-star-cleanup",
    ],
    3,
    3,
    min_try_catch=0,
    min_try_finally=4,
    min_awaits=7,
    min_conditionals=1,
)
