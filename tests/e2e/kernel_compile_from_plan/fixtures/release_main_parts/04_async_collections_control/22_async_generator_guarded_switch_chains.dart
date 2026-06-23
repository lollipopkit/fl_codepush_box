Stream<String> asyncGeneratedGuardedSwitchYieldFor(
  Stream<String> body,
  String tier,
  Future<bool> enabled,
  Future<String> cleanup,
) async* {
  try {
    await for (final value in body) {
      yield 'base-stream-guarded-switch-yield-for-$value';
    }
  } finally {
    final marker = await cleanup;
    yield 'base-stream-guarded-switch-yield-for-cleanup-$marker';
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
      yield ['base-stream-guarded-switch-list-$value'];
    }
  } finally {
    final marker = await cleanup;
    yield ['base-stream-guarded-switch-list-cleanup-$marker'];
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
      yield {'tier': 'base-stream-guarded-switch-map-$value'};
    }
  } catch (e) {
    final marker = await recovery;
    yield {'caught': 'base-stream-guarded-switch-map-caught-$marker-$e'};
  } finally {
    final marker = await cleanup;
    yield {'cleanup': 'base-stream-guarded-switch-map-cleanup-$marker'};
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
      yield 'base-stream-guarded-switch-await-scrutinee-$value';
    }
    yield* tail;
  } catch (e) {
    final marker = await recovery;
    yield 'base-stream-guarded-switch-await-scrutinee-caught-$marker-$e';
  } finally {
    final marker = await cleanup;
    yield 'base-stream-guarded-switch-await-scrutinee-cleanup-$marker';
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
        yield ['base-stream-nested-guarded-switch-$left-$right'];
      }
    }
  } finally {
    final marker = await cleanup;
    yield ['base-stream-nested-guarded-switch-cleanup-$marker'];
  }
}
