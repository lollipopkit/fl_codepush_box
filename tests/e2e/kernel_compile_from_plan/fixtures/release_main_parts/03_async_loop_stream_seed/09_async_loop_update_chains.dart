Future<String> asyncForAwaitConditionMultiAwaitUpdateTryFinallyBranchLocal(
  Future<bool> keepGoing,
  Future<int> nextI,
  Future<int> nextJ,
  Future<String> ready,
  Future<String> cleanup,
  bool premium,
) async {
  var out = 'base-for-await-condition-multi-await-update-try-finally-branch';
  for (var i = 0, j = 0; await keepGoing; i = await nextI, j = await nextJ) {
    if (premium) {
      final state = await ready;
      out = '$out-pro-$state-$i-$j';
    } else {
      out = '$out-basic-$i-$j';
    }
    final marker = await cleanup;
    out = '$out-finally-$marker';
  }
  return out;
}

Future<String> asyncForAwaitConditionMultiAwaitUpdateTryCatchBranchLocal(
  Future<bool> keepGoing,
  Future<int> nextI,
  Future<int> nextJ,
  Future<String> ready,
  Future<bool> fail,
  bool premium,
) async {
  var out = 'base-for-await-condition-multi-await-update-try-catch-branch';
  for (var i = 0, j = 0; await keepGoing; i = await nextI, j = await nextJ) {
    if (await fail) {
      out = '$out-error-$i-$j';
    } else if (premium) {
      final state = await ready;
      out = '$out-pro-$state-$i-$j';
    } else {
      out = '$out-basic-$i-$j';
    }
  }
  return out;
}

Future<String> asyncForMultiAwaitUpdateTryFinallyNestedBranchLocal(
  int limit,
  Future<int> nextI,
  Future<int> nextJ,
  Future<String> ready,
  Future<String> cleanup,
  bool premium,
) async {
  var out = 'base-for-multi-await-update-try-finally-nested';
  for (var i = 0, j = 0; limit > i; i = await nextI, j = await nextJ) {
    if (i == 0 && premium) {
      final state = await ready;
      out = '$out-pro-$state-$j';
    } else {
      out = '$out-basic-$i-$j';
    }
    final marker = await cleanup;
    out = '$out-finally-$marker';
  }
  return out;
}

Future<String> asyncForMultiAwaitUpdateTryCatchNestedBranchLocal(
  int limit,
  Future<int> nextI,
  Future<int> nextJ,
  Future<String> ready,
  Future<bool> fail,
  bool premium,
) async {
  var out = 'base-for-multi-await-update-try-catch-nested';
  for (var i = 0, j = 0; limit > i; i = await nextI, j = await nextJ) {
    if (await fail) {
      out = '$out-error-$i-$j';
    } else if (i == 0 && premium) {
      final state = await ready;
      out = '$out-pro-$state-$j';
    } else {
      out = '$out-basic-$i-$j';
    }
  }
  return out;
}

Future<String> asyncForAwaitConditionMultiAwaitUpdateSwitchExprBranchLocal(
  Future<bool> keepGoing,
  Future<int> nextI,
  Future<int> nextJ,
  Future<String> tierReady,
  bool premium,
) async {
  var out = 'base-for-await-condition-multi-await-update-switch-expr';
  for (var i = 0, j = 0; await keepGoing; i = await nextI, j = await nextJ) {
    final tier = await tierReady;
    if (premium && tier == 'gold') {
      out = '$out-pro-$i-$j';
    } else {
      out = '$out-basic-$i-$j';
    }
  }
  return out;
}

Future<String> asyncForAwaitConditionMultiAwaitUpdateSwitchTryFinally(
  Future<bool> keepGoing,
  Future<int> nextI,
  Future<int> nextJ,
  Future<String> tierReady,
  Future<String> cleanup,
) async {
  var out = 'base-for-await-condition-multi-await-update-switch-finally';
  for (var i = 0, j = 0; await keepGoing; i = await nextI, j = await nextJ) {
    final tier = await tierReady;
    out = '$out-$tier-$i-$j';
    final marker = await cleanup;
    out = '$out-finally-$marker';
  }
  return out;
}

Future<String> asyncForAwaitConditionMultiAwaitUpdateSwitchTryCatch(
  Future<bool> keepGoing,
  Future<int> nextI,
  Future<int> nextJ,
  Future<String> tierReady,
  Future<bool> fail,
) async {
  var out = 'base-for-await-condition-multi-await-update-switch-catch';
  for (var i = 0, j = 0; await keepGoing; i = await nextI, j = await nextJ) {
    if (await fail) {
      out = '$out-error-$i-$j';
    } else {
      final tier = await tierReady;
      out = '$out-$tier-$i-$j';
    }
  }
  return out;
}

Future<String> asyncForMultiAwaitUpdateSwitchStatementNestedBranchLocal(
  int limit,
  Future<int> nextI,
  Future<int> nextJ,
  Future<String> tierReady,
  bool premium,
) async {
  var out = 'base-for-multi-await-update-switch-stmt-nested';
  for (var i = 0, j = 0; limit > i; i = await nextI, j = await nextJ) {
    final tier = await tierReady;
    if (i == 0 && premium && tier == 'gold') {
      out = '$out-pro-$j';
    } else {
      out = '$out-basic-$i-$j';
    }
  }
  return out;
}

Future<String> asyncForMultiAwaitUpdateSwitchStatementTryFinallyNested(
  int limit,
  Future<int> nextI,
  Future<int> nextJ,
  Future<String> tierReady,
  Future<String> cleanup,
) async {
  var out = 'base-for-multi-await-update-switch-stmt-finally';
  for (var i = 0, j = 0; limit > i; i = await nextI, j = await nextJ) {
    final tier = await tierReady;
    out = '$out-$tier-$i-$j';
    final marker = await cleanup;
    out = '$out-finally-$marker';
  }
  return out;
}

Future<String> asyncForMultiAwaitUpdateSwitchStatementTryCatchNested(
  int limit,
  Future<int> nextI,
  Future<int> nextJ,
  Future<String> tierReady,
  Future<bool> fail,
) async {
  var out = 'base-for-multi-await-update-switch-stmt-catch';
  for (var i = 0, j = 0; limit > i; i = await nextI, j = await nextJ) {
    if (await fail) {
      out = '$out-error-$i-$j';
    } else {
      final tier = await tierReady;
      out = '$out-$tier-$i-$j';
    }
  }
  return out;
}

Future<String> asyncForAwaitConditionMultiAwaitUpdateNestedBranchTryFinally(
  Future<bool> keepGoing,
  Future<int> nextI,
  Future<int> nextJ,
  Future<String> ready,
  Future<String> cleanup,
  bool premium,
  bool special,
) async {
  var out = 'base-for-await-condition-multi-await-update-nested-finally';
  for (var i = 0, j = 0; await keepGoing; i = await nextI, j = await nextJ) {
    if (premium && special) {
      final state = await ready;
      out = '$out-special-$state-$i-$j';
    } else {
      out = '$out-basic-$i-$j';
    }
    final marker = await cleanup;
    out = '$out-finally-$marker';
  }
  return out;
}

Future<String> asyncForMultiAwaitUpdateTryCatchFinallyNestedBranchLocal(
  int limit,
  Future<int> nextI,
  Future<int> nextJ,
  Future<String> ready,
  Future<bool> fail,
  Future<String> cleanup,
  bool premium,
) async {
  var out = 'base-for-multi-await-update-try-catch-finally-nested';
  for (var i = 0, j = 0; limit > i; i = await nextI, j = await nextJ) {
    if (await fail) {
      out = '$out-error-$i-$j';
    } else if (i == 0 && premium) {
      final state = await ready;
      out = '$out-pro-$state-$j';
    } else {
      out = '$out-basic-$i-$j';
    }
    final marker = await cleanup;
    out = '$out-finally-$marker';
  }
  return out;
}

Future<String> asyncForAwaitConditionMultiAwaitUpdateSwitchExprNestedTryFinally(
  Future<bool> keepGoing,
  Future<int> nextI,
  Future<int> nextJ,
  Future<String> tierReady,
  Future<String> cleanup,
  bool premium,
) async {
  var out = 'base-for-await-condition-multi-await-update-switch-expr-nested';
  for (var i = 0, j = 0; await keepGoing; i = await nextI, j = await nextJ) {
    final tier = await tierReady;
    if (premium && tier == 'gold') {
      out = '$out-pro-$i-$j';
    } else {
      out = '$out-basic-$i-$j';
    }
    final marker = await cleanup;
    out = '$out-finally-$marker';
  }
  return out;
}

Future<String>
asyncForMultiAwaitUpdateSwitchStatementTryCatchFinallyNestedBranchLocal(
  int limit,
  Future<int> nextI,
  Future<int> nextJ,
  Future<String> tierReady,
  Future<bool> fail,
  Future<String> cleanup,
) async {
  var out = 'base-for-multi-await-update-switch-stmt-catch-finally-nested';
  for (var i = 0, j = 0; limit > i; i = await nextI, j = await nextJ) {
    if (await fail) {
      out = '$out-error-$i-$j';
    } else {
      final tier = await tierReady;
      out = '$out-$tier-$i-$j';
    }
    final marker = await cleanup;
    out = '$out-finally-$marker';
  }
  return out;
}

Future<String> asyncForAwaitConditionMultiAwaitUpdateContinueBreakTryFinally(
  Future<bool> keepGoing,
  Future<int> nextI,
  Future<int> nextJ,
  Future<bool> skip,
  Future<bool> stop,
  Future<String> cleanup,
) async {
  var out = 'base-for-await-condition-multi-await-update-continue-break';
  for (var i = 0, j = 0; await keepGoing; i = await nextI, j = await nextJ) {
    if (await skip) {
      out = '$out-skip-$i-$j';
    } else if (await stop) {
      out = '$out-stop-$i-$j';
    } else {
      out = '$out-body-$i-$j';
    }
    final marker = await cleanup;
    out = '$out-finally-$marker';
  }
  return out;
}

Future<String> asyncForMultiAwaitUpdateNestedSwitchExprTryCatchBranchLocal(
  int limit,
  Future<int> nextI,
  Future<int> nextJ,
  Future<String> tierReady,
  Future<bool> fail,
  bool premium,
) async {
  var out = 'base-for-multi-await-update-nested-switch-expr-catch';
  for (var i = 0, j = 0; limit > i; i = await nextI, j = await nextJ) {
    if (await fail) {
      out = '$out-error-$i-$j';
    } else if (premium) {
      final tier = await tierReady;
      out = '$out-$tier-$i-$j';
    } else {
      out = '$out-basic-$i-$j';
    }
  }
  return out;
}

Future<List<String>>
asyncForAwaitConditionMultiAwaitUpdateCollectionTryFinallyList(
  Future<bool> keepGoing,
  Future<int> nextI,
  Future<int> nextJ,
  Future<String> tierReady,
  Future<String> cleanup,
  List<String> extra,
) async {
  var out = <String>[
    'base-for-await-condition-multi-await-update-collection-list-head',
  ];
  for (var i = 0, j = 0; await keepGoing; i = await nextI, j = await nextJ) {
    final tier = await tierReady;
    out = [
      ...out,
      tier == 'gold'
          ? 'base-for-await-condition-multi-await-update-collection-list-premium'
          : 'base-for-await-condition-multi-await-update-collection-list-standard',
      for (final value in extra)
        'base-for-await-condition-multi-await-update-collection-list-extra-$value-$i-$j',
    ];
    final marker = await cleanup;
    out = [
      ...out,
      'base-for-await-condition-multi-await-update-collection-list-cleanup-$marker',
    ];
  }
  return out;
}

Future<Map<String, String>>
asyncForMultiAwaitUpdateCollectionTryCatchFinallyMap(
  int limit,
  Future<int> nextI,
  Future<int> nextJ,
  Future<String> tierReady,
  Future<bool> fail,
  Future<String> recovery,
  Future<String> cleanup,
  Map<String, String> extra,
) async {
  var out = <String, String>{
    'mode': 'base-for-multi-await-update-collection-map-head',
  };
  for (var i = 0, j = 0; limit > i; i = await nextI, j = await nextJ) {
    if (await fail) {
      final marker = await recovery;
      out = {
        ...out,
        'error': 'base-for-multi-await-update-collection-map-caught-$marker',
      };
    } else {
      final tier = await tierReady;
      out = {
        ...out,
        'state': tier == 'gold'
            ? 'base-for-multi-await-update-collection-map-premium'
            : 'base-for-multi-await-update-collection-map-standard',
        for (final entry in extra.entries)
          'base-for-multi-await-update-collection-map-extra-${entry.key}':
              '${entry.value}-$i-$j',
      };
    }
    final marker = await cleanup;
    out = {
      ...out,
      'cleanup': 'base-for-multi-await-update-collection-map-cleanup-$marker',
    };
  }
  return out;
}
