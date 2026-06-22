String syncSwitchStatementLabel(String tier) {
  switch (tier) {
    case 'gold':
      return 'patched-switch-stmt-gold';
    case 'silver':
      return 'patched-switch-stmt-silver';
    default:
      return 'patched-switch-stmt-other';
  }
}

Future<String> asyncSwitchStatementLabel(String tier) async {
  switch (tier) {
    case 'gold':
      return 'patched-async-switch-stmt-gold';
    case 'silver':
      return 'patched-async-switch-stmt-silver';
    default:
      return 'patched-async-switch-stmt-other';
  }
}

Future<String> asyncAwaitThenSwitchStatementLabel(Future<String> ready) async {
  final tier = await ready;
  switch (tier) {
    case 'gold':
      return 'patched-await-switch-stmt-gold';
    case 'silver':
      return 'patched-await-switch-stmt-silver';
    default:
      return 'patched-await-switch-stmt-other';
  }
}

int syncSwitchStatementScore(int code) {
  switch (code) {
    case 7:
      return 700;
    case 9:
      return 900;
    default:
      return 100;
  }
}

List<String> switchStatementListNames(String tier) {
  switch (tier) {
    case 'gold':
      return ['patched-switch-stmt-list-head', 'patched-switch-stmt-list-gold'];
    case 'silver':
      return [
        'patched-switch-stmt-list-head',
        'patched-switch-stmt-list-silver',
      ];
    default:
      return [
        'patched-switch-stmt-list-head',
        'patched-switch-stmt-list-other',
      ];
  }
}

Map<String, String> switchStatementMapLabels(int code) {
  switch (code) {
    case 7:
      return {'state': 'patched-switch-stmt-map-seven'};
    case 9:
      return {'state': 'patched-switch-stmt-map-nine'};
    default:
      return {'state': 'patched-switch-stmt-map-other'};
  }
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
  var label = 'patched-switch-stmt-assigned-head';
  switch (tier) {
    case 'gold':
      label = 'patched-switch-stmt-assigned-gold';
      break;
    case 'silver':
      label = 'patched-switch-stmt-assigned-silver';
      break;
    default:
      label = 'patched-switch-stmt-assigned-other';
  }
  return 'patched-switch-stmt-assigned-$label';
}

Future<String> asyncSwitchStatementAssignedLabel(String tier) async {
  var label = 'patched-async-switch-stmt-assigned-head';
  switch (tier) {
    case 'gold':
      label = 'patched-async-switch-stmt-assigned-gold';
      break;
    case 'silver':
      label = 'patched-async-switch-stmt-assigned-silver';
      break;
    default:
      label = 'patched-async-switch-stmt-assigned-other';
  }
  return 'patched-async-switch-stmt-assigned-$label';
}

Future<String> asyncAwaitThenSwitchStatementAssignedLabel(
  Future<String> ready,
) async {
  final tier = await ready;
  var label = 'patched-await-switch-stmt-assigned-head';
  switch (tier) {
    case 'gold':
      label = 'patched-await-switch-stmt-assigned-gold';
      break;
    case 'silver':
      label = 'patched-await-switch-stmt-assigned-silver';
      break;
    default:
      label = 'patched-await-switch-stmt-assigned-other';
  }
  return 'patched-await-switch-stmt-assigned-$label';
}

int syncSwitchStatementAssignedScore(int code) {
  var score = 1000;
  switch (code) {
    case 7:
      score = 7000;
      break;
    case 9:
      score = 9000;
      break;
    default:
      score = 1000;
  }
  return score + 1;
}

List<String> switchStatementAssignedListNames(String tier) {
  var label = 'patched-switch-stmt-assigned-list-head';
  switch (tier) {
    case 'gold':
      label = 'patched-switch-stmt-assigned-list-gold';
      break;
    case 'silver':
      label = 'patched-switch-stmt-assigned-list-silver';
      break;
    default:
      label = 'patched-switch-stmt-assigned-list-other';
  }
  return [label, 'patched-switch-stmt-assigned-list-tail'];
}

Map<String, String> switchStatementAssignedMapLabels(int code) {
  var label = 'patched-switch-stmt-assigned-map';
  switch (code) {
    case 7:
      label = 'patched-switch-stmt-assigned-map-seven';
      break;
    case 9:
      label = 'patched-switch-stmt-assigned-map-nine';
      break;
    default:
      label = 'patched-switch-stmt-assigned-map-other';
  }
  return {'state': label};
}

String syncSwitchStatementThrowLabel(String tier) {
  switch (tier) {
    case 'gold':
      return 'patched-switch-stmt-throw-gold';
    case 'blocked':
      throw 'patched-switch-stmt-throw-blocked';
    default:
      return 'patched-switch-stmt-throw-other';
  }
}

Future<String> asyncSwitchStatementThrowLabel(String tier) async {
  switch (tier) {
    case 'gold':
      return 'patched-async-switch-stmt-throw-gold';
    case 'blocked':
      throw 'patched-async-switch-stmt-throw-blocked';
    default:
      return 'patched-async-switch-stmt-throw-other';
  }
}

Future<String> asyncAwaitThenSwitchStatementThrowLabel(
  Future<String> ready,
) async {
  final tier = await ready;
  switch (tier) {
    case 'gold':
      return 'patched-await-switch-stmt-throw-gold';
    case 'blocked':
      throw 'patched-await-switch-stmt-throw-blocked';
    default:
      return 'patched-await-switch-stmt-throw-other';
  }
}

String syncSwitchStatementSequenceLabel(String tier) {
  switch (tier) {
    case 'gold':
      final label = 'patched-switch-stmt-seq-gold';
      return 'patched-switch-stmt-seq-$label';
    case 'blocked':
      final label = 'patched-switch-stmt-seq-blocked';
      throw 'patched-switch-stmt-seq-$label';
    default:
      final label = 'patched-switch-stmt-seq-other';
      return 'patched-switch-stmt-seq-$label';
  }
}

Future<String> asyncSwitchStatementSequenceLabel(String tier) async {
  switch (tier) {
    case 'gold':
      final label = 'patched-async-switch-stmt-seq-gold';
      return 'patched-async-switch-stmt-seq-$label';
    case 'blocked':
      final label = 'patched-async-switch-stmt-seq-blocked';
      throw 'patched-async-switch-stmt-seq-$label';
    default:
      final label = 'patched-async-switch-stmt-seq-other';
      return 'patched-async-switch-stmt-seq-$label';
  }
}

Future<String> asyncAwaitThenSwitchStatementSequenceLabel(
  Future<String> ready,
) async {
  final tier = await ready;
  switch (tier) {
    case 'gold':
      final label = 'patched-await-switch-stmt-seq-gold';
      return 'patched-await-switch-stmt-seq-$label';
    case 'blocked':
      final label = 'patched-await-switch-stmt-seq-blocked';
      throw 'patched-await-switch-stmt-seq-$label';
    default:
      final label = 'patched-await-switch-stmt-seq-other';
      return 'patched-await-switch-stmt-seq-$label';
  }
}

String syncSwitchStatementSideEffectTail(String tier) {
  var label = 'patched-switch-stmt-side-head';
  var suffix = 'patched-switch-stmt-side-suffix-head';
  switch (tier) {
    case 'gold':
      label = 'patched-switch-stmt-side-gold';
      suffix = 'patched-switch-stmt-side-suffix-gold';
      break;
    case 'silver':
      label = 'patched-switch-stmt-side-silver';
      suffix = 'patched-switch-stmt-side-suffix-silver';
      break;
    default:
      label = 'patched-switch-stmt-side-other';
      suffix = 'patched-switch-stmt-side-suffix-other';
  }
  return 'patched-switch-stmt-side-$label-$suffix';
}

Future<String> asyncSwitchStatementSideEffectTail(String tier) async {
  var label = 'patched-async-switch-stmt-side-head';
  var suffix = 'patched-async-switch-stmt-side-suffix-head';
  switch (tier) {
    case 'gold':
      label = 'patched-async-switch-stmt-side-gold';
      suffix = 'patched-async-switch-stmt-side-suffix-gold';
      break;
    case 'silver':
      label = 'patched-async-switch-stmt-side-silver';
      suffix = 'patched-async-switch-stmt-side-suffix-silver';
      break;
    default:
      label = 'patched-async-switch-stmt-side-other';
      suffix = 'patched-async-switch-stmt-side-suffix-other';
  }
  return 'patched-async-switch-stmt-side-$label-$suffix';
}

Future<String> asyncAwaitThenSwitchStatementSideEffectTail(
  Future<String> ready,
) async {
  final tier = await ready;
  var label = 'patched-await-switch-stmt-side-head';
  var suffix = 'patched-await-switch-stmt-side-suffix-head';
  switch (tier) {
    case 'gold':
      label = 'patched-await-switch-stmt-side-gold';
      suffix = 'patched-await-switch-stmt-side-suffix-gold';
      break;
    case 'silver':
      label = 'patched-await-switch-stmt-side-silver';
      suffix = 'patched-await-switch-stmt-side-suffix-silver';
      break;
    default:
      label = 'patched-await-switch-stmt-side-other';
      suffix = 'patched-await-switch-stmt-side-suffix-other';
  }
  return 'patched-await-switch-stmt-side-$label-$suffix';
}

Future<String> asyncSwitchStatementAwaitCaseLabel(
  String tier,
  Future<String> ready,
) async {
  switch (tier) {
    case 'gold':
      final label = await ready;
      return 'patched-async-switch-stmt-await-case-gold-$label';
    case 'blocked':
      final label = await ready;
      throw 'patched-async-switch-stmt-await-case-blocked-$label';
    default:
      final label = await ready;
      return 'patched-async-switch-stmt-await-case-other-$label';
  }
}

Future<String> asyncAwaitThenSwitchStatementAwaitCaseLabel(
  Future<String> tierReady,
  Future<String> labelReady,
) async {
  final tier = await tierReady;
  switch (tier) {
    case 'gold':
      final label = await labelReady;
      return 'patched-await-switch-stmt-await-case-gold-$label';
    case 'blocked':
      final label = await labelReady;
      throw 'patched-await-switch-stmt-await-case-blocked-$label';
    default:
      final label = await labelReady;
      return 'patched-await-switch-stmt-await-case-other-$label';
  }
}
