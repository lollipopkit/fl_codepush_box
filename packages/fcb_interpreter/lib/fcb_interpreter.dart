/// FCB restricted bytecode interpreter.
///
/// This package provides a Dart-level interpreter for FCB bytecode modules.
/// It is used at runtime to execute @hotPatchable functions that have been
/// replaced via a code push patch.
///
/// The interpreter is intentionally restricted:
/// - No closures, no generics, no async/await
/// - Only basic types: int, double, bool, String, Null, List, Map
/// - Only basic control flow: if/else, for/while
/// - Only static calls to other @hotPatchable functions or core operations
library fcb_interpreter;

export 'src/opcodes.dart';
export 'src/module.dart';
export 'src/interpreter.dart';
export 'src/dispatcher.dart';
