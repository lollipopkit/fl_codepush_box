def _function(module, member):
    return next(
        item for item in module["functions"] if item["name"].endswith(f"::{member}")
    )


def _constant_values(function):
    return {
        constant.get("value")
        for constant in function.get("constants", [])
        if constant.get("type") == "String"
    }


def _assert_common(function, required_constants):
    assert function["async_kind"] == "async_future", function
    assert 0x62 in function["code"], function
    assert 0x31 in function["code"], function
    assert 0x30 in function["code"], function
    assert 0x21 in function["code"], function
    assert 0x42 in function["code"], function
    assert 0x51 in function["code"], function
    constants = _constant_values(function)
    for value in required_constants:
        assert value in constants, function


def assert_collection_switch(module):
    names = _function(module, "asyncCollectionSwitchSpreadNames")
    _assert_common(
        names,
        {
            "patched-collection-switch-list-head",
            "patched-collection-switch-list-premium",
            "patched-collection-switch-list-for-",
            "gold",
            "vip",
        },
    )

    labels = _function(module, "asyncCollectionSwitchSpreadLabels")
    _assert_common(
        labels,
        {
            "patched-collection-switch-map-head",
            "patched-collection-switch-map-premium",
            "patched-collection-switch-map-for-",
            "state",
            "gold",
            "vip",
        },
    )

    guarded_names = _function(module, "asyncCollectionGuardedSwitchSpreadNames")
    _assert_common(
        guarded_names,
        {
            "patched-collection-guarded-switch-list-head",
            "patched-collection-guarded-switch-list-gold",
            "patched-collection-guarded-switch-list-vip",
            "patched-collection-guarded-switch-list-for-",
            "gold",
            "vip",
        },
    )
    assert guarded_names["code"].count(0x31) >= 4, guarded_names

    guarded_labels = _function(module, "asyncCollectionGuardedSwitchSpreadLabels")
    _assert_common(
        guarded_labels,
        {
            "patched-collection-guarded-switch-map-head",
            "patched-collection-guarded-switch-map-gold",
            "patched-collection-guarded-switch-map-vip",
            "patched-collection-guarded-switch-map-for-",
            "state",
            "gold",
            "vip",
        },
    )
    assert guarded_labels["code"].count(0x31) >= 4, guarded_labels

    try_finally = _function(module, "asyncCollectionSwitchTryFinallyNames")
    _assert_common(
        try_finally,
        {
            "patched-collection-switch-try-finally-list-head",
            "patched-collection-switch-try-finally-list-premium",
            "patched-collection-switch-try-finally-list-for-",
            "patched-collection-switch-try-finally-list-cleanup",
        },
    )
    assert 0x65 in try_finally["code"], try_finally
    assert 0x66 in try_finally["code"], try_finally

    try_catch = _function(module, "asyncCollectionSwitchTryCatchLabels")
    _assert_common(
        try_catch,
        {
            "patched-collection-switch-try-catch-map-head",
            "patched-collection-switch-try-catch-map-premium",
            "patched-collection-switch-try-catch-map-for-",
            "patched-collection-switch-try-catch-map-caught-",
        },
    )
    assert 0x61 in try_catch["code"], try_catch

    try_catch_finally_names = _function(
        module, "asyncCollectionSwitchTryCatchFinallyAwaitNames"
    )
    _assert_common(
        try_catch_finally_names,
        {
            "patched-collection-switch-try-catch-finally-await-list-head",
            "patched-collection-switch-try-catch-finally-await-list-premium",
            "patched-collection-switch-try-catch-finally-await-list-caught-",
            "patched-collection-switch-try-catch-finally-await-list-cleanup-",
        },
    )
    assert try_catch_finally_names["code"].count(0x62) >= 3, try_catch_finally_names
    assert 0x61 in try_catch_finally_names["code"], try_catch_finally_names
    assert 0x65 in try_catch_finally_names["code"], try_catch_finally_names
    assert 0x66 in try_catch_finally_names["code"], try_catch_finally_names

    try_catch_finally_labels = _function(
        module, "asyncCollectionSwitchTryCatchFinallyAwaitLabels"
    )
    _assert_common(
        try_catch_finally_labels,
        {
            "patched-collection-switch-try-catch-finally-await-map-head",
            "patched-collection-switch-try-catch-finally-await-map-premium",
            "patched-collection-switch-try-catch-finally-await-map-caught-",
            "patched-collection-switch-try-catch-finally-await-map-cleanup-",
        },
    )
    assert try_catch_finally_labels["code"].count(0x62) >= 3, try_catch_finally_labels
    assert 0x61 in try_catch_finally_labels["code"], try_catch_finally_labels
    assert 0x65 in try_catch_finally_labels["code"], try_catch_finally_labels
    assert 0x66 in try_catch_finally_labels["code"], try_catch_finally_labels

    await_then_names = _function(
        module, "asyncAwaitThenCollectionSwitchSpreadNames"
    )
    _assert_common(
        await_then_names,
        {
            "patched-await-then-collection-switch-list-head",
            "patched-await-then-collection-switch-list-premium",
            "patched-await-then-collection-switch-list-for-",
            "gold",
            "vip",
        },
    )
    assert await_then_names["code"].count(0x62) >= 1, await_then_names
    assert await_then_names["code"].count(0x04) >= 2, await_then_names

    await_then_labels = _function(
        module, "asyncAwaitThenCollectionSwitchSpreadLabels"
    )
    _assert_common(
        await_then_labels,
        {
            "patched-await-then-collection-switch-map-head",
            "patched-await-then-collection-switch-map-premium",
            "patched-await-then-collection-switch-map-for-",
            "state",
            "gold",
            "vip",
        },
    )
    assert await_then_labels["code"].count(0x62) >= 1, await_then_labels
    assert await_then_labels["code"].count(0x04) >= 2, await_then_labels

    await_then_guarded_names = _function(
        module, "asyncAwaitThenCollectionGuardedSwitchSpreadNames"
    )
    _assert_common(
        await_then_guarded_names,
        {
            "patched-await-then-collection-guarded-switch-list-head",
            "patched-await-then-collection-guarded-switch-list-gold",
            "patched-await-then-collection-guarded-switch-list-vip",
            "patched-await-then-collection-guarded-switch-list-for-",
            "gold",
            "vip",
        },
    )
    assert await_then_guarded_names["code"].count(0x62) >= 1, await_then_guarded_names
    assert await_then_guarded_names["code"].count(0x04) >= 2, await_then_guarded_names
    assert await_then_guarded_names["code"].count(0x31) >= 4, await_then_guarded_names

    await_then_guarded_labels = _function(
        module, "asyncAwaitThenCollectionGuardedSwitchSpreadLabels"
    )
    _assert_common(
        await_then_guarded_labels,
        {
            "patched-await-then-collection-guarded-switch-map-head",
            "patched-await-then-collection-guarded-switch-map-gold",
            "patched-await-then-collection-guarded-switch-map-vip",
            "patched-await-then-collection-guarded-switch-map-for-",
            "state",
            "gold",
            "vip",
        },
    )
    assert await_then_guarded_labels["code"].count(0x62) >= 1, await_then_guarded_labels
    assert await_then_guarded_labels["code"].count(0x04) >= 2, await_then_guarded_labels
    assert await_then_guarded_labels["code"].count(0x31) >= 4, await_then_guarded_labels

    await_then_try_finally = _function(
        module, "asyncAwaitThenCollectionSwitchTryFinallyNames"
    )
    _assert_common(
        await_then_try_finally,
        {
            "patched-await-then-collection-switch-try-finally-list-head",
            "patched-await-then-collection-switch-try-finally-list-premium",
            "patched-await-then-collection-switch-try-finally-list-for-",
            "patched-await-then-collection-switch-try-finally-list-cleanup",
        },
    )
    assert 0x65 in await_then_try_finally["code"], await_then_try_finally
    assert 0x66 in await_then_try_finally["code"], await_then_try_finally

    await_then_try_catch = _function(
        module, "asyncAwaitThenCollectionSwitchTryCatchLabels"
    )
    _assert_common(
        await_then_try_catch,
        {
            "patched-await-then-collection-switch-try-catch-map-head",
            "patched-await-then-collection-switch-try-catch-map-premium",
            "patched-await-then-collection-switch-try-catch-map-for-",
            "patched-await-then-collection-switch-try-catch-map-caught-",
        },
    )
    assert 0x61 in await_then_try_catch["code"], await_then_try_catch

    double_await_names = _function(
        module, "asyncDoubleAwaitCollectionSwitchSpreadNames"
    )
    _assert_common(
        double_await_names,
        {
            "patched-double-await-collection-switch-list-head",
            "patched-double-await-collection-switch-list-premium",
            "patched-double-await-collection-switch-list-for-",
            "gold",
            "vip",
        },
    )
    assert double_await_names["code"].count(0x62) >= 2, double_await_names
    assert double_await_names["code"].count(0x04) >= 3, double_await_names

    double_await_labels = _function(
        module, "asyncDoubleAwaitCollectionSwitchSpreadLabels"
    )
    _assert_common(
        double_await_labels,
        {
            "patched-double-await-collection-switch-map-head",
            "patched-double-await-collection-switch-map-premium",
            "patched-double-await-collection-switch-map-for-",
            "state",
            "gold",
            "vip",
        },
    )
    assert double_await_labels["code"].count(0x62) >= 2, double_await_labels
    assert double_await_labels["code"].count(0x04) >= 3, double_await_labels

    double_await_guarded_names = _function(
        module, "asyncDoubleAwaitCollectionGuardedSwitchSpreadNames"
    )
    _assert_common(
        double_await_guarded_names,
        {
            "patched-double-await-collection-guarded-switch-list-head",
            "patched-double-await-collection-guarded-switch-list-gold",
            "patched-double-await-collection-guarded-switch-list-vip",
            "patched-double-await-collection-guarded-switch-list-for-",
            "gold",
            "vip",
        },
    )
    assert double_await_guarded_names["code"].count(0x62) >= 2, double_await_guarded_names
    assert double_await_guarded_names["code"].count(0x04) >= 3, double_await_guarded_names
    assert double_await_guarded_names["code"].count(0x31) >= 4, double_await_guarded_names

    double_await_guarded_labels = _function(
        module, "asyncDoubleAwaitCollectionGuardedSwitchSpreadLabels"
    )
    _assert_common(
        double_await_guarded_labels,
        {
            "patched-double-await-collection-guarded-switch-map-head",
            "patched-double-await-collection-guarded-switch-map-gold",
            "patched-double-await-collection-guarded-switch-map-vip",
            "patched-double-await-collection-guarded-switch-map-for-",
            "state",
            "gold",
            "vip",
        },
    )
    assert double_await_guarded_labels["code"].count(0x62) >= 2, double_await_guarded_labels
    assert double_await_guarded_labels["code"].count(0x04) >= 3, double_await_guarded_labels
    assert double_await_guarded_labels["code"].count(0x31) >= 4, double_await_guarded_labels

    double_await_try_finally = _function(
        module, "asyncDoubleAwaitCollectionSwitchTryFinallyNames"
    )
    _assert_common(
        double_await_try_finally,
        {
            "patched-double-await-collection-switch-try-finally-list-head",
            "patched-double-await-collection-switch-try-finally-list-premium",
            "patched-double-await-collection-switch-try-finally-list-for-",
            "patched-double-await-collection-switch-try-finally-list-cleanup",
        },
    )
    assert 0x65 in double_await_try_finally["code"], double_await_try_finally
    assert 0x66 in double_await_try_finally["code"], double_await_try_finally

    double_await_try_catch = _function(
        module, "asyncDoubleAwaitCollectionSwitchTryCatchLabels"
    )
    _assert_common(
        double_await_try_catch,
        {
            "patched-double-await-collection-switch-try-catch-map-head",
            "patched-double-await-collection-switch-try-catch-map-premium",
            "patched-double-await-collection-switch-try-catch-map-for-",
            "patched-double-await-collection-switch-try-catch-map-caught-",
        },
    )
    assert 0x61 in double_await_try_catch["code"], double_await_try_catch

    double_await_try_catch_finally_names = _function(
        module, "asyncDoubleAwaitCollectionSwitchTryCatchFinallyAwaitNames"
    )
    _assert_common(
        double_await_try_catch_finally_names,
        {
            "patched-double-await-collection-switch-try-catch-finally-await-list-head",
            "patched-double-await-collection-switch-try-catch-finally-await-list-premium",
            "patched-double-await-collection-switch-try-catch-finally-await-list-caught-",
            "patched-double-await-collection-switch-try-catch-finally-await-list-cleanup-",
        },
    )
    assert double_await_try_catch_finally_names["code"].count(0x62) >= 4, double_await_try_catch_finally_names
    assert double_await_try_catch_finally_names["code"].count(0x04) >= 3, double_await_try_catch_finally_names
    assert 0x61 in double_await_try_catch_finally_names["code"], double_await_try_catch_finally_names
    assert 0x65 in double_await_try_catch_finally_names["code"], double_await_try_catch_finally_names
    assert 0x66 in double_await_try_catch_finally_names["code"], double_await_try_catch_finally_names

    double_await_try_catch_finally_labels = _function(
        module, "asyncDoubleAwaitCollectionSwitchTryCatchFinallyAwaitLabels"
    )
    _assert_common(
        double_await_try_catch_finally_labels,
        {
            "patched-double-await-collection-switch-try-catch-finally-await-map-head",
            "patched-double-await-collection-switch-try-catch-finally-await-map-premium",
            "patched-double-await-collection-switch-try-catch-finally-await-map-caught-",
            "patched-double-await-collection-switch-try-catch-finally-await-map-cleanup-",
        },
    )
    assert double_await_try_catch_finally_labels["code"].count(0x62) >= 4, double_await_try_catch_finally_labels
    assert double_await_try_catch_finally_labels["code"].count(0x04) >= 3, double_await_try_catch_finally_labels
    assert 0x61 in double_await_try_catch_finally_labels["code"], double_await_try_catch_finally_labels
    assert 0x65 in double_await_try_catch_finally_labels["code"], double_await_try_catch_finally_labels
    assert 0x66 in double_await_try_catch_finally_labels["code"], double_await_try_catch_finally_labels
