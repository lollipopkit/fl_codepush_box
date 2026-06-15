use crate::{err, Result};
use serde::{Deserialize, Serialize};
use std::{fs, path::Path};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FcbConfig {
    pub active_app_id: String,
    pub apps: Vec<AppConfig>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AppConfig {
    pub id: String,
    pub name: String,
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
            active_app_id: app_id.clone(),
            apps: vec![AppConfig::new(app_id, "FCB App".to_string())],
        }
    }

    pub fn write_yaml(&self, path: &Path) -> Result<()> {
        fs::write(path, serde_yaml::to_string(self)?)?;
        Ok(())
    }

    pub fn read_yaml(path: &Path) -> Result<Self> {
        let source = fs::read_to_string(path)?;
        if looks_like_legacy_config(&source) {
            return Err(err(
                "legacy fcb.yaml with top-level app_id is no longer supported; run fcb init in a new project or migrate to active_app_id + apps[]",
            ));
        }
        let config: FcbConfig = serde_yaml::from_str(&source)?;
        config.validate()?;
        Ok(config)
    }

    pub fn validate(&self) -> Result<()> {
        if self.active_app_id.trim().is_empty() {
            return Err(err("fcb.yaml missing active_app_id"));
        }
        if self.apps.is_empty() {
            return Err(err("fcb.yaml apps[] must not be empty"));
        }
        if self.apps.iter().all(|app| app.id != self.active_app_id) {
            return Err(err(format!(
                "active_app_id {} does not match any apps[].id",
                self.active_app_id
            )));
        }
        for app in &self.apps {
            if app.id.trim().is_empty() {
                return Err(err("apps[].id must not be empty"));
            }
            if app.name.trim().is_empty() {
                return Err(err(format!("app {} missing name", app.id)));
            }
        }
        Ok(())
    }

    pub fn active_app(&self) -> Result<&AppConfig> {
        self.app(&self.active_app_id)
    }

    pub fn app(&self, selector: &str) -> Result<&AppConfig> {
        self.apps
            .iter()
            .find(|app| app.id == selector || app.name == selector)
            .ok_or_else(|| err(format!("app {selector} not found in fcb.yaml")))
    }

    pub fn app_mut(&mut self, selector: &str) -> Result<&mut AppConfig> {
        self.apps
            .iter_mut()
            .find(|app| app.id == selector || app.name == selector)
            .ok_or_else(|| err(format!("app {selector} not found in fcb.yaml")))
    }

    pub fn selected_app(&self, selector: Option<&str>) -> Result<&AppConfig> {
        match selector {
            Some(selector) => self.app(selector),
            None => self.active_app(),
        }
    }
}

impl AppConfig {
    pub fn new(id: String, name: String) -> Self {
        Self {
            id,
            name,
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
}

fn looks_like_legacy_config(source: &str) -> bool {
    source
        .lines()
        .any(|line| line.starts_with("app_id:") || line.starts_with("app_id :"))
}

#[cfg(test)]
mod tests {
    use super::{AppConfig, FcbConfig};

    #[test]
    fn yaml_roundtrip_preserves_ios_abi() {
        let mut config = FcbConfig::new("app".to_string());
        config.apps[0].platforms.ios.abi = vec!["ios-arm64".to_string(), "ios-x64".to_string()];

        let parsed: FcbConfig =
            serde_yaml::from_str(&serde_yaml::to_string(&config).expect("serialize"))
                .expect("parse yaml");

        assert_eq!(
            parsed.apps[0].platforms.ios.abi,
            config.apps[0].platforms.ios.abi
        );
        assert_eq!(
            parsed.apps[0].platforms.android.abi,
            config.apps[0].platforms.android.abi
        );
    }

    #[test]
    fn selects_app_by_id_or_name() {
        let mut config = FcbConfig::new("app-a".to_string());
        config
            .apps
            .push(AppConfig::new("app-b".to_string(), "Beta".to_string()));

        assert_eq!(config.app("app-b").expect("id").id, "app-b");
        assert_eq!(config.app("Beta").expect("name").id, "app-b");
    }

    #[test]
    fn rejects_legacy_top_level_app_id() {
        assert!(super::looks_like_legacy_config(
            "app_id: old\nchannel: stable\n"
        ));
    }
}
