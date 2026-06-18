use base64::engine::general_purpose::STANDARD;
use base64::Engine as _;
use fcb_core::server_api::{
    CheckRequest as ServerCheckRequest, CheckResponse, Client, EventRequest, PatchCheck,
};
use fcb_core::state::Updater;
use fcb_core::{crypto, err, Error, Result};
use std::collections::HashMap;
use std::ffi::{CStr, CString};
use std::fs;
use std::io::Write;
use std::os::raw::{c_char, c_int};
use std::panic::{catch_unwind, AssertUnwindSafe};
use std::path::{Path, PathBuf};
use std::sync::atomic::{AtomicBool, AtomicU64, Ordering};
use std::sync::Arc;
use std::sync::{Condvar, Mutex, MutexGuard, OnceLock};

#[repr(C)]
pub struct FcbInitParams {
    pub app_id: *const c_char,
    pub channel: *const c_char,
    pub release_version: *const c_char,
    pub platform: *const c_char,
    pub arch: *const c_char,
    pub cache_dir: *const c_char,
    pub public_key_pem: *const c_char,
    pub check_on_startup: c_int,
}

#[repr(C)]
pub struct FcbLaunchPatch {
    pub has_patch: c_int,
    pub patch_number: c_int,
    pub backend: *const c_char,
    pub artifact_path: *const c_char,
    pub bytecode_path: *const c_char,
    pub manifest_path: *const c_char,
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
    org_id: Option<String>,
    client_id: String,
    baseline_artifact_path: Option<PathBuf>,
    last_check: Option<CheckResponse>,
    last_error: CString,
    strings: Vec<CString>,
}

#[derive(Debug, Default, PartialEq, Eq)]
struct InterpretFailureLocation {
    bytecode_offset: Option<u32>,
    source_location: Option<String>,
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
            org_id: None,
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

fn parse_interpret_failure_location(error: &str) -> InterpretFailureLocation {
    let mut location = InterpretFailureLocation::default();
    let Some(offset_start) = error.find(" at bytecode offset ") else {
        return location;
    };
    let offset_digits = &error[offset_start + " at bytecode offset ".len()..];
    let digit_len = offset_digits
        .bytes()
        .take_while(|byte| byte.is_ascii_digit())
        .count();
    if digit_len > 0 {
        location.bytecode_offset = offset_digits[..digit_len].parse::<u32>().ok();
    }

    let Some(open_paren) = error[offset_start..].find(" (") else {
        return location;
    };
    let suffix_start = offset_start + open_paren + 2;
    let Some(close_paren) = error[suffix_start..].find(')') else {
        return location;
    };
    let suffix = &error[suffix_start..suffix_start + close_paren];
    if let Some(source) = suffix.strip_suffix(" FCB patch") {
        if !source.is_empty() {
            location.source_location = Some(source.to_string());
        }
    }
    location
}

fn source_location_payload_value(location: Option<&String>) -> serde_json::Value {
    location
        .map(|value| serde_json::Value::String(value.clone()))
        .unwrap_or(serde_json::Value::Null)
}

fn runtime_config_path(runtime: &Runtime) -> PathBuf {
    runtime.cache_dir.join("runtime_config.json")
}

fn persist_runtime_config(runtime: &Runtime) -> Result<()> {
    let config = serde_json::json!({
        "app_id": runtime.app_id,
        "channel": runtime.channel,
        "release_version": runtime.release_version,
        "platform": runtime.platform,
        "arch": runtime.arch,
        "server_url": runtime.server_url,
        "org_id": runtime.org_id,
        "client_id": runtime.client_id,
    });
    let path = runtime_config_path(runtime);
    let bytes = serde_json::to_vec_pretty(&config).map_err(|e| err(e.to_string()))?;
    write_file(&path, &bytes)
}

fn hydrate_runtime_config(runtime: &mut Runtime) -> Result<()> {
    let path = runtime_config_path(runtime);
    if !path.exists() {
        return Ok(());
    }
    let config: serde_json::Value =
        serde_json::from_slice(&fs::read(path)?).map_err(|e| err(e.to_string()))?;
    if runtime.app_id.is_empty() {
        if let Some(value) = config.get("app_id").and_then(|v| v.as_str()) {
            runtime.app_id = value.to_string();
        }
    }
    if runtime.release_version.is_empty() {
        if let Some(value) = config.get("release_version").and_then(|v| v.as_str()) {
            runtime.release_version = value.to_string();
        }
    }
    if runtime.server_url.is_empty() {
        if let Some(value) = config.get("server_url").and_then(|v| v.as_str()) {
            runtime.server_url = value.to_string();
        }
    }
    if let Some(value) = config.get("channel").and_then(|v| v.as_str()) {
        if !value.is_empty() {
            runtime.channel = value.to_string();
        }
    }
    if let Some(value) = config.get("platform").and_then(|v| v.as_str()) {
        if !value.is_empty() {
            runtime.platform = value.to_string();
        }
    }
    if let Some(value) = config.get("arch").and_then(|v| v.as_str()) {
        if !value.is_empty() {
            runtime.arch = value.to_string();
        }
    }
    if runtime.org_id.is_none() {
        if let Some(value) = config.get("org_id").and_then(|v| v.as_str()) {
            if !value.trim().is_empty() {
                runtime.org_id = Some(value.to_string());
            }
        }
    }
    if runtime.client_id == "default" {
        if let Some(value) = config.get("client_id").and_then(|v| v.as_str()) {
            if !value.is_empty() {
                runtime.client_id = value.to_string();
            }
        }
    }
    Ok(())
}

#[derive(Clone, Debug, Eq, Hash, PartialEq)]
struct CheckRequest {
    server_url: String,
    org_id: Option<String>,
    app_id: String,
    release_version: String,
    platform: String,
    arch: String,
    channel: String,
    current_patch_number: u32,
    client_id: String,
}

struct CheckFlight {
    result: Mutex<Option<std::result::Result<CheckResponse, String>>>,
    ready: Condvar,
}

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
struct InterpreterStatsSnapshot {
    interpreted: u64,
    aot: u64,
}

impl InterpreterStatsSnapshot {
    fn total(self) -> u64 {
        self.interpreted.saturating_add(self.aot)
    }

    fn ratio(self) -> f64 {
        let total = self.total();
        if total == 0 {
            0.0
        } else {
            self.interpreted as f64 / total as f64
        }
    }
}

static RUNTIME: OnceLock<Mutex<Runtime>> = OnceLock::new();
static CANCEL_PENDING: AtomicBool = AtomicBool::new(false);
static CHECK_FLIGHTS: OnceLock<Mutex<HashMap<CheckRequest, Arc<CheckFlight>>>> = OnceLock::new();
static INTERPRETED_FUNCTION_CALLS: AtomicU64 = AtomicU64::new(0);
static AOT_FUNCTION_CALLS: AtomicU64 = AtomicU64::new(0);

#[no_mangle]
/// # Safety
/// `params` must be null or point to a valid `FcbInitParams` whose C string
/// fields are null or valid NUL-terminated strings for the duration of the call.
pub unsafe extern "C" fn fcb_init(params: *const FcbInitParams) -> c_int {
    ffi_guard(-1, |runtime| {
        if params.is_null() {
            return runtime.set_error("params is null");
        }
        // SAFETY: params is checked for null above and is only read for this call.
        let params = unsafe { &*params };
        runtime.last_check = None;
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
            Ok(value) if !value.is_empty() => match normalize_public_key_b64(&value) {
                Ok(public_key) => runtime.public_key_b64 = public_key,
                Err(e) => return runtime.set_error(e),
            },
            Ok(_) => {}
            Err(e) => return runtime.set_error(e),
        }
        let _ = persist_runtime_config(runtime);
        0
    })
}

#[no_mangle]
/// # Safety
/// `server_url` must be null or a valid NUL-terminated C string for the
/// duration of the call.
pub unsafe extern "C" fn fcb_set_server_url(server_url: *const c_char) -> c_int {
    ffi_guard(-1, |runtime| match read_cstr(server_url) {
        Ok(value) if !value.is_empty() => {
            runtime.server_url = value;
            runtime.last_check = None;
            let _ = persist_runtime_config(runtime);
            0
        }
        Ok(_) => runtime.set_error("server_url is empty"),
        Err(e) => runtime.set_error(e),
    })
}

#[no_mangle]
/// # Safety
/// `org_id` must be null or a valid NUL-terminated C string for the duration
/// of the call. Passing null or an empty string clears the configured org.
pub unsafe extern "C" fn fcb_set_org_id(org_id: *const c_char) -> c_int {
    ffi_guard(-1, |runtime| match read_cstr(org_id) {
        Ok(value) if !value.trim().is_empty() => {
            runtime.org_id = Some(value);
            runtime.last_check = None;
            let _ = persist_runtime_config(runtime);
            0
        }
        Ok(_) => {
            runtime.org_id = None;
            runtime.last_check = None;
            let _ = persist_runtime_config(runtime);
            0
        }
        Err(e) => runtime.set_error(e),
    })
}

#[no_mangle]
/// # Safety
/// `client_id` must be null or a valid NUL-terminated C string for the
/// duration of the call.
pub unsafe extern "C" fn fcb_set_client_id(client_id: *const c_char) -> c_int {
    ffi_guard(-1, |runtime| match read_cstr(client_id) {
        Ok(value) if !value.is_empty() => {
            runtime.client_id = value;
            runtime.last_check = None;
            let _ = persist_runtime_config(runtime);
            0
        }
        Ok(_) => runtime.set_error("client_id is empty"),
        Err(e) => runtime.set_error(e),
    })
}

#[no_mangle]
/// # Safety
/// `path` must be null or a valid NUL-terminated C string for the duration of
/// the call.
pub unsafe extern "C" fn fcb_set_baseline_artifact_path(path: *const c_char) -> c_int {
    ffi_guard(-1, |runtime| match read_cstr(path) {
        Ok(value) if !value.is_empty() => {
            runtime.baseline_artifact_path = Some(PathBuf::from(value));
            runtime.last_check = None;
            0
        }
        Ok(_) => {
            runtime.baseline_artifact_path = None;
            runtime.last_check = None;
            0
        }
        Err(e) => runtime.set_error(e),
    })
}

#[no_mangle]
/// # Safety
/// `out_patch` must be null or point to writable memory for a `FcbLaunchPatch`
/// for the duration of the call.
pub unsafe extern "C" fn fcb_get_launch_patch(out_patch: *mut FcbLaunchPatch) -> c_int {
    ffi_guard(-1, |runtime| {
        if out_patch.is_null() {
            return runtime.set_error("out_patch is null");
        }
        match Updater::new(runtime.cache_dir.clone()).launch_patch() {
            Ok(Some(patch)) => {
                let _ = flush_rollback_events(runtime);
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
                let _ = flush_rollback_events(runtime);
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

/// # Safety
/// This function performs a **blocking** HTTP request to the configured server.
/// Do not call from a UI or main thread that must remain responsive.
#[no_mangle]
pub extern "C" fn fcb_check_for_update_blocking() -> c_int {
    match catch_unwind(AssertUnwindSafe(|| {
        CANCEL_PENDING.store(false, Ordering::SeqCst);
        let request = {
            let runtime = RUNTIME.get_or_init(|| Mutex::new(Runtime::new()));
            let mut runtime = lock_runtime(runtime);
            match check_request_from_runtime(&runtime) {
                Ok(request) => request,
                Err(e) => return runtime.set_error(e.to_string()),
            }
        };
        let response = match check_for_update_singleflight(request) {
            Ok(response) => response,
            Err(e) => {
                let runtime = RUNTIME.get_or_init(|| Mutex::new(Runtime::new()));
                return lock_runtime(runtime).set_error(e.to_string());
            }
        };
        let available = response.patch_available;
        let runtime = RUNTIME.get_or_init(|| Mutex::new(Runtime::new()));
        lock_runtime(runtime).last_check = Some(response);
        if available {
            1
        } else {
            0
        }
    })) {
        Ok(result) => result,
        Err(_) => {
            let runtime = RUNTIME.get_or_init(|| Mutex::new(Runtime::new()));
            let mut runtime = lock_runtime(runtime);
            runtime.set_error("panic across FFI boundary");
            -1
        }
    }
}

#[no_mangle]
pub extern "C" fn fcb_download_and_install_blocking() -> c_int {
    CANCEL_PENDING.store(false, Ordering::SeqCst);
    ffi_guard(-1, |runtime| match download_and_install(runtime) {
        Ok(true) => 1,
        Ok(false) => 0,
        Err(e) => runtime.set_error(e.to_string()),
    })
}

#[no_mangle]
pub extern "C" fn fcb_cancel_pending_operations() -> c_int {
    CANCEL_PENDING.store(true, Ordering::SeqCst);
    0
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
            Ok(()) => {
                let _ = post_launch_success_event(runtime);
                0
            }
            Err(e) => runtime.set_error(e.to_string()),
        }
    })
}

#[no_mangle]
/// # Safety
/// `reason` must be null or a valid NUL-terminated C string for the duration of
/// the call.
pub unsafe extern "C" fn fcb_mark_launch_failure(
    patch_number: c_int,
    reason: *const c_char,
) -> c_int {
    ffi_guard(-1, |runtime| {
        if patch_number < 0 {
            return runtime.set_error("patch_number must be non-negative");
        }
        let reason = read_cstr(reason).unwrap_or_else(|_| "unknown".to_string());
        match Updater::new(runtime.cache_dir.clone()).mark_failure(patch_number as u32, &reason) {
            Ok(()) => {
                let _ = post_launch_failure_event(runtime, patch_number as u32, &reason);
                0
            }
            Err(e) => runtime.set_error(e.to_string()),
        }
    })
}

#[no_mangle]
/// # Safety
/// `function_id` and `error` must be null or valid NUL-terminated C strings for
/// the duration of the call.
pub unsafe extern "C" fn fcb_report_interpret_failure(
    patch_number: c_int,
    function_id: *const c_char,
    error: *const c_char,
) -> c_int {
    ffi_guard(-1, |runtime| {
        if patch_number < 0 {
            return runtime.set_error("patch_number must be non-negative");
        }
        let function_id = read_cstr(function_id).unwrap_or_else(|_| "unknown".to_string());
        let error = read_cstr(error).unwrap_or_else(|_| "unknown".to_string());
        let reason = format!("interpret_failure:{function_id}:{error}");
        match Updater::new(runtime.cache_dir.clone()).mark_failure(patch_number as u32, &reason) {
            Ok(()) => {
                let _ = post_interpret_failure_event(
                    runtime,
                    patch_number as u32,
                    &function_id,
                    &error,
                );
                0
            }
            Err(e) => runtime.set_error(e.to_string()),
        }
    })
}

#[no_mangle]
/// # Safety
/// `cb` must be null or point to a function that can safely receive each
/// rollback event JSON string during this call. The pointer passed to `cb` is
/// only valid for the duration of the callback.
pub unsafe extern "C" fn fcb_drain_rollback_events(
    cb: Option<unsafe extern "C" fn(*const c_char)>,
) -> c_int {
    ffi_guard(-1, |runtime| {
        let updater = Updater::new(runtime.cache_dir.clone());
        let events = match updater.rollback_events() {
            Ok(events) => events,
            Err(e) => return runtime.set_error(e.to_string()),
        };
        for event in &events {
            if let Some(cb) = cb {
                let json = match serde_json::to_string(event) {
                    Ok(json) => json,
                    Err(e) => return runtime.set_error(e.to_string()),
                };
                let c_json = CString::new(json).unwrap_or_else(|_| CString::new("{}").unwrap());
                // SAFETY: caller supplied `cb`; `c_json` lives through the callback.
                unsafe { cb(c_json.as_ptr()) };
            }
        }
        match updater.clear_rollback_events() {
            Ok(()) => events.len().min(c_int::MAX as usize) as c_int,
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
pub extern "C" fn fcb_active_patch_number() -> c_int {
    ffi_guard(-1, |runtime| {
        match Updater::new(runtime.cache_dir.clone()).load_state() {
            Ok(state) => {
                let active = state
                    .last_launch
                    .as_ref()
                    .map(|launch| launch.patch_number)
                    .or(state.pending_patch_number)
                    .unwrap_or(state.current_patch_number);
                if active <= c_int::MAX as u32 {
                    active as c_int
                } else {
                    runtime.set_error("active patch_number exceeds c_int range")
                }
            }
            Err(e) => runtime.set_error(e.to_string()),
        }
    })
}

#[no_mangle]
pub extern "C" fn fcb_last_known_good_patch_number() -> c_int {
    ffi_guard(-1, |runtime| {
        match Updater::new(runtime.cache_dir.clone()).load_state() {
            Ok(state) => match state.last_known_good_patch_number {
                Some(value) if value <= c_int::MAX as u32 => value as c_int,
                Some(_) => runtime.set_error("last_known_good_patch_number exceeds c_int range"),
                None => 0,
            },
            Err(e) => runtime.set_error(e.to_string()),
        }
    })
}

#[no_mangle]
pub extern "C" fn fcb_crash_rollback_history_json(limit: c_int) -> *const c_char {
    match catch_unwind(AssertUnwindSafe(|| {
        let runtime = RUNTIME.get_or_init(|| Mutex::new(Runtime::new()));
        let mut runtime = lock_runtime(runtime);
        let mut events = match Updater::new(runtime.cache_dir.clone()).rollback_events() {
            Ok(events) => events,
            Err(e) => {
                runtime.set_error(e.to_string());
                return std::ptr::null();
            }
        };
        events.reverse();
        if limit > 0 {
            events.truncate(limit as usize);
        }
        let json = match serde_json::to_string(&events) {
            Ok(json) => json,
            Err(e) => {
                runtime.set_error(e.to_string());
                return std::ptr::null();
            }
        };
        runtime.keep(json)
    })) {
        Ok(ptr) => ptr,
        Err(_) => c"panic across FFI boundary".as_ptr(),
    }
}

#[no_mangle]
pub extern "C" fn fcb_record_interpreter_call() {
    INTERPRETED_FUNCTION_CALLS.fetch_add(1, Ordering::Relaxed);
}

#[no_mangle]
pub extern "C" fn fcb_record_aot_call() {
    AOT_FUNCTION_CALLS.fetch_add(1, Ordering::Relaxed);
}

#[no_mangle]
pub extern "C" fn fcb_reset_interpreter_stats() {
    INTERPRETED_FUNCTION_CALLS.store(0, Ordering::Relaxed);
    AOT_FUNCTION_CALLS.store(0, Ordering::Relaxed);
}

#[no_mangle]
/// # Safety
/// `interpreted` and `aot` must be null or point to writable `u64` values.
pub unsafe extern "C" fn fcb_get_interpreter_stats(interpreted: *mut u64, aot: *mut u64) -> c_int {
    ffi_guard(-1, |_runtime| {
        let stats = interpreter_stats_snapshot();
        if !interpreted.is_null() {
            // SAFETY: pointer was provided by caller and checked for null above.
            unsafe { *interpreted = stats.interpreted };
        }
        if !aot.is_null() {
            // SAFETY: pointer was provided by caller and checked for null above.
            unsafe { *aot = stats.aot };
        }
        0
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

fn normalize_public_key_b64(value: &str) -> std::result::Result<String, String> {
    if value.contains("-----BEGIN") {
        let body: String = value
            .lines()
            .filter(|line| !line.starts_with("-----"))
            .map(str::trim)
            .collect();
        let der = STANDARD
            .decode(body)
            .map_err(|e| format!("invalid public_key_pem: {e}"))?;
        return public_key_der_to_raw_b64(&der);
    }

    let raw = STANDARD
        .decode(value.trim())
        .map_err(|e| format!("invalid public_key_pem: {e}"))?;
    public_key_der_to_raw_b64(&raw)
}

fn public_key_der_to_raw_b64(der: &[u8]) -> std::result::Result<String, String> {
    if der.len() == 32 {
        return Ok(STANDARD.encode(der));
    }
    if let Some(pos) = der
        .windows(3)
        .rposition(|window| window == [0x03, 0x21, 0x00])
    {
        let start = pos + 3;
        if der.len() >= start + 32 {
            return Ok(STANDARD.encode(&der[start..start + 32]));
        }
    }
    Err("public_key_pem must contain a 32-byte Ed25519 public key".to_string())
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
    CANCEL_PENDING.store(false, Ordering::SeqCst);
    check_for_update_singleflight(check_request_from_runtime(runtime)?)
}

fn interpreter_stats_snapshot() -> InterpreterStatsSnapshot {
    InterpreterStatsSnapshot {
        interpreted: INTERPRETED_FUNCTION_CALLS.load(Ordering::Relaxed),
        aot: AOT_FUNCTION_CALLS.load(Ordering::Relaxed),
    }
}

fn check_request_from_runtime(runtime: &Runtime) -> Result<CheckRequest> {
    ensure_configured(runtime)?;
    let current_patch_number = Updater::new(runtime.cache_dir.clone())
        .load_state()?
        .current_patch_number;
    Ok(CheckRequest {
        server_url: runtime.server_url.clone(),
        org_id: runtime.org_id.clone(),
        app_id: runtime.app_id.clone(),
        release_version: runtime.release_version.clone(),
        platform: runtime.platform.clone(),
        arch: runtime.arch.clone(),
        channel: runtime.channel.clone(),
        current_patch_number,
        client_id: runtime.client_id.clone(),
    })
}

fn check_for_update_singleflight(request: CheckRequest) -> Result<CheckResponse> {
    let flights = CHECK_FLIGHTS.get_or_init(|| Mutex::new(HashMap::new()));
    let (flight, leader) = {
        let mut flights = match flights.lock() {
            Ok(guard) => guard,
            Err(poisoned) => poisoned.into_inner(),
        };
        if let Some(flight) = flights.get(&request) {
            (Arc::clone(flight), false)
        } else {
            let flight = Arc::new(CheckFlight {
                result: Mutex::new(None),
                ready: Condvar::new(),
            });
            flights.insert(request.clone(), Arc::clone(&flight));
            (flight, true)
        }
    };

    if leader {
        let result = perform_check_request(&request).map_err(|e| e.to_string());
        {
            let mut slot = match flight.result.lock() {
                Ok(guard) => guard,
                Err(poisoned) => poisoned.into_inner(),
            };
            *slot = Some(result.clone());
            flight.ready.notify_all();
        }
        let mut flights = match flights.lock() {
            Ok(guard) => guard,
            Err(poisoned) => poisoned.into_inner(),
        };
        flights.remove(&request);
        return result.map_err(err);
    }

    let mut slot = match flight.result.lock() {
        Ok(guard) => guard,
        Err(poisoned) => poisoned.into_inner(),
    };
    while slot.is_none() {
        slot = match flight.ready.wait(slot) {
            Ok(guard) => guard,
            Err(poisoned) => poisoned.into_inner(),
        };
    }
    slot.clone().expect("single-flight result").map_err(err)
}

fn perform_check_request(request: &CheckRequest) -> Result<CheckResponse> {
    Client::new(&request.server_url).check(&ServerCheckRequest {
        org_id: request.org_id.as_deref(),
        app_id: &request.app_id,
        release_version: &request.release_version,
        platform: &request.platform,
        arch: &request.arch,
        channel: &request.channel,
        current_patch_number: request.current_patch_number,
        client_id: &request.client_id,
    })
}

fn download_and_install(runtime: &mut Runtime) -> Result<bool> {
    ensure_configured(runtime)?;
    ensure_not_cancelled()?;
    if runtime.public_key_b64.is_empty() {
        return Err(err("public_key is not configured"));
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
    ensure_not_cancelled()?;
    let baseline = runtime.baseline_artifact_path.as_deref();
    Updater::new(runtime.cache_dir.clone()).install_payload_with_baseline(
        &manifest_path,
        &payload_path,
        &runtime.public_key_b64,
        baseline,
    )?;
    let _ = post_install_event(runtime, patch.patch_number);
    Ok(true)
}

fn flush_rollback_events(runtime: &Runtime) -> Result<()> {
    if runtime.server_url.is_empty()
        || runtime.app_id.is_empty()
        || runtime.release_version.is_empty()
    {
        return Ok(());
    }
    let updater = Updater::new(runtime.cache_dir.clone());
    let events = updater.rollback_events()?;
    if events.is_empty() {
        return Ok(());
    }
    let client = Client::new(&runtime.server_url);
    let client_id_hash =
        crypto::sha256_hex(format!("{}{}", runtime.client_id, runtime.app_id).as_bytes());
    for event in events {
        client.post_event(&EventRequest {
            org_id: runtime.org_id.clone(),
            app_id: runtime.app_id.clone(),
            release_version: runtime.release_version.clone(),
            platform: runtime.platform.clone(),
            arch: runtime.arch.clone(),
            patch_number: Some(event.patch_number),
            event_type: event.event_type.clone(),
            client_id_hash: Some(client_id_hash.clone()),
            payload: serde_json::to_value(&event)?,
        })?;
    }
    updater.clear_rollback_events()
}

fn post_launch_success_event(runtime: &Runtime) -> Result<()> {
    if runtime.server_url.is_empty()
        || runtime.app_id.is_empty()
        || runtime.release_version.is_empty()
    {
        return Ok(());
    }
    let state = Updater::new(runtime.cache_dir.clone()).load_state()?;
    let stats = interpreter_stats_snapshot();
    let client_id_hash =
        crypto::sha256_hex(format!("{}{}", runtime.client_id, runtime.app_id).as_bytes());
    Client::new(&runtime.server_url).post_event(&EventRequest {
        org_id: runtime.org_id.clone(),
        app_id: runtime.app_id.clone(),
        release_version: runtime.release_version.clone(),
        platform: runtime.platform.clone(),
        arch: runtime.arch.clone(),
        patch_number: state.last_known_good_patch_number,
        event_type: "launch_success".to_string(),
        client_id_hash: Some(client_id_hash),
        payload: serde_json::json!({
            "event_type": "launch_success",
            "patch_number": state.last_known_good_patch_number,
            "interpreted_function_calls": stats.interpreted,
            "aot_function_calls": stats.aot,
            "interpreter_ratio": stats.ratio(),
        }),
    })
}

fn post_install_event(runtime: &Runtime, patch_number: u32) -> Result<()> {
    if runtime.server_url.is_empty()
        || runtime.app_id.is_empty()
        || runtime.release_version.is_empty()
    {
        return Ok(());
    }
    let stats = interpreter_stats_snapshot();
    let client_id_hash =
        crypto::sha256_hex(format!("{}{}", runtime.client_id, runtime.app_id).as_bytes());
    Client::new(&runtime.server_url).post_event(&EventRequest {
        org_id: runtime.org_id.clone(),
        app_id: runtime.app_id.clone(),
        release_version: runtime.release_version.clone(),
        platform: runtime.platform.clone(),
        arch: runtime.arch.clone(),
        patch_number: Some(patch_number),
        event_type: "install".to_string(),
        client_id_hash: Some(client_id_hash),
        payload: serde_json::json!({
            "event_type": "install",
            "patch_number": patch_number,
            "interpreted_function_calls": stats.interpreted,
            "aot_function_calls": stats.aot,
            "interpreter_ratio": stats.ratio(),
        }),
    })
}

fn post_launch_failure_event(runtime: &mut Runtime, patch_number: u32, reason: &str) -> Result<()> {
    let _ = hydrate_runtime_config(runtime);
    if runtime.server_url.is_empty()
        || runtime.app_id.is_empty()
        || runtime.release_version.is_empty()
    {
        return Ok(());
    }
    let stats = interpreter_stats_snapshot();
    let client_id_hash =
        crypto::sha256_hex(format!("{}{}", runtime.client_id, runtime.app_id).as_bytes());
    Client::new(&runtime.server_url).post_event(&EventRequest {
        org_id: runtime.org_id.clone(),
        app_id: runtime.app_id.clone(),
        release_version: runtime.release_version.clone(),
        platform: runtime.platform.clone(),
        arch: runtime.arch.clone(),
        patch_number: Some(patch_number),
        event_type: "launch_failure".to_string(),
        client_id_hash: Some(client_id_hash),
        payload: serde_json::json!({
            "event_type": "launch_failure",
            "patch_number": patch_number,
            "reason": reason,
            "error_message": reason,
            "interpreted_function_calls": stats.interpreted,
            "aot_function_calls": stats.aot,
            "interpreter_ratio": stats.ratio(),
        }),
    })
}

fn post_interpret_failure_event(
    runtime: &mut Runtime,
    patch_number: u32,
    function_id: &str,
    error: &str,
) -> Result<()> {
    let _ = hydrate_runtime_config(runtime);
    if runtime.server_url.is_empty()
        || runtime.app_id.is_empty()
        || runtime.release_version.is_empty()
    {
        return Ok(());
    }
    let stats = interpreter_stats_snapshot();
    let failure_location = parse_interpret_failure_location(error);
    let client_id_hash =
        crypto::sha256_hex(format!("{}{}", runtime.client_id, runtime.app_id).as_bytes());
    Client::new(&runtime.server_url).post_event(&EventRequest {
        org_id: runtime.org_id.clone(),
        app_id: runtime.app_id.clone(),
        release_version: runtime.release_version.clone(),
        platform: runtime.platform.clone(),
        arch: runtime.arch.clone(),
        patch_number: Some(patch_number),
        event_type: "crash_rollback".to_string(),
        client_id_hash: Some(client_id_hash),
        payload: serde_json::json!({
            "event_type": "crash_rollback",
            "reason": "interpret_failure",
            "patch_number": patch_number,
            "function_id": function_id,
            "error_message": error,
            "bytecode_offset": failure_location.bytecode_offset,
            "source_location": source_location_payload_value(failure_location.source_location.as_ref()),
            "interpreted_function_calls": stats.interpreted,
            "aot_function_calls": stats.aot,
            "interpreter_ratio": stats.ratio(),
        }),
    })
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

    ensure_not_cancelled()?;
    let manifest_bytes = client.download_bytes(&patch.manifest_url)?;
    ensure_not_cancelled()?;
    ensure_hash("manifest", &manifest_bytes, &patch.manifest_hash)?;
    let manifest_path = out.join("patch_manifest.json");
    write_file(&manifest_path, &manifest_bytes)?;

    let (payload_part_path, payload_path) =
        download_resumable_payload(&client, &patch.payload_url, &out, "payload.bin")?;
    let payload_bytes = fs::read(&payload_part_path)?;
    ensure_not_cancelled()?;
    ensure_hash("payload", &payload_bytes, &patch.payload_hash)?;
    fs::rename(&payload_part_path, &payload_path)?;
    let _ = fs::remove_file(out.join(".progress"));

    Ok((manifest_path, payload_path))
}

fn download_resumable_payload(
    client: &Client,
    url: &str,
    out: &Path,
    file_name: &str,
) -> Result<(PathBuf, PathBuf)> {
    let final_path = out.join(file_name);
    let part_path = out.join(format!("{file_name}.part"));
    let progress_path = out.join(".progress");
    let offset = resume_offset(&part_path, &progress_path)?;
    let (bytes, append) = client
        .download_bytes_from_with_cancel(url, offset, || CANCEL_PENDING.load(Ordering::SeqCst))?;
    ensure_not_cancelled()?;
    if append && offset > 0 {
        let mut file = fs::OpenOptions::new().append(true).open(&part_path)?;
        file.write_all(&bytes)?;
        file.sync_all()?;
    } else {
        write_file(&part_path, &bytes)?;
    }
    let written = fs::metadata(&part_path).map(|m| m.len()).unwrap_or(0);
    write_file(&progress_path, written.to_string().as_bytes())?;
    Ok((part_path, final_path))
}

fn resume_offset(part_path: &Path, progress_path: &Path) -> Result<u64> {
    let part_len = fs::metadata(part_path).map(|m| m.len()).unwrap_or(0);
    let progress_len = match fs::read_to_string(progress_path) {
        Ok(value) => value.trim().parse::<u64>().ok(),
        Err(_) => None,
    };
    let offset = progress_len.map_or(part_len, |progress| progress.min(part_len));
    if offset < part_len {
        fs::OpenOptions::new()
            .write(true)
            .open(part_path)?
            .set_len(offset)?;
    }
    Ok(offset)
}

fn ensure_not_cancelled() -> Result<()> {
    if CANCEL_PENDING.load(Ordering::SeqCst) {
        return Err(err("operation cancelled"));
    }
    Ok(())
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
mod tests;
