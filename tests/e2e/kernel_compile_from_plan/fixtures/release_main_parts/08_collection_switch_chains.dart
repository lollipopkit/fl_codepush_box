Future<List<String>> asyncCollectionSwitchSpreadNames(
  Future<bool> ready,
  String tier,
  List<String> extra,
  List<String> fallback,
) async {
  return await ready ? ['base-collection-switch-list'] : fallback;
}

Future<Map<String, String>> asyncCollectionSwitchSpreadLabels(
  Future<bool> ready,
  String tier,
  Map<String, String> extra,
  Map<String, String> fallback,
) async {
  return await ready ? {'mode': 'base-collection-switch-map'} : fallback;
}

Future<List<String>> asyncCollectionSwitchTryFinallyNames(
  Future<bool> ready,
  String tier,
  List<String> extra,
) async {
  return await ready ? ['base-collection-switch-try-finally-list'] : extra;
}

Future<Map<String, String>> asyncCollectionSwitchTryCatchLabels(
  Future<bool> ready,
  String tier,
  Map<String, String> extra,
) async {
  return await ready ? {'mode': 'base-collection-switch-try-catch-map'} : extra;
}

Future<List<String>> asyncAwaitThenCollectionSwitchSpreadNames(
  Future<bool> ready,
  String tier,
  List<String> extra,
  List<String> fallback,
) async {
  final enabled = await ready;
  return enabled ? ['base-await-then-collection-switch-list'] : fallback;
}

Future<Map<String, String>> asyncAwaitThenCollectionSwitchSpreadLabels(
  Future<bool> ready,
  String tier,
  Map<String, String> extra,
  Map<String, String> fallback,
) async {
  final enabled = await ready;
  return enabled ? {'mode': 'base-await-then-collection-switch-map'} : fallback;
}

Future<List<String>> asyncAwaitThenCollectionSwitchTryFinallyNames(
  Future<bool> ready,
  String tier,
  List<String> extra,
) async {
  final enabled = await ready;
  return enabled
      ? ['base-await-then-collection-switch-try-finally-list']
      : extra;
}

Future<Map<String, String>> asyncAwaitThenCollectionSwitchTryCatchLabels(
  Future<bool> ready,
  String tier,
  Map<String, String> extra,
) async {
  final enabled = await ready;
  return enabled
      ? {'mode': 'base-await-then-collection-switch-try-catch-map'}
      : extra;
}

Future<List<String>> asyncDoubleAwaitCollectionSwitchSpreadNames(
  Future<bool> ready,
  Future<String> tierReady,
  List<String> extra,
  List<String> fallback,
) async {
  final enabled = await ready;
  final selectedTier = await tierReady;
  return enabled
      ? ['base-double-await-collection-switch-list-$selectedTier']
      : fallback;
}

Future<Map<String, String>> asyncDoubleAwaitCollectionSwitchSpreadLabels(
  Future<bool> ready,
  Future<String> tierReady,
  Map<String, String> extra,
  Map<String, String> fallback,
) async {
  final enabled = await ready;
  final selectedTier = await tierReady;
  return enabled
      ? {'mode': 'base-double-await-collection-switch-map-$selectedTier'}
      : fallback;
}

Future<List<String>> asyncDoubleAwaitCollectionSwitchTryFinallyNames(
  Future<bool> ready,
  Future<String> tierReady,
  List<String> extra,
) async {
  final enabled = await ready;
  final selectedTier = await tierReady;
  return enabled
      ? ['base-double-await-collection-switch-try-finally-list-$selectedTier']
      : extra;
}

Future<Map<String, String>> asyncDoubleAwaitCollectionSwitchTryCatchLabels(
  Future<bool> ready,
  Future<String> tierReady,
  Map<String, String> extra,
) async {
  final enabled = await ready;
  final selectedTier = await tierReady;
  return enabled
      ? {
          'mode':
              'base-double-await-collection-switch-try-catch-map-$selectedTier',
        }
      : extra;
}
