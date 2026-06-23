Stream<Object> asyncGeneratedListRuntimeForAwaitSourceCleanupSuperChain(
  Stream<String> items,
  Future<List<String>> extras,
  Future<List<String>> tail,
  Future<String> label,
  Stream<String> cleanup,
) async* {
  try {
    await for (final item in items) {
      yield [
        'release-stream-awaited-list-source-head-$item',
        for (final extra in await extras) '${await label}-$extra',
        ...await tail,
      ];
    }
  } finally {
    await for (final value in cleanup) {
      yield [
        'release-stream-awaited-list-source-cleanup-$value',
        for (final extra in await extras) extra,
      ];
    }
  }
}

Stream<Object> asyncGeneratedMapEntriesAwaitSourceCleanupSuperChain(
  Stream<String> items,
  Future<Map<String, String>> extras,
  Future<Map<String, String>> tail,
  Future<String> label,
  Future<bool> enabled,
) async* {
  try {
    await for (final item in items) {
      yield {
        'release-stream-awaited-map-source-item': item,
        if (await enabled) 'release-stream-awaited-map-source-label': await label,
        for (final entry in (await extras).entries)
          '${await label}-${entry.key}': entry.value,
      };
    }
  } finally {
    yield {
      'release-stream-awaited-map-source-cleanup': await label,
      for (final entry in (await tail).entries) entry.key: entry.value,
    };
  }
}
