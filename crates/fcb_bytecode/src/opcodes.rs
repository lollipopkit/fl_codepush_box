//! FCB bytecode opcodes.
//!
//! Simple register-based bytecode instruction set. Each instruction is a u8 opcode
//! followed by operand bytes. The VM has a fixed set of general-purpose registers
//! (r0-r255) and a stack for nested expressions.

/// Bytecode opcodes for the FCB restricted interpreter.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
#[repr(u8)]
pub enum OpCode {
    // Control flow
    /// Halt execution, return value in register.
    Return = 0x01,
    /// Jump to offset (u16).
    Jump = 0x02,
    /// Jump to offset if register is falsy (u16).
    JumpIfFalse = 0x03,
    /// Jump to offset if register is truthy (u16).
    JumpIfTrue = 0x04,

    // Constants
    /// Load null into register.
    LoadNull = 0x10,
    /// Load boolean true into register.
    LoadTrue = 0x11,
    /// Load boolean false into register.
    LoadFalse = 0x12,
    /// Load integer constant (i64) into register.
    LoadInt = 0x13,
    /// Load double constant (f64) into register.
    LoadDouble = 0x14,
    /// Load string constant (string pool index u16) into register.
    LoadString = 0x15,

    // Arithmetic
    /// Add two registers, store in destination.
    Add = 0x20,
    /// Subtract two registers, store in destination.
    Subtract = 0x21,
    /// Multiply two registers, store in destination.
    Multiply = 0x22,
    /// Divide two registers, store in destination.
    Divide = 0x23,
    /// Modulo two registers, store in destination.
    Modulo = 0x24,
    /// Negate register, store in destination.
    Negate = 0x25,

    // Comparison
    /// Equal comparison.
    Equal = 0x30,
    /// Not equal comparison.
    NotEqual = 0x31,
    /// Less than comparison.
    LessThan = 0x32,
    /// Less than or equal comparison.
    LessEqual = 0x33,
    /// Greater than comparison.
    GreaterThan = 0x34,
    /// Greater than or equal comparison.
    GreaterEqual = 0x35,

    // Logical
    /// Logical NOT of register.
    LogicalNot = 0x40,

    // Type operations
    /// Type check: is int?
    IsInt = 0x50,
    /// Type check: is double?
    IsDouble = 0x51,
    /// Type check: is bool?
    IsBool = 0x52,
    /// Type check: is String?
    IsString = 0x53,
    /// Type check: is Null?
    IsNull = 0x54,

    // Variables
    /// Load local variable by index into register.
    LoadLocal = 0x60,
    /// Store register into local variable by index.
    StoreLocal = 0x61,

    // Collections
    /// Create empty List and store in register.
    ListNew = 0x70,
    /// List.add register value to list in register.
    ListAdd = 0x71,
    /// Create empty Map and store in register.
    MapNew = 0x72,
    /// Map[key] = value from registers.
    MapSet = 0x73,
    /// List[index] get element.
    ListGet = 0x74,
    /// List.length into register.
    ListLength = 0x75,

    // String operations
    /// String concatenation.
    StringConcat = 0x80,
    /// String interpolation (multi-part).
    StringInterpolate = 0x81,
    /// Convert register to String.
    ToString = 0x82,
    /// int.parse on string register.
    IntParse = 0x83,
    /// double.parse on string register.
    DoubleParse = 0x84,
    /// int.toDouble on register.
    IntToDouble = 0x85,
    /// double.toInt on register.
    DoubleToInt = 0x86,

    // Math operations
    /// Math.abs on register.
    MathAbs = 0x90,
    /// Math.min on two registers.
    MathMin = 0x91,
    /// Math.max on two registers.
    MathMax = 0x92,
    /// Math.sqrt on register.
    MathSqrt = 0x93,
    /// Math.round on register.
    MathRound = 0x94,

    // Function calls
    /// Call @hotPatchable function by index (u16), args count (u8).
    CallPatchable = 0xA0,
    /// Call core library function by index (u8), args count (u8).
    CallCore = 0xA1,
}

impl OpCode {
    /// Get the byte value of this opcode.
    pub fn byte(&self) -> u8 {
        *self as u8
    }

    /// Try to convert a byte to an OpCode.
    pub fn from_byte(byte: u8) -> Option<Self> {
        match byte {
            0x01 => Some(OpCode::Return),
            0x02 => Some(OpCode::Jump),
            0x03 => Some(OpCode::JumpIfFalse),
            0x04 => Some(OpCode::JumpIfTrue),
            0x10 => Some(OpCode::LoadNull),
            0x11 => Some(OpCode::LoadTrue),
            0x12 => Some(OpCode::LoadFalse),
            0x13 => Some(OpCode::LoadInt),
            0x14 => Some(OpCode::LoadDouble),
            0x15 => Some(OpCode::LoadString),
            0x20 => Some(OpCode::Add),
            0x21 => Some(OpCode::Subtract),
            0x22 => Some(OpCode::Multiply),
            0x23 => Some(OpCode::Divide),
            0x24 => Some(OpCode::Modulo),
            0x25 => Some(OpCode::Negate),
            0x30 => Some(OpCode::Equal),
            0x31 => Some(OpCode::NotEqual),
            0x32 => Some(OpCode::LessThan),
            0x33 => Some(OpCode::LessEqual),
            0x34 => Some(OpCode::GreaterThan),
            0x35 => Some(OpCode::GreaterEqual),
            0x40 => Some(OpCode::LogicalNot),
            0x50 => Some(OpCode::IsInt),
            0x51 => Some(OpCode::IsDouble),
            0x52 => Some(OpCode::IsBool),
            0x53 => Some(OpCode::IsString),
            0x54 => Some(OpCode::IsNull),
            0x60 => Some(OpCode::LoadLocal),
            0x61 => Some(OpCode::StoreLocal),
            0x70 => Some(OpCode::ListNew),
            0x71 => Some(OpCode::ListAdd),
            0x72 => Some(OpCode::MapNew),
            0x73 => Some(OpCode::MapSet),
            0x74 => Some(OpCode::ListGet),
            0x75 => Some(OpCode::ListLength),
            0x80 => Some(OpCode::StringConcat),
            0x81 => Some(OpCode::StringInterpolate),
            0x82 => Some(OpCode::ToString),
            0x83 => Some(OpCode::IntParse),
            0x84 => Some(OpCode::DoubleParse),
            0x85 => Some(OpCode::IntToDouble),
            0x86 => Some(OpCode::DoubleToInt),
            0x90 => Some(OpCode::MathAbs),
            0x91 => Some(OpCode::MathMin),
            0x92 => Some(OpCode::MathMax),
            0x93 => Some(OpCode::MathSqrt),
            0x94 => Some(OpCode::MathRound),
            0xA0 => Some(OpCode::CallPatchable),
            0xA1 => Some(OpCode::CallCore),
            _ => None,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::OpCode;

    #[test]
    fn opcodes_roundtrip() {
        let opcodes = [
            OpCode::Return,
            OpCode::Jump,
            OpCode::JumpIfFalse,
            OpCode::LoadInt,
            OpCode::Add,
            OpCode::Equal,
            OpCode::ListNew,
            OpCode::CallPatchable,
        ];
        for op in &opcodes {
            assert_eq!(OpCode::from_byte(op.byte()), Some(*op));
        }
    }

    #[test]
    fn no_opcode_zero() {
        assert_eq!(OpCode::from_byte(0x00), None);
    }
}
