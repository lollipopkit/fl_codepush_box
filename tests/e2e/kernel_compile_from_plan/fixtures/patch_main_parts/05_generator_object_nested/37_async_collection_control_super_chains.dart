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
    'patched-async-list-super-head',
    if (allow) ...first else ...fallback,
    for (final value in extra) 'patched-async-list-super-for-$value',
    ...staticTail,
    ...['patched-async-list-super-static-spread'],
    'patched-async-list-super-end',
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
  var out = <String>['patched-async-list-loop-super-head'];
  while (await keepGoing) {
    try {
      if (await fail) {
        throw 'patched-async-list-loop-super-error';
      }
      final values = await valuesReady;
      out = [
        ...out,
        for (final value in values)
          switch (tier) {
            'gold' || 'vip' => 'patched-async-list-loop-super-premium-$value',
            _ => 'patched-async-list-loop-super-standard-$value',
          },
        ...staticTail,
        ...['patched-async-list-loop-super-static-spread'],
      ];
    } catch (e) {
      final marker = await recovery;
      out = [...out, 'patched-async-list-loop-super-caught-$marker-$e'];
    } finally {
      final marker = await cleanup;
      out = [...out, 'patched-async-list-loop-super-cleanup-$marker'];
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
    'mode': 'patched-async-map-super-head',
    if (allow) ...first else ...fallback,
    for (final entry in extra.entries)
      'patched-async-map-super-for-${entry.key}': entry.value,
    ...staticTail,
    ...{'static-spread': 'patched-async-map-super-static-spread'},
    'end': 'patched-async-map-super-end',
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
  var out = <String, String>{'mode': 'patched-async-map-loop-super-head'};
  while (await keepGoing) {
    try {
      if (await fail) {
        throw 'patched-async-map-loop-super-error';
      }
      final values = await valuesReady;
      out = {
        ...out,
        for (final entry in values.entries)
          'patched-async-map-loop-super-${entry.key}': switch (tier) {
            'gold' ||
            'vip' => 'patched-async-map-loop-super-premium-${entry.value}',
            _ => 'patched-async-map-loop-super-standard-${entry.value}',
          },
        ...staticTail,
        ...{'static-spread': 'patched-async-map-loop-super-static-spread'},
      };
    } catch (e) {
      final marker = await recovery;
      out = {...out, 'error': 'patched-async-map-loop-super-caught-$marker-$e'};
    } finally {
      final marker = await cleanup;
      out = {...out, 'cleanup': 'patched-async-map-loop-super-cleanup-$marker'};
    }
  }
  return out;
}
