part of 'fcb_kernel_manifest.dart';

const _opLoadConst = 0x01;
const _opLoadArg = 0x02;
const _opLoadLocal = 0x03;
const _opStoreLocal = 0x04;
const _opPop = 0x05;
const _opAdd = 0x10;
const _opSub = 0x11;
const _opMul = 0x12;
const _opDiv = 0x13;
const _opGreater = 0x20;
const _opEqual = 0x21;
const _opJump = 0x30;
const _opJumpIfFalse = 0x31;
const _opMakeList = 0x40;
const _opMakeMap = 0x41;
const _opStringConcat = 0x42;
const _opGetField = 0x43;
const _opSetField = 0x44;
const _opIsType = 0x45;
const _opAsType = 0x46;
const _opCallStatic = 0x50;
const _opCallDynamic = 0x51;
const _opCallOriginal = 0x52;
const _opCallClosure = 0x53;
const _opMakeClosure = 0x54;
const _opNewObject = 0x55;
const _opThrow = 0x60;
const _opTryBegin = 0x61;
const _opAwait = 0x62;
const _opAsyncReturn = 0x63;
const _opYield = 0x64;
const _opTryFinally = 0x65;
const _opEndFinally = 0x66;
const _opReturn = 0xff;

class _RestrictedBytecodeCompiler {
  _RestrictedBytecodeCompiler(List<String> params)
    : args = {for (var i = 0; i < params.length; i++) params[i]: i},
      debugLocals = [
        for (var i = 0; i < params.length; i++) {'slot': i, 'name': params[i]},
      ],
      localCount = params.length + 1;

  final Map<String, int> args;
  final List<Map<String, Object?>> debugLocals;
  final List<Map<String, Object?>> constants = [];
  final Map<String, int> constantIndexes = {};
  final Map<int, int> scopedLocals = {};
  final List<int> code = [];
  int localCount;

  void compileExpr(Map<String, Object?> expr) {
    if (expr.containsKey('int')) {
      loadConst({'type': 'Int', 'value': expr['int']});
    } else if (expr.containsKey('double')) {
      loadConst({'type': 'Double', 'value': expr['double']});
    } else if (expr.containsKey('bool')) {
      loadConst({'type': 'Bool', 'value': expr['bool']});
    } else if (expr.containsKey('string')) {
      loadConst({'type': 'String', 'value': expr['string']});
    } else if (expr['null'] == true) {
      loadConst({'type': 'Null', 'value': null});
    } else if (expr['arg'] is String) {
      final index = args[expr['arg'] as String];
      if (index == null) {
        stderr.writeln('unknown parameter ${expr['arg']}');
        exit(2);
      }
      op(_opLoadArg);
      u8(index);
    } else if (expr['let_local'] is int) {
      final index = scopedLocals[expr['let_local'] as int];
      if (index == null) {
        stderr.writeln('unknown let local ${expr['let_local']}');
        exit(2);
      }
      op(_opLoadLocal);
      u8(index);
    } else if (expr['let'] is Map) {
      this.compileLet((expr['let'] as Map).cast<String, Object?>());
    } else if (expr['set_local'] is Map) {
      this.compileSetLocal((expr['set_local'] as Map).cast<String, Object?>());
    } else if (expr['while_loop'] is Map) {
      this.compileWhileLoop(
        (expr['while_loop'] as Map).cast<String, Object?>(),
      );
    } else if (expr['op'] is String) {
      final left = expr['left'];
      final right = expr['right'];
      if (left is! Map || right is! Map) {
        stderr.writeln('binary expression requires left and right operands');
        exit(2);
      }
      if (expr['op'] == '<') {
        compileExpr(right.cast<String, Object?>());
        compileExpr(left.cast<String, Object?>());
        op(_opGreater);
        return;
      }
      compileExpr(left.cast<String, Object?>());
      compileExpr(right.cast<String, Object?>());
      op(switch (expr['op']) {
        '+' => _opAdd,
        '-' => _opSub,
        '*' => _opMul,
        '/' => _opDiv,
        '>' => _opGreater,
        '==' => _opEqual,
        _ => _unsupportedOperator(expr['op']),
      });
    } else if (expr['conditional'] is Map) {
      final conditional = (expr['conditional'] as Map).cast<String, Object?>();
      final condition = conditional['condition'];
      final thenExpr = conditional['then'];
      final elseExpr = conditional['else'];
      if (condition is! Map || thenExpr is! Map || elseExpr is! Map) {
        stderr.writeln('conditional expression requires condition/then/else');
        exit(2);
      }
      compileExpr(condition.cast<String, Object?>());
      op(_opJumpIfFalse);
      final elsePatch = reserveU16();
      compileExpr(thenExpr.cast<String, Object?>());
      op(_opJump);
      final endPatch = reserveU16();
      patchU16(elsePatch, code.length);
      compileExpr(elseExpr.cast<String, Object?>());
      patchU16(endPatch, code.length);
    } else if (expr['throw'] is Map) {
      compileExpr((expr['throw'] as Map).cast<String, Object?>());
      op(_opThrow);
    } else if (expr['seq'] is List) {
      // Statement sequence: compile each element, discarding the value of all
      // but the last so the sequence evaluates to its final expression. Used for
      // multi-statement bodies (notably generators with several `yield`s).
      final items = (expr['seq'] as List)
          .whereType<Map>()
          .map((item) => item.cast<String, Object?>())
          .toList(growable: false);
      if (items.isEmpty) {
        loadConst({'type': 'Null', 'value': null});
      } else {
        for (var i = 0; i < items.length; i++) {
          compileExpr(items[i]);
          if (i != items.length - 1) {
            op(_opPop);
          }
        }
      }
    } else if (expr['yield'] is Map) {
      // `yield e` in a sync*/async* body: push the element, then Yield (which
      // pops it and suspends the generator). As an expression node it evaluates
      // to null so it composes inside `let`/sequencing constructs.
      compileExpr((expr['yield'] as Map).cast<String, Object?>());
      op(_opYield);
      loadConst({'type': 'Null', 'value': null});
    } else if (expr['yield_for_in'] is Map) {
      this.compileYieldForIn(
        (expr['yield_for_in'] as Map).cast<String, Object?>(),
      );
    } else if (expr['await'] is Map) {
      compileExpr((expr['await'] as Map).cast<String, Object?>());
      op(_opAwait);
    } else if (expr['try_finally'] is Map) {
      this.compileTryFinally(
        (expr['try_finally'] as Map).cast<String, Object?>(),
      );
    } else if (expr['try_catch'] is Map) {
      this.compileTryCatch((expr['try_catch'] as Map).cast<String, Object?>());
    } else if (expr['call_static'] is String) {
      final args = expr['args'];
      if (args is! List) {
        stderr.writeln('call_static expression requires args list');
        exit(2);
      }
      if (args.length > 255) {
        stderr.writeln('call_static expression has more than 255 arguments');
        exit(2);
      }
      for (final arg in args) {
        if (arg is! Map) {
          stderr.writeln('call_static argument must be an expression');
          exit(2);
        }
        compileExpr(arg.cast<String, Object?>());
      }
      final calleeIndex = addConst({
        'type': 'String',
        'value': expr['call_static'],
      });
      op(_opCallStatic);
      u16(calleeIndex);
      u8(args.length);
    } else if (expr['call_original'] is String) {
      final args = expr['args'];
      if (args is! List) {
        stderr.writeln('call_original expression requires args list');
        exit(2);
      }
      if (args.length > 255) {
        stderr.writeln('call_original expression has more than 255 arguments');
        exit(2);
      }
      for (final arg in args) {
        if (arg is! Map) {
          stderr.writeln('call_original argument must be an expression');
          exit(2);
        }
        compileExpr(arg.cast<String, Object?>());
      }
      final calleeIndex = addConst({
        'type': 'String',
        'value': expr['call_original'],
      });
      op(_opCallOriginal);
      u16(calleeIndex);
      u8(args.length);
    } else if (expr['call_dynamic'] is Map) {
      final spec = (expr['call_dynamic'] as Map).cast<String, Object?>();
      final receiver = spec['receiver'];
      final method = spec['method'];
      final args = spec['args'];
      final namedArgs = spec['named_args'];
      if (receiver is! Map || method is! String || method.trim().isEmpty) {
        stderr.writeln('call_dynamic expression requires receiver and method');
        exit(2);
      }
      if (args is! List) {
        stderr.writeln('call_dynamic expression requires args list');
        exit(2);
      }
      final parsedNamedArgs = <Map<String, Object?>>[];
      if (namedArgs != null) {
        if (namedArgs is! List) {
          stderr.writeln('call_dynamic named_args must be a list');
          exit(2);
        }
        for (final arg in namedArgs) {
          if (arg is! Map) {
            stderr.writeln('call_dynamic named argument must be an object');
            exit(2);
          }
          final typedArg = arg.cast<String, Object?>();
          if (typedArg['name'] is! String || typedArg['value'] is! Map) {
            stderr.writeln('call_dynamic named argument requires name/value');
            exit(2);
          }
          parsedNamedArgs.add(typedArg);
        }
      }
      final totalArgs = args.length + parsedNamedArgs.length;
      if (totalArgs > 255) {
        stderr.writeln('call_dynamic expression has more than 255 arguments');
        exit(2);
      }
      compileExpr(receiver.cast<String, Object?>());
      for (final arg in args) {
        if (arg is! Map) {
          stderr.writeln('call_dynamic argument must be an expression');
          exit(2);
        }
        compileExpr(arg.cast<String, Object?>());
      }
      for (final arg in parsedNamedArgs) {
        compileExpr((arg['value'] as Map).cast<String, Object?>());
      }
      final namedSuffix = parsedNamedArgs.isEmpty
          ? ''
          : ';named:${parsedNamedArgs.map((arg) => arg['name']).join(',')}';
      op(_opCallDynamic);
      u16(addConst({'type': 'String', 'value': '$method$namedSuffix'}));
      u8(totalArgs);
    } else if (expr['call_closure'] is Map) {
      final spec = (expr['call_closure'] as Map).cast<String, Object?>();
      final closure = spec['closure'];
      final args = spec['args'];
      final namedArgs = spec['named_args'];
      if (closure is! Map) {
        stderr.writeln('call_closure expression requires closure');
        exit(2);
      }
      if (args is! List) {
        stderr.writeln('call_closure expression requires args list');
        exit(2);
      }
      final parsedNamedArgs = <Map<String, Object?>>[];
      if (namedArgs != null) {
        if (namedArgs is! List) {
          stderr.writeln('call_closure named_args must be a list');
          exit(2);
        }
        for (final arg in namedArgs) {
          if (arg is! Map) {
            stderr.writeln('call_closure named argument must be an object');
            exit(2);
          }
          final typedArg = arg.cast<String, Object?>();
          if (typedArg['name'] is! String || typedArg['value'] is! Map) {
            stderr.writeln('call_closure named argument requires name/value');
            exit(2);
          }
          parsedNamedArgs.add(typedArg);
        }
      }
      final totalArgs = args.length + parsedNamedArgs.length;
      if (totalArgs > 255) {
        stderr.writeln('call_closure expression has more than 255 arguments');
        exit(2);
      }
      compileExpr(closure.cast<String, Object?>());
      for (final arg in args) {
        if (arg is! Map) {
          stderr.writeln('call_closure argument must be an expression');
          exit(2);
        }
        compileExpr(arg.cast<String, Object?>());
      }
      for (final arg in parsedNamedArgs) {
        compileExpr((arg['value'] as Map).cast<String, Object?>());
      }
      var metadataOperand = 0;
      if (parsedNamedArgs.isNotEmpty) {
        final metadataIndex = addConst({
          'type': 'String',
          'value':
              ';named:${parsedNamedArgs.map((arg) => arg['name']).join(',')}',
        });
        if (metadataIndex == 0xffff) {
          stderr.writeln(
            'call_closure metadata constant exceeds operand space',
          );
          exit(2);
        }
        metadataOperand = metadataIndex + 1;
      }
      op(_opCallClosure);
      u16(metadataOperand);
      u8(totalArgs);
    } else if (expr['make_closure'] is String || expr['make_closure'] is Map) {
      final raw = expr['make_closure'];
      String target;
      final captures = <Map<String, Object?>>[];
      final namedParameters = <String>[];
      var optionalPositionalCount = 0;
      var typeParameterCount = 0;
      if (raw is String) {
        target = raw;
      } else if (raw is Map) {
        final spec = raw.cast<String, Object?>();
        final specTarget = spec['target'];
        final specCaptures = spec['captures'];
        final specNamedParameters = spec['named_parameters'];
        final specOptionalPositionalCount = spec['optional_positional_count'];
        final specTypeParameterCount = spec['type_parameter_count'];
        if (specTarget is! String) {
          stderr.writeln('make_closure expression requires target');
          exit(2);
        }
        target = specTarget;
        if (specOptionalPositionalCount != null) {
          if (specOptionalPositionalCount is! int ||
              specOptionalPositionalCount < 0 ||
              specOptionalPositionalCount > 255) {
            stderr.writeln(
              'make_closure optional_positional_count must be 0..255',
            );
            exit(2);
          }
          optionalPositionalCount = specOptionalPositionalCount;
        }
        if (specNamedParameters != null) {
          if (specNamedParameters is! List) {
            stderr.writeln('make_closure named_parameters must be a list');
            exit(2);
          }
          for (final parameter in specNamedParameters) {
            if (parameter is! String || parameter.trim().isEmpty) {
              stderr.writeln(
                'make_closure named parameter must be a non-empty string',
              );
              exit(2);
            }
            namedParameters.add(parameter);
          }
        }
        if (specTypeParameterCount != null) {
          if (specTypeParameterCount is! int ||
              specTypeParameterCount < 0 ||
              specTypeParameterCount > 255) {
            stderr.writeln('make_closure type_parameter_count must be 0..255');
            exit(2);
          }
          typeParameterCount = specTypeParameterCount;
        }
        if (specCaptures != null) {
          if (specCaptures is! List) {
            stderr.writeln('make_closure captures must be a list');
            exit(2);
          }
          if (specCaptures.length > 255) {
            stderr.writeln('make_closure captures exceed operand space');
            exit(2);
          }
          for (final capture in specCaptures) {
            if (capture is! Map) {
              stderr.writeln('make_closure capture must be an expression');
              exit(2);
            }
            captures.add(capture.cast<String, Object?>());
          }
        }
      } else {
        stderr.writeln('make_closure expression requires target');
        exit(2);
      }
      if (target.trim().isEmpty) {
        stderr.writeln('make_closure expression requires target');
        exit(2);
      }
      for (final capture in captures) {
        compileExpr(capture);
      }
      if (optionalPositionalCount > 0 && namedParameters.isNotEmpty) {
        stderr.writeln(
          'make_closure cannot mix optional positional and named parameters',
        );
        exit(2);
      }
      final optionalPositionalSuffix = optionalPositionalCount == 0
          ? ''
          : ';optional-pos:$optionalPositionalCount';
      final namedSuffix = namedParameters.isEmpty
          ? ''
          : ';named:${namedParameters.join(',')}';
      final typeParameterSuffix = typeParameterCount == 0
          ? ''
          : ';type-params:$typeParameterCount';
      final metadataSuffix =
          '$optionalPositionalSuffix$namedSuffix$typeParameterSuffix';
      final targetValue = captures.isEmpty
          ? (metadataSuffix.isEmpty
                ? target
                : '$target;captures:0$metadataSuffix')
          : '$target;captures:${captures.length}$metadataSuffix';
      op(_opMakeClosure);
      u16(addConst({'type': 'String', 'value': targetValue}));
    } else if (expr['new_object'] is Map) {
      final spec = (expr['new_object'] as Map).cast<String, Object?>();
      final constructor = spec['constructor'];
      final args = spec['args'];
      final namedArgs = spec['named_args'];
      final typeArgs = spec['type_args'];
      if (constructor is! String || constructor.trim().isEmpty) {
        stderr.writeln('new_object expression requires constructor');
        exit(2);
      }
      if (args is! List) {
        stderr.writeln('new_object expression requires args list');
        exit(2);
      }
      if (args.length > 255) {
        stderr.writeln('new_object expression has more than 255 arguments');
        exit(2);
      }
      final namedNames = <String>[];
      final typeNames = <String>[];
      for (final arg in args) {
        if (arg is! Map) {
          stderr.writeln('new_object argument must be an expression');
          exit(2);
        }
        compileExpr(arg.cast<String, Object?>());
      }
      if (typeArgs != null) {
        if (typeArgs is! List) {
          stderr.writeln('new_object type_args must be a list');
          exit(2);
        }
        for (final typeArg in typeArgs) {
          if (typeArg is! String || typeArg.trim().isEmpty) {
            stderr.writeln('new_object type arg must be a non-empty string');
            exit(2);
          }
          typeNames.add(typeArg);
        }
      }
      if (namedArgs != null) {
        if (namedArgs is! List) {
          stderr.writeln('new_object named_args must be a list');
          exit(2);
        }
        if (args.length + namedArgs.length > 255) {
          stderr.writeln('new_object expression has more than 255 arguments');
          exit(2);
        }
        for (final item in namedArgs) {
          if (item is! Map) {
            stderr.writeln('new_object named arg must be an object');
            exit(2);
          }
          final namedArg = item.cast<String, Object?>();
          final name = namedArg['name'];
          final value = namedArg['value'];
          if (name is! String || name.trim().isEmpty || value is! Map) {
            stderr.writeln('new_object named arg requires name and value');
            exit(2);
          }
          namedNames.add(name);
          compileExpr(value.cast<String, Object?>());
        }
      }
      final constructorValue =
          '$constructor'
          '${typeNames.isEmpty ? "" : ";types:${typeNames.join(",")}"}'
          '${namedNames.isEmpty ? "" : ";named:${namedNames.join(",")}"}';
      op(_opNewObject);
      u16(addConst({'type': 'String', 'value': constructorValue}));
      u8(args.length + namedNames.length);
    } else if (expr['concat'] is List) {
      final parts = expr['concat'] as List;
      if (parts.length > 0xffff) {
        stderr.writeln('string concat expression has too many parts');
        exit(2);
      }
      for (final part in parts) {
        if (part is! Map) {
          stderr.writeln('string concat part must be an expression');
          exit(2);
        }
        compileExpr(part.cast<String, Object?>());
      }
      op(_opStringConcat);
      u16(parts.length);
    } else if (expr['list'] is List) {
      final items = expr['list'] as List;
      if (items.length > 0xffff) {
        stderr.writeln('list expression has too many items');
        exit(2);
      }
      for (final item in items) {
        if (item is! Map) {
          stderr.writeln('list item must be an expression');
          exit(2);
        }
        compileExpr(item.cast<String, Object?>());
      }
      op(_opMakeList);
      u16(items.length);
    } else if (expr['list_add_all'] is Map) {
      final spec = (expr['list_add_all'] as Map).cast<String, Object?>();
      final receiver = spec['receiver'];
      final spread = spec['spread'];
      if (receiver is! Map || spread is! Map) {
        stderr.writeln('list_add_all expression requires receiver and spread');
        exit(2);
      }
      final local = allocateLocal();
      compileExpr(receiver.cast<String, Object?>());
      op(_opStoreLocal);
      u8(local);
      op(_opLoadLocal);
      u8(local);
      compileExpr(spread.cast<String, Object?>());
      op(_opCallDynamic);
      u16(addConst({'type': 'String', 'value': 'addAll'}));
      u8(1);
      op(_opLoadLocal);
      u8(local);
    } else if (expr['list_for_in'] is Map) {
      this.compileListForIn(
        (expr['list_for_in'] as Map).cast<String, Object?>(),
      );
    } else if (expr['map'] is List) {
      final entries = expr['map'] as List;
      if (entries.length > 0xffff) {
        stderr.writeln('map expression has too many entries');
        exit(2);
      }
      for (final entry in entries) {
        if (entry is! Map) {
          stderr.writeln('map entry must be an object');
          exit(2);
        }
        final typedEntry = entry.cast<String, Object?>();
        final key = typedEntry['key'];
        final value = typedEntry['value'];
        if (key is! Map || value is! Map) {
          stderr.writeln('map entry requires key and value expressions');
          exit(2);
        }
        compileExpr(key.cast<String, Object?>());
        compileExpr(value.cast<String, Object?>());
      }
      op(_opMakeMap);
      u16(entries.length);
    } else if (expr['map_add_all'] is Map) {
      final spec = (expr['map_add_all'] as Map).cast<String, Object?>();
      final receiver = spec['receiver'];
      final spread = spec['spread'];
      if (receiver is! Map || spread is! Map) {
        stderr.writeln('map_add_all expression requires receiver and spread');
        exit(2);
      }
      final local = allocateLocal();
      compileExpr(receiver.cast<String, Object?>());
      op(_opStoreLocal);
      u8(local);
      op(_opLoadLocal);
      u8(local);
      compileExpr(spread.cast<String, Object?>());
      op(_opCallDynamic);
      u16(addConst({'type': 'String', 'value': 'addAll'}));
      u8(1);
      op(_opLoadLocal);
      u8(local);
    } else if (expr['map_for_in'] is Map) {
      this.compileMapForIn((expr['map_for_in'] as Map).cast<String, Object?>());
    } else if (expr['get_field'] is Map) {
      final spec = (expr['get_field'] as Map).cast<String, Object?>();
      final receiver = spec['receiver'];
      final field = spec['field'];
      if (receiver is! Map || field is! String || field.trim().isEmpty) {
        stderr.writeln('get_field expression requires receiver and field');
        exit(2);
      }
      compileExpr(receiver.cast<String, Object?>());
      op(_opGetField);
      u16(addConst({'type': 'String', 'value': field}));
    } else if (expr['set_field'] is Map) {
      final spec = (expr['set_field'] as Map).cast<String, Object?>();
      final receiver = spec['receiver'];
      final value = spec['value'];
      final field = spec['field'];
      if (receiver is! Map ||
          value is! Map ||
          field is! String ||
          field.trim().isEmpty) {
        stderr.writeln('set_field expression requires receiver, field, value');
        exit(2);
      }
      compileExpr(receiver.cast<String, Object?>());
      compileExpr(value.cast<String, Object?>());
      op(_opSetField);
      u16(addConst({'type': 'String', 'value': field}));
    } else if (expr['is_type'] is Map) {
      final spec = (expr['is_type'] as Map).cast<String, Object?>();
      final value = spec['value'];
      final type = spec['type'];
      if (value is! Map || type is! String || type.trim().isEmpty) {
        stderr.writeln('is_type expression requires value and type');
        exit(2);
      }
      compileExpr(value.cast<String, Object?>());
      op(_opIsType);
      u16(addConst({'type': 'String', 'value': type}));
    } else if (expr['as_type'] is Map) {
      final spec = (expr['as_type'] as Map).cast<String, Object?>();
      final value = spec['value'];
      final type = spec['type'];
      if (value is! Map || type is! String || type.trim().isEmpty) {
        stderr.writeln('as_type expression requires value and type');
        exit(2);
      }
      compileExpr(value.cast<String, Object?>());
      op(_opAsType);
      u16(addConst({'type': 'String', 'value': type}));
    } else {
      stderr.writeln(
        'unsupported restricted bytecode expression: ${jsonEncode(expr)}',
      );
      exit(2);
    }
  }

  void loadConst(Map<String, Object?> constant) {
    final index = addConst(constant);
    op(_opLoadConst);
    u16(index);
  }

  int addConst(Map<String, Object?> constant) {
    final key = jsonEncode(constant);
    final existing = constantIndexes[key];
    if (existing != null) return existing;
    final index = constants.length;
    if (index > 0xffff) {
      stderr.writeln('bytecode constant pool exceeds u16 index space');
      exit(2);
    }
    constants.add(constant);
    constantIndexes[key] = index;
    return index;
  }

  void op(int opcode) {
    code.add(opcode);
  }

  int allocateLocal() {
    if (localCount >= 256) {
      stderr.writeln('bytecode local count exceeds u8 index space');
      exit(2);
    }
    return localCount++;
  }

  void u8(int value) {
    code.add(value & 0xff);
  }

  void u16(int value) {
    code.add((value >> 8) & 0xff);
    code.add(value & 0xff);
  }

  int reserveU16() {
    final offset = code.length;
    code.addAll([0, 0]);
    return offset;
  }

  void patchU16(int offset, int value) {
    if (value > 0xffff) {
      stderr.writeln('bytecode jump target exceeds u16 range');
      exit(2);
    }
    code[offset] = (value >> 8) & 0xff;
    code[offset + 1] = value & 0xff;
  }
}

Never _unsupportedOperator(Object? op) {
  stderr.writeln('unsupported bytecode binary operator $op');
  exit(2);
}
