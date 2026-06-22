Future<List<String>> asyncAwaitConditionNames(Future<bool> ready) async {
  return [
    'patched-await-condition-head',
    if (await ready)
      'patched-await-condition-live'
    else
      'patched-await-condition-off',
    'patched-await-condition-tail',
  ];
}

Future<List<String>> asyncAwaitConditionDynamicNames(
  Future<bool> ready,
  List<String> extra,
) async {
  return [
    'patched-await-condition-dynamic-head',
    if (await ready)
      'patched-await-condition-dynamic-live'
    else
      'patched-await-condition-dynamic-off',
    ...extra,
  ];
}

Future<List<String>> asyncAwaitConditionRuntimeNames(
  Future<bool> ready,
  List<String> extra,
) async {
  return [
    'patched-await-condition-runtime-head',
    if (await ready)
      'patched-await-condition-runtime-live'
    else
      'patched-await-condition-runtime-off',
    for (final item in extra) item,
  ];
}

Future<List<String>> asyncAwaitConditionDynamicRuntimeNames(
  Future<bool> ready,
  List<String> extra,
  List<String> tail,
) async {
  return [
    'patched-await-condition-chain-head',
    if (await ready)
      'patched-await-condition-chain-live'
    else
      'patched-await-condition-chain-off',
    ...extra,
    for (final item in tail) item,
  ];
}

Future<List<String>> asyncAwaitConditionDynamicRuntimeStaticSpreadNames(
  Future<bool> ready,
  List<String> extra,
  List<String> tail,
) async {
  return [
    'patched-await-condition-chain-static-spread-head',
    if (await ready)
      'patched-await-condition-chain-static-spread-live'
    else
      'patched-await-condition-chain-static-spread-off',
    ...extra,
    for (final item in tail) item,
    ...[
      'patched-await-condition-chain-static-spread-tail-a',
      'patched-await-condition-chain-static-spread-tail-b',
    ],
  ];
}

Future<List<String>> asyncAwaitConditionDynamicRuntimeTailNames(
  Future<bool> ready,
  List<String> extra,
  List<String> tail,
) async {
  return [
    'patched-await-condition-chain-tail-head',
    if (await ready)
      'patched-await-condition-chain-tail-live'
    else
      'patched-await-condition-chain-tail-off',
    ...extra,
    for (final item in tail) item,
    'patched-await-condition-chain-tail-tail',
  ];
}

Future<List<String>> asyncAwaitConditionDynamicRuntimeDynamicNames(
  Future<bool> ready,
  List<String> extra,
  List<String> middle,
  List<String> tail,
) async {
  return [
    'patched-await-condition-chain-dynamic-head',
    if (await ready)
      'patched-await-condition-chain-dynamic-live'
    else
      'patched-await-condition-chain-dynamic-off',
    ...extra,
    for (final item in middle) item,
    ...tail,
  ];
}

Future<List<String>> asyncAwaitConditionDynamicDynamicRuntimeNames(
  Future<bool> ready,
  List<String> extra,
  List<String> middle,
  List<String> tail,
) async {
  return [
    'patched-await-condition-double-dynamic-runtime-head',
    if (await ready)
      'patched-await-condition-double-dynamic-runtime-live'
    else
      'patched-await-condition-double-dynamic-runtime-off',
    ...extra,
    ...middle,
    for (final item in tail) item,
  ];
}

Future<List<String>> asyncAwaitConditionDynamicDynamicDynamicNames(
  Future<bool> ready,
  List<String> extra,
  List<String> middle,
  List<String> tail,
) async {
  return [
    'patched-await-condition-triple-dynamic-head',
    if (await ready)
      'patched-await-condition-triple-dynamic-live'
    else
      'patched-await-condition-triple-dynamic-off',
    ...extra,
    ...middle,
    ...tail,
  ];
}

Future<List<String>> asyncAwaitConditionRuntimeDynamicNames(
  Future<bool> ready,
  List<String> extra,
  List<String> tail,
) async {
  return [
    'patched-await-condition-reverse-chain-head',
    if (await ready)
      'patched-await-condition-reverse-chain-live'
    else
      'patched-await-condition-reverse-chain-off',
    for (final item in extra) item,
    ...tail,
  ];
}

Future<List<String>> asyncAwaitConditionRuntimeDynamicStaticSpreadNames(
  Future<bool> ready,
  List<String> extra,
  List<String> tail,
) async {
  return [
    'patched-await-condition-reverse-chain-static-spread-head',
    if (await ready)
      'patched-await-condition-reverse-chain-static-spread-live'
    else
      'patched-await-condition-reverse-chain-static-spread-off',
    for (final item in extra) item,
    ...tail,
    ...[
      'patched-await-condition-reverse-chain-static-spread-tail-a',
      'patched-await-condition-reverse-chain-static-spread-tail-b',
    ],
  ];
}

Future<List<String>> asyncAwaitConditionRuntimeDynamicTailNames(
  Future<bool> ready,
  List<String> extra,
  List<String> tail,
) async {
  return [
    'patched-await-condition-reverse-chain-tail-head',
    if (await ready)
      'patched-await-condition-reverse-chain-tail-live'
    else
      'patched-await-condition-reverse-chain-tail-off',
    for (final item in extra) item,
    ...tail,
    'patched-await-condition-reverse-chain-tail-tail',
  ];
}

Future<List<String>> asyncAwaitConditionRuntimeDynamicRuntimeNames(
  Future<bool> ready,
  List<String> extra,
  List<String> middle,
  List<String> tail,
) async {
  return [
    'patched-await-condition-reverse-chain-runtime-head',
    if (await ready)
      'patched-await-condition-reverse-chain-runtime-live'
    else
      'patched-await-condition-reverse-chain-runtime-off',
    for (final item in extra) item,
    ...middle,
    for (final item in tail) item,
  ];
}

Future<List<String>> asyncAwaitConditionRuntimeRuntimeDynamicNames(
  Future<bool> ready,
  List<String> extra,
  List<String> middle,
  List<String> tail,
) async {
  return [
    'patched-await-condition-double-runtime-dynamic-head',
    if (await ready)
      'patched-await-condition-double-runtime-dynamic-live'
    else
      'patched-await-condition-double-runtime-dynamic-off',
    for (final item in extra) item,
    for (final item in middle) item,
    ...tail,
  ];
}

Future<List<String>> asyncAwaitConditionRuntimeRuntimeRuntimeNames(
  Future<bool> ready,
  List<String> extra,
  List<String> middle,
  List<String> tail,
) async {
  return [
    'patched-await-condition-triple-runtime-head',
    if (await ready)
      'patched-await-condition-triple-runtime-live'
    else
      'patched-await-condition-triple-runtime-off',
    for (final item in extra) item,
    for (final item in middle) item,
    for (final item in tail) item,
  ];
}

Future<List<String>> asyncAwaitConditionDynamicTailNames(
  Future<bool> ready,
  List<String> extra,
) async {
  return [
    'patched-await-condition-tail-chain-head',
    if (await ready)
      'patched-await-condition-tail-chain-live'
    else
      'patched-await-condition-tail-chain-off',
    ...extra,
    'patched-await-condition-tail-chain-tail',
  ];
}

Future<List<String>> asyncAwaitConditionRuntimeTailNames(
  Future<bool> ready,
  List<String> extra,
) async {
  return [
    'patched-await-condition-runtime-tail-head',
    if (await ready)
      'patched-await-condition-runtime-tail-live'
    else
      'patched-await-condition-runtime-tail-off',
    for (final item in extra) item,
    'patched-await-condition-runtime-tail-tail',
  ];
}

Future<List<String>> asyncAwaitConditionDynamicStaticSpreadNames(
  Future<bool> ready,
  List<String> extra,
) async {
  return [
    'patched-await-condition-static-spread-head',
    if (await ready)
      'patched-await-condition-static-spread-live'
    else
      'patched-await-condition-static-spread-off',
    ...extra,
    ...[
      'patched-await-condition-static-spread-tail-a',
      'patched-await-condition-static-spread-tail-b',
    ],
  ];
}

Future<List<String>> asyncAwaitConditionRuntimeStaticSpreadNames(
  Future<bool> ready,
  List<String> extra,
) async {
  return [
    'patched-await-condition-runtime-static-spread-head',
    if (await ready)
      'patched-await-condition-runtime-static-spread-live'
    else
      'patched-await-condition-runtime-static-spread-off',
    for (final item in extra) item,
    ...[
      'patched-await-condition-runtime-static-spread-tail-a',
      'patched-await-condition-runtime-static-spread-tail-b',
    ],
  ];
}

Future<Map<String, String>> asyncAwaitConditionLabels(
  Future<bool> ready,
) async {
  return {
    'mode': 'patched-await-condition-map',
    if (await ready)
      'state': 'patched-await-condition-live'
    else
      'state': 'patched-await-condition-off',
  };
}

Future<Map<String, String>> asyncAwaitConditionDynamicLabels(
  Future<bool> ready,
  Map<String, String> extra,
) async {
  return {
    'mode': 'patched-await-condition-dynamic-map',
    if (await ready)
      'state': 'patched-await-condition-dynamic-live'
    else
      'state': 'patched-await-condition-dynamic-off',
    ...extra,
  };
}

Future<Map<String, String>> asyncAwaitConditionRuntimeLabels(
  Future<bool> ready,
  Map<String, String> extra,
) async {
  return {
    'mode': 'patched-await-condition-runtime-map',
    if (await ready)
      'state': 'patched-await-condition-runtime-live'
    else
      'state': 'patched-await-condition-runtime-off',
    for (final entry in extra.entries) entry.key: entry.value,
  };
}

Future<Map<String, String>> asyncAwaitConditionDynamicRuntimeLabels(
  Future<bool> ready,
  Map<String, String> extra,
  Map<String, String> tail,
) async {
  return {
    'mode': 'patched-await-condition-chain-map',
    if (await ready)
      'state': 'patched-await-condition-chain-live'
    else
      'state': 'patched-await-condition-chain-off',
    ...extra,
    for (final entry in tail.entries) entry.key: entry.value,
  };
}

Future<Map<String, String>> asyncAwaitConditionDynamicRuntimeStaticSpreadLabels(
  Future<bool> ready,
  Map<String, String> extra,
  Map<String, String> tail,
) async {
  return {
    'mode': 'patched-await-condition-chain-static-spread-map',
    if (await ready)
      'state': 'patched-await-condition-chain-static-spread-live'
    else
      'state': 'patched-await-condition-chain-static-spread-off',
    ...extra,
    for (final entry in tail.entries) entry.key: entry.value,
    ...{'tail': 'patched-await-condition-chain-static-spread-tail'},
  };
}

Future<Map<String, String>> asyncAwaitConditionDynamicRuntimeTailLabels(
  Future<bool> ready,
  Map<String, String> extra,
  Map<String, String> tail,
) async {
  return {
    'mode': 'patched-await-condition-chain-tail-map',
    if (await ready)
      'state': 'patched-await-condition-chain-tail-live'
    else
      'state': 'patched-await-condition-chain-tail-off',
    ...extra,
    for (final entry in tail.entries) entry.key: entry.value,
    'tail': 'patched-await-condition-chain-tail-tail',
  };
}

Future<Map<String, String>> asyncAwaitConditionDynamicRuntimeDynamicLabels(
  Future<bool> ready,
  Map<String, String> extra,
  Map<String, String> middle,
  Map<String, String> tail,
) async {
  return {
    'mode': 'patched-await-condition-chain-dynamic-map',
    if (await ready)
      'state': 'patched-await-condition-chain-dynamic-live'
    else
      'state': 'patched-await-condition-chain-dynamic-off',
    ...extra,
    for (final entry in middle.entries) entry.key: entry.value,
    ...tail,
  };
}

Future<Map<String, String>> asyncAwaitConditionDynamicDynamicRuntimeLabels(
  Future<bool> ready,
  Map<String, String> extra,
  Map<String, String> middle,
  Map<String, String> tail,
) async {
  return {
    'mode': 'patched-await-condition-double-dynamic-runtime-map',
    if (await ready)
      'state': 'patched-await-condition-double-dynamic-runtime-live'
    else
      'state': 'patched-await-condition-double-dynamic-runtime-off',
    ...extra,
    ...middle,
    for (final entry in tail.entries) entry.key: entry.value,
  };
}

Future<Map<String, String>> asyncAwaitConditionDynamicDynamicDynamicLabels(
  Future<bool> ready,
  Map<String, String> extra,
  Map<String, String> middle,
  Map<String, String> tail,
) async {
  return {
    'mode': 'patched-await-condition-triple-dynamic-map',
    if (await ready)
      'state': 'patched-await-condition-triple-dynamic-live'
    else
      'state': 'patched-await-condition-triple-dynamic-off',
    ...extra,
    ...middle,
    ...tail,
  };
}

Future<Map<String, String>> asyncAwaitConditionRuntimeDynamicLabels(
  Future<bool> ready,
  Map<String, String> extra,
  Map<String, String> tail,
) async {
  return {
    'mode': 'patched-await-condition-reverse-chain-map',
    if (await ready)
      'state': 'patched-await-condition-reverse-chain-live'
    else
      'state': 'patched-await-condition-reverse-chain-off',
    for (final entry in extra.entries) entry.key: entry.value,
    ...tail,
  };
}

Future<Map<String, String>> asyncAwaitConditionRuntimeDynamicStaticSpreadLabels(
  Future<bool> ready,
  Map<String, String> extra,
  Map<String, String> tail,
) async {
  return {
    'mode': 'patched-await-condition-reverse-chain-static-spread-map',
    if (await ready)
      'state': 'patched-await-condition-reverse-chain-static-spread-live'
    else
      'state': 'patched-await-condition-reverse-chain-static-spread-off',
    for (final entry in extra.entries) entry.key: entry.value,
    ...tail,
    ...{'tail': 'patched-await-condition-reverse-chain-static-spread-tail'},
  };
}

Future<Map<String, String>> asyncAwaitConditionRuntimeDynamicTailLabels(
  Future<bool> ready,
  Map<String, String> extra,
  Map<String, String> tail,
) async {
  return {
    'mode': 'patched-await-condition-reverse-chain-tail-map',
    if (await ready)
      'state': 'patched-await-condition-reverse-chain-tail-live'
    else
      'state': 'patched-await-condition-reverse-chain-tail-off',
    for (final entry in extra.entries) entry.key: entry.value,
    ...tail,
    'tail': 'patched-await-condition-reverse-chain-tail-tail',
  };
}

Future<Map<String, String>> asyncAwaitConditionRuntimeDynamicRuntimeLabels(
  Future<bool> ready,
  Map<String, String> extra,
  Map<String, String> middle,
  Map<String, String> tail,
) async {
  return {
    'mode': 'patched-await-condition-reverse-chain-runtime-map',
    if (await ready)
      'state': 'patched-await-condition-reverse-chain-runtime-live'
    else
      'state': 'patched-await-condition-reverse-chain-runtime-off',
    for (final entry in extra.entries) entry.key: entry.value,
    ...middle,
    for (final entry in tail.entries) entry.key: entry.value,
  };
}

Future<Map<String, String>> asyncAwaitConditionRuntimeRuntimeDynamicLabels(
  Future<bool> ready,
  Map<String, String> extra,
  Map<String, String> middle,
  Map<String, String> tail,
) async {
  return {
    'mode': 'patched-await-condition-double-runtime-dynamic-map',
    if (await ready)
      'state': 'patched-await-condition-double-runtime-dynamic-live'
    else
      'state': 'patched-await-condition-double-runtime-dynamic-off',
    for (final entry in extra.entries) entry.key: entry.value,
    for (final entry in middle.entries) entry.key: entry.value,
    ...tail,
  };
}

Future<Map<String, String>> asyncAwaitConditionRuntimeRuntimeRuntimeLabels(
  Future<bool> ready,
  Map<String, String> extra,
  Map<String, String> middle,
  Map<String, String> tail,
) async {
  return {
    'mode': 'patched-await-condition-triple-runtime-map',
    if (await ready)
      'state': 'patched-await-condition-triple-runtime-live'
    else
      'state': 'patched-await-condition-triple-runtime-off',
    for (final entry in extra.entries) entry.key: entry.value,
    for (final entry in middle.entries) entry.key: entry.value,
    for (final entry in tail.entries) entry.key: entry.value,
  };
}

Future<Map<String, String>> asyncAwaitConditionDynamicTailLabels(
  Future<bool> ready,
  Map<String, String> extra,
) async {
  return {
    'mode': 'patched-await-condition-tail-chain-map',
    if (await ready)
      'state': 'patched-await-condition-tail-chain-live'
    else
      'state': 'patched-await-condition-tail-chain-off',
    ...extra,
    'tail': 'patched-await-condition-tail-chain-tail',
  };
}

Future<Map<String, String>> asyncAwaitConditionRuntimeTailLabels(
  Future<bool> ready,
  Map<String, String> extra,
) async {
  return {
    'mode': 'patched-await-condition-runtime-tail-map',
    if (await ready)
      'state': 'patched-await-condition-runtime-tail-live'
    else
      'state': 'patched-await-condition-runtime-tail-off',
    for (final entry in extra.entries) entry.key: entry.value,
    'tail': 'patched-await-condition-runtime-tail-tail',
  };
}

Future<Map<String, String>> asyncAwaitConditionDynamicStaticSpreadLabels(
  Future<bool> ready,
  Map<String, String> extra,
) async {
  return {
    'mode': 'patched-await-condition-static-spread-map',
    if (await ready)
      'state': 'patched-await-condition-static-spread-live'
    else
      'state': 'patched-await-condition-static-spread-off',
    ...extra,
    ...{'tail': 'patched-await-condition-static-spread-tail'},
  };
}

Future<Map<String, String>> asyncAwaitConditionRuntimeStaticSpreadLabels(
  Future<bool> ready,
  Map<String, String> extra,
) async {
  return {
    'mode': 'patched-await-condition-runtime-static-spread-map',
    if (await ready)
      'state': 'patched-await-condition-runtime-static-spread-live'
    else
      'state': 'patched-await-condition-runtime-static-spread-off',
    for (final entry in extra.entries) entry.key: entry.value,
    ...{'tail': 'patched-await-condition-runtime-static-spread-tail'},
  };
}
