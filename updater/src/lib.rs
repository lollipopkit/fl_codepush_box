use fcb_core::state::Updater;
use std::ffi::{CStr, CString};
use std::os::raw::{c_char, c_int};
use std::path::PathBuf;
use std::sync::{Mutex, OnceLock};

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
    cache_dir: PathBuf,
    last_error: CString,
    strings: Vec<CString>,
}

impl Runtime {
    fn new() -> Self {
        Self {
            cache_dir: PathBuf::from(".fcb/cache"),
            last_error: CString::new("").unwrap(),
            strings: Vec::new(),
        }
    }

    fn set_error(&mut self, message: impl Into<String>) -> c_int {
        self.last_error = CString::new(message.into()).unwrap_or_else(|_| CString::new("invalid error").unwrap());
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
    let runtime = RUNTIME.get_or_init(|| Mutex::new(Runtime::new()));
    let mut runtime = runtime.lock().unwrap();
    if params.is_null() {
        return runtime.set_error("params is null");
    }
    let params = unsafe { &*params };
    match read_cstr(params.cache_dir) {
        Ok(cache_dir) if !cache_dir.is_empty() => {
            runtime.cache_dir = PathBuf::from(cache_dir);
            0
        }
        Ok(_) => 0,
        Err(e) => runtime.set_error(e),
    }
}

#[no_mangle]
pub extern "C" fn fcb_get_launch_patch(out_patch: *mut FcbLaunchPatch) -> c_int {
    let runtime = RUNTIME.get_or_init(|| Mutex::new(Runtime::new()));
    let mut runtime = runtime.lock().unwrap();
    if out_patch.is_null() {
        return runtime.set_error("out_patch is null");
    }
    match Updater::new(runtime.cache_dir.clone()).launch_patch() {
        Ok(Some(patch)) => unsafe {
            (*out_patch).has_patch = 1;
            (*out_patch).patch_number = patch.patch_number as c_int;
            (*out_patch).backend = runtime.keep(patch.backend);
            (*out_patch).artifact_path = std::ptr::null();
            (*out_patch).bytecode_path = runtime.keep(patch.payload_path);
            (*out_patch).manifest_path = runtime.keep(patch.manifest_path);
            0
        },
        Ok(None) => unsafe {
            (*out_patch).has_patch = 0;
            (*out_patch).patch_number = 0;
            (*out_patch).backend = std::ptr::null();
            (*out_patch).artifact_path = std::ptr::null();
            (*out_patch).bytecode_path = std::ptr::null();
            (*out_patch).manifest_path = std::ptr::null();
            0
        },
        Err(e) => runtime.set_error(e.to_string()),
    }
}

#[no_mangle]
pub extern "C" fn fcb_check_for_update_async() -> c_int {
    0
}

#[no_mangle]
pub extern "C" fn fcb_download_and_install_blocking() -> c_int {
    0
}

#[no_mangle]
pub extern "C" fn fcb_mark_launch_success() -> c_int {
    let runtime = RUNTIME.get_or_init(|| Mutex::new(Runtime::new()));
    let mut runtime = runtime.lock().unwrap();
    match Updater::new(runtime.cache_dir.clone()).mark_success() {
        Ok(()) => 0,
        Err(e) => runtime.set_error(e.to_string()),
    }
}

#[no_mangle]
pub extern "C" fn fcb_mark_launch_failure(patch_number: c_int, reason: *const c_char) -> c_int {
    let runtime = RUNTIME.get_or_init(|| Mutex::new(Runtime::new()));
    let mut runtime = runtime.lock().unwrap();
    let reason = read_cstr(reason).unwrap_or_else(|_| "unknown".to_string());
    match Updater::new(runtime.cache_dir.clone()).mark_failure(patch_number as u32, &reason) {
        Ok(()) => 0,
        Err(e) => runtime.set_error(e.to_string()),
    }
}

#[no_mangle]
pub extern "C" fn fcb_current_patch_number() -> c_int {
    let runtime = RUNTIME.get_or_init(|| Mutex::new(Runtime::new()));
    let mut runtime = runtime.lock().unwrap();
    match Updater::new(runtime.cache_dir.clone()).load_state() {
        Ok(state) => state.current_patch_number as c_int,
        Err(e) => runtime.set_error(e.to_string()),
    }
}

#[no_mangle]
pub extern "C" fn fcb_last_error() -> *const c_char {
    let runtime = RUNTIME.get_or_init(|| Mutex::new(Runtime::new()));
    runtime.lock().unwrap().last_error.as_ptr()
}

fn read_cstr(ptr: *const c_char) -> Result<String, String> {
    if ptr.is_null() {
        return Ok(String::new());
    }
    unsafe { CStr::from_ptr(ptr) }
        .to_str()
        .map(|s| s.to_string())
        .map_err(|e| e.to_string())
}

