use super::{
    validate_bytecode, AsyncKind, BytecodeFunction, BytecodeModule, Constant, DebugLocalEntry,
    OpCode, SourceMapEntry,
};

#[test]
fn validates_jump_targets_are_instruction_boundaries() {
    let function = BytecodeFunction {
        name: "bad".to_string(),
        return_convention: "tagged".to_string(),
        async_kind: AsyncKind::Sync,
        param_count: 0,
        local_count: 0,
        constants: vec![Constant::Int(1)],
        code: vec![
            OpCode::Jump as u8,
            0,
            2,
            OpCode::LoadConst as u8,
            0,
            0,
            OpCode::Return as u8,
        ],
        source_map: Vec::new(),
        debug_locals: Vec::new(),
    };

    let err = validate_bytecode(&function).expect_err("target into operand should fail");

    assert!(err.to_string().contains("non-instruction offset"));
}

#[test]
fn rejects_unexpected_module_version() {
    let bytes = format!(
        r#"{{"version":{},"functions":[]}}"#,
        super::FORMAT_VERSION + 1
    );

    let err = BytecodeModule::from_slice(bytes.as_bytes()).expect_err("version should fail");

    assert!(err
        .to_string()
        .contains("unexpected bytecode module version"));
}

#[test]
fn call_original_targets_and_missing_aot_gate() {
    use std::collections::BTreeSet;
    let module = BytecodeModule::new(vec![BytecodeFunction {
        name: "package:app/main.dart::caller".to_string(),
        return_convention: "tagged".to_string(),
        async_kind: AsyncKind::Sync,
        param_count: 0,
        local_count: 0,
        constants: vec![Constant::String(
            "package:app/main.dart::helper".to_string(),
        )],
        code: vec![OpCode::CallOriginal as u8, 0, 0, 0, OpCode::Return as u8],
        source_map: Vec::new(),
        debug_locals: Vec::new(),
    }]);

    assert_eq!(
        module.call_original_targets(),
        vec!["package:app/main.dart::helper".to_string()]
    );

    // Target absent from the AOT set -> reported as missing (fail-closed).
    let empty: BTreeSet<String> = BTreeSet::new();
    assert_eq!(
        module.missing_aot_targets(&empty),
        vec!["package:app/main.dart::helper".to_string()]
    );

    // Target present in the AOT set -> nothing missing.
    let present: BTreeSet<String> = ["package:app/main.dart::helper".to_string()]
        .into_iter()
        .collect();
    assert!(module.missing_aot_targets(&present).is_empty());
}

#[test]
fn aot_gate_covers_call_static_targets() {
    use std::collections::BTreeSet;
    // Automatic patches reference unchanged code via CallStatic (0x50), e.g.
    // counter_app's wrapper calling widgetTreeLabel. The gate must protect it.
    let module = BytecodeModule::new(vec![BytecodeFunction {
        name: "package:app/main.dart::wrapper".to_string(),
        return_convention: "tagged".to_string(),
        async_kind: AsyncKind::Sync,
        param_count: 0,
        local_count: 0,
        constants: vec![Constant::String(
            "package:app/main.dart::widgetTreeLabel".to_string(),
        )],
        code: vec![OpCode::CallStatic as u8, 0, 0, 0, OpCode::Return as u8],
        source_map: Vec::new(),
        debug_locals: Vec::new(),
    }]);

    assert_eq!(
        module.aot_referenced_targets(),
        vec!["package:app/main.dart::widgetTreeLabel".to_string()]
    );
    // call_original_targets stays narrow (CallStatic is not call_original).
    assert!(module.call_original_targets().is_empty());

    let empty: BTreeSet<String> = BTreeSet::new();
    assert_eq!(
        module.missing_aot_targets(&empty),
        vec!["package:app/main.dart::widgetTreeLabel".to_string()]
    );
    let present: BTreeSet<String> = ["package:app/main.dart::widgetTreeLabel".to_string()]
        .into_iter()
        .collect();
    assert!(module.missing_aot_targets(&present).is_empty());
}

#[test]
fn module_version_accepts_inclusive_supported_range() {
    // Invariant (compile-time): the accepted range is well-formed. When
    // FORMAT_VERSION is later bumped while MIN_SUPPORTED_MODULE_VERSION stays
    // low, older patches keep parsing.
    const _: () = assert!(super::MIN_SUPPORTED_MODULE_VERSION <= super::FORMAT_VERSION);

    let module = BytecodeModule::new(vec![BytecodeFunction {
        name: "f".to_string(),
        return_convention: "tagged".to_string(),
        async_kind: AsyncKind::Sync,
        param_count: 0,
        local_count: 0,
        constants: vec![],
        code: vec![OpCode::Return as u8],
        source_map: Vec::new(),
        debug_locals: Vec::new(),
    }]);

    // The current producer version is accepted.
    let mut current = module.clone();
    current.version = super::FORMAT_VERSION;
    current
        .validate_envelope()
        .expect("current version must be accepted");

    // A version above the supported ceiling is rejected with the range message.
    let mut too_new = module;
    too_new.version = super::FORMAT_VERSION + 1;
    let err = too_new
        .validate_envelope()
        .expect_err("above-ceiling version should fail");
    assert!(err.to_string().contains("supported range"));
}

#[test]
fn validates_call_static_function_constant() {
    let function = BytecodeFunction {
        name: "caller".to_string(),
        return_convention: "tagged".to_string(),
        async_kind: AsyncKind::Sync,
        param_count: 0,
        local_count: 0,
        constants: vec![Constant::String(
            "package:app/main.dart::helper".to_string(),
        )],
        code: vec![OpCode::CallStatic as u8, 0, 0, 0, OpCode::Return as u8],
        source_map: Vec::new(),
        debug_locals: Vec::new(),
    };

    validate_bytecode(&function).expect("string callee constant should validate");
}

#[test]
fn validates_call_dynamic_method_constant() {
    let function = BytecodeFunction {
        name: "caller".to_string(),
        return_convention: "tagged".to_string(),
        async_kind: AsyncKind::Sync,
        param_count: 1,
        local_count: 1,
        constants: vec![Constant::String("label".to_string())],
        code: vec![
            OpCode::LoadArg as u8,
            0,
            OpCode::CallDynamic as u8,
            0,
            0,
            0,
            OpCode::Return as u8,
        ],
        source_map: Vec::new(),
        debug_locals: Vec::new(),
    };

    validate_bytecode(&function).expect("string method constant should validate");
}

#[test]
fn validates_call_original_function_constant() {
    let function = BytecodeFunction {
        name: "caller".to_string(),
        return_convention: "tagged".to_string(),
        async_kind: AsyncKind::Sync,
        param_count: 0,
        local_count: 0,
        constants: vec![Constant::String("dart:core::identical".to_string())],
        code: vec![OpCode::CallOriginal as u8, 0, 0, 0, OpCode::Return as u8],
        source_map: Vec::new(),
        debug_locals: Vec::new(),
    };

    validate_bytecode(&function).expect("string original callee should validate");
}

#[test]
fn validates_call_closure_opcode() {
    let function = BytecodeFunction {
        name: "closure_caller".to_string(),
        return_convention: "tagged".to_string(),
        async_kind: AsyncKind::Sync,
        param_count: 1,
        local_count: 1,
        constants: vec![],
        code: vec![
            OpCode::LoadArg as u8,
            0,
            OpCode::CallClosure as u8,
            0,
            0,
            0,
            OpCode::Return as u8,
        ],
        source_map: Vec::new(),
        debug_locals: Vec::new(),
    };

    assert_eq!(OpCode::from_byte(0x53), Some(OpCode::CallClosure));
    assert_eq!(OpCode::CallClosure.operand_len(), 3);
    validate_bytecode(&function).expect("closure call opcode should validate");
}

#[test]
fn validates_call_closure_named_metadata() {
    let function = BytecodeFunction {
        name: "closure_caller_named".to_string(),
        return_convention: "tagged".to_string(),
        async_kind: AsyncKind::Sync,
        param_count: 1,
        local_count: 1,
        constants: vec![Constant::String(";named:path".to_string())],
        code: vec![
            OpCode::LoadArg as u8,
            0,
            OpCode::CallClosure as u8,
            0,
            1,
            1,
            OpCode::Return as u8,
        ],
        source_map: Vec::new(),
        debug_locals: Vec::new(),
    };

    validate_bytecode(&function).expect("named closure metadata should validate");
}

#[test]
fn rejects_call_closure_bad_metadata() {
    let function = BytecodeFunction {
        name: "closure_caller_bad_metadata".to_string(),
        return_convention: "tagged".to_string(),
        async_kind: AsyncKind::Sync,
        param_count: 1,
        local_count: 1,
        constants: vec![Constant::String("path".to_string())],
        code: vec![
            OpCode::LoadArg as u8,
            0,
            OpCode::CallClosure as u8,
            0,
            1,
            1,
            OpCode::Return as u8,
        ],
        source_map: Vec::new(),
        debug_locals: Vec::new(),
    };

    let err = validate_bytecode(&function).expect_err("bad metadata should fail");

    assert!(err.to_string().contains("must start with ;named:"));
}

#[test]
fn rejects_call_closure_missing_metadata_constant() {
    let function = BytecodeFunction {
        name: "closure_caller_missing_metadata".to_string(),
        return_convention: "tagged".to_string(),
        async_kind: AsyncKind::Sync,
        param_count: 1,
        local_count: 1,
        constants: vec![],
        code: vec![
            OpCode::LoadArg as u8,
            0,
            OpCode::CallClosure as u8,
            0,
            1,
            1,
            OpCode::Return as u8,
        ],
        source_map: Vec::new(),
        debug_locals: Vec::new(),
    };

    let err = validate_bytecode(&function).expect_err("missing metadata should fail");

    assert!(err.to_string().contains("missing metadata constant"));
}

#[test]
fn rejects_call_closure_named_count_greater_than_argc() {
    let function = BytecodeFunction {
        name: "closure_caller_too_many_named".to_string(),
        return_convention: "tagged".to_string(),
        async_kind: AsyncKind::Sync,
        param_count: 1,
        local_count: 1,
        constants: vec![Constant::String(";named:path,query".to_string())],
        code: vec![
            OpCode::LoadArg as u8,
            0,
            OpCode::CallClosure as u8,
            0,
            1,
            1,
            OpCode::Return as u8,
        ],
        source_map: Vec::new(),
        debug_locals: Vec::new(),
    };

    let err = validate_bytecode(&function).expect_err("too many named args should fail");

    assert!(err.to_string().contains("2 named arguments"));
}

#[test]
fn rejects_inline_named_count_greater_than_argc() {
    let function = BytecodeFunction {
        name: "named_dynamic_too_many".to_string(),
        return_convention: "tagged".to_string(),
        async_kind: AsyncKind::Sync,
        param_count: 1,
        local_count: 1,
        constants: vec![Constant::String("replace;named:path,query".to_string())],
        code: vec![
            OpCode::LoadArg as u8,
            0,
            OpCode::CallDynamic as u8,
            0,
            0,
            1,
            OpCode::Return as u8,
        ],
        source_map: Vec::new(),
        debug_locals: Vec::new(),
    };

    let err = validate_bytecode(&function).expect_err("too many named args should fail");

    assert!(err.to_string().contains("2 named arguments"));
}

#[test]
fn rejects_missing_argument_or_local_reference() {
    let load_arg = BytecodeFunction {
        name: "bad_arg".to_string(),
        return_convention: "tagged".to_string(),
        async_kind: AsyncKind::Sync,
        param_count: 0,
        local_count: 0,
        constants: vec![],
        code: vec![OpCode::LoadArg as u8, 0, OpCode::Return as u8],
        source_map: Vec::new(),
        debug_locals: Vec::new(),
    };
    let err = validate_bytecode(&load_arg).expect_err("missing arg should fail");
    assert!(err.to_string().contains("missing argument"));

    let load_local = BytecodeFunction {
        name: "bad_local".to_string(),
        return_convention: "tagged".to_string(),
        async_kind: AsyncKind::Sync,
        param_count: 0,
        local_count: 0,
        constants: vec![],
        code: vec![OpCode::LoadLocal as u8, 0, OpCode::Return as u8],
        source_map: Vec::new(),
        debug_locals: Vec::new(),
    };
    let err = validate_bytecode(&load_local).expect_err("missing local should fail");
    assert!(err.to_string().contains("missing local"));
}

#[test]
fn validates_make_closure_function_constant() {
    let function = BytecodeFunction {
        name: "closure_maker".to_string(),
        return_convention: "tagged".to_string(),
        async_kind: AsyncKind::Sync,
        param_count: 0,
        local_count: 0,
        constants: vec![Constant::String("dart:core::identical".to_string())],
        code: vec![OpCode::MakeClosure as u8, 0, 0, OpCode::Return as u8],
        source_map: Vec::new(),
        debug_locals: Vec::new(),
    };

    assert_eq!(OpCode::from_byte(0x54), Some(OpCode::MakeClosure));
    assert_eq!(OpCode::MakeClosure.operand_len(), 2);
    validate_bytecode(&function).expect("make closure opcode should validate");
}

#[test]
fn validates_new_object_constructor_constant() {
    let function = BytecodeFunction {
        name: "object_maker".to_string(),
        return_convention: "tagged".to_string(),
        async_kind: AsyncKind::Sync,
        param_count: 0,
        local_count: 0,
        constants: vec![Constant::String(
            "package:app/main.dart::class:User.".to_string(),
        )],
        code: vec![OpCode::NewObject as u8, 0, 0, 0, OpCode::Return as u8],
        source_map: Vec::new(),
        debug_locals: Vec::new(),
    };

    assert_eq!(OpCode::from_byte(0x55), Some(OpCode::NewObject));
    assert_eq!(OpCode::NewObject.operand_len(), 3);
    validate_bytecode(&function).expect("new object opcode should validate");
}

#[test]
fn validates_new_object_named_constructor_constant() {
    let function = BytecodeFunction {
        name: "named_object_maker".to_string(),
        return_convention: "tagged".to_string(),
        async_kind: AsyncKind::Sync,
        param_count: 0,
        local_count: 0,
        constants: vec![Constant::String(
            "package:app/main.dart::class:Config.;named:name,label".to_string(),
        )],
        code: vec![OpCode::NewObject as u8, 0, 0, 2, OpCode::Return as u8],
        source_map: Vec::new(),
        debug_locals: Vec::new(),
    };

    validate_bytecode(&function).expect("named new object opcode should validate");
}

#[test]
fn validates_throw_and_try_begin_opcodes() {
    let function = BytecodeFunction {
        name: "try_throw".to_string(),
        return_convention: "tagged".to_string(),
        async_kind: AsyncKind::Sync,
        param_count: 0,
        local_count: 1,
        constants: vec![Constant::String("caught".to_string())],
        code: vec![
            OpCode::TryBegin as u8,
            0,
            8,
            0,
            12,
            OpCode::LoadConst as u8,
            0,
            0,
            OpCode::Throw as u8,
            OpCode::LoadConst as u8,
            0,
            0,
            OpCode::Return as u8,
        ],
        source_map: Vec::new(),
        debug_locals: Vec::new(),
    };

    assert_eq!(OpCode::from_byte(0x60), Some(OpCode::Throw));
    assert_eq!(OpCode::Throw.operand_len(), 0);
    assert_eq!(OpCode::from_byte(0x61), Some(OpCode::TryBegin));
    assert_eq!(OpCode::TryBegin.operand_len(), 4);
    validate_bytecode(&function).expect("try/throw opcodes should validate");
}

#[test]
fn validates_v3_async_control_opcodes() {
    let function = BytecodeFunction {
        name: "async_function".to_string(),
        return_convention: "tagged".to_string(),
        async_kind: AsyncKind::AsyncFuture,
        param_count: 0,
        local_count: 0,
        constants: vec![],
        code: vec![
            OpCode::Await as u8,
            OpCode::AsyncReturn as u8,
            OpCode::Yield as u8,
            OpCode::EndFinally as u8,
            OpCode::Rethrow as u8,
            OpCode::Return as u8,
        ],
        source_map: Vec::new(),
        debug_locals: Vec::new(),
    };

    assert_eq!(OpCode::from_byte(0x62), Some(OpCode::Await));
    assert_eq!(OpCode::from_byte(0x63), Some(OpCode::AsyncReturn));
    assert_eq!(OpCode::from_byte(0x64), Some(OpCode::Yield));
    assert_eq!(OpCode::from_byte(0x66), Some(OpCode::EndFinally));
    assert_eq!(OpCode::from_byte(0x67), Some(OpCode::Rethrow));
    validate_bytecode(&function).expect("async control opcodes should validate structurally");
}

#[test]
fn validates_try_finally_targets() {
    let function = BytecodeFunction {
        name: "try_finally".to_string(),
        return_convention: "tagged".to_string(),
        async_kind: AsyncKind::Sync,
        param_count: 0,
        local_count: 0,
        constants: vec![Constant::String("done".to_string())],
        code: vec![
            OpCode::TryFinally as u8,
            0,
            8,
            0,
            12,
            OpCode::LoadConst as u8,
            0,
            0,
            OpCode::EndFinally as u8,
            OpCode::LoadConst as u8,
            0,
            0,
            OpCode::Return as u8,
        ],
        source_map: Vec::new(),
        debug_locals: Vec::new(),
    };

    assert_eq!(OpCode::from_byte(0x65), Some(OpCode::TryFinally));
    assert_eq!(OpCode::TryFinally.operand_len(), 4);
    validate_bytecode(&function).expect("try/finally opcode should validate structurally");
}

#[test]
fn rejects_try_begin_handler_inside_operand() {
    let function = BytecodeFunction {
        name: "bad_try_handler".to_string(),
        return_convention: "tagged".to_string(),
        async_kind: AsyncKind::Sync,
        param_count: 0,
        local_count: 1,
        constants: vec![Constant::String("caught".to_string())],
        code: vec![
            OpCode::TryBegin as u8,
            0,
            6,
            0,
            10,
            OpCode::LoadConst as u8,
            0,
            0,
            OpCode::Throw as u8,
            OpCode::Return as u8,
        ],
        source_map: Vec::new(),
        debug_locals: Vec::new(),
    };

    let err = validate_bytecode(&function).expect_err("handler in operand should fail");

    assert!(err.to_string().contains("non-instruction offset"));
}

#[test]
fn rejects_try_begin_end_out_of_range() {
    let function = BytecodeFunction {
        name: "bad_try_end".to_string(),
        return_convention: "tagged".to_string(),
        async_kind: AsyncKind::Sync,
        param_count: 0,
        local_count: 1,
        constants: vec![Constant::String("caught".to_string())],
        code: vec![
            OpCode::TryBegin as u8,
            0,
            8,
            0,
            99,
            OpCode::LoadConst as u8,
            0,
            0,
            OpCode::Throw as u8,
            OpCode::Return as u8,
        ],
        source_map: Vec::new(),
        debug_locals: Vec::new(),
    };

    let err = validate_bytecode(&function).expect_err("end past code should fail");

    assert!(err.to_string().contains("out-of-range end offset"));
}

#[test]
fn rejects_call_static_non_string_constant() {
    let function = BytecodeFunction {
        name: "caller".to_string(),
        return_convention: "tagged".to_string(),
        async_kind: AsyncKind::Sync,
        param_count: 0,
        local_count: 0,
        constants: vec![Constant::Int(7)],
        code: vec![OpCode::CallStatic as u8, 0, 0, 0, OpCode::Return as u8],
        source_map: Vec::new(),
        debug_locals: Vec::new(),
    };

    let err = validate_bytecode(&function).expect_err("non-string callee should fail");

    assert!(err.to_string().contains("CallStatic"));
}

#[test]
fn validates_field_opcode_string_constant() {
    let function = BytecodeFunction {
        name: "field".to_string(),
        return_convention: "tagged".to_string(),
        async_kind: AsyncKind::Sync,
        param_count: 1,
        local_count: 1,
        constants: vec![Constant::String("price".to_string())],
        code: vec![
            OpCode::LoadArg as u8,
            0,
            OpCode::GetField as u8,
            0,
            0,
            OpCode::Return as u8,
        ],
        source_map: Vec::new(),
        debug_locals: Vec::new(),
    };

    validate_bytecode(&function).expect("field name constant should validate");
}

#[test]
fn validates_type_opcode_string_constant() {
    let function = BytecodeFunction {
        name: "type_check".to_string(),
        return_convention: "tagged".to_string(),
        async_kind: AsyncKind::Sync,
        param_count: 1,
        local_count: 1,
        constants: vec![Constant::String("String".to_string())],
        code: vec![
            OpCode::LoadArg as u8,
            0,
            OpCode::AsType as u8,
            0,
            0,
            OpCode::Return as u8,
        ],
        source_map: Vec::new(),
        debug_locals: Vec::new(),
    };

    validate_bytecode(&function).expect("type name constant should validate");
}

#[test]
fn rejects_field_opcode_non_string_constant() {
    let function = BytecodeFunction {
        name: "field".to_string(),
        return_convention: "tagged".to_string(),
        async_kind: AsyncKind::Sync,
        param_count: 1,
        local_count: 1,
        constants: vec![Constant::Int(7)],
        code: vec![
            OpCode::LoadArg as u8,
            0,
            OpCode::SetField as u8,
            0,
            0,
            OpCode::Return as u8,
        ],
        source_map: Vec::new(),
        debug_locals: Vec::new(),
    };

    let err = validate_bytecode(&function).expect_err("non-string field should fail");

    assert!(err.to_string().contains("SetField"));
}

#[test]
fn rejects_type_opcode_non_string_constant() {
    let function = BytecodeFunction {
        name: "type_check".to_string(),
        return_convention: "tagged".to_string(),
        async_kind: AsyncKind::Sync,
        param_count: 1,
        local_count: 1,
        constants: vec![Constant::Int(7)],
        code: vec![
            OpCode::LoadArg as u8,
            0,
            OpCode::IsType as u8,
            0,
            0,
            OpCode::Return as u8,
        ],
        source_map: Vec::new(),
        debug_locals: Vec::new(),
    };

    let err = validate_bytecode(&function).expect_err("non-string type should fail");

    assert!(err.to_string().contains("IsType"));
}

#[test]
fn binary_module_round_trips_and_validates() {
    let module = BytecodeModule::new(vec![BytecodeFunction {
        name: "package:app/main.dart::mainValue".to_string(),
        return_convention: "tagged".to_string(),
        async_kind: AsyncKind::Sync,
        param_count: 0,
        local_count: 1,
        constants: vec![
            Constant::Int(7),
            Constant::Double(1.5),
            Constant::Bool(true),
            Constant::String("package:app/main.dart::helper".to_string()),
            Constant::Null,
        ],
        code: vec![
            OpCode::LoadConst as u8,
            0,
            0,
            OpCode::CallStatic as u8,
            0,
            3,
            0,
            OpCode::Return as u8,
        ],
        source_map: vec![
            SourceMapEntry {
                bytecode_offset: 0,
                source_location: "lib/main.dart:9:10".to_string(),
            },
            SourceMapEntry {
                bytecode_offset: 3,
                source_location: "lib/main.dart:9:17".to_string(),
            },
        ],
        debug_locals: vec![DebugLocalEntry {
            slot: 0,
            name: "cachedTotal".to_string(),
        }],
    }]);

    let encoded = module.to_binary_vec().expect("encode binary module");
    assert!(encoded.starts_with(super::BINARY_MAGIC));

    let decoded = BytecodeModule::from_slice(&encoded).expect("decode binary module");

    assert_eq!(decoded, module);
}

#[test]
fn binary_v1_without_debug_locals_is_still_accepted() {
    let mut encoded = Vec::new();
    encoded.extend_from_slice(super::BINARY_MAGIC);
    encoded.extend_from_slice(&1u32.to_be_bytes());
    encoded.extend_from_slice(&1u16.to_be_bytes());
    super::write_string(
        &mut encoded,
        "package:app/main.dart::legacy",
        "function name",
    )
    .expect("write function name");
    encoded.push(0); // tagged return convention
    encoded.push(0); // param_count
    encoded.push(0); // local_count
    encoded.extend_from_slice(&0u16.to_be_bytes()); // constants
    encoded.extend_from_slice(&1u32.to_be_bytes()); // code length
    encoded.push(OpCode::Return as u8);
    encoded.extend_from_slice(&0u16.to_be_bytes()); // source_map

    let decoded = BytecodeModule::from_slice(&encoded).expect("decode v1 module");

    assert_eq!(decoded.version, 1);
    assert!(decoded.functions[0].debug_locals.is_empty());
}

#[test]
fn binary_v2_round_trips_debug_locals() {
    let module = BytecodeModule::new(vec![BytecodeFunction {
        name: "package:app/main.dart::withLocals".to_string(),
        return_convention: "tagged".to_string(),
        async_kind: AsyncKind::Sync,
        param_count: 1,
        local_count: 1,
        constants: vec![],
        code: vec![OpCode::LoadArg as u8, 0, OpCode::Return as u8],
        source_map: Vec::new(),
        debug_locals: vec![DebugLocalEntry {
            slot: 0,
            name: "input".to_string(),
        }],
    }]);

    let encoded = module.to_binary_vec().expect("encode v2 module");
    let decoded = BytecodeModule::from_slice(&encoded).expect("decode v2 module");

    assert_eq!(decoded.version, super::FORMAT_VERSION);
    assert_eq!(
        decoded.functions[0].debug_locals,
        module.functions[0].debug_locals
    );
}

#[test]
fn binary_writer_always_emits_current_format_version() {
    let mut module = BytecodeModule::new(vec![BytecodeFunction {
        name: "package:app/main.dart::current".to_string(),
        return_convention: "tagged".to_string(),
        async_kind: AsyncKind::Sync,
        param_count: 0,
        local_count: 0,
        constants: vec![],
        code: vec![OpCode::Return as u8],
        source_map: Vec::new(),
        debug_locals: Vec::new(),
    }]);
    module.version = super::MIN_SUPPORTED_MODULE_VERSION;

    let encoded = module.to_binary_vec().expect("encode binary module");
    let decoded = BytecodeModule::from_slice(&encoded).expect("decode binary module");

    assert_eq!(decoded.version, super::FORMAT_VERSION);
}

#[test]
fn rejects_out_of_range_source_map_offset() {
    let module = BytecodeModule::new(vec![BytecodeFunction {
        name: "mapped".to_string(),
        return_convention: "tagged".to_string(),
        async_kind: AsyncKind::Sync,
        param_count: 0,
        local_count: 0,
        constants: vec![],
        code: vec![OpCode::Return as u8],
        source_map: vec![SourceMapEntry {
            bytecode_offset: 1,
            source_location: "lib/main.dart:1:1".to_string(),
        }],
        debug_locals: Vec::new(),
    }]);

    let err = module.validate().expect_err("offset past code should fail");

    assert!(err.to_string().contains("out-of-range bytecode offset"));
}

#[test]
fn rejects_empty_source_map_location() {
    let module = BytecodeModule::new(vec![BytecodeFunction {
        name: "mapped".to_string(),
        return_convention: "tagged".to_string(),
        async_kind: AsyncKind::Sync,
        param_count: 0,
        local_count: 0,
        constants: vec![],
        code: vec![OpCode::Return as u8],
        source_map: vec![SourceMapEntry {
            bytecode_offset: 0,
            source_location: "   ".to_string(),
        }],
        debug_locals: Vec::new(),
    }]);

    let err = module
        .validate()
        .expect_err("blank source location should fail");

    assert!(err.to_string().contains("empty source_location"));
}
