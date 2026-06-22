import json

def assert_async_loop_sources(patch_by_member):
    def assert_try_loop_source(name, loop_kind, has_catch, condition_arg=None, update_arg=None):
        source = patch_by_member.get(name, {}).get("bytecode_source", {})
        arg = source.get("body", {}).get("new_object", {}).get("args", [{}])[0]
        outer_let = arg.get("let", {})
        outer_seq = outer_let.get("body", {}).get("seq", [])
        if loop_kind == "for":
            inner_let = outer_seq[0].get("let", {}) if outer_seq else {}
            loop = inner_let.get("body", {}).get("while_loop", {})
            body_seq = loop.get("body", {}).get("seq", [])
            loop_try = body_seq[0] if body_seq else {}
            update = body_seq[-1].get("set_local", {}) if body_seq else {}
        elif loop_kind == "while":
            loop = outer_seq[0].get("while_loop", {}) if outer_seq else {}
            body_seq = loop.get("body", {}).get("seq", [])
            loop_try = body_seq[0] if body_seq else {}
            update = body_seq[-1].get("seq", [{}])[0].get("set_local", {}) if body_seq else {}
        else:
            do_seq = outer_seq[0].get("seq", []) if outer_seq else []
            first_seq = do_seq[0].get("seq", []) if do_seq else []
            loop = do_seq[1].get("while_loop", {}) if len(do_seq) > 1 else {}
            body_seq = loop.get("body", {}).get("seq", [])
            loop_try = body_seq[0] if body_seq else {}
            update = body_seq[-1].get("seq", [{}])[0].get("set_local", {}) if body_seq else {}
            first_try = first_seq[0] if first_seq else {}
            if (first_try.get("try_catch") if has_catch else first_try.get("try_finally")) is None:
                raise SystemExit(f"expected {name} first do body try source, got {source}")
        try_expr = loop_try.get("try_catch") if has_catch else loop_try.get("try_finally")
        try_body = try_expr.get("body", {}).get("seq", []) if isinstance(try_expr, dict) else []
        guard = try_body[1].get("conditional", {}) if len(try_body) > 1 else {}
        if (
            source.get("async_future") is not True
            or (condition_arg is not None and loop.get("condition", {}).get("await", {}).get("arg") != condition_arg)
            or try_expr is None
            or guard.get("condition", {}).get("await", {}).get("arg") not in {"fail", "skip"}
            or (has_catch and try_expr.get("catch_local") is None)
            or (not has_catch and try_expr.get("finally") is None)
            or (update_arg is not None and update.get("value", {}).get("await", {}).get("arg") != update_arg)
            or outer_seq[-1].get("let_local") != (0 if loop_kind == "for" else 1)
        ):
            raise SystemExit(f"expected {name} {loop_kind} await condition/update + try source, got {source}")

    async_while_local = patch_by_member.get("asyncWhileLocal", {}).get("bytecode_source", {})
    async_while_arg = async_while_local.get("body", {}).get("new_object", {}).get("args", [{}])[0]
    async_while_outer_let = async_while_arg.get("let", {})
    async_while_locals = async_while_outer_let.get("locals", [])
    async_while_seq = async_while_outer_let.get("body", {}).get("seq", [])
    async_while_loop = async_while_seq[0].get("while_loop", {}) if async_while_seq else {}
    async_while_loop_body = async_while_loop.get("body", {}).get("seq", [])
    if (
        async_while_local.get("async_future") is not True
        or len(async_while_locals) != 2
        or async_while_locals[0].get("name") != "i"
        or async_while_locals[1].get("name") != "out"
        or async_while_loop.get("condition", {}).get("op") != ">"
        or len(async_while_loop_body) != 2
        or async_while_loop_body[0].get("set_local", {}).get("id") != 1
        or async_while_loop_body[1].get("seq", [{}])[0].get("set_local", {}).get("id") != 0
    ):
        raise SystemExit(f"expected asyncWhileLocal while_loop + set_local source, got {async_while_local}")
    async_while_break = patch_by_member.get("asyncWhileBreak", {}).get("bytecode_source", {})
    async_while_break_arg = async_while_break.get("body", {}).get("new_object", {}).get("args", [{}])[0]
    async_while_break_outer_let = async_while_break_arg.get("let", {})
    async_while_break_locals = async_while_break_outer_let.get("locals", [])
    async_while_break_seq = async_while_break_outer_let.get("body", {}).get("seq", [])
    async_while_break_loop = async_while_break_seq[0].get("while_loop", {}) if async_while_break_seq else {}
    async_while_break_body = async_while_break_loop.get("body", {}).get("seq", [])
    async_while_break_before = async_while_break_loop.get("before_break", {}).get("seq", [])
    if (
        async_while_break.get("async_future") is not True
        or len(async_while_break_locals) != 2
        or async_while_break_locals[0].get("name") != "i"
        or async_while_break_locals[1].get("name") != "out"
        or not async_while_break_before
        or async_while_break_before[0].get("set_local", {}).get("id") != 1
        or async_while_break_loop.get("break_condition", {}).get("op") != "=="
        or len(async_while_break_body) != 2
        or async_while_break_body[0].get("set_local", {}).get("id") != 0
    ):
        raise SystemExit(f"expected asyncWhileBreak before_break + break_condition source, got {async_while_break}")
    async_while_continue = patch_by_member.get("asyncWhileContinue", {}).get("bytecode_source", {})
    async_while_continue_arg = async_while_continue.get("body", {}).get("new_object", {}).get("args", [{}])[0]
    async_while_continue_outer_let = async_while_continue_arg.get("let", {})
    async_while_continue_locals = async_while_continue_outer_let.get("locals", [])
    async_while_continue_seq = async_while_continue_outer_let.get("body", {}).get("seq", [])
    async_while_continue_loop = async_while_continue_seq[0].get("while_loop", {}) if async_while_continue_seq else {}
    async_while_continue_body = async_while_continue_loop.get("body", {}).get("seq", [])
    async_while_continue_before = async_while_continue_loop.get("before_continue", {}).get("seq", [])
    async_while_continue_continue_body = async_while_continue_loop.get("continue_body", {}).get("seq", [])
    if (
        async_while_continue.get("async_future") is not True
        or len(async_while_continue_locals) != 2
        or async_while_continue_locals[0].get("name") != "i"
        or async_while_continue_locals[1].get("name") != "out"
        or not async_while_continue_before
        or async_while_continue_before[0].get("set_local", {}).get("id") != 1
        or async_while_continue_loop.get("continue_condition", {}).get("op") != "=="
        or not async_while_continue_continue_body
        or async_while_continue_continue_body[0].get("set_local", {}).get("id") != 0
        or len(async_while_continue_body) != 2
        or async_while_continue_body[0].get("set_local", {}).get("id") != 1
    ):
        raise SystemExit(f"expected asyncWhileContinue before_continue + continue_condition source, got {async_while_continue}")
    async_while_continue_break = patch_by_member.get("asyncWhileContinueBreak", {}).get("bytecode_source", {})
    async_while_continue_break_arg = async_while_continue_break.get("body", {}).get("new_object", {}).get("args", [{}])[0]
    async_while_continue_break_outer_let = async_while_continue_break_arg.get("let", {})
    async_while_continue_break_locals = async_while_continue_break_outer_let.get("locals", [])
    async_while_continue_break_seq = async_while_continue_break_outer_let.get("body", {}).get("seq", [])
    async_while_continue_break_loop = async_while_continue_break_seq[0].get("while_loop", {}) if async_while_continue_break_seq else {}
    async_while_continue_break_body = async_while_continue_break_loop.get("body", {}).get("seq", [])
    async_while_continue_break_before_continue = async_while_continue_break_loop.get("before_continue", {}).get("seq", [])
    async_while_continue_break_continue_body = async_while_continue_break_loop.get("continue_body", {}).get("seq", [])
    async_while_continue_break_before_break = async_while_continue_break_loop.get("before_break", {}).get("seq", [])
    if (
        async_while_continue_break.get("async_future") is not True
        or len(async_while_continue_break_locals) != 2
        or async_while_continue_break_locals[0].get("name") != "i"
        or async_while_continue_break_locals[1].get("name") != "out"
        or not async_while_continue_break_before_continue
        or async_while_continue_break_before_continue[0].get("set_local", {}).get("id") != 1
        or async_while_continue_break_loop.get("continue_condition", {}).get("op") != "=="
        or not async_while_continue_break_continue_body
        or async_while_continue_break_continue_body[0].get("set_local", {}).get("id") != 0
        or not async_while_continue_break_before_break
        or async_while_continue_break_before_break[0].get("set_local", {}).get("id") != 1
        or async_while_continue_break_loop.get("break_condition", {}).get("op") != "=="
        or len(async_while_continue_break_body) != 2
        or async_while_continue_break_body[0].get("set_local", {}).get("id") != 1
    ):
        raise SystemExit(f"expected asyncWhileContinueBreak continue+break source, got {async_while_continue_break}")
    async_while_await_continue_break = patch_by_member.get("asyncWhileAwaitContinueBreak", {}).get("bytecode_source", {})
    async_while_await_continue_break_arg = async_while_await_continue_break.get("body", {}).get("new_object", {}).get("args", [{}])[0]
    async_while_await_continue_break_outer_let = async_while_await_continue_break_arg.get("let", {})
    async_while_await_continue_break_locals = async_while_await_continue_break_outer_let.get("locals", [])
    async_while_await_continue_break_seq = async_while_await_continue_break_outer_let.get("body", {}).get("seq", [])
    async_while_await_continue_break_loop = async_while_await_continue_break_seq[0].get("while_loop", {}) if async_while_await_continue_break_seq else {}
    async_while_await_continue_break_before_continue = async_while_await_continue_break_loop.get("before_continue", {}).get("seq", [])
    async_while_await_continue_break_continue_body = async_while_await_continue_break_loop.get("continue_body", {}).get("seq", [])
    async_while_await_continue_break_before_break = async_while_await_continue_break_loop.get("before_break", {}).get("seq", [])
    async_while_await_continue_break_body = async_while_await_continue_break_loop.get("body", {}).get("seq", [])
    if (
        async_while_await_continue_break.get("async_future") is not True
        or len(async_while_await_continue_break_locals) != 2
        or async_while_await_continue_break_locals[0].get("name") != "i"
        or async_while_await_continue_break_locals[1].get("name") != "out"
        or async_while_await_continue_break_loop.get("continue_condition", {}).get("await", {}).get("arg") != "skip"
        or async_while_await_continue_break_loop.get("break_condition", {}).get("await", {}).get("arg") != "stop"
        or not async_while_await_continue_break_before_continue
        or async_while_await_continue_break_before_continue[0].get("set_local", {}).get("id") != 1
        or not async_while_await_continue_break_continue_body
        or async_while_await_continue_break_continue_body[0].get("set_local", {}).get("id") != 0
        or not async_while_await_continue_break_before_break
        or async_while_await_continue_break_before_break[0].get("set_local", {}).get("id") != 1
        or len(async_while_await_continue_break_body) != 2
        or async_while_await_continue_break_body[0].get("set_local", {}).get("id") != 1
    ):
        raise SystemExit(f"expected asyncWhileAwaitContinueBreak await guarded continue+break source, got {async_while_await_continue_break}")
    async_while_await_condition = patch_by_member.get("asyncWhileAwaitCondition", {}).get("bytecode_source", {})
    async_while_await_arg = async_while_await_condition.get("body", {}).get("new_object", {}).get("args", [{}])[0]
    async_while_await_let = async_while_await_arg.get("let", {})
    async_while_await_locals = async_while_await_let.get("locals", [])
    async_while_await_seq = async_while_await_let.get("body", {}).get("seq", [])
    async_while_await_loop = async_while_await_seq[0].get("while_loop", {}) if async_while_await_seq else {}
    async_while_await_before_break = async_while_await_loop.get("before_break", {}).get("seq", [])
    async_while_await_body = async_while_await_loop.get("body", {}).get("seq", [])
    if (
        async_while_await_condition.get("async_future") is not True
        or [item.get("name") for item in async_while_await_locals] != ["i", "out"]
        or async_while_await_loop.get("condition", {}).get("await", {}).get("arg") != "keepGoing"
        or not async_while_await_before_break
        or async_while_await_before_break[0].get("set_local", {}).get("id") != 1
        or async_while_await_loop.get("break_condition", {}).get("op") != "=="
        or len(async_while_await_body) != 2
        or async_while_await_body[0].get("set_local", {}).get("id") != 0
    ):
        raise SystemExit(f"expected asyncWhileAwaitCondition await condition + break source, got {async_while_await_condition}")
    async_while_await_condition_continue_break = patch_by_member.get("asyncWhileAwaitConditionContinueBreak", {}).get("bytecode_source", {})
    async_while_await_condition_continue_break_arg = async_while_await_condition_continue_break.get("body", {}).get("new_object", {}).get("args", [{}])[0]
    async_while_await_condition_continue_break_let = async_while_await_condition_continue_break_arg.get("let", {})
    async_while_await_condition_continue_break_locals = async_while_await_condition_continue_break_let.get("locals", [])
    async_while_await_condition_continue_break_seq = async_while_await_condition_continue_break_let.get("body", {}).get("seq", [])
    async_while_await_condition_continue_break_loop = async_while_await_condition_continue_break_seq[0].get("while_loop", {}) if async_while_await_condition_continue_break_seq else {}
    async_while_await_condition_continue_break_before_continue = async_while_await_condition_continue_break_loop.get("before_continue", {}).get("seq", [])
    async_while_await_condition_continue_break_continue_body = async_while_await_condition_continue_break_loop.get("continue_body", {}).get("seq", [])
    async_while_await_condition_continue_break_before_break = async_while_await_condition_continue_break_loop.get("before_break", {}).get("seq", [])
    async_while_await_condition_continue_break_body = async_while_await_condition_continue_break_loop.get("body", {}).get("seq", [])
    if (
        async_while_await_condition_continue_break.get("async_future") is not True
        or [item.get("name") for item in async_while_await_condition_continue_break_locals] != ["i", "out"]
        or async_while_await_condition_continue_break_loop.get("condition", {}).get("await", {}).get("arg") != "keepGoing"
        or async_while_await_condition_continue_break_loop.get("continue_condition", {}).get("await", {}).get("arg") != "skip"
        or async_while_await_condition_continue_break_loop.get("break_condition", {}).get("await", {}).get("arg") != "stop"
        or not async_while_await_condition_continue_break_before_continue
        or async_while_await_condition_continue_break_before_continue[0].get("set_local", {}).get("id") != 1
        or not async_while_await_condition_continue_break_continue_body
        or async_while_await_condition_continue_break_continue_body[0].get("set_local", {}).get("id") != 0
        or not async_while_await_condition_continue_break_before_break
        or async_while_await_condition_continue_break_before_break[0].get("set_local", {}).get("id") != 1
        or len(async_while_await_condition_continue_break_body) != 2
        or async_while_await_condition_continue_break_body[0].get("set_local", {}).get("id") != 1
    ):
        raise SystemExit(f"expected asyncWhileAwaitConditionContinueBreak await condition + await guarded continue/break source, got {async_while_await_condition_continue_break}")
    async_while_try_catch = patch_by_member.get("asyncWhileTryCatchAwaitGuard", {}).get("bytecode_source", {})
    async_while_try_catch_arg = async_while_try_catch.get("body", {}).get("new_object", {}).get("args", [{}])[0]
    async_while_try_catch_outer_let = async_while_try_catch_arg.get("let", {})
    async_while_try_catch_locals = async_while_try_catch_outer_let.get("locals", [])
    async_while_try_catch_seq = async_while_try_catch_outer_let.get("body", {}).get("seq", [])
    async_while_try_catch_loop = async_while_try_catch_seq[0].get("while_loop", {}) if async_while_try_catch_seq else {}
    async_while_try_catch_body = async_while_try_catch_loop.get("body", {}).get("seq", [])
    async_while_try_catch_try = async_while_try_catch_body[0].get("try_catch", {}) if async_while_try_catch_body else {}
    async_while_try_catch_try_body = async_while_try_catch_try.get("body", {}).get("seq", [])
    async_while_try_catch_guard = async_while_try_catch_try_body[1].get("conditional", {}) if len(async_while_try_catch_try_body) > 1 else {}
    async_while_try_catch_catch = async_while_try_catch_try.get("catch", {}).get("seq", [])
    async_while_try_catch_update = async_while_try_catch_body[1].get("seq", []) if len(async_while_try_catch_body) > 1 else []
    if (
        async_while_try_catch.get("async_future") is not True
        or [item.get("name") for item in async_while_try_catch_locals] != ["i", "out"]
        or async_while_try_catch_loop.get("condition", {}).get("op") != ">"
        or async_while_try_catch_try.get("catch_local") != 2
        or async_while_try_catch_try_body[0].get("set_local", {}).get("id") != 1
        or async_while_try_catch_guard.get("condition", {}).get("await", {}).get("arg") != "fail"
        or async_while_try_catch_guard.get("then", {}).get("seq", [{}])[0].get("throw") is None
        or async_while_try_catch_guard.get("else", {}).get("seq", [{}])[0].get("set_local", {}).get("id") != 1
        or async_while_try_catch_catch[0].get("set_local", {}).get("id") != 1
        or async_while_try_catch_catch[0].get("set_local", {}).get("value", {}).get("concat", [{}, {}, {}])[2].get("let_local") != 2
        or async_while_try_catch_update[0].get("set_local", {}).get("id") != 0
        or async_while_try_catch_update[1].get("null") is not True
        or async_while_try_catch_seq[1].get("let_local") != 1
    ):
        raise SystemExit(f"expected asyncWhileTryCatchAwaitGuard while + try/catch + await guard source, got {async_while_try_catch}")
    async_while_try_finally = patch_by_member.get("asyncWhileTryFinallyAwaitGuard", {}).get("bytecode_source", {})
    async_while_try_finally_arg = async_while_try_finally.get("body", {}).get("new_object", {}).get("args", [{}])[0]
    async_while_try_finally_outer_let = async_while_try_finally_arg.get("let", {})
    async_while_try_finally_locals = async_while_try_finally_outer_let.get("locals", [])
    async_while_try_finally_seq = async_while_try_finally_outer_let.get("body", {}).get("seq", [])
    async_while_try_finally_loop = async_while_try_finally_seq[0].get("while_loop", {}) if async_while_try_finally_seq else {}
    async_while_try_finally_body = async_while_try_finally_loop.get("body", {}).get("seq", [])
    async_while_try_finally_try = async_while_try_finally_body[0].get("try_finally", {}) if async_while_try_finally_body else {}
    async_while_try_finally_try_body = async_while_try_finally_try.get("body", {}).get("seq", [])
    async_while_try_finally_guard = (
        async_while_try_finally_try_body[1].get("conditional", {})
        if len(async_while_try_finally_try_body) > 1
        else {}
    )
    async_while_try_finally_finalizer = async_while_try_finally_try.get("finally", {}).get("let", {})
    async_while_try_finally_marker = async_while_try_finally_finalizer.get("locals", [{}])[0]
    async_while_try_finally_finalizer_seq = async_while_try_finally_finalizer.get("body", {}).get("seq", [])
    async_while_try_finally_finalizer_body = (
        async_while_try_finally_finalizer_seq[0] if async_while_try_finally_finalizer_seq else {}
    )
    async_while_try_finally_update = (
        async_while_try_finally_body[1].get("seq", []) if len(async_while_try_finally_body) > 1 else []
    )
    if (
        async_while_try_finally.get("async_future") is not True
        or [item.get("name") for item in async_while_try_finally_locals] != ["i", "out"]
        or async_while_try_finally_loop.get("condition", {}).get("op") != ">"
        or async_while_try_finally_try_body[0].get("set_local", {}).get("id") != 1
        or async_while_try_finally_guard.get("condition", {}).get("await", {}).get("arg") != "skip"
        or async_while_try_finally_guard.get("then", {}).get("seq", [{}])[0].get("set_local", {}).get("id") != 1
        or async_while_try_finally_guard.get("else", {}).get("seq", [{}])[0].get("set_local", {}).get("id") != 1
        or async_while_try_finally_marker.get("name") != "marker"
        or async_while_try_finally_marker.get("value", {}).get("await", {}).get("arg") != "cleanup"
        or async_while_try_finally_finalizer_body.get("set_local", {}).get("id") != 1
        or async_while_try_finally_finalizer_body.get("set_local", {}).get("value", {}).get("concat", [{}, {}, {}])[2].get("let_local") != 2
        or async_while_try_finally_finalizer_seq[1].get("null") is not True
        or async_while_try_finally_update[0].get("set_local", {}).get("id") != 0
        or async_while_try_finally_update[1].get("null") is not True
        or async_while_try_finally_seq[1].get("let_local") != 1
    ):
        raise SystemExit(
            "expected asyncWhileTryFinallyAwaitGuard while + try/finally + await guard/finalizer source, "
            f"got {async_while_try_finally}"
        )
    async_do_while_local = patch_by_member.get("asyncDoWhileLocal", {}).get("bytecode_source", {})
    async_do_while_arg = async_do_while_local.get("body", {}).get("new_object", {}).get("args", [{}])[0]
    async_do_while_let = async_do_while_arg.get("let", {})
    async_do_while_locals = async_do_while_let.get("locals", [])
    async_do_while_outer_seq = async_do_while_let.get("body", {}).get("seq", [])
    async_do_while_seq = async_do_while_outer_seq[0].get("seq", []) if async_do_while_outer_seq else []
    async_do_while_first = async_do_while_seq[0].get("seq", []) if async_do_while_seq else []
    async_do_while_loop = async_do_while_seq[1].get("while_loop", {}) if len(async_do_while_seq) > 1 else {}
    async_do_while_loop_body = async_do_while_loop.get("body", {}).get("seq", [])
    async_do_while_first_update = async_do_while_first[1].get("seq", []) if len(async_do_while_first) > 1 else []
    async_do_while_loop_update = async_do_while_loop_body[1].get("seq", []) if len(async_do_while_loop_body) > 1 else []
    if (
        async_do_while_local.get("async_future") is not True
        or [item.get("name") for item in async_do_while_locals] != ["i", "out"]
        or len(async_do_while_seq) != 2
        or len(async_do_while_first) != 2
        or async_do_while_first[0].get("set_local", {}).get("id") != 1
        or async_do_while_first_update[0].get("set_local", {}).get("id") != 0
        or async_do_while_loop.get("condition", {}).get("op") != ">"
        or len(async_do_while_loop_body) != 2
        or async_do_while_loop_body[0].get("set_local", {}).get("id") != 1
        or async_do_while_loop_update[0].get("set_local", {}).get("id") != 0
    ):
        raise SystemExit(f"expected asyncDoWhileLocal seq + while_loop source, got {async_do_while_local}")
    async_do_while_await = patch_by_member.get("asyncDoWhileAwaitCondition", {}).get("bytecode_source", {})
    async_do_while_await_arg = async_do_while_await.get("body", {}).get("new_object", {}).get("args", [{}])[0]
    async_do_while_await_let = async_do_while_await_arg.get("let", {})
    async_do_while_await_locals = async_do_while_await_let.get("locals", [])
    async_do_while_await_outer_seq = async_do_while_await_let.get("body", {}).get("seq", [])
    async_do_while_await_seq = async_do_while_await_outer_seq[0].get("seq", []) if async_do_while_await_outer_seq else []
    async_do_while_await_first = async_do_while_await_seq[0].get("seq", []) if async_do_while_await_seq else []
    async_do_while_await_loop = async_do_while_await_seq[1].get("while_loop", {}) if len(async_do_while_await_seq) > 1 else {}
    async_do_while_await_loop_body = async_do_while_await_loop.get("body", {}).get("seq", [])
    async_do_while_await_first_update = async_do_while_await_first[1].get("seq", []) if len(async_do_while_await_first) > 1 else []
    async_do_while_await_loop_update = async_do_while_await_loop_body[1].get("seq", []) if len(async_do_while_await_loop_body) > 1 else []
    if (
        async_do_while_await.get("async_future") is not True
        or [item.get("name") for item in async_do_while_await_locals] != ["i", "out"]
        or len(async_do_while_await_seq) != 2
        or async_do_while_await_loop.get("condition", {}).get("await", {}).get("arg") != "keepGoing"
        or async_do_while_await_first[0].get("set_local", {}).get("id") != 1
        or async_do_while_await_first_update[0].get("set_local", {}).get("id") != 0
        or async_do_while_await_loop_body[0].get("set_local", {}).get("id") != 1
        or async_do_while_await_loop_update[0].get("set_local", {}).get("id") != 0
    ):
        raise SystemExit(f"expected asyncDoWhileAwaitCondition await condition source, got {async_do_while_await}")
    async_do_while_branch = patch_by_member.get("asyncDoWhileBranchLocal", {}).get("bytecode_source", {})
    async_do_while_branch_arg = async_do_while_branch.get("body", {}).get("new_object", {}).get("args", [{}])[0]
    async_do_while_branch_let = async_do_while_branch_arg.get("let", {})
    async_do_while_branch_locals = async_do_while_branch_let.get("locals", [])
    async_do_while_branch_outer_seq = async_do_while_branch_let.get("body", {}).get("seq", [])
    async_do_while_branch_seq = async_do_while_branch_outer_seq[0].get("seq", []) if async_do_while_branch_outer_seq else []
    async_do_while_branch_first = async_do_while_branch_seq[0].get("let", {}) if async_do_while_branch_seq else {}
    async_do_while_branch_first_tail = async_do_while_branch_first.get("body", {}).get("seq", [])
    async_do_while_branch_loop = async_do_while_branch_seq[1].get("while_loop", {}) if len(async_do_while_branch_seq) > 1 else {}
    async_do_while_branch_loop_body = async_do_while_branch_loop.get("body", {}).get("let", {})
    async_do_while_branch_loop_tail = async_do_while_branch_loop_body.get("body", {}).get("seq", [])
    if (
        async_do_while_branch.get("async_future") is not True
        or [item.get("name") for item in async_do_while_branch_locals] != ["i", "out"]
        or len(async_do_while_branch_seq) != 2
        or async_do_while_branch_first.get("locals", [{}])[0].get("name") != "segment"
        or async_do_while_branch_first.get("locals", [{}])[0].get("value", {}).get("conditional", {}).get("condition", {}).get("op") != "=="
        or async_do_while_branch_first_tail[0].get("set_local", {}).get("id") != 1
        or async_do_while_branch_first_tail[0].get("set_local", {}).get("value", {}).get("concat", [{}, {}, {}, {}, {}])[2].get("let_local") != 2
        or async_do_while_branch_first_tail[1].get("seq", [])[0].get("set_local", {}).get("id") != 0
        or async_do_while_branch_loop.get("condition", {}).get("op") != ">"
        or async_do_while_branch_loop_body.get("locals", [{}])[0].get("name") != "segment"
        or async_do_while_branch_loop_tail[0].get("set_local", {}).get("id") != 1
        or async_do_while_branch_loop_tail[1].get("seq", [])[0].get("set_local", {}).get("id") != 0
    ):
        raise SystemExit(f"expected asyncDoWhileBranchLocal branch local source, got {async_do_while_branch}")
    async_do_while_await_branch = patch_by_member.get("asyncDoWhileAwaitConditionBranchLocal", {}).get("bytecode_source", {})
    async_do_while_await_branch_arg = async_do_while_await_branch.get("body", {}).get("new_object", {}).get("args", [{}])[0]
    async_do_while_await_branch_let = async_do_while_await_branch_arg.get("let", {})
    async_do_while_await_branch_locals = async_do_while_await_branch_let.get("locals", [])
    async_do_while_await_branch_outer_seq = async_do_while_await_branch_let.get("body", {}).get("seq", [])
    async_do_while_await_branch_seq = async_do_while_await_branch_outer_seq[0].get("seq", []) if async_do_while_await_branch_outer_seq else []
    async_do_while_await_branch_first = async_do_while_await_branch_seq[0].get("let", {}) if async_do_while_await_branch_seq else {}
    async_do_while_await_branch_first_tail = async_do_while_await_branch_first.get("body", {}).get("seq", [])
    async_do_while_await_branch_loop = async_do_while_await_branch_seq[1].get("while_loop", {}) if len(async_do_while_await_branch_seq) > 1 else {}
    async_do_while_await_branch_loop_body = async_do_while_await_branch_loop.get("body", {}).get("let", {})
    async_do_while_await_branch_loop_tail = async_do_while_await_branch_loop_body.get("body", {}).get("seq", [])
    if (
        async_do_while_await_branch.get("async_future") is not True
        or [item.get("name") for item in async_do_while_await_branch_locals] != ["i", "out"]
        or len(async_do_while_await_branch_seq) != 2
        or async_do_while_await_branch_first.get("locals", [{}])[0].get("name") != "segment"
        or async_do_while_await_branch_first.get("locals", [{}])[0].get("value", {}).get("conditional", {}).get("condition", {}).get("op") != "=="
        or async_do_while_await_branch_first_tail[0].get("set_local", {}).get("id") != 1
        or async_do_while_await_branch_first_tail[0].get("set_local", {}).get("value", {}).get("concat", [{}, {}, {}, {}, {}])[2].get("let_local") != 2
        or async_do_while_await_branch_first_tail[1].get("seq", [])[0].get("set_local", {}).get("id") != 0
        or async_do_while_await_branch_loop.get("condition", {}).get("await", {}).get("arg") != "keepGoing"
        or async_do_while_await_branch_loop_body.get("locals", [{}])[0].get("name") != "segment"
        or async_do_while_await_branch_loop_tail[0].get("set_local", {}).get("id") != 1
        or async_do_while_await_branch_loop_tail[1].get("seq", [])[0].get("set_local", {}).get("id") != 0
    ):
        raise SystemExit(f"expected asyncDoWhileAwaitConditionBranchLocal await condition + branch local source, got {async_do_while_await_branch}")
    async_do_while_await_local = patch_by_member.get("asyncDoWhileAwaitConditionAwaitLocal", {}).get("bytecode_source", {})
    async_do_while_await_local_arg = async_do_while_await_local.get("body", {}).get("new_object", {}).get("args", [{}])[0]
    async_do_while_await_local_let = async_do_while_await_local_arg.get("let", {})
    async_do_while_await_local_locals = async_do_while_await_local_let.get("locals", [])
    async_do_while_await_local_outer_seq = async_do_while_await_local_let.get("body", {}).get("seq", [])
    async_do_while_await_local_seq = async_do_while_await_local_outer_seq[0].get("seq", []) if async_do_while_await_local_outer_seq else []
    async_do_while_await_local_first = async_do_while_await_local_seq[0].get("let", {}) if async_do_while_await_local_seq else {}
    async_do_while_await_local_first_tail = async_do_while_await_local_first.get("body", {}).get("seq", [])
    async_do_while_await_local_loop = async_do_while_await_local_seq[1].get("while_loop", {}) if len(async_do_while_await_local_seq) > 1 else {}
    async_do_while_await_local_loop_body = async_do_while_await_local_loop.get("body", {}).get("let", {})
    async_do_while_await_local_loop_tail = async_do_while_await_local_loop_body.get("body", {}).get("seq", [])
    if (
        async_do_while_await_local.get("async_future") is not True
        or [item.get("name") for item in async_do_while_await_local_locals] != ["i", "out"]
        or len(async_do_while_await_local_seq) != 2
        or async_do_while_await_local_first.get("locals", [{}])[0].get("name") != "segment"
        or async_do_while_await_local_first.get("locals", [{}])[0].get("value", {}).get("await", {}).get("arg") != "ready"
        or async_do_while_await_local_first_tail[0].get("set_local", {}).get("id") != 1
        or async_do_while_await_local_first_tail[0].get("set_local", {}).get("value", {}).get("concat", [{}, {}, {}, {}, {}])[2].get("let_local") != 2
        or async_do_while_await_local_first_tail[1].get("seq", [])[0].get("set_local", {}).get("id") != 0
        or async_do_while_await_local_loop.get("condition", {}).get("await", {}).get("arg") != "keepGoing"
        or async_do_while_await_local_loop_body.get("locals", [{}])[0].get("name") != "segment"
        or async_do_while_await_local_loop_body.get("locals", [{}])[0].get("value", {}).get("await", {}).get("arg") != "ready"
        or async_do_while_await_local_loop_tail[0].get("set_local", {}).get("id") != 1
        or async_do_while_await_local_loop_tail[1].get("seq", [])[0].get("set_local", {}).get("id") != 0
    ):
        raise SystemExit(f"expected asyncDoWhileAwaitConditionAwaitLocal await condition + await local source, got {async_do_while_await_local}")
    async_do_while_break = patch_by_member.get("asyncDoWhileBreak", {}).get("bytecode_source", {})
    async_do_while_break_arg = async_do_while_break.get("body", {}).get("new_object", {}).get("args", [{}])[0]
    async_do_while_break_let = async_do_while_break_arg.get("let", {})
    async_do_while_break_locals = async_do_while_break_let.get("locals", [])
    async_do_while_break_outer_seq = async_do_while_break_let.get("body", {}).get("seq", [])
    async_do_while_break_seq = async_do_while_break_outer_seq[0].get("seq", []) if async_do_while_break_outer_seq else []
    async_do_while_break_before = async_do_while_break_seq[0].get("seq", []) if async_do_while_break_seq else []
    async_do_while_break_cond = async_do_while_break_seq[1].get("conditional", {}) if len(async_do_while_break_seq) > 1 else {}
    async_do_while_break_else = async_do_while_break_cond.get("else", {}).get("seq", [])
    async_do_while_break_loop = async_do_while_break_else[2].get("while_loop", {}) if len(async_do_while_break_else) > 2 else {}
    async_do_while_break_loop_body = async_do_while_break_loop.get("body", {}).get("seq", [])
    async_do_while_break_loop_before = async_do_while_break_loop.get("before_break", {}).get("seq", [])
    if (
        async_do_while_break.get("async_future") is not True
        or [item.get("name") for item in async_do_while_break_locals] != ["i", "out"]
        or len(async_do_while_break_seq) != 2
        or not async_do_while_break_before
        or async_do_while_break_before[0].get("set_local", {}).get("id") != 1
        or async_do_while_break_cond.get("condition", {}).get("op") != "=="
        or async_do_while_break_cond.get("then", {}).get("null") is not True
        or len(async_do_while_break_else) != 3
        or async_do_while_break_else[0].get("set_local", {}).get("id") != 1
        or async_do_while_break_else[1].get("seq", [])[0].get("set_local", {}).get("id") != 0
        or async_do_while_break_loop.get("condition", {}).get("op") != ">"
        or not async_do_while_break_loop_before
        or async_do_while_break_loop_before[0].get("set_local", {}).get("id") != 1
        or async_do_while_break_loop.get("break_condition", {}).get("op") != "=="
        or len(async_do_while_break_loop_body) != 2
    ):
        raise SystemExit(f"expected asyncDoWhileBreak guarded do-while source, got {async_do_while_break}")
    async_do_while_continue = patch_by_member.get("asyncDoWhileContinue", {}).get("bytecode_source", {})
    async_do_while_continue_arg = async_do_while_continue.get("body", {}).get("new_object", {}).get("args", [{}])[0]
    async_do_while_continue_let = async_do_while_continue_arg.get("let", {})
    async_do_while_continue_locals = async_do_while_continue_let.get("locals", [])
    async_do_while_continue_outer_seq = async_do_while_continue_let.get("body", {}).get("seq", [])
    async_do_while_continue_seq = async_do_while_continue_outer_seq[0].get("seq", []) if async_do_while_continue_outer_seq else []
    async_do_while_continue_before = async_do_while_continue_seq[0].get("seq", []) if async_do_while_continue_seq else []
    async_do_while_continue_cond = async_do_while_continue_seq[1].get("conditional", {}) if len(async_do_while_continue_seq) > 1 else {}
    async_do_while_continue_then = async_do_while_continue_cond.get("then", {}).get("seq", [])
    async_do_while_continue_else = async_do_while_continue_cond.get("else", {}).get("seq", [])
    async_do_while_continue_loop = async_do_while_continue_then[2].get("while_loop", {}) if len(async_do_while_continue_then) > 2 else {}
    async_do_while_continue_loop_before = async_do_while_continue_loop.get("before_continue", {}).get("seq", [])
    async_do_while_continue_loop_continue = async_do_while_continue_loop.get("continue_body", {}).get("seq", [])
    async_do_while_continue_loop_body = async_do_while_continue_loop.get("body", {}).get("seq", [])
    if (
        async_do_while_continue.get("async_future") is not True
        or [item.get("name") for item in async_do_while_continue_locals] != ["i", "out"]
        or len(async_do_while_continue_seq) != 2
        or not async_do_while_continue_before
        or async_do_while_continue_before[0].get("set_local", {}).get("id") != 1
        or async_do_while_continue_cond.get("condition", {}).get("op") != "=="
        or len(async_do_while_continue_then) != 3
        or async_do_while_continue_then[0].get("set_local", {}).get("id") != 0
        or async_do_while_continue_loop.get("condition", {}).get("op") != ">"
        or not async_do_while_continue_loop_before
        or async_do_while_continue_loop_before[0].get("set_local", {}).get("id") != 1
        or async_do_while_continue_loop.get("continue_condition", {}).get("op") != "=="
        or not async_do_while_continue_loop_continue
        or async_do_while_continue_loop_continue[0].get("set_local", {}).get("id") != 0
        or len(async_do_while_continue_loop_body) != 2
        or async_do_while_continue_loop_body[0].get("set_local", {}).get("id") != 1
        or len(async_do_while_continue_else) != 3
        or async_do_while_continue_else[0].get("set_local", {}).get("id") != 1
        or async_do_while_continue_else[1].get("seq", [])[0].get("set_local", {}).get("id") != 0
    ):
        raise SystemExit(f"expected asyncDoWhileContinue guarded do-while source, got {async_do_while_continue}")
    async_do_while_continue_break = patch_by_member.get("asyncDoWhileContinueBreak", {}).get("bytecode_source", {})
    async_do_while_continue_break_arg = async_do_while_continue_break.get("body", {}).get("new_object", {}).get("args", [{}])[0]
    async_do_while_continue_break_let = async_do_while_continue_break_arg.get("let", {})
    async_do_while_continue_break_locals = async_do_while_continue_break_let.get("locals", [])
    async_do_while_continue_break_outer_seq = async_do_while_continue_break_let.get("body", {}).get("seq", [])
    async_do_while_continue_break_seq = async_do_while_continue_break_outer_seq[0].get("seq", []) if async_do_while_continue_break_outer_seq else []
    async_do_while_continue_break_before = async_do_while_continue_break_seq[0].get("seq", []) if async_do_while_continue_break_seq else []
    async_do_while_continue_break_cond = async_do_while_continue_break_seq[1].get("conditional", {}) if len(async_do_while_continue_break_seq) > 1 else {}
    async_do_while_continue_break_then = async_do_while_continue_break_cond.get("then", {}).get("seq", [])
    async_do_while_continue_break_else = async_do_while_continue_break_cond.get("else", {}).get("seq", [])
    async_do_while_continue_break_else_cond = async_do_while_continue_break_else[1].get("conditional", {}) if len(async_do_while_continue_break_else) > 1 else {}
    async_do_while_continue_break_after_break = async_do_while_continue_break_else_cond.get("else", {}).get("seq", [])
    async_do_while_continue_break_loop = async_do_while_continue_break_after_break[2].get("while_loop", {}) if len(async_do_while_continue_break_after_break) > 2 else {}
    async_do_while_continue_break_loop_before_continue = async_do_while_continue_break_loop.get("before_continue", {}).get("seq", [])
    async_do_while_continue_break_loop_continue = async_do_while_continue_break_loop.get("continue_body", {}).get("seq", [])
    async_do_while_continue_break_loop_before_break = async_do_while_continue_break_loop.get("before_break", {}).get("seq", [])
    async_do_while_continue_break_loop_body = async_do_while_continue_break_loop.get("body", {}).get("seq", [])
    if (
        async_do_while_continue_break.get("async_future") is not True
        or [item.get("name") for item in async_do_while_continue_break_locals] != ["i", "out"]
        or len(async_do_while_continue_break_seq) != 2
        or not async_do_while_continue_break_before
        or async_do_while_continue_break_before[0].get("set_local", {}).get("id") != 1
        or async_do_while_continue_break_cond.get("condition", {}).get("op") != "=="
        or len(async_do_while_continue_break_then) != 3
        or async_do_while_continue_break_then[0].get("set_local", {}).get("id") != 0
        or len(async_do_while_continue_break_else) != 2
        or async_do_while_continue_break_else[0].get("seq", [])[0].get("set_local", {}).get("id") != 1
        or async_do_while_continue_break_else_cond.get("condition", {}).get("op") != "=="
        or async_do_while_continue_break_else_cond.get("then", {}).get("null") is not True
        or len(async_do_while_continue_break_after_break) != 3
        or async_do_while_continue_break_after_break[0].get("set_local", {}).get("id") != 1
        or async_do_while_continue_break_after_break[1].get("seq", [])[0].get("set_local", {}).get("id") != 0
        or async_do_while_continue_break_loop.get("condition", {}).get("op") != ">"
        or not async_do_while_continue_break_loop_before_continue
        or async_do_while_continue_break_loop_before_continue[0].get("set_local", {}).get("id") != 1
        or async_do_while_continue_break_loop.get("continue_condition", {}).get("op") != "=="
        or not async_do_while_continue_break_loop_continue
        or async_do_while_continue_break_loop_continue[0].get("set_local", {}).get("id") != 0
        or not async_do_while_continue_break_loop_before_break
        or async_do_while_continue_break_loop_before_break[0].get("set_local", {}).get("id") != 1
        or async_do_while_continue_break_loop.get("break_condition", {}).get("op") != "=="
        or len(async_do_while_continue_break_loop_body) != 2
        or async_do_while_continue_break_loop_body[0].get("set_local", {}).get("id") != 1
    ):
        raise SystemExit(f"expected asyncDoWhileContinueBreak guarded do-while source, got {async_do_while_continue_break}")
    async_do_while_await_guard_continue_break = patch_by_member.get("asyncDoWhileAwaitGuardContinueBreak", {}).get("bytecode_source", {})
    async_do_while_await_guard_continue_break_arg = async_do_while_await_guard_continue_break.get("body", {}).get("new_object", {}).get("args", [{}])[0]
    async_do_while_await_guard_continue_break_let = async_do_while_await_guard_continue_break_arg.get("let", {})
    async_do_while_await_guard_continue_break_locals = async_do_while_await_guard_continue_break_let.get("locals", [])
    async_do_while_await_guard_continue_break_outer_seq = async_do_while_await_guard_continue_break_let.get("body", {}).get("seq", [])
    async_do_while_await_guard_continue_break_seq = async_do_while_await_guard_continue_break_outer_seq[0].get("seq", []) if async_do_while_await_guard_continue_break_outer_seq else []
    async_do_while_await_guard_continue_break_cond = async_do_while_await_guard_continue_break_seq[1].get("conditional", {}) if len(async_do_while_await_guard_continue_break_seq) > 1 else {}
    async_do_while_await_guard_continue_break_then = async_do_while_await_guard_continue_break_cond.get("then", {}).get("seq", [])
    async_do_while_await_guard_continue_break_else = async_do_while_await_guard_continue_break_cond.get("else", {}).get("seq", [])
    async_do_while_await_guard_continue_break_else_cond = async_do_while_await_guard_continue_break_else[1].get("conditional", {}) if len(async_do_while_await_guard_continue_break_else) > 1 else {}
    async_do_while_await_guard_continue_break_after_break = async_do_while_await_guard_continue_break_else_cond.get("else", {}).get("seq", [])
    async_do_while_await_guard_continue_break_loop = async_do_while_await_guard_continue_break_after_break[2].get("while_loop", {}) if len(async_do_while_await_guard_continue_break_after_break) > 2 else {}
    if (
        async_do_while_await_guard_continue_break.get("async_future") is not True
        or [item.get("name") for item in async_do_while_await_guard_continue_break_locals] != ["i", "out"]
        or async_do_while_await_guard_continue_break_cond.get("condition", {}).get("await", {}).get("arg") != "skip"
        or async_do_while_await_guard_continue_break_then[0].get("set_local", {}).get("id") != 0
        or async_do_while_await_guard_continue_break_else_cond.get("condition", {}).get("await", {}).get("arg") != "stop"
        or async_do_while_await_guard_continue_break_else_cond.get("then", {}).get("null") is not True
        or async_do_while_await_guard_continue_break_loop.get("condition", {}).get("op") != ">"
        or async_do_while_await_guard_continue_break_loop.get("continue_condition", {}).get("await", {}).get("arg") != "skip"
        or async_do_while_await_guard_continue_break_loop.get("break_condition", {}).get("await", {}).get("arg") != "stop"
        or async_do_while_await_guard_continue_break_loop.get("continue_body", {}).get("seq", [{}])[0].get("set_local", {}).get("id") != 0
        or async_do_while_await_guard_continue_break_loop.get("before_break", {}).get("seq", [{}])[0].get("set_local", {}).get("id") != 1
        or async_do_while_await_guard_continue_break_loop.get("body", {}).get("seq", [{}])[0].get("set_local", {}).get("id") != 1
    ):
        raise SystemExit(f"expected asyncDoWhileAwaitGuardContinueBreak await guarded do-while source, got {async_do_while_await_guard_continue_break}")
    async_do_while_await_guard_continue_break_await_condition = patch_by_member.get("asyncDoWhileAwaitGuardContinueBreakAwaitCondition", {}).get("bytecode_source", {})
    async_do_while_await_guard_continue_break_await_condition_arg = async_do_while_await_guard_continue_break_await_condition.get("body", {}).get("new_object", {}).get("args", [{}])[0]
    async_do_while_await_guard_continue_break_await_condition_let = async_do_while_await_guard_continue_break_await_condition_arg.get("let", {})
    async_do_while_await_guard_continue_break_await_condition_locals = async_do_while_await_guard_continue_break_await_condition_let.get("locals", [])
    async_do_while_await_guard_continue_break_await_condition_outer_seq = async_do_while_await_guard_continue_break_await_condition_let.get("body", {}).get("seq", [])
    async_do_while_await_guard_continue_break_await_condition_seq = async_do_while_await_guard_continue_break_await_condition_outer_seq[0].get("seq", []) if async_do_while_await_guard_continue_break_await_condition_outer_seq else []
    async_do_while_await_guard_continue_break_await_condition_cond = async_do_while_await_guard_continue_break_await_condition_seq[1].get("conditional", {}) if len(async_do_while_await_guard_continue_break_await_condition_seq) > 1 else {}
    async_do_while_await_guard_continue_break_await_condition_then = async_do_while_await_guard_continue_break_await_condition_cond.get("then", {}).get("seq", [])
    async_do_while_await_guard_continue_break_await_condition_else = async_do_while_await_guard_continue_break_await_condition_cond.get("else", {}).get("seq", [])
    async_do_while_await_guard_continue_break_await_condition_else_cond = async_do_while_await_guard_continue_break_await_condition_else[1].get("conditional", {}) if len(async_do_while_await_guard_continue_break_await_condition_else) > 1 else {}
    async_do_while_await_guard_continue_break_await_condition_after_break = async_do_while_await_guard_continue_break_await_condition_else_cond.get("else", {}).get("seq", [])
    async_do_while_await_guard_continue_break_await_condition_loop = async_do_while_await_guard_continue_break_await_condition_after_break[2].get("while_loop", {}) if len(async_do_while_await_guard_continue_break_await_condition_after_break) > 2 else {}
    if (
        async_do_while_await_guard_continue_break_await_condition.get("async_future") is not True
        or [item.get("name") for item in async_do_while_await_guard_continue_break_await_condition_locals] != ["i", "out"]
        or async_do_while_await_guard_continue_break_await_condition_cond.get("condition", {}).get("await", {}).get("arg") != "skip"
        or async_do_while_await_guard_continue_break_await_condition_then[0].get("set_local", {}).get("id") != 0
        or async_do_while_await_guard_continue_break_await_condition_else_cond.get("condition", {}).get("await", {}).get("arg") != "stop"
        or async_do_while_await_guard_continue_break_await_condition_else_cond.get("then", {}).get("null") is not True
        or async_do_while_await_guard_continue_break_await_condition_loop.get("condition", {}).get("await", {}).get("arg") != "keepGoing"
        or async_do_while_await_guard_continue_break_await_condition_loop.get("continue_condition", {}).get("await", {}).get("arg") != "skip"
        or async_do_while_await_guard_continue_break_await_condition_loop.get("break_condition", {}).get("await", {}).get("arg") != "stop"
        or async_do_while_await_guard_continue_break_await_condition_loop.get("continue_body", {}).get("seq", [{}])[0].get("set_local", {}).get("id") != 0
        or async_do_while_await_guard_continue_break_await_condition_loop.get("before_break", {}).get("seq", [{}])[0].get("set_local", {}).get("id") != 1
        or async_do_while_await_guard_continue_break_await_condition_loop.get("body", {}).get("seq", [{}])[0].get("set_local", {}).get("id") != 1
    ):
        raise SystemExit(f"expected asyncDoWhileAwaitGuardContinueBreakAwaitCondition await guarded do-while source, got {async_do_while_await_guard_continue_break_await_condition}")
    async_do_while_try_catch = patch_by_member.get("asyncDoWhileTryCatchAwaitGuard", {}).get("bytecode_source", {})
    async_do_while_try_catch_arg = async_do_while_try_catch.get("body", {}).get("new_object", {}).get("args", [{}])[0]
    async_do_while_try_catch_let = async_do_while_try_catch_arg.get("let", {})
    async_do_while_try_catch_locals = async_do_while_try_catch_let.get("locals", [])
    async_do_while_try_catch_outer_seq = async_do_while_try_catch_let.get("body", {}).get("seq", [])
    async_do_while_try_catch_seq = async_do_while_try_catch_outer_seq[0].get("seq", []) if async_do_while_try_catch_outer_seq else []
    async_do_while_try_catch_first_seq = async_do_while_try_catch_seq[0].get("seq", []) if async_do_while_try_catch_seq else []
    async_do_while_try_catch_first_try = async_do_while_try_catch_first_seq[0].get("try_catch", {}) if async_do_while_try_catch_first_seq else {}
    async_do_while_try_catch_first_body = async_do_while_try_catch_first_try.get("body", {}).get("seq", [])
    async_do_while_try_catch_first_guard = async_do_while_try_catch_first_body[1].get("conditional", {}) if len(async_do_while_try_catch_first_body) > 1 else {}
    async_do_while_try_catch_first_catch = async_do_while_try_catch_first_try.get("catch", {}).get("seq", [])
    async_do_while_try_catch_first_update = async_do_while_try_catch_first_seq[1].get("seq", []) if len(async_do_while_try_catch_first_seq) > 1 else []
    async_do_while_try_catch_loop = async_do_while_try_catch_seq[1].get("while_loop", {}) if len(async_do_while_try_catch_seq) > 1 else {}
    async_do_while_try_catch_loop_body = async_do_while_try_catch_loop.get("body", {}).get("seq", [])
    async_do_while_try_catch_loop_try = async_do_while_try_catch_loop_body[0].get("try_catch", {}) if async_do_while_try_catch_loop_body else {}
    async_do_while_try_catch_loop_guard = async_do_while_try_catch_loop_try.get("body", {}).get("seq", [{}, {}])[1].get("conditional", {})
    async_do_while_try_catch_loop_catch = async_do_while_try_catch_loop_try.get("catch", {}).get("seq", [])
    async_do_while_try_catch_loop_update = async_do_while_try_catch_loop_body[1].get("seq", []) if len(async_do_while_try_catch_loop_body) > 1 else []
    if (
        async_do_while_try_catch.get("async_future") is not True
        or [item.get("name") for item in async_do_while_try_catch_locals] != ["i", "out"]
        or async_do_while_try_catch_first_try.get("catch_local") != 2
        or async_do_while_try_catch_first_body[0].get("set_local", {}).get("id") != 1
        or async_do_while_try_catch_first_guard.get("condition", {}).get("await", {}).get("arg") != "fail"
        or async_do_while_try_catch_first_guard.get("then", {}).get("seq", [{}])[0].get("throw") is None
        or async_do_while_try_catch_first_catch[0].get("set_local", {}).get("id") != 1
        or async_do_while_try_catch_first_catch[0].get("set_local", {}).get("value", {}).get("concat", [{}, {}, {}])[2].get("let_local") != 2
        or async_do_while_try_catch_first_update[0].get("set_local", {}).get("id") != 0
        or async_do_while_try_catch_loop.get("condition", {}).get("op") != ">"
        or async_do_while_try_catch_loop_try.get("catch_local") != 2
        or async_do_while_try_catch_loop_guard.get("condition", {}).get("await", {}).get("arg") != "fail"
        or async_do_while_try_catch_loop_catch[0].get("set_local", {}).get("id") != 1
        or async_do_while_try_catch_loop_update[0].get("set_local", {}).get("id") != 0
    ):
        raise SystemExit(f"expected asyncDoWhileTryCatchAwaitGuard do-while + try/catch + await guard source, got {async_do_while_try_catch}")
    async_do_while_try_finally = patch_by_member.get("asyncDoWhileTryFinallyAwaitGuard", {}).get("bytecode_source", {})
    async_do_while_try_finally_arg = async_do_while_try_finally.get("body", {}).get("new_object", {}).get("args", [{}])[0]
    async_do_while_try_finally_let = async_do_while_try_finally_arg.get("let", {})
    async_do_while_try_finally_locals = async_do_while_try_finally_let.get("locals", [])
    async_do_while_try_finally_outer_seq = async_do_while_try_finally_let.get("body", {}).get("seq", [])
    async_do_while_try_finally_seq = async_do_while_try_finally_outer_seq[0].get("seq", []) if async_do_while_try_finally_outer_seq else []
    async_do_while_try_finally_first_seq = async_do_while_try_finally_seq[0].get("seq", []) if async_do_while_try_finally_seq else []
    async_do_while_try_finally_first_try = (
        async_do_while_try_finally_first_seq[0].get("try_finally", {})
        if async_do_while_try_finally_first_seq
        else {}
    )
    async_do_while_try_finally_first_body = async_do_while_try_finally_first_try.get("body", {}).get("seq", [])
    async_do_while_try_finally_first_guard = (
        async_do_while_try_finally_first_body[1].get("conditional", {})
        if len(async_do_while_try_finally_first_body) > 1
        else {}
    )
    async_do_while_try_finally_first_finalizer = async_do_while_try_finally_first_try.get("finally", {}).get("let", {})
    async_do_while_try_finally_first_marker = async_do_while_try_finally_first_finalizer.get("locals", [{}])[0]
    async_do_while_try_finally_first_finalizer_seq = (
        async_do_while_try_finally_first_finalizer.get("body", {}).get("seq", [])
    )
    async_do_while_try_finally_first_update = (
        async_do_while_try_finally_first_seq[1].get("seq", [])
        if len(async_do_while_try_finally_first_seq) > 1
        else []
    )
    async_do_while_try_finally_loop = async_do_while_try_finally_seq[1].get("while_loop", {}) if len(async_do_while_try_finally_seq) > 1 else {}
    async_do_while_try_finally_loop_body = async_do_while_try_finally_loop.get("body", {}).get("seq", [])
    async_do_while_try_finally_loop_try = (
        async_do_while_try_finally_loop_body[0].get("try_finally", {})
        if async_do_while_try_finally_loop_body
        else {}
    )
    async_do_while_try_finally_loop_try_body = async_do_while_try_finally_loop_try.get("body", {}).get("seq", [])
    async_do_while_try_finally_loop_guard = (
        async_do_while_try_finally_loop_try_body[1].get("conditional", {})
        if len(async_do_while_try_finally_loop_try_body) > 1
        else {}
    )
    async_do_while_try_finally_loop_finalizer = async_do_while_try_finally_loop_try.get("finally", {}).get("let", {})
    async_do_while_try_finally_loop_marker = async_do_while_try_finally_loop_finalizer.get("locals", [{}])[0]
    async_do_while_try_finally_loop_finalizer_seq = (
        async_do_while_try_finally_loop_finalizer.get("body", {}).get("seq", [])
    )
    async_do_while_try_finally_loop_update = (
        async_do_while_try_finally_loop_body[1].get("seq", [])
        if len(async_do_while_try_finally_loop_body) > 1
        else []
    )
    if (
        async_do_while_try_finally.get("async_future") is not True
        or [item.get("name") for item in async_do_while_try_finally_locals] != ["i", "out"]
        or async_do_while_try_finally_first_body[0].get("set_local", {}).get("id") != 1
        or async_do_while_try_finally_first_guard.get("condition", {}).get("await", {}).get("arg") != "skip"
        or async_do_while_try_finally_first_guard.get("then", {}).get("seq", [{}])[0].get("set_local", {}).get("id") != 1
        or async_do_while_try_finally_first_guard.get("else", {}).get("seq", [{}])[0].get("set_local", {}).get("id") != 1
        or async_do_while_try_finally_first_marker.get("name") != "marker"
        or async_do_while_try_finally_first_marker.get("value", {}).get("await", {}).get("arg") != "cleanup"
        or async_do_while_try_finally_first_finalizer_seq[0].get("set_local", {}).get("id") != 1
        or async_do_while_try_finally_first_finalizer_seq[1].get("null") is not True
        or async_do_while_try_finally_first_update[0].get("set_local", {}).get("id") != 0
        or async_do_while_try_finally_loop.get("condition", {}).get("op") != ">"
        or async_do_while_try_finally_loop_try_body[0].get("set_local", {}).get("id") != 1
        or async_do_while_try_finally_loop_guard.get("condition", {}).get("await", {}).get("arg") != "skip"
        or async_do_while_try_finally_loop_marker.get("name") != "marker"
        or async_do_while_try_finally_loop_marker.get("value", {}).get("await", {}).get("arg") != "cleanup"
        or async_do_while_try_finally_loop_finalizer_seq[0].get("set_local", {}).get("id") != 1
        or async_do_while_try_finally_loop_finalizer_seq[1].get("null") is not True
        or async_do_while_try_finally_loop_update[0].get("set_local", {}).get("id") != 0
    ):
        raise SystemExit(
            "expected asyncDoWhileTryFinallyAwaitGuard do-while + try/finally + await guard/finalizer source, "
            f"got {async_do_while_try_finally}"
        )
    async_for_local = patch_by_member.get("asyncForLocal", {}).get("bytecode_source", {})
    async_for_arg = async_for_local.get("body", {}).get("new_object", {}).get("args", [{}])[0]
    async_for_outer_let = async_for_arg.get("let", {})
    async_for_outer_seq = async_for_outer_let.get("body", {}).get("seq", [])
    async_for_inner_let = async_for_outer_seq[0].get("let", {}) if async_for_outer_seq else {}
    async_for_loop = async_for_inner_let.get("body", {}).get("while_loop", {})
    async_for_loop_body = async_for_loop.get("body", {}).get("seq", [])
    if (
        async_for_local.get("async_future") is not True
        or async_for_outer_let.get("locals", [{}])[0].get("name") != "out"
        or async_for_inner_let.get("locals", [{}])[0].get("name") != "i"
        or async_for_loop.get("condition", {}).get("op") != ">"
        or len(async_for_loop_body) != 3
        or async_for_loop_body[0].get("set_local", {}).get("id") != 0
        or async_for_loop_body[2].get("set_local", {}).get("id") != 1
    ):
        raise SystemExit(f"expected asyncForLocal for->while_loop + update source, got {async_for_local}")
    async_for_continue = patch_by_member.get("asyncForContinue", {}).get("bytecode_source", {})
    async_for_continue_arg = async_for_continue.get("body", {}).get("new_object", {}).get("args", [{}])[0]
    async_for_continue_outer_let = async_for_continue_arg.get("let", {})
    async_for_continue_outer_seq = async_for_continue_outer_let.get("body", {}).get("seq", [])
    async_for_continue_inner_let = async_for_continue_outer_seq[0].get("let", {}) if async_for_continue_outer_seq else {}
    async_for_continue_loop = async_for_continue_inner_let.get("body", {}).get("while_loop", {})
    async_for_continue_body = async_for_continue_loop.get("body", {}).get("seq", [])
    async_for_continue_before = async_for_continue_loop.get("before_continue", {}).get("seq", [])
    async_for_continue_continue_body = async_for_continue_loop.get("continue_body", {}).get("seq", [])
    if (
        async_for_continue.get("async_future") is not True
        or async_for_continue_outer_let.get("locals", [{}])[0].get("name") != "out"
        or async_for_continue_inner_let.get("locals", [{}])[0].get("name") != "i"
        or async_for_continue_loop.get("condition", {}).get("op") != ">"
        or not async_for_continue_before
        or async_for_continue_before[0].get("set_local", {}).get("id") != 0
        or async_for_continue_loop.get("continue_condition", {}).get("op") != "=="
        or len(async_for_continue_continue_body) != 2
        or async_for_continue_continue_body[1].get("set_local", {}).get("id") != 1
        or len(async_for_continue_body) != 3
        or async_for_continue_body[0].get("set_local", {}).get("id") != 0
        or async_for_continue_body[2].get("set_local", {}).get("id") != 1
    ):
        raise SystemExit(f"expected asyncForContinue guarded continue + update source, got {async_for_continue}")
    async_for_break = patch_by_member.get("asyncForBreak", {}).get("bytecode_source", {})
    async_for_break_arg = async_for_break.get("body", {}).get("new_object", {}).get("args", [{}])[0]
    async_for_break_outer_let = async_for_break_arg.get("let", {})
    async_for_break_outer_seq = async_for_break_outer_let.get("body", {}).get("seq", [])
    async_for_break_inner_let = async_for_break_outer_seq[0].get("let", {}) if async_for_break_outer_seq else {}
    async_for_break_loop = async_for_break_inner_let.get("body", {}).get("while_loop", {})
    async_for_break_body = async_for_break_loop.get("body", {}).get("seq", [])
    async_for_break_before = async_for_break_loop.get("before_break", {}).get("seq", [])
    if (
        async_for_break.get("async_future") is not True
        or async_for_break_outer_let.get("locals", [{}])[0].get("name") != "out"
        or async_for_break_inner_let.get("locals", [{}])[0].get("name") != "i"
        or async_for_break_loop.get("condition", {}).get("op") != ">"
        or not async_for_break_before
        or async_for_break_before[0].get("set_local", {}).get("id") != 0
        or async_for_break_loop.get("break_condition", {}).get("op") != "=="
        or len(async_for_break_body) != 3
        or async_for_break_body[0].get("set_local", {}).get("id") != 0
        or async_for_break_body[2].get("set_local", {}).get("id") != 1
    ):
        raise SystemExit(f"expected asyncForBreak guarded break + update source, got {async_for_break}")
    async_for_continue_break = patch_by_member.get("asyncForContinueBreak", {}).get("bytecode_source", {})
    async_for_continue_break_arg = async_for_continue_break.get("body", {}).get("new_object", {}).get("args", [{}])[0]
    async_for_continue_break_outer_let = async_for_continue_break_arg.get("let", {})
    async_for_continue_break_outer_seq = async_for_continue_break_outer_let.get("body", {}).get("seq", [])
    async_for_continue_break_inner_let = async_for_continue_break_outer_seq[0].get("let", {}) if async_for_continue_break_outer_seq else {}
    async_for_continue_break_loop = async_for_continue_break_inner_let.get("body", {}).get("while_loop", {})
    async_for_continue_break_body = async_for_continue_break_loop.get("body", {}).get("seq", [])
    async_for_continue_break_before_continue = async_for_continue_break_loop.get("before_continue", {}).get("seq", [])
    async_for_continue_break_continue_body = async_for_continue_break_loop.get("continue_body", {}).get("seq", [])
    async_for_continue_break_before_break = async_for_continue_break_loop.get("before_break", {}).get("seq", [])
    if (
        async_for_continue_break.get("async_future") is not True
        or async_for_continue_break_outer_let.get("locals", [{}])[0].get("name") != "out"
        or async_for_continue_break_inner_let.get("locals", [{}])[0].get("name") != "i"
        or async_for_continue_break_loop.get("condition", {}).get("op") != ">"
        or not async_for_continue_break_before_continue
        or async_for_continue_break_before_continue[0].get("set_local", {}).get("id") != 0
        or async_for_continue_break_loop.get("continue_condition", {}).get("op") != "=="
        or len(async_for_continue_break_continue_body) != 2
        or async_for_continue_break_continue_body[1].get("set_local", {}).get("id") != 1
        or not async_for_continue_break_before_break
        or async_for_continue_break_before_break[0].get("set_local", {}).get("id") != 0
        or async_for_continue_break_loop.get("break_condition", {}).get("op") != "=="
        or len(async_for_continue_break_body) != 3
        or async_for_continue_break_body[0].get("set_local", {}).get("id") != 0
        or async_for_continue_break_body[2].get("set_local", {}).get("id") != 1
    ):
        raise SystemExit(f"expected asyncForContinueBreak guarded continue+break + update source, got {async_for_continue_break}")
    async_for_await_guard_continue_break = patch_by_member.get("asyncForAwaitGuardContinueBreak", {}).get("bytecode_source", {})
    async_for_await_guard_continue_break_arg = async_for_await_guard_continue_break.get("body", {}).get("new_object", {}).get("args", [{}])[0]
    async_for_await_guard_continue_break_outer_let = async_for_await_guard_continue_break_arg.get("let", {})
    async_for_await_guard_continue_break_outer_seq = async_for_await_guard_continue_break_outer_let.get("body", {}).get("seq", [])
    async_for_await_guard_continue_break_inner_let = async_for_await_guard_continue_break_outer_seq[0].get("let", {}) if async_for_await_guard_continue_break_outer_seq else {}
    async_for_await_guard_continue_break_loop = async_for_await_guard_continue_break_inner_let.get("body", {}).get("while_loop", {})
    async_for_await_guard_continue_break_before_continue = async_for_await_guard_continue_break_loop.get("before_continue", {}).get("seq", [])
    async_for_await_guard_continue_break_continue_body = async_for_await_guard_continue_break_loop.get("continue_body", {}).get("seq", [])
    async_for_await_guard_continue_break_before_break = async_for_await_guard_continue_break_loop.get("before_break", {}).get("seq", [])
    async_for_await_guard_continue_break_body = async_for_await_guard_continue_break_loop.get("body", {}).get("seq", [])
    if (
        async_for_await_guard_continue_break.get("async_future") is not True
        or async_for_await_guard_continue_break_outer_let.get("locals", [{}])[0].get("name") != "out"
        or async_for_await_guard_continue_break_inner_let.get("locals", [{}])[0].get("name") != "i"
        or async_for_await_guard_continue_break_loop.get("condition", {}).get("op") != ">"
        or async_for_await_guard_continue_break_loop.get("continue_condition", {}).get("await", {}).get("arg") != "skip"
        or async_for_await_guard_continue_break_loop.get("break_condition", {}).get("await", {}).get("arg") != "stop"
        or not async_for_await_guard_continue_break_before_continue
        or async_for_await_guard_continue_break_before_continue[0].get("set_local", {}).get("id") != 0
        or len(async_for_await_guard_continue_break_continue_body) != 2
        or async_for_await_guard_continue_break_continue_body[1].get("set_local", {}).get("id") != 1
        or not async_for_await_guard_continue_break_before_break
        or async_for_await_guard_continue_break_before_break[0].get("set_local", {}).get("id") != 0
        or len(async_for_await_guard_continue_break_body) != 3
        or async_for_await_guard_continue_break_body[0].get("set_local", {}).get("id") != 0
        or async_for_await_guard_continue_break_body[2].get("set_local", {}).get("id") != 1
    ):
        raise SystemExit(f"expected asyncForAwaitGuardContinueBreak await guarded continue+break + update source, got {async_for_await_guard_continue_break}")
    async_for_await_guard_continue_break_await_update = patch_by_member.get("asyncForAwaitGuardContinueBreakAwaitUpdate", {}).get("bytecode_source", {})
    async_for_await_guard_continue_break_await_update_arg = async_for_await_guard_continue_break_await_update.get("body", {}).get("new_object", {}).get("args", [{}])[0]
    async_for_await_guard_continue_break_await_update_outer_let = async_for_await_guard_continue_break_await_update_arg.get("let", {})
    async_for_await_guard_continue_break_await_update_outer_seq = async_for_await_guard_continue_break_await_update_outer_let.get("body", {}).get("seq", [])
    async_for_await_guard_continue_break_await_update_inner_let = async_for_await_guard_continue_break_await_update_outer_seq[0].get("let", {}) if async_for_await_guard_continue_break_await_update_outer_seq else {}
    async_for_await_guard_continue_break_await_update_loop = async_for_await_guard_continue_break_await_update_inner_let.get("body", {}).get("while_loop", {})
    async_for_await_guard_continue_break_await_update_continue_body = async_for_await_guard_continue_break_await_update_loop.get("continue_body", {}).get("seq", [])
    async_for_await_guard_continue_break_await_update_body = async_for_await_guard_continue_break_await_update_loop.get("body", {}).get("seq", [])
    if (
        async_for_await_guard_continue_break_await_update.get("async_future") is not True
        or async_for_await_guard_continue_break_await_update_outer_let.get("locals", [{}])[0].get("name") != "out"
        or async_for_await_guard_continue_break_await_update_inner_let.get("locals", [{}])[0].get("name") != "i"
        or async_for_await_guard_continue_break_await_update_loop.get("condition", {}).get("op") != ">"
        or async_for_await_guard_continue_break_await_update_loop.get("continue_condition", {}).get("await", {}).get("arg") != "skip"
        or async_for_await_guard_continue_break_await_update_loop.get("break_condition", {}).get("await", {}).get("arg") != "stop"
        or len(async_for_await_guard_continue_break_await_update_continue_body) != 2
        or async_for_await_guard_continue_break_await_update_continue_body[1].get("set_local", {}).get("value", {}).get("await", {}).get("arg") != "next"
        or len(async_for_await_guard_continue_break_await_update_body) != 3
        or async_for_await_guard_continue_break_await_update_body[2].get("set_local", {}).get("value", {}).get("await", {}).get("arg") != "next"
    ):
        raise SystemExit(f"expected asyncForAwaitGuardContinueBreakAwaitUpdate await guarded continue+break + await update source, got {async_for_await_guard_continue_break_await_update}")
    async_for_await_condition_guard_update = patch_by_member.get("asyncForAwaitConditionAwaitGuardContinueBreakAwaitUpdate", {}).get("bytecode_source", {})
    async_for_await_condition_guard_update_arg = async_for_await_condition_guard_update.get("body", {}).get("new_object", {}).get("args", [{}])[0]
    async_for_await_condition_guard_update_outer_let = async_for_await_condition_guard_update_arg.get("let", {})
    async_for_await_condition_guard_update_outer_seq = async_for_await_condition_guard_update_outer_let.get("body", {}).get("seq", [])
    async_for_await_condition_guard_update_inner_let = async_for_await_condition_guard_update_outer_seq[0].get("let", {}) if async_for_await_condition_guard_update_outer_seq else {}
    async_for_await_condition_guard_update_loop = async_for_await_condition_guard_update_inner_let.get("body", {}).get("while_loop", {})
    async_for_await_condition_guard_update_before_continue = async_for_await_condition_guard_update_loop.get("before_continue", {}).get("seq", [])
    async_for_await_condition_guard_update_continue_body = async_for_await_condition_guard_update_loop.get("continue_body", {}).get("seq", [])
    async_for_await_condition_guard_update_before_break = async_for_await_condition_guard_update_loop.get("before_break", {}).get("seq", [])
    async_for_await_condition_guard_update_body = async_for_await_condition_guard_update_loop.get("body", {}).get("seq", [])
    if (
        async_for_await_condition_guard_update.get("async_future") is not True
        or async_for_await_condition_guard_update_outer_let.get("locals", [{}])[0].get("name") != "out"
        or async_for_await_condition_guard_update_inner_let.get("locals", [{}])[0].get("name") != "i"
        or async_for_await_condition_guard_update_loop.get("condition", {}).get("await", {}).get("arg") != "keepGoing"
        or async_for_await_condition_guard_update_loop.get("continue_condition", {}).get("await", {}).get("arg") != "skip"
        or async_for_await_condition_guard_update_loop.get("break_condition", {}).get("await", {}).get("arg") != "stop"
        or not async_for_await_condition_guard_update_before_continue
        or async_for_await_condition_guard_update_before_continue[0].get("set_local", {}).get("id") != 0
        or len(async_for_await_condition_guard_update_continue_body) != 2
        or async_for_await_condition_guard_update_continue_body[1].get("set_local", {}).get("value", {}).get("await", {}).get("arg") != "next"
        or not async_for_await_condition_guard_update_before_break
        or async_for_await_condition_guard_update_before_break[0].get("set_local", {}).get("id") != 0
        or len(async_for_await_condition_guard_update_body) != 3
        or async_for_await_condition_guard_update_body[2].get("set_local", {}).get("value", {}).get("await", {}).get("arg") != "next"
    ):
        raise SystemExit(f"expected asyncForAwaitConditionAwaitGuardContinueBreakAwaitUpdate await condition/guards/update source, got {async_for_await_condition_guard_update}")
    async_for_await_update = patch_by_member.get("asyncForAwaitUpdate", {}).get("bytecode_source", {})
    async_for_await_update_arg = async_for_await_update.get("body", {}).get("new_object", {}).get("args", [{}])[0]
    async_for_await_update_outer_let = async_for_await_update_arg.get("let", {})
    async_for_await_update_outer_seq = async_for_await_update_outer_let.get("body", {}).get("seq", [])
    async_for_await_update_inner_let = async_for_await_update_outer_seq[0].get("let", {}) if async_for_await_update_outer_seq else {}
    async_for_await_update_loop = async_for_await_update_inner_let.get("body", {}).get("while_loop", {})
    async_for_await_update_body = async_for_await_update_loop.get("body", {}).get("seq", [])
    if (
        async_for_await_update.get("async_future") is not True
        or async_for_await_update_outer_let.get("locals", [{}])[0].get("name") != "out"
        or async_for_await_update_inner_let.get("locals", [{}])[0].get("name") != "i"
        or async_for_await_update_loop.get("condition", {}).get("op") != ">"
        or len(async_for_await_update_body) != 3
        or async_for_await_update_body[0].get("set_local", {}).get("id") != 0
        or async_for_await_update_body[2].get("set_local", {}).get("id") != 1
        or async_for_await_update_body[2].get("set_local", {}).get("value", {}).get("await", {}).get("arg") != "next"
    ):
        raise SystemExit(f"expected asyncForAwaitUpdate for update await source, got {async_for_await_update}")
    async_for_await_update_branch = patch_by_member.get("asyncForAwaitUpdateBranchLocal", {}).get("bytecode_source", {})
    async_for_await_update_branch_arg = async_for_await_update_branch.get("body", {}).get("new_object", {}).get("args", [{}])[0]
    async_for_await_update_branch_outer_let = async_for_await_update_branch_arg.get("let", {})
    async_for_await_update_branch_outer_seq = async_for_await_update_branch_outer_let.get("body", {}).get("seq", [])
    async_for_await_update_branch_inner_let = async_for_await_update_branch_outer_seq[0].get("let", {}) if async_for_await_update_branch_outer_seq else {}
    async_for_await_update_branch_loop = async_for_await_update_branch_inner_let.get("body", {}).get("while_loop", {})
    async_for_await_update_branch_body = async_for_await_update_branch_loop.get("body", {}).get("seq", [])
    async_for_await_update_branch_segment = async_for_await_update_branch_body[0].get("let", {}) if async_for_await_update_branch_body else {}
    async_for_await_update_branch_segment_tail = async_for_await_update_branch_segment.get("body", {}).get("seq", [])
    async_for_await_update_branch_update = async_for_await_update_branch_body[1].get("set_local", {}) if len(async_for_await_update_branch_body) > 1 else {}
    if (
        async_for_await_update_branch.get("async_future") is not True
        or async_for_await_update_branch_outer_let.get("locals", [{}])[0].get("name") != "out"
        or async_for_await_update_branch_inner_let.get("locals", [{}])[0].get("name") != "i"
        or async_for_await_update_branch_loop.get("condition", {}).get("op") != ">"
        or len(async_for_await_update_branch_body) != 2
        or async_for_await_update_branch_segment.get("locals", [{}])[0].get("name") != "segment"
        or async_for_await_update_branch_segment.get("locals", [{}])[0].get("value", {}).get("conditional", {}).get("condition", {}).get("op") != "=="
        or async_for_await_update_branch_segment_tail[0].get("set_local", {}).get("id") != 0
        or async_for_await_update_branch_segment_tail[0].get("set_local", {}).get("value", {}).get("concat", [{}, {}, {}, {}, {}])[2].get("let_local") != 2
        or async_for_await_update_branch_update.get("id") != 1
        or async_for_await_update_branch_update.get("value", {}).get("await", {}).get("arg") != "next"
    ):
        raise SystemExit(f"expected asyncForAwaitUpdateBranchLocal branch local + await update source, got {async_for_await_update_branch}")

    async_while_nested_branch = patch_by_member.get("asyncWhileNestedAwaitBranchLocal", {}).get("bytecode_source", {})
    async_while_nested_branch_arg = async_while_nested_branch.get("body", {}).get("new_object", {}).get("args", [{}])[0]
    async_while_nested_branch_let = async_while_nested_branch_arg.get("let", {})
    async_while_nested_branch_seq = async_while_nested_branch_let.get("body", {}).get("seq", [])
    async_while_nested_branch_loop = async_while_nested_branch_seq[0].get("while_loop", {}) if async_while_nested_branch_seq else {}
    async_while_nested_branch_body = async_while_nested_branch_loop.get("body", {}).get("conditional", {})
    async_while_nested_branch_then = async_while_nested_branch_body.get("then", {}).get("let", {})
    async_while_nested_branch_nested = async_while_nested_branch_then.get("body", {}).get("conditional", {})
    async_while_nested_branch_nested_then = async_while_nested_branch_nested.get("then", {}).get("let", {})
    async_while_nested_branch_else = async_while_nested_branch_body.get("else", {}).get("let", {})
    if (
        async_while_nested_branch.get("async_future") is not True
        or async_while_nested_branch.get("body", {}).get("new_object", {}).get("type_args") != ["String"]
        or [item.get("name") for item in async_while_nested_branch_let.get("locals", [])] != ["i", "out"]
        or async_while_nested_branch_loop.get("condition", {}).get("op") != ">"
        or async_while_nested_branch_body.get("condition", {}).get("op") != "=="
        or async_while_nested_branch_then.get("locals", [{}])[0].get("name") != "state"
        or async_while_nested_branch_then.get("locals", [{}])[0].get("value", {}).get("await", {}).get("arg") != "ready"
        or async_while_nested_branch_nested.get("condition", {}).get("arg") != "premium"
        or async_while_nested_branch_nested_then.get("locals", [{}])[0].get("name") != "tier"
        or async_while_nested_branch_nested_then.get("locals", [{}])[0].get("value", {}).get("string") != "patched-while-nested-pro"
        or async_while_nested_branch_else.get("locals", [{}])[0].get("name") != "state"
        or async_while_nested_branch_else.get("locals", [{}])[0].get("value", {}).get("string") != "patched-while-nested-tail"
        or async_while_nested_branch_seq[1].get("let_local") != 1
    ):
        raise SystemExit(f"expected asyncWhileNestedAwaitBranchLocal nested branch local while source, got {async_while_nested_branch}")
    async_while_await_condition_nested_branch = patch_by_member.get("asyncWhileAwaitConditionNestedAwaitBranchLocal", {}).get("bytecode_source", {})
    async_while_await_condition_nested_branch_arg = async_while_await_condition_nested_branch.get("body", {}).get("new_object", {}).get("args", [{}])[0]
    async_while_await_condition_nested_branch_let = async_while_await_condition_nested_branch_arg.get("let", {})
    async_while_await_condition_nested_branch_seq = async_while_await_condition_nested_branch_let.get("body", {}).get("seq", [])
    async_while_await_condition_nested_branch_loop = async_while_await_condition_nested_branch_seq[0].get("while_loop", {}) if async_while_await_condition_nested_branch_seq else {}
    async_while_await_condition_nested_branch_body = async_while_await_condition_nested_branch_loop.get("body", {}).get("conditional", {})
    async_while_await_condition_nested_branch_then = async_while_await_condition_nested_branch_body.get("then", {}).get("let", {})
    async_while_await_condition_nested_branch_nested = async_while_await_condition_nested_branch_then.get("body", {}).get("conditional", {})
    async_while_await_condition_nested_branch_nested_then = async_while_await_condition_nested_branch_nested.get("then", {}).get("let", {})
    async_while_await_condition_nested_branch_else = async_while_await_condition_nested_branch_body.get("else", {}).get("let", {})
    if (
        async_while_await_condition_nested_branch.get("async_future") is not True
        or async_while_await_condition_nested_branch.get("body", {}).get("new_object", {}).get("type_args") != ["String"]
        or [item.get("name") for item in async_while_await_condition_nested_branch_let.get("locals", [])] != ["i", "out"]
        or async_while_await_condition_nested_branch_loop.get("condition", {}).get("await", {}).get("arg") != "keepGoing"
        or async_while_await_condition_nested_branch_body.get("condition", {}).get("op") != "=="
        or async_while_await_condition_nested_branch_then.get("locals", [{}])[0].get("name") != "state"
        or async_while_await_condition_nested_branch_then.get("locals", [{}])[0].get("value", {}).get("await", {}).get("arg") != "ready"
        or async_while_await_condition_nested_branch_nested.get("condition", {}).get("arg") != "premium"
        or async_while_await_condition_nested_branch_nested_then.get("locals", [{}])[0].get("name") != "tier"
        or async_while_await_condition_nested_branch_nested_then.get("locals", [{}])[0].get("value", {}).get("string") != "patched-while-await-condition-nested-pro"
        or async_while_await_condition_nested_branch_else.get("locals", [{}])[0].get("name") != "state"
        or async_while_await_condition_nested_branch_else.get("locals", [{}])[0].get("value", {}).get("string") != "patched-while-await-condition-nested-tail"
        or async_while_await_condition_nested_branch_seq[1].get("let_local") != 1
    ):
        raise SystemExit(f"expected asyncWhileAwaitConditionNestedAwaitBranchLocal await condition + nested branch local while source, got {async_while_await_condition_nested_branch}")
    async_for_nested_branch = patch_by_member.get("asyncForNestedAwaitBranchLocal", {}).get("bytecode_source", {})
    async_for_nested_branch_arg = async_for_nested_branch.get("body", {}).get("new_object", {}).get("args", [{}])[0]
    async_for_nested_branch_outer_let = async_for_nested_branch_arg.get("let", {})
    async_for_nested_branch_outer_seq = async_for_nested_branch_outer_let.get("body", {}).get("seq", [])
    async_for_nested_branch_inner_let = async_for_nested_branch_outer_seq[0].get("let", {}) if async_for_nested_branch_outer_seq else {}
    async_for_nested_branch_loop = async_for_nested_branch_inner_let.get("body", {}).get("while_loop", {})
    async_for_nested_branch_body_seq = async_for_nested_branch_loop.get("body", {}).get("seq", [])
    async_for_nested_branch_body = async_for_nested_branch_body_seq[0].get("conditional", {}) if async_for_nested_branch_body_seq else {}
    async_for_nested_branch_update = async_for_nested_branch_body_seq[1].get("set_local", {}) if len(async_for_nested_branch_body_seq) > 1 else {}
    async_for_nested_branch_then = async_for_nested_branch_body.get("then", {}).get("let", {})
    async_for_nested_branch_nested = async_for_nested_branch_then.get("body", {}).get("conditional", {})
    async_for_nested_branch_nested_then = async_for_nested_branch_nested.get("then", {}).get("let", {})
    async_for_nested_branch_else = async_for_nested_branch_body.get("else", {}).get("let", {})
    if (
        async_for_nested_branch.get("async_future") is not True
        or async_for_nested_branch.get("body", {}).get("new_object", {}).get("type_args") != ["String"]
        or async_for_nested_branch_outer_let.get("locals", [{}])[0].get("name") != "out"
        or async_for_nested_branch_inner_let.get("locals", [{}])[0].get("name") != "i"
        or async_for_nested_branch_loop.get("condition", {}).get("op") != ">"
        or async_for_nested_branch_body.get("condition", {}).get("op") != "=="
        or async_for_nested_branch_then.get("locals", [{}])[0].get("name") != "state"
        or async_for_nested_branch_then.get("locals", [{}])[0].get("value", {}).get("await", {}).get("arg") != "ready"
        or async_for_nested_branch_nested.get("condition", {}).get("arg") != "premium"
        or async_for_nested_branch_nested_then.get("locals", [{}])[0].get("name") != "tier"
        or async_for_nested_branch_nested_then.get("locals", [{}])[0].get("value", {}).get("string") != "patched-for-nested-pro"
        or async_for_nested_branch_else.get("locals", [{}])[0].get("name") != "state"
        or async_for_nested_branch_else.get("locals", [{}])[0].get("value", {}).get("string") != "patched-for-nested-tail"
        or async_for_nested_branch_update.get("id") != 1
        or async_for_nested_branch_outer_seq[1].get("let_local") != 0
    ):
        raise SystemExit(f"expected asyncForNestedAwaitBranchLocal nested branch local for source, got {async_for_nested_branch}")
    async_for_await_update_nested_branch = patch_by_member.get("asyncForAwaitUpdateNestedBranchLocal", {}).get("bytecode_source", {})
    async_for_await_update_nested_branch_arg = async_for_await_update_nested_branch.get("body", {}).get("new_object", {}).get("args", [{}])[0]
    async_for_await_update_nested_branch_outer_let = async_for_await_update_nested_branch_arg.get("let", {})
    async_for_await_update_nested_branch_outer_seq = async_for_await_update_nested_branch_outer_let.get("body", {}).get("seq", [])
    async_for_await_update_nested_branch_inner_let = async_for_await_update_nested_branch_outer_seq[0].get("let", {}) if async_for_await_update_nested_branch_outer_seq else {}
    async_for_await_update_nested_branch_loop = async_for_await_update_nested_branch_inner_let.get("body", {}).get("while_loop", {})
    async_for_await_update_nested_branch_body_seq = async_for_await_update_nested_branch_loop.get("body", {}).get("seq", [])
    async_for_await_update_nested_branch_body = async_for_await_update_nested_branch_body_seq[0].get("conditional", {}) if async_for_await_update_nested_branch_body_seq else {}
    async_for_await_update_nested_branch_update = async_for_await_update_nested_branch_body_seq[1].get("set_local", {}) if len(async_for_await_update_nested_branch_body_seq) > 1 else {}
    async_for_await_update_nested_branch_then = async_for_await_update_nested_branch_body.get("then", {}).get("let", {})
    async_for_await_update_nested_branch_nested = async_for_await_update_nested_branch_then.get("body", {}).get("conditional", {})
    async_for_await_update_nested_branch_nested_then = async_for_await_update_nested_branch_nested.get("then", {}).get("let", {})
    async_for_await_update_nested_branch_else = async_for_await_update_nested_branch_body.get("else", {}).get("let", {})
    if (
        async_for_await_update_nested_branch.get("async_future") is not True
        or async_for_await_update_nested_branch.get("body", {}).get("new_object", {}).get("type_args") != ["String"]
        or async_for_await_update_nested_branch_outer_let.get("locals", [{}])[0].get("name") != "out"
        or async_for_await_update_nested_branch_inner_let.get("locals", [{}])[0].get("name") != "i"
        or async_for_await_update_nested_branch_loop.get("condition", {}).get("op") != ">"
        or async_for_await_update_nested_branch_body.get("condition", {}).get("op") != "=="
        or async_for_await_update_nested_branch_then.get("locals", [{}])[0].get("name") != "state"
        or async_for_await_update_nested_branch_then.get("locals", [{}])[0].get("value", {}).get("await", {}).get("arg") != "ready"
        or async_for_await_update_nested_branch_nested.get("condition", {}).get("arg") != "premium"
        or async_for_await_update_nested_branch_nested_then.get("locals", [{}])[0].get("name") != "tier"
        or async_for_await_update_nested_branch_nested_then.get("locals", [{}])[0].get("value", {}).get("string") != "patched-for-await-update-nested-pro"
        or async_for_await_update_nested_branch_else.get("locals", [{}])[0].get("name") != "state"
        or async_for_await_update_nested_branch_else.get("locals", [{}])[0].get("value", {}).get("string") != "patched-for-await-update-nested-tail"
        or async_for_await_update_nested_branch_update.get("id") != 1
        or async_for_await_update_nested_branch_update.get("value", {}).get("await", {}).get("arg") != "next"
        or async_for_await_update_nested_branch_outer_seq[1].get("let_local") != 0
    ):
        raise SystemExit(f"expected asyncForAwaitUpdateNestedBranchLocal nested branch local + await update source, got {async_for_await_update_nested_branch}")
    async_for_await_condition_update_nested_branch = patch_by_member.get("asyncForAwaitConditionAwaitUpdateNestedBranchLocal", {}).get("bytecode_source", {})
    async_for_await_condition_update_nested_branch_arg = async_for_await_condition_update_nested_branch.get("body", {}).get("new_object", {}).get("args", [{}])[0]
    async_for_await_condition_update_nested_branch_outer_let = async_for_await_condition_update_nested_branch_arg.get("let", {})
    async_for_await_condition_update_nested_branch_outer_seq = async_for_await_condition_update_nested_branch_outer_let.get("body", {}).get("seq", [])
    async_for_await_condition_update_nested_branch_inner_let = async_for_await_condition_update_nested_branch_outer_seq[0].get("let", {}) if async_for_await_condition_update_nested_branch_outer_seq else {}
    async_for_await_condition_update_nested_branch_loop = async_for_await_condition_update_nested_branch_inner_let.get("body", {}).get("while_loop", {})
    async_for_await_condition_update_nested_branch_body_seq = async_for_await_condition_update_nested_branch_loop.get("body", {}).get("seq", [])
    async_for_await_condition_update_nested_branch_body = async_for_await_condition_update_nested_branch_body_seq[0].get("conditional", {}) if async_for_await_condition_update_nested_branch_body_seq else {}
    async_for_await_condition_update_nested_branch_update = async_for_await_condition_update_nested_branch_body_seq[1].get("set_local", {}) if len(async_for_await_condition_update_nested_branch_body_seq) > 1 else {}
    async_for_await_condition_update_nested_branch_then = async_for_await_condition_update_nested_branch_body.get("then", {}).get("let", {})
    async_for_await_condition_update_nested_branch_nested = async_for_await_condition_update_nested_branch_then.get("body", {}).get("conditional", {})
    async_for_await_condition_update_nested_branch_nested_then = async_for_await_condition_update_nested_branch_nested.get("then", {}).get("let", {})
    async_for_await_condition_update_nested_branch_else = async_for_await_condition_update_nested_branch_body.get("else", {}).get("let", {})
    if (
        async_for_await_condition_update_nested_branch.get("async_future") is not True
        or async_for_await_condition_update_nested_branch.get("body", {}).get("new_object", {}).get("type_args") != ["String"]
        or async_for_await_condition_update_nested_branch_outer_let.get("locals", [{}])[0].get("name") != "out"
        or async_for_await_condition_update_nested_branch_inner_let.get("locals", [{}])[0].get("name") != "i"
        or async_for_await_condition_update_nested_branch_loop.get("condition", {}).get("await", {}).get("arg") != "keepGoing"
        or async_for_await_condition_update_nested_branch_body.get("condition", {}).get("op") != "=="
        or async_for_await_condition_update_nested_branch_then.get("locals", [{}])[0].get("name") != "state"
        or async_for_await_condition_update_nested_branch_then.get("locals", [{}])[0].get("value", {}).get("await", {}).get("arg") != "ready"
        or async_for_await_condition_update_nested_branch_nested.get("condition", {}).get("arg") != "premium"
        or async_for_await_condition_update_nested_branch_nested_then.get("locals", [{}])[0].get("name") != "tier"
        or async_for_await_condition_update_nested_branch_nested_then.get("locals", [{}])[0].get("value", {}).get("string") != "patched-for-await-condition-update-nested-pro"
        or async_for_await_condition_update_nested_branch_else.get("locals", [{}])[0].get("name") != "state"
        or async_for_await_condition_update_nested_branch_else.get("locals", [{}])[0].get("value", {}).get("string") != "patched-for-await-condition-update-nested-tail"
        or async_for_await_condition_update_nested_branch_update.get("value", {}).get("await", {}).get("arg") != "next"
        or async_for_await_condition_update_nested_branch_outer_seq[1].get("let_local") != 0
    ):
        raise SystemExit(f"expected asyncForAwaitConditionAwaitUpdateNestedBranchLocal await condition + nested branch local + await update source, got {async_for_await_condition_update_nested_branch}")
    async_for_try_finally = patch_by_member.get("asyncForTryFinallyAwaitGuard", {}).get("bytecode_source", {})
    async_for_try_finally_arg = async_for_try_finally.get("body", {}).get("new_object", {}).get("args", [{}])[0]
    async_for_try_finally_outer_let = async_for_try_finally_arg.get("let", {})
    async_for_try_finally_outer_seq = async_for_try_finally_outer_let.get("body", {}).get("seq", [])
    async_for_try_finally_inner_let = async_for_try_finally_outer_seq[0].get("let", {}) if async_for_try_finally_outer_seq else {}
    async_for_try_finally_loop = async_for_try_finally_inner_let.get("body", {}).get("while_loop", {})
    async_for_try_finally_body = async_for_try_finally_loop.get("body", {}).get("seq", [])
    async_for_try_finally_try = async_for_try_finally_body[0].get("try_finally", {}) if async_for_try_finally_body else {}
    async_for_try_finally_try_body = async_for_try_finally_try.get("body", {}).get("seq", [])
    async_for_try_finally_guard = async_for_try_finally_try_body[1].get("conditional", {}) if len(async_for_try_finally_try_body) > 1 else {}
    async_for_try_finally_finalizer = async_for_try_finally_try.get("finally", {}).get("let", {})
    async_for_try_finally_finalizer_body = async_for_try_finally_finalizer.get("body", {}).get("seq", [])
    async_for_try_finally_update = async_for_try_finally_body[2].get("set_local", {}) if len(async_for_try_finally_body) > 2 else {}
    if (
        async_for_try_finally.get("async_future") is not True
        or async_for_try_finally_outer_let.get("locals", [{}])[0].get("name") != "out"
        or async_for_try_finally_inner_let.get("locals", [{}])[0].get("name") != "i"
        or async_for_try_finally_loop.get("condition", {}).get("op") != ">"
        or async_for_try_finally_try_body[0].get("set_local", {}).get("id") != 0
        or async_for_try_finally_guard.get("condition", {}).get("await", {}).get("arg") != "skip"
        or async_for_try_finally_guard.get("then", {}).get("seq", [{}])[0].get("set_local", {}).get("id") != 0
        or async_for_try_finally_guard.get("else", {}).get("seq", [{}])[0].get("set_local", {}).get("id") != 0
        or async_for_try_finally_finalizer.get("locals", [{}])[0].get("name") != "marker"
        or async_for_try_finally_finalizer.get("locals", [{}])[0].get("value", {}).get("await", {}).get("arg") != "cleanup"
        or async_for_try_finally_finalizer_body[0].get("set_local", {}).get("id") != 0
        or async_for_try_finally_update.get("id") != 1
        or async_for_try_finally_outer_seq[1].get("let_local") != 0
    ):
        raise SystemExit(f"expected asyncForTryFinallyAwaitGuard for + try/finally + await guard source, got {async_for_try_finally}")
    async_for_try_finally_await_update = patch_by_member.get("asyncForTryFinallyAwaitGuardAwaitUpdate", {}).get("bytecode_source", {})
    async_for_try_finally_await_update_arg = (
        async_for_try_finally_await_update.get("body", {}).get("new_object", {}).get("args", [{}])[0]
    )
    async_for_try_finally_await_update_outer_let = async_for_try_finally_await_update_arg.get("let", {})
    async_for_try_finally_await_update_outer_seq = async_for_try_finally_await_update_outer_let.get("body", {}).get("seq", [])
    async_for_try_finally_await_update_inner_let = (
        async_for_try_finally_await_update_outer_seq[0].get("let", {})
        if async_for_try_finally_await_update_outer_seq
        else {}
    )
    async_for_try_finally_await_update_loop = async_for_try_finally_await_update_inner_let.get("body", {}).get("while_loop", {})
    async_for_try_finally_await_update_body = async_for_try_finally_await_update_loop.get("body", {}).get("seq", [])
    async_for_try_finally_await_update_try = (
        async_for_try_finally_await_update_body[0].get("try_finally", {})
        if async_for_try_finally_await_update_body
        else {}
    )
    async_for_try_finally_await_update_try_body = async_for_try_finally_await_update_try.get("body", {}).get("seq", [])
    async_for_try_finally_await_update_guard = (
        async_for_try_finally_await_update_try_body[1].get("conditional", {})
        if len(async_for_try_finally_await_update_try_body) > 1
        else {}
    )
    async_for_try_finally_await_update_finalizer = async_for_try_finally_await_update_try.get("finally", {}).get("let", {})
    async_for_try_finally_await_update_finalizer_body = (
        async_for_try_finally_await_update_finalizer.get("body", {}).get("seq", [])
    )
    async_for_try_finally_await_update_update = (
        async_for_try_finally_await_update_body[2].get("set_local", {})
        if len(async_for_try_finally_await_update_body) > 2
        else {}
    )
    if (
        async_for_try_finally_await_update.get("async_future") is not True
        or async_for_try_finally_await_update_outer_let.get("locals", [{}])[0].get("name") != "out"
        or async_for_try_finally_await_update_inner_let.get("locals", [{}])[0].get("name") != "i"
        or async_for_try_finally_await_update_loop.get("condition", {}).get("op") != ">"
        or async_for_try_finally_await_update_try_body[0].get("set_local", {}).get("id") != 0
        or async_for_try_finally_await_update_guard.get("condition", {}).get("await", {}).get("arg") != "skip"
        or async_for_try_finally_await_update_guard.get("then", {}).get("seq", [{}])[0].get("set_local", {}).get("id") != 0
        or async_for_try_finally_await_update_guard.get("else", {}).get("seq", [{}])[0].get("set_local", {}).get("id") != 0
        or async_for_try_finally_await_update_finalizer.get("locals", [{}])[0].get("name") != "marker"
        or async_for_try_finally_await_update_finalizer.get("locals", [{}])[0].get("value", {}).get("await", {}).get("arg") != "cleanup"
        or async_for_try_finally_await_update_finalizer_body[0].get("set_local", {}).get("id") != 0
        or async_for_try_finally_await_update_update.get("id") != 1
        or async_for_try_finally_await_update_update.get("value", {}).get("await", {}).get("arg") != "next"
        or async_for_try_finally_await_update_outer_seq[1].get("let_local") != 0
    ):
        raise SystemExit(
            "expected asyncForTryFinallyAwaitGuardAwaitUpdate for + try/finally + await guard/update source, "
            f"got {async_for_try_finally_await_update}"
        )
    async_for_try_catch = patch_by_member.get("asyncForTryCatchAwaitGuard", {}).get("bytecode_source", {})
    async_for_try_catch_arg = async_for_try_catch.get("body", {}).get("new_object", {}).get("args", [{}])[0]
    async_for_try_catch_outer_let = async_for_try_catch_arg.get("let", {})
    async_for_try_catch_outer_seq = async_for_try_catch_outer_let.get("body", {}).get("seq", [])
    async_for_try_catch_inner_let = async_for_try_catch_outer_seq[0].get("let", {}) if async_for_try_catch_outer_seq else {}
    async_for_try_catch_loop = async_for_try_catch_inner_let.get("body", {}).get("while_loop", {})
    async_for_try_catch_body = async_for_try_catch_loop.get("body", {}).get("seq", [])
    async_for_try_catch_try = async_for_try_catch_body[0].get("try_catch", {}) if async_for_try_catch_body else {}
    async_for_try_catch_try_body = async_for_try_catch_try.get("body", {}).get("seq", [])
    async_for_try_catch_guard = async_for_try_catch_try_body[1].get("conditional", {}) if len(async_for_try_catch_try_body) > 1 else {}
    async_for_try_catch_catch = async_for_try_catch_try.get("catch", {}).get("seq", [])
    async_for_try_catch_update = async_for_try_catch_body[2].get("set_local", {}) if len(async_for_try_catch_body) > 2 else {}
    if (
        async_for_try_catch.get("async_future") is not True
        or async_for_try_catch_outer_let.get("locals", [{}])[0].get("name") != "out"
        or async_for_try_catch_inner_let.get("locals", [{}])[0].get("name") != "i"
        or async_for_try_catch_loop.get("condition", {}).get("op") != ">"
        or async_for_try_catch_try.get("catch_local") != 2
        or async_for_try_catch_try_body[0].get("set_local", {}).get("id") != 0
        or async_for_try_catch_guard.get("condition", {}).get("await", {}).get("arg") != "fail"
        or async_for_try_catch_guard.get("then", {}).get("seq", [{}])[0].get("throw") is None
        or async_for_try_catch_guard.get("else", {}).get("seq", [{}])[0].get("set_local", {}).get("id") != 0
        or async_for_try_catch_catch[0].get("set_local", {}).get("id") != 0
        or async_for_try_catch_catch[0].get("set_local", {}).get("value", {}).get("concat", [{}, {}, {}])[2].get("let_local") != 2
        or async_for_try_catch_body[1].get("null") is not True
        or async_for_try_catch_update.get("id") != 1
        or async_for_try_catch_outer_seq[1].get("let_local") != 0
    ):
        raise SystemExit(f"expected asyncForTryCatchAwaitGuard for + try/catch + await guard source, got {async_for_try_catch}")
    async_for_try_catch_await_update = patch_by_member.get("asyncForTryCatchAwaitGuardAwaitUpdate", {}).get("bytecode_source", {})
    async_for_try_catch_await_update_arg = (
        async_for_try_catch_await_update.get("body", {}).get("new_object", {}).get("args", [{}])[0]
    )
    async_for_try_catch_await_update_outer_let = async_for_try_catch_await_update_arg.get("let", {})
    async_for_try_catch_await_update_outer_seq = async_for_try_catch_await_update_outer_let.get("body", {}).get("seq", [])
    async_for_try_catch_await_update_inner_let = (
        async_for_try_catch_await_update_outer_seq[0].get("let", {})
        if async_for_try_catch_await_update_outer_seq
        else {}
    )
    async_for_try_catch_await_update_loop = async_for_try_catch_await_update_inner_let.get("body", {}).get("while_loop", {})
    async_for_try_catch_await_update_body = async_for_try_catch_await_update_loop.get("body", {}).get("seq", [])
    async_for_try_catch_await_update_try = (
        async_for_try_catch_await_update_body[0].get("try_catch", {})
        if async_for_try_catch_await_update_body
        else {}
    )
    async_for_try_catch_await_update_try_body = async_for_try_catch_await_update_try.get("body", {}).get("seq", [])
    async_for_try_catch_await_update_guard = (
        async_for_try_catch_await_update_try_body[1].get("conditional", {})
        if len(async_for_try_catch_await_update_try_body) > 1
        else {}
    )
    async_for_try_catch_await_update_catch = async_for_try_catch_await_update_try.get("catch", {}).get("seq", [])
    async_for_try_catch_await_update_update = (
        async_for_try_catch_await_update_body[2].get("set_local", {})
        if len(async_for_try_catch_await_update_body) > 2
        else {}
    )
    if (
        async_for_try_catch_await_update.get("async_future") is not True
        or async_for_try_catch_await_update_outer_let.get("locals", [{}])[0].get("name") != "out"
        or async_for_try_catch_await_update_inner_let.get("locals", [{}])[0].get("name") != "i"
        or async_for_try_catch_await_update_loop.get("condition", {}).get("op") != ">"
        or async_for_try_catch_await_update_try.get("catch_local") != 2
        or async_for_try_catch_await_update_try_body[0].get("set_local", {}).get("id") != 0
        or async_for_try_catch_await_update_guard.get("condition", {}).get("await", {}).get("arg") != "fail"
        or async_for_try_catch_await_update_guard.get("then", {}).get("seq", [{}])[0].get("throw") is None
        or async_for_try_catch_await_update_guard.get("else", {}).get("seq", [{}])[0].get("set_local", {}).get("id") != 0
        or async_for_try_catch_await_update_catch[0].get("set_local", {}).get("id") != 0
        or async_for_try_catch_await_update_catch[0].get("set_local", {}).get("value", {}).get("concat", [{}, {}, {}])[2].get("let_local") != 2
        or async_for_try_catch_await_update_body[1].get("null") is not True
        or async_for_try_catch_await_update_update.get("id") != 1
        or async_for_try_catch_await_update_update.get("value", {}).get("await", {}).get("arg") != "next"
        or async_for_try_catch_await_update_outer_seq[1].get("let_local") != 0
    ):
        raise SystemExit(
            "expected asyncForTryCatchAwaitGuardAwaitUpdate for + try/catch + await guard/update source, "
            f"got {async_for_try_catch_await_update}"
        )
    assert_try_loop_source(
        "asyncWhileAwaitConditionTryCatchAwaitGuard",
        "while",
        True,
        condition_arg="keepGoing",
    )
    assert_try_loop_source(
        "asyncWhileAwaitConditionTryFinallyAwaitGuard",
        "while",
        False,
        condition_arg="keepGoing",
    )
    assert_try_loop_source(
        "asyncDoWhileAwaitConditionTryCatchAwaitGuard",
        "do_while",
        True,
        condition_arg="keepGoing",
    )
    assert_try_loop_source(
        "asyncDoWhileAwaitConditionTryFinallyAwaitGuard",
        "do_while",
        False,
        condition_arg="keepGoing",
    )
    assert_try_loop_source(
        "asyncForAwaitConditionTryFinallyAwaitGuardAwaitUpdate",
        "for",
        False,
        condition_arg="keepGoing",
        update_arg="next",
    )
    assert_try_loop_source(
        "asyncForAwaitConditionTryCatchAwaitGuardAwaitUpdate",
        "for",
        True,
        condition_arg="keepGoing",
        update_arg="next",
    )
    async_for_multi_update = patch_by_member.get("asyncForMultiUpdate", {}).get("bytecode_source", {})
    async_for_multi_update_arg = async_for_multi_update.get("body", {}).get("new_object", {}).get("args", [{}])[0]
    async_for_multi_update_outer_let = async_for_multi_update_arg.get("let", {})
    async_for_multi_update_outer_seq = async_for_multi_update_outer_let.get("body", {}).get("seq", [])
    async_for_multi_update_inner_let = async_for_multi_update_outer_seq[0].get("let", {}) if async_for_multi_update_outer_seq else {}
    async_for_multi_update_locals = async_for_multi_update_inner_let.get("locals", [])
    async_for_multi_update_loop = async_for_multi_update_inner_let.get("body", {}).get("while_loop", {})
    async_for_multi_update_body = async_for_multi_update_loop.get("body", {}).get("seq", [])
    if (
        async_for_multi_update.get("async_future") is not True
        or async_for_multi_update_outer_let.get("locals", [{}])[0].get("name") != "out"
        or [item.get("name") for item in async_for_multi_update_locals] != ["i", "j"]
        or async_for_multi_update_loop.get("condition", {}).get("op") != ">"
        or len(async_for_multi_update_body) != 4
        or async_for_multi_update_body[0].get("set_local", {}).get("id") != 0
        or async_for_multi_update_body[1].get("null") is not True
        or async_for_multi_update_body[2].get("set_local", {}).get("id") != 1
        or async_for_multi_update_body[3].get("set_local", {}).get("id") != 2
    ):
        raise SystemExit(f"expected asyncForMultiUpdate multi-update source, got {async_for_multi_update}")

    def assert_multi_update_combo_source(name, constants, awaits=(), has_catch=False, has_finally=False):
        source = patch_by_member.get(name, {}).get("bytecode_source", {})
        source_json = json.dumps(source)
        if (
            source.get("async_future") is not True
            or '"while_loop"' not in source_json
            or '"name": "i"' not in source_json
            or '"name": "j"' not in source_json
            or source_json.count('"set_local"') < 4
            or any(f'"await": {{"arg": "{arg}"}}' not in source_json for arg in awaits)
            or (has_catch and '"try_catch"' not in source_json)
            or (has_finally and '"try_finally"' not in source_json)
            or any(f'"string": "{constant}"' not in source_json for constant in constants)
        ):
            raise SystemExit(f"expected {name} multi-update combo source, got {source}")

    assert_multi_update_combo_source(
        "asyncForMultiUpdateBranchLocal",
        ["patched-for-multi-update-pro", "patched-for-multi-update-tail"],
        awaits=["ready"],
    )
    assert_multi_update_combo_source(
        "asyncForAwaitConditionMultiUpdateBranchLocal",
        [
            "patched-for-await-condition-multi-update-pro",
            "patched-for-await-condition-multi-update-tail",
        ],
        awaits=["keepGoing", "ready"],
    )
    assert_multi_update_combo_source(
        "asyncForMultiUpdateTryFinallyAwaitGuard",
        ["patched-for-multi-update-try-finally", "-finally-"],
        awaits=["skip", "cleanup"],
        has_finally=True,
    )
    assert_multi_update_combo_source(
        "asyncForAwaitConditionMultiUpdateTryCatchAwaitGuard",
        [
            "patched-for-await-condition-multi-update-try-catch",
            "patched-for-await-condition-multi-update-error-",
            "-caught-",
        ],
        awaits=["keepGoing", "fail"],
        has_catch=True,
    )
