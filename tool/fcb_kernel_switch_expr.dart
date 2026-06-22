part of fcb_kernel_reader;

Map<String, Object?>? _switchExpressionExpr(
  SwitchExpression expression,
  Set<String> params,
  String libraryUri,
  Map<VariableDeclaration, int> locals,
  Map<VariableDeclaration, FunctionExpression> closures,
) {
  final scrutinee = _expr(
    expression.expression,
    params,
    libraryUri,
    locals,
    closures,
  );
  if (scrutinee == null || expression.cases.length < 2) return null;

  Map<String, Object?>? otherwise;
  final branches = <_FcbSwitchExpressionBranch>[];
  for (final switchCase in expression.cases) {
    final patternGuard = switchCase.patternGuard;
    if (patternGuard.guard != null) return null;
    final body = _expr(
      switchCase.expression,
      params,
      libraryUri,
      locals,
      closures,
    );
    if (body == null) return null;

    final pattern = patternGuard.pattern;
    if (pattern is WildcardPattern) {
      if (otherwise != null || switchCase != expression.cases.last) return null;
      otherwise = body;
      continue;
    }
    if (otherwise != null) return null;
    if (pattern is! ConstantPattern) return null;
    final constant = _expr(
      pattern.expression,
      params,
      libraryUri,
      locals,
      closures,
    );
    if (constant == null) return null;
    branches.add(_FcbSwitchExpressionBranch(constant, body));
  }
  if (otherwise == null || branches.isEmpty) return null;

  var result = otherwise;
  return _switchBranchesToConditional(scrutinee, branches, result);
}

class _FcbSwitchExpressionBranch {
  _FcbSwitchExpressionBranch(this.constant, this.body);

  final Map<String, Object?> constant;
  final Map<String, Object?> body;
}

Map<String, Object?>? _loweredSwitchBlockExpressionExpr(
  BlockExpression expression,
  Set<String> params,
  String libraryUri,
  Map<VariableDeclaration, int> locals,
  Map<VariableDeclaration, FunctionExpression> closures,
) {
  final value = expression.value;
  if (value is! VariableGet) return null;
  final resultVariable = value.variable;
  final statements = expression.body.statements;
  if (statements.length < 3 ||
      statements.first is! VariableDeclaration ||
      statements.first != resultVariable ||
      resultVariable.initializer != null) {
    return null;
  }

  VariableDeclaration? scrutineeVariable;
  Map<String, Object?>? scrutinee;
  final constants = <VariableDeclaration, Map<String, Object?>>{};
  LabeledStatement? label;
  for (final statement in statements.skip(1)) {
    if (statement is LabeledStatement) {
      label = statement;
      break;
    }
    if (statement is! VariableDeclaration || statement.initializer == null) {
      return null;
    }
    if (scrutineeVariable == null) {
      final compiled = _expr(
        statement.initializer!,
        params,
        libraryUri,
        locals,
        closures,
      );
      if (compiled == null) return null;
      scrutineeVariable = statement;
      scrutinee = compiled;
    } else {
      final compiled = _switchConstantExpr(
        statement.initializer!,
        constants,
        params,
        libraryUri,
        locals,
        closures,
      );
      if (compiled == null) return null;
      constants[statement] = compiled;
    }
  }
  if (scrutineeVariable == null || scrutinee == null || label == null) {
    return null;
  }

  final labelBody = label.body;
  if (labelBody is! Block || labelBody.statements.length < 2) return null;
  final branches = <_FcbSwitchExpressionBranch>[];
  Map<String, Object?>? otherwise;
  for (final statement in labelBody.statements) {
    final ifStatement = _loweredSwitchIfStatement(statement);
    if (ifStatement == null || ifStatement.otherwise != null) return null;
    final caseBody = _loweredSwitchAssignedValue(
      ifStatement.then,
      label,
      resultVariable,
      params,
      libraryUri,
      locals,
      closures,
    );
    if (caseBody == null) return null;
    final condition = ifStatement.condition;
    if (condition is BoolLiteral && condition.value) {
      if (otherwise != null || statement != labelBody.statements.last) {
        return null;
      }
      otherwise = caseBody;
      continue;
    }
    if (otherwise != null) return null;
    final constant = _loweredSwitchCaseConstant(
      condition,
      scrutineeVariable,
      constants,
      params,
      libraryUri,
      locals,
      closures,
    );
    if (constant == null) return null;
    branches.add(_FcbSwitchExpressionBranch(constant, caseBody));
  }
  if (otherwise == null || branches.isEmpty) return null;

  var result = otherwise;
  return _switchBranchesToConditional(scrutinee, branches, result);
}

Map<String, Object?> _switchBranchesToConditional(
  Map<String, Object?> scrutinee,
  List<_FcbSwitchExpressionBranch> branches,
  Map<String, Object?> otherwise,
) {
  var result = otherwise;
  for (final branch in branches.reversed) {
    result = {
      'conditional': {
        'condition': {'op': '==', 'left': scrutinee, 'right': branch.constant},
        'then': branch.body,
        'else': result,
      },
    };
  }
  return result;
}

IfStatement? _loweredSwitchIfStatement(Statement statement) {
  if (statement is IfStatement) return statement;
  if (statement is Block && statement.statements.length == 1) {
    final only = statement.statements.single;
    if (only is IfStatement) return only;
  }
  return null;
}

Map<String, Object?>? _loweredSwitchAssignedValue(
  Statement statement,
  LabeledStatement label,
  VariableDeclaration resultVariable,
  Set<String> params,
  String libraryUri,
  Map<VariableDeclaration, int> locals,
  Map<VariableDeclaration, FunctionExpression> closures,
) {
  final statements = statement is Block ? statement.statements : [statement];
  if (statements.length != 2 || statements.last is! BreakStatement) {
    return null;
  }
  if ((statements.last as BreakStatement).target != label) return null;
  final first = statements.first;
  if (first is! ExpressionStatement || first.expression is! VariableSet) {
    return null;
  }
  final set = first.expression as VariableSet;
  if (set.variable != resultVariable) return null;
  return _expr(set.value, params, libraryUri, locals, closures);
}

Map<String, Object?>? _loweredSwitchCaseConstant(
  Expression condition,
  VariableDeclaration scrutineeVariable,
  Map<VariableDeclaration, Map<String, Object?>> constants,
  Set<String> params,
  String libraryUri,
  Map<VariableDeclaration, int> locals,
  Map<VariableDeclaration, FunctionExpression> closures,
) {
  if (condition is! EqualsCall) return null;
  final left = condition.left;
  final right = condition.right;
  if (_isSwitchScrutineeGet(left, scrutineeVariable)) {
    return _switchConstantExpr(
      right,
      constants,
      params,
      libraryUri,
      locals,
      closures,
    );
  }
  if (_isSwitchScrutineeGet(right, scrutineeVariable)) {
    return _switchConstantExpr(
      left,
      constants,
      params,
      libraryUri,
      locals,
      closures,
    );
  }
  return null;
}

bool _isSwitchScrutineeGet(
  Expression expression,
  VariableDeclaration variable,
) => expression is VariableGet && expression.variable == variable;

Map<String, Object?>? _switchConstantExpr(
  Expression expression,
  Map<VariableDeclaration, Map<String, Object?>> constants,
  Set<String> params,
  String libraryUri,
  Map<VariableDeclaration, int> locals,
  Map<VariableDeclaration, FunctionExpression> closures,
) {
  if (expression is VariableGet) {
    final constant = constants[expression.variable];
    if (constant != null) return constant;
  }
  if (expression is ConstantExpression) {
    final constant = expression.constant;
    if (constant is StringConstant) return {'string': constant.value};
    if (constant is IntConstant) return {'int': constant.value};
    if (constant is DoubleConstant) return {'double': constant.value};
    if (constant is BoolConstant) return {'bool': constant.value};
    if (constant is NullConstant) return {'null': true};
  }
  return _expr(expression, params, libraryUri, locals, closures);
}
