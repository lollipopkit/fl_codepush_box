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
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub diff_algorithm: Option<String>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub base_hash: Option<String>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub output_hash: Option<String>,
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

pub const RELEASE_MANIFEST_REQUIRED: &[&str] = &[
    "schema_version",
    "app_id",
    "release_version",
    "channel",
    "platform",
    "arch",
    "backend",
    "artifact_hash",
    "artifact_size",
];

pub const PATCH_MANIFEST_REQUIRED: &[&str] = &[
    "schema_version",
    "app_id",
    "release_version",
    "patch_number",
    "channel",
    "created_at",
    "backend",
    "platform",
    "arch",
    "payload",
    "policy",
    "signature",
];

pub const PAYLOAD_MANIFEST_REQUIRED: &[&str] =
    &["kind", "compression", "hash", "size", "download_url"];
pub const PATCH_POLICY_REQUIRED: &[&str] = &["rollout_percentage", "allow_downgrade"];
pub const PATCH_SIGNATURE_REQUIRED: &[&str] = &["algorithm", "key_id", "value"];

pub fn canonical_json<T: Serialize>(value: &T) -> Result<Vec<u8>> {
    let value = serde_json::to_value(value)?;
    let normalized = normalize(value);
    Ok(serde_json::to_vec(&normalized)?)
}

pub fn sign_patch_manifest(manifest: &mut PatchManifest, private_key_b64: &str) -> Result<()> {
    let original_value = manifest.signature.value.clone();
    let original_algorithm = manifest.signature.algorithm.clone();
    let result = (|| {
        let mut unsigned = manifest.clone();
        unsigned.signature.algorithm = "ed25519".to_string();
        unsigned.signature.value.clear();
        let bytes = canonical_json(&unsigned)?;
        let signed_b64 = crypto::sign_b64(private_key_b64, &bytes)?;
        Ok(signed_b64)
    })();

    match result {
        Ok(signed_b64) => {
            manifest.signature.algorithm = "ed25519".to_string();
            manifest.signature.value = signed_b64;
            Ok(())
        }
        Err(e) => {
            manifest.signature.algorithm = original_algorithm;
            manifest.signature.value = original_value;
            Err(e)
        }
    }
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

#[cfg(test)]
mod tests {
    use super::{
        canonical_json, sign_patch_manifest, verify_patch_manifest, PatchManifest, PatchPolicy,
        PatchSignature, PayloadManifest,
    };
    use crate::crypto;
    use serde_json::json;

    #[test]
    fn canonical_json_sorts_object_keys_recursively() {
        let value = json!({
            "z": 1,
            "a": {
                "b": 2,
                "a": 1
            }
        });

        let bytes = canonical_json(&value).expect("canonical json");

        assert_eq!(
            std::str::from_utf8(&bytes).expect("utf8"),
            r#"{"a":{"a":1,"b":2},"z":1}"#
        );
    }

    #[test]
    fn patch_manifest_sign_and_verify_roundtrip() {
        let (private_key, public_key) = crypto::generate_keypair_b64();
        let mut manifest = test_manifest();

        sign_patch_manifest(&mut manifest, &private_key).expect("sign manifest");

        assert_eq!(manifest.signature.algorithm, "ed25519");
        assert!(!manifest.signature.value.is_empty());
        verify_patch_manifest(&manifest, &public_key).expect("verify manifest");
    }

    #[test]
    fn sign_patch_manifest_restores_signature_on_failure() {
        let mut manifest = test_manifest();
        manifest.signature.algorithm = "custom".to_string();
        manifest.signature.value = "original".to_string();

        let err =
            sign_patch_manifest(&mut manifest, "not-base64").expect_err("signing should fail");

        assert!(err.to_string().contains("invalid private key base64"));
        assert_eq!(manifest.signature.algorithm, "custom");
        assert_eq!(manifest.signature.value, "original");
    }

    fn test_manifest() -> PatchManifest {
        PatchManifest {
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
                hash: "0".repeat(64),
                size: 0,
                download_url: "patches/app/release/payload.bin".to_string(),
                diff_algorithm: None,
                base_hash: None,
                output_hash: None,
            },
            policy: PatchPolicy {
                rollout_percentage: 0,
                allow_downgrade: false,
            },
            signature: PatchSignature {
                algorithm: "ed25519".to_string(),
                key_id: "dev".to_string(),
                value: String::new(),
            },
        }
    }
}
