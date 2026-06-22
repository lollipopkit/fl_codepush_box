part of fcb_kernel_reader;

Map<String, Object?>? _switchReturnStatementExpr(
  Statement statement,
  Set<String> params,
  String libraryUri,
  Map<VariableDeclaration, int> locals,
  Map<VariableDeclaration, FunctionExpression> closures,
) {
  final switchStatement = _switchStatementFromStatement(statement);
  if (switchStatement == null) return null;
  return _switchStatementExpr(
    switchStatement,
    params,
    libraryUri,
    locals,
    closures,
    (expression) => _expr(expression, params, libraryUri, locals, closures),
  );
}

Map<String, Object?>? _asyncSwitchReturnStatementExpr(
  Statement statement,
  Set<String> params,
  String libraryUri,
  Map<VariableDeclaration, int> locals,
) {
  final switchStatement = _switchStatementFromStatement(statement);
  if (switchStatement == null) return null;
  return _asyncSwitchStatementExpr(
    switchStatement,
    params,
    libraryUri,
    locals,
    (expression) =>
        _asyncCompletedExpr(expression, params, libraryUri, locals) ??
        _expr(expression, params, libraryUri, locals),
  );
}

Map<String, Object?>? _switchAssignStatementExpr(
  Statement statement,
  Set<String> params,
  String libraryUri,
  Map<VariableDeclaration, int> locals,
  Map<VariableDeclaration, FunctionExpression> closures,
  Map<String, Object?>? Function(Expression expression) compileValue,
) {
  final parsed = _switchStatementAndBreakLabel(statement);
  if (parsed == null) return null;
  return _switchAssignExpr(
    parsed.statement,
    parsed.breakLabel,
    params,
    libraryUri,
    locals,
    closures,
    compileValue,
  );
}

Map<String, Object?>? _asyncSwitchAssignStatementExpr(
  Statement statement,
  Set<String> params,
  String libraryUri,
  Map<VariableDeclaration, int> locals,
) {
  return _switchAssignStatementExpr(
    statement,
    params,
    libraryUri,
    locals,
    const {},
    (expression) =>
        _asyncCompletedExpr(expression, params, libraryUri, locals) ??
        _expr(expression, params, libraryUri, locals),
  );
}

SwitchStatement? _switchStatementFromStatement(Statement statement) {
  return _switchStatementAndBreakLabel(statement)?.statement;
}

_FcbSwitchStatementWithLabel? _switchStatementAndBreakLabel(
  Statement statement,
) {
  if (statement is SwitchStatement) {
    return _FcbSwitchStatementWithLabel(statement, null);
  }
  if (statement is LabeledStatement && statement.body is SwitchStatement) {
    return _FcbSwitchStatementWithLabel(
      statement.body as SwitchStatement,
      statement,
    );
  }
  return null;
}

Map<String, Object?>? _switchReturnBodySourceExpr(
  Statement? body,
  Set<String> params,
  String libraryUri,
) {
  final switchStatement = body is Block && body.statements.length == 1
      ? body.statements.single
      : body;
  if (switchStatement == null) return null;
  return _switchReturnStatementExpr(
    switchStatement,
    params,
    libraryUri,
    const {},
    const {},
  );
}

Map<String, Object?>? _switchStatementExpr(
  SwitchStatement statement,
  Set<String> params,
  String libraryUri,
  Map<VariableDeclaration, int> locals,
  Map<VariableDeclaration, FunctionExpression> closures,
  Map<String, Object?>? Function(Expression expression) compileReturn,
) {
  if (!statement.hasDefault || statement.cases.length < 2) return null;
  final scrutinee = _expr(
    statement.expression,
    params,
    libraryUri,
    locals,
    closures,
  );
  if (scrutinee == null) return null;

  final branches = <_FcbSwitchExpressionBranch>[];
  Map<String, Object?>? otherwise;
  for (final switchCase in statement.cases) {
    final body =
        _switchCaseSequenceExpr(
          switchCase.body,
          params,
          libraryUri,
          locals,
          closures,
        ) ??
        _switchCaseReturnExpr(switchCase.body, compileReturn);
    if (body == null) return null;
    if (switchCase.isDefault) {
      if (otherwise != null || switchCase != statement.cases.last) return null;
      otherwise = body;
      continue;
    }
    if (otherwise != null || switchCase.expressions.length != 1) return null;
    final constant = _switchConstantExpr(
      switchCase.expressions.single,
      const {},
      params,
      libraryUri,
      locals,
      closures,
    );
    if (constant == null) return null;
    branches.add(_FcbSwitchExpressionBranch(constant, body));
  }
  if (otherwise == null || branches.isEmpty) return null;
  return _switchBranchesToConditional(scrutinee, branches, otherwise);
}

Map<String, Object?>? _asyncSwitchStatementExpr(
  SwitchStatement statement,
  Set<String> params,
  String libraryUri,
  Map<VariableDeclaration, int> locals,
  Map<String, Object?>? Function(Expression expression) compileReturn,
) {
  if (!statement.hasDefault || statement.cases.length < 2) return null;
  final scrutinee = _expr(statement.expression, params, libraryUri, locals);
  if (scrutinee == null) return null;

  final branches = <_FcbSwitchExpressionBranch>[];
  Map<String, Object?>? otherwise;
  for (final switchCase in statement.cases) {
    final body =
        _asyncSwitchCaseSequenceExpr(
          switchCase.body,
          params,
          libraryUri,
          locals,
        ) ??
        _switchCaseReturnExpr(switchCase.body, compileReturn);
    if (body == null) return null;
    if (switchCase.isDefault) {
      if (otherwise != null || switchCase != statement.cases.last) return null;
      otherwise = body;
      continue;
    }
    if (otherwise != null || switchCase.expressions.length != 1) return null;
    final constant = _switchConstantExpr(
      switchCase.expressions.single,
      const {},
      params,
      libraryUri,
      locals,
      const {},
    );
    if (constant == null) return null;
    branches.add(_FcbSwitchExpressionBranch(constant, body));
  }
  if (otherwise == null || branches.isEmpty) return null;
  return _switchBranchesToConditional(scrutinee, branches, otherwise);
}

Map<String, Object?>? _switchCaseSequenceExpr(
  Statement body,
  Set<String> params,
  String libraryUri,
  Map<VariableDeclaration, int> locals,
  Map<VariableDeclaration, FunctionExpression> closures,
) {
  final statements = body is Block ? body.statements : [body];
  if (statements.length < 2) return null;
  return _tailStatementsSourceExpr(
    statements,
    params,
    libraryUri,
    locals,
    closures,
  );
}

Map<String, Object?>? _asyncSwitchCaseSequenceExpr(
  Statement body,
  Set<String> params,
  String libraryUri,
  Map<VariableDeclaration, int> locals,
) {
  final statements = body is Block ? body.statements : [body];
  if (statements.length < 2) return null;
  return _asyncTailStatementsSourceExpr(statements, params, libraryUri, locals);
}

Map<String, Object?>? _switchAssignExpr(
  SwitchStatement statement,
  LabeledStatement? breakLabel,
  Set<String> params,
  String libraryUri,
  Map<VariableDeclaration, int> locals,
  Map<VariableDeclaration, FunctionExpression> closures,
  Map<String, Object?>? Function(Expression expression) compileValue,
) {
  if (!statement.hasDefault || statement.cases.length < 2) return null;
  final scrutinee = _expr(
    statement.expression,
    params,
    libraryUri,
    locals,
    closures,
  );
  if (scrutinee == null) return null;

  VariableDeclaration? target;
  int? targetLocal;
  final branches = <_FcbSwitchExpressionBranch>[];
  Map<String, Object?>? otherwise;
  for (final switchCase in statement.cases) {
    final parsed = _switchCaseAssignOrThrowExpr(
      switchCase.body,
      breakLabel,
      switchCase.isDefault,
      target,
      params,
      libraryUri,
      locals,
      closures,
      compileValue,
    );
    if (parsed == null) return null;
    final parsedVariable = parsed.variable;
    if (parsedVariable != null) {
      target ??= parsedVariable;
      targetLocal ??= locals[parsedVariable];
      if (targetLocal == null || parsedVariable != target) return null;
    }
    final body = parsed.body != null
        ? parsed.body!
        : parsed.throwValue != null
        ? {'throw': parsed.throwValue}
        : parsed.variable == null
        ? null
        : {
            'set_local': {'id': targetLocal, 'value': parsed.value},
          };
    if (body == null) return null;
    if (switchCase.isDefault) {
      if (otherwise != null || switchCase != statement.cases.last) return null;
      otherwise = body;
      continue;
    }
    if (otherwise != null || switchCase.expressions.length != 1) return null;
    final constant = _switchConstantExpr(
      switchCase.expressions.single,
      const {},
      params,
      libraryUri,
      locals,
      closures,
    );
    if (constant == null) return null;
    branches.add(_FcbSwitchExpressionBranch(constant, body));
  }
  if (otherwise == null || branches.isEmpty) return null;
  return _switchBranchesToConditional(scrutinee, branches, otherwise);
}

Map<String, Object?>? _switchCaseReturnExpr(
  Statement body,
  Map<String, Object?>? Function(Expression expression) compileReturn,
) {
  final statements = body is Block ? body.statements : [body];
  if (statements.length != 1) return null;
  final statement = statements.single;
  if (statement is ReturnStatement) {
    final expression = statement.expression;
    if (expression == null) return null;
    return compileReturn(expression);
  }
  if (statement is ExpressionStatement && statement.expression is Throw) {
    final throwExpression = statement.expression as Throw;
    final value = compileReturn(throwExpression.expression);
    if (value == null) return null;
    return {'throw': value};
  }
  return null;
}

_FcbSwitchCaseAssignment? _switchCaseAssignmentExpr(
  Statement body,
  LabeledStatement? breakLabel,
  bool isDefault,
  VariableDeclaration? expectedVariable,
  Map<VariableDeclaration, int> locals,
  Map<String, Object?>? Function(Expression expression) compileValue,
) {
  final statements = body is Block ? body.statements : [body];
  if (statements.isEmpty || statements.length > 2) return null;
  final first = statements.first;
  if (first is! ExpressionStatement || first.expression is! VariableSet) {
    return null;
  }
  final set = first.expression as VariableSet;
  if (expectedVariable != null && set.variable != expectedVariable) {
    return null;
  }
  if (!locals.containsKey(set.variable)) return null;
  if (statements.length == 2) {
    final second = statements.last;
    if (second is! BreakStatement || second.target != breakLabel) return null;
  } else if (!isDefault && breakLabel != null) {
    return null;
  }
  final value = compileValue(set.value);
  if (value == null) return null;
  return _FcbSwitchCaseAssignment(set.variable, value);
}

_FcbSwitchCaseAction? _switchCaseAssignOrThrowExpr(
  Statement body,
  LabeledStatement? breakLabel,
  bool isDefault,
  VariableDeclaration? expectedVariable,
  Set<String> params,
  String libraryUri,
  Map<VariableDeclaration, int> locals,
  Map<VariableDeclaration, FunctionExpression> closures,
  Map<String, Object?>? Function(Expression expression) compileValue,
) {
  final statements = body is Block ? body.statements : [body];
  if (statements.length == 1) {
    final statement = statements.single;
    if (statement is ExpressionStatement && statement.expression is Throw) {
      final throwExpression = statement.expression as Throw;
      final value = compileValue(throwExpression.expression);
      if (value == null) return null;
      return _FcbSwitchCaseAction.throwValue(value);
    }
  }
  final assignment = _switchCaseAssignmentExpr(
    body,
    breakLabel,
    isDefault,
    expectedVariable,
    locals,
    compileValue,
  );
  if (assignment != null) {
    return _FcbSwitchCaseAction.assignment(
      assignment.variable,
      assignment.value,
    );
  }
  return _switchCaseSideEffectSequenceExpr(
    body,
    breakLabel,
    isDefault,
    params,
    libraryUri,
    locals,
    closures,
  );
}

_FcbSwitchCaseAction? _switchCaseSideEffectSequenceExpr(
  Statement body,
  LabeledStatement? breakLabel,
  bool isDefault,
  Set<String> params,
  String libraryUri,
  Map<VariableDeclaration, int> locals,
  Map<VariableDeclaration, FunctionExpression> closures,
) {
  final statements = body is Block ? body.statements : [body];
  if (statements.length < 2) return null;
  final last = statements.last;
  final hasBreak = last is BreakStatement && last.target == breakLabel;
  if (!hasBreak && !isDefault) return null;
  final bodyStatements = hasBreak
      ? statements.take(statements.length - 1).toList(growable: false)
      : statements;
  if (bodyStatements.isEmpty) return null;
  final bodyExpr = _tailStatementSequenceExpr(
    bodyStatements,
    params,
    libraryUri,
    locals,
    closures,
  );
  if (bodyExpr == null) return null;
  return _FcbSwitchCaseAction.body(bodyExpr);
}

class _FcbSwitchStatementWithLabel {
  _FcbSwitchStatementWithLabel(this.statement, this.breakLabel);

  final SwitchStatement statement;
  final LabeledStatement? breakLabel;
}

class _FcbSwitchCaseAssignment {
  _FcbSwitchCaseAssignment(this.variable, this.value);

  final VariableDeclaration variable;
  final Map<String, Object?> value;
}

class _FcbSwitchCaseAction {
  _FcbSwitchCaseAction.assignment(this.variable, this.value)
    : throwValue = null,
      body = null;

  _FcbSwitchCaseAction.throwValue(this.throwValue)
    : variable = null,
      value = null,
      body = null;

  _FcbSwitchCaseAction.body(this.body)
    : variable = null,
      value = null,
      throwValue = null;

  final VariableDeclaration? variable;
  final Map<String, Object?>? value;
  final Map<String, Object?>? throwValue;
  final Map<String, Object?>? body;
}
