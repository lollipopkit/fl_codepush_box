Iterable<String> syncGeneratedWhileObjectDynamicTypeFinalizerChain(
  int limit,
  Iterable<String> cleanupItems,
  String tier,
  Object candidate,
  Greeter greeter,
  List<String> extra,
) sync* {
  var i = 0;
  while (i < limit) {
    try {
      i = i + 1;
      final user = User('release-iterable-object-loop-while-user', '$i');
      final box = Box<String>(user.label);
      final dynamic dynamicGreeter = greeter;
      final isString = candidate is String;
      final casted = candidate as String;
      yield 'release-iterable-object-loop-while-is-$isString';
      yield switch (tier) {
        'gold' ||
        'vip' => 'release-iterable-object-loop-while-premium-${box.value}',
        _ => 'release-iterable-object-loop-while-standard-${user.label}',
      };
      yield dynamicGreeter.surround(
        casted,
        prefix: 'release-iterable-object-loop-while-candidate-',
        suffix: box.value,
      );
      for (final value in extra) {
        yield dynamicGreeter.surround(
          value,
          prefix: 'release-iterable-object-loop-while-extra-',
          suffix: tier,
        );
      }
    } finally {
      yield 'release-iterable-object-loop-while-cleanup-head-$i';
      for (final value in cleanupItems) {
        yield 'release-iterable-object-loop-while-cleanup-tail-$value';
      }
    }
  }
}

Iterable<Map<String, Object>>
syncGeneratedForNamedObjectStaticMapCatchFinallyChain(
  int limit,
  Iterable<Map<String, Object>> recoveryItems,
  Iterable<Map<String, Object>> cleanupItems,
  String tier,
  bool enabled,
  bool fail,
  Map<String, String> labels,
) sync* {
  for (var i = 0; i < limit; i = i + 1) {
    try {
      try {
        if (fail && i == 1) {
          throw 'release-iterable-object-loop-for-error-$i';
        }
        final config = Config(
          name: label('release-iterable-object-loop-for-name'),
          label: '$i',
        );
        switch (tier) {
          case 'gold' when enabled:
            yield {
              'tier': 'release-iterable-object-loop-for-gold-$i',
              'config': config,
              for (final entry in labels.entries)
                'release-iterable-object-loop-for-${entry.key}': Config(
                  name: entry.key,
                  label: label(entry.value),
                ),
            };
            break;
          case 'blocked':
            throw 'release-iterable-object-loop-for-blocked';
          default:
            yield {
              'tier': 'release-iterable-object-loop-for-other-$i',
              'box': Box<String>('release-iterable-object-loop-for-box-$i'),
            };
        }
      } catch (e) {
        yield {'caught': 'release-iterable-object-loop-for-caught-$e'};
        yield* recoveryItems;
      }
    } finally {
      yield {'cleanup': 'release-iterable-object-loop-for-cleanup-head-$i'};
      yield* cleanupItems;
    }
  }
}

Iterable<String> syncGeneratedDoWhileObjectCallCollectionRecoveryCleanupChain(
  int limit,
  Iterable<String> recoveryItems,
  Iterable<String> cleanupItems,
  bool fail,
  Object candidate,
  Greeter greeter,
  List<String> extra,
) sync* {
  var i = 0;
  do {
    try {
      i = i + 1;
      if (fail && i == 1) {
        throw 'release-iterable-object-loop-do-error';
      }
      final dynamic dynamicGreeter = greeter;
      final isString = candidate is String;
      final casted = candidate as String;
      yield 'release-iterable-object-loop-do-is-$isString';
      yield dynamicGreeter.surround(
        casted,
        prefix: 'release-iterable-object-loop-do-candidate-',
        suffix: '$i',
      );
      for (final value in extra) {
        yield 'release-iterable-object-loop-do-extra-$value-$i';
      }
    } catch (e) {
      yield 'release-iterable-object-loop-do-caught-$e';
      yield* recoveryItems;
    } finally {
      yield 'release-iterable-object-loop-do-cleanup-head-$i';
      yield* cleanupItems;
    }
  } while (i < limit);
}
