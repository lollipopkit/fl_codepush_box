import 'dart:math' as math;
import 'module.dart';
import 'opcodes.dart';

/// Result of interpreting a bytecode function.
class InterpretResult {
  final dynamic value;
  final bool success;
  final String? error;

  InterpretResult._(this.value, this.success, this.error);

  static InterpretResult ok(dynamic value) =>
      InterpretResult._(value, true, null);
  static InterpretResult err(String message) =>
      InterpretResult._(null, false, message);
}

/// FCB restricted bytecode interpreter.
///
/// Executes bytecode functions from a BytecodeModule. The interpreter is
/// register-based with a locals array and a value stack for expression
/// evaluation.
class FcbInterpreter {
  final BytecodeModule module;

  /// Optional callback for CallPatchable instructions that reference
  /// functions not in the current module.
  final dynamic Function(String functionName, List<dynamic> args)?
      onExternalCall;

  FcbInterpreter(this.module, {this.onExternalCall});

  /// Call a function by name with the given positional arguments.
  InterpretResult call(String functionName, List<dynamic> args) {
    final fn = module.findFunction(functionName);
    if (fn == null) {
      if (onExternalCall != null) {
        try {
          final result = onExternalCall!(functionName, args);
          return InterpretResult.ok(result);
        } catch (e) {
          return InterpretResult.err('external call $functionName failed: $e');
        }
      }
      return InterpretResult.err('function not found: $functionName');
    }
    if (args.length != fn.paramCount) {
      return InterpretResult.err(
          'function $functionName expects ${fn.paramCount} args, got ${args.length}');
    }
    return _execute(fn, args);
  }

  InterpretResult _execute(BytecodeFunction fn, List<dynamic> args) {
    final locals = List<dynamic>.filled(fn.localCount, null);
    for (var i = 0; i < args.length && i < locals.length; i++) {
      locals[i] = args[i];
    }
    final valueStack = <dynamic>[];
    var ip = 0;
    final code = fn.code;

    while (ip < code.length) {
      final op = code[ip++];
      switch (op) {
        case OpCode.return_:
          if (valueStack.isNotEmpty) {
            return InterpretResult.ok(valueStack.last);
          }
          return InterpretResult.ok(null);

        case OpCode.jump:
          final target = _readU16(code, ip);
          ip = target;
          continue;

        case OpCode.jumpIfFalse:
          final target = _readU16(code, ip);
          ip += 2;
          if (valueStack.isEmpty) {
            return InterpretResult.err('jumpIfFalse: stack underflow');
          }
          final condition = valueStack.removeLast();
          if (!_isTruthy(condition)) {
            ip = target;
          }
          continue;

        case OpCode.jumpIfTrue:
          final target = _readU16(code, ip);
          ip += 2;
          if (valueStack.isEmpty) {
            return InterpretResult.err('jumpIfTrue: stack underflow');
          }
          final condition = valueStack.removeLast();
          if (_isTruthy(condition)) {
            ip = target;
          }
          continue;

        case OpCode.loadNull:
          valueStack.add(null);
          break;

        case OpCode.loadTrue:
          valueStack.add(true);
          break;

        case OpCode.loadFalse:
          valueStack.add(false);
          break;

        case OpCode.loadInt:
          final idx = _readU16(code, ip);
          ip += 2;
          if (idx >= module.intPool.length) {
            return InterpretResult.err('loadInt: pool index $idx out of range');
          }
          valueStack.add(module.intPool[idx]);
          break;

        case OpCode.loadDouble:
          final idx = _readU16(code, ip);
          ip += 2;
          if (idx >= module.doublePool.length) {
            return InterpretResult.err('loadDouble: pool index $idx out of range');
          }
          valueStack.add(module.doublePool[idx]);
          break;

        case OpCode.loadString:
          final idx = _readU16(code, ip);
          ip += 2;
          if (idx >= module.stringPool.length) {
            return InterpretResult.err('loadString: pool index $idx out of range');
          }
          valueStack.add(module.stringPool[idx]);
          break;

        case OpCode.add:
          final b = valueStack.removeLast();
          final a = valueStack.removeLast();
          if (a is int && b is int) {
            valueStack.add(a + b);
          } else if (a is num && b is num) {
            valueStack.add(a + b);
          } else if (a is String && b is String) {
            valueStack.add(a + b);
          } else {
            return InterpretResult.err(
                'add: unsupported types ${a.runtimeType} + ${b.runtimeType}');
          }
          break;

        case OpCode.subtract:
          final b = valueStack.removeLast() as num;
          final a = valueStack.removeLast() as num;
          valueStack.add(a - b);
          break;

        case OpCode.multiply:
          final b = valueStack.removeLast() as num;
          final a = valueStack.removeLast() as num;
          valueStack.add(a * b);
          break;

        case OpCode.divide:
          final b = valueStack.removeLast() as num;
          final a = valueStack.removeLast() as num;
          if (b == 0) {
            return InterpretResult.err('divide by zero');
          }
          valueStack.add(a / b);
          break;

        case OpCode.modulo:
          final b = valueStack.removeLast() as num;
          final a = valueStack.removeLast() as num;
          if (b == 0) {
            return InterpretResult.err('modulo by zero');
          }
          valueStack.add(a % b);
          break;

        case OpCode.negate:
          final a = valueStack.removeLast() as num;
          valueStack.add(-a);
          break;

        case OpCode.equal:
          final b = valueStack.removeLast();
          final a = valueStack.removeLast();
          valueStack.add(a == b);
          break;

        case OpCode.notEqual:
          final b = valueStack.removeLast();
          final a = valueStack.removeLast();
          valueStack.add(a != b);
          break;

        case OpCode.lessThan:
          final b = valueStack.removeLast() as num;
          final a = valueStack.removeLast() as num;
          valueStack.add(a < b);
          break;

        case OpCode.lessEqual:
          final b = valueStack.removeLast() as num;
          final a = valueStack.removeLast() as num;
          valueStack.add(a <= b);
          break;

        case OpCode.greaterThan:
          final b = valueStack.removeLast() as num;
          final a = valueStack.removeLast() as num;
          valueStack.add(a > b);
          break;

        case OpCode.greaterEqual:
          final b = valueStack.removeLast() as num;
          final a = valueStack.removeLast() as num;
          valueStack.add(a >= b);
          break;

        case OpCode.logicalNot:
          final a = valueStack.removeLast();
          valueStack.add(!_isTruthy(a));
          break;

        case OpCode.isInt:
          valueStack.add(valueStack.removeLast() is int);
          break;
        case OpCode.isDouble:
          valueStack.add(valueStack.removeLast() is double);
          break;
        case OpCode.isBool:
          valueStack.add(valueStack.removeLast() is bool);
          break;
        case OpCode.isString:
          valueStack.add(valueStack.removeLast() is String);
          break;
        case OpCode.isNull:
          valueStack.add(valueStack.removeLast() == null);
          break;

        case OpCode.loadLocal:
          final idx = code[ip++];
          if (idx >= locals.length) {
            return InterpretResult.err('loadLocal: index $idx out of range');
          }
          valueStack.add(locals[idx]);
          break;

        case OpCode.storeLocal:
          final idx = code[ip++];
          if (idx >= locals.length) {
            return InterpretResult.err('storeLocal: index $idx out of range');
          }
          locals[idx] = valueStack.removeLast();
          break;

        case OpCode.listNew:
          valueStack.add(<dynamic>[]);
          break;

        case OpCode.listAdd:
          final value = valueStack.removeLast();
          final list = valueStack.last as List<dynamic>;
          list.add(value);
          break;

        case OpCode.mapNew:
          valueStack.add(<dynamic, dynamic>{});
          break;

        case OpCode.mapSet:
          final value = valueStack.removeLast();
          final key = valueStack.removeLast();
          final map = valueStack.last as Map<dynamic, dynamic>;
          map[key] = value;
          break;

        case OpCode.listGet:
          final idx = valueStack.removeLast() as int;
          final list = valueStack.last as List<dynamic>;
          valueStack.removeLast();
          valueStack.add(list[idx]);
          break;

        case OpCode.listLength:
          final list = valueStack.last as List<dynamic>;
          valueStack.removeLast();
          valueStack.add(list.length);
          break;

        case OpCode.stringConcat:
          final b = valueStack.removeLast().toString();
          final a = valueStack.removeLast().toString();
          valueStack.add(a + b);
          break;

        case OpCode.toString_:
          valueStack.add(valueStack.removeLast().toString());
          break;

        case OpCode.intParse:
          final s = valueStack.removeLast().toString();
          valueStack.add(int.tryParse(s) ?? 0);
          break;

        case OpCode.doubleParse:
          final s = valueStack.removeLast().toString();
          valueStack.add(double.tryParse(s) ?? 0.0);
          break;

        case OpCode.intToDouble:
          final n = valueStack.removeLast() as int;
          valueStack.add(n.toDouble());
          break;

        case OpCode.doubleToInt:
          final n = valueStack.removeLast() as double;
          valueStack.add(n.toInt());
          break;

        case OpCode.mathAbs:
          final n = valueStack.removeLast() as num;
          valueStack.add(n.abs());
          break;

        case OpCode.mathMin:
          final b = valueStack.removeLast() as num;
          final a = valueStack.removeLast() as num;
          valueStack.add(a < b ? a : b);
          break;

        case OpCode.mathMax:
          final b = valueStack.removeLast() as num;
          final a = valueStack.removeLast() as num;
          valueStack.add(a > b ? a : b);
          break;

        case OpCode.mathSqrt:
          final n = valueStack.removeLast() as num;
          valueStack.add(math.sqrt(n.toDouble()));
          break;

        case OpCode.mathRound:
          final n = valueStack.removeLast() as num;
          valueStack.add(n.round());
          break;

        case OpCode.callPatchable:
          final funcIdxHi = code[ip++];
          final funcIdxLo = code[ip++];
          final funcIdx = (funcIdxHi << 8) | funcIdxLo;
          final argCount = code[ip++];
          if (funcIdx >= module.functions.length) {
            final name = 'patchable_$funcIdx';
            final callArgs = <dynamic>[];
            for (var i = 0; i < argCount; i++) {
              callArgs.insert(0, valueStack.removeLast());
            }
            if (onExternalCall != null) {
              final result = onExternalCall!(name, callArgs);
              valueStack.add(result);
            } else {
              return InterpretResult.err(
                  'callPatchable: function index $funcIdx out of range');
            }
          } else {
            final target = module.functions[funcIdx];
            final callArgs = <dynamic>[];
            for (var i = 0; i < argCount; i++) {
              callArgs.insert(0, valueStack.removeLast());
            }
            final result = _execute(target, callArgs);
            if (!result.success) return result;
            valueStack.add(result.value);
          }
          break;

        case OpCode.callCore:
          final coreIdx = code[ip++];
          final argCount = code[ip++];
          final result = _callCore(coreIdx, argCount, valueStack);
          if (!result.success) return result;
          break;

        default:
          return InterpretResult.err(
              'unknown opcode 0x${op.toRadixString(16)} at position ${ip - 1}');
      }
    }
    return InterpretResult.ok(valueStack.isNotEmpty ? valueStack.last : null);
  }

  InterpretResult _callCore(
      int coreIdx, int argCount, List<dynamic> stack) {
    switch (coreIdx) {
      case 0: // print
        final parts = <String>[];
        for (var i = 0; i < argCount; i++) {
          parts.insert(0, stack.removeLast().toString());
        }
        // print is a side effect; push null
        stack.add(null);
        return InterpretResult.ok(null);
      default:
        return InterpretResult.err('unknown core function index: $coreIdx');
    }
  }

  bool _isTruthy(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value != 0;
    if (value is double) return value != 0.0;
    if (value is String) return value.isNotEmpty;
    return true;
  }

  int _readU16(List<int> code, int ip) {
    return (code[ip] << 8) | code[ip + 1];
  }
}
