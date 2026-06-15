# Android Engine integration notes

This directory is the Phase B patch payload for a Flutter Engine fork. It is
kept independent of concrete Engine headers so the fork can wire it into the
current Engine revision without carrying stale file paths in this repository.

## Build wiring

1. Build the updater for the same Android ABI as the Engine target:

   ```sh
   cargo ndk -t x86_64 -o /tmp/fcb-updater build -p fcb_updater --release
   ```

2. Add a GN target equivalent to `BUILD.gn.snippet`.

3. Link that target into the Android shell/embedder library that configures
   Dart AOT settings for the root isolate.

4. Ensure the final shared object exports or statically links these updater
   symbols:

   - `fcb_init`
   - `fcb_get_launch_patch`
   - `fcb_mark_launch_success`

## Runtime wiring

Before Android root isolate launch, collect the app's FCB configuration and
initialize the updater:

```cc
FcbInitParams params = {};
params.app_id = app_id;
params.channel = channel;
params.release_version = release_version;
params.platform = "android";
params.arch = android_abi;
params.cache_dir = cache_dir;
params.public_key_pem = public_key;
params.check_on_startup = 0;
fcb_init(&params);
```

On the Engine revision inspected in this workspace, Android AOT library paths
are parsed from `--aot-shared-library-name` in
`flutter/shell/common/switches.cc` into
`Settings::application_library_paths`. Android builds those settings in
`flutter/shell/platform/android/flutter_main.cc`, inside `FlutterMain::Init`.

Call `fcb_apply_android_snapshot_replace(...)` in `FlutterMain::Init` after
`settings.enable_platform_isolates = true` and before
`g_flutter_main.reset(new FlutterMain(settings, ...))`. The
`set_aot_artifact_path` callback should clear
`settings.application_library_paths` and push `decision.artifact_path`.

Use the same updater cache directory as the Dart package. For the current
Android embedding, `engineCachesPath` is `Context.getCodeCacheDir()` or
`Context.getCacheDir()`; the temporary app validation used
`<cache>/fcb`, so the Engine patch should call:

```cc
params.cache_dir = (engineCachesPath + "/fcb").c_str();
```

`flutter_engine_current.patch` is a concrete patch sketch for this Engine
layout. It still needs to be applied inside the Engine checkout and compiled
with `fcb_enable_code_push=true` and `fcb_updater_staticlib` pointing at the
ABI-matching Rust static library.

After the root isolate has rendered its first frame, call:

```cc
fcb_mark_android_launch_success(fcb_mark_launch_success);
```

On the inspected Android Engine, a concrete hook point is
`PlatformViewAndroid::FireFirstFrameCallback()` in
`flutter/shell/platform/android/platform_view_android.cc`, immediately before
or after `jni_facade_->FlutterViewOnFirstFrame()`. That transitions the patch
from pending to current. If the process exits before this call, the next launch
treats that patch as failed and rolls back.

## Validation target

The local adapter test does not require a Flutter Engine checkout:

```sh
c++ -std=c++17 -Wall -Wextra -Werror -Iengine_patch/android \
  engine_patch/android/fcb_engine_hook.cc \
  engine_patch/android/fcb_engine_hook_test.cc \
  -o /tmp/fcb_engine_hook_test
/tmp/fcb_engine_hook_test
```

Full Phase B validation still requires an Engine fork build because stock
Flutter Engine never calls `fcb_get_launch_patch()` and therefore cannot load
the downloaded `patches/<n>/libapp.so`.

## Phase D VM bytecode wiring

For the Dart VM integrated backend, keep the same updater initialization but do
not override `Settings::application_library_paths`. Instead, resolve the launch
patch and register the installed bytecode module with the forked VM patch
runtime before root isolate execution:

```cc
#include "vm/fcb_patch_api.h"

int RegisterVmBytecodePatch(void* user_data,
                            const char* bytecode_path,
                            const char* manifest_path) {
  (void)user_data;
  (void)manifest_path;
  std::string error;
  return dart::fcb::LoadPatchRuntimeForCurrentIsolateGroup(bytecode_path,
                                                           &error)
             ? 0
             : -1;
}

FcbEnginePatchDecision decision = {};
const int rc = fcb_apply_android_vm_bytecode_patch(
    fcb_get_launch_patch,
    RegisterVmBytecodePatch,
    nullptr,
    &decision);
```

`manifest_path` remains available to enforce signed manifest/payload binding in
the final Engine integration; the current VM bridge loads the already installed
bytecode payload selected by the updater.

The VM fork then consults its patch table from function entry / invocation
dispatch:

- `OriginalOnly`: continue to original AOT code.
- `PatchedInterpreted`: enter the VM-adjacent FCB interpreter.
- `DisabledBadPatch`: fall back to original AOT code and leave rollback state
  to the updater.

`vendor/flutter/engine/src/flutter/shell/platform/android/fcb/` contains the
current embedded Engine wiring. It installs a root-isolate callback from
`FlutterMain::Init()` and marks the launch successful from
`PlatformViewAndroid::FireFirstFrameCallback()`.

`vendor/sdk/runtime/vm/fcb_patch_api.*` exposes the VM-side registration bridge.
`fcb_patch_entry.*` and `fcb_patch_runtime.*` contain the current dispatch-table
and VM-neutral interpreter skeleton that still needs to be adapted to real VM
types such as `Thread*`, `ObjectPtr`, `ArrayPtr`, and `TypeArgumentsPtr`.
