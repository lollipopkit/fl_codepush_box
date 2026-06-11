use crate::{crypto, err, Result};
use serde::{Deserialize, Serialize};
use serde_json::{Map, Value};
use std::fs;
use std::path::Path;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ReleaseManifest {
    pub schema_version: u32,
    pub app_id: String,
    pub release_version: String,
    pub channel: String,
    pub platform: String,
    pub arch: String,
    pub backend: String,
    pub artifact_hash: String,
    pub artifact_size: u64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PatchManifest {
    pub schema_version: u32,
    pub app_id: String,
    pub release_version: String,
    pub patch_number: u32,
    pub channel: String,
    pub created_at: String,
    pub backend: String,
    pub platform: String,
    pub arch: String,
    pub payload: PayloadManifest,
    pub policy: PatchPolicy,
    pub signature: PatchSignature,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PayloadManifest {
    pub kind: String,
    pub compression: String,
    pub hash: String,
    pub size: u64,
    pub download_url: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PatchPolicy {
    pub rollout_percentage: u8,
    pub allow_downgrade: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PatchSignature {
    pub algorithm: String,
    pub key_id: String,
    pub value: String,
}

pub fn canonical_json<T: Serialize>(value: &T) -> Result<Vec<u8>> {
    let value = serde_json::to_value(value)?;
    let normalized = normalize(value);
    Ok(serde_json::to_vec(&normalized)?)
}

pub fn sign_patch_manifest(manifest: &mut PatchManifest, private_key_b64: &str) -> Result<()> {
    manifest.signature.value.clear();
    let bytes = canonical_json(manifest)?;
    manifest.signature.value = crypto::sign_b64(private_key_b64, &bytes)?;
    Ok(())
}

pub fn verify_patch_manifest(manifest: &PatchManifest, public_key_b64: &str) -> Result<()> {
    if manifest.signature.algorithm != "ed25519" {
        return Err(err("unsupported patch signature algorithm"));
    }
    let mut unsigned = manifest.clone();
    let signature = unsigned.signature.value.clone();
    unsigned.signature.value.clear();
    let bytes = canonical_json(&unsigned)?;
    crypto::verify_b64(public_key_b64, &bytes, &signature)
}

pub fn read_json<T: for<'de> Deserialize<'de>>(path: &Path) -> Result<T> {
    Ok(serde_json::from_slice(&fs::read(path)?)?)
}

pub fn write_json<T: Serialize>(path: &Path, value: &T) -> Result<()> {
    if let Some(parent) = path.parent() {
        fs::create_dir_all(parent)?;
    }
    let bytes = serde_json::to_vec_pretty(value)?;
    fs::write(path, bytes)?;
    Ok(())
}

fn normalize(value: Value) -> Value {
    match value {
        Value::Object(map) => {
            let mut keys = map.keys().cloned().collect::<Vec<_>>();
            keys.sort();
            let mut ordered = Map::new();
            for key in keys {
                ordered.insert(key.clone(), normalize(map.get(&key).unwrap().clone()));
            }
            Value::Object(ordered)
        }
        Value::Array(items) => Value::Array(items.into_iter().map(normalize).collect()),
        other => other,
    }
}

