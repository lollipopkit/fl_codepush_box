use crate::bytecode::BytecodeModule;
use crate::diff;
use crate::manifest::{self, PatchManifest};
use crate::{crypto, err, Result};
use serde::{Deserialize, Serialize};
use std::fs::{self, File};
use std::io::Write;
use std::path::{Path, PathBuf};
use std::sync::atomic::{AtomicU64, Ordering};
use std::time::{SystemTime, UNIX_EPOCH};

static TEMP_COUNTER: AtomicU64 = AtomicU64::new(0);
const STATE_SCHEMA_VERSION: u32 = 2;
const MAX_BOOT_ATTEMPTS: u32 = 3;
const ROLLBACK_EVENTS_FILE: &str = "events.log";
const MAX_ROLLBACK_EVENTS: usize = 50;

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct State {
    pub schema_version: u32,
    pub release_version: String,
    pub current_patch_number: u32,
    pub pending_patch_number: Option<u32>,
    #[serde(default)]
    pub last_known_good_patch_number: Option<u32>,
    #[serde(default)]
    pub boot_attempts: u32,
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

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CrashRollbackEvent {
    pub event_type: String,
    pub patch_number: u32,
    pub boot_attempts: u32,
    pub last_known_good_patch_number: Option<u32>,
    pub timestamp: String,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub reason: Option<String>,
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

    pub fn rollback_events_path(&self) -> PathBuf {
        self.cache_dir.join(ROLLBACK_EVENTS_FILE)
    }

    pub fn load_state(&self) -> Result<State> {
        let path = self.state_path();
        if !path.exists() {
            return Ok(State {
                schema_version: STATE_SCHEMA_VERSION,
                ..State::default()
            });
        }
        let bytes = fs::read(&path)?;
        let mut state: State = match serde_json::from_slice(&bytes) {
            Ok(state) => state,
            Err(error) => {
                backup_corrupt_state(&path)?;
                append_rollback_event(
                    &self.cache_dir,
                    CrashRollbackEvent {
                        event_type: "state_reset".to_string(),
                        patch_number: 0,
                        boot_attempts: 0,
                        last_known_good_patch_number: None,
                        timestamp: now_string(),
                        reason: Some(format!("failed to parse state.json: {error}")),
                    },
                )?;
                return Ok(State {
                    schema_version: STATE_SCHEMA_VERSION,
                    ..State::default()
                });
            }
        };
        migrate_state(&mut state);
        Ok(state)
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
        validate_payload_contract(&manifest, &payload)?;

        let patch_dir = self
            .cache_dir
            .join("patches")
            .join(manifest.patch_number.to_string());
        fs::create_dir_all(&patch_dir)?;
        atomic_write_bytes(&patch_dir.join("manifest.json"), &fs::read(manifest_path)?)?;
        atomic_write_bytes(&patch_dir.join("payload.bin"), &payload)?;

        let mut state = self.load_state()?;
        let artifact_path = if manifest.backend == "snapshot_replace" {
            let artifact = snapshot_replace_chained_diff(
                &manifest,
                &payload,
                &state.installed,
                &self.cache_dir,
                baseline_artifact_path,
            )?;
            atomic_write_bytes(&patch_dir.join("libapp.so"), &artifact)?;
            Some(format!("patches/{}/libapp.so", manifest.patch_number))
        } else {
            None
        };
        state.schema_version = STATE_SCHEMA_VERSION;
        state.release_version = manifest.release_version.clone();
        state.pending_patch_number = Some(manifest.patch_number);
        state.boot_attempts = 0;
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
            let last_known_good = state.last_known_good_patch_number;
            let Some(index) = state.installed.iter().position(|patch| {
                patch.patch_number != current
                    && Some(patch.patch_number) != pending
                    && Some(patch.patch_number) != last_known_good
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
            if let Some(patch_number) = state.last_launch.as_ref().map(|last| last.patch_number) {
                if state.boot_attempts.saturating_add(1) >= MAX_BOOT_ATTEMPTS {
                    append_rollback_event(
                        &self.cache_dir,
                        CrashRollbackEvent {
                            event_type: "crash_rollback".to_string(),
                            patch_number,
                            boot_attempts: state.boot_attempts.saturating_add(1),
                            last_known_good_patch_number: state.last_known_good_patch_number,
                            timestamp: now_string(),
                            reason: None,
                        },
                    )?;
                    mark_patch_bad(&mut state, patch_number);
                }
            }
            state.last_launch = None;
            state_changed = true;
        }
        let Some(patch_number) = select_launch_patch_number(&state) else {
            if state_changed {
                self.save_state(&state)?;
            }
            return Ok(None);
        };
        let installed = state
            .installed
            .iter()
            .find(|p| p.patch_number == patch_number)
            .cloned();
        if installed.is_some() {
            state.boot_attempts = state.boot_attempts.saturating_add(1);
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
        if state.bad_patches.contains(&last.patch_number) {
            return Err(err("cannot mark a bad patch as successful"));
        }
        if last.status.starts_with("failure:") {
            return Err(err("cannot mark a failed launch as successful"));
        }
        state.current_patch_number = last.patch_number;
        state.last_known_good_patch_number = Some(last.patch_number);
        state.pending_patch_number = None;
        state.boot_attempts = 0;
        last.status = "success".to_string();
        self.save_state(&state)
    }

    pub fn mark_failure(&self, patch_number: u32, reason: &str) -> Result<()> {
        let mut state = self.load_state()?;
        mark_patch_bad(&mut state, patch_number);
        state.last_launch = Some(LastLaunch {
            patch_number,
            status: format!("failure:{reason}"),
            started_at: now_string(),
        });
        self.save_state(&state)
    }

    pub fn rollback_events(&self) -> Result<Vec<CrashRollbackEvent>> {
        let path = self.rollback_events_path();
        if !path.exists() {
            return Ok(Vec::new());
        }
        let content = fs::read_to_string(path)?;
        content
            .lines()
            .filter(|line| !line.trim().is_empty())
            .map(|line| serde_json::from_str(line).map_err(Into::into))
            .collect()
    }

    pub fn clear_rollback_events(&self) -> Result<()> {
        let path = self.rollback_events_path();
        if path.exists() {
            fs::remove_file(path)?;
        }
        Ok(())
    }
}

fn append_rollback_event(cache_dir: &Path, event: CrashRollbackEvent) -> Result<()> {
    fs::create_dir_all(cache_dir)?;
    let path = cache_dir.join(ROLLBACK_EVENTS_FILE);
    let mut lines = if path.exists() {
        fs::read_to_string(&path)?
            .lines()
            .filter(|line| !line.trim().is_empty())
            .map(ToString::to_string)
            .collect::<Vec<_>>()
    } else {
        Vec::new()
    };
    lines.push(serde_json::to_string(&event)?);
    if lines.len() > MAX_ROLLBACK_EVENTS {
        lines.drain(0..lines.len() - MAX_ROLLBACK_EVENTS);
    }
    let mut content = lines.join("\n").into_bytes();
    content.push(b'\n');
    atomic_write_bytes(&path, &content)
}

fn backup_corrupt_state(path: &Path) -> Result<()> {
    let backup = path.with_file_name(format!("state.json.corrupt.{}", unique_suffix()));
    fs::rename(path, backup)?;
    Ok(())
}

fn migrate_state(state: &mut State) {
    if state.schema_version < STATE_SCHEMA_VERSION {
        if state.last_known_good_patch_number.is_none() && state.current_patch_number > 0 {
            state.last_known_good_patch_number = Some(state.current_patch_number);
        }
        state.schema_version = STATE_SCHEMA_VERSION;
    }
}

fn mark_patch_bad(state: &mut State, patch_number: u32) {
    if !state.bad_patches.contains(&patch_number) {
        state.bad_patches.push(patch_number);
    }
    if state.current_patch_number == patch_number {
        state.current_patch_number = state
            .last_known_good_patch_number
            .filter(|lkg| *lkg != patch_number)
            .unwrap_or_default();
    }
    if state.pending_patch_number == Some(patch_number) {
        state.pending_patch_number = None;
    }
    if state.last_known_good_patch_number == Some(patch_number) {
        state.last_known_good_patch_number = None;
    }
    state.boot_attempts = 0;
}

fn select_launch_patch_number(state: &State) -> Option<u32> {
    [
        state.pending_patch_number,
        (state.current_patch_number > 0).then_some(state.current_patch_number),
        state.last_known_good_patch_number,
    ]
    .into_iter()
    .flatten()
    .find(|patch_number| {
        !state.bad_patches.contains(patch_number)
            && state
                .installed
                .iter()
                .any(|patch| patch.patch_number == *patch_number)
    })
}

fn validate_payload_contract(manifest: &PatchManifest, payload: &[u8]) -> Result<()> {
    match manifest.backend.as_str() {
        "bytecode" => {
            if manifest.payload.kind != "bytecode_module" {
                return Err(err("bytecode backend requires bytecode_module payload"));
            }
            validate_bytecode_module_payload(payload)
        }
        "snapshot_replace" => {
            if manifest.payload.kind != "binary_diff" {
                return Err(err("snapshot_replace backend requires binary_diff payload"));
            }
            if manifest.payload.diff_algorithm.is_none() {
                return Err(err("snapshot_replace binary_diff requires diff_algorithm"));
            }
            if manifest.payload.base_hash.is_none() {
                return Err(err("snapshot_replace binary_diff requires base_hash"));
            }
            if manifest.payload.output_hash.is_none() {
                return Err(err("snapshot_replace binary_diff requires output_hash"));
            }
            Ok(())
        }
        backend => Err(err(format!("unsupported patch backend {backend}"))),
    }
}

fn snapshot_replace_chained_diff(
    manifest: &PatchManifest,
    payload: &[u8],
    installed: &[InstalledPatch],
    cache_dir: &Path,
    baseline_artifact_path: Option<&Path>,
) -> Result<Vec<u8>> {
    let diff_algorithm = manifest
        .payload
        .diff_algorithm
        .as_deref()
        .ok_or_else(|| err("missing binary diff algorithm"))?;
    let expected_base_hash = manifest
        .payload
        .base_hash
        .as_deref()
        .ok_or_else(|| err("snapshot_replace binary_diff requires base_hash"))?;

    let base = find_diff_base(
        expected_base_hash,
        installed,
        cache_dir,
        baseline_artifact_path,
    )?;
    let artifact = diff::apply_binary_diff(diff_algorithm, &base, payload)?;

    if let Some(expected_output_hash) = &manifest.payload.output_hash {
        let actual_output_hash = crypto::sha256_hex(&artifact);
        if actual_output_hash != *expected_output_hash {
            return Err(err("patched artifact sha256 mismatch"));
        }
    }
    Ok(artifact)
}

fn find_diff_base(
    expected_hash: &str,
    installed: &[InstalledPatch],
    cache_dir: &Path,
    baseline_artifact_path: Option<&Path>,
) -> Result<Vec<u8>> {
    for patch in installed.iter().rev() {
        let Some(artifact_rel) = &patch.artifact_path else {
            continue;
        };
        let Ok(candidate) = fs::read(cache_dir.join(artifact_rel)) else {
            continue;
        };
        if crypto::sha256_hex(&candidate) == expected_hash {
            return Ok(candidate);
        }
    }
    let Some(baseline_path) = baseline_artifact_path else {
        return Err(err(
            "no installed patch artifact matches base_hash and no baseline artifact provided",
        ));
    };
    let baseline = fs::read(baseline_path)?;
    if crypto::sha256_hex(&baseline) != expected_hash {
        return Err(err(
            "baseline artifact sha256 does not match manifest base_hash",
        ));
    }
    Ok(baseline)
}

fn validate_bytecode_module_payload(payload: &[u8]) -> Result<()> {
    BytecodeModule::from_slice_envelope(payload).map(|_| ())
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
#[path = "state_tests.rs"]
mod tests;
