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
            ? 'patched-stream-yield-await-list-premium-$value'
            : 'patched-stream-yield-await-list-standard-$value',
      ];
    }
  } finally {
    await for (final value in cleanup) {
      yield [await label, 'patched-stream-yield-await-list-cleanup-$value'];
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
          'gold' || 'vip' => 'patched-stream-yield-await-map-premium-$value',
          _ => 'patched-stream-yield-await-map-standard-$value',
        },
      };
    }
  } finally {
    await for (final value in cleanup) {
      yield {
        'label': await label,
        'cleanup': 'patched-stream-yield-await-map-cleanup-$value',
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
          ? 'patched-stream-yield-await-string-${await label}-$value'
          : 'patched-stream-yield-await-string-disabled-$value';
    }
  } finally {
    await for (final value in cleanup) {
      yield 'patched-stream-yield-await-string-cleanup-${await label}-$value';
    }
  }
}
