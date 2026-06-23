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

Future<List<String>> asyncCollectionGuardedSwitchSpreadNames(
  Future<bool> ready,
  String tier,
  bool premium,
  List<String> extra,
  List<String> fallback,
) async {
  return await ready && premium
      ? ['base-collection-guarded-switch-list-$tier']
      : fallback;
}

Future<Map<String, String>> asyncCollectionGuardedSwitchSpreadLabels(
  Future<bool> ready,
  String tier,
  bool premium,
  Map<String, String> extra,
  Map<String, String> fallback,
) async {
  return await ready && premium
      ? {'mode': 'base-collection-guarded-switch-map-$tier'}
      : fallback;
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

Future<List<String>> asyncCollectionSwitchTryCatchFinallyAwaitNames(
  Future<bool> ready,
  String tier,
  Future<String> recovery,
  Future<String> cleanup,
  List<String> extra,
) async {
  return await ready
      ? ['base-collection-switch-try-catch-finally-await-list-$tier']
      : extra;
}

Future<Map<String, String>> asyncCollectionSwitchTryCatchFinallyAwaitLabels(
  Future<bool> ready,
  String tier,
  Future<String> recovery,
  Future<String> cleanup,
  Map<String, String> extra,
) async {
  return await ready
      ? {'mode': 'base-collection-switch-try-catch-finally-await-map-$tier'}
      : extra;
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

Future<List<String>> asyncAwaitThenCollectionGuardedSwitchSpreadNames(
  Future<bool> ready,
  String tier,
  bool premium,
  List<String> extra,
  List<String> fallback,
) async {
  final enabled = await ready;
  return enabled && premium
      ? ['base-await-then-collection-guarded-switch-list-$tier']
      : fallback;
}

Future<Map<String, String>> asyncAwaitThenCollectionGuardedSwitchSpreadLabels(
  Future<bool> ready,
  String tier,
  bool premium,
  Map<String, String> extra,
  Map<String, String> fallback,
) async {
  final enabled = await ready;
  return enabled && premium
      ? {'mode': 'base-await-then-collection-guarded-switch-map-$tier'}
      : fallback;
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

Future<List<String>> asyncDoubleAwaitCollectionGuardedSwitchSpreadNames(
  Future<bool> ready,
  Future<String> tierReady,
  bool premium,
  List<String> extra,
  List<String> fallback,
) async {
  final enabled = await ready;
  final selectedTier = await tierReady;
  return enabled && premium
      ? ['base-double-await-collection-guarded-switch-list-$selectedTier']
      : fallback;
}

Future<Map<String, String>> asyncDoubleAwaitCollectionGuardedSwitchSpreadLabels(
  Future<bool> ready,
  Future<String> tierReady,
  bool premium,
  Map<String, String> extra,
  Map<String, String> fallback,
) async {
  final enabled = await ready;
  final selectedTier = await tierReady;
  return enabled && premium
      ? {
          'mode':
              'base-double-await-collection-guarded-switch-map-$selectedTier',
        }
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

Future<List<String>> asyncDoubleAwaitCollectionSwitchTryCatchFinallyAwaitNames(
  Future<bool> ready,
  Future<String> tierReady,
  Future<String> recovery,
  Future<String> cleanup,
  List<String> extra,
) async {
  final enabled = await ready;
  final selectedTier = await tierReady;
  return enabled
      ? [
          'base-double-await-collection-switch-try-catch-finally-await-list-$selectedTier',
        ]
      : extra;
}

Future<Map<String, String>>
asyncDoubleAwaitCollectionSwitchTryCatchFinallyAwaitLabels(
  Future<bool> ready,
  Future<String> tierReady,
  Future<String> recovery,
  Future<String> cleanup,
  Map<String, String> extra,
) async {
  final enabled = await ready;
  final selectedTier = await tierReady;
  return enabled
      ? {
          'mode':
              'base-double-await-collection-switch-try-catch-finally-await-map-$selectedTier',
        }
      : extra;
}
