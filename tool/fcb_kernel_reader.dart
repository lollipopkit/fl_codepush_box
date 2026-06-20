library fcb_kernel_reader;

import 'dart:convert';
import 'dart:io';

import 'package:kernel/ast.dart';
import 'package:kernel/kernel.dart';
import 'package:kernel/text/ast_to_text.dart';

import 'fcb_kernel_callback_inline.dart';
import 'fcb_kernel_type_names.dart';
import 'fcb_kernel_unsupported_audit.dart';

part 'fcb_kernel_logical_expr.dart';
part 'fcb_kernel_async_expr.dart';
part 'fcb_kernel_generator_expr.dart';
part 'fcb_kernel_generator_for_expr.dart';
part 'fcb_kernel_generator_loop_expr.dart';
part 'fcb_kernel_generator_stream_expr.dart';
part 'fcb_kernel_returning_closure.dart';
part 'fcb_kernel_statement_expr.dart';
part 'fcb_kernel_static_invocation_expr.dart';
part 'fcb_kernel_reader_text.dart';
part 'fcb_kernel_unary_binary_expr.dart';

void main(List<String> args) {
  final dill = args[0];
  final project = Directory(args[1]).absolute;
  final target = args[2];
  final packageName = args[3];
  final component = loadComponentFromBinary(dill);
  final functions = <Map<String, Object?>>[];
  final classes = <Map<String, Object?>>[];
  final fields = <Map<String, Object?>>[];

  for (final library in component.libraries) {
    if (!_isProjectLibrary(library, project, packageName)) continue;
    final libraryUri = _canonicalLibraryUri(library, project, packageName);
    for (final klass in library.classes) {
      classes.add(_classEntry(libraryUri, klass));
      for (final constructor in klass.constructors) {
        functions.add(
          _constructorEntry(libraryUri, 'class:${klass.name}', constructor),
        );
      }
      for (final procedure in klass.procedures) {
        functions.add(
          _procedureEntry(libraryUri, 'class:${klass.name}', procedure),
        );
      }
    }
    for (final procedure in library.procedures) {
      functions.add(
        _procedureEntry(libraryUri, _extensionEnclosing(procedure), procedure),
      );
    }
    for (final field in library.fields) {
      fields.add(_fieldEntry(libraryUri, field));
    }
  }

  stdout.write(
    jsonEncode({
      'schema_version': 1,
      'functions': functions,
      'classes': classes,
      'top_level_fields': fields,
      'target': target,
      'inventory_source': 'kernel_ast',
    }),
  );
}

bool _isProjectLibrary(Library library, Directory project, String packageName) {
  final uri = library.importUri;
  if (uri.scheme == 'package') {
    return uri.path == packageName || uri.path.startsWith('$packageName/');
  }
  if (uri.scheme == 'file') {
    final path = File.fromUri(uri).absolute.path;
    return path.startsWith('${project.path}/lib/');
  }
  return false;
}

String _canonicalLibraryUri(
  Library library,
  Directory project,
  String packageName,
) {
  final uri = library.importUri;
  if (uri.scheme == 'package') return uri.toString();
  if (uri.scheme == 'file') {
    final path = File.fromUri(uri).absolute.path;
    final libPrefix = '${project.path}/lib/';
    if (path.startsWith(libPrefix)) {
      return 'package:$packageName/${path.substring(libPrefix.length)}';
    }
  }
  return uri.toString();
}

Map<String, Object?> _procedureEntry(
  String libraryUri,
  String enclosing,
  Procedure procedure,
) {
  final function = procedure.function;
  final memberName = procedure.name.text;
  final signature = _signature(function);
  final source = _bytecodeSource(libraryUri, enclosing, memberName, function);
  final unsupported = fcbUnsupportedReasons(function, source);
  final functionId = _hash(
    [
      libraryUri,
      enclosing,
      memberName,
      _hash(signature),
      function.typeParameters.length,
    ].join('\n'),
  );
  return {
    'function_id': functionId,
    'library_uri': libraryUri,
    'enclosing': enclosing,
    'member_name': memberName,
    'signature_hash': _hash(signature),
    'body_hash': _hash(_nodeText(function.body)),
    'source_location': _location(procedure),
    if (source != null && unsupported.isEmpty) 'bytecode_source': source,
    'unsupported_reasons': unsupported,
  };
}

Map<String, Object?> _classEntry(String libraryUri, Class klass) {
  final shape = [
    klass.name,
    klass.typeParameters.map(_typeParameterText).join(','),
    klass.supertype?.toString() ?? '',
    klass.mixedInType?.toString() ?? '',
    klass.implementedTypes.map((type) => type.toString()).join(','),
    ...klass.fields.map(
      (field) =>
          'field:${field.name.text}:${field.type}:${field.isStatic}:${field.isFinal}:${field.isConst}',
    ),
    ...klass.constructors.map(
      (constructor) =>
          'constructor:${constructor.name.text}:${constructor.isConst}:${constructor.isExternal}:${_signature(constructor.function)}:${constructor.initializers.map(_nodeText).join(",")}',
    ),
    ...klass.procedures.map(
      (procedure) =>
          'procedure:${procedure.name.text}:${procedure.kind}:${procedure.isStatic}:${_signature(procedure.function)}',
    ),
  ].join('\n');
  return {
    'class_id': _hash([libraryUri, 'class:${klass.name}'].join('\n')),
    'class_name': klass.name,
    'shape_hash': _hash(shape),
    'source_location': _location(klass),
  };
}

Map<String, Object?> _constructorEntry(
  String libraryUri,
  String enclosing,
  Constructor constructor,
) {
  final memberName = constructor.name.text;
  final signature = _signature(constructor.function);
  final functionId = _hash(
    [
      libraryUri,
      enclosing,
      memberName,
      _hash(signature),
      constructor.function.typeParameters.length,
    ].join('\n'),
  );
  return {
    'function_id': functionId,
    'library_uri': libraryUri,
    'enclosing': enclosing,
    'member_name': memberName,
    'signature_hash': _hash(signature),
    'body_hash': _hash(
      [
        _nodeText(constructor.function.body),
        constructor.initializers.map(_nodeText).join('\n'),
      ].join('\n'),
    ),
    'source_location': _location(constructor),
    'unsupported_reasons': ['unsupported_kernel_node'],
  };
}

Map<String, Object?> _fieldEntry(String libraryUri, Field field) {
  final signature = [
    field.name.text,
    field.type.toString(),
    field.isStatic,
    field.isFinal,
    field.isConst,
    field.isLate,
  ].join(':');
  return {
    'field_id': _hash([libraryUri, field.name.text].join('\n')),
    'signature_hash': _hash(signature),
    'source_location': _location(field),
  };
}

String _extensionEnclosing(Procedure procedure) {
  if (!procedure.isExtensionMember && !procedure.isExtensionTypeMember) {
    return '';
  }
  final name = procedure.name.text;
  final separator = name.indexOf('|');
  if (separator > 0) return 'extension:${name.substring(0, separator)}';
  return 'extension';
}

String _signature(FunctionNode function) {
  return [
    function.returnType.toString(),
    function.requiredParameterCount,
    function.typeParameters.map(_typeParameterText).join(','),
    function.positionalParameters.map(_variableSignature).join(','),
    function.namedParameters.map(_variableSignature).join(','),
  ].join(':');
}

String _typeParameterText(TypeParameter parameter) {
  return '${parameter.name}:${parameter.bound}:${parameter.defaultType}';
}

String _variableSignature(VariableDeclaration variable) {
  return '${variable.name}:${variable.type}:${variable.isRequired}';
}

Map<String, Object?>? _bytecodeSource(
  String libraryUri,
  String enclosing,
  String memberName,
  FunctionNode function,
) {
  final statement = _returnStatement(function.body);
  final params = [
    ...function.positionalParameters.map((param) => param.name ?? ''),
    ...function.namedParameters.map((param) => param.name ?? ''),
  ].where((name) => name.isNotEmpty).toList();
  final paramsSet = params.toSet();
  final qualified = enclosing.isEmpty ? memberName : '$enclosing.$memberName';
  final asyncValue = _asyncFutureValueSource(
    libraryUri,
    qualified,
    params,
    paramsSet,
    function,
  );
  if (asyncValue != null) return asyncValue;
  final generator = _generatorSource(
    libraryUri,
    qualified,
    params,
    paramsSet,
    function,
  );
  if (generator != null) return generator;
  final returningClosure = _returningClosureSource(
    libraryUri,
    qualified,
    params,
    function,
  );
  if (returningClosure != null) return returningClosure;
  final expr =
      (statement?.expression == null
          ? null
          : _expr(statement!.expression!, paramsSet, libraryUri)) ??
      _letBodySourceExpr(function.body, paramsSet, libraryUri) ??
      _tryCatchBodySourceExpr(function.body, paramsSet, libraryUri) ??
      _returnBodySourceExpr(function.body, paramsSet);
  if (expr == null) return null;
  return {
    'name': '$libraryUri::$qualified',
    'return_type': fcbKernelTypeName(function.returnType),
    'params': params,
    'body': expr,
  };
}

Map<String, Object?>? _returnBodySourceExpr(
  Statement? body,
  Set<String> params,
) {
  final text = _nodeText(body);
  final match = RegExp(r'^\{\s*return\s+(.+);\s*\}$').firstMatch(text);
  if (match == null) return null;
  return _sourceExpr(match.group(1)!.trim(), params);
}

Map<String, Object?>? _tryCatchBodySourceExpr(
  Statement? body,
  Set<String> params,
  String libraryUri,
) {
  final tryCatch = body is TryCatch
      ? body
      : body is Block && body.statements.length == 1
      ? body.statements.single
      : null;
  if (tryCatch is! TryCatch || tryCatch.catches.length != 1) return null;
  final catchClause = tryCatch.catches.single;
  if (catchClause.stackTrace != null || catchClause.exception == null) {
    return null;
  }

  final catchLocalId = 0;
  final bodyExpr = _singleReturnExpr(tryCatch.body, params, libraryUri);
  final catchExpr = _singleReturnExpr(catchClause.body, params, libraryUri, {
    catchClause.exception!: catchLocalId,
  });
  if (bodyExpr == null || catchExpr == null) return null;
  return {
    'try_catch': {
      'body': bodyExpr,
      'catch_local': catchLocalId,
      'catch': catchExpr,
    },
  };
}

Map<String, Object?>? _expr(
  Expression expression,
  Set<String> params,
  String libraryUri, [
  Map<VariableDeclaration, int> locals = const {},
  Map<VariableDeclaration, FunctionExpression> closures = const {},
]) {
  if (expression is IntLiteral) return {'int': expression.value};
  if (expression is DoubleLiteral) return {'double': expression.value};
  if (expression is StringLiteral) return {'string': expression.value};
  if (expression is BoolLiteral) return {'bool': expression.value};
  if (expression is NullLiteral) return {'null': true};
  if (expression is ConstantExpression) {
    final constant = expression.constant;
    if (constant is StaticTearOffConstant) {
      return {'make_closure': _staticTargetName(constant.target)};
    }
  }
  if (expression is Throw) {
    final value = _expr(
      expression.expression,
      params,
      libraryUri,
      locals,
      closures,
    );
    if (value == null) return null;
    return {'throw': value};
  }
  if (expression is LogicalExpression) {
    return _logicalExpressionExpr(
      expression,
      params,
      libraryUri,
      locals,
      closures,
    );
  }
  if (expression is EqualsCall) {
    return _equalsCallExpr(expression, params, libraryUri, locals, closures);
  }
  if (expression is Not) {
    return _notExpr(expression, params, libraryUri, locals, closures);
  }
  if (expression is VariableGet) {
    final local = locals[expression.variable];
    if (local != null) return {'let_local': local};
    final name = expression.variable.name;
    if (name != null && params.contains(name)) return {'arg': name};
    return null;
  }
  if (expression is StaticTearOff) {
    return {'make_closure': _staticTargetName(expression.target)};
  }
  if (expression is StaticGet && expression.target is Procedure) {
    return {'make_closure': _staticTargetName(expression.target as Procedure)};
  }
  if (expression is InstanceGet) {
    final receiver = _expr(
      expression.receiver,
      params,
      libraryUri,
      locals,
      closures,
    );
    final field = expression.name.text;
    if (receiver != null && field.isNotEmpty) {
      return {
        'get_field': {'receiver': receiver, 'field': field},
      };
    }
    return null;
  }
  if (expression is DynamicGet) {
    final receiver = _expr(
      expression.receiver,
      params,
      libraryUri,
      locals,
      closures,
    );
    final field = expression.name.text;
    if (receiver != null && field.isNotEmpty) {
      return {
        'get_field': {'receiver': receiver, 'field': field},
      };
    }
    return null;
  }
  if (expression is StaticInvocation) {
    final inlineCallback = fcbInlineableStaticCallback(expression);
    if (inlineCallback != null) {
      return _inlineClosureInvocation(
        inlineCallback,
        params,
        libraryUri,
        locals,
        closures,
      );
    }
    final Procedure target;
    try {
      target = expression.target;
    } catch (error) {
      final text = error.toString();
      if (text.contains('_GrowableList') || text.contains('_List')) {
        final items = <Map<String, Object?>>[];
        for (final arg in expression.arguments.positional) {
          final compiledArg = _expr(arg, params, libraryUri, locals, closures);
          if (compiledArg == null) return null;
          items.add(compiledArg);
        }
        return {'list': items};
      }
      final originalCall = _unboundDartStaticInvocationExpr(
        expression,
        params,
        libraryUri,
        locals,
        closures,
      );
      if (originalCall != null) return originalCall;
      return _sourceExpr(_nodeText(expression), params);
    }
    final args = <Map<String, Object?>>[];
    for (final arg in expression.arguments.positional) {
      final compiledArg = _expr(arg, params, libraryUri, locals, closures);
      if (compiledArg == null) return null;
      args.add(compiledArg);
    }
    if (expression.arguments.named.isNotEmpty) return null;
    final targetName = _staticTargetName(target);
    if (target.enclosingLibrary.importUri.scheme == 'dart') {
      return {'call_original': targetName, 'args': args};
    }
    return {'call_static': targetName, 'args': args};
  }
  if (expression is ConstructorInvocation) {
    final args = <Map<String, Object?>>[];
    for (final arg in expression.arguments.positional) {
      final compiledArg = _expr(arg, params, libraryUri, locals, closures);
      if (compiledArg == null) return null;
      args.add(compiledArg);
    }
    final namedArgs = <Map<String, Object?>>[];
    for (final arg in expression.arguments.named) {
      final compiledArg = _expr(
        arg.value,
        params,
        libraryUri,
        locals,
        closures,
      );
      if (compiledArg == null) return null;
      namedArgs.add({'name': arg.name, 'value': compiledArg});
    }
    final typeArgs = <String>[];
    for (final type in expression.arguments.types) {
      final typeName = _typeName(type);
      if (typeName == null) return null;
      typeArgs.add(typeName);
    }
    final Constructor constructor;
    try {
      constructor = expression.target;
    } catch (_) {
      return null;
    }
    final klass = constructor.enclosingClass;
    final constructorLibraryUri = _constructorLibraryUri(
      klass.enclosingLibrary,
      libraryUri,
    );
    final constructorName = constructor.name.text;
    final suffix = constructorName.isEmpty ? '.' : '.$constructorName';
    return {
      'new_object': {
        'constructor': '$constructorLibraryUri::class:${klass.name}$suffix',
        'args': args,
        if (typeArgs.isNotEmpty) 'type_args': typeArgs,
        if (namedArgs.isNotEmpty) 'named_args': namedArgs,
      },
    };
  }
  if (expression is BlockExpression) {
    return _blockCollectionExpr(expression, params, libraryUri);
  }
  if (expression is ListLiteral) {
    final items = <Map<String, Object?>>[];
    for (final item in expression.expressions) {
      final compiledItem = _expr(item, params, libraryUri, locals, closures);
      if (compiledItem == null) return null;
      items.add(compiledItem);
    }
    return {'list': items};
  }
  if (expression is MapLiteral) {
    final entries = <Map<String, Object?>>[];
    for (final entry in expression.entries) {
      if (entry is! MapLiteralEntry) return null;
      final key = _expr(entry.key, params, libraryUri, locals, closures);
      final value = _expr(entry.value, params, libraryUri, locals, closures);
      if (key == null || value == null) return null;
      entries.add({'key': key, 'value': value});
    }
    return {'map': entries};
  }
  if (expression is StringConcatenation) {
    return _concatExpr(
      expression.expressions,
      params,
      libraryUri,
      locals,
      closures,
    );
  }
  if (expression is IsExpression) {
    final value = _expr(
      expression.operand,
      params,
      libraryUri,
      locals,
      closures,
    );
    final type = _typeName(expression.type);
    if (value != null && type != null) {
      return {
        'is_type': {'value': value, 'type': type},
      };
    }
  }
  if (expression is AsExpression) {
    final value = _expr(
      expression.operand,
      params,
      libraryUri,
      locals,
      closures,
    );
    final type = _typeName(expression.type);
    if (value != null && type != null) {
      return {
        'as_type': {'value': value, 'type': type},
      };
    }
  }
  if (expression is ConditionalExpression) {
    final condition = _expr(
      expression.condition,
      params,
      libraryUri,
      locals,
      closures,
    );
    final thenExpr = _expr(
      expression.then,
      params,
      libraryUri,
      locals,
      closures,
    );
    final elseExpr = _expr(
      expression.otherwise,
      params,
      libraryUri,
      locals,
      closures,
    );
    if (condition != null && thenExpr != null && elseExpr != null) {
      return {
        'conditional': {
          'condition': condition,
          'then': thenExpr,
          'else': elseExpr,
        },
      };
    }
    return null;
  }
  if (expression is FunctionInvocation) {
    if (expression.arguments.positional.isNotEmpty ||
        expression.arguments.named.isNotEmpty ||
        expression.arguments.types.isNotEmpty) {
      return null;
    }
    final receiver = expression.receiver;
    final closure = receiver is FunctionExpression
        ? receiver
        : receiver is VariableGet
        ? closures[receiver.variable]
        : null;
    if (closure == null) return null;
    return _inlineClosureInvocation(
      closure,
      params,
      libraryUri,
      locals,
      closures,
    );
  }
  if (expression is InstanceInvocationExpression) {
    final op = expression.name.text;
    if (['==', '>', '+', '-', '*', '/'].contains(op) &&
        expression.arguments.positional.length == 1 &&
        expression.arguments.named.isEmpty) {
      final left = _expr(
        expression.receiver,
        params,
        libraryUri,
        locals,
        closures,
      );
      final right = _expr(
        expression.arguments.positional.single,
        params,
        libraryUri,
        locals,
        closures,
      );
      if (left != null && right != null) {
        return {'op': op, 'left': left, 'right': right};
      }
    }
    if (op.isEmpty) return null;
    final receiver = _expr(
      expression.receiver,
      params,
      libraryUri,
      locals,
      closures,
    );
    if (receiver == null) return null;
    final args = <Map<String, Object?>>[];
    for (final arg in expression.arguments.positional) {
      final compiledArg = _expr(arg, params, libraryUri, locals, closures);
      if (compiledArg == null) return null;
      args.add(compiledArg);
    }
    final namedArgs = <Map<String, Object?>>[];
    for (final arg in expression.arguments.named) {
      final compiledArg = _expr(
        arg.value,
        params,
        libraryUri,
        locals,
        closures,
      );
      if (compiledArg == null) return null;
      namedArgs.add({'name': arg.name, 'value': compiledArg});
    }
    return {
      'call_dynamic': {
        'receiver': receiver,
        'method': op,
        'args': args,
        if (namedArgs.isNotEmpty) 'named_args': namedArgs,
      },
    };
  }
  final text = _nodeText(expression);
  for (final op in ['==', '>', '+', '-', '*', '/']) {
    final idx = text.indexOf(' $op ');
    if (idx > 0) {
      final left = _sourceExpr(text.substring(0, idx).trim(), params);
      final right = _sourceExpr(
        text.substring(idx + op.length + 2).trim(),
        params,
      );
      if (left != null && right != null) {
        return {'op': op, 'left': left, 'right': right};
      }
    }
  }
  return null;
}

Map<String, Object?>? _inlineClosureInvocation(
  FunctionExpression expression,
  Set<String> params,
  String libraryUri,
  Map<VariableDeclaration, int> locals,
  Map<VariableDeclaration, FunctionExpression> closures,
) {
  final function = expression.function;
  if (function.positionalParameters.isNotEmpty ||
      function.namedParameters.isNotEmpty ||
      function.typeParameters.isNotEmpty) {
    return null;
  }
  final statement = _returnStatement(function.body);
  if (statement == null || statement.expression == null) return null;
  return _expr(statement.expression!, params, libraryUri, locals, closures);
}

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
        if (condition == null || thenExpr == null || elseExpr == null)
          return null;
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
        if (condition == null || thenExpr == null || elseExpr == null)
          return null;
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

Map<String, Object?>? _concatExpr(
  List<Expression> expressions,
  Set<String> params,
  String libraryUri, [
  Map<VariableDeclaration, int> locals = const {},
  Map<VariableDeclaration, FunctionExpression> closures = const {},
]) {
  if (expressions.isEmpty) return {'string': ''};
  final parts = <Map<String, Object?>>[];
  for (final expression in expressions) {
    final part = _expr(expression, params, libraryUri, locals, closures);
    if (part == null) return null;
    parts.add(part);
  }
  return {'concat': parts};
}

Map<String, Object?>? _sourceExpr(String raw, Set<String> params) {
  raw = raw.trim();
  if (RegExp(r'^-?\d+$').hasMatch(raw)) return {'int': int.parse(raw)};
  if (RegExp(r'^-?\d+\.\d+$').hasMatch(raw)) {
    return {'double': double.parse(raw)};
  }
  if (raw == 'true' || raw == 'false') return {'bool': raw == 'true'};
  if (raw == 'null') return {'null': true};
  if (raw.startsWith("'") && raw.endsWith("'")) {
    return {'string': raw.substring(1, raw.length - 1)};
  }
  if (raw.startsWith('"') && raw.endsWith('"')) {
    return {'string': raw.substring(1, raw.length - 1)};
  }
  if (params.contains(raw)) return {'arg': raw};
  final isMatch = RegExp(
    r'^(.+)\s+is\s+([A-Za-z_:][A-Za-z0-9_:]*)$',
  ).firstMatch(raw);
  if (isMatch != null) {
    final value = _sourceExpr(isMatch.group(1)!.trim(), params);
    final type = fcbNormalizeSimpleTypeName(isMatch.group(2)!);
    if (value != null && type != null) {
      return {
        'is_type': {'value': value, 'type': type},
      };
    }
  }
  final asMatch = RegExp(
    r'^(.+)\s+as\s+([A-Za-z_:][A-Za-z0-9_:]*)$',
  ).firstMatch(raw);
  if (asMatch != null) {
    final value = _sourceExpr(asMatch.group(1)!.trim(), params);
    final type = fcbNormalizeSimpleTypeName(asMatch.group(2)!);
    if (value != null && type != null) {
      return {
        'as_type': {'value': value, 'type': type},
      };
    }
  }
  final call = RegExp(r'^([A-Za-z_$][A-Za-z0-9_$]*)\((.*)\)$').firstMatch(raw);
  if (call != null) {
    final argsRaw = call.group(2)!.trim();
    final args = <Map<String, Object?>>[];
    if (argsRaw.isNotEmpty) {
      for (final part in argsRaw.split(',')) {
        final arg = _sourceExpr(part.trim(), params);
        if (arg == null) return null;
        args.add(arg);
      }
    }
    return {'call_static': call.group(1)!, 'args': args};
  }
  return null;
}

String _location(TreeNode node) {
  final location = node.location;
  if (location == null) return '';
  return '${location.file}:${location.line}:${location.column}';
}

String _hash(Object value) {
  final bytes = utf8.encode(value.toString());
  var hash = BigInt.parse('cbf29ce484222325', radix: 16);
  final prime = BigInt.parse('100000001b3', radix: 16);
  final mask = BigInt.parse('ffffffffffffffff', radix: 16);
  for (final byte in bytes) {
    hash = hash ^ BigInt.from(byte);
    hash = (hash * prime) & mask;
  }
  return hash.toRadixString(16).padLeft(16, '0');
}
