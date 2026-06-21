part of fcb_kernel_reader;

ReturnStatement? _returnStatement(Statement? body) {
  if (body is ReturnStatement) return body;
  if (body is Block && body.statements.length == 1) {
    final only = body.statements.single;
    if (only is ReturnStatement) return only;
  }
  return null;
}

Map<String, Object?>? _singleReturnExpr(
  Statement body,
  Set<String> params,
  String libraryUri, [
  Map<VariableDeclaration, int> locals = const {},
  Map<VariableDeclaration, FunctionExpression> closures = const {},
]) {
  final statement = _returnStatement(body);
  if (statement != null && statement.expression != null) {
    return _expr(statement.expression!, params, libraryUri, locals, closures);
  }
  return _letBodySourceExpr(body, params, libraryUri);
}

Map<String, Object?>? _letBodySourceExpr(
  Statement? body,
  Set<String> params,
  String libraryUri,
) {
  if (body is! Block || body.statements.length < 2) return null;
  final locals = <Map<String, Object?>>[];
  final localIds = <VariableDeclaration, int>{};
  final closures = <VariableDeclaration, FunctionExpression>{};
  var nextLocalId = 0;
  var tailStart = 0;
  for (; tailStart < body.statements.length; tailStart++) {
    final statement = body.statements[tailStart];
    if (statement is! VariableDeclaration || statement.initializer == null) {
      break;
    }
    final initializer = statement.initializer!;
    if (initializer is FunctionExpression) {
      closures[statement] = initializer;
      continue;
    }
    final value = _expr(initializer, params, libraryUri, localIds, closures);
    if (value == null) return null;
    final id = nextLocalId++;
    localIds[statement] = id;
    locals.add({
      'id': id,
      if (statement.name != null && statement.name!.isNotEmpty)
        'name': statement.name,
      'value': value,
    });
  }
  if (locals.isEmpty && closures.isEmpty) return null;
  final bodyExpr = _tailStatementsSourceExpr(
    body.statements.skip(tailStart).toList(),
    params,
    libraryUri,
    localIds,
    closures,
  );
  if (bodyExpr == null) return null;
  if (locals.isEmpty) return bodyExpr;
  return {
    'let': {'locals': locals, 'body': bodyExpr},
  };
}

Map<String, Object?>? _syncExpressionStatementSequenceExpr(
  Statement? body,
  Set<String> params,
  String libraryUri,
) {
  if (body is! Block || body.statements.isEmpty) return null;
  final items = <Map<String, Object?>>[];
  for (var i = 0; i < body.statements.length; i++) {
    final statement = body.statements[i];
    if (statement is ReturnStatement &&
        i == body.statements.length - 1 &&
        statement.expression != null) {
      final expr = _expr(statement.expression!, params, libraryUri);
      if (expr == null) return null;
      items.add(expr);
      continue;
    }
    if (statement is! ExpressionStatement) {
      return null;
    }
    final expr = _expr(statement.expression, params, libraryUri);
    if (expr == null) return null;
    items.add(expr);
  }
  if (body.statements.last is! ReturnStatement) {
    items.add({'null': true});
  }
  return {'seq': items};
}

Map<String, Object?>? _tailStatementsSourceExpr(
  List<Statement> statements,
  Set<String> params,
  String libraryUri,
  Map<VariableDeclaration, int> locals,
  Map<VariableDeclaration, FunctionExpression> closures,
) {
  if (statements.length == 1) {
    final only = statements.single;
    if (only is ReturnStatement && only.expression != null) {
      return _expr(only.expression!, params, libraryUri, locals, closures);
    }
    return _ifReturnBodySourceExpr(only, params, libraryUri, locals, closures);
  }
  final ifReturn = statements.length == 2
      ? _ifReturnBodySourceExpr(
          Block(statements),
          params,
          libraryUri,
          locals,
          closures,
        )
      : null;
  if (ifReturn != null) return ifReturn;
  return _tailStatementSequenceExpr(
    statements,
    params,
    libraryUri,
    locals,
    closures,
  );
}

Map<String, Object?>? _tailStatementSequenceExpr(
  List<Statement> statements,
  Set<String> params,
  String libraryUri,
  Map<VariableDeclaration, int> locals,
  Map<VariableDeclaration, FunctionExpression> closures,
) {
  if (statements.length < 2) return null;
  final items = <Map<String, Object?>>[];
  for (var i = 0; i < statements.length; i++) {
    final statement = statements[i];
    if (statement is ReturnStatement &&
        i == statements.length - 1 &&
        statement.expression != null) {
      final expr = _expr(
        statement.expression!,
        params,
        libraryUri,
        locals,
        closures,
      );
      if (expr == null) return null;
      items.add(expr);
      continue;
    }
    if (statement is! ExpressionStatement) return null;
    final expr = _expr(
      statement.expression,
      params,
      libraryUri,
      locals,
      closures,
    );
    if (expr == null) return null;
    items.add(expr);
  }
  return {'seq': items};
}

Map<String, Object?>? _ifReturnBodySourceExpr(
  Statement? body,
  Set<String> params,
  String libraryUri, [
  Map<VariableDeclaration, int> locals = const {},
  Map<VariableDeclaration, FunctionExpression> closures = const {},
]) {
  final ifStatement = body is IfStatement
      ? body
      : body is Block && body.statements.length == 1
      ? body.statements.single
      : null;
  if (ifStatement is IfStatement) {
    return _ifReturnExpr(ifStatement, params, libraryUri, locals, closures);
  }
  if (body is! Block || body.statements.length != 2) return null;
  final first = body.statements.first;
  final second = body.statements.last;
  if (first is! IfStatement || first.otherwise != null) return null;
  final condition = _expr(
    first.condition,
    params,
    libraryUri,
    locals,
    closures,
  );
  final thenExpr = _singleReturnExpr(
    first.then,
    params,
    libraryUri,
    locals,
    closures,
  );
  final elseExpr = _singleReturnExpr(
    second,
    params,
    libraryUri,
    locals,
    closures,
  );
  if (condition == null || thenExpr == null || elseExpr == null) return null;
  return {
    'conditional': {'condition': condition, 'then': thenExpr, 'else': elseExpr},
  };
}

Map<String, Object?>? _ifReturnExpr(
  IfStatement statement,
  Set<String> params,
  String libraryUri,
  Map<VariableDeclaration, int> locals,
  Map<VariableDeclaration, FunctionExpression> closures,
) {
  final otherwise = statement.otherwise;
  if (otherwise == null) return null;
  final condition = _expr(
    statement.condition,
    params,
    libraryUri,
    locals,
    closures,
  );
  final thenExpr = _singleReturnExpr(
    statement.then,
    params,
    libraryUri,
    locals,
    closures,
  );
  final elseExpr = _singleReturnExpr(
    otherwise,
    params,
    libraryUri,
    locals,
    closures,
  );
  if (condition == null || thenExpr == null || elseExpr == null) return null;
  return {
    'conditional': {'condition': condition, 'then': thenExpr, 'else': elseExpr},
  };
}
