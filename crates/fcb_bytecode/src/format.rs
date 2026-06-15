use fcb_core::{err, Result};
use serde::{Deserialize, Serialize};
use std::collections::BTreeSet;

pub const FORMAT_VERSION: u32 = 1;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
#[repr(u8)]
pub enum OpCode {
    LoadConst = 0x01,
    LoadArg = 0x02,
    LoadLocal = 0x03,
    StoreLocal = 0x04,
    Add = 0x10,
    Sub = 0x11,
    Mul = 0x12,
    Div = 0x13,
    Greater = 0x20,
    Equal = 0x21,
    Jump = 0x30,
    JumpIfFalse = 0x31,
    JumpIfTrue = 0x32,
    MakeList = 0x40,
    MakeMap = 0x41,
    Return = 0xff,
}

impl OpCode {
    pub fn from_byte(byte: u8) -> Option<Self> {
        Some(match byte {
            0x01 => Self::LoadConst,
            0x02 => Self::LoadArg,
            0x03 => Self::LoadLocal,
            0x04 => Self::StoreLocal,
            0x10 => Self::Add,
            0x11 => Self::Sub,
            0x12 => Self::Mul,
            0x13 => Self::Div,
            0x20 => Self::Greater,
            0x21 => Self::Equal,
            0x30 => Self::Jump,
            0x31 => Self::JumpIfFalse,
            0x32 => Self::JumpIfTrue,
            0x40 => Self::MakeList,
            0x41 => Self::MakeMap,
            0xff => Self::Return,
            _ => return None,
        })
    }

    pub fn operand_len(self) -> usize {
        match self {
            Self::LoadConst
            | Self::Jump
            | Self::JumpIfFalse
            | Self::JumpIfTrue
            | Self::MakeList
            | Self::MakeMap => 2,
            Self::LoadArg | Self::LoadLocal | Self::StoreLocal => 1,
            Self::Add
            | Self::Sub
            | Self::Mul
            | Self::Div
            | Self::Greater
            | Self::Equal
            | Self::Return => 0,
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
#[serde(tag = "type", content = "value")]
pub enum Constant {
    Int(i64),
    Double(f64),
    Bool(bool),
    String(String),
    Null,
}

fn default_return_convention() -> String {
    "tagged".to_string()
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct BytecodeFunction {
    pub name: String,
    #[serde(default = "default_return_convention")]
    pub return_convention: String,
    pub param_count: u8,
    pub local_count: u8,
    pub constants: Vec<Constant>,
    pub code: Vec<u8>,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct BytecodeModule {
    pub version: u32,
    pub functions: Vec<BytecodeFunction>,
}

impl BytecodeModule {
    pub fn new(functions: Vec<BytecodeFunction>) -> Self {
        Self {
            version: FORMAT_VERSION,
            functions,
        }
    }

    pub fn from_slice(bytes: &[u8]) -> Result<Self> {
        let module: Self = serde_json::from_slice(bytes)?;
        module.validate()?;
        Ok(module)
    }

    pub fn to_vec(&self) -> Result<Vec<u8>> {
        self.validate()?;
        Ok(serde_json::to_vec(self)?)
    }

    pub fn validate(&self) -> Result<()> {
        if self.version != FORMAT_VERSION {
            return Err(err(format!(
                "unexpected bytecode module version {}, expected {}",
                self.version, FORMAT_VERSION
            )));
        }
        if self.functions.is_empty() {
            return Err(err("bytecode module must contain at least one function"));
        }
        let mut names = BTreeSet::new();
        for function in &self.functions {
            if function.name.trim().is_empty() {
                return Err(err("bytecode function name must not be empty"));
            }
            if function.return_convention != "tagged"
                && function.return_convention != "unboxed_int64"
            {
                return Err(err(format!(
                    "unsupported return_convention {} for function {}",
                    function.return_convention, function.name
                )));
            }
            if !names.insert(function.name.clone()) {
                return Err(err(format!(
                    "duplicate bytecode function {}",
                    function.name
                )));
            }
            validate_bytecode(function)?;
        }
        Ok(())
    }
}

#[derive(Debug, Default)]
pub struct ConstantPool {
    constants: Vec<Constant>,
}

impl ConstantPool {
    pub fn push(&mut self, constant: Constant) -> Result<u16> {
        let idx = self.constants.len();
        self.constants.push(constant);
        u16::try_from(idx).map_err(|_| err("bytecode constant pool exceeds u16 index space"))
    }

    pub fn into_vec(self) -> Vec<Constant> {
        self.constants
    }
}

pub fn validate_bytecode(function: &BytecodeFunction) -> Result<()> {
    if function.local_count < function.param_count {
        return Err(err(format!(
            "function {} local_count {} is smaller than param_count {}",
            function.name, function.local_count, function.param_count
        )));
    }

    let mut pos = 0usize;
    let mut starts = BTreeSet::new();
    while pos < function.code.len() {
        starts.insert(pos);
        let opcode_byte = function.code[pos];
        let Some(opcode) = OpCode::from_byte(opcode_byte) else {
            return Err(err(format!(
                "invalid opcode 0x{opcode_byte:02x} at offset {pos}"
            )));
        };
        let operand_start = pos + 1;
        let next = operand_start + opcode.operand_len();
        if next > function.code.len() {
            return Err(err(format!(
                "opcode {:?} at offset {} requires {} operand bytes",
                opcode,
                pos,
                opcode.operand_len()
            )));
        }
        if opcode == OpCode::LoadConst {
            let idx = read_u16(&function.code, operand_start) as usize;
            if idx >= function.constants.len() {
                return Err(err(format!(
                    "LoadConst at offset {pos} references missing constant {idx}"
                )));
            }
        }
        pos = next;
    }
    if function.code.is_empty() {
        return Err(err(format!(
            "function {} has empty bytecode",
            function.name
        )));
    }

    pos = 0;
    while pos < function.code.len() {
        let opcode = OpCode::from_byte(function.code[pos]).expect("validated opcode");
        let operand_start = pos + 1;
        if matches!(
            opcode,
            OpCode::Jump | OpCode::JumpIfFalse | OpCode::JumpIfTrue
        ) {
            let target = read_u16(&function.code, operand_start) as usize;
            if target >= function.code.len() {
                return Err(err(format!(
                    "{:?} at offset {} targets out-of-range offset {}",
                    opcode, pos, target
                )));
            }
            if !starts.contains(&target) {
                return Err(err(format!(
                    "{:?} at offset {} targets non-instruction offset {}",
                    opcode, pos, target
                )));
            }
        }
        pos = operand_start + opcode.operand_len();
    }
    Ok(())
}

fn read_u16(code: &[u8], pos: usize) -> u16 {
    u16::from_be_bytes([code[pos], code[pos + 1]])
}

#[cfg(test)]
mod tests {
    use super::{validate_bytecode, BytecodeFunction, BytecodeModule, Constant, OpCode};

    #[test]
    fn validates_jump_targets_are_instruction_boundaries() {
        let function = BytecodeFunction {
            name: "bad".to_string(),
            return_convention: "tagged".to_string(),
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
        };

        let err = validate_bytecode(&function).expect_err("target into operand should fail");

        assert!(err.to_string().contains("non-instruction offset"));
    }

    #[test]
    fn rejects_unexpected_module_version() {
        let bytes = br#"{"version":2,"functions":[]}"#;

        let err = BytecodeModule::from_slice(bytes).expect_err("version should fail");

        assert!(err
            .to_string()
            .contains("unexpected bytecode module version"));
    }
}
