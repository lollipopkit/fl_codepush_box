String syncSwitchLabel(String tier) {
  return switch (tier) {
    'gold' => 'patched-switch-gold',
    'silver' => 'patched-switch-silver',
    _ => 'patched-switch-other',
  };
}

String syncSwitchMultiValueLabel(String tier) {
  return switch (tier) {
    'gold' || 'vip' => 'patched-switch-premium',
    'trial' || 'guest' => 'patched-switch-limited',
    _ => 'patched-switch-standard',
  };
}

Future<String> asyncSwitchLabel(String tier) async {
  return switch (tier) {
    'gold' => 'patched-async-switch-gold',
    'silver' => 'patched-async-switch-silver',
    _ => 'patched-async-switch-other',
  };
}

Future<String> asyncSwitchMultiValueLabel(String tier) async {
  return switch (tier) {
    'gold' || 'vip' => 'patched-async-switch-premium',
    'trial' || 'guest' => 'patched-async-switch-limited',
    _ => 'patched-async-switch-standard',
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

Future<String> asyncAwaitThenSwitchMultiValueLabel(Future<String> ready) async {
  final tier = await ready;
  return switch (tier) {
    'gold' || 'vip' => 'patched-await-switch-premium',
    'trial' || 'guest' => 'patched-await-switch-limited',
    _ => 'patched-await-switch-standard',
  };
}

int syncSwitchScore(int code) {
  return switch (code) {
    7 => 70,
    9 => 90,
    _ => 10,
  };
}

int syncSwitchMultiValueScore(int code) {
  return switch (code) {
    7 || 8 => 80,
    9 || 10 => 100,
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
