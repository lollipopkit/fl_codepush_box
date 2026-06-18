import 'package:kernel/ast.dart';

String? fcbNormalizeSimpleTypeName(String raw) => _normalizeSimpleTypeName(raw);

String? fcbUnsupportedRuntimeTypeReason(DartType type) {
  if (_containsRecordType(type)) return 'record_type_unsupported';
  if (_containsFunctionType(type)) return 'function_type_unsupported';
  return null;
}

String? fcbKernelTypeName(DartType type) {
  if (type is! InterfaceType) return _normalizeSimpleTypeName(type.toString());
  final Class klass;
  try {
    klass = type.classNode;
  } catch (_) {
    return _normalizeSimpleTypeName(type.toString());
  }
  final libraryUri = klass.enclosingLibrary.importUri.toString();
  final base = libraryUri == 'dart:core'
      ? _normalizeSimpleTypeName(klass.name)
      : '$libraryUri::${klass.name}';
  if (base == null || type.typeArguments.isEmpty) return base;
  final args = [for (final arg in type.typeArguments) fcbKernelTypeName(arg)];
  if (args.any((arg) => arg == null)) return null;
  return '$base<${args.cast<String>().join(',')}>';
}

String? _normalizeSimpleTypeName(String raw) {
  var text = raw.trim();
  if (text.startsWith('InterfaceType(') && text.endsWith(')')) {
    text = text.substring('InterfaceType('.length, text.length - 1);
  }
  while (text.endsWith('?') || text.endsWith('*')) {
    text = text.substring(0, text.length - 1);
  }
  final typeArgsStart = text.indexOf('<');
  if (typeArgsStart != -1 && text.endsWith('>')) {
    final base = _normalizeSimpleTypeName(text.substring(0, typeArgsStart));
    final args = text
        .substring(typeArgsStart + 1, text.length - 1)
        .split(',')
        .map(_normalizeSimpleTypeName)
        .toList();
    if (base == null || args.any((arg) => arg == null)) return null;
    return '$base<${args.cast<String>().join(',')}>';
  }
  final coreMatch = RegExp(
    r'(?:dart:)?core::([A-Za-z_][A-Za-z0-9_]*)',
  ).firstMatch(text);
  if (coreMatch != null) text = coreMatch.group(1)!;
  if (text.startsWith('dart:core::')) {
    text = text.substring('dart:core::'.length);
  } else if (text.startsWith('core::')) {
    text = text.substring('core::'.length);
  }
  return switch (text) {
    'int' ||
    'double' ||
    'num' ||
    'bool' ||
    'String' ||
    'Object' ||
    'Null' ||
    'List' ||
    'Map' ||
    'dynamic' ||
    'void' => text,
    _ => null,
  };
}

bool _containsRecordType(DartType type) {
  if (type is RecordType) return true;
  if (type is InterfaceType) {
    return type.typeArguments.any(_containsRecordType);
  }
  if (type is FunctionType) {
    return type.positionalParameters.any(_containsRecordType) ||
        type.namedParameters.any((param) => _containsRecordType(param.type)) ||
        _containsRecordType(type.returnType);
  }
  return false;
}

bool _containsFunctionType(DartType type) {
  if (type is FunctionType) return true;
  if (type is InterfaceType) {
    final Class klass;
    try {
      klass = type.classNode;
    } catch (_) {
      return type.typeArguments.any(_containsFunctionType);
    }
    final libraryUri = klass.enclosingLibrary.importUri.toString();
    if (libraryUri == 'dart:core' && klass.name == 'Function') {
      return true;
    }
    return type.typeArguments.any(_containsFunctionType);
  }
  if (type is RecordType) {
    return type.positional.any(_containsFunctionType) ||
        type.named.any((field) => _containsFunctionType(field.type));
  }
  return false;
}
