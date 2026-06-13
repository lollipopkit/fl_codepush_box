# Phase B Android snapshot_replace Validation

Phase B is only complete after the real Android device or emulator flow passes with a patched Flutter Engine. Local Rust, Go, and shell tests are useful guardrails, but they do not prove that the Engine loads the patched `libapp.so` on device.

## Required Environment

- `flutter` on `PATH`
- `adb` on `PATH`, with a connected device or emulator
- built `fcb` CLI, exposed through `FCB_BIN` or `PATH`
- built server binary, exposed through `SERVER_BIN` or `PATH`
- Android updater native library at `packages/fcb_code_push/android/src/main/jniLibs/<abi>/libfcb_updater.so`; preflight verifies this is an ELF shared object, not just a placeholder file
- Flutter Engine source patched with `engine_patch/android/apply_engine_patch.sh`
- local Flutter Engine build output under `/path/to/engine/src/out/<local-engine>`
- local Flutter Engine host build output under `/path/to/engine/src/out/<local-engine-host>`
- Flutter build arguments pointing at that patched local Engine

Before building the local Engine, verify the Android hook is both linked and
called:

```bash
engine_patch/android/verify_engine_patch.sh /path/to/engine/src
```

Example:

```bash
FCB_AUTO_BUILD_ANDROID_UPDATER=1 \
FLUTTER_BUILD_EXTRA_ARGS='--local-engine-src-path /path/to/engine/src --local-engine android_release_arm64 --local-engine-host host_release' \
tests/e2e/test_phase_b_android.sh
```

For a specific device or ABI:

```bash
ADB_DEVICE=emulator-5554 \
ABI=arm64-v8a \
TARGET_PLATFORM=android-arm64 \
FCB_BIN=/path/to/fcb \
SERVER_BIN=/path/to/fcb_server \
FLUTTER_BUILD_EXTRA_ARGS='--local-engine-src-path /path/to/engine/src --local-engine android_release_arm64 --local-engine-host host_release' \
tests/e2e/test_phase_b_android.sh
```

When the real device script passes, it writes a machine-readable evidence file
under `.phase_b_evidence/` by default. Set `PHASE_B_EVIDENCE_DIR=/path/to/dir`
to store that proof elsewhere. The evidence records the Android device state,
Android version/API/ABI, Flutter device listing, local Engine source/target/host
names, artifact hashes, and each Phase B acceptance validation.

Verify the latest evidence file with:

```bash
tests/e2e/verify_phase_b_evidence.sh
```

The verifier rejects dry-run evidence by default; only the real Android script
running against a patched local Engine can produce completion evidence.

`TARGET_PLATFORM` must match `ABI`:

- `arm64-v8a` -> `android-arm64`
- `armeabi-v7a` -> `android-arm`
- `x86_64` -> `android-x64`
- `x86` -> `android-x86`

By default the script uses `DEVICE_SERVER_URL=http://127.0.0.1:<port>` and
configures `adb reverse` so the device can reach the local server. If
`USE_ADB_REVERSE=0`, `DEVICE_SERVER_URL` must be a host that is directly
reachable from the Android device or emulator, such as `http://10.0.2.2:<port>`
for the standard Android emulator. `USE_ADB_REVERSE` must be `auto`, `1`, or
`0`; loopback hosts such as `127.0.0.1`, `localhost`, or `::1` require
`USE_ADB_REVERSE=auto` or `1`.

## What The Device Test Proves

The script creates a temporary Flutter counter app and verifies the Phase B acceptance path:

- baseline APK starts with `Counter: 1`
- CLI publishes the release from the APK `libapp.so`
- patch APK build produces a new `libapp.so`
- CLI generates and promotes a signed `bsdiff`/`zstd` patch
- installed baseline app downloads the patch
- restart loads the patched AOT artifact and shows `Counter: 2`
- stopping the server still launches the local active patch
- a bad patch is blocklisted and the next launch rolls back to the previous active patch

The preflight requires `--local-engine-src-path` or `FCB_ENGINE_SRC`, verifies that the requested `--local-engine` and `--local-engine-host` outputs exist, verifies that the APK contains both `lib/<abi>/libapp.so` and `lib/<abi>/libfcb_updater.so`, and verifies that the patched Engine source calls the FCB Android snapshot replacement hook outside the copied hook directory.

## Local Checks

These checks do not replace the device test, but should pass before running it:

```bash
tests/e2e/test_phase_b_local.sh
```

The local gate expands to:

```bash
bash -n tests/e2e/test_phase_b_android.sh
bash -n tests/e2e/phase_b_preflight.sh
engine_patch/android/test_apply_engine_patch.sh
engine_patch/android/test_verify_engine_patch.sh
tests/e2e/test_phase_b_android_helpers.sh
tests/e2e/test_phase_b_android_dry_run.sh
ABI=x86_64 TARGET_PLATFORM=android-x64 SERVER_ADDR=127.0.0.1:18198 tests/e2e/test_phase_b_android_dry_run.sh
tests/e2e/verify_phase_b_evidence.sh /path/to/phase_b_android_<abi>_<timestamp>.json
tests/e2e/test_android_plugin_paths.sh
tests/e2e/test_android_native_packaging.sh
tests/e2e/test_counter_app_phase_b_contract.sh
tests/e2e/test_phase_b_preflight.sh
tests/e2e/test_force_extract_native_libs.sh
tests/e2e/test_e2e.sh
```

If `tests/e2e/phase_b_preflight.sh` fails with `required tool not found: flutter` or `required tool not found: adb`, the current machine cannot produce the final Phase B evidence.
