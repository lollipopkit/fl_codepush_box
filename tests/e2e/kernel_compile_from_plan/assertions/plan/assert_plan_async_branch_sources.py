import json


def assert_async_branch_sources(patch_by_member):
    async_branch_local = patch_by_member.get("asyncBranchLocal", {}).get("bytecode_source", {})
    async_branch_conditional = async_branch_local.get("body", {}).get("new_object", {}).get(
        "args", [{}]
    )[0].get("conditional", {})
    if (
        async_branch_conditional.get("condition", {}).get("arg") != "enabled"
        or async_branch_conditional.get("then", {}).get("let", {}).get("locals", [{}])[0].get("name") != "status"
        or async_branch_conditional.get("else", {}).get("let", {}).get("locals", [{}])[0].get("name") != "status"
    ):
        raise SystemExit(f"expected asyncBranchLocal branch-local conditional source, got {async_branch_local}")

    async_if_try_finally = patch_by_member.get("asyncIfTryFinallyAwaitTail", {}).get("bytecode_source", {})
    async_if_try_arg = async_if_try_finally.get("body", {}).get("new_object", {}).get("args", [{}])[0]
    async_if_try_let = async_if_try_arg.get("let", {})
    async_if_try_conditional = async_if_try_let.get("body", {}).get("conditional", {})
    async_if_try_then_seq = async_if_try_conditional.get("then", {}).get("seq", [])
    async_if_try_then_finally = async_if_try_then_seq[0].get("try_finally", {}) if async_if_try_then_seq else {}
    async_if_try_body = async_if_try_then_finally.get("body", {}).get("let", {})
    async_if_try_body_seq = async_if_try_body.get("body", {}).get("seq", [])
    async_if_try_finalizer = async_if_try_then_finally.get("finally", {}).get("let", {})
    async_if_try_finalizer_seq = async_if_try_finalizer.get("body", {}).get("seq", [])
    async_if_try_else_seq = async_if_try_conditional.get("else", {}).get("seq", [])
    if (
        async_if_try_let.get("locals", [{}])[0].get("name") != "out"
        or async_if_try_conditional.get("condition", {}).get("arg") != "enabled"
        or async_if_try_body.get("locals", [{}])[0].get("name") != "value"
        or async_if_try_body.get("locals", [{}])[0].get("value", {}).get("await", {}).get("arg") != "ready"
        or async_if_try_body_seq[0].get("set_local", {}).get("id") != 0
        or async_if_try_finalizer.get("locals", [{}])[0].get("name") != "marker"
        or async_if_try_finalizer.get("locals", [{}])[0].get("value", {}).get("await", {}).get("arg") != "cleanup"
        or async_if_try_finalizer_seq[0].get("set_local", {}).get("id") != 0
        or async_if_try_then_seq[1].get("let_local") != 0
        or async_if_try_else_seq[0].get("set_local", {}).get("id") != 0
        or async_if_try_else_seq[1].get("let_local") != 0
    ):
        raise SystemExit(
            "expected asyncIfTryFinallyAwaitTail branch try/finally await statement + shared tail source, "
            f"got {async_if_try_finally}"
        )

    async_if_try_catch = patch_by_member.get("asyncIfTryCatchAwaitTail", {}).get("bytecode_source", {})
    async_if_catch_arg = async_if_try_catch.get("body", {}).get("new_object", {}).get("args", [{}])[0]
    async_if_catch_let = async_if_catch_arg.get("let", {})
    async_if_catch_conditional = async_if_catch_let.get("body", {}).get("conditional", {})
    async_if_catch_then_seq = async_if_catch_conditional.get("then", {}).get("seq", [])
    async_if_catch_then_try = async_if_catch_then_seq[0].get("try_catch", {}) if async_if_catch_then_seq else {}
    async_if_catch_body = async_if_catch_then_try.get("body", {}).get("let", {})
    async_if_catch_body_seq = async_if_catch_body.get("body", {}).get("seq", [])
    async_if_catch_catch = async_if_catch_then_try.get("catch", {}).get("let", {})
    async_if_catch_catch_seq = async_if_catch_catch.get("body", {}).get("seq", [])
    async_if_catch_else_seq = async_if_catch_conditional.get("else", {}).get("seq", [])
    if (
        async_if_catch_let.get("locals", [{}])[0].get("name") != "out"
        or async_if_catch_conditional.get("condition", {}).get("arg") != "enabled"
        or async_if_catch_then_try.get("catch_local") != 1
        or async_if_catch_body.get("locals", [{}])[0].get("name") != "value"
        or async_if_catch_body.get("locals", [{}])[0].get("value", {}).get("await", {}).get("arg") != "ready"
        or async_if_catch_body_seq[0].get("set_local", {}).get("id") != 0
        or async_if_catch_catch.get("locals", [{}])[0].get("name") != "recovered"
        or async_if_catch_catch.get("locals", [{}])[0].get("value", {}).get("await", {}).get("arg") != "recovery"
        or async_if_catch_catch_seq[0].get("set_local", {}).get("id") != 0
        or async_if_catch_catch_seq[0]
        .get("set_local", {})
        .get("value", {})
        .get("concat", [{}, {}, {}, {}])[2]
        .get("let_local")
        != 1
        or async_if_catch_catch_seq[0]
        .get("set_local", {})
        .get("value", {})
        .get("concat", [{}, {}, {}, {}])[4]
        .get("let_local")
        != 2
        or async_if_catch_then_seq[1].get("let_local") != 0
        or async_if_catch_else_seq[0].get("set_local", {}).get("id") != 0
        or async_if_catch_else_seq[1].get("let_local") != 0
    ):
        raise SystemExit(
            "expected asyncIfTryCatchAwaitTail branch try/catch await statement + shared tail source, "
            f"got {async_if_try_catch}"
        )

    async_ifelse_try = patch_by_member.get(
        "asyncIfElseTryFinallyCatchAwaitTail", {}
    ).get("bytecode_source", {})
    async_ifelse_arg = async_ifelse_try.get("body", {}).get("new_object", {}).get("args", [{}])[0]
    async_ifelse_let = async_ifelse_arg.get("let", {})
    async_ifelse_conditional = async_ifelse_let.get("body", {}).get("conditional", {})
    async_ifelse_then_seq = async_ifelse_conditional.get("then", {}).get("seq", [])
    async_ifelse_then_finally = async_ifelse_then_seq[0].get("try_finally", {}) if async_ifelse_then_seq else {}
    async_ifelse_then_body = async_ifelse_then_finally.get("body", {}).get("let", {})
    async_ifelse_then_body_seq = async_ifelse_then_body.get("body", {}).get("seq", [])
    async_ifelse_then_finalizer = async_ifelse_then_finally.get("finally", {}).get("let", {})
    async_ifelse_then_finalizer_seq = async_ifelse_then_finalizer.get("body", {}).get("seq", [])
    async_ifelse_else_seq = async_ifelse_conditional.get("else", {}).get("seq", [])
    async_ifelse_else_try = async_ifelse_else_seq[0].get("try_catch", {}) if async_ifelse_else_seq else {}
    async_ifelse_else_body = async_ifelse_else_try.get("body", {}).get("let", {})
    async_ifelse_else_body_seq = async_ifelse_else_body.get("body", {}).get("seq", [])
    async_ifelse_else_catch = async_ifelse_else_try.get("catch", {}).get("let", {})
    async_ifelse_else_catch_seq = async_ifelse_else_catch.get("body", {}).get("seq", [])
    if (
        async_ifelse_let.get("locals", [{}])[0].get("name") != "out"
        or async_ifelse_conditional.get("condition", {}).get("arg") != "enabled"
        or async_ifelse_then_body.get("locals", [{}])[0].get("name") != "value"
        or async_ifelse_then_body.get("locals", [{}])[0].get("value", {}).get("await", {}).get("arg") != "ready"
        or async_ifelse_then_body_seq[0].get("set_local", {}).get("id") != 0
        or async_ifelse_then_finalizer.get("locals", [{}])[0].get("name") != "marker"
        or async_ifelse_then_finalizer.get("locals", [{}])[0].get("value", {}).get("await", {}).get("arg")
        != "cleanup"
        or async_ifelse_then_finalizer_seq[0].get("set_local", {}).get("id") != 0
        or async_ifelse_then_seq[1].get("let_local") != 0
        or async_ifelse_else_try.get("catch_local") != 1
        or async_ifelse_else_body.get("locals", [{}])[0].get("name") != "value"
        or async_ifelse_else_body.get("locals", [{}])[0].get("value", {}).get("await", {}).get("arg") != "ready"
        or async_ifelse_else_body_seq[0].get("set_local", {}).get("id") != 0
        or async_ifelse_else_catch.get("locals", [{}])[0].get("name") != "recovered"
        or async_ifelse_else_catch.get("locals", [{}])[0].get("value", {}).get("await", {}).get("arg")
        != "recovery"
        or async_ifelse_else_catch_seq[0].get("set_local", {}).get("id") != 0
        or async_ifelse_else_seq[1].get("let_local") != 0
    ):
        raise SystemExit(
            "expected asyncIfElseTryFinallyCatchAwaitTail if/else try-finally/try-catch await shared tail source, "
            f"got {async_ifelse_try}"
        )

    def assert_branch_tail(member, constants, min_try_finally, min_try_catch, min_awaits):
        function = patch_by_member.get(member)
        if function is None:
            raise SystemExit(f"missing inventory entry for {member}")
        source = function.get("bytecode_source")
        source_json = json.dumps(source)
        if (
            function.get("unsupported_reasons") != []
            or not isinstance(source, dict)
            or source.get("async_future") is not True
            or source_json.count('"conditional"') < 1
            or source_json.count('"try_finally"') < min_try_finally
            or source_json.count('"try_catch"') < min_try_catch
            or source_json.count('"await"') < min_awaits
            or '"arg": "enabled"' not in source_json
            or '"string": "-tail"' not in source_json
            or any(f'"string": "{constant}"' not in source_json for constant in constants)
        ):
            raise SystemExit(f"expected {member} double-branch try source, got {function}")

    assert_branch_tail(
        "asyncIfElseBothTryFinallyAwaitTail",
        [
            "patched-ifelse-both-try-finally-await-tail",
            "-on-cleanup-",
            "-off-cleanup-",
        ],
        min_try_finally=2,
        min_try_catch=0,
        min_awaits=4,
    )
    assert_branch_tail(
        "asyncIfElseBothTryCatchFinallyAwaitTail",
        [
            "patched-ifelse-both-catch-finally-await-tail",
            "-on-caught-",
            "-off-caught-",
            "-off-cleanup-",
        ],
        min_try_finally=2,
        min_try_catch=2,
        min_awaits=6,
    )

    async_nested_branch_local = patch_by_member.get("asyncNestedBranchLocal", {}).get("bytecode_source", {})
    async_nested_arg = async_nested_branch_local.get("body", {}).get("new_object", {}).get("args", [{}])[0]
    async_nested_outer = async_nested_arg.get("conditional", {})
    async_nested_then_let = async_nested_outer.get("then", {}).get("let", {})
    async_nested_then_inner = async_nested_then_let.get("body", {}).get("conditional", {})
    async_nested_then_pro = async_nested_then_inner.get("then", {}).get("let", {})
    async_nested_then_basic = async_nested_then_inner.get("else", {}).get("let", {})
    async_nested_else_let = async_nested_outer.get("else", {}).get("let", {})
    async_nested_else_inner = async_nested_else_let.get("body", {}).get("conditional", {})
    async_nested_else_pro = async_nested_else_inner.get("then", {}).get("let", {})
    async_nested_else_basic = async_nested_else_inner.get("else", {}).get("let", {})
    if (
        async_nested_outer.get("condition", {}).get("arg") != "enabled"
        or async_nested_then_let.get("locals", [{}])[0].get("name") != "state"
        or async_nested_then_let.get("locals", [{}])[0].get("value", {}).get("string")
        != "patched-nested-enabled"
        or async_nested_then_inner.get("condition", {}).get("arg") != "premium"
        or async_nested_then_pro.get("locals", [{}])[0].get("name") != "tier"
        or async_nested_then_pro.get("locals", [{}])[0].get("value", {}).get("string") != "patched-nested-pro"
        or async_nested_then_basic.get("locals", [{}])[0].get("value", {}).get("string")
        != "patched-nested-basic"
        or async_nested_else_let.get("locals", [{}])[0].get("name") != "state"
        or async_nested_else_let.get("locals", [{}])[0].get("value", {}).get("string")
        != "patched-nested-disabled"
        or async_nested_else_inner.get("condition", {}).get("arg") != "premium"
        or async_nested_else_pro.get("locals", [{}])[0].get("value", {}).get("string")
        != "patched-nested-disabled-pro"
        or async_nested_else_basic.get("locals", [{}])[0].get("value", {}).get("string")
        != "patched-nested-disabled-basic"
        or async_nested_then_pro.get("body", {}).get("concat", [{}, {}, {}])[0].get("let_local") != 0
        or async_nested_then_pro.get("body", {}).get("concat", [{}, {}, {}])[2].get("let_local") != 1
    ):
        raise SystemExit(
            f"expected asyncNestedBranchLocal nested branch-local source, got {async_nested_branch_local}"
        )

    async_nested_await_branch_local = patch_by_member.get(
        "asyncNestedAwaitBranchLocal", {}
    ).get("bytecode_source", {})
    async_nested_await_arg = async_nested_await_branch_local.get("body", {}).get("new_object", {}).get(
        "args", [{}]
    )[0]
    async_nested_await_outer = async_nested_await_arg.get("conditional", {})
    async_nested_await_then_let = async_nested_await_outer.get("then", {}).get("let", {})
    async_nested_await_then_inner = async_nested_await_then_let.get("body", {}).get("conditional", {})
    async_nested_await_then_pro = async_nested_await_then_inner.get("then", {}).get("let", {})
    async_nested_await_then_basic = async_nested_await_then_inner.get("else", {}).get("let", {})
    async_nested_await_else_let = async_nested_await_outer.get("else", {}).get("let", {})
    async_nested_await_else_inner = async_nested_await_else_let.get("body", {}).get("conditional", {})
    async_nested_await_else_pro = async_nested_await_else_inner.get("then", {}).get("let", {})
    async_nested_await_else_basic = async_nested_await_else_inner.get("else", {}).get("let", {})
    if (
        async_nested_await_outer.get("condition", {}).get("arg") != "enabled"
        or async_nested_await_then_let.get("locals", [{}])[0].get("name") != "state"
        or async_nested_await_then_let.get("locals", [{}])[0].get("value", {}).get("await", {}).get("arg")
        != "ready"
        or async_nested_await_then_inner.get("condition", {}).get("arg") != "premium"
        or async_nested_await_then_pro.get("locals", [{}])[0].get("value", {}).get("string")
        != "patched-nested-await-pro"
        or async_nested_await_then_basic.get("locals", [{}])[0].get("value", {}).get("string")
        != "patched-nested-await-basic"
        or async_nested_await_else_let.get("locals", [{}])[0].get("value", {}).get("string")
        != "patched-nested-await-disabled"
        or async_nested_await_else_inner.get("condition", {}).get("arg") != "premium"
        or async_nested_await_else_pro.get("locals", [{}])[0].get("name") != "tier"
        or async_nested_await_else_pro.get("locals", [{}])[0].get("value", {}).get("await", {}).get("arg")
        != "ready"
        or async_nested_await_else_basic.get("locals", [{}])[0].get("value", {}).get("string")
        != "patched-nested-await-disabled-basic"
        or async_nested_await_else_pro.get("body", {}).get("concat", [{}, {}, {}])[0].get("let_local") != 0
        or async_nested_await_else_pro.get("body", {}).get("concat", [{}, {}, {}])[2].get("let_local") != 1
    ):
        raise SystemExit(
            "expected asyncNestedAwaitBranchLocal nested await branch-local source, "
            f"got {async_nested_await_branch_local}"
        )
