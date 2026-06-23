Iterable<List<String>> syncGeneratedCollectionSwitchList(
  String tier,
  List<String> extra,
) sync* {
  yield [
    'base-iterable-collection-switch-head',
    if (tier == 'gold') 'base-iterable-collection-switch-premium',
    for (final value in extra) 'base-iterable-collection-switch-for-$value',
  ];
}

Stream<List<String>> asyncGeneratedCollectionSwitchList(
  String tier,
  List<String> extra,
) async* {
  yield [
    'base-stream-collection-switch-head',
    if (tier == 'gold') 'base-stream-collection-switch-premium',
    for (final value in extra) 'base-stream-collection-switch-for-$value',
  ];
}

Stream<List<String>> asyncGeneratedAwaitCollectionTryFinallyList(
  Future<bool> enabled,
  Future<String> cleanup,
  List<String> extra,
) async* {
  try {
    if (await enabled) {
      yield [
        'base-stream-await-collection-try-finally-head',
        for (final value in extra)
          'base-stream-await-collection-try-finally-for-$value',
      ];
    }
  } finally {
    final marker = await cleanup;
    yield ['base-stream-await-collection-try-finally-cleanup-$marker'];
  }
}

Stream<Map<String, String>> asyncGeneratedCollectionSwitchTryCatchMap(
  String tier,
  Future<bool> fail,
  Map<String, String> extra,
) async* {
  try {
    if (await fail) {
      throw 'base-stream-collection-switch-map-error-$tier';
    }
    yield {
      'mode': 'base-stream-collection-switch-map-head',
      if (tier == 'gold') 'state': 'base-stream-collection-switch-map-premium',
      for (final entry in extra.entries)
        'base-stream-collection-switch-map-for-${entry.key}': entry.value,
    };
  } catch (e) {
    yield {'error': 'base-stream-collection-switch-map-caught-$e'};
  }
}

Iterable<Map<String, String>> syncGeneratedGuardedCollectionSwitchMap(
  String tier,
  bool enabled,
  Map<String, String> extra,
) sync* {
  yield {
    'mode': 'base-iterable-guarded-collection-switch-map-head',
    if (tier == 'gold' && enabled)
      'state': 'base-iterable-guarded-collection-switch-map-premium',
    for (final entry in extra.entries)
      'base-iterable-guarded-collection-switch-map-for-${entry.key}':
          entry.value,
  };
}

Iterable<List<String>> syncGeneratedNestedCollectionForSwitchList(
  List<String> tiers,
  List<String> extra,
) sync* {
  yield [
    'base-iterable-nested-collection-switch-head',
    for (final tier in tiers)
      tier == 'gold'
          ? 'base-iterable-nested-collection-switch-premium'
          : 'base-iterable-nested-collection-switch-standard',
    for (final value in extra)
      'base-iterable-nested-collection-switch-for-$value',
  ];
}

Stream<Map<String, String>> asyncGeneratedAwaitThenCollectionSwitchMap(
  Future<String> tierReady,
  Future<bool> enabled,
  Map<String, String> extra,
) async* {
  final tier = await tierReady;
  final allow = await enabled;
  yield {
    'mode': 'base-stream-await-then-collection-switch-map-head',
    if (tier == 'gold' && allow)
      'state': 'base-stream-await-then-collection-switch-map-premium',
    for (final entry in extra.entries)
      'base-stream-await-then-collection-switch-map-for-${entry.key}':
          entry.value,
  };
}

Stream<List<String>> asyncGeneratedDoubleAwaitGuardedCollectionList(
  Future<String> tierReady,
  Future<bool> enabled,
  List<String> extra,
) async* {
  final tier = await tierReady;
  final allow = await enabled;
  yield [
    'base-stream-double-await-guarded-collection-head',
    if (tier == 'gold' && allow)
      'base-stream-double-await-guarded-collection-premium',
    for (final value in extra)
      'base-stream-double-await-guarded-collection-for-$value',
  ];
}

Stream<List<String>> asyncGeneratedCollectionSwitchTryCatchFinallyList(
  String tier,
  Future<bool> fail,
  Future<String> cleanup,
  List<String> extra,
) async* {
  try {
    if (await fail) {
      throw 'base-stream-collection-switch-list-error-$tier';
    }
    yield [
      'base-stream-collection-switch-list-head',
      if (tier == 'gold') 'base-stream-collection-switch-list-premium',
      for (final value in extra)
        'base-stream-collection-switch-list-for-$value',
    ];
  } catch (e) {
    yield ['base-stream-collection-switch-list-caught-$e'];
  } finally {
    final marker = await cleanup;
    yield ['base-stream-collection-switch-list-cleanup-$marker'];
  }
}

Stream<Map<String, String>>
asyncGeneratedCollectionSwitchMapTryCatchFinallyAwait(
  String tier,
  Future<bool> fail,
  Future<String> recovery,
  Future<String> cleanup,
  Map<String, String> extra,
) async* {
  try {
    if (await fail) {
      throw 'base-stream-collection-switch-map-finally-error-$tier';
    }
    yield {
      'mode': 'base-stream-collection-switch-map-finally-head',
      if (tier == 'gold')
        'state': 'base-stream-collection-switch-map-finally-premium',
      for (final entry in extra.entries)
        'base-stream-collection-switch-map-finally-for-${entry.key}':
            entry.value,
    };
  } catch (e) {
    final marker = await recovery;
    yield {
      'error': 'base-stream-collection-switch-map-finally-caught-$marker-$e',
    };
  } finally {
    final marker = await cleanup;
    yield {
      'cleanup': 'base-stream-collection-switch-map-finally-cleanup-$marker',
    };
  }
}

Iterable<List<String>> syncGeneratedNestedGuardedCollectionForList(
  List<String> tiers,
  bool enabled,
  List<String> extra,
) sync* {
  yield [
    'base-iterable-nested-guarded-collection-list-head',
    for (final tier in tiers)
      tier == 'gold' && enabled
          ? 'base-iterable-nested-guarded-collection-list-premium'
          : 'base-iterable-nested-guarded-collection-list-standard',
    for (final value in extra)
      'base-iterable-nested-guarded-collection-list-for-$value',
  ];
}

Stream<List<String>> asyncGeneratedAwaitThenNestedCollectionForSwitchList(
  Future<List<String>> tiersReady,
  Future<bool> enabled,
  List<String> extra,
) async* {
  final tiers = await tiersReady;
  final allow = await enabled;
  yield [
    'base-stream-await-then-nested-collection-list-head',
    for (final tier in tiers)
      tier == 'gold' && allow
          ? 'base-stream-await-then-nested-collection-list-premium'
          : 'base-stream-await-then-nested-collection-list-standard',
    for (final value in extra)
      'base-stream-await-then-nested-collection-list-for-$value',
  ];
}

Stream<List<String>> asyncGeneratedCollectionDynamicSpreadTryCatchFinallyList(
  Future<bool> fail,
  Future<String> recovery,
  Future<String> cleanup,
  List<String> base,
  List<String> extra,
) async* {
  try {
    if (await fail) {
      throw 'base-stream-collection-dynamic-spread-list-error';
    }
    yield [
      'base-stream-collection-dynamic-spread-list-head',
      ...base,
      for (final value in extra)
        'base-stream-collection-dynamic-spread-list-for-$value',
    ];
  } catch (e) {
    yield ['base-stream-collection-dynamic-spread-list-caught-$e'];
  } finally {
    final marker = await cleanup;
    yield ['base-stream-collection-dynamic-spread-list-cleanup-$marker'];
  }
}

Stream<Map<String, String>>
asyncGeneratedCollectionDynamicSpreadTryCatchFinallyMap(
  Future<bool> fail,
  Future<String> recovery,
  Future<String> cleanup,
  Map<String, String> base,
  Map<String, String> extra,
) async* {
  try {
    if (await fail) {
      throw 'base-stream-collection-dynamic-spread-map-error';
    }
    yield {
      'mode': 'base-stream-collection-dynamic-spread-map-head',
      ...base,
      for (final entry in extra.entries)
        'base-stream-collection-dynamic-spread-map-for-${entry.key}':
            entry.value,
    };
  } catch (e) {
    yield {'error': 'base-stream-collection-dynamic-spread-map-caught-$e'};
  } finally {
    final marker = await cleanup;
    yield {
      'cleanup': 'base-stream-collection-dynamic-spread-map-cleanup-$marker',
    };
  }
}

Iterable<List<String>> syncGeneratedDynamicSpreadSwitchList(
  String tier,
  List<String> base,
  List<String> extra,
) sync* {
  yield [
    'base-iterable-dynamic-spread-switch-list-head',
    ...base,
    if (tier == 'gold') 'base-iterable-dynamic-spread-switch-list-premium',
    for (final value in extra)
      'base-iterable-dynamic-spread-switch-list-for-$value',
  ];
}

Stream<List<String>> asyncGeneratedDynamicSpreadSwitchList(
  Future<String> tierReady,
  List<String> base,
  List<String> extra,
) async* {
  final tier = await tierReady;
  yield [
    'base-stream-dynamic-spread-switch-list-head',
    ...base,
    if (tier == 'gold') 'base-stream-dynamic-spread-switch-list-premium',
    for (final value in extra)
      'base-stream-dynamic-spread-switch-list-for-$value',
  ];
}

Iterable<Map<String, String>> syncGeneratedDynamicSpreadSwitchMap(
  String tier,
  Map<String, String> base,
  Map<String, String> extra,
) sync* {
  yield {
    'mode': 'base-iterable-dynamic-spread-switch-map-head',
    ...base,
    if (tier == 'gold')
      'state': 'base-iterable-dynamic-spread-switch-map-premium',
    for (final entry in extra.entries)
      'base-iterable-dynamic-spread-switch-map-for-${entry.key}': entry.value,
  };
}

Stream<Map<String, String>> asyncGeneratedDynamicSpreadSwitchMap(
  Future<String> tierReady,
  Map<String, String> base,
  Map<String, String> extra,
) async* {
  final tier = await tierReady;
  yield {
    'mode': 'base-stream-dynamic-spread-switch-map-head',
    ...base,
    if (tier == 'gold')
      'state': 'base-stream-dynamic-spread-switch-map-premium',
    for (final entry in extra.entries)
      'base-stream-dynamic-spread-switch-map-for-${entry.key}': entry.value,
  };
}

Stream<List<String>> asyncGeneratedDynamicSpreadSwitchTryFinallyList(
  Future<String> tierReady,
  Future<String> cleanup,
  List<String> base,
  List<String> extra,
) async* {
  try {
    final tier = await tierReady;
    yield [
      'base-stream-dynamic-spread-switch-try-finally-list-head',
      ...base,
      tier == 'gold'
          ? 'base-stream-dynamic-spread-switch-try-finally-list-premium'
          : 'base-stream-dynamic-spread-switch-try-finally-list-standard',
      for (final value in extra)
        'base-stream-dynamic-spread-switch-try-finally-list-for-$value',
    ];
  } finally {
    final marker = await cleanup;
    yield [
      'base-stream-dynamic-spread-switch-try-finally-list-cleanup-$marker',
    ];
  }
}

Stream<Map<String, String>> asyncGeneratedDynamicSpreadSwitchTryCatchFinallyMap(
  Future<String> tierReady,
  Future<bool> fail,
  Future<String> recovery,
  Future<String> cleanup,
  Map<String, String> base,
  Map<String, String> extra,
) async* {
  try {
    final tier = await tierReady;
    if (await fail) {
      throw 'base-stream-dynamic-spread-switch-try-catch-finally-map-error-$tier';
    }
    yield {
      'mode': 'base-stream-dynamic-spread-switch-try-catch-finally-map-head',
      ...base,
      'state': tier == 'gold'
          ? 'base-stream-dynamic-spread-switch-try-catch-finally-map-premium'
          : 'base-stream-dynamic-spread-switch-try-catch-finally-map-standard',
      for (final entry in extra.entries)
        'base-stream-dynamic-spread-switch-try-catch-finally-map-for-${entry.key}':
            entry.value,
    };
  } catch (e) {
    final marker = await recovery;
    yield {
      'error':
          'base-stream-dynamic-spread-switch-try-catch-finally-map-caught-$marker-$e',
    };
  } finally {
    final marker = await cleanup;
    yield {
      'cleanup':
          'base-stream-dynamic-spread-switch-try-catch-finally-map-cleanup-$marker',
    };
  }
}

Iterable<List<String>> syncGeneratedDynamicSpreadNestedSwitchList(
  List<String> tiers,
  List<String> base,
  List<String> extra,
) sync* {
  yield [
    'base-iterable-dynamic-spread-nested-switch-list-head',
    ...base,
    for (final tier in tiers)
      tier == 'gold'
          ? 'base-iterable-dynamic-spread-nested-switch-list-premium'
          : 'base-iterable-dynamic-spread-nested-switch-list-standard',
    for (final value in extra)
      'base-iterable-dynamic-spread-nested-switch-list-for-$value',
  ];
}

Iterable<List<String>> syncGeneratedDynamicSpreadNestedForList(
  List<String> tiers,
  List<String> base,
  List<String> extra,
) sync* {
  yield [
    'base-iterable-dynamic-spread-nested-for-list-head',
    ...base,
    for (final tier in tiers)
      'base-iterable-dynamic-spread-nested-for-list-tier-$tier',
    for (final value in extra)
      'base-iterable-dynamic-spread-nested-for-list-extra-$value',
  ];
}

Iterable<Map<String, String>> syncGeneratedDynamicSpreadNestedSwitchMap(
  List<String> tiers,
  Map<String, String> base,
  Map<String, String> extra,
) sync* {
  yield {
    'mode': 'base-iterable-dynamic-spread-nested-switch-map-head',
    ...base,
    for (final tier in tiers)
      'base-iterable-dynamic-spread-nested-switch-map-tier-$tier':
          tier == 'gold'
          ? 'base-iterable-dynamic-spread-nested-switch-map-premium'
          : 'base-iterable-dynamic-spread-nested-switch-map-standard',
    for (final entry in extra.entries)
      'base-iterable-dynamic-spread-nested-switch-map-extra-${entry.key}':
          entry.value,
  };
}

Stream<List<String>> asyncGeneratedAwaitDynamicSpreadNestedSwitchList(
  Future<List<String>> tiersReady,
  Future<bool> enabled,
  List<String> base,
  List<String> extra,
) async* {
  final tiers = await tiersReady;
  final allow = await enabled;
  yield [
    'base-stream-await-dynamic-spread-nested-switch-list-head',
    ...base,
    for (final tier in tiers)
      tier == 'gold' && allow
          ? 'base-stream-await-dynamic-spread-nested-switch-list-premium'
          : 'base-stream-await-dynamic-spread-nested-switch-list-standard',
    for (final value in extra)
      'base-stream-await-dynamic-spread-nested-switch-list-for-$value',
  ];
}

Stream<List<String>>
asyncGeneratedDynamicSpreadSwitchTryFinallyDoubleCleanupList(
  Future<String> tierReady,
  Future<String> cleanup,
  Future<String> cleanupTail,
  List<String> base,
  List<String> extra,
) async* {
  try {
    final tier = await tierReady;
    yield [
      'base-stream-dynamic-spread-switch-double-cleanup-list-head',
      ...base,
      tier == 'gold'
          ? 'base-stream-dynamic-spread-switch-double-cleanup-list-premium'
          : 'base-stream-dynamic-spread-switch-double-cleanup-list-standard',
      for (final value in extra)
        'base-stream-dynamic-spread-switch-double-cleanup-list-for-$value',
    ];
  } finally {
    final marker = await cleanup;
    final tail = await cleanupTail;
    yield [
      'base-stream-dynamic-spread-switch-double-cleanup-list-cleanup-$marker-$tail',
    ];
  }
}

Stream<Map<String, String>>
asyncGeneratedDynamicSpreadSwitchTryCatchFinallyDoubleAwaitMap(
  Future<String> tierReady,
  Future<bool> fail,
  Future<String> recovery,
  Future<String> cleanup,
  Future<String> cleanupTail,
  Map<String, String> base,
  Map<String, String> extra,
) async* {
  try {
    final tier = await tierReady;
    if (await fail) {
      throw 'base-stream-dynamic-spread-switch-double-await-map-error-$tier';
    }
    yield {
      'mode': 'base-stream-dynamic-spread-switch-double-await-map-head',
      ...base,
      'state': tier == 'gold'
          ? 'base-stream-dynamic-spread-switch-double-await-map-premium'
          : 'base-stream-dynamic-spread-switch-double-await-map-standard',
      for (final entry in extra.entries)
        'base-stream-dynamic-spread-switch-double-await-map-for-${entry.key}':
            entry.value,
    };
  } catch (e) {
    final marker = await recovery;
    yield {
      'error':
          'base-stream-dynamic-spread-switch-double-await-map-caught-$marker-$e',
    };
  } finally {
    final marker = await cleanup;
    final tail = await cleanupTail;
    yield {
      'cleanup':
          'base-stream-dynamic-spread-switch-double-await-map-cleanup-$marker-$tail',
    };
  }
}

Stream<Map<String, String>> asyncGeneratedAwaitThenDynamicSpreadRuntimeMap(
  Future<Map<String, String>> baseReady,
  Future<Map<String, String>> extraReady,
) async* {
  final base = await baseReady;
  final extra = await extraReady;
  yield {
    'mode': 'base-stream-await-then-dynamic-spread-runtime-map-head',
    ...base,
    for (final entry in extra.entries)
      'base-stream-await-then-dynamic-spread-runtime-map-for-${entry.key}':
          entry.value,
  };
}

Stream<Map<String, String>> asyncGeneratedAwaitDynamicSpreadNestedSwitchMap(
  Future<List<String>> tiersReady,
  Future<bool> enabled,
  Map<String, String> base,
  Map<String, String> extra,
) async* {
  final tiers = await tiersReady;
  final allow = await enabled;
  yield {
    'mode': 'base-stream-await-dynamic-spread-nested-switch-map-head',
    ...base,
    for (final tier in tiers)
      'base-stream-await-dynamic-spread-nested-switch-map-tier-$tier':
          tier == 'gold' && allow
          ? 'base-stream-await-dynamic-spread-nested-switch-map-premium'
          : 'base-stream-await-dynamic-spread-nested-switch-map-standard',
    for (final entry in extra.entries)
      'base-stream-await-dynamic-spread-nested-switch-map-extra-${entry.key}':
          entry.value,
  };
}

Stream<Map<String, String>>
asyncGeneratedDynamicSpreadNestedSwitchMapTryFinallyDoubleCleanup(
  Future<List<String>> tiersReady,
  Future<String> cleanup,
  Future<String> cleanupTail,
  Map<String, String> base,
  Map<String, String> extra,
) async* {
  try {
    final tiers = await tiersReady;
    yield {
      'mode':
          'base-stream-dynamic-spread-nested-switch-map-double-cleanup-head',
      ...base,
      for (final tier in tiers)
        'base-stream-dynamic-spread-nested-switch-map-double-cleanup-tier-$tier':
            tier == 'gold'
            ? 'base-stream-dynamic-spread-nested-switch-map-double-cleanup-premium'
            : 'base-stream-dynamic-spread-nested-switch-map-double-cleanup-standard',
      for (final entry in extra.entries)
        'base-stream-dynamic-spread-nested-switch-map-double-cleanup-extra-${entry.key}':
            entry.value,
    };
  } finally {
    final marker = await cleanup;
    final tail = await cleanupTail;
    yield {
      'cleanup':
          'base-stream-dynamic-spread-nested-switch-map-double-cleanup-$marker-$tail',
    };
  }
}

Stream<Map<String, String>>
asyncGeneratedDynamicSpreadNestedSwitchMapTryCatchFinallyDoubleAwait(
  Future<List<String>> tiersReady,
  Future<bool> fail,
  Future<String> recovery,
  Future<String> cleanup,
  Map<String, String> base,
  Map<String, String> extra,
) async* {
  try {
    final tiers = await tiersReady;
    if (await fail) {
      throw 'base-stream-dynamic-spread-nested-switch-map-catch-error';
    }
    yield {
      'mode': 'base-stream-dynamic-spread-nested-switch-map-catch-head',
      ...base,
      for (final tier in tiers)
        'base-stream-dynamic-spread-nested-switch-map-catch-tier-$tier':
            tier == 'gold'
            ? 'base-stream-dynamic-spread-nested-switch-map-catch-premium'
            : 'base-stream-dynamic-spread-nested-switch-map-catch-standard',
      for (final entry in extra.entries)
        'base-stream-dynamic-spread-nested-switch-map-catch-extra-${entry.key}':
            entry.value,
    };
  } catch (e) {
    final marker = await recovery;
    yield {
      'error':
          'base-stream-dynamic-spread-nested-switch-map-catch-caught-$marker-$e',
    };
  } finally {
    final marker = await cleanup;
    yield {
      'cleanup':
          'base-stream-dynamic-spread-nested-switch-map-catch-cleanup-$marker',
    };
  }
}
