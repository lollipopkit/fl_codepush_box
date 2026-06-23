Stream<List<String>> asyncGeneratedYieldAwaitListCollectionForSuperChain(
  Stream<String> body,
  Stream<String> cleanup,
  Future<String> label,
  Future<bool> includeExtra,
  List<String> extra,
  List<String> tail,
) async* {
  try {
    await for (final value in body) {
      yield [
        'patched-stream-yield-await-list-for-head-$value',
        if (await includeExtra)
          for (final item in extra)
            'patched-stream-yield-await-list-for-${await label}-$item',
        ...tail,
      ];
    }
  } finally {
    await for (final value in cleanup) {
      yield [
        'patched-stream-yield-await-list-for-cleanup-${await label}-$value',
        ...tail,
      ];
    }
  }
}

Stream<Map<String, String>> asyncGeneratedYieldAwaitMapCollectionForSuperChain(
  Stream<String> body,
  Stream<String> cleanup,
  Future<String> label,
  Future<bool> includeExtra,
  Map<String, String> extra,
  Map<String, String> tail,
) async* {
  try {
    await for (final value in body) {
      yield {
        'body': 'patched-stream-yield-await-map-for-body-$value',
        if (await includeExtra)
          for (final entry in extra.entries)
            'patched-stream-yield-await-map-for-${entry.key}':
                '${await label}-${entry.value}',
        ...tail,
      };
    }
  } finally {
    await for (final value in cleanup) {
      yield {
        'cleanup':
            'patched-stream-yield-await-map-for-cleanup-${await label}-$value',
        ...tail,
      };
    }
  }
}
