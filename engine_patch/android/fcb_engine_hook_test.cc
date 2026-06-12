#include "fcb_engine_hook.h"

#include <cassert>
#include <cstring>

// Stub for the production FFI symbol. The real fcb_get_launch_patch is
// provided by libfcb_updater at link time; this stub always returns an error
// so that unit tests can inject their own callback via
// fcb::ResolveEnginePatch.
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
  out_patch->artifact_path =
      "/data/user/0/app/cache/.fcb/patches/7/libapp.so";
  out_patch->manifest_path =
      "/data/user/0/app/cache/.fcb/patches/7/manifest.json";
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
  out_patch->bytecode_path =
      "/data/user/0/app/cache/.fcb/patches/8/payload.bin";
  return 0;
}

int UpdaterError(FcbLaunchPatch* out_patch) {
  (void)out_patch;
  return -1;
}

}  // namespace

int main() {
  fcb::EnginePatchDecision decision = {};

  // Null arguments are rejected.
  assert(fcb::ResolveEnginePatch(nullptr, &decision) == -1);
  assert(fcb::ResolveEnginePatch(NoPatch, nullptr) == -1);

  // No patch available: returns 0, no override.
  assert(fcb::ResolveEnginePatch(NoPatch, &decision) == 0);
  assert(decision.use_snapshot_artifact == 0);

  // snapshot_replace patch: returns 1, artifact path is set.
  assert(fcb::ResolveEnginePatch(SnapshotPatch, &decision) == 1);
  assert(decision.use_snapshot_artifact == 1);
  assert(decision.patch_number == 7);
  assert(std::strcmp(decision.backend, "snapshot_replace") == 0);
  assert(std::strcmp(decision.artifact_path,
                     "/data/user/0/app/cache/.fcb/patches/7/libapp.so") == 0);

  // Bytecode patch: returns 0 (no Engine artifact override needed).
  assert(fcb::ResolveEnginePatch(BytecodePatch, &decision) == 0);
  assert(decision.use_snapshot_artifact == 0);

  // snapshot_replace with null artifact_path: returns -1.
  assert(fcb::ResolveEnginePatch(SnapshotPatchWithoutArtifact, &decision) ==
         -1);

  // Updater error: returns -1.
  assert(fcb::ResolveEnginePatch(UpdaterError, &decision) == -1);

  return 0;
}
