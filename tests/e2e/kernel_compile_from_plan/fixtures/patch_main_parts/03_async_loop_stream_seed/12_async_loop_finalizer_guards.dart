Future<String> asyncWhileTryFinallyAwaitGuardContinueBreak(
  int limit,
  Future<bool> skip,
  Future<bool> stop,
  Future<String> cleanup,
) async {
  var i = 0;
  var out = 'patched-while-finalizer-guard';
  while (i < limit) {
    try {
      if (await skip) continue;
      if (await stop) break;
      out = '$out-body-$i';
      i = i + 1;
    } finally {
      final marker = await cleanup;
      out = '$out-finally-$marker';
    }
  }
  return out;
}

Future<String> asyncWhileAwaitConditionTryFinallyAwaitGuardContinueBreak(
  Future<bool> keepGoing,
  Future<bool> skip,
  Future<bool> stop,
  Future<String> cleanup,
) async {
  var out = 'patched-while-await-condition-finalizer-guard';
  while (await keepGoing) {
    try {
      if (await skip) continue;
      if (await stop) break;
      out = '$out-body';
    } finally {
      final marker = await cleanup;
      out = '$out-finally-$marker';
    }
  }
  return out;
}

Future<String> asyncWhileNestedTryFinallyAwaitGuardContinueBreak(
  int limit,
  Future<bool> skip,
  Future<bool> stop,
  Future<String> ready,
  Future<String> cleanup,
  bool premium,
) async {
  var i = 0;
  var out = 'patched-while-nested-finalizer-guard';
  while (i < limit) {
    try {
      if (await skip) continue;
      if (await stop) break;
      if (premium) {
        final state = await ready;
        out = '$out-premium-$state-$i';
      } else {
        out = '$out-basic-$i';
      }
      i = i + 1;
    } finally {
      final marker = await cleanup;
      out = '$out-finally-$marker';
    }
  }
  return out;
}

Future<String> asyncWhileTryCatchFinallyAwaitGuardContinueBreak(
  int limit,
  Future<bool> skip,
  Future<bool> stop,
  Future<bool> fail,
  Future<String> cleanup,
) async {
  var i = 0;
  var out = 'patched-while-catch-finalizer-guard';
  while (i < limit) {
    try {
      try {
        if (await skip) continue;
        if (await stop) break;
        if (await fail) {
          throw 'patched-while-catch-finalizer-guard-error-$i';
        }
        out = '$out-body-$i';
        i = i + 1;
      } catch (e) {
        out = '$out-caught-$e';
      }
    } finally {
      final marker = await cleanup;
      out = '$out-finally-$marker';
    }
  }
  return out;
}

Future<String> asyncDoWhileTryFinallyAwaitGuardContinueBreak(
  int limit,
  Future<bool> skip,
  Future<bool> stop,
  Future<String> cleanup,
) async {
  var i = 0;
  var out = 'patched-do-finalizer-guard';
  do {
    try {
      if (await skip) continue;
      if (await stop) break;
      out = '$out-body-$i';
      i = i + 1;
    } finally {
      final marker = await cleanup;
      out = '$out-finally-$marker';
    }
  } while (i < limit);
  return out;
}

Future<String> asyncDoWhileAwaitConditionTryFinallyAwaitGuardContinueBreak(
  Future<bool> keepGoing,
  Future<bool> skip,
  Future<bool> stop,
  Future<String> cleanup,
) async {
  var out = 'patched-do-await-condition-finalizer-guard';
  do {
    try {
      if (await skip) continue;
      if (await stop) break;
      out = '$out-body';
    } finally {
      final marker = await cleanup;
      out = '$out-finally-$marker';
    }
  } while (await keepGoing);
  return out;
}

Future<String> asyncDoWhileNestedTryFinallyAwaitGuardContinueBreak(
  int limit,
  Future<bool> skip,
  Future<bool> stop,
  Future<String> ready,
  Future<String> cleanup,
  bool premium,
) async {
  var i = 0;
  var out = 'patched-do-nested-finalizer-guard';
  do {
    try {
      if (await skip) continue;
      if (await stop) break;
      if (premium) {
        final state = await ready;
        out = '$out-premium-$state-$i';
      } else {
        out = '$out-basic-$i';
      }
      i = i + 1;
    } finally {
      final marker = await cleanup;
      out = '$out-finally-$marker';
    }
  } while (i < limit);
  return out;
}

Future<String> asyncDoWhileTryCatchFinallyAwaitGuardContinueBreak(
  int limit,
  Future<bool> skip,
  Future<bool> stop,
  Future<bool> fail,
  Future<String> cleanup,
) async {
  var i = 0;
  var out = 'patched-do-catch-finalizer-guard';
  do {
    try {
      try {
        if (await skip) continue;
        if (await stop) break;
        if (await fail) {
          throw 'patched-do-catch-finalizer-guard-error-$i';
        }
        out = '$out-body-$i';
        i = i + 1;
      } catch (e) {
        out = '$out-caught-$e';
      }
    } finally {
      final marker = await cleanup;
      out = '$out-finally-$marker';
    }
  } while (i < limit);
  return out;
}

Future<String> asyncWhileSwitchTryFinallyAwaitGuardContinueBreak(
  int limit,
  String tier,
  Future<bool> skip,
  Future<bool> stop,
  Future<String> cleanup,
) async {
  var i = 0;
  var out = 'patched-while-switch-finalizer-guard';
  while (i < limit) {
    try {
      if (await skip) continue;
      if (await stop) break;
      var label = 'patched-while-switch-finalizer-head';
      switch (tier) {
        case 'gold':
          label = 'patched-while-switch-finalizer-gold';
          break;
        case 'silver':
          label = 'patched-while-switch-finalizer-silver';
          break;
        default:
          label = 'patched-while-switch-finalizer-other';
      }
      out = '$out-$label-$i';
      i = i + 1;
    } finally {
      final marker = await cleanup;
      out = '$out-finally-$marker';
    }
  }
  return out;
}

Future<String> asyncDoWhileSwitchTryFinallyAwaitGuardContinueBreak(
  int limit,
  String tier,
  Future<bool> skip,
  Future<bool> stop,
  Future<String> cleanup,
) async {
  var i = 0;
  var out = 'patched-do-switch-finalizer-guard';
  do {
    try {
      if (await skip) continue;
      if (await stop) break;
      var label = 'patched-do-switch-finalizer-head';
      switch (tier) {
        case 'gold':
          label = 'patched-do-switch-finalizer-gold';
          break;
        case 'silver':
          label = 'patched-do-switch-finalizer-silver';
          break;
        default:
          label = 'patched-do-switch-finalizer-other';
      }
      out = '$out-$label-$i';
      i = i + 1;
    } finally {
      final marker = await cleanup;
      out = '$out-finally-$marker';
    }
  } while (i < limit);
  return out;
}

Future<String> asyncWhileSwitchOrPatternTryFinallyAwaitGuardContinueBreak(
  int limit,
  String tier,
  Future<bool> skip,
  Future<bool> stop,
  Future<String> cleanup,
) async {
  var i = 0;
  var out = 'patched-while-switch-or-finalizer-guard';
  while (i < limit) {
    try {
      if (await skip) continue;
      if (await stop) break;
      var label = 'patched-while-switch-or-finalizer-head';
      switch (tier) {
        case 'gold' || 'vip':
          label = 'patched-while-switch-or-finalizer-premium';
          break;
        case 'silver' || 'trial':
          label = 'patched-while-switch-or-finalizer-limited';
          break;
        default:
          label = 'patched-while-switch-or-finalizer-other';
      }
      out = '$out-$label-$i';
      i = i + 1;
    } finally {
      final marker = await cleanup;
      out = '$out-finally-$marker';
    }
  }
  return out;
}

Future<String> asyncDoWhileSwitchOrPatternTryFinallyAwaitGuardContinueBreak(
  int limit,
  String tier,
  Future<bool> skip,
  Future<bool> stop,
  Future<String> cleanup,
) async {
  var i = 0;
  var out = 'patched-do-switch-or-finalizer-guard';
  do {
    try {
      if (await skip) continue;
      if (await stop) break;
      var label = 'patched-do-switch-or-finalizer-head';
      switch (tier) {
        case 'gold' || 'vip':
          label = 'patched-do-switch-or-finalizer-premium';
          break;
        case 'silver' || 'trial':
          label = 'patched-do-switch-or-finalizer-limited';
          break;
        default:
          label = 'patched-do-switch-or-finalizer-other';
      }
      out = '$out-$label-$i';
      i = i + 1;
    } finally {
      final marker = await cleanup;
      out = '$out-finally-$marker';
    }
  } while (i < limit);
  return out;
}

Future<List<String>> asyncWhileCollectionTryFinallyAwaitGuardContinueBreak(
  int limit,
  Future<bool> skip,
  Future<bool> stop,
  Future<String> cleanup,
) async {
  var i = 0;
  var out = <String>['patched-while-collection-finalizer-head'];
  while (i < limit) {
    try {
      if (await skip) continue;
      if (await stop) break;
      out = [...out, 'patched-while-collection-finalizer-body-$i'];
      i = i + 1;
    } finally {
      final marker = await cleanup;
      out = [...out, 'patched-while-collection-finalizer-cleanup-$marker'];
    }
  }
  return out;
}

Future<List<String>> asyncDoWhileCollectionTryFinallyAwaitGuardContinueBreak(
  int limit,
  Future<bool> skip,
  Future<bool> stop,
  Future<String> cleanup,
) async {
  var i = 0;
  var out = <String>['patched-do-collection-finalizer-head'];
  do {
    try {
      if (await skip) continue;
      if (await stop) break;
      out = [...out, 'patched-do-collection-finalizer-body-$i'];
      i = i + 1;
    } finally {
      final marker = await cleanup;
      out = [...out, 'patched-do-collection-finalizer-cleanup-$marker'];
    }
  } while (i < limit);
  return out;
}

Future<Map<String, String>>
asyncWhileMapCollectionTryFinallyAwaitGuardContinueBreak(
  int limit,
  Future<bool> skip,
  Future<bool> stop,
  Future<String> cleanup,
) async {
  var i = 0;
  var out = <String, String>{'mode': 'patched-while-map-finalizer-head'};
  while (i < limit) {
    try {
      if (await skip) continue;
      if (await stop) break;
      out = {...out, 'body': 'patched-while-map-finalizer-body-$i'};
      i = i + 1;
    } finally {
      final marker = await cleanup;
      out = {...out, 'cleanup': 'patched-while-map-finalizer-cleanup-$marker'};
    }
  }
  return out;
}

Future<Map<String, String>>
asyncDoWhileMapCollectionTryFinallyAwaitGuardContinueBreak(
  int limit,
  Future<bool> skip,
  Future<bool> stop,
  Future<String> cleanup,
) async {
  var i = 0;
  var out = <String, String>{'mode': 'patched-do-map-finalizer-head'};
  do {
    try {
      if (await skip) continue;
      if (await stop) break;
      out = {...out, 'body': 'patched-do-map-finalizer-body-$i'};
      i = i + 1;
    } finally {
      final marker = await cleanup;
      out = {...out, 'cleanup': 'patched-do-map-finalizer-cleanup-$marker'};
    }
  } while (i < limit);
  return out;
}

Future<List<String>>
asyncWhileCollectionSwitchForTryFinallyAwaitGuardContinueBreak(
  int limit,
  String tier,
  Future<bool> skip,
  Future<bool> stop,
  Future<String> cleanup,
  List<String> extra,
) async {
  var i = 0;
  var out = <String>['patched-while-collection-switch-finalizer-head'];
  while (i < limit) {
    try {
      if (await skip) continue;
      if (await stop) break;
      out = [
        ...out,
        ...switch (tier) {
          'gold' ||
          'vip' => ['patched-while-collection-switch-finalizer-premium'],
          _ => ['patched-while-collection-switch-finalizer-standard'],
        },
        for (final value in extra)
          'patched-while-collection-switch-finalizer-extra-$value-$i',
      ];
      i = i + 1;
    } finally {
      final marker = await cleanup;
      out = [
        ...out,
        'patched-while-collection-switch-finalizer-cleanup-$marker',
      ];
    }
  }
  return out;
}

Future<List<String>>
asyncDoWhileCollectionSwitchForTryFinallyAwaitGuardContinueBreak(
  int limit,
  String tier,
  Future<bool> skip,
  Future<bool> stop,
  Future<String> cleanup,
  List<String> extra,
) async {
  var i = 0;
  var out = <String>['patched-do-collection-switch-finalizer-head'];
  do {
    try {
      if (await skip) continue;
      if (await stop) break;
      out = [
        ...out,
        ...switch (tier) {
          'gold' || 'vip' => ['patched-do-collection-switch-finalizer-premium'],
          _ => ['patched-do-collection-switch-finalizer-standard'],
        },
        for (final value in extra)
          'patched-do-collection-switch-finalizer-extra-$value-$i',
      ];
      i = i + 1;
    } finally {
      final marker = await cleanup;
      out = [...out, 'patched-do-collection-switch-finalizer-cleanup-$marker'];
    }
  } while (i < limit);
  return out;
}

Future<Map<String, String>>
asyncWhileMapSwitchForTryCatchFinallyAwaitGuardContinueBreak(
  int limit,
  String tier,
  Future<bool> skip,
  Future<bool> stop,
  Future<bool> fail,
  Future<String> cleanup,
  Map<String, String> extra,
) async {
  var i = 0;
  var out = <String, String>{'mode': 'patched-while-map-switch-finalizer-head'};
  while (i < limit) {
    try {
      try {
        if (await skip) continue;
        if (await stop) break;
        if (await fail) {
          throw 'patched-while-map-switch-finalizer-error-$i';
        }
        out = {
          ...out,
          ...switch (tier) {
            'gold' ||
            'vip' => {'state': 'patched-while-map-switch-finalizer-premium'},
            _ => {'state': 'patched-while-map-switch-finalizer-standard'},
          },
          for (final entry in extra.entries)
            'patched-while-map-switch-finalizer-extra-${entry.key}':
                entry.value,
        };
        i = i + 1;
      } catch (e) {
        out = {...out, 'error': 'patched-while-map-switch-finalizer-caught-$e'};
      }
    } finally {
      final marker = await cleanup;
      out = {
        ...out,
        'cleanup': 'patched-while-map-switch-finalizer-cleanup-$marker',
      };
    }
  }
  return out;
}

Future<Map<String, String>>
asyncDoWhileMapSwitchForTryCatchFinallyAwaitGuardContinueBreak(
  int limit,
  String tier,
  Future<bool> skip,
  Future<bool> stop,
  Future<bool> fail,
  Future<String> cleanup,
  Map<String, String> extra,
) async {
  var i = 0;
  var out = <String, String>{'mode': 'patched-do-map-switch-finalizer-head'};
  do {
    try {
      try {
        if (await skip) continue;
        if (await stop) break;
        if (await fail) {
          throw 'patched-do-map-switch-finalizer-error-$i';
        }
        out = {
          ...out,
          ...switch (tier) {
            'gold' ||
            'vip' => {'state': 'patched-do-map-switch-finalizer-premium'},
            _ => {'state': 'patched-do-map-switch-finalizer-standard'},
          },
          for (final entry in extra.entries)
            'patched-do-map-switch-finalizer-extra-${entry.key}': entry.value,
        };
        i = i + 1;
      } catch (e) {
        out = {...out, 'error': 'patched-do-map-switch-finalizer-caught-$e'};
      }
    } finally {
      final marker = await cleanup;
      out = {
        ...out,
        'cleanup': 'patched-do-map-switch-finalizer-cleanup-$marker',
      };
    }
  } while (i < limit);
  return out;
}

Future<List<String>>
asyncWhileAwaitConditionCollectionSwitchTryFinallyAwaitGuardContinueBreak(
  Future<bool> keepGoing,
  String tier,
  Future<bool> skip,
  Future<bool> stop,
  Future<String> cleanup,
  List<String> extra,
) async {
  var out = <String>[
    'patched-while-await-condition-collection-switch-finalizer-head',
  ];
  while (await keepGoing) {
    try {
      if (await skip) continue;
      if (await stop) break;
      out = [
        ...out,
        ...switch (tier) {
          'gold' || 'vip' => [
            'patched-while-await-condition-collection-switch-finalizer-premium',
          ],
          _ => [
            'patched-while-await-condition-collection-switch-finalizer-standard',
          ],
        },
        for (final value in extra)
          'patched-while-await-condition-collection-switch-finalizer-extra-$value',
      ];
    } finally {
      final marker = await cleanup;
      out = [
        ...out,
        'patched-while-await-condition-collection-switch-finalizer-cleanup-$marker',
      ];
    }
  }
  return out;
}

Future<Map<String, String>>
asyncDoWhileAwaitConditionMapSwitchForTryCatchFinallyAwaitGuardContinueBreak(
  Future<bool> keepGoing,
  String tier,
  Future<bool> skip,
  Future<bool> stop,
  Future<bool> fail,
  Future<String> cleanup,
  Map<String, String> extra,
) async {
  var out = <String, String>{
    'mode': 'patched-do-await-condition-map-switch-finalizer-head',
  };
  do {
    try {
      try {
        if (await skip) continue;
        if (await stop) break;
        if (await fail) {
          throw 'patched-do-await-condition-map-switch-finalizer-error';
        }
        out = {
          ...out,
          ...switch (tier) {
            'gold' || 'vip' => {
              'state':
                  'patched-do-await-condition-map-switch-finalizer-premium',
            },
            _ => {
              'state':
                  'patched-do-await-condition-map-switch-finalizer-standard',
            },
          },
          for (final entry in extra.entries)
            'patched-do-await-condition-map-switch-finalizer-extra-${entry.key}':
                entry.value,
        };
      } catch (e) {
        out = {
          ...out,
          'error': 'patched-do-await-condition-map-switch-finalizer-caught-$e',
        };
      }
    } finally {
      final marker = await cleanup;
      out = {
        ...out,
        'cleanup':
            'patched-do-await-condition-map-switch-finalizer-cleanup-$marker',
      };
    }
  } while (await keepGoing);
  return out;
}

Future<List<String>> asyncWhileNestedCollectionTryFinallyAwaitGuard(
  int limit,
  Future<bool> skip,
  Future<bool> stop,
  Future<String> ready,
  Future<String> cleanup,
  bool premium,
  List<String> extra,
) async {
  var i = 0;
  var out = <String>['patched-while-nested-collection-finalizer-head'];
  while (i < limit) {
    try {
      if (await skip) continue;
      if (await stop) break;
      if (premium) {
        final state = await ready;
        out = [
          ...out,
          'patched-while-nested-collection-finalizer-premium-$state-$i',
          for (final value in extra)
            'patched-while-nested-collection-finalizer-extra-$value-$i',
        ];
      } else {
        out = [...out, 'patched-while-nested-collection-finalizer-basic-$i'];
      }
      i = i + 1;
    } finally {
      final marker = await cleanup;
      out = [
        ...out,
        'patched-while-nested-collection-finalizer-cleanup-$marker',
      ];
    }
  }
  return out;
}

Future<Map<String, String>> asyncDoWhileNestedMapTryCatchFinallyAwaitGuard(
  int limit,
  Future<bool> skip,
  Future<bool> stop,
  Future<bool> fail,
  Future<String> ready,
  Future<String> cleanup,
  bool premium,
  Map<String, String> extra,
) async {
  var i = 0;
  var out = <String, String>{'mode': 'patched-do-nested-map-finalizer-head'};
  do {
    try {
      try {
        if (await skip) continue;
        if (await stop) break;
        if (await fail) {
          throw 'patched-do-nested-map-finalizer-error-$i';
        }
        if (premium) {
          final state = await ready;
          out = {
            ...out,
            'state': 'patched-do-nested-map-finalizer-premium-$state-$i',
            for (final entry in extra.entries)
              'patched-do-nested-map-finalizer-extra-${entry.key}':
                  '${entry.value}-$i',
          };
        } else {
          out = {...out, 'state': 'patched-do-nested-map-finalizer-basic-$i'};
        }
        i = i + 1;
      } catch (e) {
        out = {...out, 'error': 'patched-do-nested-map-finalizer-caught-$e'};
      }
    } finally {
      final marker = await cleanup;
      out = {
        ...out,
        'cleanup': 'patched-do-nested-map-finalizer-cleanup-$marker',
      };
    }
  } while (i < limit);
  return out;
}

Future<List<String>>
asyncWhileAwaitConditionNestedCollectionTryCatchFinallyGuard(
  Future<bool> keepGoing,
  Future<bool> skip,
  Future<bool> stop,
  Future<bool> fail,
  Future<String> ready,
  Future<String> cleanup,
  bool premium,
  List<String> extra,
) async {
  var out = <String>[
    'patched-while-await-condition-nested-collection-finalizer-head',
  ];
  while (await keepGoing) {
    try {
      try {
        if (await skip) continue;
        if (await stop) break;
        if (await fail) {
          throw 'patched-while-await-condition-nested-collection-error';
        }
        if (premium) {
          final state = await ready;
          out = [
            ...out,
            'patched-while-await-condition-nested-collection-premium-$state',
            for (final value in extra)
              'patched-while-await-condition-nested-collection-extra-$value',
          ];
        } else {
          out = [
            ...out,
            'patched-while-await-condition-nested-collection-basic',
          ];
        }
      } catch (e) {
        out = [
          ...out,
          'patched-while-await-condition-nested-collection-caught-$e',
        ];
      }
    } finally {
      final marker = await cleanup;
      out = [
        ...out,
        'patched-while-await-condition-nested-collection-cleanup-$marker',
      ];
    }
  }
  return out;
}

Future<Map<String, String>> asyncForAwaitConditionSwitchMapTryFinallyAwaitGuard(
  Future<bool> keepGoing,
  String tier,
  Future<bool> skip,
  Future<bool> stop,
  Future<String> cleanup,
  Map<String, String> extra,
) async {
  var out = <String, String>{
    'mode': 'patched-for-await-condition-switch-map-finalizer-head',
  };
  for (var i = 0; await keepGoing; i = i + 1) {
    try {
      if (await skip) continue;
      if (await stop) break;
      out = {
        ...out,
        ...switch (tier) {
          'gold' || 'vip' => {
            'state': 'patched-for-await-condition-switch-map-premium-$i',
          },
          _ => {'state': 'patched-for-await-condition-switch-map-standard-$i'},
        },
        for (final entry in extra.entries)
          'patched-for-await-condition-switch-map-extra-${entry.key}':
              '${entry.value}-$i',
      };
    } finally {
      final marker = await cleanup;
      out = {
        ...out,
        'cleanup': 'patched-for-await-condition-switch-map-cleanup-$marker',
      };
    }
  }
  return out;
}

Future<List<String>> asyncWhileMultiAwaitUpdateCollectionTryCatchFinallyGuard(
  int limit,
  Future<int> nextI,
  Future<int> nextJ,
  Future<bool> skip,
  Future<bool> stop,
  Future<bool> fail,
  Future<String> cleanup,
  List<String> extra,
) async {
  var out = <String>[
    'patched-while-multi-await-update-collection-finalizer-head',
  ];
  var i = 0;
  var j = 0;
  while (i < limit) {
    try {
      try {
        if (await skip) continue;
        if (await stop) break;
        if (await fail) {
          throw 'patched-while-multi-await-update-collection-error-$i-$j';
        }
        out = [
          ...out,
          'patched-while-multi-await-update-collection-body-$i-$j',
          for (final value in extra)
            'patched-while-multi-await-update-collection-extra-$value-$i-$j',
        ];
        i = await nextI;
        j = await nextJ;
      } catch (e) {
        out = [...out, 'patched-while-multi-await-update-collection-caught-$e'];
      }
    } finally {
      final marker = await cleanup;
      out = [
        ...out,
        'patched-while-multi-await-update-collection-cleanup-$marker',
      ];
    }
  }
  return out;
}

Future<Map<String, String>> asyncDoWhileSwitchMapNestedTryCatchFinallyGuard(
  int limit,
  String tier,
  Future<bool> skip,
  Future<bool> stop,
  Future<bool> fail,
  Future<String> ready,
  Future<String> cleanup,
  Map<String, String> extra,
) async {
  var i = 0;
  var out = <String, String>{
    'mode': 'patched-do-switch-map-nested-finalizer-head',
  };
  do {
    try {
      try {
        if (await skip) continue;
        if (await stop) break;
        if (await fail) {
          throw 'patched-do-switch-map-nested-finalizer-error-$i';
        }
        final state = await ready;
        out = {
          ...out,
          ...switch (tier) {
            'gold' || 'vip' => {
              'state': 'patched-do-switch-map-nested-finalizer-premium-$state',
            },
            _ => {
              'state': 'patched-do-switch-map-nested-finalizer-standard-$state',
            },
          },
          for (final entry in extra.entries)
            'patched-do-switch-map-nested-finalizer-extra-${entry.key}':
                '${entry.value}-$i',
        };
        i = i + 1;
      } catch (e) {
        out = {
          ...out,
          'error': 'patched-do-switch-map-nested-finalizer-caught-$e',
        };
      }
    } finally {
      final marker = await cleanup;
      out = {
        ...out,
        'cleanup': 'patched-do-switch-map-nested-finalizer-cleanup-$marker',
      };
    }
  } while (i < limit);
  return out;
}

Future<List<String>> asyncWhileSwitchCollectionFinallyNestedCleanupGuard(
  int limit,
  String tier,
  Future<bool> skip,
  Future<bool> stop,
  Future<String> cleanup,
  Future<String> cleanupTail,
  List<String> extra,
) async {
  var i = 0;
  var out = <String>['patched-while-switch-collection-nested-cleanup-head'];
  while (i < limit) {
    try {
      if (await skip) continue;
      if (await stop) break;
      out = [
        ...out,
        ...switch (tier) {
          'gold' ||
          'vip' => ['patched-while-switch-collection-nested-cleanup-premium'],
          _ => ['patched-while-switch-collection-nested-cleanup-standard'],
        },
        for (final value in extra)
          'patched-while-switch-collection-nested-cleanup-extra-$value-$i',
      ];
      i = i + 1;
    } finally {
      final marker = await cleanup;
      final tail = await cleanupTail;
      out = [
        ...out,
        'patched-while-switch-collection-nested-cleanup-$marker-$tail',
      ];
    }
  }
  return out;
}

Future<Map<String, String>>
asyncWhileAwaitConditionMapTryCatchFinallyDoubleCleanupGuard(
  Future<bool> keepGoing,
  Future<bool> skip,
  Future<bool> stop,
  Future<bool> fail,
  Future<String> recovery,
  Future<String> cleanup,
  Future<String> cleanupTail,
  Map<String, String> extra,
) async {
  var out = <String, String>{
    'mode': 'patched-while-await-condition-map-double-cleanup-head',
  };
  while (await keepGoing) {
    try {
      try {
        if (await skip) continue;
        if (await stop) break;
        if (await fail) {
          throw 'patched-while-await-condition-map-double-cleanup-error';
        }
        out = {
          ...out,
          for (final entry in extra.entries)
            'patched-while-await-condition-map-double-cleanup-extra-${entry.key}':
                entry.value,
        };
      } catch (e) {
        final marker = await recovery;
        out = {
          ...out,
          'error':
              'patched-while-await-condition-map-double-cleanup-caught-$marker-$e',
        };
      }
    } finally {
      final marker = await cleanup;
      final tail = await cleanupTail;
      out = {
        ...out,
        'cleanup':
            'patched-while-await-condition-map-double-cleanup-$marker-$tail',
      };
    }
  }
  return out;
}
