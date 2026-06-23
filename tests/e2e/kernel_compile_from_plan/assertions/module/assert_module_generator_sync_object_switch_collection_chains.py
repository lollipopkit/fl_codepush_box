def assert_generator_sync_object_switch_collection_chains(module):
    def assert_chain(
        name,
        constants,
        *,
        min_yields,
        min_new_objects=0,
        has_catch=False,
        min_conditionals=0,
        requires_throw=True,
        requires_dynamic_call=False,
        requires_static_call=False,
        requires_type_ops=False,
    ):
        function = next(
            item for item in module["functions"] if item["name"].endswith(f"::{name}")
        )
        assert function.get("async_kind") == "sync_star", function
        assert function["code"].count(0x64) >= min_yields, function
        assert function["code"].count(0x55) >= min_new_objects, function
        assert 0x65 in function["code"], function
        assert 0x66 in function["code"], function
        if requires_throw:
            assert 0x60 in function["code"], function
        if has_catch:
            assert 0x61 in function["code"], function
        if min_conditionals:
            assert function["code"].count(0x31) >= min_conditionals, function
        if requires_dynamic_call:
            assert 0x51 in function["code"], function
        if requires_static_call:
            assert 0x50 in function["code"], function
        if requires_type_ops:
            assert 0x45 in function["code"], function
            assert 0x46 in function["code"], function
        for value in constants:
            assert any(
                constant.get("type") == "String" and constant.get("value") == value
                for constant in function["constants"]
            ), function

    assert_chain(
        "syncGeneratedObjectSwitchListRecoveryCleanup",
        [
            "patched-iterable-object-switch-list-user",
            "patched-iterable-object-switch-list-blocked",
            "patched-iterable-object-switch-list-cleanup-head",
        ],
        min_yields=3,
        min_new_objects=2,
        has_catch=True,
        min_conditionals=4,
        requires_dynamic_call=True,
        requires_type_ops=True,
    )
    assert_chain(
        "syncGeneratedNamedObjectSwitchMapYieldStarCleanup",
        [
            "patched-iterable-object-switch-map-name",
            "patched-iterable-object-switch-map-blocked",
            "patched-iterable-object-switch-map-cleanup-head",
        ],
        min_yields=3,
        min_new_objects=3,
        has_catch=True,
        min_conditionals=3,
        requires_static_call=True,
    )
    assert_chain(
        "syncGeneratedObjectSwitchForInYieldStarFinally",
        [
            "patched-iterable-object-switch-for-in-gold-",
            "patched-iterable-object-switch-for-in-cleanup-head",
        ],
        min_yields=3,
        min_conditionals=2,
        requires_throw=False,
        requires_dynamic_call=True,
    )
