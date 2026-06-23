def assert_core_op_sources(source_for):
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
    async_await_arithmetic_arg = async_await_arithmetic_source.get("body", {}).get("new_object", {}).get(
        "args", [{}]
    )[0]
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
    async_await_multiply_arg = async_await_multiply_source.get("body", {}).get("new_object", {}).get(
        "args", [{}]
    )[0]
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

    async_await_divide_source = source_for("asyncAwaitThenDivideValue")
    async_await_divide_arg = async_await_divide_source.get("body", {}).get("new_object", {}).get("args", [{}])[0]
    async_await_divide_let = async_await_divide_arg.get("let", {})
    async_await_divide_locals = async_await_divide_let.get("locals", [])
    async_await_divide_op = async_await_divide_let.get("body", {})
    if (
        async_await_divide_source.get("async_future") is not True
        or async_await_divide_source.get("body", {}).get("new_object", {}).get("type_args") != ["double"]
        or async_await_divide_source.get("params") != ["ready"]
        or len(async_await_divide_locals) != 1
        or async_await_divide_locals[0].get("name") != "value"
        or async_await_divide_locals[0].get("value", {}).get("await", {}).get("arg") != "ready"
        or async_await_divide_op.get("op") != "/"
        or async_await_divide_op.get("left", {}).get("let_local") != 0
        or async_await_divide_op.get("right", {}).get("int") != 11
    ):
        raise SystemExit(
            "expected asyncAwaitThenDivideValue await/binary op source, "
            f"got {async_await_divide_source}"
        )

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

    async_await_logical_source = source_for("asyncAwaitThenLogicalFlag")
    async_await_logical_arg = async_await_logical_source.get("body", {}).get("new_object", {}).get("args", [{}])[0]
    async_await_logical_let = async_await_logical_arg.get("let", {})
    async_await_logical_locals = async_await_logical_let.get("locals", [])
    async_await_logical_condition = async_await_logical_let.get("body", {}).get("conditional", {})
    async_await_logical_and = async_await_logical_condition.get("condition", {}).get("conditional", {})
    async_await_logical_not = async_await_logical_and.get("then", {}).get("conditional", {})
    if (
        async_await_logical_source.get("async_future") is not True
        or async_await_logical_source.get("body", {}).get("new_object", {}).get("type_args") != ["bool"]
        or async_await_logical_source.get("params") != ["ready", "premium"]
        or len(async_await_logical_locals) != 1
        or async_await_logical_locals[0].get("name") != "enabled"
        or async_await_logical_locals[0].get("value", {}).get("await", {}).get("arg") != "ready"
        or async_await_logical_condition.get("then", {}).get("bool") is not True
        or async_await_logical_condition.get("else", {}).get("arg") != "premium"
        or async_await_logical_and.get("condition", {}).get("let_local") != 0
        or async_await_logical_and.get("else", {}).get("bool") is not False
        or async_await_logical_not.get("condition", {}).get("arg") != "premium"
        or async_await_logical_not.get("then", {}).get("bool") is not False
        or async_await_logical_not.get("else", {}).get("bool") is not True
    ):
        raise SystemExit(
            "expected asyncAwaitThenLogicalFlag await/logical source, "
            f"got {async_await_logical_source}"
        )

    async_always_throw_source = source_for("asyncAlwaysThrow")
    async_always_throw_arg = async_always_throw_source.get("body", {}).get("new_object", {}).get("args", [{}])[0]
    if (
        async_always_throw_source.get("async_future") is not True
        or async_always_throw_source.get("body", {}).get("new_object", {}).get("type_args") != ["String"]
        or async_always_throw_arg.get("throw", {}).get("string") != "patched-async-boom"
    ):
        raise SystemExit(f"expected asyncAlwaysThrow async throw source, got {async_always_throw_source}")

    async_await_throw_source = source_for("asyncAwaitThenAlwaysThrow")
    async_await_throw_arg = async_await_throw_source.get("body", {}).get("new_object", {}).get("args", [{}])[0]
    async_await_throw_let = async_await_throw_arg.get("let", {})
    async_await_throw_locals = async_await_throw_let.get("locals", [])
    async_await_throw_throw = async_await_throw_let.get("body", {}).get("throw", {})
    async_await_throw_concat = async_await_throw_throw.get("concat", [])
    if (
        async_await_throw_source.get("async_future") is not True
        or async_await_throw_source.get("body", {}).get("new_object", {}).get("type_args") != ["String"]
        or async_await_throw_source.get("params") != ["ready"]
        or len(async_await_throw_locals) != 1
        or async_await_throw_locals[0].get("name") != "value"
        or async_await_throw_locals[0].get("value", {}).get("await", {}).get("arg") != "ready"
        or async_await_throw_concat != [
            {"string": "patched-await-throw:"},
            {"let_local": 0},
        ]
    ):
        raise SystemExit(
            "expected asyncAwaitThenAlwaysThrow await/throw source, "
            f"got {async_await_throw_source}"
        )

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
