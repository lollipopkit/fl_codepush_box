import 'module.dart';
import 'interpreter.dart';

/// Dispatches calls to @hotPatchable functions, checking if a bytecode
/// patch is available before falling back to the original AOT implementation.
///
/// Usage:
/// ```dart
/// final dispatcher = FcbDispatcher();
/// // After downloading a bytecode patch:
/// dispatcher.loadModule(bytecodeJsonBytes);
/// // Call a hot-patchable function:
/// final result = dispatcher.call('calculatePrice', [100, 0.08]);
/// ```
class FcbDispatcher {
  BytecodeModule? _module;
  FcbInterpreter? _interpreter;

  /// Load a bytecode module from JSON bytes (as received from the patch payload).
  bool loadModule(List<int> bytes) {
    try {
      _module = BytecodeModule.fromBytes(bytes);
      _interpreter = FcbInterpreter(_module!, onExternalCall: _onExternalCall);
      return true;
    } catch (_) {
      _module = null;
      _interpreter = null;
      return false;
    }
  }

  /// Clear the loaded module (e.g., after a rollback).
  void clearModule() {
    _module = null;
    _interpreter = null;
  }

  /// Whether a bytecode patch is currently loaded.
  bool get hasPatch => _module != null;

  /// The currently loaded module, if any.
  BytecodeModule? get module => _module;

  /// Call a @hotPatchable function by name.
  ///
  /// If a bytecode patch is loaded and contains the named function,
  /// the interpreter executes it. Otherwise returns null to indicate
  /// the caller should fall back to the original AOT implementation.
  dynamic call(String functionName, List<dynamic> args) {
    if (_interpreter == null || _module == null) {
      return null;
    }
    final fn = _module!.findFunction(functionName);
    if (fn == null) {
      return null;
    }
    final result = _interpreter!.call(functionName, args);
    if (result.success) {
      return result.value;
    }
    // If interpretation fails, return null to signal fallback.
    return null;
  }

  /// Check if a specific function name has a bytecode patch.
  bool hasFunction(String functionName) {
    return _module?.findFunction(functionName) != null;
  }

  /// List all patched function names.
  List<String> get patchedFunctionNames {
    return _module?.functions.map((f) => f.name).toList() ?? [];
  }

  dynamic _onExternalCall(String name, List<dynamic> args) {
    // External calls in Phase C are not supported; return null for fallback.
    return null;
  }
}
