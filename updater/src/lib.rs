use fcb_core::server_api::{CheckResponse, Client, PatchCheck};
use fcb_core::state::Updater;
use fcb_core::{crypto, err, Error, Result};
use std::ffi::{CStr, CString};
use std::fs;
use std::io::Write;
use std::os::raw::{c_char, c_int};
use std::panic::{catch_unwind, AssertUnwindSafe};
use std::path::{Path, PathBuf};
use std::sync::{Mutex, MutexGuard, OnceLock};

#[repr(C)]
pub struct FcbInitParams {
    app_id: *const c_char,
    channel: *const c_char,
    release_version: *const c_char,
    platform: *const c_char,
    arch: *const c_char,
    cache_dir: *const c_char,
    public_key_pem: *const c_char,
    check_on_startup: c_int,
}

#[repr(C)]
pub struct FcbLaunchPatch {
    has_patch: c_int,
    patch_number: c_int,
    backend: *const c_char,
    artifact_path: *const c_char,
    bytecode_path: *const c_char,
    manifest_path: *const c_char,
}

struct Runtime {
    app_id: String,
    channel: String,
    release_version: String,
    platform: String,
    arch: String,
    cache_dir: PathBuf,
    public_key_b64: String,
    server_url: String,
    client_id: String,
    baseline_artifact_path: Option<PathBuf>,
    last_check: Option<CheckResponse>,
    last_error: CString,
    strings: Vec<CString>,
}

impl Runtime {
    fn new() -> Self {
        Self {
            app_id: String::new(),
            channel: "stable".to_string(),
            release_version: String::new(),
            platform: "android".to_string(),
            arch: "arm64-v8a".to_string(),
            cache_dir: PathBuf::from(".fcb/cache"),
            public_key_b64: String::new(),
            server_url: String::new(),
            client_id: "default".to_string(),
            baseline_artifact_path: None,
            last_check: None,
            last_error: CString::new("").unwrap(),
            strings: Vec::new(),
        }
    }

    fn set_error(&mut self, message: impl Into<String>) -> c_int {
        self.last_error =
            CString::new(message.into()).unwrap_or_else(|_| CString::new("invalid error").unwrap());
        -1
    }

    fn keep(&mut self, value: String) -> *const c_char {
        let c = CString::new(value).unwrap_or_else(|_| CString::new("").unwrap());
        let ptr = c.as_ptr();
        self.strings.push(c);
        ptr
    }
}

static RUNTIME: OnceLock<Mutex<Runtime>> = OnceLock::new();

#[no_mangle]
pub extern "C" fn fcb_init(params: *const FcbInitParams) -> c_int {
    ffi_guard(-1, |runtime| {
        if params.is_null() {
            return runtime.set_error("params is null");
        }
        // SAFETY: params is checked for null above and is only read for this call.
        let params = unsafe { &*params };
        match read_cstr(params.cache_dir) {
            Ok(cache_dir) if !cache_dir.is_empty() => {
                runtime.cache_dir = PathBuf::from(cache_dir);
            }
            Ok(_) => {}
            Err(e) => return runtime.set_error(e),
        }
        match read_cstr(params.app_id) {
            Ok(value) if !value.is_empty() => runtime.app_id = value,
            Ok(_) => {}
            Err(e) => return runtime.set_error(e),
        }
        match read_cstr(params.channel) {
            Ok(value) if !value.is_empty() => runtime.channel = value,
            Ok(_) => {}
            Err(e) => return runtime.set_error(e),
        }
        match read_cstr(params.release_version) {
            Ok(value) if !value.is_empty() => runtime.release_version = value,
            Ok(_) => {}
            Err(e) => return runtime.set_error(e),
        }
        match read_cstr(params.platform) {
            Ok(value) if !value.is_empty() => runtime.platform = value,
            Ok(_) => {}
            Err(e) => return runtime.set_error(e),
        }
        match read_cstr(params.arch) {
            Ok(value) if !value.is_empty() => runtime.arch = value,
            Ok(_) => {}
            Err(e) => return runtime.set_error(e),
        }
        match read_cstr(params.public_key_pem) {
            Ok(value) if !value.is_empty() => runtime.public_key_b64 = value,
            Ok(_) => {}
            Err(e) => return runtime.set_error(e),
        }
        0
    })
}

#[no_mangle]
pub extern "C" fn fcb_set_server_url(server_url: *const c_char) -> c_int {
    ffi_guard(-1, |runtime| match read_cstr(server_url) {
        Ok(value) if !value.is_empty() => {
            runtime.server_url = value;
            0
        }
        Ok(_) => runtime.set_error("server_url is empty"),
        Err(e) => runtime.set_error(e),
    })
}

#[no_mangle]
pub extern "C" fn fcb_set_client_id(client_id: *const c_char) -> c_int {
    ffi_guard(-1, |runtime| match read_cstr(client_id) {
        Ok(value) if !value.is_empty() => {
            runtime.client_id = value;
            0
        }
        Ok(_) => runtime.set_error("client_id is empty"),
        Err(e) => runtime.set_error(e),
    })
}

#[no_mangle]
pub extern "C" fn fcb_set_baseline_artifact_path(path: *const c_char) -> c_int {
    ffi_guard(-1, |runtime| match read_cstr(path) {
        Ok(value) if !value.is_empty() => {
            runtime.baseline_artifact_path = Some(PathBuf::from(value));
            0
        }
        Ok(_) => {
            runtime.baseline_artifact_path = None;
            0
        }
        Err(e) => runtime.set_error(e),
    })
}

#[no_mangle]
pub extern "C" fn fcb_get_launch_patch(out_patch: *mut FcbLaunchPatch) -> c_int {
    ffi_guard(-1, |runtime| {
        if out_patch.is_null() {
            return runtime.set_error("out_patch is null");
        }
        match Updater::new(runtime.cache_dir.clone()).launch_patch() {
            Ok(Some(patch)) => {
                if patch.patch_number > c_int::MAX as u32 {
                    return runtime.set_error("patch number exceeds c_int range");
                }
                let artifact_path = patch
                    .artifact_path
                    .as_ref()
                    .map(|path| runtime.cache_dir.join(path).to_string_lossy().to_string());
                let bytecode_path = if artifact_path.is_none() {
                    Some(
                        runtime
                            .cache_dir
                            .join(&patch.payload_path)
                            .to_string_lossy()
                            .to_string(),
                    )
                } else {
                    None
                };
                // SAFETY: out_patch is checked for null above and points to caller-owned writable memory.
                unsafe {
                    (*out_patch).has_patch = 1;
                    (*out_patch).patch_number = patch.patch_number as c_int;
                    (*out_patch).backend = runtime.keep(patch.backend);
                    (*out_patch).artifact_path = artifact_path
                        .map(|path| runtime.keep(path))
                        .unwrap_or(std::ptr::null());
                    (*out_patch).bytecode_path = bytecode_path
                        .map(|path| runtime.keep(path))
                        .unwrap_or(std::ptr::null());
                    (*out_patch).manifest_path = runtime.keep(
                        runtime
                            .cache_dir
                            .join(patch.manifest_path)
                            .to_string_lossy()
                            .to_string(),
                    );
                }
                0
            }
            Ok(None) => {
                // SAFETY: out_patch is checked for null above and points to caller-owned writable memory.
                unsafe {
                    (*out_patch).has_patch = 0;
                    (*out_patch).patch_number = 0;
                    (*out_patch).backend = std::ptr::null();
                    (*out_patch).artifact_path = std::ptr::null();
                    (*out_patch).bytecode_path = std::ptr::null();
                    (*out_patch).manifest_path = std::ptr::null();
                }
                0
            }
            Err(e) => runtime.set_error(e.to_string()),
        }
    })
}

#[no_mangle]
pub extern "C" fn fcb_check_for_update_async() -> c_int {
    ffi_guard(-1, |runtime| match check_for_update(runtime) {
        Ok(response) => {
            let available = response.patch_available;
            runtime.last_check = Some(response);
            if available {
                1
            } else {
                0
            }
        }
        Err(e) => runtime.set_error(e.to_string()),
    })
}

#[no_mangle]
pub extern "C" fn fcb_download_and_install_blocking() -> c_int {
    ffi_guard(-1, |runtime| match download_and_install(runtime) {
        Ok(true) => 1,
        Ok(false) => 0,
        Err(e) => runtime.set_error(e.to_string()),
    })
}

#[no_mangle]
pub extern "C" fn fcb_is_new_patch_ready_to_install() -> c_int {
    ffi_guard(-1, |runtime| {
        match Updater::new(runtime.cache_dir.clone()).ready_patch() {
            Ok(Some(_)) => 1,
            Ok(None) => 0,
            Err(e) => runtime.set_error(e.to_string()),
        }
    })
}

#[no_mangle]
pub extern "C" fn fcb_last_check_patch_number() -> c_int {
    ffi_guard(-1, |runtime| {
        let Some(response) = &runtime.last_check else {
            return 0;
        };
        let Some(patch) = &response.patch else {
            return 0;
        };
        if patch.patch_number > c_int::MAX as u32 {
            return runtime.set_error("last check patch_number exceeds c_int range");
        }
        patch.patch_number as c_int
    })
}

#[no_mangle]
pub extern "C" fn fcb_mark_launch_success() -> c_int {
    ffi_guard(-1, |runtime| {
        match Updater::new(runtime.cache_dir.clone()).mark_success() {
            Ok(()) => 0,
            Err(e) => runtime.set_error(e.to_string()),
        }
    })
}

#[no_mangle]
pub extern "C" fn fcb_mark_launch_failure(patch_number: c_int, reason: *const c_char) -> c_int {
    ffi_guard(-1, |runtime| {
        if patch_number < 0 {
            return runtime.set_error("patch_number must be non-negative");
        }
        let reason = read_cstr(reason).unwrap_or_else(|_| "unknown".to_string());
        match Updater::new(runtime.cache_dir.clone()).mark_failure(patch_number as u32, &reason) {
            Ok(()) => 0,
            Err(e) => runtime.set_error(e.to_string()),
        }
    })
}

#[no_mangle]
pub extern "C" fn fcb_current_patch_number() -> c_int {
    ffi_guard(-1, |runtime| {
        match Updater::new(runtime.cache_dir.clone()).load_state() {
            Ok(state) if state.current_patch_number <= c_int::MAX as u32 => {
                state.current_patch_number as c_int
            }
            Ok(_) => runtime.set_error("current_patch_number exceeds c_int range"),
            Err(e) => runtime.set_error(e.to_string()),
        }
    })
}

#[no_mangle]
pub extern "C" fn fcb_last_error() -> *const c_char {
    match catch_unwind(AssertUnwindSafe(|| {
        let runtime = RUNTIME.get_or_init(|| Mutex::new(Runtime::new()));
        lock_runtime(runtime).last_error.as_ptr()
    })) {
        Ok(ptr) => ptr,
        Err(_) => c"panic across FFI boundary".as_ptr(),
    }
}

fn read_cstr(ptr: *const c_char) -> std::result::Result<String, String> {
    if ptr.is_null() {
        return Ok(String::new());
    }
    // SAFETY: caller must pass a valid NUL-terminated C string pointer or null.
    unsafe { CStr::from_ptr(ptr) }
        .to_str()
        .map(|s| s.to_string())
        .map_err(|e| e.to_string())
}

fn ffi_guard(default: c_int, f: impl FnOnce(&mut Runtime) -> c_int) -> c_int {
    match catch_unwind(AssertUnwindSafe(|| {
        let runtime = RUNTIME.get_or_init(|| Mutex::new(Runtime::new()));
        let mut runtime = lock_runtime(runtime);
        f(&mut runtime)
    })) {
        Ok(result) => result,
        Err(_) => {
            let runtime = RUNTIME.get_or_init(|| Mutex::new(Runtime::new()));
            let mut runtime = lock_runtime(runtime);
            runtime.set_error("panic across FFI boundary");
            default
        }
    }
}

fn lock_runtime(runtime: &Mutex<Runtime>) -> MutexGuard<'_, Runtime> {
    match runtime.lock() {
        Ok(guard) => guard,
        Err(poisoned) => poisoned.into_inner(),
    }
}

fn check_for_update(runtime: &Runtime) -> Result<CheckResponse> {
    ensure_configured(runtime)?;
    let current_patch_number = Updater::new(runtime.cache_dir.clone())
        .load_state()?
        .current_patch_number;
    Client::new(&runtime.server_url).check(
        &runtime.app_id,
        &runtime.release_version,
        &runtime.platform,
        &runtime.arch,
        &runtime.channel,
        current_patch_number,
        &runtime.client_id,
    )
}

fn download_and_install(runtime: &mut Runtime) -> Result<bool> {
    ensure_configured(runtime)?;
    if runtime.public_key_b64.is_empty() {
        return Err(err("public_key_pem is empty"));
    }
    let response = match &runtime.last_check {
        Some(response) => response.clone(),
        None => check_for_update(runtime)?,
    };
    let Some(patch) = response.patch else {
        if response.patch_available {
            return Err(err(
                "server response marked patch_available but omitted patch",
            ));
        }
        return Ok(false);
    };
    let (manifest_path, payload_path) = download_patch_files(runtime, &patch)?;
    let baseline = runtime.baseline_artifact_path.as_deref();
    Updater::new(runtime.cache_dir.clone()).install_payload_with_baseline(
        &manifest_path,
        &payload_path,
        &runtime.public_key_b64,
        baseline,
    )?;
    Ok(true)
}

fn ensure_configured(runtime: &Runtime) -> Result<()> {
    if runtime.server_url.is_empty() {
        return Err(err("server_url is not configured"));
    }
    if runtime.app_id.is_empty() {
        return Err(err("app_id is empty"));
    }
    if runtime.release_version.is_empty() {
        return Err(err("release_version is empty"));
    }
    Ok(())
}

fn download_patch_files(runtime: &Runtime, patch: &PatchCheck) -> Result<(PathBuf, PathBuf)> {
    let out = runtime
        .cache_dir
        .join("downloads")
        .join(runtime.release_version.as_str())
        .join(patch.patch_number.to_string())
        .join(runtime.platform.as_str())
        .join(runtime.arch.as_str());
    fs::create_dir_all(&out)?;
    let client = Client::new(&runtime.server_url);

    let manifest_bytes = client.download_bytes(&patch.manifest_url)?;
    ensure_hash("manifest", &manifest_bytes, &patch.manifest_hash)?;
    let manifest_path = out.join("patch_manifest.json");
    write_file(&manifest_path, &manifest_bytes)?;

    let payload_bytes = client.download_bytes(&patch.payload_url)?;
    ensure_hash("payload", &payload_bytes, &patch.payload_hash)?;
    let payload_path = out.join("payload.bin");
    write_file(&payload_path, &payload_bytes)?;

    Ok((manifest_path, payload_path))
}

fn ensure_hash(label: &str, bytes: &[u8], expected: &str) -> Result<()> {
    let actual = crypto::sha256_hex(bytes);
    if actual != expected {
        return Err(Error::Message(format!(
            "{label} sha256 mismatch: expected {expected}, got {actual}"
        )));
    }
    Ok(())
}

fn write_file(path: &Path, bytes: &[u8]) -> Result<()> {
    if let Some(parent) = path.parent() {
        fs::create_dir_all(parent)?;
    }
    let mut file = fs::File::create(path)?;
    file.write_all(bytes)?;
    file.sync_all()?;
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::{
        fcb_check_for_update_async, fcb_download_and_install_blocking, fcb_get_launch_patch,
        fcb_init, fcb_is_new_patch_ready_to_install, fcb_last_check_patch_number,
        fcb_set_server_url, FcbInitParams, FcbLaunchPatch,
    };
    use fcb_core::crypto;
    use fcb_core::manifest::{self, PatchManifest, PatchPolicy, PatchSignature, PayloadManifest};
    use fcb_core::state::{InstalledPatch, State, Updater};
    use std::ffi::{CStr, CString};
    use std::io::{Read, Write};
    use std::net::TcpListener;
    use std::sync::Mutex;

    static TEST_LOCK: Mutex<()> = Mutex::new(());

    #[test]
    fn get_launch_patch_returns_snapshot_artifact_path() {
        let _guard = TEST_LOCK.lock().expect("test lock");
        let cache_dir = std::env::temp_dir().join(format!(
            "fcb-updater-ffi-test-{}",
            std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH)
                .expect("time")
                .as_nanos()
        ));
        let updater = Updater::new(&cache_dir);
        updater
            .save_state(&State {
                schema_version: 1,
                release_version: "1.0.0+1".to_string(),
                current_patch_number: 0,
                pending_patch_number: Some(3),
                bad_patches: Vec::new(),
                last_launch: None,
                installed: vec![InstalledPatch {
                    patch_number: 3,
                    backend: "snapshot_replace".to_string(),
                    manifest_path: "patches/3/manifest.json".to_string(),
                    payload_path: "patches/3/payload.bin".to_string(),
                    artifact_path: Some("patches/3/libapp.so".to_string()),
                    installed_at: "0".to_string(),
                }],
            })
            .expect("write state");

        let cache_dir_c = CString::new(cache_dir.to_string_lossy().as_bytes()).expect("cache dir");
        let params = FcbInitParams {
            app_id: std::ptr::null(),
            channel: std::ptr::null(),
            release_version: std::ptr::null(),
            platform: std::ptr::null(),
            arch: std::ptr::null(),
            cache_dir: cache_dir_c.as_ptr(),
            public_key_pem: std::ptr::null(),
            check_on_startup: 0,
        };
        assert_eq!(fcb_init(&params), 0);

        let mut patch = FcbLaunchPatch {
            has_patch: 0,
            patch_number: 0,
            backend: std::ptr::null(),
            artifact_path: std::ptr::null(),
            bytecode_path: std::ptr::null(),
            manifest_path: std::ptr::null(),
        };
        assert_eq!(fcb_get_launch_patch(&mut patch), 0);
        assert_eq!(patch.has_patch, 1);
        assert_eq!(patch.patch_number, 3);
        assert!(patch.bytecode_path.is_null());
        assert_eq!(
            unsafe { CStr::from_ptr(patch.artifact_path) }
                .to_string_lossy()
                .as_ref(),
            cache_dir.join("patches/3/libapp.so").to_string_lossy()
        );

        let _ = std::fs::remove_dir_all(cache_dir);
    }

    #[test]
    fn ready_check_does_not_mark_launch_pending() {
        let _guard = TEST_LOCK.lock().expect("test lock");
        let cache_dir = std::env::temp_dir().join(format!(
            "fcb-updater-ready-test-{}",
            std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH)
                .expect("time")
                .as_nanos()
        ));
        let updater = Updater::new(&cache_dir);
        updater
            .save_state(&State {
                schema_version: 1,
                release_version: "1.0.0+1".to_string(),
                current_patch_number: 0,
                pending_patch_number: Some(4),
                bad_patches: Vec::new(),
                last_launch: None,
                installed: vec![InstalledPatch {
                    patch_number: 4,
                    backend: "snapshot_replace".to_string(),
                    manifest_path: "patches/4/manifest.json".to_string(),
                    payload_path: "patches/4/payload.bin".to_string(),
                    artifact_path: Some("patches/4/libapp.so".to_string()),
                    installed_at: "0".to_string(),
                }],
            })
            .expect("write state");

        let cache_dir_c = CString::new(cache_dir.to_string_lossy().as_bytes()).expect("cache dir");
        let params = FcbInitParams {
            app_id: std::ptr::null(),
            channel: std::ptr::null(),
            release_version: std::ptr::null(),
            platform: std::ptr::null(),
            arch: std::ptr::null(),
            cache_dir: cache_dir_c.as_ptr(),
            public_key_pem: std::ptr::null(),
            check_on_startup: 0,
        };
        assert_eq!(fcb_init(&params), 0);

        assert_eq!(fcb_is_new_patch_ready_to_install(), 1);
        assert!(updater
            .load_state()
            .expect("load state")
            .last_launch
            .is_none());

        let _ = std::fs::remove_dir_all(cache_dir);
    }

    #[test]
    fn check_and_download_install_over_http() {
        let _guard = TEST_LOCK.lock().expect("test lock");
        let cache_dir = std::env::temp_dir().join(format!(
            "fcb-updater-download-test-{}",
            std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH)
                .expect("time")
                .as_nanos()
        ));
        let payload = b"bytecode payload";
        let (private_key, public_key) = crypto::generate_keypair_b64();
        let mut patch = PatchManifest {
            schema_version: 1,
            app_id: "00000000-0000-0000-0000-000000000001".to_string(),
            release_version: "1.0.0+1".to_string(),
            patch_number: 9,
            channel: "stable".to_string(),
            created_at: "1970-01-01T00:00:00Z".to_string(),
            backend: "bytecode".to_string(),
            platform: "android".to_string(),
            arch: "arm64-v8a".to_string(),
            payload: PayloadManifest {
                kind: "opaque_payload".to_string(),
                compression: "none".to_string(),
                hash: crypto::sha256_hex(payload),
                size: payload.len() as u64,
                download_url: "/payload".to_string(),
                diff_algorithm: None,
                base_hash: None,
                output_hash: None,
            },
            policy: PatchPolicy {
                rollout_percentage: 100,
                allow_downgrade: false,
            },
            signature: PatchSignature {
                algorithm: "ed25519".to_string(),
                key_id: "dev".to_string(),
                value: String::new(),
            },
        };
        manifest::sign_patch_manifest(&mut patch, &private_key).expect("sign manifest");
        let manifest_bytes = serde_json::to_vec(&patch).expect("manifest json");
        let manifest_hash = crypto::sha256_hex(&manifest_bytes);
        let payload_hash = crypto::sha256_hex(payload);

        let listener = TcpListener::bind("127.0.0.1:0").expect("bind server");
        let server_url = format!("http://{}", listener.local_addr().expect("local addr"));
        let server_url_for_thread = server_url.clone();
        let server = std::thread::spawn(move || {
            for _ in 0..3 {
                let (mut stream, _) = listener.accept().expect("accept");
                let mut request = [0_u8; 2048];
                let n = stream.read(&mut request).expect("read request");
                let request = String::from_utf8_lossy(&request[..n]);
                let path = request
                    .lines()
                    .next()
                    .and_then(|line| line.split_whitespace().nth(1))
                    .unwrap_or("/");
                if path.starts_with("/v1/patches/check") {
                    let body = serde_json::json!({
                        "patch_available": true,
                            "patch": {
                                "patch_number": 9,
                            "manifest_url": format!("{server_url_for_thread}/manifest"),
                            "payload_url": format!("{server_url_for_thread}/payload"),
                            "manifest_hash": manifest_hash,
                            "payload_hash": payload_hash,
                        }
                    })
                    .to_string();
                    write_response(&mut stream, "application/json", body.as_bytes());
                } else if path == "/manifest" {
                    write_response(&mut stream, "application/json", &manifest_bytes);
                } else if path == "/payload" {
                    write_response(&mut stream, "application/octet-stream", payload);
                } else {
                    write_response(&mut stream, "text/plain", b"not found");
                }
            }
        });

        let cache_dir_c = CString::new(cache_dir.to_string_lossy().as_bytes()).expect("cache dir");
        let app_id_c = CString::new("00000000-0000-0000-0000-000000000001").expect("app id");
        let release_c = CString::new("1.0.0+1").expect("release");
        let channel_c = CString::new("stable").expect("channel");
        let platform_c = CString::new("android").expect("platform");
        let arch_c = CString::new("arm64-v8a").expect("arch");
        let public_key_c = CString::new(public_key).expect("public key");
        let server_url_c = CString::new(server_url).expect("server url");
        let params = FcbInitParams {
            app_id: app_id_c.as_ptr(),
            channel: channel_c.as_ptr(),
            release_version: release_c.as_ptr(),
            platform: platform_c.as_ptr(),
            arch: arch_c.as_ptr(),
            cache_dir: cache_dir_c.as_ptr(),
            public_key_pem: public_key_c.as_ptr(),
            check_on_startup: 0,
        };
        assert_eq!(fcb_init(&params), 0);
        assert_eq!(fcb_set_server_url(server_url_c.as_ptr()), 0);
        assert_eq!(fcb_check_for_update_async(), 1);
        assert_eq!(fcb_last_check_patch_number(), 9);
        assert_eq!(fcb_download_and_install_blocking(), 1);
        assert_eq!(fcb_is_new_patch_ready_to_install(), 1);
        assert_eq!(
            std::fs::read(cache_dir.join("patches/9/payload.bin")).expect("payload"),
            payload
        );

        server.join().expect("server join");
        let _ = std::fs::remove_dir_all(cache_dir);
    }

    fn write_response(stream: &mut std::net::TcpStream, content_type: &str, body: &[u8]) {
        write!(
            stream,
            "HTTP/1.1 200 OK\r\nContent-Type: {content_type}\r\nContent-Length: {}\r\nConnection: close\r\n\r\n",
            body.len()
        )
        .expect("write headers");
        stream.write_all(body).expect("write body");
    }
}
