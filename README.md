# Flutter CodePush Box (FCB)

FCB is a self-hosted code-push system for Flutter: ship fixes and changes to your
app's **Dart code** without a full app-store release, with signing, staged
rollout, and automatic rollback.

> Status: research / prototype. Not yet production-ready (see `plans/`).

## How it works

- Unchanged functions keep running the original AOT machine code; only changed
  functions run in an in-app interpreter. Patches apply on the **next app
  restart** (no live hot-swap).
- Every patch is **Ed25519-signed** and hash-verified before install. A patch
  that fails to boot is automatically rolled back to the last known good version.
- Three backends (see [`docs/backends.md`](docs/backends.md)):
  - **`bytecode`** — ships interpreted Dart bytecode run by the forked-VM
    interpreter. Store-compliant on every platform (Android + iOS + desktop).
    The default and product line.
  - **`dart_vm`** — desktop only (macOS/Linux/Windows): ship the unstripped
    official Dart VM and run an updated kernel `.dill` through it (JIT). For
    self-distribution; not for iOS.
  - **`snapshot_replace`** — ships native `.so` diffs. **Enterprise/internal
    only, not Play/App Store compliant.**

## Components

| Path | Role |
|------|------|
| `cli/` | `fcb` CLI: release / patch / promote / rollback / inspect (Rust) |
| `server/` | self-hosted API + admin UI + SQLite, multi-org (Go) |
| `updater/` | on-device download / install / rollback, exposed over C ABI (Rust) |
| `packages/fcb_code_push/` | Flutter/Dart package (FFI) |
| `crates/fcb_core/` | shared library: bytecode schema, linker, state, signing |
| `tool/` | Dart Kernel → bytecode compiler |
| `vendor/` | forked Flutter engine + Dart VM with the patch runtime |

## Quick start

Configure `fcb.yaml` in your app:

```yaml
app_id: "your-app-uuid"
channel: "stable"
security:
  public_key: "<ed25519 public key>"
platforms:
  android:
    enabled: true
    backend: "snapshot_replace"   # bytecode for store distribution
  ios:
    enabled: true
    backend: "bytecode"
```

Publish a release, then a patch:

```bash
fcb release android --release-version 1.0.0+1
# ... change your Dart code ...
fcb patch   android --release-version 1.0.0+1 --patch-number 1
fcb promote --release-version 1.0.0+1 --patch-number 1 --rollout-percentage 10
fcb rollback --release-version 1.0.0+1 --patch-number 1   # stop distribution
```

Integrate the Flutter package:

```dart
import 'package:fcb_code_push/fcb_code_push.dart';

final fcb = FcbCodePush.instance;
await fcb.configure(serverUrl: '...', appId: '...');
await fcb.checkForUpdate();      // downloads patch for next launch
await fcb.markLaunchSuccessful(); // call after first frame renders
```

## Store compliance

- iOS uses the `bytecode` backend only (interpreted code, no downloaded
  executables).
- For Google Play, use `bytecode`; `snapshot_replace` is for internal/enterprise
  distribution only.
- Patches cannot change native code, assets, or the Flutter/Dart/engine version.

## For developers

- Implementation plans: [`plans/`](plans/)
- Architecture decisions: [`docs/architecture_decisions.md`](docs/architecture_decisions.md),
  [`docs/key_rotation_design.md`](docs/key_rotation_design.md),
  [`docs/backends.md`](docs/backends.md)
- Operations: [`docs/operations.md`](docs/operations.md)
- Build from source: `scripts/bootstrap.sh` (initializes `vendor/`), then the
  workflows under `.github/workflows/` and helper scripts under `scripts/`.
