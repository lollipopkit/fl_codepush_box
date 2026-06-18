use crate::auto::{estimated_interpreter_ratio, interpreter_ratio_warning, PatchReport};
use fcb_bytecode::format::{BytecodeModule, OpCode};
use fcb_core::manifest::{PatchManifest, ReleaseManifest};
use fcb_core::{err, Result};
use serde_json::Value;
use std::fs;
use std::path::Path;

pub(crate) fn inspect(kind: &str, path: &Path) -> Result<()> {
    let bytes = fs::read(path)?;
    match kind {
        "patch" => inspect_patch(&bytes),
        "release" => {
            let manifest: ReleaseManifest = serde_json::from_slice(&bytes)?;
            println!("{}", serde_json::to_string_pretty(&manifest)?);
            Ok(())
        }
        _ => Err(err("inspect kind must be patch or release")),
    }
}

fn inspect_patch(bytes: &[u8]) -> Result<()> {
    let json: Value = match serde_json::from_slice(bytes) {
        Ok(json) => json,
        Err(json_error) => {
            let module = BytecodeModule::from_slice(bytes).map_err(|module_error| {
                err(format!(
                    "patch is not JSON ({json_error}) or bytecode module ({module_error})"
                ))
            })?;
            println!(
                "{}",
                serde_json::to_string_pretty(&bytecode_summary(&module))?
            );
            return Ok(());
        }
    };
    if json.get("status").is_some() {
        let report: PatchReport = serde_json::from_value(json)?;
        let summary = patch_report_summary(&report)?;
        if let Some(warning) = summary
            .get("interpreter_ratio_warning")
            .and_then(Value::as_str)
        {
            eprintln!("{warning}");
        }
        println!("{}", serde_json::to_string_pretty(&summary)?);
    } else if json.get("functions").is_some() && json.get("version").is_some() {
        let module: BytecodeModule = serde_json::from_value(json)?;
        module.validate()?;
        println!(
            "{}",
            serde_json::to_string_pretty(&bytecode_summary(&module))?
        );
    } else {
        let manifest: PatchManifest = serde_json::from_value(json)?;
        println!("{}", serde_json::to_string_pretty(&manifest)?);
    }
    Ok(())
}

fn patch_report_summary(report: &PatchReport) -> Result<Value> {
    let mut summary = serde_json::to_value(report)?;
    let Some(plan) = &report.linker_plan else {
        return Ok(summary);
    };
    let ratio = estimated_interpreter_ratio(plan);
    let Some(object) = summary.as_object_mut() else {
        return Ok(summary);
    };
    object.insert(
        "estimated_interpreter_ratio".to_string(),
        serde_json::json!(ratio),
    );
    object.insert(
        "estimated_interpreted_functions".to_string(),
        serde_json::json!(plan.interpret.len()),
    );
    object.insert(
        "estimated_total_patchable_functions".to_string(),
        serde_json::json!(plan.interpret.len() + plan.unchanged.len()),
    );
    if let Some(warning) = interpreter_ratio_warning(plan) {
        object.insert(
            "interpreter_ratio_warning".to_string(),
            serde_json::json!(warning),
        );
    }
    Ok(summary)
}

fn bytecode_summary(module: &BytecodeModule) -> Value {
    let total_code_bytes: usize = module
        .functions
        .iter()
        .map(|function| function.code.len())
        .sum();
    let total_constants: usize = module
        .functions
        .iter()
        .map(|function| function.constants.len())
        .sum();
    let total_source_map_entries: usize = module
        .functions
        .iter()
        .map(|function| function.source_map.len())
        .sum();
    let functions_with_source_map = module
        .functions
        .iter()
        .filter(|function| !function.source_map.is_empty())
        .count();
    serde_json::json!({
        "kind": "bytecode_module",
        "version": module.version,
        "function_count": module.functions.len(),
        "total_code_bytes": total_code_bytes,
        "total_constants": total_constants,
        "total_source_map_entries": total_source_map_entries,
        "functions_with_source_map": functions_with_source_map,
        "functions": module.functions.iter().map(|function| {
            serde_json::json!({
                "name": function.name,
                "return_convention": function.return_convention,
                "param_count": function.param_count,
                "local_count": function.local_count,
                "constant_count": function.constants.len(),
                "code_bytes": function.code.len(),
                "source_map_entries": function.source_map.len(),
                "first_source_location": function.source_map.first().map(|entry| entry.source_location.as_str()),
                "uses_call_static": function.code.contains(&(OpCode::CallStatic as u8)),
                "uses_get_field": function.code.contains(&(OpCode::GetField as u8)),
                "uses_set_field": function.code.contains(&(OpCode::SetField as u8)),
            })
        }).collect::<Vec<_>>(),
    })
}

#[cfg(test)]
mod tests {
    use super::{
        bytecode_summary, estimated_interpreter_ratio, inspect_patch, patch_report_summary,
    };
    use fcb_bytecode::format::{
        BytecodeFunction, BytecodeModule, Constant, OpCode, SourceMapEntry,
    };
    use fcb_core::linker::{FunctionDecision, LinkerPlan};

    #[test]
    fn patch_report_estimates_interpreter_ratio_without_warning_at_threshold() {
        let mut report = crate::auto::PatchReport::new("bytecode", "ios", "arm64", "1.0.0+1", 1);
        report.linker_plan = Some(LinkerPlan {
            unchanged: (0..19)
                .map(|idx| FunctionDecision {
                    function_id: format!("same-{idx}"),
                    source_location: None,
                })
                .collect(),
            interpret: vec![FunctionDecision {
                function_id: "changed".to_string(),
                source_location: None,
            }],
            reject: Vec::new(),
        });

        let summary = patch_report_summary(&report).expect("summary");

        assert_eq!(summary["estimated_interpreter_ratio"], 0.05);
        assert!(summary.get("interpreter_ratio_warning").is_none());
    }

    #[test]
    fn patch_report_warns_when_interpreter_ratio_is_high() {
        let mut report = crate::auto::PatchReport::new("bytecode", "ios", "arm64", "1.0.0+1", 1);
        let plan = LinkerPlan {
            unchanged: (0..18)
                .map(|idx| FunctionDecision {
                    function_id: format!("same-{idx}"),
                    source_location: None,
                })
                .collect(),
            interpret: vec![
                FunctionDecision {
                    function_id: "changed-a".to_string(),
                    source_location: None,
                },
                FunctionDecision {
                    function_id: "changed-b".to_string(),
                    source_location: None,
                },
            ],
            reject: Vec::new(),
        };
        assert_eq!(estimated_interpreter_ratio(&plan), 0.1);
        report.linker_plan = Some(plan);

        let summary = patch_report_summary(&report).expect("summary");

        assert_eq!(summary["estimated_interpreter_ratio"], 0.1);
        assert_eq!(summary["estimated_interpreted_functions"], 2);
        assert!(summary["interpreter_ratio_warning"]
            .as_str()
            .expect("warning")
            .contains("exceeds 5.00%"));
    }

    #[test]
    fn bytecode_summary_reports_binary_capabilities() {
        let module = BytecodeModule::new(vec![BytecodeFunction {
            name: "package:app/main.dart::mainValue".to_string(),
            return_convention: "tagged".to_string(),
            param_count: 0,
            local_count: 1,
            constants: vec![Constant::String(
                "package:app/main.dart::helper".to_string(),
            )],
            code: vec![
                OpCode::LoadArg as u8,
                0,
                OpCode::GetField as u8,
                0,
                0,
                OpCode::CallStatic as u8,
                0,
                0,
                0,
                OpCode::Return as u8,
            ],
            source_map: vec![SourceMapEntry {
                bytecode_offset: 0,
                source_location: "package:app/main.dart:7:10".to_string(),
            }],
        }]);

        let summary = bytecode_summary(&module);

        assert_eq!(summary["kind"], "bytecode_module");
        assert_eq!(summary["function_count"], 1);
        assert_eq!(summary["total_source_map_entries"], 1);
        assert_eq!(summary["functions_with_source_map"], 1);
        assert_eq!(summary["functions"][0]["source_map_entries"], 1);
        assert_eq!(
            summary["functions"][0]["first_source_location"],
            "package:app/main.dart:7:10"
        );
        assert_eq!(summary["functions"][0]["uses_call_static"], true);
        assert_eq!(summary["functions"][0]["uses_get_field"], true);
        assert_eq!(summary["functions"][0]["uses_set_field"], false);
    }

    #[test]
    fn inspect_patch_accepts_binary_bytecode_module() {
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

        inspect_patch(&bytes).expect("binary bytecode inspect");
    }
}
