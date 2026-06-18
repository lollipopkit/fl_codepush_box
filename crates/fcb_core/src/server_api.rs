use crate::config::RemoteAppConfig;
use crate::manifest::{PatchManifest, ReleaseManifest};
use crate::{err, Error, Result};
use base64::{engine::general_purpose::STANDARD, Engine};
use serde::{Deserialize, Serialize};
use std::fs;
use std::io::Read;
use std::path::Path;
use std::thread;
use std::time::{Duration, SystemTime, UNIX_EPOCH};

const RETRY_DELAYS: [Duration; 4] = [
    Duration::from_millis(50),
    Duration::from_millis(200),
    Duration::from_millis(800),
    Duration::from_millis(3200),
];

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

#[derive(Debug, Clone)]
pub struct CheckRequest<'a> {
    pub org_id: Option<&'a str>,
    pub app_id: &'a str,
    pub release_version: &'a str,
    pub platform: &'a str,
    pub arch: &'a str,
    pub channel: &'a str,
    pub current_patch_number: u32,
    pub client_id: &'a str,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct EventRequest {
    #[serde(skip_serializing_if = "Option::is_none")]
    pub org_id: Option<String>,
    pub app_id: String,
    pub release_version: String,
    pub platform: String,
    pub arch: String,
    pub patch_number: Option<u32>,
    pub event_type: String,
    pub client_id_hash: Option<String>,
    pub payload: serde_json::Value,
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

    pub fn post_event(&self, request: &EventRequest) -> Result<()> {
        self.post_json("/v1/events", request)
    }

    pub fn check(&self, request: &CheckRequest<'_>) -> Result<CheckResponse> {
        let url = format!("{}/v1/patches/check", self.base_url);
        let current_patch_number = request.current_patch_number.to_string();
        let mut last_error = None;
        for attempt in 0..=RETRY_DELAYS.len() {
            let mut http_request = self
                .agent
                .get(&url)
                .query("app_id", request.app_id)
                .query("release_version", request.release_version)
                .query("platform", request.platform)
                .query("arch", request.arch)
                .query("channel", request.channel)
                .query("current_patch_number", &current_patch_number)
                .query("client_id", request.client_id);
            if let Some(org_id) = request.org_id {
                if !org_id.trim().is_empty() {
                    http_request = http_request.query("org_id", org_id);
                }
            }
            let response = http_request.call();
            match response {
                Ok(resp) if resp.status().is_success() => {
                    return Ok(resp.into_body().read_json().map_err(Box::new)?);
                }
                Ok(mut resp)
                    if should_retry_status(resp.status().as_u16()) && can_retry(attempt) =>
                {
                    let _ = resp.body_mut().read_to_string();
                    sleep_before_retry(attempt);
                }
                Ok(mut resp) => {
                    let code = resp.status().as_u16();
                    let body = resp.body_mut().read_to_string().unwrap_or_default();
                    return Err(err(format!("server returned HTTP {code}: {body}")));
                }
                Err(e) if can_retry(attempt) => {
                    last_error = Some(e);
                    sleep_before_retry(attempt);
                }
                Err(e) => return Err(Error::Http(Box::new(e))),
            }
        }
        Err(Error::Http(Box::new(
            last_error.expect("retry loop should retain last error"),
        )))
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
        Ok(self.download_bytes_from(url, 0)?.0)
    }

    /// Like `download_bytes`, but sends a HTTP Range request when `offset > 0`.
    /// The returned boolean is true only when the server responds with 206 and
    /// the returned bytes should be appended to an existing partial file.
    pub fn download_bytes_from(&self, url: &str, offset: u64) -> Result<(Vec<u8>, bool)> {
        self.download_bytes_from_with_cancel(url, offset, || false)
    }

    /// Like `download_bytes_from`, but checks `should_cancel` between body
    /// chunks so callers can abort large in-flight downloads before the full
    /// response body has been read.
    pub fn download_bytes_from_with_cancel<F>(
        &self,
        url: &str,
        offset: u64,
        mut should_cancel: F,
    ) -> Result<(Vec<u8>, bool)>
    where
        F: FnMut() -> bool,
    {
        if url.starts_with("http://") || url.starts_with("https://") {
            let mut last_error = None;
            // Reset to a full download when a resume offset turns out to be
            // unusable (e.g. the partial is already full-length but corrupt, so
            // the server answers `Range:` with 416). Without this, the client
            // would resend the same out-of-range request forever and stay stuck.
            let mut effective_offset = offset;
            for attempt in 0..=RETRY_DELAYS.len() {
                if should_cancel() {
                    return Err(err("operation cancelled"));
                }
                let mut request = self.agent.get(url);
                if effective_offset > 0 {
                    request = request.header("Range", &format!("bytes={effective_offset}-"));
                }
                let response = request.call();
                match response {
                    Ok(mut resp) if resp.status().as_u16() == 416 && effective_offset > 0 => {
                        let _ = resp.body_mut().read_to_string();
                        effective_offset = 0;
                    }
                    Ok(resp) if resp.status().as_u16() == 206 => {
                        let bytes = read_body_with_cancel(
                            resp.into_body().into_reader(),
                            &mut should_cancel,
                        )?;
                        return Ok((bytes, true));
                    }
                    Ok(resp) if resp.status().is_success() => {
                        let bytes = read_body_with_cancel(
                            resp.into_body().into_reader(),
                            &mut should_cancel,
                        )?;
                        return Ok((bytes, false));
                    }
                    Ok(mut resp)
                        if should_retry_status(resp.status().as_u16()) && can_retry(attempt) =>
                    {
                        let _ = resp.body_mut().read_to_string();
                        sleep_before_retry(attempt);
                    }
                    Ok(mut resp) => {
                        let code = resp.status().as_u16();
                        let body = resp.body_mut().read_to_string().unwrap_or_default();
                        return Err(err(format!("server returned HTTP {code}: {body}")));
                    }
                    Err(e) if can_retry(attempt) => {
                        last_error = Some(e);
                        sleep_before_retry(attempt);
                    }
                    Err(e) => return Err(Error::Http(Box::new(e))),
                }
            }
            return Err(Error::Http(Box::new(
                last_error.expect("retry loop should retain last error"),
            )));
        }
        if should_cancel() {
            return Err(err("operation cancelled"));
        }
        Ok((fs::read(Path::new(url))?, false))
    }

    fn post_json<T: Serialize>(&self, path: &str, value: &T) -> Result<()> {
        let url = format!("{}{}", self.base_url, path);
        let json = serde_json::to_value(value)?;
        let mut last_error = None;
        for attempt in 0..=RETRY_DELAYS.len() {
            let request = self.agent.post(&url);
            let request = if let Some(token) = &self.token {
                request.header("Authorization", &format!("Bearer {token}"))
            } else {
                request
            };
            let response = request.send_json(json.clone());
            match response {
                Ok(resp) if resp.status().is_success() => return Ok(()),
                Ok(mut resp)
                    if should_retry_status(resp.status().as_u16()) && can_retry(attempt) =>
                {
                    let _ = resp.body_mut().read_to_string();
                    sleep_before_retry(attempt);
                }
                Ok(mut resp) => {
                    let code = resp.status().as_u16();
                    let body = resp.body_mut().read_to_string().unwrap_or_default();
                    return Err(err(format!("server returned HTTP {code}: {body}")));
                }
                Err(e) if can_retry(attempt) => {
                    last_error = Some(e);
                    sleep_before_retry(attempt);
                }
                Err(e) => return Err(Error::Http(Box::new(e))),
            }
        }
        Err(Error::Http(Box::new(
            last_error.expect("retry loop should retain last error"),
        )))
    }

    fn get_json<T: for<'de> Deserialize<'de>>(&self, path: &str) -> Result<T> {
        let url = format!("{}{}", self.base_url, path);
        let mut last_error = None;
        for attempt in 0..=RETRY_DELAYS.len() {
            let request = self.agent.get(&url);
            let request = if let Some(token) = &self.token {
                request.header("Authorization", &format!("Bearer {token}"))
            } else {
                request
            };
            let response = request.call();
            match response {
                Ok(resp) if resp.status().is_success() => {
                    return Ok(resp.into_body().read_json().map_err(Box::new)?);
                }
                Ok(mut resp)
                    if should_retry_status(resp.status().as_u16()) && can_retry(attempt) =>
                {
                    let _ = resp.body_mut().read_to_string();
                    sleep_before_retry(attempt);
                }
                Ok(mut resp) => {
                    let code = resp.status().as_u16();
                    let body = resp.body_mut().read_to_string().unwrap_or_default();
                    return Err(err(format!("server returned HTTP {code}: {body}")));
                }
                Err(e) if can_retry(attempt) => {
                    last_error = Some(e);
                    sleep_before_retry(attempt);
                }
                Err(e) => return Err(Error::Http(Box::new(e))),
            }
        }
        Err(Error::Http(Box::new(
            last_error.expect("retry loop should retain last error"),
        )))
    }
}

fn can_retry(attempt: usize) -> bool {
    attempt < RETRY_DELAYS.len()
}

fn sleep_before_retry(attempt: usize) {
    thread::sleep(retry_delay(attempt));
}

fn retry_delay(attempt: usize) -> Duration {
    let base = RETRY_DELAYS[attempt];
    let base_micros = base.as_micros();
    let jitter_micros = base_micros / 4;
    let span = jitter_micros.saturating_mul(2).saturating_add(1);
    let seed = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap_or_default()
        .as_nanos();
    let offset = seed % span;
    let delay_micros = base_micros
        .saturating_sub(jitter_micros)
        .saturating_add(offset);
    Duration::from_micros(delay_micros as u64)
}

fn should_retry_status(status: u16) -> bool {
    status >= 500
}

fn read_body_with_cancel<R, F>(mut reader: R, should_cancel: &mut F) -> Result<Vec<u8>>
where
    R: Read,
    F: FnMut() -> bool,
{
    const MAX_BODY_BYTES: usize = 64 * 1024 * 1024;
    let mut out = Vec::new();
    let mut buffer = [0_u8; 16 * 1024];
    loop {
        if should_cancel() {
            return Err(err("operation cancelled"));
        }
        let n = reader.read(&mut buffer)?;
        if n == 0 {
            return Ok(out);
        }
        if out.len().saturating_add(n) > MAX_BODY_BYTES {
            return Err(err("response body exceeds 64 MiB limit"));
        }
        out.extend_from_slice(&buffer[..n]);
    }
}

#[cfg(test)]
mod tests {
    use super::{retry_delay, CheckRequest, Client, RETRY_DELAYS};
    use std::io::{Read, Write};
    use std::net::TcpListener;
    use std::sync::atomic::{AtomicBool, AtomicUsize, Ordering};
    use std::sync::mpsc;
    use std::sync::Arc;
    use std::time::{Duration, Instant};

    #[test]
    fn check_retries_5xx_until_success() {
        let listener = TcpListener::bind("127.0.0.1:0").expect("bind server");
        let server_url = format!("http://{}", listener.local_addr().expect("local addr"));
        let server = std::thread::spawn(move || {
            for attempt in 0..3 {
                let (mut stream, _) = listener.accept().expect("accept");
                let mut request = [0_u8; 1024];
                let _ = stream.read(&mut request).expect("read request");
                if attempt < 2 {
                    write_response(&mut stream, 503, b"retry");
                } else {
                    write_response(
                        &mut stream,
                        200,
                        br#"{"patch_available":false,"patch":null}"#,
                    );
                }
            }
        });

        let response = Client::new(server_url)
            .check(&CheckRequest {
                org_id: None,
                app_id: "app",
                release_version: "1.0.0+1",
                platform: "android",
                arch: "arm64-v8a",
                channel: "stable",
                current_patch_number: 0,
                client_id: "client",
            })
            .expect("check should retry");

        assert!(!response.patch_available);
        server.join().expect("server join");
    }

    #[test]
    fn retry_delay_applies_bounded_jitter() {
        for (attempt, base) in RETRY_DELAYS.iter().enumerate() {
            let delay = retry_delay(attempt);
            assert!(delay >= base.mul_f64(0.75), "{delay:?} < 75% of {base:?}");
            assert!(delay <= base.mul_f64(1.25), "{delay:?} > 125% of {base:?}");
        }
    }

    #[test]
    fn check_does_not_retry_4xx() {
        let listener = TcpListener::bind("127.0.0.1:0").expect("bind server");
        listener.set_nonblocking(true).expect("nonblocking");
        let server_url = format!("http://{}", listener.local_addr().expect("local addr"));
        let request_count = Arc::new(AtomicUsize::new(0));
        let request_count_for_thread = Arc::clone(&request_count);
        let server = std::thread::spawn(move || {
            let deadline = Instant::now() + Duration::from_millis(300);
            while Instant::now() < deadline {
                match listener.accept() {
                    Ok((mut stream, _)) => {
                        request_count_for_thread.fetch_add(1, Ordering::SeqCst);
                        let mut request = [0_u8; 1024];
                        let _ = stream.read(&mut request).expect("read request");
                        write_response(&mut stream, 400, b"bad request");
                    }
                    Err(e) if e.kind() == std::io::ErrorKind::WouldBlock => {
                        std::thread::sleep(Duration::from_millis(10));
                    }
                    Err(e) => panic!("accept failed: {e}"),
                }
            }
        });

        let err = Client::new(server_url)
            .check(&CheckRequest {
                org_id: None,
                app_id: "app",
                release_version: "1.0.0+1",
                platform: "android",
                arch: "arm64-v8a",
                channel: "stable",
                current_patch_number: 0,
                client_id: "client",
            })
            .expect_err("4xx should fail without retry");

        assert!(err.to_string().contains("HTTP 400"));
        server.join().expect("server join");
        assert_eq!(request_count.load(Ordering::SeqCst), 1);
    }

    #[test]
    fn download_bytes_from_uses_http_range() {
        let listener = TcpListener::bind("127.0.0.1:0").expect("bind server");
        let server_url = format!("http://{}", listener.local_addr().expect("local addr"));
        let server = std::thread::spawn(move || {
            let (mut stream, _) = listener.accept().expect("accept");
            let mut request = [0_u8; 1024];
            let n = stream.read(&mut request).expect("read request");
            let request = String::from_utf8_lossy(&request[..n]);
            assert!(
                request.to_ascii_lowercase().contains("range: bytes=3-"),
                "{request}"
            );
            write_partial_response(&mut stream, b"lo");
        });

        let (bytes, append) = Client::new(&server_url)
            .download_bytes_from(&format!("{server_url}/payload"), 3)
            .expect("range download");

        assert_eq!(bytes, b"lo");
        assert!(append);
        server.join().expect("server join");
    }

    #[test]
    fn download_resume_falls_back_to_full_on_416() {
        let listener = TcpListener::bind("127.0.0.1:0").expect("bind server");
        let server_url = format!("http://{}", listener.local_addr().expect("local addr"));
        let server = std::thread::spawn(move || {
            // First request carries the stale resume offset and is answered with
            // 416; the client must retry without a Range header and get the full
            // body instead of getting stuck resending the same request.
            let (mut stream, _) = listener.accept().expect("accept range");
            let mut request = [0_u8; 1024];
            let n = stream.read(&mut request).expect("read request");
            assert!(
                String::from_utf8_lossy(&request[..n])
                    .to_ascii_lowercase()
                    .contains("range: bytes=9-"),
                "first request should carry resume offset"
            );
            write_response(&mut stream, 416, b"range not satisfiable");

            let (mut stream, _) = listener.accept().expect("accept full");
            let mut request = [0_u8; 1024];
            let n = stream.read(&mut request).expect("read request");
            assert!(
                !String::from_utf8_lossy(&request[..n])
                    .to_ascii_lowercase()
                    .contains("range:"),
                "fallback request should omit Range header"
            );
            write_response(&mut stream, 200, b"full-body");
        });

        let (bytes, append) = Client::new(&server_url)
            .download_bytes_from(&format!("{server_url}/payload"), 9)
            .expect("416 should fall back to full download");

        assert_eq!(bytes, b"full-body");
        assert!(
            !append,
            "full re-download must signal overwrite, not append"
        );
        server.join().expect("server join");
    }

    #[test]
    fn check_includes_org_id_when_configured() {
        let listener = TcpListener::bind("127.0.0.1:0").expect("bind server");
        let server_url = format!("http://{}", listener.local_addr().expect("local addr"));
        let server = std::thread::spawn(move || {
            let (mut stream, _) = listener.accept().expect("accept");
            let mut request = [0_u8; 2048];
            let n = stream.read(&mut request).expect("read request");
            let request = String::from_utf8_lossy(&request[..n]);
            assert!(request.contains("org_id=acme"), "{request}");
            write_response(
                &mut stream,
                200,
                br#"{"patch_available":false,"patch":null}"#,
            );
        });

        let response = Client::new(&server_url)
            .check(&CheckRequest {
                org_id: Some("acme"),
                app_id: "app",
                release_version: "1.0.0+1",
                platform: "android",
                arch: "arm64-v8a",
                channel: "stable",
                current_patch_number: 0,
                client_id: "client",
            })
            .expect("check");

        assert!(!response.patch_available);
        server.join().expect("server join");
    }

    #[test]
    fn download_bytes_from_with_cancel_aborts_mid_body() {
        let listener = TcpListener::bind("127.0.0.1:0").expect("bind server");
        let server_url = format!("http://{}", listener.local_addr().expect("local addr"));
        let (first_chunk_tx, first_chunk_rx) = mpsc::channel();
        let (finish_tx, finish_rx) = mpsc::channel();
        let server = std::thread::spawn(move || {
            let (mut stream, _) = listener.accept().expect("accept");
            let mut request = [0_u8; 1024];
            let _ = stream.read(&mut request).expect("read request");
            write!(
                stream,
                "HTTP/1.1 200 OK\r\nContent-Length: 10\r\nConnection: close\r\n\r\n"
            )
            .expect("write headers");
            stream.write_all(b"hello").expect("write first chunk");
            stream.flush().expect("flush first chunk");
            first_chunk_tx.send(()).expect("send first chunk");
            finish_rx.recv().expect("finish response");
            let _ = stream.write_all(b"world");
        });

        let cancelled = Arc::new(AtomicBool::new(false));
        let cancelled_for_worker = Arc::clone(&cancelled);
        let worker = std::thread::spawn(move || {
            Client::new(&server_url).download_bytes_from_with_cancel(
                &format!("{server_url}/payload"),
                0,
                || cancelled_for_worker.load(Ordering::SeqCst),
            )
        });

        first_chunk_rx
            .recv_timeout(Duration::from_secs(2))
            .expect("first chunk");
        cancelled.store(true, Ordering::SeqCst);
        let err = worker
            .join()
            .expect("worker join")
            .expect_err("download should be cancelled before the second chunk");
        assert!(err.to_string().contains("operation cancelled"), "{err}");
        finish_tx.send(()).expect("finish response");
        server.join().expect("server join");
    }

    fn write_response(stream: &mut std::net::TcpStream, status: u16, body: &[u8]) {
        let reason = if status == 200 {
            "OK"
        } else {
            "Service Unavailable"
        };
        write!(
            stream,
            "HTTP/1.1 {status} {reason}\r\nContent-Length: {}\r\nConnection: close\r\n\r\n",
            body.len()
        )
        .expect("write headers");
        stream.write_all(body).expect("write body");
    }

    fn write_partial_response(stream: &mut std::net::TcpStream, body: &[u8]) {
        write!(
            stream,
            "HTTP/1.1 206 Partial Content\r\nContent-Length: {}\r\nConnection: close\r\n\r\n",
            body.len()
        )
        .expect("write headers");
        stream.write_all(body).expect("write body");
    }
}
