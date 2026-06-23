Future<String> asyncNotAwaitGuardedSwitchExprLabel(
  String tier,
  Future<bool> enabled,
) async {
  return switch (tier) {
    'gold' when !await enabled => 'patched-not-await-guarded-switch-expr-gold',
    'vip' when !await enabled => 'patched-not-await-guarded-switch-expr-vip',
    _ => 'patched-not-await-guarded-switch-expr-other',
  };
}

Future<String> asyncNotAwaitGuardedSwitchExprAwaitScrutinee(
  Future<String> ready,
  Future<bool> enabled,
) async {
  return switch (await ready) {
    'gold' when !await enabled =>
      'patched-not-await-guarded-switch-await-expr-gold',
    'vip' when !await enabled =>
      'patched-not-await-guarded-switch-await-expr-vip',
    _ => 'patched-not-await-guarded-switch-await-expr-other',
  };
}

Future<String> asyncNotAwaitGuardedSwitchStatementLabel(
  String tier,
  Future<bool> enabled,
) async {
  switch (tier) {
    case 'gold' when !await enabled:
      return 'patched-not-await-guarded-switch-stmt-gold';
    case 'vip' when !await enabled:
      return 'patched-not-await-guarded-switch-stmt-vip';
    default:
      return 'patched-not-await-guarded-switch-stmt-other';
  }
}

Future<String> asyncNotAwaitGuardedSwitchStatementAwaitScrutinee(
  Future<String> ready,
  Future<bool> enabled,
) async {
  switch (await ready) {
    case 'gold' when !await enabled:
      return 'patched-not-await-guarded-switch-await-stmt-gold';
    case 'vip' when !await enabled:
      return 'patched-not-await-guarded-switch-await-stmt-vip';
    default:
      return 'patched-not-await-guarded-switch-await-stmt-other';
  }
}

Future<String> asyncNotAwaitGuardedSwitchTryFinallyCleanup(
  String tier,
  Future<bool> enabled,
  Future<String> cleanup,
) async {
  var out = 'patched-not-await-guarded-switch-finally-head';
  try {
    out = switch (tier) {
      'gold' when !await enabled =>
        'patched-not-await-guarded-switch-finally-gold',
      'vip' when !await enabled =>
        'patched-not-await-guarded-switch-finally-vip',
      _ => 'patched-not-await-guarded-switch-finally-other',
    };
  } finally {
    final marker = await cleanup;
    out = '$out-cleanup-$marker';
  }
  return out;
}

Future<String> asyncNotAwaitGuardedSwitchTryCatchFinallyRecovery(
  String tier,
  Future<bool> enabled,
  Future<String> recovery,
  Future<String> cleanup,
) async {
  var out = 'patched-not-await-guarded-switch-catch-finally-head';
  try {
    switch (tier) {
      case 'gold' when !await enabled:
        out = 'patched-not-await-guarded-switch-catch-finally-gold';
        break;
      case 'blocked':
        throw 'patched-not-await-guarded-switch-catch-finally-blocked';
      case 'vip' when !await enabled:
        out = 'patched-not-await-guarded-switch-catch-finally-vip';
        break;
      default:
        out = 'patched-not-await-guarded-switch-catch-finally-other';
    }
  } catch (error) {
    final marker = await recovery;
    out = 'patched-not-await-guarded-switch-caught-$error-$marker';
  } finally {
    final marker = await cleanup;
    out = '$out-cleanup-$marker';
  }
  return out;
}
