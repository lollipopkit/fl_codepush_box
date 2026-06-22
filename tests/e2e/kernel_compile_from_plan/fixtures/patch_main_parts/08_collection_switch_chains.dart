Future<List<String>> asyncCollectionSwitchSpreadNames(
  Future<bool> ready,
  String tier,
  List<String> extra,
  List<String> fallback,
) async {
  return [
    'patched-collection-switch-list-head',
    if (await ready)
      ...switch (tier) {
        'gold' || 'vip' => ['patched-collection-switch-list-premium'],
        'trial' || 'guest' => extra,
        _ => fallback,
      }
    else
      'patched-collection-switch-list-off',
    for (final value in extra) 'patched-collection-switch-list-for-$value',
  ];
}

Future<Map<String, String>> asyncCollectionSwitchSpreadLabels(
  Future<bool> ready,
  String tier,
  Map<String, String> extra,
  Map<String, String> fallback,
) async {
  return {
    'mode': 'patched-collection-switch-map-head',
    if (await ready)
      ...switch (tier) {
        'gold' || 'vip' => {'state': 'patched-collection-switch-map-premium'},
        'trial' || 'guest' => extra,
        _ => fallback,
      }
    else
      'state': 'patched-collection-switch-map-off',
    for (final entry in extra.entries)
      'patched-collection-switch-map-for-${entry.key}': entry.value,
  };
}

Future<List<String>> asyncCollectionSwitchTryFinallyNames(
  Future<bool> ready,
  String tier,
  List<String> extra,
) async {
  try {
    return [
      'patched-collection-switch-try-finally-list-head',
      if (await ready)
        ...switch (tier) {
          'gold' ||
          'vip' => ['patched-collection-switch-try-finally-list-premium'],
          _ => extra,
        }
      else
        'patched-collection-switch-try-finally-list-off',
      for (final value in extra)
        'patched-collection-switch-try-finally-list-for-$value',
    ];
  } finally {
    extra.add('patched-collection-switch-try-finally-list-cleanup');
  }
}

Future<Map<String, String>> asyncCollectionSwitchTryCatchLabels(
  Future<bool> ready,
  String tier,
  Map<String, String> extra,
) async {
  try {
    return {
      'mode': 'patched-collection-switch-try-catch-map-head',
      if (await ready)
        ...switch (tier) {
          'gold' ||
          'vip' => {'state': 'patched-collection-switch-try-catch-map-premium'},
          _ => extra,
        }
      else
        'state': 'patched-collection-switch-try-catch-map-off',
      for (final entry in extra.entries)
        'patched-collection-switch-try-catch-map-for-${entry.key}': entry.value,
    };
  } catch (e) {
    return {'caught': 'patched-collection-switch-try-catch-map-caught-$e'};
  }
}

Future<List<String>> asyncAwaitThenCollectionSwitchSpreadNames(
  Future<bool> ready,
  String tier,
  List<String> extra,
  List<String> fallback,
) async {
  final enabled = await ready;
  return [
    'patched-await-then-collection-switch-list-head',
    if (enabled)
      ...switch (tier) {
        'gold' ||
        'vip' => ['patched-await-then-collection-switch-list-premium'],
        'trial' || 'guest' => extra,
        _ => fallback,
      }
    else
      'patched-await-then-collection-switch-list-off',
    for (final value in extra)
      'patched-await-then-collection-switch-list-for-$value',
  ];
}

Future<Map<String, String>> asyncAwaitThenCollectionSwitchSpreadLabels(
  Future<bool> ready,
  String tier,
  Map<String, String> extra,
  Map<String, String> fallback,
) async {
  final enabled = await ready;
  return {
    'mode': 'patched-await-then-collection-switch-map-head',
    if (enabled)
      ...switch (tier) {
        'gold' ||
        'vip' => {'state': 'patched-await-then-collection-switch-map-premium'},
        'trial' || 'guest' => extra,
        _ => fallback,
      }
    else
      'state': 'patched-await-then-collection-switch-map-off',
    for (final entry in extra.entries)
      'patched-await-then-collection-switch-map-for-${entry.key}': entry.value,
  };
}

Future<List<String>> asyncAwaitThenCollectionSwitchTryFinallyNames(
  Future<bool> ready,
  String tier,
  List<String> extra,
) async {
  final enabled = await ready;
  try {
    return [
      'patched-await-then-collection-switch-try-finally-list-head',
      if (enabled)
        ...switch (tier) {
          'gold' || 'vip' => [
            'patched-await-then-collection-switch-try-finally-list-premium',
          ],
          _ => extra,
        }
      else
        'patched-await-then-collection-switch-try-finally-list-off',
      for (final value in extra)
        'patched-await-then-collection-switch-try-finally-list-for-$value',
    ];
  } finally {
    extra.add('patched-await-then-collection-switch-try-finally-list-cleanup');
  }
}

Future<Map<String, String>> asyncAwaitThenCollectionSwitchTryCatchLabels(
  Future<bool> ready,
  String tier,
  Map<String, String> extra,
) async {
  final enabled = await ready;
  try {
    return {
      'mode': 'patched-await-then-collection-switch-try-catch-map-head',
      if (enabled)
        ...switch (tier) {
          'gold' || 'vip' => {
            'state':
                'patched-await-then-collection-switch-try-catch-map-premium',
          },
          _ => extra,
        }
      else
        'state': 'patched-await-then-collection-switch-try-catch-map-off',
      for (final entry in extra.entries)
        'patched-await-then-collection-switch-try-catch-map-for-${entry.key}':
            entry.value,
    };
  } catch (e) {
    return {
      'caught': 'patched-await-then-collection-switch-try-catch-map-caught-$e',
    };
  }
}

Future<List<String>> asyncDoubleAwaitCollectionSwitchSpreadNames(
  Future<bool> ready,
  Future<String> tierReady,
  List<String> extra,
  List<String> fallback,
) async {
  final enabled = await ready;
  final selectedTier = await tierReady;
  return [
    'patched-double-await-collection-switch-list-head',
    if (enabled)
      ...switch (selectedTier) {
        'gold' ||
        'vip' => ['patched-double-await-collection-switch-list-premium'],
        'trial' || 'guest' => extra,
        _ => fallback,
      }
    else
      'patched-double-await-collection-switch-list-off',
    for (final value in extra)
      'patched-double-await-collection-switch-list-for-$value',
  ];
}

Future<Map<String, String>> asyncDoubleAwaitCollectionSwitchSpreadLabels(
  Future<bool> ready,
  Future<String> tierReady,
  Map<String, String> extra,
  Map<String, String> fallback,
) async {
  final enabled = await ready;
  final selectedTier = await tierReady;
  return {
    'mode': 'patched-double-await-collection-switch-map-head',
    if (enabled)
      ...switch (selectedTier) {
        'gold' || 'vip' => {
          'state': 'patched-double-await-collection-switch-map-premium',
        },
        'trial' || 'guest' => extra,
        _ => fallback,
      }
    else
      'state': 'patched-double-await-collection-switch-map-off',
    for (final entry in extra.entries)
      'patched-double-await-collection-switch-map-for-${entry.key}':
          entry.value,
  };
}

Future<List<String>> asyncDoubleAwaitCollectionSwitchTryFinallyNames(
  Future<bool> ready,
  Future<String> tierReady,
  List<String> extra,
) async {
  final enabled = await ready;
  final selectedTier = await tierReady;
  try {
    return [
      'patched-double-await-collection-switch-try-finally-list-head',
      if (enabled)
        ...switch (selectedTier) {
          'gold' || 'vip' => [
            'patched-double-await-collection-switch-try-finally-list-premium',
          ],
          _ => extra,
        }
      else
        'patched-double-await-collection-switch-try-finally-list-off',
      for (final value in extra)
        'patched-double-await-collection-switch-try-finally-list-for-$value',
    ];
  } finally {
    extra.add(
      'patched-double-await-collection-switch-try-finally-list-cleanup',
    );
  }
}

Future<Map<String, String>> asyncDoubleAwaitCollectionSwitchTryCatchLabels(
  Future<bool> ready,
  Future<String> tierReady,
  Map<String, String> extra,
) async {
  final enabled = await ready;
  final selectedTier = await tierReady;
  try {
    return {
      'mode': 'patched-double-await-collection-switch-try-catch-map-head',
      if (enabled)
        ...switch (selectedTier) {
          'gold' || 'vip' => {
            'state':
                'patched-double-await-collection-switch-try-catch-map-premium',
          },
          _ => extra,
        }
      else
        'state': 'patched-double-await-collection-switch-try-catch-map-off',
      for (final entry in extra.entries)
        'patched-double-await-collection-switch-try-catch-map-for-${entry.key}':
            entry.value,
    };
  } catch (e) {
    return {
      'caught':
          'patched-double-await-collection-switch-try-catch-map-caught-$e',
    };
  }
}
