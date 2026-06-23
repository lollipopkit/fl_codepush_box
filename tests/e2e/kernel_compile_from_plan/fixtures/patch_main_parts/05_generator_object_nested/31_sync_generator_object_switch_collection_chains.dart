Iterable<List<String>> syncGeneratedObjectSwitchListRecoveryCleanup(
  Iterable<String> body,
  Iterable<String> cleanupItems,
  String tier,
  bool enabled,
  Object candidate,
  Greeter greeter,
  List<String> extra,
) sync* {
  try {
    final user = User('patched-iterable-object-switch-list-user', tier);
    final box = Box<String>(user.label);
    final dynamic dynamicGreeter = greeter;
    final isString = candidate is String;
    final casted = candidate as String;
    for (final value in body) {
      switch (tier) {
        case 'gold' when enabled:
          yield [
            'patched-iterable-object-switch-list-gold-$value',
            'patched-iterable-object-switch-list-is-$isString',
            dynamicGreeter.surround(
              casted,
              prefix: 'patched-iterable-object-switch-list-candidate-',
              suffix: box.value,
            ),
            for (final item in extra)
              dynamicGreeter.surround(
                item,
                prefix: 'patched-iterable-object-switch-list-extra-',
                suffix: tier,
              ),
          ];
          break;
        case 'blocked':
          throw 'patched-iterable-object-switch-list-blocked';
        default:
          yield ['patched-iterable-object-switch-list-other-$value'];
      }
    }
  } catch (e) {
    yield ['patched-iterable-object-switch-list-caught-$e'];
  } finally {
    yield ['patched-iterable-object-switch-list-cleanup-head'];
    for (final value in cleanupItems) {
      yield ['patched-iterable-object-switch-list-cleanup-tail-$value'];
    }
  }
}

Iterable<Map<String, Object>> syncGeneratedNamedObjectSwitchMapYieldStarCleanup(
  Iterable<Map<String, Object>> body,
  Iterable<Map<String, Object>> recoveryItems,
  Iterable<Map<String, Object>> cleanupItems,
  String tier,
  bool enabled,
  Map<String, String> labels,
) sync* {
  try {
    final config = Config(
      name: label('patched-iterable-object-switch-map-name'),
      label: tier,
    );
    switch (tier) {
      case 'gold' when enabled:
        yield {
          'config': config,
          for (final entry in labels.entries)
            'patched-iterable-object-switch-map-${entry.key}': Config(
              name: entry.key,
              label: label(entry.value),
            ),
        };
        yield* body;
        break;
      case 'blocked':
        throw 'patched-iterable-object-switch-map-blocked';
      default:
        yield {'box': Box<String>('patched-iterable-object-switch-map-box')};
    }
  } catch (e) {
    yield {'caught': 'patched-iterable-object-switch-map-caught-$e'};
    yield* recoveryItems;
  } finally {
    yield {'cleanup': 'patched-iterable-object-switch-map-cleanup-head'};
    yield* cleanupItems;
  }
}

Iterable<String> syncGeneratedObjectSwitchForInYieldStarFinally(
  Iterable<String> body,
  Iterable<String> tail,
  Iterable<String> cleanupItems,
  String tier,
  bool enabled,
  Greeter greeter,
) sync* {
  try {
    final dynamic dynamicGreeter = greeter;
    for (final value in body) {
      switch (tier) {
        case 'gold' when enabled:
          yield dynamicGreeter.surround(
            value,
            prefix: 'patched-iterable-object-switch-for-in-gold-',
            suffix: tier,
          );
          break;
        default:
          yield 'patched-iterable-object-switch-for-in-other-$value';
      }
    }
    yield* tail;
  } finally {
    yield 'patched-iterable-object-switch-for-in-cleanup-head';
    yield* cleanupItems;
  }
}
