use super::{InstalledPatch, LastLaunch, State, Updater};
use crate::bytecode::{BytecodeFunction, BytecodeModule, Constant, OpCode};
use crate::crypto;
use crate::diff::{self, BSDIFF_ZSTD_ALGORITHM};
use crate::manifest::{self, PatchManifest, PatchPolicy, PatchSignature, PayloadManifest};

#[test]
fn mark_success_requires_last_launch() {
    let cache_dir = std::env::temp_dir().join(format!("fcb-state-test-{}", super::unique_suffix()));
    let updater = Updater::new(&cache_dir);

    let err = updater
        .mark_success()
        .expect_err("missing last_launch should fail");

    assert!(err.to_string().contains("no last_launch to mark success"));
    let _ = std::fs::remove_dir_all(cache_dir);
}

#[test]
fn launch_patch_retries_pending_launch_before_threshold() {
    let cache_dir = std::env::temp_dir().join(format!("fcb-state-test-{}", super::unique_suffix()));
    let updater = Updater::new(&cache_dir);
    updater
        .save_state(&State {
            schema_version: 1,
            release_version: "1.0.0+1".to_string(),
            current_patch_number: 0,
            pending_patch_number: Some(1),
            last_known_good_patch_number: None,
            boot_attempts: 0,
            bad_patches: Vec::new(),
            last_launch: Some(LastLaunch {
                patch_number: 1,
                status: "pending_success".to_string(),
                started_at: "0".to_string(),
            }),
            installed: vec![InstalledPatch {
                patch_number: 1,
                backend: "snapshot_replace".to_string(),
                manifest_path: "patches/1/manifest.json".to_string(),
                payload_path: "patches/1/payload.bin".to_string(),
                artifact_path: Some("patches/1/libapp.so".to_string()),
                installed_at: "0".to_string(),
            }],
        })
        .expect("write state");

    let launch = updater.launch_patch().expect("launch patch");
    let state = updater.load_state().expect("load state");

    assert_eq!(launch.expect("retry launch").patch_number, 1);
    assert!(state.bad_patches.is_empty());
    assert_eq!(state.pending_patch_number, Some(1));
    assert_eq!(state.boot_attempts, 1);
    assert_eq!(
        state.last_launch.as_ref().map(|launch| launch.patch_number),
        Some(1)
    );
    let _ = std::fs::remove_dir_all(cache_dir);
}

#[test]
fn launch_patch_marks_third_pending_launch_bad() {
    let cache_dir = std::env::temp_dir().join(format!("fcb-state-test-{}", super::unique_suffix()));
    let updater = Updater::new(&cache_dir);
    updater
        .save_state(&State {
            schema_version: 2,
            release_version: "1.0.0+1".to_string(),
            current_patch_number: 0,
            pending_patch_number: Some(1),
            last_known_good_patch_number: None,
            boot_attempts: 2,
            bad_patches: Vec::new(),
            last_launch: Some(LastLaunch {
                patch_number: 1,
                status: "pending_success".to_string(),
                started_at: "0".to_string(),
            }),
            installed: vec![InstalledPatch {
                patch_number: 1,
                backend: "snapshot_replace".to_string(),
                manifest_path: "patches/1/manifest.json".to_string(),
                payload_path: "patches/1/payload.bin".to_string(),
                artifact_path: Some("patches/1/libapp.so".to_string()),
                installed_at: "0".to_string(),
            }],
        })
        .expect("write state");

    let launch = updater.launch_patch().expect("launch patch");
    let state = updater.load_state().expect("load state");

    assert!(launch.is_none());
    assert_eq!(state.bad_patches, vec![1]);
    assert_eq!(state.pending_patch_number, None);
    assert_eq!(state.boot_attempts, 0);
    assert!(state.last_launch.is_none());
    let _ = std::fs::remove_dir_all(cache_dir);
}

#[test]
fn launch_patch_falls_back_to_lkg_after_pending_reaches_threshold() {
    let cache_dir = std::env::temp_dir().join(format!("fcb-state-test-{}", super::unique_suffix()));
    let updater = Updater::new(&cache_dir);
    updater
        .save_state(&State {
            schema_version: 2,
            release_version: "1.0.0+1".to_string(),
            current_patch_number: 1,
            pending_patch_number: Some(2),
            last_known_good_patch_number: Some(1),
            boot_attempts: 2,
            bad_patches: Vec::new(),
            last_launch: Some(LastLaunch {
                patch_number: 2,
                status: "pending_success".to_string(),
                started_at: "0".to_string(),
            }),
            installed: vec![
                InstalledPatch {
                    patch_number: 1,
                    backend: "bytecode".to_string(),
                    manifest_path: "patches/1/manifest.json".to_string(),
                    payload_path: "patches/1/payload.bin".to_string(),
                    artifact_path: None,
                    installed_at: "0".to_string(),
                },
                InstalledPatch {
                    patch_number: 2,
                    backend: "bytecode".to_string(),
                    manifest_path: "patches/2/manifest.json".to_string(),
                    payload_path: "patches/2/payload.bin".to_string(),
                    artifact_path: None,
                    installed_at: "0".to_string(),
                },
            ],
        })
        .expect("write state");

    let launch = updater
        .launch_patch()
        .expect("launch patch")
        .expect("lkg fallback");
    let state = updater.load_state().expect("load state");

    assert_eq!(launch.patch_number, 1);
    assert_eq!(state.bad_patches, vec![2]);
    assert_eq!(state.current_patch_number, 1);
    assert_eq!(state.pending_patch_number, None);
    assert_eq!(state.last_known_good_patch_number, Some(1));
    assert_eq!(state.boot_attempts, 1);
    assert_eq!(
        state.last_launch.as_ref().map(|launch| launch.patch_number),
        Some(1)
    );
    let events = updater.rollback_events().expect("rollback events");
    assert_eq!(events.len(), 1);
    assert_eq!(events[0].event_type, "crash_rollback");
    assert_eq!(events[0].patch_number, 2);
    assert_eq!(events[0].boot_attempts, 3);
    assert_eq!(events[0].last_known_good_patch_number, Some(1));
    let _ = std::fs::remove_dir_all(cache_dir);
}

#[test]
fn rollback_event_log_keeps_latest_50_entries() {
    let cache_dir = std::env::temp_dir().join(format!("fcb-state-test-{}", super::unique_suffix()));
    let updater = Updater::new(&cache_dir);
    for patch_number in 1..=55 {
        super::append_rollback_event(
            &cache_dir,
            super::CrashRollbackEvent {
                event_type: "crash_rollback".to_string(),
                patch_number,
                boot_attempts: 3,
                last_known_good_patch_number: None,
                timestamp: patch_number.to_string(),
                reason: None,
            },
        )
        .expect("append rollback event");
    }

    let events = updater.rollback_events().expect("events");

    assert_eq!(events.len(), 50);
    assert_eq!(events[0].patch_number, 6);
    assert_eq!(events[49].patch_number, 55);
    let _ = std::fs::remove_dir_all(cache_dir);
}

#[test]
fn mark_success_updates_lkg_and_resets_boot_attempts() {
    let cache_dir = std::env::temp_dir().join(format!("fcb-state-test-{}", super::unique_suffix()));
    let updater = Updater::new(&cache_dir);
    updater
        .save_state(&State {
            schema_version: 2,
            release_version: "1.0.0+1".to_string(),
            current_patch_number: 1,
            pending_patch_number: Some(2),
            last_known_good_patch_number: Some(1),
            boot_attempts: 2,
            bad_patches: Vec::new(),
            last_launch: Some(LastLaunch {
                patch_number: 2,
                status: "pending_success".to_string(),
                started_at: "0".to_string(),
            }),
            installed: Vec::new(),
        })
        .expect("write state");

    updater.mark_success().expect("mark success");
    let state = updater.load_state().expect("load state");

    assert_eq!(state.current_patch_number, 2);
    assert_eq!(state.pending_patch_number, None);
    assert_eq!(state.last_known_good_patch_number, Some(2));
    assert_eq!(state.boot_attempts, 0);
    assert_eq!(
        state
            .last_launch
            .as_ref()
            .map(|launch| launch.status.as_str()),
        Some("success")
    );
    let _ = std::fs::remove_dir_all(cache_dir);
}

#[test]
fn mark_success_rejects_bad_patch() {
    let cache_dir = std::env::temp_dir().join(format!("fcb-state-test-{}", super::unique_suffix()));
    let updater = Updater::new(&cache_dir);
    updater
        .save_state(&State {
            schema_version: 2,
            release_version: "1.0.0+1".to_string(),
            current_patch_number: 0,
            pending_patch_number: None,
            last_known_good_patch_number: None,
            boot_attempts: 0,
            bad_patches: vec![2],
            last_launch: Some(LastLaunch {
                patch_number: 2,
                status: "failure:interpret_failure:fn:Return stack underflow".to_string(),
                started_at: "0".to_string(),
            }),
            installed: Vec::new(),
        })
        .expect("write state");

    let error = updater
        .mark_success()
        .expect_err("bad patch success rejected");
    assert!(error.to_string().contains("bad patch"), "{}", error);
    let state = updater.load_state().expect("load state");
    assert_eq!(state.current_patch_number, 0);
    assert_eq!(state.pending_patch_number, None);
    assert_eq!(state.last_known_good_patch_number, None);
    assert_eq!(state.bad_patches, vec![2]);
    let _ = std::fs::remove_dir_all(cache_dir);
}

#[test]
fn load_state_migrates_v1_current_patch_to_lkg() {
    let cache_dir = std::env::temp_dir().join(format!("fcb-state-test-{}", super::unique_suffix()));
    let updater = Updater::new(&cache_dir);
    std::fs::create_dir_all(&cache_dir).expect("create cache dir");
    std::fs::write(
        updater.state_path(),
        r#"{
  "schema_version": 1,
  "release_version": "1.0.0+1",
  "current_patch_number": 7,
  "pending_patch_number": null,
  "bad_patches": [],
  "last_launch": null,
  "installed": []
}"#,
    )
    .expect("write v1 state");

    let state = updater.load_state().expect("load migrated state");

    assert_eq!(state.schema_version, 2);
    assert_eq!(state.last_known_good_patch_number, Some(7));
    assert_eq!(state.boot_attempts, 0);
    let _ = std::fs::remove_dir_all(cache_dir);
}

#[test]
fn load_state_backs_up_corrupt_json_and_resets() {
    let cache_dir = std::env::temp_dir().join(format!("fcb-state-test-{}", super::unique_suffix()));
    let updater = Updater::new(&cache_dir);
    std::fs::create_dir_all(&cache_dir).expect("create cache dir");
    std::fs::write(updater.state_path(), b"{not json").expect("write corrupt state");

    let state = updater.load_state().expect("load reset state");

    assert_eq!(state.schema_version, 2);
    assert_eq!(state.current_patch_number, 0);
    assert!(!updater.state_path().exists());
    assert!(std::fs::read_dir(&cache_dir)
        .expect("read cache dir")
        .filter_map(|entry| entry.ok())
        .any(|entry| entry
            .file_name()
            .to_string_lossy()
            .starts_with("state.json.corrupt.")));
    let events = updater.rollback_events().expect("events");
    assert_eq!(events.len(), 1);
    assert_eq!(events[0].event_type, "state_reset");
    assert!(events[0]
        .reason
        .as_deref()
        .unwrap_or_default()
        .contains("failed to parse state.json"));
    let _ = std::fs::remove_dir_all(cache_dir);
}

#[test]
fn ready_patch_reports_pending_without_marking_launch() {
    let cache_dir = std::env::temp_dir().join(format!("fcb-state-test-{}", super::unique_suffix()));
    let updater = Updater::new(&cache_dir);
    updater
        .save_state(&State {
            schema_version: 1,
            release_version: "1.0.0+1".to_string(),
            current_patch_number: 0,
            pending_patch_number: Some(1),
            last_known_good_patch_number: None,
            boot_attempts: 0,
            bad_patches: Vec::new(),
            last_launch: None,
            installed: vec![InstalledPatch {
                patch_number: 1,
                backend: "snapshot_replace".to_string(),
                manifest_path: "patches/1/manifest.json".to_string(),
                payload_path: "patches/1/payload.bin".to_string(),
                artifact_path: Some("patches/1/libapp.so".to_string()),
                installed_at: "0".to_string(),
            }],
        })
        .expect("write state");

    let ready = updater.ready_patch().expect("ready patch");
    let state = updater.load_state().expect("load state");

    assert_eq!(ready.expect("ready").patch_number, 1);
    assert!(state.last_launch.is_none());
    assert_eq!(state.pending_patch_number, Some(1));
    let _ = std::fs::remove_dir_all(cache_dir);
}

#[test]
fn install_snapshot_replace_payload_writes_launch_artifact() {
    let cache_dir = std::env::temp_dir().join(format!("fcb-state-test-{}", super::unique_suffix()));
    let input_dir =
        std::env::temp_dir().join(format!("fcb-state-input-{}", super::unique_suffix()));
    std::fs::create_dir_all(&input_dir).expect("create input dir");
    let baseline = b"counter: 1; shared suffix";
    let patched = b"counter: 2; shared suffix";
    let baseline_path = input_dir.join("baseline.bin");
    std::fs::write(&baseline_path, baseline).expect("write baseline");
    let payload = diff::create_bsdiff_zstd(baseline, patched).expect("create diff");
    let payload_path = input_dir.join("payload.bin");
    std::fs::write(&payload_path, &payload).expect("write payload");

    let (private_key, public_key) = crypto::generate_keypair_b64();
    let mut patch = PatchManifest {
        schema_version: 1,
        app_id: "00000000-0000-0000-0000-000000000001".to_string(),
        release_version: "1.0.0+1".to_string(),
        patch_number: 2,
        channel: "stable".to_string(),
        created_at: "1970-01-01T00:00:00Z".to_string(),
        backend: "snapshot_replace".to_string(),
        platform: "android".to_string(),
        arch: "arm64-v8a".to_string(),
        payload: PayloadManifest {
            kind: "binary_diff".to_string(),
            compression: "none".to_string(),
            hash: crypto::sha256_hex(&payload),
            size: payload.len() as u64,
            download_url: "patches/app/release/android/arm64-v8a/2/payload.bin".to_string(),
            diff_algorithm: Some(BSDIFF_ZSTD_ALGORITHM.to_string()),
            base_hash: Some(crypto::sha256_hex(baseline)),
            output_hash: Some(crypto::sha256_hex(patched)),
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
    let manifest_path = input_dir.join("patch_manifest.json");
    manifest::write_json(&manifest_path, &patch).expect("write manifest");

    let updater = Updater::new(&cache_dir);
    updater
        .install_payload_with_baseline(
            &manifest_path,
            &payload_path,
            &public_key,
            Some(&baseline_path),
        )
        .expect("install payload");

    let artifact_path = cache_dir.join("patches/2/libapp.so");
    assert_eq!(
        std::fs::read(&artifact_path).expect("read artifact"),
        patched
    );
    let launch = updater
        .launch_patch()
        .expect("launch patch")
        .expect("installed patch");
    assert_eq!(launch.artifact_path.as_deref(), Some("patches/2/libapp.so"));

    let _ = std::fs::remove_dir_all(cache_dir);
    let _ = std::fs::remove_dir_all(input_dir);
}

#[test]
fn install_snapshot_replace_chained_uses_previous_patch_artifact() {
    let cache_dir = std::env::temp_dir().join(format!("fcb-state-test-{}", super::unique_suffix()));
    let input_dir =
        std::env::temp_dir().join(format!("fcb-state-input-{}", super::unique_suffix()));
    std::fs::create_dir_all(&input_dir).expect("create input dir");

    let baseline = b"v0";
    let v1 = b"v0v1";
    let v2 = b"v0v1v2";
    let baseline_path = input_dir.join("baseline.bin");
    std::fs::write(&baseline_path, baseline).expect("write baseline");

    let (private_key, public_key) = crypto::generate_keypair_b64();

    // Install patch 1: diff from baseline -> v1
    let diff1 = diff::create_bsdiff_zstd(baseline, v1).expect("diff1");
    let mut patch1 = make_snapshot_patch(
        &private_key,
        1,
        crypto::sha256_hex(baseline),
        crypto::sha256_hex(v1),
        &diff1,
    );
    manifest::sign_patch_manifest(&mut patch1, &private_key).expect("sign1");
    let manifest1_path = input_dir.join("m1.json");
    let payload1_path = input_dir.join("p1.bin");
    manifest::write_json(&manifest1_path, &patch1).expect("write manifest1");
    std::fs::write(&payload1_path, &diff1).expect("write payload1");

    let updater = Updater::new(&cache_dir);
    updater
        .install_payload_with_baseline(
            &manifest1_path,
            &payload1_path,
            &public_key,
            Some(&baseline_path),
        )
        .expect("install patch 1");

    assert_eq!(
        std::fs::read(cache_dir.join("patches/1/libapp.so")).expect("v1 artifact"),
        v1
    );

    // Install patch 2: diff from v1 -> v2 (no baseline_path needed; uses patch 1 artifact)
    let diff2 = diff::create_bsdiff_zstd(v1, v2).expect("diff2");
    let mut patch2 = make_snapshot_patch(
        &private_key,
        2,
        crypto::sha256_hex(v1),
        crypto::sha256_hex(v2),
        &diff2,
    );
    manifest::sign_patch_manifest(&mut patch2, &private_key).expect("sign2");
    let manifest2_path = input_dir.join("m2.json");
    let payload2_path = input_dir.join("p2.bin");
    manifest::write_json(&manifest2_path, &patch2).expect("write manifest2");
    std::fs::write(&payload2_path, &diff2).expect("write payload2");

    updater
        .install_payload_with_baseline(&manifest2_path, &payload2_path, &public_key, None)
        .expect("install patch 2");

    assert_eq!(
        std::fs::read(cache_dir.join("patches/2/libapp.so")).expect("v2 artifact"),
        v2
    );
    let state = updater.load_state().expect("load state");
    assert_eq!(state.pending_patch_number, Some(2));

    let _ = std::fs::remove_dir_all(cache_dir);
    let _ = std::fs::remove_dir_all(input_dir);
}

fn make_snapshot_patch(
    _private_key: &str,
    patch_number: u32,
    base_hash: String,
    output_hash: String,
    payload: &[u8],
) -> PatchManifest {
    use crate::diff::BSDIFF_ZSTD_ALGORITHM;
    PatchManifest {
        schema_version: 1,
        app_id: "00000000-0000-0000-0000-000000000001".to_string(),
        release_version: "1.0.0+1".to_string(),
        patch_number,
        channel: "stable".to_string(),
        created_at: "1970-01-01T00:00:00Z".to_string(),
        backend: "snapshot_replace".to_string(),
        platform: "android".to_string(),
        arch: "arm64-v8a".to_string(),
        payload: PayloadManifest {
            kind: "binary_diff".to_string(),
            compression: "none".to_string(),
            hash: crypto::sha256_hex(payload),
            size: payload.len() as u64,
            download_url: format!(
                "patches/app/release/android/arm64-v8a/{patch_number}/payload.bin"
            ),
            diff_algorithm: Some(BSDIFF_ZSTD_ALGORITHM.to_string()),
            base_hash: Some(base_hash),
            output_hash: Some(output_hash),
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
    }
}

#[test]
fn install_snapshot_replace_rejects_non_binary_diff_payload() {
    let cache_dir = std::env::temp_dir().join(format!("fcb-state-test-{}", super::unique_suffix()));
    let input_dir =
        std::env::temp_dir().join(format!("fcb-state-input-{}", super::unique_suffix()));
    std::fs::create_dir_all(&input_dir).expect("create input dir");
    let payload = b"raw artifact";
    let payload_path = input_dir.join("payload.bin");
    std::fs::write(&payload_path, payload).expect("write payload");

    let (private_key, public_key) = crypto::generate_keypair_b64();
    let mut patch = PatchManifest {
        schema_version: 1,
        app_id: "00000000-0000-0000-0000-000000000001".to_string(),
        release_version: "1.0.0+1".to_string(),
        patch_number: 1,
        channel: "stable".to_string(),
        created_at: "1970-01-01T00:00:00Z".to_string(),
        backend: "snapshot_replace".to_string(),
        platform: "android".to_string(),
        arch: "arm64-v8a".to_string(),
        payload: PayloadManifest {
            kind: "opaque_payload".to_string(),
            compression: "none".to_string(),
            hash: crypto::sha256_hex(payload),
            size: payload.len() as u64,
            download_url: "patches/app/1/payload.bin".to_string(),
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
    manifest::sign_patch_manifest(&mut patch, &private_key).expect("sign");
    let manifest_path = input_dir.join("m.json");
    manifest::write_json(&manifest_path, &patch).expect("write manifest");

    let err = Updater::new(&cache_dir)
        .install_payload(&manifest_path, &payload_path, &public_key)
        .expect_err("opaque_payload should be rejected");

    assert!(
        err.to_string().contains("requires binary_diff payload"),
        "{err}"
    );

    let _ = std::fs::remove_dir_all(cache_dir);
    let _ = std::fs::remove_dir_all(input_dir);
}

#[test]
fn install_bytecode_payload_launches_payload_without_artifact() {
    let cache_dir = std::env::temp_dir().join(format!("fcb-state-test-{}", super::unique_suffix()));
    let input_dir =
        std::env::temp_dir().join(format!("fcb-state-input-{}", super::unique_suffix()));
    std::fs::create_dir_all(&input_dir).expect("create input dir");
    let payload = br#"{"version":1,"functions":[{"name":"initialCounterValue","param_count":0,"local_count":0,"constants":[{"type":"Int","value":2}],"code":[1,0,0,255]}]}"#;
    let payload_path = input_dir.join("payload.bin");
    std::fs::write(&payload_path, payload).expect("write payload");

    let (private_key, public_key) = crypto::generate_keypair_b64();
    let mut patch = PatchManifest {
        schema_version: 1,
        app_id: "00000000-0000-0000-0000-000000000001".to_string(),
        release_version: "1.0.0+1".to_string(),
        patch_number: 4,
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
            download_url: "patches/app/release/android/arm64-v8a/4/payload.bin".to_string(),
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
    let manifest_path = input_dir.join("patch_manifest.json");
    manifest::write_json(&manifest_path, &patch).expect("write manifest");

    let updater = Updater::new(&cache_dir);
    updater
        .install_payload(&manifest_path, &payload_path, &public_key)
        .expect("install payload");

    let state = updater.load_state().expect("load state");
    let installed = state.installed.first().expect("installed patch");
    assert_eq!(installed.backend, "bytecode");
    assert_eq!(installed.payload_path, "patches/4/payload.bin");
    assert!(installed.artifact_path.is_none());
    assert_eq!(
        std::fs::read(cache_dir.join(&installed.payload_path)).expect("read payload"),
        payload
    );

    let launch = updater
        .launch_patch()
        .expect("launch patch")
        .expect("installed patch");
    assert_eq!(launch.payload_path, "patches/4/payload.bin");
    assert!(launch.artifact_path.is_none());

    let _ = std::fs::remove_dir_all(cache_dir);
    let _ = std::fs::remove_dir_all(input_dir);
}

#[test]
fn install_binary_bytecode_payload_accepts_modern_opcodes() {
    let payload = BytecodeModule::new(vec![BytecodeFunction {
        name: "package:app/main.dart::initialCounterValue".to_string(),
        return_convention: "tagged".to_string(),
        param_count: 1,
        local_count: 1,
        constants: vec![
            Constant::String("package:app/main.dart::helper".to_string()),
            Constant::String("value".to_string()),
        ],
        code: vec![
            OpCode::LoadArg as u8,
            0,
            OpCode::GetField as u8,
            0,
            1,
            OpCode::CallStatic as u8,
            0,
            0,
            1,
            OpCode::Return as u8,
        ],
        source_map: Vec::new(),
    }])
    .to_binary_vec()
    .expect("encode binary bytecode");

    let (updater, cache_dir, input_dir) =
        install_bytecode_payload_bytes(6, &payload).expect("install binary bytecode");

    let state = updater.load_state().expect("load state");
    let installed = state.installed.first().expect("installed patch");
    assert_eq!(installed.backend, "bytecode");
    assert_eq!(
        std::fs::read(cache_dir.join(&installed.payload_path)).expect("read payload"),
        payload
    );

    let _ = std::fs::remove_dir_all(cache_dir);
    let _ = std::fs::remove_dir_all(input_dir);
}

#[test]
fn install_bytecode_payload_accepts_unknown_opcode_for_vm_fallback() {
    let payload = build_binary_bytecode_payload_with_raw_code(&[0xee, 0xff]);

    let (updater, cache_dir, input_dir) =
        install_bytecode_payload_bytes(7, &payload).expect("install unknown opcode bytecode");

    let state = updater.load_state().expect("load state");
    assert_eq!(state.pending_patch_number, Some(7));
    let installed = state.installed.first().expect("installed patch");
    assert_eq!(
        std::fs::read(cache_dir.join(&installed.payload_path)).expect("read payload"),
        payload
    );

    let _ = std::fs::remove_dir_all(cache_dir);
    let _ = std::fs::remove_dir_all(input_dir);
}

#[test]
fn install_prunes_old_patch_without_removing_current() {
    let cache_dir = std::env::temp_dir().join(format!("fcb-state-test-{}", super::unique_suffix()));
    let input_dir =
        std::env::temp_dir().join(format!("fcb-state-input-{}", super::unique_suffix()));
    std::fs::create_dir_all(&input_dir).expect("create input dir");
    let updater = Updater::new(&cache_dir);
    updater
        .save_state(&State {
            schema_version: 1,
            release_version: "1.0.0+1".to_string(),
            current_patch_number: 1,
            pending_patch_number: None,
            last_known_good_patch_number: Some(1),
            boot_attempts: 0,
            bad_patches: Vec::new(),
            last_launch: None,
            installed: vec![
                InstalledPatch {
                    patch_number: 1,
                    backend: "bytecode".to_string(),
                    manifest_path: "patches/1/manifest.json".to_string(),
                    payload_path: "patches/1/payload.bin".to_string(),
                    artifact_path: None,
                    installed_at: "0".to_string(),
                },
                InstalledPatch {
                    patch_number: 2,
                    backend: "bytecode".to_string(),
                    manifest_path: "patches/2/manifest.json".to_string(),
                    payload_path: "patches/2/payload.bin".to_string(),
                    artifact_path: None,
                    installed_at: "0".to_string(),
                },
            ],
        })
        .expect("write state");

    let payload = br#"{"version":1,"functions":[{"name":"initialCounterValue","param_count":0,"local_count":0,"constants":[{"type":"Int","value":3}],"code":[1,0,0,255]}]}"#;
    let payload_path = input_dir.join("payload.bin");
    std::fs::write(&payload_path, payload).expect("write payload");
    let (private_key, public_key) = crypto::generate_keypair_b64();
    let mut patch = PatchManifest {
        schema_version: 1,
        app_id: "00000000-0000-0000-0000-000000000001".to_string(),
        release_version: "1.0.0+1".to_string(),
        patch_number: 3,
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
            download_url: "patches/app/release/android/arm64-v8a/3/payload.bin".to_string(),
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
    let manifest_path = input_dir.join("patch_manifest.json");
    manifest::write_json(&manifest_path, &patch).expect("write manifest");

    updater
        .install_payload(&manifest_path, &payload_path, &public_key)
        .expect("install payload");
    let state = updater.load_state().expect("load state");
    let installed: Vec<u32> = state
        .installed
        .iter()
        .map(|patch| patch.patch_number)
        .collect();

    assert_eq!(installed, vec![1, 3]);
    assert_eq!(state.current_patch_number, 1);
    assert_eq!(state.pending_patch_number, Some(3));

    let _ = std::fs::remove_dir_all(cache_dir);
    let _ = std::fs::remove_dir_all(input_dir);
}

#[test]
fn install_rejects_invalid_bytecode_payload_before_writing_state() {
    let cache_dir = std::env::temp_dir().join(format!("fcb-state-test-{}", super::unique_suffix()));
    let input_dir =
        std::env::temp_dir().join(format!("fcb-state-input-{}", super::unique_suffix()));
    std::fs::create_dir_all(&input_dir).expect("create input dir");
    let payload =
        br#"{"version":1,"functions":[{"name":"bad","param_count":0,"local_count":0,"constants":[],"code":[]}]}"#;
    let payload_path = input_dir.join("payload.bin");
    std::fs::write(&payload_path, payload).expect("write payload");

    let (private_key, public_key) = crypto::generate_keypair_b64();
    let mut patch = PatchManifest {
        schema_version: 1,
        app_id: "00000000-0000-0000-0000-000000000001".to_string(),
        release_version: "1.0.0+1".to_string(),
        patch_number: 5,
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
            download_url: "patches/app/release/android/arm64-v8a/5/payload.bin".to_string(),
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
    let manifest_path = input_dir.join("patch_manifest.json");
    manifest::write_json(&manifest_path, &patch).expect("write manifest");

    let updater = Updater::new(&cache_dir);
    let err = updater
        .install_payload(&manifest_path, &payload_path, &public_key)
        .expect_err("invalid bytecode should fail");

    assert!(err.to_string().contains("empty bytecode"));
    assert!(!cache_dir.join("patches/5/payload.bin").exists());
    let state = updater.load_state().expect("load state");
    assert!(state.installed.is_empty());
    assert_eq!(state.pending_patch_number, None);

    let _ = std::fs::remove_dir_all(cache_dir);
    let _ = std::fs::remove_dir_all(input_dir);
}

fn install_bytecode_payload_bytes(
    patch_number: u32,
    payload: &[u8],
) -> crate::Result<(Updater, std::path::PathBuf, std::path::PathBuf)> {
    let cache_dir = std::env::temp_dir().join(format!("fcb-state-test-{}", super::unique_suffix()));
    let input_dir =
        std::env::temp_dir().join(format!("fcb-state-input-{}", super::unique_suffix()));
    std::fs::create_dir_all(&input_dir).expect("create input dir");
    let payload_path = input_dir.join("payload.bin");
    std::fs::write(&payload_path, payload).expect("write payload");

    let (private_key, public_key) = crypto::generate_keypair_b64();
    let mut patch = PatchManifest {
        schema_version: 1,
        app_id: "00000000-0000-0000-0000-000000000001".to_string(),
        release_version: "1.0.0+1".to_string(),
        patch_number,
        channel: "stable".to_string(),
        created_at: "1970-01-01T00:00:00Z".to_string(),
        backend: "bytecode".to_string(),
        platform: "ios".to_string(),
        arch: "arm64".to_string(),
        payload: PayloadManifest {
            kind: "bytecode_module".to_string(),
            compression: "none".to_string(),
            hash: crypto::sha256_hex(payload),
            size: payload.len() as u64,
            download_url: format!("patches/app/release/ios/arm64/{patch_number}/payload.bin"),
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
    let manifest_path = input_dir.join("patch_manifest.json");
    manifest::write_json(&manifest_path, &patch).expect("write manifest");

    let updater = Updater::new(&cache_dir);
    updater.install_payload(&manifest_path, &payload_path, &public_key)?;
    Ok((updater, cache_dir, input_dir))
}

fn build_binary_bytecode_payload_with_raw_code(code: &[u8]) -> Vec<u8> {
    let mut out = Vec::new();
    out.extend_from_slice(b"FCBM");
    out.extend_from_slice(&1u32.to_be_bytes());
    out.extend_from_slice(&1u16.to_be_bytes());
    write_binary_string(&mut out, "package:app/main.dart::futureOpcode");
    out.push(0);
    out.push(0);
    out.push(0);
    out.extend_from_slice(&0u16.to_be_bytes());
    out.extend_from_slice(&(code.len() as u32).to_be_bytes());
    out.extend_from_slice(code);
    out.extend_from_slice(&0u16.to_be_bytes());
    out
}

fn write_binary_string(out: &mut Vec<u8>, value: &str) {
    out.extend_from_slice(&(value.len() as u16).to_be_bytes());
    out.extend_from_slice(value.as_bytes());
}
