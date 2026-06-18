part of fcb_kernel_reader;

Map<String, Object?>? _equalsCallExpr(
  EqualsCall expression,
  Set<String> params,
  String libraryUri,
  Map<VariableDeclaration, int> locals,
  Map<VariableDeclaration, FunctionExpression> closures,
) {
  final left = _expr(expression.left, params, libraryUri, locals, closures);
  final right = _expr(expression.right, params, libraryUri, locals, closures);
  if (left == null || right == null) return null;
  return {'op': '==', 'left': left, 'right': right};
}

Map<String, Object?>? _notExpr(
  Not expression,
  Set<String> params,
  String libraryUri,
  Map<VariableDeclaration, int> locals,
  Map<VariableDeclaration, FunctionExpression> closures,
) {
  final operand = _expr(
    expression.operand,
    params,
    libraryUri,
    locals,
    closures,
  );
  if (operand == null) return null;
  return {
    'conditional': {
      'condition': operand,
      'then': {'bool': false},
      'else': {'bool': true},
    },
  };
}
