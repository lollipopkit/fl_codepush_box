def assert_collection_static_label_calls(module):
    labels = next(item for item in module["functions"] if item["name"].endswith("::labels"))
    assert labels["param_count"] == 2, labels
    assert 0x41 in labels["code"], labels
    assert 0x31 in labels["code"], labels
    assert 0x30 in labels["code"], labels
    assert labels["code"].count(0x31) >= 2, labels
    for value in ["mode", "tail", "spread", "yes", "for", "off", "tier"]:
        assert any(
            constant.get("type") == "String" and constant.get("value") == value
            for constant in labels["constants"]
        ), labels

    async_labels = next(item for item in module["functions"] if item["name"].endswith("::asyncLabels"))
    assert async_labels["async_kind"] == "async_future", async_labels
    assert async_labels["param_count"] == 2, async_labels
    assert 0x41 in async_labels["code"], async_labels
    assert 0x31 in async_labels["code"], async_labels
    assert 0x30 in async_labels["code"], async_labels
    assert 0x63 in async_labels["code"], async_labels
    assert async_labels["code"].count(0x31) >= 2, async_labels
    for value in [
        "patched-async-static",
        "async-spread",
        "async-for",
        "async-state",
        "off",
        "async-tier",
    ]:
        assert any(
            constant.get("type") == "String" and constant.get("value") == value
            for constant in async_labels["constants"]
        ), async_labels

    async_await_labels = next(item for item in module["functions"] if item["name"].endswith("::asyncAwaitThenLabels"))
    assert async_await_labels["async_kind"] == "async_future", async_await_labels
    assert async_await_labels["param_count"] == 1, async_await_labels
    assert 0x62 in async_await_labels["code"], async_await_labels
    assert 0x03 in async_await_labels["code"], async_await_labels
    assert 0x41 in async_await_labels["code"], async_await_labels
    assert 0x55 in async_await_labels["code"], async_await_labels
    assert 0x63 in async_await_labels["code"], async_await_labels
    for value in ["mode", "patched-await-map", "value"]:
        assert any(
            constant.get("type") == "String" and constant.get("value") == value
            for constant in async_await_labels["constants"]
        ), async_await_labels
