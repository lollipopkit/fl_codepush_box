String syncSwitchLabel(String tier) {
  return switch (tier) {
    'gold' => 'patched-switch-gold',
    'silver' => 'patched-switch-silver',
    _ => 'patched-switch-other',
  };
}

Future<String> asyncSwitchLabel(String tier) async {
  return switch (tier) {
    'gold' => 'patched-async-switch-gold',
    'silver' => 'patched-async-switch-silver',
    _ => 'patched-async-switch-other',
  };
}

Future<String> asyncAwaitThenSwitchLabel(Future<String> ready) async {
  final tier = await ready;
  return switch (tier) {
    'gold' => 'patched-await-switch-gold',
    'silver' => 'patched-await-switch-silver',
    _ => 'patched-await-switch-other',
  };
}

int syncSwitchScore(int code) {
  return switch (code) {
    7 => 70,
    9 => 90,
    _ => 10,
  };
}

List<String> switchListNames(String tier) {
  return [
    'patched-switch-list-head',
    switch (tier) {
      'gold' => 'patched-switch-list-gold',
      'silver' => 'patched-switch-list-silver',
      _ => 'patched-switch-list-other',
    },
    'patched-switch-list-tail',
  ];
}

Map<String, String> switchMapLabels(int code) {
  return {
    'mode': 'patched-switch-map',
    'state': switch (code) {
      7 => 'patched-switch-map-seven',
      9 => 'patched-switch-map-nine',
      _ => 'patched-switch-map-other',
    },
  };
}

String unchangedGuardedSwitchLabel(String tier, bool enabled) {
  return switch (tier) {
    'gold' when enabled => 'guarded-switch-gold',
    _ => 'guarded-switch-other',
  };
}
