use crate::{crypto, err, Result};
use base64::{engine::general_purpose::STANDARD, Engine};
use serde::{Deserialize, Serialize};

/// Legacy simple diff algorithm for backward compatibility.
pub const SIMPLE_DIFF_ALGORITHM: &str = "fcb-simple-v1";

/// Primary binary diff algorithm for Phase B: bsdiff + zstd compression.
pub const BSDIFF_ZSTD_ALGORITHM: &str = "bsdiff-zstd-v1";

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SimpleBinaryDiff {
    pub algorithm: String,
    pub base_hash: String,
    pub output_hash: String,
    pub prefix_len: usize,
    pub suffix_len: usize,
    pub insert_b64: String,
}

/// Binary diff envelope: a self-describing container that wraps the diff payload
/// with algorithm identification, integrity hashes, and optional zstd compression.
///
/// For `bsdiff-zstd-v1`, the `payload` field contains the raw bsdiff patch bytes,
/// optionally compressed with zstd (when `compression == "zstd"`).
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BinaryDiffEnvelope {
    /// Must equal BSDIFF_ZSTD_ALGORITHM.
    pub algorithm: String,
    /// SHA-256 hex of the base (original) artifact.
    pub base_hash: String,
    /// SHA-256 hex of the target (patched) artifact.
    pub output_hash: String,
    /// Compression applied to the payload: "none" or "zstd".
    pub compression: String,
    /// Raw or compressed diff payload bytes, base64-encoded.
    pub payload_b64: String,
}

pub fn create_simple_diff(base: &[u8], target: &[u8]) -> Result<Vec<u8>> {
    let mut prefix_len = 0;
    while prefix_len < base.len()
        && prefix_len < target.len()
        && base[prefix_len] == target[prefix_len]
    {
        prefix_len += 1;
    }

    let mut suffix_len = 0;
    while suffix_len < base.len().saturating_sub(prefix_len)
        && suffix_len < target.len().saturating_sub(prefix_len)
        && base[base.len() - 1 - suffix_len] == target[target.len() - 1 - suffix_len]
    {
        suffix_len += 1;
    }

    let insert = &target[prefix_len..target.len() - suffix_len];
    let diff = SimpleBinaryDiff {
        algorithm: SIMPLE_DIFF_ALGORITHM.to_string(),
        base_hash: crypto::sha256_hex(base),
        output_hash: crypto::sha256_hex(target),
        prefix_len,
        suffix_len,
        insert_b64: STANDARD.encode(insert),
    };
    Ok(serde_json::to_vec(&diff)?)
}

pub fn apply_simple_diff(base: &[u8], diff_bytes: &[u8]) -> Result<Vec<u8>> {
    let diff: SimpleBinaryDiff = serde_json::from_slice(diff_bytes)?;
    if diff.algorithm != SIMPLE_DIFF_ALGORITHM {
        return Err(err("unsupported binary diff algorithm"));
    }
    let base_hash = crypto::sha256_hex(base);
    if base_hash != diff.base_hash {
        return Err(err("base artifact sha256 mismatch"));
    }
    if diff.prefix_len + diff.suffix_len > base.len() {
        return Err(err("binary diff range exceeds base artifact"));
    }

    let insert = STANDARD
        .decode(diff.insert_b64)
        .map_err(|e| err(e.to_string()))?;
    let mut output = Vec::with_capacity(diff.prefix_len + insert.len() + diff.suffix_len);
    output.extend_from_slice(&base[..diff.prefix_len]);
    output.extend_from_slice(&insert);
    output.extend_from_slice(&base[base.len() - diff.suffix_len..]);

    let output_hash = crypto::sha256_hex(&output);
    if output_hash != diff.output_hash {
        return Err(err("patched artifact sha256 mismatch"));
    }
    Ok(output)
}

/// Create a bsdiff + zstd compressed binary diff envelope.
/// This is the primary diff algorithm for Phase B snapshot_replace.
pub fn create_bsdiff_zstd_diff(base: &[u8], target: &[u8]) -> Result<Vec<u8>> {
    let mut patch = Vec::new();
    bsdiff::diff(base, target, &mut patch).map_err(|e| err(format!("bsdiff failed: {e}")))?;
    let compressed = zstd::encode_all(patch.as_slice(), 0)
        .map_err(|e| err(format!("zstd compression failed: {e}")))?;
    let envelope = BinaryDiffEnvelope {
        algorithm: BSDIFF_ZSTD_ALGORITHM.to_string(),
        base_hash: crypto::sha256_hex(base),
        output_hash: crypto::sha256_hex(target),
        compression: "zstd".to_string(),
        payload_b64: STANDARD.encode(&compressed),
    };
    Ok(serde_json::to_vec(&envelope)?)
}

/// Apply a binary diff envelope (bsdiff-zstd or simple) to a base artifact,
/// producing the patched output.
pub fn apply_binary_diff(base: &[u8], diff_bytes: &[u8]) -> Result<Vec<u8>> {
    // Try to parse as BinaryDiffEnvelope first (the new format).
    if let Ok(envelope) = serde_json::from_slice::<BinaryDiffEnvelope>(diff_bytes) {
        return apply_envelope(base, &envelope);
    }
    // Fall back to legacy SimpleBinaryDiff.
    apply_simple_diff(base, diff_bytes)
}

fn apply_envelope(base: &[u8], envelope: &BinaryDiffEnvelope) -> Result<Vec<u8>> {
    let base_hash = crypto::sha256_hex(base);
    if base_hash != envelope.base_hash {
        return Err(err(format!(
            "base artifact sha256 mismatch: expected {}, got {}",
            envelope.base_hash, base_hash
        )));
    }
    let payload = STANDARD
        .decode(&envelope.payload_b64)
        .map_err(|e| err(format!("invalid base64 in diff payload: {e}")))?;
    let patch_bytes = match envelope.compression.as_str() {
        "zstd" => zstd::decode_all(payload.as_slice())
            .map_err(|e| err(format!("zstd decompression failed: {e}")))?,
        "none" => payload,
        other => return Err(err(format!("unsupported diff compression: {other}"))),
    };
    match envelope.algorithm.as_str() {
        BSDIFF_ZSTD_ALGORITHM => {
            let mut output = Vec::new();
            bsdiff::patch(base, &mut patch_bytes.as_slice(), &mut output)
                .map_err(|e| err(format!("bspatch failed: {e}")))?;
            let output_hash = crypto::sha256_hex(&output);
            if output_hash != envelope.output_hash {
                return Err(err(format!(
                    "patched artifact sha256 mismatch: expected {}, got {}",
                    envelope.output_hash, output_hash
                )));
            }
            Ok(output)
        }
        other => Err(err(format!(
            "unsupported diff algorithm in envelope: {other}"
        ))),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn simple_diff_roundtrip_preserves_shared_prefix_and_suffix() {
        let base = b"counter: 1; shared suffix";
        let target = b"counter: 2; shared suffix";

        let diff = create_simple_diff(base, target).expect("create diff");
        let patched = apply_simple_diff(base, &diff).expect("apply diff");

        assert_eq!(patched, target);
        assert!(diff.len() < target.len() + 220);
    }

    #[test]
    fn simple_diff_rejects_wrong_base() {
        let diff = create_simple_diff(b"base", b"target").expect("create diff");

        let err = apply_simple_diff(b"other", &diff).expect_err("wrong base should fail");

        assert!(err.to_string().contains("base artifact sha256 mismatch"));
    }

    #[test]
    fn bsdiff_zstd_roundtrip_small_change() {
        let base = b"counter: 1; shared suffix data that is the same";
        let target = b"counter: 2; shared suffix data that is the same";

        let diff = create_bsdiff_zstd_diff(base, target).expect("create bsdiff diff");
        let patched = apply_binary_diff(base, &diff).expect("apply bsdiff diff");

        assert_eq!(patched, target);
    }

    #[test]
    fn bsdiff_zstd_roundtrip_large_artifact() {
        let base: Vec<u8> = (0..10000).map(|i| (i % 256) as u8).collect();
        let mut target = base.clone();
        // Change a few bytes in the middle.
        target[5000] = 0xAA;
        target[5001] = 0xBB;
        target[5002] = 0xCC;

        let diff = create_bsdiff_zstd_diff(&base, &target).expect("create bsdiff diff");
        let patched = apply_binary_diff(&base, &diff).expect("apply bsdiff diff");

        assert_eq!(patched, target);
        // Diff should be much smaller than the full artifact.
        assert!(
            diff.len() < target.len(),
            "bsdiff diff should be smaller than target"
        );
    }

    #[test]
    fn bsdiff_zstd_rejects_wrong_base() {
        let base = b"base artifact content";
        let target = b"target artifact content";

        let diff = create_bsdiff_zstd_diff(base, target).expect("create diff");
        let err = apply_binary_diff(b"wrong base", &diff).expect_err("wrong base should fail");

        assert!(
            err.to_string().contains("base artifact sha256 mismatch"),
            "expected sha256 mismatch, got: {err}"
        );
    }

    #[test]
    fn apply_binary_diff_falls_back_to_simple() {
        let base = b"counter: 1; shared suffix";
        let target = b"counter: 2; shared suffix";

        let diff = create_simple_diff(base, target).expect("create simple diff");
        let patched = apply_binary_diff(base, &diff).expect("apply via generic dispatcher");

        assert_eq!(patched, target);
    }

    #[test]
    fn bsdiff_zstd_diff_is_smaller_than_full_artifact() {
        // Simulate a libapp.so-like scenario: large base, small changes.
        let base = vec![0u8; 1_000_000];
        let mut target = base.clone();
        // Change 100 bytes near the beginning.
        for i in 0..100 {
            target[i] = 0xFF;
        }

        let diff = create_bsdiff_zstd_diff(&base, &target).expect("create bsdiff diff");
        assert!(
            diff.len() < target.len() / 10,
            "bsdiff+zstd diff ({}) should be < 10% of target ({})",
            diff.len(),
            target.len()
        );

        let patched = apply_binary_diff(&base, &diff).expect("apply bsdiff diff");
        assert_eq!(patched, target);
    }
}
