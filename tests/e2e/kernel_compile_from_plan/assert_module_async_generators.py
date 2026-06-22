from assert_module_async_future import assert_async_future_module
from assert_module_dynamic_for_in import assert_dynamic_for_in
from assert_module_generator_for_in import assert_generator_for_in
from assert_module_stream_generators import assert_stream_generators

def assert_async_generators(module):
    function = next(
        item for item in module["functions"] if item["name"].endswith("::mainValue")
    )
    assert_async_future_module(module)
    sync_generated = next(
        item for item in module["functions"] if item["name"].endswith("::syncGenerated")
    )
    assert sync_generated.get("async_kind") == "sync_star", sync_generated
    assert 0x64 in sync_generated["code"], sync_generated
    async_generated = next(
        item for item in module["functions"] if item["name"].endswith("::asyncGenerated")
    )
    assert async_generated.get("async_kind") == "async_star", async_generated
    assert 0x64 in async_generated["code"], async_generated
    async_generated_await = next(
        item for item in module["functions"] if item["name"].endswith("::asyncGeneratedAwait")
    )
    assert async_generated_await.get("async_kind") == "async_star", async_generated_await
    assert 0x62 in async_generated_await["code"], async_generated_await
    assert 0x64 in async_generated_await["code"], async_generated_await
    assert 0x04 in async_generated_await["code"], async_generated_await
    assert {"slot": 0, "name": "ready"} in async_generated_await.get("debug_locals", []), async_generated_await
    assert any(entry.get("name") == "value" for entry in async_generated_await.get("debug_locals", [])), async_generated_await
    async_generated_try_finally = next(
        item for item in module["functions"] if item["name"].endswith("::asyncGeneratedTryFinally")
    )
    assert async_generated_try_finally.get("async_kind") == "async_star", async_generated_try_finally
    assert 0x62 in async_generated_try_finally["code"], async_generated_try_finally
    assert 0x64 in async_generated_try_finally["code"], async_generated_try_finally
    assert 0x65 in async_generated_try_finally["code"], async_generated_try_finally
    assert 0x66 in async_generated_try_finally["code"], async_generated_try_finally
    assert {"slot": 0, "name": "ready"} in async_generated_try_finally.get("debug_locals", []), async_generated_try_finally
    assert any(entry.get("name") == "cleanup" for entry in async_generated_try_finally.get("debug_locals", [])), async_generated_try_finally
    async_generated_finally_yield = next(
        item for item in module["functions"] if item["name"].endswith("::asyncGeneratedFinallyYield")
    )
    assert async_generated_finally_yield.get("async_kind") == "async_star", async_generated_finally_yield
    assert 0x62 in async_generated_finally_yield["code"], async_generated_finally_yield
    assert async_generated_finally_yield["code"].count(0x64) == 2, async_generated_finally_yield
    assert 0x65 in async_generated_finally_yield["code"], async_generated_finally_yield
    assert 0x66 in async_generated_finally_yield["code"], async_generated_finally_yield
    assert any(
        constant.get("type") == "String" and constant.get("value") == "patched-stream-finally-yield-cleanup"
        for constant in async_generated_finally_yield["constants"]
    ), async_generated_finally_yield
    async_generated_catch_await = next(
        item for item in module["functions"] if item["name"].endswith("::asyncGeneratedCatchAwait")
    )
    assert async_generated_catch_await.get("async_kind") == "async_star", async_generated_catch_await
    assert 0x61 in async_generated_catch_await["code"], async_generated_catch_await
    assert 0x62 in async_generated_catch_await["code"], async_generated_catch_await
    assert async_generated_catch_await["code"].count(0x64) == 2, async_generated_catch_await
    assert {"slot": 0, "name": "ready"} in async_generated_catch_await.get("debug_locals", []), async_generated_catch_await
    assert any(
        constant.get("type") == "String" and constant.get("value") == "patched-stream-caught-"
        for constant in async_generated_catch_await["constants"]
    ), async_generated_catch_await
    sync_generated_many = next(
        item for item in module["functions"] if item["name"].endswith("::syncGeneratedMany")
    )
    assert sync_generated_many.get("async_kind") == "sync_star", sync_generated_many
    assert sync_generated_many["code"].count(0x64) == 3, sync_generated_many
    assert 0x31 in sync_generated_many["code"], sync_generated_many
    assert {"slot": 0, "name": "enabled"} in sync_generated_many.get("debug_locals", []), sync_generated_many
    assert any(entry.get("name") == "prefix" for entry in sync_generated_many.get("debug_locals", [])), sync_generated_many
    async_generated_many = next(
        item for item in module["functions"] if item["name"].endswith("::asyncGeneratedMany")
    )
    assert async_generated_many.get("async_kind") == "async_star", async_generated_many
    assert async_generated_many["code"].count(0x64) == 3, async_generated_many
    assert 0x31 in async_generated_many["code"], async_generated_many
    sync_generated_while = next(
        item for item in module["functions"] if item["name"].endswith("::syncGeneratedWhile")
    )
    assert sync_generated_while.get("async_kind") == "sync_star", sync_generated_while
    assert sync_generated_while["code"].count(0x64) == 1, sync_generated_while
    assert 0x04 in sync_generated_while["code"], sync_generated_while
    assert 0x10 in sync_generated_while["code"], sync_generated_while
    assert 0x20 in sync_generated_while["code"], sync_generated_while
    assert 0x30 in sync_generated_while["code"], sync_generated_while
    assert 0x31 in sync_generated_while["code"], sync_generated_while
    assert any(entry.get("name") == "i" for entry in sync_generated_while.get("debug_locals", [])), sync_generated_while
    async_generated_while = next(
        item for item in module["functions"] if item["name"].endswith("::asyncGeneratedWhile")
    )
    assert async_generated_while.get("async_kind") == "async_star", async_generated_while
    assert async_generated_while["code"].count(0x64) == 1, async_generated_while
    assert 0x04 in async_generated_while["code"], async_generated_while
    assert 0x10 in async_generated_while["code"], async_generated_while
    assert 0x20 in async_generated_while["code"], async_generated_while
    assert 0x30 in async_generated_while["code"], async_generated_while
    assert 0x31 in async_generated_while["code"], async_generated_while
    assert any(entry.get("name") == "i" for entry in async_generated_while.get("debug_locals", [])), async_generated_while
    sync_generated_while_break = next(
        item for item in module["functions"] if item["name"].endswith("::syncGeneratedWhileBreak")
    )
    assert sync_generated_while_break.get("async_kind") == "sync_star", sync_generated_while_break
    assert sync_generated_while_break["code"].count(0x64) == 2, sync_generated_while_break
    assert 0x04 in sync_generated_while_break["code"], sync_generated_while_break
    assert 0x10 in sync_generated_while_break["code"], sync_generated_while_break
    assert 0x20 in sync_generated_while_break["code"], sync_generated_while_break
    assert 0x21 in sync_generated_while_break["code"], sync_generated_while_break
    assert sync_generated_while_break["code"].count(0x30) >= 2, sync_generated_while_break
    assert sync_generated_while_break["code"].count(0x31) >= 2, sync_generated_while_break
    assert any(entry.get("name") == "i" for entry in sync_generated_while_break.get("debug_locals", [])), sync_generated_while_break
    async_generated_while_break = next(
        item for item in module["functions"] if item["name"].endswith("::asyncGeneratedWhileBreak")
    )
    assert async_generated_while_break.get("async_kind") == "async_star", async_generated_while_break
    assert async_generated_while_break["code"].count(0x64) == 2, async_generated_while_break
    assert 0x04 in async_generated_while_break["code"], async_generated_while_break
    assert 0x10 in async_generated_while_break["code"], async_generated_while_break
    assert 0x20 in async_generated_while_break["code"], async_generated_while_break
    assert 0x21 in async_generated_while_break["code"], async_generated_while_break
    assert async_generated_while_break["code"].count(0x30) >= 2, async_generated_while_break
    assert async_generated_while_break["code"].count(0x31) >= 2, async_generated_while_break
    assert any(entry.get("name") == "i" for entry in async_generated_while_break.get("debug_locals", [])), async_generated_while_break
    sync_generated_while_continue = next(
        item for item in module["functions"] if item["name"].endswith("::syncGeneratedWhileContinue")
    )
    assert sync_generated_while_continue.get("async_kind") == "sync_star", sync_generated_while_continue
    assert sync_generated_while_continue["code"].count(0x64) == 2, sync_generated_while_continue
    assert 0x04 in sync_generated_while_continue["code"], sync_generated_while_continue
    assert 0x10 in sync_generated_while_continue["code"], sync_generated_while_continue
    assert 0x20 in sync_generated_while_continue["code"], sync_generated_while_continue
    assert 0x21 in sync_generated_while_continue["code"], sync_generated_while_continue
    assert sync_generated_while_continue["code"].count(0x30) >= 2, sync_generated_while_continue
    assert sync_generated_while_continue["code"].count(0x31) >= 2, sync_generated_while_continue
    assert any(entry.get("name") == "i" for entry in sync_generated_while_continue.get("debug_locals", [])), sync_generated_while_continue
    async_generated_while_continue = next(
        item for item in module["functions"] if item["name"].endswith("::asyncGeneratedWhileContinue")
    )
    assert async_generated_while_continue.get("async_kind") == "async_star", async_generated_while_continue
    assert async_generated_while_continue["code"].count(0x64) == 2, async_generated_while_continue
    assert 0x04 in async_generated_while_continue["code"], async_generated_while_continue
    assert 0x10 in async_generated_while_continue["code"], async_generated_while_continue
    assert 0x20 in async_generated_while_continue["code"], async_generated_while_continue
    assert 0x21 in async_generated_while_continue["code"], async_generated_while_continue
    assert async_generated_while_continue["code"].count(0x30) >= 2, async_generated_while_continue
    assert async_generated_while_continue["code"].count(0x31) >= 2, async_generated_while_continue
    assert any(entry.get("name") == "i" for entry in async_generated_while_continue.get("debug_locals", [])), async_generated_while_continue
    sync_generated_while_continue_break = next(
        item for item in module["functions"] if item["name"].endswith("::syncGeneratedWhileContinueBreak")
    )
    assert sync_generated_while_continue_break.get("async_kind") == "sync_star", sync_generated_while_continue_break
    assert sync_generated_while_continue_break["code"].count(0x64) == 3, sync_generated_while_continue_break
    assert 0x04 in sync_generated_while_continue_break["code"], sync_generated_while_continue_break
    assert 0x10 in sync_generated_while_continue_break["code"], sync_generated_while_continue_break
    assert 0x20 in sync_generated_while_continue_break["code"], sync_generated_while_continue_break
    assert 0x21 in sync_generated_while_continue_break["code"], sync_generated_while_continue_break
    assert sync_generated_while_continue_break["code"].count(0x30) >= 2, sync_generated_while_continue_break
    assert sync_generated_while_continue_break["code"].count(0x31) >= 3, sync_generated_while_continue_break
    assert any(entry.get("name") == "i" for entry in sync_generated_while_continue_break.get("debug_locals", [])), sync_generated_while_continue_break
    async_generated_while_continue_break = next(
        item for item in module["functions"] if item["name"].endswith("::asyncGeneratedWhileContinueBreak")
    )
    assert async_generated_while_continue_break.get("async_kind") == "async_star", async_generated_while_continue_break
    assert async_generated_while_continue_break["code"].count(0x64) == 3, async_generated_while_continue_break
    assert 0x04 in async_generated_while_continue_break["code"], async_generated_while_continue_break
    assert 0x10 in async_generated_while_continue_break["code"], async_generated_while_continue_break
    assert 0x20 in async_generated_while_continue_break["code"], async_generated_while_continue_break
    assert 0x21 in async_generated_while_continue_break["code"], async_generated_while_continue_break
    assert async_generated_while_continue_break["code"].count(0x30) >= 2, async_generated_while_continue_break
    assert async_generated_while_continue_break["code"].count(0x31) >= 3, async_generated_while_continue_break
    assert any(entry.get("name") == "i" for entry in async_generated_while_continue_break.get("debug_locals", [])), async_generated_while_continue_break
    sync_generated_do_while = next(
        item for item in module["functions"] if item["name"].endswith("::syncGeneratedDoWhile")
    )
    assert sync_generated_do_while.get("async_kind") == "sync_star", sync_generated_do_while
    assert sync_generated_do_while["code"].count(0x64) == 2, sync_generated_do_while
    assert 0x04 in sync_generated_do_while["code"], sync_generated_do_while
    assert 0x30 in sync_generated_do_while["code"], sync_generated_do_while
    assert 0x31 in sync_generated_do_while["code"], sync_generated_do_while
    assert any(entry.get("name") == "i" for entry in sync_generated_do_while.get("debug_locals", [])), sync_generated_do_while
    async_generated_do_while = next(
        item for item in module["functions"] if item["name"].endswith("::asyncGeneratedDoWhile")
    )
    assert async_generated_do_while.get("async_kind") == "async_star", async_generated_do_while
    assert async_generated_do_while["code"].count(0x64) == 2, async_generated_do_while
    assert 0x04 in async_generated_do_while["code"], async_generated_do_while
    assert 0x30 in async_generated_do_while["code"], async_generated_do_while
    assert 0x31 in async_generated_do_while["code"], async_generated_do_while
    assert any(entry.get("name") == "i" for entry in async_generated_do_while.get("debug_locals", [])), async_generated_do_while
    sync_generated_do_while_break = next(
        item for item in module["functions"] if item["name"].endswith("::syncGeneratedDoWhileBreak")
    )
    assert sync_generated_do_while_break.get("async_kind") == "sync_star", sync_generated_do_while_break
    assert sync_generated_do_while_break["code"].count(0x64) == 4, sync_generated_do_while_break
    assert 0x04 in sync_generated_do_while_break["code"], sync_generated_do_while_break
    assert 0x10 in sync_generated_do_while_break["code"], sync_generated_do_while_break
    assert 0x20 in sync_generated_do_while_break["code"], sync_generated_do_while_break
    assert 0x21 in sync_generated_do_while_break["code"], sync_generated_do_while_break
    assert sync_generated_do_while_break["code"].count(0x30) >= 2, sync_generated_do_while_break
    assert sync_generated_do_while_break["code"].count(0x31) >= 2, sync_generated_do_while_break
    assert any(entry.get("name") == "i" for entry in sync_generated_do_while_break.get("debug_locals", [])), sync_generated_do_while_break
    async_generated_do_while_break = next(
        item for item in module["functions"] if item["name"].endswith("::asyncGeneratedDoWhileBreak")
    )
    assert async_generated_do_while_break.get("async_kind") == "async_star", async_generated_do_while_break
    assert async_generated_do_while_break["code"].count(0x64) == 4, async_generated_do_while_break
    assert 0x04 in async_generated_do_while_break["code"], async_generated_do_while_break
    assert 0x10 in async_generated_do_while_break["code"], async_generated_do_while_break
    assert 0x20 in async_generated_do_while_break["code"], async_generated_do_while_break
    assert 0x21 in async_generated_do_while_break["code"], async_generated_do_while_break
    assert async_generated_do_while_break["code"].count(0x30) >= 2, async_generated_do_while_break
    assert async_generated_do_while_break["code"].count(0x31) >= 2, async_generated_do_while_break
    assert any(entry.get("name") == "i" for entry in async_generated_do_while_break.get("debug_locals", [])), async_generated_do_while_break
    sync_generated_do_while_continue = next(
        item for item in module["functions"] if item["name"].endswith("::syncGeneratedDoWhileContinue")
    )
    assert sync_generated_do_while_continue.get("async_kind") == "sync_star", sync_generated_do_while_continue
    assert sync_generated_do_while_continue["code"].count(0x64) == 4, sync_generated_do_while_continue
    assert 0x04 in sync_generated_do_while_continue["code"], sync_generated_do_while_continue
    assert 0x10 in sync_generated_do_while_continue["code"], sync_generated_do_while_continue
    assert 0x20 in sync_generated_do_while_continue["code"], sync_generated_do_while_continue
    assert 0x21 in sync_generated_do_while_continue["code"], sync_generated_do_while_continue
    assert sync_generated_do_while_continue["code"].count(0x30) >= 2, sync_generated_do_while_continue
    assert sync_generated_do_while_continue["code"].count(0x31) >= 2, sync_generated_do_while_continue
    assert any(entry.get("name") == "i" for entry in sync_generated_do_while_continue.get("debug_locals", [])), sync_generated_do_while_continue
    async_generated_do_while_continue = next(
        item for item in module["functions"] if item["name"].endswith("::asyncGeneratedDoWhileContinue")
    )
    assert async_generated_do_while_continue.get("async_kind") == "async_star", async_generated_do_while_continue
    assert async_generated_do_while_continue["code"].count(0x64) == 4, async_generated_do_while_continue
    assert 0x04 in async_generated_do_while_continue["code"], async_generated_do_while_continue
    assert 0x10 in async_generated_do_while_continue["code"], async_generated_do_while_continue
    assert 0x20 in async_generated_do_while_continue["code"], async_generated_do_while_continue
    assert 0x21 in async_generated_do_while_continue["code"], async_generated_do_while_continue
    assert async_generated_do_while_continue["code"].count(0x30) >= 2, async_generated_do_while_continue
    assert async_generated_do_while_continue["code"].count(0x31) >= 2, async_generated_do_while_continue
    assert any(entry.get("name") == "i" for entry in async_generated_do_while_continue.get("debug_locals", [])), async_generated_do_while_continue
    sync_generated_do_while_continue_break = next(
        item for item in module["functions"] if item["name"].endswith("::syncGeneratedDoWhileContinueBreak")
    )
    assert sync_generated_do_while_continue_break.get("async_kind") == "sync_star", sync_generated_do_while_continue_break
    assert sync_generated_do_while_continue_break["code"].count(0x64) == 9, sync_generated_do_while_continue_break
    assert 0x04 in sync_generated_do_while_continue_break["code"], sync_generated_do_while_continue_break
    assert 0x10 in sync_generated_do_while_continue_break["code"], sync_generated_do_while_continue_break
    assert 0x20 in sync_generated_do_while_continue_break["code"], sync_generated_do_while_continue_break
    assert 0x21 in sync_generated_do_while_continue_break["code"], sync_generated_do_while_continue_break
    assert sync_generated_do_while_continue_break["code"].count(0x30) >= 8, sync_generated_do_while_continue_break
    assert sync_generated_do_while_continue_break["code"].count(0x31) >= 8, sync_generated_do_while_continue_break
    assert any(entry.get("name") == "i" for entry in sync_generated_do_while_continue_break.get("debug_locals", [])), sync_generated_do_while_continue_break
    async_generated_do_while_continue_break = next(
        item for item in module["functions"] if item["name"].endswith("::asyncGeneratedDoWhileContinueBreak")
    )
    assert async_generated_do_while_continue_break.get("async_kind") == "async_star", async_generated_do_while_continue_break
    assert async_generated_do_while_continue_break["code"].count(0x64) == 9, async_generated_do_while_continue_break
    assert 0x04 in async_generated_do_while_continue_break["code"], async_generated_do_while_continue_break
    assert 0x10 in async_generated_do_while_continue_break["code"], async_generated_do_while_continue_break
    assert 0x20 in async_generated_do_while_continue_break["code"], async_generated_do_while_continue_break
    assert 0x21 in async_generated_do_while_continue_break["code"], async_generated_do_while_continue_break
    assert async_generated_do_while_continue_break["code"].count(0x30) >= 8, async_generated_do_while_continue_break
    assert async_generated_do_while_continue_break["code"].count(0x31) >= 8, async_generated_do_while_continue_break
    assert any(entry.get("name") == "i" for entry in async_generated_do_while_continue_break.get("debug_locals", [])), async_generated_do_while_continue_break
    sync_generated_for_loop = next(
        item for item in module["functions"] if item["name"].endswith("::syncGeneratedForLoop")
    )
    assert sync_generated_for_loop.get("async_kind") == "sync_star", sync_generated_for_loop
    assert sync_generated_for_loop["code"].count(0x64) == 1, sync_generated_for_loop
    assert 0x04 in sync_generated_for_loop["code"], sync_generated_for_loop
    assert 0x10 in sync_generated_for_loop["code"], sync_generated_for_loop
    assert 0x20 in sync_generated_for_loop["code"], sync_generated_for_loop
    assert 0x30 in sync_generated_for_loop["code"], sync_generated_for_loop
    assert 0x31 in sync_generated_for_loop["code"], sync_generated_for_loop
    assert any(entry.get("name") == "i" for entry in sync_generated_for_loop.get("debug_locals", [])), sync_generated_for_loop
    async_generated_for_loop = next(
        item for item in module["functions"] if item["name"].endswith("::asyncGeneratedForLoop")
    )
    assert async_generated_for_loop.get("async_kind") == "async_star", async_generated_for_loop
    assert async_generated_for_loop["code"].count(0x64) == 1, async_generated_for_loop
    assert 0x04 in async_generated_for_loop["code"], async_generated_for_loop
    assert 0x10 in async_generated_for_loop["code"], async_generated_for_loop
    assert 0x20 in async_generated_for_loop["code"], async_generated_for_loop
    assert 0x30 in async_generated_for_loop["code"], async_generated_for_loop
    assert 0x31 in async_generated_for_loop["code"], async_generated_for_loop
    assert any(entry.get("name") == "i" for entry in async_generated_for_loop.get("debug_locals", [])), async_generated_for_loop
    sync_generated_for_loop_postinc = next(
        item for item in module["functions"] if item["name"].endswith("::syncGeneratedForLoopPostIncrement")
    )
    assert sync_generated_for_loop_postinc.get("async_kind") == "sync_star", sync_generated_for_loop_postinc
    assert sync_generated_for_loop_postinc["code"].count(0x64) == 1, sync_generated_for_loop_postinc
    assert 0x04 in sync_generated_for_loop_postinc["code"], sync_generated_for_loop_postinc
    assert 0x20 in sync_generated_for_loop_postinc["code"], sync_generated_for_loop_postinc
    assert 0x30 in sync_generated_for_loop_postinc["code"], sync_generated_for_loop_postinc
    assert 0x31 in sync_generated_for_loop_postinc["code"], sync_generated_for_loop_postinc
    assert any(entry.get("name") == "i" for entry in sync_generated_for_loop_postinc.get("debug_locals", [])), sync_generated_for_loop_postinc
    async_generated_for_loop_postinc = next(
        item for item in module["functions"] if item["name"].endswith("::asyncGeneratedForLoopPostIncrement")
    )
    assert async_generated_for_loop_postinc.get("async_kind") == "async_star", async_generated_for_loop_postinc
    assert async_generated_for_loop_postinc["code"].count(0x64) == 1, async_generated_for_loop_postinc
    assert 0x04 in async_generated_for_loop_postinc["code"], async_generated_for_loop_postinc
    assert 0x20 in async_generated_for_loop_postinc["code"], async_generated_for_loop_postinc
    assert 0x30 in async_generated_for_loop_postinc["code"], async_generated_for_loop_postinc
    assert 0x31 in async_generated_for_loop_postinc["code"], async_generated_for_loop_postinc
    assert any(entry.get("name") == "i" for entry in async_generated_for_loop_postinc.get("debug_locals", [])), async_generated_for_loop_postinc
    sync_generated_for_loop_multi = next(
        item for item in module["functions"] if item["name"].endswith("::syncGeneratedForLoopMultiUpdate")
    )
    assert sync_generated_for_loop_multi.get("async_kind") == "sync_star", sync_generated_for_loop_multi
    assert sync_generated_for_loop_multi["code"].count(0x64) == 1, sync_generated_for_loop_multi
    assert sync_generated_for_loop_multi["code"].count(0x04) >= 4, sync_generated_for_loop_multi
    assert 0x30 in sync_generated_for_loop_multi["code"], sync_generated_for_loop_multi
    assert 0x31 in sync_generated_for_loop_multi["code"], sync_generated_for_loop_multi
    sync_for_multi_names = {entry.get("name") for entry in sync_generated_for_loop_multi.get("debug_locals", [])}
    assert {"i", "j"}.issubset(sync_for_multi_names), sync_generated_for_loop_multi
    async_generated_for_loop_multi = next(
        item for item in module["functions"] if item["name"].endswith("::asyncGeneratedForLoopMultiUpdate")
    )
    assert async_generated_for_loop_multi.get("async_kind") == "async_star", async_generated_for_loop_multi
    assert async_generated_for_loop_multi["code"].count(0x64) == 1, async_generated_for_loop_multi
    assert async_generated_for_loop_multi["code"].count(0x04) >= 4, async_generated_for_loop_multi
    assert 0x30 in async_generated_for_loop_multi["code"], async_generated_for_loop_multi
    assert 0x31 in async_generated_for_loop_multi["code"], async_generated_for_loop_multi
    async_for_multi_names = {entry.get("name") for entry in async_generated_for_loop_multi.get("debug_locals", [])}
    assert {"i", "j"}.issubset(async_for_multi_names), async_generated_for_loop_multi
    sync_generated_for_loop_external = next(
        item for item in module["functions"] if item["name"].endswith("::syncGeneratedForLoopExternalLocal")
    )
    assert sync_generated_for_loop_external.get("async_kind") == "sync_star", sync_generated_for_loop_external
    assert sync_generated_for_loop_external["code"].count(0x64) == 1, sync_generated_for_loop_external
    assert 0x04 in sync_generated_for_loop_external["code"], sync_generated_for_loop_external
    assert 0x30 in sync_generated_for_loop_external["code"], sync_generated_for_loop_external
    assert 0x31 in sync_generated_for_loop_external["code"], sync_generated_for_loop_external
    assert any(entry.get("name") == "i" for entry in sync_generated_for_loop_external.get("debug_locals", [])), sync_generated_for_loop_external
    async_generated_for_loop_external = next(
        item for item in module["functions"] if item["name"].endswith("::asyncGeneratedForLoopExternalLocal")
    )
    assert async_generated_for_loop_external.get("async_kind") == "async_star", async_generated_for_loop_external
    assert async_generated_for_loop_external["code"].count(0x64) == 1, async_generated_for_loop_external
    assert 0x04 in async_generated_for_loop_external["code"], async_generated_for_loop_external
    assert 0x30 in async_generated_for_loop_external["code"], async_generated_for_loop_external
    assert 0x31 in async_generated_for_loop_external["code"], async_generated_for_loop_external
    assert any(entry.get("name") == "i" for entry in async_generated_for_loop_external.get("debug_locals", [])), async_generated_for_loop_external
    sync_generated_for_loop_body_update = next(
        item for item in module["functions"] if item["name"].endswith("::syncGeneratedForLoopBodyUpdate")
    )
    assert sync_generated_for_loop_body_update.get("async_kind") == "sync_star", sync_generated_for_loop_body_update
    assert sync_generated_for_loop_body_update["code"].count(0x64) == 1, sync_generated_for_loop_body_update
    assert 0x04 in sync_generated_for_loop_body_update["code"], sync_generated_for_loop_body_update
    assert 0x30 in sync_generated_for_loop_body_update["code"], sync_generated_for_loop_body_update
    assert 0x31 in sync_generated_for_loop_body_update["code"], sync_generated_for_loop_body_update
    assert any(entry.get("name") == "i" for entry in sync_generated_for_loop_body_update.get("debug_locals", [])), sync_generated_for_loop_body_update
    async_generated_for_loop_body_update = next(
        item for item in module["functions"] if item["name"].endswith("::asyncGeneratedForLoopBodyUpdate")
    )
    assert async_generated_for_loop_body_update.get("async_kind") == "async_star", async_generated_for_loop_body_update
    assert async_generated_for_loop_body_update["code"].count(0x64) == 1, async_generated_for_loop_body_update
    assert 0x04 in async_generated_for_loop_body_update["code"], async_generated_for_loop_body_update
    assert 0x30 in async_generated_for_loop_body_update["code"], async_generated_for_loop_body_update
    assert 0x31 in async_generated_for_loop_body_update["code"], async_generated_for_loop_body_update
    assert any(entry.get("name") == "i" for entry in async_generated_for_loop_body_update.get("debug_locals", [])), async_generated_for_loop_body_update
    sync_generated_for_loop_continue = next(
        item for item in module["functions"] if item["name"].endswith("::syncGeneratedForLoopContinue")
    )
    assert sync_generated_for_loop_continue.get("async_kind") == "sync_star", sync_generated_for_loop_continue
    assert sync_generated_for_loop_continue["code"].count(0x64) == 2, sync_generated_for_loop_continue
    assert 0x04 in sync_generated_for_loop_continue["code"], sync_generated_for_loop_continue
    assert 0x21 in sync_generated_for_loop_continue["code"], sync_generated_for_loop_continue
    assert sync_generated_for_loop_continue["code"].count(0x30) >= 1, sync_generated_for_loop_continue
    assert sync_generated_for_loop_continue["code"].count(0x31) >= 2, sync_generated_for_loop_continue
    assert any(entry.get("name") == "i" for entry in sync_generated_for_loop_continue.get("debug_locals", [])), sync_generated_for_loop_continue
    async_generated_for_loop_continue = next(
        item for item in module["functions"] if item["name"].endswith("::asyncGeneratedForLoopContinue")
    )
    assert async_generated_for_loop_continue.get("async_kind") == "async_star", async_generated_for_loop_continue
    assert async_generated_for_loop_continue["code"].count(0x64) == 2, async_generated_for_loop_continue
    assert 0x04 in async_generated_for_loop_continue["code"], async_generated_for_loop_continue
    assert 0x21 in async_generated_for_loop_continue["code"], async_generated_for_loop_continue
    assert async_generated_for_loop_continue["code"].count(0x30) >= 1, async_generated_for_loop_continue
    assert async_generated_for_loop_continue["code"].count(0x31) >= 2, async_generated_for_loop_continue
    assert any(entry.get("name") == "i" for entry in async_generated_for_loop_continue.get("debug_locals", [])), async_generated_for_loop_continue
    sync_generated_for_loop_continue_break = next(
        item for item in module["functions"] if item["name"].endswith("::syncGeneratedForLoopContinueBreak")
    )
    assert sync_generated_for_loop_continue_break.get("async_kind") == "sync_star", sync_generated_for_loop_continue_break
    assert sync_generated_for_loop_continue_break["code"].count(0x64) == 3, sync_generated_for_loop_continue_break
    assert 0x04 in sync_generated_for_loop_continue_break["code"], sync_generated_for_loop_continue_break
    assert 0x21 in sync_generated_for_loop_continue_break["code"], sync_generated_for_loop_continue_break
    assert sync_generated_for_loop_continue_break["code"].count(0x30) >= 2, sync_generated_for_loop_continue_break
    assert sync_generated_for_loop_continue_break["code"].count(0x31) >= 3, sync_generated_for_loop_continue_break
    assert any(entry.get("name") == "i" for entry in sync_generated_for_loop_continue_break.get("debug_locals", [])), sync_generated_for_loop_continue_break
    async_generated_for_loop_continue_break = next(
        item for item in module["functions"] if item["name"].endswith("::asyncGeneratedForLoopContinueBreak")
    )
    assert async_generated_for_loop_continue_break.get("async_kind") == "async_star", async_generated_for_loop_continue_break
    assert async_generated_for_loop_continue_break["code"].count(0x64) == 3, async_generated_for_loop_continue_break
    assert 0x04 in async_generated_for_loop_continue_break["code"], async_generated_for_loop_continue_break
    assert 0x21 in async_generated_for_loop_continue_break["code"], async_generated_for_loop_continue_break
    assert async_generated_for_loop_continue_break["code"].count(0x30) >= 2, async_generated_for_loop_continue_break
    assert async_generated_for_loop_continue_break["code"].count(0x31) >= 3, async_generated_for_loop_continue_break
    assert any(entry.get("name") == "i" for entry in async_generated_for_loop_continue_break.get("debug_locals", [])), async_generated_for_loop_continue_break
    sync_generated_for_loop_break = next(
        item for item in module["functions"] if item["name"].endswith("::syncGeneratedForLoopBreak")
    )
    assert sync_generated_for_loop_break.get("async_kind") == "sync_star", sync_generated_for_loop_break
    assert sync_generated_for_loop_break["code"].count(0x64) == 2, sync_generated_for_loop_break
    assert 0x04 in sync_generated_for_loop_break["code"], sync_generated_for_loop_break
    assert 0x21 in sync_generated_for_loop_break["code"], sync_generated_for_loop_break
    assert sync_generated_for_loop_break["code"].count(0x30) >= 2, sync_generated_for_loop_break
    assert sync_generated_for_loop_break["code"].count(0x31) >= 2, sync_generated_for_loop_break
    assert any(entry.get("name") == "i" for entry in sync_generated_for_loop_break.get("debug_locals", [])), sync_generated_for_loop_break
    async_generated_for_loop_break = next(
        item for item in module["functions"] if item["name"].endswith("::asyncGeneratedForLoopBreak")
    )
    assert async_generated_for_loop_break.get("async_kind") == "async_star", async_generated_for_loop_break
    assert async_generated_for_loop_break["code"].count(0x64) == 2, async_generated_for_loop_break
    assert 0x04 in async_generated_for_loop_break["code"], async_generated_for_loop_break
    assert 0x21 in async_generated_for_loop_break["code"], async_generated_for_loop_break
    assert async_generated_for_loop_break["code"].count(0x30) >= 2, async_generated_for_loop_break
    assert async_generated_for_loop_break["code"].count(0x31) >= 2, async_generated_for_loop_break
    assert any(entry.get("name") == "i" for entry in async_generated_for_loop_break.get("debug_locals", [])), async_generated_for_loop_break
    assert_generator_for_in(module)
    assert_dynamic_for_in(module)
    assert_stream_generators(module)
    double_count = sum(
        1
        for constant in function["constants"]
        if constant.get("type") == "Double" and constant.get("value") == 1.5
    )
    assert double_count == 1, function
    assert any(
        constant.get("type") == "Double" and constant.get("value") == 1.5
        for constant in function["constants"]
    ), function
