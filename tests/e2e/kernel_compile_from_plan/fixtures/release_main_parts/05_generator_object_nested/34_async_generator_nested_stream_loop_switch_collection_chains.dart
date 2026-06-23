Stream<List<String>> asyncGeneratedWhileAwaitForObjectSwitchCollectionCleanup(
  int limit,
  Stream<String> body,
  Stream<String> recovery,
  Stream<String> cleanup,
  Future<String> ready,
  String tier,
  Future<bool> enabled,
  Object candidate,
  Greeter greeter,
  List<String> extra,
) async* {
  var i = 0;
  while (i < limit) {
    try {
      i = i + 1;
      final marker = await ready;
      final user = User('release-stream-nested-loop-switch-list-user', marker);
      final box = Box<String>(user.label);
      final dynamic dynamicGreeter = greeter;
      final isString = candidate is String;
      final casted = candidate as String;
      await for (final value in body) {
        switch (tier) {
          case 'gold' when await enabled:
            yield [
              'release-stream-nested-loop-switch-list-gold-$value-$i',
              'release-stream-nested-loop-switch-list-is-$isString',
              dynamicGreeter.surround(
                casted,
                prefix: 'release-stream-nested-loop-switch-list-candidate-',
                suffix: box.value,
              ),
              for (final item in extra)
                dynamicGreeter.surround(
                  item,
                  prefix: 'release-stream-nested-loop-switch-list-extra-',
                  suffix: marker,
                ),
            ];
            break;
          case 'blocked':
            throw 'release-stream-nested-loop-switch-list-blocked';
          default:
            yield ['release-stream-nested-loop-switch-list-other-$value-$i'];
        }
      }
    } catch (e) {
      yield ['release-stream-nested-loop-switch-list-caught-$e'];
      await for (final value in recovery) {
        yield ['release-stream-nested-loop-switch-list-recovery-$value'];
      }
    } finally {
      await for (final value in cleanup) {
        yield ['release-stream-nested-loop-switch-list-cleanup-$value'];
      }
    }
  }
}

Stream<Map<String, Object>> asyncGeneratedForAwaitForNamedMapYieldStarCleanup(
  int limit,
  Stream<Map<String, Object>> body,
  Stream<Map<String, Object>> recovery,
  Stream<Map<String, Object>> cleanup,
  Future<String> ready,
  String tier,
  Future<bool> enabled,
  Map<String, String> labels,
) async* {
  for (var i = 0; i < limit; i = i + 1) {
    try {
      final marker = await ready;
      final config = Config(
        name: label('release-stream-nested-loop-switch-map-name'),
        label: marker,
      );
      switch (tier) {
        case 'gold' when await enabled:
          yield {
            'tier': 'release-stream-nested-loop-switch-map-gold-$i',
            'config': config,
            for (final entry in labels.entries)
              'release-stream-nested-loop-switch-map-${entry.key}': Config(
                name: entry.key,
                label: label(entry.value),
              ),
          };
          await for (final value in body) {
            yield value;
          }
          break;
        case 'blocked':
          throw 'release-stream-nested-loop-switch-map-blocked';
        default:
          yield {
            'tier': 'release-stream-nested-loop-switch-map-other-$i',
            'box': Box<String>(
              'release-stream-nested-loop-switch-map-box-$marker',
            ),
          };
      }
    } catch (e) {
      yield {'caught': 'release-stream-nested-loop-switch-map-caught-$e'};
      yield* recovery;
    } finally {
      yield {'cleanup': 'release-stream-nested-loop-switch-map-cleanup-head'};
      yield* cleanup;
    }
  }
}
