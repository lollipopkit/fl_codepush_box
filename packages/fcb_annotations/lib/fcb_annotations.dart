/// FCB Annotations for marking functions as hot-patchable.
///
/// Import this package and use `@hotPatchable` to annotate functions
/// that should be replaceable via the FCB bytecode backend.
///
/// ```dart
/// import 'package:fcb_annotations/hot_patchable.dart';
///
/// @hotPatchable
/// int calculateTotal(int price, int quantity) => price * quantity;
/// ```
library fcb_annotations;

export 'hot_patchable.dart';
