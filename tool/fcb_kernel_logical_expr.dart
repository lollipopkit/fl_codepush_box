part of fcb_kernel_reader;

Map<String, Object?>? _logicalExpressionExpr(
  LogicalExpression expression,
  Set<String> params,
  String libraryUri,
  Map<VariableDeclaration, int> locals,
  Map<VariableDeclaration, FunctionExpression> closures,
) {
  final left = _expr(expression.left, params, libraryUri, locals, closures);
  final right = _expr(expression.right, params, libraryUri, locals, closures);
  if (left == null || right == null) return null;
  return switch (expression.operatorEnum) {
    LogicalExpressionOperator.AND => {
      'conditional': {
        'condition': left,
        'then': right,
        'else': {'bool': false},
      },
    },
    LogicalExpressionOperator.OR => {
      'conditional': {
        'condition': left,
        'then': {'bool': true},
        'else': right,
      },
    },
  };
}
