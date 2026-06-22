Future<String> asyncDoWhileLocal(int limit) async {
  var i = 0;
  var out = 'base-do-while';
  do {
    out = '$out-$i';
    i = i + 1;
  } while (limit > i);
  return out;
}

Future<String> asyncDoWhileAwaitCondition(Future<bool> keepGoing) async {
  var i = 0;
  var out = 'base-do-while-await';
  do {
    out = '$out-$i';
    i = i + 1;
  } while (await keepGoing);
  return out;
}

Future<String> asyncDoWhileBranchLocal(int limit) async {
  var i = 0;
  var out = 'base-do-while-branch';
  do {
    final segment = i == 0 ? 'first' : 'again';
    out = '$out-$segment-$i';
    i = i + 1;
  } while (limit > i);
  return out;
}

Future<String> asyncDoWhileAwaitConditionBranchLocal(
  Future<bool> keepGoing,
) async {
  var i = 0;
  var out = 'base-do-while-await-branch';
  do {
    final segment = i == 0 ? 'first' : 'again';
    out = '$out-$segment-$i';
    i = i + 1;
  } while (await keepGoing);
  return out;
}

Future<String> asyncDoWhileAwaitConditionAwaitLocal(
  Future<bool> keepGoing,
  Future<String> ready,
) async {
  var i = 0;
  var out = 'base-do-while-await-local';
  do {
    final segment = await ready;
    out = '$out-$segment-$i';
    i = i + 1;
  } while (await keepGoing);
  return out;
}

Future<String> asyncDoWhileBreak(int limit) async {
  var i = 0;
  var out = 'base-do-while-break';
  do {
    out = '$out-before-$i';
    if (i == 1) break;
    out = '$out-after-$i';
    i = i + 1;
  } while (limit > i);
  return out;
}

Future<String> asyncDoWhileContinue(int limit) async {
  var i = 0;
  var out = 'base-do-while-continue';
  do {
    out = '$out-before-$i';
    if (i == 1) {
      i = i + 1;
      continue;
    }
    out = '$out-after-$i';
    i = i + 1;
  } while (limit > i);
  return out;
}

Future<String> asyncDoWhileContinueBreak(int limit) async {
  var i = 0;
  var out = 'base-do-while-continue-break';
  do {
    out = '$out-before-$i';
    if (i == 1) {
      i = i + 1;
      continue;
    }
    out = '$out-middle-$i';
    if (i == 2) break;
    out = '$out-after-$i';
    i = i + 1;
  } while (limit > i);
  return out;
}

Future<String> asyncDoWhileAwaitGuardContinueBreak(
  int limit,
  Future<bool> skip,
  Future<bool> stop,
) async {
  var i = 0;
  var out = 'base-do-while-await-guard-continue-break';
  do {
    out = '$out-before-$i';
    if (await skip) {
      i = i + 1;
      continue;
    }
    out = '$out-middle-$i';
    if (await stop) break;
    out = '$out-after-$i';
    i = i + 1;
  } while (limit > i);
  return out;
}

Future<String> asyncDoWhileAwaitGuardContinueBreakAwaitCondition(
  Future<bool> keepGoing,
  Future<bool> skip,
  Future<bool> stop,
) async {
  var i = 0;
  var out = 'base-do-while-await-guard-continue-break-await-condition';
  do {
    out = '$out-before-$i';
    if (await skip) {
      i = i + 1;
      continue;
    }
    out = '$out-middle-$i';
    if (await stop) break;
    out = '$out-after-$i';
    i = i + 1;
  } while (await keepGoing);
  return out;
}

Future<String> asyncDoWhileTryCatchAwaitGuard(
  int limit,
  Future<bool> fail,
) async {
  var i = 0;
  var out = 'base-do-while-try-catch-await-guard';
  do {
    try {
      out = '$out-body-$i';
      if (await fail) throw 'base-do-while-catch-$i';
      out = '$out-tail-$i';
    } catch (e) {
      out = '$out-caught-$e';
    }
    i = i + 1;
  } while (limit > i);
  return out;
}

Future<String> asyncDoWhileTryFinallyAwaitGuard(
  int limit,
  Future<bool> skip,
  Future<String> cleanup,
) async {
  var i = 0;
  var out = 'base-do-while-try-finally-await-guard';
  do {
    try {
      out = '$out-body-$i';
      if (await skip) {
        out = '$out-skip-$i';
      } else {
        out = '$out-tail-$i';
      }
    } finally {
      final marker = await cleanup;
      out = '$out-finally-$marker';
    }
    i = i + 1;
  } while (limit > i);
  return out;
}

Future<String> asyncDoWhileAwaitConditionTryCatchAwaitGuard(
  Future<bool> keepGoing,
  Future<bool> fail,
) async {
  var i = 0;
  var out = 'base-do-while-await-condition-try-catch';
  do {
    try {
      out = '$out-body-$i';
      if (await fail) throw 'base-do-while-await-condition-catch-$i';
      out = '$out-tail-$i';
    } catch (e) {
      out = '$out-caught-$e';
    }
    i = i + 1;
  } while (await keepGoing);
  return out;
}

Future<String> asyncDoWhileAwaitConditionTryFinallyAwaitGuard(
  Future<bool> keepGoing,
  Future<bool> skip,
  Future<String> cleanup,
) async {
  var i = 0;
  var out = 'base-do-while-await-condition-try-finally';
  do {
    try {
      out = '$out-body-$i';
      if (await skip) {
        out = '$out-skip-$i';
      } else {
        out = '$out-tail-$i';
      }
    } finally {
      final marker = await cleanup;
      out = '$out-finally-$marker';
    }
    i = i + 1;
  } while (await keepGoing);
  return out;
}

Future<String> asyncWhileTryCatchAwaitGuard(
  int limit,
  Future<bool> fail,
) async {
  var i = 0;
  var out = 'base-while-try-catch-await-guard';
  while (limit > i) {
    try {
      out = '$out-body-$i';
      if (await fail) throw 'base-while-catch-$i';
      out = '$out-tail-$i';
    } catch (e) {
      out = '$out-caught-$e';
    }
    i = i + 1;
  }
  return out;
}

Future<String> asyncWhileTryFinallyAwaitGuard(
  int limit,
  Future<bool> skip,
  Future<String> cleanup,
) async {
  var i = 0;
  var out = 'base-while-try-finally-await-guard';
  while (limit > i) {
    try {
      out = '$out-body-$i';
      if (await skip) {
        out = '$out-skip-$i';
      } else {
        out = '$out-tail-$i';
      }
    } finally {
      final marker = await cleanup;
      out = '$out-finally-$marker';
    }
    i = i + 1;
  }
  return out;
}

Future<String> asyncWhileAwaitConditionTryCatchAwaitGuard(
  Future<bool> keepGoing,
  Future<bool> fail,
) async {
  var i = 0;
  var out = 'base-while-await-condition-try-catch';
  while (await keepGoing) {
    try {
      out = '$out-body-$i';
      if (await fail) throw 'base-while-await-condition-catch-$i';
      out = '$out-tail-$i';
    } catch (e) {
      out = '$out-caught-$e';
    }
    i = i + 1;
  }
  return out;
}

Future<String> asyncWhileAwaitConditionTryFinallyAwaitGuard(
  Future<bool> keepGoing,
  Future<bool> skip,
  Future<String> cleanup,
) async {
  var i = 0;
  var out = 'base-while-await-condition-try-finally';
  while (await keepGoing) {
    try {
      out = '$out-body-$i';
      if (await skip) {
        out = '$out-skip-$i';
      } else {
        out = '$out-tail-$i';
      }
    } finally {
      final marker = await cleanup;
      out = '$out-finally-$marker';
    }
    i = i + 1;
  }
  return out;
}

Future<String> asyncForLocal(int limit) async {
  var out = 'base-for';
  for (var i = 0; limit > i; i = i + 1) {
    out = '$out-$i';
  }
  return out;
}

Future<String> asyncForContinue(int limit) async {
  var out = 'base-for-continue';
  for (var i = 0; limit > i; i = i + 1) {
    out = '$out-before-$i';
    if (i == 1) continue;
    out = '$out-after-$i';
  }
  return out;
}

Future<String> asyncForBreak(int limit) async {
  var out = 'base-for-break';
  for (var i = 0; limit > i; i = i + 1) {
    out = '$out-before-$i';
    if (i == 1) break;
    out = '$out-after-$i';
  }
  return out;
}

Future<String> asyncForContinueBreak(int limit) async {
  var out = 'base-for-continue-break';
  for (var i = 0; limit > i; i = i + 1) {
    out = '$out-before-$i';
    if (i == 1) continue;
    out = '$out-mid-$i';
    if (i == 2) break;
    out = '$out-after-$i';
  }
  return out;
}

Future<String> asyncForAwaitGuardContinueBreak(
  int limit,
  Future<bool> skip,
  Future<bool> stop,
) async {
  var out = 'base-for-await-guard-continue-break';
  for (var i = 0; limit > i; i = i + 1) {
    out = '$out-before-$i';
    if (await skip) continue;
    out = '$out-mid-$i';
    if (await stop) break;
    out = '$out-after-$i';
  }
  return out;
}

Future<String> asyncForAwaitGuardContinueBreakAwaitUpdate(
  int limit,
  Future<bool> skip,
  Future<bool> stop,
  Future<int> next,
) async {
  var out = 'base-for-await-guard-continue-break-await-update';
  for (var i = 0; limit > i; i = await next) {
    out = '$out-before-$i';
    if (await skip) continue;
    out = '$out-mid-$i';
    if (await stop) break;
    out = '$out-after-$i';
  }
  return out;
}

Future<String> asyncForAwaitConditionAwaitGuardContinueBreakAwaitUpdate(
  Future<bool> keepGoing,
  Future<bool> skip,
  Future<bool> stop,
  Future<int> next,
) async {
  var out = 'base-for-await-condition-guard-update';
  for (var i = 0; await keepGoing; i = await next) {
    out = '$out-before-$i';
    if (await skip) continue;
    out = '$out-mid-$i';
    if (await stop) break;
    out = '$out-after-$i';
  }
  return out;
}

Future<String> asyncForAwaitUpdate(int limit, Future<int> next) async {
  var out = 'base-for-await-update';
  for (var i = 0; limit > i; i = await next) {
    out = '$out-$i';
  }
  return out;
}

Future<String> asyncForAwaitUpdateBranchLocal(
  int limit,
  Future<int> next,
) async {
  var out = 'base-for-await-update-branch';
  for (var i = 0; limit > i; i = await next) {
    final segment = i == 1 ? 'one' : 'many';
    out = '$out-$segment-$i';
  }
  return out;
}

Future<String> asyncForNestedAwaitBranchLocal(
  int limit,
  bool premium,
  Future<String> ready,
) async {
  var out = 'base-for-nested-await-branch';
  for (var i = 0; limit > i; i = i + 1) {
    if (i == 0) {
      final state = await ready;
      if (premium) {
        final tier = 'base-for-nested-pro';
        out = '$out-$state-$tier';
      } else {
        final tier = 'base-for-nested-basic';
        out = '$out-$state-$tier';
      }
    } else {
      final state = 'base-for-nested-tail';
      out = '$out-$state-$i';
    }
  }
  return out;
}

Future<String> asyncForAwaitUpdateNestedBranchLocal(
  int limit,
  bool premium,
  Future<String> ready,
  Future<int> next,
) async {
  var out = 'base-for-await-update-nested-branch';
  for (var i = 0; limit > i; i = await next) {
    if (i == 0) {
      final state = await ready;
      if (premium) {
        final tier = 'base-for-await-update-nested-pro';
        out = '$out-$state-$tier';
      } else {
        final tier = 'base-for-await-update-nested-basic';
        out = '$out-$state-$tier';
      }
    } else {
      final state = 'base-for-await-update-nested-tail';
      out = '$out-$state-$i';
    }
  }
  return out;
}

Future<String> asyncForAwaitConditionAwaitUpdateNestedBranchLocal(
  Future<bool> keepGoing,
  bool premium,
  Future<String> ready,
  Future<int> next,
) async {
  var out = 'base-for-await-condition-update-nested-branch';
  for (var i = 0; await keepGoing; i = await next) {
    if (i == 0) {
      final state = await ready;
      if (premium) {
        final tier = 'base-for-await-condition-update-nested-pro';
        out = '$out-$state-$tier';
      } else {
        final tier = 'base-for-await-condition-update-nested-basic';
        out = '$out-$state-$tier';
      }
    } else {
      final state = 'base-for-await-condition-update-nested-tail';
      out = '$out-$state-$i';
    }
  }
  return out;
}

Future<String> asyncForTryFinallyAwaitGuard(
  int limit,
  Future<bool> skip,
  Future<String> cleanup,
) async {
  var out = 'base-for-try-finally-await-guard';
  for (var i = 0; limit > i; i = i + 1) {
    try {
      out = '$out-body-$i';
      if (await skip) {
        out = '$out-skip-$i';
      } else {
        out = '$out-tail-$i';
      }
    } finally {
      final marker = await cleanup;
      out = '$out-finally-$marker';
    }
  }
  return out;
}

Future<String> asyncForTryFinallyAwaitGuardAwaitUpdate(
  int limit,
  Future<bool> skip,
  Future<String> cleanup,
  Future<int> next,
) async {
  var out = 'base-for-try-finally-await-guard-update';
  for (var i = 0; limit > i; i = await next) {
    try {
      out = '$out-body-$i';
      if (await skip) {
        out = '$out-skip-$i';
      } else {
        out = '$out-tail-$i';
      }
    } finally {
      final marker = await cleanup;
      out = '$out-finally-$marker';
    }
  }
  return out;
}

Future<String> asyncForTryCatchAwaitGuard(int limit, Future<bool> fail) async {
  var out = 'base-for-try-catch-await-guard';
  for (var i = 0; limit > i; i = i + 1) {
    try {
      out = '$out-body-$i';
      if (await fail) throw 'base-for-catch-$i';
      out = '$out-tail-$i';
    } catch (e) {
      out = '$out-caught-$e';
    }
  }
  return out;
}

Future<String> asyncForTryCatchAwaitGuardAwaitUpdate(
  int limit,
  Future<bool> fail,
  Future<int> next,
) async {
  var out = 'base-for-try-catch-await-guard-update';
  for (var i = 0; limit > i; i = await next) {
    try {
      out = '$out-body-$i';
      if (await fail) throw 'base-for-catch-update-$i';
      out = '$out-tail-$i';
    } catch (e) {
      out = '$out-caught-$e';
    }
  }
  return out;
}

Future<String> asyncForAwaitConditionTryFinallyAwaitGuardAwaitUpdate(
  Future<bool> keepGoing,
  Future<bool> skip,
  Future<String> cleanup,
  Future<int> next,
) async {
  var out = 'base-for-await-condition-try-finally-update';
  for (var i = 0; await keepGoing; i = await next) {
    try {
      out = '$out-body-$i';
      if (await skip) {
        out = '$out-skip-$i';
      } else {
        out = '$out-tail-$i';
      }
    } finally {
      final marker = await cleanup;
      out = '$out-finally-$marker';
    }
  }
  return out;
}

Future<String> asyncForAwaitConditionTryCatchAwaitGuardAwaitUpdate(
  Future<bool> keepGoing,
  Future<bool> fail,
  Future<int> next,
) async {
  var out = 'base-for-await-condition-try-catch-update';
  for (var i = 0; await keepGoing; i = await next) {
    try {
      out = '$out-body-$i';
      if (await fail) throw 'base-for-await-condition-catch-update-$i';
      out = '$out-tail-$i';
    } catch (e) {
      out = '$out-caught-$e';
    }
  }
  return out;
}

Future<String> asyncForMultiUpdate(int limit) async {
  var out = 'base-for-multi-update';
  for (var i = 0, j = 0; limit > i; i = i + 1, j = j + 2) {
    out = '$out-$i-$j';
  }
  return out;
}

Future<String> asyncForMultiUpdateBranchLocal(
  int limit,
  Future<String> ready,
  bool premium,
) async {
  return 'base-for-multi-update-branch';
}

Future<String> asyncForAwaitConditionMultiUpdateBranchLocal(
  Future<bool> keepGoing,
  Future<String> ready,
  bool premium,
) async {
  return 'base-for-await-condition-multi-update-branch';
}

Future<String> asyncForMultiUpdateTryFinallyAwaitGuard(
  int limit,
  Future<bool> skip,
  Future<String> cleanup,
) async {
  return 'base-for-multi-update-try-finally';
}

Future<String> asyncForAwaitConditionMultiUpdateTryCatchAwaitGuard(
  Future<bool> keepGoing,
  Future<bool> fail,
) async {
  return 'base-for-await-condition-multi-update-try-catch';
}

Future<String> asyncWhileSwitchAssignedLabel(int limit, String tier) async {
  var i = 0;
  var out = 'base-while-switch-assigned';
  while (limit > i) {
    var label = 'base-while-switch-head';
    if (tier == 'gold') {
      label = 'base-while-switch-gold';
    }
    out = '$out-$label-$i';
    i = i + 1;
  }
  return out;
}

Future<String> asyncWhileAwaitConditionSwitchAssignedLabel(
  Future<bool> keepGoing,
  String tier,
) async {
  var i = 0;
  var out = 'base-while-await-condition-switch-assigned';
  while (await keepGoing) {
    var label = 'base-while-await-switch-head';
    if (tier == 'gold') {
      label = 'base-while-await-switch-gold';
    }
    out = '$out-$label-$i';
    i = i + 1;
  }
  return out;
}

Future<String> asyncForSwitchAssignedLabel(int limit, String tier) async {
  var out = 'base-for-switch-assigned';
  for (var i = 0; limit > i; i = i + 1) {
    var label = 'base-for-switch-head';
    if (tier == 'gold') {
      label = 'base-for-switch-gold';
    }
    out = '$out-$label-$i';
  }
  return out;
}

Future<String> asyncForAwaitUpdateSwitchAssignedLabel(
  int limit,
  String tier,
  Future<int> next,
) async {
  var out = 'base-for-await-update-switch-assigned';
  for (var i = 0; limit > i; i = await next) {
    var label = 'base-for-await-update-switch-head';
    if (tier == 'gold') {
      label = 'base-for-await-update-switch-gold';
    }
    out = '$out-$label-$i';
  }
  return out;
}

Future<List<String>> asyncForSwitchAssignedListNames(
  int limit,
  String tier,
) async {
  var out = 'base-for-switch-list';
  for (var i = 0; limit > i; i = i + 1) {
    var label = 'base-for-switch-list-head';
    if (tier == 'gold') {
      label = 'base-for-switch-list-gold';
    }
    out = '$out-$label-$i';
  }
  return [out, 'base-for-switch-list-tail'];
}

Future<Map<String, String>> asyncForSwitchAssignedMapLabels(
  int limit,
  int code,
) async {
  var out = 'base-for-switch-map';
  for (var i = 0; limit > i; i = i + 1) {
    var label = 'base-for-switch-map-head';
    if (code == 7) {
      label = 'base-for-switch-map-seven';
    }
    out = '$out-$label-$i';
  }
  return {'state': out};
}

Future<String> asyncDoWhileSwitchAssignedLabel(int limit, String tier) async {
  var i = 0;
  var out = 'base-do-while-switch-assigned';
  do {
    var label = 'base-do-while-switch-head';
    if (tier == 'gold') {
      label = 'base-do-while-switch-gold';
    }
    out = '$out-$label-$i';
    i = i + 1;
  } while (limit > i);
  return out;
}

Future<String> asyncWhileSwitchOrPatternAssignedLabel(
  int limit,
  String tier,
) async {
  var i = 0;
  var out = 'base-while-switch-or-assigned';
  while (limit > i) {
    var label = 'base-while-switch-or-head';
    if (tier == 'gold' || tier == 'vip') {
      label = 'base-while-switch-or-premium';
    }
    out = '$out-$label-$i';
    i = i + 1;
  }
  return out;
}

Future<String> asyncForAwaitUpdateSwitchOrPatternAssignedLabel(
  int limit,
  String tier,
  Future<int> next,
) async {
  var out = 'base-for-await-update-switch-or-assigned';
  for (var i = 0; limit > i; i = await next) {
    var label = 'base-for-await-update-switch-or-head';
    if (tier == 'gold' || tier == 'vip') {
      label = 'base-for-await-update-switch-or-premium';
    }
    out = '$out-$label-$i';
  }
  return out;
}

Future<String> asyncWhileNestedBranchSwitchAssignedLabel(
  int limit,
  String tier,
  bool enabled,
) async {
  var i = 0;
  var out = 'base-while-nested-switch-assigned';
  while (limit > i) {
    if (enabled) {
      var label = 'base-while-nested-switch-head';
      if (tier == 'gold') {
        label = 'base-while-nested-switch-gold';
      }
      out = '$out-$label-$i';
    } else {
      out = '$out-disabled-$i';
    }
    i = i + 1;
  }
  return out;
}

Future<String> asyncForTryCatchSwitchAssignedLabel(
  int limit,
  String tier,
) async {
  var out = 'base-for-try-catch-switch-assigned';
  for (var i = 0; limit > i; i = i + 1) {
    try {
      var label = 'base-for-try-catch-switch-head';
      if (tier == 'gold') {
        label = 'base-for-try-catch-switch-gold';
      } else {
        throw 'base-for-try-catch-switch-other-$i';
      }
      out = '$out-$label-$i';
    } catch (e) {
      out = '$out-caught-$e';
    }
  }
  return out;
}

Future<String> asyncForAwaitUpdateTryFinallySwitchAssignedLabel(
  int limit,
  String tier,
  Future<int> next,
  Future<String> cleanup,
) async {
  var out = 'base-for-await-update-try-finally-switch-assigned';
  for (var i = 0; limit > i; i = await next) {
    try {
      var label = 'base-for-await-update-try-finally-switch-head';
      if (tier == 'gold') {
        label = 'base-for-await-update-try-finally-switch-gold';
      }
      out = '$out-$label-$i';
    } finally {
      final marker = await cleanup;
      out = '$out-finally-$marker';
    }
  }
  return out;
}

Future<String> asyncWhileAwaitConditionTryCatchSwitchAssignedLabel(
  Future<bool> keepGoing,
  String tier,
) async {
  var i = 0;
  var out = 'base-while-await-condition-try-catch-switch-assigned';
  while (await keepGoing) {
    try {
      var label = 'base-while-await-condition-try-catch-switch-head';
      if (tier == 'gold') {
        label = 'base-while-await-condition-try-catch-switch-gold';
      } else {
        throw 'base-while-await-condition-try-catch-switch-other-$i';
      }
      out = '$out-$label-$i';
    } catch (e) {
      out = '$out-caught-$e';
    }
    i = i + 1;
  }
  return out;
}

Future<String> asyncWhileAwaitConditionTryCatchSwitchOrPatternAssignedLabel(
  Future<bool> keepGoing,
  String tier,
) async {
  var i = 0;
  var out = 'base-while-await-condition-try-catch-switch-or-assigned';
  while (await keepGoing) {
    try {
      var label = 'base-while-await-condition-try-catch-switch-or-head';
      if (tier == 'gold' || tier == 'vip') {
        label = 'base-while-await-condition-try-catch-switch-or-premium';
      } else {
        throw 'base-while-await-condition-try-catch-switch-or-other-$i';
      }
      out = '$out-$label-$i';
    } catch (e) {
      out = '$out-caught-$e';
    }
    i = i + 1;
  }
  return out;
}

Future<String> asyncDoWhileTryFinallySwitchAssignedLabel(
  int limit,
  String tier,
  Future<String> cleanup,
) async {
  var i = 0;
  var out = 'base-do-while-try-finally-switch-assigned';
  do {
    try {
      var label = 'base-do-while-try-finally-switch-head';
      if (tier == 'gold') {
        label = 'base-do-while-try-finally-switch-gold';
      }
      out = '$out-$label-$i';
    } finally {
      final marker = await cleanup;
      out = '$out-finally-$marker';
    }
    i = i + 1;
  } while (limit > i);
  return out;
}

Future<String> asyncDoWhileTryFinallySwitchOrPatternAssignedLabel(
  int limit,
  String tier,
  Future<String> cleanup,
) async {
  var i = 0;
  var out = 'base-do-while-try-finally-switch-or-assigned';
  do {
    try {
      var label = 'base-do-while-try-finally-switch-or-head';
      if (tier == 'gold' || tier == 'vip') {
        label = 'base-do-while-try-finally-switch-or-premium';
      }
      out = '$out-$label-$i';
    } finally {
      final marker = await cleanup;
      out = '$out-finally-$marker';
    }
    i = i + 1;
  } while (limit > i);
  return out;
}
