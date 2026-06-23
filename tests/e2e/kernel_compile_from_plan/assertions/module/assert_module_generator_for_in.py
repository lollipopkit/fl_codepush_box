def assert_generator_for_in(module):
    sync_generated_for_in = next(
        item for item in module["functions"] if item["name"].endswith("::syncGeneratedForIn")
    )
    assert sync_generated_for_in.get("async_kind") == "sync_star", sync_generated_for_in
    assert sync_generated_for_in["code"].count(0x64) == 2, sync_generated_for_in
    async_generated_for_in = next(
        item for item in module["functions"] if item["name"].endswith("::asyncGeneratedForIn")
    )
    assert async_generated_for_in.get("async_kind") == "async_star", async_generated_for_in
    assert async_generated_for_in["code"].count(0x64) == 2, async_generated_for_in
    sync_generated_for_in_break = next(
        item for item in module["functions"] if item["name"].endswith("::syncGeneratedForInBreak")
    )
    assert sync_generated_for_in_break.get("async_kind") == "sync_star", sync_generated_for_in_break
    assert sync_generated_for_in_break["code"].count(0x64) == 2, sync_generated_for_in_break
    assert sync_generated_for_in_break["code"].count(0x30) >= 2, sync_generated_for_in_break
    assert 0x31 in sync_generated_for_in_break["code"], sync_generated_for_in_break
    assert 0x42 in sync_generated_for_in_break["code"], sync_generated_for_in_break
    assert 0x51 in sync_generated_for_in_break["code"], sync_generated_for_in_break
    assert any(entry.get("name") == "prefix" for entry in sync_generated_for_in_break.get("debug_locals", [])), sync_generated_for_in_break
    assert any(entry.get("name") == "value" for entry in sync_generated_for_in_break.get("debug_locals", [])), sync_generated_for_in_break
    async_generated_for_in_break = next(
        item for item in module["functions"] if item["name"].endswith("::asyncGeneratedForInBreak")
    )
    assert async_generated_for_in_break.get("async_kind") == "async_star", async_generated_for_in_break
    assert async_generated_for_in_break["code"].count(0x64) == 2, async_generated_for_in_break
    assert async_generated_for_in_break["code"].count(0x30) >= 2, async_generated_for_in_break
    assert 0x31 in async_generated_for_in_break["code"], async_generated_for_in_break
    assert 0x42 in async_generated_for_in_break["code"], async_generated_for_in_break
    assert 0x51 in async_generated_for_in_break["code"], async_generated_for_in_break
    assert any(entry.get("name") == "prefix" for entry in async_generated_for_in_break.get("debug_locals", [])), async_generated_for_in_break
    assert any(entry.get("name") == "value" for entry in async_generated_for_in_break.get("debug_locals", [])), async_generated_for_in_break
    sync_generated_for_in_break_first = next(
        item for item in module["functions"] if item["name"].endswith("::syncGeneratedForInBreakFirst")
    )
    assert sync_generated_for_in_break_first.get("async_kind") == "sync_star", sync_generated_for_in_break_first
    assert sync_generated_for_in_break_first["code"].count(0x64) == 1, sync_generated_for_in_break_first
    assert sync_generated_for_in_break_first["code"].count(0x30) >= 2, sync_generated_for_in_break_first
    assert 0x31 in sync_generated_for_in_break_first["code"], sync_generated_for_in_break_first
    assert 0x42 in sync_generated_for_in_break_first["code"], sync_generated_for_in_break_first
    assert 0x51 in sync_generated_for_in_break_first["code"], sync_generated_for_in_break_first
    assert any(entry.get("name") == "prefix" for entry in sync_generated_for_in_break_first.get("debug_locals", [])), sync_generated_for_in_break_first
    assert any(entry.get("name") == "value" for entry in sync_generated_for_in_break_first.get("debug_locals", [])), sync_generated_for_in_break_first
    async_generated_for_in_break_first = next(
        item for item in module["functions"] if item["name"].endswith("::asyncGeneratedForInBreakFirst")
    )
    assert async_generated_for_in_break_first.get("async_kind") == "async_star", async_generated_for_in_break_first
    assert async_generated_for_in_break_first["code"].count(0x64) == 1, async_generated_for_in_break_first
    assert async_generated_for_in_break_first["code"].count(0x30) >= 2, async_generated_for_in_break_first
    assert 0x31 in async_generated_for_in_break_first["code"], async_generated_for_in_break_first
    assert 0x42 in async_generated_for_in_break_first["code"], async_generated_for_in_break_first
    assert 0x51 in async_generated_for_in_break_first["code"], async_generated_for_in_break_first
    assert any(entry.get("name") == "prefix" for entry in async_generated_for_in_break_first.get("debug_locals", [])), async_generated_for_in_break_first
    assert any(entry.get("name") == "value" for entry in async_generated_for_in_break_first.get("debug_locals", [])), async_generated_for_in_break_first
    sync_generated_for_in_continue = next(
        item for item in module["functions"] if item["name"].endswith("::syncGeneratedForInContinue")
    )
    assert sync_generated_for_in_continue.get("async_kind") == "sync_star", sync_generated_for_in_continue
    assert sync_generated_for_in_continue["code"].count(0x64) == 1, sync_generated_for_in_continue
    assert 0x31 in sync_generated_for_in_continue["code"], sync_generated_for_in_continue
    assert 0x42 in sync_generated_for_in_continue["code"], sync_generated_for_in_continue
    assert 0x51 in sync_generated_for_in_continue["code"], sync_generated_for_in_continue
    assert any(entry.get("name") == "prefix" for entry in sync_generated_for_in_continue.get("debug_locals", [])), sync_generated_for_in_continue
    assert any(entry.get("name") == "value" for entry in sync_generated_for_in_continue.get("debug_locals", [])), sync_generated_for_in_continue
    async_generated_for_in_continue = next(
        item for item in module["functions"] if item["name"].endswith("::asyncGeneratedForInContinue")
    )
    assert async_generated_for_in_continue.get("async_kind") == "async_star", async_generated_for_in_continue
    assert async_generated_for_in_continue["code"].count(0x64) == 1, async_generated_for_in_continue
    assert 0x31 in async_generated_for_in_continue["code"], async_generated_for_in_continue
    assert 0x42 in async_generated_for_in_continue["code"], async_generated_for_in_continue
    assert 0x51 in async_generated_for_in_continue["code"], async_generated_for_in_continue
    assert any(entry.get("name") == "prefix" for entry in async_generated_for_in_continue.get("debug_locals", [])), async_generated_for_in_continue
    assert any(entry.get("name") == "value" for entry in async_generated_for_in_continue.get("debug_locals", [])), async_generated_for_in_continue
    sync_generated_for_in_continue_after_yield = next(
        item for item in module["functions"] if item["name"].endswith("::syncGeneratedForInContinueAfterYield")
    )
    assert sync_generated_for_in_continue_after_yield.get("async_kind") == "sync_star", sync_generated_for_in_continue_after_yield
    assert sync_generated_for_in_continue_after_yield["code"].count(0x64) == 2, sync_generated_for_in_continue_after_yield
    assert 0x31 in sync_generated_for_in_continue_after_yield["code"], sync_generated_for_in_continue_after_yield
    assert 0x42 in sync_generated_for_in_continue_after_yield["code"], sync_generated_for_in_continue_after_yield
    assert 0x51 in sync_generated_for_in_continue_after_yield["code"], sync_generated_for_in_continue_after_yield
    assert any(entry.get("name") == "prefix" for entry in sync_generated_for_in_continue_after_yield.get("debug_locals", [])), sync_generated_for_in_continue_after_yield
    assert any(entry.get("name") == "value" for entry in sync_generated_for_in_continue_after_yield.get("debug_locals", [])), sync_generated_for_in_continue_after_yield
    async_generated_for_in_continue_after_yield = next(
        item for item in module["functions"] if item["name"].endswith("::asyncGeneratedForInContinueAfterYield")
    )
    assert async_generated_for_in_continue_after_yield.get("async_kind") == "async_star", async_generated_for_in_continue_after_yield
    assert async_generated_for_in_continue_after_yield["code"].count(0x64) == 2, async_generated_for_in_continue_after_yield
    assert 0x31 in async_generated_for_in_continue_after_yield["code"], async_generated_for_in_continue_after_yield
    assert 0x42 in async_generated_for_in_continue_after_yield["code"], async_generated_for_in_continue_after_yield
    assert 0x51 in async_generated_for_in_continue_after_yield["code"], async_generated_for_in_continue_after_yield
    assert any(entry.get("name") == "prefix" for entry in async_generated_for_in_continue_after_yield.get("debug_locals", [])), async_generated_for_in_continue_after_yield
    assert any(entry.get("name") == "value" for entry in async_generated_for_in_continue_after_yield.get("debug_locals", [])), async_generated_for_in_continue_after_yield
