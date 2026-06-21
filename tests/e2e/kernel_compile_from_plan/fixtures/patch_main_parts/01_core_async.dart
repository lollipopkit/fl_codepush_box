class User {
  User(this.name, this.label);
  final String name;
  final String label;
}

class Config {
  Config({required this.name, required this.label});
  final String name;
  String label;
}

class Box<T> {
  Box(this.value);
  final T value;
}

class Greeter {
  Greeter();

  String surround(
    String value, {
    required String prefix,
    required String suffix,
  }) {
    return '$prefix$value$suffix';
  }
}

double helper() {
  return 2.5;
}

Object? maybeNull() {
  return null;
}

Future<Object?> asyncNullableChoice(bool enabled) async {
  return enabled ? null : 'patched-null';
}

String label(String name) {
  return 'hello $name!';
}

String displayName(User user) {
  return user.label;
}

Future<String> asyncDisplayName(User user) async {
  return user.label;
}

Future<String> asyncAwaitThenReadField(User user, Future<String> ready) async {
  final prefix = await ready;
  return 'patched-await-field:$prefix ${user.label}';
}

User makeUser() {
  return User('patched', 'patched-label');
}

Future<User> asyncMakeUser() async {
  return User('patched-async', 'patched-async-label');
}

Config makeConfig() {
  return Config(name: 'patched', label: 'patched-label');
}

Future<Config> asyncMakeConfig() async {
  return Config(name: 'patched-async', label: 'patched-async-label');
}

String updateConfigLabel(Config config, String label) {
  config.label = '$label-patched';
  return config.label;
}

Future<String> asyncUpdateConfigLabel(Config config, String label) async {
  config.label = '$label-async-patched';
  return config.label;
}

Future<String> asyncAwaitThenUpdateConfigLabel(
  Config config,
  Future<String> ready,
) async {
  final label = await ready;
  config.label = '$label-await-patched';
  return config.label;
}

Box<String> makeStringBox() {
  return Box<String>('patched-box');
}

Future<Box<String>> asyncMakeStringBox() async {
  return Box<String>('patched-async-box');
}

Future<Box<String>> asyncAwaitThenMakeStringBox(Future<String> ready) async {
  final value = await ready;
  return Box<String>('patched-await-box:$value');
}

String dynamicNamedCall() {
  return Greeter().surround('patched', prefix: '<', suffix: '>');
}

Future<String> asyncDynamicNamedCall() async {
  return Greeter().surround('patched-async', prefix: '<', suffix: '>');
}

Future<String> asyncAwaitThenDynamicCall(Future<String> ready) async {
  final value = await ready;
  return Greeter().surround(
    value,
    prefix: 'patched-await-dynamic<',
    suffix: '>',
  );
}

bool sameObject(Object value) {
  return identical(value, value);
}

Future<bool> asyncSameObject(Object value) async {
  return identical(value, value);
}

Future<bool> asyncAwaitThenSameObject(Future<Object> ready) async {
  final value = await ready;
  return identical(value, value);
}

Future<bool> asyncAwaitThenIsString(Future<Object> ready) async {
  final value = await ready;
  return value is String;
}

Future<Object> asyncAwaitThenAsStringList(Future<Object> ready) async {
  final value = await ready;
  return value as List<String>;
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

String syncLocalMutation(String name) {
  var out = 'patched-local';
  out = '$out-$name';
  return out;
}

Future<String> asyncLocalMutation(String name) async {
  var out = 'patched-async-local';
  out = '$out-$name';
  return out;
}

Future<String> asyncAwaitThenLocalMutation(
  Future<String> ready,
  String name,
) async {
  var out = await ready;
  out = 'patched-await-local:$out-$name';
  return out;
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

String Function([String? suffix]) optionalPositionalEscapingGreeting(
  String name,
) {
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
  return (enabled, premium) => enabled && (premium || name == 'vip') || !enabled
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

String directCallbackValue(String Function() callback) {
  return '${callback()} patched-direct';
}

String directCallbackArg(String Function(String) callback, String value) {
  return '${callback(value)} patched-arg';
}

String directCallbackNamed(
  String Function({required String value}) callback,
  String value,
) {
  return '${callback(value: value)} patched-named';
}

String directCallbackMixed(
  String Function(String value, {required String suffix}) callback,
  String value,
  String suffix,
) {
  return '${callback(value, suffix: suffix)} patched-mixed';
}

Future<String> asyncDirectCallbackMixed(
  String Function(String value, {required String suffix}) callback,
  String value,
  String suffix,
) async {
  return '${callback(value, suffix: suffix)} patched-async-mixed';
}

Future<String> asyncAwaitThenDirectCallbackMixed(
  String Function(String value, {required String suffix}) callback,
  Future<String> ready,
  String suffix,
) async {
  final value = await ready;
  return '${callback(value, suffix: suffix)} patched-await-callback';
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

Future<String> asyncAlwaysThrow() async {
  return throw 'patched-async-boom';
}

Future<String> asyncLabel() async {
  return 'patched-async';
}

Future<String> asyncConcatLabel(String name) async {
  return 'patched-async $name';
}

Future<double> asyncStaticHelperValue() async {
  return helper() + 3.5;
}

Future<double> asyncAwaitThenStaticHelperValue(Future<double> ready) async {
  final value = await ready;
  return value + helper();
}

Future<int> asyncArithmeticValue(int value) async {
  return value + 2;
}

Future<int> asyncAwaitThenArithmeticValue(Future<int> ready) async {
  final value = await ready;
  return value + 5;
}

Future<int> asyncSubtractValue(int value) async {
  return value - 3;
}

Future<int> asyncAwaitThenSubtractValue(Future<int> ready) async {
  final value = await ready;
  return value - 7;
}

Future<int> asyncMultiplyValue(int value) async {
  return value * 3;
}

Future<int> asyncAwaitThenMultiplyValue(Future<int> ready) async {
  final value = await ready;
  return value * 9;
}

Future<double> asyncDivideValue(int value) async {
  return value / 4;
}

Future<bool> asyncLogicalFlag(bool enabled, bool premium) async {
  return enabled && !premium || premium;
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

Future<String> awaitedLabel(bool enabled) async {
  if (await Future.value(enabled))
    return 'patched ${await Future.value('awaited')}';
  return 'patched disabled';
}

Future<String> awaitedLocalLabel(String name) async {
  try {
    final base = 'patched-local';
    final prefix = await Future.value(base);
    if (name == 'Ada') return '$prefix ${await Future.value('done')}';
    return '$prefix $name';
  } catch (e) {
    return 'patched-caught $e';
  }
}

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

Future<String> asyncNestedBranchLocal(bool enabled, bool premium) async {
  if (enabled) {
    final state = 'patched-nested-enabled';
    if (premium) {
      final tier = 'patched-nested-pro';
      return '$state-$tier';
    } else {
      final tier = 'patched-nested-basic';
      return '$state-$tier';
    }
  } else {
    final state = 'patched-nested-disabled';
    if (premium) {
      final tier = 'patched-nested-disabled-pro';
      return '$state-$tier';
    }
    final tier = 'patched-nested-disabled-basic';
    return '$state-$tier';
  }
}

Future<String> asyncNestedAwaitBranchLocal(
  bool enabled,
  bool premium,
  Future<String> ready,
) async {
  if (enabled) {
    final state = await ready;
    if (premium) {
      final tier = 'patched-nested-await-pro';
      return '$state-$tier';
    } else {
      final tier = 'patched-nested-await-basic';
      return '$state-$tier';
    }
  } else {
    final state = 'patched-nested-await-disabled';
    if (premium) {
      final tier = await ready;
      return '$state-$tier';
    }
    final tier = 'patched-nested-await-disabled-basic';
    return '$state-$tier';
  }
}

Future<String> asyncIfElseSideEffectTail(
  bool enabled,
  Future<String> ready,
) async {
  var out = 'patched-ifelse-side-effect';
  if (enabled) {
    final state = await ready;
    out = '$out-$state';
  } else {
    final state = 'patched-ifelse-disabled';
    out = '$out-$state';
  }
  out = '$out-tail';
  return out;
}

Future<String> asyncIfSideEffectTail(bool enabled, Future<String> ready) async {
  var out = 'patched-if-side-effect';
  if (enabled) {
    final state = await ready;
    out = '$out-$state';
  }
  out = '$out-tail';
  return out;
}

Future<String> asyncConditionalAwaitExpr(
  bool enabled,
  Future<String> ready,
) async {
  return enabled ? await ready : 'patched-conditional-disabled';
}

Future<String> asyncLessThanAwaitTail(int limit, Future<String> ready) async {
  if (limit < 2) return await ready;
  return 'patched-less-than-tail';
}

Future<String> asyncLessEqualAwaitTail(int limit, Future<String> ready) async {
  if (limit <= 2) return await ready;
  return 'patched-less-equal-tail';
}

Future<String> asyncGreaterEqualAwaitTail(
  int limit,
  Future<String> ready,
) async {
  if (limit >= 2) return await ready;
  return 'patched-greater-equal-tail';
}

Future<String> asyncNotEqualAwaitTail(
  String marker,
  Future<String> ready,
) async {
  if (marker != 'skip') return await ready;
  return 'patched-not-equal-tail';
}

Future<String> asyncGuardAwaitTail(bool enabled, Future<String> ready) async {
  if (enabled) return 'patched-guard-fast';
  await ready;
  return 'patched-guard-tail';
}

Future<int> asyncIntInput() {
  return Future.value(2);
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

Future<String> asyncWhileContinueBreak(int limit) async {
  var i = 0;
  var out = 'patched-while-continue-break';
  while (limit > i) {
    out = '$out-before-$i';
    if (i == 1) {
      i = i + 1;
      continue;
    }
    out = '$out-middle-$i';
    if (i == 2) break;
    out = '$out-after-$i';
    i = i + 1;
  }
  return out;
}

Future<String> asyncWhileAwaitContinueBreak(
  int limit,
  Future<bool> skip,
  Future<bool> stop,
) async {
  var i = 0;
  var out = 'patched-while-await-continue-break';
  while (limit > i) {
    out = '$out-before-$i';
    if (await skip) {
      i = i + 1;
      continue;
    }
    out = '$out-middle-$i';
    if (await stop) break;
    out = '$out-after-$i';
    i = i + 1;
  }
  return out;
}

Future<String> asyncWhileAwaitCondition(Future<bool> keepGoing) async {
  var i = 0;
  var out = 'patched-while-await-condition';
  while (await keepGoing) {
    out = '$out-$i';
    if (i == 0) break;
    i = i + 1;
  }
  return out;
}

Future<String> asyncWhileNestedAwaitBranchLocal(
  int limit,
  bool premium,
  Future<String> ready,
) async {
  var i = 0;
  var out = 'patched-while-nested-await-branch';
  while (limit > i) {
    if (i == 0) {
      final state = await ready;
      if (premium) {
        final tier = 'patched-while-nested-pro';
        out = '$out-$state-$tier';
      } else {
        final tier = 'patched-while-nested-basic';
        out = '$out-$state-$tier';
      }
    } else {
      final state = 'patched-while-nested-tail';
      out = '$out-$state-$i';
    }
    i = i + 1;
  }
  return out;
}

Future<String> asyncDoWhileLocal(int limit) async {
  var i = 0;
  var out = 'patched-do-while';
  do {
    out = '$out-$i';
    i = i + 1;
  } while (limit > i);
  return out;
}

Future<String> asyncDoWhileAwaitCondition(Future<bool> keepGoing) async {
  var i = 0;
  var out = 'patched-do-while-await';
  do {
    out = '$out-$i';
    i = i + 1;
  } while (await keepGoing);
  return out;
}

Future<String> asyncDoWhileBranchLocal(int limit) async {
  var i = 0;
  var out = 'patched-do-while-branch';
  do {
    final segment = i == 0 ? 'first' : 'again';
    out = '$out-$segment-$i';
    i = i + 1;
  } while (limit > i);
  return out;
}

Future<String> asyncDoWhileBreak(int limit) async {
  var i = 0;
  var out = 'patched-do-while-break';
  do {
    out = '$out-before-$i';
    if (i == 1) break;
    out = '$out-after-$i';
    i = i + 1;
  } while (limit > i);
  return out;
}

Future<String> asyncDoWhileContinue(int limit) async {
  var i = 0;
  var out = 'patched-do-while-continue';
  do {
    out = '$out-before-$i';
    if (i == 1) {
      i = i + 1;
      continue;
    }
    out = '$out-after-$i';
    i = i + 1;
  } while (limit > i);
  return out;
}

Future<String> asyncDoWhileContinueBreak(int limit) async {
  var i = 0;
  var out = 'patched-do-while-continue-break';
  do {
    out = '$out-before-$i';
    if (i == 1) {
      i = i + 1;
      continue;
    }
    out = '$out-middle-$i';
    if (i == 2) break;
    out = '$out-after-$i';
    i = i + 1;
  } while (limit > i);
  return out;
}

Future<String> asyncDoWhileAwaitGuardContinueBreak(
  int limit,
  Future<bool> skip,
  Future<bool> stop,
) async {
  var i = 0;
  var out = 'patched-do-while-await-guard-continue-break';
  do {
    out = '$out-before-$i';
    if (await skip) {
      i = i + 1;
      continue;
    }
    out = '$out-middle-$i';
    if (await stop) break;
    out = '$out-after-$i';
    i = i + 1;
  } while (limit > i);
  return out;
}

Future<String> asyncDoWhileAwaitGuardContinueBreakAwaitCondition(
  Future<bool> keepGoing,
  Future<bool> skip,
  Future<bool> stop,
) async {
  var i = 0;
  var out = 'patched-do-while-await-guard-continue-break-await-condition';
  do {
    out = '$out-before-$i';
    if (await skip) {
      i = i + 1;
      continue;
    }
    out = '$out-middle-$i';
    if (await stop) break;
    out = '$out-after-$i';
    i = i + 1;
  } while (await keepGoing);
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

Future<String> asyncForAwaitGuardContinueBreak(
  int limit,
  Future<bool> skip,
  Future<bool> stop,
) async {
  var out = 'patched-for-await-guard-continue-break';
  for (var i = 0; limit > i; i = i + 1) {
    out = '$out-before-$i';
    if (await skip) continue;
    out = '$out-mid-$i';
    if (await stop) break;
    out = '$out-after-$i';
  }
  return out;
}

Future<String> asyncForAwaitGuardContinueBreakAwaitUpdate(
  int limit,
  Future<bool> skip,
  Future<bool> stop,
  Future<int> next,
) async {
  var out = 'patched-for-await-guard-continue-break-await-update';
  for (var i = 0; limit > i; i = await next) {
    out = '$out-before-$i';
    if (await skip) continue;
    out = '$out-mid-$i';
    if (await stop) break;
    out = '$out-after-$i';
  }
  return out;
}

Future<String> asyncForAwaitUpdate(int limit, Future<int> next) async {
  var out = 'patched-for-await-update';
  for (var i = 0; limit > i; i = await next) {
    out = '$out-$i';
  }
  return out;
}

Future<String> asyncForAwaitUpdateBranchLocal(
  int limit,
  Future<int> next,
) async {
  var out = 'patched-for-await-update-branch';
  for (var i = 0; limit > i; i = await next) {
    final segment = i == 1 ? 'one' : 'many';
    out = '$out-$segment-$i';
  }
  return out;
}

Future<String> asyncForNestedAwaitBranchLocal(
  int limit,
  bool premium,
  Future<String> ready,
) async {
  var out = 'patched-for-nested-await-branch';
  for (var i = 0; limit > i; i = i + 1) {
    if (i == 0) {
      final state = await ready;
      if (premium) {
        final tier = 'patched-for-nested-pro';
        out = '$out-$state-$tier';
      } else {
        final tier = 'patched-for-nested-basic';
        out = '$out-$state-$tier';
      }
    } else {
      final state = 'patched-for-nested-tail';
      out = '$out-$state-$i';
    }
  }
  return out;
}

Future<String> asyncForAwaitUpdateNestedBranchLocal(
  int limit,
  bool premium,
  Future<String> ready,
  Future<int> next,
) async {
  var out = 'patched-for-await-update-nested-branch';
  for (var i = 0; limit > i; i = await next) {
    if (i == 0) {
      final state = await ready;
      if (premium) {
        final tier = 'patched-for-await-update-nested-pro';
        out = '$out-$state-$tier';
      } else {
        final tier = 'patched-for-await-update-nested-basic';
        out = '$out-$state-$tier';
      }
    } else {
      final state = 'patched-for-await-update-nested-tail';
      out = '$out-$state-$i';
    }
  }
  return out;
}

Future<String> asyncForMultiUpdate(int limit) async {
  var out = 'patched-for-multi-update';
  for (var i = 0, j = 0; limit > i; i = i + 1, j = j + 2) {
    out = '$out-$i-$j';
  }
  return out;
}
