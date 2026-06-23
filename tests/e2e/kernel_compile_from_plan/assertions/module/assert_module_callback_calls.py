def assert_callback_calls(module):
    captured_greeting = next(item for item in module["functions"] if item["name"].endswith("::capturedGreeting"))
    assert captured_greeting["param_count"] == 1, captured_greeting
    assert 0x42 in captured_greeting["code"], captured_greeting
    assert 0x03 in captured_greeting["code"], captured_greeting
    assert 0x04 in captured_greeting["code"], captured_greeting
    assert any(
        constant.get("type") == "String" and constant.get("value") == "patched"
        for constant in captured_greeting["constants"]
    ), captured_greeting

    stored_closure_greeting = next(
        item for item in module["functions"] if item["name"].endswith("::storedClosureGreeting")
    )
    assert stored_closure_greeting["param_count"] == 1, stored_closure_greeting
    assert 0x42 in stored_closure_greeting["code"], stored_closure_greeting
    assert 0x03 in stored_closure_greeting["code"], stored_closure_greeting
    assert 0x04 in stored_closure_greeting["code"], stored_closure_greeting
    assert any(
        constant.get("type") == "String" and constant.get("value") == "patched"
        for constant in stored_closure_greeting["constants"]
    ), stored_closure_greeting

    passed_escaping_greeting = next(
        item for item in module["functions"] if item["name"].endswith("::passedEscapingGreeting")
    )
    assert passed_escaping_greeting["param_count"] == 1, passed_escaping_greeting
    assert 0x42 in passed_escaping_greeting["code"], passed_escaping_greeting
    assert 0x03 in passed_escaping_greeting["code"], passed_escaping_greeting
    assert 0x04 in passed_escaping_greeting["code"], passed_escaping_greeting
    assert any(
        constant.get("type") == "String" and constant.get("value") == "patched"
        for constant in passed_escaping_greeting["constants"]
    ), passed_escaping_greeting

    direct_callback = next(item for item in module["functions"] if item["name"].endswith("::directCallbackValue"))
    assert direct_callback["param_count"] == 1, direct_callback
    assert direct_callback["async_kind"] == "sync", direct_callback
    assert 0x53 in direct_callback["code"], direct_callback
    assert 0x42 in direct_callback["code"], direct_callback
    assert any(
        constant.get("type") == "String" and constant.get("value") == " patched-direct"
        for constant in direct_callback["constants"]
    ), direct_callback

    direct_callback_arg = next(item for item in module["functions"] if item["name"].endswith("::directCallbackArg"))
    assert direct_callback_arg["param_count"] == 2, direct_callback_arg
    assert direct_callback_arg["async_kind"] == "sync", direct_callback_arg
    assert direct_callback_arg["code"].count(0x02) >= 2, direct_callback_arg
    assert 0x53 in direct_callback_arg["code"], direct_callback_arg
    assert 0x42 in direct_callback_arg["code"], direct_callback_arg
    assert any(
        constant.get("type") == "String" and constant.get("value") == " patched-arg"
        for constant in direct_callback_arg["constants"]
    ), direct_callback_arg

    direct_callback_named = next(
        item for item in module["functions"] if item["name"].endswith("::directCallbackNamed")
    )
    assert direct_callback_named["param_count"] == 2, direct_callback_named
    assert direct_callback_named["async_kind"] == "sync", direct_callback_named
    assert direct_callback_named["code"].count(0x02) >= 2, direct_callback_named
    assert 0x53 in direct_callback_named["code"], direct_callback_named
    assert 0x42 in direct_callback_named["code"], direct_callback_named
    assert any(
        constant.get("type") == "String" and constant.get("value") == ";named:value"
        for constant in direct_callback_named["constants"]
    ), direct_callback_named
    assert any(
        constant.get("type") == "String" and constant.get("value") == " patched-named"
        for constant in direct_callback_named["constants"]
    ), direct_callback_named

    direct_callback_mixed = next(
        item for item in module["functions"] if item["name"].endswith("::directCallbackMixed")
    )
    assert direct_callback_mixed["param_count"] == 3, direct_callback_mixed
    assert direct_callback_mixed["async_kind"] == "sync", direct_callback_mixed
    assert direct_callback_mixed["code"].count(0x02) >= 3, direct_callback_mixed
    assert 0x53 in direct_callback_mixed["code"], direct_callback_mixed
    assert 0x42 in direct_callback_mixed["code"], direct_callback_mixed
    assert any(
        constant.get("type") == "String" and constant.get("value") == ";named:suffix"
        for constant in direct_callback_mixed["constants"]
    ), direct_callback_mixed
    assert any(
        constant.get("type") == "String" and constant.get("value") == " patched-mixed"
        for constant in direct_callback_mixed["constants"]
    ), direct_callback_mixed

    async_direct_callback_mixed = next(
        item for item in module["functions"] if item["name"].endswith("::asyncDirectCallbackMixed")
    )
    assert async_direct_callback_mixed["param_count"] == 3, async_direct_callback_mixed
    assert async_direct_callback_mixed["async_kind"] == "async_future", async_direct_callback_mixed
    assert async_direct_callback_mixed["code"].count(0x02) >= 3, async_direct_callback_mixed
    assert 0x53 in async_direct_callback_mixed["code"], async_direct_callback_mixed
    assert 0x42 in async_direct_callback_mixed["code"], async_direct_callback_mixed
    assert 0x63 in async_direct_callback_mixed["code"], async_direct_callback_mixed
    assert any(
        constant.get("type") == "String" and constant.get("value") == ";named:suffix"
        for constant in async_direct_callback_mixed["constants"]
    ), async_direct_callback_mixed
    assert any(
        constant.get("type") == "String" and constant.get("value") == " patched-async-mixed"
        for constant in async_direct_callback_mixed["constants"]
    ), async_direct_callback_mixed
