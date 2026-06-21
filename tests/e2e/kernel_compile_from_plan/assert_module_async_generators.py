from assert_module_dynamic_for_in import assert_dynamic_for_in
from assert_module_stream_generators import assert_stream_generators

def assert_async_generators(module):
    function = next(
        item for item in module["functions"] if item["name"].endswith("::mainValue")
    )
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
    async_branch_local = next(
        item for item in module["functions"] if item["name"].endswith("::asyncBranchLocal")
    )
    assert async_branch_local.get("async_kind") == "async_future", async_branch_local
    assert 0x31 in async_branch_local["code"], async_branch_local
    assert async_branch_local["code"].count(0x04) >= 2, async_branch_local
    assert 0x63 in async_branch_local["code"], async_branch_local
    async_branch_local_names = {
        entry.get("name") for entry in async_branch_local.get("debug_locals", [])
    }
    assert {"enabled", "status"}.issubset(async_branch_local_names), async_branch_local
    async_nested_branch_local = next(
        item for item in module["functions"] if item["name"].endswith("::asyncNestedBranchLocal")
    )
    assert async_nested_branch_local.get("async_kind") == "async_future", async_nested_branch_local
    assert async_nested_branch_local["code"].count(0x31) >= 2, async_nested_branch_local
    assert async_nested_branch_local["code"].count(0x04) >= 6, async_nested_branch_local
    assert 0x42 in async_nested_branch_local["code"], async_nested_branch_local
    assert 0x63 in async_nested_branch_local["code"], async_nested_branch_local
    async_nested_branch_local_names = {
        entry.get("name") for entry in async_nested_branch_local.get("debug_locals", [])
    }
    assert {"enabled", "premium", "state", "tier"}.issubset(
        async_nested_branch_local_names
    ), async_nested_branch_local
    assert any(
        constant.get("type") == "String" and constant.get("value") == "patched-nested-disabled-basic"
        for constant in async_nested_branch_local["constants"]
    ), async_nested_branch_local
    async_nested_await_branch_local = next(
        item for item in module["functions"] if item["name"].endswith("::asyncNestedAwaitBranchLocal")
    )
    assert async_nested_await_branch_local.get("async_kind") == "async_future", async_nested_await_branch_local
    assert async_nested_await_branch_local["code"].count(0x31) >= 2, async_nested_await_branch_local
    assert async_nested_await_branch_local["code"].count(0x62) == 2, async_nested_await_branch_local
    assert 0x42 in async_nested_await_branch_local["code"], async_nested_await_branch_local
    assert 0x63 in async_nested_await_branch_local["code"], async_nested_await_branch_local
    async_nested_await_branch_local_names = {
        entry.get("name") for entry in async_nested_await_branch_local.get("debug_locals", [])
    }
    assert {"enabled", "premium", "ready", "state", "tier"}.issubset(
        async_nested_await_branch_local_names
    ), async_nested_await_branch_local
    assert any(
        constant.get("type") == "String" and constant.get("value") == "patched-nested-await-disabled-basic"
        for constant in async_nested_await_branch_local["constants"]
    ), async_nested_await_branch_local
    async_ifelse_side_effect = next(
        item for item in module["functions"] if item["name"].endswith("::asyncIfElseSideEffectTail")
    )
    assert async_ifelse_side_effect.get("async_kind") == "async_future", async_ifelse_side_effect
    assert 0x31 in async_ifelse_side_effect["code"], async_ifelse_side_effect
    assert 0x62 in async_ifelse_side_effect["code"], async_ifelse_side_effect
    assert async_ifelse_side_effect["code"].count(0x04) >= 4, async_ifelse_side_effect
    assert 0x63 in async_ifelse_side_effect["code"], async_ifelse_side_effect
    async_ifelse_side_effect_names = {
        entry.get("name") for entry in async_ifelse_side_effect.get("debug_locals", [])
    }
    assert {"enabled", "ready", "out", "state"}.issubset(
        async_ifelse_side_effect_names
    ), async_ifelse_side_effect
    for value in [
        "patched-ifelse-side-effect",
        "patched-ifelse-disabled",
        "-tail",
    ]:
        assert any(
            constant.get("type") == "String" and constant.get("value") == value
            for constant in async_ifelse_side_effect["constants"]
        ), async_ifelse_side_effect
    async_if_side_effect = next(
        item for item in module["functions"] if item["name"].endswith("::asyncIfSideEffectTail")
    )
    assert async_if_side_effect.get("async_kind") == "async_future", async_if_side_effect
    assert 0x31 in async_if_side_effect["code"], async_if_side_effect
    assert 0x62 in async_if_side_effect["code"], async_if_side_effect
    assert async_if_side_effect["code"].count(0x04) >= 3, async_if_side_effect
    assert 0x63 in async_if_side_effect["code"], async_if_side_effect
    async_if_side_effect_names = {
        entry.get("name") for entry in async_if_side_effect.get("debug_locals", [])
    }
    assert {"enabled", "ready", "out", "state"}.issubset(
        async_if_side_effect_names
    ), async_if_side_effect
    for value in ["patched-if-side-effect", "-tail"]:
        assert any(
            constant.get("type") == "String" and constant.get("value") == value
            for constant in async_if_side_effect["constants"]
        ), async_if_side_effect
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
    async_while_local = next(
        item for item in module["functions"] if item["name"].endswith("::asyncWhileLocal")
    )
    assert async_while_local.get("async_kind") == "async_future", async_while_local
    assert 0x31 in async_while_local["code"], async_while_local
    assert 0x30 in async_while_local["code"], async_while_local
    assert async_while_local["code"].count(0x04) >= 4, async_while_local
    assert 0x63 in async_while_local["code"], async_while_local
    async_while_local_names = {
        entry.get("name") for entry in async_while_local.get("debug_locals", [])
    }
    assert {"limit", "i", "out"}.issubset(async_while_local_names), async_while_local
    async_while_break = next(
        item for item in module["functions"] if item["name"].endswith("::asyncWhileBreak")
    )
    assert async_while_break.get("async_kind") == "async_future", async_while_break
    assert 0x31 in async_while_break["code"], async_while_break
    assert 0x30 in async_while_break["code"], async_while_break
    assert async_while_break["code"].count(0x04) >= 4, async_while_break
    assert 0x63 in async_while_break["code"], async_while_break
    async_while_break_names = {
        entry.get("name") for entry in async_while_break.get("debug_locals", [])
    }
    assert {"limit", "i", "out"}.issubset(async_while_break_names), async_while_break
    async_while_continue = next(
        item for item in module["functions"] if item["name"].endswith("::asyncWhileContinue")
    )
    assert async_while_continue.get("async_kind") == "async_future", async_while_continue
    assert 0x31 in async_while_continue["code"], async_while_continue
    assert 0x30 in async_while_continue["code"], async_while_continue
    assert async_while_continue["code"].count(0x04) >= 5, async_while_continue
    assert 0x63 in async_while_continue["code"], async_while_continue
    async_while_continue_names = {
        entry.get("name") for entry in async_while_continue.get("debug_locals", [])
    }
    assert {"limit", "i", "out"}.issubset(async_while_continue_names), async_while_continue
    async_while_continue_break = next(
        item for item in module["functions"] if item["name"].endswith("::asyncWhileContinueBreak")
    )
    assert async_while_continue_break.get("async_kind") == "async_future", async_while_continue_break
    assert 0x31 in async_while_continue_break["code"], async_while_continue_break
    assert 0x30 in async_while_continue_break["code"], async_while_continue_break
    assert async_while_continue_break["code"].count(0x04) >= 7, async_while_continue_break
    assert 0x63 in async_while_continue_break["code"], async_while_continue_break
    async_while_continue_break_names = {
        entry.get("name") for entry in async_while_continue_break.get("debug_locals", [])
    }
    assert {"limit", "i", "out"}.issubset(async_while_continue_break_names), async_while_continue_break
    async_while_await_continue_break = next(
        item for item in module["functions"] if item["name"].endswith("::asyncWhileAwaitContinueBreak")
    )
    assert async_while_await_continue_break.get("async_kind") == "async_future", async_while_await_continue_break
    assert 0x31 in async_while_await_continue_break["code"], async_while_await_continue_break
    assert 0x30 in async_while_await_continue_break["code"], async_while_await_continue_break
    assert async_while_await_continue_break["code"].count(0x62) >= 2, async_while_await_continue_break
    assert async_while_await_continue_break["code"].count(0x04) >= 7, async_while_await_continue_break
    assert 0x63 in async_while_await_continue_break["code"], async_while_await_continue_break
    async_while_await_continue_break_names = {
        entry.get("name") for entry in async_while_await_continue_break.get("debug_locals", [])
    }
    assert {
        "limit",
        "skip",
        "stop",
        "i",
        "out",
    }.issubset(async_while_await_continue_break_names), async_while_await_continue_break
    async_while_await_condition = next(
        item for item in module["functions"] if item["name"].endswith("::asyncWhileAwaitCondition")
    )
    assert async_while_await_condition.get("async_kind") == "async_future", async_while_await_condition
    assert 0x31 in async_while_await_condition["code"], async_while_await_condition
    assert 0x30 in async_while_await_condition["code"], async_while_await_condition
    assert 0x62 in async_while_await_condition["code"], async_while_await_condition
    assert 0x63 in async_while_await_condition["code"], async_while_await_condition
    async_while_await_condition_names = {
        entry.get("name") for entry in async_while_await_condition.get("debug_locals", [])
    }
    assert {"keepGoing", "i", "out"}.issubset(async_while_await_condition_names), async_while_await_condition
    assert any(
        constant.get("type") == "String" and constant.get("value") == "patched-while-await-condition"
        for constant in async_while_await_condition["constants"]
    ), async_while_await_condition
    async_while_nested_branch = next(
        item for item in module["functions"] if item["name"].endswith("::asyncWhileNestedAwaitBranchLocal")
    )
    assert async_while_nested_branch.get("async_kind") == "async_future", async_while_nested_branch
    assert 0x31 in async_while_nested_branch["code"], async_while_nested_branch
    assert 0x30 in async_while_nested_branch["code"], async_while_nested_branch
    assert 0x62 in async_while_nested_branch["code"], async_while_nested_branch
    assert async_while_nested_branch["code"].count(0x04) >= 8, async_while_nested_branch
    assert 0x63 in async_while_nested_branch["code"], async_while_nested_branch
    async_while_nested_branch_names = {
        entry.get("name") for entry in async_while_nested_branch.get("debug_locals", [])
    }
    assert {
        "limit",
        "premium",
        "ready",
        "i",
        "out",
        "state",
        "tier",
    }.issubset(async_while_nested_branch_names), async_while_nested_branch
    for value in [
        "patched-while-nested-await-branch",
        "patched-while-nested-pro",
        "patched-while-nested-basic",
        "patched-while-nested-tail",
    ]:
        assert any(
            constant.get("type") == "String" and constant.get("value") == value
            for constant in async_while_nested_branch["constants"]
        ), async_while_nested_branch
    async_do_while_local = next(
        item for item in module["functions"] if item["name"].endswith("::asyncDoWhileLocal")
    )
    assert async_do_while_local.get("async_kind") == "async_future", async_do_while_local
    assert 0x31 in async_do_while_local["code"], async_do_while_local
    assert 0x30 in async_do_while_local["code"], async_do_while_local
    assert async_do_while_local["code"].count(0x04) >= 4, async_do_while_local
    assert 0x63 in async_do_while_local["code"], async_do_while_local
    async_do_while_local_names = {
        entry.get("name") for entry in async_do_while_local.get("debug_locals", [])
    }
    assert {"limit", "i", "out"}.issubset(async_do_while_local_names), async_do_while_local
    assert any(
        constant.get("type") == "String" and constant.get("value") == "patched-do-while"
        for constant in async_do_while_local["constants"]
    ), async_do_while_local
    async_do_while_await = next(
        item for item in module["functions"] if item["name"].endswith("::asyncDoWhileAwaitCondition")
    )
    assert async_do_while_await.get("async_kind") == "async_future", async_do_while_await
    assert 0x31 in async_do_while_await["code"], async_do_while_await
    assert 0x30 in async_do_while_await["code"], async_do_while_await
    assert 0x62 in async_do_while_await["code"], async_do_while_await
    assert async_do_while_await["code"].count(0x04) >= 4, async_do_while_await
    assert 0x63 in async_do_while_await["code"], async_do_while_await
    async_do_while_await_names = {
        entry.get("name") for entry in async_do_while_await.get("debug_locals", [])
    }
    assert {"keepGoing", "i", "out"}.issubset(async_do_while_await_names), async_do_while_await
    assert any(
        constant.get("type") == "String" and constant.get("value") == "patched-do-while-await"
        for constant in async_do_while_await["constants"]
    ), async_do_while_await
    async_do_while_branch = next(
        item for item in module["functions"] if item["name"].endswith("::asyncDoWhileBranchLocal")
    )
    assert async_do_while_branch.get("async_kind") == "async_future", async_do_while_branch
    assert 0x31 in async_do_while_branch["code"], async_do_while_branch
    assert 0x30 in async_do_while_branch["code"], async_do_while_branch
    assert async_do_while_branch["code"].count(0x04) >= 6, async_do_while_branch
    assert 0x63 in async_do_while_branch["code"], async_do_while_branch
    async_do_while_branch_names = {
        entry.get("name") for entry in async_do_while_branch.get("debug_locals", [])
    }
    assert {"limit", "i", "out", "segment"}.issubset(async_do_while_branch_names), async_do_while_branch
    assert any(
        constant.get("type") == "String" and constant.get("value") == "patched-do-while-branch"
        for constant in async_do_while_branch["constants"]
    ), async_do_while_branch
    async_do_while_break = next(
        item for item in module["functions"] if item["name"].endswith("::asyncDoWhileBreak")
    )
    assert async_do_while_break.get("async_kind") == "async_future", async_do_while_break
    assert async_do_while_break["code"].count(0x31) >= 2, async_do_while_break
    assert async_do_while_break["code"].count(0x30) >= 2, async_do_while_break
    assert async_do_while_break["code"].count(0x04) >= 6, async_do_while_break
    assert 0x63 in async_do_while_break["code"], async_do_while_break
    async_do_while_break_names = {
        entry.get("name") for entry in async_do_while_break.get("debug_locals", [])
    }
    assert {"limit", "i", "out"}.issubset(async_do_while_break_names), async_do_while_break
    assert any(
        constant.get("type") == "String" and constant.get("value") == "patched-do-while-break"
        for constant in async_do_while_break["constants"]
    ), async_do_while_break
    async_do_while_continue_break = next(
        item for item in module["functions"] if item["name"].endswith("::asyncDoWhileContinueBreak")
    )
    assert async_do_while_continue_break.get("async_kind") == "async_future", async_do_while_continue_break
    assert async_do_while_continue_break["code"].count(0x31) >= 3, async_do_while_continue_break
    assert async_do_while_continue_break["code"].count(0x30) >= 3, async_do_while_continue_break
    assert async_do_while_continue_break["code"].count(0x04) >= 8, async_do_while_continue_break
    assert 0x63 in async_do_while_continue_break["code"], async_do_while_continue_break
    async_do_while_continue_break_names = {
        entry.get("name") for entry in async_do_while_continue_break.get("debug_locals", [])
    }
    assert {"limit", "i", "out"}.issubset(async_do_while_continue_break_names), async_do_while_continue_break
    assert any(
        constant.get("type") == "String" and constant.get("value") == "patched-do-while-continue-break"
        for constant in async_do_while_continue_break["constants"]
    ), async_do_while_continue_break
    async_do_while_await_guard_continue_break = next(
        item for item in module["functions"] if item["name"].endswith("::asyncDoWhileAwaitGuardContinueBreak")
    )
    assert async_do_while_await_guard_continue_break.get("async_kind") == "async_future", async_do_while_await_guard_continue_break
    assert async_do_while_await_guard_continue_break["code"].count(0x31) >= 3, async_do_while_await_guard_continue_break
    assert async_do_while_await_guard_continue_break["code"].count(0x30) >= 3, async_do_while_await_guard_continue_break
    assert async_do_while_await_guard_continue_break["code"].count(0x62) >= 2, async_do_while_await_guard_continue_break
    assert async_do_while_await_guard_continue_break["code"].count(0x04) >= 8, async_do_while_await_guard_continue_break
    assert 0x63 in async_do_while_await_guard_continue_break["code"], async_do_while_await_guard_continue_break
    async_do_while_await_guard_continue_break_names = {
        entry.get("name") for entry in async_do_while_await_guard_continue_break.get("debug_locals", [])
    }
    assert {
        "limit",
        "skip",
        "stop",
        "i",
        "out",
    }.issubset(async_do_while_await_guard_continue_break_names), async_do_while_await_guard_continue_break
    async_do_while_await_guard_continue_break_await_condition = next(
        item for item in module["functions"] if item["name"].endswith("::asyncDoWhileAwaitGuardContinueBreakAwaitCondition")
    )
    assert async_do_while_await_guard_continue_break_await_condition.get("async_kind") == "async_future", async_do_while_await_guard_continue_break_await_condition
    assert async_do_while_await_guard_continue_break_await_condition["code"].count(0x31) >= 3, async_do_while_await_guard_continue_break_await_condition
    assert async_do_while_await_guard_continue_break_await_condition["code"].count(0x30) >= 3, async_do_while_await_guard_continue_break_await_condition
    assert async_do_while_await_guard_continue_break_await_condition["code"].count(0x62) >= 3, async_do_while_await_guard_continue_break_await_condition
    assert async_do_while_await_guard_continue_break_await_condition["code"].count(0x04) >= 8, async_do_while_await_guard_continue_break_await_condition
    assert 0x63 in async_do_while_await_guard_continue_break_await_condition["code"], async_do_while_await_guard_continue_break_await_condition
    async_do_while_await_guard_continue_break_await_condition_names = {
        entry.get("name") for entry in async_do_while_await_guard_continue_break_await_condition.get("debug_locals", [])
    }
    assert {
        "keepGoing",
        "skip",
        "stop",
        "i",
        "out",
    }.issubset(async_do_while_await_guard_continue_break_await_condition_names), async_do_while_await_guard_continue_break_await_condition
    async_for_local = next(
        item for item in module["functions"] if item["name"].endswith("::asyncForLocal")
    )
    assert async_for_local.get("async_kind") == "async_future", async_for_local
    assert 0x31 in async_for_local["code"], async_for_local
    assert 0x30 in async_for_local["code"], async_for_local
    assert async_for_local["code"].count(0x04) >= 3, async_for_local
    assert 0x63 in async_for_local["code"], async_for_local
    async_for_local_names = {
        entry.get("name") for entry in async_for_local.get("debug_locals", [])
    }
    assert {"limit", "i", "out"}.issubset(async_for_local_names), async_for_local
    async_for_continue = next(
        item for item in module["functions"] if item["name"].endswith("::asyncForContinue")
    )
    assert async_for_continue.get("async_kind") == "async_future", async_for_continue
    assert 0x31 in async_for_continue["code"], async_for_continue
    assert 0x30 in async_for_continue["code"], async_for_continue
    assert async_for_continue["code"].count(0x04) >= 4, async_for_continue
    assert 0x63 in async_for_continue["code"], async_for_continue
    async_for_continue_names = {
        entry.get("name") for entry in async_for_continue.get("debug_locals", [])
    }
    assert {"limit", "i", "out"}.issubset(async_for_continue_names), async_for_continue
    async_for_break = next(
        item for item in module["functions"] if item["name"].endswith("::asyncForBreak")
    )
    assert async_for_break.get("async_kind") == "async_future", async_for_break
    assert 0x31 in async_for_break["code"], async_for_break
    assert 0x30 in async_for_break["code"], async_for_break
    assert async_for_break["code"].count(0x04) >= 4, async_for_break
    assert 0x63 in async_for_break["code"], async_for_break
    async_for_break_names = {
        entry.get("name") for entry in async_for_break.get("debug_locals", [])
    }
    assert {"limit", "i", "out"}.issubset(async_for_break_names), async_for_break
    async_for_continue_break = next(
        item for item in module["functions"] if item["name"].endswith("::asyncForContinueBreak")
    )
    assert async_for_continue_break.get("async_kind") == "async_future", async_for_continue_break
    assert 0x31 in async_for_continue_break["code"], async_for_continue_break
    assert 0x30 in async_for_continue_break["code"], async_for_continue_break
    assert async_for_continue_break["code"].count(0x04) >= 5, async_for_continue_break
    assert 0x63 in async_for_continue_break["code"], async_for_continue_break
    async_for_continue_break_names = {
        entry.get("name") for entry in async_for_continue_break.get("debug_locals", [])
    }
    assert {"limit", "i", "out"}.issubset(async_for_continue_break_names), async_for_continue_break
    async_for_await_guard_continue_break = next(
        item for item in module["functions"] if item["name"].endswith("::asyncForAwaitGuardContinueBreak")
    )
    assert async_for_await_guard_continue_break.get("async_kind") == "async_future", async_for_await_guard_continue_break
    assert 0x31 in async_for_await_guard_continue_break["code"], async_for_await_guard_continue_break
    assert 0x30 in async_for_await_guard_continue_break["code"], async_for_await_guard_continue_break
    assert async_for_await_guard_continue_break["code"].count(0x62) >= 2, async_for_await_guard_continue_break
    assert async_for_await_guard_continue_break["code"].count(0x04) >= 7, async_for_await_guard_continue_break
    assert 0x63 in async_for_await_guard_continue_break["code"], async_for_await_guard_continue_break
    async_for_await_guard_continue_break_names = {
        entry.get("name") for entry in async_for_await_guard_continue_break.get("debug_locals", [])
    }
    assert {
        "limit",
        "skip",
        "stop",
        "i",
        "out",
    }.issubset(async_for_await_guard_continue_break_names), async_for_await_guard_continue_break
    async_for_await_guard_continue_break_await_update = next(
        item for item in module["functions"] if item["name"].endswith("::asyncForAwaitGuardContinueBreakAwaitUpdate")
    )
    assert async_for_await_guard_continue_break_await_update.get("async_kind") == "async_future", async_for_await_guard_continue_break_await_update
    assert 0x31 in async_for_await_guard_continue_break_await_update["code"], async_for_await_guard_continue_break_await_update
    assert 0x30 in async_for_await_guard_continue_break_await_update["code"], async_for_await_guard_continue_break_await_update
    assert async_for_await_guard_continue_break_await_update["code"].count(0x62) >= 3, async_for_await_guard_continue_break_await_update
    assert async_for_await_guard_continue_break_await_update["code"].count(0x04) >= 7, async_for_await_guard_continue_break_await_update
    assert 0x63 in async_for_await_guard_continue_break_await_update["code"], async_for_await_guard_continue_break_await_update
    async_for_await_guard_continue_break_await_update_names = {
        entry.get("name") for entry in async_for_await_guard_continue_break_await_update.get("debug_locals", [])
    }
    assert {
        "limit",
        "skip",
        "stop",
        "next",
        "i",
        "out",
    }.issubset(async_for_await_guard_continue_break_await_update_names), async_for_await_guard_continue_break_await_update
    async_for_await_update = next(
        item for item in module["functions"] if item["name"].endswith("::asyncForAwaitUpdate")
    )
    assert async_for_await_update.get("async_kind") == "async_future", async_for_await_update
    assert 0x31 in async_for_await_update["code"], async_for_await_update
    assert 0x30 in async_for_await_update["code"], async_for_await_update
    assert 0x62 in async_for_await_update["code"], async_for_await_update
    assert 0x63 in async_for_await_update["code"], async_for_await_update
    async_for_await_update_names = {
        entry.get("name") for entry in async_for_await_update.get("debug_locals", [])
    }
    assert {"limit", "next", "i", "out"}.issubset(async_for_await_update_names), async_for_await_update
    assert any(
        constant.get("type") == "String" and constant.get("value") == "patched-for-await-update"
        for constant in async_for_await_update["constants"]
    ), async_for_await_update
    async_for_await_update_branch = next(
        item for item in module["functions"] if item["name"].endswith("::asyncForAwaitUpdateBranchLocal")
    )
    assert async_for_await_update_branch.get("async_kind") == "async_future", async_for_await_update_branch
    assert 0x31 in async_for_await_update_branch["code"], async_for_await_update_branch
    assert 0x30 in async_for_await_update_branch["code"], async_for_await_update_branch
    assert 0x62 in async_for_await_update_branch["code"], async_for_await_update_branch
    assert async_for_await_update_branch["code"].count(0x04) >= 5, async_for_await_update_branch
    assert 0x63 in async_for_await_update_branch["code"], async_for_await_update_branch
    async_for_await_update_branch_names = {
        entry.get("name") for entry in async_for_await_update_branch.get("debug_locals", [])
    }
    assert {"limit", "next", "i", "out", "segment"}.issubset(async_for_await_update_branch_names), async_for_await_update_branch
    assert any(
        constant.get("type") == "String" and constant.get("value") == "patched-for-await-update-branch"
        for constant in async_for_await_update_branch["constants"]
    ), async_for_await_update_branch
    async_for_nested_branch = next(
        item for item in module["functions"] if item["name"].endswith("::asyncForNestedAwaitBranchLocal")
    )
    assert async_for_nested_branch.get("async_kind") == "async_future", async_for_nested_branch
    assert 0x31 in async_for_nested_branch["code"], async_for_nested_branch
    assert 0x30 in async_for_nested_branch["code"], async_for_nested_branch
    assert 0x62 in async_for_nested_branch["code"], async_for_nested_branch
    assert async_for_nested_branch["code"].count(0x04) >= 8, async_for_nested_branch
    assert 0x63 in async_for_nested_branch["code"], async_for_nested_branch
    async_for_nested_branch_names = {
        entry.get("name") for entry in async_for_nested_branch.get("debug_locals", [])
    }
    assert {
        "limit",
        "premium",
        "ready",
        "i",
        "out",
        "state",
        "tier",
    }.issubset(async_for_nested_branch_names), async_for_nested_branch
    for value in [
        "patched-for-nested-await-branch",
        "patched-for-nested-pro",
        "patched-for-nested-basic",
        "patched-for-nested-tail",
    ]:
        assert any(
            constant.get("type") == "String" and constant.get("value") == value
            for constant in async_for_nested_branch["constants"]
        ), async_for_nested_branch
    async_for_await_update_nested_branch = next(
        item for item in module["functions"] if item["name"].endswith("::asyncForAwaitUpdateNestedBranchLocal")
    )
    assert async_for_await_update_nested_branch.get("async_kind") == "async_future", async_for_await_update_nested_branch
    assert 0x31 in async_for_await_update_nested_branch["code"], async_for_await_update_nested_branch
    assert 0x30 in async_for_await_update_nested_branch["code"], async_for_await_update_nested_branch
    assert async_for_await_update_nested_branch["code"].count(0x62) >= 2, async_for_await_update_nested_branch
    assert async_for_await_update_nested_branch["code"].count(0x04) >= 8, async_for_await_update_nested_branch
    assert 0x63 in async_for_await_update_nested_branch["code"], async_for_await_update_nested_branch
    async_for_await_update_nested_branch_names = {
        entry.get("name") for entry in async_for_await_update_nested_branch.get("debug_locals", [])
    }
    assert {
        "limit",
        "premium",
        "ready",
        "next",
        "i",
        "out",
        "state",
        "tier",
    }.issubset(async_for_await_update_nested_branch_names), async_for_await_update_nested_branch
    for value in [
        "patched-for-await-update-nested-branch",
        "patched-for-await-update-nested-pro",
        "patched-for-await-update-nested-basic",
        "patched-for-await-update-nested-tail",
    ]:
        assert any(
            constant.get("type") == "String" and constant.get("value") == value
            for constant in async_for_await_update_nested_branch["constants"]
        ), async_for_await_update_nested_branch
    async_for_multi_update = next(
        item for item in module["functions"] if item["name"].endswith("::asyncForMultiUpdate")
    )
    assert async_for_multi_update.get("async_kind") == "async_future", async_for_multi_update
    assert 0x31 in async_for_multi_update["code"], async_for_multi_update
    assert 0x30 in async_for_multi_update["code"], async_for_multi_update
    assert async_for_multi_update["code"].count(0x04) >= 5, async_for_multi_update
    assert 0x63 in async_for_multi_update["code"], async_for_multi_update
    async_for_multi_update_names = {
        entry.get("name") for entry in async_for_multi_update.get("debug_locals", [])
    }
    assert {"limit", "i", "j", "out"}.issubset(async_for_multi_update_names), async_for_multi_update
    assert any(
        constant.get("type") == "String" and constant.get("value") == "patched-for-multi-update"
        for constant in async_for_multi_update["constants"]
    ), async_for_multi_update
    sync_generated = next(
        item for item in module["functions"] if item["name"].endswith("::syncGenerated")
    )
    assert sync_generated.get("async_kind") == "sync_star", sync_generated
    assert 0x64 in sync_generated["code"], sync_generated
    async_generated = next(
        item for item in module["functions"] if item["name"].endswith("::asyncGenerated")
    )
    assert async_generated.get("async_kind") == "async_star", async_generated
    assert 0x64 in async_generated["code"], async_generated
    async_generated_await = next(
        item for item in module["functions"] if item["name"].endswith("::asyncGeneratedAwait")
    )
    assert async_generated_await.get("async_kind") == "async_star", async_generated_await
    assert 0x62 in async_generated_await["code"], async_generated_await
    assert 0x64 in async_generated_await["code"], async_generated_await
    assert 0x04 in async_generated_await["code"], async_generated_await
    assert {"slot": 0, "name": "ready"} in async_generated_await.get("debug_locals", []), async_generated_await
    assert any(entry.get("name") == "value" for entry in async_generated_await.get("debug_locals", [])), async_generated_await
    async_generated_try_finally = next(
        item for item in module["functions"] if item["name"].endswith("::asyncGeneratedTryFinally")
    )
    assert async_generated_try_finally.get("async_kind") == "async_star", async_generated_try_finally
    assert 0x62 in async_generated_try_finally["code"], async_generated_try_finally
    assert 0x64 in async_generated_try_finally["code"], async_generated_try_finally
    assert 0x65 in async_generated_try_finally["code"], async_generated_try_finally
    assert 0x66 in async_generated_try_finally["code"], async_generated_try_finally
    assert {"slot": 0, "name": "ready"} in async_generated_try_finally.get("debug_locals", []), async_generated_try_finally
    assert any(entry.get("name") == "cleanup" for entry in async_generated_try_finally.get("debug_locals", [])), async_generated_try_finally
    async_generated_finally_yield = next(
        item for item in module["functions"] if item["name"].endswith("::asyncGeneratedFinallyYield")
    )
    assert async_generated_finally_yield.get("async_kind") == "async_star", async_generated_finally_yield
    assert 0x62 in async_generated_finally_yield["code"], async_generated_finally_yield
    assert async_generated_finally_yield["code"].count(0x64) == 2, async_generated_finally_yield
    assert 0x65 in async_generated_finally_yield["code"], async_generated_finally_yield
    assert 0x66 in async_generated_finally_yield["code"], async_generated_finally_yield
    assert any(
        constant.get("type") == "String" and constant.get("value") == "patched-stream-finally-yield-cleanup"
        for constant in async_generated_finally_yield["constants"]
    ), async_generated_finally_yield
    async_generated_catch_await = next(
        item for item in module["functions"] if item["name"].endswith("::asyncGeneratedCatchAwait")
    )
    assert async_generated_catch_await.get("async_kind") == "async_star", async_generated_catch_await
    assert 0x61 in async_generated_catch_await["code"], async_generated_catch_await
    assert 0x62 in async_generated_catch_await["code"], async_generated_catch_await
    assert async_generated_catch_await["code"].count(0x64) == 2, async_generated_catch_await
    assert {"slot": 0, "name": "ready"} in async_generated_catch_await.get("debug_locals", []), async_generated_catch_await
    assert any(
        constant.get("type") == "String" and constant.get("value") == "patched-stream-caught-"
        for constant in async_generated_catch_await["constants"]
    ), async_generated_catch_await
    sync_generated_many = next(
        item for item in module["functions"] if item["name"].endswith("::syncGeneratedMany")
    )
    assert sync_generated_many.get("async_kind") == "sync_star", sync_generated_many
    assert sync_generated_many["code"].count(0x64) == 3, sync_generated_many
    assert 0x31 in sync_generated_many["code"], sync_generated_many
    assert {"slot": 0, "name": "enabled"} in sync_generated_many.get("debug_locals", []), sync_generated_many
    assert any(entry.get("name") == "prefix" for entry in sync_generated_many.get("debug_locals", [])), sync_generated_many
    async_generated_many = next(
        item for item in module["functions"] if item["name"].endswith("::asyncGeneratedMany")
    )
    assert async_generated_many.get("async_kind") == "async_star", async_generated_many
    assert async_generated_many["code"].count(0x64) == 3, async_generated_many
    assert 0x31 in async_generated_many["code"], async_generated_many
    sync_generated_while = next(
        item for item in module["functions"] if item["name"].endswith("::syncGeneratedWhile")
    )
    assert sync_generated_while.get("async_kind") == "sync_star", sync_generated_while
    assert sync_generated_while["code"].count(0x64) == 1, sync_generated_while
    assert 0x04 in sync_generated_while["code"], sync_generated_while
    assert 0x10 in sync_generated_while["code"], sync_generated_while
    assert 0x20 in sync_generated_while["code"], sync_generated_while
    assert 0x30 in sync_generated_while["code"], sync_generated_while
    assert 0x31 in sync_generated_while["code"], sync_generated_while
    assert any(entry.get("name") == "i" for entry in sync_generated_while.get("debug_locals", [])), sync_generated_while
    async_generated_while = next(
        item for item in module["functions"] if item["name"].endswith("::asyncGeneratedWhile")
    )
    assert async_generated_while.get("async_kind") == "async_star", async_generated_while
    assert async_generated_while["code"].count(0x64) == 1, async_generated_while
    assert 0x04 in async_generated_while["code"], async_generated_while
    assert 0x10 in async_generated_while["code"], async_generated_while
    assert 0x20 in async_generated_while["code"], async_generated_while
    assert 0x30 in async_generated_while["code"], async_generated_while
    assert 0x31 in async_generated_while["code"], async_generated_while
    assert any(entry.get("name") == "i" for entry in async_generated_while.get("debug_locals", [])), async_generated_while
    sync_generated_while_break = next(
        item for item in module["functions"] if item["name"].endswith("::syncGeneratedWhileBreak")
    )
    assert sync_generated_while_break.get("async_kind") == "sync_star", sync_generated_while_break
    assert sync_generated_while_break["code"].count(0x64) == 2, sync_generated_while_break
    assert 0x04 in sync_generated_while_break["code"], sync_generated_while_break
    assert 0x10 in sync_generated_while_break["code"], sync_generated_while_break
    assert 0x20 in sync_generated_while_break["code"], sync_generated_while_break
    assert 0x21 in sync_generated_while_break["code"], sync_generated_while_break
    assert sync_generated_while_break["code"].count(0x30) >= 2, sync_generated_while_break
    assert sync_generated_while_break["code"].count(0x31) >= 2, sync_generated_while_break
    assert any(entry.get("name") == "i" for entry in sync_generated_while_break.get("debug_locals", [])), sync_generated_while_break
    async_generated_while_break = next(
        item for item in module["functions"] if item["name"].endswith("::asyncGeneratedWhileBreak")
    )
    assert async_generated_while_break.get("async_kind") == "async_star", async_generated_while_break
    assert async_generated_while_break["code"].count(0x64) == 2, async_generated_while_break
    assert 0x04 in async_generated_while_break["code"], async_generated_while_break
    assert 0x10 in async_generated_while_break["code"], async_generated_while_break
    assert 0x20 in async_generated_while_break["code"], async_generated_while_break
    assert 0x21 in async_generated_while_break["code"], async_generated_while_break
    assert async_generated_while_break["code"].count(0x30) >= 2, async_generated_while_break
    assert async_generated_while_break["code"].count(0x31) >= 2, async_generated_while_break
    assert any(entry.get("name") == "i" for entry in async_generated_while_break.get("debug_locals", [])), async_generated_while_break
    sync_generated_while_continue = next(
        item for item in module["functions"] if item["name"].endswith("::syncGeneratedWhileContinue")
    )
    assert sync_generated_while_continue.get("async_kind") == "sync_star", sync_generated_while_continue
    assert sync_generated_while_continue["code"].count(0x64) == 2, sync_generated_while_continue
    assert 0x04 in sync_generated_while_continue["code"], sync_generated_while_continue
    assert 0x10 in sync_generated_while_continue["code"], sync_generated_while_continue
    assert 0x20 in sync_generated_while_continue["code"], sync_generated_while_continue
    assert 0x21 in sync_generated_while_continue["code"], sync_generated_while_continue
    assert sync_generated_while_continue["code"].count(0x30) >= 2, sync_generated_while_continue
    assert sync_generated_while_continue["code"].count(0x31) >= 2, sync_generated_while_continue
    assert any(entry.get("name") == "i" for entry in sync_generated_while_continue.get("debug_locals", [])), sync_generated_while_continue
    async_generated_while_continue = next(
        item for item in module["functions"] if item["name"].endswith("::asyncGeneratedWhileContinue")
    )
    assert async_generated_while_continue.get("async_kind") == "async_star", async_generated_while_continue
    assert async_generated_while_continue["code"].count(0x64) == 2, async_generated_while_continue
    assert 0x04 in async_generated_while_continue["code"], async_generated_while_continue
    assert 0x10 in async_generated_while_continue["code"], async_generated_while_continue
    assert 0x20 in async_generated_while_continue["code"], async_generated_while_continue
    assert 0x21 in async_generated_while_continue["code"], async_generated_while_continue
    assert async_generated_while_continue["code"].count(0x30) >= 2, async_generated_while_continue
    assert async_generated_while_continue["code"].count(0x31) >= 2, async_generated_while_continue
    assert any(entry.get("name") == "i" for entry in async_generated_while_continue.get("debug_locals", [])), async_generated_while_continue
    sync_generated_while_continue_break = next(
        item for item in module["functions"] if item["name"].endswith("::syncGeneratedWhileContinueBreak")
    )
    assert sync_generated_while_continue_break.get("async_kind") == "sync_star", sync_generated_while_continue_break
    assert sync_generated_while_continue_break["code"].count(0x64) == 3, sync_generated_while_continue_break
    assert 0x04 in sync_generated_while_continue_break["code"], sync_generated_while_continue_break
    assert 0x10 in sync_generated_while_continue_break["code"], sync_generated_while_continue_break
    assert 0x20 in sync_generated_while_continue_break["code"], sync_generated_while_continue_break
    assert 0x21 in sync_generated_while_continue_break["code"], sync_generated_while_continue_break
    assert sync_generated_while_continue_break["code"].count(0x30) >= 2, sync_generated_while_continue_break
    assert sync_generated_while_continue_break["code"].count(0x31) >= 3, sync_generated_while_continue_break
    assert any(entry.get("name") == "i" for entry in sync_generated_while_continue_break.get("debug_locals", [])), sync_generated_while_continue_break
    async_generated_while_continue_break = next(
        item for item in module["functions"] if item["name"].endswith("::asyncGeneratedWhileContinueBreak")
    )
    assert async_generated_while_continue_break.get("async_kind") == "async_star", async_generated_while_continue_break
    assert async_generated_while_continue_break["code"].count(0x64) == 3, async_generated_while_continue_break
    assert 0x04 in async_generated_while_continue_break["code"], async_generated_while_continue_break
    assert 0x10 in async_generated_while_continue_break["code"], async_generated_while_continue_break
    assert 0x20 in async_generated_while_continue_break["code"], async_generated_while_continue_break
    assert 0x21 in async_generated_while_continue_break["code"], async_generated_while_continue_break
    assert async_generated_while_continue_break["code"].count(0x30) >= 2, async_generated_while_continue_break
    assert async_generated_while_continue_break["code"].count(0x31) >= 3, async_generated_while_continue_break
    assert any(entry.get("name") == "i" for entry in async_generated_while_continue_break.get("debug_locals", [])), async_generated_while_continue_break
    sync_generated_do_while = next(
        item for item in module["functions"] if item["name"].endswith("::syncGeneratedDoWhile")
    )
    assert sync_generated_do_while.get("async_kind") == "sync_star", sync_generated_do_while
    assert sync_generated_do_while["code"].count(0x64) == 2, sync_generated_do_while
    assert 0x04 in sync_generated_do_while["code"], sync_generated_do_while
    assert 0x30 in sync_generated_do_while["code"], sync_generated_do_while
    assert 0x31 in sync_generated_do_while["code"], sync_generated_do_while
    assert any(entry.get("name") == "i" for entry in sync_generated_do_while.get("debug_locals", [])), sync_generated_do_while
    async_generated_do_while = next(
        item for item in module["functions"] if item["name"].endswith("::asyncGeneratedDoWhile")
    )
    assert async_generated_do_while.get("async_kind") == "async_star", async_generated_do_while
    assert async_generated_do_while["code"].count(0x64) == 2, async_generated_do_while
    assert 0x04 in async_generated_do_while["code"], async_generated_do_while
    assert 0x30 in async_generated_do_while["code"], async_generated_do_while
    assert 0x31 in async_generated_do_while["code"], async_generated_do_while
    assert any(entry.get("name") == "i" for entry in async_generated_do_while.get("debug_locals", [])), async_generated_do_while
    sync_generated_do_while_break = next(
        item for item in module["functions"] if item["name"].endswith("::syncGeneratedDoWhileBreak")
    )
    assert sync_generated_do_while_break.get("async_kind") == "sync_star", sync_generated_do_while_break
    assert sync_generated_do_while_break["code"].count(0x64) == 4, sync_generated_do_while_break
    assert 0x04 in sync_generated_do_while_break["code"], sync_generated_do_while_break
    assert 0x10 in sync_generated_do_while_break["code"], sync_generated_do_while_break
    assert 0x20 in sync_generated_do_while_break["code"], sync_generated_do_while_break
    assert 0x21 in sync_generated_do_while_break["code"], sync_generated_do_while_break
    assert sync_generated_do_while_break["code"].count(0x30) >= 2, sync_generated_do_while_break
    assert sync_generated_do_while_break["code"].count(0x31) >= 2, sync_generated_do_while_break
    assert any(entry.get("name") == "i" for entry in sync_generated_do_while_break.get("debug_locals", [])), sync_generated_do_while_break
    async_generated_do_while_break = next(
        item for item in module["functions"] if item["name"].endswith("::asyncGeneratedDoWhileBreak")
    )
    assert async_generated_do_while_break.get("async_kind") == "async_star", async_generated_do_while_break
    assert async_generated_do_while_break["code"].count(0x64) == 4, async_generated_do_while_break
    assert 0x04 in async_generated_do_while_break["code"], async_generated_do_while_break
    assert 0x10 in async_generated_do_while_break["code"], async_generated_do_while_break
    assert 0x20 in async_generated_do_while_break["code"], async_generated_do_while_break
    assert 0x21 in async_generated_do_while_break["code"], async_generated_do_while_break
    assert async_generated_do_while_break["code"].count(0x30) >= 2, async_generated_do_while_break
    assert async_generated_do_while_break["code"].count(0x31) >= 2, async_generated_do_while_break
    assert any(entry.get("name") == "i" for entry in async_generated_do_while_break.get("debug_locals", [])), async_generated_do_while_break
    sync_generated_do_while_continue = next(
        item for item in module["functions"] if item["name"].endswith("::syncGeneratedDoWhileContinue")
    )
    assert sync_generated_do_while_continue.get("async_kind") == "sync_star", sync_generated_do_while_continue
    assert sync_generated_do_while_continue["code"].count(0x64) == 4, sync_generated_do_while_continue
    assert 0x04 in sync_generated_do_while_continue["code"], sync_generated_do_while_continue
    assert 0x10 in sync_generated_do_while_continue["code"], sync_generated_do_while_continue
    assert 0x20 in sync_generated_do_while_continue["code"], sync_generated_do_while_continue
    assert 0x21 in sync_generated_do_while_continue["code"], sync_generated_do_while_continue
    assert sync_generated_do_while_continue["code"].count(0x30) >= 2, sync_generated_do_while_continue
    assert sync_generated_do_while_continue["code"].count(0x31) >= 2, sync_generated_do_while_continue
    assert any(entry.get("name") == "i" for entry in sync_generated_do_while_continue.get("debug_locals", [])), sync_generated_do_while_continue
    async_generated_do_while_continue = next(
        item for item in module["functions"] if item["name"].endswith("::asyncGeneratedDoWhileContinue")
    )
    assert async_generated_do_while_continue.get("async_kind") == "async_star", async_generated_do_while_continue
    assert async_generated_do_while_continue["code"].count(0x64) == 4, async_generated_do_while_continue
    assert 0x04 in async_generated_do_while_continue["code"], async_generated_do_while_continue
    assert 0x10 in async_generated_do_while_continue["code"], async_generated_do_while_continue
    assert 0x20 in async_generated_do_while_continue["code"], async_generated_do_while_continue
    assert 0x21 in async_generated_do_while_continue["code"], async_generated_do_while_continue
    assert async_generated_do_while_continue["code"].count(0x30) >= 2, async_generated_do_while_continue
    assert async_generated_do_while_continue["code"].count(0x31) >= 2, async_generated_do_while_continue
    assert any(entry.get("name") == "i" for entry in async_generated_do_while_continue.get("debug_locals", [])), async_generated_do_while_continue
    sync_generated_do_while_continue_break = next(
        item for item in module["functions"] if item["name"].endswith("::syncGeneratedDoWhileContinueBreak")
    )
    assert sync_generated_do_while_continue_break.get("async_kind") == "sync_star", sync_generated_do_while_continue_break
    assert sync_generated_do_while_continue_break["code"].count(0x64) == 9, sync_generated_do_while_continue_break
    assert 0x04 in sync_generated_do_while_continue_break["code"], sync_generated_do_while_continue_break
    assert 0x10 in sync_generated_do_while_continue_break["code"], sync_generated_do_while_continue_break
    assert 0x20 in sync_generated_do_while_continue_break["code"], sync_generated_do_while_continue_break
    assert 0x21 in sync_generated_do_while_continue_break["code"], sync_generated_do_while_continue_break
    assert sync_generated_do_while_continue_break["code"].count(0x30) >= 8, sync_generated_do_while_continue_break
    assert sync_generated_do_while_continue_break["code"].count(0x31) >= 8, sync_generated_do_while_continue_break
    assert any(entry.get("name") == "i" for entry in sync_generated_do_while_continue_break.get("debug_locals", [])), sync_generated_do_while_continue_break
    async_generated_do_while_continue_break = next(
        item for item in module["functions"] if item["name"].endswith("::asyncGeneratedDoWhileContinueBreak")
    )
    assert async_generated_do_while_continue_break.get("async_kind") == "async_star", async_generated_do_while_continue_break
    assert async_generated_do_while_continue_break["code"].count(0x64) == 9, async_generated_do_while_continue_break
    assert 0x04 in async_generated_do_while_continue_break["code"], async_generated_do_while_continue_break
    assert 0x10 in async_generated_do_while_continue_break["code"], async_generated_do_while_continue_break
    assert 0x20 in async_generated_do_while_continue_break["code"], async_generated_do_while_continue_break
    assert 0x21 in async_generated_do_while_continue_break["code"], async_generated_do_while_continue_break
    assert async_generated_do_while_continue_break["code"].count(0x30) >= 8, async_generated_do_while_continue_break
    assert async_generated_do_while_continue_break["code"].count(0x31) >= 8, async_generated_do_while_continue_break
    assert any(entry.get("name") == "i" for entry in async_generated_do_while_continue_break.get("debug_locals", [])), async_generated_do_while_continue_break
    sync_generated_for_loop = next(
        item for item in module["functions"] if item["name"].endswith("::syncGeneratedForLoop")
    )
    assert sync_generated_for_loop.get("async_kind") == "sync_star", sync_generated_for_loop
    assert sync_generated_for_loop["code"].count(0x64) == 1, sync_generated_for_loop
    assert 0x04 in sync_generated_for_loop["code"], sync_generated_for_loop
    assert 0x10 in sync_generated_for_loop["code"], sync_generated_for_loop
    assert 0x20 in sync_generated_for_loop["code"], sync_generated_for_loop
    assert 0x30 in sync_generated_for_loop["code"], sync_generated_for_loop
    assert 0x31 in sync_generated_for_loop["code"], sync_generated_for_loop
    assert any(entry.get("name") == "i" for entry in sync_generated_for_loop.get("debug_locals", [])), sync_generated_for_loop
    async_generated_for_loop = next(
        item for item in module["functions"] if item["name"].endswith("::asyncGeneratedForLoop")
    )
    assert async_generated_for_loop.get("async_kind") == "async_star", async_generated_for_loop
    assert async_generated_for_loop["code"].count(0x64) == 1, async_generated_for_loop
    assert 0x04 in async_generated_for_loop["code"], async_generated_for_loop
    assert 0x10 in async_generated_for_loop["code"], async_generated_for_loop
    assert 0x20 in async_generated_for_loop["code"], async_generated_for_loop
    assert 0x30 in async_generated_for_loop["code"], async_generated_for_loop
    assert 0x31 in async_generated_for_loop["code"], async_generated_for_loop
    assert any(entry.get("name") == "i" for entry in async_generated_for_loop.get("debug_locals", [])), async_generated_for_loop
    sync_generated_for_loop_postinc = next(
        item for item in module["functions"] if item["name"].endswith("::syncGeneratedForLoopPostIncrement")
    )
    assert sync_generated_for_loop_postinc.get("async_kind") == "sync_star", sync_generated_for_loop_postinc
    assert sync_generated_for_loop_postinc["code"].count(0x64) == 1, sync_generated_for_loop_postinc
    assert 0x04 in sync_generated_for_loop_postinc["code"], sync_generated_for_loop_postinc
    assert 0x20 in sync_generated_for_loop_postinc["code"], sync_generated_for_loop_postinc
    assert 0x30 in sync_generated_for_loop_postinc["code"], sync_generated_for_loop_postinc
    assert 0x31 in sync_generated_for_loop_postinc["code"], sync_generated_for_loop_postinc
    assert any(entry.get("name") == "i" for entry in sync_generated_for_loop_postinc.get("debug_locals", [])), sync_generated_for_loop_postinc
    async_generated_for_loop_postinc = next(
        item for item in module["functions"] if item["name"].endswith("::asyncGeneratedForLoopPostIncrement")
    )
    assert async_generated_for_loop_postinc.get("async_kind") == "async_star", async_generated_for_loop_postinc
    assert async_generated_for_loop_postinc["code"].count(0x64) == 1, async_generated_for_loop_postinc
    assert 0x04 in async_generated_for_loop_postinc["code"], async_generated_for_loop_postinc
    assert 0x20 in async_generated_for_loop_postinc["code"], async_generated_for_loop_postinc
    assert 0x30 in async_generated_for_loop_postinc["code"], async_generated_for_loop_postinc
    assert 0x31 in async_generated_for_loop_postinc["code"], async_generated_for_loop_postinc
    assert any(entry.get("name") == "i" for entry in async_generated_for_loop_postinc.get("debug_locals", [])), async_generated_for_loop_postinc
    sync_generated_for_loop_multi = next(
        item for item in module["functions"] if item["name"].endswith("::syncGeneratedForLoopMultiUpdate")
    )
    assert sync_generated_for_loop_multi.get("async_kind") == "sync_star", sync_generated_for_loop_multi
    assert sync_generated_for_loop_multi["code"].count(0x64) == 1, sync_generated_for_loop_multi
    assert sync_generated_for_loop_multi["code"].count(0x04) >= 4, sync_generated_for_loop_multi
    assert 0x30 in sync_generated_for_loop_multi["code"], sync_generated_for_loop_multi
    assert 0x31 in sync_generated_for_loop_multi["code"], sync_generated_for_loop_multi
    sync_for_multi_names = {entry.get("name") for entry in sync_generated_for_loop_multi.get("debug_locals", [])}
    assert {"i", "j"}.issubset(sync_for_multi_names), sync_generated_for_loop_multi
    async_generated_for_loop_multi = next(
        item for item in module["functions"] if item["name"].endswith("::asyncGeneratedForLoopMultiUpdate")
    )
    assert async_generated_for_loop_multi.get("async_kind") == "async_star", async_generated_for_loop_multi
    assert async_generated_for_loop_multi["code"].count(0x64) == 1, async_generated_for_loop_multi
    assert async_generated_for_loop_multi["code"].count(0x04) >= 4, async_generated_for_loop_multi
    assert 0x30 in async_generated_for_loop_multi["code"], async_generated_for_loop_multi
    assert 0x31 in async_generated_for_loop_multi["code"], async_generated_for_loop_multi
    async_for_multi_names = {entry.get("name") for entry in async_generated_for_loop_multi.get("debug_locals", [])}
    assert {"i", "j"}.issubset(async_for_multi_names), async_generated_for_loop_multi
    sync_generated_for_loop_external = next(
        item for item in module["functions"] if item["name"].endswith("::syncGeneratedForLoopExternalLocal")
    )
    assert sync_generated_for_loop_external.get("async_kind") == "sync_star", sync_generated_for_loop_external
    assert sync_generated_for_loop_external["code"].count(0x64) == 1, sync_generated_for_loop_external
    assert 0x04 in sync_generated_for_loop_external["code"], sync_generated_for_loop_external
    assert 0x30 in sync_generated_for_loop_external["code"], sync_generated_for_loop_external
    assert 0x31 in sync_generated_for_loop_external["code"], sync_generated_for_loop_external
    assert any(entry.get("name") == "i" for entry in sync_generated_for_loop_external.get("debug_locals", [])), sync_generated_for_loop_external
    async_generated_for_loop_external = next(
        item for item in module["functions"] if item["name"].endswith("::asyncGeneratedForLoopExternalLocal")
    )
    assert async_generated_for_loop_external.get("async_kind") == "async_star", async_generated_for_loop_external
    assert async_generated_for_loop_external["code"].count(0x64) == 1, async_generated_for_loop_external
    assert 0x04 in async_generated_for_loop_external["code"], async_generated_for_loop_external
    assert 0x30 in async_generated_for_loop_external["code"], async_generated_for_loop_external
    assert 0x31 in async_generated_for_loop_external["code"], async_generated_for_loop_external
    assert any(entry.get("name") == "i" for entry in async_generated_for_loop_external.get("debug_locals", [])), async_generated_for_loop_external
    sync_generated_for_loop_body_update = next(
        item for item in module["functions"] if item["name"].endswith("::syncGeneratedForLoopBodyUpdate")
    )
    assert sync_generated_for_loop_body_update.get("async_kind") == "sync_star", sync_generated_for_loop_body_update
    assert sync_generated_for_loop_body_update["code"].count(0x64) == 1, sync_generated_for_loop_body_update
    assert 0x04 in sync_generated_for_loop_body_update["code"], sync_generated_for_loop_body_update
    assert 0x30 in sync_generated_for_loop_body_update["code"], sync_generated_for_loop_body_update
    assert 0x31 in sync_generated_for_loop_body_update["code"], sync_generated_for_loop_body_update
    assert any(entry.get("name") == "i" for entry in sync_generated_for_loop_body_update.get("debug_locals", [])), sync_generated_for_loop_body_update
    async_generated_for_loop_body_update = next(
        item for item in module["functions"] if item["name"].endswith("::asyncGeneratedForLoopBodyUpdate")
    )
    assert async_generated_for_loop_body_update.get("async_kind") == "async_star", async_generated_for_loop_body_update
    assert async_generated_for_loop_body_update["code"].count(0x64) == 1, async_generated_for_loop_body_update
    assert 0x04 in async_generated_for_loop_body_update["code"], async_generated_for_loop_body_update
    assert 0x30 in async_generated_for_loop_body_update["code"], async_generated_for_loop_body_update
    assert 0x31 in async_generated_for_loop_body_update["code"], async_generated_for_loop_body_update
    assert any(entry.get("name") == "i" for entry in async_generated_for_loop_body_update.get("debug_locals", [])), async_generated_for_loop_body_update
    sync_generated_for_loop_continue = next(
        item for item in module["functions"] if item["name"].endswith("::syncGeneratedForLoopContinue")
    )
    assert sync_generated_for_loop_continue.get("async_kind") == "sync_star", sync_generated_for_loop_continue
    assert sync_generated_for_loop_continue["code"].count(0x64) == 2, sync_generated_for_loop_continue
    assert 0x04 in sync_generated_for_loop_continue["code"], sync_generated_for_loop_continue
    assert 0x21 in sync_generated_for_loop_continue["code"], sync_generated_for_loop_continue
    assert sync_generated_for_loop_continue["code"].count(0x30) >= 1, sync_generated_for_loop_continue
    assert sync_generated_for_loop_continue["code"].count(0x31) >= 2, sync_generated_for_loop_continue
    assert any(entry.get("name") == "i" for entry in sync_generated_for_loop_continue.get("debug_locals", [])), sync_generated_for_loop_continue
    async_generated_for_loop_continue = next(
        item for item in module["functions"] if item["name"].endswith("::asyncGeneratedForLoopContinue")
    )
    assert async_generated_for_loop_continue.get("async_kind") == "async_star", async_generated_for_loop_continue
    assert async_generated_for_loop_continue["code"].count(0x64) == 2, async_generated_for_loop_continue
    assert 0x04 in async_generated_for_loop_continue["code"], async_generated_for_loop_continue
    assert 0x21 in async_generated_for_loop_continue["code"], async_generated_for_loop_continue
    assert async_generated_for_loop_continue["code"].count(0x30) >= 1, async_generated_for_loop_continue
    assert async_generated_for_loop_continue["code"].count(0x31) >= 2, async_generated_for_loop_continue
    assert any(entry.get("name") == "i" for entry in async_generated_for_loop_continue.get("debug_locals", [])), async_generated_for_loop_continue
    sync_generated_for_loop_continue_break = next(
        item for item in module["functions"] if item["name"].endswith("::syncGeneratedForLoopContinueBreak")
    )
    assert sync_generated_for_loop_continue_break.get("async_kind") == "sync_star", sync_generated_for_loop_continue_break
    assert sync_generated_for_loop_continue_break["code"].count(0x64) == 3, sync_generated_for_loop_continue_break
    assert 0x04 in sync_generated_for_loop_continue_break["code"], sync_generated_for_loop_continue_break
    assert 0x21 in sync_generated_for_loop_continue_break["code"], sync_generated_for_loop_continue_break
    assert sync_generated_for_loop_continue_break["code"].count(0x30) >= 2, sync_generated_for_loop_continue_break
    assert sync_generated_for_loop_continue_break["code"].count(0x31) >= 3, sync_generated_for_loop_continue_break
    assert any(entry.get("name") == "i" for entry in sync_generated_for_loop_continue_break.get("debug_locals", [])), sync_generated_for_loop_continue_break
    async_generated_for_loop_continue_break = next(
        item for item in module["functions"] if item["name"].endswith("::asyncGeneratedForLoopContinueBreak")
    )
    assert async_generated_for_loop_continue_break.get("async_kind") == "async_star", async_generated_for_loop_continue_break
    assert async_generated_for_loop_continue_break["code"].count(0x64) == 3, async_generated_for_loop_continue_break
    assert 0x04 in async_generated_for_loop_continue_break["code"], async_generated_for_loop_continue_break
    assert 0x21 in async_generated_for_loop_continue_break["code"], async_generated_for_loop_continue_break
    assert async_generated_for_loop_continue_break["code"].count(0x30) >= 2, async_generated_for_loop_continue_break
    assert async_generated_for_loop_continue_break["code"].count(0x31) >= 3, async_generated_for_loop_continue_break
    assert any(entry.get("name") == "i" for entry in async_generated_for_loop_continue_break.get("debug_locals", [])), async_generated_for_loop_continue_break
    sync_generated_for_loop_break = next(
        item for item in module["functions"] if item["name"].endswith("::syncGeneratedForLoopBreak")
    )
    assert sync_generated_for_loop_break.get("async_kind") == "sync_star", sync_generated_for_loop_break
    assert sync_generated_for_loop_break["code"].count(0x64) == 2, sync_generated_for_loop_break
    assert 0x04 in sync_generated_for_loop_break["code"], sync_generated_for_loop_break
    assert 0x21 in sync_generated_for_loop_break["code"], sync_generated_for_loop_break
    assert sync_generated_for_loop_break["code"].count(0x30) >= 2, sync_generated_for_loop_break
    assert sync_generated_for_loop_break["code"].count(0x31) >= 2, sync_generated_for_loop_break
    assert any(entry.get("name") == "i" for entry in sync_generated_for_loop_break.get("debug_locals", [])), sync_generated_for_loop_break
    async_generated_for_loop_break = next(
        item for item in module["functions"] if item["name"].endswith("::asyncGeneratedForLoopBreak")
    )
    assert async_generated_for_loop_break.get("async_kind") == "async_star", async_generated_for_loop_break
    assert async_generated_for_loop_break["code"].count(0x64) == 2, async_generated_for_loop_break
    assert 0x04 in async_generated_for_loop_break["code"], async_generated_for_loop_break
    assert 0x21 in async_generated_for_loop_break["code"], async_generated_for_loop_break
    assert async_generated_for_loop_break["code"].count(0x30) >= 2, async_generated_for_loop_break
    assert async_generated_for_loop_break["code"].count(0x31) >= 2, async_generated_for_loop_break
    assert any(entry.get("name") == "i" for entry in async_generated_for_loop_break.get("debug_locals", [])), async_generated_for_loop_break
    sync_generated_for_in = next(
        item for item in module["functions"] if item["name"].endswith("::syncGeneratedForIn")
    )
    assert sync_generated_for_in.get("async_kind") == "sync_star", sync_generated_for_in
    assert sync_generated_for_in["code"].count(0x64) == 2, sync_generated_for_in
    async_generated_for_in = next(
        item for item in module["functions"] if item["name"].endswith("::asyncGeneratedForIn")
    )
    assert async_generated_for_in.get("async_kind") == "async_star", async_generated_for_in
    assert async_generated_for_in["code"].count(0x64) == 2, async_generated_for_in
    sync_generated_for_in_break = next(
        item for item in module["functions"] if item["name"].endswith("::syncGeneratedForInBreak")
    )
    assert sync_generated_for_in_break.get("async_kind") == "sync_star", sync_generated_for_in_break
    assert sync_generated_for_in_break["code"].count(0x64) == 2, sync_generated_for_in_break
    assert sync_generated_for_in_break["code"].count(0x30) >= 2, sync_generated_for_in_break
    assert 0x31 in sync_generated_for_in_break["code"], sync_generated_for_in_break
    assert 0x42 in sync_generated_for_in_break["code"], sync_generated_for_in_break
    assert 0x51 in sync_generated_for_in_break["code"], sync_generated_for_in_break
    assert any(entry.get("name") == "prefix" for entry in sync_generated_for_in_break.get("debug_locals", [])), sync_generated_for_in_break
    assert any(entry.get("name") == "value" for entry in sync_generated_for_in_break.get("debug_locals", [])), sync_generated_for_in_break
    async_generated_for_in_break = next(
        item for item in module["functions"] if item["name"].endswith("::asyncGeneratedForInBreak")
    )
    assert async_generated_for_in_break.get("async_kind") == "async_star", async_generated_for_in_break
    assert async_generated_for_in_break["code"].count(0x64) == 2, async_generated_for_in_break
    assert async_generated_for_in_break["code"].count(0x30) >= 2, async_generated_for_in_break
    assert 0x31 in async_generated_for_in_break["code"], async_generated_for_in_break
    assert 0x42 in async_generated_for_in_break["code"], async_generated_for_in_break
    assert 0x51 in async_generated_for_in_break["code"], async_generated_for_in_break
    assert any(entry.get("name") == "prefix" for entry in async_generated_for_in_break.get("debug_locals", [])), async_generated_for_in_break
    assert any(entry.get("name") == "value" for entry in async_generated_for_in_break.get("debug_locals", [])), async_generated_for_in_break
    sync_generated_for_in_break_first = next(
        item for item in module["functions"] if item["name"].endswith("::syncGeneratedForInBreakFirst")
    )
    assert sync_generated_for_in_break_first.get("async_kind") == "sync_star", sync_generated_for_in_break_first
    assert sync_generated_for_in_break_first["code"].count(0x64) == 1, sync_generated_for_in_break_first
    assert sync_generated_for_in_break_first["code"].count(0x30) >= 2, sync_generated_for_in_break_first
    assert 0x31 in sync_generated_for_in_break_first["code"], sync_generated_for_in_break_first
    assert 0x42 in sync_generated_for_in_break_first["code"], sync_generated_for_in_break_first
    assert 0x51 in sync_generated_for_in_break_first["code"], sync_generated_for_in_break_first
    assert any(entry.get("name") == "prefix" for entry in sync_generated_for_in_break_first.get("debug_locals", [])), sync_generated_for_in_break_first
    assert any(entry.get("name") == "value" for entry in sync_generated_for_in_break_first.get("debug_locals", [])), sync_generated_for_in_break_first
    async_generated_for_in_break_first = next(
        item for item in module["functions"] if item["name"].endswith("::asyncGeneratedForInBreakFirst")
    )
    assert async_generated_for_in_break_first.get("async_kind") == "async_star", async_generated_for_in_break_first
    assert async_generated_for_in_break_first["code"].count(0x64) == 1, async_generated_for_in_break_first
    assert async_generated_for_in_break_first["code"].count(0x30) >= 2, async_generated_for_in_break_first
    assert 0x31 in async_generated_for_in_break_first["code"], async_generated_for_in_break_first
    assert 0x42 in async_generated_for_in_break_first["code"], async_generated_for_in_break_first
    assert 0x51 in async_generated_for_in_break_first["code"], async_generated_for_in_break_first
    assert any(entry.get("name") == "prefix" for entry in async_generated_for_in_break_first.get("debug_locals", [])), async_generated_for_in_break_first
    assert any(entry.get("name") == "value" for entry in async_generated_for_in_break_first.get("debug_locals", [])), async_generated_for_in_break_first
    sync_generated_for_in_continue = next(
        item for item in module["functions"] if item["name"].endswith("::syncGeneratedForInContinue")
    )
    assert sync_generated_for_in_continue.get("async_kind") == "sync_star", sync_generated_for_in_continue
    assert sync_generated_for_in_continue["code"].count(0x64) == 1, sync_generated_for_in_continue
    assert 0x31 in sync_generated_for_in_continue["code"], sync_generated_for_in_continue
    assert 0x42 in sync_generated_for_in_continue["code"], sync_generated_for_in_continue
    assert 0x51 in sync_generated_for_in_continue["code"], sync_generated_for_in_continue
    assert any(entry.get("name") == "prefix" for entry in sync_generated_for_in_continue.get("debug_locals", [])), sync_generated_for_in_continue
    assert any(entry.get("name") == "value" for entry in sync_generated_for_in_continue.get("debug_locals", [])), sync_generated_for_in_continue
    async_generated_for_in_continue = next(
        item for item in module["functions"] if item["name"].endswith("::asyncGeneratedForInContinue")
    )
    assert async_generated_for_in_continue.get("async_kind") == "async_star", async_generated_for_in_continue
    assert async_generated_for_in_continue["code"].count(0x64) == 1, async_generated_for_in_continue
    assert 0x31 in async_generated_for_in_continue["code"], async_generated_for_in_continue
    assert 0x42 in async_generated_for_in_continue["code"], async_generated_for_in_continue
    assert 0x51 in async_generated_for_in_continue["code"], async_generated_for_in_continue
    assert any(entry.get("name") == "prefix" for entry in async_generated_for_in_continue.get("debug_locals", [])), async_generated_for_in_continue
    assert any(entry.get("name") == "value" for entry in async_generated_for_in_continue.get("debug_locals", [])), async_generated_for_in_continue
    sync_generated_for_in_continue_after_yield = next(
        item for item in module["functions"] if item["name"].endswith("::syncGeneratedForInContinueAfterYield")
    )
    assert sync_generated_for_in_continue_after_yield.get("async_kind") == "sync_star", sync_generated_for_in_continue_after_yield
    assert sync_generated_for_in_continue_after_yield["code"].count(0x64) == 2, sync_generated_for_in_continue_after_yield
    assert 0x31 in sync_generated_for_in_continue_after_yield["code"], sync_generated_for_in_continue_after_yield
    assert 0x42 in sync_generated_for_in_continue_after_yield["code"], sync_generated_for_in_continue_after_yield
    assert 0x51 in sync_generated_for_in_continue_after_yield["code"], sync_generated_for_in_continue_after_yield
    assert any(entry.get("name") == "prefix" for entry in sync_generated_for_in_continue_after_yield.get("debug_locals", [])), sync_generated_for_in_continue_after_yield
    assert any(entry.get("name") == "value" for entry in sync_generated_for_in_continue_after_yield.get("debug_locals", [])), sync_generated_for_in_continue_after_yield
    async_generated_for_in_continue_after_yield = next(
        item for item in module["functions"] if item["name"].endswith("::asyncGeneratedForInContinueAfterYield")
    )
    assert async_generated_for_in_continue_after_yield.get("async_kind") == "async_star", async_generated_for_in_continue_after_yield
    assert async_generated_for_in_continue_after_yield["code"].count(0x64) == 2, async_generated_for_in_continue_after_yield
    assert 0x31 in async_generated_for_in_continue_after_yield["code"], async_generated_for_in_continue_after_yield
    assert 0x42 in async_generated_for_in_continue_after_yield["code"], async_generated_for_in_continue_after_yield
    assert 0x51 in async_generated_for_in_continue_after_yield["code"], async_generated_for_in_continue_after_yield
    assert any(entry.get("name") == "prefix" for entry in async_generated_for_in_continue_after_yield.get("debug_locals", [])), async_generated_for_in_continue_after_yield
    assert any(entry.get("name") == "value" for entry in async_generated_for_in_continue_after_yield.get("debug_locals", [])), async_generated_for_in_continue_after_yield
    assert_dynamic_for_in(module)
    assert_stream_generators(module)
    double_count = sum(
        1
        for constant in function["constants"]
        if constant.get("type") == "Double" and constant.get("value") == 1.5
    )
    assert double_count == 1, function
    assert any(
        constant.get("type") == "Double" and constant.get("value") == 1.5
        for constant in function["constants"]
    ), function
