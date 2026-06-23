Stream<String> asyncGeneratedYieldStarAwaitStreamFutureSuperChain(
  Future<Stream<String>> first,
  Stream<String> body,
  Future<Stream<String>> tail,
  Stream<String> cleanup,
  Future<bool> useTail,
) async* {
  try {
    yield* await first;
    await for (final value in body) {
      yield 'patched-stream-yield-star-await-stream-body-$value';
    }
    if (await useTail) {
      yield* await tail;
    }
  } finally {
    await for (final value in cleanup) {
      yield 'patched-stream-yield-star-await-stream-cleanup-$value';
    }
  }
}

Stream<String> asyncGeneratedYieldStarAwaitStreamFutureCatchFinallySuperChain(
  Future<Stream<String>> first,
  Stream<String> recovery,
  Future<Stream<String>> cleanup,
) async* {
  try {
    yield* await first;
  } catch (e) {
    await for (final value in recovery) {
      yield 'patched-stream-yield-star-await-stream-caught-$value-$e';
    }
  } finally {
    yield* await cleanup;
  }
}
