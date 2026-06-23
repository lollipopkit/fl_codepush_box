Stream<String> asyncGeneratedSwitchStatementYieldStarRecoveryCleanup(
  Stream<String> first,
  Stream<String> second,
  Stream<String> recoveryStream,
  Stream<String> cleanupStream,
  Future<String> tierReady,
  Future<bool> enabled,
  Future<String> recovery,
  Future<String> cleanup,
) async* {
  try {
    yield 'base-stream-switch-stmt-yield-star-head';
    yield* first;
  } catch (e) {
    final marker = await recovery;
    yield 'base-stream-switch-stmt-yield-star-caught-$marker-$e';
    yield* recoveryStream;
  } finally {
    final marker = await cleanup;
    yield 'base-stream-switch-stmt-yield-star-cleanup-$marker';
    yield* cleanupStream;
  }
}

Stream<List<String>> asyncGeneratedNestedSwitchStatementYieldStarListCleanup(
  Stream<String> outer,
  Stream<String> delegated,
  Stream<String> cleanupStream,
  Future<String> tierReady,
  Future<bool> enabled,
  Future<String> cleanup,
  List<String> extra,
) async* {
  try {
    await for (final left in outer) {
      yield ['base-stream-nested-switch-stmt-yield-star-list-$left'];
    }
  } finally {
    final marker = await cleanup;
    yield ['base-stream-nested-switch-stmt-yield-star-list-cleanup-$marker'];
    await for (final value in cleanupStream) {
      yield [
        'base-stream-nested-switch-stmt-yield-star-list-cleanup-tail-$value',
      ];
    }
  }
}
