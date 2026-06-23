Stream<List<String>>
asyncGeneratedStreamGuardedContinueBreakRecoveryCleanupSuperChain(
  Stream<String> body,
  Stream<String> recovery,
  Stream<String> cleanup,
  String tier,
  List<String> extra,
) async* {
  try {
    await for (final value in body) {
      if (value == 'skip-guarded-super') continue;
      if (value == 'stop-guarded-super') break;
      yield [
        switch (tier) {
          'gold' || 'vip' => 'patched-stream-guarded-super-premium-$value',
          _ => 'patched-stream-guarded-super-standard-$value',
        },
        for (final item in extra) 'patched-stream-guarded-super-extra-$item',
      ];
    }
  } catch (e) {
    await for (final value in recovery) {
      yield ['patched-stream-guarded-super-caught-$value-$e'];
    }
  } finally {
    await for (final value in cleanup) {
      yield ['patched-stream-guarded-super-cleanup-$value'];
    }
  }
}

Stream<Map<String, String>>
asyncGeneratedNestedStreamGuardedRecoveryCleanupSuperChain(
  Stream<String> outer,
  Stream<String> inner,
  Stream<Map<String, String>> recovery,
  Stream<Map<String, String>> cleanup,
  String tier,
  Map<String, String> labels,
) async* {
  try {
    await for (final left in outer) {
      await for (final right in inner) {
        if (right == 'skip-nested-guarded-super') continue;
        if (right == 'stop-nested-guarded-super') break;
        yield {
          'body': switch (tier) {
            'gold' ||
            'vip' => 'patched-stream-nested-guarded-super-premium-$left-$right',
            _ => 'patched-stream-nested-guarded-super-standard-$left-$right',
          },
          for (final entry in labels.entries)
            'patched-stream-nested-guarded-super-${entry.key}': entry.value,
        };
      }
    }
  } catch (e) {
    yield {'caught': 'patched-stream-nested-guarded-super-caught-$e'};
    yield* recovery;
  } finally {
    yield* cleanup;
  }
}

Stream<List<String>> asyncGeneratedWhileStreamGuardedDoubleCleanupSuperChain(
  int limit,
  Stream<String> first,
  Stream<String> second,
  Stream<String> recovery,
  Stream<String> cleanup,
  String tier,
  List<String> extra,
) async* {
  var i = 0;
  while (i < limit) {
    try {
      i = i + 1;
      await for (final left in first) {
        if (left == 'skip-while-guarded-super') continue;
        yield ['patched-stream-while-guarded-super-first-$i-$left'];
      }
      await for (final right in second) {
        if (right == 'stop-while-guarded-super') break;
        yield [
          switch (tier) {
            'gold' ||
            'vip' => 'patched-stream-while-guarded-super-premium-$i-$right',
            _ => 'patched-stream-while-guarded-super-standard-$i-$right',
          },
          for (final item in extra)
            'patched-stream-while-guarded-super-extra-$item',
        ];
      }
    } catch (e) {
      await for (final value in recovery) {
        yield ['patched-stream-while-guarded-super-caught-$value-$e'];
      }
    } finally {
      await for (final value in cleanup) {
        yield ['patched-stream-while-guarded-super-cleanup-$value'];
      }
    }
  }
}
