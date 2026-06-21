**目标**
继续 Phase E:在保持 SDK delta 独立、reader/audit fail-closed 的前提下,把 host 侧已验证能力推进到
Android/counter_app 与 desktop embedder 的完整退出验收。当前不能标记 Phase E complete。

**硬约束**
- 中文输出/文档;专业名词可保留英文。
- 工作树很脏且可能有并行 agent;不要回退或清理无关改动。
- FCB 改动尽量隔离在自有 helper/native/test/tool;`async_patch.dart` 不应带 FCB delta。
- reader 没产出 `bytecode_source` 时 audit 必 reject,不能误放行。
- 单源码/断言文件目标 1500 行以内,继续用 `make check-kernel-compile-fixture-size` 守。

**已完成**
- Host 侧 Phase E 证据仍通过;VM summary、Kernel compile summary、SDK delta audit 都被
  `make check-phase-e-host-evidence` 覆盖。
- Kernel 前端 P1/P2/P3 当前是“子集/核心闭合,继续扩长尾”:普通 async control-flow、pending
  `await`、collection spread/for/if、runtime collection-for、type-test/cast、mixed callback、
  generator/stream/await-for/yield* 等已有 source/module/binary 或 runtime 覆盖。
- `asyncSubtractValue` / `asyncMultiplyValue` / `asyncDivideValue` 已补普通 async direct binary
  `-` / `*` / `/` → `Sub(0x11)` / `Mul(0x12)` / `Div(0x13)` source/module/binary 覆盖。
- `asyncLogicalFlag` 已补普通 async `&&` / `||` / `!` → conditional IR source/module/binary 覆盖。
- `asyncAlwaysThrow` 已补普通 async direct `throw` expression → `Throw(0x60)` source/module/binary 覆盖。
- `asyncStaticHelperValue` 已补普通 async project `call_static` → `CallStatic(0x50)` source/module/binary 覆盖。
- `asyncConcatLabel` 已补普通 async direct string concat → `StringConcat(0x42)` source/module/binary 覆盖。
- `asyncNullableChoice` 已补普通 async conditional `null` literal → `Null` constant source/module/binary 覆盖。
- `asyncMakeStringBox` 已补普通 async generic `new_object` `Box<String>` → `NewObject(0x55)` source/module/binary 覆盖。
- `asyncAwaitThenReadField` 已补普通 async pending `await` local + `GetField(0x43)` +
  `StringConcat(0x42)` source/module/binary 覆盖。
- `asyncAwaitThenDynamicCall` 已补普通 async pending `await` local + dynamic named
  `CallDynamic(0x51)` source/module/binary 覆盖。
- `asyncAwaitThenMakeStringBox` 已补普通 async pending `await` local + generic
  `NewObject(0x55)` source/module/binary 覆盖。
- `asyncAwaitThenIsString` 已补普通 async pending `await` local + `IsType(0x45)`
  source/module/binary 覆盖。
- `asyncAwaitThenAsStringList` 已补普通 async pending `await` local + `AsType(0x46)`
  source/module/binary 覆盖。
- `asyncAwaitThenSameObject` 已补普通 async pending `await` local +
  `CallOriginal(0x52)` source/module/binary 覆盖。
- `asyncAwaitThenStaticHelperValue` 已补普通 async pending `await` local +
  `CallStatic(0x50)` source/module/binary 覆盖。
- `asyncAwaitThenDirectCallbackMixed` 已补普通 async pending `await` local +
  `CallClosure(0x53)` source/module/binary 覆盖。
- `asyncAwaitThenUpdateConfigLabel` 已补普通 async pending `await` local +
  `SetField(0x44)`/`GetField(0x43)` source/module/binary 覆盖。
- `asyncAwaitThenLocalMutation` 已补普通 async pending `await` local +
  `StoreLocal(0x04)`/`LoadLocal(0x03)` source/module/binary 覆盖。
- `asyncAwaitThenArithmeticValue` 已补普通 async pending `await` local +
  plain `Add(0x10)` source/module/binary 覆盖。
- `asyncAwaitThenSubtractValue` 已补普通 async pending `await` local +
  plain `Sub(0x11)` source/module/binary 覆盖。
- `asyncAwaitThenMultiplyValue` 已补普通 async pending `await` local +
  plain `Mul(0x12)` source/module/binary 覆盖。
- `target/fcb/kernel-compile-from-plan/summary.txt` 当前计数是 `248/263/263`。
- Android acceptance 旧证据显示 `emulator-5554` 上 nopatch/patch 业务值通过,但不能替代当前设备
  preflight。

**最近已验证**
- `dart format tests/e2e/kernel_compile_from_plan/fixtures/release_main_parts/01_core_async.dart tests/e2e/kernel_compile_from_plan/fixtures/patch_main_parts/01_core_async.dart`:通过。
- `python3 -m py_compile tests/e2e/kernel_compile_from_plan/assert_*.py`:通过。
- `make check-kernel-compile-fixture-size`:通过。
- `FCB_KEEP_KERNEL_COMPILE_TEST=1 tests/e2e/test_kernel_compile_from_plan.sh`:通过,summary 为 `248/263/263`。
- `make check-phase-e-host-evidence`:通过。
- `scripts/audit_vendor_dart_sdk_delta.sh`:通过,`fcb_or_allowed_delta_count: 28`。
- `git diff --check`:通过。
- `git -C vendor/flutter/engine/src/flutter/third_party/dart diff --check`:通过。
- `FCB_ADB_TIMEOUT_SECONDS=5 make check-phase-e-completion`:仍 pending,原因是 Android device
  preflight、interpret-failure evidence、interpreter stats 样本、desktop embedder full。

**本轮核对的产物**
- `target/fcb/kernel-compile-from-plan/summary.txt`:仍为 `248/263/263`,Kernel compile-from-plan passed。
- `target/fcb/vendor-vm-test/summary.txt`:standalone FCB runtime passed,SDK pin `0faa95f739c`。
- `target/fcb/phase-e-completion/host-evidence.log`:host evidence passed。
- `target/fcb/phase-e-completion/summary.txt`:仍 pending;host_evidence/pass,
  android_device_preflight/fail,android_acceptance/pass,android_interpret_failure/fail,
  android_interpreter_ratio/fail(`0/0/0.000000`),desktop_embedder_full/fail。

**当前阻塞**
- Android device preflight 失败:`adb wait-for-device` 5s timeout。
- Android interpret-failure fallback evidence 缺失。
- Android interpreter stats 无样本:`0/0/0.000000`,因此 ratio gate fail。
- desktop embedder full 失败在 macOS Metal Toolchain preflight;summary 提示需
  `xcodebuild -downloadComponent MetalToolchain` 后复跑。之前提权安装请求被策略拒绝。

**下一步**
1. 接入可用 Android 真机/模拟器后跑 `make check-android-arm64-device` 与
   `make test-android-arm64-acceptance`,补齐当前设备、fallback、interpreter ratio 样本。
2. Metal Toolchain 安装/修复后跑 `make check-macos-metal-toolchain` 与
   `make test-desktop-embedder-full`。
3. 最后跑 `FCB_ADB_TIMEOUT_SECONDS=5 make check-phase-e-completion`,直到 summary 不再 pending。
4. 非阻塞长尾:继续扩 Kernel 前端组合覆盖,例如更复杂 `while`/`for` update、
   branch-local/await 与 stream/generator cross-product。
