use fcb_core::state::{InstalledPatch, LastLaunch, State, Updater};
use fcb_updater::{
    fcb_get_launch_patch, fcb_init, fcb_set_server_url, FcbInitParams, FcbLaunchPatch,
};
use std::ffi::CString;
use std::io::{Read, Write};
use std::net::TcpListener;
use std::sync::mpsc;

#[test]
fn crash_rollback_event_survives_failed_flush_and_posts_later() {
    let cache_dir = std::env::temp_dir().join(format!(
        "fcb-updater-rollback-flush-test-{}",
        std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .expect("time")
            .as_nanos()
    ));
    let updater = Updater::new(&cache_dir);
    updater
        .save_state(&State {
            schema_version: 2,
            release_version: "1.0.0+1".to_string(),
            current_patch_number: 0,
            pending_patch_number: Some(11),
            last_known_good_patch_number: Some(7),
            boot_attempts: 2,
            bad_patches: Vec::new(),
            last_launch: Some(LastLaunch {
                patch_number: 11,
                status: "pending_success".to_string(),
                started_at: "0".to_string(),
            }),
            installed: vec![InstalledPatch {
                patch_number: 11,
                backend: "bytecode".to_string(),
                manifest_path: "patches/11/manifest.json".to_string(),
                payload_path: "patches/11/payload.bin".to_string(),
                artifact_path: None,
                installed_at: "0".to_string(),
            }],
        })
        .expect("write state");

    let failing_url = spawn_event_server(503).0;
    init_runtime(&cache_dir, &failing_url);
    assert_eq!(
        unsafe { fcb_get_launch_patch(&mut empty_launch_patch()) },
        0
    );
    let events = updater
        .rollback_events()
        .expect("events after failed flush");
    assert_eq!(events.len(), 1);
    assert_eq!(events[0].event_type, "crash_rollback");
    assert_eq!(events[0].patch_number, 11);
    assert_eq!(events[0].boot_attempts, 3);
    assert_eq!(events[0].last_known_good_patch_number, Some(7));

    let (success_url, request_rx) = spawn_event_server(200);
    let success_url_c = CString::new(success_url).expect("server url");
    assert_eq!(unsafe { fcb_set_server_url(success_url_c.as_ptr()) }, 0);
    assert_eq!(
        unsafe { fcb_get_launch_patch(&mut empty_launch_patch()) },
        0
    );

    let request = request_rx.recv().expect("event post");
    assert!(request.starts_with("POST /v1/events "), "{request}");
    assert!(
        request.contains(r#""event_type": "crash_rollback""#),
        "{request}"
    );
    assert!(request.contains(r#""patch_number": 11"#), "{request}");
    assert!(request.contains(r#""boot_attempts": 3"#), "{request}");
    assert!(
        request.contains(r#""last_known_good_patch_number": 7"#),
        "{request}"
    );
    assert!(updater
        .rollback_events()
        .expect("events after successful flush")
        .is_empty());

    let _ = std::fs::remove_dir_all(cache_dir);
}

#[test]
fn rollback_flush_posts_multiple_events_in_order_and_clears_after_state_reset() {
    let cache_dir = std::env::temp_dir().join(format!(
        "fcb-updater-rollback-multi-flush-test-{}",
        std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .expect("time")
            .as_nanos()
    ));
    std::fs::create_dir_all(&cache_dir).expect("create cache dir");
    std::fs::write(
        cache_dir.join("events.log"),
        r#"{"event_type":"crash_rollback","patch_number":22,"boot_attempts":3,"last_known_good_patch_number":7,"timestamp":"1"}"#,
    )
    .expect("write existing event");
    std::fs::write(cache_dir.join("state.json"), b"{not-json").expect("write corrupt state");

    let (success_url, request_rx) = spawn_event_server_requests(200, 2);
    init_runtime(&cache_dir, &success_url);
    assert_eq!(
        unsafe { fcb_get_launch_patch(&mut empty_launch_patch()) },
        0
    );

    let first = request_rx.recv().expect("first event post");
    let second = request_rx.recv().expect("second event post");
    assert!(
        first.contains(r#""event_type": "crash_rollback""#),
        "{first}"
    );
    assert!(first.contains(r#""patch_number": 22"#), "{first}");
    assert!(first.contains(r#""boot_attempts": 3"#), "{first}");
    assert!(
        second.contains(r#""event_type": "state_reset""#),
        "{second}"
    );
    assert!(second.contains(r#""patch_number": 0"#), "{second}");
    assert!(second.contains("failed to parse state.json"), "{second}");
    assert!(Updater::new(&cache_dir)
        .rollback_events()
        .expect("events after successful multi flush")
        .is_empty());

    let _ = std::fs::remove_dir_all(cache_dir);
}

fn init_runtime(cache_dir: &std::path::Path, server_url: &str) {
    let cache_dir_c = CString::new(cache_dir.to_string_lossy().as_bytes()).expect("cache dir");
    let app_id_c = CString::new("rollback-app").expect("app id");
    let release_c = CString::new("1.0.0+1").expect("release");
    let channel_c = CString::new("stable").expect("channel");
    let platform_c = CString::new("android").expect("platform");
    let arch_c = CString::new("arm64-v8a").expect("arch");
    let server_url_c = CString::new(server_url).expect("server url");
    let params = FcbInitParams {
        app_id: app_id_c.as_ptr(),
        channel: channel_c.as_ptr(),
        release_version: release_c.as_ptr(),
        platform: platform_c.as_ptr(),
        arch: arch_c.as_ptr(),
        cache_dir: cache_dir_c.as_ptr(),
        public_key_pem: std::ptr::null(),
        check_on_startup: 0,
    };
    assert_eq!(unsafe { fcb_init(&params) }, 0);
    assert_eq!(unsafe { fcb_set_server_url(server_url_c.as_ptr()) }, 0);
}

fn empty_launch_patch() -> FcbLaunchPatch {
    FcbLaunchPatch {
        has_patch: 0,
        patch_number: 0,
        backend: std::ptr::null(),
        artifact_path: std::ptr::null(),
        bytecode_path: std::ptr::null(),
        manifest_path: std::ptr::null(),
    }
}

fn spawn_event_server(status: u16) -> (String, mpsc::Receiver<String>) {
    spawn_event_server_requests(status, 1)
}

fn spawn_event_server_requests(
    status: u16,
    expected_requests: usize,
) -> (String, mpsc::Receiver<String>) {
    let listener = TcpListener::bind("127.0.0.1:0").expect("bind server");
    let url = format!("http://{}", listener.local_addr().expect("local addr"));
    let (tx, rx) = mpsc::channel();
    std::thread::spawn(move || {
        for _ in 0..expected_requests {
            let (mut stream, _) = listener.accept().expect("accept");
            let mut request = Vec::new();
            let mut buffer = [0_u8; 4096];
            loop {
                let n = stream.read(&mut buffer).expect("read request");
                if n == 0 {
                    break;
                }
                request.extend_from_slice(&buffer[..n]);
                if has_complete_http_request(&request) {
                    break;
                }
            }
            let _ = tx.send(String::from_utf8_lossy(&request).to_string());
            let body = br#"{"status":"ok"}"#;
            let reason = if status == 200 {
                "OK"
            } else {
                "Service Unavailable"
            };
            write!(
                stream,
                "HTTP/1.1 {status} {reason}\r\nContent-Type: application/json\r\nContent-Length: {}\r\nConnection: close\r\n\r\n",
                body.len()
            )
            .expect("write headers");
            stream.write_all(body).expect("write body");
            if status != 200 {
                break;
            }
        }
    });
    (url, rx)
}

fn has_complete_http_request(request: &[u8]) -> bool {
    let Some(header_end) = request.windows(4).position(|window| window == b"\r\n\r\n") else {
        return false;
    };
    let headers = String::from_utf8_lossy(&request[..header_end]);
    let content_length = headers
        .lines()
        .find_map(|line| {
            let (name, value) = line.split_once(':')?;
            name.eq_ignore_ascii_case("content-length")
                .then(|| value.trim().parse::<usize>().ok())
                .flatten()
        })
        .unwrap_or(0);
    request.len() >= header_end + 4 + content_length
}
