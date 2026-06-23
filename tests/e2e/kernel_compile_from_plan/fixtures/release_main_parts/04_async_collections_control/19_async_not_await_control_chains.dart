Future<String> asyncNotAwaitIfTryFinallyTail(
  Future<bool> ready,
  Future<String> cleanup,
) async {
  var out = 'base-async-not-await-if-finally';
  if (!await ready) {
    try {
      out = '$out-body';
    } finally {
      final marker = await cleanup;
      out = '$out-cleanup-$marker';
    }
  }
  return '$out-tail';
}

Future<String> asyncNotAwaitIfElseTryCatchFinallyTail(
  Future<bool> ready,
  Future<String> value,
  Future<String> recovery,
  Future<String> cleanup,
) async {
  var out = 'base-async-not-await-ifelse';
  if (!await ready) {
    try {
      final result = await value;
      out = '$out-body-$result';
    } catch (e) {
      final marker = await recovery;
      out = '$out-caught-$marker-$e';
    } finally {
      final marker = await cleanup;
      out = '$out-cleanup-$marker';
    }
  } else {
    out = '$out-ready';
  }
  return '$out-tail';
}

Future<String> asyncNotAwaitWhileTryFinallyLoop(
  Future<bool> keepGoing,
  Future<String> cleanup,
) async {
  var out = 'base-async-not-await-while';
  var index = 0;
  while (!await keepGoing) {
    try {
      out = '$out-body-$index';
    } finally {
      final marker = await cleanup;
      out = '$out-cleanup-$marker';
    }
    if (index == 0) {
      break;
    }
    index = index + 1;
  }
  return out;
}

Future<String> asyncNotAwaitForTryCatchLoop(
  int limit,
  Future<bool> keepGoing,
  Future<String> value,
  Future<String> recovery,
) async {
  var out = 'base-async-not-await-for';
  for (var index = 0; index < limit && !await keepGoing; index = index + 1) {
    try {
      final result = await value;
      out = '$out-body-$index-$result';
    } catch (e) {
      final marker = await recovery;
      out = '$out-caught-$marker-$e';
    }
    if (index == 0) {
      break;
    }
  }
  return out;
}

Future<String> asyncNotAwaitDoWhileFinallyCondition(
  Future<bool> again,
  Future<String> cleanup,
) async {
  var out = 'base-async-not-await-do';
  var index = 0;
  do {
    out = '$out-body-$index';
    final marker = await cleanup;
    out = '$out-cleanup-$marker';
    index = index + 1;
  } while (!await again);
  return out;
}
