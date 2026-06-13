//! Restricted bytecode linker.
//!
//! Phase C intentionally keeps the first linker contract small: a Dart Kernel
//! analyzer or build transformer emits normalized function descriptors, and
//! this linker performs stable FunctionId generation plus P1 change-policy
//! decisions before producing an HBC module for interpreted functions.

use crate::compiler::{compile_module, PatchableFunction};
use crate::format::BytecodeModule;
use fcb_core::{crypto, err, Error, Result};
use serde::{Deserialize, Serialize};
use std::collections::{BTreeMap, BTreeSet};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ProgramSpec {
    pub app_id: String,
    pub release_version: String,
    #[serde(default)]
    pub constants_added: u32,
    pub functions: Vec<FunctionSpec>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FunctionSpec {
    pub canonical_library_uri: String,
    #[serde(default)]
    pub class_qualified_name: String,
    pub member_name: String,
    pub normalized_type_signature: String,
    #[serde(default)]
    pub type_parameter_shape: String,
    pub body_hash: String,
    #[serde(default)]
    pub class_shape_hash: String,
    #[serde(default)]
    pub visibility: Visibility,
    pub param_count: u8,
    #[serde(default)]
    pub bytecode: Vec<u8>,
    #[serde(default)]
    pub unsupported_changes: Vec<UnsupportedChange>,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum Visibility {
    Public,
    Private,
}

impl Default for Visibility {
    fn default() -> Self {
        Self::Public
    }
}

#[derive(Debug, Clone, PartialEq, Eq, PartialOrd, Ord, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum UnsupportedChange {
    PublicFunctionSignatureChanged,
    InstanceFieldLayoutChanged,
    EnumShapeChanged,
    NativePluginDependencyChanged,
    MainEntrypointChanged,
    IsolateEntrypointChanged,
    FfiSignatureChanged,
    MethodChannelNativeContractChanged,
    AssetPathChanged,
    MirrorsReflection,
    UnsupportedSyntax,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LinkOutput {
    pub report: LinkReport,
    pub module: BytecodeModule,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LinkReport {
    pub functions: BTreeMap<String, LinkDecision>,
    pub class_shape_changes: Vec<String>,
    pub constants_added: u32,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LinkDecision {
    pub decision: DecisionKind,
    pub reason: String,
    pub function_id: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub bytecode_offset: Option<u32>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub bytecode_length: Option<u32>,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum DecisionKind {
    ReuseAot,
    Interpret,
    Reject,
    Deleted,
}

/// Generate the stable P1 FunctionId specified in PLAN.md.
pub fn function_id(function: &FunctionSpec) -> String {
    crypto::sha256_hex(
        format!(
            "{}\n{}\n{}\n{}\n{}",
            normalize_uri(&function.canonical_library_uri),
            normalize_name(&function.class_qualified_name),
            normalize_name(&function.member_name),
            normalize_signature(&function.normalized_type_signature),
            normalize_signature(&function.type_parameter_shape),
        )
        .as_bytes(),
    )
}

pub fn link_programs(
    base: &ProgramSpec,
    patch: &ProgramSpec,
    patch_number: u32,
) -> Result<LinkOutput> {
    if base.app_id != patch.app_id {
        return Err(err(format!(
            "app_id mismatch: base={} patch={}",
            base.app_id, patch.app_id
        )));
    }
    if base.release_version != patch.release_version {
        return Err(err(format!(
            "release_version mismatch: base={} patch={}",
            base.release_version, patch.release_version
        )));
    }

    let base_by_symbol = index_by_symbol(&base.functions)?;
    let patch_by_symbol = index_by_symbol(&patch.functions)?;
    let mut all_symbols = BTreeSet::new();
    all_symbols.extend(base_by_symbol.keys().cloned());
    all_symbols.extend(patch_by_symbol.keys().cloned());

    let mut decisions = BTreeMap::new();
    let mut class_shape_changes = BTreeSet::new();
    let mut interpreted = Vec::new();
    let mut bytecode_offset = 0u32;

    for symbol in all_symbols {
        match (base_by_symbol.get(&symbol), patch_by_symbol.get(&symbol)) {
            (Some(base_fn), Some(patch_fn)) => {
                let id = function_id(patch_fn);
                if base_fn.normalized_type_signature != patch_fn.normalized_type_signature {
                    decisions.insert(
                        symbol.clone(),
                        reject(id, "public_function_signature_changed"),
                    );
                    continue;
                }
                if base_fn.type_parameter_shape != patch_fn.type_parameter_shape {
                    decisions.insert(symbol.clone(), reject(id, "type_parameter_shape_changed"));
                    continue;
                }
                if base_fn.class_shape_hash != patch_fn.class_shape_hash {
                    class_shape_changes.insert(symbol.clone());
                    decisions.insert(symbol.clone(), reject(id, "instance_field_layout_changed"));
                    continue;
                }
                if let Some(reason) = first_unsupported_change(patch_fn) {
                    decisions.insert(symbol.clone(), reject(id, &reason));
                    continue;
                }
                if base_fn.body_hash == patch_fn.body_hash {
                    decisions.insert(
                        symbol,
                        LinkDecision {
                            decision: DecisionKind::ReuseAot,
                            reason: "body_hash_equal".to_string(),
                            function_id: id,
                            bytecode_offset: None,
                            bytecode_length: None,
                        },
                    );
                    continue;
                }
                if patch_fn.bytecode.is_empty() {
                    decisions.insert(symbol.clone(), reject(id, "changed_body_missing_bytecode"));
                    continue;
                }

                let length = patch_fn.bytecode.len() as u32;
                decisions.insert(
                    symbol,
                    LinkDecision {
                        decision: DecisionKind::Interpret,
                        reason: "body_changed".to_string(),
                        function_id: id,
                        bytecode_offset: Some(bytecode_offset),
                        bytecode_length: Some(length),
                    },
                );
                bytecode_offset = bytecode_offset.saturating_add(length);
                interpreted.push(to_patchable_function(patch_fn));
            }
            (None, Some(patch_fn)) => {
                let id = function_id(patch_fn);
                if let Some(reason) = first_unsupported_change(patch_fn) {
                    decisions.insert(symbol.clone(), reject(id, &reason));
                    continue;
                }
                if patch_fn.visibility == Visibility::Public {
                    decisions.insert(symbol.clone(), reject(id, "new_public_function"));
                    continue;
                }
                if patch_fn.bytecode.is_empty() {
                    decisions.insert(symbol.clone(), reject(id, "new_function_missing_bytecode"));
                    continue;
                }
                let length = patch_fn.bytecode.len() as u32;
                decisions.insert(
                    symbol,
                    LinkDecision {
                        decision: DecisionKind::Interpret,
                        reason: "new_private_function".to_string(),
                        function_id: id,
                        bytecode_offset: Some(bytecode_offset),
                        bytecode_length: Some(length),
                    },
                );
                bytecode_offset = bytecode_offset.saturating_add(length);
                interpreted.push(to_patchable_function(patch_fn));
            }
            (Some(base_fn), None) => {
                decisions.insert(
                    symbol,
                    LinkDecision {
                        decision: DecisionKind::Deleted,
                        reason: "function_deleted".to_string(),
                        function_id: function_id(base_fn),
                        bytecode_offset: None,
                        bytecode_length: None,
                    },
                );
            }
            (None, None) => unreachable!("symbol set is built from both maps"),
        }
    }

    let report = LinkReport {
        functions: decisions,
        class_shape_changes: class_shape_changes.into_iter().collect(),
        constants_added: patch.constants_added.saturating_sub(base.constants_added),
    };
    fail_if_rejected(&report)?;
    let module = compile_module(
        &patch.app_id,
        &patch.release_version,
        patch_number,
        interpreted,
    )?;
    Ok(LinkOutput { report, module })
}

fn index_by_symbol(functions: &[FunctionSpec]) -> Result<BTreeMap<String, FunctionSpec>> {
    let mut out = BTreeMap::new();
    for function in functions {
        let symbol = symbol_key(function);
        if out.insert(symbol.clone(), function.clone()).is_some() {
            return Err(err(format!("duplicate function symbol: {symbol}")));
        }
    }
    Ok(out)
}

fn symbol_key(function: &FunctionSpec) -> String {
    format!(
        "{}::{}::{}",
        normalize_uri(&function.canonical_library_uri),
        normalize_name(&function.class_qualified_name),
        normalize_name(&function.member_name),
    )
}

fn normalize_uri(value: &str) -> String {
    value.trim().replace('\\', "/")
}

fn normalize_name(value: &str) -> String {
    value.trim().to_string()
}

fn normalize_signature(value: &str) -> String {
    value.chars().filter(|ch| !ch.is_whitespace()).collect()
}

fn first_unsupported_change(function: &FunctionSpec) -> Option<String> {
    function
        .unsupported_changes
        .iter()
        .min()
        .map(|change| serde_json::to_value(change).ok())
        .flatten()
        .and_then(|value| value.as_str().map(ToOwned::to_owned))
}

fn reject(function_id: String, reason: &str) -> LinkDecision {
    LinkDecision {
        decision: DecisionKind::Reject,
        reason: reason.to_string(),
        function_id,
        bytecode_offset: None,
        bytecode_length: None,
    }
}

fn to_patchable_function(function: &FunctionSpec) -> PatchableFunction {
    PatchableFunction {
        name: symbol_key(function),
        param_count: function.param_count,
        code: function.bytecode.clone(),
    }
}

fn fail_if_rejected(report: &LinkReport) -> Result<()> {
    let rejected = report
        .functions
        .iter()
        .filter(|(_, decision)| decision.decision == DecisionKind::Reject)
        .map(|(symbol, decision)| format!("{symbol}: {}", decision.reason))
        .collect::<Vec<_>>();
    if rejected.is_empty() {
        return Ok(());
    }
    Err(Error::Message(format!(
        "unsupported P1 bytecode changes:\n{}",
        rejected.join("\n")
    )))
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::opcodes::OpCode;

    fn spec(member_name: &str, body_hash: &str, bytecode: Vec<u8>) -> FunctionSpec {
        FunctionSpec {
            canonical_library_uri: "package:app/pricing.dart".to_string(),
            class_qualified_name: String::new(),
            member_name: member_name.to_string(),
            normalized_type_signature: "(int)->int".to_string(),
            type_parameter_shape: String::new(),
            body_hash: body_hash.to_string(),
            class_shape_hash: "shape1".to_string(),
            visibility: Visibility::Public,
            param_count: 1,
            bytecode,
            unsupported_changes: Vec::new(),
        }
    }

    #[test]
    fn function_id_is_stable_after_whitespace_normalization() {
        let mut a = spec("price", "body1", vec![]);
        let mut b = a.clone();
        b.canonical_library_uri = " package:app/pricing.dart ".to_string();
        b.normalized_type_signature = "(int)   ->   int".to_string();
        assert_eq!(function_id(&a), function_id(&b));
        a.member_name = "other".to_string();
        assert_ne!(function_id(&a), function_id(&b));
    }

    #[test]
    fn unchanged_function_reuses_aot() {
        let base = ProgramSpec {
            app_id: "app".to_string(),
            release_version: "1.0.0+1".to_string(),
            constants_added: 0,
            functions: vec![spec("price", "same", vec![])],
        };
        let patch = base.clone();
        let output = link_programs(&base, &patch, 1).expect("link");
        let decision = output
            .report
            .functions
            .get("package:app/pricing.dart::::price")
            .expect("decision");
        assert_eq!(decision.decision, DecisionKind::ReuseAot);
        assert!(output.module.functions.is_empty());
    }

    #[test]
    fn changed_function_enters_interpreter() {
        let base = ProgramSpec {
            app_id: "app".to_string(),
            release_version: "1.0.0+1".to_string(),
            constants_added: 0,
            functions: vec![spec("price", "base", vec![])],
        };
        let patch = ProgramSpec {
            functions: vec![spec(
                "price",
                "patch",
                vec![OpCode::LoadLocal.byte(), 0, OpCode::Return.byte()],
            )],
            ..base.clone()
        };
        let output = link_programs(&base, &patch, 1).expect("link");
        let decision = output
            .report
            .functions
            .get("package:app/pricing.dart::::price")
            .expect("decision");
        assert_eq!(decision.decision, DecisionKind::Interpret);
        assert_eq!(output.module.functions.len(), 1);
    }

    #[test]
    fn signature_change_fails_fast() {
        let base = ProgramSpec {
            app_id: "app".to_string(),
            release_version: "1.0.0+1".to_string(),
            constants_added: 0,
            functions: vec![spec("price", "base", vec![])],
        };
        let mut changed = spec("price", "patch", vec![OpCode::Return.byte()]);
        changed.normalized_type_signature = "(String)->int".to_string();
        let patch = ProgramSpec {
            functions: vec![changed],
            ..base.clone()
        };
        let err = link_programs(&base, &patch, 1).expect_err("signature change should fail");
        assert!(err
            .to_string()
            .contains("public_function_signature_changed"));
    }

    #[test]
    fn explicit_unsupported_change_fails_fast() {
        let base = ProgramSpec {
            app_id: "app".to_string(),
            release_version: "1.0.0+1".to_string(),
            constants_added: 0,
            functions: vec![spec("price", "base", vec![])],
        };
        let mut patch_fn = spec("price", "patch", vec![OpCode::Return.byte()]);
        patch_fn
            .unsupported_changes
            .push(UnsupportedChange::FfiSignatureChanged);
        let patch = ProgramSpec {
            functions: vec![patch_fn],
            ..base.clone()
        };
        let err = link_programs(&base, &patch, 1).expect_err("unsupported change should fail");
        assert!(err.to_string().contains("ffi_signature_changed"));
    }
}
