use crate::{err, Result};
use serde::{Deserialize, Serialize};
use std::collections::BTreeSet;

/// Highest bytecode-module container version this build can parse/produce.
pub const FORMAT_VERSION: u32 = 3;
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
    Pop = 0x05,
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
    Await = 0x62,
    AsyncReturn = 0x63,
    Yield = 0x64,
    TryFinally = 0x65,
    EndFinally = 0x66,
    Rethrow = 0x67,
    Return = 0xff,
}

impl OpCode {
    pub fn from_byte(byte: u8) -> Option<Self> {
        Some(match byte {
            0x01 => Self::LoadConst,
            0x02 => Self::LoadArg,
            0x03 => Self::LoadLocal,
            0x04 => Self::StoreLocal,
            0x05 => Self::Pop,
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
            0x62 => Self::Await,
            0x63 => Self::AsyncReturn,
            0x64 => Self::Yield,
            0x65 => Self::TryFinally,
            0x66 => Self::EndFinally,
            0x67 => Self::Rethrow,
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
            Self::TryBegin | Self::TryFinally => 4,
            Self::LoadArg | Self::LoadLocal | Self::StoreLocal => 1,
            Self::Pop
            | Self::Add
            | Self::Sub
            | Self::Mul
            | Self::Div
            | Self::Greater
            | Self::Equal
            | Self::Throw
            | Self::Await
            | Self::AsyncReturn
            | Self::Yield
            | Self::EndFinally
            | Self::Rethrow
            | Self::Return => 0,
        }
    }
}

#[derive(Debug, Clone, Copy, Serialize, Deserialize, PartialEq, Eq)]
#[serde(rename_all = "snake_case")]
pub enum AsyncKind {
    Sync,
    AsyncFuture,
    AsyncStar,
    SyncStar,
}

fn default_async_kind() -> AsyncKind {
    AsyncKind::Sync
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
    #[serde(default = "default_async_kind")]
    pub async_kind: AsyncKind,
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
            let async_kind = if version >= 3 {
                match reader.u8()? {
                    0 => AsyncKind::Sync,
                    1 => AsyncKind::AsyncFuture,
                    2 => AsyncKind::AsyncStar,
                    3 => AsyncKind::SyncStar,
                    other => return Err(err(format!("unsupported binary async kind {other}"))),
                }
            } else {
                AsyncKind::Sync
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
                async_kind,
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
            out.push(match function.async_kind {
                AsyncKind::Sync => 0,
                AsyncKind::AsyncFuture => 1,
                AsyncKind::AsyncStar => 2,
                AsyncKind::SyncStar => 3,
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
            OpCode::Jump
                | OpCode::JumpIfFalse
                | OpCode::JumpIfTrue
                | OpCode::TryBegin
                | OpCode::TryFinally
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
            if opcode == OpCode::TryBegin || opcode == OpCode::TryFinally {
                let end = read_u16(&function.code, operand_start + 2) as usize;
                if end >= function.code.len() {
                    return Err(err(format!(
                        "{:?} at offset {} has out-of-range end offset {}",
                        opcode, pos, end
                    )));
                }
                if !starts.contains(&end) {
                    return Err(err(format!(
                        "{:?} at offset {} has non-instruction end offset {}",
                        opcode, pos, end
                    )));
                }
                if target <= pos || target >= end {
                    return Err(err(format!(
                        "{:?} at offset {} requires current < handler < end",
                        opcode, pos
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
#[path = "bytecode_tests.rs"]
mod tests;
