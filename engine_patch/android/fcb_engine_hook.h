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

typedef int (*FcbGetLaunchPatchFn)(FcbLaunchPatch* out_patch);

typedef struct FcbEnginePatchDecision {
  int use_snapshot_artifact;
  int patch_number;
  const char* backend;
  const char* artifact_path;
  const char* manifest_path;
} FcbEnginePatchDecision;

// Production FFI symbol exported by the Rust updater.
int fcb_get_launch_patch(FcbLaunchPatch* out_patch);

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

// Production convenience wrapper around fcb_get_launch_patch().
int fcb_resolve_android_snapshot_replace(
    FcbEnginePatchDecision* out_decision);

#ifdef __cplusplus
}
#endif

#endif  // FCB_ENGINE_PATCH_ANDROID_FCB_ENGINE_HOOK_H_
