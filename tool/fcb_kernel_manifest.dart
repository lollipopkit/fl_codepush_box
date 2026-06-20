import 'dart:convert';
import 'dart:io';

import 'fcb_binary_module_writer.dart';
import 'fcb_kernel_reader_bundle.dart';

Future<void> main(List<String> args) async {
  final project = _arg(args, '--project') ?? '.';
  final target = _arg(args, '--target') ?? 'lib/main.dart';
  final explicitDill = _arg(args, '--dill');
  final compileFromPlan = _arg(args, '--compile-from-plan');
  final patchDill = _arg(args, '--patch') ?? explicitDill;
  final outPath = _arg(args, '-o') ?? _arg(args, '--out');
  final outputFormat = _arg(args, '--format') ?? 'json';
  final root = Directory(
    Directory(project).absolute.resolveSymbolicLinksSync(),
  );
  if (!File('${root.path}/pubspec.yaml').existsSync()) {
    stderr.writeln('project has no pubspec.yaml: ${root.path}');
    exit(2);
  }

  final packageName = _packageName(root);
  final temp = Directory.systemTemp.createTempSync('fcb_kernel_manifest_');
  try {
    if (compileFromPlan != null) {
      if (patchDill == null) {
        stderr.writeln('--compile-from-plan requires --patch <app.dill>');
        exit(2);
      }
      final inventoryJson = await _kernelInventoryJson(
        root: root,
        target: target,
        explicitDill: patchDill,
        packageName: packageName,
        temp: temp,
      );
      final module = _compileModuleFromPlan(
        plan: jsonDecode(File(compileFromPlan).readAsStringSync()),
        inventory: jsonDecode(inventoryJson),
      );
      if (outputFormat == 'json') {
        final encoded = jsonEncode(module);
        if (outPath == null) {
          stdout.write(encoded);
        } else {
          File(outPath)
            ..parent.createSync(recursive: true)
            ..writeAsStringSync(encoded);
        }
      } else if (outputFormat == 'binary') {
        final encoded = encodeBinaryModule(module);
        if (outPath == null) {
          stdout.add(encoded);
        } else {
          File(outPath)
            ..parent.createSync(recursive: true)
            ..writeAsBytesSync(encoded);
        }
      } else {
        stderr.writeln('unsupported --format $outputFormat');
        exit(2);
      }
    } else {
      stdout.write(
        await _kernelInventoryJson(
          root: root,
          target: target,
          explicitDill: explicitDill,
          packageName: packageName,
          temp: temp,
        ),
      );
    }
  } finally {
    temp.deleteSync(recursive: true);
  }
}

String? _arg(List<String> args, String name) {
  final idx = args.indexOf(name);
  if (idx < 0 || idx + 1 >= args.length) return null;
  return args[idx + 1];
}

Future<String> _kernelInventoryJson({
  required Directory root,
  required String target,
  required String? explicitDill,
  required String packageName,
  required Directory temp,
}) async {
  final dill = explicitDill != null
      ? File(explicitDill).absolute
      : await _resolveDill(root, target, temp);
  final sdkRoot = _sdkRoot();
  final packageConfig = _writeKernelPackageConfig(temp, sdkRoot);
  final reader = writeKernelReaderBundle(temp);
  final result = await Process.run(Platform.resolvedExecutable, [
    '--packages=${packageConfig.path}',
    reader.path,
    dill.path,
    root.path,
    target,
    packageName,
  ]);
  if (result.exitCode != 0) {
    stderr.write(result.stderr);
    exit(result.exitCode);
  }
  return result.stdout.toString();
}

String _packageName(Directory root) {
  final pubspec = File('${root.path}/pubspec.yaml');
  final match = RegExp(
    r'^name:\s*([A-Za-z0-9_]+)\s*$',
    multiLine: true,
  ).firstMatch(pubspec.readAsStringSync());
  return match?.group(1) ?? 'app';
}

Future<File> _resolveDill(Directory root, String target, Directory temp) async {
  final existing = _newestNonEmptyAppDill(root);
  if (existing != null) {
    stderr.writeln(
      'warning: using Flutter app.dill ${existing.path}; ensure it matches the current build config',
    );
    return existing;
  }

  stderr.writeln(
    'warning: using fallback Kernel; .dart_tool/flutter_build/**/app.dill not found',
  );
  final out = File('${temp.path}/app.dill');
  final targetFile = File('${root.path}/$target').absolute;
  final wrapper = File('${temp.path}/fcb_entry.dart')
    ..writeAsStringSync("import '${targetFile.uri}';\nvoid main() {}\n");
  final args = <String>[
    'compile',
    'kernel',
    '--no-link-platform',
    '-o',
    out.path,
  ];
  final packageConfig = File('${root.path}/.dart_tool/package_config.json');
  if (packageConfig.existsSync()) {
    args.add('--packages=${packageConfig.path}');
  }
  args.add(wrapper.path);
  final result = await Process.run(
    Platform.resolvedExecutable,
    args,
    workingDirectory: root.path,
  );
  if (result.exitCode != 0 || !out.existsSync() || out.lengthSync() == 0) {
    stderr.write(result.stdout);
    stderr.write(result.stderr);
    exit(result.exitCode == 0 ? 2 : result.exitCode);
  }
  return out;
}

File? _newestNonEmptyAppDill(Directory root) {
  final buildRoot = Directory('${root.path}/.dart_tool/flutter_build');
  if (!buildRoot.existsSync()) return null;
  final candidates =
      buildRoot
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('/app.dill'))
          .where((file) => file.lengthSync() > 0)
          .toList()
        ..sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
  return candidates.isEmpty ? null : candidates.first;
}

Directory _sdkRoot() {
  final env = Platform.environment['FCB_KERNEL_SDK_ROOT'];
  if (env != null && Directory(env).existsSync()) return Directory(env);
  for (final base in [
    Directory.current,
    File.fromUri(Platform.script).parent,
  ]) {
    var dir = base.absolute;
    while (true) {
      final candidate = Directory(
        '${dir.path}/vendor/flutter/engine/src/flutter/third_party/dart',
      );
      if (candidate.existsSync()) return candidate;
      final parent = dir.parent;
      if (parent.path == dir.path) break;
      dir = parent;
    }
  }
  stderr.writeln(
    'missing vendor/flutter/engine/src/flutter/third_party/dart; '
    'set FCB_KERNEL_SDK_ROOT',
  );
  exit(2);
}

File _writeKernelPackageConfig(Directory temp, Directory sdkRoot) {
  final file = File('${temp.path}/package_config.json');
  final packages = [
    _package('kernel', '${sdkRoot.path}/pkg/kernel'),
    _package('_fe_analyzer_shared', '${sdkRoot.path}/pkg/_fe_analyzer_shared'),
  ];
  file.writeAsStringSync(
    jsonEncode({'configVersion': 2, 'packages': packages}),
  );
  return file;
}

Map<String, Object?> _package(String name, String rootUri) {
  return {
    'name': name,
    'rootUri': rootUri,
    'packageUri': 'lib/',
    'languageVersion': '3.12',
  };
}

Map<String, Object?> _compileModuleFromPlan({
  required Object? plan,
  required Object? inventory,
}) {
  if (plan is! Map || inventory is! Map) {
    stderr.writeln('plan and inventory must be JSON objects');
    exit(2);
  }
  final functions = <String, Map<String, Object?>>{};
  for (final item in (inventory['functions'] as List? ?? const [])) {
    if (item is Map && item['function_id'] is String) {
      functions[item['function_id'] as String] = item.cast<String, Object?>();
    }
  }

  final compiled = <Map<String, Object?>>[];
  for (final decision in (plan['interpret'] as List? ?? const [])) {
    if (decision is! Map || decision['function_id'] is! String) {
      stderr.writeln('linker plan interpret entry is missing function_id');
      exit(2);
    }
    final functionId = decision['function_id'] as String;
    final function = functions[functionId];
    if (function == null) {
      stderr.writeln('linker selected missing function $functionId');
      exit(2);
    }
    final source = function['bytecode_source'];
    if (source is! Map) {
      stderr.writeln('function $functionId has no bytecode_source');
      exit(2);
    }
    final typedSource = source.cast<String, Object?>();
    compiled.add(
      _compileSourceFunction(
        typedSource,
        decision['source_location']?.toString() ??
            function['source_location']?.toString(),
      ),
    );
    final extraFunctions = typedSource['extra_functions'];
    if (extraFunctions != null) {
      if (extraFunctions is! List) {
        stderr.writeln('bytecode source extra_functions must be a list');
        exit(2);
      }
      for (final extra in extraFunctions) {
        if (extra is! Map) {
          stderr.writeln('bytecode source extra function must be an object');
          exit(2);
        }
        compiled.add(
          _compileSourceFunction(extra.cast<String, Object?>(), null),
        );
      }
    }
  }

  if (compiled.isEmpty) {
    stderr.writeln('linker plan has no interpreted functions to compile');
    exit(2);
  }
  return {'version': 3, 'functions': compiled};
}

Map<String, Object?> _compileSourceFunction(
  Map<String, Object?> source,
  String? sourceLocation,
) {
  final name = source['name'];
  final params = (source['params'] as List? ?? const [])
      .map((value) => value.toString())
      .toList(growable: false);
  final body = source['body'];
  if (name is! String || name.trim().isEmpty || body is! Map) {
    stderr.writeln('bytecode source function requires name and body');
    exit(2);
  }
  if (params.length > 255) {
    stderr.writeln('bytecode function $name has more than 255 parameters');
    exit(2);
  }

  final compiler = _RestrictedBytecodeCompiler(params);
  compiler.compileExpr(body.cast<String, Object?>());
  final asyncKindSource = source['async_kind']?.toString();
  final isSyncStar =
      asyncKindSource == 'sync_star' || source['sync_star'] == true;
  final isAsyncStar =
      asyncKindSource == 'async_star' || source['async_star'] == true;
  final isAsyncFuture =
      !isSyncStar &&
      !isAsyncStar &&
      (asyncKindSource == 'async_future' ||
          source['async_future'] == true ||
          source['async_future_value'] == true);
  // Generators (sync*/async*) end on a plain Return that closes the iterator;
  // only async (Future) functions wrap their result via AsyncReturn.
  compiler.op(isAsyncFuture ? _opAsyncReturn : _opReturn);
  final returnConvention = _returnConventionForSource(source);
  final asyncKind = isSyncStar
      ? 'sync_star'
      : isAsyncStar
      ? 'async_star'
      : isAsyncFuture
      ? 'async_future'
      : 'sync';
  return {
    'name': name,
    'return_convention': returnConvention,
    'async_kind': asyncKind,
    'param_count': params.length,
    'local_count': compiler.localCount,
    'constants': compiler.constants,
    'code': compiler.code,
    if (compiler.debugLocals.isNotEmpty) 'debug_locals': compiler.debugLocals,
    if (sourceLocation != null && sourceLocation.trim().isNotEmpty)
      'source_map': [
        {'bytecode_offset': 0, 'source_location': sourceLocation},
      ],
  };
}

String _returnConventionForSource(Map<String, Object?> source) {
  final explicit = source['return_convention']?.toString();
  if (explicit == 'tagged' || explicit == 'unboxed_int64') {
    return explicit!;
  }
  if (source['return_type']?.toString() == 'int') {
    return 'unboxed_int64';
  }
  return 'tagged';
}

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
      compileLet((expr['let'] as Map).cast<String, Object?>());
    } else if (expr['set_local'] is Map) {
      compileSetLocal((expr['set_local'] as Map).cast<String, Object?>());
    } else if (expr['while_loop'] is Map) {
      compileWhileLoop((expr['while_loop'] as Map).cast<String, Object?>());
    } else if (expr['op'] is String) {
      final left = expr['left'];
      final right = expr['right'];
      if (left is! Map || right is! Map) {
        stderr.writeln('binary expression requires left and right operands');
        exit(2);
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
      compileYieldForIn((expr['yield_for_in'] as Map).cast<String, Object?>());
    } else if (expr['await'] is Map) {
      compileExpr((expr['await'] as Map).cast<String, Object?>());
      op(_opAwait);
    } else if (expr['try_finally'] is Map) {
      compileTryFinally((expr['try_finally'] as Map).cast<String, Object?>());
    } else if (expr['try_catch'] is Map) {
      compileTryCatch((expr['try_catch'] as Map).cast<String, Object?>());
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
      compileListForIn((expr['list_for_in'] as Map).cast<String, Object?>());
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
      compileMapForIn((expr['map_for_in'] as Map).cast<String, Object?>());
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

  void compileListForIn(Map<String, Object?> spec) {
    final receiver = spec['receiver'];
    final source = spec['source'];
    if (receiver is! Map || source is! Map) {
      stderr.writeln('list_for_in expression requires receiver and source');
      exit(2);
    }
    final resultLocal = allocateLocal();
    final iteratorLocal = allocateLocal();
    compileExpr(receiver.cast<String, Object?>());
    op(_opStoreLocal);
    u8(resultLocal);
    compileExpr(source.cast<String, Object?>());
    callDynamic('get:iterator', 0);
    op(_opStoreLocal);
    u8(iteratorLocal);
    final loopStart = code.length;
    op(_opLoadLocal);
    u8(iteratorLocal);
    callDynamic('moveNext', 0);
    op(_opJumpIfFalse);
    final endPatch = reserveU16();
    op(_opLoadLocal);
    u8(resultLocal);
    op(_opLoadLocal);
    u8(iteratorLocal);
    callDynamic('get:current', 0);
    callDynamic('add', 1);
    op(_opJump);
    u16(loopStart);
    patchU16(endPatch, code.length);
    op(_opLoadLocal);
    u8(resultLocal);
  }

  void compileMapForIn(Map<String, Object?> spec) {
    final receiver = spec['receiver'];
    final source = spec['source'];
    if (receiver is! Map || source is! Map) {
      stderr.writeln('map_for_in expression requires receiver and source');
      exit(2);
    }
    final resultLocal = allocateLocal();
    final iteratorLocal = allocateLocal();
    final entryLocal = allocateLocal();
    compileExpr(receiver.cast<String, Object?>());
    op(_opStoreLocal);
    u8(resultLocal);
    compileExpr(source.cast<String, Object?>());
    callDynamic('get:iterator', 0);
    op(_opStoreLocal);
    u8(iteratorLocal);
    final loopStart = code.length;
    op(_opLoadLocal);
    u8(iteratorLocal);
    callDynamic('moveNext', 0);
    op(_opJumpIfFalse);
    final endPatch = reserveU16();
    op(_opLoadLocal);
    u8(iteratorLocal);
    callDynamic('get:current', 0);
    op(_opStoreLocal);
    u8(entryLocal);
    op(_opLoadLocal);
    u8(resultLocal);
    op(_opLoadLocal);
    u8(entryLocal);
    callDynamic('get:key', 0);
    op(_opLoadLocal);
    u8(entryLocal);
    callDynamic('get:value', 0);
    callDynamic('[]=', 2);
    op(_opJump);
    u16(loopStart);
    patchU16(endPatch, code.length);
    op(_opLoadLocal);
    u8(resultLocal);
  }

  void compileYieldForIn(Map<String, Object?> spec) {
    final source = spec['source'];
    final local = spec['local'];
    final body = spec['body'];
    final beforeBreak = spec['before_break'];
    final breakCondition = spec['break_condition'];
    if (source is! Map) {
      stderr.writeln('yield_for_in expression requires source');
      exit(2);
    }
    if (beforeBreak != null && beforeBreak is! Map) {
      stderr.writeln('yield_for_in before_break must be an expression');
      exit(2);
    }
    if (breakCondition != null && breakCondition is! Map) {
      stderr.writeln('yield_for_in break_condition must be an expression');
      exit(2);
    }
    if (beforeBreak != null && breakCondition == null) {
      stderr.writeln('yield_for_in before_break requires break_condition');
      exit(2);
    }
    Map<String, Object?>? localSpec;
    if (local != null) {
      if (local is! Map) {
        stderr.writeln('yield_for_in local must be an object');
        exit(2);
      }
      localSpec = local.cast<String, Object?>();
      if (localSpec['id'] is! int || body is! Map) {
        stderr.writeln('yield_for_in local mode requires local id and body');
        exit(2);
      }
    } else if (body != null) {
      stderr.writeln('yield_for_in body requires local');
      exit(2);
    }
    final iteratorLocal = allocateLocal();
    final currentLocal = localSpec == null ? null : allocateLocal();
    compileExpr(source.cast<String, Object?>());
    callDynamic('get:iterator', 0);
    op(_opStoreLocal);
    u8(iteratorLocal);
    final loopStart = code.length;
    op(_opLoadLocal);
    u8(iteratorLocal);
    callDynamic('moveNext', 0);
    op(_opJumpIfFalse);
    final endPatch = reserveU16();
    op(_opLoadLocal);
    u8(iteratorLocal);
    callDynamic('get:current', 0);
    if (localSpec == null) {
      op(_opYield);
    } else {
      op(_opStoreLocal);
      u8(currentLocal!);
      final id = localSpec['id'] as int;
      final name = localSpec['name'];
      if (name is String && name.trim().isNotEmpty) {
        debugLocals.add({'slot': currentLocal, 'name': name.trim()});
      }
      final previous = scopedLocals[id];
      scopedLocals[id] = currentLocal;
      if (breakCondition is Map) {
        if (beforeBreak is Map) {
          compileExpr(beforeBreak.cast<String, Object?>());
          op(_opPop);
        }
        compileExpr(breakCondition.cast<String, Object?>());
        op(_opJumpIfFalse);
        final continuePatch = reserveU16();
        op(_opJump);
        final breakPatch = reserveU16();
        patchU16(continuePatch, code.length);
        compileExpr((body as Map).cast<String, Object?>());
        if (previous == null) {
          scopedLocals.remove(id);
        } else {
          scopedLocals[id] = previous;
        }
        op(_opPop);
        op(_opJump);
        u16(loopStart);
        patchU16(breakPatch, code.length);
        patchU16(endPatch, code.length);
        loadConst({'type': 'Null', 'value': null});
        return;
      }
      compileExpr((body as Map).cast<String, Object?>());
      if (previous == null) {
        scopedLocals.remove(id);
      } else {
        scopedLocals[id] = previous;
      }
      op(_opPop);
    }
    op(_opJump);
    u16(loopStart);
    patchU16(endPatch, code.length);
    loadConst({'type': 'Null', 'value': null});
  }

  void callDynamic(String method, int argc) {
    op(_opCallDynamic);
    u16(addConst({'type': 'String', 'value': method}));
    u8(argc);
  }

  void compileSetLocal(Map<String, Object?> spec) {
    final id = spec['id'];
    final value = spec['value'];
    if (id is! int || value is! Map) {
      stderr.writeln('set_local expression requires id and value');
      exit(2);
    }
    final index = scopedLocals[id];
    if (index == null) {
      stderr.writeln('unknown set_local target $id');
      exit(2);
    }
    compileExpr(value.cast<String, Object?>());
    op(_opStoreLocal);
    u8(index);
    loadConst({'type': 'Null', 'value': null});
  }

  void compileWhileLoop(Map<String, Object?> spec) {
    final condition = spec['condition'];
    final body = spec['body'];
    final beforeBreak = spec['before_break'];
    final breakCondition = spec['break_condition'];
    final beforeContinue = spec['before_continue'];
    final continueCondition = spec['continue_condition'];
    final continueBody = spec['continue_body'];
    if (condition is! Map || body is! Map) {
      stderr.writeln('while_loop expression requires condition and body');
      exit(2);
    }
    if (beforeBreak != null && beforeBreak is! Map) {
      stderr.writeln('while_loop before_break must be an expression');
      exit(2);
    }
    if (breakCondition != null && breakCondition is! Map) {
      stderr.writeln('while_loop break_condition must be an expression');
      exit(2);
    }
    if (beforeBreak != null && breakCondition == null) {
      stderr.writeln('while_loop before_break requires break_condition');
      exit(2);
    }
    if (beforeContinue != null && beforeContinue is! Map) {
      stderr.writeln('while_loop before_continue must be an expression');
      exit(2);
    }
    if (continueCondition != null && continueCondition is! Map) {
      stderr.writeln('while_loop continue_condition must be an expression');
      exit(2);
    }
    if (continueBody != null && continueBody is! Map) {
      stderr.writeln('while_loop continue_body must be an expression');
      exit(2);
    }
    if (beforeContinue != null && continueCondition == null) {
      stderr.writeln('while_loop before_continue requires continue_condition');
      exit(2);
    }
    if (continueCondition != null && continueBody == null) {
      stderr.writeln('while_loop continue_condition requires continue_body');
      exit(2);
    }
    final loopStart = code.length;
    compileExpr(condition.cast<String, Object?>());
    op(_opJumpIfFalse);
    final endPatch = reserveU16();
    if (continueCondition is Map) {
      if (beforeContinue is Map) {
        compileExpr(beforeContinue.cast<String, Object?>());
        op(_opPop);
      }
      compileExpr(continueCondition.cast<String, Object?>());
      op(_opJumpIfFalse);
      final bodyPatch = reserveU16();
      if ((continueBody as Map)['null'] != true) {
        compileExpr(continueBody.cast<String, Object?>());
        op(_opPop);
      }
      op(_opJump);
      u16(loopStart);
      patchU16(bodyPatch, code.length);
    }
    if (breakCondition is Map) {
      if (beforeBreak is Map) {
        compileExpr(beforeBreak.cast<String, Object?>());
        op(_opPop);
      }
      compileExpr(breakCondition.cast<String, Object?>());
      op(_opJumpIfFalse);
      final continuePatch = reserveU16();
      op(_opJump);
      final breakPatch = reserveU16();
      patchU16(continuePatch, code.length);
      compileExpr(body.cast<String, Object?>());
      op(_opPop);
      op(_opJump);
      u16(loopStart);
      patchU16(breakPatch, code.length);
      patchU16(endPatch, code.length);
      loadConst({'type': 'Null', 'value': null});
      return;
    }
    compileExpr(body.cast<String, Object?>());
    op(_opPop);
    op(_opJump);
    u16(loopStart);
    patchU16(endPatch, code.length);
    loadConst({'type': 'Null', 'value': null});
  }

  void compileLet(Map<String, Object?> spec) {
    final locals = spec['locals'];
    final body = spec['body'];
    if (locals is! List || body is! Map) {
      stderr.writeln('let expression requires locals and body');
      exit(2);
    }

    final previous = <int, int?>{};
    for (final item in locals) {
      if (item is! Map) {
        stderr.writeln('let local must be an object');
        exit(2);
      }
      final local = item.cast<String, Object?>();
      final id = local['id'];
      final name = local['name'];
      final value = local['value'];
      if (id is! int || value is! Map) {
        stderr.writeln('let local requires id and value');
        exit(2);
      }
      final localIndex = allocateLocal();
      compileExpr(value.cast<String, Object?>());
      op(_opStoreLocal);
      u8(localIndex);
      if (name is String && name.trim().isNotEmpty) {
        debugLocals.add({'slot': localIndex, 'name': name.trim()});
      }
      previous[id] = scopedLocals[id];
      scopedLocals[id] = localIndex;
    }
    compileExpr(body.cast<String, Object?>());
    for (final id in previous.keys.toList().reversed) {
      final old = previous[id];
      if (old == null) {
        scopedLocals.remove(id);
      } else {
        scopedLocals[id] = old;
      }
    }
  }

  void compileTryCatch(Map<String, Object?> spec) {
    final body = spec['body'];
    final catchBody = spec['catch'];
    final catchLocal = spec['catch_local'];
    if (body is! Map || catchBody is! Map || catchLocal is! int) {
      stderr.writeln('try_catch expression requires body/catch/catch_local');
      exit(2);
    }

    op(_opTryBegin);
    final handlerPatch = reserveU16();
    final endOperandPatch = reserveU16();
    compileExpr(body.cast<String, Object?>());
    op(_opJump);
    final endJumpPatch = reserveU16();

    patchU16(handlerPatch, code.length);
    final catchLocalIndex = allocateLocal();
    op(_opStoreLocal);
    u8(catchLocalIndex);
    final previous = scopedLocals[catchLocal];
    scopedLocals[catchLocal] = catchLocalIndex;
    compileExpr(catchBody.cast<String, Object?>());
    if (previous == null) {
      scopedLocals.remove(catchLocal);
    } else {
      scopedLocals[catchLocal] = previous;
    }

    patchU16(endOperandPatch, code.length);
    patchU16(endJumpPatch, code.length);
  }

  void compileTryFinally(Map<String, Object?> spec) {
    final body = spec['body'];
    final finalizer = spec['finally'];
    if (body is! Map || finalizer is! Map) {
      stderr.writeln('try_finally expression requires body/finally');
      exit(2);
    }
    final preserveValue = spec['value'] == true;
    final valueLocal = preserveValue ? allocateLocal() : null;

    op(_opTryFinally);
    final finallyPatch = reserveU16();
    final endOperandPatch = reserveU16();
    compileExpr(body.cast<String, Object?>());
    if (valueLocal != null) {
      op(_opStoreLocal);
      u8(valueLocal);
    }
    op(_opJump);
    final endJumpPatch = reserveU16();

    patchU16(finallyPatch, code.length);
    compileExpr(finalizer.cast<String, Object?>());
    op(_opPop);
    op(_opEndFinally);

    patchU16(endOperandPatch, code.length);
    patchU16(endJumpPatch, code.length);
    if (valueLocal != null) {
      op(_opLoadLocal);
      u8(valueLocal);
    } else {
      loadConst({'type': 'Null', 'value': null});
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
