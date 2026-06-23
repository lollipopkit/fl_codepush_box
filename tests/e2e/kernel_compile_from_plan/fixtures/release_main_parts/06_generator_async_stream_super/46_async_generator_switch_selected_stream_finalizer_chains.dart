Stream<String> asyncGeneratedSwitchSelectedYieldStarThenAwaitForFinallySuperChain(
  Future<String> tier,
  Future<Stream<String>> primary,
  Future<Stream<String>> fallback,
  Stream<String> tail,
  Future<Stream<String>> cleanup,
  Future<bool> stop,
) async* {
  try {
    yield* switch (await tier) {
      'gold' || 'vip' => await primary,
      _ => await fallback,
    };
    await for (final value in tail) {
      if (await stop) break;
      yield 'release-stream-switch-selected-finalizer-body-$value';
    }
  } finally {
    yield* await cleanup;
  }
}

Stream<String> asyncGeneratedNestedSwitchSelectedAwaitForFinallySuperChain(
  Future<String> outerTier,
  Future<String> innerTier,
  Future<Stream<String>> outerPrimary,
  Future<Stream<String>> outerFallback,
  Future<Stream<String>> innerPrimary,
  Future<Stream<String>> innerFallback,
  Stream<String> cleanup,
  Future<bool> skip,
) async* {
  try {
    await for (final outer in switch (await outerTier) {
      'gold' || 'vip' => await outerPrimary,
      _ => await outerFallback,
    }) {
      await for (final inner in switch (await innerTier) {
        'gold' || 'vip' => await innerPrimary,
        _ => await innerFallback,
      }) {
        if (await skip) continue;
        yield 'release-stream-switch-selected-finalizer-nested-$outer-$inner';
      }
    }
  } catch (e) {
    yield 'release-stream-switch-selected-finalizer-caught-$e';
  } finally {
    await for (final value in cleanup) {
      yield 'release-stream-switch-selected-finalizer-cleanup-$value';
    }
  }
}
