use clap::{Parser, Subcommand};
use fcb_core::config::FcbConfig;
use fcb_core::crypto;
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
            release_version,
            arch,
        } => release(
            &args.server,
            &platform,
            example.as_deref(),
            &release_version,
            &arch,
        ),
        Command::Patch {
            platform,
            release_version,
            patch_number,
            arch,
            payload,
        } => patch(
            &args.server,
            &platform,
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
    release_version: &str,
    arch: &str,
) -> Result<()> {
    let config = FcbConfig::read_yaml(Path::new("fcb.yaml"))?;
    let artifact = release_artifact_bytes(example)?;
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
    payload: Option<&Path>,
) -> Result<()> {
    let config = FcbConfig::read_yaml(Path::new("fcb.yaml"))?;
    let payload_bytes = if let Some(path) = payload {
        fs::read(path)?
    } else {
        format!("fcb patch {patch_number} for {release_version}\n").into_bytes()
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
        backend: backend_for(&config, platform),
        platform: platform.to_string(),
        arch: arch.to_string(),
        payload: PayloadManifest {
            kind: "opaque_payload".to_string(),
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
    Updater::new(cache_dir).install_payload(manifest_path, payload_path, public_key.trim())?;
    println!("installed patch into {}", cache_dir.display());
    Ok(())
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

fn release_artifact_bytes(example: Option<&Path>) -> Result<Vec<u8>> {
    if let Some(example) = example {
        let main = example.join("lib/main.dart");
        if main.exists() {
            return Ok(fs::read(main)?);
        }
    }
    Ok(b"fcb baseline artifact\n".to_vec())
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
