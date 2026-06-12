// FCB Android JNI bridge.
//
// This file provides the JNI native method that FlutterLoader.java calls
// via tryInitFcb() to initialize the FCB updater before the Engine starts.
// The init call configures the updater's cache directory and public key
// so that fcb::ResolveAndroidSnapshotReplace() can find a ready patch
// when switches.cc runs.

#include <jni.h>
#include <android/log.h>
#include <cstring>
#include <cstdlib>
#include <string>

// Include the updater FFI header for fcb_init and FcbInitParams.
#include "fcb_engine_hook.h"

#ifdef __cplusplus
extern "C" {
#endif

// FcbInitParams must match the Rust definition in updater/src/lib.rs.
struct FcbInitParams {
  const char* app_id;
  const char* channel;
  const char* release_version;
  const char* platform;
  const char* arch;
  const char* cache_dir;
  const char* public_key_pem;
  int check_on_startup;
};

// Rust FFI entry points (linked from libfcb_updater).
extern int fcb_init(const FcbInitParams* params);
extern int fcb_set_server_url(const char* server_url);
extern int fcb_set_client_id(const char* client_id);
extern int fcb_set_baseline_artifact_path(const char* path);

#ifdef __cplusplus
}  // extern "C"
#endif

namespace {

const char* kTag = "FCB";

}  // namespace

// Called from FlutterLoader.tryInitFcb() via JNI.
// Configures the updater with the app's cache directory and public key.
// Returns 0 on success, non-zero on failure.
extern "C" JNIEXPORT jint JNICALL
Java_io_flutter_embedding_engine_loader_FlutterLoader_nativeFcbInit(
    JNIEnv* env,
    jobject /* this */,
    jstring j_cache_dir,
    jstring j_public_key) {
  if (!j_cache_dir) {
    __android_log_print(ANDROID_LOG_WARN, kTag, "nativeFcbInit: cache_dir is null");
    return -1;
  }

  const char* cache_dir = env->GetStringUTFChars(j_cache_dir, nullptr);
  if (!cache_dir) {
    __android_log_print(ANDROID_LOG_WARN, kTag, "nativeFcbInit: failed to get cache_dir string");
    return -1;
  }

  const char* public_key = nullptr;
  if (j_public_key) {
    public_key = env->GetStringUTFChars(j_public_key, nullptr);
  }

  FcbInitParams params = {};
  params.app_id = "";         // Set from Dart package via fcb_set_server_url
  params.channel = "stable";
  params.release_version = ""; // Set from Dart package
  params.platform = "android";
  params.arch = "arm64-v8a";
  params.cache_dir = cache_dir;
  params.public_key_pem = public_key ? public_key : "";
  params.check_on_startup = 0;

  int rc = fcb_init(&params);

  env->ReleaseStringUTFChars(j_cache_dir, cache_dir);
  if (public_key && j_public_key) {
    env->ReleaseStringUTFChars(j_public_key, public_key);
  }

  if (rc != 0) {
    __android_log_print(ANDROID_LOG_WARN, kTag, "fcb_init returned %d", rc);
  } else {
    __android_log_print(ANDROID_LOG_INFO, kTag, "FCB updater initialized");
  }
  return rc;
}
