String syncSwitchLabel(String tier) {
  return switch (tier) {
    'gold' => 'patched-switch-gold',
    'silver' => 'patched-switch-silver',
    _ => 'patched-switch-other',
  };
}

String syncSwitchMultiValueLabel(String tier) {
  return switch (tier) {
    'gold' || 'vip' => 'patched-switch-premium',
    'trial' || 'guest' => 'patched-switch-limited',
    _ => 'patched-switch-standard',
  };
}

Future<String> asyncSwitchLabel(String tier) async {
  return switch (tier) {
    'gold' => 'patched-async-switch-gold',
    'silver' => 'patched-async-switch-silver',
    _ => 'patched-async-switch-other',
  };
}

Future<String> asyncSwitchMultiValueLabel(String tier) async {
  return switch (tier) {
    'gold' || 'vip' => 'patched-async-switch-premium',
    'trial' || 'guest' => 'patched-async-switch-limited',
    _ => 'patched-async-switch-standard',
  };
}

Future<String> asyncAwaitThenSwitchLabel(Future<String> ready) async {
  final tier = await ready;
  return switch (tier) {
    'gold' => 'patched-await-switch-gold',
    'silver' => 'patched-await-switch-silver',
    _ => 'patched-await-switch-other',
  };
}

Future<String> asyncAwaitThenSwitchMultiValueLabel(Future<String> ready) async {
  final tier = await ready;
  return switch (tier) {
    'gold' || 'vip' => 'patched-await-switch-premium',
    'trial' || 'guest' => 'patched-await-switch-limited',
    _ => 'patched-await-switch-standard',
  };
}

int syncSwitchScore(int code) {
  return switch (code) {
    7 => 70,
    9 => 90,
    _ => 10,
  };
}

int syncSwitchMultiValueScore(int code) {
  return switch (code) {
    7 || 8 => 80,
    9 || 10 => 100,
    _ => 10,
  };
}

List<String> switchListNames(String tier) {
  return [
    'patched-switch-list-head',
    switch (tier) {
      'gold' => 'patched-switch-list-gold',
      'silver' => 'patched-switch-list-silver',
      _ => 'patched-switch-list-other',
    },
    'patched-switch-list-tail',
  ];
}

Map<String, String> switchMapLabels(int code) {
  return {
    'mode': 'patched-switch-map',
    'state': switch (code) {
      7 => 'patched-switch-map-seven',
      9 => 'patched-switch-map-nine',
      _ => 'patched-switch-map-other',
    },
  };
}

String unchangedGuardedSwitchLabel(String tier, bool enabled) {
  return switch (tier) {
    'gold' when enabled => 'patched-guarded-switch-gold',
    'vip' when enabled => 'patched-guarded-switch-vip',
    _ => 'patched-guarded-switch-other',
  };
}

Future<String> asyncGuardedSwitchLabel(String tier, bool enabled) async {
  return switch (tier) {
    'gold' when enabled => 'patched-async-guarded-switch-gold',
    'vip' when enabled => 'patched-async-guarded-switch-vip',
    _ => 'patched-async-guarded-switch-other',
  };
}

Future<String> asyncAwaitThenGuardedSwitchLabel(
  Future<String> ready,
  bool enabled,
) async {
  final tier = await ready;
  return switch (tier) {
    'gold' when enabled => 'patched-await-guarded-switch-gold',
    'vip' when enabled => 'patched-await-guarded-switch-vip',
    _ => 'patched-await-guarded-switch-other',
  };
}

Future<String> asyncAwaitConditionSwitchTryCatchRecoveryLabel(
  Future<String> ready,
  Future<String> recovery,
) async {
  try {
    return switch (await ready) {
      'gold' => 'patched-await-condition-switch-try-catch-gold',
      'blocked' => throw 'patched-await-condition-switch-try-catch-blocked',
      _ => 'patched-await-condition-switch-try-catch-other',
    };
  } catch (error) {
    final label = await recovery;
    return 'patched-await-condition-switch-try-catch-caught-$error-$label';
  }
}

Future<String> asyncAwaitConditionSwitchTryFinallyCleanupLabel(
  Future<String> ready,
  Future<String> cleanup,
) async {
  try {
    return switch (await ready) {
      'gold' => 'patched-await-condition-switch-try-finally-gold',
      'silver' => 'patched-await-condition-switch-try-finally-silver',
      _ => 'patched-await-condition-switch-try-finally-other',
    };
  } finally {
    await cleanup;
  }
}

Future<String> asyncAwaitThenSwitchTryCatchRecoveryLabel(
  Future<String> ready,
  Future<String> recovery,
) async {
  final tier = await ready;
  try {
    return switch (tier) {
      'gold' => 'patched-await-then-switch-try-catch-gold',
      'blocked' => throw 'patched-await-then-switch-try-catch-blocked',
      _ => 'patched-await-then-switch-try-catch-other',
    };
  } catch (error) {
    final label = await recovery;
    return 'patched-await-then-switch-try-catch-caught-$error-$label';
  }
}

Future<String> asyncAwaitThenSwitchTryFinallyCleanupLabel(
  Future<String> ready,
  Future<String> cleanup,
) async {
  final tier = await ready;
  try {
    return switch (tier) {
      'gold' => 'patched-await-then-switch-try-finally-gold',
      'silver' => 'patched-await-then-switch-try-finally-silver',
      _ => 'patched-await-then-switch-try-finally-other',
    };
  } finally {
    await cleanup;
  }
}

Future<String> asyncDoubleAwaitSwitchTryCatchFinallyRecoveryLabel(
  Future<String> ready,
  Future<String> recovery,
  Future<String> cleanup,
) async {
  final tier = await ready;
  try {
    return switch (tier) {
      'gold' => 'patched-double-await-switch-try-catch-finally-gold',
      'blocked' =>
        throw 'patched-double-await-switch-try-catch-finally-blocked',
      _ => 'patched-double-await-switch-try-catch-finally-other',
    };
  } catch (error) {
    final label = await recovery;
    return 'patched-double-await-switch-try-catch-finally-caught-$error-$label';
  } finally {
    await cleanup;
  }
}

Future<String> asyncDoubleAwaitSwitchTryFinallyCleanupLabel(
  Future<String> ready,
  Future<String> cleanup,
) async {
  final tier = await ready;
  try {
    return switch (tier) {
      'gold' => 'patched-double-await-switch-try-finally-gold',
      'silver' => 'patched-double-await-switch-try-finally-silver',
      _ => 'patched-double-await-switch-try-finally-other',
    };
  } finally {
    await cleanup;
  }
}

Future<String> asyncSwitchAwaitGuardLabel(
  String tier,
  Future<bool> enabled,
) async {
  return switch (tier) {
    'gold' when await enabled => 'patched-switch-await-guard-gold',
    'vip' when await enabled => 'patched-switch-await-guard-vip',
    _ => 'patched-switch-await-guard-other',
  };
}

Future<String> asyncAwaitThenSwitchAwaitGuardLabel(
  Future<String> ready,
  Future<bool> enabled,
) async {
  final tier = await ready;
  return switch (tier) {
    'gold' when await enabled => 'patched-await-switch-await-guard-gold',
    'vip' when await enabled => 'patched-await-switch-await-guard-vip',
    _ => 'patched-await-switch-await-guard-other',
  };
}
