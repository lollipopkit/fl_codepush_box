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

int combine(int left, int right) {
  return left + right;
}

Object? maybeNull() {
  return null;
}

Future<Object?> asyncNullableChoice(bool enabled) async {
  return enabled ? null : 'base-null';
}

Future<Object?> asyncAwaitThenNullableChoice(Future<bool> ready) async {
  final enabled = await ready;
  return enabled ? null : 'base-await-null';
}

String label(String name) {
  return 'hi $name';
}

String syncTryFinallyTail(String name) {
  var out = 'base-sync-finally';
  try {
    out = '$out-body-$name';
  } finally {
    out = '$out-cleanup';
  }
  return out;
}

String syncTryCatchTail(String name) {
  var out = 'base-sync-catch';
  try {
    out = '$out-ok-$name';
  } catch (e) {
    out = '$out-caught-$e';
  }
  return out;
}

String syncTryCatchLocalStatementTail(String name) {
  var out = 'base-sync-catch-local-statement';
  try {
    label(name);
  } catch (e) {
    final message = 'base-sync-catch-local-message-$e';
    out = message;
  }
  return out;
}

String syncTryCatchBodyLocalStatementTail(String name) {
  var out = 'base-sync-catch-body-local-statement';
  try {
    final message = 'base-sync-catch-body-local-message-$name';
    out = message;
  } catch (e) {
    label('base-sync-catch-body-local-caught-$e');
  }
  return out;
}

String syncTryCatchReturnValue(String name) {
  try {
    return 'base-catch-return-$name';
  } catch (e) {
    return 'base-caught-return-$e';
  }
}

String syncTryCatchLocalReturnValue(String name) {
  try {
    return 'base-catch-local-return-$name';
  } catch (e) {
    final message = 'base-catch-local-caught-$e';
    return message;
  }
}

String syncTryCatchFinallyReturnValue(String name) {
  try {
    return 'base-catch-finally-return-$name';
  } catch (e) {
    return 'base-catch-finally-caught-$e';
  } finally {
    label('base-catch-finally-cleanup-$name');
  }
}

String syncTryCatchStatementTail(String name) {
  try {
    label(name);
  } catch (e) {
    label('$e');
  }
  return 'base-sync-catch-statement-$name';
}

void syncTryCatchStatementVoid(String name) {
  try {
    label(name);
  } catch (e) {
    label('base-catch-void-$e');
  }
}

String syncTryFinallyStatementTail(String name) {
  try {
    label(name);
  } finally {
    label('base-cleanup-$name');
  }
  return 'base-sync-finally-statement-$name';
}

String syncTryFinallyLocalStatementTail(String name) {
  try {
    label(name);
  } finally {
    final cleanup = 'base-cleanup-local-$name';
    label(cleanup);
  }
  return 'base-sync-finally-local-statement-$name';
}

String syncTryFinallyBodyLocalStatementTail(String name) {
  try {
    final message = 'base-finally-body-local-$name';
    label(message);
  } finally {
    label('base-finally-body-cleanup-$name');
  }
  return 'base-sync-finally-body-local-statement-$name';
}

void syncTryFinallyStatementVoid(String name) {
  try {
    label(name);
  } finally {
    label('base-void-cleanup-$name');
  }
}

String syncTryFinallyReturnValue(String name) {
  try {
    return 'base-finally-return-$name';
  } finally {
    label('base-return-cleanup-$name');
  }
}

String syncIfSideEffectTail(bool enabled, String name) {
  if (enabled) {
    label('base-if-side-effect-$name');
  }
  return 'base-if-tail-$name';
}

String syncIfElseSideEffectTail(bool enabled, String name) {
  if (enabled) {
    label('base-ifelse-side-effect-on-$name');
  } else {
    label('base-ifelse-side-effect-off-$name');
  }
  return 'base-ifelse-tail-$name';
}

String syncIfElseLocalSideEffectTail(bool enabled, String name) {
  if (enabled) {
    final message = 'base-ifelse-local-on-$name';
    label(message);
  } else {
    final message = 'base-ifelse-local-off-$name';
    label(message);
  }
  return 'base-ifelse-local-tail-$name';
}

String displayName(User user) {
  return user.name;
}

Future<String> asyncDisplayName(User user) async {
  return user.name;
}

Future<String> asyncAwaitThenReadField(User user, Future<String> ready) async {
  final prefix = await ready;
  return 'base-await-field:$prefix ${user.name}';
}

User makeUser() {
  return User('base', 'base-label');
}

Future<User> asyncMakeUser() async {
  return User('base-async', 'base-async-label');
}

Future<User> asyncAwaitThenMakeUser(Future<String> ready) async {
  final label = await ready;
  return User('base-await-user', label);
}

Config makeConfig() {
  return Config(name: 'base', label: 'base-label');
}

Future<Config> asyncMakeConfig() async {
  return Config(name: 'base-async', label: 'base-async-label');
}

Future<Config> asyncAwaitThenMakeConfig(Future<String> ready) async {
  final label = await ready;
  return Config(name: 'base-await-config', label: label);
}

String updateConfigLabel(Config config, String label) {
  config.label = label;
  return config.label;
}

Future<String> asyncUpdateConfigLabel(Config config, String label) async {
  config.label = label;
  return config.label;
}

Future<String> asyncAwaitThenUpdateConfigLabel(
  Config config,
  Future<String> ready,
) async {
  final label = await ready;
  config.label = label;
  return config.label;
}

Box<String> makeStringBox() {
  return Box<String>('base-box');
}

Future<Box<String>> asyncMakeStringBox() async {
  return Box<String>('base-async-box');
}

Future<Box<String>> asyncAwaitThenMakeStringBox(Future<String> ready) async {
  final value = await ready;
  return Box<String>('base-await-box:$value');
}

String dynamicNamedCall() {
  return Greeter().surround('base', prefix: '[', suffix: ']');
}

Future<String> asyncDynamicNamedCall() async {
  return Greeter().surround('base-async', prefix: '[', suffix: ']');
}

Future<String> asyncAwaitThenDynamicCall(Future<String> ready) async {
  final value = await ready;
  return Greeter().surround(value, prefix: 'base-await-dynamic[', suffix: ']');
}

bool sameObject(Object value) {
  return false;
}

Future<bool> asyncSameObject(Object value) async {
  return false;
}

Future<bool> asyncAwaitThenSameObject(Future<Object> ready) async {
  final value = await ready;
  return false;
}

Future<bool> asyncAwaitThenIsString(Future<Object> ready) async {
  final value = await ready;
  return value is int;
}

Future<Object> asyncAwaitThenAsStringList(Future<Object> ready) async {
  final value = await ready;
  return value as List<int>;
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

String syncLocalMutation(String name) {
  var out = 'base-local';
  out = '$out-$name';
  return out;
}

Future<String> asyncLocalMutation(String name) async {
  var out = 'base-async-local';
  out = '$out-$name';
  return out;
}

Future<String> asyncAwaitThenLocalMutation(
  Future<String> ready,
  String name,
) async {
  var out = await ready;
  out = 'base-await-local:$out-$name';
  return out;
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

String Function([String? suffix]) optionalPositionalEscapingGreeting(
  String name,
) {
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
  return (enabled, premium) => enabled && (premium || name == 'vip') || !enabled
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

String directCallbackValue(String Function() callback) {
  return '${callback()} base-direct';
}

String directCallbackArg(String Function(String) callback, String value) {
  return '${callback(value)} base-arg';
}

String directCallbackNamed(
  String Function({required String value}) callback,
  String value,
) {
  return '${callback(value: value)} base-named';
}

String directCallbackMixed(
  String Function(String value, {required String suffix}) callback,
  String value,
  String suffix,
) {
  return '${callback(value, suffix: suffix)} base-mixed';
}

Future<String> asyncDirectCallbackMixed(
  String Function(String value, {required String suffix}) callback,
  String value,
  String suffix,
) async {
  return '${callback(value, suffix: suffix)} base-async-mixed';
}

Future<String> asyncAwaitThenDirectCallbackMixed(
  String Function(String value, {required String suffix}) callback,
  Future<String> ready,
  String suffix,
) async {
  final value = await ready;
  return '${callback(value, suffix: suffix)} base-await-callback';
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

Future<String> asyncAlwaysThrow() async {
  return throw 'base-async-boom';
}

Future<String> asyncAwaitThenAlwaysThrow(Future<String> ready) async {
  final value = await ready;
  return throw 'base-await-throw:$value';
}

Future<String> asyncLabel() async {
  return 'base-async';
}

Future<String> asyncConcatLabel(String name) async {
  return 'base-async $name';
}

Future<String> asyncAwaitThenConcatLabel(Future<String> ready) async {
  final value = await ready;
  return 'base-await-concat $value';
}

Future<double> asyncStaticHelperValue() async {
  return helper() + 2.5;
}

Future<double> asyncAwaitThenStaticHelperValue(Future<double> ready) async {
  final value = await ready;
  return value + 1.0;
}

Future<int> asyncAwaitThenStaticCombine(Future<int> ready, int right) async {
  final left = await ready;
  return combine(right, left);
}

Future<int> asyncArithmeticValue(int value) async {
  return value + 1;
}

Future<int> asyncAwaitThenArithmeticValue(Future<int> ready) async {
  final value = await ready;
  return value + 4;
}

Future<int> asyncSubtractValue(int value) async {
  return value - 1;
}

Future<int> asyncAwaitThenSubtractValue(Future<int> ready) async {
  final value = await ready;
  return value - 6;
}

Future<int> asyncMultiplyValue(int value) async {
  return value * 2;
}

Future<int> asyncAwaitThenMultiplyValue(Future<int> ready) async {
  final value = await ready;
  return value * 8;
}

Future<double> asyncDivideValue(int value) async {
  return value / 2;
}

Future<double> asyncAwaitThenDivideValue(Future<int> ready) async {
  final value = await ready;
  return value / 10;
}

Future<bool> asyncLogicalFlag(bool enabled, bool premium) async {
  return enabled && premium || !enabled;
}

Future<bool> asyncAwaitThenLogicalFlag(Future<bool> ready, bool premium) async {
  final enabled = await ready;
  return enabled && premium || !enabled;
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

Future<String> awaitedLabel(bool enabled) async {
  if (await Future.value(enabled))
    return 'base ${await Future.value('awaited')}';
  return 'base disabled';
}

Future<String> awaitedLocalLabel(String name) async {
  try {
    final base = 'base-local';
    final prefix = await Future.value(base);
    if (name == 'Ada') return '$prefix ${await Future.value('done')}';
    return '$prefix $name';
  } catch (e) {
    return 'base-caught $e';
  }
}

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

Future<String> awaitedCatchTail(Future<String> ready) async {
  var out = 'base-catch-tail';
  try {
    final value = await ready;
    out = '$out-ok-$value';
  } catch (e) {
    out = '$out-caught-$e';
  }
  return out;
}

Future<String> awaitedCatchAwaitTail(
  Future<String> ready,
  Future<String> recovery,
) async {
  var out = 'base-catch-await-tail';
  try {
    final value = await ready;
    out = '$out-ok-$value';
  } catch (e) {
    final recovered = await recovery;
    out = '$out-caught-$e-$recovered';
  }
  return out;
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

Future<String> awaitedFinallyStatementTail(Future<String> ready) async {
  var out = 'base-finally-tail';
  try {
    final value = await ready;
    out = '$out-body-$value';
  } finally {
    final cleanup = 'base-finally-tail-cleanup';
    out = '$out-$cleanup';
  }
  return '$out-done';
}

Future<String> awaitedFinallyAwaitCleanupTail(
  Future<String> ready,
  Future<String> cleanup,
) async {
  var out = 'base-finally-await-tail';
  try {
    final value = await ready;
    out = '$out-body-$value';
  } finally {
    final marker = await cleanup;
    out = '$out-cleanup-$marker';
  }
  return '$out-done';
}

Future<String> awaitedCatchFinallyCleanup(
  Future<String> ready,
  Future<String> cleanup,
) async {
  try {
    try {
      final value = await ready;
      return 'base-catch-finally-ok-$value';
    } catch (e) {
      return 'base-catch-finally-caught-$e';
    }
  } finally {
    await cleanup;
  }
}

Future<String> awaitedCatchFinallyAwaitTail(
  Future<String> ready,
  Future<String> recovery,
  Future<String> cleanup,
) async {
  var out = 'base-catch-finally-await-tail';
  try {
    try {
      final value = await ready;
      out = '$out-ok-$value';
    } catch (e) {
      final recovered = await recovery;
      out = '$out-caught-$e-$recovered';
    }
  } finally {
    final marker = await cleanup;
    out = '$out-cleanup-$marker';
  }
  return out;
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

Future<String> asyncIfTryFinallyAwaitTail(
  bool enabled,
  Future<String> ready,
  Future<String> cleanup,
) async {
  var out = 'base-if-try-finally-await-tail';
  if (enabled) {
    try {
      final value = await ready;
      out = '$out-on-$value';
    } finally {
      final marker = await cleanup;
      out = '$out-cleanup-$marker';
    }
  } else {
    out = '$out-off';
  }
  return out;
}

Future<String> asyncIfTryCatchAwaitTail(
  bool enabled,
  Future<String> ready,
  Future<String> recovery,
) async {
  var out = 'base-if-try-catch-await-tail';
  if (enabled) {
    try {
      final value = await ready;
      out = '$out-on-$value';
    } catch (e) {
      final recovered = await recovery;
      out = '$out-caught-$e-$recovered';
    }
  } else {
    out = '$out-off';
  }
  return out;
}

Future<String> asyncIfElseTryFinallyCatchAwaitTail(
  bool enabled,
  Future<String> ready,
  Future<String> recovery,
  Future<String> cleanup,
) async {
  var out = 'base-ifelse-try-finally-catch-await-tail';
  if (enabled) {
    try {
      final value = await ready;
      out = '$out-on-$value';
    } finally {
      final marker = await cleanup;
      out = '$out-cleanup-$marker';
    }
  } else {
    try {
      final value = await ready;
      out = '$out-off-$value';
    } catch (e) {
      final recovered = await recovery;
      out = '$out-caught-$e-$recovered';
    }
  }
  return out;
}

Future<String> asyncNestedBranchLocal(bool enabled, bool premium) async {
  if (enabled) {
    final state = 'base-nested-enabled';
    if (premium) {
      final tier = 'base-nested-pro';
      return '$state-$tier';
    } else {
      final tier = 'base-nested-basic';
      return '$state-$tier';
    }
  } else {
    final state = 'base-nested-disabled';
    if (premium) {
      final tier = 'base-nested-disabled-pro';
      return '$state-$tier';
    }
    final tier = 'base-nested-disabled-basic';
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
      final tier = 'base-nested-await-pro';
      return '$state-$tier';
    } else {
      final tier = 'base-nested-await-basic';
      return '$state-$tier';
    }
  } else {
    final state = 'base-nested-await-disabled';
    if (premium) {
      final tier = await ready;
      return '$state-$tier';
    }
    final tier = 'base-nested-await-disabled-basic';
    return '$state-$tier';
  }
}

Future<String> asyncIfElseSideEffectTail(
  bool enabled,
  Future<String> ready,
) async {
  var out = 'base-ifelse-side-effect';
  if (enabled) {
    final state = await ready;
    out = '$out-$state';
  } else {
    final state = 'base-ifelse-disabled';
    out = '$out-$state';
  }
  out = '$out-tail';
  return out;
}

Future<String> asyncIfSideEffectTail(bool enabled, Future<String> ready) async {
  var out = 'base-if-side-effect';
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
  return enabled ? await ready : 'base-conditional-disabled';
}

Future<String> asyncLessThanAwaitTail(int limit, Future<String> ready) async {
  if (limit < 2) return await ready;
  return 'base-less-than-tail';
}

Future<String> asyncLessEqualAwaitTail(int limit, Future<String> ready) async {
  if (limit <= 2) return await ready;
  return 'base-less-equal-tail';
}

Future<String> asyncGreaterEqualAwaitTail(
  int limit,
  Future<String> ready,
) async {
  if (limit >= 2) return await ready;
  return 'base-greater-equal-tail';
}

Future<String> asyncNotEqualAwaitTail(
  String marker,
  Future<String> ready,
) async {
  if (marker != 'skip') return await ready;
  return 'base-not-equal-tail';
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

Future<String> asyncWhileContinueBreak(int limit) async {
  var i = 0;
  var out = 'base-while-continue-break';
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
  var out = 'base-while-await-continue-break';
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
  var out = 'base-while-await-condition';
  while (await keepGoing) {
    out = '$out-$i';
    if (i == 0) break;
    i = i + 1;
  }
  return out;
}

Future<String> asyncWhileAwaitConditionContinueBreak(
  Future<bool> keepGoing,
  Future<bool> skip,
  Future<bool> stop,
) async {
  var i = 0;
  var out = 'base-while-await-condition-continue-break';
  while (await keepGoing) {
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

Future<String> asyncWhileNestedAwaitBranchLocal(
  int limit,
  bool premium,
  Future<String> ready,
) async {
  var i = 0;
  var out = 'base-while-nested-await-branch';
  while (limit > i) {
    if (i == 0) {
      final state = await ready;
      if (premium) {
        final tier = 'base-while-nested-pro';
        out = '$out-$state-$tier';
      } else {
        final tier = 'base-while-nested-basic';
        out = '$out-$state-$tier';
      }
    } else {
      final state = 'base-while-nested-tail';
      out = '$out-$state-$i';
    }
    i = i + 1;
  }
  return out;
}

Future<String> asyncWhileAwaitConditionNestedAwaitBranchLocal(
  Future<bool> keepGoing,
  bool premium,
  Future<String> ready,
) async {
  var i = 0;
  var out = 'base-while-await-condition-nested-branch';
  while (await keepGoing) {
    if (i == 0) {
      final state = await ready;
      if (premium) {
        final tier = 'base-while-await-condition-nested-pro';
        out = '$out-$state-$tier';
      } else {
        final tier = 'base-while-await-condition-nested-basic';
        out = '$out-$state-$tier';
      }
    } else {
      final state = 'base-while-await-condition-nested-tail';
      out = '$out-$state-$i';
    }
    i = i + 1;
  }
  return out;
}
