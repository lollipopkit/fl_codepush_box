import json
import sys

patch = json.load(open(sys.argv[1]))
patch_by_member = {f.get("member_name"): f for f in patch["functions"]}

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
sync_generated_yield_star = patch_by_member.get("syncGeneratedYieldStar", {}).get("bytecode_source", {})
yield_star_items = sync_generated_yield_star.get("body", {}).get("seq", [])
if (
    sync_generated_yield_star.get("async_kind") != "sync_star"
    or len(yield_star_items) != 2
    or yield_star_items[0].get("yield", {}).get("string") != "patched-yield-star-a"
    or yield_star_items[1].get("yield", {}).get("string") != "patched-yield-star-b"
):
    raise SystemExit(f"expected syncGeneratedYieldStar static yield* source, got {sync_generated_yield_star}")
sync_generated_yield_star_dynamic = patch_by_member.get("syncGeneratedYieldStarDynamic", {}).get("bytecode_source", {})
dynamic_yield_star_seq = sync_generated_yield_star_dynamic.get("body", {}).get("seq", [])
dynamic_yield_star_for = dynamic_yield_star_seq[0].get("yield_for_in", {}) if dynamic_yield_star_seq else {}
if (
    sync_generated_yield_star_dynamic.get("async_kind") != "sync_star"
    or len(dynamic_yield_star_seq) != 2
    or dynamic_yield_star_for.get("source", {}).get("arg") != "extra"
    or dynamic_yield_star_seq[1].get("yield", {}).get("string") != "patched-yield-star-dynamic-tail"
):
    raise SystemExit(f"expected syncGeneratedYieldStarDynamic dynamic yield* source, got {sync_generated_yield_star_dynamic}")
async_generated_yield_star = patch_by_member.get("asyncGeneratedYieldStar", {}).get("bytecode_source", {})
async_yield_star_items = async_generated_yield_star.get("body", {}).get("seq", [])
if (
    async_generated_yield_star.get("async_kind") != "async_star"
    or len(async_yield_star_items) != 2
    or async_yield_star_items[0].get("yield", {}).get("string") != "patched-stream-yield-star-a"
    or async_yield_star_items[1].get("yield", {}).get("string") != "patched-stream-yield-star-b"
):
    raise SystemExit(f"expected asyncGeneratedYieldStar static yield* source, got {async_generated_yield_star}")
async_generated_yield_star_dynamic = patch_by_member.get("asyncGeneratedYieldStarDynamic", {}).get("bytecode_source", {})
async_dynamic_yield_star_seq = async_generated_yield_star_dynamic.get("body", {}).get("seq", [])
async_dynamic_yield_star_for = async_dynamic_yield_star_seq[0].get("yield_for_in", {}) if async_dynamic_yield_star_seq else {}
if (
    async_generated_yield_star_dynamic.get("async_kind") != "async_star"
    or len(async_dynamic_yield_star_seq) != 2
    or async_dynamic_yield_star_for.get("source", {}).get("arg") != "extra"
    or async_dynamic_yield_star_seq[1].get("yield", {}).get("string") != "patched-stream-yield-star-dynamic-tail"
):
    raise SystemExit(f"expected asyncGeneratedYieldStarDynamic Stream.fromIterable yield* source, got {async_generated_yield_star_dynamic}")
async_generated_yield_star_stream = patch_by_member.get("asyncGeneratedYieldStarStream", {}).get("bytecode_source", {})
async_yield_star_stream_let = async_generated_yield_star_stream.get("body", {}).get("let", {})
async_yield_star_stream_locals = async_yield_star_stream_let.get("locals", [])
async_yield_star_stream_try = async_yield_star_stream_let.get("body", {}).get("try_finally", {})
async_yield_star_stream_loop = async_yield_star_stream_try.get("body", {}).get("while_loop", {})
async_yield_star_stream_condition = async_yield_star_stream_loop.get("condition", {}).get("await", {}).get("call_dynamic", {})
async_yield_star_stream_body = async_yield_star_stream_loop.get("body", {}).get("seq", [])
async_yield_star_stream_finally = async_yield_star_stream_try.get("finally", {}).get("await", {}).get("call_dynamic", {})
if (
    async_generated_yield_star_stream.get("async_kind") != "async_star"
    or len(async_yield_star_stream_locals) != 3
    or async_yield_star_stream_locals[0].get("value", {}).get("arg") != "extra"
    or async_yield_star_stream_locals[1].get("value", {}).get("new_object", {}).get("constructor") != "dart:async::class:_StreamIterator."
    or async_yield_star_stream_condition.get("method") != "moveNext"
    or len(async_yield_star_stream_body) != 2
    or async_yield_star_stream_body[0].get("set_local", {}).get("id") != 2
    or async_yield_star_stream_body[1].get("yield", {}).get("let_local") != 2
    or async_yield_star_stream_finally.get("method") != "cancel"
):
    raise SystemExit(f"expected asyncGeneratedYieldStarStream generic Stream yield* source, got {async_generated_yield_star_stream}")
async_generated_yield_star_stream_finally = patch_by_member.get("asyncGeneratedYieldStarStreamFinally", {}).get("bytecode_source", {})
async_yield_star_stream_outer_finally = async_generated_yield_star_stream_finally.get("body", {}).get("try_finally", {})
async_yield_star_stream_finally_let = async_yield_star_stream_outer_finally.get("body", {}).get("let", {})
async_yield_star_stream_finally_inner = async_yield_star_stream_finally_let.get("body", {}).get("try_finally", {})
async_yield_star_stream_finally_loop = async_yield_star_stream_finally_inner.get("body", {}).get("while_loop", {})
async_yield_star_stream_finally_cleanup = async_yield_star_stream_outer_finally.get("finally", {}).get("yield", {})
if (
    async_generated_yield_star_stream_finally.get("async_kind") != "async_star"
    or async_yield_star_stream_finally_let.get("locals", [{}])[0].get("value", {}).get("arg") != "extra"
    or async_yield_star_stream_finally_loop.get("condition", {}).get("await", {}).get("call_dynamic", {}).get("method") != "moveNext"
    or async_yield_star_stream_finally_inner.get("finally", {}).get("await", {}).get("call_dynamic", {}).get("method") != "cancel"
    or async_yield_star_stream_finally_cleanup.get("string") != "patched-stream-yield-star-stream-finally-cleanup"
):
    raise SystemExit(f"expected asyncGeneratedYieldStarStreamFinally generic Stream yield* try/finally source, got {async_generated_yield_star_stream_finally}")
async_generated_yield_star_stream_sandwich = patch_by_member.get(
    "asyncGeneratedYieldStarStreamSandwichFinally", {}
).get("bytecode_source", {})
async_yield_star_stream_sandwich_outer = async_generated_yield_star_stream_sandwich.get("body", {}).get("try_finally", {})
async_yield_star_stream_sandwich_seq = async_yield_star_stream_sandwich_outer.get("body", {}).get("seq", [])
async_yield_star_stream_sandwich_let = (
    async_yield_star_stream_sandwich_seq[1].get("let", {})
    if len(async_yield_star_stream_sandwich_seq) > 1
    else {}
)
async_yield_star_stream_sandwich_inner = async_yield_star_stream_sandwich_let.get("body", {}).get("try_finally", {})
async_yield_star_stream_sandwich_loop = async_yield_star_stream_sandwich_inner.get("body", {}).get("while_loop", {})
async_yield_star_stream_sandwich_cleanup = async_yield_star_stream_sandwich_outer.get("finally", {}).get("yield", {})
if (
    async_generated_yield_star_stream_sandwich.get("async_kind") != "async_star"
    or len(async_yield_star_stream_sandwich_seq) != 3
    or async_yield_star_stream_sandwich_seq[0].get("yield", {}).get("string") != "patched-stream-yield-star-stream-before"
    or async_yield_star_stream_sandwich_let.get("locals", [{}])[0].get("value", {}).get("arg") != "extra"
    or async_yield_star_stream_sandwich_loop.get("condition", {}).get("await", {}).get("call_dynamic", {}).get("method") != "moveNext"
    or async_yield_star_stream_sandwich_inner.get("finally", {}).get("await", {}).get("call_dynamic", {}).get("method") != "cancel"
    or async_yield_star_stream_sandwich_seq[2].get("yield", {}).get("string") != "patched-stream-yield-star-stream-after"
    or async_yield_star_stream_sandwich_cleanup.get("string") != "patched-stream-yield-star-stream-sandwich-cleanup"
):
    raise SystemExit(
        "expected asyncGeneratedYieldStarStreamSandwichFinally generic Stream "
        f"yield* sandwich try/finally source, got {async_generated_yield_star_stream_sandwich}"
    )
async_generated_yield_star_two_streams = patch_by_member.get(
    "asyncGeneratedYieldStarTwoStreamsFinally", {}
).get("bytecode_source", {})
async_yield_star_two_outer = async_generated_yield_star_two_streams.get("body", {}).get("try_finally", {})
async_yield_star_two_seq = async_yield_star_two_outer.get("body", {}).get("seq", [])
async_yield_star_two_first = async_yield_star_two_seq[0].get("let", {}) if async_yield_star_two_seq else {}
async_yield_star_two_second = async_yield_star_two_seq[1].get("let", {}) if len(async_yield_star_two_seq) > 1 else {}
async_yield_star_two_first_try = async_yield_star_two_first.get("body", {}).get("try_finally", {})
async_yield_star_two_second_try = async_yield_star_two_second.get("body", {}).get("try_finally", {})
if (
    async_generated_yield_star_two_streams.get("async_kind") != "async_star"
    or len(async_yield_star_two_seq) != 2
    or async_yield_star_two_first.get("locals", [{}])[0].get("value", {}).get("arg") != "first"
    or async_yield_star_two_second.get("locals", [{}])[0].get("value", {}).get("arg") != "second"
    or async_yield_star_two_first_try.get("body", {}).get("while_loop", {}).get("condition", {}).get("await", {}).get("call_dynamic", {}).get("method") != "moveNext"
    or async_yield_star_two_second_try.get("body", {}).get("while_loop", {}).get("condition", {}).get("await", {}).get("call_dynamic", {}).get("method") != "moveNext"
    or async_yield_star_two_first_try.get("finally", {}).get("await", {}).get("call_dynamic", {}).get("method") != "cancel"
    or async_yield_star_two_second_try.get("finally", {}).get("await", {}).get("call_dynamic", {}).get("method") != "cancel"
    or async_yield_star_two_outer.get("finally", {}).get("yield", {}).get("string") != "patched-stream-yield-star-two-streams-cleanup"
):
    raise SystemExit(
        "expected asyncGeneratedYieldStarTwoStreamsFinally two generic Stream "
        f"yield* blocks under one try/finally, got {async_generated_yield_star_two_streams}"
    )
async_generated_yield_star_value = patch_by_member.get("asyncGeneratedYieldStarValue", {}).get("bytecode_source", {})
async_yield_star_value = async_generated_yield_star_value.get("body", {}).get("yield", {}).get("concat", [])
if (
    async_generated_yield_star_value.get("async_kind") != "async_star"
    or len(async_yield_star_value) != 2
    or async_yield_star_value[0].get("string") != "patched-stream-yield-star-value-"
    or async_yield_star_value[1].get("arg") != "value"
):
    raise SystemExit(f"expected asyncGeneratedYieldStarValue Stream.value yield* source, got {async_generated_yield_star_value}")
async_generated_yield_star_future = patch_by_member.get("asyncGeneratedYieldStarFromFuture", {}).get("bytecode_source", {})
async_yield_star_future = async_generated_yield_star_future.get("body", {}).get("yield", {}).get("concat", [])
if (
    async_generated_yield_star_future.get("async_kind") != "async_star"
    or len(async_yield_star_future) != 2
    or async_yield_star_future[0].get("string") != "patched-stream-yield-star-future-"
    or async_yield_star_future[1].get("arg") != "value"
):
    raise SystemExit(f"expected asyncGeneratedYieldStarFromFuture Stream.fromFuture(Future.value) yield* source, got {async_generated_yield_star_future}")
async_generated_yield_star_pending = patch_by_member.get("asyncGeneratedYieldStarPendingFuture", {}).get("bytecode_source", {})
async_yield_star_pending = async_generated_yield_star_pending.get("body", {}).get("yield", {}).get("await", {})
if (
    async_generated_yield_star_pending.get("async_kind") != "async_star"
    or async_yield_star_pending.get("arg") != "ready"
):
    raise SystemExit(f"expected asyncGeneratedYieldStarPendingFuture Stream.fromFuture pending yield* source, got {async_generated_yield_star_pending}")
async_generated_yield_star_empty = patch_by_member.get("asyncGeneratedYieldStarEmpty", {}).get("bytecode_source", {})
if (
    async_generated_yield_star_empty.get("async_kind") != "async_star"
    or async_generated_yield_star_empty.get("body", {}).get("null") is not True
):
    raise SystemExit(f"expected asyncGeneratedYieldStarEmpty Stream.empty yield* source, got {async_generated_yield_star_empty}")
async_generated_await_for_iterable = patch_by_member.get("asyncGeneratedAwaitForFromIterable", {}).get("bytecode_source", {})
async_await_for_iterable = async_generated_await_for_iterable.get("body", {}).get("yield_for_in", {})
async_await_for_iterable_body = async_await_for_iterable.get("body", {}).get("yield", {}).get("concat", [])
if (
    async_generated_await_for_iterable.get("async_kind") != "async_star"
    or async_await_for_iterable.get("source", {}).get("arg") != "extra"
    or async_await_for_iterable.get("local", {}).get("name") != "value"
    or len(async_await_for_iterable_body) != 2
    or async_await_for_iterable_body[0].get("string") != "patched-stream-await-for-iterable-"
    or async_await_for_iterable_body[1].get("let_local") != 0
):
    raise SystemExit(f"expected asyncGeneratedAwaitForFromIterable lowered await-for source, got {async_generated_await_for_iterable}")
async_generated_await_for_continue = patch_by_member.get("asyncGeneratedAwaitForContinue", {}).get("bytecode_source", {})
async_await_for_continue = async_generated_await_for_continue.get("body", {}).get("yield_for_in", {})
async_await_for_continue_body = async_await_for_continue.get("body", {}).get("conditional", {})
async_await_for_continue_else = async_await_for_continue_body.get("else", {}).get("yield", {}).get("concat", [])
if (
    async_generated_await_for_continue.get("async_kind") != "async_star"
    or async_await_for_continue.get("source", {}).get("arg") != "extra"
    or async_await_for_continue.get("local", {}).get("name") != "value"
    or async_await_for_continue_body.get("condition", {}).get("op") != "=="
    or async_await_for_continue_body.get("then", {}).get("null") is not True
    or len(async_await_for_continue_else) != 2
    or async_await_for_continue_else[0].get("string") != "patched-stream-await-for-continue-"
    or async_await_for_continue_else[1].get("let_local") != 0
):
    raise SystemExit(f"expected asyncGeneratedAwaitForContinue guarded continue await-for source, got {async_generated_await_for_continue}")
async_generated_await_for_break = patch_by_member.get("asyncGeneratedAwaitForBreak", {}).get("bytecode_source", {})
async_await_for_break = async_generated_await_for_break.get("body", {}).get("yield_for_in", {})
async_await_for_break_body = async_await_for_break.get("body", {}).get("yield", {}).get("concat", [])
if (
    async_generated_await_for_break.get("async_kind") != "async_star"
    or async_await_for_break.get("source", {}).get("arg") != "extra"
    or async_await_for_break.get("local", {}).get("name") != "value"
    or async_await_for_break.get("break_condition", {}).get("op") != "=="
    or len(async_await_for_break_body) != 2
    or async_await_for_break_body[0].get("string") != "patched-stream-await-for-break-"
    or async_await_for_break_body[1].get("let_local") != 0
):
    raise SystemExit(f"expected asyncGeneratedAwaitForBreak guarded break await-for source, got {async_generated_await_for_break}")
async_generated_await_for_value = patch_by_member.get("asyncGeneratedAwaitForValue", {}).get("bytecode_source", {})
async_await_for_value = async_generated_await_for_value.get("body", {}).get("yield_for_in", {})
async_await_for_value_items = async_await_for_value.get("source", {}).get("list", [])
async_await_for_value_body = async_await_for_value.get("body", {}).get("yield", {}).get("concat", [])
if (
    async_generated_await_for_value.get("async_kind") != "async_star"
    or len(async_await_for_value_items) != 1
    or async_await_for_value_items[0].get("arg") != "value"
    or async_await_for_value.get("local", {}).get("name") != "item"
    or len(async_await_for_value_body) != 2
    or async_await_for_value_body[0].get("string") != "patched-stream-await-for-value-"
    or async_await_for_value_body[1].get("let_local") != 0
):
    raise SystemExit(f"expected asyncGeneratedAwaitForValue Stream.value await-for source, got {async_generated_await_for_value}")
async_generated_await_for_future = patch_by_member.get("asyncGeneratedAwaitForFuture", {}).get("bytecode_source", {})
async_await_for_future = async_generated_await_for_future.get("body", {}).get("yield_for_in", {})
async_await_for_future_items = async_await_for_future.get("source", {}).get("list", [])
async_await_for_future_body = async_await_for_future.get("body", {}).get("yield", {}).get("concat", [])
if (
    async_generated_await_for_future.get("async_kind") != "async_star"
    or len(async_await_for_future_items) != 1
    or async_await_for_future_items[0].get("arg") != "value"
    or async_await_for_future.get("local", {}).get("name") != "item"
    or len(async_await_for_future_body) != 2
    or async_await_for_future_body[0].get("string") != "patched-stream-await-for-future-"
    or async_await_for_future_body[1].get("let_local") != 0
):
    raise SystemExit(f"expected asyncGeneratedAwaitForFuture Stream.fromFuture(Future.value) await-for source, got {async_generated_await_for_future}")
async_generated_await_for_future_break = patch_by_member.get("asyncGeneratedAwaitForFutureBreak", {}).get("bytecode_source", {})
async_await_for_future_break = async_generated_await_for_future_break.get("body", {}).get("yield_for_in", {})
async_await_for_future_break_items = async_await_for_future_break.get("source", {}).get("list", [])
async_await_for_future_break_body = async_await_for_future_break.get("body", {}).get("yield", {}).get("concat", [])
if (
    async_generated_await_for_future_break.get("async_kind") != "async_star"
    or len(async_await_for_future_break_items) != 1
    or async_await_for_future_break_items[0].get("arg") != "value"
    or async_await_for_future_break.get("local", {}).get("name") != "item"
    or async_await_for_future_break.get("break_condition", {}).get("op") != "=="
    or len(async_await_for_future_break_body) != 2
    or async_await_for_future_break_body[0].get("string") != "patched-stream-await-for-future-break-"
    or async_await_for_future_break_body[1].get("let_local") != 0
):
    raise SystemExit(f"expected asyncGeneratedAwaitForFutureBreak Stream.fromFuture guarded break source, got {async_generated_await_for_future_break}")
async_generated_await_for_pending = patch_by_member.get("asyncGeneratedAwaitForPendingFuture", {}).get("bytecode_source", {})
async_await_for_pending = async_generated_await_for_pending.get("body", {}).get("yield_for_in", {})
async_await_for_pending_items = async_await_for_pending.get("source", {}).get("list", [])
async_await_for_pending_body = async_await_for_pending.get("body", {}).get("yield", {}).get("concat", [])
if (
    async_generated_await_for_pending.get("async_kind") != "async_star"
    or len(async_await_for_pending_items) != 1
    or async_await_for_pending_items[0].get("await", {}).get("arg") != "ready"
    or async_await_for_pending.get("local", {}).get("name") != "item"
    or len(async_await_for_pending_body) != 2
    or async_await_for_pending_body[0].get("string") != "patched-stream-await-for-pending-future-"
    or async_await_for_pending_body[1].get("let_local") != 0
):
    raise SystemExit(f"expected asyncGeneratedAwaitForPendingFuture Stream.fromFuture pending await-for source, got {async_generated_await_for_pending}")
async_generated_await_for_pending_continue = patch_by_member.get("asyncGeneratedAwaitForPendingContinue", {}).get("bytecode_source", {})
async_await_for_pending_continue = async_generated_await_for_pending_continue.get("body", {}).get("yield_for_in", {})
async_await_for_pending_continue_items = async_await_for_pending_continue.get("source", {}).get("list", [])
async_await_for_pending_continue_body = async_await_for_pending_continue.get("body", {}).get("conditional", {})
async_await_for_pending_continue_else = async_await_for_pending_continue_body.get("else", {}).get("yield", {}).get("concat", [])
if (
    async_generated_await_for_pending_continue.get("async_kind") != "async_star"
    or len(async_await_for_pending_continue_items) != 1
    or async_await_for_pending_continue_items[0].get("await", {}).get("arg") != "ready"
    or async_await_for_pending_continue.get("local", {}).get("name") != "item"
    or async_await_for_pending_continue_body.get("condition", {}).get("op") != "=="
    or async_await_for_pending_continue_body.get("then", {}).get("null") is not True
    or len(async_await_for_pending_continue_else) != 2
    or async_await_for_pending_continue_else[0].get("string") != "patched-stream-await-for-pending-continue-"
    or async_await_for_pending_continue_else[1].get("let_local") != 0
):
    raise SystemExit(f"expected asyncGeneratedAwaitForPendingContinue Stream.fromFuture pending guarded continue source, got {async_generated_await_for_pending_continue}")
async_generated_await_for_empty = patch_by_member.get("asyncGeneratedAwaitForEmpty", {}).get("bytecode_source", {})
async_await_for_empty = async_generated_await_for_empty.get("body", {}).get("yield_for_in", {})
async_await_for_empty_items = async_await_for_empty.get("source", {}).get("list", [])
async_await_for_empty_body = async_await_for_empty.get("body", {}).get("yield", {}).get("concat", [])
if (
    async_generated_await_for_empty.get("async_kind") != "async_star"
    or async_await_for_empty_items != []
    or async_await_for_empty.get("local", {}).get("name") != "item"
    or len(async_await_for_empty_body) != 2
    or async_await_for_empty_body[0].get("string") != "patched-stream-await-for-empty-"
    or async_await_for_empty_body[1].get("let_local") != 0
):
    raise SystemExit(f"expected asyncGeneratedAwaitForEmpty Stream.empty await-for source, got {async_generated_await_for_empty}")
async_generated_await_for_stream = patch_by_member.get("asyncGeneratedAwaitFor", {}).get("bytecode_source", {})
async_await_for_stream_let = async_generated_await_for_stream.get("body", {}).get("let", {})
async_await_for_stream_locals = async_await_for_stream_let.get("locals", [])
async_await_for_stream_try = async_await_for_stream_let.get("body", {}).get("try_finally", {})
async_await_for_stream_loop = async_await_for_stream_try.get("body", {}).get("while_loop", {})
async_await_for_stream_condition = async_await_for_stream_loop.get("condition", {}).get("await", {}).get("call_dynamic", {})
async_await_for_stream_body = async_await_for_stream_loop.get("body", {}).get("seq", [])
async_await_for_stream_finally = async_await_for_stream_try.get("finally", {}).get("await", {}).get("call_dynamic", {})
if (
    async_generated_await_for_stream.get("async_kind") != "async_star"
    or len(async_await_for_stream_locals) != 3
    or async_await_for_stream_locals[0].get("value", {}).get("arg") != "extra"
    or async_await_for_stream_locals[1].get("value", {}).get("new_object", {}).get("constructor") != "dart:async::class:_StreamIterator."
    or async_await_for_stream_condition.get("method") != "moveNext"
    or len(async_await_for_stream_body) != 2
    or async_await_for_stream_body[0].get("set_local", {}).get("id") != 2
    or async_await_for_stream_body[1].get("yield", {}).get("let_local") != 2
    or async_await_for_stream_finally.get("method") != "cancel"
):
    raise SystemExit(f"expected asyncGeneratedAwaitFor generic Stream await-for source, got {async_generated_await_for_stream}")
async_generated_await_for_finally = patch_by_member.get("asyncGeneratedAwaitForFinally", {}).get("bytecode_source", {})
async_await_for_finally_outer = async_generated_await_for_finally.get("body", {}).get("try_finally", {})
async_await_for_finally_let = async_await_for_finally_outer.get("body", {}).get("let", {})
async_await_for_finally_inner = async_await_for_finally_let.get("body", {}).get("try_finally", {})
async_await_for_finally_loop = async_await_for_finally_inner.get("body", {}).get("while_loop", {})
async_await_for_finally_cleanup = async_await_for_finally_outer.get("finally", {}).get("yield", {})
if (
    async_generated_await_for_finally.get("async_kind") != "async_star"
    or async_await_for_finally_let.get("locals", [{}])[0].get("value", {}).get("arg") != "extra"
    or async_await_for_finally_loop.get("condition", {}).get("await", {}).get("call_dynamic", {}).get("method") != "moveNext"
    or async_await_for_finally_inner.get("finally", {}).get("await", {}).get("call_dynamic", {}).get("method") != "cancel"
    or async_await_for_finally_cleanup.get("string") != "patched-stream-await-for-finally-cleanup"
):
    raise SystemExit(f"expected asyncGeneratedAwaitForFinally generic Stream await-for try/finally source, got {async_generated_await_for_finally}")
async_generated_await_for_stream_continue = patch_by_member.get("asyncGeneratedAwaitForStreamContinue", {}).get("bytecode_source", {})
async_await_for_stream_continue_let = async_generated_await_for_stream_continue.get("body", {}).get("let", {})
async_await_for_stream_continue_locals = async_await_for_stream_continue_let.get("locals", [])
async_await_for_stream_continue_try = async_await_for_stream_continue_let.get("body", {}).get("try_finally", {})
async_await_for_stream_continue_loop = async_await_for_stream_continue_try.get("body", {}).get("while_loop", {})
async_await_for_stream_continue_condition = async_await_for_stream_continue_loop.get("condition", {}).get("await", {}).get("call_dynamic", {})
async_await_for_stream_continue_body = async_await_for_stream_continue_loop.get("body", {}).get("seq", [])
async_await_for_stream_continue_guard = (
    async_await_for_stream_continue_body[1].get("conditional", {})
    if len(async_await_for_stream_continue_body) > 1
    else {}
)
async_await_for_stream_continue_else = async_await_for_stream_continue_guard.get("else", {}).get("yield", {}).get("concat", [])
async_await_for_stream_continue_finally = async_await_for_stream_continue_try.get("finally", {}).get("await", {}).get("call_dynamic", {})
if (
    async_generated_await_for_stream_continue.get("async_kind") != "async_star"
    or len(async_await_for_stream_continue_locals) != 3
    or async_await_for_stream_continue_locals[0].get("value", {}).get("arg") != "extra"
    or async_await_for_stream_continue_locals[1].get("value", {}).get("new_object", {}).get("constructor") != "dart:async::class:_StreamIterator."
    or async_await_for_stream_continue_condition.get("method") != "moveNext"
    or len(async_await_for_stream_continue_body) != 2
    or async_await_for_stream_continue_body[0].get("set_local", {}).get("id") != 2
    or async_await_for_stream_continue_guard.get("condition", {}).get("op") != "=="
    or async_await_for_stream_continue_guard.get("then", {}).get("null") is not True
    or len(async_await_for_stream_continue_else) != 2
    or async_await_for_stream_continue_else[0].get("string") != "patched-stream-await-for-stream-continue-"
    or async_await_for_stream_continue_else[1].get("let_local") != 2
    or async_await_for_stream_continue_finally.get("method") != "cancel"
):
    raise SystemExit(f"expected asyncGeneratedAwaitForStreamContinue generic Stream guarded continue source, got {async_generated_await_for_stream_continue}")
async_generated_await_for_stream_break = patch_by_member.get("asyncGeneratedAwaitForStreamBreak", {}).get("bytecode_source", {})
async_await_for_stream_break_let = async_generated_await_for_stream_break.get("body", {}).get("let", {})
async_await_for_stream_break_locals = async_await_for_stream_break_let.get("locals", [])
async_await_for_stream_break_try = async_await_for_stream_break_let.get("body", {}).get("try_finally", {})
async_await_for_stream_break_loop = async_await_for_stream_break_try.get("body", {}).get("while_loop", {})
async_await_for_stream_break_condition = async_await_for_stream_break_loop.get("condition", {}).get("await", {}).get("call_dynamic", {})
async_await_for_stream_break_before = async_await_for_stream_break_loop.get("before_break", {}).get("set_local", {})
async_await_for_stream_break_guard = async_await_for_stream_break_loop.get("break_condition", {})
async_await_for_stream_break_body = async_await_for_stream_break_loop.get("body", {}).get("yield", {}).get("concat", [])
async_await_for_stream_break_finally = async_await_for_stream_break_try.get("finally", {}).get("await", {}).get("call_dynamic", {})
if (
    async_generated_await_for_stream_break.get("async_kind") != "async_star"
    or len(async_await_for_stream_break_locals) != 3
    or async_await_for_stream_break_locals[0].get("value", {}).get("arg") != "extra"
    or async_await_for_stream_break_locals[1].get("value", {}).get("new_object", {}).get("constructor") != "dart:async::class:_StreamIterator."
    or async_await_for_stream_break_condition.get("method") != "moveNext"
    or async_await_for_stream_break_before.get("id") != 2
    or async_await_for_stream_break_guard.get("op") != "=="
    or async_await_for_stream_break_guard.get("right", {}).get("string") != "stop"
    or len(async_await_for_stream_break_body) != 2
    or async_await_for_stream_break_body[0].get("string") != "patched-stream-await-for-stream-break-"
    or async_await_for_stream_break_body[1].get("let_local") != 2
    or async_await_for_stream_break_finally.get("method") != "cancel"
):
    raise SystemExit(f"expected asyncGeneratedAwaitForStreamBreak generic Stream guarded break source, got {async_generated_await_for_stream_break}")
async_generated_await_for_stream_continue_break_finally = patch_by_member.get(
    "asyncGeneratedAwaitForStreamContinueBreakFinally", {}
).get("bytecode_source", {})
async_await_for_stream_continue_break_outer = (
    async_generated_await_for_stream_continue_break_finally.get("body", {}).get("try_finally", {})
)
async_await_for_stream_continue_break_let = async_await_for_stream_continue_break_outer.get("body", {}).get("let", {})
async_await_for_stream_continue_break_inner = (
    async_await_for_stream_continue_break_let.get("body", {}).get("try_finally", {})
)
async_await_for_stream_continue_break_loop = async_await_for_stream_continue_break_inner.get("body", {}).get("while_loop", {})
async_await_for_stream_continue_break_before = async_await_for_stream_continue_break_loop.get("before_break", {}).get("set_local", {})
async_await_for_stream_continue_break_break = async_await_for_stream_continue_break_loop.get("break_condition", {}).get("conditional", {})
async_await_for_stream_continue_break_body = async_await_for_stream_continue_break_loop.get("body", {}).get("conditional", {})
async_await_for_stream_continue_break_tail = async_await_for_stream_continue_break_body.get("else", {}).get("yield", {}).get("concat", [])
async_await_for_stream_continue_break_cleanup = async_await_for_stream_continue_break_outer.get("finally", {}).get("yield", {})
if (
    async_generated_await_for_stream_continue_break_finally.get("async_kind") != "async_star"
    or async_await_for_stream_continue_break_let.get("locals", [{}])[0].get("value", {}).get("arg") != "extra"
    or async_await_for_stream_continue_break_loop.get("condition", {}).get("await", {}).get("call_dynamic", {}).get("method") != "moveNext"
    or async_await_for_stream_continue_break_inner.get("finally", {}).get("await", {}).get("call_dynamic", {}).get("method") != "cancel"
    or async_await_for_stream_continue_break_before.get("id") != 2
    or async_await_for_stream_continue_break_break.get("condition", {}).get("op") != "=="
    or async_await_for_stream_continue_break_break.get("condition", {}).get("right", {}).get("string") != "skip"
    or async_await_for_stream_continue_break_break.get("then", {}).get("bool") is not False
    or async_await_for_stream_continue_break_break.get("else", {}).get("right", {}).get("string") != "stop"
    or async_await_for_stream_continue_break_body.get("condition", {}).get("op") != "=="
    or async_await_for_stream_continue_break_body.get("then", {}).get("null") is not True
    or len(async_await_for_stream_continue_break_tail) != 2
    or async_await_for_stream_continue_break_tail[0].get("string") != "patched-stream-await-for-stream-continue-break-"
    or async_await_for_stream_continue_break_tail[1].get("let_local") != 2
    or async_await_for_stream_continue_break_cleanup.get("string") != "patched-stream-await-for-stream-continue-break-cleanup"
):
    raise SystemExit(
        "expected asyncGeneratedAwaitForStreamContinueBreakFinally generic Stream "
        f"continue+break+finally source, got {async_generated_await_for_stream_continue_break_finally}"
    )
async_generated_await_for_nested = patch_by_member.get(
    "asyncGeneratedAwaitForNestedValueFinally", {}
).get("bytecode_source", {})
async_await_for_nested_outer = async_generated_await_for_nested.get("body", {}).get("try_finally", {})
async_await_for_nested_let = async_await_for_nested_outer.get("body", {}).get("let", {})
async_await_for_nested_inner_try = async_await_for_nested_let.get("body", {}).get("try_finally", {})
async_await_for_nested_loop = async_await_for_nested_inner_try.get("body", {}).get("while_loop", {})
async_await_for_nested_body = async_await_for_nested_loop.get("body", {}).get("seq", [])
async_await_for_nested_yield_for = (
    async_await_for_nested_body[1].get("yield_for_in", {})
    if len(async_await_for_nested_body) > 1
    else {}
)
async_await_for_nested_source = async_await_for_nested_yield_for.get("source", {}).get("list", [])
async_await_for_nested_source_concat = async_await_for_nested_source[0].get("concat", []) if async_await_for_nested_source else []
async_await_for_nested_yield = async_await_for_nested_yield_for.get("body", {}).get("yield", {}).get("concat", [])
async_await_for_nested_cleanup = async_await_for_nested_outer.get("finally", {}).get("yield", {})
if (
    async_generated_await_for_nested.get("async_kind") != "async_star"
    or async_await_for_nested_let.get("locals", [{}])[0].get("value", {}).get("arg") != "extra"
    or async_await_for_nested_loop.get("condition", {}).get("await", {}).get("call_dynamic", {}).get("method") != "moveNext"
    or async_await_for_nested_body[0].get("set_local", {}).get("id") != 2
    or len(async_await_for_nested_source_concat) != 2
    or async_await_for_nested_source_concat[0].get("let_local") != 2
    or async_await_for_nested_source_concat[1].get("string") != "-inner"
    or async_await_for_nested_yield_for.get("local", {}).get("name") != "inner"
    or len(async_await_for_nested_yield) != 2
    or async_await_for_nested_yield[0].get("string") != "patched-stream-await-for-nested-"
    or async_await_for_nested_yield[1].get("let_local") != 3
    or async_await_for_nested_inner_try.get("finally", {}).get("await", {}).get("call_dynamic", {}).get("method") != "cancel"
    or async_await_for_nested_cleanup.get("string") != "patched-stream-await-for-nested-cleanup"
):
    raise SystemExit(
        "expected asyncGeneratedAwaitForNestedValueFinally nested generic Stream await-for "
        f"source, got {async_generated_await_for_nested}"
    )
async_generated_await_for_nested_stream = patch_by_member.get(
    "asyncGeneratedAwaitForNestedStreamFinally", {}
).get("bytecode_source", {})
async_await_for_nested_stream_outer = async_generated_await_for_nested_stream.get("body", {}).get("try_finally", {})
async_await_for_nested_stream_let = async_await_for_nested_stream_outer.get("body", {}).get("let", {})
async_await_for_nested_stream_outer_try = async_await_for_nested_stream_let.get("body", {}).get("try_finally", {})
async_await_for_nested_stream_outer_loop = async_await_for_nested_stream_outer_try.get("body", {}).get("while_loop", {})
async_await_for_nested_stream_outer_body = async_await_for_nested_stream_outer_loop.get("body", {}).get("seq", [])
async_await_for_nested_stream_inner_let = (
    async_await_for_nested_stream_outer_body[1].get("let", {})
    if len(async_await_for_nested_stream_outer_body) > 1
    else {}
)
async_await_for_nested_stream_inner_try = async_await_for_nested_stream_inner_let.get("body", {}).get("try_finally", {})
async_await_for_nested_stream_inner_loop = async_await_for_nested_stream_inner_try.get("body", {}).get("while_loop", {})
async_await_for_nested_stream_inner_body = async_await_for_nested_stream_inner_loop.get("body", {}).get("seq", [])
async_await_for_nested_stream_yield = (
    async_await_for_nested_stream_inner_body[1].get("yield", {}).get("concat", [])
    if len(async_await_for_nested_stream_inner_body) > 1
    else []
)
async_await_for_nested_stream_cleanup = async_await_for_nested_stream_outer.get("finally", {}).get("yield", {})
if (
    async_generated_await_for_nested_stream.get("async_kind") != "async_star"
    or async_await_for_nested_stream_let.get("locals", [{}])[0].get("value", {}).get("arg") != "outer"
    or async_await_for_nested_stream_outer_loop.get("condition", {}).get("await", {}).get("call_dynamic", {}).get("method") != "moveNext"
    or async_await_for_nested_stream_outer_body[0].get("set_local", {}).get("id") != 2
    or async_await_for_nested_stream_inner_let.get("locals", [{}])[0].get("value", {}).get("arg") != "inner"
    or async_await_for_nested_stream_inner_loop.get("condition", {}).get("await", {}).get("call_dynamic", {}).get("method") != "moveNext"
    or async_await_for_nested_stream_inner_body[0].get("set_local", {}).get("id") != 5
    or len(async_await_for_nested_stream_yield) != 4
    or async_await_for_nested_stream_yield[0].get("string") != "patched-stream-await-for-nested-stream-"
    or async_await_for_nested_stream_yield[1].get("let_local") != 2
    or async_await_for_nested_stream_yield[2].get("string") != "-"
    or async_await_for_nested_stream_yield[3].get("let_local") != 5
    or async_await_for_nested_stream_inner_try.get("finally", {}).get("await", {}).get("call_dynamic", {}).get("method") != "cancel"
    or async_await_for_nested_stream_outer_try.get("finally", {}).get("await", {}).get("call_dynamic", {}).get("method") != "cancel"
    or async_await_for_nested_stream_cleanup.get("string") != "patched-stream-await-for-nested-stream-cleanup"
):
    raise SystemExit(
        "expected asyncGeneratedAwaitForNestedStreamFinally nested generic Stream await-for "
        f"source, got {async_generated_await_for_nested_stream}"
    )

null_sources = [
    f.get("bytecode_source", {}).get("body")
    for f in patch["functions"]
    if f.get("member_name") == "maybeNull"
]
if null_sources != [{"null": True}]:
    raise SystemExit(f"expected maybeNull null bytecode source, got {null_sources}")

label_sources = [
    f.get("bytecode_source", {}).get("body")
    for f in patch["functions"]
    if f.get("member_name") == "label"
]
if len(label_sources) != 1:
    raise SystemExit(f"expected one label bytecode source, got {label_sources}")
label_source = label_sources[0]
if "concat" not in label_source:
    raise SystemExit(f"expected label string concat source, got {label_source}")
if '"hello "' not in json.dumps(label_source) or '"!"' not in json.dumps(label_source):
    raise SystemExit(f"expected label concat constants, got {label_source}")
