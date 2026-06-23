Future<String> asyncWhileTryFinallyAwaitGuardContinueBreak(
  int limit,
  Future<bool> skip,
  Future<bool> stop,
  Future<String> cleanup,
) async {
  var i = 0;
  var out = 'base-while-finalizer-guard';
  while (i < limit) {
    if (await skip) {
      out = '$out-skip-$i';
    } else if (await stop) {
      out = '$out-stop-$i';
    } else {
      out = '$out-body-$i';
    }
    final marker = await cleanup;
    out = '$out-finally-$marker';
    i = i + 1;
  }
  return out;
}

Future<String> asyncWhileAwaitConditionTryFinallyAwaitGuardContinueBreak(
  Future<bool> keepGoing,
  Future<bool> skip,
  Future<bool> stop,
  Future<String> cleanup,
) async {
  var out = 'base-while-await-condition-finalizer-guard';
  while (await keepGoing) {
    if (await skip) {
      out = '$out-skip';
    } else if (await stop) {
      out = '$out-stop';
    } else {
      out = '$out-body';
    }
    final marker = await cleanup;
    out = '$out-finally-$marker';
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
  var out = 'base-while-nested-finalizer-guard';
  while (i < limit) {
    if (await skip) {
      out = '$out-skip-$i';
    } else if (await stop) {
      out = '$out-stop-$i';
    } else if (premium) {
      final state = await ready;
      out = '$out-premium-$state-$i';
    } else {
      out = '$out-basic-$i';
    }
    final marker = await cleanup;
    out = '$out-finally-$marker';
    i = i + 1;
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
  var out = 'base-while-catch-finalizer-guard';
  while (i < limit) {
    if (await skip) {
      out = '$out-skip-$i';
    } else if (await stop) {
      out = '$out-stop-$i';
    } else if (await fail) {
      out = '$out-error-$i';
    } else {
      out = '$out-body-$i';
    }
    final marker = await cleanup;
    out = '$out-finally-$marker';
    i = i + 1;
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
  var out = 'base-do-finalizer-guard';
  do {
    if (await skip) {
      out = '$out-skip-$i';
    } else if (await stop) {
      out = '$out-stop-$i';
    } else {
      out = '$out-body-$i';
    }
    final marker = await cleanup;
    out = '$out-finally-$marker';
    i = i + 1;
  } while (i < limit);
  return out;
}

Future<String> asyncDoWhileAwaitConditionTryFinallyAwaitGuardContinueBreak(
  Future<bool> keepGoing,
  Future<bool> skip,
  Future<bool> stop,
  Future<String> cleanup,
) async {
  var out = 'base-do-await-condition-finalizer-guard';
  do {
    if (await skip) {
      out = '$out-skip';
    } else if (await stop) {
      out = '$out-stop';
    } else {
      out = '$out-body';
    }
    final marker = await cleanup;
    out = '$out-finally-$marker';
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
  var out = 'base-do-nested-finalizer-guard';
  do {
    if (await skip) {
      out = '$out-skip-$i';
    } else if (await stop) {
      out = '$out-stop-$i';
    } else if (premium) {
      final state = await ready;
      out = '$out-premium-$state-$i';
    } else {
      out = '$out-basic-$i';
    }
    final marker = await cleanup;
    out = '$out-finally-$marker';
    i = i + 1;
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
  var out = 'base-do-catch-finalizer-guard';
  do {
    if (await skip) {
      out = '$out-skip-$i';
    } else if (await stop) {
      out = '$out-stop-$i';
    } else if (await fail) {
      out = '$out-error-$i';
    } else {
      out = '$out-body-$i';
    }
    final marker = await cleanup;
    out = '$out-finally-$marker';
    i = i + 1;
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
  var out = 'base-while-switch-finalizer-guard';
  while (i < limit) {
    if (await skip) {
      out = '$out-skip-$i';
    } else if (await stop) {
      out = '$out-stop-$i';
    } else {
      out = '$out-$tier-$i';
    }
    final marker = await cleanup;
    out = '$out-finally-$marker';
    i = i + 1;
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
  var out = 'base-do-switch-finalizer-guard';
  do {
    if (await skip) {
      out = '$out-skip-$i';
    } else if (await stop) {
      out = '$out-stop-$i';
    } else {
      out = '$out-$tier-$i';
    }
    final marker = await cleanup;
    out = '$out-finally-$marker';
    i = i + 1;
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
  var out = 'base-while-switch-or-finalizer-guard';
  while (i < limit) {
    if (await skip) {
      out = '$out-skip-$i';
    } else if (await stop) {
      out = '$out-stop-$i';
    } else {
      out = '$out-$tier-$i';
    }
    final marker = await cleanup;
    out = '$out-finally-$marker';
    i = i + 1;
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
  var out = 'base-do-switch-or-finalizer-guard';
  do {
    if (await skip) {
      out = '$out-skip-$i';
    } else if (await stop) {
      out = '$out-stop-$i';
    } else {
      out = '$out-$tier-$i';
    }
    final marker = await cleanup;
    out = '$out-finally-$marker';
    i = i + 1;
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
  var out = <String>['base-while-collection-finalizer-head'];
  while (i < limit) {
    if (await skip) {
      out = [...out, 'base-while-collection-finalizer-skip-$i'];
    } else if (await stop) {
      out = [...out, 'base-while-collection-finalizer-stop-$i'];
    } else {
      out = [...out, 'base-while-collection-finalizer-body-$i'];
    }
    final marker = await cleanup;
    out = [...out, 'base-while-collection-finalizer-cleanup-$marker'];
    i = i + 1;
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
  var out = <String>['base-do-collection-finalizer-head'];
  do {
    if (await skip) {
      out = [...out, 'base-do-collection-finalizer-skip-$i'];
    } else if (await stop) {
      out = [...out, 'base-do-collection-finalizer-stop-$i'];
    } else {
      out = [...out, 'base-do-collection-finalizer-body-$i'];
    }
    final marker = await cleanup;
    out = [...out, 'base-do-collection-finalizer-cleanup-$marker'];
    i = i + 1;
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
  var out = <String, String>{'mode': 'base-while-map-finalizer-head'};
  while (i < limit) {
    if (await skip) {
      out = {...out, 'skip': 'base-while-map-finalizer-skip-$i'};
    } else if (await stop) {
      out = {...out, 'stop': 'base-while-map-finalizer-stop-$i'};
    } else {
      out = {...out, 'body': 'base-while-map-finalizer-body-$i'};
    }
    final marker = await cleanup;
    out = {...out, 'cleanup': 'base-while-map-finalizer-cleanup-$marker'};
    i = i + 1;
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
  var out = <String, String>{'mode': 'base-do-map-finalizer-head'};
  do {
    if (await skip) {
      out = {...out, 'skip': 'base-do-map-finalizer-skip-$i'};
    } else if (await stop) {
      out = {...out, 'stop': 'base-do-map-finalizer-stop-$i'};
    } else {
      out = {...out, 'body': 'base-do-map-finalizer-body-$i'};
    }
    final marker = await cleanup;
    out = {...out, 'cleanup': 'base-do-map-finalizer-cleanup-$marker'};
    i = i + 1;
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
  var out = <String>['base-while-collection-switch-finalizer-head'];
  while (i < limit) {
    if (await skip) {
      out = [...out, 'base-while-collection-switch-finalizer-skip-$i'];
    } else if (await stop) {
      out = [...out, 'base-while-collection-switch-finalizer-stop-$i'];
    } else {
      out = [
        ...out,
        tier == 'gold'
            ? 'base-while-collection-switch-finalizer-premium'
            : 'base-while-collection-switch-finalizer-standard',
        for (final value in extra)
          'base-while-collection-switch-finalizer-extra-$value-$i',
      ];
    }
    final marker = await cleanup;
    out = [...out, 'base-while-collection-switch-finalizer-cleanup-$marker'];
    i = i + 1;
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
  var out = <String>['base-do-collection-switch-finalizer-head'];
  do {
    if (await skip) {
      out = [...out, 'base-do-collection-switch-finalizer-skip-$i'];
    } else if (await stop) {
      out = [...out, 'base-do-collection-switch-finalizer-stop-$i'];
    } else {
      out = [
        ...out,
        tier == 'gold'
            ? 'base-do-collection-switch-finalizer-premium'
            : 'base-do-collection-switch-finalizer-standard',
        for (final value in extra)
          'base-do-collection-switch-finalizer-extra-$value-$i',
      ];
    }
    final marker = await cleanup;
    out = [...out, 'base-do-collection-switch-finalizer-cleanup-$marker'];
    i = i + 1;
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
  var out = <String, String>{'mode': 'base-while-map-switch-finalizer-head'};
  while (i < limit) {
    if (await skip) {
      out = {...out, 'skip': 'base-while-map-switch-finalizer-skip-$i'};
    } else if (await stop) {
      out = {...out, 'stop': 'base-while-map-switch-finalizer-stop-$i'};
    } else if (await fail) {
      out = {...out, 'error': 'base-while-map-switch-finalizer-error-$i'};
    } else {
      out = {
        ...out,
        'state': tier == 'gold'
            ? 'base-while-map-switch-finalizer-premium'
            : 'base-while-map-switch-finalizer-standard',
        for (final entry in extra.entries)
          'base-while-map-switch-finalizer-extra-${entry.key}': entry.value,
      };
    }
    final marker = await cleanup;
    out = {
      ...out,
      'cleanup': 'base-while-map-switch-finalizer-cleanup-$marker',
    };
    i = i + 1;
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
  var out = <String, String>{'mode': 'base-do-map-switch-finalizer-head'};
  do {
    if (await skip) {
      out = {...out, 'skip': 'base-do-map-switch-finalizer-skip-$i'};
    } else if (await stop) {
      out = {...out, 'stop': 'base-do-map-switch-finalizer-stop-$i'};
    } else if (await fail) {
      out = {...out, 'error': 'base-do-map-switch-finalizer-error-$i'};
    } else {
      out = {
        ...out,
        'state': tier == 'gold'
            ? 'base-do-map-switch-finalizer-premium'
            : 'base-do-map-switch-finalizer-standard',
        for (final entry in extra.entries)
          'base-do-map-switch-finalizer-extra-${entry.key}': entry.value,
      };
    }
    final marker = await cleanup;
    out = {...out, 'cleanup': 'base-do-map-switch-finalizer-cleanup-$marker'};
    i = i + 1;
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
    'base-while-await-condition-collection-switch-finalizer-head',
  ];
  while (await keepGoing) {
    if (await skip) {
      out = [
        ...out,
        'base-while-await-condition-collection-switch-finalizer-skip',
      ];
    } else if (await stop) {
      out = [
        ...out,
        'base-while-await-condition-collection-switch-finalizer-stop',
      ];
    } else {
      out = [
        ...out,
        tier == 'gold'
            ? 'base-while-await-condition-collection-switch-finalizer-premium'
            : 'base-while-await-condition-collection-switch-finalizer-standard',
        for (final value in extra)
          'base-while-await-condition-collection-switch-finalizer-extra-$value',
      ];
    }
    final marker = await cleanup;
    out = [
      ...out,
      'base-while-await-condition-collection-switch-finalizer-cleanup-$marker',
    ];
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
    'mode': 'base-do-await-condition-map-switch-finalizer-head',
  };
  do {
    if (await skip) {
      out = {
        ...out,
        'skip': 'base-do-await-condition-map-switch-finalizer-skip',
      };
    } else if (await stop) {
      out = {
        ...out,
        'stop': 'base-do-await-condition-map-switch-finalizer-stop',
      };
    } else if (await fail) {
      out = {
        ...out,
        'error': 'base-do-await-condition-map-switch-finalizer-error',
      };
    } else {
      out = {
        ...out,
        'state': tier == 'gold'
            ? 'base-do-await-condition-map-switch-finalizer-premium'
            : 'base-do-await-condition-map-switch-finalizer-standard',
        for (final entry in extra.entries)
          'base-do-await-condition-map-switch-finalizer-extra-${entry.key}':
              entry.value,
      };
    }
    final marker = await cleanup;
    out = {
      ...out,
      'cleanup': 'base-do-await-condition-map-switch-finalizer-cleanup-$marker',
    };
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
  var out = <String>['base-while-nested-collection-finalizer-head'];
  while (i < limit) {
    if (await skip) {
      out = [...out, 'base-while-nested-collection-finalizer-skip-$i'];
    } else if (await stop) {
      out = [...out, 'base-while-nested-collection-finalizer-stop-$i'];
    } else if (premium) {
      final state = await ready;
      out = [
        ...out,
        'base-while-nested-collection-finalizer-premium-$state-$i',
        for (final value in extra)
          'base-while-nested-collection-finalizer-extra-$value-$i',
      ];
    } else {
      out = [...out, 'base-while-nested-collection-finalizer-basic-$i'];
    }
    final marker = await cleanup;
    out = [...out, 'base-while-nested-collection-finalizer-cleanup-$marker'];
    i = i + 1;
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
  var out = <String, String>{'mode': 'base-do-nested-map-finalizer-head'};
  do {
    if (await skip) {
      out = {...out, 'skip': 'base-do-nested-map-finalizer-skip-$i'};
    } else if (await stop) {
      out = {...out, 'stop': 'base-do-nested-map-finalizer-stop-$i'};
    } else if (await fail) {
      out = {...out, 'error': 'base-do-nested-map-finalizer-error-$i'};
    } else if (premium) {
      final state = await ready;
      out = {
        ...out,
        'state': 'base-do-nested-map-finalizer-premium-$state-$i',
        for (final entry in extra.entries)
          'base-do-nested-map-finalizer-extra-${entry.key}':
              '${entry.value}-$i',
      };
    } else {
      out = {...out, 'state': 'base-do-nested-map-finalizer-basic-$i'};
    }
    final marker = await cleanup;
    out = {...out, 'cleanup': 'base-do-nested-map-finalizer-cleanup-$marker'};
    i = i + 1;
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
    'base-while-await-condition-nested-collection-finalizer-head',
  ];
  while (await keepGoing) {
    if (await skip) {
      out = [...out, 'base-while-await-condition-nested-collection-skip'];
    } else if (await stop) {
      out = [...out, 'base-while-await-condition-nested-collection-stop'];
    } else if (await fail) {
      out = [...out, 'base-while-await-condition-nested-collection-error'];
    } else if (premium) {
      final state = await ready;
      out = [
        ...out,
        'base-while-await-condition-nested-collection-premium-$state',
        for (final value in extra)
          'base-while-await-condition-nested-collection-extra-$value',
      ];
    } else {
      out = [...out, 'base-while-await-condition-nested-collection-basic'];
    }
    final marker = await cleanup;
    out = [
      ...out,
      'base-while-await-condition-nested-collection-cleanup-$marker',
    ];
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
    'mode': 'base-for-await-condition-switch-map-finalizer-head',
  };
  for (var i = 0; await keepGoing; i = i + 1) {
    if (await skip) {
      out = {...out, 'skip': 'base-for-await-condition-switch-map-skip-$i'};
    } else if (await stop) {
      out = {...out, 'stop': 'base-for-await-condition-switch-map-stop-$i'};
    } else {
      out = {
        ...out,
        'state': tier == 'gold'
            ? 'base-for-await-condition-switch-map-premium-$i'
            : 'base-for-await-condition-switch-map-standard-$i',
        for (final entry in extra.entries)
          'base-for-await-condition-switch-map-extra-${entry.key}':
              '${entry.value}-$i',
      };
    }
    final marker = await cleanup;
    out = {
      ...out,
      'cleanup': 'base-for-await-condition-switch-map-cleanup-$marker',
    };
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
  var out = <String>['base-while-multi-await-update-collection-finalizer-head'];
  var i = 0;
  var j = 0;
  while (i < limit) {
    if (await skip) {
      out = [...out, 'base-while-multi-await-update-collection-skip-$i-$j'];
    } else if (await stop) {
      out = [...out, 'base-while-multi-await-update-collection-stop-$i-$j'];
    } else if (await fail) {
      out = [...out, 'base-while-multi-await-update-collection-error-$i-$j'];
    } else {
      out = [
        ...out,
        'base-while-multi-await-update-collection-body-$i-$j',
        for (final value in extra)
          'base-while-multi-await-update-collection-extra-$value-$i-$j',
      ];
      i = await nextI;
      j = await nextJ;
    }
    final marker = await cleanup;
    out = [...out, 'base-while-multi-await-update-collection-cleanup-$marker'];
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
    'mode': 'base-do-switch-map-nested-finalizer-head',
  };
  do {
    if (await skip) {
      out = {...out, 'skip': 'base-do-switch-map-nested-skip-$i'};
    } else if (await stop) {
      out = {...out, 'stop': 'base-do-switch-map-nested-stop-$i'};
    } else if (await fail) {
      out = {...out, 'error': 'base-do-switch-map-nested-error-$i'};
    } else {
      final state = await ready;
      out = {
        ...out,
        'state': tier == 'gold'
            ? 'base-do-switch-map-nested-premium-$state'
            : 'base-do-switch-map-nested-standard-$state',
        for (final entry in extra.entries)
          'base-do-switch-map-nested-extra-${entry.key}': '${entry.value}-$i',
      };
    }
    final marker = await cleanup;
    out = {...out, 'cleanup': 'base-do-switch-map-nested-cleanup-$marker'};
    i = i + 1;
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
  var out = <String>['base-while-switch-collection-nested-cleanup-head'];
  while (i < limit) {
    if (await skip) {
      out = [...out, 'base-while-switch-collection-nested-cleanup-skip-$i'];
    } else if (await stop) {
      out = [...out, 'base-while-switch-collection-nested-cleanup-stop-$i'];
    } else {
      out = [
        ...out,
        tier == 'gold'
            ? 'base-while-switch-collection-nested-cleanup-premium'
            : 'base-while-switch-collection-nested-cleanup-standard',
        for (final value in extra)
          'base-while-switch-collection-nested-cleanup-extra-$value-$i',
      ];
    }
    final marker = await cleanup;
    final tail = await cleanupTail;
    out = [...out, 'base-while-switch-collection-nested-cleanup-$marker-$tail'];
    i = i + 1;
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
    'mode': 'base-while-await-condition-map-double-cleanup-head',
  };
  while (await keepGoing) {
    if (await skip) {
      out = {
        ...out,
        'skip': 'base-while-await-condition-map-double-cleanup-skip',
      };
    } else if (await stop) {
      out = {
        ...out,
        'stop': 'base-while-await-condition-map-double-cleanup-stop',
      };
    } else if (await fail) {
      final marker = await recovery;
      out = {
        ...out,
        'error': 'base-while-await-condition-map-double-cleanup-caught-$marker',
      };
    } else {
      out = {
        ...out,
        for (final entry in extra.entries)
          'base-while-await-condition-map-double-cleanup-extra-${entry.key}':
              entry.value,
      };
    }
    final marker = await cleanup;
    final tail = await cleanupTail;
    out = {
      ...out,
      'cleanup': 'base-while-await-condition-map-double-cleanup-$marker-$tail',
    };
  }
  return out;
}
