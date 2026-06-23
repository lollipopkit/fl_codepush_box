Iterable<String> syncGenerated() sync* {
  yield 'patched-iterable';
}

Iterable<String> syncGeneratedMany(bool enabled) sync* {
  final prefix = 'patched-iterable';
  yield '$prefix-a';
  if (enabled) yield '$prefix-live';
  yield '$prefix-tail';
}

Iterable<String> syncGeneratedWhile() sync* {
  var i = 0;
  while (2 > i) {
    yield 'patched-iterable-while-$i';
    i = i + 1;
  }
}

Iterable<String> syncGeneratedWhileBreak() sync* {
  var i = 0;
  while (4 > i) {
    yield 'patched-iterable-while-break-before-$i';
    if (i == 2) break;
    yield 'patched-iterable-while-break-after-$i';
    i = i + 1;
  }
}

Iterable<String> syncGeneratedWhileContinue() sync* {
  var i = 0;
  while (3 > i) {
    yield 'patched-iterable-while-continue-before-$i';
    if (i == 1) {
      i = i + 1;
      continue;
    }
    yield 'patched-iterable-while-continue-after-$i';
    i = i + 1;
  }
}

Iterable<String> syncGeneratedWhileContinueBreak() sync* {
  var i = 0;
  while (4 > i) {
    yield 'patched-iterable-while-continue-before-$i';
    if (i == 1) {
      i = i + 1;
      continue;
    }
    yield 'patched-iterable-while-continue-mid-$i';
    if (i == 2) break;
    yield 'patched-iterable-while-continue-after-$i';
    i = i + 1;
  }
}

Iterable<String> syncGeneratedDoWhile() sync* {
  var i = 0;
  do {
    yield 'patched-iterable-do-$i';
    i = i + 1;
  } while (2 > i);
}

Iterable<String> syncGeneratedDoWhileBreak() sync* {
  var i = 0;
  do {
    yield 'patched-iterable-do-break-before-$i';
    if (i == 1) break;
    yield 'patched-iterable-do-break-after-$i';
    i = i + 1;
  } while (3 > i);
}

Iterable<String> syncGeneratedDoWhileContinue() sync* {
  var i = 0;
  do {
    yield 'patched-iterable-do-continue-before-$i';
    if (i == 1) {
      i = i + 1;
      continue;
    }
    yield 'patched-iterable-do-continue-after-$i';
    i = i + 1;
  } while (3 > i);
}

Iterable<String> syncGeneratedDoWhileContinueBreak() sync* {
  var i = 0;
  do {
    yield 'patched-iterable-do-continue-before-$i';
    if (i == 1) {
      i = i + 1;
      continue;
    }
    yield 'patched-iterable-do-continue-mid-$i';
    if (i == 2) break;
    yield 'patched-iterable-do-continue-after-$i';
    i = i + 1;
  } while (4 > i);
}

Iterable<String> syncGeneratedForLoop() sync* {
  for (var i = 0; 2 > i; i = i + 1) {
    yield 'patched-iterable-for-$i';
  }
}

Iterable<String> syncGeneratedForLoopPostIncrement() sync* {
  for (var i = 0; 2 > i; i++) {
    yield 'patched-iterable-for-postinc-$i';
  }
}

Iterable<String> syncGeneratedForLoopMultiUpdate() sync* {
  for (var i = 0, j = 10; 2 > i; i = i + 1, j = j + 1) {
    yield 'patched-iterable-for-multi-$i-$j';
  }
}

Iterable<String> syncGeneratedForLoopExternalLocal() sync* {
  var i = 0;
  for (; 2 > i; i = i + 1) {
    yield 'patched-iterable-for-external-$i';
  }
}

Iterable<String> syncGeneratedForLoopBodyUpdate() sync* {
  var i = 0;
  for (; 2 > i;) {
    yield 'patched-iterable-for-body-update-$i';
    i = i + 1;
  }
}

Iterable<String> syncGeneratedForLoopContinue() sync* {
  for (var i = 0; 3 > i; i = i + 1) {
    yield 'patched-iterable-for-continue-before-$i';
    if (i == 1) continue;
    yield 'patched-iterable-for-continue-after-$i';
  }
}

Iterable<String> syncGeneratedForLoopContinueBreak() sync* {
  for (var i = 0; 4 > i; i = i + 1) {
    yield 'patched-iterable-for-continue-before-$i';
    if (i == 1) continue;
    yield 'patched-iterable-for-continue-mid-$i';
    if (i == 2) break;
    yield 'patched-iterable-for-continue-after-$i';
  }
}

Iterable<String> syncGeneratedForLoopBreak() sync* {
  for (var i = 0; 3 > i; i = i + 1) {
    yield 'patched-iterable-for-break-before-$i';
    if (i == 1) break;
    yield 'patched-iterable-for-break-after-$i';
  }
}

Iterable<String> syncGeneratedForIn() sync* {
  for (final value in ['patched-iterable-a', 'patched-iterable-b']) {
    yield value;
  }
}

Iterable<String> syncGeneratedForInBreak() sync* {
  final prefix = 'patched-iterable-static-break';
  for (final value in ['a', 'stop', 'tail']) {
    yield '$prefix-before-$value';
    if (value == 'stop') break;
    yield '$prefix-after-$value';
  }
}

Iterable<String> syncGeneratedForInBreakFirst() sync* {
  final prefix = 'patched-iterable-static-break-first';
  for (final value in ['a', 'stop', 'tail']) {
    if (value == 'stop') break;
    yield '$prefix-$value';
  }
}

Iterable<String> syncGeneratedForInContinue() sync* {
  final prefix = 'patched-iterable-static-continue';
  for (final value in ['a', 'skip', 'tail']) {
    if (value == 'skip') continue;
    yield '$prefix-$value';
  }
}

Iterable<String> syncGeneratedForInContinueAfterYield() sync* {
  final prefix = 'patched-iterable-static-continue-after-yield';
  for (final value in ['a', 'skip', 'tail']) {
    yield '$prefix-before-$value';
    if (value == 'skip') continue;
    yield '$prefix-after-$value';
  }
}

Iterable<String> syncGeneratedDynamicForIn(List<String> extra) sync* {
  for (final value in extra) {
    yield value;
  }
  yield 'patched-iterable-dynamic-tail';
}

Iterable<String> syncGeneratedDynamicForInMapped(List<String> extra) sync* {
  final prefix = 'patched-iterable-map';
  for (final value in extra) {
    yield '$prefix-$value';
  }
}

Iterable<String> syncGeneratedDynamicForInMany(List<String> extra) sync* {
  final prefix = 'patched-iterable-many';
  for (final value in extra) {
    yield '$prefix-a-$value';
    yield '$prefix-b-$value';
  }
}

Iterable<String> syncGeneratedDynamicForInIf(List<String> extra) sync* {
  final prefix = 'patched-iterable-if';
  for (final value in extra) {
    if (value == 'live') yield '$prefix-hit-$value';
    yield '$prefix-tail-$value';
  }
}

Iterable<String> syncGeneratedDynamicForInIfElse(List<String> extra) sync* {
  final prefix = 'patched-iterable-ifelse';
  for (final value in extra) {
    if (value == 'live') {
      yield '$prefix-hit-$value';
    } else {
      yield '$prefix-miss-$value';
    }
  }
}

Iterable<String> syncGeneratedDynamicForInLocal(List<String> extra) sync* {
  final prefix = 'patched-iterable-local';
  for (final value in extra) {
    final marker = '$prefix-$value';
    yield marker;
  }
}

Iterable<String> syncGeneratedDynamicForInContinue(List<String> extra) sync* {
  final prefix = 'patched-iterable-continue';
  for (final value in extra) {
    if (value == 'skip') continue;
    yield '$prefix-$value';
  }
}

Iterable<String> syncGeneratedDynamicForInContinueAfterYield(
  List<String> extra,
) sync* {
  final prefix = 'patched-iterable-continue-after-yield';
  for (final value in extra) {
    yield '$prefix-before-$value';
    if (value == 'skip') continue;
    yield '$prefix-after-$value';
  }
}

Iterable<String> syncGeneratedDynamicForInBreak(List<String> extra) sync* {
  final prefix = 'patched-iterable-break';
  for (final value in extra) {
    if (value == 'stop') break;
    yield '$prefix-$value';
  }
}

Iterable<String> syncGeneratedDynamicForInBreakAfterYield(
  List<String> extra,
) sync* {
  final prefix = 'patched-iterable-break-after-yield';
  for (final value in extra) {
    yield '$prefix-before-$value';
    if (value == 'stop') break;
    yield '$prefix-after-$value';
  }
}

Iterable<String> syncGeneratedDynamicForInBreakAtEnd(List<String> extra) sync* {
  final prefix = 'patched-iterable-break-at-end';
  for (final value in extra) {
    yield '$prefix-before-$value';
    if (value == 'stop') break;
  }
}

Iterable<String> syncGeneratedDynamicForInContinueThenBreak(
  List<String> extra,
) sync* {
  final prefix = 'patched-iterable-continue-break';
  for (final value in extra) {
    if (value == 'skip') continue;
    if (value == 'stop') break;
    yield '$prefix-$value';
  }
}

Iterable<String> syncGeneratedDynamicForInContinueYieldBreak(
  List<String> extra,
) sync* {
  final prefix = 'patched-iterable-continue-yield-break';
  for (final value in extra) {
    if (value == 'skip') continue;
    yield '$prefix-before-$value';
    if (value == 'stop') break;
    yield '$prefix-after-$value';
  }
}

Iterable<String> syncGeneratedDynamicForInNested(
  List<String> extra,
  List<String> suffixes,
) sync* {
  final prefix = 'patched-iterable-nested';
  for (final value in extra) {
    for (final suffix in suffixes) {
      yield '$prefix-$value-$suffix';
    }
  }
}

Iterable<String> syncGeneratedDynamicForInNestedBreakContinue(
  List<String> extra,
  List<String> suffixes,
) sync* {
  final prefix = 'patched-iterable-nested-control';
  for (final value in extra) {
    if (value == 'skip') continue;
    for (final suffix in suffixes) {
      if (suffix == 'skip') continue;
      yield '$prefix-$value-$suffix';
      if (suffix == 'stop') break;
    }
    if (value == 'stop') break;
  }
}

Iterable<String> syncGeneratedYieldStar() sync* {
  yield* ['patched-yield-star-a', 'patched-yield-star-b'];
}

Iterable<String> syncGeneratedYieldStarDynamic(List<String> extra) sync* {
  yield* extra;
  yield 'patched-yield-star-dynamic-tail';
}

Iterable<String> syncGeneratedSwitchOrPatternExpr(String tier) sync* {
  yield switch (tier) {
    'gold' || 'vip' => 'patched-iterable-switch-or-premium',
    'trial' || 'guest' => 'patched-iterable-switch-or-limited',
    _ => 'patched-iterable-switch-or-other',
  };
}

Iterable<String> syncGeneratedSwitchOrPatternStatement(String tier) sync* {
  switch (tier) {
    case 'gold' || 'vip':
      yield 'patched-iterable-switch-stmt-or-premium';
    case 'trial' || 'guest':
      yield 'patched-iterable-switch-stmt-or-limited';
    default:
      yield 'patched-iterable-switch-stmt-or-other';
  }
}

Iterable<String> syncGeneratedGuardedSwitchExpr(
  String tier,
  bool enabled,
) sync* {
  yield switch (tier) {
    'gold' when enabled => 'patched-iterable-guarded-switch-gold',
    'vip' when enabled => 'patched-iterable-guarded-switch-vip',
    _ => 'patched-iterable-guarded-switch-other',
  };
}

Iterable<String> syncGeneratedGuardedSwitchStatement(
  String tier,
  bool enabled,
) sync* {
  switch (tier) {
    case 'gold' when enabled:
      yield 'patched-iterable-guarded-switch-stmt-gold';
    case 'vip' when enabled:
      yield 'patched-iterable-guarded-switch-stmt-vip';
    default:
      yield 'patched-iterable-guarded-switch-stmt-other';
  }
}

Iterable<String> syncGeneratedWhileSwitchOrPatternStatement() sync* {
  var i = 0;
  while (3 > i) {
    switch (i) {
      case 0 || 1:
        yield 'patched-iterable-while-switch-or-premium-$i';
      default:
        yield 'patched-iterable-while-switch-or-other-$i';
    }
    i = i + 1;
  }
}

Iterable<String> syncGeneratedForSwitchOrPatternStatement() sync* {
  for (var i = 0; 3 > i; i = i + 1) {
    switch (i) {
      case 0 || 1:
        yield 'patched-iterable-for-switch-or-premium-$i';
      default:
        yield 'patched-iterable-for-switch-or-other-$i';
    }
  }
}
