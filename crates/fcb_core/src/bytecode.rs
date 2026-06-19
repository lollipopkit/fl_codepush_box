use crate::{err, Result};
use serde::{Deserialize, Serialize};
use std::collections::BTreeSet;

/// Highest bytecode-module container version this build can parse/produce.
pub const FORMAT_VERSION: u32 = 2;
/// Lowest container version this build still accepts. The reader accepts the
/// inclusive range `MIN_SUPPORTED_MODULE_VERSION..=FORMAT_VERSION` so that a
/// device built today keeps accepting older patches after FORMAT_VERSION is
/// bumped — only a genuinely newer container (> FORMAT_VERSION) is rejected,
/// and that degrades gracefully (patch skipped, baseline keeps running) rather
/// than forcing a store release for every additive format change.
pub const MIN_SUPPORTED_MODULE_VERSION: u32 = 1;
pub const BINARY_MAGIC: &[u8; 4] = b"FCBM";

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
    StringConcat = 0x42,
    GetField = 0x43,
    SetField = 0x44,
    IsType = 0x45,
    AsType = 0x46,
    CallStatic = 0x50,
    CallDynamic = 0x51,
    CallOriginal = 0x52,
    CallClosure = 0x53,
    MakeClosure = 0x54,
    NewObject = 0x55,
    Throw = 0x60,
    TryBegin = 0x61,
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
            0x42 => Self::StringConcat,
            0x43 => Self::GetField,
            0x44 => Self::SetField,
            0x45 => Self::IsType,
            0x46 => Self::AsType,
            0x50 => Self::CallStatic,
            0x51 => Self::CallDynamic,
            0x52 => Self::CallOriginal,
            0x53 => Self::CallClosure,
            0x54 => Self::MakeClosure,
            0x55 => Self::NewObject,
            0x60 => Self::Throw,
            0x61 => Self::TryBegin,
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
            | Self::MakeMap
            | Self::StringConcat
            | Self::GetField
            | Self::SetField
            | Self::IsType
            | Self::AsType
            | Self::MakeClosure => 2,
            Self::CallStatic
            | Self::CallDynamic
            | Self::CallOriginal
            | Self::CallClosure
            | Self::NewObject => 3,
            Self::TryBegin => 4,
            Self::LoadArg | Self::LoadLocal | Self::StoreLocal => 1,
            Self::Add
            | Self::Sub
            | Self::Mul
            | Self::Div
            | Self::Greater
            | Self::Equal
            | Self::Throw
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
    #[serde(default, skip_serializing_if = "Vec::is_empty")]
    pub source_map: Vec<SourceMapEntry>,
    #[serde(default, skip_serializing_if = "Vec::is_empty")]
    pub debug_locals: Vec<DebugLocalEntry>,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub struct SourceMapEntry {
    pub bytecode_offset: u32,
    pub source_location: String,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub struct DebugLocalEntry {
    pub slot: u16,
    pub name: String,
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
        if bytes.starts_with(BINARY_MAGIC) {
            return Self::from_binary(bytes);
        }
        let module: Self = serde_json::from_slice(bytes)?;
        module.validate()?;
        Ok(module)
    }

    pub fn from_slice_envelope(bytes: &[u8]) -> Result<Self> {
        if bytes.starts_with(BINARY_MAGIC) {
            return Self::from_binary_envelope(bytes);
        }
        let module: Self = serde_json::from_slice(bytes)?;
        module.validate_envelope()?;
        Ok(module)
    }

    pub fn from_binary(bytes: &[u8]) -> Result<Self> {
        let module = Self::read_binary(bytes)?;
        module.validate()?;
        Ok(module)
    }

    pub fn from_binary_envelope(bytes: &[u8]) -> Result<Self> {
        let module = Self::read_binary(bytes)?;
        module.validate_envelope()?;
        Ok(module)
    }

    fn read_binary(bytes: &[u8]) -> Result<Self> {
        let mut reader = BinaryReader::new(bytes);
        reader.expect_magic(BINARY_MAGIC)?;
        let version = reader.u32()?;
        let function_count = reader.u16()? as usize;
        let mut functions = Vec::with_capacity(function_count);
        for _ in 0..function_count {
            let name = reader.string()?;
            let return_convention = match reader.u8()? {
                0 => "tagged".to_string(),
                1 => "unboxed_int64".to_string(),
                other => return Err(err(format!("unsupported binary return convention {other}"))),
            };
            let param_count = reader.u8()?;
            let local_count = reader.u8()?;
            let constant_count = reader.u16()? as usize;
            let mut constants = Vec::with_capacity(constant_count);
            for _ in 0..constant_count {
                constants.push(reader.constant()?);
            }
            let code_len = reader.u32()? as usize;
            let code = reader.bytes(code_len)?.to_vec();
            let source_map_count = reader.u16()? as usize;
            let mut source_map = Vec::with_capacity(source_map_count);
            for _ in 0..source_map_count {
                source_map.push(SourceMapEntry {
                    bytecode_offset: reader.u32()?,
                    source_location: reader.string()?,
                });
            }
            let mut debug_locals = Vec::new();
            if version >= 2 {
                let debug_local_count = reader.u16()? as usize;
                debug_locals = Vec::with_capacity(debug_local_count);
                for _ in 0..debug_local_count {
                    debug_locals.push(DebugLocalEntry {
                        slot: reader.u16()?,
                        name: reader.string()?,
                    });
                }
            }
            functions.push(BytecodeFunction {
                name,
                return_convention,
                param_count,
                local_count,
                constants,
                code,
                source_map,
                debug_locals,
            });
        }
        reader.finish()?;
        Ok(Self { version, functions })
    }

    pub fn to_vec(&self) -> Result<Vec<u8>> {
        self.validate()?;
        Ok(serde_json::to_vec(self)?)
    }

    pub fn to_binary_vec(&self) -> Result<Vec<u8>> {
        self.validate()?;
        let mut out = Vec::new();
        out.extend_from_slice(BINARY_MAGIC);
        out.extend_from_slice(&FORMAT_VERSION.to_be_bytes());
        write_u16(&mut out, self.functions.len(), "function count")?;
        for function in &self.functions {
            write_string(&mut out, &function.name, "function name")?;
            out.push(match function.return_convention.as_str() {
                "tagged" => 0,
                "unboxed_int64" => 1,
                _ => {
                    return Err(err(format!(
                        "unsupported return_convention {} for function {}",
                        function.return_convention, function.name
                    )))
                }
            });
            out.push(function.param_count);
            out.push(function.local_count);
            write_u16(&mut out, function.constants.len(), "constant count")?;
            for constant in &function.constants {
                write_constant(&mut out, constant)?;
            }
            write_u32(&mut out, function.code.len(), "code length")?;
            out.extend_from_slice(&function.code);
            write_u16(&mut out, function.source_map.len(), "source map count")?;
            for entry in &function.source_map {
                out.extend_from_slice(&entry.bytecode_offset.to_be_bytes());
                write_string(&mut out, &entry.source_location, "source location")?;
            }
            write_u16(&mut out, function.debug_locals.len(), "debug locals count")?;
            for entry in &function.debug_locals {
                out.extend_from_slice(&entry.slot.to_be_bytes());
                write_string(&mut out, &entry.name, "debug local name")?;
            }
        }
        Ok(out)
    }

    pub fn validate(&self) -> Result<()> {
        self.validate_envelope()?;
        for function in &self.functions {
            validate_bytecode(function)?;
        }
        Ok(())
    }

    pub fn validate_envelope(&self) -> Result<()> {
        if self.version < MIN_SUPPORTED_MODULE_VERSION || self.version > FORMAT_VERSION {
            return Err(err(format!(
                "unexpected bytecode module version {}, supported range {}..={}",
                self.version, MIN_SUPPORTED_MODULE_VERSION, FORMAT_VERSION
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
            if function.local_count < function.param_count {
                return Err(err(format!(
                    "function {} local_count {} is smaller than param_count {}",
                    function.name, function.local_count, function.param_count
                )));
            }
            if function.code.is_empty() {
                return Err(err(format!(
                    "function {} has empty bytecode",
                    function.name
                )));
            }
            for entry in &function.source_map {
                if entry.bytecode_offset as usize >= function.code.len() {
                    return Err(err(format!(
                        "source_map for function {} targets out-of-range bytecode offset {}",
                        function.name, entry.bytecode_offset
                    )));
                }
                if entry.source_location.trim().is_empty() {
                    return Err(err(format!(
                        "source_map for function {} has empty source_location",
                        function.name
                    )));
                }
            }
            for entry in &function.debug_locals {
                if entry.slot as usize
                    >= function.param_count as usize + function.local_count as usize
                {
                    return Err(err(format!(
                        "debug_locals for function {} targets out-of-range slot {}",
                        function.name, entry.slot
                    )));
                }
                if entry.name.trim().is_empty() {
                    return Err(err(format!(
                        "debug_locals for function {} has empty name",
                        function.name
                    )));
                }
            }
        }
        Ok(())
    }

    /// Function ids this module invokes via `CallOriginal` (the original AOT
    /// implementation). Subset of [`Self::aot_referenced_targets`]; kept for
    /// callers that specifically care about the call_original set.
    pub fn call_original_targets(&self) -> Vec<String> {
        self.targets_for(&[OpCode::CallOriginal])
    }

    /// Qualified function ids this module dispatches to **by name in the AOT
    /// snapshot** and therefore require a real AOT entry point: `CallStatic` and
    /// `CallOriginal` both resolve their target via `DartEntry::InvokeFunction`,
    /// so a tree-shaken/inlined target crashes at runtime. ADR-#2.
    ///
    /// `NewObject`/`MakeClosure` are intentionally excluded for now: constructors
    /// and tear-offs are frequently inlined (no standalone entry even when valid),
    /// which would cause false rejects until the patch-friendly build mode lands.
    pub fn aot_referenced_targets(&self) -> Vec<String> {
        self.targets_for(&[OpCode::CallStatic, OpCode::CallOriginal])
    }

    /// Collect the string constant referenced by the first operand (a u16
    /// constant index) of each occurrence of any opcode in `opcodes`.
    fn targets_for(&self, opcodes: &[OpCode]) -> Vec<String> {
        let mut targets = BTreeSet::new();
        for function in &self.functions {
            let mut pos = 0usize;
            while pos < function.code.len() {
                let Some(opcode) = OpCode::from_byte(function.code[pos]) else {
                    break;
                };
                let operand_start = pos + 1;
                if opcodes.contains(&opcode) && operand_start + 2 <= function.code.len() {
                    let idx = read_u16(&function.code, operand_start) as usize;
                    if let Some(Constant::String(target)) = function.constants.get(idx) {
                        targets.insert(target.clone());
                    }
                }
                pos = operand_start + opcode.operand_len();
            }
        }
        targets.into_iter().collect()
    }

    /// AOT-referenced targets (see [`Self::aot_referenced_targets`]) NOT present
    /// in `aot_present` (the set of function ids that survived AOT with a real
    /// entry point). Non-empty means the patch would dispatch into a function the
    /// AOT snapshot no longer contains, and must be rejected at build time rather
    /// than crashing at runtime.
    pub fn missing_aot_targets(&self, aot_present: &BTreeSet<String>) -> Vec<String> {
        self.aot_referenced_targets()
            .into_iter()
            .filter(|target| !aot_present.contains(target))
            .collect()
    }
}

#[derive(Debug, Default)]
pub struct ConstantPool {
    constants: Vec<Constant>,
}

impl ConstantPool {
    pub fn push(&mut self, constant: Constant) -> Result<u16> {
        if let Some(idx) = self
            .constants
            .iter()
            .position(|existing| existing == &constant)
        {
            return u16::try_from(idx)
                .map_err(|_| err("bytecode constant pool exceeds u16 index space"));
        }
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
        } else if opcode == OpCode::LoadArg {
            let idx = function.code[operand_start] as usize;
            if idx >= function.param_count as usize {
                return Err(err(format!(
                    "LoadArg at offset {pos} references missing argument {idx}"
                )));
            }
        } else if opcode == OpCode::LoadLocal || opcode == OpCode::StoreLocal {
            let idx = function.code[operand_start] as usize;
            if idx >= function.local_count as usize {
                return Err(err(format!(
                    "{opcode:?} at offset {pos} references missing local {idx}"
                )));
            }
        } else if opcode == OpCode::CallClosure {
            let metadata_idx = read_u16(&function.code, operand_start);
            if metadata_idx != 0 {
                let idx = metadata_idx as usize - 1;
                let Some(Constant::String(value)) = function.constants.get(idx) else {
                    return Err(err(format!(
                        "CallClosure at offset {pos} references missing metadata constant {idx}"
                    )));
                };
                if !value.starts_with(";named:") {
                    return Err(err(format!(
                        "CallClosure metadata at offset {pos} must start with ;named:"
                    )));
                }
                let argc = function.code[operand_start + 2] as usize;
                let named_count = count_named_arguments(value, true);
                if named_count > argc {
                    return Err(err(format!(
                        "CallClosure at offset {pos} has {named_count} named arguments but argc is {argc}"
                    )));
                }
            }
        } else if matches!(
            opcode,
            OpCode::GetField
                | OpCode::SetField
                | OpCode::IsType
                | OpCode::AsType
                | OpCode::CallStatic
                | OpCode::CallDynamic
                | OpCode::CallOriginal
                | OpCode::MakeClosure
                | OpCode::NewObject
        ) {
            let idx = read_u16(&function.code, operand_start) as usize;
            if !matches!(function.constants.get(idx), Some(Constant::String(_))) {
                return Err(err(format!(
                    "{opcode:?} at offset {pos} references missing string constant {idx}"
                )));
            }
            if matches!(
                opcode,
                OpCode::CallDynamic | OpCode::CallOriginal | OpCode::NewObject
            ) {
                if let Some(Constant::String(value)) = function.constants.get(idx) {
                    let argc = function.code[operand_start + 2] as usize;
                    let named_count = count_named_arguments(value, false);
                    if named_count > argc {
                        return Err(err(format!(
                            "{opcode:?} at offset {pos} has {named_count} named arguments but argc is {argc}"
                        )));
                    }
                }
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
            OpCode::Jump | OpCode::JumpIfFalse | OpCode::JumpIfTrue | OpCode::TryBegin
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
            if opcode == OpCode::TryBegin {
                let end = read_u16(&function.code, operand_start + 2) as usize;
                if end >= function.code.len() {
                    return Err(err(format!(
                        "TryBegin at offset {} has out-of-range end offset {}",
                        pos, end
                    )));
                }
                if !starts.contains(&end) {
                    return Err(err(format!(
                        "TryBegin at offset {} has non-instruction end offset {}",
                        pos, end
                    )));
                }
                if target <= pos || target >= end {
                    return Err(err(format!(
                        "TryBegin at offset {} requires current < handler < end",
                        pos
                    )));
                }
            }
        }
        pos = operand_start + opcode.operand_len();
    }
    Ok(())
}

fn read_u16(code: &[u8], pos: usize) -> u16 {
    u16::from_be_bytes([code[pos], code[pos + 1]])
}

fn count_named_arguments(metadata: &str, require_prefix: bool) -> usize {
    const MARKER: &str = ";named:";
    let Some(marker_start) = metadata.find(MARKER) else {
        return 0;
    };
    if require_prefix && marker_start != 0 {
        return 0;
    }
    metadata[marker_start + MARKER.len()..]
        .split(',')
        .filter(|name| !name.is_empty())
        .count()
}

fn write_u16(out: &mut Vec<u8>, value: usize, label: &str) -> Result<()> {
    let value = u16::try_from(value).map_err(|_| err(format!("{label} exceeds u16 range")))?;
    out.extend_from_slice(&value.to_be_bytes());
    Ok(())
}

fn write_u32(out: &mut Vec<u8>, value: usize, label: &str) -> Result<()> {
    let value = u32::try_from(value).map_err(|_| err(format!("{label} exceeds u32 range")))?;
    out.extend_from_slice(&value.to_be_bytes());
    Ok(())
}

fn write_string(out: &mut Vec<u8>, value: &str, label: &str) -> Result<()> {
    write_u16(out, value.len(), label)?;
    out.extend_from_slice(value.as_bytes());
    Ok(())
}

fn write_constant(out: &mut Vec<u8>, constant: &Constant) -> Result<()> {
    match constant {
        Constant::Null => out.push(0),
        Constant::Int(value) => {
            out.push(1);
            out.extend_from_slice(&value.to_be_bytes());
        }
        Constant::Double(value) => {
            out.push(2);
            out.extend_from_slice(&value.to_bits().to_be_bytes());
        }
        Constant::Bool(value) => {
            out.push(3);
            out.push(u8::from(*value));
        }
        Constant::String(value) => {
            out.push(4);
            write_string(out, value, "string constant")?;
        }
    }
    Ok(())
}

struct BinaryReader<'a> {
    bytes: &'a [u8],
    pos: usize,
}

impl<'a> BinaryReader<'a> {
    fn new(bytes: &'a [u8]) -> Self {
        Self { bytes, pos: 0 }
    }

    fn expect_magic(&mut self, magic: &[u8]) -> Result<()> {
        let actual = self.bytes(magic.len())?;
        if actual != magic {
            return Err(err("invalid FCB bytecode binary magic"));
        }
        Ok(())
    }

    fn u8(&mut self) -> Result<u8> {
        Ok(*self
            .bytes(1)?
            .first()
            .expect("BinaryReader::bytes returned one byte"))
    }

    fn u16(&mut self) -> Result<u16> {
        let bytes = self.bytes(2)?;
        Ok(u16::from_be_bytes([bytes[0], bytes[1]]))
    }

    fn u32(&mut self) -> Result<u32> {
        let bytes = self.bytes(4)?;
        Ok(u32::from_be_bytes([bytes[0], bytes[1], bytes[2], bytes[3]]))
    }

    fn i64(&mut self) -> Result<i64> {
        let bytes = self.bytes(8)?;
        Ok(i64::from_be_bytes(bytes.try_into().expect("8 byte slice")))
    }

    fn f64(&mut self) -> Result<f64> {
        let bytes = self.bytes(8)?;
        Ok(f64::from_bits(u64::from_be_bytes(
            bytes.try_into().expect("8 byte slice"),
        )))
    }

    fn string(&mut self) -> Result<String> {
        let len = self.u16()? as usize;
        let bytes = self.bytes(len)?;
        String::from_utf8(bytes.to_vec()).map_err(|e| err(e.to_string()))
    }

    fn constant(&mut self) -> Result<Constant> {
        Ok(match self.u8()? {
            0 => Constant::Null,
            1 => Constant::Int(self.i64()?),
            2 => Constant::Double(self.f64()?),
            3 => Constant::Bool(match self.u8()? {
                0 => false,
                1 => true,
                other => return Err(err(format!("invalid bool constant byte {other}"))),
            }),
            4 => Constant::String(self.string()?),
            other => return Err(err(format!("unsupported binary constant tag {other}"))),
        })
    }

    fn bytes(&mut self, len: usize) -> Result<&'a [u8]> {
        let end = self
            .pos
            .checked_add(len)
            .ok_or_else(|| err("binary bytecode offset overflow"))?;
        if end > self.bytes.len() {
            return Err(err("truncated FCB bytecode binary"));
        }
        let out = &self.bytes[self.pos..end];
        self.pos = end;
        Ok(out)
    }

    fn finish(&self) -> Result<()> {
        if self.pos != self.bytes.len() {
            return Err(err("trailing FCB bytecode binary data"));
        }
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::{
        validate_bytecode, BytecodeFunction, BytecodeModule, Constant, DebugLocalEntry, OpCode,
        SourceMapEntry,
    };

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
    fn rejects_try_begin_handler_inside_operand() {
        let function = BytecodeFunction {
            name: "bad_try_handler".to_string(),
            return_convention: "tagged".to_string(),
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
}
