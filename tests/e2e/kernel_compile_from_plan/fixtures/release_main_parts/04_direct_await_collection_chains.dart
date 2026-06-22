Future<List<String>> asyncAwaitConditionNames(Future<bool> ready) async {
  return await ready
      ? ['base-await-condition-live']
      : ['base-await-condition-off'];
}

Future<List<String>> asyncAwaitConditionDynamicNames(
  Future<bool> ready,
  List<String> extra,
) async {
  return await ready ? ['base-await-condition-live', ...extra] : extra;
}

Future<List<String>> asyncAwaitConditionRuntimeNames(
  Future<bool> ready,
  List<String> extra,
) async {
  return await ready
      ? ['base-await-condition-live', for (final item in extra) item]
      : extra;
}

Future<List<String>> asyncAwaitConditionDynamicRuntimeNames(
  Future<bool> ready,
  List<String> extra,
  List<String> tail,
) async {
  return await ready
      ? ['base-await-condition-live', ...extra, for (final item in tail) item]
      : extra;
}

Future<List<String>> asyncAwaitConditionDynamicRuntimeStaticSpreadNames(
  Future<bool> ready,
  List<String> extra,
  List<String> tail,
) async {
  return await ready
      ? [
          'base-await-condition-live',
          ...extra,
          for (final item in tail) item,
          ...['base-await-condition-tail-a', 'base-await-condition-tail-b'],
        ]
      : extra;
}

Future<List<String>> asyncAwaitConditionDynamicRuntimeTailNames(
  Future<bool> ready,
  List<String> extra,
  List<String> tail,
) async {
  return await ready
      ? [
          'base-await-condition-live',
          ...extra,
          for (final item in tail) item,
          'base-await-condition-tail',
        ]
      : extra;
}

Future<List<String>> asyncAwaitConditionDynamicRuntimeDynamicNames(
  Future<bool> ready,
  List<String> extra,
  List<String> middle,
  List<String> tail,
) async {
  return await ready
      ? [
          'base-await-condition-live',
          ...extra,
          for (final item in middle) item,
          ...tail,
        ]
      : extra;
}

Future<List<String>> asyncAwaitConditionDynamicDynamicRuntimeNames(
  Future<bool> ready,
  List<String> extra,
  List<String> middle,
  List<String> tail,
) async {
  return await ready
      ? [
          'base-await-condition-live',
          ...extra,
          ...middle,
          for (final item in tail) item,
        ]
      : extra;
}

Future<List<String>> asyncAwaitConditionDynamicDynamicDynamicNames(
  Future<bool> ready,
  List<String> extra,
  List<String> middle,
  List<String> tail,
) async {
  return await ready
      ? [
          'base-await-condition-live',
          ...extra,
          ...middle,
          ...tail,
        ]
      : extra;
}

Future<List<String>> asyncAwaitConditionRuntimeDynamicNames(
  Future<bool> ready,
  List<String> extra,
  List<String> tail,
) async {
  return await ready
      ? ['base-await-condition-live', for (final item in extra) item, ...tail]
      : extra;
}

Future<List<String>> asyncAwaitConditionRuntimeDynamicStaticSpreadNames(
  Future<bool> ready,
  List<String> extra,
  List<String> tail,
) async {
  return await ready
      ? [
          'base-await-condition-live',
          for (final item in extra) item,
          ...tail,
          ...['base-await-condition-tail-a', 'base-await-condition-tail-b'],
        ]
      : extra;
}

Future<List<String>> asyncAwaitConditionRuntimeDynamicTailNames(
  Future<bool> ready,
  List<String> extra,
  List<String> tail,
) async {
  return await ready
      ? [
          'base-await-condition-live',
          for (final item in extra) item,
          ...tail,
          'base-await-condition-tail',
        ]
      : extra;
}

Future<List<String>> asyncAwaitConditionRuntimeDynamicRuntimeNames(
  Future<bool> ready,
  List<String> extra,
  List<String> middle,
  List<String> tail,
) async {
  return await ready
      ? [
          'base-await-condition-live',
          for (final item in extra) item,
          ...middle,
          for (final item in tail) item,
        ]
      : extra;
}

Future<List<String>> asyncAwaitConditionRuntimeRuntimeDynamicNames(
  Future<bool> ready,
  List<String> extra,
  List<String> middle,
  List<String> tail,
) async {
  return await ready
      ? [
          'base-await-condition-live',
          for (final item in extra) item,
          for (final item in middle) item,
          ...tail,
        ]
      : extra;
}

Future<List<String>> asyncAwaitConditionRuntimeRuntimeRuntimeNames(
  Future<bool> ready,
  List<String> extra,
  List<String> middle,
  List<String> tail,
) async {
  return await ready
      ? [
          'base-await-condition-live',
          for (final item in extra) item,
          for (final item in middle) item,
          for (final item in tail) item,
        ]
      : extra;
}

Future<List<String>> asyncAwaitConditionDynamicTailNames(
  Future<bool> ready,
  List<String> extra,
) async {
  return await ready
      ? ['base-await-condition-live', ...extra, 'base-await-condition-tail']
      : extra;
}

Future<List<String>> asyncAwaitConditionRuntimeTailNames(
  Future<bool> ready,
  List<String> extra,
) async {
  return await ready
      ? [
          'base-await-condition-live',
          for (final item in extra) item,
          'base-await-condition-tail',
        ]
      : extra;
}

Future<List<String>> asyncAwaitConditionDynamicStaticSpreadNames(
  Future<bool> ready,
  List<String> extra,
) async {
  return await ready
      ? [
          'base-await-condition-live',
          ...extra,
          ...['base-await-condition-tail-a', 'base-await-condition-tail-b'],
        ]
      : extra;
}

Future<List<String>> asyncAwaitConditionRuntimeStaticSpreadNames(
  Future<bool> ready,
  List<String> extra,
) async {
  return await ready
      ? [
          'base-await-condition-live',
          for (final item in extra) item,
          ...['base-await-condition-tail-a', 'base-await-condition-tail-b'],
        ]
      : extra;
}

Future<List<String>> asyncAwaitConditionTryCatchDynamicRuntimeNames(
  Future<bool> ready,
  List<String> extra,
  List<String> tail,
) async {
  return await ready ? ['base-await-condition-try-catch-list'] : extra;
}

Future<List<String>> asyncAwaitThenTryFinallyDynamicRuntimeNames(
  Future<bool> ready,
  List<String> extra,
  List<String> tail,
) async {
  final enabled = await ready;
  return enabled ? ['base-await-then-try-finally-list', ...extra] : tail;
}

Future<List<String>> asyncAwaitConditionTryCatchFinallyRuntimeDynamicNames(
  Future<bool> ready,
  List<String> extra,
  List<String> tail,
) async {
  return await ready
      ? ['base-await-condition-try-catch-finally-list', for (final item in extra) item]
      : tail;
}

Future<Map<String, String>> asyncAwaitConditionLabels(
  Future<bool> ready,
) async {
  return await ready
      ? {'state': 'base-await-condition-live'}
      : {'state': 'base-await-condition-off'};
}

Future<Map<String, String>> asyncAwaitConditionDynamicLabels(
  Future<bool> ready,
  Map<String, String> extra,
) async {
  return await ready ? {'state': 'base-await-condition-live', ...extra} : extra;
}

Future<Map<String, String>> asyncAwaitConditionRuntimeLabels(
  Future<bool> ready,
  Map<String, String> extra,
) async {
  return await ready
      ? {
          'state': 'base-await-condition-live',
          for (final entry in extra.entries) entry.key: entry.value,
        }
      : extra;
}

Future<Map<String, String>> asyncAwaitConditionDynamicRuntimeLabels(
  Future<bool> ready,
  Map<String, String> extra,
  Map<String, String> tail,
) async {
  return await ready
      ? {
          'state': 'base-await-condition-live',
          ...extra,
          for (final entry in tail.entries) entry.key: entry.value,
        }
      : extra;
}

Future<Map<String, String>> asyncAwaitConditionDynamicRuntimeStaticSpreadLabels(
  Future<bool> ready,
  Map<String, String> extra,
  Map<String, String> tail,
) async {
  return await ready
      ? {
          'state': 'base-await-condition-live',
          ...extra,
          for (final entry in tail.entries) entry.key: entry.value,
          ...{'tail': 'base-await-condition-tail'},
        }
      : extra;
}

Future<Map<String, String>> asyncAwaitConditionDynamicRuntimeTailLabels(
  Future<bool> ready,
  Map<String, String> extra,
  Map<String, String> tail,
) async {
  return await ready
      ? {
          'state': 'base-await-condition-live',
          ...extra,
          for (final entry in tail.entries) entry.key: entry.value,
          'tail': 'base-await-condition-tail',
        }
      : extra;
}

Future<Map<String, String>> asyncAwaitConditionDynamicRuntimeDynamicLabels(
  Future<bool> ready,
  Map<String, String> extra,
  Map<String, String> middle,
  Map<String, String> tail,
) async {
  return await ready
      ? {
          'state': 'base-await-condition-live',
          ...extra,
          for (final entry in middle.entries) entry.key: entry.value,
          ...tail,
        }
      : extra;
}

Future<Map<String, String>> asyncAwaitConditionDynamicDynamicRuntimeLabels(
  Future<bool> ready,
  Map<String, String> extra,
  Map<String, String> middle,
  Map<String, String> tail,
) async {
  return await ready
      ? {
          'state': 'base-await-condition-live',
          ...extra,
          ...middle,
          for (final entry in tail.entries) entry.key: entry.value,
        }
      : extra;
}

Future<Map<String, String>> asyncAwaitConditionDynamicDynamicDynamicLabels(
  Future<bool> ready,
  Map<String, String> extra,
  Map<String, String> middle,
  Map<String, String> tail,
) async {
  return await ready
      ? {
          'state': 'base-await-condition-live',
          ...extra,
          ...middle,
          ...tail,
        }
      : extra;
}

Future<Map<String, String>> asyncAwaitConditionRuntimeDynamicLabels(
  Future<bool> ready,
  Map<String, String> extra,
  Map<String, String> tail,
) async {
  return await ready
      ? {
          'state': 'base-await-condition-live',
          for (final entry in extra.entries) entry.key: entry.value,
          ...tail,
        }
      : extra;
}

Future<Map<String, String>> asyncAwaitConditionRuntimeDynamicStaticSpreadLabels(
  Future<bool> ready,
  Map<String, String> extra,
  Map<String, String> tail,
) async {
  return await ready
      ? {
          'state': 'base-await-condition-live',
          for (final entry in extra.entries) entry.key: entry.value,
          ...tail,
          ...{'tail': 'base-await-condition-tail'},
        }
      : extra;
}

Future<Map<String, String>> asyncAwaitConditionRuntimeDynamicTailLabels(
  Future<bool> ready,
  Map<String, String> extra,
  Map<String, String> tail,
) async {
  return await ready
      ? {
          'state': 'base-await-condition-live',
          for (final entry in extra.entries) entry.key: entry.value,
          ...tail,
          'tail': 'base-await-condition-tail',
        }
      : extra;
}

Future<Map<String, String>> asyncAwaitConditionRuntimeDynamicRuntimeLabels(
  Future<bool> ready,
  Map<String, String> extra,
  Map<String, String> middle,
  Map<String, String> tail,
) async {
  return await ready
      ? {
          'state': 'base-await-condition-live',
          for (final entry in extra.entries) entry.key: entry.value,
          ...middle,
          for (final entry in tail.entries) entry.key: entry.value,
        }
      : extra;
}

Future<Map<String, String>> asyncAwaitConditionRuntimeRuntimeDynamicLabels(
  Future<bool> ready,
  Map<String, String> extra,
  Map<String, String> middle,
  Map<String, String> tail,
) async {
  return await ready
      ? {
          'state': 'base-await-condition-live',
          for (final entry in extra.entries) entry.key: entry.value,
          for (final entry in middle.entries) entry.key: entry.value,
          ...tail,
        }
      : extra;
}

Future<Map<String, String>> asyncAwaitConditionRuntimeRuntimeRuntimeLabels(
  Future<bool> ready,
  Map<String, String> extra,
  Map<String, String> middle,
  Map<String, String> tail,
) async {
  return await ready
      ? {
          'state': 'base-await-condition-live',
          for (final entry in extra.entries) entry.key: entry.value,
          for (final entry in middle.entries) entry.key: entry.value,
          for (final entry in tail.entries) entry.key: entry.value,
        }
      : extra;
}

Future<Map<String, String>> asyncAwaitConditionDynamicTailLabels(
  Future<bool> ready,
  Map<String, String> extra,
) async {
  return await ready
      ? {
          'state': 'base-await-condition-live',
          ...extra,
          'tail': 'base-await-condition-tail',
        }
      : extra;
}

Future<Map<String, String>> asyncAwaitConditionRuntimeTailLabels(
  Future<bool> ready,
  Map<String, String> extra,
) async {
  return await ready
      ? {
          'state': 'base-await-condition-live',
          for (final entry in extra.entries) entry.key: entry.value,
          'tail': 'base-await-condition-tail',
        }
      : extra;
}

Future<Map<String, String>> asyncAwaitConditionDynamicStaticSpreadLabels(
  Future<bool> ready,
  Map<String, String> extra,
) async {
  return await ready
      ? {
          'state': 'base-await-condition-live',
          ...extra,
          ...{'tail': 'base-await-condition-tail'},
        }
      : extra;
}

Future<Map<String, String>> asyncAwaitConditionRuntimeStaticSpreadLabels(
  Future<bool> ready,
  Map<String, String> extra,
) async {
  return await ready
      ? {
          'state': 'base-await-condition-live',
          for (final entry in extra.entries) entry.key: entry.value,
          ...{'tail': 'base-await-condition-tail'},
        }
      : extra;
}

Future<Map<String, String>> asyncAwaitConditionTryCatchDynamicRuntimeLabels(
  Future<bool> ready,
  Map<String, String> extra,
  Map<String, String> tail,
) async {
  return await ready ? {'state': 'base-await-condition-try-catch-map', ...extra} : tail;
}

Future<Map<String, String>> asyncAwaitThenTryFinallyDynamicRuntimeLabels(
  Future<bool> ready,
  Map<String, String> extra,
  Map<String, String> tail,
) async {
  final enabled = await ready;
  return enabled ? {'state': 'base-await-then-try-finally-map', ...extra} : tail;
}

Future<Map<String, String>>
asyncAwaitConditionTryCatchFinallyRuntimeDynamicLabels(
  Future<bool> ready,
  Map<String, String> extra,
  Map<String, String> tail,
) async {
  return await ready
      ? {
          'state': 'base-await-condition-try-catch-finally-map',
          for (final entry in extra.entries) entry.key: entry.value,
        }
      : tail;
}
