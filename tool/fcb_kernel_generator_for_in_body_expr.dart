part of fcb_kernel_reader;

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
    if (continueBody != null) return {'_uses_continue': true, ...continueBody};
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
