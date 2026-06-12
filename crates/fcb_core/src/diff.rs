use crate::{crypto, err, Result};
use base64::{engine::general_purpose::STANDARD, Engine};
use serde::{Deserialize, Serialize};

pub const SIMPLE_DIFF_ALGORITHM: &str = "fcb-simple-v1";

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
    use super::{apply_simple_diff, create_simple_diff};

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
