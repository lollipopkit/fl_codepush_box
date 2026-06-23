Stream<String> asyncGeneratedTripleSwitchSelectedAwaitForFinalizerSuperChain(
  Future<String> outerTier,
  Future<String> middleTier,
  Future<String> innerTier,
  Future<Stream<String>> outerPrimary,
  Future<Stream<String>> outerFallback,
  Future<Stream<String>> middlePrimary,
  Future<Stream<String>> middleFallback,
  Future<Stream<String>> innerPrimary,
  Future<Stream<String>> innerFallback,
  Future<Stream<String>> cleanup,
  Future<bool> skipOuter,
  Future<bool> stopInner,
) async* {
  try {
    await for (final outer in switch (await outerTier) {
      'gold' || 'vip' => await outerPrimary,
      _ => await outerFallback,
    }) {
      if (await skipOuter) continue;
      await for (final middle in switch (await middleTier) {
        'gold' || 'vip' => await middlePrimary,
        _ => await middleFallback,
      }) {
        await for (final inner in switch (await innerTier) {
          'gold' || 'vip' => await innerPrimary,
          _ => await innerFallback,
        }) {
          if (await stopInner) break;
          yield 'patched-stream-triple-switch-finalizer-body-$outer-$middle-$inner';
        }
      }
    }
  } catch (e) {
    yield 'patched-stream-triple-switch-finalizer-caught-$e';
  } finally {
    yield* await cleanup;
  }
}

Stream<String> asyncGeneratedTripleSwitchSelectedYieldStarRecoverySuperChain(
  Future<String> firstTier,
  Future<String> secondTier,
  Future<String> cleanupTier,
  Future<Stream<String>> firstPrimary,
  Future<Stream<String>> firstFallback,
  Future<Stream<String>> secondPrimary,
  Future<Stream<String>> secondFallback,
  Future<Stream<String>> cleanupPrimary,
  Future<Stream<String>> cleanupFallback,
  Stream<String> tail,
  Future<bool> skip,
) async* {
  try {
    yield* switch (await firstTier) {
      'gold' || 'vip' => await firstPrimary,
      _ => await firstFallback,
    };
    await for (final value in switch (await secondTier) {
      'gold' || 'vip' => await secondPrimary,
      _ => await secondFallback,
    }) {
      if (await skip) continue;
      yield 'patched-stream-triple-switch-recovery-body-$value';
    }
  } catch (e) {
    yield* tail;
  } finally {
    await for (final value in switch (await cleanupTier) {
      'gold' || 'vip' => await cleanupPrimary,
      _ => await cleanupFallback,
    }) {
      yield 'patched-stream-triple-switch-recovery-cleanup-$value';
    }
  }
}
