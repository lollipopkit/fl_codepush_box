part of fcb_kernel_reader;

Map<String, Object?>? _blockCollectionExpr(
  BlockExpression expression,
  Set<String> params,
  String libraryUri,
) {
  if (expression.body.statements.isEmpty || expression.value is! VariableGet) {
    return null;
  }
  final first = expression.body.statements.first;
  if (first is! VariableDeclaration || first.initializer == null) return null;
  if ((expression.value as VariableGet).variable != first) return null;
  final seed = _expr(first.initializer!, params, libraryUri);
  final list = seed?['list'];
  final map = seed?['map'];
  if (list is List) {
    Map<String, Object?> expr = {'list': list.cast<Map<String, Object?>>()};
    for (final statement in expression.body.statements.skip(1)) {
      if (statement is IfStatement && statement.condition is! BoolLiteral) {
        final condition = _expr(statement.condition, params, libraryUri);
        final thenExpr = _appendListExpr(
          expr,
          statement.then,
          first,
          params,
          libraryUri,
        );
        final elseExpr = statement.otherwise == null
            ? expr
            : _appendListExpr(
                expr,
                statement.otherwise!,
                first,
                params,
                libraryUri,
              );
        if (condition == null || thenExpr == null || elseExpr == null) {
          return null;
        }
        expr = {
          'conditional': {
            'condition': condition,
            'then': thenExpr,
            'else': elseExpr,
          },
        };
      } else {
        final next = _appendListExpr(
          expr,
          statement,
          first,
          params,
          libraryUri,
        );
        if (next == null) return null;
        expr = next;
      }
    }
    return expr;
  }
  if (map is List) {
    Map<String, Object?> expr = {'map': map.cast<Map<String, Object?>>()};
    for (final statement in expression.body.statements.skip(1)) {
      if (statement is IfStatement && statement.condition is! BoolLiteral) {
        final condition = _expr(statement.condition, params, libraryUri);
        final thenExpr = _appendMapExpr(
          expr,
          statement.then,
          first,
          params,
          libraryUri,
        );
        final elseExpr = statement.otherwise == null
            ? expr
            : _appendMapExpr(
                expr,
                statement.otherwise!,
                first,
                params,
                libraryUri,
              );
        if (condition == null || thenExpr == null || elseExpr == null) {
          return null;
        }
        expr = {
          'conditional': {
            'condition': condition,
            'then': thenExpr,
            'else': elseExpr,
          },
        };
      } else {
        final next = _appendMapExpr(expr, statement, first, params, libraryUri);
        if (next == null) return null;
        expr = next;
      }
    }
    return expr;
  }
  return null;
}

Map<String, Object?>? _appendListExpr(
  Map<String, Object?> expr,
  Statement statement,
  VariableDeclaration variable,
  Set<String> params,
  String libraryUri,
) {
  final list = expr['list'];
  final conditional = expr['conditional'];
  if (list is List) {
    final items = [...list.cast<Map<String, Object?>>()];
    final spread = _dynamicListSpread(statement, variable, params, libraryUri);
    if (spread != null) {
      return {
        'list_add_all': {
          'receiver': {'list': items},
          'spread': spread,
        },
      };
    }
    final runtimeFor = _runtimeListForExpr(
      statement,
      variable,
      {'list': items},
      params,
      libraryUri,
    );
    if (runtimeFor != null) return runtimeFor;
    return _applyListStatement(statement, variable, items, params, libraryUri)
        ? {'list': items}
        : null;
  }
  if (conditional is Map) {
    final spec = conditional.cast<String, Object?>();
    final thenExpr = spec['then'];
    final elseExpr = spec['else'];
    if (thenExpr is! Map || elseExpr is! Map) return null;
    final thenAppended = _appendListExpr(
      thenExpr.cast<String, Object?>(),
      statement,
      variable,
      params,
      libraryUri,
    );
    final elseAppended = _appendListExpr(
      elseExpr.cast<String, Object?>(),
      statement,
      variable,
      params,
      libraryUri,
    );
    if (thenAppended == null || elseAppended == null) return null;
    return {
      'conditional': {
        'condition': spec['condition'],
        'then': thenAppended,
        'else': elseAppended,
      },
    };
  }
  return null;
}

Map<String, Object?>? _appendMapExpr(
  Map<String, Object?> expr,
  Statement statement,
  VariableDeclaration variable,
  Set<String> params,
  String libraryUri,
) {
  final map = expr['map'];
  final conditional = expr['conditional'];
  if (map is List) {
    final entries = [...map.cast<Map<String, Object?>>()];
    final spread = _dynamicMapSpread(statement, variable, params, libraryUri);
    if (spread != null) {
      return {
        'map_add_all': {
          'receiver': {'map': entries},
          'spread': spread,
        },
      };
    }
    final runtimeFor = _runtimeMapForExpr(
      statement,
      variable,
      {'map': entries},
      params,
      libraryUri,
    );
    if (runtimeFor != null) return runtimeFor;
    return _applyMapStatement(statement, variable, entries, params, libraryUri)
        ? {'map': entries}
        : null;
  }
  if (conditional is Map) {
    final spec = conditional.cast<String, Object?>();
    final thenExpr = spec['then'];
    final elseExpr = spec['else'];
    if (thenExpr is! Map || elseExpr is! Map) return null;
    final thenAppended = _appendMapExpr(
      thenExpr.cast<String, Object?>(),
      statement,
      variable,
      params,
      libraryUri,
    );
    final elseAppended = _appendMapExpr(
      elseExpr.cast<String, Object?>(),
      statement,
      variable,
      params,
      libraryUri,
    );
    if (thenAppended == null || elseAppended == null) return null;
    return {
      'conditional': {
        'condition': spec['condition'],
        'then': thenAppended,
        'else': elseAppended,
      },
    };
  }
  return null;
}

Map<String, Object?>? _dynamicListSpread(
  Statement statement,
  VariableDeclaration variable,
  Set<String> params,
  String libraryUri,
) {
  if (statement is! ExpressionStatement) return null;
  final expression = statement.expression;
  if (!_isCollectionCall(expression, variable, 'addAll', 1)) return null;
  final call = expression as InstanceInvocationExpression;
  final spread = _expr(call.arguments.positional.single, params, libraryUri);
  if (spread == null || spread['list'] is List) return null;
  return spread;
}

Map<String, Object?>? _dynamicMapSpread(
  Statement statement,
  VariableDeclaration variable,
  Set<String> params,
  String libraryUri,
) {
  if (statement is! ExpressionStatement) return null;
  final expression = statement.expression;
  if (!_isCollectionCall(expression, variable, 'addAll', 1)) return null;
  final call = expression as InstanceInvocationExpression;
  final spread = _expr(call.arguments.positional.single, params, libraryUri);
  if (spread == null || spread['map'] is List) return null;
  return spread;
}

Map<String, Object?>? _runtimeListForExpr(
  Statement statement,
  VariableDeclaration variable,
  Map<String, Object?> receiver,
  Set<String> params,
  String libraryUri,
) {
  final parsed = _runtimeCollectionFor(statement, params, libraryUri);
  if (parsed == null || parsed.kind != _RuntimeCollectionForKind.list) {
    return null;
  }
  final addExpression = parsed.addExpression;
  if (!_isCollectionCall(addExpression, variable, 'add', 1)) return null;
  final call = addExpression as InstanceInvocationExpression;
  if (!_isVariableGet(call.arguments.positional.single, parsed.loopVariable)) {
    return null;
  }
  return {
    'list_for_in': {'receiver': receiver, 'source': parsed.source},
  };
}

Map<String, Object?>? _runtimeMapForExpr(
  Statement statement,
  VariableDeclaration variable,
  Map<String, Object?> receiver,
  Set<String> params,
  String libraryUri,
) {
  final parsed = _runtimeCollectionFor(statement, params, libraryUri);
  if (parsed == null || parsed.kind != _RuntimeCollectionForKind.map) {
    return null;
  }
  final addExpression = parsed.addExpression;
  if (!_isCollectionCall(addExpression, variable, '[]=', 2)) return null;
  final call = addExpression as InstanceInvocationExpression;
  final key = call.arguments.positional[0];
  final value = call.arguments.positional[1];
  if (!_isVariableFieldGet(key, parsed.loopVariable, 'key') ||
      !_isVariableFieldGet(value, parsed.loopVariable, 'value')) {
    return null;
  }
  return {
    'map_for_in': {'receiver': receiver, 'source': parsed.source},
  };
}

bool _applyListStatement(
  Statement statement,
  VariableDeclaration variable,
  List<Map<String, Object?>> items,
  Set<String> params,
  String libraryUri,
) {
  if (_applyStaticListForStatement(
    statement,
    variable,
    items,
    params,
    libraryUri,
  )) {
    return true;
  }
  if (statement is IfStatement) {
    final condition = statement.condition;
    if (condition is! BoolLiteral) return false;
    final selected = condition.value ? statement.then : statement.otherwise;
    return selected == null ||
        _applyListStatement(selected, variable, items, params, libraryUri);
  }
  if (statement is! ExpressionStatement) return false;
  final expression = statement.expression;
  if (_isCollectionCall(expression, variable, 'addAll', 1)) {
    final call = expression as InstanceInvocationExpression;
    final spread = _expr(call.arguments.positional.single, params, libraryUri);
    final list = spread?['list'];
    if (list is! List) return false;
    items.addAll(list.cast<Map<String, Object?>>());
    return true;
  }
  if (!_isCollectionCall(expression, variable, 'add', 1)) return false;
  final call = expression as InstanceInvocationExpression;
  final item = _expr(call.arguments.positional.single, params, libraryUri);
  if (item == null) return false;
  items.add(item);
  return true;
}

bool _applyMapStatement(
  Statement statement,
  VariableDeclaration variable,
  List<Map<String, Object?>> entries,
  Set<String> params,
  String libraryUri,
) {
  if (_applyStaticMapForStatement(
    statement,
    variable,
    entries,
    params,
    libraryUri,
  )) {
    return true;
  }
  if (statement is IfStatement) {
    final condition = statement.condition;
    if (condition is! BoolLiteral) return false;
    final selected = condition.value ? statement.then : statement.otherwise;
    return selected == null ||
        _applyMapStatement(selected, variable, entries, params, libraryUri);
  }
  if (statement is! ExpressionStatement) return false;
  final expression = statement.expression;
  if (_isCollectionCall(expression, variable, 'addAll', 1)) {
    final call = expression as InstanceInvocationExpression;
    final spread = _expr(call.arguments.positional.single, params, libraryUri);
    final map = spread?['map'];
    if (map is! List) return false;
    entries.addAll(map.cast<Map<String, Object?>>());
    return true;
  }
  if (!_isCollectionCall(expression, variable, '[]=', 2)) return false;
  final call = expression as InstanceInvocationExpression;
  final key = _expr(call.arguments.positional[0], params, libraryUri);
  final value = _expr(call.arguments.positional[1], params, libraryUri);
  if (key == null || value == null) return false;
  entries.add({'key': key, 'value': value});
  return true;
}

bool _applyStaticListForStatement(
  Statement statement,
  VariableDeclaration variable,
  List<Map<String, Object?>> items,
  Set<String> params,
  String libraryUri,
) {
  final parsed = _staticCollectionFor(statement, params, libraryUri);
  if (parsed == null || parsed.items == null) return false;
  final addExpression = parsed.addExpression;
  if (!_isCollectionCall(addExpression, variable, 'add', 1)) return false;
  final call = addExpression as InstanceInvocationExpression;
  if (!_isVariableGet(call.arguments.positional.single, parsed.loopVariable)) {
    return false;
  }
  items.addAll(parsed.items!);
  return true;
}

bool _applyStaticMapForStatement(
  Statement statement,
  VariableDeclaration variable,
  List<Map<String, Object?>> entries,
  Set<String> params,
  String libraryUri,
) {
  final parsed = _staticCollectionFor(statement, params, libraryUri);
  if (parsed == null || parsed.entries == null) return false;
  final addExpression = parsed.addExpression;
  if (!_isCollectionCall(addExpression, variable, '[]=', 2)) return false;
  final call = addExpression as InstanceInvocationExpression;
  final key = call.arguments.positional[0];
  final value = call.arguments.positional[1];
  if (!_isVariableFieldGet(key, parsed.loopVariable, 'key') ||
      !_isVariableFieldGet(value, parsed.loopVariable, 'value')) {
    return false;
  }
  entries.addAll(parsed.entries!);
  return true;
}

_StaticCollectionFor? _staticCollectionFor(
  Statement statement,
  Set<String> params,
  String libraryUri,
) {
  if (statement is! Block || statement.statements.length != 2) return null;
  final iterator = statement.statements[0];
  if (iterator is! VariableDeclaration || iterator.initializer == null) {
    return null;
  }
  final source = _staticIteratorSource(
    iterator.initializer!,
    params,
    libraryUri,
  );
  if (source == null) return null;
  final loop = statement.statements[1];
  if (loop is! ForStatement ||
      loop.variables.isNotEmpty ||
      loop.updates.isNotEmpty ||
      !_isIteratorMoveNext(loop.condition, iterator) ||
      loop.body is! Block) {
    return null;
  }
  final body = loop.body as Block;
  if (body.statements.length != 2) return null;
  final current = body.statements[0];
  if (current is! VariableDeclaration ||
      current.initializer == null ||
      !_isIteratorCurrent(current.initializer!, iterator)) {
    return null;
  }
  final add = body.statements[1];
  if (add is! ExpressionStatement) return null;
  return _StaticCollectionFor(
    items: source.items,
    entries: source.entries,
    loopVariable: current,
    addExpression: add.expression,
  );
}

_StaticIteratorSource? _staticIteratorSource(
  Expression expression,
  Set<String> params,
  String libraryUri,
) {
  if (_propertyName(expression) != 'iterator') return null;
  final receiver = _propertyReceiver(expression);
  if (receiver == null) return null;
  if (_propertyName(receiver) == 'entries') {
    final mapReceiver = _propertyReceiver(receiver);
    if (mapReceiver == null) return null;
    final map = _expr(mapReceiver, params, libraryUri)?['map'];
    if (map is List) {
      return _StaticIteratorSource(entries: map.cast<Map<String, Object?>>());
    }
    return null;
  }
  final list = _expr(receiver, params, libraryUri)?['list'];
  if (list is List) {
    return _StaticIteratorSource(items: list.cast<Map<String, Object?>>());
  }
  return null;
}

_RuntimeCollectionFor? _runtimeCollectionFor(
  Statement statement,
  Set<String> params,
  String libraryUri,
) {
  if (statement is! Block || statement.statements.length != 2) return null;
  final iterator = statement.statements[0];
  if (iterator is! VariableDeclaration || iterator.initializer == null) {
    return null;
  }
  final source = _runtimeIteratorSource(
    iterator.initializer!,
    params,
    libraryUri,
  );
  if (source == null) return null;
  final loop = statement.statements[1];
  if (loop is! ForStatement ||
      loop.variables.isNotEmpty ||
      loop.updates.isNotEmpty ||
      !_isIteratorMoveNext(loop.condition, iterator) ||
      loop.body is! Block) {
    return null;
  }
  final body = loop.body as Block;
  if (body.statements.length != 2) return null;
  final current = body.statements[0];
  if (current is! VariableDeclaration ||
      current.initializer == null ||
      !_isIteratorCurrent(current.initializer!, iterator)) {
    return null;
  }
  final add = body.statements[1];
  if (add is! ExpressionStatement) return null;
  return _RuntimeCollectionFor(
    kind: source.kind,
    source: source.source,
    loopVariable: current,
    addExpression: add.expression,
  );
}

_RuntimeIteratorSource? _runtimeIteratorSource(
  Expression expression,
  Set<String> params,
  String libraryUri,
) {
  if (_propertyName(expression) != 'iterator') return null;
  final receiver = _propertyReceiver(expression);
  if (receiver == null) return null;
  if (_propertyName(receiver) == 'entries') {
    final mapReceiver = _propertyReceiver(receiver);
    if (mapReceiver == null) return null;
    final map = _expr(mapReceiver, params, libraryUri);
    if (map == null || map['map'] is List) return null;
    return _RuntimeIteratorSource(
      kind: _RuntimeCollectionForKind.map,
      source: {
        'call_dynamic': {'receiver': map, 'method': 'get:entries', 'args': []},
      },
    );
  }
  final source = _expr(receiver, params, libraryUri);
  if (source == null || source['list'] is List) return null;
  return _RuntimeIteratorSource(
    kind: _RuntimeCollectionForKind.list,
    source: source,
  );
}

bool _isIteratorMoveNext(
  Expression? expression,
  VariableDeclaration iterator,
) =>
    expression is InstanceInvocationExpression &&
    expression.name.text == 'moveNext' &&
    expression.arguments.positional.isEmpty &&
    expression.arguments.named.isEmpty &&
    _isVariableGet(expression.receiver, iterator);

bool _isIteratorCurrent(Expression expression, VariableDeclaration iterator) =>
    _propertyName(expression) == 'current' &&
    _isVariableGet(_propertyReceiver(expression), iterator);

bool _isVariableGet(Expression? expression, VariableDeclaration variable) =>
    expression is VariableGet && expression.variable == variable;

bool _isVariableFieldGet(
  Expression expression,
  VariableDeclaration variable,
  String field,
) =>
    _propertyName(expression) == field &&
    _isVariableGet(_propertyReceiver(expression), variable);

String? _propertyName(Expression expression) {
  if (expression is InstanceGet) return expression.name.text;
  if (expression is DynamicGet) return expression.name.text;
  return null;
}

Expression? _propertyReceiver(Expression expression) {
  if (expression is InstanceGet) return expression.receiver;
  if (expression is DynamicGet) return expression.receiver;
  return null;
}

class _StaticIteratorSource {
  _StaticIteratorSource({this.items, this.entries});

  final List<Map<String, Object?>>? items;
  final List<Map<String, Object?>>? entries;
}

class _StaticCollectionFor {
  _StaticCollectionFor({
    required this.loopVariable,
    required this.addExpression,
    this.items,
    this.entries,
  });

  final List<Map<String, Object?>>? items;
  final List<Map<String, Object?>>? entries;
  final VariableDeclaration loopVariable;
  final Expression addExpression;
}

enum _RuntimeCollectionForKind { list, map }

class _RuntimeIteratorSource {
  _RuntimeIteratorSource({required this.kind, required this.source});

  final _RuntimeCollectionForKind kind;
  final Map<String, Object?> source;
}

class _RuntimeCollectionFor {
  _RuntimeCollectionFor({
    required this.kind,
    required this.source,
    required this.loopVariable,
    required this.addExpression,
  });

  final _RuntimeCollectionForKind kind;
  final Map<String, Object?> source;
  final VariableDeclaration loopVariable;
  final Expression addExpression;
}

bool _isCollectionCall(
  Expression expression,
  VariableDeclaration variable,
  String name,
  int positionalCount,
) =>
    expression is InstanceInvocationExpression &&
    expression.name.text == name &&
    expression.arguments.positional.length == positionalCount &&
    expression.arguments.named.isEmpty &&
    expression.receiver is VariableGet &&
    (expression.receiver as VariableGet).variable == variable;
