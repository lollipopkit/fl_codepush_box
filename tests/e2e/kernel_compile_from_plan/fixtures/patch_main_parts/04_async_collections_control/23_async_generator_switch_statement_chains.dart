Stream<Map<String, String>>
asyncGeneratedGuardedSwitchStatementMapRecoveryCleanup(
  Stream<String> body,
  String tier,
  Future<bool> enabled,
  Future<String> recovery,
  Future<String> cleanup,
  Map<String, String> extra,
) async* {
  try {
    await for (final value in body) {
      switch (tier) {
        case 'gold' when !await enabled:
          yield {
            'tier': 'patched-stream-guarded-switch-stmt-map-gold-$value',
            for (final entry in extra.entries)
              'patched-stream-guarded-switch-stmt-map-extra-${entry.key}':
                  entry.value,
          };
          break;
        case 'blocked':
          throw 'patched-stream-guarded-switch-stmt-map-blocked';
        case 'vip' when !await enabled:
          yield {
            'tier': 'patched-stream-guarded-switch-stmt-map-vip-$value',
            for (final entry in extra.entries)
              'patched-stream-guarded-switch-stmt-map-extra-${entry.key}':
                  entry.value,
          };
          break;
        default:
          yield {'tier': 'patched-stream-guarded-switch-stmt-map-other-$value'};
      }
    }
  } catch (e) {
    final marker = await recovery;
    yield {
      'caught': 'patched-stream-guarded-switch-stmt-map-caught-$marker-$e',
    };
  } finally {
    final marker = await cleanup;
    yield {'cleanup': 'patched-stream-guarded-switch-stmt-map-cleanup-$marker'};
  }
}
