def assert_object_calls(module):
    make_user = next(item for item in module["functions"] if item["name"].endswith("::makeUser"))
    assert make_user["param_count"] == 0, make_user
    assert 0x55 in make_user["code"], make_user
    assert any(
        constant.get("type") == "String"
        and constant.get("value") == "package:fcb_kernel_compile_test/main.dart::class:User."
        for constant in make_user["constants"]
    ), make_user
    async_make_user = next(item for item in module["functions"] if item["name"].endswith("::asyncMakeUser"))
    assert async_make_user["async_kind"] == "async_future", async_make_user
    assert async_make_user["param_count"] == 0, async_make_user
    assert async_make_user["code"].count(0x55) >= 2, async_make_user
    assert any(
        constant.get("type") == "String"
        and constant.get("value") == "package:fcb_kernel_compile_test/main.dart::class:User."
        for constant in async_make_user["constants"]
    ), async_make_user
    assert any(
        constant.get("type") == "String"
        and constant.get("value") == "dart:async::class:_Future.value;types:User"
        for constant in async_make_user["constants"]
    ), async_make_user
    async_await_user = next(item for item in module["functions"] if item["name"].endswith("::asyncAwaitThenMakeUser"))
    assert async_await_user["async_kind"] == "async_future", async_await_user
    assert async_await_user["param_count"] == 1, async_await_user
    assert 0x62 in async_await_user["code"], async_await_user
    assert 0x03 in async_await_user["code"], async_await_user
    assert async_await_user["code"].count(0x55) >= 2, async_await_user
    assert 0x63 in async_await_user["code"], async_await_user
    assert any(
        constant.get("type") == "String"
        and constant.get("value") == "package:fcb_kernel_compile_test/main.dart::class:User."
        for constant in async_await_user["constants"]
    ), async_await_user
    assert any(
        constant.get("type") == "String" and constant.get("value") == "patched-await-user"
        for constant in async_await_user["constants"]
    ), async_await_user
    make_config = next(item for item in module["functions"] if item["name"].endswith("::makeConfig"))
    assert make_config["param_count"] == 0, make_config
    assert 0x55 in make_config["code"], make_config
    assert any(
        constant.get("type") == "String"
        and constant.get("value") == "package:fcb_kernel_compile_test/main.dart::class:Config.;named:name,label"
        for constant in make_config["constants"]
    ), make_config
    async_make_config = next(item for item in module["functions"] if item["name"].endswith("::asyncMakeConfig"))
    assert async_make_config["async_kind"] == "async_future", async_make_config
    assert async_make_config["param_count"] == 0, async_make_config
    assert async_make_config["code"].count(0x55) >= 2, async_make_config
    assert any(
        constant.get("type") == "String"
        and constant.get("value") == "package:fcb_kernel_compile_test/main.dart::class:Config.;named:name,label"
        for constant in async_make_config["constants"]
    ), async_make_config
    assert any(
        constant.get("type") == "String"
        and constant.get("value") == "dart:async::class:_Future.value;types:Config"
        for constant in async_make_config["constants"]
    ), async_make_config
    async_await_config = next(item for item in module["functions"] if item["name"].endswith("::asyncAwaitThenMakeConfig"))
    assert async_await_config["async_kind"] == "async_future", async_await_config
    assert async_await_config["param_count"] == 1, async_await_config
    assert 0x62 in async_await_config["code"], async_await_config
    assert 0x03 in async_await_config["code"], async_await_config
    assert async_await_config["code"].count(0x55) >= 2, async_await_config
    assert 0x63 in async_await_config["code"], async_await_config
    assert any(
        constant.get("type") == "String"
        and constant.get("value") == "package:fcb_kernel_compile_test/main.dart::class:Config.;named:name,label"
        for constant in async_await_config["constants"]
    ), async_await_config
    assert any(
        constant.get("type") == "String" and constant.get("value") == "patched-await-config"
        for constant in async_await_config["constants"]
    ), async_await_config
    make_string_box = next(item for item in module["functions"] if item["name"].endswith("::makeStringBox"))
    assert make_string_box["param_count"] == 0, make_string_box
    assert 0x55 in make_string_box["code"], make_string_box
    assert any(
        constant.get("type") == "String"
        and constant.get("value") == "package:fcb_kernel_compile_test/main.dart::class:Box.;types:String"
        for constant in make_string_box["constants"]
    ), make_string_box
    async_make_string_box = next(item for item in module["functions"] if item["name"].endswith("::asyncMakeStringBox"))
    assert async_make_string_box["async_kind"] == "async_future", async_make_string_box
    assert async_make_string_box["param_count"] == 0, async_make_string_box
    assert async_make_string_box["code"].count(0x55) >= 2, async_make_string_box
    assert any(
        constant.get("type") == "String"
        and constant.get("value") == "package:fcb_kernel_compile_test/main.dart::class:Box.;types:String"
        for constant in async_make_string_box["constants"]
    ), async_make_string_box
    assert any(
        constant.get("type") == "String"
        and constant.get("value") == "dart:async::class:_Future.value;types:Box<String>"
        for constant in async_make_string_box["constants"]
    ), async_make_string_box
    async_await_box = next(item for item in module["functions"] if item["name"].endswith("::asyncAwaitThenMakeStringBox"))
    assert async_await_box["async_kind"] == "async_future", async_await_box
    assert async_await_box["param_count"] == 1, async_await_box
    assert 0x62 in async_await_box["code"], async_await_box
    assert async_await_box["code"].count(0x55) >= 2, async_await_box
    assert 0x42 in async_await_box["code"], async_await_box
    assert 0x63 in async_await_box["code"], async_await_box
    assert any(
        constant.get("type") == "String"
        and constant.get("value") == "package:fcb_kernel_compile_test/main.dart::class:Box.;types:String"
        for constant in async_await_box["constants"]
    ), async_await_box
    assert any(
        constant.get("type") == "String"
        and constant.get("value") == "dart:async::class:_Future.value;types:Box<String>"
        for constant in async_await_box["constants"]
    ), async_await_box
    assert any(
        constant.get("type") == "String" and constant.get("value") == "patched-await-box:"
        for constant in async_await_box["constants"]
    ), async_await_box
