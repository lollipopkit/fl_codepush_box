Future<List<String>> asyncWhileAwaitConditionSwitchCollectionDoubleCleanupGuard(
  Future<bool> keepGoing,
  String tier,
  Future<bool> skip,
  Future<bool> stop,
  Future<String> cleanup,
  Future<String> cleanupTail,
  List<String> extra,
) async {
  var out = <String>[
    'base-while-await-condition-switch-collection-double-cleanup-head',
  ];
  while (await keepGoing) {
    if (await skip) {
      out = [
        ...out,
        'base-while-await-condition-switch-collection-double-cleanup-skip',
      ];
    } else if (await stop) {
      out = [
        ...out,
        'base-while-await-condition-switch-collection-double-cleanup-stop',
      ];
    } else {
      out = [
        ...out,
        tier == 'gold'
            ? 'base-while-await-condition-switch-collection-double-cleanup-premium'
            : 'base-while-await-condition-switch-collection-double-cleanup-standard',
        for (final value in extra)
          'base-while-await-condition-switch-collection-double-cleanup-extra-$value',
      ];
    }
    final marker = await cleanup;
    final tail = await cleanupTail;
    out = [
      ...out,
      'base-while-await-condition-switch-collection-double-cleanup-$marker-$tail',
    ];
  }
  return out;
}

Future<Map<String, String>>
asyncDoWhileAwaitConditionMapTryCatchDoubleCleanupGuard(
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
    'mode': 'base-do-await-condition-map-double-cleanup-head',
  };
  do {
    if (await skip) {
      out = {...out, 'skip': 'base-do-await-condition-map-double-cleanup-skip'};
    } else if (await stop) {
      out = {...out, 'stop': 'base-do-await-condition-map-double-cleanup-stop'};
    } else if (await fail) {
      final marker = await recovery;
      out = {
        ...out,
        'error': 'base-do-await-condition-map-double-cleanup-caught-$marker',
      };
    } else {
      out = {
        ...out,
        for (final entry in extra.entries)
          'base-do-await-condition-map-double-cleanup-extra-${entry.key}':
              entry.value,
      };
    }
    final marker = await cleanup;
    final tail = await cleanupTail;
    out = {
      ...out,
      'cleanup': 'base-do-await-condition-map-double-cleanup-$marker-$tail',
    };
  } while (await keepGoing);
  return out;
}

Future<List<String>> asyncWhileNestedSwitchCollectionTryCatchFinallyGuard(
  int limit,
  String tier,
  Future<bool> skip,
  Future<bool> stop,
  Future<bool> fail,
  Future<String> ready,
  Future<String> cleanup,
  bool premium,
  List<String> extra,
) async {
  var i = 0;
  var out = <String>['base-while-nested-switch-collection-finalizer-head'];
  while (i < limit) {
    if (await skip) {
      out = [...out, 'base-while-nested-switch-collection-skip-$i'];
    } else if (await stop) {
      out = [...out, 'base-while-nested-switch-collection-stop-$i'];
    } else if (await fail) {
      out = [...out, 'base-while-nested-switch-collection-error-$i'];
    } else if (premium) {
      final state = await ready;
      out = [
        ...out,
        tier == 'gold'
            ? 'base-while-nested-switch-collection-premium-$state'
            : 'base-while-nested-switch-collection-standard-$state',
        for (final value in extra)
          'base-while-nested-switch-collection-extra-$value-$i',
      ];
    } else {
      out = [...out, 'base-while-nested-switch-collection-basic-$i'];
    }
    final marker = await cleanup;
    out = [...out, 'base-while-nested-switch-collection-cleanup-$marker'];
    i = i + 1;
  }
  return out;
}

Future<Map<String, String>>
asyncDoWhileNestedSwitchMapTryFinallyDoubleCleanupGuard(
  int limit,
  String tier,
  Future<bool> skip,
  Future<bool> stop,
  Future<String> ready,
  Future<String> cleanup,
  Future<String> cleanupTail,
  Map<String, String> extra,
) async {
  var i = 0;
  var out = <String, String>{
    'mode': 'base-do-nested-switch-map-double-cleanup-head',
  };
  do {
    if (await skip) {
      out = {
        ...out,
        'skip': 'base-do-nested-switch-map-double-cleanup-skip-$i',
      };
    } else if (await stop) {
      out = {
        ...out,
        'stop': 'base-do-nested-switch-map-double-cleanup-stop-$i',
      };
    } else {
      final state = await ready;
      out = {
        ...out,
        'state': tier == 'gold'
            ? 'base-do-nested-switch-map-double-cleanup-premium-$state'
            : 'base-do-nested-switch-map-double-cleanup-standard-$state',
        for (final entry in extra.entries)
          'base-do-nested-switch-map-double-cleanup-extra-${entry.key}':
              '${entry.value}-$i',
      };
    }
    final marker = await cleanup;
    final tail = await cleanupTail;
    out = {
      ...out,
      'cleanup': 'base-do-nested-switch-map-double-cleanup-$marker-$tail',
    };
    i = i + 1;
  } while (i < limit);
  return out;
}

Future<List<String>>
asyncForAwaitConditionCollectionTryFinallyDoubleCleanupGuard(
  Future<bool> keepGoing,
  Future<bool> skip,
  Future<bool> stop,
  Future<String> cleanup,
  Future<String> cleanupTail,
  List<String> extra,
) async {
  var out = <String>['base-for-await-condition-collection-double-cleanup-head'];
  for (var i = 0; await keepGoing; i = i + 1) {
    if (await skip) {
      out = [
        ...out,
        'base-for-await-condition-collection-double-cleanup-skip-$i',
      ];
    } else if (await stop) {
      out = [
        ...out,
        'base-for-await-condition-collection-double-cleanup-stop-$i',
      ];
    } else {
      out = [
        ...out,
        'base-for-await-condition-collection-double-cleanup-body-$i',
        for (final value in extra)
          'base-for-await-condition-collection-double-cleanup-extra-$value-$i',
      ];
    }
    final marker = await cleanup;
    final tail = await cleanupTail;
    out = [
      ...out,
      'base-for-await-condition-collection-double-cleanup-$marker-$tail',
    ];
  }
  return out;
}

Future<Map<String, String>>
asyncWhileRuntimeMapTryCatchFinallyRecoveryCleanupGuard(
  int limit,
  Future<bool> skip,
  Future<bool> stop,
  Future<bool> fail,
  Future<String> recovery,
  Future<String> cleanup,
  Map<String, String> extra,
) async {
  var i = 0;
  var out = <String, String>{
    'mode': 'base-while-runtime-map-recovery-cleanup-head',
  };
  while (i < limit) {
    if (await skip) {
      out = {...out, 'skip': 'base-while-runtime-map-recovery-cleanup-skip-$i'};
    } else if (await stop) {
      out = {...out, 'stop': 'base-while-runtime-map-recovery-cleanup-stop-$i'};
    } else if (await fail) {
      final marker = await recovery;
      out = {
        ...out,
        'error': 'base-while-runtime-map-recovery-cleanup-caught-$marker',
      };
    } else {
      out = {
        ...out,
        for (final entry in extra.entries)
          'base-while-runtime-map-recovery-cleanup-extra-${entry.key}':
              '${entry.value}-$i',
      };
    }
    final marker = await cleanup;
    out = {
      ...out,
      'cleanup': 'base-while-runtime-map-recovery-cleanup-$marker',
    };
    i = i + 1;
  }
  return out;
}

Future<Map<String, String>>
asyncWhileAwaitConditionMapTryCatchFinallyRecoveryCleanupGuard(
  Future<bool> keepGoing,
  Future<bool> skip,
  Future<bool> stop,
  Future<bool> fail,
  Future<String> recovery,
  Future<String> cleanup,
  Map<String, String> extra,
) async {
  var out = <String, String>{
    'mode': 'base-while-await-condition-map-recovery-cleanup-head',
  };
  while (await keepGoing) {
    if (await skip) {
      out = {
        ...out,
        'skip': 'base-while-await-condition-map-recovery-cleanup-skip',
      };
    } else if (await stop) {
      out = {
        ...out,
        'stop': 'base-while-await-condition-map-recovery-cleanup-stop',
      };
    } else if (await fail) {
      final marker = await recovery;
      out = {
        ...out,
        'error':
            'base-while-await-condition-map-recovery-cleanup-caught-$marker',
      };
    } else {
      out = {
        ...out,
        for (final entry in extra.entries)
          'base-while-await-condition-map-recovery-cleanup-extra-${entry.key}':
              entry.value,
      };
    }
    final marker = await cleanup;
    out = {
      ...out,
      'cleanup': 'base-while-await-condition-map-recovery-cleanup-$marker',
    };
  }
  return out;
}

Future<List<String>> asyncDoWhileSwitchCollectionTryCatchFinallyRecoveryGuard(
  int limit,
  String tier,
  Future<bool> skip,
  Future<bool> stop,
  Future<bool> fail,
  Future<String> recovery,
  Future<String> cleanup,
  List<String> extra,
) async {
  var i = 0;
  var out = <String>['base-do-switch-collection-recovery-head'];
  do {
    if (await skip) {
      out = [...out, 'base-do-switch-collection-recovery-skip-$i'];
    } else if (await stop) {
      out = [...out, 'base-do-switch-collection-recovery-stop-$i'];
    } else if (await fail) {
      final marker = await recovery;
      out = [...out, 'base-do-switch-collection-recovery-caught-$marker'];
    } else {
      out = [
        ...out,
        tier == 'gold'
            ? 'base-do-switch-collection-recovery-premium'
            : 'base-do-switch-collection-recovery-standard',
        for (final value in extra)
          'base-do-switch-collection-recovery-extra-$value-$i',
      ];
    }
    final marker = await cleanup;
    out = [...out, 'base-do-switch-collection-recovery-cleanup-$marker'];
    i = i + 1;
  } while (i < limit);
  return out;
}

Future<List<String>> asyncWhileNestedListTryFinallyDoubleCleanupGuard(
  int limit,
  Future<bool> skip,
  Future<bool> stop,
  Future<String> ready,
  Future<String> cleanup,
  Future<String> cleanupTail,
  bool premium,
  List<String> extra,
) async {
  var i = 0;
  var out = <String>['base-while-nested-list-double-cleanup-head'];
  while (i < limit) {
    if (await skip) {
      out = [...out, 'base-while-nested-list-double-cleanup-skip-$i'];
    } else if (await stop) {
      out = [...out, 'base-while-nested-list-double-cleanup-stop-$i'];
    } else if (premium) {
      final state = await ready;
      out = [
        ...out,
        'base-while-nested-list-double-cleanup-premium-$state-$i',
        for (final value in extra)
          'base-while-nested-list-double-cleanup-extra-$value-$i',
      ];
    } else {
      out = [...out, 'base-while-nested-list-double-cleanup-basic-$i'];
    }
    final marker = await cleanup;
    final tail = await cleanupTail;
    out = [...out, 'base-while-nested-list-double-cleanup-$marker-$tail'];
    i = i + 1;
  }
  return out;
}

Future<List<String>> asyncForSwitchCollectionTryFinallyDoubleCleanupGuard(
  int limit,
  String tier,
  Future<bool> skip,
  Future<bool> stop,
  Future<String> cleanup,
  Future<String> cleanupTail,
  List<String> extra,
) async {
  var out = <String>['base-for-switch-collection-double-cleanup-head'];
  for (var i = 0; i < limit; i = i + 1) {
    if (await skip) {
      out = [...out, 'base-for-switch-collection-double-cleanup-skip-$i'];
    } else if (await stop) {
      out = [...out, 'base-for-switch-collection-double-cleanup-stop-$i'];
    } else {
      out = [
        ...out,
        tier == 'gold'
            ? 'base-for-switch-collection-double-cleanup-premium'
            : 'base-for-switch-collection-double-cleanup-standard',
        for (final value in extra)
          'base-for-switch-collection-double-cleanup-extra-$value-$i',
      ];
    }
    final marker = await cleanup;
    final tail = await cleanupTail;
    out = [...out, 'base-for-switch-collection-double-cleanup-$marker-$tail'];
  }
  return out;
}

Future<List<String>>
asyncDoWhileAwaitConditionSwitchCollectionTryFinallyDoubleCleanupGuard(
  Future<bool> keepGoing,
  String tier,
  Future<bool> skip,
  Future<bool> stop,
  Future<String> cleanup,
  Future<String> cleanupTail,
  List<String> extra,
) async {
  var out = <String>[
    'base-do-await-condition-switch-collection-double-cleanup-head',
  ];
  do {
    if (await skip) {
      out = [
        ...out,
        'base-do-await-condition-switch-collection-double-cleanup-skip',
      ];
    } else if (await stop) {
      out = [
        ...out,
        'base-do-await-condition-switch-collection-double-cleanup-stop',
      ];
    } else {
      out = [
        ...out,
        tier == 'gold'
            ? 'base-do-await-condition-switch-collection-double-cleanup-premium'
            : 'base-do-await-condition-switch-collection-double-cleanup-standard',
        for (final value in extra)
          'base-do-await-condition-switch-collection-double-cleanup-extra-$value',
      ];
    }
    final marker = await cleanup;
    final tail = await cleanupTail;
    out = [
      ...out,
      'base-do-await-condition-switch-collection-double-cleanup-$marker-$tail',
    ];
  } while (await keepGoing);
  return out;
}

Future<Map<String, String>>
asyncWhileMapSwitchTryCatchFinallyRecoveryDoubleCleanupGuard(
  int limit,
  String tier,
  Future<bool> skip,
  Future<bool> stop,
  Future<bool> fail,
  Future<String> recovery,
  Future<String> cleanup,
  Future<String> cleanupTail,
  Map<String, String> extra,
) async {
  var i = 0;
  var out = <String, String>{
    'mode': 'base-while-map-switch-recovery-double-cleanup-head',
  };
  while (i < limit) {
    if (await skip) {
      out = {
        ...out,
        'skip': 'base-while-map-switch-recovery-double-cleanup-skip-$i',
      };
    } else if (await stop) {
      out = {
        ...out,
        'stop': 'base-while-map-switch-recovery-double-cleanup-stop-$i',
      };
    } else if (await fail) {
      final marker = await recovery;
      out = {
        ...out,
        'error': 'base-while-map-switch-recovery-double-cleanup-caught-$marker',
      };
    } else {
      out = {
        ...out,
        'state': tier == 'gold'
            ? 'base-while-map-switch-recovery-double-cleanup-premium'
            : 'base-while-map-switch-recovery-double-cleanup-standard',
        for (final entry in extra.entries)
          'base-while-map-switch-recovery-double-cleanup-extra-${entry.key}':
              '${entry.value}-$i',
      };
      i = i + 1;
    }
    final marker = await cleanup;
    final tail = await cleanupTail;
    out = {
      ...out,
      'cleanup': 'base-while-map-switch-recovery-double-cleanup-$marker-$tail',
    };
  }
  return out;
}
