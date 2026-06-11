Flutter 热更新系统实现文档（面向 Code Agent）

版本：2026-06-11
项目代号：FCB（Flutter CodePush Box）
目标：参考 Shorebird，实现一套可自研、可灰度、可回滚的 Flutter Dart 代码热更新系统。

⸻

0. 结论先行

推荐实现路线分三层：

1. P0：Android / Desktop 技术验证版
    * 不做真正运行时替换。
    * App 启动时检查补丁，下载 diff，下次启动生效。
    * Android 可先实现 “AOT artifact / libapp.so replacement” 模式，验证 CLI、server、updater、diff、rollback 的闭环。
    * 注意：如果面向 Google Play，直接下载 .so 或机器码补丁存在政策风险。Google Play 明确限制从 Google Play 以外下载 dex/JAR/.so 等可执行代码，但对 VM/interpreter 中运行的代码有例外。 
2. P1：商店合规版
    * 补丁 payload 不下发 native executable。
    * 下发自定义 Dart bytecode / Kernel 派生 bytecode。
    * 在 App 包内预置 interpreter，由 interpreter 执行补丁逻辑。
    * iOS 必须走解释执行路线；Apple Developer Program License Agreement 允许下载 interpreted code，但要求不能改变 App 主要目的、不能绕过签名/沙盒/系统安全机制、不能创建其它应用商店。 
3. P2：Shorebird 级完整方案
    * fork Flutter Engine、Flutter Tool、Dart SDK。
    * Dart VM 支持函数级 patch dispatch。
    * 未变函数继续跑原 AOT 机器码，变更函数进入 interpreter。
    * 编译器/linker 比较 release 与 patch 两个 Dart 程序，最大化复用原 AOT 代码。
    * 这是长期工程，不是单纯业务层 SDK。Shorebird 官方说明其系统包含 CLI、Flutter engine fork、云服务、Dart compiler toolchain fork；并且不是 JIT，而是自定义 interpreter + linker。 

默认交付顺序：P0 → P1 restricted bytecode → P2 full Dart VM fork。

⸻

1. 背景事实与技术边界

Flutter release 构建面向发布，禁用调试能力并优化启动、执行速度和包体；Flutter hot reload 只在 debug 模式可用。  Flutter 架构上，Engine 包含渲染、文本、文件/网络 I/O、Dart runtime 和编译工具链等底层能力。 

Flutter AOT 模式启动一个 isolate 需要 VM snapshot data、VM snapshot instructions、isolate snapshot data、isolate snapshot instructions 四类 artifact；Android 上这些 artifact 由 gen_snapshot/flutter build aot 生成并由 engine 解析加载，iOS 上通常打入 App.framework 并通过符号加载。 

Dart 官方 dart compile 支持 exe、aot-snapshot、jit-snapshot、kernel 等输出；其中 AOT snapshot 是架构相关的机器码模块，kernel 是可移植中间表示。  所以不能把 stock Flutter release engine 简单理解为“能直接加载任意 .dill 并执行”的运行时。

Shorebird 的公开架构是：release 包含 modified Flutter engine；App 启动时检查 Dart code patch，下载后下次启动可见。  Shorebird patch 可以改 Dart app code、generated code、纯 Dart dependency；不能改 asset、native code、Flutter engine 或 Flutter version。 

Shorebird 的 system architecture 还说明：release/patch 都是通过 CLI 包装 Flutter 构建；patch 会基于 release binary 与 patch binary 生成 binary diff；updater 下载 diff、校验 hash、应用 diff，并在 patch 启动失败时把 patch 标记为 bad，避免 crash loop。 

⸻

2. 非目标

本系统第一版不做以下事情：

* 不支持更新 Java/Kotlin、Objective-C/Swift、C/C++、Rust 等 native code。
* 不支持更新 Flutter Engine、Flutter SDK version、Dart SDK ABI。
* 不默认支持 asset/font/image 更新；asset patch 可作为独立后续模块。
* 不默认做当前 isolate 内的 live hot swap；默认“下载后下次启动生效”。
* 不承诺 Google Play / App Store 一定审核通过；合规实现必须走 VM/interpreter payload，并由业务方法务/审核策略确认。
* 不支持任意 ABI 不兼容变更，例如随意新增 instance field、修改 class layout 后继续复用旧对象。

⸻

3. 总体架构

flowchart TD
  Dev[Developer Source] --> CLI[FCB CLI]
  CLI --> BuildRelease[release build]
  CLI --> BuildPatch[patch build]
  BuildRelease --> ReleaseArtifacts[baseline artifacts]
  BuildPatch --> PatchArtifacts[new artifacts / bytecode]
  ReleaseArtifacts --> Diff[diff/linker]
  PatchArtifacts --> Diff
  Diff --> PatchBundle[patch bundle + manifest + signature]
  PatchBundle --> Server[FCB API + Object Storage + CDN]
  App[Flutter App with modified engine] --> Updater[embedded updater]
  Updater --> Check[patch check API]
  Check --> Server
  Server --> CDN[patch download URL]
  CDN --> Updater
  Updater --> Verify[verify hash/signature]
  Verify --> Apply[apply diff / install bytecode]
  Apply --> State[state.json]
  State --> LaunchSelector[engine launch selector]
  LaunchSelector --> AOT[original AOT]
  LaunchSelector --> PatchedAOT[patched AOT backend]
  LaunchSelector --> Bytecode[interpreter backend]

⸻

4. Repository 结构

Code agent 创建 monorepo：

fcb/
  cli/                         # Rust CLI
  server/                      # Go Fiber API service, DB migration, object storage adapter
  updater/                     # Rust updater library, C ABI
  engine_patch/                # Flutter Engine fork patch files / patch scripts
  dart_sdk_patch/              # Dart SDK fork patch files, P2 使用
  linker/                      # Kernel diff, function linker, bytecode compiler
  packages/
    fcb_code_push/             # Flutter/Dart package exposed to app
    fcb_annotations/           # @hotPatchable 等 annotation
  schemas/
    fcb.yaml.schema.json
    release_manifest.schema.json
    patch_manifest.schema.json
  examples/
    counter_app/
  tests/
    e2e/
    fixtures/

⸻

5. CLI 设计

5.1 命令

fcb init
fcb doctor
fcb release android --flavor prod --dart-define-from-file=config/prod.json
fcb release ios --flavor prod
fcb patch android --release-version 1.2.3+45
fcb patch ios --release-version 1.2.3+45
fcb patch promote --app-id <id> --release-version 1.2.3+45 --patch-number 3 --channel stable
fcb patch rollback --app-id <id> --release-version 1.2.3+45 --to-patch-number 2
fcb inspect release --release-version 1.2.3+45
fcb inspect patch --release-version 1.2.3+45 --patch-number 3

5.2 fcb.yaml

app_id: "uuid"
channel: "stable"
update:
  check_on_startup: true
  activation: "next_restart"
security:
  public_key_id: "prod-ed25519-2026-01"
platforms:
  android:
    enabled: true
    backend: "snapshot_replace" # snapshot_replace | bytecode
    abi:
      - arm64-v8a
      - armeabi-v7a
      - x86_64
  ios:
    enabled: true
    backend: "bytecode"

5.3 Rust CLI release 行为

fcb release <platform> 必须执行：

1. 读取 pubspec.yaml version、fcb.yaml app_id、channel。
2. 使用 vendored Flutter SDK 或本地 custom engine 构建 release。
3. 提取 baseline artifacts：
    * Android：每个 ABI 的 libapp.so 或 AOT snapshot blobs。
    * iOS：App.framework metadata；P1 不提取可替换机器码，只提取 Dart program metadata。
4. 生成 release_manifest.json。
5. 上传 release artifact 到私有 object storage。
6. 创建 release record。
7. 输出商店提交产物：AAB/APK/IPA。

⸻

6. Patch bundle 格式

6.1 patch_manifest.json

{
  "schema_version": 1,
  "app_id": "uuid",
  "release_version": "1.2.3+45",
  "patch_number": 3,
  "channel": "stable",
  "created_at": "2026-06-11T00:00:00Z",
  "flutter_revision": "exact_flutter_revision",
  "dart_revision": "exact_dart_revision",
  "engine_revision": "fcb_engine_revision",
  "backend": "bytecode",
  "platform": "android",
  "arch": "arm64-v8a",
  "base": {
    "artifact_hash": "sha256-base",
    "artifact_size": 12345678,
    "function_map_hash": "sha256-function-map"
  },
  "payload": {
    "kind": "binary_diff",
    "compression": "zstd",
    "diff_algorithm": "bsdiff",
    "hash": "sha256-payload",
    "size": 12345,
    "download_url": "cdn-object-key-or-presigned-url"
  },
  "output": {
    "artifact_hash": "sha256-patched-output",
    "artifact_size": 12345679
  },
  "policy": {
    "min_app_build": 45,
    "max_app_build": 45,
    "rollout_percentage": 10,
    "allow_downgrade": false
  },
  "signature": {
    "algorithm": "ed25519",
    "key_id": "prod-ed25519-2026-01",
    "value": "base64-signature-over-canonical-manifest-without-signature"
  }
}

6.2 签名规则

* 使用 canonical JSON。
* 签名内容包含 manifest 除 signature.value 以外的所有字段。
* payload hash 必须参与签名。
* App 内嵌 Ed25519 public key。
* SHA-256 hash 只用于完整性校验，不作为安全边界；安全边界必须是签名。Shorebird 文档也区分了 patch diff hash 的下载完整性用途和 patch signing 的安全用途。 

⸻

7. Server 设计

7.1 数据表

create table apps (
  id uuid primary key,
  name text not null,
  created_at timestamptz not null default now()
);
create table releases (
  id uuid primary key,
  app_id uuid not null references apps(id),
  release_version text not null,
  platform text not null,
  created_at timestamptz not null default now(),
  manifest jsonb not null,
  unique(app_id, release_version, platform)
);
create table patches (
  id uuid primary key,
  app_id uuid not null references apps(id),
  release_version text not null,
  platform text not null,
  arch text not null,
  patch_number int not null,
  channel text not null default 'staging',
  rollout_percentage int not null default 0,
  manifest jsonb not null,
  active bool not null default false,
  created_at timestamptz not null default now(),
  unique(app_id, release_version, platform, arch, patch_number)
);
create table patch_events (
  id uuid primary key,
  app_id uuid not null,
  release_version text not null,
  platform text not null,
  arch text not null,
  patch_number int,
  event_type text not null,
  client_id_hash text,
  created_at timestamptz not null default now()
);

7.2 APIs

POST /v1/apps
POST /v1/releases
POST /v1/patches
POST /v1/patches/{patch_id}/promote
POST /v1/patches/{patch_id}/rollback
GET /v1/patches/check
POST /v1/events

7.3 Patch check request

{
  "app_id": "uuid",
  "release_version": "1.2.3+45",
  "platform": "android",
  "arch": "arm64-v8a",
  "channel": "stable",
  "current_patch_number": 2,
  "client_id": "anonymous-stable-id"
}

7.4 Patch check response

{
  "patch_available": true,
  "patch": {
    "patch_number": 3,
    "manifest_url": "signed-url-or-cdn-key",
    "payload_url": "signed-url-or-cdn-key",
    "manifest_hash": "sha256",
    "payload_hash": "sha256"
  }
}

7.5 Rollout 规则

Server 对 client_id 做稳定 hash：

bucket = hash(app_id + release_version + patch_number + client_id) % 100
eligible = bucket < rollout_percentage

同一个 client 在同一个 patch_number 上结果必须稳定。

⸻

8. Updater library 设计

实现语言：Rust。
暴露 C ABI 给 Flutter Engine 和 Dart FFI。

8.1 C ABI

typedef struct {
  const char* app_id;
  const char* channel;
  const char* release_version;
  const char* platform;
  const char* arch;
  const char* cache_dir;
  const char* public_key_pem;
  int check_on_startup;
} FcbInitParams;
typedef struct {
  int has_patch;
  int patch_number;
  const char* backend;
  const char* artifact_path;
  const char* bytecode_path;
  const char* manifest_path;
} FcbLaunchPatch;
int fcb_init(const FcbInitParams* params);
int fcb_get_launch_patch(FcbLaunchPatch* out_patch);
int fcb_check_for_update_async(void);
int fcb_download_and_install_blocking(void);
int fcb_is_new_patch_ready_to_install(void);
int fcb_mark_launch_success(void);
int fcb_mark_launch_failure(int patch_number, const char* reason);
int fcb_current_patch_number(void);
const char* fcb_last_error(void);

8.2 本地状态文件

state.json：

{
  "schema_version": 1,
  "release_version": "1.2.3+45",
  "current_patch_number": 2,
  "pending_patch_number": 3,
  "bad_patches": [1],
  "last_launch": {
    "patch_number": 3,
    "status": "pending_success",
    "started_at": "2026-06-11T00:00:00Z"
  },
  "installed": [
    {
      "patch_number": 2,
      "backend": "bytecode",
      "manifest_path": "patches/2/manifest.json",
      "payload_path": "patches/2/module.hbc",
      "installed_at": "2026-06-10T00:00:00Z"
    }
  ]
}

8.3 状态机

no_patch
  -> downloading
  -> downloaded
  -> verifying
  -> applying
  -> installed_pending
  -> launching_pending_success
  -> active
  -> bad
  -> rolled_back

规则：

* installed_pending：补丁已安装，下次启动可用。
* launching_pending_success：本次启动正在使用该 patch。
* Engine 在 root isolate 启动并渲染首帧后调用 fcb_mark_launch_success()。
* 如果进程崩溃，下一次启动时发现上次 patch 未成功标记，则将该 patch 加入 bad_patches，回退到上一个 active patch 或 baseline。
* 安装新 patch 成功后，只保留最多 2 个 patch 目录。

⸻

9. Flutter Engine 修改点

Shorebird 为实现 code push fork 了 buildroot、engine、flutter framework、Dart SDK，并在 engine 中加入 updater，让 engine 能加载新代码。  本项目也按同样层次拆分，但先做最小改动。

9.1 Buildroot / linking

任务：

* 将 updater/ 编译为 libfcb_updater.a。
* 在 engine GN 配置中链接该 static library。
* 将 fcb_* C symbols 加入可见符号 allowlist。
* Android/iOS/desktop 分别验证符号导出。
* 若 Rust panic/backtrace 需要 unwind 支持，则在对应平台补齐 unwind 依赖。

9.2 Engine 启动流程 hook

在 Engine 创建 Dart VM / root isolate 前执行：

FcbInitParams params = CollectParamsFromEmbedderAndBundle();
fcb_init(&params);
FcbLaunchPatch patch = {};
fcb_get_launch_patch(&patch);
if (patch.has_patch) {
  if (strcmp(patch.backend, "snapshot_replace") == 0) {
    ConfigureAotArtifactOverride(settings, patch.artifact_path);
  } else if (strcmp(patch.backend, "bytecode") == 0) {
    ConfigureBytecodePatch(settings, patch.bytecode_path, patch.manifest_path);
  }
}

需要 code agent 在当前 Flutter Engine 版本中定位这些概念点，而不是死绑单个文件名：

* Settings / DartVM 初始化位置。
* root isolate launch 位置。
* Android embedder 传 shell args 的位置。
* iOS FlutterDartProject / FlutterEngine 组装 settings 的位置。
* desktop embedder 组装 assets / ICU / AOT data 的位置。

9.3 Android backend: snapshot_replace

目标：先跑通技术闭环。

实现：

* App 包内保留 baseline libapp.so。
* patch 安装时，用 binary diff 从 baseline 生成 patched libapp.so 到 app code cache。
* 下次启动，Engine 将 Dart AOT shared library path 指向 patched artifact。
* 每个 ABI 单独 patch。
* 仅用于 internal distribution、企业分发、技术验证，或在完成政策审查后使用。

限制：

* 不能用于 iOS。
* 对 Google Play 发布场景，优先使用 bytecode backend。

9.4 iOS backend: bytecode

iOS 不加载下载的 unsigned executable code。实现方式：

* Store 包内仍加载原始 App.framework。
* patch payload 为 signed bytecode/data。
* Engine 初始化 Dart VM 后，把 bytecode module 注册到 Dart VM patch runtime。
* patched function 被调用时进入 interpreter。
* unchanged function 继续跑原 AOT。

9.5 首帧成功回调

在 Engine 首帧 rasterized 或 root isolate ready 后调用：

fcb_mark_launch_success();

如果没有首帧回调可稳定复用，则先在 Dart package 中由用户显式调用：

await FcbCodePush.instance.markLaunchSuccessful();

但最终应在 engine 内自动完成。

⸻

10. Dart package API

packages/fcb_code_push：

class FcbCodePush {
  static final FcbCodePush instance = FcbCodePush._();
  Future<int?> currentPatchNumber();
  Future<bool> isUpdateAvailable();
  Future<UpdateCheckResult> checkForUpdate();
  Future<DownloadResult> downloadUpdate();
  Future<bool> isNewPatchReadyToInstall();
  /// 默认不做 live activation。
  /// 返回 true 表示可以提示用户重启 App。
  Future<bool> requestRestartToApply();
  Future<void> markLaunchSuccessful();
}

UpdateCheckResult：

class UpdateCheckResult {
  final bool patchAvailable;
  final int? patchNumber;
  final String? reason;
}

⸻

11. Diff 编译设计

11.1 Release build 输出

每次 release 保存：

release_artifacts/
  android/
    arm64-v8a/
      libapp.so
      manifest.json
      function_map.json
    armeabi-v7a/
      libapp.so
      manifest.json
      function_map.json
  ios/
    app.dill.metadata
    function_map.json
    class_table.json
  build_info.json

build_info.json 必须包含：

{
  "flutter_revision": "...",
  "dart_revision": "...",
  "engine_revision": "...",
  "target_platform": "android-arm64",
  "build_mode": "release",
  "dart_defines_hash": "...",
  "pubspec_lock_hash": "...",
  "obfuscation": false,
  "split_debug_info": null
}

Patch 构建时必须校验这些字段一致。Flutter/Dart/Engine revision 不一致时拒绝 patch，要求新 release。

11.2 P0 binary diff

# pseudo
fcb_diff \
  --base release_artifacts/android/arm64-v8a/libapp.so \
  --new build/patch/android/arm64-v8a/libapp.so \
  --out patch_payloads/android/arm64-v8a/patch.bsdiff \
  --algorithm bsdiff \
  --compress zstd

安装时：

patched = bspatch(base_libapp_so, patch.bsdiff)
sha256(patched) == manifest.output.artifact_hash
atomic_rename(patched.tmp, patches/3/libapp.so)

11.3 P1 bytecode diff

输入：

base.dill
patch.dill
base.function_map.json

输出：

patch.hbc      # Hot ByteCode module
patch.map      # FunctionId -> bytecode offset
patch.meta     # constants, class/method metadata, source map

流程：

1. Compile app to Kernel IR.
2. Normalize Kernel:
   - canonical URI
   - canonical names
   - remove unstable offsets
   - normalize synthetic names where possible
3. Build stable FunctionId.
4. Compare base vs patch:
   - unchanged
   - changed_body
   - changed_signature
   - new_function
   - deleted_function
   - class_shape_changed
5. Reject unsupported changes.
6. Compile changed/new supported functions to HBC.
7. Emit patch table.
8. Sign manifest + bytecode.

FunctionId：

sha256(
  canonical_library_uri + "\n" +
  class_qualified_name + "\n" +
  member_name + "\n" +
  normalized_type_signature + "\n" +
  type_parameter_shape
)

11.4 Unsupported change policy for P1

P1 bytecode backend 直接拒绝：

* 修改 public function signature。
* 修改 instance field layout。
* 修改 enum shape。
* 新增 native plugin dependency。
* 修改 main() 启动协议。
* 修改 isolate entrypoint。
* 修改 FFI 调用签名。
* 修改 method channel native side contract。
* 变更 asset 路径但未随包内置。
* 复杂 mirrors/reflection。

P2 再逐步放开。

⸻

12. Bytecode runtime 设计

12.1 HBC module 格式

HBCHeader
  magic = "FCBHBC\0"
  version = 1
  target_dart_abi
  target_flutter_revision_hash
  module_hash
  constant_pool_offset
  function_table_offset
  instruction_offset
  source_map_offset
ConstantPool
  null
  bool
  int64
  double
  string
  symbol_ref
  type_ref
  list_literal
  map_literal
FunctionTableEntry
  function_id
  name
  arity
  type_params_count
  register_count
  instruction_start
  instruction_length
  exception_table_start
  flags
Instructions
  load_const
  load_arg
  move
  add/sub/mul/div
  eq/neq/lt/lte/gt/gte
  jump
  jump_if_true
  jump_if_false
  call_static
  call_dynamic
  call_original
  get_field
  set_field
  new_object
  return
  throw
  await

12.2 VM 内执行模型

P2 需要在 Dart VM 内部实现 interpreter，直接操作 Dart VM object representation：

ObjectPtr HotBytecodeInterpreter::Invoke(
    Thread* thread,
    FunctionId function_id,
    ArrayPtr args,
    TypeArgumentsPtr type_args) {
  auto function = module.Lookup(function_id);
  Frame frame(function.register_count);
  frame.LoadArgs(args);
  while (true) {
    auto op = ReadOp();
    switch (op.code) {
      case OpCode::kLoadConst:
        frame[op.dst] = constant_pool[op.index];
        break;
      case OpCode::kCallStatic:
        frame[op.dst] = DartEntry::InvokeFunction(
          thread,
          ResolveTarget(op.target),
          frame.ReadArgs(op));
        break;
      case OpCode::kCallOriginal:
        frame[op.dst] = InvokeOriginalAotFunction(op.target, frame.ReadArgs(op));
        break;
      case OpCode::kReturn:
        return frame[op.src];
    }
  }
}

12.3 Function dispatch

每个可 patch function 有三种状态：

OriginalOnly:
  直接跳原 AOT Code
PatchedInterpreted:
  进入 HotBytecodeInterpreter
DisabledBadPatch:
  跳原 AOT Code 或抛 controlled error

函数调用入口：

ObjectPtr PatchableFunctionEntry(Thread* thread, FunctionId id, Args args) {
  PatchEntry* patch = PatchTable::Lookup(id);
  if (patch == nullptr) {
    return InvokeOriginalAot(id, args);
  }
  return HotBytecodeInterpreter::Invoke(thread, id, args);
}

P1 可用代码生成方式先绕开 VM 深改：

@pragma('vm:never-inline')
T fcbDispatch<T>(
  String functionId,
  T Function() original,
  List<Object?> args,
) {
  final patched = FcbRuntime.lookup(functionId);
  if (patched == null) return original();
  return FcbRuntime.invoke<T>(patched, args);
}

业务代码由 transformer 改写：

int price(int amount) {
  return fcbDispatch<int>(
    'package:app/pricing.dart::price(int)',
    () => _price_original(amount),
    [amount],
  );
}
int _price_original(int amount) {
  return amount * 100;
}

这不是 Shorebird 级透明方案，但能显著降低 P1 实现难度。

⸻

13. Linker 设计

Shorebird 公开说明其 linker 会比较 previous/new 两个 Dart program，并在函数级决定哪些代码可复用原 binary、哪些进入 interpreter；目标是尽量让 patched app 仍跑原 AOT 代码。  本项目 linker 采用同样目标，但分阶段实现。

13.1 输入

base.kernel
patch.kernel
base.function_map
base.class_table
base.constant_pool_map
patch.compiler_report

13.2 输出

{
  "functions": {
    "function_id_1": {
      "decision": "reuse_aot",
      "reason": "body_hash_equal"
    },
    "function_id_2": {
      "decision": "interpret",
      "reason": "body_changed",
      "bytecode_offset": 1024
    },
    "function_id_3": {
      "decision": "reject",
      "reason": "signature_changed"
    }
  },
  "class_shape_changes": [],
  "constants_added": 12
}

13.3 决策规则

if signature changed:
  reject
else if class instance layout changed:
  reject in P1
else if normalized body hash equal:
  reuse_aot
else:
  interpret

P2 优化：

* 支持新 private helper function。
* 支持 build method 变更。
* 支持 async state machine。
* 支持 closure。
* 支持 generic specialization fallback。
* 支持 constant pool 独立追加，避免重排 base object pool。

⸻

14. Hot patch 激活策略

默认策略：next restart activation。

原因：

* release Flutter 没有 debug hot reload 能力。
* 当前 isolate 中 class table、object layout、inline cache、optimized code、async continuation 都可能持有旧假设。
* next restart 简单、可恢复、可灰度、可回滚。
* Shorebird 公开文档也说明用户会在下载 patch 后的下一次 App restart 看到更新。 

可选策略：

update:
  activation: "next_restart"  # default
  allow_runtime_activation_for_bytecode: false

仅当 bytecode backend 且 patch 不包含 class shape/signature 变更时，后续版本才允许 runtime activation。

⸻

15. Engine 编译和本地验证

Flutter Engine 官方构建流程使用 gclient sync、flutter/tools/gn、ninja；Android 可按 CPU/runtime-mode 生成对应 out 目录，iOS 也需要 device 与 host-side executables。 

15.1 Android local engine

cd engine/src
gclient sync
./flutter/tools/gn --android --android-cpu arm64 --runtime-mode=release
ninja -C out/android_release_arm64
./flutter/tools/gn --runtime-mode=release
ninja -C out/host_release

测试 App：

flutter build apk \
  --release \
  --target-platform android-arm64 \
  --local-engine-src-path /path/to/engine/src \
  --local-engine android_release_arm64

15.2 iOS local engine

cd engine/src
gclient sync
./flutter/tools/gn --ios --runtime-mode=release
ninja -C out/ios_release
./flutter/tools/gn --runtime-mode=release
ninja -C out/host_release

iOS 不实现 downloaded AOT replacement，只接入 updater + bytecode runtime。

⸻

16. Security 要求

必须实现：

* TLS。
* Ed25519 patch signing。
* Public key baked into app/engine。
* Manifest canonicalization。
* Payload SHA-256。
* Output artifact SHA-256。
* Patch number monotonic。
* Bad patch blocklist。
* Rollback event 上报。
* Server-side auth for release/patch upload。
* CI secret 不进 App 包。
* app_id 不是 secret，只用于定位 app/release。
* Patch payload 不允许执行 native shell、动态加载任意系统库、绕过 sandbox。

禁止：

* 从未签名来源加载 patch。
* 只靠 HTTPS 不验签。
* 允许 downgrade 到旧 patch，除非 rollback manifest 被签名并显式声明。
* 将用户 PII 加入 patch check request。
* 在 UI 线程同步下载 patch。

⸻

17. Store compliance 策略

17.1 Android

Google Play policy 明确禁止 App 通过 Google Play 以外的方法修改/替换/更新自身，也禁止从非 Google Play 来源下载 dex/JAR/.so 等 executable code；但 VM/interpreter 运行的代码有例外。 

因此：

* snapshot_replace backend 不作为 Play 默认方案。
* Play 默认使用 bytecode backend。
* Patch bytecode 必须由包内 interpreter 执行。
* Interpreter 不得提供直接 Android API 绕过能力；所有 native access 仍走原 App 已审核代码路径。

17.2 iOS

Apple 协议禁止下载/安装 executable code，但允许 interpreted code，条件是不能改变 App 主要目的、不能绕过签名/沙盒/系统安全、不能创建其它 App store。 

因此：

* iOS 只使用 bytecode backend。
* 不下载 .framework、.dylib、JIT code、native machine code。
* Patch 必须是解释执行数据。
* 重大新功能仍走 App Store release。

⸻

18. Agent 实施顺序

Phase A：基础设施闭环

目标：不用改 Dart VM，先完成 release/patch/check/download/install/rollback。

任务：

* 创建 monorepo。
* 实现 fcb.yaml parser。
* 实现 Rust CLI skeleton。
* 实现 Go Fiber server API。
* 实现 object storage adapter，本地可先用 filesystem。
* 实现 patch manifest canonical JSON。
* 实现 Ed25519 sign/verify。
* 实现 Rust updater：
    * state machine
    * patch check
    * download
    * verify
    * atomic install
    * rollback
* 实现 Flutter package FFI 调用。

验收：

* fcb init 生成 app_id。
* fcb release android 生成 release record。
* fcb patch android 生成 signed manifest。
* example app 能调用 checkForUpdate() 并下载 patch。
* invalid signature 被拒绝。
* bad patch 被 blocklist。

Phase B：Android snapshot_replace backend

目标：技术验证版可更新 Dart AOT artifact。

任务：

* 修改 engine 链接 updater。
* Engine 启动前读取 fcb_get_launch_patch()。
* 对 Android 设置 patched AOT artifact path。
* CLI 提取 base/new libapp.so。
* 实现 bsdiff/zstd。
* 安装 patch 后下次启动加载 patched libapp.so。

验收：

* Counter app v1 显示 1。
* 发布 release。
* 源码改为显示 2。
* 生成 patch。
* 已安装 v1 的设备启动后下载 patch。
* 重启 App 后显示 2。
* 删除网络后仍使用本地 active patch。
* 制造崩溃 patch 后自动回滚到 v1 或上一个 patch。

Phase C：P1 restricted bytecode backend

目标：不下载 native executable，支持受限 Dart 函数补丁。

任务：

* 实现 @hotPatchable annotation。
* 实现 build transformer/codegen，把 annotated function 包成 dispatch wrapper。
* 实现 HBC bytecode compiler，先支持：
    * int/double/bool/string/null
    * list/map literal
    * if/else
    * for/while
    * local variables
    * static function call
    * selected Dart core operations
* 实现 Dart-level interpreter 或 C++ VM-adjacent interpreter。
* Rust CLI patch 时只编译 annotated changed functions。
* iOS/Android 都使用 bytecode backend。

验收：

* 修改 annotated pricing/business 函数后可 patch。
* iOS 不下载 executable artifact。
* Android Play backend 不产生 .so patch。
* unsupported Dart 语法给出明确 compile error。
* patch 后下次启动生效。
* 可灰度、可回滚。

Phase D：P2 Dart VM integrated bytecode

目标：降低业务侵入，接近 Shorebird 模型。

任务：

* Fork Dart SDK。
* 在 VM 内实现 bytecode module loader。
* 实现 VM object interop。
* 实现 function patch table。
* 修改 function entry / invocation stub。
* 实现 Kernel linker。
* 支持 Flutter widget build() method patch。
* 支持 async/await。
* 支持 closure。
* 支持 generic calls。
* 支持 source map / stack trace 映射。

验收：

* 不需要 annotation，即可 patch 普通 Dart function/method。
* 未修改函数继续跑原 AOT。
* 修改函数进入 interpreter。
* crash rollback 生效。
* 性能报告显示 interpreter 调用比例。
* Flutter framework 代码不被解释执行，除非确实发生变更。

⸻

19. 测试计划

19.1 Unit tests

* fcb.yaml parser。
* manifest canonicalization。
* Ed25519 sign/verify。
* SHA mismatch。
* bsdiff apply。
* state machine transition。
* bad patch blocklist。
* rollout hash stability。
* semver/build number matching。
* FunctionId stability。
* Kernel normalization。

19.2 Integration tests

* 本地 Go Fiber server + local object storage。
* Rust CLI release/patch/check 全流程。
* Android emulator/device 启动下载 patch。
* 重启后 patch 生效。
* patch crash 后 rollback。
* staged channel 不影响 stable 用户。
* 10% rollout 只命中稳定 bucket。
* 多 ABI patch 匹配正确。

19.3 Bytecode tests

覆盖：

int add(int a, int b) => a + b;
String greet(String name) => 'hi $name';
bool check(int x) => x > 3 && x < 10;
List<int> makeList() => [1, 2, 3];
Map<String, int> makeMap() => {'a': 1};
int loop(int n) { var s = 0; for (...) s += i; return s; }

P2 追加：

* instance method。
* overridden method。
* generic method。
* closure。
* async/await。
* exception stack trace。
* Flutter widget build method。

⸻

20. 性能指标

必须收集：

{
  "patch_number": 3,
  "backend": "bytecode",
  "download_ms": 120,
  "verify_ms": 3,
  "apply_ms": 40,
  "patch_size_bytes": 12345,
  "installed_size_bytes": 300000,
  "startup_extra_ms": 8,
  "interpreted_function_calls": 1024,
  "aot_function_calls": 982341,
  "interpreter_ratio": 0.001
}

目标：

* patch check 不阻塞 UI thread。
* 启动额外耗时可观测。
* patch apply 使用后台线程。
* installed patch 最多保留 2 份。
* interpreter ratio 可上报，用于判断是否需要新 store release。

⸻

21. 失败处理

场景	行为
无网络	使用当前 active patch 或 baseline
patch check 失败	静默失败，下次启动重试
下载中断	删除 temp 文件
hash mismatch	拒绝安装，上报事件
signature invalid	拒绝安装，上报安全事件
apply diff 失败	保留当前版本，上报事件
patched app crash before success	标记 patch bad，回滚
server rollback	下次 check 返回 rollback manifest
unsupported Dart change	Rust CLI patch 阶段失败，不上传

⸻

22. Code agent 注意事项

实现时遵守：

* 先做能跑通的最小闭环，不要一开始深改 Dart VM。
* 每个 phase 都必须有 example app 和 e2e test。
* Engine patch 不要硬编码 Flutter 单一版本路径；通过 symbol/search 定位。
* 所有外部输入都必须校验。
* 所有文件安装都必须 temp + fsync + atomic rename。
* 不允许 UI thread 网络请求。
* 不允许只下载 patch 不验签。
* 不允许 patch 改 native code。
* 不允许 patch 改 Flutter/Dart/Engine revision。
* Rust CLI 对 unsupported change 必须 fail fast。
* P0 的 snapshot_replace 明确标记为 policy-sensitive backend。
* iOS 永远不实现 downloaded executable backend。

⸻

23. 最小可交付 Definition of Done

examples/counter_app 完成以下脚本：

# 1. 创建 release
fcb release android --example examples/counter_app
# 2. 安装 release APK
adb install build/app/outputs/flutter-apk/app-release.apk
# 3. 修改 Dart 文案 1 -> 2
perl -pi -e 's/Counter: 1/Counter: 2/g' examples/counter_app/lib/main.dart
# 4. 创建 patch
fcb patch android --release-version 1.0.0+1
# 5. 启动 App，下载 patch
adb shell am start -n com.example.counter/.MainActivity
# 6. 重启 App，验证显示 Counter: 2
adb shell am force-stop com.example.counter
adb shell am start -n com.example.counter/.MainActivity

自动化断言：

* patch manifest 签名有效。
* patch payload hash 正确。
* App 第一次启动下载 patch 但仍可显示 baseline。
* App 第二次启动显示 patched result。
* crash patch 被回滚。
* invalid signature patch 不生效。
* staged patch 不影响 stable channel。

⸻

24. 更好的方案选择

24.1 直接使用 Shorebird

如果目标是生产上线，优先用 Shorebird。原因是完整方案需要长期维护 Flutter Engine/Dart SDK fork，而 Shorebird 已经公开说明其实现涉及 Flutter/Dart 多仓库 fork、custom interpreter、linker、updater 和云端发布系统。 

适合：

* 希望更新任意 Dart code。
* 希望少改业务代码。
* 希望有现成灰度、回滚、CI 集成。
* 团队不想长期维护编译器/VM fork。

24.2 Remote Config / Feature Flags

适合：

* 开关功能。
* 调整文案、阈值、实验参数。
* 不需要新增代码路径。

限制：Remote Config/LaunchDarkly 类系统改变配置，不替换设备上的代码；Shorebird FAQ 也明确区分了 code push 与配置系统。 

24.3 Server-driven UI / DSL

适合：

* 首页、活动页、表单、运营位。
* 合规压力小。
* 可控组件集合。

限制：

* 不是任意 Dart 热更新。
* 需要预先内置组件和 schema。
* 复杂业务逻辑仍需发版或 bytecode interpreter。

24.4 自研 restricted bytecode

适合：

* 有强合规要求。
* 可接受只 patch 部分业务逻辑。
* 团队不想 fork Dart VM 到很深。

限制：

* 对业务代码有 annotation/codegen 侵入。
* 不支持任意 Flutter/Dart 变更。
* 性能和语义兼容性需要持续补齐。

⸻

25. 推荐最终路线

生产短期：Shorebird 或 Remote Config + Server-driven UI
自研中期：
  P0 Android snapshot_replace 验证全链路
  P1 restricted bytecode 支持 iOS/Play 合规路线
  P1.5 annotation/codegen 降低业务接入成本
自研长期：
  P2 Dart VM fork + function linker + interpreter
  P3 更完整 Dart 语义、async、generic、widget build patch

最重要的工程判断：热更新系统的难点不在“下载一个 diff”，而在“让 release AOT Flutter 在不违反平台规则的前提下执行新 Dart 语义，并在失败时安全回滚”。
