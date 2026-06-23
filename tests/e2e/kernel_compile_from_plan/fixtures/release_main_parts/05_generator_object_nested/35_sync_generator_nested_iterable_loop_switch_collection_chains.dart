Iterable<List<String>> syncGeneratedWhileForInObjectSwitchCollectionCleanup(
  int limit,
  Iterable<String> body,
  Iterable<String> recoveryItems,
  Iterable<String> cleanupItems,
  String tier,
  bool enabled,
  Object candidate,
  Greeter greeter,
  List<String> extra,
) sync* {
  var i = 0;
  while (i < limit) {
    try {
      i = i + 1;
      final user = User('release-iterable-nested-loop-switch-list-user', '$i');
      final box = Box<String>(user.label);
      final dynamic dynamicGreeter = greeter;
      final isString = candidate is String;
      final casted = candidate as String;
      for (final value in body) {
        switch (tier) {
          case 'gold' when enabled:
            yield [
              'release-iterable-nested-loop-switch-list-gold-$value-$i',
              'release-iterable-nested-loop-switch-list-is-$isString',
              dynamicGreeter.surround(
                casted,
                prefix: 'release-iterable-nested-loop-switch-list-candidate-',
                suffix: box.value,
              ),
              for (final item in extra)
                dynamicGreeter.surround(
                  item,
                  prefix: 'release-iterable-nested-loop-switch-list-extra-',
                  suffix: tier,
                ),
            ];
            break;
          case 'blocked':
            throw 'release-iterable-nested-loop-switch-list-blocked';
          default:
            yield ['release-iterable-nested-loop-switch-list-other-$value-$i'];
        }
      }
    } catch (e) {
      yield ['release-iterable-nested-loop-switch-list-caught-$e'];
      for (final value in recoveryItems) {
        yield ['release-iterable-nested-loop-switch-list-recovery-$value'];
      }
    } finally {
      for (final value in cleanupItems) {
        yield ['release-iterable-nested-loop-switch-list-cleanup-$value'];
      }
    }
  }
}

Iterable<Map<String, Object>> syncGeneratedForForInNamedMapYieldStarCleanup(
  int limit,
  Iterable<Map<String, Object>> body,
  Iterable<Map<String, Object>> recoveryItems,
  Iterable<Map<String, Object>> cleanupItems,
  String tier,
  bool enabled,
  Map<String, String> labels,
) sync* {
  for (var i = 0; i < limit; i = i + 1) {
    try {
      final config = Config(
        name: label('release-iterable-nested-loop-switch-map-name'),
        label: '$i',
      );
      switch (tier) {
        case 'gold' when enabled:
          yield {
            'tier': 'release-iterable-nested-loop-switch-map-gold-$i',
            'config': config,
            for (final entry in labels.entries)
              'release-iterable-nested-loop-switch-map-${entry.key}': Config(
                name: entry.key,
                label: label(entry.value),
              ),
          };
          for (final value in body) {
            yield value;
          }
          break;
        case 'blocked':
          throw 'release-iterable-nested-loop-switch-map-blocked';
        default:
          yield {
            'tier': 'release-iterable-nested-loop-switch-map-other-$i',
            'box': Box<String>(
              'release-iterable-nested-loop-switch-map-box-$i',
            ),
          };
      }
    } catch (e) {
      yield {'caught': 'release-iterable-nested-loop-switch-map-caught-$e'};
      yield* recoveryItems;
    } finally {
      yield {'cleanup': 'release-iterable-nested-loop-switch-map-cleanup-head'};
      yield* cleanupItems;
    }
  }
}
