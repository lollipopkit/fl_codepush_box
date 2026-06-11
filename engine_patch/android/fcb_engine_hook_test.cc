#include "fcb_engine_hook.h"

#include <cassert>
#include <cstring>

extern "C" int fcb_get_launch_patch(FcbLaunchPatch* out_patch) {
  (void)out_patch;
  return -1;
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
  return 0;
}
