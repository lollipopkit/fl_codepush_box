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

int fcb_apply_android_snapshot_replace(
    FcbGetLaunchPatchFn get_launch_patch,
    FcbSetAotArtifactPathFn set_aot_artifact_path,
    void* user_data,
    FcbEnginePatchDecision* out_decision) {
  if (set_aot_artifact_path == nullptr) {
    return -1;
  }
  FcbEnginePatchDecision decision = {};
  FcbEnginePatchDecision* target_decision =
      out_decision == nullptr ? &decision : out_decision;
  const int rc = fcb_resolve_engine_patch(get_launch_patch, target_decision);
  if (rc != 1) {
    return rc;
  }
  return set_aot_artifact_path(user_data, target_decision->artifact_path) == 0
             ? 1
             : -1;
}

int fcb_mark_android_launch_success(
    FcbMarkLaunchSuccessFn mark_launch_success) {
  if (mark_launch_success == nullptr) {
    return -1;
  }
  return mark_launch_success();
}

int fcb_resolve_android_snapshot_replace(
    FcbEnginePatchDecision* out_decision) {
  return fcb_resolve_engine_patch(fcb_get_launch_patch, out_decision);
}
