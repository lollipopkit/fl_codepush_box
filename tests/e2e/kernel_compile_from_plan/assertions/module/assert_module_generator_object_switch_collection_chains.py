def assert_generator_object_switch_collection_chains(module):
    def assert_chain(
        name,
        constants,
        *,
        min_streams,
        min_new_objects=0,
        has_catch=False,
        min_conditionals=0,
        requires_dynamic_call=False,
        requires_static_call=False,
        requires_type_ops=False,
    ):
        function = next(
            item for item in module["functions"] if item["name"].endswith(f"::{name}")
        )
        assert function.get("async_kind") == "async_star", function
        assert function["code"].count(0x55) >= min_new_objects, function
        assert function["code"].count(0x62) >= min_streams + 1, function
        assert function["code"].count(0x65) >= min_streams, function
        assert function["code"].count(0x66) >= min_streams, function
        assert 0x64 in function["code"], function
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
        "asyncGeneratedObjectSwitchListRecoveryCleanup",
        [
            "patched-stream-object-switch-list-user",
            "patched-stream-object-switch-list-blocked",
            "patched-stream-object-switch-list-cleanup-",
        ],
        min_streams=3,
        min_new_objects=2,
        has_catch=True,
        min_conditionals=4,
        requires_dynamic_call=True,
        requires_type_ops=True,
    )
    assert_chain(
        "asyncGeneratedNamedObjectSwitchMapYieldStarCleanup",
        [
            "patched-stream-object-switch-map-name",
            "patched-stream-object-switch-map-blocked",
            "patched-stream-object-switch-map-cleanup-",
        ],
        min_streams=4,
        min_new_objects=4,
        has_catch=True,
        min_conditionals=3,
        requires_static_call=True,
    )
    assert_chain(
        "asyncGeneratedObjectSwitchAwaitForYieldStarFinally",
        [
            "patched-stream-object-switch-await-for-gold-",
            "patched-stream-object-switch-await-for-cleanup-",
        ],
        min_streams=3,
        min_conditionals=3,
        requires_dynamic_call=True,
    )
