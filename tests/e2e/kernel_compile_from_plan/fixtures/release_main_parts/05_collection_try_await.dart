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
