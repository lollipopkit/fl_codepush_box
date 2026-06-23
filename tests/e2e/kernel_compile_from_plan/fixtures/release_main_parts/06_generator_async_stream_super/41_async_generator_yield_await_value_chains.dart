Stream<List<String>> asyncGeneratedYieldAwaitListValueSuperChain(
  Stream<String> body,
  Stream<String> cleanup,
  Future<String> label,
  Future<bool> premium,
) async* {
  try {
    await for (final value in body) {
      yield [
        await label,
        (await premium)
            ? 'release-stream-yield-await-list-premium-$value'
            : 'release-stream-yield-await-list-standard-$value',
      ];
    }
  } finally {
    await for (final value in cleanup) {
      yield [await label, 'release-stream-yield-await-list-cleanup-$value'];
    }
  }
}

Stream<Map<String, String>> asyncGeneratedYieldAwaitMapSwitchValueSuperChain(
  Stream<String> body,
  Stream<String> cleanup,
  Future<String> label,
  Future<String> tier,
) async* {
  try {
    await for (final value in body) {
      yield {
        'label': await label,
        'body': switch (await tier) {
          'gold' || 'vip' => 'release-stream-yield-await-map-premium-$value',
          _ => 'release-stream-yield-await-map-standard-$value',
        },
      };
    }
  } finally {
    await for (final value in cleanup) {
      yield {
        'label': await label,
        'cleanup': 'release-stream-yield-await-map-cleanup-$value',
      };
    }
  }
}

Stream<String> asyncGeneratedYieldAwaitStringValueSuperChain(
  Stream<String> body,
  Stream<String> cleanup,
  Future<String> label,
  Future<bool> enabled,
) async* {
  try {
    await for (final value in body) {
      yield (await enabled)
          ? 'release-stream-yield-await-string-${await label}-$value'
          : 'release-stream-yield-await-string-disabled-$value';
    }
  } finally {
    await for (final value in cleanup) {
      yield 'release-stream-yield-await-string-cleanup-${await label}-$value';
    }
  }
}
