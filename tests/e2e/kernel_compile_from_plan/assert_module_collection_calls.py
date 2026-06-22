from assert_module_collection_label_calls import assert_collection_label_calls

def assert_collection_calls(module):
    names = next(item for item in module["functions"] if item["name"].endswith("::names"))
    assert names["param_count"] == 2, names
    assert 0x40 in names["code"], names
    assert 0x31 in names["code"], names
    assert 0x30 in names["code"], names
    assert names["code"].count(0x31) >= 2, names
    assert any(
        constant.get("type") == "String" and constant.get("value") == "patched"
        for constant in names["constants"]
    ), names
    assert any(
        constant.get("type") == "String" and constant.get("value") == "tail"
        for constant in names["constants"]
    ), names
    assert any(
        constant.get("type") == "String" and constant.get("value") == "spread-a"
        for constant in names["constants"]
    ), names
    assert any(
        constant.get("type") == "String" and constant.get("value") == "spread-b"
        for constant in names["constants"]
    ), names
    assert any(
        constant.get("type") == "String" and constant.get("value") == "for-a"
        for constant in names["constants"]
    ), names
    assert any(
        constant.get("type") == "String" and constant.get("value") == "for-b"
        for constant in names["constants"]
    ), names
    assert any(
        constant.get("type") == "String" and constant.get("value") == "off"
        for constant in names["constants"]
    ), names
    assert any(
        constant.get("type") == "String" and constant.get("value") == "pro"
        for constant in names["constants"]
    ), names
    async_names = next(item for item in module["functions"] if item["name"].endswith("::asyncNames"))
    assert async_names["async_kind"] == "async_future", async_names
    assert async_names["param_count"] == 2, async_names
    assert 0x40 in async_names["code"], async_names
    assert 0x31 in async_names["code"], async_names
    assert 0x30 in async_names["code"], async_names
    assert 0x63 in async_names["code"], async_names
    assert async_names["code"].count(0x31) >= 2, async_names
    for value in [
        "patched-async-static",
        "async-spread-a",
        "async-spread-b",
        "async-for-a",
        "async-for-b",
        "async-off",
        "async-pro",
    ]:
        assert any(
            constant.get("type") == "String" and constant.get("value") == value
            for constant in async_names["constants"]
        ), async_names
    async_await_names = next(item for item in module["functions"] if item["name"].endswith("::asyncAwaitThenNames"))
    assert async_await_names["async_kind"] == "async_future", async_await_names
    assert async_await_names["param_count"] == 1, async_await_names
    assert 0x62 in async_await_names["code"], async_await_names
    assert 0x03 in async_await_names["code"], async_await_names
    assert 0x40 in async_await_names["code"], async_await_names
    assert 0x55 in async_await_names["code"], async_await_names
    assert 0x63 in async_await_names["code"], async_await_names
    for value in ["patched-await-list", "patched-await-tail"]:
        assert any(
            constant.get("type") == "String" and constant.get("value") == value
            for constant in async_await_names["constants"]
        ), async_await_names
    async_await_conditional_names = next(
        item for item in module["functions"] if item["name"].endswith("::asyncAwaitThenConditionalNames")
    )
    assert async_await_conditional_names["async_kind"] == "async_future", async_await_conditional_names
    assert async_await_conditional_names["param_count"] == 1, async_await_conditional_names
    assert 0x62 in async_await_conditional_names["code"], async_await_conditional_names
    assert 0x03 in async_await_conditional_names["code"], async_await_conditional_names
    assert 0x31 in async_await_conditional_names["code"], async_await_conditional_names
    assert 0x30 in async_await_conditional_names["code"], async_await_conditional_names
    assert 0x40 in async_await_conditional_names["code"], async_await_conditional_names
    assert 0x55 in async_await_conditional_names["code"], async_await_conditional_names
    assert 0x63 in async_await_conditional_names["code"], async_await_conditional_names
    for value in [
        "patched-await-if-head",
        "patched-await-if-live",
        "patched-await-if-off",
        "patched-await-if-tail",
    ]:
        assert any(
            constant.get("type") == "String" and constant.get("value") == value
            for constant in async_await_conditional_names["constants"]
        ), async_await_conditional_names
    async_await_conditional_dynamic_names = next(
        item for item in module["functions"] if item["name"].endswith("::asyncAwaitThenConditionalDynamicNames")
    )
    assert async_await_conditional_dynamic_names["async_kind"] == "async_future", async_await_conditional_dynamic_names
    assert async_await_conditional_dynamic_names["param_count"] == 2, async_await_conditional_dynamic_names
    assert 0x62 in async_await_conditional_dynamic_names["code"], async_await_conditional_dynamic_names
    assert 0x03 in async_await_conditional_dynamic_names["code"], async_await_conditional_dynamic_names
    assert 0x31 in async_await_conditional_dynamic_names["code"], async_await_conditional_dynamic_names
    assert 0x30 in async_await_conditional_dynamic_names["code"], async_await_conditional_dynamic_names
    assert 0x40 in async_await_conditional_dynamic_names["code"], async_await_conditional_dynamic_names
    assert 0x51 in async_await_conditional_dynamic_names["code"], async_await_conditional_dynamic_names
    assert 0x55 in async_await_conditional_dynamic_names["code"], async_await_conditional_dynamic_names
    assert 0x63 in async_await_conditional_dynamic_names["code"], async_await_conditional_dynamic_names
    for value in [
        "patched-await-if-dynamic-head",
        "patched-await-if-dynamic-live",
        "patched-await-if-dynamic-off",
        "addAll",
    ]:
        assert any(
            constant.get("type") == "String" and constant.get("value") == value
            for constant in async_await_conditional_dynamic_names["constants"]
        ), async_await_conditional_dynamic_names
    async_await_conditional_dynamic_tail_names = next(
        item
        for item in module["functions"]
        if item["name"].endswith("::asyncAwaitThenConditionalDynamicTailNames")
    )
    assert async_await_conditional_dynamic_tail_names["async_kind"] == "async_future", (
        async_await_conditional_dynamic_tail_names
    )
    assert async_await_conditional_dynamic_tail_names["param_count"] == 2, (
        async_await_conditional_dynamic_tail_names
    )
    for opcode in [0x62, 0x03, 0x31, 0x30, 0x40, 0x51, 0x04, 0x55, 0x63]:
        assert opcode in async_await_conditional_dynamic_tail_names["code"], (
            async_await_conditional_dynamic_tail_names
        )
    for value in [
        "patched-await-if-dynamic-tail-head",
        "patched-await-if-dynamic-tail-live",
        "patched-await-if-dynamic-tail-off",
        "patched-await-if-dynamic-tail-tail",
        "addAll",
    ]:
        assert any(
            constant.get("type") == "String" and constant.get("value") == value
            for constant in async_await_conditional_dynamic_tail_names["constants"]
        ), async_await_conditional_dynamic_tail_names
    async_await_conditional_dynamic_spread_names = next(
        item
        for item in module["functions"]
        if item["name"].endswith("::asyncAwaitThenConditionalDynamicStaticSpreadNames")
    )
    assert async_await_conditional_dynamic_spread_names["async_kind"] == "async_future", (
        async_await_conditional_dynamic_spread_names
    )
    assert async_await_conditional_dynamic_spread_names["param_count"] == 2, (
        async_await_conditional_dynamic_spread_names
    )
    for opcode in [0x62, 0x03, 0x31, 0x30, 0x40, 0x51, 0x04, 0x55, 0x63]:
        assert opcode in async_await_conditional_dynamic_spread_names["code"], (
            async_await_conditional_dynamic_spread_names
        )
    for value in [
        "patched-await-if-dynamic-static-spread-head",
        "patched-await-if-dynamic-static-spread-live",
        "patched-await-if-dynamic-static-spread-off",
        "patched-await-if-dynamic-static-spread-tail-a",
        "patched-await-if-dynamic-static-spread-tail-b",
        "addAll",
    ]:
        assert any(
            constant.get("type") == "String" and constant.get("value") == value
            for constant in async_await_conditional_dynamic_spread_names["constants"]
        ), async_await_conditional_dynamic_spread_names
    async_await_conditional_chain_names = next(
        item
        for item in module["functions"]
        if item["name"].endswith("::asyncAwaitThenConditionalDynamicRuntimeNames")
    )
    assert async_await_conditional_chain_names["async_kind"] == "async_future", async_await_conditional_chain_names
    assert async_await_conditional_chain_names["param_count"] == 3, async_await_conditional_chain_names
    for opcode in [0x62, 0x03, 0x31, 0x30, 0x40, 0x51, 0x04, 0x55, 0x63]:
        assert opcode in async_await_conditional_chain_names["code"], async_await_conditional_chain_names
    for value in [
        "patched-await-if-dynamic-runtime-head",
        "patched-await-if-dynamic-runtime-live",
        "patched-await-if-dynamic-runtime-off",
        "addAll",
        "get:iterator",
        "moveNext",
        "get:current",
        "add",
    ]:
        assert any(
            constant.get("type") == "String" and constant.get("value") == value
            for constant in async_await_conditional_chain_names["constants"]
        ), async_await_conditional_chain_names
    async_await_conditional_chain_tail_names = next(
        item
        for item in module["functions"]
        if item["name"].endswith("::asyncAwaitThenConditionalDynamicRuntimeTailNames")
    )
    assert async_await_conditional_chain_tail_names["async_kind"] == "async_future", (
        async_await_conditional_chain_tail_names
    )
    assert async_await_conditional_chain_tail_names["param_count"] == 3, (
        async_await_conditional_chain_tail_names
    )
    for opcode in [0x62, 0x03, 0x31, 0x30, 0x40, 0x51, 0x04, 0x55, 0x63]:
        assert opcode in async_await_conditional_chain_tail_names["code"], (
            async_await_conditional_chain_tail_names
        )
    for value in [
        "patched-await-if-dynamic-runtime-tail-head",
        "patched-await-if-dynamic-runtime-tail-live",
        "patched-await-if-dynamic-runtime-tail-off",
        "patched-await-if-dynamic-runtime-tail-tail",
        "addAll",
        "get:iterator",
        "moveNext",
        "get:current",
        "add",
    ]:
        assert any(
            constant.get("type") == "String" and constant.get("value") == value
            for constant in async_await_conditional_chain_tail_names["constants"]
        ), async_await_conditional_chain_tail_names
    async_await_conditional_chain_spread_names = next(
        item
        for item in module["functions"]
        if item["name"].endswith("::asyncAwaitThenConditionalDynamicRuntimeStaticSpreadNames")
    )
    assert async_await_conditional_chain_spread_names["async_kind"] == "async_future", (
        async_await_conditional_chain_spread_names
    )
    assert async_await_conditional_chain_spread_names["param_count"] == 3, (
        async_await_conditional_chain_spread_names
    )
    for opcode in [0x62, 0x03, 0x31, 0x30, 0x40, 0x51, 0x04, 0x55, 0x63]:
        assert opcode in async_await_conditional_chain_spread_names["code"], (
            async_await_conditional_chain_spread_names
        )
    for value in [
        "patched-await-if-dynamic-runtime-static-spread-head",
        "patched-await-if-dynamic-runtime-static-spread-live",
        "patched-await-if-dynamic-runtime-static-spread-off",
        "patched-await-if-dynamic-runtime-static-spread-tail-a",
        "patched-await-if-dynamic-runtime-static-spread-tail-b",
        "addAll",
        "get:iterator",
        "moveNext",
        "get:current",
        "add",
    ]:
        assert any(
            constant.get("type") == "String" and constant.get("value") == value
            for constant in async_await_conditional_chain_spread_names["constants"]
        ), async_await_conditional_chain_spread_names
    async_await_conditional_runtime_names = next(
        item for item in module["functions"] if item["name"].endswith("::asyncAwaitThenConditionalRuntimeNames")
    )
    assert async_await_conditional_runtime_names["async_kind"] == "async_future", async_await_conditional_runtime_names
    assert async_await_conditional_runtime_names["param_count"] == 2, async_await_conditional_runtime_names
    for opcode in [0x62, 0x03, 0x31, 0x30, 0x40, 0x51, 0x04, 0x55, 0x63]:
        assert opcode in async_await_conditional_runtime_names["code"], async_await_conditional_runtime_names
    for value in [
        "patched-await-if-runtime-head",
        "patched-await-if-runtime-live",
        "patched-await-if-runtime-off",
        "get:iterator",
        "moveNext",
        "get:current",
        "add",
    ]:
        assert any(
            constant.get("type") == "String" and constant.get("value") == value
            for constant in async_await_conditional_runtime_names["constants"]
        ), async_await_conditional_runtime_names
    async_await_conditional_runtime_tail_names = next(
        item
        for item in module["functions"]
        if item["name"].endswith("::asyncAwaitThenConditionalRuntimeTailNames")
    )
    assert async_await_conditional_runtime_tail_names["async_kind"] == "async_future", (
        async_await_conditional_runtime_tail_names
    )
    assert async_await_conditional_runtime_tail_names["param_count"] == 2, (
        async_await_conditional_runtime_tail_names
    )
    for opcode in [0x62, 0x03, 0x31, 0x30, 0x40, 0x51, 0x04, 0x55, 0x63]:
        assert opcode in async_await_conditional_runtime_tail_names["code"], (
            async_await_conditional_runtime_tail_names
        )
    for value in [
        "patched-await-if-runtime-tail-head",
        "patched-await-if-runtime-tail-live",
        "patched-await-if-runtime-tail-off",
        "patched-await-if-runtime-tail-tail",
        "get:iterator",
        "moveNext",
        "get:current",
        "add",
        "addAll",
    ]:
        assert any(
            constant.get("type") == "String" and constant.get("value") == value
            for constant in async_await_conditional_runtime_tail_names["constants"]
        ), async_await_conditional_runtime_tail_names
    async_await_conditional_runtime_spread_names = next(
        item
        for item in module["functions"]
        if item["name"].endswith("::asyncAwaitThenConditionalRuntimeStaticSpreadNames")
    )
    assert async_await_conditional_runtime_spread_names["async_kind"] == "async_future", (
        async_await_conditional_runtime_spread_names
    )
    assert async_await_conditional_runtime_spread_names["param_count"] == 2, (
        async_await_conditional_runtime_spread_names
    )
    for opcode in [0x62, 0x03, 0x31, 0x30, 0x40, 0x51, 0x04, 0x55, 0x63]:
        assert opcode in async_await_conditional_runtime_spread_names["code"], (
            async_await_conditional_runtime_spread_names
        )
    for value in [
        "patched-await-if-runtime-static-spread-head",
        "patched-await-if-runtime-static-spread-live",
        "patched-await-if-runtime-static-spread-off",
        "patched-await-if-runtime-static-spread-tail-a",
        "patched-await-if-runtime-static-spread-tail-b",
        "get:iterator",
        "moveNext",
        "get:current",
        "add",
        "addAll",
    ]:
        assert any(
            constant.get("type") == "String" and constant.get("value") == value
            for constant in async_await_conditional_runtime_spread_names["constants"]
        ), async_await_conditional_runtime_spread_names
    async_await_conditional_reverse_names = next(
        item
        for item in module["functions"]
        if item["name"].endswith("::asyncAwaitThenConditionalRuntimeDynamicNames")
    )
    assert async_await_conditional_reverse_names["async_kind"] == "async_future", async_await_conditional_reverse_names
    assert async_await_conditional_reverse_names["param_count"] == 3, async_await_conditional_reverse_names
    for opcode in [0x62, 0x03, 0x31, 0x30, 0x40, 0x51, 0x04, 0x55, 0x63]:
        assert opcode in async_await_conditional_reverse_names["code"], async_await_conditional_reverse_names
    for value in [
        "patched-await-if-runtime-dynamic-head",
        "patched-await-if-runtime-dynamic-live",
        "patched-await-if-runtime-dynamic-off",
        "get:iterator",
        "moveNext",
        "get:current",
        "add",
        "addAll",
    ]:
        assert any(
            constant.get("type") == "String" and constant.get("value") == value
            for constant in async_await_conditional_reverse_names["constants"]
        ), async_await_conditional_reverse_names
    async_await_conditional_reverse_tail_names = next(
        item
        for item in module["functions"]
        if item["name"].endswith("::asyncAwaitThenConditionalRuntimeDynamicTailNames")
    )
    assert async_await_conditional_reverse_tail_names["async_kind"] == "async_future", (
        async_await_conditional_reverse_tail_names
    )
    assert async_await_conditional_reverse_tail_names["param_count"] == 3, (
        async_await_conditional_reverse_tail_names
    )
    for opcode in [0x62, 0x03, 0x31, 0x30, 0x40, 0x51, 0x04, 0x55, 0x63]:
        assert opcode in async_await_conditional_reverse_tail_names["code"], (
            async_await_conditional_reverse_tail_names
        )
    for value in [
        "patched-await-if-runtime-dynamic-tail-head",
        "patched-await-if-runtime-dynamic-tail-live",
        "patched-await-if-runtime-dynamic-tail-off",
        "patched-await-if-runtime-dynamic-tail-tail",
        "get:iterator",
        "moveNext",
        "get:current",
        "add",
        "addAll",
    ]:
        assert any(
            constant.get("type") == "String" and constant.get("value") == value
            for constant in async_await_conditional_reverse_tail_names["constants"]
        ), async_await_conditional_reverse_tail_names
    async_await_conditional_reverse_spread_names = next(
        item
        for item in module["functions"]
        if item["name"].endswith("::asyncAwaitThenConditionalRuntimeDynamicStaticSpreadNames")
    )
    assert async_await_conditional_reverse_spread_names["async_kind"] == "async_future", (
        async_await_conditional_reverse_spread_names
    )
    assert async_await_conditional_reverse_spread_names["param_count"] == 3, (
        async_await_conditional_reverse_spread_names
    )
    for opcode in [0x62, 0x03, 0x31, 0x30, 0x40, 0x51, 0x04, 0x55, 0x63]:
        assert opcode in async_await_conditional_reverse_spread_names["code"], (
            async_await_conditional_reverse_spread_names
        )
    for value in [
        "patched-await-if-runtime-dynamic-static-spread-head",
        "patched-await-if-runtime-dynamic-static-spread-live",
        "patched-await-if-runtime-dynamic-static-spread-off",
        "patched-await-if-runtime-dynamic-static-spread-tail-a",
        "patched-await-if-runtime-dynamic-static-spread-tail-b",
        "get:iterator",
        "moveNext",
        "get:current",
        "add",
        "addAll",
    ]:
        assert any(
            constant.get("type") == "String" and constant.get("value") == value
            for constant in async_await_conditional_reverse_spread_names["constants"]
        ), async_await_conditional_reverse_spread_names
    async_await_condition_names = next(
        item for item in module["functions"] if item["name"].endswith("::asyncAwaitConditionNames")
    )
    assert async_await_condition_names["async_kind"] == "async_future", async_await_condition_names
    assert async_await_condition_names["param_count"] == 1, async_await_condition_names
    for opcode in [0x62, 0x31, 0x30, 0x40, 0x55, 0x63]:
        assert opcode in async_await_condition_names["code"], async_await_condition_names
    for value in [
        "patched-await-condition-head",
        "patched-await-condition-live",
        "patched-await-condition-off",
        "patched-await-condition-tail",
    ]:
        assert any(
            constant.get("type") == "String" and constant.get("value") == value
            for constant in async_await_condition_names["constants"]
        ), async_await_condition_names
    async_await_condition_dynamic_names = next(
        item for item in module["functions"] if item["name"].endswith("::asyncAwaitConditionDynamicNames")
    )
    assert async_await_condition_dynamic_names["async_kind"] == "async_future", async_await_condition_dynamic_names
    assert async_await_condition_dynamic_names["param_count"] == 2, async_await_condition_dynamic_names
    for opcode in [0x62, 0x31, 0x30, 0x40, 0x51, 0x55, 0x63]:
        assert opcode in async_await_condition_dynamic_names["code"], async_await_condition_dynamic_names
    for value in [
        "patched-await-condition-dynamic-head",
        "patched-await-condition-dynamic-live",
        "patched-await-condition-dynamic-off",
        "addAll",
    ]:
        assert any(
            constant.get("type") == "String" and constant.get("value") == value
            for constant in async_await_condition_dynamic_names["constants"]
        ), async_await_condition_dynamic_names
    async_await_condition_runtime_names = next(
        item for item in module["functions"] if item["name"].endswith("::asyncAwaitConditionRuntimeNames")
    )
    assert async_await_condition_runtime_names["async_kind"] == "async_future", async_await_condition_runtime_names
    assert async_await_condition_runtime_names["param_count"] == 2, async_await_condition_runtime_names
    for opcode in [0x62, 0x31, 0x30, 0x40, 0x51, 0x04, 0x55, 0x63]:
        assert opcode in async_await_condition_runtime_names["code"], async_await_condition_runtime_names
    for value in [
        "patched-await-condition-runtime-head",
        "patched-await-condition-runtime-live",
        "patched-await-condition-runtime-off",
        "get:iterator",
        "moveNext",
        "get:current",
        "add",
    ]:
        assert any(
            constant.get("type") == "String" and constant.get("value") == value
            for constant in async_await_condition_runtime_names["constants"]
        ), async_await_condition_runtime_names
    async_await_condition_chain_names = next(
        item for item in module["functions"] if item["name"].endswith("::asyncAwaitConditionDynamicRuntimeNames")
    )
    assert async_await_condition_chain_names["async_kind"] == "async_future", async_await_condition_chain_names
    assert async_await_condition_chain_names["param_count"] == 3, async_await_condition_chain_names
    for opcode in [0x62, 0x31, 0x30, 0x40, 0x51, 0x04, 0x55, 0x63]:
        assert opcode in async_await_condition_chain_names["code"], async_await_condition_chain_names
    for value in [
        "patched-await-condition-chain-head",
        "patched-await-condition-chain-live",
        "patched-await-condition-chain-off",
        "addAll",
        "get:iterator",
        "moveNext",
        "get:current",
        "add",
    ]:
        assert any(
            constant.get("type") == "String" and constant.get("value") == value
            for constant in async_await_condition_chain_names["constants"]
        ), async_await_condition_chain_names
    async_await_condition_chain_spread_names = next(
        item
        for item in module["functions"]
        if item["name"].endswith("::asyncAwaitConditionDynamicRuntimeStaticSpreadNames")
    )
    assert async_await_condition_chain_spread_names["async_kind"] == "async_future", (
        async_await_condition_chain_spread_names
    )
    assert async_await_condition_chain_spread_names["param_count"] == 3, (
        async_await_condition_chain_spread_names
    )
    for opcode in [0x62, 0x31, 0x30, 0x40, 0x51, 0x04, 0x55, 0x63]:
        assert opcode in async_await_condition_chain_spread_names["code"], (
            async_await_condition_chain_spread_names
        )
    for value in [
        "patched-await-condition-chain-static-spread-head",
        "patched-await-condition-chain-static-spread-live",
        "patched-await-condition-chain-static-spread-off",
        "patched-await-condition-chain-static-spread-tail-a",
        "patched-await-condition-chain-static-spread-tail-b",
        "addAll",
        "get:iterator",
        "moveNext",
        "get:current",
        "add",
    ]:
        assert any(
            constant.get("type") == "String" and constant.get("value") == value
            for constant in async_await_condition_chain_spread_names["constants"]
        ), async_await_condition_chain_spread_names
    async_await_condition_chain_tail_names = next(
        item
        for item in module["functions"]
        if item["name"].endswith("::asyncAwaitConditionDynamicRuntimeTailNames")
    )
    assert async_await_condition_chain_tail_names["async_kind"] == "async_future", (
        async_await_condition_chain_tail_names
    )
    assert async_await_condition_chain_tail_names["param_count"] == 3, (
        async_await_condition_chain_tail_names
    )
    for opcode in [0x62, 0x31, 0x30, 0x40, 0x51, 0x04, 0x55, 0x63]:
        assert opcode in async_await_condition_chain_tail_names["code"], async_await_condition_chain_tail_names
    for value in [
        "patched-await-condition-chain-tail-head",
        "patched-await-condition-chain-tail-live",
        "patched-await-condition-chain-tail-off",
        "patched-await-condition-chain-tail-tail",
        "addAll",
        "get:iterator",
        "moveNext",
        "get:current",
        "add",
    ]:
        assert any(
            constant.get("type") == "String" and constant.get("value") == value
            for constant in async_await_condition_chain_tail_names["constants"]
        ), async_await_condition_chain_tail_names
    async_await_condition_reverse_chain_names = next(
        item for item in module["functions"] if item["name"].endswith("::asyncAwaitConditionRuntimeDynamicNames")
    )
    assert async_await_condition_reverse_chain_names["async_kind"] == "async_future", (
        async_await_condition_reverse_chain_names
    )
    assert async_await_condition_reverse_chain_names["param_count"] == 3, async_await_condition_reverse_chain_names
    for opcode in [0x62, 0x31, 0x30, 0x40, 0x51, 0x04, 0x55, 0x63]:
        assert opcode in async_await_condition_reverse_chain_names["code"], async_await_condition_reverse_chain_names
    for value in [
        "patched-await-condition-reverse-chain-head",
        "patched-await-condition-reverse-chain-live",
        "patched-await-condition-reverse-chain-off",
        "addAll",
        "get:iterator",
        "moveNext",
        "get:current",
        "add",
    ]:
        assert any(
            constant.get("type") == "String" and constant.get("value") == value
            for constant in async_await_condition_reverse_chain_names["constants"]
        ), async_await_condition_reverse_chain_names
    async_await_condition_reverse_chain_spread_names = next(
        item
        for item in module["functions"]
        if item["name"].endswith("::asyncAwaitConditionRuntimeDynamicStaticSpreadNames")
    )
    assert async_await_condition_reverse_chain_spread_names["async_kind"] == "async_future", (
        async_await_condition_reverse_chain_spread_names
    )
    assert async_await_condition_reverse_chain_spread_names["param_count"] == 3, (
        async_await_condition_reverse_chain_spread_names
    )
    for opcode in [0x62, 0x31, 0x30, 0x40, 0x51, 0x04, 0x55, 0x63]:
        assert opcode in async_await_condition_reverse_chain_spread_names["code"], (
            async_await_condition_reverse_chain_spread_names
        )
    for value in [
        "patched-await-condition-reverse-chain-static-spread-head",
        "patched-await-condition-reverse-chain-static-spread-live",
        "patched-await-condition-reverse-chain-static-spread-off",
        "patched-await-condition-reverse-chain-static-spread-tail-a",
        "patched-await-condition-reverse-chain-static-spread-tail-b",
        "addAll",
        "get:iterator",
        "moveNext",
        "get:current",
        "add",
    ]:
        assert any(
            constant.get("type") == "String" and constant.get("value") == value
            for constant in async_await_condition_reverse_chain_spread_names["constants"]
        ), async_await_condition_reverse_chain_spread_names
    async_await_condition_reverse_chain_tail_names = next(
        item
        for item in module["functions"]
        if item["name"].endswith("::asyncAwaitConditionRuntimeDynamicTailNames")
    )
    assert async_await_condition_reverse_chain_tail_names["async_kind"] == "async_future", (
        async_await_condition_reverse_chain_tail_names
    )
    assert async_await_condition_reverse_chain_tail_names["param_count"] == 3, (
        async_await_condition_reverse_chain_tail_names
    )
    for opcode in [0x62, 0x31, 0x30, 0x40, 0x51, 0x04, 0x55, 0x63]:
        assert opcode in async_await_condition_reverse_chain_tail_names["code"], (
            async_await_condition_reverse_chain_tail_names
        )
    for value in [
        "patched-await-condition-reverse-chain-tail-head",
        "patched-await-condition-reverse-chain-tail-live",
        "patched-await-condition-reverse-chain-tail-off",
        "patched-await-condition-reverse-chain-tail-tail",
        "addAll",
        "get:iterator",
        "moveNext",
        "get:current",
        "add",
    ]:
        assert any(
            constant.get("type") == "String" and constant.get("value") == value
            for constant in async_await_condition_reverse_chain_tail_names["constants"]
        ), async_await_condition_reverse_chain_tail_names
    async_await_condition_tail_names = next(
        item for item in module["functions"] if item["name"].endswith("::asyncAwaitConditionDynamicTailNames")
    )
    assert async_await_condition_tail_names["async_kind"] == "async_future", async_await_condition_tail_names
    assert async_await_condition_tail_names["param_count"] == 2, async_await_condition_tail_names
    for opcode in [0x62, 0x31, 0x30, 0x40, 0x51, 0x04, 0x55, 0x63]:
        assert opcode in async_await_condition_tail_names["code"], async_await_condition_tail_names
    for value in [
        "patched-await-condition-tail-chain-head",
        "patched-await-condition-tail-chain-live",
        "patched-await-condition-tail-chain-off",
        "patched-await-condition-tail-chain-tail",
        "addAll",
    ]:
        assert any(
            constant.get("type") == "String" and constant.get("value") == value
            for constant in async_await_condition_tail_names["constants"]
        ), async_await_condition_tail_names
    async_await_condition_runtime_tail_names = next(
        item for item in module["functions"] if item["name"].endswith("::asyncAwaitConditionRuntimeTailNames")
    )
    assert async_await_condition_runtime_tail_names["async_kind"] == "async_future", (
        async_await_condition_runtime_tail_names
    )
    assert async_await_condition_runtime_tail_names["param_count"] == 2, async_await_condition_runtime_tail_names
    for opcode in [0x62, 0x31, 0x30, 0x40, 0x51, 0x04, 0x55, 0x63]:
        assert opcode in async_await_condition_runtime_tail_names["code"], async_await_condition_runtime_tail_names
    for value in [
        "patched-await-condition-runtime-tail-head",
        "patched-await-condition-runtime-tail-live",
        "patched-await-condition-runtime-tail-off",
        "patched-await-condition-runtime-tail-tail",
        "addAll",
        "get:iterator",
        "moveNext",
        "get:current",
        "add",
    ]:
        assert any(
            constant.get("type") == "String" and constant.get("value") == value
            for constant in async_await_condition_runtime_tail_names["constants"]
        ), async_await_condition_runtime_tail_names
    async_await_condition_static_spread_names = next(
        item
        for item in module["functions"]
        if item["name"].endswith("::asyncAwaitConditionDynamicStaticSpreadNames")
    )
    assert async_await_condition_static_spread_names["async_kind"] == "async_future", (
        async_await_condition_static_spread_names
    )
    assert async_await_condition_static_spread_names["param_count"] == 2, (
        async_await_condition_static_spread_names
    )
    for opcode in [0x62, 0x31, 0x30, 0x40, 0x51, 0x04, 0x55, 0x63]:
        assert opcode in async_await_condition_static_spread_names["code"], async_await_condition_static_spread_names
    for value in [
        "patched-await-condition-static-spread-head",
        "patched-await-condition-static-spread-live",
        "patched-await-condition-static-spread-off",
        "patched-await-condition-static-spread-tail-a",
        "patched-await-condition-static-spread-tail-b",
        "addAll",
    ]:
        assert any(
            constant.get("type") == "String" and constant.get("value") == value
            for constant in async_await_condition_static_spread_names["constants"]
        ), async_await_condition_static_spread_names
    async_await_condition_runtime_static_spread_names = next(
        item
        for item in module["functions"]
        if item["name"].endswith("::asyncAwaitConditionRuntimeStaticSpreadNames")
    )
    assert async_await_condition_runtime_static_spread_names["async_kind"] == "async_future", (
        async_await_condition_runtime_static_spread_names
    )
    assert async_await_condition_runtime_static_spread_names["param_count"] == 2, (
        async_await_condition_runtime_static_spread_names
    )
    for opcode in [0x62, 0x31, 0x30, 0x40, 0x51, 0x04, 0x55, 0x63]:
        assert opcode in async_await_condition_runtime_static_spread_names["code"], (
            async_await_condition_runtime_static_spread_names
        )
    for value in [
        "patched-await-condition-runtime-static-spread-head",
        "patched-await-condition-runtime-static-spread-live",
        "patched-await-condition-runtime-static-spread-off",
        "patched-await-condition-runtime-static-spread-tail-a",
        "patched-await-condition-runtime-static-spread-tail-b",
        "addAll",
        "get:iterator",
        "moveNext",
        "get:current",
        "add",
    ]:
        assert any(
            constant.get("type") == "String" and constant.get("value") == value
            for constant in async_await_condition_runtime_static_spread_names["constants"]
        ), async_await_condition_runtime_static_spread_names
    assert_collection_label_calls(module)
