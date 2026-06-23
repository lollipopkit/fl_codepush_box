Stream<String> asyncGeneratedCatchAwaitForRecoveryFinallyYieldStarCleanup(
  Stream<String> body,
  Stream<String> recovery,
  Stream<String> cleanup,
) async* {
  try {
    await for (final value in body) {
      yield 'patched-stream-catch-await-for-recovery-finally-yield-star-body-$value';
    }
  } catch (e) {
    await for (final value in recovery) {
      yield 'patched-stream-catch-await-for-recovery-finally-yield-star-caught-$value-$e';
    }
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
    yield 'patched-stream-catch-yield-star-recovery-finally-await-for-caught-$e';
  } finally {
    await for (final value in cleanup) {
      yield 'patched-stream-catch-yield-star-recovery-finally-await-for-cleanup-$value';
    }
  }
}

Stream<List<String>> asyncGeneratedStreamCollectionSwitchFinallyYieldStar(
  Stream<String> body,
  Stream<List<String>> cleanup,
  String tier,
) async* {
  try {
    await for (final value in body) {
      yield [
        'patched-stream-collection-switch-finally-yield-star-head',
        ...switch (tier) {
          'gold' || 'vip' => [
            'patched-stream-collection-switch-finally-yield-star-premium',
          ],
          _ => ['patched-stream-collection-switch-finally-yield-star-standard'],
        },
        'patched-stream-collection-switch-finally-yield-star-body-$value',
      ];
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
    yield {
      'mode': 'patched-stream-map-switch-catch-await-for-finally-head',
      ...switch (tier) {
        'gold' || 'vip' => {
          'state': 'patched-stream-map-switch-catch-await-for-finally-premium',
        },
        _ => {
          'state': 'patched-stream-map-switch-catch-await-for-finally-standard',
        },
      },
    };
    await for (final value in body) {
      yield {
        'body': 'patched-stream-map-switch-catch-await-for-finally-body-$value',
      };
    }
  } catch (e) {
    await for (final value in recovery) {
      yield {
        'caught':
            'patched-stream-map-switch-catch-await-for-finally-caught-$value-$e',
      };
    }
  } finally {
    final marker = await cleanup;
    yield {
      'cleanup':
          'patched-stream-map-switch-catch-await-for-finally-cleanup-$marker',
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
    try {
      await for (final left in first) {
        if (left == 'skip-nested-finalizer') continue;
        yield 'patched-stream-nested-catch-await-for-finally-yield-star-first-$left';
      }
      yield* second;
    } catch (e) {
      await for (final value in recovery) {
        yield 'patched-stream-nested-catch-await-for-finally-yield-star-inner-$value-$e';
      }
    }
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
    try {
      yield* second;
    } catch (e) {
      yield 'patched-stream-yield-star-nested-catch-finally-await-for-inner-$e';
    }
  } finally {
    await for (final value in cleanup) {
      if (value == 'skip-cleanup-finalizer') continue;
      yield 'patched-stream-yield-star-nested-catch-finally-await-for-cleanup-$value';
    }
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
      yield [
        'patched-stream-await-for-catch-collection-finally-body-$value',
        for (final item in extra)
          'patched-stream-await-for-catch-collection-finally-extra-$item',
      ];
    }
  } catch (e) {
    await for (final value in recovery) {
      yield [
        'patched-stream-await-for-catch-collection-finally-caught-$value-$e',
      ];
    }
  } finally {
    await for (final value in cleanup) {
      yield [
        'patched-stream-await-for-catch-collection-finally-cleanup-$value',
      ];
    }
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
    yield {
      'caught': 'patched-stream-yield-star-catch-map-finally-caught-$e',
      for (final entry in extra.entries)
        'patched-stream-yield-star-catch-map-finally-extra-${entry.key}':
            entry.value,
    };
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
      yield 'patched-stream-sequential-finally-two-cleanups-first-$left';
    }
    await for (final right in second) {
      if (right == 'skip-second-cleanup-chain') continue;
      yield 'patched-stream-sequential-finally-two-cleanups-second-$right';
    }
  } finally {
    await for (final value in cleanup) {
      yield 'patched-stream-sequential-finally-two-cleanups-cleanup-$value';
    }
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
    await for (final value in recovery) {
      yield switch (tier) {
        'gold' || 'vip' =>
          'patched-stream-yield-star-catch-switch-recovery-premium-$value-$e',
        _ =>
          'patched-stream-yield-star-catch-switch-recovery-standard-$value-$e',
      };
    }
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
          'patched-stream-nested-await-for-collection-cleanup-body-$left-$right',
          for (final value in extra)
            'patched-stream-nested-await-for-collection-cleanup-extra-$value',
        ];
      }
    }
  } catch (e) {
    await for (final value in recovery) {
      yield [
        'patched-stream-nested-await-for-collection-cleanup-caught-$value-$e',
      ];
    }
  } finally {
    await for (final value in cleanup) {
      yield [
        'patched-stream-nested-await-for-collection-cleanup-cleanup-$value',
      ];
    }
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
    await for (final value in recovery) {
      yield {
        'caught':
            'patched-stream-yield-star-catch-finally-map-caught-$value-$e',
        for (final entry in extra.entries)
          'patched-stream-yield-star-catch-finally-map-extra-${entry.key}':
              entry.value,
      };
    }
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
      if (value == 'stop-body-tail-chain') break;
      yield 'patched-stream-await-for-catch-yield-star-finally-tail-body-$value';
    }
  } catch (e) {
    yield* recovery;
    yield 'patched-stream-await-for-catch-yield-star-finally-tail-caught-$e';
  } finally {
    await for (final value in cleanup) {
      yield 'patched-stream-await-for-catch-yield-star-finally-tail-cleanup-$value';
    }
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
      if (left == 'skip-nested-tail-chain') continue;
      await for (final right in inner) {
        yield [
          'patched-stream-yield-star-nested-await-for-finally-collection-body-$left-$right',
          for (final value in extra)
            'patched-stream-yield-star-nested-await-for-finally-collection-extra-$value',
        ];
      }
    }
  } finally {
    await for (final value in cleanup) {
      yield [
        'patched-stream-yield-star-nested-await-for-finally-collection-cleanup-$value',
      ];
    }
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
    await for (final value in recovery) {
      yield 'patched-stream-triple-yield-star-catch-finally-cleanup-caught-$value-$e';
    }
  } finally {
    await for (final value in cleanup) {
      if (value == 'skip-triple-cleanup') continue;
      yield 'patched-stream-triple-yield-star-catch-finally-cleanup-$value';
    }
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
      yield switch (tier) {
        'gold' || 'vip' => {
          'body':
              'patched-stream-await-for-switch-catch-map-finally-premium-$value',
        },
        _ => {
          'body':
              'patched-stream-await-for-switch-catch-map-finally-standard-$value',
        },
      };
    }
  } catch (e) {
    await for (final value in recovery) {
      yield {
        'caught':
            'patched-stream-await-for-switch-catch-map-finally-caught-$value-$e',
      };
    }
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
      if (value == 'skip-double-await-for-cleanup') continue;
      yield 'patched-stream-await-for-catch-yield-star-double-cleanup-body-$value';
    }
  } catch (e) {
    yield* recovery;
    yield 'patched-stream-await-for-catch-yield-star-double-cleanup-caught-$e';
  } finally {
    await for (final value in cleanup) {
      yield 'patched-stream-await-for-catch-yield-star-double-cleanup-cleanup-$value';
    }
    await for (final value in tail) {
      yield 'patched-stream-await-for-catch-yield-star-double-cleanup-tail-$value';
    }
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
        'patched-stream-yield-star-catch-await-for-list-cleanup-caught-$value-$e',
        for (final item in extra)
          'patched-stream-yield-star-catch-await-for-list-cleanup-extra-$item',
      ];
    }
  } finally {
    await for (final value in cleanup) {
      yield [
        'patched-stream-yield-star-catch-await-for-list-cleanup-cleanup-$value',
        for (final item in extra)
          'patched-stream-yield-star-catch-await-for-list-cleanup-tail-$item',
      ];
    }
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
      try {
        await for (final right in inner) {
          if (right == 'stop-inner-finalizer-chain') break;
          yield 'patched-stream-nested-inner-catch-yield-star-cleanup-body-$left-$right';
        }
      } catch (e) {
        await for (final value in recovery) {
          yield 'patched-stream-nested-inner-catch-yield-star-cleanup-caught-$value-$e';
        }
      }
    }
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
            'patched-stream-yield-star-map-recovery-await-cleanup-caught-$value-$e',
        for (final entry in extra.entries)
          'patched-stream-yield-star-map-recovery-await-cleanup-extra-${entry.key}':
              entry.value,
      };
    }
  } finally {
    await for (final value in cleanup) {
      yield {
        'cleanup':
            'patched-stream-yield-star-map-recovery-await-cleanup-cleanup-$value',
        for (final entry in extra.entries)
          'patched-stream-yield-star-map-recovery-await-cleanup-tail-${entry.key}':
              entry.value,
      };
    }
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
      if (value == 'skip-sequential-yield-star-await-for') continue;
      yield 'patched-stream-sequential-yield-star-await-for-tail-body-$value';
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
      yield switch (tier) {
        'gold' || 'vip' => [
          'patched-stream-await-for-switch-list-cleanup-premium-$value',
          for (final item in extra)
            'patched-stream-await-for-switch-list-cleanup-extra-$item',
        ],
        _ => ['patched-stream-await-for-switch-list-cleanup-standard-$value'],
      };
    }
  } catch (e) {
    await for (final value in recovery) {
      yield ['patched-stream-await-for-switch-list-cleanup-caught-$value-$e'];
    }
  } finally {
    await for (final value in cleanup) {
      yield ['patched-stream-await-for-switch-list-cleanup-cleanup-$value'];
    }
  }
}
