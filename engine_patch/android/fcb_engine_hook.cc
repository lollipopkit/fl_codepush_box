#include "fcb_engine_hook.h"

#include <dlfcn.h>

#include <cstring>

namespace {

void ClearDecision(FcbEnginePatchDecision* decision) {
  if (decision == nullptr) {
    return;
  }
  decision->use_snapshot_artifact = 0;
  decision->patch_number = 0;
  decision->backend = nullptr;
  decision->artifact_path = nullptr;
  decision->manifest_path = nullptr;
}

bool StringEquals(const char* left, const char* right) {
  return left != nullptr && right != nullptr && std::strcmp(left, right) == 0;
}

const char* NonEmptyOrDefault(const char* value, const char* fallback) {
  return value != nullptr && value[0] != '\0' ? value : fallback;
}

}  // namespace

int fcb_load_updater_symbols(const char* library_path,
                             FcbUpdaterSymbols* out_symbols) {
  if (out_symbols == nullptr) {
    return -1;
  }
  out_symbols->init = nullptr;
  out_symbols->get_launch_patch = nullptr;

  const char* path = NonEmptyOrDefault(library_path, "libfcb_updater.so");
  void* handle = dlopen(path, RTLD_NOW | RTLD_LOCAL);
  if (handle == nullptr) {
    return -1;
  }

  out_symbols->init =
      reinterpret_cast<FcbInitFn>(dlsym(handle, "fcb_init"));
  out_symbols->get_launch_patch = reinterpret_cast<FcbGetLaunchPatchFn>(
      dlsym(handle, "fcb_get_launch_patch"));
  if (out_symbols->init == nullptr ||
      out_symbols->get_launch_patch == nullptr) {
    return -1;
  }
  return 0;
}

int fcb_resolve_engine_patch(FcbGetLaunchPatchFn get_launch_patch,
                             FcbEnginePatchDecision* out_decision) {
  if (get_launch_patch == nullptr || out_decision == nullptr) {
    return -1;
  }
  ClearDecision(out_decision);

  FcbLaunchPatch patch = {};
  const int rc = get_launch_patch(&patch);
  if (rc != 0) {
    return -1;
  }
  if (patch.has_patch == 0) {
    return 0;
  }
  if (!StringEquals(patch.backend, "snapshot_replace")) {
    return 0;
  }
  if (patch.artifact_path == nullptr || patch.artifact_path[0] == '\0') {
    return -1;
  }

  out_decision->use_snapshot_artifact = 1;
  out_decision->patch_number = patch.patch_number;
  out_decision->backend = patch.backend;
  out_decision->artifact_path = patch.artifact_path;
  out_decision->manifest_path = patch.manifest_path;
  return 1;
}

int fcb_resolve_android_snapshot_replace(
    FcbEnginePatchDecision* out_decision) {
  return fcb_resolve_engine_patch(fcb_get_launch_patch, out_decision);
}

int fcb_apply_android_snapshot_replace(FcbGetLaunchPatchFn get_launch_patch,
                                       FcbSetAotArtifactPathFn set_path) {
  if (set_path == nullptr) {
    return -1;
  }

  FcbEnginePatchDecision decision = {};
  const int rc = fcb_resolve_engine_patch(get_launch_patch, &decision);
  if (rc <= 0) {
    return rc;
  }
  if (decision.use_snapshot_artifact == 0) {
    return 0;
  }
  return set_path(decision.artifact_path, decision.manifest_path,
                  decision.patch_number) == 0
             ? 1
             : -1;
}

int fcb_apply_android_snapshot_replace_with_config(
    const FcbAndroidSnapshotReplaceConfig* config,
    FcbSetAotArtifactPathFn set_path) {
  if (config == nullptr || set_path == nullptr) {
    return -1;
  }
  if (config->cache_dir == nullptr || config->cache_dir[0] == '\0') {
    return -1;
  }

  FcbUpdaterSymbols symbols = config->symbols;
  if (symbols.init == nullptr || symbols.get_launch_patch == nullptr) {
    if (fcb_load_updater_symbols(config->updater_library_path, &symbols) != 0) {
      return -1;
    }
  }

  FcbInitParams params = {};
  params.app_id = config->app_id;
  params.channel = NonEmptyOrDefault(config->channel, "stable");
  params.release_version = config->release_version;
  params.platform = "android";
  params.arch = NonEmptyOrDefault(config->arch, "arm64-v8a");
  params.cache_dir = config->cache_dir;
  params.public_key_pem = config->public_key_pem;
  params.check_on_startup = 0;
  if (symbols.init(&params) != 0) {
    return -1;
  }

  return fcb_apply_android_snapshot_replace(symbols.get_launch_patch, set_path);
}
