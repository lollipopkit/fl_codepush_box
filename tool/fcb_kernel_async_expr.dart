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
      _asyncTryCatchBodySourceExpr(function.body, paramsSet, libraryUri) ??
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
    'async_future_value': true,
  };
}

Map<String, Object?>? _asyncReturnedValueExpr(
  Expression? expression,
  Set<String> paramsSet,
  String libraryUri,
) {
  if (expression == null) return null;
  if (expression is AwaitExpression) {
    return _awaitedImmediateFutureValueExpr(
      expression.operand,
      paramsSet,
      libraryUri,
    );
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
    return _awaitedImmediateFutureValueExpr(
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
        ? _awaitedImmediateFutureValueExpr(
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

Map<String, Object?>? _asyncTailStatementsSourceExpr(
  List<Statement> statements,
  Set<String> paramsSet,
  String libraryUri,
  Map<VariableDeclaration, int> locals,
) {
  if (statements.length == 1) {
    final only = statements.single;
    if (only is ReturnStatement && only.expression != null) {
      return _asyncCompletedExpr(
            only.expression!,
            paramsSet,
            libraryUri,
            locals,
          ) ??
          _expr(only.expression!, paramsSet, libraryUri, locals);
    }
    return _asyncIfReturnBodySourceExpr(only, paramsSet, libraryUri, locals);
  }
  if (statements.length != 2) return null;
  return _asyncIfReturnBodySourceExpr(
    Block(statements),
    paramsSet,
    libraryUri,
    locals,
  );
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
  if (body is! Block || body.statements.length != 2) return null;
  final first = body.statements.first;
  final second = body.statements.last;
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
  final elseExpr = _asyncSingleReturnExpr(
    second,
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

  final bodyExpr =
      _asyncImmediateAwaitLocalExpr(tryCatch.body, paramsSet, libraryUri) ??
      _asyncIfReturnBodySourceExpr(tryCatch.body, paramsSet, libraryUri) ??
      _asyncSingleReturnExpr(tryCatch.body, paramsSet, libraryUri);
  final catchLocalId = 0;
  final catchExpr = _singleReturnExpr(catchClause.body, paramsSet, libraryUri, {
    catchClause.exception!: catchLocalId,
  });
  if (bodyExpr == null || catchExpr == null) return null;
  return {
    'try_catch': {
      'body': bodyExpr,
      'catch_local': catchLocalId,
      'catch': catchExpr,
    },
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
  var text = returnType.toString();
  if (text.startsWith('InterfaceType(') && text.endsWith(')')) {
    text = text.substring('InterfaceType('.length, text.length - 1);
  }
  const prefix = 'Future<';
  if (!text.startsWith(prefix) || !text.endsWith('>')) return null;
  final typeName = text.substring(prefix.length, text.length - 1).trim();
  if (typeName.isEmpty || typeName.contains(',')) return null;
  return [typeName];
}
