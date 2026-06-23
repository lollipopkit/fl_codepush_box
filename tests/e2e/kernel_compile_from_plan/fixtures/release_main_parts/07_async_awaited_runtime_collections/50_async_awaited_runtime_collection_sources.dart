Future<List<String>> asyncListAwaitedRuntimeSourcesSuperChain(
  Future<List<String>> items,
  Future<List<String>> tail,
  Future<String> label,
) async {
  return [
    'release-async-awaited-list-source-head',
    for (final item in await items) '${await label}-$item',
    ...await tail,
  ];
}

Future<Map<String, String>> asyncMapEntriesAwaitedRuntimeSourcesSuperChain(
  Future<Map<String, String>> items,
  Future<Map<String, String>> tail,
  Future<String> label,
  Future<bool> enabled,
) async {
  return {
    'release-async-awaited-map-source-head': await label,
    if (await enabled)
      for (final entry in (await items).entries)
        '${await label}-${entry.key}': entry.value,
    ...await tail,
  };
}
