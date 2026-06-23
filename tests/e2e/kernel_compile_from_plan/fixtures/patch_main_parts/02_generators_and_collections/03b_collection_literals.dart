List<String> names(bool enabled, bool premium) {
  return [
    'patched',
    ...['spread-a', 'spread-b'],
    for (final value in ['for-a', 'for-b']) value,
    if (enabled) 'live' else 'off',
    if (premium) 'pro',
    'tail',
  ];
}

Future<List<String>> asyncNames(bool enabled, bool premium) async {
  return [
    'patched-async-static',
    ...['async-spread-a', 'async-spread-b'],
    for (final value in ['async-for-a', 'async-for-b']) value,
    if (enabled) 'async-live' else 'async-off',
    if (premium) 'async-pro',
    'async-tail',
  ];
}

Future<List<String>> asyncAwaitThenNames(Future<String> ready) async {
  final value = await ready;
  return ['patched-await-list', value, 'patched-await-tail'];
}

Future<List<String>> asyncAwaitThenConditionalNames(Future<bool> ready) async {
  final enabled = await ready;
  return [
    'patched-await-if-head',
    if (enabled) 'patched-await-if-live' else 'patched-await-if-off',
    'patched-await-if-tail',
  ];
}

Future<List<String>> asyncAwaitThenConditionalDynamicNames(
  Future<bool> ready,
  List<String> extra,
) async {
  final enabled = await ready;
  return [
    'patched-await-if-dynamic-head',
    if (enabled)
      'patched-await-if-dynamic-live'
    else
      'patched-await-if-dynamic-off',
    ...extra,
  ];
}

Future<List<String>> asyncAwaitThenConditionalDynamicTailNames(
  Future<bool> ready,
  List<String> extra,
) async {
  final enabled = await ready;
  return [
    'patched-await-if-dynamic-tail-head',
    if (enabled)
      'patched-await-if-dynamic-tail-live'
    else
      'patched-await-if-dynamic-tail-off',
    ...extra,
    'patched-await-if-dynamic-tail-tail',
  ];
}

Future<List<String>> asyncAwaitThenConditionalDynamicStaticSpreadNames(
  Future<bool> ready,
  List<String> extra,
) async {
  final enabled = await ready;
  return [
    'patched-await-if-dynamic-static-spread-head',
    if (enabled)
      'patched-await-if-dynamic-static-spread-live'
    else
      'patched-await-if-dynamic-static-spread-off',
    ...extra,
    ...[
      'patched-await-if-dynamic-static-spread-tail-a',
      'patched-await-if-dynamic-static-spread-tail-b',
    ],
  ];
}

Future<List<String>> asyncAwaitThenConditionalDynamicRuntimeNames(
  Future<bool> ready,
  List<String> extra,
  List<String> tail,
) async {
  final enabled = await ready;
  return [
    'patched-await-if-dynamic-runtime-head',
    if (enabled)
      'patched-await-if-dynamic-runtime-live'
    else
      'patched-await-if-dynamic-runtime-off',
    ...extra,
    for (final item in tail) item,
  ];
}

Future<List<String>> asyncAwaitThenConditionalDynamicRuntimeTailNames(
  Future<bool> ready,
  List<String> extra,
  List<String> tail,
) async {
  final enabled = await ready;
  return [
    'patched-await-if-dynamic-runtime-tail-head',
    if (enabled)
      'patched-await-if-dynamic-runtime-tail-live'
    else
      'patched-await-if-dynamic-runtime-tail-off',
    ...extra,
    for (final item in tail) item,
    'patched-await-if-dynamic-runtime-tail-tail',
  ];
}

Future<List<String>> asyncAwaitThenConditionalDynamicRuntimeStaticSpreadNames(
  Future<bool> ready,
  List<String> extra,
  List<String> tail,
) async {
  final enabled = await ready;
  return [
    'patched-await-if-dynamic-runtime-static-spread-head',
    if (enabled)
      'patched-await-if-dynamic-runtime-static-spread-live'
    else
      'patched-await-if-dynamic-runtime-static-spread-off',
    ...extra,
    for (final item in tail) item,
    ...[
      'patched-await-if-dynamic-runtime-static-spread-tail-a',
      'patched-await-if-dynamic-runtime-static-spread-tail-b',
    ],
  ];
}

Future<List<String>> asyncAwaitThenConditionalRuntimeNames(
  Future<bool> ready,
  List<String> extra,
) async {
  final enabled = await ready;
  return [
    'patched-await-if-runtime-head',
    if (enabled)
      'patched-await-if-runtime-live'
    else
      'patched-await-if-runtime-off',
    for (final item in extra) item,
  ];
}

Future<List<String>> asyncAwaitThenConditionalRuntimeTailNames(
  Future<bool> ready,
  List<String> extra,
) async {
  final enabled = await ready;
  return [
    'patched-await-if-runtime-tail-head',
    if (enabled)
      'patched-await-if-runtime-tail-live'
    else
      'patched-await-if-runtime-tail-off',
    for (final item in extra) item,
    'patched-await-if-runtime-tail-tail',
  ];
}

Future<List<String>> asyncAwaitThenConditionalRuntimeStaticSpreadNames(
  Future<bool> ready,
  List<String> extra,
) async {
  final enabled = await ready;
  return [
    'patched-await-if-runtime-static-spread-head',
    if (enabled)
      'patched-await-if-runtime-static-spread-live'
    else
      'patched-await-if-runtime-static-spread-off',
    for (final item in extra) item,
    ...[
      'patched-await-if-runtime-static-spread-tail-a',
      'patched-await-if-runtime-static-spread-tail-b',
    ],
  ];
}

Future<List<String>> asyncAwaitThenConditionalRuntimeDynamicNames(
  Future<bool> ready,
  List<String> extra,
  List<String> tail,
) async {
  final enabled = await ready;
  return [
    'patched-await-if-runtime-dynamic-head',
    if (enabled)
      'patched-await-if-runtime-dynamic-live'
    else
      'patched-await-if-runtime-dynamic-off',
    for (final item in extra) item,
    ...tail,
  ];
}

Future<List<String>> asyncAwaitThenConditionalRuntimeDynamicTailNames(
  Future<bool> ready,
  List<String> extra,
  List<String> tail,
) async {
  final enabled = await ready;
  return [
    'patched-await-if-runtime-dynamic-tail-head',
    if (enabled)
      'patched-await-if-runtime-dynamic-tail-live'
    else
      'patched-await-if-runtime-dynamic-tail-off',
    for (final item in extra) item,
    ...tail,
    'patched-await-if-runtime-dynamic-tail-tail',
  ];
}

Future<List<String>> asyncAwaitThenConditionalRuntimeDynamicStaticSpreadNames(
  Future<bool> ready,
  List<String> extra,
  List<String> tail,
) async {
  final enabled = await ready;
  return [
    'patched-await-if-runtime-dynamic-static-spread-head',
    if (enabled)
      'patched-await-if-runtime-dynamic-static-spread-live'
    else
      'patched-await-if-runtime-dynamic-static-spread-off',
    for (final item in extra) item,
    ...tail,
    ...[
      'patched-await-if-runtime-dynamic-static-spread-tail-a',
      'patched-await-if-runtime-dynamic-static-spread-tail-b',
    ],
  ];
}

List<String> dynamicNames(List<String> extra) {
  return ['patched', ...extra];
}

Future<List<String>> asyncDynamicNames(List<String> extra) async {
  return ['patched-async', ...extra];
}

Future<List<String>> asyncAwaitThenDynamicNames(
  Future<String> ready,
  List<String> extra,
) async {
  final value = await ready;
  return ['patched-await-dynamic', ...extra];
}

List<String> runtimeForNames(List<String> extra) {
  return ['patched', for (final value in extra) value];
}

Future<List<String>> asyncRuntimeForNames(List<String> extra) async {
  return ['patched-async-for', for (final value in extra) value];
}

Future<List<String>> asyncAwaitThenRuntimeForNames(
  Future<String> ready,
  List<String> extra,
) async {
  final value = await ready;
  return ['patched-await-runtime-for', for (final item in extra) item];
}

Map<String, String> labels(bool enabled, bool premium) {
  return {
    'mode': 'patched',
    ...{'spread': 'yes'},
    for (final entry in {'for': 'yes'}.entries) entry.key: entry.value,
    if (enabled) 'state': 'live' else 'state': 'off',
    if (premium) 'tier': 'pro',
    'tail': 'done',
  };
}

Future<Map<String, String>> asyncLabels(bool enabled, bool premium) async {
  return {
    'mode': 'patched-async-static',
    ...{'async-spread': 'yes'},
    for (final entry in {'async-for': 'yes'}.entries) entry.key: entry.value,
    if (enabled) 'async-state': 'live' else 'async-state': 'off',
    if (premium) 'async-tier': 'pro',
    'async-tail': 'done',
  };
}

Future<Map<String, String>> asyncAwaitThenLabels(Future<String> ready) async {
  final value = await ready;
  return {'mode': 'patched-await-map', 'value': value};
}

Future<Map<String, String>> asyncAwaitThenConditionalLabels(
  Future<bool> ready,
) async {
  final enabled = await ready;
  return {
    'mode': 'patched-await-if-map',
    if (enabled)
      'state': 'patched-await-if-live'
    else
      'state': 'patched-await-if-off',
    'tail': 'patched-await-if-tail',
  };
}

Future<Map<String, String>> asyncAwaitThenConditionalDynamicLabels(
  Future<bool> ready,
  Map<String, String> extra,
) async {
  final enabled = await ready;
  return {
    'mode': 'patched-await-if-dynamic-map',
    if (enabled)
      'state': 'patched-await-if-dynamic-live'
    else
      'state': 'patched-await-if-dynamic-off',
    ...extra,
  };
}

Future<Map<String, String>> asyncAwaitThenConditionalDynamicTailLabels(
  Future<bool> ready,
  Map<String, String> extra,
) async {
  final enabled = await ready;
  return {
    'mode': 'patched-await-if-dynamic-tail-map',
    if (enabled)
      'state': 'patched-await-if-dynamic-tail-live'
    else
      'state': 'patched-await-if-dynamic-tail-off',
    ...extra,
    'tail': 'patched-await-if-dynamic-tail-tail',
  };
}

Future<Map<String, String>> asyncAwaitThenConditionalDynamicStaticSpreadLabels(
  Future<bool> ready,
  Map<String, String> extra,
) async {
  final enabled = await ready;
  return {
    'mode': 'patched-await-if-dynamic-static-spread-map',
    if (enabled)
      'state': 'patched-await-if-dynamic-static-spread-live'
    else
      'state': 'patched-await-if-dynamic-static-spread-off',
    ...extra,
    ...{'tail': 'patched-await-if-dynamic-static-spread-tail'},
  };
}

Future<Map<String, String>> asyncAwaitThenConditionalDynamicRuntimeLabels(
  Future<bool> ready,
  Map<String, String> extra,
  Map<String, String> tail,
) async {
  final enabled = await ready;
  return {
    'mode': 'patched-await-if-dynamic-runtime-map',
    if (enabled)
      'state': 'patched-await-if-dynamic-runtime-live'
    else
      'state': 'patched-await-if-dynamic-runtime-off',
    ...extra,
    for (final entry in tail.entries) entry.key: entry.value,
  };
}

Future<Map<String, String>> asyncAwaitThenConditionalDynamicRuntimeTailLabels(
  Future<bool> ready,
  Map<String, String> extra,
  Map<String, String> tail,
) async {
  final enabled = await ready;
  return {
    'mode': 'patched-await-if-dynamic-runtime-tail-map',
    if (enabled)
      'state': 'patched-await-if-dynamic-runtime-tail-live'
    else
      'state': 'patched-await-if-dynamic-runtime-tail-off',
    ...extra,
    for (final entry in tail.entries) entry.key: entry.value,
    'tail': 'patched-await-if-dynamic-runtime-tail-tail',
  };
}

Future<Map<String, String>>
asyncAwaitThenConditionalDynamicRuntimeStaticSpreadLabels(
  Future<bool> ready,
  Map<String, String> extra,
  Map<String, String> tail,
) async {
  final enabled = await ready;
  return {
    'mode': 'patched-await-if-dynamic-runtime-static-spread-map',
    if (enabled)
      'state': 'patched-await-if-dynamic-runtime-static-spread-live'
    else
      'state': 'patched-await-if-dynamic-runtime-static-spread-off',
    ...extra,
    for (final entry in tail.entries) entry.key: entry.value,
    ...{'tail': 'patched-await-if-dynamic-runtime-static-spread-tail'},
  };
}

Future<Map<String, String>> asyncAwaitThenConditionalRuntimeLabels(
  Future<bool> ready,
  Map<String, String> extra,
) async {
  final enabled = await ready;
  return {
    'mode': 'patched-await-if-runtime-map',
    if (enabled)
      'state': 'patched-await-if-runtime-live'
    else
      'state': 'patched-await-if-runtime-off',
    for (final entry in extra.entries) entry.key: entry.value,
  };
}

Future<Map<String, String>> asyncAwaitThenConditionalRuntimeTailLabels(
  Future<bool> ready,
  Map<String, String> extra,
) async {
  final enabled = await ready;
  return {
    'mode': 'patched-await-if-runtime-tail-map',
    if (enabled)
      'state': 'patched-await-if-runtime-tail-live'
    else
      'state': 'patched-await-if-runtime-tail-off',
    for (final entry in extra.entries) entry.key: entry.value,
    'tail': 'patched-await-if-runtime-tail-tail',
  };
}

Future<Map<String, String>> asyncAwaitThenConditionalRuntimeStaticSpreadLabels(
  Future<bool> ready,
  Map<String, String> extra,
) async {
  final enabled = await ready;
  return {
    'mode': 'patched-await-if-runtime-static-spread-map',
    if (enabled)
      'state': 'patched-await-if-runtime-static-spread-live'
    else
      'state': 'patched-await-if-runtime-static-spread-off',
    for (final entry in extra.entries) entry.key: entry.value,
    ...{'tail': 'patched-await-if-runtime-static-spread-tail'},
  };
}

Future<Map<String, String>> asyncAwaitThenConditionalRuntimeDynamicLabels(
  Future<bool> ready,
  Map<String, String> extra,
  Map<String, String> tail,
) async {
  final enabled = await ready;
  return {
    'mode': 'patched-await-if-runtime-dynamic-map',
    if (enabled)
      'state': 'patched-await-if-runtime-dynamic-live'
    else
      'state': 'patched-await-if-runtime-dynamic-off',
    for (final entry in extra.entries) entry.key: entry.value,
    ...tail,
  };
}

Future<Map<String, String>> asyncAwaitThenConditionalRuntimeDynamicTailLabels(
  Future<bool> ready,
  Map<String, String> extra,
  Map<String, String> tail,
) async {
  final enabled = await ready;
  return {
    'mode': 'patched-await-if-runtime-dynamic-tail-map',
    if (enabled)
      'state': 'patched-await-if-runtime-dynamic-tail-live'
    else
      'state': 'patched-await-if-runtime-dynamic-tail-off',
    for (final entry in extra.entries) entry.key: entry.value,
    ...tail,
    'tail': 'patched-await-if-runtime-dynamic-tail-tail',
  };
}

Future<Map<String, String>>
asyncAwaitThenConditionalRuntimeDynamicStaticSpreadLabels(
  Future<bool> ready,
  Map<String, String> extra,
  Map<String, String> tail,
) async {
  final enabled = await ready;
  return {
    'mode': 'patched-await-if-runtime-dynamic-static-spread-map',
    if (enabled)
      'state': 'patched-await-if-runtime-dynamic-static-spread-live'
    else
      'state': 'patched-await-if-runtime-dynamic-static-spread-off',
    for (final entry in extra.entries) entry.key: entry.value,
    ...tail,
    ...{'tail': 'patched-await-if-runtime-dynamic-static-spread-tail'},
  };
}

Map<String, String> dynamicLabels(Map<String, String> extra) {
  return {'mode': 'patched', ...extra};
}

Future<Map<String, String>> asyncDynamicLabels(
  Map<String, String> extra,
) async {
  return {'mode': 'patched-async', ...extra};
}

Future<Map<String, String>> asyncAwaitThenDynamicLabels(
  Future<String> ready,
  Map<String, String> extra,
) async {
  final value = await ready;
  return {'mode': 'patched-await-dynamic-map', ...extra};
}

Map<String, String> runtimeForLabels(Map<String, String> extra) {
  return {
    'mode': 'patched',
    for (final entry in extra.entries) entry.key: entry.value,
  };
}

Future<Map<String, String>> asyncRuntimeForLabels(
  Map<String, String> extra,
) async {
  return {
    'mode': 'patched-async-for',
    for (final entry in extra.entries) entry.key: entry.value,
  };
}

Future<Map<String, String>> asyncAwaitThenRuntimeForLabels(
  Future<String> ready,
  Map<String, String> extra,
) async {
  final value = await ready;
  return {
    'mode': 'patched-await-runtime-for',
    for (final entry in extra.entries) entry.key: entry.value,
  };
}

String chooseLabel(bool enabled) {
  return enabled ? 'patched-live' : 'patched-off';
}

Future<String> asyncAwaitThenChooseLabel(Future<bool> ready) async {
  final enabled = await ready;
  return enabled ? 'patched-await-live' : 'patched-await-off';
}

bool isKnown(Object value) {
  return value is String;
}

bool isUser(Object value) {
  return value is User;
}

bool isStringList(Object value) {
  return value is List<String>;
}

Object asStringList(Object value) {
  return value as List<String>;
}

Future<bool> asyncIsStringList(Object value) async {
  return value is List<String>;
}

Future<Object> asyncAsStringList(Object value) async {
  return value as List<String>;
}

Future<String Function()> asyncFutureCallbackTypeArg() async {
  return () => 'unsupported-future-callback';
}

Future<(String, int)> asyncFutureRecordTypeArg() async {
  return ('unsupported-future-record', 1);
}

bool isCallable(Object value) {
  return value is String Function();
}

bool isRecord(Object value) {
  return value is (String, int);
}

double mainValue() {
  return helper() + 1.5 + 1.5;
}

void main() {
  mainValue();
  helper();
}
