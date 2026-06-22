part of fcb_kernel_reader;

Map<String, Object?>? _appendListExpr(
  Map<String, Object?> expr,
  Statement statement,
  VariableDeclaration variable,
  Set<String> params,
  String libraryUri,
  Map<VariableDeclaration, int> locals,
  Map<VariableDeclaration, FunctionExpression> closures,
) {
  final list = expr['list'];
  final conditional = expr['conditional'];
  if (list is List) {
    final items = [...list.cast<Map<String, Object?>>()];
    final spread = _dynamicListSpread(
      statement,
      variable,
      params,
      libraryUri,
      locals,
      closures,
    );
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
      locals,
      closures,
    );
    if (runtimeFor != null) return runtimeFor;
    return _applyListStatement(
          statement,
          variable,
          items,
          params,
          libraryUri,
          locals,
          closures,
        )
        ? {'list': items}
        : null;
  }
  if (expr['list_add_all'] is Map || expr['list_for_in'] is Map) {
    final spread = _dynamicListSpread(
      statement,
      variable,
      params,
      libraryUri,
      locals,
      closures,
    );
    if (spread != null) {
      return {
        'list_add_all': {'receiver': expr, 'spread': spread},
      };
    }
    final runtimeFor = _runtimeListForExpr(
      statement,
      variable,
      expr,
      params,
      libraryUri,
      locals,
      closures,
    );
    if (runtimeFor != null) return runtimeFor;
    final staticSpread = _staticListAppendSpread(
      statement,
      variable,
      params,
      libraryUri,
      locals,
      closures,
    );
    if (staticSpread != null) {
      return {
        'list_add_all': {'receiver': expr, 'spread': staticSpread},
      };
    }
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
      locals,
      closures,
    );
    final elseAppended = _appendListExpr(
      elseExpr.cast<String, Object?>(),
      statement,
      variable,
      params,
      libraryUri,
      locals,
      closures,
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
  Map<VariableDeclaration, int> locals,
  Map<VariableDeclaration, FunctionExpression> closures,
) {
  final map = expr['map'];
  final conditional = expr['conditional'];
  if (map is List) {
    final entries = [...map.cast<Map<String, Object?>>()];
    final spread = _dynamicMapSpread(
      statement,
      variable,
      params,
      libraryUri,
      locals,
      closures,
    );
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
      locals,
      closures,
    );
    if (runtimeFor != null) return runtimeFor;
    return _applyMapStatement(
          statement,
          variable,
          entries,
          params,
          libraryUri,
          locals,
          closures,
        )
        ? {'map': entries}
        : null;
  }
  if (expr['map_add_all'] is Map || expr['map_for_in'] is Map) {
    final spread = _dynamicMapSpread(
      statement,
      variable,
      params,
      libraryUri,
      locals,
      closures,
    );
    if (spread != null) {
      return {
        'map_add_all': {'receiver': expr, 'spread': spread},
      };
    }
    final runtimeFor = _runtimeMapForExpr(
      statement,
      variable,
      expr,
      params,
      libraryUri,
      locals,
      closures,
    );
    if (runtimeFor != null) return runtimeFor;
    final staticSpread = _staticMapAppendSpread(
      statement,
      variable,
      params,
      libraryUri,
      locals,
      closures,
    );
    if (staticSpread != null) {
      return {
        'map_add_all': {'receiver': expr, 'spread': staticSpread},
      };
    }
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
      locals,
      closures,
    );
    final elseAppended = _appendMapExpr(
      elseExpr.cast<String, Object?>(),
      statement,
      variable,
      params,
      libraryUri,
      locals,
      closures,
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
  Map<VariableDeclaration, int> locals,
  Map<VariableDeclaration, FunctionExpression> closures,
) {
  if (statement is! ExpressionStatement) return null;
  final expression = statement.expression;
  if (!_isCollectionCall(expression, variable, 'addAll', 1)) return null;
  final call = expression as InstanceInvocationExpression;
  final spread = _expr(
    call.arguments.positional.single,
    params,
    libraryUri,
    locals,
    closures,
  );
  if (spread == null || spread['list'] is List) return null;
  return spread;
}

Map<String, Object?>? _dynamicMapSpread(
  Statement statement,
  VariableDeclaration variable,
  Set<String> params,
  String libraryUri,
  Map<VariableDeclaration, int> locals,
  Map<VariableDeclaration, FunctionExpression> closures,
) {
  if (statement is! ExpressionStatement) return null;
  final expression = statement.expression;
  if (!_isCollectionCall(expression, variable, 'addAll', 1)) return null;
  final call = expression as InstanceInvocationExpression;
  final spread = _expr(
    call.arguments.positional.single,
    params,
    libraryUri,
    locals,
    closures,
  );
  if (spread == null || spread['map'] is List) return null;
  return spread;
}

Map<String, Object?>? _staticListAppendSpread(
  Statement statement,
  VariableDeclaration variable,
  Set<String> params,
  String libraryUri,
  Map<VariableDeclaration, int> locals,
  Map<VariableDeclaration, FunctionExpression> closures,
) {
  if (statement is! ExpressionStatement) return null;
  final expression = statement.expression;
  if (_isCollectionCall(expression, variable, 'addAll', 1)) {
    final call = expression as InstanceInvocationExpression;
    final spread = _expr(
      call.arguments.positional.single,
      params,
      libraryUri,
      locals,
      closures,
    );
    final list = spread?['list'];
    if (list is! List) return null;
    return {'list': list.cast<Map<String, Object?>>()};
  }
  if (!_isCollectionCall(expression, variable, 'add', 1)) return null;
  final call = expression as InstanceInvocationExpression;
  final item = _expr(
    call.arguments.positional.single,
    params,
    libraryUri,
    locals,
    closures,
  );
  if (item == null) return null;
  return {
    'list': [item],
  };
}

Map<String, Object?>? _staticMapAppendSpread(
  Statement statement,
  VariableDeclaration variable,
  Set<String> params,
  String libraryUri,
  Map<VariableDeclaration, int> locals,
  Map<VariableDeclaration, FunctionExpression> closures,
) {
  if (statement is! ExpressionStatement) return null;
  final expression = statement.expression;
  if (_isCollectionCall(expression, variable, 'addAll', 1)) {
    final call = expression as InstanceInvocationExpression;
    final spread = _expr(
      call.arguments.positional.single,
      params,
      libraryUri,
      locals,
      closures,
    );
    final map = spread?['map'];
    if (map is! List) return null;
    return {'map': map.cast<Map<String, Object?>>()};
  }
  if (!_isCollectionCall(expression, variable, '[]=', 2)) return null;
  final call = expression as InstanceInvocationExpression;
  final key = _expr(
    call.arguments.positional[0],
    params,
    libraryUri,
    locals,
    closures,
  );
  final value = _expr(
    call.arguments.positional[1],
    params,
    libraryUri,
    locals,
    closures,
  );
  if (key == null || value == null) return null;
  return {
    'map': [
      {'key': key, 'value': value},
    ],
  };
}

Map<String, Object?>? _runtimeListForExpr(
  Statement statement,
  VariableDeclaration variable,
  Map<String, Object?> receiver,
  Set<String> params,
  String libraryUri,
  Map<VariableDeclaration, int> locals,
  Map<VariableDeclaration, FunctionExpression> closures,
) {
  final parsed = _runtimeCollectionFor(
    statement,
    params,
    libraryUri,
    locals,
    closures,
  );
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
  Map<VariableDeclaration, int> locals,
  Map<VariableDeclaration, FunctionExpression> closures,
) {
  final parsed = _runtimeCollectionFor(
    statement,
    params,
    libraryUri,
    locals,
    closures,
  );
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
