Stream<String> asyncGeneratedWhileObjectDynamicTypeFinalizerChain(
  int limit,
  Stream<String> cleanup,
  Future<String> ready,
  String tier,
  Object candidate,
  Greeter greeter,
  List<String> extra,
) async* {
  var i = 0;
  while (i < limit) {
    try {
      i = i + 1;
      final marker = await ready;
      final user = User('patched-stream-object-loop-while-user', marker);
      final box = Box<String>(user.label);
      final dynamic dynamicGreeter = greeter;
      final isString = candidate is String;
      final casted = candidate as String;
      yield 'patched-stream-object-loop-while-is-$isString';
      yield switch (tier) {
        'gold' ||
        'vip' => 'patched-stream-object-loop-while-premium-${box.value}',
        _ => 'patched-stream-object-loop-while-standard-${user.label}',
      };
      yield dynamicGreeter.surround(
        casted,
        prefix: 'patched-stream-object-loop-while-candidate-',
        suffix: marker,
      );
      for (final value in extra) {
        yield dynamicGreeter.surround(
          value,
          prefix: 'patched-stream-object-loop-while-extra-',
          suffix: marker,
        );
      }
    } finally {
      await for (final value in cleanup) {
        yield 'patched-stream-object-loop-while-cleanup-$value';
      }
    }
  }
}

Stream<Map<String, Object>>
asyncGeneratedForNamedObjectStaticMapCatchFinallyChain(
  int limit,
  Stream<Map<String, Object>> recovery,
  Stream<Map<String, Object>> cleanup,
  Future<String> ready,
  String tier,
  Future<bool> enabled,
  Future<bool> fail,
  Map<String, String> labels,
) async* {
  for (var i = 0; i < limit; i = i + 1) {
    try {
      try {
        if (await fail) {
          throw 'patched-stream-object-loop-for-error-$i';
        }
        final marker = await ready;
        final config = Config(
          name: label('patched-stream-object-loop-for-name'),
          label: marker,
        );
        switch (tier) {
          case 'gold' when await enabled:
            yield {
              'tier': 'patched-stream-object-loop-for-gold-$i',
              'config': config,
              for (final entry in labels.entries)
                'patched-stream-object-loop-for-${entry.key}': Config(
                  name: entry.key,
                  label: label(entry.value),
                ),
            };
            break;
          case 'blocked':
            throw 'patched-stream-object-loop-for-blocked';
          default:
            yield {
              'tier': 'patched-stream-object-loop-for-other-$i',
              'box': Box<String>('patched-stream-object-loop-for-box-$marker'),
            };
        }
      } catch (e) {
        yield {'caught': 'patched-stream-object-loop-for-caught-$e'};
        yield* recovery;
      }
    } finally {
      yield {'cleanup': 'patched-stream-object-loop-for-cleanup-head-$i'};
      yield* cleanup;
    }
  }
}

Stream<String> asyncGeneratedDoWhileObjectCallCollectionRecoveryCleanupChain(
  int limit,
  Stream<String> recovery,
  Stream<String> cleanup,
  Future<bool> fail,
  Future<String> ready,
  Object candidate,
  Greeter greeter,
  List<String> extra,
) async* {
  var i = 0;
  do {
    try {
      i = i + 1;
      if (await fail) {
        throw 'patched-stream-object-loop-do-error';
      }
      final marker = await ready;
      final dynamic dynamicGreeter = greeter;
      final isString = candidate is String;
      final casted = candidate as String;
      yield 'patched-stream-object-loop-do-is-$isString';
      yield dynamicGreeter.surround(
        casted,
        prefix: 'patched-stream-object-loop-do-candidate-',
        suffix: marker,
      );
      for (final value in extra) {
        yield 'patched-stream-object-loop-do-extra-$value-$marker';
      }
    } catch (e) {
      yield 'patched-stream-object-loop-do-caught-$e';
      yield* recovery;
    } finally {
      await for (final value in cleanup) {
        yield 'patched-stream-object-loop-do-cleanup-$value';
      }
    }
  } while (i < limit);
}
