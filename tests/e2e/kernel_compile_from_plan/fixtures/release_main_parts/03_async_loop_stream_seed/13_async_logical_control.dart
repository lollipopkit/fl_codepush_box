Future<String> asyncDoWhileLogicalAwaitCondition(
  bool enabled,
  Future<bool> keepGoing,
) async {
  var i = 0;
  var out = 'base-do-logical-await-condition';
  do {
    out = '$out-$i';
    if (i == 0) break;
    i = i + 1;
  } while (enabled && await keepGoing);
  return out;
}

Future<String> asyncForLogicalAwaitCondition(
  int limit,
  bool enabled,
  Future<bool> keepGoing,
) async {
  var out = 'base-for-logical-await-condition';
  for (var i = 0; i < limit && enabled && await keepGoing; i = i + 1) {
    out = '$out-$i';
    if (i == 0) break;
  }
  return out;
}

Future<String> asyncIfTryFinallyLogicalAwaitTail(
  bool enabled,
  Future<bool> ready,
  Future<String> cleanup,
) async {
  var out = 'base-if-try-finally-logical-await';
  if (enabled && await ready) {
    try {
      out = '$out-on';
    } finally {
      final marker = await cleanup;
      out = '$out-cleanup-$marker';
    }
  }
  out = '$out-tail';
  return out;
}

Future<String> asyncIfTryCatchLogicalAwaitTail(
  Future<bool> ready,
  bool fallback,
  Future<String> value,
  Future<String> recovery,
) async {
  var out = 'base-if-try-catch-logical-await';
  if (await ready || fallback) {
    try {
      final result = await value;
      out = '$out-on-$result';
    } catch (e) {
      final recovered = await recovery;
      out = '$out-caught-$e-$recovered';
    }
  }
  out = '$out-tail';
  return out;
}

Future<List<String>> asyncLogicalCollectionSpreadNames(
  bool enabled,
  Future<bool> ready,
  List<String> extra,
) async {
  return [
    'base-logical-collection-list-head',
    if (enabled && await ready)
      ...extra
    else
      'base-logical-collection-list-off',
    'base-logical-collection-list-tail',
  ];
}

Future<Map<String, String>> asyncLogicalCollectionSpreadLabels(
  bool enabled,
  Future<bool> ready,
  Map<String, String> extra,
) async {
  return {
    'head': 'base-logical-collection-map-head',
    if (enabled && await ready)
      ...extra
    else
      'state': 'base-logical-collection-map-off',
    'tail': 'base-logical-collection-map-tail',
  };
}

Future<List<String>> asyncLogicalCollectionForNames(
  bool enabled,
  Future<bool> ready,
  List<String> extra,
) async {
  return [
    'base-logical-collection-for-list-head',
    if (enabled && await ready)
      for (final value in extra) 'base-logical-collection-for-list-$value'
    else
      'base-logical-collection-for-list-off',
  ];
}

Future<Map<String, String>> asyncLogicalCollectionForLabels(
  bool enabled,
  Future<bool> ready,
  Map<String, String> extra,
) async {
  return {
    'head': 'base-logical-collection-for-map-head',
    if (enabled && await ready)
      for (final entry in extra.entries)
        'base-logical-collection-for-map-${entry.key}': entry.value
    else
      'state': 'base-logical-collection-for-map-off',
  };
}

Future<List<String>> asyncLogicalCollectionTryFinallyNames(
  bool enabled,
  Future<bool> ready,
  Future<String> cleanup,
  List<String> extra,
) async {
  try {
    return [
      'base-logical-collection-try-finally-list-head',
      if (enabled && await ready)
        ...extra
      else
        'base-logical-collection-try-finally-list-off',
    ];
  } finally {
    final marker = await cleanup;
    extra.add('base-logical-collection-try-finally-list-cleanup-$marker');
  }
}

Future<Map<String, String>> asyncLogicalCollectionTryFinallyLabels(
  bool enabled,
  Future<bool> ready,
  Future<String> cleanup,
  Map<String, String> extra,
) async {
  try {
    return {
      'head': 'base-logical-collection-try-finally-map-head',
      if (enabled && await ready)
        ...extra
      else
        'state': 'base-logical-collection-try-finally-map-off',
    };
  } finally {
    final marker = await cleanup;
    extra['cleanup'] =
        'base-logical-collection-try-finally-map-cleanup-$marker';
  }
}

Future<List<String>> asyncLogicalCollectionTryCatchNames(
  Future<bool> ready,
  bool fallback,
  Future<String> recovery,
  List<String> extra,
) async {
  try {
    return [
      'base-logical-collection-try-catch-list-head',
      if (await ready || fallback)
        for (final value in extra)
          'base-logical-collection-try-catch-list-$value'
      else
        'base-logical-collection-try-catch-list-off',
    ];
  } catch (e) {
    final marker = await recovery;
    return ['base-logical-collection-try-catch-list-caught-$marker-$e'];
  }
}

Future<Map<String, String>> asyncLogicalCollectionTryCatchLabels(
  Future<bool> ready,
  bool fallback,
  Future<String> recovery,
  Map<String, String> extra,
) async {
  try {
    return {
      'head': 'base-logical-collection-try-catch-map-head',
      if (await ready || fallback)
        for (final entry in extra.entries)
          'base-logical-collection-try-catch-map-${entry.key}': entry.value
      else
        'state': 'base-logical-collection-try-catch-map-off',
    };
  } catch (e) {
    final marker = await recovery;
    return {
      'caught': 'base-logical-collection-try-catch-map-caught-$marker-$e',
    };
  }
}

Future<List<String>> asyncLogicalCollectionTryCatchFinallyNames(
  bool enabled,
  Future<bool> ready,
  Future<String> recovery,
  Future<String> cleanup,
  List<String> extra,
) async {
  try {
    return [
      'base-logical-collection-try-catch-finally-list-head',
      if (enabled && await ready)
        for (final value in extra)
          'base-logical-collection-try-catch-finally-list-$value'
      else
        'base-logical-collection-try-catch-finally-list-off',
    ];
  } catch (e) {
    final marker = await recovery;
    return ['base-logical-collection-try-catch-finally-list-caught-$marker-$e'];
  } finally {
    final marker = await cleanup;
    extra.add('base-logical-collection-try-catch-finally-list-cleanup-$marker');
  }
}

Future<Map<String, String>> asyncLogicalCollectionTryCatchFinallyLabels(
  bool enabled,
  Future<bool> ready,
  Future<String> recovery,
  Future<String> cleanup,
  Map<String, String> extra,
) async {
  try {
    return {
      'head': 'base-logical-collection-try-catch-finally-map-head',
      if (enabled && await ready)
        ...extra
      else
        'state': 'base-logical-collection-try-catch-finally-map-off',
    };
  } catch (e) {
    final marker = await recovery;
    return {
      'caught':
          'base-logical-collection-try-catch-finally-map-caught-$marker-$e',
    };
  } finally {
    final marker = await cleanup;
    extra['cleanup'] =
        'base-logical-collection-try-catch-finally-map-cleanup-$marker';
  }
}
