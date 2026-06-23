Future<List<String>> asyncListAwaitConditionSpreadForStaticSuperChain(
  Future<bool> enabled,
  Future<List<String>> firstReady,
  Future<List<String>> fallbackReady,
  List<String> extra,
  List<String> staticTail,
) async {
  final allow = await enabled;
  final first = await firstReady;
  final fallback = await fallbackReady;
  return [
    'release-async-list-super-head',
    if (allow) ...first else ...fallback,
    for (final value in extra) 'release-async-list-super-for-$value',
    ...staticTail,
    ...['release-async-list-super-static-spread'],
    'release-async-list-super-end',
  ];
}

Future<List<String>> asyncListLoopCollectionRecoveryCleanupSuperChain(
  Future<bool> keepGoing,
  Future<bool> fail,
  Future<List<String>> valuesReady,
  Future<String> recovery,
  Future<String> cleanup,
  String tier,
  List<String> staticTail,
) async {
  var out = <String>['release-async-list-loop-super-head'];
  while (await keepGoing) {
    try {
      if (await fail) {
        throw 'release-async-list-loop-super-error';
      }
      final values = await valuesReady;
      out = [
        ...out,
        for (final value in values)
          switch (tier) {
            'gold' || 'vip' => 'release-async-list-loop-super-premium-$value',
            _ => 'release-async-list-loop-super-standard-$value',
          },
        ...staticTail,
        ...['release-async-list-loop-super-static-spread'],
      ];
    } catch (e) {
      final marker = await recovery;
      out = [...out, 'release-async-list-loop-super-caught-$marker-$e'];
    } finally {
      final marker = await cleanup;
      out = [...out, 'release-async-list-loop-super-cleanup-$marker'];
    }
  }
  return out;
}

Future<Map<String, String>> asyncMapAwaitConditionSpreadForStaticSuperChain(
  Future<bool> enabled,
  Future<Map<String, String>> firstReady,
  Future<Map<String, String>> fallbackReady,
  Map<String, String> extra,
  Map<String, String> staticTail,
) async {
  final allow = await enabled;
  final first = await firstReady;
  final fallback = await fallbackReady;
  return {
    'mode': 'release-async-map-super-head',
    if (allow) ...first else ...fallback,
    for (final entry in extra.entries)
      'release-async-map-super-for-${entry.key}': entry.value,
    ...staticTail,
    ...{'static-spread': 'release-async-map-super-static-spread'},
    'end': 'release-async-map-super-end',
  };
}

Future<Map<String, String>> asyncMapLoopCollectionRecoveryCleanupSuperChain(
  Future<bool> keepGoing,
  Future<bool> fail,
  Future<Map<String, String>> valuesReady,
  Future<String> recovery,
  Future<String> cleanup,
  String tier,
  Map<String, String> staticTail,
) async {
  var out = <String, String>{'mode': 'release-async-map-loop-super-head'};
  while (await keepGoing) {
    try {
      if (await fail) {
        throw 'release-async-map-loop-super-error';
      }
      final values = await valuesReady;
      out = {
        ...out,
        for (final entry in values.entries)
          'release-async-map-loop-super-${entry.key}': switch (tier) {
            'gold' ||
            'vip' => 'release-async-map-loop-super-premium-${entry.value}',
            _ => 'release-async-map-loop-super-standard-${entry.value}',
          },
        ...staticTail,
        ...{'static-spread': 'release-async-map-loop-super-static-spread'},
      };
    } catch (e) {
      final marker = await recovery;
      out = {...out, 'error': 'release-async-map-loop-super-caught-$marker-$e'};
    } finally {
      final marker = await cleanup;
      out = {...out, 'cleanup': 'release-async-map-loop-super-cleanup-$marker'};
    }
  }
  return out;
}
