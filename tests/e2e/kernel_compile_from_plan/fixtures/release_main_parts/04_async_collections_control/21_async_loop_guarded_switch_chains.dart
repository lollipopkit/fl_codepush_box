Future<List<String>> asyncWhileNotAwaitGuardedSwitchCollectionFinalizer(
  Future<bool> keepGoing,
  String tier,
  Future<bool> enabled,
  Future<bool> skip,
  Future<bool> stop,
  Future<String> cleanup,
  List<String> extra,
) async {
  var out = <String>['release-loop-not-await-guarded-switch-list-head'];
  while (await keepGoing) {
    try {
      if (await skip) continue;
      if (await stop) break;
      out = [
        ...out,
        switch (tier) {
          'gold' when !await enabled =>
            'release-loop-not-await-guarded-switch-list-gold',
          'vip' when !await enabled =>
            'release-loop-not-await-guarded-switch-list-vip',
          _ => 'release-loop-not-await-guarded-switch-list-other',
        },
        for (final value in extra)
          'release-loop-not-await-guarded-switch-list-extra-$value',
      ];
    } finally {
      final marker = await cleanup;
      out = [
        ...out,
        'release-loop-not-await-guarded-switch-list-cleanup-$marker',
      ];
    }
  }
  return out;
}

Future<Map<String, String>> asyncDoWhileNotAwaitGuardedSwitchMapTryCatchFinally(
  Future<bool> again,
  String tier,
  Future<bool> enabled,
  Future<bool> stop,
  Future<String> recovery,
  Future<String> cleanup,
  Map<String, String> extra,
) async {
  var out = <String, String>{
    'mode': 'release-loop-not-await-guarded-switch-map-head',
  };
  do {
    try {
      try {
        if (await stop) break;
        switch (tier) {
          case 'gold' when !await enabled:
            out = {
              ...out,
              'tier': 'release-loop-not-await-guarded-switch-map-gold',
            };
            break;
          case 'blocked':
            throw 'release-loop-not-await-guarded-switch-map-blocked';
          case 'vip' when !await enabled:
            out = {
              ...out,
              'tier': 'release-loop-not-await-guarded-switch-map-vip',
            };
            break;
          default:
            out = {
              ...out,
              'tier': 'release-loop-not-await-guarded-switch-map-other',
            };
        }
        out = {
          ...out,
          for (final entry in extra.entries)
            'release-loop-not-await-guarded-switch-map-extra-${entry.key}':
                entry.value,
        };
      } catch (e) {
        final marker = await recovery;
        out = {
          ...out,
          'error':
              'release-loop-not-await-guarded-switch-map-caught-$marker-$e',
        };
      }
    } finally {
      final marker = await cleanup;
      out = {
        ...out,
        'cleanup': 'release-loop-not-await-guarded-switch-map-cleanup-$marker',
      };
    }
  } while (await again);
  return out;
}

Future<List<String>> asyncForAwaitScrutineeNotAwaitGuardedSwitchFinally(
  int limit,
  Future<String> tierReady,
  Future<bool> enabled,
  Future<bool> skip,
  Future<String> cleanup,
  List<String> extra,
) async {
  var out = <String>[
    'release-for-await-scrutinee-not-await-guarded-switch-head',
  ];
  for (var i = 0; i < limit; i = i + 1) {
    try {
      if (await skip) continue;
      switch (await tierReady) {
        case 'gold' when !await enabled:
          out = [
            ...out,
            'release-for-await-scrutinee-not-await-guarded-switch-gold-$i',
          ];
          break;
        case 'vip' when !await enabled:
          out = [
            ...out,
            'release-for-await-scrutinee-not-await-guarded-switch-vip-$i',
          ];
          break;
        default:
          out = [
            ...out,
            'release-for-await-scrutinee-not-await-guarded-switch-other-$i',
          ];
      }
      out = [
        ...out,
        for (final value in extra)
          'release-for-await-scrutinee-not-await-guarded-switch-extra-$value-$i',
      ];
    } finally {
      final marker = await cleanup;
      out = [
        ...out,
        'release-for-await-scrutinee-not-await-guarded-switch-cleanup-$marker-$i',
      ];
    }
  }
  return out;
}

Future<Map<String, String>>
asyncWhileAwaitScrutineeNotAwaitGuardedMapRecoveryCleanup(
  Future<bool> keepGoing,
  Future<String> tierReady,
  Future<bool> enabled,
  Future<bool> fail,
  Future<String> recovery,
  Future<String> cleanup,
  Map<String, String> extra,
) async {
  var out = <String, String>{
    'mode': 'release-while-await-scrutinee-not-await-guarded-map-head',
  };
  while (await keepGoing) {
    try {
      if (await fail) {
        throw 'release-while-await-scrutinee-not-await-guarded-map-error';
      }
      final tier = await tierReady;
      out = {
        ...out,
        'tier': switch (tier) {
          'gold' when !await enabled =>
            'release-while-await-scrutinee-not-await-guarded-map-gold',
          'vip' when !await enabled =>
            'release-while-await-scrutinee-not-await-guarded-map-vip',
          _ => 'release-while-await-scrutinee-not-await-guarded-map-other',
        },
        for (final entry in extra.entries)
          'release-while-await-scrutinee-not-await-guarded-map-extra-${entry.key}':
              entry.value,
      };
    } catch (e) {
      final marker = await recovery;
      out = {
        ...out,
        'error':
            'release-while-await-scrutinee-not-await-guarded-map-caught-$marker-$e',
      };
    } finally {
      final marker = await cleanup;
      out = {
        ...out,
        'cleanup':
            'release-while-await-scrutinee-not-await-guarded-map-cleanup-$marker',
      };
    }
  }
  return out;
}
