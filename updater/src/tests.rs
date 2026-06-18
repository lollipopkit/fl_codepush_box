use super::{
    fcb_active_patch_number, fcb_cancel_pending_operations, fcb_check_for_update_blocking,
    fcb_crash_rollback_history_json, fcb_download_and_install_blocking, fcb_drain_rollback_events,
    fcb_get_interpreter_stats, fcb_get_launch_patch, fcb_init, fcb_is_new_patch_ready_to_install,
    fcb_last_check_patch_number, fcb_last_known_good_patch_number, fcb_mark_launch_failure,
    fcb_mark_launch_success, fcb_record_aot_call, fcb_record_interpreter_call,
    fcb_report_interpret_failure, fcb_reset_interpreter_stats, fcb_set_org_id, fcb_set_server_url,
    parse_interpret_failure_location, post_interpret_failure_event, FcbInitParams, FcbLaunchPatch,
    Runtime,
};
use fcb_core::crypto;
use fcb_core::manifest::{self, PatchManifest, PatchPolicy, PatchSignature, PayloadManifest};
use fcb_core::state::{InstalledPatch, LastLaunch, State, Updater};
use std::ffi::{CStr, CString};
use std::io::{Read, Write};
use std::net::{TcpListener, TcpStream};
use std::sync::atomic::{AtomicUsize, Ordering};
use std::sync::{mpsc, Arc, Barrier, Mutex, MutexGuard, OnceLock};
use std::time::{Duration, Instant};

static TEST_LOCK: Mutex<()> = Mutex::new(());
static DRAINED_EVENTS: OnceLock<Mutex<Vec<String>>> = OnceLock::new();

fn test_lock() -> MutexGuard<'static, ()> {
    TEST_LOCK
        .lock()
        .unwrap_or_else(|poisoned| poisoned.into_inner())
}

#[test]
fn get_launch_patch_returns_snapshot_artifact_path() {
    let _guard = test_lock();
    let cache_dir = std::env::temp_dir().join(format!(
        "fcb-updater-ffi-test-{}",
        std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .expect("time")
            .as_nanos()
    ));
    let updater = Updater::new(&cache_dir);
    updater
        .save_state(&State {
            schema_version: 1,
            release_version: "1.0.0+1".to_string(),
            current_patch_number: 0,
            pending_patch_number: Some(3),
            last_known_good_patch_number: None,
            boot_attempts: 0,
            bad_patches: Vec::new(),
            last_launch: None,
            installed: vec![InstalledPatch {
                patch_number: 3,
                backend: "snapshot_replace".to_string(),
                manifest_path: "patches/3/manifest.json".to_string(),
                payload_path: "patches/3/payload.bin".to_string(),
                artifact_path: Some("patches/3/libapp.so".to_string()),
                installed_at: "0".to_string(),
            }],
        })
        .expect("write state");

    let cache_dir_c = CString::new(cache_dir.to_string_lossy().as_bytes()).expect("cache dir");
    let params = FcbInitParams {
        app_id: std::ptr::null(),
        channel: std::ptr::null(),
        release_version: std::ptr::null(),
        platform: std::ptr::null(),
        arch: std::ptr::null(),
        cache_dir: cache_dir_c.as_ptr(),
        public_key_pem: std::ptr::null(),
        check_on_startup: 0,
    };
    assert_eq!(unsafe { fcb_init(&params) }, 0);

    let mut patch = FcbLaunchPatch {
        has_patch: 0,
        patch_number: 0,
        backend: std::ptr::null(),
        artifact_path: std::ptr::null(),
        bytecode_path: std::ptr::null(),
        manifest_path: std::ptr::null(),
    };
    assert_eq!(unsafe { fcb_get_launch_patch(&mut patch) }, 0);
    assert_eq!(patch.has_patch, 1);
    assert_eq!(patch.patch_number, 3);
    assert!(patch.bytecode_path.is_null());
    assert_eq!(
        unsafe { CStr::from_ptr(patch.artifact_path) }
            .to_string_lossy()
            .as_ref(),
        cache_dir.join("patches/3/libapp.so").to_string_lossy()
    );

    let _ = std::fs::remove_dir_all(cache_dir);
}

#[test]
fn ready_check_does_not_mark_launch_pending() {
    let _guard = test_lock();
    let cache_dir = std::env::temp_dir().join(format!(
        "fcb-updater-ready-test-{}",
        std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .expect("time")
            .as_nanos()
    ));
    let updater = Updater::new(&cache_dir);
    updater
        .save_state(&State {
            schema_version: 1,
            release_version: "1.0.0+1".to_string(),
            current_patch_number: 0,
            pending_patch_number: Some(4),
            last_known_good_patch_number: None,
            boot_attempts: 0,
            bad_patches: Vec::new(),
            last_launch: None,
            installed: vec![InstalledPatch {
                patch_number: 4,
                backend: "snapshot_replace".to_string(),
                manifest_path: "patches/4/manifest.json".to_string(),
                payload_path: "patches/4/payload.bin".to_string(),
                artifact_path: Some("patches/4/libapp.so".to_string()),
                installed_at: "0".to_string(),
            }],
        })
        .expect("write state");

    let cache_dir_c = CString::new(cache_dir.to_string_lossy().as_bytes()).expect("cache dir");
    let params = FcbInitParams {
        app_id: std::ptr::null(),
        channel: std::ptr::null(),
        release_version: std::ptr::null(),
        platform: std::ptr::null(),
        arch: std::ptr::null(),
        cache_dir: cache_dir_c.as_ptr(),
        public_key_pem: std::ptr::null(),
        check_on_startup: 0,
    };
    assert_eq!(unsafe { fcb_init(&params) }, 0);

    assert_eq!(fcb_is_new_patch_ready_to_install(), 1);
    assert!(updater
        .load_state()
        .expect("load state")
        .last_launch
        .is_none());

    let _ = std::fs::remove_dir_all(cache_dir);
}

#[test]
fn drain_rollback_events_returns_json_and_clears_log() {
    let _guard = test_lock();
    let cache_dir = std::env::temp_dir().join(format!(
        "fcb-updater-drain-test-{}",
        std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .expect("time")
            .as_nanos()
    ));
    let updater = Updater::new(&cache_dir);
    updater
        .save_state(&State {
            schema_version: 2,
            release_version: "1.0.0+1".to_string(),
            current_patch_number: 0,
            pending_patch_number: Some(8),
            last_known_good_patch_number: None,
            boot_attempts: 2,
            bad_patches: Vec::new(),
            last_launch: Some(fcb_core::state::LastLaunch {
                patch_number: 8,
                status: "pending_success".to_string(),
                started_at: "0".to_string(),
            }),
            installed: vec![InstalledPatch {
                patch_number: 8,
                backend: "bytecode".to_string(),
                manifest_path: "patches/8/manifest.json".to_string(),
                payload_path: "patches/8/payload.bin".to_string(),
                artifact_path: None,
                installed_at: "0".to_string(),
            }],
        })
        .expect("write state");
    updater.launch_patch().expect("trigger rollback");

    let cache_dir_c = CString::new(cache_dir.to_string_lossy().as_bytes()).expect("cache dir");
    let params = FcbInitParams {
        app_id: std::ptr::null(),
        channel: std::ptr::null(),
        release_version: std::ptr::null(),
        platform: std::ptr::null(),
        arch: std::ptr::null(),
        cache_dir: cache_dir_c.as_ptr(),
        public_key_pem: std::ptr::null(),
        check_on_startup: 0,
    };
    DRAINED_EVENTS
        .get_or_init(|| Mutex::new(Vec::new()))
        .lock()
        .expect("events lock")
        .clear();
    assert_eq!(unsafe { fcb_init(&params) }, 0);
    assert_eq!(unsafe { fcb_drain_rollback_events(Some(capture_event)) }, 1);

    let events = DRAINED_EVENTS
        .get()
        .expect("events")
        .lock()
        .expect("events lock");
    assert_eq!(events.len(), 1);
    assert!(events[0].contains(r#""event_type":"crash_rollback""#));
    assert!(events[0].contains(r#""patch_number":8"#));
    drop(events);
    assert!(updater
        .rollback_events()
        .expect("events cleared")
        .is_empty());
    let _ = std::fs::remove_dir_all(cache_dir);
}

#[test]
fn observability_ffi_returns_lkg_history_and_interpreter_stats() {
    let _guard = test_lock();
    let cache_dir = std::env::temp_dir().join(format!(
        "fcb-updater-observe-test-{}",
        std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .expect("time")
            .as_nanos()
    ));
    let updater = Updater::new(&cache_dir);
    updater
        .save_state(&State {
            schema_version: 2,
            release_version: "1.0.0+1".to_string(),
            current_patch_number: 4,
            pending_patch_number: Some(5),
            last_known_good_patch_number: Some(4),
            boot_attempts: 2,
            bad_patches: Vec::new(),
            last_launch: Some(fcb_core::state::LastLaunch {
                patch_number: 5,
                status: "pending_success".to_string(),
                started_at: "0".to_string(),
            }),
            installed: vec![
                InstalledPatch {
                    patch_number: 4,
                    backend: "bytecode".to_string(),
                    manifest_path: "patches/4/manifest.json".to_string(),
                    payload_path: "patches/4/payload.bin".to_string(),
                    artifact_path: None,
                    installed_at: "0".to_string(),
                },
                InstalledPatch {
                    patch_number: 5,
                    backend: "bytecode".to_string(),
                    manifest_path: "patches/5/manifest.json".to_string(),
                    payload_path: "patches/5/payload.bin".to_string(),
                    artifact_path: None,
                    installed_at: "0".to_string(),
                },
            ],
        })
        .expect("write state");
    updater.launch_patch().expect("trigger rollback");

    let cache_dir_c = CString::new(cache_dir.to_string_lossy().as_bytes()).expect("cache dir");
    let params = FcbInitParams {
        app_id: std::ptr::null(),
        channel: std::ptr::null(),
        release_version: std::ptr::null(),
        platform: std::ptr::null(),
        arch: std::ptr::null(),
        cache_dir: cache_dir_c.as_ptr(),
        public_key_pem: std::ptr::null(),
        check_on_startup: 0,
    };
    assert_eq!(unsafe { fcb_init(&params) }, 0);
    assert_eq!(fcb_last_known_good_patch_number(), 4);

    let history = unsafe { CStr::from_ptr(fcb_crash_rollback_history_json(10)) }
        .to_string_lossy()
        .to_string();
    assert!(history.contains(r#""patch_number":5"#));

    fcb_reset_interpreter_stats();
    fcb_record_interpreter_call();
    fcb_record_interpreter_call();
    fcb_record_aot_call();
    let mut interpreted = 0_u64;
    let mut aot = 0_u64;
    assert_eq!(
        unsafe { fcb_get_interpreter_stats(&mut interpreted, &mut aot) },
        0
    );
    assert_eq!((interpreted, aot), (2, 1));

    let _ = std::fs::remove_dir_all(cache_dir);
}

#[test]
fn get_launch_patch_rolls_back_to_lkg_after_three_failed_launches() {
    let _guard = test_lock();
    let cache_dir = std::env::temp_dir().join(format!(
        "fcb-updater-crash-loop-ffi-test-{}",
        std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .expect("time")
            .as_nanos()
    ));
    let updater = Updater::new(&cache_dir);
    updater
        .save_state(&State {
            schema_version: 2,
            release_version: "1.0.0+1".to_string(),
            current_patch_number: 4,
            pending_patch_number: Some(5),
            last_known_good_patch_number: Some(4),
            boot_attempts: 0,
            bad_patches: Vec::new(),
            last_launch: None,
            installed: vec![
                InstalledPatch {
                    patch_number: 4,
                    backend: "bytecode".to_string(),
                    manifest_path: "patches/4/manifest.json".to_string(),
                    payload_path: "patches/4/payload.bin".to_string(),
                    artifact_path: None,
                    installed_at: "0".to_string(),
                },
                InstalledPatch {
                    patch_number: 5,
                    backend: "bytecode".to_string(),
                    manifest_path: "patches/5/manifest.json".to_string(),
                    payload_path: "patches/5/payload.bin".to_string(),
                    artifact_path: None,
                    installed_at: "0".to_string(),
                },
            ],
        })
        .expect("write state");

    let cache_dir_c = CString::new(cache_dir.to_string_lossy().as_bytes()).expect("cache dir");
    let params = FcbInitParams {
        app_id: std::ptr::null(),
        channel: std::ptr::null(),
        release_version: std::ptr::null(),
        platform: std::ptr::null(),
        arch: std::ptr::null(),
        cache_dir: cache_dir_c.as_ptr(),
        public_key_pem: std::ptr::null(),
        check_on_startup: 0,
    };
    assert_eq!(unsafe { fcb_init(&params) }, 0);

    let mut patch = empty_launch_patch();
    assert_eq!(unsafe { fcb_get_launch_patch(&mut patch) }, 0);
    assert_eq!(patch.has_patch, 1);
    assert_eq!(patch.patch_number, 5);

    let mut patch = empty_launch_patch();
    assert_eq!(unsafe { fcb_get_launch_patch(&mut patch) }, 0);
    assert_eq!(patch.has_patch, 1);
    assert_eq!(patch.patch_number, 5);

    let mut patch = empty_launch_patch();
    assert_eq!(unsafe { fcb_get_launch_patch(&mut patch) }, 0);
    assert_eq!(patch.has_patch, 1);
    assert_eq!(patch.patch_number, 4);

    let state = updater.load_state().expect("state");
    assert_eq!(state.current_patch_number, 4);
    assert_eq!(state.pending_patch_number, None);
    assert_eq!(state.last_known_good_patch_number, Some(4));
    assert!(state.bad_patches.contains(&5));
    assert_eq!(state.boot_attempts, 1);
    assert_eq!(
        state.last_launch.as_ref().map(|launch| launch.patch_number),
        Some(4)
    );

    let history = unsafe { CStr::from_ptr(fcb_crash_rollback_history_json(10)) }
        .to_string_lossy()
        .to_string();
    let events: serde_json::Value = serde_json::from_str(&history).expect("history json");
    assert_eq!(events[0]["event_type"], "crash_rollback");
    assert_eq!(events[0]["patch_number"], 5);
    assert_eq!(events[0]["boot_attempts"], 3);
    assert_eq!(events[0]["last_known_good_patch_number"], 4);

    let _ = std::fs::remove_dir_all(cache_dir);
}

#[test]
fn mark_launch_success_posts_interpreter_ratio_event() {
    let _guard = test_lock();
    let cache_dir = std::env::temp_dir().join(format!(
        "fcb-updater-launch-success-event-test-{}",
        std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .expect("time")
            .as_nanos()
    ));
    Updater::new(&cache_dir)
        .save_state(&State {
            schema_version: 2,
            release_version: "1.0.0+1".to_string(),
            current_patch_number: 0,
            pending_patch_number: Some(6),
            last_known_good_patch_number: None,
            boot_attempts: 1,
            bad_patches: Vec::new(),
            last_launch: Some(fcb_core::state::LastLaunch {
                patch_number: 6,
                status: "pending_success".to_string(),
                started_at: "0".to_string(),
            }),
            installed: vec![InstalledPatch {
                patch_number: 6,
                backend: "bytecode".to_string(),
                manifest_path: "patches/6/manifest.json".to_string(),
                payload_path: "patches/6/payload.bin".to_string(),
                artifact_path: None,
                installed_at: "0".to_string(),
            }],
        })
        .expect("write state");

    let (server_url, request_rx) = spawn_single_event_server(200);
    let cache_dir_c = CString::new(cache_dir.to_string_lossy().as_bytes()).expect("cache dir");
    let app_id_c = CString::new("stats-app").expect("app id");
    let release_c = CString::new("1.0.0+1").expect("release");
    let channel_c = CString::new("stable").expect("channel");
    let platform_c = CString::new("android").expect("platform");
    let arch_c = CString::new("arm64-v8a").expect("arch");
    let server_url_c = CString::new(server_url).expect("server url");
    let org_id_c = CString::new("acme").expect("org id");
    let params = FcbInitParams {
        app_id: app_id_c.as_ptr(),
        channel: channel_c.as_ptr(),
        release_version: release_c.as_ptr(),
        platform: platform_c.as_ptr(),
        arch: arch_c.as_ptr(),
        cache_dir: cache_dir_c.as_ptr(),
        public_key_pem: std::ptr::null(),
        check_on_startup: 0,
    };
    assert_eq!(unsafe { fcb_init(&params) }, 0);
    assert_eq!(unsafe { fcb_set_server_url(server_url_c.as_ptr()) }, 0);
    assert_eq!(unsafe { fcb_set_org_id(org_id_c.as_ptr()) }, 0);

    fcb_reset_interpreter_stats();
    fcb_record_interpreter_call();
    fcb_record_interpreter_call();
    fcb_record_aot_call();
    fcb_record_aot_call();
    fcb_record_aot_call();
    assert_eq!(fcb_mark_launch_success(), 0);

    let request = request_rx.recv().expect("launch success event post");
    assert!(request.starts_with("POST /v1/events "), "{request}");
    let body = request.split("\r\n\r\n").nth(1).expect("request body");
    let event: serde_json::Value = serde_json::from_str(body).expect("event json");
    assert_eq!(event["org_id"], "acme");
    assert_eq!(event["event_type"], "launch_success");
    assert_eq!(event["patch_number"], 6);
    assert_eq!(event["payload"]["interpreted_function_calls"], 2);
    assert_eq!(event["payload"]["aot_function_calls"], 3);
    assert_eq!(event["payload"]["interpreter_ratio"], 0.4);

    let _ = std::fs::remove_dir_all(cache_dir);
}

#[test]
fn mark_launch_failure_posts_reason_and_interpreter_ratio_event() {
    let _guard = test_lock();
    let cache_dir = std::env::temp_dir().join(format!(
        "fcb-updater-launch-failure-event-test-{}",
        std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .expect("time")
            .as_nanos()
    ));
    let (server_url, request_rx) = spawn_single_event_server(200);
    let cache_dir_c = CString::new(cache_dir.to_string_lossy().as_bytes()).expect("cache dir");
    let app_id_c = CString::new("failure-app").expect("app id");
    let release_c = CString::new("1.0.0+1").expect("release");
    let channel_c = CString::new("stable").expect("channel");
    let platform_c = CString::new("android").expect("platform");
    let arch_c = CString::new("arm64-v8a").expect("arch");
    let server_url_c = CString::new(server_url).expect("server url");
    let reason_c = CString::new("first-frame-failed").expect("reason");
    let params = FcbInitParams {
        app_id: app_id_c.as_ptr(),
        channel: channel_c.as_ptr(),
        release_version: release_c.as_ptr(),
        platform: platform_c.as_ptr(),
        arch: arch_c.as_ptr(),
        cache_dir: cache_dir_c.as_ptr(),
        public_key_pem: std::ptr::null(),
        check_on_startup: 0,
    };
    assert_eq!(unsafe { fcb_init(&params) }, 0);
    assert_eq!(unsafe { fcb_set_server_url(server_url_c.as_ptr()) }, 0);

    fcb_reset_interpreter_stats();
    fcb_record_interpreter_call();
    fcb_record_aot_call();
    fcb_record_aot_call();
    assert_eq!(unsafe { fcb_mark_launch_failure(12, reason_c.as_ptr()) }, 0);

    let state = Updater::new(&cache_dir).load_state().expect("state");
    assert!(state.bad_patches.contains(&12));
    let request = request_rx.recv().expect("launch failure event post");
    assert!(request.starts_with("POST /v1/events "), "{request}");
    let body = request.split("\r\n\r\n").nth(1).expect("request body");
    let event: serde_json::Value = serde_json::from_str(body).expect("event json");
    assert_eq!(event["event_type"], "launch_failure");
    assert_eq!(event["patch_number"], 12);
    assert_eq!(event["payload"]["reason"], "first-frame-failed");
    assert_eq!(event["payload"]["error_message"], "first-frame-failed");
    assert_eq!(event["payload"]["interpreted_function_calls"], 1);
    assert_eq!(event["payload"]["aot_function_calls"], 2);
    assert_eq!(event["payload"]["interpreter_ratio"], 1.0 / 3.0);

    let _ = std::fs::remove_dir_all(cache_dir);
}

#[test]
fn report_interpret_failure_marks_bad_patch_and_posts_crash_event() {
    let _guard = test_lock();
    let cache_dir = std::env::temp_dir().join(format!(
        "fcb-updater-interpret-failure-event-test-{}",
        std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .expect("time")
            .as_nanos()
    ));
    let (server_url, request_rx) = spawn_single_event_server(200);
    let cache_dir_c = CString::new(cache_dir.to_string_lossy().as_bytes()).expect("cache dir");
    let app_id_c = CString::new("interpret-failure-app").expect("app id");
    let release_c = CString::new("1.0.0+1").expect("release");
    let channel_c = CString::new("stable").expect("channel");
    let platform_c = CString::new("android").expect("platform");
    let arch_c = CString::new("arm64-v8a").expect("arch");
    let server_url_c = CString::new(server_url).expect("server url");
    let function_id_c = CString::new("package:app/main.dart::build").expect("function id");
    let error_c = CString::new("unsupported opcode 0xfe").expect("error");
    let params = FcbInitParams {
        app_id: app_id_c.as_ptr(),
        channel: channel_c.as_ptr(),
        release_version: release_c.as_ptr(),
        platform: platform_c.as_ptr(),
        arch: arch_c.as_ptr(),
        cache_dir: cache_dir_c.as_ptr(),
        public_key_pem: std::ptr::null(),
        check_on_startup: 0,
    };
    assert_eq!(unsafe { fcb_init(&params) }, 0);
    assert_eq!(unsafe { fcb_set_server_url(server_url_c.as_ptr()) }, 0);

    fcb_reset_interpreter_stats();
    fcb_record_interpreter_call();
    fcb_record_aot_call();
    assert_eq!(
        unsafe { fcb_report_interpret_failure(21, function_id_c.as_ptr(), error_c.as_ptr()) },
        0
    );

    let state = Updater::new(&cache_dir).load_state().expect("state");
    assert!(state.bad_patches.contains(&21));
    let last_launch = state.last_launch.expect("last launch");
    assert_eq!(last_launch.patch_number, 21);
    assert!(
        last_launch
            .status
            .contains("interpret_failure:package:app/main.dart::build:unsupported opcode 0xfe"),
        "{}",
        last_launch.status
    );

    let request = request_rx.recv().expect("interpret failure event post");
    assert!(request.starts_with("POST /v1/events "), "{request}");
    let body = request.split("\r\n\r\n").nth(1).expect("request body");
    let event: serde_json::Value = serde_json::from_str(body).expect("event json");
    assert_eq!(event["event_type"], "crash_rollback");
    assert_eq!(event["patch_number"], 21);
    assert_eq!(event["payload"]["reason"], "interpret_failure");
    assert_eq!(
        event["payload"]["function_id"],
        "package:app/main.dart::build"
    );
    assert_eq!(event["payload"]["error_message"], "unsupported opcode 0xfe");
    assert!(event["payload"]["bytecode_offset"].is_null());
    assert!(event["payload"]["source_location"].is_null());
    assert_eq!(event["payload"]["interpreted_function_calls"], 1);
    assert_eq!(event["payload"]["aot_function_calls"], 1);
    assert_eq!(event["payload"]["interpreter_ratio"], 0.5);

    let _ = std::fs::remove_dir_all(cache_dir);
}

#[test]
fn interpret_failure_event_hydrates_persisted_runtime_config() {
    let _guard = test_lock();
    let cache_dir = std::env::temp_dir().join(format!(
        "fcb-updater-runtime-config-hydrate-test-{}",
        std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .expect("time")
            .as_nanos()
    ));
    let (server_url, request_rx) = spawn_single_event_server(200);
    let cache_dir_c = CString::new(cache_dir.to_string_lossy().as_bytes()).expect("cache dir");
    let app_id_c = CString::new("hydrate-app").expect("app id");
    let release_c = CString::new("1.0.0+1").expect("release");
    let channel_c = CString::new("stable").expect("channel");
    let platform_c = CString::new("android").expect("platform");
    let arch_c = CString::new("arm64-v8a").expect("arch");
    let server_url_c = CString::new(server_url).expect("server url");
    let params = FcbInitParams {
        app_id: app_id_c.as_ptr(),
        channel: channel_c.as_ptr(),
        release_version: release_c.as_ptr(),
        platform: platform_c.as_ptr(),
        arch: arch_c.as_ptr(),
        cache_dir: cache_dir_c.as_ptr(),
        public_key_pem: std::ptr::null(),
        check_on_startup: 0,
    };
    assert_eq!(unsafe { fcb_init(&params) }, 0);
    assert_eq!(unsafe { fcb_set_server_url(server_url_c.as_ptr()) }, 0);

    let mut engine_runtime = Runtime::new();
    engine_runtime.cache_dir = cache_dir.clone();
    post_interpret_failure_event(
        &mut engine_runtime,
        22,
        "package:app/main.dart::build",
        "Return stack underflow at bytecode offset 0 (package:app/main.dart:9:3 FCB patch)",
    )
    .expect("post hydrated interpret failure event");

    let request = request_rx.recv().expect("interpret failure event post");
    assert!(request.starts_with("POST /v1/events "), "{request}");
    let body = request.split("\r\n\r\n").nth(1).expect("request body");
    let event: serde_json::Value = serde_json::from_str(body).expect("event json");
    assert_eq!(event["app_id"], "hydrate-app");
    assert_eq!(event["event_type"], "crash_rollback");
    assert_eq!(event["patch_number"], 22);
    assert_eq!(event["payload"]["reason"], "interpret_failure");
    assert_eq!(event["payload"]["bytecode_offset"], 0);
    assert_eq!(
        event["payload"]["source_location"],
        "package:app/main.dart:9:3"
    );

    let _ = std::fs::remove_dir_all(cache_dir);
}

#[test]
fn parses_interpret_failure_location_from_vm_error() {
    let with_source = parse_interpret_failure_location(
        "Return stack underflow at bytecode offset 12 (package:app/main.dart:9:3 FCB patch)",
    );
    assert_eq!(with_source.bytecode_offset, Some(12));
    assert_eq!(
        with_source.source_location.as_deref(),
        Some("package:app/main.dart:9:3")
    );

    let without_source =
        parse_interpret_failure_location("Return stack underflow at bytecode offset 0 (FCB patch)");
    assert_eq!(without_source.bytecode_offset, Some(0));
    assert_eq!(without_source.source_location, None);

    let no_location = parse_interpret_failure_location("unsupported opcode 0xfe");
    assert_eq!(no_location.bytecode_offset, None);
    assert_eq!(no_location.source_location, None);
}

#[test]
fn active_patch_number_prefers_pending_launch() {
    let _guard = test_lock();
    let cache_dir = std::env::temp_dir().join(format!(
        "fcb-updater-active-patch-number-test-{}",
        std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .expect("time")
            .as_nanos()
    ));
    let updater = Updater::new(&cache_dir);
    updater
        .save_state(&State {
            schema_version: 2,
            release_version: "1.0.0+1".to_string(),
            current_patch_number: 0,
            pending_patch_number: Some(7),
            last_known_good_patch_number: None,
            boot_attempts: 1,
            bad_patches: Vec::new(),
            last_launch: Some(LastLaunch {
                patch_number: 7,
                status: "pending_success".to_string(),
                started_at: "1".to_string(),
            }),
            installed: vec![InstalledPatch {
                patch_number: 7,
                backend: "bytecode".to_string(),
                manifest_path: "patches/7/manifest.json".to_string(),
                payload_path: "patches/7/payload.bin".to_string(),
                artifact_path: None,
                installed_at: "0".to_string(),
            }],
        })
        .expect("write state");

    let cache_dir_c = CString::new(cache_dir.to_string_lossy().as_bytes()).expect("cache dir");
    let params = FcbInitParams {
        app_id: std::ptr::null(),
        channel: std::ptr::null(),
        release_version: std::ptr::null(),
        platform: std::ptr::null(),
        arch: std::ptr::null(),
        cache_dir: cache_dir_c.as_ptr(),
        public_key_pem: std::ptr::null(),
        check_on_startup: 0,
    };
    assert_eq!(unsafe { fcb_init(&params) }, 0);
    assert_eq!(fcb_active_patch_number(), 7);

    let _ = std::fs::remove_dir_all(cache_dir);
}

#[test]
fn cancel_pending_operations_is_safe_without_runtime() {
    assert_eq!(fcb_cancel_pending_operations(), 0);
}

#[test]
fn cancel_pending_operations_aborts_inflight_download_before_install() {
    let _guard = test_lock();
    let cache_dir = std::env::temp_dir().join(format!(
        "fcb-updater-cancel-test-{}",
        std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .expect("time")
            .as_nanos()
    ));
    let payload = br#"{"version":1,"functions":[{"name":"initialCounterValue","param_count":0,"local_count":0,"constants":[{"type":"Int","value":3}],"code":[1,0,0,255]}]}"#;
    let (private_key, public_key) = crypto::generate_keypair_b64();
    let mut patch = PatchManifest {
        schema_version: 1,
        app_id: "00000000-0000-0000-0000-000000000003".to_string(),
        release_version: "1.0.0+1".to_string(),
        patch_number: 11,
        channel: "stable".to_string(),
        created_at: "1970-01-01T00:00:00Z".to_string(),
        backend: "bytecode".to_string(),
        platform: "android".to_string(),
        arch: "arm64-v8a".to_string(),
        payload: PayloadManifest {
            kind: "bytecode_module".to_string(),
            compression: "none".to_string(),
            hash: crypto::sha256_hex(payload),
            size: payload.len() as u64,
            download_url: "/payload".to_string(),
            diff_algorithm: None,
            base_hash: None,
            output_hash: None,
        },
        policy: PatchPolicy {
            rollout_percentage: 100,
            allow_downgrade: false,
        },
        signature: PatchSignature {
            algorithm: "ed25519".to_string(),
            key_id: "dev".to_string(),
            value: String::new(),
        },
    };
    manifest::sign_patch_manifest(&mut patch, &private_key).expect("sign manifest");
    let manifest_bytes = serde_json::to_vec(&patch).expect("manifest json");
    let manifest_hash = crypto::sha256_hex(&manifest_bytes);
    let payload_hash = crypto::sha256_hex(payload);

    let listener = TcpListener::bind("127.0.0.1:0").expect("bind server");
    let server_url = format!("http://{}", listener.local_addr().expect("local addr"));
    let server_url_for_thread = server_url.clone();
    let (payload_requested_tx, payload_requested_rx) = mpsc::channel();
    let (release_payload_tx, release_payload_rx) = mpsc::channel();
    let server = std::thread::spawn(move || {
        for _ in 0..3 {
            let (mut stream, _) = listener.accept().expect("accept");
            let mut request = [0_u8; 2048];
            let n = stream.read(&mut request).expect("read request");
            let request = String::from_utf8_lossy(&request[..n]);
            let path = request
                .lines()
                .next()
                .and_then(|line| line.split_whitespace().nth(1))
                .unwrap_or("/");
            if path.starts_with("/v1/patches/check") {
                let body = serde_json::json!({
                    "patch_available": true,
                    "patch": {
                        "patch_number": 11,
                        "manifest_url": format!("{server_url_for_thread}/manifest"),
                        "payload_url": format!("{server_url_for_thread}/payload"),
                        "manifest_hash": manifest_hash,
                        "payload_hash": payload_hash,
                    }
                })
                .to_string();
                write_response(&mut stream, "application/json", body.as_bytes());
            } else if path == "/manifest" {
                write_response(&mut stream, "application/json", &manifest_bytes);
            } else if path == "/payload" {
                payload_requested_tx.send(()).expect("payload requested");
                release_payload_rx.recv().expect("release payload");
                write_response(&mut stream, "application/octet-stream", payload);
            } else {
                write_response(&mut stream, "text/plain", b"not found");
            }
        }
    });

    let cache_dir_c = CString::new(cache_dir.to_string_lossy().as_bytes()).expect("cache dir");
    let app_id_c = CString::new("00000000-0000-0000-0000-000000000003").expect("app id");
    let release_c = CString::new("1.0.0+1").expect("release");
    let channel_c = CString::new("stable").expect("channel");
    let platform_c = CString::new("android").expect("platform");
    let arch_c = CString::new("arm64-v8a").expect("arch");
    let public_key_c = CString::new(public_key).expect("public key");
    let server_url_c = CString::new(server_url).expect("server url");
    let params = FcbInitParams {
        app_id: app_id_c.as_ptr(),
        channel: channel_c.as_ptr(),
        release_version: release_c.as_ptr(),
        platform: platform_c.as_ptr(),
        arch: arch_c.as_ptr(),
        cache_dir: cache_dir_c.as_ptr(),
        public_key_pem: public_key_c.as_ptr(),
        check_on_startup: 0,
    };
    assert_eq!(unsafe { fcb_init(&params) }, 0);
    assert_eq!(unsafe { fcb_set_server_url(server_url_c.as_ptr()) }, 0);
    assert_eq!(fcb_check_for_update_blocking(), 1);

    let worker = std::thread::spawn(|| fcb_download_and_install_blocking());
    payload_requested_rx
        .recv_timeout(Duration::from_secs(2))
        .expect("payload request");
    assert_eq!(fcb_cancel_pending_operations(), 0);
    release_payload_tx.send(()).expect("release payload");

    assert_eq!(worker.join().expect("download worker"), -1);
    let last_error = unsafe { CStr::from_ptr(super::fcb_last_error()) }.to_string_lossy();
    assert!(last_error.contains("operation cancelled"), "{last_error}");
    assert!(!cache_dir.join("patches/11/payload.bin").exists());

    server.join().expect("server join");
    let _ = std::fs::remove_dir_all(cache_dir);
}

#[test]
fn concurrent_check_for_update_uses_single_inflight_request() {
    let _guard = test_lock();
    let cache_dir = std::env::temp_dir().join(format!(
        "fcb-updater-singleflight-test-{}",
        std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .expect("time")
            .as_nanos()
    ));
    let listener = TcpListener::bind("127.0.0.1:0").expect("bind server");
    listener.set_nonblocking(true).expect("nonblocking");
    let server_url = format!("http://{}", listener.local_addr().expect("local addr"));
    let request_count = Arc::new(AtomicUsize::new(0));
    let request_count_for_thread = Arc::clone(&request_count);
    let server = std::thread::spawn(move || {
        let deadline = Instant::now() + Duration::from_millis(800);
        while Instant::now() < deadline {
            match listener.accept() {
                Ok((mut stream, _)) => {
                    request_count_for_thread.fetch_add(1, Ordering::SeqCst);
                    let mut request = [0_u8; 1024];
                    let _ = stream.read(&mut request).expect("read request");
                    std::thread::sleep(Duration::from_millis(200));
                    write_response(
                        &mut stream,
                        "application/json",
                        br#"{"patch_available":false,"patch":null}"#,
                    );
                }
                Err(e) if e.kind() == std::io::ErrorKind::WouldBlock => {
                    std::thread::sleep(Duration::from_millis(10));
                }
                Err(e) => panic!("accept failed: {e}"),
            }
        }
    });

    let cache_dir_c = CString::new(cache_dir.to_string_lossy().as_bytes()).expect("cache dir");
    let app_id_c = CString::new("singleflight-app").expect("app id");
    let release_c = CString::new("1.0.0+1").expect("release");
    let channel_c = CString::new("stable").expect("channel");
    let platform_c = CString::new("android").expect("platform");
    let arch_c = CString::new("arm64-v8a").expect("arch");
    let server_url_c = CString::new(server_url).expect("server url");
    let params = FcbInitParams {
        app_id: app_id_c.as_ptr(),
        channel: channel_c.as_ptr(),
        release_version: release_c.as_ptr(),
        platform: platform_c.as_ptr(),
        arch: arch_c.as_ptr(),
        cache_dir: cache_dir_c.as_ptr(),
        public_key_pem: std::ptr::null(),
        check_on_startup: 0,
    };
    assert_eq!(unsafe { fcb_init(&params) }, 0);
    assert_eq!(unsafe { fcb_set_server_url(server_url_c.as_ptr()) }, 0);

    let barrier = Arc::new(Barrier::new(6));
    let workers: Vec<_> = (0..5)
        .map(|_| {
            let barrier = Arc::clone(&barrier);
            std::thread::spawn(move || {
                barrier.wait();
                fcb_check_for_update_blocking()
            })
        })
        .collect();
    barrier.wait();
    for worker in workers {
        assert_eq!(worker.join().expect("worker join"), 0);
    }
    server.join().expect("server join");
    assert_eq!(request_count.load(Ordering::SeqCst), 1);
    let _ = std::fs::remove_dir_all(cache_dir);
}

#[test]
fn check_and_download_install_over_http() {
    let _guard = test_lock();
    let cache_dir = std::env::temp_dir().join(format!(
        "fcb-updater-download-test-{}",
        std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .expect("time")
            .as_nanos()
    ));
    let payload = br#"{"version":1,"functions":[{"name":"initialCounterValue","param_count":0,"local_count":0,"constants":[{"type":"Int","value":2}],"code":[1,0,0,255]}]}"#;
    let (private_key, public_key) = crypto::generate_keypair_b64();
    let mut patch = PatchManifest {
        schema_version: 1,
        app_id: "00000000-0000-0000-0000-000000000001".to_string(),
        release_version: "1.0.0+1".to_string(),
        patch_number: 9,
        channel: "stable".to_string(),
        created_at: "1970-01-01T00:00:00Z".to_string(),
        backend: "bytecode".to_string(),
        platform: "android".to_string(),
        arch: "arm64-v8a".to_string(),
        payload: PayloadManifest {
            kind: "bytecode_module".to_string(),
            compression: "none".to_string(),
            hash: crypto::sha256_hex(payload),
            size: payload.len() as u64,
            download_url: "/payload".to_string(),
            diff_algorithm: None,
            base_hash: None,
            output_hash: None,
        },
        policy: PatchPolicy {
            rollout_percentage: 100,
            allow_downgrade: false,
        },
        signature: PatchSignature {
            algorithm: "ed25519".to_string(),
            key_id: "dev".to_string(),
            value: String::new(),
        },
    };
    manifest::sign_patch_manifest(&mut patch, &private_key).expect("sign manifest");
    let manifest_bytes = serde_json::to_vec(&patch).expect("manifest json");
    let manifest_hash = crypto::sha256_hex(&manifest_bytes);
    let payload_hash = crypto::sha256_hex(payload);

    let listener = TcpListener::bind("127.0.0.1:0").expect("bind server");
    let server_url = format!("http://{}", listener.local_addr().expect("local addr"));
    let server_url_for_thread = server_url.clone();
    let (event_tx, event_rx) = mpsc::channel();
    let server = std::thread::spawn(move || {
        for _ in 0..4 {
            let (mut stream, _) = listener.accept().expect("accept");
            let request = read_http_request(&mut stream);
            let path = request
                .lines()
                .next()
                .and_then(|line| line.split_whitespace().nth(1))
                .unwrap_or("/");
            if path.starts_with("/v1/patches/check") {
                let body = serde_json::json!({
                    "patch_available": true,
                        "patch": {
                            "patch_number": 9,
                        "manifest_url": format!("{server_url_for_thread}/manifest"),
                        "payload_url": format!("{server_url_for_thread}/payload"),
                        "manifest_hash": manifest_hash,
                        "payload_hash": payload_hash,
                    }
                })
                .to_string();
                write_response(&mut stream, "application/json", body.as_bytes());
            } else if path == "/manifest" {
                write_response(&mut stream, "application/json", &manifest_bytes);
            } else if path == "/payload" {
                write_response(&mut stream, "application/octet-stream", payload);
            } else if path == "/v1/events" {
                event_tx
                    .send(request.to_string())
                    .expect("send install event");
                write_status_response(&mut stream, 200, b"{}");
            } else {
                write_response(&mut stream, "text/plain", b"not found");
            }
        }
    });

    let cache_dir_c = CString::new(cache_dir.to_string_lossy().as_bytes()).expect("cache dir");
    let app_id_c = CString::new("00000000-0000-0000-0000-000000000001").expect("app id");
    let release_c = CString::new("1.0.0+1").expect("release");
    let channel_c = CString::new("stable").expect("channel");
    let platform_c = CString::new("android").expect("platform");
    let arch_c = CString::new("arm64-v8a").expect("arch");
    let public_key_c = CString::new(public_key).expect("public key");
    let server_url_c = CString::new(server_url).expect("server url");
    let params = FcbInitParams {
        app_id: app_id_c.as_ptr(),
        channel: channel_c.as_ptr(),
        release_version: release_c.as_ptr(),
        platform: platform_c.as_ptr(),
        arch: arch_c.as_ptr(),
        cache_dir: cache_dir_c.as_ptr(),
        public_key_pem: public_key_c.as_ptr(),
        check_on_startup: 0,
    };
    assert_eq!(unsafe { fcb_init(&params) }, 0);
    assert_eq!(unsafe { fcb_set_server_url(server_url_c.as_ptr()) }, 0);
    assert_eq!(fcb_check_for_update_blocking(), 1);
    assert_eq!(fcb_last_check_patch_number(), 9);
    fcb_reset_interpreter_stats();
    fcb_record_interpreter_call();
    fcb_record_aot_call();
    fcb_record_aot_call();
    assert_eq!(fcb_download_and_install_blocking(), 1);
    assert_eq!(fcb_is_new_patch_ready_to_install(), 1);
    assert_eq!(
        std::fs::read(cache_dir.join("patches/9/payload.bin")).expect("payload"),
        payload
    );
    let request = event_rx.recv().expect("install event post");
    assert!(request.starts_with("POST /v1/events "), "{request}");
    let body = request.split("\r\n\r\n").nth(1).expect("request body");
    let event: serde_json::Value = serde_json::from_str(body).expect("event json");
    assert_eq!(event["event_type"], "install");
    assert_eq!(event["patch_number"], 9);
    assert_eq!(event["payload"]["interpreted_function_calls"], 1);
    assert_eq!(event["payload"]["aot_function_calls"], 2);
    assert_eq!(event["payload"]["interpreter_ratio"], 1.0 / 3.0);

    server.join().expect("server join");
    let _ = std::fs::remove_dir_all(cache_dir);
}

#[test]
fn download_install_resumes_existing_partial_payload() {
    let _guard = test_lock();
    let cache_dir = std::env::temp_dir().join(format!(
        "fcb-updater-resume-test-{}",
        std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .expect("time")
            .as_nanos()
    ));
    let payload = br#"{"version":1,"functions":[{"name":"initialCounterValue","param_count":0,"local_count":0,"constants":[{"type":"Int","value":7}],"code":[1,0,0,255]}]}"#;
    let prefix_len = 24;
    let prefix = &payload[..prefix_len];
    let suffix = &payload[prefix_len..];
    let mut stale_partial = prefix.to_vec();
    stale_partial.extend_from_slice(b"stale-bytes");
    let out = cache_dir
        .join("downloads")
        .join("1.0.0+1")
        .join("10")
        .join("android")
        .join("arm64-v8a");
    std::fs::create_dir_all(&out).expect("create download dir");
    std::fs::write(out.join("payload.bin.part"), stale_partial).expect("write partial");
    std::fs::write(out.join(".progress"), prefix_len.to_string()).expect("write progress");

    let (private_key, public_key) = crypto::generate_keypair_b64();
    let mut patch = PatchManifest {
        schema_version: 1,
        app_id: "00000000-0000-0000-0000-000000000002".to_string(),
        release_version: "1.0.0+1".to_string(),
        patch_number: 10,
        channel: "stable".to_string(),
        created_at: "1970-01-01T00:00:00Z".to_string(),
        backend: "bytecode".to_string(),
        platform: "android".to_string(),
        arch: "arm64-v8a".to_string(),
        payload: PayloadManifest {
            kind: "bytecode_module".to_string(),
            compression: "none".to_string(),
            hash: crypto::sha256_hex(payload),
            size: payload.len() as u64,
            download_url: "/payload".to_string(),
            diff_algorithm: None,
            base_hash: None,
            output_hash: None,
        },
        policy: PatchPolicy {
            rollout_percentage: 100,
            allow_downgrade: false,
        },
        signature: PatchSignature {
            algorithm: "ed25519".to_string(),
            key_id: "dev".to_string(),
            value: String::new(),
        },
    };
    manifest::sign_patch_manifest(&mut patch, &private_key).expect("sign manifest");
    let manifest_bytes = serde_json::to_vec(&patch).expect("manifest json");
    let manifest_hash = crypto::sha256_hex(&manifest_bytes);
    let payload_hash = crypto::sha256_hex(payload);

    let listener = TcpListener::bind("127.0.0.1:0").expect("bind server");
    let server_url = format!("http://{}", listener.local_addr().expect("local addr"));
    let server_url_for_thread = server_url.clone();
    let server = std::thread::spawn(move || {
        for _ in 0..3 {
            let (mut stream, _) = listener.accept().expect("accept");
            let mut request = [0_u8; 2048];
            let n = stream.read(&mut request).expect("read request");
            let request = String::from_utf8_lossy(&request[..n]);
            let path = request
                .lines()
                .next()
                .and_then(|line| line.split_whitespace().nth(1))
                .unwrap_or("/");
            if path.starts_with("/v1/patches/check") {
                let body = serde_json::json!({
                    "patch_available": true,
                    "patch": {
                        "patch_number": 10,
                        "manifest_url": format!("{server_url_for_thread}/manifest"),
                        "payload_url": format!("{server_url_for_thread}/payload"),
                        "manifest_hash": manifest_hash,
                        "payload_hash": payload_hash,
                    }
                })
                .to_string();
                write_response(&mut stream, "application/json", body.as_bytes());
            } else if path == "/manifest" {
                write_response(&mut stream, "application/json", &manifest_bytes);
            } else if path == "/payload" {
                assert!(
                    request
                        .to_ascii_lowercase()
                        .contains(&format!("range: bytes={prefix_len}-")),
                    "{request}"
                );
                write_partial_response(&mut stream, suffix);
            } else {
                write_response(&mut stream, "text/plain", b"not found");
            }
        }
    });

    let cache_dir_c = CString::new(cache_dir.to_string_lossy().as_bytes()).expect("cache dir");
    let app_id_c = CString::new("00000000-0000-0000-0000-000000000002").expect("app id");
    let release_c = CString::new("1.0.0+1").expect("release");
    let channel_c = CString::new("stable").expect("channel");
    let platform_c = CString::new("android").expect("platform");
    let arch_c = CString::new("arm64-v8a").expect("arch");
    let public_key_c = CString::new(public_key).expect("public key");
    let server_url_c = CString::new(server_url).expect("server url");
    let params = FcbInitParams {
        app_id: app_id_c.as_ptr(),
        channel: channel_c.as_ptr(),
        release_version: release_c.as_ptr(),
        platform: platform_c.as_ptr(),
        arch: arch_c.as_ptr(),
        cache_dir: cache_dir_c.as_ptr(),
        public_key_pem: public_key_c.as_ptr(),
        check_on_startup: 0,
    };
    assert_eq!(unsafe { fcb_init(&params) }, 0);
    assert_eq!(unsafe { fcb_set_server_url(server_url_c.as_ptr()) }, 0);
    assert_eq!(fcb_check_for_update_blocking(), 1);
    assert_eq!(fcb_download_and_install_blocking(), 1);
    assert_eq!(
        std::fs::read(cache_dir.join("patches/10/payload.bin")).expect("payload"),
        payload
    );
    assert!(!out.join("payload.bin.part").exists());
    assert!(!out.join(".progress").exists());

    server.join().expect("server join");
    let _ = std::fs::remove_dir_all(cache_dir);
}

#[test]
fn download_install_recovers_after_interrupted_payload_response() {
    let _guard = test_lock();
    let cache_dir = std::env::temp_dir().join(format!(
        "fcb-updater-interrupted-resume-test-{}",
        std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .expect("time")
            .as_nanos()
    ));
    let payload = br#"{"version":1,"functions":[{"name":"initialCounterValue","param_count":0,"local_count":0,"constants":[{"type":"Int","value":13}],"code":[1,0,0,255]}]}"#;
    let split_at = 31;
    let first_chunk = &payload[..split_at];
    let second_chunk = &payload[split_at..];
    let (private_key, public_key) = crypto::generate_keypair_b64();
    let mut patch = PatchManifest {
        schema_version: 1,
        app_id: "00000000-0000-0000-0000-000000000004".to_string(),
        release_version: "1.0.0+1".to_string(),
        patch_number: 12,
        channel: "stable".to_string(),
        created_at: "1970-01-01T00:00:00Z".to_string(),
        backend: "bytecode".to_string(),
        platform: "android".to_string(),
        arch: "arm64-v8a".to_string(),
        payload: PayloadManifest {
            kind: "bytecode_module".to_string(),
            compression: "none".to_string(),
            hash: crypto::sha256_hex(payload),
            size: payload.len() as u64,
            download_url: "/payload".to_string(),
            diff_algorithm: None,
            base_hash: None,
            output_hash: None,
        },
        policy: PatchPolicy {
            rollout_percentage: 100,
            allow_downgrade: false,
        },
        signature: PatchSignature {
            algorithm: "ed25519".to_string(),
            key_id: "dev".to_string(),
            value: String::new(),
        },
    };
    manifest::sign_patch_manifest(&mut patch, &private_key).expect("sign manifest");
    let manifest_bytes = serde_json::to_vec(&patch).expect("manifest json");
    let manifest_hash = crypto::sha256_hex(&manifest_bytes);
    let payload_hash = crypto::sha256_hex(payload);
    let download_dir = cache_dir
        .join("downloads")
        .join("1.0.0+1")
        .join("12")
        .join("android")
        .join("arm64-v8a");

    let listener = TcpListener::bind("127.0.0.1:0").expect("bind server");
    let server_url = format!("http://{}", listener.local_addr().expect("local addr"));
    let server_url_for_thread = server_url.clone();
    let (range_tx, range_rx) = mpsc::channel();
    let (event_tx, event_rx) = mpsc::channel();
    let server = std::thread::spawn(move || {
        let mut payload_requests = 0;
        for _ in 0..6 {
            let (mut stream, _) = listener.accept().expect("accept");
            let mut request = Vec::new();
            let mut buffer = [0_u8; 2048];
            loop {
                let n = stream.read(&mut buffer).expect("read request");
                if n == 0 {
                    break;
                }
                request.extend_from_slice(&buffer[..n]);
                if has_complete_http_request(&request) {
                    break;
                }
            }
            let request = String::from_utf8_lossy(&request).to_string();
            let path = request
                .lines()
                .next()
                .and_then(|line| line.split_whitespace().nth(1))
                .unwrap_or("/");
            if path.starts_with("/v1/patches/check") {
                let body = serde_json::json!({
                    "patch_available": true,
                    "patch": {
                        "patch_number": 12,
                        "manifest_url": format!("{server_url_for_thread}/manifest"),
                        "payload_url": format!("{server_url_for_thread}/payload"),
                        "manifest_hash": manifest_hash,
                        "payload_hash": payload_hash,
                    }
                })
                .to_string();
                write_response(&mut stream, "application/json", body.as_bytes());
            } else if path == "/manifest" {
                write_response(&mut stream, "application/json", &manifest_bytes);
            } else if path == "/payload" {
                payload_requests += 1;
                if payload_requests == 1 {
                    write_response(&mut stream, "application/octet-stream", first_chunk);
                } else {
                    range_tx.send(request).expect("send range request");
                    write_partial_response(&mut stream, second_chunk);
                }
            } else if path == "/v1/events" {
                event_tx.send(request).expect("send install event");
                write_status_response(&mut stream, 200, b"{}");
            } else {
                write_status_response(&mut stream, 404, b"not found");
            }
        }
    });

    let cache_dir_c = CString::new(cache_dir.to_string_lossy().as_bytes()).expect("cache dir");
    let app_id_c = CString::new("00000000-0000-0000-0000-000000000004").expect("app id");
    let release_c = CString::new("1.0.0+1").expect("release");
    let channel_c = CString::new("stable").expect("channel");
    let platform_c = CString::new("android").expect("platform");
    let arch_c = CString::new("arm64-v8a").expect("arch");
    let public_key_c = CString::new(public_key).expect("public key");
    let server_url_c = CString::new(server_url).expect("server url");
    let params = FcbInitParams {
        app_id: app_id_c.as_ptr(),
        channel: channel_c.as_ptr(),
        release_version: release_c.as_ptr(),
        platform: platform_c.as_ptr(),
        arch: arch_c.as_ptr(),
        cache_dir: cache_dir_c.as_ptr(),
        public_key_pem: public_key_c.as_ptr(),
        check_on_startup: 0,
    };
    assert_eq!(unsafe { fcb_init(&params) }, 0);
    assert_eq!(unsafe { fcb_set_server_url(server_url_c.as_ptr()) }, 0);
    assert_eq!(fcb_check_for_update_blocking(), 1);

    assert_eq!(fcb_download_and_install_blocking(), -1);
    let last_error = unsafe { CStr::from_ptr(super::fcb_last_error()) }.to_string_lossy();
    assert!(
        last_error.contains("payload sha256 mismatch"),
        "{last_error}"
    );
    assert_eq!(
        std::fs::read(download_dir.join("payload.bin.part")).expect("partial payload"),
        first_chunk
    );
    assert_eq!(
        std::fs::read_to_string(download_dir.join(".progress")).expect("progress"),
        split_at.to_string()
    );

    assert_eq!(fcb_download_and_install_blocking(), 1);
    let range_request = range_rx.recv().expect("range request");
    assert!(
        range_request
            .to_ascii_lowercase()
            .contains(&format!("range: bytes={split_at}-")),
        "{range_request}"
    );
    assert_eq!(
        std::fs::read(cache_dir.join("patches/12/payload.bin")).expect("payload"),
        payload
    );
    assert!(!download_dir.join("payload.bin.part").exists());
    assert!(!download_dir.join(".progress").exists());
    let install_event = event_rx.recv().expect("install event");
    assert!(
        install_event.contains(r#""event_type":"install""#)
            || install_event.contains(r#""event_type": "install""#),
        "{install_event}"
    );

    server.join().expect("server join");
    let _ = std::fs::remove_dir_all(cache_dir);
}

unsafe extern "C" fn capture_event(json: *const std::os::raw::c_char) {
    let json = unsafe { CStr::from_ptr(json) }
        .to_string_lossy()
        .to_string();
    DRAINED_EVENTS
        .get_or_init(|| Mutex::new(Vec::new()))
        .lock()
        .expect("events lock")
        .push(json);
}

fn spawn_single_event_server(status: u16) -> (String, mpsc::Receiver<String>) {
    let listener = TcpListener::bind("127.0.0.1:0").expect("bind event server");
    let server_url = format!("http://{}", listener.local_addr().expect("local addr"));
    let (tx, rx) = mpsc::channel();
    std::thread::spawn(move || {
        let (mut stream, _) = listener.accept().expect("accept event");
        let mut request = Vec::new();
        let mut buf = [0_u8; 1024];
        loop {
            let n = stream.read(&mut buf).expect("read event request");
            if n == 0 {
                break;
            }
            request.extend_from_slice(&buf[..n]);
            if has_complete_http_request(&request) {
                break;
            }
        }
        tx.send(String::from_utf8_lossy(&request).to_string())
            .expect("send event request");
        write_status_response(&mut stream, status, b"{}");
    });
    (server_url, rx)
}

fn read_http_request(stream: &mut TcpStream) -> String {
    let mut request = Vec::new();
    let mut buffer = [0_u8; 4096];
    loop {
        let n = stream.read(&mut buffer).expect("read request");
        if n == 0 {
            break;
        }
        request.extend_from_slice(&buffer[..n]);
        if has_complete_http_request(&request) {
            break;
        }
    }
    String::from_utf8_lossy(&request).to_string()
}

fn empty_launch_patch() -> FcbLaunchPatch {
    FcbLaunchPatch {
        has_patch: 0,
        patch_number: 0,
        backend: std::ptr::null(),
        artifact_path: std::ptr::null(),
        bytecode_path: std::ptr::null(),
        manifest_path: std::ptr::null(),
    }
}

fn has_complete_http_request(request: &[u8]) -> bool {
    let Some(header_end) = request.windows(4).position(|window| window == b"\r\n\r\n") else {
        return false;
    };
    let headers = String::from_utf8_lossy(&request[..header_end]);
    let content_length = headers
        .lines()
        .find_map(|line| {
            let (name, value) = line.split_once(':')?;
            name.eq_ignore_ascii_case("content-length")
                .then(|| value.trim().parse::<usize>().ok())
                .flatten()
        })
        .unwrap_or(0);
    request.len() >= header_end + 4 + content_length
}

fn write_status_response(stream: &mut std::net::TcpStream, status: u16, body: &[u8]) {
    let reason = match status {
        200 => "OK",
        503 => "Service Unavailable",
        _ => "Status",
    };
    write!(
            stream,
            "HTTP/1.1 {status} {reason}\r\nContent-Type: application/json\r\nContent-Length: {}\r\nConnection: close\r\n\r\n",
            body.len()
        )
        .expect("write headers");
    stream.write_all(body).expect("write body");
}

fn write_response(stream: &mut std::net::TcpStream, content_type: &str, body: &[u8]) {
    write!(
            stream,
            "HTTP/1.1 200 OK\r\nContent-Type: {content_type}\r\nContent-Length: {}\r\nConnection: close\r\n\r\n",
            body.len()
        )
        .expect("write headers");
    stream.write_all(body).expect("write body");
}

fn write_partial_response(stream: &mut std::net::TcpStream, body: &[u8]) {
    write!(
            stream,
            "HTTP/1.1 206 Partial Content\r\nContent-Type: application/octet-stream\r\nContent-Length: {}\r\nConnection: close\r\n\r\n",
            body.len()
        )
        .expect("write headers");
    stream.write_all(body).expect("write body");
}
