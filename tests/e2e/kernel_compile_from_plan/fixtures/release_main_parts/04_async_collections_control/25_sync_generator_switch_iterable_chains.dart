Iterable<String> syncGeneratedSwitchStatementYieldStarRecoveryCleanup(
  Iterable<String> first,
  Iterable<String> second,
  Iterable<String> recoveryItems,
  Iterable<String> cleanupItems,
  String tier,
  bool enabled,
) sync* {
  try {
    yield 'base-iterable-switch-stmt-yield-star-head';
    yield* first;
  } catch (e) {
    yield 'base-iterable-switch-stmt-yield-star-caught-$e';
    yield* recoveryItems;
  } finally {
    yield 'base-iterable-switch-stmt-yield-star-cleanup-head';
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
      yield ['base-iterable-nested-switch-stmt-list-$left'];
    }
  } finally {
    yield ['base-iterable-nested-switch-stmt-list-cleanup-head'];
    for (final value in cleanupItems) {
      yield ['base-iterable-nested-switch-stmt-list-cleanup-tail-$value'];
    }
  }
}
