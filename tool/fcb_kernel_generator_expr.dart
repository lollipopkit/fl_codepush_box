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
  if (body is SwitchStatement) {
    return _generatorSwitchStatementExpr(
      body,
      null,
      params,
      libraryUri,
      asyncKind,
      locals,
    );
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
  if (asyncKind == 'async_star') {
    return _asyncCompletedExpr(expression, params, libraryUri, locals) ??
        _expr(expression, params, libraryUri, locals);
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
  if (expression is Throw) {
    return _expr(expression, params, libraryUri, locals);
  }
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

Map<String, Object?>? _generatorIfExpr(
  IfStatement statement,
  Set<String> params,
  String libraryUri,
  String asyncKind,
  Map<VariableDeclaration, int> locals,
) {
  final condition = asyncKind == 'async_star'
      ? _asyncConditionExpr(statement.condition, params, libraryUri, locals)
      : _expr(statement.condition, params, libraryUri, locals);
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
  if (body is SwitchStatement) {
    return _generatorSwitchStatementExpr(
      body,
      statement,
      params,
      libraryUri,
      asyncKind,
      locals,
    );
  }
  if (body is Block) {
    final loweredSwitch = _generatorLoweredSwitchStatementExpr(
      statement,
      params,
      libraryUri,
      asyncKind,
      locals,
    );
    if (loweredSwitch != null) return loweredSwitch;
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

Map<String, Object?>? _generatorSwitchStatementExpr(
  SwitchStatement statement,
  LabeledStatement? breakLabel,
  Set<String> params,
  String libraryUri,
  String asyncKind,
  Map<VariableDeclaration, int> locals,
) {
  if (!statement.hasDefault || statement.cases.length < 2) return null;
  final scrutinee = _generatorSwitchValueExpr(
    statement.expression,
    params,
    libraryUri,
    asyncKind,
    locals,
  );
  if (scrutinee == null) return null;

  final branches = <_FcbSwitchExpressionBranch>[];
  Map<String, Object?>? otherwise;
  for (final switchCase in statement.cases) {
    final body = _generatorSwitchCaseBodyExpr(
      switchCase.body,
      breakLabel,
      switchCase.isDefault,
      params,
      libraryUri,
      asyncKind,
      locals,
    );
    if (body == null) return null;
    if (switchCase.isDefault) {
      if (otherwise != null || switchCase != statement.cases.last) return null;
      otherwise = body;
      continue;
    }
    if (otherwise != null) return null;
    if (!_addSwitchCaseBranches(
      branches,
      switchCase,
      body,
      params,
      libraryUri,
      locals,
      const {},
      compileGuard: (expression) => _generatorSwitchValueExpr(
        expression,
        params,
        libraryUri,
        asyncKind,
        locals,
      ),
    )) {
      return null;
    }
  }
  if (otherwise == null || branches.isEmpty) return null;
  return _switchBranchesToConditional(scrutinee, branches, otherwise);
}

Map<String, Object?>? _generatorLoweredSwitchStatementExpr(
  LabeledStatement statement,
  Set<String> params,
  String libraryUri,
  String asyncKind,
  Map<VariableDeclaration, int> locals,
) {
  final parsed = _loweredSwitchStatementParts(
    statement,
    params,
    libraryUri,
    locals,
    const {},
    (expression) => _generatorSwitchValueExpr(
      expression,
      params,
      libraryUri,
      asyncKind,
      locals,
    ),
  );
  if (parsed == null) return null;

  final branches = <_FcbSwitchExpressionBranch>[];
  Map<String, Object?>? otherwise;
  for (final statement in parsed.statements) {
    final ifStatement = _loweredSwitchIfStatement(statement);
    final isDefault = ifStatement == null;
    final caseBody = isDefault
        ? _unwrapSwitchCaseBody(statement)
        : _unwrapSwitchCaseBody(ifStatement.then);
    final body = _generatorSwitchCaseBodyExpr(
      caseBody,
      parsed.label,
      isDefault,
      params,
      libraryUri,
      asyncKind,
      locals,
    );
    if (body == null) return null;
    if (isDefault) {
      if (otherwise != null || statement != parsed.statements.last) {
        return null;
      }
      otherwise = body;
      continue;
    }
    if (otherwise != null) return null;
    final caseBranches = _loweredSwitchCaseBranches(
      ifStatement.condition,
      parsed.scrutineeVariable,
      parsed.constants,
      body,
      params,
      libraryUri,
      locals,
      const {},
      compileGuard: (expression) => _generatorSwitchValueExpr(
        expression,
        params,
        libraryUri,
        asyncKind,
        locals,
      ),
    );
    if (caseBranches == null || caseBranches.isEmpty) return null;
    branches.addAll(caseBranches);
  }
  if (otherwise == null || branches.isEmpty) return null;
  return _switchBranchesToConditional(parsed.scrutinee, branches, otherwise);
}

Map<String, Object?>? _generatorSwitchValueExpr(
  Expression expression,
  Set<String> params,
  String libraryUri,
  String asyncKind,
  Map<VariableDeclaration, int> locals,
) {
  if (asyncKind == 'async_star') {
    return _asyncCompletedExpr(expression, params, libraryUri, locals) ??
        _expr(expression, params, libraryUri, locals);
  }
  return _expr(expression, params, libraryUri, locals);
}

Map<String, Object?>? _generatorSwitchCaseBodyExpr(
  Statement body,
  LabeledStatement? breakLabel,
  bool isDefault,
  Set<String> params,
  String libraryUri,
  String asyncKind,
  Map<VariableDeclaration, int> locals,
) {
  final statements = body is Block ? body.statements : [body];
  if (statements.isEmpty) return null;
  final last = statements.last;
  final hasBreak = last is BreakStatement && last.target == breakLabel;
  if (!hasBreak &&
      !isDefault &&
      breakLabel != null &&
      !_generatorSwitchCaseTerminates(statements)) {
    return null;
  }
  final bodyStatements = hasBreak
      ? statements.take(statements.length - 1).toList(growable: false)
      : statements;
  if (bodyStatements.isEmpty) return null;
  final caseBody = bodyStatements.length == 1
      ? bodyStatements.single
      : Block(bodyStatements);
  return _generatorBodyExpr(caseBody, params, libraryUri, asyncKind, locals);
}

bool _generatorSwitchCaseTerminates(List<Statement> statements) {
  if (statements.length != 1) return false;
  var statement = statements.single;
  while (statement is Block && statement.statements.length == 1) {
    statement = statement.statements.single;
  }
  return statement is ExpressionStatement && statement.expression is Throw;
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
    locals,
    const {},
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
