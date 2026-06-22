import json
import sys

from assert_plan_core_collection_names import assert_core_collection_name_sources
from assert_plan_core_objects import assert_core_object_sources
from assert_plan_core_ops import assert_core_op_sources

patch = json.load(open(sys.argv[1]))
patch_by_member = {f.get("member_name"): f for f in patch["functions"]}


def source_for(member):
    function = patch_by_member.get(member)
    if function is None:
        raise SystemExit(f"missing inventory entry for {member}")
    source = function.get("bytecode_source")
    if not isinstance(source, dict):
        raise SystemExit(f"{member} should produce bytecode source: {function}")
    if function.get("unsupported_reasons") != []:
        raise SystemExit(f"{member} should now be supported, got {function}")
    return source


sync_try_finally_source = source_for("syncTryFinallyTail")
sync_try_finally_let = sync_try_finally_source.get("body", {}).get("let", {})
sync_try_finally_locals = sync_try_finally_let.get("locals", [])
sync_try_finally_seq = sync_try_finally_let.get("body", {}).get("seq", [])
sync_try_finally = sync_try_finally_seq[0].get("try_finally", {}) if sync_try_finally_seq else {}
sync_try_finally_body_set = sync_try_finally.get("body", {}).get("set_local", {})
sync_try_finally_finally_set = sync_try_finally.get("finally", {}).get("set_local", {})
if (
    sync_try_finally_source.get("params") != ["name"]
    or sync_try_finally_source.get("return_type") != "String"
    or len(sync_try_finally_locals) != 1
    or sync_try_finally_locals[0].get("name") != "out"
    or sync_try_finally_locals[0].get("value", {}).get("string") != "patched-sync-finally"
    or sync_try_finally_body_set.get("id") != 0
    or sync_try_finally_body_set.get("value", {}).get("concat", [{}, {}, {}])[2].get("arg") != "name"
    or sync_try_finally_finally_set.get("id") != 0
    or sync_try_finally_finally_set.get("value", {}).get("concat", [{}, {}])[1].get("string") != "-cleanup"
    or sync_try_finally_seq[1].get("let_local") != 0
):
    raise SystemExit(f"expected syncTryFinallyTail sync try/finally statement + tail source, got {sync_try_finally_source}")

sync_try_catch_source = source_for("syncTryCatchTail")
sync_try_catch_let = sync_try_catch_source.get("body", {}).get("let", {})
sync_try_catch_locals = sync_try_catch_let.get("locals", [])
sync_try_catch_seq = sync_try_catch_let.get("body", {}).get("seq", [])
sync_try_catch = sync_try_catch_seq[0].get("try_catch", {}) if sync_try_catch_seq else {}
sync_try_catch_body_set = sync_try_catch.get("body", {}).get("set_local", {})
sync_try_catch_catch_set = sync_try_catch.get("catch", {}).get("set_local", {})
if (
    sync_try_catch_source.get("params") != ["name"]
    or sync_try_catch_source.get("return_type") != "String"
    or len(sync_try_catch_locals) != 1
    or sync_try_catch_locals[0].get("name") != "out"
    or sync_try_catch_locals[0].get("value", {}).get("string") != "patched-sync-catch"
    or sync_try_catch.get("catch_local") != 1
    or sync_try_catch_body_set.get("id") != 0
    or sync_try_catch_body_set.get("value", {}).get("concat", [{}, {}, {}])[2].get("arg") != "name"
    or sync_try_catch_catch_set.get("id") != 0
    or sync_try_catch_catch_set.get("value", {}).get("concat", [{}, {}, {}])[2].get("let_local") != 1
    or sync_try_catch_seq[1].get("let_local") != 0
):
    raise SystemExit(f"expected syncTryCatchTail sync try/catch statement + tail source, got {sync_try_catch_source}")

sync_try_catch_local_statement_source = source_for("syncTryCatchLocalStatementTail")
sync_try_catch_local_statement_let = sync_try_catch_local_statement_source.get("body", {}).get("let", {})
sync_try_catch_local_statement_seq = sync_try_catch_local_statement_let.get("body", {}).get("seq", [])
sync_try_catch_local_statement_try = (
    sync_try_catch_local_statement_seq[0].get("try_catch", {}) if sync_try_catch_local_statement_seq else {}
)
sync_try_catch_local_statement_catch_let = sync_try_catch_local_statement_try.get("catch", {}).get("let", {})
sync_try_catch_local_statement_message = sync_try_catch_local_statement_catch_let.get("locals", [{}])[0]
sync_try_catch_local_statement_set = sync_try_catch_local_statement_catch_let.get("body", {}).get("set_local", {})
if (
    sync_try_catch_local_statement_source.get("params") != ["name"]
    or sync_try_catch_local_statement_source.get("return_type") != "String"
    or sync_try_catch_local_statement_let.get("locals", [{}])[0].get("name") != "out"
    or sync_try_catch_local_statement_try.get("catch_local") != 1
    or not sync_try_catch_local_statement_try.get("body", {}).get("call_static", "").endswith("::label")
    or sync_try_catch_local_statement_message.get("id") != 2
    or sync_try_catch_local_statement_message.get("name") != "message"
    or sync_try_catch_local_statement_message.get("value", {}).get("concat", [{}, {}])[1].get("let_local") != 1
    or sync_try_catch_local_statement_set.get("id") != 0
    or sync_try_catch_local_statement_set.get("value", {}).get("let_local") != 2
    or sync_try_catch_local_statement_seq[1].get("let_local") != 0
):
    raise SystemExit(
        f"expected syncTryCatchLocalStatementTail catch-local statement source, got {sync_try_catch_local_statement_source}"
    )

sync_try_catch_body_local_source = source_for("syncTryCatchBodyLocalStatementTail")
sync_try_catch_body_local_let = sync_try_catch_body_local_source.get("body", {}).get("let", {})
sync_try_catch_body_local_seq = sync_try_catch_body_local_let.get("body", {}).get("seq", [])
sync_try_catch_body_local_try = (
    sync_try_catch_body_local_seq[0].get("try_catch", {}) if sync_try_catch_body_local_seq else {}
)
sync_try_catch_body_local_try_let = sync_try_catch_body_local_try.get("body", {}).get("let", {})
sync_try_catch_body_local_message = sync_try_catch_body_local_try_let.get("locals", [{}])[0]
sync_try_catch_body_local_set = sync_try_catch_body_local_try_let.get("body", {}).get("set_local", {})
sync_try_catch_body_local_catch = sync_try_catch_body_local_try.get("catch", {})
if (
    sync_try_catch_body_local_source.get("params") != ["name"]
    or sync_try_catch_body_local_source.get("return_type") != "String"
    or sync_try_catch_body_local_let.get("locals", [{}])[0].get("name") != "out"
    or sync_try_catch_body_local_try.get("catch_local") != 1
    or sync_try_catch_body_local_message.get("id") != 1
    or sync_try_catch_body_local_message.get("name") != "message"
    or sync_try_catch_body_local_message.get("value", {}).get("concat", [{}, {}])[0].get("string")
    != "patched-sync-catch-body-local-message-"
    or sync_try_catch_body_local_set.get("id") != 0
    or sync_try_catch_body_local_set.get("value", {}).get("let_local") != 1
    or not sync_try_catch_body_local_catch.get("call_static", "").endswith("::label")
    or sync_try_catch_body_local_catch.get("args", [{}])[0].get("concat", [{}, {}])[1].get("let_local") != 1
    or sync_try_catch_body_local_seq[1].get("let_local") != 0
):
    raise SystemExit(
        f"expected syncTryCatchBodyLocalStatementTail try-body-local statement source, got {sync_try_catch_body_local_source}"
    )

sync_try_catch_return_source = source_for("syncTryCatchReturnValue")
sync_try_catch_return = sync_try_catch_return_source.get("body", {}).get("try_catch", {})
sync_try_catch_return_body = sync_try_catch_return.get("body", {}).get("concat", [])
sync_try_catch_return_catch = sync_try_catch_return.get("catch", {}).get("concat", [])
if (
    sync_try_catch_return_source.get("params") != ["name"]
    or sync_try_catch_return_source.get("return_type") != "String"
    or sync_try_catch_return.get("catch_local") != 0
    or sync_try_catch_return_body != [{"string": "patched-catch-return-"}, {"arg": "name"}]
    or sync_try_catch_return_catch != [{"string": "patched-caught-return-"}, {"let_local": 0}]
):
    raise SystemExit(
        f"expected syncTryCatchReturnValue sync try/catch value-preserving source, got {sync_try_catch_return_source}"
    )

sync_try_catch_local_return_source = source_for("syncTryCatchLocalReturnValue")
sync_try_catch_local_return = sync_try_catch_local_return_source.get("body", {}).get("try_catch", {})
sync_try_catch_local_catch_let = sync_try_catch_local_return.get("catch", {}).get("let", {})
sync_try_catch_local_catch_locals = sync_try_catch_local_catch_let.get("locals", [])
sync_try_catch_local_message = sync_try_catch_local_catch_locals[0] if sync_try_catch_local_catch_locals else {}
sync_try_catch_local_message_value = sync_try_catch_local_message.get("value", {}).get("concat", [])
if (
    sync_try_catch_local_return_source.get("params") != ["name"]
    or sync_try_catch_local_return_source.get("return_type") != "String"
    or sync_try_catch_local_return.get("catch_local") != 0
    or sync_try_catch_local_return.get("body", {}).get("concat", [])
    != [{"string": "patched-catch-local-return-"}, {"arg": "name"}]
    or sync_try_catch_local_message.get("id") != 1
    or sync_try_catch_local_message.get("name") != "message"
    or sync_try_catch_local_message_value != [{"string": "patched-catch-local-caught-"}, {"let_local": 0}]
    or sync_try_catch_local_catch_let.get("body", {}).get("let_local") != 1
):
    raise SystemExit(
        f"expected syncTryCatchLocalReturnValue catch-local let source, got {sync_try_catch_local_return_source}"
    )

sync_try_catch_finally_return_source = source_for("syncTryCatchFinallyReturnValue")
sync_try_catch_finally_return = sync_try_catch_finally_return_source.get("body", {}).get("try_finally", {})
sync_try_catch_finally_body = sync_try_catch_finally_return.get("body", {}).get("try_catch", {})
sync_try_catch_finally_try = sync_try_catch_finally_body.get("body", {}).get("concat", [])
sync_try_catch_finally_catch = sync_try_catch_finally_body.get("catch", {}).get("concat", [])
sync_try_catch_finally_cleanup = sync_try_catch_finally_return.get("finally", {}).get("args", [{}])[0].get(
    "concat",
    [],
)
if (
    sync_try_catch_finally_return_source.get("params") != ["name"]
    or sync_try_catch_finally_return_source.get("return_type") != "String"
    or sync_try_catch_finally_return.get("value") is not True
    or sync_try_catch_finally_body.get("catch_local") != 0
    or sync_try_catch_finally_try != [{"string": "patched-catch-finally-return-"}, {"arg": "name"}]
    or sync_try_catch_finally_catch != [{"string": "patched-catch-finally-caught-"}, {"let_local": 0}]
    or sync_try_catch_finally_cleanup != [{"string": "patched-catch-finally-cleanup-"}, {"arg": "name"}]
):
    raise SystemExit(
        "expected syncTryCatchFinallyReturnValue nested try/catch/finally value-preserving source, "
        f"got {sync_try_catch_finally_return_source}"
    )

sync_try_catch_statement_source = source_for("syncTryCatchStatementTail")
sync_try_catch_statement_seq = sync_try_catch_statement_source.get("body", {}).get("seq", [])
sync_try_catch_statement = (
    sync_try_catch_statement_seq[0].get("try_catch", {}) if sync_try_catch_statement_seq else {}
)
sync_try_catch_statement_body = sync_try_catch_statement.get("body", {})
sync_try_catch_statement_catch = sync_try_catch_statement.get("catch", {})
sync_try_catch_statement_tail = sync_try_catch_statement_seq[1].get("concat", []) if len(sync_try_catch_statement_seq) > 1 else []
if (
    sync_try_catch_statement_source.get("params") != ["name"]
    or sync_try_catch_statement_source.get("return_type") != "String"
    or sync_try_catch_statement.get("catch_local") != 0
    or not sync_try_catch_statement_body.get("call_static", "").endswith("::label")
    or sync_try_catch_statement_body.get("args") != [{"arg": "name"}]
    or not sync_try_catch_statement_catch.get("call_static", "").endswith("::label")
    or sync_try_catch_statement_catch.get("args", [{}])[0].get("concat", [{}])[0].get("let_local") != 0
    or sync_try_catch_statement_tail != [{"string": "patched-sync-catch-statement-"}, {"arg": "name"}]
):
    raise SystemExit(
        f"expected syncTryCatchStatementTail sync try/catch expression statement + tail source, got {sync_try_catch_statement_source}"
    )

sync_try_catch_void_source = source_for("syncTryCatchStatementVoid")
sync_try_catch_void_seq = sync_try_catch_void_source.get("body", {}).get("seq", [])
sync_try_catch_void = sync_try_catch_void_seq[0].get("try_catch", {}) if sync_try_catch_void_seq else {}
sync_try_catch_void_body = sync_try_catch_void.get("body", {})
sync_try_catch_void_catch = sync_try_catch_void.get("catch", {})
if (
    sync_try_catch_void_source.get("params") != ["name"]
    or sync_try_catch_void_source.get("return_type") is not None
    or sync_try_catch_void.get("catch_local") != 0
    or not sync_try_catch_void_body.get("call_static", "").endswith("::label")
    or sync_try_catch_void_body.get("args") != [{"arg": "name"}]
    or not sync_try_catch_void_catch.get("call_static", "").endswith("::label")
    or sync_try_catch_void_catch.get("args", [{}])[0].get("concat", [{}, {}])[0].get("string")
    != "patched-catch-void-"
    or sync_try_catch_void_catch.get("args", [{}])[0].get("concat", [{}, {}])[1].get("let_local") != 0
    or sync_try_catch_void_seq[1].get("null") is not True
):
    raise SystemExit(
        f"expected syncTryCatchStatementVoid sync try/catch expression statement + implicit null source, got {sync_try_catch_void_source}"
    )

sync_try_finally_statement_source = source_for("syncTryFinallyStatementTail")
sync_try_finally_statement_seq = sync_try_finally_statement_source.get("body", {}).get("seq", [])
sync_try_finally_statement = (
    sync_try_finally_statement_seq[0].get("try_finally", {}) if sync_try_finally_statement_seq else {}
)
sync_try_finally_statement_body = sync_try_finally_statement.get("body", {})
sync_try_finally_statement_finally = sync_try_finally_statement.get("finally", {})
sync_try_finally_statement_tail = (
    sync_try_finally_statement_seq[1].get("concat", []) if len(sync_try_finally_statement_seq) > 1 else []
)
if (
    sync_try_finally_statement_source.get("params") != ["name"]
    or sync_try_finally_statement_source.get("return_type") != "String"
    or not sync_try_finally_statement_body.get("call_static", "").endswith("::label")
    or sync_try_finally_statement_body.get("args") != [{"arg": "name"}]
    or not sync_try_finally_statement_finally.get("call_static", "").endswith("::label")
    or sync_try_finally_statement_finally.get("args", [{}])[0].get("concat", [{}, {}])[0].get("string")
    != "patched-cleanup-"
    or sync_try_finally_statement_finally.get("args", [{}])[0].get("concat", [{}, {}])[1].get("arg") != "name"
    or sync_try_finally_statement_tail != [{"string": "patched-sync-finally-statement-"}, {"arg": "name"}]
):
    raise SystemExit(
        f"expected syncTryFinallyStatementTail sync try/finally expression statement + tail source, got {sync_try_finally_statement_source}"
    )

sync_try_finally_local_statement_source = source_for("syncTryFinallyLocalStatementTail")
sync_try_finally_local_statement_seq = sync_try_finally_local_statement_source.get("body", {}).get("seq", [])
sync_try_finally_local_statement = (
    sync_try_finally_local_statement_seq[0].get("try_finally", {})
    if sync_try_finally_local_statement_seq
    else {}
)
sync_try_finally_local_finally = sync_try_finally_local_statement.get("finally", {}).get("let", {})
sync_try_finally_local_cleanup = sync_try_finally_local_finally.get("locals", [{}])[0]
sync_try_finally_local_tail = (
    sync_try_finally_local_statement_seq[1].get("concat", [])
    if len(sync_try_finally_local_statement_seq) > 1
    else []
)
if (
    sync_try_finally_local_statement_source.get("params") != ["name"]
    or sync_try_finally_local_statement_source.get("return_type") != "String"
    or not sync_try_finally_local_statement.get("body", {}).get("call_static", "").endswith("::label")
    or sync_try_finally_local_cleanup.get("name") != "cleanup"
    or sync_try_finally_local_cleanup.get("value", {}).get("concat", [{}, {}])[0].get("string")
    != "patched-cleanup-local-"
    or not sync_try_finally_local_finally.get("body", {}).get("call_static", "").endswith("::label")
    or sync_try_finally_local_finally.get("body", {}).get("args", [{}])[0].get("let_local") != 0
    or sync_try_finally_local_tail
    != [{"string": "patched-sync-finally-local-statement-"}, {"arg": "name"}]
):
    raise SystemExit(
        f"expected syncTryFinallyLocalStatementTail sync try/finally finalizer-local source, got {sync_try_finally_local_statement_source}"
    )

sync_try_finally_body_local_source = source_for("syncTryFinallyBodyLocalStatementTail")
sync_try_finally_body_local_seq = sync_try_finally_body_local_source.get("body", {}).get("seq", [])
sync_try_finally_body_local = (
    sync_try_finally_body_local_seq[0].get("try_finally", {})
    if sync_try_finally_body_local_seq
    else {}
)
sync_try_finally_body_local_body = sync_try_finally_body_local.get("body", {}).get("let", {})
sync_try_finally_body_local_message = sync_try_finally_body_local_body.get("locals", [{}])[0]
sync_try_finally_body_local_finally = sync_try_finally_body_local.get("finally", {})
sync_try_finally_body_local_tail = (
    sync_try_finally_body_local_seq[1].get("concat", [])
    if len(sync_try_finally_body_local_seq) > 1
    else []
)
if (
    sync_try_finally_body_local_source.get("params") != ["name"]
    or sync_try_finally_body_local_source.get("return_type") != "String"
    or sync_try_finally_body_local_message.get("name") != "message"
    or sync_try_finally_body_local_message.get("value", {}).get("concat", [{}, {}])[0].get("string")
    != "patched-finally-body-local-"
    or not sync_try_finally_body_local_body.get("body", {}).get("call_static", "").endswith("::label")
    or sync_try_finally_body_local_body.get("body", {}).get("args", [{}])[0].get("let_local") != 0
    or not sync_try_finally_body_local_finally.get("call_static", "").endswith("::label")
    or sync_try_finally_body_local_finally.get("args", [{}])[0].get("concat", [{}, {}])[0].get("string")
    != "patched-finally-body-cleanup-"
    or sync_try_finally_body_local_tail
    != [{"string": "patched-sync-finally-body-local-statement-"}, {"arg": "name"}]
):
    raise SystemExit(
        f"expected syncTryFinallyBodyLocalStatementTail sync try/finally body-local source, got {sync_try_finally_body_local_source}"
    )

sync_try_finally_void_source = source_for("syncTryFinallyStatementVoid")
sync_try_finally_void_seq = sync_try_finally_void_source.get("body", {}).get("seq", [])
sync_try_finally_void = sync_try_finally_void_seq[0].get("try_finally", {}) if sync_try_finally_void_seq else {}
sync_try_finally_void_body = sync_try_finally_void.get("body", {})
sync_try_finally_void_finally = sync_try_finally_void.get("finally", {})
if (
    sync_try_finally_void_source.get("params") != ["name"]
    or sync_try_finally_void_source.get("return_type") is not None
    or not sync_try_finally_void_body.get("call_static", "").endswith("::label")
    or sync_try_finally_void_body.get("args") != [{"arg": "name"}]
    or not sync_try_finally_void_finally.get("call_static", "").endswith("::label")
    or sync_try_finally_void_finally.get("args", [{}])[0].get("concat", [{}, {}])[0].get("string")
    != "patched-void-cleanup-"
    or sync_try_finally_void_finally.get("args", [{}])[0].get("concat", [{}, {}])[1].get("arg") != "name"
    or sync_try_finally_void_seq[1].get("null") is not True
):
    raise SystemExit(
        f"expected syncTryFinallyStatementVoid sync try/finally expression statement + implicit null source, got {sync_try_finally_void_source}"
    )

sync_try_finally_return_source = source_for("syncTryFinallyReturnValue")
sync_try_finally_return = sync_try_finally_return_source.get("body", {}).get("try_finally", {})
sync_try_finally_return_body = sync_try_finally_return.get("body", {}).get("concat", [])
sync_try_finally_return_finally = sync_try_finally_return.get("finally", {})
sync_try_finally_return_cleanup = sync_try_finally_return_finally.get("args", [{}])[0].get("concat", [])
if (
    sync_try_finally_return_source.get("params") != ["name"]
    or sync_try_finally_return_source.get("return_type") != "String"
    or sync_try_finally_return.get("value") is not True
    or sync_try_finally_return_body != [{"string": "patched-finally-return-"}, {"arg": "name"}]
    or not sync_try_finally_return_finally.get("call_static", "").endswith("::label")
    or sync_try_finally_return_cleanup != [{"string": "patched-return-cleanup-"}, {"arg": "name"}]
):
    raise SystemExit(
        f"expected syncTryFinallyReturnValue sync try/finally value-preserving source, got {sync_try_finally_return_source}"
    )

sync_if_side_effect_source = source_for("syncIfSideEffectTail")
sync_if_side_effect_seq = sync_if_side_effect_source.get("body", {}).get("seq", [])
sync_if_side_effect_conditional = sync_if_side_effect_seq[0].get("conditional", {}) if sync_if_side_effect_seq else {}
sync_if_side_effect_then = sync_if_side_effect_conditional.get("then", {})
sync_if_side_effect_tail = sync_if_side_effect_seq[1].get("concat", []) if len(sync_if_side_effect_seq) > 1 else []
if (
    sync_if_side_effect_source.get("params") != ["enabled", "name"]
    or sync_if_side_effect_source.get("return_type") != "String"
    or sync_if_side_effect_conditional.get("condition", {}).get("arg") != "enabled"
    or sync_if_side_effect_conditional.get("else", {}).get("null") is not True
    or not sync_if_side_effect_then.get("call_static", "").endswith("::label")
    or sync_if_side_effect_then.get("args", [{}])[0].get("concat", [{}, {}])[0].get("string")
    != "patched-if-side-effect-"
    or sync_if_side_effect_tail != [{"string": "patched-if-tail-"}, {"arg": "name"}]
):
    raise SystemExit(f"expected syncIfSideEffectTail sync if side-effect + tail source, got {sync_if_side_effect_source}")

sync_ifelse_side_effect_source = source_for("syncIfElseSideEffectTail")
sync_ifelse_side_effect_seq = sync_ifelse_side_effect_source.get("body", {}).get("seq", [])
sync_ifelse_side_effect_conditional = (
    sync_ifelse_side_effect_seq[0].get("conditional", {}) if sync_ifelse_side_effect_seq else {}
)
sync_ifelse_side_effect_then = sync_ifelse_side_effect_conditional.get("then", {})
sync_ifelse_side_effect_else = sync_ifelse_side_effect_conditional.get("else", {})
sync_ifelse_side_effect_tail = (
    sync_ifelse_side_effect_seq[1].get("concat", []) if len(sync_ifelse_side_effect_seq) > 1 else []
)
if (
    sync_ifelse_side_effect_source.get("params") != ["enabled", "name"]
    or sync_ifelse_side_effect_source.get("return_type") != "String"
    or sync_ifelse_side_effect_conditional.get("condition", {}).get("arg") != "enabled"
    or not sync_ifelse_side_effect_then.get("call_static", "").endswith("::label")
    or sync_ifelse_side_effect_then.get("args", [{}])[0].get("concat", [{}, {}])[0].get("string")
    != "patched-ifelse-side-effect-on-"
    or not sync_ifelse_side_effect_else.get("call_static", "").endswith("::label")
    or sync_ifelse_side_effect_else.get("args", [{}])[0].get("concat", [{}, {}])[0].get("string")
    != "patched-ifelse-side-effect-off-"
    or sync_ifelse_side_effect_tail != [{"string": "patched-ifelse-tail-"}, {"arg": "name"}]
):
    raise SystemExit(
        f"expected syncIfElseSideEffectTail sync if/else side-effect + tail source, got {sync_ifelse_side_effect_source}"
    )

sync_ifelse_local_source = source_for("syncIfElseLocalSideEffectTail")
sync_ifelse_local_seq = sync_ifelse_local_source.get("body", {}).get("seq", [])
sync_ifelse_local_conditional = sync_ifelse_local_seq[0].get("conditional", {}) if sync_ifelse_local_seq else {}
sync_ifelse_local_then = sync_ifelse_local_conditional.get("then", {}).get("let", {})
sync_ifelse_local_else = sync_ifelse_local_conditional.get("else", {}).get("let", {})
sync_ifelse_local_then_local = sync_ifelse_local_then.get("locals", [{}])[0]
sync_ifelse_local_else_local = sync_ifelse_local_else.get("locals", [{}])[0]
sync_ifelse_local_tail = sync_ifelse_local_seq[1].get("concat", []) if len(sync_ifelse_local_seq) > 1 else []
if (
    sync_ifelse_local_source.get("params") != ["enabled", "name"]
    or sync_ifelse_local_source.get("return_type") != "String"
    or sync_ifelse_local_conditional.get("condition", {}).get("arg") != "enabled"
    or sync_ifelse_local_then_local.get("name") != "message"
    or sync_ifelse_local_then_local.get("value", {}).get("concat", [{}, {}])[0].get("string")
    != "patched-ifelse-local-on-"
    or not sync_ifelse_local_then.get("body", {}).get("call_static", "").endswith("::label")
    or sync_ifelse_local_then.get("body", {}).get("args", [{}])[0].get("let_local") != 0
    or sync_ifelse_local_else_local.get("name") != "message"
    or sync_ifelse_local_else_local.get("value", {}).get("concat", [{}, {}])[0].get("string")
    != "patched-ifelse-local-off-"
    or not sync_ifelse_local_else.get("body", {}).get("call_static", "").endswith("::label")
    or sync_ifelse_local_else.get("body", {}).get("args", [{}])[0].get("let_local") != 0
    or sync_ifelse_local_tail != [{"string": "patched-ifelse-local-tail-"}, {"arg": "name"}]
):
    raise SystemExit(
        f"expected syncIfElseLocalSideEffectTail sync if/else local side-effect + tail source, got {sync_ifelse_local_source}"
    )

update_config_source = source_for("updateConfigLabel")
update_config_seq = update_config_source.get("body", {}).get("seq", [])
update_config_set = update_config_seq[0].get("set_field", {}) if update_config_seq else {}
update_config_get = update_config_seq[1].get("get_field", {}) if len(update_config_seq) > 1 else {}
if (
    update_config_set.get("receiver", {}).get("arg") != "config"
    or update_config_set.get("field") != "label"
    or update_config_set.get("value", {}).get("concat", [{}, {}])[1].get("string") != "-patched"
    or update_config_get.get("receiver", {}).get("arg") != "config"
    or update_config_get.get("field") != "label"
):
    raise SystemExit(f"expected updateConfigLabel set_field/get_field seq source, got {update_config_source}")

async_update_config_source = source_for("asyncUpdateConfigLabel")
async_update_config_arg = async_update_config_source.get("body", {}).get("new_object", {}).get("args", [{}])[0]
async_update_config_seq = async_update_config_arg.get("seq", [])
async_update_config_set = async_update_config_seq[0].get("set_field", {}) if async_update_config_seq else {}
async_update_config_get = async_update_config_seq[1].get("get_field", {}) if len(async_update_config_seq) > 1 else {}
if (
    async_update_config_source.get("async_future") is not True
    or async_update_config_source.get("body", {}).get("new_object", {}).get("type_args") != ["String"]
    or async_update_config_set.get("receiver", {}).get("arg") != "config"
    or async_update_config_set.get("field") != "label"
    or async_update_config_set.get("value", {}).get("concat", [{}, {}])[1].get("string") != "-async-patched"
    or async_update_config_get.get("receiver", {}).get("arg") != "config"
    or async_update_config_get.get("field") != "label"
):
    raise SystemExit(f"expected asyncUpdateConfigLabel async set_field/get_field seq source, got {async_update_config_source}")

async_await_update_source = source_for("asyncAwaitThenUpdateConfigLabel")
async_await_update_arg = async_await_update_source.get("body", {}).get("new_object", {}).get("args", [{}])[0]
async_await_update_let = async_await_update_arg.get("let", {})
async_await_update_locals = async_await_update_let.get("locals", [])
async_await_update_seq = async_await_update_let.get("body", {}).get("seq", [])
async_await_update_set = async_await_update_seq[0].get("set_field", {}) if async_await_update_seq else {}
async_await_update_get = async_await_update_seq[1].get("get_field", {}) if len(async_await_update_seq) > 1 else {}
async_await_update_concat = async_await_update_set.get("value", {}).get("concat", [])
if (
    async_await_update_source.get("async_future") is not True
    or async_await_update_source.get("body", {}).get("new_object", {}).get("type_args") != ["String"]
    or async_await_update_source.get("params") != ["config", "ready"]
    or len(async_await_update_locals) != 1
    or async_await_update_locals[0].get("name") != "label"
    or async_await_update_locals[0].get("value", {}).get("await", {}).get("arg") != "ready"
    or async_await_update_set.get("receiver", {}).get("arg") != "config"
    or async_await_update_set.get("field") != "label"
    or async_await_update_concat != [{"let_local": 0}, {"string": "-await-patched"}]
    or async_await_update_get.get("receiver", {}).get("arg") != "config"
    or async_await_update_get.get("field") != "label"
):
    raise SystemExit(f"expected asyncAwaitThenUpdateConfigLabel await/set_field/get_field source, got {async_await_update_source}")

async_dynamic_named_source = source_for("asyncDynamicNamedCall")
async_dynamic_named_arg = async_dynamic_named_source.get("body", {}).get("new_object", {}).get("args", [{}])[0]
async_dynamic_call = async_dynamic_named_arg.get("call_dynamic", {})
if (
    async_dynamic_named_source.get("async_future") is not True
    or async_dynamic_named_source.get("body", {}).get("new_object", {}).get("type_args") != ["String"]
    or async_dynamic_call.get("receiver", {}).get("new_object", {}).get("constructor", "").endswith("::class:Greeter.") is not True
    or async_dynamic_call.get("method") != "surround"
    or async_dynamic_call.get("args") != [{"string": "patched-async"}]
    or async_dynamic_call.get("named_args") != [
        {"name": "prefix", "value": {"string": "<"}},
        {"name": "suffix", "value": {"string": ">"}},
    ]
):
    raise SystemExit(f"expected asyncDynamicNamedCall async call_dynamic source, got {async_dynamic_named_source}")

async_await_dynamic_source = source_for("asyncAwaitThenDynamicCall")
async_await_dynamic_arg = async_await_dynamic_source.get("body", {}).get("new_object", {}).get("args", [{}])[0]
async_await_dynamic_let = async_await_dynamic_arg.get("let", {})
async_await_dynamic_locals = async_await_dynamic_let.get("locals", [])
async_await_dynamic_call = async_await_dynamic_let.get("body", {}).get("call_dynamic", {})
if (
    async_await_dynamic_source.get("async_future") is not True
    or async_await_dynamic_source.get("body", {}).get("new_object", {}).get("type_args") != ["String"]
    or async_await_dynamic_source.get("params") != ["ready"]
    or len(async_await_dynamic_locals) != 1
    or async_await_dynamic_locals[0].get("name") != "value"
    or async_await_dynamic_locals[0].get("value", {}).get("await", {}).get("arg") != "ready"
    or async_await_dynamic_call.get("receiver", {}).get("new_object", {}).get("constructor", "").endswith("::class:Greeter.") is not True
    or async_await_dynamic_call.get("method") != "surround"
    or async_await_dynamic_call.get("args") != [{"let_local": 0}]
    or async_await_dynamic_call.get("named_args") != [
        {"name": "prefix", "value": {"string": "patched-await-dynamic<"}},
        {"name": "suffix", "value": {"string": ">"}},
    ]
):
    raise SystemExit(f"expected asyncAwaitThenDynamicCall await/call_dynamic source, got {async_await_dynamic_source}")

async_direct_callback_source = source_for("asyncDirectCallbackMixed")
async_direct_callback_arg = async_direct_callback_source.get("body", {}).get("new_object", {}).get("args", [{}])[0]
async_direct_callback_concat = async_direct_callback_arg.get("concat", [])
async_direct_callback_call = async_direct_callback_concat[0].get("call_closure", {}) if async_direct_callback_concat else {}
if (
    async_direct_callback_source.get("async_future") is not True
    or async_direct_callback_source.get("body", {}).get("new_object", {}).get("type_args") != ["String"]
    or async_direct_callback_call.get("closure", {}).get("arg") != "callback"
    or async_direct_callback_call.get("args") != [{"arg": "value"}]
    or async_direct_callback_call.get("named_args") != [{"name": "suffix", "value": {"arg": "suffix"}}]
    or async_direct_callback_concat[1].get("string") != " patched-async-mixed"
):
    raise SystemExit(f"expected asyncDirectCallbackMixed async call_closure source, got {async_direct_callback_source}")

async_await_callback_source = source_for("asyncAwaitThenDirectCallbackMixed")
async_await_callback_arg = async_await_callback_source.get("body", {}).get("new_object", {}).get("args", [{}])[0]
async_await_callback_let = async_await_callback_arg.get("let", {})
async_await_callback_locals = async_await_callback_let.get("locals", [])
async_await_callback_concat = async_await_callback_let.get("body", {}).get("concat", [])
async_await_callback_call = async_await_callback_concat[0].get("call_closure", {}) if async_await_callback_concat else {}
if (
    async_await_callback_source.get("async_future") is not True
    or async_await_callback_source.get("body", {}).get("new_object", {}).get("type_args") != ["String"]
    or async_await_callback_source.get("params") != ["callback", "ready", "suffix"]
    or len(async_await_callback_locals) != 1
    or async_await_callback_locals[0].get("name") != "value"
    or async_await_callback_locals[0].get("value", {}).get("await", {}).get("arg") != "ready"
    or async_await_callback_call.get("closure", {}).get("arg") != "callback"
    or async_await_callback_call.get("args") != [{"let_local": 0}]
    or async_await_callback_call.get("named_args") != [{"name": "suffix", "value": {"arg": "suffix"}}]
    or async_await_callback_concat[1].get("string") != " patched-await-callback"
):
    raise SystemExit(f"expected asyncAwaitThenDirectCallbackMixed await/call_closure source, got {async_await_callback_source}")

async_same_source = source_for("asyncSameObject")
async_same_arg = async_same_source.get("body", {}).get("new_object", {}).get("args", [{}])[0]
if (
    async_same_source.get("async_future") is not True
    or async_same_source.get("body", {}).get("new_object", {}).get("type_args") != ["bool"]
    or async_same_arg.get("call_original") != "dart:core::identical"
    or async_same_arg.get("args") != [{"arg": "value"}, {"arg": "value"}]
):
    raise SystemExit(f"expected asyncSameObject async call_original source, got {async_same_source}")

async_await_same_source = source_for("asyncAwaitThenSameObject")
async_await_same_arg = async_await_same_source.get("body", {}).get("new_object", {}).get("args", [{}])[0]
async_await_same_let = async_await_same_arg.get("let", {})
async_await_same_locals = async_await_same_let.get("locals", [])
async_await_same_call = async_await_same_let.get("body", {}).get("call_original", {})
if (
    async_await_same_source.get("async_future") is not True
    or async_await_same_source.get("body", {}).get("new_object", {}).get("type_args") != ["bool"]
    or async_await_same_source.get("params") != ["ready"]
    or len(async_await_same_locals) != 1
    or async_await_same_locals[0].get("name") != "value"
    or async_await_same_locals[0].get("value", {}).get("await", {}).get("arg") != "ready"
    or async_await_same_call != "dart:core::identical"
    or async_await_same_let.get("body", {}).get("args") != [{"let_local": 0}, {"let_local": 0}]
):
    raise SystemExit(f"expected asyncAwaitThenSameObject await/call_original source, got {async_await_same_source}")

async_static_helper_source = source_for("asyncStaticHelperValue")
async_static_helper_arg = async_static_helper_source.get("body", {}).get("new_object", {}).get("args", [{}])[0]
async_static_helper_call = async_static_helper_arg.get("left", {})
if (
    async_static_helper_source.get("async_future") is not True
    or async_static_helper_source.get("body", {}).get("new_object", {}).get("type_args") != ["double"]
    or async_static_helper_arg.get("op") != "+"
    or async_static_helper_call.get("call_static", "").endswith("::helper") is not True
    or async_static_helper_call.get("args") != []
    or async_static_helper_arg.get("right", {}).get("double") != 3.5
):
    raise SystemExit(f"expected asyncStaticHelperValue async call_static source, got {async_static_helper_source}")

async_await_static_source = source_for("asyncAwaitThenStaticHelperValue")
async_await_static_arg = async_await_static_source.get("body", {}).get("new_object", {}).get("args", [{}])[0]
async_await_static_let = async_await_static_arg.get("let", {})
async_await_static_locals = async_await_static_let.get("locals", [])
async_await_static_op = async_await_static_let.get("body", {})
async_await_static_call = async_await_static_op.get("right", {})
if (
    async_await_static_source.get("async_future") is not True
    or async_await_static_source.get("body", {}).get("new_object", {}).get("type_args") != ["double"]
    or async_await_static_source.get("params") != ["ready"]
    or len(async_await_static_locals) != 1
    or async_await_static_locals[0].get("name") != "value"
    or async_await_static_locals[0].get("value", {}).get("await", {}).get("arg") != "ready"
    or async_await_static_op.get("op") != "+"
    or async_await_static_op.get("left", {}).get("let_local") != 0
    or async_await_static_call.get("call_static", "").endswith("::helper") is not True
    or async_await_static_call.get("args") != []
):
    raise SystemExit(f"expected asyncAwaitThenStaticHelperValue await/call_static source, got {async_await_static_source}")

async_await_static_combine_source = source_for("asyncAwaitThenStaticCombine")
async_await_static_combine_arg = async_await_static_combine_source.get("body", {}).get("new_object", {}).get(
    "args", [{}]
)[0]
async_await_static_combine_let = async_await_static_combine_arg.get("let", {})
async_await_static_combine_locals = async_await_static_combine_let.get("locals", [])
async_await_static_combine_call = async_await_static_combine_let.get("body", {})
if (
    async_await_static_combine_source.get("async_future") is not True
    or async_await_static_combine_source.get("body", {}).get("new_object", {}).get("type_args") != ["int"]
    or async_await_static_combine_source.get("params") != ["ready", "right"]
    or len(async_await_static_combine_locals) != 1
    or async_await_static_combine_locals[0].get("name") != "left"
    or async_await_static_combine_locals[0].get("value", {}).get("await", {}).get("arg") != "ready"
    or async_await_static_combine_call.get("call_static", "").endswith("::combine") is not True
    or async_await_static_combine_call.get("args") != [{"let_local": 0}, {"arg": "right"}]
):
    raise SystemExit(
        "expected asyncAwaitThenStaticCombine await/call_static args source, "
        f"got {async_await_static_combine_source}"
    )

async_concat_source = source_for("asyncConcatLabel")
async_concat_arg = async_concat_source.get("body", {}).get("new_object", {}).get("args", [{}])[0]
async_concat_items = async_concat_arg.get("concat", [])
if (
    async_concat_source.get("async_future") is not True
    or async_concat_source.get("body", {}).get("new_object", {}).get("type_args") != ["String"]
    or len(async_concat_items) != 2
    or async_concat_items[0].get("string") != "patched-async "
    or async_concat_items[1].get("arg") != "name"
):
    raise SystemExit(f"expected asyncConcatLabel async concat source, got {async_concat_source}")

async_await_concat_source = source_for("asyncAwaitThenConcatLabel")
async_await_concat_arg = async_await_concat_source.get("body", {}).get("new_object", {}).get("args", [{}])[0]
async_await_concat_let = async_await_concat_arg.get("let", {})
async_await_concat_locals = async_await_concat_let.get("locals", [])
async_await_concat_items = async_await_concat_let.get("body", {}).get("concat", [])
if (
    async_await_concat_source.get("async_future") is not True
    or async_await_concat_source.get("body", {}).get("new_object", {}).get("type_args") != ["String"]
    or async_await_concat_source.get("params") != ["ready"]
    or len(async_await_concat_locals) != 1
    or async_await_concat_locals[0].get("name") != "value"
    or async_await_concat_locals[0].get("value", {}).get("await", {}).get("arg") != "ready"
    or async_await_concat_items != [
        {"string": "patched-await-concat "},
        {"let_local": 0},
    ]
):
    raise SystemExit(
        "expected asyncAwaitThenConcatLabel await/concat source, "
        f"got {async_await_concat_source}"
    )

async_nullable_source = source_for("asyncNullableChoice")
async_nullable_arg = async_nullable_source.get("body", {}).get("new_object", {}).get("args", [{}])[0]
async_nullable_conditional = async_nullable_arg.get("conditional", {})
if (
    async_nullable_source.get("async_future") is not True
    or async_nullable_source.get("body", {}).get("new_object", {}).get("type_args") != ["Object"]
    or async_nullable_conditional.get("condition", {}).get("arg") != "enabled"
    or async_nullable_conditional.get("then", {}).get("null") is not True
    or async_nullable_conditional.get("else", {}).get("string") != "patched-null"
):
    raise SystemExit(f"expected asyncNullableChoice async null conditional source, got {async_nullable_source}")

async_await_nullable_source = source_for("asyncAwaitThenNullableChoice")
async_await_nullable_arg = async_await_nullable_source.get("body", {}).get("new_object", {}).get("args", [{}])[0]
async_await_nullable_let = async_await_nullable_arg.get("let", {})
async_await_nullable_locals = async_await_nullable_let.get("locals", [])
async_await_nullable_conditional = async_await_nullable_let.get("body", {}).get("conditional", {})
if (
    async_await_nullable_source.get("async_future") is not True
    or async_await_nullable_source.get("body", {}).get("new_object", {}).get("type_args") != ["Object"]
    or async_await_nullable_source.get("params") != ["ready"]
    or len(async_await_nullable_locals) != 1
    or async_await_nullable_locals[0].get("name") != "enabled"
    or async_await_nullable_locals[0].get("value", {}).get("await", {}).get("arg") != "ready"
    or async_await_nullable_conditional.get("condition", {}).get("let_local") != 0
    or async_await_nullable_conditional.get("then", {}).get("null") is not True
    or async_await_nullable_conditional.get("else", {}).get("string") != "patched-await-null"
):
    raise SystemExit(
        "expected asyncAwaitThenNullableChoice await/null conditional source, "
        f"got {async_await_nullable_source}"
    )

async_await_choose_label_source = source_for("asyncAwaitThenChooseLabel")
async_await_choose_label_arg = async_await_choose_label_source.get("body", {}).get("new_object", {}).get("args", [{}])[0]
async_await_choose_label_let = async_await_choose_label_arg.get("let", {})
async_await_choose_label_locals = async_await_choose_label_let.get("locals", [])
async_await_choose_label_conditional = async_await_choose_label_let.get("body", {}).get("conditional", {})
if (
    async_await_choose_label_source.get("async_future") is not True
    or async_await_choose_label_source.get("body", {}).get("new_object", {}).get("type_args") != ["String"]
    or async_await_choose_label_source.get("params") != ["ready"]
    or len(async_await_choose_label_locals) != 1
    or async_await_choose_label_locals[0].get("name") != "enabled"
    or async_await_choose_label_locals[0].get("value", {}).get("await", {}).get("arg") != "ready"
    or async_await_choose_label_conditional.get("condition", {}).get("let_local") != 0
    or async_await_choose_label_conditional.get("then", {}).get("string") != "patched-await-live"
    or async_await_choose_label_conditional.get("else", {}).get("string") != "patched-await-off"
):
    raise SystemExit(
        "expected asyncAwaitThenChooseLabel await/conditional source, "
        f"got {async_await_choose_label_source}"
    )

async_display_source = source_for("asyncDisplayName")
async_display_arg = async_display_source.get("body", {}).get("new_object", {}).get("args", [{}])[0]
async_display_get = async_display_arg.get("get_field", {})
if (
    async_display_source.get("async_future") is not True
    or async_display_source.get("body", {}).get("new_object", {}).get("type_args") != ["String"]
    or async_display_get.get("receiver", {}).get("arg") != "user"
    or async_display_get.get("field") != "label"
):
    raise SystemExit(f"expected asyncDisplayName async get_field source, got {async_display_source}")

async_await_field_source = source_for("asyncAwaitThenReadField")
async_await_field_arg = async_await_field_source.get("body", {}).get("new_object", {}).get("args", [{}])[0]
async_await_field_let = async_await_field_arg.get("let", {})
async_await_field_locals = async_await_field_let.get("locals", [])
async_await_field_concat = async_await_field_let.get("body", {}).get("concat", [])
async_await_field_get = async_await_field_concat[3].get("get_field", {}) if len(async_await_field_concat) > 3 else {}
if (
    async_await_field_source.get("async_future") is not True
    or async_await_field_source.get("body", {}).get("new_object", {}).get("type_args") != ["String"]
    or async_await_field_source.get("params") != ["user", "ready"]
    or len(async_await_field_locals) != 1
    or async_await_field_locals[0].get("name") != "prefix"
    or async_await_field_locals[0].get("value", {}).get("await", {}).get("arg") != "ready"
    or async_await_field_concat[0].get("string") != "patched-await-field:"
    or async_await_field_concat[1].get("let_local") != 0
    or async_await_field_concat[2].get("string") != " "
    or async_await_field_get.get("receiver", {}).get("arg") != "user"
    or async_await_field_get.get("field") != "label"
):
    raise SystemExit(f"expected asyncAwaitThenReadField await/get_field concat source, got {async_await_field_source}")

assert_core_object_sources(source_for)
assert_core_op_sources(source_for)
assert_core_collection_name_sources(source_for)

async_dynamic_labels_source = source_for("asyncDynamicLabels")
async_dynamic_labels_arg = async_dynamic_labels_source.get("body", {}).get("new_object", {}).get("args", [{}])[0]
async_dynamic_labels_add_all = async_dynamic_labels_arg.get("map_add_all", {})
if (
    async_dynamic_labels_source.get("async_future") is not True
    or async_dynamic_labels_source.get("body", {}).get("new_object", {}).get("type_args") != ["Map<String,String>"]
    or async_dynamic_labels_add_all.get("receiver", {}).get("map", [{}])[0].get("key", {}).get("string") != "mode"
    or async_dynamic_labels_add_all.get("receiver", {}).get("map", [{}])[0].get("value", {}).get("string") != "patched-async"
    or async_dynamic_labels_add_all.get("spread", {}).get("arg") != "extra"
):
    raise SystemExit(f"expected asyncDynamicLabels async map_add_all source, got {async_dynamic_labels_source}")

async_await_dynamic_labels_source = source_for("asyncAwaitThenDynamicLabels")
async_await_dynamic_labels_arg = async_await_dynamic_labels_source.get("body", {}).get("new_object", {}).get("args", [{}])[0]
async_await_dynamic_labels_let = async_await_dynamic_labels_arg.get("let", {})
async_await_dynamic_labels_locals = async_await_dynamic_labels_let.get("locals", [])
async_await_dynamic_labels_add_all = async_await_dynamic_labels_let.get("body", {}).get("map_add_all", {})
async_await_dynamic_labels_receiver = async_await_dynamic_labels_add_all.get("receiver", {}).get("map", [])
if (
    async_await_dynamic_labels_source.get("async_future") is not True
    or async_await_dynamic_labels_source.get("body", {}).get("new_object", {}).get("type_args") != ["Map<String,String>"]
    or async_await_dynamic_labels_source.get("params") != ["ready", "extra"]
    or len(async_await_dynamic_labels_locals) != 1
    or async_await_dynamic_labels_locals[0].get("name") != "value"
    or async_await_dynamic_labels_locals[0].get("value", {}).get("await", {}).get("arg") != "ready"
    or async_await_dynamic_labels_receiver
    != [{"key": {"string": "mode"}, "value": {"string": "patched-await-dynamic-map"}}]
    or async_await_dynamic_labels_add_all.get("spread", {}).get("arg") != "extra"
):
    raise SystemExit(
        "expected asyncAwaitThenDynamicLabels await/map_add_all source, "
        f"got {async_await_dynamic_labels_source}"
    )

async_labels_source = source_for("asyncLabels")
async_labels_arg = async_labels_source.get("body", {}).get("new_object", {}).get("args", [{}])[0]
async_labels_premium = async_labels_arg.get("conditional", {})
async_labels_premium_then = async_labels_premium.get("then", {}).get("conditional", {}).get("then", {}).get("map", [])
async_labels_premium_else = async_labels_premium.get("else", {}).get("conditional", {}).get("else", {}).get("map", [])
if (
    async_labels_source.get("async_future") is not True
    or async_labels_source.get("body", {}).get("new_object", {}).get("type_args") != ["Map<String,String>"]
    or async_labels_premium.get("condition", {}).get("arg") != "premium"
    or len(async_labels_premium_then) != 6
    or async_labels_premium_then[0].get("value", {}).get("string") != "patched-async-static"
    or async_labels_premium_then[2].get("key", {}).get("string") != "async-for"
    or async_labels_premium_then[3].get("value", {}).get("string") != "live"
    or async_labels_premium_then[4].get("key", {}).get("string") != "async-tier"
    or len(async_labels_premium_else) != 5
    or async_labels_premium_else[3].get("value", {}).get("string") != "off"
):
    raise SystemExit(f"expected asyncLabels async static map source, got {async_labels_source}")

async_await_labels_source = source_for("asyncAwaitThenLabels")
async_await_labels_arg = async_await_labels_source.get("body", {}).get("new_object", {}).get("args", [{}])[0]
async_await_labels_let = async_await_labels_arg.get("let", {})
async_await_labels_locals = async_await_labels_let.get("locals", [])
async_await_labels_map = async_await_labels_let.get("body", {}).get("map", [])
if (
    async_await_labels_source.get("async_future") is not True
    or async_await_labels_source.get("body", {}).get("new_object", {}).get("type_args") != ["Map<String,String>"]
    or async_await_labels_source.get("params") != ["ready"]
    or len(async_await_labels_locals) != 1
    or async_await_labels_locals[0].get("name") != "value"
    or async_await_labels_locals[0].get("value", {}).get("await", {}).get("arg") != "ready"
    or async_await_labels_map != [
        {"key": {"string": "mode"}, "value": {"string": "patched-await-map"}},
        {"key": {"string": "value"}, "value": {"let_local": 0}},
    ]
):
    raise SystemExit(
        "expected asyncAwaitThenLabels await/static map source, "
        f"got {async_await_labels_source}"
    )

async_await_conditional_labels_source = source_for("asyncAwaitThenConditionalLabels")
async_await_conditional_labels_arg = async_await_conditional_labels_source.get("body", {}).get("new_object", {}).get(
    "args", [{}]
)[0]
async_await_conditional_labels_let = async_await_conditional_labels_arg.get("let", {})
async_await_conditional_labels_locals = async_await_conditional_labels_let.get("locals", [])
async_await_conditional_labels_conditional = async_await_conditional_labels_let.get("body", {}).get("conditional", {})
async_await_conditional_labels_then = async_await_conditional_labels_conditional.get("then", {}).get("map", [])
async_await_conditional_labels_else = async_await_conditional_labels_conditional.get("else", {}).get("map", [])
if (
    async_await_conditional_labels_source.get("async_future") is not True
    or async_await_conditional_labels_source.get("body", {}).get("new_object", {}).get("type_args")
    != ["Map<String,String>"]
    or async_await_conditional_labels_source.get("params") != ["ready"]
    or len(async_await_conditional_labels_locals) != 1
    or async_await_conditional_labels_locals[0].get("name") != "enabled"
    or async_await_conditional_labels_locals[0].get("value", {}).get("await", {}).get("arg") != "ready"
    or async_await_conditional_labels_conditional.get("condition", {}).get("let_local") != 0
    or async_await_conditional_labels_then != [
        {"key": {"string": "mode"}, "value": {"string": "patched-await-if-map"}},
        {"key": {"string": "state"}, "value": {"string": "patched-await-if-live"}},
        {"key": {"string": "tail"}, "value": {"string": "patched-await-if-tail"}},
    ]
    or async_await_conditional_labels_else != [
        {"key": {"string": "mode"}, "value": {"string": "patched-await-if-map"}},
        {"key": {"string": "state"}, "value": {"string": "patched-await-if-off"}},
        {"key": {"string": "tail"}, "value": {"string": "patched-await-if-tail"}},
    ]
):
    raise SystemExit(
        "expected asyncAwaitThenConditionalLabels await/collection-if map source, "
        f"got {async_await_conditional_labels_source}"
    )

async_await_conditional_dynamic_labels_source = source_for("asyncAwaitThenConditionalDynamicLabels")
async_await_conditional_dynamic_labels_arg = async_await_conditional_dynamic_labels_source.get("body", {}).get(
    "new_object", {}
).get("args", [{}])[0]
async_await_conditional_dynamic_labels_let = async_await_conditional_dynamic_labels_arg.get("let", {})
async_await_conditional_dynamic_labels_locals = async_await_conditional_dynamic_labels_let.get("locals", [])
async_await_conditional_dynamic_labels_conditional = async_await_conditional_dynamic_labels_let.get("body", {}).get(
    "conditional", {}
)
async_await_conditional_dynamic_labels_then = async_await_conditional_dynamic_labels_conditional.get("then", {}).get(
    "map_add_all", {}
)
async_await_conditional_dynamic_labels_else = async_await_conditional_dynamic_labels_conditional.get("else", {}).get(
    "map_add_all", {}
)
if (
    async_await_conditional_dynamic_labels_source.get("async_future") is not True
    or async_await_conditional_dynamic_labels_source.get("body", {}).get("new_object", {}).get("type_args")
    != ["Map<String,String>"]
    or async_await_conditional_dynamic_labels_source.get("params") != ["ready", "extra"]
    or len(async_await_conditional_dynamic_labels_locals) != 1
    or async_await_conditional_dynamic_labels_locals[0].get("name") != "enabled"
    or async_await_conditional_dynamic_labels_locals[0].get("value", {}).get("await", {}).get("arg") != "ready"
    or async_await_conditional_dynamic_labels_conditional.get("condition", {}).get("let_local") != 0
    or async_await_conditional_dynamic_labels_then.get("receiver", {}).get("map") != [
        {"key": {"string": "mode"}, "value": {"string": "patched-await-if-dynamic-map"}},
        {"key": {"string": "state"}, "value": {"string": "patched-await-if-dynamic-live"}},
    ]
    or async_await_conditional_dynamic_labels_then.get("spread", {}).get("arg") != "extra"
    or async_await_conditional_dynamic_labels_else.get("receiver", {}).get("map") != [
        {"key": {"string": "mode"}, "value": {"string": "patched-await-if-dynamic-map"}},
        {"key": {"string": "state"}, "value": {"string": "patched-await-if-dynamic-off"}},
    ]
    or async_await_conditional_dynamic_labels_else.get("spread", {}).get("arg") != "extra"
):
    raise SystemExit(
        "expected asyncAwaitThenConditionalDynamicLabels await/collection-if/map_add_all source, "
        f"got {async_await_conditional_dynamic_labels_source}"
    )

async_await_conditional_runtime_labels_source = source_for("asyncAwaitThenConditionalRuntimeLabels")
async_await_conditional_runtime_labels_arg = async_await_conditional_runtime_labels_source.get("body", {}).get(
    "new_object", {}
).get("args", [{}])[0]
async_await_conditional_runtime_labels_let = async_await_conditional_runtime_labels_arg.get("let", {})
async_await_conditional_runtime_labels_locals = async_await_conditional_runtime_labels_let.get("locals", [])
async_await_conditional_runtime_labels_conditional = async_await_conditional_runtime_labels_let.get("body", {}).get(
    "conditional", {}
)
async_await_conditional_runtime_labels_then = async_await_conditional_runtime_labels_conditional.get("then", {}).get(
    "map_for_in", {}
)
async_await_conditional_runtime_labels_else = async_await_conditional_runtime_labels_conditional.get("else", {}).get(
    "map_for_in", {}
)
if (
    async_await_conditional_runtime_labels_source.get("async_future") is not True
    or async_await_conditional_runtime_labels_source.get("body", {}).get("new_object", {}).get("type_args")
    != ["Map<String,String>"]
    or async_await_conditional_runtime_labels_source.get("params") != ["ready", "extra"]
    or len(async_await_conditional_runtime_labels_locals) != 1
    or async_await_conditional_runtime_labels_locals[0].get("name") != "enabled"
    or async_await_conditional_runtime_labels_locals[0].get("value", {}).get("await", {}).get("arg") != "ready"
    or async_await_conditional_runtime_labels_conditional.get("condition", {}).get("let_local") != 0
    or async_await_conditional_runtime_labels_then.get("receiver", {}).get("map") != [
        {"key": {"string": "mode"}, "value": {"string": "patched-await-if-runtime-map"}},
        {"key": {"string": "state"}, "value": {"string": "patched-await-if-runtime-live"}},
    ]
    or async_await_conditional_runtime_labels_then.get("source", {}).get("call_dynamic", {}).get("method")
    != "get:entries"
    or async_await_conditional_runtime_labels_else.get("receiver", {}).get("map") != [
        {"key": {"string": "mode"}, "value": {"string": "patched-await-if-runtime-map"}},
        {"key": {"string": "state"}, "value": {"string": "patched-await-if-runtime-off"}},
    ]
    or async_await_conditional_runtime_labels_else.get("source", {}).get("call_dynamic", {}).get("method")
    != "get:entries"
):
    raise SystemExit(
        "expected asyncAwaitThenConditionalRuntimeLabels await/collection-if/map_for_in source, "
        f"got {async_await_conditional_runtime_labels_source}"
    )

async_await_condition_labels_source = source_for("asyncAwaitConditionLabels")
async_await_condition_labels_arg = async_await_condition_labels_source.get("body", {}).get("new_object", {}).get(
    "args", [{}]
)[0]
async_await_condition_labels_conditional = async_await_condition_labels_arg.get("conditional", {})
async_await_condition_labels_then = async_await_condition_labels_conditional.get("then", {}).get("map", [])
async_await_condition_labels_else = async_await_condition_labels_conditional.get("else", {}).get("map", [])
if (
    async_await_condition_labels_source.get("async_future") is not True
    or async_await_condition_labels_source.get("body", {}).get("new_object", {}).get("type_args")
    != ["Map<String,String>"]
    or async_await_condition_labels_source.get("params") != ["ready"]
    or async_await_condition_labels_conditional.get("condition", {}).get("await", {}).get("arg") != "ready"
    or async_await_condition_labels_then != [
        {"key": {"string": "mode"}, "value": {"string": "patched-await-condition-map"}},
        {"key": {"string": "state"}, "value": {"string": "patched-await-condition-live"}},
    ]
    or async_await_condition_labels_else != [
        {"key": {"string": "mode"}, "value": {"string": "patched-await-condition-map"}},
        {"key": {"string": "state"}, "value": {"string": "patched-await-condition-off"}},
    ]
):
    raise SystemExit(
        "expected asyncAwaitConditionLabels collection-if direct await source, "
        f"got {async_await_condition_labels_source}"
    )

async_await_condition_dynamic_labels_source = source_for("asyncAwaitConditionDynamicLabels")
async_await_condition_dynamic_labels_arg = async_await_condition_dynamic_labels_source.get("body", {}).get(
    "new_object", {}
).get("args", [{}])[0]
async_await_condition_dynamic_labels_conditional = async_await_condition_dynamic_labels_arg.get("conditional", {})
async_await_condition_dynamic_labels_then = async_await_condition_dynamic_labels_conditional.get("then", {}).get(
    "map_add_all", {}
)
async_await_condition_dynamic_labels_else = async_await_condition_dynamic_labels_conditional.get("else", {}).get(
    "map_add_all", {}
)
if (
    async_await_condition_dynamic_labels_source.get("async_future") is not True
    or async_await_condition_dynamic_labels_source.get("body", {}).get("new_object", {}).get("type_args")
    != ["Map<String,String>"]
    or async_await_condition_dynamic_labels_source.get("params") != ["ready", "extra"]
    or async_await_condition_dynamic_labels_conditional.get("condition", {}).get("await", {}).get("arg") != "ready"
    or async_await_condition_dynamic_labels_then.get("receiver", {}).get("map") != [
        {"key": {"string": "mode"}, "value": {"string": "patched-await-condition-dynamic-map"}},
        {"key": {"string": "state"}, "value": {"string": "patched-await-condition-dynamic-live"}},
    ]
    or async_await_condition_dynamic_labels_then.get("spread", {}).get("arg") != "extra"
    or async_await_condition_dynamic_labels_else.get("receiver", {}).get("map") != [
        {"key": {"string": "mode"}, "value": {"string": "patched-await-condition-dynamic-map"}},
        {"key": {"string": "state"}, "value": {"string": "patched-await-condition-dynamic-off"}},
    ]
    or async_await_condition_dynamic_labels_else.get("spread", {}).get("arg") != "extra"
):
    raise SystemExit(
        "expected asyncAwaitConditionDynamicLabels collection-if direct await/map_add_all source, "
        f"got {async_await_condition_dynamic_labels_source}"
    )

async_await_condition_runtime_labels_source = source_for("asyncAwaitConditionRuntimeLabels")
async_await_condition_runtime_labels_arg = async_await_condition_runtime_labels_source.get("body", {}).get(
    "new_object", {}
).get("args", [{}])[0]
async_await_condition_runtime_labels_conditional = async_await_condition_runtime_labels_arg.get("conditional", {})
async_await_condition_runtime_labels_then = async_await_condition_runtime_labels_conditional.get("then", {}).get(
    "map_for_in", {}
)
async_await_condition_runtime_labels_else = async_await_condition_runtime_labels_conditional.get("else", {}).get(
    "map_for_in", {}
)
if (
    async_await_condition_runtime_labels_source.get("async_future") is not True
    or async_await_condition_runtime_labels_source.get("body", {}).get("new_object", {}).get("type_args")
    != ["Map<String,String>"]
    or async_await_condition_runtime_labels_source.get("params") != ["ready", "extra"]
    or async_await_condition_runtime_labels_conditional.get("condition", {}).get("await", {}).get("arg") != "ready"
    or async_await_condition_runtime_labels_then.get("receiver", {}).get("map") != [
        {"key": {"string": "mode"}, "value": {"string": "patched-await-condition-runtime-map"}},
        {"key": {"string": "state"}, "value": {"string": "patched-await-condition-runtime-live"}},
    ]
    or async_await_condition_runtime_labels_then.get("source", {}).get("call_dynamic", {}).get("method")
    != "get:entries"
    or async_await_condition_runtime_labels_else.get("receiver", {}).get("map") != [
        {"key": {"string": "mode"}, "value": {"string": "patched-await-condition-runtime-map"}},
        {"key": {"string": "state"}, "value": {"string": "patched-await-condition-runtime-off"}},
    ]
    or async_await_condition_runtime_labels_else.get("source", {}).get("call_dynamic", {}).get("method")
    != "get:entries"
):
    raise SystemExit(
        "expected asyncAwaitConditionRuntimeLabels collection-if direct await/map_for_in source, "
        f"got {async_await_condition_runtime_labels_source}"
    )

async_runtime_for_names_source = source_for("asyncRuntimeForNames")
async_runtime_for_names_arg = async_runtime_for_names_source.get("body", {}).get("new_object", {}).get("args", [{}])[0]
async_runtime_for_names_for = async_runtime_for_names_arg.get("list_for_in", {})
if (
    async_runtime_for_names_source.get("async_future") is not True
    or async_runtime_for_names_source.get("body", {}).get("new_object", {}).get("type_args") != ["List<String>"]
    or async_runtime_for_names_for.get("receiver", {}).get("list", [{}])[0].get("string") != "patched-async-for"
    or async_runtime_for_names_for.get("source", {}).get("arg") != "extra"
):
    raise SystemExit(f"expected asyncRuntimeForNames async list_for_in source, got {async_runtime_for_names_source}")

async_await_runtime_for_names_source = source_for("asyncAwaitThenRuntimeForNames")
async_await_runtime_for_names_arg = async_await_runtime_for_names_source.get("body", {}).get("new_object", {}).get("args", [{}])[0]
async_await_runtime_for_names_let = async_await_runtime_for_names_arg.get("let", {})
async_await_runtime_for_names_locals = async_await_runtime_for_names_let.get("locals", [])
async_await_runtime_for_names_for = async_await_runtime_for_names_let.get("body", {}).get("list_for_in", {})
if (
    async_await_runtime_for_names_source.get("async_future") is not True
    or async_await_runtime_for_names_source.get("body", {}).get("new_object", {}).get("type_args") != ["List<String>"]
    or async_await_runtime_for_names_source.get("params") != ["ready", "extra"]
    or len(async_await_runtime_for_names_locals) != 1
    or async_await_runtime_for_names_locals[0].get("name") != "value"
    or async_await_runtime_for_names_locals[0].get("value", {}).get("await", {}).get("arg") != "ready"
    or async_await_runtime_for_names_for.get("receiver", {}).get("list", [{}])[0].get("string") != "patched-await-runtime-for"
    or async_await_runtime_for_names_for.get("source", {}).get("arg") != "extra"
):
    raise SystemExit(
        "expected asyncAwaitThenRuntimeForNames await/list_for_in source, "
        f"got {async_await_runtime_for_names_source}"
    )

async_runtime_for_labels_source = source_for("asyncRuntimeForLabels")
async_runtime_for_labels_arg = async_runtime_for_labels_source.get("body", {}).get("new_object", {}).get("args", [{}])[0]
async_runtime_for_labels_for = async_runtime_for_labels_arg.get("map_for_in", {})
if (
    async_runtime_for_labels_source.get("async_future") is not True
    or async_runtime_for_labels_source.get("body", {}).get("new_object", {}).get("type_args") != ["Map<String,String>"]
    or async_runtime_for_labels_for.get("receiver", {}).get("map", [{}])[0].get("key", {}).get("string") != "mode"
    or async_runtime_for_labels_for.get("receiver", {}).get("map", [{}])[0].get("value", {}).get("string") != "patched-async-for"
    or async_runtime_for_labels_for.get("source", {}).get("call_dynamic", {}).get("method") != "get:entries"
    or async_runtime_for_labels_for.get("source", {}).get("call_dynamic", {}).get("receiver", {}).get("arg") != "extra"
):
    raise SystemExit(f"expected asyncRuntimeForLabels async map_for_in source, got {async_runtime_for_labels_source}")

async_await_runtime_for_labels_source = source_for("asyncAwaitThenRuntimeForLabels")
async_await_runtime_for_labels_arg = async_await_runtime_for_labels_source.get("body", {}).get("new_object", {}).get("args", [{}])[0]
async_await_runtime_for_labels_let = async_await_runtime_for_labels_arg.get("let", {})
async_await_runtime_for_labels_locals = async_await_runtime_for_labels_let.get("locals", [])
async_await_runtime_for_labels_for = async_await_runtime_for_labels_let.get("body", {}).get("map_for_in", {})
if (
    async_await_runtime_for_labels_source.get("async_future") is not True
    or async_await_runtime_for_labels_source.get("body", {}).get("new_object", {}).get("type_args") != ["Map<String,String>"]
    or async_await_runtime_for_labels_source.get("params") != ["ready", "extra"]
    or len(async_await_runtime_for_labels_locals) != 1
    or async_await_runtime_for_labels_locals[0].get("name") != "value"
    or async_await_runtime_for_labels_locals[0].get("value", {}).get("await", {}).get("arg") != "ready"
    or async_await_runtime_for_labels_for.get("receiver", {}).get("map", [{}])[0].get("key", {}).get("string") != "mode"
    or async_await_runtime_for_labels_for.get("receiver", {}).get("map", [{}])[0].get("value", {}).get("string") != "patched-await-runtime-for"
    or async_await_runtime_for_labels_for.get("source", {}).get("call_dynamic", {}).get("method") != "get:entries"
    or async_await_runtime_for_labels_for.get("source", {}).get("call_dynamic", {}).get("receiver", {}).get("arg") != "extra"
):
    raise SystemExit(
        "expected asyncAwaitThenRuntimeForLabels await/map_for_in source, "
        f"got {async_await_runtime_for_labels_source}"
    )
