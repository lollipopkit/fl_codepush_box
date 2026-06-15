use serde::{Deserialize, Serialize};

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
    use super::{RemoteAppConfig, RemotePlatformEntry};

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
}
