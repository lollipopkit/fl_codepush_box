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
    'patched-async-list-deep-spread-head',
    ...first,
    for (final value in extra)
      allow
          ? 'patched-async-list-deep-spread-extra-live-$value'
          : 'patched-async-list-deep-spread-extra-muted-$value',
    ...second,
    for (final value in staticTail)
      'patched-async-list-deep-spread-tail-$value',
    'patched-async-list-deep-spread-end',
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
      throw 'patched-async-list-deep-spread-error';
    }
    final first = await firstReady;
    final second = await secondReady;
    out = [
      'patched-async-list-deep-spread-catch-head',
      ...first,
      for (final value in extra)
        'patched-async-list-deep-spread-catch-extra-$value',
      ...second,
      'patched-async-list-deep-spread-catch-tail',
    ];
  } catch (e) {
    final marker = await recovery;
    out = ['patched-async-list-deep-spread-caught-$marker-$e'];
  } finally {
    final marker = await cleanup;
    out = [...out, 'patched-async-list-deep-spread-cleanup-$marker'];
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
    'mode': 'patched-async-map-deep-spread-head',
    ...first,
    for (final entry in extra.entries)
      'patched-async-map-deep-spread-extra-${entry.key}': allow
          ? 'patched-async-map-deep-spread-live-${entry.value}'
          : 'patched-async-map-deep-spread-muted-${entry.value}',
    ...second,
    for (final entry in staticTail.entries)
      'patched-async-map-deep-spread-tail-${entry.key}': entry.value,
    'end': 'patched-async-map-deep-spread-end',
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
      throw 'patched-async-map-deep-spread-error';
    }
    final first = await firstReady;
    final second = await secondReady;
    out = {
      'mode': 'patched-async-map-deep-spread-catch-head',
      ...first,
      for (final entry in extra.entries)
        'patched-async-map-deep-spread-catch-extra-${entry.key}': entry.value,
      ...second,
      'tail': 'patched-async-map-deep-spread-catch-tail',
    };
  } catch (e) {
    final marker = await recovery;
    out = {'error': 'patched-async-map-deep-spread-caught-$marker-$e'};
  } finally {
    final marker = await cleanup;
    out = {...out, 'cleanup': 'patched-async-map-deep-spread-cleanup-$marker'};
  }
  return out;
}
