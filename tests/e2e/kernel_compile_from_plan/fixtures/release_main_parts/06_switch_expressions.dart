String syncSwitchLabel(String tier) {
  return tier == 'gold' ? 'base-switch-gold' : 'base-switch-other';
}

String syncSwitchMultiValueLabel(String tier) {
  return tier == 'gold' ? 'base-switch-premium' : 'base-switch-standard';
}

Future<String> asyncSwitchLabel(String tier) async {
  return tier == 'gold' ? 'base-async-switch-gold' : 'base-async-switch-other';
}

Future<String> asyncSwitchMultiValueLabel(String tier) async {
  return tier == 'gold'
      ? 'base-async-switch-premium'
      : 'base-async-switch-standard';
}

Future<String> asyncAwaitThenSwitchLabel(Future<String> ready) async {
  final tier = await ready;
  return tier == 'gold' ? 'base-await-switch-gold' : 'base-await-switch-other';
}

Future<String> asyncAwaitThenSwitchMultiValueLabel(Future<String> ready) async {
  final tier = await ready;
  return tier == 'gold'
      ? 'base-await-switch-premium'
      : 'base-await-switch-standard';
}

int syncSwitchScore(int code) {
  return code == 7 ? 70 : 10;
}

int syncSwitchMultiValueScore(int code) {
  return code == 7 ? 80 : 10;
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
