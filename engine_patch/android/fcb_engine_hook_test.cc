#include "fcb_engine_hook.h"

#include <cassert>
#include <cstring>

extern "C" int fcb_get_launch_patch(FcbLaunchPatch* out_patch) {
  // fcb_get_launch_patch(FcbLaunchPatch*) is a linker/test placeholder that always errors.
  (void)out_patch;
  return -1;
}

namespace {

const char* g_last_artifact_path = nullptr;
const char* g_last_manifest_path = nullptr;
const char* g_last_arch = nullptr;
const char* g_last_channel = nullptr;
const char* g_last_cache_dir = nullptr;
const char* g_last_platform = nullptr;
int g_last_patch_number = 0;
int g_setter_calls = 0;
int g_init_calls = 0;

int NoPatch(FcbLaunchPatch* out_patch) {
  out_patch->has_patch = 0;
  return 0;
}

int SnapshotPatch(FcbLaunchPatch* out_patch) {
  out_patch->has_patch = 1;
  out_patch->patch_number = 7;
  out_patch->backend = "snapshot_replace";
  out_patch->artifact_path = "/data/user/0/app/cache/fcb/patches/7/libapp.so";
  out_patch->manifest_path = "/data/user/0/app/cache/fcb/patches/7/manifest.json";
  return 0;
}

int SnapshotPatchWithoutArtifact(FcbLaunchPatch* out_patch) {
  out_patch->has_patch = 1;
  out_patch->patch_number = 7;
  out_patch->backend = "snapshot_replace";
  out_patch->artifact_path = nullptr;
  return 0;
}

int BytecodePatch(FcbLaunchPatch* out_patch) {
  out_patch->has_patch = 1;
  out_patch->patch_number = 8;
  out_patch->backend = "bytecode";
  out_patch->bytecode_path = "/data/user/0/app/cache/fcb/patches/8/payload.bin";
  return 0;
}

int UpdaterError(FcbLaunchPatch* out_patch) {
  (void)out_patch;
  return -1;
}

int CaptureInit(const FcbInitParams* params) {
  ++g_init_calls;
  g_last_arch = params->arch;
  g_last_channel = params->channel;
  g_last_cache_dir = params->cache_dir;
  g_last_platform = params->platform;
  return 0;
}

int RejectInit(const FcbInitParams* params) {
  (void)params;
  return -1;
}

int CaptureAotPath(const char* artifact_path,
                   const char* manifest_path,
                   int patch_number) {
  ++g_setter_calls;
  g_last_artifact_path = artifact_path;
  g_last_manifest_path = manifest_path;
  g_last_patch_number = patch_number;
  return 0;
}

int RejectAotPath(const char* artifact_path,
                  const char* manifest_path,
                  int patch_number) {
  (void)artifact_path;
  (void)manifest_path;
  (void)patch_number;
  return -1;
}

void ResetCapture() {
  g_last_artifact_path = nullptr;
  g_last_manifest_path = nullptr;
  g_last_arch = nullptr;
  g_last_channel = nullptr;
  g_last_cache_dir = nullptr;
  g_last_platform = nullptr;
  g_last_patch_number = 0;
  g_setter_calls = 0;
  g_init_calls = 0;
}

}  // namespace

int main() {
  FcbEnginePatchDecision decision = {};

  assert(fcb_resolve_engine_patch(nullptr, &decision) == -1);
  assert(fcb_resolve_engine_patch(NoPatch, nullptr) == -1);

  assert(fcb_resolve_engine_patch(NoPatch, &decision) == 0);
  assert(decision.use_snapshot_artifact == 0);

  assert(fcb_resolve_engine_patch(SnapshotPatch, &decision) == 1);
  assert(decision.use_snapshot_artifact == 1);
  assert(decision.patch_number == 7);
  assert(std::strcmp(decision.backend, "snapshot_replace") == 0);
  assert(std::strcmp(decision.artifact_path,
                     "/data/user/0/app/cache/fcb/patches/7/libapp.so") == 0);

  assert(fcb_resolve_engine_patch(BytecodePatch, &decision) == 0);
  assert(decision.use_snapshot_artifact == 0);

  assert(fcb_resolve_engine_patch(SnapshotPatchWithoutArtifact, &decision) == -1);
  assert(fcb_resolve_engine_patch(UpdaterError, &decision) == -1);

  ResetCapture();
  assert(fcb_apply_android_snapshot_replace(SnapshotPatch, CaptureAotPath) == 1);
  assert(g_setter_calls == 1);
  assert(g_last_patch_number == 7);
  assert(std::strcmp(g_last_artifact_path,
                     "/data/user/0/app/cache/fcb/patches/7/libapp.so") == 0);
  assert(std::strcmp(g_last_manifest_path,
                     "/data/user/0/app/cache/fcb/patches/7/manifest.json") == 0);

  ResetCapture();
  assert(fcb_apply_android_snapshot_replace(NoPatch, CaptureAotPath) == 0);
  assert(g_setter_calls == 0);

  assert(fcb_apply_android_snapshot_replace(SnapshotPatch, RejectAotPath) == -1);
  assert(fcb_apply_android_snapshot_replace(SnapshotPatch, nullptr) == -1);

  ResetCapture();
  FcbAndroidSnapshotReplaceConfig config = {};
  config.cache_dir = "/data/user/0/com.example/cache/fcb";
  config.arch = "arm64-v8a";
  config.symbols.init = CaptureInit;
  config.symbols.get_launch_patch = SnapshotPatch;
  assert(fcb_apply_android_snapshot_replace_with_config(&config,
                                                        CaptureAotPath) == 1);
  assert(g_init_calls == 1);
  assert(std::strcmp(g_last_cache_dir,
                     "/data/user/0/com.example/cache/fcb") == 0);
  assert(std::strcmp(g_last_platform, "android") == 0);
  assert(std::strcmp(g_last_arch, "arm64-v8a") == 0);
  assert(std::strcmp(g_last_channel, "stable") == 0);
  assert(g_setter_calls == 1);

  ResetCapture();
  config = {};
  config.cache_dir = "/data/user/0/com.example/cache/fcb";
  config.arch = "";
  config.channel = "";
  config.symbols.init = CaptureInit;
  config.symbols.get_launch_patch = NoPatch;
  assert(fcb_apply_android_snapshot_replace_with_config(&config,
                                                        CaptureAotPath) == 0);
  assert(g_init_calls == 1);
  assert(std::strcmp(g_last_arch, "arm64-v8a") == 0);
  assert(std::strcmp(g_last_channel, "stable") == 0);
  assert(g_setter_calls == 0);

  ResetCapture();
  config.symbols.get_launch_patch = BytecodePatch;
  assert(fcb_apply_android_snapshot_replace_with_config(&config,
                                                        CaptureAotPath) == 0);
  assert(g_init_calls == 1);
  assert(g_setter_calls == 0);

  ResetCapture();
  config.cache_dir = nullptr;
  config.symbols.get_launch_patch = SnapshotPatch;
  assert(fcb_apply_android_snapshot_replace_with_config(&config,
                                                        CaptureAotPath) == -1);
  assert(g_init_calls == 0);
  assert(g_setter_calls == 0);

  config.cache_dir = "";
  assert(fcb_apply_android_snapshot_replace_with_config(&config,
                                                        CaptureAotPath) == -1);
  assert(g_init_calls == 0);
  assert(g_setter_calls == 0);

  config.cache_dir = "/data/user/0/com.example/cache/fcb";
  config.symbols.init = RejectInit;
  assert(fcb_apply_android_snapshot_replace_with_config(&config,
                                                        CaptureAotPath) == -1);
  assert(fcb_apply_android_snapshot_replace_with_config(nullptr,
                                                        CaptureAotPath) == -1);
  return 0;
}
