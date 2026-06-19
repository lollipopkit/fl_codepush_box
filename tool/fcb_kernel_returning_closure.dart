part of fcb_kernel_reader;

Map<String, Object?>? _returningClosureSource(
  String libraryUri,
  String qualified,
  List<String> params,
  FunctionNode function,
) {
  final body = function.body;
  if (body is! Block || body.statements.isEmpty) return null;
  final last = body.statements.last;
  if (last is! ReturnStatement) return null;
  final closure = _returnedClosure(body.statements, last.expression);
  if (closure == null) return null;
  final typeParameterCount = closure.function.typeParameters.length;

  final paramsSet = params.toSet();
  final localIds = <VariableDeclaration, int>{};
  final locals = <Map<String, Object?>>[];
  var nextLocalId = 0;
  for (final statement in body.statements.take(body.statements.length - 1)) {
    if (statement is FunctionDeclaration) {
      if (statement == closure.declaration) continue;
      return null;
    }
    if (statement is! VariableDeclaration || statement.initializer == null) {
      return null;
    }
    if (statement.initializer is FunctionExpression) {
      if (statement.initializer == closure.expression) continue;
      return null;
    }
    final value = _expr(
      statement.initializer!,
      paramsSet,
      libraryUri,
      localIds,
    );
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

  final paramNamesByVariable = <VariableDeclaration, String>{};
  for (final parameter in [
    ...function.positionalParameters,
    ...function.namedParameters,
  ]) {
    final name = parameter.name;
    if (name != null && name.isNotEmpty) {
      paramNamesByVariable[parameter] = name;
    }
  }
  final captures = _capturedClosureVariables(
    closure.function,
    paramNamesByVariable.keys.toSet(),
    localIds.keys.toSet(),
  );
  if (captures.isEmpty) return null;

  final captureNames = <String>[];
  final captureExprs = <Map<String, Object?>>[];
  for (final capture in captures) {
    final paramName = paramNamesByVariable[capture];
    final localId = localIds[capture];
    final captureName = capture.name?.isNotEmpty == true
        ? capture.name!
        : 'capture_${captureNames.length}';
    captureNames.add(captureName);
    if (paramName != null) {
      captureExprs.add({'arg': paramName});
    } else if (localId != null) {
      captureExprs.add({'let_local': localId});
    } else {
      return null;
    }
  }

  final closureParamNames = <String>[];
  final closureNamedParamNames = <String>[];
  final optionalPositionalCount =
      closure.function.positionalParameters.length -
      closure.function.requiredParameterCount;
  if (optionalPositionalCount < 0) return null;
  for (
    var i = closure.function.requiredParameterCount;
    i < closure.function.positionalParameters.length;
    i++
  ) {
    final initializer = closure.function.positionalParameters[i].initializer;
    if (!_isSupportedNullDefault(initializer)) return null;
  }
  for (final parameter in closure.function.positionalParameters) {
    final name = parameter.name;
    if (name == null || name.isEmpty) {
      return null;
    }
    closureParamNames.add(name);
  }
  for (final parameter in closure.function.namedParameters) {
    final name = parameter.name;
    if (name == null || name.isEmpty) {
      return null;
    }
    if (!parameter.isRequired) {
      final initializer = parameter.initializer;
      if (!_isSupportedNullDefault(initializer)) return null;
    }
    closureParamNames.add(name);
    closureNamedParamNames.add(parameter.isRequired ? name : '?$name');
  }
  final closureBody = _closureBodyExpr(closure.function.body, {
    ...captureNames,
    ...closureParamNames,
  }, libraryUri);
  if (closureBody == null) return null;
  final closureName = '$libraryUri::$qualified.<closure0>()';
  Map<String, Object?> bodyExpr = {
    'make_closure': {
      'target': closureName,
      'captures': captureExprs,
      if (optionalPositionalCount > 0)
        'optional_positional_count': optionalPositionalCount,
      if (typeParameterCount > 0) 'type_parameter_count': typeParameterCount,
      if (closureNamedParamNames.isNotEmpty)
        'named_parameters': closureNamedParamNames,
    },
  };
  if (locals.isNotEmpty) {
    bodyExpr = {
      'let': {'locals': locals, 'body': bodyExpr},
    };
  }
  return {
    'name': '$libraryUri::$qualified',
    'params': params,
    'body': bodyExpr,
    'extra_functions': [
      {
        'name': closureName,
        'params': [...captureNames, ...closureParamNames],
        'body': closureBody,
      },
    ],
  };
}

bool _isSupportedNullDefault(Expression? initializer) {
  if (initializer == null ||
      initializer is NullLiteral ||
      initializer is InvalidExpression) {
    return true;
  }
  return initializer is ConstantExpression &&
      initializer.constant is NullConstant;
}

Map<String, Object?>? _closureBodyExpr(
  Statement? body,
  Set<String> params,
  String libraryUri,
) {
  final statement = _returnStatement(body);
  if (statement != null && statement.expression != null) {
    return _expr(statement.expression!, params, libraryUri);
  }
  return _ifReturnBodySourceExpr(body, params, libraryUri) ??
      _letBodySourceExpr(body, params, libraryUri) ??
      _tryCatchBodySourceExpr(body, params, libraryUri);
}

_ReturnedClosure? _returnedClosure(
  List<Statement> statements,
  Expression? expression,
) {
  if (expression is FunctionExpression) {
    return _ReturnedClosure(
      function: expression.function,
      expression: expression,
    );
  }
  if (expression is! VariableGet) return null;
  for (final statement in statements.take(statements.length - 1)) {
    if (statement is VariableDeclaration && statement == expression.variable) {
      final initializer = statement.initializer;
      return initializer is FunctionExpression
          ? _ReturnedClosure(
              function: initializer.function,
              expression: initializer,
            )
          : null;
    }
    if (statement is FunctionDeclaration &&
        statement.variable == expression.variable) {
      return _ReturnedClosure(
        function: statement.function,
        declaration: statement,
      );
    }
  }
  return null;
}

List<VariableDeclaration> _capturedClosureVariables(
  FunctionNode function,
  Set<VariableDeclaration> outerParams,
  Set<VariableDeclaration> outerLocals,
) {
  final visitor = _ReturningClosureCaptureVisitor(outerParams, outerLocals);
  function.body?.accept(visitor);
  return visitor.captures;
}

class _ReturnedClosure {
  _ReturnedClosure({required this.function, this.expression, this.declaration});

  final FunctionNode function;
  final FunctionExpression? expression;
  final FunctionDeclaration? declaration;
}

class _ReturningClosureCaptureVisitor extends RecursiveVisitor {
  _ReturningClosureCaptureVisitor(this._outerParams, this._outerLocals);

  final Set<VariableDeclaration> _outerParams;
  final Set<VariableDeclaration> _outerLocals;
  final List<VariableDeclaration> captures = [];
  final Set<VariableDeclaration> _seen = {};
  final Set<VariableDeclaration> _declared = {};

  @override
  void defaultDartType(DartType node) {}

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    _declared.add(node);
    node.initializer?.accept(this);
  }

  @override
  void visitVariableGet(VariableGet node) {
    final variable = node.variable;
    if (_declared.contains(variable)) return;
    if (!_outerParams.contains(variable) && !_outerLocals.contains(variable)) {
      return;
    }
    if (_seen.add(variable)) captures.add(variable);
  }

  @override
  void visitEqualsCall(EqualsCall node) {
    node.left.accept(this);
    node.right.accept(this);
  }

  @override
  void visitNot(Not node) {
    node.operand.accept(this);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    final previous = Set<VariableDeclaration>.of(_declared);
    _declared.addAll(node.function.positionalParameters);
    _declared.addAll(node.function.namedParameters);
    node.function.body?.accept(this);
    _declared
      ..clear()
      ..addAll(previous);
  }
}
