String syncSwitchLabel(String tier) {
  return tier == 'gold' ? 'base-switch-gold' : 'base-switch-other';
}

Future<String> asyncSwitchLabel(String tier) async {
  return tier == 'gold' ? 'base-async-switch-gold' : 'base-async-switch-other';
}

Future<String> asyncAwaitThenSwitchLabel(Future<String> ready) async {
  final tier = await ready;
  return tier == 'gold' ? 'base-await-switch-gold' : 'base-await-switch-other';
}

int syncSwitchScore(int code) {
  return code == 7 ? 70 : 10;
}

List<String> switchListNames(String tier) {
  return ['base-switch-list-head', tier, 'base-switch-list-tail'];
}

Map<String, String> switchMapLabels(int code) {
  return {'state': 'base-switch-map-$code'};
}

String unchangedGuardedSwitchLabel(String tier, bool enabled) {
  return switch (tier) {
    'gold' when enabled => 'guarded-switch-gold',
    _ => 'guarded-switch-other',
  };
}
