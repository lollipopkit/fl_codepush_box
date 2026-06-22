Future<String> asyncDoWhileLocal(int limit) async {
  var i = 0;
  var out = 'patched-do-while';
  do {
    out = '$out-$i';
    i = i + 1;
  } while (limit > i);
  return out;
}

Future<String> asyncDoWhileAwaitCondition(Future<bool> keepGoing) async {
  var i = 0;
  var out = 'patched-do-while-await';
  do {
    out = '$out-$i';
    i = i + 1;
  } while (await keepGoing);
  return out;
}

Future<String> asyncDoWhileBranchLocal(int limit) async {
  var i = 0;
  var out = 'patched-do-while-branch';
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
  var out = 'patched-do-while-await-branch';
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
  var out = 'patched-do-while-await-local';
  do {
    final segment = await ready;
    out = '$out-$segment-$i';
    i = i + 1;
  } while (await keepGoing);
  return out;
}

Future<String> asyncDoWhileBreak(int limit) async {
  var i = 0;
  var out = 'patched-do-while-break';
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
  var out = 'patched-do-while-continue';
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
  var out = 'patched-do-while-continue-break';
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
  var out = 'patched-do-while-await-guard-continue-break';
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
  var out = 'patched-do-while-await-guard-continue-break-await-condition';
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
  var out = 'patched-do-while-try-catch-await-guard';
  do {
    try {
      out = '$out-body-$i';
      if (await fail) throw 'patched-do-while-catch-$i';
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
  var out = 'patched-do-while-try-finally-await-guard';
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
  var out = 'patched-do-while-await-condition-try-catch';
  do {
    try {
      out = '$out-body-$i';
      if (await fail) throw 'patched-do-while-await-condition-catch-$i';
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
  var out = 'patched-do-while-await-condition-try-finally';
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
  var out = 'patched-while-try-catch-await-guard';
  while (limit > i) {
    try {
      out = '$out-body-$i';
      if (await fail) throw 'patched-while-catch-$i';
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
  var out = 'patched-while-try-finally-await-guard';
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
  var out = 'patched-while-await-condition-try-catch';
  while (await keepGoing) {
    try {
      out = '$out-body-$i';
      if (await fail) throw 'patched-while-await-condition-catch-$i';
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
  var out = 'patched-while-await-condition-try-finally';
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
  var out = 'patched-for';
  for (var i = 0; limit > i; i = i + 1) {
    out = '$out-$i';
  }
  return out;
}

Future<String> asyncForContinue(int limit) async {
  var out = 'patched-for-continue';
  for (var i = 0; limit > i; i = i + 1) {
    out = '$out-before-$i';
    if (i == 1) continue;
    out = '$out-after-$i';
  }
  return out;
}

Future<String> asyncForBreak(int limit) async {
  var out = 'patched-for-break';
  for (var i = 0; limit > i; i = i + 1) {
    out = '$out-before-$i';
    if (i == 1) break;
    out = '$out-after-$i';
  }
  return out;
}

Future<String> asyncForContinueBreak(int limit) async {
  var out = 'patched-for-continue-break';
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
  var out = 'patched-for-await-guard-continue-break';
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
  var out = 'patched-for-await-guard-continue-break-await-update';
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
  var out = 'patched-for-await-condition-guard-update';
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
  var out = 'patched-for-await-update';
  for (var i = 0; limit > i; i = await next) {
    out = '$out-$i';
  }
  return out;
}

Future<String> asyncForAwaitUpdateBranchLocal(
  int limit,
  Future<int> next,
) async {
  var out = 'patched-for-await-update-branch';
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
  var out = 'patched-for-nested-await-branch';
  for (var i = 0; limit > i; i = i + 1) {
    if (i == 0) {
      final state = await ready;
      if (premium) {
        final tier = 'patched-for-nested-pro';
        out = '$out-$state-$tier';
      } else {
        final tier = 'patched-for-nested-basic';
        out = '$out-$state-$tier';
      }
    } else {
      final state = 'patched-for-nested-tail';
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
  var out = 'patched-for-await-update-nested-branch';
  for (var i = 0; limit > i; i = await next) {
    if (i == 0) {
      final state = await ready;
      if (premium) {
        final tier = 'patched-for-await-update-nested-pro';
        out = '$out-$state-$tier';
      } else {
        final tier = 'patched-for-await-update-nested-basic';
        out = '$out-$state-$tier';
      }
    } else {
      final state = 'patched-for-await-update-nested-tail';
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
  var out = 'patched-for-await-condition-update-nested-branch';
  for (var i = 0; await keepGoing; i = await next) {
    if (i == 0) {
      final state = await ready;
      if (premium) {
        final tier = 'patched-for-await-condition-update-nested-pro';
        out = '$out-$state-$tier';
      } else {
        final tier = 'patched-for-await-condition-update-nested-basic';
        out = '$out-$state-$tier';
      }
    } else {
      final state = 'patched-for-await-condition-update-nested-tail';
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
  var out = 'patched-for-try-finally-await-guard';
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
  var out = 'patched-for-try-finally-await-guard-update';
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
  var out = 'patched-for-try-catch-await-guard';
  for (var i = 0; limit > i; i = i + 1) {
    try {
      out = '$out-body-$i';
      if (await fail) throw 'patched-for-catch-$i';
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
  var out = 'patched-for-try-catch-await-guard-update';
  for (var i = 0; limit > i; i = await next) {
    try {
      out = '$out-body-$i';
      if (await fail) throw 'patched-for-catch-update-$i';
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
  var out = 'patched-for-await-condition-try-finally-update';
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
  var out = 'patched-for-await-condition-try-catch-update';
  for (var i = 0; await keepGoing; i = await next) {
    try {
      out = '$out-body-$i';
      if (await fail) throw 'patched-for-await-condition-catch-update-$i';
      out = '$out-tail-$i';
    } catch (e) {
      out = '$out-caught-$e';
    }
  }
  return out;
}

Future<String> asyncForMultiUpdate(int limit) async {
  var out = 'patched-for-multi-update';
  for (var i = 0, j = 0; limit > i; i = i + 1, j = j + 2) {
    out = '$out-$i-$j';
  }
  return out;
}
