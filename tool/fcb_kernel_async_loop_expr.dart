part of fcb_kernel_reader;

Map<String, Object?>? _asyncDoExpr(
  DoStatement statement,
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
  final tryFinallyBody = bodyLabel == null
      ? breakLabel == null
            ? null
            : _asyncTryFinallyBreakableWhileBodyExpr(
                bodyStatements,
                breakLabel,
                paramsSet,
                libraryUri,
                locals,
              )
      : _asyncTryFinallyWhileBodyExpr(
          bodyStatements,
          bodyLabel,
          breakLabel,
          paramsSet,
          libraryUri,
          locals,
        );
  final combinedBody = breakLabel != null && bodyLabel != null
      ? _asyncContinuableBreakableLoopBodyExpr(
          bodyStatements,
          bodyLabel,
          breakLabel,
          paramsSet,
          libraryUri,
          locals,
        )
      : null;
  final body =
      tryFinallyBody ??
      combinedBody ??
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
  if (breakCondition != null && continueCondition != null) {
    return _asyncDoContinueBreakExpr(
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
    return _asyncDoBreakExpr(condition, body, beforeBreak, breakCondition);
  }
  if (continueCondition != null) {
    return _asyncDoContinueExpr(
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

Map<String, Object?>? _asyncDoContinueBreakExpr(
  Map<String, Object?> condition,
  Map<String, Object?> body,
  Object? beforeContinue,
  Object? continueCondition,
  Object? continueBody,
  Object? beforeBreak,
  Object? breakCondition,
) {
  if (continueCondition is! Map ||
      continueBody is! Map ||
      breakCondition is! Map) {
    return null;
  }
  final loop = {
    'while_loop': {
      'condition': condition,
      if (beforeContinue != null) 'before_continue': beforeContinue,
      'continue_condition': continueCondition.cast<String, Object?>(),
      'continue_body': continueBody.cast<String, Object?>(),
      if (beforeBreak != null) 'before_break': beforeBreak,
      'break_condition': breakCondition.cast<String, Object?>(),
      'body': body,
    },
  };
  final afterContinue = {
    'seq': [..._asyncSeqItems(continueBody.cast<String, Object?>()), loop],
  };
  final afterBreak = {
    'seq': [..._asyncSeqItems(body), loop],
  };
  final afterFirst = {
    'seq': [
      if (beforeBreak is Map) beforeBreak.cast<String, Object?>(),
      {
        'conditional': {
          'condition': breakCondition.cast<String, Object?>(),
          'then': {'null': true},
          'else': afterBreak,
        },
      },
    ],
  };
  return {
    'seq': [
      if (beforeContinue is Map) beforeContinue.cast<String, Object?>(),
      {
        'conditional': {
          'condition': continueCondition.cast<String, Object?>(),
          'then': afterContinue,
          'else': afterFirst,
        },
      },
    ],
  };
}

Map<String, Object?>? _asyncDoContinueExpr(
  Map<String, Object?> condition,
  Map<String, Object?> body,
  Object? beforeContinue,
  Object? continueCondition,
  Object? continueBody,
) {
  if (continueCondition is! Map || continueBody is! Map) return null;
  final loop = {
    'while_loop': {
      'condition': condition,
      if (beforeContinue != null) 'before_continue': beforeContinue,
      'continue_condition': continueCondition.cast<String, Object?>(),
      'continue_body': continueBody.cast<String, Object?>(),
      'body': body,
    },
  };
  final afterContinue = {
    'seq': [..._asyncSeqItems(continueBody.cast<String, Object?>()), loop],
  };
  final afterFirst = {
    'seq': [..._asyncSeqItems(body), loop],
  };
  return {
    'seq': [
      if (beforeContinue is Map) beforeContinue.cast<String, Object?>(),
      {
        'conditional': {
          'condition': continueCondition.cast<String, Object?>(),
          'then': afterContinue,
          'else': afterFirst,
        },
      },
    ],
  };
}

Map<String, Object?> _asyncDoBreakExpr(
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
  final afterFirst = {
    'seq': [..._asyncSeqItems(body), loop],
  };
  return {
    'seq': [
      if (beforeBreak is Map) beforeBreak.cast<String, Object?>(),
      {
        'conditional': {
          'condition': (breakCondition as Map).cast<String, Object?>(),
          'then': {'null': true},
          'else': afterFirst,
        },
      },
    ],
  };
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
  final tryFinallyBody = bodyLabel == null
      ? breakLabel == null
            ? null
            : _asyncTryFinallyBreakableWhileBodyExpr(
                bodyStatements,
                breakLabel,
                paramsSet,
                libraryUri,
                locals,
              )
      : _asyncTryFinallyWhileBodyExpr(
          bodyStatements,
          bodyLabel,
          breakLabel,
          paramsSet,
          libraryUri,
          locals,
        );
  final combinedBody = breakLabel != null && bodyLabel != null
      ? _asyncContinuableBreakableLoopBodyExpr(
          bodyStatements,
          bodyLabel,
          breakLabel,
          paramsSet,
          libraryUri,
          locals,
        )
      : null;
  final body =
      tryFinallyBody ??
      combinedBody ??
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
  final breakBody = body.remove('break_body');
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
      if (breakBody != null) 'break_body': breakBody,
      'body': body,
    },
  };
}

Map<String, Object?>? _asyncTryFinallyWhileBodyExpr(
  List<Statement> statements,
  LabeledStatement continueLabel,
  LabeledStatement? breakLabel,
  Set<String> paramsSet,
  String libraryUri,
  Map<VariableDeclaration, int> locals,
) {
  if (breakLabel == null || statements.length != 1) return null;
  final only = statements.single;
  if (only is! TryFinally) return null;
  final finalizer = _asyncTailStatementsSourceExpr(
    _asyncStatementsFromBody(only.finalizer),
    paramsSet,
    libraryUri,
    locals,
  );
  if (finalizer == null) return null;
  final tryBody = _asyncStatementsFromBody(only.body);
  Map<String, Object?>? tryFinallyBody;
  Map<String, Object?>? body = _asyncContinuableBreakableLoopBodyExpr(
    tryBody,
    continueLabel,
    breakLabel,
    paramsSet,
    libraryUri,
    locals,
  );
  tryFinallyBody = body;
  if (body == null &&
      tryBody.length == 1 &&
      tryBody.single is LabeledStatement) {
    final nestedLabel = tryBody.single as LabeledStatement;
    body = _asyncContinuableBreakableLoopBodyExpr(
      _asyncStatementsFromBody(nestedLabel.body),
      nestedLabel,
      breakLabel,
      paramsSet,
      libraryUri,
      locals,
    );
    tryFinallyBody = body;
  }
  if (body == null && tryBody.length == 1 && tryBody.single is TryCatch) {
    final tryCatch = tryBody.single as TryCatch;
    if (tryCatch.catches.length != 1) return null;
    final catchClause = tryCatch.catches.single;
    if (catchClause.stackTrace != null || catchClause.exception == null) {
      return null;
    }
    final catchLocalId = locals.length;
    final tryCatchBody = _asyncStatementsFromBody(tryCatch.body);
    body =
        _asyncContinuableBreakableLoopBodyExpr(
          tryCatchBody,
          continueLabel,
          breakLabel,
          paramsSet,
          libraryUri,
          locals,
        ) ??
        _asyncBreakableWhileBodyExpr(
          tryCatchBody,
          breakLabel,
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
    if (body == null || catchExpr == null) return null;
    tryFinallyBody = {
      'try_catch': {
        'body': body,
        'catch_local': catchLocalId,
        'catch': catchExpr,
      },
    };
  }
  if (body == null || tryFinallyBody == null) return null;
  final beforeContinue = body.remove('before_continue');
  final continueCondition = body.remove('continue_condition');
  final continueBody = body.remove('continue_body');
  final beforeBreak = body.remove('before_break');
  final breakCondition = body.remove('break_condition');
  if (beforeContinue != null || beforeBreak != null) return null;
  if (breakCondition == null) return null;
  final result = <String, Object?>{
    'break_condition': breakCondition,
    'break_body': finalizer,
    'try_finally': {'body': tryFinallyBody, 'finally': finalizer},
  };
  if (continueCondition != null) {
    if (continueBody is! Map) return null;
    result['continue_condition'] = continueCondition;
    result['continue_body'] = _appendAsyncSeq(
      continueBody.cast<String, Object?>(),
      finalizer,
    );
  } else if (continueBody != null) {
    return null;
  }
  return result;
}

Map<String, Object?>? _asyncTryFinallyBreakableWhileBodyExpr(
  List<Statement> statements,
  LabeledStatement breakLabel,
  Set<String> paramsSet,
  String libraryUri,
  Map<VariableDeclaration, int> locals,
) {
  if (statements.length != 1) return null;
  final only = statements.single;
  if (only is! TryFinally) return null;
  final finalizer = _asyncTailStatementsSourceExpr(
    _asyncStatementsFromBody(only.finalizer),
    paramsSet,
    libraryUri,
    locals,
  );
  if (finalizer == null) return null;
  final tryBody = _asyncStatementsFromBody(only.body);
  Map<String, Object?>? body;
  Map<String, Object?>? tryFinallyBody;
  if (tryBody.length == 1 && tryBody.single is TryCatch) {
    final tryCatch = tryBody.single as TryCatch;
    if (tryCatch.catches.length != 1) return null;
    final catchClause = tryCatch.catches.single;
    if (catchClause.stackTrace != null || catchClause.exception == null) {
      return null;
    }
    final catchLocalId = locals.length;
    body = _asyncBreakableWhileBodyExpr(
      _asyncStatementsFromBody(tryCatch.body),
      breakLabel,
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
    if (body == null || catchExpr == null) return null;
    tryFinallyBody = {
      'try_catch': {
        'body': body,
        'catch_local': catchLocalId,
        'catch': catchExpr,
      },
    };
  } else {
    body = _asyncBreakableWhileBodyExpr(
      tryBody,
      breakLabel,
      paramsSet,
      libraryUri,
      locals,
    );
    tryFinallyBody = body;
  }
  if (body == null || tryFinallyBody == null) return null;
  final beforeBreak = body.remove('before_break');
  final breakCondition = body.remove('break_condition');
  if (beforeBreak != null || breakCondition == null) return null;
  return {
    'break_condition': breakCondition,
    'break_body': finalizer,
    'try_finally': {'body': tryFinallyBody, 'finally': finalizer},
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

Map<String, Object?>? _asyncContinuableBreakableLoopBodyExpr(
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
        _asyncIsBreakToLoop(statement.then, breakLabel),
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
