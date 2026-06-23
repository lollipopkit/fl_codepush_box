def assert_stream_generators(module):
    def assert_async_star_stream_error_cleanup(name, constants, min_streams, has_finally):
        function = next(
            item for item in module["functions"] if item["name"].endswith(f"::{name}")
        )
        assert function.get("async_kind") == "async_star", function
        assert function["code"].count(0x55) >= min_streams, function
        assert function["code"].count(0x62) >= min_streams, function
        assert 0x64 in function["code"], function
        assert 0x61 in function["code"], function
        assert 0x65 in function["code"], function
        assert 0x66 in function["code"], function
        if has_finally:
            assert function["code"].count(0x65) >= min_streams + 1, function
            assert function["code"].count(0x66) >= min_streams + 1, function
        for value in constants:
            assert any(
                constant.get("type") == "String" and constant.get("value") == value
                for constant in function["constants"]
            ), function

    def assert_async_star_finite_stream_error_cleanup(name, constants):
        function = next(
            item for item in module["functions"] if item["name"].endswith(f"::{name}")
        )
        assert function.get("async_kind") == "async_star", function
        assert 0x61 in function["code"], function
        assert 0x65 in function["code"], function
        assert 0x66 in function["code"], function
        assert 0x64 in function["code"], function
        for value in constants:
            assert any(
                constant.get("type") == "String" and constant.get("value") == value
                for constant in function["constants"]
            ), function

    def assert_async_star_stream_finally_await_cleanup(name, constants, min_streams=1):
        function = next(
            item for item in module["functions"] if item["name"].endswith(f"::{name}")
        )
        assert function.get("async_kind") == "async_star", function
        assert function["code"].count(0x55) >= min_streams, function
        assert function["code"].count(0x62) >= min_streams + 1, function
        assert 0x64 in function["code"], function
        assert 0x65 in function["code"], function
        assert 0x66 in function["code"], function
        for value in constants:
            assert any(
                constant.get("type") == "String" and constant.get("value") == value
                for constant in function["constants"]
            ), function

    sync_generated_yield_star = next(
        item for item in module["functions"] if item["name"].endswith("::syncGeneratedYieldStar")
    )
    assert sync_generated_yield_star.get("async_kind") == "sync_star", sync_generated_yield_star
    assert sync_generated_yield_star["code"].count(0x64) == 2, sync_generated_yield_star
    sync_generated_yield_star_dynamic = next(
        item for item in module["functions"] if item["name"].endswith("::syncGeneratedYieldStarDynamic")
    )
    assert sync_generated_yield_star_dynamic.get("async_kind") == "sync_star", sync_generated_yield_star_dynamic
    assert sync_generated_yield_star_dynamic["code"].count(0x64) == 2, sync_generated_yield_star_dynamic
    assert 0x51 in sync_generated_yield_star_dynamic["code"], sync_generated_yield_star_dynamic
    assert 0x31 in sync_generated_yield_star_dynamic["code"], sync_generated_yield_star_dynamic
    sync_generated_nested_control = next(
        item
        for item in module["functions"]
        if item["name"].endswith("::syncGeneratedDynamicForInNestedBreakContinue")
    )
    assert sync_generated_nested_control.get("async_kind") == "sync_star", sync_generated_nested_control
    assert sync_generated_nested_control["code"].count(0x64) == 1, sync_generated_nested_control
    assert sync_generated_nested_control["code"].count(0x51) >= 2, sync_generated_nested_control
    assert sync_generated_nested_control["code"].count(0x31) >= 4, sync_generated_nested_control
    assert sync_generated_nested_control["code"].count(0x30) >= 4, sync_generated_nested_control
    assert {"slot": 0, "name": "extra"} in sync_generated_nested_control.get("debug_locals", []), sync_generated_nested_control
    assert {"slot": 1, "name": "suffixes"} in sync_generated_nested_control.get("debug_locals", []), sync_generated_nested_control
    assert any(
        constant.get("type") == "String" and constant.get("value") == "patched-iterable-nested-control"
        for constant in sync_generated_nested_control["constants"]
    ), sync_generated_nested_control
    assert any(
        constant.get("type") == "String" and constant.get("value") == "skip"
        for constant in sync_generated_nested_control["constants"]
    ), sync_generated_nested_control
    assert any(
        constant.get("type") == "String" and constant.get("value") == "stop"
        for constant in sync_generated_nested_control["constants"]
    ), sync_generated_nested_control
    async_generated_yield_star = next(
        item for item in module["functions"] if item["name"].endswith("::asyncGeneratedYieldStar")
    )
    assert async_generated_yield_star.get("async_kind") == "async_star", async_generated_yield_star
    assert async_generated_yield_star["code"].count(0x64) == 2, async_generated_yield_star
    async_generated_yield_star_dynamic = next(
        item for item in module["functions"] if item["name"].endswith("::asyncGeneratedYieldStarDynamic")
    )
    assert async_generated_yield_star_dynamic.get("async_kind") == "async_star", async_generated_yield_star_dynamic
    assert async_generated_yield_star_dynamic["code"].count(0x64) == 2, async_generated_yield_star_dynamic
    assert 0x51 in async_generated_yield_star_dynamic["code"], async_generated_yield_star_dynamic
    assert 0x31 in async_generated_yield_star_dynamic["code"], async_generated_yield_star_dynamic
    async_generated_nested_control = next(
        item
        for item in module["functions"]
        if item["name"].endswith("::asyncGeneratedDynamicForInNestedBreakContinue")
    )
    assert async_generated_nested_control.get("async_kind") == "async_star", async_generated_nested_control
    assert async_generated_nested_control["code"].count(0x64) == 1, async_generated_nested_control
    assert async_generated_nested_control["code"].count(0x51) >= 2, async_generated_nested_control
    assert async_generated_nested_control["code"].count(0x31) >= 4, async_generated_nested_control
    assert async_generated_nested_control["code"].count(0x30) >= 4, async_generated_nested_control
    assert {"slot": 0, "name": "extra"} in async_generated_nested_control.get("debug_locals", []), async_generated_nested_control
    assert {"slot": 1, "name": "suffixes"} in async_generated_nested_control.get("debug_locals", []), async_generated_nested_control
    assert any(
        constant.get("type") == "String" and constant.get("value") == "patched-stream-nested-control"
        for constant in async_generated_nested_control["constants"]
    ), async_generated_nested_control
    assert any(
        constant.get("type") == "String" and constant.get("value") == "skip"
        for constant in async_generated_nested_control["constants"]
    ), async_generated_nested_control
    assert any(
        constant.get("type") == "String" and constant.get("value") == "stop"
        for constant in async_generated_nested_control["constants"]
    ), async_generated_nested_control
    async_generated_yield_star_stream = next(
        item for item in module["functions"] if item["name"].endswith("::asyncGeneratedYieldStarStream")
    )
    assert async_generated_yield_star_stream.get("async_kind") == "async_star", async_generated_yield_star_stream
    assert 0x55 in async_generated_yield_star_stream["code"], async_generated_yield_star_stream
    assert 0x62 in async_generated_yield_star_stream["code"], async_generated_yield_star_stream
    assert 0x64 in async_generated_yield_star_stream["code"], async_generated_yield_star_stream
    assert 0x65 in async_generated_yield_star_stream["code"], async_generated_yield_star_stream
    assert 0x66 in async_generated_yield_star_stream["code"], async_generated_yield_star_stream
    assert any(
        constant.get("type") == "String" and constant.get("value") == "dart:async::class:_StreamIterator."
        for constant in async_generated_yield_star_stream["constants"]
    ), async_generated_yield_star_stream
    assert any(
        constant.get("type") == "String" and constant.get("value") == "moveNext"
        for constant in async_generated_yield_star_stream["constants"]
    ), async_generated_yield_star_stream
    assert any(
        constant.get("type") == "String" and constant.get("value") == "cancel"
        for constant in async_generated_yield_star_stream["constants"]
    ), async_generated_yield_star_stream
    assert any(
        entry.get("name") == ":yield-star-current"
        for entry in async_generated_yield_star_stream.get("debug_locals", [])
    ), async_generated_yield_star_stream
    async_generated_yield_star_stream_finally = next(
        item for item in module["functions"] if item["name"].endswith("::asyncGeneratedYieldStarStreamFinally")
    )
    assert async_generated_yield_star_stream_finally.get("async_kind") == "async_star", async_generated_yield_star_stream_finally
    assert 0x55 in async_generated_yield_star_stream_finally["code"], async_generated_yield_star_stream_finally
    assert 0x62 in async_generated_yield_star_stream_finally["code"], async_generated_yield_star_stream_finally
    assert async_generated_yield_star_stream_finally["code"].count(0x64) == 2, async_generated_yield_star_stream_finally
    assert async_generated_yield_star_stream_finally["code"].count(0x65) >= 2, async_generated_yield_star_stream_finally
    assert async_generated_yield_star_stream_finally["code"].count(0x66) >= 2, async_generated_yield_star_stream_finally
    assert any(
        constant.get("type") == "String" and constant.get("value") == "patched-stream-yield-star-stream-finally-cleanup"
        for constant in async_generated_yield_star_stream_finally["constants"]
    ), async_generated_yield_star_stream_finally
    async_generated_yield_star_stream_sandwich = next(
        item
        for item in module["functions"]
        if item["name"].endswith("::asyncGeneratedYieldStarStreamSandwichFinally")
    )
    assert async_generated_yield_star_stream_sandwich.get("async_kind") == "async_star", async_generated_yield_star_stream_sandwich
    assert 0x55 in async_generated_yield_star_stream_sandwich["code"], async_generated_yield_star_stream_sandwich
    assert 0x62 in async_generated_yield_star_stream_sandwich["code"], async_generated_yield_star_stream_sandwich
    assert async_generated_yield_star_stream_sandwich["code"].count(0x64) == 4, async_generated_yield_star_stream_sandwich
    assert async_generated_yield_star_stream_sandwich["code"].count(0x65) >= 2, async_generated_yield_star_stream_sandwich
    assert async_generated_yield_star_stream_sandwich["code"].count(0x66) >= 2, async_generated_yield_star_stream_sandwich
    assert any(
        constant.get("type") == "String" and constant.get("value") == "patched-stream-yield-star-stream-before"
        for constant in async_generated_yield_star_stream_sandwich["constants"]
    ), async_generated_yield_star_stream_sandwich
    assert any(
        constant.get("type") == "String" and constant.get("value") == "patched-stream-yield-star-stream-after"
        for constant in async_generated_yield_star_stream_sandwich["constants"]
    ), async_generated_yield_star_stream_sandwich
    assert any(
        constant.get("type") == "String" and constant.get("value") == "patched-stream-yield-star-stream-sandwich-cleanup"
        for constant in async_generated_yield_star_stream_sandwich["constants"]
    ), async_generated_yield_star_stream_sandwich
    async_generated_yield_star_two_streams = next(
        item
        for item in module["functions"]
        if item["name"].endswith("::asyncGeneratedYieldStarTwoStreamsFinally")
    )
    assert async_generated_yield_star_two_streams.get("async_kind") == "async_star", async_generated_yield_star_two_streams
    assert async_generated_yield_star_two_streams["code"].count(0x55) >= 2, async_generated_yield_star_two_streams
    assert async_generated_yield_star_two_streams["code"].count(0x62) >= 2, async_generated_yield_star_two_streams
    assert async_generated_yield_star_two_streams["code"].count(0x64) == 3, async_generated_yield_star_two_streams
    assert async_generated_yield_star_two_streams["code"].count(0x65) >= 3, async_generated_yield_star_two_streams
    assert async_generated_yield_star_two_streams["code"].count(0x66) >= 3, async_generated_yield_star_two_streams
    assert any(
        constant.get("type") == "String" and constant.get("value") == "patched-stream-yield-star-two-streams-cleanup"
        for constant in async_generated_yield_star_two_streams["constants"]
    ), async_generated_yield_star_two_streams
    assert_async_star_stream_error_cleanup(
        "asyncGeneratedYieldStarStreamCatch",
        ["patched-stream-yield-star-stream-caught-"],
        1,
        False,
    )
    assert_async_star_stream_error_cleanup(
        "asyncGeneratedYieldStarStreamCatchFinally",
        [
            "patched-stream-yield-star-stream-catch-finally-caught-",
            "patched-stream-yield-star-stream-catch-finally-cleanup",
        ],
        1,
        True,
    )
    assert_async_star_stream_error_cleanup(
        "asyncGeneratedYieldStarStreamCatchAwaitRecovery",
        ["patched-stream-yield-star-stream-catch-await-caught-"],
        1,
        False,
    )
    assert_async_star_stream_finally_await_cleanup(
        "asyncGeneratedYieldStarStreamFinallyAwaitCleanup",
        ["patched-stream-yield-star-stream-finally-await-cleanup-"],
    )
    assert_async_star_stream_error_cleanup(
        "asyncGeneratedYieldStarStreamCatchFinallyAwaitRecovery",
        [
            "patched-stream-yield-star-stream-catch-finally-await-caught-",
            "patched-stream-yield-star-stream-catch-finally-await-cleanup-",
        ],
        1,
        True,
    )
    assert_async_star_stream_error_cleanup(
        "asyncGeneratedYieldStarTwoStreamsCatchFinally",
        [
            "patched-stream-yield-star-two-streams-caught-",
            "patched-stream-yield-star-two-streams-catch-finally-cleanup",
        ],
        2,
        True,
    )
    assert_async_star_stream_error_cleanup(
        "asyncGeneratedYieldStarTwoStreamsCatchAwaitRecovery",
        ["patched-stream-yield-star-two-streams-catch-await-caught-"],
        2,
        False,
    )
    assert_async_star_stream_finally_await_cleanup(
        "asyncGeneratedYieldStarTwoStreamsFinallyAwaitCleanup",
        ["patched-stream-yield-star-two-streams-finally-await-cleanup-"],
    )
    assert_async_star_stream_error_cleanup(
        "asyncGeneratedYieldStarTwoStreamsCatchFinallyAwaitRecovery",
        [
            "patched-stream-yield-star-two-streams-catch-finally-await-caught-",
            "patched-stream-yield-star-two-streams-catch-finally-await-cleanup-",
        ],
        2,
        True,
    )
    assert_async_star_stream_error_cleanup(
        "asyncGeneratedYieldStarStreamSandwichCatchFinally",
        [
            "patched-stream-yield-star-stream-sandwich-catch-before",
            "patched-stream-yield-star-stream-sandwich-catch-after",
            "patched-stream-yield-star-stream-sandwich-caught-",
            "patched-stream-yield-star-stream-sandwich-catch-cleanup",
        ],
        1,
        True,
    )
    assert_async_star_stream_error_cleanup(
        "asyncGeneratedYieldStarTwoStreamsSandwichCatchFinally",
        [
            "patched-stream-yield-star-two-streams-sandwich-before",
            "patched-stream-yield-star-two-streams-sandwich-middle",
            "patched-stream-yield-star-two-streams-sandwich-after",
            "patched-stream-yield-star-two-streams-sandwich-caught-",
            "patched-stream-yield-star-two-streams-sandwich-cleanup",
        ],
        2,
        True,
    )
    assert_async_star_stream_error_cleanup(
        "asyncGeneratedYieldStarTripleStreamsCatchFinally",
        [
            "patched-stream-yield-star-triple-streams-caught-",
            "patched-stream-yield-star-triple-streams-cleanup",
        ],
        3,
        True,
    )
    assert_async_star_stream_error_cleanup(
        "asyncGeneratedYieldStarTripleStreamsCatchAwaitRecovery",
        ["patched-stream-yield-star-triple-streams-catch-await-caught-"],
        3,
        False,
    )
    assert_async_star_stream_finally_await_cleanup(
        "asyncGeneratedYieldStarTripleStreamsFinallyAwaitCleanup",
        ["patched-stream-yield-star-triple-streams-finally-await-cleanup-"],
        3,
    )
    assert_async_star_stream_error_cleanup(
        "asyncGeneratedYieldStarTripleStreamsCatchFinallyAwaitRecovery",
        [
            "patched-stream-yield-star-triple-streams-catch-finally-await-caught-",
            "patched-stream-yield-star-triple-streams-catch-finally-await-cleanup-",
        ],
        3,
        True,
    )
    assert_async_star_stream_error_cleanup(
        "asyncGeneratedAwaitForStreamCatchAwaitRecovery",
        [
            "patched-stream-await-for-stream-catch-await-body-",
            "patched-stream-await-for-stream-catch-await-caught-",
        ],
        1,
        False,
    )
    assert_async_star_stream_finally_await_cleanup(
        "asyncGeneratedAwaitForStreamFinallyAwaitCleanup",
        [
            "patched-stream-await-for-stream-finally-await-body-",
            "patched-stream-await-for-stream-finally-await-cleanup-",
        ],
    )
    assert_async_star_stream_error_cleanup(
        "asyncGeneratedAwaitForStreamCatchFinallyAwaitRecovery",
        [
            "patched-stream-await-for-stream-catch-finally-await-body-",
            "patched-stream-await-for-stream-catch-finally-await-caught-",
            "patched-stream-await-for-stream-catch-finally-await-cleanup-",
        ],
        1,
        True,
    )
    assert_async_star_finite_stream_error_cleanup(
        "asyncGeneratedYieldStarDynamicCatchFinally",
        [
            "patched-stream-yield-star-dynamic-caught-",
            "patched-stream-yield-star-dynamic-catch-cleanup",
        ],
    )
    assert_async_star_finite_stream_error_cleanup(
        "asyncGeneratedYieldStarFromFutureCatchFinally",
        [
            "patched-stream-yield-star-future-catch-",
            "patched-stream-yield-star-future-caught-",
            "patched-stream-yield-star-future-catch-cleanup",
        ],
    )
    assert_async_star_finite_stream_error_cleanup(
        "asyncGeneratedYieldStarPendingFutureCatchFinally",
        [
            "patched-stream-yield-star-pending-caught-",
            "patched-stream-yield-star-pending-catch-cleanup",
        ],
    )
    assert_async_star_finite_stream_error_cleanup(
        "asyncGeneratedYieldStarValueCatchFinally",
        [
            "patched-stream-yield-star-value-catch-",
            "patched-stream-yield-star-value-caught-",
            "patched-stream-yield-star-value-catch-cleanup",
        ],
    )
    assert_async_star_finite_stream_error_cleanup(
        "asyncGeneratedYieldStarEmptyCatchFinally",
        [
            "patched-stream-yield-star-empty-caught-",
            "patched-stream-yield-star-empty-catch-cleanup",
        ],
    )
    async_generated_yield_star_value = next(
        item for item in module["functions"] if item["name"].endswith("::asyncGeneratedYieldStarValue")
    )
    assert async_generated_yield_star_value.get("async_kind") == "async_star", async_generated_yield_star_value
    assert async_generated_yield_star_value["code"].count(0x64) == 1, async_generated_yield_star_value
    assert any(
        constant.get("type") == "String" and constant.get("value") == "patched-stream-yield-star-value-"
        for constant in async_generated_yield_star_value["constants"]
    ), async_generated_yield_star_value
    async_generated_yield_star_future = next(
        item for item in module["functions"] if item["name"].endswith("::asyncGeneratedYieldStarFromFuture")
    )
    assert async_generated_yield_star_future.get("async_kind") == "async_star", async_generated_yield_star_future
    assert async_generated_yield_star_future["code"].count(0x64) == 1, async_generated_yield_star_future
    assert any(
        constant.get("type") == "String" and constant.get("value") == "patched-stream-yield-star-future-"
        for constant in async_generated_yield_star_future["constants"]
    ), async_generated_yield_star_future
    async_generated_yield_star_pending = next(
        item for item in module["functions"] if item["name"].endswith("::asyncGeneratedYieldStarPendingFuture")
    )
    assert async_generated_yield_star_pending.get("async_kind") == "async_star", async_generated_yield_star_pending
    assert 0x62 in async_generated_yield_star_pending["code"], async_generated_yield_star_pending
    assert 0x64 in async_generated_yield_star_pending["code"], async_generated_yield_star_pending
    assert {"slot": 0, "name": "ready"} in async_generated_yield_star_pending.get("debug_locals", []), async_generated_yield_star_pending
    async_generated_yield_star_empty = next(
        item for item in module["functions"] if item["name"].endswith("::asyncGeneratedYieldStarEmpty")
    )
    assert async_generated_yield_star_empty.get("async_kind") == "async_star", async_generated_yield_star_empty
    assert 0x64 not in async_generated_yield_star_empty["code"], async_generated_yield_star_empty
    async_generated_await_for_iterable = next(
        item for item in module["functions"] if item["name"].endswith("::asyncGeneratedAwaitForFromIterable")
    )
    assert async_generated_await_for_iterable.get("async_kind") == "async_star", async_generated_await_for_iterable
    assert async_generated_await_for_iterable["code"].count(0x64) == 1, async_generated_await_for_iterable
    assert 0x51 in async_generated_await_for_iterable["code"], async_generated_await_for_iterable
    assert 0x31 in async_generated_await_for_iterable["code"], async_generated_await_for_iterable
    assert any(
        constant.get("type") == "String" and constant.get("value") == "patched-stream-await-for-iterable-"
        for constant in async_generated_await_for_iterable["constants"]
    ), async_generated_await_for_iterable
    async_generated_await_for_continue = next(
        item for item in module["functions"] if item["name"].endswith("::asyncGeneratedAwaitForContinue")
    )
    assert async_generated_await_for_continue.get("async_kind") == "async_star", async_generated_await_for_continue
    assert async_generated_await_for_continue["code"].count(0x64) == 1, async_generated_await_for_continue
    assert 0x31 in async_generated_await_for_continue["code"], async_generated_await_for_continue
    assert any(
        constant.get("type") == "String" and constant.get("value") == "patched-stream-await-for-continue-"
        for constant in async_generated_await_for_continue["constants"]
    ), async_generated_await_for_continue
    async_generated_await_for_break = next(
        item for item in module["functions"] if item["name"].endswith("::asyncGeneratedAwaitForBreak")
    )
    assert async_generated_await_for_break.get("async_kind") == "async_star", async_generated_await_for_break
    assert async_generated_await_for_break["code"].count(0x64) == 1, async_generated_await_for_break
    assert 0x31 in async_generated_await_for_break["code"], async_generated_await_for_break
    assert any(
        constant.get("type") == "String" and constant.get("value") == "patched-stream-await-for-break-"
        for constant in async_generated_await_for_break["constants"]
    ), async_generated_await_for_break
    async_generated_await_for_value = next(
        item for item in module["functions"] if item["name"].endswith("::asyncGeneratedAwaitForValue")
    )
    assert async_generated_await_for_value.get("async_kind") == "async_star", async_generated_await_for_value
    assert async_generated_await_for_value["code"].count(0x64) == 1, async_generated_await_for_value
    assert 0x51 in async_generated_await_for_value["code"], async_generated_await_for_value
    assert 0x31 in async_generated_await_for_value["code"], async_generated_await_for_value
    assert any(
        constant.get("type") == "String" and constant.get("value") == "patched-stream-await-for-value-"
        for constant in async_generated_await_for_value["constants"]
    ), async_generated_await_for_value
    async_generated_await_for_future = next(
        item for item in module["functions"] if item["name"].endswith("::asyncGeneratedAwaitForFuture")
    )
    assert async_generated_await_for_future.get("async_kind") == "async_star", async_generated_await_for_future
    assert async_generated_await_for_future["code"].count(0x64) == 1, async_generated_await_for_future
    assert 0x51 in async_generated_await_for_future["code"], async_generated_await_for_future
    assert 0x31 in async_generated_await_for_future["code"], async_generated_await_for_future
    assert any(
        constant.get("type") == "String" and constant.get("value") == "patched-stream-await-for-future-"
        for constant in async_generated_await_for_future["constants"]
    ), async_generated_await_for_future
    async_generated_await_for_future_break = next(
        item for item in module["functions"] if item["name"].endswith("::asyncGeneratedAwaitForFutureBreak")
    )
    assert async_generated_await_for_future_break.get("async_kind") == "async_star", async_generated_await_for_future_break
    assert async_generated_await_for_future_break["code"].count(0x64) == 1, async_generated_await_for_future_break
    assert 0x31 in async_generated_await_for_future_break["code"], async_generated_await_for_future_break
    assert any(
        constant.get("type") == "String" and constant.get("value") == "patched-stream-await-for-future-break-"
        for constant in async_generated_await_for_future_break["constants"]
    ), async_generated_await_for_future_break
    async_generated_await_for_pending = next(
        item for item in module["functions"] if item["name"].endswith("::asyncGeneratedAwaitForPendingFuture")
    )
    assert async_generated_await_for_pending.get("async_kind") == "async_star", async_generated_await_for_pending
    assert 0x62 in async_generated_await_for_pending["code"], async_generated_await_for_pending
    assert 0x64 in async_generated_await_for_pending["code"], async_generated_await_for_pending
    assert {"slot": 0, "name": "ready"} in async_generated_await_for_pending.get("debug_locals", []), async_generated_await_for_pending
    assert any(
        constant.get("type") == "String" and constant.get("value") == "patched-stream-await-for-pending-future-"
        for constant in async_generated_await_for_pending["constants"]
    ), async_generated_await_for_pending
    async_generated_await_for_pending_continue = next(
        item for item in module["functions"] if item["name"].endswith("::asyncGeneratedAwaitForPendingContinue")
    )
    assert async_generated_await_for_pending_continue.get("async_kind") == "async_star", async_generated_await_for_pending_continue
    assert 0x62 in async_generated_await_for_pending_continue["code"], async_generated_await_for_pending_continue
    assert 0x64 in async_generated_await_for_pending_continue["code"], async_generated_await_for_pending_continue
    assert 0x31 in async_generated_await_for_pending_continue["code"], async_generated_await_for_pending_continue
    assert {"slot": 0, "name": "ready"} in async_generated_await_for_pending_continue.get("debug_locals", []), async_generated_await_for_pending_continue
    assert any(
        constant.get("type") == "String" and constant.get("value") == "patched-stream-await-for-pending-continue-"
        for constant in async_generated_await_for_pending_continue["constants"]
    ), async_generated_await_for_pending_continue
    async_generated_await_for_empty = next(
        item for item in module["functions"] if item["name"].endswith("::asyncGeneratedAwaitForEmpty")
    )
    assert async_generated_await_for_empty.get("async_kind") == "async_star", async_generated_await_for_empty
    assert 0x64 in async_generated_await_for_empty["code"], async_generated_await_for_empty
    assert 0x31 in async_generated_await_for_empty["code"], async_generated_await_for_empty
    assert any(
        constant.get("type") == "String" and constant.get("value") == "patched-stream-await-for-empty-"
        for constant in async_generated_await_for_empty["constants"]
    ), async_generated_await_for_empty
    async_generated_await_for_stream = next(
        item for item in module["functions"] if item["name"].endswith("::asyncGeneratedAwaitFor")
    )
    assert async_generated_await_for_stream.get("async_kind") == "async_star", async_generated_await_for_stream
    assert 0x55 in async_generated_await_for_stream["code"], async_generated_await_for_stream
    assert 0x62 in async_generated_await_for_stream["code"], async_generated_await_for_stream
    assert 0x64 in async_generated_await_for_stream["code"], async_generated_await_for_stream
    assert 0x65 in async_generated_await_for_stream["code"], async_generated_await_for_stream
    assert 0x66 in async_generated_await_for_stream["code"], async_generated_await_for_stream
    assert any(
        constant.get("type") == "String" and constant.get("value") == "dart:async::class:_StreamIterator."
        for constant in async_generated_await_for_stream["constants"]
    ), async_generated_await_for_stream
    assert any(
        constant.get("type") == "String" and constant.get("value") == "moveNext"
        for constant in async_generated_await_for_stream["constants"]
    ), async_generated_await_for_stream
    assert any(
        constant.get("type") == "String" and constant.get("value") == "cancel"
        for constant in async_generated_await_for_stream["constants"]
    ), async_generated_await_for_stream
    assert any(
        entry.get("name") == "value"
        for entry in async_generated_await_for_stream.get("debug_locals", [])
    ), async_generated_await_for_stream
    async_generated_await_for_finally = next(
        item for item in module["functions"] if item["name"].endswith("::asyncGeneratedAwaitForFinally")
    )
    assert async_generated_await_for_finally.get("async_kind") == "async_star", async_generated_await_for_finally
    assert 0x55 in async_generated_await_for_finally["code"], async_generated_await_for_finally
    assert 0x62 in async_generated_await_for_finally["code"], async_generated_await_for_finally
    assert async_generated_await_for_finally["code"].count(0x64) == 2, async_generated_await_for_finally
    assert async_generated_await_for_finally["code"].count(0x65) >= 2, async_generated_await_for_finally
    assert async_generated_await_for_finally["code"].count(0x66) >= 2, async_generated_await_for_finally
    assert any(
        constant.get("type") == "String" and constant.get("value") == "patched-stream-await-for-finally-cleanup"
        for constant in async_generated_await_for_finally["constants"]
    ), async_generated_await_for_finally
    async_generated_await_for_stream_continue = next(
        item for item in module["functions"] if item["name"].endswith("::asyncGeneratedAwaitForStreamContinue")
    )
    assert async_generated_await_for_stream_continue.get("async_kind") == "async_star", async_generated_await_for_stream_continue
    assert 0x55 in async_generated_await_for_stream_continue["code"], async_generated_await_for_stream_continue
    assert 0x62 in async_generated_await_for_stream_continue["code"], async_generated_await_for_stream_continue
    assert 0x64 in async_generated_await_for_stream_continue["code"], async_generated_await_for_stream_continue
    assert 0x65 in async_generated_await_for_stream_continue["code"], async_generated_await_for_stream_continue
    assert 0x66 in async_generated_await_for_stream_continue["code"], async_generated_await_for_stream_continue
    assert 0x31 in async_generated_await_for_stream_continue["code"], async_generated_await_for_stream_continue
    assert any(
        constant.get("type") == "String" and constant.get("value") == "dart:async::class:_StreamIterator."
        for constant in async_generated_await_for_stream_continue["constants"]
    ), async_generated_await_for_stream_continue
    assert any(
        constant.get("type") == "String" and constant.get("value") == "moveNext"
        for constant in async_generated_await_for_stream_continue["constants"]
    ), async_generated_await_for_stream_continue
    assert any(
        constant.get("type") == "String" and constant.get("value") == "cancel"
        for constant in async_generated_await_for_stream_continue["constants"]
    ), async_generated_await_for_stream_continue
    assert any(
        constant.get("type") == "String" and constant.get("value") == "patched-stream-await-for-stream-continue-"
        for constant in async_generated_await_for_stream_continue["constants"]
    ), async_generated_await_for_stream_continue
    assert any(
        entry.get("name") == "value"
        for entry in async_generated_await_for_stream_continue.get("debug_locals", [])
    ), async_generated_await_for_stream_continue
    async_generated_await_for_stream_break = next(
        item for item in module["functions"] if item["name"].endswith("::asyncGeneratedAwaitForStreamBreak")
    )
    assert async_generated_await_for_stream_break.get("async_kind") == "async_star", async_generated_await_for_stream_break
    assert 0x55 in async_generated_await_for_stream_break["code"], async_generated_await_for_stream_break
    assert 0x62 in async_generated_await_for_stream_break["code"], async_generated_await_for_stream_break
    assert 0x64 in async_generated_await_for_stream_break["code"], async_generated_await_for_stream_break
    assert 0x65 in async_generated_await_for_stream_break["code"], async_generated_await_for_stream_break
    assert 0x66 in async_generated_await_for_stream_break["code"], async_generated_await_for_stream_break
    assert 0x31 in async_generated_await_for_stream_break["code"], async_generated_await_for_stream_break
    assert 0x30 in async_generated_await_for_stream_break["code"], async_generated_await_for_stream_break
    assert any(
        constant.get("type") == "String" and constant.get("value") == "dart:async::class:_StreamIterator."
        for constant in async_generated_await_for_stream_break["constants"]
    ), async_generated_await_for_stream_break
    assert any(
        constant.get("type") == "String" and constant.get("value") == "moveNext"
        for constant in async_generated_await_for_stream_break["constants"]
    ), async_generated_await_for_stream_break
    assert any(
        constant.get("type") == "String" and constant.get("value") == "cancel"
        for constant in async_generated_await_for_stream_break["constants"]
    ), async_generated_await_for_stream_break
    assert any(
        constant.get("type") == "String" and constant.get("value") == "patched-stream-await-for-stream-break-"
        for constant in async_generated_await_for_stream_break["constants"]
    ), async_generated_await_for_stream_break
    assert any(
        entry.get("name") == "value"
        for entry in async_generated_await_for_stream_break.get("debug_locals", [])
    ), async_generated_await_for_stream_break
    async_generated_await_for_stream_continue_break_finally = next(
        item
        for item in module["functions"]
        if item["name"].endswith("::asyncGeneratedAwaitForStreamContinueBreakFinally")
    )
    assert async_generated_await_for_stream_continue_break_finally.get("async_kind") == "async_star", async_generated_await_for_stream_continue_break_finally
    assert 0x55 in async_generated_await_for_stream_continue_break_finally["code"], async_generated_await_for_stream_continue_break_finally
    assert 0x62 in async_generated_await_for_stream_continue_break_finally["code"], async_generated_await_for_stream_continue_break_finally
    assert async_generated_await_for_stream_continue_break_finally["code"].count(0x64) == 2, async_generated_await_for_stream_continue_break_finally
    assert async_generated_await_for_stream_continue_break_finally["code"].count(0x65) >= 2, async_generated_await_for_stream_continue_break_finally
    assert async_generated_await_for_stream_continue_break_finally["code"].count(0x66) >= 2, async_generated_await_for_stream_continue_break_finally
    assert 0x31 in async_generated_await_for_stream_continue_break_finally["code"], async_generated_await_for_stream_continue_break_finally
    assert 0x30 in async_generated_await_for_stream_continue_break_finally["code"], async_generated_await_for_stream_continue_break_finally
    assert any(
        constant.get("type") == "String" and constant.get("value") == "patched-stream-await-for-stream-continue-break-"
        for constant in async_generated_await_for_stream_continue_break_finally["constants"]
    ), async_generated_await_for_stream_continue_break_finally
    assert any(
        constant.get("type") == "String" and constant.get("value") == "patched-stream-await-for-stream-continue-break-cleanup"
        for constant in async_generated_await_for_stream_continue_break_finally["constants"]
    ), async_generated_await_for_stream_continue_break_finally
    assert_async_star_stream_error_cleanup(
        "asyncGeneratedAwaitForStreamCatch",
        [
            "patched-stream-await-for-stream-caught-body-",
            "patched-stream-await-for-stream-caught-",
        ],
        1,
        False,
    )
    assert_async_star_stream_error_cleanup(
        "asyncGeneratedAwaitForStreamCatchFinally",
        [
            "patched-stream-await-for-stream-catch-finally-body-",
            "patched-stream-await-for-stream-catch-finally-caught-",
            "patched-stream-await-for-stream-catch-finally-cleanup",
        ],
        1,
        True,
    )
    assert_async_star_stream_error_cleanup(
        "asyncGeneratedAwaitForTwoStreamsCatchFinally",
        [
            "patched-stream-await-for-two-streams-left-",
            "patched-stream-await-for-two-streams-right-",
            "patched-stream-await-for-two-streams-caught-",
            "patched-stream-await-for-two-streams-catch-finally-cleanup",
        ],
        2,
        True,
    )
    assert_async_star_stream_error_cleanup(
        "asyncGeneratedAwaitForNestedStreamCatchFinally",
        [
            "patched-stream-await-for-nested-stream-catch-",
            "patched-stream-await-for-nested-stream-caught-",
            "patched-stream-await-for-nested-stream-catch-cleanup",
        ],
        2,
        True,
    )
    assert_async_star_stream_error_cleanup(
        "asyncGeneratedAwaitForNestedStreamBreakContinueCatchFinally",
        [
            "patched-stream-await-for-nested-stream-break-continue-catch-",
            "patched-stream-await-for-nested-stream-break-continue-caught-",
            "patched-stream-await-for-nested-stream-break-continue-catch-cleanup",
            "skip",
            "stop",
        ],
        2,
        True,
    )
    assert_async_star_stream_error_cleanup(
        "asyncGeneratedAwaitForTripleNestedStreamCatchFinally",
        [
            "patched-stream-await-for-triple-nested-catch-",
            "patched-stream-await-for-triple-nested-caught-",
            "patched-stream-await-for-triple-nested-catch-cleanup",
            "skip",
            "stop-middle",
        ],
        3,
        True,
    )
    assert_async_star_finite_stream_error_cleanup(
        "asyncGeneratedAwaitForFromIterableCatchFinally",
        [
            "patched-stream-await-for-iterable-catch-",
            "patched-stream-await-for-iterable-caught-",
            "patched-stream-await-for-iterable-catch-cleanup",
        ],
    )
    assert_async_star_finite_stream_error_cleanup(
        "asyncGeneratedAwaitForFutureCatchFinally",
        [
            "patched-stream-await-for-future-catch-",
            "patched-stream-await-for-future-catch-item-",
            "patched-stream-await-for-future-caught-",
            "patched-stream-await-for-future-catch-cleanup",
        ],
    )
    assert_async_star_finite_stream_error_cleanup(
        "asyncGeneratedAwaitForPendingFutureCatchFinally",
        [
            "patched-stream-await-for-pending-catch-",
            "patched-stream-await-for-pending-caught-",
            "patched-stream-await-for-pending-catch-cleanup",
        ],
    )
    assert_async_star_finite_stream_error_cleanup(
        "asyncGeneratedAwaitForValueCatchFinally",
        [
            "patched-stream-await-for-value-catch-",
            "patched-stream-await-for-value-caught-",
            "patched-stream-await-for-value-catch-cleanup",
        ],
    )
    assert_async_star_finite_stream_error_cleanup(
        "asyncGeneratedAwaitForEmptyCatchFinally",
        [
            "patched-stream-await-for-empty-catch-",
            "patched-stream-await-for-empty-caught-",
            "patched-stream-await-for-empty-catch-cleanup",
        ],
    )
    assert_async_star_finite_stream_error_cleanup(
        "asyncGeneratedAwaitForFutureBreakCatchFinally",
        [
            "patched-stream-await-for-future-break-catch-",
            "patched-stream-await-for-future-break-caught-",
            "patched-stream-await-for-future-break-catch-cleanup",
            "stop",
        ],
    )
    assert_async_star_finite_stream_error_cleanup(
        "asyncGeneratedAwaitForPendingContinueCatchFinally",
        [
            "patched-stream-await-for-pending-continue-catch-",
            "patched-stream-await-for-pending-continue-caught-",
            "patched-stream-await-for-pending-continue-catch-cleanup",
            "skip",
        ],
    )
    async_generated_await_for_nested = next(
        item
        for item in module["functions"]
        if item["name"].endswith("::asyncGeneratedAwaitForNestedValueFinally")
    )
    assert async_generated_await_for_nested.get("async_kind") == "async_star", async_generated_await_for_nested
    assert 0x55 in async_generated_await_for_nested["code"], async_generated_await_for_nested
    assert 0x62 in async_generated_await_for_nested["code"], async_generated_await_for_nested
    assert async_generated_await_for_nested["code"].count(0x64) == 2, async_generated_await_for_nested
    assert async_generated_await_for_nested["code"].count(0x65) >= 2, async_generated_await_for_nested
    assert async_generated_await_for_nested["code"].count(0x66) >= 2, async_generated_await_for_nested
    assert 0x51 in async_generated_await_for_nested["code"], async_generated_await_for_nested
    assert any(
        constant.get("type") == "String" and constant.get("value") == "-inner"
        for constant in async_generated_await_for_nested["constants"]
    ), async_generated_await_for_nested
    assert any(
        constant.get("type") == "String" and constant.get("value") == "patched-stream-await-for-nested-"
        for constant in async_generated_await_for_nested["constants"]
    ), async_generated_await_for_nested
    assert any(
        constant.get("type") == "String" and constant.get("value") == "patched-stream-await-for-nested-cleanup"
        for constant in async_generated_await_for_nested["constants"]
    ), async_generated_await_for_nested
    async_generated_await_for_nested_stream = next(
        item
        for item in module["functions"]
        if item["name"].endswith("::asyncGeneratedAwaitForNestedStreamFinally")
    )
    assert async_generated_await_for_nested_stream.get("async_kind") == "async_star", async_generated_await_for_nested_stream
    assert async_generated_await_for_nested_stream["code"].count(0x55) >= 2, async_generated_await_for_nested_stream
    assert async_generated_await_for_nested_stream["code"].count(0x62) >= 2, async_generated_await_for_nested_stream
    assert async_generated_await_for_nested_stream["code"].count(0x64) == 2, async_generated_await_for_nested_stream
    assert async_generated_await_for_nested_stream["code"].count(0x65) >= 3, async_generated_await_for_nested_stream
    assert async_generated_await_for_nested_stream["code"].count(0x66) >= 3, async_generated_await_for_nested_stream
    assert any(
        constant.get("type") == "String" and constant.get("value") == "patched-stream-await-for-nested-stream-"
        for constant in async_generated_await_for_nested_stream["constants"]
    ), async_generated_await_for_nested_stream
    assert any(
        constant.get("type") == "String" and constant.get("value") == "patched-stream-await-for-nested-stream-cleanup"
        for constant in async_generated_await_for_nested_stream["constants"]
    ), async_generated_await_for_nested_stream
    async_generated_await_for_nested_stream_break_continue = next(
        item
        for item in module["functions"]
        if item["name"].endswith("::asyncGeneratedAwaitForNestedStreamBreakContinueFinally")
    )
    assert async_generated_await_for_nested_stream_break_continue.get("async_kind") == "async_star", async_generated_await_for_nested_stream_break_continue
    assert async_generated_await_for_nested_stream_break_continue["code"].count(0x55) >= 2, async_generated_await_for_nested_stream_break_continue
    assert async_generated_await_for_nested_stream_break_continue["code"].count(0x62) >= 2, async_generated_await_for_nested_stream_break_continue
    assert async_generated_await_for_nested_stream_break_continue["code"].count(0x64) == 2, async_generated_await_for_nested_stream_break_continue
    assert async_generated_await_for_nested_stream_break_continue["code"].count(0x65) >= 3, async_generated_await_for_nested_stream_break_continue
    assert async_generated_await_for_nested_stream_break_continue["code"].count(0x66) >= 3, async_generated_await_for_nested_stream_break_continue
    assert 0x30 in async_generated_await_for_nested_stream_break_continue["code"], async_generated_await_for_nested_stream_break_continue
    assert 0x31 in async_generated_await_for_nested_stream_break_continue["code"], async_generated_await_for_nested_stream_break_continue
    assert any(
        constant.get("type") == "String" and constant.get("value") == "patched-stream-await-for-nested-stream-break-continue-"
        for constant in async_generated_await_for_nested_stream_break_continue["constants"]
    ), async_generated_await_for_nested_stream_break_continue
    assert any(
        constant.get("type") == "String" and constant.get("value") == "patched-stream-await-for-nested-stream-break-continue-cleanup"
        for constant in async_generated_await_for_nested_stream_break_continue["constants"]
    ), async_generated_await_for_nested_stream_break_continue
    async_generated_await_for_triple_nested_stream = next(
        item
        for item in module["functions"]
        if item["name"].endswith("::asyncGeneratedAwaitForTripleNestedStreamFinally")
    )
    assert async_generated_await_for_triple_nested_stream.get("async_kind") == "async_star", async_generated_await_for_triple_nested_stream
    assert async_generated_await_for_triple_nested_stream["code"].count(0x55) >= 3, async_generated_await_for_triple_nested_stream
    assert async_generated_await_for_triple_nested_stream["code"].count(0x62) >= 3, async_generated_await_for_triple_nested_stream
    assert async_generated_await_for_triple_nested_stream["code"].count(0x64) == 2, async_generated_await_for_triple_nested_stream
    assert async_generated_await_for_triple_nested_stream["code"].count(0x65) >= 4, async_generated_await_for_triple_nested_stream
    assert async_generated_await_for_triple_nested_stream["code"].count(0x66) >= 4, async_generated_await_for_triple_nested_stream
    assert 0x30 in async_generated_await_for_triple_nested_stream["code"], async_generated_await_for_triple_nested_stream
    assert 0x31 in async_generated_await_for_triple_nested_stream["code"], async_generated_await_for_triple_nested_stream
    assert any(
        constant.get("type") == "String" and constant.get("value") == "patched-stream-await-for-triple-nested-"
        for constant in async_generated_await_for_triple_nested_stream["constants"]
    ), async_generated_await_for_triple_nested_stream
    assert any(
        constant.get("type") == "String" and constant.get("value") == "patched-stream-await-for-triple-nested-cleanup"
        for constant in async_generated_await_for_triple_nested_stream["constants"]
    ), async_generated_await_for_triple_nested_stream
