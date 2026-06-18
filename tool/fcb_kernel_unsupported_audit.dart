import 'package:kernel/ast.dart';
import 'package:kernel/visitor.dart';

import 'fcb_kernel_closure_audit.dart';
import 'fcb_kernel_type_names.dart';

List<String> fcbUnsupportedReasons(
  FunctionNode function,
  Map<String, Object?>? source,
) {
  if (function.dartAsyncMarker != AsyncMarker.Sync) {
    if (_isAsyncFutureValueSource(source)) return [];
    return ['async_await_unsupported'];
  }
  final typeCheckReason = _runtimeTypeCheckUnsupportedReason(function);
  if (source == null && typeCheckReason != null) {
    return [typeCheckReason];
  }
  final closureReason = source == null
      ? escapingCapturingClosureReason(function)
      : null;
  if (closureReason != null) {
    return [closureReason];
  }
  if (source == null) {
    return ['unsupported_kernel_node'];
  }
  return [];
}

bool _isAsyncFutureValueSource(Map<String, Object?>? source) {
  return source?['async_future_value'] == true;
}

String? _runtimeTypeCheckUnsupportedReason(FunctionNode function) {
  final body = function.body;
  if (body == null) return null;
  final visitor = _RuntimeTypeCheckUnsupportedVisitor();
  body.accept(visitor);
  return visitor.reason;
}

class _RuntimeTypeCheckUnsupportedVisitor extends RecursiveVisitor {
  String? reason;

  @override
  void defaultDartType(DartType node) {}

  @override
  void visitAsExpression(AsExpression node) {
    reason ??= fcbUnsupportedRuntimeTypeReason(node.type);
    if (reason != null) return;
    node.operand.accept(this);
  }

  @override
  void visitIsExpression(IsExpression node) {
    reason ??= fcbUnsupportedRuntimeTypeReason(node.type);
    if (reason != null) return;
    node.operand.accept(this);
  }

  @override
  void visitEqualsCall(EqualsCall node) {
    if (reason != null) return;
    node.left.accept(this);
    if (reason != null) return;
    node.right.accept(this);
  }

  @override
  void visitNot(Not node) {
    if (reason != null) return;
    node.operand.accept(this);
  }

  @override
  void visitDynamicGet(DynamicGet node) {
    if (reason != null) return;
    node.receiver.accept(this);
  }

  @override
  void visitInstanceGet(InstanceGet node) {
    if (reason != null) return;
    node.receiver.accept(this);
  }

  @override
  void visitInstanceInvocation(InstanceInvocation node) {
    if (reason != null) return;
    node.receiver.accept(this);
    if (reason != null) return;
    for (final argument in node.arguments.positional) {
      argument.accept(this);
      if (reason != null) return;
    }
    for (final argument in node.arguments.named) {
      argument.value.accept(this);
      if (reason != null) return;
    }
  }

  @override
  void visitStaticInvocation(StaticInvocation node) {
    if (reason != null) return;
    for (final argument in node.arguments.positional) {
      argument.accept(this);
      if (reason != null) return;
    }
    for (final argument in node.arguments.named) {
      argument.value.accept(this);
      if (reason != null) return;
    }
  }
}
