part of fcb_kernel_reader;

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
