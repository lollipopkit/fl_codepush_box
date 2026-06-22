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
  return _letBodySourceExpr(body, params, libraryUri, locals, closures);
}

Map<String, Object?>? _letBodySourceExpr(
  Statement? body,
  Set<String> params,
  String libraryUri, [
  Map<VariableDeclaration, int> baseLocals = const {},
  Map<VariableDeclaration, FunctionExpression> baseClosures = const {},
]) {
  if (body is! Block || body.statements.length < 2) return null;
  final locals = <Map<String, Object?>>[];
  final localIds = {...baseLocals};
  final closures = {...baseClosures};
  var nextLocalId = 0;
  for (final id in localIds.values) {
    if (id >= nextLocalId) nextLocalId = id + 1;
  }
  final baseClosureCount = closures.length;
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
  if (locals.isEmpty && closures.length == baseClosureCount) return null;
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
  final expr = _tailStatementsSourceExpr(
    body.statements,
    params,
    libraryUri,
    const {},
    const {},
  );
  if (expr == null) return null;
  if (body.statements.last is ReturnStatement) return expr;
  final items = expr['seq'] is List
      ? List<Object?>.from(expr['seq'] as List)
      : [expr];
  items.add({'null': true});
  return {'seq': items};
}

Map<String, Object?>? _tryFinallyBodySourceExpr(
  Statement? body,
  Set<String> params,
  String libraryUri,
) {
  final tryFinally = body is TryFinally
      ? body
      : body is Block && body.statements.length == 1
      ? body.statements.single
      : null;
  if (tryFinally is! TryFinally) return null;
  final finalizerStatements = _syncStatementsFromBody(tryFinally.finalizer);
  if (finalizerStatements.any((statement) => statement is ReturnStatement)) {
    return null;
  }
  final bodyExpr =
      _singleReturnExpr(tryFinally.body, params, libraryUri) ??
      _tryCatchBodySourceExpr(tryFinally.body, params, libraryUri);
  final finalizerExpr = _tailStatementsSourceExpr(
    finalizerStatements,
    params,
    libraryUri,
    const {},
    const {},
  );
  if (bodyExpr == null || finalizerExpr == null) return null;
  return {
    'try_finally': {'body': bodyExpr, 'finally': finalizerExpr, 'value': true},
  };
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
    if (only is ExpressionStatement) {
      return _expr(only.expression, params, libraryUri, locals, closures);
    }
    if (only is TryFinally || only is TryCatch) {
      return _tailStatementSequenceExpr(
        statements,
        params,
        libraryUri,
        locals,
        closures,
      );
    }
    final switchReturn = _switchReturnStatementExpr(
      only,
      params,
      libraryUri,
      locals,
      closures,
    );
    if (switchReturn != null) return switchReturn;
    return _ifReturnBodySourceExpr(only, params, libraryUri, locals, closures);
  }
  final first = statements.first;
  if (first is VariableDeclaration && first.initializer != null) {
    final value = _expr(
      first.initializer!,
      params,
      libraryUri,
      locals,
      closures,
    );
    if (value == null) return null;
    final id = _nextLocalId(locals);
    final bodyExpr = _tailStatementsSourceExpr(
      statements.skip(1).toList(growable: false),
      params,
      libraryUri,
      {...locals, first: id},
      closures,
    );
    if (bodyExpr == null) return null;
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
        'body': bodyExpr,
      },
    };
  }
  final switchAssign = _switchAssignStatementExpr(
    first,
    params,
    libraryUri,
    locals,
    closures,
    (expression) => _expr(expression, params, libraryUri, locals, closures),
  );
  if (switchAssign != null) {
    final tail = _tailStatementsSourceExpr(
      statements.skip(1).toList(growable: false),
      params,
      libraryUri,
      locals,
      closures,
    );
    if (tail == null) return null;
    return {
      'seq': [switchAssign, tail],
    };
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

int _nextLocalId(Map<VariableDeclaration, int> locals) {
  var nextLocalId = 0;
  for (final id in locals.values) {
    if (id >= nextLocalId) nextLocalId = id + 1;
  }
  return nextLocalId;
}

Map<String, Object?>? _tailStatementSequenceExpr(
  List<Statement> statements,
  Set<String> params,
  String libraryUri,
  Map<VariableDeclaration, int> locals,
  Map<VariableDeclaration, FunctionExpression> closures,
) {
  if (statements.isEmpty) return null;
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
    if (statement is TryFinally) {
      final bodyExpr = _tailStatementsSourceExpr(
        _syncStatementsFromBody(statement.body),
        params,
        libraryUri,
        locals,
        closures,
      );
      final finalizerExpr = _tailStatementsSourceExpr(
        _syncStatementsFromBody(statement.finalizer),
        params,
        libraryUri,
        locals,
        closures,
      );
      if (bodyExpr == null || finalizerExpr == null) return null;
      items.add({
        'try_finally': {'body': bodyExpr, 'finally': finalizerExpr},
      });
      continue;
    }
    if (statement is TryCatch) {
      if (statement.catches.length != 1) return null;
      final catchClause = statement.catches.single;
      if (catchClause.stackTrace != null || catchClause.exception == null) {
        return null;
      }
      final catchLocalId = locals.length;
      final bodyExpr = _tailStatementsSourceExpr(
        _syncStatementsFromBody(statement.body),
        params,
        libraryUri,
        locals,
        closures,
      );
      final catchExpr = _tailStatementsSourceExpr(
        _syncStatementsFromBody(catchClause.body),
        params,
        libraryUri,
        {...locals, catchClause.exception!: catchLocalId},
        closures,
      );
      if (bodyExpr == null || catchExpr == null) return null;
      items.add({
        'try_catch': {
          'body': bodyExpr,
          'catch_local': catchLocalId,
          'catch': catchExpr,
        },
      });
      continue;
    }
    if (statement is IfStatement) {
      final condition = _expr(
        statement.condition,
        params,
        libraryUri,
        locals,
        closures,
      );
      final thenExpr = _tailStatementsSourceExpr(
        _syncStatementsFromBody(statement.then),
        params,
        libraryUri,
        locals,
        closures,
      );
      final elseExpr = statement.otherwise == null
          ? {'null': true}
          : _tailStatementsSourceExpr(
              _syncStatementsFromBody(statement.otherwise!),
              params,
              libraryUri,
              locals,
              closures,
            );
      if (condition == null || thenExpr == null || elseExpr == null) {
        return null;
      }
      items.add({
        'conditional': {
          'condition': condition,
          'then': thenExpr,
          'else': elseExpr,
        },
      });
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

List<Statement> _syncStatementsFromBody(Statement statement) {
  return statement is Block ? statement.statements : [statement];
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
