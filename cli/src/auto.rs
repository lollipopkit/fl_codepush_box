use clap::Args as ClapArgs;
use fcb_core::build_info::{BuildInfo, BuildInfoComparison, BUILD_INFO_SCHEMA_VERSION};
use fcb_core::config::LocalBuildConfig;
use fcb_core::crypto;
use fcb_core::linker::{KernelInventory, LinkerPlan};
use fcb_core::manifest::{self, ReleaseManifest};
use fcb_core::{err, fcb_dir, Result};
use serde::{Deserialize, Serialize};
use std::collections::{BTreeMap, BTreeSet};
use std::fs;
use std::path::{Path, PathBuf};
use std::process::Command as ProcessCommand;
use uuid::Uuid;

const INTERPRETER_RATIO_WARNING_THRESHOLD: f64 = 0.05;

#[derive(Clone, Debug, Default, ClapArgs)]
pub(crate) struct BuildOptions {
    #[arg(long)]
    pub(crate) project: Option<PathBuf>,
    #[arg(long)]
    pub(crate) flutter: Option<PathBuf>,
    #[arg(long)]
    pub(crate) target: Option<String>,
    #[arg(long)]
    pub(crate) build_mode: Option<String>,
    #[arg(long)]
    pub(crate) flavor: Option<String>,
    #[arg(long = "dart-define")]
    pub(crate) dart_defines: Vec<String>,
    #[arg(long = "ignore-dart-define")]
    pub(crate) ignored_dart_define_keys: Vec<String>,
    #[arg(long)]
    pub(crate) ios_sdk: Option<String>,
    #[arg(long)]
    pub(crate) local_engine: Option<String>,
    #[arg(long)]
    pub(crate) local_engine_host: Option<String>,
    #[arg(long)]
    pub(crate) local_engine_src_path: Option<PathBuf>,
}

#[derive(Debug, Clone)]
pub(crate) struct ResolvedBuild {
    pub(crate) project: PathBuf,
    pub(crate) flutter: PathBuf,
    pub(crate) target: String,
    pub(crate) build_mode: String,
    pub(crate) flavor: Option<String>,
    pub(crate) dart_defines: BTreeMap<String, String>,
    pub(crate) ignored_dart_define_keys: BTreeSet<String>,
    pub(crate) ios_sdk: String,
    pub(crate) local_engine: Option<String>,
    pub(crate) local_engine_host: Option<String>,
    pub(crate) local_engine_src_path: Option<PathBuf>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub(crate) struct ReleaseCacheMetadata {
    pub(crate) schema_version: u32,
    pub(crate) manifest: ReleaseManifest,
    pub(crate) build_info: BuildInfo,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub(crate) struct PatchReport {
    pub(crate) schema_version: u32,
    pub(crate) status: String,
    pub(crate) backend: String,
    pub(crate) platform: String,
    pub(crate) arch: String,
    pub(crate) release_version: String,
    pub(crate) patch_number: u32,
    #[serde(default)]
    pub(crate) build_comparison: Option<BuildInfoComparison>,
    #[serde(default)]
    pub(crate) linker_plan: Option<LinkerPlan>,
    #[serde(default)]
    pub(crate) payload_hash: Option<String>,
    #[serde(default)]
    pub(crate) ignored_dart_define_keys: Vec<String>,
    #[serde(default)]
    pub(crate) messages: Vec<String>,
}

impl PatchReport {
    pub(crate) fn new(
        backend: &str,
        platform: &str,
        arch: &str,
        release_version: &str,
        patch_number: u32,
    ) -> Self {
        Self {
            schema_version: 1,
            status: "started".to_string(),
            backend: backend.to_string(),
            platform: platform.to_string(),
            arch: arch.to_string(),
            release_version: release_version.to_string(),
            patch_number,
            build_comparison: None,
            linker_plan: None,
            payload_hash: None,
            ignored_dart_define_keys: Vec::new(),
            messages: Vec::new(),
        }
    }
}

pub(crate) fn estimated_interpreter_ratio(plan: &LinkerPlan) -> f64 {
    let total = plan.interpret.len() + plan.unchanged.len();
    if total == 0 {
        0.0
    } else {
        plan.interpret.len() as f64 / total as f64
    }
}

pub(crate) fn interpreter_ratio_warning(plan: &LinkerPlan) -> Option<String> {
    let ratio = estimated_interpreter_ratio(plan);
    if ratio <= INTERPRETER_RATIO_WARNING_THRESHOLD {
        return None;
    }
    Some(format!(
        "warning: estimated interpreter_ratio {:.2}% exceeds {:.2}%; consider shipping a new release",
        ratio * 100.0,
        INTERPRETER_RATIO_WARNING_THRESHOLD * 100.0,
    ))
}

pub(crate) fn record_interpreter_ratio_warning(report: &mut PatchReport) -> Option<String> {
    let warning = interpreter_ratio_warning(report.linker_plan.as_ref()?)?;
    if !report.messages.iter().any(|message| message == &warning) {
        report.messages.push(warning.clone());
    }
    Some(warning)
}

pub(crate) trait BuildContext {
    fn config_path(&self) -> &Path;
    fn build_config(&self) -> &LocalBuildConfig;
}

pub(crate) fn resolve_build<C: BuildContext>(
    context: &C,
    platform: &str,
    arch: &str,
    options: &BuildOptions,
    example: Option<&Path>,
) -> Result<ResolvedBuild> {
    let config_dir = context
        .config_path()
        .parent()
        .unwrap_or_else(|| Path::new("."));
    let build_config = context.build_config();
    let platform_config = build_config.platforms.get(platform);
    let project = options
        .project
        .clone()
        .or_else(|| example.map(PathBuf::from))
        .or_else(|| build_config.project.as_ref().map(PathBuf::from))
        .unwrap_or_else(|| config_dir.to_path_buf());
    if options.project.is_none() && example.is_some() {
        eprintln!("warning: --example is deprecated; use --project");
    }
    let flutter = options
        .flutter
        .clone()
        .or_else(|| build_config.flutter.as_ref().map(PathBuf::from))
        .unwrap_or_else(default_flutter_path);
    let target = options
        .target
        .clone()
        .or_else(|| build_config.target.clone())
        .unwrap_or_else(|| "lib/main.dart".to_string());
    let build_mode = options
        .build_mode
        .clone()
        .or_else(|| build_config.build_mode.clone())
        .unwrap_or_else(|| "release".to_string());
    if !matches!(build_mode.as_str(), "debug" | "profile" | "release") {
        return Err(err(format!("unsupported build mode {build_mode}")));
    }
    let mut dart_defines = build_config.dart_defines.clone();
    for define in &options.dart_defines {
        let (key, value) = define
            .split_once('=')
            .ok_or_else(|| err(format!("--dart-define must be KEY=VALUE, got {define}")))?;
        dart_defines.insert(key.to_string(), value.to_string());
    }
    let mut ignored = build_config.ignored_dart_define_keys.clone();
    ignored.extend(options.ignored_dart_define_keys.iter().cloned());
    let ios_sdk = options
        .ios_sdk
        .clone()
        .or_else(|| platform_config.and_then(|config| config.sdk.clone()))
        .unwrap_or_else(|| "iphoneos".to_string());
    if platform == "ios" && !matches!(ios_sdk.as_str(), "iphoneos" | "iphonesimulator") {
        return Err(err(format!("unsupported iOS sdk {ios_sdk}")));
    }
    if platform == "android" {
        if let Some(config) = platform_config {
            if !config.abis.is_empty() && !config.abis.iter().any(|abi| abi == arch) {
                return Err(err(format!(
                    "arch {arch} is not in configured Android ABI list: {}",
                    config.abis.join(", ")
                )));
            }
        }
    }
    Ok(ResolvedBuild {
        project: resolve_path(config_dir, &project),
        flutter: resolve_path(config_dir, &flutter),
        target,
        build_mode,
        flavor: options
            .flavor
            .clone()
            .or_else(|| build_config.flavor.clone()),
        dart_defines,
        ignored_dart_define_keys: ignored,
        ios_sdk,
        local_engine: options
            .local_engine
            .clone()
            .or_else(|| platform_config.and_then(|config| config.local_engine.clone())),
        local_engine_host: options
            .local_engine_host
            .clone()
            .or_else(|| platform_config.and_then(|config| config.local_engine_host.clone())),
        local_engine_src_path: options
            .local_engine_src_path
            .clone()
            .or_else(|| {
                platform_config
                    .and_then(|config| config.local_engine_src_path.as_ref())
                    .map(PathBuf::from)
            })
            .map(|path| resolve_path(config_dir, &path)),
    })
}

pub(crate) fn run_flutter_build(
    platform: &str,
    arch: &str,
    backend: &str,
    build: &ResolvedBuild,
) -> Result<()> {
    if !build.project.join("pubspec.yaml").exists() {
        return Err(err(format!(
            "project {} does not contain pubspec.yaml",
            build.project.display()
        )));
    }
    let mut command = ProcessCommand::new(&build.flutter);
    command
        .current_dir(&build.project)
        .arg("--no-version-check")
        .arg("build");
    match backend {
        "bytecode" => {
            command.arg("bundle");
            command.arg(format!("--{}", build.build_mode));
            command.arg("--target").arg(&build.target);
            command
                .arg("--target-platform")
                .arg(bundle_target_platform(platform, arch)?);
        }
        "snapshot_replace" => {
            if platform != "android" {
                return Err(err("snapshot_replace build is only supported for Android"));
            }
            command.arg("apk");
            command.arg(format!("--{}", build.build_mode));
            command.arg("--target").arg(&build.target);
            command
                .arg("--target-platform")
                .arg(android_target_platform(arch)?);
        }
        other => return Err(err(format!("unsupported build backend {other}"))),
    }
    if let Some(flavor) = &build.flavor {
        command.arg("--flavor").arg(flavor);
    }
    for (key, value) in &build.dart_defines {
        command.arg("--dart-define").arg(format!("{key}={value}"));
    }
    if let Some(path) = &build.local_engine_src_path {
        command.arg("--local-engine-src-path").arg(path);
    }
    if let Some(host) = &build.local_engine_host {
        command.arg("--local-engine-host").arg(host);
    }
    if let Some(engine) = &build.local_engine {
        command.arg("--local-engine").arg(engine);
    }
    let status = command.status()?;
    if !status.success() {
        return Err(err(format!(
            "flutter build failed for {platform}/{backend} with status {status}"
        )));
    }
    Ok(())
}

pub(crate) fn android_target_platform(arch: &str) -> Result<&'static str> {
    match arch {
        "arm64-v8a" => Ok("android-arm64"),
        "armeabi-v7a" => Ok("android-arm"),
        "x86_64" => Ok("android-x64"),
        other => Err(err(format!("unsupported Android arch {other}"))),
    }
}

pub(crate) fn bundle_target_platform(platform: &str, arch: &str) -> Result<&'static str> {
    match platform {
        "ios" => Ok("ios"),
        "android" => android_target_platform(arch),
        other => Err(err(format!("unsupported bundle platform {other}"))),
    }
}

pub(crate) fn collect_release_artifact(
    release_dir: &Path,
    platform: &str,
    arch: &str,
    backend: &str,
    build: &ResolvedBuild,
) -> Result<Vec<u8>> {
    match backend {
        "snapshot_replace" => {
            if platform != "android" {
                return Err(err(
                    "snapshot_replace release artifact is only supported on Android",
                ));
            }
            let source = android_app_so_path(&build.project, arch);
            let artifact = fs::read(&source).map_err(|e| {
                err(format!(
                    "failed to read Android app.so at {}: {e}",
                    source.display()
                ))
            })?;
            fs::write(release_dir.join("app.so"), &artifact)?;
            Ok(artifact)
        }
        "bytecode" => {
            let inventory = generate_kernel_inventory(build)?;
            let bytes = serde_json::to_vec_pretty(&inventory)?;
            fs::write(release_dir.join("kernel_inventory.json"), &bytes)?;
            // ADR-#2: capture the real AOT entry-point set for the call_original
            // gate. Best-effort — never fail the release on this.
            let dill = newest_non_empty_app_dill(&build.project);
            match crate::aot_entry_points::generate_aot_entry_points(
                release_dir,
                &flutter_sdk_root(&build.flutter),
                dill.as_deref(),
                platform,
                arch,
            ) {
                Ok(Some(count)) => {
                    eprintln!("recorded {count} AOT entry points for call_original gate")
                }
                Ok(None) => eprintln!(
                    "warning: gen_snapshot or app.dill unavailable; skipped AOT entry-point capture (ADR-#2)"
                ),
                Err(e) => eprintln!("warning: AOT entry-point capture failed: {e}"),
            }
            Ok(bytes)
        }
        other => Err(err(format!("unsupported release backend: {other}"))),
    }
}

pub(crate) fn android_app_so_path(project: &Path, arch: &str) -> PathBuf {
    project
        .join("build/app/intermediates/flutter/release")
        .join(arch)
        .join("app.so")
}

pub(crate) fn collect_build_info(
    platform: &str,
    arch: &str,
    backend: &str,
    build: &ResolvedBuild,
) -> Result<BuildInfo> {
    let flutter_root = flutter_sdk_root(&build.flutter);
    let engine_root = build
        .local_engine_src_path
        .as_deref()
        .unwrap_or(flutter_root.as_path());
    Ok(BuildInfo {
        schema_version: BUILD_INFO_SCHEMA_VERSION,
        backend: backend.to_string(),
        platform: platform.to_string(),
        arch: arch.to_string(),
        target_platform: target_platform_label(platform, arch, build)?,
        build_mode: build.build_mode.clone(),
        flavor: build.flavor.clone(),
        flutter_tool_rev: flutter_tool_rev(&build.flutter),
        engine_fork_rev: git_rev(engine_root),
        dart_sdk_rev: dart_sdk_git_rev(build),
        pubspec_lock_hash: hash_optional_file(&build.project.join("pubspec.lock"))?,
        asset_hash: hash_build_assets(platform, backend, build)?,
        native_hash: hash_build_native(platform, backend, build)?,
        plugin_hash: hash_build_plugins(platform, backend, build)?,
        obfuscation: false,
        split_debug_info: None,
        dart_defines: build.dart_defines.clone(),
        ignored_dart_define_keys: build.ignored_dart_define_keys.clone(),
    })
}

pub(crate) fn build_info_warnings(build_info: &BuildInfo) -> Vec<String> {
    let mut warnings = Vec::new();
    for (field, value) in [
        ("flutter_tool_rev", build_info.flutter_tool_rev.as_str()),
        ("engine_fork_rev", build_info.engine_fork_rev.as_str()),
        ("dart_sdk_rev", build_info.dart_sdk_rev.as_str()),
    ] {
        if value == "unknown" {
            warnings.push(format!(
                "warning: build_info {field} is unknown; SDK pin protection is weakened"
            ));
        }
    }
    warnings
}

pub(crate) fn collect_prebuild_build_info(
    release: &BuildInfo,
    platform: &str,
    arch: &str,
    backend: &str,
    build: &ResolvedBuild,
) -> Result<BuildInfo> {
    let flutter_root = flutter_sdk_root(&build.flutter);
    let engine_root = build
        .local_engine_src_path
        .as_deref()
        .unwrap_or(flutter_root.as_path());
    Ok(BuildInfo {
        schema_version: BUILD_INFO_SCHEMA_VERSION,
        backend: backend.to_string(),
        platform: platform.to_string(),
        arch: arch.to_string(),
        target_platform: target_platform_label(platform, arch, build)?,
        build_mode: build.build_mode.clone(),
        flavor: build.flavor.clone(),
        flutter_tool_rev: flutter_tool_rev(&build.flutter),
        engine_fork_rev: git_rev(engine_root),
        dart_sdk_rev: dart_sdk_git_rev(build),
        pubspec_lock_hash: hash_optional_file(&build.project.join("pubspec.lock"))?,
        asset_hash: release.asset_hash.clone(),
        native_hash: release.native_hash.clone(),
        plugin_hash: release.plugin_hash.clone(),
        obfuscation: release.obfuscation,
        split_debug_info: release.split_debug_info.clone(),
        dart_defines: build.dart_defines.clone(),
        ignored_dart_define_keys: build.ignored_dart_define_keys.clone(),
    })
}

pub(crate) fn write_release_cache(
    release_dir: &Path,
    manifest: &ReleaseManifest,
    build_info: &BuildInfo,
    artifact: &[u8],
    platform: &str,
    backend: &str,
) -> Result<()> {
    manifest::write_json(&release_dir.join("release_manifest.json"), manifest)?;
    manifest::write_json(&release_dir.join("build_info.json"), build_info)?;
    let metadata = ReleaseCacheMetadata {
        schema_version: 2,
        manifest: manifest.clone(),
        build_info: build_info.clone(),
    };
    manifest::write_json(&release_dir.join("release_cache.json"), &metadata)?;
    if backend == "snapshot_replace" && platform == "android" {
        fs::write(release_dir.join("artifact.bin"), artifact)?;
    }
    Ok(())
}

pub(crate) fn generate_kernel_inventory(build: &ResolvedBuild) -> Result<KernelInventory> {
    let tool = KernelManifestTool::prepare(build)?;
    let output = ProcessCommand::new(&tool.dart)
        .arg(&tool.snapshot)
        .arg("--project")
        .arg(&build.project)
        .arg("--target")
        .arg(&build.target)
        .env("FCB_KERNEL_SDK_ROOT", &tool.sdk_root)
        .env("FCB_KERNEL_TOOL_DIR", &tool.tool_dir)
        .output()?;
    if !output.stderr.is_empty() {
        eprint!("{}", String::from_utf8_lossy(&output.stderr));
    }
    if !output.status.success() {
        let stderr = String::from_utf8_lossy(&output.stderr);
        return Err(err(format!("kernel inventory tool failed: {stderr}")));
    }
    let inventory: KernelInventory = serde_json::from_slice(&output.stdout)?;
    inventory.validate()?;
    Ok(inventory)
}

pub(crate) fn compile_kernel_plan(
    build: &ResolvedBuild,
    plan: &LinkerPlan,
) -> Result<Option<Vec<u8>>> {
    if plan.interpret.is_empty() {
        return Ok(None);
    }
    let patch_dill = newest_non_empty_app_dill(&build.project).ok_or_else(|| {
        err(format!(
            "missing Flutter app.dill under {}; rerun flutter build bundle before compiling bytecode",
            build.project.join(".dart_tool/flutter_build").display()
        ))
    })?;
    let tool = KernelManifestTool::prepare(build)?;
    let temp = std::env::temp_dir().join(format!("fcb-kernel-compile-{}", Uuid::new_v4()));
    fs::create_dir_all(&temp)?;
    let plan_path = temp.join("linker_plan.json");
    let out_path = temp.join("module.fcbm");
    manifest::write_json(&plan_path, plan)?;
    let output = ProcessCommand::new(&tool.dart)
        .arg(&tool.snapshot)
        .arg("--compile-from-plan")
        .arg(&plan_path)
        .arg("--patch")
        .arg(&patch_dill)
        .arg("--project")
        .arg(&build.project)
        .arg("--target")
        .arg(&build.target)
        .arg("--format")
        .arg("binary")
        .arg("-o")
        .arg(&out_path)
        .env("FCB_KERNEL_SDK_ROOT", &tool.sdk_root)
        .env("FCB_KERNEL_TOOL_DIR", &tool.tool_dir)
        .output()?;
    if !output.stderr.is_empty() {
        eprint!("{}", String::from_utf8_lossy(&output.stderr));
    }
    if !output.status.success() {
        let _ = fs::remove_dir_all(&temp);
        let stderr = String::from_utf8_lossy(&output.stderr);
        return Err(err(format!("kernel bytecode compiler failed: {stderr}")));
    }
    let bytes = fs::read(&out_path)?;
    let _ = fs::remove_dir_all(&temp);
    Ok(Some(bytes))
}

struct KernelManifestTool {
    dart: PathBuf,
    snapshot: PathBuf,
    sdk_root: PathBuf,
    tool_dir: PathBuf,
}

impl KernelManifestTool {
    fn prepare(build: &ResolvedBuild) -> Result<Self> {
        let tool = kernel_inventory_tool_path()?;
        let display_tool = tool.display().to_string();
        if !tool.exists() {
            return Err(err(format!(
                "missing kernel inventory tool {}",
                tool.display()
            )));
        }
        let dart = flutter_dart_path(&build.flutter);
        let cache_dir = fcb_dir().join("tool-cache");
        fs::create_dir_all(&cache_dir)?;
        let tool_hash = hash_optional_file(&tool)?;
        let dart_rev = dart_sdk_rev(&build.flutter)?;
        let key = crypto::sha256_hex(format!("{dart_rev}\n{tool_hash}").as_bytes());
        let key_path = cache_dir.join("fcb_kernel_manifest.key");
        let snapshot = cache_dir.join("fcb_kernel_manifest.dart.snapshot");
        let current_key = fs::read_to_string(&key_path).unwrap_or_default();
        if current_key != key || !snapshot.exists() {
            let status = ProcessCommand::new(&dart)
                .arg("compile")
                .arg("kernel")
                .arg(&tool)
                .arg("-o")
                .arg(&snapshot)
                .status()?;
            if !status.success() {
                return Err(err(format!("failed to compile {display_tool}")));
            }
            fs::write(&key_path, &key)?;
        }
        Ok(Self {
            dart,
            snapshot,
            sdk_root: kernel_sdk_root(&tool, build),
            tool_dir: tool
                .parent()
                .unwrap_or_else(|| Path::new("tool"))
                .to_path_buf(),
        })
    }
}

fn newest_non_empty_app_dill(project: &Path) -> Option<PathBuf> {
    let build_root = project.join(".dart_tool/flutter_build");
    let mut candidates = Vec::new();
    collect_app_dill_candidates(&build_root, &mut candidates);
    candidates.sort_by(|a, b| {
        let a_time = a
            .metadata()
            .and_then(|metadata| metadata.modified())
            .unwrap_or(std::time::UNIX_EPOCH);
        let b_time = b
            .metadata()
            .and_then(|metadata| metadata.modified())
            .unwrap_or(std::time::UNIX_EPOCH);
        b_time.cmp(&a_time)
    });
    candidates.into_iter().next()
}

fn collect_app_dill_candidates(dir: &Path, candidates: &mut Vec<PathBuf>) {
    let Ok(entries) = fs::read_dir(dir) else {
        return;
    };
    for entry in entries.flatten() {
        let path = entry.path();
        if path.is_dir() {
            collect_app_dill_candidates(&path, candidates);
        } else if path.file_name().and_then(|name| name.to_str()) == Some("app.dill")
            && path
                .metadata()
                .map(|metadata| metadata.len() > 0)
                .unwrap_or(false)
        {
            candidates.push(path);
        }
    }
}

fn kernel_inventory_tool_path() -> Result<PathBuf> {
    if let Some(path) = std::env::var_os("FCB_KERNEL_MANIFEST_TOOL") {
        return Ok(PathBuf::from(path));
    }
    let cwd_tool = PathBuf::from("tool/fcb_kernel_manifest.dart");
    if cwd_tool.exists() {
        return Ok(cwd_tool);
    }
    if let Ok(exe) = std::env::current_exe() {
        for ancestor in exe.ancestors() {
            let candidate = ancestor.join("tool/fcb_kernel_manifest.dart");
            if candidate.exists() {
                return Ok(candidate);
            }
        }
    }
    Ok(cwd_tool)
}

fn kernel_sdk_root(tool: &Path, build: &ResolvedBuild) -> PathBuf {
    if let Some(path) = std::env::var_os("FCB_KERNEL_SDK_ROOT") {
        let path = PathBuf::from(path);
        if path.exists() {
            return path;
        }
    }
    if let Some(path) = embedded_dart_sdk_root(build) {
        return path;
    }
    for ancestor in tool.ancestors() {
        let candidate = ancestor.join("vendor/flutter/engine/src/flutter/third_party/dart");
        if candidate.exists() {
            return candidate;
        }
    }
    PathBuf::from("vendor/flutter/engine/src/flutter/third_party/dart")
}

pub(crate) fn read_release_cache(release_dir: &Path) -> Result<ReleaseCacheMetadata> {
    let metadata_path = release_dir.join("release_cache.json");
    if metadata_path.exists() {
        let metadata: ReleaseCacheMetadata = manifest::read_json(&metadata_path)?;
        if metadata.schema_version != 2 {
            return Err(err(format!(
                "unsupported release cache schema_version {}",
                metadata.schema_version
            )));
        }
        metadata.build_info.validate()?;
        return Ok(metadata);
    }
    Err(err(format!(
        "missing release metadata {}; run 'fcb release' first",
        metadata_path.display()
    )))
}

pub(crate) fn write_patch_report(out: &Path, report: &PatchReport) -> Result<()> {
    manifest::write_json(&out.join("patch_report.json"), report)
}

fn default_flutter_path() -> PathBuf {
    let vendored = PathBuf::from("vendor/flutter/bin/flutter");
    if vendored.exists() {
        vendored
    } else {
        PathBuf::from("flutter")
    }
}

fn target_platform_label(platform: &str, arch: &str, build: &ResolvedBuild) -> Result<String> {
    match platform {
        "android" => Ok(android_target_platform(arch)?.to_string()),
        "ios" => Ok(build.ios_sdk.clone()),
        other => Err(err(format!("unsupported platform {other}"))),
    }
}

fn command_rev(command: &Path, args: &[&str]) -> Result<String> {
    let output = ProcessCommand::new(command).args(args).output()?;
    if !output.status.success() {
        return Ok(format!("{}:unknown", command.display()));
    }
    let stdout = String::from_utf8_lossy(&output.stdout);
    Ok(stdout
        .lines()
        .next()
        .unwrap_or("unknown")
        .trim()
        .to_string())
}

fn dart_sdk_rev(flutter: &Path) -> Result<String> {
    let dart = flutter_dart_path(flutter);
    if dart.exists() {
        command_rev(&dart, &["--version"])
    } else {
        Ok("dart:unknown".to_string())
    }
}

fn flutter_tool_rev(flutter: &Path) -> String {
    git_rev(&flutter_sdk_root(flutter))
}

fn dart_sdk_git_rev(build: &ResolvedBuild) -> String {
    if let Some(sdk_root) = embedded_dart_sdk_root(build) {
        let rev = git_rev(&sdk_root);
        if rev != "unknown" {
            return rev;
        }
    }
    let flutter = &build.flutter;
    let sdk_root = flutter_sdk_root(flutter).join("bin/cache/dart-sdk");
    let rev = git_rev(&sdk_root);
    if rev != "unknown" {
        return rev;
    }
    "unknown".to_string()
}

fn embedded_dart_sdk_root(build: &ResolvedBuild) -> Option<PathBuf> {
    let mut candidates = Vec::new();
    if let Some(engine_src) = &build.local_engine_src_path {
        candidates.push(engine_src.join("flutter/third_party/dart"));
        candidates.push(engine_src.join("third_party/dart"));
    }
    candidates.push(flutter_sdk_root(&build.flutter).join("engine/src/flutter/third_party/dart"));
    candidates
        .into_iter()
        .find(|path| path.join("runtime/vm").exists())
}

fn flutter_sdk_root(flutter: &Path) -> PathBuf {
    flutter
        .parent()
        .and_then(Path::parent)
        .map(Path::to_path_buf)
        .unwrap_or_else(|| PathBuf::from("vendor/flutter"))
}

fn flutter_dart_path(flutter: &Path) -> PathBuf {
    flutter
        .parent()
        .and_then(Path::parent)
        .map(|root| root.join("bin/cache/dart-sdk/bin/dart"))
        .unwrap_or_else(|| PathBuf::from("dart"))
}

fn git_rev(path: &Path) -> String {
    let output = ProcessCommand::new("git")
        .arg("-C")
        .arg(path)
        .arg("rev-parse")
        .arg("HEAD")
        .output();
    match output {
        Ok(output) if output.status.success() => {
            String::from_utf8_lossy(&output.stdout).trim().to_string()
        }
        _ => "unknown".to_string(),
    }
}

fn hash_optional_file(path: &Path) -> Result<String> {
    if path.exists() {
        Ok(crypto::sha256_hex(&fs::read(path)?))
    } else {
        Ok("missing".to_string())
    }
}

fn hash_build_assets(platform: &str, backend: &str, build: &ResolvedBuild) -> Result<String> {
    if backend == "bytecode" {
        return hash_first_existing(&[
            build
                .project
                .join("build/flutter_assets/AssetManifest.bin.json"),
            build.project.join("build/flutter_assets/AssetManifest.bin"),
            build
                .project
                .join("build/flutter_assets/AssetManifest.json"),
        ]);
    }
    let candidates = match platform {
        "android" => vec![
            build.project.join(
                "build/app/intermediates/flutter/release/flutter_assets/AssetManifest.bin.json",
            ),
            build
                .project
                .join("build/app/intermediates/flutter/release/flutter_assets/AssetManifest.bin"),
            build
                .project
                .join("build/app/intermediates/flutter/release/flutter_assets/AssetManifest.json"),
            build.project.join(
                "build/app/intermediates/assets/release/flutter_assets/AssetManifest.bin.json",
            ),
            build
                .project
                .join("build/app/intermediates/assets/release/flutter_assets/AssetManifest.bin"),
            build
                .project
                .join("build/app/intermediates/assets/release/flutter_assets/AssetManifest.json"),
        ],
        "ios" => vec![
            build
                .project
                .join("build/ios/iphoneos/Runner.app/Frameworks/App.framework/flutter_assets/AssetManifest.bin.json"),
            build
                .project
                .join("build/ios/iphoneos/Runner.app/Frameworks/App.framework/flutter_assets/AssetManifest.bin"),
            build
                .project
                .join("build/ios/iphoneos/Runner.app/Frameworks/App.framework/flutter_assets/AssetManifest.json"),
            build
                .project
                .join("build/ios/iphonesimulator/Runner.app/Frameworks/App.framework/flutter_assets/AssetManifest.bin.json"),
            build
                .project
                .join("build/ios/iphonesimulator/Runner.app/Frameworks/App.framework/flutter_assets/AssetManifest.bin"),
            build
                .project
                .join("build/ios/iphonesimulator/Runner.app/Frameworks/App.framework/flutter_assets/AssetManifest.json"),
        ],
        _ => Vec::new(),
    };
    hash_first_existing(&candidates)
}

fn hash_build_native(platform: &str, backend: &str, build: &ResolvedBuild) -> Result<String> {
    if backend == "bytecode" {
        return Ok("missing".to_string());
    }
    let candidates = match platform {
        "android" => vec![
            build
                .project
                .join("build/app/intermediates/merged_native_libs"),
            build
                .project
                .join("build/app/intermediates/stripped_native_libs"),
        ],
        "ios" => vec![
            build
                .project
                .join("build/ios/iphoneos/Runner.app/Frameworks"),
            build
                .project
                .join("build/ios/iphonesimulator/Runner.app/Frameworks"),
        ],
        _ => Vec::new(),
    };
    if platform == "android" {
        hash_first_existing_excluding(&candidates, &["libapp.so"])
    } else if platform == "ios" {
        hash_first_existing_excluding(&candidates, &["App.framework"])
    } else {
        hash_first_existing(&candidates)
    }
}

fn hash_build_plugins(platform: &str, backend: &str, build: &ResolvedBuild) -> Result<String> {
    if backend == "bytecode" {
        return hash_optional_file(&build.project.join(".flutter-plugins-dependencies"));
    }
    let candidates = match platform {
        "android" => vec![build.project.join(".flutter-plugins-dependencies")],
        "ios" => vec![
            build
                .project
                .join("build/ios/iphoneos/Runner.app/Frameworks"),
            build
                .project
                .join("build/ios/iphonesimulator/Runner.app/Frameworks"),
        ],
        _ => Vec::new(),
    };
    if platform == "ios" {
        hash_first_existing_excluding(&candidates, &["App.framework"])
    } else {
        hash_first_existing(&candidates)
    }
}

fn hash_first_existing(candidates: &[PathBuf]) -> Result<String> {
    for path in candidates {
        if path.exists() {
            return hash_optional_file(path);
        }
    }
    Ok("missing".to_string())
}

fn hash_first_existing_excluding(
    candidates: &[PathBuf],
    excluded_names: &[&str],
) -> Result<String> {
    for path in candidates {
        if path.exists() {
            return hash_path_excluding(path, excluded_names);
        }
    }
    Ok("missing".to_string())
}

fn hash_path_excluding(path: &Path, excluded_names: &[&str]) -> Result<String> {
    if path.is_file() {
        return hash_optional_file(path);
    }
    if !path.exists() {
        return Ok("missing".to_string());
    }
    let mut entries = Vec::new();
    collect_hash_entries_excluding(path, path, &mut entries, excluded_names)?;
    entries.sort_by(|a, b| a.0.cmp(&b.0));
    if entries.is_empty() {
        return Ok("missing".to_string());
    }
    let mut bytes = Vec::new();
    for (rel, hash) in entries {
        bytes.extend_from_slice(rel.as_bytes());
        bytes.push(0);
        bytes.extend_from_slice(hash.as_bytes());
        bytes.push(b'\n');
    }
    Ok(crypto::sha256_hex(&bytes))
}

fn collect_hash_entries_excluding(
    root: &Path,
    path: &Path,
    out: &mut Vec<(String, String)>,
    excluded_names: &[&str],
) -> Result<()> {
    for entry in fs::read_dir(path)? {
        let entry = entry?;
        let path = entry.path();
        let name = entry.file_name();
        let name = name.to_string_lossy();
        if excluded_names
            .iter()
            .any(|excluded| *excluded == name.as_ref())
        {
            continue;
        }
        if matches!(name.as_ref(), ".git" | ".dart_tool" | "build" | ".fcb") {
            continue;
        }
        if path.is_dir() {
            collect_hash_entries_excluding(root, &path, out, excluded_names)?;
        } else if path.is_file() {
            let rel = path
                .strip_prefix(root)
                .unwrap_or(path.as_path())
                .to_string_lossy()
                .replace('\\', "/");
            out.push((rel, crypto::sha256_hex(&fs::read(&path)?)));
        }
    }
    Ok(())
}

fn resolve_path(config_dir: &Path, path: &Path) -> PathBuf {
    let expanded = expand_home(path);
    if expanded.is_absolute() {
        expanded
    } else {
        config_dir.join(expanded)
    }
}

fn expand_home(path: &Path) -> PathBuf {
    let value = path.to_string_lossy();
    if value == "~" {
        if let Some(home) = std::env::var_os("HOME") {
            return PathBuf::from(home);
        }
    } else if let Some(rest) = value.strip_prefix("~/") {
        if let Some(home) = std::env::var_os("HOME") {
            return PathBuf::from(home).join(rest);
        }
    }
    path.to_path_buf()
}

#[cfg(test)]
mod tests {
    use super::{resolve_build, BuildContext, BuildOptions};
    use fcb_core::config::{LocalBuildConfig, LocalPlatformBuildConfig};
    use std::collections::BTreeMap;
    use std::path::{Path, PathBuf};

    struct TestContext {
        config_path: PathBuf,
        build: LocalBuildConfig,
    }

    impl BuildContext for TestContext {
        fn config_path(&self) -> &Path {
            &self.config_path
        }

        fn build_config(&self) -> &LocalBuildConfig {
            &self.build
        }
    }

    #[test]
    fn resolve_build_accepts_example_as_project_alias() {
        let context = TestContext {
            config_path: PathBuf::from("/tmp/fcb-test/fcb.yaml"),
            build: LocalBuildConfig::default(),
        };

        let build = resolve_build(
            &context,
            "android",
            "arm64-v8a",
            &BuildOptions::default(),
            Some(Path::new("example_app")),
        )
        .expect("resolve build");

        assert_eq!(build.project, PathBuf::from("/tmp/fcb-test/example_app"));
    }

    #[test]
    fn resolve_build_rejects_android_arch_outside_configured_abis() {
        let mut platforms = BTreeMap::new();
        platforms.insert(
            "android".to_string(),
            LocalPlatformBuildConfig {
                abis: vec!["arm64-v8a".to_string()],
                ..Default::default()
            },
        );
        let context = TestContext {
            config_path: PathBuf::from("/tmp/fcb-test/fcb.yaml"),
            build: LocalBuildConfig {
                platforms,
                ..Default::default()
            },
        };

        let err = resolve_build(
            &context,
            "android",
            "x86_64",
            &BuildOptions::default(),
            Some(Path::new("example_app")),
        )
        .expect_err("arch mismatch should fail");

        assert!(err.to_string().contains("is not in configured Android ABI"));
    }

    #[test]
    fn resolve_build_rejects_invalid_ios_sdk_override() {
        let context = TestContext {
            config_path: PathBuf::from("/tmp/fcb-test/fcb.yaml"),
            build: LocalBuildConfig::default(),
        };
        let options = BuildOptions {
            ios_sdk: Some("watchos".to_string()),
            ..Default::default()
        };

        let err = resolve_build(
            &context,
            "ios",
            "arm64",
            &options,
            Some(Path::new("example_app")),
        )
        .expect_err("invalid sdk should fail");

        assert!(err.to_string().contains("unsupported iOS sdk"));
    }
}
