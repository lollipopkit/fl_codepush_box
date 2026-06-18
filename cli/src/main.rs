mod auto;
mod bytecode_payload;
mod inspect;

use auto::{
    android_app_so_path, build_info_warnings, collect_build_info, collect_prebuild_build_info,
    collect_release_artifact, compile_kernel_plan, generate_kernel_inventory, read_release_cache,
    record_interpreter_ratio_warning, resolve_build, run_flutter_build, write_patch_report,
    write_release_cache, BuildContext, BuildOptions, PatchReport, ResolvedBuild,
};
use bytecode_payload::{read_bytecode_module, validate_compiled_bytecode_payload};
use clap::{Parser, Subcommand};
use fcb_core::config::{LocalAppContext, LocalBuildConfig, RemoteAppConfig, RemotePlatformEntry};
use fcb_core::crypto;
use fcb_core::diff::{self, BSDIFF_ZSTD_ALGORITHM};
#[cfg(test)]
use fcb_core::linker::LinkerPlan;
use fcb_core::linker::{self, KernelInventory};
use fcb_core::manifest::{
    self, PatchManifest, PatchPolicy, PatchSignature, PayloadManifest, ReleaseManifest,
};
use fcb_core::server_api::{
    CheckRequest, CheckResponse, Client, CreateAppRequest, PatchCheck, PromotePatchRequest,
};
use fcb_core::state::Updater;
use fcb_core::{err, fcb_dir, Result};
use inspect::inspect;
#[cfg(test)]
use serde_json::Value;
use std::fs;
use std::path::{Path, PathBuf};
use uuid::Uuid;

#[cfg(unix)]
use std::os::unix::fs::PermissionsExt;

#[derive(Parser)]
#[command(name = "fcb")]
#[command(about = "Flutter CodePush Box CLI")]
struct Args {
    #[arg(long, env = "FCB_SERVER")]
    server: Option<String>,
    #[arg(long, env = "FCB_CLI_TOKEN")]
    token: Option<String>,
    #[arg(long, env = "FCB_APP")]
    app: Option<String>,
    #[arg(long, env = "FCB_APP_ID")]
    app_id: Option<String>,
    #[arg(long)]
    key_file: Option<PathBuf>,
    #[command(subcommand)]
    command: Command,
}

#[derive(Subcommand)]
enum Command {
    Init {
        #[arg(long, default_value = "FCB App")]
        name: String,
        #[arg(long, default_value = "stable")]
        channel: String,
    },
    App {
        #[command(subcommand)]
        command: AppCommand,
    },
    Doctor,
    Release {
        platform: String,
        #[command(flatten)]
        build: BuildOptions,
        #[arg(long)]
        example: Option<PathBuf>,
        #[arg(long, default_value = "1.0.0+1")]
        release_version: String,
        #[arg(long, default_value = "arm64-v8a")]
        arch: String,
    },
    Patch {
        platform: String,
        #[command(flatten)]
        build: BuildOptions,
        #[arg(long)]
        release_version: String,
        #[arg(long, default_value_t = 1)]
        patch_number: u32,
        #[arg(long, default_value = "arm64-v8a")]
        arch: String,
        #[arg(long)]
        payload: Option<PathBuf>,
    },
    Promote {
        #[arg(long)]
        release_version: String,
        #[arg(long)]
        patch_number: u32,
        #[arg(long, default_value = "android")]
        platform: String,
        #[arg(long, default_value = "arm64-v8a")]
        arch: String,
        #[arg(long, default_value = "stable")]
        channel: String,
        #[arg(long, default_value_t = 100)]
        rollout_percentage: u8,
    },
    Rollback {
        #[arg(long)]
        release_version: String,
        #[arg(long)]
        patch_number: u32,
        #[arg(long, default_value = "android")]
        platform: String,
        #[arg(long, default_value = "arm64-v8a")]
        arch: String,
    },
    Check {
        #[arg(long)]
        release_version: String,
        #[arg(long, default_value = "android")]
        platform: String,
        #[arg(long, default_value = "arm64-v8a")]
        arch: String,
        #[arg(long, default_value = "stable")]
        channel: String,
        #[arg(long, default_value_t = 0)]
        current_patch_number: u32,
        #[arg(long, default_value = "dev-client")]
        client_id: String,
        #[arg(long)]
        install: bool,
        #[arg(long, default_value = ".fcb/cache")]
        cache_dir: PathBuf,
    },
    Install {
        #[arg(long)]
        manifest: PathBuf,
        #[arg(long)]
        payload: PathBuf,
        #[arg(long, default_value = ".fcb/cache")]
        cache_dir: PathBuf,
    },
    MarkSuccess {
        #[arg(long, default_value = ".fcb/cache")]
        cache_dir: PathBuf,
    },
    MarkFailure {
        patch_number: u32,
        #[arg(long, default_value = "manual")]
        reason: String,
        #[arg(long, default_value = ".fcb/cache")]
        cache_dir: PathBuf,
    },
    Inspect {
        kind: String,
        path: PathBuf,
    },
}

#[derive(Subcommand)]
enum AppCommand {
    Add {
        name: String,
        #[arg(long)]
        id: Option<String>,
        #[arg(long, default_value = "stable")]
        channel: String,
    },
}

fn main() {
    if let Err(e) = run() {
        eprintln!("error: {e}");
        std::process::exit(1);
    }
}

fn run() -> Result<()> {
    let args = Args::parse();
    let config_path = Path::new("fcb.yaml");
    let local_context = load_local_context(config_path)?;
    let context = ResolvedContext::new(&args, local_context.as_ref(), config_path);
    match args.command {
        Command::Init { name, channel } => init(&context, &name, &channel),
        Command::App { command } => match command {
            AppCommand::Add { name, id, channel } => app_add(&context, &name, id, &channel),
        },
        Command::Doctor => {
            println!("fcb doctor: ok");
            Ok(())
        }
        Command::Release {
            platform,
            build,
            example,
            release_version,
            arch,
        } => release(
            &context,
            &platform,
            &build,
            example.as_deref(),
            &release_version,
            &arch,
        ),
        Command::Patch {
            platform,
            build,
            release_version,
            patch_number,
            arch,
            payload,
        } => patch(
            &context,
            &platform,
            &build,
            &release_version,
            patch_number,
            &arch,
            payload.as_deref(),
        ),
        Command::Promote {
            release_version,
            patch_number,
            platform,
            arch,
            channel,
            rollout_percentage,
        } => promote(
            &context,
            &release_version,
            patch_number,
            &platform,
            &arch,
            &channel,
            rollout_percentage,
        ),
        Command::Check {
            release_version,
            platform,
            arch,
            channel,
            current_patch_number,
            client_id,
            install,
            cache_dir,
        } => check(CheckCommandInput {
            context: &context,
            release_version: &release_version,
            platform: &platform,
            arch: &arch,
            channel: &channel,
            current_patch_number,
            client_id: &client_id,
            install_patch: install,
            cache_dir: &cache_dir,
        }),
        Command::Install {
            manifest,
            payload,
            cache_dir,
        } => install(&context, &manifest, &payload, &cache_dir),
        Command::MarkSuccess { cache_dir } => {
            Updater::new(cache_dir).mark_success()?;
            println!("launch marked successful");
            Ok(())
        }
        Command::MarkFailure {
            patch_number,
            reason,
            cache_dir,
        } => {
            Updater::new(cache_dir).mark_failure(patch_number, &reason)?;
            println!("patch {patch_number} marked failed");
            Ok(())
        }
        Command::Rollback {
            release_version,
            patch_number,
            platform,
            arch,
        } => rollback(&context, &release_version, patch_number, &platform, &arch),
        Command::Inspect { kind, path } => inspect(&kind, &path),
    }
}

struct ResolvedContext {
    server: String,
    token: Option<String>,
    app: Option<String>,
    app_id: Option<String>,
    key_file: PathBuf,
    config_path: PathBuf,
    build: LocalBuildConfig,
}

impl ResolvedContext {
    fn new(args: &Args, local: Option<&LocalAppContext>, config_path: &Path) -> Self {
        let config_dir = config_path.parent().unwrap_or_else(|| Path::new("."));
        let server = args
            .server
            .clone()
            .or_else(|| local.map(|context| context.server.clone()))
            .unwrap_or_else(|| "http://127.0.0.1:8080".to_string());
        let app = args
            .app
            .clone()
            .or_else(|| local.map(|context| context.app.clone()));
        let key_file = args
            .key_file
            .clone()
            .or_else(|| local.map(|context| PathBuf::from(&context.key_file)))
            .unwrap_or_else(|| PathBuf::from(".fcb/private_key"));
        let key_file = resolve_key_path(config_dir, &key_file);
        Self {
            server,
            token: args.token.clone(),
            app,
            app_id: args.app_id.clone(),
            key_file,
            config_path: config_path.to_path_buf(),
            build: local
                .map(|context| context.build.clone())
                .unwrap_or_default(),
        }
    }
}

impl BuildContext for ResolvedContext {
    fn config_path(&self) -> &Path {
        &self.config_path
    }

    fn build_config(&self) -> &LocalBuildConfig {
        &self.build
    }
}

fn init(context: &ResolvedContext, name: &str, channel: &str) -> Result<()> {
    if context.config_path.exists() {
        return Err(err("fcb.yaml already exists"));
    }
    let key_file = &context.key_file;
    if let Some(parent) = key_file.parent() {
        fs::create_dir_all(parent)?;
    }
    let app_id = Uuid::new_v4().to_string();
    let public_key = if key_file.exists() {
        let key_material = fs::read_to_string(key_file)?;
        crypto::public_key_b64_from_private_key(&key_material)?
    } else {
        let (private_key, public_key) = crypto::generate_keypair_b64();
        fs::write(key_file, private_key)?;
        #[cfg(unix)]
        fs::set_permissions(key_file, fs::Permissions::from_mode(0o600))?;
        public_key
    };
    authed_client(&context.server, context.token.as_deref())?.create_app(&CreateAppRequest {
        id: app_id.clone(),
        name: name.to_string(),
        channel: channel.to_string(),
        public_key,
        platforms: default_platforms(),
    })?;
    LocalAppContext {
        app: name.to_string(),
        server: context.server.clone(),
        key_file: path_for_context(&context.config_path, key_file),
        build: Default::default(),
    }
    .write_yaml(&context.config_path)?;
    println!("APP_ID={app_id}");
    println!("app={name}");
    println!("private_key={}", key_file.display());
    Ok(())
}

fn app_add(context: &ResolvedContext, name: &str, id: Option<String>, channel: &str) -> Result<()> {
    let key_file = &context.key_file;
    if let Some(parent) = key_file.parent() {
        fs::create_dir_all(parent)?;
    }
    let public_key = if key_file.exists() {
        let key_material = fs::read_to_string(key_file)?;
        crypto::public_key_b64_from_private_key(&key_material)?
    } else {
        let (private_key, public_key) = crypto::generate_keypair_b64();
        fs::write(key_file, private_key)?;
        #[cfg(unix)]
        fs::set_permissions(key_file, fs::Permissions::from_mode(0o600))?;
        public_key
    };
    let app_id = id.unwrap_or_else(|| Uuid::new_v4().to_string());
    authed_client(&context.server, context.token.as_deref())?.create_app(&CreateAppRequest {
        id: app_id.clone(),
        name: name.to_string(),
        channel: channel.to_string(),
        public_key,
        platforms: default_platforms(),
    })?;
    LocalAppContext {
        app: name.to_string(),
        server: context.server.clone(),
        key_file: path_for_context(&context.config_path, key_file),
        build: context.build.clone(),
    }
    .write_yaml(&context.config_path)?;
    println!("APP_ID={app_id}");
    println!("app={name}");
    Ok(())
}

fn release(
    context: &ResolvedContext,
    platform: &str,
    build_options: &BuildOptions,
    example: Option<&Path>,
    release_version: &str,
    arch: &str,
) -> Result<()> {
    let client = authed_client(&context.server, context.token.as_deref())?;
    let app = resolve_app(&client, context)?;
    let backend = backend_for(&app, platform)?;
    let build = resolve_build(context, platform, arch, build_options, example)?;
    run_flutter_build(platform, arch, &backend, &build)?;
    let release_dir = release_cache_dir(&app.id, release_version, platform, arch);
    fs::create_dir_all(&release_dir)?;
    let artifact = collect_release_artifact(&release_dir, platform, arch, &backend, &build)?;
    let build_info = collect_build_info(platform, arch, &backend, &build)?;
    for warning in build_info_warnings(&build_info) {
        eprintln!("{warning}");
    }
    let manifest = ReleaseManifest {
        schema_version: 1,
        app_id: app.id.clone(),
        release_version: release_version.to_string(),
        channel: app.channel.clone(),
        platform: platform.to_string(),
        arch: arch.to_string(),
        backend: backend.clone(),
        artifact_hash: crypto::sha256_hex(&artifact),
        artifact_size: artifact.len() as u64,
    };
    write_release_cache(
        &release_dir,
        &manifest,
        &build_info,
        &artifact,
        platform,
        &backend,
    )?;
    client.create_release(&manifest)?;
    println!("{}", release_dir.join("release_manifest.json").display());
    Ok(())
}

fn patch(
    context: &ResolvedContext,
    platform: &str,
    build_options: &BuildOptions,
    release_version: &str,
    patch_number: u32,
    arch: &str,
    payload: Option<&Path>,
) -> Result<()> {
    let client = authed_client(&context.server, context.token.as_deref())?;
    let app = resolve_app(&client, context)?;
    let backend = backend_for(&app, platform)?;
    let out = patch_cache_dir(release_version, patch_number, platform, arch);
    fs::create_dir_all(&out)?;
    let mut report = PatchReport::new(&backend, platform, arch, release_version, patch_number);
    let payload_result = if let Some(path) = payload {
        report
            .messages
            .push("--payload supplied; bypassing automatic build checks".to_string());
        manual_patch_payload(
            &app,
            &backend,
            release_version,
            patch_number,
            platform,
            arch,
            path,
        )
    } else {
        automatic_patch_payload(AutomaticPatchPayloadInput {
            context,
            app: &app,
            backend: &backend,
            platform,
            build_options,
            release_version,
            patch_number,
            arch,
            out: &out,
            report: &mut report,
        })
    };

    let (payload_bytes, payload_kind, diff_algorithm, base_hash, output_hash, artifact) =
        match payload_result {
            Ok(Some(value)) => value,
            Ok(None) => {
                report.status = "no_op".to_string();
                report
                    .messages
                    .push("no-op: 0 functions changed, no patch created".to_string());
                write_patch_report(&out, &report)?;
                println!("no-op: 0 functions changed, no patch created");
                println!("{}", out.join("patch_report.json").display());
                return Ok(());
            }
            Err(e) => {
                report.status = "rejected".to_string();
                report.messages.push(e.to_string());
                write_patch_report(&out, &report)?;
                return Err(e);
            }
        };

    fs::write(out.join("payload.bin"), &payload_bytes)?;
    if let Some(artifact) = &artifact {
        fs::write(out.join("artifact.bin"), artifact)?;
    }
    let payload_hash = crypto::sha256_hex(&payload_bytes);
    report.payload_hash = Some(payload_hash.clone());
    let private_key = load_private_key(&context.key_file)?;
    let mut manifest = PatchManifest {
        schema_version: 1,
        app_id: app.id.clone(),
        release_version: release_version.to_string(),
        patch_number,
        channel: app.channel.clone(),
        created_at: "1970-01-01T00:00:00Z".to_string(),
        backend: backend.clone(),
        platform: platform.to_string(),
        arch: arch.to_string(),
        payload: PayloadManifest {
            kind: payload_kind.to_string(),
            compression: "none".to_string(),
            hash: payload_hash.clone(),
            size: payload_bytes.len() as u64,
            download_url: object_key(
                &app.id,
                release_version,
                platform,
                arch,
                patch_number,
                "payload.bin",
            ),
            diff_algorithm,
            base_hash,
            output_hash,
        },
        policy: PatchPolicy {
            rollout_percentage: 0,
            allow_downgrade: false,
        },
        signature: PatchSignature {
            algorithm: "ed25519".to_string(),
            key_id: app.id.clone(),
            value: String::new(),
        },
    };
    manifest::sign_patch_manifest(&mut manifest, private_key.trim())?;
    manifest::write_json(&out.join("patch_manifest.json"), &manifest)?;
    client.create_patch(&manifest, &payload_bytes)?;
    report.status = "created".to_string();
    write_patch_report(&out, &report)?;
    println!("{}", out.join("patch_manifest.json").display());
    println!("{}", out.join("patch_report.json").display());
    println!("payload_sha256={payload_hash}");
    Ok(())
}

type PatchPayloadResult = (
    Vec<u8>,
    &'static str,
    Option<String>,
    Option<String>,
    Option<String>,
    Option<Vec<u8>>,
);

struct AutomaticPatchPayloadInput<'a> {
    context: &'a ResolvedContext,
    app: &'a RemoteAppConfig,
    backend: &'a str,
    platform: &'a str,
    build_options: &'a BuildOptions,
    release_version: &'a str,
    patch_number: u32,
    arch: &'a str,
    out: &'a Path,
    report: &'a mut PatchReport,
}

struct CheckCommandInput<'a> {
    context: &'a ResolvedContext,
    release_version: &'a str,
    platform: &'a str,
    arch: &'a str,
    channel: &'a str,
    current_patch_number: u32,
    client_id: &'a str,
    install_patch: bool,
    cache_dir: &'a Path,
}

struct DownloadInstallInput<'a> {
    context: &'a ResolvedContext,
    client: &'a Client,
    response: &'a CheckResponse,
    app_id: &'a str,
    release_version: &'a str,
    platform: &'a str,
    arch: &'a str,
    cache_dir: &'a Path,
}

fn manual_patch_payload(
    app: &RemoteAppConfig,
    backend: &str,
    release_version: &str,
    patch_number: u32,
    platform: &str,
    arch: &str,
    path: &Path,
) -> Result<Option<PatchPayloadResult>> {
    let target_artifact = fs::read(path)?;
    if backend == "snapshot_replace" {
        let base =
            snapshot_replace_diff_base(&app.id, release_version, platform, arch, patch_number)?;
        Ok(Some((
            diff::create_bsdiff_zstd(&base, &target_artifact)?,
            "binary_diff",
            Some(BSDIFF_ZSTD_ALGORITHM.to_string()),
            Some(crypto::sha256_hex(&base)),
            Some(crypto::sha256_hex(&target_artifact)),
            Some(target_artifact),
        )))
    } else if backend == "bytecode" {
        let module = read_bytecode_module(&target_artifact)?;
        Ok(Some((
            module.to_vec()?,
            "bytecode_module",
            None,
            None,
            None,
            None,
        )))
    } else {
        Err(err(format!("unsupported patch backend: {backend}")))
    }
}

fn automatic_patch_payload(
    input: AutomaticPatchPayloadInput<'_>,
) -> Result<Option<PatchPayloadResult>> {
    let AutomaticPatchPayloadInput {
        context,
        app,
        backend,
        platform,
        build_options,
        release_version,
        patch_number,
        arch,
        out,
        report,
    } = input;
    let release_dir = release_cache_dir(&app.id, release_version, platform, arch);
    if !release_dir.exists() {
        return Err(err(format!(
            "missing release cache {}; run 'fcb release' first",
            release_dir.display()
        )));
    }
    let release_metadata = read_release_cache(&release_dir)?;
    let build = resolve_build(context, platform, arch, build_options, None)?;
    let prebuild_info = collect_prebuild_build_info(
        &release_metadata.build_info,
        platform,
        arch,
        backend,
        &build,
    )?;
    let prebuild_comparison = release_metadata
        .build_info
        .compare_for_patch(&prebuild_info);
    report.ignored_dart_define_keys = prebuild_info
        .ignored_dart_define_keys
        .iter()
        .cloned()
        .collect();
    report.build_comparison = Some(prebuild_comparison.clone());
    if !prebuild_comparison.is_ok() {
        write_patch_report(out, report)?;
        return Err(err(format!(
            "release was built with different config; see {}",
            out.join("patch_report.json").display()
        )));
    }
    for warning in build_info_warnings(&prebuild_info) {
        report.messages.push(warning);
    }
    run_flutter_build(platform, arch, backend, &build)?;
    let patch_build_info = collect_build_info(platform, arch, backend, &build)?;
    let comparison = release_metadata
        .build_info
        .compare_for_patch(&patch_build_info);
    report.ignored_dart_define_keys = patch_build_info
        .ignored_dart_define_keys
        .iter()
        .cloned()
        .collect();
    report.build_comparison = Some(comparison.clone());
    if !comparison.is_ok() {
        write_patch_report(out, report)?;
        return Err(err(format!(
            "release was built with different config; see {}",
            out.join("patch_report.json").display()
        )));
    }

    match backend {
        "snapshot_replace" => {
            automatic_snapshot_payload(app, release_version, patch_number, platform, arch, &build)
        }
        "bytecode" => automatic_bytecode_payload(&release_dir, &build, report),
        other => Err(err(format!("unsupported patch backend: {other}"))),
    }
}

fn automatic_snapshot_payload(
    app: &RemoteAppConfig,
    release_version: &str,
    patch_number: u32,
    platform: &str,
    arch: &str,
    build: &ResolvedBuild,
) -> Result<Option<PatchPayloadResult>> {
    if platform != "android" {
        return Err(err("snapshot_replace is only supported for Android"));
    }
    let target_artifact = fs::read(android_app_so_path(&build.project, arch))?;
    let base = snapshot_replace_diff_base(&app.id, release_version, platform, arch, patch_number)?;
    Ok(Some((
        diff::create_bsdiff_zstd(&base, &target_artifact)?,
        "binary_diff",
        Some(BSDIFF_ZSTD_ALGORITHM.to_string()),
        Some(crypto::sha256_hex(&base)),
        Some(crypto::sha256_hex(&target_artifact)),
        Some(target_artifact),
    )))
}

fn automatic_bytecode_payload(
    release_dir: &Path,
    build: &ResolvedBuild,
    report: &mut PatchReport,
) -> Result<Option<PatchPayloadResult>> {
    let release_inventory: KernelInventory =
        manifest::read_json(&release_dir.join("kernel_inventory.json"))?;
    let patch_inventory = generate_kernel_inventory(build)?;
    let plan = linker::plan_bytecode_link(&release_inventory, &patch_inventory)?;
    report.linker_plan = Some(plan.clone());
    if let Some(warning) = record_interpreter_ratio_warning(report) {
        eprintln!("{warning}");
    }
    if plan.has_rejects() {
        return Err(err("bytecode patch rejected; see patch_report.json"));
    }
    if plan.changed_function_count() == 0 {
        return Ok(None);
    }
    let Some(bytes) = compile_kernel_plan(build, &plan)? else {
        return Ok(None);
    };
    Ok(Some((
        validate_compiled_bytecode_payload(&bytes)?,
        "bytecode_module",
        None,
        None,
        None,
        None,
    )))
}

#[cfg(test)]
fn bytecode_payload_from_inventories(
    release_inventory: &KernelInventory,
    patch_inventory: &KernelInventory,
    report: &mut PatchReport,
) -> Result<Option<PatchPayloadResult>> {
    let plan = linker::plan_bytecode_link(release_inventory, patch_inventory)?;
    report.linker_plan = Some(plan.clone());
    record_interpreter_ratio_warning(report);
    if plan.has_rejects() {
        return Err(err("bytecode patch rejected; see patch_report.json"));
    }
    if plan.changed_function_count() == 0 {
        return Ok(None);
    }
    let _sources = interpret_sources(patch_inventory, &plan)?;
    Err(err(
        "test bytecode payload helper no longer compiles source JSON; use Dart compile-from-plan",
    ))
}

#[cfg(test)]
fn interpret_sources(patch_inventory: &KernelInventory, plan: &LinkerPlan) -> Result<Vec<Value>> {
    use fcb_core::linker::FunctionInventoryEntry;
    use std::collections::BTreeMap;

    let mut functions = BTreeMap::<String, &FunctionInventoryEntry>::new();
    for function in &patch_inventory.functions {
        functions.insert(function.function_id.clone(), function);
    }
    let mut sources = Vec::new();
    for decision in &plan.interpret {
        let function = functions.get(&decision.function_id).ok_or_else(|| {
            err(format!(
                "linker selected missing function {}",
                decision.function_id
            ))
        })?;
        let source = function.bytecode_source.clone().ok_or_else(|| {
            err(format!(
                "function {} has no bytecode source",
                decision.function_id
            ))
        })?;
        sources.push(source);
    }
    Ok(sources)
}

fn promote(
    context: &ResolvedContext,
    release_version: &str,
    patch_number: u32,
    platform: &str,
    arch: &str,
    channel: &str,
    rollout_percentage: u8,
) -> Result<()> {
    let client = authed_client(&context.server, context.token.as_deref())?;
    let app = resolve_app(&client, context)?;
    client.promote_patch(&PromotePatchRequest {
        app_id: app.id,
        release_version: release_version.to_string(),
        platform: platform.to_string(),
        arch: arch.to_string(),
        patch_number,
        channel: channel.to_string(),
        rollout_percentage,
    })?;
    println!("patch {patch_number} promoted to {channel} at {rollout_percentage}%");
    Ok(())
}

fn rollback(
    context: &ResolvedContext,
    release_version: &str,
    patch_number: u32,
    platform: &str,
    arch: &str,
) -> Result<()> {
    let client = authed_client(&context.server, context.token.as_deref())?;
    let app = resolve_app(&client, context)?;
    client.rollback_patch(&PromotePatchRequest {
        app_id: app.id,
        release_version: release_version.to_string(),
        platform: platform.to_string(),
        arch: arch.to_string(),
        patch_number,
        channel: String::new(),
        rollout_percentage: 0,
    })?;
    println!("patch {patch_number} rolled back");
    Ok(())
}

fn check(input: CheckCommandInput<'_>) -> Result<()> {
    let CheckCommandInput {
        context,
        release_version,
        platform,
        arch,
        channel,
        current_patch_number,
        client_id,
        install_patch,
        cache_dir,
    } = input;
    let authed = authed_client(&context.server, context.token.as_deref())?;
    let app = resolve_app(&authed, context)?;
    let client = Client::new(&context.server);
    let response = client.check(&CheckRequest {
        org_id: app.org_id.as_deref(),
        app_id: &app.id,
        release_version,
        platform,
        arch,
        channel,
        current_patch_number,
        client_id,
    })?;
    println!("{}", serde_json::to_string_pretty(&response)?);
    if install_patch {
        download_and_install(DownloadInstallInput {
            context,
            client: &client,
            response: &response,
            app_id: &app.id,
            release_version,
            platform,
            arch,
            cache_dir,
        })?;
    }
    Ok(())
}

fn download_and_install(input: DownloadInstallInput<'_>) -> Result<()> {
    let DownloadInstallInput {
        context,
        client,
        response,
        app_id,
        release_version,
        platform,
        arch,
        cache_dir,
    } = input;
    let Some(patch) = &response.patch else {
        if response.patch_available {
            return Err(err(
                "server response marked patch_available but omitted patch",
            ));
        }
        return Ok(());
    };
    let (manifest_path, payload_path) =
        download_patch_files(client, patch, app_id, release_version, platform, arch)?;
    install(context, &manifest_path, &payload_path, cache_dir)
}

fn download_patch_files(
    client: &Client,
    patch: &PatchCheck,
    app_id: &str,
    release_version: &str,
    platform: &str,
    arch: &str,
) -> Result<(PathBuf, PathBuf)> {
    let out = fcb_dir()
        .join("apps")
        .join(app_id)
        .join("downloads")
        .join(release_version)
        .join(patch.patch_number.to_string())
        .join(platform)
        .join(arch);
    fs::create_dir_all(&out)?;

    let manifest_bytes = client.download_bytes(&patch.manifest_url)?;
    ensure_hash("manifest", &manifest_bytes, &patch.manifest_hash)?;
    let manifest_path = out.join("patch_manifest.json");
    fs::write(&manifest_path, manifest_bytes)?;

    let payload_bytes = client.download_bytes(&patch.payload_url)?;
    ensure_hash("payload", &payload_bytes, &patch.payload_hash)?;
    let payload_path = out.join("payload.bin");
    fs::write(&payload_path, payload_bytes)?;

    Ok((manifest_path, payload_path))
}

fn ensure_hash(label: &str, bytes: &[u8], expected: &str) -> Result<()> {
    let actual = crypto::sha256_hex(bytes);
    if actual != expected {
        return Err(err(format!(
            "{label} sha256 mismatch: expected {expected}, got {actual}"
        )));
    }
    Ok(())
}

fn install(
    context: &ResolvedContext,
    manifest_path: &Path,
    payload_path: &Path,
    cache_dir: &Path,
) -> Result<()> {
    let manifest: PatchManifest = manifest::read_json(manifest_path)?;
    enforce_secure_server(&context.server)?;
    let app =
        authed_client(&context.server, context.token.as_deref())?.get_app(&manifest.app_id)?;
    if app.public_key.trim().is_empty() {
        return Err(err(format!("app {} has no public_key", manifest.app_id)));
    }
    ensure_pinned_public_key(
        cache_dir,
        &context.server,
        &manifest.app_id,
        app.public_key.trim(),
    )?;
    let baseline_path = release_artifact_path(
        &manifest.app_id,
        &manifest.release_version,
        &manifest.platform,
        &manifest.arch,
    );
    // Pass the release artifact as fallback baseline when available.
    // The Updater will check installed patch artifacts first for chained diffs.
    let baseline = baseline_path.exists().then_some(baseline_path.as_path());
    Updater::new(cache_dir).install_payload_with_baseline(
        manifest_path,
        payload_path,
        app.public_key.trim(),
        baseline,
    )?;
    println!("installed patch into {}", cache_dir.display());
    Ok(())
}

fn release_artifact_path(
    app_id: &str,
    release_version: &str,
    platform: &str,
    arch: &str,
) -> PathBuf {
    let app_so = release_cache_dir(app_id, release_version, platform, arch).join("app.so");
    if app_so.exists() {
        return app_so;
    }
    release_cache_dir(app_id, release_version, platform, arch).join("artifact.bin")
}

fn release_cache_dir(app_id: &str, release_version: &str, platform: &str, arch: &str) -> PathBuf {
    fcb_dir()
        .join("apps")
        .join(app_id)
        .join("releases")
        .join(release_version)
        .join(platform)
        .join(arch)
}

fn patch_cache_dir(
    release_version: &str,
    patch_number: u32,
    platform: &str,
    arch: &str,
) -> PathBuf {
    fcb_dir()
        .join("patches")
        .join(release_version)
        .join(patch_number.to_string())
        .join(platform)
        .join(arch)
}

fn patch_artifact_path(
    release_version: &str,
    patch_number: u32,
    platform: &str,
    arch: &str,
) -> PathBuf {
    patch_cache_dir(release_version, patch_number, platform, arch).join("artifact.bin")
}

fn snapshot_replace_diff_base(
    app_id: &str,
    release_version: &str,
    platform: &str,
    arch: &str,
    patch_number: u32,
) -> Result<Vec<u8>> {
    if patch_number > 1 {
        let prev = patch_artifact_path(release_version, patch_number - 1, platform, arch);
        if prev.exists() {
            return Ok(fs::read(&prev)?);
        }
    }
    let release = release_artifact_path(app_id, release_version, platform, arch);
    if release.exists() {
        return Ok(fs::read(&release)?);
    }
    Err(err(format!(
        "missing base artifact for snapshot_replace patch {patch_number}: \
         expected {} or {}",
        patch_artifact_path(
            release_version,
            patch_number.saturating_sub(1),
            platform,
            arch
        )
        .display(),
        release.display(),
    )))
}

fn backend_for(config: &RemoteAppConfig, platform: &str) -> Result<String> {
    let entry = config.platform(platform).ok_or_else(|| {
        err(format!(
            "app {} does not define platform {platform}",
            config.id
        ))
    })?;
    if !entry.enabled {
        return Err(err(format!(
            "platform {platform} is disabled for app {}",
            config.id
        )));
    }
    Ok(entry.backend.clone())
}

fn load_private_key(path: &Path) -> Result<String> {
    crypto::private_key_seed_b64(&fs::read_to_string(path)?)
}

fn resolve_app(client: &Client, context: &ResolvedContext) -> Result<RemoteAppConfig> {
    if let Some(app_id) = context
        .app_id
        .as_deref()
        .map(|value| value.trim())
        .filter(|value| !value.is_empty())
    {
        return client.get_app(app_id);
    }
    let app = context
        .app
        .as_deref()
        .map(|value| value.trim())
        .filter(|value| !value.is_empty())
        .ok_or_else(|| err("app required; pass --app, set FCB_APP, or add app to fcb.yaml"))?;
    client.resolve_app(app)
}

fn ensure_pinned_public_key(
    cache_dir: &Path,
    server: &str,
    app_id: &str,
    public_key: &str,
) -> Result<()> {
    let pins_dir = cache_dir.join("trusted_keys");
    fs::create_dir_all(&pins_dir)?;
    let pin_scope = format!("{}__{}", safe_filename(server), safe_filename(app_id));
    let pin_path = pins_dir.join(format!("{pin_scope}.sha256"));
    let fingerprint = crypto::sha256_hex(public_key.as_bytes());
    if pin_path.exists() {
        let pinned = fs::read_to_string(&pin_path)?;
        if pinned.trim() != fingerprint {
            return Err(err(format!(
                "public key fingerprint mismatch for app {app_id}; refusing to install"
            )));
        }
        return Ok(());
    }
    fs::write(pin_path, format!("{fingerprint}\n"))?;
    Ok(())
}

fn enforce_secure_server(server: &str) -> Result<()> {
    if server.starts_with("https://") {
        return Ok(());
    }
    if let Some(rest) = server.strip_prefix("http://") {
        let host_port = rest.split('/').next().unwrap_or(rest);
        let host = host_port
            .strip_prefix('[')
            .and_then(|value| value.split(']').next())
            .unwrap_or_else(|| host_port.split(':').next().unwrap_or(host_port));
        if matches!(host, "localhost" | "127.0.0.1" | "::1") {
            return Ok(());
        }
    }
    Err(err(
        "HTTPS is required when fetching public keys from non-localhost servers",
    ))
}

fn safe_filename(value: &str) -> String {
    value
        .chars()
        .map(|ch| {
            if ch.is_ascii_alphanumeric() || matches!(ch, '-' | '_' | '.') {
                ch
            } else {
                '_'
            }
        })
        .collect()
}

fn load_local_context(path: &Path) -> Result<Option<LocalAppContext>> {
    match LocalAppContext::read_yaml(path) {
        Ok(context) => Ok(Some(context)),
        Err(fcb_core::Error::Io(err)) if err.kind() == std::io::ErrorKind::NotFound => Ok(None),
        Err(err) => Err(err),
    }
}

fn resolve_key_path(config_dir: &Path, path: &Path) -> PathBuf {
    resolve_path(config_dir, path)
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

fn path_for_context(config_path: &Path, path: &Path) -> String {
    let config_dir = config_path.parent().unwrap_or_else(|| Path::new("."));
    path.strip_prefix(config_dir)
        .unwrap_or(path)
        .to_string_lossy()
        .to_string()
}

fn default_platforms() -> Vec<RemotePlatformEntry> {
    vec![
        RemotePlatformEntry {
            platform: "android".to_string(),
            enabled: true,
            backend: "snapshot_replace".to_string(),
            abi: vec!["arm64-v8a".to_string(), "x86_64".to_string()],
        },
        RemotePlatformEntry {
            platform: "ios".to_string(),
            enabled: true,
            backend: "bytecode".to_string(),
            abi: Vec::new(),
        },
    ]
}

fn authed_client(server: &str, token: Option<&str>) -> Result<Client> {
    let token = token
        .map(str::to_string)
        .or_else(|| std::env::var("FCB_CLI_TOKEN").ok())
        .ok_or_else(|| err("CLI token required; pass --token or set FCB_CLI_TOKEN"))?;
    Ok(Client::new(server).with_token(token))
}

fn object_key(
    app_id: &str,
    release_version: &str,
    platform: &str,
    arch: &str,
    patch_number: u32,
    file_name: &str,
) -> String {
    format!("patches/{app_id}/{release_version}/{platform}/{arch}/{patch_number}/{file_name}")
}

#[cfg(test)]
mod patch_report_tests;

#[cfg(test)]
mod tests {
    use super::{
        bytecode_payload_from_inventories, interpret_sources, manual_patch_payload,
        validate_compiled_bytecode_payload,
    };
    use fcb_bytecode::format::{BytecodeFunction, BytecodeModule, Constant, OpCode, BINARY_MAGIC};
    use fcb_core::config::RemoteAppConfig;
    use fcb_core::linker::{
        FunctionDecision, FunctionInventoryEntry, KernelInventory, LinkerPlan,
        KERNEL_INVENTORY_SCHEMA_VERSION,
    };

    #[test]
    fn compiled_bytecode_payload_preserves_binary_module() {
        let module = BytecodeModule::new(vec![BytecodeFunction {
            name: "package:app/main.dart::mainValue".to_string(),
            return_convention: "tagged".to_string(),
            param_count: 0,
            local_count: 1,
            constants: vec![Constant::String(
                "package:app/main.dart::helper".to_string(),
            )],
            code: vec![OpCode::CallStatic as u8, 0, 0, 0, OpCode::Return as u8],
            source_map: Vec::new(),
        }]);
        let bytes = module.to_binary_vec().expect("binary module");

        let payload = validate_compiled_bytecode_payload(&bytes).expect("validated payload");

        assert!(payload.starts_with(BINARY_MAGIC));
        assert_eq!(payload, bytes);
    }

    #[test]
    fn interpret_sources_uses_only_linker_interpret_entries() {
        let inventory = KernelInventory {
            schema_version: KERNEL_INVENTORY_SCHEMA_VERSION,
            functions: vec![
                function(
                    "same",
                    Some(serde_json::json!({"name":"same","params":[],"body":{"int":1}})),
                ),
                function(
                    "changed",
                    Some(serde_json::json!({"name":"changed","params":[],"body":{"int":2}})),
                ),
            ],
            classes: Vec::new(),
            top_level_fields: Vec::new(),
        };
        let plan = LinkerPlan {
            unchanged: vec![FunctionDecision {
                function_id: "same".to_string(),
                source_location: None,
            }],
            interpret: vec![FunctionDecision {
                function_id: "changed".to_string(),
                source_location: None,
            }],
            reject: Vec::new(),
        };

        let sources = interpret_sources(&inventory, &plan).expect("sources");

        assert_eq!(sources.len(), 1);
        assert_eq!(sources[0]["name"], "changed");
    }

    #[test]
    fn automatic_bytecode_payload_returns_noop_when_all_functions_unchanged() {
        let inventory = KernelInventory {
            schema_version: KERNEL_INVENTORY_SCHEMA_VERSION,
            functions: vec![function("same", None)],
            classes: Vec::new(),
            top_level_fields: Vec::new(),
        };
        let mut report = super::PatchReport::new("bytecode", "ios", "arm64", "1.0.0+1", 1);

        let result = bytecode_payload_from_inventories(&inventory, &inventory, &mut report)
            .expect("bytecode");

        assert!(result.is_none());
        assert!(report.linker_plan.expect("plan").interpret.is_empty());
    }

    #[test]
    fn automatic_bytecode_test_helper_requires_dart_compiler_for_changed_functions() {
        let release = KernelInventory {
            schema_version: KERNEL_INVENTORY_SCHEMA_VERSION,
            functions: vec![FunctionInventoryEntry {
                body_hash: "old".to_string(),
                ..function("changed", None)
            }],
            classes: Vec::new(),
            top_level_fields: Vec::new(),
        };
        let patch = KernelInventory {
            schema_version: KERNEL_INVENTORY_SCHEMA_VERSION,
            functions: vec![FunctionInventoryEntry {
                body_hash: "new".to_string(),
                bytecode_source: Some(serde_json::json!({
                    "name": "package:app/main.dart::changed",
                    "params": ["x"],
                    "body": {
                        "op": "+",
                        "left": {"arg": "x"},
                        "right": {"int": 1}
                    }
                })),
                ..function("changed", None)
            }],
            classes: Vec::new(),
            top_level_fields: Vec::new(),
        };
        let mut report = super::PatchReport::new("bytecode", "ios", "arm64", "1.0.0+1", 1);

        let err = bytecode_payload_from_inventories(&release, &patch, &mut report)
            .expect_err("test helper should not compile source JSON");

        assert!(err.to_string().contains("Dart compile-from-plan"));
        assert!(report.linker_plan.expect("plan").reject.is_empty());
    }

    #[test]
    fn manual_bytecode_payload_bypasses_automatic_flow() {
        let dir = std::env::temp_dir().join(format!("fcb-cli-test-payload-{}", std::process::id()));
        let _ = std::fs::remove_dir_all(&dir);
        std::fs::create_dir_all(&dir).expect("dir");
        let payload_path = dir.join("payload.json");
        let module = BytecodeModule::new(vec![BytecodeFunction {
            name: "manual".to_string(),
            return_convention: "tagged".to_string(),
            param_count: 0,
            local_count: 0,
            constants: vec![Constant::Int(7)],
            code: vec![OpCode::LoadConst as u8, 0, 0, OpCode::Return as u8],
            source_map: Vec::new(),
        }]);
        std::fs::write(&payload_path, module.to_vec().expect("module json")).expect("payload");
        let app = RemoteAppConfig {
            id: "app".to_string(),
            org_id: None,
            name: "App".to_string(),
            channel: "stable".to_string(),
            public_key: "key".to_string(),
            platforms: Vec::new(),
        };

        let result = manual_patch_payload(
            &app,
            "bytecode",
            "1.0.0+1",
            1,
            "ios",
            "arm64",
            &payload_path,
        )
        .expect("manual")
        .expect("payload result");

        assert_eq!(result.1, "bytecode_module");
        assert!(result.3.is_none());
        let _ = std::fs::remove_dir_all(dir);
    }

    fn function(id: &str, bytecode_source: Option<serde_json::Value>) -> FunctionInventoryEntry {
        FunctionInventoryEntry {
            function_id: id.to_string(),
            library_uri: "package:app/main.dart".to_string(),
            enclosing: String::new(),
            member_name: id.to_string(),
            signature_hash: "sig".to_string(),
            body_hash: "same-body".to_string(),
            source_location: None,
            bytecode_source,
            unsupported_reasons: Vec::new(),
        }
    }
}
