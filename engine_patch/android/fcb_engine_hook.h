#ifndef FCB_ENGINE_PATCH_ANDROID_FCB_ENGINE_HOOK_H_
#define FCB_ENGINE_PATCH_ANDROID_FCB_ENGINE_HOOK_H_

#ifdef __cplusplus
extern "C" {
#endif

typedef struct FcbLaunchPatch {
  int has_patch;
  int patch_number;
  const char* backend;
  const char* artifact_path;
  const char* bytecode_path;
  const char* manifest_path;
} FcbLaunchPatch;

typedef struct FcbInitParams {
  const char* app_id;
  const char* channel;
  const char* release_version;
  const char* platform;
  const char* arch;
  const char* cache_dir;
  const char* public_key_pem;
  int check_on_startup;
} FcbInitParams;

typedef int (*FcbGetLaunchPatchFn)(FcbLaunchPatch* out_patch);
typedef int (*FcbSetAotArtifactPathFn)(void* user_data,
                                       const char* artifact_path);
typedef int (*FcbMarkLaunchSuccessFn)();

typedef struct FcbEnginePatchDecision {
  int use_snapshot_artifact;
  int patch_number;
  const char* backend;
  const char* artifact_path;
  const char* manifest_path;
} FcbEnginePatchDecision;

// Production FFI symbol exported by the Rust updater.
int fcb_init(const FcbInitParams* params);
int fcb_get_launch_patch(FcbLaunchPatch* out_patch);
int fcb_mark_launch_success();
const char* fcb_last_error();

// Converts the updater launch-patch result into the minimal decision an Android
// Flutter Engine fork needs before configuring Dart AOT artifact settings.
//
// Returns:
//   1 when snapshot_replace should override the AOT artifact path.
//   0 when no Engine override should be applied.
//  -1 when the callback contract is invalid or the updater reports an error.
//
// String pointers are borrowed from the updater runtime and must not be freed.
int fcb_resolve_engine_patch(FcbGetLaunchPatchFn get_launch_patch,
                             FcbEnginePatchDecision* out_decision);

// Resolves the pending launch patch and calls set_aot_artifact_path with the
// patched libapp.so path when snapshot_replace is active.
//
// Returns:
//   1 when a snapshot artifact override was applied.
//   0 when no override is needed.
//  -1 when resolving the patch or applying the override fails.
int fcb_apply_android_snapshot_replace(
    FcbGetLaunchPatchFn get_launch_patch,
    FcbSetAotArtifactPathFn set_aot_artifact_path,
    void* user_data,
    FcbEnginePatchDecision* out_decision);

// Marks the last launch patch successful. Wire this after the Android root
// isolate has rendered its first frame, or after the earliest Engine lifecycle
// point your fork treats as a successful launch.
int fcb_mark_android_launch_success(FcbMarkLaunchSuccessFn mark_launch_success);

// Production convenience wrapper around fcb_get_launch_patch().
int fcb_resolve_android_snapshot_replace(
    FcbEnginePatchDecision* out_decision);

#ifdef __cplusplus
}
#endif

#endif  // FCB_ENGINE_PATCH_ANDROID_FCB_ENGINE_HOOK_H_
