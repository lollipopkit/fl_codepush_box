use crate::{err, Result};
use serde::{Deserialize, Serialize};
use std::{fs, path::Path};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FcbConfig {
    pub app_id: String,
    pub channel: String,
    pub update: UpdateConfig,
    pub security: SecurityConfig,
    pub platforms: PlatformConfig,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct UpdateConfig {
    pub check_on_startup: bool,
    pub activation: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SecurityConfig {
    pub public_key_id: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PlatformConfig {
    pub android: PlatformEntry,
    pub ios: PlatformEntry,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PlatformEntry {
    pub enabled: bool,
    pub backend: String,
    pub abi: Vec<String>,
}

impl FcbConfig {
    pub fn new(app_id: String) -> Self {
        Self {
            app_id,
            channel: "stable".to_string(),
            update: UpdateConfig {
                check_on_startup: true,
                activation: "next_restart".to_string(),
            },
            security: SecurityConfig {
                public_key_id: "dev-ed25519".to_string(),
            },
            platforms: PlatformConfig {
                android: PlatformEntry {
                    enabled: true,
                    backend: "snapshot_replace".to_string(),
                    abi: vec!["arm64-v8a".to_string(), "x86_64".to_string()],
                },
                ios: PlatformEntry {
                    enabled: true,
                    backend: "bytecode".to_string(),
                    abi: Vec::new(),
                },
            },
        }
    }

    pub fn to_yaml(&self) -> String {
        let android_abi = self
            .platforms
            .android
            .abi
            .iter()
            .map(|abi| format!("      - {abi}\n"))
            .collect::<String>();
        let ios_abi = self
            .platforms
            .ios
            .abi
            .iter()
            .map(|abi| format!("      - {abi}\n"))
            .collect::<String>();
        format!(
            "app_id: \"{}\"\nchannel: \"{}\"\nupdate:\n  check_on_startup: {}\n  activation: \"{}\"\nsecurity:\n  public_key_id: \"{}\"\nplatforms:\n  android:\n    enabled: {}\n    backend: \"{}\"\n    abi:\n{}  ios:\n    enabled: {}\n    backend: \"{}\"\n    abi:\n{}",
            self.app_id,
            self.channel,
            self.update.check_on_startup,
            self.update.activation,
            self.security.public_key_id,
            self.platforms.android.enabled,
            self.platforms.android.backend,
            android_abi,
            self.platforms.ios.enabled,
            self.platforms.ios.backend,
            ios_abi,
        )
    }

    pub fn write_yaml(&self, path: &Path) -> Result<()> {
        fs::write(path, self.to_yaml())?;
        Ok(())
    }

    pub fn read_yaml(path: &Path) -> Result<Self> {
        let source = fs::read_to_string(path)?;
        parse_yaml_subset(&source)
    }
}

fn parse_yaml_subset(source: &str) -> Result<FcbConfig> {
    let mut app_id = None;
    let mut channel = Some("stable".to_string());
    let mut check_on_startup = Some(true);
    let mut activation = Some("next_restart".to_string());
    let mut public_key_id = Some("dev-ed25519".to_string());
    let mut android_enabled = Some(true);
    let mut android_backend = Some("snapshot_replace".to_string());
    let mut android_abi = Vec::new();
    let mut ios_enabled = Some(true);
    let mut ios_backend = Some("bytecode".to_string());
    let mut ios_abi = Vec::new();
    let mut section = "";
    let mut platform = "";

    for raw in source.lines() {
        let line = raw.trim_end();
        let trimmed = line.trim();
        if trimmed.is_empty() || trimmed.starts_with('#') {
            continue;
        }
        if !raw.starts_with(' ') && trimmed.ends_with(':') {
            section = trimmed.trim_end_matches(':');
            platform = "";
            continue;
        }
        if section == "platforms"
            && raw.starts_with("  ")
            && !raw.starts_with("    ")
            && trimmed.ends_with(':')
        {
            platform = trimmed.trim_end_matches(':');
            continue;
        }
        if trimmed.starts_with("- ") {
            let abi = unquote(trimmed.trim_start_matches("- ").trim());
            match platform {
                "android" => android_abi.push(abi),
                "ios" => ios_abi.push(abi),
                _ => {}
            }
            continue;
        }
        let Some((key, value)) = trimmed.split_once(':') else {
            continue;
        };
        let value = value.trim();
        match (section, platform, key.trim()) {
            ("", "", "app_id") => app_id = Some(unquote(value)),
            ("", "", "channel") => channel = Some(unquote(value)),
            ("update", "", "check_on_startup") => check_on_startup = Some(parse_bool(value)?),
            ("update", "", "activation") => activation = Some(unquote(value)),
            ("security", "", "public_key_id") => public_key_id = Some(unquote(value)),
            ("platforms", "android", "enabled") => android_enabled = Some(parse_bool(value)?),
            ("platforms", "android", "backend") => android_backend = Some(unquote(value)),
            ("platforms", "ios", "enabled") => ios_enabled = Some(parse_bool(value)?),
            ("platforms", "ios", "backend") => ios_backend = Some(unquote(value)),
            _ => {}
        }
    }

    let app_id = app_id.ok_or_else(|| err("fcb.yaml missing app_id"))?;
    Ok(FcbConfig {
        app_id,
        channel: channel.unwrap(),
        update: UpdateConfig {
            check_on_startup: check_on_startup.unwrap(),
            activation: activation.unwrap(),
        },
        security: SecurityConfig {
            public_key_id: public_key_id.unwrap(),
        },
        platforms: PlatformConfig {
            android: PlatformEntry {
                enabled: android_enabled.unwrap(),
                backend: android_backend.unwrap(),
                abi: android_abi,
            },
            ios: PlatformEntry {
                enabled: ios_enabled.unwrap(),
                backend: ios_backend.unwrap(),
                abi: ios_abi,
            },
        },
    })
}

fn unquote(value: &str) -> String {
    value.trim_matches('"').trim_matches('\'').to_string()
}

fn parse_bool(value: &str) -> Result<bool> {
    match value {
        "true" => Ok(true),
        "false" => Ok(false),
        _ => Err(err(format!("invalid bool value {value}"))),
    }
}

#[cfg(test)]
mod tests {
    use super::FcbConfig;

    #[test]
    fn yaml_roundtrip_preserves_ios_abi() {
        let mut config = FcbConfig::new("app".to_string());
        config.platforms.ios.abi = vec!["ios-arm64".to_string(), "ios-x64".to_string()];

        let parsed = super::parse_yaml_subset(&config.to_yaml()).expect("parse yaml");

        assert_eq!(parsed.platforms.ios.abi, config.platforms.ios.abi);
        assert_eq!(parsed.platforms.android.abi, config.platforms.android.abi);
    }
}
