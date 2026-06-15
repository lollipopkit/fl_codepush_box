use crate::diff;
use crate::manifest::{self, PatchManifest};
use crate::{crypto, err, Result};
use serde::{Deserialize, Serialize};
use serde_json::Value;
use std::collections::BTreeSet;
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

    let base = find_diff_base(expected_base_hash, installed, cache_dir, baseline_artifact_path)?;
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
    let module: Value = serde_json::from_slice(payload)?;
    let Some(object) = module.as_object() else {
        return Err(err("bytecode module must be a JSON object"));
    };
    let version = object
        .get("version")
        .and_then(Value::as_u64)
        .ok_or_else(|| err("bytecode module version must be an integer"))?;
    if version != 1 {
        return Err(err(format!(
            "unexpected bytecode module version {version}, expected 1"
        )));
    }
    let functions = object
        .get("functions")
        .and_then(Value::as_array)
        .ok_or_else(|| err("bytecode module functions must be a list"))?;
    if functions.is_empty() {
        return Err(err("bytecode module must contain at least one function"));
    }

    let mut names = BTreeSet::new();
    for function in functions {
        validate_bytecode_function(function, &mut names)?;
    }
    Ok(())
}

fn validate_bytecode_function(function: &Value, names: &mut BTreeSet<String>) -> Result<()> {
    let Some(object) = function.as_object() else {
        return Err(err("bytecode function must be a JSON object"));
    };
    let name = object
        .get("name")
        .and_then(Value::as_str)
        .ok_or_else(|| err("bytecode function name must be a string"))?;
    if name.trim().is_empty() {
        return Err(err("bytecode function name must not be empty"));
    }
    if !names.insert(name.to_string()) {
        return Err(err(format!("duplicate bytecode function {name}")));
    }
    let param_count = read_u8_field(object, "param_count", name)?;
    let local_count = read_u8_field(object, "local_count", name)?;
    if local_count < param_count {
        return Err(err(format!(
            "function {name} local_count {local_count} is smaller than param_count {param_count}"
        )));
    }
    let constants_len = object
        .get("constants")
        .and_then(Value::as_array)
        .ok_or_else(|| err(format!("constants for {name} must be a list")))?
        .len();
    let code_values = object
        .get("code")
        .and_then(Value::as_array)
        .ok_or_else(|| err(format!("code for {name} must be a list")))?;
    let code = code_values
        .iter()
        .map(|value| {
            let byte = value
                .as_u64()
                .ok_or_else(|| err(format!("code for {name} must contain byte integers")))?;
            u8::try_from(byte).map_err(|_| err(format!("code byte {byte} for {name} exceeds u8")))
        })
        .collect::<Result<Vec<_>>>()?;
    validate_bytecode(name, constants_len, &code)
}

fn read_u8_field(
    object: &serde_json::Map<String, Value>,
    field: &str,
    function_name: &str,
) -> Result<u8> {
    let value = object
        .get(field)
        .and_then(Value::as_u64)
        .ok_or_else(|| err(format!("{field} for {function_name} must be an integer")))?;
    u8::try_from(value).map_err(|_| err(format!("{field} for {function_name} exceeds u8")))
}

fn validate_bytecode(function_name: &str, constants_len: usize, code: &[u8]) -> Result<()> {
    if code.is_empty() {
        return Err(err(format!("function {function_name} has empty bytecode")));
    }

    let mut starts = BTreeSet::new();
    let mut pos = 0usize;
    while pos < code.len() {
        starts.insert(pos);
        let opcode = decode_opcode(code[pos]).ok_or_else(|| {
            err(format!(
                "invalid opcode 0x{:02x} at offset {pos} in {function_name}",
                code[pos]
            ))
        })?;
        let operand_start = pos + 1;
        let next = operand_start + opcode_operand_len(opcode);
        if next > code.len() {
            return Err(err(format!(
                "opcode 0x{opcode:02x} at offset {pos} in {function_name} requires {} operand bytes",
                opcode_operand_len(opcode)
            )));
        }
        if opcode == 0x01 {
            let idx = read_u16(code, operand_start) as usize;
            if idx >= constants_len {
                return Err(err(format!(
                    "LoadConst at offset {pos} in {function_name} references missing constant {idx}"
                )));
            }
        }
        pos = next;
    }

    pos = 0;
    while pos < code.len() {
        let opcode = decode_opcode(code[pos]).expect("validated opcode");
        let operand_start = pos + 1;
        if matches!(opcode, 0x30 | 0x31 | 0x32) {
            let target = read_u16(code, operand_start) as usize;
            if target >= code.len() {
                return Err(err(format!(
                    "opcode 0x{opcode:02x} at offset {pos} in {function_name} targets out-of-range offset {target}"
                )));
            }
            if !starts.contains(&target) {
                return Err(err(format!(
                    "opcode 0x{opcode:02x} at offset {pos} in {function_name} targets non-instruction offset {target}"
                )));
            }
        }
        pos = operand_start + opcode_operand_len(opcode);
    }
    Ok(())
}

fn decode_opcode(byte: u8) -> Option<u8> {
    match byte {
        0x01 | 0x02 | 0x03 | 0x04 | 0x10 | 0x11 | 0x12 | 0x13 | 0x20 | 0x21 | 0x30 | 0x31
        | 0x32 | 0x40 | 0x41 | 0xff => Some(byte),
        _ => None,
    }
}

fn opcode_operand_len(opcode: u8) -> usize {
    match opcode {
        0x01 | 0x30 | 0x31 | 0x32 | 0x40 | 0x41 => 2,
        0x02 | 0x03 | 0x04 => 1,
        0x10 | 0x11 | 0x12 | 0x13 | 0x20 | 0x21 | 0xff => 0,
        _ => 0,
    }
}

fn read_u16(code: &[u8], pos: usize) -> u16 {
    u16::from_be_bytes([code[pos], code[pos + 1]])
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
    use crate::diff::{self, BSDIFF_ZSTD_ALGORITHM};
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
        let cache_dir =
            std::env::temp_dir().join(format!("fcb-state-test-{}", super::unique_suffix()));
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
            &private_key, 1,
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
            .install_payload_with_baseline(&manifest1_path, &payload1_path, &public_key, Some(&baseline_path))
            .expect("install patch 1");

        assert_eq!(
            std::fs::read(cache_dir.join("patches/1/libapp.so")).expect("v1 artifact"),
            v1
        );

        // Install patch 2: diff from v1 -> v2 (no baseline_path needed; uses patch 1 artifact)
        let diff2 = diff::create_bsdiff_zstd(v1, v2).expect("diff2");
        let mut patch2 = make_snapshot_patch(
            &private_key, 2,
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
                download_url: format!("patches/app/release/android/arm64-v8a/{patch_number}/payload.bin"),
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
        let cache_dir =
            std::env::temp_dir().join(format!("fcb-state-test-{}", super::unique_suffix()));
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

        assert!(err.to_string().contains("requires binary_diff payload"), "{err}");

        let _ = std::fs::remove_dir_all(cache_dir);
        let _ = std::fs::remove_dir_all(input_dir);
    }

    #[test]
    fn install_bytecode_payload_launches_payload_without_artifact() {
        let cache_dir =
            std::env::temp_dir().join(format!("fcb-state-test-{}", super::unique_suffix()));
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
        let cache_dir =
            std::env::temp_dir().join(format!("fcb-state-test-{}", super::unique_suffix()));
        let input_dir =
            std::env::temp_dir().join(format!("fcb-state-input-{}", super::unique_suffix()));
        std::fs::create_dir_all(&input_dir).expect("create input dir");
        let payload = br#"{"version":1,"functions":[{"name":"bad","param_count":0,"local_count":0,"constants":[],"code":[1,0,0,255]}]}"#;
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

        assert!(err.to_string().contains("references missing constant"));
        assert!(!cache_dir.join("patches/5/payload.bin").exists());
        let state = updater.load_state().expect("load state");
        assert!(state.installed.is_empty());
        assert_eq!(state.pending_patch_number, None);

        let _ = std::fs::remove_dir_all(cache_dir);
        let _ = std::fs::remove_dir_all(input_dir);
    }
}
