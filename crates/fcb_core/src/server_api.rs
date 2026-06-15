use crate::config::RemoteAppConfig;
use crate::manifest::{PatchManifest, ReleaseManifest};
use crate::{err, Error, Result};
use base64::{engine::general_purpose::STANDARD, Engine};
use serde::{Deserialize, Serialize};
use std::fs;
use std::path::Path;
use std::time::Duration;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CreateAppRequest {
    pub id: String,
    pub name: String,
    pub channel: String,
    pub public_key: String,
    pub platforms: Vec<crate::config::RemotePlatformEntry>,
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
    token: Option<String>,
    agent: ureq::Agent,
}

impl Client {
    pub fn new(base_url: impl Into<String>) -> Self {
        Self {
            base_url: base_url.into().trim_end_matches('/').to_string(),
            token: None,
            agent: ureq::Agent::config_builder()
                .timeout_connect(Some(Duration::from_secs(5)))
                .timeout_recv_body(Some(Duration::from_secs(30)))
                .timeout_send_body(Some(Duration::from_secs(30)))
                .http_status_as_error(false)
                .build()
                .into(),
        }
    }

    pub fn with_token(mut self, token: impl Into<String>) -> Self {
        let token = token.into();
        if !token.trim().is_empty() {
            self.token = Some(token);
        }
        self
    }

    pub fn create_app(&self, request: &CreateAppRequest) -> Result<()> {
        self.post_json("/v1/apps", request)
    }

    pub fn get_app(&self, app_id: &str) -> Result<RemoteAppConfig> {
        self.get_json(&format!("/v1/apps/{}", Self::path_segment_encode(app_id)))
    }

    pub fn resolve_app(&self, selector: &str) -> Result<RemoteAppConfig> {
        let url = format!("{}/v1/apps/resolve", self.base_url);
        let request = self.agent.get(&url).query("app", selector);
        let request = if let Some(token) = &self.token {
            request.header("Authorization", &format!("Bearer {token}"))
        } else {
            request
        };
        let response = request.call();
        match response {
            Ok(resp) if resp.status().is_success() => {
                Ok(resp.into_body().read_json().map_err(Box::new)?)
            }
            Ok(mut resp) => {
                let code = resp.status().as_u16();
                let body = resp.body_mut().read_to_string().unwrap_or_default();
                Err(err(format!("server returned HTTP {code}: {body}")))
            }
            Err(e) => Err(Error::Http(Box::new(e))),
        }
    }

    fn path_segment_encode(value: &str) -> String {
        let mut out = String::new();
        for byte in value.bytes() {
            if byte.is_ascii_alphanumeric() || matches!(byte, b'-' | b'.' | b'_' | b'~') {
                out.push(byte as char);
            } else {
                out.push_str(&format!("%{byte:02X}"));
            }
        }
        out
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

    pub fn rollback_patch(&self, request: &PromotePatchRequest) -> Result<()> {
        self.post_json("/v1/patches/rollback", request)
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
        Ok(response.into_body().read_json().map_err(Box::new)?)
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
                .into_body()
                .into_with_config()
                .limit(64 * 1024 * 1024)
                .read_to_vec()
                .map_err(|e| Error::Http(Box::new(e)));
        }
        Ok(fs::read(Path::new(url))?)
    }

    fn post_json<T: Serialize>(&self, path: &str, value: &T) -> Result<()> {
        let url = format!("{}{}", self.base_url, path);
        let request = self.agent.post(&url);
        let request = if let Some(token) = &self.token {
            request.header("Authorization", &format!("Bearer {token}"))
        } else {
            request
        };
        let response = request.send_json(serde_json::to_value(value)?);
        match response {
            Ok(resp) if resp.status().is_success() => Ok(()),
            Ok(mut resp) => {
                let code = resp.status().as_u16();
                let body = resp.body_mut().read_to_string().unwrap_or_default();
                Err(err(format!("server returned HTTP {code}: {body}")))
            }
            Err(e) => Err(Error::Http(Box::new(e))),
        }
    }

    fn get_json<T: for<'de> Deserialize<'de>>(&self, path: &str) -> Result<T> {
        let url = format!("{}{}", self.base_url, path);
        let request = self.agent.get(&url);
        let request = if let Some(token) = &self.token {
            request.header("Authorization", &format!("Bearer {token}"))
        } else {
            request
        };
        let response = request.call();
        match response {
            Ok(resp) if resp.status().is_success() => {
                Ok(resp.into_body().read_json().map_err(Box::new)?)
            }
            Ok(mut resp) => {
                let code = resp.status().as_u16();
                let body = resp.body_mut().read_to_string().unwrap_or_default();
                Err(err(format!("server returned HTTP {code}: {body}")))
            }
            Err(e) => Err(Error::Http(Box::new(e))),
        }
    }
}
