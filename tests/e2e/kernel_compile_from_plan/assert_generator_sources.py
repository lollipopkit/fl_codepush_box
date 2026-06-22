import json
import sys
from assert_generator_for_in_sources import assert_generator_for_in_sources

patch = json.load(open(sys.argv[1]))
patch_by_member = {f.get("member_name"): f for f in patch["functions"]}

def assert_stream_error_cleanup_source(name, args, constants, min_move_next, min_cancel, has_finally):
    source = patch_by_member.get(name, {}).get("bytecode_source", {})
    source_json = json.dumps(source)
    if (
        source.get("async_kind") != "async_star"
        or '"try_catch"' not in source_json
        or source_json.count('"method": "moveNext"') < min_move_next
        or source_json.count('"method": "cancel"') < min_cancel
        or any(f'"arg": "{arg}"' not in source_json for arg in args)
        or any(f'"string": "{constant}"' not in source_json for constant in constants)
        or (has_finally and '"try_finally"' not in source_json)
    ):
        raise SystemExit(f"expected {name} stream error/cleanup source, got {source}")

def assert_finite_stream_error_cleanup_source(name, args, constants, min_yield_for_in, min_awaits):
    source = patch_by_member.get(name, {}).get("bytecode_source", {})
    source_json = json.dumps(source)
    if (
        source.get("async_kind") != "async_star"
        or '"try_catch"' not in source_json
        or '"try_finally"' not in source_json
        or source_json.count('"yield_for_in"') < min_yield_for_in
        or source_json.count('"await"') < min_awaits
        or any(f'"arg": "{arg}"' not in source_json for arg in args)
        or any(f'"string": "{constant}"' not in source_json for constant in constants)
    ):
        raise SystemExit(f"expected {name} finite stream error/cleanup source, got {source}")

assert_generator_for_in_sources(patch_by_member)

sync_generated_yield_star = patch_by_member.get("syncGeneratedYieldStar", {}).get("bytecode_source", {})
yield_star_items = sync_generated_yield_star.get("body", {}).get("seq", [])
if (
    sync_generated_yield_star.get("async_kind") != "sync_star"
    or len(yield_star_items) != 2
    or yield_star_items[0].get("yield", {}).get("string") != "patched-yield-star-a"
    or yield_star_items[1].get("yield", {}).get("string") != "patched-yield-star-b"
):
    raise SystemExit(f"expected syncGeneratedYieldStar static yield* source, got {sync_generated_yield_star}")
sync_generated_yield_star_dynamic = patch_by_member.get("syncGeneratedYieldStarDynamic", {}).get("bytecode_source", {})
dynamic_yield_star_seq = sync_generated_yield_star_dynamic.get("body", {}).get("seq", [])
dynamic_yield_star_for = dynamic_yield_star_seq[0].get("yield_for_in", {}) if dynamic_yield_star_seq else {}
if (
    sync_generated_yield_star_dynamic.get("async_kind") != "sync_star"
    or len(dynamic_yield_star_seq) != 2
    or dynamic_yield_star_for.get("source", {}).get("arg") != "extra"
    or dynamic_yield_star_seq[1].get("yield", {}).get("string") != "patched-yield-star-dynamic-tail"
):
    raise SystemExit(f"expected syncGeneratedYieldStarDynamic dynamic yield* source, got {sync_generated_yield_star_dynamic}")
async_generated_yield_star = patch_by_member.get("asyncGeneratedYieldStar", {}).get("bytecode_source", {})
async_yield_star_items = async_generated_yield_star.get("body", {}).get("seq", [])
if (
    async_generated_yield_star.get("async_kind") != "async_star"
    or len(async_yield_star_items) != 2
    or async_yield_star_items[0].get("yield", {}).get("string") != "patched-stream-yield-star-a"
    or async_yield_star_items[1].get("yield", {}).get("string") != "patched-stream-yield-star-b"
):
    raise SystemExit(f"expected asyncGeneratedYieldStar static yield* source, got {async_generated_yield_star}")
async_generated_yield_star_dynamic = patch_by_member.get("asyncGeneratedYieldStarDynamic", {}).get("bytecode_source", {})
async_dynamic_yield_star_seq = async_generated_yield_star_dynamic.get("body", {}).get("seq", [])
async_dynamic_yield_star_for = async_dynamic_yield_star_seq[0].get("yield_for_in", {}) if async_dynamic_yield_star_seq else {}
if (
    async_generated_yield_star_dynamic.get("async_kind") != "async_star"
    or len(async_dynamic_yield_star_seq) != 2
    or async_dynamic_yield_star_for.get("source", {}).get("arg") != "extra"
    or async_dynamic_yield_star_seq[1].get("yield", {}).get("string") != "patched-stream-yield-star-dynamic-tail"
):
    raise SystemExit(f"expected asyncGeneratedYieldStarDynamic Stream.fromIterable yield* source, got {async_generated_yield_star_dynamic}")

def assert_generator_switch_or_source(name, async_kind, expected_constants):
    source = patch_by_member.get(name, {}).get("bytecode_source", {})
    source_json = json.dumps(source)
    if (
        source.get("async_kind") != async_kind
        or source_json.count('"conditional"') < 4
        or source_json.count('"yield"') < 1
        or '"arg": "tier"' not in source_json
        or '"string": "gold"' not in source_json
        or '"string": "vip"' not in source_json
        or '"string": "trial"' not in source_json
        or '"string": "guest"' not in source_json
        or any(f'"string": "{constant}"' not in source_json for constant in expected_constants)
    ):
        raise SystemExit(f"expected {name} generator switch-or source, got {source}")

assert_generator_switch_or_source(
    "syncGeneratedSwitchOrPatternExpr",
    "sync_star",
    [
        "patched-iterable-switch-or-premium",
        "patched-iterable-switch-or-limited",
        "patched-iterable-switch-or-other",
    ],
)
assert_generator_switch_or_source(
    "syncGeneratedSwitchOrPatternStatement",
    "sync_star",
    [
        "patched-iterable-switch-stmt-or-premium",
        "patched-iterable-switch-stmt-or-limited",
        "patched-iterable-switch-stmt-or-other",
    ],
)
assert_generator_switch_or_source(
    "asyncGeneratedSwitchOrPatternExpr",
    "async_star",
    [
        "patched-stream-switch-or-premium",
        "patched-stream-switch-or-limited",
        "patched-stream-switch-or-other",
    ],
)
assert_generator_switch_or_source(
    "asyncGeneratedSwitchOrPatternStatement",
    "async_star",
    [
        "patched-stream-switch-stmt-or-premium",
        "patched-stream-switch-stmt-or-limited",
        "patched-stream-switch-stmt-or-other",
    ],
)

def assert_generator_loop_switch_or_source(name, async_kind, expected_constants):
    source = patch_by_member.get(name, {}).get("bytecode_source", {})
    source_json = json.dumps(source)
    if (
        source.get("async_kind") != async_kind
        or '"while_loop"' not in source_json
        or source_json.count('"conditional"') < 2
        or source_json.count('"yield"') < 2
        or '"int": 0' not in source_json
        or '"int": 1' not in source_json
        or '"set_local"' not in source_json
        or any(f'"string": "{constant}"' not in source_json for constant in expected_constants)
    ):
        raise SystemExit(f"expected {name} generator loop switch-or source, got {source}")

def assert_generator_await_for_switch_or_source(name, expected_constants, args, min_move_next):
    source = patch_by_member.get(name, {}).get("bytecode_source", {})
    source_json = json.dumps(source)
    if (
        source.get("async_kind") != "async_star"
        or source_json.count('"method": "moveNext"') < min_move_next
        or source_json.count('"method": "cancel"') < min_move_next
        or source_json.count('"conditional"') < 2
        or source_json.count('"yield"') < 2
        or '"string": "gold"' not in source_json
        or '"string": "vip"' not in source_json
        or any(f'"arg": "{arg}"' not in source_json for arg in args)
        or any(f'"string": "{constant}"' not in source_json for constant in expected_constants)
    ):
        raise SystemExit(f"expected {name} generator await-for switch-or source, got {source}")

assert_generator_loop_switch_or_source(
    "syncGeneratedWhileSwitchOrPatternStatement",
    "sync_star",
    [
        "patched-iterable-while-switch-or-premium-",
        "patched-iterable-while-switch-or-other-",
    ],
)
assert_generator_loop_switch_or_source(
    "syncGeneratedForSwitchOrPatternStatement",
    "sync_star",
    [
        "patched-iterable-for-switch-or-premium-",
        "patched-iterable-for-switch-or-other-",
    ],
)
assert_generator_loop_switch_or_source(
    "asyncGeneratedWhileSwitchOrPatternStatement",
    "async_star",
    [
        "patched-stream-while-switch-or-premium-",
        "patched-stream-while-switch-or-other-",
    ],
)
assert_generator_loop_switch_or_source(
    "asyncGeneratedForSwitchOrPatternStatement",
    "async_star",
    [
        "patched-stream-for-switch-or-premium-",
        "patched-stream-for-switch-or-other-",
    ],
)
assert_generator_await_for_switch_or_source(
    "asyncGeneratedAwaitForSwitchOrPatternStatement",
    [
        "patched-stream-await-for-switch-or-premium-",
        "patched-stream-await-for-switch-or-other-",
    ],
    ["extra"],
    1,
)
assert_generator_await_for_switch_or_source(
    "asyncGeneratedNestedAwaitForSwitchOrPatternStatement",
    [
        "patched-stream-nested-await-for-switch-or-premium-",
        "patched-stream-nested-await-for-switch-or-other-",
    ],
    ["outer", "inner"],
    2,
)

def assert_generator_await_for_switch_or_error_cleanup_source(
    name,
    expected_constants,
    args,
    min_move_next,
    has_catch,
    guard_constants=(),
):
    source = patch_by_member.get(name, {}).get("bytecode_source", {})
    source_json = json.dumps(source)
    if (
        source.get("async_kind") != "async_star"
        or source_json.count('"method": "moveNext"') < min_move_next
        or source_json.count('"method": "cancel"') < min_move_next
        or '"try_finally"' not in source_json
        or (has_catch and '"try_catch"' not in source_json)
        or source_json.count('"conditional"') < 2
        or source_json.count('"yield"') < 3
        or '"string": "gold"' not in source_json
        or '"string": "vip"' not in source_json
        or any(f'"arg": "{arg}"' not in source_json for arg in args)
        or any(f'"string": "{constant}"' not in source_json for constant in expected_constants)
        or any(f'"string": "{constant}"' not in source_json for constant in guard_constants)
    ):
        raise SystemExit(
            f"expected {name} generator await-for switch-or error/cleanup source, got {source}"
        )

assert_generator_await_for_switch_or_error_cleanup_source(
    "asyncGeneratedAwaitForSwitchOrPatternCatchFinally",
    [
        "patched-stream-await-for-switch-or-catch-premium-",
        "patched-stream-await-for-switch-or-catch-other-",
        "patched-stream-await-for-switch-or-caught-",
        "patched-stream-await-for-switch-or-cleanup",
    ],
    ["extra"],
    1,
    True,
)
assert_generator_await_for_switch_or_error_cleanup_source(
    "asyncGeneratedAwaitForSwitchOrPatternBreakContinueFinally",
    [
        "patched-stream-await-for-switch-or-break-continue-premium-",
        "patched-stream-await-for-switch-or-break-continue-other-",
        "patched-stream-await-for-switch-or-break-continue-cleanup",
    ],
    ["extra"],
    1,
    False,
    ["skip", "stop"],
)
assert_generator_await_for_switch_or_error_cleanup_source(
    "asyncGeneratedNestedAwaitForSwitchOrPatternCatchFinally",
    [
        "patched-stream-nested-await-for-switch-or-catch-premium-",
        "patched-stream-nested-await-for-switch-or-catch-other-",
        "patched-stream-nested-await-for-switch-or-caught-",
        "patched-stream-nested-await-for-switch-or-cleanup",
    ],
    ["outer", "inner"],
    2,
    True,
)
assert_generator_await_for_switch_or_error_cleanup_source(
    "asyncGeneratedNestedAwaitForSwitchOrPatternBreakContinueFinally",
    [
        "patched-stream-nested-await-for-switch-or-break-continue-premium-",
        "patched-stream-nested-await-for-switch-or-break-continue-other-",
        "patched-stream-nested-await-for-switch-or-break-continue-cleanup",
    ],
    ["outer", "inner"],
    2,
    False,
    ["skip", "stop"],
)
async_generated_yield_star_stream = patch_by_member.get("asyncGeneratedYieldStarStream", {}).get("bytecode_source", {})
async_yield_star_stream_let = async_generated_yield_star_stream.get("body", {}).get("let", {})
async_yield_star_stream_locals = async_yield_star_stream_let.get("locals", [])
async_yield_star_stream_try = async_yield_star_stream_let.get("body", {}).get("try_finally", {})
async_yield_star_stream_loop = async_yield_star_stream_try.get("body", {}).get("while_loop", {})
async_yield_star_stream_condition = async_yield_star_stream_loop.get("condition", {}).get("await", {}).get("call_dynamic", {})
async_yield_star_stream_body = async_yield_star_stream_loop.get("body", {}).get("seq", [])
async_yield_star_stream_finally = async_yield_star_stream_try.get("finally", {}).get("await", {}).get("call_dynamic", {})
if (
    async_generated_yield_star_stream.get("async_kind") != "async_star"
    or len(async_yield_star_stream_locals) != 3
    or async_yield_star_stream_locals[0].get("value", {}).get("arg") != "extra"
    or async_yield_star_stream_locals[1].get("value", {}).get("new_object", {}).get("constructor") != "dart:async::class:_StreamIterator."
    or async_yield_star_stream_condition.get("method") != "moveNext"
    or len(async_yield_star_stream_body) != 2
    or async_yield_star_stream_body[0].get("set_local", {}).get("id") != 2
    or async_yield_star_stream_body[1].get("yield", {}).get("let_local") != 2
    or async_yield_star_stream_finally.get("method") != "cancel"
):
    raise SystemExit(f"expected asyncGeneratedYieldStarStream generic Stream yield* source, got {async_generated_yield_star_stream}")
async_generated_yield_star_stream_finally = patch_by_member.get("asyncGeneratedYieldStarStreamFinally", {}).get("bytecode_source", {})
async_yield_star_stream_outer_finally = async_generated_yield_star_stream_finally.get("body", {}).get("try_finally", {})
async_yield_star_stream_finally_let = async_yield_star_stream_outer_finally.get("body", {}).get("let", {})
async_yield_star_stream_finally_inner = async_yield_star_stream_finally_let.get("body", {}).get("try_finally", {})
async_yield_star_stream_finally_loop = async_yield_star_stream_finally_inner.get("body", {}).get("while_loop", {})
async_yield_star_stream_finally_cleanup = async_yield_star_stream_outer_finally.get("finally", {}).get("yield", {})
if (
    async_generated_yield_star_stream_finally.get("async_kind") != "async_star"
    or async_yield_star_stream_finally_let.get("locals", [{}])[0].get("value", {}).get("arg") != "extra"
    or async_yield_star_stream_finally_loop.get("condition", {}).get("await", {}).get("call_dynamic", {}).get("method") != "moveNext"
    or async_yield_star_stream_finally_inner.get("finally", {}).get("await", {}).get("call_dynamic", {}).get("method") != "cancel"
    or async_yield_star_stream_finally_cleanup.get("string") != "patched-stream-yield-star-stream-finally-cleanup"
):
    raise SystemExit(f"expected asyncGeneratedYieldStarStreamFinally generic Stream yield* try/finally source, got {async_generated_yield_star_stream_finally}")
async_generated_yield_star_stream_sandwich = patch_by_member.get(
    "asyncGeneratedYieldStarStreamSandwichFinally", {}
).get("bytecode_source", {})
async_yield_star_stream_sandwich_outer = async_generated_yield_star_stream_sandwich.get("body", {}).get("try_finally", {})
async_yield_star_stream_sandwich_seq = async_yield_star_stream_sandwich_outer.get("body", {}).get("seq", [])
async_yield_star_stream_sandwich_let = (
    async_yield_star_stream_sandwich_seq[1].get("let", {})
    if len(async_yield_star_stream_sandwich_seq) > 1
    else {}
)
async_yield_star_stream_sandwich_inner = async_yield_star_stream_sandwich_let.get("body", {}).get("try_finally", {})
async_yield_star_stream_sandwich_loop = async_yield_star_stream_sandwich_inner.get("body", {}).get("while_loop", {})
async_yield_star_stream_sandwich_cleanup = async_yield_star_stream_sandwich_outer.get("finally", {}).get("yield", {})
if (
    async_generated_yield_star_stream_sandwich.get("async_kind") != "async_star"
    or len(async_yield_star_stream_sandwich_seq) != 3
    or async_yield_star_stream_sandwich_seq[0].get("yield", {}).get("string") != "patched-stream-yield-star-stream-before"
    or async_yield_star_stream_sandwich_let.get("locals", [{}])[0].get("value", {}).get("arg") != "extra"
    or async_yield_star_stream_sandwich_loop.get("condition", {}).get("await", {}).get("call_dynamic", {}).get("method") != "moveNext"
    or async_yield_star_stream_sandwich_inner.get("finally", {}).get("await", {}).get("call_dynamic", {}).get("method") != "cancel"
    or async_yield_star_stream_sandwich_seq[2].get("yield", {}).get("string") != "patched-stream-yield-star-stream-after"
    or async_yield_star_stream_sandwich_cleanup.get("string") != "patched-stream-yield-star-stream-sandwich-cleanup"
):
    raise SystemExit(
        "expected asyncGeneratedYieldStarStreamSandwichFinally generic Stream "
        f"yield* sandwich try/finally source, got {async_generated_yield_star_stream_sandwich}"
    )
async_generated_yield_star_two_streams = patch_by_member.get(
    "asyncGeneratedYieldStarTwoStreamsFinally", {}
).get("bytecode_source", {})
async_yield_star_two_outer = async_generated_yield_star_two_streams.get("body", {}).get("try_finally", {})
async_yield_star_two_seq = async_yield_star_two_outer.get("body", {}).get("seq", [])
async_yield_star_two_first = async_yield_star_two_seq[0].get("let", {}) if async_yield_star_two_seq else {}
async_yield_star_two_second = async_yield_star_two_seq[1].get("let", {}) if len(async_yield_star_two_seq) > 1 else {}
async_yield_star_two_first_try = async_yield_star_two_first.get("body", {}).get("try_finally", {})
async_yield_star_two_second_try = async_yield_star_two_second.get("body", {}).get("try_finally", {})
if (
    async_generated_yield_star_two_streams.get("async_kind") != "async_star"
    or len(async_yield_star_two_seq) != 2
    or async_yield_star_two_first.get("locals", [{}])[0].get("value", {}).get("arg") != "first"
    or async_yield_star_two_second.get("locals", [{}])[0].get("value", {}).get("arg") != "second"
    or async_yield_star_two_first_try.get("body", {}).get("while_loop", {}).get("condition", {}).get("await", {}).get("call_dynamic", {}).get("method") != "moveNext"
    or async_yield_star_two_second_try.get("body", {}).get("while_loop", {}).get("condition", {}).get("await", {}).get("call_dynamic", {}).get("method") != "moveNext"
    or async_yield_star_two_first_try.get("finally", {}).get("await", {}).get("call_dynamic", {}).get("method") != "cancel"
    or async_yield_star_two_second_try.get("finally", {}).get("await", {}).get("call_dynamic", {}).get("method") != "cancel"
    or async_yield_star_two_outer.get("finally", {}).get("yield", {}).get("string") != "patched-stream-yield-star-two-streams-cleanup"
):
    raise SystemExit(
        "expected asyncGeneratedYieldStarTwoStreamsFinally two generic Stream "
        f"yield* blocks under one try/finally, got {async_generated_yield_star_two_streams}"
    )
assert_stream_error_cleanup_source(
    "asyncGeneratedYieldStarStreamCatch",
    ["extra"],
    ["patched-stream-yield-star-stream-caught-"],
    1,
    1,
    False,
)
assert_stream_error_cleanup_source(
    "asyncGeneratedYieldStarStreamCatchFinally",
    ["extra"],
    [
        "patched-stream-yield-star-stream-catch-finally-caught-",
        "patched-stream-yield-star-stream-catch-finally-cleanup",
    ],
    1,
    1,
    True,
)
assert_stream_error_cleanup_source(
    "asyncGeneratedYieldStarTwoStreamsCatchFinally",
    ["first", "second"],
    [
        "patched-stream-yield-star-two-streams-caught-",
        "patched-stream-yield-star-two-streams-catch-finally-cleanup",
    ],
    2,
    2,
    True,
)
assert_stream_error_cleanup_source(
    "asyncGeneratedYieldStarStreamSandwichCatchFinally",
    ["extra"],
    [
        "patched-stream-yield-star-stream-sandwich-catch-before",
        "patched-stream-yield-star-stream-sandwich-catch-after",
        "patched-stream-yield-star-stream-sandwich-caught-",
        "patched-stream-yield-star-stream-sandwich-catch-cleanup",
    ],
    1,
    1,
    True,
)
assert_stream_error_cleanup_source(
    "asyncGeneratedYieldStarTwoStreamsSandwichCatchFinally",
    ["first", "second"],
    [
        "patched-stream-yield-star-two-streams-sandwich-before",
        "patched-stream-yield-star-two-streams-sandwich-middle",
        "patched-stream-yield-star-two-streams-sandwich-after",
        "patched-stream-yield-star-two-streams-sandwich-caught-",
        "patched-stream-yield-star-two-streams-sandwich-cleanup",
    ],
    2,
    2,
    True,
)
assert_stream_error_cleanup_source(
    "asyncGeneratedYieldStarTripleStreamsCatchFinally",
    ["first", "second", "third"],
    [
        "patched-stream-yield-star-triple-streams-caught-",
        "patched-stream-yield-star-triple-streams-cleanup",
    ],
    3,
    3,
    True,
)
assert_finite_stream_error_cleanup_source(
    "asyncGeneratedYieldStarDynamicCatchFinally",
    ["extra"],
    [
        "patched-stream-yield-star-dynamic-caught-",
        "patched-stream-yield-star-dynamic-catch-cleanup",
    ],
    1,
    0,
)
assert_finite_stream_error_cleanup_source(
    "asyncGeneratedYieldStarFromFutureCatchFinally",
    ["value"],
    [
        "patched-stream-yield-star-future-catch-",
        "patched-stream-yield-star-future-caught-",
        "patched-stream-yield-star-future-catch-cleanup",
    ],
    0,
    0,
)
assert_finite_stream_error_cleanup_source(
    "asyncGeneratedYieldStarPendingFutureCatchFinally",
    ["ready"],
    [
        "patched-stream-yield-star-pending-caught-",
        "patched-stream-yield-star-pending-catch-cleanup",
    ],
    0,
    1,
)
assert_finite_stream_error_cleanup_source(
    "asyncGeneratedYieldStarValueCatchFinally",
    ["value"],
    [
        "patched-stream-yield-star-value-catch-",
        "patched-stream-yield-star-value-caught-",
        "patched-stream-yield-star-value-catch-cleanup",
    ],
    0,
    0,
)
assert_finite_stream_error_cleanup_source(
    "asyncGeneratedYieldStarEmptyCatchFinally",
    [],
    [
        "patched-stream-yield-star-empty-caught-",
        "patched-stream-yield-star-empty-catch-cleanup",
    ],
    0,
    0,
)
async_generated_yield_star_value = patch_by_member.get("asyncGeneratedYieldStarValue", {}).get("bytecode_source", {})
async_yield_star_value = async_generated_yield_star_value.get("body", {}).get("yield", {}).get("concat", [])
if (
    async_generated_yield_star_value.get("async_kind") != "async_star"
    or len(async_yield_star_value) != 2
    or async_yield_star_value[0].get("string") != "patched-stream-yield-star-value-"
    or async_yield_star_value[1].get("arg") != "value"
):
    raise SystemExit(f"expected asyncGeneratedYieldStarValue Stream.value yield* source, got {async_generated_yield_star_value}")
async_generated_yield_star_future = patch_by_member.get("asyncGeneratedYieldStarFromFuture", {}).get("bytecode_source", {})
async_yield_star_future = async_generated_yield_star_future.get("body", {}).get("yield", {}).get("concat", [])
if (
    async_generated_yield_star_future.get("async_kind") != "async_star"
    or len(async_yield_star_future) != 2
    or async_yield_star_future[0].get("string") != "patched-stream-yield-star-future-"
    or async_yield_star_future[1].get("arg") != "value"
):
    raise SystemExit(f"expected asyncGeneratedYieldStarFromFuture Stream.fromFuture(Future.value) yield* source, got {async_generated_yield_star_future}")
async_generated_yield_star_pending = patch_by_member.get("asyncGeneratedYieldStarPendingFuture", {}).get("bytecode_source", {})
async_yield_star_pending = async_generated_yield_star_pending.get("body", {}).get("yield", {}).get("await", {})
if (
    async_generated_yield_star_pending.get("async_kind") != "async_star"
    or async_yield_star_pending.get("arg") != "ready"
):
    raise SystemExit(f"expected asyncGeneratedYieldStarPendingFuture Stream.fromFuture pending yield* source, got {async_generated_yield_star_pending}")
async_generated_yield_star_empty = patch_by_member.get("asyncGeneratedYieldStarEmpty", {}).get("bytecode_source", {})
if (
    async_generated_yield_star_empty.get("async_kind") != "async_star"
    or async_generated_yield_star_empty.get("body", {}).get("null") is not True
):
    raise SystemExit(f"expected asyncGeneratedYieldStarEmpty Stream.empty yield* source, got {async_generated_yield_star_empty}")
async_generated_await_for_iterable = patch_by_member.get("asyncGeneratedAwaitForFromIterable", {}).get("bytecode_source", {})
async_await_for_iterable = async_generated_await_for_iterable.get("body", {}).get("yield_for_in", {})
async_await_for_iterable_body = async_await_for_iterable.get("body", {}).get("yield", {}).get("concat", [])
if (
    async_generated_await_for_iterable.get("async_kind") != "async_star"
    or async_await_for_iterable.get("source", {}).get("arg") != "extra"
    or async_await_for_iterable.get("local", {}).get("name") != "value"
    or len(async_await_for_iterable_body) != 2
    or async_await_for_iterable_body[0].get("string") != "patched-stream-await-for-iterable-"
    or async_await_for_iterable_body[1].get("let_local") != 0
):
    raise SystemExit(f"expected asyncGeneratedAwaitForFromIterable lowered await-for source, got {async_generated_await_for_iterable}")
async_generated_await_for_continue = patch_by_member.get("asyncGeneratedAwaitForContinue", {}).get("bytecode_source", {})
async_await_for_continue = async_generated_await_for_continue.get("body", {}).get("yield_for_in", {})
async_await_for_continue_body = async_await_for_continue.get("body", {}).get("conditional", {})
async_await_for_continue_else = async_await_for_continue_body.get("else", {}).get("yield", {}).get("concat", [])
if (
    async_generated_await_for_continue.get("async_kind") != "async_star"
    or async_await_for_continue.get("source", {}).get("arg") != "extra"
    or async_await_for_continue.get("local", {}).get("name") != "value"
    or async_await_for_continue_body.get("condition", {}).get("op") != "=="
    or async_await_for_continue_body.get("then", {}).get("null") is not True
    or len(async_await_for_continue_else) != 2
    or async_await_for_continue_else[0].get("string") != "patched-stream-await-for-continue-"
    or async_await_for_continue_else[1].get("let_local") != 0
):
    raise SystemExit(f"expected asyncGeneratedAwaitForContinue guarded continue await-for source, got {async_generated_await_for_continue}")
async_generated_await_for_break = patch_by_member.get("asyncGeneratedAwaitForBreak", {}).get("bytecode_source", {})
async_await_for_break = async_generated_await_for_break.get("body", {}).get("yield_for_in", {})
async_await_for_break_body = async_await_for_break.get("body", {}).get("yield", {}).get("concat", [])
if (
    async_generated_await_for_break.get("async_kind") != "async_star"
    or async_await_for_break.get("source", {}).get("arg") != "extra"
    or async_await_for_break.get("local", {}).get("name") != "value"
    or async_await_for_break.get("break_condition", {}).get("op") != "=="
    or len(async_await_for_break_body) != 2
    or async_await_for_break_body[0].get("string") != "patched-stream-await-for-break-"
    or async_await_for_break_body[1].get("let_local") != 0
):
    raise SystemExit(f"expected asyncGeneratedAwaitForBreak guarded break await-for source, got {async_generated_await_for_break}")
async_generated_await_for_value = patch_by_member.get("asyncGeneratedAwaitForValue", {}).get("bytecode_source", {})
async_await_for_value = async_generated_await_for_value.get("body", {}).get("yield_for_in", {})
async_await_for_value_items = async_await_for_value.get("source", {}).get("list", [])
async_await_for_value_body = async_await_for_value.get("body", {}).get("yield", {}).get("concat", [])
if (
    async_generated_await_for_value.get("async_kind") != "async_star"
    or len(async_await_for_value_items) != 1
    or async_await_for_value_items[0].get("arg") != "value"
    or async_await_for_value.get("local", {}).get("name") != "item"
    or len(async_await_for_value_body) != 2
    or async_await_for_value_body[0].get("string") != "patched-stream-await-for-value-"
    or async_await_for_value_body[1].get("let_local") != 0
):
    raise SystemExit(f"expected asyncGeneratedAwaitForValue Stream.value await-for source, got {async_generated_await_for_value}")
async_generated_await_for_future = patch_by_member.get("asyncGeneratedAwaitForFuture", {}).get("bytecode_source", {})
async_await_for_future = async_generated_await_for_future.get("body", {}).get("yield_for_in", {})
async_await_for_future_items = async_await_for_future.get("source", {}).get("list", [])
async_await_for_future_body = async_await_for_future.get("body", {}).get("yield", {}).get("concat", [])
if (
    async_generated_await_for_future.get("async_kind") != "async_star"
    or len(async_await_for_future_items) != 1
    or async_await_for_future_items[0].get("arg") != "value"
    or async_await_for_future.get("local", {}).get("name") != "item"
    or len(async_await_for_future_body) != 2
    or async_await_for_future_body[0].get("string") != "patched-stream-await-for-future-"
    or async_await_for_future_body[1].get("let_local") != 0
):
    raise SystemExit(f"expected asyncGeneratedAwaitForFuture Stream.fromFuture(Future.value) await-for source, got {async_generated_await_for_future}")
async_generated_await_for_future_break = patch_by_member.get("asyncGeneratedAwaitForFutureBreak", {}).get("bytecode_source", {})
async_await_for_future_break = async_generated_await_for_future_break.get("body", {}).get("yield_for_in", {})
async_await_for_future_break_items = async_await_for_future_break.get("source", {}).get("list", [])
async_await_for_future_break_body = async_await_for_future_break.get("body", {}).get("yield", {}).get("concat", [])
if (
    async_generated_await_for_future_break.get("async_kind") != "async_star"
    or len(async_await_for_future_break_items) != 1
    or async_await_for_future_break_items[0].get("arg") != "value"
    or async_await_for_future_break.get("local", {}).get("name") != "item"
    or async_await_for_future_break.get("break_condition", {}).get("op") != "=="
    or len(async_await_for_future_break_body) != 2
    or async_await_for_future_break_body[0].get("string") != "patched-stream-await-for-future-break-"
    or async_await_for_future_break_body[1].get("let_local") != 0
):
    raise SystemExit(f"expected asyncGeneratedAwaitForFutureBreak Stream.fromFuture guarded break source, got {async_generated_await_for_future_break}")
async_generated_await_for_pending = patch_by_member.get("asyncGeneratedAwaitForPendingFuture", {}).get("bytecode_source", {})
async_await_for_pending = async_generated_await_for_pending.get("body", {}).get("yield_for_in", {})
async_await_for_pending_items = async_await_for_pending.get("source", {}).get("list", [])
async_await_for_pending_body = async_await_for_pending.get("body", {}).get("yield", {}).get("concat", [])
if (
    async_generated_await_for_pending.get("async_kind") != "async_star"
    or len(async_await_for_pending_items) != 1
    or async_await_for_pending_items[0].get("await", {}).get("arg") != "ready"
    or async_await_for_pending.get("local", {}).get("name") != "item"
    or len(async_await_for_pending_body) != 2
    or async_await_for_pending_body[0].get("string") != "patched-stream-await-for-pending-future-"
    or async_await_for_pending_body[1].get("let_local") != 0
):
    raise SystemExit(f"expected asyncGeneratedAwaitForPendingFuture Stream.fromFuture pending await-for source, got {async_generated_await_for_pending}")
async_generated_await_for_pending_continue = patch_by_member.get("asyncGeneratedAwaitForPendingContinue", {}).get("bytecode_source", {})
async_await_for_pending_continue = async_generated_await_for_pending_continue.get("body", {}).get("yield_for_in", {})
async_await_for_pending_continue_items = async_await_for_pending_continue.get("source", {}).get("list", [])
async_await_for_pending_continue_body = async_await_for_pending_continue.get("body", {}).get("conditional", {})
async_await_for_pending_continue_else = async_await_for_pending_continue_body.get("else", {}).get("yield", {}).get("concat", [])
if (
    async_generated_await_for_pending_continue.get("async_kind") != "async_star"
    or len(async_await_for_pending_continue_items) != 1
    or async_await_for_pending_continue_items[0].get("await", {}).get("arg") != "ready"
    or async_await_for_pending_continue.get("local", {}).get("name") != "item"
    or async_await_for_pending_continue_body.get("condition", {}).get("op") != "=="
    or async_await_for_pending_continue_body.get("then", {}).get("null") is not True
    or len(async_await_for_pending_continue_else) != 2
    or async_await_for_pending_continue_else[0].get("string") != "patched-stream-await-for-pending-continue-"
    or async_await_for_pending_continue_else[1].get("let_local") != 0
):
    raise SystemExit(f"expected asyncGeneratedAwaitForPendingContinue Stream.fromFuture pending guarded continue source, got {async_generated_await_for_pending_continue}")
async_generated_await_for_empty = patch_by_member.get("asyncGeneratedAwaitForEmpty", {}).get("bytecode_source", {})
async_await_for_empty = async_generated_await_for_empty.get("body", {}).get("yield_for_in", {})
async_await_for_empty_items = async_await_for_empty.get("source", {}).get("list", [])
async_await_for_empty_body = async_await_for_empty.get("body", {}).get("yield", {}).get("concat", [])
if (
    async_generated_await_for_empty.get("async_kind") != "async_star"
    or async_await_for_empty_items != []
    or async_await_for_empty.get("local", {}).get("name") != "item"
    or len(async_await_for_empty_body) != 2
    or async_await_for_empty_body[0].get("string") != "patched-stream-await-for-empty-"
    or async_await_for_empty_body[1].get("let_local") != 0
):
    raise SystemExit(f"expected asyncGeneratedAwaitForEmpty Stream.empty await-for source, got {async_generated_await_for_empty}")
async_generated_await_for_stream = patch_by_member.get("asyncGeneratedAwaitFor", {}).get("bytecode_source", {})
async_await_for_stream_let = async_generated_await_for_stream.get("body", {}).get("let", {})
async_await_for_stream_locals = async_await_for_stream_let.get("locals", [])
async_await_for_stream_try = async_await_for_stream_let.get("body", {}).get("try_finally", {})
async_await_for_stream_loop = async_await_for_stream_try.get("body", {}).get("while_loop", {})
async_await_for_stream_condition = async_await_for_stream_loop.get("condition", {}).get("await", {}).get("call_dynamic", {})
async_await_for_stream_body = async_await_for_stream_loop.get("body", {}).get("seq", [])
async_await_for_stream_finally = async_await_for_stream_try.get("finally", {}).get("await", {}).get("call_dynamic", {})
if (
    async_generated_await_for_stream.get("async_kind") != "async_star"
    or len(async_await_for_stream_locals) != 3
    or async_await_for_stream_locals[0].get("value", {}).get("arg") != "extra"
    or async_await_for_stream_locals[1].get("value", {}).get("new_object", {}).get("constructor") != "dart:async::class:_StreamIterator."
    or async_await_for_stream_condition.get("method") != "moveNext"
    or len(async_await_for_stream_body) != 2
    or async_await_for_stream_body[0].get("set_local", {}).get("id") != 2
    or async_await_for_stream_body[1].get("yield", {}).get("let_local") != 2
    or async_await_for_stream_finally.get("method") != "cancel"
):
    raise SystemExit(f"expected asyncGeneratedAwaitFor generic Stream await-for source, got {async_generated_await_for_stream}")
async_generated_await_for_finally = patch_by_member.get("asyncGeneratedAwaitForFinally", {}).get("bytecode_source", {})
async_await_for_finally_outer = async_generated_await_for_finally.get("body", {}).get("try_finally", {})
async_await_for_finally_let = async_await_for_finally_outer.get("body", {}).get("let", {})
async_await_for_finally_inner = async_await_for_finally_let.get("body", {}).get("try_finally", {})
async_await_for_finally_loop = async_await_for_finally_inner.get("body", {}).get("while_loop", {})
async_await_for_finally_cleanup = async_await_for_finally_outer.get("finally", {}).get("yield", {})
if (
    async_generated_await_for_finally.get("async_kind") != "async_star"
    or async_await_for_finally_let.get("locals", [{}])[0].get("value", {}).get("arg") != "extra"
    or async_await_for_finally_loop.get("condition", {}).get("await", {}).get("call_dynamic", {}).get("method") != "moveNext"
    or async_await_for_finally_inner.get("finally", {}).get("await", {}).get("call_dynamic", {}).get("method") != "cancel"
    or async_await_for_finally_cleanup.get("string") != "patched-stream-await-for-finally-cleanup"
):
    raise SystemExit(f"expected asyncGeneratedAwaitForFinally generic Stream await-for try/finally source, got {async_generated_await_for_finally}")
async_generated_await_for_stream_continue = patch_by_member.get("asyncGeneratedAwaitForStreamContinue", {}).get("bytecode_source", {})
async_await_for_stream_continue_let = async_generated_await_for_stream_continue.get("body", {}).get("let", {})
async_await_for_stream_continue_locals = async_await_for_stream_continue_let.get("locals", [])
async_await_for_stream_continue_try = async_await_for_stream_continue_let.get("body", {}).get("try_finally", {})
async_await_for_stream_continue_loop = async_await_for_stream_continue_try.get("body", {}).get("while_loop", {})
async_await_for_stream_continue_condition = async_await_for_stream_continue_loop.get("condition", {}).get("await", {}).get("call_dynamic", {})
async_await_for_stream_continue_body = async_await_for_stream_continue_loop.get("body", {}).get("seq", [])
async_await_for_stream_continue_guard = (
    async_await_for_stream_continue_body[1].get("conditional", {})
    if len(async_await_for_stream_continue_body) > 1
    else {}
)
async_await_for_stream_continue_else = async_await_for_stream_continue_guard.get("else", {}).get("yield", {}).get("concat", [])
async_await_for_stream_continue_finally = async_await_for_stream_continue_try.get("finally", {}).get("await", {}).get("call_dynamic", {})
if (
    async_generated_await_for_stream_continue.get("async_kind") != "async_star"
    or len(async_await_for_stream_continue_locals) != 3
    or async_await_for_stream_continue_locals[0].get("value", {}).get("arg") != "extra"
    or async_await_for_stream_continue_locals[1].get("value", {}).get("new_object", {}).get("constructor") != "dart:async::class:_StreamIterator."
    or async_await_for_stream_continue_condition.get("method") != "moveNext"
    or len(async_await_for_stream_continue_body) != 2
    or async_await_for_stream_continue_body[0].get("set_local", {}).get("id") != 2
    or async_await_for_stream_continue_guard.get("condition", {}).get("op") != "=="
    or async_await_for_stream_continue_guard.get("then", {}).get("null") is not True
    or len(async_await_for_stream_continue_else) != 2
    or async_await_for_stream_continue_else[0].get("string") != "patched-stream-await-for-stream-continue-"
    or async_await_for_stream_continue_else[1].get("let_local") != 2
    or async_await_for_stream_continue_finally.get("method") != "cancel"
):
    raise SystemExit(f"expected asyncGeneratedAwaitForStreamContinue generic Stream guarded continue source, got {async_generated_await_for_stream_continue}")
async_generated_await_for_stream_break = patch_by_member.get("asyncGeneratedAwaitForStreamBreak", {}).get("bytecode_source", {})
async_await_for_stream_break_let = async_generated_await_for_stream_break.get("body", {}).get("let", {})
async_await_for_stream_break_locals = async_await_for_stream_break_let.get("locals", [])
async_await_for_stream_break_try = async_await_for_stream_break_let.get("body", {}).get("try_finally", {})
async_await_for_stream_break_loop = async_await_for_stream_break_try.get("body", {}).get("while_loop", {})
async_await_for_stream_break_condition = async_await_for_stream_break_loop.get("condition", {}).get("await", {}).get("call_dynamic", {})
async_await_for_stream_break_before = async_await_for_stream_break_loop.get("before_break", {}).get("set_local", {})
async_await_for_stream_break_guard = async_await_for_stream_break_loop.get("break_condition", {})
async_await_for_stream_break_body = async_await_for_stream_break_loop.get("body", {}).get("yield", {}).get("concat", [])
async_await_for_stream_break_finally = async_await_for_stream_break_try.get("finally", {}).get("await", {}).get("call_dynamic", {})
if (
    async_generated_await_for_stream_break.get("async_kind") != "async_star"
    or len(async_await_for_stream_break_locals) != 3
    or async_await_for_stream_break_locals[0].get("value", {}).get("arg") != "extra"
    or async_await_for_stream_break_locals[1].get("value", {}).get("new_object", {}).get("constructor") != "dart:async::class:_StreamIterator."
    or async_await_for_stream_break_condition.get("method") != "moveNext"
    or async_await_for_stream_break_before.get("id") != 2
    or async_await_for_stream_break_guard.get("op") != "=="
    or async_await_for_stream_break_guard.get("right", {}).get("string") != "stop"
    or len(async_await_for_stream_break_body) != 2
    or async_await_for_stream_break_body[0].get("string") != "patched-stream-await-for-stream-break-"
    or async_await_for_stream_break_body[1].get("let_local") != 2
    or async_await_for_stream_break_finally.get("method") != "cancel"
):
    raise SystemExit(f"expected asyncGeneratedAwaitForStreamBreak generic Stream guarded break source, got {async_generated_await_for_stream_break}")
async_generated_await_for_stream_continue_break_finally = patch_by_member.get(
    "asyncGeneratedAwaitForStreamContinueBreakFinally", {}
).get("bytecode_source", {})
async_await_for_stream_continue_break_outer = (
    async_generated_await_for_stream_continue_break_finally.get("body", {}).get("try_finally", {})
)
async_await_for_stream_continue_break_let = async_await_for_stream_continue_break_outer.get("body", {}).get("let", {})
async_await_for_stream_continue_break_inner = (
    async_await_for_stream_continue_break_let.get("body", {}).get("try_finally", {})
)
async_await_for_stream_continue_break_loop = async_await_for_stream_continue_break_inner.get("body", {}).get("while_loop", {})
async_await_for_stream_continue_break_before = async_await_for_stream_continue_break_loop.get("before_break", {}).get("set_local", {})
async_await_for_stream_continue_break_break = async_await_for_stream_continue_break_loop.get("break_condition", {}).get("conditional", {})
async_await_for_stream_continue_break_body = async_await_for_stream_continue_break_loop.get("body", {}).get("conditional", {})
async_await_for_stream_continue_break_tail = async_await_for_stream_continue_break_body.get("else", {}).get("yield", {}).get("concat", [])
async_await_for_stream_continue_break_cleanup = async_await_for_stream_continue_break_outer.get("finally", {}).get("yield", {})
if (
    async_generated_await_for_stream_continue_break_finally.get("async_kind") != "async_star"
    or async_await_for_stream_continue_break_let.get("locals", [{}])[0].get("value", {}).get("arg") != "extra"
    or async_await_for_stream_continue_break_loop.get("condition", {}).get("await", {}).get("call_dynamic", {}).get("method") != "moveNext"
    or async_await_for_stream_continue_break_inner.get("finally", {}).get("await", {}).get("call_dynamic", {}).get("method") != "cancel"
    or async_await_for_stream_continue_break_before.get("id") != 2
    or async_await_for_stream_continue_break_break.get("condition", {}).get("op") != "=="
    or async_await_for_stream_continue_break_break.get("condition", {}).get("right", {}).get("string") != "skip"
    or async_await_for_stream_continue_break_break.get("then", {}).get("bool") is not False
    or async_await_for_stream_continue_break_break.get("else", {}).get("right", {}).get("string") != "stop"
    or async_await_for_stream_continue_break_body.get("condition", {}).get("op") != "=="
    or async_await_for_stream_continue_break_body.get("then", {}).get("null") is not True
    or len(async_await_for_stream_continue_break_tail) != 2
    or async_await_for_stream_continue_break_tail[0].get("string") != "patched-stream-await-for-stream-continue-break-"
    or async_await_for_stream_continue_break_tail[1].get("let_local") != 2
    or async_await_for_stream_continue_break_cleanup.get("string") != "patched-stream-await-for-stream-continue-break-cleanup"
):
    raise SystemExit(
        "expected asyncGeneratedAwaitForStreamContinueBreakFinally generic Stream "
        f"continue+break+finally source, got {async_generated_await_for_stream_continue_break_finally}"
    )
assert_stream_error_cleanup_source(
    "asyncGeneratedAwaitForStreamCatch",
    ["extra"],
    [
        "patched-stream-await-for-stream-caught-body-",
        "patched-stream-await-for-stream-caught-",
    ],
    1,
    1,
    False,
)
assert_stream_error_cleanup_source(
    "asyncGeneratedAwaitForStreamCatchFinally",
    ["extra"],
    [
        "patched-stream-await-for-stream-catch-finally-body-",
        "patched-stream-await-for-stream-catch-finally-caught-",
        "patched-stream-await-for-stream-catch-finally-cleanup",
    ],
    1,
    1,
    True,
)
assert_stream_error_cleanup_source(
    "asyncGeneratedAwaitForTwoStreamsCatchFinally",
    ["first", "second"],
    [
        "patched-stream-await-for-two-streams-left-",
        "patched-stream-await-for-two-streams-right-",
        "patched-stream-await-for-two-streams-caught-",
        "patched-stream-await-for-two-streams-catch-finally-cleanup",
    ],
    2,
    2,
    True,
)
assert_stream_error_cleanup_source(
    "asyncGeneratedAwaitForNestedStreamCatchFinally",
    ["outer", "inner"],
    [
        "patched-stream-await-for-nested-stream-catch-",
        "patched-stream-await-for-nested-stream-caught-",
        "patched-stream-await-for-nested-stream-catch-cleanup",
    ],
    2,
    2,
    True,
)
assert_stream_error_cleanup_source(
    "asyncGeneratedAwaitForNestedStreamBreakContinueCatchFinally",
    ["outer", "inner"],
    [
        "patched-stream-await-for-nested-stream-break-continue-catch-",
        "patched-stream-await-for-nested-stream-break-continue-caught-",
        "patched-stream-await-for-nested-stream-break-continue-catch-cleanup",
        "skip",
        "stop",
    ],
    2,
    2,
    True,
)
assert_stream_error_cleanup_source(
    "asyncGeneratedAwaitForTripleNestedStreamCatchFinally",
    ["outer", "middle", "inner"],
    [
        "patched-stream-await-for-triple-nested-catch-",
        "patched-stream-await-for-triple-nested-caught-",
        "patched-stream-await-for-triple-nested-catch-cleanup",
        "skip",
        "stop-middle",
    ],
    3,
    3,
    True,
)
assert_finite_stream_error_cleanup_source(
    "asyncGeneratedAwaitForFromIterableCatchFinally",
    ["extra"],
    [
        "patched-stream-await-for-iterable-catch-",
        "patched-stream-await-for-iterable-caught-",
        "patched-stream-await-for-iterable-catch-cleanup",
    ],
    1,
    0,
)
assert_finite_stream_error_cleanup_source(
    "asyncGeneratedAwaitForFutureCatchFinally",
    ["value"],
    [
        "patched-stream-await-for-future-catch-",
        "patched-stream-await-for-future-catch-item-",
        "patched-stream-await-for-future-caught-",
        "patched-stream-await-for-future-catch-cleanup",
    ],
    1,
    0,
)
assert_finite_stream_error_cleanup_source(
    "asyncGeneratedAwaitForPendingFutureCatchFinally",
    ["ready"],
    [
        "patched-stream-await-for-pending-catch-",
        "patched-stream-await-for-pending-caught-",
        "patched-stream-await-for-pending-catch-cleanup",
    ],
    1,
    1,
)
assert_finite_stream_error_cleanup_source(
    "asyncGeneratedAwaitForValueCatchFinally",
    ["value"],
    [
        "patched-stream-await-for-value-catch-",
        "patched-stream-await-for-value-caught-",
        "patched-stream-await-for-value-catch-cleanup",
    ],
    1,
    0,
)
assert_finite_stream_error_cleanup_source(
    "asyncGeneratedAwaitForEmptyCatchFinally",
    [],
    [
        "patched-stream-await-for-empty-catch-",
        "patched-stream-await-for-empty-caught-",
        "patched-stream-await-for-empty-catch-cleanup",
    ],
    1,
    0,
)
assert_finite_stream_error_cleanup_source(
    "asyncGeneratedAwaitForFutureBreakCatchFinally",
    ["value"],
    [
        "patched-stream-await-for-future-break-catch-",
        "patched-stream-await-for-future-break-caught-",
        "patched-stream-await-for-future-break-catch-cleanup",
        "stop",
    ],
    1,
    0,
)
assert_finite_stream_error_cleanup_source(
    "asyncGeneratedAwaitForPendingContinueCatchFinally",
    ["ready"],
    [
        "patched-stream-await-for-pending-continue-catch-",
        "patched-stream-await-for-pending-continue-caught-",
        "patched-stream-await-for-pending-continue-catch-cleanup",
        "skip",
    ],
    1,
    1,
)
async_generated_await_for_nested = patch_by_member.get(
    "asyncGeneratedAwaitForNestedValueFinally", {}
).get("bytecode_source", {})
async_await_for_nested_outer = async_generated_await_for_nested.get("body", {}).get("try_finally", {})
async_await_for_nested_let = async_await_for_nested_outer.get("body", {}).get("let", {})
async_await_for_nested_inner_try = async_await_for_nested_let.get("body", {}).get("try_finally", {})
async_await_for_nested_loop = async_await_for_nested_inner_try.get("body", {}).get("while_loop", {})
async_await_for_nested_body = async_await_for_nested_loop.get("body", {}).get("seq", [])
async_await_for_nested_yield_for = (
    async_await_for_nested_body[1].get("yield_for_in", {})
    if len(async_await_for_nested_body) > 1
    else {}
)
async_await_for_nested_source = async_await_for_nested_yield_for.get("source", {}).get("list", [])
async_await_for_nested_source_concat = async_await_for_nested_source[0].get("concat", []) if async_await_for_nested_source else []
async_await_for_nested_yield = async_await_for_nested_yield_for.get("body", {}).get("yield", {}).get("concat", [])
async_await_for_nested_cleanup = async_await_for_nested_outer.get("finally", {}).get("yield", {})
if (
    async_generated_await_for_nested.get("async_kind") != "async_star"
    or async_await_for_nested_let.get("locals", [{}])[0].get("value", {}).get("arg") != "extra"
    or async_await_for_nested_loop.get("condition", {}).get("await", {}).get("call_dynamic", {}).get("method") != "moveNext"
    or async_await_for_nested_body[0].get("set_local", {}).get("id") != 2
    or len(async_await_for_nested_source_concat) != 2
    or async_await_for_nested_source_concat[0].get("let_local") != 2
    or async_await_for_nested_source_concat[1].get("string") != "-inner"
    or async_await_for_nested_yield_for.get("local", {}).get("name") != "inner"
    or len(async_await_for_nested_yield) != 2
    or async_await_for_nested_yield[0].get("string") != "patched-stream-await-for-nested-"
    or async_await_for_nested_yield[1].get("let_local") != 3
    or async_await_for_nested_inner_try.get("finally", {}).get("await", {}).get("call_dynamic", {}).get("method") != "cancel"
    or async_await_for_nested_cleanup.get("string") != "patched-stream-await-for-nested-cleanup"
):
    raise SystemExit(
        "expected asyncGeneratedAwaitForNestedValueFinally nested generic Stream await-for "
        f"source, got {async_generated_await_for_nested}"
    )
async_generated_await_for_nested_stream = patch_by_member.get(
    "asyncGeneratedAwaitForNestedStreamFinally", {}
).get("bytecode_source", {})
async_await_for_nested_stream_outer = async_generated_await_for_nested_stream.get("body", {}).get("try_finally", {})
async_await_for_nested_stream_let = async_await_for_nested_stream_outer.get("body", {}).get("let", {})
async_await_for_nested_stream_outer_try = async_await_for_nested_stream_let.get("body", {}).get("try_finally", {})
async_await_for_nested_stream_outer_loop = async_await_for_nested_stream_outer_try.get("body", {}).get("while_loop", {})
async_await_for_nested_stream_outer_body = async_await_for_nested_stream_outer_loop.get("body", {}).get("seq", [])
async_await_for_nested_stream_inner_let = (
    async_await_for_nested_stream_outer_body[1].get("let", {})
    if len(async_await_for_nested_stream_outer_body) > 1
    else {}
)
async_await_for_nested_stream_inner_try = async_await_for_nested_stream_inner_let.get("body", {}).get("try_finally", {})
async_await_for_nested_stream_inner_loop = async_await_for_nested_stream_inner_try.get("body", {}).get("while_loop", {})
async_await_for_nested_stream_inner_body = async_await_for_nested_stream_inner_loop.get("body", {}).get("seq", [])
async_await_for_nested_stream_yield = (
    async_await_for_nested_stream_inner_body[1].get("yield", {}).get("concat", [])
    if len(async_await_for_nested_stream_inner_body) > 1
    else []
)
async_await_for_nested_stream_cleanup = async_await_for_nested_stream_outer.get("finally", {}).get("yield", {})
if (
    async_generated_await_for_nested_stream.get("async_kind") != "async_star"
    or async_await_for_nested_stream_let.get("locals", [{}])[0].get("value", {}).get("arg") != "outer"
    or async_await_for_nested_stream_outer_loop.get("condition", {}).get("await", {}).get("call_dynamic", {}).get("method") != "moveNext"
    or async_await_for_nested_stream_outer_body[0].get("set_local", {}).get("id") != 2
    or async_await_for_nested_stream_inner_let.get("locals", [{}])[0].get("value", {}).get("arg") != "inner"
    or async_await_for_nested_stream_inner_loop.get("condition", {}).get("await", {}).get("call_dynamic", {}).get("method") != "moveNext"
    or async_await_for_nested_stream_inner_body[0].get("set_local", {}).get("id") != 5
    or len(async_await_for_nested_stream_yield) != 4
    or async_await_for_nested_stream_yield[0].get("string") != "patched-stream-await-for-nested-stream-"
    or async_await_for_nested_stream_yield[1].get("let_local") != 2
    or async_await_for_nested_stream_yield[2].get("string") != "-"
    or async_await_for_nested_stream_yield[3].get("let_local") != 5
    or async_await_for_nested_stream_inner_try.get("finally", {}).get("await", {}).get("call_dynamic", {}).get("method") != "cancel"
    or async_await_for_nested_stream_outer_try.get("finally", {}).get("await", {}).get("call_dynamic", {}).get("method") != "cancel"
    or async_await_for_nested_stream_cleanup.get("string") != "patched-stream-await-for-nested-stream-cleanup"
):
    raise SystemExit(
        "expected asyncGeneratedAwaitForNestedStreamFinally nested generic Stream await-for "
        f"source, got {async_generated_await_for_nested_stream}"
    )

async_generated_await_for_triple_nested_stream = patch_by_member.get(
    "asyncGeneratedAwaitForTripleNestedStreamFinally", {}
).get("bytecode_source", {})
async_generated_await_for_triple_nested_stream_json = json.dumps(
    async_generated_await_for_triple_nested_stream
)
if (
    async_generated_await_for_triple_nested_stream.get("async_kind") != "async_star"
    or async_generated_await_for_triple_nested_stream_json.count('"method": "moveNext"') < 3
    or async_generated_await_for_triple_nested_stream_json.count('"method": "cancel"') < 3
    or '"arg": "outer"' not in async_generated_await_for_triple_nested_stream_json
    or '"arg": "middle"' not in async_generated_await_for_triple_nested_stream_json
    or '"arg": "inner"' not in async_generated_await_for_triple_nested_stream_json
    or '"string": "patched-stream-await-for-triple-nested-"' not in async_generated_await_for_triple_nested_stream_json
    or '"string": "patched-stream-await-for-triple-nested-cleanup"' not in async_generated_await_for_triple_nested_stream_json
    or '"string": "skip"' not in async_generated_await_for_triple_nested_stream_json
    or '"string": "stop-middle"' not in async_generated_await_for_triple_nested_stream_json
):
    raise SystemExit(
        "expected asyncGeneratedAwaitForTripleNestedStreamFinally triple nested "
        f"generic Stream await-for source, got {async_generated_await_for_triple_nested_stream}"
    )

null_sources = [
    f.get("bytecode_source", {}).get("body")
    for f in patch["functions"]
    if f.get("member_name") == "maybeNull"
]
if null_sources != [{"null": True}]:
    raise SystemExit(f"expected maybeNull null bytecode source, got {null_sources}")

label_sources = [
    f.get("bytecode_source", {}).get("body")
    for f in patch["functions"]
    if f.get("member_name") == "label"
]
if len(label_sources) != 1:
    raise SystemExit(f"expected one label bytecode source, got {label_sources}")
label_source = label_sources[0]
if "concat" not in label_source:
    raise SystemExit(f"expected label string concat source, got {label_source}")
if '"hello "' not in json.dumps(label_source) or '"!"' not in json.dumps(label_source):
    raise SystemExit(f"expected label concat constants, got {label_source}")
