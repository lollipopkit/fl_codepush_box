#include "fcb_engine_hook.h"

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

}  // namespace

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
