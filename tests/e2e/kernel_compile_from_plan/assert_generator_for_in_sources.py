def assert_generator_for_in_sources(patch_by_member):
    sync_generated_for_in = patch_by_member.get("syncGeneratedForIn", {}).get("bytecode_source", {})
    sync_for_items = sync_generated_for_in.get("body", {}).get("seq", [])
    if (
        sync_generated_for_in.get("async_kind") != "sync_star"
        or len(sync_for_items) != 2
        or sync_for_items[0].get("let", {}).get("locals", [{}])[0].get("value", {}).get("string") != "patched-iterable-a"
        or sync_for_items[0].get("let", {}).get("body", {}).get("yield", {}).get("let_local") != 0
        or sync_for_items[1].get("let", {}).get("locals", [{}])[0].get("value", {}).get("string") != "patched-iterable-b"
        or sync_for_items[1].get("let", {}).get("body", {}).get("yield", {}).get("let_local") != 0
    ):
        raise SystemExit(f"expected syncGeneratedForIn unrolled list-literal source, got {sync_generated_for_in}")
    async_generated_for_in = patch_by_member.get("asyncGeneratedForIn", {}).get("bytecode_source", {})
    async_for_items = async_generated_for_in.get("body", {}).get("seq", [])
    if (
        async_generated_for_in.get("async_kind") != "async_star"
        or len(async_for_items) != 2
        or async_for_items[0].get("let", {}).get("locals", [{}])[0].get("value", {}).get("string") != "patched-stream-a"
        or async_for_items[0].get("let", {}).get("body", {}).get("yield", {}).get("let_local") != 0
        or async_for_items[1].get("let", {}).get("locals", [{}])[0].get("value", {}).get("string") != "patched-stream-b"
        or async_for_items[1].get("let", {}).get("body", {}).get("yield", {}).get("let_local") != 0
    ):
        raise SystemExit(f"expected asyncGeneratedForIn unrolled list-literal source, got {async_generated_for_in}")
    sync_generated_for_in_break = patch_by_member.get("syncGeneratedForInBreak", {}).get("bytecode_source", {})
    sync_for_break_let = sync_generated_for_in_break.get("body", {}).get("let", {})
    sync_for_break_for = sync_for_break_let.get("body", {}).get("yield_for_in", {})
    if (
        sync_generated_for_in_break.get("async_kind") != "sync_star"
        or sync_for_break_let.get("locals", [{}])[0].get("name") != "prefix"
        or len(sync_for_break_for.get("source", {}).get("list", [])) != 3
        or sync_for_break_for.get("local", {}).get("name") != "value"
        or sync_for_break_for.get("before_break", {}).get("yield", {}).get("concat") is None
        or sync_for_break_for.get("break_condition", {}).get("op") != "=="
        or sync_for_break_for.get("body", {}).get("yield", {}).get("concat") is None
    ):
        raise SystemExit(f"expected syncGeneratedForInBreak static list yield_for_in source, got {sync_generated_for_in_break}")
    async_generated_for_in_break = patch_by_member.get("asyncGeneratedForInBreak", {}).get("bytecode_source", {})
    async_for_break_let = async_generated_for_in_break.get("body", {}).get("let", {})
    async_for_break_for = async_for_break_let.get("body", {}).get("yield_for_in", {})
    if (
        async_generated_for_in_break.get("async_kind") != "async_star"
        or async_for_break_let.get("locals", [{}])[0].get("name") != "prefix"
        or len(async_for_break_for.get("source", {}).get("list", [])) != 3
        or async_for_break_for.get("local", {}).get("name") != "value"
        or async_for_break_for.get("before_break", {}).get("yield", {}).get("concat") is None
        or async_for_break_for.get("break_condition", {}).get("op") != "=="
        or async_for_break_for.get("body", {}).get("yield", {}).get("concat") is None
    ):
        raise SystemExit(f"expected asyncGeneratedForInBreak static list yield_for_in source, got {async_generated_for_in_break}")
    sync_generated_for_in_break_first = patch_by_member.get("syncGeneratedForInBreakFirst", {}).get("bytecode_source", {})
    sync_for_break_first_let = sync_generated_for_in_break_first.get("body", {}).get("let", {})
    sync_for_break_first_for = sync_for_break_first_let.get("body", {}).get("yield_for_in", {})
    if (
        sync_generated_for_in_break_first.get("async_kind") != "sync_star"
        or sync_for_break_first_let.get("locals", [{}])[0].get("name") != "prefix"
        or len(sync_for_break_first_for.get("source", {}).get("list", [])) != 3
        or sync_for_break_first_for.get("local", {}).get("name") != "value"
        or sync_for_break_first_for.get("break_condition", {}).get("op") != "=="
        or sync_for_break_first_for.get("body", {}).get("yield", {}).get("concat") is None
    ):
        raise SystemExit(f"expected syncGeneratedForInBreakFirst static list yield_for_in source, got {sync_generated_for_in_break_first}")
    async_generated_for_in_break_first = patch_by_member.get("asyncGeneratedForInBreakFirst", {}).get("bytecode_source", {})
    async_for_break_first_let = async_generated_for_in_break_first.get("body", {}).get("let", {})
    async_for_break_first_for = async_for_break_first_let.get("body", {}).get("yield_for_in", {})
    if (
        async_generated_for_in_break_first.get("async_kind") != "async_star"
        or async_for_break_first_let.get("locals", [{}])[0].get("name") != "prefix"
        or len(async_for_break_first_for.get("source", {}).get("list", [])) != 3
        or async_for_break_first_for.get("local", {}).get("name") != "value"
        or async_for_break_first_for.get("break_condition", {}).get("op") != "=="
        or async_for_break_first_for.get("body", {}).get("yield", {}).get("concat") is None
    ):
        raise SystemExit(f"expected asyncGeneratedForInBreakFirst static list yield_for_in source, got {async_generated_for_in_break_first}")
    sync_generated_for_in_continue = patch_by_member.get("syncGeneratedForInContinue", {}).get("bytecode_source", {})
    sync_for_continue_let = sync_generated_for_in_continue.get("body", {}).get("let", {})
    sync_for_continue_for = sync_for_continue_let.get("body", {}).get("yield_for_in", {})
    sync_for_continue_body = sync_for_continue_for.get("body", {}).get("conditional", {})
    if (
        sync_generated_for_in_continue.get("async_kind") != "sync_star"
        or sync_for_continue_let.get("locals", [{}])[0].get("name") != "prefix"
        or len(sync_for_continue_for.get("source", {}).get("list", [])) != 3
        or sync_for_continue_for.get("local", {}).get("name") != "value"
        or sync_for_continue_body.get("condition", {}).get("op") != "=="
        or sync_for_continue_body.get("then", {}).get("null") is not True
        or sync_for_continue_body.get("else", {}).get("yield", {}).get("concat") is None
    ):
        raise SystemExit(f"expected syncGeneratedForInContinue static list yield_for_in source, got {sync_generated_for_in_continue}")
    async_generated_for_in_continue = patch_by_member.get("asyncGeneratedForInContinue", {}).get("bytecode_source", {})
    async_for_continue_let = async_generated_for_in_continue.get("body", {}).get("let", {})
    async_for_continue_for = async_for_continue_let.get("body", {}).get("yield_for_in", {})
    async_for_continue_body = async_for_continue_for.get("body", {}).get("conditional", {})
    if (
        async_generated_for_in_continue.get("async_kind") != "async_star"
        or async_for_continue_let.get("locals", [{}])[0].get("name") != "prefix"
        or len(async_for_continue_for.get("source", {}).get("list", [])) != 3
        or async_for_continue_for.get("local", {}).get("name") != "value"
        or async_for_continue_body.get("condition", {}).get("op") != "=="
        or async_for_continue_body.get("then", {}).get("null") is not True
        or async_for_continue_body.get("else", {}).get("yield", {}).get("concat") is None
    ):
        raise SystemExit(f"expected asyncGeneratedForInContinue static list yield_for_in source, got {async_generated_for_in_continue}")
    sync_generated_for_in_continue_after_yield = patch_by_member.get("syncGeneratedForInContinueAfterYield", {}).get("bytecode_source", {})
    sync_for_continue_after_let = sync_generated_for_in_continue_after_yield.get("body", {}).get("let", {})
    sync_for_continue_after_for = sync_for_continue_after_let.get("body", {}).get("yield_for_in", {})
    sync_for_continue_after_seq = sync_for_continue_after_for.get("body", {}).get("seq", [])
    if (
        sync_generated_for_in_continue_after_yield.get("async_kind") != "sync_star"
        or sync_for_continue_after_let.get("locals", [{}])[0].get("name") != "prefix"
        or len(sync_for_continue_after_for.get("source", {}).get("list", [])) != 3
        or sync_for_continue_after_for.get("local", {}).get("name") != "value"
        or len(sync_for_continue_after_seq) != 2
        or sync_for_continue_after_seq[0].get("yield", {}).get("concat") is None
        or sync_for_continue_after_seq[1].get("conditional", {}).get("condition", {}).get("op") != "=="
        or sync_for_continue_after_seq[1].get("conditional", {}).get("then", {}).get("null") is not True
        or sync_for_continue_after_seq[1].get("conditional", {}).get("else", {}).get("yield", {}).get("concat") is None
    ):
        raise SystemExit(f"expected syncGeneratedForInContinueAfterYield static list yield_for_in source, got {sync_generated_for_in_continue_after_yield}")
    async_generated_for_in_continue_after_yield = patch_by_member.get("asyncGeneratedForInContinueAfterYield", {}).get("bytecode_source", {})
    async_for_continue_after_let = async_generated_for_in_continue_after_yield.get("body", {}).get("let", {})
    async_for_continue_after_for = async_for_continue_after_let.get("body", {}).get("yield_for_in", {})
    async_for_continue_after_seq = async_for_continue_after_for.get("body", {}).get("seq", [])
    if (
        async_generated_for_in_continue_after_yield.get("async_kind") != "async_star"
        or async_for_continue_after_let.get("locals", [{}])[0].get("name") != "prefix"
        or len(async_for_continue_after_for.get("source", {}).get("list", [])) != 3
        or async_for_continue_after_for.get("local", {}).get("name") != "value"
        or len(async_for_continue_after_seq) != 2
        or async_for_continue_after_seq[0].get("yield", {}).get("concat") is None
        or async_for_continue_after_seq[1].get("conditional", {}).get("condition", {}).get("op") != "=="
        or async_for_continue_after_seq[1].get("conditional", {}).get("then", {}).get("null") is not True
        or async_for_continue_after_seq[1].get("conditional", {}).get("else", {}).get("yield", {}).get("concat") is None
    ):
        raise SystemExit(f"expected asyncGeneratedForInContinueAfterYield static list yield_for_in source, got {async_generated_for_in_continue_after_yield}")
    sync_generated_dynamic_for_in = patch_by_member.get("syncGeneratedDynamicForIn", {}).get("bytecode_source", {})
    sync_dynamic_seq = sync_generated_dynamic_for_in.get("body", {}).get("seq", [])
    sync_dynamic_for = sync_dynamic_seq[0].get("yield_for_in", {}) if sync_dynamic_seq else {}
    if (
        sync_generated_dynamic_for_in.get("async_kind") != "sync_star"
        or len(sync_dynamic_seq) != 2
        or sync_dynamic_for.get("source", {}).get("arg") != "extra"
        or sync_dynamic_seq[1].get("yield", {}).get("string") != "patched-iterable-dynamic-tail"
    ):
        raise SystemExit(f"expected syncGeneratedDynamicForIn dynamic yield_for_in source, got {sync_generated_dynamic_for_in}")
    async_generated_dynamic_for_in = patch_by_member.get("asyncGeneratedDynamicForIn", {}).get("bytecode_source", {})
    async_dynamic_seq = async_generated_dynamic_for_in.get("body", {}).get("seq", [])
    async_dynamic_for = async_dynamic_seq[0].get("yield_for_in", {}) if async_dynamic_seq else {}
    if (
        async_generated_dynamic_for_in.get("async_kind") != "async_star"
        or len(async_dynamic_seq) != 2
        or async_dynamic_for.get("source", {}).get("arg") != "extra"
        or async_dynamic_seq[1].get("yield", {}).get("string") != "patched-stream-dynamic-tail"
    ):
        raise SystemExit(f"expected asyncGeneratedDynamicForIn dynamic yield_for_in source, got {async_generated_dynamic_for_in}")
    sync_generated_dynamic_for_in_mapped = patch_by_member.get("syncGeneratedDynamicForInMapped", {}).get("bytecode_source", {})
    sync_dynamic_mapped_let = sync_generated_dynamic_for_in_mapped.get("body", {}).get("let", {})
    sync_dynamic_mapped_for = sync_dynamic_mapped_let.get("body", {}).get("yield_for_in", {})
    if (
        sync_generated_dynamic_for_in_mapped.get("async_kind") != "sync_star"
        or sync_dynamic_mapped_let.get("locals", [{}])[0].get("name") != "prefix"
        or sync_dynamic_mapped_for.get("source", {}).get("arg") != "extra"
        or sync_dynamic_mapped_for.get("local", {}).get("name") != "value"
        or sync_dynamic_mapped_for.get("body", {}).get("yield", {}).get("concat") is None
    ):
        raise SystemExit(f"expected syncGeneratedDynamicForInMapped mapped yield_for_in source, got {sync_generated_dynamic_for_in_mapped}")
    async_generated_dynamic_for_in_mapped = patch_by_member.get("asyncGeneratedDynamicForInMapped", {}).get("bytecode_source", {})
    async_dynamic_mapped_let = async_generated_dynamic_for_in_mapped.get("body", {}).get("let", {})
    async_dynamic_mapped_for = async_dynamic_mapped_let.get("body", {}).get("yield_for_in", {})
    if (
        async_generated_dynamic_for_in_mapped.get("async_kind") != "async_star"
        or async_dynamic_mapped_let.get("locals", [{}])[0].get("name") != "prefix"
        or async_dynamic_mapped_for.get("source", {}).get("arg") != "extra"
        or async_dynamic_mapped_for.get("local", {}).get("name") != "value"
        or async_dynamic_mapped_for.get("body", {}).get("yield", {}).get("concat") is None
    ):
        raise SystemExit(f"expected asyncGeneratedDynamicForInMapped mapped yield_for_in source, got {async_generated_dynamic_for_in_mapped}")
    sync_generated_dynamic_for_in_many = patch_by_member.get("syncGeneratedDynamicForInMany", {}).get("bytecode_source", {})
    sync_dynamic_many_let = sync_generated_dynamic_for_in_many.get("body", {}).get("let", {})
    sync_dynamic_many_for = sync_dynamic_many_let.get("body", {}).get("yield_for_in", {})
    sync_dynamic_many_body = sync_dynamic_many_for.get("body", {}).get("seq", [])
    if (
        sync_generated_dynamic_for_in_many.get("async_kind") != "sync_star"
        or sync_dynamic_many_let.get("locals", [{}])[0].get("name") != "prefix"
        or sync_dynamic_many_for.get("source", {}).get("arg") != "extra"
        or sync_dynamic_many_for.get("local", {}).get("name") != "value"
        or len(sync_dynamic_many_body) != 2
        or sync_dynamic_many_body[0].get("yield", {}).get("concat") is None
        or sync_dynamic_many_body[1].get("yield", {}).get("concat") is None
    ):
        raise SystemExit(f"expected syncGeneratedDynamicForInMany multi-yield source, got {sync_generated_dynamic_for_in_many}")
    async_generated_dynamic_for_in_many = patch_by_member.get("asyncGeneratedDynamicForInMany", {}).get("bytecode_source", {})
    async_dynamic_many_let = async_generated_dynamic_for_in_many.get("body", {}).get("let", {})
    async_dynamic_many_for = async_dynamic_many_let.get("body", {}).get("yield_for_in", {})
    async_dynamic_many_body = async_dynamic_many_for.get("body", {}).get("seq", [])
    if (
        async_generated_dynamic_for_in_many.get("async_kind") != "async_star"
        or async_dynamic_many_let.get("locals", [{}])[0].get("name") != "prefix"
        or async_dynamic_many_for.get("source", {}).get("arg") != "extra"
        or async_dynamic_many_for.get("local", {}).get("name") != "value"
        or len(async_dynamic_many_body) != 2
        or async_dynamic_many_body[0].get("yield", {}).get("concat") is None
        or async_dynamic_many_body[1].get("yield", {}).get("concat") is None
    ):
        raise SystemExit(f"expected asyncGeneratedDynamicForInMany multi-yield source, got {async_generated_dynamic_for_in_many}")
    sync_generated_dynamic_for_in_if = patch_by_member.get("syncGeneratedDynamicForInIf", {}).get("bytecode_source", {})
    sync_dynamic_if_let = sync_generated_dynamic_for_in_if.get("body", {}).get("let", {})
    sync_dynamic_if_for = sync_dynamic_if_let.get("body", {}).get("yield_for_in", {})
    sync_dynamic_if_body = sync_dynamic_if_for.get("body", {}).get("seq", [])
    if (
        sync_generated_dynamic_for_in_if.get("async_kind") != "sync_star"
        or sync_dynamic_if_let.get("locals", [{}])[0].get("name") != "prefix"
        or sync_dynamic_if_for.get("source", {}).get("arg") != "extra"
        or sync_dynamic_if_for.get("local", {}).get("name") != "value"
        or len(sync_dynamic_if_body) != 2
        or sync_dynamic_if_body[0].get("conditional", {}).get("condition", {}).get("op") != "=="
        or sync_dynamic_if_body[0].get("conditional", {}).get("then", {}).get("yield", {}).get("concat") is None
        or sync_dynamic_if_body[1].get("yield", {}).get("concat") is None
    ):
        raise SystemExit(f"expected syncGeneratedDynamicForInIf guarded source, got {sync_generated_dynamic_for_in_if}")
    async_generated_dynamic_for_in_if = patch_by_member.get("asyncGeneratedDynamicForInIf", {}).get("bytecode_source", {})
    async_dynamic_if_let = async_generated_dynamic_for_in_if.get("body", {}).get("let", {})
    async_dynamic_if_for = async_dynamic_if_let.get("body", {}).get("yield_for_in", {})
    async_dynamic_if_body = async_dynamic_if_for.get("body", {}).get("seq", [])
    if (
        async_generated_dynamic_for_in_if.get("async_kind") != "async_star"
        or async_dynamic_if_let.get("locals", [{}])[0].get("name") != "prefix"
        or async_dynamic_if_for.get("source", {}).get("arg") != "extra"
        or async_dynamic_if_for.get("local", {}).get("name") != "value"
        or len(async_dynamic_if_body) != 2
        or async_dynamic_if_body[0].get("conditional", {}).get("condition", {}).get("op") != "=="
        or async_dynamic_if_body[0].get("conditional", {}).get("then", {}).get("yield", {}).get("concat") is None
        or async_dynamic_if_body[1].get("yield", {}).get("concat") is None
    ):
        raise SystemExit(f"expected asyncGeneratedDynamicForInIf guarded source, got {async_generated_dynamic_for_in_if}")
    sync_generated_dynamic_for_in_ifelse = patch_by_member.get("syncGeneratedDynamicForInIfElse", {}).get("bytecode_source", {})
    sync_dynamic_ifelse_let = sync_generated_dynamic_for_in_ifelse.get("body", {}).get("let", {})
    sync_dynamic_ifelse_for = sync_dynamic_ifelse_let.get("body", {}).get("yield_for_in", {})
    sync_dynamic_ifelse_conditional = sync_dynamic_ifelse_for.get("body", {}).get("conditional", {})
    if (
        sync_generated_dynamic_for_in_ifelse.get("async_kind") != "sync_star"
        or sync_dynamic_ifelse_let.get("locals", [{}])[0].get("name") != "prefix"
        or sync_dynamic_ifelse_for.get("source", {}).get("arg") != "extra"
        or sync_dynamic_ifelse_for.get("local", {}).get("name") != "value"
        or sync_dynamic_ifelse_conditional.get("condition", {}).get("op") != "=="
        or sync_dynamic_ifelse_conditional.get("then", {}).get("yield", {}).get("concat") is None
        or sync_dynamic_ifelse_conditional.get("else", {}).get("yield", {}).get("concat") is None
    ):
        raise SystemExit(f"expected syncGeneratedDynamicForInIfElse if/else source, got {sync_generated_dynamic_for_in_ifelse}")
    async_generated_dynamic_for_in_ifelse = patch_by_member.get("asyncGeneratedDynamicForInIfElse", {}).get("bytecode_source", {})
    async_dynamic_ifelse_let = async_generated_dynamic_for_in_ifelse.get("body", {}).get("let", {})
    async_dynamic_ifelse_for = async_dynamic_ifelse_let.get("body", {}).get("yield_for_in", {})
    async_dynamic_ifelse_conditional = async_dynamic_ifelse_for.get("body", {}).get("conditional", {})
    if (
        async_generated_dynamic_for_in_ifelse.get("async_kind") != "async_star"
        or async_dynamic_ifelse_let.get("locals", [{}])[0].get("name") != "prefix"
        or async_dynamic_ifelse_for.get("source", {}).get("arg") != "extra"
        or async_dynamic_ifelse_for.get("local", {}).get("name") != "value"
        or async_dynamic_ifelse_conditional.get("condition", {}).get("op") != "=="
        or async_dynamic_ifelse_conditional.get("then", {}).get("yield", {}).get("concat") is None
        or async_dynamic_ifelse_conditional.get("else", {}).get("yield", {}).get("concat") is None
    ):
        raise SystemExit(f"expected asyncGeneratedDynamicForInIfElse if/else source, got {async_generated_dynamic_for_in_ifelse}")
    sync_generated_dynamic_for_in_local = patch_by_member.get("syncGeneratedDynamicForInLocal", {}).get("bytecode_source", {})
    sync_dynamic_local_let = sync_generated_dynamic_for_in_local.get("body", {}).get("let", {})
    sync_dynamic_local_for = sync_dynamic_local_let.get("body", {}).get("yield_for_in", {})
    sync_dynamic_local_body_let = sync_dynamic_local_for.get("body", {}).get("let", {})
    if (
        sync_generated_dynamic_for_in_local.get("async_kind") != "sync_star"
        or sync_dynamic_local_let.get("locals", [{}])[0].get("name") != "prefix"
        or sync_dynamic_local_for.get("source", {}).get("arg") != "extra"
        or sync_dynamic_local_for.get("local", {}).get("name") != "value"
        or sync_dynamic_local_body_let.get("locals", [{}])[0].get("name") != "marker"
        or sync_dynamic_local_body_let.get("body", {}).get("yield", {}).get("let_local") != 2
    ):
        raise SystemExit(f"expected syncGeneratedDynamicForInLocal local body source, got {sync_generated_dynamic_for_in_local}")
    async_generated_dynamic_for_in_local = patch_by_member.get("asyncGeneratedDynamicForInLocal", {}).get("bytecode_source", {})
    async_dynamic_local_let = async_generated_dynamic_for_in_local.get("body", {}).get("let", {})
    async_dynamic_local_for = async_dynamic_local_let.get("body", {}).get("yield_for_in", {})
    async_dynamic_local_body_let = async_dynamic_local_for.get("body", {}).get("let", {})
    if (
        async_generated_dynamic_for_in_local.get("async_kind") != "async_star"
        or async_dynamic_local_let.get("locals", [{}])[0].get("name") != "prefix"
        or async_dynamic_local_for.get("source", {}).get("arg") != "extra"
        or async_dynamic_local_for.get("local", {}).get("name") != "value"
        or async_dynamic_local_body_let.get("locals", [{}])[0].get("name") != "marker"
        or async_dynamic_local_body_let.get("body", {}).get("yield", {}).get("let_local") != 2
    ):
        raise SystemExit(f"expected asyncGeneratedDynamicForInLocal local body source, got {async_generated_dynamic_for_in_local}")
    sync_generated_dynamic_for_in_continue = patch_by_member.get("syncGeneratedDynamicForInContinue", {}).get("bytecode_source", {})
    sync_dynamic_continue_let = sync_generated_dynamic_for_in_continue.get("body", {}).get("let", {})
    sync_dynamic_continue_for = sync_dynamic_continue_let.get("body", {}).get("yield_for_in", {})
    sync_dynamic_continue_conditional = sync_dynamic_continue_for.get("body", {}).get("conditional", {})
    if (
        sync_generated_dynamic_for_in_continue.get("async_kind") != "sync_star"
        or sync_dynamic_continue_let.get("locals", [{}])[0].get("name") != "prefix"
        or sync_dynamic_continue_for.get("source", {}).get("arg") != "extra"
        or sync_dynamic_continue_for.get("local", {}).get("name") != "value"
        or sync_dynamic_continue_conditional.get("condition", {}).get("op") != "=="
        or sync_dynamic_continue_conditional.get("then", {}).get("null") is not True
        or sync_dynamic_continue_conditional.get("else", {}).get("yield", {}).get("concat") is None
    ):
        raise SystemExit(f"expected syncGeneratedDynamicForInContinue guard-continue source, got {sync_generated_dynamic_for_in_continue}")
    async_generated_dynamic_for_in_continue = patch_by_member.get("asyncGeneratedDynamicForInContinue", {}).get("bytecode_source", {})
    async_dynamic_continue_let = async_generated_dynamic_for_in_continue.get("body", {}).get("let", {})
    async_dynamic_continue_for = async_dynamic_continue_let.get("body", {}).get("yield_for_in", {})
    async_dynamic_continue_conditional = async_dynamic_continue_for.get("body", {}).get("conditional", {})
    if (
        async_generated_dynamic_for_in_continue.get("async_kind") != "async_star"
        or async_dynamic_continue_let.get("locals", [{}])[0].get("name") != "prefix"
        or async_dynamic_continue_for.get("source", {}).get("arg") != "extra"
        or async_dynamic_continue_for.get("local", {}).get("name") != "value"
        or async_dynamic_continue_conditional.get("condition", {}).get("op") != "=="
        or async_dynamic_continue_conditional.get("then", {}).get("null") is not True
        or async_dynamic_continue_conditional.get("else", {}).get("yield", {}).get("concat") is None
    ):
        raise SystemExit(f"expected asyncGeneratedDynamicForInContinue guard-continue source, got {async_generated_dynamic_for_in_continue}")
    sync_generated_dynamic_for_in_continue_after_yield = patch_by_member.get("syncGeneratedDynamicForInContinueAfterYield", {}).get("bytecode_source", {})
    sync_dynamic_continue_after_let = sync_generated_dynamic_for_in_continue_after_yield.get("body", {}).get("let", {})
    sync_dynamic_continue_after_for = sync_dynamic_continue_after_let.get("body", {}).get("yield_for_in", {})
    sync_dynamic_continue_after_body = sync_dynamic_continue_after_for.get("body", {}).get("seq", [])
    sync_dynamic_continue_after_conditional = sync_dynamic_continue_after_body[1].get("conditional", {}) if len(sync_dynamic_continue_after_body) > 1 else {}
    if (
        sync_generated_dynamic_for_in_continue_after_yield.get("async_kind") != "sync_star"
        or sync_dynamic_continue_after_let.get("locals", [{}])[0].get("name") != "prefix"
        or sync_dynamic_continue_after_for.get("source", {}).get("arg") != "extra"
        or sync_dynamic_continue_after_for.get("local", {}).get("name") != "value"
        or sync_dynamic_continue_after_body[0].get("yield", {}).get("concat") is None
        or sync_dynamic_continue_after_conditional.get("condition", {}).get("op") != "=="
        or sync_dynamic_continue_after_conditional.get("then", {}).get("null") is not True
        or sync_dynamic_continue_after_conditional.get("else", {}).get("yield", {}).get("concat") is None
    ):
        raise SystemExit(f"expected syncGeneratedDynamicForInContinueAfterYield before-continue source, got {sync_generated_dynamic_for_in_continue_after_yield}")
    async_generated_dynamic_for_in_continue_after_yield = patch_by_member.get("asyncGeneratedDynamicForInContinueAfterYield", {}).get("bytecode_source", {})
    async_dynamic_continue_after_let = async_generated_dynamic_for_in_continue_after_yield.get("body", {}).get("let", {})
    async_dynamic_continue_after_for = async_dynamic_continue_after_let.get("body", {}).get("yield_for_in", {})
    async_dynamic_continue_after_body = async_dynamic_continue_after_for.get("body", {}).get("seq", [])
    async_dynamic_continue_after_conditional = async_dynamic_continue_after_body[1].get("conditional", {}) if len(async_dynamic_continue_after_body) > 1 else {}
    if (
        async_generated_dynamic_for_in_continue_after_yield.get("async_kind") != "async_star"
        or async_dynamic_continue_after_let.get("locals", [{}])[0].get("name") != "prefix"
        or async_dynamic_continue_after_for.get("source", {}).get("arg") != "extra"
        or async_dynamic_continue_after_for.get("local", {}).get("name") != "value"
        or async_dynamic_continue_after_body[0].get("yield", {}).get("concat") is None
        or async_dynamic_continue_after_conditional.get("condition", {}).get("op") != "=="
        or async_dynamic_continue_after_conditional.get("then", {}).get("null") is not True
        or async_dynamic_continue_after_conditional.get("else", {}).get("yield", {}).get("concat") is None
    ):
        raise SystemExit(f"expected asyncGeneratedDynamicForInContinueAfterYield before-continue source, got {async_generated_dynamic_for_in_continue_after_yield}")
    sync_generated_dynamic_for_in_break = patch_by_member.get("syncGeneratedDynamicForInBreak", {}).get("bytecode_source", {})
    sync_dynamic_break_let = sync_generated_dynamic_for_in_break.get("body", {}).get("let", {})
    sync_dynamic_break_for = sync_dynamic_break_let.get("body", {}).get("yield_for_in", {})
    if (
        sync_generated_dynamic_for_in_break.get("async_kind") != "sync_star"
        or sync_dynamic_break_let.get("locals", [{}])[0].get("name") != "prefix"
        or sync_dynamic_break_for.get("source", {}).get("arg") != "extra"
        or sync_dynamic_break_for.get("local", {}).get("name") != "value"
        or sync_dynamic_break_for.get("break_condition", {}).get("op") != "=="
        or sync_dynamic_break_for.get("body", {}).get("yield", {}).get("concat") is None
    ):
        raise SystemExit(f"expected syncGeneratedDynamicForInBreak guard-break source, got {sync_generated_dynamic_for_in_break}")
    async_generated_dynamic_for_in_break = patch_by_member.get("asyncGeneratedDynamicForInBreak", {}).get("bytecode_source", {})
    async_dynamic_break_let = async_generated_dynamic_for_in_break.get("body", {}).get("let", {})
    async_dynamic_break_for = async_dynamic_break_let.get("body", {}).get("yield_for_in", {})
    if (
        async_generated_dynamic_for_in_break.get("async_kind") != "async_star"
        or async_dynamic_break_let.get("locals", [{}])[0].get("name") != "prefix"
        or async_dynamic_break_for.get("source", {}).get("arg") != "extra"
        or async_dynamic_break_for.get("local", {}).get("name") != "value"
        or async_dynamic_break_for.get("break_condition", {}).get("op") != "=="
        or async_dynamic_break_for.get("body", {}).get("yield", {}).get("concat") is None
    ):
        raise SystemExit(f"expected asyncGeneratedDynamicForInBreak guard-break source, got {async_generated_dynamic_for_in_break}")
    sync_generated_dynamic_for_in_break_after_yield = patch_by_member.get("syncGeneratedDynamicForInBreakAfterYield", {}).get("bytecode_source", {})
    sync_dynamic_break_after_let = sync_generated_dynamic_for_in_break_after_yield.get("body", {}).get("let", {})
    sync_dynamic_break_after_for = sync_dynamic_break_after_let.get("body", {}).get("yield_for_in", {})
    if (
        sync_generated_dynamic_for_in_break_after_yield.get("async_kind") != "sync_star"
        or sync_dynamic_break_after_let.get("locals", [{}])[0].get("name") != "prefix"
        or sync_dynamic_break_after_for.get("source", {}).get("arg") != "extra"
        or sync_dynamic_break_after_for.get("local", {}).get("name") != "value"
        or sync_dynamic_break_after_for.get("before_break", {}).get("yield", {}).get("concat") is None
        or sync_dynamic_break_after_for.get("break_condition", {}).get("op") != "=="
        or sync_dynamic_break_after_for.get("body", {}).get("yield", {}).get("concat") is None
    ):
        raise SystemExit(f"expected syncGeneratedDynamicForInBreakAfterYield before-break source, got {sync_generated_dynamic_for_in_break_after_yield}")
    async_generated_dynamic_for_in_break_after_yield = patch_by_member.get("asyncGeneratedDynamicForInBreakAfterYield", {}).get("bytecode_source", {})
    async_dynamic_break_after_let = async_generated_dynamic_for_in_break_after_yield.get("body", {}).get("let", {})
    async_dynamic_break_after_for = async_dynamic_break_after_let.get("body", {}).get("yield_for_in", {})
    if (
        async_generated_dynamic_for_in_break_after_yield.get("async_kind") != "async_star"
        or async_dynamic_break_after_let.get("locals", [{}])[0].get("name") != "prefix"
        or async_dynamic_break_after_for.get("source", {}).get("arg") != "extra"
        or async_dynamic_break_after_for.get("local", {}).get("name") != "value"
        or async_dynamic_break_after_for.get("before_break", {}).get("yield", {}).get("concat") is None
        or async_dynamic_break_after_for.get("break_condition", {}).get("op") != "=="
        or async_dynamic_break_after_for.get("body", {}).get("yield", {}).get("concat") is None
    ):
        raise SystemExit(f"expected asyncGeneratedDynamicForInBreakAfterYield before-break source, got {async_generated_dynamic_for_in_break_after_yield}")
    sync_generated_dynamic_for_in_break_at_end = patch_by_member.get("syncGeneratedDynamicForInBreakAtEnd", {}).get("bytecode_source", {})
    sync_dynamic_break_end_let = sync_generated_dynamic_for_in_break_at_end.get("body", {}).get("let", {})
    sync_dynamic_break_end_for = sync_dynamic_break_end_let.get("body", {}).get("yield_for_in", {})
    if (
        sync_generated_dynamic_for_in_break_at_end.get("async_kind") != "sync_star"
        or sync_dynamic_break_end_let.get("locals", [{}])[0].get("name") != "prefix"
        or sync_dynamic_break_end_for.get("source", {}).get("arg") != "extra"
        or sync_dynamic_break_end_for.get("local", {}).get("name") != "value"
        or sync_dynamic_break_end_for.get("before_break", {}).get("yield", {}).get("concat") is None
        or sync_dynamic_break_end_for.get("break_condition", {}).get("op") != "=="
        or sync_dynamic_break_end_for.get("body", {}).get("null") is not True
    ):
        raise SystemExit(f"expected syncGeneratedDynamicForInBreakAtEnd before-break null-tail source, got {sync_generated_dynamic_for_in_break_at_end}")
    async_generated_dynamic_for_in_break_at_end = patch_by_member.get("asyncGeneratedDynamicForInBreakAtEnd", {}).get("bytecode_source", {})
    async_dynamic_break_end_let = async_generated_dynamic_for_in_break_at_end.get("body", {}).get("let", {})
    async_dynamic_break_end_for = async_dynamic_break_end_let.get("body", {}).get("yield_for_in", {})
    if (
        async_generated_dynamic_for_in_break_at_end.get("async_kind") != "async_star"
        or async_dynamic_break_end_let.get("locals", [{}])[0].get("name") != "prefix"
        or async_dynamic_break_end_for.get("source", {}).get("arg") != "extra"
        or async_dynamic_break_end_for.get("local", {}).get("name") != "value"
        or async_dynamic_break_end_for.get("before_break", {}).get("yield", {}).get("concat") is None
        or async_dynamic_break_end_for.get("break_condition", {}).get("op") != "=="
        or async_dynamic_break_end_for.get("body", {}).get("null") is not True
    ):
        raise SystemExit(f"expected asyncGeneratedDynamicForInBreakAtEnd before-break null-tail source, got {async_generated_dynamic_for_in_break_at_end}")
    sync_generated_dynamic_for_in_continue_then_break = patch_by_member.get("syncGeneratedDynamicForInContinueThenBreak", {}).get("bytecode_source", {})
    sync_dynamic_continue_break_let = sync_generated_dynamic_for_in_continue_then_break.get("body", {}).get("let", {})
    sync_dynamic_continue_break_for = sync_dynamic_continue_break_let.get("body", {}).get("yield_for_in", {})
    sync_dynamic_continue_break_condition = sync_dynamic_continue_break_for.get("break_condition", {}).get("conditional", {})
    sync_dynamic_continue_break_body = sync_dynamic_continue_break_for.get("body", {}).get("conditional", {})
    if (
        sync_generated_dynamic_for_in_continue_then_break.get("async_kind") != "sync_star"
        or sync_dynamic_continue_break_let.get("locals", [{}])[0].get("name") != "prefix"
        or sync_dynamic_continue_break_for.get("source", {}).get("arg") != "extra"
        or sync_dynamic_continue_break_for.get("local", {}).get("name") != "value"
        or sync_dynamic_continue_break_condition.get("condition", {}).get("op") != "=="
        or sync_dynamic_continue_break_condition.get("then", {}).get("bool") is not False
        or sync_dynamic_continue_break_condition.get("else", {}).get("op") != "=="
        or sync_dynamic_continue_break_body.get("condition", {}).get("op") != "=="
        or sync_dynamic_continue_break_body.get("then", {}).get("null") is not True
        or sync_dynamic_continue_break_body.get("else", {}).get("yield", {}).get("concat") is None
    ):
        raise SystemExit(f"expected syncGeneratedDynamicForInContinueThenBreak continue+break source, got {sync_generated_dynamic_for_in_continue_then_break}")
    async_generated_dynamic_for_in_continue_then_break = patch_by_member.get("asyncGeneratedDynamicForInContinueThenBreak", {}).get("bytecode_source", {})
    async_dynamic_continue_break_let = async_generated_dynamic_for_in_continue_then_break.get("body", {}).get("let", {})
    async_dynamic_continue_break_for = async_dynamic_continue_break_let.get("body", {}).get("yield_for_in", {})
    async_dynamic_continue_break_condition = async_dynamic_continue_break_for.get("break_condition", {}).get("conditional", {})
    async_dynamic_continue_break_body = async_dynamic_continue_break_for.get("body", {}).get("conditional", {})
    if (
        async_generated_dynamic_for_in_continue_then_break.get("async_kind") != "async_star"
        or async_dynamic_continue_break_let.get("locals", [{}])[0].get("name") != "prefix"
        or async_dynamic_continue_break_for.get("source", {}).get("arg") != "extra"
        or async_dynamic_continue_break_for.get("local", {}).get("name") != "value"
        or async_dynamic_continue_break_condition.get("condition", {}).get("op") != "=="
        or async_dynamic_continue_break_condition.get("then", {}).get("bool") is not False
        or async_dynamic_continue_break_condition.get("else", {}).get("op") != "=="
        or async_dynamic_continue_break_body.get("condition", {}).get("op") != "=="
        or async_dynamic_continue_break_body.get("then", {}).get("null") is not True
        or async_dynamic_continue_break_body.get("else", {}).get("yield", {}).get("concat") is None
    ):
        raise SystemExit(f"expected asyncGeneratedDynamicForInContinueThenBreak continue+break source, got {async_generated_dynamic_for_in_continue_then_break}")
    sync_generated_dynamic_for_in_continue_yield_break = patch_by_member.get("syncGeneratedDynamicForInContinueYieldBreak", {}).get("bytecode_source", {})
    sync_dynamic_continue_yield_break_let = sync_generated_dynamic_for_in_continue_yield_break.get("body", {}).get("let", {})
    sync_dynamic_continue_yield_break_for = sync_dynamic_continue_yield_break_let.get("body", {}).get("yield_for_in", {})
    sync_dynamic_continue_yield_break_before = sync_dynamic_continue_yield_break_for.get("before_break", {}).get("conditional", {})
    sync_dynamic_continue_yield_break_condition = sync_dynamic_continue_yield_break_for.get("break_condition", {}).get("conditional", {})
    sync_dynamic_continue_yield_break_body = sync_dynamic_continue_yield_break_for.get("body", {}).get("conditional", {})
    if (
        sync_generated_dynamic_for_in_continue_yield_break.get("async_kind") != "sync_star"
        or sync_dynamic_continue_yield_break_let.get("locals", [{}])[0].get("name") != "prefix"
        or sync_dynamic_continue_yield_break_for.get("source", {}).get("arg") != "extra"
        or sync_dynamic_continue_yield_break_for.get("local", {}).get("name") != "value"
        or sync_dynamic_continue_yield_break_before.get("condition", {}).get("op") != "=="
        or sync_dynamic_continue_yield_break_before.get("then", {}).get("null") is not True
        or sync_dynamic_continue_yield_break_before.get("else", {}).get("yield", {}).get("concat") is None
        or sync_dynamic_continue_yield_break_condition.get("condition", {}).get("op") != "=="
        or sync_dynamic_continue_yield_break_condition.get("then", {}).get("bool") is not False
        or sync_dynamic_continue_yield_break_condition.get("else", {}).get("op") != "=="
        or sync_dynamic_continue_yield_break_body.get("condition", {}).get("op") != "=="
        or sync_dynamic_continue_yield_break_body.get("then", {}).get("null") is not True
        or sync_dynamic_continue_yield_break_body.get("else", {}).get("yield", {}).get("concat") is None
    ):
        raise SystemExit(f"expected syncGeneratedDynamicForInContinueYieldBreak guarded before-break source, got {sync_generated_dynamic_for_in_continue_yield_break}")
    async_generated_dynamic_for_in_continue_yield_break = patch_by_member.get("asyncGeneratedDynamicForInContinueYieldBreak", {}).get("bytecode_source", {})
    async_dynamic_continue_yield_break_let = async_generated_dynamic_for_in_continue_yield_break.get("body", {}).get("let", {})
    async_dynamic_continue_yield_break_for = async_dynamic_continue_yield_break_let.get("body", {}).get("yield_for_in", {})
    async_dynamic_continue_yield_break_before = async_dynamic_continue_yield_break_for.get("before_break", {}).get("conditional", {})
    async_dynamic_continue_yield_break_condition = async_dynamic_continue_yield_break_for.get("break_condition", {}).get("conditional", {})
    async_dynamic_continue_yield_break_body = async_dynamic_continue_yield_break_for.get("body", {}).get("conditional", {})
    if (
        async_generated_dynamic_for_in_continue_yield_break.get("async_kind") != "async_star"
        or async_dynamic_continue_yield_break_let.get("locals", [{}])[0].get("name") != "prefix"
        or async_dynamic_continue_yield_break_for.get("source", {}).get("arg") != "extra"
        or async_dynamic_continue_yield_break_for.get("local", {}).get("name") != "value"
        or async_dynamic_continue_yield_break_before.get("condition", {}).get("op") != "=="
        or async_dynamic_continue_yield_break_before.get("then", {}).get("null") is not True
        or async_dynamic_continue_yield_break_before.get("else", {}).get("yield", {}).get("concat") is None
        or async_dynamic_continue_yield_break_condition.get("condition", {}).get("op") != "=="
        or async_dynamic_continue_yield_break_condition.get("then", {}).get("bool") is not False
        or async_dynamic_continue_yield_break_condition.get("else", {}).get("op") != "=="
        or async_dynamic_continue_yield_break_body.get("condition", {}).get("op") != "=="
        or async_dynamic_continue_yield_break_body.get("then", {}).get("null") is not True
        or async_dynamic_continue_yield_break_body.get("else", {}).get("yield", {}).get("concat") is None
    ):
        raise SystemExit(f"expected asyncGeneratedDynamicForInContinueYieldBreak guarded before-break source, got {async_generated_dynamic_for_in_continue_yield_break}")
    sync_generated_dynamic_for_in_nested = patch_by_member.get("syncGeneratedDynamicForInNested", {}).get("bytecode_source", {})
    sync_dynamic_nested_let = sync_generated_dynamic_for_in_nested.get("body", {}).get("let", {})
    sync_dynamic_nested_outer = sync_dynamic_nested_let.get("body", {}).get("yield_for_in", {})
    sync_dynamic_nested_inner = sync_dynamic_nested_outer.get("body", {}).get("yield_for_in", {})
    if (
        sync_generated_dynamic_for_in_nested.get("async_kind") != "sync_star"
        or sync_dynamic_nested_let.get("locals", [{}])[0].get("name") != "prefix"
        or sync_dynamic_nested_outer.get("source", {}).get("arg") != "extra"
        or sync_dynamic_nested_outer.get("local", {}).get("name") != "value"
        or sync_dynamic_nested_inner.get("source", {}).get("arg") != "suffixes"
        or sync_dynamic_nested_inner.get("local", {}).get("name") != "suffix"
        or sync_dynamic_nested_inner.get("body", {}).get("yield", {}).get("concat") is None
    ):
        raise SystemExit(f"expected syncGeneratedDynamicForInNested nested yield_for_in source, got {sync_generated_dynamic_for_in_nested}")
    async_generated_dynamic_for_in_nested = patch_by_member.get("asyncGeneratedDynamicForInNested", {}).get("bytecode_source", {})
    async_dynamic_nested_let = async_generated_dynamic_for_in_nested.get("body", {}).get("let", {})
    async_dynamic_nested_outer = async_dynamic_nested_let.get("body", {}).get("yield_for_in", {})
    async_dynamic_nested_inner = async_dynamic_nested_outer.get("body", {}).get("yield_for_in", {})
    if (
        async_generated_dynamic_for_in_nested.get("async_kind") != "async_star"
        or async_dynamic_nested_let.get("locals", [{}])[0].get("name") != "prefix"
        or async_dynamic_nested_outer.get("source", {}).get("arg") != "extra"
        or async_dynamic_nested_outer.get("local", {}).get("name") != "value"
        or async_dynamic_nested_inner.get("source", {}).get("arg") != "suffixes"
        or async_dynamic_nested_inner.get("local", {}).get("name") != "suffix"
        or async_dynamic_nested_inner.get("body", {}).get("yield", {}).get("concat") is None
    ):
        raise SystemExit(f"expected asyncGeneratedDynamicForInNested nested yield_for_in source, got {async_generated_dynamic_for_in_nested}")
    sync_generated_dynamic_for_in_nested_control = patch_by_member.get("syncGeneratedDynamicForInNestedBreakContinue", {}).get("bytecode_source", {})
    sync_dynamic_nested_control_let = sync_generated_dynamic_for_in_nested_control.get("body", {}).get("let", {})
    sync_dynamic_nested_control_outer = sync_dynamic_nested_control_let.get("body", {}).get("yield_for_in", {})
    sync_dynamic_nested_control_outer_before = sync_dynamic_nested_control_outer.get("before_break", {}).get("conditional", {})
    sync_dynamic_nested_control_inner = sync_dynamic_nested_control_outer_before.get("else", {}).get("yield_for_in", {})
    sync_dynamic_nested_control_inner_before = sync_dynamic_nested_control_inner.get("before_break", {}).get("conditional", {})
    sync_dynamic_nested_control_inner_break = sync_dynamic_nested_control_inner.get("break_condition", {}).get("conditional", {})
    sync_dynamic_nested_control_inner_body = sync_dynamic_nested_control_inner.get("body", {}).get("conditional", {})
    sync_dynamic_nested_control_outer_break = sync_dynamic_nested_control_outer.get("break_condition", {}).get("conditional", {})
    sync_dynamic_nested_control_outer_body = sync_dynamic_nested_control_outer.get("body", {}).get("conditional", {})
    if (
        sync_generated_dynamic_for_in_nested_control.get("async_kind") != "sync_star"
        or sync_dynamic_nested_control_let.get("locals", [{}])[0].get("name") != "prefix"
        or sync_dynamic_nested_control_outer.get("source", {}).get("arg") != "extra"
        or sync_dynamic_nested_control_outer.get("local", {}).get("name") != "value"
        or sync_dynamic_nested_control_outer_before.get("condition", {}).get("op") != "=="
        or sync_dynamic_nested_control_outer_before.get("then", {}).get("null") is not True
        or sync_dynamic_nested_control_outer_break.get("condition", {}).get("op") != "=="
        or sync_dynamic_nested_control_outer_break.get("then", {}).get("bool") is not False
        or sync_dynamic_nested_control_outer_break.get("else", {}).get("op") != "=="
        or sync_dynamic_nested_control_outer_body.get("condition", {}).get("op") != "=="
        or sync_dynamic_nested_control_outer_body.get("then", {}).get("null") is not True
        or sync_dynamic_nested_control_outer_body.get("else", {}).get("null") is not True
        or sync_dynamic_nested_control_inner.get("source", {}).get("arg") != "suffixes"
        or sync_dynamic_nested_control_inner.get("local", {}).get("name") != "suffix"
        or sync_dynamic_nested_control_inner_before.get("condition", {}).get("op") != "=="
        or sync_dynamic_nested_control_inner_before.get("then", {}).get("null") is not True
        or sync_dynamic_nested_control_inner_before.get("else", {}).get("yield", {}).get("concat") is None
        or sync_dynamic_nested_control_inner_break.get("condition", {}).get("op") != "=="
        or sync_dynamic_nested_control_inner_break.get("then", {}).get("bool") is not False
        or sync_dynamic_nested_control_inner_break.get("else", {}).get("op") != "=="
        or sync_dynamic_nested_control_inner_body.get("condition", {}).get("op") != "=="
        or sync_dynamic_nested_control_inner_body.get("then", {}).get("null") is not True
        or sync_dynamic_nested_control_inner_body.get("else", {}).get("null") is not True
    ):
        raise SystemExit(f"expected syncGeneratedDynamicForInNestedBreakContinue nested control source, got {sync_generated_dynamic_for_in_nested_control}")
    async_generated_dynamic_for_in_nested_control = patch_by_member.get("asyncGeneratedDynamicForInNestedBreakContinue", {}).get("bytecode_source", {})
    async_dynamic_nested_control_let = async_generated_dynamic_for_in_nested_control.get("body", {}).get("let", {})
    async_dynamic_nested_control_outer = async_dynamic_nested_control_let.get("body", {}).get("yield_for_in", {})
    async_dynamic_nested_control_outer_before = async_dynamic_nested_control_outer.get("before_break", {}).get("conditional", {})
    async_dynamic_nested_control_inner = async_dynamic_nested_control_outer_before.get("else", {}).get("yield_for_in", {})
    async_dynamic_nested_control_inner_before = async_dynamic_nested_control_inner.get("before_break", {}).get("conditional", {})
    async_dynamic_nested_control_inner_break = async_dynamic_nested_control_inner.get("break_condition", {}).get("conditional", {})
    async_dynamic_nested_control_inner_body = async_dynamic_nested_control_inner.get("body", {}).get("conditional", {})
    async_dynamic_nested_control_outer_break = async_dynamic_nested_control_outer.get("break_condition", {}).get("conditional", {})
    async_dynamic_nested_control_outer_body = async_dynamic_nested_control_outer.get("body", {}).get("conditional", {})
    if (
        async_generated_dynamic_for_in_nested_control.get("async_kind") != "async_star"
        or async_dynamic_nested_control_let.get("locals", [{}])[0].get("name") != "prefix"
        or async_dynamic_nested_control_outer.get("source", {}).get("arg") != "extra"
        or async_dynamic_nested_control_outer.get("local", {}).get("name") != "value"
        or async_dynamic_nested_control_outer_before.get("condition", {}).get("op") != "=="
        or async_dynamic_nested_control_outer_before.get("then", {}).get("null") is not True
        or async_dynamic_nested_control_outer_break.get("condition", {}).get("op") != "=="
        or async_dynamic_nested_control_outer_break.get("then", {}).get("bool") is not False
        or async_dynamic_nested_control_outer_break.get("else", {}).get("op") != "=="
        or async_dynamic_nested_control_outer_body.get("condition", {}).get("op") != "=="
        or async_dynamic_nested_control_outer_body.get("then", {}).get("null") is not True
        or async_dynamic_nested_control_outer_body.get("else", {}).get("null") is not True
        or async_dynamic_nested_control_inner.get("source", {}).get("arg") != "suffixes"
        or async_dynamic_nested_control_inner.get("local", {}).get("name") != "suffix"
        or async_dynamic_nested_control_inner_before.get("condition", {}).get("op") != "=="
        or async_dynamic_nested_control_inner_before.get("then", {}).get("null") is not True
        or async_dynamic_nested_control_inner_before.get("else", {}).get("yield", {}).get("concat") is None
        or async_dynamic_nested_control_inner_break.get("condition", {}).get("op") != "=="
        or async_dynamic_nested_control_inner_break.get("then", {}).get("bool") is not False
        or async_dynamic_nested_control_inner_break.get("else", {}).get("op") != "=="
        or async_dynamic_nested_control_inner_body.get("condition", {}).get("op") != "=="
        or async_dynamic_nested_control_inner_body.get("then", {}).get("null") is not True
        or async_dynamic_nested_control_inner_body.get("else", {}).get("null") is not True
    ):
        raise SystemExit(f"expected asyncGeneratedDynamicForInNestedBreakContinue nested control source, got {async_generated_dynamic_for_in_nested_control}")
