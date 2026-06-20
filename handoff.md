**目标**
继续 Phase E:在 VM gate 已通过的基础上,把 Kernel 前端与生成器/stream 语义补到可用于真实业务
patch,最后完成 Android/counter_app 设备验收。当前重点是 P3/P4 的 stream/generator 深覆盖与退出验收。

**硬约束**
- 输出/文档用中文,专业名词可保留英文。
- 工作树很脏且可能有并行 agent;不要回退或清理无关改动。
- audit 必须 source-backed:reader 没产出 `bytecode_source` 就不能放行。
- SDK delta 尽量隔离在 FCB helper/native 和外围 tool,避免扩大官方 Dart SDK 热点 diff。
- 单源码文件目标 1500 行以内;`tool/fcb_kernel_manifest.dart` 约 1488 行,不要继续膨胀。
- `runtime/vm/fcb_patch_runtime_async_star_test.cc` 当前约 1364 行;继续加 runtime case 前优先复用
  `fcb_patch_runtime_stream_test_helpers.h` 或拆新文件。

**已完成**
- P0 VM 验收脚本化且通过:`scripts/test_vendor_vm_runtime.sh` 实际执行 standalone、debug/release FCB VM filters。
- 本轮收敛 SDK delta:`sdk/lib/_internal/vm/lib/async_patch.dart` 的纯格式化差异已移除并更新 index,
  async Dart helper 仍集中在 FCB 专用 `sdk/lib/_internal/vm/lib/fcb_async_patch.dart`;官方 async patch
  文件当前不再出现在 staged/unstaged diff。剩余官方热点已分类:async/vm GNI、libraries
  YAML/JSON、`bootstrap_natives.h`、`vm_sources.gni` 是 FCB 文件/native 注册面;
  `isolate.cc` 是 `PatchRuntime::Clear()` 生命周期 hook;`runtime_offsets_extracted.h` 是
  Thread layout 生成偏移同步文件。新增 `scripts/audit_vendor_dart_sdk_delta.sh` 将该边界脚本化:
  禁止 `async_patch.dart` 带 FCB delta,只允许 FCB-owned path 或已登记的官方注册/生成/hook 文件。
  `scripts/test_vendor_vm_runtime.sh` 已在 VM 编译/测试前调用该 audit,并把
  `sdk_delta_audit` log 写入 `target/fcb/vendor-vm-test/summary.txt`。
  `Makefile` 已新增 `test-vendor-sdk-delta`;`test-vendor-vm-runtime` 继续作为 VM gate 入口。
  `scripts/ci_local_core.sh` 已新增可选 `FCB_LOCAL_CI_VENDOR_VM=1`,会调用
  `make test-vendor-vm-runtime`。
- 本轮补齐 local CI 依赖的 Make targets:`check-workflows`、`check-github-actions-inventory`、
  `check-phase-h-runbooks`,只做本地静态存在性/结构检查,不把远端 GitHub Actions 成功证据伪装成本地完成。
- P1/P2 已有真实 Kernel source 到 IR/module 的 async/await、sync*/async*、loop、yield、部分 `yield*` /
  `await for` lowering,且 reader/audit 保持 fail-closed。
- P3 已覆盖通用 Stream 参数 `yield*` 与 `await for` 多种组合:
  two-stream 正常、第一路/第二路 error、第二路 cancel-after-second;嵌套 generic stream await-for 正常、
  outer/inner error、cancel-after-first、cancel-after-second。本轮把 two-stream 第一/第二路 error 都切到
  data-then-error under `DartListenToFcbStreamEventsWithPauseForTest`,覆盖委派 stream 已 yield data 后
  pause/resume、再进入对应 stream error、外层 finally cleanup yield 后传播原始 error。本轮继续新增 test-only data-then-error stream helper,
  把 nested generic-stream await-for 的 inner/outer error case 都改成先 yield data、首个 data 后
  pause/resume、再触发对应 stream error,最后外层 cleanup yield 后传播原始 error。
- P4 本地 debugger 覆盖新增 `FcbPatchDebuggerCollectsAsyncStarResumeFrame`:async* pending-await
  resume 后 FCB frame 会进入 `DebuggerStackTrace`,并暴露 source location/locals。
- P4 本地 source-stack 覆盖新增 `FcbPatchDebuggerAsyncStarErrorHasSourceStackFrame`:async* stream
  error 路径会把 FCB source location 写入 VM stack trace,并可转成 debugger frame。
- P4 本地 debugger source pause/step 覆盖新增独立文件
  `fcb_patch_runtime_debugger_step_test.cc` 和 filter
  `FcbPatchDebuggerSourceBreakpointAndStepPause`:解释器每条指令前按 source map 上报 active FCB
  frame,测试在 source-mapped offset 处模拟停靠,采集 `DebuggerStackTrace` 的 source
  url/line/column/locals,并继续观察后续 source line step。真正 IDE/VM `BreakpointLocation`
  与 single-step registry 仍未实现。
- P4 本地 GC 覆盖新增 `FcbPatchRuntimeAsyncStarPendingAwaitSurvivesGc`:async* pending-await
  parked frame 经过 compacting GC 后仍可 resume/yield/close。
- P4 本地 finalizer 覆盖新增 `FcbPatchRuntimeSyncStarAbandonedIterableFinalizer` 和
  `FcbPatchRuntimeSyncStarAbandonedIteratorFinalizer`:abandoned sync* Iterable/Iterator 经过
  Dart `Finalizer` 调 `_fcbDropGenerator` 后会清 runtime seed/frame;同步修正
  `Value::VisitObjectPointers` 对 VM null sentinel 的 standalone-safe guard。
- 新增最小真实业务 stream e2e:`tests/e2e/test_kernel_business_stream_e2e.sh` 生成最小
  source plan/module,并用 `FcbPatchRuntimeBusinessStreamSourceE2e` 覆盖 `await ready` + `yield`
  + 通用 Stream `await for` + nested `await for Stream.value(...)` + 通用 Stream 参数
  `yield* delegated` + `yield* Stream.value(...)` + `finally` 的成功、cancel-after-second、
  委派 stream data-then-error under pause/resume cleanup/error 传播,以及先 yield 后 stream error
  的 cleanup/error 传播;本轮把
  error-after-yield case 切到 `DartListenToFcbStreamEventsWithPauseForTest`,首个 data 后 pause/resume
  再验证 finally cleanup yield 与原始 stream error 顺序。
  为此新增独立小 VM test 文件 `fcb_patch_runtime_business_stream_test.cc`,并给 VM `GetField(0x43)`
  增加显式 getter fallback。
- 本轮修正 VM nested finally unwind:`EndFinally(0x66)` 对 pending `kThrow`/`kReturn` 转入外层
  finally/catch 时继续解释,避免把中间 `Ok(null)` 误当成 async* 正常 close;同时保留 async*
  running 中同步 await callback 的 `pending_resume` guard。
- 本轮抽出 FCB stream 测试 helper 到 `runtime/vm/fcb_patch_runtime_stream_test_helpers.h`,复用
  microtask drain、stream builder、source stream listen 断言等 helper;`fcb_patch_runtime_async_star_test.cc`
  从约 1476 行降到 1353 行,`fcb_patch_runtime_business_stream_test.cc` 降到 161 行。
- e2e 断言已拆分到 `tests/e2e/kernel_compile_from_plan/`,stream generator module 断言放在
  `assert_module_stream_generators.py`。
- counter_app widget smoke 已同步当前 source/JIT 预期并通过;它不替代 Android bytecode patch 验收。

**已验证**
- `scripts/test_vendor_vm_runtime.sh`:通过;证据在 `target/fcb/vendor-vm-test/summary.txt`,Dart SDK commit
  `0faa95f739c450d28bb8150ead9d47e05f9a899d`,包含 `FcbPatchRuntimeAsyncStarSourceModuleStreamListen`
  与 `FcbPatchRuntimeGcStress`,并包含 `sdk_delta_audit` 证据;本轮新增 nested generic-stream await-for cancel-after-second 和
  `FcbPatchDebuggerCollectsAsyncStarResumeFrame` /
  `FcbPatchDebuggerAsyncStarErrorHasSourceStackFrame` /
  `FcbPatchDebuggerSourceBreakpointAndStepPause` /
  `FcbPatchRuntimeAsyncStarPendingAwaitSurvivesGc` /
  `FcbPatchRuntimeSyncStarAbandonedIterableFinalizer` /
  `FcbPatchRuntimeSyncStarAbandonedIteratorFinalizer` /
  `FcbPatchRuntimeBusinessStreamSourceE2e` 后已复跑。
- `vendor/flutter/engine/src/out/host_debug_unopt_arm64/run_vm_tests FcbPatchRuntimeSyncStarAbandonedIterableFinalizer`
  和 `... FcbPatchRuntimeSyncStarAbandonedIteratorFinalizer`:通过。
- `vendor/flutter/engine/src/out/host_release_arm64/run_vm_tests FcbPatchRuntimeSyncStarAbandonedIterableFinalizer`
  和 `... FcbPatchRuntimeSyncStarAbandonedIteratorFinalizer`:通过。
- `tests/e2e/test_kernel_business_stream_e2e.sh`:通过,包含 nested await-for、第二个通用
  `yield* delegated` 委派 stream 成功收值、委派 stream data-then-error under pause/resume
  backpressure cleanup/error 顺序,以及真实业务 stream error-after-yield under pause/resume
  backpressure。
- `bash -n tests/e2e/test_kernel_business_stream_e2e.sh`:通过。
- `tests/e2e/test_kernel_compile_from_plan.sh`:通过。
  包含 `asyncGeneratedYieldStarTwoStreamsFinally` 第一/第二路 error under pause/resume backpressure,
  以及 `asyncGeneratedAwaitForNestedStreamFinally` inner/outer data-then-error under pause/resume。
- `scripts/audit_vendor_dart_sdk_delta.sh`:通过,`fcb_or_allowed_delta_count: 27`。
- `make check-github-actions-inventory`:通过。
- `make check-workflows`:通过。
- `make check-phase-h-runbooks`:通过。
- `make test-vendor-sdk-delta`:通过,`fcb_or_allowed_delta_count: 27`。
- `PATH="$PWD/vendor/depot_tools:$PATH" VPYTHON_VIRTUALENV_ROOT="$PWD/target/fcb/vpython-root" ninja -C vendor/flutter/engine/src/out/host_debug_unopt_arm64 run_vm_tests`:
  通过;用于编译新增 `fcb_patch_runtime_debugger_step_test.cc`。直接跑 ninja 时曾因沙箱访问
  `~/Library/Caches/vpython-root...` 被拒,已改用 workspace 内 `VPYTHON_VIRTUALENV_ROOT`。
- `vendor/flutter/engine/src/out/host_debug_unopt_arm64/run_vm_tests FcbPatchDebuggerSourceBreakpointAndStepPause`:通过。
- `FCB_LOCAL_CI_KERNEL=0 FCB_LOCAL_CI_E2E=0 FCB_LOCAL_CI_FLUTTER=0 FCB_LOCAL_CI_NPM_CI=0 FCB_LOCAL_CI_VENDOR_VM=1 FCB_LOCAL_CI_S3=0 scripts/ci_local_core.sh`:
  通过;summary 在 `target/fcb/local-ci-core/summary.txt`,completed steps 包含
  `check-workflows`、`github-actions-inventory`、`phase-h-runbooks` 和 `vendor-vm-runtime`。
- `python3 -m py_compile tests/e2e/kernel_compile_from_plan/assert_*.py`:通过。
- `bash -n` 覆盖 `scripts/audit_vendor_dart_sdk_delta.sh`、`scripts/test_vendor_vm_runtime.sh`
  和两个 Kernel e2e 脚本:通过。
- `git diff --check`:通过。
- `git -C vendor/flutter/engine/src/flutter/third_party/dart diff --check`:通过。
- `git -C vendor/flutter/engine/src/flutter/third_party/dart status --short -- sdk/lib/_internal/vm/lib/async_patch.dart`:无输出。
- `wc -l`: `fcb_patch_runtime_async_star_test.cc` 1364,
  `fcb_patch_runtime_business_stream_test.cc` 161,
  `fcb_patch_runtime_stream_test_helpers.h` 171,`tool/fcb_kernel_manifest.dart` 1488。
- `cd examples/counter_app && ../../vendor/flutter/bin/flutter test test/widget_test.dart`:通过。
- `scripts/check_android_arm64_device.sh`:未完成;卡在 `adb wait-for-device` 后中止,随后 `adb devices` 为空。

**当前状态**
- 根工作树仍有大量 staged/unstaged/untracked 改动,包括并行 agent 可能修改的文件;只碰当前目标相关文件。
- embedded Dart SDK checkout 中本轮新增 `runtime/vm/fcb_patch_runtime_debugger_step_test.cc` 为
  untracked;`runtime/vm/vm_sources.gni` 已接入该 test,但该文件本身已有其它 staged/unstaged 混合改动。
- `tests/e2e/kernel_compile_from_plan/__pycache__/` 是 untracked 测试生成残留;本轮未清理。
- Android acceptance 所需 `vendor/flutter/bin/flutter`、`out/android_release_arm64/libflutter.so`、
  `out/host_release/gen_snapshot` 存在;当前缺 adb device。
- 2026-06-21 复核:`target/fcb/vendor-vm-test/summary.txt` 记录 VM gate 通过;`adb devices` 仍为空。
- `scripts/ci_local_core.sh` 的本地 workflow/runbook Make target 错配已修复;关闭 Kernel/e2e/Flutter/S3
  可选项并启用 `FCB_LOCAL_CI_VENDOR_VM=1` 时,local core CI 已能走到并通过 vendor VM gate。

**下一步**
1. 有 Android 设备/模拟器后先跑 `scripts/check_android_arm64_device.sh`,再跑
   `scripts/accept_android_arm64.sh` 完成 counter_app no-patch / bytecode patch / fallback drill。
2. 无设备时继续 P3/P4 本地项:补更复杂 `yield* stream` 多层 cancel/finally/backpressure
   与多源嵌套 `await for` e2e。
3. 继续补 source stack/debugger parked-frame 深覆盖,以及更复杂 stream 委派/嵌套 await-for
   的 cancel/finally/error 组合。

**完整计划仍缺**
- Android 真机/模拟器退出验收和 interpreter_ratio < 1% 设备证据。
- 更复杂/多层 stream 委派 cancel/finally/backpressure 组合。
- 多层/多源嵌套 `await for` cancel/finally/error 组合。
- P4 的 IDE/VM `BreakpointLocation`/single-step registry、更多 parked-frame 深覆盖与
  counter_app Android 真实 patch 验收。
