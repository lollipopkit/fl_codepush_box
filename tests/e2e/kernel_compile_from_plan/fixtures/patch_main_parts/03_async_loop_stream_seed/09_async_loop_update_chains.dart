Future<String> asyncForAwaitConditionMultiAwaitUpdateTryFinallyBranchLocal(
  Future<bool> keepGoing,
  Future<int> nextI,
  Future<int> nextJ,
  Future<String> ready,
  Future<String> cleanup,
  bool premium,
) async {
  var out = 'patched-for-await-condition-multi-await-update-try-finally-branch';
  for (var i = 0, j = 0; await keepGoing; i = await nextI, j = await nextJ) {
    try {
      if (premium) {
        final state = await ready;
        final tier =
            'patched-for-await-condition-multi-await-update-try-finally-pro';
        out = '$out-$tier-$state-$i-$j';
      } else {
        final state =
            'patched-for-await-condition-multi-await-update-try-finally-basic';
        out = '$out-$state-$i-$j';
      }
    } finally {
      final marker = await cleanup;
      out = '$out-finally-$marker';
    }
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
  var out = 'patched-for-await-condition-multi-await-update-try-catch-branch';
  for (var i = 0, j = 0; await keepGoing; i = await nextI, j = await nextJ) {
    try {
      if (await fail) {
        throw 'patched-for-await-condition-multi-await-update-try-catch-error-$i-$j';
      }
      if (premium) {
        final state = await ready;
        final tier =
            'patched-for-await-condition-multi-await-update-try-catch-pro';
        out = '$out-$tier-$state-$i-$j';
      } else {
        final state =
            'patched-for-await-condition-multi-await-update-try-catch-basic';
        out = '$out-$state-$i-$j';
      }
    } catch (e) {
      out = '$out-caught-$e';
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
  var out = 'patched-for-multi-await-update-try-finally-nested';
  for (var i = 0, j = 0; limit > i; i = await nextI, j = await nextJ) {
    try {
      if (i == 0) {
        if (premium) {
          final state = await ready;
          out =
              '$out-patched-for-multi-await-update-try-finally-nested-pro-$state-$j';
        } else {
          out =
              '$out-patched-for-multi-await-update-try-finally-nested-basic-$j';
        }
      } else {
        out =
            '$out-patched-for-multi-await-update-try-finally-nested-tail-$i-$j';
      }
    } finally {
      final marker = await cleanup;
      out = '$out-finally-$marker';
    }
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
  var out = 'patched-for-multi-await-update-try-catch-nested';
  for (var i = 0, j = 0; limit > i; i = await nextI, j = await nextJ) {
    try {
      if (await fail) {
        throw 'patched-for-multi-await-update-try-catch-nested-error-$i-$j';
      }
      if (i == 0) {
        if (premium) {
          final state = await ready;
          out =
              '$out-patched-for-multi-await-update-try-catch-nested-pro-$state-$j';
        } else {
          out = '$out-patched-for-multi-await-update-try-catch-nested-basic-$j';
        }
      } else {
        out = '$out-patched-for-multi-await-update-try-catch-nested-tail-$i-$j';
      }
    } catch (e) {
      out = '$out-caught-$e';
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
  var out = 'patched-for-await-condition-multi-await-update-switch-expr';
  for (var i = 0, j = 0; await keepGoing; i = await nextI, j = await nextJ) {
    final tier = await tierReady;
    if (premium) {
      final label = switch (tier) {
        'gold' || 'vip' =>
          'patched-for-await-condition-multi-await-update-switch-expr-pro',
        _ =>
          'patched-for-await-condition-multi-await-update-switch-expr-standard',
      };
      out = '$out-$label-$i-$j';
    } else {
      out =
          '$out-patched-for-await-condition-multi-await-update-switch-expr-basic-$i-$j';
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
  var out = 'patched-for-await-condition-multi-await-update-switch-finally';
  for (var i = 0, j = 0; await keepGoing; i = await nextI, j = await nextJ) {
    try {
      final tier = await tierReady;
      final label = switch (tier) {
        'gold' || 'vip' =>
          'patched-for-await-condition-multi-await-update-switch-finally-pro',
        _ =>
          'patched-for-await-condition-multi-await-update-switch-finally-basic',
      };
      out = '$out-$label-$i-$j';
    } finally {
      final marker = await cleanup;
      out = '$out-finally-$marker';
    }
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
  var out = 'patched-for-await-condition-multi-await-update-switch-catch';
  for (var i = 0, j = 0; await keepGoing; i = await nextI, j = await nextJ) {
    try {
      if (await fail) {
        throw 'patched-for-await-condition-multi-await-update-switch-catch-error-$i-$j';
      }
      final tier = await tierReady;
      final label = switch (tier) {
        'gold' || 'vip' =>
          'patched-for-await-condition-multi-await-update-switch-catch-pro',
        _ =>
          'patched-for-await-condition-multi-await-update-switch-catch-basic',
      };
      out = '$out-$label-$i-$j';
    } catch (e) {
      out = '$out-caught-$e';
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
  var out = 'patched-for-multi-await-update-switch-stmt-nested';
  for (var i = 0, j = 0; limit > i; i = await nextI, j = await nextJ) {
    if (i == 0) {
      final tier = await tierReady;
      switch (tier) {
        case 'gold' || 'vip':
          if (premium) {
            out = '$out-patched-for-multi-await-update-switch-stmt-pro-$j';
          } else {
            out = '$out-patched-for-multi-await-update-switch-stmt-standard-$j';
          }
          break;
        default:
          out = '$out-patched-for-multi-await-update-switch-stmt-basic-$j';
      }
    } else {
      out = '$out-patched-for-multi-await-update-switch-stmt-tail-$i-$j';
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
  var out = 'patched-for-multi-await-update-switch-stmt-finally';
  for (var i = 0, j = 0; limit > i; i = await nextI, j = await nextJ) {
    try {
      final tier = await tierReady;
      switch (tier) {
        case 'gold' || 'vip':
          out =
              '$out-patched-for-multi-await-update-switch-stmt-finally-pro-$j';
          break;
        default:
          out =
              '$out-patched-for-multi-await-update-switch-stmt-finally-basic-$i-$j';
      }
    } finally {
      final marker = await cleanup;
      out = '$out-finally-$marker';
    }
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
  var out = 'patched-for-multi-await-update-switch-stmt-catch';
  for (var i = 0, j = 0; limit > i; i = await nextI, j = await nextJ) {
    try {
      if (await fail) {
        throw 'patched-for-multi-await-update-switch-stmt-catch-error-$i-$j';
      }
      final tier = await tierReady;
      switch (tier) {
        case 'gold' || 'vip':
          out = '$out-patched-for-multi-await-update-switch-stmt-catch-pro-$j';
          break;
        default:
          out =
              '$out-patched-for-multi-await-update-switch-stmt-catch-basic-$i-$j';
      }
    } catch (e) {
      out = '$out-caught-$e';
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
  var out = 'patched-for-await-condition-multi-await-update-nested-finally';
  for (var i = 0, j = 0; await keepGoing; i = await nextI, j = await nextJ) {
    try {
      if (premium) {
        if (special) {
          final state = await ready;
          out =
              '$out-patched-for-await-condition-multi-await-update-nested-finally-special-$state-$i-$j';
        } else {
          out =
              '$out-patched-for-await-condition-multi-await-update-nested-finally-premium-$i-$j';
        }
      } else {
        out =
            '$out-patched-for-await-condition-multi-await-update-nested-finally-basic-$i-$j';
      }
    } finally {
      final marker = await cleanup;
      out = '$out-finally-$marker';
    }
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
  var out = 'patched-for-multi-await-update-try-catch-finally-nested';
  for (var i = 0, j = 0; limit > i; i = await nextI, j = await nextJ) {
    try {
      if (await fail) {
        throw 'patched-for-multi-await-update-try-catch-finally-error-$i-$j';
      }
      if (i == 0) {
        if (premium) {
          final state = await ready;
          out =
              '$out-patched-for-multi-await-update-try-catch-finally-pro-$state-$j';
        } else {
          out =
              '$out-patched-for-multi-await-update-try-catch-finally-basic-$j';
        }
      } else {
        out =
            '$out-patched-for-multi-await-update-try-catch-finally-tail-$i-$j';
      }
    } catch (e) {
      out = '$out-caught-$e';
    } finally {
      final marker = await cleanup;
      out = '$out-finally-$marker';
    }
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
  var out =
      'patched-for-await-condition-multi-await-update-switch-expr-nested-finally';
  for (var i = 0, j = 0; await keepGoing; i = await nextI, j = await nextJ) {
    try {
      if (premium) {
        final tier = await tierReady;
        final label = switch (tier) {
          'gold' || 'vip' =>
            'patched-for-await-condition-multi-await-update-switch-expr-nested-finally-pro',
          _ =>
            'patched-for-await-condition-multi-await-update-switch-expr-nested-finally-standard',
        };
        out = '$out-$label-$i-$j';
      } else {
        out =
            '$out-patched-for-await-condition-multi-await-update-switch-expr-nested-finally-basic-$i-$j';
      }
    } finally {
      final marker = await cleanup;
      out = '$out-finally-$marker';
    }
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
  var out = 'patched-for-multi-await-update-switch-stmt-catch-finally-nested';
  for (var i = 0, j = 0; limit > i; i = await nextI, j = await nextJ) {
    try {
      if (await fail) {
        throw 'patched-for-multi-await-update-switch-stmt-catch-finally-error-$i-$j';
      }
      final tier = await tierReady;
      switch (tier) {
        case 'gold' || 'vip':
          out =
              '$out-patched-for-multi-await-update-switch-stmt-catch-finally-pro-$j';
          break;
        default:
          out =
              '$out-patched-for-multi-await-update-switch-stmt-catch-finally-basic-$i-$j';
      }
    } catch (e) {
      out = '$out-caught-$e';
    } finally {
      final marker = await cleanup;
      out = '$out-finally-$marker';
    }
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
  var out = 'patched-for-await-condition-multi-await-update-continue-break';
  for (var i = 0, j = 0; await keepGoing; i = await nextI, j = await nextJ) {
    try {
      if (await skip) continue;
      if (await stop) break;
      out = '$out-body-$i-$j';
    } finally {
      final marker = await cleanup;
      out = '$out-finally-$marker';
    }
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
  var out = 'patched-for-multi-await-update-nested-switch-expr-catch';
  for (var i = 0, j = 0; limit > i; i = await nextI, j = await nextJ) {
    try {
      if (await fail) {
        throw 'patched-for-multi-await-update-nested-switch-expr-catch-error-$i-$j';
      }
      if (premium) {
        final tier = await tierReady;
        final label = switch (tier) {
          'gold' || 'vip' =>
            'patched-for-multi-await-update-nested-switch-expr-catch-pro',
          _ =>
            'patched-for-multi-await-update-nested-switch-expr-catch-standard',
        };
        out = '$out-$label-$i-$j';
      } else {
        out =
            '$out-patched-for-multi-await-update-nested-switch-expr-catch-basic-$i-$j';
      }
    } catch (e) {
      out = '$out-caught-$e';
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
    'patched-for-await-condition-multi-await-update-collection-list-head',
  ];
  for (var i = 0, j = 0; await keepGoing; i = await nextI, j = await nextJ) {
    try {
      final tier = await tierReady;
      out = [
        ...out,
        ...switch (tier) {
          'gold' || 'vip' => [
            'patched-for-await-condition-multi-await-update-collection-list-premium',
          ],
          _ => [
            'patched-for-await-condition-multi-await-update-collection-list-standard',
          ],
        },
        for (final value in extra)
          'patched-for-await-condition-multi-await-update-collection-list-extra-$value-$i-$j',
      ];
    } finally {
      final marker = await cleanup;
      out = [
        ...out,
        'patched-for-await-condition-multi-await-update-collection-list-cleanup-$marker',
      ];
    }
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
    'mode': 'patched-for-multi-await-update-collection-map-head',
  };
  for (var i = 0, j = 0; limit > i; i = await nextI, j = await nextJ) {
    try {
      if (await fail) {
        throw 'patched-for-multi-await-update-collection-map-error-$i-$j';
      }
      final tier = await tierReady;
      out = {
        ...out,
        ...switch (tier) {
          'gold' || 'vip' => {
            'state': 'patched-for-multi-await-update-collection-map-premium',
          },
          _ => {
            'state': 'patched-for-multi-await-update-collection-map-standard',
          },
        },
        for (final entry in extra.entries)
          'patched-for-multi-await-update-collection-map-extra-${entry.key}':
              '${entry.value}-$i-$j',
      };
    } catch (e) {
      final marker = await recovery;
      out = {
        ...out,
        'error':
            'patched-for-multi-await-update-collection-map-caught-$marker-$e',
      };
    } finally {
      final marker = await cleanup;
      out = {
        ...out,
        'cleanup':
            'patched-for-multi-await-update-collection-map-cleanup-$marker',
      };
    }
  }
  return out;
}
