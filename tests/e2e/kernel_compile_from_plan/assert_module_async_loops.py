def assert_async_loop_module(module):
    def assert_loop_switch_module(name, constants, min_awaits=0):
        function = next(
            item for item in module["functions"] if item["name"].endswith(f"::{name}")
        )
        assert function.get("async_kind") == "async_future", function
        assert 0x31 in function["code"], function
        assert 0x30 in function["code"], function
        assert 0x04 in function["code"], function
        assert 0x21 in function["code"], function
        assert function["code"].count(0x62) >= min_awaits, function
        debug_names = {entry.get("name") for entry in function.get("debug_locals", [])}
        assert {"out", "i", "label"}.issubset(debug_names), function
        for value in constants:
            assert any(
                constant.get("type") == "String" and constant.get("value") == value
                for constant in function["constants"]
            ), function

    def assert_async_try_loop(name, names, constants, min_awaits, has_catch):
        function = next(
            item for item in module["functions"] if item["name"].endswith(f"::{name}")
        )
        assert function.get("async_kind") == "async_future", function
        assert 0x31 in function["code"], function
        assert 0x30 in function["code"], function
        assert function["code"].count(0x62) >= min_awaits, function
        assert function["code"].count(0x04) >= 5, function
        assert 0x63 in function["code"], function
        if has_catch:
            assert 0x61 in function["code"], function
            assert 0x60 in function["code"], function
        else:
            assert 0x65 in function["code"], function
            assert 0x66 in function["code"], function
        debug_names = {entry.get("name") for entry in function.get("debug_locals", [])}
        assert set(names).issubset(debug_names), function
        for value in constants:
            assert any(
                constant.get("type") == "String" and constant.get("value") == value
                for constant in function["constants"]
            ), function

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
    async_while_await_condition_continue_break = next(
        item for item in module["functions"] if item["name"].endswith("::asyncWhileAwaitConditionContinueBreak")
    )
    assert async_while_await_condition_continue_break.get("async_kind") == "async_future", async_while_await_condition_continue_break
    assert 0x31 in async_while_await_condition_continue_break["code"], async_while_await_condition_continue_break
    assert 0x30 in async_while_await_condition_continue_break["code"], async_while_await_condition_continue_break
    assert async_while_await_condition_continue_break["code"].count(0x62) >= 3, async_while_await_condition_continue_break
    assert async_while_await_condition_continue_break["code"].count(0x04) >= 7, async_while_await_condition_continue_break
    assert 0x63 in async_while_await_condition_continue_break["code"], async_while_await_condition_continue_break
    async_while_await_condition_continue_break_names = {
        entry.get("name") for entry in async_while_await_condition_continue_break.get("debug_locals", [])
    }
    assert {
        "keepGoing",
        "skip",
        "stop",
        "i",
        "out",
    }.issubset(async_while_await_condition_continue_break_names), async_while_await_condition_continue_break
    assert any(
        constant.get("type") == "String" and constant.get("value") == "patched-while-await-condition-continue-break"
        for constant in async_while_await_condition_continue_break["constants"]
    ), async_while_await_condition_continue_break
    async_while_try_catch = next(
        item for item in module["functions"] if item["name"].endswith("::asyncWhileTryCatchAwaitGuard")
    )
    assert async_while_try_catch.get("async_kind") == "async_future", async_while_try_catch
    assert 0x31 in async_while_try_catch["code"], async_while_try_catch
    assert 0x30 in async_while_try_catch["code"], async_while_try_catch
    assert 0x61 in async_while_try_catch["code"], async_while_try_catch
    assert 0x60 in async_while_try_catch["code"], async_while_try_catch
    assert 0x62 in async_while_try_catch["code"], async_while_try_catch
    assert async_while_try_catch["code"].count(0x04) >= 5, async_while_try_catch
    assert 0x63 in async_while_try_catch["code"], async_while_try_catch
    async_while_try_catch_names = {
        entry.get("name") for entry in async_while_try_catch.get("debug_locals", [])
    }
    assert {"limit", "fail", "i", "out"}.issubset(async_while_try_catch_names), async_while_try_catch
    for value in [
        "patched-while-try-catch-await-guard",
        "patched-while-catch-",
        "-caught-",
    ]:
        assert any(
            constant.get("type") == "String" and constant.get("value") == value
            for constant in async_while_try_catch["constants"]
        ), async_while_try_catch
    async_while_try_finally = next(
        item for item in module["functions"] if item["name"].endswith("::asyncWhileTryFinallyAwaitGuard")
    )
    assert async_while_try_finally.get("async_kind") == "async_future", async_while_try_finally
    assert 0x31 in async_while_try_finally["code"], async_while_try_finally
    assert 0x30 in async_while_try_finally["code"], async_while_try_finally
    assert 0x65 in async_while_try_finally["code"], async_while_try_finally
    assert 0x66 in async_while_try_finally["code"], async_while_try_finally
    assert async_while_try_finally["code"].count(0x62) >= 2, async_while_try_finally
    assert async_while_try_finally["code"].count(0x04) >= 6, async_while_try_finally
    assert 0x63 in async_while_try_finally["code"], async_while_try_finally
    async_while_try_finally_names = {
        entry.get("name") for entry in async_while_try_finally.get("debug_locals", [])
    }
    assert {
        "limit",
        "skip",
        "cleanup",
        "i",
        "out",
        "marker",
    }.issubset(async_while_try_finally_names), async_while_try_finally
    for value in [
        "patched-while-try-finally-await-guard",
        "-body-",
        "-skip-",
        "-tail-",
        "-finally-",
    ]:
        assert any(
            constant.get("type") == "String" and constant.get("value") == value
            for constant in async_while_try_finally["constants"]
        ), async_while_try_finally
    assert_loop_switch_module(
        "asyncWhileSwitchAssignedLabel",
        ["patched-while-switch-assigned", "patched-while-switch-gold"],
    )
    assert_loop_switch_module(
        "asyncWhileAwaitConditionSwitchAssignedLabel",
        [
            "patched-while-await-condition-switch-assigned",
            "patched-while-await-switch-gold",
        ],
        min_awaits=1,
    )
    assert_loop_switch_module(
        "asyncForSwitchAssignedLabel",
        ["patched-for-switch-assigned", "patched-for-switch-gold"],
    )
    assert_loop_switch_module(
        "asyncForAwaitUpdateSwitchAssignedLabel",
        ["patched-for-await-update-switch-assigned", "patched-for-await-update-switch-gold"],
        min_awaits=1,
    )
    assert_loop_switch_module(
        "asyncForSwitchAssignedListNames",
        ["patched-for-switch-list", "patched-for-switch-list-gold"],
    )
    assert_loop_switch_module(
        "asyncForSwitchAssignedMapLabels",
        ["patched-for-switch-map", "patched-for-switch-map-seven"],
    )
    assert_loop_switch_module(
        "asyncDoWhileSwitchAssignedLabel",
        ["patched-do-while-switch-assigned", "patched-do-while-switch-gold"],
    )
    assert_loop_switch_module(
        "asyncWhileSwitchOrPatternAssignedLabel",
        ["patched-while-switch-or-assigned", "patched-while-switch-or-premium"],
    )
    assert_loop_switch_module(
        "asyncForAwaitUpdateSwitchOrPatternAssignedLabel",
        [
            "patched-for-await-update-switch-or-assigned",
            "patched-for-await-update-switch-or-premium",
        ],
        min_awaits=1,
    )
    assert_loop_switch_module(
        "asyncWhileNestedBranchSwitchAssignedLabel",
        ["patched-while-nested-switch-assigned", "patched-while-nested-switch-gold"],
    )
    assert_loop_switch_module(
        "asyncForTryCatchSwitchAssignedLabel",
        ["patched-for-try-catch-switch-assigned", "patched-for-try-catch-switch-gold"],
    )
    assert_loop_switch_module(
        "asyncForAwaitUpdateTryFinallySwitchAssignedLabel",
        [
            "patched-for-await-update-try-finally-switch-assigned",
            "patched-for-await-update-try-finally-switch-gold",
        ],
        min_awaits=2,
    )
    assert_loop_switch_module(
        "asyncWhileAwaitConditionTryCatchSwitchAssignedLabel",
        [
            "patched-while-await-condition-try-catch-switch-assigned",
            "patched-while-await-condition-try-catch-switch-gold",
        ],
        min_awaits=1,
    )
    assert_loop_switch_module(
        "asyncWhileAwaitConditionTryCatchSwitchOrPatternAssignedLabel",
        [
            "patched-while-await-condition-try-catch-switch-or-assigned",
            "patched-while-await-condition-try-catch-switch-or-premium",
        ],
        min_awaits=1,
    )
    assert_loop_switch_module(
        "asyncDoWhileTryFinallySwitchAssignedLabel",
        [
            "patched-do-while-try-finally-switch-assigned",
            "patched-do-while-try-finally-switch-gold",
        ],
        min_awaits=1,
    )
    assert_loop_switch_module(
        "asyncDoWhileTryFinallySwitchOrPatternAssignedLabel",
        [
            "patched-do-while-try-finally-switch-or-assigned",
            "patched-do-while-try-finally-switch-or-premium",
        ],
        min_awaits=1,
    )
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
    async_while_await_condition_nested_branch = next(
        item for item in module["functions"] if item["name"].endswith("::asyncWhileAwaitConditionNestedAwaitBranchLocal")
    )
    assert async_while_await_condition_nested_branch.get("async_kind") == "async_future", async_while_await_condition_nested_branch
    assert 0x31 in async_while_await_condition_nested_branch["code"], async_while_await_condition_nested_branch
    assert 0x30 in async_while_await_condition_nested_branch["code"], async_while_await_condition_nested_branch
    assert async_while_await_condition_nested_branch["code"].count(0x62) >= 2, async_while_await_condition_nested_branch
    assert async_while_await_condition_nested_branch["code"].count(0x04) >= 8, async_while_await_condition_nested_branch
    assert 0x63 in async_while_await_condition_nested_branch["code"], async_while_await_condition_nested_branch
    async_while_await_condition_nested_branch_names = {
        entry.get("name") for entry in async_while_await_condition_nested_branch.get("debug_locals", [])
    }
    assert {
        "keepGoing",
        "premium",
        "ready",
        "i",
        "out",
        "state",
        "tier",
    }.issubset(async_while_await_condition_nested_branch_names), async_while_await_condition_nested_branch
    for value in [
        "patched-while-await-condition-nested-branch",
        "patched-while-await-condition-nested-pro",
        "patched-while-await-condition-nested-basic",
        "patched-while-await-condition-nested-tail",
    ]:
        assert any(
            constant.get("type") == "String" and constant.get("value") == value
            for constant in async_while_await_condition_nested_branch["constants"]
        ), async_while_await_condition_nested_branch
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
    async_do_while_await_branch = next(
        item for item in module["functions"] if item["name"].endswith("::asyncDoWhileAwaitConditionBranchLocal")
    )
    assert async_do_while_await_branch.get("async_kind") == "async_future", async_do_while_await_branch
    assert 0x31 in async_do_while_await_branch["code"], async_do_while_await_branch
    assert 0x30 in async_do_while_await_branch["code"], async_do_while_await_branch
    assert 0x62 in async_do_while_await_branch["code"], async_do_while_await_branch
    assert async_do_while_await_branch["code"].count(0x04) >= 5, async_do_while_await_branch
    assert 0x63 in async_do_while_await_branch["code"], async_do_while_await_branch
    async_do_while_await_branch_names = {
        entry.get("name") for entry in async_do_while_await_branch.get("debug_locals", [])
    }
    assert {"keepGoing", "i", "out", "segment"}.issubset(async_do_while_await_branch_names), async_do_while_await_branch
    assert any(
        constant.get("type") == "String" and constant.get("value") == "patched-do-while-await-branch"
        for constant in async_do_while_await_branch["constants"]
    ), async_do_while_await_branch
    async_do_while_await_local = next(
        item for item in module["functions"] if item["name"].endswith("::asyncDoWhileAwaitConditionAwaitLocal")
    )
    assert async_do_while_await_local.get("async_kind") == "async_future", async_do_while_await_local
    assert 0x31 in async_do_while_await_local["code"], async_do_while_await_local
    assert 0x30 in async_do_while_await_local["code"], async_do_while_await_local
    assert async_do_while_await_local["code"].count(0x62) >= 2, async_do_while_await_local
    assert async_do_while_await_local["code"].count(0x04) >= 5, async_do_while_await_local
    assert 0x63 in async_do_while_await_local["code"], async_do_while_await_local
    async_do_while_await_local_names = {
        entry.get("name") for entry in async_do_while_await_local.get("debug_locals", [])
    }
    assert {"keepGoing", "ready", "i", "out", "segment"}.issubset(async_do_while_await_local_names), async_do_while_await_local
    assert any(
        constant.get("type") == "String" and constant.get("value") == "patched-do-while-await-local"
        for constant in async_do_while_await_local["constants"]
    ), async_do_while_await_local
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
    async_do_while_try_catch = next(
        item for item in module["functions"] if item["name"].endswith("::asyncDoWhileTryCatchAwaitGuard")
    )
    assert async_do_while_try_catch.get("async_kind") == "async_future", async_do_while_try_catch
    assert 0x31 in async_do_while_try_catch["code"], async_do_while_try_catch
    assert 0x30 in async_do_while_try_catch["code"], async_do_while_try_catch
    assert 0x61 in async_do_while_try_catch["code"], async_do_while_try_catch
    assert 0x60 in async_do_while_try_catch["code"], async_do_while_try_catch
    assert 0x62 in async_do_while_try_catch["code"], async_do_while_try_catch
    assert async_do_while_try_catch["code"].count(0x04) >= 5, async_do_while_try_catch
    assert 0x63 in async_do_while_try_catch["code"], async_do_while_try_catch
    async_do_while_try_catch_names = {
        entry.get("name") for entry in async_do_while_try_catch.get("debug_locals", [])
    }
    assert {"limit", "fail", "i", "out"}.issubset(async_do_while_try_catch_names), async_do_while_try_catch
    for value in [
        "patched-do-while-try-catch-await-guard",
        "patched-do-while-catch-",
        "-caught-",
    ]:
        assert any(
            constant.get("type") == "String" and constant.get("value") == value
            for constant in async_do_while_try_catch["constants"]
        ), async_do_while_try_catch
    async_do_while_try_finally = next(
        item for item in module["functions"] if item["name"].endswith("::asyncDoWhileTryFinallyAwaitGuard")
    )
    assert async_do_while_try_finally.get("async_kind") == "async_future", async_do_while_try_finally
    assert 0x31 in async_do_while_try_finally["code"], async_do_while_try_finally
    assert 0x30 in async_do_while_try_finally["code"], async_do_while_try_finally
    assert 0x65 in async_do_while_try_finally["code"], async_do_while_try_finally
    assert 0x66 in async_do_while_try_finally["code"], async_do_while_try_finally
    assert async_do_while_try_finally["code"].count(0x62) >= 2, async_do_while_try_finally
    assert async_do_while_try_finally["code"].count(0x04) >= 6, async_do_while_try_finally
    assert 0x63 in async_do_while_try_finally["code"], async_do_while_try_finally
    async_do_while_try_finally_names = {
        entry.get("name") for entry in async_do_while_try_finally.get("debug_locals", [])
    }
    assert {
        "limit",
        "skip",
        "cleanup",
        "i",
        "out",
        "marker",
    }.issubset(async_do_while_try_finally_names), async_do_while_try_finally
    for value in [
        "patched-do-while-try-finally-await-guard",
        "-body-",
        "-skip-",
        "-tail-",
        "-finally-",
    ]:
        assert any(
            constant.get("type") == "String" and constant.get("value") == value
            for constant in async_do_while_try_finally["constants"]
        ), async_do_while_try_finally
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
    async_for_await_condition_guard_update = next(
        item for item in module["functions"] if item["name"].endswith("::asyncForAwaitConditionAwaitGuardContinueBreakAwaitUpdate")
    )
    assert async_for_await_condition_guard_update.get("async_kind") == "async_future", async_for_await_condition_guard_update
    assert 0x31 in async_for_await_condition_guard_update["code"], async_for_await_condition_guard_update
    assert 0x30 in async_for_await_condition_guard_update["code"], async_for_await_condition_guard_update
    assert async_for_await_condition_guard_update["code"].count(0x62) >= 4, async_for_await_condition_guard_update
    assert async_for_await_condition_guard_update["code"].count(0x04) >= 7, async_for_await_condition_guard_update
    assert 0x63 in async_for_await_condition_guard_update["code"], async_for_await_condition_guard_update
    async_for_await_condition_guard_update_names = {
        entry.get("name") for entry in async_for_await_condition_guard_update.get("debug_locals", [])
    }
    assert {
        "keepGoing",
        "skip",
        "stop",
        "next",
        "i",
        "out",
    }.issubset(async_for_await_condition_guard_update_names), async_for_await_condition_guard_update
    assert any(
        constant.get("type") == "String" and constant.get("value") == "patched-for-await-condition-guard-update"
        for constant in async_for_await_condition_guard_update["constants"]
    ), async_for_await_condition_guard_update
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
    async_for_await_condition_update_nested_branch = next(
        item for item in module["functions"] if item["name"].endswith("::asyncForAwaitConditionAwaitUpdateNestedBranchLocal")
    )
    assert async_for_await_condition_update_nested_branch.get("async_kind") == "async_future", async_for_await_condition_update_nested_branch
    assert 0x31 in async_for_await_condition_update_nested_branch["code"], async_for_await_condition_update_nested_branch
    assert 0x30 in async_for_await_condition_update_nested_branch["code"], async_for_await_condition_update_nested_branch
    assert async_for_await_condition_update_nested_branch["code"].count(0x62) >= 3, async_for_await_condition_update_nested_branch
    assert async_for_await_condition_update_nested_branch["code"].count(0x04) >= 8, async_for_await_condition_update_nested_branch
    assert 0x63 in async_for_await_condition_update_nested_branch["code"], async_for_await_condition_update_nested_branch
    async_for_await_condition_update_nested_branch_names = {
        entry.get("name") for entry in async_for_await_condition_update_nested_branch.get("debug_locals", [])
    }
    assert {
        "keepGoing",
        "premium",
        "ready",
        "next",
        "i",
        "out",
        "state",
        "tier",
    }.issubset(async_for_await_condition_update_nested_branch_names), async_for_await_condition_update_nested_branch
    for value in [
        "patched-for-await-condition-update-nested-branch",
        "patched-for-await-condition-update-nested-pro",
        "patched-for-await-condition-update-nested-basic",
        "patched-for-await-condition-update-nested-tail",
    ]:
        assert any(
            constant.get("type") == "String" and constant.get("value") == value
            for constant in async_for_await_condition_update_nested_branch["constants"]
        ), async_for_await_condition_update_nested_branch
    async_for_try_finally = next(
        item for item in module["functions"] if item["name"].endswith("::asyncForTryFinallyAwaitGuard")
    )
    assert async_for_try_finally.get("async_kind") == "async_future", async_for_try_finally
    assert 0x31 in async_for_try_finally["code"], async_for_try_finally
    assert 0x30 in async_for_try_finally["code"], async_for_try_finally
    assert 0x65 in async_for_try_finally["code"], async_for_try_finally
    assert 0x66 in async_for_try_finally["code"], async_for_try_finally
    assert async_for_try_finally["code"].count(0x62) >= 2, async_for_try_finally
    assert async_for_try_finally["code"].count(0x04) >= 6, async_for_try_finally
    assert 0x63 in async_for_try_finally["code"], async_for_try_finally
    async_for_try_finally_names = {
        entry.get("name") for entry in async_for_try_finally.get("debug_locals", [])
    }
    assert {
        "limit",
        "skip",
        "cleanup",
        "i",
        "out",
        "marker",
    }.issubset(async_for_try_finally_names), async_for_try_finally
    for value in [
        "patched-for-try-finally-await-guard",
        "-body-",
        "-skip-",
        "-tail-",
        "-finally-",
    ]:
        assert any(
            constant.get("type") == "String" and constant.get("value") == value
            for constant in async_for_try_finally["constants"]
        ), async_for_try_finally
    async_for_try_finally_await_update = next(
        item for item in module["functions"] if item["name"].endswith("::asyncForTryFinallyAwaitGuardAwaitUpdate")
    )
    assert async_for_try_finally_await_update.get("async_kind") == "async_future", async_for_try_finally_await_update
    assert 0x31 in async_for_try_finally_await_update["code"], async_for_try_finally_await_update
    assert 0x30 in async_for_try_finally_await_update["code"], async_for_try_finally_await_update
    assert 0x65 in async_for_try_finally_await_update["code"], async_for_try_finally_await_update
    assert 0x66 in async_for_try_finally_await_update["code"], async_for_try_finally_await_update
    assert async_for_try_finally_await_update["code"].count(0x62) >= 3, async_for_try_finally_await_update
    assert async_for_try_finally_await_update["code"].count(0x04) >= 6, async_for_try_finally_await_update
    assert 0x63 in async_for_try_finally_await_update["code"], async_for_try_finally_await_update
    async_for_try_finally_await_update_names = {
        entry.get("name") for entry in async_for_try_finally_await_update.get("debug_locals", [])
    }
    assert {
        "limit",
        "skip",
        "cleanup",
        "next",
        "i",
        "out",
        "marker",
    }.issubset(async_for_try_finally_await_update_names), async_for_try_finally_await_update
    for value in [
        "patched-for-try-finally-await-guard-update",
        "-body-",
        "-skip-",
        "-tail-",
        "-finally-",
    ]:
        assert any(
            constant.get("type") == "String" and constant.get("value") == value
            for constant in async_for_try_finally_await_update["constants"]
        ), async_for_try_finally_await_update
    async_for_try_catch = next(
        item for item in module["functions"] if item["name"].endswith("::asyncForTryCatchAwaitGuard")
    )
    assert async_for_try_catch.get("async_kind") == "async_future", async_for_try_catch
    assert 0x31 in async_for_try_catch["code"], async_for_try_catch
    assert 0x30 in async_for_try_catch["code"], async_for_try_catch
    assert 0x61 in async_for_try_catch["code"], async_for_try_catch
    assert 0x60 in async_for_try_catch["code"], async_for_try_catch
    assert 0x62 in async_for_try_catch["code"], async_for_try_catch
    assert async_for_try_catch["code"].count(0x04) >= 5, async_for_try_catch
    assert 0x63 in async_for_try_catch["code"], async_for_try_catch
    async_for_try_catch_names = {
        entry.get("name") for entry in async_for_try_catch.get("debug_locals", [])
    }
    assert {"limit", "fail", "i", "out"}.issubset(async_for_try_catch_names), async_for_try_catch
    for value in [
        "patched-for-try-catch-await-guard",
        "patched-for-catch-",
        "-caught-",
    ]:
        assert any(
            constant.get("type") == "String" and constant.get("value") == value
            for constant in async_for_try_catch["constants"]
        ), async_for_try_catch
    async_for_try_catch_await_update = next(
        item for item in module["functions"] if item["name"].endswith("::asyncForTryCatchAwaitGuardAwaitUpdate")
    )
    assert async_for_try_catch_await_update.get("async_kind") == "async_future", async_for_try_catch_await_update
    assert 0x31 in async_for_try_catch_await_update["code"], async_for_try_catch_await_update
    assert 0x30 in async_for_try_catch_await_update["code"], async_for_try_catch_await_update
    assert 0x61 in async_for_try_catch_await_update["code"], async_for_try_catch_await_update
    assert 0x60 in async_for_try_catch_await_update["code"], async_for_try_catch_await_update
    assert async_for_try_catch_await_update["code"].count(0x62) >= 2, async_for_try_catch_await_update
    assert async_for_try_catch_await_update["code"].count(0x04) >= 5, async_for_try_catch_await_update
    assert 0x63 in async_for_try_catch_await_update["code"], async_for_try_catch_await_update
    async_for_try_catch_await_update_names = {
        entry.get("name") for entry in async_for_try_catch_await_update.get("debug_locals", [])
    }
    assert {"limit", "fail", "next", "i", "out"}.issubset(
        async_for_try_catch_await_update_names
    ), async_for_try_catch_await_update
    for value in [
        "patched-for-try-catch-await-guard-update",
        "patched-for-catch-update-",
        "-caught-",
    ]:
        assert any(
            constant.get("type") == "String" and constant.get("value") == value
            for constant in async_for_try_catch_await_update["constants"]
        ), async_for_try_catch_await_update
    assert_async_try_loop(
        "asyncWhileAwaitConditionTryCatchAwaitGuard",
        ["keepGoing", "fail", "i", "out"],
        [
            "patched-while-await-condition-try-catch",
            "patched-while-await-condition-catch-",
            "-caught-",
        ],
        2,
        True,
    )
    assert_async_try_loop(
        "asyncWhileAwaitConditionTryFinallyAwaitGuard",
        ["keepGoing", "skip", "cleanup", "i", "out", "marker"],
        ["patched-while-await-condition-try-finally", "-finally-"],
        3,
        False,
    )
    assert_async_try_loop(
        "asyncDoWhileAwaitConditionTryCatchAwaitGuard",
        ["keepGoing", "fail", "i", "out"],
        [
            "patched-do-while-await-condition-try-catch",
            "patched-do-while-await-condition-catch-",
            "-caught-",
        ],
        3,
        True,
    )
    assert_async_try_loop(
        "asyncDoWhileAwaitConditionTryFinallyAwaitGuard",
        ["keepGoing", "skip", "cleanup", "i", "out", "marker"],
        ["patched-do-while-await-condition-try-finally", "-finally-"],
        5,
        False,
    )
    assert_async_try_loop(
        "asyncForAwaitConditionTryFinallyAwaitGuardAwaitUpdate",
        ["keepGoing", "skip", "cleanup", "next", "i", "out", "marker"],
        ["patched-for-await-condition-try-finally-update", "-finally-"],
        4,
        False,
    )
    assert_async_try_loop(
        "asyncForAwaitConditionTryCatchAwaitGuardAwaitUpdate",
        ["keepGoing", "fail", "next", "i", "out"],
        [
            "patched-for-await-condition-try-catch-update",
            "patched-for-await-condition-catch-update-",
            "-caught-",
        ],
        3,
        True,
    )
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

    def assert_multi_update_combo_module(
        name,
        params,
        debug_names,
        constants,
        min_awaits,
        has_catch=False,
        has_finally=False,
    ):
        function = next(
            item for item in module["functions"] if item["name"].endswith(f"::{name}")
        )
        assert function.get("async_kind") == "async_future", function
        assert function.get("param_count") == params, function
        assert function["code"].count(0x04) >= 10, function
        assert function["code"].count(0x30) >= 3, function
        assert function["code"].count(0x62) >= min_awaits, function
        assert 0x63 in function["code"], function
        if has_catch:
            assert 0x61 in function["code"], function
        if has_finally:
            assert 0x65 in function["code"] and 0x66 in function["code"], function
        actual_debug_names = {
            entry.get("name") for entry in function.get("debug_locals", [])
        }
        assert set(debug_names).issubset(actual_debug_names), function
        for value in constants:
            assert any(
                constant.get("type") == "String" and constant.get("value") == value
                for constant in function["constants"]
            ), function

    assert_multi_update_combo_module(
        "asyncForMultiUpdateBranchLocal",
        3,
        ["limit", "ready", "premium", "out", "i", "j", "state", "tier"],
        ["patched-for-multi-update-branch", "patched-for-multi-update-pro"],
        1,
    )
    assert_multi_update_combo_module(
        "asyncForAwaitConditionMultiUpdateBranchLocal",
        3,
        ["keepGoing", "ready", "premium", "out", "i", "j", "state", "tier"],
        [
            "patched-for-await-condition-multi-update-branch",
            "patched-for-await-condition-multi-update-pro",
        ],
        2,
    )
    assert_multi_update_combo_module(
        "asyncForMultiUpdateTryFinallyAwaitGuard",
        3,
        ["limit", "skip", "cleanup", "out", "i", "j", "marker"],
        ["patched-for-multi-update-try-finally", "-finally-"],
        2,
        has_finally=True,
    )
    assert_multi_update_combo_module(
        "asyncForAwaitConditionMultiUpdateTryCatchAwaitGuard",
        2,
        ["keepGoing", "fail", "out", "i", "j"],
        [
            "patched-for-await-condition-multi-update-try-catch",
            "patched-for-await-condition-multi-update-error-",
            "-caught-",
        ],
        3,
        has_catch=True,
    )
