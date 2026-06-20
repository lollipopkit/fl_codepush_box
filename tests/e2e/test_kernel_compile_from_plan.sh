#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
if [ -z "${DART_BIN:-}" ] && [ -x "/Users/lk/env/flutter/bin/cache/dart-sdk/bin/dart" ]; then
  DART_BIN="/Users/lk/env/flutter/bin/cache/dart-sdk/bin/dart"
else
  DART_BIN="${DART_BIN:-dart}"
fi
FCB_RUN_VM_TESTS="${FCB_RUN_VM_TESTS:-$ROOT_DIR/vendor/flutter/engine/src/out/host_release_arm64/run_vm_tests}"
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

bool sameObject(Object value) {
  return false;
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

Future<void> awaitedVoid(Future<void> ready) async {
  await ready;
  final marker = 'base-void';
}

Future<void> awaitedReturnVoid(Future<void> ready) async {
  await ready;
  final marker = 'base-return-void';
  return;
}

Future<String> awaitedLabel(bool enabled) async { if (await Future.value(enabled)) return 'base ${await Future.value('awaited')}'; return 'base disabled'; }

Future<String> awaitedLocalLabel(String name) async { try { final base = 'base-local'; final prefix = await Future.value(base); if (name == 'Ada') return '$prefix ${await Future.value('done')}'; return '$prefix $name'; } catch (e) { return 'base-caught $e'; } }

Future<String> awaitedFutureParam(Future<String> value) async {
  return 'base ${await value}';
}

Future<String> awaitedStatement(Future<String> ready) async {
  await ready;
  return 'base-after-await-statement';
}

Future<String> awaitedStatementLocal(Future<String> ready) async {
  await ready;
  final marker = 'base-after-await-local';
  return marker;
}

Future<String> awaitedTryStatementLocal(Future<String> ready) async {
  try {
    await ready;
    final marker = 'base-after-try-await-local';
    return marker;
  } catch (e) {
    return 'base-try-caught $e';
  }
}

Future<String> awaitedCatchLocal(Future<String> ready) async {
  try {
    await ready;
    return 'base-catch-local-ok';
  } catch (e) {
    final message = 'base-catch-local $e';
    return message;
  }
}

Future<String> awaitedCatchAwait(Future<String> ready) async {
  try {
    await ready;
    return 'base-catch-await-ok';
  } catch (e) {
    return await Future.value('base-catch-await $e');
  }
}

Future<String> awaitedFinallyLocal(Future<String> ready) async {
  try {
    final value = await ready;
    return 'base-finally-$value';
  } finally {
    final cleanup = 'base-finally-cleanup';
  }
}

Future<String> awaitedFinallyCleanup(
  Future<String> ready,
  Future<String> cleanup,
) async {
  try {
    final value = await ready;
    return 'base-finally-cleanup-$value';
  } finally {
    await cleanup;
  }
}

Future<String> asyncBranchLocal(bool enabled) async {
  if (enabled) {
    final status = 'base-branch-enabled';
    return status;
  } else {
    final status = 'base-branch-disabled';
    return status;
  }
}

Future<String> asyncGuardAwaitTail(bool enabled, Future<String> ready) async {
  if (enabled) return 'base-guard-fast';
  await ready;
  return 'base-guard-tail';
}

Future<int> asyncIntInput() {
  return Future.value(1);
}

Future<int> plannedAsyncAwait() async {
  final x = await asyncIntInput();
  if (x > 0) return x + 1;
  return 0;
}

Future<String> asyncWhileLocal(int limit) async {
  var i = 0;
  var out = 'base-while';
  while (limit > i) {
    out = '$out-$i';
    i = i + 1;
  }
  return out;
}

Future<String> asyncWhileBreak(int limit) async {
  var i = 0;
  var out = 'base-while-break';
  while (limit > i) {
    out = '$out-$i';
    if (i == 1) break;
    i = i + 1;
  }
  return out;
}

Future<String> asyncWhileContinue(int limit) async {
  var i = 0;
  var out = 'base-while-continue';
  while (limit > i) {
    out = '$out-before-$i';
    if (i == 1) {
      i = i + 1;
      continue;
    }
    out = '$out-after-$i';
    i = i + 1;
  }
  return out;
}

Future<String> asyncForLocal(int limit) async {
  var out = 'base-for';
  for (var i = 0; limit > i; i = i + 1) {
    out = '$out-$i';
  }
  return out;
}

Future<String> asyncForContinue(int limit) async {
  var out = 'base-for-continue';
  for (var i = 0; limit > i; i = i + 1) {
    out = '$out-before-$i';
    if (i == 1) continue;
    out = '$out-after-$i';
  }
  return out;
}

Future<String> asyncForBreak(int limit) async {
  var out = 'base-for-break';
  for (var i = 0; limit > i; i = i + 1) {
    out = '$out-before-$i';
    if (i == 1) break;
    out = '$out-after-$i';
  }
  return out;
}

Future<String> asyncForContinueBreak(int limit) async {
  var out = 'base-for-continue-break';
  for (var i = 0; limit > i; i = i + 1) {
    out = '$out-before-$i';
    if (i == 1) continue;
    out = '$out-mid-$i';
    if (i == 2) break;
    out = '$out-after-$i';
  }
  return out;
}

Stream<String> asyncGenerated() async* {
  yield 'base-stream';
}

Stream<String> asyncGeneratedAwait(Future<String> ready) async* {
  final value = await ready;
  yield 'base-stream-await-$value';
}

Stream<String> asyncGeneratedTryFinally(Future<String> ready) async* {
  try {
    yield await ready;
  } finally {
    final cleanup = 'base-stream-finally-cleanup';
  }
}

Stream<String> asyncGeneratedFinallyYield(Future<String> ready) async* {
  yield 'base-stream-finally-yield';
}

Stream<String> asyncGeneratedCatchAwait(Future<String> ready) async* {
  yield 'base-stream-catch-await';
}

Stream<String> asyncGeneratedMany(bool enabled) async* {
  final prefix = 'base-stream';
  yield '$prefix-a';
  if (enabled) yield '$prefix-live';
  yield '$prefix-tail';
}

Stream<String> asyncGeneratedWhile() async* {
  var i = 0;
  while (2 > i) {
    yield 'base-stream-while-$i';
    i = i + 1;
  }
}

Stream<String> asyncGeneratedWhileBreak() async* {
  var i = 0;
  while (4 > i) {
    yield 'base-stream-while-break-before-$i';
    if (i == 2) break;
    yield 'base-stream-while-break-after-$i';
    i = i + 1;
  }
}

Stream<String> asyncGeneratedWhileContinue() async* {
  var i = 0;
  while (3 > i) {
    yield 'base-stream-while-continue-before-$i';
    if (i == 1) {
      i = i + 1;
      continue;
    }
    yield 'base-stream-while-continue-after-$i';
    i = i + 1;
  }
}

Stream<String> asyncGeneratedWhileContinueBreak() async* {
  var i = 0;
  while (4 > i) {
    yield 'base-stream-while-continue-before-$i';
    if (i == 1) {
      i = i + 1;
      continue;
    }
    yield 'base-stream-while-continue-mid-$i';
    if (i == 2) break;
    yield 'base-stream-while-continue-after-$i';
    i = i + 1;
  }
}

Stream<String> asyncGeneratedDoWhile() async* {
  var i = 0;
  do {
    yield 'base-stream-do-$i';
    i = i + 1;
  } while (2 > i);
}

Stream<String> asyncGeneratedDoWhileBreak() async* {
  var i = 0;
  do {
    yield 'base-stream-do-break-before-$i';
    if (i == 1) break;
    yield 'base-stream-do-break-after-$i';
    i = i + 1;
  } while (3 > i);
}

Stream<String> asyncGeneratedDoWhileContinue() async* {
  var i = 0;
  do {
    yield 'base-stream-do-continue-before-$i';
    if (i == 1) {
      i = i + 1;
      continue;
    }
    yield 'base-stream-do-continue-after-$i';
    i = i + 1;
  } while (3 > i);
}

Stream<String> asyncGeneratedDoWhileContinueBreak() async* {
  var i = 0;
  do {
    yield 'base-stream-do-continue-before-$i';
    if (i == 1) {
      i = i + 1;
      continue;
    }
    yield 'base-stream-do-continue-mid-$i';
    if (i == 2) break;
    yield 'base-stream-do-continue-after-$i';
    i = i + 1;
  } while (4 > i);
}

Stream<String> asyncGeneratedForLoop() async* {
  for (var i = 0; 2 > i; i = i + 1) {
    yield 'base-stream-for-$i';
  }
}

Stream<String> asyncGeneratedForLoopPostIncrement() async* {
  for (var i = 0; 2 > i; i++) {
    yield 'base-stream-for-postinc-$i';
  }
}

Stream<String> asyncGeneratedForLoopMultiUpdate() async* {
  for (var i = 0, j = 10; 2 > i; i = i + 1, j = j + 1) {
    yield 'base-stream-for-multi-$i-$j';
  }
}

Stream<String> asyncGeneratedForLoopExternalLocal() async* {
  var i = 0;
  for (; 2 > i; i = i + 1) {
    yield 'base-stream-for-external-$i';
  }
}

Stream<String> asyncGeneratedForLoopBodyUpdate() async* {
  var i = 0;
  for (; 2 > i;) {
    yield 'base-stream-for-body-update-$i';
    i = i + 1;
  }
}

Stream<String> asyncGeneratedForLoopContinue() async* {
  for (var i = 0; 3 > i; i = i + 1) {
    yield 'base-stream-for-continue-before-$i';
    if (i == 1) continue;
    yield 'base-stream-for-continue-after-$i';
  }
}

Stream<String> asyncGeneratedForLoopContinueBreak() async* {
  for (var i = 0; 4 > i; i = i + 1) {
    yield 'base-stream-for-continue-before-$i';
    if (i == 1) continue;
    yield 'base-stream-for-continue-mid-$i';
    if (i == 2) break;
    yield 'base-stream-for-continue-after-$i';
  }
}

Stream<String> asyncGeneratedForLoopBreak() async* {
  for (var i = 0; 3 > i; i = i + 1) {
    yield 'base-stream-for-break-before-$i';
    if (i == 1) break;
    yield 'base-stream-for-break-after-$i';
  }
}

Stream<String> asyncGeneratedForIn() async* {
  for (final value in ['base-stream-a', 'base-stream-b']) {
    yield value;
  }
}

Stream<String> asyncGeneratedForInBreak() async* {
  final prefix = 'base-stream-static-break';
  for (final value in ['a', 'stop', 'tail']) {
    yield '$prefix-before-$value';
    if (value == 'stop') break;
    yield '$prefix-after-$value';
  }
}

Stream<String> asyncGeneratedForInBreakFirst() async* {
  final prefix = 'base-stream-static-break-first';
  for (final value in ['a', 'stop', 'tail']) {
    if (value == 'stop') break;
    yield '$prefix-$value';
  }
}

Stream<String> asyncGeneratedForInContinue() async* {
  final prefix = 'base-stream-static-continue';
  for (final value in ['a', 'skip', 'tail']) {
    if (value == 'skip') continue;
    yield '$prefix-$value';
  }
}

Stream<String> asyncGeneratedForInContinueAfterYield() async* {
  final prefix = 'base-stream-static-continue-after-yield';
  for (final value in ['a', 'skip', 'tail']) {
    yield '$prefix-before-$value';
    if (value == 'skip') continue;
    yield '$prefix-after-$value';
  }
}

Stream<String> asyncGeneratedDynamicForIn(List<String> extra) async* {
  for (final value in extra) {
    yield value;
  }
  yield 'base-stream-dynamic-tail';
}

Stream<String> asyncGeneratedDynamicForInMapped(List<String> extra) async* {
  final prefix = 'base-stream-map';
  for (final value in extra) {
    yield '$prefix-$value';
  }
}

Stream<String> asyncGeneratedDynamicForInMany(List<String> extra) async* {
  final prefix = 'base-stream-many';
  for (final value in extra) {
    yield '$prefix-a-$value';
    yield '$prefix-b-$value';
  }
}

Stream<String> asyncGeneratedDynamicForInIf(List<String> extra) async* {
  final prefix = 'base-stream-if';
  for (final value in extra) {
    if (value == 'live') yield '$prefix-hit-$value';
    yield '$prefix-tail-$value';
  }
}

Stream<String> asyncGeneratedDynamicForInIfElse(List<String> extra) async* {
  final prefix = 'base-stream-ifelse';
  for (final value in extra) {
    if (value == 'live') {
      yield '$prefix-hit-$value';
    } else {
      yield '$prefix-miss-$value';
    }
  }
}

Stream<String> asyncGeneratedDynamicForInLocal(List<String> extra) async* {
  final prefix = 'base-stream-local';
  for (final value in extra) {
    final marker = '$prefix-$value';
    yield marker;
  }
}

Stream<String> asyncGeneratedDynamicForInContinue(List<String> extra) async* {
  final prefix = 'base-stream-continue';
  for (final value in extra) {
    if (value == 'skip') continue;
    yield '$prefix-$value';
  }
}

Stream<String> asyncGeneratedDynamicForInContinueAfterYield(List<String> extra) async* {
  final prefix = 'base-stream-continue-after-yield';
  for (final value in extra) {
    yield '$prefix-before-$value';
    if (value == 'skip') continue;
    yield '$prefix-after-$value';
  }
}

Stream<String> asyncGeneratedDynamicForInBreak(List<String> extra) async* {
  final prefix = 'base-stream-break';
  for (final value in extra) {
    if (value == 'stop') break;
    yield '$prefix-$value';
  }
}

Stream<String> asyncGeneratedDynamicForInBreakAfterYield(List<String> extra) async* {
  final prefix = 'base-stream-break-after-yield';
  for (final value in extra) {
    yield '$prefix-before-$value';
    if (value == 'stop') break;
    yield '$prefix-after-$value';
  }
}

Stream<String> asyncGeneratedDynamicForInBreakAtEnd(List<String> extra) async* {
  final prefix = 'base-stream-break-at-end';
  for (final value in extra) {
    yield '$prefix-before-$value';
    if (value == 'stop') break;
  }
}

Stream<String> asyncGeneratedDynamicForInContinueThenBreak(List<String> extra) async* {
  final prefix = 'base-stream-continue-break';
  for (final value in extra) {
    if (value == 'skip') continue;
    if (value == 'stop') break;
    yield '$prefix-$value';
  }
}

Stream<String> asyncGeneratedDynamicForInContinueYieldBreak(List<String> extra) async* {
  final prefix = 'base-stream-continue-yield-break';
  for (final value in extra) {
    if (value == 'skip') continue;
    yield '$prefix-before-$value';
    if (value == 'stop') break;
    yield '$prefix-after-$value';
  }
}

Stream<String> asyncGeneratedDynamicForInNested(
  List<String> extra,
  List<String> suffixes,
) async* {
  final prefix = 'base-stream-nested';
  for (final value in extra) {
    for (final suffix in suffixes) {
      yield '$prefix-$value-$suffix';
    }
  }
}

Stream<String> asyncGeneratedYieldStar() async* {
  yield* Stream.fromIterable([
    'base-stream-yield-star-a',
    'base-stream-yield-star-b',
  ]);
}

Stream<String> asyncGeneratedYieldStarDynamic(List<String> extra) async* {
  yield* Stream.fromIterable(extra);
  yield 'base-stream-yield-star-dynamic-tail';
}

Stream<String> asyncGeneratedYieldStarValue(String value) async* {
  yield* Stream.value('base-stream-yield-star-value-$value');
}

Stream<String> asyncGeneratedYieldStarFromFuture(String value) async* {
  yield* Stream.fromFuture(Future.value('base-stream-yield-star-future-$value'));
}

Stream<String> asyncGeneratedYieldStarPendingFuture(
  Future<String> ready,
) async* {
  yield* Stream.value('base-stream-yield-star-pending');
}

Stream<String> asyncGeneratedYieldStarEmpty() async* {
  yield 'base-stream-yield-star-empty-before';
  yield* Stream<String>.empty();
}

Stream<String> asyncGeneratedAwaitForFromIterable(List<String> extra) async* {
  await for (final value in Stream.fromIterable(extra)) {
    yield 'base-stream-await-for-iterable-$value';
  }
}

Stream<String> asyncGeneratedAwaitForContinue(List<String> extra) async* {
  await for (final value in Stream.fromIterable(extra)) {
    if (value == 'skip') continue;
    yield 'base-stream-await-for-continue-$value';
  }
}

Stream<String> asyncGeneratedAwaitForBreak(List<String> extra) async* {
  await for (final value in Stream.fromIterable(extra)) {
    if (value == 'stop') break;
    yield 'base-stream-await-for-break-$value';
  }
}

Stream<String> asyncGeneratedAwaitForValue(String value) async* {
  await for (final item in Stream.value(value)) {
    yield 'base-stream-await-for-value-$item';
  }
}

Stream<String> asyncGeneratedAwaitForFuture(String value) async* {
  await for (final item in Stream.fromFuture(Future.value(value))) {
    yield 'base-stream-await-for-future-$item';
  }
}

Stream<String> asyncGeneratedAwaitForFutureBreak(String value) async* {
  await for (final item in Stream.fromFuture(Future.value(value))) {
    if (item == 'stop') break;
    yield 'base-stream-await-for-future-break-$item';
  }
}

Stream<String> asyncGeneratedAwaitForPendingFuture(Future<String> ready) async* {
  await for (final item in Stream.fromFuture(ready)) {
    yield 'base-stream-await-for-pending-future-$item';
  }
}

Stream<String> asyncGeneratedAwaitForPendingContinue(
  Future<String> ready,
) async* {
  await for (final item in Stream.fromFuture(ready)) {
    if (item == 'skip') continue;
    yield 'base-stream-await-for-pending-continue-$item';
  }
}

Stream<String> asyncGeneratedAwaitForEmpty() async* {
  await for (final item in Stream<String>.empty()) {
    yield 'base-stream-await-for-empty-$item';
  }
}

Stream<String> asyncGeneratedYieldStarStream(Stream<String> extra) async* {
  yield 'base-stream-yield-star-stream';
}

Stream<String> asyncGeneratedYieldStarStreamFinally(Stream<String> extra) async* {
  yield 'base-stream-yield-star-stream-finally';
}

Stream<String> asyncGeneratedYieldStarStreamSandwichFinally(
  Stream<String> extra,
) async* {
  yield 'base-stream-yield-star-stream-sandwich-finally';
}

Stream<String> asyncGeneratedYieldStarTwoStreamsFinally(
  Stream<String> first,
  Stream<String> second,
) async* {
  yield 'base-stream-yield-star-two-streams-finally';
}

Stream<String> asyncGeneratedAwaitFor(Stream<String> extra) async* {
  yield 'base-stream-await-for';
}

Stream<String> asyncGeneratedAwaitForFinally(Stream<String> extra) async* {
  yield 'base-stream-await-for-finally';
}

Stream<String> asyncGeneratedAwaitForStreamContinue(Stream<String> extra) async* {
  yield 'base-stream-await-for-stream-continue';
}

Stream<String> asyncGeneratedAwaitForStreamBreak(Stream<String> extra) async* {
  yield 'base-stream-await-for-stream-break';
}

Stream<String> asyncGeneratedAwaitForStreamContinueBreakFinally(
  Stream<String> extra,
) async* {
  yield 'base-stream-await-for-stream-continue-break-finally';
}

Stream<String> asyncGeneratedAwaitForNestedValueFinally(
  Stream<String> extra,
) async* {
  yield 'base-stream-await-for-nested-value-finally';
}

Stream<String> asyncGeneratedAwaitForNestedStreamFinally(
  Stream<String> outer,
  Stream<String> inner,
) async* {
  yield 'base-stream-await-for-nested-stream-finally';
}

Iterable<String> syncGenerated() sync* {
  yield 'base-iterable';
}

Iterable<String> syncGeneratedMany(bool enabled) sync* {
  final prefix = 'base-iterable';
  yield '$prefix-a';
  if (enabled) yield '$prefix-live';
  yield '$prefix-tail';
}

Iterable<String> syncGeneratedWhile() sync* {
  var i = 0;
  while (2 > i) {
    yield 'base-iterable-while-$i';
    i = i + 1;
  }
}

Iterable<String> syncGeneratedWhileBreak() sync* {
  var i = 0;
  while (4 > i) {
    yield 'base-iterable-while-break-before-$i';
    if (i == 2) break;
    yield 'base-iterable-while-break-after-$i';
    i = i + 1;
  }
}

Iterable<String> syncGeneratedWhileContinue() sync* {
  var i = 0;
  while (3 > i) {
    yield 'base-iterable-while-continue-before-$i';
    if (i == 1) {
      i = i + 1;
      continue;
    }
    yield 'base-iterable-while-continue-after-$i';
    i = i + 1;
  }
}

Iterable<String> syncGeneratedWhileContinueBreak() sync* {
  var i = 0;
  while (4 > i) {
    yield 'base-iterable-while-continue-before-$i';
    if (i == 1) {
      i = i + 1;
      continue;
    }
    yield 'base-iterable-while-continue-mid-$i';
    if (i == 2) break;
    yield 'base-iterable-while-continue-after-$i';
    i = i + 1;
  }
}

Iterable<String> syncGeneratedDoWhile() sync* {
  var i = 0;
  do {
    yield 'base-iterable-do-$i';
    i = i + 1;
  } while (2 > i);
}

Iterable<String> syncGeneratedDoWhileBreak() sync* {
  var i = 0;
  do {
    yield 'base-iterable-do-break-before-$i';
    if (i == 1) break;
    yield 'base-iterable-do-break-after-$i';
    i = i + 1;
  } while (3 > i);
}

Iterable<String> syncGeneratedDoWhileContinue() sync* {
  var i = 0;
  do {
    yield 'base-iterable-do-continue-before-$i';
    if (i == 1) {
      i = i + 1;
      continue;
    }
    yield 'base-iterable-do-continue-after-$i';
    i = i + 1;
  } while (3 > i);
}

Iterable<String> syncGeneratedDoWhileContinueBreak() sync* {
  var i = 0;
  do {
    yield 'base-iterable-do-continue-before-$i';
    if (i == 1) {
      i = i + 1;
      continue;
    }
    yield 'base-iterable-do-continue-mid-$i';
    if (i == 2) break;
    yield 'base-iterable-do-continue-after-$i';
    i = i + 1;
  } while (4 > i);
}

Iterable<String> syncGeneratedForLoop() sync* {
  for (var i = 0; 2 > i; i = i + 1) {
    yield 'base-iterable-for-$i';
  }
}

Iterable<String> syncGeneratedForLoopPostIncrement() sync* {
  for (var i = 0; 2 > i; i++) {
    yield 'base-iterable-for-postinc-$i';
  }
}

Iterable<String> syncGeneratedForLoopMultiUpdate() sync* {
  for (var i = 0, j = 10; 2 > i; i = i + 1, j = j + 1) {
    yield 'base-iterable-for-multi-$i-$j';
  }
}

Iterable<String> syncGeneratedForLoopExternalLocal() sync* {
  var i = 0;
  for (; 2 > i; i = i + 1) {
    yield 'base-iterable-for-external-$i';
  }
}

Iterable<String> syncGeneratedForLoopBodyUpdate() sync* {
  var i = 0;
  for (; 2 > i;) {
    yield 'base-iterable-for-body-update-$i';
    i = i + 1;
  }
}

Iterable<String> syncGeneratedForLoopContinue() sync* {
  for (var i = 0; 3 > i; i = i + 1) {
    yield 'base-iterable-for-continue-before-$i';
    if (i == 1) continue;
    yield 'base-iterable-for-continue-after-$i';
  }
}

Iterable<String> syncGeneratedForLoopContinueBreak() sync* {
  for (var i = 0; 4 > i; i = i + 1) {
    yield 'base-iterable-for-continue-before-$i';
    if (i == 1) continue;
    yield 'base-iterable-for-continue-mid-$i';
    if (i == 2) break;
    yield 'base-iterable-for-continue-after-$i';
  }
}

Iterable<String> syncGeneratedForLoopBreak() sync* {
  for (var i = 0; 3 > i; i = i + 1) {
    yield 'base-iterable-for-break-before-$i';
    if (i == 1) break;
    yield 'base-iterable-for-break-after-$i';
  }
}

Iterable<String> syncGeneratedForIn() sync* {
  for (final value in ['base-iterable-a', 'base-iterable-b']) {
    yield value;
  }
}

Iterable<String> syncGeneratedForInBreak() sync* {
  final prefix = 'base-iterable-static-break';
  for (final value in ['a', 'stop', 'tail']) {
    yield '$prefix-before-$value';
    if (value == 'stop') break;
    yield '$prefix-after-$value';
  }
}

Iterable<String> syncGeneratedForInBreakFirst() sync* {
  final prefix = 'base-iterable-static-break-first';
  for (final value in ['a', 'stop', 'tail']) {
    if (value == 'stop') break;
    yield '$prefix-$value';
  }
}

Iterable<String> syncGeneratedForInContinue() sync* {
  final prefix = 'base-iterable-static-continue';
  for (final value in ['a', 'skip', 'tail']) {
    if (value == 'skip') continue;
    yield '$prefix-$value';
  }
}

Iterable<String> syncGeneratedForInContinueAfterYield() sync* {
  final prefix = 'base-iterable-static-continue-after-yield';
  for (final value in ['a', 'skip', 'tail']) {
    yield '$prefix-before-$value';
    if (value == 'skip') continue;
    yield '$prefix-after-$value';
  }
}

Iterable<String> syncGeneratedDynamicForIn(List<String> extra) sync* {
  for (final value in extra) {
    yield value;
  }
  yield 'base-iterable-dynamic-tail';
}

Iterable<String> syncGeneratedDynamicForInMapped(List<String> extra) sync* {
  final prefix = 'base-iterable-map';
  for (final value in extra) {
    yield '$prefix-$value';
  }
}

Iterable<String> syncGeneratedDynamicForInMany(List<String> extra) sync* {
  final prefix = 'base-iterable-many';
  for (final value in extra) {
    yield '$prefix-a-$value';
    yield '$prefix-b-$value';
  }
}

Iterable<String> syncGeneratedDynamicForInIf(List<String> extra) sync* {
  final prefix = 'base-iterable-if';
  for (final value in extra) {
    if (value == 'live') yield '$prefix-hit-$value';
    yield '$prefix-tail-$value';
  }
}

Iterable<String> syncGeneratedDynamicForInIfElse(List<String> extra) sync* {
  final prefix = 'base-iterable-ifelse';
  for (final value in extra) {
    if (value == 'live') {
      yield '$prefix-hit-$value';
    } else {
      yield '$prefix-miss-$value';
    }
  }
}

Iterable<String> syncGeneratedDynamicForInLocal(List<String> extra) sync* {
  final prefix = 'base-iterable-local';
  for (final value in extra) {
    final marker = '$prefix-$value';
    yield marker;
  }
}

Iterable<String> syncGeneratedDynamicForInContinue(List<String> extra) sync* {
  final prefix = 'base-iterable-continue';
  for (final value in extra) {
    if (value == 'skip') continue;
    yield '$prefix-$value';
  }
}

Iterable<String> syncGeneratedDynamicForInContinueAfterYield(List<String> extra) sync* {
  final prefix = 'base-iterable-continue-after-yield';
  for (final value in extra) {
    yield '$prefix-before-$value';
    if (value == 'skip') continue;
    yield '$prefix-after-$value';
  }
}

Iterable<String> syncGeneratedDynamicForInBreak(List<String> extra) sync* {
  final prefix = 'base-iterable-break';
  for (final value in extra) {
    if (value == 'stop') break;
    yield '$prefix-$value';
  }
}

Iterable<String> syncGeneratedDynamicForInBreakAfterYield(List<String> extra) sync* {
  final prefix = 'base-iterable-break-after-yield';
  for (final value in extra) {
    yield '$prefix-before-$value';
    if (value == 'stop') break;
    yield '$prefix-after-$value';
  }
}

Iterable<String> syncGeneratedDynamicForInBreakAtEnd(List<String> extra) sync* {
  final prefix = 'base-iterable-break-at-end';
  for (final value in extra) {
    yield '$prefix-before-$value';
    if (value == 'stop') break;
  }
}

Iterable<String> syncGeneratedDynamicForInContinueThenBreak(List<String> extra) sync* {
  final prefix = 'base-iterable-continue-break';
  for (final value in extra) {
    if (value == 'skip') continue;
    if (value == 'stop') break;
    yield '$prefix-$value';
  }
}

Iterable<String> syncGeneratedDynamicForInContinueYieldBreak(List<String> extra) sync* {
  final prefix = 'base-iterable-continue-yield-break';
  for (final value in extra) {
    if (value == 'skip') continue;
    yield '$prefix-before-$value';
    if (value == 'stop') break;
    yield '$prefix-after-$value';
  }
}

Iterable<String> syncGeneratedDynamicForInNested(
  List<String> extra,
  List<String> suffixes,
) sync* {
  final prefix = 'base-iterable-nested';
  for (final value in extra) {
    for (final suffix in suffixes) {
      yield '$prefix-$value-$suffix';
    }
  }
}

Iterable<String> syncGeneratedYieldStar() sync* {
  yield* ['base-yield-star-a', 'base-yield-star-b'];
}

Iterable<String> syncGeneratedYieldStarDynamic(List<String> extra) sync* {
  yield* extra;
  yield 'base-yield-star-dynamic-tail';
}

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

bool sameObject(Object value) {
  return identical(value, value);
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

Future<void> awaitedVoid(Future<void> ready) async {
  await ready;
  final marker = 'patched-void';
}

Future<void> awaitedReturnVoid(Future<void> ready) async {
  await ready;
  final marker = 'patched-return-void';
  return;
}

Future<String> awaitedLabel(bool enabled) async { if (await Future.value(enabled)) return 'patched ${await Future.value('awaited')}'; return 'patched disabled'; }

Future<String> awaitedLocalLabel(String name) async { try { final base = 'patched-local'; final prefix = await Future.value(base); if (name == 'Ada') return '$prefix ${await Future.value('done')}'; return '$prefix $name'; } catch (e) { return 'patched-caught $e'; } }

Future<String> awaitedFutureParam(Future<String> value) async {
  return 'patched ${await value}';
}

Future<String> awaitedStatement(Future<String> ready) async {
  await ready;
  return 'patched-after-await-statement';
}

Future<String> awaitedStatementLocal(Future<String> ready) async {
  await ready;
  final marker = 'patched-after-await-local';
  return marker;
}

Future<String> awaitedTryStatementLocal(Future<String> ready) async {
  try {
    await ready;
    final marker = 'patched-after-try-await-local';
    return marker;
  } catch (e) {
    return 'patched-try-caught $e';
  }
}

Future<String> awaitedCatchLocal(Future<String> ready) async {
  try {
    await ready;
    return 'patched-catch-local-ok';
  } catch (e) {
    final message = 'patched-catch-local $e';
    return message;
  }
}

Future<String> awaitedCatchAwait(Future<String> ready) async {
  try {
    await ready;
    return 'patched-catch-await-ok';
  } catch (e) {
    return await Future.value('patched-catch-await $e');
  }
}

Future<String> awaitedFinallyLocal(Future<String> ready) async {
  try {
    final value = await ready;
    return 'patched-finally-$value';
  } finally {
    final cleanup = 'patched-finally-cleanup';
  }
}

Future<String> awaitedFinallyCleanup(
  Future<String> ready,
  Future<String> cleanup,
) async {
  try {
    final value = await ready;
    return 'patched-finally-cleanup-$value';
  } finally {
    await cleanup;
  }
}

Future<String> asyncBranchLocal(bool enabled) async {
  if (enabled) {
    final status = 'patched-branch-enabled';
    return status;
  } else {
    final status = 'patched-branch-disabled';
    return status;
  }
}

Future<String> asyncGuardAwaitTail(bool enabled, Future<String> ready) async {
  if (enabled) return 'patched-guard-fast';
  await ready;
  return 'patched-guard-tail';
}

Future<int> asyncIntInput() {
  return Future.value(1);
}

Future<int> plannedAsyncAwait() async {
  final x = await asyncIntInput();
  if (x > 0) return x + 2;
  return 0;
}

Future<String> asyncWhileLocal(int limit) async {
  var i = 0;
  var out = 'patched-while';
  while (limit > i) {
    out = '$out-$i';
    i = i + 1;
  }
  return out;
}

Future<String> asyncWhileBreak(int limit) async {
  var i = 0;
  var out = 'patched-while-break';
  while (limit > i) {
    out = '$out-$i';
    if (i == 1) break;
    i = i + 1;
  }
  return out;
}

Future<String> asyncWhileContinue(int limit) async {
  var i = 0;
  var out = 'patched-while-continue';
  while (limit > i) {
    out = '$out-before-$i';
    if (i == 1) {
      i = i + 1;
      continue;
    }
    out = '$out-after-$i';
    i = i + 1;
  }
  return out;
}

Future<String> asyncForLocal(int limit) async {
  var out = 'patched-for';
  for (var i = 0; limit > i; i = i + 1) {
    out = '$out-$i';
  }
  return out;
}

Future<String> asyncForContinue(int limit) async {
  var out = 'patched-for-continue';
  for (var i = 0; limit > i; i = i + 1) {
    out = '$out-before-$i';
    if (i == 1) continue;
    out = '$out-after-$i';
  }
  return out;
}

Future<String> asyncForBreak(int limit) async {
  var out = 'patched-for-break';
  for (var i = 0; limit > i; i = i + 1) {
    out = '$out-before-$i';
    if (i == 1) break;
    out = '$out-after-$i';
  }
  return out;
}

Future<String> asyncForContinueBreak(int limit) async {
  var out = 'patched-for-continue-break';
  for (var i = 0; limit > i; i = i + 1) {
    out = '$out-before-$i';
    if (i == 1) continue;
    out = '$out-mid-$i';
    if (i == 2) break;
    out = '$out-after-$i';
  }
  return out;
}

Stream<String> asyncGenerated() async* {
  yield 'patched-stream';
}

Stream<String> asyncGeneratedAwait(Future<String> ready) async* {
  final value = await ready;
  yield 'patched-stream-await-$value';
}

Stream<String> asyncGeneratedTryFinally(Future<String> ready) async* {
  try {
    yield await ready;
  } finally {
    final cleanup = 'patched-stream-finally-cleanup';
  }
}

Stream<String> asyncGeneratedFinallyYield(Future<String> ready) async* {
  try {
    yield await ready;
  } finally {
    yield 'patched-stream-finally-yield-cleanup';
  }
}

Stream<String> asyncGeneratedCatchAwait(Future<String> ready) async* {
  try {
    yield await ready;
  } catch (e) {
    yield 'patched-stream-caught-$e';
  }
}

Stream<String> asyncGeneratedMany(bool enabled) async* {
  final prefix = 'patched-stream';
  yield '$prefix-a';
  if (enabled) yield '$prefix-live';
  yield '$prefix-tail';
}

Stream<String> asyncGeneratedWhile() async* {
  var i = 0;
  while (2 > i) {
    yield 'patched-stream-while-$i';
    i = i + 1;
  }
}

Stream<String> asyncGeneratedWhileBreak() async* {
  var i = 0;
  while (4 > i) {
    yield 'patched-stream-while-break-before-$i';
    if (i == 2) break;
    yield 'patched-stream-while-break-after-$i';
    i = i + 1;
  }
}

Stream<String> asyncGeneratedWhileContinue() async* {
  var i = 0;
  while (3 > i) {
    yield 'patched-stream-while-continue-before-$i';
    if (i == 1) {
      i = i + 1;
      continue;
    }
    yield 'patched-stream-while-continue-after-$i';
    i = i + 1;
  }
}

Stream<String> asyncGeneratedWhileContinueBreak() async* {
  var i = 0;
  while (4 > i) {
    yield 'patched-stream-while-continue-before-$i';
    if (i == 1) {
      i = i + 1;
      continue;
    }
    yield 'patched-stream-while-continue-mid-$i';
    if (i == 2) break;
    yield 'patched-stream-while-continue-after-$i';
    i = i + 1;
  }
}

Stream<String> asyncGeneratedDoWhile() async* {
  var i = 0;
  do {
    yield 'patched-stream-do-$i';
    i = i + 1;
  } while (2 > i);
}

Stream<String> asyncGeneratedDoWhileBreak() async* {
  var i = 0;
  do {
    yield 'patched-stream-do-break-before-$i';
    if (i == 1) break;
    yield 'patched-stream-do-break-after-$i';
    i = i + 1;
  } while (3 > i);
}

Stream<String> asyncGeneratedDoWhileContinue() async* {
  var i = 0;
  do {
    yield 'patched-stream-do-continue-before-$i';
    if (i == 1) {
      i = i + 1;
      continue;
    }
    yield 'patched-stream-do-continue-after-$i';
    i = i + 1;
  } while (3 > i);
}

Stream<String> asyncGeneratedDoWhileContinueBreak() async* {
  var i = 0;
  do {
    yield 'patched-stream-do-continue-before-$i';
    if (i == 1) {
      i = i + 1;
      continue;
    }
    yield 'patched-stream-do-continue-mid-$i';
    if (i == 2) break;
    yield 'patched-stream-do-continue-after-$i';
    i = i + 1;
  } while (4 > i);
}

Stream<String> asyncGeneratedForLoop() async* {
  for (var i = 0; 2 > i; i = i + 1) {
    yield 'patched-stream-for-$i';
  }
}

Stream<String> asyncGeneratedForLoopPostIncrement() async* {
  for (var i = 0; 2 > i; i++) {
    yield 'patched-stream-for-postinc-$i';
  }
}

Stream<String> asyncGeneratedForLoopMultiUpdate() async* {
  for (var i = 0, j = 10; 2 > i; i = i + 1, j = j + 1) {
    yield 'patched-stream-for-multi-$i-$j';
  }
}

Stream<String> asyncGeneratedForLoopExternalLocal() async* {
  var i = 0;
  for (; 2 > i; i = i + 1) {
    yield 'patched-stream-for-external-$i';
  }
}

Stream<String> asyncGeneratedForLoopBodyUpdate() async* {
  var i = 0;
  for (; 2 > i;) {
    yield 'patched-stream-for-body-update-$i';
    i = i + 1;
  }
}

Stream<String> asyncGeneratedForLoopContinue() async* {
  for (var i = 0; 3 > i; i = i + 1) {
    yield 'patched-stream-for-continue-before-$i';
    if (i == 1) continue;
    yield 'patched-stream-for-continue-after-$i';
  }
}

Stream<String> asyncGeneratedForLoopContinueBreak() async* {
  for (var i = 0; 4 > i; i = i + 1) {
    yield 'patched-stream-for-continue-before-$i';
    if (i == 1) continue;
    yield 'patched-stream-for-continue-mid-$i';
    if (i == 2) break;
    yield 'patched-stream-for-continue-after-$i';
  }
}

Stream<String> asyncGeneratedForLoopBreak() async* {
  for (var i = 0; 3 > i; i = i + 1) {
    yield 'patched-stream-for-break-before-$i';
    if (i == 1) break;
    yield 'patched-stream-for-break-after-$i';
  }
}

Stream<String> asyncGeneratedForIn() async* {
  for (final value in ['patched-stream-a', 'patched-stream-b']) {
    yield value;
  }
}

Stream<String> asyncGeneratedForInBreak() async* {
  final prefix = 'patched-stream-static-break';
  for (final value in ['a', 'stop', 'tail']) {
    yield '$prefix-before-$value';
    if (value == 'stop') break;
    yield '$prefix-after-$value';
  }
}

Stream<String> asyncGeneratedForInBreakFirst() async* {
  final prefix = 'patched-stream-static-break-first';
  for (final value in ['a', 'stop', 'tail']) {
    if (value == 'stop') break;
    yield '$prefix-$value';
  }
}

Stream<String> asyncGeneratedForInContinue() async* {
  final prefix = 'patched-stream-static-continue';
  for (final value in ['a', 'skip', 'tail']) {
    if (value == 'skip') continue;
    yield '$prefix-$value';
  }
}

Stream<String> asyncGeneratedForInContinueAfterYield() async* {
  final prefix = 'patched-stream-static-continue-after-yield';
  for (final value in ['a', 'skip', 'tail']) {
    yield '$prefix-before-$value';
    if (value == 'skip') continue;
    yield '$prefix-after-$value';
  }
}

Stream<String> asyncGeneratedDynamicForIn(List<String> extra) async* {
  for (final value in extra) {
    yield value;
  }
  yield 'patched-stream-dynamic-tail';
}

Stream<String> asyncGeneratedDynamicForInMapped(List<String> extra) async* {
  final prefix = 'patched-stream-map';
  for (final value in extra) {
    yield '$prefix-$value';
  }
}

Stream<String> asyncGeneratedDynamicForInMany(List<String> extra) async* {
  final prefix = 'patched-stream-many';
  for (final value in extra) {
    yield '$prefix-a-$value';
    yield '$prefix-b-$value';
  }
}

Stream<String> asyncGeneratedDynamicForInIf(List<String> extra) async* {
  final prefix = 'patched-stream-if';
  for (final value in extra) {
    if (value == 'live') yield '$prefix-hit-$value';
    yield '$prefix-tail-$value';
  }
}

Stream<String> asyncGeneratedDynamicForInIfElse(List<String> extra) async* {
  final prefix = 'patched-stream-ifelse';
  for (final value in extra) {
    if (value == 'live') {
      yield '$prefix-hit-$value';
    } else {
      yield '$prefix-miss-$value';
    }
  }
}

Stream<String> asyncGeneratedDynamicForInLocal(List<String> extra) async* {
  final prefix = 'patched-stream-local';
  for (final value in extra) {
    final marker = '$prefix-$value';
    yield marker;
  }
}

Stream<String> asyncGeneratedDynamicForInContinue(List<String> extra) async* {
  final prefix = 'patched-stream-continue';
  for (final value in extra) {
    if (value == 'skip') continue;
    yield '$prefix-$value';
  }
}

Stream<String> asyncGeneratedDynamicForInContinueAfterYield(List<String> extra) async* {
  final prefix = 'patched-stream-continue-after-yield';
  for (final value in extra) {
    yield '$prefix-before-$value';
    if (value == 'skip') continue;
    yield '$prefix-after-$value';
  }
}

Stream<String> asyncGeneratedDynamicForInBreak(List<String> extra) async* {
  final prefix = 'patched-stream-break';
  for (final value in extra) {
    if (value == 'stop') break;
    yield '$prefix-$value';
  }
}

Stream<String> asyncGeneratedDynamicForInBreakAfterYield(List<String> extra) async* {
  final prefix = 'patched-stream-break-after-yield';
  for (final value in extra) {
    yield '$prefix-before-$value';
    if (value == 'stop') break;
    yield '$prefix-after-$value';
  }
}

Stream<String> asyncGeneratedDynamicForInBreakAtEnd(List<String> extra) async* {
  final prefix = 'patched-stream-break-at-end';
  for (final value in extra) {
    yield '$prefix-before-$value';
    if (value == 'stop') break;
  }
}

Stream<String> asyncGeneratedDynamicForInContinueThenBreak(List<String> extra) async* {
  final prefix = 'patched-stream-continue-break';
  for (final value in extra) {
    if (value == 'skip') continue;
    if (value == 'stop') break;
    yield '$prefix-$value';
  }
}

Stream<String> asyncGeneratedDynamicForInContinueYieldBreak(List<String> extra) async* {
  final prefix = 'patched-stream-continue-yield-break';
  for (final value in extra) {
    if (value == 'skip') continue;
    yield '$prefix-before-$value';
    if (value == 'stop') break;
    yield '$prefix-after-$value';
  }
}

Stream<String> asyncGeneratedDynamicForInNested(
  List<String> extra,
  List<String> suffixes,
) async* {
  final prefix = 'patched-stream-nested';
  for (final value in extra) {
    for (final suffix in suffixes) {
      yield '$prefix-$value-$suffix';
    }
  }
}

Stream<String> asyncGeneratedYieldStar() async* {
  yield* Stream.fromIterable([
    'patched-stream-yield-star-a',
    'patched-stream-yield-star-b',
  ]);
}

Stream<String> asyncGeneratedYieldStarDynamic(List<String> extra) async* {
  yield* Stream.fromIterable(extra);
  yield 'patched-stream-yield-star-dynamic-tail';
}

Stream<String> asyncGeneratedYieldStarValue(String value) async* {
  yield* Stream.value('patched-stream-yield-star-value-$value');
}

Stream<String> asyncGeneratedYieldStarFromFuture(String value) async* {
  yield* Stream.fromFuture(Future.value('patched-stream-yield-star-future-$value'));
}

Stream<String> asyncGeneratedYieldStarPendingFuture(
  Future<String> ready,
) async* {
  yield* Stream.fromFuture(ready);
}

Stream<String> asyncGeneratedYieldStarEmpty() async* {
  yield* Stream<String>.empty();
}

Stream<String> asyncGeneratedAwaitForFromIterable(List<String> extra) async* {
  await for (final value in Stream.fromIterable(extra)) {
    yield 'patched-stream-await-for-iterable-$value';
  }
}

Stream<String> asyncGeneratedAwaitForContinue(List<String> extra) async* {
  await for (final value in Stream.fromIterable(extra)) {
    if (value == 'skip') continue;
    yield 'patched-stream-await-for-continue-$value';
  }
}

Stream<String> asyncGeneratedAwaitForBreak(List<String> extra) async* {
  await for (final value in Stream.fromIterable(extra)) {
    if (value == 'stop') break;
    yield 'patched-stream-await-for-break-$value';
  }
}

Stream<String> asyncGeneratedAwaitForValue(String value) async* {
  await for (final item in Stream.value(value)) {
    yield 'patched-stream-await-for-value-$item';
  }
}

Stream<String> asyncGeneratedAwaitForFuture(String value) async* {
  await for (final item in Stream.fromFuture(Future.value(value))) {
    yield 'patched-stream-await-for-future-$item';
  }
}

Stream<String> asyncGeneratedAwaitForFutureBreak(String value) async* {
  await for (final item in Stream.fromFuture(Future.value(value))) {
    if (item == 'stop') break;
    yield 'patched-stream-await-for-future-break-$item';
  }
}

Stream<String> asyncGeneratedAwaitForPendingFuture(Future<String> ready) async* {
  await for (final item in Stream.fromFuture(ready)) {
    yield 'patched-stream-await-for-pending-future-$item';
  }
}

Stream<String> asyncGeneratedAwaitForPendingContinue(
  Future<String> ready,
) async* {
  await for (final item in Stream.fromFuture(ready)) {
    if (item == 'skip') continue;
    yield 'patched-stream-await-for-pending-continue-$item';
  }
}

Stream<String> asyncGeneratedAwaitForEmpty() async* {
  await for (final item in Stream<String>.empty()) {
    yield 'patched-stream-await-for-empty-$item';
  }
}

Stream<String> asyncGeneratedYieldStarStream(Stream<String> extra) async* {
  yield* extra;
}

Stream<String> asyncGeneratedYieldStarStreamFinally(Stream<String> extra) async* {
  try {
    yield* extra;
  } finally {
    yield 'patched-stream-yield-star-stream-finally-cleanup';
  }
}

Stream<String> asyncGeneratedYieldStarStreamSandwichFinally(
  Stream<String> extra,
) async* {
  try {
    yield 'patched-stream-yield-star-stream-before';
    yield* extra;
    yield 'patched-stream-yield-star-stream-after';
  } finally {
    yield 'patched-stream-yield-star-stream-sandwich-cleanup';
  }
}

Stream<String> asyncGeneratedYieldStarTwoStreamsFinally(
  Stream<String> first,
  Stream<String> second,
) async* {
  try {
    yield* first;
    yield* second;
  } finally {
    yield 'patched-stream-yield-star-two-streams-cleanup';
  }
}

Stream<String> asyncGeneratedAwaitFor(Stream<String> extra) async* {
  await for (final value in extra) {
    yield value;
  }
}

Stream<String> asyncGeneratedAwaitForFinally(Stream<String> extra) async* {
  try {
    await for (final value in extra) {
      yield value;
    }
  } finally {
    yield 'patched-stream-await-for-finally-cleanup';
  }
}

Stream<String> asyncGeneratedAwaitForStreamContinue(Stream<String> extra) async* {
  await for (final value in extra) {
    if (value == 'skip') continue;
    yield 'patched-stream-await-for-stream-continue-$value';
  }
}

Stream<String> asyncGeneratedAwaitForStreamBreak(Stream<String> extra) async* {
  await for (final value in extra) {
    if (value == 'stop') break;
    yield 'patched-stream-await-for-stream-break-$value';
  }
}

Stream<String> asyncGeneratedAwaitForStreamContinueBreakFinally(
  Stream<String> extra,
) async* {
  try {
    await for (final value in extra) {
      if (value == 'skip') continue;
      if (value == 'stop') break;
      yield 'patched-stream-await-for-stream-continue-break-$value';
    }
  } finally {
    yield 'patched-stream-await-for-stream-continue-break-cleanup';
  }
}

Stream<String> asyncGeneratedAwaitForNestedValueFinally(
  Stream<String> extra,
) async* {
  try {
    await for (final outer in extra) {
      await for (final inner in Stream.value('$outer-inner')) {
        yield 'patched-stream-await-for-nested-$inner';
      }
    }
  } finally {
    yield 'patched-stream-await-for-nested-cleanup';
  }
}

Stream<String> asyncGeneratedAwaitForNestedStreamFinally(
  Stream<String> outer,
  Stream<String> inner,
) async* {
  try {
    await for (final left in outer) {
      await for (final right in inner) {
        yield 'patched-stream-await-for-nested-stream-$left-$right';
      }
    }
  } finally {
    yield 'patched-stream-await-for-nested-stream-cleanup';
  }
}

Iterable<String> syncGenerated() sync* {
  yield 'patched-iterable';
}

Iterable<String> syncGeneratedMany(bool enabled) sync* {
  final prefix = 'patched-iterable';
  yield '$prefix-a';
  if (enabled) yield '$prefix-live';
  yield '$prefix-tail';
}

Iterable<String> syncGeneratedWhile() sync* {
  var i = 0;
  while (2 > i) {
    yield 'patched-iterable-while-$i';
    i = i + 1;
  }
}

Iterable<String> syncGeneratedWhileBreak() sync* {
  var i = 0;
  while (4 > i) {
    yield 'patched-iterable-while-break-before-$i';
    if (i == 2) break;
    yield 'patched-iterable-while-break-after-$i';
    i = i + 1;
  }
}

Iterable<String> syncGeneratedWhileContinue() sync* {
  var i = 0;
  while (3 > i) {
    yield 'patched-iterable-while-continue-before-$i';
    if (i == 1) {
      i = i + 1;
      continue;
    }
    yield 'patched-iterable-while-continue-after-$i';
    i = i + 1;
  }
}

Iterable<String> syncGeneratedWhileContinueBreak() sync* {
  var i = 0;
  while (4 > i) {
    yield 'patched-iterable-while-continue-before-$i';
    if (i == 1) {
      i = i + 1;
      continue;
    }
    yield 'patched-iterable-while-continue-mid-$i';
    if (i == 2) break;
    yield 'patched-iterable-while-continue-after-$i';
    i = i + 1;
  }
}

Iterable<String> syncGeneratedDoWhile() sync* {
  var i = 0;
  do {
    yield 'patched-iterable-do-$i';
    i = i + 1;
  } while (2 > i);
}

Iterable<String> syncGeneratedDoWhileBreak() sync* {
  var i = 0;
  do {
    yield 'patched-iterable-do-break-before-$i';
    if (i == 1) break;
    yield 'patched-iterable-do-break-after-$i';
    i = i + 1;
  } while (3 > i);
}

Iterable<String> syncGeneratedDoWhileContinue() sync* {
  var i = 0;
  do {
    yield 'patched-iterable-do-continue-before-$i';
    if (i == 1) {
      i = i + 1;
      continue;
    }
    yield 'patched-iterable-do-continue-after-$i';
    i = i + 1;
  } while (3 > i);
}

Iterable<String> syncGeneratedDoWhileContinueBreak() sync* {
  var i = 0;
  do {
    yield 'patched-iterable-do-continue-before-$i';
    if (i == 1) {
      i = i + 1;
      continue;
    }
    yield 'patched-iterable-do-continue-mid-$i';
    if (i == 2) break;
    yield 'patched-iterable-do-continue-after-$i';
    i = i + 1;
  } while (4 > i);
}

Iterable<String> syncGeneratedForLoop() sync* {
  for (var i = 0; 2 > i; i = i + 1) {
    yield 'patched-iterable-for-$i';
  }
}

Iterable<String> syncGeneratedForLoopPostIncrement() sync* {
  for (var i = 0; 2 > i; i++) {
    yield 'patched-iterable-for-postinc-$i';
  }
}

Iterable<String> syncGeneratedForLoopMultiUpdate() sync* {
  for (var i = 0, j = 10; 2 > i; i = i + 1, j = j + 1) {
    yield 'patched-iterable-for-multi-$i-$j';
  }
}

Iterable<String> syncGeneratedForLoopExternalLocal() sync* {
  var i = 0;
  for (; 2 > i; i = i + 1) {
    yield 'patched-iterable-for-external-$i';
  }
}

Iterable<String> syncGeneratedForLoopBodyUpdate() sync* {
  var i = 0;
  for (; 2 > i;) {
    yield 'patched-iterable-for-body-update-$i';
    i = i + 1;
  }
}

Iterable<String> syncGeneratedForLoopContinue() sync* {
  for (var i = 0; 3 > i; i = i + 1) {
    yield 'patched-iterable-for-continue-before-$i';
    if (i == 1) continue;
    yield 'patched-iterable-for-continue-after-$i';
  }
}

Iterable<String> syncGeneratedForLoopContinueBreak() sync* {
  for (var i = 0; 4 > i; i = i + 1) {
    yield 'patched-iterable-for-continue-before-$i';
    if (i == 1) continue;
    yield 'patched-iterable-for-continue-mid-$i';
    if (i == 2) break;
    yield 'patched-iterable-for-continue-after-$i';
  }
}

Iterable<String> syncGeneratedForLoopBreak() sync* {
  for (var i = 0; 3 > i; i = i + 1) {
    yield 'patched-iterable-for-break-before-$i';
    if (i == 1) break;
    yield 'patched-iterable-for-break-after-$i';
  }
}

Iterable<String> syncGeneratedForIn() sync* {
  for (final value in ['patched-iterable-a', 'patched-iterable-b']) {
    yield value;
  }
}

Iterable<String> syncGeneratedForInBreak() sync* {
  final prefix = 'patched-iterable-static-break';
  for (final value in ['a', 'stop', 'tail']) {
    yield '$prefix-before-$value';
    if (value == 'stop') break;
    yield '$prefix-after-$value';
  }
}

Iterable<String> syncGeneratedForInBreakFirst() sync* {
  final prefix = 'patched-iterable-static-break-first';
  for (final value in ['a', 'stop', 'tail']) {
    if (value == 'stop') break;
    yield '$prefix-$value';
  }
}

Iterable<String> syncGeneratedForInContinue() sync* {
  final prefix = 'patched-iterable-static-continue';
  for (final value in ['a', 'skip', 'tail']) {
    if (value == 'skip') continue;
    yield '$prefix-$value';
  }
}

Iterable<String> syncGeneratedForInContinueAfterYield() sync* {
  final prefix = 'patched-iterable-static-continue-after-yield';
  for (final value in ['a', 'skip', 'tail']) {
    yield '$prefix-before-$value';
    if (value == 'skip') continue;
    yield '$prefix-after-$value';
  }
}

Iterable<String> syncGeneratedDynamicForIn(List<String> extra) sync* {
  for (final value in extra) {
    yield value;
  }
  yield 'patched-iterable-dynamic-tail';
}

Iterable<String> syncGeneratedDynamicForInMapped(List<String> extra) sync* {
  final prefix = 'patched-iterable-map';
  for (final value in extra) {
    yield '$prefix-$value';
  }
}

Iterable<String> syncGeneratedDynamicForInMany(List<String> extra) sync* {
  final prefix = 'patched-iterable-many';
  for (final value in extra) {
    yield '$prefix-a-$value';
    yield '$prefix-b-$value';
  }
}

Iterable<String> syncGeneratedDynamicForInIf(List<String> extra) sync* {
  final prefix = 'patched-iterable-if';
  for (final value in extra) {
    if (value == 'live') yield '$prefix-hit-$value';
    yield '$prefix-tail-$value';
  }
}

Iterable<String> syncGeneratedDynamicForInIfElse(List<String> extra) sync* {
  final prefix = 'patched-iterable-ifelse';
  for (final value in extra) {
    if (value == 'live') {
      yield '$prefix-hit-$value';
    } else {
      yield '$prefix-miss-$value';
    }
  }
}

Iterable<String> syncGeneratedDynamicForInLocal(List<String> extra) sync* {
  final prefix = 'patched-iterable-local';
  for (final value in extra) {
    final marker = '$prefix-$value';
    yield marker;
  }
}

Iterable<String> syncGeneratedDynamicForInContinue(List<String> extra) sync* {
  final prefix = 'patched-iterable-continue';
  for (final value in extra) {
    if (value == 'skip') continue;
    yield '$prefix-$value';
  }
}

Iterable<String> syncGeneratedDynamicForInContinueAfterYield(List<String> extra) sync* {
  final prefix = 'patched-iterable-continue-after-yield';
  for (final value in extra) {
    yield '$prefix-before-$value';
    if (value == 'skip') continue;
    yield '$prefix-after-$value';
  }
}

Iterable<String> syncGeneratedDynamicForInBreak(List<String> extra) sync* {
  final prefix = 'patched-iterable-break';
  for (final value in extra) {
    if (value == 'stop') break;
    yield '$prefix-$value';
  }
}

Iterable<String> syncGeneratedDynamicForInBreakAfterYield(List<String> extra) sync* {
  final prefix = 'patched-iterable-break-after-yield';
  for (final value in extra) {
    yield '$prefix-before-$value';
    if (value == 'stop') break;
    yield '$prefix-after-$value';
  }
}

Iterable<String> syncGeneratedDynamicForInBreakAtEnd(List<String> extra) sync* {
  final prefix = 'patched-iterable-break-at-end';
  for (final value in extra) {
    yield '$prefix-before-$value';
    if (value == 'stop') break;
  }
}

Iterable<String> syncGeneratedDynamicForInContinueThenBreak(List<String> extra) sync* {
  final prefix = 'patched-iterable-continue-break';
  for (final value in extra) {
    if (value == 'skip') continue;
    if (value == 'stop') break;
    yield '$prefix-$value';
  }
}

Iterable<String> syncGeneratedDynamicForInContinueYieldBreak(List<String> extra) sync* {
  final prefix = 'patched-iterable-continue-yield-break';
  for (final value in extra) {
    if (value == 'skip') continue;
    yield '$prefix-before-$value';
    if (value == 'stop') break;
    yield '$prefix-after-$value';
  }
}

Iterable<String> syncGeneratedDynamicForInNested(
  List<String> extra,
  List<String> suffixes,
) sync* {
  final prefix = 'patched-iterable-nested';
  for (final value in extra) {
    for (final suffix in suffixes) {
      yield '$prefix-$value-$suffix';
    }
  }
}

Iterable<String> syncGeneratedYieldStar() sync* {
  yield* ['patched-yield-star-a', 'patched-yield-star-b'];
}

Iterable<String> syncGeneratedYieldStarDynamic(List<String> extra) sync* {
  yield* extra;
  yield 'patched-yield-star-dynamic-tail';
}

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

python3 "$ROOT_DIR/tests/e2e/kernel_compile_from_plan/assert_plan_inventory.py" \
  "$WORKDIR/release_inventory.json" "$WORKDIR/patch_inventory.json" "$WORKDIR/plan.json"
python3 "$ROOT_DIR/tests/e2e/kernel_compile_from_plan/assert_generator_sources.py" \
  "$WORKDIR/patch_inventory.json"

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

python3 "$ROOT_DIR/tests/e2e/kernel_compile_from_plan/assert_module.py" "$WORKDIR/module.fcbm"

python3 "$ROOT_DIR/tests/e2e/kernel_compile_from_plan/assert_binary.py" "$WORKDIR/module.bin"

if [ -x "$FCB_RUN_VM_TESTS" ]; then
  FCB_SOURCE_ASYNC_STAR_MODULE="$WORKDIR/module.bin" \
    "$FCB_RUN_VM_TESTS" FcbPatchRuntimeAsyncStarSourceModuleStreamListen
else
  echo "skipping source async* runtime e2e: missing run_vm_tests at $FCB_RUN_VM_TESTS" >&2
fi
