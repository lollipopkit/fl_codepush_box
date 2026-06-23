Stream<String> asyncGeneratedYieldStarNestedCatchFinallyAwaitRecovery(
  Stream<String> first,
  Stream<String> second,
  Future<String> recovery,
  Future<String> cleanup,
) async* {
  try {
    yield* first;
    yield* second;
  } catch (e) {
    yield 'base-stream-yield-star-nested-caught-$e';
  } finally {
    final marker = await cleanup;
    yield 'base-stream-yield-star-nested-cleanup-$marker';
  }
}

Stream<String> asyncGeneratedYieldStarNestedFinallyAwaitCleanup(
  Stream<String> first,
  Stream<String> second,
  Future<String> cleanup,
) async* {
  try {
    yield* first;
    yield* second;
  } finally {
    final marker = await cleanup;
    yield 'base-stream-yield-star-nested-finally-cleanup-$marker';
  }
}

Stream<String> asyncGeneratedAwaitForNestedCatchFinallyAwaitRecovery(
  Stream<String> outer,
  Stream<String> inner,
  Future<String> recovery,
  Future<String> cleanup,
) async* {
  try {
    await for (final left in outer) {
      await for (final right in inner) {
        yield 'base-stream-await-for-nested-catch-finally-await-body-$left-$right';
      }
    }
  } catch (e) {
    final marker = await recovery;
    yield 'base-stream-await-for-nested-catch-finally-await-caught-$marker-$e';
  } finally {
    final marker = await cleanup;
    yield 'base-stream-await-for-nested-catch-finally-await-cleanup-$marker';
  }
}

Stream<String> asyncGeneratedAwaitForTripleNestedCatchFinallyAwaitRecovery(
  Stream<String> outer,
  Stream<String> middle,
  Stream<String> inner,
  Future<String> recovery,
  Future<String> cleanup,
) async* {
  try {
    await for (final left in outer) {
      await for (final center in middle) {
        await for (final right in inner) {
          yield 'base-stream-await-for-triple-nested-catch-finally-await-body-$left-$center-$right';
        }
      }
    }
  } catch (e) {
    final marker = await recovery;
    yield 'base-stream-await-for-triple-nested-catch-finally-await-caught-$marker-$e';
  } finally {
    final marker = await cleanup;
    yield 'base-stream-await-for-triple-nested-catch-finally-await-cleanup-$marker';
  }
}

Stream<String> asyncGeneratedYieldStarTripleNestedCatchFinallyAwaitRecovery(
  Stream<String> first,
  Stream<String> second,
  Stream<String> third,
  Future<String> recovery,
  Future<String> cleanup,
) async* {
  try {
    yield* first;
    yield* second;
    yield* third;
  } catch (e) {
    final marker = await recovery;
    yield 'base-stream-yield-star-triple-nested-caught-$marker-$e';
  } finally {
    final marker = await cleanup;
    yield 'base-stream-yield-star-triple-nested-cleanup-$marker';
  }
}

Stream<String> asyncGeneratedYieldStarTripleNestedFinallyAwaitCleanup(
  Stream<String> first,
  Stream<String> second,
  Stream<String> third,
  Future<String> cleanup,
) async* {
  try {
    yield* first;
    yield* second;
    yield* third;
  } finally {
    final marker = await cleanup;
    yield 'base-stream-yield-star-triple-nested-finally-cleanup-$marker';
  }
}

Stream<String>
asyncGeneratedAwaitForNestedBreakContinueCatchFinallyAwaitRecovery(
  Stream<String> outer,
  Stream<String> inner,
  Future<String> recovery,
  Future<String> cleanup,
) async* {
  try {
    await for (final left in outer) {
      await for (final right in inner) {
        yield 'base-stream-await-for-nested-break-continue-catch-finally-await-body-$left-$right';
      }
    }
  } catch (e) {
    final marker = await recovery;
    yield 'base-stream-await-for-nested-break-continue-catch-finally-await-caught-$marker-$e';
  } finally {
    final marker = await cleanup;
    yield 'base-stream-await-for-nested-break-continue-catch-finally-await-cleanup-$marker';
  }
}

Stream<String> asyncGeneratedAwaitForTripleNestedFinallyAwaitCleanup(
  Stream<String> outer,
  Stream<String> middle,
  Stream<String> inner,
  Future<String> cleanup,
) async* {
  try {
    await for (final left in outer) {
      await for (final center in middle) {
        await for (final right in inner) {
          yield 'base-stream-await-for-triple-nested-finally-await-body-$left-$center-$right';
        }
      }
    }
  } finally {
    final marker = await cleanup;
    yield 'base-stream-await-for-triple-nested-finally-await-cleanup-$marker';
  }
}

Stream<String> asyncGeneratedAwaitForSequentialCatchFinallyAwaitRecovery(
  Stream<String> first,
  Stream<String> second,
  Future<String> recovery,
  Future<String> cleanup,
) async* {
  try {
    await for (final left in first) {
      yield 'base-stream-await-for-sequential-catch-finally-first-$left';
    }
    await for (final right in second) {
      yield 'base-stream-await-for-sequential-catch-finally-second-$right';
    }
  } catch (e) {
    yield 'base-stream-await-for-sequential-catch-finally-caught-$e';
  } finally {
    final marker = await cleanup;
    yield 'base-stream-await-for-sequential-catch-finally-cleanup-$marker';
  }
}

Stream<String> asyncGeneratedAwaitForSequentialBreakContinueFinallyAwaitCleanup(
  Stream<String> first,
  Stream<String> second,
  Future<String> cleanup,
) async* {
  try {
    await for (final left in first) {
      yield 'base-stream-await-for-sequential-break-continue-first-$left';
    }
    await for (final right in second) {
      yield 'base-stream-await-for-sequential-break-continue-second-$right';
    }
  } finally {
    final marker = await cleanup;
    yield 'base-stream-await-for-sequential-break-continue-cleanup-$marker';
  }
}

Stream<String> asyncGeneratedAwaitForNestedInnerCatchOuterFinallyAwaitRecovery(
  Stream<String> outer,
  Stream<String> inner,
  Future<String> recovery,
  Future<String> cleanup,
) async* {
  try {
    await for (final left in outer) {
      await for (final right in inner) {
        yield 'base-stream-await-for-nested-inner-catch-outer-finally-body-$left-$right';
      }
    }
  } catch (e) {
    yield 'base-stream-await-for-nested-inner-catch-outer-finally-caught-$e';
  } finally {
    final marker = await cleanup;
    yield 'base-stream-await-for-nested-inner-catch-outer-finally-cleanup-$marker';
  }
}

Stream<String> asyncGeneratedYieldStarThenAwaitForCatchFinallyAwaitRecovery(
  Stream<String> first,
  Stream<String> second,
  Future<String> recovery,
  Future<String> cleanup,
) async* {
  try {
    yield* first;
    await for (final value in second) {
      yield 'base-stream-yield-star-then-await-for-catch-finally-body-$value';
    }
  } catch (e) {
    yield 'base-stream-yield-star-then-await-for-catch-finally-caught-$e';
  } finally {
    final marker = await cleanup;
    yield 'base-stream-yield-star-then-await-for-catch-finally-cleanup-$marker';
  }
}

Stream<String> asyncGeneratedAwaitForThenYieldStarFinallyAwaitCleanup(
  Stream<String> first,
  Stream<String> second,
  Future<String> cleanup,
) async* {
  try {
    await for (final value in first) {
      yield 'base-stream-await-for-then-yield-star-finally-body-$value';
    }
    yield* second;
  } finally {
    final marker = await cleanup;
    yield 'base-stream-await-for-then-yield-star-finally-cleanup-$marker';
  }
}

Stream<String> asyncGeneratedYieldStarAwaitForNestedCatchFinallyAwaitRecovery(
  Stream<String> first,
  Stream<String> middle,
  Stream<String> inner,
  Future<String> recovery,
  Future<String> cleanup,
) async* {
  try {
    yield* first;
    await for (final center in middle) {
      await for (final right in inner) {
        yield 'base-stream-yield-star-await-for-nested-catch-finally-body-$center-$right';
      }
    }
  } catch (e) {
    yield 'base-stream-yield-star-await-for-nested-catch-finally-caught-$e';
  } finally {
    final marker = await cleanup;
    yield 'base-stream-yield-star-await-for-nested-catch-finally-cleanup-$marker';
  }
}

Stream<String> asyncGeneratedAwaitForSequentialNestedCatchFinallyAwaitRecovery(
  Stream<String> first,
  Stream<String> middle,
  Stream<String> inner,
  Future<String> recovery,
  Future<String> cleanup,
) async* {
  try {
    await for (final left in first) {
      yield 'base-stream-await-for-sequential-nested-catch-finally-first-$left';
    }
    await for (final center in middle) {
      await for (final right in inner) {
        yield 'base-stream-await-for-sequential-nested-catch-finally-inner-$center-$right';
      }
    }
  } catch (e) {
    yield 'base-stream-await-for-sequential-nested-catch-finally-caught-$e';
  } finally {
    final marker = await cleanup;
    yield 'base-stream-await-for-sequential-nested-catch-finally-cleanup-$marker';
  }
}

Stream<String>
asyncGeneratedAwaitForNestedThenYieldStarCatchFinallyAwaitRecovery(
  Stream<String> outer,
  Stream<String> inner,
  Stream<String> tail,
  Future<String> recovery,
  Future<String> cleanup,
) async* {
  try {
    await for (final left in outer) {
      await for (final right in inner) {
        yield 'base-stream-await-for-nested-then-yield-star-body-$left-$right';
      }
    }
    yield* tail;
  } catch (e) {
    yield 'base-stream-await-for-nested-then-yield-star-caught-$e';
  } finally {
    final marker = await cleanup;
    yield 'base-stream-await-for-nested-then-yield-star-cleanup-$marker';
  }
}

Stream<String>
asyncGeneratedYieldStarThenAwaitForThenYieldStarCatchFinallyAwaitRecovery(
  Stream<String> first,
  Stream<String> middle,
  Stream<String> last,
  Future<String> recovery,
  Future<String> cleanup,
) async* {
  try {
    yield* first;
    await for (final value in middle) {
      yield 'base-stream-yield-star-await-for-yield-star-middle-$value';
    }
    yield* last;
  } catch (e) {
    yield 'base-stream-yield-star-await-for-yield-star-caught-$e';
  } finally {
    final marker = await cleanup;
    yield 'base-stream-yield-star-await-for-yield-star-cleanup-$marker';
  }
}

Stream<String>
asyncGeneratedYieldStarNestedAwaitForThenYieldStarCatchFinallyAwaitRecovery(
  Stream<String> first,
  Stream<String> outer,
  Stream<String> inner,
  Stream<String> last,
  Future<String> recovery,
  Future<String> cleanup,
) async* {
  try {
    yield* first;
    await for (final left in outer) {
      await for (final right in inner) {
        yield 'base-stream-yield-star-nested-await-for-yield-star-body-$left-$right';
      }
    }
    yield* last;
  } catch (e) {
    yield 'base-stream-yield-star-nested-await-for-yield-star-caught-$e';
  } finally {
    final marker = await cleanup;
    yield 'base-stream-yield-star-nested-await-for-yield-star-cleanup-$marker';
  }
}

Stream<String> asyncGeneratedAwaitForFinallyAwaitForCleanup(
  Stream<String> body,
  Stream<String> cleanupStream,
) async* {
  try {
    await for (final value in body) {
      yield 'base-stream-await-for-finally-await-for-body-$value';
    }
  } finally {
    await for (final cleanup in cleanupStream) {
      yield 'base-stream-await-for-finally-await-for-cleanup-$cleanup';
    }
  }
}

Stream<String> asyncGeneratedYieldStarFinallyYieldStarCleanup(
  Stream<String> body,
  Stream<String> cleanupStream,
) async* {
  try {
    yield* body;
  } finally {
    yield* cleanupStream;
  }
}

Stream<String> asyncGeneratedAwaitForCatchFinallyAwaitForCleanup(
  Stream<String> body,
  Stream<String> cleanupStream,
  Future<String> recovery,
) async* {
  try {
    await for (final value in body) {
      yield 'base-stream-await-for-catch-finally-await-for-body-$value';
    }
  } catch (e) {
    yield 'base-stream-await-for-catch-finally-await-for-caught-$e';
  } finally {
    await for (final cleanup in cleanupStream) {
      yield 'base-stream-await-for-catch-finally-await-for-cleanup-$cleanup';
    }
  }
}

Stream<String> asyncGeneratedYieldStarAwaitForFinallyYieldStarCleanup(
  Stream<String> first,
  Stream<String> middle,
  Stream<String> cleanupStream,
) async* {
  try {
    yield* first;
    await for (final value in middle) {
      yield 'base-stream-yield-star-await-for-finally-yield-star-middle-$value';
    }
  } finally {
    yield* cleanupStream;
  }
}

Stream<String> asyncGeneratedAwaitForYieldStarFinallyAwaitForCleanup(
  Stream<String> first,
  Stream<String> delegated,
  Stream<String> cleanupStream,
  Future<String> recovery,
) async* {
  try {
    await for (final value in first) {
      if (value == 'skip-await-for-yield-star-finally') continue;
      yield 'base-stream-await-for-yield-star-finally-body-$value';
    }
    yield* delegated;
  } catch (e) {
    final marker = await recovery;
    yield 'base-stream-await-for-yield-star-finally-caught-$marker-$e';
  } finally {
    await for (final cleanup in cleanupStream) {
      if (cleanup == 'stop-await-for-yield-star-finally-cleanup') break;
      yield 'base-stream-await-for-yield-star-finally-cleanup-$cleanup';
    }
  }
}

Stream<String> asyncGeneratedYieldStarFinallyAwaitForYieldStarCleanup(
  Stream<String> body,
  Stream<String> cleanupHead,
  Stream<String> cleanupTail,
  Future<String> cleanup,
) async* {
  try {
    yield 'base-stream-yield-star-finally-await-for-yield-star-head';
    yield* body;
  } finally {
    final marker = await cleanup;
    yield 'base-stream-yield-star-finally-await-for-yield-star-cleanup-$marker';
    await for (final value in cleanupHead) {
      if (value == 'skip-yield-star-finally-await-for-yield-star-cleanup') {
        continue;
      }
      yield 'base-stream-yield-star-finally-await-for-yield-star-middle-$value';
    }
    yield* cleanupTail;
  }
}
