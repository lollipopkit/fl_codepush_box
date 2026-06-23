Future<List<String>> asyncCollectionTryCatchAwaitRecoveryNames(
  Future<bool> ready,
  Future<String> recovery,
  List<String> extra,
) async {
  return await ready ? ['base-collection-try-catch-await-list'] : extra;
}

Future<List<String>> asyncCollectionTryFinallyAwaitCleanupNames(
  Future<bool> ready,
  Future<String> cleanup,
  List<String> extra,
) async {
  return await ready
      ? [
          'base-collection-try-finally-await-list',
          for (final item in extra) item,
        ]
      : extra;
}

Future<List<String>> asyncCollectionTryCatchFinallyAwaitRecoveryNames(
  Future<bool> ready,
  Future<String> recovery,
  Future<String> cleanup,
  List<String> extra,
) async {
  return await ready ? ['base-collection-try-catch-finally-await-list'] : extra;
}

Future<Map<String, String>> asyncCollectionTryCatchAwaitRecoveryLabels(
  Future<bool> ready,
  Future<String> recovery,
  Map<String, String> extra,
) async {
  return await ready
      ? {'state': 'base-collection-try-catch-await-map', ...extra}
      : extra;
}

Future<Map<String, String>> asyncCollectionTryFinallyAwaitCleanupLabels(
  Future<bool> ready,
  Future<String> cleanup,
  Map<String, String> extra,
) async {
  return await ready
      ? {
          'state': 'base-collection-try-finally-await-map',
          for (final entry in extra.entries) entry.key: entry.value,
        }
      : extra;
}

Future<Map<String, String>> asyncCollectionTryCatchFinallyAwaitRecoveryLabels(
  Future<bool> ready,
  Future<String> recovery,
  Future<String> cleanup,
  Map<String, String> extra,
) async {
  return await ready
      ? {'state': 'base-collection-try-catch-finally-await-map', ...extra}
      : extra;
}

Future<List<String>> asyncAwaitThenCollectionTryCatchAwaitRecoveryNames(
  Future<bool> ready,
  Future<String> recovery,
  List<String> extra,
) async {
  final enabled = await ready;
  return enabled ? ['base-await-then-collection-try-catch-await-list'] : extra;
}

Future<List<String>> asyncAwaitThenCollectionTryFinallyAwaitCleanupNames(
  Future<bool> ready,
  Future<String> cleanup,
  List<String> extra,
) async {
  final enabled = await ready;
  return enabled
      ? [
          'base-await-then-collection-try-finally-await-list',
          for (final item in extra) item,
        ]
      : extra;
}

Future<List<String>> asyncAwaitThenCollectionTryCatchFinallyAwaitRecoveryNames(
  Future<bool> ready,
  Future<String> recovery,
  Future<String> cleanup,
  List<String> extra,
) async {
  final enabled = await ready;
  return enabled
      ? ['base-await-then-collection-try-catch-finally-await-list']
      : extra;
}

Future<Map<String, String>> asyncAwaitThenCollectionTryCatchAwaitRecoveryLabels(
  Future<bool> ready,
  Future<String> recovery,
  Map<String, String> extra,
) async {
  final enabled = await ready;
  return enabled
      ? {'state': 'base-await-then-collection-try-catch-await-map', ...extra}
      : extra;
}

Future<Map<String, String>>
asyncAwaitThenCollectionTryFinallyAwaitCleanupLabels(
  Future<bool> ready,
  Future<String> cleanup,
  Map<String, String> extra,
) async {
  final enabled = await ready;
  return enabled
      ? {
          'state': 'base-await-then-collection-try-finally-await-map',
          for (final entry in extra.entries) entry.key: entry.value,
        }
      : extra;
}

Future<Map<String, String>>
asyncAwaitThenCollectionTryCatchFinallyAwaitRecoveryLabels(
  Future<bool> ready,
  Future<String> recovery,
  Future<String> cleanup,
  Map<String, String> extra,
) async {
  final enabled = await ready;
  return enabled
      ? {
          'state': 'base-await-then-collection-try-catch-finally-await-map',
          ...extra,
        }
      : extra;
}

Future<List<String>> asyncDoubleAwaitCollectionTryCatchAwaitRecoveryNames(
  Future<bool> ready,
  Future<String> tierReady,
  Future<String> recovery,
  List<String> extra,
) async {
  final enabled = await ready;
  final selectedTier = await tierReady;
  return enabled
      ? ['base-double-await-collection-try-catch-await-list-$selectedTier']
      : extra;
}

Future<List<String>> asyncDoubleAwaitCollectionTryFinallyAwaitCleanupNames(
  Future<bool> ready,
  Future<String> tierReady,
  Future<String> cleanup,
  List<String> extra,
) async {
  final enabled = await ready;
  final selectedTier = await tierReady;
  return enabled
      ? [
          'base-double-await-collection-try-finally-await-list-$selectedTier',
          for (final item in extra) item,
        ]
      : extra;
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
  return enabled
      ? [
          'base-double-await-collection-try-catch-finally-await-list-$selectedTier',
        ]
      : extra;
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
  return enabled
      ? {
          'state':
              'base-double-await-collection-try-catch-await-map-$selectedTier',
          ...extra,
        }
      : extra;
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
  return enabled
      ? {
          'state':
              'base-double-await-collection-try-finally-await-map-$selectedTier',
          for (final entry in extra.entries) entry.key: entry.value,
        }
      : extra;
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
  return enabled
      ? {
          'state':
              'base-double-await-collection-try-catch-finally-await-map-$selectedTier',
          ...extra,
        }
      : extra;
}
