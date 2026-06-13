/// Marks a function or method as eligible for hot-patching via FCB bytecode.
///
/// Only functions annotated with `@hotPatchable` can be replaced at runtime
/// through the FCB restricted bytecode backend. The build transformer generates
/// a dispatch wrapper that checks for an updated bytecode implementation before
/// falling back to the original AOT code.
///
/// Restrictions:
/// - Only top-level functions, static methods, and instance methods are supported.
/// - The function must have a return type that is one of:
///   int, double, bool, String, num, Null, or a List/Map of these types.
/// - Async functions (Future/Stream) are not supported in Phase C.
/// - Generic type parameters are not supported in Phase C.
///
/// Example:
/// ```dart
/// @hotPatchable
/// int calculatePrice(int base, double taxRate) => (base * (1 + taxRate)).toInt();
/// ```
const hotPatchable = _HotPatchable();

class _HotPatchable {
  const _HotPatchable();
}

/// Marks a class whose methods are eligible for hot-patching.
///
/// When applied to a class, all concrete methods in the class become
/// hot-patchable unless they are explicitly excluded with `@hotPatchableExclude`.
///
/// Example:
/// ```dart
/// @hotPatchable
/// class PricingEngine {
///   int calculatePrice(int base) => base + 10;
/// }
/// ```
const hotPatchableClass = _HotPatchableClass();

class _HotPatchableClass {
  const _HotPatchableClass();
}

/// Excludes a method from hot-patching when the class is annotated with
/// `@hotPatchable`.
const hotPatchableExclude = _HotPatchableExclude();

class _HotPatchableExclude {
  const _HotPatchableExclude();
}
