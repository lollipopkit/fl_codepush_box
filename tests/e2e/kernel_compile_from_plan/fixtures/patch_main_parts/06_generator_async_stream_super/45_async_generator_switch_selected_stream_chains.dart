Stream<String> asyncGeneratedYieldStarSwitchSelectedAwaitStreamSuperChain(
  Future<String> tier,
  Future<Stream<String>> premium,
  Future<Stream<String>> standard,
  Stream<String> cleanup,
) async* {
  try {
    yield* switch (await tier) {
      'gold' || 'vip' => await premium,
      _ => await standard,
    };
  } finally {
    await for (final value in cleanup) {
      yield 'patched-stream-switch-selected-yield-star-cleanup-$value';
    }
  }
}

Stream<String> asyncGeneratedAwaitForSwitchSelectedAwaitStreamSuperChain(
  Future<String> tier,
  Future<Stream<String>> premium,
  Future<Stream<String>> standard,
  Stream<String> cleanup,
  Future<bool> skip,
) async* {
  try {
    await for (final value in switch (await tier) {
      'gold' || 'vip' => await premium,
      _ => await standard,
    }) {
      if (await skip) continue;
      yield 'patched-stream-switch-selected-await-for-body-$value';
    }
  } finally {
    await for (final value in cleanup) {
      yield 'patched-stream-switch-selected-await-for-cleanup-$value';
    }
  }
}
