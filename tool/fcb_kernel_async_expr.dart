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
      _asyncStatementSequenceExpr(function.body, paramsSet, libraryUri) ??
      _asyncTryFinallyBodySourceExpr(function.body, paramsSet, libraryUri) ??
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
    'async_future': true,
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

  return null;
}

Map<String, Object?>? _asyncWhileExpr(
  WhileStatement statement,
  Set<String> paramsSet,
  String libraryUri,
  Map<VariableDeclaration, int> locals, {
  LabeledStatement? breakLabel,
}) {
  final condition = _asyncConditionExpr(
    statement.condition,
    paramsSet,
    libraryUri,
    locals,
  );
  final bodyLabel = statement.body is LabeledStatement
      ? statement.body as LabeledStatement
      : null;
  final effectiveBreakLabel = bodyLabel ?? breakLabel;
  final bodyNode = bodyLabel?.body ?? statement.body;
  final bodyStatements = bodyNode is Block ? bodyNode.statements : [bodyNode];
  final body =
      _asyncContinuableWhileBodyExpr(
        bodyStatements,
        effectiveBreakLabel,
        paramsSet,
        libraryUri,
        locals,
      ) ??
      _asyncBreakableWhileBodyExpr(
        bodyStatements,
        effectiveBreakLabel,
        paramsSet,
        libraryUri,
        locals,
      ) ??
      _asyncTailStatementsSourceExpr(
        bodyStatements,
        paramsSet,
        libraryUri,
        locals,
      );
  if (condition == null || body == null) return null;
  final beforeBreak = body.remove('before_break');
  final breakCondition = body.remove('break_condition');
  final beforeContinue = body.remove('before_continue');
  final continueCondition = body.remove('continue_condition');
  final continueBody = body.remove('continue_body');
  return {
    'while_loop': {
      'condition': condition,
      if (beforeContinue != null) 'before_continue': beforeContinue,
      if (continueCondition != null) 'continue_condition': continueCondition,
      if (continueBody != null) 'continue_body': continueBody,
      if (beforeBreak != null) 'before_break': beforeBreak,
      if (breakCondition != null) 'break_condition': breakCondition,
      'body': body,
    },
  };
}

Map<String, Object?>? _asyncContinuableWhileBodyExpr(
  List<Statement> statements,
  LabeledStatement? continueLabel,
  Set<String> paramsSet,
  String libraryUri,
  Map<VariableDeclaration, int> locals,
) {
  if (continueLabel == null) return null;
  final continueIndex = statements.indexWhere(
    (statement) =>
        statement is IfStatement &&
        statement.otherwise == null &&
        _continueBranchPrefix(statement.then, continueLabel) != null,
  );
  if (continueIndex < 0) return null;
  final continueStatement = statements[continueIndex] as IfStatement;
  final continuePrefix = _continueBranchPrefix(
    continueStatement.then,
    continueLabel,
  );
  if (continuePrefix == null || continuePrefix.isEmpty) return null;
  final condition = _asyncConditionExpr(
    continueStatement.condition,
    paramsSet,
    libraryUri,
    locals,
  );
  final beforeContinue = statements.take(continueIndex).toList(growable: false);
  final tail = statements.skip(continueIndex + 1).toList(growable: false);
  if (condition == null || tail.isEmpty) return null;
  final beforeContinueBody = beforeContinue.isEmpty
      ? null
      : _asyncTailStatementsSourceExpr(
          beforeContinue,
          paramsSet,
          libraryUri,
          locals,
        );
  final continueBody = _asyncTailStatementsSourceExpr(
    continuePrefix,
    paramsSet,
    libraryUri,
    locals,
  );
  final body = _asyncTailStatementsSourceExpr(
    tail,
    paramsSet,
    libraryUri,
    locals,
  );
  if (beforeContinue.isNotEmpty && beforeContinueBody == null) return null;
  if (continueBody == null || body == null) return null;
  return {
    if (beforeContinueBody != null) 'before_continue': beforeContinueBody,
    'continue_condition': condition,
    'continue_body': continueBody,
    ...body,
  };
}

Map<String, Object?>? _asyncBreakableWhileBodyExpr(
  List<Statement> statements,
  LabeledStatement? breakLabel,
  Set<String> paramsSet,
  String libraryUri,
  Map<VariableDeclaration, int> locals,
) {
  final breakIndex = statements.indexWhere(
    (statement) =>
        statement is IfStatement &&
        statement.otherwise == null &&
        _asyncIsBreakToLoop(statement.then, breakLabel),
  );
  if (breakIndex < 0) {
    return _asyncTailStatementsSourceExpr(
      statements,
      paramsSet,
      libraryUri,
      locals,
    );
  }
  final breakStatement = statements[breakIndex] as IfStatement;
  final condition = _asyncConditionExpr(
    breakStatement.condition,
    paramsSet,
    libraryUri,
    locals,
  );
  final beforeBreak = statements.take(breakIndex).toList(growable: false);
  final tail = statements.skip(breakIndex + 1).toList(growable: false);
  if (condition == null) return null;
  final beforeBreakBody = beforeBreak.isEmpty
      ? null
      : _asyncTailStatementsSourceExpr(
          beforeBreak,
          paramsSet,
          libraryUri,
          locals,
        );
  final body = tail.isEmpty
      ? {'null': true}
      : _asyncTailStatementsSourceExpr(tail, paramsSet, libraryUri, locals);
  if (beforeBreak.isNotEmpty && beforeBreakBody == null) return null;
  if (body == null) return null;
  return {
    if (beforeBreakBody != null) 'before_break': beforeBreakBody,
    'break_condition': condition,
    ...body,
  };
}

bool _asyncIsBreakToLoop(Statement statement, LabeledStatement? label) {
  if (label != null) return _isBreakToLabel(statement, label);
  final unwrapped = statement is Block && statement.statements.length == 1
      ? statement.statements.single
      : statement;
  return unwrapped is BreakStatement;
}

Map<String, Object?>? _asyncForExpr(
  ForStatement statement,
  Set<String> paramsSet,
  String libraryUri,
  Map<VariableDeclaration, int> outerLocals, {
  LabeledStatement? breakLabel,
}) {
  if (statement.condition == null) return null;
  final localIds = Map<VariableDeclaration, int>.of(outerLocals);
  final localEntries = <Map<String, Object?>>[];
  for (final variable in statement.variableInitializations) {
    if (variable is! VariableDeclaration || variable.initializer == null) {
      return null;
    }
    final value =
        _asyncCompletedExpr(
          variable.initializer!,
          paramsSet,
          libraryUri,
          localIds,
        ) ??
        _expr(variable.initializer!, paramsSet, libraryUri, localIds);
    if (value == null) return null;
    final id = localIds.length;
    localIds[variable] = id;
    localEntries.add({
      'id': id,
      if (variable.name != null && variable.name!.isNotEmpty)
        'name': variable.name,
      'value': value,
    });
  }
  final condition = _asyncConditionExpr(
    statement.condition!,
    paramsSet,
    libraryUri,
    localIds,
  );
  final update = statement.updates.isEmpty
      ? null
      : _asyncUpdateExpr(statement.updates, paramsSet, libraryUri, localIds);
  final body = _asyncForBodyExpr(
    statement.body,
    update,
    breakLabel,
    paramsSet,
    libraryUri,
    localIds,
  );
  if (condition == null || body == null) return null;
  final beforeBreak = body.remove('before_break');
  final breakCondition = body.remove('break_condition');
  final beforeContinue = body.remove('before_continue');
  final continueCondition = body.remove('continue_condition');
  final continueBody = body.remove('continue_body');
  final whileLoop = {
    'while_loop': {
      'condition': condition,
      if (beforeContinue != null) 'before_continue': beforeContinue,
      if (continueCondition != null) 'continue_condition': continueCondition,
      if (continueBody != null) 'continue_body': continueBody,
      if (beforeBreak != null) 'before_break': beforeBreak,
      if (breakCondition != null) 'break_condition': breakCondition,
      'body': body,
    },
  };
  if (localEntries.isEmpty) return whileLoop;
  return {
    'let': {'locals': localEntries, 'body': whileLoop},
  };
}

Map<String, Object?>? _asyncForBodyExpr(
  Statement statement,
  Map<String, Object?>? update,
  LabeledStatement? breakLabel,
  Set<String> paramsSet,
  String libraryUri,
  Map<VariableDeclaration, int> locals,
) {
  final bodyLabel = statement is LabeledStatement ? statement : null;
  final bodyNode = bodyLabel?.body ?? statement;
  final bodyStatements = bodyNode is Block ? bodyNode.statements : [bodyNode];
  final body = bodyLabel == null
      ? null
      : breakLabel == null
      ? _asyncContinuableForBodyExpr(
          bodyStatements,
          bodyLabel,
          paramsSet,
          libraryUri,
          locals,
        )
      : _asyncContinuableBreakableForBodyExpr(
              bodyStatements,
              bodyLabel,
              breakLabel,
              paramsSet,
              libraryUri,
              locals,
            ) ??
            _asyncContinuableForBodyExpr(
              bodyStatements,
              bodyLabel,
              paramsSet,
              libraryUri,
              locals,
            ) ??
            _asyncTailStatementsSourceExpr(
              bodyStatements,
              paramsSet,
              libraryUri,
              locals,
            );
  if (body == null && breakLabel != null) {
    final breakBody = _asyncBreakableWhileBodyExpr(
      bodyStatements,
      breakLabel,
      paramsSet,
      libraryUri,
      locals,
    );
    if (breakBody != null) {
      final beforeBreak = breakBody.remove('before_break');
      final breakCondition = breakBody.remove('break_condition');
      return {
        if (beforeBreak != null) 'before_break': beforeBreak,
        if (breakCondition != null) 'break_condition': breakCondition,
        ..._appendAsyncSeq(breakBody, update),
      };
    }
  }
  if (body == null) {
    final normalBody = _asyncTailStatementsSourceExpr(
      bodyStatements,
      paramsSet,
      libraryUri,
      locals,
    );
    if (normalBody == null) return null;
    return _appendAsyncSeq(normalBody, update);
  }
  final beforeBreak = body.remove('before_break');
  final breakCondition = body.remove('break_condition');
  final beforeContinue = body.remove('before_continue');
  final continueCondition = body.remove('continue_condition');
  final continueBody = body.remove('continue_body');
  final appendedBody = _appendAsyncSeq(body, update);
  if (continueBody == null) return appendedBody;
  if (continueBody is! Map) return null;
  return {
    if (beforeContinue != null) 'before_continue': beforeContinue,
    if (continueCondition != null) 'continue_condition': continueCondition,
    'continue_body': _appendAsyncSeq(
      continueBody.cast<String, Object?>(),
      update,
    ),
    if (beforeBreak != null) 'before_break': beforeBreak,
    if (breakCondition != null) 'break_condition': breakCondition,
    ...appendedBody,
  };
}

Map<String, Object?>? _asyncContinuableBreakableForBodyExpr(
  List<Statement> statements,
  LabeledStatement continueLabel,
  LabeledStatement breakLabel,
  Set<String> paramsSet,
  String libraryUri,
  Map<VariableDeclaration, int> locals,
) {
  final continueIndex = statements.indexWhere(
    (statement) =>
        statement is IfStatement &&
        statement.otherwise == null &&
        _continueBranchPrefix(statement.then, continueLabel) != null,
  );
  if (continueIndex < 0) return null;
  final continueStatement = statements[continueIndex] as IfStatement;
  final continuePrefix = _continueBranchPrefix(
    continueStatement.then,
    continueLabel,
  );
  if (continuePrefix == null) return null;
  final tail = statements.skip(continueIndex + 1).toList(growable: false);
  final breakIndex = tail.indexWhere(
    (statement) =>
        statement is IfStatement &&
        statement.otherwise == null &&
        _isBreakToLabel(statement.then, breakLabel),
  );
  if (breakIndex < 0) return null;
  final continueCondition = _asyncConditionExpr(
    continueStatement.condition,
    paramsSet,
    libraryUri,
    locals,
  );
  final breakStatement = tail[breakIndex] as IfStatement;
  final breakCondition = _asyncConditionExpr(
    breakStatement.condition,
    paramsSet,
    libraryUri,
    locals,
  );
  if (continueCondition == null || breakCondition == null) return null;
  final beforeContinue = statements.take(continueIndex).toList(growable: false);
  final beforeContinueBody = beforeContinue.isEmpty
      ? null
      : _asyncTailStatementsSourceExpr(
          beforeContinue,
          paramsSet,
          libraryUri,
          locals,
        );
  if (beforeContinue.isNotEmpty && beforeContinueBody == null) return null;
  final continueBody = continuePrefix.isEmpty
      ? {'null': true}
      : _asyncTailStatementsSourceExpr(
          continuePrefix,
          paramsSet,
          libraryUri,
          locals,
        );
  final beforeBreak = tail.take(breakIndex).toList(growable: false);
  final beforeBreakBody = beforeBreak.isEmpty
      ? null
      : _asyncTailStatementsSourceExpr(
          beforeBreak,
          paramsSet,
          libraryUri,
          locals,
        );
  if (beforeBreak.isNotEmpty && beforeBreakBody == null) return null;
  final afterBreak = tail.skip(breakIndex + 1).toList(growable: false);
  final body = afterBreak.isEmpty
      ? {'null': true}
      : _asyncTailStatementsSourceExpr(
          afterBreak,
          paramsSet,
          libraryUri,
          locals,
        );
  if (continueBody == null || body == null) return null;
  return {
    if (beforeContinueBody != null) 'before_continue': beforeContinueBody,
    'continue_condition': continueCondition,
    'continue_body': continueBody,
    if (beforeBreakBody != null) 'before_break': beforeBreakBody,
    'break_condition': breakCondition,
    ...body,
  };
}

Map<String, Object?>? _asyncContinuableForBodyExpr(
  List<Statement> statements,
  LabeledStatement continueLabel,
  Set<String> paramsSet,
  String libraryUri,
  Map<VariableDeclaration, int> locals,
) {
  final continueIndex = statements.indexWhere(
    (statement) =>
        statement is IfStatement &&
        statement.otherwise == null &&
        _continueBranchPrefix(statement.then, continueLabel) != null,
  );
  if (continueIndex < 0) return null;
  final continueStatement = statements[continueIndex] as IfStatement;
  final continuePrefix = _continueBranchPrefix(
    continueStatement.then,
    continueLabel,
  );
  if (continuePrefix == null) return null;
  final condition = _asyncConditionExpr(
    continueStatement.condition,
    paramsSet,
    libraryUri,
    locals,
  );
  final beforeContinue = statements.take(continueIndex).toList(growable: false);
  final tail = statements.skip(continueIndex + 1).toList(growable: false);
  if (condition == null || tail.isEmpty) return null;
  final beforeContinueBody = beforeContinue.isEmpty
      ? null
      : _asyncTailStatementsSourceExpr(
          beforeContinue,
          paramsSet,
          libraryUri,
          locals,
        );
  final continueBody = continuePrefix.isEmpty
      ? {'null': true}
      : _asyncTailStatementsSourceExpr(
          continuePrefix,
          paramsSet,
          libraryUri,
          locals,
        );
  final body = _asyncTailStatementsSourceExpr(
    tail,
    paramsSet,
    libraryUri,
    locals,
  );
  if (beforeContinue.isNotEmpty && beforeContinueBody == null) return null;
  if (continueBody == null || body == null) return null;
  return {
    if (beforeContinueBody != null) 'before_continue': beforeContinueBody,
    'continue_condition': condition,
    'continue_body': continueBody,
    ...body,
  };
}

Map<String, Object?>? _asyncUpdateExpr(
  List<Expression> updates,
  Set<String> paramsSet,
  String libraryUri,
  Map<VariableDeclaration, int> locals,
) {
  final items = <Map<String, Object?>>[];
  for (final update in updates) {
    final item =
        _asyncCompletedExpr(update, paramsSet, libraryUri, locals) ??
        _expr(update, paramsSet, libraryUri, locals);
    if (item == null) return null;
    items.add(item);
  }
  if (items.isEmpty) return null;
  return items.length == 1 ? items.single : {'seq': items};
}

Map<String, Object?> _appendAsyncSeq(
  Map<String, Object?> body,
  Map<String, Object?>? update,
) {
  if (update == null) return body;
  return {
    'seq': [..._asyncSeqItems(body), ..._asyncSeqItems(update)],
  };
}

List<Map<String, Object?>> _asyncSeqItems(Map<String, Object?> expr) {
  final seq = expr['seq'];
  if (seq is List) {
    return [
      for (final item in seq)
        if (item is Map) item.cast<String, Object?>(),
    ];
  }
  return [expr];
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
  final bodyExpr = _asyncSingleReturnExpr(
    tryFinally.body,
    paramsSet,
    libraryUri,
  );
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
