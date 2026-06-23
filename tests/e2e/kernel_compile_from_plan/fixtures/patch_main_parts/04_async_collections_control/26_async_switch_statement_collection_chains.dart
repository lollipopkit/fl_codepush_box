Future<List<String>>
asyncSwitchStatementAwaitScrutineeCollectionRecoveryCleanup(
  Future<String> tierReady,
  Future<bool> enabled,
  Future<String> recovery,
  Future<String> cleanup,
  List<String> extra,
) async {
  var out = <String>['patched-async-switch-stmt-collection-head'];
  try {
    switch (await tierReady) {
      case 'gold' when !await enabled:
        out = [
          ...out,
          'patched-async-switch-stmt-collection-gold',
          for (final item in extra)
            'patched-async-switch-stmt-collection-extra-$item',
        ];
        break;
      case 'vip' when !await enabled:
        out = [...out, 'patched-async-switch-stmt-collection-vip'];
        break;
      case 'blocked':
        throw 'patched-async-switch-stmt-collection-blocked';
      default:
        out = [...out, 'patched-async-switch-stmt-collection-other'];
    }
  } catch (e) {
    final marker = await recovery;
    out = [...out, 'patched-async-switch-stmt-collection-caught-$marker-$e'];
  } finally {
    final marker = await cleanup;
    out = [...out, 'patched-async-switch-stmt-collection-cleanup-$marker'];
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
  var out = <String, String>{'mode': 'patched-async-switch-stmt-map-head'};
  try {
    switch (tier) {
      case 'gold' when !await enabled:
        out = {
          ...out,
          'tier': 'patched-async-switch-stmt-map-gold',
          for (final entry in extra.entries)
            'patched-async-switch-stmt-map-extra-${entry.key}': entry.value,
        };
        break;
      case 'vip' when !await enabled:
        out = {...out, 'tier': 'patched-async-switch-stmt-map-vip'};
        break;
      case 'blocked':
        throw 'patched-async-switch-stmt-map-blocked';
      default:
        out = {...out, 'tier': 'patched-async-switch-stmt-map-other'};
    }
  } catch (e) {
    final marker = await recovery;
    out = {...out, 'caught': 'patched-async-switch-stmt-map-caught-$marker-$e'};
  } finally {
    final marker = await cleanup;
    out = {...out, 'cleanup': 'patched-async-switch-stmt-map-cleanup-$marker'};
  }
  return out;
}
