# Vendor Rebase Runbook

This runbook describes the quarterly vendor rebase for the Flutter and embedded
Dart SDK forks used by FCB. It must be exercised during every real rebase before
the local vendor checkout refs and Engine DEPS Dart pin are advanced.

## Scope

- `vendor/flutter`: follows Flutter stable plus FCB engine hook commits.
- `vendor/flutter/engine/src/flutter/third_party/dart`: follows the
  `lollipopkit/dartsdk` fork plus FCB patch runtime commits. This embedded
  checkout is the only Dart VM patch source tree maintained in this repository.
- `vendor/depot_tools`: pinned Chromium toolchain checkout; normally update only
  when Flutter engine tooling requires it.

## Quarterly Flow

1. Pick the new Flutter stable and Dart SDK base refs.
2. Create temporary rebase branches in the Flutter fork and Dart SDK fork.
3. Rebase or cherry-pick the FCB hook commits onto the new bases:
   - Flutter Android/iOS engine hook commits.
   - Dart VM `fcb_patch_runtime`, `fcb_patch_entry`, API, and stub hook commits.
4. Resolve conflicts with the conflict strategy below.
5. Build and test the rebased forks.
6. Push the rebased fork branches.
7. Update the local `vendor/flutter` checkout and the Flutter Engine `DEPS`
   embedded Dart pin to the new fork commits.
8. Record evidence with `make record-vendor-rebase-evidence`.

## Conflict Strategy

`stub_code_compiler` is the highest-risk conflict point because upstream Dart VM
changes can move architecture-specific call stubs. Resolve it by keeping the
upstream control flow first, then reapplying the FCB hook at the smallest call
dispatch point for every supported architecture.

For `fcb_patch_runtime` conflicts, preserve upstream VM object ownership and GC
rooting semantics. Do not downgrade ObjectPtr integration back to plain byte
vectors or host-only Value structs.

For Flutter engine conflicts, keep the root isolate lifecycle unchanged and
reapply FCB initialization before user Dart code runs. Android and iOS bridges
must still load the patch runtime before first frame and report launch success
after the app is active.

## Validation Checklist

Run these checks before updating the parent repository:

```sh
scripts/bootstrap.sh --check
scripts/build_android_engine.sh
cargo test --workspace
tests/e2e/test_e2e.sh
scripts/full_arm64_drill.sh
```

For iOS release candidates, also run the iPhone device drill and TestFlight
External Testing flow from `docs/ios_distribution.md`.

The rebase is not complete until the evidence archive contains:

- Rebase command and conflict log with `replayed FCB hook commits`, the source
  ref, target ref, rebased Flutter commit, and rebased embedded Dart commit.
- Engine build evidence with `engine build passed` and the rebased Flutter commit.
- Cargo test evidence with `cargo test --workspace passed`.
- x64 e2e evidence with `e2e_x64 passed`.
- Android arm64 drill evidence with `arm64 drill passed`.

## Evidence Recording

After the validation checklist passes, run:

```sh
FCB_VENDOR_REBASE_STATUS=passed \
FCB_VENDOR_REBASE_SOURCE_REF=<old-stable-or-fcb-ref> \
FCB_VENDOR_REBASE_TARGET_REF=<new-flutter-stable-ref> \
FCB_VENDOR_REBASE_FLUTTER_COMMIT=<rebased-flutter-commit> \
FCB_VENDOR_REBASE_DART_COMMIT=<rebased-embedded-dart-commit> \
FCB_VENDOR_REBASE_REBASE_LOG=<rebase-log-file> \
FCB_VENDOR_REBASE_ENGINE_BUILD_EVIDENCE=<engine-build-log> \
FCB_VENDOR_REBASE_CARGO_TEST_EVIDENCE=<cargo-test-log> \
FCB_VENDOR_REBASE_E2E_X64_EVIDENCE=<e2e-x64-log> \
FCB_VENDOR_REBASE_ARM64_DRILL_EVIDENCE=<arm64-drill-log> \
make record-vendor-rebase-evidence
```

The generated summary must include `Vendor rebase validation passed`.

## Rollback

If the rebased forks introduce a regression, use the rollback path: restore the
parent repository to the previous stable `vendor/flutter` / `vendor/depot_tools`
vendor checkout commits and the previous Engine `DEPS` Dart pin. Keep the failed
evidence archive for postmortem. Do not force-push the fork branches; create a
fix-forward branch or new rebase attempt instead.
