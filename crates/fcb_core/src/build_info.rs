use crate::{err, Result};
use serde::{Deserialize, Serialize};
use std::collections::{BTreeMap, BTreeSet};

pub const BUILD_INFO_SCHEMA_VERSION: u32 = 3;

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub struct BuildInfo {
    pub schema_version: u32,
    pub backend: String,
    pub platform: String,
    pub arch: String,
    pub target_platform: String,
    pub build_mode: String,
    #[serde(default)]
    pub flavor: Option<String>,
    pub flutter_tool_rev: String,
    pub engine_fork_rev: String,
    pub dart_sdk_rev: String,
    pub pubspec_lock_hash: String,
    pub asset_hash: String,
    pub native_hash: String,
    pub plugin_hash: String,
    pub obfuscation: bool,
    pub split_debug_info: Option<String>,
    #[serde(default)]
    pub dart_defines: BTreeMap<String, String>,
    #[serde(default)]
    pub ignored_dart_define_keys: BTreeSet<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub struct BuildInfoMismatch {
    pub field: String,
    pub release_value: String,
    pub patch_value: String,
    pub severity: MismatchSeverity,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
#[serde(rename_all = "snake_case")]
pub enum MismatchSeverity {
    HardFail,
    Warning,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default, PartialEq, Eq)]
pub struct BuildInfoComparison {
    pub hard_failures: Vec<BuildInfoMismatch>,
    pub warnings: Vec<BuildInfoMismatch>,
}

impl BuildInfoComparison {
    pub fn is_ok(&self) -> bool {
        self.hard_failures.is_empty()
    }

    pub fn ensure_ok(&self) -> Result<()> {
        if self.is_ok() {
            return Ok(());
        }
        let fields = self
            .hard_failures
            .iter()
            .map(|mismatch| mismatch.field.as_str())
            .collect::<Vec<_>>()
            .join(", ");
        Err(err(format!(
            "release was built with different config: {fields}"
        )))
    }
}

impl BuildInfo {
    pub fn validate(&self) -> Result<()> {
        if self.schema_version != BUILD_INFO_SCHEMA_VERSION {
            return Err(err(format!(
                "unsupported build_info schema_version {}, expected {}",
                self.schema_version, BUILD_INFO_SCHEMA_VERSION
            )));
        }
        for (field, value) in [
            ("backend", &self.backend),
            ("platform", &self.platform),
            ("arch", &self.arch),
            ("target_platform", &self.target_platform),
            ("build_mode", &self.build_mode),
            ("flutter_tool_rev", &self.flutter_tool_rev),
            ("engine_fork_rev", &self.engine_fork_rev),
            ("dart_sdk_rev", &self.dart_sdk_rev),
        ] {
            if value.trim().is_empty() {
                return Err(err(format!("build_info missing {field}")));
            }
        }
        Ok(())
    }

    pub fn compare_for_patch(&self, patch: &Self) -> BuildInfoComparison {
        let mut comparison = BuildInfoComparison::default();
        for (field, release, patch) in [
            (
                "schema_version",
                self.schema_version.to_string(),
                patch.schema_version.to_string(),
            ),
            ("backend", self.backend.clone(), patch.backend.clone()),
            ("platform", self.platform.clone(), patch.platform.clone()),
            ("arch", self.arch.clone(), patch.arch.clone()),
            (
                "target_platform",
                self.target_platform.clone(),
                patch.target_platform.clone(),
            ),
            (
                "build_mode",
                self.build_mode.clone(),
                patch.build_mode.clone(),
            ),
            (
                "flavor",
                self.flavor.clone().unwrap_or_default(),
                patch.flavor.clone().unwrap_or_default(),
            ),
            (
                "flutter_tool_rev",
                self.flutter_tool_rev.clone(),
                patch.flutter_tool_rev.clone(),
            ),
            (
                "engine_fork_rev",
                self.engine_fork_rev.clone(),
                patch.engine_fork_rev.clone(),
            ),
            (
                "dart_sdk_rev",
                self.dart_sdk_rev.clone(),
                patch.dart_sdk_rev.clone(),
            ),
            (
                "pubspec_lock_hash",
                self.pubspec_lock_hash.clone(),
                patch.pubspec_lock_hash.clone(),
            ),
            (
                "asset_hash",
                self.asset_hash.clone(),
                patch.asset_hash.clone(),
            ),
            (
                "native_hash",
                self.native_hash.clone(),
                patch.native_hash.clone(),
            ),
            (
                "plugin_hash",
                self.plugin_hash.clone(),
                patch.plugin_hash.clone(),
            ),
            (
                "obfuscation",
                self.obfuscation.to_string(),
                patch.obfuscation.to_string(),
            ),
            (
                "split_debug_info",
                self.split_debug_info.clone().unwrap_or_default(),
                patch.split_debug_info.clone().unwrap_or_default(),
            ),
        ] {
            if release != patch {
                comparison.hard_failures.push(BuildInfoMismatch {
                    field: field.to_string(),
                    release_value: release,
                    patch_value: patch,
                    severity: MismatchSeverity::HardFail,
                });
            }
        }

        let ignored = self
            .ignored_dart_define_keys
            .union(&patch.ignored_dart_define_keys)
            .cloned()
            .collect::<BTreeSet<_>>();
        let keys = self
            .dart_defines
            .keys()
            .chain(patch.dart_defines.keys())
            .cloned()
            .collect::<BTreeSet<_>>();
        for key in keys {
            if ignored.contains(&key) {
                continue;
            }
            let release = self.dart_defines.get(&key).cloned().unwrap_or_default();
            let patch = patch.dart_defines.get(&key).cloned().unwrap_or_default();
            if release != patch {
                comparison.warnings.push(BuildInfoMismatch {
                    field: format!("dart_define.{key}"),
                    release_value: release,
                    patch_value: patch,
                    severity: MismatchSeverity::Warning,
                });
            }
        }
        comparison
    }
}

#[cfg(test)]
mod tests {
    use super::{BuildInfo, BUILD_INFO_SCHEMA_VERSION};
    use std::collections::{BTreeMap, BTreeSet};

    fn info() -> BuildInfo {
        BuildInfo {
            schema_version: BUILD_INFO_SCHEMA_VERSION,
            backend: "bytecode".to_string(),
            platform: "ios".to_string(),
            arch: "arm64".to_string(),
            target_platform: "iphoneos".to_string(),
            build_mode: "release".to_string(),
            flavor: None,
            flutter_tool_rev: "flutter".to_string(),
            engine_fork_rev: "engine".to_string(),
            dart_sdk_rev: "dart".to_string(),
            pubspec_lock_hash: "lock".to_string(),
            asset_hash: "assets".to_string(),
            native_hash: "native".to_string(),
            plugin_hash: "plugins".to_string(),
            obfuscation: false,
            split_debug_info: None,
            dart_defines: BTreeMap::new(),
            ignored_dart_define_keys: BTreeSet::new(),
        }
    }

    #[test]
    fn treats_dart_define_changes_as_warnings() {
        let mut release = info();
        release
            .dart_defines
            .insert("API".to_string(), "prod".to_string());
        let mut patch = info();
        patch
            .dart_defines
            .insert("API".to_string(), "stage".to_string());

        let comparison = release.compare_for_patch(&patch);

        assert!(comparison.hard_failures.is_empty());
        assert_eq!(comparison.warnings[0].field, "dart_define.API");
    }

    #[test]
    fn ignores_declared_dart_define_changes() {
        let mut release = info();
        release
            .dart_defines
            .insert("API".to_string(), "prod".to_string());
        release.ignored_dart_define_keys.insert("API".to_string());
        let mut patch = info();
        patch
            .dart_defines
            .insert("API".to_string(), "stage".to_string());

        let comparison = release.compare_for_patch(&patch);

        assert!(comparison.hard_failures.is_empty());
        assert!(comparison.warnings.is_empty());
    }

    #[test]
    fn hard_fails_flavor_changes() {
        let release = info();
        let mut patch = info();
        patch.flavor = Some("staging".to_string());

        let comparison = release.compare_for_patch(&patch);

        assert_eq!(comparison.hard_failures[0].field, "flavor");
    }

    #[test]
    fn hard_fails_runtime_artifact_hash_changes() {
        let release = info();
        let mut patch = info();
        patch.asset_hash = "changed-assets".to_string();
        patch.native_hash = "changed-native".to_string();
        patch.plugin_hash = "changed-plugins".to_string();

        let comparison = release.compare_for_patch(&patch);
        let fields = comparison
            .hard_failures
            .iter()
            .map(|mismatch| mismatch.field.as_str())
            .collect::<Vec<_>>();

        assert!(fields.contains(&"asset_hash"));
        assert!(fields.contains(&"native_hash"));
        assert!(fields.contains(&"plugin_hash"));
    }
}
