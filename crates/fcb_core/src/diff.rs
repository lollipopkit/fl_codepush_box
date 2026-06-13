use crate::{crypto, err, Result};
use base64::{engine::general_purpose::STANDARD, Engine};
use serde::{Deserialize, Serialize};
use std::io::Cursor;

pub const BSDIFF_ZSTD_ALGORITHM: &str = "bsdiff-zstd-v1";
pub const SIMPLE_DIFF_ALGORITHM: &str = "fcb-simple-v1";
const ZSTD_LEVEL: i32 = 9;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SimpleBinaryDiff {
    pub algorithm: String,
    pub base_hash: String,
    pub output_hash: String,
    pub prefix_len: usize,
    pub suffix_len: usize,
    pub insert_b64: String,
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

pub fn create_bsdiff_zstd(base: &[u8], target: &[u8]) -> Result<Vec<u8>> {
    let mut raw_patch = Vec::new();
    bsdiff::diff(base, target, &mut raw_patch)?;
    Ok(zstd::bulk::compress(&raw_patch, ZSTD_LEVEL)?)
}

pub fn apply_binary_diff(algorithm: &str, base: &[u8], diff_bytes: &[u8]) -> Result<Vec<u8>> {
    match algorithm {
        BSDIFF_ZSTD_ALGORITHM => apply_bsdiff_zstd(base, diff_bytes),
        SIMPLE_DIFF_ALGORITHM => apply_simple_diff(base, diff_bytes),
        _ => Err(err("unsupported binary diff algorithm")),
    }
}

pub fn apply_bsdiff_zstd(base: &[u8], diff_bytes: &[u8]) -> Result<Vec<u8>> {
    let raw_patch = zstd::decode_all(Cursor::new(diff_bytes))?;
    let mut output = Vec::new();
    bsdiff::patch(base, &mut raw_patch.as_slice(), &mut output)?;
    Ok(output)
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

#[cfg(test)]
mod tests {
    use super::{
        apply_binary_diff, apply_bsdiff_zstd, apply_simple_diff, create_bsdiff_zstd,
        create_simple_diff, BSDIFF_ZSTD_ALGORITHM, SIMPLE_DIFF_ALGORITHM,
    };

    #[test]
    fn bsdiff_zstd_roundtrip_preserves_target() {
        let base = b"counter: 1; shared suffix";
        let target = b"counter: 2; shared suffix";

        let diff = create_bsdiff_zstd(base, target).expect("create diff");
        let patched = apply_bsdiff_zstd(base, &diff).expect("apply diff");

        assert_eq!(patched, target);
        assert!(diff.len() < target.len() + 220);
    }

    #[test]
    fn binary_diff_dispatch_supports_current_and_legacy_algorithms() {
        let base = b"counter: 1; shared suffix";
        let target = b"counter: 2; shared suffix";

        let current = create_bsdiff_zstd(base, target).expect("create bsdiff");
        let legacy = create_simple_diff(base, target).expect("create simple diff");

        assert_eq!(
            apply_binary_diff(BSDIFF_ZSTD_ALGORITHM, base, &current).expect("apply bsdiff"),
            target
        );
        assert_eq!(
            apply_binary_diff(SIMPLE_DIFF_ALGORITHM, base, &legacy).expect("apply simple"),
            target
        );
    }

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
}
