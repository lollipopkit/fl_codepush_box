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
    final guard = patternGuard.guard == null
        ? null
        : _expr(patternGuard.guard!, params, libraryUri, locals, closures);
    if (patternGuard.guard != null && guard == null) return null;
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
    final constants = _switchPatternConstants(
      pattern,
      params,
      libraryUri,
      locals,
      closures,
    );
    if (constants == null || constants.isEmpty) return null;
    for (final constant in constants) {
      branches.add(_FcbSwitchExpressionBranch(constant, body, guard: guard));
    }
  }
  if (otherwise == null || branches.isEmpty) return null;

  var result = otherwise;
  return _switchBranchesToConditional(scrutinee, branches, result);
}

List<Map<String, Object?>>? _switchPatternConstants(
  Pattern pattern,
  Set<String> params,
  String libraryUri,
  Map<VariableDeclaration, int> locals,
  Map<VariableDeclaration, FunctionExpression> closures,
) {
  if (pattern is ConstantPattern) {
    final constant = _expr(
      pattern.expression,
      params,
      libraryUri,
      locals,
      closures,
    );
    if (constant == null) return null;
    return [constant];
  }
  if (pattern is OrPattern) {
    final left = _switchPatternConstants(
      pattern.left,
      params,
      libraryUri,
      locals,
      closures,
    );
    final right = _switchPatternConstants(
      pattern.right,
      params,
      libraryUri,
      locals,
      closures,
    );
    if (left == null || right == null) return null;
    return [...left, ...right];
  }
  return null;
}

class _FcbSwitchExpressionBranch {
  _FcbSwitchExpressionBranch(this.constant, this.body, {this.guard});

  final Map<String, Object?> constant;
  final Map<String, Object?> body;
  final Map<String, Object?>? guard;
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
    final caseBranches = _loweredSwitchCaseBranches(
      condition,
      scrutineeVariable,
      constants,
      caseBody,
      params,
      libraryUri,
      locals,
      closures,
    );
    if (caseBranches == null || caseBranches.isEmpty) return null;
    branches.addAll(caseBranches);
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
    final match = {'op': '==', 'left': scrutinee, 'right': branch.constant};
    final guard = branch.guard;
    result = {
      'conditional': {
        'condition': guard == null
            ? match
            : {
                'conditional': {
                  'condition': match,
                  'then': guard,
                  'else': {'bool': false},
                },
              },
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

List<_FcbSwitchExpressionBranch>? _loweredSwitchCaseBranches(
  Expression condition,
  VariableDeclaration scrutineeVariable,
  Map<VariableDeclaration, Map<String, Object?>> constants,
  Map<String, Object?> body,
  Set<String> params,
  String libraryUri,
  Map<VariableDeclaration, int> locals,
  Map<VariableDeclaration, FunctionExpression> closures, {
  Map<String, Object?>? Function(Expression expression)? compileGuard,
}) {
  if (condition is LogicalExpression) {
    if (condition.operatorEnum == LogicalExpressionOperator.OR) {
      final left = _loweredSwitchCaseBranches(
        condition.left,
        scrutineeVariable,
        constants,
        body,
        params,
        libraryUri,
        locals,
        closures,
        compileGuard: compileGuard,
      );
      final right = _loweredSwitchCaseBranches(
        condition.right,
        scrutineeVariable,
        constants,
        body,
        params,
        libraryUri,
        locals,
        closures,
        compileGuard: compileGuard,
      );
      if (left == null || right == null) return null;
      return [...left, ...right];
    }
    if (condition.operatorEnum == LogicalExpressionOperator.AND) {
      return _loweredSwitchGuardedCaseBranches(
            condition.left,
            condition.right,
            scrutineeVariable,
            constants,
            body,
            params,
            libraryUri,
            locals,
            closures,
            compileGuard: compileGuard,
          ) ??
          _loweredSwitchGuardedCaseBranches(
            condition.right,
            condition.left,
            scrutineeVariable,
            constants,
            body,
            params,
            libraryUri,
            locals,
            closures,
            compileGuard: compileGuard,
          );
    }
  }
  final caseConstants = _loweredSwitchCaseConstants(
    condition,
    scrutineeVariable,
    constants,
    params,
    libraryUri,
    locals,
    closures,
  );
  if (caseConstants == null) return null;
  return [
    for (final constant in caseConstants)
      _FcbSwitchExpressionBranch(constant, body),
  ];
}

List<_FcbSwitchExpressionBranch>? _loweredSwitchGuardedCaseBranches(
  Expression caseCondition,
  Expression guardCondition,
  VariableDeclaration scrutineeVariable,
  Map<VariableDeclaration, Map<String, Object?>> constants,
  Map<String, Object?> body,
  Set<String> params,
  String libraryUri,
  Map<VariableDeclaration, int> locals,
  Map<VariableDeclaration, FunctionExpression> closures, {
  Map<String, Object?>? Function(Expression expression)? compileGuard,
}) {
  final caseConstants = _loweredSwitchCaseConstants(
    caseCondition,
    scrutineeVariable,
    constants,
    params,
    libraryUri,
    locals,
    closures,
  );
  if (caseConstants == null || caseConstants.isEmpty) return null;
  final guard = compileGuard != null
      ? compileGuard(guardCondition)
      : _asyncCompletedExpr(guardCondition, params, libraryUri, locals) ??
            _expr(guardCondition, params, libraryUri, locals, closures);
  if (guard == null) return null;
  return [
    for (final constant in caseConstants)
      _FcbSwitchExpressionBranch(constant, body, guard: guard),
  ];
}

List<Map<String, Object?>>? _loweredSwitchCaseConstants(
  Expression condition,
  VariableDeclaration scrutineeVariable,
  Map<VariableDeclaration, Map<String, Object?>> constants,
  Set<String> params,
  String libraryUri,
  Map<VariableDeclaration, int> locals,
  Map<VariableDeclaration, FunctionExpression> closures,
) {
  if (condition is LogicalExpression &&
      condition.operatorEnum == LogicalExpressionOperator.OR) {
    final left = _loweredSwitchCaseConstants(
      condition.left,
      scrutineeVariable,
      constants,
      params,
      libraryUri,
      locals,
      closures,
    );
    final right = _loweredSwitchCaseConstants(
      condition.right,
      scrutineeVariable,
      constants,
      params,
      libraryUri,
      locals,
      closures,
    );
    if (left == null || right == null) return null;
    return [...left, ...right];
  }
  if (condition is! EqualsCall) return null;
  final left = condition.left;
  final right = condition.right;
  if (_isSwitchScrutineeGet(left, scrutineeVariable)) {
    final constant = _switchConstantExpr(
      right,
      constants,
      params,
      libraryUri,
      locals,
      closures,
    );
    return constant == null ? null : [constant];
  }
  if (_isSwitchScrutineeGet(right, scrutineeVariable)) {
    final constant = _switchConstantExpr(
      left,
      constants,
      params,
      libraryUri,
      locals,
      closures,
    );
    return constant == null ? null : [constant];
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
