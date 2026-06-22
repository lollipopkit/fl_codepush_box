part of fcb_kernel_reader;

Map<String, Object?>? _asyncFutureValueSource(
  String libraryUri,
  String qualified,
  List<String> params,
  Set<String> paramsSet,
  FunctionNode function,
) {
  if (function.dartAsyncMarker != AsyncMarker.Async) return null;
  final typeArgs = _futureValueTypeArgs(function.returnType);
  if (typeArgs == null) return null;
  final statement = _returnStatement(function.body);
  final expr =
      _asyncReturnedValueExpr(statement?.expression, paramsSet, libraryUri) ??
      _asyncImmediateAwaitLocalExpr(function.body, paramsSet, libraryUri) ??
      _asyncTryFinallyBodySourceExpr(function.body, paramsSet, libraryUri) ??
      _asyncTryCatchBodySourceExpr(function.body, paramsSet, libraryUri) ??
      _asyncStatementSequenceExpr(function.body, paramsSet, libraryUri) ??
      _asyncIfReturnBodySourceExpr(function.body, paramsSet, libraryUri) ??
      _letBodySourceExpr(function.body, paramsSet, libraryUri) ??
      _tryCatchBodySourceExpr(function.body, paramsSet, libraryUri) ??
      _returnBodySourceExpr(function.body, paramsSet);
  if (expr == null) return null;
  return {
    'name': '$libraryUri::$qualified',
    'params': params,
    'body': {
      'new_object': {
        'constructor': 'dart:async::class:_Future.value',
        'type_args': typeArgs,
        'args': [expr],
      },
    },
    'async_future': true,
    'async_future_value': true,
  };
}

Map<String, Object?>? _syncFutureValueSource(
  String libraryUri,
  String qualified,
  List<String> params,
  Set<String> paramsSet,
  FunctionNode function,
) {
  if (function.dartAsyncMarker != AsyncMarker.Sync) return null;
  final typeArgs = _futureValueTypeArgs(function.returnType);
  if (typeArgs == null) return null;
  final statement = _returnStatement(function.body);
  final expression = statement?.expression;
  if (expression is! StaticInvocation ||
      !_isFutureValueInvocation(expression)) {
    return null;
  }
  if (expression.arguments.positional.length != 1 ||
      expression.arguments.named.isNotEmpty ||
      expression.arguments.types.length > 1) {
    return null;
  }
  final value = _expr(
    expression.arguments.positional.single,
    paramsSet,
    libraryUri,
  );
  if (value == null) return null;
  final returnType = fcbKernelTypeName(function.returnType);
  return {
    'name': '$libraryUri::$qualified',
    if (returnType != null) 'return_type': returnType,
    'params': params,
    'body': {
      'new_object': {
        'constructor': 'dart:async::class:_Future.value',
        'type_args': typeArgs,
        'args': [value],
      },
    },
  };
}

Map<String, Object?>? _asyncReturnedValueExpr(
  Expression? expression,
  Set<String> paramsSet,
  String libraryUri,
) {
  if (expression == null) return null;
  if (expression is AwaitExpression) {
    return _awaitedFutureExpr(expression.operand, paramsSet, libraryUri);
  }
  final completedExpr = _asyncCompletedExpr(expression, paramsSet, libraryUri);
  if (completedExpr != null) return completedExpr;
  return _expr(expression, paramsSet, libraryUri);
}

Map<String, Object?>? _asyncCompletedExpr(
  Expression expression,
  Set<String> paramsSet,
  String libraryUri, [
  Map<VariableDeclaration, int> locals = const {},
]) {
  if (expression is AwaitExpression) {
    return _awaitedFutureExpr(
      expression.operand,
      paramsSet,
      libraryUri,
      locals,
    );
  }
  if (expression is StringConcatenation) {
    if (expression.expressions.isEmpty) return {'string': ''};
    final parts = <Map<String, Object?>>[];
    for (final part in expression.expressions) {
      final compiled =
          _asyncCompletedExpr(part, paramsSet, libraryUri, locals) ??
          _expr(part, paramsSet, libraryUri, locals);
      if (compiled == null) return null;
      parts.add(compiled);
    }
    return {'concat': parts};
  }
  if (expression is ConditionalExpression) {
    final condition = _asyncConditionExpr(
      expression.condition,
      paramsSet,
      libraryUri,
      locals,
    );
    final thenExpr =
        _asyncCompletedExpr(expression.then, paramsSet, libraryUri, locals) ??
        _expr(expression.then, paramsSet, libraryUri, locals);
    final elseExpr =
        _asyncCompletedExpr(
          expression.otherwise,
          paramsSet,
          libraryUri,
          locals,
        ) ??
        _expr(expression.otherwise, paramsSet, libraryUri, locals);
    if (condition == null || thenExpr == null || elseExpr == null) {
      return null;
    }
    return {
      'conditional': {
        'condition': condition,
        'then': thenExpr,
        'else': elseExpr,
      },
    };
  }
  if (expression is VariableSet) {
    final id = locals[expression.variable];
    if (id == null) return null;
    final value =
        _asyncCompletedExpr(expression.value, paramsSet, libraryUri, locals) ??
        _expr(expression.value, paramsSet, libraryUri, locals);
    if (value == null) return null;
    return {
      'set_local': {'id': id, 'value': value},
    };
  }
  return null;
}

Map<String, Object?>? _asyncConditionExpr(
  Expression expression,
  Set<String> paramsSet,
  String libraryUri, [
  Map<VariableDeclaration, int> locals = const {},
]) {
  return _asyncCompletedExpr(expression, paramsSet, libraryUri, locals) ??
      _expr(expression, paramsSet, libraryUri, locals);
}

Map<String, Object?>? _awaitedImmediateFutureValueExpr(
  Expression operand,
  Set<String> paramsSet,
  String libraryUri, [
  Map<VariableDeclaration, int> locals = const {},
]) {
  if (operand is! StaticInvocation ||
      operand.arguments.positional.length != 1 ||
      operand.arguments.named.isNotEmpty ||
      operand.arguments.types.length > 1) {
    return null;
  }
  if (!_isFutureValueInvocation(operand)) return null;
  return _expr(
    operand.arguments.positional.single,
    paramsSet,
    libraryUri,
    locals,
  );
}

Map<String, Object?>? _awaitedFutureExpr(
  Expression operand,
  Set<String> paramsSet,
  String libraryUri, [
  Map<VariableDeclaration, int> locals = const {},
]) {
  final immediate = _awaitedImmediateFutureValueExpr(
    operand,
    paramsSet,
    libraryUri,
    locals,
  );
  if (immediate != null) return immediate;
  final compiled =
      _asyncCompletedExpr(operand, paramsSet, libraryUri, locals) ??
      _expr(operand, paramsSet, libraryUri, locals);
  if (compiled == null) return null;
  return {'await': compiled};
}

Map<String, Object?>? _asyncImmediateAwaitLocalExpr(
  Statement? body,
  Set<String> paramsSet,
  String libraryUri,
) {
  if (body is! Block || body.statements.length < 2) return null;
  final locals = <Map<String, Object?>>[];
  final localIds = <VariableDeclaration, int>{};
  var tailStart = 0;
  for (; tailStart < body.statements.length; tailStart++) {
    final statement = body.statements[tailStart];
    if (statement is! VariableDeclaration || statement.initializer == null) {
      break;
    }
    final initializer = statement.initializer!;
    final value = initializer is AwaitExpression
        ? _awaitedFutureExpr(
            initializer.operand,
            paramsSet,
            libraryUri,
            localIds,
          )
        : _asyncCompletedExpr(initializer, paramsSet, libraryUri, localIds) ??
              _expr(initializer, paramsSet, libraryUri, localIds);
    if (value == null) return null;
    final id = localIds.length;
    localIds[statement] = id;
    locals.add({
      'id': id,
      if (statement.name != null && statement.name!.isNotEmpty)
        'name': statement.name,
      'value': value,
    });
  }
  if (locals.isEmpty) return null;
  final bodyExpr = _asyncTailStatementsSourceExpr(
    body.statements.skip(tailStart).toList(),
    paramsSet,
    libraryUri,
    localIds,
  );
  if (bodyExpr == null) return null;
  return {
    'let': {'locals': locals, 'body': bodyExpr},
  };
}

Map<String, Object?>? _asyncStatementSequenceExpr(
  Statement? body,
  Set<String> paramsSet,
  String libraryUri,
) {
  if (body is! Block || body.statements.isEmpty) return null;
  return _asyncTailStatementsSourceExpr(
    body.statements,
    paramsSet,
    libraryUri,
    const {},
  );
}

Map<String, Object?>? _asyncTailStatementsSourceExpr(
  List<Statement> statements,
  Set<String> paramsSet,
  String libraryUri,
  Map<VariableDeclaration, int> locals,
) {
  if (statements.isEmpty) return {'null': true};
  final first = statements.first;
  final rest = statements.skip(1).toList(growable: false);

  if (first is ExpressionStatement) {
    final head =
        _asyncCompletedExpr(first.expression, paramsSet, libraryUri, locals) ??
        _expr(first.expression, paramsSet, libraryUri, locals);
    final tail = _asyncTailStatementsSourceExpr(
      rest,
      paramsSet,
      libraryUri,
      locals,
    );
    if (head == null || tail == null) return null;
    return {
      'seq': [head, tail],
    };
  }

  if (first is VariableDeclaration && first.initializer != null) {
    final value = first.initializer is AwaitExpression
        ? _awaitedFutureExpr(
            (first.initializer as AwaitExpression).operand,
            paramsSet,
            libraryUri,
            locals,
          )
        : _asyncCompletedExpr(
                first.initializer!,
                paramsSet,
                libraryUri,
                locals,
              ) ??
              _expr(first.initializer!, paramsSet, libraryUri, locals);
    if (value == null) return null;
    final id = locals.length;
    final tail = _asyncTailStatementsSourceExpr(rest, paramsSet, libraryUri, {
      ...locals,
      first: id,
    });
    if (tail == null) return null;
    return {
      'let': {
        'locals': [
          {
            'id': id,
            if (first.name != null && first.name!.isNotEmpty)
              'name': first.name,
            'value': value,
          },
        ],
        'body': tail,
      },
    };
  }

  if (first is IfStatement) {
    final branch = _asyncIfStatementSequenceExpr(
      first,
      rest,
      paramsSet,
      libraryUri,
      locals,
    );
    if (branch != null) return branch;
  }

  if (first is TryFinally) {
    final bodyExpr = _asyncTailStatementsSourceExpr(
      _asyncStatementsFromBody(first.body),
      paramsSet,
      libraryUri,
      locals,
    );
    final finalizerExpr = _asyncTailStatementsSourceExpr(
      _asyncStatementsFromBody(first.finalizer),
      paramsSet,
      libraryUri,
      locals,
    );
    final tail = _asyncTailStatementsSourceExpr(
      rest,
      paramsSet,
      libraryUri,
      locals,
    );
    if (bodyExpr == null || finalizerExpr == null || tail == null) {
      return null;
    }
    return {
      'seq': [
        {
          'try_finally': {'body': bodyExpr, 'finally': finalizerExpr},
        },
        tail,
      ],
    };
  }

  if (first is TryCatch) {
    if (first.catches.length != 1) return null;
    final catchClause = first.catches.single;
    if (catchClause.stackTrace != null || catchClause.exception == null) {
      return null;
    }
    final catchLocalId = locals.length;
    final bodyExpr = _asyncTailStatementsSourceExpr(
      _asyncStatementsFromBody(first.body),
      paramsSet,
      libraryUri,
      locals,
    );
    final catchExpr = _asyncTailStatementsSourceExpr(
      _asyncStatementsFromBody(catchClause.body),
      paramsSet,
      libraryUri,
      {...locals, catchClause.exception!: catchLocalId},
    );
    final tail = _asyncTailStatementsSourceExpr(
      rest,
      paramsSet,
      libraryUri,
      locals,
    );
    if (bodyExpr == null || catchExpr == null || tail == null) {
      return null;
    }
    return {
      'seq': [
        {
          'try_catch': {
            'body': bodyExpr,
            'catch_local': catchLocalId,
            'catch': catchExpr,
          },
        },
        tail,
      ],
    };
  }

  if (first is WhileStatement ||
      first is LabeledStatement && first.body is WhileStatement) {
    final loop = first is LabeledStatement
        ? _asyncWhileExpr(
            first.body as WhileStatement,
            paramsSet,
            libraryUri,
            locals,
            breakLabel: first,
          )
        : _asyncWhileExpr(
            first as WhileStatement,
            paramsSet,
            libraryUri,
            locals,
          );
    final tail = _asyncTailStatementsSourceExpr(
      rest,
      paramsSet,
      libraryUri,
      locals,
    );
    if (loop == null || tail == null) return null;
    return {
      'seq': [loop, tail],
    };
  }

  if (first is DoStatement ||
      first is LabeledStatement && first.body is DoStatement) {
    final loop = first is LabeledStatement
        ? _asyncDoExpr(
            first.body as DoStatement,
            paramsSet,
            libraryUri,
            locals,
            breakLabel: first,
          )
        : _asyncDoExpr(first as DoStatement, paramsSet, libraryUri, locals);
    final tail = _asyncTailStatementsSourceExpr(
      rest,
      paramsSet,
      libraryUri,
      locals,
    );
    if (loop == null || tail == null) return null;
    return {
      'seq': [loop, tail],
    };
  }

  if (first is ForStatement ||
      first is LabeledStatement && first.body is ForStatement) {
    final loop = first is LabeledStatement
        ? _asyncForExpr(
            first.body as ForStatement,
            paramsSet,
            libraryUri,
            locals,
            breakLabel: first,
          )
        : _asyncForExpr(first as ForStatement, paramsSet, libraryUri, locals);
    final tail = _asyncTailStatementsSourceExpr(
      rest,
      paramsSet,
      libraryUri,
      locals,
    );
    if (loop == null || tail == null) return null;
    return {
      'seq': [loop, tail],
    };
  }

  if (statements.length == 1) {
    if (first is ReturnStatement && first.expression == null) {
      return {'null': true};
    }
    if (first is ReturnStatement && first.expression != null) {
      return _asyncCompletedExpr(
            first.expression!,
            paramsSet,
            libraryUri,
            locals,
          ) ??
          _expr(first.expression!, paramsSet, libraryUri, locals);
    }
    return _asyncIfReturnBodySourceExpr(first, paramsSet, libraryUri, locals);
  }

  if (statements.length == 2) {
    return _asyncIfReturnBodySourceExpr(
      Block(statements),
      paramsSet,
      libraryUri,
      locals,
    );
  }

  final guardedReturn = _asyncIfReturnBodySourceExpr(
    Block(statements),
    paramsSet,
    libraryUri,
    locals,
  );
  if (guardedReturn != null) return guardedReturn;

  return null;
}

Map<String, Object?>? _asyncIfStatementSequenceExpr(
  IfStatement statement,
  List<Statement> rest,
  Set<String> paramsSet,
  String libraryUri,
  Map<VariableDeclaration, int> locals,
) {
  final condition = _asyncConditionExpr(
    statement.condition,
    paramsSet,
    libraryUri,
    locals,
  );
  if (condition == null) return null;
  final thenStatements = [..._asyncStatementsFromBody(statement.then), ...rest];
  final elseStatements = [
    if (statement.otherwise != null)
      ..._asyncStatementsFromBody(statement.otherwise!),
    ...rest,
  ];
  final thenExpr = _asyncTailStatementsSourceExpr(
    thenStatements,
    paramsSet,
    libraryUri,
    locals,
  );
  final elseExpr = _asyncTailStatementsSourceExpr(
    elseStatements,
    paramsSet,
    libraryUri,
    locals,
  );
  if (thenExpr == null || elseExpr == null) return null;
  return {
    'conditional': {'condition': condition, 'then': thenExpr, 'else': elseExpr},
  };
}

List<Statement> _asyncStatementsFromBody(Statement statement) {
  return statement is Block ? statement.statements : [statement];
}

Map<String, Object?>? _asyncIfReturnBodySourceExpr(
  Statement? body,
  Set<String> paramsSet,
  String libraryUri, [
  Map<VariableDeclaration, int> locals = const {},
]) {
  final ifStatement = body is IfStatement
      ? body
      : body is Block && body.statements.length == 1
      ? body.statements.single
      : null;
  if (ifStatement is IfStatement) {
    return _asyncIfReturnExpr(ifStatement, paramsSet, libraryUri, locals);
  }
  if (body is! Block || body.statements.length < 2) return null;
  final first = body.statements.first;
  if (first is! IfStatement || first.otherwise != null) return null;
  final condition = _asyncConditionExpr(
    first.condition,
    paramsSet,
    libraryUri,
    locals,
  );
  final thenExpr = _asyncSingleReturnExpr(
    first.then,
    paramsSet,
    libraryUri,
    locals,
  );
  final elseExpr = _asyncTailStatementsSourceExpr(
    body.statements.skip(1).toList(growable: false),
    paramsSet,
    libraryUri,
    locals,
  );
  if (condition == null || thenExpr == null || elseExpr == null) return null;
  return {
    'conditional': {'condition': condition, 'then': thenExpr, 'else': elseExpr},
  };
}

Map<String, Object?>? _asyncIfReturnExpr(
  IfStatement statement,
  Set<String> paramsSet,
  String libraryUri,
  Map<VariableDeclaration, int> locals,
) {
  final otherwise = statement.otherwise;
  if (otherwise == null) return null;
  final condition = _asyncConditionExpr(
    statement.condition,
    paramsSet,
    libraryUri,
    locals,
  );
  final thenExpr = _asyncSingleReturnExpr(
    statement.then,
    paramsSet,
    libraryUri,
    locals,
  );
  final elseExpr = _asyncSingleReturnExpr(
    otherwise,
    paramsSet,
    libraryUri,
    locals,
  );
  if (condition == null || thenExpr == null || elseExpr == null) return null;
  return {
    'conditional': {'condition': condition, 'then': thenExpr, 'else': elseExpr},
  };
}

Map<String, Object?>? _asyncTryCatchBodySourceExpr(
  Statement? body,
  Set<String> paramsSet,
  String libraryUri,
) {
  final tryCatch = body is TryCatch
      ? body
      : body is Block && body.statements.length == 1
      ? body.statements.single
      : null;
  if (tryCatch is! TryCatch || tryCatch.catches.length != 1) return null;
  final catchClause = tryCatch.catches.single;
  if (catchClause.stackTrace != null || catchClause.exception == null) {
    return null;
  }

  final bodyExpr = _asyncSingleReturnExpr(tryCatch.body, paramsSet, libraryUri);
  final catchLocalId = 0;
  final catchExpr = _asyncSingleReturnExpr(
    catchClause.body,
    paramsSet,
    libraryUri,
    {catchClause.exception!: catchLocalId},
  );
  if (bodyExpr == null || catchExpr == null) return null;
  return {
    'try_catch': {
      'body': bodyExpr,
      'catch_local': catchLocalId,
      'catch': catchExpr,
    },
  };
}

Map<String, Object?>? _asyncTryFinallyBodySourceExpr(
  Statement? body,
  Set<String> paramsSet,
  String libraryUri,
) {
  final tryFinally = body is TryFinally
      ? body
      : body is Block && body.statements.length == 1
      ? body.statements.single
      : null;
  if (tryFinally is! TryFinally) return null;
  final bodyExpr =
      _asyncTryCatchBodySourceExpr(tryFinally.body, paramsSet, libraryUri) ??
      _asyncSingleReturnExpr(tryFinally.body, paramsSet, libraryUri);
  final finalizer = _asyncTailStatementsSourceExpr(
    tryFinally.finalizer is Block
        ? (tryFinally.finalizer as Block).statements
        : [tryFinally.finalizer],
    paramsSet,
    libraryUri,
    const {},
  );
  if (bodyExpr == null || finalizer == null) return null;
  return {
    'try_finally': {'body': bodyExpr, 'finally': finalizer, 'value': true},
  };
}

Map<String, Object?>? _asyncSingleReturnExpr(
  Statement body,
  Set<String> paramsSet,
  String libraryUri, [
  Map<VariableDeclaration, int> locals = const {},
]) {
  final ifExpr = _asyncIfReturnBodySourceExpr(
    body,
    paramsSet,
    libraryUri,
    locals,
  );
  if (ifExpr != null) return ifExpr;
  if (body is Block) {
    final blockExpr = _asyncTailStatementsSourceExpr(
      body.statements,
      paramsSet,
      libraryUri,
      locals,
    );
    if (blockExpr != null) return blockExpr;
  }
  final statement = _returnStatement(body);
  final expression = statement?.expression;
  if (expression == null) return null;
  return _asyncCompletedExpr(expression, paramsSet, libraryUri, locals) ??
      _expr(expression, paramsSet, libraryUri, locals);
}

bool _isFutureValueInvocation(StaticInvocation invocation) {
  try {
    return invocation.target.name.text == 'value' &&
        invocation.target.enclosingClass?.name == 'Future' &&
        invocation.target.enclosingLibrary.importUri.toString() == 'dart:async';
  } catch (_) {
    return _nodeText(invocation).contains('Future::value');
  }
}

List<String>? _futureValueTypeArgs(DartType returnType) {
  if (returnType is InterfaceType) {
    try {
      final klass = returnType.classNode;
      if (klass.name != 'Future' ||
          klass.enclosingLibrary.importUri.toString() != 'dart:async' ||
          returnType.typeArguments.length != 1) {
        return null;
      }
      final valueType = returnType.typeArguments.single;
      if (fcbUnsupportedRuntimeTypeReason(valueType) != null) return null;
      final typeName = fcbKernelTypeName(valueType);
      if (typeName == null || typeName.isEmpty) return null;
      return [typeName];
    } catch (_) {
      // Fall back to text parsing when the Kernel reference is not bound.
    }
  }
  var text = returnType.toString();
  if (text.startsWith('InterfaceType(') && text.endsWith(')')) {
    text = text.substring('InterfaceType('.length, text.length - 1);
  }
  const prefix = 'Future<';
  if (!text.startsWith(prefix) || !text.endsWith('>')) return null;
  final typeName = text.substring(prefix.length, text.length - 1).trim();
  final fallback = _futureValueFallbackTypeArg(typeName);
  return fallback == null ? null : [fallback];
}

String? _futureValueFallbackTypeArg(String typeName) {
  final text = typeName.trim();
  if (text.isEmpty) return null;
  if (RegExp(r'\bFunction\b').hasMatch(text)) return null;
  if (text.startsWith('(') || text.contains('RecordType(')) return null;
  return fcbNormalizeSimpleTypeName(text) ?? text;
}
