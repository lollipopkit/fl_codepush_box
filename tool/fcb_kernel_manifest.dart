import 'dart:convert';
import 'dart:io';

Future<void> main(List<String> args) async {
  final project = _arg(args, '--project') ?? '.';
  final target = _arg(args, '--target') ?? 'lib/main.dart';
  final explicitDill = _arg(args, '--dill');
  final root = Directory(project).absolute;
  if (!File('${root.path}/pubspec.yaml').existsSync()) {
    stderr.writeln('project has no pubspec.yaml: ${root.path}');
    exit(2);
  }

  final packageName = _packageName(root);
  final temp = Directory.systemTemp.createTempSync('fcb_kernel_manifest_');
  try {
    final dill = explicitDill != null
        ? File(explicitDill).absolute
        : await _resolveDill(root, target, temp);
    final sdkRoot = _sdkRoot();
    final packageConfig = _writeKernelPackageConfig(temp, sdkRoot);
    final reader = _writeKernelReader(temp);
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
    stdout.write(result.stdout);
  } finally {
    temp.deleteSync(recursive: true);
  }
}

String? _arg(List<String> args, String name) {
  final idx = args.indexOf(name);
  if (idx < 0 || idx + 1 >= args.length) return null;
  return args[idx + 1];
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
  if (existing != null) return existing;

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
      final candidate = Directory('${dir.path}/vendor/sdk');
      if (candidate.existsSync()) return candidate;
      final parent = dir.parent;
      if (parent.path == dir.path) break;
      dir = parent;
    }
  }
  stderr.writeln('missing vendor/sdk; set FCB_KERNEL_SDK_ROOT');
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

File _writeKernelReader(Directory temp) {
  final file = File('${temp.path}/kernel_reader.dart');
  file.writeAsStringSync(_kernelReaderSource);
  return file;
}

const _kernelReaderSource = r'''
import 'dart:convert';
import 'dart:io';

import 'package:kernel/ast.dart';
import 'package:kernel/kernel.dart';
import 'package:kernel/text/ast_to_text.dart';

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
        functions.add(_procedureEntry(libraryUri, 'class:${klass.name}', procedure));
      }
    }
    for (final procedure in library.procedures) {
      functions.add(_procedureEntry(libraryUri, _extensionEnclosing(procedure), procedure));
    }
    for (final field in library.fields) {
      fields.add(_fieldEntry(libraryUri, field));
    }
  }

  stdout.write(jsonEncode({
    'schema_version': 1,
    'functions': functions,
    'classes': classes,
    'top_level_fields': fields,
    'target': target,
    'inventory_source': 'kernel_ast',
  }));
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
  final unsupported = <String>[];
  if (source == null || function.dartAsyncMarker != AsyncMarker.Sync) {
    unsupported.add('unsupported_kernel_node');
  }
  final functionId = _hash([
    libraryUri,
    enclosing,
    memberName,
    _hash(signature),
    function.typeParameters.length,
  ].join('\n'));
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
    ...klass.fields.map((field) => 'field:${field.name.text}:${field.type}:${field.isStatic}:${field.isFinal}:${field.isConst}'),
    ...klass.constructors.map((constructor) => 'constructor:${constructor.name.text}:${constructor.isConst}:${constructor.isExternal}:${_signature(constructor.function)}:${constructor.initializers.map(_nodeText).join(",")}'),
    ...klass.procedures.map((procedure) => 'procedure:${procedure.name.text}:${procedure.kind}:${procedure.isStatic}:${_signature(procedure.function)}'),
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
  final functionId = _hash([
    libraryUri,
    enclosing,
    memberName,
    _hash(signature),
    constructor.function.typeParameters.length,
  ].join('\n'));
  return {
    'function_id': functionId,
    'library_uri': libraryUri,
    'enclosing': enclosing,
    'member_name': memberName,
    'signature_hash': _hash(signature),
    'body_hash': _hash([
      _nodeText(constructor.function.body),
      constructor.initializers.map(_nodeText).join('\n'),
    ].join('\n')),
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
  if (statement == null || statement.expression == null) return null;
  final params = [
    ...function.positionalParameters.map((param) => param.name ?? ''),
    ...function.namedParameters.map((param) => param.name ?? ''),
  ].where((name) => name.isNotEmpty).toList();
  final expr = _expr(statement.expression!, params.toSet());
  if (expr == null) return null;
  final qualified = enclosing.isEmpty ? memberName : '$enclosing.$memberName';
  return {
    'name': '$libraryUri::$qualified',
    'params': params,
    'body': expr,
  };
}

ReturnStatement? _returnStatement(Statement? body) {
  if (body is ReturnStatement) return body;
  if (body is Block && body.statements.length == 1) {
    final only = body.statements.single;
    if (only is ReturnStatement) return only;
  }
  return null;
}

Map<String, Object?>? _expr(Expression expression, Set<String> params) {
  if (expression is IntLiteral) return {'int': expression.value};
  if (expression is StringLiteral) return {'string': expression.value};
  if (expression is BoolLiteral) return {'bool': expression.value};
  if (expression is VariableGet) {
    final name = expression.variable.name;
    if (name != null && params.contains(name)) return {'arg': name};
    return null;
  }
  final text = _nodeText(expression);
  for (final op in ['==', '>', '+', '-', '*', '/']) {
    final idx = text.indexOf(' $op ');
    if (idx > 0) {
      final left = _sourceExpr(text.substring(0, idx).trim(), params);
      final right = _sourceExpr(text.substring(idx + op.length + 2).trim(), params);
      if (left != null && right != null) {
        return {'op': op, 'left': left, 'right': right};
      }
    }
  }
  return null;
}

Map<String, Object?>? _sourceExpr(String raw, Set<String> params) {
  if (RegExp(r'^-?\d+$').hasMatch(raw)) return {'int': int.parse(raw)};
  if (raw == 'true' || raw == 'false') return {'bool': raw == 'true'};
  if (raw.startsWith("'") && raw.endsWith("'")) {
    return {'string': raw.substring(1, raw.length - 1)};
  }
  if (raw.startsWith('"') && raw.endsWith('"')) {
    return {'string': raw.substring(1, raw.length - 1)};
  }
  if (params.contains(raw)) return {'arg': raw};
  return null;
}

String _nodeText(Node? node) {
  if (node == null) return '';
  final buffer = StringBuffer();
  Printer(buffer, syntheticNames: NameSystem()).writeNode(node);
  return buffer.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
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
''';
