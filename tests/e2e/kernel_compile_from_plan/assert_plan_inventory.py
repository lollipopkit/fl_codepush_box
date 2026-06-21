import json
import sys

release = json.load(open(sys.argv[1]))
patch = json.load(open(sys.argv[2]))
release_by_id = {f["function_id"]: f for f in release["functions"]}
plan = {"unchanged": [], "interpret": [], "reject": []}

for function in patch["functions"]:
    old = release_by_id.get(function["function_id"])
    if old is None:
        continue
    entry = {
        "function_id": function["function_id"],
        "source_location": function.get("source_location"),
    }
    if old["body_hash"] == function["body_hash"]:
        plan["unchanged"].append(entry)
    elif function.get("unsupported_reasons"):
        plan["reject"].append({
            **entry,
            "reject_reason": function["unsupported_reasons"][0],
        })
    else:
        plan["interpret"].append(entry)

if len(plan["interpret"]) != 248:
    raise SystemExit(f"expected 248 interpreted functions, got {len(plan['interpret'])}")
if len(plan["reject"]) != 2:
    raise SystemExit(f"expected two rejected functions, got {plan['reject']}")

patch_by_member = {f.get("member_name"): f for f in patch["functions"]}

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
async_await_local_mutation_arg = async_await_local_mutation.get("body", {}).get("new_object", {}).get("args", [{}])[0]
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

escaping = [
    f for f in patch["functions"]
    if f.get("member_name") == "escapingGreeting"
]
if len(escaping) != 1:
    raise SystemExit(f"expected one escapingGreeting inventory entry, got {escaping}")
escaping_source = escaping[0].get("bytecode_source")
if not isinstance(escaping_source, dict):
    raise SystemExit(f"escaping closure must produce bytecode source: {escaping[0]}")
if escaping[0].get("unsupported_reasons") != []:
    raise SystemExit(f"escaping closure should now be supported, got {escaping[0]}")
if escaping_source.get("body", {}).get("let", {}).get("body", {}).get("make_closure") is None:
    raise SystemExit(f"expected escaping closure make_closure source, got {escaping_source}")
if len(escaping_source.get("extra_functions", [])) != 1:
    raise SystemExit(f"expected escaping closure extra function, got {escaping_source}")

stored_escaping = [
    f for f in patch["functions"]
    if f.get("member_name") == "storedEscapingGreeting"
]
if len(stored_escaping) != 1:
    raise SystemExit(f"expected one storedEscapingGreeting inventory entry, got {stored_escaping}")
stored_escaping_source = stored_escaping[0].get("bytecode_source")
if not isinstance(stored_escaping_source, dict):
    raise SystemExit(f"stored escaping closure must produce bytecode source: {stored_escaping[0]}")
if stored_escaping[0].get("unsupported_reasons") != []:
    raise SystemExit(f"stored escaping closure should now be supported, got {stored_escaping[0]}")
if stored_escaping_source.get("body", {}).get("let", {}).get("body", {}).get("make_closure") is None:
    raise SystemExit(f"expected stored escaping closure make_closure source, got {stored_escaping_source}")
if len(stored_escaping_source.get("extra_functions", [])) != 1:
    raise SystemExit(f"expected stored escaping closure extra function, got {stored_escaping_source}")

personalized_escaping = [
    f for f in patch["functions"]
    if f.get("member_name") == "personalizedEscapingGreeting"
]
if len(personalized_escaping) != 1:
    raise SystemExit(f"expected one personalizedEscapingGreeting inventory entry, got {personalized_escaping}")
personalized_escaping_source = personalized_escaping[0].get("bytecode_source")
if not isinstance(personalized_escaping_source, dict):
    raise SystemExit(f"personalized escaping closure must produce bytecode source: {personalized_escaping[0]}")
if personalized_escaping[0].get("unsupported_reasons") != []:
    raise SystemExit(f"personalized escaping closure should now be supported, got {personalized_escaping[0]}")
if personalized_escaping_source.get("body", {}).get("let", {}).get("body", {}).get("make_closure") is None:
    raise SystemExit(f"expected personalized escaping closure make_closure source, got {personalized_escaping_source}")
extra_functions = personalized_escaping_source.get("extra_functions", [])
if len(extra_functions) != 1 or extra_functions[0].get("params") != ["prefix", "name", "suffix"]:
    raise SystemExit(f"expected personalized escaping closure params, got {personalized_escaping_source}")

named_escaping = [
    f for f in patch["functions"]
    if f.get("member_name") == "namedEscapingGreeting"
]
if len(named_escaping) != 1:
    raise SystemExit(f"expected one namedEscapingGreeting inventory entry, got {named_escaping}")
named_escaping_source = named_escaping[0].get("bytecode_source")
if not isinstance(named_escaping_source, dict):
    raise SystemExit(f"named escaping closure must produce bytecode source: {named_escaping[0]}")
if named_escaping[0].get("unsupported_reasons") != []:
    raise SystemExit(f"named escaping closure should now be supported, got {named_escaping[0]}")
if named_escaping_source.get("body", {}).get("let", {}).get("body", {}).get("make_closure") is None:
    raise SystemExit(f"expected named escaping closure make_closure source, got {named_escaping_source}")
extra_functions = named_escaping_source.get("extra_functions", [])
if len(extra_functions) != 1 or extra_functions[0].get("params") != ["prefix", "name", "suffix"]:
    raise SystemExit(f"expected named escaping closure params, got {named_escaping_source}")
make_closure = named_escaping_source.get("body", {}).get("let", {}).get("body", {}).get("make_closure", {})
if make_closure.get("named_parameters") != ["suffix"]:
    raise SystemExit(f"expected required named escaping closure metadata, got {named_escaping_source}")

optional_positional_escaping = [
    f for f in patch["functions"]
    if f.get("member_name") == "optionalPositionalEscapingGreeting"
]
if len(optional_positional_escaping) != 1:
    raise SystemExit(f"expected one optionalPositionalEscapingGreeting inventory entry, got {optional_positional_escaping}")
optional_positional_source = optional_positional_escaping[0].get("bytecode_source")
if not isinstance(optional_positional_source, dict):
    raise SystemExit(f"optional positional escaping closure must produce bytecode source: {optional_positional_escaping[0]}")
if optional_positional_escaping[0].get("unsupported_reasons") != []:
    raise SystemExit(f"optional positional escaping closure should now be supported, got {optional_positional_escaping[0]}")
make_closure = optional_positional_source.get("body", {}).get("let", {}).get("body", {}).get("make_closure", {})
if make_closure.get("optional_positional_count") != 1:
    raise SystemExit(f"expected optional positional escaping closure metadata, got {optional_positional_source}")
extra_functions = optional_positional_source.get("extra_functions", [])
if len(extra_functions) != 1 or extra_functions[0].get("params") != ["prefix", "name", "suffix"]:
    raise SystemExit(f"expected optional positional escaping closure params, got {optional_positional_source}")

optional_named_escaping = [
    f for f in patch["functions"]
    if f.get("member_name") == "optionalNamedEscapingGreeting"
]
if len(optional_named_escaping) != 1:
    raise SystemExit(f"expected one optionalNamedEscapingGreeting inventory entry, got {optional_named_escaping}")
optional_named_source = optional_named_escaping[0].get("bytecode_source")
if not isinstance(optional_named_source, dict):
    raise SystemExit(f"optional named escaping closure must produce bytecode source: {optional_named_escaping[0]}")
if optional_named_escaping[0].get("unsupported_reasons") != []:
    raise SystemExit(f"optional named escaping closure should now be supported, got {optional_named_escaping[0]}")
make_closure = optional_named_source.get("body", {}).get("let", {}).get("body", {}).get("make_closure", {})
if make_closure.get("named_parameters") != ["?suffix"]:
    raise SystemExit(f"expected optional named escaping closure metadata, got {optional_named_source}")
extra_functions = optional_named_source.get("extra_functions", [])
if len(extra_functions) != 1 or extra_functions[0].get("params") != ["prefix", "name", "suffix"]:
    raise SystemExit(f"expected optional named escaping closure params, got {optional_named_source}")

generic_escaping = [
    f for f in patch["functions"]
    if f.get("member_name") == "genericEscapingGreeting"
]
if len(generic_escaping) != 1:
    raise SystemExit(f"expected one genericEscapingGreeting inventory entry, got {generic_escaping}")
generic_source = generic_escaping[0].get("bytecode_source")
if not isinstance(generic_source, dict):
    raise SystemExit(f"generic escaping closure must produce bytecode source: {generic_escaping[0]}")
if generic_escaping[0].get("unsupported_reasons") != []:
    raise SystemExit(f"generic escaping closure should now be supported, got {generic_escaping[0]}")
make_closure = generic_source.get("body", {}).get("let", {}).get("body", {}).get("make_closure", {})
if make_closure.get("type_parameter_count") != 1:
    raise SystemExit(f"expected generic escaping closure type metadata, got {generic_source}")
extra_functions = generic_source.get("extra_functions", [])
if len(extra_functions) != 1 or extra_functions[0].get("params") != ["prefix", "name", "value"]:
    raise SystemExit(f"expected generic escaping closure params, got {generic_source}")

local_function_escaping = [
    f for f in patch["functions"]
    if f.get("member_name") == "localFunctionEscapingGreeting"
]
if len(local_function_escaping) != 1:
    raise SystemExit(f"expected one localFunctionEscapingGreeting inventory entry, got {local_function_escaping}")
local_function_source = local_function_escaping[0].get("bytecode_source")
if not isinstance(local_function_source, dict):
    raise SystemExit(f"local function escaping closure must produce bytecode source: {local_function_escaping[0]}")
if local_function_escaping[0].get("unsupported_reasons") != []:
    raise SystemExit(f"local function escaping closure should now be supported, got {local_function_escaping[0]}")
if local_function_source.get("body", {}).get("let", {}).get("body", {}).get("make_closure") is None:
    raise SystemExit(f"expected local function escaping closure make_closure source, got {local_function_source}")
extra_functions = local_function_source.get("extra_functions", [])
if len(extra_functions) != 1 or extra_functions[0].get("params") != ["prefix", "name"]:
    raise SystemExit(f"expected local function escaping closure params, got {local_function_source}")

body_local_escaping = [
    f for f in patch["functions"]
    if f.get("member_name") == "bodyLocalEscapingGreeting"
]
if len(body_local_escaping) != 1:
    raise SystemExit(f"expected one bodyLocalEscapingGreeting inventory entry, got {body_local_escaping}")
body_local_source = body_local_escaping[0].get("bytecode_source")
if not isinstance(body_local_source, dict):
    raise SystemExit(f"body-local escaping closure must produce bytecode source: {body_local_escaping[0]}")
if body_local_escaping[0].get("unsupported_reasons") != []:
    raise SystemExit(f"body-local escaping closure should now be supported, got {body_local_escaping[0]}")
if body_local_source.get("body", {}).get("let", {}).get("body", {}).get("make_closure") is None:
    raise SystemExit(f"expected body-local escaping closure make_closure source, got {body_local_source}")
extra_functions = body_local_source.get("extra_functions", [])
if len(extra_functions) != 1 or extra_functions[0].get("params") != ["prefix", "name"]:
    raise SystemExit(f"expected body-local escaping closure params, got {body_local_source}")
if extra_functions[0].get("body", {}).get("let", {}).get("locals") is None:
    raise SystemExit(f"expected body-local escaping closure body let, got {body_local_source}")

try_catch_escaping = [
    f for f in patch["functions"]
    if f.get("member_name") == "tryCatchEscapingGreeting"
]
if len(try_catch_escaping) != 1:
    raise SystemExit(f"expected one tryCatchEscapingGreeting inventory entry, got {try_catch_escaping}")
try_catch_source = try_catch_escaping[0].get("bytecode_source")
if not isinstance(try_catch_source, dict):
    raise SystemExit(f"try/catch escaping closure must produce bytecode source: {try_catch_escaping[0]}")
if try_catch_escaping[0].get("unsupported_reasons") != []:
    raise SystemExit(f"try/catch escaping closure should now be supported, got {try_catch_escaping[0]}")
if try_catch_source.get("body", {}).get("let", {}).get("body", {}).get("make_closure") is None:
    raise SystemExit(f"expected try/catch escaping closure make_closure source, got {try_catch_source}")
extra_functions = try_catch_source.get("extra_functions", [])
if len(extra_functions) != 1 or extra_functions[0].get("params") != ["prefix", "fail"]:
    raise SystemExit(f"expected try/catch escaping closure params, got {try_catch_source}")
if extra_functions[0].get("body", {}).get("try_catch") is None:
    raise SystemExit(f"expected try/catch escaping closure body try_catch, got {try_catch_source}")

dynamic_call_escaping = [
    f for f in patch["functions"]
    if f.get("member_name") == "dynamicCallEscapingGreeting"
]
if len(dynamic_call_escaping) != 1:
    raise SystemExit(f"expected one dynamicCallEscapingGreeting inventory entry, got {dynamic_call_escaping}")
dynamic_call_source = dynamic_call_escaping[0].get("bytecode_source")
if not isinstance(dynamic_call_source, dict):
    raise SystemExit(f"dynamic-call escaping closure must produce bytecode source: {dynamic_call_escaping[0]}")
if dynamic_call_escaping[0].get("unsupported_reasons") != []:
    raise SystemExit(f"dynamic-call escaping closure should now be supported, got {dynamic_call_escaping[0]}")
if dynamic_call_source.get("body", {}).get("let", {}).get("body", {}).get("make_closure") is None:
    raise SystemExit(f"expected dynamic-call escaping closure make_closure source, got {dynamic_call_source}")
extra_functions = dynamic_call_source.get("extra_functions", [])
if len(extra_functions) != 1 or extra_functions[0].get("params") != ["greeter", "name", "suffix"]:
    raise SystemExit(f"expected dynamic-call escaping closure params, got {dynamic_call_source}")
if extra_functions[0].get("body", {}).get("call_dynamic") is None:
    raise SystemExit(f"expected dynamic-call escaping closure body call_dynamic, got {dynamic_call_source}")

logical_escaping = [
    f for f in patch["functions"]
    if f.get("member_name") == "logicalEscapingGreeting"
]
if len(logical_escaping) != 1:
    raise SystemExit(f"expected one logicalEscapingGreeting inventory entry, got {logical_escaping}")
logical_source = logical_escaping[0].get("bytecode_source")
if not isinstance(logical_source, dict):
    raise SystemExit(f"logical escaping closure must produce bytecode source: {logical_escaping[0]}")
if logical_escaping[0].get("unsupported_reasons") != []:
    raise SystemExit(f"logical escaping closure should now be supported, got {logical_escaping[0]}")
if logical_source.get("body", {}).get("let", {}).get("body", {}).get("make_closure") is None:
    raise SystemExit(f"expected logical escaping closure make_closure source, got {logical_source}")
extra_functions = logical_source.get("extra_functions", [])
if len(extra_functions) != 1 or extra_functions[0].get("params") != ["name", "prefix", "enabled", "premium"]:
    raise SystemExit(f"expected logical escaping closure params, got {logical_source}")
if extra_functions[0].get("body", {}).get("conditional") is None:
    raise SystemExit(f"expected logical escaping closure body conditional, got {logical_source}")

if_else_escaping = [
    f for f in patch["functions"]
    if f.get("member_name") == "ifElseEscapingGreeting"
]
if len(if_else_escaping) != 1:
    raise SystemExit(f"expected one ifElseEscapingGreeting inventory entry, got {if_else_escaping}")
if_else_source = if_else_escaping[0].get("bytecode_source")
if not isinstance(if_else_source, dict):
    raise SystemExit(f"if/else escaping closure must produce bytecode source: {if_else_escaping[0]}")
if if_else_escaping[0].get("unsupported_reasons") != []:
    raise SystemExit(f"if/else escaping closure should now be supported, got {if_else_escaping[0]}")
if if_else_source.get("body", {}).get("let", {}).get("body", {}).get("make_closure") is None:
    raise SystemExit(f"expected if/else escaping closure make_closure source, got {if_else_source}")
extra_functions = if_else_source.get("extra_functions", [])
if len(extra_functions) != 1 or extra_functions[0].get("params") != ["prefix", "name", "enabled"]:
    raise SystemExit(f"expected if/else escaping closure params, got {if_else_source}")
if extra_functions[0].get("body", {}).get("conditional") is None:
    raise SystemExit(f"expected if/else escaping closure body conditional, got {if_else_source}")

body_local_if_else_escaping = [
    f for f in patch["functions"]
    if f.get("member_name") == "bodyLocalIfElseEscapingGreeting"
]
if len(body_local_if_else_escaping) != 1:
    raise SystemExit(f"expected one bodyLocalIfElseEscapingGreeting inventory entry, got {body_local_if_else_escaping}")
body_local_if_else_source = body_local_if_else_escaping[0].get("bytecode_source")
if not isinstance(body_local_if_else_source, dict):
    raise SystemExit(f"body-local if/else escaping closure must produce bytecode source: {body_local_if_else_escaping[0]}")
if body_local_if_else_escaping[0].get("unsupported_reasons") != []:
    raise SystemExit(f"body-local if/else escaping closure should now be supported, got {body_local_if_else_escaping[0]}")
if body_local_if_else_source.get("body", {}).get("let", {}).get("body", {}).get("make_closure") is None:
    raise SystemExit(f"expected body-local if/else escaping closure make_closure source, got {body_local_if_else_source}")
extra_functions = body_local_if_else_source.get("extra_functions", [])
if len(extra_functions) != 1 or extra_functions[0].get("params") != ["prefix", "name", "enabled"]:
    raise SystemExit(f"expected body-local if/else escaping closure params, got {body_local_if_else_source}")
closure_body = extra_functions[0].get("body", {})
if closure_body.get("let", {}).get("body", {}).get("conditional") is None:
    raise SystemExit(f"expected body-local if/else escaping closure body let+conditional, got {body_local_if_else_source}")

branch_local_if_else_escaping = [
    f for f in patch["functions"]
    if f.get("member_name") == "branchLocalIfElseEscapingGreeting"
]
if len(branch_local_if_else_escaping) != 1:
    raise SystemExit(f"expected one branchLocalIfElseEscapingGreeting inventory entry, got {branch_local_if_else_escaping}")
branch_local_if_else_source = branch_local_if_else_escaping[0].get("bytecode_source")
if not isinstance(branch_local_if_else_source, dict):
    raise SystemExit(f"branch-local if/else escaping closure must produce bytecode source: {branch_local_if_else_escaping[0]}")
if branch_local_if_else_escaping[0].get("unsupported_reasons") != []:
    raise SystemExit(f"branch-local if/else escaping closure should now be supported, got {branch_local_if_else_escaping[0]}")
if branch_local_if_else_source.get("body", {}).get("let", {}).get("body", {}).get("make_closure") is None:
    raise SystemExit(f"expected branch-local if/else escaping closure make_closure source, got {branch_local_if_else_source}")
extra_functions = branch_local_if_else_source.get("extra_functions", [])
if len(extra_functions) != 1 or extra_functions[0].get("params") != ["prefix", "name", "enabled"]:
    raise SystemExit(f"expected branch-local if/else escaping closure params, got {branch_local_if_else_source}")
conditional = extra_functions[0].get("body", {}).get("conditional", {})
if conditional.get("then", {}).get("let") is None or conditional.get("else", {}).get("let") is None:
    raise SystemExit(f"expected branch-local if/else escaping closure branch lets, got {branch_local_if_else_source}")

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
direct_callback_named_call = direct_callback_named_concat[0].get("call_closure", {}) if direct_callback_named_concat else {}
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
direct_callback_mixed_call = direct_callback_mixed_concat[0].get("call_closure", {}) if direct_callback_mixed_concat else {}
if (
    direct_callback_mixed.get("unsupported_reasons") != []
    or direct_callback_mixed_call.get("closure", {}).get("arg") != "callback"
    or direct_callback_mixed_call.get("args") != [{"arg": "value"}]
    or direct_callback_mixed_call.get("named_args") != [{"name": "suffix", "value": {"arg": "suffix"}}]
    or direct_callback_mixed_concat[1].get("string") != " patched-mixed"
):
    raise SystemExit(f"expected directCallbackMixed mixed call_closure source, got {direct_callback_mixed_source}")

main_function = patch_by_member.get("main")
if main_function is None:
    raise SystemExit("missing inventory entry for main")
main_source = main_function.get("bytecode_source")
if not isinstance(main_source, dict):
    raise SystemExit(f"main should produce bytecode source: {main_function}")
main_seq = main_source.get("body", {}).get("seq", [])
if (
    main_function.get("unsupported_reasons") != []
    or len(main_seq) != 3
    or not main_seq[0].get("call_static", "").endswith("::mainValue")
    or not main_seq[1].get("call_static", "").endswith("::helper")
    or main_seq[2].get("null") is not True
):
    raise SystemExit(f"expected main sync expression statement sequence source, got {main_source}")

expected_rejects = {
    "isCallable": "function_type_unsupported",
    "isRecord": "record_type_unsupported",
}

expected_unchanged_async_rejects = {
    "asyncFutureCallbackTypeArg": "async_await_unsupported",
    "asyncFutureRecordTypeArg": "async_await_unsupported",
}

def contains_key(value, key):
    if isinstance(value, dict):
        return key in value or any(contains_key(item, key) for item in value.values())
    if isinstance(value, list):
        return any(contains_key(item, key) for item in value)
    return False

for function in patch["functions"]:
    source = function.get("bytecode_source")
    if source is not None and contains_key(source, "_uses_continue"):
        raise SystemExit(f"internal generator metadata leaked into bytecode_source: {function}")

plan_rejects = {item["function_id"]: item["reject_reason"] for item in plan["reject"]}
plan_reject_members = {
    function.get("member_name")
    for function in patch["functions"]
    if function.get("function_id") in plan_rejects
}
if plan_reject_members != set(expected_rejects):
    raise SystemExit(f"expected only {set(expected_rejects)} rejects, got {plan_reject_members}: {plan['reject']}")
for member, reason in expected_rejects.items():
    function = patch_by_member.get(member)
    if function is None:
        raise SystemExit(f"missing inventory entry for {member}")
    if function.get("bytecode_source") is not None:
        raise SystemExit(f"{member} must not produce bytecode source: {function}")
    if function.get("unsupported_reasons") != [reason]:
        raise SystemExit(f"expected {member} reason {reason}, got {function}")
    if plan_rejects.get(function["function_id"]) != reason:
        raise SystemExit(f"expected plan reject {member}={reason}, got {plan['reject']}")

for member, reason in expected_unchanged_async_rejects.items():
    function = patch_by_member.get(member)
    if function is None:
        raise SystemExit(f"missing inventory entry for {member}")
    if function.get("bytecode_source") is not None:
        raise SystemExit(f"{member} must not produce bytecode source: {function}")
    if function.get("unsupported_reasons") != [reason]:
        raise SystemExit(f"expected {member} reason {reason}, got {function}")
    if function["function_id"] in plan_rejects:
        raise SystemExit(f"{member} is unchanged and must not enter plan rejects: {plan['reject']}")

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
awaited_local_outer_let = awaited_local.get("body", {}).get("new_object", {}).get("args", [{}])[0].get("try_catch", {}).get("body", {}).get("let", {})
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
awaited_statement_local_seq = awaited_statement_local.get("body", {}).get("new_object", {}).get("args", [{}])[0].get("seq", [])
awaited_statement_local_let = awaited_statement_local_seq[1].get("let", {}) if len(awaited_statement_local_seq) > 1 else {}
if (
    len(awaited_statement_local_seq) != 2
    or awaited_statement_local_seq[0].get("await", {}).get("arg") != "ready"
    or awaited_statement_local_let.get("locals", [{}])[0].get("name") != "marker"
    or awaited_statement_local_let.get("body", {}).get("let_local") != 0
):
    raise SystemExit(f"expected awaitedStatementLocal await statement + local source, got {awaited_statement_local}")
awaited_try_statement_local = patch_by_member.get("awaitedTryStatementLocal", {}).get("bytecode_source", {})
awaited_try = awaited_try_statement_local.get("body", {}).get("new_object", {}).get("args", [{}])[0].get("try_catch", {})
awaited_try_seq = awaited_try.get("body", {}).get("seq", [])
awaited_try_let = awaited_try_seq[1].get("let", {}) if len(awaited_try_seq) > 1 else {}
if (
    len(awaited_try_seq) != 2
    or awaited_try_seq[0].get("await", {}).get("arg") != "ready"
    or awaited_try_let.get("locals", [{}])[0].get("name") != "marker"
    or awaited_try.get("catch", {}).get("concat") is None
):
    raise SystemExit(f"expected awaitedTryStatementLocal try/catch await statement + local source, got {awaited_try_statement_local}")
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
awaited_catch_await_try = awaited_catch_await.get("body", {}).get("new_object", {}).get("args", [{}])[0].get("try_catch", {})
if (
    awaited_catch_await_try.get("body", {}).get("seq", [])[0].get("await", {}).get("arg") != "ready"
    or awaited_catch_await_try.get("catch", {}).get("concat", [{}, {}])[1].get("let_local") != 0
):
    raise SystemExit(f"expected awaitedCatchAwait catch await source, got {awaited_catch_await}")
awaited_finally_local = patch_by_member.get("awaitedFinallyLocal", {}).get("bytecode_source", {})
awaited_finally = awaited_finally_local.get("body", {}).get("new_object", {}).get("args", [{}])[0].get("try_finally", {})
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
awaited_cleanup_try = awaited_finally_cleanup.get("body", {}).get("new_object", {}).get("args", [{}])[0].get("try_finally", {})
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
sync_generated = patch_by_member.get("syncGenerated", {}).get("bytecode_source", {})
if sync_generated.get("async_kind") != "sync_star":
    raise SystemExit(f"expected syncGenerated sync_star source, got {sync_generated}")
if sync_generated.get("body", {}).get("yield", {}).get("string") != "patched-iterable":
    raise SystemExit(f"expected syncGenerated yield source, got {sync_generated}")
async_generated = patch_by_member.get("asyncGenerated", {}).get("bytecode_source", {})
if async_generated.get("async_kind") != "async_star":
    raise SystemExit(f"expected asyncGenerated async_star source, got {async_generated}")
if async_generated.get("body", {}).get("yield", {}).get("string") != "patched-stream":
    raise SystemExit(f"expected asyncGenerated yield source, got {async_generated}")
async_generated_await = patch_by_member.get("asyncGeneratedAwait", {}).get("bytecode_source", {})
async_generated_await_body = async_generated_await.get("body", {}).get("let", {})
async_generated_await_value = async_generated_await_body.get("locals", [{}])[0].get("value", {})
async_generated_await_yield = async_generated_await_body.get("body", {}).get("yield", {})
if (
    async_generated_await.get("async_kind") != "async_star"
    or async_generated_await_value.get("await", {}).get("arg") != "ready"
    or async_generated_await_yield.get("concat") is None
):
    raise SystemExit(f"expected asyncGeneratedAwait async* await local source, got {async_generated_await}")
async_generated_try_finally = patch_by_member.get("asyncGeneratedTryFinally", {}).get("bytecode_source", {})
async_try_finally = async_generated_try_finally.get("body", {}).get("try_finally", {})
async_try_finally_body = async_try_finally.get("body", {}).get("yield", {})
async_try_finally_finalizer = async_try_finally.get("finally", {}).get("let", {})
if (
    async_generated_try_finally.get("async_kind") != "async_star"
    or async_try_finally_body.get("await", {}).get("arg") != "ready"
    or async_try_finally_finalizer.get("locals", [{}])[0].get("name") != "cleanup"
):
    raise SystemExit(f"expected asyncGeneratedTryFinally try_finally source, got {async_generated_try_finally}")
async_generated_finally_yield = patch_by_member.get("asyncGeneratedFinallyYield", {}).get("bytecode_source", {})
async_finally_yield = async_generated_finally_yield.get("body", {}).get("try_finally", {})
async_finally_yield_body = async_finally_yield.get("body", {}).get("yield", {})
async_finally_yield_finalizer = async_finally_yield.get("finally", {}).get("yield", {})
if (
    async_generated_finally_yield.get("async_kind") != "async_star"
    or async_finally_yield_body.get("await", {}).get("arg") != "ready"
    or async_finally_yield_finalizer.get("string") != "patched-stream-finally-yield-cleanup"
):
    raise SystemExit(f"expected asyncGeneratedFinallyYield try_finally yield source, got {async_generated_finally_yield}")
async_generated_catch_await = patch_by_member.get("asyncGeneratedCatchAwait", {}).get("bytecode_source", {})
async_catch_await = async_generated_catch_await.get("body", {}).get("try_catch", {})
async_catch_await_body = async_catch_await.get("body", {}).get("yield", {})
async_catch_await_catch = async_catch_await.get("catch", {}).get("yield", {})
if (
    async_generated_catch_await.get("async_kind") != "async_star"
    or async_catch_await.get("catch_local") != 0
    or async_catch_await_body.get("await", {}).get("arg") != "ready"
    or async_catch_await_catch.get("concat", [{}, {}])[1].get("let_local") != 0
):
    raise SystemExit(f"expected asyncGeneratedCatchAwait try_catch await source, got {async_generated_catch_await}")
sync_generated_many = patch_by_member.get("syncGeneratedMany", {}).get("bytecode_source", {})
sync_many_body = sync_generated_many.get("body", {}).get("let", {}).get("body", {}).get("seq", [])
if (
    sync_generated_many.get("async_kind") != "sync_star"
    or len(sync_many_body) != 3
    or sync_many_body[1].get("conditional") is None
):
    raise SystemExit(f"expected syncGeneratedMany let + seq + conditional yield source, got {sync_generated_many}")
async_generated_many = patch_by_member.get("asyncGeneratedMany", {}).get("bytecode_source", {})
async_many_body = async_generated_many.get("body", {}).get("let", {}).get("body", {}).get("seq", [])
if (
    async_generated_many.get("async_kind") != "async_star"
    or len(async_many_body) != 3
    or async_many_body[1].get("conditional") is None
):
    raise SystemExit(f"expected asyncGeneratedMany let + seq + conditional yield source, got {async_generated_many}")
sync_generated_while = patch_by_member.get("syncGeneratedWhile", {}).get("bytecode_source", {})
sync_while_let = sync_generated_while.get("body", {}).get("let", {})
sync_while = sync_while_let.get("body", {}).get("while_loop", {})
sync_while_body = sync_while.get("body", {}).get("seq", [])
if (
    sync_generated_while.get("async_kind") != "sync_star"
    or sync_while_let.get("locals", [{}])[0].get("name") != "i"
    or sync_while_let.get("locals", [{}])[0].get("value", {}).get("int") != 0
    or sync_while.get("condition", {}).get("op") != ">"
    or len(sync_while_body) != 2
    or sync_while_body[0].get("yield", {}).get("concat") is None
    or sync_while_body[1].get("set_local", {}).get("id") != 0
    or sync_while_body[1].get("set_local", {}).get("value", {}).get("op") != "+"
):
    raise SystemExit(f"expected syncGeneratedWhile let + while_loop source, got {sync_generated_while}")
async_generated_while = patch_by_member.get("asyncGeneratedWhile", {}).get("bytecode_source", {})
async_while_let = async_generated_while.get("body", {}).get("let", {})
async_while = async_while_let.get("body", {}).get("while_loop", {})
async_while_body = async_while.get("body", {}).get("seq", [])
if (
    async_generated_while.get("async_kind") != "async_star"
    or async_while_let.get("locals", [{}])[0].get("name") != "i"
    or async_while_let.get("locals", [{}])[0].get("value", {}).get("int") != 0
    or async_while.get("condition", {}).get("op") != ">"
    or len(async_while_body) != 2
    or async_while_body[0].get("yield", {}).get("concat") is None
    or async_while_body[1].get("set_local", {}).get("id") != 0
    or async_while_body[1].get("set_local", {}).get("value", {}).get("op") != "+"
):
    raise SystemExit(f"expected asyncGeneratedWhile let + while_loop source, got {async_generated_while}")
sync_generated_while_break = patch_by_member.get("syncGeneratedWhileBreak", {}).get("bytecode_source", {})
sync_while_break_let = sync_generated_while_break.get("body", {}).get("let", {})
sync_while_break = sync_while_break_let.get("body", {}).get("while_loop", {})
sync_while_break_body = sync_while_break.get("body", {}).get("seq", [])
if (
    sync_generated_while_break.get("async_kind") != "sync_star"
    or sync_while_break_let.get("locals", [{}])[0].get("name") != "i"
    or sync_while_break.get("condition", {}).get("op") != ">"
    or sync_while_break.get("before_break", {}).get("yield", {}).get("concat") is None
    or sync_while_break.get("break_condition", {}).get("op") != "=="
    or len(sync_while_break_body) != 2
    or sync_while_break_body[0].get("yield", {}).get("concat") is None
    or sync_while_break_body[1].get("set_local", {}).get("id") != 0
):
    raise SystemExit(f"expected syncGeneratedWhileBreak guarded while break source, got {sync_generated_while_break}")
async_generated_while_break = patch_by_member.get("asyncGeneratedWhileBreak", {}).get("bytecode_source", {})
async_while_break_let = async_generated_while_break.get("body", {}).get("let", {})
async_while_break = async_while_break_let.get("body", {}).get("while_loop", {})
async_while_break_body = async_while_break.get("body", {}).get("seq", [])
if (
    async_generated_while_break.get("async_kind") != "async_star"
    or async_while_break_let.get("locals", [{}])[0].get("name") != "i"
    or async_while_break.get("condition", {}).get("op") != ">"
    or async_while_break.get("before_break", {}).get("yield", {}).get("concat") is None
    or async_while_break.get("break_condition", {}).get("op") != "=="
    or len(async_while_break_body) != 2
    or async_while_break_body[0].get("yield", {}).get("concat") is None
    or async_while_break_body[1].get("set_local", {}).get("id") != 0
):
    raise SystemExit(f"expected asyncGeneratedWhileBreak guarded while break source, got {async_generated_while_break}")
sync_generated_while_continue = patch_by_member.get("syncGeneratedWhileContinue", {}).get("bytecode_source", {})
sync_while_continue_let = sync_generated_while_continue.get("body", {}).get("let", {})
sync_while_continue = sync_while_continue_let.get("body", {}).get("while_loop", {})
sync_while_continue_body = sync_while_continue.get("body", {}).get("seq", [])
if (
    sync_generated_while_continue.get("async_kind") != "sync_star"
    or sync_while_continue_let.get("locals", [{}])[0].get("name") != "i"
    or sync_while_continue.get("condition", {}).get("op") != ">"
    or sync_while_continue.get("before_continue", {}).get("yield", {}).get("concat") is None
    or sync_while_continue.get("continue_condition", {}).get("op") != "=="
    or sync_while_continue.get("continue_body", {}).get("set_local", {}).get("id") != 0
    or sync_while_continue.get("continue_body", {}).get("set_local", {}).get("value", {}).get("op") != "+"
    or len(sync_while_continue_body) != 2
    or sync_while_continue_body[0].get("yield", {}).get("concat") is None
    or sync_while_continue_body[1].get("set_local", {}).get("id") != 0
):
    raise SystemExit(f"expected syncGeneratedWhileContinue guarded while continue source, got {sync_generated_while_continue}")
async_generated_while_continue = patch_by_member.get("asyncGeneratedWhileContinue", {}).get("bytecode_source", {})
async_while_continue_let = async_generated_while_continue.get("body", {}).get("let", {})
async_while_continue = async_while_continue_let.get("body", {}).get("while_loop", {})
async_while_continue_body = async_while_continue.get("body", {}).get("seq", [])
if (
    async_generated_while_continue.get("async_kind") != "async_star"
    or async_while_continue_let.get("locals", [{}])[0].get("name") != "i"
    or async_while_continue.get("condition", {}).get("op") != ">"
    or async_while_continue.get("before_continue", {}).get("yield", {}).get("concat") is None
    or async_while_continue.get("continue_condition", {}).get("op") != "=="
    or async_while_continue.get("continue_body", {}).get("set_local", {}).get("id") != 0
    or async_while_continue.get("continue_body", {}).get("set_local", {}).get("value", {}).get("op") != "+"
    or len(async_while_continue_body) != 2
    or async_while_continue_body[0].get("yield", {}).get("concat") is None
    or async_while_continue_body[1].get("set_local", {}).get("id") != 0
):
    raise SystemExit(f"expected asyncGeneratedWhileContinue guarded while continue source, got {async_generated_while_continue}")
sync_generated_while_continue_break = patch_by_member.get("syncGeneratedWhileContinueBreak", {}).get("bytecode_source", {})
sync_while_continue_break_let = sync_generated_while_continue_break.get("body", {}).get("let", {})
sync_while_continue_break = sync_while_continue_break_let.get("body", {}).get("while_loop", {})
sync_while_continue_break_body = sync_while_continue_break.get("body", {}).get("seq", [])
if (
    sync_generated_while_continue_break.get("async_kind") != "sync_star"
    or sync_while_continue_break_let.get("locals", [{}])[0].get("name") != "i"
    or sync_while_continue_break.get("condition", {}).get("op") != ">"
    or sync_while_continue_break.get("before_continue", {}).get("yield", {}).get("concat") is None
    or sync_while_continue_break.get("continue_condition", {}).get("op") != "=="
    or sync_while_continue_break.get("continue_body", {}).get("set_local", {}).get("id") != 0
    or sync_while_continue_break.get("before_break", {}).get("yield", {}).get("concat") is None
    or sync_while_continue_break.get("break_condition", {}).get("op") != "=="
    or len(sync_while_continue_break_body) != 2
    or sync_while_continue_break_body[0].get("yield", {}).get("concat") is None
    or sync_while_continue_break_body[1].get("set_local", {}).get("id") != 0
):
    raise SystemExit(f"expected syncGeneratedWhileContinueBreak guarded while continue+break source, got {sync_generated_while_continue_break}")
async_generated_while_continue_break = patch_by_member.get("asyncGeneratedWhileContinueBreak", {}).get("bytecode_source", {})
async_while_continue_break_let = async_generated_while_continue_break.get("body", {}).get("let", {})
async_while_continue_break = async_while_continue_break_let.get("body", {}).get("while_loop", {})
async_while_continue_break_body = async_while_continue_break.get("body", {}).get("seq", [])
if (
    async_generated_while_continue_break.get("async_kind") != "async_star"
    or async_while_continue_break_let.get("locals", [{}])[0].get("name") != "i"
    or async_while_continue_break.get("condition", {}).get("op") != ">"
    or async_while_continue_break.get("before_continue", {}).get("yield", {}).get("concat") is None
    or async_while_continue_break.get("continue_condition", {}).get("op") != "=="
    or async_while_continue_break.get("continue_body", {}).get("set_local", {}).get("id") != 0
    or async_while_continue_break.get("before_break", {}).get("yield", {}).get("concat") is None
    or async_while_continue_break.get("break_condition", {}).get("op") != "=="
    or len(async_while_continue_break_body) != 2
    or async_while_continue_break_body[0].get("yield", {}).get("concat") is None
    or async_while_continue_break_body[1].get("set_local", {}).get("id") != 0
):
    raise SystemExit(f"expected asyncGeneratedWhileContinueBreak guarded while continue+break source, got {async_generated_while_continue_break}")
sync_generated_do_while = patch_by_member.get("syncGeneratedDoWhile", {}).get("bytecode_source", {})
sync_do_while_let = sync_generated_do_while.get("body", {}).get("let", {})
sync_do_while_seq = sync_do_while_let.get("body", {}).get("seq", [])
sync_do_while_first = sync_do_while_seq[0].get("seq", []) if len(sync_do_while_seq) > 0 else []
sync_do_while_loop = sync_do_while_seq[1].get("while_loop", {}) if len(sync_do_while_seq) > 1 else {}
sync_do_while_loop_body = sync_do_while_loop.get("body", {}).get("seq", [])
if (
    sync_generated_do_while.get("async_kind") != "sync_star"
    or sync_do_while_let.get("locals", [{}])[0].get("name") != "i"
    or len(sync_do_while_seq) != 2
    or len(sync_do_while_first) != 2
    or sync_do_while_first[0].get("yield", {}).get("concat") is None
    or sync_do_while_first[1].get("set_local", {}).get("id") != 0
    or sync_do_while_loop.get("condition", {}).get("op") != ">"
    or len(sync_do_while_loop_body) != 2
    or sync_do_while_loop_body[0].get("yield", {}).get("concat") is None
    or sync_do_while_loop_body[1].get("set_local", {}).get("id") != 0
):
    raise SystemExit(f"expected syncGeneratedDoWhile seq + while_loop source, got {sync_generated_do_while}")
async_generated_do_while = patch_by_member.get("asyncGeneratedDoWhile", {}).get("bytecode_source", {})
async_do_while_let = async_generated_do_while.get("body", {}).get("let", {})
async_do_while_seq = async_do_while_let.get("body", {}).get("seq", [])
async_do_while_first = async_do_while_seq[0].get("seq", []) if len(async_do_while_seq) > 0 else []
async_do_while_loop = async_do_while_seq[1].get("while_loop", {}) if len(async_do_while_seq) > 1 else {}
async_do_while_loop_body = async_do_while_loop.get("body", {}).get("seq", [])
if (
    async_generated_do_while.get("async_kind") != "async_star"
    or async_do_while_let.get("locals", [{}])[0].get("name") != "i"
    or len(async_do_while_seq) != 2
    or len(async_do_while_first) != 2
    or async_do_while_first[0].get("yield", {}).get("concat") is None
    or async_do_while_first[1].get("set_local", {}).get("id") != 0
    or async_do_while_loop.get("condition", {}).get("op") != ">"
    or len(async_do_while_loop_body) != 2
    or async_do_while_loop_body[0].get("yield", {}).get("concat") is None
    or async_do_while_loop_body[1].get("set_local", {}).get("id") != 0
):
    raise SystemExit(f"expected asyncGeneratedDoWhile seq + while_loop source, got {async_generated_do_while}")
sync_generated_do_while_break = patch_by_member.get("syncGeneratedDoWhileBreak", {}).get("bytecode_source", {})
sync_do_while_break_let = sync_generated_do_while_break.get("body", {}).get("let", {})
sync_do_while_break_seq = sync_do_while_break_let.get("body", {}).get("seq", [])
sync_do_while_break_cond = sync_do_while_break_seq[1].get("conditional", {}) if len(sync_do_while_break_seq) > 1 else {}
sync_do_while_break_else = sync_do_while_break_cond.get("else", {}).get("seq", [])
sync_do_while_break_loop = sync_do_while_break_else[2].get("while_loop", {}) if len(sync_do_while_break_else) > 2 else {}
sync_do_while_break_loop_body = sync_do_while_break_loop.get("body", {}).get("seq", [])
if (
    sync_generated_do_while_break.get("async_kind") != "sync_star"
    or sync_do_while_break_let.get("locals", [{}])[0].get("name") != "i"
    or len(sync_do_while_break_seq) != 2
    or sync_do_while_break_seq[0].get("yield", {}).get("concat") is None
    or sync_do_while_break_cond.get("condition", {}).get("op") != "=="
    or sync_do_while_break_cond.get("then", {}).get("null") is not True
    or len(sync_do_while_break_else) != 3
    or sync_do_while_break_else[0].get("yield", {}).get("concat") is None
    or sync_do_while_break_else[1].get("set_local", {}).get("id") != 0
    or sync_do_while_break_loop.get("condition", {}).get("op") != ">"
    or sync_do_while_break_loop.get("before_break", {}).get("yield", {}).get("concat") is None
    or sync_do_while_break_loop.get("break_condition", {}).get("op") != "=="
    or len(sync_do_while_break_loop_body) != 2
):
    raise SystemExit(f"expected syncGeneratedDoWhileBreak guarded do-while source, got {sync_generated_do_while_break}")
async_generated_do_while_break = patch_by_member.get("asyncGeneratedDoWhileBreak", {}).get("bytecode_source", {})
async_do_while_break_let = async_generated_do_while_break.get("body", {}).get("let", {})
async_do_while_break_seq = async_do_while_break_let.get("body", {}).get("seq", [])
async_do_while_break_cond = async_do_while_break_seq[1].get("conditional", {}) if len(async_do_while_break_seq) > 1 else {}
async_do_while_break_else = async_do_while_break_cond.get("else", {}).get("seq", [])
async_do_while_break_loop = async_do_while_break_else[2].get("while_loop", {}) if len(async_do_while_break_else) > 2 else {}
async_do_while_break_loop_body = async_do_while_break_loop.get("body", {}).get("seq", [])
if (
    async_generated_do_while_break.get("async_kind") != "async_star"
    or async_do_while_break_let.get("locals", [{}])[0].get("name") != "i"
    or len(async_do_while_break_seq) != 2
    or async_do_while_break_seq[0].get("yield", {}).get("concat") is None
    or async_do_while_break_cond.get("condition", {}).get("op") != "=="
    or async_do_while_break_cond.get("then", {}).get("null") is not True
    or len(async_do_while_break_else) != 3
    or async_do_while_break_else[0].get("yield", {}).get("concat") is None
    or async_do_while_break_else[1].get("set_local", {}).get("id") != 0
    or async_do_while_break_loop.get("condition", {}).get("op") != ">"
    or async_do_while_break_loop.get("before_break", {}).get("yield", {}).get("concat") is None
    or async_do_while_break_loop.get("break_condition", {}).get("op") != "=="
    or len(async_do_while_break_loop_body) != 2
):
    raise SystemExit(f"expected asyncGeneratedDoWhileBreak guarded do-while source, got {async_generated_do_while_break}")
sync_generated_do_while_continue = patch_by_member.get("syncGeneratedDoWhileContinue", {}).get("bytecode_source", {})
sync_do_while_continue_let = sync_generated_do_while_continue.get("body", {}).get("let", {})
sync_do_while_continue_seq = sync_do_while_continue_let.get("body", {}).get("seq", [])
sync_do_while_continue_cond = sync_do_while_continue_seq[1].get("conditional", {}) if len(sync_do_while_continue_seq) > 1 else {}
sync_do_while_continue_else = sync_do_while_continue_cond.get("else", {}).get("seq", [])
sync_do_while_continue_loop = sync_do_while_continue_seq[2].get("while_loop", {}) if len(sync_do_while_continue_seq) > 2 else {}
sync_do_while_continue_loop_body = sync_do_while_continue_loop.get("body", {}).get("seq", [])
if (
    sync_generated_do_while_continue.get("async_kind") != "sync_star"
    or sync_do_while_continue_let.get("locals", [{}])[0].get("name") != "i"
    or len(sync_do_while_continue_seq) != 3
    or sync_do_while_continue_seq[0].get("yield", {}).get("concat") is None
    or sync_do_while_continue_cond.get("condition", {}).get("op") != "=="
    or sync_do_while_continue_cond.get("then", {}).get("set_local", {}).get("id") != 0
    or len(sync_do_while_continue_else) != 2
    or sync_do_while_continue_else[0].get("yield", {}).get("concat") is None
    or sync_do_while_continue_else[1].get("set_local", {}).get("id") != 0
    or sync_do_while_continue_loop.get("condition", {}).get("op") != ">"
    or sync_do_while_continue_loop.get("before_continue", {}).get("yield", {}).get("concat") is None
    or sync_do_while_continue_loop.get("continue_condition", {}).get("op") != "=="
    or sync_do_while_continue_loop.get("continue_body", {}).get("set_local", {}).get("id") != 0
    or len(sync_do_while_continue_loop_body) != 2
):
    raise SystemExit(f"expected syncGeneratedDoWhileContinue guarded do-while source, got {sync_generated_do_while_continue}")
async_generated_do_while_continue = patch_by_member.get("asyncGeneratedDoWhileContinue", {}).get("bytecode_source", {})
async_do_while_continue_let = async_generated_do_while_continue.get("body", {}).get("let", {})
async_do_while_continue_seq = async_do_while_continue_let.get("body", {}).get("seq", [])
async_do_while_continue_cond = async_do_while_continue_seq[1].get("conditional", {}) if len(async_do_while_continue_seq) > 1 else {}
async_do_while_continue_else = async_do_while_continue_cond.get("else", {}).get("seq", [])
async_do_while_continue_loop = async_do_while_continue_seq[2].get("while_loop", {}) if len(async_do_while_continue_seq) > 2 else {}
async_do_while_continue_loop_body = async_do_while_continue_loop.get("body", {}).get("seq", [])
if (
    async_generated_do_while_continue.get("async_kind") != "async_star"
    or async_do_while_continue_let.get("locals", [{}])[0].get("name") != "i"
    or len(async_do_while_continue_seq) != 3
    or async_do_while_continue_seq[0].get("yield", {}).get("concat") is None
    or async_do_while_continue_cond.get("condition", {}).get("op") != "=="
    or async_do_while_continue_cond.get("then", {}).get("set_local", {}).get("id") != 0
    or len(async_do_while_continue_else) != 2
    or async_do_while_continue_else[0].get("yield", {}).get("concat") is None
    or async_do_while_continue_else[1].get("set_local", {}).get("id") != 0
    or async_do_while_continue_loop.get("condition", {}).get("op") != ">"
    or async_do_while_continue_loop.get("before_continue", {}).get("yield", {}).get("concat") is None
    or async_do_while_continue_loop.get("continue_condition", {}).get("op") != "=="
    or async_do_while_continue_loop.get("continue_body", {}).get("set_local", {}).get("id") != 0
    or len(async_do_while_continue_loop_body) != 2
):
    raise SystemExit(f"expected asyncGeneratedDoWhileContinue guarded do-while source, got {async_generated_do_while_continue}")
sync_generated_do_while_continue_break = patch_by_member.get("syncGeneratedDoWhileContinueBreak", {}).get("bytecode_source", {})
sync_do_while_continue_break_let = sync_generated_do_while_continue_break.get("body", {}).get("let", {})
sync_do_while_continue_break_seq = sync_do_while_continue_break_let.get("body", {}).get("seq", [])
sync_do_while_continue_break_cond = sync_do_while_continue_break_seq[1].get("conditional", {}) if len(sync_do_while_continue_break_seq) > 1 else {}
sync_do_while_continue_break_then = sync_do_while_continue_break_cond.get("then", {}).get("seq", [])
sync_do_while_continue_break_else = sync_do_while_continue_break_cond.get("else", {}).get("seq", [])
sync_do_while_continue_break_else_cond = sync_do_while_continue_break_else[1].get("conditional", {}) if len(sync_do_while_continue_break_else) > 1 else {}
sync_do_while_continue_break_after_break = sync_do_while_continue_break_else_cond.get("else", {}).get("seq", [])
sync_do_while_continue_break_loop = sync_do_while_continue_break_after_break[2].get("while_loop", {}) if len(sync_do_while_continue_break_after_break) > 2 else {}
sync_do_while_continue_break_loop_body = sync_do_while_continue_break_loop.get("body", {}).get("seq", [])
if (
    sync_generated_do_while_continue_break.get("async_kind") != "sync_star"
    or sync_do_while_continue_break_let.get("locals", [{}])[0].get("name") != "i"
    or len(sync_do_while_continue_break_seq) != 2
    or sync_do_while_continue_break_seq[0].get("yield", {}).get("concat") is None
    or sync_do_while_continue_break_cond.get("condition", {}).get("op") != "=="
    or len(sync_do_while_continue_break_then) != 2
    or sync_do_while_continue_break_then[0].get("set_local", {}).get("id") != 0
    or sync_do_while_continue_break_then[1].get("while_loop", {}).get("condition", {}).get("op") != ">"
    or len(sync_do_while_continue_break_else) != 2
    or sync_do_while_continue_break_else[0].get("yield", {}).get("concat") is None
    or sync_do_while_continue_break_else_cond.get("condition", {}).get("op") != "=="
    or sync_do_while_continue_break_else_cond.get("then", {}).get("null") is not True
    or len(sync_do_while_continue_break_after_break) != 3
    or sync_do_while_continue_break_after_break[0].get("yield", {}).get("concat") is None
    or sync_do_while_continue_break_after_break[1].get("set_local", {}).get("id") != 0
    or sync_do_while_continue_break_loop.get("before_continue", {}).get("yield", {}).get("concat") is None
    or sync_do_while_continue_break_loop.get("continue_condition", {}).get("op") != "=="
    or sync_do_while_continue_break_loop.get("continue_body", {}).get("set_local", {}).get("id") != 0
    or sync_do_while_continue_break_loop.get("before_break", {}).get("yield", {}).get("concat") is None
    or sync_do_while_continue_break_loop.get("break_condition", {}).get("op") != "=="
    or len(sync_do_while_continue_break_loop_body) != 2
):
    raise SystemExit(f"expected syncGeneratedDoWhileContinueBreak guarded do-while continue+break source, got {sync_generated_do_while_continue_break}")
async_generated_do_while_continue_break = patch_by_member.get("asyncGeneratedDoWhileContinueBreak", {}).get("bytecode_source", {})
async_do_while_continue_break_let = async_generated_do_while_continue_break.get("body", {}).get("let", {})
async_do_while_continue_break_seq = async_do_while_continue_break_let.get("body", {}).get("seq", [])
async_do_while_continue_break_cond = async_do_while_continue_break_seq[1].get("conditional", {}) if len(async_do_while_continue_break_seq) > 1 else {}
async_do_while_continue_break_then = async_do_while_continue_break_cond.get("then", {}).get("seq", [])
async_do_while_continue_break_else = async_do_while_continue_break_cond.get("else", {}).get("seq", [])
async_do_while_continue_break_else_cond = async_do_while_continue_break_else[1].get("conditional", {}) if len(async_do_while_continue_break_else) > 1 else {}
async_do_while_continue_break_after_break = async_do_while_continue_break_else_cond.get("else", {}).get("seq", [])
async_do_while_continue_break_loop = async_do_while_continue_break_after_break[2].get("while_loop", {}) if len(async_do_while_continue_break_after_break) > 2 else {}
async_do_while_continue_break_loop_body = async_do_while_continue_break_loop.get("body", {}).get("seq", [])
if (
    async_generated_do_while_continue_break.get("async_kind") != "async_star"
    or async_do_while_continue_break_let.get("locals", [{}])[0].get("name") != "i"
    or len(async_do_while_continue_break_seq) != 2
    or async_do_while_continue_break_seq[0].get("yield", {}).get("concat") is None
    or async_do_while_continue_break_cond.get("condition", {}).get("op") != "=="
    or len(async_do_while_continue_break_then) != 2
    or async_do_while_continue_break_then[0].get("set_local", {}).get("id") != 0
    or async_do_while_continue_break_then[1].get("while_loop", {}).get("condition", {}).get("op") != ">"
    or len(async_do_while_continue_break_else) != 2
    or async_do_while_continue_break_else[0].get("yield", {}).get("concat") is None
    or async_do_while_continue_break_else_cond.get("condition", {}).get("op") != "=="
    or async_do_while_continue_break_else_cond.get("then", {}).get("null") is not True
    or len(async_do_while_continue_break_after_break) != 3
    or async_do_while_continue_break_after_break[0].get("yield", {}).get("concat") is None
    or async_do_while_continue_break_after_break[1].get("set_local", {}).get("id") != 0
    or async_do_while_continue_break_loop.get("before_continue", {}).get("yield", {}).get("concat") is None
    or async_do_while_continue_break_loop.get("continue_condition", {}).get("op") != "=="
    or async_do_while_continue_break_loop.get("continue_body", {}).get("set_local", {}).get("id") != 0
    or async_do_while_continue_break_loop.get("before_break", {}).get("yield", {}).get("concat") is None
    or async_do_while_continue_break_loop.get("break_condition", {}).get("op") != "=="
    or len(async_do_while_continue_break_loop_body) != 2
):
    raise SystemExit(f"expected asyncGeneratedDoWhileContinueBreak guarded do-while continue+break source, got {async_generated_do_while_continue_break}")
sync_generated_for_loop = patch_by_member.get("syncGeneratedForLoop", {}).get("bytecode_source", {})
sync_for_loop_let = sync_generated_for_loop.get("body", {}).get("let", {})
sync_for_loop = sync_for_loop_let.get("body", {}).get("while_loop", {})
sync_for_loop_body = sync_for_loop.get("body", {}).get("seq", [])
if (
    sync_generated_for_loop.get("async_kind") != "sync_star"
    or sync_for_loop_let.get("locals", [{}])[0].get("name") != "i"
    or sync_for_loop_let.get("locals", [{}])[0].get("value", {}).get("int") != 0
    or sync_for_loop.get("condition", {}).get("op") != ">"
    or len(sync_for_loop_body) != 2
    or sync_for_loop_body[0].get("yield", {}).get("concat") is None
    or sync_for_loop_body[1].get("set_local", {}).get("id") != 0
    or sync_for_loop_body[1].get("set_local", {}).get("value", {}).get("op") != "+"
):
    raise SystemExit(f"expected syncGeneratedForLoop lowered for source, got {sync_generated_for_loop}")
async_generated_for_loop = patch_by_member.get("asyncGeneratedForLoop", {}).get("bytecode_source", {})
async_for_loop_let = async_generated_for_loop.get("body", {}).get("let", {})
async_for_loop = async_for_loop_let.get("body", {}).get("while_loop", {})
async_for_loop_body = async_for_loop.get("body", {}).get("seq", [])
if (
    async_generated_for_loop.get("async_kind") != "async_star"
    or async_for_loop_let.get("locals", [{}])[0].get("name") != "i"
    or async_for_loop_let.get("locals", [{}])[0].get("value", {}).get("int") != 0
    or async_for_loop.get("condition", {}).get("op") != ">"
    or len(async_for_loop_body) != 2
    or async_for_loop_body[0].get("yield", {}).get("concat") is None
    or async_for_loop_body[1].get("set_local", {}).get("id") != 0
    or async_for_loop_body[1].get("set_local", {}).get("value", {}).get("op") != "+"
):
    raise SystemExit(f"expected asyncGeneratedForLoop lowered for source, got {async_generated_for_loop}")
sync_generated_for_loop_postinc = patch_by_member.get("syncGeneratedForLoopPostIncrement", {}).get("bytecode_source", {})
sync_for_loop_postinc_let = sync_generated_for_loop_postinc.get("body", {}).get("let", {})
sync_for_loop_postinc = sync_for_loop_postinc_let.get("body", {}).get("while_loop", {})
sync_for_loop_postinc_body = sync_for_loop_postinc.get("body", {}).get("seq", [])
if (
    sync_generated_for_loop_postinc.get("async_kind") != "sync_star"
    or sync_for_loop_postinc_let.get("locals", [{}])[0].get("name") != "i"
    or sync_for_loop_postinc.get("condition", {}).get("op") != ">"
    or len(sync_for_loop_postinc_body) != 2
    or sync_for_loop_postinc_body[0].get("yield", {}).get("concat") is None
    or sync_for_loop_postinc_body[1].get("set_local", {}).get("id") != 0
    or sync_for_loop_postinc_body[1].get("set_local", {}).get("value", {}).get("op") != "+"
):
    raise SystemExit(f"expected syncGeneratedForLoopPostIncrement lowered post-increment source, got {sync_generated_for_loop_postinc}")
async_generated_for_loop_postinc = patch_by_member.get("asyncGeneratedForLoopPostIncrement", {}).get("bytecode_source", {})
async_for_loop_postinc_let = async_generated_for_loop_postinc.get("body", {}).get("let", {})
async_for_loop_postinc = async_for_loop_postinc_let.get("body", {}).get("while_loop", {})
async_for_loop_postinc_body = async_for_loop_postinc.get("body", {}).get("seq", [])
if (
    async_generated_for_loop_postinc.get("async_kind") != "async_star"
    or async_for_loop_postinc_let.get("locals", [{}])[0].get("name") != "i"
    or async_for_loop_postinc.get("condition", {}).get("op") != ">"
    or len(async_for_loop_postinc_body) != 2
    or async_for_loop_postinc_body[0].get("yield", {}).get("concat") is None
    or async_for_loop_postinc_body[1].get("set_local", {}).get("id") != 0
    or async_for_loop_postinc_body[1].get("set_local", {}).get("value", {}).get("op") != "+"
):
    raise SystemExit(f"expected asyncGeneratedForLoopPostIncrement lowered post-increment source, got {async_generated_for_loop_postinc}")
sync_generated_for_loop_multi = patch_by_member.get("syncGeneratedForLoopMultiUpdate", {}).get("bytecode_source", {})
sync_for_loop_multi_let = sync_generated_for_loop_multi.get("body", {}).get("let", {})
sync_for_loop_multi = sync_for_loop_multi_let.get("body", {}).get("while_loop", {})
sync_for_loop_multi_body = sync_for_loop_multi.get("body", {}).get("seq", [])
sync_for_loop_multi_locals = sync_for_loop_multi_let.get("locals", [])
if (
    sync_generated_for_loop_multi.get("async_kind") != "sync_star"
    or [item.get("name") for item in sync_for_loop_multi_locals] != ["i", "j"]
    or sync_for_loop_multi_locals[0].get("value", {}).get("int") != 0
    or sync_for_loop_multi_locals[1].get("value", {}).get("int") != 10
    or sync_for_loop_multi.get("condition", {}).get("op") != ">"
    or len(sync_for_loop_multi_body) != 3
    or sync_for_loop_multi_body[0].get("yield", {}).get("concat") is None
    or sync_for_loop_multi_body[1].get("set_local", {}).get("id") != 0
    or sync_for_loop_multi_body[2].get("set_local", {}).get("id") != 1
):
    raise SystemExit(f"expected syncGeneratedForLoopMultiUpdate multi-update source, got {sync_generated_for_loop_multi}")
async_generated_for_loop_multi = patch_by_member.get("asyncGeneratedForLoopMultiUpdate", {}).get("bytecode_source", {})
async_for_loop_multi_let = async_generated_for_loop_multi.get("body", {}).get("let", {})
async_for_loop_multi = async_for_loop_multi_let.get("body", {}).get("while_loop", {})
async_for_loop_multi_body = async_for_loop_multi.get("body", {}).get("seq", [])
async_for_loop_multi_locals = async_for_loop_multi_let.get("locals", [])
if (
    async_generated_for_loop_multi.get("async_kind") != "async_star"
    or [item.get("name") for item in async_for_loop_multi_locals] != ["i", "j"]
    or async_for_loop_multi_locals[0].get("value", {}).get("int") != 0
    or async_for_loop_multi_locals[1].get("value", {}).get("int") != 10
    or async_for_loop_multi.get("condition", {}).get("op") != ">"
    or len(async_for_loop_multi_body) != 3
    or async_for_loop_multi_body[0].get("yield", {}).get("concat") is None
    or async_for_loop_multi_body[1].get("set_local", {}).get("id") != 0
    or async_for_loop_multi_body[2].get("set_local", {}).get("id") != 1
):
    raise SystemExit(f"expected asyncGeneratedForLoopMultiUpdate multi-update source, got {async_generated_for_loop_multi}")
sync_generated_for_loop_external = patch_by_member.get("syncGeneratedForLoopExternalLocal", {}).get("bytecode_source", {})
sync_for_loop_external_let = sync_generated_for_loop_external.get("body", {}).get("let", {})
sync_for_loop_external = sync_for_loop_external_let.get("body", {}).get("while_loop", {})
sync_for_loop_external_body = sync_for_loop_external.get("body", {}).get("seq", [])
if (
    sync_generated_for_loop_external.get("async_kind") != "sync_star"
    or sync_for_loop_external_let.get("locals", [{}])[0].get("name") != "i"
    or sync_for_loop_external.get("condition", {}).get("op") != ">"
    or len(sync_for_loop_external_body) != 2
    or sync_for_loop_external_body[0].get("yield", {}).get("concat") is None
    or sync_for_loop_external_body[1].get("set_local", {}).get("id") != 0
):
    raise SystemExit(f"expected syncGeneratedForLoopExternalLocal no-init source, got {sync_generated_for_loop_external}")
async_generated_for_loop_external = patch_by_member.get("asyncGeneratedForLoopExternalLocal", {}).get("bytecode_source", {})
async_for_loop_external_let = async_generated_for_loop_external.get("body", {}).get("let", {})
async_for_loop_external = async_for_loop_external_let.get("body", {}).get("while_loop", {})
async_for_loop_external_body = async_for_loop_external.get("body", {}).get("seq", [])
if (
    async_generated_for_loop_external.get("async_kind") != "async_star"
    or async_for_loop_external_let.get("locals", [{}])[0].get("name") != "i"
    or async_for_loop_external.get("condition", {}).get("op") != ">"
    or len(async_for_loop_external_body) != 2
    or async_for_loop_external_body[0].get("yield", {}).get("concat") is None
    or async_for_loop_external_body[1].get("set_local", {}).get("id") != 0
):
    raise SystemExit(f"expected asyncGeneratedForLoopExternalLocal no-init source, got {async_generated_for_loop_external}")
sync_generated_for_loop_body_update = patch_by_member.get("syncGeneratedForLoopBodyUpdate", {}).get("bytecode_source", {})
sync_for_loop_body_update_let = sync_generated_for_loop_body_update.get("body", {}).get("let", {})
sync_for_loop_body_update = sync_for_loop_body_update_let.get("body", {}).get("while_loop", {})
sync_for_loop_body_update_body = sync_for_loop_body_update.get("body", {}).get("seq", [])
if (
    sync_generated_for_loop_body_update.get("async_kind") != "sync_star"
    or sync_for_loop_body_update_let.get("locals", [{}])[0].get("name") != "i"
    or sync_for_loop_body_update.get("condition", {}).get("op") != ">"
    or len(sync_for_loop_body_update_body) != 2
    or sync_for_loop_body_update_body[0].get("yield", {}).get("concat") is None
    or sync_for_loop_body_update_body[1].get("set_local", {}).get("id") != 0
):
    raise SystemExit(f"expected syncGeneratedForLoopBodyUpdate no-update source, got {sync_generated_for_loop_body_update}")
async_generated_for_loop_body_update = patch_by_member.get("asyncGeneratedForLoopBodyUpdate", {}).get("bytecode_source", {})
async_for_loop_body_update_let = async_generated_for_loop_body_update.get("body", {}).get("let", {})
async_for_loop_body_update = async_for_loop_body_update_let.get("body", {}).get("while_loop", {})
async_for_loop_body_update_body = async_for_loop_body_update.get("body", {}).get("seq", [])
if (
    async_generated_for_loop_body_update.get("async_kind") != "async_star"
    or async_for_loop_body_update_let.get("locals", [{}])[0].get("name") != "i"
    or async_for_loop_body_update.get("condition", {}).get("op") != ">"
    or len(async_for_loop_body_update_body) != 2
    or async_for_loop_body_update_body[0].get("yield", {}).get("concat") is None
    or async_for_loop_body_update_body[1].get("set_local", {}).get("id") != 0
):
    raise SystemExit(f"expected asyncGeneratedForLoopBodyUpdate no-update source, got {async_generated_for_loop_body_update}")
sync_generated_for_loop_continue = patch_by_member.get("syncGeneratedForLoopContinue", {}).get("bytecode_source", {})
sync_for_loop_continue_let = sync_generated_for_loop_continue.get("body", {}).get("let", {})
sync_for_loop_continue = sync_for_loop_continue_let.get("body", {}).get("while_loop", {})
sync_for_loop_continue_body = sync_for_loop_continue.get("body", {}).get("seq", [])
sync_for_loop_continue_guard = sync_for_loop_continue_body[1].get("conditional", {}) if len(sync_for_loop_continue_body) > 1 else {}
if (
    sync_generated_for_loop_continue.get("async_kind") != "sync_star"
    or sync_for_loop_continue_let.get("locals", [{}])[0].get("name") != "i"
    or sync_for_loop_continue.get("condition", {}).get("op") != ">"
    or len(sync_for_loop_continue_body) != 3
    or sync_for_loop_continue_body[0].get("yield", {}).get("concat") is None
    or sync_for_loop_continue_guard.get("condition", {}).get("op") != "=="
    or sync_for_loop_continue_guard.get("then", {}).get("null") is not True
    or sync_for_loop_continue_guard.get("else", {}).get("yield", {}).get("concat") is None
    or sync_for_loop_continue_body[2].get("set_local", {}).get("id") != 0
):
    raise SystemExit(f"expected syncGeneratedForLoopContinue lowered continue source, got {sync_generated_for_loop_continue}")
async_generated_for_loop_continue = patch_by_member.get("asyncGeneratedForLoopContinue", {}).get("bytecode_source", {})
async_for_loop_continue_let = async_generated_for_loop_continue.get("body", {}).get("let", {})
async_for_loop_continue = async_for_loop_continue_let.get("body", {}).get("while_loop", {})
async_for_loop_continue_body = async_for_loop_continue.get("body", {}).get("seq", [])
async_for_loop_continue_guard = async_for_loop_continue_body[1].get("conditional", {}) if len(async_for_loop_continue_body) > 1 else {}
if (
    async_generated_for_loop_continue.get("async_kind") != "async_star"
    or async_for_loop_continue_let.get("locals", [{}])[0].get("name") != "i"
    or async_for_loop_continue.get("condition", {}).get("op") != ">"
    or len(async_for_loop_continue_body) != 3
    or async_for_loop_continue_body[0].get("yield", {}).get("concat") is None
    or async_for_loop_continue_guard.get("condition", {}).get("op") != "=="
    or async_for_loop_continue_guard.get("then", {}).get("null") is not True
    or async_for_loop_continue_guard.get("else", {}).get("yield", {}).get("concat") is None
    or async_for_loop_continue_body[2].get("set_local", {}).get("id") != 0
):
    raise SystemExit(f"expected asyncGeneratedForLoopContinue lowered continue source, got {async_generated_for_loop_continue}")
sync_generated_for_loop_continue_break = patch_by_member.get("syncGeneratedForLoopContinueBreak", {}).get("bytecode_source", {})
sync_for_loop_continue_break_let = sync_generated_for_loop_continue_break.get("body", {}).get("let", {})
sync_for_loop_continue_break = sync_for_loop_continue_break_let.get("body", {}).get("while_loop", {})
sync_for_loop_continue_break_body = sync_for_loop_continue_break.get("body", {}).get("seq", [])
if (
    sync_generated_for_loop_continue_break.get("async_kind") != "sync_star"
    or sync_for_loop_continue_break_let.get("locals", [{}])[0].get("name") != "i"
    or sync_for_loop_continue_break.get("condition", {}).get("op") != ">"
    or sync_for_loop_continue_break.get("before_continue", {}).get("yield", {}).get("concat") is None
    or sync_for_loop_continue_break.get("continue_condition", {}).get("op") != "=="
    or sync_for_loop_continue_break.get("continue_body", {}).get("set_local", {}).get("id") != 0
    or sync_for_loop_continue_break.get("before_break", {}).get("yield", {}).get("concat") is None
    or sync_for_loop_continue_break.get("break_condition", {}).get("op") != "=="
    or len(sync_for_loop_continue_break_body) != 2
    or sync_for_loop_continue_break_body[0].get("yield", {}).get("concat") is None
    or sync_for_loop_continue_break_body[1].get("set_local", {}).get("id") != 0
):
    raise SystemExit(f"expected syncGeneratedForLoopContinueBreak lowered continue+break source, got {sync_generated_for_loop_continue_break}")
async_generated_for_loop_continue_break = patch_by_member.get("asyncGeneratedForLoopContinueBreak", {}).get("bytecode_source", {})
async_for_loop_continue_break_let = async_generated_for_loop_continue_break.get("body", {}).get("let", {})
async_for_loop_continue_break = async_for_loop_continue_break_let.get("body", {}).get("while_loop", {})
async_for_loop_continue_break_body = async_for_loop_continue_break.get("body", {}).get("seq", [])
if (
    async_generated_for_loop_continue_break.get("async_kind") != "async_star"
    or async_for_loop_continue_break_let.get("locals", [{}])[0].get("name") != "i"
    or async_for_loop_continue_break.get("condition", {}).get("op") != ">"
    or async_for_loop_continue_break.get("before_continue", {}).get("yield", {}).get("concat") is None
    or async_for_loop_continue_break.get("continue_condition", {}).get("op") != "=="
    or async_for_loop_continue_break.get("continue_body", {}).get("set_local", {}).get("id") != 0
    or async_for_loop_continue_break.get("before_break", {}).get("yield", {}).get("concat") is None
    or async_for_loop_continue_break.get("break_condition", {}).get("op") != "=="
    or len(async_for_loop_continue_break_body) != 2
    or async_for_loop_continue_break_body[0].get("yield", {}).get("concat") is None
    or async_for_loop_continue_break_body[1].get("set_local", {}).get("id") != 0
):
    raise SystemExit(f"expected asyncGeneratedForLoopContinueBreak lowered continue+break source, got {async_generated_for_loop_continue_break}")
sync_generated_for_loop_break = patch_by_member.get("syncGeneratedForLoopBreak", {}).get("bytecode_source", {})
sync_for_loop_break_let = sync_generated_for_loop_break.get("body", {}).get("let", {})
sync_for_loop_break = sync_for_loop_break_let.get("body", {}).get("while_loop", {})
sync_for_loop_break_body = sync_for_loop_break.get("body", {}).get("seq", [])
if (
    sync_generated_for_loop_break.get("async_kind") != "sync_star"
    or sync_for_loop_break_let.get("locals", [{}])[0].get("name") != "i"
    or sync_for_loop_break.get("condition", {}).get("op") != ">"
    or sync_for_loop_break.get("before_break", {}).get("yield", {}).get("concat") is None
    or sync_for_loop_break.get("break_condition", {}).get("op") != "=="
    or len(sync_for_loop_break_body) != 2
    or sync_for_loop_break_body[0].get("yield", {}).get("concat") is None
    or sync_for_loop_break_body[1].get("set_local", {}).get("id") != 0
):
    raise SystemExit(f"expected syncGeneratedForLoopBreak lowered break source, got {sync_generated_for_loop_break}")
async_generated_for_loop_break = patch_by_member.get("asyncGeneratedForLoopBreak", {}).get("bytecode_source", {})
async_for_loop_break_let = async_generated_for_loop_break.get("body", {}).get("let", {})
async_for_loop_break = async_for_loop_break_let.get("body", {}).get("while_loop", {})
async_for_loop_break_body = async_for_loop_break.get("body", {}).get("seq", [])
if (
    async_generated_for_loop_break.get("async_kind") != "async_star"
    or async_for_loop_break_let.get("locals", [{}])[0].get("name") != "i"
    or async_for_loop_break.get("condition", {}).get("op") != ">"
    or async_for_loop_break.get("before_break", {}).get("yield", {}).get("concat") is None
    or async_for_loop_break.get("break_condition", {}).get("op") != "=="
    or len(async_for_loop_break_body) != 2
    or async_for_loop_break_body[0].get("yield", {}).get("concat") is None
    or async_for_loop_break_body[1].get("set_local", {}).get("id") != 0
):
    raise SystemExit(f"expected asyncGeneratedForLoopBreak lowered break source, got {async_generated_for_loop_break}")

json.dump(plan, open(sys.argv[3], "w"))
