use crate::manifest::{PatchManifest, ReleaseManifest};
use crate::{err, Error, Result};
use base64::{engine::general_purpose::STANDARD, Engine};
use serde::{Deserialize, Serialize};
use std::fs;
use std::io::Read;
use std::path::Path;
use std::time::Duration;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CreateAppRequest {
    pub id: String,
    pub name: String,
}

#[derive(Debug, Clone, Serialize)]
pub struct CreatePatchRequest<'a> {
    pub manifest: &'a PatchManifest,
    pub payload_b64: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PromotePatchRequest {
    pub app_id: String,
    pub release_version: String,
    pub platform: String,
    pub arch: String,
    pub patch_number: u32,
    pub channel: String,
    pub rollout_percentage: u8,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CheckResponse {
    pub patch_available: bool,
    pub patch: Option<PatchCheck>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PatchCheck {
    pub patch_number: u32,
    pub manifest_url: String,
    pub payload_url: String,
    pub manifest_hash: String,
    pub payload_hash: String,
}

#[derive(Debug, Clone)]
pub struct Client {
    base_url: String,
    agent: ureq::Agent,
}

impl Client {
    pub fn new(base_url: impl Into<String>) -> Self {
        Self {
            base_url: base_url.into().trim_end_matches('/').to_string(),
            agent: ureq::AgentBuilder::new()
                .timeout_connect(Duration::from_secs(5))
                .timeout_read(Duration::from_secs(30))
                .timeout_write(Duration::from_secs(30))
                .build(),
        }
    }

    pub fn create_app(&self, request: &CreateAppRequest) -> Result<()> {
        self.post_json("/v1/apps", request)
    }

    pub fn create_release(&self, manifest: &ReleaseManifest) -> Result<()> {
        self.post_json("/v1/releases", manifest)
    }

    pub fn create_patch(&self, manifest: &PatchManifest, payload: &[u8]) -> Result<()> {
        self.post_json(
            "/v1/patches",
            &CreatePatchRequest {
                manifest,
                payload_b64: STANDARD.encode(payload),
            },
        )
    }

    pub fn promote_patch(&self, request: &PromotePatchRequest) -> Result<()> {
        self.post_json("/v1/patches/promote", request)
    }

    pub fn check(
        &self,
        app_id: &str,
        release_version: &str,
        platform: &str,
        arch: &str,
        channel: &str,
        current_patch_number: u32,
        client_id: &str,
    ) -> Result<CheckResponse> {
        let url = format!("{}/v1/patches/check", self.base_url);
        let current_patch_number = current_patch_number.to_string();
        let response = self
            .agent
            .get(&url)
            .query("app_id", app_id)
            .query("release_version", release_version)
            .query("platform", platform)
            .query("arch", arch)
            .query("channel", channel)
            .query("current_patch_number", &current_patch_number)
            .query("client_id", client_id)
            .call()
            .map_err(Box::new)?;
        Ok(response.into_json()?)
    }

    /// `download_bytes` fetches `http://` and `https://` URLs over HTTP(S) via
    /// `self.agent`; all other values are treated as local filesystem paths and
    /// read with `fs::read`.
    ///
    /// Security assumption: callers must ensure non-HTTP URLs come from a
    /// trusted source, such as a server `CheckResponse`. Validate or sanitize
    /// inputs first if that trust boundary cannot be guaranteed, otherwise a
    /// malicious value could cause unintended local file reads.
    pub fn download_bytes(&self, url: &str) -> Result<Vec<u8>> {
        if url.starts_with("http://") || url.starts_with("https://") {
            let response = self.agent.get(url).call().map_err(Box::new)?;
            return response
                .into_reader()
                .take(64 * 1024 * 1024)
                .bytes()
                .collect::<std::io::Result<Vec<_>>>()
                .map_err(Into::into);
        }
        Ok(fs::read(Path::new(url))?)
    }

    fn post_json<T: Serialize>(&self, path: &str, value: &T) -> Result<()> {
        let url = format!("{}{}", self.base_url, path);
        let response = self
            .agent
            .post(&url)
            .send_json(serde_json::to_value(value)?);
        match response {
            Ok(resp) if (200..300).contains(&resp.status()) => Ok(()),
            Ok(resp) => Err(err(format!("server returned HTTP {}", resp.status()))),
            Err(ureq::Error::Status(code, resp)) => {
                let body = resp.into_string().unwrap_or_default();
                Err(err(format!("server returned HTTP {code}: {body}")))
            }
            Err(e) => Err(Error::Http(Box::new(e))),
        }
    }
}
