Future<List<String>> asyncListForSourceDoubleAwaitSwitchChain(
  Future<List<String>> tiersReady,
  Future<bool> enabled,
  List<String> base,
  List<String> extra,
) async {
  final tiers = await tiersReady;
  final allow = await enabled;
  return [
    'patched-async-list-for-source-switch-head',
    ...base,
    for (final tier in tiers)
      switch (tier) {
        'gold' when allow => 'patched-async-list-for-source-switch-premium',
        'vip' when allow => 'patched-async-list-for-source-switch-premium',
        _ => 'patched-async-list-for-source-switch-standard',
      },
    for (final item in extra)
      'patched-async-list-for-source-switch-extra-$item',
  ];
}

Future<List<String>> asyncListForSourceWhileTryFinallyLoop(
  Future<bool> keepGoing,
  Future<List<String>> tiersReady,
  Future<String> cleanup,
  List<String> base,
) async {
  var out = <String>[];
  var index = 0;
  while (index < 2) {
    if (!await keepGoing) {
      break;
    }
    try {
      final tiers = await tiersReady;
      out = [
        ...out,
        ...base,
        for (final tier in tiers)
          'patched-async-list-for-source-while-tier-$index-$tier',
      ];
    } finally {
      final marker = await cleanup;
      out = [
        ...out,
        'patched-async-list-for-source-while-cleanup-$marker-$index',
      ];
    }
    index = index + 1;
  }
  return out;
}

Future<List<String>> asyncListForSourceForTryCatchFinallyRecovery(
  Future<List<String>> tiersReady,
  Future<bool> fail,
  Future<String> recovery,
  Future<String> cleanup,
  List<String> extra,
) async {
  var out = <String>[];
  for (var index = 0; index < 2; index = index + 1) {
    try {
      if (await fail) {
        throw 'patched-async-list-for-source-for-error';
      }
      final tiers = await tiersReady;
      out = [
        ...out,
        for (final tier in tiers)
          switch (tier) {
            'gold' || 'vip' => 'patched-async-list-for-source-for-premium',
            _ => 'patched-async-list-for-source-for-standard',
          },
        for (final item in extra)
          'patched-async-list-for-source-for-extra-$index-$item',
      ];
    } catch (e) {
      final marker = await recovery;
      out = [...out, 'patched-async-list-for-source-for-caught-$marker-$e'];
    } finally {
      final marker = await cleanup;
      out = [
        ...out,
        'patched-async-list-for-source-for-cleanup-$marker-$index',
      ];
    }
  }
  return out;
}

Future<List<String>> asyncListForSourceDoWhileCatchFinallyChain(
  Future<List<String>> tiersReady,
  Future<bool> fail,
  Future<bool> again,
  Future<String> recovery,
  Future<String> cleanup,
  List<String> extra,
) async {
  var out = <String>[];
  var index = 0;
  do {
    try {
      if (await fail) {
        throw 'patched-async-list-for-source-do-error';
      }
      final tiers = await tiersReady;
      out = [
        ...out,
        for (final tier in tiers)
          'patched-async-list-for-source-do-tier-$index-$tier',
        for (final item in extra)
          'patched-async-list-for-source-do-extra-$index-$item',
      ];
    } catch (e) {
      final marker = await recovery;
      out = [...out, 'patched-async-list-for-source-do-caught-$marker-$e'];
    } finally {
      final marker = await cleanup;
      out = [...out, 'patched-async-list-for-source-do-cleanup-$marker-$index'];
    }
    index = index + 1;
  } while (await again);
  return out;
}

Future<List<String>> asyncListForSourceNestedBranchRecovery(
  Future<bool> enabled,
  Future<List<String>> primaryReady,
  Future<List<String>> fallbackReady,
  Future<String> recovery,
  List<String> extra,
) async {
  try {
    final selected = await enabled ? await primaryReady : await fallbackReady;
    return [
      'patched-async-list-for-source-branch-head',
      for (final tier in selected)
        switch (tier) {
          'gold' || 'vip' => 'patched-async-list-for-source-branch-premium',
          _ => 'patched-async-list-for-source-branch-standard',
        },
      for (final item in extra)
        'patched-async-list-for-source-branch-extra-$item',
    ];
  } catch (e) {
    final marker = await recovery;
    return ['patched-async-list-for-source-branch-caught-$marker-$e'];
  }
}
