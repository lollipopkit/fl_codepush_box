use crate::{err, Result};
use base64::{engine::general_purpose::STANDARD, Engine};
use ed25519_dalek::{Signature, Signer, SigningKey, Verifier, VerifyingKey};
use rand::rngs::OsRng;
use sha2::{Digest, Sha256};

pub fn sha256_hex(bytes: &[u8]) -> String {
    hex::encode(Sha256::digest(bytes))
}

pub fn generate_keypair_b64() -> (String, String) {
    let signing = SigningKey::generate(&mut OsRng);
    let verify = signing.verifying_key();
    (STANDARD.encode(signing.to_bytes()), STANDARD.encode(verify.to_bytes()))
}

pub fn sign_b64(private_key_b64: &str, message: &[u8]) -> Result<String> {
    let key_bytes = STANDARD
        .decode(private_key_b64)
        .map_err(|e| err(format!("invalid private key base64: {e}")))?;
    let key: [u8; 32] = key_bytes
        .try_into()
        .map_err(|_| err("ed25519 private key must be 32 bytes"))?;
    let signing = SigningKey::from_bytes(&key);
    Ok(STANDARD.encode(signing.sign(message).to_bytes()))
}

pub fn verify_b64(public_key_b64: &str, message: &[u8], signature_b64: &str) -> Result<()> {
    let key_bytes = STANDARD
        .decode(public_key_b64)
        .map_err(|e| err(format!("invalid public key base64: {e}")))?;
    let key: [u8; 32] = key_bytes
        .try_into()
        .map_err(|_| err("ed25519 public key must be 32 bytes"))?;
    let verifying = VerifyingKey::from_bytes(&key).map_err(|e| err(format!("invalid public key: {e}")))?;
    let sig_bytes = STANDARD
        .decode(signature_b64)
        .map_err(|e| err(format!("invalid signature base64: {e}")))?;
    let signature = Signature::from_slice(&sig_bytes).map_err(|e| err(format!("invalid signature: {e}")))?;
    verifying
        .verify(message, &signature)
        .map_err(|e| err(format!("signature verification failed: {e}")))
}

