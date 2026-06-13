#include "fcb_engine_hook.h"

#include <cassert>
#include <cstring>

extern "C" int fcb_get_launch_patch(FcbLaunchPatch* out_patch) {
  // fcb_get_launch_patch(FcbLaunchPatch*) is a linker/test placeholder that always errors.
  (void)out_patch;
  return -1;
}

extern "C" int fcb_init(const FcbInitParams* params) {
  (void)params;
  return 0;
}

extern "C" int fcb_mark_launch_success() {
  return 0;
}

namespace {

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

int SetAotArtifactPath(void* user_data, const char* artifact_path) {
  auto** out_path = static_cast<const char**>(user_data);
  *out_path = artifact_path;
  return 0;
}

int SetAotArtifactPathFails(void* user_data, const char* artifact_path) {
  (void)user_data;
  (void)artifact_path;
  return -1;
}

int MarkLaunchSuccess() {
  return 0;
}

int MarkLaunchSuccessFails() {
  return -1;
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

  const char* applied_path = nullptr;
  assert(fcb_apply_android_snapshot_replace(SnapshotPatch, SetAotArtifactPath,
                                            &applied_path, &decision) == 1);
  assert(std::strcmp(applied_path,
                     "/data/user/0/app/cache/fcb/patches/7/libapp.so") == 0);

  assert(fcb_apply_android_snapshot_replace(NoPatch, SetAotArtifactPath,
                                            &applied_path, &decision) == 0);
  assert(fcb_apply_android_snapshot_replace(SnapshotPatch,
                                            SetAotArtifactPathFails,
                                            &applied_path, &decision) == -1);
  assert(fcb_apply_android_snapshot_replace(SnapshotPatch, nullptr,
                                            &applied_path, &decision) == -1);

  assert(fcb_mark_android_launch_success(MarkLaunchSuccess) == 0);
  assert(fcb_mark_android_launch_success(MarkLaunchSuccessFails) == -1);
  assert(fcb_mark_android_launch_success(nullptr) == -1);
  return 0;
}
