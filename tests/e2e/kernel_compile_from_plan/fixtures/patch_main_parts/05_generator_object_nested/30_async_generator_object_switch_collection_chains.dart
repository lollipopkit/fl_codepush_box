Stream<List<String>> asyncGeneratedObjectSwitchListRecoveryCleanup(
  Stream<String> body,
  Stream<String> cleanupStream,
  Future<String> tierReady,
  Future<bool> enabled,
  Future<String> ready,
  Future<String> recovery,
  Future<String> cleanup,
  Object candidate,
  Greeter greeter,
  List<String> extra,
) async* {
  try {
    final marker = await ready;
    final user = User('patched-stream-object-switch-list-user', marker);
    final box = Box<String>(user.label);
    final dynamic dynamicGreeter = greeter;
    final isString = candidate is String;
    final casted = candidate as String;
    await for (final value in body) {
      switch (await tierReady) {
        case 'gold' when !await enabled:
          yield [
            'patched-stream-object-switch-list-gold-$value',
            'patched-stream-object-switch-list-is-$isString',
            dynamicGreeter.surround(
              casted,
              prefix: 'patched-stream-object-switch-list-candidate-',
              suffix: box.value,
            ),
            for (final item in extra)
              dynamicGreeter.surround(
                item,
                prefix: 'patched-stream-object-switch-list-extra-',
                suffix: marker,
              ),
          ];
          break;
        case 'blocked':
          throw 'patched-stream-object-switch-list-blocked';
        default:
          yield ['patched-stream-object-switch-list-other-$value'];
      }
    }
  } catch (e) {
    final marker = await recovery;
    yield ['patched-stream-object-switch-list-caught-$marker-$e'];
  } finally {
    final marker = await cleanup;
    yield ['patched-stream-object-switch-list-cleanup-$marker'];
    await for (final value in cleanupStream) {
      yield ['patched-stream-object-switch-list-cleanup-tail-$value'];
    }
  }
}

Stream<Map<String, Object>> asyncGeneratedNamedObjectSwitchMapYieldStarCleanup(
  Stream<Map<String, Object>> body,
  Stream<Map<String, Object>> recoveryStream,
  Stream<Map<String, Object>> cleanupStream,
  Future<String> tierReady,
  Future<bool> enabled,
  Future<String> ready,
  Future<String> recovery,
  Future<String> cleanup,
  Map<String, String> labels,
) async* {
  try {
    final marker = await ready;
    final config = Config(
      name: label('patched-stream-object-switch-map-name'),
      label: marker,
    );
    switch (await tierReady) {
      case 'gold' when !await enabled:
        yield {
          'config': config,
          for (final entry in labels.entries)
            'patched-stream-object-switch-map-${entry.key}': Config(
              name: entry.key,
              label: label(entry.value),
            ),
        };
        yield* body;
        break;
      case 'blocked':
        throw 'patched-stream-object-switch-map-blocked';
      default:
        yield {'box': Box<String>('patched-stream-object-switch-map-box')};
    }
  } catch (e) {
    final marker = await recovery;
    yield {'caught': 'patched-stream-object-switch-map-caught-$marker-$e'};
    yield* recoveryStream;
  } finally {
    final marker = await cleanup;
    yield {'cleanup': 'patched-stream-object-switch-map-cleanup-$marker'};
    yield* cleanupStream;
  }
}

Stream<String> asyncGeneratedObjectSwitchAwaitForYieldStarFinally(
  Stream<String> body,
  Stream<String> tail,
  Stream<String> cleanupStream,
  Future<String> tierReady,
  Future<bool> enabled,
  Future<String> ready,
  Future<String> cleanup,
  Greeter greeter,
) async* {
  try {
    final marker = await ready;
    final dynamic dynamicGreeter = greeter;
    await for (final value in body) {
      switch (await tierReady) {
        case 'gold' when !await enabled:
          yield dynamicGreeter.surround(
            value,
            prefix: 'patched-stream-object-switch-await-for-gold-',
            suffix: marker,
          );
          break;
        default:
          yield 'patched-stream-object-switch-await-for-other-$value';
      }
    }
    yield* tail;
  } finally {
    final marker = await cleanup;
    yield 'patched-stream-object-switch-await-for-cleanup-$marker';
    yield* cleanupStream;
  }
}
