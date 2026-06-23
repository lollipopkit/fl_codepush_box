def assert_generator_object_call_type_chains(module):
    def assert_chain(
        name,
        constants,
        *,
        min_streams,
        min_new_objects=0,
        has_catch=False,
        requires_dynamic_call=False,
        requires_static_call=False,
        requires_type_ops=False,
    ):
        function = next(
            item for item in module["functions"] if item["name"].endswith(f"::{name}")
        )
        assert function.get("async_kind") == "async_star", function
        assert function["code"].count(0x55) >= min_streams + min_new_objects, function
        assert function["code"].count(0x62) >= min_streams + 1, function
        assert function["code"].count(0x65) >= min_streams, function
        assert function["code"].count(0x66) >= min_streams, function
        assert 0x64 in function["code"], function
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
        "asyncGeneratedObjectDynamicTypeAwaitForCleanup",
        [
            "patched-stream-object-dynamic-type-user",
            "patched-stream-object-dynamic-type-body-",
            "patched-stream-object-dynamic-type-cleanup-",
        ],
        min_streams=2,
        min_new_objects=2,
        requires_dynamic_call=True,
        requires_type_ops=True,
    )
    assert_chain(
        "asyncGeneratedNamedObjectStaticYieldStarRecovery",
        [
            "patched-stream-named-object-static-name",
            "patched-stream-named-object-static-caught-",
        ],
        min_streams=3,
        min_new_objects=2,
        has_catch=True,
        requires_static_call=True,
    )
    assert_chain(
        "asyncGeneratedObjectCallAwaitForYieldStarFinally",
        [
            "patched-stream-object-call-await-for-",
            "patched-stream-object-call-await-for-cleanup-",
        ],
        min_streams=3,
        requires_dynamic_call=True,
    )
