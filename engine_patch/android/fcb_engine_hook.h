#ifndef FCB_ENGINE_PATCH_ANDROID_FCB_ENGINE_HOOK_H_
#define FCB_ENGINE_PATCH_ANDROID_FCB_ENGINE_HOOK_H_

#ifdef __cplusplus
extern "C" {
#endif

// FcbLaunchPatch describes the result of fcb_get_launch_patch().
// Produced by the Rust updater FFI library (libfcb_updater).
typedef struct FcbLaunchPatch {
  int has_patch;       // 1 if a patch is ready for launch, 0 otherwise
  int patch_number;    // The patch number, valid only when has_patch == 1
  const char* backend;       // "snapshot_replace" or "bytecode"
  const char* artifact_path; // Absolute path to patched libapp.so (snapshot_replace)
  const char* bytecode_path; // Absolute path to bytecode payload (bytecode)
  const char* manifest_path; // Absolute path to patch manifest
} FcbLaunchPatch;

// Production FFI symbol exported by the Rust updater.
// Returns 0 on success (out_patch filled), non-zero on error.
int fcb_get_launch_patch(FcbLaunchPatch* out_patch);

#ifdef __cplusplus
}  // extern "C"
#endif

// C++ integration layer for Flutter Engine.
//
// fcb_resolve_engine_patch() calls the updater FFI and converts the result
// into a minimal decision struct. fcb_resolve_android_snapshot_replace() is
// a convenience wrapper that uses the production fcb_get_launch_patch symbol.

namespace fcb {

struct EnginePatchDecision {
  int use_snapshot_artifact;  // 1 = override AOT path, 0 = no override
  int patch_number;           // Patch number when use_snapshot_artifact == 1
  const char* backend;        // Backend name, e.g. "snapshot_replace"
  const char* artifact_path;  // Absolute path to patched libapp.so
  const char* manifest_path;  // Absolute path to manifest
};

using FcbGetLaunchPatchFn = int (*)(FcbLaunchPatch*);

// Calls get_launch_patch and fills out_decision:
//   Returns 1 when snapshot_replace should override the AOT artifact path.
//   Returns 0 when no Engine override should be applied (no patch or bytecode backend).
//   Returns -1 on error or invalid callback contract.
// String pointers in out_decision are borrowed from the updater runtime and
// must not be freed or used after the next FCB call.
int ResolveEnginePatch(FcbGetLaunchPatchFn get_launch_patch,
                       EnginePatchDecision* out_decision);

// Convenience wrapper that calls ResolveEnginePatch with the production
// fcb_get_launch_patch symbol. For use inside Engine code where the FFI
// library is linked statically.
//
// Important: this function must be called AFTER fcb_init() has been called
// (typically by the Java-side FlutterLoader before native Engine startup).
int ResolveAndroidSnapshotReplace(EnginePatchDecision* out_decision);

}  // namespace fcb

#endif  // FCB_ENGINE_PATCH_ANDROID_FCB_ENGINE_HOOK_H_
