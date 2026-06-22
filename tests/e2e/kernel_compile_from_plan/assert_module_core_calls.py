from assert_module_callback_calls import assert_callback_calls
from assert_module_collection_calls import assert_collection_calls
from assert_module_object_calls import assert_object_calls


def assert_constant(function, type_name, value):
    assert any(
        constant.get("type") == type_name and constant.get("value") == value
        for constant in function["constants"]
    ), function


def assert_string_constant(function, value):
    assert_constant(function, "String", value)


def assert_int_constant(function, value):
    assert_constant(function, "Int", value)


def assert_bool_constant(function, value):
    assert_constant(function, "Bool", value)


def assert_null_constant(function):
    assert_constant(function, "Null", None)


def assert_core_calls(module):
    label = next(item for item in module["functions"] if item["name"].endswith("::label"))
    assert label["param_count"] == 1, label
    assert 0x42 in label["code"], label
    assert_string_constant(label, "hello ")
    assert_string_constant(label, "!")
    sync_try_finally = next(item for item in module["functions"] if item["name"].endswith("::syncTryFinallyTail"))
    assert sync_try_finally["async_kind"] == "sync", sync_try_finally
    assert sync_try_finally["param_count"] == 1, sync_try_finally
    assert 0x65 in sync_try_finally["code"], sync_try_finally
    assert 0x66 in sync_try_finally["code"], sync_try_finally
    assert sync_try_finally["code"].count(0x04) >= 2, sync_try_finally
    assert sync_try_finally["code"].count(0x05) >= 2, sync_try_finally
    assert 0x42 in sync_try_finally["code"], sync_try_finally
    assert 0x03 in sync_try_finally["code"], sync_try_finally
    assert {"slot": 0, "name": "name"} in sync_try_finally.get("debug_locals", []), sync_try_finally
    assert any(entry.get("name") == "out" for entry in sync_try_finally.get("debug_locals", [])), sync_try_finally
    assert_string_constant(sync_try_finally, "patched-sync-finally")
    assert_string_constant(sync_try_finally, "-body-")
    assert_string_constant(sync_try_finally, "-cleanup")
    sync_try_catch = next(item for item in module["functions"] if item["name"].endswith("::syncTryCatchTail"))
    assert sync_try_catch["async_kind"] == "sync", sync_try_catch
    assert sync_try_catch["param_count"] == 1, sync_try_catch
    assert 0x61 in sync_try_catch["code"], sync_try_catch
    assert sync_try_catch["code"].count(0x04) >= 2, sync_try_catch
    assert sync_try_catch["code"].count(0x03) >= 2, sync_try_catch
    assert 0x42 in sync_try_catch["code"], sync_try_catch
    assert 0x05 in sync_try_catch["code"], sync_try_catch
    assert {"slot": 0, "name": "name"} in sync_try_catch.get("debug_locals", []), sync_try_catch
    assert any(entry.get("name") == "out" for entry in sync_try_catch.get("debug_locals", [])), sync_try_catch
    assert_string_constant(sync_try_catch, "patched-sync-catch")
    assert_string_constant(sync_try_catch, "-ok-")
    assert_string_constant(sync_try_catch, "-caught-")
    sync_try_catch_local_statement = next(
        item for item in module["functions"] if item["name"].endswith("::syncTryCatchLocalStatementTail")
    )
    assert sync_try_catch_local_statement["async_kind"] == "sync", sync_try_catch_local_statement
    assert sync_try_catch_local_statement["param_count"] == 1, sync_try_catch_local_statement
    assert 0x61 in sync_try_catch_local_statement["code"], sync_try_catch_local_statement
    assert sync_try_catch_local_statement["code"].count(0x04) >= 2, sync_try_catch_local_statement
    assert sync_try_catch_local_statement["code"].count(0x03) >= 2, sync_try_catch_local_statement
    assert 0x42 in sync_try_catch_local_statement["code"], sync_try_catch_local_statement
    sync_try_catch_local_statement_names = {
        entry.get("name") for entry in sync_try_catch_local_statement.get("debug_locals", [])
    }
    assert {"name", "out", "message"}.issubset(
        sync_try_catch_local_statement_names,
    ), sync_try_catch_local_statement
    assert_string_constant(sync_try_catch_local_statement, "patched-sync-catch-local-statement")
    assert_string_constant(sync_try_catch_local_statement, "patched-sync-catch-local-message-")
    sync_try_catch_body_local = next(
        item for item in module["functions"] if item["name"].endswith("::syncTryCatchBodyLocalStatementTail")
    )
    assert sync_try_catch_body_local["async_kind"] == "sync", sync_try_catch_body_local
    assert sync_try_catch_body_local["param_count"] == 1, sync_try_catch_body_local
    assert 0x61 in sync_try_catch_body_local["code"], sync_try_catch_body_local
    assert sync_try_catch_body_local["code"].count(0x04) >= 2, sync_try_catch_body_local
    assert sync_try_catch_body_local["code"].count(0x03) >= 2, sync_try_catch_body_local
    assert 0x42 in sync_try_catch_body_local["code"], sync_try_catch_body_local
    sync_try_catch_body_local_names = {
        entry.get("name") for entry in sync_try_catch_body_local.get("debug_locals", [])
    }
    assert {"name", "out", "message"}.issubset(sync_try_catch_body_local_names), sync_try_catch_body_local
    assert_string_constant(sync_try_catch_body_local, "patched-sync-catch-body-local-statement")
    assert_string_constant(sync_try_catch_body_local, "patched-sync-catch-body-local-message-")
    assert_string_constant(sync_try_catch_body_local, "patched-sync-catch-body-local-caught-")
    sync_try_catch_return = next(
        item for item in module["functions"] if item["name"].endswith("::syncTryCatchReturnValue")
    )
    assert sync_try_catch_return["async_kind"] == "sync", sync_try_catch_return
    assert sync_try_catch_return["param_count"] == 1, sync_try_catch_return
    assert 0x61 in sync_try_catch_return["code"], sync_try_catch_return
    assert 0x42 in sync_try_catch_return["code"], sync_try_catch_return
    assert 0x03 in sync_try_catch_return["code"], sync_try_catch_return
    assert {"slot": 0, "name": "name"} in sync_try_catch_return.get(
        "debug_locals",
        [],
    ), sync_try_catch_return
    assert_string_constant(sync_try_catch_return, "patched-catch-return-")
    assert_string_constant(sync_try_catch_return, "patched-caught-return-")
    sync_try_catch_local_return = next(
        item for item in module["functions"] if item["name"].endswith("::syncTryCatchLocalReturnValue")
    )
    assert sync_try_catch_local_return["async_kind"] == "sync", sync_try_catch_local_return
    assert sync_try_catch_local_return["param_count"] == 1, sync_try_catch_local_return
    assert 0x61 in sync_try_catch_local_return["code"], sync_try_catch_local_return
    assert sync_try_catch_local_return["code"].count(0x04) >= 1, sync_try_catch_local_return
    assert sync_try_catch_local_return["code"].count(0x03) >= 2, sync_try_catch_local_return
    assert 0x42 in sync_try_catch_local_return["code"], sync_try_catch_local_return
    sync_try_catch_local_return_names = {
        entry.get("name") for entry in sync_try_catch_local_return.get("debug_locals", [])
    }
    assert {"name", "message"}.issubset(sync_try_catch_local_return_names), sync_try_catch_local_return
    assert_string_constant(sync_try_catch_local_return, "patched-catch-local-return-")
    assert_string_constant(sync_try_catch_local_return, "patched-catch-local-caught-")
    sync_try_catch_finally_return = next(
        item for item in module["functions"] if item["name"].endswith("::syncTryCatchFinallyReturnValue")
    )
    assert sync_try_catch_finally_return["async_kind"] == "sync", sync_try_catch_finally_return
    assert sync_try_catch_finally_return["param_count"] == 1, sync_try_catch_finally_return
    assert 0x65 in sync_try_catch_finally_return["code"], sync_try_catch_finally_return
    assert 0x66 in sync_try_catch_finally_return["code"], sync_try_catch_finally_return
    assert 0x61 in sync_try_catch_finally_return["code"], sync_try_catch_finally_return
    assert 0x04 in sync_try_catch_finally_return["code"], sync_try_catch_finally_return
    assert 0x03 in sync_try_catch_finally_return["code"], sync_try_catch_finally_return
    assert 0x42 in sync_try_catch_finally_return["code"], sync_try_catch_finally_return
    assert 0x50 in sync_try_catch_finally_return["code"], sync_try_catch_finally_return
    assert {"slot": 0, "name": "name"} in sync_try_catch_finally_return.get(
        "debug_locals",
        [],
    ), sync_try_catch_finally_return
    assert_string_constant(sync_try_catch_finally_return, "patched-catch-finally-return-")
    assert_string_constant(sync_try_catch_finally_return, "patched-catch-finally-caught-")
    assert_string_constant(sync_try_catch_finally_return, "patched-catch-finally-cleanup-")
    sync_try_catch_statement = next(
        item for item in module["functions"] if item["name"].endswith("::syncTryCatchStatementTail")
    )
    assert sync_try_catch_statement["async_kind"] == "sync", sync_try_catch_statement
    assert sync_try_catch_statement["param_count"] == 1, sync_try_catch_statement
    assert 0x61 in sync_try_catch_statement["code"], sync_try_catch_statement
    assert sync_try_catch_statement["code"].count(0x50) == 2, sync_try_catch_statement
    assert 0x42 in sync_try_catch_statement["code"], sync_try_catch_statement
    assert 0x05 in sync_try_catch_statement["code"], sync_try_catch_statement
    assert {"slot": 0, "name": "name"} in sync_try_catch_statement.get("debug_locals", []), sync_try_catch_statement
    assert_string_constant(
        sync_try_catch_statement,
        "package:fcb_kernel_compile_test/main.dart::label",
    )
    assert_string_constant(sync_try_catch_statement, "patched-sync-catch-statement-")
    sync_try_catch_void = next(
        item for item in module["functions"] if item["name"].endswith("::syncTryCatchStatementVoid")
    )
    assert sync_try_catch_void["async_kind"] == "sync", sync_try_catch_void
    assert sync_try_catch_void["param_count"] == 1, sync_try_catch_void
    assert 0x61 in sync_try_catch_void["code"], sync_try_catch_void
    assert sync_try_catch_void["code"].count(0x50) == 2, sync_try_catch_void
    assert 0x42 in sync_try_catch_void["code"], sync_try_catch_void
    assert 0x05 in sync_try_catch_void["code"], sync_try_catch_void
    assert {"slot": 0, "name": "name"} in sync_try_catch_void.get("debug_locals", []), sync_try_catch_void
    assert_string_constant(
        sync_try_catch_void,
        "package:fcb_kernel_compile_test/main.dart::label",
    )
    assert_string_constant(sync_try_catch_void, "patched-catch-void-")
    assert_null_constant(sync_try_catch_void)
    sync_try_finally_statement = next(
        item for item in module["functions"] if item["name"].endswith("::syncTryFinallyStatementTail")
    )
    assert sync_try_finally_statement["async_kind"] == "sync", sync_try_finally_statement
    assert sync_try_finally_statement["param_count"] == 1, sync_try_finally_statement
    assert 0x65 in sync_try_finally_statement["code"], sync_try_finally_statement
    assert 0x66 in sync_try_finally_statement["code"], sync_try_finally_statement
    assert sync_try_finally_statement["code"].count(0x50) == 2, sync_try_finally_statement
    assert 0x42 in sync_try_finally_statement["code"], sync_try_finally_statement
    assert sync_try_finally_statement["code"].count(0x05) >= 2, sync_try_finally_statement
    assert {"slot": 0, "name": "name"} in sync_try_finally_statement.get(
        "debug_locals",
        [],
    ), sync_try_finally_statement
    assert_string_constant(
        sync_try_finally_statement,
        "package:fcb_kernel_compile_test/main.dart::label",
    )
    assert_string_constant(sync_try_finally_statement, "patched-cleanup-")
    assert_string_constant(sync_try_finally_statement, "patched-sync-finally-statement-")
    sync_try_finally_local_statement = next(
        item for item in module["functions"] if item["name"].endswith("::syncTryFinallyLocalStatementTail")
    )
    assert sync_try_finally_local_statement["async_kind"] == "sync", sync_try_finally_local_statement
    assert sync_try_finally_local_statement["param_count"] == 1, sync_try_finally_local_statement
    assert 0x65 in sync_try_finally_local_statement["code"], sync_try_finally_local_statement
    assert 0x66 in sync_try_finally_local_statement["code"], sync_try_finally_local_statement
    assert sync_try_finally_local_statement["code"].count(0x50) == 2, sync_try_finally_local_statement
    assert 0x04 in sync_try_finally_local_statement["code"], sync_try_finally_local_statement
    assert 0x03 in sync_try_finally_local_statement["code"], sync_try_finally_local_statement
    sync_try_finally_local_names = {
        entry.get("name") for entry in sync_try_finally_local_statement.get("debug_locals", [])
    }
    assert {"name", "cleanup"}.issubset(sync_try_finally_local_names), sync_try_finally_local_statement
    assert_string_constant(sync_try_finally_local_statement, "patched-cleanup-local-")
    assert_string_constant(sync_try_finally_local_statement, "patched-sync-finally-local-statement-")
    sync_try_finally_body_local = next(
        item for item in module["functions"] if item["name"].endswith("::syncTryFinallyBodyLocalStatementTail")
    )
    assert sync_try_finally_body_local["async_kind"] == "sync", sync_try_finally_body_local
    assert sync_try_finally_body_local["param_count"] == 1, sync_try_finally_body_local
    assert 0x65 in sync_try_finally_body_local["code"], sync_try_finally_body_local
    assert 0x66 in sync_try_finally_body_local["code"], sync_try_finally_body_local
    assert sync_try_finally_body_local["code"].count(0x50) == 2, sync_try_finally_body_local
    assert 0x04 in sync_try_finally_body_local["code"], sync_try_finally_body_local
    assert 0x03 in sync_try_finally_body_local["code"], sync_try_finally_body_local
    sync_try_finally_body_local_names = {
        entry.get("name") for entry in sync_try_finally_body_local.get("debug_locals", [])
    }
    assert {"name", "message"}.issubset(sync_try_finally_body_local_names), sync_try_finally_body_local
    assert_string_constant(sync_try_finally_body_local, "patched-finally-body-local-")
    assert_string_constant(sync_try_finally_body_local, "patched-finally-body-cleanup-")
    assert_string_constant(sync_try_finally_body_local, "patched-sync-finally-body-local-statement-")
    sync_try_finally_void = next(
        item for item in module["functions"] if item["name"].endswith("::syncTryFinallyStatementVoid")
    )
    assert sync_try_finally_void["async_kind"] == "sync", sync_try_finally_void
    assert sync_try_finally_void["param_count"] == 1, sync_try_finally_void
    assert 0x65 in sync_try_finally_void["code"], sync_try_finally_void
    assert 0x66 in sync_try_finally_void["code"], sync_try_finally_void
    assert sync_try_finally_void["code"].count(0x50) == 2, sync_try_finally_void
    assert 0x42 in sync_try_finally_void["code"], sync_try_finally_void
    assert sync_try_finally_void["code"].count(0x05) >= 2, sync_try_finally_void
    assert {"slot": 0, "name": "name"} in sync_try_finally_void.get("debug_locals", []), sync_try_finally_void
    assert_string_constant(
        sync_try_finally_void,
        "package:fcb_kernel_compile_test/main.dart::label",
    )
    assert_string_constant(sync_try_finally_void, "patched-void-cleanup-")
    assert_null_constant(sync_try_finally_void)
    sync_try_finally_return = next(
        item for item in module["functions"] if item["name"].endswith("::syncTryFinallyReturnValue")
    )
    assert sync_try_finally_return["async_kind"] == "sync", sync_try_finally_return
    assert sync_try_finally_return["param_count"] == 1, sync_try_finally_return
    assert 0x65 in sync_try_finally_return["code"], sync_try_finally_return
    assert 0x66 in sync_try_finally_return["code"], sync_try_finally_return
    assert 0x04 in sync_try_finally_return["code"], sync_try_finally_return
    assert 0x03 in sync_try_finally_return["code"], sync_try_finally_return
    assert 0x42 in sync_try_finally_return["code"], sync_try_finally_return
    assert 0x50 in sync_try_finally_return["code"], sync_try_finally_return
    assert {"slot": 0, "name": "name"} in sync_try_finally_return.get(
        "debug_locals",
        [],
    ), sync_try_finally_return
    assert_string_constant(sync_try_finally_return, "patched-finally-return-")
    assert_string_constant(sync_try_finally_return, "patched-return-cleanup-")
    assert_string_constant(
        sync_try_finally_return,
        "package:fcb_kernel_compile_test/main.dart::label",
    )
    sync_if_side_effect = next(
        item for item in module["functions"] if item["name"].endswith("::syncIfSideEffectTail")
    )
    assert sync_if_side_effect["async_kind"] == "sync", sync_if_side_effect
    assert sync_if_side_effect["param_count"] == 2, sync_if_side_effect
    assert 0x31 in sync_if_side_effect["code"], sync_if_side_effect
    assert 0x50 in sync_if_side_effect["code"], sync_if_side_effect
    assert 0x42 in sync_if_side_effect["code"], sync_if_side_effect
    assert {"slot": 0, "name": "enabled"} in sync_if_side_effect.get(
        "debug_locals",
        [],
    ), sync_if_side_effect
    assert {"slot": 1, "name": "name"} in sync_if_side_effect.get(
        "debug_locals",
        [],
    ), sync_if_side_effect
    assert_string_constant(sync_if_side_effect, "patched-if-side-effect-")
    assert_string_constant(sync_if_side_effect, "patched-if-tail-")
    sync_ifelse_side_effect = next(
        item for item in module["functions"] if item["name"].endswith("::syncIfElseSideEffectTail")
    )
    assert sync_ifelse_side_effect["async_kind"] == "sync", sync_ifelse_side_effect
    assert sync_ifelse_side_effect["param_count"] == 2, sync_ifelse_side_effect
    assert 0x31 in sync_ifelse_side_effect["code"], sync_ifelse_side_effect
    assert sync_ifelse_side_effect["code"].count(0x50) == 2, sync_ifelse_side_effect
    assert 0x42 in sync_ifelse_side_effect["code"], sync_ifelse_side_effect
    assert {"slot": 0, "name": "enabled"} in sync_ifelse_side_effect.get(
        "debug_locals",
        [],
    ), sync_ifelse_side_effect
    assert {"slot": 1, "name": "name"} in sync_ifelse_side_effect.get(
        "debug_locals",
        [],
    ), sync_ifelse_side_effect
    assert_string_constant(sync_ifelse_side_effect, "patched-ifelse-side-effect-on-")
    assert_string_constant(sync_ifelse_side_effect, "patched-ifelse-side-effect-off-")
    assert_string_constant(sync_ifelse_side_effect, "patched-ifelse-tail-")
    sync_ifelse_local = next(
        item for item in module["functions"] if item["name"].endswith("::syncIfElseLocalSideEffectTail")
    )
    assert sync_ifelse_local["async_kind"] == "sync", sync_ifelse_local
    assert sync_ifelse_local["param_count"] == 2, sync_ifelse_local
    assert 0x31 in sync_ifelse_local["code"], sync_ifelse_local
    assert sync_ifelse_local["code"].count(0x50) == 2, sync_ifelse_local
    assert sync_ifelse_local["code"].count(0x04) >= 2, sync_ifelse_local
    assert sync_ifelse_local["code"].count(0x03) >= 2, sync_ifelse_local
    sync_ifelse_local_names = {
        entry.get("name") for entry in sync_ifelse_local.get("debug_locals", [])
    }
    assert {"enabled", "name", "message"}.issubset(sync_ifelse_local_names), sync_ifelse_local
    assert_string_constant(sync_ifelse_local, "patched-ifelse-local-on-")
    assert_string_constant(sync_ifelse_local, "patched-ifelse-local-off-")
    assert_string_constant(sync_ifelse_local, "patched-ifelse-local-tail-")
    display = next(item for item in module["functions"] if item["name"].endswith("::displayName"))
    assert display["param_count"] == 1, display
    assert 0x43 in display["code"], display
    assert_string_constant(display, "label")
    async_display = next(item for item in module["functions"] if item["name"].endswith("::asyncDisplayName"))
    assert async_display["async_kind"] == "async_future", async_display
    assert async_display["param_count"] == 1, async_display
    assert 0x43 in async_display["code"], async_display
    assert_string_constant(async_display, "label")
    async_await_field = next(item for item in module["functions"] if item["name"].endswith("::asyncAwaitThenReadField"))
    assert async_await_field["async_kind"] == "async_future", async_await_field
    assert async_await_field["param_count"] == 2, async_await_field
    assert 0x62 in async_await_field["code"], async_await_field
    assert 0x03 in async_await_field["code"], async_await_field
    assert 0x43 in async_await_field["code"], async_await_field
    assert 0x42 in async_await_field["code"], async_await_field
    assert 0x55 in async_await_field["code"], async_await_field
    assert 0x63 in async_await_field["code"], async_await_field
    assert_string_constant(async_await_field, "patched-await-field:")
    assert_string_constant(async_await_field, "label")
    is_known = next(item for item in module["functions"] if item["name"].endswith("::isKnown"))
    assert is_known["param_count"] == 1, is_known
    assert 0x45 in is_known["code"], is_known
    assert_string_constant(is_known, "String")
    is_user = next(item for item in module["functions"] if item["name"].endswith("::isUser"))
    assert is_user["param_count"] == 1, is_user
    assert 0x45 in is_user["code"], is_user
    assert_string_constant(is_user, "package:fcb_kernel_compile_test/main.dart::User")
    is_string_list = next(item for item in module["functions"] if item["name"].endswith("::isStringList"))
    assert is_string_list["param_count"] == 1, is_string_list
    assert 0x45 in is_string_list["code"], is_string_list
    assert_string_constant(is_string_list, "List<String>")
    as_string_list = next(item for item in module["functions"] if item["name"].endswith("::asStringList"))
    assert as_string_list["param_count"] == 1, as_string_list
    assert 0x46 in as_string_list["code"], as_string_list
    assert_string_constant(as_string_list, "List<String>")
    async_is_string_list = next(item for item in module["functions"] if item["name"].endswith("::asyncIsStringList"))
    assert async_is_string_list["async_kind"] == "async_future", async_is_string_list
    assert async_is_string_list["param_count"] == 1, async_is_string_list
    assert 0x45 in async_is_string_list["code"], async_is_string_list
    assert 0x63 in async_is_string_list["code"], async_is_string_list
    assert_string_constant(async_is_string_list, "List<String>")
    async_as_string_list = next(item for item in module["functions"] if item["name"].endswith("::asyncAsStringList"))
    assert async_as_string_list["async_kind"] == "async_future", async_as_string_list
    assert async_as_string_list["param_count"] == 1, async_as_string_list
    assert 0x46 in async_as_string_list["code"], async_as_string_list
    assert 0x63 in async_as_string_list["code"], async_as_string_list
    assert_string_constant(async_as_string_list, "List<String>")
    async_arithmetic_value = next(item for item in module["functions"] if item["name"].endswith("::asyncArithmeticValue"))
    assert async_arithmetic_value["async_kind"] == "async_future", async_arithmetic_value
    assert async_arithmetic_value["param_count"] == 1, async_arithmetic_value
    assert 0x02 in async_arithmetic_value["code"], async_arithmetic_value
    assert 0x01 in async_arithmetic_value["code"], async_arithmetic_value
    assert 0x10 in async_arithmetic_value["code"], async_arithmetic_value
    assert 0x55 in async_arithmetic_value["code"], async_arithmetic_value
    assert 0x63 in async_arithmetic_value["code"], async_arithmetic_value
    assert_int_constant(async_arithmetic_value, 2)
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
    assert_int_constant(async_await_arithmetic, 5)
    async_subtract_value = next(item for item in module["functions"] if item["name"].endswith("::asyncSubtractValue"))
    assert async_subtract_value["async_kind"] == "async_future", async_subtract_value
    assert async_subtract_value["param_count"] == 1, async_subtract_value
    assert 0x02 in async_subtract_value["code"], async_subtract_value
    assert 0x01 in async_subtract_value["code"], async_subtract_value
    assert 0x11 in async_subtract_value["code"], async_subtract_value
    assert 0x55 in async_subtract_value["code"], async_subtract_value
    assert 0x63 in async_subtract_value["code"], async_subtract_value
    assert_int_constant(async_subtract_value, 3)
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
    assert_int_constant(async_await_subtract, 7)
    async_multiply_value = next(item for item in module["functions"] if item["name"].endswith("::asyncMultiplyValue"))
    assert async_multiply_value["async_kind"] == "async_future", async_multiply_value
    assert async_multiply_value["param_count"] == 1, async_multiply_value
    assert 0x02 in async_multiply_value["code"], async_multiply_value
    assert 0x01 in async_multiply_value["code"], async_multiply_value
    assert 0x12 in async_multiply_value["code"], async_multiply_value
    assert 0x55 in async_multiply_value["code"], async_multiply_value
    assert 0x63 in async_multiply_value["code"], async_multiply_value
    assert_int_constant(async_multiply_value, 3)
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
    assert_int_constant(async_await_multiply, 9)
    async_divide_value = next(item for item in module["functions"] if item["name"].endswith("::asyncDivideValue"))
    assert async_divide_value["async_kind"] == "async_future", async_divide_value
    assert async_divide_value["param_count"] == 1, async_divide_value
    assert 0x02 in async_divide_value["code"], async_divide_value
    assert 0x01 in async_divide_value["code"], async_divide_value
    assert 0x13 in async_divide_value["code"], async_divide_value
    assert 0x55 in async_divide_value["code"], async_divide_value
    assert 0x63 in async_divide_value["code"], async_divide_value
    assert_int_constant(async_divide_value, 4)
    async_await_divide = next(
        item for item in module["functions"] if item["name"].endswith("::asyncAwaitThenDivideValue")
    )
    assert async_await_divide["async_kind"] == "async_future", async_await_divide
    assert async_await_divide["param_count"] == 1, async_await_divide
    assert 0x62 in async_await_divide["code"], async_await_divide
    assert 0x03 in async_await_divide["code"], async_await_divide
    assert 0x13 in async_await_divide["code"], async_await_divide
    assert 0x55 in async_await_divide["code"], async_await_divide
    assert 0x63 in async_await_divide["code"], async_await_divide
    assert_int_constant(async_await_divide, 11)
    async_logical_flag = next(item for item in module["functions"] if item["name"].endswith("::asyncLogicalFlag"))
    assert async_logical_flag["async_kind"] == "async_future", async_logical_flag
    assert async_logical_flag["param_count"] == 2, async_logical_flag
    assert async_logical_flag["code"].count(0x02) >= 3, async_logical_flag
    assert async_logical_flag["code"].count(0x31) >= 3, async_logical_flag
    assert 0x30 in async_logical_flag["code"], async_logical_flag
    assert 0x55 in async_logical_flag["code"], async_logical_flag
    assert 0x63 in async_logical_flag["code"], async_logical_flag
    assert_bool_constant(async_logical_flag, True)
    assert_bool_constant(async_logical_flag, False)
    async_await_logical = next(
        item for item in module["functions"] if item["name"].endswith("::asyncAwaitThenLogicalFlag")
    )
    assert async_await_logical["async_kind"] == "async_future", async_await_logical
    assert async_await_logical["param_count"] == 2, async_await_logical
    assert 0x62 in async_await_logical["code"], async_await_logical
    assert 0x03 in async_await_logical["code"], async_await_logical
    assert async_await_logical["code"].count(0x31) >= 3, async_await_logical
    assert 0x30 in async_await_logical["code"], async_await_logical
    assert 0x55 in async_await_logical["code"], async_await_logical
    assert 0x63 in async_await_logical["code"], async_await_logical
    assert_bool_constant(async_await_logical, True)
    assert_bool_constant(async_await_logical, False)
    async_always_throw = next(item for item in module["functions"] if item["name"].endswith("::asyncAlwaysThrow"))
    assert async_always_throw["async_kind"] == "async_future", async_always_throw
    assert async_always_throw["param_count"] == 0, async_always_throw
    assert 0x60 in async_always_throw["code"], async_always_throw
    assert 0x55 in async_always_throw["code"], async_always_throw
    assert 0x63 in async_always_throw["code"], async_always_throw
    assert_string_constant(async_always_throw, "patched-async-boom")
    async_await_throw = next(
        item for item in module["functions"] if item["name"].endswith("::asyncAwaitThenAlwaysThrow")
    )
    assert async_await_throw["async_kind"] == "async_future", async_await_throw
    assert async_await_throw["param_count"] == 1, async_await_throw
    assert 0x62 in async_await_throw["code"], async_await_throw
    assert 0x03 in async_await_throw["code"], async_await_throw
    assert 0x42 in async_await_throw["code"], async_await_throw
    assert 0x60 in async_await_throw["code"], async_await_throw
    assert 0x55 in async_await_throw["code"], async_await_throw
    assert 0x63 in async_await_throw["code"], async_await_throw
    assert_string_constant(async_await_throw, "patched-await-throw:")
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
    async_await_static_combine = next(
        item for item in module["functions"] if item["name"].endswith("::asyncAwaitThenStaticCombine")
    )
    assert async_await_static_combine["async_kind"] == "async_future", async_await_static_combine
    assert async_await_static_combine["param_count"] == 2, async_await_static_combine
    assert 0x62 in async_await_static_combine["code"], async_await_static_combine
    assert 0x03 in async_await_static_combine["code"], async_await_static_combine
    assert 0x50 in async_await_static_combine["code"], async_await_static_combine
    assert 0x55 in async_await_static_combine["code"], async_await_static_combine
    assert 0x63 in async_await_static_combine["code"], async_await_static_combine
    assert any(
        constant.get("type") == "String" and constant.get("value", "").endswith("::combine")
        for constant in async_await_static_combine["constants"]
    ), async_await_static_combine
    async_concat_label = next(item for item in module["functions"] if item["name"].endswith("::asyncConcatLabel"))
    assert async_concat_label["async_kind"] == "async_future", async_concat_label
    assert async_concat_label["param_count"] == 1, async_concat_label
    assert 0x02 in async_concat_label["code"], async_concat_label
    assert 0x42 in async_concat_label["code"], async_concat_label
    assert 0x55 in async_concat_label["code"], async_concat_label
    assert 0x63 in async_concat_label["code"], async_concat_label
    assert_string_constant(async_concat_label, "patched-async ")
    async_await_concat = next(
        item for item in module["functions"] if item["name"].endswith("::asyncAwaitThenConcatLabel")
    )
    assert async_await_concat["async_kind"] == "async_future", async_await_concat
    assert async_await_concat["param_count"] == 1, async_await_concat
    assert 0x62 in async_await_concat["code"], async_await_concat
    assert 0x03 in async_await_concat["code"], async_await_concat
    assert 0x42 in async_await_concat["code"], async_await_concat
    assert 0x55 in async_await_concat["code"], async_await_concat
    assert 0x63 in async_await_concat["code"], async_await_concat
    assert_string_constant(async_await_concat, "patched-await-concat ")
    async_nullable_choice = next(item for item in module["functions"] if item["name"].endswith("::asyncNullableChoice"))
    assert async_nullable_choice["async_kind"] == "async_future", async_nullable_choice
    assert async_nullable_choice["param_count"] == 1, async_nullable_choice
    assert 0x02 in async_nullable_choice["code"], async_nullable_choice
    assert 0x31 in async_nullable_choice["code"], async_nullable_choice
    assert 0x30 in async_nullable_choice["code"], async_nullable_choice
    assert 0x55 in async_nullable_choice["code"], async_nullable_choice
    assert 0x63 in async_nullable_choice["code"], async_nullable_choice
    assert_null_constant(async_nullable_choice)
    assert_string_constant(async_nullable_choice, "patched-null")
    async_await_nullable = next(
        item for item in module["functions"] if item["name"].endswith("::asyncAwaitThenNullableChoice")
    )
    assert async_await_nullable["async_kind"] == "async_future", async_await_nullable
    assert async_await_nullable["param_count"] == 1, async_await_nullable
    assert 0x62 in async_await_nullable["code"], async_await_nullable
    assert 0x03 in async_await_nullable["code"], async_await_nullable
    assert 0x31 in async_await_nullable["code"], async_await_nullable
    assert 0x30 in async_await_nullable["code"], async_await_nullable
    assert 0x55 in async_await_nullable["code"], async_await_nullable
    assert 0x63 in async_await_nullable["code"], async_await_nullable
    assert_null_constant(async_await_nullable)
    assert_string_constant(async_await_nullable, "patched-await-null")
    assert_object_calls(module)
    update_config = next(item for item in module["functions"] if item["name"].endswith("::updateConfigLabel"))
    assert update_config["param_count"] == 2, update_config
    assert 0x44 in update_config["code"], update_config
    assert 0x43 in update_config["code"], update_config
    assert 0x05 in update_config["code"], update_config
    assert_string_constant(update_config, "label")
    assert_string_constant(update_config, "-patched")
    dynamic_named_call = next(item for item in module["functions"] if item["name"].endswith("::dynamicNamedCall"))
    assert dynamic_named_call["param_count"] == 0, dynamic_named_call
    assert 0x55 in dynamic_named_call["code"], dynamic_named_call
    assert 0x51 in dynamic_named_call["code"], dynamic_named_call
    assert_string_constant(dynamic_named_call, "package:fcb_kernel_compile_test/main.dart::class:Greeter.")
    assert_string_constant(dynamic_named_call, "surround;named:prefix,suffix")
    for value in ["patched", "<", ">"]:
        assert_string_constant(dynamic_named_call, value)
    async_dynamic_named_call = next(item for item in module["functions"] if item["name"].endswith("::asyncDynamicNamedCall"))
    assert async_dynamic_named_call["async_kind"] == "async_future", async_dynamic_named_call
    assert async_dynamic_named_call["param_count"] == 0, async_dynamic_named_call
    assert 0x55 in async_dynamic_named_call["code"], async_dynamic_named_call
    assert 0x51 in async_dynamic_named_call["code"], async_dynamic_named_call
    assert_string_constant(async_dynamic_named_call, "package:fcb_kernel_compile_test/main.dart::class:Greeter.")
    assert_string_constant(async_dynamic_named_call, "surround;named:prefix,suffix")
    for value in ["patched-async", "<", ">"]:
        assert_string_constant(async_dynamic_named_call, value)
    async_await_dynamic_call = next(item for item in module["functions"] if item["name"].endswith("::asyncAwaitThenDynamicCall"))
    assert async_await_dynamic_call["async_kind"] == "async_future", async_await_dynamic_call
    assert async_await_dynamic_call["param_count"] == 1, async_await_dynamic_call
    assert 0x62 in async_await_dynamic_call["code"], async_await_dynamic_call
    assert 0x03 in async_await_dynamic_call["code"], async_await_dynamic_call
    assert 0x51 in async_await_dynamic_call["code"], async_await_dynamic_call
    assert 0x55 in async_await_dynamic_call["code"], async_await_dynamic_call
    assert 0x63 in async_await_dynamic_call["code"], async_await_dynamic_call
    assert_string_constant(async_await_dynamic_call, "surround;named:prefix,suffix")
    assert_string_constant(async_await_dynamic_call, "patched-await-dynamic<")
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
    assert_callback_calls(module)
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
    assert_collection_calls(module)
