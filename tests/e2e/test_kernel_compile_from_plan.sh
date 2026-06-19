#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DART_BIN="${DART_BIN:-dart}"
WORKDIR="$(mktemp -d /tmp/fcb_kernel_compile_from_plan_XXXXXX)"

cleanup() {
  if [ "${FCB_KEEP_KERNEL_COMPILE_TEST:-0}" = "1" ]; then
    echo "keeping workdir: $WORKDIR" >&2
  else
    rm -rf "$WORKDIR"
  fi
}
trap cleanup EXIT

mkdir -p "$WORKDIR/project/lib" "$WORKDIR/project/.dart_tool" "$WORKDIR/wrappers"

cat >"$WORKDIR/project/pubspec.yaml" <<'YAML'
name: fcb_kernel_compile_test
YAML

cat >"$WORKDIR/project/.dart_tool/package_config.json" <<JSON
{
  "configVersion": 2,
  "packages": [{
    "name": "fcb_kernel_compile_test",
    "rootUri": "$WORKDIR/project",
    "packageUri": "lib/",
    "languageVersion": "3.12"
  }]
}
JSON

cat >"$WORKDIR/project/lib/main.dart" <<'DART'
class User {
  User(this.name, this.label);
  final String name;
  final String label;
}

class Config {
  Config({required this.name, required this.label});
  final String name;
  final String label;
}

class Box<T> {
  Box(this.value);
  final T value;
}

class Greeter {
  Greeter();

  String surround(String value, {required String prefix, required String suffix}) {
    return '$prefix$value$suffix';
  }
}

double helper() {
  return 2.5;
}

Object? maybeNull() {
  return null;
}

String label(String name) {
  return 'hi $name';
}

String displayName(User user) {
  return user.name;
}

User makeUser() {
  return User('base', 'base-label');
}

Config makeConfig() {
  return Config(name: 'base', label: 'base-label');
}

Box<String> makeStringBox() {
  return Box<String>('base-box');
}

String dynamicNamedCall() {
  return Greeter().surround('base', prefix: '[', suffix: ']');
}

String capturedGreeting(String name) {
  final prefix = 'base';
  return (() => '$prefix $name')();
}

String storedClosureGreeting(String name) {
  final prefix = 'base';
  final format = () => '$prefix $name';
  return format();
}

String stableTearOffLabel() {
  return 'stable-tear-off';
}

String Function() topLevelTearOff() {
  return () => 'base-tear-off';
}

String Function() escapingGreeting(String name) {
  final prefix = 'base';
  return () => '$prefix $name';
}

String Function() storedEscapingGreeting(String name) {
  final prefix = 'base';
  final format = () => '$prefix $name';
  return format;
}

String Function(String) personalizedEscapingGreeting(String name) {
  final prefix = 'base';
  return (suffix) => '$prefix $name $suffix';
}

String Function({required String suffix}) namedEscapingGreeting(String name) {
  final prefix = 'base';
  return ({required suffix}) => '$prefix $name $suffix';
}

String Function([String? suffix]) optionalPositionalEscapingGreeting(String name) {
  final prefix = 'base';
  return ([suffix]) => '$prefix $name $suffix';
}

String Function({String? suffix}) optionalNamedEscapingGreeting(String name) {
  final prefix = 'base';
  return ({suffix}) => '$prefix $name $suffix';
}

String Function<T>(T) genericEscapingGreeting(String name) {
  final prefix = 'base';
  return <T>(value) => '$prefix $name $value';
}

String Function() localFunctionEscapingGreeting(String name) {
  final prefix = 'base';
  String format() {
    return '$prefix $name';
  }
  return format;
}

String Function() bodyLocalEscapingGreeting(String name) {
  final prefix = 'base';
  return () {
    final suffix = 'body';
    return '$prefix $name $suffix';
  };
}

String Function(bool) tryCatchEscapingGreeting(String name) {
  final prefix = 'base';
  return (fail) {
    try {
      return fail ? throw '$prefix-boom' : '$prefix-ok';
    } catch (e) {
      return '$prefix-caught $e';
    }
  };
}

String Function(String) dynamicCallEscapingGreeting(String name) {
  final greeter = Greeter();
  return (suffix) => greeter.surround(name, prefix: 'base-', suffix: suffix);
}

String Function(bool, bool) logicalEscapingGreeting(String name) {
  final prefix = 'base';
  return (enabled, premium) =>
      enabled && (premium || name == 'vip') || !enabled
      ? '$prefix $name pro'
      : '$prefix $name basic';
}

String Function(bool) ifElseEscapingGreeting(String name) {
  final prefix = 'base';
  return (enabled) {
    if (enabled) {
      return '$prefix $name enabled';
    }
    return '$prefix $name disabled';
  };
}

String Function(bool) bodyLocalIfElseEscapingGreeting(String name) {
  final prefix = 'base';
  return (enabled) {
    final suffix = 'body';
    if (enabled) {
      return '$prefix $name $suffix enabled';
    }
    return '$prefix $name $suffix disabled';
  };
}

String Function(bool) branchLocalIfElseEscapingGreeting(String name) {
  final prefix = 'base';
  return (enabled) {
    if (enabled) {
      final status = 'branch-enabled';
      return '$prefix $name $status';
    } else {
      final status = 'branch-disabled';
      return '$prefix $name $status';
    }
  };
}

String useCallback(String Function() callback) {
  return callback();
}

String passedEscapingGreeting(String name) {
  final prefix = 'base';
  return useCallback(() => '$prefix $name');
}

String recoverFromThrow(bool fail) {
  try {
    return fail ? throw 'base-boom' : 'base-ok';
  } catch (e) {
    return 'base-caught $e';
  }
}

String alwaysThrow() {
  return throw 'base-boom';
}

Future<String> asyncLabel() async {
  return 'base-async';
}

Future<String> awaitedLabel(bool enabled) async { if (await Future.value(enabled)) return 'base ${await Future.value('awaited')}'; return 'base disabled'; }

Future<String> awaitedLocalLabel(String name) async { try { final base = 'base-local'; final prefix = await Future.value(base); if (name == 'Ada') return '$prefix ${await Future.value('done')}'; return '$prefix $name'; } catch (e) { return 'base-caught $e'; } }
List<String> names(bool enabled, bool premium) {
  return ['base'];
}

List<String> dynamicNames(List<String> extra) {
  return ['base', ...extra];
}

List<String> runtimeForNames(List<String> extra) {
  return ['base', for (final value in extra) value];
}

Map<String, String> labels(bool enabled, bool premium) {
  return {'mode': 'base'};
}

Map<String, String> dynamicLabels(Map<String, String> extra) {
  return {'mode': 'base', ...extra};
}

Map<String, String> runtimeForLabels(Map<String, String> extra) {
  return {'mode': 'base', for (final entry in extra.entries) entry.key: entry.value};
}

String chooseLabel(bool enabled) {
  return enabled ? 'base-live' : 'base-off';
}

bool isKnown(Object value) {
  return value is int;
}

bool isUser(Object value) {
  return value is String;
}

bool isStringList(Object value) {
  return value is List<int>;
}

Object asStringList(Object value) {
  return value as List<int>;
}

bool isCallable(Object value) {
  return value is Object;
}

bool isRecord(Object value) {
  return value is Object;
}

double mainValue() {
  return helper();
}

void main() {
  mainValue();
}
DART

"$DART_BIN" "$ROOT_DIR/tool/fcb_kernel_manifest.dart" \
  --project "$WORKDIR/project" \
  --target lib/main.dart \
  >"$WORKDIR/release_inventory.json"

cat >"$WORKDIR/project/lib/main.dart" <<'DART'
class User {
  User(this.name, this.label);
  final String name;
  final String label;
}

class Config {
  Config({required this.name, required this.label});
  final String name;
  final String label;
}

class Box<T> {
  Box(this.value);
  final T value;
}

class Greeter {
  Greeter();

  String surround(String value, {required String prefix, required String suffix}) {
    return '$prefix$value$suffix';
  }
}

double helper() {
  return 2.5;
}

Object? maybeNull() {
  return null;
}

String label(String name) {
  return 'hello $name!';
}

String displayName(User user) {
  return user.label;
}

User makeUser() {
  return User('patched', 'patched-label');
}

Config makeConfig() {
  return Config(name: 'patched', label: 'patched-label');
}

Box<String> makeStringBox() {
  return Box<String>('patched-box');
}

String dynamicNamedCall() {
  return Greeter().surround('patched', prefix: '<', suffix: '>');
}

String capturedGreeting(String name) {
  final prefix = 'patched';
  return (() => '$prefix $name')();
}

String storedClosureGreeting(String name) {
  final prefix = 'patched';
  final format = () => '$prefix $name';
  return format();
}

String stableTearOffLabel() {
  return 'stable-tear-off';
}

String Function() topLevelTearOff() {
  return stableTearOffLabel;
}

String Function() escapingGreeting(String name) {
  final prefix = 'patched';
  return () => '$prefix $name';
}

String Function() storedEscapingGreeting(String name) {
  final prefix = 'patched';
  final format = () => '$prefix $name';
  return format;
}

String Function(String) personalizedEscapingGreeting(String name) {
  final prefix = 'patched';
  return (suffix) => '$prefix $name $suffix';
}

String Function({required String suffix}) namedEscapingGreeting(String name) {
  final prefix = 'patched';
  return ({required suffix}) => '$prefix $name $suffix';
}

String Function([String? suffix]) optionalPositionalEscapingGreeting(String name) {
  final prefix = 'patched';
  return ([suffix]) => '$prefix $name $suffix';
}

String Function({String? suffix}) optionalNamedEscapingGreeting(String name) {
  final prefix = 'patched';
  return ({suffix}) => '$prefix $name $suffix';
}

String Function<T>(T) genericEscapingGreeting(String name) {
  final prefix = 'patched';
  return <T>(value) => '$prefix $name $value';
}

String Function() localFunctionEscapingGreeting(String name) {
  final prefix = 'patched';
  String format() {
    return '$prefix $name';
  }
  return format;
}

String Function() bodyLocalEscapingGreeting(String name) {
  final prefix = 'patched';
  return () {
    final suffix = 'body';
    return '$prefix $name $suffix';
  };
}

String Function(bool) tryCatchEscapingGreeting(String name) {
  final prefix = 'patched';
  return (fail) {
    try {
      return fail ? throw '$prefix-boom' : '$prefix-ok';
    } catch (e) {
      return '$prefix-caught $e';
    }
  };
}

String Function(String) dynamicCallEscapingGreeting(String name) {
  final greeter = Greeter();
  return (suffix) => greeter.surround(name, prefix: 'patched-', suffix: suffix);
}

String Function(bool, bool) logicalEscapingGreeting(String name) {
  final prefix = 'patched';
  return (enabled, premium) =>
      enabled && (premium || name == 'vip') || !enabled
      ? '$prefix $name pro'
      : '$prefix $name basic';
}

String Function(bool) ifElseEscapingGreeting(String name) {
  final prefix = 'patched';
  return (enabled) {
    if (enabled) {
      return '$prefix $name enabled';
    }
    return '$prefix $name disabled';
  };
}

String Function(bool) bodyLocalIfElseEscapingGreeting(String name) {
  final prefix = 'patched';
  return (enabled) {
    final suffix = 'body';
    if (enabled) {
      return '$prefix $name $suffix enabled';
    }
    return '$prefix $name $suffix disabled';
  };
}

String Function(bool) branchLocalIfElseEscapingGreeting(String name) {
  final prefix = 'patched';
  return (enabled) {
    if (enabled) {
      final status = 'branch-enabled';
      return '$prefix $name $status';
    } else {
      final status = 'branch-disabled';
      return '$prefix $name $status';
    }
  };
}

String useCallback(String Function() callback) {
  return callback();
}

String passedEscapingGreeting(String name) {
  final prefix = 'patched';
  return useCallback(() => '$prefix $name');
}

String recoverFromThrow(bool fail) {
  try {
    return fail ? throw 'patched-boom' : 'patched-ok';
  } catch (e) {
    return 'patched-caught $e';
  }
}

String alwaysThrow() {
  return throw 'patched-boom';
}

Future<String> asyncLabel() async {
  return 'patched-async';
}

Future<String> awaitedLabel(bool enabled) async { if (await Future.value(enabled)) return 'patched ${await Future.value('awaited')}'; return 'patched disabled'; }

Future<String> awaitedLocalLabel(String name) async { try { final base = 'patched-local'; final prefix = await Future.value(base); if (name == 'Ada') return '$prefix ${await Future.value('done')}'; return '$prefix $name'; } catch (e) { return 'patched-caught $e'; } }
List<String> names(bool enabled, bool premium) {
  return ['patched', ...['spread-a', 'spread-b'], for (final value in ['for-a', 'for-b']) value, if (enabled) 'live' else 'off', if (premium) 'pro', 'tail'];
}

List<String> dynamicNames(List<String> extra) {
  return ['patched', ...extra];
}

List<String> runtimeForNames(List<String> extra) {
  return ['patched', for (final value in extra) value];
}

Map<String, String> labels(bool enabled, bool premium) {
  return {'mode': 'patched', ...{'spread': 'yes'}, for (final entry in {'for': 'yes'}.entries) entry.key: entry.value, if (enabled) 'state': 'live' else 'state': 'off', if (premium) 'tier': 'pro', 'tail': 'done'};
}

Map<String, String> dynamicLabels(Map<String, String> extra) {
  return {'mode': 'patched', ...extra};
}

Map<String, String> runtimeForLabels(Map<String, String> extra) {
  return {'mode': 'patched', for (final entry in extra.entries) entry.key: entry.value};
}

String chooseLabel(bool enabled) {
  return enabled ? 'patched-live' : 'patched-off';
}

bool isKnown(Object value) {
  return value is String;
}

bool isUser(Object value) {
  return value is User;
}

bool isStringList(Object value) {
  return value is List<String>;
}

Object asStringList(Object value) {
  return value as List<String>;
}

bool isCallable(Object value) {
  return value is String Function();
}

bool isRecord(Object value) {
  return value is (String, int);
}

double mainValue() {
  return helper() + 1.5 + 1.5;
}

void main() {
  mainValue();
}
DART

cat >"$WORKDIR/wrappers/fcb_entry.dart" <<'DART'
import 'package:fcb_kernel_compile_test/main.dart';
void main() {}
DART

"$DART_BIN" compile kernel \
  --no-link-platform \
  --packages="$WORKDIR/project/.dart_tool/package_config.json" \
  -o "$WORKDIR/patch.dill" \
  "$WORKDIR/wrappers/fcb_entry.dart" >/dev/null

"$DART_BIN" "$ROOT_DIR/tool/fcb_kernel_manifest.dart" \
  --project "$WORKDIR/project" \
  --target lib/main.dart \
  --dill "$WORKDIR/patch.dill" \
  >"$WORKDIR/patch_inventory.json"

python3 - "$WORKDIR/release_inventory.json" "$WORKDIR/patch_inventory.json" "$WORKDIR/plan.json" <<'PY'
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

if len(plan["interpret"]) != 42:
    raise SystemExit(f"expected 42 interpreted functions, got {len(plan['interpret'])}")
if len(plan["reject"]) != 2:
    raise SystemExit(f"expected two rejected functions, got {plan['reject']}")

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

expected_rejects = {
    "isCallable": "function_type_unsupported",
    "isRecord": "record_type_unsupported",
}
patch_by_member = {f.get("member_name"): f for f in patch["functions"]}
plan_rejects = {item["function_id"]: item["reject_reason"] for item in plan["reject"]}
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
awaited = patch_by_member.get("awaitedLabel", {}).get("bytecode_source", {})
if awaited.get("body", {}).get("new_object", {}).get("constructor") != "dart:async::class:_Future.value":
    raise SystemExit(f"expected awaitedLabel _Future.value source, got {awaited}")
awaited_local = patch_by_member.get("awaitedLocalLabel", {}).get("bytecode_source", {})
awaited_local_let = awaited_local.get("body", {}).get("new_object", {}).get("args", [{}])[0].get("try_catch", {}).get("body", {}).get("let", {})
if len(awaited_local_let.get("locals", [])) != 2 or awaited_local_let.get("body", {}).get("conditional") is None:
    raise SystemExit(f"expected awaitedLocalLabel try/catch mixed-local if-return source, got {awaited_local}")

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

json.dump(plan, open(sys.argv[3], "w"))
PY

"$DART_BIN" "$ROOT_DIR/tool/fcb_kernel_manifest.dart" \
  --project "$WORKDIR/project" \
  --target lib/main.dart \
  --compile-from-plan "$WORKDIR/plan.json" \
  --patch "$WORKDIR/patch.dill" \
  -o "$WORKDIR/module.fcbm"

"$DART_BIN" "$ROOT_DIR/tool/fcb_kernel_manifest.dart" \
  --project "$WORKDIR/project" \
  --target lib/main.dart \
  --compile-from-plan "$WORKDIR/plan.json" \
  --patch "$WORKDIR/patch.dill" \
  --format binary \
  -o "$WORKDIR/module.bin"

python3 - "$WORKDIR/module.fcbm" <<'PY'
import json
import sys

module = json.load(open(sys.argv[1]))
assert module["version"] == 2, module
assert len(module["functions"]) == 57, module
function = next(
    item for item in module["functions"] if item["name"].endswith("::mainValue")
)
assert function["code"][-1] == 255, function
assert 0x50 in function["code"], function
source_map = function.get("source_map")
assert isinstance(source_map, list) and len(source_map) == 1, function
assert source_map[0]["bytecode_offset"] == 0, source_map
assert isinstance(source_map[0]["source_location"], str), source_map
assert source_map[0]["source_location"].strip(), source_map
assert any(
    constant.get("type") == "String" and "helper" in constant.get("value", "")
    for constant in function["constants"]
), function
async_label = next(
    item for item in module["functions"] if item["name"].endswith("::asyncLabel")
)
assert 0x55 in async_label["code"], async_label
assert any(
    constant.get("type") == "String"
    and constant.get("value") == "dart:async::class:_Future.value;types:String"
    for constant in async_label["constants"]
), async_label
assert any(
    constant.get("type") == "String" and constant.get("value") == "patched-async"
    for constant in async_label["constants"]
), async_label
awaited_label = next(
    item for item in module["functions"] if item["name"].endswith("::awaitedLabel")
)
assert 0x55 in awaited_label["code"] and 0x42 in awaited_label["code"] and 0x31 in awaited_label["code"], awaited_label
assert {"slot": 0, "name": "enabled"} in awaited_label.get("debug_locals", []), awaited_label
awaited_local = next(item for item in module["functions"] if item["name"].endswith("::awaitedLocalLabel"))
assert 0x55 in awaited_local["code"] and awaited_local["code"].count(0x04) >= 2 and 0x31 in awaited_local["code"] and 0x42 in awaited_local["code"] and 0x61 in awaited_local["code"], awaited_local
awaited_local_debug_names = {
    entry.get("name") for entry in awaited_local.get("debug_locals", [])
}
assert {"name", "base", "prefix"}.issubset(awaited_local_debug_names), awaited_local
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
label = next(item for item in module["functions"] if item["name"].endswith("::label"))
assert label["param_count"] == 1, label
assert 0x42 in label["code"], label
assert any(
    constant.get("type") == "String" and constant.get("value") == "hello "
    for constant in label["constants"]
), label
assert any(
    constant.get("type") == "String" and constant.get("value") == "!"
    for constant in label["constants"]
), label
display = next(item for item in module["functions"] if item["name"].endswith("::displayName"))
assert display["param_count"] == 1, display
assert 0x43 in display["code"], display
assert any(
    constant.get("type") == "String" and constant.get("value") == "label"
    for constant in display["constants"]
), display
is_known = next(item for item in module["functions"] if item["name"].endswith("::isKnown"))
assert is_known["param_count"] == 1, is_known
assert 0x45 in is_known["code"], is_known
assert any(
    constant.get("type") == "String" and constant.get("value") == "String"
    for constant in is_known["constants"]
), is_known
is_user = next(item for item in module["functions"] if item["name"].endswith("::isUser"))
assert is_user["param_count"] == 1, is_user
assert 0x45 in is_user["code"], is_user
assert any(
    constant.get("type") == "String" and constant.get("value") == "package:fcb_kernel_compile_test/main.dart::User"
    for constant in is_user["constants"]
), is_user
is_string_list = next(item for item in module["functions"] if item["name"].endswith("::isStringList"))
assert is_string_list["param_count"] == 1, is_string_list
assert 0x45 in is_string_list["code"], is_string_list
assert any(
    constant.get("type") == "String" and constant.get("value") == "List<String>"
    for constant in is_string_list["constants"]
), is_string_list
as_string_list = next(item for item in module["functions"] if item["name"].endswith("::asStringList"))
assert as_string_list["param_count"] == 1, as_string_list
assert 0x46 in as_string_list["code"], as_string_list
assert any(
    constant.get("type") == "String" and constant.get("value") == "List<String>"
    for constant in as_string_list["constants"]
), as_string_list
make_user = next(item for item in module["functions"] if item["name"].endswith("::makeUser"))
assert make_user["param_count"] == 0, make_user
assert 0x55 in make_user["code"], make_user
assert any(
    constant.get("type") == "String" and constant.get("value") == "package:fcb_kernel_compile_test/main.dart::class:User."
    for constant in make_user["constants"]
), make_user
make_config = next(item for item in module["functions"] if item["name"].endswith("::makeConfig"))
assert make_config["param_count"] == 0, make_config
assert 0x55 in make_config["code"], make_config
assert any(
    constant.get("type") == "String" and constant.get("value") == "package:fcb_kernel_compile_test/main.dart::class:Config.;named:name,label"
    for constant in make_config["constants"]
), make_config
make_string_box = next(item for item in module["functions"] if item["name"].endswith("::makeStringBox"))
assert make_string_box["param_count"] == 0, make_string_box
assert 0x55 in make_string_box["code"], make_string_box
assert any(
    constant.get("type") == "String" and constant.get("value") == "package:fcb_kernel_compile_test/main.dart::class:Box.;types:String"
    for constant in make_string_box["constants"]
), make_string_box
dynamic_named_call = next(item for item in module["functions"] if item["name"].endswith("::dynamicNamedCall"))
assert dynamic_named_call["param_count"] == 0, dynamic_named_call
assert 0x55 in dynamic_named_call["code"], dynamic_named_call
assert 0x51 in dynamic_named_call["code"], dynamic_named_call
assert any(
    constant.get("type") == "String" and constant.get("value") == "package:fcb_kernel_compile_test/main.dart::class:Greeter."
    for constant in dynamic_named_call["constants"]
), dynamic_named_call
assert any(
    constant.get("type") == "String" and constant.get("value") == "surround;named:prefix,suffix"
    for constant in dynamic_named_call["constants"]
), dynamic_named_call
for value in ["patched", "<", ">"]:
    assert any(
        constant.get("type") == "String" and constant.get("value") == value
        for constant in dynamic_named_call["constants"]
    ), dynamic_named_call
captured_greeting = next(item for item in module["functions"] if item["name"].endswith("::capturedGreeting"))
assert captured_greeting["param_count"] == 1, captured_greeting
assert 0x42 in captured_greeting["code"], captured_greeting
assert 0x03 in captured_greeting["code"], captured_greeting
assert 0x04 in captured_greeting["code"], captured_greeting
assert any(
    constant.get("type") == "String" and constant.get("value") == "patched"
    for constant in captured_greeting["constants"]
), captured_greeting
stored_closure_greeting = next(item for item in module["functions"] if item["name"].endswith("::storedClosureGreeting"))
assert stored_closure_greeting["param_count"] == 1, stored_closure_greeting
assert 0x42 in stored_closure_greeting["code"], stored_closure_greeting
assert 0x03 in stored_closure_greeting["code"], stored_closure_greeting
assert 0x04 in stored_closure_greeting["code"], stored_closure_greeting
assert any(
    constant.get("type") == "String" and constant.get("value") == "patched"
    for constant in stored_closure_greeting["constants"]
), stored_closure_greeting
passed_escaping_greeting = next(item for item in module["functions"] if item["name"].endswith("::passedEscapingGreeting"))
assert passed_escaping_greeting["param_count"] == 1, passed_escaping_greeting
assert 0x42 in passed_escaping_greeting["code"], passed_escaping_greeting
assert 0x03 in passed_escaping_greeting["code"], passed_escaping_greeting
assert 0x04 in passed_escaping_greeting["code"], passed_escaping_greeting
assert any(
    constant.get("type") == "String" and constant.get("value") == "patched"
    for constant in passed_escaping_greeting["constants"]
), passed_escaping_greeting
escaping_greeting = next(item for item in module["functions"] if item["name"].endswith("::escapingGreeting"))
assert escaping_greeting["param_count"] == 1, escaping_greeting
assert 0x54 in escaping_greeting["code"], escaping_greeting
assert 0x03 in escaping_greeting["code"], escaping_greeting
assert 0x04 in escaping_greeting["code"], escaping_greeting
assert any(
    constant.get("type") == "String" and constant.get("value") == "patched"
    for constant in escaping_greeting["constants"]
), escaping_greeting
assert any(
    constant.get("type") == "String" and constant.get("value", "").endswith("::escapingGreeting.<closure0>();captures:2")
    for constant in escaping_greeting["constants"]
), escaping_greeting
escaping_closure = next(item for item in module["functions"] if item["name"].endswith("::escapingGreeting.<closure0>()"))
assert escaping_closure["param_count"] == 2, escaping_closure
assert 0x42 in escaping_closure["code"], escaping_closure
stored_escaping_greeting = next(item for item in module["functions"] if item["name"].endswith("::storedEscapingGreeting"))
assert stored_escaping_greeting["param_count"] == 1, stored_escaping_greeting
assert 0x54 in stored_escaping_greeting["code"], stored_escaping_greeting
assert 0x03 in stored_escaping_greeting["code"], stored_escaping_greeting
assert 0x04 in stored_escaping_greeting["code"], stored_escaping_greeting
assert any(
    constant.get("type") == "String" and constant.get("value") == "patched"
    for constant in stored_escaping_greeting["constants"]
), stored_escaping_greeting
assert any(
    constant.get("type") == "String" and constant.get("value", "").endswith("::storedEscapingGreeting.<closure0>();captures:2")
    for constant in stored_escaping_greeting["constants"]
), stored_escaping_greeting
stored_escaping_closure = next(item for item in module["functions"] if item["name"].endswith("::storedEscapingGreeting.<closure0>()"))
assert stored_escaping_closure["param_count"] == 2, stored_escaping_closure
assert 0x42 in stored_escaping_closure["code"], stored_escaping_closure
personalized_escaping_greeting = next(item for item in module["functions"] if item["name"].endswith("::personalizedEscapingGreeting"))
assert personalized_escaping_greeting["param_count"] == 1, personalized_escaping_greeting
assert 0x54 in personalized_escaping_greeting["code"], personalized_escaping_greeting
assert 0x03 in personalized_escaping_greeting["code"], personalized_escaping_greeting
assert 0x04 in personalized_escaping_greeting["code"], personalized_escaping_greeting
assert any(
    constant.get("type") == "String" and constant.get("value") == "patched"
    for constant in personalized_escaping_greeting["constants"]
), personalized_escaping_greeting
assert any(
    constant.get("type") == "String" and constant.get("value", "").endswith("::personalizedEscapingGreeting.<closure0>();captures:2")
    for constant in personalized_escaping_greeting["constants"]
), personalized_escaping_greeting
personalized_escaping_closure = next(item for item in module["functions"] if item["name"].endswith("::personalizedEscapingGreeting.<closure0>()"))
assert personalized_escaping_closure["param_count"] == 3, personalized_escaping_closure
assert 0x42 in personalized_escaping_closure["code"], personalized_escaping_closure
named_escaping_greeting = next(item for item in module["functions"] if item["name"].endswith("::namedEscapingGreeting"))
assert named_escaping_greeting["param_count"] == 1, named_escaping_greeting
assert 0x54 in named_escaping_greeting["code"], named_escaping_greeting
assert 0x03 in named_escaping_greeting["code"], named_escaping_greeting
assert 0x04 in named_escaping_greeting["code"], named_escaping_greeting
assert any(
    constant.get("type") == "String" and constant.get("value") == "patched"
    for constant in named_escaping_greeting["constants"]
), named_escaping_greeting
assert any(
    constant.get("type") == "String" and constant.get("value", "").endswith("::namedEscapingGreeting.<closure0>();captures:2;named:suffix")
    for constant in named_escaping_greeting["constants"]
), named_escaping_greeting
named_escaping_closure = next(item for item in module["functions"] if item["name"].endswith("::namedEscapingGreeting.<closure0>()"))
assert named_escaping_closure["param_count"] == 3, named_escaping_closure
assert 0x42 in named_escaping_closure["code"], named_escaping_closure
optional_positional_escaping_greeting = next(item for item in module["functions"] if item["name"].endswith("::optionalPositionalEscapingGreeting"))
assert optional_positional_escaping_greeting["param_count"] == 1, optional_positional_escaping_greeting
assert 0x54 in optional_positional_escaping_greeting["code"], optional_positional_escaping_greeting
assert 0x03 in optional_positional_escaping_greeting["code"], optional_positional_escaping_greeting
assert 0x04 in optional_positional_escaping_greeting["code"], optional_positional_escaping_greeting
assert any(
    constant.get("type") == "String" and constant.get("value") == "patched"
    for constant in optional_positional_escaping_greeting["constants"]
), optional_positional_escaping_greeting
assert any(
    constant.get("type") == "String" and constant.get("value", "").endswith("::optionalPositionalEscapingGreeting.<closure0>();captures:2;optional-pos:1")
    for constant in optional_positional_escaping_greeting["constants"]
), optional_positional_escaping_greeting
optional_positional_escaping_closure = next(item for item in module["functions"] if item["name"].endswith("::optionalPositionalEscapingGreeting.<closure0>()"))
assert optional_positional_escaping_closure["param_count"] == 3, optional_positional_escaping_closure
assert 0x42 in optional_positional_escaping_closure["code"], optional_positional_escaping_closure
optional_named_escaping_greeting = next(item for item in module["functions"] if item["name"].endswith("::optionalNamedEscapingGreeting"))
assert optional_named_escaping_greeting["param_count"] == 1, optional_named_escaping_greeting
assert 0x54 in optional_named_escaping_greeting["code"], optional_named_escaping_greeting
assert 0x03 in optional_named_escaping_greeting["code"], optional_named_escaping_greeting
assert 0x04 in optional_named_escaping_greeting["code"], optional_named_escaping_greeting
assert any(
    constant.get("type") == "String" and constant.get("value") == "patched"
    for constant in optional_named_escaping_greeting["constants"]
), optional_named_escaping_greeting
assert any(
    constant.get("type") == "String" and constant.get("value", "").endswith("::optionalNamedEscapingGreeting.<closure0>();captures:2;named:?suffix")
    for constant in optional_named_escaping_greeting["constants"]
), optional_named_escaping_greeting
optional_named_escaping_closure = next(item for item in module["functions"] if item["name"].endswith("::optionalNamedEscapingGreeting.<closure0>()"))
assert optional_named_escaping_closure["param_count"] == 3, optional_named_escaping_closure
assert 0x42 in optional_named_escaping_closure["code"], optional_named_escaping_closure
generic_escaping_greeting = next(item for item in module["functions"] if item["name"].endswith("::genericEscapingGreeting"))
assert generic_escaping_greeting["param_count"] == 1, generic_escaping_greeting
assert 0x54 in generic_escaping_greeting["code"], generic_escaping_greeting
assert any(
    constant.get("type") == "String" and constant.get("value", "").endswith("::genericEscapingGreeting.<closure0>();captures:2;type-params:1")
    for constant in generic_escaping_greeting["constants"]
), generic_escaping_greeting
generic_escaping_closure = next(item for item in module["functions"] if item["name"].endswith("::genericEscapingGreeting.<closure0>()"))
assert generic_escaping_closure["param_count"] == 3, generic_escaping_closure
assert 0x42 in generic_escaping_closure["code"], generic_escaping_closure
local_function_escaping_greeting = next(item for item in module["functions"] if item["name"].endswith("::localFunctionEscapingGreeting"))
assert local_function_escaping_greeting["param_count"] == 1, local_function_escaping_greeting
assert 0x54 in local_function_escaping_greeting["code"], local_function_escaping_greeting
assert 0x03 in local_function_escaping_greeting["code"], local_function_escaping_greeting
assert 0x04 in local_function_escaping_greeting["code"], local_function_escaping_greeting
assert any(
    constant.get("type") == "String" and constant.get("value") == "patched"
    for constant in local_function_escaping_greeting["constants"]
), local_function_escaping_greeting
assert any(
    constant.get("type") == "String" and constant.get("value", "").endswith("::localFunctionEscapingGreeting.<closure0>();captures:2")
    for constant in local_function_escaping_greeting["constants"]
), local_function_escaping_greeting
local_function_escaping_closure = next(item for item in module["functions"] if item["name"].endswith("::localFunctionEscapingGreeting.<closure0>()"))
assert local_function_escaping_closure["param_count"] == 2, local_function_escaping_closure
assert 0x42 in local_function_escaping_closure["code"], local_function_escaping_closure
body_local_escaping_greeting = next(item for item in module["functions"] if item["name"].endswith("::bodyLocalEscapingGreeting"))
assert body_local_escaping_greeting["param_count"] == 1, body_local_escaping_greeting
assert 0x54 in body_local_escaping_greeting["code"], body_local_escaping_greeting
assert 0x03 in body_local_escaping_greeting["code"], body_local_escaping_greeting
assert 0x04 in body_local_escaping_greeting["code"], body_local_escaping_greeting
assert any(
    constant.get("type") == "String" and constant.get("value") == "patched"
    for constant in body_local_escaping_greeting["constants"]
), body_local_escaping_greeting
assert any(
    constant.get("type") == "String" and constant.get("value", "").endswith("::bodyLocalEscapingGreeting.<closure0>();captures:2")
    for constant in body_local_escaping_greeting["constants"]
), body_local_escaping_greeting
body_local_escaping_closure = next(item for item in module["functions"] if item["name"].endswith("::bodyLocalEscapingGreeting.<closure0>()"))
assert body_local_escaping_closure["param_count"] == 2, body_local_escaping_closure
assert 0x42 in body_local_escaping_closure["code"], body_local_escaping_closure
assert 0x03 in body_local_escaping_closure["code"], body_local_escaping_closure
assert 0x04 in body_local_escaping_closure["code"], body_local_escaping_closure
assert any(
    constant.get("type") == "String" and constant.get("value") == "body"
    for constant in body_local_escaping_closure["constants"]
), body_local_escaping_closure
try_catch_escaping_greeting = next(item for item in module["functions"] if item["name"].endswith("::tryCatchEscapingGreeting"))
assert try_catch_escaping_greeting["param_count"] == 1, try_catch_escaping_greeting
assert 0x54 in try_catch_escaping_greeting["code"], try_catch_escaping_greeting
assert 0x03 in try_catch_escaping_greeting["code"], try_catch_escaping_greeting
assert 0x04 in try_catch_escaping_greeting["code"], try_catch_escaping_greeting
assert any(
    constant.get("type") == "String" and constant.get("value", "").endswith("::tryCatchEscapingGreeting.<closure0>();captures:1")
    for constant in try_catch_escaping_greeting["constants"]
), try_catch_escaping_greeting
try_catch_escaping_closure = next(item for item in module["functions"] if item["name"].endswith("::tryCatchEscapingGreeting.<closure0>()"))
assert try_catch_escaping_closure["param_count"] == 2, try_catch_escaping_closure
assert 0x61 in try_catch_escaping_closure["code"], try_catch_escaping_closure
assert 0x60 in try_catch_escaping_closure["code"], try_catch_escaping_closure
assert 0x31 in try_catch_escaping_closure["code"], try_catch_escaping_closure
assert 0x30 in try_catch_escaping_closure["code"], try_catch_escaping_closure
assert 0x03 in try_catch_escaping_closure["code"], try_catch_escaping_closure
assert 0x04 in try_catch_escaping_closure["code"], try_catch_escaping_closure
assert any(
    constant.get("type") == "String" and constant.get("value") == "-boom"
    for constant in try_catch_escaping_closure["constants"]
), try_catch_escaping_closure
assert any(
    constant.get("type") == "String" and constant.get("value") == "-caught "
    for constant in try_catch_escaping_closure["constants"]
), try_catch_escaping_closure
dynamic_call_escaping_greeting = next(item for item in module["functions"] if item["name"].endswith("::dynamicCallEscapingGreeting"))
assert dynamic_call_escaping_greeting["param_count"] == 1, dynamic_call_escaping_greeting
assert 0x55 in dynamic_call_escaping_greeting["code"], dynamic_call_escaping_greeting
assert 0x54 in dynamic_call_escaping_greeting["code"], dynamic_call_escaping_greeting
assert 0x03 in dynamic_call_escaping_greeting["code"], dynamic_call_escaping_greeting
assert 0x04 in dynamic_call_escaping_greeting["code"], dynamic_call_escaping_greeting
assert any(
    constant.get("type") == "String" and constant.get("value") == "package:fcb_kernel_compile_test/main.dart::class:Greeter."
    for constant in dynamic_call_escaping_greeting["constants"]
), dynamic_call_escaping_greeting
assert any(
    constant.get("type") == "String" and constant.get("value", "").endswith("::dynamicCallEscapingGreeting.<closure0>();captures:2")
    for constant in dynamic_call_escaping_greeting["constants"]
), dynamic_call_escaping_greeting
dynamic_call_escaping_closure = next(item for item in module["functions"] if item["name"].endswith("::dynamicCallEscapingGreeting.<closure0>()"))
assert dynamic_call_escaping_closure["param_count"] == 3, dynamic_call_escaping_closure
assert 0x51 in dynamic_call_escaping_closure["code"], dynamic_call_escaping_closure
assert any(
    constant.get("type") == "String" and constant.get("value") == "surround;named:prefix,suffix"
    for constant in dynamic_call_escaping_closure["constants"]
), dynamic_call_escaping_closure
assert any(
    constant.get("type") == "String" and constant.get("value") == "patched-"
    for constant in dynamic_call_escaping_closure["constants"]
), dynamic_call_escaping_closure
logical_escaping_greeting = next(item for item in module["functions"] if item["name"].endswith("::logicalEscapingGreeting"))
assert logical_escaping_greeting["param_count"] == 1, logical_escaping_greeting
assert 0x54 in logical_escaping_greeting["code"], logical_escaping_greeting
assert 0x03 in logical_escaping_greeting["code"], logical_escaping_greeting
assert 0x04 in logical_escaping_greeting["code"], logical_escaping_greeting
assert any(
    constant.get("type") == "String" and constant.get("value", "").endswith("::logicalEscapingGreeting.<closure0>();captures:2")
    for constant in logical_escaping_greeting["constants"]
), logical_escaping_greeting
logical_escaping_closure = next(item for item in module["functions"] if item["name"].endswith("::logicalEscapingGreeting.<closure0>()"))
assert logical_escaping_closure["param_count"] == 4, logical_escaping_closure
assert logical_escaping_closure["code"].count(0x31) >= 4, logical_escaping_closure
assert 0x30 in logical_escaping_closure["code"], logical_escaping_closure
assert 0x42 in logical_escaping_closure["code"], logical_escaping_closure
assert 0x21 in logical_escaping_closure["code"], logical_escaping_closure
for value in ["vip", " pro", " basic"]:
    assert any(
        constant.get("type") == "String" and constant.get("value") == value
        for constant in logical_escaping_closure["constants"]
    ), logical_escaping_closure
assert any(
    constant.get("type") == "Bool" and constant.get("value") == True
    for constant in logical_escaping_closure["constants"]
), logical_escaping_closure
assert any(
    constant.get("type") == "Bool" and constant.get("value") == False
    for constant in logical_escaping_closure["constants"]
), logical_escaping_closure
if_else_escaping_greeting = next(item for item in module["functions"] if item["name"].endswith("::ifElseEscapingGreeting"))
assert if_else_escaping_greeting["param_count"] == 1, if_else_escaping_greeting
assert 0x54 in if_else_escaping_greeting["code"], if_else_escaping_greeting
assert 0x03 in if_else_escaping_greeting["code"], if_else_escaping_greeting
assert 0x04 in if_else_escaping_greeting["code"], if_else_escaping_greeting
assert any(
    constant.get("type") == "String" and constant.get("value", "").endswith("::ifElseEscapingGreeting.<closure0>();captures:2")
    for constant in if_else_escaping_greeting["constants"]
), if_else_escaping_greeting
if_else_escaping_closure = next(item for item in module["functions"] if item["name"].endswith("::ifElseEscapingGreeting.<closure0>()"))
assert if_else_escaping_closure["param_count"] == 3, if_else_escaping_closure
assert 0x31 in if_else_escaping_closure["code"], if_else_escaping_closure
assert 0x30 in if_else_escaping_closure["code"], if_else_escaping_closure
assert 0x42 in if_else_escaping_closure["code"], if_else_escaping_closure
for value in [" enabled", " disabled"]:
    assert any(
        constant.get("type") == "String" and constant.get("value") == value
        for constant in if_else_escaping_closure["constants"]
    ), if_else_escaping_closure
body_local_if_else_escaping_greeting = next(item for item in module["functions"] if item["name"].endswith("::bodyLocalIfElseEscapingGreeting"))
assert body_local_if_else_escaping_greeting["param_count"] == 1, body_local_if_else_escaping_greeting
assert 0x54 in body_local_if_else_escaping_greeting["code"], body_local_if_else_escaping_greeting
assert 0x03 in body_local_if_else_escaping_greeting["code"], body_local_if_else_escaping_greeting
assert 0x04 in body_local_if_else_escaping_greeting["code"], body_local_if_else_escaping_greeting
assert any(
    constant.get("type") == "String" and constant.get("value", "").endswith("::bodyLocalIfElseEscapingGreeting.<closure0>();captures:2")
    for constant in body_local_if_else_escaping_greeting["constants"]
), body_local_if_else_escaping_greeting
body_local_if_else_escaping_closure = next(item for item in module["functions"] if item["name"].endswith("::bodyLocalIfElseEscapingGreeting.<closure0>()"))
assert body_local_if_else_escaping_closure["param_count"] == 3, body_local_if_else_escaping_closure
assert 0x31 in body_local_if_else_escaping_closure["code"], body_local_if_else_escaping_closure
assert 0x30 in body_local_if_else_escaping_closure["code"], body_local_if_else_escaping_closure
assert 0x42 in body_local_if_else_escaping_closure["code"], body_local_if_else_escaping_closure
assert 0x03 in body_local_if_else_escaping_closure["code"], body_local_if_else_escaping_closure
assert 0x04 in body_local_if_else_escaping_closure["code"], body_local_if_else_escaping_closure
for value in ["body", " enabled", " disabled"]:
    assert any(
        constant.get("type") == "String" and constant.get("value") == value
        for constant in body_local_if_else_escaping_closure["constants"]
    ), body_local_if_else_escaping_closure
branch_local_if_else_escaping_greeting = next(item for item in module["functions"] if item["name"].endswith("::branchLocalIfElseEscapingGreeting"))
assert branch_local_if_else_escaping_greeting["param_count"] == 1, branch_local_if_else_escaping_greeting
assert 0x54 in branch_local_if_else_escaping_greeting["code"], branch_local_if_else_escaping_greeting
assert 0x03 in branch_local_if_else_escaping_greeting["code"], branch_local_if_else_escaping_greeting
assert 0x04 in branch_local_if_else_escaping_greeting["code"], branch_local_if_else_escaping_greeting
assert any(
    constant.get("type") == "String" and constant.get("value", "").endswith("::branchLocalIfElseEscapingGreeting.<closure0>();captures:2")
    for constant in branch_local_if_else_escaping_greeting["constants"]
), branch_local_if_else_escaping_greeting
branch_local_if_else_escaping_closure = next(item for item in module["functions"] if item["name"].endswith("::branchLocalIfElseEscapingGreeting.<closure0>()"))
assert branch_local_if_else_escaping_closure["param_count"] == 3, branch_local_if_else_escaping_closure
assert 0x31 in branch_local_if_else_escaping_closure["code"], branch_local_if_else_escaping_closure
assert 0x30 in branch_local_if_else_escaping_closure["code"], branch_local_if_else_escaping_closure
assert 0x42 in branch_local_if_else_escaping_closure["code"], branch_local_if_else_escaping_closure
assert branch_local_if_else_escaping_closure["code"].count(0x03) >= 2, branch_local_if_else_escaping_closure
assert branch_local_if_else_escaping_closure["code"].count(0x04) >= 2, branch_local_if_else_escaping_closure
for value in ["branch-enabled", "branch-disabled"]:
    assert any(
        constant.get("type") == "String" and constant.get("value") == value
        for constant in branch_local_if_else_escaping_closure["constants"]
    ), branch_local_if_else_escaping_closure
top_level_tear_off = next(item for item in module["functions"] if item["name"].endswith("::topLevelTearOff"))
assert top_level_tear_off["param_count"] == 0, top_level_tear_off
assert 0x54 in top_level_tear_off["code"], top_level_tear_off
assert any(
    constant.get("type") == "String" and constant.get("value") == "package:fcb_kernel_compile_test/main.dart::stableTearOffLabel"
    for constant in top_level_tear_off["constants"]
), top_level_tear_off
recover_from_throw = next(item for item in module["functions"] if item["name"].endswith("::recoverFromThrow"))
assert recover_from_throw["param_count"] == 1, recover_from_throw
assert 0x61 in recover_from_throw["code"], recover_from_throw
assert 0x60 in recover_from_throw["code"], recover_from_throw
assert 0x31 in recover_from_throw["code"], recover_from_throw
assert 0x30 in recover_from_throw["code"], recover_from_throw
assert 0x03 in recover_from_throw["code"], recover_from_throw
assert 0x04 in recover_from_throw["code"], recover_from_throw
assert any(
    constant.get("type") == "String" and constant.get("value") == "patched-boom"
    for constant in recover_from_throw["constants"]
), recover_from_throw
assert any(
    constant.get("type") == "String" and constant.get("value") == "patched-caught "
    for constant in recover_from_throw["constants"]
), recover_from_throw
always_throw = next(item for item in module["functions"] if item["name"].endswith("::alwaysThrow"))
assert always_throw["param_count"] == 0, always_throw
assert 0x60 in always_throw["code"], always_throw
assert any(
    constant.get("type") == "String" and constant.get("value") == "patched-boom"
    for constant in always_throw["constants"]
), always_throw
names = next(item for item in module["functions"] if item["name"].endswith("::names"))
assert names["param_count"] == 2, names
assert 0x40 in names["code"], names
assert 0x31 in names["code"], names
assert 0x30 in names["code"], names
assert names["code"].count(0x31) >= 2, names
assert any(
    constant.get("type") == "String" and constant.get("value") == "patched"
    for constant in names["constants"]
), names
assert any(
    constant.get("type") == "String" and constant.get("value") == "tail"
    for constant in names["constants"]
), names
assert any(
    constant.get("type") == "String" and constant.get("value") == "spread-a"
    for constant in names["constants"]
), names
assert any(
    constant.get("type") == "String" and constant.get("value") == "spread-b"
    for constant in names["constants"]
), names
assert any(
    constant.get("type") == "String" and constant.get("value") == "for-a"
    for constant in names["constants"]
), names
assert any(
    constant.get("type") == "String" and constant.get("value") == "for-b"
    for constant in names["constants"]
), names
assert any(
    constant.get("type") == "String" and constant.get("value") == "off"
    for constant in names["constants"]
), names
assert any(
    constant.get("type") == "String" and constant.get("value") == "pro"
    for constant in names["constants"]
), names
labels = next(item for item in module["functions"] if item["name"].endswith("::labels"))
assert labels["param_count"] == 2, labels
assert 0x41 in labels["code"], labels
assert 0x31 in labels["code"], labels
assert 0x30 in labels["code"], labels
assert labels["code"].count(0x31) >= 2, labels
assert any(
    constant.get("type") == "String" and constant.get("value") == "mode"
    for constant in labels["constants"]
), labels
assert any(
    constant.get("type") == "String" and constant.get("value") == "tail"
    for constant in labels["constants"]
), labels
assert any(
    constant.get("type") == "String" and constant.get("value") == "spread"
    for constant in labels["constants"]
), labels
assert any(
    constant.get("type") == "String" and constant.get("value") == "yes"
    for constant in labels["constants"]
), labels
assert any(
    constant.get("type") == "String" and constant.get("value") == "for"
    for constant in labels["constants"]
), labels
assert any(
    constant.get("type") == "String" and constant.get("value") == "off"
    for constant in labels["constants"]
), labels
assert any(
    constant.get("type") == "String" and constant.get("value") == "tier"
    for constant in labels["constants"]
), labels
dynamic_names = next(item for item in module["functions"] if item["name"].endswith("::dynamicNames"))
assert dynamic_names["param_count"] == 1, dynamic_names
assert 0x40 in dynamic_names["code"], dynamic_names
assert 0x51 in dynamic_names["code"], dynamic_names
assert 0x03 in dynamic_names["code"], dynamic_names
assert 0x04 in dynamic_names["code"], dynamic_names
assert any(
    constant.get("type") == "String" and constant.get("value") == "addAll"
    for constant in dynamic_names["constants"]
), dynamic_names
runtime_for_names = next(item for item in module["functions"] if item["name"].endswith("::runtimeForNames"))
assert runtime_for_names["param_count"] == 1, runtime_for_names
assert 0x40 in runtime_for_names["code"], runtime_for_names
assert 0x51 in runtime_for_names["code"], runtime_for_names
assert 0x03 in runtime_for_names["code"], runtime_for_names
assert 0x04 in runtime_for_names["code"], runtime_for_names
assert 0x31 in runtime_for_names["code"], runtime_for_names
assert 0x30 in runtime_for_names["code"], runtime_for_names
for value in ["get:iterator", "moveNext", "get:current", "add"]:
    assert any(
        constant.get("type") == "String" and constant.get("value") == value
        for constant in runtime_for_names["constants"]
    ), runtime_for_names
dynamic_labels = next(item for item in module["functions"] if item["name"].endswith("::dynamicLabels"))
assert dynamic_labels["param_count"] == 1, dynamic_labels
assert 0x41 in dynamic_labels["code"], dynamic_labels
assert 0x51 in dynamic_labels["code"], dynamic_labels
assert 0x03 in dynamic_labels["code"], dynamic_labels
assert 0x04 in dynamic_labels["code"], dynamic_labels
assert any(
    constant.get("type") == "String" and constant.get("value") == "addAll"
    for constant in dynamic_labels["constants"]
), dynamic_labels
runtime_for_labels = next(item for item in module["functions"] if item["name"].endswith("::runtimeForLabels"))
assert runtime_for_labels["param_count"] == 1, runtime_for_labels
assert 0x41 in runtime_for_labels["code"], runtime_for_labels
assert 0x51 in runtime_for_labels["code"], runtime_for_labels
assert 0x03 in runtime_for_labels["code"], runtime_for_labels
assert 0x04 in runtime_for_labels["code"], runtime_for_labels
assert 0x31 in runtime_for_labels["code"], runtime_for_labels
assert 0x30 in runtime_for_labels["code"], runtime_for_labels
for value in ["get:entries", "get:iterator", "moveNext", "get:current", "get:key", "get:value", "[]="]:
    assert any(
        constant.get("type") == "String" and constant.get("value") == value
        for constant in runtime_for_labels["constants"]
    ), runtime_for_labels
choose_label = next(item for item in module["functions"] if item["name"].endswith("::chooseLabel"))
assert choose_label["param_count"] == 1, choose_label
assert 0x31 in choose_label["code"], choose_label
assert 0x30 in choose_label["code"], choose_label
assert any(
    constant.get("type") == "String" and constant.get("value") == "patched-live"
    for constant in choose_label["constants"]
), choose_label
assert any(
    constant.get("type") == "String" and constant.get("value") == "patched-off"
    for constant in choose_label["constants"]
), choose_label
print("kernel compile-from-plan drill passed")
PY

python3 - "$WORKDIR/module.bin" <<'PY'
import struct
import sys

data = open(sys.argv[1], "rb").read()
assert data[:4] == b"FCBM", data[:4]
version = struct.unpack(">I", data[4:8])[0]
function_count = struct.unpack(">H", data[8:10])[0]
assert version == 2, version
assert function_count == 57, function_count
assert b"\x50" in data, data
assert b"\x40" in data, data
assert b"\x41" in data, data
assert b"\x42" in data, data
assert b"\x43" in data, data
assert b"\x45" in data, data
assert b"\x55" in data, data
assert b"\x54" in data, data
assert b"\x60" in data, data
assert b"\x61" in data, data
assert b"\x51" in data, data
assert b"\x03" in data, data
assert b"\x04" in data, data
assert b"\x31" in data, data
assert b"\x30" in data, data
assert b"enabled" in data, data
assert b"prefix" in data, data
print("kernel binary compile-from-plan drill passed")
PY
