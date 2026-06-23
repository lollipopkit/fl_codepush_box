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
      yield {'tier': 'base-stream-guarded-switch-stmt-map-$value'};
    }
  } catch (e) {
    final marker = await recovery;
    yield {'caught': 'base-stream-guarded-switch-stmt-map-caught-$marker-$e'};
  } finally {
    final marker = await cleanup;
    yield {'cleanup': 'base-stream-guarded-switch-stmt-map-cleanup-$marker'};
  }
}
