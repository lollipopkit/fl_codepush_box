def assert_sync_generator_switch_iterable_chains(module):
    def assert_chain(
        name,
        constants,
        *,
        min_yields,
        has_catch=False,
    ):
        function = next(
            item for item in module["functions"] if item["name"].endswith(f"::{name}")
        )
        assert function["async_kind"] == "sync_star", function
        assert function["code"].count(0x64) >= min_yields, function
        assert function["code"].count(0x31) >= 3, function
        assert 0x60 in function["code"], function
        assert 0x64 in function["code"], function
        assert 0x65 in function["code"], function
        assert 0x66 in function["code"], function
        if has_catch:
            assert 0x61 in function["code"], function
        for value in constants:
            assert any(
                constant.get("type") == "String" and constant.get("value") == value
                for constant in function["constants"]
            ), function

    assert_chain(
        "syncGeneratedSwitchStatementYieldStarRecoveryCleanup",
        [
            "patched-iterable-switch-stmt-yield-star-gold-head",
            "patched-iterable-switch-stmt-yield-star-blocked",
            "patched-iterable-switch-stmt-yield-star-caught-",
            "patched-iterable-switch-stmt-yield-star-cleanup-head",
        ],
        min_yields=4,
        has_catch=True,
    )
    assert_chain(
        "syncGeneratedNestedSwitchStatementListCleanup",
        [
            "patched-iterable-nested-switch-stmt-list-gold-",
            "patched-iterable-nested-switch-stmt-list-blocked",
            "patched-iterable-nested-switch-stmt-list-cleanup-tail-",
        ],
        min_yields=3,
    )
