# Dart SDK Phase D patch skeleton

Phase D moves FCB from app-level generated wrappers into a Dart VM integrated
patch runtime. The final fork should live inside the Dart SDK / Flutter Engine
checkout; this directory keeps the patchable core and integration notes in this
repository so it can be reviewed and tested before being transplanted.

## Target VM integration

The forked VM needs three pieces:

1. `FcbPatchRuntime`
   - Loads a signed FCB bytecode module selected by the updater.
   - Owns a function patch table keyed by stable `FunctionId`.
   - Decides whether a function runs original AOT code or interpreted patch
     bytecode.

2. Function entry dispatch
   - At AOT function entry or invocation stub, resolve the stable function id.
   - If no patch exists, continue to original AOT code.
   - If a valid patch exists, enter the VM-adjacent interpreter.
   - If a patch is disabled or failed, fall back to original AOT code.

3. VM object interop interpreter
   - Reads FCB bytecode operations.
   - Stores values as Dart VM `ObjectPtr` in real fork code.
   - Uses VM helpers for calls, allocation, fields, exceptions, async, closure,
     generic calls, and stack trace mapping.

## Files here

- `runtime/fcb_patch_runtime.h`
- `runtime/fcb_patch_runtime.cc`
- `runtime/fcb_patch_runtime_test.cc`

The current runtime core is intentionally independent from Dart VM headers. It
models the dispatch table and module validation that must later be wired to
real `Thread*`, `ObjectPtr`, `ArrayPtr`, and invocation stubs in the SDK fork.

## Local validation

```sh
c++ -std=c++17 -Wall -Wextra -Werror \
  dart_sdk_patch/runtime/fcb_patch_runtime.cc \
  dart_sdk_patch/runtime/fcb_patch_runtime_test.cc \
  -o /tmp/fcb_patch_runtime_test
/tmp/fcb_patch_runtime_test
```
