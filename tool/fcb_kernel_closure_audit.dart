import 'package:kernel/ast.dart';
import 'package:kernel/visitor.dart';

bool hasEscapingCapturingClosure(FunctionNode function) {
  return escapingCapturingClosureReason(function) != null;
}

String? escapingCapturingClosureReason(FunctionNode function) {
  final body = function.body;
  if (body == null) return null;
  final safeClosureVariables = <VariableDeclaration>{};
  final visitor = _EscapingCapturingClosureVisitor(safeClosureVariables);
  body.accept(visitor);
  return visitor.reason;
}

class _EscapingCapturingClosureVisitor extends RecursiveVisitor {
  _EscapingCapturingClosureVisitor(this._safeClosureVariables);

  final Set<VariableDeclaration> _safeClosureVariables;
  String? reason;

  @override
  void defaultDartType(DartType node) {}

  @override
  void visitReturnStatement(ReturnStatement node) {
    final expression = node.expression;
    if (_isCapturingClosureExpression(expression)) {
      reason ??= 'returning_capturing_closure';
      return;
    }
    expression?.accept(this);
  }

  @override
  void visitFunctionInvocation(FunctionInvocation node) {
    if (reason != null) return;
    final receiver = node.receiver;
    if (receiver is FunctionExpression && _capturesOuterVariable(receiver)) {
      return;
    }
    if (receiver is VariableGet &&
        _safeClosureVariables.contains(receiver.variable)) {
      return;
    }
    receiver.accept(this);
    _visitInvocationArguments(node.arguments);
  }

  @override
  void visitInstanceInvocation(InstanceInvocation node) {
    if (reason != null) return;
    node.receiver.accept(this);
    if (reason != null) return;
    _visitInvocationArguments(node.arguments);
  }

  @override
  void visitStaticInvocation(StaticInvocation node) {
    if (reason != null) return;
    _visitInvocationArguments(node.arguments);
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    if (reason != null) return;
    final initializer = node.initializer;
    if (initializer is FunctionExpression &&
        _capturesOuterVariable(initializer)) {
      _safeClosureVariables.add(node);
      return;
    }
    initializer?.accept(this);
  }

  @override
  void visitVariableGet(VariableGet node) {
    if (_safeClosureVariables.contains(node.variable)) {
      reason ??= 'escaping_capturing_closure';
    }
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    if (_capturesOuterVariable(node)) {
      reason ??= 'escaping_capturing_closure';
    }
  }

  bool _isCapturingClosureExpression(Expression? expression) {
    if (expression is FunctionExpression) {
      return _capturesOuterVariable(expression);
    }
    if (expression is VariableGet) {
      return _safeClosureVariables.contains(expression.variable);
    }
    return false;
  }

  void _visitInvocationArguments(Arguments arguments) {
    for (final argument in arguments.positional) {
      if (_isCapturingClosureExpression(argument)) {
        reason ??= 'passing_capturing_closure';
        return;
      }
      argument.accept(this);
      if (reason != null) return;
    }
    for (final argument in arguments.named) {
      if (_isCapturingClosureExpression(argument.value)) {
        reason ??= 'passing_capturing_closure';
        return;
      }
      argument.value.accept(this);
      if (reason != null) return;
    }
  }
}

bool _capturesOuterVariable(FunctionExpression expression) {
  final declared = <VariableDeclaration>{
    ...expression.function.positionalParameters,
    ...expression.function.namedParameters,
  };
  final body = expression.function.body;
  if (body == null) return false;
  final visitor = _ClosureCaptureVisitor(declared);
  body.accept(visitor);
  return visitor.capturesOuter;
}

class _ClosureCaptureVisitor extends RecursiveVisitor {
  _ClosureCaptureVisitor(this._declared);

  final Set<VariableDeclaration> _declared;
  bool capturesOuter = false;

  @override
  void defaultDartType(DartType node) {}

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    _declared.add(node);
    node.initializer?.accept(this);
  }

  @override
  void visitVariableGet(VariableGet node) {
    if (!_declared.contains(node.variable)) capturesOuter = true;
  }

  @override
  void visitFunctionInvocation(FunctionInvocation node) {
    node.receiver.accept(this);
    _visitArguments(node.arguments);
  }

  @override
  void visitInstanceInvocation(InstanceInvocation node) {
    node.receiver.accept(this);
    _visitArguments(node.arguments);
  }

  @override
  void visitStaticInvocation(StaticInvocation node) {
    _visitArguments(node.arguments);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    final previous = Set<VariableDeclaration>.of(_declared);
    _declared.addAll(node.function.positionalParameters);
    _declared.addAll(node.function.namedParameters);
    node.function.body?.accept(this);
    _declared
      ..clear()
      ..addAll(previous);
  }

  void _visitArguments(Arguments arguments) {
    for (final argument in arguments.positional) {
      argument.accept(this);
    }
    for (final argument in arguments.named) {
      argument.value.accept(this);
    }
  }
}
