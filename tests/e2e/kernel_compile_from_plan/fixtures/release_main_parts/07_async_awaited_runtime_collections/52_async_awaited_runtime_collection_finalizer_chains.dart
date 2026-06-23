Future<List<String>> asyncListAwaitedRuntimeSourcesFinallyCleanupSuperChain(
  Future<bool> enabled,
  Future<List<String>> primary,
  Future<List<String>> recovery,
  Future<List<String>> cleanup,
  Future<String> label,
) async {
  try {
    if (await enabled) {
      return [
        'release-async-awaited-list-finally-enabled',
        for (final item in await primary) '${await label}-$item',
      ];
    }
    return ['release-async-awaited-list-finally-disabled', ...await primary];
  } catch (e) {
    return [
      'release-async-awaited-list-finally-caught-$e',
      for (final item in await recovery) item,
    ];
  } finally {
    await [
      'release-async-awaited-list-finally-cleanup',
      for (final item in await cleanup) item,
    ];
  }
}

Future<Map<String, String>>
asyncMapAwaitedRuntimeSourcesFinallyCleanupSuperChain(
  Future<String> tier,
  Future<Map<String, String>> primary,
  Future<Map<String, String>> recovery,
  Future<Map<String, String>> cleanup,
  Future<String> label,
) async {
  try {
    return {
      switch (await tier) {
        'gold' => 'release-async-awaited-map-finally-premium',
        _ => 'release-async-awaited-map-finally-standard',
      }: await label,
      for (final entry in (await primary).entries)
        '${await label}-${entry.key}': entry.value,
    };
  } catch (e) {
    return {
      'release-async-awaited-map-finally-caught': '$e',
      for (final entry in (await recovery).entries) entry.key: entry.value,
    };
  } finally {
    await {
      'release-async-awaited-map-finally-cleanup': await label,
      for (final entry in (await cleanup).entries) entry.key: entry.value,
    };
  }
}
