def assert_generator_sync_object_loop_finalizer_chains(module):
    def assert_chain(
        name,
        constants,
        *,
        min_yields,
        min_yield_for_in,
        min_new_objects=0,
        has_catch=False,
        requires_dynamic_call=False,
        requires_static_call=False,
        requires_type_ops=False,
    ):
        function = next(
            item for item in module["functions"] if item["name"].endswith(f"::{name}")
        )
        assert function.get("async_kind") == "sync_star", function
        assert function["code"].count(0x64) >= min_yields, function
        assert function["code"].count(0x65) >= min_yield_for_in, function
        assert function["code"].count(0x55) >= min_new_objects, function
        assert 0x30 in function["code"], function
        assert 0x31 in function["code"], function
        assert 0x66 in function["code"], function
        if has_catch:
            assert 0x61 in function["code"], function
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
        "syncGeneratedWhileObjectDynamicTypeFinalizerChain",
        [
            "patched-iterable-object-loop-while-user",
            "patched-iterable-object-loop-while-cleanup-head-",
        ],
        min_yields=5,
        min_yield_for_in=1,
        min_new_objects=2,
        requires_dynamic_call=True,
        requires_type_ops=True,
    )
    assert_chain(
        "syncGeneratedForNamedObjectStaticMapCatchFinallyChain",
        [
            "patched-iterable-object-loop-for-blocked",
            "patched-iterable-object-loop-for-caught-",
            "patched-iterable-object-loop-for-cleanup-head-",
        ],
        min_yields=3,
        min_yield_for_in=1,
        min_new_objects=3,
        has_catch=True,
        requires_static_call=True,
    )
    assert_chain(
        "syncGeneratedDoWhileObjectCallCollectionRecoveryCleanupChain",
        [
            "patched-iterable-object-loop-do-error",
            "patched-iterable-object-loop-do-is-",
            "patched-iterable-object-loop-do-caught-",
            "patched-iterable-object-loop-do-cleanup-head-",
        ],
        min_yields=4,
        min_yield_for_in=2,
        has_catch=True,
        requires_dynamic_call=True,
        requires_type_ops=True,
    )
