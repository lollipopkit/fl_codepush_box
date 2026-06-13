//! FCB bytecode compiler.
//!
//! The compiler takes @hotPatchable function descriptions and compiles them
//! into BytecodeModule payloads for distribution. In Phase C, the compiler
//! works from a simplified function description (not a full Dart AST parser)
//! that describes the function's behavior in terms the restricted bytecode
//! can express.

use crate::format::{BytecodeFunction, BytecodeModule};
use crate::opcodes::OpCode;
use fcb_core::err;

/// A simplified description of a @hotPatchable function, suitable for
/// compiling into bytecode. In a production system, this would be derived
/// from Dart Kernel AST analysis via a build transformer.
#[derive(Debug, Clone)]
pub struct PatchableFunction {
    /// Fully qualified name (e.g., "MyClass.calculatePrice").
    pub name: String,
    /// Number of positional parameters.
    pub param_count: u8,
    /// The compiled bytecode for this function body.
    pub code: Vec<u8>,
}

/// Compile a set of patchable functions into a bytecode module.
pub fn compile_module(
    app_id: &str,
    release_version: &str,
    patch_number: u32,
    functions: Vec<PatchableFunction>,
) -> Result<BytecodeModule, fcb_core::Error> {
    let mut module = BytecodeModule::new(app_id, release_version, patch_number);
    for func in functions {
        validate_bytecode(&func.code)?;
        module.functions.push(BytecodeFunction {
            name: func.name,
            param_count: func.param_count,
            local_count: func.param_count + 1, // params + return slot
            code: func.code,
        });
    }
    Ok(module)
}

/// Validate that bytecode contains only known opcodes and valid operand ranges.
fn validate_bytecode(code: &[u8]) -> Result<(), fcb_core::Error> {
    let mut pos = 0;
    while pos < code.len() {
        let op_byte = code[pos];
        let op = OpCode::from_byte(op_byte)
            .ok_or_else(|| err(format!("invalid opcode 0x{op_byte:02x} at position {pos}")))?;
        pos += 1;
        let operand_size = match op {
            OpCode::Return
            | OpCode::LoadNull
            | OpCode::LoadTrue
            | OpCode::LoadFalse
            | OpCode::ListNew
            | OpCode::MapNew
            | OpCode::LogicalNot
            | OpCode::IsInt
            | OpCode::IsDouble
            | OpCode::IsBool
            | OpCode::IsString
            | OpCode::IsNull
            | OpCode::ListLength
            | OpCode::ToString
            | OpCode::IntParse
            | OpCode::DoubleParse
            | OpCode::IntToDouble
            | OpCode::DoubleToInt
            | OpCode::MathAbs
            | OpCode::MathRound
            | OpCode::MathSqrt
            | OpCode::Negate => 0,
            OpCode::LoadLocal
            | OpCode::StoreLocal
            | OpCode::Add
            | OpCode::Subtract
            | OpCode::Multiply
            | OpCode::Divide
            | OpCode::Modulo
            | OpCode::Equal
            | OpCode::NotEqual
            | OpCode::LessThan
            | OpCode::LessEqual
            | OpCode::GreaterThan
            | OpCode::GreaterEqual
            | OpCode::ListAdd
            | OpCode::ListGet
            | OpCode::MapSet
            | OpCode::StringConcat
            | OpCode::StringInterpolate
            | OpCode::MathMin
            | OpCode::MathMax => 1,
            OpCode::LoadInt | OpCode::LoadDouble | OpCode::LoadString => 2,
            OpCode::Jump | OpCode::JumpIfFalse | OpCode::JumpIfTrue => 2,
            OpCode::CallPatchable => 3,
            OpCode::CallCore => 2,
        };
        if pos + operand_size > code.len() {
            return Err(err(format!(
                "opcode {op:?} at position {} requires {operand_size} operand bytes but only {} remain",
                pos - 1,
                code.len() - pos
            )));
        }
        pos += operand_size;
    }
    Ok(())
}

/// Helper builder for constructing bytecode instruction sequences.
pub struct BytecodeBuilder {
    code: Vec<u8>,
}

impl BytecodeBuilder {
    pub fn new() -> Self {
        Self { code: Vec::new() }
    }

    /// Emit a no-operand instruction.
    pub fn emit(&mut self, op: OpCode) -> &mut Self {
        self.code.push(op.byte());
        self
    }

    /// Emit an instruction with a single u8 operand.
    pub fn emit_u8(&mut self, op: OpCode, value: u8) -> &mut Self {
        self.code.push(op.byte());
        self.code.push(value);
        self
    }

    /// Emit an instruction with a u16 operand (big-endian).
    pub fn emit_u16(&mut self, op: OpCode, value: u16) -> &mut Self {
        self.code.push(op.byte());
        self.code.push((value >> 8) as u8);
        self.code.push((value & 0xFF) as u8);
        self
    }

    /// Emit CallPatchable with function index and arg count.
    pub fn emit_call_patchable(&mut self, func_idx: u16, arg_count: u8) -> &mut Self {
        self.code.push(OpCode::CallPatchable.byte());
        self.code.push((func_idx >> 8) as u8);
        self.code.push((func_idx & 0xFF) as u8);
        self.code.push(arg_count);
        self
    }

    /// Emit CallCore with core function index and arg count.
    pub fn emit_call_core(&mut self, core_idx: u8, arg_count: u8) -> &mut Self {
        self.code.push(OpCode::CallCore.byte());
        self.code.push(core_idx);
        self.code.push(arg_count);
        self
    }

    /// Get the current code position (for jump target calculation).
    pub fn position(&self) -> usize {
        self.code.len()
    }

    /// Patch a u16 jump target at the given position.
    pub fn patch_jump_target(&mut self, pos: usize, target: u16) {
        self.code[pos] = (target >> 8) as u8;
        self.code[pos + 1] = (target & 0xFF) as u8;
    }

    /// Build the final bytecode.
    pub fn build(self) -> Vec<u8> {
        self.code
    }
}

impl Default for BytecodeBuilder {
    fn default() -> Self {
        Self::new()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn validate_known_bytecode() {
        let mut builder = BytecodeBuilder::new();
        builder.emit_u16(OpCode::LoadInt, 0); // load int from pool[0]
        builder.emit(OpCode::Return);
        let code = builder.build();
        assert!(validate_bytecode(&code).is_ok());
    }

    #[test]
    fn validate_rejects_invalid_opcode() {
        let code = vec![0x00]; // no opcode at 0x00
        assert!(validate_bytecode(&code).is_err());
    }

    #[test]
    fn validate_rejects_truncated_operands() {
        let code = vec![OpCode::LoadInt.byte()]; // missing 2-byte operand
        assert!(validate_bytecode(&code).is_err());
    }

    #[test]
    fn compile_module_creates_valid_module() {
        let mut builder = BytecodeBuilder::new();
        builder.emit_u16(OpCode::LoadInt, 0);
        builder.emit(OpCode::Return);
        let code = builder.build();

        let funcs = vec![PatchableFunction {
            name: "calculatePrice".to_string(),
            param_count: 2,
            code,
        }];

        let module = compile_module("test-app", "1.0.0+1", 1, funcs).expect("compile module");

        assert_eq!(module.functions.len(), 1);
        assert_eq!(module.functions[0].name, "calculatePrice");
        assert_eq!(module.functions[0].param_count, 2);
    }
}
