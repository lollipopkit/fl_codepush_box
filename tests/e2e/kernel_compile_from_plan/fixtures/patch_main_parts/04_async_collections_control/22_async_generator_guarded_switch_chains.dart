Stream<String> asyncGeneratedGuardedSwitchYieldFor(
  Stream<String> body,
  String tier,
  Future<bool> enabled,
  Future<String> cleanup,
) async* {
  try {
    await for (final value in body) {
      yield switch (tier) {
        'gold' when !await enabled =>
          'patched-stream-guarded-switch-yield-for-gold-$value',
        'vip' when !await enabled =>
          'patched-stream-guarded-switch-yield-for-vip-$value',
        _ => 'patched-stream-guarded-switch-yield-for-other-$value',
      };
    }
  } finally {
    final marker = await cleanup;
    yield 'patched-stream-guarded-switch-yield-for-cleanup-$marker';
  }
}

Stream<List<String>> asyncGeneratedGuardedSwitchListCleanup(
  Stream<String> body,
  String tier,
  Future<bool> enabled,
  Future<String> cleanup,
  List<String> extra,
) async* {
  try {
    await for (final value in body) {
      yield [
        switch (tier) {
          'gold' when !await enabled =>
            'patched-stream-guarded-switch-list-gold-$value',
          'vip' when !await enabled =>
            'patched-stream-guarded-switch-list-vip-$value',
          _ => 'patched-stream-guarded-switch-list-other-$value',
        },
        for (final item in extra)
          'patched-stream-guarded-switch-list-extra-$item-$value',
      ];
    }
  } finally {
    final marker = await cleanup;
    yield ['patched-stream-guarded-switch-list-cleanup-$marker'];
  }
}

Stream<Map<String, String>> asyncGeneratedGuardedSwitchMapRecoveryCleanup(
  Stream<String> body,
  String tier,
  Future<bool> enabled,
  Future<String> recovery,
  Future<String> cleanup,
  Map<String, String> extra,
) async* {
  try {
    await for (final value in body) {
      yield switch (tier) {
        'gold' when !await enabled => {
          'tier': 'patched-stream-guarded-switch-map-gold-$value',
          for (final entry in extra.entries)
            'patched-stream-guarded-switch-map-extra-${entry.key}': entry.value,
        },
        'blocked' => throw 'patched-stream-guarded-switch-map-blocked',
        'vip' when !await enabled => {
          'tier': 'patched-stream-guarded-switch-map-vip-$value',
          for (final entry in extra.entries)
            'patched-stream-guarded-switch-map-extra-${entry.key}': entry.value,
        },
        _ => {'tier': 'patched-stream-guarded-switch-map-other-$value'},
      };
    }
  } catch (e) {
    final marker = await recovery;
    yield {'caught': 'patched-stream-guarded-switch-map-caught-$marker-$e'};
  } finally {
    final marker = await cleanup;
    yield {'cleanup': 'patched-stream-guarded-switch-map-cleanup-$marker'};
  }
}

Stream<String> asyncGeneratedGuardedSwitchAwaitScrutineeYieldStar(
  Stream<String> body,
  Stream<String> tail,
  Future<String> tierReady,
  Future<bool> enabled,
  Future<String> recovery,
  Future<String> cleanup,
) async* {
  try {
    await for (final value in body) {
      switch (await tierReady) {
        case 'gold' when !await enabled:
          yield 'patched-stream-guarded-switch-await-scrutinee-gold-$value';
          break;
        case 'vip' when !await enabled:
          yield 'patched-stream-guarded-switch-await-scrutinee-vip-$value';
          break;
        default:
          yield 'patched-stream-guarded-switch-await-scrutinee-other-$value';
      }
    }
    yield* tail;
  } catch (e) {
    final marker = await recovery;
    yield 'patched-stream-guarded-switch-await-scrutinee-caught-$marker-$e';
  } finally {
    final marker = await cleanup;
    yield 'patched-stream-guarded-switch-await-scrutinee-cleanup-$marker';
  }
}

Stream<List<String>> asyncGeneratedNestedGuardedSwitchAwaitForCollection(
  Stream<String> outer,
  Stream<String> inner,
  String tier,
  Future<bool> enabled,
  Future<String> cleanup,
  List<String> extra,
) async* {
  try {
    await for (final left in outer) {
      await for (final right in inner) {
        if (right == 'stop-guarded-switch-inner') break;
        yield [
          switch (tier) {
            'gold' when !await enabled =>
              'patched-stream-nested-guarded-switch-gold-$left-$right',
            'vip' when !await enabled =>
              'patched-stream-nested-guarded-switch-vip-$left-$right',
            _ => 'patched-stream-nested-guarded-switch-other-$left-$right',
          },
          for (final item in extra)
            'patched-stream-nested-guarded-switch-extra-$item-$left-$right',
        ];
      }
    }
  } finally {
    final marker = await cleanup;
    yield ['patched-stream-nested-guarded-switch-cleanup-$marker'];
  }
}
