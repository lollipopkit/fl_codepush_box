part of fcb_kernel_reader;

List<Map<String, Object?>>? _finiteStreamStaticListItems(
  Expression expression,
  Set<String> params,
  String libraryUri,
  Map<VariableDeclaration, int> locals,
) {
  if (_isEmptyStreamConstructor(expression)) {
    return [];
  }
  if (expression is! StaticInvocation ||
      expression.arguments.named.isNotEmpty) {
    return null;
  }
  if (_isStreamStaticInvocation(expression, 'value') &&
      expression.arguments.positional.length == 1) {
    final compiled = _expr(
      expression.arguments.positional.single,
      params,
      libraryUri,
      locals,
    );
    if (compiled == null) return null;
    return [compiled];
  }
  if (_isStreamStaticInvocation(expression, 'fromFuture') &&
      expression.arguments.positional.length == 1) {
    final item = _futureStreamValueArg(
      expression.arguments.positional.single,
      params,
      libraryUri,
      locals,
    );
    if (item == null) return null;
    return [item];
  }
  if (!_isStreamStaticInvocation(expression, 'fromIterable') ||
      expression.arguments.positional.length != 1) {
    return null;
  }
  final compiled = _expr(
    expression.arguments.positional.single,
    params,
    libraryUri,
    locals,
  );
  final listItems = compiled?['list'];
  if (listItems is! List) return null;
  return listItems.cast<Map<String, Object?>>();
}

Map<String, Object?>? _finiteStreamDynamicSource(
  Expression expression,
  Set<String> params,
  String libraryUri,
  Map<VariableDeclaration, int> locals,
) {
  if (expression is! StaticInvocation ||
      expression.arguments.positional.length != 1 ||
      expression.arguments.named.isNotEmpty) {
    return null;
  }
  if (!_isStreamStaticInvocation(expression, 'fromIterable')) return null;
  final source = _expr(
    expression.arguments.positional.single,
    params,
    libraryUri,
    locals,
  );
  if (source == null || source['list'] is List || source['map'] is List) {
    return null;
  }
  return source;
}

Map<String, Object?>? _finiteStreamSource(
  Expression expression,
  Set<String> params,
  String libraryUri,
  Map<VariableDeclaration, int> locals,
) {
  if (_isEmptyStreamConstructor(expression)) {
    return {'list': <Map<String, Object?>>[]};
  }
  if (expression is! StaticInvocation ||
      expression.arguments.named.isNotEmpty) {
    return null;
  }
  if (_isStreamStaticInvocation(expression, 'value') &&
      expression.arguments.positional.length == 1) {
    final item = _expr(
      expression.arguments.positional.single,
      params,
      libraryUri,
      locals,
    );
    if (item == null) return null;
    return {
      'list': [item],
    };
  }
  if (_isStreamStaticInvocation(expression, 'fromFuture') &&
      expression.arguments.positional.length == 1) {
    final item = _futureStreamValueArg(
      expression.arguments.positional.single,
      params,
      libraryUri,
      locals,
    );
    if (item == null) return null;
    return {
      'list': [item],
    };
  }
  if (!_isStreamStaticInvocation(expression, 'fromIterable') ||
      expression.arguments.positional.length != 1) {
    return null;
  }
  final source = _expr(
    expression.arguments.positional.single,
    params,
    libraryUri,
    locals,
  );
  if (source == null || source['map'] is List) return null;
  return source;
}

bool _isEmptyStreamConstructor(Expression expression) {
  if (expression is! ConstructorInvocation) return false;
  if (expression.arguments.positional.isNotEmpty ||
      expression.arguments.named.isNotEmpty) {
    return false;
  }
  try {
    if (expression.target.enclosingClass?.name == '_EmptyStream') {
      return true;
    }
  } catch (_) {
    // Some fallback Kernel references are intentionally not bound to AST nodes.
  }
  return _nodeText(expression).contains('_EmptyStream');
}

bool _isStreamStaticInvocation(StaticInvocation invocation, String method) {
  try {
    final target = invocation.target;
    if (target.name.text == method &&
        target.enclosingClass?.name == 'Stream' &&
        target.enclosingLibrary.importUri.toString() == 'dart:async') {
      return true;
    }
  } catch (_) {
    // Some fallback Kernel references are intentionally not bound to AST nodes.
  }
  return _nodeText(invocation).contains('Stream::$method');
}

Map<String, Object?>? _futureStreamValueArg(
  Expression expression,
  Set<String> params,
  String libraryUri,
  Map<VariableDeclaration, int> locals,
) {
  return _awaitedFutureExpr(expression, params, libraryUri, locals);
}

Map<String, Object?>? _generatorAsyncForInFromIterableExpr(
  ForInStatement statement,
  Set<String> params,
  String libraryUri,
  String asyncKind,
  Map<VariableDeclaration, int> locals,
) {
  if (asyncKind != 'async_star') return null;
  final source = _finiteStreamSource(
    statement.iterable,
    params,
    libraryUri,
    locals,
  );
  if (source == null) return null;
  final loopLocalId = locals.length;
  final bodyExpr = _generatorBodyExpr(
    statement.body,
    params,
    libraryUri,
    asyncKind,
    {...locals, statement.variable: loopLocalId},
  );
  if (bodyExpr == null) return null;
  return {
    'yield_for_in': _yieldForInSpec(
      source: source,
      loopVariable: statement.variable,
      loopLocalId: loopLocalId,
      bodyExpr: bodyExpr,
    ),
  };
}

Map<String, Object?>? _generatorLoweredAsyncForInFromIterableExpr(
  Block block,
  Set<String> params,
  String libraryUri,
  String asyncKind,
  Map<VariableDeclaration, int> locals, {
  LabeledStatement? breakLabel,
}) {
  if (asyncKind != 'async_star' || block.statements.length != 3) return null;
  final stream = block.statements[0];
  final iterator = block.statements[1];
  final tryFinally = block.statements[2];
  if (stream is! VariableStatement ||
      iterator is! VariableStatement ||
      tryFinally is! TryFinally ||
      stream.initializer == null ||
      iterator.initializer == null) {
    return null;
  }
  final source = _finiteStreamSource(
    stream.initializer!,
    params,
    libraryUri,
    locals,
  );
  if (source == null ||
      !_isStreamIteratorConstructor(iterator.initializer!, stream) ||
      !_isStreamIteratorCancelFinally(tryFinally.finalizer, iterator)) {
    return null;
  }
  final rawLoop = tryFinally.body;
  final loopLabel = rawLoop is LabeledStatement ? rawLoop : null;
  final effectiveBreakLabel = breakLabel ?? loopLabel;
  final loop = loopLabel?.body ?? rawLoop;
  if (loop is! WhileStatement ||
      !_isAsyncStreamIteratorMoveNext(loop.condition, iterator)) {
    return null;
  }
  final loopVariable = _loweredForInCurrentDeclaration(loop.body, iterator);
  if (loopVariable == null) return null;
  final loopLocalId = locals.length;
  final bodyExpr = _loweredForInBodyExpr(
    loop.body,
    loopVariable,
    loopLocalId,
    effectiveBreakLabel,
    params,
    libraryUri,
    asyncKind,
    locals,
  );
  if (bodyExpr == null) return null;
  return {
    'yield_for_in': _yieldForInSpec(
      source: source,
      loopVariable: loopVariable,
      loopLocalId: loopLocalId,
      bodyExpr: bodyExpr,
    ),
  };
}

Map<String, Object?>? _generatorLoweredAsyncForInStreamExpr(
  Block block,
  Set<String> params,
  String libraryUri,
  String asyncKind,
  Map<VariableDeclaration, int> locals, {
  LabeledStatement? breakLabel,
}) {
  if (asyncKind != 'async_star' || block.statements.length != 3) return null;
  final stream = block.statements[0];
  final iterator = block.statements[1];
  final tryFinally = block.statements[2];
  if (stream is! VariableStatement ||
      iterator is! VariableStatement ||
      tryFinally is! TryFinally ||
      stream.initializer == null ||
      iterator.initializer == null ||
      !_isStreamIteratorConstructor(iterator.initializer!, stream) ||
      !_isStreamIteratorCancelFinally(tryFinally.finalizer, iterator)) {
    return null;
  }

  final streamLocalId = locals.length;
  final iteratorLocalId = locals.length + 1;
  final loopLocalId = locals.length + 2;
  final streamValue = _expr(stream.initializer!, params, libraryUri, locals);
  if (streamValue == null) return null;
  final streamLocals = {...locals, stream: streamLocalId};
  final iteratorValue = _streamIteratorConstructorExpr(
    iterator.initializer!,
    streamLocalId,
  );
  if (iteratorValue == null) return null;
  final streamIteratorLocals = {...streamLocals, iterator: iteratorLocalId};
  final finalizer = _streamIteratorCancelFinalizerExpr(iteratorLocalId);

  final rawLoop = tryFinally.body;
  final loopLabel = rawLoop is LabeledStatement ? rawLoop : null;
  final effectiveBreakLabel = breakLabel ?? loopLabel;
  final loop = loopLabel?.body ?? rawLoop;
  if (loop is! WhileStatement ||
      !_isAsyncStreamIteratorMoveNext(loop.condition, iterator)) {
    return null;
  }
  final loopVariable = _loweredForInCurrentDeclaration(loop.body, iterator);
  if (loopVariable == null) return null;
  final bodyExpr = _loweredForInBodyExpr(
    loop.body,
    loopVariable,
    loopLocalId,
    effectiveBreakLabel,
    params,
    libraryUri,
    asyncKind,
    streamIteratorLocals,
  );
  if (bodyExpr == null) return null;
  final condition = _awaitedFutureExpr(
    (loop.condition as AwaitExpression).operand,
    params,
    libraryUri,
    streamIteratorLocals,
  );
  final setCurrent = {
    'set_local': {
      'id': loopLocalId,
      'value': {
        'get_field': {
          'receiver': {'let_local': iteratorLocalId},
          'field': 'current',
        },
      },
    },
  };
  final loopBody = _streamIteratorLoopBody(setCurrent, bodyExpr);
  return {
    'let': {
      'locals': [
        {
          'id': streamLocalId,
          if (stream.name != null && stream.name!.isNotEmpty)
            'name': stream.name,
          'value': streamValue,
        },
        {
          'id': iteratorLocalId,
          if (iterator.name != null && iterator.name!.isNotEmpty)
            'name': iterator.name,
          'value': iteratorValue,
        },
        {
          'id': loopLocalId,
          if (loopVariable.name != null && loopVariable.name!.isNotEmpty)
            'name': loopVariable.name,
          'value': {'null': true},
        },
      ],
      'body': {
        'try_finally': {
          'body': {
            'while_loop': {'condition': condition, ...loopBody},
          },
          'finally': finalizer,
        },
      },
    },
  };
}

Map<String, Object?>? _yieldStarStreamExpr(
  Expression expression,
  Set<String> params,
  String libraryUri,
  Map<VariableDeclaration, int> locals,
) {
  final streamLocalId = locals.length;
  final iteratorLocalId = locals.length + 1;
  final currentLocalId = locals.length + 2;
  final streamValue = _expr(expression, params, libraryUri, locals);
  if (streamValue == null) return null;
  final iteratorValue = _streamIteratorConstructorValue(streamLocalId);
  final condition = {
    'await': {
      'call_dynamic': {
        'receiver': {'let_local': iteratorLocalId},
        'method': 'moveNext',
        'args': <Map<String, Object?>>[],
      },
    },
  };
  final setCurrent = {
    'set_local': {
      'id': currentLocalId,
      'value': {
        'get_field': {
          'receiver': {'let_local': iteratorLocalId},
          'field': 'current',
        },
      },
    },
  };
  final loopBody = _streamIteratorLoopBody(setCurrent, {
    'yield': {'let_local': currentLocalId},
  });
  return {
    'let': {
      'locals': [
        {'id': streamLocalId, 'name': ':stream', 'value': streamValue},
        {
          'id': iteratorLocalId,
          'name': ':yield-star-iterator',
          'value': iteratorValue,
        },
        {
          'id': currentLocalId,
          'name': ':yield-star-current',
          'value': {'null': true},
        },
      ],
      'body': {
        'try_finally': {
          'body': {
            'while_loop': {'condition': condition, ...loopBody},
          },
          'finally': _streamIteratorCancelFinalizerExpr(iteratorLocalId),
        },
      },
    },
  };
}

Map<String, Object?> _streamIteratorLoopBody(
  Map<String, Object?> setCurrent,
  Map<String, Object?> bodyExpr,
) {
  final body = Map<String, Object?>.of(bodyExpr)..remove('_uses_continue');
  final beforeContinue = body.remove('before_continue');
  final continueCondition = body.remove('continue_condition');
  final continueBody = body.remove('continue_body');
  final beforeBreak = body.remove('before_break');
  final breakCondition = body.remove('break_condition');
  final result = <String, Object?>{};
  if (continueCondition != null) {
    result['before_continue'] = _seqExpr([
      setCurrent,
      if (beforeContinue is Map) beforeContinue.cast<String, Object?>(),
    ]);
    result['continue_condition'] = continueCondition;
    result['continue_body'] = continueBody ?? {'null': true};
  } else if (breakCondition != null) {
    result['before_break'] = _seqExpr([
      setCurrent,
      if (beforeBreak is Map) beforeBreak.cast<String, Object?>(),
    ]);
  } else {
    result['body'] = _seqExpr([setCurrent, body]);
    return result;
  }
  if (breakCondition != null) {
    result['break_condition'] = breakCondition;
    if (beforeBreak != null && continueCondition != null) {
      result['before_break'] = beforeBreak;
    }
  }
  result['body'] = body;
  return result;
}

Map<String, Object?> _seqExpr(List<Map<String, Object?>> items) {
  final filtered = items
      .where((item) => item['null'] != true)
      .toList(growable: false);
  if (filtered.isEmpty) return {'null': true};
  if (filtered.length == 1) return filtered.single;
  return {'seq': filtered};
}

Map<String, Object?> _streamIteratorCancelFinalizerExpr(int iteratorLocalId) {
  return {
    'await': {
      'call_dynamic': {
        'receiver': {'let_local': iteratorLocalId},
        'method': 'cancel',
        'args': <Map<String, Object?>>[],
      },
    },
  };
}

Map<String, Object?> _streamIteratorConstructorValue(int streamLocalId) {
  return {
    'new_object': {
      'constructor': 'dart:async::class:_StreamIterator.',
      'args': [
        {'let_local': streamLocalId},
      ],
    },
  };
}

Map<String, Object?>? _streamIteratorConstructorExpr(
  Expression expression,
  int streamLocalId,
) {
  if (expression is! ConstructorInvocation) return null;
  return _streamIteratorConstructorValue(streamLocalId);
}

bool _isStreamIteratorConstructor(
  Expression expression,
  VariableStatement stream,
) {
  final name = _kernelVariableName(stream);
  if (name.isEmpty) return false;
  final text = _nodeText(expression);
  return text.contains('_StreamIterator') && text.contains(name);
}

bool _isAsyncStreamIteratorMoveNext(
  Expression expression,
  VariableStatement iterator,
) {
  if (expression is! AwaitExpression) return false;
  final name = _kernelVariableName(iterator);
  if (name.isEmpty) return false;
  final text = _nodeText(expression.operand);
  return text.contains('_StreamIterator::moveNext') && text.contains(name);
}

bool _isStreamIteratorCancelFinally(
  Statement statement,
  VariableStatement iterator,
) {
  final name = _kernelVariableName(iterator);
  if (name.isEmpty) return false;
  final text = _nodeText(statement);
  return text.contains('_StreamIterator::cancel') && text.contains(name);
}

String _kernelVariableName(VariableDeclaration variable) =>
    variable.name?.trim() ?? '';
