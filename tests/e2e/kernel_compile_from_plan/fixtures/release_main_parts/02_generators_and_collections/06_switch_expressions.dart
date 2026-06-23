String syncSwitchLabel(String tier) {
  return tier == 'gold' ? 'base-switch-gold' : 'base-switch-other';
}

String syncSwitchMultiValueLabel(String tier) {
  return tier == 'gold' ? 'base-switch-premium' : 'base-switch-standard';
}

Future<String> asyncSwitchLabel(String tier) async {
  return tier == 'gold' ? 'base-async-switch-gold' : 'base-async-switch-other';
}

Future<String> asyncSwitchMultiValueLabel(String tier) async {
  return tier == 'gold'
      ? 'base-async-switch-premium'
      : 'base-async-switch-standard';
}

Future<String> asyncAwaitThenSwitchLabel(Future<String> ready) async {
  final tier = await ready;
  return tier == 'gold' ? 'base-await-switch-gold' : 'base-await-switch-other';
}

Future<String> asyncAwaitThenSwitchMultiValueLabel(Future<String> ready) async {
  final tier = await ready;
  return tier == 'gold'
      ? 'base-await-switch-premium'
      : 'base-await-switch-standard';
}

int syncSwitchScore(int code) {
  return code == 7 ? 70 : 10;
}

int syncSwitchMultiValueScore(int code) {
  return code == 7 ? 80 : 10;
}

List<String> switchListNames(String tier) {
  return ['base-switch-list-head', tier, 'base-switch-list-tail'];
}

Map<String, String> switchMapLabels(int code) {
  return {'state': 'base-switch-map-$code'};
}

String unchangedGuardedSwitchLabel(String tier, bool enabled) {
  return switch (tier) {
    'gold' when enabled => 'guarded-switch-gold',
    _ => 'guarded-switch-other',
  };
}

Future<String> asyncGuardedSwitchLabel(String tier, bool enabled) async {
  return enabled
      ? 'base-async-guarded-switch-$tier'
      : 'base-async-guarded-switch-other';
}

Future<String> asyncAwaitThenGuardedSwitchLabel(
  Future<String> ready,
  bool enabled,
) async {
  final tier = await ready;
  return enabled
      ? 'base-await-guarded-switch-$tier'
      : 'base-await-guarded-switch-other';
}

Future<String> asyncAwaitConditionSwitchTryCatchRecoveryLabel(
  Future<String> ready,
  Future<String> recovery,
) async {
  final tier = await ready;
  if (tier == 'blocked') {
    final label = await recovery;
    return 'base-await-condition-switch-try-catch-caught-$label';
  }
  return 'base-await-condition-switch-try-catch-$tier';
}

Future<String> asyncAwaitConditionSwitchTryFinallyCleanupLabel(
  Future<String> ready,
  Future<String> cleanup,
) async {
  final tier = await ready;
  await cleanup;
  return 'base-await-condition-switch-try-finally-$tier';
}

Future<String> asyncAwaitThenSwitchTryCatchRecoveryLabel(
  Future<String> ready,
  Future<String> recovery,
) async {
  final tier = await ready;
  if (tier == 'blocked') {
    final label = await recovery;
    return 'base-await-then-switch-try-catch-caught-$label';
  }
  return 'base-await-then-switch-try-catch-$tier';
}

Future<String> asyncAwaitThenSwitchTryFinallyCleanupLabel(
  Future<String> ready,
  Future<String> cleanup,
) async {
  final tier = await ready;
  await cleanup;
  return 'base-await-then-switch-try-finally-$tier';
}

Future<String> asyncDoubleAwaitSwitchTryCatchFinallyRecoveryLabel(
  Future<String> ready,
  Future<String> recovery,
  Future<String> cleanup,
) async {
  final tier = await ready;
  if (tier == 'blocked') {
    final label = await recovery;
    await cleanup;
    return 'base-double-await-switch-try-catch-finally-caught-$label';
  }
  await cleanup;
  return 'base-double-await-switch-try-catch-finally-$tier';
}

Future<String> asyncDoubleAwaitSwitchTryFinallyCleanupLabel(
  Future<String> ready,
  Future<String> cleanup,
) async {
  final tier = await ready;
  await cleanup;
  return 'base-double-await-switch-try-finally-$tier';
}

Future<String> asyncSwitchAwaitGuardLabel(
  String tier,
  Future<bool> enabled,
) async {
  if (await enabled) {
    return 'base-switch-await-guard-$tier';
  }
  return 'base-switch-await-guard-other';
}

Future<String> asyncAwaitThenSwitchAwaitGuardLabel(
  Future<String> ready,
  Future<bool> enabled,
) async {
  final tier = await ready;
  if (await enabled) {
    return 'base-await-switch-await-guard-$tier';
  }
  return 'base-await-switch-await-guard-other';
}
