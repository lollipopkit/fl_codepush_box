part of fcb_kernel_reader;

Map<String, Object?>? _generatorSource(
  String libraryUri,
  String qualified,
  List<String> params,
  Set<String> paramsSet,
  FunctionNode function,
) {
  final asyncKind = switch (function.dartAsyncMarker) {
    AsyncMarker.SyncStar => 'sync_star',
    AsyncMarker.AsyncStar => 'async_star',
    _ => null,
  };
  if (asyncKind == null) return null;
  final body = _generatorBodyExpr(
    function.body,
    paramsSet,
    libraryUri,
    asyncKind,
  );
  if (body == null) return null;
  return {
    'name': '$libraryUri::$qualified',
    'return_type': fcbKernelTypeName(function.returnType),
    'params': params,
    'body': body,
    'async_kind': asyncKind,
  };
}

Map<String, Object?>? _generatorBodyExpr(
  Statement? body,
  Set<String> params,
  String libraryUri,
  String asyncKind, [
  Map<VariableDeclaration, int> locals = const {},
]) {
  if (body == null) return null;
  if (body is YieldStatement) {
    return _yieldStatementExpr(body, params, libraryUri, asyncKind, locals);
  }
  if (body is IfStatement) {
    return _generatorIfExpr(body, params, libraryUri, asyncKind, locals);
  }
  if (body is ForInStatement) {
    return _generatorForInExpr(body, params, libraryUri, asyncKind, locals);
  }
  if (body is ForStatement) {
    return _generatorForExpr(body, params, libraryUri, asyncKind, locals);
  }
  if (body is WhileStatement) {
    return _generatorWhileExpr(body, params, libraryUri, asyncKind, locals);
  }
  if (body is DoStatement) {
    return _generatorDoExpr(body, params, libraryUri, asyncKind, locals);
  }
  if (body is TryCatch) {
    return _generatorTryCatchExpr(body, params, libraryUri, asyncKind, locals);
  }
  if (body is TryFinally) {
    return _generatorTryFinallyExpr(
      body,
      params,
      libraryUri,
      asyncKind,
      locals,
    );
  }
  if (body is ExpressionStatement) {
    return _generatorExpressionStatementExpr(body, params, libraryUri, locals);
  }
  if (body is LabeledStatement) {
    return _generatorLabeledExpr(body, params, libraryUri, asyncKind, locals);
  }
  if (body is EmptyStatement) return {'null': true};
  if (body is Block) {
    return _generatorBlockExpr(body, params, libraryUri, asyncKind, locals);
  }
  return null;
}

Map<String, Object?>? _generatorBlockExpr(
  Block block,
  Set<String> params,
  String libraryUri,
  String asyncKind,
  Map<VariableDeclaration, int> outerLocals,
) {
  if (block.statements.isEmpty) return {'null': true};
  final loweredForIn = _generatorLoweredStaticForInExpr(
    block,
    params,
    libraryUri,
    asyncKind,
    outerLocals,
  );
  if (loweredForIn != null) return loweredForIn;
  final loweredAsyncForIn = _generatorLoweredAsyncForInFromIterableExpr(
    block,
    params,
    libraryUri,
    asyncKind,
    outerLocals,
  );
  if (loweredAsyncForIn != null) return loweredAsyncForIn;
  final loweredAsyncForInStream = _generatorLoweredAsyncForInStreamExpr(
    block,
    params,
    libraryUri,
    asyncKind,
    outerLocals,
  );
  if (loweredAsyncForInStream != null) return loweredAsyncForInStream;

  final localIds = Map<VariableDeclaration, int>.of(outerLocals);
  final localEntries = <Map<String, Object?>>[];
  final bodyItems = <Map<String, Object?>>[];
  var nextLocalId = localIds.length;

  for (final statement in block.statements) {
    if (statement is VariableDeclaration && statement.initializer != null) {
      final value = _generatorValueExpr(
        statement.initializer!,
        params,
        libraryUri,
        asyncKind,
        localIds,
      );
      if (value == null) return null;
      final id = nextLocalId++;
      localIds[statement] = id;
      localEntries.add({
        'id': id,
        if (statement.name != null && statement.name!.isNotEmpty)
          'name': statement.name,
        'value': value,
      });
      continue;
    }
    final item = _generatorBodyExpr(
      statement,
      params,
      libraryUri,
      asyncKind,
      localIds,
    );
    if (item == null) return null;
    bodyItems.add(item);
  }

  final body = bodyItems.isEmpty
      ? {'null': true}
      : bodyItems.length == 1
      ? bodyItems.single
      : {'seq': bodyItems};
  if (localEntries.isEmpty) return body;
  return {
    'let': {'locals': localEntries, 'body': body},
  };
}

Map<String, Object?>? _generatorTryCatchExpr(
  TryCatch statement,
  Set<String> params,
  String libraryUri,
  String asyncKind,
  Map<VariableDeclaration, int> locals,
) {
  if (statement.catches.length != 1) return null;
  final catchClause = statement.catches.single;
  if (catchClause.stackTrace != null || catchClause.exception == null) {
    return null;
  }
  final catchLocalId = locals.length;
  final body = _generatorBodyExpr(
    statement.body,
    params,
    libraryUri,
    asyncKind,
    locals,
  );
  final catchBody = _generatorBodyExpr(
    catchClause.body,
    params,
    libraryUri,
    asyncKind,
    {...locals, catchClause.exception!: catchLocalId},
  );
  if (body == null || catchBody == null) return null;
  return {
    'try_catch': {
      'body': body,
      'catch_local': catchLocalId,
      'catch': catchBody,
    },
  };
}

Map<String, Object?>? _generatorTryFinallyExpr(
  TryFinally statement,
  Set<String> params,
  String libraryUri,
  String asyncKind,
  Map<VariableDeclaration, int> locals,
) {
  final body = _generatorBodyExpr(
    statement.body,
    params,
    libraryUri,
    asyncKind,
    locals,
  );
  final finalizer = _generatorBodyExpr(
    statement.finalizer,
    params,
    libraryUri,
    asyncKind,
    locals,
  );
  if (body == null || finalizer == null) return null;
  return {
    'try_finally': {'body': body, 'finally': finalizer},
  };
}

Map<String, Object?>? _generatorValueExpr(
  Expression expression,
  Set<String> params,
  String libraryUri,
  String asyncKind,
  Map<VariableDeclaration, int> locals,
) {
  if (asyncKind == 'async_star' && expression is AwaitExpression) {
    return _awaitedFutureExpr(expression.operand, params, libraryUri, locals);
  }
  return _expr(expression, params, libraryUri, locals);
}

Map<String, Object?>? _generatorExpressionStatementExpr(
  ExpressionStatement statement,
  Set<String> params,
  String libraryUri,
  Map<VariableDeclaration, int> locals,
) {
  final expression = statement.expression;
  return _generatorExpressionExpr(expression, params, libraryUri, locals);
}

Map<String, Object?>? _generatorExpressionExpr(
  Expression expression,
  Set<String> params,
  String libraryUri,
  Map<VariableDeclaration, int> locals,
) {
  if (expression is VariableSet) {
    final id = locals[expression.variable];
    if (id == null) return null;
    final value = _expr(expression.value, params, libraryUri, locals);
    if (value == null) return null;
    return {
      'set_local': {'id': id, 'value': value},
    };
  }
  return null;
}

Map<String, Object?>? _generatorDoExpr(
  DoStatement statement,
  Set<String> params,
  String libraryUri,
  String asyncKind,
  Map<VariableDeclaration, int> locals, {
  LabeledStatement? breakLabel,
}) {
  final condition = _expr(statement.condition, params, libraryUri, locals);
  final bodyLabel = statement.body is LabeledStatement
      ? statement.body as LabeledStatement
      : null;
  final body = breakLabel != null
      ? _generatorBreakableDoBodyExpr(
          statement.body,
          breakLabel,
          params,
          libraryUri,
          asyncKind,
          locals,
          continueLabel: bodyLabel,
        )
      : bodyLabel != null
      ? _generatorContinueDoBodyExpr(
          bodyLabel,
          params,
          libraryUri,
          asyncKind,
          locals,
        )
      : _generatorBodyExpr(
          statement.body,
          params,
          libraryUri,
          asyncKind,
          locals,
        );
  if (condition == null || body == null) return null;
  final beforeBreak = body.remove('before_break');
  final breakCondition = body.remove('break_condition');
  final beforeContinue = body.remove('before_continue');
  final continueCondition = body.remove('continue_condition');
  final continueBody = body.remove('continue_body');
  if (breakCondition != null &&
      continueCondition != null &&
      continueBody != null) {
    return _generatorDoContinueBreakExpr(
      condition,
      body,
      beforeContinue,
      continueCondition,
      continueBody,
      beforeBreak,
      breakCondition,
    );
  }
  if (breakCondition != null) {
    return _generatorDoBreakExpr(condition, body, beforeBreak, breakCondition);
  }
  if (continueCondition != null && continueBody != null) {
    return _generatorDoContinueExpr(
      condition,
      body,
      beforeContinue,
      continueCondition,
      continueBody,
    );
  }
  return {
    'seq': [
      body,
      {
        'while_loop': {'condition': condition, 'body': body},
      },
    ],
  };
}

Map<String, Object?>? _generatorBreakableDoBodyExpr(
  Statement body,
  LabeledStatement breakLabel,
  Set<String> params,
  String libraryUri,
  String asyncKind,
  Map<VariableDeclaration, int> locals, {
  LabeledStatement? continueLabel,
}) {
  final labeledBody = body is LabeledStatement ? body : null;
  final loopBody = labeledBody?.body ?? body;
  final effectiveContinueLabel = continueLabel ?? labeledBody;
  if (loopBody is! Block) return null;
  if (effectiveContinueLabel != null) {
    final continueBody = _loweredWhileContinueBodyExpr(
      loopBody.statements,
      effectiveContinueLabel,
      params,
      libraryUri,
      asyncKind,
      locals,
      breakLabel: breakLabel,
    );
    if (continueBody != null) return continueBody;
  }
  final breakBody = _loweredForInBreakBodyExpr(
    loopBody.statements,
    breakLabel,
    params,
    libraryUri,
    asyncKind,
    locals,
  );
  return breakBody ??
      _generatorBodyExpr(loopBody, params, libraryUri, asyncKind, locals);
}

Map<String, Object?>? _generatorContinueDoBodyExpr(
  LabeledStatement continueLabel,
  Set<String> params,
  String libraryUri,
  String asyncKind,
  Map<VariableDeclaration, int> locals,
) {
  final body = continueLabel.body;
  if (body is! Block) return null;
  final continueBody = _loweredWhileContinueBodyExpr(
    body.statements,
    continueLabel,
    params,
    libraryUri,
    asyncKind,
    locals,
  );
  return continueBody ??
      _generatorBodyExpr(body, params, libraryUri, asyncKind, locals);
}

Map<String, Object?> _generatorDoBreakExpr(
  Map<String, Object?> condition,
  Map<String, Object?> body,
  Object? beforeBreak,
  Object? breakCondition,
) {
  final loop = {
    'while_loop': {
      'condition': condition,
      if (beforeBreak != null) 'before_break': beforeBreak,
      'break_condition': breakCondition,
      'body': body,
    },
  };
  final afterFirst = _generatorSeq([..._generatorSeqItems(body), loop]);
  return _generatorSeq([
    if (beforeBreak is Map) beforeBreak.cast<String, Object?>(),
    {
      'conditional': {
        'condition': (breakCondition as Map).cast<String, Object?>(),
        'then': {'null': true},
        'else': afterFirst,
      },
    },
  ]);
}

Map<String, Object?> _generatorDoContinueExpr(
  Map<String, Object?> condition,
  Map<String, Object?> body,
  Object? beforeContinue,
  Object? continueCondition,
  Object? continueBody,
) {
  final loop = {
    'while_loop': {
      'condition': condition,
      if (beforeContinue != null) 'before_continue': beforeContinue,
      'continue_condition': continueCondition,
      'continue_body': continueBody,
      'body': body,
    },
  };
  return _generatorSeq([
    if (beforeContinue is Map) beforeContinue.cast<String, Object?>(),
    {
      'conditional': {
        'condition': (continueCondition as Map).cast<String, Object?>(),
        'then': (continueBody as Map).cast<String, Object?>(),
        'else': body,
      },
    },
    loop,
  ]);
}

Map<String, Object?> _generatorDoContinueBreakExpr(
  Map<String, Object?> condition,
  Map<String, Object?> body,
  Object? beforeContinue,
  Object? continueCondition,
  Object? continueBody,
  Object? beforeBreak,
  Object? breakCondition,
) {
  final loop = {
    'while_loop': {
      'condition': condition,
      if (beforeContinue != null) 'before_continue': beforeContinue,
      'continue_condition': continueCondition,
      'continue_body': continueBody,
      if (beforeBreak != null) 'before_break': beforeBreak,
      'break_condition': breakCondition,
      'body': body,
    },
  };
  final afterContinue = _generatorSeq([
    if (beforeBreak is Map) beforeBreak.cast<String, Object?>(),
    {
      'conditional': {
        'condition': (breakCondition as Map).cast<String, Object?>(),
        'then': {'null': true},
        'else': _generatorSeq([..._generatorSeqItems(body), loop]),
      },
    },
  ]);
  return _generatorSeq([
    if (beforeContinue is Map) beforeContinue.cast<String, Object?>(),
    {
      'conditional': {
        'condition': (continueCondition as Map).cast<String, Object?>(),
        'then': _generatorSeq([
          (continueBody as Map).cast<String, Object?>(),
          loop,
        ]),
        'else': afterContinue,
      },
    },
  ]);
}

Map<String, Object?>? _yieldStatementExpr(
  YieldStatement statement,
  Set<String> params,
  String libraryUri,
  String asyncKind,
  Map<VariableDeclaration, int> locals,
) {
  if (statement.isYieldStar) {
    final staticItems = _yieldStarStaticListExpr(
      statement.expression,
      params,
      libraryUri,
      locals,
    );
    if (staticItems != null) return staticItems;
    if (asyncKind == 'sync_star') {
      return _yieldStarDynamicIterableExpr(
        statement.expression,
        params,
        libraryUri,
        locals,
      );
    }
    if (asyncKind == 'async_star') {
      final streamIterable = _finiteStreamDynamicSource(
        statement.expression,
        params,
        libraryUri,
        locals,
      );
      if (streamIterable != null) {
        return {
          'yield_for_in': {'source': streamIterable},
        };
      }
      final stream = _yieldStarStreamExpr(
        statement.expression,
        params,
        libraryUri,
        locals,
      );
      if (stream != null) return stream;
    }
    return null;
  }
  final value = _generatorValueExpr(
    statement.expression,
    params,
    libraryUri,
    asyncKind,
    locals,
  );
  if (value == null) return null;
  return {'yield': value};
}

Map<String, Object?>? _yieldStarStaticListExpr(
  Expression expression,
  Set<String> params,
  String libraryUri,
  Map<VariableDeclaration, int> locals,
) {
  final listItems =
      _expr(expression, params, libraryUri, locals)?['list'] ??
      _finiteStreamStaticListItems(expression, params, libraryUri, locals);
  if (listItems is! List) return null;
  final items = <Map<String, Object?>>[];
  for (final item in listItems) {
    if (item is! Map) return null;
    items.add({'yield': item.cast<String, Object?>()});
  }
  if (items.isEmpty) return {'null': true};
  return items.length == 1 ? items.single : {'seq': items};
}

Map<String, Object?>? _yieldStarDynamicIterableExpr(
  Expression expression,
  Set<String> params,
  String libraryUri,
  Map<VariableDeclaration, int> locals,
) {
  final source = _expr(expression, params, libraryUri, locals);
  if (source == null || source['list'] is List || source['map'] is List) {
    return null;
  }
  return {
    'yield_for_in': {'source': source},
  };
}

Map<String, Object?>? _generatorIfExpr(
  IfStatement statement,
  Set<String> params,
  String libraryUri,
  String asyncKind,
  Map<VariableDeclaration, int> locals,
) {
  final condition = _expr(statement.condition, params, libraryUri, locals);
  final thenExpr = _generatorBodyExpr(
    statement.then,
    params,
    libraryUri,
    asyncKind,
    locals,
  );
  final elseExpr = statement.otherwise == null
      ? {'null': true}
      : _generatorBodyExpr(
          statement.otherwise,
          params,
          libraryUri,
          asyncKind,
          locals,
        );
  if (condition == null || thenExpr == null || elseExpr == null) return null;
  return {
    'conditional': {'condition': condition, 'then': thenExpr, 'else': elseExpr},
  };
}

Map<String, Object?>? _generatorForInExpr(
  ForInStatement statement,
  Set<String> params,
  String libraryUri,
  String asyncKind,
  Map<VariableDeclaration, int> locals,
) {
  if (statement.isAsync) {
    return _generatorAsyncForInFromIterableExpr(
      statement,
      params,
      libraryUri,
      asyncKind,
      locals,
    );
  }
  final iterableExpr = _expr(statement.iterable, params, libraryUri, locals);
  final listItems = iterableExpr?['list'];
  if (listItems is! List) return null;
  final items = <Map<String, Object?>>[];
  final loopLocalId = locals.length;
  for (final item in listItems) {
    if (item is! Map) return null;
    final value = item.cast<String, Object?>();
    final bodyExpr = _generatorBodyExpr(
      statement.body,
      params,
      libraryUri,
      asyncKind,
      {...locals, statement.variable: loopLocalId},
    );
    if (bodyExpr == null) return null;
    items.add({
      'let': {
        'locals': [
          {
            'id': loopLocalId,
            if (statement.variable.name != null &&
                statement.variable.name!.isNotEmpty)
              'name': statement.variable.name,
            'value': value,
          },
        ],
        'body': bodyExpr,
      },
    });
  }
  if (items.isEmpty) return {'null': true};
  return items.length == 1 ? items.single : {'seq': items};
}

Map<String, Object?>? _generatorLabeledExpr(
  LabeledStatement statement,
  Set<String> params,
  String libraryUri,
  String asyncKind,
  Map<VariableDeclaration, int> locals,
) {
  final body = statement.body;
  if (body is WhileStatement) {
    return _generatorWhileExpr(
      body,
      params,
      libraryUri,
      asyncKind,
      locals,
      breakLabel: statement,
    );
  }
  if (body is ForStatement) {
    return _generatorForExpr(
      body,
      params,
      libraryUri,
      asyncKind,
      locals,
      breakLabel: statement,
    );
  }
  if (body is DoStatement) {
    return _generatorDoExpr(
      body,
      params,
      libraryUri,
      asyncKind,
      locals,
      breakLabel: statement,
    );
  }
  if (body is Block) {
    final loweredAsyncForIn = _generatorLoweredAsyncForInFromIterableExpr(
      body,
      params,
      libraryUri,
      asyncKind,
      locals,
      breakLabel: statement,
    );
    if (loweredAsyncForIn != null) return loweredAsyncForIn;
    final loweredAsyncForInStream = _generatorLoweredAsyncForInStreamExpr(
      body,
      params,
      libraryUri,
      asyncKind,
      locals,
      breakLabel: statement,
    );
    if (loweredAsyncForInStream != null) return loweredAsyncForInStream;
    return _generatorLoweredStaticForInExpr(
      body,
      params,
      libraryUri,
      asyncKind,
      locals,
      breakLabel: statement,
    );
  }
  return null;
}

Map<String, Object?>? _generatorLoweredStaticForInExpr(
  Block block,
  Set<String> params,
  String libraryUri,
  String asyncKind,
  Map<VariableDeclaration, int> locals, {
  LabeledStatement? breakLabel,
}) {
  if (block.statements.length != 2 ||
      block.statements.first is! VariableStatement) {
    return null;
  }
  final iterator = block.statements.first as VariableStatement;
  final loweredLoop = _loweredForInLoop(block.statements.last);
  if (loweredLoop == null) return null;
  final forStatement = loweredLoop.statement;
  if (forStatement.variableInitializations.isNotEmpty ||
      forStatement.updates.isNotEmpty) {
    return null;
  }
  final loopBreakLabel = breakLabel ?? loweredLoop.breakLabel;
  final dynamicForIn = _generatorLoweredDynamicForInExpr(
    iterator,
    forStatement,
    loopBreakLabel,
    params,
    libraryUri,
    asyncKind,
    locals,
  );
  if (dynamicForIn != null) return dynamicForIn;
  final listItems = _staticListLiteralItems(
    iterator.initializer,
    params,
    libraryUri,
    locals,
  );
  if (listItems == null) return null;
  final loopVariable = _loweredForInCurrentDeclaration(
    forStatement.body,
    iterator,
  );
  if (loopVariable == null) return null;
  final loopLocalId = locals.length;
  final bodyExpr = _loweredForInBodyExpr(
    forStatement.body,
    loopVariable,
    loopLocalId,
    loopBreakLabel,
    params,
    libraryUri,
    asyncKind,
    locals,
  );
  if (bodyExpr == null) return null;
  final usesContinue = bodyExpr.remove('_uses_continue') == true;
  if (bodyExpr['break_condition'] != null ||
      bodyExpr['before_break'] != null ||
      usesContinue) {
    return {
      'yield_for_in': _yieldForInSpec(
        source: {'list': listItems},
        loopVariable: loopVariable,
        loopLocalId: loopLocalId,
        bodyExpr: bodyExpr,
      ),
    };
  }
  final items = [
    for (final value in listItems)
      {
        'let': {
          'locals': [
            {
              'id': loopLocalId,
              if (loopVariable.name != null && loopVariable.name!.isNotEmpty)
                'name': loopVariable.name,
              'value': value,
            },
          ],
          'body': bodyExpr,
        },
      },
  ];
  if (items.isEmpty) return {'null': true};
  return items.length == 1 ? items.single : {'seq': items};
}

Map<String, Object?>? _generatorLoweredDynamicForInExpr(
  VariableStatement iterator,
  ForStatement forStatement,
  LabeledStatement? breakLabel,
  Set<String> params,
  String libraryUri,
  String asyncKind,
  Map<VariableDeclaration, int> locals,
) {
  if (iterator.initializer == null ||
      !_isIteratorMoveNext(forStatement.condition, iterator)) {
    return null;
  }
  final source = _runtimeIteratorSource(
    iterator.initializer!,
    params,
    libraryUri,
  );
  if (source == null || source.kind != _RuntimeCollectionForKind.list) {
    return null;
  }
  final loopVariable = _loweredForInCurrentDeclaration(
    forStatement.body,
    iterator,
  );
  if (loopVariable == null) return null;
  final loopLocalId = locals.length;
  final bodyExpr = _loweredForInBodyExpr(
    forStatement.body,
    loopVariable,
    loopLocalId,
    breakLabel,
    params,
    libraryUri,
    asyncKind,
    locals,
  );
  if (bodyExpr == null) return null;
  final spec = <String, Object?>{
    ..._yieldForInSpec(
      source: source.source,
      loopVariable: loopVariable,
      loopLocalId: loopLocalId,
      bodyExpr: bodyExpr,
    ),
  };
  return {'yield_for_in': spec};
}

Map<String, Object?> _yieldForInSpec({
  required Map<String, Object?> source,
  required VariableDeclaration loopVariable,
  required int loopLocalId,
  required Map<String, Object?> bodyExpr,
}) {
  bodyExpr.remove('_uses_continue');
  final spec = <String, Object?>{
    'source': source,
    'local': {
      'id': loopLocalId,
      if (loopVariable.name != null && loopVariable.name!.isNotEmpty)
        'name': loopVariable.name,
    },
  };
  final beforeBreak = bodyExpr.remove('before_break');
  if (beforeBreak != null) spec['before_break'] = beforeBreak;
  final breakCondition = bodyExpr.remove('break_condition');
  if (breakCondition != null) spec['break_condition'] = breakCondition;
  spec['body'] = bodyExpr;
  return spec;
}

List<Map<String, Object?>>? _staticListLiteralItems(
  Expression? expression,
  Set<String> params,
  String libraryUri,
  Map<VariableDeclaration, int> locals,
) {
  if (expression is InstanceGet) {
    return _staticListLiteralItems(
      expression.receiver,
      params,
      libraryUri,
      locals,
    );
  }
  if (expression is StaticInvocation) {
    final text = _nodeText(expression);
    if (!text.contains('_GrowableList::_literal')) return null;
    final items = <Map<String, Object?>>[];
    for (final arg in expression.arguments.positional) {
      final item = _expr(arg, params, libraryUri, locals);
      if (item == null) return null;
      items.add(item);
    }
    return items;
  }
  return null;
}

VariableDeclaration? _loweredForInCurrentDeclaration(
  Statement body,
  VariableStatement iterator,
) {
  if (body is! Block || body.statements.length < 2) return null;
  final first = body.statements.first;
  if (first is! VariableStatement) return null;
  if (first.initializer == null ||
      !_isIteratorCurrent(first.initializer!, iterator)) {
    return null;
  }
  return first;
}

Map<String, Object?>? _loweredForInBodyExpr(
  Statement body,
  VariableDeclaration loopVariable,
  int loopLocalId,
  LabeledStatement? breakLabel,
  Set<String> params,
  String libraryUri,
  String asyncKind,
  Map<VariableDeclaration, int> locals,
) {
  if (body is! Block || body.statements.length < 2) return null;
  final tail = _loweredForInTailStatements(
    body.statements.skip(1).toList(growable: false),
  );
  final tailBody = tail.length == 1 ? tail.single : Block(tail);
  final scopedLocals = {...locals, loopVariable: loopLocalId};
  if (breakLabel != null && tailBody is LabeledStatement) {
    final continueBreakBody = _loweredForInContinueThenBreakBodyExpr(
      tailBody,
      breakLabel,
      params,
      libraryUri,
      asyncKind,
      scopedLocals,
    );
    if (continueBreakBody != null) return continueBreakBody;
  }
  if (breakLabel != null) {
    final breakBody = _loweredForInBreakBodyExpr(
      tail,
      breakLabel,
      params,
      libraryUri,
      asyncKind,
      scopedLocals,
    );
    if (breakBody != null) return breakBody;
  }
  if (tailBody is LabeledStatement) {
    final continueBody = _loweredForInContinueBodyExpr(
      tailBody,
      params,
      libraryUri,
      asyncKind,
      scopedLocals,
    );
    if (continueBody == null) return null;
    return {'_uses_continue': true, ...continueBody};
  }
  return _generatorBodyExpr(
    tailBody,
    params,
    libraryUri,
    asyncKind,
    scopedLocals,
  );
}

Map<String, Object?>? _loweredForInContinueThenBreakBodyExpr(
  LabeledStatement continueLabel,
  LabeledStatement breakLabel,
  Set<String> params,
  String libraryUri,
  String asyncKind,
  Map<VariableDeclaration, int> locals,
) {
  final body = continueLabel.body;
  if (body is! Block || body.statements.length < 2) return null;
  final continueStatement = body.statements.first;
  if (continueStatement is! IfStatement ||
      continueStatement.otherwise != null ||
      !_isRepeatableGuardCondition(continueStatement.condition) ||
      !_isBreakToLabel(continueStatement.then, continueLabel)) {
    return null;
  }
  final remaining = body.statements.skip(1).toList(growable: false);
  final breakIndex = remaining.indexWhere(
    (statement) =>
        statement is IfStatement &&
        statement.otherwise == null &&
        _isBreakToLabel(statement.then, breakLabel),
  );
  if (breakIndex < 0) return null;
  final breakStatement = remaining[breakIndex] as IfStatement;
  final continueCondition = _expr(
    continueStatement.condition,
    params,
    libraryUri,
    locals,
  );
  final breakCondition = _expr(
    breakStatement.condition,
    params,
    libraryUri,
    locals,
  );
  final beforeBreak = remaining.take(breakIndex).toList(growable: false);
  final beforeBreakExpr = beforeBreak.isEmpty
      ? null
      : _generatorBodyExpr(
          beforeBreak.length == 1 ? beforeBreak.single : Block(beforeBreak),
          params,
          libraryUri,
          asyncKind,
          locals,
        );
  if (beforeBreak.isNotEmpty && beforeBreakExpr == null) return null;
  final tail = remaining.skip(breakIndex + 1).toList(growable: false);
  final tailExpr = tail.isEmpty
      ? {'null': true}
      : _generatorBodyExpr(
          tail.length == 1 ? tail.single : Block(tail),
          params,
          libraryUri,
          asyncKind,
          locals,
        );
  if (continueCondition == null || breakCondition == null || tailExpr == null) {
    return null;
  }
  final guardedBeforeBreak = beforeBreakExpr == null
      ? null
      : _guardedContinueTail(continueCondition, beforeBreakExpr);
  return {
    '_uses_continue': true,
    if (guardedBeforeBreak != null) 'before_break': guardedBeforeBreak,
    'break_condition': {
      'conditional': {
        'condition': continueCondition,
        'then': {'bool': false},
        'else': breakCondition,
      },
    },
    ..._guardedContinueTail(continueCondition, tailExpr),
  };
}

Map<String, Object?> _guardedContinueTail(
  Map<String, Object?> condition,
  Map<String, Object?> tail,
) {
  return {
    'conditional': {
      'condition': condition,
      'then': {'null': true},
      'else': tail,
    },
  };
}

List<Statement> _loweredForInTailStatements(List<Statement> tail) {
  if (tail.length == 1 && tail.single is Block) {
    return (tail.single as Block).statements;
  }
  return tail;
}

Map<String, Object?>? _loweredForInBreakBodyExpr(
  List<Statement> statements,
  LabeledStatement breakLabel,
  Set<String> params,
  String libraryUri,
  String asyncKind,
  Map<VariableDeclaration, int> locals,
) {
  if (statements.isEmpty) return null;
  final breakIndex = statements.indexWhere(
    (statement) =>
        statement is IfStatement &&
        statement.otherwise == null &&
        _isBreakToLabel(statement.then, breakLabel),
  );
  if (breakIndex < 0) {
    return null;
  }
  final breakStatement = statements[breakIndex] as IfStatement;
  final condition = _expr(breakStatement.condition, params, libraryUri, locals);
  final beforeBreak = statements.take(breakIndex).toList(growable: false);
  final tail = statements.skip(breakIndex + 1).toList(growable: false);
  if (condition == null) return null;
  final beforeBreakBody = beforeBreak.isEmpty
      ? null
      : _generatorBodyExpr(
          beforeBreak.length == 1 ? beforeBreak.single : Block(beforeBreak),
          params,
          libraryUri,
          asyncKind,
          locals,
        );
  if (beforeBreak.isNotEmpty && beforeBreakBody == null) return null;
  final bodyExpr = tail.isEmpty
      ? {'null': true}
      : _generatorBodyExpr(
          tail.length == 1 ? tail.single : Block(tail),
          params,
          libraryUri,
          asyncKind,
          locals,
        );
  if (bodyExpr == null) return null;
  return {
    if (beforeBreakBody != null) 'before_break': beforeBreakBody,
    'break_condition': condition,
    ...bodyExpr,
  };
}

_LoweredForInLoop? _loweredForInLoop(Statement statement) {
  if (statement is ForStatement) {
    return _LoweredForInLoop(statement: statement);
  }
  if (statement is LabeledStatement && statement.body is ForStatement) {
    return _LoweredForInLoop(
      statement: statement.body as ForStatement,
      breakLabel: statement,
    );
  }
  return null;
}

class _LoweredForInLoop {
  _LoweredForInLoop({required this.statement, this.breakLabel});

  final ForStatement statement;
  final LabeledStatement? breakLabel;
}

Map<String, Object?>? _loweredForInContinueBodyExpr(
  LabeledStatement labeled,
  Set<String> params,
  String libraryUri,
  String asyncKind,
  Map<VariableDeclaration, int> locals,
) {
  final body = labeled.body;
  if (body is! Block) return null;
  return _loweredForInContinueBlockExpr(
    body.statements,
    labeled,
    params,
    libraryUri,
    asyncKind,
    locals,
  );
}

Map<String, Object?>? _loweredForInContinueBlockExpr(
  List<Statement> statements,
  LabeledStatement label,
  Set<String> params,
  String libraryUri,
  String asyncKind,
  Map<VariableDeclaration, int> locals,
) {
  if (statements.isEmpty) return {'null': true};
  final first = statements.first;
  if (first is IfStatement &&
      first.otherwise == null &&
      _isBreakToLabel(first.then, label)) {
    final condition = _expr(first.condition, params, libraryUri, locals);
    final elseExpr = _loweredForInContinueBlockExpr(
      statements.skip(1).toList(growable: false),
      label,
      params,
      libraryUri,
      asyncKind,
      locals,
    );
    if (condition == null || elseExpr == null) return null;
    return {
      'conditional': {
        'condition': condition,
        'then': {'null': true},
        'else': elseExpr,
      },
    };
  }
  if (first is BreakStatement) return null;
  if (statements.length == 1) {
    return _generatorBodyExpr(first, params, libraryUri, asyncKind, locals);
  }
  final item = _generatorBodyExpr(first, params, libraryUri, asyncKind, locals);
  final rest = _loweredForInContinueBlockExpr(
    statements.skip(1).toList(growable: false),
    label,
    params,
    libraryUri,
    asyncKind,
    locals,
  );
  if (item == null || rest == null) return null;
  return {
    'seq': [item, rest],
  };
}

bool _isBreakToLabel(Statement statement, LabeledStatement label) {
  final unwrapped = statement is Block && statement.statements.length == 1
      ? statement.statements.single
      : statement;
  return unwrapped is BreakStatement && unwrapped.target == label;
}

List<Statement>? _continueBranchPrefix(
  Statement statement,
  LabeledStatement label,
) {
  if (statement is BreakStatement && statement.target == label) {
    return const [];
  }
  if (statement is! Block || statement.statements.isEmpty) return null;
  final last = statement.statements.last;
  if (last is! BreakStatement || last.target != label) return null;
  return statement.statements
      .take(statement.statements.length - 1)
      .toList(growable: false);
}

bool _isRepeatableGuardCondition(Expression expression) {
  if (expression is BoolLiteral || expression is VariableGet) return true;
  if (expression is Not) return _isRepeatableGuardCondition(expression.operand);
  if (expression is EqualsCall) {
    return _isRepeatableGuardOperand(expression.left) &&
        _isRepeatableGuardOperand(expression.right);
  }
  return false;
}

bool _isRepeatableGuardOperand(Expression expression) {
  return expression is VariableGet ||
      expression is StringLiteral ||
      expression is IntLiteral ||
      expression is DoubleLiteral ||
      expression is BoolLiteral ||
      expression is NullLiteral;
}
