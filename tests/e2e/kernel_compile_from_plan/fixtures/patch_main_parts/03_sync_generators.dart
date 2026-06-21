Iterable<String> syncGenerated() sync* {
  yield 'patched-iterable';
}

Iterable<String> syncGeneratedMany(bool enabled) sync* {
  final prefix = 'patched-iterable';
  yield '$prefix-a';
  if (enabled) yield '$prefix-live';
  yield '$prefix-tail';
}

Iterable<String> syncGeneratedWhile() sync* {
  var i = 0;
  while (2 > i) {
    yield 'patched-iterable-while-$i';
    i = i + 1;
  }
}

Iterable<String> syncGeneratedWhileBreak() sync* {
  var i = 0;
  while (4 > i) {
    yield 'patched-iterable-while-break-before-$i';
    if (i == 2) break;
    yield 'patched-iterable-while-break-after-$i';
    i = i + 1;
  }
}

Iterable<String> syncGeneratedWhileContinue() sync* {
  var i = 0;
  while (3 > i) {
    yield 'patched-iterable-while-continue-before-$i';
    if (i == 1) {
      i = i + 1;
      continue;
    }
    yield 'patched-iterable-while-continue-after-$i';
    i = i + 1;
  }
}

Iterable<String> syncGeneratedWhileContinueBreak() sync* {
  var i = 0;
  while (4 > i) {
    yield 'patched-iterable-while-continue-before-$i';
    if (i == 1) {
      i = i + 1;
      continue;
    }
    yield 'patched-iterable-while-continue-mid-$i';
    if (i == 2) break;
    yield 'patched-iterable-while-continue-after-$i';
    i = i + 1;
  }
}

Iterable<String> syncGeneratedDoWhile() sync* {
  var i = 0;
  do {
    yield 'patched-iterable-do-$i';
    i = i + 1;
  } while (2 > i);
}

Iterable<String> syncGeneratedDoWhileBreak() sync* {
  var i = 0;
  do {
    yield 'patched-iterable-do-break-before-$i';
    if (i == 1) break;
    yield 'patched-iterable-do-break-after-$i';
    i = i + 1;
  } while (3 > i);
}

Iterable<String> syncGeneratedDoWhileContinue() sync* {
  var i = 0;
  do {
    yield 'patched-iterable-do-continue-before-$i';
    if (i == 1) {
      i = i + 1;
      continue;
    }
    yield 'patched-iterable-do-continue-after-$i';
    i = i + 1;
  } while (3 > i);
}

Iterable<String> syncGeneratedDoWhileContinueBreak() sync* {
  var i = 0;
  do {
    yield 'patched-iterable-do-continue-before-$i';
    if (i == 1) {
      i = i + 1;
      continue;
    }
    yield 'patched-iterable-do-continue-mid-$i';
    if (i == 2) break;
    yield 'patched-iterable-do-continue-after-$i';
    i = i + 1;
  } while (4 > i);
}

Iterable<String> syncGeneratedForLoop() sync* {
  for (var i = 0; 2 > i; i = i + 1) {
    yield 'patched-iterable-for-$i';
  }
}

Iterable<String> syncGeneratedForLoopPostIncrement() sync* {
  for (var i = 0; 2 > i; i++) {
    yield 'patched-iterable-for-postinc-$i';
  }
}

Iterable<String> syncGeneratedForLoopMultiUpdate() sync* {
  for (var i = 0, j = 10; 2 > i; i = i + 1, j = j + 1) {
    yield 'patched-iterable-for-multi-$i-$j';
  }
}

Iterable<String> syncGeneratedForLoopExternalLocal() sync* {
  var i = 0;
  for (; 2 > i; i = i + 1) {
    yield 'patched-iterable-for-external-$i';
  }
}

Iterable<String> syncGeneratedForLoopBodyUpdate() sync* {
  var i = 0;
  for (; 2 > i;) {
    yield 'patched-iterable-for-body-update-$i';
    i = i + 1;
  }
}

Iterable<String> syncGeneratedForLoopContinue() sync* {
  for (var i = 0; 3 > i; i = i + 1) {
    yield 'patched-iterable-for-continue-before-$i';
    if (i == 1) continue;
    yield 'patched-iterable-for-continue-after-$i';
  }
}

Iterable<String> syncGeneratedForLoopContinueBreak() sync* {
  for (var i = 0; 4 > i; i = i + 1) {
    yield 'patched-iterable-for-continue-before-$i';
    if (i == 1) continue;
    yield 'patched-iterable-for-continue-mid-$i';
    if (i == 2) break;
    yield 'patched-iterable-for-continue-after-$i';
  }
}

Iterable<String> syncGeneratedForLoopBreak() sync* {
  for (var i = 0; 3 > i; i = i + 1) {
    yield 'patched-iterable-for-break-before-$i';
    if (i == 1) break;
    yield 'patched-iterable-for-break-after-$i';
  }
}

Iterable<String> syncGeneratedForIn() sync* {
  for (final value in ['patched-iterable-a', 'patched-iterable-b']) {
    yield value;
  }
}

Iterable<String> syncGeneratedForInBreak() sync* {
  final prefix = 'patched-iterable-static-break';
  for (final value in ['a', 'stop', 'tail']) {
    yield '$prefix-before-$value';
    if (value == 'stop') break;
    yield '$prefix-after-$value';
  }
}

Iterable<String> syncGeneratedForInBreakFirst() sync* {
  final prefix = 'patched-iterable-static-break-first';
  for (final value in ['a', 'stop', 'tail']) {
    if (value == 'stop') break;
    yield '$prefix-$value';
  }
}

Iterable<String> syncGeneratedForInContinue() sync* {
  final prefix = 'patched-iterable-static-continue';
  for (final value in ['a', 'skip', 'tail']) {
    if (value == 'skip') continue;
    yield '$prefix-$value';
  }
}

Iterable<String> syncGeneratedForInContinueAfterYield() sync* {
  final prefix = 'patched-iterable-static-continue-after-yield';
  for (final value in ['a', 'skip', 'tail']) {
    yield '$prefix-before-$value';
    if (value == 'skip') continue;
    yield '$prefix-after-$value';
  }
}

Iterable<String> syncGeneratedDynamicForIn(List<String> extra) sync* {
  for (final value in extra) {
    yield value;
  }
  yield 'patched-iterable-dynamic-tail';
}

Iterable<String> syncGeneratedDynamicForInMapped(List<String> extra) sync* {
  final prefix = 'patched-iterable-map';
  for (final value in extra) {
    yield '$prefix-$value';
  }
}

Iterable<String> syncGeneratedDynamicForInMany(List<String> extra) sync* {
  final prefix = 'patched-iterable-many';
  for (final value in extra) {
    yield '$prefix-a-$value';
    yield '$prefix-b-$value';
  }
}

Iterable<String> syncGeneratedDynamicForInIf(List<String> extra) sync* {
  final prefix = 'patched-iterable-if';
  for (final value in extra) {
    if (value == 'live') yield '$prefix-hit-$value';
    yield '$prefix-tail-$value';
  }
}

Iterable<String> syncGeneratedDynamicForInIfElse(List<String> extra) sync* {
  final prefix = 'patched-iterable-ifelse';
  for (final value in extra) {
    if (value == 'live') {
      yield '$prefix-hit-$value';
    } else {
      yield '$prefix-miss-$value';
    }
  }
}

Iterable<String> syncGeneratedDynamicForInLocal(List<String> extra) sync* {
  final prefix = 'patched-iterable-local';
  for (final value in extra) {
    final marker = '$prefix-$value';
    yield marker;
  }
}

Iterable<String> syncGeneratedDynamicForInContinue(List<String> extra) sync* {
  final prefix = 'patched-iterable-continue';
  for (final value in extra) {
    if (value == 'skip') continue;
    yield '$prefix-$value';
  }
}

Iterable<String> syncGeneratedDynamicForInContinueAfterYield(
  List<String> extra,
) sync* {
  final prefix = 'patched-iterable-continue-after-yield';
  for (final value in extra) {
    yield '$prefix-before-$value';
    if (value == 'skip') continue;
    yield '$prefix-after-$value';
  }
}

Iterable<String> syncGeneratedDynamicForInBreak(List<String> extra) sync* {
  final prefix = 'patched-iterable-break';
  for (final value in extra) {
    if (value == 'stop') break;
    yield '$prefix-$value';
  }
}

Iterable<String> syncGeneratedDynamicForInBreakAfterYield(
  List<String> extra,
) sync* {
  final prefix = 'patched-iterable-break-after-yield';
  for (final value in extra) {
    yield '$prefix-before-$value';
    if (value == 'stop') break;
    yield '$prefix-after-$value';
  }
}

Iterable<String> syncGeneratedDynamicForInBreakAtEnd(List<String> extra) sync* {
  final prefix = 'patched-iterable-break-at-end';
  for (final value in extra) {
    yield '$prefix-before-$value';
    if (value == 'stop') break;
  }
}

Iterable<String> syncGeneratedDynamicForInContinueThenBreak(
  List<String> extra,
) sync* {
  final prefix = 'patched-iterable-continue-break';
  for (final value in extra) {
    if (value == 'skip') continue;
    if (value == 'stop') break;
    yield '$prefix-$value';
  }
}

Iterable<String> syncGeneratedDynamicForInContinueYieldBreak(
  List<String> extra,
) sync* {
  final prefix = 'patched-iterable-continue-yield-break';
  for (final value in extra) {
    if (value == 'skip') continue;
    yield '$prefix-before-$value';
    if (value == 'stop') break;
    yield '$prefix-after-$value';
  }
}

Iterable<String> syncGeneratedDynamicForInNested(
  List<String> extra,
  List<String> suffixes,
) sync* {
  final prefix = 'patched-iterable-nested';
  for (final value in extra) {
    for (final suffix in suffixes) {
      yield '$prefix-$value-$suffix';
    }
  }
}

Iterable<String> syncGeneratedDynamicForInNestedBreakContinue(
  List<String> extra,
  List<String> suffixes,
) sync* {
  final prefix = 'patched-iterable-nested-control';
  for (final value in extra) {
    if (value == 'skip') continue;
    for (final suffix in suffixes) {
      if (suffix == 'skip') continue;
      yield '$prefix-$value-$suffix';
      if (suffix == 'stop') break;
    }
    if (value == 'stop') break;
  }
}

Iterable<String> syncGeneratedYieldStar() sync* {
  yield* ['patched-yield-star-a', 'patched-yield-star-b'];
}

Iterable<String> syncGeneratedYieldStarDynamic(List<String> extra) sync* {
  yield* extra;
  yield 'patched-yield-star-dynamic-tail';
}

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

List<String> dynamicNames(List<String> extra) {
  return ['patched', ...extra];
}

Future<List<String>> asyncDynamicNames(List<String> extra) async {
  return ['patched-async', ...extra];
}

List<String> runtimeForNames(List<String> extra) {
  return ['patched', for (final value in extra) value];
}

Future<List<String>> asyncRuntimeForNames(List<String> extra) async {
  return ['patched-async-for', for (final value in extra) value];
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

Map<String, String> dynamicLabels(Map<String, String> extra) {
  return {'mode': 'patched', ...extra};
}

Future<Map<String, String>> asyncDynamicLabels(
  Map<String, String> extra,
) async {
  return {'mode': 'patched-async', ...extra};
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

String chooseLabel(bool enabled) {
  return enabled ? 'patched-live' : 'patched-off';
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
