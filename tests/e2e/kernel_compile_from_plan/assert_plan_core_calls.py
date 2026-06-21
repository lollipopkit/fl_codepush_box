import json
import sys

patch = json.load(open(sys.argv[1]))
patch_by_member = {f.get("member_name"): f for f in patch["functions"]}


def source_for(member):
    function = patch_by_member.get(member)
    if function is None:
        raise SystemExit(f"missing inventory entry for {member}")
    source = function.get("bytecode_source")
    if not isinstance(source, dict):
        raise SystemExit(f"{member} should produce bytecode source: {function}")
    if function.get("unsupported_reasons") != []:
        raise SystemExit(f"{member} should now be supported, got {function}")
    return source


update_config_source = source_for("updateConfigLabel")
update_config_seq = update_config_source.get("body", {}).get("seq", [])
update_config_set = update_config_seq[0].get("set_field", {}) if update_config_seq else {}
update_config_get = update_config_seq[1].get("get_field", {}) if len(update_config_seq) > 1 else {}
if (
    update_config_set.get("receiver", {}).get("arg") != "config"
    or update_config_set.get("field") != "label"
    or update_config_set.get("value", {}).get("concat", [{}, {}])[1].get("string") != "-patched"
    or update_config_get.get("receiver", {}).get("arg") != "config"
    or update_config_get.get("field") != "label"
):
    raise SystemExit(f"expected updateConfigLabel set_field/get_field seq source, got {update_config_source}")

async_update_config_source = source_for("asyncUpdateConfigLabel")
async_update_config_arg = async_update_config_source.get("body", {}).get("new_object", {}).get("args", [{}])[0]
async_update_config_seq = async_update_config_arg.get("seq", [])
async_update_config_set = async_update_config_seq[0].get("set_field", {}) if async_update_config_seq else {}
async_update_config_get = async_update_config_seq[1].get("get_field", {}) if len(async_update_config_seq) > 1 else {}
if (
    async_update_config_source.get("async_future") is not True
    or async_update_config_source.get("body", {}).get("new_object", {}).get("type_args") != ["String"]
    or async_update_config_set.get("receiver", {}).get("arg") != "config"
    or async_update_config_set.get("field") != "label"
    or async_update_config_set.get("value", {}).get("concat", [{}, {}])[1].get("string") != "-async-patched"
    or async_update_config_get.get("receiver", {}).get("arg") != "config"
    or async_update_config_get.get("field") != "label"
):
    raise SystemExit(f"expected asyncUpdateConfigLabel async set_field/get_field seq source, got {async_update_config_source}")

async_await_update_source = source_for("asyncAwaitThenUpdateConfigLabel")
async_await_update_arg = async_await_update_source.get("body", {}).get("new_object", {}).get("args", [{}])[0]
async_await_update_let = async_await_update_arg.get("let", {})
async_await_update_locals = async_await_update_let.get("locals", [])
async_await_update_seq = async_await_update_let.get("body", {}).get("seq", [])
async_await_update_set = async_await_update_seq[0].get("set_field", {}) if async_await_update_seq else {}
async_await_update_get = async_await_update_seq[1].get("get_field", {}) if len(async_await_update_seq) > 1 else {}
async_await_update_concat = async_await_update_set.get("value", {}).get("concat", [])
if (
    async_await_update_source.get("async_future") is not True
    or async_await_update_source.get("body", {}).get("new_object", {}).get("type_args") != ["String"]
    or async_await_update_source.get("params") != ["config", "ready"]
    or len(async_await_update_locals) != 1
    or async_await_update_locals[0].get("name") != "label"
    or async_await_update_locals[0].get("value", {}).get("await", {}).get("arg") != "ready"
    or async_await_update_set.get("receiver", {}).get("arg") != "config"
    or async_await_update_set.get("field") != "label"
    or async_await_update_concat != [{"let_local": 0}, {"string": "-await-patched"}]
    or async_await_update_get.get("receiver", {}).get("arg") != "config"
    or async_await_update_get.get("field") != "label"
):
    raise SystemExit(f"expected asyncAwaitThenUpdateConfigLabel await/set_field/get_field source, got {async_await_update_source}")

async_dynamic_named_source = source_for("asyncDynamicNamedCall")
async_dynamic_named_arg = async_dynamic_named_source.get("body", {}).get("new_object", {}).get("args", [{}])[0]
async_dynamic_call = async_dynamic_named_arg.get("call_dynamic", {})
if (
    async_dynamic_named_source.get("async_future") is not True
    or async_dynamic_named_source.get("body", {}).get("new_object", {}).get("type_args") != ["String"]
    or async_dynamic_call.get("receiver", {}).get("new_object", {}).get("constructor", "").endswith("::class:Greeter.") is not True
    or async_dynamic_call.get("method") != "surround"
    or async_dynamic_call.get("args") != [{"string": "patched-async"}]
    or async_dynamic_call.get("named_args") != [
        {"name": "prefix", "value": {"string": "<"}},
        {"name": "suffix", "value": {"string": ">"}},
    ]
):
    raise SystemExit(f"expected asyncDynamicNamedCall async call_dynamic source, got {async_dynamic_named_source}")

async_await_dynamic_source = source_for("asyncAwaitThenDynamicCall")
async_await_dynamic_arg = async_await_dynamic_source.get("body", {}).get("new_object", {}).get("args", [{}])[0]
async_await_dynamic_let = async_await_dynamic_arg.get("let", {})
async_await_dynamic_locals = async_await_dynamic_let.get("locals", [])
async_await_dynamic_call = async_await_dynamic_let.get("body", {}).get("call_dynamic", {})
if (
    async_await_dynamic_source.get("async_future") is not True
    or async_await_dynamic_source.get("body", {}).get("new_object", {}).get("type_args") != ["String"]
    or async_await_dynamic_source.get("params") != ["ready"]
    or len(async_await_dynamic_locals) != 1
    or async_await_dynamic_locals[0].get("name") != "value"
    or async_await_dynamic_locals[0].get("value", {}).get("await", {}).get("arg") != "ready"
    or async_await_dynamic_call.get("receiver", {}).get("new_object", {}).get("constructor", "").endswith("::class:Greeter.") is not True
    or async_await_dynamic_call.get("method") != "surround"
    or async_await_dynamic_call.get("args") != [{"let_local": 0}]
    or async_await_dynamic_call.get("named_args") != [
        {"name": "prefix", "value": {"string": "patched-await-dynamic<"}},
        {"name": "suffix", "value": {"string": ">"}},
    ]
):
    raise SystemExit(f"expected asyncAwaitThenDynamicCall await/call_dynamic source, got {async_await_dynamic_source}")

async_direct_callback_source = source_for("asyncDirectCallbackMixed")
async_direct_callback_arg = async_direct_callback_source.get("body", {}).get("new_object", {}).get("args", [{}])[0]
async_direct_callback_concat = async_direct_callback_arg.get("concat", [])
async_direct_callback_call = async_direct_callback_concat[0].get("call_closure", {}) if async_direct_callback_concat else {}
if (
    async_direct_callback_source.get("async_future") is not True
    or async_direct_callback_source.get("body", {}).get("new_object", {}).get("type_args") != ["String"]
    or async_direct_callback_call.get("closure", {}).get("arg") != "callback"
    or async_direct_callback_call.get("args") != [{"arg": "value"}]
    or async_direct_callback_call.get("named_args") != [{"name": "suffix", "value": {"arg": "suffix"}}]
    or async_direct_callback_concat[1].get("string") != " patched-async-mixed"
):
    raise SystemExit(f"expected asyncDirectCallbackMixed async call_closure source, got {async_direct_callback_source}")

async_await_callback_source = source_for("asyncAwaitThenDirectCallbackMixed")
async_await_callback_arg = async_await_callback_source.get("body", {}).get("new_object", {}).get("args", [{}])[0]
async_await_callback_let = async_await_callback_arg.get("let", {})
async_await_callback_locals = async_await_callback_let.get("locals", [])
async_await_callback_concat = async_await_callback_let.get("body", {}).get("concat", [])
async_await_callback_call = async_await_callback_concat[0].get("call_closure", {}) if async_await_callback_concat else {}
if (
    async_await_callback_source.get("async_future") is not True
    or async_await_callback_source.get("body", {}).get("new_object", {}).get("type_args") != ["String"]
    or async_await_callback_source.get("params") != ["callback", "ready", "suffix"]
    or len(async_await_callback_locals) != 1
    or async_await_callback_locals[0].get("name") != "value"
    or async_await_callback_locals[0].get("value", {}).get("await", {}).get("arg") != "ready"
    or async_await_callback_call.get("closure", {}).get("arg") != "callback"
    or async_await_callback_call.get("args") != [{"let_local": 0}]
    or async_await_callback_call.get("named_args") != [{"name": "suffix", "value": {"arg": "suffix"}}]
    or async_await_callback_concat[1].get("string") != " patched-await-callback"
):
    raise SystemExit(f"expected asyncAwaitThenDirectCallbackMixed await/call_closure source, got {async_await_callback_source}")

async_same_source = source_for("asyncSameObject")
async_same_arg = async_same_source.get("body", {}).get("new_object", {}).get("args", [{}])[0]
if (
    async_same_source.get("async_future") is not True
    or async_same_source.get("body", {}).get("new_object", {}).get("type_args") != ["bool"]
    or async_same_arg.get("call_original") != "dart:core::identical"
    or async_same_arg.get("args") != [{"arg": "value"}, {"arg": "value"}]
):
    raise SystemExit(f"expected asyncSameObject async call_original source, got {async_same_source}")

async_await_same_source = source_for("asyncAwaitThenSameObject")
async_await_same_arg = async_await_same_source.get("body", {}).get("new_object", {}).get("args", [{}])[0]
async_await_same_let = async_await_same_arg.get("let", {})
async_await_same_locals = async_await_same_let.get("locals", [])
async_await_same_call = async_await_same_let.get("body", {}).get("call_original", {})
if (
    async_await_same_source.get("async_future") is not True
    or async_await_same_source.get("body", {}).get("new_object", {}).get("type_args") != ["bool"]
    or async_await_same_source.get("params") != ["ready"]
    or len(async_await_same_locals) != 1
    or async_await_same_locals[0].get("name") != "value"
    or async_await_same_locals[0].get("value", {}).get("await", {}).get("arg") != "ready"
    or async_await_same_call != "dart:core::identical"
    or async_await_same_let.get("body", {}).get("args") != [{"let_local": 0}, {"let_local": 0}]
):
    raise SystemExit(f"expected asyncAwaitThenSameObject await/call_original source, got {async_await_same_source}")

async_arithmetic_source = source_for("asyncArithmeticValue")
async_arithmetic_arg = async_arithmetic_source.get("body", {}).get("new_object", {}).get("args", [{}])[0]
if (
    async_arithmetic_source.get("async_future") is not True
    or async_arithmetic_source.get("body", {}).get("new_object", {}).get("type_args") != ["int"]
    or async_arithmetic_arg.get("op") != "+"
    or async_arithmetic_arg.get("left", {}).get("arg") != "value"
    or async_arithmetic_arg.get("right", {}).get("int") != 2
):
    raise SystemExit(f"expected asyncArithmeticValue async binary op source, got {async_arithmetic_source}")

async_await_arithmetic_source = source_for("asyncAwaitThenArithmeticValue")
async_await_arithmetic_arg = async_await_arithmetic_source.get("body", {}).get("new_object", {}).get("args", [{}])[0]
async_await_arithmetic_let = async_await_arithmetic_arg.get("let", {})
async_await_arithmetic_locals = async_await_arithmetic_let.get("locals", [])
async_await_arithmetic_op = async_await_arithmetic_let.get("body", {})
if (
    async_await_arithmetic_source.get("async_future") is not True
    or async_await_arithmetic_source.get("body", {}).get("new_object", {}).get("type_args") != ["int"]
    or async_await_arithmetic_source.get("params") != ["ready"]
    or len(async_await_arithmetic_locals) != 1
    or async_await_arithmetic_locals[0].get("name") != "value"
    or async_await_arithmetic_locals[0].get("value", {}).get("await", {}).get("arg") != "ready"
    or async_await_arithmetic_op.get("op") != "+"
    or async_await_arithmetic_op.get("left", {}).get("let_local") != 0
    or async_await_arithmetic_op.get("right", {}).get("int") != 5
):
    raise SystemExit(
        "expected asyncAwaitThenArithmeticValue await/binary op source, "
        f"got {async_await_arithmetic_source}"
    )

async_subtract_source = source_for("asyncSubtractValue")
async_subtract_arg = async_subtract_source.get("body", {}).get("new_object", {}).get("args", [{}])[0]
if (
    async_subtract_source.get("async_future") is not True
    or async_subtract_source.get("body", {}).get("new_object", {}).get("type_args") != ["int"]
    or async_subtract_arg.get("op") != "-"
    or async_subtract_arg.get("left", {}).get("arg") != "value"
    or async_subtract_arg.get("right", {}).get("int") != 3
):
    raise SystemExit(f"expected asyncSubtractValue async binary op source, got {async_subtract_source}")

async_await_subtract_source = source_for("asyncAwaitThenSubtractValue")
async_await_subtract_arg = async_await_subtract_source.get("body", {}).get("new_object", {}).get("args", [{}])[0]
async_await_subtract_let = async_await_subtract_arg.get("let", {})
async_await_subtract_locals = async_await_subtract_let.get("locals", [])
async_await_subtract_op = async_await_subtract_let.get("body", {})
if (
    async_await_subtract_source.get("async_future") is not True
    or async_await_subtract_source.get("body", {}).get("new_object", {}).get("type_args") != ["int"]
    or async_await_subtract_source.get("params") != ["ready"]
    or len(async_await_subtract_locals) != 1
    or async_await_subtract_locals[0].get("name") != "value"
    or async_await_subtract_locals[0].get("value", {}).get("await", {}).get("arg") != "ready"
    or async_await_subtract_op.get("op") != "-"
    or async_await_subtract_op.get("left", {}).get("let_local") != 0
    or async_await_subtract_op.get("right", {}).get("int") != 7
):
    raise SystemExit(
        "expected asyncAwaitThenSubtractValue await/binary op source, "
        f"got {async_await_subtract_source}"
    )

async_multiply_source = source_for("asyncMultiplyValue")
async_multiply_arg = async_multiply_source.get("body", {}).get("new_object", {}).get("args", [{}])[0]
if (
    async_multiply_source.get("async_future") is not True
    or async_multiply_source.get("body", {}).get("new_object", {}).get("type_args") != ["int"]
    or async_multiply_arg.get("op") != "*"
    or async_multiply_arg.get("left", {}).get("arg") != "value"
    or async_multiply_arg.get("right", {}).get("int") != 3
):
    raise SystemExit(f"expected asyncMultiplyValue async binary op source, got {async_multiply_source}")

async_await_multiply_source = source_for("asyncAwaitThenMultiplyValue")
async_await_multiply_arg = async_await_multiply_source.get("body", {}).get("new_object", {}).get("args", [{}])[0]
async_await_multiply_let = async_await_multiply_arg.get("let", {})
async_await_multiply_locals = async_await_multiply_let.get("locals", [])
async_await_multiply_op = async_await_multiply_let.get("body", {})
if (
    async_await_multiply_source.get("async_future") is not True
    or async_await_multiply_source.get("body", {}).get("new_object", {}).get("type_args") != ["int"]
    or async_await_multiply_source.get("params") != ["ready"]
    or len(async_await_multiply_locals) != 1
    or async_await_multiply_locals[0].get("name") != "value"
    or async_await_multiply_locals[0].get("value", {}).get("await", {}).get("arg") != "ready"
    or async_await_multiply_op.get("op") != "*"
    or async_await_multiply_op.get("left", {}).get("let_local") != 0
    or async_await_multiply_op.get("right", {}).get("int") != 9
):
    raise SystemExit(
        "expected asyncAwaitThenMultiplyValue await/binary op source, "
        f"got {async_await_multiply_source}"
    )

async_divide_source = source_for("asyncDivideValue")
async_divide_arg = async_divide_source.get("body", {}).get("new_object", {}).get("args", [{}])[0]
if (
    async_divide_source.get("async_future") is not True
    or async_divide_source.get("body", {}).get("new_object", {}).get("type_args") != ["double"]
    or async_divide_arg.get("op") != "/"
    or async_divide_arg.get("left", {}).get("arg") != "value"
    or async_divide_arg.get("right", {}).get("int") != 4
):
    raise SystemExit(f"expected asyncDivideValue async binary op source, got {async_divide_source}")

async_logical_source = source_for("asyncLogicalFlag")
async_logical_arg = async_logical_source.get("body", {}).get("new_object", {}).get("args", [{}])[0]
async_logical_condition = async_logical_arg.get("conditional", {})
async_logical_and = async_logical_condition.get("condition", {}).get("conditional", {})
async_logical_not = async_logical_and.get("then", {}).get("conditional", {})
if (
    async_logical_source.get("async_future") is not True
    or async_logical_source.get("body", {}).get("new_object", {}).get("type_args") != ["bool"]
    or async_logical_condition.get("then", {}).get("bool") is not True
    or async_logical_condition.get("else", {}).get("arg") != "premium"
    or async_logical_and.get("condition", {}).get("arg") != "enabled"
    or async_logical_and.get("else", {}).get("bool") is not False
    or async_logical_not.get("condition", {}).get("arg") != "premium"
    or async_logical_not.get("then", {}).get("bool") is not False
    or async_logical_not.get("else", {}).get("bool") is not True
):
    raise SystemExit(f"expected asyncLogicalFlag async logical source, got {async_logical_source}")

async_always_throw_source = source_for("asyncAlwaysThrow")
async_always_throw_arg = async_always_throw_source.get("body", {}).get("new_object", {}).get("args", [{}])[0]
if (
    async_always_throw_source.get("async_future") is not True
    or async_always_throw_source.get("body", {}).get("new_object", {}).get("type_args") != ["String"]
    or async_always_throw_arg.get("throw", {}).get("string") != "patched-async-boom"
):
    raise SystemExit(f"expected asyncAlwaysThrow async throw source, got {async_always_throw_source}")

async_static_helper_source = source_for("asyncStaticHelperValue")
async_static_helper_arg = async_static_helper_source.get("body", {}).get("new_object", {}).get("args", [{}])[0]
async_static_helper_call = async_static_helper_arg.get("left", {})
if (
    async_static_helper_source.get("async_future") is not True
    or async_static_helper_source.get("body", {}).get("new_object", {}).get("type_args") != ["double"]
    or async_static_helper_arg.get("op") != "+"
    or async_static_helper_call.get("call_static", "").endswith("::helper") is not True
    or async_static_helper_call.get("args") != []
    or async_static_helper_arg.get("right", {}).get("double") != 3.5
):
    raise SystemExit(f"expected asyncStaticHelperValue async call_static source, got {async_static_helper_source}")

async_await_static_source = source_for("asyncAwaitThenStaticHelperValue")
async_await_static_arg = async_await_static_source.get("body", {}).get("new_object", {}).get("args", [{}])[0]
async_await_static_let = async_await_static_arg.get("let", {})
async_await_static_locals = async_await_static_let.get("locals", [])
async_await_static_op = async_await_static_let.get("body", {})
async_await_static_call = async_await_static_op.get("right", {})
if (
    async_await_static_source.get("async_future") is not True
    or async_await_static_source.get("body", {}).get("new_object", {}).get("type_args") != ["double"]
    or async_await_static_source.get("params") != ["ready"]
    or len(async_await_static_locals) != 1
    or async_await_static_locals[0].get("name") != "value"
    or async_await_static_locals[0].get("value", {}).get("await", {}).get("arg") != "ready"
    or async_await_static_op.get("op") != "+"
    or async_await_static_op.get("left", {}).get("let_local") != 0
    or async_await_static_call.get("call_static", "").endswith("::helper") is not True
    or async_await_static_call.get("args") != []
):
    raise SystemExit(f"expected asyncAwaitThenStaticHelperValue await/call_static source, got {async_await_static_source}")

async_concat_source = source_for("asyncConcatLabel")
async_concat_arg = async_concat_source.get("body", {}).get("new_object", {}).get("args", [{}])[0]
async_concat_items = async_concat_arg.get("concat", [])
if (
    async_concat_source.get("async_future") is not True
    or async_concat_source.get("body", {}).get("new_object", {}).get("type_args") != ["String"]
    or len(async_concat_items) != 2
    or async_concat_items[0].get("string") != "patched-async "
    or async_concat_items[1].get("arg") != "name"
):
    raise SystemExit(f"expected asyncConcatLabel async concat source, got {async_concat_source}")

async_nullable_source = source_for("asyncNullableChoice")
async_nullable_arg = async_nullable_source.get("body", {}).get("new_object", {}).get("args", [{}])[0]
async_nullable_conditional = async_nullable_arg.get("conditional", {})
if (
    async_nullable_source.get("async_future") is not True
    or async_nullable_source.get("body", {}).get("new_object", {}).get("type_args") != ["Object"]
    or async_nullable_conditional.get("condition", {}).get("arg") != "enabled"
    or async_nullable_conditional.get("then", {}).get("null") is not True
    or async_nullable_conditional.get("else", {}).get("string") != "patched-null"
):
    raise SystemExit(f"expected asyncNullableChoice async null conditional source, got {async_nullable_source}")

async_display_source = source_for("asyncDisplayName")
async_display_arg = async_display_source.get("body", {}).get("new_object", {}).get("args", [{}])[0]
async_display_get = async_display_arg.get("get_field", {})
if (
    async_display_source.get("async_future") is not True
    or async_display_source.get("body", {}).get("new_object", {}).get("type_args") != ["String"]
    or async_display_get.get("receiver", {}).get("arg") != "user"
    or async_display_get.get("field") != "label"
):
    raise SystemExit(f"expected asyncDisplayName async get_field source, got {async_display_source}")

async_await_field_source = source_for("asyncAwaitThenReadField")
async_await_field_arg = async_await_field_source.get("body", {}).get("new_object", {}).get("args", [{}])[0]
async_await_field_let = async_await_field_arg.get("let", {})
async_await_field_locals = async_await_field_let.get("locals", [])
async_await_field_concat = async_await_field_let.get("body", {}).get("concat", [])
async_await_field_get = async_await_field_concat[3].get("get_field", {}) if len(async_await_field_concat) > 3 else {}
if (
    async_await_field_source.get("async_future") is not True
    or async_await_field_source.get("body", {}).get("new_object", {}).get("type_args") != ["String"]
    or async_await_field_source.get("params") != ["user", "ready"]
    or len(async_await_field_locals) != 1
    or async_await_field_locals[0].get("name") != "prefix"
    or async_await_field_locals[0].get("value", {}).get("await", {}).get("arg") != "ready"
    or async_await_field_concat[0].get("string") != "patched-await-field:"
    or async_await_field_concat[1].get("let_local") != 0
    or async_await_field_concat[2].get("string") != " "
    or async_await_field_get.get("receiver", {}).get("arg") != "user"
    or async_await_field_get.get("field") != "label"
):
    raise SystemExit(f"expected asyncAwaitThenReadField await/get_field concat source, got {async_await_field_source}")

async_make_user_source = source_for("asyncMakeUser")
async_make_user_object = async_make_user_source.get("body", {}).get("new_object", {})
async_make_user_arg = async_make_user_object.get("args", [{}])[0].get("new_object", {})
if (
    async_make_user_source.get("async_future") is not True
    or async_make_user_object.get("type_args") != ["User"]
    or not async_make_user_arg.get("constructor", "").endswith("::class:User.")
    or async_make_user_arg.get("args") != [
        {"string": "patched-async"},
        {"string": "patched-async-label"},
    ]
):
    raise SystemExit(f"expected asyncMakeUser async new_object source, got {async_make_user_source}")

async_make_config_source = source_for("asyncMakeConfig")
async_make_config_object = async_make_config_source.get("body", {}).get("new_object", {})
async_make_config_arg = async_make_config_object.get("args", [{}])[0].get("new_object", {})
if (
    async_make_config_source.get("async_future") is not True
    or async_make_config_object.get("type_args") != ["Config"]
    or not async_make_config_arg.get("constructor", "").endswith("::class:Config.")
    or async_make_config_arg.get("named_args") != [
        {"name": "name", "value": {"string": "patched-async"}},
        {"name": "label", "value": {"string": "patched-async-label"}},
    ]
):
    raise SystemExit(f"expected asyncMakeConfig async named new_object source, got {async_make_config_source}")

async_make_box_source = source_for("asyncMakeStringBox")
async_make_box_object = async_make_box_source.get("body", {}).get("new_object", {})
async_make_box_arg = async_make_box_object.get("args", [{}])[0].get("new_object", {})
if (
    async_make_box_source.get("async_future") is not True
    or async_make_box_object.get("type_args") != ["Box<String>"]
    or not async_make_box_arg.get("constructor", "").endswith("::class:Box.")
    or async_make_box_arg.get("type_args") != ["String"]
    or async_make_box_arg.get("args") != [{"string": "patched-async-box"}]
):
    raise SystemExit(f"expected asyncMakeStringBox async generic new_object source, got {async_make_box_source}")

async_await_box_source = source_for("asyncAwaitThenMakeStringBox")
async_await_box_object = async_await_box_source.get("body", {}).get("new_object", {})
async_await_box_let = async_await_box_object.get("args", [{}])[0].get("let", {})
async_await_box_locals = async_await_box_let.get("locals", [])
async_await_box_inner = async_await_box_let.get("body", {}).get("new_object", {})
async_await_box_concat = async_await_box_inner.get("args", [{}])[0].get("concat", [])
if (
    async_await_box_source.get("async_future") is not True
    or async_await_box_object.get("type_args") != ["Box<String>"]
    or async_await_box_source.get("params") != ["ready"]
    or len(async_await_box_locals) != 1
    or async_await_box_locals[0].get("name") != "value"
    or async_await_box_locals[0].get("value", {}).get("await", {}).get("arg") != "ready"
    or not async_await_box_inner.get("constructor", "").endswith("::class:Box.")
    or async_await_box_inner.get("type_args") != ["String"]
    or async_await_box_concat != [{"string": "patched-await-box:"}, {"let_local": 0}]
):
    raise SystemExit(f"expected asyncAwaitThenMakeStringBox await/generic new_object source, got {async_await_box_source}")

async_is_string_list_source = source_for("asyncIsStringList")
async_is_string_list_arg = async_is_string_list_source.get("body", {}).get("new_object", {}).get("args", [{}])[0]
async_is_type = async_is_string_list_arg.get("is_type", {})
if (
    async_is_string_list_source.get("async_future") is not True
    or async_is_string_list_source.get("body", {}).get("new_object", {}).get("type_args") != ["bool"]
    or async_is_type.get("value", {}).get("arg") != "value"
    or async_is_type.get("type") != "List<String>"
):
    raise SystemExit(f"expected asyncIsStringList async is_type source, got {async_is_string_list_source}")

async_as_string_list_source = source_for("asyncAsStringList")
async_as_string_list_arg = async_as_string_list_source.get("body", {}).get("new_object", {}).get("args", [{}])[0]
async_as_type = async_as_string_list_arg.get("as_type", {})
if (
    async_as_string_list_source.get("async_future") is not True
    or async_as_string_list_source.get("body", {}).get("new_object", {}).get("type_args") != ["Object"]
    or async_as_type.get("value", {}).get("arg") != "value"
    or async_as_type.get("type") != "List<String>"
):
    raise SystemExit(f"expected asyncAsStringList async as_type source, got {async_as_string_list_source}")

async_await_is_source = source_for("asyncAwaitThenIsString")
async_await_is_arg = async_await_is_source.get("body", {}).get("new_object", {}).get("args", [{}])[0]
async_await_is_let = async_await_is_arg.get("let", {})
async_await_is_locals = async_await_is_let.get("locals", [])
async_await_is_type = async_await_is_let.get("body", {}).get("is_type", {})
if (
    async_await_is_source.get("async_future") is not True
    or async_await_is_source.get("body", {}).get("new_object", {}).get("type_args") != ["bool"]
    or async_await_is_source.get("params") != ["ready"]
    or len(async_await_is_locals) != 1
    or async_await_is_locals[0].get("name") != "value"
    or async_await_is_locals[0].get("value", {}).get("await", {}).get("arg") != "ready"
    or async_await_is_type.get("value", {}).get("let_local") != 0
    or async_await_is_type.get("type") != "String"
):
    raise SystemExit(f"expected asyncAwaitThenIsString await/is_type source, got {async_await_is_source}")

async_await_as_source = source_for("asyncAwaitThenAsStringList")
async_await_as_arg = async_await_as_source.get("body", {}).get("new_object", {}).get("args", [{}])[0]
async_await_as_let = async_await_as_arg.get("let", {})
async_await_as_locals = async_await_as_let.get("locals", [])
async_await_as_type = async_await_as_let.get("body", {}).get("as_type", {})
if (
    async_await_as_source.get("async_future") is not True
    or async_await_as_source.get("body", {}).get("new_object", {}).get("type_args") != ["Object"]
    or async_await_as_source.get("params") != ["ready"]
    or len(async_await_as_locals) != 1
    or async_await_as_locals[0].get("name") != "value"
    or async_await_as_locals[0].get("value", {}).get("await", {}).get("arg") != "ready"
    or async_await_as_type.get("value", {}).get("let_local") != 0
    or async_await_as_type.get("type") != "List<String>"
):
    raise SystemExit(f"expected asyncAwaitThenAsStringList await/as_type source, got {async_await_as_source}")

async_dynamic_names_source = source_for("asyncDynamicNames")
async_dynamic_names_arg = async_dynamic_names_source.get("body", {}).get("new_object", {}).get("args", [{}])[0]
async_dynamic_names_add_all = async_dynamic_names_arg.get("list_add_all", {})
if (
    async_dynamic_names_source.get("async_future") is not True
    or async_dynamic_names_source.get("body", {}).get("new_object", {}).get("type_args") != ["List<String>"]
    or async_dynamic_names_add_all.get("receiver", {}).get("list", [{}])[0].get("string") != "patched-async"
    or async_dynamic_names_add_all.get("spread", {}).get("arg") != "extra"
):
    raise SystemExit(f"expected asyncDynamicNames async list_add_all source, got {async_dynamic_names_source}")

async_names_source = source_for("asyncNames")
async_names_arg = async_names_source.get("body", {}).get("new_object", {}).get("args", [{}])[0]
async_names_premium = async_names_arg.get("conditional", {})
async_names_premium_then = async_names_premium.get("then", {}).get("conditional", {}).get("then", {}).get("list", [])
async_names_premium_else = async_names_premium.get("else", {}).get("conditional", {}).get("else", {}).get("list", [])
if (
    async_names_source.get("async_future") is not True
    or async_names_source.get("body", {}).get("new_object", {}).get("type_args") != ["List<String>"]
    or async_names_premium.get("condition", {}).get("arg") != "premium"
    or len(async_names_premium_then) != 8
    or async_names_premium_then[0].get("string") != "patched-async-static"
    or async_names_premium_then[3].get("string") != "async-for-a"
    or async_names_premium_then[5].get("string") != "async-live"
    or async_names_premium_then[6].get("string") != "async-pro"
    or len(async_names_premium_else) != 7
    or async_names_premium_else[5].get("string") != "async-off"
):
    raise SystemExit(f"expected asyncNames async static collection source, got {async_names_source}")

async_dynamic_labels_source = source_for("asyncDynamicLabels")
async_dynamic_labels_arg = async_dynamic_labels_source.get("body", {}).get("new_object", {}).get("args", [{}])[0]
async_dynamic_labels_add_all = async_dynamic_labels_arg.get("map_add_all", {})
if (
    async_dynamic_labels_source.get("async_future") is not True
    or async_dynamic_labels_source.get("body", {}).get("new_object", {}).get("type_args") != ["Map<String,String>"]
    or async_dynamic_labels_add_all.get("receiver", {}).get("map", [{}])[0].get("key", {}).get("string") != "mode"
    or async_dynamic_labels_add_all.get("receiver", {}).get("map", [{}])[0].get("value", {}).get("string") != "patched-async"
    or async_dynamic_labels_add_all.get("spread", {}).get("arg") != "extra"
):
    raise SystemExit(f"expected asyncDynamicLabels async map_add_all source, got {async_dynamic_labels_source}")

async_labels_source = source_for("asyncLabels")
async_labels_arg = async_labels_source.get("body", {}).get("new_object", {}).get("args", [{}])[0]
async_labels_premium = async_labels_arg.get("conditional", {})
async_labels_premium_then = async_labels_premium.get("then", {}).get("conditional", {}).get("then", {}).get("map", [])
async_labels_premium_else = async_labels_premium.get("else", {}).get("conditional", {}).get("else", {}).get("map", [])
if (
    async_labels_source.get("async_future") is not True
    or async_labels_source.get("body", {}).get("new_object", {}).get("type_args") != ["Map<String,String>"]
    or async_labels_premium.get("condition", {}).get("arg") != "premium"
    or len(async_labels_premium_then) != 6
    or async_labels_premium_then[0].get("value", {}).get("string") != "patched-async-static"
    or async_labels_premium_then[2].get("key", {}).get("string") != "async-for"
    or async_labels_premium_then[3].get("value", {}).get("string") != "live"
    or async_labels_premium_then[4].get("key", {}).get("string") != "async-tier"
    or len(async_labels_premium_else) != 5
    or async_labels_premium_else[3].get("value", {}).get("string") != "off"
):
    raise SystemExit(f"expected asyncLabels async static map source, got {async_labels_source}")

async_runtime_for_names_source = source_for("asyncRuntimeForNames")
async_runtime_for_names_arg = async_runtime_for_names_source.get("body", {}).get("new_object", {}).get("args", [{}])[0]
async_runtime_for_names_for = async_runtime_for_names_arg.get("list_for_in", {})
if (
    async_runtime_for_names_source.get("async_future") is not True
    or async_runtime_for_names_source.get("body", {}).get("new_object", {}).get("type_args") != ["List<String>"]
    or async_runtime_for_names_for.get("receiver", {}).get("list", [{}])[0].get("string") != "patched-async-for"
    or async_runtime_for_names_for.get("source", {}).get("arg") != "extra"
):
    raise SystemExit(f"expected asyncRuntimeForNames async list_for_in source, got {async_runtime_for_names_source}")

async_runtime_for_labels_source = source_for("asyncRuntimeForLabels")
async_runtime_for_labels_arg = async_runtime_for_labels_source.get("body", {}).get("new_object", {}).get("args", [{}])[0]
async_runtime_for_labels_for = async_runtime_for_labels_arg.get("map_for_in", {})
if (
    async_runtime_for_labels_source.get("async_future") is not True
    or async_runtime_for_labels_source.get("body", {}).get("new_object", {}).get("type_args") != ["Map<String,String>"]
    or async_runtime_for_labels_for.get("receiver", {}).get("map", [{}])[0].get("key", {}).get("string") != "mode"
    or async_runtime_for_labels_for.get("receiver", {}).get("map", [{}])[0].get("value", {}).get("string") != "patched-async-for"
    or async_runtime_for_labels_for.get("source", {}).get("call_dynamic", {}).get("method") != "get:entries"
    or async_runtime_for_labels_for.get("source", {}).get("call_dynamic", {}).get("receiver", {}).get("arg") != "extra"
):
    raise SystemExit(f"expected asyncRuntimeForLabels async map_for_in source, got {async_runtime_for_labels_source}")
