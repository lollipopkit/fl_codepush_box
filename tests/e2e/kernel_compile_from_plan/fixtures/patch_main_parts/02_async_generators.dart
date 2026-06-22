Stream<String> asyncGenerated() async* {
  yield 'patched-stream';
}

Stream<String> asyncGeneratedAwait(Future<String> ready) async* {
  final value = await ready;
  yield 'patched-stream-await-$value';
}

Stream<String> asyncGeneratedTryFinally(Future<String> ready) async* {
  try {
    yield await ready;
  } finally {
    final cleanup = 'patched-stream-finally-cleanup';
  }
}

Stream<String> asyncGeneratedFinallyYield(Future<String> ready) async* {
  try {
    yield await ready;
  } finally {
    yield 'patched-stream-finally-yield-cleanup';
  }
}

Stream<String> asyncGeneratedCatchAwait(Future<String> ready) async* {
  try {
    yield await ready;
  } catch (e) {
    yield 'patched-stream-caught-$e';
  }
}

Stream<String> asyncGeneratedMany(bool enabled) async* {
  final prefix = 'patched-stream';
  yield '$prefix-a';
  if (enabled) yield '$prefix-live';
  yield '$prefix-tail';
}

Stream<String> asyncGeneratedWhile() async* {
  var i = 0;
  while (2 > i) {
    yield 'patched-stream-while-$i';
    i = i + 1;
  }
}

Stream<String> asyncGeneratedWhileBreak() async* {
  var i = 0;
  while (4 > i) {
    yield 'patched-stream-while-break-before-$i';
    if (i == 2) break;
    yield 'patched-stream-while-break-after-$i';
    i = i + 1;
  }
}

Stream<String> asyncGeneratedWhileContinue() async* {
  var i = 0;
  while (3 > i) {
    yield 'patched-stream-while-continue-before-$i';
    if (i == 1) {
      i = i + 1;
      continue;
    }
    yield 'patched-stream-while-continue-after-$i';
    i = i + 1;
  }
}

Stream<String> asyncGeneratedWhileContinueBreak() async* {
  var i = 0;
  while (4 > i) {
    yield 'patched-stream-while-continue-before-$i';
    if (i == 1) {
      i = i + 1;
      continue;
    }
    yield 'patched-stream-while-continue-mid-$i';
    if (i == 2) break;
    yield 'patched-stream-while-continue-after-$i';
    i = i + 1;
  }
}

Stream<String> asyncGeneratedDoWhile() async* {
  var i = 0;
  do {
    yield 'patched-stream-do-$i';
    i = i + 1;
  } while (2 > i);
}

Stream<String> asyncGeneratedDoWhileBreak() async* {
  var i = 0;
  do {
    yield 'patched-stream-do-break-before-$i';
    if (i == 1) break;
    yield 'patched-stream-do-break-after-$i';
    i = i + 1;
  } while (3 > i);
}

Stream<String> asyncGeneratedDoWhileContinue() async* {
  var i = 0;
  do {
    yield 'patched-stream-do-continue-before-$i';
    if (i == 1) {
      i = i + 1;
      continue;
    }
    yield 'patched-stream-do-continue-after-$i';
    i = i + 1;
  } while (3 > i);
}

Stream<String> asyncGeneratedDoWhileContinueBreak() async* {
  var i = 0;
  do {
    yield 'patched-stream-do-continue-before-$i';
    if (i == 1) {
      i = i + 1;
      continue;
    }
    yield 'patched-stream-do-continue-mid-$i';
    if (i == 2) break;
    yield 'patched-stream-do-continue-after-$i';
    i = i + 1;
  } while (4 > i);
}

Stream<String> asyncGeneratedForLoop() async* {
  for (var i = 0; 2 > i; i = i + 1) {
    yield 'patched-stream-for-$i';
  }
}

Stream<String> asyncGeneratedForLoopPostIncrement() async* {
  for (var i = 0; 2 > i; i++) {
    yield 'patched-stream-for-postinc-$i';
  }
}

Stream<String> asyncGeneratedForLoopMultiUpdate() async* {
  for (var i = 0, j = 10; 2 > i; i = i + 1, j = j + 1) {
    yield 'patched-stream-for-multi-$i-$j';
  }
}

Stream<String> asyncGeneratedForLoopExternalLocal() async* {
  var i = 0;
  for (; 2 > i; i = i + 1) {
    yield 'patched-stream-for-external-$i';
  }
}

Stream<String> asyncGeneratedForLoopBodyUpdate() async* {
  var i = 0;
  for (; 2 > i;) {
    yield 'patched-stream-for-body-update-$i';
    i = i + 1;
  }
}

Stream<String> asyncGeneratedForLoopContinue() async* {
  for (var i = 0; 3 > i; i = i + 1) {
    yield 'patched-stream-for-continue-before-$i';
    if (i == 1) continue;
    yield 'patched-stream-for-continue-after-$i';
  }
}

Stream<String> asyncGeneratedForLoopContinueBreak() async* {
  for (var i = 0; 4 > i; i = i + 1) {
    yield 'patched-stream-for-continue-before-$i';
    if (i == 1) continue;
    yield 'patched-stream-for-continue-mid-$i';
    if (i == 2) break;
    yield 'patched-stream-for-continue-after-$i';
  }
}

Stream<String> asyncGeneratedForLoopBreak() async* {
  for (var i = 0; 3 > i; i = i + 1) {
    yield 'patched-stream-for-break-before-$i';
    if (i == 1) break;
    yield 'patched-stream-for-break-after-$i';
  }
}

Stream<String> asyncGeneratedForIn() async* {
  for (final value in ['patched-stream-a', 'patched-stream-b']) {
    yield value;
  }
}

Stream<String> asyncGeneratedForInBreak() async* {
  final prefix = 'patched-stream-static-break';
  for (final value in ['a', 'stop', 'tail']) {
    yield '$prefix-before-$value';
    if (value == 'stop') break;
    yield '$prefix-after-$value';
  }
}

Stream<String> asyncGeneratedForInBreakFirst() async* {
  final prefix = 'patched-stream-static-break-first';
  for (final value in ['a', 'stop', 'tail']) {
    if (value == 'stop') break;
    yield '$prefix-$value';
  }
}

Stream<String> asyncGeneratedForInContinue() async* {
  final prefix = 'patched-stream-static-continue';
  for (final value in ['a', 'skip', 'tail']) {
    if (value == 'skip') continue;
    yield '$prefix-$value';
  }
}

Stream<String> asyncGeneratedForInContinueAfterYield() async* {
  final prefix = 'patched-stream-static-continue-after-yield';
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
  yield 'patched-stream-dynamic-tail';
}

Stream<String> asyncGeneratedDynamicForInMapped(List<String> extra) async* {
  final prefix = 'patched-stream-map';
  for (final value in extra) {
    yield '$prefix-$value';
  }
}

Stream<String> asyncGeneratedDynamicForInMany(List<String> extra) async* {
  final prefix = 'patched-stream-many';
  for (final value in extra) {
    yield '$prefix-a-$value';
    yield '$prefix-b-$value';
  }
}

Stream<String> asyncGeneratedDynamicForInIf(List<String> extra) async* {
  final prefix = 'patched-stream-if';
  for (final value in extra) {
    if (value == 'live') yield '$prefix-hit-$value';
    yield '$prefix-tail-$value';
  }
}

Stream<String> asyncGeneratedDynamicForInIfElse(List<String> extra) async* {
  final prefix = 'patched-stream-ifelse';
  for (final value in extra) {
    if (value == 'live') {
      yield '$prefix-hit-$value';
    } else {
      yield '$prefix-miss-$value';
    }
  }
}

Stream<String> asyncGeneratedDynamicForInLocal(List<String> extra) async* {
  final prefix = 'patched-stream-local';
  for (final value in extra) {
    final marker = '$prefix-$value';
    yield marker;
  }
}

Stream<String> asyncGeneratedDynamicForInContinue(List<String> extra) async* {
  final prefix = 'patched-stream-continue';
  for (final value in extra) {
    if (value == 'skip') continue;
    yield '$prefix-$value';
  }
}

Stream<String> asyncGeneratedDynamicForInContinueAfterYield(List<String> extra) async* {
  final prefix = 'patched-stream-continue-after-yield';
  for (final value in extra) {
    yield '$prefix-before-$value';
    if (value == 'skip') continue;
    yield '$prefix-after-$value';
  }
}

Stream<String> asyncGeneratedDynamicForInBreak(List<String> extra) async* {
  final prefix = 'patched-stream-break';
  for (final value in extra) {
    if (value == 'stop') break;
    yield '$prefix-$value';
  }
}

Stream<String> asyncGeneratedDynamicForInBreakAfterYield(List<String> extra) async* {
  final prefix = 'patched-stream-break-after-yield';
  for (final value in extra) {
    yield '$prefix-before-$value';
    if (value == 'stop') break;
    yield '$prefix-after-$value';
  }
}

Stream<String> asyncGeneratedDynamicForInBreakAtEnd(List<String> extra) async* {
  final prefix = 'patched-stream-break-at-end';
  for (final value in extra) {
    yield '$prefix-before-$value';
    if (value == 'stop') break;
  }
}

Stream<String> asyncGeneratedDynamicForInContinueThenBreak(List<String> extra) async* {
  final prefix = 'patched-stream-continue-break';
  for (final value in extra) {
    if (value == 'skip') continue;
    if (value == 'stop') break;
    yield '$prefix-$value';
  }
}

Stream<String> asyncGeneratedDynamicForInContinueYieldBreak(List<String> extra) async* {
  final prefix = 'patched-stream-continue-yield-break';
  for (final value in extra) {
    if (value == 'skip') continue;
    yield '$prefix-before-$value';
    if (value == 'stop') break;
    yield '$prefix-after-$value';
  }
}

Stream<String> asyncGeneratedDynamicForInNested(List<String> extra, List<String> suffixes) async* {
  final prefix = 'patched-stream-nested';
  for (final value in extra) {
    for (final suffix in suffixes) {
      yield '$prefix-$value-$suffix';
    }
  }
}

Stream<String> asyncGeneratedDynamicForInNestedBreakContinue(List<String> extra, List<String> suffixes) async* {
  final prefix = 'patched-stream-nested-control';
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
  yield* Stream.fromIterable(['patched-stream-yield-star-a', 'patched-stream-yield-star-b']);
}

Stream<String> asyncGeneratedYieldStarDynamic(List<String> extra) async* {
  yield* Stream.fromIterable(extra);
  yield 'patched-stream-yield-star-dynamic-tail';
}

Stream<String> asyncGeneratedYieldStarValue(String value) async* {
  yield* Stream.value('patched-stream-yield-star-value-$value');
}

Stream<String> asyncGeneratedYieldStarFromFuture(String value) async* {
  yield* Stream.fromFuture(Future.value('patched-stream-yield-star-future-$value'));
}

Stream<String> asyncGeneratedYieldStarPendingFuture(Future<String> ready) async* {
  yield* Stream.fromFuture(ready);
}

Stream<String> asyncGeneratedYieldStarEmpty() async* {
  yield* Stream<String>.empty();
}

Stream<String> asyncGeneratedAwaitForFromIterable(List<String> extra) async* {
  await for (final value in Stream.fromIterable(extra)) {
    yield 'patched-stream-await-for-iterable-$value';
  }
}

Stream<String> asyncGeneratedAwaitForContinue(List<String> extra) async* {
  await for (final value in Stream.fromIterable(extra)) {
    if (value == 'skip') continue;
    yield 'patched-stream-await-for-continue-$value';
  }
}

Stream<String> asyncGeneratedAwaitForBreak(List<String> extra) async* {
  await for (final value in Stream.fromIterable(extra)) {
    if (value == 'stop') break;
    yield 'patched-stream-await-for-break-$value';
  }
}

Stream<String> asyncGeneratedAwaitForValue(String value) async* {
  await for (final item in Stream.value(value)) {
    yield 'patched-stream-await-for-value-$item';
  }
}

Stream<String> asyncGeneratedAwaitForFuture(String value) async* {
  await for (final item in Stream.fromFuture(Future.value(value))) {
    yield 'patched-stream-await-for-future-$item';
  }
}

Stream<String> asyncGeneratedAwaitForFutureBreak(String value) async* {
  await for (final item in Stream.fromFuture(Future.value(value))) {
    if (item == 'stop') break;
    yield 'patched-stream-await-for-future-break-$item';
  }
}

Stream<String> asyncGeneratedAwaitForPendingFuture(Future<String> ready) async* {
  await for (final item in Stream.fromFuture(ready)) {
    yield 'patched-stream-await-for-pending-future-$item';
  }
}

Stream<String> asyncGeneratedAwaitForPendingContinue(Future<String> ready) async* {
  await for (final item in Stream.fromFuture(ready)) {
    if (item == 'skip') continue;
    yield 'patched-stream-await-for-pending-continue-$item';
  }
}

Stream<String> asyncGeneratedAwaitForFromIterableCatchFinally(List<String> extra) async* {
  try {
    try {
      await for (final value in Stream.fromIterable(extra)) {
        yield 'patched-stream-await-for-iterable-catch-$value';
      }
    } catch (e) {
      yield 'patched-stream-await-for-iterable-caught-$e';
    }
  } finally {
    yield 'patched-stream-await-for-iterable-catch-cleanup';
  }
}

Stream<String> asyncGeneratedAwaitForFutureCatchFinally(String value) async* {
  try {
    try {
      await for (final item in Stream.fromFuture(Future.value('patched-stream-await-for-future-catch-$value'))) {
        yield 'patched-stream-await-for-future-catch-item-$item';
      }
    } catch (e) {
      yield 'patched-stream-await-for-future-caught-$e';
    }
  } finally {
    yield 'patched-stream-await-for-future-catch-cleanup';
  }
}

Stream<String> asyncGeneratedAwaitForPendingFutureCatchFinally(Future<String> ready) async* {
  try {
    try {
      await for (final item in Stream.fromFuture(ready)) {
        yield 'patched-stream-await-for-pending-catch-$item';
      }
    } catch (e) {
      yield 'patched-stream-await-for-pending-caught-$e';
    }
  } finally {
    yield 'patched-stream-await-for-pending-catch-cleanup';
  }
}

Stream<String> asyncGeneratedAwaitForValueCatchFinally(String value) async* {
  try {
    try {
      await for (final item in Stream.value(value)) {
        yield 'patched-stream-await-for-value-catch-$item';
      }
    } catch (e) {
      yield 'patched-stream-await-for-value-caught-$e';
    }
  } finally {
    yield 'patched-stream-await-for-value-catch-cleanup';
  }
}

Stream<String> asyncGeneratedAwaitForEmptyCatchFinally() async* {
  try {
    try {
      await for (final item in Stream<String>.empty()) {
        yield 'patched-stream-await-for-empty-catch-$item';
      }
    } catch (e) {
      yield 'patched-stream-await-for-empty-caught-$e';
    }
  } finally {
    yield 'patched-stream-await-for-empty-catch-cleanup';
  }
}

Stream<String> asyncGeneratedAwaitForFutureBreakCatchFinally(String value) async* {
  try {
    try {
      await for (final item in Stream.fromFuture(Future.value(value))) {
        if (item == 'stop') break;
        yield 'patched-stream-await-for-future-break-catch-$item';
      }
    } catch (e) {
      yield 'patched-stream-await-for-future-break-caught-$e';
    }
  } finally {
    yield 'patched-stream-await-for-future-break-catch-cleanup';
  }
}

Stream<String> asyncGeneratedAwaitForPendingContinueCatchFinally(Future<String> ready) async* {
  try {
    try {
      await for (final item in Stream.fromFuture(ready)) {
        if (item == 'skip') continue;
        yield 'patched-stream-await-for-pending-continue-catch-$item';
      }
    } catch (e) {
      yield 'patched-stream-await-for-pending-continue-caught-$e';
    }
  } finally {
    yield 'patched-stream-await-for-pending-continue-catch-cleanup';
  }
}

Stream<String> asyncGeneratedAwaitForEmpty() async* {
  await for (final item in Stream<String>.empty()) {
    yield 'patched-stream-await-for-empty-$item';
  }
}

Stream<String> asyncGeneratedYieldStarStream(Stream<String> extra) async* {
  yield* extra;
}

Stream<String> asyncGeneratedYieldStarStreamFinally(Stream<String> extra) async* {
  try {
    yield* extra;
  } finally {
    yield 'patched-stream-yield-star-stream-finally-cleanup';
  }
}

Stream<String> asyncGeneratedYieldStarStreamSandwichFinally(Stream<String> extra) async* {
  try {
    yield 'patched-stream-yield-star-stream-before';
    yield* extra;
    yield 'patched-stream-yield-star-stream-after';
  } finally {
    yield 'patched-stream-yield-star-stream-sandwich-cleanup';
  }
}

Stream<String> asyncGeneratedYieldStarTwoStreamsFinally(Stream<String> first, Stream<String> second) async* {
  try {
    yield* first;
    yield* second;
  } finally {
    yield 'patched-stream-yield-star-two-streams-cleanup';
  }
}

Stream<String> asyncGeneratedYieldStarStreamCatch(Stream<String> extra) async* {
  try {
    yield* extra;
  } catch (e) {
    yield 'patched-stream-yield-star-stream-caught-$e';
  }
}

Stream<String> asyncGeneratedYieldStarStreamCatchFinally(Stream<String> extra) async* {
  try {
    try {
      yield* extra;
    } catch (e) {
      yield 'patched-stream-yield-star-stream-catch-finally-caught-$e';
    }
  } finally {
    yield 'patched-stream-yield-star-stream-catch-finally-cleanup';
  }
}

Stream<String> asyncGeneratedYieldStarTwoStreamsCatchFinally(Stream<String> first, Stream<String> second) async* {
  try {
    try {
      yield* first;
      yield* second;
    } catch (e) {
      yield 'patched-stream-yield-star-two-streams-caught-$e';
    }
  } finally {
    yield 'patched-stream-yield-star-two-streams-catch-finally-cleanup';
  }
}

Stream<String> asyncGeneratedYieldStarDynamicCatchFinally(List<String> extra) async* {
  try {
    try {
      yield* Stream.fromIterable(extra);
    } catch (e) {
      yield 'patched-stream-yield-star-dynamic-caught-$e';
    }
  } finally {
    yield 'patched-stream-yield-star-dynamic-catch-cleanup';
  }
}

Stream<String> asyncGeneratedYieldStarFromFutureCatchFinally(String value) async* {
  try {
    try {
      yield* Stream.fromFuture(Future.value('patched-stream-yield-star-future-catch-$value'));
    } catch (e) {
      yield 'patched-stream-yield-star-future-caught-$e';
    }
  } finally {
    yield 'patched-stream-yield-star-future-catch-cleanup';
  }
}

Stream<String> asyncGeneratedYieldStarPendingFutureCatchFinally(Future<String> ready) async* {
  try {
    try {
      yield* Stream.fromFuture(ready);
    } catch (e) {
      yield 'patched-stream-yield-star-pending-caught-$e';
    }
  } finally {
    yield 'patched-stream-yield-star-pending-catch-cleanup';
  }
}

Stream<String> asyncGeneratedYieldStarValueCatchFinally(String value) async* {
  try {
    try {
      yield* Stream.value('patched-stream-yield-star-value-catch-$value');
    } catch (e) {
      yield 'patched-stream-yield-star-value-caught-$e';
    }
  } finally {
    yield 'patched-stream-yield-star-value-catch-cleanup';
  }
}

Stream<String> asyncGeneratedYieldStarEmptyCatchFinally() async* {
  try {
    try {
      yield* Stream<String>.empty();
    } catch (e) {
      yield 'patched-stream-yield-star-empty-caught-$e';
    }
  } finally {
    yield 'patched-stream-yield-star-empty-catch-cleanup';
  }
}

Stream<String> asyncGeneratedYieldStarStreamSandwichCatchFinally(Stream<String> extra) async* {
  try {
    try {
      yield 'patched-stream-yield-star-stream-sandwich-catch-before';
      yield* extra;
      yield 'patched-stream-yield-star-stream-sandwich-catch-after';
    } catch (e) {
      yield 'patched-stream-yield-star-stream-sandwich-caught-$e';
    }
  } finally {
    yield 'patched-stream-yield-star-stream-sandwich-catch-cleanup';
  }
}

Stream<String> asyncGeneratedYieldStarTwoStreamsSandwichCatchFinally(Stream<String> first, Stream<String> second) async* {
  try {
    try {
      yield 'patched-stream-yield-star-two-streams-sandwich-before';
      yield* first;
      yield 'patched-stream-yield-star-two-streams-sandwich-middle';
      yield* second;
      yield 'patched-stream-yield-star-two-streams-sandwich-after';
    } catch (e) {
      yield 'patched-stream-yield-star-two-streams-sandwich-caught-$e';
    }
  } finally {
    yield 'patched-stream-yield-star-two-streams-sandwich-cleanup';
  }
}

Stream<String> asyncGeneratedYieldStarTripleStreamsCatchFinally(Stream<String> first, Stream<String> second, Stream<String> third) async* {
  try {
    try {
      yield* first;
      yield* second;
      yield* third;
    } catch (e) {
      yield 'patched-stream-yield-star-triple-streams-caught-$e';
    }
  } finally {
    yield 'patched-stream-yield-star-triple-streams-cleanup';
  }
}

Stream<String> asyncGeneratedAwaitFor(Stream<String> extra) async* {
  await for (final value in extra) {
    yield value;
  }
}

Stream<String> asyncGeneratedAwaitForFinally(Stream<String> extra) async* {
  try {
    await for (final value in extra) {
      yield value;
    }
  } finally {
    yield 'patched-stream-await-for-finally-cleanup';
  }
}

Stream<String> asyncGeneratedAwaitForStreamContinue(Stream<String> extra) async* {
  await for (final value in extra) {
    if (value == 'skip') continue;
    yield 'patched-stream-await-for-stream-continue-$value';
  }
}

Stream<String> asyncGeneratedAwaitForStreamBreak(Stream<String> extra) async* {
  await for (final value in extra) {
    if (value == 'stop') break;
    yield 'patched-stream-await-for-stream-break-$value';
  }
}

Stream<String> asyncGeneratedAwaitForStreamContinueBreakFinally(Stream<String> extra) async* {
  try {
    await for (final value in extra) {
      if (value == 'skip') continue;
      if (value == 'stop') break;
      yield 'patched-stream-await-for-stream-continue-break-$value';
    }
  } finally {
    yield 'patched-stream-await-for-stream-continue-break-cleanup';
  }
}

Stream<String> asyncGeneratedAwaitForStreamCatch(Stream<String> extra) async* {
  try {
    await for (final value in extra) {
      yield 'patched-stream-await-for-stream-caught-body-$value';
    }
  } catch (e) {
    yield 'patched-stream-await-for-stream-caught-$e';
  }
}

Stream<String> asyncGeneratedAwaitForStreamCatchFinally(Stream<String> extra) async* {
  try {
    try {
      await for (final value in extra) {
        yield 'patched-stream-await-for-stream-catch-finally-body-$value';
      }
    } catch (e) {
      yield 'patched-stream-await-for-stream-catch-finally-caught-$e';
    }
  } finally {
    yield 'patched-stream-await-for-stream-catch-finally-cleanup';
  }
}

Stream<String> asyncGeneratedAwaitForTwoStreamsCatchFinally(Stream<String> first, Stream<String> second) async* {
  try {
    try {
      await for (final left in first) {
        yield 'patched-stream-await-for-two-streams-left-$left';
      }
      await for (final right in second) {
        yield 'patched-stream-await-for-two-streams-right-$right';
      }
    } catch (e) {
      yield 'patched-stream-await-for-two-streams-caught-$e';
    }
  } finally {
    yield 'patched-stream-await-for-two-streams-catch-finally-cleanup';
  }
}

Stream<String> asyncGeneratedAwaitForNestedStreamCatchFinally(Stream<String> outer, Stream<String> inner) async* {
  try {
    try {
      await for (final left in outer) {
        await for (final right in inner) {
          yield 'patched-stream-await-for-nested-stream-catch-$left-$right';
        }
      }
    } catch (e) {
      yield 'patched-stream-await-for-nested-stream-caught-$e';
    }
  } finally {
    yield 'patched-stream-await-for-nested-stream-catch-cleanup';
  }
}

Stream<String> asyncGeneratedAwaitForNestedStreamBreakContinueCatchFinally(Stream<String> outer, Stream<String> inner) async* {
  try {
    try {
      await for (final left in outer) {
        if (left == 'skip') continue;
        await for (final right in inner) {
          if (right == 'stop') break;
          yield 'patched-stream-await-for-nested-stream-break-continue-catch-$left-$right';
        }
      }
    } catch (e) {
      yield 'patched-stream-await-for-nested-stream-break-continue-caught-$e';
    }
  } finally {
    yield 'patched-stream-await-for-nested-stream-break-continue-catch-cleanup';
  }
}

Stream<String> asyncGeneratedAwaitForTripleNestedStreamCatchFinally(Stream<String> outer, Stream<String> middle, Stream<String> inner) async* {
  try {
    try {
      await for (final left in outer) {
        if (left == 'skip') continue;
        await for (final center in middle) {
          if (center == 'stop-middle') break;
          await for (final right in inner) {
            yield 'patched-stream-await-for-triple-nested-catch-$left-$center-$right';
          }
        }
      }
    } catch (e) {
      yield 'patched-stream-await-for-triple-nested-caught-$e';
    }
  } finally {
    yield 'patched-stream-await-for-triple-nested-catch-cleanup';
  }
}

Stream<String> asyncGeneratedAwaitForNestedValueFinally(Stream<String> extra) async* {
  try {
    await for (final outer in extra) {
      await for (final inner in Stream.value('$outer-inner')) {
        yield 'patched-stream-await-for-nested-$inner';
      }
    }
  } finally {
    yield 'patched-stream-await-for-nested-cleanup';
  }
}

Stream<String> asyncGeneratedAwaitForNestedStreamFinally(Stream<String> outer, Stream<String> inner) async* {
  try {
    await for (final left in outer) {
      await for (final right in inner) {
        yield 'patched-stream-await-for-nested-stream-$left-$right';
      }
    }
  } finally {
    yield 'patched-stream-await-for-nested-stream-cleanup';
  }
}

Stream<String> asyncGeneratedAwaitForNestedStreamBreakContinueFinally(Stream<String> outer, Stream<String> inner) async* {
  try {
    await for (final left in outer) {
      if (left == 'skip') continue;
      await for (final right in inner) {
        if (right == 'stop') break;
        yield 'patched-stream-await-for-nested-stream-break-continue-$left-$right';
      }
    }
  } finally {
    yield 'patched-stream-await-for-nested-stream-break-continue-cleanup';
  }
}

Stream<String> asyncGeneratedAwaitForTripleNestedStreamFinally(Stream<String> outer, Stream<String> middle, Stream<String> inner) async* {
  try {
    await for (final left in outer) {
      if (left == 'skip') continue;
      await for (final center in middle) {
        if (center == 'stop-middle') break;
        await for (final right in inner) {
          yield 'patched-stream-await-for-triple-nested-$left-$center-$right';
        }
      }
    }
  } finally {
    yield 'patched-stream-await-for-triple-nested-cleanup';
  }
}

Stream<String> asyncGeneratedSwitchOrPatternExpr(String tier) async* {
  yield switch (tier) {
    'gold' || 'vip' => 'patched-stream-switch-or-premium',
    'trial' || 'guest' => 'patched-stream-switch-or-limited',
    _ => 'patched-stream-switch-or-other',
  };
}

Stream<String> asyncGeneratedSwitchOrPatternStatement(String tier) async* {
  switch (tier) {
    case 'gold' || 'vip':
      yield 'patched-stream-switch-stmt-or-premium';
    case 'trial' || 'guest':
      yield 'patched-stream-switch-stmt-or-limited';
    default:
      yield 'patched-stream-switch-stmt-or-other';
  }
}

Stream<String> asyncGeneratedWhileSwitchOrPatternStatement() async* {
  var i = 0;
  while (3 > i) {
    switch (i) {
      case 0 || 1:
        yield 'patched-stream-while-switch-or-premium-$i';
      default:
        yield 'patched-stream-while-switch-or-other-$i';
    }
    i = i + 1;
  }
}

Stream<String> asyncGeneratedForSwitchOrPatternStatement() async* {
  for (var i = 0; 3 > i; i = i + 1) {
    switch (i) {
      case 0 || 1:
        yield 'patched-stream-for-switch-or-premium-$i';
      default:
        yield 'patched-stream-for-switch-or-other-$i';
    }
  }
}

Stream<String> asyncGeneratedAwaitForSwitchOrPatternStatement(
  Stream<String> extra,
) async* {
  await for (final tier in extra) {
    switch (tier) {
      case 'gold' || 'vip':
        yield 'patched-stream-await-for-switch-or-premium-$tier';
      default:
        yield 'patched-stream-await-for-switch-or-other-$tier';
    }
  }
}

Stream<String> asyncGeneratedNestedAwaitForSwitchOrPatternStatement(
  Stream<String> outer,
  Stream<String> inner,
) async* {
  await for (final left in outer) {
    await for (final tier in inner) {
      switch (tier) {
        case 'gold' || 'vip':
          yield 'patched-stream-nested-await-for-switch-or-premium-$left-$tier';
        default:
          yield 'patched-stream-nested-await-for-switch-or-other-$left-$tier';
      }
    }
  }
}

Stream<String> asyncGeneratedAwaitForSwitchOrPatternCatchFinally(
  Stream<String> extra,
) async* {
  try {
    await for (final tier in extra) {
      switch (tier) {
        case 'gold' || 'vip':
          yield 'patched-stream-await-for-switch-or-catch-premium-$tier';
        default:
          yield 'patched-stream-await-for-switch-or-catch-other-$tier';
      }
    }
  } catch (e) {
    yield 'patched-stream-await-for-switch-or-caught-$e';
  } finally {
    yield 'patched-stream-await-for-switch-or-cleanup';
  }
}

Stream<String> asyncGeneratedAwaitForSwitchOrPatternBreakContinueFinally(
  Stream<String> extra,
) async* {
  try {
    await for (final tier in extra) {
      if (tier == 'skip') continue;
      switch (tier) {
        case 'gold' || 'vip':
          yield 'patched-stream-await-for-switch-or-break-continue-premium-$tier';
        default:
          yield 'patched-stream-await-for-switch-or-break-continue-other-$tier';
      }
      if (tier == 'stop') break;
    }
  } finally {
    yield 'patched-stream-await-for-switch-or-break-continue-cleanup';
  }
}

Stream<String> asyncGeneratedNestedAwaitForSwitchOrPatternCatchFinally(
  Stream<String> outer,
  Stream<String> inner,
) async* {
  try {
    await for (final left in outer) {
      await for (final tier in inner) {
        switch (tier) {
          case 'gold' || 'vip':
            yield 'patched-stream-nested-await-for-switch-or-catch-premium-$left-$tier';
          default:
            yield 'patched-stream-nested-await-for-switch-or-catch-other-$left-$tier';
        }
      }
    }
  } catch (e) {
    yield 'patched-stream-nested-await-for-switch-or-caught-$e';
  } finally {
    yield 'patched-stream-nested-await-for-switch-or-cleanup';
  }
}

Stream<String> asyncGeneratedNestedAwaitForSwitchOrPatternBreakContinueFinally(
  Stream<String> outer,
  Stream<String> inner,
) async* {
  try {
    await for (final left in outer) {
      if (left == 'skip') continue;
      await for (final tier in inner) {
        switch (tier) {
          case 'gold' || 'vip':
            yield 'patched-stream-nested-await-for-switch-or-break-continue-premium-$left-$tier';
          default:
            yield 'patched-stream-nested-await-for-switch-or-break-continue-other-$left-$tier';
        }
        if (tier == 'stop') break;
      }
    }
  } finally {
    yield 'patched-stream-nested-await-for-switch-or-break-continue-cleanup';
  }
}
