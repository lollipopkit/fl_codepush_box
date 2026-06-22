String syncSwitchStatementLabel(String tier) {
  return tier == 'gold' ? 'base-switch-stmt-gold' : 'base-switch-stmt-other';
}

Future<String> asyncSwitchStatementLabel(String tier) async {
  return tier == 'gold'
      ? 'base-async-switch-stmt-gold'
      : 'base-async-switch-stmt-other';
}

Future<String> asyncAwaitThenSwitchStatementLabel(Future<String> ready) async {
  final tier = await ready;
  return tier == 'gold'
      ? 'base-await-switch-stmt-gold'
      : 'base-await-switch-stmt-other';
}

int syncSwitchStatementScore(int code) {
  return code == 7 ? 700 : 100;
}

List<String> switchStatementListNames(String tier) {
  return ['base-switch-stmt-list-head', tier, 'base-switch-stmt-list-tail'];
}

Map<String, String> switchStatementMapLabels(int code) {
  return {'state': 'base-switch-stmt-map-$code'};
}

String unchangedGuardedSwitchStatementLabel(String tier, bool enabled) {
  switch (tier) {
    case 'gold' when enabled:
      return 'guarded-switch-stmt-gold';
    default:
      return 'guarded-switch-stmt-other';
  }
}

String syncSwitchStatementAssignedLabel(String tier) {
  var label = 'base-switch-stmt-assigned-head';
  if (tier == 'gold') {
    label = 'base-switch-stmt-assigned-gold';
  }
  return 'base-switch-stmt-assigned-$label';
}

Future<String> asyncSwitchStatementAssignedLabel(String tier) async {
  var label = 'base-async-switch-stmt-assigned-head';
  if (tier == 'gold') {
    label = 'base-async-switch-stmt-assigned-gold';
  }
  return 'base-async-switch-stmt-assigned-$label';
}

Future<String> asyncAwaitThenSwitchStatementAssignedLabel(
  Future<String> ready,
) async {
  final tier = await ready;
  var label = 'base-await-switch-stmt-assigned-head';
  if (tier == 'gold') {
    label = 'base-await-switch-stmt-assigned-gold';
  }
  return 'base-await-switch-stmt-assigned-$label';
}

int syncSwitchStatementAssignedScore(int code) {
  var score = 1000;
  if (code == 7) {
    score = 7000;
  }
  return score + 1;
}

List<String> switchStatementAssignedListNames(String tier) {
  var label = 'base-switch-stmt-assigned-list-head';
  if (tier == 'gold') {
    label = 'base-switch-stmt-assigned-list-gold';
  }
  return [label, 'base-switch-stmt-assigned-list-tail'];
}

Map<String, String> switchStatementAssignedMapLabels(int code) {
  var label = 'base-switch-stmt-assigned-map';
  if (code == 7) {
    label = 'base-switch-stmt-assigned-map-seven';
  }
  return {'state': label};
}

String syncSwitchStatementThrowLabel(String tier) {
  if (tier == 'gold') {
    return 'base-switch-stmt-throw-gold';
  }
  if (tier == 'blocked') {
    throw 'base-switch-stmt-throw-blocked';
  }
  return 'base-switch-stmt-throw-other';
}

Future<String> asyncSwitchStatementThrowLabel(String tier) async {
  if (tier == 'gold') {
    return 'base-async-switch-stmt-throw-gold';
  }
  if (tier == 'blocked') {
    throw 'base-async-switch-stmt-throw-blocked';
  }
  return 'base-async-switch-stmt-throw-other';
}

Future<String> asyncAwaitThenSwitchStatementThrowLabel(
  Future<String> ready,
) async {
  final tier = await ready;
  if (tier == 'gold') {
    return 'base-await-switch-stmt-throw-gold';
  }
  if (tier == 'blocked') {
    throw 'base-await-switch-stmt-throw-blocked';
  }
  return 'base-await-switch-stmt-throw-other';
}

String syncSwitchStatementSequenceLabel(String tier) {
  if (tier == 'gold') {
    final label = 'base-switch-stmt-seq-gold';
    return 'base-switch-stmt-seq-$label';
  }
  if (tier == 'blocked') {
    final label = 'base-switch-stmt-seq-blocked';
    throw 'base-switch-stmt-seq-$label';
  }
  final label = 'base-switch-stmt-seq-other';
  return 'base-switch-stmt-seq-$label';
}

Future<String> asyncSwitchStatementSequenceLabel(String tier) async {
  if (tier == 'gold') {
    final label = 'base-async-switch-stmt-seq-gold';
    return 'base-async-switch-stmt-seq-$label';
  }
  if (tier == 'blocked') {
    final label = 'base-async-switch-stmt-seq-blocked';
    throw 'base-async-switch-stmt-seq-$label';
  }
  final label = 'base-async-switch-stmt-seq-other';
  return 'base-async-switch-stmt-seq-$label';
}

Future<String> asyncAwaitThenSwitchStatementSequenceLabel(
  Future<String> ready,
) async {
  final tier = await ready;
  if (tier == 'gold') {
    final label = 'base-await-switch-stmt-seq-gold';
    return 'base-await-switch-stmt-seq-$label';
  }
  if (tier == 'blocked') {
    final label = 'base-await-switch-stmt-seq-blocked';
    throw 'base-await-switch-stmt-seq-$label';
  }
  final label = 'base-await-switch-stmt-seq-other';
  return 'base-await-switch-stmt-seq-$label';
}

String syncSwitchStatementSideEffectTail(String tier) {
  var label = 'base-switch-stmt-side-head';
  var suffix = 'base-switch-stmt-side-suffix-head';
  if (tier == 'gold') {
    label = 'base-switch-stmt-side-gold';
    suffix = 'base-switch-stmt-side-suffix-gold';
  }
  return 'base-switch-stmt-side-$label-$suffix';
}

Future<String> asyncSwitchStatementSideEffectTail(String tier) async {
  var label = 'base-async-switch-stmt-side-head';
  var suffix = 'base-async-switch-stmt-side-suffix-head';
  if (tier == 'gold') {
    label = 'base-async-switch-stmt-side-gold';
    suffix = 'base-async-switch-stmt-side-suffix-gold';
  }
  return 'base-async-switch-stmt-side-$label-$suffix';
}

Future<String> asyncAwaitThenSwitchStatementSideEffectTail(
  Future<String> ready,
) async {
  final tier = await ready;
  var label = 'base-await-switch-stmt-side-head';
  var suffix = 'base-await-switch-stmt-side-suffix-head';
  if (tier == 'gold') {
    label = 'base-await-switch-stmt-side-gold';
    suffix = 'base-await-switch-stmt-side-suffix-gold';
  }
  return 'base-await-switch-stmt-side-$label-$suffix';
}

Future<String> asyncSwitchStatementAwaitCaseLabel(
  String tier,
  Future<String> ready,
) async {
  if (tier == 'gold') {
    final label = await ready;
    return 'base-async-switch-stmt-await-case-gold-$label';
  }
  if (tier == 'blocked') {
    final label = await ready;
    throw 'base-async-switch-stmt-await-case-blocked-$label';
  }
  final label = await ready;
  return 'base-async-switch-stmt-await-case-other-$label';
}

Future<String> asyncAwaitThenSwitchStatementAwaitCaseLabel(
  Future<String> tierReady,
  Future<String> labelReady,
) async {
  final tier = await tierReady;
  if (tier == 'gold') {
    final label = await labelReady;
    return 'base-await-switch-stmt-await-case-gold-$label';
  }
  if (tier == 'blocked') {
    final label = await labelReady;
    throw 'base-await-switch-stmt-await-case-blocked-$label';
  }
  final label = await labelReady;
  return 'base-await-switch-stmt-await-case-other-$label';
}
