import 'package:kernel/ast.dart';
import 'package:kernel/visitor.dart';

bool hasEscapingCapturingClosure(FunctionNode function) {
  return escapingCapturingClosureReason(function) != null;
}

String? escapingCapturingClosureReason(FunctionNode function) {
  final body = function.body;
  if (body == null) return null;
  final safeClosureVariables = <VariableDeclaration>{};
  final genericClosureVariables = <VariableDeclaration>{};
  final visitor = _EscapingCapturingClosureVisitor(
    safeClosureVariables,
    genericClosureVariables,
  );
  body.accept(visitor);
  return visitor.reason;
}

class _EscapingCapturingClosureVisitor extends RecursiveVisitor {
  _EscapingCapturingClosureVisitor(
    this._safeClosureVariables,
    this._genericClosureVariables,
  );

  final Set<VariableDeclaration> _safeClosureVariables;
  final Set<VariableDeclaration> _genericClosureVariables;
  String? reason;

  @override
  void defaultDartType(DartType node) {}

  @override
  void visitReturnStatement(ReturnStatement node) {
    final expression = node.expression;
    final closureReason = _capturingClosureReason(
      expression,
      fallbackReason: 'returning_capturing_closure',
    );
    if (closureReason != null) {
      reason ??= closureReason;
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
  void visitEqualsCall(EqualsCall node) {
    if (reason != null) return;
    node.left.accept(this);
    if (reason != null) return;
    node.right.accept(this);
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
      if (_isGenericClosure(initializer)) {
        _genericClosureVariables.add(node);
      }
      return;
    }
    initializer?.accept(this);
  }

  @override
  void visitVariableGet(VariableGet node) {
    if (_safeClosureVariables.contains(node.variable)) {
      reason ??= _genericClosureVariables.contains(node.variable)
          ? 'generic_closure_unsupported'
          : 'escaping_capturing_closure';
    }
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    if (_capturesOuterVariable(node)) {
      reason ??= _isGenericClosure(node)
          ? 'generic_closure_unsupported'
          : 'escaping_capturing_closure';
    }
  }

  String? _capturingClosureReason(
    Expression? expression, {
    required String fallbackReason,
  }) {
    if (expression is FunctionExpression) {
      if (!_capturesOuterVariable(expression)) return null;
      return _isGenericClosure(expression)
          ? 'generic_closure_unsupported'
          : fallbackReason;
    }
    if (expression is VariableGet) {
      if (!_safeClosureVariables.contains(expression.variable)) return null;
      return _genericClosureVariables.contains(expression.variable)
          ? 'generic_closure_unsupported'
          : fallbackReason;
    }
    return null;
  }

  void _visitInvocationArguments(Arguments arguments) {
    for (final argument in arguments.positional) {
      final closureReason = _capturingClosureReason(
        argument,
        fallbackReason: 'passing_capturing_closure',
      );
      if (closureReason != null) {
        reason ??= closureReason;
        return;
      }
      argument.accept(this);
      if (reason != null) return;
    }
    for (final argument in arguments.named) {
      final closureReason = _capturingClosureReason(
        argument.value,
        fallbackReason: 'passing_capturing_closure',
      );
      if (closureReason != null) {
        reason ??= closureReason;
        return;
      }
      argument.value.accept(this);
      if (reason != null) return;
    }
  }
}

bool _isGenericClosure(FunctionExpression expression) =>
    expression.function.typeParameters.isNotEmpty;

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
  void visitEqualsCall(EqualsCall node) {
    node.left.accept(this);
    node.right.accept(this);
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
