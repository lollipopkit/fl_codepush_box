Future<List<String>> asyncCollectionTryCatchAwaitRecoveryNames(
  Future<bool> ready,
  Future<String> recovery,
  List<String> extra,
) async {
  try {
    return [
      'patched-collection-try-catch-await-list-head',
      if (await ready)
        'patched-collection-try-catch-await-list-live'
      else
        'patched-collection-try-catch-await-list-off',
      ...extra,
    ];
  } catch (e) {
    final marker = await recovery;
    return ['patched-collection-try-catch-await-list-caught-$marker-$e'];
  }
}

Future<List<String>> asyncCollectionTryFinallyAwaitCleanupNames(
  Future<bool> ready,
  Future<String> cleanup,
  List<String> extra,
) async {
  try {
    return [
      'patched-collection-try-finally-await-list-head',
      if (await ready)
        'patched-collection-try-finally-await-list-live'
      else
        'patched-collection-try-finally-await-list-off',
      for (final item in extra) item,
    ];
  } finally {
    final marker = await cleanup;
    extra.add('patched-collection-try-finally-await-list-cleanup-$marker');
  }
}

Future<List<String>> asyncCollectionTryCatchFinallyAwaitRecoveryNames(
  Future<bool> ready,
  Future<String> recovery,
  Future<String> cleanup,
  List<String> extra,
) async {
  try {
    try {
      return [
        'patched-collection-try-catch-finally-await-list-head',
        if (await ready)
          'patched-collection-try-catch-finally-await-list-live'
        else
          'patched-collection-try-catch-finally-await-list-off',
        ...extra,
      ];
    } catch (e) {
      final marker = await recovery;
      return [
        'patched-collection-try-catch-finally-await-list-caught-$marker-$e',
      ];
    }
  } finally {
    final marker = await cleanup;
    extra.add(
      'patched-collection-try-catch-finally-await-list-cleanup-$marker',
    );
  }
}

Future<Map<String, String>> asyncCollectionTryCatchAwaitRecoveryLabels(
  Future<bool> ready,
  Future<String> recovery,
  Map<String, String> extra,
) async {
  try {
    return {
      'mode': 'patched-collection-try-catch-await-map',
      if (await ready)
        'state': 'patched-collection-try-catch-await-map-live'
      else
        'state': 'patched-collection-try-catch-await-map-off',
      ...extra,
    };
  } catch (e) {
    final marker = await recovery;
    return {
      'caught': 'patched-collection-try-catch-await-map-caught-$marker-$e',
    };
  }
}

Future<Map<String, String>> asyncCollectionTryFinallyAwaitCleanupLabels(
  Future<bool> ready,
  Future<String> cleanup,
  Map<String, String> extra,
) async {
  try {
    return {
      'mode': 'patched-collection-try-finally-await-map',
      if (await ready)
        'state': 'patched-collection-try-finally-await-map-live'
      else
        'state': 'patched-collection-try-finally-await-map-off',
      for (final entry in extra.entries) entry.key: entry.value,
    };
  } finally {
    final marker = await cleanup;
    extra['cleanup'] =
        'patched-collection-try-finally-await-map-cleanup-$marker';
  }
}

Future<Map<String, String>> asyncCollectionTryCatchFinallyAwaitRecoveryLabels(
  Future<bool> ready,
  Future<String> recovery,
  Future<String> cleanup,
  Map<String, String> extra,
) async {
  try {
    try {
      return {
        'mode': 'patched-collection-try-catch-finally-await-map',
        if (await ready)
          'state': 'patched-collection-try-catch-finally-await-map-live'
        else
          'state': 'patched-collection-try-catch-finally-await-map-off',
        ...extra,
      };
    } catch (e) {
      final marker = await recovery;
      return {
        'caught':
            'patched-collection-try-catch-finally-await-map-caught-$marker-$e',
      };
    }
  } finally {
    final marker = await cleanup;
    extra['cleanup'] =
        'patched-collection-try-catch-finally-await-map-cleanup-$marker';
  }
}
