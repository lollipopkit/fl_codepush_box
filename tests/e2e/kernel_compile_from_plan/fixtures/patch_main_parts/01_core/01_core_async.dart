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
  return left + right + 10;
}

Object? maybeNull() {
  return null;
}

Future<Object?> asyncNullableChoice(bool enabled) async {
  return enabled ? null : 'patched-null';
}

Future<Object?> asyncAwaitThenNullableChoice(Future<bool> ready) async {
  final enabled = await ready;
  return enabled ? null : 'patched-await-null';
}

String label(String name) {
  return 'hello $name!';
}

String syncTryFinallyTail(String name) {
  var out = 'patched-sync-finally';
  try {
    out = '$out-body-$name';
  } finally {
    out = '$out-cleanup';
  }
  return out;
}

String syncTryCatchTail(String name) {
  var out = 'patched-sync-catch';
  try {
    out = '$out-ok-$name';
  } catch (e) {
    out = '$out-caught-$e';
  }
  return out;
}

String syncTryCatchLocalStatementTail(String name) {
  var out = 'patched-sync-catch-local-statement';
  try {
    label(name);
  } catch (e) {
    final message = 'patched-sync-catch-local-message-$e';
    out = message;
  }
  return out;
}

String syncTryCatchBodyLocalStatementTail(String name) {
  var out = 'patched-sync-catch-body-local-statement';
  try {
    final message = 'patched-sync-catch-body-local-message-$name';
    out = message;
  } catch (e) {
    label('patched-sync-catch-body-local-caught-$e');
  }
  return out;
}

String syncTryCatchReturnValue(String name) {
  try {
    return 'patched-catch-return-$name';
  } catch (e) {
    return 'patched-caught-return-$e';
  }
}

String syncTryCatchLocalReturnValue(String name) {
  try {
    return 'patched-catch-local-return-$name';
  } catch (e) {
    final message = 'patched-catch-local-caught-$e';
    return message;
  }
}

String syncTryCatchFinallyReturnValue(String name) {
  try {
    return 'patched-catch-finally-return-$name';
  } catch (e) {
    return 'patched-catch-finally-caught-$e';
  } finally {
    label('patched-catch-finally-cleanup-$name');
  }
}

String syncTryCatchStatementTail(String name) {
  try {
    label(name);
  } catch (e) {
    label('$e');
  }
  return 'patched-sync-catch-statement-$name';
}

void syncTryCatchStatementVoid(String name) {
  try {
    label(name);
  } catch (e) {
    label('patched-catch-void-$e');
  }
}

String syncTryFinallyStatementTail(String name) {
  try {
    label(name);
  } finally {
    label('patched-cleanup-$name');
  }
  return 'patched-sync-finally-statement-$name';
}

String syncTryFinallyLocalStatementTail(String name) {
  try {
    label(name);
  } finally {
    final cleanup = 'patched-cleanup-local-$name';
    label(cleanup);
  }
  return 'patched-sync-finally-local-statement-$name';
}

String syncTryFinallyBodyLocalStatementTail(String name) {
  try {
    final message = 'patched-finally-body-local-$name';
    label(message);
  } finally {
    label('patched-finally-body-cleanup-$name');
  }
  return 'patched-sync-finally-body-local-statement-$name';
}

void syncTryFinallyStatementVoid(String name) {
  try {
    label(name);
  } finally {
    label('patched-void-cleanup-$name');
  }
}

String syncTryFinallyReturnValue(String name) {
  try {
    return 'patched-finally-return-$name';
  } finally {
    label('patched-return-cleanup-$name');
  }
}

String syncIfSideEffectTail(bool enabled, String name) {
  if (enabled) {
    label('patched-if-side-effect-$name');
  }
  return 'patched-if-tail-$name';
}

String syncIfElseSideEffectTail(bool enabled, String name) {
  if (enabled) {
    label('patched-ifelse-side-effect-on-$name');
  } else {
    label('patched-ifelse-side-effect-off-$name');
  }
  return 'patched-ifelse-tail-$name';
}

String syncIfElseLocalSideEffectTail(bool enabled, String name) {
  if (enabled) {
    final message = 'patched-ifelse-local-on-$name';
    label(message);
  } else {
    final message = 'patched-ifelse-local-off-$name';
    label(message);
  }
  return 'patched-ifelse-local-tail-$name';
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

Future<User> asyncAwaitThenMakeUser(Future<String> ready) async {
  final label = await ready;
  return User('patched-await-user', label);
}

Config makeConfig() {
  return Config(name: 'patched', label: 'patched-label');
}

Future<Config> asyncMakeConfig() async {
  return Config(name: 'patched-async', label: 'patched-async-label');
}

Future<Config> asyncAwaitThenMakeConfig(Future<String> ready) async {
  final label = await ready;
  return Config(name: 'patched-await-config', label: label);
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

Future<String> asyncAwaitThenAlwaysThrow(Future<String> ready) async {
  final value = await ready;
  return throw 'patched-await-throw:$value';
}

Future<String> asyncLabel() async {
  return 'patched-async';
}

Future<String> asyncConcatLabel(String name) async {
  return 'patched-async $name';
}

Future<String> asyncAwaitThenConcatLabel(Future<String> ready) async {
  final value = await ready;
  return 'patched-await-concat $value';
}

Future<double> asyncStaticHelperValue() async {
  return helper() + 3.5;
}

Future<double> asyncAwaitThenStaticHelperValue(Future<double> ready) async {
  final value = await ready;
  return value + helper();
}

Future<int> asyncAwaitThenStaticCombine(Future<int> ready, int right) async {
  final left = await ready;
  return combine(left, right);
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

Future<double> asyncAwaitThenDivideValue(Future<int> ready) async {
  final value = await ready;
  return value / 11;
}

Future<bool> asyncLogicalFlag(bool enabled, bool premium) async {
  return enabled && !premium || premium;
}

Future<bool> asyncAwaitThenLogicalFlag(Future<bool> ready, bool premium) async {
  final enabled = await ready;
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

Future<String> awaitedCatchTail(Future<String> ready) async {
  var out = 'patched-catch-tail';
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
  var out = 'patched-catch-await-tail';
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

Future<String> awaitedFinallyStatementTail(Future<String> ready) async {
  var out = 'patched-finally-tail';
  try {
    final value = await ready;
    out = '$out-body-$value';
  } finally {
    final cleanup = 'patched-finally-tail-cleanup';
    out = '$out-$cleanup';
  }
  return '$out-done';
}

Future<String> awaitedFinallyAwaitCleanupTail(
  Future<String> ready,
  Future<String> cleanup,
) async {
  var out = 'patched-finally-await-tail';
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
      return 'patched-catch-finally-ok-$value';
    } catch (e) {
      return 'patched-catch-finally-caught-$e';
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
  var out = 'patched-catch-finally-await-tail';
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
    final status = 'patched-branch-enabled';
    return status;
  } else {
    final status = 'patched-branch-disabled';
    return status;
  }
}

Future<String> asyncIfTryFinallyAwaitTail(
  bool enabled,
  Future<String> ready,
  Future<String> cleanup,
) async {
  var out = 'patched-if-try-finally-await-tail';
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
  var out = 'patched-if-try-catch-await-tail';
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
  var out = 'patched-ifelse-try-finally-catch-await-tail';
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

Future<String> asyncIfElseBothTryFinallyAwaitTail(
  bool enabled,
  Future<String> ready,
  Future<String> cleanup,
) async {
  var out = 'patched-ifelse-both-try-finally-await-tail';
  if (enabled) {
    try {
      final value = await ready;
      out = '$out-on-$value';
    } finally {
      final marker = await cleanup;
      out = '$out-on-cleanup-$marker';
    }
  } else {
    try {
      final value = await ready;
      out = '$out-off-$value';
    } finally {
      final marker = await cleanup;
      out = '$out-off-cleanup-$marker';
    }
  }
  out = '$out-tail';
  return out;
}

Future<String> asyncIfElseBothTryCatchFinallyAwaitTail(
  bool enabled,
  Future<String> ready,
  Future<String> recovery,
  Future<String> cleanup,
) async {
  var out = 'patched-ifelse-both-catch-finally-await-tail';
  if (enabled) {
    try {
      try {
        final value = await ready;
        out = '$out-on-$value';
      } catch (e) {
        final recovered = await recovery;
        out = '$out-on-caught-$e-$recovered';
      }
    } finally {
      final marker = await cleanup;
      out = '$out-on-cleanup-$marker';
    }
  } else {
    try {
      try {
        final value = await ready;
        out = '$out-off-$value';
      } catch (e) {
        final recovered = await recovery;
        out = '$out-off-caught-$e-$recovered';
      }
    } finally {
      final marker = await cleanup;
      out = '$out-off-cleanup-$marker';
    }
  }
  out = '$out-tail';
  return out;
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

Future<String> asyncConditionalBothAwaitExpr(
  bool enabled,
  Future<String> ready,
  Future<String> fallback,
) async {
  return enabled ? await ready : await fallback;
}

Future<String> asyncAwaitConditionConditionalBothAwaitExpr(
  Future<bool> enabled,
  Future<String> ready,
  Future<String> fallback,
) async {
  return await enabled ? await ready : await fallback;
}

Future<String> asyncNestedConditionalAwaitExpr(
  bool enabled,
  bool premium,
  Future<String> ready,
  Future<String> fallback,
  Future<String> disabled,
) async {
  return enabled ? (premium ? await ready : await fallback) : await disabled;
}

Future<String> asyncAwaitConditionNestedConditionalAwaitExpr(
  Future<bool> enabled,
  bool premium,
  Future<String> ready,
  Future<String> fallback,
  Future<String> disabled,
) async {
  return await enabled
      ? (premium ? await ready : await fallback)
      : await disabled;
}

Future<bool> asyncLogicalAndAwaitLeft(Future<bool> ready, bool fallback) async {
  return await ready && fallback;
}

Future<bool> asyncLogicalAndAwaitRight(bool enabled, Future<bool> ready) async {
  return enabled && await ready;
}

Future<bool> asyncLogicalOrAwaitLeft(Future<bool> ready, bool fallback) async {
  return await ready || fallback;
}

Future<bool> asyncNestedLogicalAwait(
  bool enabled,
  Future<bool> ready,
  Future<bool> fallback,
) async {
  return enabled && (await ready || await fallback);
}

Future<String> asyncIfLogicalAndAwaitTail(
  bool enabled,
  Future<bool> ready,
) async {
  var out = 'patched-if-logical-and-await';
  if (enabled && await ready) {
    out = '$out-on';
  }
  out = '$out-tail';
  return out;
}

Future<String> asyncIfElseLogicalOrAwaitTail(
  Future<bool> ready,
  bool fallback,
) async {
  var out = 'patched-ifelse-logical-or-await';
  if (await ready || fallback) {
    out = '$out-on';
  } else {
    out = '$out-off';
  }
  out = '$out-tail';
  return out;
}

Future<String> asyncIfNestedLogicalAwaitReturn(
  bool enabled,
  Future<bool> ready,
  Future<bool> fallback,
) async {
  if (enabled && (await ready || await fallback)) {
    return 'patched-if-nested-logical-await-on';
  }
  return 'patched-if-nested-logical-await-off';
}

Future<String> asyncWhileLogicalAwaitCondition(
  bool enabled,
  Future<bool> keepGoing,
) async {
  var i = 0;
  var out = 'patched-while-logical-await-condition';
  while (enabled && await keepGoing) {
    out = '$out-$i';
    if (i == 0) break;
    i = i + 1;
  }
  return out;
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

Future<String> asyncWhileAwaitConditionContinueBreak(
  Future<bool> keepGoing,
  Future<bool> skip,
  Future<bool> stop,
) async {
  var i = 0;
  var out = 'patched-while-await-condition-continue-break';
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

Future<String> asyncWhileAwaitConditionNestedAwaitBranchLocal(
  Future<bool> keepGoing,
  bool premium,
  Future<String> ready,
) async {
  var i = 0;
  var out = 'patched-while-await-condition-nested-branch';
  while (await keepGoing) {
    if (i == 0) {
      final state = await ready;
      if (premium) {
        final tier = 'patched-while-await-condition-nested-pro';
        out = '$out-$state-$tier';
      } else {
        final tier = 'patched-while-await-condition-nested-basic';
        out = '$out-$state-$tier';
      }
    } else {
      final state = 'patched-while-await-condition-nested-tail';
      out = '$out-$state-$i';
    }
    i = i + 1;
  }
  return out;
}
