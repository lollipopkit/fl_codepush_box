# Android snapshot_replace hook

This directory contains the Engine-side adapter for the FCB Phase B
`snapshot_replace` backend.

## Architecture

The snapshot_replace backend works by replacing the Dart AOT snapshot artifact
(`libapp.so` on Android) at runtime. The patched Flutter Engine checks for an
available code patch on startup, and if one exists, loads the patched `libapp.so`
instead of the bundled one.

The flow is:

1. App starts → Flutter Engine initializes.
2. Before the root isolate launches, the patched Engine calls
   `fcb_apply_android_snapshot_replace_with_config()`.
3. If a patch is available, the hook calls the Engine-provided setter with the
   patched `libapp.so` path from the FCB cache.
4. If no patch or an error occurs, the Engine falls back to the bundled artifact.

## Files

- `fcb_engine_hook.h` — C header defining `FcbLaunchPatch`,
  `FcbEnginePatchDecision`, `fcb_resolve_engine_patch()`,
  `fcb_resolve_android_snapshot_replace()`,
  `fcb_apply_android_snapshot_replace()`, and
  `fcb_apply_android_snapshot_replace_with_config()`.
- `fcb_engine_hook.cc` — Implementation that bridges the Rust updater ABI to the
  Engine patch decision and applies it through a caller-provided AOT path setter.
  Does not depend on Flutter Engine headers.
- `fcb_engine_hook_test.cc` — Unit tests for the hook logic.
- `apply_engine_patch.sh` — Script to copy hook files into a Flutter Engine source
  tree and print integration instructions.
- `verify_engine_patch.sh` — Verifies that a Flutter Engine source tree has the
  hook copied, linked from Android `BUILD.gn`, and called from Android startup
  code outside the copied hook directory.

`apply_engine_patch.sh` copies a prebuilt updater library into
`third_party/fcb/android/<abi>/` when one is available. It first looks in the
Android plugin packaging path,
`packages/fcb_code_push/android/src/main/jniLibs/<abi>/libfcb_updater.so`, which
is also what the Phase B APK validation checks.

## Integration Points

### Android: AOT snapshot loading

The primary integration point in the Flutter Engine is in the Android embedder,
specifically where the Dart VM AOT snapshot data is configured. The exact file
depends on the Flutter Engine version, but it is typically in:

- `shell/platform/android/io/flutter/embedding/engine/FlutterJNI.java` (Java side)
- `shell/platform/android/engine.cc` or `shell/platform/android/android_shell_holder.cc` (C++ side)

The C++ hook target must be linked into the Android Engine target that owns AOT
settings:

```gn
deps += [ "//shell/platform/android/fcb:fcb_engine_hook" ]
```

The generated `fcb/BUILD.gn` links `dl` because the preferred integration path
uses `dlopen`/`dlsym` to resolve `libfcb_updater.so`.

The C++ hook must be called before `FlutterEngineLaunch` or before the
`DartIsolate` is configured with AOT snapshot data. The Engine revision-specific
adapter passes a setter and an `FcbAndroidSnapshotReplaceConfig` to
`fcb_apply_android_snapshot_replace_with_config()`. The setter writes
`artifact_path` to the field used by that Engine revision for Android's
`libapp.so` path. The config must provide the app cache directory used by the
Flutter package, usually `<Context.getCacheDir()>/fcb`.

### Key Engine functions to patch

In a Flutter Engine fork, find where `Settings` are configured for the root
isolate on Android. The settings include paths like:

- `vm_snapshot_data` / `vm_snapshot_instructions`
- `isolate_snapshot_data` / `isolate_snapshot_instructions`

Or in newer engine versions, a single `libapp.so` path. The FCB hook should
override whichever path the Engine uses to locate the AOT snapshot data.

### Patched Engine lifecycle

```
App start
  → fcb_apply_android_snapshot_replace_with_config(&config, SetAotPath)
  → if SetAotPath is called
      override AOT path = artifact_path
  → launch FlutterEngine with (possibly overridden) settings
  → fcb_mark_launch_success()  // Mark patch as good after UI renders
```

The setter contract is:

```cc
int SetAotPath(const char* artifact_path,
               const char* manifest_path,
               int patch_number);
```

Return `0` when the Engine setting was updated. Return non-zero to keep the
bundled artifact and report a hook error.

The preferred config is:

```cc
FcbAndroidSnapshotReplaceConfig config = {};
config.channel = "stable";
config.release_version = "<release version>";
config.arch = "<android abi>";
config.cache_dir = "<Context.getCacheDir()>/fcb";
config.updater_library_path = "libfcb_updater.so";
```

`cache_dir` is required. The hook returns `-1` before initializing the updater
when `cache_dir` is null or empty, because the Engine must use the same
application cache directory as the Flutter package.

When `config.symbols` is empty, the hook uses `dlopen`/`dlsym` to load
`fcb_init` and `fcb_get_launch_patch` from `libfcb_updater.so`.

### Failure handling

If `fcb_apply_android_snapshot_replace_with_config` returns `-1`, the Engine
should keep the bundled artifact and continue startup. If a patched artifact
causes a crash, the updater state machine blocklists the patch on the next
launch because the previous `pending_success` launch was never marked
successful.

## Validation

Verify a patched Engine tree before building it:

```sh
engine_patch/android/verify_engine_patch.sh /path/to/engine/src
```

```sh
c++ -std=c++17 -Wall -Wextra -Werror -Iengine_patch/android \
  engine_patch/android/fcb_engine_hook.cc \
  engine_patch/android/fcb_engine_hook_test.cc \
  -o /tmp/fcb_engine_hook_test
/tmp/fcb_engine_hook_test
```

## Binary diff: bsdiff + zstd

Phase B uses `bsdiff-zstd-v1` as the primary binary diff algorithm. The diff
envelope is a JSON `BinaryDiffEnvelope` containing:

- `algorithm`: `"bsdiff-zstd-v1"`
- `base_hash`: SHA-256 of the baseline `libapp.so`
- `output_hash`: SHA-256 of the target `libapp.so`
- `compression`: `"zstd"` (bsdiff output compressed with zstd)
- `payload_b64`: base64-encoded, zstd-compressed bsdiff patch

The updater applies the diff by:
1. Decoding the base64 payload.
2. Decompressing with zstd.
3. Applying bsdiff patch against the baseline `libapp.so`.
4. Verifying the output hash matches `output_hash`.
5. Writing the patched `libapp.so` to the cache.

Legacy `fcb-simple-v1` diffs are still supported for backward compatibility.
