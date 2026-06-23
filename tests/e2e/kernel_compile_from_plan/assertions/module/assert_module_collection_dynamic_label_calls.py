def assert_collection_dynamic_label_calls(module):
    dynamic_labels = next(item for item in module["functions"] if item["name"].endswith("::dynamicLabels"))
    assert dynamic_labels["param_count"] == 1, dynamic_labels
    assert 0x41 in dynamic_labels["code"], dynamic_labels
    assert 0x51 in dynamic_labels["code"], dynamic_labels
    assert 0x03 in dynamic_labels["code"], dynamic_labels
    assert 0x04 in dynamic_labels["code"], dynamic_labels
    assert any(
        constant.get("type") == "String" and constant.get("value") == "addAll"
        for constant in dynamic_labels["constants"]
    ), dynamic_labels
    async_dynamic_labels = next(item for item in module["functions"] if item["name"].endswith("::asyncDynamicLabels"))
    assert async_dynamic_labels["async_kind"] == "async_future", async_dynamic_labels
    assert async_dynamic_labels["param_count"] == 1, async_dynamic_labels
    assert 0x41 in async_dynamic_labels["code"], async_dynamic_labels
    assert 0x51 in async_dynamic_labels["code"], async_dynamic_labels
    assert 0x03 in async_dynamic_labels["code"], async_dynamic_labels
    assert 0x04 in async_dynamic_labels["code"], async_dynamic_labels
    assert 0x63 in async_dynamic_labels["code"], async_dynamic_labels
    assert any(
        constant.get("type") == "String" and constant.get("value") == "patched-async"
        for constant in async_dynamic_labels["constants"]
    ), async_dynamic_labels
    assert any(
        constant.get("type") == "String" and constant.get("value") == "addAll"
        for constant in async_dynamic_labels["constants"]
    ), async_dynamic_labels
    runtime_for_labels = next(item for item in module["functions"] if item["name"].endswith("::runtimeForLabels"))
    assert runtime_for_labels["param_count"] == 1, runtime_for_labels
    assert 0x41 in runtime_for_labels["code"], runtime_for_labels
    assert 0x51 in runtime_for_labels["code"], runtime_for_labels
    assert 0x03 in runtime_for_labels["code"], runtime_for_labels
    assert 0x04 in runtime_for_labels["code"], runtime_for_labels
    assert 0x31 in runtime_for_labels["code"], runtime_for_labels
    assert 0x30 in runtime_for_labels["code"], runtime_for_labels
    for value in ["get:entries", "get:iterator", "moveNext", "get:current", "get:key", "get:value", "[]="]:
        assert any(
            constant.get("type") == "String" and constant.get("value") == value
            for constant in runtime_for_labels["constants"]
        ), runtime_for_labels
    async_runtime_for_labels = next(item for item in module["functions"] if item["name"].endswith("::asyncRuntimeForLabels"))
    assert async_runtime_for_labels["async_kind"] == "async_future", async_runtime_for_labels
    assert async_runtime_for_labels["param_count"] == 1, async_runtime_for_labels
    assert 0x41 in async_runtime_for_labels["code"], async_runtime_for_labels
    assert 0x51 in async_runtime_for_labels["code"], async_runtime_for_labels
    assert 0x03 in async_runtime_for_labels["code"], async_runtime_for_labels
    assert 0x04 in async_runtime_for_labels["code"], async_runtime_for_labels
    assert 0x31 in async_runtime_for_labels["code"], async_runtime_for_labels
    assert 0x30 in async_runtime_for_labels["code"], async_runtime_for_labels
    assert 0x63 in async_runtime_for_labels["code"], async_runtime_for_labels
    assert any(
        constant.get("type") == "String" and constant.get("value") == "patched-async-for"
        for constant in async_runtime_for_labels["constants"]
    ), async_runtime_for_labels
    for value in ["get:entries", "get:iterator", "moveNext", "get:current", "get:key", "get:value", "[]="]:
        assert any(
            constant.get("type") == "String" and constant.get("value") == value
            for constant in async_runtime_for_labels["constants"]
        ), async_runtime_for_labels
    async_await_runtime_for_labels = next(
        item for item in module["functions"] if item["name"].endswith("::asyncAwaitThenRuntimeForLabels")
    )
    assert async_await_runtime_for_labels["async_kind"] == "async_future", async_await_runtime_for_labels
    assert async_await_runtime_for_labels["param_count"] == 2, async_await_runtime_for_labels
    assert 0x62 in async_await_runtime_for_labels["code"], async_await_runtime_for_labels
    assert 0x03 in async_await_runtime_for_labels["code"], async_await_runtime_for_labels
    assert 0x41 in async_await_runtime_for_labels["code"], async_await_runtime_for_labels
    assert 0x51 in async_await_runtime_for_labels["code"], async_await_runtime_for_labels
    assert 0x04 in async_await_runtime_for_labels["code"], async_await_runtime_for_labels
    assert 0x31 in async_await_runtime_for_labels["code"], async_await_runtime_for_labels
    assert 0x30 in async_await_runtime_for_labels["code"], async_await_runtime_for_labels
    assert 0x55 in async_await_runtime_for_labels["code"], async_await_runtime_for_labels
    assert 0x63 in async_await_runtime_for_labels["code"], async_await_runtime_for_labels
    assert any(
        constant.get("type") == "String" and constant.get("value") == "patched-await-runtime-for"
        for constant in async_await_runtime_for_labels["constants"]
    ), async_await_runtime_for_labels
    for value in ["get:entries", "get:iterator", "moveNext", "get:current", "get:key", "get:value", "[]="]:
        assert any(
            constant.get("type") == "String" and constant.get("value") == value
            for constant in async_await_runtime_for_labels["constants"]
        ), async_await_runtime_for_labels
    choose_label = next(item for item in module["functions"] if item["name"].endswith("::chooseLabel"))
    assert choose_label["param_count"] == 1, choose_label
    assert 0x31 in choose_label["code"], choose_label
    assert 0x30 in choose_label["code"], choose_label
    assert any(
        constant.get("type") == "String" and constant.get("value") == "patched-live"
        for constant in choose_label["constants"]
    ), choose_label
    assert any(
        constant.get("type") == "String" and constant.get("value") == "patched-off"
        for constant in choose_label["constants"]
    ), choose_label
    async_await_choose_label = next(
        item for item in module["functions"] if item["name"].endswith("::asyncAwaitThenChooseLabel")
    )
    assert async_await_choose_label["async_kind"] == "async_future", async_await_choose_label
    assert async_await_choose_label["param_count"] == 1, async_await_choose_label
    assert 0x62 in async_await_choose_label["code"], async_await_choose_label
    assert 0x03 in async_await_choose_label["code"], async_await_choose_label
    assert 0x31 in async_await_choose_label["code"], async_await_choose_label
    assert 0x30 in async_await_choose_label["code"], async_await_choose_label
    assert 0x55 in async_await_choose_label["code"], async_await_choose_label
    assert 0x63 in async_await_choose_label["code"], async_await_choose_label
    for value in ["patched-await-live", "patched-await-off"]:
        assert any(
            constant.get("type") == "String" and constant.get("value") == value
            for constant in async_await_choose_label["constants"]
        ), async_await_choose_label
