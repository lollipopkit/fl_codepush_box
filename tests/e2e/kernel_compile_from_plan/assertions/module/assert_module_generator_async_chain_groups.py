# Merged assertion group. Keep this file below the fixture size limit.


# ---- assert_module_generator_async_await_for_await_stream_chains.py ----
def assert_generator_async_await_for_await_stream_chains(module):
    def assert_chain(
        name,
        constants,
        *,
        min_awaits,
        min_streams,
        min_yields,
        min_conditionals=0,
        requires_catch=False,
    ):
        function = next(
            item for item in module["functions"] if item["name"].endswith(f"::{name}")
        )
        assert function.get("async_kind") == "async_star", function
        assert function["code"].count(0x62) >= min_awaits, function
        assert function["code"].count(0x65) >= min_streams, function
        assert function["code"].count(0x66) >= min_streams, function
        assert function["code"].count(0x64) >= min_yields, function
        assert function["code"].count(0x31) >= min_conditionals, function
        if requires_catch:
            assert 0x61 in function["code"], function
        for value in constants:
            assert any(
                constant.get("type") == "String" and constant.get("value") == value
                for constant in function["constants"]
            ), function

    assert_chain(
        "asyncGeneratedAwaitForAwaitStreamFutureSuperChain",
        [
            "patched-stream-await-for-await-stream-first-",
            "patched-stream-await-for-await-stream-second-",
            "patched-stream-await-for-await-stream-cleanup-",
        ],
        min_awaits=8,
        min_streams=3,
        min_yields=3,
        min_conditionals=1,
    )
    assert_chain(
        "asyncGeneratedAwaitForAwaitStreamFutureCatchFinallySuperChain",
        [
            "patched-stream-await-for-await-stream-catch-body-",
            "patched-stream-await-for-await-stream-catch-recovery-",
            "patched-stream-await-for-await-stream-catch-cleanup-",
        ],
        min_awaits=9,
        min_streams=3,
        min_yields=3,
        requires_catch=True,
    )

# ---- assert_module_generator_async_awaited_runtime_collection_sources.py ----
def assert_generator_async_awaited_runtime_collection_sources(module):
    def assert_chain(
        name,
        constants,
        *,
        min_awaits,
        min_streams,
        min_yields,
        min_lists=0,
        min_maps=0,
        min_conditionals=0,
    ):
        function = next(
            item for item in module["functions"] if item["name"].endswith(f"::{name}")
        )
        assert function.get("async_kind") == "async_star", function
        assert function["code"].count(0x62) >= min_awaits, function
        assert function["code"].count(0x65) >= min_streams, function
        assert function["code"].count(0x66) >= min_streams, function
        assert function["code"].count(0x64) >= min_yields, function
        assert function["code"].count(0x40) >= min_lists, function
        assert function["code"].count(0x41) >= min_maps, function
        assert function["code"].count(0x31) >= min_conditionals, function
        for value in constants:
            assert any(
                constant.get("type") == "String" and constant.get("value") == value
                for constant in function["constants"]
            ), function

    assert_chain(
        "asyncGeneratedListRuntimeForAwaitSourceCleanupSuperChain",
        [
            "patched-stream-awaited-list-source-head-",
            "patched-stream-awaited-list-source-cleanup-",
        ],
        min_awaits=7,
        min_streams=2,
        min_yields=2,
        min_lists=2,
    )
    assert_chain(
        "asyncGeneratedMapEntriesAwaitSourceCleanupSuperChain",
        [
            "patched-stream-awaited-map-source-item",
            "patched-stream-awaited-map-source-label",
            "patched-stream-awaited-map-source-cleanup",
        ],
        min_awaits=7,
        min_streams=1,
        min_yields=2,
        min_maps=2,
        min_conditionals=1,
    )

# ---- assert_module_generator_async_collection_stream_finalizer_chains.py ----
def assert_generator_async_collection_stream_finalizer_chains(module):
    def assert_chain(
        name,
        constants,
        *,
        min_awaits,
        min_streams,
        min_yields,
        min_lists=0,
        min_maps=0,
        min_conditionals=0,
    ):
        function = next(
            item for item in module["functions"] if item["name"].endswith(f"::{name}")
        )
        assert function.get("async_kind") == "async_star", function
        assert function["code"].count(0x62) >= min_awaits, function
        assert function["code"].count(0x65) >= min_streams, function
        assert function["code"].count(0x66) >= min_streams, function
        assert function["code"].count(0x64) >= min_yields, function
        assert function["code"].count(0x40) >= min_lists, function
        assert function["code"].count(0x41) >= min_maps, function
        assert function["code"].count(0x31) >= min_conditionals, function
        for value in constants:
            assert any(
                constant.get("type") == "String" and constant.get("value") == value
                for constant in function["constants"]
            ), function

    assert_chain(
        "asyncGeneratedListCollectionAwaitForFinalizerSuperChain",
        [
            "patched-stream-collection-finalizer-head",
            "patched-stream-collection-finalizer-cleanup",
        ],
        min_awaits=6,
        min_streams=2,
        min_yields=2,
        min_lists=2,
        min_conditionals=1,
    )
    assert_chain(
        "asyncGeneratedMapCollectionCatchFinallySuperChain",
        [
            "patched-stream-map-finalizer-item",
            "patched-stream-map-finalizer-label",
            "patched-stream-map-finalizer-caught",
            "patched-stream-map-finalizer-cleanup",
        ],
        min_awaits=6,
        min_streams=1,
        min_yields=3,
        min_maps=3,
        min_conditionals=1,
    )

# ---- assert_module_generator_async_nested_loop_switch_collection_chains.py ----
def assert_generator_async_nested_loop_switch_collection_chains(module):
    def assert_chain(
        name,
        constants,
        *,
        min_awaits,
        min_streams,
        min_yields,
        min_new_objects=0,
        requires_dynamic_call=False,
        requires_static_call=False,
        requires_type_ops=False,
    ):
        function = next(
            item for item in module["functions"] if item["name"].endswith(f"::{name}")
        )
        assert function.get("async_kind") == "async_star", function
        assert function["code"].count(0x62) >= min_awaits, function
        assert function["code"].count(0x65) >= min_streams, function
        assert function["code"].count(0x66) >= min_streams, function
        assert function["code"].count(0x64) >= min_yields, function
        assert function["code"].count(0x55) >= min_new_objects, function
        assert 0x30 in function["code"], function
        assert 0x31 in function["code"], function
        assert 0x60 in function["code"], function
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
        "asyncGeneratedWhileAwaitForObjectSwitchCollectionCleanup",
        [
            "patched-stream-nested-loop-switch-list-user",
            "patched-stream-nested-loop-switch-list-blocked",
            "patched-stream-nested-loop-switch-list-cleanup-",
        ],
        min_awaits=8,
        min_streams=3,
        min_yields=5,
        min_new_objects=4,
        requires_dynamic_call=True,
        requires_type_ops=True,
    )
    assert_chain(
        "asyncGeneratedForAwaitForNamedMapYieldStarCleanup",
        [
            "patched-stream-nested-loop-switch-map-name",
            "patched-stream-nested-loop-switch-map-blocked",
            "patched-stream-nested-loop-switch-map-cleanup-head",
        ],
        min_awaits=8,
        min_streams=3,
        min_yields=4,
        min_new_objects=5,
        requires_static_call=True,
    )

# ---- assert_module_generator_async_object_loop_finalizer_chains.py ----
def assert_generator_async_object_loop_finalizer_chains(module):
    def assert_chain(
        name,
        constants,
        *,
        min_awaits,
        min_streams,
        min_yields,
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
        assert function["code"].count(0x62) >= min_awaits, function
        assert function["code"].count(0x65) >= min_streams, function
        assert function["code"].count(0x66) >= min_streams, function
        assert function["code"].count(0x64) >= min_yields, function
        assert function["code"].count(0x55) >= min_new_objects, function
        assert 0x30 in function["code"], function
        assert 0x31 in function["code"], function
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
        "asyncGeneratedWhileObjectDynamicTypeFinalizerChain",
        [
            "patched-stream-object-loop-while-user",
            "patched-stream-object-loop-while-cleanup-",
        ],
        min_awaits=3,
        min_streams=1,
        min_yields=5,
        min_new_objects=2,
        requires_dynamic_call=True,
        requires_type_ops=True,
    )
    assert_chain(
        "asyncGeneratedForNamedObjectStaticMapCatchFinallyChain",
        [
            "patched-stream-object-loop-for-blocked",
            "patched-stream-object-loop-for-caught-",
            "patched-stream-object-loop-for-cleanup-head-",
        ],
        min_awaits=5,
        min_streams=2,
        min_yields=3,
        min_new_objects=3,
        has_catch=True,
        requires_static_call=True,
    )
    assert_chain(
        "asyncGeneratedDoWhileObjectCallCollectionRecoveryCleanupChain",
        [
            "patched-stream-object-loop-do-error",
            "patched-stream-object-loop-do-is-",
            "patched-stream-object-loop-do-caught-",
            "patched-stream-object-loop-do-cleanup-",
        ],
        min_awaits=6,
        min_streams=2,
        min_yields=4,
        has_catch=True,
        requires_dynamic_call=True,
        requires_type_ops=True,
    )

# ---- assert_module_generator_async_pending_guard_super_chains.py ----
def assert_generator_async_pending_guard_super_chains(module):
    def assert_chain(
        name,
        constants,
        *,
        min_awaits,
        min_streams,
        min_yields,
        min_conditionals,
    ):
        function = next(
            item for item in module["functions"] if item["name"].endswith(f"::{name}")
        )
        assert function.get("async_kind") == "async_star", function
        assert function["code"].count(0x62) >= min_awaits, function
        assert function["code"].count(0x65) >= min_streams, function
        assert function["code"].count(0x66) >= min_streams, function
        assert function["code"].count(0x64) >= min_yields, function
        assert function["code"].count(0x31) >= min_conditionals, function
        assert 0x61 in function["code"], function
        for value in constants:
            assert any(
                constant.get("type") == "String" and constant.get("value") == value
                for constant in function["constants"]
            ), function

    assert_chain(
        "asyncGeneratedStreamPendingContinueRecoveryCleanupSuperChain",
        [
            "patched-stream-pending-continue-premium-",
            "patched-stream-pending-continue-caught-",
            "patched-stream-pending-continue-cleanup-",
        ],
        min_awaits=6,
        min_streams=3,
        min_yields=3,
        min_conditionals=3,
    )
    assert_chain(
        "asyncGeneratedStreamPendingBreakRecoveryCleanupSuperChain",
        [
            "patched-stream-pending-break-premium-",
            "patched-stream-pending-break-caught-",
        ],
        min_awaits=7,
        min_streams=3,
        min_yields=4,
        min_conditionals=2,
    )
    assert_chain(
        "asyncGeneratedNestedStreamPendingGuardSuperChain",
        [
            "patched-stream-pending-nested-premium-",
            "patched-stream-pending-nested-tail-",
            "patched-stream-pending-nested-cleanup-",
        ],
        min_awaits=10,
        min_streams=5,
        min_yields=4,
        min_conditionals=3,
    )

# ---- assert_module_generator_async_stream_guarded_super_chains.py ----
def assert_generator_async_stream_guarded_super_chains(module):
    def assert_chain(
        name,
        constants,
        *,
        min_awaits,
        min_streams,
        min_yields,
        min_conditionals,
        has_loop=False,
    ):
        function = next(
            item for item in module["functions"] if item["name"].endswith(f"::{name}")
        )
        assert function.get("async_kind") == "async_star", function
        assert function["code"].count(0x62) >= min_awaits, function
        assert function["code"].count(0x65) >= min_streams, function
        assert function["code"].count(0x66) >= min_streams, function
        assert function["code"].count(0x64) >= min_yields, function
        assert function["code"].count(0x31) >= min_conditionals, function
        assert 0x61 in function["code"], function
        if has_loop:
            assert 0x30 in function["code"], function
        for value in constants:
            assert any(
                constant.get("type") == "String" and constant.get("value") == value
                for constant in function["constants"]
            ), function

    assert_chain(
        "asyncGeneratedStreamGuardedContinueBreakRecoveryCleanupSuperChain",
        [
            "patched-stream-guarded-super-premium-",
            "patched-stream-guarded-super-caught-",
            "patched-stream-guarded-super-cleanup-",
        ],
        min_awaits=6,
        min_streams=3,
        min_yields=3,
        min_conditionals=3,
    )
    assert_chain(
        "asyncGeneratedNestedStreamGuardedRecoveryCleanupSuperChain",
        [
            "patched-stream-nested-guarded-super-premium-",
            "patched-stream-nested-guarded-super-caught-",
        ],
        min_awaits=8,
        min_streams=4,
        min_yields=4,
        min_conditionals=4,
    )
    assert_chain(
        "asyncGeneratedWhileStreamGuardedDoubleCleanupSuperChain",
        [
            "patched-stream-while-guarded-super-first-",
            "patched-stream-while-guarded-super-premium-",
            "patched-stream-while-guarded-super-cleanup-",
        ],
        min_awaits=7,
        min_streams=4,
        min_yields=4,
        min_conditionals=4,
        has_loop=True,
    )

# ---- assert_module_generator_async_stream_super_chains.py ----
def assert_generator_async_stream_super_chains(module):
    def assert_chain(
        name,
        constants,
        *,
        min_awaits,
        min_streams,
        min_yields,
        min_conditionals=0,
        has_loop=False,
    ):
        function = next(
            item for item in module["functions"] if item["name"].endswith(f"::{name}")
        )
        assert function.get("async_kind") == "async_star", function
        assert function["code"].count(0x62) >= min_awaits, function
        assert function["code"].count(0x65) >= min_streams, function
        assert function["code"].count(0x66) >= min_streams, function
        assert function["code"].count(0x64) >= min_yields, function
        assert 0x61 in function["code"], function
        if min_conditionals:
            assert function["code"].count(0x31) >= min_conditionals, function
        if has_loop:
            assert 0x30 in function["code"], function
        for value in constants:
            assert any(
                constant.get("type") == "String" and constant.get("value") == value
                for constant in function["constants"]
            ), function

    assert_chain(
        "asyncGeneratedNestedAwaitForRecoveryDoubleCleanupSuperChain",
        [
            "patched-stream-super-nested-premium-",
            "patched-stream-super-nested-caught-",
            "patched-stream-super-nested-cleanup-",
        ],
        min_awaits=7,
        min_streams=5,
        min_yields=4,
        min_conditionals=2,
    )
    assert_chain(
        "asyncGeneratedYieldStarAwaitForMapRecoveryCleanupTailSuperChain",
        [
            "patched-stream-super-map-body-",
            "patched-stream-super-map-caught-",
            "patched-stream-super-map-cleanup-",
        ],
        min_awaits=7,
        min_streams=4,
        min_yields=5,
    )
    assert_chain(
        "asyncGeneratedWhileYieldStarAwaitForSwitchCleanupSuperChain",
        [
            "patched-stream-super-while-premium-",
            "patched-stream-super-while-caught-",
            "patched-stream-super-while-cleanup-",
        ],
        min_awaits=8,
        min_streams=5,
        min_yields=4,
        min_conditionals=2,
        has_loop=True,
    )

# ---- assert_module_generator_async_switch_selected_stream_chains.py ----
def assert_generator_async_switch_selected_stream_chains(module):
    def assert_chain(
        name,
        constants,
        *,
        min_awaits,
        min_streams,
        min_yields,
        min_conditionals,
    ):
        function = next(
            item for item in module["functions"] if item["name"].endswith(f"::{name}")
        )
        assert function.get("async_kind") == "async_star", function
        assert function["code"].count(0x62) >= min_awaits, function
        assert function["code"].count(0x65) >= min_streams, function
        assert function["code"].count(0x66) >= min_streams, function
        assert function["code"].count(0x64) >= min_yields, function
        assert function["code"].count(0x31) >= min_conditionals, function
        for value in constants:
            assert any(
                constant.get("type") == "String" and constant.get("value") == value
                for constant in function["constants"]
            ), function

    assert_chain(
        "asyncGeneratedYieldStarSwitchSelectedAwaitStreamSuperChain",
        ["patched-stream-switch-selected-yield-star-cleanup-"],
        min_awaits=6,
        min_streams=2,
        min_yields=2,
        min_conditionals=2,
    )
    assert_chain(
        "asyncGeneratedAwaitForSwitchSelectedAwaitStreamSuperChain",
        [
            "patched-stream-switch-selected-await-for-body-",
            "patched-stream-switch-selected-await-for-cleanup-",
        ],
        min_awaits=7,
        min_streams=2,
        min_yields=2,
        min_conditionals=3,
    )

# ---- assert_module_generator_async_switch_selected_stream_finalizer_chains.py ----
def assert_generator_async_switch_selected_stream_finalizer_chains(module):
    def assert_chain(
        name,
        constants,
        *,
        min_awaits,
        min_streams,
        min_yields,
        min_conditionals,
    ):
        function = next(
            item for item in module["functions"] if item["name"].endswith(f"::{name}")
        )
        assert function.get("async_kind") == "async_star", function
        assert function["code"].count(0x62) >= min_awaits, function
        assert function["code"].count(0x65) >= min_streams, function
        assert function["code"].count(0x66) >= min_streams, function
        assert function["code"].count(0x64) >= min_yields, function
        assert function["code"].count(0x31) >= min_conditionals, function
        for value in constants:
            assert any(
                constant.get("type") == "String" and constant.get("value") == value
                for constant in function["constants"]
            ), function

    assert_chain(
        "asyncGeneratedSwitchSelectedYieldStarThenAwaitForFinallySuperChain",
        ["patched-stream-switch-selected-finalizer-body-"],
        min_awaits=8,
        min_streams=3,
        min_yields=3,
        min_conditionals=2,
    )
    assert_chain(
        "asyncGeneratedNestedSwitchSelectedAwaitForFinallySuperChain",
        [
            "patched-stream-switch-selected-finalizer-nested-",
            "patched-stream-switch-selected-finalizer-caught-",
            "patched-stream-switch-selected-finalizer-cleanup-",
        ],
        min_awaits=10,
        min_streams=3,
        min_yields=3,
        min_conditionals=5,
    )

# ---- assert_module_generator_async_triple_switch_stream_finalizer_chains.py ----
def assert_generator_async_triple_switch_stream_finalizer_chains(module):
    def assert_chain(
        name,
        constants,
        *,
        min_awaits,
        min_streams,
        min_yields,
        min_conditionals,
    ):
        function = next(
            item for item in module["functions"] if item["name"].endswith(f"::{name}")
        )
        assert function.get("async_kind") == "async_star", function
        assert function["code"].count(0x62) >= min_awaits, function
        assert function["code"].count(0x65) >= min_streams, function
        assert function["code"].count(0x66) >= min_streams, function
        assert function["code"].count(0x64) >= min_yields, function
        assert function["code"].count(0x31) >= min_conditionals, function
        for value in constants:
            assert any(
                constant.get("type") == "String" and constant.get("value") == value
                for constant in function["constants"]
            ), function

    assert_chain(
        "asyncGeneratedTripleSwitchSelectedAwaitForFinalizerSuperChain",
        [
            "patched-stream-triple-switch-finalizer-body-",
            "patched-stream-triple-switch-finalizer-caught-",
        ],
        min_awaits=15,
        min_streams=4,
        min_yields=3,
        min_conditionals=7,
    )
    assert_chain(
        "asyncGeneratedTripleSwitchSelectedYieldStarRecoverySuperChain",
        [
            "patched-stream-triple-switch-recovery-body-",
            "patched-stream-triple-switch-recovery-cleanup-",
        ],
        min_awaits=13,
        min_streams=4,
        min_yields=4,
        min_conditionals=7,
    )

# ---- assert_module_generator_async_yield_await_collection_for_chains.py ----
def assert_generator_async_yield_await_collection_for_chains(module):
    def assert_chain(
        name,
        constants,
        *,
        min_awaits,
        min_streams,
        min_yields,
        min_conditionals,
    ):
        function = next(
            item for item in module["functions"] if item["name"].endswith(f"::{name}")
        )
        assert function.get("async_kind") == "async_star", function
        assert function["code"].count(0x62) >= min_awaits, function
        assert function["code"].count(0x65) >= min_streams, function
        assert function["code"].count(0x66) >= min_streams, function
        assert function["code"].count(0x64) >= min_yields, function
        assert function["code"].count(0x31) >= min_conditionals, function
        for value in constants:
            assert any(
                constant.get("type") == "String" and constant.get("value") == value
                for constant in function["constants"]
            ), function

    assert_chain(
        "asyncGeneratedYieldAwaitListCollectionForSuperChain",
        [
            "patched-stream-yield-await-list-for-head-",
            "patched-stream-yield-await-list-for-",
            "patched-stream-yield-await-list-for-cleanup-",
        ],
        min_awaits=6,
        min_streams=2,
        min_yields=2,
        min_conditionals=1,
    )
    assert_chain(
        "asyncGeneratedYieldAwaitMapCollectionForSuperChain",
        [
            "patched-stream-yield-await-map-for-body-",
            "patched-stream-yield-await-map-for-",
            "patched-stream-yield-await-map-for-cleanup-",
        ],
        min_awaits=6,
        min_streams=2,
        min_yields=2,
        min_conditionals=1,
    )

# ---- assert_module_generator_async_yield_await_value_chains.py ----
def assert_generator_async_yield_await_value_chains(module):
    def assert_chain(
        name,
        constants,
        *,
        min_awaits,
        min_streams,
        min_yields,
        min_conditionals,
    ):
        function = next(
            item for item in module["functions"] if item["name"].endswith(f"::{name}")
        )
        assert function.get("async_kind") == "async_star", function
        assert function["code"].count(0x62) >= min_awaits, function
        assert function["code"].count(0x65) >= min_streams, function
        assert function["code"].count(0x66) >= min_streams, function
        assert function["code"].count(0x64) >= min_yields, function
        assert function["code"].count(0x31) >= min_conditionals, function
        for value in constants:
            assert any(
                constant.get("type") == "String" and constant.get("value") == value
                for constant in function["constants"]
            ), function

    assert_chain(
        "asyncGeneratedYieldAwaitListValueSuperChain",
        [
            "patched-stream-yield-await-list-premium-",
            "patched-stream-yield-await-list-cleanup-",
        ],
        min_awaits=6,
        min_streams=2,
        min_yields=2,
        min_conditionals=1,
    )
    assert_chain(
        "asyncGeneratedYieldAwaitMapSwitchValueSuperChain",
        [
            "patched-stream-yield-await-map-premium-",
            "patched-stream-yield-await-map-cleanup-",
        ],
        min_awaits=6,
        min_streams=2,
        min_yields=2,
        min_conditionals=2,
    )
    assert_chain(
        "asyncGeneratedYieldAwaitStringValueSuperChain",
        [
            "patched-stream-yield-await-string-",
            "patched-stream-yield-await-string-cleanup-",
        ],
        min_awaits=6,
        min_streams=2,
        min_yields=2,
        min_conditionals=1,
    )

# ---- assert_module_generator_async_yield_star_await_stream_chains.py ----
def assert_generator_async_yield_star_await_stream_chains(module):
    def assert_chain(
        name,
        constants,
        *,
        min_awaits,
        min_streams,
        min_yields,
        min_conditionals=0,
        requires_catch=False,
    ):
        function = next(
            item for item in module["functions"] if item["name"].endswith(f"::{name}")
        )
        assert function.get("async_kind") == "async_star", function
        assert function["code"].count(0x62) >= min_awaits, function
        assert function["code"].count(0x65) >= min_streams, function
        assert function["code"].count(0x66) >= min_streams, function
        assert function["code"].count(0x64) >= min_yields, function
        assert function["code"].count(0x31) >= min_conditionals, function
        if requires_catch:
            assert 0x61 in function["code"], function
        for value in constants:
            assert any(
                constant.get("type") == "String" and constant.get("value") == value
                for constant in function["constants"]
            ), function

    assert_chain(
        "asyncGeneratedYieldStarAwaitStreamFutureSuperChain",
        [
            "patched-stream-yield-star-await-stream-body-",
            "patched-stream-yield-star-await-stream-cleanup-",
        ],
        min_awaits=9,
        min_streams=4,
        min_yields=4,
        min_conditionals=1,
    )
    assert_chain(
        "asyncGeneratedYieldStarAwaitStreamFutureCatchFinallySuperChain",
        ["patched-stream-yield-star-await-stream-caught-"],
        min_awaits=7,
        min_streams=3,
        min_yields=3,
        requires_catch=True,
    )
