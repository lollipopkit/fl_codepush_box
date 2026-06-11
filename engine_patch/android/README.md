# Android snapshot_replace hook

This directory contains the minimal Engine-side adapter for the FCB P0
`snapshot_replace` backend.

`fcb_engine_hook.cc` does not depend on Flutter Engine headers. It converts the
Rust updater ABI result from `fcb_get_launch_patch()` into a small
`FcbEnginePatchDecision`:

- return `1`: set the Android Flutter Engine AOT artifact path to
  `decision.artifact_path`.
- return `0`: keep the bundled `libapp.so`.
- return `-1`: treat the updater result as invalid and keep the bundled
  artifact or fail closed, depending on the embedder policy.

The intended Engine fork integration point is immediately before Android
configures Dart AOT artifact settings for root isolate launch. When
`use_snapshot_artifact == 1`, wire `artifact_path` into the same setting that
normally points at the bundled `libapp.so`.

Validation:

```sh
c++ -std=c++17 -Wall -Wextra -Werror -Iengine_patch/android \
  engine_patch/android/fcb_engine_hook.cc \
  engine_patch/android/fcb_engine_hook_test.cc \
  -o /tmp/fcb_engine_hook_test
/tmp/fcb_engine_hook_test
```
