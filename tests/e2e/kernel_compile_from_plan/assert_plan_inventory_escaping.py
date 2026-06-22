def assert_inventory_escaping_sources(patch):
    escaping = [
        f for f in patch["functions"]
        if f.get("member_name") == "escapingGreeting"
    ]
    if len(escaping) != 1:
        raise SystemExit(f"expected one escapingGreeting inventory entry, got {escaping}")
    escaping_source = escaping[0].get("bytecode_source")
    if not isinstance(escaping_source, dict):
        raise SystemExit(f"escaping closure must produce bytecode source: {escaping[0]}")
    if escaping[0].get("unsupported_reasons") != []:
        raise SystemExit(f"escaping closure should now be supported, got {escaping[0]}")
    if escaping_source.get("body", {}).get("let", {}).get("body", {}).get("make_closure") is None:
        raise SystemExit(f"expected escaping closure make_closure source, got {escaping_source}")
    if len(escaping_source.get("extra_functions", [])) != 1:
        raise SystemExit(f"expected escaping closure extra function, got {escaping_source}")

    stored_escaping = [
        f for f in patch["functions"]
        if f.get("member_name") == "storedEscapingGreeting"
    ]
    if len(stored_escaping) != 1:
        raise SystemExit(f"expected one storedEscapingGreeting inventory entry, got {stored_escaping}")
    stored_escaping_source = stored_escaping[0].get("bytecode_source")
    if not isinstance(stored_escaping_source, dict):
        raise SystemExit(f"stored escaping closure must produce bytecode source: {stored_escaping[0]}")
    if stored_escaping[0].get("unsupported_reasons") != []:
        raise SystemExit(f"stored escaping closure should now be supported, got {stored_escaping[0]}")
    if stored_escaping_source.get("body", {}).get("let", {}).get("body", {}).get("make_closure") is None:
        raise SystemExit(f"expected stored escaping closure make_closure source, got {stored_escaping_source}")
    if len(stored_escaping_source.get("extra_functions", [])) != 1:
        raise SystemExit(f"expected stored escaping closure extra function, got {stored_escaping_source}")

    personalized_escaping = [
        f for f in patch["functions"]
        if f.get("member_name") == "personalizedEscapingGreeting"
    ]
    if len(personalized_escaping) != 1:
        raise SystemExit(f"expected one personalizedEscapingGreeting inventory entry, got {personalized_escaping}")
    personalized_escaping_source = personalized_escaping[0].get("bytecode_source")
    if not isinstance(personalized_escaping_source, dict):
        raise SystemExit(f"personalized escaping closure must produce bytecode source: {personalized_escaping[0]}")
    if personalized_escaping[0].get("unsupported_reasons") != []:
        raise SystemExit(f"personalized escaping closure should now be supported, got {personalized_escaping[0]}")
    if personalized_escaping_source.get("body", {}).get("let", {}).get("body", {}).get("make_closure") is None:
        raise SystemExit(f"expected personalized escaping closure make_closure source, got {personalized_escaping_source}")
    extra_functions = personalized_escaping_source.get("extra_functions", [])
    if len(extra_functions) != 1 or extra_functions[0].get("params") != ["prefix", "name", "suffix"]:
        raise SystemExit(f"expected personalized escaping closure params, got {personalized_escaping_source}")

    named_escaping = [
        f for f in patch["functions"]
        if f.get("member_name") == "namedEscapingGreeting"
    ]
    if len(named_escaping) != 1:
        raise SystemExit(f"expected one namedEscapingGreeting inventory entry, got {named_escaping}")
    named_escaping_source = named_escaping[0].get("bytecode_source")
    if not isinstance(named_escaping_source, dict):
        raise SystemExit(f"named escaping closure must produce bytecode source: {named_escaping[0]}")
    if named_escaping[0].get("unsupported_reasons") != []:
        raise SystemExit(f"named escaping closure should now be supported, got {named_escaping[0]}")
    if named_escaping_source.get("body", {}).get("let", {}).get("body", {}).get("make_closure") is None:
        raise SystemExit(f"expected named escaping closure make_closure source, got {named_escaping_source}")
    extra_functions = named_escaping_source.get("extra_functions", [])
    if len(extra_functions) != 1 or extra_functions[0].get("params") != ["prefix", "name", "suffix"]:
        raise SystemExit(f"expected named escaping closure params, got {named_escaping_source}")
    make_closure = named_escaping_source.get("body", {}).get("let", {}).get("body", {}).get("make_closure", {})
    if make_closure.get("named_parameters") != ["suffix"]:
        raise SystemExit(f"expected required named escaping closure metadata, got {named_escaping_source}")

    optional_positional_escaping = [
        f for f in patch["functions"]
        if f.get("member_name") == "optionalPositionalEscapingGreeting"
    ]
    if len(optional_positional_escaping) != 1:
        raise SystemExit(f"expected one optionalPositionalEscapingGreeting inventory entry, got {optional_positional_escaping}")
    optional_positional_source = optional_positional_escaping[0].get("bytecode_source")
    if not isinstance(optional_positional_source, dict):
        raise SystemExit(f"optional positional escaping closure must produce bytecode source: {optional_positional_escaping[0]}")
    if optional_positional_escaping[0].get("unsupported_reasons") != []:
        raise SystemExit(f"optional positional escaping closure should now be supported, got {optional_positional_escaping[0]}")
    make_closure = optional_positional_source.get("body", {}).get("let", {}).get("body", {}).get("make_closure", {})
    if make_closure.get("optional_positional_count") != 1:
        raise SystemExit(f"expected optional positional escaping closure metadata, got {optional_positional_source}")
    extra_functions = optional_positional_source.get("extra_functions", [])
    if len(extra_functions) != 1 or extra_functions[0].get("params") != ["prefix", "name", "suffix"]:
        raise SystemExit(f"expected optional positional escaping closure params, got {optional_positional_source}")

    optional_named_escaping = [
        f for f in patch["functions"]
        if f.get("member_name") == "optionalNamedEscapingGreeting"
    ]
    if len(optional_named_escaping) != 1:
        raise SystemExit(f"expected one optionalNamedEscapingGreeting inventory entry, got {optional_named_escaping}")
    optional_named_source = optional_named_escaping[0].get("bytecode_source")
    if not isinstance(optional_named_source, dict):
        raise SystemExit(f"optional named escaping closure must produce bytecode source: {optional_named_escaping[0]}")
    if optional_named_escaping[0].get("unsupported_reasons") != []:
        raise SystemExit(f"optional named escaping closure should now be supported, got {optional_named_escaping[0]}")
    make_closure = optional_named_source.get("body", {}).get("let", {}).get("body", {}).get("make_closure", {})
    if make_closure.get("named_parameters") != ["?suffix"]:
        raise SystemExit(f"expected optional named escaping closure metadata, got {optional_named_source}")
    extra_functions = optional_named_source.get("extra_functions", [])
    if len(extra_functions) != 1 or extra_functions[0].get("params") != ["prefix", "name", "suffix"]:
        raise SystemExit(f"expected optional named escaping closure params, got {optional_named_source}")

    generic_escaping = [
        f for f in patch["functions"]
        if f.get("member_name") == "genericEscapingGreeting"
    ]
    if len(generic_escaping) != 1:
        raise SystemExit(f"expected one genericEscapingGreeting inventory entry, got {generic_escaping}")
    generic_source = generic_escaping[0].get("bytecode_source")
    if not isinstance(generic_source, dict):
        raise SystemExit(f"generic escaping closure must produce bytecode source: {generic_escaping[0]}")
    if generic_escaping[0].get("unsupported_reasons") != []:
        raise SystemExit(f"generic escaping closure should now be supported, got {generic_escaping[0]}")
    make_closure = generic_source.get("body", {}).get("let", {}).get("body", {}).get("make_closure", {})
    if make_closure.get("type_parameter_count") != 1:
        raise SystemExit(f"expected generic escaping closure type metadata, got {generic_source}")
    extra_functions = generic_source.get("extra_functions", [])
    if len(extra_functions) != 1 or extra_functions[0].get("params") != ["prefix", "name", "value"]:
        raise SystemExit(f"expected generic escaping closure params, got {generic_source}")

    local_function_escaping = [
        f for f in patch["functions"]
        if f.get("member_name") == "localFunctionEscapingGreeting"
    ]
    if len(local_function_escaping) != 1:
        raise SystemExit(f"expected one localFunctionEscapingGreeting inventory entry, got {local_function_escaping}")
    local_function_source = local_function_escaping[0].get("bytecode_source")
    if not isinstance(local_function_source, dict):
        raise SystemExit(f"local function escaping closure must produce bytecode source: {local_function_escaping[0]}")
    if local_function_escaping[0].get("unsupported_reasons") != []:
        raise SystemExit(f"local function escaping closure should now be supported, got {local_function_escaping[0]}")
    if local_function_source.get("body", {}).get("let", {}).get("body", {}).get("make_closure") is None:
        raise SystemExit(f"expected local function escaping closure make_closure source, got {local_function_source}")
    extra_functions = local_function_source.get("extra_functions", [])
    if len(extra_functions) != 1 or extra_functions[0].get("params") != ["prefix", "name"]:
        raise SystemExit(f"expected local function escaping closure params, got {local_function_source}")

    body_local_escaping = [
        f for f in patch["functions"]
        if f.get("member_name") == "bodyLocalEscapingGreeting"
    ]
    if len(body_local_escaping) != 1:
        raise SystemExit(f"expected one bodyLocalEscapingGreeting inventory entry, got {body_local_escaping}")
    body_local_source = body_local_escaping[0].get("bytecode_source")
    if not isinstance(body_local_source, dict):
        raise SystemExit(f"body-local escaping closure must produce bytecode source: {body_local_escaping[0]}")
    if body_local_escaping[0].get("unsupported_reasons") != []:
        raise SystemExit(f"body-local escaping closure should now be supported, got {body_local_escaping[0]}")
    if body_local_source.get("body", {}).get("let", {}).get("body", {}).get("make_closure") is None:
        raise SystemExit(f"expected body-local escaping closure make_closure source, got {body_local_source}")
    extra_functions = body_local_source.get("extra_functions", [])
    if len(extra_functions) != 1 or extra_functions[0].get("params") != ["prefix", "name"]:
        raise SystemExit(f"expected body-local escaping closure params, got {body_local_source}")
    if extra_functions[0].get("body", {}).get("let", {}).get("locals") is None:
        raise SystemExit(f"expected body-local escaping closure body let, got {body_local_source}")

    try_catch_escaping = [
        f for f in patch["functions"]
        if f.get("member_name") == "tryCatchEscapingGreeting"
    ]
    if len(try_catch_escaping) != 1:
        raise SystemExit(f"expected one tryCatchEscapingGreeting inventory entry, got {try_catch_escaping}")
    try_catch_source = try_catch_escaping[0].get("bytecode_source")
    if not isinstance(try_catch_source, dict):
        raise SystemExit(f"try/catch escaping closure must produce bytecode source: {try_catch_escaping[0]}")
    if try_catch_escaping[0].get("unsupported_reasons") != []:
        raise SystemExit(f"try/catch escaping closure should now be supported, got {try_catch_escaping[0]}")
    if try_catch_source.get("body", {}).get("let", {}).get("body", {}).get("make_closure") is None:
        raise SystemExit(f"expected try/catch escaping closure make_closure source, got {try_catch_source}")
    extra_functions = try_catch_source.get("extra_functions", [])
    if len(extra_functions) != 1 or extra_functions[0].get("params") != ["prefix", "fail"]:
        raise SystemExit(f"expected try/catch escaping closure params, got {try_catch_source}")
    if extra_functions[0].get("body", {}).get("try_catch") is None:
        raise SystemExit(f"expected try/catch escaping closure body try_catch, got {try_catch_source}")

    dynamic_call_escaping = [
        f for f in patch["functions"]
        if f.get("member_name") == "dynamicCallEscapingGreeting"
    ]
    if len(dynamic_call_escaping) != 1:
        raise SystemExit(f"expected one dynamicCallEscapingGreeting inventory entry, got {dynamic_call_escaping}")
    dynamic_call_source = dynamic_call_escaping[0].get("bytecode_source")
    if not isinstance(dynamic_call_source, dict):
        raise SystemExit(f"dynamic-call escaping closure must produce bytecode source: {dynamic_call_escaping[0]}")
    if dynamic_call_escaping[0].get("unsupported_reasons") != []:
        raise SystemExit(f"dynamic-call escaping closure should now be supported, got {dynamic_call_escaping[0]}")
    if dynamic_call_source.get("body", {}).get("let", {}).get("body", {}).get("make_closure") is None:
        raise SystemExit(f"expected dynamic-call escaping closure make_closure source, got {dynamic_call_source}")
    extra_functions = dynamic_call_source.get("extra_functions", [])
    if len(extra_functions) != 1 or extra_functions[0].get("params") != ["greeter", "name", "suffix"]:
        raise SystemExit(f"expected dynamic-call escaping closure params, got {dynamic_call_source}")
    if extra_functions[0].get("body", {}).get("call_dynamic") is None:
        raise SystemExit(f"expected dynamic-call escaping closure body call_dynamic, got {dynamic_call_source}")

    logical_escaping = [
        f for f in patch["functions"]
        if f.get("member_name") == "logicalEscapingGreeting"
    ]
    if len(logical_escaping) != 1:
        raise SystemExit(f"expected one logicalEscapingGreeting inventory entry, got {logical_escaping}")
    logical_source = logical_escaping[0].get("bytecode_source")
    if not isinstance(logical_source, dict):
        raise SystemExit(f"logical escaping closure must produce bytecode source: {logical_escaping[0]}")
    if logical_escaping[0].get("unsupported_reasons") != []:
        raise SystemExit(f"logical escaping closure should now be supported, got {logical_escaping[0]}")
    if logical_source.get("body", {}).get("let", {}).get("body", {}).get("make_closure") is None:
        raise SystemExit(f"expected logical escaping closure make_closure source, got {logical_source}")
    extra_functions = logical_source.get("extra_functions", [])
    if len(extra_functions) != 1 or extra_functions[0].get("params") != ["name", "prefix", "enabled", "premium"]:
        raise SystemExit(f"expected logical escaping closure params, got {logical_source}")
    if extra_functions[0].get("body", {}).get("conditional") is None:
        raise SystemExit(f"expected logical escaping closure body conditional, got {logical_source}")

    if_else_escaping = [
        f for f in patch["functions"]
        if f.get("member_name") == "ifElseEscapingGreeting"
    ]
    if len(if_else_escaping) != 1:
        raise SystemExit(f"expected one ifElseEscapingGreeting inventory entry, got {if_else_escaping}")
    if_else_source = if_else_escaping[0].get("bytecode_source")
    if not isinstance(if_else_source, dict):
        raise SystemExit(f"if/else escaping closure must produce bytecode source: {if_else_escaping[0]}")
    if if_else_escaping[0].get("unsupported_reasons") != []:
        raise SystemExit(f"if/else escaping closure should now be supported, got {if_else_escaping[0]}")
    if if_else_source.get("body", {}).get("let", {}).get("body", {}).get("make_closure") is None:
        raise SystemExit(f"expected if/else escaping closure make_closure source, got {if_else_source}")
    extra_functions = if_else_source.get("extra_functions", [])
    if len(extra_functions) != 1 or extra_functions[0].get("params") != ["prefix", "name", "enabled"]:
        raise SystemExit(f"expected if/else escaping closure params, got {if_else_source}")
    if extra_functions[0].get("body", {}).get("conditional") is None:
        raise SystemExit(f"expected if/else escaping closure body conditional, got {if_else_source}")

    body_local_if_else_escaping = [
        f for f in patch["functions"]
        if f.get("member_name") == "bodyLocalIfElseEscapingGreeting"
    ]
    if len(body_local_if_else_escaping) != 1:
        raise SystemExit(f"expected one bodyLocalIfElseEscapingGreeting inventory entry, got {body_local_if_else_escaping}")
    body_local_if_else_source = body_local_if_else_escaping[0].get("bytecode_source")
    if not isinstance(body_local_if_else_source, dict):
        raise SystemExit(f"body-local if/else escaping closure must produce bytecode source: {body_local_if_else_escaping[0]}")
    if body_local_if_else_escaping[0].get("unsupported_reasons") != []:
        raise SystemExit(f"body-local if/else escaping closure should now be supported, got {body_local_if_else_escaping[0]}")
    if body_local_if_else_source.get("body", {}).get("let", {}).get("body", {}).get("make_closure") is None:
        raise SystemExit(f"expected body-local if/else escaping closure make_closure source, got {body_local_if_else_source}")
    extra_functions = body_local_if_else_source.get("extra_functions", [])
    if len(extra_functions) != 1 or extra_functions[0].get("params") != ["prefix", "name", "enabled"]:
        raise SystemExit(f"expected body-local if/else escaping closure params, got {body_local_if_else_source}")
    closure_body = extra_functions[0].get("body", {})
    if closure_body.get("let", {}).get("body", {}).get("conditional") is None:
        raise SystemExit(f"expected body-local if/else escaping closure body let+conditional, got {body_local_if_else_source}")

    branch_local_if_else_escaping = [
        f for f in patch["functions"]
        if f.get("member_name") == "branchLocalIfElseEscapingGreeting"
    ]
    if len(branch_local_if_else_escaping) != 1:
        raise SystemExit(f"expected one branchLocalIfElseEscapingGreeting inventory entry, got {branch_local_if_else_escaping}")
    branch_local_if_else_source = branch_local_if_else_escaping[0].get("bytecode_source")
    if not isinstance(branch_local_if_else_source, dict):
        raise SystemExit(f"branch-local if/else escaping closure must produce bytecode source: {branch_local_if_else_escaping[0]}")
    if branch_local_if_else_escaping[0].get("unsupported_reasons") != []:
        raise SystemExit(f"branch-local if/else escaping closure should now be supported, got {branch_local_if_else_escaping[0]}")
    if branch_local_if_else_source.get("body", {}).get("let", {}).get("body", {}).get("make_closure") is None:
        raise SystemExit(f"expected branch-local if/else escaping closure make_closure source, got {branch_local_if_else_source}")
    extra_functions = branch_local_if_else_source.get("extra_functions", [])
    if len(extra_functions) != 1 or extra_functions[0].get("params") != ["prefix", "name", "enabled"]:
        raise SystemExit(f"expected branch-local if/else escaping closure params, got {branch_local_if_else_source}")
    conditional = extra_functions[0].get("body", {}).get("conditional", {})
    if conditional.get("then", {}).get("let") is None or conditional.get("else", {}).get("let") is None:
        raise SystemExit(f"expected branch-local if/else escaping closure branch lets, got {branch_local_if_else_source}")

