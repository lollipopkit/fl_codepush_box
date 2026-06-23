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
    'patched-while-await-condition-switch-collection-double-cleanup-head',
  ];
  while (await keepGoing) {
    try {
      if (await skip) continue;
      if (await stop) break;
      out = [
        ...out,
        ...switch (tier) {
          'gold' || 'vip' => [
            'patched-while-await-condition-switch-collection-double-cleanup-premium',
          ],
          _ => [
            'patched-while-await-condition-switch-collection-double-cleanup-standard',
          ],
        },
        for (final value in extra)
          'patched-while-await-condition-switch-collection-double-cleanup-extra-$value',
      ];
    } finally {
      final marker = await cleanup;
      final tail = await cleanupTail;
      out = [
        ...out,
        'patched-while-await-condition-switch-collection-double-cleanup-$marker-$tail',
      ];
    }
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
    'mode': 'patched-do-await-condition-map-double-cleanup-head',
  };
  do {
    try {
      try {
        if (await skip) continue;
        if (await stop) break;
        if (await fail) {
          throw 'patched-do-await-condition-map-double-cleanup-error';
        }
        out = {
          ...out,
          for (final entry in extra.entries)
            'patched-do-await-condition-map-double-cleanup-extra-${entry.key}':
                entry.value,
        };
      } catch (e) {
        final marker = await recovery;
        out = {
          ...out,
          'error':
              'patched-do-await-condition-map-double-cleanup-caught-$marker-$e',
        };
      }
    } finally {
      final marker = await cleanup;
      final tail = await cleanupTail;
      out = {
        ...out,
        'cleanup':
            'patched-do-await-condition-map-double-cleanup-$marker-$tail',
      };
    }
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
  var out = <String>['patched-while-nested-switch-collection-finalizer-head'];
  while (i < limit) {
    try {
      try {
        if (await skip) continue;
        if (await stop) break;
        if (await fail) {
          throw 'patched-while-nested-switch-collection-finalizer-error-$i';
        }
        if (premium) {
          final state = await ready;
          out = [
            ...out,
            ...switch (tier) {
              'gold' || 'vip' => [
                'patched-while-nested-switch-collection-finalizer-premium-$state',
              ],
              _ => [
                'patched-while-nested-switch-collection-finalizer-standard-$state',
              ],
            },
            for (final value in extra)
              'patched-while-nested-switch-collection-finalizer-extra-$value-$i',
          ];
        } else {
          out = [
            ...out,
            'patched-while-nested-switch-collection-finalizer-basic-$i',
          ];
        }
        i = i + 1;
      } catch (e) {
        out = [
          ...out,
          'patched-while-nested-switch-collection-finalizer-caught-$e',
        ];
      }
    } finally {
      final marker = await cleanup;
      out = [
        ...out,
        'patched-while-nested-switch-collection-finalizer-cleanup-$marker',
      ];
    }
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
    'mode': 'patched-do-nested-switch-map-double-cleanup-head',
  };
  do {
    try {
      if (await skip) continue;
      if (await stop) break;
      final state = await ready;
      out = {
        ...out,
        ...switch (tier) {
          'gold' || 'vip' => {
            'state':
                'patched-do-nested-switch-map-double-cleanup-premium-$state',
          },
          _ => {
            'state':
                'patched-do-nested-switch-map-double-cleanup-standard-$state',
          },
        },
        for (final entry in extra.entries)
          'patched-do-nested-switch-map-double-cleanup-extra-${entry.key}':
              '${entry.value}-$i',
      };
      i = i + 1;
    } finally {
      final marker = await cleanup;
      final tail = await cleanupTail;
      out = {
        ...out,
        'cleanup': 'patched-do-nested-switch-map-double-cleanup-$marker-$tail',
      };
    }
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
  var out = <String>[
    'patched-for-await-condition-collection-double-cleanup-head',
  ];
  for (var i = 0; await keepGoing; i = i + 1) {
    try {
      if (await skip) continue;
      if (await stop) break;
      out = [
        ...out,
        'patched-for-await-condition-collection-double-cleanup-body-$i',
        for (final value in extra)
          'patched-for-await-condition-collection-double-cleanup-extra-$value-$i',
      ];
    } finally {
      final marker = await cleanup;
      final tail = await cleanupTail;
      out = [
        ...out,
        'patched-for-await-condition-collection-double-cleanup-$marker-$tail',
      ];
    }
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
    'mode': 'patched-while-runtime-map-recovery-cleanup-head',
  };
  while (i < limit) {
    try {
      try {
        if (await skip) continue;
        if (await stop) break;
        if (await fail) {
          throw 'patched-while-runtime-map-recovery-cleanup-error-$i';
        }
        out = {
          ...out,
          for (final entry in extra.entries)
            'patched-while-runtime-map-recovery-cleanup-extra-${entry.key}':
                '${entry.value}-$i',
        };
        i = i + 1;
      } catch (e) {
        final marker = await recovery;
        out = {
          ...out,
          'error':
              'patched-while-runtime-map-recovery-cleanup-caught-$marker-$e',
        };
      }
    } finally {
      final marker = await cleanup;
      out = {
        ...out,
        'cleanup': 'patched-while-runtime-map-recovery-cleanup-$marker',
      };
    }
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
    'mode': 'patched-while-await-condition-map-recovery-cleanup-head',
  };
  while (await keepGoing) {
    try {
      try {
        if (await skip) continue;
        if (await stop) break;
        if (await fail) {
          throw 'patched-while-await-condition-map-recovery-cleanup-error';
        }
        out = {
          ...out,
          for (final entry in extra.entries)
            'patched-while-await-condition-map-recovery-cleanup-extra-${entry.key}':
                entry.value,
        };
      } catch (e) {
        final marker = await recovery;
        out = {
          ...out,
          'error':
              'patched-while-await-condition-map-recovery-cleanup-caught-$marker-$e',
        };
      }
    } finally {
      final marker = await cleanup;
      out = {
        ...out,
        'cleanup': 'patched-while-await-condition-map-recovery-cleanup-$marker',
      };
    }
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
  var out = <String>['patched-do-switch-collection-recovery-head'];
  do {
    try {
      try {
        if (await skip) continue;
        if (await stop) break;
        if (await fail) {
          throw 'patched-do-switch-collection-recovery-error-$i';
        }
        out = [
          ...out,
          ...switch (tier) {
            'gold' ||
            'vip' => ['patched-do-switch-collection-recovery-premium'],
            _ => ['patched-do-switch-collection-recovery-standard'],
          },
          for (final value in extra)
            'patched-do-switch-collection-recovery-extra-$value-$i',
        ];
        i = i + 1;
      } catch (e) {
        final marker = await recovery;
        out = [
          ...out,
          'patched-do-switch-collection-recovery-caught-$marker-$e',
        ];
      }
    } finally {
      final marker = await cleanup;
      out = [...out, 'patched-do-switch-collection-recovery-cleanup-$marker'];
    }
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
  var out = <String>['patched-while-nested-list-double-cleanup-head'];
  while (i < limit) {
    try {
      if (await skip) continue;
      if (await stop) break;
      if (premium) {
        final state = await ready;
        out = [
          ...out,
          'patched-while-nested-list-double-cleanup-premium-$state-$i',
          for (final value in extra)
            'patched-while-nested-list-double-cleanup-extra-$value-$i',
        ];
      } else {
        out = [...out, 'patched-while-nested-list-double-cleanup-basic-$i'];
      }
      i = i + 1;
    } finally {
      final marker = await cleanup;
      final tail = await cleanupTail;
      out = [...out, 'patched-while-nested-list-double-cleanup-$marker-$tail'];
    }
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
  var out = <String>['patched-for-switch-collection-double-cleanup-head'];
  for (var i = 0; i < limit; i = i + 1) {
    try {
      if (await skip) continue;
      if (await stop) break;
      out = [
        ...out,
        ...switch (tier) {
          'gold' ||
          'vip' => ['patched-for-switch-collection-double-cleanup-premium'],
          _ => ['patched-for-switch-collection-double-cleanup-standard'],
        },
        for (final value in extra)
          'patched-for-switch-collection-double-cleanup-extra-$value-$i',
      ];
    } finally {
      final marker = await cleanup;
      final tail = await cleanupTail;
      out = [
        ...out,
        'patched-for-switch-collection-double-cleanup-$marker-$tail',
      ];
    }
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
    'patched-do-await-condition-switch-collection-double-cleanup-head',
  ];
  do {
    try {
      if (await skip) continue;
      if (await stop) break;
      out = [
        ...out,
        ...switch (tier) {
          'gold' || 'vip' => [
            'patched-do-await-condition-switch-collection-double-cleanup-premium',
          ],
          _ => [
            'patched-do-await-condition-switch-collection-double-cleanup-standard',
          ],
        },
        for (final value in extra)
          'patched-do-await-condition-switch-collection-double-cleanup-extra-$value',
      ];
    } finally {
      final marker = await cleanup;
      final tail = await cleanupTail;
      out = [
        ...out,
        'patched-do-await-condition-switch-collection-double-cleanup-$marker-$tail',
      ];
    }
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
    'mode': 'patched-while-map-switch-recovery-double-cleanup-head',
  };
  while (i < limit) {
    try {
      try {
        if (await skip) continue;
        if (await stop) break;
        if (await fail) {
          throw 'patched-while-map-switch-recovery-double-cleanup-error-$i';
        }
        out = {
          ...out,
          ...switch (tier) {
            'gold' || 'vip' => {
              'state':
                  'patched-while-map-switch-recovery-double-cleanup-premium',
            },
            _ => {
              'state':
                  'patched-while-map-switch-recovery-double-cleanup-standard',
            },
          },
          for (final entry in extra.entries)
            'patched-while-map-switch-recovery-double-cleanup-extra-${entry.key}':
                '${entry.value}-$i',
        };
        i = i + 1;
      } catch (e) {
        final marker = await recovery;
        out = {
          ...out,
          'error':
              'patched-while-map-switch-recovery-double-cleanup-caught-$marker-$e',
        };
      }
    } finally {
      final marker = await cleanup;
      final tail = await cleanupTail;
      out = {
        ...out,
        'cleanup':
            'patched-while-map-switch-recovery-double-cleanup-$marker-$tail',
      };
    }
  }
  return out;
}
