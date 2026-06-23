Stream<List<String>>
asyncGeneratedNestedAwaitForRecoveryDoubleCleanupSuperChain(
  Stream<String> outer,
  Stream<String> inner,
  Stream<String> recovery,
  Stream<String> cleanup,
  Stream<List<String>> tail,
  String tier,
  List<String> extra,
) async* {
  try {
    await for (final left in outer) {
      await for (final right in inner) {
        yield [
          switch (tier) {
            'gold' ||
            'vip' => 'patched-stream-super-nested-premium-$left-$right',
            _ => 'patched-stream-super-nested-standard-$left-$right',
          },
          for (final item in extra) 'patched-stream-super-nested-extra-$item',
        ];
      }
    }
  } catch (e) {
    await for (final value in recovery) {
      yield ['patched-stream-super-nested-caught-$value-$e'];
    }
  } finally {
    await for (final value in cleanup) {
      yield ['patched-stream-super-nested-cleanup-$value'];
    }
    yield* tail;
  }
}

Stream<Map<String, String>>
asyncGeneratedYieldStarAwaitForMapRecoveryCleanupTailSuperChain(
  Stream<Map<String, String>> first,
  Stream<String> body,
  Stream<Map<String, String>> recovery,
  Stream<String> cleanup,
  Stream<Map<String, String>> tail,
  Map<String, String> labels,
) async* {
  try {
    yield* first;
    await for (final value in body) {
      yield {
        'body': 'patched-stream-super-map-body-$value',
        for (final entry in labels.entries)
          'patched-stream-super-map-label-${entry.key}': entry.value,
      };
    }
  } catch (e) {
    yield {'caught': 'patched-stream-super-map-caught-$e'};
    yield* recovery;
  } finally {
    await for (final value in cleanup) {
      yield {'cleanup': 'patched-stream-super-map-cleanup-$value'};
    }
    yield* tail;
  }
}

Stream<List<String>>
asyncGeneratedWhileYieldStarAwaitForSwitchCleanupSuperChain(
  int limit,
  Stream<List<String>> first,
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
      await for (final values in first) {
        yield values;
      }
      await for (final value in second) {
        yield [
          switch (tier) {
            'gold' || 'vip' => 'patched-stream-super-while-premium-$i-$value',
            _ => 'patched-stream-super-while-standard-$i-$value',
          },
          for (final item in extra) 'patched-stream-super-while-extra-$item',
        ];
      }
    } catch (e) {
      await for (final value in recovery) {
        yield ['patched-stream-super-while-caught-$value-$e'];
      }
    } finally {
      await for (final value in cleanup) {
        yield ['patched-stream-super-while-cleanup-$value'];
      }
    }
  }
}
