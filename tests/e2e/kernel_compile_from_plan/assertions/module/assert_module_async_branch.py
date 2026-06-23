def assert_async_branch_module(module):
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
    async_if_try_finally = next(
        item for item in module["functions"] if item["name"].endswith("::asyncIfTryFinallyAwaitTail")
    )
    assert async_if_try_finally.get("async_kind") == "async_future", async_if_try_finally
    assert 0x31 in async_if_try_finally["code"], async_if_try_finally
    assert 0x65 in async_if_try_finally["code"], async_if_try_finally
    assert 0x66 in async_if_try_finally["code"], async_if_try_finally
    assert async_if_try_finally["code"].count(0x62) == 2, async_if_try_finally
    assert async_if_try_finally["code"].count(0x04) >= 4, async_if_try_finally
    assert async_if_try_finally["code"].count(0x03) >= 3, async_if_try_finally
    assert 0x63 in async_if_try_finally["code"], async_if_try_finally
    async_if_try_finally_names = {
        entry.get("name") for entry in async_if_try_finally.get("debug_locals", [])
    }
    assert {"enabled", "ready", "cleanup", "out", "value", "marker"}.issubset(
        async_if_try_finally_names
    ), async_if_try_finally
    for value in [
        "patched-if-try-finally-await-tail",
        "-on-",
        "-cleanup-",
        "-off",
    ]:
        assert any(
            constant.get("type") == "String" and constant.get("value") == value
            for constant in async_if_try_finally["constants"]
        ), async_if_try_finally
    async_if_try_catch = next(
        item for item in module["functions"] if item["name"].endswith("::asyncIfTryCatchAwaitTail")
    )
    assert async_if_try_catch.get("async_kind") == "async_future", async_if_try_catch
    assert 0x31 in async_if_try_catch["code"], async_if_try_catch
    assert 0x61 in async_if_try_catch["code"], async_if_try_catch
    assert async_if_try_catch["code"].count(0x62) == 2, async_if_try_catch
    assert async_if_try_catch["code"].count(0x04) >= 4, async_if_try_catch
    assert async_if_try_catch["code"].count(0x03) >= 4, async_if_try_catch
    assert 0x63 in async_if_try_catch["code"], async_if_try_catch
    async_if_try_catch_names = {
        entry.get("name") for entry in async_if_try_catch.get("debug_locals", [])
    }
    assert {"enabled", "ready", "recovery", "out", "value", "recovered"}.issubset(
        async_if_try_catch_names
    ), async_if_try_catch
    for value in [
        "patched-if-try-catch-await-tail",
        "-on-",
        "-caught-",
        "-off",
    ]:
        assert any(
            constant.get("type") == "String" and constant.get("value") == value
            for constant in async_if_try_catch["constants"]
        ), async_if_try_catch
    async_ifelse_try = next(
        item for item in module["functions"] if item["name"].endswith("::asyncIfElseTryFinallyCatchAwaitTail")
    )
    assert async_ifelse_try.get("async_kind") == "async_future", async_ifelse_try
    assert async_ifelse_try["code"].count(0x31) >= 1, async_ifelse_try
    assert 0x65 in async_ifelse_try["code"], async_ifelse_try
    assert 0x66 in async_ifelse_try["code"], async_ifelse_try
    assert 0x61 in async_ifelse_try["code"], async_ifelse_try
    assert async_ifelse_try["code"].count(0x62) == 4, async_ifelse_try
    assert async_ifelse_try["code"].count(0x04) >= 6, async_ifelse_try
    assert async_ifelse_try["code"].count(0x03) >= 6, async_ifelse_try
    assert 0x63 in async_ifelse_try["code"], async_ifelse_try
    async_ifelse_try_names = {
        entry.get("name") for entry in async_ifelse_try.get("debug_locals", [])
    }
    assert {"enabled", "ready", "recovery", "cleanup", "out", "value", "marker", "recovered"}.issubset(
        async_ifelse_try_names
    ), async_ifelse_try
    for value in [
        "patched-ifelse-try-finally-catch-await-tail",
        "-on-",
        "-cleanup-",
        "-off-",
        "-caught-",
    ]:
        assert any(
            constant.get("type") == "String" and constant.get("value") == value
            for constant in async_ifelse_try["constants"]
        ), async_ifelse_try

    async_ifelse_both_finally = next(
        item for item in module["functions"] if item["name"].endswith("::asyncIfElseBothTryFinallyAwaitTail")
    )
    assert async_ifelse_both_finally.get("async_kind") == "async_future", async_ifelse_both_finally
    assert async_ifelse_both_finally["code"].count(0x31) >= 1, async_ifelse_both_finally
    assert async_ifelse_both_finally["code"].count(0x65) >= 2, async_ifelse_both_finally
    assert async_ifelse_both_finally["code"].count(0x66) >= 2, async_ifelse_both_finally
    assert async_ifelse_both_finally["code"].count(0x62) == 4, async_ifelse_both_finally
    assert 0x63 in async_ifelse_both_finally["code"], async_ifelse_both_finally
    for value in [
        "patched-ifelse-both-try-finally-await-tail",
        "-on-cleanup-",
        "-off-cleanup-",
        "-tail",
    ]:
        assert any(
            constant.get("type") == "String" and constant.get("value") == value
            for constant in async_ifelse_both_finally["constants"]
        ), async_ifelse_both_finally

    async_ifelse_both_catch_finally = next(
        item for item in module["functions"] if item["name"].endswith("::asyncIfElseBothTryCatchFinallyAwaitTail")
    )
    assert async_ifelse_both_catch_finally.get("async_kind") == "async_future", async_ifelse_both_catch_finally
    assert async_ifelse_both_catch_finally["code"].count(0x31) >= 1, async_ifelse_both_catch_finally
    assert async_ifelse_both_catch_finally["code"].count(0x61) >= 2, async_ifelse_both_catch_finally
    assert async_ifelse_both_catch_finally["code"].count(0x65) >= 2, async_ifelse_both_catch_finally
    assert async_ifelse_both_catch_finally["code"].count(0x66) >= 2, async_ifelse_both_catch_finally
    assert async_ifelse_both_catch_finally["code"].count(0x62) == 6, async_ifelse_both_catch_finally
    assert 0x63 in async_ifelse_both_catch_finally["code"], async_ifelse_both_catch_finally
    for value in [
        "patched-ifelse-both-catch-finally-await-tail",
        "-on-caught-",
        "-off-caught-",
        "-off-cleanup-",
        "-tail",
    ]:
        assert any(
            constant.get("type") == "String" and constant.get("value") == value
            for constant in async_ifelse_both_catch_finally["constants"]
        ), async_ifelse_both_catch_finally

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
