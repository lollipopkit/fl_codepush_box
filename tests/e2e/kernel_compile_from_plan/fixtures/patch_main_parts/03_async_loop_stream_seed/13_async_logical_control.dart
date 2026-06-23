Future<String> asyncDoWhileLogicalAwaitCondition(
  bool enabled,
  Future<bool> keepGoing,
) async {
  var i = 0;
  var out = 'patched-do-logical-await-condition';
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
  var out = 'patched-for-logical-await-condition';
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
  var out = 'patched-if-try-finally-logical-await';
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
  var out = 'patched-if-try-catch-logical-await';
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
    'patched-logical-collection-list-head',
    if (enabled && await ready)
      ...extra
    else
      'patched-logical-collection-list-off',
    'patched-logical-collection-list-tail',
  ];
}

Future<Map<String, String>> asyncLogicalCollectionSpreadLabels(
  bool enabled,
  Future<bool> ready,
  Map<String, String> extra,
) async {
  return {
    'head': 'patched-logical-collection-map-head',
    if (enabled && await ready)
      ...extra
    else
      'state': 'patched-logical-collection-map-off',
    'tail': 'patched-logical-collection-map-tail',
  };
}

Future<List<String>> asyncLogicalCollectionForNames(
  bool enabled,
  Future<bool> ready,
  List<String> extra,
) async {
  return [
    'patched-logical-collection-for-list-head',
    if (enabled && await ready)
      for (final value in extra) 'patched-logical-collection-for-list-$value'
    else
      'patched-logical-collection-for-list-off',
  ];
}

Future<Map<String, String>> asyncLogicalCollectionForLabels(
  bool enabled,
  Future<bool> ready,
  Map<String, String> extra,
) async {
  return {
    'head': 'patched-logical-collection-for-map-head',
    if (enabled && await ready)
      for (final entry in extra.entries)
        'patched-logical-collection-for-map-${entry.key}': entry.value
    else
      'state': 'patched-logical-collection-for-map-off',
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
      'patched-logical-collection-try-finally-list-head',
      if (enabled && await ready)
        ...extra
      else
        'patched-logical-collection-try-finally-list-off',
    ];
  } finally {
    final marker = await cleanup;
    extra.add('patched-logical-collection-try-finally-list-cleanup-$marker');
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
      'head': 'patched-logical-collection-try-finally-map-head',
      if (enabled && await ready)
        ...extra
      else
        'state': 'patched-logical-collection-try-finally-map-off',
    };
  } finally {
    final marker = await cleanup;
    extra['cleanup'] =
        'patched-logical-collection-try-finally-map-cleanup-$marker';
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
      'patched-logical-collection-try-catch-list-head',
      if (await ready || fallback)
        for (final value in extra)
          'patched-logical-collection-try-catch-list-$value'
      else
        'patched-logical-collection-try-catch-list-off',
    ];
  } catch (e) {
    final marker = await recovery;
    return ['patched-logical-collection-try-catch-list-caught-$marker-$e'];
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
      'head': 'patched-logical-collection-try-catch-map-head',
      if (await ready || fallback)
        for (final entry in extra.entries)
          'patched-logical-collection-try-catch-map-${entry.key}': entry.value
      else
        'state': 'patched-logical-collection-try-catch-map-off',
    };
  } catch (e) {
    final marker = await recovery;
    return {
      'caught': 'patched-logical-collection-try-catch-map-caught-$marker-$e',
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
      'patched-logical-collection-try-catch-finally-list-head',
      if (enabled && await ready)
        for (final value in extra)
          'patched-logical-collection-try-catch-finally-list-$value'
      else
        'patched-logical-collection-try-catch-finally-list-off',
    ];
  } catch (e) {
    final marker = await recovery;
    return [
      'patched-logical-collection-try-catch-finally-list-caught-$marker-$e',
    ];
  } finally {
    final marker = await cleanup;
    extra.add(
      'patched-logical-collection-try-catch-finally-list-cleanup-$marker',
    );
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
      'head': 'patched-logical-collection-try-catch-finally-map-head',
      if (enabled && await ready)
        ...extra
      else
        'state': 'patched-logical-collection-try-catch-finally-map-off',
    };
  } catch (e) {
    final marker = await recovery;
    return {
      'caught':
          'patched-logical-collection-try-catch-finally-map-caught-$marker-$e',
    };
  } finally {
    final marker = await cleanup;
    extra['cleanup'] =
        'patched-logical-collection-try-catch-finally-map-cleanup-$marker';
  }
}
