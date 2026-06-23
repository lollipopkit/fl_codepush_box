Iterable<List<String>> syncGeneratedCollectionSwitchList(
  String tier,
  List<String> extra,
) sync* {
  yield [
    'patched-iterable-collection-switch-head',
    ...switch (tier) {
      'gold' || 'vip' => ['patched-iterable-collection-switch-premium'],
      _ => ['patched-iterable-collection-switch-standard'],
    },
    for (final value in extra) 'patched-iterable-collection-switch-for-$value',
  ];
}

Stream<List<String>> asyncGeneratedCollectionSwitchList(
  String tier,
  List<String> extra,
) async* {
  yield [
    'patched-stream-collection-switch-head',
    ...switch (tier) {
      'gold' || 'vip' => ['patched-stream-collection-switch-premium'],
      _ => ['patched-stream-collection-switch-standard'],
    },
    for (final value in extra) 'patched-stream-collection-switch-for-$value',
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
        'patched-stream-await-collection-try-finally-head',
        for (final value in extra)
          'patched-stream-await-collection-try-finally-for-$value',
      ];
    } else {
      yield ['patched-stream-await-collection-try-finally-off'];
    }
  } finally {
    final marker = await cleanup;
    yield ['patched-stream-await-collection-try-finally-cleanup-$marker'];
  }
}

Stream<Map<String, String>> asyncGeneratedCollectionSwitchTryCatchMap(
  String tier,
  Future<bool> fail,
  Map<String, String> extra,
) async* {
  try {
    if (await fail) {
      throw 'patched-stream-collection-switch-map-error-$tier';
    }
    yield {
      'mode': 'patched-stream-collection-switch-map-head',
      ...switch (tier) {
        'gold' ||
        'vip' => {'state': 'patched-stream-collection-switch-map-premium'},
        _ => {'state': 'patched-stream-collection-switch-map-standard'},
      },
      for (final entry in extra.entries)
        'patched-stream-collection-switch-map-for-${entry.key}': entry.value,
    };
  } catch (e) {
    yield {'error': 'patched-stream-collection-switch-map-caught-$e'};
  }
}

Iterable<Map<String, String>> syncGeneratedGuardedCollectionSwitchMap(
  String tier,
  bool enabled,
  Map<String, String> extra,
) sync* {
  yield {
    'mode': 'patched-iterable-guarded-collection-switch-map-head',
    ...switch (tier) {
      'gold' when enabled => {
        'state': 'patched-iterable-guarded-collection-switch-map-premium',
      },
      _ => {'state': 'patched-iterable-guarded-collection-switch-map-standard'},
    },
    for (final entry in extra.entries)
      'patched-iterable-guarded-collection-switch-map-for-${entry.key}':
          entry.value,
  };
}

Iterable<List<String>> syncGeneratedNestedCollectionForSwitchList(
  List<String> tiers,
  List<String> extra,
) sync* {
  yield [
    'patched-iterable-nested-collection-switch-head',
    for (final tier in tiers)
      switch (tier) {
        'gold' || 'vip' => 'patched-iterable-nested-collection-switch-premium',
        _ => 'patched-iterable-nested-collection-switch-standard',
      },
    for (final value in extra)
      'patched-iterable-nested-collection-switch-for-$value',
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
    'mode': 'patched-stream-await-then-collection-switch-map-head',
    ...switch (tier) {
      'gold' when allow => {
        'state': 'patched-stream-await-then-collection-switch-map-premium',
      },
      _ => {
        'state': 'patched-stream-await-then-collection-switch-map-standard',
      },
    },
    for (final entry in extra.entries)
      'patched-stream-await-then-collection-switch-map-for-${entry.key}':
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
    'patched-stream-double-await-guarded-collection-head',
    ...switch (tier) {
      'gold' when allow => [
        'patched-stream-double-await-guarded-collection-premium',
      ],
      _ => ['patched-stream-double-await-guarded-collection-standard'],
    },
    for (final value in extra)
      'patched-stream-double-await-guarded-collection-for-$value',
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
      throw 'patched-stream-collection-switch-list-error-$tier';
    }
    yield [
      'patched-stream-collection-switch-list-head',
      ...switch (tier) {
        'gold' || 'vip' => ['patched-stream-collection-switch-list-premium'],
        _ => ['patched-stream-collection-switch-list-standard'],
      },
      for (final value in extra)
        'patched-stream-collection-switch-list-for-$value',
    ];
  } catch (e) {
    yield ['patched-stream-collection-switch-list-caught-$e'];
  } finally {
    final marker = await cleanup;
    yield ['patched-stream-collection-switch-list-cleanup-$marker'];
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
      throw 'patched-stream-collection-switch-map-finally-error-$tier';
    }
    yield {
      'mode': 'patched-stream-collection-switch-map-finally-head',
      ...switch (tier) {
        'gold' || 'vip' => {
          'state': 'patched-stream-collection-switch-map-finally-premium',
        },
        _ => {'state': 'patched-stream-collection-switch-map-finally-standard'},
      },
      for (final entry in extra.entries)
        'patched-stream-collection-switch-map-finally-for-${entry.key}':
            entry.value,
    };
  } catch (e) {
    final marker = await recovery;
    yield {
      'error': 'patched-stream-collection-switch-map-finally-caught-$marker-$e',
    };
  } finally {
    final marker = await cleanup;
    yield {
      'cleanup': 'patched-stream-collection-switch-map-finally-cleanup-$marker',
    };
  }
}

Iterable<List<String>> syncGeneratedNestedGuardedCollectionForList(
  List<String> tiers,
  bool enabled,
  List<String> extra,
) sync* {
  yield [
    'patched-iterable-nested-guarded-collection-list-head',
    for (final tier in tiers)
      switch (tier) {
        'gold' when enabled =>
          'patched-iterable-nested-guarded-collection-list-premium',
        'vip' when enabled =>
          'patched-iterable-nested-guarded-collection-list-premium',
        _ => 'patched-iterable-nested-guarded-collection-list-standard',
      },
    for (final value in extra)
      'patched-iterable-nested-guarded-collection-list-for-$value',
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
    'patched-stream-await-then-nested-collection-list-head',
    for (final tier in tiers)
      switch (tier) {
        'gold' when allow =>
          'patched-stream-await-then-nested-collection-list-premium',
        'vip' when allow =>
          'patched-stream-await-then-nested-collection-list-premium',
        _ => 'patched-stream-await-then-nested-collection-list-standard',
      },
    for (final value in extra)
      'patched-stream-await-then-nested-collection-list-for-$value',
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
      throw 'patched-stream-collection-dynamic-spread-list-error';
    }
    yield [
      'patched-stream-collection-dynamic-spread-list-head',
      ...base,
      for (final value in extra)
        'patched-stream-collection-dynamic-spread-list-for-$value',
    ];
  } catch (e) {
    final marker = await recovery;
    yield ['patched-stream-collection-dynamic-spread-list-caught-$marker-$e'];
  } finally {
    final marker = await cleanup;
    yield ['patched-stream-collection-dynamic-spread-list-cleanup-$marker'];
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
      throw 'patched-stream-collection-dynamic-spread-map-error';
    }
    yield {
      'mode': 'patched-stream-collection-dynamic-spread-map-head',
      ...base,
      for (final entry in extra.entries)
        'patched-stream-collection-dynamic-spread-map-for-${entry.key}':
            entry.value,
    };
  } catch (e) {
    final marker = await recovery;
    yield {
      'error': 'patched-stream-collection-dynamic-spread-map-caught-$marker-$e',
    };
  } finally {
    final marker = await cleanup;
    yield {
      'cleanup': 'patched-stream-collection-dynamic-spread-map-cleanup-$marker',
    };
  }
}

Iterable<List<String>> syncGeneratedDynamicSpreadSwitchList(
  String tier,
  List<String> base,
  List<String> extra,
) sync* {
  yield [
    'patched-iterable-dynamic-spread-switch-list-head',
    ...base,
    ...switch (tier) {
      'gold' ||
      'vip' => ['patched-iterable-dynamic-spread-switch-list-premium'],
      _ => ['patched-iterable-dynamic-spread-switch-list-standard'],
    },
    for (final value in extra)
      'patched-iterable-dynamic-spread-switch-list-for-$value',
  ];
}

Stream<List<String>> asyncGeneratedDynamicSpreadSwitchList(
  Future<String> tierReady,
  List<String> base,
  List<String> extra,
) async* {
  final tier = await tierReady;
  yield [
    'patched-stream-dynamic-spread-switch-list-head',
    ...base,
    ...switch (tier) {
      'gold' || 'vip' => ['patched-stream-dynamic-spread-switch-list-premium'],
      _ => ['patched-stream-dynamic-spread-switch-list-standard'],
    },
    for (final value in extra)
      'patched-stream-dynamic-spread-switch-list-for-$value',
  ];
}

Iterable<Map<String, String>> syncGeneratedDynamicSpreadSwitchMap(
  String tier,
  Map<String, String> base,
  Map<String, String> extra,
) sync* {
  yield {
    'mode': 'patched-iterable-dynamic-spread-switch-map-head',
    ...base,
    ...switch (tier) {
      'gold' ||
      'vip' => {'state': 'patched-iterable-dynamic-spread-switch-map-premium'},
      _ => {'state': 'patched-iterable-dynamic-spread-switch-map-standard'},
    },
    for (final entry in extra.entries)
      'patched-iterable-dynamic-spread-switch-map-for-${entry.key}':
          entry.value,
  };
}

Stream<Map<String, String>> asyncGeneratedDynamicSpreadSwitchMap(
  Future<String> tierReady,
  Map<String, String> base,
  Map<String, String> extra,
) async* {
  final tier = await tierReady;
  yield {
    'mode': 'patched-stream-dynamic-spread-switch-map-head',
    ...base,
    ...switch (tier) {
      'gold' ||
      'vip' => {'state': 'patched-stream-dynamic-spread-switch-map-premium'},
      _ => {'state': 'patched-stream-dynamic-spread-switch-map-standard'},
    },
    for (final entry in extra.entries)
      'patched-stream-dynamic-spread-switch-map-for-${entry.key}': entry.value,
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
      'patched-stream-dynamic-spread-switch-try-finally-list-head',
      ...base,
      ...switch (tier) {
        'gold' || 'vip' => [
          'patched-stream-dynamic-spread-switch-try-finally-list-premium',
        ],
        _ => ['patched-stream-dynamic-spread-switch-try-finally-list-standard'],
      },
      for (final value in extra)
        'patched-stream-dynamic-spread-switch-try-finally-list-for-$value',
    ];
  } finally {
    final marker = await cleanup;
    yield [
      'patched-stream-dynamic-spread-switch-try-finally-list-cleanup-$marker',
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
      throw 'patched-stream-dynamic-spread-switch-try-catch-finally-map-error-$tier';
    }
    yield {
      'mode': 'patched-stream-dynamic-spread-switch-try-catch-finally-map-head',
      ...base,
      ...switch (tier) {
        'gold' || 'vip' => {
          'state':
              'patched-stream-dynamic-spread-switch-try-catch-finally-map-premium',
        },
        _ => {
          'state':
              'patched-stream-dynamic-spread-switch-try-catch-finally-map-standard',
        },
      },
      for (final entry in extra.entries)
        'patched-stream-dynamic-spread-switch-try-catch-finally-map-for-${entry.key}':
            entry.value,
    };
  } catch (e) {
    final marker = await recovery;
    yield {
      'error':
          'patched-stream-dynamic-spread-switch-try-catch-finally-map-caught-$marker-$e',
    };
  } finally {
    final marker = await cleanup;
    yield {
      'cleanup':
          'patched-stream-dynamic-spread-switch-try-catch-finally-map-cleanup-$marker',
    };
  }
}

Iterable<List<String>> syncGeneratedDynamicSpreadNestedSwitchList(
  List<String> tiers,
  List<String> base,
  List<String> extra,
) sync* {
  yield [
    'patched-iterable-dynamic-spread-nested-switch-list-head',
    ...base,
    for (final tier in tiers)
      switch (tier) {
        'gold' ||
        'vip' => 'patched-iterable-dynamic-spread-nested-switch-list-premium',
        _ => 'patched-iterable-dynamic-spread-nested-switch-list-standard',
      },
    for (final value in extra)
      'patched-iterable-dynamic-spread-nested-switch-list-for-$value',
  ];
}

Iterable<List<String>> syncGeneratedDynamicSpreadNestedForList(
  List<String> tiers,
  List<String> base,
  List<String> extra,
) sync* {
  yield [
    'patched-iterable-dynamic-spread-nested-for-list-head',
    ...base,
    for (final tier in tiers)
      'patched-iterable-dynamic-spread-nested-for-list-tier-$tier',
    for (final value in extra)
      'patched-iterable-dynamic-spread-nested-for-list-extra-$value',
  ];
}

Iterable<Map<String, String>> syncGeneratedDynamicSpreadNestedSwitchMap(
  List<String> tiers,
  Map<String, String> base,
  Map<String, String> extra,
) sync* {
  yield {
    'mode': 'patched-iterable-dynamic-spread-nested-switch-map-head',
    ...base,
    for (final tier in tiers)
      'patched-iterable-dynamic-spread-nested-switch-map-tier-$tier':
          switch (tier) {
            'gold' || 'vip' =>
              'patched-iterable-dynamic-spread-nested-switch-map-premium',
            _ => 'patched-iterable-dynamic-spread-nested-switch-map-standard',
          },
    for (final entry in extra.entries)
      'patched-iterable-dynamic-spread-nested-switch-map-extra-${entry.key}':
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
    'patched-stream-await-dynamic-spread-nested-switch-list-head',
    ...base,
    for (final tier in tiers)
      switch (tier) {
        'gold' when allow =>
          'patched-stream-await-dynamic-spread-nested-switch-list-premium',
        'vip' when allow =>
          'patched-stream-await-dynamic-spread-nested-switch-list-premium',
        _ => 'patched-stream-await-dynamic-spread-nested-switch-list-standard',
      },
    for (final value in extra)
      'patched-stream-await-dynamic-spread-nested-switch-list-for-$value',
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
      'patched-stream-dynamic-spread-switch-double-cleanup-list-head',
      ...base,
      ...switch (tier) {
        'gold' || 'vip' => [
          'patched-stream-dynamic-spread-switch-double-cleanup-list-premium',
        ],
        _ => [
          'patched-stream-dynamic-spread-switch-double-cleanup-list-standard',
        ],
      },
      for (final value in extra)
        'patched-stream-dynamic-spread-switch-double-cleanup-list-for-$value',
    ];
  } finally {
    final marker = await cleanup;
    final tail = await cleanupTail;
    yield [
      'patched-stream-dynamic-spread-switch-double-cleanup-list-cleanup-$marker-$tail',
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
      throw 'patched-stream-dynamic-spread-switch-double-await-map-error-$tier';
    }
    yield {
      'mode': 'patched-stream-dynamic-spread-switch-double-await-map-head',
      ...base,
      ...switch (tier) {
        'gold' || 'vip' => {
          'state':
              'patched-stream-dynamic-spread-switch-double-await-map-premium',
        },
        _ => {
          'state':
              'patched-stream-dynamic-spread-switch-double-await-map-standard',
        },
      },
      for (final entry in extra.entries)
        'patched-stream-dynamic-spread-switch-double-await-map-for-${entry.key}':
            entry.value,
    };
  } catch (e) {
    final marker = await recovery;
    yield {
      'error':
          'patched-stream-dynamic-spread-switch-double-await-map-caught-$marker-$e',
    };
  } finally {
    final marker = await cleanup;
    final tail = await cleanupTail;
    yield {
      'cleanup':
          'patched-stream-dynamic-spread-switch-double-await-map-cleanup-$marker-$tail',
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
    'mode': 'patched-stream-await-then-dynamic-spread-runtime-map-head',
    ...base,
    for (final entry in extra.entries)
      'patched-stream-await-then-dynamic-spread-runtime-map-for-${entry.key}':
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
    'mode': 'patched-stream-await-dynamic-spread-nested-switch-map-head',
    ...base,
    for (final tier in tiers)
      'patched-stream-await-dynamic-spread-nested-switch-map-tier-$tier':
          switch (tier) {
            'gold' when allow =>
              'patched-stream-await-dynamic-spread-nested-switch-map-premium',
            'vip' when allow =>
              'patched-stream-await-dynamic-spread-nested-switch-map-premium',
            _ =>
              'patched-stream-await-dynamic-spread-nested-switch-map-standard',
          },
    for (final entry in extra.entries)
      'patched-stream-await-dynamic-spread-nested-switch-map-extra-${entry.key}':
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
          'patched-stream-dynamic-spread-nested-switch-map-double-cleanup-head',
      ...base,
      for (final tier in tiers)
        'patched-stream-dynamic-spread-nested-switch-map-double-cleanup-tier-$tier':
            switch (tier) {
              'gold' || 'vip' =>
                'patched-stream-dynamic-spread-nested-switch-map-double-cleanup-premium',
              _ =>
                'patched-stream-dynamic-spread-nested-switch-map-double-cleanup-standard',
            },
      for (final entry in extra.entries)
        'patched-stream-dynamic-spread-nested-switch-map-double-cleanup-extra-${entry.key}':
            entry.value,
    };
  } finally {
    final marker = await cleanup;
    final tail = await cleanupTail;
    yield {
      'cleanup':
          'patched-stream-dynamic-spread-nested-switch-map-double-cleanup-$marker-$tail',
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
      throw 'patched-stream-dynamic-spread-nested-switch-map-catch-error';
    }
    yield {
      'mode': 'patched-stream-dynamic-spread-nested-switch-map-catch-head',
      ...base,
      for (final tier in tiers)
        'patched-stream-dynamic-spread-nested-switch-map-catch-tier-$tier':
            switch (tier) {
              'gold' || 'vip' =>
                'patched-stream-dynamic-spread-nested-switch-map-catch-premium',
              _ =>
                'patched-stream-dynamic-spread-nested-switch-map-catch-standard',
            },
      for (final entry in extra.entries)
        'patched-stream-dynamic-spread-nested-switch-map-catch-extra-${entry.key}':
            entry.value,
    };
  } catch (e) {
    final marker = await recovery;
    yield {
      'error':
          'patched-stream-dynamic-spread-nested-switch-map-catch-caught-$marker-$e',
    };
  } finally {
    final marker = await cleanup;
    yield {
      'cleanup':
          'patched-stream-dynamic-spread-nested-switch-map-catch-cleanup-$marker',
    };
  }
}
