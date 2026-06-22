import 'dart:convert';
import 'dart:io';

import 'fcb_binary_module_writer.dart';
import 'fcb_kernel_reader_bundle.dart';

part 'fcb_kernel_manifest_compiler.dart';
part 'fcb_kernel_manifest_control_compiler.dart';

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
