Future<List<String>> asyncWhileObjectDynamicTypeFinalizerChain(
  Future<bool> keepGoing,
  Future<bool> skip,
  Future<bool> stop,
  Future<String> ready,
  Future<String> cleanup,
  String tier,
  Object candidate,
  Greeter greeter,
  List<String> extra,
) async {
  var out = <String>['release-async-object-loop-while-head'];
  while (await keepGoing) {
    try {
      if (await skip) continue;
      if (await stop) break;
      final marker = await ready;
      final user = User('release-async-object-loop-while-user', marker);
      final box = Box<String>(user.label);
      final dynamic dynamicGreeter = greeter;
      final isString = candidate is String;
      final casted = candidate as String;
      out = [
        ...out,
        'release-async-object-loop-while-is-$isString',
        switch (tier) {
          'gold' ||
          'vip' => 'release-async-object-loop-while-premium-${box.value}',
          _ => 'release-async-object-loop-while-standard-${user.label}',
        },
        dynamicGreeter.surround(
          casted,
          prefix: 'release-async-object-loop-while-candidate-',
          suffix: marker,
        ),
        for (final value in extra)
          dynamicGreeter.surround(
            value,
            prefix: 'release-async-object-loop-while-extra-',
            suffix: marker,
          ),
      ];
    } finally {
      final marker = await cleanup;
      out = [...out, 'release-async-object-loop-while-cleanup-$marker'];
    }
  }
  return out;
}

Future<Map<String, Object>> asyncForNamedObjectStaticMapCatchFinallyChain(
  int limit,
  Future<String> tierReady,
  Future<bool> enabled,
  Future<bool> fail,
  Future<String> ready,
  Future<String> recovery,
  Future<String> cleanup,
  Map<String, String> labels,
) async {
  var out = <String, Object>{'mode': 'release-async-object-loop-for-head'};
  for (var i = 0; i < limit; i = i + 1) {
    try {
      try {
        if (await fail) {
          throw 'release-async-object-loop-for-error-$i';
        }
        final marker = await ready;
        final config = Config(
          name: label('release-async-object-loop-for-name'),
          label: marker,
        );
        switch (await tierReady) {
          case 'gold' when !await enabled:
            out = {
              ...out,
              'tier': 'release-async-object-loop-for-gold-$i',
              'config': config,
              for (final entry in labels.entries)
                'release-async-object-loop-for-${entry.key}': Config(
                  name: entry.key,
                  label: label(entry.value),
                ),
            };
            break;
          case 'blocked':
            throw 'release-async-object-loop-for-blocked';
          default:
            out = {
              ...out,
              'tier': 'release-async-object-loop-for-other-$i',
              'box': Box<String>('release-async-object-loop-for-box-$marker'),
            };
        }
      } catch (e) {
        final marker = await recovery;
        out = {
          ...out,
          'error': 'release-async-object-loop-for-caught-$marker-$e',
        };
      }
    } finally {
      final marker = await cleanup;
      out = {
        ...out,
        'cleanup': 'release-async-object-loop-for-cleanup-$marker',
      };
    }
  }
  return out;
}

Future<List<String>> asyncDoWhileObjectCallCollectionRecoveryCleanupChain(
  Future<bool> keepGoing,
  Future<bool> fail,
  Future<String> ready,
  Future<String> recovery,
  Future<String> cleanup,
  Object candidate,
  Greeter greeter,
  List<String> extra,
) async {
  var out = <String>['release-async-object-loop-do-head'];
  do {
    try {
      if (await fail) {
        throw 'release-async-object-loop-do-error';
      }
      final marker = await ready;
      final dynamic dynamicGreeter = greeter;
      final casted = candidate as String;
      out = [
        ...out,
        dynamicGreeter.surround(
          casted,
          prefix: 'release-async-object-loop-do-candidate-',
          suffix: marker,
        ),
        for (final value in extra)
          'release-async-object-loop-do-extra-$value-$marker',
      ];
    } catch (e) {
      final marker = await recovery;
      out = [...out, 'release-async-object-loop-do-caught-$marker-$e'];
    } finally {
      final marker = await cleanup;
      out = [...out, 'release-async-object-loop-do-cleanup-$marker'];
    }
  } while (await keepGoing);
  return out;
}
