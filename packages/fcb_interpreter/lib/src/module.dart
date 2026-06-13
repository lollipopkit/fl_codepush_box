import 'dart:convert';

/// A bytecode module deserialized from a patch payload.
class BytecodeModule {
  final int version;
  final String appId;
  final String releaseVersion;
  final int patchNumber;
  final List<String> stringPool;
  final List<int> intPool;
  final List<double> doublePool;
  final List<BytecodeFunction> functions;

  BytecodeModule({
    required this.version,
    required this.appId,
    required this.releaseVersion,
    required this.patchNumber,
    required this.stringPool,
    required this.intPool,
    required this.doublePool,
    required this.functions,
  });

  static const int formatVersion = 1;

  /// Deserialize a module from JSON bytes.
  static BytecodeModule fromBytes(List<int> bytes) {
    final json = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    final module = BytecodeModule(
      version: json['version'] as int,
      appId: json['app_id'] as String,
      releaseVersion: json['release_version'] as String,
      patchNumber: json['patch_number'] as int,
      stringPool: (json['string_pool'] as List).cast<String>(),
      intPool: (json['int_pool'] as List).cast<int>(),
      doublePool: (json['double_pool'] as List).cast<double>(),
      functions: [],
    );
    for (final fn in json['functions'] as List) {
      final f = fn as Map<String, dynamic>;
      module.functions.add(BytecodeFunction(
        name: f['name'] as String,
        paramCount: f['param_count'] as int,
        localCount: f['local_count'] as int,
        code: (f['code'] as List).cast<int>(),
      ));
    }
    return module;
  }

  /// Find a function by name.
  BytecodeFunction? findFunction(String name) {
    for (final fn in functions) {
      if (fn.name == name) return fn;
    }
    return null;
  }
}

/// A single compiled @hotPatchable function.
class BytecodeFunction {
  final String name;
  final int paramCount;
  final int localCount;
  final List<int> code;

  BytecodeFunction({
    required this.name,
    required this.paramCount,
    required this.localCount,
    required this.code,
  });
}
