from assert_module_async_branch import assert_async_branch_module
from assert_module_async_loops import assert_async_loop_module


def assert_async_future_module(module):
    async_label = next(
        item for item in module["functions"] if item["name"].endswith("::asyncLabel")
    )
    assert async_label.get("async_kind") == "async_future", async_label
    assert 0x55 in async_label["code"], async_label
    assert any(
        constant.get("type") == "String"
        and constant.get("value") == "dart:async::class:_Future.value;types:String"
        for constant in async_label["constants"]
    ), async_label
    assert any(
        constant.get("type") == "String" and constant.get("value") == "patched-async"
        for constant in async_label["constants"]
    ), async_label
    awaited_void = next(
        item for item in module["functions"] if item["name"].endswith("::awaitedVoid")
    )
    assert awaited_void.get("async_kind") == "async_future", awaited_void
    assert 0x62 in awaited_void["code"], awaited_void
    assert 0x05 in awaited_void["code"], awaited_void
    assert 0x04 in awaited_void["code"], awaited_void
    assert 0x63 in awaited_void["code"], awaited_void
    awaited_void_names = {entry.get("name") for entry in awaited_void.get("debug_locals", [])}
    assert {"ready", "marker"}.issubset(awaited_void_names), awaited_void
    awaited_return_void = next(
        item for item in module["functions"] if item["name"].endswith("::awaitedReturnVoid")
    )
    assert awaited_return_void.get("async_kind") == "async_future", awaited_return_void
    assert 0x62 in awaited_return_void["code"], awaited_return_void
    assert 0x05 in awaited_return_void["code"], awaited_return_void
    assert 0x04 in awaited_return_void["code"], awaited_return_void
    assert 0x63 in awaited_return_void["code"], awaited_return_void
    awaited_return_void_names = {
        entry.get("name") for entry in awaited_return_void.get("debug_locals", [])
    }
    assert {"ready", "marker"}.issubset(awaited_return_void_names), awaited_return_void
    awaited_label = next(
        item for item in module["functions"] if item["name"].endswith("::awaitedLabel")
    )
    assert awaited_label.get("async_kind") == "async_future", awaited_label
    assert 0x55 in awaited_label["code"] and 0x42 in awaited_label["code"] and 0x31 in awaited_label["code"], awaited_label
    assert {"slot": 0, "name": "enabled"} in awaited_label.get("debug_locals", []), awaited_label
    awaited_local = next(item for item in module["functions"] if item["name"].endswith("::awaitedLocalLabel"))
    assert awaited_local.get("async_kind") == "async_future", awaited_local
    assert 0x55 in awaited_local["code"] and awaited_local["code"].count(0x04) >= 2 and 0x31 in awaited_local["code"] and 0x42 in awaited_local["code"] and 0x61 in awaited_local["code"], awaited_local
    awaited_local_debug_names = {
        entry.get("name") for entry in awaited_local.get("debug_locals", [])
    }
    assert {"name", "base", "prefix"}.issubset(awaited_local_debug_names), awaited_local
    awaited_future_param = next(
        item for item in module["functions"] if item["name"].endswith("::awaitedFutureParam")
    )
    assert awaited_future_param.get("async_kind") == "async_future", awaited_future_param
    assert 0x62 in awaited_future_param["code"], awaited_future_param
    assert 0x63 in awaited_future_param["code"], awaited_future_param
    assert {"slot": 0, "name": "value"} in awaited_future_param.get("debug_locals", []), awaited_future_param
    awaited_statement = next(
        item for item in module["functions"] if item["name"].endswith("::awaitedStatement")
    )
    assert awaited_statement.get("async_kind") == "async_future", awaited_statement
    assert 0x62 in awaited_statement["code"], awaited_statement
    assert 0x05 in awaited_statement["code"], awaited_statement
    assert 0x63 in awaited_statement["code"], awaited_statement
    assert {"slot": 0, "name": "ready"} in awaited_statement.get("debug_locals", []), awaited_statement
    awaited_statement_local = next(
        item for item in module["functions"] if item["name"].endswith("::awaitedStatementLocal")
    )
    assert awaited_statement_local.get("async_kind") == "async_future", awaited_statement_local
    assert 0x62 in awaited_statement_local["code"], awaited_statement_local
    assert 0x05 in awaited_statement_local["code"], awaited_statement_local
    assert 0x04 in awaited_statement_local["code"], awaited_statement_local
    assert 0x63 in awaited_statement_local["code"], awaited_statement_local
    awaited_statement_local_names = {
        entry.get("name") for entry in awaited_statement_local.get("debug_locals", [])
    }
    assert {"ready", "marker"}.issubset(awaited_statement_local_names), awaited_statement_local
    awaited_try_statement_local = next(
        item for item in module["functions"] if item["name"].endswith("::awaitedTryStatementLocal")
    )
    assert awaited_try_statement_local.get("async_kind") == "async_future", awaited_try_statement_local
    assert 0x61 in awaited_try_statement_local["code"], awaited_try_statement_local
    assert 0x62 in awaited_try_statement_local["code"], awaited_try_statement_local
    assert 0x05 in awaited_try_statement_local["code"], awaited_try_statement_local
    assert 0x04 in awaited_try_statement_local["code"], awaited_try_statement_local
    assert 0x63 in awaited_try_statement_local["code"], awaited_try_statement_local
    awaited_try_statement_local_names = {
        entry.get("name") for entry in awaited_try_statement_local.get("debug_locals", [])
    }
    assert {"ready", "marker"}.issubset(awaited_try_statement_local_names), awaited_try_statement_local
    awaited_catch_local = next(
        item for item in module["functions"] if item["name"].endswith("::awaitedCatchLocal")
    )
    assert awaited_catch_local.get("async_kind") == "async_future", awaited_catch_local
    assert 0x61 in awaited_catch_local["code"], awaited_catch_local
    assert 0x62 in awaited_catch_local["code"], awaited_catch_local
    assert 0x04 in awaited_catch_local["code"], awaited_catch_local
    assert 0x63 in awaited_catch_local["code"], awaited_catch_local
    awaited_catch_local_names = {
        entry.get("name") for entry in awaited_catch_local.get("debug_locals", [])
    }
    assert {"ready", "message"}.issubset(awaited_catch_local_names), awaited_catch_local
    awaited_catch_await = next(
        item for item in module["functions"] if item["name"].endswith("::awaitedCatchAwait")
    )
    assert awaited_catch_await.get("async_kind") == "async_future", awaited_catch_await
    assert 0x61 in awaited_catch_await["code"], awaited_catch_await
    assert 0x62 in awaited_catch_await["code"], awaited_catch_await
    assert 0x63 in awaited_catch_await["code"], awaited_catch_await
    assert {"slot": 0, "name": "ready"} in awaited_catch_await.get("debug_locals", []), awaited_catch_await
    awaited_catch_tail = next(
        item for item in module["functions"] if item["name"].endswith("::awaitedCatchTail")
    )
    assert awaited_catch_tail.get("async_kind") == "async_future", awaited_catch_tail
    assert 0x61 in awaited_catch_tail["code"], awaited_catch_tail
    assert 0x62 in awaited_catch_tail["code"], awaited_catch_tail
    assert awaited_catch_tail["code"].count(0x04) >= 2, awaited_catch_tail
    assert 0x63 in awaited_catch_tail["code"], awaited_catch_tail
    awaited_catch_tail_names = {
        entry.get("name") for entry in awaited_catch_tail.get("debug_locals", [])
    }
    assert {"ready", "out", "value"}.issubset(awaited_catch_tail_names), awaited_catch_tail
    assert any(
        constant.get("type") == "String" and constant.get("value") == "patched-catch-tail"
        for constant in awaited_catch_tail["constants"]
    ), awaited_catch_tail
    awaited_catch_await_tail = next(
        item for item in module["functions"] if item["name"].endswith("::awaitedCatchAwaitTail")
    )
    assert awaited_catch_await_tail.get("async_kind") == "async_future", awaited_catch_await_tail
    assert 0x61 in awaited_catch_await_tail["code"], awaited_catch_await_tail
    assert awaited_catch_await_tail["code"].count(0x62) == 2, awaited_catch_await_tail
    assert awaited_catch_await_tail["code"].count(0x04) >= 3, awaited_catch_await_tail
    assert awaited_catch_await_tail["code"].count(0x03) >= 3, awaited_catch_await_tail
    assert 0x63 in awaited_catch_await_tail["code"], awaited_catch_await_tail
    awaited_catch_await_tail_names = {
        entry.get("name") for entry in awaited_catch_await_tail.get("debug_locals", [])
    }
    assert {"ready", "recovery", "out", "value", "recovered"}.issubset(
        awaited_catch_await_tail_names
    ), awaited_catch_await_tail
    for value in [
        "patched-catch-await-tail",
        "-ok-",
        "-caught-",
    ]:
        assert any(
            constant.get("type") == "String" and constant.get("value") == value
            for constant in awaited_catch_await_tail["constants"]
        ), awaited_catch_await_tail
    awaited_finally_local = next(
        item for item in module["functions"] if item["name"].endswith("::awaitedFinallyLocal")
    )
    assert awaited_finally_local.get("async_kind") == "async_future", awaited_finally_local
    assert 0x65 in awaited_finally_local["code"], awaited_finally_local
    assert 0x66 in awaited_finally_local["code"], awaited_finally_local
    assert 0x62 in awaited_finally_local["code"], awaited_finally_local
    assert 0x04 in awaited_finally_local["code"], awaited_finally_local
    assert 0x63 in awaited_finally_local["code"], awaited_finally_local
    awaited_finally_local_names = {
        entry.get("name") for entry in awaited_finally_local.get("debug_locals", [])
    }
    assert {"ready", "value", "cleanup"}.issubset(awaited_finally_local_names), awaited_finally_local
    awaited_finally_cleanup = next(
        item for item in module["functions"] if item["name"].endswith("::awaitedFinallyCleanup")
    )
    assert awaited_finally_cleanup.get("async_kind") == "async_future", awaited_finally_cleanup
    assert 0x65 in awaited_finally_cleanup["code"], awaited_finally_cleanup
    assert 0x66 in awaited_finally_cleanup["code"], awaited_finally_cleanup
    assert awaited_finally_cleanup["code"].count(0x62) == 2, awaited_finally_cleanup
    assert 0x04 in awaited_finally_cleanup["code"], awaited_finally_cleanup
    assert 0x63 in awaited_finally_cleanup["code"], awaited_finally_cleanup
    awaited_finally_cleanup_names = {
        entry.get("name") for entry in awaited_finally_cleanup.get("debug_locals", [])
    }
    assert {"ready", "cleanup", "value"}.issubset(awaited_finally_cleanup_names), awaited_finally_cleanup
    awaited_finally_statement_tail = next(
        item for item in module["functions"] if item["name"].endswith("::awaitedFinallyStatementTail")
    )
    assert awaited_finally_statement_tail.get("async_kind") == "async_future", awaited_finally_statement_tail
    assert 0x65 in awaited_finally_statement_tail["code"], awaited_finally_statement_tail
    assert 0x66 in awaited_finally_statement_tail["code"], awaited_finally_statement_tail
    assert 0x62 in awaited_finally_statement_tail["code"], awaited_finally_statement_tail
    assert awaited_finally_statement_tail["code"].count(0x04) >= 3, awaited_finally_statement_tail
    assert awaited_finally_statement_tail["code"].count(0x03) >= 2, awaited_finally_statement_tail
    assert 0x63 in awaited_finally_statement_tail["code"], awaited_finally_statement_tail
    awaited_finally_statement_tail_names = {
        entry.get("name") for entry in awaited_finally_statement_tail.get("debug_locals", [])
    }
    assert {"ready", "out", "value", "cleanup"}.issubset(
        awaited_finally_statement_tail_names
    ), awaited_finally_statement_tail
    for value in [
        "patched-finally-tail",
        "-body-",
        "patched-finally-tail-cleanup",
        "-done",
    ]:
        assert any(
            constant.get("type") == "String" and constant.get("value") == value
            for constant in awaited_finally_statement_tail["constants"]
        ), awaited_finally_statement_tail
    awaited_finally_await_cleanup_tail = next(
        item for item in module["functions"] if item["name"].endswith("::awaitedFinallyAwaitCleanupTail")
    )
    assert awaited_finally_await_cleanup_tail.get("async_kind") == "async_future", awaited_finally_await_cleanup_tail
    assert 0x65 in awaited_finally_await_cleanup_tail["code"], awaited_finally_await_cleanup_tail
    assert 0x66 in awaited_finally_await_cleanup_tail["code"], awaited_finally_await_cleanup_tail
    assert awaited_finally_await_cleanup_tail["code"].count(0x62) == 2, awaited_finally_await_cleanup_tail
    assert awaited_finally_await_cleanup_tail["code"].count(0x04) >= 3, awaited_finally_await_cleanup_tail
    assert awaited_finally_await_cleanup_tail["code"].count(0x03) >= 2, awaited_finally_await_cleanup_tail
    assert 0x63 in awaited_finally_await_cleanup_tail["code"], awaited_finally_await_cleanup_tail
    awaited_finally_await_cleanup_tail_names = {
        entry.get("name") for entry in awaited_finally_await_cleanup_tail.get("debug_locals", [])
    }
    assert {"ready", "cleanup", "out", "value", "marker"}.issubset(
        awaited_finally_await_cleanup_tail_names
    ), awaited_finally_await_cleanup_tail
    for value in [
        "patched-finally-await-tail",
        "-body-",
        "-cleanup-",
        "-done",
    ]:
        assert any(
            constant.get("type") == "String" and constant.get("value") == value
            for constant in awaited_finally_await_cleanup_tail["constants"]
        ), awaited_finally_await_cleanup_tail
    awaited_catch_finally_cleanup = next(
        item for item in module["functions"] if item["name"].endswith("::awaitedCatchFinallyCleanup")
    )
    assert awaited_catch_finally_cleanup.get("async_kind") == "async_future", awaited_catch_finally_cleanup
    assert 0x65 in awaited_catch_finally_cleanup["code"], awaited_catch_finally_cleanup
    assert 0x66 in awaited_catch_finally_cleanup["code"], awaited_catch_finally_cleanup
    assert 0x61 in awaited_catch_finally_cleanup["code"], awaited_catch_finally_cleanup
    assert awaited_catch_finally_cleanup["code"].count(0x62) == 2, awaited_catch_finally_cleanup
    assert 0x04 in awaited_catch_finally_cleanup["code"], awaited_catch_finally_cleanup
    assert 0x03 in awaited_catch_finally_cleanup["code"], awaited_catch_finally_cleanup
    assert 0x63 in awaited_catch_finally_cleanup["code"], awaited_catch_finally_cleanup
    awaited_catch_finally_cleanup_names = {
        entry.get("name") for entry in awaited_catch_finally_cleanup.get("debug_locals", [])
    }
    assert {"ready", "cleanup", "value"}.issubset(
        awaited_catch_finally_cleanup_names,
    ), awaited_catch_finally_cleanup
    awaited_catch_finally_await_tail = next(
        item for item in module["functions"] if item["name"].endswith("::awaitedCatchFinallyAwaitTail")
    )
    assert awaited_catch_finally_await_tail.get("async_kind") == "async_future", awaited_catch_finally_await_tail
    assert 0x65 in awaited_catch_finally_await_tail["code"], awaited_catch_finally_await_tail
    assert 0x66 in awaited_catch_finally_await_tail["code"], awaited_catch_finally_await_tail
    assert 0x61 in awaited_catch_finally_await_tail["code"], awaited_catch_finally_await_tail
    assert awaited_catch_finally_await_tail["code"].count(0x62) == 3, awaited_catch_finally_await_tail
    assert awaited_catch_finally_await_tail["code"].count(0x04) >= 4, awaited_catch_finally_await_tail
    assert awaited_catch_finally_await_tail["code"].count(0x03) >= 4, awaited_catch_finally_await_tail
    assert 0x63 in awaited_catch_finally_await_tail["code"], awaited_catch_finally_await_tail
    awaited_catch_finally_await_tail_names = {
        entry.get("name") for entry in awaited_catch_finally_await_tail.get("debug_locals", [])
    }
    assert {"ready", "recovery", "cleanup", "out", "value", "recovered", "marker"}.issubset(
        awaited_catch_finally_await_tail_names
    ), awaited_catch_finally_await_tail
    for value in [
        "patched-catch-finally-await-tail",
        "-ok-",
        "-caught-",
        "-cleanup-",
    ]:
        assert any(
            constant.get("type") == "String" and constant.get("value") == value
            for constant in awaited_catch_finally_await_tail["constants"]
        ), awaited_catch_finally_await_tail
    assert_async_branch_module(module)
    async_conditional_await = next(
        item for item in module["functions"] if item["name"].endswith("::asyncConditionalAwaitExpr")
    )
    assert async_conditional_await.get("async_kind") == "async_future", async_conditional_await
    assert 0x31 in async_conditional_await["code"], async_conditional_await
    assert 0x62 in async_conditional_await["code"], async_conditional_await
    assert 0x63 in async_conditional_await["code"], async_conditional_await
    async_conditional_await_names = {
        entry.get("name") for entry in async_conditional_await.get("debug_locals", [])
    }
    assert {"enabled", "ready"}.issubset(
        async_conditional_await_names
    ), async_conditional_await
    assert any(
        constant.get("type") == "String" and constant.get("value") == "patched-conditional-disabled"
        for constant in async_conditional_await["constants"]
    ), async_conditional_await
    async_less_than_await = next(
        item for item in module["functions"] if item["name"].endswith("::asyncLessThanAwaitTail")
    )
    assert async_less_than_await.get("async_kind") == "async_future", async_less_than_await
    assert 0x31 in async_less_than_await["code"], async_less_than_await
    assert 0x62 in async_less_than_await["code"], async_less_than_await
    assert 0x63 in async_less_than_await["code"], async_less_than_await
    async_less_than_await_names = {
        entry.get("name") for entry in async_less_than_await.get("debug_locals", [])
    }
    assert {"limit", "ready"}.issubset(async_less_than_await_names), async_less_than_await
    assert any(
        constant.get("type") == "String" and constant.get("value") == "patched-less-than-tail"
        for constant in async_less_than_await["constants"]
    ), async_less_than_await
    async_less_equal_await = next(
        item for item in module["functions"] if item["name"].endswith("::asyncLessEqualAwaitTail")
    )
    assert async_less_equal_await.get("async_kind") == "async_future", async_less_equal_await
    assert 0x31 in async_less_equal_await["code"], async_less_equal_await
    assert 0x62 in async_less_equal_await["code"], async_less_equal_await
    assert 0x63 in async_less_equal_await["code"], async_less_equal_await
    assert any(
        constant.get("type") == "String" and constant.get("value") == "patched-less-equal-tail"
        for constant in async_less_equal_await["constants"]
    ), async_less_equal_await
    async_greater_equal_await = next(
        item for item in module["functions"] if item["name"].endswith("::asyncGreaterEqualAwaitTail")
    )
    assert async_greater_equal_await.get("async_kind") == "async_future", async_greater_equal_await
    assert async_greater_equal_await["code"].count(0x31) >= 2, async_greater_equal_await
    assert 0x62 in async_greater_equal_await["code"], async_greater_equal_await
    assert 0x63 in async_greater_equal_await["code"], async_greater_equal_await
    assert any(
        constant.get("type") == "String" and constant.get("value") == "patched-greater-equal-tail"
        for constant in async_greater_equal_await["constants"]
    ), async_greater_equal_await
    async_not_equal_await = next(
        item for item in module["functions"] if item["name"].endswith("::asyncNotEqualAwaitTail")
    )
    assert async_not_equal_await.get("async_kind") == "async_future", async_not_equal_await
    assert async_not_equal_await["code"].count(0x31) >= 2, async_not_equal_await
    assert 0x62 in async_not_equal_await["code"], async_not_equal_await
    assert 0x63 in async_not_equal_await["code"], async_not_equal_await
    assert any(
        constant.get("type") == "String" and constant.get("value") == "patched-not-equal-tail"
        for constant in async_not_equal_await["constants"]
    ), async_not_equal_await
    async_guard_tail = next(
        item for item in module["functions"] if item["name"].endswith("::asyncGuardAwaitTail")
    )
    assert async_guard_tail.get("async_kind") == "async_future", async_guard_tail
    assert 0x31 in async_guard_tail["code"], async_guard_tail
    assert 0x62 in async_guard_tail["code"], async_guard_tail
    assert 0x05 in async_guard_tail["code"], async_guard_tail
    assert 0x63 in async_guard_tail["code"], async_guard_tail
    async_guard_tail_names = {
        entry.get("name") for entry in async_guard_tail.get("debug_locals", [])
    }
    assert {"enabled", "ready"}.issubset(async_guard_tail_names), async_guard_tail
    planned_async = next(
        item for item in module["functions"] if item["name"].endswith("::plannedAsyncAwait")
    )
    assert planned_async.get("async_kind") == "async_future", planned_async
    assert 0x62 in planned_async["code"], planned_async
    assert 0x04 in planned_async["code"], planned_async
    assert 0x31 in planned_async["code"], planned_async
    assert 0x63 in planned_async["code"], planned_async
    planned_debug_names = {entry.get("name") for entry in planned_async.get("debug_locals", [])}
    assert "x" in planned_debug_names, planned_async
    assert_async_loop_module(module)
