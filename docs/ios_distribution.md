# iOS Distribution Drill

This document is the Phase H4 runbook for iPhone arm64 and TestFlight validation.

## Prerequisites

- Apple Developer Program access with App Store Connect permission for the bundle id.
- A physical iPhone registered for development.
- Xcode with the iOS SDK installed.
- `vendor/flutter` checked out at the pinned FCB commit; its Engine `DEPS`
  points embedded Dart at the pinned `lollipopkit/dartsdk` commit.
- iOS engine built with FCB hooks:

```bash
FCB_IOS_CPU=arm64 FCB_RUNTIME_MODE=release scripts/build_ios_engine.sh
```

For simulator smoke before device work:

```bash
FCB_IOS_SIMULATOR=1 FCB_IOS_CPU=x64 scripts/build_ios_engine.sh
scripts/test_ios_sim.sh
```

The H4 wrapper keeps the simulator preflight, device command log, TestFlight
command log, and evidence archive under one directory:

```bash
scripts/full_ios_drill.sh
```

Set `FCB_SKIP_IOS_SIM_PREFLIGHT=1` when only generating the iPhone/TestFlight
command logs.
After real iPhone evidence is collected, rerun the wrapper with
`FCB_H4_DEVICE_EVIDENCE=<device-log>` and
`FCB_H4_SERVER_EVENTS_EVIDENCE=<server-events-export>` so the archived summary
can include the `H4 iPhone device drill passed` completion marker used by
`make audit-plan-completion`.

## Device Drill

1. Build `libfcb_updater.a` through `scripts/build_ios_engine.sh`.
2. Open `examples/counter_app/ios/Runner.xcworkspace` in Xcode.
3. Set a real signing team, bundle id, and provisioning profile.
4. Build and install the app on the iPhone with the local FCB engine.
5. Launch baseline and record the visible counter/debug overlay state.
6. Publish a bytecode patch through the FCB server and promote it to 100%.
7. Restart the app, download the patch, restart again, and verify patched output.
8. Trigger the crash rollback payload once Phase E exposes a crash-producing VM patch.
9. Verify the app falls back to last-known-good and the server receives `crash_rollback`.
10. Archive device logs, server event export, app build number, and engine commit hashes.
11. Copy final evidence into `target/fcb/evidence/ios_drill_<timestamp>/` or let
    `scripts/full_ios_drill.sh` do it automatically.

## TestFlight

1. Archive the signed `Runner` target in Xcode.
2. Validate the archive before upload.
3. Upload to App Store Connect.
4. Add internal testers first.
5. Submit external testing only after the device drill passes.
6. Save the App Review result in the release notes or issue tracker.
7. Record the accepted External Testing evidence:

```bash
FCB_TESTFLIGHT_BUILD_NUMBER=<build-number> \
FCB_TESTFLIGHT_STATUS="External Testing" \
FCB_TESTFLIGHT_EXTERNAL_TESTING_EVIDENCE=<app-store-connect-status-file> \
FCB_TESTFLIGHT_UPLOAD_EVIDENCE=<upload-log-file> \
make record-testflight-evidence
```

The command writes `target/fcb/evidence/testflight_<timestamp>/summary.txt` with the
`TestFlight External Testing entered` marker used by
`make audit-plan-completion`. The status evidence file must contain the text
`External Testing`, the bundle id, and the TestFlight build number. The optional
upload evidence file must contain `accepted` and the same build number.

If Apple rejects the build, record the exact rejection text, build number, and patch payload scope. Cross-reference `docs/apple_compliance.md` before deciding whether to narrow interpreter scope, adjust reviewer notes, or disable iOS code push for that channel.
