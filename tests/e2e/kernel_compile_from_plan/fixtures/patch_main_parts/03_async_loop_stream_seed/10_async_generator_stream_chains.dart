Stream<String> asyncGeneratedYieldStarNestedCatchFinallyAwaitRecovery(
  Stream<String> first,
  Stream<String> second,
  Future<String> recovery,
  Future<String> cleanup,
) async* {
  try {
    try {
      yield* first;
      try {
        yield* second;
      } catch (e) {
        final marker = await recovery;
        yield 'patched-stream-yield-star-nested-catch-finally-inner-$marker-$e';
      }
    } catch (e) {
      final marker = await recovery;
      yield 'patched-stream-yield-star-nested-catch-finally-outer-$marker-$e';
    }
  } finally {
    final marker = await cleanup;
    yield 'patched-stream-yield-star-nested-catch-finally-cleanup-$marker';
  }
}

Stream<String> asyncGeneratedYieldStarNestedFinallyAwaitCleanup(
  Stream<String> first,
  Stream<String> second,
  Future<String> cleanup,
) async* {
  try {
    yield* first;
    try {
      yield* second;
    } finally {
      final marker = await cleanup;
      yield 'patched-stream-yield-star-nested-finally-inner-cleanup-$marker';
    }
  } finally {
    final marker = await cleanup;
    yield 'patched-stream-yield-star-nested-finally-outer-cleanup-$marker';
  }
}

Stream<String> asyncGeneratedAwaitForNestedCatchFinallyAwaitRecovery(
  Stream<String> outer,
  Stream<String> inner,
  Future<String> recovery,
  Future<String> cleanup,
) async* {
  try {
    try {
      await for (final left in outer) {
        await for (final right in inner) {
          yield 'patched-stream-await-for-nested-catch-finally-await-body-$left-$right';
        }
      }
    } catch (e) {
      final marker = await recovery;
      yield 'patched-stream-await-for-nested-catch-finally-await-caught-$marker-$e';
    }
  } finally {
    final marker = await cleanup;
    yield 'patched-stream-await-for-nested-catch-finally-await-cleanup-$marker';
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
    try {
      await for (final left in outer) {
        if (left == 'skip') continue;
        await for (final center in middle) {
          if (center == 'stop-middle') break;
          await for (final right in inner) {
            yield 'patched-stream-await-for-triple-nested-catch-finally-await-body-$left-$center-$right';
          }
        }
      }
    } catch (e) {
      final marker = await recovery;
      yield 'patched-stream-await-for-triple-nested-catch-finally-await-caught-$marker-$e';
    }
  } finally {
    final marker = await cleanup;
    yield 'patched-stream-await-for-triple-nested-catch-finally-await-cleanup-$marker';
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
    try {
      yield* first;
      try {
        yield* second;
        yield* third;
      } catch (e) {
        final marker = await recovery;
        yield 'patched-stream-yield-star-triple-nested-catch-finally-inner-$marker-$e';
      }
    } catch (e) {
      final marker = await recovery;
      yield 'patched-stream-yield-star-triple-nested-catch-finally-outer-$marker-$e';
    }
  } finally {
    final marker = await cleanup;
    yield 'patched-stream-yield-star-triple-nested-catch-finally-cleanup-$marker';
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
    try {
      yield* second;
      yield* third;
    } finally {
      final marker = await cleanup;
      yield 'patched-stream-yield-star-triple-nested-finally-inner-cleanup-$marker';
    }
  } finally {
    final marker = await cleanup;
    yield 'patched-stream-yield-star-triple-nested-finally-outer-cleanup-$marker';
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
    try {
      await for (final left in outer) {
        if (left == 'skip') continue;
        await for (final right in inner) {
          if (right == 'stop') break;
          yield 'patched-stream-await-for-nested-break-continue-catch-finally-await-body-$left-$right';
        }
      }
    } catch (e) {
      final marker = await recovery;
      yield 'patched-stream-await-for-nested-break-continue-catch-finally-await-caught-$marker-$e';
    }
  } finally {
    final marker = await cleanup;
    yield 'patched-stream-await-for-nested-break-continue-catch-finally-await-cleanup-$marker';
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
      if (left == 'skip') continue;
      await for (final center in middle) {
        if (center == 'stop-middle') break;
        await for (final right in inner) {
          yield 'patched-stream-await-for-triple-nested-finally-await-body-$left-$center-$right';
        }
      }
    }
  } finally {
    final marker = await cleanup;
    yield 'patched-stream-await-for-triple-nested-finally-await-cleanup-$marker';
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
      yield 'patched-stream-await-for-sequential-catch-finally-first-$left';
    }
    await for (final right in second) {
      yield 'patched-stream-await-for-sequential-catch-finally-second-$right';
    }
  } catch (e) {
    final marker = await recovery;
    yield 'patched-stream-await-for-sequential-catch-finally-caught-$marker-$e';
  } finally {
    final marker = await cleanup;
    yield 'patched-stream-await-for-sequential-catch-finally-cleanup-$marker';
  }
}

Stream<String> asyncGeneratedAwaitForSequentialBreakContinueFinallyAwaitCleanup(
  Stream<String> first,
  Stream<String> second,
  Future<String> cleanup,
) async* {
  try {
    await for (final left in first) {
      if (left == 'skip-first') continue;
      yield 'patched-stream-await-for-sequential-break-continue-first-$left';
    }
    await for (final right in second) {
      if (right == 'stop-second') break;
      yield 'patched-stream-await-for-sequential-break-continue-second-$right';
    }
  } finally {
    final marker = await cleanup;
    yield 'patched-stream-await-for-sequential-break-continue-cleanup-$marker';
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
      try {
        await for (final right in inner) {
          if (right == 'stop-inner') break;
          yield 'patched-stream-await-for-nested-inner-catch-outer-finally-body-$left-$right';
        }
      } catch (e) {
        final marker = await recovery;
        yield 'patched-stream-await-for-nested-inner-catch-outer-finally-inner-caught-$marker-$e';
      }
    }
  } finally {
    final marker = await cleanup;
    yield 'patched-stream-await-for-nested-inner-catch-outer-finally-cleanup-$marker';
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
      if (value == 'skip-second') continue;
      yield 'patched-stream-yield-star-then-await-for-catch-finally-body-$value';
    }
  } catch (e) {
    final marker = await recovery;
    yield 'patched-stream-yield-star-then-await-for-catch-finally-caught-$marker-$e';
  } finally {
    final marker = await cleanup;
    yield 'patched-stream-yield-star-then-await-for-catch-finally-cleanup-$marker';
  }
}

Stream<String> asyncGeneratedAwaitForThenYieldStarFinallyAwaitCleanup(
  Stream<String> first,
  Stream<String> second,
  Future<String> cleanup,
) async* {
  try {
    await for (final value in first) {
      if (value == 'skip-first') continue;
      yield 'patched-stream-await-for-then-yield-star-finally-body-$value';
    }
    yield* second;
  } finally {
    final marker = await cleanup;
    yield 'patched-stream-await-for-then-yield-star-finally-cleanup-$marker';
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
      if (center == 'skip-middle') continue;
      await for (final right in inner) {
        if (right == 'stop-inner') break;
        yield 'patched-stream-yield-star-await-for-nested-catch-finally-body-$center-$right';
      }
    }
  } catch (e) {
    final marker = await recovery;
    yield 'patched-stream-yield-star-await-for-nested-catch-finally-caught-$marker-$e';
  } finally {
    final marker = await cleanup;
    yield 'patched-stream-yield-star-await-for-nested-catch-finally-cleanup-$marker';
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
      if (left == 'skip-first-deep') continue;
      yield 'patched-stream-await-for-sequential-nested-catch-finally-first-$left';
    }
    await for (final center in middle) {
      if (center == 'stop-middle-deep') break;
      await for (final right in inner) {
        yield 'patched-stream-await-for-sequential-nested-catch-finally-inner-$center-$right';
      }
    }
  } catch (e) {
    final marker = await recovery;
    yield 'patched-stream-await-for-sequential-nested-catch-finally-caught-$marker-$e';
  } finally {
    final marker = await cleanup;
    yield 'patched-stream-await-for-sequential-nested-catch-finally-cleanup-$marker';
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
        if (right == 'stop-nested-tail') break;
        yield 'patched-stream-await-for-nested-then-yield-star-body-$left-$right';
      }
    }
    yield* tail;
  } catch (e) {
    final marker = await recovery;
    yield 'patched-stream-await-for-nested-then-yield-star-caught-$marker-$e';
  } finally {
    final marker = await cleanup;
    yield 'patched-stream-await-for-nested-then-yield-star-cleanup-$marker';
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
      if (value == 'skip-middle-deep') continue;
      yield 'patched-stream-yield-star-await-for-yield-star-middle-$value';
    }
    yield* last;
  } catch (e) {
    final marker = await recovery;
    yield 'patched-stream-yield-star-await-for-yield-star-caught-$marker-$e';
  } finally {
    final marker = await cleanup;
    yield 'patched-stream-yield-star-await-for-yield-star-cleanup-$marker';
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
      if (left == 'skip-outer-deep') continue;
      await for (final right in inner) {
        if (right == 'stop-inner-deep') break;
        yield 'patched-stream-yield-star-nested-await-for-yield-star-body-$left-$right';
      }
    }
    yield* last;
  } catch (e) {
    final marker = await recovery;
    yield 'patched-stream-yield-star-nested-await-for-yield-star-caught-$marker-$e';
  } finally {
    final marker = await cleanup;
    yield 'patched-stream-yield-star-nested-await-for-yield-star-cleanup-$marker';
  }
}

Stream<String> asyncGeneratedAwaitForFinallyAwaitForCleanup(
  Stream<String> body,
  Stream<String> cleanupStream,
) async* {
  try {
    await for (final value in body) {
      if (value == 'skip-body-finally') continue;
      yield 'patched-stream-await-for-finally-await-for-body-$value';
    }
  } finally {
    await for (final cleanup in cleanupStream) {
      yield 'patched-stream-await-for-finally-await-for-cleanup-$cleanup';
    }
  }
}

Stream<String> asyncGeneratedYieldStarFinallyYieldStarCleanup(
  Stream<String> body,
  Stream<String> cleanupStream,
) async* {
  try {
    yield 'patched-stream-yield-star-finally-yield-star-head';
    yield* body;
  } finally {
    yield 'patched-stream-yield-star-finally-yield-star-cleanup-head';
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
      if (value == 'stop-body-finally') break;
      yield 'patched-stream-await-for-catch-finally-await-for-body-$value';
    }
  } catch (e) {
    final marker = await recovery;
    yield 'patched-stream-await-for-catch-finally-await-for-caught-$marker-$e';
  } finally {
    await for (final cleanup in cleanupStream) {
      yield 'patched-stream-await-for-catch-finally-await-for-cleanup-$cleanup';
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
      if (value == 'skip-middle-finally') continue;
      yield 'patched-stream-yield-star-await-for-finally-yield-star-middle-$value';
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
      yield 'patched-stream-await-for-yield-star-finally-body-$value';
    }
    yield* delegated;
  } catch (e) {
    final marker = await recovery;
    yield 'patched-stream-await-for-yield-star-finally-caught-$marker-$e';
  } finally {
    await for (final cleanup in cleanupStream) {
      if (cleanup == 'stop-await-for-yield-star-finally-cleanup') break;
      yield 'patched-stream-await-for-yield-star-finally-cleanup-$cleanup';
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
    yield 'patched-stream-yield-star-finally-await-for-yield-star-head';
    yield* body;
  } finally {
    final marker = await cleanup;
    yield 'patched-stream-yield-star-finally-await-for-yield-star-cleanup-$marker';
    await for (final value in cleanupHead) {
      if (value == 'skip-yield-star-finally-await-for-yield-star-cleanup') {
        continue;
      }
      yield 'patched-stream-yield-star-finally-await-for-yield-star-middle-$value';
    }
    yield* cleanupTail;
  }
}
