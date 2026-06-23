Future<Map<String, String>> asyncMapForListSourceSwitchChain(
  Future<List<String>> tiersReady,
  Future<bool> enabled,
  Map<String, String> base,
  Map<String, String> extra,
) async {
  final tiers = await tiersReady;
  final allow = await enabled;
  return {
    'mode': 'patched-async-map-for-list-source-switch-head',
    ...base,
    for (final tier in tiers)
      'patched-async-map-for-list-source-switch-tier-$tier': switch (tier) {
        'gold' when allow => 'patched-async-map-for-list-source-switch-premium',
        'vip' when allow => 'patched-async-map-for-list-source-switch-premium',
        _ => 'patched-async-map-for-list-source-switch-standard',
      },
    for (final entry in extra.entries)
      'patched-async-map-for-list-source-switch-extra-${entry.key}':
          entry.value,
  };
}

Future<Map<String, String>> asyncMapForListSourceTryFinallyCleanup(
  Future<List<String>> tiersReady,
  Future<String> cleanup,
  Future<String> cleanupTail,
  Map<String, String> base,
  Map<String, String> extra,
) async {
  var out = <String, String>{};
  try {
    final tiers = await tiersReady;
    out = {
      'mode': 'patched-async-map-for-list-source-finally-head',
      ...base,
      for (final tier in tiers)
        'patched-async-map-for-list-source-finally-tier-$tier':
            'patched-async-map-for-list-source-finally-value-$tier',
      for (final entry in extra.entries)
        'patched-async-map-for-list-source-finally-extra-${entry.key}':
            entry.value,
    };
  } finally {
    final marker = await cleanup;
    final tail = await cleanupTail;
    out = {
      ...out,
      'cleanup':
          'patched-async-map-for-list-source-finally-cleanup-$marker-$tail',
    };
  }
  return out;
}

Future<Map<String, String>> asyncMapForListSourceTryCatchFinallyRecovery(
  Future<List<String>> tiersReady,
  Future<bool> fail,
  Future<String> recovery,
  Future<String> cleanup,
  Map<String, String> base,
  Map<String, String> extra,
) async {
  var out = <String, String>{};
  try {
    final tiers = await tiersReady;
    if (await fail) {
      throw 'patched-async-map-for-list-source-catch-error';
    }
    out = {
      'mode': 'patched-async-map-for-list-source-catch-head',
      ...base,
      for (final tier in tiers)
        'patched-async-map-for-list-source-catch-tier-$tier': switch (tier) {
          'gold' || 'vip' => 'patched-async-map-for-list-source-catch-premium',
          _ => 'patched-async-map-for-list-source-catch-standard',
        },
      for (final entry in extra.entries)
        'patched-async-map-for-list-source-catch-extra-${entry.key}':
            entry.value,
    };
  } catch (e) {
    final marker = await recovery;
    out = {
      'error': 'patched-async-map-for-list-source-catch-caught-$marker-$e',
    };
  } finally {
    final marker = await cleanup;
    out = {
      ...out,
      'cleanup': 'patched-async-map-for-list-source-catch-cleanup-$marker',
    };
  }
  return out;
}

Future<Map<String, String>> asyncMapForListSourceWhileTryFinallyLoop(
  Future<bool> keepGoing,
  Future<List<String>> tiersReady,
  Future<String> cleanup,
  Map<String, String> base,
) async {
  var out = <String, String>{};
  var index = 0;
  while (index < 2) {
    if (!await keepGoing) {
      break;
    }
    try {
      final tiers = await tiersReady;
      out = {
        ...out,
        ...base,
        for (final tier in tiers)
          'patched-async-map-for-list-source-while-tier-$tier': switch (tier) {
            'gold' ||
            'vip' => 'patched-async-map-for-list-source-while-premium',
            _ => 'patched-async-map-for-list-source-while-standard',
          },
      };
    } finally {
      final marker = await cleanup;
      out = {
        ...out,
        'cleanup':
            'patched-async-map-for-list-source-while-cleanup-$marker-$index',
      };
    }
    index = index + 1;
  }
  return out;
}

Future<Map<String, String>> asyncMapForListSourceForSwitchFinallyChain(
  Future<List<String>> tiersReady,
  Future<String> cleanup,
  Map<String, String> base,
  Map<String, String> extra,
) async {
  var out = <String, String>{};
  for (var index = 0; index < 2; index = index + 1) {
    try {
      final tiers = await tiersReady;
      out = {
        ...out,
        ...base,
        for (final tier in tiers)
          'patched-async-map-for-list-source-for-tier-$index-$tier':
              'patched-async-map-for-list-source-for-value-$tier',
        for (final entry in extra.entries)
          'patched-async-map-for-list-source-for-extra-$index-${entry.key}':
              entry.value,
      };
    } finally {
      final marker = await cleanup;
      out = {
        ...out,
        'cleanup':
            'patched-async-map-for-list-source-for-cleanup-$marker-$index',
      };
    }
  }
  return out;
}

Future<Map<String, String>> asyncMapForListSourceDoWhileCatchFinallyChain(
  Future<List<String>> tiersReady,
  Future<bool> fail,
  Future<bool> again,
  Future<String> recovery,
  Future<String> cleanup,
  Map<String, String> extra,
) async {
  var out = <String, String>{};
  var index = 0;
  do {
    try {
      if (await fail) {
        throw 'patched-async-map-for-list-source-do-error';
      }
      final tiers = await tiersReady;
      out = {
        ...out,
        for (final tier in tiers)
          'patched-async-map-for-list-source-do-tier-$index-$tier':
              switch (tier) {
                'gold' => 'patched-async-map-for-list-source-do-premium',
                _ => 'patched-async-map-for-list-source-do-standard',
              },
        for (final entry in extra.entries)
          'patched-async-map-for-list-source-do-extra-$index-${entry.key}':
              entry.value,
      };
    } catch (e) {
      final marker = await recovery;
      out = {
        ...out,
        'error': 'patched-async-map-for-list-source-do-caught-$marker-$e',
      };
    } finally {
      final marker = await cleanup;
      out = {
        ...out,
        'cleanup':
            'patched-async-map-for-list-source-do-cleanup-$marker-$index',
      };
    }
    index = index + 1;
  } while (await again);
  return out;
}

Future<Map<String, String>> asyncMapForListSourceNestedBranchRecovery(
  Future<bool> enabled,
  Future<List<String>> primaryReady,
  Future<List<String>> fallbackReady,
  Future<String> recovery,
  Map<String, String> extra,
) async {
  try {
    final selected = await enabled ? await primaryReady : await fallbackReady;
    return {
      'mode': 'patched-async-map-for-list-source-branch-head',
      for (final tier in selected)
        'patched-async-map-for-list-source-branch-tier-$tier': switch (tier) {
          'gold' || 'vip' => 'patched-async-map-for-list-source-branch-premium',
          _ => 'patched-async-map-for-list-source-branch-standard',
        },
      for (final entry in extra.entries)
        'patched-async-map-for-list-source-branch-extra-${entry.key}':
            entry.value,
    };
  } catch (e) {
    final marker = await recovery;
    return {
      'error': 'patched-async-map-for-list-source-branch-caught-$marker-$e',
    };
  }
}
