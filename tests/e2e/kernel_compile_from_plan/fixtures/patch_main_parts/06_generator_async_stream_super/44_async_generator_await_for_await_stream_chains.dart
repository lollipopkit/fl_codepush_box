Stream<String> asyncGeneratedAwaitForAwaitStreamFutureSuperChain(
  Future<Stream<String>> first,
  Future<Stream<String>> second,
  Stream<String> cleanup,
  Future<bool> skip,
  Future<bool> stop,
) async* {
  try {
    await for (final value in await first) {
      if (await skip) continue;
      yield 'patched-stream-await-for-await-stream-first-$value';
    }
    await for (final value in await second) {
      if (await stop) break;
      yield 'patched-stream-await-for-await-stream-second-$value';
    }
  } finally {
    await for (final value in cleanup) {
      yield 'patched-stream-await-for-await-stream-cleanup-$value';
    }
  }
}

Stream<String> asyncGeneratedAwaitForAwaitStreamFutureCatchFinallySuperChain(
  Future<Stream<String>> body,
  Future<Stream<String>> recovery,
  Future<Stream<String>> cleanup,
) async* {
  try {
    await for (final value in await body) {
      yield 'patched-stream-await-for-await-stream-catch-body-$value';
    }
  } catch (e) {
    await for (final value in await recovery) {
      yield 'patched-stream-await-for-await-stream-catch-recovery-$value-$e';
    }
  } finally {
    await for (final value in await cleanup) {
      yield 'patched-stream-await-for-await-stream-catch-cleanup-$value';
    }
  }
}
