def assert_core_calls(module):
    label = next(item for item in module["functions"] if item["name"].endswith("::label"))
    assert label["param_count"] == 1, label
    assert 0x42 in label["code"], label
    assert any(
        constant.get("type") == "String" and constant.get("value") == "hello "
        for constant in label["constants"]
    ), label
    assert any(
        constant.get("type") == "String" and constant.get("value") == "!"
        for constant in label["constants"]
    ), label
    display = next(item for item in module["functions"] if item["name"].endswith("::displayName"))
    assert display["param_count"] == 1, display
    assert 0x43 in display["code"], display
    assert any(
        constant.get("type") == "String" and constant.get("value") == "label"
        for constant in display["constants"]
    ), display
    async_display = next(item for item in module["functions"] if item["name"].endswith("::asyncDisplayName"))
    assert async_display["async_kind"] == "async_future", async_display
    assert async_display["param_count"] == 1, async_display
    assert 0x43 in async_display["code"], async_display
    assert any(
        constant.get("type") == "String" and constant.get("value") == "label"
        for constant in async_display["constants"]
    ), async_display
    async_await_field = next(item for item in module["functions"] if item["name"].endswith("::asyncAwaitThenReadField"))
    assert async_await_field["async_kind"] == "async_future", async_await_field
    assert async_await_field["param_count"] == 2, async_await_field
    assert 0x62 in async_await_field["code"], async_await_field
    assert 0x03 in async_await_field["code"], async_await_field
    assert 0x43 in async_await_field["code"], async_await_field
    assert 0x42 in async_await_field["code"], async_await_field
    assert 0x55 in async_await_field["code"], async_await_field
    assert 0x63 in async_await_field["code"], async_await_field
    assert any(
        constant.get("type") == "String" and constant.get("value") == "patched-await-field:"
        for constant in async_await_field["constants"]
    ), async_await_field
    assert any(
        constant.get("type") == "String" and constant.get("value") == "label"
        for constant in async_await_field["constants"]
    ), async_await_field
    is_known = next(item for item in module["functions"] if item["name"].endswith("::isKnown"))
    assert is_known["param_count"] == 1, is_known
    assert 0x45 in is_known["code"], is_known
    assert any(
        constant.get("type") == "String" and constant.get("value") == "String"
        for constant in is_known["constants"]
    ), is_known
    is_user = next(item for item in module["functions"] if item["name"].endswith("::isUser"))
    assert is_user["param_count"] == 1, is_user
    assert 0x45 in is_user["code"], is_user
    assert any(
        constant.get("type") == "String" and constant.get("value") == "package:fcb_kernel_compile_test/main.dart::User"
        for constant in is_user["constants"]
    ), is_user
    is_string_list = next(item for item in module["functions"] if item["name"].endswith("::isStringList"))
    assert is_string_list["param_count"] == 1, is_string_list
    assert 0x45 in is_string_list["code"], is_string_list
    assert any(
        constant.get("type") == "String" and constant.get("value") == "List<String>"
        for constant in is_string_list["constants"]
    ), is_string_list
    as_string_list = next(item for item in module["functions"] if item["name"].endswith("::asStringList"))
    assert as_string_list["param_count"] == 1, as_string_list
    assert 0x46 in as_string_list["code"], as_string_list
    assert any(
        constant.get("type") == "String" and constant.get("value") == "List<String>"
        for constant in as_string_list["constants"]
    ), as_string_list
    async_is_string_list = next(item for item in module["functions"] if item["name"].endswith("::asyncIsStringList"))
    assert async_is_string_list["async_kind"] == "async_future", async_is_string_list
    assert async_is_string_list["param_count"] == 1, async_is_string_list
    assert 0x45 in async_is_string_list["code"], async_is_string_list
    assert 0x63 in async_is_string_list["code"], async_is_string_list
    assert any(
        constant.get("type") == "String" and constant.get("value") == "List<String>"
        for constant in async_is_string_list["constants"]
    ), async_is_string_list
    async_as_string_list = next(item for item in module["functions"] if item["name"].endswith("::asyncAsStringList"))
    assert async_as_string_list["async_kind"] == "async_future", async_as_string_list
    assert async_as_string_list["param_count"] == 1, async_as_string_list
    assert 0x46 in async_as_string_list["code"], async_as_string_list
    assert 0x63 in async_as_string_list["code"], async_as_string_list
    assert any(
        constant.get("type") == "String" and constant.get("value") == "List<String>"
        for constant in async_as_string_list["constants"]
    ), async_as_string_list
    async_arithmetic_value = next(item for item in module["functions"] if item["name"].endswith("::asyncArithmeticValue"))
    assert async_arithmetic_value["async_kind"] == "async_future", async_arithmetic_value
    assert async_arithmetic_value["param_count"] == 1, async_arithmetic_value
    assert 0x02 in async_arithmetic_value["code"], async_arithmetic_value
    assert 0x01 in async_arithmetic_value["code"], async_arithmetic_value
    assert 0x10 in async_arithmetic_value["code"], async_arithmetic_value
    assert 0x55 in async_arithmetic_value["code"], async_arithmetic_value
    assert 0x63 in async_arithmetic_value["code"], async_arithmetic_value
    assert any(
        constant.get("type") == "Int" and constant.get("value") == 2
        for constant in async_arithmetic_value["constants"]
    ), async_arithmetic_value
    async_await_arithmetic = next(
        item for item in module["functions"] if item["name"].endswith("::asyncAwaitThenArithmeticValue")
    )
    assert async_await_arithmetic["async_kind"] == "async_future", async_await_arithmetic
    assert async_await_arithmetic["param_count"] == 1, async_await_arithmetic
    assert 0x62 in async_await_arithmetic["code"], async_await_arithmetic
    assert 0x03 in async_await_arithmetic["code"], async_await_arithmetic
    assert 0x10 in async_await_arithmetic["code"], async_await_arithmetic
    assert 0x55 in async_await_arithmetic["code"], async_await_arithmetic
    assert 0x63 in async_await_arithmetic["code"], async_await_arithmetic
    assert any(
        constant.get("type") == "Int" and constant.get("value") == 5
        for constant in async_await_arithmetic["constants"]
    ), async_await_arithmetic
    async_subtract_value = next(item for item in module["functions"] if item["name"].endswith("::asyncSubtractValue"))
    assert async_subtract_value["async_kind"] == "async_future", async_subtract_value
    assert async_subtract_value["param_count"] == 1, async_subtract_value
    assert 0x02 in async_subtract_value["code"], async_subtract_value
    assert 0x01 in async_subtract_value["code"], async_subtract_value
    assert 0x11 in async_subtract_value["code"], async_subtract_value
    assert 0x55 in async_subtract_value["code"], async_subtract_value
    assert 0x63 in async_subtract_value["code"], async_subtract_value
    assert any(
        constant.get("type") == "Int" and constant.get("value") == 3
        for constant in async_subtract_value["constants"]
    ), async_subtract_value
    async_await_subtract = next(
        item for item in module["functions"] if item["name"].endswith("::asyncAwaitThenSubtractValue")
    )
    assert async_await_subtract["async_kind"] == "async_future", async_await_subtract
    assert async_await_subtract["param_count"] == 1, async_await_subtract
    assert 0x62 in async_await_subtract["code"], async_await_subtract
    assert 0x03 in async_await_subtract["code"], async_await_subtract
    assert 0x11 in async_await_subtract["code"], async_await_subtract
    assert 0x55 in async_await_subtract["code"], async_await_subtract
    assert 0x63 in async_await_subtract["code"], async_await_subtract
    assert any(
        constant.get("type") == "Int" and constant.get("value") == 7
        for constant in async_await_subtract["constants"]
    ), async_await_subtract
    async_multiply_value = next(item for item in module["functions"] if item["name"].endswith("::asyncMultiplyValue"))
    assert async_multiply_value["async_kind"] == "async_future", async_multiply_value
    assert async_multiply_value["param_count"] == 1, async_multiply_value
    assert 0x02 in async_multiply_value["code"], async_multiply_value
    assert 0x01 in async_multiply_value["code"], async_multiply_value
    assert 0x12 in async_multiply_value["code"], async_multiply_value
    assert 0x55 in async_multiply_value["code"], async_multiply_value
    assert 0x63 in async_multiply_value["code"], async_multiply_value
    assert any(
        constant.get("type") == "Int" and constant.get("value") == 3
        for constant in async_multiply_value["constants"]
    ), async_multiply_value
    async_await_multiply = next(
        item for item in module["functions"] if item["name"].endswith("::asyncAwaitThenMultiplyValue")
    )
    assert async_await_multiply["async_kind"] == "async_future", async_await_multiply
    assert async_await_multiply["param_count"] == 1, async_await_multiply
    assert 0x62 in async_await_multiply["code"], async_await_multiply
    assert 0x03 in async_await_multiply["code"], async_await_multiply
    assert 0x12 in async_await_multiply["code"], async_await_multiply
    assert 0x55 in async_await_multiply["code"], async_await_multiply
    assert 0x63 in async_await_multiply["code"], async_await_multiply
    assert any(
        constant.get("type") == "Int" and constant.get("value") == 9
        for constant in async_await_multiply["constants"]
    ), async_await_multiply
    async_divide_value = next(item for item in module["functions"] if item["name"].endswith("::asyncDivideValue"))
    assert async_divide_value["async_kind"] == "async_future", async_divide_value
    assert async_divide_value["param_count"] == 1, async_divide_value
    assert 0x02 in async_divide_value["code"], async_divide_value
    assert 0x01 in async_divide_value["code"], async_divide_value
    assert 0x13 in async_divide_value["code"], async_divide_value
    assert 0x55 in async_divide_value["code"], async_divide_value
    assert 0x63 in async_divide_value["code"], async_divide_value
    assert any(
        constant.get("type") == "Int" and constant.get("value") == 4
        for constant in async_divide_value["constants"]
    ), async_divide_value
    async_logical_flag = next(item for item in module["functions"] if item["name"].endswith("::asyncLogicalFlag"))
    assert async_logical_flag["async_kind"] == "async_future", async_logical_flag
    assert async_logical_flag["param_count"] == 2, async_logical_flag
    assert async_logical_flag["code"].count(0x02) >= 3, async_logical_flag
    assert async_logical_flag["code"].count(0x31) >= 3, async_logical_flag
    assert 0x30 in async_logical_flag["code"], async_logical_flag
    assert 0x55 in async_logical_flag["code"], async_logical_flag
    assert 0x63 in async_logical_flag["code"], async_logical_flag
    assert any(
        constant.get("type") == "Bool" and constant.get("value") is True
        for constant in async_logical_flag["constants"]
    ), async_logical_flag
    assert any(
        constant.get("type") == "Bool" and constant.get("value") is False
        for constant in async_logical_flag["constants"]
    ), async_logical_flag
    async_always_throw = next(item for item in module["functions"] if item["name"].endswith("::asyncAlwaysThrow"))
    assert async_always_throw["async_kind"] == "async_future", async_always_throw
    assert async_always_throw["param_count"] == 0, async_always_throw
    assert 0x60 in async_always_throw["code"], async_always_throw
    assert 0x55 in async_always_throw["code"], async_always_throw
    assert 0x63 in async_always_throw["code"], async_always_throw
    assert any(
        constant.get("type") == "String" and constant.get("value") == "patched-async-boom"
        for constant in async_always_throw["constants"]
    ), async_always_throw
    async_static_helper = next(item for item in module["functions"] if item["name"].endswith("::asyncStaticHelperValue"))
    assert async_static_helper["async_kind"] == "async_future", async_static_helper
    assert async_static_helper["param_count"] == 0, async_static_helper
    assert 0x50 in async_static_helper["code"], async_static_helper
    assert 0x10 in async_static_helper["code"], async_static_helper
    assert 0x55 in async_static_helper["code"], async_static_helper
    assert 0x63 in async_static_helper["code"], async_static_helper
    assert any(
        constant.get("type") == "String" and constant.get("value", "").endswith("::helper")
        for constant in async_static_helper["constants"]
    ), async_static_helper
    assert any(
        constant.get("type") == "Double" and constant.get("value") == 3.5
        for constant in async_static_helper["constants"]
    ), async_static_helper
    async_await_static = next(item for item in module["functions"] if item["name"].endswith("::asyncAwaitThenStaticHelperValue"))
    assert async_await_static["async_kind"] == "async_future", async_await_static
    assert async_await_static["param_count"] == 1, async_await_static
    assert 0x62 in async_await_static["code"], async_await_static
    assert 0x03 in async_await_static["code"], async_await_static
    assert 0x50 in async_await_static["code"], async_await_static
    assert 0x10 in async_await_static["code"], async_await_static
    assert 0x55 in async_await_static["code"], async_await_static
    assert 0x63 in async_await_static["code"], async_await_static
    assert any(
        constant.get("type") == "String" and constant.get("value", "").endswith("::helper")
        for constant in async_await_static["constants"]
    ), async_await_static
    async_concat_label = next(item for item in module["functions"] if item["name"].endswith("::asyncConcatLabel"))
    assert async_concat_label["async_kind"] == "async_future", async_concat_label
    assert async_concat_label["param_count"] == 1, async_concat_label
    assert 0x02 in async_concat_label["code"], async_concat_label
    assert 0x42 in async_concat_label["code"], async_concat_label
    assert 0x55 in async_concat_label["code"], async_concat_label
    assert 0x63 in async_concat_label["code"], async_concat_label
    assert any(
        constant.get("type") == "String" and constant.get("value") == "patched-async "
        for constant in async_concat_label["constants"]
    ), async_concat_label
    async_nullable_choice = next(item for item in module["functions"] if item["name"].endswith("::asyncNullableChoice"))
    assert async_nullable_choice["async_kind"] == "async_future", async_nullable_choice
    assert async_nullable_choice["param_count"] == 1, async_nullable_choice
    assert 0x02 in async_nullable_choice["code"], async_nullable_choice
    assert 0x31 in async_nullable_choice["code"], async_nullable_choice
    assert 0x30 in async_nullable_choice["code"], async_nullable_choice
    assert 0x55 in async_nullable_choice["code"], async_nullable_choice
    assert 0x63 in async_nullable_choice["code"], async_nullable_choice
    assert any(
        constant.get("type") == "Null" and constant.get("value") is None
        for constant in async_nullable_choice["constants"]
    ), async_nullable_choice
    assert any(
        constant.get("type") == "String" and constant.get("value") == "patched-null"
        for constant in async_nullable_choice["constants"]
    ), async_nullable_choice
    make_user = next(item for item in module["functions"] if item["name"].endswith("::makeUser"))
    assert make_user["param_count"] == 0, make_user
    assert 0x55 in make_user["code"], make_user
    assert any(
        constant.get("type") == "String" and constant.get("value") == "package:fcb_kernel_compile_test/main.dart::class:User."
        for constant in make_user["constants"]
    ), make_user
    async_make_user = next(item for item in module["functions"] if item["name"].endswith("::asyncMakeUser"))
    assert async_make_user["async_kind"] == "async_future", async_make_user
    assert async_make_user["param_count"] == 0, async_make_user
    assert async_make_user["code"].count(0x55) >= 2, async_make_user
    assert any(
        constant.get("type") == "String" and constant.get("value") == "package:fcb_kernel_compile_test/main.dart::class:User."
        for constant in async_make_user["constants"]
    ), async_make_user
    assert any(
        constant.get("type") == "String"
        and constant.get("value") == "dart:async::class:_Future.value;types:User"
        for constant in async_make_user["constants"]
    ), async_make_user
    make_config = next(item for item in module["functions"] if item["name"].endswith("::makeConfig"))
    assert make_config["param_count"] == 0, make_config
    assert 0x55 in make_config["code"], make_config
    assert any(
        constant.get("type") == "String" and constant.get("value") == "package:fcb_kernel_compile_test/main.dart::class:Config.;named:name,label"
        for constant in make_config["constants"]
    ), make_config
    async_make_config = next(item for item in module["functions"] if item["name"].endswith("::asyncMakeConfig"))
    assert async_make_config["async_kind"] == "async_future", async_make_config
    assert async_make_config["param_count"] == 0, async_make_config
    assert async_make_config["code"].count(0x55) >= 2, async_make_config
    assert any(
        constant.get("type") == "String" and constant.get("value") == "package:fcb_kernel_compile_test/main.dart::class:Config.;named:name,label"
        for constant in async_make_config["constants"]
    ), async_make_config
    assert any(
        constant.get("type") == "String"
        and constant.get("value") == "dart:async::class:_Future.value;types:Config"
        for constant in async_make_config["constants"]
    ), async_make_config
    update_config = next(item for item in module["functions"] if item["name"].endswith("::updateConfigLabel"))
    assert update_config["param_count"] == 2, update_config
    assert 0x44 in update_config["code"], update_config
    assert 0x43 in update_config["code"], update_config
    assert 0x05 in update_config["code"], update_config
    assert any(
        constant.get("type") == "String" and constant.get("value") == "label"
        for constant in update_config["constants"]
    ), update_config
    assert any(
        constant.get("type") == "String" and constant.get("value") == "-patched"
        for constant in update_config["constants"]
    ), update_config
    make_string_box = next(item for item in module["functions"] if item["name"].endswith("::makeStringBox"))
    assert make_string_box["param_count"] == 0, make_string_box
    assert 0x55 in make_string_box["code"], make_string_box
    assert any(
        constant.get("type") == "String" and constant.get("value") == "package:fcb_kernel_compile_test/main.dart::class:Box.;types:String"
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
    dynamic_named_call = next(item for item in module["functions"] if item["name"].endswith("::dynamicNamedCall"))
    assert dynamic_named_call["param_count"] == 0, dynamic_named_call
    assert 0x55 in dynamic_named_call["code"], dynamic_named_call
    assert 0x51 in dynamic_named_call["code"], dynamic_named_call
    assert any(
        constant.get("type") == "String" and constant.get("value") == "package:fcb_kernel_compile_test/main.dart::class:Greeter."
        for constant in dynamic_named_call["constants"]
    ), dynamic_named_call
    assert any(
        constant.get("type") == "String" and constant.get("value") == "surround;named:prefix,suffix"
        for constant in dynamic_named_call["constants"]
    ), dynamic_named_call
    for value in ["patched", "<", ">"]:
        assert any(
            constant.get("type") == "String" and constant.get("value") == value
            for constant in dynamic_named_call["constants"]
        ), dynamic_named_call
    async_dynamic_named_call = next(item for item in module["functions"] if item["name"].endswith("::asyncDynamicNamedCall"))
    assert async_dynamic_named_call["async_kind"] == "async_future", async_dynamic_named_call
    assert async_dynamic_named_call["param_count"] == 0, async_dynamic_named_call
    assert 0x55 in async_dynamic_named_call["code"], async_dynamic_named_call
    assert 0x51 in async_dynamic_named_call["code"], async_dynamic_named_call
    assert any(
        constant.get("type") == "String" and constant.get("value") == "package:fcb_kernel_compile_test/main.dart::class:Greeter."
        for constant in async_dynamic_named_call["constants"]
    ), async_dynamic_named_call
    assert any(
        constant.get("type") == "String" and constant.get("value") == "surround;named:prefix,suffix"
        for constant in async_dynamic_named_call["constants"]
    ), async_dynamic_named_call
    for value in ["patched-async", "<", ">"]:
        assert any(
            constant.get("type") == "String" and constant.get("value") == value
            for constant in async_dynamic_named_call["constants"]
        ), async_dynamic_named_call
    async_await_dynamic_call = next(item for item in module["functions"] if item["name"].endswith("::asyncAwaitThenDynamicCall"))
    assert async_await_dynamic_call["async_kind"] == "async_future", async_await_dynamic_call
    assert async_await_dynamic_call["param_count"] == 1, async_await_dynamic_call
    assert 0x62 in async_await_dynamic_call["code"], async_await_dynamic_call
    assert 0x03 in async_await_dynamic_call["code"], async_await_dynamic_call
    assert 0x51 in async_await_dynamic_call["code"], async_await_dynamic_call
    assert 0x55 in async_await_dynamic_call["code"], async_await_dynamic_call
    assert 0x63 in async_await_dynamic_call["code"], async_await_dynamic_call
    assert any(
        constant.get("type") == "String" and constant.get("value") == "surround;named:prefix,suffix"
        for constant in async_await_dynamic_call["constants"]
    ), async_await_dynamic_call
    assert any(
        constant.get("type") == "String" and constant.get("value") == "patched-await-dynamic<"
        for constant in async_await_dynamic_call["constants"]
    ), async_await_dynamic_call
    async_await_callback = next(item for item in module["functions"] if item["name"].endswith("::asyncAwaitThenDirectCallbackMixed"))
    assert async_await_callback["async_kind"] == "async_future", async_await_callback
    assert async_await_callback["param_count"] == 3, async_await_callback
    assert 0x62 in async_await_callback["code"], async_await_callback
    assert 0x03 in async_await_callback["code"], async_await_callback
    assert 0x53 in async_await_callback["code"], async_await_callback
    assert 0x42 in async_await_callback["code"], async_await_callback
    assert 0x55 in async_await_callback["code"], async_await_callback
    assert 0x63 in async_await_callback["code"], async_await_callback
    assert any(
        constant.get("type") == "String" and constant.get("value") == " patched-await-callback"
        for constant in async_await_callback["constants"]
    ), async_await_callback
    async_int_input = next(item for item in module["functions"] if item["name"].endswith("::asyncIntInput"))
    assert async_int_input["async_kind"] == "sync", async_int_input
    assert async_int_input["return_convention"] == "tagged", async_int_input
    assert async_int_input["param_count"] == 0, async_int_input
    assert 0x55 in async_int_input["code"], async_int_input
    assert async_int_input["code"][-1] == 255, async_int_input
    assert any(
        constant.get("type") == "Int" and constant.get("value") == 2
        for constant in async_int_input["constants"]
    ), async_int_input
    assert any(
        constant.get("type") == "String"
        and constant.get("value") == "dart:async::class:_Future.value;types:int"
        for constant in async_int_input["constants"]
    ), async_int_input
    same_object = next(item for item in module["functions"] if item["name"].endswith("::sameObject"))
    assert same_object["param_count"] == 1, same_object
    assert 0x52 in same_object["code"], same_object
    assert any(
        constant.get("type") == "String" and constant.get("value") == "dart:core::identical"
        for constant in same_object["constants"]
    ), same_object
    async_same_object = next(item for item in module["functions"] if item["name"].endswith("::asyncSameObject"))
    assert async_same_object["async_kind"] == "async_future", async_same_object
    assert async_same_object["param_count"] == 1, async_same_object
    assert 0x52 in async_same_object["code"], async_same_object
    assert any(
        constant.get("type") == "String" and constant.get("value") == "dart:core::identical"
        for constant in async_same_object["constants"]
    ), async_same_object
    async_await_same = next(item for item in module["functions"] if item["name"].endswith("::asyncAwaitThenSameObject"))
    assert async_await_same["async_kind"] == "async_future", async_await_same
    assert async_await_same["param_count"] == 1, async_await_same
    assert 0x62 in async_await_same["code"], async_await_same
    assert 0x03 in async_await_same["code"], async_await_same
    assert 0x52 in async_await_same["code"], async_await_same
    assert 0x55 in async_await_same["code"], async_await_same
    assert 0x63 in async_await_same["code"], async_await_same
    assert any(
        constant.get("type") == "String" and constant.get("value") == "dart:core::identical"
        for constant in async_await_same["constants"]
    ), async_await_same
    async_await_is = next(item for item in module["functions"] if item["name"].endswith("::asyncAwaitThenIsString"))
    assert async_await_is["async_kind"] == "async_future", async_await_is
    assert async_await_is["param_count"] == 1, async_await_is
    assert 0x62 in async_await_is["code"], async_await_is
    assert 0x03 in async_await_is["code"], async_await_is
    assert 0x45 in async_await_is["code"], async_await_is
    assert 0x55 in async_await_is["code"], async_await_is
    assert 0x63 in async_await_is["code"], async_await_is
    assert any(
        constant.get("type") == "String" and constant.get("value") == "String"
        for constant in async_await_is["constants"]
    ), async_await_is
    async_await_as = next(item for item in module["functions"] if item["name"].endswith("::asyncAwaitThenAsStringList"))
    assert async_await_as["async_kind"] == "async_future", async_await_as
    assert async_await_as["param_count"] == 1, async_await_as
    assert 0x62 in async_await_as["code"], async_await_as
    assert 0x03 in async_await_as["code"], async_await_as
    assert 0x46 in async_await_as["code"], async_await_as
    assert 0x55 in async_await_as["code"], async_await_as
    assert 0x63 in async_await_as["code"], async_await_as
    assert any(
        constant.get("type") == "String" and constant.get("value") == "List<String>"
        for constant in async_await_as["constants"]
    ), async_await_as
    captured_greeting = next(item for item in module["functions"] if item["name"].endswith("::capturedGreeting"))
    assert captured_greeting["param_count"] == 1, captured_greeting
    assert 0x42 in captured_greeting["code"], captured_greeting
    assert 0x03 in captured_greeting["code"], captured_greeting
    assert 0x04 in captured_greeting["code"], captured_greeting
    assert any(
        constant.get("type") == "String" and constant.get("value") == "patched"
        for constant in captured_greeting["constants"]
    ), captured_greeting
    stored_closure_greeting = next(item for item in module["functions"] if item["name"].endswith("::storedClosureGreeting"))
    assert stored_closure_greeting["param_count"] == 1, stored_closure_greeting
    assert 0x42 in stored_closure_greeting["code"], stored_closure_greeting
    assert 0x03 in stored_closure_greeting["code"], stored_closure_greeting
    assert 0x04 in stored_closure_greeting["code"], stored_closure_greeting
    assert any(
        constant.get("type") == "String" and constant.get("value") == "patched"
        for constant in stored_closure_greeting["constants"]
    ), stored_closure_greeting
    passed_escaping_greeting = next(item for item in module["functions"] if item["name"].endswith("::passedEscapingGreeting"))
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
    direct_callback_named = next(item for item in module["functions"] if item["name"].endswith("::directCallbackNamed"))
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
    direct_callback_mixed = next(item for item in module["functions"] if item["name"].endswith("::directCallbackMixed"))
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
    async_direct_callback_mixed = next(item for item in module["functions"] if item["name"].endswith("::asyncDirectCallbackMixed"))
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
    escaping_greeting = next(item for item in module["functions"] if item["name"].endswith("::escapingGreeting"))
    assert escaping_greeting["param_count"] == 1, escaping_greeting
    assert 0x54 in escaping_greeting["code"], escaping_greeting
    assert 0x03 in escaping_greeting["code"], escaping_greeting
    assert 0x04 in escaping_greeting["code"], escaping_greeting
    assert any(
        constant.get("type") == "String" and constant.get("value") == "patched"
        for constant in escaping_greeting["constants"]
    ), escaping_greeting
    assert any(
        constant.get("type") == "String" and constant.get("value", "").endswith("::escapingGreeting.<closure0>();captures:2")
        for constant in escaping_greeting["constants"]
    ), escaping_greeting
    escaping_closure = next(item for item in module["functions"] if item["name"].endswith("::escapingGreeting.<closure0>()"))
    assert escaping_closure["param_count"] == 2, escaping_closure
    assert 0x42 in escaping_closure["code"], escaping_closure
    stored_escaping_greeting = next(item for item in module["functions"] if item["name"].endswith("::storedEscapingGreeting"))
    assert stored_escaping_greeting["param_count"] == 1, stored_escaping_greeting
    assert 0x54 in stored_escaping_greeting["code"], stored_escaping_greeting
    assert 0x03 in stored_escaping_greeting["code"], stored_escaping_greeting
    assert 0x04 in stored_escaping_greeting["code"], stored_escaping_greeting
    assert any(
        constant.get("type") == "String" and constant.get("value") == "patched"
        for constant in stored_escaping_greeting["constants"]
    ), stored_escaping_greeting
    assert any(
        constant.get("type") == "String" and constant.get("value", "").endswith("::storedEscapingGreeting.<closure0>();captures:2")
        for constant in stored_escaping_greeting["constants"]
    ), stored_escaping_greeting
    stored_escaping_closure = next(item for item in module["functions"] if item["name"].endswith("::storedEscapingGreeting.<closure0>()"))
    assert stored_escaping_closure["param_count"] == 2, stored_escaping_closure
    assert 0x42 in stored_escaping_closure["code"], stored_escaping_closure
    personalized_escaping_greeting = next(item for item in module["functions"] if item["name"].endswith("::personalizedEscapingGreeting"))
    assert personalized_escaping_greeting["param_count"] == 1, personalized_escaping_greeting
    assert 0x54 in personalized_escaping_greeting["code"], personalized_escaping_greeting
    assert 0x03 in personalized_escaping_greeting["code"], personalized_escaping_greeting
    assert 0x04 in personalized_escaping_greeting["code"], personalized_escaping_greeting
    assert any(
        constant.get("type") == "String" and constant.get("value") == "patched"
        for constant in personalized_escaping_greeting["constants"]
    ), personalized_escaping_greeting
    assert any(
        constant.get("type") == "String" and constant.get("value", "").endswith("::personalizedEscapingGreeting.<closure0>();captures:2")
        for constant in personalized_escaping_greeting["constants"]
    ), personalized_escaping_greeting
    personalized_escaping_closure = next(item for item in module["functions"] if item["name"].endswith("::personalizedEscapingGreeting.<closure0>()"))
    assert personalized_escaping_closure["param_count"] == 3, personalized_escaping_closure
    assert 0x42 in personalized_escaping_closure["code"], personalized_escaping_closure
    named_escaping_greeting = next(item for item in module["functions"] if item["name"].endswith("::namedEscapingGreeting"))
    assert named_escaping_greeting["param_count"] == 1, named_escaping_greeting
    assert 0x54 in named_escaping_greeting["code"], named_escaping_greeting
    assert 0x03 in named_escaping_greeting["code"], named_escaping_greeting
    assert 0x04 in named_escaping_greeting["code"], named_escaping_greeting
    assert any(
        constant.get("type") == "String" and constant.get("value") == "patched"
        for constant in named_escaping_greeting["constants"]
    ), named_escaping_greeting
    assert any(
        constant.get("type") == "String" and constant.get("value", "").endswith("::namedEscapingGreeting.<closure0>();captures:2;named:suffix")
        for constant in named_escaping_greeting["constants"]
    ), named_escaping_greeting
    named_escaping_closure = next(item for item in module["functions"] if item["name"].endswith("::namedEscapingGreeting.<closure0>()"))
    assert named_escaping_closure["param_count"] == 3, named_escaping_closure
    assert 0x42 in named_escaping_closure["code"], named_escaping_closure
    optional_positional_escaping_greeting = next(item for item in module["functions"] if item["name"].endswith("::optionalPositionalEscapingGreeting"))
    assert optional_positional_escaping_greeting["param_count"] == 1, optional_positional_escaping_greeting
    assert 0x54 in optional_positional_escaping_greeting["code"], optional_positional_escaping_greeting
    assert 0x03 in optional_positional_escaping_greeting["code"], optional_positional_escaping_greeting
    assert 0x04 in optional_positional_escaping_greeting["code"], optional_positional_escaping_greeting
    assert any(
        constant.get("type") == "String" and constant.get("value") == "patched"
        for constant in optional_positional_escaping_greeting["constants"]
    ), optional_positional_escaping_greeting
    assert any(
        constant.get("type") == "String" and constant.get("value", "").endswith("::optionalPositionalEscapingGreeting.<closure0>();captures:2;optional-pos:1")
        for constant in optional_positional_escaping_greeting["constants"]
    ), optional_positional_escaping_greeting
    optional_positional_escaping_closure = next(item for item in module["functions"] if item["name"].endswith("::optionalPositionalEscapingGreeting.<closure0>()"))
    assert optional_positional_escaping_closure["param_count"] == 3, optional_positional_escaping_closure
    assert 0x42 in optional_positional_escaping_closure["code"], optional_positional_escaping_closure
    optional_named_escaping_greeting = next(item for item in module["functions"] if item["name"].endswith("::optionalNamedEscapingGreeting"))
    assert optional_named_escaping_greeting["param_count"] == 1, optional_named_escaping_greeting
    assert 0x54 in optional_named_escaping_greeting["code"], optional_named_escaping_greeting
    assert 0x03 in optional_named_escaping_greeting["code"], optional_named_escaping_greeting
    assert 0x04 in optional_named_escaping_greeting["code"], optional_named_escaping_greeting
    assert any(
        constant.get("type") == "String" and constant.get("value") == "patched"
        for constant in optional_named_escaping_greeting["constants"]
    ), optional_named_escaping_greeting
    assert any(
        constant.get("type") == "String" and constant.get("value", "").endswith("::optionalNamedEscapingGreeting.<closure0>();captures:2;named:?suffix")
        for constant in optional_named_escaping_greeting["constants"]
    ), optional_named_escaping_greeting
    optional_named_escaping_closure = next(item for item in module["functions"] if item["name"].endswith("::optionalNamedEscapingGreeting.<closure0>()"))
    assert optional_named_escaping_closure["param_count"] == 3, optional_named_escaping_closure
    assert 0x42 in optional_named_escaping_closure["code"], optional_named_escaping_closure
    generic_escaping_greeting = next(item for item in module["functions"] if item["name"].endswith("::genericEscapingGreeting"))
    assert generic_escaping_greeting["param_count"] == 1, generic_escaping_greeting
    assert 0x54 in generic_escaping_greeting["code"], generic_escaping_greeting
    assert any(
        constant.get("type") == "String" and constant.get("value", "").endswith("::genericEscapingGreeting.<closure0>();captures:2;type-params:1")
        for constant in generic_escaping_greeting["constants"]
    ), generic_escaping_greeting
    generic_escaping_closure = next(item for item in module["functions"] if item["name"].endswith("::genericEscapingGreeting.<closure0>()"))
    assert generic_escaping_closure["param_count"] == 3, generic_escaping_closure
    assert 0x42 in generic_escaping_closure["code"], generic_escaping_closure
    local_function_escaping_greeting = next(item for item in module["functions"] if item["name"].endswith("::localFunctionEscapingGreeting"))
    assert local_function_escaping_greeting["param_count"] == 1, local_function_escaping_greeting
    assert 0x54 in local_function_escaping_greeting["code"], local_function_escaping_greeting
    assert 0x03 in local_function_escaping_greeting["code"], local_function_escaping_greeting
    assert 0x04 in local_function_escaping_greeting["code"], local_function_escaping_greeting
    assert any(
        constant.get("type") == "String" and constant.get("value") == "patched"
        for constant in local_function_escaping_greeting["constants"]
    ), local_function_escaping_greeting
    assert any(
        constant.get("type") == "String" and constant.get("value", "").endswith("::localFunctionEscapingGreeting.<closure0>();captures:2")
        for constant in local_function_escaping_greeting["constants"]
    ), local_function_escaping_greeting
    local_function_escaping_closure = next(item for item in module["functions"] if item["name"].endswith("::localFunctionEscapingGreeting.<closure0>()"))
    assert local_function_escaping_closure["param_count"] == 2, local_function_escaping_closure
    assert 0x42 in local_function_escaping_closure["code"], local_function_escaping_closure
    body_local_escaping_greeting = next(item for item in module["functions"] if item["name"].endswith("::bodyLocalEscapingGreeting"))
    assert body_local_escaping_greeting["param_count"] == 1, body_local_escaping_greeting
    assert 0x54 in body_local_escaping_greeting["code"], body_local_escaping_greeting
    assert 0x03 in body_local_escaping_greeting["code"], body_local_escaping_greeting
    assert 0x04 in body_local_escaping_greeting["code"], body_local_escaping_greeting
    assert any(
        constant.get("type") == "String" and constant.get("value") == "patched"
        for constant in body_local_escaping_greeting["constants"]
    ), body_local_escaping_greeting
    assert any(
        constant.get("type") == "String" and constant.get("value", "").endswith("::bodyLocalEscapingGreeting.<closure0>();captures:2")
        for constant in body_local_escaping_greeting["constants"]
    ), body_local_escaping_greeting
    body_local_escaping_closure = next(item for item in module["functions"] if item["name"].endswith("::bodyLocalEscapingGreeting.<closure0>()"))
    assert body_local_escaping_closure["param_count"] == 2, body_local_escaping_closure
    assert 0x42 in body_local_escaping_closure["code"], body_local_escaping_closure
    assert 0x03 in body_local_escaping_closure["code"], body_local_escaping_closure
    assert 0x04 in body_local_escaping_closure["code"], body_local_escaping_closure
    assert any(
        constant.get("type") == "String" and constant.get("value") == "body"
        for constant in body_local_escaping_closure["constants"]
    ), body_local_escaping_closure
    try_catch_escaping_greeting = next(item for item in module["functions"] if item["name"].endswith("::tryCatchEscapingGreeting"))
    assert try_catch_escaping_greeting["param_count"] == 1, try_catch_escaping_greeting
    assert 0x54 in try_catch_escaping_greeting["code"], try_catch_escaping_greeting
    assert 0x03 in try_catch_escaping_greeting["code"], try_catch_escaping_greeting
    assert 0x04 in try_catch_escaping_greeting["code"], try_catch_escaping_greeting
    assert any(
        constant.get("type") == "String" and constant.get("value", "").endswith("::tryCatchEscapingGreeting.<closure0>();captures:1")
        for constant in try_catch_escaping_greeting["constants"]
    ), try_catch_escaping_greeting
    try_catch_escaping_closure = next(item for item in module["functions"] if item["name"].endswith("::tryCatchEscapingGreeting.<closure0>()"))
    assert try_catch_escaping_closure["param_count"] == 2, try_catch_escaping_closure
    assert 0x61 in try_catch_escaping_closure["code"], try_catch_escaping_closure
    assert 0x60 in try_catch_escaping_closure["code"], try_catch_escaping_closure
    assert 0x31 in try_catch_escaping_closure["code"], try_catch_escaping_closure
    assert 0x30 in try_catch_escaping_closure["code"], try_catch_escaping_closure
    assert 0x03 in try_catch_escaping_closure["code"], try_catch_escaping_closure
    assert 0x04 in try_catch_escaping_closure["code"], try_catch_escaping_closure
    assert any(
        constant.get("type") == "String" and constant.get("value") == "-boom"
        for constant in try_catch_escaping_closure["constants"]
    ), try_catch_escaping_closure
    assert any(
        constant.get("type") == "String" and constant.get("value") == "-caught "
        for constant in try_catch_escaping_closure["constants"]
    ), try_catch_escaping_closure
    dynamic_call_escaping_greeting = next(item for item in module["functions"] if item["name"].endswith("::dynamicCallEscapingGreeting"))
    assert dynamic_call_escaping_greeting["param_count"] == 1, dynamic_call_escaping_greeting
    assert 0x55 in dynamic_call_escaping_greeting["code"], dynamic_call_escaping_greeting
    assert 0x54 in dynamic_call_escaping_greeting["code"], dynamic_call_escaping_greeting
    assert 0x03 in dynamic_call_escaping_greeting["code"], dynamic_call_escaping_greeting
    assert 0x04 in dynamic_call_escaping_greeting["code"], dynamic_call_escaping_greeting
    assert any(
        constant.get("type") == "String" and constant.get("value") == "package:fcb_kernel_compile_test/main.dart::class:Greeter."
        for constant in dynamic_call_escaping_greeting["constants"]
    ), dynamic_call_escaping_greeting
    assert any(
        constant.get("type") == "String" and constant.get("value", "").endswith("::dynamicCallEscapingGreeting.<closure0>();captures:2")
        for constant in dynamic_call_escaping_greeting["constants"]
    ), dynamic_call_escaping_greeting
    dynamic_call_escaping_closure = next(item for item in module["functions"] if item["name"].endswith("::dynamicCallEscapingGreeting.<closure0>()"))
    assert dynamic_call_escaping_closure["param_count"] == 3, dynamic_call_escaping_closure
    assert 0x51 in dynamic_call_escaping_closure["code"], dynamic_call_escaping_closure
    assert any(
        constant.get("type") == "String" and constant.get("value") == "surround;named:prefix,suffix"
        for constant in dynamic_call_escaping_closure["constants"]
    ), dynamic_call_escaping_closure
    assert any(
        constant.get("type") == "String" and constant.get("value") == "patched-"
        for constant in dynamic_call_escaping_closure["constants"]
    ), dynamic_call_escaping_closure
    logical_escaping_greeting = next(item for item in module["functions"] if item["name"].endswith("::logicalEscapingGreeting"))
    assert logical_escaping_greeting["param_count"] == 1, logical_escaping_greeting
    assert 0x54 in logical_escaping_greeting["code"], logical_escaping_greeting
    assert 0x03 in logical_escaping_greeting["code"], logical_escaping_greeting
    assert 0x04 in logical_escaping_greeting["code"], logical_escaping_greeting
    assert any(
        constant.get("type") == "String" and constant.get("value", "").endswith("::logicalEscapingGreeting.<closure0>();captures:2")
        for constant in logical_escaping_greeting["constants"]
    ), logical_escaping_greeting
    logical_escaping_closure = next(item for item in module["functions"] if item["name"].endswith("::logicalEscapingGreeting.<closure0>()"))
    assert logical_escaping_closure["param_count"] == 4, logical_escaping_closure
    assert logical_escaping_closure["code"].count(0x31) >= 4, logical_escaping_closure
    assert 0x30 in logical_escaping_closure["code"], logical_escaping_closure
    assert 0x42 in logical_escaping_closure["code"], logical_escaping_closure
    assert 0x21 in logical_escaping_closure["code"], logical_escaping_closure
    for value in ["vip", " pro", " basic"]:
        assert any(
            constant.get("type") == "String" and constant.get("value") == value
            for constant in logical_escaping_closure["constants"]
        ), logical_escaping_closure
    assert any(
        constant.get("type") == "Bool" and constant.get("value") == True
        for constant in logical_escaping_closure["constants"]
    ), logical_escaping_closure
    assert any(
        constant.get("type") == "Bool" and constant.get("value") == False
        for constant in logical_escaping_closure["constants"]
    ), logical_escaping_closure
    if_else_escaping_greeting = next(item for item in module["functions"] if item["name"].endswith("::ifElseEscapingGreeting"))
    assert if_else_escaping_greeting["param_count"] == 1, if_else_escaping_greeting
    assert 0x54 in if_else_escaping_greeting["code"], if_else_escaping_greeting
    assert 0x03 in if_else_escaping_greeting["code"], if_else_escaping_greeting
    assert 0x04 in if_else_escaping_greeting["code"], if_else_escaping_greeting
    assert any(
        constant.get("type") == "String" and constant.get("value", "").endswith("::ifElseEscapingGreeting.<closure0>();captures:2")
        for constant in if_else_escaping_greeting["constants"]
    ), if_else_escaping_greeting
    if_else_escaping_closure = next(item for item in module["functions"] if item["name"].endswith("::ifElseEscapingGreeting.<closure0>()"))
    assert if_else_escaping_closure["param_count"] == 3, if_else_escaping_closure
    assert 0x31 in if_else_escaping_closure["code"], if_else_escaping_closure
    assert 0x30 in if_else_escaping_closure["code"], if_else_escaping_closure
    assert 0x42 in if_else_escaping_closure["code"], if_else_escaping_closure
    for value in [" enabled", " disabled"]:
        assert any(
            constant.get("type") == "String" and constant.get("value") == value
            for constant in if_else_escaping_closure["constants"]
        ), if_else_escaping_closure
    body_local_if_else_escaping_greeting = next(item for item in module["functions"] if item["name"].endswith("::bodyLocalIfElseEscapingGreeting"))
    assert body_local_if_else_escaping_greeting["param_count"] == 1, body_local_if_else_escaping_greeting
    assert 0x54 in body_local_if_else_escaping_greeting["code"], body_local_if_else_escaping_greeting
    assert 0x03 in body_local_if_else_escaping_greeting["code"], body_local_if_else_escaping_greeting
    assert 0x04 in body_local_if_else_escaping_greeting["code"], body_local_if_else_escaping_greeting
    assert any(
        constant.get("type") == "String" and constant.get("value", "").endswith("::bodyLocalIfElseEscapingGreeting.<closure0>();captures:2")
        for constant in body_local_if_else_escaping_greeting["constants"]
    ), body_local_if_else_escaping_greeting
    body_local_if_else_escaping_closure = next(item for item in module["functions"] if item["name"].endswith("::bodyLocalIfElseEscapingGreeting.<closure0>()"))
    assert body_local_if_else_escaping_closure["param_count"] == 3, body_local_if_else_escaping_closure
    assert 0x31 in body_local_if_else_escaping_closure["code"], body_local_if_else_escaping_closure
    assert 0x30 in body_local_if_else_escaping_closure["code"], body_local_if_else_escaping_closure
    assert 0x42 in body_local_if_else_escaping_closure["code"], body_local_if_else_escaping_closure
    assert 0x03 in body_local_if_else_escaping_closure["code"], body_local_if_else_escaping_closure
    assert 0x04 in body_local_if_else_escaping_closure["code"], body_local_if_else_escaping_closure
    for value in ["body", " enabled", " disabled"]:
        assert any(
            constant.get("type") == "String" and constant.get("value") == value
            for constant in body_local_if_else_escaping_closure["constants"]
        ), body_local_if_else_escaping_closure
    branch_local_if_else_escaping_greeting = next(item for item in module["functions"] if item["name"].endswith("::branchLocalIfElseEscapingGreeting"))
    assert branch_local_if_else_escaping_greeting["param_count"] == 1, branch_local_if_else_escaping_greeting
    assert 0x54 in branch_local_if_else_escaping_greeting["code"], branch_local_if_else_escaping_greeting
    assert 0x03 in branch_local_if_else_escaping_greeting["code"], branch_local_if_else_escaping_greeting
    assert 0x04 in branch_local_if_else_escaping_greeting["code"], branch_local_if_else_escaping_greeting
    assert any(
        constant.get("type") == "String" and constant.get("value", "").endswith("::branchLocalIfElseEscapingGreeting.<closure0>();captures:2")
        for constant in branch_local_if_else_escaping_greeting["constants"]
    ), branch_local_if_else_escaping_greeting
    branch_local_if_else_escaping_closure = next(item for item in module["functions"] if item["name"].endswith("::branchLocalIfElseEscapingGreeting.<closure0>()"))
    assert branch_local_if_else_escaping_closure["param_count"] == 3, branch_local_if_else_escaping_closure
    assert 0x31 in branch_local_if_else_escaping_closure["code"], branch_local_if_else_escaping_closure
    assert 0x30 in branch_local_if_else_escaping_closure["code"], branch_local_if_else_escaping_closure
    assert 0x42 in branch_local_if_else_escaping_closure["code"], branch_local_if_else_escaping_closure
    assert branch_local_if_else_escaping_closure["code"].count(0x03) >= 2, branch_local_if_else_escaping_closure
    assert branch_local_if_else_escaping_closure["code"].count(0x04) >= 2, branch_local_if_else_escaping_closure
    for value in ["branch-enabled", "branch-disabled"]:
        assert any(
            constant.get("type") == "String" and constant.get("value") == value
            for constant in branch_local_if_else_escaping_closure["constants"]
        ), branch_local_if_else_escaping_closure
    top_level_tear_off = next(item for item in module["functions"] if item["name"].endswith("::topLevelTearOff"))
    assert top_level_tear_off["param_count"] == 0, top_level_tear_off
    assert 0x54 in top_level_tear_off["code"], top_level_tear_off
    assert any(
        constant.get("type") == "String" and constant.get("value") == "package:fcb_kernel_compile_test/main.dart::stableTearOffLabel"
        for constant in top_level_tear_off["constants"]
    ), top_level_tear_off
    recover_from_throw = next(item for item in module["functions"] if item["name"].endswith("::recoverFromThrow"))
    assert recover_from_throw["param_count"] == 1, recover_from_throw
    assert 0x61 in recover_from_throw["code"], recover_from_throw
    assert 0x60 in recover_from_throw["code"], recover_from_throw
    assert 0x31 in recover_from_throw["code"], recover_from_throw
    assert 0x30 in recover_from_throw["code"], recover_from_throw
    assert 0x03 in recover_from_throw["code"], recover_from_throw
    assert 0x04 in recover_from_throw["code"], recover_from_throw
    assert any(
        constant.get("type") == "String" and constant.get("value") == "patched-boom"
        for constant in recover_from_throw["constants"]
    ), recover_from_throw
    assert any(
        constant.get("type") == "String" and constant.get("value") == "patched-caught "
        for constant in recover_from_throw["constants"]
    ), recover_from_throw
    always_throw = next(item for item in module["functions"] if item["name"].endswith("::alwaysThrow"))
    assert always_throw["param_count"] == 0, always_throw
    assert 0x60 in always_throw["code"], always_throw
    assert any(
        constant.get("type") == "String" and constant.get("value") == "patched-boom"
        for constant in always_throw["constants"]
    ), always_throw
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
    labels = next(item for item in module["functions"] if item["name"].endswith("::labels"))
    assert labels["param_count"] == 2, labels
    assert 0x41 in labels["code"], labels
    assert 0x31 in labels["code"], labels
    assert 0x30 in labels["code"], labels
    assert labels["code"].count(0x31) >= 2, labels
    assert any(
        constant.get("type") == "String" and constant.get("value") == "mode"
        for constant in labels["constants"]
    ), labels
    assert any(
        constant.get("type") == "String" and constant.get("value") == "tail"
        for constant in labels["constants"]
    ), labels
    assert any(
        constant.get("type") == "String" and constant.get("value") == "spread"
        for constant in labels["constants"]
    ), labels
    assert any(
        constant.get("type") == "String" and constant.get("value") == "yes"
        for constant in labels["constants"]
    ), labels
    assert any(
        constant.get("type") == "String" and constant.get("value") == "for"
        for constant in labels["constants"]
    ), labels
    assert any(
        constant.get("type") == "String" and constant.get("value") == "off"
        for constant in labels["constants"]
    ), labels
    assert any(
        constant.get("type") == "String" and constant.get("value") == "tier"
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
