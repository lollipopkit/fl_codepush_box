Stream<String> asyncGeneratedCatchAwaitForRecoveryFinallyYieldStarCleanup(
  Stream<String> body,
  Stream<String> recovery,
  Stream<String> cleanup,
) async* {
  try {
    yield* body;
  } catch (e) {
    yield 'base-stream-catch-await-for-recovery-finally-yield-star-caught-$e';
  } finally {
    yield* cleanup;
  }
}

Stream<String> asyncGeneratedCatchYieldStarRecoveryFinallyAwaitForCleanup(
  Stream<String> body,
  Stream<String> recovery,
  Stream<String> cleanup,
) async* {
  try {
    yield* body;
  } catch (e) {
    yield* recovery;
  } finally {
    yield* cleanup;
  }
}

Stream<List<String>> asyncGeneratedStreamCollectionSwitchFinallyYieldStar(
  Stream<String> body,
  Stream<List<String>> cleanup,
  String tier,
) async* {
  try {
    await for (final value in body) {
      yield ['base-stream-collection-switch-finally-yield-star-body-$value'];
    }
  } finally {
    yield* cleanup;
  }
}

Stream<Map<String, String>>
asyncGeneratedStreamMapSwitchCatchAwaitForFinallyCleanup(
  Stream<String> body,
  Stream<String> recovery,
  Future<String> cleanup,
  String tier,
) async* {
  try {
    await for (final value in body) {
      yield {
        'body': 'base-stream-map-switch-catch-await-for-finally-body-$value',
      };
    }
  } catch (e) {
    yield {
      'caught': 'base-stream-map-switch-catch-await-for-finally-caught-$e',
    };
  } finally {
    final marker = await cleanup;
    yield {
      'cleanup':
          'base-stream-map-switch-catch-await-for-finally-cleanup-$marker',
    };
  }
}

Stream<String> asyncGeneratedNestedCatchAwaitForFinallyYieldStarCleanup(
  Stream<String> first,
  Stream<String> second,
  Stream<String> recovery,
  Stream<String> cleanup,
) async* {
  try {
    yield* first;
    yield* second;
  } catch (e) {
    yield 'base-stream-nested-catch-await-for-finally-yield-star-caught-$e';
  } finally {
    yield* cleanup;
  }
}

Stream<String> asyncGeneratedYieldStarNestedCatchFinallyAwaitForCleanup(
  Stream<String> first,
  Stream<String> second,
  Stream<String> cleanup,
) async* {
  try {
    yield* first;
    yield* second;
  } catch (e) {
    yield 'base-stream-yield-star-nested-catch-finally-await-for-caught-$e';
  } finally {
    yield* cleanup;
  }
}

Stream<List<String>> asyncGeneratedAwaitForCatchCollectionFinallyAwaitFor(
  Stream<String> body,
  Stream<String> recovery,
  Stream<String> cleanup,
  List<String> extra,
) async* {
  try {
    await for (final value in body) {
      yield ['base-stream-await-for-catch-collection-finally-body-$value'];
    }
  } catch (e) {
    yield ['base-stream-await-for-catch-collection-finally-caught-$e'];
  } finally {
    yield* cleanup.map(
      (value) => [
        'base-stream-await-for-catch-collection-finally-cleanup-$value',
      ],
    );
  }
}

Stream<Map<String, String>>
asyncGeneratedYieldStarCatchMapCollectionFinallyYieldStar(
  Stream<Map<String, String>> body,
  Stream<Map<String, String>> recovery,
  Stream<Map<String, String>> cleanup,
  Map<String, String> extra,
) async* {
  try {
    yield* body;
  } catch (e) {
    yield* recovery;
  } finally {
    yield* cleanup;
  }
}

Stream<String> asyncGeneratedSequentialAwaitForFinallyTwoCleanups(
  Stream<String> first,
  Stream<String> second,
  Stream<String> cleanup,
  Stream<String> tail,
) async* {
  try {
    await for (final left in first) {
      yield 'base-stream-sequential-finally-two-cleanups-first-$left';
    }
    await for (final right in second) {
      yield 'base-stream-sequential-finally-two-cleanups-second-$right';
    }
  } finally {
    yield* cleanup;
    yield* tail;
  }
}

Stream<String>
asyncGeneratedYieldStarCatchAwaitForSwitchRecoveryFinallyYieldStar(
  Stream<String> body,
  Stream<String> recovery,
  Stream<String> cleanup,
  String tier,
) async* {
  try {
    yield* body;
  } catch (e) {
    yield* recovery;
  } finally {
    yield* cleanup;
  }
}

Stream<List<String>> asyncGeneratedNestedAwaitForCatchFinallyCollectionCleanup(
  Stream<String> outer,
  Stream<String> inner,
  Stream<String> recovery,
  Stream<String> cleanup,
  List<String> extra,
) async* {
  try {
    await for (final left in outer) {
      await for (final right in inner) {
        yield [
          'base-stream-nested-await-for-collection-cleanup-body-$left-$right',
        ];
      }
    }
  } catch (e) {
    yield ['base-stream-nested-await-for-collection-cleanup-caught-$e'];
  } finally {
    yield* cleanup.map(
      (value) => [
        'base-stream-nested-await-for-collection-cleanup-cleanup-$value',
      ],
    );
  }
}

Stream<Map<String, String>> asyncGeneratedYieldStarCatchFinallyMapCleanup(
  Stream<Map<String, String>> body,
  Stream<String> recovery,
  Stream<Map<String, String>> cleanup,
  Map<String, String> extra,
) async* {
  try {
    yield* body;
  } catch (e) {
    yield {'caught': 'base-stream-yield-star-catch-finally-map-caught-$e'};
  } finally {
    yield* cleanup;
  }
}

Stream<String> asyncGeneratedAwaitForCatchYieldStarFinallyAwaitForTail(
  Stream<String> body,
  Stream<String> recovery,
  Stream<String> cleanup,
  Stream<String> tail,
) async* {
  try {
    await for (final value in body) {
      yield 'base-stream-await-for-catch-yield-star-finally-tail-body-$value';
    }
  } catch (e) {
    yield* recovery;
  } finally {
    yield* cleanup;
    yield* tail;
  }
}

Stream<List<String>> asyncGeneratedYieldStarThenNestedAwaitForFinallyCollection(
  Stream<List<String>> first,
  Stream<String> outer,
  Stream<String> inner,
  Stream<String> cleanup,
  List<String> extra,
) async* {
  try {
    yield* first;
    await for (final left in outer) {
      await for (final right in inner) {
        yield [
          'base-stream-yield-star-nested-await-for-finally-collection-body-$left-$right',
        ];
      }
    }
  } finally {
    yield* cleanup.map(
      (value) => [
        'base-stream-yield-star-nested-await-for-finally-collection-cleanup-$value',
      ],
    );
  }
}

Stream<String> asyncGeneratedTripleYieldStarCatchFinallyAwaitForCleanup(
  Stream<String> first,
  Stream<String> second,
  Stream<String> third,
  Stream<String> recovery,
  Stream<String> cleanup,
) async* {
  try {
    yield* first;
    yield* second;
    yield* third;
  } catch (e) {
    yield* recovery;
  } finally {
    yield* cleanup;
  }
}

Stream<String> asyncGeneratedAwaitForCatchYieldStarFinallyDoubleAwaitForCleanup(
  Stream<String> body,
  Stream<String> recovery,
  Stream<String> cleanup,
  Stream<String> tail,
) async* {
  try {
    await for (final value in body) {
      yield 'base-stream-await-for-catch-yield-star-double-cleanup-body-$value';
    }
  } catch (e) {
    yield* recovery;
  } finally {
    yield* cleanup;
    yield* tail;
  }
}

Stream<List<String>> asyncGeneratedYieldStarCatchAwaitForFinallyListCleanupTail(
  Stream<List<String>> body,
  Stream<String> recovery,
  Stream<String> cleanup,
  List<String> extra,
) async* {
  try {
    yield* body;
  } catch (e) {
    await for (final value in recovery) {
      yield [
        'base-stream-yield-star-catch-await-for-list-cleanup-caught-$value-$e',
      ];
    }
  } finally {
    yield* cleanup.map(
      (value) => [
        'base-stream-yield-star-catch-await-for-list-cleanup-cleanup-$value',
      ],
    );
  }
}

Stream<String> asyncGeneratedNestedAwaitForInnerCatchFinallyYieldStarCleanup(
  Stream<String> outer,
  Stream<String> inner,
  Stream<String> recovery,
  Stream<String> cleanup,
) async* {
  try {
    await for (final left in outer) {
      await for (final right in inner) {
        yield 'base-stream-nested-inner-catch-yield-star-cleanup-body-$left-$right';
      }
    }
  } catch (e) {
    yield* recovery;
  } finally {
    yield* cleanup;
  }
}

Stream<Map<String, String>>
asyncGeneratedYieldStarCatchMapRecoveryFinallyAwaitForCleanupTail(
  Stream<Map<String, String>> body,
  Stream<String> recovery,
  Stream<String> cleanup,
  Map<String, String> extra,
) async* {
  try {
    yield* body;
  } catch (e) {
    await for (final value in recovery) {
      yield {
        'caught':
            'base-stream-yield-star-map-recovery-await-cleanup-caught-$value-$e',
      };
    }
  } finally {
    yield* cleanup.map(
      (value) => {
        'cleanup':
            'base-stream-yield-star-map-recovery-await-cleanup-cleanup-$value',
      },
    );
  }
}

Stream<String> asyncGeneratedSequentialYieldStarAwaitForFinallyYieldStarTail(
  Stream<String> first,
  Stream<String> second,
  Stream<String> cleanup,
  Stream<String> tail,
) async* {
  try {
    yield* first;
    await for (final value in second) {
      yield 'base-stream-sequential-yield-star-await-for-tail-body-$value';
    }
  } finally {
    yield* cleanup;
    yield* tail;
  }
}

Stream<List<String>> asyncGeneratedAwaitForSwitchCatchFinallyListCleanupTail(
  Stream<String> body,
  Stream<String> recovery,
  Stream<String> cleanup,
  String tier,
  List<String> extra,
) async* {
  try {
    await for (final value in body) {
      yield ['base-stream-await-for-switch-list-cleanup-body-$value'];
    }
  } catch (e) {
    yield ['base-stream-await-for-switch-list-cleanup-caught-$e'];
  } finally {
    yield* cleanup.map(
      (value) => ['base-stream-await-for-switch-list-cleanup-cleanup-$value'],
    );
  }
}

Stream<Map<String, String>>
asyncGeneratedAwaitForSwitchCatchMapFinallyYieldStarCleanup(
  Stream<String> body,
  Stream<String> recovery,
  Stream<Map<String, String>> cleanup,
  String tier,
) async* {
  try {
    await for (final value in body) {
      yield {'body': 'base-stream-await-for-switch-catch-map-finally-$value'};
    }
  } catch (e) {
    yield {
      'caught': 'base-stream-await-for-switch-catch-map-finally-caught-$e',
    };
  } finally {
    yield* cleanup;
  }
}
