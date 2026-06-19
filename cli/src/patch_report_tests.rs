use super::{bytecode_payload_from_inventories, PatchReport};
use fcb_core::linker::{
    FunctionInventoryEntry, KernelInventory, RejectReason, KERNEL_INVENTORY_SCHEMA_VERSION,
};

fn function(id: &str) -> FunctionInventoryEntry {
    function_with_source(id, None)
}

fn function_with_source(
    id: &str,
    bytecode_source: Option<serde_json::Value>,
) -> FunctionInventoryEntry {
    FunctionInventoryEntry {
        function_id: id.to_string(),
        library_uri: "package:app/main.dart".to_string(),
        enclosing: String::new(),
        member_name: id.to_string(),
        signature_hash: "sig".to_string(),
        body_hash: "same-body".to_string(),
        source_location: None,
        bytecode_source,
        unsupported_reasons: Vec::new(),
    }
}

#[test]
fn automatic_bytecode_payload_reports_unsupported_kernel_node_reject() {
    let release = KernelInventory {
        schema_version: KERNEL_INVENTORY_SCHEMA_VERSION,
        functions: vec![FunctionInventoryEntry {
            body_hash: "old".to_string(),
            ..function("changed")
        }],
        classes: Vec::new(),
        top_level_fields: Vec::new(),
    };
    let patch = KernelInventory {
        functions: vec![FunctionInventoryEntry {
            body_hash: "new".to_string(),
            unsupported_reasons: vec![RejectReason::UnsupportedKernelNode],
            ..function("changed")
        }],
        ..release.clone()
    };
    let mut report = PatchReport::new("bytecode", "ios", "arm64", "1.0.0+1", 1);

    bytecode_payload_from_inventories(&release, &patch, &mut report)
        .expect_err("unsupported Kernel node should reject patch");
    let plan = report.linker_plan.expect("plan");

    assert!(matches!(
        plan.reject[0].reject_reason,
        RejectReason::UnsupportedKernelNode
    ));
}

#[test]
fn automatic_bytecode_payload_reports_escaping_capturing_closure_reject() {
    for reason in [
        RejectReason::EscapingCapturingClosure,
        RejectReason::ReturningCapturingClosure,
        RejectReason::PassingCapturingClosure,
    ] {
        let release = KernelInventory {
            schema_version: KERNEL_INVENTORY_SCHEMA_VERSION,
            functions: vec![FunctionInventoryEntry {
                body_hash: "old".to_string(),
                ..function("changed")
            }],
            classes: Vec::new(),
            top_level_fields: Vec::new(),
        };
        let patch = KernelInventory {
            functions: vec![FunctionInventoryEntry {
                body_hash: "new".to_string(),
                unsupported_reasons: vec![reason.clone()],
                ..function("changed")
            }],
            ..release.clone()
        };
        let mut report = PatchReport::new("bytecode", "ios", "arm64", "1.0.0+1", 1);

        bytecode_payload_from_inventories(&release, &patch, &mut report)
            .expect_err("escaping capturing closure should reject patch");
        let plan = report.linker_plan.expect("plan");

        assert_eq!(plan.reject[0].reject_reason, reason);
    }
}

#[test]
fn automatic_bytecode_payload_preserves_structured_runtime_rejects() {
    for reason in [
        RejectReason::AsyncAwaitUnsupported,
        RejectReason::GenericClosureUnsupported,
        RejectReason::FunctionTypeUnsupported,
        RejectReason::RecordTypeUnsupported,
    ] {
        let release = KernelInventory {
            schema_version: KERNEL_INVENTORY_SCHEMA_VERSION,
            functions: vec![FunctionInventoryEntry {
                body_hash: "old".to_string(),
                ..function("changed")
            }],
            classes: Vec::new(),
            top_level_fields: Vec::new(),
        };
        let patch = KernelInventory {
            functions: vec![FunctionInventoryEntry {
                body_hash: "new".to_string(),
                unsupported_reasons: vec![reason.clone()],
                ..function("changed")
            }],
            ..release.clone()
        };
        let mut report = PatchReport::new("bytecode", "ios", "arm64", "1.0.0+1", 1);

        bytecode_payload_from_inventories(&release, &patch, &mut report)
            .expect_err("structured runtime unsupported reason should reject patch");
        let plan = report.linker_plan.expect("plan");

        assert_eq!(plan.reject[0].reject_reason, reason);
    }
}

#[test]
fn automatic_bytecode_payload_warns_when_many_functions_are_interpreted() {
    let mut release_functions = Vec::new();
    let mut patch_functions = Vec::new();
    let source = serde_json::json!({
        "name": "changed",
        "params": [],
        "body": {"int": 1},
    });
    for idx in 0..100 {
        let id = format!("fn-{idx}");
        release_functions.push(FunctionInventoryEntry {
            body_hash: format!("old-{idx}"),
            ..function(&id)
        });
        let changed = idx < 10;
        patch_functions.push(FunctionInventoryEntry {
            body_hash: if changed {
                format!("new-{idx}")
            } else {
                format!("old-{idx}")
            },
            ..function_with_source(&id, changed.then(|| source.clone()))
        });
    }
    let release = KernelInventory {
        schema_version: KERNEL_INVENTORY_SCHEMA_VERSION,
        functions: release_functions,
        classes: Vec::new(),
        top_level_fields: Vec::new(),
    };
    let patch = KernelInventory {
        schema_version: KERNEL_INVENTORY_SCHEMA_VERSION,
        functions: patch_functions,
        classes: Vec::new(),
        top_level_fields: Vec::new(),
    };
    let mut report = PatchReport::new("bytecode", "ios", "arm64", "1.0.0+1", 1);

    let err = bytecode_payload_from_inventories(&release, &patch, &mut report)
        .expect_err("test helper should stop before Dart compiler");

    assert!(err.to_string().contains("Dart compile-from-plan"));
    assert_eq!(
        report.linker_plan.as_ref().expect("plan").interpret.len(),
        10
    );
    assert!(report
        .messages
        .iter()
        .any(|message| message.contains("estimated interpreter_ratio 10.00% exceeds 5.00%")));
}
