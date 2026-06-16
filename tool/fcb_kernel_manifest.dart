import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  final project = _arg(args, '--project') ?? '.';
  final target = _arg(args, '--target') ?? 'lib/main.dart';
  final root = Directory(project);
  final lib = Directory('${root.path}/lib');
  if (!lib.existsSync()) {
    stderr.writeln('project has no lib directory: ${root.path}');
    exit(2);
  }

  final functions = <Map<String, Object?>>[];
  for (final file
      in lib
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'))) {
    final rel = _relative(root, file);
    final libraryUri = _libraryUri(root, file);
    final source = file.readAsStringSync();
    functions.addAll(_scanFunctions(source, rel, libraryUri));
  }

  final inventory = <String, Object?>{
    'schema_version': 1,
    'functions': functions,
    'classes': <Object?>[],
    'top_level_fields': <Object?>[],
    'target': target,
  };
  stdout.write(jsonEncode(inventory));
}

String? _arg(List<String> args, String name) {
  final idx = args.indexOf(name);
  if (idx < 0 || idx + 1 >= args.length) return null;
  return args[idx + 1];
}

String _relative(Directory root, File file) {
  final rootPath = root.absolute.path;
  final filePath = file.absolute.path;
  if (filePath.startsWith('$rootPath/')) {
    return filePath.substring(rootPath.length + 1);
  }
  return file.path;
}

String _libraryUri(Directory root, File file) {
  final pubspec = File('${root.path}/pubspec.yaml');
  var package = 'app';
  if (pubspec.existsSync()) {
    final match = RegExp(
      r'^name:\s*([A-Za-z0-9_]+)\s*$',
      multiLine: true,
    ).firstMatch(pubspec.readAsStringSync());
    if (match != null) package = match.group(1)!;
  }
  final rel = _relative(root, file).replaceAll('\\', '/');
  if (rel.startsWith('lib/')) {
    return 'package:$package/${rel.substring(4)}';
  }
  return rel;
}

List<Map<String, Object?>> _scanFunctions(
  String source,
  String rel,
  String libraryUri,
) {
  final functions = <Map<String, Object?>>[];
  final pattern = RegExp(
    r'(?:(?:@pragma\([^\n]+\)\s*)*)(?:static\s+)?(?:int|String|bool|double|Object|dynamic|void)\s+([A-Za-z_][A-Za-z0-9_]*)\s*\(([^)]*)\)\s*\{',
    multiLine: true,
  );
  for (final match in pattern.allMatches(source)) {
    final name = match.group(1)!;
    final params = _params(match.group(2)!);
    final open = match.end - 1;
    final close = _matchingBrace(source, open);
    if (close == null) continue;
    final body = source.substring(open + 1, close);
    final canonicalSignature =
        '${params.length}:${params.map((p) => p.type).join(',')}';
    final functionId = _hash(
      [
        libraryUri,
        '',
        name,
        _hash([canonicalSignature]),
        '',
      ].join('\n'),
    );
    final bytecodeSource = _bytecodeSource(
      name: '$libraryUri::$name',
      params: params.map((p) => p.name).toList(),
      body: body,
    );
    functions.add({
      'function_id': functionId,
      'library_uri': libraryUri,
      'enclosing': '',
      'member_name': name,
      'signature_hash': _hash([canonicalSignature]),
      'body_hash': _hash([_stableBody(body)]),
      'source_location': '$rel:${_lineOf(source, match.start)}',
      if (bytecodeSource != null) 'bytecode_source': bytecodeSource,
      'unsupported_reasons': bytecodeSource == null
          ? <String>['unsupported_kernel_node']
          : <String>[],
    });
  }
  return functions;
}

List<_Param> _params(String source) {
  final trimmed = source.trim();
  if (trimmed.isEmpty) return const [];
  return trimmed.split(',').map((raw) {
    final parts = raw.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return _Param('dynamic', parts.single);
    return _Param(parts[parts.length - 2], parts.last);
  }).toList();
}

int? _matchingBrace(String source, int open) {
  var depth = 0;
  for (var i = open; i < source.length; i++) {
    final ch = source.codeUnitAt(i);
    if (ch == 0x7b) depth++;
    if (ch == 0x7d) {
      depth--;
      if (depth == 0) return i;
    }
  }
  return null;
}

Map<String, Object?>? _bytecodeSource({
  required String name,
  required List<String> params,
  required String body,
}) {
  final returnExpr = RegExp(r'return\s+([^;]+);').firstMatch(body);
  if (returnExpr == null) return null;
  final expr = _expr(returnExpr.group(1)!.trim(), params);
  if (expr == null) return null;
  return {'name': name, 'params': params, 'body': expr};
}

Map<String, Object?>? _expr(String raw, List<String> params) {
  if (RegExp(r'^-?\d+$').hasMatch(raw)) return {'int': int.parse(raw)};
  if (raw == 'true' || raw == 'false') return {'bool': raw == 'true'};
  if (raw.startsWith("'") && raw.endsWith("'")) {
    return {'string': raw.substring(1, raw.length - 1)};
  }
  if (raw.startsWith('"') && raw.endsWith('"')) {
    return {'string': raw.substring(1, raw.length - 1)};
  }
  if (params.contains(raw)) return {'arg': raw};
  for (final op in ['==', '>', '+', '-', '*', '/']) {
    final idx = raw.indexOf(op);
    if (idx > 0) {
      final left = _expr(raw.substring(0, idx).trim(), params);
      final right = _expr(raw.substring(idx + op.length).trim(), params);
      if (left != null && right != null) {
        return {'op': op, 'left': left, 'right': right};
      }
    }
  }
  return null;
}

String _stableBody(String body) => body.replaceAll(RegExp(r'\s+'), ' ').trim();

int _lineOf(String source, int offset) =>
    '\n'.allMatches(source.substring(0, offset)).length + 1;

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

class _Param {
  const _Param(this.type, this.name);
  final String type;
  final String name;
}
