Future<List<String>>
asyncSwitchStatementAwaitScrutineeCollectionRecoveryCleanup(
  Future<String> tierReady,
  Future<bool> enabled,
  Future<String> recovery,
  Future<String> cleanup,
  List<String> extra,
) async {
  var out = <String>['base-async-switch-stmt-collection-head'];
  try {
    out = [...out, 'base-async-switch-stmt-collection-body-${await tierReady}'];
  } catch (e) {
    final marker = await recovery;
    out = [...out, 'base-async-switch-stmt-collection-caught-$marker-$e'];
  } finally {
    final marker = await cleanup;
    out = [...out, 'base-async-switch-stmt-collection-cleanup-$marker'];
  }
  return out;
}

Future<Map<String, String>> asyncSwitchStatementMapRecoveryCleanup(
  String tier,
  Future<bool> enabled,
  Future<String> recovery,
  Future<String> cleanup,
  Map<String, String> extra,
) async {
  var out = <String, String>{'mode': 'base-async-switch-stmt-map-head'};
  try {
    out = {...out, 'tier': 'base-async-switch-stmt-map-$tier'};
  } catch (e) {
    final marker = await recovery;
    out = {...out, 'caught': 'base-async-switch-stmt-map-caught-$marker-$e'};
  } finally {
    final marker = await cleanup;
    out = {...out, 'cleanup': 'base-async-switch-stmt-map-cleanup-$marker'};
  }
  return out;
}
