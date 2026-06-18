# Flutter CodePush Box

FCB is a self-hosted Flutter code-push prototype with a Rust CLI/updater,
Go server, Flutter package, and forked Flutter/Dart VM integration.

## Bootstrap

Clone the repository and initialize vendor dependencies:

```bash
git clone --recursive <repo-url> fl_codepush_box
cd fl_codepush_box
scripts/bootstrap.sh
```

For an existing checkout:

```bash
git pull
scripts/bootstrap.sh
```

`scripts/bootstrap.sh --check` validates the current `vendor/flutter`,
Engine-embedded Dart SDK, and `vendor/depot_tools` checkouts and prints their commits.
`scripts/bootstrap.sh --check --strict-submodules` is the Phase H1 gate for the
top-level vendor submodules. Dart VM work is maintained in
`vendor/flutter/engine/src/flutter/third_party/dart`, not in a separate
top-level `vendor/sdk` checkout.

## Fast Verification

```bash
cargo fmt --check
cargo test --workspace --no-default-features

cd server
go vet ./...
go test -count=1 ./...
```

The fake Flutter end-to-end drill expects a built CLI, built server, and Dart:

```bash
cargo build -p fcb --no-default-features
(cd server && go build -o ../target/debug/fcb_server .)
FCB_BIN="$PWD/target/debug/fcb" \
SERVER_BIN="$PWD/target/debug/fcb_server" \
DART_BIN="$(command -v dart)" \
bash tests/e2e/test_e2e.sh
```

Local core CI aggregation:

```bash
make ci-local-core
```

To audit real GitHub Actions evidence after the workflows are pushed:

```bash
make check-github-actions-inventory
make check-github-actions-evidence
```

The inventory check is local and offline. The evidence check is read-only,
uses `gh run list`, writes a summary under `target/fcb/github-actions-evidence/`,
and fails until the required workflows exist on the target branch and have
successful runs.

To verify Phase H runbook command generation without devices:

```bash
make check-phase-h-runbooks
```

Before marking all plans complete, run the evidence audit:

```bash
make audit-plan-completion
```

The audit is read-only and fails until the required remote CI, vendor VM,
device, TestFlight, submodule, and rebase evidence is present.
GitHub Actions evidence must come from the latest completed runs, with
successful conclusions and one shared push head SHA. By default the final
audit requires a live remote GitHub Actions check for `main`; use
`FCB_PLAN_AUDIT_GITHUB_BRANCH` only for an explicit branch audit. Cached
summaries are only accepted when `FCB_PLAN_AUDIT_GITHUB_EVIDENCE=0` is set
explicitly for offline inspection, and their branch must match the audit
branch. The final audit fixes the GitHub Actions duration limits at 5.0
minutes for push workflows, 60.0 minutes for Android nightly, and 90.0 minutes
for iOS nightly unless the corresponding `FCB_PLAN_AUDIT_GITHUB_MAX_*`
variables are set explicitly.
The local core CI evidence used by the final audit must include passed Kernel
compile, fake Flutter e2e, and Flutter package steps; summaries that skipped
those steps are treated as incomplete.
Evidence summaries must reference regular files inside their archive with
relative paths; absolute paths, symlinks, and paths escaping the archive are
rejected.
Device and store evidence summaries must include explicit completion markers,
for example `H3 Android arm64 drill passed`, `H4 iPhone device drill passed`,
`TestFlight External Testing entered`, `Counter app real VM patch passed`, or
`Vendor rebase validation passed`. The final gate also validates required
summary metadata and the `vendor/REBASE.md` rebase runbook content.

To produce the vendor VM test evidence consumed by the audit:

```bash
make test-vendor-vm-runtime
```

To record evidence after a real counter_app VM interpreted patch:

```bash
make record-vm-patch-evidence
```

To record evidence after a real vendor rebase validation:

```bash
make record-vendor-rebase-evidence
```

## Phase H Device Workflows

The real Engine/device flows depend on the vendor checkouts:

```bash
scripts/build_android_engine.sh
scripts/test_android_arm64.sh
scripts/full_arm64_drill.sh
scripts/build_ios_engine.sh
scripts/test_ios_sim.sh
scripts/record_testflight_evidence.sh
scripts/record_vendor_rebase_evidence.sh
```

Do not maintain `engine_patch/`, `dart_sdk_patch/`, or a separate top-level
`vendor/sdk` mirror. During development, branch and commit directly in
`vendor/flutter` and its embedded Dart checkout, then update the pinned commits
through the vendor rebase flow.
