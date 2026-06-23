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

Future<List<String>> asyncAwaitThenCollectionTryCatchAwaitRecoveryNames(
  Future<bool> ready,
  Future<String> recovery,
  List<String> extra,
) async {
  final enabled = await ready;
  try {
    return [
      'patched-await-then-collection-try-catch-await-list-head',
      if (enabled)
        'patched-await-then-collection-try-catch-await-list-live'
      else
        'patched-await-then-collection-try-catch-await-list-off',
      ...extra,
    ];
  } catch (e) {
    final marker = await recovery;
    return [
      'patched-await-then-collection-try-catch-await-list-caught-$marker-$e',
    ];
  }
}

Future<List<String>> asyncAwaitThenCollectionTryFinallyAwaitCleanupNames(
  Future<bool> ready,
  Future<String> cleanup,
  List<String> extra,
) async {
  final enabled = await ready;
  try {
    return [
      'patched-await-then-collection-try-finally-await-list-head',
      if (enabled)
        'patched-await-then-collection-try-finally-await-list-live'
      else
        'patched-await-then-collection-try-finally-await-list-off',
      for (final item in extra) item,
    ];
  } finally {
    final marker = await cleanup;
    extra.add(
      'patched-await-then-collection-try-finally-await-list-cleanup-$marker',
    );
  }
}

Future<List<String>> asyncAwaitThenCollectionTryCatchFinallyAwaitRecoveryNames(
  Future<bool> ready,
  Future<String> recovery,
  Future<String> cleanup,
  List<String> extra,
) async {
  final enabled = await ready;
  try {
    try {
      return [
        'patched-await-then-collection-try-catch-finally-await-list-head',
        if (enabled)
          'patched-await-then-collection-try-catch-finally-await-list-live'
        else
          'patched-await-then-collection-try-catch-finally-await-list-off',
        ...extra,
      ];
    } catch (e) {
      final marker = await recovery;
      return [
        'patched-await-then-collection-try-catch-finally-await-list-caught-$marker-$e',
      ];
    }
  } finally {
    final marker = await cleanup;
    extra.add(
      'patched-await-then-collection-try-catch-finally-await-list-cleanup-$marker',
    );
  }
}

Future<Map<String, String>> asyncAwaitThenCollectionTryCatchAwaitRecoveryLabels(
  Future<bool> ready,
  Future<String> recovery,
  Map<String, String> extra,
) async {
  final enabled = await ready;
  try {
    return {
      'mode': 'patched-await-then-collection-try-catch-await-map',
      if (enabled)
        'state': 'patched-await-then-collection-try-catch-await-map-live'
      else
        'state': 'patched-await-then-collection-try-catch-await-map-off',
      ...extra,
    };
  } catch (e) {
    final marker = await recovery;
    return {
      'caught':
          'patched-await-then-collection-try-catch-await-map-caught-$marker-$e',
    };
  }
}

Future<Map<String, String>>
asyncAwaitThenCollectionTryFinallyAwaitCleanupLabels(
  Future<bool> ready,
  Future<String> cleanup,
  Map<String, String> extra,
) async {
  final enabled = await ready;
  try {
    return {
      'mode': 'patched-await-then-collection-try-finally-await-map',
      if (enabled)
        'state': 'patched-await-then-collection-try-finally-await-map-live'
      else
        'state': 'patched-await-then-collection-try-finally-await-map-off',
      for (final entry in extra.entries) entry.key: entry.value,
    };
  } finally {
    final marker = await cleanup;
    extra['cleanup'] =
        'patched-await-then-collection-try-finally-await-map-cleanup-$marker';
  }
}

Future<Map<String, String>>
asyncAwaitThenCollectionTryCatchFinallyAwaitRecoveryLabels(
  Future<bool> ready,
  Future<String> recovery,
  Future<String> cleanup,
  Map<String, String> extra,
) async {
  final enabled = await ready;
  try {
    try {
      return {
        'mode': 'patched-await-then-collection-try-catch-finally-await-map',
        if (enabled)
          'state':
              'patched-await-then-collection-try-catch-finally-await-map-live'
        else
          'state':
              'patched-await-then-collection-try-catch-finally-await-map-off',
        ...extra,
      };
    } catch (e) {
      final marker = await recovery;
      return {
        'caught':
            'patched-await-then-collection-try-catch-finally-await-map-caught-$marker-$e',
      };
    }
  } finally {
    final marker = await cleanup;
    extra['cleanup'] =
        'patched-await-then-collection-try-catch-finally-await-map-cleanup-$marker';
  }
}

Future<List<String>> asyncDoubleAwaitCollectionTryCatchAwaitRecoveryNames(
  Future<bool> ready,
  Future<String> tierReady,
  Future<String> recovery,
  List<String> extra,
) async {
  final enabled = await ready;
  final selectedTier = await tierReady;
  try {
    return [
      'patched-double-await-collection-try-catch-await-list-head-$selectedTier',
      if (enabled)
        'patched-double-await-collection-try-catch-await-list-live-$selectedTier'
      else
        'patched-double-await-collection-try-catch-await-list-off-$selectedTier',
      ...extra,
    ];
  } catch (e) {
    final marker = await recovery;
    return [
      'patched-double-await-collection-try-catch-await-list-caught-$marker-$selectedTier-$e',
    ];
  }
}

Future<List<String>> asyncDoubleAwaitCollectionTryFinallyAwaitCleanupNames(
  Future<bool> ready,
  Future<String> tierReady,
  Future<String> cleanup,
  List<String> extra,
) async {
  final enabled = await ready;
  final selectedTier = await tierReady;
  try {
    return [
      'patched-double-await-collection-try-finally-await-list-head-$selectedTier',
      if (enabled)
        'patched-double-await-collection-try-finally-await-list-live-$selectedTier'
      else
        'patched-double-await-collection-try-finally-await-list-off-$selectedTier',
      for (final item in extra) '$selectedTier-$item',
    ];
  } finally {
    final marker = await cleanup;
    extra.add(
      'patched-double-await-collection-try-finally-await-list-cleanup-$marker-$selectedTier',
    );
  }
}

Future<List<String>>
asyncDoubleAwaitCollectionTryCatchFinallyAwaitRecoveryNames(
  Future<bool> ready,
  Future<String> tierReady,
  Future<String> recovery,
  Future<String> cleanup,
  List<String> extra,
) async {
  final enabled = await ready;
  final selectedTier = await tierReady;
  try {
    try {
      return [
        'patched-double-await-collection-try-catch-finally-await-list-head-$selectedTier',
        if (enabled)
          'patched-double-await-collection-try-catch-finally-await-list-live-$selectedTier'
        else
          'patched-double-await-collection-try-catch-finally-await-list-off-$selectedTier',
        ...extra,
      ];
    } catch (e) {
      final marker = await recovery;
      return [
        'patched-double-await-collection-try-catch-finally-await-list-caught-$marker-$selectedTier-$e',
      ];
    }
  } finally {
    final marker = await cleanup;
    extra.add(
      'patched-double-await-collection-try-catch-finally-await-list-cleanup-$marker-$selectedTier',
    );
  }
}

Future<Map<String, String>>
asyncDoubleAwaitCollectionTryCatchAwaitRecoveryLabels(
  Future<bool> ready,
  Future<String> tierReady,
  Future<String> recovery,
  Map<String, String> extra,
) async {
  final enabled = await ready;
  final selectedTier = await tierReady;
  try {
    return {
      'mode':
          'patched-double-await-collection-try-catch-await-map-$selectedTier',
      if (enabled)
        'state':
            'patched-double-await-collection-try-catch-await-map-live-$selectedTier'
      else
        'state':
            'patched-double-await-collection-try-catch-await-map-off-$selectedTier',
      ...extra,
    };
  } catch (e) {
    final marker = await recovery;
    return {
      'caught':
          'patched-double-await-collection-try-catch-await-map-caught-$marker-$selectedTier-$e',
    };
  }
}

Future<Map<String, String>>
asyncDoubleAwaitCollectionTryFinallyAwaitCleanupLabels(
  Future<bool> ready,
  Future<String> tierReady,
  Future<String> cleanup,
  Map<String, String> extra,
) async {
  final enabled = await ready;
  final selectedTier = await tierReady;
  try {
    return {
      'mode':
          'patched-double-await-collection-try-finally-await-map-$selectedTier',
      if (enabled)
        'state':
            'patched-double-await-collection-try-finally-await-map-live-$selectedTier'
      else
        'state':
            'patched-double-await-collection-try-finally-await-map-off-$selectedTier',
      for (final entry in extra.entries)
        entry.key: '$selectedTier-${entry.value}',
    };
  } finally {
    final marker = await cleanup;
    extra['cleanup'] =
        'patched-double-await-collection-try-finally-await-map-cleanup-$marker-$selectedTier';
  }
}

Future<Map<String, String>>
asyncDoubleAwaitCollectionTryCatchFinallyAwaitRecoveryLabels(
  Future<bool> ready,
  Future<String> tierReady,
  Future<String> recovery,
  Future<String> cleanup,
  Map<String, String> extra,
) async {
  final enabled = await ready;
  final selectedTier = await tierReady;
  try {
    try {
      return {
        'mode':
            'patched-double-await-collection-try-catch-finally-await-map-$selectedTier',
        if (enabled)
          'state':
              'patched-double-await-collection-try-catch-finally-await-map-live-$selectedTier'
        else
          'state':
              'patched-double-await-collection-try-catch-finally-await-map-off-$selectedTier',
        ...extra,
      };
    } catch (e) {
      final marker = await recovery;
      return {
        'caught':
            'patched-double-await-collection-try-catch-finally-await-map-caught-$marker-$selectedTier-$e',
      };
    }
  } finally {
    final marker = await cleanup;
    extra['cleanup'] =
        'patched-double-await-collection-try-catch-finally-await-map-cleanup-$marker-$selectedTier';
  }
}
