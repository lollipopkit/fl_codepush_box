Stream<List<String>> asyncGeneratedObjectDynamicTypeAwaitForCleanup(
  Stream<String> body,
  Stream<String> cleanup,
  Future<String> ready,
  Object candidate,
  Greeter greeter,
  List<String> extra,
) async* {
  try {
    final marker = await ready;
    final user = User('release-stream-object-dynamic-type-user', marker);
    final box = Box<String>(user.label);
    final dynamic dynamicGreeter = greeter;
    final isString = candidate is String;
    final casted = candidate as String;
    await for (final value in body) {
      yield [
        'release-stream-object-dynamic-type-body-$value',
        'release-stream-object-dynamic-type-is-$isString',
        dynamicGreeter.surround(
          casted,
          prefix: 'release-stream-object-dynamic-type-candidate-',
          suffix: box.value,
        ),
        for (final item in extra)
          dynamicGreeter.surround(
            item,
            prefix: 'release-stream-object-dynamic-type-extra-',
            suffix: marker,
          ),
      ];
    }
  } finally {
    await for (final value in cleanup) {
      yield ['release-stream-object-dynamic-type-cleanup-$value'];
    }
  }
}

Stream<Map<String, Object>> asyncGeneratedNamedObjectStaticYieldStarRecovery(
  Stream<Map<String, Object>> body,
  Stream<Map<String, Object>> recovery,
  Stream<Map<String, Object>> cleanup,
  Future<String> ready,
  Map<String, String> labels,
) async* {
  try {
    final marker = await ready;
    yield {
      'head': Config(
        name: label('release-stream-named-object-static-name'),
        label: marker,
      ),
      for (final entry in labels.entries)
        'release-stream-named-object-static-${entry.key}': Config(
          name: entry.key,
          label: label(entry.value),
        ),
    };
    yield* body;
  } catch (e) {
    yield {'caught': 'release-stream-named-object-static-caught-$e'};
    yield* recovery;
  } finally {
    yield* cleanup;
  }
}

Stream<String> asyncGeneratedObjectCallAwaitForYieldStarFinally(
  Stream<String> body,
  Stream<String> tail,
  Stream<String> cleanup,
  Future<String> ready,
  Greeter greeter,
) async* {
  try {
    final marker = await ready;
    final dynamic dynamicGreeter = greeter;
    await for (final value in body) {
      yield dynamicGreeter.surround(
        value,
        prefix: 'release-stream-object-call-await-for-',
        suffix: marker,
      );
    }
    yield* tail;
  } finally {
    await for (final value in cleanup) {
      yield 'release-stream-object-call-await-for-cleanup-$value';
    }
  }
}
