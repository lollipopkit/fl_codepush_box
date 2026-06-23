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
    switch (await tierReady) {
      case 'gold' when !await enabled:
        yield 'patched-stream-switch-stmt-yield-star-gold-head';
        yield* first;
        break;
      case 'vip' when !await enabled:
        await for (final value in second) {
          if (value == 'skip-switch-stmt-yield-star') continue;
          yield 'patched-stream-switch-stmt-yield-star-vip-$value';
        }
        break;
      case 'blocked':
        throw 'patched-stream-switch-stmt-yield-star-blocked';
      default:
        yield 'patched-stream-switch-stmt-yield-star-other';
    }
  } catch (e) {
    final marker = await recovery;
    yield 'patched-stream-switch-stmt-yield-star-caught-$marker-$e';
    yield* recoveryStream;
  } finally {
    final marker = await cleanup;
    yield 'patched-stream-switch-stmt-yield-star-cleanup-$marker';
    await for (final value in cleanupStream) {
      yield 'patched-stream-switch-stmt-yield-star-cleanup-tail-$value';
    }
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
      switch (await tierReady) {
        case 'gold' when !await enabled:
          yield [
            'patched-stream-nested-switch-stmt-yield-star-list-gold-$left',
            for (final item in extra)
              'patched-stream-nested-switch-stmt-yield-star-list-extra-$item-$left',
          ];
          break;
        case 'vip' when !await enabled:
          await for (final value in delegated) {
            yield [
              'patched-stream-nested-switch-stmt-yield-star-list-vip-$left-$value',
            ];
          }
          break;
        case 'blocked':
          throw 'patched-stream-nested-switch-stmt-yield-star-list-blocked';
        default:
          yield [
            'patched-stream-nested-switch-stmt-yield-star-list-other-$left',
          ];
      }
    }
  } finally {
    final marker = await cleanup;
    yield ['patched-stream-nested-switch-stmt-yield-star-list-cleanup-$marker'];
    await for (final value in cleanupStream) {
      yield [
        'patched-stream-nested-switch-stmt-yield-star-list-cleanup-tail-$value',
      ];
    }
  }
}
