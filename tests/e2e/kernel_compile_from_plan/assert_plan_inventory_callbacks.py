def assert_inventory_callback_sources(patch_by_member):
    use_callback = patch_by_member.get("useCallback")
    if use_callback is None:
        raise SystemExit("missing inventory entry for useCallback")
    use_callback_source = use_callback.get("bytecode_source")
    if not isinstance(use_callback_source, dict):
        raise SystemExit(f"useCallback should produce bytecode source: {use_callback}")
    if use_callback.get("unsupported_reasons") != []:
        raise SystemExit(f"useCallback should now be supported, got {use_callback}")
    use_callback_call = use_callback_source.get("body", {}).get("call_closure", {})
    if (
        use_callback_call.get("closure", {}).get("arg") != "callback"
        or use_callback_call.get("args") != []
    ):
        raise SystemExit(f"expected useCallback direct parameter closure call source, got {use_callback_source}")

    direct_callback = patch_by_member.get("directCallbackValue")
    if direct_callback is None:
        raise SystemExit("missing inventory entry for directCallbackValue")
    direct_callback_source = direct_callback.get("bytecode_source")
    if not isinstance(direct_callback_source, dict):
        raise SystemExit(f"directCallbackValue should produce bytecode source: {direct_callback}")
    direct_callback_concat = direct_callback_source.get("body", {}).get("concat", [])
    direct_callback_call = direct_callback_concat[0].get("call_closure", {}) if direct_callback_concat else {}
    if (
        direct_callback.get("unsupported_reasons") != []
        or direct_callback_call.get("closure", {}).get("arg") != "callback"
        or direct_callback_call.get("args") != []
        or direct_callback_concat[1].get("string") != " patched-direct"
    ):
        raise SystemExit(f"expected directCallbackValue call_closure concat source, got {direct_callback_source}")

    direct_callback_arg = patch_by_member.get("directCallbackArg")
    if direct_callback_arg is None:
        raise SystemExit("missing inventory entry for directCallbackArg")
    direct_callback_arg_source = direct_callback_arg.get("bytecode_source")
    if not isinstance(direct_callback_arg_source, dict):
        raise SystemExit(f"directCallbackArg should produce bytecode source: {direct_callback_arg}")
    direct_callback_arg_concat = direct_callback_arg_source.get("body", {}).get("concat", [])
    direct_callback_arg_call = direct_callback_arg_concat[0].get("call_closure", {}) if direct_callback_arg_concat else {}
    if (
        direct_callback_arg.get("unsupported_reasons") != []
        or direct_callback_arg_call.get("closure", {}).get("arg") != "callback"
        or direct_callback_arg_call.get("args") != [{"arg": "value"}]
        or direct_callback_arg_concat[1].get("string") != " patched-arg"
    ):
        raise SystemExit(f"expected directCallbackArg positional call_closure source, got {direct_callback_arg_source}")

    direct_callback_named = patch_by_member.get("directCallbackNamed")
    if direct_callback_named is None:
        raise SystemExit("missing inventory entry for directCallbackNamed")
    direct_callback_named_source = direct_callback_named.get("bytecode_source")
    if not isinstance(direct_callback_named_source, dict):
        raise SystemExit(f"directCallbackNamed should produce bytecode source: {direct_callback_named}")
    direct_callback_named_concat = direct_callback_named_source.get("body", {}).get("concat", [])
    direct_callback_named_call = (
        direct_callback_named_concat[0].get("call_closure", {}) if direct_callback_named_concat else {}
    )
    if (
        direct_callback_named.get("unsupported_reasons") != []
        or direct_callback_named_call.get("closure", {}).get("arg") != "callback"
        or direct_callback_named_call.get("args") != []
        or direct_callback_named_call.get("named_args") != [{"name": "value", "value": {"arg": "value"}}]
        or direct_callback_named_concat[1].get("string") != " patched-named"
    ):
        raise SystemExit(f"expected directCallbackNamed named call_closure source, got {direct_callback_named_source}")

    direct_callback_mixed = patch_by_member.get("directCallbackMixed")
    if direct_callback_mixed is None:
        raise SystemExit("missing inventory entry for directCallbackMixed")
    direct_callback_mixed_source = direct_callback_mixed.get("bytecode_source")
    if not isinstance(direct_callback_mixed_source, dict):
        raise SystemExit(f"directCallbackMixed should produce bytecode source: {direct_callback_mixed}")
    direct_callback_mixed_concat = direct_callback_mixed_source.get("body", {}).get("concat", [])
    direct_callback_mixed_call = (
        direct_callback_mixed_concat[0].get("call_closure", {}) if direct_callback_mixed_concat else {}
    )
    if (
        direct_callback_mixed.get("unsupported_reasons") != []
        or direct_callback_mixed_call.get("closure", {}).get("arg") != "callback"
        or direct_callback_mixed_call.get("args") != [{"arg": "value"}]
        or direct_callback_mixed_call.get("named_args") != [{"name": "suffix", "value": {"arg": "suffix"}}]
        or direct_callback_mixed_concat[1].get("string") != " patched-mixed"
    ):
        raise SystemExit(f"expected directCallbackMixed mixed call_closure source, got {direct_callback_mixed_source}")
