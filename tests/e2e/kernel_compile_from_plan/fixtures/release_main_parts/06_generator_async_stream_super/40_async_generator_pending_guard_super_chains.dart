Stream<List<String>>
asyncGeneratedStreamPendingContinueRecoveryCleanupSuperChain(
  Stream<String> body,
  Stream<String> recovery,
  Stream<String> cleanup,
  Future<bool> skip,
  String tier,
  List<String> extra,
) async* {
  try {
    await for (final value in body) {
      if (await skip) continue;
      yield [
        switch (tier) {
          'gold' || 'vip' => 'release-stream-pending-continue-premium-$value',
          _ => 'release-stream-pending-continue-standard-$value',
        },
        for (final item in extra) 'release-stream-pending-continue-extra-$item',
      ];
    }
  } catch (e) {
    await for (final value in recovery) {
      yield ['release-stream-pending-continue-caught-$value-$e'];
    }
  } finally {
    await for (final value in cleanup) {
      yield ['release-stream-pending-continue-cleanup-$value'];
    }
  }
}

Stream<Map<String, String>>
asyncGeneratedStreamPendingBreakRecoveryCleanupSuperChain(
  Stream<String> body,
  Stream<Map<String, String>> recovery,
  Stream<Map<String, String>> cleanup,
  Future<bool> stop,
  String tier,
  Map<String, String> labels,
) async* {
  try {
    await for (final value in body) {
      if (await stop) break;
      yield {
        'body': switch (tier) {
          'gold' || 'vip' => 'release-stream-pending-break-premium-$value',
          _ => 'release-stream-pending-break-standard-$value',
        },
        for (final entry in labels.entries)
          'release-stream-pending-break-${entry.key}': entry.value,
      };
    }
  } catch (e) {
    yield {'caught': 'release-stream-pending-break-caught-$e'};
    yield* recovery;
  } finally {
    yield* cleanup;
  }
}

Stream<List<String>> asyncGeneratedNestedStreamPendingGuardSuperChain(
  Stream<String> outer,
  Stream<String> inner,
  Stream<String> recovery,
  Stream<String> cleanup,
  Future<bool> skip,
  Future<bool> stop,
  String tier,
  List<String> extra,
) async* {
  try {
    await for (final left in outer) {
      await for (final right in inner) {
        if (await skip) continue;
        yield [
          switch (tier) {
            'gold' ||
            'vip' => 'release-stream-pending-nested-premium-$left-$right',
            _ => 'release-stream-pending-nested-standard-$left-$right',
          },
          for (final item in extra) 'release-stream-pending-nested-extra-$item',
        ];
      }
      await for (final marker in inner) {
        if (await stop) break;
        yield ['release-stream-pending-nested-tail-$left-$marker'];
      }
    }
  } catch (e) {
    await for (final value in recovery) {
      yield ['release-stream-pending-nested-caught-$value-$e'];
    }
  } finally {
    await for (final value in cleanup) {
      yield ['release-stream-pending-nested-cleanup-$value'];
    }
  }
}
