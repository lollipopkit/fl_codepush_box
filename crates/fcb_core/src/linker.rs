use crate::{err, Result};
use serde::{Deserialize, Serialize};
use std::collections::{BTreeMap, BTreeSet};

pub const KERNEL_INVENTORY_SCHEMA_VERSION: u32 = 1;

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub struct KernelInventory {
    pub schema_version: u32,
    #[serde(default)]
    pub functions: Vec<FunctionInventoryEntry>,
    #[serde(default)]
    pub classes: Vec<ClassInventoryEntry>,
    #[serde(default)]
    pub top_level_fields: Vec<FieldInventoryEntry>,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub struct FunctionInventoryEntry {
    pub function_id: String,
    pub library_uri: String,
    pub enclosing: String,
    pub member_name: String,
    pub signature_hash: String,
    pub body_hash: String,
    #[serde(default)]
    pub source_location: Option<String>,
    #[serde(default)]
    pub bytecode_source: Option<serde_json::Value>,
    #[serde(default)]
    pub unsupported_reasons: Vec<RejectReason>,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub struct ClassInventoryEntry {
    pub class_id: String,
    pub shape_hash: String,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub struct FieldInventoryEntry {
    pub field_id: String,
    pub signature_hash: String,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub struct LinkerPlan {
    #[serde(default)]
    pub unchanged: Vec<FunctionDecision>,
    #[serde(default)]
    pub interpret: Vec<FunctionDecision>,
    #[serde(default)]
    pub reject: Vec<RejectDecision>,
}

impl LinkerPlan {
    pub fn has_rejects(&self) -> bool {
        !self.reject.is_empty()
    }

    pub fn changed_function_count(&self) -> usize {
        self.interpret.len()
    }
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub struct FunctionDecision {
    pub function_id: String,
    pub source_location: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub struct RejectDecision {
    pub function_id: String,
    pub source_location: Option<String>,
    pub reject_reason: RejectReason,
    pub message: String,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
#[serde(rename_all = "snake_case")]
pub enum RejectReason {
    MissingBaselineFunction,
    SignatureChanged,
    ClassShapeChanged,
    FieldSignatureChanged,
    UnsupportedKernelNode,
    MissingBytecodeSource,
}

pub fn plan_bytecode_link(
    release: &KernelInventory,
    patch: &KernelInventory,
) -> Result<LinkerPlan> {
    release.validate()?;
    patch.validate()?;

    let release_functions = release.function_map()?;
    let release_classes = release.class_map()?;
    let patch_classes = patch.class_map()?;
    let release_fields = release.field_map()?;
    let patch_fields = patch.field_map()?;

    let mut plan = LinkerPlan {
        unchanged: Vec::new(),
        interpret: Vec::new(),
        reject: Vec::new(),
    };

    for (class_id, patch_class) in &patch_classes {
        if let Some(release_class) = release_classes.get(class_id) {
            if release_class.shape_hash != patch_class.shape_hash {
                plan.reject.push(RejectDecision {
                    function_id: class_id.clone(),
                    source_location: None,
                    reject_reason: RejectReason::ClassShapeChanged,
                    message: "class shape changed".to_string(),
                });
            }
        }
    }

    for (field_id, patch_field) in &patch_fields {
        if let Some(release_field) = release_fields.get(field_id) {
            if release_field.signature_hash != patch_field.signature_hash {
                plan.reject.push(RejectDecision {
                    function_id: field_id.clone(),
                    source_location: None,
                    reject_reason: RejectReason::FieldSignatureChanged,
                    message: "top-level field signature changed".to_string(),
                });
            }
        }
    }

    for function in &patch.functions {
        let Some(release_function) = release_functions.get(&function.function_id) else {
            plan.reject.push(RejectDecision {
                function_id: function.function_id.clone(),
                source_location: function.source_location.clone(),
                reject_reason: RejectReason::MissingBaselineFunction,
                message: "function is not present in the release baseline".to_string(),
            });
            continue;
        };
        if release_function.signature_hash != function.signature_hash {
            plan.reject.push(RejectDecision {
                function_id: function.function_id.clone(),
                source_location: function.source_location.clone(),
                reject_reason: RejectReason::SignatureChanged,
                message: "function signature changed".to_string(),
            });
            continue;
        }
        if release_function.body_hash == function.body_hash {
            plan.unchanged.push(FunctionDecision {
                function_id: function.function_id.clone(),
                source_location: function.source_location.clone(),
            });
            continue;
        }
        if let Some(reason) = function.unsupported_reasons.first() {
            plan.reject.push(RejectDecision {
                function_id: function.function_id.clone(),
                source_location: function.source_location.clone(),
                reject_reason: reason.clone(),
                message: "changed function contains unsupported Kernel nodes".to_string(),
            });
            continue;
        }
        if function.bytecode_source.is_none() {
            plan.reject.push(RejectDecision {
                function_id: function.function_id.clone(),
                source_location: function.source_location.clone(),
                reject_reason: RejectReason::MissingBytecodeSource,
                message: "changed function has no bytecode source".to_string(),
            });
            continue;
        }
        plan.interpret.push(FunctionDecision {
            function_id: function.function_id.clone(),
            source_location: function.source_location.clone(),
        });
    }

    Ok(plan)
}

impl KernelInventory {
    pub fn validate(&self) -> Result<()> {
        if self.schema_version != KERNEL_INVENTORY_SCHEMA_VERSION {
            return Err(err(format!(
                "unsupported kernel_inventory schema_version {}, expected {}",
                self.schema_version, KERNEL_INVENTORY_SCHEMA_VERSION
            )));
        }
        let mut seen = BTreeSet::new();
        for function in &self.functions {
            if function.function_id.trim().is_empty() {
                return Err(err("kernel inventory function_id must not be empty"));
            }
            if !seen.insert(function.function_id.clone()) {
                return Err(err(format!(
                    "duplicate kernel inventory function {}",
                    function.function_id
                )));
            }
        }
        Ok(())
    }

    fn function_map(&self) -> Result<BTreeMap<String, &FunctionInventoryEntry>> {
        let mut map = BTreeMap::new();
        for function in &self.functions {
            if map.insert(function.function_id.clone(), function).is_some() {
                return Err(err(format!(
                    "duplicate kernel inventory function {}",
                    function.function_id
                )));
            }
        }
        Ok(map)
    }

    fn class_map(&self) -> Result<BTreeMap<String, &ClassInventoryEntry>> {
        let mut map = BTreeMap::new();
        for class in &self.classes {
            if map.insert(class.class_id.clone(), class).is_some() {
                return Err(err(format!(
                    "duplicate kernel inventory class {}",
                    class.class_id
                )));
            }
        }
        Ok(map)
    }

    fn field_map(&self) -> Result<BTreeMap<String, &FieldInventoryEntry>> {
        let mut map = BTreeMap::new();
        for field in &self.top_level_fields {
            if map.insert(field.field_id.clone(), field).is_some() {
                return Err(err(format!(
                    "duplicate kernel inventory field {}",
                    field.field_id
                )));
            }
        }
        Ok(map)
    }
}

#[cfg(test)]
mod tests {
    use super::{
        plan_bytecode_link, ClassInventoryEntry, FieldInventoryEntry, FunctionInventoryEntry,
        KernelInventory, RejectReason, KERNEL_INVENTORY_SCHEMA_VERSION,
    };

    fn function(id: &str, sig: &str, body: &str, bytecode: bool) -> FunctionInventoryEntry {
        FunctionInventoryEntry {
            function_id: id.to_string(),
            library_uri: "package:app/main.dart".to_string(),
            enclosing: String::new(),
            member_name: id.to_string(),
            signature_hash: sig.to_string(),
            body_hash: body.to_string(),
            source_location: Some("lib/main.dart:1".to_string()),
            bytecode_source: bytecode.then(|| serde_json::json!({"int": 1})),
            unsupported_reasons: Vec::new(),
        }
    }

    fn inventory(functions: Vec<FunctionInventoryEntry>) -> KernelInventory {
        KernelInventory {
            schema_version: KERNEL_INVENTORY_SCHEMA_VERSION,
            functions,
            classes: Vec::new(),
            top_level_fields: Vec::new(),
        }
    }

    #[test]
    fn splits_unchanged_interpret_and_reject() {
        let release = inventory(vec![
            function("same", "sig", "old", false),
            function("changed", "sig", "old", false),
            function("sig", "old-sig", "old", false),
        ]);
        let patch = inventory(vec![
            function("same", "sig", "old", false),
            function("changed", "sig", "new", true),
            function("sig", "new-sig", "new", true),
        ]);

        let plan = plan_bytecode_link(&release, &patch).expect("plan");

        assert_eq!(plan.unchanged[0].function_id, "same");
        assert_eq!(plan.interpret[0].function_id, "changed");
        assert_eq!(plan.reject[0].reject_reason, RejectReason::SignatureChanged);
    }

    #[test]
    fn rejects_class_shape_and_field_signature_changes() {
        let mut release = inventory(vec![function("same", "sig", "old", false)]);
        release.classes.push(ClassInventoryEntry {
            class_id: "class:pricing".to_string(),
            shape_hash: "old-shape".to_string(),
        });
        release.top_level_fields.push(FieldInventoryEntry {
            field_id: "field:flag".to_string(),
            signature_hash: "old-field".to_string(),
        });
        let mut patch = inventory(vec![function("same", "sig", "old", false)]);
        patch.classes.push(ClassInventoryEntry {
            class_id: "class:pricing".to_string(),
            shape_hash: "new-shape".to_string(),
        });
        patch.top_level_fields.push(FieldInventoryEntry {
            field_id: "field:flag".to_string(),
            signature_hash: "new-field".to_string(),
        });

        let plan = plan_bytecode_link(&release, &patch).expect("plan");

        assert!(plan
            .reject
            .iter()
            .any(|reject| reject.reject_reason == RejectReason::ClassShapeChanged));
        assert!(plan
            .reject
            .iter()
            .any(|reject| reject.reject_reason == RejectReason::FieldSignatureChanged));
    }

    #[test]
    fn rejects_changed_function_without_bytecode_source() {
        let release = inventory(vec![function("changed", "sig", "old", false)]);
        let patch = inventory(vec![function("changed", "sig", "new", false)]);

        let plan = plan_bytecode_link(&release, &patch).expect("plan");

        assert_eq!(
            plan.reject[0].reject_reason,
            RejectReason::MissingBytecodeSource
        );
        assert!(plan.interpret.is_empty());
    }
}
