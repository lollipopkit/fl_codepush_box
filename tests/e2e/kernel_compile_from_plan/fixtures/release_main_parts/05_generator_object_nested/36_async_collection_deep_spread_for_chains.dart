Future<List<String>> asyncListDynamicSpreadRuntimeForDeepChain(
  Future<bool> enabled,
  Future<List<String>> firstReady,
  Future<List<String>> secondReady,
  List<String> staticTail,
  List<String> extra,
) async {
  final allow = await enabled;
  final first = await firstReady;
  final second = await secondReady;
  return [
    'release-async-list-deep-spread-head',
    ...first,
    for (final value in extra)
      allow
          ? 'release-async-list-deep-spread-extra-live-$value'
          : 'release-async-list-deep-spread-extra-muted-$value',
    ...second,
    for (final value in staticTail)
      'release-async-list-deep-spread-tail-$value',
    'release-async-list-deep-spread-end',
  ];
}

Future<List<String>> asyncListDeepSpreadTryCatchFinallyChain(
  Future<bool> fail,
  Future<List<String>> firstReady,
  Future<List<String>> secondReady,
  Future<String> recovery,
  Future<String> cleanup,
  List<String> extra,
) async {
  var out = <String>[];
  try {
    if (await fail) {
      throw 'release-async-list-deep-spread-error';
    }
    final first = await firstReady;
    final second = await secondReady;
    out = [
      'release-async-list-deep-spread-catch-head',
      ...first,
      for (final value in extra)
        'release-async-list-deep-spread-catch-extra-$value',
      ...second,
      'release-async-list-deep-spread-catch-tail',
    ];
  } catch (e) {
    final marker = await recovery;
    out = ['release-async-list-deep-spread-caught-$marker-$e'];
  } finally {
    final marker = await cleanup;
    out = [...out, 'release-async-list-deep-spread-cleanup-$marker'];
  }
  return out;
}

Future<Map<String, String>> asyncMapDynamicSpreadRuntimeForDeepChain(
  Future<bool> enabled,
  Future<Map<String, String>> firstReady,
  Future<Map<String, String>> secondReady,
  Map<String, String> staticTail,
  Map<String, String> extra,
) async {
  final allow = await enabled;
  final first = await firstReady;
  final second = await secondReady;
  return {
    'mode': 'release-async-map-deep-spread-head',
    ...first,
    for (final entry in extra.entries)
      'release-async-map-deep-spread-extra-${entry.key}': allow
          ? 'release-async-map-deep-spread-live-${entry.value}'
          : 'release-async-map-deep-spread-muted-${entry.value}',
    ...second,
    for (final entry in staticTail.entries)
      'release-async-map-deep-spread-tail-${entry.key}': entry.value,
    'end': 'release-async-map-deep-spread-end',
  };
}

Future<Map<String, String>> asyncMapDeepSpreadTryCatchFinallyChain(
  Future<bool> fail,
  Future<Map<String, String>> firstReady,
  Future<Map<String, String>> secondReady,
  Future<String> recovery,
  Future<String> cleanup,
  Map<String, String> extra,
) async {
  var out = <String, String>{};
  try {
    if (await fail) {
      throw 'release-async-map-deep-spread-error';
    }
    final first = await firstReady;
    final second = await secondReady;
    out = {
      'mode': 'release-async-map-deep-spread-catch-head',
      ...first,
      for (final entry in extra.entries)
        'release-async-map-deep-spread-catch-extra-${entry.key}': entry.value,
      ...second,
      'tail': 'release-async-map-deep-spread-catch-tail',
    };
  } catch (e) {
    final marker = await recovery;
    out = {'error': 'release-async-map-deep-spread-caught-$marker-$e'};
  } finally {
    final marker = await cleanup;
    out = {...out, 'cleanup': 'release-async-map-deep-spread-cleanup-$marker'};
  }
  return out;
}
