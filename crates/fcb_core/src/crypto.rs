use crate::{err, Result};
use base64::{engine::general_purpose::STANDARD, Engine};
use ed25519_dalek::{Signature, Signer, SigningKey, Verifier, VerifyingKey};
use sha2::{Digest, Sha256};

pub fn sha256_hex(bytes: &[u8]) -> String {
    hex::encode(Sha256::digest(bytes))
}

pub fn generate_keypair_b64() -> (String, String) {
    let mut key = [0u8; 32];
    getrandom::fill(&mut key).expect("OS random source failed");
    let signing = SigningKey::from_bytes(&key);
    let verify = signing.verifying_key();
    (
        STANDARD.encode(signing.to_bytes()),
        STANDARD.encode(verify.to_bytes()),
    )
}

pub fn sign_b64(private_key_b64: &str, message: &[u8]) -> Result<String> {
    let key = private_key_seed(private_key_b64)?;
    let signing = SigningKey::from_bytes(&key);
    Ok(STANDARD.encode(signing.sign(message).to_bytes()))
}

pub fn private_key_seed_b64(key_material: &str) -> Result<String> {
    Ok(STANDARD.encode(private_key_seed(key_material)?))
}

pub fn public_key_b64_from_private_key(key_material: &str) -> Result<String> {
    let signing = SigningKey::from_bytes(&private_key_seed(key_material)?);
    Ok(STANDARD.encode(signing.verifying_key().to_bytes()))
}

pub fn verify_b64(public_key_b64: &str, message: &[u8], signature_b64: &str) -> Result<()> {
    let key_bytes = STANDARD
        .decode(public_key_b64)
        .map_err(|e| err(format!("invalid public key base64: {e}")))?;
    let key: [u8; 32] = key_bytes
        .try_into()
        .map_err(|_| err("ed25519 public key must be 32 bytes"))?;
    let verifying =
        VerifyingKey::from_bytes(&key).map_err(|e| err(format!("invalid public key: {e}")))?;
    let sig_bytes = STANDARD
        .decode(signature_b64)
        .map_err(|e| err(format!("invalid signature base64: {e}")))?;
    let signature =
        Signature::from_slice(&sig_bytes).map_err(|e| err(format!("invalid signature: {e}")))?;
    verifying
        .verify(message, &signature)
        .map_err(|e| err(format!("signature verification failed: {e}")))
}

fn private_key_seed(key_material: &str) -> Result<[u8; 32]> {
    let trimmed = key_material.trim();
    if trimmed.starts_with("-----BEGIN OPENSSH PRIVATE KEY-----") {
        return openssh_ed25519_seed(trimmed);
    }
    let key_bytes = STANDARD
        .decode(trimmed)
        .map_err(|e| err(format!("invalid private key base64: {e}")))?;
    key_bytes
        .try_into()
        .map_err(|_| err("ed25519 private key must be 32 bytes"))
}

fn openssh_ed25519_seed(pem: &str) -> Result<[u8; 32]> {
    let b64 = pem
        .lines()
        .filter(|line| !line.starts_with("-----"))
        .collect::<String>();
    let data = STANDARD
        .decode(b64)
        .map_err(|e| err(format!("invalid OpenSSH private key base64: {e}")))?;
    let mut reader = BinaryReader::new(&data);
    reader.expect_bytes(b"openssh-key-v1\0")?;
    let cipher = reader.string_utf8()?;
    let kdf = reader.string_utf8()?;
    let _kdf_options = reader.string()?;
    let nkeys = reader.u32()?;
    if cipher != "none" || kdf != "none" {
        return Err(err("encrypted OpenSSH private keys are not supported"));
    }
    if nkeys != 1 {
        return Err(err("OpenSSH private key must contain exactly one key"));
    }
    let _public = reader.string()?;
    let private_blob = reader.string()?;
    let mut private = BinaryReader::new(private_blob);
    let check1 = private.u32()?;
    let check2 = private.u32()?;
    if check1 != check2 {
        return Err(err("invalid OpenSSH private key checkints"));
    }
    let key_type = private.string_utf8()?;
    if key_type != "ssh-ed25519" {
        return Err(err(format!(
            "unsupported OpenSSH private key type: {key_type}"
        )));
    }
    let public = private.string()?;
    if public.len() != 32 {
        return Err(err("invalid OpenSSH ed25519 public key length"));
    }
    let private_key = private.string()?;
    if private_key.len() != 64 {
        return Err(err("invalid OpenSSH ed25519 private key length"));
    }
    if private_key[32..64] != *public {
        return Err(err(
            "OpenSSH ed25519 private key embedded public key mismatch",
        ));
    }
    let seed: [u8; 32] = private_key[..32]
        .try_into()
        .map_err(|_| err("invalid OpenSSH ed25519 private key seed"))?;
    let signing = SigningKey::from_bytes(&seed);
    if signing.verifying_key().to_bytes() != public {
        return Err(err("OpenSSH ed25519 public key does not match private key"));
    }
    Ok(seed)
}

struct BinaryReader<'a> {
    data: &'a [u8],
    offset: usize,
}

impl<'a> BinaryReader<'a> {
    fn new(data: &'a [u8]) -> Self {
        Self { data, offset: 0 }
    }

    fn expect_bytes(&mut self, expected: &[u8]) -> Result<()> {
        let actual = self.take(expected.len())?;
        if actual != expected {
            return Err(err("invalid OpenSSH private key header"));
        }
        Ok(())
    }

    fn u32(&mut self) -> Result<u32> {
        let bytes: [u8; 4] = self
            .take(4)?
            .try_into()
            .map_err(|_| err("invalid OpenSSH private key integer"))?;
        Ok(u32::from_be_bytes(bytes))
    }

    fn string(&mut self) -> Result<&'a [u8]> {
        let len = self.u32()? as usize;
        self.take(len)
    }

    fn string_utf8(&mut self) -> Result<String> {
        String::from_utf8(self.string()?.to_vec())
            .map_err(|e| err(format!("invalid OpenSSH private key string: {e}")))
    }

    fn take(&mut self, len: usize) -> Result<&'a [u8]> {
        let end = self
            .offset
            .checked_add(len)
            .ok_or_else(|| err("OpenSSH private key offset overflow"))?;
        if end > self.data.len() {
            return Err(err("truncated OpenSSH private key"));
        }
        let out = &self.data[self.offset..end];
        self.offset = end;
        Ok(out)
    }
}

#[cfg(test)]
mod tests {
    use super::{private_key_seed_b64, public_key_b64_from_private_key, sign_b64, verify_b64};
    use base64::{engine::general_purpose::STANDARD, Engine};
    use ed25519_dalek::SigningKey;

    #[test]
    fn base64_private_key_public_key_roundtrip() {
        let private_key = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
        let public_key = public_key_b64_from_private_key(private_key).expect("public key");
        let signature = sign_b64(
            &private_key_seed_b64(private_key).expect("seed"),
            b"message",
        )
        .expect("sign");
        verify_b64(&public_key, b"message", &signature).expect("verify");
    }

    #[test]
    fn openssh_ed25519_private_key_roundtrip() {
        let seed = [7u8; 32];
        let pem = openssh_private_key_pem(&seed);
        let public_key = public_key_b64_from_private_key(&pem).expect("public key");
        let signature =
            sign_b64(&private_key_seed_b64(&pem).expect("seed"), b"message").expect("sign");
        verify_b64(&public_key, b"message", &signature).expect("verify");
    }

    fn openssh_private_key_pem(seed: &[u8; 32]) -> String {
        let signing = SigningKey::from_bytes(seed);
        let public = signing.verifying_key().to_bytes();
        let mut private_blob = Vec::new();
        put_u32(&mut private_blob, 0x01020304);
        put_u32(&mut private_blob, 0x01020304);
        put_string(&mut private_blob, b"ssh-ed25519");
        put_string(&mut private_blob, &public);
        let mut private = Vec::new();
        private.extend_from_slice(seed);
        private.extend_from_slice(&public);
        put_string(&mut private_blob, &private);
        put_string(&mut private_blob, b"test-key");
        let pad_len = 8 - (private_blob.len() % 8);
        for i in 1..=pad_len {
            private_blob.push(i as u8);
        }

        let mut public_blob = Vec::new();
        put_string(&mut public_blob, b"ssh-ed25519");
        put_string(&mut public_blob, &public);

        let mut data = Vec::new();
        data.extend_from_slice(b"openssh-key-v1\0");
        put_string(&mut data, b"none");
        put_string(&mut data, b"none");
        put_string(&mut data, b"");
        put_u32(&mut data, 1);
        put_string(&mut data, &public_blob);
        put_string(&mut data, &private_blob);
        format!(
            "-----BEGIN OPENSSH PRIVATE KEY-----\n{}\n-----END OPENSSH PRIVATE KEY-----\n",
            STANDARD.encode(data)
        )
    }

    fn put_u32(out: &mut Vec<u8>, value: u32) {
        out.extend_from_slice(&value.to_be_bytes());
    }

    fn put_string(out: &mut Vec<u8>, value: &[u8]) {
        put_u32(out, value.len() as u32);
        out.extend_from_slice(value);
    }
}
