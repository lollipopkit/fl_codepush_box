part of fcb_kernel_reader;

Map<String, Object?>? _generatorForExpr(
  ForStatement statement,
  Set<String> params,
  String libraryUri,
  String asyncKind,
  Map<VariableDeclaration, int> outerLocals, {
  LabeledStatement? breakLabel,
}) {
  if (statement.condition == null) {
    return null;
  }
  final localIds = Map<VariableDeclaration, int>.of(outerLocals);
  final localEntries = <Map<String, Object?>>[];
  for (final variable in statement.variableInitializations) {
    if (variable is! VariableDeclaration || variable.initializer == null) {
      return null;
    }
    final id = localIds.length;
    final initializer = _expr(
      variable.initializer!,
      params,
      libraryUri,
      localIds,
    );
    if (initializer == null) return null;
    localIds[variable] = id;
    localEntries.add({
      'id': id,
      if (variable.name != null && variable.name!.isNotEmpty)
        'name': variable.name,
      'value': initializer,
    });
  }
  final condition = _expr(statement.condition!, params, libraryUri, localIds);
  final update = statement.updates.isEmpty
      ? null
      : _generatorUpdateExpr(statement.updates, params, libraryUri, localIds);
  final body = _generatorForBodyExpr(
    statement.body,
    update,
    breakLabel,
    params,
    libraryUri,
    asyncKind,
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

Map<String, Object?>? _generatorUpdateExpr(
  List<Expression> updates,
  Set<String> params,
  String libraryUri,
  Map<VariableDeclaration, int> locals,
) {
  final items = <Map<String, Object?>>[];
  for (final update in updates) {
    final item = _generatorExpressionExpr(update, params, libraryUri, locals);
    if (item == null) return null;
    items.add(item);
  }
  if (items.isEmpty) return null;
  return items.length == 1 ? items.single : {'seq': items};
}

Map<String, Object?>? _generatorForBodyExpr(
  Statement statement,
  Map<String, Object?>? update,
  LabeledStatement? breakLabel,
  Set<String> params,
  String libraryUri,
  String asyncKind,
  Map<VariableDeclaration, int> locals,
) {
  final bodyLabel = statement is LabeledStatement ? statement : null;
  final body = bodyLabel == null ? statement : bodyLabel.body;
  if (breakLabel != null && body is Block) {
    if (bodyLabel != null) {
      final continueBreakBody = _loweredForContinueBreakBodyExpr(
        body.statements,
        bodyLabel,
        breakLabel,
        update,
        params,
        libraryUri,
        asyncKind,
        locals,
      );
      if (continueBreakBody != null) return continueBreakBody;
    }
    final breakBody = _loweredForInBreakBodyExpr(
      body.statements,
      breakLabel,
      params,
      libraryUri,
      asyncKind,
      locals,
    );
    if (breakBody != null) {
      final beforeBreak = breakBody.remove('before_break');
      final breakCondition = breakBody.remove('break_condition');
      return {
        if (beforeBreak != null) 'before_break': beforeBreak,
        if (breakCondition != null) 'break_condition': breakCondition,
        ..._appendGeneratorSeq(breakBody, update),
      };
    }
  }
  final bodyExpr = bodyLabel == null
      ? _generatorBodyExpr(body, params, libraryUri, asyncKind, locals)
      : _loweredForInContinueBodyExpr(
          bodyLabel,
          params,
          libraryUri,
          asyncKind,
          locals,
        );
  if (bodyExpr == null) return null;
  if (breakLabel == null || body is! Block) {
    return _appendGeneratorSeq(bodyExpr, update);
  }
  return _appendGeneratorSeq(bodyExpr, update);
}

Map<String, Object?>? _loweredForContinueBreakBodyExpr(
  List<Statement> statements,
  LabeledStatement continueLabel,
  LabeledStatement breakLabel,
  Map<String, Object?>? update,
  Set<String> params,
  String libraryUri,
  String asyncKind,
  Map<VariableDeclaration, int> locals,
) {
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
  if (continuePrefix == null) return null;
  final continueCondition = _expr(
    continueStatement.condition,
    params,
    libraryUri,
    locals,
  );
  final beforeContinue = statements.take(continueIndex).toList(growable: false);
  final tail = statements.skip(continueIndex + 1).toList(growable: false);
  final breakIndex = tail.indexWhere(
    (statement) =>
        statement is IfStatement &&
        statement.otherwise == null &&
        _isBreakToLabel(statement.then, breakLabel),
  );
  if (continueCondition == null || breakIndex < 0) return null;
  final breakStatement = tail[breakIndex] as IfStatement;
  final breakCondition = _expr(
    breakStatement.condition,
    params,
    libraryUri,
    locals,
  );
  if (breakCondition == null) return null;
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
  if (beforeContinue.isNotEmpty && beforeContinueBody == null) return null;
  final continuePrefixBody = continuePrefix.isEmpty
      ? {'null': true}
      : _generatorBodyExpr(
          continuePrefix.length == 1
              ? continuePrefix.single
              : Block(continuePrefix),
          params,
          libraryUri,
          asyncKind,
          locals,
        );
  if (continuePrefixBody == null) return null;
  final continueBody = _appendGeneratorSeq(continuePrefixBody, update);
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
  if (beforeBreak.isNotEmpty && beforeBreakBody == null) return null;
  final bodyWithoutUpdate = afterBreak.isEmpty
      ? {'null': true}
      : _generatorBodyExpr(
          afterBreak.length == 1 ? afterBreak.single : Block(afterBreak),
          params,
          libraryUri,
          asyncKind,
          locals,
        );
  if (bodyWithoutUpdate == null) return null;
  return {
    if (beforeContinueBody != null) 'before_continue': beforeContinueBody,
    'continue_condition': continueCondition,
    'continue_body': continueBody,
    if (beforeBreakBody != null) 'before_break': beforeBreakBody,
    'break_condition': breakCondition,
    ..._appendGeneratorSeq(bodyWithoutUpdate, update),
  };
}

Map<String, Object?> _appendGeneratorSeq(
  Map<String, Object?> body,
  Map<String, Object?>? update,
) {
  final items = [
    ..._generatorSeqItems(body),
    if (update != null) ..._generatorSeqItems(update),
  ];
  if (items.length == 1) return items.single;
  return {'seq': items};
}

Map<String, Object?> _generatorSeq(List<Map<String, Object?>> items) {
  final compact = [
    for (final item in items)
      if (item['null'] != true) item,
  ];
  if (compact.isEmpty) return {'null': true};
  if (compact.length == 1) return compact.single;
  return {'seq': compact};
}

List<Map<String, Object?>> _generatorSeqItems(Map<String, Object?> expr) {
  final seq = expr['seq'];
  if (seq is List) {
    return [
      for (final item in seq)
        if (item is Map) item.cast<String, Object?>(),
    ];
  }
  if (expr['null'] == true) return const [];
  return [expr];
}
