def assert_inventory_async_await_sources(patch_by_member):
    async_label = patch_by_member.get("asyncLabel")
    if async_label is None:
        raise SystemExit("missing inventory entry for asyncLabel")
    async_source = async_label.get("bytecode_source")
    if not isinstance(async_source, dict):
        raise SystemExit(f"asyncLabel should now produce bytecode source: {async_label}")
    if async_label.get("unsupported_reasons") != []:
        raise SystemExit(f"asyncLabel should now be supported, got {async_label}")
    async_new_object = async_source.get("body", {}).get("new_object", {})
    if async_new_object.get("constructor") != "dart:async::class:_Future.value":
        raise SystemExit(f"expected asyncLabel _Future.value source, got {async_source}")
    if async_new_object.get("type_args") != ["String"]:
        raise SystemExit(f"expected asyncLabel Future<String> type arg, got {async_source}")

    async_int_input = patch_by_member.get("asyncIntInput")
    if async_int_input is None:
        raise SystemExit("missing inventory entry for asyncIntInput")
    async_int_input_source = async_int_input.get("bytecode_source")
    if not isinstance(async_int_input_source, dict):
        raise SystemExit(f"asyncIntInput should produce bytecode source: {async_int_input}")
    if async_int_input.get("unsupported_reasons") != []:
        raise SystemExit(f"asyncIntInput should now be supported, got {async_int_input}")
    async_int_input_object = async_int_input_source.get("body", {}).get("new_object", {})
    if (
        async_int_input_object.get("constructor") != "dart:async::class:_Future.value"
        or async_int_input_object.get("type_args") != ["int"]
        or async_int_input_object.get("args", [{}])[0].get("int") != 2
    ):
        raise SystemExit(f"expected asyncIntInput sync Future.value<int> source, got {async_int_input_source}")

    awaited_void = patch_by_member.get("awaitedVoid", {}).get("bytecode_source", {})
    awaited_void_new_object = awaited_void.get("body", {}).get("new_object", {})
    awaited_void_arg = awaited_void_new_object.get("args", [{}])[0]
    awaited_void_seq = awaited_void_arg.get("seq", [])
    awaited_void_let = awaited_void_seq[1].get("let", {}) if len(awaited_void_seq) > 1 else {}
    if (
        awaited_void_new_object.get("type_args") != ["void"]
        or len(awaited_void_seq) != 2
        or awaited_void_seq[0].get("await", {}).get("arg") != "ready"
        or awaited_void_let.get("locals", [{}])[0].get("name") != "marker"
        or awaited_void_let.get("body", {}).get("null") is not True
    ):
        raise SystemExit(f"expected awaitedVoid await statement + implicit null source, got {awaited_void}")

    awaited_return_void = patch_by_member.get("awaitedReturnVoid", {}).get("bytecode_source", {})
    awaited_return_void_arg = awaited_return_void.get("body", {}).get("new_object", {}).get("args", [{}])[0]
    awaited_return_void_seq = awaited_return_void_arg.get("seq", [])
    awaited_return_void_let = awaited_return_void_seq[1].get("let", {}) if len(awaited_return_void_seq) > 1 else {}
    if (
        len(awaited_return_void_seq) != 2
        or awaited_return_void_seq[0].get("await", {}).get("arg") != "ready"
        or awaited_return_void_let.get("locals", [{}])[0].get("name") != "marker"
        or awaited_return_void_let.get("body", {}).get("null") is not True
    ):
        raise SystemExit(f"expected awaitedReturnVoid await statement + explicit null return source, got {awaited_return_void}")

    awaited = patch_by_member.get("awaitedLabel", {}).get("bytecode_source", {})
    if awaited.get("body", {}).get("new_object", {}).get("constructor") != "dart:async::class:_Future.value":
        raise SystemExit(f"expected awaitedLabel _Future.value source, got {awaited}")

    awaited_local = patch_by_member.get("awaitedLocalLabel", {}).get("bytecode_source", {})
    awaited_local_outer_let = (
        awaited_local.get("body", {})
        .get("new_object", {})
        .get("args", [{}])[0]
        .get("try_catch", {})
        .get("body", {})
        .get("let", {})
    )
    awaited_local_inner_let = awaited_local_outer_let.get("body", {}).get("let", {})
    if (
        awaited_local_outer_let.get("locals", [{}])[0].get("name") != "base"
        or awaited_local_inner_let.get("locals", [{}])[0].get("name") != "prefix"
        or awaited_local_inner_let.get("body", {}).get("conditional") is None
    ):
        raise SystemExit(f"expected awaitedLocalLabel try/catch mixed-local if-return source, got {awaited_local}")

    awaited_future_param = patch_by_member.get("awaitedFutureParam", {}).get("bytecode_source", {})
    awaited_future_arg = awaited_future_param.get("body", {}).get("new_object", {}).get("args", [{}])[0]
    if awaited_future_arg.get("concat", [{}, {}])[1].get("await", {}).get("arg") != "value":
        raise SystemExit(f"expected awaitedFutureParam general await source, got {awaited_future_param}")

    awaited_statement = patch_by_member.get("awaitedStatement", {}).get("bytecode_source", {})
    awaited_statement_seq = awaited_statement.get("body", {}).get("new_object", {}).get("args", [{}])[0].get("seq", [])
    if (
        len(awaited_statement_seq) != 2
        or awaited_statement_seq[0].get("await", {}).get("arg") != "ready"
        or awaited_statement_seq[1].get("string") != "patched-after-await-statement"
    ):
        raise SystemExit(f"expected awaitedStatement await-expression statement seq source, got {awaited_statement}")

    awaited_statement_local = patch_by_member.get("awaitedStatementLocal", {}).get("bytecode_source", {})
    awaited_statement_local_seq = (
        awaited_statement_local.get("body", {}).get("new_object", {}).get("args", [{}])[0].get("seq", [])
    )
    awaited_statement_local_let = (
        awaited_statement_local_seq[1].get("let", {}) if len(awaited_statement_local_seq) > 1 else {}
    )
    if (
        len(awaited_statement_local_seq) != 2
        or awaited_statement_local_seq[0].get("await", {}).get("arg") != "ready"
        or awaited_statement_local_let.get("locals", [{}])[0].get("name") != "marker"
        or awaited_statement_local_let.get("body", {}).get("let_local") != 0
    ):
        raise SystemExit(f"expected awaitedStatementLocal await statement + local source, got {awaited_statement_local}")

    awaited_try_statement_local = patch_by_member.get("awaitedTryStatementLocal", {}).get("bytecode_source", {})
    awaited_try = (
        awaited_try_statement_local.get("body", {})
        .get("new_object", {})
        .get("args", [{}])[0]
        .get("try_catch", {})
    )
    awaited_try_seq = awaited_try.get("body", {}).get("seq", [])
    awaited_try_let = awaited_try_seq[1].get("let", {}) if len(awaited_try_seq) > 1 else {}
    if (
        len(awaited_try_seq) != 2
        or awaited_try_seq[0].get("await", {}).get("arg") != "ready"
        or awaited_try_let.get("locals", [{}])[0].get("name") != "marker"
        or awaited_try.get("catch", {}).get("concat") is None
    ):
        raise SystemExit(
            f"expected awaitedTryStatementLocal try/catch await statement + local source, got {awaited_try_statement_local}"
        )

    awaited_catch_local = patch_by_member.get("awaitedCatchLocal", {}).get("bytecode_source", {})
    awaited_catch = awaited_catch_local.get("body", {}).get("new_object", {}).get("args", [{}])[0].get("try_catch", {})
    awaited_catch_let = awaited_catch.get("catch", {}).get("let", {})
    if (
        awaited_catch.get("body", {}).get("seq", [])[0].get("await", {}).get("arg") != "ready"
        or awaited_catch_let.get("locals", [{}])[0].get("name") != "message"
        or awaited_catch_let.get("body", {}).get("let_local") != 1
    ):
        raise SystemExit(f"expected awaitedCatchLocal catch-local source, got {awaited_catch_local}")

    awaited_catch_await = patch_by_member.get("awaitedCatchAwait", {}).get("bytecode_source", {})
    awaited_catch_await_try = (
        awaited_catch_await.get("body", {}).get("new_object", {}).get("args", [{}])[0].get("try_catch", {})
    )
    if (
        awaited_catch_await_try.get("body", {}).get("seq", [])[0].get("await", {}).get("arg") != "ready"
        or awaited_catch_await_try.get("catch", {}).get("concat", [{}, {}])[1].get("let_local") != 0
    ):
        raise SystemExit(f"expected awaitedCatchAwait catch await source, got {awaited_catch_await}")

    awaited_catch_tail = patch_by_member.get("awaitedCatchTail", {}).get("bytecode_source", {})
    awaited_catch_tail_arg = (
        awaited_catch_tail.get("body", {}).get("new_object", {}).get("args", [{}])[0]
    )
    awaited_catch_tail_let = awaited_catch_tail_arg.get("let", {})
    awaited_catch_tail_seq = awaited_catch_tail_let.get("body", {}).get("seq", [])
    awaited_catch_tail_try = awaited_catch_tail_seq[0].get("try_catch", {}) if awaited_catch_tail_seq else {}
    awaited_catch_tail_try_body = awaited_catch_tail_try.get("body", {}).get("let", {})
    awaited_catch_tail_try_body_seq = awaited_catch_tail_try_body.get("body", {}).get("seq", [])
    awaited_catch_tail_catch = awaited_catch_tail_try.get("catch", {}).get("seq", [])
    if (
        awaited_catch_tail.get("async_future") is not True
        or awaited_catch_tail_let.get("locals", [{}])[0].get("name") != "out"
        or awaited_catch_tail_try.get("catch_local") != 1
        or awaited_catch_tail_try_body.get("locals", [{}])[0].get("name") != "value"
        or awaited_catch_tail_try_body.get("locals", [{}])[0].get("value", {}).get("await", {}).get("arg") != "ready"
        or awaited_catch_tail_try_body_seq[0].get("set_local", {}).get("id") != 0
        or awaited_catch_tail_catch[0].get("set_local", {}).get("id") != 0
        or awaited_catch_tail_catch[0].get("set_local", {}).get("value", {}).get("concat", [{}, {}, {}])[2].get("let_local") != 1
        or awaited_catch_tail_seq[1].get("let_local") != 0
    ):
        raise SystemExit(f"expected awaitedCatchTail try/catch statement + tail source, got {awaited_catch_tail}")

    awaited_catch_await_tail = patch_by_member.get("awaitedCatchAwaitTail", {}).get("bytecode_source", {})
    awaited_catch_await_tail_arg = (
        awaited_catch_await_tail.get("body", {}).get("new_object", {}).get("args", [{}])[0]
    )
    awaited_catch_await_tail_let = awaited_catch_await_tail_arg.get("let", {})
    awaited_catch_await_tail_seq = awaited_catch_await_tail_let.get("body", {}).get("seq", [])
    awaited_catch_await_tail_try = (
        awaited_catch_await_tail_seq[0].get("try_catch", {}) if awaited_catch_await_tail_seq else {}
    )
    awaited_catch_await_tail_body = awaited_catch_await_tail_try.get("body", {}).get("let", {})
    awaited_catch_await_tail_body_seq = awaited_catch_await_tail_body.get("body", {}).get("seq", [])
    awaited_catch_await_tail_catch = awaited_catch_await_tail_try.get("catch", {}).get("let", {})
    awaited_catch_await_tail_catch_seq = awaited_catch_await_tail_catch.get("body", {}).get("seq", [])
    if (
        awaited_catch_await_tail.get("async_future") is not True
        or awaited_catch_await_tail_let.get("locals", [{}])[0].get("name") != "out"
        or awaited_catch_await_tail_try.get("catch_local") != 1
        or awaited_catch_await_tail_body.get("locals", [{}])[0].get("name") != "value"
        or awaited_catch_await_tail_body.get("locals", [{}])[0].get("value", {}).get("await", {}).get("arg")
        != "ready"
        or awaited_catch_await_tail_body_seq[0].get("set_local", {}).get("id") != 0
        or awaited_catch_await_tail_catch.get("locals", [{}])[0].get("name") != "recovered"
        or awaited_catch_await_tail_catch.get("locals", [{}])[0].get("value", {}).get("await", {}).get("arg")
        != "recovery"
        or awaited_catch_await_tail_catch_seq[0].get("set_local", {}).get("id") != 0
        or awaited_catch_await_tail_catch_seq[0]
        .get("set_local", {})
        .get("value", {})
        .get("concat", [{}, {}, {}, {}])[2]
        .get("let_local")
        != 1
        or awaited_catch_await_tail_catch_seq[0]
        .get("set_local", {})
        .get("value", {})
        .get("concat", [{}, {}, {}, {}])[4]
        .get("let_local")
        != 2
        or awaited_catch_await_tail_seq[1].get("let_local") != 0
    ):
        raise SystemExit(
            f"expected awaitedCatchAwaitTail try/catch catch-await statement + tail source, got {awaited_catch_await_tail}"
        )

    awaited_finally_local = patch_by_member.get("awaitedFinallyLocal", {}).get("bytecode_source", {})
    awaited_finally = (
        awaited_finally_local.get("body", {}).get("new_object", {}).get("args", [{}])[0].get("try_finally", {})
    )
    awaited_finally_body = awaited_finally.get("body", {}).get("let", {})
    awaited_finally_finalizer = awaited_finally.get("finally", {}).get("let", {})
    if (
        awaited_finally.get("value") is not True
        or awaited_finally_body.get("locals", [{}])[0].get("name") != "value"
        or awaited_finally_body.get("locals", [{}])[0].get("value", {}).get("await", {}).get("arg") != "ready"
        or awaited_finally_body.get("body", {}).get("concat", [{}, {}])[1].get("let_local") != 0
        or awaited_finally_finalizer.get("locals", [{}])[0].get("name") != "cleanup"
        or awaited_finally_finalizer.get("body", {}).get("null") is not True
    ):
        raise SystemExit(f"expected awaitedFinallyLocal try/finally await source, got {awaited_finally_local}")

    awaited_finally_cleanup = patch_by_member.get("awaitedFinallyCleanup", {}).get("bytecode_source", {})
    awaited_cleanup_try = (
        awaited_finally_cleanup.get("body", {}).get("new_object", {}).get("args", [{}])[0].get("try_finally", {})
    )
    awaited_cleanup_body = awaited_cleanup_try.get("body", {}).get("let", {})
    awaited_cleanup_finally_seq = awaited_cleanup_try.get("finally", {}).get("seq", [])
    if (
        awaited_cleanup_try.get("value") is not True
        or awaited_cleanup_body.get("locals", [{}])[0].get("name") != "value"
        or awaited_cleanup_body.get("locals", [{}])[0].get("value", {}).get("await", {}).get("arg") != "ready"
        or awaited_cleanup_body.get("body", {}).get("concat", [{}, {}])[1].get("let_local") != 0
        or len(awaited_cleanup_finally_seq) != 2
        or awaited_cleanup_finally_seq[0].get("await", {}).get("arg") != "cleanup"
        or awaited_cleanup_finally_seq[1].get("null") is not True
    ):
        raise SystemExit(f"expected awaitedFinallyCleanup finalizer await source, got {awaited_finally_cleanup}")

    awaited_finally_statement_tail = patch_by_member.get("awaitedFinallyStatementTail", {}).get(
        "bytecode_source", {}
    )
    awaited_statement_tail_arg = (
        awaited_finally_statement_tail.get("body", {})
        .get("new_object", {})
        .get("args", [{}])[0]
    )
    awaited_statement_tail_let = awaited_statement_tail_arg.get("let", {})
    awaited_statement_tail_seq = awaited_statement_tail_let.get("body", {}).get("seq", [])
    awaited_statement_tail_try = (
        awaited_statement_tail_seq[0].get("try_finally", {}) if awaited_statement_tail_seq else {}
    )
    awaited_statement_tail_body = awaited_statement_tail_try.get("body", {}).get("let", {})
    awaited_statement_tail_body_seq = awaited_statement_tail_body.get("body", {}).get("seq", [])
    awaited_statement_tail_finalizer = awaited_statement_tail_try.get("finally", {}).get("let", {})
    awaited_statement_tail_finalizer_seq = awaited_statement_tail_finalizer.get("body", {}).get("seq", [])
    if (
        awaited_statement_tail_let.get("locals", [{}])[0].get("name") != "out"
        or awaited_statement_tail_body.get("locals", [{}])[0].get("name") != "value"
        or awaited_statement_tail_body.get("locals", [{}])[0].get("value", {}).get("await", {}).get("arg") != "ready"
        or awaited_statement_tail_body_seq[0].get("set_local", {}).get("id") != 0
        or awaited_statement_tail_finalizer.get("locals", [{}])[0].get("name") != "cleanup"
        or awaited_statement_tail_finalizer_seq[0].get("set_local", {}).get("id") != 0
        or awaited_statement_tail_seq[1].get("concat", [{}, {}])[0].get("let_local") != 0
    ):
        raise SystemExit(
            "expected awaitedFinallyStatementTail async try/finally statement local side-effect + tail source, "
            f"got {awaited_finally_statement_tail}"
        )

    awaited_finally_await_cleanup_tail = patch_by_member.get(
        "awaitedFinallyAwaitCleanupTail", {}
    ).get("bytecode_source", {})
    awaited_cleanup_tail_arg = (
        awaited_finally_await_cleanup_tail.get("body", {})
        .get("new_object", {})
        .get("args", [{}])[0]
    )
    awaited_cleanup_tail_let = awaited_cleanup_tail_arg.get("let", {})
    awaited_cleanup_tail_seq = awaited_cleanup_tail_let.get("body", {}).get("seq", [])
    awaited_cleanup_tail_try = (
        awaited_cleanup_tail_seq[0].get("try_finally", {}) if awaited_cleanup_tail_seq else {}
    )
    awaited_cleanup_tail_body = awaited_cleanup_tail_try.get("body", {}).get("let", {})
    awaited_cleanup_tail_body_seq = awaited_cleanup_tail_body.get("body", {}).get("seq", [])
    awaited_cleanup_tail_finalizer = awaited_cleanup_tail_try.get("finally", {}).get("let", {})
    awaited_cleanup_tail_finalizer_seq = awaited_cleanup_tail_finalizer.get("body", {}).get("seq", [])
    if (
        awaited_cleanup_tail_let.get("locals", [{}])[0].get("name") != "out"
        or awaited_cleanup_tail_body.get("locals", [{}])[0].get("name") != "value"
        or awaited_cleanup_tail_body.get("locals", [{}])[0].get("value", {}).get("await", {}).get("arg") != "ready"
        or awaited_cleanup_tail_body_seq[0].get("set_local", {}).get("id") != 0
        or awaited_cleanup_tail_finalizer.get("locals", [{}])[0].get("name") != "marker"
        or awaited_cleanup_tail_finalizer.get("locals", [{}])[0].get("value", {}).get("await", {}).get("arg")
        != "cleanup"
        or awaited_cleanup_tail_finalizer_seq[0].get("set_local", {}).get("id") != 0
        or awaited_cleanup_tail_seq[1].get("concat", [{}, {}])[0].get("let_local") != 0
    ):
        raise SystemExit(
            "expected awaitedFinallyAwaitCleanupTail async try/finally finalizer-await statement + tail source, "
            f"got {awaited_finally_await_cleanup_tail}"
        )

    awaited_catch_finally_cleanup = patch_by_member.get(
        "awaitedCatchFinallyCleanup",
        {},
    ).get("bytecode_source", {})
    awaited_catch_cleanup_try = (
        awaited_catch_finally_cleanup.get("body", {})
        .get("new_object", {})
        .get("args", [{}])[0]
        .get("try_finally", {})
    )
    awaited_catch_cleanup_body = awaited_catch_cleanup_try.get("body", {}).get("try_catch", {})
    awaited_catch_cleanup_try_body = awaited_catch_cleanup_body.get("body", {}).get("let", {})
    awaited_catch_cleanup_finally_seq = awaited_catch_cleanup_try.get("finally", {}).get("seq", [])
    if (
        awaited_catch_cleanup_try.get("value") is not True
        or awaited_catch_cleanup_body.get("catch_local") != 0
        or awaited_catch_cleanup_try_body.get("locals", [{}])[0].get("name") != "value"
        or awaited_catch_cleanup_try_body.get("locals", [{}])[0].get("value", {}).get("await", {}).get("arg") != "ready"
        or awaited_catch_cleanup_try_body.get("body", {}).get("concat", [{}, {}])[0].get("string")
        != "patched-catch-finally-ok-"
        or awaited_catch_cleanup_body.get("catch", {}).get("concat", [{}, {}])[1].get("let_local") != 0
        or len(awaited_catch_cleanup_finally_seq) != 2
        or awaited_catch_cleanup_finally_seq[0].get("await", {}).get("arg") != "cleanup"
        or awaited_catch_cleanup_finally_seq[1].get("null") is not True
    ):
        raise SystemExit(
            f"expected awaitedCatchFinallyCleanup nested try/catch/finally await source, got {awaited_catch_finally_cleanup}"
        )

    awaited_catch_finally_await_tail = patch_by_member.get(
        "awaitedCatchFinallyAwaitTail",
        {},
    ).get("bytecode_source", {})
    awaited_catch_finally_tail_arg = (
        awaited_catch_finally_await_tail.get("body", {})
        .get("new_object", {})
        .get("args", [{}])[0]
    )
    awaited_catch_finally_tail_let = awaited_catch_finally_tail_arg.get("let", {})
    awaited_catch_finally_tail_seq = awaited_catch_finally_tail_let.get("body", {}).get("seq", [])
    awaited_catch_finally_tail_try_finally = (
        awaited_catch_finally_tail_seq[0].get("try_finally", {}) if awaited_catch_finally_tail_seq else {}
    )
    awaited_catch_finally_tail_body_outer_seq = awaited_catch_finally_tail_try_finally.get("body", {}).get("seq", [])
    awaited_catch_finally_tail_try = (
        awaited_catch_finally_tail_body_outer_seq[0].get("try_catch", {})
        if awaited_catch_finally_tail_body_outer_seq
        else {}
    )
    awaited_catch_finally_tail_body = awaited_catch_finally_tail_try.get("body", {}).get("let", {})
    awaited_catch_finally_tail_body_seq = awaited_catch_finally_tail_body.get("body", {}).get("seq", [])
    awaited_catch_finally_tail_catch = awaited_catch_finally_tail_try.get("catch", {}).get("let", {})
    awaited_catch_finally_tail_catch_seq = awaited_catch_finally_tail_catch.get("body", {}).get("seq", [])
    awaited_catch_finally_tail_finalizer = awaited_catch_finally_tail_try_finally.get("finally", {}).get("let", {})
    awaited_catch_finally_tail_finalizer_seq = awaited_catch_finally_tail_finalizer.get("body", {}).get("seq", [])
    if (
        awaited_catch_finally_tail_let.get("locals", [{}])[0].get("name") != "out"
        or awaited_catch_finally_tail_try.get("catch_local") != 1
        or awaited_catch_finally_tail_body_outer_seq[1].get("null") is not True
        or awaited_catch_finally_tail_body.get("locals", [{}])[0].get("name") != "value"
        or awaited_catch_finally_tail_body.get("locals", [{}])[0].get("value", {}).get("await", {}).get("arg")
        != "ready"
        or awaited_catch_finally_tail_body_seq[0].get("set_local", {}).get("id") != 0
        or awaited_catch_finally_tail_catch.get("locals", [{}])[0].get("name") != "recovered"
        or awaited_catch_finally_tail_catch.get("locals", [{}])[0].get("value", {}).get("await", {}).get("arg")
        != "recovery"
        or awaited_catch_finally_tail_catch_seq[0].get("set_local", {}).get("id") != 0
        or awaited_catch_finally_tail_finalizer.get("locals", [{}])[0].get("name") != "marker"
        or awaited_catch_finally_tail_finalizer.get("locals", [{}])[0].get("value", {}).get("await", {}).get("arg")
        != "cleanup"
        or awaited_catch_finally_tail_finalizer_seq[0].get("set_local", {}).get("id") != 0
        or awaited_catch_finally_tail_seq[1].get("let_local") != 0
    ):
        raise SystemExit(
            "expected awaitedCatchFinallyAwaitTail nested try/catch/finally catch/finalizer-await tail source, "
            f"got {awaited_catch_finally_await_tail}"
        )
