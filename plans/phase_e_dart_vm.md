# Phase E — Dart VM 真正可用

**所属阶段**：关键路径（Production-Ready 的卡脖子）
**预计工作量**：6–10 人月
**前置依赖**：无（Engine embedded Dart SDK 已经把 skeleton 落地，可直接开工）
**并行性**：与 F/G/H 完全独立

## 进度更新（2026-06-18）

🟢 **Phase E 业务级 Android VM patch gate 已通过**。所有 Phase E VM 相关逻辑以 `vendor/flutter/engine/src/flutter/third_party/dart/runtime/vm` 为唯一真源；旧镜像目录和同步脚本已移除，不再作为实现入口。新的 Android arm64 counter_app 证据归档在 `tests/e2e/vm_patch_20260618_104500_widget_method/summary.txt`，覆盖 widget tree 文案、`setState`、plugin MethodChannel `getPaths`、`CallStatic` wrapper、`GetField` 和 restart persistence。`FCB_PLAN_AUDIT_GITHUB_EVIDENCE=0 make audit-plan-completion` 的 Phase E 检查已全部 passed；当前 audit 剩余失败项属于 Phase H vendor submodule / GitHub Actions / 设备发布 / vendor rebase 证据。

| 子阶段 | 状态 | 证据 |
|--------|------|------|
| E1 Value↔ObjectPtr | ✅ VM materialization + GC stress runner 已通过 | Engine embedded Dart 的 `runtime/vm/fcb_patch_runtime.{h,cc}` 已引入 `ObjectPtr` slot、`Value::FromDart` / `ToDart`、递归 `VisitObjectPointers`，并在存在 current Dart mutator thread 时让 `Value::Int/Double/Bool/String/List/Map` materialize 为 VM object roots；standalone 路径保留 scalar fallback。`IsolateGroup` 已新增 `kFcbPatchRuntime` root slice 并 visit patch runtime roots。`Value::Map` 在 VM thread 下通过 `Map._fromKeyValues` factory materialize 为真实 Dart `_Map` object，解释器继续保留 `map_entries` 作为 standalone/map-backed field fallback shadow。`runtime/vm/fcb_patch_runtime_gc_test.cc` 的 `FcbPatchRuntimeGcStress` isolate test 已覆盖 nested `List/String` roots 与 `Map` roots，经 100 次 compact full GC 后仍可解释调用，并断言返回对象 `IsMap()`、length 与 key/value iterator 正确；该 test object 已用 `run_vm_tests_set.fcb_patch_runtime_gc_test.o` 真实 VM build flags 编译通过。`third_party/zlib` 已按 Engine DEPS commit 补齐，arm64 `run_vm_tests` 已成功构建，`out/host_release_arm64/run_vm_tests FcbPatchRuntimeGcStress` 与 `FcbPatchRuntime` 均通过 |
| E2 opcode 集补全 | 🟡 部分完成 | Engine embedded Dart 的 `runtime/vm/fcb_patch_runtime_loader.cc` 已承接 binary `FCBM` reader 与 JSON/binary `source_map`；`runtime/vm/fcb_patch_runtime.{cc,test.cc}` 已支持 `CallStatic` opcode `0x50` 的 patch module 内递归解释执行（含 0 参数、传参、missing target tests）、`CallDynamic` opcode `0x51` 的真实 VM instance method dispatch（positional/named，`Resolver::ResolveDynamicForReceiverClass` + `DartEntry::InvokeFunction`，已用 `String.substring` 和 `Uri.replace(path: ...)` isolate tests 验证）、`CallOriginal` opcode `0x52` 的真实 VM original call（top-level/static positional、class static qualified name、named args、generic function type args，`Library::LookupFunctionAllowPrivate` / `Class::LookupStaticFunctionAllowPrivate` + `TypeArguments` + `ArgumentsDescriptor` + `DartEntry::InvokeFunction` + `ScopedSuppressPatchInvocation`，已用 `dart:core::identical`、`dart:core::class:int.parse`、`dart:core::class:int.parse;named:radix` 和 `dart:core::class:ArgumentError.checkNotNull;types:String` isolate tests 验证）、`CallClosure` opcode `0x53` 的真实 VM closure object 调用（positional/named，`DartEntry::InvokeClosure` + `ScopedSuppressPatchInvocation`，已用 `dart:core::identical` implicit static closure、`Uri.replace(path: ...)` instance tear-off closure 和 named metadata 错误边界 isolate tests 验证）、`MakeClosure` opcode `0x54` 的真实 VM static/top-level implicit closure materialization（`ImplicitClosureFunction` + `ImplicitStaticClosure`，`FcbPatchRuntimeMakeClosure` 已验证 MakeClosure→CallClosure 链路），以及 `MakeClosure target;captures:N` 的内部 bytecode closure materialization（捕获值保存在 `Value::closure_captures`，`CallClosure` 会把 captured context 前置后递归解释目标 bytecode function；`FcbPatchRuntimeReturningBytecodeClosureCapturesContext` 覆盖返回 closure 后再调用并读取 captured `prefix/name`，以及 closure 自身 positional 参数追加在 captured context 之后）、`NewObject` opcode `0x55` 的真实 VM generative/factory constructor 调用（positional/named/generic class type args，constructor id 格式 `libraryUri::class:ClassName.name`，未命名 constructor 用尾随 `.`，class type args 用 `;types:String,...`，named args 用 `;named:name,label` 元数据；`FcbPatchRuntimeNewObject` 已用 `dart:core::class:Object.` 验证 generative，`FcbPatchRuntimeNewObjectFactory` 已用 `dart:core::class:String.fromCharCode` 验证 factory，`FcbPatchRuntimeNewObjectNamedFactory` 已用 `dart:core::class:Uri.;named:scheme,path` 验证 named factory + 后续 dynamic dispatch，`FcbPatchRuntimeNewObjectGeneric` 已用 `dart:core::class:List.filled;types:String` 验证 factory class type args 与返回实例 type arguments）、`Throw` opcode `0x60` 与 `TryBegin` opcode `0x61` 的 interpreter-local try/catch 子集（catch 内恢复 thrown value，未捕获 throw 仍按 interpret failure fallback）、`StringConcat` opcode `0x42`（含 happy / scalar coercion / stack-underflow tests）、`MakeList`/`MakeMap` opcode `0x40`/`0x41`（standalone 与 VM ObjectPtr materialization 路径均已有测试）、`GetField`/`SetField` opcode `0x43`/`0x44`，以及 `IsType`/`AsType` opcode `0x45`/`0x46`。类型检查在 VM 下走 `Instance::IsInstanceOf`，已覆盖 core `Type` object（`int/double/num/bool/String/Object/Null/List/Map`）、`libraryUri::ClassName` 用户类型和 `List<String>` 这类 core generic type args；standalone 下保留 scalar fallback；`FcbPatchRuntimeIsType` 验证真实 VM `int is num`，`FcbPatchRuntimeUserDefinedIsType` 验证真实 VM 用户类型 positive/negative path，`FcbPatchRuntimeGenericIsType*` / `FcbPatchRuntimeGenericAsType*` 验证真实 VM `List<String>` positive/negative 与 `as` failure path。Kernel `StringConcatenation` 已在 `tool/fcb_kernel_manifest.dart` 降级为 `StringConcat 0x42`，普通 `ListLiteral`/`MapLiteral` 已降级为 `MakeList`/`MakeMap`，常量条件 collection-if、动态 collection-if / collection-if-else、静态 list/map spread、参数/表达式运行期 list/map spread、静态源 collection-for、参数/表达式运行期 list/map collection-for 已从 Kernel `BlockExpression` 降级到既有 `MakeList`/`MakeMap` + branch / `CallDynamic(addAll)` / `iterator` + `moveNext` + `current` loop 路径，普通 `InstanceInvocationExpression` 已降级为 `CallDynamic 0x51`，普通 `ConstructorInvocation` 已降级为 `NewObject 0x55`（含 positional/named args/generic class type args），non-escaping zero-arg capturing closure 的立即调用/局部变量调用已降级为 `let` + `StoreLocal 0x04` / `LoadLocal 0x03` + 原 closure body bytecode，同库同步 callback wrapper（单个 function 参数且 body 为 `return callback();`）会内联传入的捕获闭包 body，简单 returning capturing closure 已由 `tool/fcb_kernel_returning_closure.dart` 编译为主函数 `MakeClosure target;captures:N` + synthetic `extra_functions` closure body，覆盖 `return () => ...`、`final format = () => ...; return format;`、`return (suffix) => ...`、局部函数声明 `String format() { ... } return format;`、closure body 内部局部变量、closure body 内部单 `try { return ... } catch (e) { return ... }`，以及捕获对象后在 closure body 内执行 named dynamic call 的形态，简单 `return throw ...` 与单 `catch (e)` 的 `try { return ... } catch (e) { return ... }` 已降级为 `Throw 0x60` / `TryBegin 0x61`，Kernel `is` / `as` 表达式已降级为 `IsType 0x45` / `AsType 0x46`，restricted source 可显式发出 `CallOriginal 0x52` / `CallClosure` `0x53` / `MakeClosure` `0x54` / `NewObject` `0x55` / `AsType` `0x46` / `list` / `map`，`tests/e2e/test_kernel_compile_from_plan.sh` 覆盖 string interpolation/concat、simple list/map literals、常量 collection-if list/map literals、field get、core `is` type check、用户类型 `value is User`、generic `value is List<String>` / `value as List<String>`、普通 `User(...)` positional constructor、`Config(name:..., label:...)` named constructor、`Box<String>(...)` generic constructor、`(() => '$prefix $name')()` / `final format = () => ...; format()` 捕获闭包子集、`escapingGreeting` / `storedEscapingGreeting` / `personalizedEscapingGreeting` / `localFunctionEscapingGreeting` / `bodyLocalEscapingGreeting` / `tryCatchEscapingGreeting` / `dynamicCallEscapingGreeting` returning capturing closure 的 `MakeClosure 0x54` + synthetic `<closure0>()` function、`useCallback(() => '$prefix $name')` 同步 callback wrapper 内联子集、`recoverFromThrow` / `alwaysThrow` try/throw 子集、`['patched', ...extra]` / `{'mode':'patched', ...extra}` 运行期 spread，以及 `['patched', for (final value in extra) value]` / `{'mode':'patched', for (final entry in extra.entries) entry.key: entry.value}` 运行期 collection-for 编译到 JSON/binary bytecode。字段 opcode 在 standalone 下保留 map-backed fallback，在 VM 下已接 `Class::LookupFieldAllowPrivate` + `Instance::GetField/SetField`，并让 `Value::FromDart` 标注 int/double/bool/string scalar kind；把内部 bytecode closure 暴露成 Dart `_Closure`、await continuation / `_FutureImpl` state-machine 恢复、VM unwinder 级 try/catch/throw 仍未完成 |
| E3 编译器 Dart 化 | ✅ 完成 | `tool/fcb_kernel_manifest.dart` 已拆分为 1144 行主编译器、1461 行 `tool/fcb_kernel_reader.dart`、367 行 `tool/fcb_kernel_async_expr.dart`、239 行 `tool/fcb_kernel_returning_closure.dart`、29 行 `tool/fcb_kernel_logical_expr.dart`、38 行 `tool/fcb_kernel_unary_binary_expr.dart`、177 行 `tool/fcb_kernel_statement_expr.dart`、39 行 `tool/fcb_kernel_callback_inline.dart`、106 行 `tool/fcb_kernel_type_names.dart`、116 行 `tool/fcb_kernel_unsupported_audit.dart`、189 行 `tool/fcb_kernel_closure_audit.dart` 与 171 行 `tool/fcb_binary_module_writer.dart`，含 `--compile-from-plan`、opcode emitter（`op(int)`）、binary BytecodeModule 输出和 `debug_locals` 源码变量名 metadata，并已让 Kernel `StringConcatenation` 生成 `StringConcat` `0x42`、Kernel `LogicalExpression` 生成现有 `conditional` + `JumpIfFalse 0x31` / `Jump 0x30`、Kernel `EqualsCall` 生成 `Equal 0x21`、unary `Not` 生成 bool branch、closure body 简单 `if` return 分支、局部变量后接 if-return 尾部和 if/else 分支内局部变量 return 生成 `conditional` / `let`、普通 `ListLiteral`/`MapLiteral` 与常量条件 collection-if 生成 `MakeList`/`MakeMap` `0x40`/`0x41`、简单 `InstanceGet`/`DynamicGet` 生成 `GetField` `0x43`、Kernel `is`/`as` 生成 `IsType` `0x45` / `AsType` `0x46`（含 project `InterfaceType` → `package:...::ClassName` 与 `List<String>` 这类 core generic type args）、普通 positional/named instance call 生成 `CallDynamic` `0x51`、普通 positional/named/generic constructor invocation 生成 `NewObject` `0x55`、无 `await` 的简单 async return / immediate `await Future.value(...)` / immediate await string interpolation / await condition / 语句级 if-return immediate await / ordinary/immediate-await mixed locals + await-local tail if-return 降级为 `NewObject dart:async::class:_Future.value<T>`，non-escaping zero-arg capturing closure 生成 `let` + local load/store，同库同步 callback wrapper 内联传入的捕获闭包 body，简单 returning capturing closure 生成 `MakeClosure 0x54` + synthetic `extra_functions` closure body，static/top-level tear-off `StaticTearOff` / procedure `StaticGet` / `ConstantExpression(StaticTearOffConstant)` 生成 `MakeClosure 0x54`，简单 throw/try-catch 生成 `Throw 0x60` / `TryBegin 0x61`，restricted source 可显式生成 `CallOriginal` `0x52` / named `CallClosure` `0x53` / `MakeClosure` `0x54` / `NewObject` `0x55` / `AsType` `0x46` / `list` / `map`；`crates/fcb_bytecode/src/compiler.rs` 已删除，`lib.rs` 仅剩 `pub mod format;`（schema/reader）。`tests/e2e/test_kernel_compile_from_plan.sh`、`cli/src/bytecode_payload.rs` 已接入 |
| E4 fallback + stack trace | ✅ Host + Android server-backed failure chain + VM StackTrace source location 已验证 | Engine embedded Dart 的 `runtime/vm/fcb_patch_entry.cc` 已在 patch miss / arg mismatch / interpret failure 时记录 AOT fallback，interpret failure 会 disable patch、上报 `fcb_report_interpret_failure(...)` 并返回原 AOT/JIT 路径；解释成功但返回值无法转换回 Dart（例如内部 bytecode closure 逃逸到 Dart 边界）现在也会 disable patch、上报 interpret failure 并返回原 AOT/JIT，而不是向调用者返回 `ApiError`；`FcbPatchEntryFallsBackOnEscapingBytecodeClosure` 已覆盖 unique bridge 下 escaping bytecode closure 返回 false 且 patch 进入 `kDisabledBadPatch`。`updater` FFI test 已验证 interpret failure 写入 `state.bad_patches`、记录 reason、POST `/v1/events` `crash_rollback`；`scripts/test_crash_rollback.sh` 已验证三次启动失败回 LKG。`scripts/test_android_interpret_failure.sh` 已在 emulator-5554 验证 runtime `Return stack underflow` patch 被注册后 fallback 到 baseline（`1/8/7/base/base-field/10`）、无新增 tombstone，并把 patch 1 写入设备 `state.bad_patches`；state reason 含 `interpret_failure:... (FCB patch)`。server-backed run 已验证 `patch_events` 有 `crash_rollback` 行，payload 含 `function_id`、`error_message`、`bytecode_offset`。`runtime/vm/object.cc::StackTrace::ToCString()` 现在会追加 FCB patch source location stack，`FcbPatchRuntimeStackTraceSourceLocation` isolate test 已验证真实 VM `StackTrace` 文本含 `package:app/bad.dart:9:3` 与 `FCB patch`；`runtime/vm/debugger.cc` 的 `DebuggerStackTrace::From(StackTrace)` 现在会把 `StackTrace.code_array` 中的 FCB `String` marker 转为 `ActivationFrame::kFcbPatch`，service JSON 输出 `FcbPatchSourceLocation`（`sourceUri`/`line`/`column`），避免异常 StackTrace 进入 debugger/service 时被静默跳过；`DebuggerStackTrace::Collect()` 也会把当前 thread-local FCB source location stack 追加为 live `ActivationFrame::kFcbPatch`，让 debugger/service live stack 能看到正在解释的 patch frame；live FCB frame 现在携带 `function_id` 与 `bytecode_offset`，`QualifiedFunctionName()` 返回 patch function id，service JSON 输出 `fcbPatchFunctionId` / `fcbPatchBytecodeOffset`；FCB pseudo frame 的 `SourceUrl` / `LineNumber` / `ColumnNumber` / locals / receiver / rewindability 现在有安全返回，`EvaluateCompiledExpression` 会按 `SourceUrl()` 查找 library 并进入该 library 的 top-level expression context，找不到 library 时明确返回 `ApiError`，避免 `Dart_ActivationFrameInfo` / service evaluate 这类 frame API 查询时触发普通 Dart frame 断言。嵌套 bytecode closure 解释失败时现在保留 inner closure body 与 outer caller 两个 FCB patch location，`FcbPatchRuntimeReturningBytecodeClosureCapturesContext` 已验证未捕获 closure throw 记录 `package:app/closure.dart:77:5` 和 caller `package:app/closure.dart:101:3` 两帧，同时验证被 caller-side `TryBegin` 捕获的 closure throw 会清理 FCB patch location stack，避免污染后续 `StackTrace` 文本 |
| E5 性能上报 | ✅ 完成 | VM entry 已调用 `fcb_record_interpreter_call()` / `fcb_record_aot_call()`；`updater/src/lib.rs` 暴露 `fcb_get_interpreter_stats` 并接入事件字段；counter_app evidence 记录 `interpreter_ratio: 0.0`，低于 1%。CLI 侧 `fcb inspect patch` 会显示基于 `linker_plan.interpret / (interpret + unchanged)` 的 estimated interpreter ratio；自动 bytecode patch 生成会在 ratio 超过 5% 时把 warning 写入 `patch_report.messages` 并输出到 stderr，10/100 interpreted functions 的高比例用例已由 `patch_report_tests::automatic_bytecode_payload_warns_when_many_functions_are_interpreted` 覆盖 |
| Vendor VM test gate | ✅ 完成 | `scripts/test_vendor_vm_runtime.sh` 会编译并运行 standalone `FcbPatchRuntime`，已生成 `target/fcb/vendor-vm-test/summary.txt`；`make audit-plan-completion` 已识别 `E vendor VM tests: runtime/vm/fcb_patch_runtime_test evidence present` |
| Android counter_app e2e | ✅ 业务级 widget/setState/MethodChannel drill 已通过 | `examples/counter_app` 已新增 `PricingOffer` / `fieldStatusLabel(PricingOffer)`、`widgetTreeLabel()` 与 UI 行 `Widget tree: ...`，并用 `vm:entry-point` 保留 AOT metadata。`scripts/accept_android_arm64.sh` / `scripts/test_android.sh` 要求 7 项 contract：nopatch `1/8/7/base/baseline widget tree/base-field/10`，patch `42/42/42/patched/patched widget tree/patched-field/42`。真实设备运行已通过：`target/fcb/android-widget-method-acceptance/summary.txt` 记录 `setState_observed: true` 与 `methodChannelCacheDir_observed: /data/user/0/com.example.fcb_counter_app/code_cache/fcb`；`scripts/install_android_bytecode_patch.sh` 的 `_phaseDWidgetTreeLabel` 通过 `CallStatic 0x50` 调用 `widgetTreeLabel`，`fieldStatusLabel` 通过 `GetField 0x43` 读取 `patchLabel`；restart run `target/fcb/android-widget-method-restart/result.txt` 证明 force-stop 后 patch 仍 active。归档证据：`tests/e2e/vm_patch_20260618_104500_widget_method/summary.txt` |

**当前校正**：`CallDynamic 0x51` 已从 positional-only 扩展为 positional/named
instance dispatch，method id 使用 `method;named:name,...` 元数据，VM 侧通过
`ArgumentsDescriptor` 调用真实 Dart instance method。`FcbPatchRuntimeCallDynamicNamed`
已用 `Uri.replace(path: ...)` 验证 named dispatch；compile-from-plan drill 已验证
普通 named instance call 生成 `CallDynamic 0x51` 和 `surround;named:prefix,suffix`
常量。

**本轮新增**：`tool/fcb_kernel_manifest.dart` 已支持 Kernel `ConditionalExpression`
降级为 `JumpIfFalse 0x31` + `Jump 0x30`，`tests/e2e/test_kernel_compile_from_plan.sh`
新增 `chooseLabel(bool enabled) => enabled ? ... : ...`，并在 JSON/binary module 中
断言 `0x31`/`0x30`。主编译器后续已增长到 1016 行，`tool/fcb_binary_module_writer.dart`
为 156 行。

**最新增量**：动态 collection-if / collection-if-else 已支持。Kernel 将
`['a', if (enabled) 'b' else 'x', 'c']` /
`{'a': '1', if (enabled) 'b': '2' else 'b': 'x', 'c': '3'}`
降成 `BlockExpression`，编译器现在会把动态 `if` 降级为
`conditional`，分别生成完整 then/else `MakeList 0x40` / `MakeMap 0x41`
分支，并复用 `JumpIfFalse 0x31` + `Jump 0x30`。`tests/e2e/test_kernel_compile_from_plan.sh`
已覆盖 `names(bool enabled, bool premium)` 与 `labels(bool enabled, bool premium)`
的多个动态 collection-if。
同时，Kernel reader 源码已从 `tool/fcb_kernel_manifest.dart` 的 raw string
拆到 `tool/fcb_kernel_reader.dart`，type name 解析拆到
`tool/fcb_kernel_type_names.dart`；当前又把 unsupported 边界扫描拆到
`tool/fcb_kernel_unsupported_audit.dart`，同库同步 callback wrapper 内联拆到
`tool/fcb_kernel_callback_inline.dart`，并新增
`tool/fcb_kernel_returning_closure.dart` 承接 returning capturing closure 子集；
`tool/fcb_kernel_logical_expr.dart` 承接 Kernel `LogicalExpression` 降级；
`tool/fcb_kernel_unary_binary_expr.dart` 承接 Kernel `EqualsCall` 与 unary `Not`
降级；`tool/fcb_kernel_statement_expr.dart` 承接 return/try helper；
`tool/fcb_kernel_async_expr.dart` 承接无 `await` async return 到 `_Future.value` 的降级。主编译器当前
1132 行，reader 为 1461 行，async helper 为 362 行，returning closure helper 为 234 行，
logical helper 为 29 行，unary/binary helper 为 38 行，statement helper 为 172 行，
callback inline helper 为 39 行，type name helper 为 106 行，unsupported audit 为 116 行，closure audit 为 189 行，所有源码文件保持在
1500 行上限内。
**spread / collection-for 增量**：Kernel 将 list/map spread 降为 `addAll(...)`，
将 collection-for 降为 `iterator` + `moveNext()` + `current` 的嵌套 `Block`。
编译器现在支持源表达式可静态降级为 `list` / `map` 的 spread，以及
`for (final value in ['a', 'b']) value` / `for (final entry in {'k': 'v'}.entries) entry.key: entry.value`
这类静态源 collection-for，会直接展开到 `MakeList 0x40` / `MakeMap 0x41`
的元素序列中。`tests/e2e/test_kernel_compile_from_plan.sh` 已覆盖 list/map
spread、静态源 collection-for 与动态 collection-if 的组合。新增运行期 spread
支持会把 `['patched', ...extra]` / `{'mode': 'patched', ...extra}` 降级为
`MakeList 0x40` / `MakeMap 0x41` + `StoreLocal 0x04` + `CallDynamic 0x51`
调用 `addAll` + `LoadLocal 0x03`，`tests/e2e/test_kernel_compile_from_plan.sh`
已覆盖 JSON/binary module 中的 `0x51`、`0x03`、`0x04` 与 `addAll` 常量。
新增运行期 collection-for 支持会把 `['patched', for (final value in extra) value]`
和 `{'mode': 'patched', for (final entry in extra.entries) entry.key: entry.value}`
降级为 `StoreLocal 0x04` / `LoadLocal 0x03`、`CallDynamic 0x51`
调用 `get:iterator` / `moveNext` / `get:current`，list 侧调用 `add`，
map 侧调用 `get:entries` / `get:key` / `get:value` / `[]=`
完成 append。`tests/e2e/test_kernel_compile_from_plan.sh` 已覆盖 JSON/binary module
中的循环 opcode 与动态调用常量。
**generic is/as 增量**：`tool/fcb_kernel_type_names.dart` 现在负责 Kernel
type name 解析，能保留 `List<String>` 这类 core generic type args；
`runtime/vm/fcb_patch_runtime_vm.cc::ResolveType` 会解析顶层 generic
参数、递归 canonicalize `TypeArguments` 并构造 finalized VM `Type`，
因此 `IsType 0x45` / `AsType 0x46` 不再把 `List<String>` 退化为 `List`。
新增 `runtime/vm/fcb_patch_runtime_type_test.cc` 覆盖 `List<String>`
positive/negative、`as List<String>` 成功和失败路径，并已纳入
`vm_sources.gni`。`tests/e2e/test_kernel_compile_from_plan.sh` 已验证
`value is List<String>` / `value as List<String>` 生成 JSON/binary bytecode
中的 `0x45` / `0x46` 与 `List<String>` 常量。
**CallOriginal 增量**：`runtime/vm/fcb_patch_runtime_vm.cc::ResolveOriginalFunction`
现在支持 `libraryUri::class:ClassName.method` 形式的 class static target，
优先按 VM class 内静态函数名 `method` 查找，并兼容旧的 `ClassName.method`
symbol；`DartCallOriginal` 会解析 `;named:name,...` 元数据并构造
`ArgumentsDescriptor`，也会解析 `;types:Type,...` 元数据、构造 canonical
`TypeArguments` 并作为 generic function type arguments 传给 VM，再执行参数数量和类型检查。新增
`runtime/vm/fcb_patch_runtime_call_original_test.cc` 覆盖
`dart:core::class:int.parse` 与 `dart:core::class:int.parse;named:radix`，
`dart:core::class:ArgumentError.checkNotNull;types:String`，以及错误
type argument count、too many named args、malformed `;types:String,` 边界；
同时确认既有 `dart:core::identical` top-level original call 未回归。
**CallDynamic named args 增量**：`runtime/vm/fcb_patch_runtime_vm.cc::DartInstanceCallDynamic`
现在会解析 `method;named:name,...`，为 named instance call 构造
`ArgumentsDescriptor` 并继续通过 `Resolver::ResolveDynamicForReceiverClass`
和 `DartEntry::InvokeFunction` 调用真实 Dart method。新增
`runtime/vm/fcb_patch_runtime_call_dynamic_test.cc` 覆盖
`Uri(path: "old").replace(path: "new").toString()`，以及 too many named args /
unknown named args 两条错误边界；同时保留既有 `FcbPatchRuntimeCallDynamic`
的 `String.substring` positional path。
**CallClosure named args 增量**：`CallClosure 0x53` 的保留 operand 现在支持
非零 named metadata index（`constants[operand - 1]`，值形如 `;named:path`），
旧 operand `0` positional-only bytecode 保持兼容。`DartCallClosure` 会为 named
closure invocation 构造 `ArgumentsDescriptor` 并通过
`DartEntry::InvokeClosure(thread, args, descriptor)` 调用真实 Dart closure。
新增 `runtime/vm/fcb_patch_runtime_call_closure_test.cc`，用 `Uri(path: "old")`
的 `replace` instance tear-off closure 验证 `CallClosure ;named:path` 返回
`new`，并覆盖 malformed metadata、too many named args 两条错误边界；同时保留既有
`FcbPatchRuntimeCallClosure` / `FcbPatchRuntimeMakeClosure` positional path。
同文件新增 `FcbPatchRuntimeMakeClosureRejectsMissingTarget`，覆盖真实 VM 下
`MakeClosure 0x54` 指向不存在 top-level/static target 时返回
`MakeClosure failed: function not found`；新增
`FcbPatchRuntimeTryCatchesMakeClosureMissingTarget`，验证相同 VM closure 构造失败
在 active `TryBegin` handler 内会进入 catch value，而不是直接作为解释器错误返回。
**NewObject metadata/error boundary 增量**：新增
`runtime/vm/fcb_patch_runtime_new_object_test.cc`，覆盖 constructor named metadata
多于实参数量时的 `too many named constructor arguments`，以及
`;types:String,` 这类 malformed generic type metadata 触发 `empty type argument`。
同时保留既有 `FcbPatchRuntimeNewObjectNamedFactory` named factory happy path。
**async / unsupported boundary 增量**：`tool/fcb_kernel_async_expr.dart`
现在支持无 `await` 的简单 async return 子集、`return await Future.value(value)` 的 immediate await 子集、
`return 'prefix ${await Future.value(value)}'` 这类 string interpolation 内 immediate await 子集、`if (await Future.value(condition)) ...` 的 await condition 子集、语句级 if-return 内 immediate await 子集，以及 `try { final base = ...; final x = await Future.value(base); if (...) return '$x ${await Future.value(...)}'; return ...; } catch (e) { return ...; }` 的 ordinary/immediate-await mixed locals + await-local tail if-return 子集，把
`Future<T> f() async { return value; }` / `Future<T> f() async { return await Future.value(value); }` / `Future<T> f() async { return '${await Future.value(value)}'; }` / `Future<T> f(bool b) async { if (await Future.value(b)) return await Future.value(value); return other; }` / `Future<T> f() async { try { final x = await Future.value(value); if (ok) return '$x ${await Future.value(other)}'; return '$x fallback'; } catch (e) { return fallback; } }` 降级为
`NewObject 0x55` 调用 `dart:async::class:_Future.value;types:T`，返回一个已完成的
VM `Future` 实例；`FcbPatchRuntimeNewObjectFutureValue` 已验证真实 VM 下
`_Future.value<String>` constructor path 可执行。真正挂起的 `await` continuation 仍未实现。
`tool/fcb_kernel_unsupported_audit.dart` 仍会把未降级的 async/await、function type
`is/as` 与 record type `is/as` 分类为 `async_await_unsupported`、
`function_type_unsupported`、`record_type_unsupported`。`crates/fcb_core::RejectReason`
和 CLI patch report 已能反序列化并保留这些结构化原因；
`tests/e2e/test_kernel_compile_from_plan.sh` 覆盖 `asyncLabel()`、`awaitedLabel()` 的 await condition + 语句级 if-return immediate await string interpolation 与 `awaitedLocalLabel()` 的 ordinary/immediate-await mixed locals + await-local tail if-return 进入 `interpret` 并生成
`_Future.value<String>` bytecode，`awaitedLocalLabel()` 同时包含 `TryBegin 0x61`、至少两个 `StoreLocal 0x04`、`JumpIfFalse 0x31` 与 `StringConcat 0x42`；`value is String Function()` 与
`value is (String, int)` 继续不生成 `bytecode_source` 并进入 `reject`。
**returning closure 增量**：`tool/fcb_kernel_returning_closure.dart` 现在会把简单
返回捕获闭包编译为内部 bytecode closure，覆盖直接返回闭包、返回局部闭包变量、带位置参数的返回闭包、带 named 参数的返回闭包、局部函数声明返回、closure body 局部变量、closure body 单 catch `try/catch`、closure body 中的 `LogicalExpression`、`EqualsCall` 与 unary `Not` 降级为既有 `conditional` / `Equal 0x21` / bool 分支、closure body 简单 `if` return 分支、局部变量后接 if-return 尾部、if/else 分支内局部变量 return 降级为 `conditional` / `let`，以及捕获对象后在 closure body 内执行 named dynamic call，例如
`String Function() escapingGreeting(String name) { final prefix = 'patched'; return () => '$prefix $name'; }`。
以及 `String Function() storedEscapingGreeting(String name) { final prefix = 'patched'; final format = () => '$prefix $name'; return format; }`。
以及 `String Function(String) personalizedEscapingGreeting(String name) { final prefix = 'patched'; return (suffix) => '$prefix $name $suffix'; }`。
以及 `String Function({required String suffix}) namedEscapingGreeting(String name) { final prefix = 'patched'; return ({required suffix}) => '$prefix $name $suffix'; }`。
以及 `String Function() localFunctionEscapingGreeting(String name) { final prefix = 'patched'; String format() { return '$prefix $name'; } return format; }`。
以及 `String Function(String) dynamicCallEscapingGreeting(String name) { final greeter = Greeter(); return (suffix) => greeter.surround(name, prefix: 'patched-', suffix: suffix); }`。
以及 `String Function(bool,bool) logicalEscapingGreeting(String name) { final prefix = 'patched'; return (enabled, premium) => enabled && (premium || name == 'vip') || !enabled ? '$prefix $name pro' : '$prefix $name basic'; }`。
以及 `String Function(bool) ifElseEscapingGreeting(String name) { final prefix = 'patched'; return (enabled) { if (enabled) { return '$prefix $name enabled'; } return '$prefix $name disabled'; }; }`。
以及 `String Function(bool) bodyLocalIfElseEscapingGreeting(String name) { final prefix = 'patched'; return (enabled) { final suffix = 'body'; if (enabled) { return '$prefix $name $suffix enabled'; } return '$prefix $name $suffix disabled'; }; }`。
以及 `String Function(bool) branchLocalIfElseEscapingGreeting(String name) { final prefix = 'patched'; return (enabled) { if (enabled) { final status = 'branch-enabled'; return '$prefix $name $status'; } else { final status = 'branch-disabled'; return '$prefix $name $status'; } }; }`。
它会为主函数生成 `MakeClosure target;captures:N`，并把 synthetic
`<closure0>()` 写入 `bytecode_source.extra_functions`。`tests/e2e/test_kernel_compile_from_plan.sh`
已验证 `escapingGreeting` / `storedEscapingGreeting` / `personalizedEscapingGreeting` / `namedEscapingGreeting` / `localFunctionEscapingGreeting` / `bodyLocalEscapingGreeting` / `tryCatchEscapingGreeting` / `dynamicCallEscapingGreeting` / `logicalEscapingGreeting` / `ifElseEscapingGreeting` / `bodyLocalIfElseEscapingGreeting` / `branchLocalIfElseEscapingGreeting` 不再有 `unsupported_reasons`，JSON/binary module 中包含主函数
`0x54`、`0x03`、`0x04`、`...::<member>.<closure0>();captures:2` 常量，以及
对应 `<closure0>()` synthetic function；`personalizedEscapingGreeting.<closure0>()`
的 synthetic function 参数顺序为 captured `prefix/name` 后接 closure 参数 `suffix`。
`dynamicCallEscapingGreeting` 额外验证主函数中 `NewObject 0x55` materialize `Greeter()`，synthetic closure 中 `CallDynamic 0x51` 调用 `surround;named:prefix,suffix`。
`logicalEscapingGreeting` 额外验证 synthetic closure 中 `&&` / `||` 被降级为 `JumpIfFalse 0x31` + `Jump 0x30` 的 nested conditional，`name == 'vip'` 生成 `Equal 0x21`，`!enabled` 生成 bool true/false 常量和分支，JSON/binary module 中包含 `vip`、`pro`、`basic` 常量。
`ifElseEscapingGreeting` 额外验证 closure body 中 `if (enabled) return ...; return ...;` 被降级为 `JumpIfFalse 0x31` + `Jump 0x30` 的 conditional，synthetic closure 中包含 `enabled` 参数、`StringConcat 0x42` 以及 `enabled` / `disabled` 常量。
`bodyLocalIfElseEscapingGreeting` 额外验证 closure body 中局部变量 `suffix` 会先降级为 `StoreLocal 0x04`，随后 if-return 尾部降级为 conditional，synthetic closure 中包含 `LoadLocal 0x03`、`JumpIfFalse 0x31`、`Jump 0x30`、`StringConcat 0x42` 以及 `body` / `enabled` / `disabled` 常量。
`branchLocalIfElseEscapingGreeting` 额外验证 then/else 分支内部局部变量 `status` 分别降级为 branch-local `StoreLocal 0x04` / `LoadLocal 0x03`，synthetic closure 中包含 `branch-enabled` / `branch-disabled` 常量。
当前 VM runtime 已新增内部 bytecode
closure context materialization 子集：`MakeClosure` target 可带 `;captures:N` 元数据，
解释器会从栈上保存 captured values 到 `Value::closure_captures`，`CallClosure` 调用该内部
closure 时把 captured context 前置、再追加调用实参给目标 bytecode function 并递归解释；bytecode closure 的 `;named:` metadata 现在会校验 named 参数数量，避免 named 元数据多于实参时静默继续；递归解释前也会按目标 bytecode function 的 `parameter_count` 校验 captured + call args 总数，避免参数过少/过多时落到较弱的下层错误；递归解释失败现在也会走 caller-side active handler，因此 bytecode closure 内部 `Throw` 可被调用方 `try/catch` 捕获；未捕获的嵌套 bytecode closure 解释错误会把 inner closure body 和 outer caller 的 source-map location 都追加到 FCB patch location stack；内部 bytecode closure body 的 `JumpIfFalse 0x31` / `Jump 0x30`、`StoreLocal 0x04` / `LoadLocal 0x03` 与 `StringConcat 0x42` 组合已由 VM runner 覆盖；内部 bytecode closure 也已可作为 `Value` 参数跨 bytecode function 传递，再由 callee `CallClosure` 调用。
`FcbPatchRuntimeReturningBytecodeClosureCapturesContext` 已验证返回 closure 后再调用仍能读取
captured `prefix/name`，验证 closure 自身 positional/named 参数追加在 captured context 之后，并覆盖 bytecode closure named metadata 过多、调用参数过少/过多、bytecode closure throw 被 caller-side `try/catch` 捕获、未捕获 closure throw 同时记录 `package:app/closure.dart:77:5` body frame 与 `package:app/closure.dart:101:3` caller frame、branch-local conditional closure true/false 两条路径，以及 bytecode closure 作为参数跨函数传递后再调用的边界。
`Value::List` / `Value::Map` 现在会检测内部 bytecode closure；一旦容器内含
`ValueKind::kBytecodeClosure`，不会提前 materialize 成 Dart Array/Map，避免递归
`ToDart()` 把 bytecode closure 静默伪装成 `null`。VM helper 参数转换统一走
`TryMaterializeDartObject`，`CallOriginal` / `CallDynamic` / `CallClosure` /
`NewObject` / `IsType` / instance field helper 遇到 bytecode closure 会显式失败并
fallback，而不是把它作为 `null` 传进 Dart 层；`FcbPatchRuntimeRejectsBytecodeClosureDartMaterialization`
已验证 `CallOriginal dart:core::identical(closure, null)` 不再返回 true，而是报
`bytecode closure cannot be materialized as Dart _Closure yet`。
最新安全补丁还封住了 direct `Value::ToDart()` 绕过路径：`MaterializeDartObject`
遇到 `ValueKind::kBytecodeClosure` 或包含 bytecode closure 的 `List` / `Map` 会返回
`nullptr`，不会缓存成 `Object::null()` 或生成含 `null` 的 Dart 容器；
`FcbPatchRuntimeBytecodeClosureToDartDoesNotBecomeNull` 已覆盖 closure / List / Map
三种直接 materialization 入口。
入口返回值转换也已接入相同安全边界：解释器返回 `ValueKind::kBytecodeClosure`
给 Dart 调用方时，`fcb_patch_entry.cc` 会 disable patch、上报 failure 并让当前调用
fall through 到原 AOT/JIT；`FcbPatchEntryFallsBackOnEscapingBytecodeClosure`
已验证 escaping closure 不再变成 Dart `ApiError`。
同步 wrapper 内联仍只覆盖不会真正逃出当前同步调用的子集；
把内部 bytecode closure 作为 Dart `_Closure` 暴露给应用层仍未完成。
已尝试过一个零捕获 closure trampoline 原型（synthetic native parent function +
implicit static closure），但当前 host VM runner 未启 `DART_DYNAMIC_MODULES`，动态创建的
closure function 不能 attach `implicit_static_closure_bytecode()`，会回落到不存在的
Kernel body 并在 `KernelReaderHelper::ReportUnexpectedTag` FATAL；该原型已回退，后续
不能重复简单 synthetic native `Closure::New` / implicit closure 方案，必须走 VM 支持的
trampoline/code 安装或真实 Dart patch/private external trampoline。
**static/top-level tear-off 增量**：`tool/fcb_kernel_reader.dart` 已把
`StaticTearOff`、procedure `StaticGet` 和
`ConstantExpression(StaticTearOffConstant)` 降级为 `make_closure`。因此
`String Function() topLevelTearOff() => stableTearOffLabel;` 现在会生成
`MakeClosure 0x54`，常量目标为
`package:fcb_kernel_compile_test/main.dart::stableTearOffLabel`。
`DART_BIN=vendor/flutter/bin/dart tests/e2e/test_kernel_compile_from_plan.sh`
已验证 JSON/binary module 中包含该函数、`0x54` 与对应目标常量。这个增量覆盖的是
非捕获 static/top-level tear-off；capturing closure 当前覆盖简单 returning closure、
closure body 内局部变量、closure body 内单 catch `try/catch`、closure body logical/equality/not、closure body 简单 `if` return 分支、局部变量后接 if-return 尾部、if/else 分支内局部变量 return 和同步 wrapper 内联子集。
**try/throw 增量**：Engine embedded Dart 的 `runtime/vm/fcb_patch_runtime.cc`
新增 `Throw 0x60` 与 `TryBegin 0x61`，解释器用 handler stack 支持
interpreter-local 的 `try { return ... } catch (e) { return ... }` 子集：
catch handler 会收到 thrown value，try 正常路径会跳过 catch，未捕获 throw
仍返回 interpret failure 并走既有 fallback。`runtime/vm/fcb_patch_runtime_try_test.cc`
覆盖 caught throw、try fallthrough、catch exception value、uncaught throw 和
invalid handler target；该文件已加入 `vm_sources.gni` 与
`scripts/test_vendor_vm_runtime.sh`。`tool/fcb_kernel_reader.dart` /
`tool/fcb_kernel_manifest.dart` 已将简单 `return throw ...` 与单 catch
降级到 `0x60` / `0x61`，`tests/e2e/test_kernel_compile_from_plan.sh`
已覆盖 JSON/binary module 中的 `0x60` / `0x61`。当前又让 active
`TryBegin` 覆盖 VM helper 调用失败路径：`CallDynamic` / `CallOriginal` /
`CallStatic` 递归解释失败、`CallClosure` / `MakeClosure` / `NewObject`
在 handler 内不再直接解释失败；如果 helper 返回真实
Dart `Error` object，则把该 VM object 作为 catch value 交给 handler，否则才回退为
错误文本；`FcbPatchRuntimeTryCatchesCallDynamicException` 用
`"abc".substring(10)` 验证 `CallDynamic` 抛出的真实 VM `Error` object 可被
active handler catch；`FcbPatchRuntimeTryCatchesCallOriginalException`
已用 `ArgumentError.checkNotNull<String>(null)` 验证真实 VM call exception
能以真实 `Error` object 被 bytecode catch；
`FcbPatchRuntimeTryCatchesMakeClosureMissingTarget` 覆盖 missing VM closure target
构造失败被 active handler catch；`FcbPatchRuntimeTryCatchesCallClosureException` 用 `int.parse` closure 验证
`CallClosure` 抛出的真实 VM `Error` object 可被 active handler catch；
`FcbPatchRuntimeTryCatchesNewObjectException` 用
`List.filled<String>(2, 1)` 验证 `NewObject` argument type check 产生的真实
VM `Error` object 可被 catch。`AsType 0x46` mismatch 现在也会在 active handler
存在时进入 catch，`FcbPatchRuntimeTryCatchesAsTypeMismatch` 覆盖
`List<int> as List<String>` 的 interpreter-local catch value。caught bytecode closure
throw 现在会清理 FCB patch location stack，避免被捕获的 patch frame 泄漏到后续
`StackTrace::ToCString()`；当前又把同一清理 contract 扩展为回归断言：
`CallDynamic` / `CallOriginal` / `CallClosure` / `MakeClosure` / `NewObject` /
`AsType` 在 active handler 内被 catch 后，`PatchStackTraceLocationCount()==0`，
避免被捕获的 VM helper 异常污染后续 `StackTrace` / debugger frame。未捕获路径仍保留
inner/caller source-map frame。
异常对象上的 `StackTrace` 转 debugger/service 展示路径已能保留 FCB patch frame；
live stack frame collection 已能附加 FCB pseudo frame，基础 frame info API 已安全可查；
FCB pseudo frame 的 expression evaluation 入口现在已接入 source library context：
active interpreter frame 现在会从 `debug_locals` 导出源码变量名 locals（缺失时回退
`argN` / `localN`）并注入
`BuildParameters`，`EvaluateCompiledExpression` 会用
`SourceUrl()` 查找 library 并调用 VM 既有 `Instance::EvaluateCompiledExpression` 的
top-level 路径；source library 缺失时返回明确 `ApiError`，避免 service 在 FCB frame
上误走普通 Dart frame 并触发断言。当前 captured context 仍只通过 closure synthetic
function 参数表达，还没有完整 captured-context scope metadata，因此真正闭包上下文级
evaluate 停靠帧、exception handler unwinder 仍未完成。
live FCB frame 的 thread-local stack 现在保存 `function_id` / `source_location` /
`bytecode_offset` 结构，而不是只有 source location 字符串；`DebuggerStackTrace::Collect()`
构造的 `ActivationFrame::kFcbPatch` 会暴露 `QualifiedFunctionName()==function_id`，
service JSON 也会输出 `fcbPatchFunctionId` 与 `fcbPatchBytecodeOffset`。异常
`StackTrace` 中旧的 String marker 路径仍兼容为匿名 `<fcb patch>` frame。
解释器执行期间也会维护独立 active frame stack，`FcbPatchDebuggerCollectsActiveInterpreterFrame`
通过 `UpdateActivePatchFrame` 测试回调在 bytecode 正在执行时调用
`DebuggerStackTrace::Collect()`，验证 active `ActivationFrame::kFcbPatch` 可见且 offset
随当前指令更新；该测试也验证 active frame 的 `NumLocalVariables()`、`VariableAt()` 与
`BuildParameters()` 能看到当前参数/register locals 快照；正常返回后 active frame
stack 清空。`FcbPatchDebuggerCollectsCapturedClosureActiveFrame` 进一步覆盖
`MakeClosure target;captures:2` 进入内部 bytecode closure body 时的 active frame：
`DebuggerStackTrace::Collect()` 可同时看到 caller 与 closure body 两个 FCB frame，closure
body 栈顶 frame 通过 `debug_locals` 把 captured `prefix` / `name` 与 closure 参数 `suffix`
按源码名暴露给 `VariableAt()` / `BuildParameters()`；active frame 还会携带
`captured_argument_count`，`ActivationFrame` / service JSON 暴露
`fcbPatchCapturedSlotCount`，用于区分 synthetic closure function 参数列表中前置的
captured context slots 与真实 closure 调用参数。当前又新增 `fcbPatchArgumentCount`
与结构化 `fcbPatchScope` service JSON，按 captured / arguments / locals 三段输出变量
区间和源码变量名列表，避免 debugger/service 只能看到一条平铺 locals 数组。这证明当前 synthetic closure
参数形态下 captured context 已可在 active FCB frame 中观察，并具备基础 scope
分段 metadata。当前还新增 `fcbPatchVars`，以 `FcbPatchBoundVariable` 形式输出每个变量的
`name` / `slot` / `scope` / `valueMaterialized` / `valueKind` / `valuePreview`，让 service/debugger 不依赖普通 Dart frame
的 service object-id 路径也能消费 FCB 变量清单。`fcbPatchVars` 的 kind/materialized/preview
现在来自原始 `fcb::Value`，不是从 materialized Dart `Object` 反推；因此内部 bytecode
closure 这类不能物化为 Dart `_Closure` 的 local 不会被误报成 `null`，而是显示为
`valueMaterialized=false,valueKind=bytecode_closure`。最新 debugger/unwinder 安全边界补丁让
`ActivationFrame::HandlesException()` 对 `ActivationFrame::kFcbPatch` 直接返回 false，
并由 `FcbPatchDebuggerStackTraceFromStringFrame` 断言 `GetHandlerFrame()` 不会把 FCB
pseudo frame 当成普通 VM catch handler，避免 service 在 exception pause / handler-frame
查找时对 FCB frame 访问普通 Dart `code().exception_handlers()` 并触发断言。仍未完成的是
VM Context/Scope 对象级 captured context metadata、真正 pause/evaluate 可停靠帧，以及
让 FCB bytecode handler 参与 VM exception unwinder 的完整语义。

**结论**：真实 Android counter_app AOT VM patch 已通过增强业务 contract（`1/8/7/base/baseline widget tree/base-field/10` → `42/42/42/patched/patched widget tree/patched-field/42`），并有 `setState`、plugin MethodChannel、`CallStatic`、`GetField`、restart persistence 证据。`make audit-plan-completion` 已识别 `E end-to-end VM patch` 通过。Android server-backed 解释失败 fallback 也已通过。VM GC stress test 已落地并通过 arm64 `run_vm_tests` runner 验证，E1 的完整 runner 阻塞已解除。真实 Dart StackTrace source location 注入已由 VM isolate test 覆盖，异常 `StackTrace` 进入 `DebuggerStackTrace::From` / service JSON 时也会保留 FCB patch pseudo frame，live `DebuggerStackTrace::Collect()` 也会追加当前 FCB patch pseudo frame，FCB pseudo frame 的基础 frame info API 已安全可查，service evaluate 入口已接入 source library top-level context 并对缺失 library fail-closed；已有 closure object 的 positional/named 调用已由 `CallClosure 0x53` 覆盖，static/top-level closure materialization 已由 VM `MakeClosure 0x54` 和 compiler `StaticTearOff` / `StaticGet` / `ConstantExpression(StaticTearOffConstant)` 降级覆盖，内部 bytecode closure context 已由 `MakeClosure ;captures:N` + `Value::closure_captures` + `CallClosure` 递归解释覆盖返回后再调用以及 closure positional 参数调用的子集；generative/factory constructor positional/named/generic class type args 已由 `NewObject 0x55` 覆盖，`_Future.value<String>` 已由 `NewObject 0x55` 覆盖无 `await` async return、immediate `await Future.value(...)`、immediate await string interpolation、await condition、语句级 if-return immediate await、ordinary/immediate-await mixed locals 和 await-local tail if-return 的已完成 Future 子集；non-escaping zero-arg capturing closure、同库同步 callback wrapper 内联、直接 returning capturing closure、返回局部闭包变量、带位置参数、局部函数声明、closure body 局部变量、closure body 单 catch `try/catch`、closure body logical/equality/not、closure body 简单 `if` return 分支、局部变量后接 if-return 尾部、if/else 分支内局部变量 return 与捕获对象后 named dynamic call 的 returning capturing closure 已由 compile-from-plan JSON/binary drill 覆盖；interpreter-local try/throw 子集、`AsType` mismatch catch 子集与 VM helper 调用失败 catch 子集已由 VM runner 与 compile-from-plan drill 覆盖，`CallDynamic` / `CallOriginal` / `CallClosure` / `NewObject` 的真实 Dart `Error` object 均可作为 catch value，caught bytecode closure throw 不再泄漏 FCB source-map frames，未捕获 bytecode closure throw 仍保留 inner/caller 两帧，`MakeClosure` missing VM target 会作为解释器错误文本 catch value；function/record type 等未支持语义已有显式 reject contract，带真正挂起 `await` 的 async continuation 仍显式 reject；Dart `_Closure` 暴露、await continuation / `_FutureImpl` state-machine 恢复、exception handler unwinder / 带 locals/captured context 的真正 debugger pause/evaluate 可停靠帧仍未完成。

**debugger locals 校正（2026-06-18）**：共享 bytecode schema、binary writer、
VM JSON/binary loader 与 compiler 已接入可选 `debug_locals` metadata；active FCB
debugger frame 会优先显示源码变量名（例如 `enabled` / `base` / `prefix`），缺失时才
回退 `argN`/`localN`，并由 `VariableAt()` 与 `BuildParameters()` 暴露。内部 bytecode
closure 的 captured context 目前作为 synthetic closure function 的前置参数暴露，
`FcbPatchDebuggerCollectsCapturedClosureActiveFrame` 已验证 captured `prefix` / `name`
和 closure 参数 `suffix` 在 active frame 中均以源码名可见。仍未完成的是完整 captured
context scope metadata、让 FCB bytecode handler 参与 VM exception unwinder 的完整语义，
以及真正 VM pause/evaluate 可停靠帧；当前 FCB pseudo frame 在 debugger handler 查找
中已 fail-closed，不再被误当作普通 Dart handler frame。

**设备重跑修复（2026-06-18）**：`scripts/check_android_arm64_device.sh`
确认 `emulator-5554` 是 primary `arm64-v8a`。此前 Android release build
在 x86_64 `gen_snapshot` 的 Rosetta 路径崩于
`runtime/vm/cpuinfo_macos.cc:42: error: unreachable code`；已在唯一真源
`vendor/flutter/engine/src/flutter/third_party/dart/runtime/vm/cpuinfo_macos.cc`
把 macOS 缺失 sysctl 字段处理为 feature miss / empty field，并重建
`vendor/flutter/engine/src/out/android_release_arm64/{libflutter.so,clang_x64/gen_snapshot,gen_snapshot}`。
当前 target `libflutter.so` 与 `gen_snapshot` 的 Dart snapshot version 均为
`62afbf8b4e531310474eb5318d12f671`，`scripts/test_android.sh` 会在 build 前校验
target snapshotter 与 `libflutter.so` 的 hash 一致，避免再次混用不同 Dart VM artifact。

## ✅ 方向性问题已修复（2026-06-18）：bytecode 安装校验三处分叉，生产路径断裂

**原症状（实现错误）**：`fcb patch` 实际下发的是 **binary FCBM** bytecode（`cli/src/main.rs:780`
`validate_compiled_bytecode_payload` 原样返回二进制；`tests/e2e/test_e2e.sh:268` 断言
`payload[:4]==b"FCBM"`）。但设备端真正的安装路径
`fcb_download_and_install_blocking → download_and_install → install_payload_with_baseline
→ validate_payload_contract → validate_bytecode_module_payload`（`crates/fcb_core/src/state.rs:490`）
仍然是 `serde_json::from_slice(payload)` —— **只认 JSON**，且 `decode_opcode` 只认最初 ~16 个
opcode（`0x01–0x41,0xff`），不认 `0x42 StringConcat`/`0x43 GetField`/`0x45 IsType`/`0x50 CallStatic`/
`0x52 CallOriginal`/`0x55 NewObject` 等编译器现已产出的 opcode。
→ **真实编译出来的 bytecode patch 在设备上会在 install 阶段被直接拒绝，VM 根本拿不到字节。**

**为什么测试是绿的（覆盖盲区）**：
- `tests/e2e/test_e2e.sh` 的 `--install` 只装 android `snapshot_replace`（binary_diff）patch；iOS bytecode patch 只构建并断言 FCBM，从不经更新器安装。
- `crates/fcb_core/src/state_tests.rs:612/715/777` 安装的是**手写 JSON**、且只用 `[LoadConst,Return]` 旧 opcode 的 payload。
- `scripts/install_android_bytecode_patch.sh` 绕过更新器：手写 **JSON** payload + 手写 `state.json`，`adb push` 直接塞进 `code_cache/fcb`（line 225/280/310）。它验证的是 VM loader，不是 install 路径。

**根因（方向性）**：
1. **bytecode schema/opcode 真理被复制成三份**（CLI 的 `fcb_bytecode::format`、更新器的 `fcb_core::state`、VM 的 `fcb_patch_runtime_loader`），其中更新器那份既旧又窄，已经漂移。
2. **crate 分层不允许复用**：`fcb_bytecode` 依赖 `fcb_core`（`crates/fcb_bytecode/Cargo.toml:8`），所以 `fcb_core::state` 无法反向复用规范实现 → 被迫手抄 → 漂移。`updater/Cargo.toml` 甚至不依赖 `fcb_bytecode`。
3. **更安全更深的问题：更新器根本不该在 install 时做 opcode 级语义校验。** 热更新的全部价值是「不发版即可下发新 Dart 语义（含新 opcode）」。把 opcode 白名单编进已发布的 App 更新器，意味着**编译器一旦新增 opcode，所有线上旧设备都会在 install 阶段拒绝该 patch，反而强制发版**——正好打掉系统的立身之本。opcode 语义的唯一权威必须是 VM，且 VM 已具备「不认就 disable patch + fallback AOT + 上报 crash_rollback」的安全网（见 E4）。

**正确方向**：
- 更新器 install 契约收敛为：验签（安全边界）＋ payload sha256（完整性）＋ 最小信封校验（magic/version，「看起来是不是一个 bytecode module」）。然后落盘交给 VM。
- VM 作为 opcode 唯一权威，未知 opcode/结构异常/解释错误一律 disable patch + 回 AOT + 上报（E4 已实现），实现优雅降级（坏一个 patch 回滚），而不是 install 硬拒甚至逼迫发版。
- 消除漂移：把共享 schema（`BytecodeModule` reader + opcode 表 + binary/JSON）下沉到 **CLI 与更新器都能依赖** 的 crate。由于 `fcb_bytecode` 现依赖 `fcb_core`，干净做法是把 format 模块并入 `fcb_core::bytecode`（它只用到 `err`/`Result`），`fcb_bytecode` 重导出或删除；`state.rs` 改为调用同一份 reader 做信封级校验。

**修复结果**：
- `crates/fcb_core/src/bytecode.rs` 成为 Rust 侧共享 BytecodeModule schema/reader；`crates/fcb_bytecode/src/format.rs` 仅 `pub use fcb_core::bytecode::*`，CLI 与 updater 不再维护两份 Rust opcode/schema。
- `crates/fcb_core/src/state.rs::validate_bytecode_module_payload` 改为 `BytecodeModule::from_slice_envelope(payload)`：同时接受 binary FCBM 和 JSON，只做 envelope 级校验，不再执行 install-time opcode allowlist。
- `BytecodeModule::from_slice` 仍保留 full validation 给 CLI/authoring 使用；新增 `from_slice_envelope` 给 updater 使用，保证线上旧 updater 不因未来 opcode 被迫拒绝安装。
- `FORMAT_VERSION` 已升到 2，`MIN_SUPPORTED_MODULE_VERSION` 保持 1；Rust reader 与 VM binary loader 仅在 version>=2 时读取 `debug_locals`，Rust `to_binary_vec` / Dart binary writer 生产路径始终产出当前 v2 布局，v1 binary 只作为 legacy reader 输入保持旧布局，避免 additive 字段原地破坏 v1。
- `crates/fcb_core/src/state_tests.rs` 新增真实 binary FCBM install 回归，覆盖 `GetField 0x43` + `CallStatic 0x50`；并新增 unknown opcode payload 安装成功测试，证明 opcode 语义留给 VM fallback。
- `tests/e2e/test_e2e.sh` 新增 iOS bytecode `promote` + `check --install --platform ios --arch arm64` 分支，验证真实 binary FCBM payload 经 updater install 后落盘且不生成 snapshot artifact。
- 额外修复 e2e 暴露的工具问题：`tool/fcb_kernel_closure_audit.dart` 避免 fallback Kernel 下递归访问未绑定 `interfaceTarget`；`cli/src/auto.rs` + `tool/fcb_kernel_manifest.dart` 用 `FCB_KERNEL_TOOL_DIR` 固定 snapshot 运行时 helper 文件目录。

**验证证据**：
- `cargo test --workspace`：通过，覆盖 CLI / fcb_core / fcb_bytecode / updater / rollback events。
- `cd server && go test ./...`：通过。
- `FCB_BIN=target/debug/fcb SERVER_BIN=target/debug/fcb_server tests/e2e/test_e2e.sh`：通过，输出 `=== Check --install iOS bytecode ===` / `installed patch into .fcb/cache-ios-bytecode` / `=== All e2e tests passed ===`。
- `cargo test -p fcb_core`：通过，覆盖 v1 legacy binary 无 `debug_locals` 可读、v2 `debug_locals` round-trip、writer 始终产当前 `FORMAT_VERSION`、unknown opcode install、modern opcode binary install。
- `DART_BIN=vendor/flutter/bin/dart tests/e2e/test_kernel_compile_from_plan.sh`：通过，JSON/binary compile-from-plan 产出 v2 FCBM。
- `scripts/test_vendor_vm_runtime.sh`：通过，standalone VM loader 覆盖 v1 FCBM source_map 与 v2 FCBM `debug_locals`。
- 仓库根直接运行 `go test ./...` 仍不是有效命令：根目录不是 Go module，应在 `server/` 下运行。

> 给另一个 code agent 的执行 prompt 见仓库根对话 / 本节末尾「Agent Prompt」。

## 目标

把 `vendor/flutter/engine/src/flutter/third_party/dart/runtime/vm/fcb_patch_runtime.{h,cc}` 从 plain-struct skeleton 升级为能解释真实业务 Dart 代码的 in-VM interpreter，并在解释失败时安全 fallback 到原 AOT。验收标准是 counter_app 真实业务级 patch（修改 widget tree、调用 setState、调用 plugin method channel）能正确运行。

## 现状（必读，开工前确认）

Engine embedded Dart HEAD = `1b88776798d`，commit `022e0730047` 提供的能力：

| 文件 | 行数 | 角色 |
|------|------|------|
| `runtime/vm/fcb_patch_runtime.{h,cc}` / `runtime/vm/fcb_patch_runtime_value.cc` | 172 + 1489 + 109 | Value/InterpretResult 数据结构、PatchState 枚举、基础 opcode interpreter、ObjectPtr root visit、内部 bytecode closure context、debug local metadata、bytecode closure 参数数量边界校验、bytecode closure 容器 materialization guard、interpreter-local try/throw handler stack、active handler 内 bytecode `CallStatic` 递归失败、VM helper 调用失败与 `AsType` mismatch 转 catch value、嵌套 bytecode 解释错误追加 FCB source location stack，caught throw 清理 FCB source location stack，解释执行期间 active debugger frame offset/locals 更新 |
| `runtime/vm/fcb_patch_runtime_internal.h` / `runtime/vm/fcb_patch_runtime_vm.cc` | 122 + 1480 | VM ObjectPtr materialization、真实 Dart Map factory materialization、Dart instance field/dynamic/original/closure/type-check/new-object helper、bytecode closure named metadata helper、bytecode closure Dart materialization 显式拒绝边界、direct `ToDart()` bytecode closure/null-伪装 guard、真实 Dart Error object catch value 输出、FCB patch source location stack trace metadata、active FCB patch frame arguments/register locals 快照与 function metadata 指针；standalone fallback helper |
| `runtime/vm/fcb_patch_runtime_loader.cc` | 774 | JSON/binary BytecodeModule 加载、source_map / debug_locals reader |
| `runtime/vm/fcb_patch_entry.{h,cc}` | 103 + 835 | DispatchDecision、与 stub_code 的 ABI 桥；解释成功但返回值不能转换回 Dart 时 disable patch 并 fall through 到 AOT |
| `runtime/vm/fcb_patch_api.{h,cc}` | 33 + 47 | Engine-facing `LoadPatchRuntimeForIsolateGroup` / `ClearPatchRuntimeForIsolateGroup` |
| `runtime/vm/fcb_patch_runtime_test.cc` / `runtime/vm/fcb_patch_runtime_debugger_test.cc` / `runtime/vm/fcb_patch_runtime_bytecode_closure_test.cc` / `runtime/vm/fcb_patch_runtime_try_test.cc` / `runtime/vm/fcb_patch_runtime_type_test.cc` / `runtime/vm/fcb_patch_runtime_call_original_test.cc` / `runtime/vm/fcb_patch_runtime_call_dynamic_test.cc` / `runtime/vm/fcb_patch_runtime_call_closure_test.cc` / `runtime/vm/fcb_patch_runtime_new_object_test.cc` / `runtime/vm/fcb_patch_runtime_gc_test.cc` | 1500 + 643 + 623 + 232 + 154 + 249 + 171 + 374 + 159 + 111 | standalone/VM 单测，覆盖 loader、source map、CallStatic、CallDynamic positional/named 与 named args 错误边界、CallOriginal top-level/class static/named args/generic function type args、内部 bytecode closure captured context 与 closure positional/named 参数调用、bytecode closure named metadata 与参数数量错误边界、bytecode closure branch-local conditional true/false 路径、bytecode closure 作为参数跨 bytecode function 传递后再调用、bytecode closure throw 被 caller-side active handler catch 且 caught path 清理 FCB source location stack、bytecode closure Dart materialization 显式拒绝边界、direct `ToDart()` bytecode closure/List/Map 不变成 `null`、escaping bytecode closure 返回 Dart 边界时的 disable + AOT fallback、嵌套 bytecode closure 未捕获错误记录 inner body 与 caller 两个 source location、异常 StackTrace 的 FCB String frame 转 `DebuggerStackTrace` / service JSON 的非 PRODUCT 覆盖、live `DebuggerStackTrace::Collect()` 追加当前 FCB patch frame、active interpreter frame 暴露源码名/debug local 快照并注入 `BuildParameters`、captured bytecode closure active frame 暴露 captured `prefix` / `name` 与 closure 参数 `suffix` 源码名、真实 Dart Error object catch value 子集与 metadata 错误边界、CallClosure positional/named 与 named metadata 错误边界、MakeClosure happy path、missing target 错误边界与 active handler catch missing target、caught VM helper / `AsType` exception 不泄漏 FCB patch stack location、NewObject generative/factory/named factory/generic class type args、`_Future.value<String>` 已完成 Future 子集与 metadata 错误边界、StringConcat、interpreter-local TryBegin/Throw、active handler catch bytecode `CallStatic` 递归 throw、active handler catch `CallDynamic` / `CallOriginal` / `CallClosure` / `MakeClosure` / `NewObject`、active handler catch `AsType` mismatch、map-backed GetField/SetField、core/user-defined/generic IsType/AsType、GC root stress、真实 VM StackTrace source location 和错误路径 |
| `runtime/vm/compiler/stub_code_compiler_{arm,arm64,x64,ia32,riscv}.cc` | +900 | 全架构 dispatch stub |
| `runtime/vm/runtime_entry.cc` / `runtime_entry_list.h` | +439 | runtime entry 注册 |

**头文件现状（fcb_patch_runtime.h:1–10）已更新为 VM root 状态**：
> "The runtime owns the bytecode and source-map loader, the interpreter core, and VM ObjectPtr roots for values materialized while a Dart mutator thread is current."

也就是说 dispatch 链路已经打通，`Value` 已不再只是 plain C++ scalar；在 VM mutator thread 存在时会 materialize 为 Dart heap object root。standalone test 仍保留 scalar fallback，以便不依赖完整 VM runner 验证 bytecode 语义。

## 子阶段

### E1 — Value ↔ ObjectPtr 集成（2–3 人月）

**任务**

- 把 `struct Value` 从 plain C++ 升级为持有 `ObjectPtr`（指向 Dart heap 上的真实对象）。
- 修改 `Value::Int / Double / Bool / String / List / Map` 的工厂，在 current `Thread::Current()->isolate_group()` 下 allocate Dart 对象。
- 实现 `Value::FromDart(ObjectPtr)` 与 `Value::ToDart()` 双向转换，用于参数传入和返回值传出。
- 把 `BytecodeModule::Load` 中的 constant pool 改为分配 Dart object（String/Int 直接走 `Smi::New` / `String::New`）。
- 在 `IsolateGroup` 上注册 `FcbPatchRuntime*` 字段，纳入 `IsolateGroup::VisitObjectPointers` 让 GC 扫描 root（避免 GC 移动后悬挂指针）。
- 升级 `fcb_patch_runtime_test.cc`：现有用例从 plain Value 改为构造 Dart 对象，验证 GC 一次后 patch 仍可调用。

**关键文件**

- `vendor/flutter/engine/src/flutter/third_party/dart/runtime/vm/fcb_patch_runtime.h:30–80`（`enum ValueKind` 与 `struct Value`）
- `vendor/flutter/engine/src/flutter/third_party/dart/runtime/vm/fcb_patch_runtime.cc`（Value 工厂 + ModuleLoader）
- `vendor/flutter/engine/src/flutter/third_party/dart/runtime/vm/isolate.cc` / `isolate.h`（添加 `fcb_patch_runtime_` 成员）
- `vendor/flutter/engine/src/flutter/third_party/dart/runtime/vm/program_visitor.cc`（snapshot 路径上的 visit）

**验收**

- 现有 478 行 test 全部以 ObjectPtr 形式重写，通过。
- 新增 GC stress test：`FcbPatchRuntimeGcStress` 连续 100 次 compact full GC + patch 调用，验证 runtime constants 中的 nested Dart `List/String` 与 `Map` ObjectPtr roots 经 `IsolateGroup::VisitObjectPointers` 后仍可解释调用；`ninja -C vendor/flutter/engine/src/out/host_release_arm64 flutter/third_party/dart/runtime/bin:run_vm_tests` 已编译 `run_vm_tests_set.fcb_patch_runtime_gc_test.o`，`out/host_release_arm64/run_vm_tests FcbPatchRuntimeGcStress` 已通过。
- `scripts/test_vendor_vm_runtime.sh` 的 standalone `FcbPatchRuntime` 绿。

---

### E2 — Opcode 集补全（2–3 人月）

**任务**

按业务覆盖优先级顺序实现。每条 opcode 增量做：interpreter case + 单测 + 编译器侧产生（E3 提供 stub）。

| 优先级 | opcode | 覆盖语义 | 难度 |
|--------|--------|---------|------|
| P0 | `call_static` | 已支持 patch module 内 static/top-level function 递归解释执行；外部原函数调用由 `CallOriginal` 覆盖 | 中 |
| P0 | `call_dynamic` | 已支持 positional/named instance method dispatch，走 `Resolver::ResolveDynamicForReceiverClass` + `DartEntry::InvokeFunction`；`FcbPatchRuntimeCallDynamic` 用真实 Dart `String.substring` 验证，`FcbPatchRuntimeCallDynamicNamed` 用 `Uri.replace(path: ...)` 验证 | 高 |
| P0 | `call_original` | 已支持 top-level/static positional、class static qualified name、named args 和 generic function type args 原函数调用，走 `Library::LookupFunctionAllowPrivate` / `Class::LookupStaticFunctionAllowPrivate` + `TypeArguments` + `ArgumentsDescriptor` + `DartEntry::InvokeFunction`，并用 `ScopedSuppressPatchInvocation` 跳过 FCB hook；`FcbPatchRuntimeCallOriginal` 用 `dart:core::identical` 验证，`FcbPatchRuntimeCallOriginalClassStatic` / `FcbPatchRuntimeCallOriginalNamed` / `FcbPatchRuntimeCallOriginalGeneric` 分别用 `int.parse`、`radix` 与 `ArgumentError.checkNotNull<String>` 验证，错误边界覆盖 wrong type arg count、too many named args、malformed type metadata | 高 |
| P0 | `get_field` / `set_field` | 已有 `GetField`/`SetField` opcode `0x43`/`0x44` 语义、schema 与 compiler 入口；VM 路径已接 `LookupFieldAllowPrivate` + `Instance::GetField/SetField`，standalone 路径保留 map fallback；Android arm64 field-aware device evidence 已通过 | 中 |
| P0 | `string_concat` / `string_interp` | `StringConcat` opcode `0x42` 已接入 runtime；Kernel `StringConcatenation` 已由 compiler 降级到同一 opcode，覆盖字符串插值/拼接的当前 restricted bytecode 路径 | 低 |
| P1 | `make_closure` / `call_closure` | `CallClosure 0x53` 已支持调用已有 closure object 的 positional/named 参数；`MakeClosure 0x54` 已支持 static/top-level implicit closure，并覆盖 missing target 错误边界与 active handler catch missing target；`MakeClosure target;captures:N` 已支持内部 bytecode closure context，并由返回后再调用、closure positional 参数调用、branch-local conditional closure true/false 路径，以及 bytecode closure 作为参数跨 bytecode function 传递后再调用的 VM runner test 覆盖；non-escaping zero-arg capturing closure 已在 compiler 侧降级到 let/local bytecode；同库同步 callback wrapper 会内联传入的 capturing closure body；简单 Kernel returning capturing closure 已编译为内部 bytecode closure + synthetic extra function，覆盖直接 `return () => ...`、`final format = () => ...; return format;`、`return (suffix) => ...`、局部函数声明 `String format() { ... } return format;`、closure body 内部局部变量、closure body 内单 catch `try/catch`、closure body logical/equality/not、closure body 简单 `if` return 分支、局部变量后接 if-return 尾部、if/else 分支内局部变量 return 与捕获对象后 named dynamic call；bytecode closure 的 Dart 物化入口已拆到 `runtime/vm/fcb_patch_runtime_closure.cc` 并由 `TryMaterializeBytecodeClosure` fail-closed 承接，direct `ToDart()` 也不会把 bytecode closure/List/Map 伪装成 `null`；后续 VM trampoline / `Function` / `Closure` / `Context` 逻辑应落在该文件；真正 Dart `_Closure` 暴露和更完整闭包语义仍待实现 | 高 |
| P1 | `is_type` / `as_type` | 已支持 core type、`libraryUri::ClassName` 用户类型与 `List<String>` 这类 generic type arguments 检查/转换；VM 路径走 `Instance::IsInstanceOf`，standalone 路径保留 scalar fallback；function/record type 仍限制在 unsupported 边界 | 中 |
| P1 | `try_catch` / `throw` | `Throw 0x60` / `TryBegin 0x61` 已支持 interpreter-local 单 catch 子集；active handler 内的 bytecode `CallStatic` 递归失败和 VM helper 调用失败可进入 catch value，真实 Dart `Error` object 会作为 catch value 保留，`MakeClosure` missing target 这类解释器错误文本也可作为 catch value；`AsType` mismatch 在 active handler 下也可进入 catch value；未捕获的嵌套 bytecode closure throw 会保留 inner body 与 caller 两个 FCB source location，被捕获的 bytecode throw 会清理 FCB source location stack；VM unwinder 与 Dart stack unwinding 对象级协作仍待实现 | 高 |
| P1 | `await` / `async_resume` | 无 `await` 的 async return、immediate `await Future.value(...)`、immediate await string interpolation、await condition、语句级 if-return immediate await、ordinary/immediate-await mixed locals 和 await-local tail if-return 已能生成 `_Future.value<T>`；真正挂起的 `await` continuation 与 `_FutureImpl` state machine 恢复仍未实现 | 极高 |
| P2 | `new_object` | 已支持 generative/factory constructor positional/named/generic class type args 调用与返回新 instance；constructor id 格式 `libraryUri::class:ClassName.name`，未命名 constructor 用尾随 `.`，class type args 通过 `;types:String,...` 生成 canonical `TypeArguments`，named args 通过 `;named:name,label` 元数据进入 VM `ArgumentsDescriptor`；字段初始化增强待扩展 | 中 |
| P2 | `list_lit_extended` / `map_lit_extended` | simple list/map literals、常量/动态条件 collection-if、静态 list/map spread、参数/表达式运行期 list/map spread、静态源 collection-for、参数/表达式运行期 list/map collection-for 已降级为 `MakeList`/`MakeMap` + `CallDynamic(addAll)` / iterator loop；更复杂嵌套 body 仍按 unsupported 处理 | 中 |

**关键文件**

- `vendor/flutter/engine/src/flutter/third_party/dart/runtime/vm/fcb_patch_runtime.cc` 的 `Interpret()` 主循环（当前 16 个 case）
- `vendor/flutter/engine/src/flutter/third_party/dart/runtime/vm/dart_entry.cc`（已加入 6 行 hook，开放给 `call_original`）
- `vendor/flutter/engine/src/flutter/third_party/dart/runtime/vm/runtime_entry.cc`（+430 行，已经有 FCB runtime entry 注册框架）

**验收**

- 每条 opcode 至少 3 个单测（happy path、boundary、error）。
- 集成测试：构造一个手写 BytecodeModule，覆盖一条 patched widget `build()` 方法，包含 setState、字符串插值、call_original，端到端跑通。

---

### E3 — 编译器 Dart 化（1–2 人月）

**任务**

扩展 `tool/fcb_kernel_manifest.dart`（当前 455 行，只输出 inventory）：

- 新增 CLI 子命令 `--compile-from-plan plan.json --patch patch.dill -o module.fcbm`。
- 用 `package:kernel` 的 `Visitor<void>` 遍历 `Member.function.body`，把 `Statement` / `Expression` 翻译为 E2 定义的 opcode 序列。
- 输出 binary 格式严格对齐 `fcb_patch_runtime.h::BytecodeModule`（magic + version + constant pool + function table + instructions），用 `package:typed_data` 写 `Uint8List`。
- constant pool 复用：相同字面量去重。
- 遇到 unsupported Kernel node（reflection、`extension` static dispatch 等）→ 输出 `RejectReason::UnsupportedKernelNode` 到 stderr，CLI 侧收集进 `patch_report.json`。
- 删除 `crates/fcb_bytecode/src/compiler.rs`；`format.rs` 缩为 schema 校验 + 反序列化（给 `fcb inspect` 用）。
- CLI 侧 `cli/src/main.rs::automatic_bytecode_payload` 改为 spawn Dart 工具，读 binary 输出。

**关键文件**

- `tool/fcb_kernel_manifest.dart`（扩展）
- `cli/src/main.rs:713–749`（`automatic_bytecode_payload` / `bytecode_payload_from_inventories`）
- `cli/src/main.rs:962–971`（`compile_or_read_bytecode_module`，简化为 read 模式）
- `crates/fcb_bytecode/src/lib.rs`（裁剪）

**当前增量验收**

- `tests/e2e/test_kernel_compile_from_plan.sh`：`String chooseLabel(bool enabled) => enabled ? ... : ...` 产生包含 `JumpIfFalse` `0x31` 与 `Jump` `0x30` 的 JSON/binary module；`logicalEscapingGreeting(String name)` 返回的 escaping closure body 中 `enabled && (premium || name == 'vip') || !enabled ? ... : ...` 会生成 nested `conditional`，synthetic `<closure0>()` function 的 JSON/binary bytecode 中包含至少三个 `JumpIfFalse 0x31` 和 `Jump 0x30`，并包含 `Equal 0x21`、`vip` 常量与 unary `Not` 的 bool true/false 分支。
- `tests/e2e/test_kernel_compile_from_plan.sh`：`ifElseEscapingGreeting(String name)` 返回的 escaping closure body 中 `if (enabled) { return ...; } return ...;` 会生成 synthetic `<closure0>()` function，JSON/binary bytecode 中包含 `JumpIfFalse 0x31`、`Jump 0x30`、`StringConcat 0x42` 以及 `enabled` / `disabled` 常量。
- `tests/e2e/test_kernel_compile_from_plan.sh`：`bodyLocalIfElseEscapingGreeting(String name)` 返回的 escaping closure body 中 `final suffix = 'body'; if (enabled) { return ...; } return ...;` 会生成 synthetic `<closure0>()` function，JSON/binary bytecode 中包含 `StoreLocal 0x04` / `LoadLocal 0x03`、`JumpIfFalse 0x31`、`Jump 0x30`、`StringConcat 0x42` 以及 `body` / `enabled` / `disabled` 常量。
- `tests/e2e/test_kernel_compile_from_plan.sh`：`branchLocalIfElseEscapingGreeting(String name)` 返回的 escaping closure body 中 then/else 分支分别声明 `final status = ...` 后 return，会生成 branch-local `let`，JSON/binary bytecode 中包含多个 `StoreLocal 0x04` / `LoadLocal 0x03`、`JumpIfFalse 0x31`、`Jump 0x30`、`StringConcat 0x42` 以及 `branch-enabled` / `branch-disabled` 常量。
- 当前 compile-from-plan drill 为 39 个 interpreted functions、2 个 rejected functions、51 个 binary functions；`asyncLabel()` 的无 `await` async return、`awaitedLabel(bool enabled)` 的 await condition + 语句级 if-return immediate await string interpolation 和 `awaitedLocalLabel()` 的 ordinary/immediate-await mixed locals + await-local tail if-return 已进入 interpret，function type 与 record type 用例继续留在 reject，`logicalEscapingGreeting`、`ifElseEscapingGreeting`、`bodyLocalIfElseEscapingGreeting` 与 `branchLocalIfElseEscapingGreeting` 已进入 interpret。
- `tests/e2e/test_kernel_compile_from_plan.sh`：`List<String> names(bool enabled, bool premium)` 与 `Map<String,String> labels(bool enabled, bool premium)` 的多个动态 collection-if-else、静态 list/map spread、静态源 collection-for 产生包含多个 `JumpIfFalse` `0x31` / `Jump` `0x30` 以及 `MakeList` `0x40` / `MakeMap` `0x41` 的 JSON/binary module；`dynamicNames(List<String> extra)` 与 `dynamicLabels(Map<String,String> extra)` 的运行期 spread 产生 `CallDynamic 0x51`、`LoadLocal 0x03`、`StoreLocal 0x04` 与 `addAll` 常量；`runtimeForNames(List<String> extra)` 与 `runtimeForLabels(Map<String,String> extra)` 的运行期 collection-for 产生 `CallDynamic 0x51`、`LoadLocal 0x03`、`StoreLocal 0x04`、`JumpIfFalse 0x31`、`Jump 0x30` 以及 `get:iterator` / `moveNext` / `get:current` 等常量。
- `tests/e2e/test_kernel_compile_from_plan.sh`：`capturedGreeting(String name)` 的 `(() => '$prefix $name')()` 与 `storedClosureGreeting(String name)` 的 `final format = () => ...; format()` 会降级为 `let` 局部保存 + `StringConcat 0x42`，JSON/binary module 中包含 `LoadLocal 0x03` / `StoreLocal 0x04`。
- `tests/e2e/test_kernel_compile_from_plan.sh`：`escapingGreeting(String name)` 的直接返回捕获闭包、`storedEscapingGreeting(String name)` 的局部闭包变量返回、`personalizedEscapingGreeting(String name)` 的带位置参数返回闭包、`namedEscapingGreeting(String name)` 的 named 参数返回闭包与 `localFunctionEscapingGreeting(String name)` 的局部函数声明返回都会生成 `bytecode_source`，主函数体为 local capture + `MakeClosure 0x54`，`bytecode_source.extra_functions` 含 `<member>.<closure0>()` synthetic function，本地 plan 会把它们放入 `interpret`；`passedEscapingGreeting(String name)` 的 `useCallback(() => '$prefix $name')` 会被识别为同库同步 callback wrapper，编译期内联为 `StringConcat 0x42` + local load/store bytecode。
- `tests/e2e/test_kernel_compile_from_plan.sh`：`asyncLabel()` 的 `Future<String> asyncLabel() async { return 'patched-async'; }` 与 `awaitedLabel(bool enabled)` 的 `if (await Future.value(enabled)) return 'patched ${await Future.value('awaited')}'; return 'patched disabled';` 会生成 `NewObject 0x55`，constructor 常量为 `dart:async::class:_Future.value;types:String`，`awaitedLabel()` body 同时包含 `StringConcat 0x42` 与 `JumpIfFalse 0x31`，并在 `debug_locals` 中记录参数名 `enabled`；`awaitedLocalLabel()` 的 `try { final base = 'patched-local'; final prefix = await Future.value(base); if (...) return '$prefix ${await Future.value(...)}'; return ...; } catch (e) { return ...; }` 生成 `TryBegin 0x61`、至少两个 `StoreLocal 0x04`、`JumpIfFalse 0x31`、`StringConcat 0x42` 和 `_Future.value<String>`，并在 JSON/binary module 的 `debug_locals` 中记录 `name` / `base` / `prefix`；本地 plan 会把它们放入 `interpret`；`value is String Function()` 与 `value is (String, int)` 会分别被 inventory 标记为 `function_type_unsupported`、`record_type_unsupported`，不生成 `bytecode_source`，本地 plan 会把它们放入 `reject`。
- `tests/e2e/test_kernel_compile_from_plan.sh`：`recoverFromThrow(bool fail)` 的 `try { return fail ? throw ... : ... } catch (e) { return ... }` 产生包含 `TryBegin 0x61`、`Throw 0x60`、`JumpIfFalse 0x31`、`Jump 0x30`、`LoadLocal 0x03` 与 `StoreLocal 0x04` 的 JSON/binary module；`alwaysThrow()` 产生 `Throw 0x60`。
- `crates/fcb_core/src/bytecode.rs`：Rust canonical `OpCode` 已补齐 `Throw 0x60` 与 `TryBegin 0x61`，`validate_bytecode` 会按 VM 相同规则校验 `TryBegin` 的 `current < handler < end < code.len()` 和 instruction-boundary，避免 CLI/authoring full validation 拒绝 compiler 已产出的 try/throw bytecode；当前又补齐 `CallClosure` named metadata 常量校验（非 0 operand 必须指向 `;named:` 字符串）以及 `LoadArg` / `LoadLocal` / `StoreLocal` 越界校验，避免坏 bytecode 逃到 VM runtime 才失败。`cargo test -p fcb_core` 覆盖 happy path、handler 落在 operand 中、end 越界、bad/missing `CallClosure` metadata、missing argument/local 回归。
- `runtime/vm/fcb_patch_runtime.cc`：VM `ValidateModule` 已同步补齐 `MakeClosure 0x54` / `NewObject 0x55` string operand 校验，以及 `CallClosure 0x53` metadata 常量校验（非 0 operand 必须指向 `;named:` 字符串）。`runtime/vm/fcb_patch_runtime_loader_test.cc` 覆盖 missing `MakeClosure`/`NewObject` string operand、bad/missing `CallClosure` metadata，`scripts/test_vendor_vm_runtime.sh` 通过。
- `tests/e2e/test_kernel_compile_from_plan.sh`：`String Function() topLevelTearOff() => stableTearOffLabel;` 产生包含 `MakeClosure 0x54` 的 JSON/binary module，目标常量为 `package:fcb_kernel_compile_test/main.dart::stableTearOffLabel`；当前 drill 解释 39 个函数、拒绝 2 个函数，binary module 含 51 个 functions。
- `VPYTHON_VIRTUALENV_ROOT=/private/tmp/fcb-vpython-root PATH="$PWD/vendor/depot_tools:$PATH" ninja -C vendor/flutter/engine/src/out/host_release_arm64 run_vm_tests`：已重编译 `run_vm_tests_set.fcb_patch_runtime_bytecode_closure_test.o`、`libdart_vm_precompiler.fcb_patch_runtime.o` 并 relink `run_vm_tests`。
- `VPYTHON_VIRTUALENV_ROOT=/private/tmp/fcb-vpython-root PATH="$PWD/vendor/depot_tools:$PATH" ./flutter/tools/gn --mac --mac-cpu arm64 --runtime-mode debug --unoptimized --enable-unittests --no-lto --no-rbe --no-goma --prebuilt-dart-sdk --allow-deprecated-api-calls --target-dir host_debug_unopt_arm64`：已生成 non-PRODUCT host debug runner 配置。
- `VPYTHON_VIRTUALENV_ROOT=/private/tmp/fcb-vpython-root PATH="$PWD/vendor/depot_tools:$PATH" ninja -C vendor/flutter/engine/src/out/host_debug_unopt_arm64 run_vm_tests`：通过，首次构建并链接 non-PRODUCT `run_vm_tests`。
- `vendor/flutter/engine/src/out/host_debug_unopt_arm64/run_vm_tests FcbPatchDebuggerStackTraceFromStringFrame`：通过，真实运行验证 FCB `String` marker 经 `DebuggerStackTrace::From(StackTrace)` 转为 `ActivationFrame::kFcbPatch`，service JSON 输出 `FcbPatchSourceLocation`、`sourceUri`、`line`、`column`。
- `vendor/flutter/engine/src/out/host_debug_unopt_arm64/run_vm_tests FcbPatchDebuggerCollectsLivePatchFrame`：通过，真实运行验证 live `DebuggerStackTrace::Collect()` 会把当前 thread-local FCB source location stack 追加为 `ActivationFrame::kFcbPatch`；frame 携带 `package:app/live.dart::broken()` function id 和 bytecode offset `7`，`QualifiedFunctionName()` 与 service JSON 的 `fcbPatchFunctionId` / `fcbPatchBytecodeOffset` 均可查。
- `vendor/flutter/engine/src/out/host_debug_unopt_arm64/run_vm_tests FcbPatchDebuggerCollectsActiveInterpreterFrame`：通过，真实运行一个 `LoadArg 0; StoreLocal 0; LoadLocal 0; Return` bytecode function，并在解释器 `UpdateActivePatchFrame` 回调中调用 `DebuggerStackTrace::Collect()`，验证正在执行的 FCB frame 可见、function id 为 `package:app/live.dart::activeFrame()`、source location 为 `package:app/live.dart:20:3`、bytecode offset 为 `4`，`NumLocalVariables()` / `VariableAt()` 通过 `debug_locals` 暴露源码名 `input=41` 与 `savedInput=41`，`BuildParameters()` 注入同一组 locals，解释返回后 active frame stack 为空。
- `vendor/flutter/engine/src/out/host_debug_unopt_arm64/run_vm_tests FcbPatchDebuggerCollectsCapturedClosureActiveFrame`：通过，真实运行 `MakeClosure target;captures:2` + `CallClosure` 的内部 bytecode closure 链路，并在 closure body 的 `StringConcat` 指令处调用 `DebuggerStackTrace::Collect()`；验证 active stack 同时包含 caller 和 closure body 两个 FCB frame，closure body frame 的 `VariableAt()` / `BuildParameters()` 通过 `debug_locals` 暴露 captured `prefix=patched `、captured `name=Ada` 和 closure 参数 `suffix= friend`。
- `vendor/flutter/engine/src/out/host_debug_unopt_arm64/run_vm_tests FcbPatchDebuggerCollectsActiveInterpreterFrame` / `FcbPatchDebuggerCollectsCapturedClosureActiveFrame`：通过，新增断言 active frame metadata 中 `fcb_patch_argument_count()` 与 `fcb_patch_captured_slot_count()` 正确；service JSON 输出 `fcbPatchArgumentCount`、`fcbPatchCapturedSlotCount`、`fcbPatchScope` 与 `fcbPatchVars`。普通 active frame 的 scope 分段为 `arguments` + `locals`，并列出 `input` / `savedInput` 变量名，`fcbPatchVars` 暴露 `input` 的 `scope=arguments,valueMaterialized=true,valueKind=int,valuePreview=41` 与 `savedInput` 的 `scope=locals`；captured closure frame 的 scope 分段为 `captured` + `arguments` + `locals`，其中 captured 段 `start=0,count=2,variables=[prefix,name]`、closure 调用参数段 `start=2,count=1,variables=[suffix]`、locals 段 `start=3,count=3`，`fcbPatchVars` 暴露 `prefix` 的 `scope=captured,valueKind=string,valuePreview=patched ` 与 `suffix` 的 `scope=arguments,valueKind=string,valuePreview= friend`。实现中已避免 `JSONArray::AddValue(Object)` 触发未 setup `JSONStream` 的 service-id 崩溃，scope variables 以普通 JSON string 输出；`fcbPatchVars.valuePreview` 也用字符串预览，避免复用普通 frame 的 object-id `value` 字段。
- `vendor/flutter/engine/src/out/host_debug_unopt_arm64/run_vm_tests FcbPatchDebuggerDescribesUnmaterializedBytecodeClosure`：通过，构造 `MakeClosure target;captures:0` 后 `StoreLocal callback` 的 active frame；`VariableAt()` 仍因 Dart `_Closure` 尚未 materialize 而看到 `null` fallback，但 `fcbPatchVars` 保留原始 `fcb::Value` 语义，输出 `callback` 的 `scope=locals,valueMaterialized=false,valueKind=bytecode_closure,valuePreview=BytecodeClosure(function=...,captures=0)`，避免 debugger/service 把内部 bytecode closure local 误判为真实 `null`。
- `VPYTHON_VIRTUALENV_ROOT=/private/tmp/fcb-vpython-root PATH="$PWD/vendor/depot_tools:$PATH" ninja -C vendor/flutter/engine/src/out/host_release_arm64 run_vm_tests`：通过，release `run_vm_tests` 目标完成链接，仅有既有 hidden symbol linker warning。
- `vendor/flutter/engine/src/out/host_debug_unopt_arm64/run_vm_tests FcbPatchDebuggerFrameEvaluationUsesSourceLibrary`：通过，验证 FCB pseudo frame 的 `BuildParameters` 返回空参数/null type args，`EvaluateCompiledExpression` 使用 source URI 查找 library；`dart:core:21:7` 会进入 VM expression loader（畸形 kernel 返回 `Kernel isolate returned ill-formed kernel`），`package:app/eval.dart:21:7` 这类缺失 library 会返回明确 `library not found` `ApiError`，不会落入普通 Dart frame 的 `function()`/locals 断言路径。
- `scripts/test_vendor_vm_runtime.sh`：通过，覆盖新增 `FcbPatchDebuggerStackTraceFromStringFrame` handler lookup 断言；FCB pseudo frame 的 `HandlesException()` 返回 false，`DebuggerStackTrace::GetHandlerFrame()` 不会把它选为普通 VM exception handler frame。
- `vendor/flutter/engine/src/out/host_release_arm64/run_vm_tests FcbPatchRuntimeReturningBytecodeClosureCapturesContext`：验证 `MakeClosure target;captures:2` 创建内部 bytecode closure，返回后再由 `CallClosure` 调用仍可读取 captured `prefix/name` context；同时验证 bytecode closure named call metadata 可用于 named 参数调用，并在 named metadata 多于实参、调用参数过少/过多时返回错误；bytecode closure 内部 `Throw` 可被调用方 active `TryBegin` handler 捕获，caught path 后 `PatchStackTraceLocationCount()==0`；branch-local conditional closure 的 true/false 两条路径分别返回 `patched Ada enabled` / `patched Ada disabled`；`passBranchLocalGreeting` 证明 bytecode closure 可作为参数传给另一个 bytecode function 再调用；未捕获 throwing closure 的 FCB patch location stack 同时包含 closure body `package:app/closure.dart:77:5` 与 caller `package:app/closure.dart:101:3`。
- `vendor/flutter/engine/src/out/host_release_arm64/run_vm_tests FcbPatchRuntimeTryCatchesCallClosureException`：通过，作为 captured closure release 相邻回归；`FcbPatchDebuggerCollectsCapturedClosureActiveFrame` 在 release runner 中无匹配项，属于 non-PRODUCT debugger 测试。
- `vendor/flutter/engine/src/out/host_release_arm64/run_vm_tests FcbPatchRuntimeTryCatchesCallDynamicException` / `FcbPatchRuntimeTryCatchesCallOriginalException` / `FcbPatchRuntimeTryCatchesCallClosureException` / `FcbPatchRuntimeTryCatchesNewObjectException` / `FcbPatchRuntimeTryCatchesMakeClosureMissingTarget` / `FcbPatchRuntimeTryCatchesAsTypeMismatch`：通过，验证 `CallDynamic`、`CallOriginal`、`CallClosure`、`NewObject`、`MakeClosure` missing target 和 `AsType` mismatch 均可被 active `TryBegin` handler 捕获；caught path 后 `PatchStackTraceLocationCount()==0`，不会把已捕获异常的 FCB patch frame 泄漏给后续 `StackTrace` / debugger。
- `vendor/flutter/engine/src/out/host_release_arm64/run_vm_tests FcbPatchRuntimeNewObjectFutureValue`：验证 `NewObject 0x55` 可调用 `dart:async::class:_Future.value;types:String`，返回 Dart 层可见的 `Future` instance，用于无 `await` async return、immediate `await Future.value(...)`、immediate await string interpolation、await condition、语句级 if-return immediate await、ordinary/immediate-await mixed locals 和 await-local tail if-return 的已完成 Future 子集。
- `tests/e2e/test_kernel_compile_from_plan.sh`：counter_app 形态的 `mainValue() => helper() + 1.5 + 1.5` 产生包含 `call_static` `0x50` 的 JSON/binary module；`List<String> names() => [...]` 产生包含 `MakeList` `0x40` 的 JSON/binary module；`Map<String,String> labels() => {...}` 产生包含 `MakeMap` `0x41` 的 JSON/binary module；`String label(String name) => 'hello $name!'` 产生包含 `StringConcat` `0x42` 的 JSON/binary module；`displayName(User user) => user.label` 产生包含 `GetField` `0x43` 的 JSON/binary module；`bool isKnown(Object value) => value is String`、`bool isUser(Object value) => value is User` 与 `bool isStringList(Object value) => value is List<String>` 产生包含 `IsType` `0x45` 的 JSON/binary module，用户类型常量为 `package:fcb_kernel_compile_test/main.dart::User`，generic core type 常量为 `List<String>`；`Object asStringList(Object value) => value as List<String>` 产生包含 `AsType` `0x46` 的 JSON/binary module；`User makeUser() => User(...)` 产生包含 `NewObject` `0x55` 的 JSON/binary module，constructor 常量为 `package:fcb_kernel_compile_test/main.dart::class:User.`；`Config makeConfig() => Config(name:..., label:...)` 产生包含 `NewObject` `0x55` 的 JSON/binary module，constructor 常量为 `package:fcb_kernel_compile_test/main.dart::class:Config.;named:name,label`；`Box<String> makeStringBox() => Box<String>(...)` 产生包含 `NewObject` `0x55` 的 JSON/binary module，constructor 常量为 `package:fcb_kernel_compile_test/main.dart::class:Box.;types:String`；普通 positional instance call 已接 `CallDynamic` `0x51` emitter，restricted source 已接 `CallOriginal` `0x52`、`CallClosure` `0x53`、`MakeClosure` `0x54`、`NewObject` `0x55`、`AsType` `0x46`、`list` 与 `map` emitter。
- `tests/e2e/test_kernel_compile_from_plan.sh`：`dynamicNamedCall()` 的 `Greeter().surround('patched', prefix: '<', suffix: '>')` 产生包含 `NewObject 0x55`、`CallDynamic 0x51` 与 `surround;named:prefix,suffix` 常量的 JSON/binary module。
- `scripts/test_vendor_vm_runtime.sh`：standalone `FcbPatchRuntime` 覆盖 `CallStatic` 0 参数、传参、missing target，`StringConcat` happy / scalar coercion / stack-underflow，以及 map-backed `GetField`/`SetField` 读写与错误路径。
- `vendor/flutter/engine/src/out/host_release_arm64/run_vm_tests FcbPatchRuntimeTryCatchThrow`：验证 `Throw 0x60` / `TryBegin 0x61` 的 VM runner test 已纳入 Engine 构建，并覆盖 active handler 捕获 bytecode `CallStatic` 递归 throw。
- `vendor/flutter/engine/src/out/host_release_arm64/run_vm_tests --list | awk '/^FcbPatchRuntime/ {print $1}' | while read -r test_name; do vendor/flutter/engine/src/out/host_release_arm64/run_vm_tests "$test_name" || exit 1; done`：逐个运行全部 `FcbPatchRuntime*` VM tests，包含新增 `FcbPatchRuntimeTryCatchesMakeClosureMissingTarget`，全部通过。
- `clang++ -std=c++20 -Ivendor/flutter/engine/src/flutter/third_party/dart/runtime -fsyntax-only ...fcb_patch_runtime.cc ...fcb_patch_runtime_loader.cc`：验证非-standalone VM API 路径能解析 `Object`/`Instance`/`Field`/`Class::LookupInstanceField`。
- `patch_report.json` 含 `reject_reason: unsupported_kernel_node`、`escaping_capturing_closure`、`returning_capturing_closure`、`passing_capturing_closure`、`async_await_unsupported`、`function_type_unsupported` 与 `record_type_unsupported` 的兼容用例；当前 compile-from-plan drill 中剩余 reject 为 `function_type_unsupported` 与 `record_type_unsupported`，带 `await` 的 async 形态仍应使用 `async_await_unsupported`。

---

### E4 — 失败 fallback + stack trace（1 人月）

**任务**

- interpreter 任意 case 抛出 `InterpretResult::Error` → patch 整体标记 `PatchState::kDisabledBadPatch`，**当前调用** fall through 到原 AOT（必须能做到不影响调用者）。
- 把 `kDisabledBadPatch` 写回客户端 cache 的 `state.json`（updater 侧 G 阶段消费），下次启动直接跳过该 patch。
- 上报 `crash_rollback` 事件到 server（POST /v1/events，payload 含 `function_id` + `error_message` + `bytecode_offset`）。
- stack trace：BytecodeModule 持 `source_map`（FunctionId + bytecode_offset → source location）；解释帧异常时把 Dart `StackTrace` 拼上 `package:app/foo.dart:123 (FCB patch)`。

**关键文件**

- `vendor/flutter/engine/src/flutter/third_party/dart/runtime/vm/fcb_patch_runtime.cc`（错误路径 + state 回写）
- `vendor/flutter/engine/src/flutter/third_party/dart/runtime/vm/object.cc`（`StackTrace::ToCString()` 注入点）
- `crates/fcb_core/src/state.rs:240`（`mark_failure` 已存在，扩展为接 patch_runtime 的回调）
- `updater/src/lib.rs`（exposed C ABI `fcb_report_interpret_failure(patch_number, function_id, error)`）

**验收**

- Host-side 已验证：
  - `cargo test -p fcb_updater --no-default-features interpret_failure`：`fcb_report_interpret_failure(...)` 会写入 `state.bad_patches`、保留 `interpret_failure:function_id:error` reason，并 POST `/v1/events` `crash_rollback`；覆盖 Dart FFI copy 写入 `runtime_config.json`、Engine VM hook copy 从同一 cache hydrate server/app 配置后上报的 Android 双 runtime 场景。
  - `make test-crash-rollback`：三次 pending launch 失败后回到 LKG，failed patch 标记为 bad，并记录本地 `crash_rollback` history。
- Android local 已验证：`scripts/test_android_interpret_failure.sh` 生成 `return_underflow` bytecode patch（`code:[255]`，manual payload 已写 `source_map`），设备端注册 patch 后 `initialCounterValue` fallback 为 1，其它结果为 baseline，tombstone 不增加，`state.json.bad_patches` 含 patch 1，`last_launch.status` 为 `failure:interpret_failure:...Return stack underflow at bytecode offset 0 (...)`。
- Android server-backed 已验证：`target/fcb/android-server-crash-rollback/final/summary.txt` 证明同一设备失败路径配置真实 server 后通过，`server_events_evidence` 指向 `target/fcb/android-server-crash-rollback/final/server-crash-rollback-event.json`；server `patch_events` 表记录 `crash_rollback`，payload 含 `function_id=package:fcb_counter_app/pricing_source.dart::initialCounterValue`、`error_message=Return stack underflow ... (FCB patch)`。后续新增 `updater` 结构化解析：当 VM error 含 `at bytecode offset N (package:... FCB patch)` 时，`crash_rollback` payload 会写入 `bytecode_offset:N` 与 `source_location:package:...`；`cargo test -p fcb_updater --no-default-features interpret_failure` 已覆盖该 contract。
- 真实 VM StackTrace source location 已验证：`fcb_patch_runtime.cc` 在解释器错误发生时记录最接近的 `source_map` entry，`fcb_patch_runtime_vm.cc` 通过 thread-local vector 保存 FCB patch frame metadata stack，`object.cc::StackTrace::ToCString()` 逐帧追加 `#N <fcb patch> (package:... FCB patch)`；`out/host_release_arm64/run_vm_tests FcbPatchRuntimeStackTraceSourceLocation` 已验证 `StackTrace` 文本含 `package:app/bad.dart:9:3` 与 `FCB patch`，`FcbPatchRuntimeReturningBytecodeClosureCapturesContext` 已验证嵌套 bytecode closure 未捕获错误同时保留 inner body 与 caller 两帧，并验证 caught bytecode closure throw 不会残留 FCB patch location。`DebuggerStackTrace::From(StackTrace)` 已新增 FCB `String` marker 到 `ActivationFrame::kFcbPatch` 的转换和 `FcbPatchSourceLocation` JSON 输出，`out/host_debug_unopt_arm64/run_vm_tests FcbPatchDebuggerStackTraceFromStringFrame` 已真实运行覆盖该非 PRODUCT debugger/service JSON 路径；`DebuggerStackTrace::Collect()` 已新增 live FCB frame 追加，`FcbPatchDebuggerCollectsLivePatchFrame` 已验证 live collection 会保留当前 FCB patch source location、function id 与 bytecode offset，并通过 service JSON 暴露；`FcbPatchDebuggerCollectsActiveInterpreterFrame` 已验证真实解释执行期间 active frame 可被 `DebuggerStackTrace::Collect()` 采集，frame API 通过 `debug_locals` 暴露源码变量名快照并注入 `BuildParameters()`，且正常返回后清空；`FcbPatchDebuggerFrameEvaluationUsesSourceLibrary` 已验证 FCB frame 上的 service evaluate 入口使用 source URI 查找 library，命中 library 时进入 VM expression loader，缺失 library 时返回明确 `ApiError`；`FcbPatchDebuggerStackTraceFromStringFrame` 现在也覆盖 FCB pseudo frame 的 exception handler lookup fail-closed，证明 `HandlesException()` / `GetHandlerFrame()` 不会把它误当作普通 Dart catch handler。当前调用仍保持 fallback 到原 AOT/JIT，不默认向 Dart 层抛异常；FCB bytecode handler 参与 VM exception unwinder 的完整语义和带完整 captured context metadata 的真正 debugger 可停靠 frame 仍未完成。
- 解释成功但返回值不能转换回 Dart 的边界也已纳入 fallback contract：`fcb_patch_entry.cc` 对 return conversion failure 执行 `DisablePatch`、`fcb_report_interpret_failure` 与 `RecordAotCall`，然后返回 false 让当前调用继续原 AOT/JIT；`out/host_release_arm64/run_vm_tests FcbPatchEntryFallsBackOnEscapingBytecodeClosure` 已验证内部 bytecode closure 逃逸到 Dart 返回边界时不会返回 `ApiError`，并把 patch 标记为 `kDisabledBadPatch`。

---

### E5 — 性能上报 + 决策辅助（2 周）

**任务**

- 在 `Interpret()` 主循环入口/出口加轻量 counter（atomic uint64），统计 `interpreted_function_calls` 与 `aot_function_calls`。
- 暴露 C ABI `fcb_get_interpreter_stats(uint64_t* interpreted, uint64_t* aot)`。
- `fcb_code_push.dart` 加 `Future<InterpreterStats> interpreterStats()`。
- 客户端定期（每次 mark_success 后）上报 `interpreter_ratio` 事件。
- CLI 加 `fcb inspect patch <path>` 显示估算 interpreter_ratio（基于 plan.interpret 数量 / 总函数数）。
- 如果 ratio > 阈值（例如 5%）→ CLI 在 `fcb patch` 时输出 warning：「该 patch 解释比例高，建议发新 release」。

**关键文件**

- `vendor/flutter/engine/src/flutter/third_party/dart/runtime/vm/fcb_patch_runtime.cc`（counter 自增）
- `updater/src/lib.rs`（暴露 stats）
- `packages/fcb_code_push/lib/fcb_code_push.dart`（Dart API）
- `cli/src/auto.rs` / `cli/src/inspect.rs` / `cli/src/main.rs`（estimated interpreter ratio、`fcb inspect patch` summary 与自动 patch warning）

**验收**

- counter_app patch 后 interpreter_ratio < 1%。
- 故意 patch 大量函数（10+）触发 CLI warning：`cargo test -p fcb automatic_bytecode_payload_warns_when_many_functions_are_interpreted` 已覆盖 10/100 interpreted functions，自动 bytecode payload helper 会把 `estimated interpreter_ratio 10.00% exceeds 5.00%` 写入 `patch_report.messages`。

## 风险与缓解

| 风险 | 严重性 | 缓解 |
|------|--------|------|
| ObjectPtr 集成踩 GC 时序 | 高 | 先在 stress test mode 验证；review by Dart VM 老手 |
| async/await 实现难度远超预估 | 高 | E2 的 P1 await 可推迟到 Phase E 后期，业务上禁止 async 函数 patch 也能临时回避 |
| Dart SDK upstream rebase 时 stub_code hook 漂移 | 中 | 锁定 Dart SDK 到 3.12.2，rebase 时由 vendor/REBASE.md（Phase H）流程承担 |
| `call_original` 复杂目标覆盖不足 | 低 | 当前已覆盖 top-level/static positional、class static qualified name、named args、generic function type args；剩余主要是更复杂 tear-off / closure generic 调用形态，普通 restricted source 侧保持显式目标字符串约束 |

## 退出标准

- counter_app 真实 patch（含 widget tree 修改 + setState + plugin call）跑通。
- `scripts/test_vendor_vm_runtime.sh` 的 standalone `FcbPatchRuntime` 全绿。
- 解释失败 fallback 端到端走通（Android 设备 fallback + bad patch + server `crash_rollback` 已验证）。
- interpreter_ratio 可观测，< 1% 在 counter_app 场景。
- `fcb inspect patch` 可显示 estimated interpreter ratio，`fcb patch` 在解释比例超过 5% 时会输出建议发新 release 的 warning。
- `crates/fcb_bytecode` 已裁剪，编译职责完全转给 Dart 工具。
