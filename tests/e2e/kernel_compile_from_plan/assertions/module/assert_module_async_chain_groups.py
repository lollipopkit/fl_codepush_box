# Merged assertion group. Keep this file below the fixture size limit.


# ---- assert_module_async_awaited_runtime_collection_sources.py ----
def assert_async_awaited_runtime_collection_sources(module):
    def assert_chain(
        name,
        constants,
        *,
        min_awaits,
        has_list=False,
        has_map=False,
        min_conditionals=0,
        has_catch=False,
        has_finally=False,
    ):
        function = next(
            item for item in module["functions"] if item["name"].endswith(f"::{name}")
        )
        assert function["async_kind"] == "async_future", function
        assert function["code"].count(0x62) >= min_awaits, function
        assert 0x63 in function["code"], function
        if has_list:
            assert 0x40 in function["code"], function
        if has_map:
            assert 0x41 in function["code"], function
        if has_catch:
            assert 0x61 in function["code"], function
        if has_finally:
            assert 0x65 in function["code"], function
            assert 0x66 in function["code"], function
        assert function["code"].count(0x31) >= min_conditionals, function
        for value in constants:
            assert any(
                constant.get("type") == "String" and constant.get("value") == value
                for constant in function["constants"]
            ), function

    assert_chain(
        "asyncListAwaitedRuntimeSourcesSuperChain",
        ["patched-async-awaited-list-source-head"],
        min_awaits=3,
        has_list=True,
    )
    assert_chain(
        "asyncMapEntriesAwaitedRuntimeSourcesSuperChain",
        ["patched-async-awaited-map-source-head"],
        min_awaits=5,
        has_map=True,
        min_conditionals=1,
    )
    assert_chain(
        "asyncListAwaitedRuntimeSourcesTryCatchSwitchSuperChain",
        [
            "patched-async-awaited-list-try-premium",
            "patched-async-awaited-list-try-caught-",
        ],
        min_awaits=5,
        has_list=True,
        min_conditionals=2,
        has_catch=True,
    )
    assert_chain(
        "asyncMapAwaitedEntriesTryCatchSwitchSuperChain",
        [
            "patched-async-awaited-map-try-label",
            "patched-async-awaited-map-try-caught",
        ],
        min_awaits=6,
        has_map=True,
        min_conditionals=1,
        has_catch=True,
    )
    assert_chain(
        "asyncListAwaitedRuntimeSourcesFinallyCleanupSuperChain",
        [
            "patched-async-awaited-list-finally-enabled",
            "patched-async-awaited-list-finally-cleanup",
        ],
        min_awaits=7,
        has_list=True,
        min_conditionals=1,
        has_catch=True,
        has_finally=True,
    )
    assert_chain(
        "asyncMapAwaitedRuntimeSourcesFinallyCleanupSuperChain",
        [
            "patched-async-awaited-map-finally-premium",
            "patched-async-awaited-map-finally-cleanup",
        ],
        min_awaits=8,
        has_map=True,
        min_conditionals=1,
        has_catch=True,
        has_finally=True,
    )

# ---- assert_module_async_collection_control_super_chains.py ----
def assert_async_collection_control_super_chains(module):
    def assert_chain(
        name,
        constants,
        *,
        min_awaits,
        make_opcode,
        has_catch=False,
        has_finally=False,
    ):
        function = next(
            item for item in module["functions"] if item["name"].endswith(f"::{name}")
        )
        assert function["async_kind"] == "async_future", function
        assert function["code"].count(0x62) >= min_awaits, function
        assert make_opcode in function["code"], function
        assert 0x63 in function["code"], function
        if has_catch:
            assert 0x61 in function["code"], function
        if has_finally:
            assert 0x65 in function["code"], function
            assert 0x66 in function["code"], function
        for value in constants:
            assert any(
                constant.get("type") == "String" and constant.get("value") == value
                for constant in function["constants"]
            ), function

    assert_chain(
        "asyncListAwaitConditionSpreadForStaticSuperChain",
        [
            "patched-async-list-super-head",
            "patched-async-list-super-for-",
            "patched-async-list-super-static-spread",
        ],
        min_awaits=3,
        make_opcode=0x40,
    )
    assert_chain(
        "asyncListLoopCollectionRecoveryCleanupSuperChain",
        [
            "patched-async-list-loop-super-head",
            "patched-async-list-loop-super-premium-",
            "patched-async-list-loop-super-cleanup-",
        ],
        min_awaits=5,
        make_opcode=0x40,
        has_catch=True,
        has_finally=True,
    )
    assert_chain(
        "asyncMapAwaitConditionSpreadForStaticSuperChain",
        [
            "patched-async-map-super-head",
            "patched-async-map-super-for-",
            "patched-async-map-super-static-spread",
        ],
        min_awaits=3,
        make_opcode=0x41,
    )
    assert_chain(
        "asyncMapLoopCollectionRecoveryCleanupSuperChain",
        [
            "patched-async-map-loop-super-head",
            "patched-async-map-loop-super-premium-",
            "patched-async-map-loop-super-cleanup-",
        ],
        min_awaits=5,
        make_opcode=0x41,
        has_catch=True,
        has_finally=True,
    )

# ---- assert_module_async_collection_deep_spread_for_chains.py ----
def assert_async_collection_deep_spread_for_chains(module):
    def assert_chain(
        name,
        constants,
        *,
        min_awaits,
        make_opcode,
        has_catch=False,
        has_finally=False,
    ):
        function = next(
            item for item in module["functions"] if item["name"].endswith(f"::{name}")
        )
        assert function["async_kind"] == "async_future", function
        assert function["code"].count(0x62) >= min_awaits, function
        assert make_opcode in function["code"], function
        assert 0x63 in function["code"], function
        if has_catch:
            assert 0x61 in function["code"], function
        if has_finally:
            assert 0x65 in function["code"], function
            assert 0x66 in function["code"], function
        for value in constants:
            assert any(
                constant.get("type") == "String" and constant.get("value") == value
                for constant in function["constants"]
            ), function

    assert_chain(
        "asyncListDynamicSpreadRuntimeForDeepChain",
        [
            "patched-async-list-deep-spread-head",
            "patched-async-list-deep-spread-extra-live-",
        ],
        min_awaits=3,
        make_opcode=0x40,
    )
    assert_chain(
        "asyncListDeepSpreadTryCatchFinallyChain",
        [
            "patched-async-list-deep-spread-catch-head",
            "patched-async-list-deep-spread-caught-",
            "patched-async-list-deep-spread-cleanup-",
        ],
        min_awaits=5,
        make_opcode=0x40,
        has_catch=True,
        has_finally=True,
    )
    assert_chain(
        "asyncMapDynamicSpreadRuntimeForDeepChain",
        [
            "patched-async-map-deep-spread-head",
            "patched-async-map-deep-spread-live-",
        ],
        min_awaits=3,
        make_opcode=0x41,
    )
    assert_chain(
        "asyncMapDeepSpreadTryCatchFinallyChain",
        [
            "patched-async-map-deep-spread-catch-head",
            "patched-async-map-deep-spread-caught-",
            "patched-async-map-deep-spread-cleanup-",
        ],
        min_awaits=5,
        make_opcode=0x41,
        has_catch=True,
        has_finally=True,
    )

# ---- assert_module_async_list_for_chains.py ----
def assert_async_list_for_chains(module):
    def assert_chain(
        name,
        constants,
        *,
        min_awaits,
        has_catch=False,
        has_finally=False,
    ):
        function = next(
            item for item in module["functions"] if item["name"].endswith(f"::{name}")
        )
        assert function["async_kind"] == "async_future", function
        assert function["code"].count(0x62) >= min_awaits, function
        assert 0x40 in function["code"], function
        assert 0x63 in function["code"], function
        if has_catch:
            assert 0x61 in function["code"], function
        if has_finally:
            assert 0x65 in function["code"], function
            assert 0x66 in function["code"], function
        for value in constants:
            assert any(
                constant.get("type") == "String" and constant.get("value") == value
                for constant in function["constants"]
            ), function

    assert_chain(
        "asyncListForSourceDoubleAwaitSwitchChain",
        [
            "patched-async-list-for-source-switch-head",
            "patched-async-list-for-source-switch-premium",
        ],
        min_awaits=2,
    )
    assert_chain(
        "asyncListForSourceWhileTryFinallyLoop",
        [
            "patched-async-list-for-source-while-tier-",
            "patched-async-list-for-source-while-cleanup-",
        ],
        min_awaits=3,
        has_finally=True,
    )
    assert_chain(
        "asyncListForSourceForTryCatchFinallyRecovery",
        [
            "patched-async-list-for-source-for-premium",
            "patched-async-list-for-source-for-caught-",
            "patched-async-list-for-source-for-cleanup-",
        ],
        min_awaits=4,
        has_catch=True,
        has_finally=True,
    )
    assert_chain(
        "asyncListForSourceDoWhileCatchFinallyChain",
        [
            "patched-async-list-for-source-do-tier-",
            "patched-async-list-for-source-do-caught-",
            "patched-async-list-for-source-do-cleanup-",
        ],
        min_awaits=5,
        has_catch=True,
        has_finally=True,
    )
    assert_chain(
        "asyncListForSourceNestedBranchRecovery",
        [
            "patched-async-list-for-source-branch-head",
            "patched-async-list-for-source-branch-premium",
            "patched-async-list-for-source-branch-caught-",
        ],
        min_awaits=3,
        has_catch=True,
    )

# ---- assert_module_async_map_for_chains.py ----
def assert_async_map_for_chains(module):
    def assert_chain(
        name,
        constants,
        *,
        min_awaits,
        has_catch=False,
        has_finally=False,
    ):
        function = next(
            item for item in module["functions"] if item["name"].endswith(f"::{name}")
        )
        assert function["async_kind"] == "async_future", function
        assert function["code"].count(0x62) >= min_awaits, function
        assert 0x41 in function["code"], function
        assert 0x63 in function["code"], function
        if has_catch:
            assert 0x61 in function["code"], function
        if has_finally:
            assert 0x65 in function["code"], function
            assert 0x66 in function["code"], function
        for value in constants:
            assert any(
                constant.get("type") == "String" and constant.get("value") == value
                for constant in function["constants"]
            ), function

    assert_chain(
        "asyncMapForListSourceSwitchChain",
        [
            "patched-async-map-for-list-source-switch-head",
            "patched-async-map-for-list-source-switch-premium",
        ],
        min_awaits=2,
    )
    assert_chain(
        "asyncMapForListSourceTryFinallyCleanup",
        [
            "patched-async-map-for-list-source-finally-head",
            "patched-async-map-for-list-source-finally-cleanup-",
        ],
        min_awaits=3,
        has_finally=True,
    )
    assert_chain(
        "asyncMapForListSourceTryCatchFinallyRecovery",
        [
            "patched-async-map-for-list-source-catch-head",
            "patched-async-map-for-list-source-catch-caught-",
            "patched-async-map-for-list-source-catch-cleanup-",
        ],
        min_awaits=4,
        has_catch=True,
        has_finally=True,
    )
    assert_chain(
        "asyncMapForListSourceWhileTryFinallyLoop",
        [
            "patched-async-map-for-list-source-while-premium",
            "patched-async-map-for-list-source-while-cleanup-",
        ],
        min_awaits=3,
        has_finally=True,
    )
    assert_chain(
        "asyncMapForListSourceForSwitchFinallyChain",
        [
            "patched-async-map-for-list-source-for-value-",
            "patched-async-map-for-list-source-for-cleanup-",
        ],
        min_awaits=2,
        has_finally=True,
    )
    assert_chain(
        "asyncMapForListSourceDoWhileCatchFinallyChain",
        [
            "patched-async-map-for-list-source-do-premium",
            "patched-async-map-for-list-source-do-caught-",
            "patched-async-map-for-list-source-do-cleanup-",
        ],
        min_awaits=5,
        has_catch=True,
        has_finally=True,
    )
    assert_chain(
        "asyncMapForListSourceNestedBranchRecovery",
        [
            "patched-async-map-for-list-source-branch-head",
            "patched-async-map-for-list-source-branch-premium",
            "patched-async-map-for-list-source-branch-caught-",
        ],
        min_awaits=3,
        has_catch=True,
    )

# ---- assert_module_async_not_await_collection_chains.py ----
def assert_async_not_await_collection_chains(module):
    def assert_chain(
        name,
        constants,
        *,
        min_awaits,
        has_catch=False,
        has_finally=False,
    ):
        function = next(
            item for item in module["functions"] if item["name"].endswith(f"::{name}")
        )
        assert function["async_kind"] == "async_future", function
        assert function["code"].count(0x62) >= min_awaits, function
        assert 0x31 in function["code"], function
        assert 0x63 in function["code"], function
        if has_catch:
            assert 0x61 in function["code"], function
        if has_finally:
            assert 0x65 in function["code"], function
            assert 0x66 in function["code"], function
        for value in constants:
            assert any(
                constant.get("type") == "String" and constant.get("value") == value
                for constant in function["constants"]
            ), function

    assert_chain(
        "asyncNotAwaitCollectionIfListChain",
        [
            "patched-async-not-await-list-head",
            "patched-async-not-await-list-live-",
        ],
        min_awaits=1,
    )
    assert_chain(
        "asyncNotAwaitCollectionIfMapChain",
        [
            "patched-async-not-await-map-head",
            "patched-async-not-await-map-live-",
        ],
        min_awaits=1,
    )
    assert_chain(
        "asyncNotAwaitCollectionIfTryFinallyListCleanup",
        [
            "patched-async-not-await-list-finally-head",
            "patched-async-not-await-list-finally-cleanup-",
        ],
        min_awaits=2,
        has_finally=True,
    )
    assert_chain(
        "asyncNotAwaitCollectionIfTryCatchFinallyMapRecovery",
        [
            "patched-async-not-await-map-try-head",
            "patched-async-not-await-map-caught-",
            "patched-async-not-await-map-cleanup-",
        ],
        min_awaits=4,
        has_catch=True,
        has_finally=True,
    )

# ---- assert_module_async_not_await_control_chains.py ----
def assert_async_not_await_control_chains(module):
    def assert_chain(
        name,
        constants,
        *,
        min_awaits,
        has_catch=False,
        has_finally=False,
        has_loop=False,
    ):
        function = next(
            item for item in module["functions"] if item["name"].endswith(f"::{name}")
        )
        assert function["async_kind"] == "async_future", function
        assert function["code"].count(0x62) >= min_awaits, function
        assert 0x31 in function["code"], function
        assert 0x63 in function["code"], function
        if has_catch:
            assert 0x61 in function["code"], function
        if has_finally:
            assert 0x65 in function["code"], function
            assert 0x66 in function["code"], function
        if has_loop:
            assert 0x30 in function["code"], function
        for value in constants:
            assert any(
                constant.get("type") == "String" and constant.get("value") == value
                for constant in function["constants"]
            ), function

    assert_chain(
        "asyncNotAwaitIfTryFinallyTail",
        ["patched-async-not-await-if-finally", "-cleanup-", "-tail"],
        min_awaits=2,
        has_finally=True,
    )
    assert_chain(
        "asyncNotAwaitIfElseTryCatchFinallyTail",
        ["patched-async-not-await-ifelse", "-caught-", "-cleanup-", "-ready"],
        min_awaits=4,
        has_catch=True,
        has_finally=True,
    )
    assert_chain(
        "asyncNotAwaitWhileTryFinallyLoop",
        ["patched-async-not-await-while", "-cleanup-"],
        min_awaits=2,
        has_finally=True,
        has_loop=True,
    )
    assert_chain(
        "asyncNotAwaitForTryCatchLoop",
        ["patched-async-not-await-for", "-caught-"],
        min_awaits=3,
        has_catch=True,
        has_loop=True,
    )
    assert_chain(
        "asyncNotAwaitDoWhileFinallyCondition",
        ["patched-async-not-await-do", "-cleanup-"],
        min_awaits=2,
        has_loop=True,
    )

# ---- assert_module_async_not_await_guarded_switch_chains.py ----
def assert_async_not_await_guarded_switch_chains(module):
    def assert_chain(
        name,
        constants,
        *,
        min_awaits,
        has_catch=False,
        has_finally=False,
    ):
        function = next(
            item for item in module["functions"] if item["name"].endswith(f"::{name}")
        )
        assert function["async_kind"] == "async_future", function
        assert function["code"].count(0x62) >= min_awaits, function
        assert 0x21 in function["code"], function
        assert 0x31 in function["code"], function
        assert 0x63 in function["code"], function
        if has_catch:
            assert 0x61 in function["code"], function
        if has_finally:
            assert 0x65 in function["code"], function
            assert 0x66 in function["code"], function
        for value in constants:
            assert any(
                constant.get("type") == "String" and constant.get("value") == value
                for constant in function["constants"]
            ), function

    assert_chain(
        "asyncNotAwaitGuardedSwitchExprLabel",
        [
            "patched-not-await-guarded-switch-expr-gold",
            "patched-not-await-guarded-switch-expr-vip",
        ],
        min_awaits=2,
    )
    assert_chain(
        "asyncNotAwaitGuardedSwitchExprAwaitScrutinee",
        [
            "patched-not-await-guarded-switch-await-expr-gold",
            "patched-not-await-guarded-switch-await-expr-vip",
        ],
        min_awaits=3,
    )
    assert_chain(
        "asyncNotAwaitGuardedSwitchStatementLabel",
        [
            "patched-not-await-guarded-switch-stmt-gold",
            "patched-not-await-guarded-switch-stmt-vip",
        ],
        min_awaits=2,
    )
    assert_chain(
        "asyncNotAwaitGuardedSwitchStatementAwaitScrutinee",
        [
            "patched-not-await-guarded-switch-await-stmt-gold",
            "patched-not-await-guarded-switch-await-stmt-vip",
        ],
        min_awaits=3,
    )
    assert_chain(
        "asyncNotAwaitGuardedSwitchTryFinallyCleanup",
        [
            "patched-not-await-guarded-switch-finally-head",
            "patched-not-await-guarded-switch-finally-gold",
            "-cleanup-",
        ],
        min_awaits=3,
        has_finally=True,
    )
    assert_chain(
        "asyncNotAwaitGuardedSwitchTryCatchFinallyRecovery",
        [
            "patched-not-await-guarded-switch-catch-finally-head",
            "patched-not-await-guarded-switch-catch-finally-gold",
            "patched-not-await-guarded-switch-caught-",
            "-cleanup-",
        ],
        min_awaits=4,
        has_catch=True,
        has_finally=True,
    )

# ---- assert_module_async_object_call_type_collection_chains.py ----
def assert_async_object_call_type_collection_chains(module):
    def assert_chain(
        name,
        constants,
        *,
        min_awaits,
        requires_list_for=False,
        requires_map_for=False,
        requires_dynamic_call=False,
        requires_static_call=False,
        requires_type_ops=False,
    ):
        function = next(
            item for item in module["functions"] if item["name"].endswith(f"::{name}")
        )
        assert function["async_kind"] == "async_future", function
        assert function["code"].count(0x62) >= min_awaits, function
        assert function["code"].count(0x55) >= 2, function
        assert function["code"].count(0x31) >= 4, function
        assert 0x60 in function["code"], function
        assert 0x61 in function["code"], function
        assert 0x63 in function["code"], function
        if requires_list_for or requires_map_for:
            assert 0x55 in function["code"], function
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
        "asyncObjectCallTypeCollectionSwitchRecoveryCleanup",
        [
            "patched-async-object-call-type-head",
            "patched-async-object-call-type-user",
            "patched-async-object-call-type-blocked",
            "patched-async-object-call-type-cleanup-",
        ],
        min_awaits=5,
        requires_list_for=True,
        requires_dynamic_call=True,
        requires_type_ops=True,
    )
    assert_chain(
        "asyncNamedObjectStaticCallMapRecoveryCleanup",
        [
            "patched-async-named-object-map-head",
            "patched-async-named-object-map-blocked",
            "patched-async-named-object-map-cleanup-",
        ],
        min_awaits=5,
        requires_map_for=True,
        requires_static_call=True,
    )

# ---- assert_module_async_object_loop_finalizer_chains.py ----
def assert_async_object_loop_finalizer_chains(module):
    def assert_chain(
        name,
        constants,
        *,
        min_awaits,
        min_new_objects=0,
        has_catch=False,
        requires_dynamic_call=False,
        requires_static_call=False,
        requires_type_ops=False,
    ):
        function = next(
            item for item in module["functions"] if item["name"].endswith(f"::{name}")
        )
        assert function["async_kind"] == "async_future", function
        assert function["code"].count(0x62) >= min_awaits, function
        assert function["code"].count(0x55) >= min_new_objects, function
        assert 0x30 in function["code"], function
        assert 0x31 in function["code"], function
        assert 0x63 in function["code"], function
        assert 0x65 in function["code"], function
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
        "asyncWhileObjectDynamicTypeFinalizerChain",
        [
            "patched-async-object-loop-while-head",
            "patched-async-object-loop-while-user",
            "patched-async-object-loop-while-cleanup-",
        ],
        min_awaits=5,
        min_new_objects=2,
        requires_dynamic_call=True,
        requires_type_ops=True,
    )
    assert_chain(
        "asyncForNamedObjectStaticMapCatchFinallyChain",
        [
            "patched-async-object-loop-for-head",
            "patched-async-object-loop-for-blocked",
            "patched-async-object-loop-for-caught-",
            "patched-async-object-loop-for-cleanup-",
        ],
        min_awaits=6,
        min_new_objects=4,
        has_catch=True,
        requires_static_call=True,
    )
    assert_chain(
        "asyncDoWhileObjectCallCollectionRecoveryCleanupChain",
        [
            "patched-async-object-loop-do-head",
            "patched-async-object-loop-do-error",
            "patched-async-object-loop-do-caught-",
            "patched-async-object-loop-do-cleanup-",
        ],
        min_awaits=5,
        has_catch=True,
        requires_dynamic_call=True,
    )

# ---- assert_module_async_switch_statement_collection_chains.py ----
def assert_async_switch_statement_collection_chains(module):
    def assert_chain(
        name,
        constants,
        *,
        min_awaits,
        requires_collection_for=False,
    ):
        function = next(
            item for item in module["functions"] if item["name"].endswith(f"::{name}")
        )
        assert function["async_kind"] == "async_future", function
        assert function["code"].count(0x62) >= min_awaits, function
        assert function["code"].count(0x31) >= 3, function
        assert 0x60 in function["code"], function
        assert 0x61 in function["code"], function
        assert 0x63 in function["code"], function
        if requires_collection_for:
            assert 0x55 in function["code"], function
        for value in constants:
            assert any(
                constant.get("type") == "String" and constant.get("value") == value
                for constant in function["constants"]
            ), function

    assert_chain(
        "asyncSwitchStatementAwaitScrutineeCollectionRecoveryCleanup",
        [
            "patched-async-switch-stmt-collection-head",
            "patched-async-switch-stmt-collection-blocked",
            "patched-async-switch-stmt-collection-cleanup-",
        ],
        min_awaits=6,
        requires_collection_for=True,
    )
    assert_chain(
        "asyncSwitchStatementMapRecoveryCleanup",
        [
            "patched-async-switch-stmt-map-head",
            "patched-async-switch-stmt-map-blocked",
            "patched-async-switch-stmt-map-cleanup-",
        ],
        min_awaits=4,
        requires_collection_for=True,
    )


# ---- assert_module_async_loop_guarded_switch_chains.py ----
def assert_async_loop_guarded_switch_chains(module):
    def assert_chain(
        name,
        constants,
        *,
        min_awaits,
        has_catch=False,
    ):
        function = next(
            item for item in module["functions"] if item["name"].endswith(f"::{name}")
        )
        assert function["async_kind"] == "async_future", function
        assert function["code"].count(0x62) >= min_awaits, function
        assert 0x30 in function["code"], function
        assert 0x31 in function["code"], function
        assert 0x63 in function["code"], function
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
        "asyncWhileNotAwaitGuardedSwitchCollectionFinalizer",
        [
            "patched-loop-not-await-guarded-switch-list-head",
            "patched-loop-not-await-guarded-switch-list-gold",
            "patched-loop-not-await-guarded-switch-list-cleanup-",
        ],
        min_awaits=5,
    )
    assert_chain(
        "asyncDoWhileNotAwaitGuardedSwitchMapTryCatchFinally",
        [
            "patched-loop-not-await-guarded-switch-map-head",
            "patched-loop-not-await-guarded-switch-map-gold",
            "patched-loop-not-await-guarded-switch-map-caught-",
            "patched-loop-not-await-guarded-switch-map-cleanup-",
        ],
        min_awaits=5,
        has_catch=True,
    )
    assert_chain(
        "asyncForAwaitScrutineeNotAwaitGuardedSwitchFinally",
        [
            "patched-for-await-scrutinee-not-await-guarded-switch-head",
            "patched-for-await-scrutinee-not-await-guarded-switch-gold-",
            "patched-for-await-scrutinee-not-await-guarded-switch-cleanup-",
        ],
        min_awaits=4,
    )
    assert_chain(
        "asyncWhileAwaitScrutineeNotAwaitGuardedMapRecoveryCleanup",
        [
            "patched-while-await-scrutinee-not-await-guarded-map-head",
            "patched-while-await-scrutinee-not-await-guarded-map-gold",
            "patched-while-await-scrutinee-not-await-guarded-map-caught-",
            "patched-while-await-scrutinee-not-await-guarded-map-cleanup-",
        ],
        min_awaits=5,
        has_catch=True,
    )

# ---- assert_module_async_loop_update_chains.py ----
def assert_async_loop_update_chains(module):
    def function_named(name):
        return next(
            item for item in module["functions"] if item["name"].endswith(f"::{name}")
        )

    def assert_loop_update_chain(
        name,
        constants,
        min_awaits,
        *,
        has_catch=False,
        has_finally=False,
    ):
        function = function_named(name)
        assert function.get("async_kind") == "async_future", function
        assert 0x31 in function["code"], function
        assert 0x30 in function["code"], function
        assert function["code"].count(0x62) >= min_awaits, function
        assert function["code"].count(0x04) >= 5, function
        assert 0x63 in function["code"], function
        if has_catch:
            assert 0x61 in function["code"], function
            assert 0x60 in function["code"], function
        if has_finally:
            assert 0x65 in function["code"], function
            assert 0x66 in function["code"], function
        debug_names = {entry.get("name") for entry in function.get("debug_locals", [])}
        assert {"i", "j", "out"}.issubset(debug_names), function
        for value in constants:
            assert any(
                constant.get("type") == "String" and constant.get("value") == value
                for constant in function["constants"]
            ), function

    assert_loop_update_chain(
        "asyncForAwaitConditionMultiAwaitUpdateTryFinallyBranchLocal",
        [
            "patched-for-await-condition-multi-await-update-try-finally-branch",
            "patched-for-await-condition-multi-await-update-try-finally-pro",
        ],
        5,
        has_finally=True,
    )
    assert_loop_update_chain(
        "asyncForAwaitConditionMultiAwaitUpdateTryCatchBranchLocal",
        [
            "patched-for-await-condition-multi-await-update-try-catch-branch",
            "patched-for-await-condition-multi-await-update-try-catch-error-",
        ],
        5,
        has_catch=True,
    )
    assert_loop_update_chain(
        "asyncForMultiAwaitUpdateTryFinallyNestedBranchLocal",
        [
            "patched-for-multi-await-update-try-finally-nested",
            "-patched-for-multi-await-update-try-finally-nested-pro-",
        ],
        4,
        has_finally=True,
    )
    assert_loop_update_chain(
        "asyncForMultiAwaitUpdateTryCatchNestedBranchLocal",
        [
            "patched-for-multi-await-update-try-catch-nested",
            "patched-for-multi-await-update-try-catch-nested-error-",
        ],
        4,
        has_catch=True,
    )
    assert_loop_update_chain(
        "asyncForAwaitConditionMultiAwaitUpdateSwitchExprBranchLocal",
        [
            "patched-for-await-condition-multi-await-update-switch-expr",
            "patched-for-await-condition-multi-await-update-switch-expr-pro",
        ],
        4,
    )
    assert_loop_update_chain(
        "asyncForAwaitConditionMultiAwaitUpdateSwitchTryFinally",
        [
            "patched-for-await-condition-multi-await-update-switch-finally",
            "patched-for-await-condition-multi-await-update-switch-finally-pro",
        ],
        5,
        has_finally=True,
    )
    assert_loop_update_chain(
        "asyncForAwaitConditionMultiAwaitUpdateSwitchTryCatch",
        [
            "patched-for-await-condition-multi-await-update-switch-catch",
            "patched-for-await-condition-multi-await-update-switch-catch-error-",
        ],
        5,
        has_catch=True,
    )
    assert_loop_update_chain(
        "asyncForMultiAwaitUpdateSwitchStatementNestedBranchLocal",
        [
            "patched-for-multi-await-update-switch-stmt-nested",
            "-patched-for-multi-await-update-switch-stmt-pro-",
        ],
        3,
    )
    assert_loop_update_chain(
        "asyncForMultiAwaitUpdateSwitchStatementTryFinallyNested",
        [
            "patched-for-multi-await-update-switch-stmt-finally",
            "-patched-for-multi-await-update-switch-stmt-finally-pro-",
        ],
        4,
        has_finally=True,
    )
    assert_loop_update_chain(
        "asyncForMultiAwaitUpdateSwitchStatementTryCatchNested",
        [
            "patched-for-multi-await-update-switch-stmt-catch",
            "patched-for-multi-await-update-switch-stmt-catch-error-",
        ],
        4,
        has_catch=True,
    )
    assert_loop_update_chain(
        "asyncForAwaitConditionMultiAwaitUpdateNestedBranchTryFinally",
        [
            "patched-for-await-condition-multi-await-update-nested-finally",
            "-patched-for-await-condition-multi-await-update-nested-finally-special-",
        ],
        5,
        has_finally=True,
    )
    assert_loop_update_chain(
        "asyncForMultiAwaitUpdateTryCatchFinallyNestedBranchLocal",
        [
            "patched-for-multi-await-update-try-catch-finally-nested",
            "patched-for-multi-await-update-try-catch-finally-error-",
        ],
        5,
        has_catch=True,
        has_finally=True,
    )
    assert_loop_update_chain(
        "asyncForAwaitConditionMultiAwaitUpdateSwitchExprNestedTryFinally",
        [
            "patched-for-await-condition-multi-await-update-switch-expr-nested-finally",
            "patched-for-await-condition-multi-await-update-switch-expr-nested-finally-pro",
        ],
        5,
        has_finally=True,
    )
    assert_loop_update_chain(
        "asyncForMultiAwaitUpdateSwitchStatementTryCatchFinallyNestedBranchLocal",
        [
            "patched-for-multi-await-update-switch-stmt-catch-finally-nested",
            "patched-for-multi-await-update-switch-stmt-catch-finally-error-",
        ],
        5,
        has_catch=True,
        has_finally=True,
    )
    assert_loop_update_chain(
        "asyncForAwaitConditionMultiAwaitUpdateContinueBreakTryFinally",
        [
            "patched-for-await-condition-multi-await-update-continue-break",
            "-body-",
        ],
        6,
        has_finally=True,
    )
    assert_loop_update_chain(
        "asyncForMultiAwaitUpdateNestedSwitchExprTryCatchBranchLocal",
        [
            "patched-for-multi-await-update-nested-switch-expr-catch",
            "patched-for-multi-await-update-nested-switch-expr-catch-error-",
        ],
        4,
        has_catch=True,
    )
    assert_loop_update_chain(
        "asyncForAwaitConditionMultiAwaitUpdateCollectionTryFinallyList",
        [
            "patched-for-await-condition-multi-await-update-collection-list-head",
            "patched-for-await-condition-multi-await-update-collection-list-premium",
            "patched-for-await-condition-multi-await-update-collection-list-cleanup-",
        ],
        5,
        has_finally=True,
    )
    assert_loop_update_chain(
        "asyncForMultiAwaitUpdateCollectionTryCatchFinallyMap",
        [
            "patched-for-multi-await-update-collection-map-head",
            "patched-for-multi-await-update-collection-map-premium",
            "patched-for-multi-await-update-collection-map-cleanup-",
        ],
        6,
        has_catch=True,
        has_finally=True,
    )

# ---- assert_module_async_generator_guarded_switch_chains.py ----
def assert_async_generator_guarded_switch_chains(module):
    def assert_chain(
        name,
        constants,
        *,
        min_awaits,
        has_catch=False,
        min_streams=1,
    ):
        function = next(
            item for item in module["functions"] if item["name"].endswith(f"::{name}")
        )
        assert function["async_kind"] == "async_star", function
        assert function["code"].count(0x62) >= min_awaits, function
        assert function["code"].count(0x55) >= min_streams, function
        assert function["code"].count(0x31) >= 2, function
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
        "asyncGeneratedGuardedSwitchYieldFor",
        [
            "patched-stream-guarded-switch-yield-for-gold-",
            "patched-stream-guarded-switch-yield-for-cleanup-",
        ],
        min_awaits=4,
    )
    assert_chain(
        "asyncGeneratedGuardedSwitchListCleanup",
        [
            "patched-stream-guarded-switch-list-gold-",
            "patched-stream-guarded-switch-list-cleanup-",
        ],
        min_awaits=4,
    )
    assert_chain(
        "asyncGeneratedGuardedSwitchMapRecoveryCleanup",
        [
            "patched-stream-guarded-switch-map-gold-",
            "patched-stream-guarded-switch-map-caught-",
            "patched-stream-guarded-switch-map-cleanup-",
        ],
        min_awaits=4,
        has_catch=True,
    )
    assert_chain(
        "asyncGeneratedGuardedSwitchAwaitScrutineeYieldStar",
        [
            "patched-stream-guarded-switch-await-scrutinee-gold-",
            "patched-stream-guarded-switch-await-scrutinee-caught-",
            "patched-stream-guarded-switch-await-scrutinee-cleanup-",
        ],
        min_awaits=7,
        has_catch=True,
        min_streams=2,
    )
    assert_chain(
        "asyncGeneratedNestedGuardedSwitchAwaitForCollection",
        [
            "patched-stream-nested-guarded-switch-gold-",
            "patched-stream-nested-guarded-switch-cleanup-",
            "stop-guarded-switch-inner",
        ],
        min_awaits=6,
        min_streams=2,
    )

# ---- assert_module_async_generator_switch_statement_chains.py ----
def assert_async_generator_switch_statement_chains(module):
    function = next(
        item
        for item in module["functions"]
        if item["name"].endswith(
            "::asyncGeneratedGuardedSwitchStatementMapRecoveryCleanup"
        )
    )
    assert function["async_kind"] == "async_star", function
    assert function["code"].count(0x62) >= 4, function
    assert function["code"].count(0x31) >= 3, function
    assert function["code"].count(0x55) >= 1, function
    assert 0x60 in function["code"], function
    assert 0x61 in function["code"], function
    assert 0x64 in function["code"], function
    assert 0x65 in function["code"], function
    assert 0x66 in function["code"], function
    for value in [
        "patched-stream-guarded-switch-stmt-map-gold-",
        "patched-stream-guarded-switch-stmt-map-blocked",
        "patched-stream-guarded-switch-stmt-map-caught-",
        "patched-stream-guarded-switch-stmt-map-cleanup-",
    ]:
        assert any(
            constant.get("type") == "String" and constant.get("value") == value
            for constant in function["constants"]
        ), function


# ---- assert_module_async_generator_switch_stream_chains.py ----
def assert_async_generator_switch_stream_chains(module):
    def assert_chain(
        name,
        constants,
        *,
        min_awaits,
        min_streams,
        has_catch=False,
    ):
        function = next(
            item for item in module["functions"] if item["name"].endswith(f"::{name}")
        )
        assert function["async_kind"] == "async_star", function
        assert function["code"].count(0x62) >= min_awaits, function
        assert function["code"].count(0x55) >= min_streams, function
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
        "asyncGeneratedSwitchStatementYieldStarRecoveryCleanup",
        [
            "patched-stream-switch-stmt-yield-star-gold-head",
            "patched-stream-switch-stmt-yield-star-blocked",
            "patched-stream-switch-stmt-yield-star-caught-",
            "patched-stream-switch-stmt-yield-star-cleanup-tail-",
        ],
        min_awaits=12,
        min_streams=4,
        has_catch=True,
    )
    assert_chain(
        "asyncGeneratedNestedSwitchStatementYieldStarListCleanup",
        [
            "patched-stream-nested-switch-stmt-yield-star-list-gold-",
            "patched-stream-nested-switch-stmt-yield-star-list-blocked",
            "patched-stream-nested-switch-stmt-yield-star-list-cleanup-tail-",
        ],
        min_awaits=10,
        min_streams=3,
    )

