import 'package:kernel/ast.dart';

FunctionExpression? fcbInlineableStaticCallback(StaticInvocation invocation) {
  if (invocation.arguments.positional.length != 1 ||
      invocation.arguments.named.isNotEmpty ||
      invocation.arguments.types.isNotEmpty) {
    return null;
  }
  final callback = invocation.arguments.positional.single;
  if (callback is! FunctionExpression) return null;

  final target = invocation.target.function;
  if (target.positionalParameters.length != 1 ||
      target.namedParameters.isNotEmpty ||
      target.typeParameters.isNotEmpty) {
    return null;
  }
  final parameter = target.positionalParameters.single;
  final statement = _returnStatement(target.body);
  final expression = statement?.expression;
  if (expression is! FunctionInvocation ||
      expression.arguments.positional.isNotEmpty ||
      expression.arguments.named.isNotEmpty ||
      expression.arguments.types.isNotEmpty) {
    return null;
  }
  final receiver = expression.receiver;
  if (receiver is! VariableGet || receiver.variable != parameter) return null;
  return callback;
}

ReturnStatement? _returnStatement(Statement? body) {
  if (body is ReturnStatement) return body;
  if (body is Block && body.statements.length == 1) {
    final only = body.statements.single;
    if (only is ReturnStatement) return only;
  }
  return null;
}
