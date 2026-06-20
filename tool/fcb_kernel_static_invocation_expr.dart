part of fcb_kernel_reader;

Map<String, Object?>? _unboundDartStaticInvocationExpr(
  StaticInvocation expression,
  Set<String> params,
  String libraryUri,
  Map<VariableDeclaration, int> locals,
  Map<VariableDeclaration, FunctionExpression> closures,
) {
  final originalTarget = _unboundDartStaticTargetName(_nodeText(expression));
  if (originalTarget == null || expression.arguments.named.isNotEmpty) {
    return null;
  }
  final args = <Map<String, Object?>>[];
  for (final arg in expression.arguments.positional) {
    final compiledArg = _expr(arg, params, libraryUri, locals, closures);
    if (compiledArg == null) return null;
    args.add(compiledArg);
  }
  return {'call_original': originalTarget, 'args': args};
}

String? _unboundDartStaticTargetName(String text) {
  if (text.contains('dart:core::identical') ||
      text.trim().startsWith('core::identical(') ||
      text.trim().startsWith('identical(')) {
    return 'dart:core::identical';
  }
  return null;
}
