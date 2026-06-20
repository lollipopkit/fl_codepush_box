part of fcb_kernel_reader;

Map<String, Object?>? _generatorWhileExpr(
  WhileStatement statement,
  Set<String> params,
  String libraryUri,
  String asyncKind,
  Map<VariableDeclaration, int> locals, {
  LabeledStatement? breakLabel,
}) {
  final condition = _expr(statement.condition, params, libraryUri, locals);
  final bodyLabel = statement.body is LabeledStatement
      ? statement.body as LabeledStatement
      : null;
  final body = breakLabel != null
      ? _generatorBreakableWhileBodyExpr(
          statement.body,
          breakLabel,
          params,
          libraryUri,
          asyncKind,
          locals,
          continueLabel: bodyLabel,
        )
      : bodyLabel != null
      ? _generatorBreakableWhileBodyExpr(
          bodyLabel.body,
          bodyLabel,
          params,
          libraryUri,
          asyncKind,
          locals,
        )
      : _generatorBodyExpr(
          statement.body,
          params,
          libraryUri,
          asyncKind,
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

Map<String, Object?>? _generatorBreakableWhileBodyExpr(
  Statement body,
  LabeledStatement breakLabel,
  Set<String> params,
  String libraryUri,
  String asyncKind,
  Map<VariableDeclaration, int> locals, {
  LabeledStatement? continueLabel,
}) {
  final labeledBody = body is LabeledStatement ? body : null;
  final loopBody = labeledBody?.body ?? body;
  final effectiveContinueLabel = continueLabel ?? labeledBody ?? breakLabel;
  if (loopBody is! Block) return null;
  final continueBody = _loweredWhileContinueBodyExpr(
    loopBody.statements,
    effectiveContinueLabel,
    params,
    libraryUri,
    asyncKind,
    locals,
    breakLabel: breakLabel,
  );
  if (continueBody != null) return continueBody;
  final breakBody = _loweredForInBreakBodyExpr(
    loopBody.statements,
    breakLabel,
    params,
    libraryUri,
    asyncKind,
    locals,
  );
  return breakBody ??
      _generatorBodyExpr(loopBody, params, libraryUri, asyncKind, locals);
}

Map<String, Object?>? _loweredWhileContinueBodyExpr(
  List<Statement> statements,
  LabeledStatement continueLabel,
  Set<String> params,
  String libraryUri,
  String asyncKind,
  Map<VariableDeclaration, int> locals, {
  LabeledStatement? breakLabel,
}) {
  if (statements.isEmpty) return null;
  final continueIndex = statements.indexWhere(
    (statement) =>
        statement is IfStatement &&
        statement.otherwise == null &&
        _isRepeatableGuardCondition(statement.condition) &&
        _continueBranchPrefix(statement.then, continueLabel) != null,
  );
  if (continueIndex < 0) return null;
  final continueStatement = statements[continueIndex] as IfStatement;
  final continuePrefix = _continueBranchPrefix(
    continueStatement.then,
    continueLabel,
  );
  if (continuePrefix == null || continuePrefix.isEmpty) return null;
  final condition = _expr(
    continueStatement.condition,
    params,
    libraryUri,
    locals,
  );
  final beforeContinue = statements.take(continueIndex).toList(growable: false);
  final tail = statements.skip(continueIndex + 1).toList(growable: false);
  if (condition == null || tail.isEmpty) return null;
  final beforeContinueBody = beforeContinue.isEmpty
      ? null
      : _generatorBodyExpr(
          beforeContinue.length == 1
              ? beforeContinue.single
              : Block(beforeContinue),
          params,
          libraryUri,
          asyncKind,
          locals,
        );
  final continueBody = _generatorBodyExpr(
    continuePrefix.length == 1 ? continuePrefix.single : Block(continuePrefix),
    params,
    libraryUri,
    asyncKind,
    locals,
  );
  final breakIndex = tail.indexWhere(
    (statement) =>
        statement is IfStatement &&
        statement.otherwise == null &&
        _isBreakToLabel(statement.then, breakLabel ?? continueLabel),
  );
  if (breakIndex >= 0) {
    final breakStatement = tail[breakIndex] as IfStatement;
    final breakCondition = _expr(
      breakStatement.condition,
      params,
      libraryUri,
      locals,
    );
    final beforeBreak = tail.take(breakIndex).toList(growable: false);
    final afterBreak = tail.skip(breakIndex + 1).toList(growable: false);
    final beforeBreakBody = beforeBreak.isEmpty
        ? null
        : _generatorBodyExpr(
            beforeBreak.length == 1 ? beforeBreak.single : Block(beforeBreak),
            params,
            libraryUri,
            asyncKind,
            locals,
          );
    final body = afterBreak.isEmpty
        ? {'null': true}
        : _generatorBodyExpr(
            afterBreak.length == 1 ? afterBreak.single : Block(afterBreak),
            params,
            libraryUri,
            asyncKind,
            locals,
          );
    if (beforeBreak.isNotEmpty && beforeBreakBody == null) return null;
    if (continueBody == null || breakCondition == null || body == null) {
      return null;
    }
    return {
      if (beforeContinueBody != null) 'before_continue': beforeContinueBody,
      'continue_condition': condition,
      'continue_body': continueBody,
      if (beforeBreakBody != null) 'before_break': beforeBreakBody,
      'break_condition': breakCondition,
      ...body,
    };
  }
  final body = _generatorBodyExpr(
    tail.length == 1 ? tail.single : Block(tail),
    params,
    libraryUri,
    asyncKind,
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
