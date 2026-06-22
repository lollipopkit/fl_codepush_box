Stream<String> asyncGenerated() async* {
  yield 'base-stream';
}

Stream<String> asyncGeneratedAwait(Future<String> ready) async* {
  final value = await ready;
  yield 'base-stream-await-$value';
}

Stream<String> asyncGeneratedTryFinally(Future<String> ready) async* {
  try {
    yield await ready;
  } finally {
    final cleanup = 'base-stream-finally-cleanup';
  }
}

Stream<String> asyncGeneratedFinallyYield(Future<String> ready) async* {
  yield 'base-stream-finally-yield';
}

Stream<String> asyncGeneratedCatchAwait(Future<String> ready) async* {
  yield 'base-stream-catch-await';
}

Stream<String> asyncGeneratedMany(bool enabled) async* {
  final prefix = 'base-stream';
  yield '$prefix-a';
  if (enabled) yield '$prefix-live';
  yield '$prefix-tail';
}

Stream<String> asyncGeneratedWhile() async* {
  var i = 0;
  while (2 > i) {
    yield 'base-stream-while-$i';
    i = i + 1;
  }
}

Stream<String> asyncGeneratedWhileBreak() async* {
  var i = 0;
  while (4 > i) {
    yield 'base-stream-while-break-before-$i';
    if (i == 2) break;
    yield 'base-stream-while-break-after-$i';
    i = i + 1;
  }
}

Stream<String> asyncGeneratedWhileContinue() async* {
  var i = 0;
  while (3 > i) {
    yield 'base-stream-while-continue-before-$i';
    if (i == 1) {
      i = i + 1;
      continue;
    }
    yield 'base-stream-while-continue-after-$i';
    i = i + 1;
  }
}

Stream<String> asyncGeneratedWhileContinueBreak() async* {
  var i = 0;
  while (4 > i) {
    yield 'base-stream-while-continue-before-$i';
    if (i == 1) {
      i = i + 1;
      continue;
    }
    yield 'base-stream-while-continue-mid-$i';
    if (i == 2) break;
    yield 'base-stream-while-continue-after-$i';
    i = i + 1;
  }
}

Stream<String> asyncGeneratedDoWhile() async* {
  var i = 0;
  do {
    yield 'base-stream-do-$i';
    i = i + 1;
  } while (2 > i);
}

Stream<String> asyncGeneratedDoWhileBreak() async* {
  var i = 0;
  do {
    yield 'base-stream-do-break-before-$i';
    if (i == 1) break;
    yield 'base-stream-do-break-after-$i';
    i = i + 1;
  } while (3 > i);
}

Stream<String> asyncGeneratedDoWhileContinue() async* {
  var i = 0;
  do {
    yield 'base-stream-do-continue-before-$i';
    if (i == 1) {
      i = i + 1;
      continue;
    }
    yield 'base-stream-do-continue-after-$i';
    i = i + 1;
  } while (3 > i);
}

Stream<String> asyncGeneratedDoWhileContinueBreak() async* {
  var i = 0;
  do {
    yield 'base-stream-do-continue-before-$i';
    if (i == 1) {
      i = i + 1;
      continue;
    }
    yield 'base-stream-do-continue-mid-$i';
    if (i == 2) break;
    yield 'base-stream-do-continue-after-$i';
    i = i + 1;
  } while (4 > i);
}

Stream<String> asyncGeneratedForLoop() async* {
  for (var i = 0; 2 > i; i = i + 1) {
    yield 'base-stream-for-$i';
  }
}

Stream<String> asyncGeneratedForLoopPostIncrement() async* {
  for (var i = 0; 2 > i; i++) {
    yield 'base-stream-for-postinc-$i';
  }
}

Stream<String> asyncGeneratedForLoopMultiUpdate() async* {
  for (var i = 0, j = 10; 2 > i; i = i + 1, j = j + 1) {
    yield 'base-stream-for-multi-$i-$j';
  }
}

Stream<String> asyncGeneratedForLoopExternalLocal() async* {
  var i = 0;
  for (; 2 > i; i = i + 1) {
    yield 'base-stream-for-external-$i';
  }
}

Stream<String> asyncGeneratedForLoopBodyUpdate() async* {
  var i = 0;
  for (; 2 > i;) {
    yield 'base-stream-for-body-update-$i';
    i = i + 1;
  }
}

Stream<String> asyncGeneratedForLoopContinue() async* {
  for (var i = 0; 3 > i; i = i + 1) {
    yield 'base-stream-for-continue-before-$i';
    if (i == 1) continue;
    yield 'base-stream-for-continue-after-$i';
  }
}

Stream<String> asyncGeneratedForLoopContinueBreak() async* {
  for (var i = 0; 4 > i; i = i + 1) {
    yield 'base-stream-for-continue-before-$i';
    if (i == 1) continue;
    yield 'base-stream-for-continue-mid-$i';
    if (i == 2) break;
    yield 'base-stream-for-continue-after-$i';
  }
}

Stream<String> asyncGeneratedForLoopBreak() async* {
  for (var i = 0; 3 > i; i = i + 1) {
    yield 'base-stream-for-break-before-$i';
    if (i == 1) break;
    yield 'base-stream-for-break-after-$i';
  }
}

Stream<String> asyncGeneratedForIn() async* {
  for (final value in ['base-stream-a', 'base-stream-b']) {
    yield value;
  }
}

Stream<String> asyncGeneratedForInBreak() async* {
  final prefix = 'base-stream-static-break';
  for (final value in ['a', 'stop', 'tail']) {
    yield '$prefix-before-$value';
    if (value == 'stop') break;
    yield '$prefix-after-$value';
  }
}

Stream<String> asyncGeneratedForInBreakFirst() async* {
  final prefix = 'base-stream-static-break-first';
  for (final value in ['a', 'stop', 'tail']) {
    if (value == 'stop') break;
    yield '$prefix-$value';
  }
}

Stream<String> asyncGeneratedForInContinue() async* {
  final prefix = 'base-stream-static-continue';
  for (final value in ['a', 'skip', 'tail']) {
    if (value == 'skip') continue;
    yield '$prefix-$value';
  }
}

Stream<String> asyncGeneratedForInContinueAfterYield() async* {
  final prefix = 'base-stream-static-continue-after-yield';
  for (final value in ['a', 'skip', 'tail']) {
    yield '$prefix-before-$value';
    if (value == 'skip') continue;
    yield '$prefix-after-$value';
  }
}

Stream<String> asyncGeneratedDynamicForIn(List<String> extra) async* {
  for (final value in extra) {
    yield value;
  }
  yield 'base-stream-dynamic-tail';
}

Stream<String> asyncGeneratedDynamicForInMapped(List<String> extra) async* {
  final prefix = 'base-stream-map';
  for (final value in extra) {
    yield '$prefix-$value';
  }
}

Stream<String> asyncGeneratedDynamicForInMany(List<String> extra) async* {
  final prefix = 'base-stream-many';
  for (final value in extra) {
    yield '$prefix-a-$value';
    yield '$prefix-b-$value';
  }
}

Stream<String> asyncGeneratedDynamicForInIf(List<String> extra) async* {
  final prefix = 'base-stream-if';
  for (final value in extra) {
    if (value == 'live') yield '$prefix-hit-$value';
    yield '$prefix-tail-$value';
  }
}

Stream<String> asyncGeneratedDynamicForInIfElse(List<String> extra) async* {
  final prefix = 'base-stream-ifelse';
  for (final value in extra) {
    if (value == 'live') {
      yield '$prefix-hit-$value';
    } else {
      yield '$prefix-miss-$value';
    }
  }
}

Stream<String> asyncGeneratedDynamicForInLocal(List<String> extra) async* {
  final prefix = 'base-stream-local';
  for (final value in extra) {
    final marker = '$prefix-$value';
    yield marker;
  }
}

Stream<String> asyncGeneratedDynamicForInContinue(List<String> extra) async* {
  final prefix = 'base-stream-continue';
  for (final value in extra) {
    if (value == 'skip') continue;
    yield '$prefix-$value';
  }
}

Stream<String> asyncGeneratedDynamicForInContinueAfterYield(List<String> extra) async* {
  final prefix = 'base-stream-continue-after-yield';
  for (final value in extra) {
    yield '$prefix-before-$value';
    if (value == 'skip') continue;
    yield '$prefix-after-$value';
  }
}

Stream<String> asyncGeneratedDynamicForInBreak(List<String> extra) async* {
  final prefix = 'base-stream-break';
  for (final value in extra) {
    if (value == 'stop') break;
    yield '$prefix-$value';
  }
}

Stream<String> asyncGeneratedDynamicForInBreakAfterYield(List<String> extra) async* {
  final prefix = 'base-stream-break-after-yield';
  for (final value in extra) {
    yield '$prefix-before-$value';
    if (value == 'stop') break;
    yield '$prefix-after-$value';
  }
}

Stream<String> asyncGeneratedDynamicForInBreakAtEnd(List<String> extra) async* {
  final prefix = 'base-stream-break-at-end';
  for (final value in extra) {
    yield '$prefix-before-$value';
    if (value == 'stop') break;
  }
}

Stream<String> asyncGeneratedDynamicForInContinueThenBreak(List<String> extra) async* {
  final prefix = 'base-stream-continue-break';
  for (final value in extra) {
    if (value == 'skip') continue;
    if (value == 'stop') break;
    yield '$prefix-$value';
  }
}

Stream<String> asyncGeneratedDynamicForInContinueYieldBreak(List<String> extra) async* {
  final prefix = 'base-stream-continue-yield-break';
  for (final value in extra) {
    if (value == 'skip') continue;
    yield '$prefix-before-$value';
    if (value == 'stop') break;
    yield '$prefix-after-$value';
  }
}

Stream<String> asyncGeneratedDynamicForInNested(List<String> extra, List<String> suffixes) async* {
  final prefix = 'base-stream-nested';
  for (final value in extra) {
    for (final suffix in suffixes) {
      yield '$prefix-$value-$suffix';
    }
  }
}

Stream<String> asyncGeneratedDynamicForInNestedBreakContinue(List<String> extra, List<String> suffixes) async* {
  final prefix = 'base-stream-nested-control';
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

Stream<String> asyncGeneratedYieldStar() async* {
  yield* Stream.fromIterable(['base-stream-yield-star-a', 'base-stream-yield-star-b']);
}

Stream<String> asyncGeneratedYieldStarDynamic(List<String> extra) async* {
  yield* Stream.fromIterable(extra);
  yield 'base-stream-yield-star-dynamic-tail';
}

Stream<String> asyncGeneratedYieldStarValue(String value) async* {
  yield* Stream.value('base-stream-yield-star-value-$value');
}

Stream<String> asyncGeneratedYieldStarFromFuture(String value) async* {
  yield* Stream.fromFuture(Future.value('base-stream-yield-star-future-$value'));
}

Stream<String> asyncGeneratedYieldStarPendingFuture(Future<String> ready) async* {
  yield* Stream.value('base-stream-yield-star-pending');
}

Stream<String> asyncGeneratedYieldStarEmpty() async* {
  yield 'base-stream-yield-star-empty-before';
  yield* Stream<String>.empty();
}

Stream<String> asyncGeneratedAwaitForFromIterable(List<String> extra) async* {
  await for (final value in Stream.fromIterable(extra)) {
    yield 'base-stream-await-for-iterable-$value';
  }
}

Stream<String> asyncGeneratedAwaitForContinue(List<String> extra) async* {
  await for (final value in Stream.fromIterable(extra)) {
    if (value == 'skip') continue;
    yield 'base-stream-await-for-continue-$value';
  }
}

Stream<String> asyncGeneratedAwaitForBreak(List<String> extra) async* {
  await for (final value in Stream.fromIterable(extra)) {
    if (value == 'stop') break;
    yield 'base-stream-await-for-break-$value';
  }
}

Stream<String> asyncGeneratedAwaitForValue(String value) async* {
  await for (final item in Stream.value(value)) {
    yield 'base-stream-await-for-value-$item';
  }
}

Stream<String> asyncGeneratedAwaitForFuture(String value) async* {
  await for (final item in Stream.fromFuture(Future.value(value))) {
    yield 'base-stream-await-for-future-$item';
  }
}

Stream<String> asyncGeneratedAwaitForFutureBreak(String value) async* {
  await for (final item in Stream.fromFuture(Future.value(value))) {
    if (item == 'stop') break;
    yield 'base-stream-await-for-future-break-$item';
  }
}

Stream<String> asyncGeneratedAwaitForPendingFuture(Future<String> ready) async* {
  await for (final item in Stream.fromFuture(ready)) {
    yield 'base-stream-await-for-pending-future-$item';
  }
}

Stream<String> asyncGeneratedAwaitForPendingContinue(Future<String> ready) async* {
  await for (final item in Stream.fromFuture(ready)) {
    if (item == 'skip') continue;
    yield 'base-stream-await-for-pending-continue-$item';
  }
}

Stream<String> asyncGeneratedAwaitForFromIterableCatchFinally(List<String> extra) async* {
  yield 'base-stream-await-for-iterable-catch-finally';
}

Stream<String> asyncGeneratedAwaitForFutureCatchFinally(String value) async* {
  yield 'base-stream-await-for-future-catch-finally';
}

Stream<String> asyncGeneratedAwaitForPendingFutureCatchFinally(Future<String> ready) async* {
  yield 'base-stream-await-for-pending-catch-finally';
}

Stream<String> asyncGeneratedAwaitForValueCatchFinally(String value) async* {
  yield 'base-stream-await-for-value-catch-finally';
}

Stream<String> asyncGeneratedAwaitForEmptyCatchFinally() async* {
  yield 'base-stream-await-for-empty-catch-finally';
}

Stream<String> asyncGeneratedAwaitForFutureBreakCatchFinally(String value) async* {
  yield 'base-stream-await-for-future-break-catch-finally';
}

Stream<String> asyncGeneratedAwaitForPendingContinueCatchFinally(Future<String> ready) async* {
  yield 'base-stream-await-for-pending-continue-catch-finally';
}

Stream<String> asyncGeneratedAwaitForEmpty() async* {
  await for (final item in Stream<String>.empty()) {
    yield 'base-stream-await-for-empty-$item';
  }
}

Stream<String> asyncGeneratedYieldStarStream(Stream<String> extra) async* {
  yield 'base-stream-yield-star-stream';
}

Stream<String> asyncGeneratedYieldStarStreamFinally(Stream<String> extra) async* {
  yield 'base-stream-yield-star-stream-finally';
}

Stream<String> asyncGeneratedYieldStarStreamSandwichFinally(Stream<String> extra) async* {
  yield 'base-stream-yield-star-stream-sandwich-finally';
}

Stream<String> asyncGeneratedYieldStarTwoStreamsFinally(Stream<String> first, Stream<String> second) async* {
  yield 'base-stream-yield-star-two-streams-finally';
}

Stream<String> asyncGeneratedYieldStarStreamCatch(Stream<String> extra) async* {
  yield 'base-stream-yield-star-stream-catch';
}

Stream<String> asyncGeneratedYieldStarStreamCatchFinally(Stream<String> extra) async* {
  yield 'base-stream-yield-star-stream-catch-finally';
}

Stream<String> asyncGeneratedYieldStarTwoStreamsCatchFinally(Stream<String> first, Stream<String> second) async* {
  yield 'base-stream-yield-star-two-streams-catch-finally';
}

Stream<String> asyncGeneratedYieldStarDynamicCatchFinally(List<String> extra) async* {
  yield 'base-stream-yield-star-dynamic-catch-finally';
}

Stream<String> asyncGeneratedYieldStarFromFutureCatchFinally(String value) async* {
  yield 'base-stream-yield-star-future-catch-finally';
}

Stream<String> asyncGeneratedYieldStarPendingFutureCatchFinally(Future<String> ready) async* {
  yield 'base-stream-yield-star-pending-catch-finally';
}

Stream<String> asyncGeneratedYieldStarValueCatchFinally(String value) async* {
  yield 'base-stream-yield-star-value-catch-finally';
}

Stream<String> asyncGeneratedYieldStarEmptyCatchFinally() async* {
  yield 'base-stream-yield-star-empty-catch-finally';
}

Stream<String> asyncGeneratedYieldStarStreamSandwichCatchFinally(Stream<String> extra) async* {
  yield 'base-stream-yield-star-stream-sandwich-catch-finally';
}

Stream<String> asyncGeneratedYieldStarTwoStreamsSandwichCatchFinally(Stream<String> first, Stream<String> second) async* {
  yield 'base-stream-yield-star-two-streams-sandwich-catch-finally';
}

Stream<String> asyncGeneratedYieldStarTripleStreamsCatchFinally(Stream<String> first, Stream<String> second, Stream<String> third) async* {
  yield 'base-stream-yield-star-triple-streams-catch-finally';
}

Stream<String> asyncGeneratedAwaitFor(Stream<String> extra) async* {
  yield 'base-stream-await-for';
}

Stream<String> asyncGeneratedAwaitForFinally(Stream<String> extra) async* {
  yield 'base-stream-await-for-finally';
}

Stream<String> asyncGeneratedAwaitForStreamContinue(Stream<String> extra) async* {
  yield 'base-stream-await-for-stream-continue';
}

Stream<String> asyncGeneratedAwaitForStreamBreak(Stream<String> extra) async* {
  yield 'base-stream-await-for-stream-break';
}

Stream<String> asyncGeneratedAwaitForStreamContinueBreakFinally(Stream<String> extra) async* {
  yield 'base-stream-await-for-stream-continue-break-finally';
}

Stream<String> asyncGeneratedAwaitForStreamCatch(Stream<String> extra) async* {
  yield 'base-stream-await-for-stream-catch';
}

Stream<String> asyncGeneratedAwaitForStreamCatchFinally(Stream<String> extra) async* {
  yield 'base-stream-await-for-stream-catch-finally';
}

Stream<String> asyncGeneratedAwaitForTwoStreamsCatchFinally(Stream<String> first, Stream<String> second) async* {
  yield 'base-stream-await-for-two-streams-catch-finally';
}

Stream<String> asyncGeneratedAwaitForNestedStreamCatchFinally(Stream<String> outer, Stream<String> inner) async* {
  yield 'base-stream-await-for-nested-stream-catch-finally';
}

Stream<String> asyncGeneratedAwaitForNestedStreamBreakContinueCatchFinally(Stream<String> outer, Stream<String> inner) async* {
  yield 'base-stream-await-for-nested-stream-break-continue-catch-finally';
}

Stream<String> asyncGeneratedAwaitForTripleNestedStreamCatchFinally(Stream<String> outer, Stream<String> middle, Stream<String> inner) async* {
  yield 'base-stream-await-for-triple-nested-stream-catch-finally';
}

Stream<String> asyncGeneratedAwaitForNestedValueFinally(Stream<String> extra) async* {
  yield 'base-stream-await-for-nested-value-finally';
}

Stream<String> asyncGeneratedAwaitForNestedStreamFinally(Stream<String> outer, Stream<String> inner) async* {
  yield 'base-stream-await-for-nested-stream-finally';
}

Stream<String> asyncGeneratedAwaitForNestedStreamBreakContinueFinally(Stream<String> outer, Stream<String> inner) async* {
  yield 'base-stream-await-for-nested-stream-break-continue-finally';
}

Stream<String> asyncGeneratedAwaitForTripleNestedStreamFinally(Stream<String> outer, Stream<String> middle, Stream<String> inner) async* {
  yield 'base-stream-await-for-triple-nested-stream-finally';
}

Stream<String> asyncGeneratedSwitchOrPatternExpr(String tier) async* {
  yield tier == 'gold'
      ? 'base-stream-switch-or-premium'
      : 'base-stream-switch-or-other';
}

Stream<String> asyncGeneratedSwitchOrPatternStatement(String tier) async* {
  if (tier == 'gold' || tier == 'vip') {
    yield 'base-stream-switch-stmt-or-premium';
  } else {
    yield 'base-stream-switch-stmt-or-other';
  }
}

Stream<String> asyncGeneratedWhileSwitchOrPatternStatement() async* {
  yield 'base-stream-while-switch-or';
}

Stream<String> asyncGeneratedForSwitchOrPatternStatement() async* {
  yield 'base-stream-for-switch-or';
}

Stream<String> asyncGeneratedAwaitForSwitchOrPatternStatement(
  Stream<String> extra,
) async* {
  yield 'base-stream-await-for-switch-or';
}

Stream<String> asyncGeneratedNestedAwaitForSwitchOrPatternStatement(
  Stream<String> outer,
  Stream<String> inner,
) async* {
  yield 'base-stream-nested-await-for-switch-or';
}

Stream<String> asyncGeneratedAwaitForSwitchOrPatternCatchFinally(
  Stream<String> extra,
) async* {
  yield 'base-stream-await-for-switch-or-catch-finally';
}

Stream<String> asyncGeneratedAwaitForSwitchOrPatternBreakContinueFinally(
  Stream<String> extra,
) async* {
  yield 'base-stream-await-for-switch-or-break-continue-finally';
}

Stream<String> asyncGeneratedNestedAwaitForSwitchOrPatternCatchFinally(
  Stream<String> outer,
  Stream<String> inner,
) async* {
  yield 'base-stream-nested-await-for-switch-or-catch-finally';
}

Stream<String> asyncGeneratedNestedAwaitForSwitchOrPatternBreakContinueFinally(
  Stream<String> outer,
  Stream<String> inner,
) async* {
  yield 'base-stream-nested-await-for-switch-or-break-continue-finally';
}
