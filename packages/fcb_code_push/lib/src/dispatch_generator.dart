/// Dispatch wrapper generator for @hotPatchable functions.
///
/// This module generates the dispatch wrapper pattern that allows
/// @hotPatchable functions to be replaced at runtime via bytecode patches.
///
/// Usage pattern in generated code:
/// ```dart
/// // Original @hotPatchable function:
/// @hotPatchable
/// int calculatePrice(int base, double taxRate) => (base * (1 + taxRate)).toInt();
///
/// // Generated dispatch wrapper:
/// int calculatePrice(int base, double taxRate) {
///   final patched = FcbCodePush.instance.callBytecode(
///     'calculatePrice', [base, taxRate]);
///   if (patched != null) return patched as int;
///   return _calculatePriceOriginal(base, taxRate);
/// }
/// int _calculatePriceOriginal(int base, double taxRate) =>
///   (base * (1 + taxRate)).toInt();
/// ```
class DispatchGenerator {
  /// Generate a dispatch wrapper for a hot-patchable function.
  ///
  /// Returns the source code for the dispatch wrapper method.
  static String generateWrapper({
    required String functionName,
    required String returnType,
    required List<ParameterInfo> parameters,
    required String originalBody,
  }) {
    final argsList =
        parameters.map((p) => '${p.type} ${p.name}').join(', ');
    final argsArray =
        parameters.map((p) => p.name).join(', ');

    final dispatchCall =
        "FcbCodePush.instance.callBytecode('$functionName', [$argsArray])";

    if (returnType == 'void') {
      return '''
  void $functionName($argsList) {
    final patched = $dispatchCall;
    if (patched != null) return;
    _${functionName}Original($argsArray);
  }
  void _${functionName}Original($argsList) $originalBody''';
    }

    if (_isPrimitiveType(returnType)) {
      return '''
  $returnType $functionName($argsList) {
    final patched = $dispatchCall;
    if (patched != null) return patched as $returnType;
    return _${functionName}Original($argsArray);
  }
  $returnType _${functionName}Original($argsList) $originalBody''';
    }

    return '''
  $returnType? $functionName($argsList) {
    final patched = $dispatchCall;
    if (patched != null) return patched as $returnType;
    return _${functionName}Original($argsArray);
  }
  $returnType _${functionName}Original($argsList) $originalBody''';
  }

  /// Generate a class-level dispatch wrapper for instance methods.
  static String generateInstanceWrapper({
    required String className,
    required String functionName,
    required String returnType,
    required List<ParameterInfo> parameters,
    required String originalBody,
  }) {
    final qualifiedName = '$className.$functionName';
    final argsList =
        parameters.map((p) => '${p.type} ${p.name}').join(', ');
    final argsArray =
        parameters.map((p) => p.name).join(', ');

    final dispatchCall =
        "FcbCodePush.instance.callBytecode('$qualifiedName', [$argsArray])";

    if (returnType == 'void') {
      return '''
  void $functionName($argsList) {
    final patched = $dispatchCall;
    if (patched != null) return;
    _${functionName}Original($argsArray);
  }
  void _${functionName}Original($argsList) $originalBody''';
    }

    return '''
  $returnType $functionName($argsList) {
    final patched = $dispatchCall;
    if (patched != null) return patched as $returnType;
    return _${functionName}Original($argsArray);
  }
  $returnType _${functionName}Original($argsList) $originalBody''';
  }

  static bool _isPrimitiveType(String type) {
    return const {'int', 'double', 'bool', 'String', 'num', 'Null'}
        .contains(type);
  }
}

/// Parameter info for function generation.
class ParameterInfo {
  final String type;
  final String name;

  const ParameterInfo({required this.type, required this.name});
}
