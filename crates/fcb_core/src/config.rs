use crate::{err, Result};
use serde::{Deserialize, Serialize};
use std::collections::{BTreeMap, BTreeSet};
use std::{fs, path::Path};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LocalAppContext {
    pub app: String,
    pub server: String,
    pub key_file: String,
    #[serde(default)]
    pub build: LocalBuildConfig,
}

impl LocalAppContext {
    pub fn read_yaml(path: &Path) -> Result<Self> {
        let source = fs::read_to_string(path)?;
        let context: Self = serde_yaml::from_str(&source)?;
        context.validate()?;
        Ok(context)
    }

    pub fn write_yaml(&self, path: &Path) -> Result<()> {
        if let Some(parent) = path.parent() {
            fs::create_dir_all(parent)?;
        }
        fs::write(path, serde_yaml::to_string(self)?)?;
        Ok(())
    }

    pub fn validate(&self) -> Result<()> {
        if self.app.trim().is_empty() {
            return Err(err("fcb.yaml missing app"));
        }
        if self.server.trim().is_empty() {
            return Err(err("fcb.yaml missing server"));
        }
        if self.key_file.trim().is_empty() {
            return Err(err("fcb.yaml missing key_file"));
        }
        self.build.validate()?;
        Ok(())
    }
}

#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct LocalBuildConfig {
    #[serde(default)]
    pub project: Option<String>,
    #[serde(default)]
    pub flutter: Option<String>,
    #[serde(default)]
    pub target: Option<String>,
    #[serde(default)]
    pub build_mode: Option<String>,
    #[serde(default)]
    pub flavor: Option<String>,
    #[serde(default)]
    pub dart_defines: BTreeMap<String, String>,
    #[serde(default)]
    pub ignored_dart_define_keys: BTreeSet<String>,
    #[serde(default)]
    pub platforms: BTreeMap<String, LocalPlatformBuildConfig>,
}

#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct LocalPlatformBuildConfig {
    #[serde(default)]
    pub abis: Vec<String>,
    #[serde(default)]
    pub sdk: Option<String>,
    #[serde(default)]
    pub local_engine: Option<String>,
    #[serde(default)]
    pub local_engine_host: Option<String>,
    #[serde(default)]
    pub local_engine_src_path: Option<String>,
}

impl LocalBuildConfig {
    pub fn validate(&self) -> Result<()> {
        if let Some(build_mode) = &self.build_mode {
            if !matches!(build_mode.as_str(), "debug" | "profile" | "release") {
                return Err(err(format!("unsupported build.build_mode {build_mode}")));
            }
        }
        for (platform, config) in &self.platforms {
            if platform == "ios" {
                if let Some(sdk) = &config.sdk {
                    if !matches!(sdk.as_str(), "iphoneos" | "iphonesimulator") {
                        return Err(err(format!("unsupported build platform ios sdk {sdk}")));
                    }
                }
            }
        }
        Ok(())
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RemoteAppConfig {
    pub id: String,
    pub name: String,
    pub channel: String,
    pub public_key: String,
    #[serde(default)]
    pub platforms: Vec<RemotePlatformEntry>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RemotePlatformEntry {
    pub platform: String,
    pub enabled: bool,
    pub backend: String,
    #[serde(default)]
    pub abi: Vec<String>,
}

impl RemoteAppConfig {
    pub fn platform(&self, name: &str) -> Option<&RemotePlatformEntry> {
        self.platforms.iter().find(|entry| entry.platform == name)
    }

    pub fn enabled_platforms(&self) -> Vec<&RemotePlatformEntry> {
        self.platforms
            .iter()
            .filter(|entry| entry.enabled)
            .collect()
    }
}

#[cfg(test)]
mod tests {
    use super::{LocalAppContext, RemoteAppConfig, RemotePlatformEntry};

    #[test]
    fn selects_platforms() {
        let config = RemoteAppConfig {
            id: "app".to_string(),
            name: "App".to_string(),
            channel: "stable".to_string(),
            public_key: "key".to_string(),
            platforms: vec![
                RemotePlatformEntry {
                    platform: "android".to_string(),
                    enabled: true,
                    backend: "snapshot_replace".to_string(),
                    abi: vec!["arm64-v8a".to_string()],
                },
                RemotePlatformEntry {
                    platform: "ios".to_string(),
                    enabled: false,
                    backend: "bytecode".to_string(),
                    abi: vec![],
                },
            ],
        };

        assert_eq!(
            config.platform("android").expect("android").backend,
            "snapshot_replace"
        );
        assert_eq!(config.enabled_platforms().len(), 1);
    }

    #[test]
    fn local_context_yaml_roundtrip() {
        let context = LocalAppContext {
            app: "Counter App".to_string(),
            server: "http://127.0.0.1:8080".to_string(),
            key_file: "~/.ssh/id_ed25519".to_string(),
            build: Default::default(),
        };
        let parsed: LocalAppContext =
            serde_yaml::from_str(&serde_yaml::to_string(&context).expect("serialize"))
                .expect("parse yaml");

        assert_eq!(parsed.app, context.app);
        assert_eq!(parsed.server, context.server);
        assert_eq!(parsed.key_file, context.key_file);
        parsed.validate().expect("valid context");
    }
}
