List<String> names(bool enabled, bool premium) {
  return ['base'];
}

Future<List<String>> asyncNames(bool enabled, bool premium) async {
  return ['base-async'];
}

Future<List<String>> asyncAwaitThenNames(Future<String> ready) async {
  final value = await ready;
  return ['base-await-list', value, 'base-await-tail'];
}

Future<List<String>> asyncAwaitThenConditionalNames(Future<bool> ready) async {
  final enabled = await ready;
  return enabled ? ['base-await-if-live'] : ['base-await-if-off'];
}

Future<List<String>> asyncAwaitThenConditionalDynamicNames(
  Future<bool> ready,
  List<String> extra,
) async {
  final enabled = await ready;
  return enabled ? ['base-await-if-live', ...extra] : ['base-await-if-off'];
}

Future<List<String>> asyncAwaitThenConditionalDynamicTailNames(
  Future<bool> ready,
  List<String> extra,
) async {
  final enabled = await ready;
  return enabled
      ? ['base-await-if-live', ...extra, 'base-await-if-tail']
      : ['base-await-if-off', ...extra, 'base-await-if-tail'];
}

Future<List<String>> asyncAwaitThenConditionalDynamicStaticSpreadNames(
  Future<bool> ready,
  List<String> extra,
) async {
  final enabled = await ready;
  return enabled
      ? [
          'base-await-if-live',
          ...extra,
          ...['base-await-if-spread-a', 'base-await-if-spread-b'],
        ]
      : [
          'base-await-if-off',
          ...extra,
          ...['base-await-if-spread-a', 'base-await-if-spread-b'],
        ];
}

Future<List<String>> asyncAwaitThenConditionalDynamicRuntimeNames(
  Future<bool> ready,
  List<String> extra,
  List<String> tail,
) async {
  final enabled = await ready;
  return enabled
      ? ['base-await-if-live', ...extra, for (final item in tail) item]
      : ['base-await-if-off', ...extra, for (final item in tail) item];
}

Future<List<String>> asyncAwaitThenConditionalDynamicRuntimeTailNames(
  Future<bool> ready,
  List<String> extra,
  List<String> tail,
) async {
  final enabled = await ready;
  return enabled
      ? [
          'base-await-if-live',
          ...extra,
          for (final item in tail) item,
          'base-await-if-tail',
        ]
      : [
          'base-await-if-off',
          ...extra,
          for (final item in tail) item,
          'base-await-if-tail',
        ];
}

Future<List<String>> asyncAwaitThenConditionalDynamicRuntimeStaticSpreadNames(
  Future<bool> ready,
  List<String> extra,
  List<String> tail,
) async {
  final enabled = await ready;
  return enabled
      ? [
          'base-await-if-live',
          ...extra,
          for (final item in tail) item,
          ...['base-await-if-spread-a', 'base-await-if-spread-b'],
        ]
      : [
          'base-await-if-off',
          ...extra,
          for (final item in tail) item,
          ...['base-await-if-spread-a', 'base-await-if-spread-b'],
        ];
}

Future<List<String>> asyncAwaitThenConditionalRuntimeNames(
  Future<bool> ready,
  List<String> extra,
) async {
  final enabled = await ready;
  return enabled
      ? ['base-await-if-live', for (final item in extra) item]
      : extra;
}

Future<List<String>> asyncAwaitThenConditionalRuntimeTailNames(
  Future<bool> ready,
  List<String> extra,
) async {
  final enabled = await ready;
  return enabled
      ? [
          'base-await-if-live',
          for (final item in extra) item,
          'base-await-if-tail',
        ]
      : [
          'base-await-if-off',
          for (final item in extra) item,
          'base-await-if-tail',
        ];
}

Future<List<String>> asyncAwaitThenConditionalRuntimeStaticSpreadNames(
  Future<bool> ready,
  List<String> extra,
) async {
  final enabled = await ready;
  return enabled
      ? [
          'base-await-if-live',
          for (final item in extra) item,
          ...['base-await-if-spread-a', 'base-await-if-spread-b'],
        ]
      : [
          'base-await-if-off',
          for (final item in extra) item,
          ...['base-await-if-spread-a', 'base-await-if-spread-b'],
        ];
}

Future<List<String>> asyncAwaitThenConditionalRuntimeDynamicNames(
  Future<bool> ready,
  List<String> extra,
  List<String> tail,
) async {
  final enabled = await ready;
  return enabled
      ? ['base-await-if-live', for (final item in extra) item, ...tail]
      : ['base-await-if-off', for (final item in extra) item, ...tail];
}

Future<List<String>> asyncAwaitThenConditionalRuntimeDynamicTailNames(
  Future<bool> ready,
  List<String> extra,
  List<String> tail,
) async {
  final enabled = await ready;
  return enabled
      ? [
          'base-await-if-live',
          for (final item in extra) item,
          ...tail,
          'base-await-if-tail',
        ]
      : [
          'base-await-if-off',
          for (final item in extra) item,
          ...tail,
          'base-await-if-tail',
        ];
}

Future<List<String>> asyncAwaitThenConditionalRuntimeDynamicStaticSpreadNames(
  Future<bool> ready,
  List<String> extra,
  List<String> tail,
) async {
  final enabled = await ready;
  return enabled
      ? [
          'base-await-if-live',
          for (final item in extra) item,
          ...tail,
          ...['base-await-if-spread-a', 'base-await-if-spread-b'],
        ]
      : [
          'base-await-if-off',
          for (final item in extra) item,
          ...tail,
          ...['base-await-if-spread-a', 'base-await-if-spread-b'],
        ];
}

List<String> dynamicNames(List<String> extra) {
  return ['base', ...extra];
}

Future<List<String>> asyncDynamicNames(List<String> extra) async {
  return ['base-async', ...extra];
}

Future<List<String>> asyncAwaitThenDynamicNames(
  Future<String> ready,
  List<String> extra,
) async {
  final value = await ready;
  return ['base-await-dynamic', ...extra];
}

List<String> runtimeForNames(List<String> extra) {
  return ['base', for (final value in extra) value];
}

Future<List<String>> asyncRuntimeForNames(List<String> extra) async {
  return ['base-async', for (final value in extra) value];
}

Future<List<String>> asyncAwaitThenRuntimeForNames(
  Future<String> ready,
  List<String> extra,
) async {
  final value = await ready;
  return ['base-await-runtime-for', for (final item in extra) item];
}

Map<String, String> labels(bool enabled, bool premium) {
  return {'mode': 'base'};
}

Future<Map<String, String>> asyncLabels(bool enabled, bool premium) async {
  return {'mode': 'base-async'};
}

Future<Map<String, String>> asyncAwaitThenLabels(Future<String> ready) async {
  final value = await ready;
  return {'mode': 'base-await-map', 'value': value};
}

Future<Map<String, String>> asyncAwaitThenConditionalLabels(
  Future<bool> ready,
) async {
  final enabled = await ready;
  return enabled
      ? {'state': 'base-await-if-live'}
      : {'state': 'base-await-if-off'};
}

Future<Map<String, String>> asyncAwaitThenConditionalDynamicLabels(
  Future<bool> ready,
  Map<String, String> extra,
) async {
  final enabled = await ready;
  return enabled ? {'state': 'base-await-if-live', ...extra} : extra;
}

Future<Map<String, String>> asyncAwaitThenConditionalDynamicTailLabels(
  Future<bool> ready,
  Map<String, String> extra,
) async {
  final enabled = await ready;
  return {
    if (enabled)
      'state': 'base-await-if-live'
    else
      'state': 'base-await-if-off',
    ...extra,
    'tail': 'base-await-if-tail',
  };
}

Future<Map<String, String>> asyncAwaitThenConditionalDynamicRuntimeTailLabels(
  Future<bool> ready,
  Map<String, String> extra,
  Map<String, String> tail,
) async {
  final enabled = await ready;
  return {
    if (enabled)
      'state': 'base-await-if-live'
    else
      'state': 'base-await-if-off',
    ...extra,
    for (final entry in tail.entries) entry.key: entry.value,
    'tail': 'base-await-if-tail',
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
    if (enabled)
      'state': 'base-await-if-live'
    else
      'state': 'base-await-if-off',
    ...extra,
    for (final entry in tail.entries) entry.key: entry.value,
    ...{'tail': 'base-await-if-spread'},
  };
}

Future<Map<String, String>> asyncAwaitThenConditionalRuntimeLabels(
  Future<bool> ready,
  Map<String, String> extra,
) async {
  final enabled = await ready;
  return enabled
      ? {
          'state': 'base-await-if-live',
          for (final entry in extra.entries) entry.key: entry.value,
        }
      : extra;
}

Future<Map<String, String>> asyncAwaitThenConditionalRuntimeTailLabels(
  Future<bool> ready,
  Map<String, String> extra,
) async {
  final enabled = await ready;
  return {
    if (enabled)
      'state': 'base-await-if-live'
    else
      'state': 'base-await-if-off',
    for (final entry in extra.entries) entry.key: entry.value,
    'tail': 'base-await-if-tail',
  };
}

Future<Map<String, String>> asyncAwaitThenConditionalDynamicStaticSpreadLabels(
  Future<bool> ready,
  Map<String, String> extra,
) async {
  final enabled = await ready;
  return {
    if (enabled)
      'state': 'base-await-if-live'
    else
      'state': 'base-await-if-off',
    ...extra,
    ...{'tail': 'base-await-if-spread'},
  };
}

Future<Map<String, String>> asyncAwaitThenConditionalDynamicRuntimeLabels(
  Future<bool> ready,
  Map<String, String> extra,
  Map<String, String> tail,
) async {
  final enabled = await ready;
  return {
    if (enabled)
      'state': 'base-await-if-live'
    else
      'state': 'base-await-if-off',
    ...extra,
    for (final entry in tail.entries) entry.key: entry.value,
  };
}

Future<Map<String, String>> asyncAwaitThenConditionalRuntimeStaticSpreadLabels(
  Future<bool> ready,
  Map<String, String> extra,
) async {
  final enabled = await ready;
  return {
    if (enabled)
      'state': 'base-await-if-live'
    else
      'state': 'base-await-if-off',
    for (final entry in extra.entries) entry.key: entry.value,
    ...{'tail': 'base-await-if-spread'},
  };
}

Future<Map<String, String>> asyncAwaitThenConditionalRuntimeDynamicLabels(
  Future<bool> ready,
  Map<String, String> extra,
  Map<String, String> tail,
) async {
  final enabled = await ready;
  return {
    if (enabled)
      'state': 'base-await-if-live'
    else
      'state': 'base-await-if-off',
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
    if (enabled)
      'state': 'base-await-if-live'
    else
      'state': 'base-await-if-off',
    for (final entry in extra.entries) entry.key: entry.value,
    ...tail,
    'tail': 'base-await-if-tail',
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
    if (enabled)
      'state': 'base-await-if-live'
    else
      'state': 'base-await-if-off',
    for (final entry in extra.entries) entry.key: entry.value,
    ...tail,
    ...{'tail': 'base-await-if-spread'},
  };
}

Map<String, String> dynamicLabels(Map<String, String> extra) {
  return {'mode': 'base', ...extra};
}

Future<Map<String, String>> asyncDynamicLabels(
  Map<String, String> extra,
) async {
  return {'mode': 'base-async', ...extra};
}

Future<Map<String, String>> asyncAwaitThenDynamicLabels(
  Future<String> ready,
  Map<String, String> extra,
) async {
  final value = await ready;
  return {'mode': 'base-await-dynamic-map', ...extra};
}

Map<String, String> runtimeForLabels(Map<String, String> extra) {
  return {
    'mode': 'base',
    for (final entry in extra.entries) entry.key: entry.value,
  };
}

Future<Map<String, String>> asyncRuntimeForLabels(
  Map<String, String> extra,
) async {
  return {
    'mode': 'base-async',
    for (final entry in extra.entries) entry.key: entry.value,
  };
}

Future<Map<String, String>> asyncAwaitThenRuntimeForLabels(
  Future<String> ready,
  Map<String, String> extra,
) async {
  final value = await ready;
  return {
    'mode': 'base-await-runtime-for',
    for (final entry in extra.entries) entry.key: entry.value,
  };
}

String chooseLabel(bool enabled) {
  return enabled ? 'base-live' : 'base-off';
}

Future<String> asyncAwaitThenChooseLabel(Future<bool> ready) async {
  final enabled = await ready;
  return enabled ? 'base-await-live' : 'base-await-off';
}

bool isKnown(Object value) {
  return value is int;
}

bool isUser(Object value) {
  return value is String;
}

bool isStringList(Object value) {
  return value is List<int>;
}

Object asStringList(Object value) {
  return value as List<int>;
}

Future<bool> asyncIsStringList(Object value) async {
  return value is List<int>;
}

Future<Object> asyncAsStringList(Object value) async {
  return value as List<int>;
}

Future<String Function()> asyncFutureCallbackTypeArg() async {
  return () => 'unsupported-future-callback';
}

Future<(String, int)> asyncFutureRecordTypeArg() async {
  return ('unsupported-future-record', 1);
}

bool isCallable(Object value) {
  return value is Object;
}

bool isRecord(Object value) {
  return value is Object;
}

double mainValue() {
  return helper();
}

void main() {
  mainValue();
}
