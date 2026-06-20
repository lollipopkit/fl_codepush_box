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
    make_user = next(item for item in module["functions"] if item["name"].endswith("::makeUser"))
    assert make_user["param_count"] == 0, make_user
    assert 0x55 in make_user["code"], make_user
    assert any(
        constant.get("type") == "String" and constant.get("value") == "package:fcb_kernel_compile_test/main.dart::class:User."
        for constant in make_user["constants"]
    ), make_user
    make_config = next(item for item in module["functions"] if item["name"].endswith("::makeConfig"))
    assert make_config["param_count"] == 0, make_config
    assert 0x55 in make_config["code"], make_config
    assert any(
        constant.get("type") == "String" and constant.get("value") == "package:fcb_kernel_compile_test/main.dart::class:Config.;named:name,label"
        for constant in make_config["constants"]
    ), make_config
    make_string_box = next(item for item in module["functions"] if item["name"].endswith("::makeStringBox"))
    assert make_string_box["param_count"] == 0, make_string_box
    assert 0x55 in make_string_box["code"], make_string_box
    assert any(
        constant.get("type") == "String" and constant.get("value") == "package:fcb_kernel_compile_test/main.dart::class:Box.;types:String"
        for constant in make_string_box["constants"]
    ), make_string_box
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
    same_object = next(item for item in module["functions"] if item["name"].endswith("::sameObject"))
    assert same_object["param_count"] == 1, same_object
    assert 0x52 in same_object["code"], same_object
    assert any(
        constant.get("type") == "String" and constant.get("value") == "dart:core::identical"
        for constant in same_object["constants"]
    ), same_object
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
