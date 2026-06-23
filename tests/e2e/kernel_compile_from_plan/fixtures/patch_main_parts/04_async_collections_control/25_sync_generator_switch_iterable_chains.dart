Iterable<String> syncGeneratedSwitchStatementYieldStarRecoveryCleanup(
  Iterable<String> first,
  Iterable<String> second,
  Iterable<String> recoveryItems,
  Iterable<String> cleanupItems,
  String tier,
  bool enabled,
) sync* {
  try {
    switch (tier) {
      case 'gold' when enabled:
        yield 'patched-iterable-switch-stmt-yield-star-gold-head';
        yield* first;
        break;
      case 'vip' when enabled:
        for (final value in second) {
          if (value == 'skip-sync-switch-stmt-yield-star') continue;
          yield 'patched-iterable-switch-stmt-yield-star-vip-$value';
        }
        break;
      case 'blocked':
        throw 'patched-iterable-switch-stmt-yield-star-blocked';
      default:
        yield 'patched-iterable-switch-stmt-yield-star-other';
    }
  } catch (e) {
    yield 'patched-iterable-switch-stmt-yield-star-caught-$e';
    yield* recoveryItems;
  } finally {
    yield 'patched-iterable-switch-stmt-yield-star-cleanup-head';
    yield* cleanupItems;
  }
}

Iterable<List<String>> syncGeneratedNestedSwitchStatementListCleanup(
  Iterable<String> outer,
  Iterable<String> delegated,
  Iterable<String> cleanupItems,
  String tier,
  bool enabled,
  List<String> extra,
) sync* {
  try {
    for (final left in outer) {
      switch (tier) {
        case 'gold' when enabled:
          yield [
            'patched-iterable-nested-switch-stmt-list-gold-$left',
            for (final item in extra)
              'patched-iterable-nested-switch-stmt-list-extra-$item-$left',
          ];
          break;
        case 'vip' when enabled:
          for (final value in delegated) {
            yield ['patched-iterable-nested-switch-stmt-list-vip-$left-$value'];
          }
          break;
        case 'blocked':
          throw 'patched-iterable-nested-switch-stmt-list-blocked';
        default:
          yield ['patched-iterable-nested-switch-stmt-list-other-$left'];
      }
    }
  } finally {
    yield ['patched-iterable-nested-switch-stmt-list-cleanup-head'];
    for (final value in cleanupItems) {
      yield ['patched-iterable-nested-switch-stmt-list-cleanup-tail-$value'];
    }
  }
}
