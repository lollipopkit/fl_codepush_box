Stream<Object> asyncGeneratedListCollectionAwaitForFinalizerSuperChain(
  Stream<String> items,
  Future<bool> enabled,
  Future<String> label,
  Future<List<String>> extras,
  Stream<String> cleanup,
) async* {
  try {
    await for (final item in items) {
      yield [
        'patched-stream-collection-finalizer-head',
        if (await enabled) await label,
        ...await extras,
        item,
      ];
    }
  } finally {
    await for (final value in cleanup) {
      yield [
        'patched-stream-collection-finalizer-cleanup',
        value,
      ];
    }
  }
}

Stream<Object> asyncGeneratedMapCollectionCatchFinallySuperChain(
  Stream<String> items,
  Future<bool> enabled,
  Future<String> label,
  Future<List<String>> keys,
  Future<Map<String, String>> cleanup,
) async* {
  try {
    await for (final item in items) {
      yield {
        'patched-stream-map-finalizer-item': item,
        if (await enabled) 'patched-stream-map-finalizer-label': await label,
        for (final key in await keys) key: await label,
      };
    }
  } catch (e) {
    yield {
      'patched-stream-map-finalizer-caught': '$e',
    };
  } finally {
    yield {
      'patched-stream-map-finalizer-cleanup': await label,
      ...await cleanup,
    };
  }
}
