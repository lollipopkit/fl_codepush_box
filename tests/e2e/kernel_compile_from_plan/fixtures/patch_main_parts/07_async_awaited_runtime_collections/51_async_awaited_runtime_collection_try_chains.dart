Future<List<String>> asyncListAwaitedRuntimeSourcesTryCatchSwitchSuperChain(
  Future<String> tier,
  Future<List<String>> primary,
  Future<List<String>> recovery,
  Future<List<String>> tail,
  Future<String> label,
) async {
  try {
    return [
      switch (await tier) {
        'gold' || 'vip' => 'patched-async-awaited-list-try-premium',
        _ => 'patched-async-awaited-list-try-standard',
      },
      for (final item in await primary) '${await label}-$item',
      ...await tail,
    ];
  } catch (e) {
    return [
      'patched-async-awaited-list-try-caught-$e',
      for (final item in await recovery) item,
    ];
  }
}

Future<Map<String, String>> asyncMapAwaitedEntriesTryCatchSwitchSuperChain(
  Future<bool> enabled,
  Future<Map<String, String>> primary,
  Future<Map<String, String>> recovery,
  Future<Map<String, String>> tail,
  Future<String> label,
) async {
  try {
    return {
      if (await enabled) 'patched-async-awaited-map-try-label': await label,
      for (final entry in (await primary).entries)
        '${await label}-${entry.key}': entry.value,
      ...await tail,
    };
  } catch (e) {
    return {
      'patched-async-awaited-map-try-caught': '$e',
      for (final entry in (await recovery).entries) entry.key: entry.value,
    };
  }
}
