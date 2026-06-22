def assert_inventory_local_mutation_sources(patch_by_member):
    sync_local_mutation = patch_by_member.get("syncLocalMutation", {}).get("bytecode_source", {})
    sync_local_mutation_let = sync_local_mutation.get("body", {}).get("let", {})
    sync_local_mutation_locals = sync_local_mutation_let.get("locals", [])
    sync_local_mutation_tail = sync_local_mutation_let.get("body", {}).get("seq", [])
    sync_local_mutation_set = sync_local_mutation_tail[0].get("set_local", {}) if sync_local_mutation_tail else {}
    sync_local_mutation_concat = sync_local_mutation_set.get("value", {}).get("concat", [])
    if (
        sync_local_mutation.get("return_type") != "String"
        or sync_local_mutation.get("params") != ["name"]
        or len(sync_local_mutation_locals) != 1
        or sync_local_mutation_locals[0].get("id") != 0
        or sync_local_mutation_locals[0].get("name") != "out"
        or sync_local_mutation_locals[0].get("value", {}).get("string") != "patched-local"
        or len(sync_local_mutation_tail) != 2
        or sync_local_mutation_set.get("id") != 0
        or sync_local_mutation_concat != [{"let_local": 0}, {"string": "-"}, {"arg": "name"}]
        or sync_local_mutation_tail[1].get("let_local") != 0
    ):
        raise SystemExit(f"expected syncLocalMutation set_local source, got {sync_local_mutation}")

    async_local_mutation = patch_by_member.get("asyncLocalMutation", {}).get("bytecode_source", {})
    async_local_mutation_arg = async_local_mutation.get("body", {}).get("new_object", {}).get("args", [{}])[0]
    async_local_mutation_let = async_local_mutation_arg.get("let", {})
    async_local_mutation_locals = async_local_mutation_let.get("locals", [])
    async_local_mutation_tail = async_local_mutation_let.get("body", {}).get("seq", [])
    async_local_mutation_set = async_local_mutation_tail[0].get("set_local", {}) if async_local_mutation_tail else {}
    async_local_mutation_concat = async_local_mutation_set.get("value", {}).get("concat", [])
    if (
        async_local_mutation.get("async_future") is not True
        or async_local_mutation.get("body", {}).get("new_object", {}).get("type_args") != ["String"]
        or len(async_local_mutation_locals) != 1
        or async_local_mutation_locals[0].get("id") != 0
        or async_local_mutation_locals[0].get("name") != "out"
        or async_local_mutation_locals[0].get("value", {}).get("string") != "patched-async-local"
        or len(async_local_mutation_tail) != 2
        or async_local_mutation_set.get("id") != 0
        or async_local_mutation_concat != [{"let_local": 0}, {"string": "-"}, {"arg": "name"}]
        or async_local_mutation_tail[1].get("let_local") != 0
    ):
        raise SystemExit(f"expected asyncLocalMutation async set_local source, got {async_local_mutation}")

    async_await_local_mutation = patch_by_member.get("asyncAwaitThenLocalMutation", {}).get("bytecode_source", {})
    async_await_local_mutation_arg = async_await_local_mutation.get("body", {}).get("new_object", {}).get(
        "args", [{}]
    )[0]
    async_await_local_mutation_let = async_await_local_mutation_arg.get("let", {})
    async_await_local_mutation_locals = async_await_local_mutation_let.get("locals", [])
    async_await_local_mutation_tail = async_await_local_mutation_let.get("body", {}).get("seq", [])
    async_await_local_mutation_set = (
        async_await_local_mutation_tail[0].get("set_local", {})
        if async_await_local_mutation_tail
        else {}
    )
    async_await_local_mutation_concat = async_await_local_mutation_set.get("value", {}).get("concat", [])
    if (
        async_await_local_mutation.get("async_future") is not True
        or async_await_local_mutation.get("body", {}).get("new_object", {}).get("type_args") != ["String"]
        or len(async_await_local_mutation_locals) != 1
        or async_await_local_mutation_locals[0].get("id") != 0
        or async_await_local_mutation_locals[0].get("name") != "out"
        or async_await_local_mutation_locals[0].get("value", {}).get("await", {}).get("arg") != "ready"
        or len(async_await_local_mutation_tail) != 2
        or async_await_local_mutation_set.get("id") != 0
        or async_await_local_mutation_concat != [
            {"string": "patched-await-local:"},
            {"let_local": 0},
            {"string": "-"},
            {"arg": "name"},
        ]
        or async_await_local_mutation_tail[1].get("let_local") != 0
    ):
        raise SystemExit(
            "expected asyncAwaitThenLocalMutation await+set_local source, "
            f"got {async_await_local_mutation}"
        )
