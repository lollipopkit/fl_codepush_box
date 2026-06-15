# Vendor Checkouts

This directory contains local upstream/fork checkouts used by FCB.

## Layout

- `flutter/`
  - Remote: `https://github.com/lollipopkit/flutter`
  - Branch: `stable`
  - This is the Flutter framework/tool repository.
  - Modern stable checkouts include the Engine source under `engine/`.
  - The Engine revision is pinned by `flutter/bin/internal/engine.version`.

- `sdk/`
  - Remote: `https://github.com/lollipopkit/dartsdk`
  - Branch: `stable`
  - This is the Dart SDK checkout. Dart VM changes live under `runtime/vm/`.

- `depot_tools/`
  - Chromium build toolchain providing `gclient`, `gn`, and `ninja`.
  - Required by `build_android_engine.sh`, `bootstrap_engine_min_deps.sh`, and
    `sync_flutter_engine_deps.sh`.

- `flutter/engine/`
  - Comes from the modern Flutter stable checkout.
  - Engine C++ sources live under `flutter/engine/src/flutter/`.

## Sync Dart VM Patch

After making changes to `vendor/sdk`, sync them into the Engine's embedded Dart
SDK checkout:

```sh
scripts/sync_dart_vm_patch.sh
```

This runs `git pull origin stable` inside:

```text
vendor/flutter/engine/src/flutter/third_party/dart
```

That directory is a git clone of `vendor/sdk` (local path as origin), so the
pull fast-forwards it to the latest FCB commit.

## Android Engine FCB Wiring

The active Android Engine integration lives in:

```text
vendor/flutter/engine/src/flutter/shell/platform/android/fcb/
```

Enable it when generating an Android Engine build by setting:

```text
fcb_enable_code_push=true
fcb_updater_staticlib="/absolute/path/to/libfcb_updater.a"
```

The Engine hook initializes the updater with `<engineCachesPath>/fcb`, resolves
an installed `bytecode` launch patch, and registers it from
`Settings::root_isolate_create_callback` before user Dart code runs. The Android
bridge directly includes `third_party/dart/runtime/vm/fcb_patch_api.h`, so the
Dart VM patch files must be synced into the Engine's Dart SDK checkout before
building with `fcb_enable_code_push=true`.

Flutter `DEPS` pins the Engine Dart SDK checkout at:

```text
vendor/flutter/engine/src/flutter/third_party/dart
```

After `gclient sync` has populated that directory, sync the local VM patch:

```sh
scripts/sync_dart_vm_patch.sh
```

## Build Android Engine

Use the repository wrapper instead of invoking `tools/gn` by hand:

```sh
scripts/build_android_engine.sh
```

Before GN can run, the embedded Engine checkout must have its gclient
dependencies populated. A full `gclient sync` can refuse to continue when the
embedded Engine checkout contains local VM/Engine edits. Use the minimum
bootstrap script instead:

```sh
scripts/bootstrap_engine_min_deps.sh
```

That script reads the authoritative stable pins from `vendor/flutter/DEPS` and
populates the Android GN/build dependencies needed by this checkout, including
Skia, Vulkan deps, GN, Ninja, Clang, Android tools/NDK, ICU, zlib, BoringSSL,
Perfetto, libcxx/libcxxabi, HarfBuzz, ANGLE, SwiftShader, Impeller shader
compiler deps, and related third-party libraries.

If you still want to try full gclient sync after making sure local Engine changes
are safe, run:

```sh
scripts/sync_flutter_engine_deps.sh
```

That wrapper uses `vendor/depot_tools`, keeps depot/vpython cache under
`target/fcb/depot-home`, defaults to Android deps, and does not pass
`--reset`, `--force`, or `--delete_unversioned_trees`.

Current smoke status:

```text
FCB_SKIP_SYNC=1 FCB_SKIP_NINJA=1 scripts/build_android_engine.sh
```

passes GN generation and creates:

```text
vendor/flutter/engine/src/out/android_release_arm64
```

The full Android Engine target also passes:

```sh
FCB_SKIP_SYNC=1 scripts/build_android_engine.sh
```

It builds:

```text
vendor/flutter/engine/src/out/android_release_arm64/libflutter.so
vendor/flutter/engine/src/out/android_release_arm64/lib.stripped/libflutter.so
```

The x64 Android Engine target also builds. Use it only for local x86_64
emulator smoke tests when an arm64 device/emulator is not available:

```sh
FCB_ANDROID_CPU=x64 FCB_SKIP_SYNC=1 scripts/build_android_engine.sh
```

It refreshes the local-engine artifacts needed by Flutter:

```text
vendor/flutter/engine/src/out/android_release_x64/libflutter.so
vendor/flutter/engine/src/out/android_release_x64/lib.stripped/libflutter.so
vendor/flutter/engine/src/out/android_release_x64/x86_64_release.jar
vendor/flutter/engine/src/out/android_release_x64/gen_snapshot
```

By default the wrapper:

- syncs the local Dart VM overlay from `vendor/sdk` into the Engine Dart SDK;
- builds `libfcb_updater.a` with `cargo-ndk` when
  `FCB_UPDATER_STATICLIB` is not provided;
- runs Engine GN for Android with `fcb_enable_code_push=true` and an absolute
  `fcb_updater_staticlib` path;
- passes an ABI-matching NDK `libunwind.a` path as `fcb_unwind_staticlib`, which
  is required because the Rust updater staticlib pulls Rust std backtrace and
  personality symbols into the final Android Engine link;
- builds `flutter/shell/platform/android:flutter_shell_native` with ninja.

Useful variants:

```sh
# Generate GN only, useful for checking args/deps before a full Engine build.
FCB_SKIP_NINJA=1 scripts/build_android_engine.sh

# Build/resolve the updater staticlib and print the Engine output path without GN.
FCB_SKIP_GN=1 FCB_SKIP_NINJA=1 scripts/build_android_engine.sh

# Use an already-built ABI-matching updater static library.
FCB_UPDATER_STATICLIB=/absolute/path/to/libfcb_updater.a \
  scripts/build_android_engine.sh

# Use an explicit ABI-matching NDK libunwind.a when auto-detection is wrong.
FCB_UNWIND_STATICLIB=/absolute/path/to/libunwind.a \
  scripts/build_android_engine.sh

# Build a different Android CPU/runtime mode.
FCB_ANDROID_CPU=x64 FCB_RUNTIME_MODE=profile \
  scripts/build_android_engine.sh
```

When the wrapper builds the Rust updater itself, it defaults
`FCB_UPDATER_RUSTFLAGS` to the current `RUSTFLAGS` plus `-C panic=abort` so Rust
panics do not cross the Engine FFI boundary as unwinds.

The default output for Android arm64 release is:

```text
vendor/flutter/engine/src/out/android_release_arm64
```

When building an app against this Engine, pass the embedded Engine source root
and the generated output directory name:

```sh
FCB_ENABLE_AOT_DISPATCH=1 vendor/flutter/bin/flutter build apk \
  --release \
  --target-platform android-arm64 \
  --local-engine-src-path "$PWD/vendor/flutter/engine/src" \
  --local-engine android_release_arm64
```

For arm64 device acceptance, use the checked-in wrapper:

```sh
scripts/accept_android_arm64.sh
```

It first verifies that the current adb device primary ABI is `arm64-v8a`, then
runs both required launch modes on the same real arm64 adb device:

- no-patch: `1/8/7/base/10`
- bytecode patch: `42/42/42/patched/42`

The wrapper treats those values as the acceptance contract. It passes explicit
expected values to the underlying phase runner and forces the manual bytecode
patch installer to include the int, string, static-method, and four-argument
patch entries, so leftover `FCB_PATCH_RETURN_VALUE` or related environment
overrides cannot silently weaken the final arm64 result.
The fifth value is `quadCounterValue(int,int,int,int)` and verifies the Android
arm64 AOT static-call trampoline path for four positional arguments.

On success it writes a compact evidence file at:

```text
target/fcb/android-arm64-acceptance/summary.txt
```

The summary records the device ABI, expected and observed no-patch/patch
results, per-phase result files with tombstone counts, logcat paths, and
SHA-256/file metadata for the APK, `app.so`, and `libflutter.so`.

To check the connected device before paying the build cost:

```sh
scripts/check_android_arm64_device.sh
```

For debugging a single launch mode, use:

```sh
scripts/test_android_arm64.sh
```

The shared Android acceptance implementation is:

```sh
scripts/test_android.sh
```

It defaults to `android-arm64` and `android_release_arm64`. The `arm64` and
`x64` scripts are thin wrappers that set those defaults explicitly for their
target ABI.

This requires an adb device whose primary ABI is `arm64-v8a`. An x86_64 emulator
that lists `arm64-v8a` only as a translated secondary ABI is not a valid FCB
runtime acceptance target. `scripts/test_android_arm64.sh` sets
`FCB_REQUIRE_PRIMARY_ABI=1` by default and fails fast on translated secondary
ABI devices.

The shared script can still be forced through native-bridge experiments, but
that is only a smoke test:

```sh
FCB_ALLOW_SECONDARY_ABI=1 scripts/test_android.sh
```

Crashes or success there do not prove arm64 stub correctness; use the arm64
wrapper on a real `arm64-v8a` device for acceptance.

For the x64 emulator-only smoke path, use:

```sh
scripts/test_android_x64.sh
```

The wrapper builds `examples/counter_app` with
`FCB_ENABLE_AOT_DISPATCH=1`, installs it on the current adb device, launches
`com.example.fcb_counter_app/.MainActivity`, and fails on missing process,
crash-like logcat entries, or missing local-engine artifacts. To reuse an
already-built APK:

```sh
FCB_SKIP_BUILD=1 scripts/test_android_x64.sh
```

To install a manual bytecode launch patch before starting the app and require
the Engine bridge to register it with the VM:

```sh
FCB_SKIP_BUILD=1 FCB_INSTALL_BYTECODE_PATCH=1 scripts/test_android_x64.sh
```

This verifies the updater state, Android Engine bridge, and VM bytecode module
registration path on a locally runnable emulator ABI. It is not the primary
Android acceptance target; runtime acceptance should be done with
`scripts/test_android.sh` or `scripts/test_android_arm64.sh` on `arm64-v8a`,
because current production Android devices are overwhelmingly arm64.

The current VM overlay hooks `DartEntry::InvokeFunction()` and dispatches to
the FCB interpreter when the loaded patch table contains either
`<script-url>::<qualified-function-name>` or `<qualified-function-name>`.
The VM-neutral interpreter currently validates opcode boundaries and operand
ranges before install, rejects jump targets that land outside instruction
starts, and executes the Phase B bytecode subset for null/int/double/bool/string
values plus `MakeList` and `MakeMap` aggregate construction. Numeric bytecode
ops accept mixed int/double operands, and division returns a double to match Dart
`/` semantics. JSON module loading accepts signed integer and floating-point
constants, matching the Rust bytecode format used by the package-side compiler.
The transitional VM object bridge converts scalar arguments/returns, fixed and
growable VM list arguments, fixed VM list returns, and VM Map arguments via
`Map::Iterator` into flat bytecode key/value entries. Map returns are converted
by building a fixed key/value list and invoking
`dart:_compact_hash#createMapFromKeyValueListUnsafe`, so the Dart library code
maintains the compact-hash index instead of the bridge writing VM Map internals
directly. This still leaves full `ObjectPtr` stack semantics and arbitrary Dart
object allocation for the later object-semantics pass.
It also defines `FcbPatchCall0`, `FcbPatchCall1`, `FcbPatchCall2`, and
`FcbPatchCall3` runtime
entries as the next lower-level targets for architecture-specific static/IC
call stubs. The x64, arm64, arm, ia32, and riscv unoptimized static call stubs
now probe those entries for 0, 1, 2, and 3 argument calls before jumping to the
original target. The x64 probe keeps `FUNCTION_REG` intact while reading stack
arguments, which is required for the no-patch continuation and for passing the
target function into the FCB runtime entry. Static calls with more than 4
arguments currently skip the FCB probe and continue through the original VM call
path, avoiding an unsupported runtime-entry arity. When a patch table is already
loaded, the JIT optimizing
compiler also keeps patched static targets out of inlining and optimized direct
static-call emission so those calls continue through the FCB probe.

For precompiled AOT work, the VM overlay adds the experimental flag:

```text
--fcb_enable_aot_dispatch
```

When enabled during AOT compilation/snapshot binding, it disables pc-relative
static-call emission and keeps each static call table's `Function` target instead
of replacing it only with `Code`. The binder still patches `CallStaticFunction`
call sites to the original target `Code`, so no-patch startup follows the normal
AOT target and does not depend on metadata fallback behavior. This preserves the
metadata required by an FCB-aware AOT static-call trampoline without breaking the
original target binding.
By default, FCB AOT dispatch probes non-SDK, non-Flutter Dart package static
functions and only enters the interpreter when the installed bytecode patch table
has a matching function id. `--fcb_aot_probe_allowlist` remains available as an
optional compile-time narrowing filter for debugging or size experiments, but it
is no longer required for the Android arm64 acceptance path.
The VM `Code` object layout and AOT snapshot serializer now keep
`static_calls_target_table_` in precompiled runtime as well. On Android x64 and
arm64, selected precompiled call-via-code sites can be patched to the dedicated
`FcbAotStaticCall` stub family. On Android arm64, those stubs probe
`FcbPatchStaticCallAot` / `FcbPatchStaticCallAot4` for 0-4 positional arguments
and fall back through the normal `PatchStaticCall` runtime entry when no patch
applies. The ordinary `CallStaticFunction` stub intentionally stays on the stock
VM fallback path.

The Flutter tool fork wires this into Android AOT builds through:

```sh
FCB_ENABLE_AOT_DISPATCH=1 vendor/flutter/bin/flutter build apk ...
```

`packages/flutter_tools` appends `--fcb_enable_aot_dispatch` to `gen_snapshot`
only for Android AOT snapshot builds when that environment variable is set. Set
`FCB_AOT_PROBE_ALLOWLIST` only when you deliberately want to restrict which
static functions are rewritten to FCB AOT stubs.

## Notes

- Do not add `-stable` suffixes to vendor directory names.
- Keep `vendor/flutter` and `vendor/sdk` on their `stable` branches.
- `flutter/engine` on GitHub is archived/read-only. For current stable, use the
  Engine source embedded in `vendor/flutter/engine/`.
- If `vendor/engine/` or `vendor/flutter/engine.incomplete-*` exists, treat it
  as stale cache from the older external checkout attempt. The active Engine
  checkout path is `vendor/flutter/engine/`.
