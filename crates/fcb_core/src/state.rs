use crate::diff::{self, BSDIFF_ZSTD_ALGORITHM, SIMPLE_DIFF_ALGORITHM};
use crate::manifest::{self, PatchManifest};
use crate::{crypto, err, Result};
use serde::{Deserialize, Serialize};
use std::fs::{self, File};
use std::io::Write;
use std::path::{Path, PathBuf};
use std::sync::atomic::{AtomicU64, Ordering};
use std::time::{SystemTime, UNIX_EPOCH};

static TEMP_COUNTER: AtomicU64 = AtomicU64::new(0);

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct State {
    pub schema_version: u32,
    pub release_version: String,
    pub current_patch_number: u32,
    pub pending_patch_number: Option<u32>,
    pub bad_patches: Vec<u32>,
    pub last_launch: Option<LastLaunch>,
    pub installed: Vec<InstalledPatch>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LastLaunch {
    pub patch_number: u32,
    pub status: String,
    pub started_at: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct InstalledPatch {
    pub patch_number: u32,
    pub backend: String,
    pub manifest_path: String,
    pub payload_path: String,
    pub artifact_path: Option<String>,
    pub installed_at: String,
}

pub struct Updater {
    cache_dir: PathBuf,
}

impl Updater {
    pub fn new(cache_dir: impl Into<PathBuf>) -> Self {
        Self {
            cache_dir: cache_dir.into(),
        }
    }

    pub fn state_path(&self) -> PathBuf {
        self.cache_dir.join("state.json")
    }

    pub fn load_state(&self) -> Result<State> {
        let path = self.state_path();
        if !path.exists() {
            return Ok(State {
                schema_version: 1,
                ..State::default()
            });
        }
        Ok(serde_json::from_slice(&fs::read(path)?)?)
    }

    pub fn save_state(&self, state: &State) -> Result<()> {
        atomic_write_json(&self.state_path(), state)
    }

    pub fn install_payload(
        &self,
        manifest_path: &Path,
        payload_path: &Path,
        public_key_b64: &str,
    ) -> Result<()> {
        self.install_payload_with_baseline(manifest_path, payload_path, public_key_b64, None)
    }

    pub fn install_payload_with_baseline(
        &self,
        manifest_path: &Path,
        payload_path: &Path,
        public_key_b64: &str,
        baseline_artifact_path: Option<&Path>,
    ) -> Result<()> {
        let manifest: PatchManifest = manifest::read_json(manifest_path)?;
        manifest::verify_patch_manifest(&manifest, public_key_b64)?;
        let payload = fs::read(payload_path)?;
        let hash = crypto::sha256_hex(&payload);
        if hash != manifest.payload.hash {
            return Err(err("payload sha256 mismatch"));
        }

        let patch_dir = self
            .cache_dir
            .join("patches")
            .join(manifest.patch_number.to_string());
        fs::create_dir_all(&patch_dir)?;
        atomic_write_bytes(&patch_dir.join("manifest.json"), &fs::read(manifest_path)?)?;
        atomic_write_bytes(&patch_dir.join("payload.bin"), &payload)?;
        let artifact_path = if manifest.backend == "snapshot_replace" {
            let artifact = snapshot_replace_artifact(&manifest, &payload, baseline_artifact_path)?;
            atomic_write_bytes(&patch_dir.join("libapp.so"), &artifact)?;
            Some(format!("patches/{}/libapp.so", manifest.patch_number))
        } else {
            None
        };

        let mut state = self.load_state()?;
        state.schema_version = 1;
        state.release_version = manifest.release_version.clone();
        state.pending_patch_number = Some(manifest.patch_number);
        state
            .installed
            .retain(|p| p.patch_number != manifest.patch_number);
        state.installed.push(InstalledPatch {
            patch_number: manifest.patch_number,
            backend: manifest.backend,
            manifest_path: format!("patches/{}/manifest.json", manifest.patch_number),
            payload_path: format!("patches/{}/payload.bin", manifest.patch_number),
            artifact_path,
            installed_at: now_string(),
        });
        state.installed.sort_by_key(|p| p.patch_number);
        while state.installed.len() > 2 {
            let current = state.current_patch_number;
            let pending = state.pending_patch_number;
            let Some(index) = state.installed.iter().position(|patch| {
                patch.patch_number != current && Some(patch.patch_number) != pending
            }) else {
                break;
            };
            let old = state.installed.remove(index);
            let _ = fs::remove_dir_all(
                self.cache_dir
                    .join("patches")
                    .join(old.patch_number.to_string()),
            );
        }
        self.save_state(&state)
    }

    pub fn launch_patch(&self) -> Result<Option<InstalledPatch>> {
        let mut state = self.load_state()?;
        let mut state_changed = false;
        if matches!(
            state
                .last_launch
                .as_ref()
                .map(|launch| launch.status.as_str()),
            Some("pending_success")
        ) {
            if let Some(last) = &state.last_launch {
                if !state.bad_patches.contains(&last.patch_number) {
                    state.bad_patches.push(last.patch_number);
                }
                if state.current_patch_number == last.patch_number {
                    state.current_patch_number = 0;
                }
                if state.pending_patch_number == Some(last.patch_number) {
                    state.pending_patch_number = None;
                }
            }
            state.last_launch = None;
            state_changed = true;
        }
        let Some(patch_number) = state.pending_patch_number.or_else(|| {
            if state.current_patch_number == 0 {
                None
            } else {
                Some(state.current_patch_number)
            }
        }) else {
            if state_changed {
                self.save_state(&state)?;
            }
            return Ok(None);
        };
        if state.bad_patches.contains(&patch_number) {
            if state_changed {
                self.save_state(&state)?;
            }
            return Ok(None);
        }
        let installed = state
            .installed
            .iter()
            .find(|p| p.patch_number == patch_number)
            .cloned();
        if installed.is_some() {
            state.last_launch = Some(LastLaunch {
                patch_number,
                status: "pending_success".to_string(),
                started_at: now_string(),
            });
            state_changed = true;
        }
        if state_changed {
            self.save_state(&state)?;
        }
        Ok(installed)
    }

    pub fn ready_patch(&self) -> Result<Option<InstalledPatch>> {
        let state = self.load_state()?;
        let Some(patch_number) = state.pending_patch_number else {
            return Ok(None);
        };
        if state.bad_patches.contains(&patch_number) {
            return Ok(None);
        }
        Ok(state
            .installed
            .iter()
            .find(|p| p.patch_number == patch_number)
            .cloned())
    }

    pub fn mark_success(&self) -> Result<()> {
        let mut state = self.load_state()?;
        let Some(last) = &mut state.last_launch else {
            return Err(err("no last_launch to mark success"));
        };
        state.current_patch_number = last.patch_number;
        state.pending_patch_number = None;
        last.status = "success".to_string();
        self.save_state(&state)
    }

    pub fn mark_failure(&self, patch_number: u32, reason: &str) -> Result<()> {
        let mut state = self.load_state()?;
        if !state.bad_patches.contains(&patch_number) {
            state.bad_patches.push(patch_number);
        }
        if state.current_patch_number == patch_number {
            state.current_patch_number = 0;
        }
        if state.pending_patch_number == Some(patch_number) {
            state.pending_patch_number = None;
        }
        state.last_launch = Some(LastLaunch {
            patch_number,
            status: format!("failure:{reason}"),
            started_at: now_string(),
        });
        self.save_state(&state)
    }
}

fn snapshot_replace_artifact(
    manifest: &PatchManifest,
    payload: &[u8],
    baseline_artifact_path: Option<&Path>,
) -> Result<Vec<u8>> {
    match manifest.payload.kind.as_str() {
        "snapshot_replace_artifact" | "opaque_payload" => Ok(payload.to_vec()),
        "binary_diff" => {
            let algorithm = manifest.payload.diff_algorithm.as_deref();
            if algorithm != Some(SIMPLE_DIFF_ALGORITHM) && algorithm != Some(BSDIFF_ZSTD_ALGORITHM)
            {
                return Err(err(format!(
                    "unsupported binary diff algorithm: {:?}",
                    algorithm
                )));
            }
            let Some(baseline_artifact_path) = baseline_artifact_path else {
                return Err(err("baseline artifact required for binary diff"));
            };
            let baseline = fs::read(baseline_artifact_path)?;
            if let Some(expected_base_hash) = &manifest.payload.base_hash {
                let actual_base_hash = crypto::sha256_hex(&baseline);
                if &actual_base_hash != expected_base_hash {
                    return Err(err("base artifact sha256 mismatch"));
                }
            }
            let artifact = diff::apply_binary_diff(&baseline, payload)?;
            if let Some(expected_output_hash) = &manifest.payload.output_hash {
                let actual_output_hash = crypto::sha256_hex(&artifact);
                if &actual_output_hash != expected_output_hash {
                    return Err(err("patched artifact sha256 mismatch"));
                }
            }
            Ok(artifact)
        }
        _ => Err(err(format!(
            "unsupported snapshot_replace payload kind: {}",
            manifest.payload.kind
        ))),
    }
}

fn atomic_write_json<T: Serialize>(path: &Path, value: &T) -> Result<()> {
    let bytes = serde_json::to_vec_pretty(value)?;
    atomic_write_bytes(path, &bytes)
}

fn atomic_write_bytes(path: &Path, bytes: &[u8]) -> Result<()> {
    if let Some(parent) = path.parent() {
        fs::create_dir_all(parent)?;
    }
    let file_name = path
        .file_name()
        .and_then(|name| name.to_str())
        .unwrap_or("state");
    let tmp = path.with_file_name(format!(
        ".{file_name}.{}.{}.tmp",
        std::process::id(),
        unique_suffix()
    ));
    {
        let mut file = File::create(&tmp)?;
        file.write_all(bytes)?;
        file.sync_all()?;
    }
    fs::rename(tmp, path)?;
    Ok(())
}

fn now_string() -> String {
    let secs = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap_or_default()
        .as_secs();
    format!("{secs}")
}

fn unique_suffix() -> u128 {
    let nanos = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap_or_default()
        .as_nanos();
    let counter = TEMP_COUNTER.fetch_add(1, Ordering::Relaxed) as u128;
    (nanos << 32) | counter
}

#[cfg(test)]
mod tests {
    use super::{InstalledPatch, LastLaunch, State, Updater};
    use crate::crypto;
    use crate::diff::{self, BSDIFF_ZSTD_ALGORITHM, SIMPLE_DIFF_ALGORITHM};
    use crate::manifest::{self, PatchManifest, PatchPolicy, PatchSignature, PayloadManifest};

    #[test]
    fn mark_success_requires_last_launch() {
        let cache_dir =
            std::env::temp_dir().join(format!("fcb-state-test-{}", super::unique_suffix()));
        let updater = Updater::new(&cache_dir);

        let err = updater
            .mark_success()
            .expect_err("missing last_launch should fail");

        assert!(err.to_string().contains("no last_launch to mark success"));
        let _ = std::fs::remove_dir_all(cache_dir);
    }

    #[test]
    fn launch_patch_marks_previous_pending_launch_bad() {
        let cache_dir =
            std::env::temp_dir().join(format!("fcb-state-test-{}", super::unique_suffix()));
        let updater = Updater::new(&cache_dir);
        updater
            .save_state(&State {
                schema_version: 1,
                release_version: "1.0.0+1".to_string(),
                current_patch_number: 0,
                pending_patch_number: Some(1),
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
        assert!(state.last_launch.is_none());
        let _ = std::fs::remove_dir_all(cache_dir);
    }

    #[test]
    fn launch_patch_rolls_back_crashing_pending_patch_to_active_patch() {
        let cache_dir =
            std::env::temp_dir().join(format!("fcb-state-test-{}", super::unique_suffix()));
        let updater = Updater::new(&cache_dir);
        updater
            .save_state(&State {
                schema_version: 1,
                release_version: "1.0.0+1".to_string(),
                current_patch_number: 1,
                pending_patch_number: Some(2),
                bad_patches: Vec::new(),
                last_launch: Some(LastLaunch {
                    patch_number: 2,
                    status: "pending_success".to_string(),
                    started_at: "0".to_string(),
                }),
                installed: vec![
                    InstalledPatch {
                        patch_number: 1,
                        backend: "snapshot_replace".to_string(),
                        manifest_path: "patches/1/manifest.json".to_string(),
                        payload_path: "patches/1/payload.bin".to_string(),
                        artifact_path: Some("patches/1/libapp.so".to_string()),
                        installed_at: "0".to_string(),
                    },
                    InstalledPatch {
                        patch_number: 2,
                        backend: "snapshot_replace".to_string(),
                        manifest_path: "patches/2/manifest.json".to_string(),
                        payload_path: "patches/2/payload.bin".to_string(),
                        artifact_path: Some("patches/2/libapp.so".to_string()),
                        installed_at: "1".to_string(),
                    },
                ],
            })
            .expect("write state");

        let launch = updater
            .launch_patch()
            .expect("launch rollback patch")
            .expect("active patch should launch");
        let state = updater.load_state().expect("load state");

        assert_eq!(launch.patch_number, 1);
        assert_eq!(launch.artifact_path.as_deref(), Some("patches/1/libapp.so"));
        assert_eq!(state.bad_patches, vec![2]);
        assert_eq!(state.current_patch_number, 1);
        assert_eq!(state.pending_patch_number, None);
        assert_eq!(
            state.last_launch.as_ref().map(|launch| launch.patch_number),
            Some(1)
        );
        let _ = std::fs::remove_dir_all(cache_dir);
    }

    #[test]
    fn ready_patch_reports_pending_without_marking_launch() {
        let cache_dir =
            std::env::temp_dir().join(format!("fcb-state-test-{}", super::unique_suffix()));
        let updater = Updater::new(&cache_dir);
        updater
            .save_state(&State {
                schema_version: 1,
                release_version: "1.0.0+1".to_string(),
                current_patch_number: 0,
                pending_patch_number: Some(1),
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
        let cache_dir =
            std::env::temp_dir().join(format!("fcb-state-test-{}", super::unique_suffix()));
        let input_dir =
            std::env::temp_dir().join(format!("fcb-state-input-{}", super::unique_suffix()));
        std::fs::create_dir_all(&input_dir).expect("create input dir");
        let baseline = b"counter: 1; shared suffix";
        let patched = b"counter: 2; shared suffix";
        let baseline_path = input_dir.join("baseline.bin");
        std::fs::write(&baseline_path, baseline).expect("write baseline");
        let payload = diff::create_simple_diff(baseline, patched).expect("create diff");
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
                diff_algorithm: Some(SIMPLE_DIFF_ALGORITHM.to_string()),
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
    fn install_snapshot_replace_bsdiff_zstd_writes_launch_artifact() {
        let cache_dir =
            std::env::temp_dir().join(format!("fcb-state-test-{}", super::unique_suffix()));
        let input_dir =
            std::env::temp_dir().join(format!("fcb-state-input-{}", super::unique_suffix()));
        std::fs::create_dir_all(&input_dir).expect("create input dir");
        let baseline = b"counter: 1; shared suffix";
        let patched = b"counter: 2; shared suffix";
        let baseline_path = input_dir.join("baseline.bin");
        std::fs::write(&baseline_path, baseline).expect("write baseline");
        let payload = diff::create_bsdiff_zstd_diff(baseline, patched).expect("create bsdiff diff");
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
    fn install_prunes_old_patch_without_removing_current() {
        let cache_dir =
            std::env::temp_dir().join(format!("fcb-state-test-{}", super::unique_suffix()));
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

        let payload = b"bytecode payload";
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
                kind: "opaque_payload".to_string(),
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
}
