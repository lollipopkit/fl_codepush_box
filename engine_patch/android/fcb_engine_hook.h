#ifndef FCB_ENGINE_PATCH_ANDROID_FCB_ENGINE_HOOK_H_
#define FCB_ENGINE_PATCH_ANDROID_FCB_ENGINE_HOOK_H_

#ifdef __cplusplus
extern "C" {
#endif

#if defined(__GNUC__) || defined(__clang__)
#define FCB_WEAK_SYMBOL __attribute__((weak))
#else
#define FCB_WEAK_SYMBOL
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

typedef int (*FcbInitFn)(const FcbInitParams* params);
typedef int (*FcbGetLaunchPatchFn)(FcbLaunchPatch* out_patch);
typedef int (*FcbSetAotArtifactPathFn)(const char* artifact_path,
                                       const char* manifest_path,
                                       int patch_number);

typedef struct FcbUpdaterSymbols {
  FcbInitFn init;
  FcbGetLaunchPatchFn get_launch_patch;
} FcbUpdaterSymbols;

typedef struct FcbAndroidSnapshotReplaceConfig {
  const char* app_id;
  const char* channel;
  const char* release_version;
  const char* arch;
  const char* cache_dir;
  const char* public_key_pem;
  const char* updater_library_path;
  FcbUpdaterSymbols symbols;
} FcbAndroidSnapshotReplaceConfig;

typedef struct FcbEnginePatchDecision {
  int use_snapshot_artifact;
  int patch_number;
  const char* backend;
  const char* artifact_path;
  const char* manifest_path;
} FcbEnginePatchDecision;

// Production FFI symbol exported by the Rust updater.
int fcb_init(const FcbInitParams* params) FCB_WEAK_SYMBOL;
int fcb_get_launch_patch(FcbLaunchPatch* out_patch) FCB_WEAK_SYMBOL;

// Attempts to load updater symbols from `library_path` with dlopen/dlsym.
// Pass null or empty library_path to use "libfcb_updater.so".
int fcb_load_updater_symbols(const char* library_path,
                             FcbUpdaterSymbols* out_symbols);

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

// Applies the snapshot_replace decision to the Engine's AOT configuration via
// a caller-provided setter. The Flutter Engine fork should pass a small adapter
// that writes artifact_path to its version-specific Android AOT setting.
//
// Returns:
//   1 when the setter was called and accepted the patched artifact path.
//   0 when no patch is available or the backend is not snapshot_replace.
//  -1 when the updater or setter reports an error.
int fcb_apply_android_snapshot_replace(FcbGetLaunchPatchFn get_launch_patch,
                                       FcbSetAotArtifactPathFn set_path);

// Initializes the updater runtime and applies a snapshot_replace patch.
//
// This is the preferred Android Engine integration entrypoint. The Engine
// should provide app cache_dir and, optionally, app_id/channel/release/arch.
// If config.symbols is empty, the hook dynamically loads libfcb_updater.so.
int fcb_apply_android_snapshot_replace_with_config(
    const FcbAndroidSnapshotReplaceConfig* config,
    FcbSetAotArtifactPathFn set_path);

#undef FCB_WEAK_SYMBOL

#ifdef __cplusplus
}
#endif

#endif  // FCB_ENGINE_PATCH_ANDROID_FCB_ENGINE_HOOK_H_
