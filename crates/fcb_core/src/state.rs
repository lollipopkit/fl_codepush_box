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
            installed_at: now_string(),
        });
        state.installed.sort_by_key(|p| p.patch_number);
        while state.installed.len() > 2 {
            if let Some(old) = state.installed.first().cloned() {
                let _ = fs::remove_dir_all(
                    self.cache_dir
                        .join("patches")
                        .join(old.patch_number.to_string()),
                );
                state.installed.remove(0);
            }
        }
        self.save_state(&state)
    }

    pub fn launch_patch(&self) -> Result<Option<InstalledPatch>> {
        let mut state = self.load_state()?;
        let Some(patch_number) = state.pending_patch_number.or_else(|| {
            if state.current_patch_number == 0 {
                None
            } else {
                Some(state.current_patch_number)
            }
        }) else {
            return Ok(None);
        };
        if state.bad_patches.contains(&patch_number) {
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
            self.save_state(&state)?;
        }
        Ok(installed)
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
    use super::Updater;

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
}
