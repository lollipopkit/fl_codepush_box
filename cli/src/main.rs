use clap::{Parser, Subcommand};
use fcb_core::config::FcbConfig;
use fcb_core::crypto;
use fcb_core::diff::{self, BSDIFF_ZSTD_ALGORITHM};
use fcb_core::manifest::{
    self, PatchManifest, PatchPolicy, PatchSignature, PayloadManifest, ReleaseManifest,
};
use fcb_core::server_api::{
    CheckResponse, Client, CreateAppRequest, PatchCheck, PromotePatchRequest,
};
use fcb_core::state::Updater;
use fcb_core::{err, fcb_dir, Result};
use std::fs;
use std::path::{Path, PathBuf};
use uuid::Uuid;

#[cfg(unix)]
use std::os::unix::fs::PermissionsExt;

#[derive(Parser)]
#[command(name = "fcb")]
#[command(about = "Flutter CodePush Box CLI")]
struct Args {
    #[arg(long, default_value = "http://127.0.0.1:8080")]
    server: String,
    #[command(subcommand)]
    command: Command,
}

#[derive(Subcommand)]
enum Command {
    Init,
    Doctor,
    Release {
        platform: String,
        #[arg(long)]
        example: Option<PathBuf>,
        #[arg(long)]
        artifact: Option<PathBuf>,
        #[arg(long, default_value = "1.0.0+1")]
        release_version: String,
        #[arg(long, default_value = "arm64-v8a")]
        arch: String,
    },
    Patch {
        platform: String,
        #[arg(long)]
        release_version: String,
        #[arg(long, default_value_t = 1)]
        patch_number: u32,
        #[arg(long, default_value = "arm64-v8a")]
        arch: String,
        #[arg(long)]
        example: Option<PathBuf>,
        #[arg(long)]
        artifact: Option<PathBuf>,
        #[arg(long)]
        payload: Option<PathBuf>,
    },
    PatchBytecode {
        platform: String,
        #[arg(long)]
        release_version: String,
        #[arg(long, default_value_t = 1)]
        patch_number: u32,
        #[arg(long, default_value = "arm64-v8a")]
        arch: String,
        #[arg(long)]
        bytecode: PathBuf,
    },
    LinkBytecode {
        #[arg(long)]
        base: PathBuf,
        #[arg(long)]
        patch: PathBuf,
        #[arg(long)]
        patch_number: u32,
        #[arg(long)]
        out: PathBuf,
        #[arg(long)]
        report: PathBuf,
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
    LaunchPatch {
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

fn main() {
    if let Err(e) = run() {
        eprintln!("error: {e}");
        std::process::exit(1);
    }
}

fn run() -> Result<()> {
    let args = Args::parse();
    match args.command {
        Command::Init => init(),
        Command::Doctor => {
            println!("fcb doctor: ok");
            Ok(())
        }
        Command::Release {
            platform,
            example,
            artifact,
            release_version,
            arch,
        } => release(
            &args.server,
            &platform,
            example.as_deref(),
            artifact.as_deref(),
            &release_version,
            &arch,
        ),
        Command::Patch {
            platform,
            release_version,
            patch_number,
            arch,
            example,
            artifact,
            payload,
        } => patch(
            &args.server,
            &platform,
            &release_version,
            patch_number,
            &arch,
            example.as_deref(),
            artifact.as_deref(),
            payload.as_deref(),
        ),
        Command::PatchBytecode {
            platform,
            release_version,
            patch_number,
            arch,
            bytecode,
        } => patch_bytecode(
            &args.server,
            &platform,
            &release_version,
            patch_number,
            &arch,
            &bytecode,
        ),
        Command::LinkBytecode {
            base,
            patch,
            patch_number,
            out,
            report,
        } => link_bytecode(&base, &patch, patch_number, &out, &report),
        Command::Promote {
            release_version,
            patch_number,
            platform,
            arch,
            channel,
            rollout_percentage,
        } => promote(
            &args.server,
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
        } => check(
            &args.server,
            &release_version,
            &platform,
            &arch,
            &channel,
            current_patch_number,
            &client_id,
            install,
            &cache_dir,
        ),
        Command::Install {
            manifest,
            payload,
            cache_dir,
        } => install(&manifest, &payload, &cache_dir),
        Command::LaunchPatch { cache_dir } => launch_patch(&cache_dir),
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
        } => rollback(
            &args.server,
            &release_version,
            patch_number,
            &platform,
            &arch,
        ),
        Command::Inspect { kind, path } => inspect(&kind, &path),
    }
}

fn init() -> Result<()> {
    if Path::new("fcb.yaml").exists() {
        return Err(err("fcb.yaml already exists"));
    }
    fs::create_dir_all(fcb_dir().join("keys"))?;
    let app_id = Uuid::new_v4().to_string();
    FcbConfig::new(app_id.clone()).write_yaml(Path::new("fcb.yaml"))?;
    let (private_key, public_key) = crypto::generate_keypair_b64();
    let private_key_path = fcb_dir().join("keys/dev-ed25519.private");
    fs::write(&private_key_path, private_key)?;
    #[cfg(unix)]
    fs::set_permissions(&private_key_path, fs::Permissions::from_mode(0o600))?;
    fs::write(fcb_dir().join("keys/dev-ed25519.public"), public_key)?;
    println!("created fcb.yaml for app_id {app_id}");
    Ok(())
}

fn release(
    server: &str,
    platform: &str,
    example: Option<&Path>,
    artifact_path: Option<&Path>,
    release_version: &str,
    arch: &str,
) -> Result<()> {
    let config = FcbConfig::read_yaml(Path::new("fcb.yaml"))?;
    let artifact = release_artifact_bytes(example, artifact_path, platform, arch)?;
    let manifest = ReleaseManifest {
        schema_version: 1,
        app_id: config.app_id.clone(),
        release_version: release_version.to_string(),
        channel: config.channel.clone(),
        platform: platform.to_string(),
        arch: arch.to_string(),
        backend: backend_for(&config, platform),
        artifact_hash: crypto::sha256_hex(&artifact),
        artifact_size: artifact.len() as u64,
    };
    let out = fcb_dir()
        .join("releases")
        .join(release_version)
        .join(platform)
        .join(arch);
    fs::create_dir_all(&out)?;
    fs::write(out.join("artifact.bin"), artifact)?;
    manifest::write_json(&out.join("release_manifest.json"), &manifest)?;
    let client = Client::new(server);
    client.create_app(&CreateAppRequest {
        id: config.app_id,
        name: "FCB App".to_string(),
    })?;
    client.create_release(&manifest)?;
    println!("{}", out.join("release_manifest.json").display());
    Ok(())
}

fn patch(
    server: &str,
    platform: &str,
    release_version: &str,
    patch_number: u32,
    arch: &str,
    example: Option<&Path>,
    artifact_path: Option<&Path>,
    payload: Option<&Path>,
) -> Result<()> {
    let config = FcbConfig::read_yaml(Path::new("fcb.yaml"))?;
    let target_artifact = patch_artifact_bytes(
        example,
        artifact_path,
        payload,
        platform,
        arch,
        release_version,
        patch_number,
    )?;
    let backend = backend_for(&config, platform);
    let baseline_path = release_artifact_path(release_version, platform, arch);
    let baseline = if backend == "snapshot_replace" && baseline_path.exists() {
        Some(fs::read(&baseline_path)?)
    } else {
        None
    };
    let (payload_bytes, payload_kind, diff_algorithm, base_hash, output_hash) =
        if backend == "snapshot_replace" {
            let Some(base) = baseline.as_deref() else {
                return Err(err(format!(
                    "missing baseline artifact for snapshot_replace: {}",
                    baseline_path.display()
                )));
            };
            (
                diff::create_bsdiff_zstd_diff(base, &target_artifact)?,
                "binary_diff",
                Some(BSDIFF_ZSTD_ALGORITHM.to_string()),
                Some(crypto::sha256_hex(base)),
                Some(crypto::sha256_hex(&target_artifact)),
            )
        } else {
            (target_artifact, "opaque_payload", None, None, None)
        };
    let out = fcb_dir()
        .join("patches")
        .join(release_version)
        .join(patch_number.to_string())
        .join(platform)
        .join(arch);
    fs::create_dir_all(&out)?;
    fs::write(out.join("payload.bin"), &payload_bytes)?;
    let payload_hash = crypto::sha256_hex(&payload_bytes);
    let public_key_id = config.security.public_key_id.clone();
    let private_key = fs::read_to_string(
        fcb_dir()
            .join("keys")
            .join(format!("{public_key_id}.private")),
    )?;
    let mut manifest = PatchManifest {
        schema_version: 1,
        app_id: config.app_id.clone(),
        release_version: release_version.to_string(),
        patch_number,
        channel: config.channel.clone(),
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
                &config.app_id,
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
            key_id: public_key_id,
            value: String::new(),
        },
    };
    manifest::sign_patch_manifest(&mut manifest, private_key.trim())?;
    manifest::write_json(&out.join("patch_manifest.json"), &manifest)?;
    Client::new(server).create_patch(&manifest, &payload_bytes)?;
    println!("{}", out.join("patch_manifest.json").display());
    println!("payload_sha256={payload_hash}");
    Ok(())
}

fn patch_artifact_bytes(
    example: Option<&Path>,
    artifact_path: Option<&Path>,
    payload: Option<&Path>,
    platform: &str,
    arch: &str,
    release_version: &str,
    patch_number: u32,
) -> Result<Vec<u8>> {
    if artifact_path.is_some() || example.is_some() {
        return release_artifact_bytes(example, artifact_path, platform, arch);
    }
    if let Some(path) = payload {
        if !path.exists() {
            return Err(err(format!("payload not found: {}", path.display())));
        }
        return Ok(fs::read(path)?);
    }
    Ok(format!("fcb patch {patch_number} for {release_version}\n").into_bytes())
}

fn promote(
    server: &str,
    release_version: &str,
    patch_number: u32,
    platform: &str,
    arch: &str,
    channel: &str,
    rollout_percentage: u8,
) -> Result<()> {
    let config = FcbConfig::read_yaml(Path::new("fcb.yaml"))?;
    Client::new(server).promote_patch(&PromotePatchRequest {
        app_id: config.app_id,
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
    server: &str,
    release_version: &str,
    patch_number: u32,
    platform: &str,
    arch: &str,
) -> Result<()> {
    let config = FcbConfig::read_yaml(Path::new("fcb.yaml"))?;
    Client::new(server).rollback_patch(&PromotePatchRequest {
        app_id: config.app_id,
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

fn check(
    server: &str,
    release_version: &str,
    platform: &str,
    arch: &str,
    channel: &str,
    current_patch_number: u32,
    client_id: &str,
    install_patch: bool,
    cache_dir: &Path,
) -> Result<()> {
    let config = FcbConfig::read_yaml(Path::new("fcb.yaml"))?;
    let client = Client::new(server);
    let response = client.check(
        &config.app_id,
        release_version,
        platform,
        arch,
        channel,
        current_patch_number,
        client_id,
    )?;
    println!("{}", serde_json::to_string_pretty(&response)?);
    if install_patch {
        download_and_install(
            &client,
            &response,
            release_version,
            platform,
            arch,
            cache_dir,
        )?;
    }
    Ok(())
}

fn download_and_install(
    client: &Client,
    response: &CheckResponse,
    release_version: &str,
    platform: &str,
    arch: &str,
    cache_dir: &Path,
) -> Result<()> {
    let Some(patch) = &response.patch else {
        if response.patch_available {
            return Err(err(
                "server response marked patch_available but omitted patch",
            ));
        }
        return Ok(());
    };
    let (manifest_path, payload_path) =
        download_patch_files(client, patch, release_version, platform, arch)?;
    install(&manifest_path, &payload_path, cache_dir)
}

fn download_patch_files(
    client: &Client,
    patch: &PatchCheck,
    release_version: &str,
    platform: &str,
    arch: &str,
) -> Result<(PathBuf, PathBuf)> {
    let out = fcb_dir()
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

fn install(manifest_path: &Path, payload_path: &Path, cache_dir: &Path) -> Result<()> {
    let config = FcbConfig::read_yaml(Path::new("fcb.yaml"))?;
    let public_key = fs::read_to_string(
        fcb_dir()
            .join("keys")
            .join(format!("{}.public", config.security.public_key_id)),
    )?;
    let manifest: PatchManifest = manifest::read_json(manifest_path)?;
    let baseline_path = release_artifact_path(
        &manifest.release_version,
        &manifest.platform,
        &manifest.arch,
    );
    let baseline = if manifest.payload.kind == "binary_diff" {
        if !baseline_path.exists() {
            return Err(err(format!(
                "missing baseline artifact for binary diff: {}",
                baseline_path.display()
            )));
        }
        Some(baseline_path.as_path())
    } else {
        None
    };
    Updater::new(cache_dir).install_payload_with_baseline(
        manifest_path,
        payload_path,
        public_key.trim(),
        baseline,
    )?;
    println!("installed patch into {}", cache_dir.display());
    Ok(())
}

fn launch_patch(cache_dir: &Path) -> Result<()> {
    let patch = Updater::new(cache_dir).launch_patch()?;
    println!("{}", serde_json::to_string_pretty(&patch)?);
    Ok(())
}

fn release_artifact_path(release_version: &str, platform: &str, arch: &str) -> PathBuf {
    fcb_dir()
        .join("releases")
        .join(release_version)
        .join(platform)
        .join(arch)
        .join("artifact.bin")
}

fn inspect(kind: &str, path: &Path) -> Result<()> {
    let bytes = fs::read(path)?;
    match kind {
        "patch" => {
            let manifest: PatchManifest = serde_json::from_slice(&bytes)?;
            println!("{}", serde_json::to_string_pretty(&manifest)?);
        }
        "release" => {
            let manifest: ReleaseManifest = serde_json::from_slice(&bytes)?;
            println!("{}", serde_json::to_string_pretty(&manifest)?);
        }
        _ => return Err(err("inspect kind must be patch or release")),
    }
    Ok(())
}

fn release_artifact_bytes(
    example: Option<&Path>,
    artifact_path: Option<&Path>,
    platform: &str,
    arch: &str,
) -> Result<Vec<u8>> {
    // Explicit artifact path takes highest priority.
    if let Some(path) = artifact_path {
        if !path.exists() {
            return Err(err(format!("artifact not found: {}", path.display())));
        }
        return Ok(fs::read(path)?);
    }
    // For Android snapshot_replace, look for libapp.so in the Flutter build output.
    if platform == "android" {
        if let Some(example) = example {
            // Also check the per-ABI path in the stripped APK output.
            let abi_libapp = example
                .join("build")
                .join("app")
                .join("intermediates")
                .join("stripped_native_libs")
                .join("release")
                .join("out")
                .join("lib")
                .join(arch)
                .join("libapp.so");
            if abi_libapp.exists() {
                return Ok(fs::read(&abi_libapp)?);
            }
            let libapp = example
                .join("build")
                .join("app")
                .join("outputs")
                .join("flutter-apk")
                .join("libapp.so");
            if libapp.exists() {
                return Ok(fs::read(&libapp)?);
            }
            return Err(err(format!(
                "android snapshot_replace artifact not found for ABI {arch}; pass --artifact or build the example first so libapp.so exists under {}",
                example.display()
            )));
        }
        return Err(err(
            "android snapshot_replace requires --artifact or --example with a built libapp.so",
        ));
    }
    if let Some(example) = example {
        let main = example.join("lib/main.dart");
        if main.exists() {
            return Ok(fs::read(main)?);
        }
    }
    Ok(b"fcb baseline artifact\n".to_vec())
}

fn patch_bytecode(
    server: &str,
    platform: &str,
    release_version: &str,
    patch_number: u32,
    arch: &str,
    bytecode_path: &Path,
) -> Result<()> {
    let config = FcbConfig::read_yaml(Path::new("fcb.yaml"))?;
    let bytecode_bytes = fs::read(bytecode_path)?;
    // Validate that the bytecode module can be deserialized.
    let module: fcb_bytecode::format::BytecodeModule = serde_json::from_slice(&bytecode_bytes)
        .map_err(|e| err(format!("invalid bytecode module: {e}")))?;
    if module.version != fcb_bytecode::format::BytecodeModule::FORMAT_VERSION {
        return Err(err(format!(
            "unsupported bytecode version: {} (expected {})",
            module.version,
            fcb_bytecode::format::BytecodeModule::FORMAT_VERSION
        )));
    }
    println!(
        "bytecode module: {} functions, app_id={}",
        module.functions.len(),
        module.app_id
    );
    for func in &module.functions {
        println!(
            "  {} ({} params, {} locals, {} bytes)",
            func.name,
            func.param_count,
            func.local_count,
            func.code.len()
        );
    }
    // For bytecode backend, the payload IS the bytecode module (not a binary diff).
    // The payload kind is "bytecode_module" and the backend is "bytecode".
    let payload_hash = crypto::sha256_hex(&bytecode_bytes);
    let public_key_id = config.security.public_key_id.clone();
    let private_key = fs::read_to_string(
        fcb_dir()
            .join("keys")
            .join(format!("{public_key_id}.private")),
    )?;
    let mut patch = PatchManifest {
        schema_version: 1,
        app_id: config.app_id.clone(),
        release_version: release_version.to_string(),
        patch_number,
        channel: config.channel.clone(),
        created_at: "1970-01-01T00:00:00Z".to_string(),
        backend: "bytecode".to_string(),
        platform: platform.to_string(),
        arch: arch.to_string(),
        payload: PayloadManifest {
            kind: "bytecode_module".to_string(),
            compression: "none".to_string(),
            hash: payload_hash.clone(),
            size: bytecode_bytes.len() as u64,
            download_url: object_key(
                &config.app_id,
                release_version,
                platform,
                arch,
                patch_number,
                "payload.bin",
            ),
            diff_algorithm: None,
            base_hash: None,
            output_hash: None,
        },
        policy: PatchPolicy {
            rollout_percentage: 0,
            allow_downgrade: false,
        },
        signature: PatchSignature {
            algorithm: "ed25519".to_string(),
            key_id: public_key_id,
            value: String::new(),
        },
    };
    manifest::sign_patch_manifest(&mut patch, private_key.trim())?;
    let out = fcb_dir()
        .join("patches")
        .join(release_version)
        .join(patch_number.to_string())
        .join(platform)
        .join(arch);
    fs::create_dir_all(&out)?;
    manifest::write_json(&out.join("patch_manifest.json"), &patch)?;
    fs::write(out.join("payload.bin"), &bytecode_bytes)?;
    let client = Client::new(server);
    client.create_app(&CreateAppRequest {
        id: config.app_id.clone(),
        name: "FCB App".to_string(),
    })?;
    client.create_patch(&patch, &bytecode_bytes)?;
    println!("{}", out.join("patch_manifest.json").display());
    Ok(())
}

fn link_bytecode(
    base_path: &Path,
    patch_path: &Path,
    patch_number: u32,
    out_path: &Path,
    report_path: &Path,
) -> Result<()> {
    let base_bytes = fs::read(base_path)?;
    let patch_bytes = fs::read(patch_path)?;
    let base: fcb_bytecode::ProgramSpec = serde_json::from_slice(&base_bytes)
        .map_err(|e| err(format!("invalid base program spec: {e}")))?;
    let patch: fcb_bytecode::ProgramSpec = serde_json::from_slice(&patch_bytes)
        .map_err(|e| err(format!("invalid patch program spec: {e}")))?;
    let output = fcb_bytecode::link_programs(&base, &patch, patch_number)?;
    if let Some(parent) = out_path.parent() {
        fs::create_dir_all(parent)?;
    }
    if let Some(parent) = report_path.parent() {
        fs::create_dir_all(parent)?;
    }
    fs::write(out_path, serde_json::to_vec_pretty(&output.module)?)?;
    fs::write(report_path, serde_json::to_vec_pretty(&output.report)?)?;
    println!(
        "linked {} interpreted functions into {}",
        output.module.functions.len(),
        out_path.display()
    );
    println!("{}", report_path.display());
    Ok(())
}

fn backend_for(config: &FcbConfig, platform: &str) -> String {
    match platform {
        "ios" => config.platforms.ios.backend.clone(),
        _ => config.platforms.android.backend.clone(),
    }
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
mod tests {
    use super::*;
    use fcb_bytecode::linker::{FunctionSpec, UnsupportedChange, Visibility};
    use fcb_bytecode::{OpCode, ProgramSpec};

    fn temp_path(name: &str) -> PathBuf {
        let unique = format!(
            "fcb_cli_test_{}_{}_{}",
            name,
            std::process::id(),
            std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH)
                .expect("time")
                .as_nanos()
        );
        std::env::temp_dir().join(unique)
    }

    fn program(body_hash: &str, bytecode: Vec<u8>) -> ProgramSpec {
        ProgramSpec {
            app_id: "app".to_string(),
            release_version: "1.0.0+1".to_string(),
            constants_added: 0,
            functions: vec![FunctionSpec {
                canonical_library_uri: "package:app/pricing.dart".to_string(),
                class_qualified_name: String::new(),
                member_name: "price".to_string(),
                normalized_type_signature: "(int)->int".to_string(),
                type_parameter_shape: String::new(),
                body_hash: body_hash.to_string(),
                class_shape_hash: "shape".to_string(),
                visibility: Visibility::Public,
                param_count: 1,
                bytecode,
                unsupported_changes: Vec::new(),
            }],
        }
    }

    #[test]
    fn android_artifact_extraction_prefers_per_abi_libapp_so() {
        let dir = temp_path("android_artifact");
        let flat_dir = dir.join("build/app/outputs/flutter-apk");
        fs::create_dir_all(&flat_dir).expect("mkdir flat");
        fs::write(flat_dir.join("libapp.so"), b"flat libapp").expect("write flat libapp");
        let abi_dir =
            dir.join("build/app/intermediates/stripped_native_libs/release/out/lib/arm64-v8a");
        fs::create_dir_all(&abi_dir).expect("mkdir");
        fs::write(abi_dir.join("libapp.so"), b"arm64 libapp").expect("write libapp");

        let bytes =
            release_artifact_bytes(Some(&dir), None, "android", "arm64-v8a").expect("extract");

        assert_eq!(bytes, b"arm64 libapp");
        fs::remove_dir_all(dir).ok();
    }

    #[test]
    fn android_artifact_extraction_selects_requested_abi() {
        let dir = temp_path("android_artifact_multi_abi");
        let arm64_dir =
            dir.join("build/app/intermediates/stripped_native_libs/release/out/lib/arm64-v8a");
        let x64_dir =
            dir.join("build/app/intermediates/stripped_native_libs/release/out/lib/x86_64");
        fs::create_dir_all(&arm64_dir).expect("mkdir arm64");
        fs::create_dir_all(&x64_dir).expect("mkdir x64");
        fs::write(arm64_dir.join("libapp.so"), b"arm64 libapp").expect("write arm64");
        fs::write(x64_dir.join("libapp.so"), b"x86_64 libapp").expect("write x64");

        let bytes = release_artifact_bytes(Some(&dir), None, "android", "x86_64").expect("extract");

        assert_eq!(bytes, b"x86_64 libapp");
        fs::remove_dir_all(dir).ok();
    }

    #[test]
    fn android_artifact_extraction_rejects_missing_libapp_so() {
        let dir = temp_path("android_missing_artifact");
        fs::create_dir_all(dir.join("lib")).expect("mkdir");
        fs::write(dir.join("lib/main.dart"), b"void main() {}").expect("write dart");

        let err = release_artifact_bytes(Some(&dir), None, "android", "arm64-v8a")
            .expect_err("android release must not fall back to Dart source");

        assert!(
            err.to_string()
                .contains("android snapshot_replace artifact not found"),
            "{err}"
        );
        fs::remove_dir_all(dir).ok();
    }

    #[test]
    fn android_artifact_extraction_requires_artifact_or_example() {
        let err = release_artifact_bytes(None, None, "android", "arm64-v8a")
            .expect_err("android release must require a real libapp.so");

        assert!(
            err.to_string()
                .contains("android snapshot_replace requires --artifact"),
            "{err}"
        );
    }

    #[test]
    fn patch_artifact_extraction_accepts_explicit_artifact() {
        let dir = temp_path("patch_artifact");
        fs::create_dir_all(&dir).expect("mkdir");
        let artifact = dir.join("patched-libapp.so");
        fs::write(&artifact, b"patched libapp").expect("write artifact");

        let bytes = patch_artifact_bytes(
            None,
            Some(&artifact),
            None,
            "android",
            "arm64-v8a",
            "1.0.0+1",
            2,
        )
        .expect("extract");

        assert_eq!(bytes, b"patched libapp");
        fs::remove_dir_all(dir).ok();
    }

    #[test]
    fn link_bytecode_writes_module_and_report() {
        let dir = temp_path("link_ok");
        fs::create_dir_all(&dir).expect("mkdir");
        let base_path = dir.join("base.json");
        let patch_path = dir.join("patch.json");
        let out_path = dir.join("module.hbc.json");
        let report_path = dir.join("report.json");
        let base = program("base", vec![]);
        let patch = program(
            "patch",
            vec![OpCode::LoadLocal.byte(), 0, OpCode::Return.byte()],
        );
        fs::write(&base_path, serde_json::to_vec(&base).expect("json")).expect("write base");
        fs::write(&patch_path, serde_json::to_vec(&patch).expect("json")).expect("write patch");

        link_bytecode(&base_path, &patch_path, 7, &out_path, &report_path).expect("link");

        let module: fcb_bytecode::BytecodeModule =
            serde_json::from_slice(&fs::read(out_path).expect("read module")).expect("module");
        assert_eq!(module.patch_number, 7);
        assert_eq!(module.functions.len(), 1);
        let report = fs::read_to_string(report_path).expect("read report");
        assert!(report.contains("\"interpret\""));
        fs::remove_dir_all(dir).ok();
    }

    #[test]
    fn link_bytecode_rejects_unsupported_change() {
        let dir = temp_path("link_reject");
        fs::create_dir_all(&dir).expect("mkdir");
        let base_path = dir.join("base.json");
        let patch_path = dir.join("patch.json");
        let out_path = dir.join("module.hbc.json");
        let report_path = dir.join("report.json");
        let base = program("base", vec![]);
        let mut patch = program("patch", vec![OpCode::Return.byte()]);
        patch.functions[0]
            .unsupported_changes
            .push(UnsupportedChange::MethodChannelNativeContractChanged);
        fs::write(&base_path, serde_json::to_vec(&base).expect("json")).expect("write base");
        fs::write(&patch_path, serde_json::to_vec(&patch).expect("json")).expect("write patch");

        let err = link_bytecode(&base_path, &patch_path, 7, &out_path, &report_path)
            .expect_err("unsupported change should fail");
        assert!(err
            .to_string()
            .contains("method_channel_native_contract_changed"));
        fs::remove_dir_all(dir).ok();
    }
}
