Future<List<String>> asyncNotAwaitCollectionIfListChain(
  Future<bool> ready,
  List<String> live,
  List<String> fallback,
) async {
  return [
    'patched-async-not-await-list-head',
    if (!await ready) ...fallback else ...live,
    for (final item in live) 'patched-async-not-await-list-live-$item',
  ];
}

Future<Map<String, String>> asyncNotAwaitCollectionIfMapChain(
  Future<bool> ready,
  Map<String, String> live,
  Map<String, String> fallback,
) async {
  return {
    'mode': 'patched-async-not-await-map-head',
    if (!await ready) ...fallback else ...live,
    for (final entry in live.entries)
      'patched-async-not-await-map-live-${entry.key}': entry.value,
  };
}

Future<List<String>> asyncNotAwaitCollectionIfTryFinallyListCleanup(
  Future<bool> ready,
  Future<String> cleanup,
  List<String> live,
  List<String> fallback,
) async {
  var out = <String>[];
  try {
    out = [
      'patched-async-not-await-list-finally-head',
      if (!await ready) ...fallback else ...live,
      for (final item in fallback)
        'patched-async-not-await-list-finally-fallback-$item',
    ];
  } finally {
    final marker = await cleanup;
    out = [...out, 'patched-async-not-await-list-finally-cleanup-$marker'];
  }
  return out;
}

Future<Map<String, String>> asyncNotAwaitCollectionIfTryCatchFinallyMapRecovery(
  Future<bool> ready,
  Future<bool> fail,
  Future<String> recovery,
  Future<String> cleanup,
  Map<String, String> live,
  Map<String, String> fallback,
) async {
  var out = <String, String>{};
  try {
    if (await fail) {
      throw 'patched-async-not-await-map-error';
    }
    out = {
      'mode': 'patched-async-not-await-map-try-head',
      if (!await ready) ...fallback else ...live,
      for (final entry in fallback.entries)
        'patched-async-not-await-map-fallback-${entry.key}': entry.value,
    };
  } catch (e) {
    final marker = await recovery;
    out = {'error': 'patched-async-not-await-map-caught-$marker-$e'};
  } finally {
    final marker = await cleanup;
    out = {...out, 'cleanup': 'patched-async-not-await-map-cleanup-$marker'};
  }
  return out;
}
