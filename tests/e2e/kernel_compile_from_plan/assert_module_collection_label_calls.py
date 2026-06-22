from assert_module_collection_dynamic_label_calls import assert_collection_dynamic_label_calls
from assert_module_collection_static_label_calls import assert_collection_static_label_calls


def assert_string_constants(function, values):
    for value in values:
        assert any(
            constant.get("type") == "String" and constant.get("value") == value
            for constant in function["constants"]
        ), function


def assert_collection_label_calls(module):
    assert_collection_static_label_calls(module)
    async_await_conditional_labels = next(
        item for item in module["functions"] if item["name"].endswith("::asyncAwaitThenConditionalLabels")
    )
    assert async_await_conditional_labels["async_kind"] == "async_future", async_await_conditional_labels
    assert async_await_conditional_labels["param_count"] == 1, async_await_conditional_labels
    assert 0x62 in async_await_conditional_labels["code"], async_await_conditional_labels
    assert 0x03 in async_await_conditional_labels["code"], async_await_conditional_labels
    assert 0x31 in async_await_conditional_labels["code"], async_await_conditional_labels
    assert 0x30 in async_await_conditional_labels["code"], async_await_conditional_labels
    assert 0x41 in async_await_conditional_labels["code"], async_await_conditional_labels
    assert 0x55 in async_await_conditional_labels["code"], async_await_conditional_labels
    assert 0x63 in async_await_conditional_labels["code"], async_await_conditional_labels
    assert_string_constants(async_await_conditional_labels, [
        "patched-await-if-map",
        "patched-await-if-live",
        "patched-await-if-off",
        "patched-await-if-tail",
    ])
    async_await_conditional_dynamic_labels = next(
        item for item in module["functions"] if item["name"].endswith("::asyncAwaitThenConditionalDynamicLabels")
    )
    assert async_await_conditional_dynamic_labels["async_kind"] == "async_future", async_await_conditional_dynamic_labels
    assert async_await_conditional_dynamic_labels["param_count"] == 2, async_await_conditional_dynamic_labels
    assert 0x62 in async_await_conditional_dynamic_labels["code"], async_await_conditional_dynamic_labels
    assert 0x03 in async_await_conditional_dynamic_labels["code"], async_await_conditional_dynamic_labels
    assert 0x31 in async_await_conditional_dynamic_labels["code"], async_await_conditional_dynamic_labels
    assert 0x30 in async_await_conditional_dynamic_labels["code"], async_await_conditional_dynamic_labels
    assert 0x41 in async_await_conditional_dynamic_labels["code"], async_await_conditional_dynamic_labels
    assert 0x51 in async_await_conditional_dynamic_labels["code"], async_await_conditional_dynamic_labels
    assert 0x55 in async_await_conditional_dynamic_labels["code"], async_await_conditional_dynamic_labels
    assert 0x63 in async_await_conditional_dynamic_labels["code"], async_await_conditional_dynamic_labels
    assert_string_constants(async_await_conditional_dynamic_labels, [
        "patched-await-if-dynamic-map",
        "patched-await-if-dynamic-live",
        "patched-await-if-dynamic-off",
        "addAll",
    ])
    async_await_conditional_dynamic_tail_labels = next(
        item
        for item in module["functions"]
        if item["name"].endswith("::asyncAwaitThenConditionalDynamicTailLabels")
    )
    assert async_await_conditional_dynamic_tail_labels["async_kind"] == "async_future", (
        async_await_conditional_dynamic_tail_labels
    )
    assert async_await_conditional_dynamic_tail_labels["param_count"] == 2, (
        async_await_conditional_dynamic_tail_labels
    )
    for opcode in [0x62, 0x03, 0x31, 0x30, 0x41, 0x51, 0x04, 0x55, 0x63]:
        assert opcode in async_await_conditional_dynamic_tail_labels["code"], (
            async_await_conditional_dynamic_tail_labels
        )
    assert_string_constants(async_await_conditional_dynamic_tail_labels, [
        "patched-await-if-dynamic-tail-map",
        "patched-await-if-dynamic-tail-live",
        "patched-await-if-dynamic-tail-off",
        "patched-await-if-dynamic-tail-tail",
        "addAll",
    ])
    async_await_conditional_dynamic_spread_labels = next(
        item
        for item in module["functions"]
        if item["name"].endswith("::asyncAwaitThenConditionalDynamicStaticSpreadLabels")
    )
    assert async_await_conditional_dynamic_spread_labels["async_kind"] == "async_future", (
        async_await_conditional_dynamic_spread_labels
    )
    assert async_await_conditional_dynamic_spread_labels["param_count"] == 2, (
        async_await_conditional_dynamic_spread_labels
    )
    for opcode in [0x62, 0x03, 0x31, 0x30, 0x41, 0x51, 0x04, 0x55, 0x63]:
        assert opcode in async_await_conditional_dynamic_spread_labels["code"], (
            async_await_conditional_dynamic_spread_labels
        )
    assert_string_constants(async_await_conditional_dynamic_spread_labels, [
        "patched-await-if-dynamic-static-spread-map",
        "patched-await-if-dynamic-static-spread-live",
        "patched-await-if-dynamic-static-spread-off",
        "patched-await-if-dynamic-static-spread-tail",
        "addAll",
    ])
    async_await_conditional_chain_labels = next(
        item
        for item in module["functions"]
        if item["name"].endswith("::asyncAwaitThenConditionalDynamicRuntimeLabels")
    )
    assert async_await_conditional_chain_labels["async_kind"] == "async_future", async_await_conditional_chain_labels
    assert async_await_conditional_chain_labels["param_count"] == 3, async_await_conditional_chain_labels
    for opcode in [0x62, 0x03, 0x31, 0x30, 0x41, 0x51, 0x04, 0x55, 0x63]:
        assert opcode in async_await_conditional_chain_labels["code"], async_await_conditional_chain_labels
    assert_string_constants(async_await_conditional_chain_labels, [
        "patched-await-if-dynamic-runtime-map",
        "patched-await-if-dynamic-runtime-live",
        "patched-await-if-dynamic-runtime-off",
        "addAll",
        "get:entries",
        "get:iterator",
        "moveNext",
        "get:current",
        "get:key",
        "get:value",
        "[]=",
    ])
    async_await_conditional_chain_tail_labels = next(
        item
        for item in module["functions"]
        if item["name"].endswith("::asyncAwaitThenConditionalDynamicRuntimeTailLabels")
    )
    assert async_await_conditional_chain_tail_labels["async_kind"] == "async_future", (
        async_await_conditional_chain_tail_labels
    )
    assert async_await_conditional_chain_tail_labels["param_count"] == 3, (
        async_await_conditional_chain_tail_labels
    )
    for opcode in [0x62, 0x03, 0x31, 0x30, 0x41, 0x51, 0x04, 0x55, 0x63]:
        assert opcode in async_await_conditional_chain_tail_labels["code"], (
            async_await_conditional_chain_tail_labels
        )
    assert_string_constants(async_await_conditional_chain_tail_labels, [
        "patched-await-if-dynamic-runtime-tail-map",
        "patched-await-if-dynamic-runtime-tail-live",
        "patched-await-if-dynamic-runtime-tail-off",
        "patched-await-if-dynamic-runtime-tail-tail",
        "addAll",
        "get:entries",
        "get:iterator",
        "moveNext",
        "get:current",
        "get:key",
        "get:value",
        "[]=",
    ])
    async_await_conditional_chain_spread_labels = next(
        item
        for item in module["functions"]
        if item["name"].endswith("::asyncAwaitThenConditionalDynamicRuntimeStaticSpreadLabels")
    )
    assert async_await_conditional_chain_spread_labels["async_kind"] == "async_future", (
        async_await_conditional_chain_spread_labels
    )
    assert async_await_conditional_chain_spread_labels["param_count"] == 3, (
        async_await_conditional_chain_spread_labels
    )
    for opcode in [0x62, 0x03, 0x31, 0x30, 0x41, 0x51, 0x04, 0x55, 0x63]:
        assert opcode in async_await_conditional_chain_spread_labels["code"], (
            async_await_conditional_chain_spread_labels
        )
    assert_string_constants(async_await_conditional_chain_spread_labels, [
        "patched-await-if-dynamic-runtime-static-spread-map",
        "patched-await-if-dynamic-runtime-static-spread-live",
        "patched-await-if-dynamic-runtime-static-spread-off",
        "patched-await-if-dynamic-runtime-static-spread-tail",
        "addAll",
        "get:entries",
        "get:iterator",
        "moveNext",
        "get:current",
        "get:key",
        "get:value",
        "[]=",
    ])
    async_await_conditional_runtime_labels = next(
        item for item in module["functions"] if item["name"].endswith("::asyncAwaitThenConditionalRuntimeLabels")
    )
    assert async_await_conditional_runtime_labels["async_kind"] == "async_future", async_await_conditional_runtime_labels
    assert async_await_conditional_runtime_labels["param_count"] == 2, async_await_conditional_runtime_labels
    for opcode in [0x62, 0x03, 0x31, 0x30, 0x41, 0x51, 0x04, 0x55, 0x63]:
        assert opcode in async_await_conditional_runtime_labels["code"], async_await_conditional_runtime_labels
    assert_string_constants(async_await_conditional_runtime_labels, [
        "patched-await-if-runtime-map",
        "patched-await-if-runtime-live",
        "patched-await-if-runtime-off",
        "get:entries",
        "get:iterator",
        "moveNext",
        "get:current",
        "get:key",
        "get:value",
        "[]=",
    ])
    async_await_conditional_runtime_tail_labels = next(
        item
        for item in module["functions"]
        if item["name"].endswith("::asyncAwaitThenConditionalRuntimeTailLabels")
    )
    assert async_await_conditional_runtime_tail_labels["async_kind"] == "async_future", (
        async_await_conditional_runtime_tail_labels
    )
    assert async_await_conditional_runtime_tail_labels["param_count"] == 2, (
        async_await_conditional_runtime_tail_labels
    )
    for opcode in [0x62, 0x03, 0x31, 0x30, 0x41, 0x51, 0x04, 0x55, 0x63]:
        assert opcode in async_await_conditional_runtime_tail_labels["code"], (
            async_await_conditional_runtime_tail_labels
        )
    assert_string_constants(async_await_conditional_runtime_tail_labels, [
        "patched-await-if-runtime-tail-map",
        "patched-await-if-runtime-tail-live",
        "patched-await-if-runtime-tail-off",
        "patched-await-if-runtime-tail-tail",
        "get:entries",
        "get:iterator",
        "moveNext",
        "get:current",
        "get:key",
        "get:value",
        "[]=",
        "addAll",
    ])
    async_await_conditional_runtime_spread_labels = next(
        item
        for item in module["functions"]
        if item["name"].endswith("::asyncAwaitThenConditionalRuntimeStaticSpreadLabels")
    )
    assert async_await_conditional_runtime_spread_labels["async_kind"] == "async_future", (
        async_await_conditional_runtime_spread_labels
    )
    assert async_await_conditional_runtime_spread_labels["param_count"] == 2, (
        async_await_conditional_runtime_spread_labels
    )
    for opcode in [0x62, 0x03, 0x31, 0x30, 0x41, 0x51, 0x04, 0x55, 0x63]:
        assert opcode in async_await_conditional_runtime_spread_labels["code"], (
            async_await_conditional_runtime_spread_labels
        )
    assert_string_constants(async_await_conditional_runtime_spread_labels, [
        "patched-await-if-runtime-static-spread-map",
        "patched-await-if-runtime-static-spread-live",
        "patched-await-if-runtime-static-spread-off",
        "patched-await-if-runtime-static-spread-tail",
        "get:entries",
        "get:iterator",
        "moveNext",
        "get:current",
        "get:key",
        "get:value",
        "[]=",
        "addAll",
    ])
    async_await_conditional_reverse_labels = next(
        item
        for item in module["functions"]
        if item["name"].endswith("::asyncAwaitThenConditionalRuntimeDynamicLabels")
    )
    assert async_await_conditional_reverse_labels["async_kind"] == "async_future", async_await_conditional_reverse_labels
    assert async_await_conditional_reverse_labels["param_count"] == 3, async_await_conditional_reverse_labels
    for opcode in [0x62, 0x03, 0x31, 0x30, 0x41, 0x51, 0x04, 0x55, 0x63]:
        assert opcode in async_await_conditional_reverse_labels["code"], async_await_conditional_reverse_labels
    assert_string_constants(async_await_conditional_reverse_labels, [
        "patched-await-if-runtime-dynamic-map",
        "patched-await-if-runtime-dynamic-live",
        "patched-await-if-runtime-dynamic-off",
        "get:entries",
        "get:iterator",
        "moveNext",
        "get:current",
        "get:key",
        "get:value",
        "[]=",
        "addAll",
    ])
    async_await_conditional_reverse_tail_labels = next(
        item
        for item in module["functions"]
        if item["name"].endswith("::asyncAwaitThenConditionalRuntimeDynamicTailLabels")
    )
    assert async_await_conditional_reverse_tail_labels["async_kind"] == "async_future", (
        async_await_conditional_reverse_tail_labels
    )
    assert async_await_conditional_reverse_tail_labels["param_count"] == 3, (
        async_await_conditional_reverse_tail_labels
    )
    for opcode in [0x62, 0x03, 0x31, 0x30, 0x41, 0x51, 0x04, 0x55, 0x63]:
        assert opcode in async_await_conditional_reverse_tail_labels["code"], (
            async_await_conditional_reverse_tail_labels
        )
    assert_string_constants(async_await_conditional_reverse_tail_labels, [
        "patched-await-if-runtime-dynamic-tail-map",
        "patched-await-if-runtime-dynamic-tail-live",
        "patched-await-if-runtime-dynamic-tail-off",
        "patched-await-if-runtime-dynamic-tail-tail",
        "get:entries",
        "get:iterator",
        "moveNext",
        "get:current",
        "get:key",
        "get:value",
        "[]=",
        "addAll",
    ])
    async_await_conditional_reverse_spread_labels = next(
        item
        for item in module["functions"]
        if item["name"].endswith("::asyncAwaitThenConditionalRuntimeDynamicStaticSpreadLabels")
    )
    assert async_await_conditional_reverse_spread_labels["async_kind"] == "async_future", (
        async_await_conditional_reverse_spread_labels
    )
    assert async_await_conditional_reverse_spread_labels["param_count"] == 3, (
        async_await_conditional_reverse_spread_labels
    )
    for opcode in [0x62, 0x03, 0x31, 0x30, 0x41, 0x51, 0x04, 0x55, 0x63]:
        assert opcode in async_await_conditional_reverse_spread_labels["code"], (
            async_await_conditional_reverse_spread_labels
        )
    assert_string_constants(async_await_conditional_reverse_spread_labels, [
        "patched-await-if-runtime-dynamic-static-spread-map",
        "patched-await-if-runtime-dynamic-static-spread-live",
        "patched-await-if-runtime-dynamic-static-spread-off",
        "patched-await-if-runtime-dynamic-static-spread-tail",
        "get:entries",
        "get:iterator",
        "moveNext",
        "get:current",
        "get:key",
        "get:value",
        "[]=",
        "addAll",
    ])
    async_await_condition_labels = next(
        item for item in module["functions"] if item["name"].endswith("::asyncAwaitConditionLabels")
    )
    assert async_await_condition_labels["async_kind"] == "async_future", async_await_condition_labels
    assert async_await_condition_labels["param_count"] == 1, async_await_condition_labels
    for opcode in [0x62, 0x31, 0x30, 0x41, 0x55, 0x63]:
        assert opcode in async_await_condition_labels["code"], async_await_condition_labels
    assert_string_constants(async_await_condition_labels, [
        "patched-await-condition-map",
        "patched-await-condition-live",
        "patched-await-condition-off",
    ])
    async_await_condition_dynamic_labels = next(
        item for item in module["functions"] if item["name"].endswith("::asyncAwaitConditionDynamicLabels")
    )
    assert async_await_condition_dynamic_labels["async_kind"] == "async_future", async_await_condition_dynamic_labels
    assert async_await_condition_dynamic_labels["param_count"] == 2, async_await_condition_dynamic_labels
    for opcode in [0x62, 0x31, 0x30, 0x41, 0x51, 0x55, 0x63]:
        assert opcode in async_await_condition_dynamic_labels["code"], async_await_condition_dynamic_labels
    assert_string_constants(async_await_condition_dynamic_labels, [
        "patched-await-condition-dynamic-map",
        "patched-await-condition-dynamic-live",
        "patched-await-condition-dynamic-off",
        "addAll",
    ])
    async_await_condition_runtime_labels = next(
        item for item in module["functions"] if item["name"].endswith("::asyncAwaitConditionRuntimeLabels")
    )
    assert async_await_condition_runtime_labels["async_kind"] == "async_future", async_await_condition_runtime_labels
    assert async_await_condition_runtime_labels["param_count"] == 2, async_await_condition_runtime_labels
    for opcode in [0x62, 0x31, 0x30, 0x41, 0x51, 0x04, 0x55, 0x63]:
        assert opcode in async_await_condition_runtime_labels["code"], async_await_condition_runtime_labels
    assert_string_constants(async_await_condition_runtime_labels, [
        "patched-await-condition-runtime-map",
        "patched-await-condition-runtime-live",
        "patched-await-condition-runtime-off",
        "get:entries",
        "get:iterator",
        "moveNext",
        "get:current",
        "get:key",
        "get:value",
        "[]=",
    ])
    async_await_condition_chain_labels = next(
        item for item in module["functions"] if item["name"].endswith("::asyncAwaitConditionDynamicRuntimeLabels")
    )
    assert async_await_condition_chain_labels["async_kind"] == "async_future", async_await_condition_chain_labels
    assert async_await_condition_chain_labels["param_count"] == 3, async_await_condition_chain_labels
    for opcode in [0x62, 0x31, 0x30, 0x41, 0x51, 0x04, 0x55, 0x63]:
        assert opcode in async_await_condition_chain_labels["code"], async_await_condition_chain_labels
    assert_string_constants(async_await_condition_chain_labels, [
        "patched-await-condition-chain-map",
        "patched-await-condition-chain-live",
        "patched-await-condition-chain-off",
        "addAll",
        "get:entries",
        "get:iterator",
        "moveNext",
        "get:current",
        "get:key",
        "get:value",
        "[]=",
    ])
    async_await_condition_chain_spread_labels = next(
        item
        for item in module["functions"]
        if item["name"].endswith("::asyncAwaitConditionDynamicRuntimeStaticSpreadLabels")
    )
    assert async_await_condition_chain_spread_labels["async_kind"] == "async_future", (
        async_await_condition_chain_spread_labels
    )
    assert async_await_condition_chain_spread_labels["param_count"] == 3, (
        async_await_condition_chain_spread_labels
    )
    for opcode in [0x62, 0x31, 0x30, 0x41, 0x51, 0x04, 0x55, 0x63]:
        assert opcode in async_await_condition_chain_spread_labels["code"], (
            async_await_condition_chain_spread_labels
        )
    for value in [
        "patched-await-condition-chain-static-spread-map",
        "patched-await-condition-chain-static-spread-live",
        "patched-await-condition-chain-static-spread-off",
        "patched-await-condition-chain-static-spread-tail",
        "addAll",
        "get:entries",
        "get:iterator",
        "moveNext",
        "get:current",
        "get:key",
        "get:value",
        "[]=",
    ]:
        assert any(
            constant.get("type") == "String" and constant.get("value") == value
            for constant in async_await_condition_chain_spread_labels["constants"]
        ), async_await_condition_chain_spread_labels
    async_await_condition_chain_tail_labels = next(
        item
        for item in module["functions"]
        if item["name"].endswith("::asyncAwaitConditionDynamicRuntimeTailLabels")
    )
    assert async_await_condition_chain_tail_labels["async_kind"] == "async_future", (
        async_await_condition_chain_tail_labels
    )
    assert async_await_condition_chain_tail_labels["param_count"] == 3, (
        async_await_condition_chain_tail_labels
    )
    for opcode in [0x62, 0x31, 0x30, 0x41, 0x51, 0x04, 0x55, 0x63]:
        assert opcode in async_await_condition_chain_tail_labels["code"], async_await_condition_chain_tail_labels
    for value in [
        "patched-await-condition-chain-tail-map",
        "patched-await-condition-chain-tail-live",
        "patched-await-condition-chain-tail-off",
        "patched-await-condition-chain-tail-tail",
        "addAll",
        "get:entries",
        "get:iterator",
        "moveNext",
        "get:current",
        "get:key",
        "get:value",
        "[]=",
    ]:
        assert any(
            constant.get("type") == "String" and constant.get("value") == value
            for constant in async_await_condition_chain_tail_labels["constants"]
        ), async_await_condition_chain_tail_labels
    async_await_condition_reverse_chain_labels = next(
        item for item in module["functions"] if item["name"].endswith("::asyncAwaitConditionRuntimeDynamicLabels")
    )
    assert async_await_condition_reverse_chain_labels["async_kind"] == "async_future", (
        async_await_condition_reverse_chain_labels
    )
    assert async_await_condition_reverse_chain_labels["param_count"] == 3, async_await_condition_reverse_chain_labels
    for opcode in [0x62, 0x31, 0x30, 0x41, 0x51, 0x04, 0x55, 0x63]:
        assert opcode in async_await_condition_reverse_chain_labels["code"], async_await_condition_reverse_chain_labels
    for value in [
        "patched-await-condition-reverse-chain-map",
        "patched-await-condition-reverse-chain-live",
        "patched-await-condition-reverse-chain-off",
        "addAll",
        "get:entries",
        "get:iterator",
        "moveNext",
        "get:current",
        "get:key",
        "get:value",
        "[]=",
    ]:
        assert any(
            constant.get("type") == "String" and constant.get("value") == value
            for constant in async_await_condition_reverse_chain_labels["constants"]
        ), async_await_condition_reverse_chain_labels
    async_await_condition_reverse_chain_spread_labels = next(
        item
        for item in module["functions"]
        if item["name"].endswith("::asyncAwaitConditionRuntimeDynamicStaticSpreadLabels")
    )
    assert async_await_condition_reverse_chain_spread_labels["async_kind"] == "async_future", (
        async_await_condition_reverse_chain_spread_labels
    )
    assert async_await_condition_reverse_chain_spread_labels["param_count"] == 3, (
        async_await_condition_reverse_chain_spread_labels
    )
    for opcode in [0x62, 0x31, 0x30, 0x41, 0x51, 0x04, 0x55, 0x63]:
        assert opcode in async_await_condition_reverse_chain_spread_labels["code"], (
            async_await_condition_reverse_chain_spread_labels
        )
    for value in [
        "patched-await-condition-reverse-chain-static-spread-map",
        "patched-await-condition-reverse-chain-static-spread-live",
        "patched-await-condition-reverse-chain-static-spread-off",
        "patched-await-condition-reverse-chain-static-spread-tail",
        "addAll",
        "get:entries",
        "get:iterator",
        "moveNext",
        "get:current",
        "get:key",
        "get:value",
        "[]=",
    ]:
        assert any(
            constant.get("type") == "String" and constant.get("value") == value
            for constant in async_await_condition_reverse_chain_spread_labels["constants"]
        ), async_await_condition_reverse_chain_spread_labels
    async_await_condition_reverse_chain_tail_labels = next(
        item
        for item in module["functions"]
        if item["name"].endswith("::asyncAwaitConditionRuntimeDynamicTailLabels")
    )
    assert async_await_condition_reverse_chain_tail_labels["async_kind"] == "async_future", (
        async_await_condition_reverse_chain_tail_labels
    )
    assert async_await_condition_reverse_chain_tail_labels["param_count"] == 3, (
        async_await_condition_reverse_chain_tail_labels
    )
    for opcode in [0x62, 0x31, 0x30, 0x41, 0x51, 0x04, 0x55, 0x63]:
        assert opcode in async_await_condition_reverse_chain_tail_labels["code"], (
            async_await_condition_reverse_chain_tail_labels
        )
    for value in [
        "patched-await-condition-reverse-chain-tail-map",
        "patched-await-condition-reverse-chain-tail-live",
        "patched-await-condition-reverse-chain-tail-off",
        "patched-await-condition-reverse-chain-tail-tail",
        "addAll",
        "get:entries",
        "get:iterator",
        "moveNext",
        "get:current",
        "get:key",
        "get:value",
        "[]=",
    ]:
        assert any(
            constant.get("type") == "String" and constant.get("value") == value
            for constant in async_await_condition_reverse_chain_tail_labels["constants"]
        ), async_await_condition_reverse_chain_tail_labels
    async_await_condition_tail_labels = next(
        item for item in module["functions"] if item["name"].endswith("::asyncAwaitConditionDynamicTailLabels")
    )
    assert async_await_condition_tail_labels["async_kind"] == "async_future", async_await_condition_tail_labels
    assert async_await_condition_tail_labels["param_count"] == 2, async_await_condition_tail_labels
    for opcode in [0x62, 0x31, 0x30, 0x41, 0x51, 0x04, 0x55, 0x63]:
        assert opcode in async_await_condition_tail_labels["code"], async_await_condition_tail_labels
    for value in [
        "patched-await-condition-tail-chain-map",
        "patched-await-condition-tail-chain-live",
        "patched-await-condition-tail-chain-off",
        "patched-await-condition-tail-chain-tail",
        "addAll",
    ]:
        assert any(
            constant.get("type") == "String" and constant.get("value") == value
            for constant in async_await_condition_tail_labels["constants"]
        ), async_await_condition_tail_labels
    async_await_condition_runtime_tail_labels = next(
        item for item in module["functions"] if item["name"].endswith("::asyncAwaitConditionRuntimeTailLabels")
    )
    assert async_await_condition_runtime_tail_labels["async_kind"] == "async_future", (
        async_await_condition_runtime_tail_labels
    )
    assert async_await_condition_runtime_tail_labels["param_count"] == 2, async_await_condition_runtime_tail_labels
    for opcode in [0x62, 0x31, 0x30, 0x41, 0x51, 0x04, 0x55, 0x63]:
        assert opcode in async_await_condition_runtime_tail_labels["code"], async_await_condition_runtime_tail_labels
    for value in [
        "patched-await-condition-runtime-tail-map",
        "patched-await-condition-runtime-tail-live",
        "patched-await-condition-runtime-tail-off",
        "patched-await-condition-runtime-tail-tail",
        "addAll",
        "get:entries",
        "get:iterator",
        "moveNext",
        "get:current",
        "get:key",
        "get:value",
        "[]=",
    ]:
        assert any(
            constant.get("type") == "String" and constant.get("value") == value
            for constant in async_await_condition_runtime_tail_labels["constants"]
        ), async_await_condition_runtime_tail_labels
    async_await_condition_static_spread_labels = next(
        item
        for item in module["functions"]
        if item["name"].endswith("::asyncAwaitConditionDynamicStaticSpreadLabels")
    )
    assert async_await_condition_static_spread_labels["async_kind"] == "async_future", (
        async_await_condition_static_spread_labels
    )
    assert async_await_condition_static_spread_labels["param_count"] == 2, (
        async_await_condition_static_spread_labels
    )
    for opcode in [0x62, 0x31, 0x30, 0x41, 0x51, 0x04, 0x55, 0x63]:
        assert opcode in async_await_condition_static_spread_labels["code"], (
            async_await_condition_static_spread_labels
        )
    for value in [
        "patched-await-condition-static-spread-map",
        "patched-await-condition-static-spread-live",
        "patched-await-condition-static-spread-off",
        "patched-await-condition-static-spread-tail",
        "addAll",
    ]:
        assert any(
            constant.get("type") == "String" and constant.get("value") == value
            for constant in async_await_condition_static_spread_labels["constants"]
        ), async_await_condition_static_spread_labels
    async_await_condition_runtime_static_spread_labels = next(
        item
        for item in module["functions"]
        if item["name"].endswith("::asyncAwaitConditionRuntimeStaticSpreadLabels")
    )
    assert async_await_condition_runtime_static_spread_labels["async_kind"] == "async_future", (
        async_await_condition_runtime_static_spread_labels
    )
    assert async_await_condition_runtime_static_spread_labels["param_count"] == 2, (
        async_await_condition_runtime_static_spread_labels
    )
    for opcode in [0x62, 0x31, 0x30, 0x41, 0x51, 0x04, 0x55, 0x63]:
        assert opcode in async_await_condition_runtime_static_spread_labels["code"], (
            async_await_condition_runtime_static_spread_labels
        )
    for value in [
        "patched-await-condition-runtime-static-spread-map",
        "patched-await-condition-runtime-static-spread-live",
        "patched-await-condition-runtime-static-spread-off",
        "patched-await-condition-runtime-static-spread-tail",
        "addAll",
        "get:entries",
        "get:iterator",
        "moveNext",
        "get:current",
        "get:key",
        "get:value",
        "[]=",
    ]:
        assert any(
            constant.get("type") == "String" and constant.get("value") == value
            for constant in async_await_condition_runtime_static_spread_labels["constants"]
        ), async_await_condition_runtime_static_spread_labels
    dynamic_names = next(item for item in module["functions"] if item["name"].endswith("::dynamicNames"))
    assert dynamic_names["param_count"] == 1, dynamic_names
    assert 0x40 in dynamic_names["code"], dynamic_names
    assert 0x51 in dynamic_names["code"], dynamic_names
    assert 0x03 in dynamic_names["code"], dynamic_names
    assert 0x04 in dynamic_names["code"], dynamic_names
    assert any(
        constant.get("type") == "String" and constant.get("value") == "addAll"
        for constant in dynamic_names["constants"]
    ), dynamic_names
    async_dynamic_names = next(item for item in module["functions"] if item["name"].endswith("::asyncDynamicNames"))
    assert async_dynamic_names["async_kind"] == "async_future", async_dynamic_names
    assert async_dynamic_names["param_count"] == 1, async_dynamic_names
    assert 0x40 in async_dynamic_names["code"], async_dynamic_names
    assert 0x51 in async_dynamic_names["code"], async_dynamic_names
    assert 0x63 in async_dynamic_names["code"], async_dynamic_names
    assert any(
        constant.get("type") == "String" and constant.get("value") == "addAll"
        for constant in async_dynamic_names["constants"]
    ), async_dynamic_names
    assert any(
        constant.get("type") == "String" and constant.get("value") == "patched-async"
        for constant in async_dynamic_names["constants"]
    ), async_dynamic_names
    async_await_dynamic_names = next(
        item for item in module["functions"] if item["name"].endswith("::asyncAwaitThenDynamicNames")
    )
    assert async_await_dynamic_names["async_kind"] == "async_future", async_await_dynamic_names
    assert async_await_dynamic_names["param_count"] == 2, async_await_dynamic_names
    assert 0x62 in async_await_dynamic_names["code"], async_await_dynamic_names
    assert 0x03 in async_await_dynamic_names["code"], async_await_dynamic_names
    assert 0x40 in async_await_dynamic_names["code"], async_await_dynamic_names
    assert 0x51 in async_await_dynamic_names["code"], async_await_dynamic_names
    assert 0x55 in async_await_dynamic_names["code"], async_await_dynamic_names
    assert 0x63 in async_await_dynamic_names["code"], async_await_dynamic_names
    assert any(
        constant.get("type") == "String" and constant.get("value") == "patched-await-dynamic"
        for constant in async_await_dynamic_names["constants"]
    ), async_await_dynamic_names
    assert any(
        constant.get("type") == "String" and constant.get("value") == "addAll"
        for constant in async_await_dynamic_names["constants"]
    ), async_await_dynamic_names
    async_await_dynamic_labels = next(
        item for item in module["functions"] if item["name"].endswith("::asyncAwaitThenDynamicLabels")
    )
    assert async_await_dynamic_labels["async_kind"] == "async_future", async_await_dynamic_labels
    assert async_await_dynamic_labels["param_count"] == 2, async_await_dynamic_labels
    assert 0x62 in async_await_dynamic_labels["code"], async_await_dynamic_labels
    assert 0x03 in async_await_dynamic_labels["code"], async_await_dynamic_labels
    assert 0x41 in async_await_dynamic_labels["code"], async_await_dynamic_labels
    assert 0x51 in async_await_dynamic_labels["code"], async_await_dynamic_labels
    assert 0x55 in async_await_dynamic_labels["code"], async_await_dynamic_labels
    assert 0x63 in async_await_dynamic_labels["code"], async_await_dynamic_labels
    assert any(
        constant.get("type") == "String" and constant.get("value") == "patched-await-dynamic-map"
        for constant in async_await_dynamic_labels["constants"]
    ), async_await_dynamic_labels
    assert any(
        constant.get("type") == "String" and constant.get("value") == "addAll"
        for constant in async_await_dynamic_labels["constants"]
    ), async_await_dynamic_labels
    runtime_for_names = next(item for item in module["functions"] if item["name"].endswith("::runtimeForNames"))
    assert runtime_for_names["param_count"] == 1, runtime_for_names
    assert 0x40 in runtime_for_names["code"], runtime_for_names
    assert 0x51 in runtime_for_names["code"], runtime_for_names
    assert 0x03 in runtime_for_names["code"], runtime_for_names
    assert 0x04 in runtime_for_names["code"], runtime_for_names
    assert 0x31 in runtime_for_names["code"], runtime_for_names
    assert 0x30 in runtime_for_names["code"], runtime_for_names
    for value in ["get:iterator", "moveNext", "get:current", "add"]:
        assert any(
            constant.get("type") == "String" and constant.get("value") == value
            for constant in runtime_for_names["constants"]
        ), runtime_for_names
    async_runtime_for_names = next(item for item in module["functions"] if item["name"].endswith("::asyncRuntimeForNames"))
    assert async_runtime_for_names["async_kind"] == "async_future", async_runtime_for_names
    assert async_runtime_for_names["param_count"] == 1, async_runtime_for_names
    assert 0x40 in async_runtime_for_names["code"], async_runtime_for_names
    assert 0x51 in async_runtime_for_names["code"], async_runtime_for_names
    assert 0x03 in async_runtime_for_names["code"], async_runtime_for_names
    assert 0x04 in async_runtime_for_names["code"], async_runtime_for_names
    assert 0x31 in async_runtime_for_names["code"], async_runtime_for_names
    assert 0x30 in async_runtime_for_names["code"], async_runtime_for_names
    assert 0x63 in async_runtime_for_names["code"], async_runtime_for_names
    assert any(
        constant.get("type") == "String" and constant.get("value") == "patched-async-for"
        for constant in async_runtime_for_names["constants"]
    ), async_runtime_for_names
    for value in ["get:iterator", "moveNext", "get:current", "add"]:
        assert any(
            constant.get("type") == "String" and constant.get("value") == value
            for constant in async_runtime_for_names["constants"]
        ), async_runtime_for_names
    async_await_runtime_for_names = next(
        item for item in module["functions"] if item["name"].endswith("::asyncAwaitThenRuntimeForNames")
    )
    assert async_await_runtime_for_names["async_kind"] == "async_future", async_await_runtime_for_names
    assert async_await_runtime_for_names["param_count"] == 2, async_await_runtime_for_names
    assert 0x62 in async_await_runtime_for_names["code"], async_await_runtime_for_names
    assert 0x03 in async_await_runtime_for_names["code"], async_await_runtime_for_names
    assert 0x40 in async_await_runtime_for_names["code"], async_await_runtime_for_names
    assert 0x51 in async_await_runtime_for_names["code"], async_await_runtime_for_names
    assert 0x04 in async_await_runtime_for_names["code"], async_await_runtime_for_names
    assert 0x31 in async_await_runtime_for_names["code"], async_await_runtime_for_names
    assert 0x30 in async_await_runtime_for_names["code"], async_await_runtime_for_names
    assert 0x55 in async_await_runtime_for_names["code"], async_await_runtime_for_names
    assert 0x63 in async_await_runtime_for_names["code"], async_await_runtime_for_names
    assert any(
        constant.get("type") == "String" and constant.get("value") == "patched-await-runtime-for"
        for constant in async_await_runtime_for_names["constants"]
    ), async_await_runtime_for_names
    for value in ["get:iterator", "moveNext", "get:current", "add"]:
        assert any(
            constant.get("type") == "String" and constant.get("value") == value
            for constant in async_await_runtime_for_names["constants"]
        ), async_await_runtime_for_names
    assert_collection_dynamic_label_calls(module)
