use fcb_core::state::Updater;
use std::ffi::{CStr, CString};
use std::os::raw::{c_char, c_int};
use std::panic::{catch_unwind, AssertUnwindSafe};
use std::path::PathBuf;
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
                0
            }
            Ok(_) => 0,
            Err(e) => runtime.set_error(e),
        }
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
    0
}

#[no_mangle]
pub extern "C" fn fcb_download_and_install_blocking() -> c_int {
    ffi_guard(-1, |runtime| {
        runtime.set_error("download and install is not configured")
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

fn read_cstr(ptr: *const c_char) -> Result<String, String> {
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

#[cfg(test)]
mod tests {
    use super::{fcb_get_launch_patch, fcb_init, FcbInitParams, FcbLaunchPatch};
    use fcb_core::state::{InstalledPatch, State, Updater};
    use std::ffi::{CStr, CString};

    #[test]
    fn get_launch_patch_returns_snapshot_artifact_path() {
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
}
