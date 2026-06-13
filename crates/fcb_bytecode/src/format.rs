//! FCB bytecode module format.
//!
//! A BytecodeModule is the top-level container for a set of compiled
//! @hotPatchable functions. It includes:
//! - A string pool for constants
//! - An int pool for integer constants
//! - A double pool for floating-point constants
//! - A list of function entries with their bytecode bodies
//! - Metadata linking function names to their entries

use serde::{Deserialize, Serialize};

/// Top-level bytecode module distributed as a patch payload.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BytecodeModule {
    /// Format version, must match the interpreter version.
    pub version: u32,
    /// Unique identifier for the app this module belongs to.
    pub app_id: String,
    /// Release version this patch targets.
    pub release_version: String,
    /// Patch number within this release.
    pub patch_number: u32,
    /// String constant pool (indexed by LoadString operands).
    pub string_pool: Vec<String>,
    /// Integer constant pool (indexed by LoadInt operands).
    pub int_pool: Vec<i64>,
    /// Double constant pool (indexed by LoadDouble operands).
    pub double_pool: Vec<f64>,
    /// Compiled function entries.
    pub functions: Vec<BytecodeFunction>,
}

/// A single compiled @hotPatchable function.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BytecodeFunction {
    /// Fully qualified function name (e.g., "MyClass.calculatePrice").
    pub name: String,
    /// Number of parameters.
    pub param_count: u8,
    /// Number of local variable slots (including parameters).
    pub local_count: u8,
    /// Raw bytecode bytes (OpCodes + operands).
    pub code: Vec<u8>,
}

impl BytecodeModule {
    /// Current bytecode format version.
    pub const FORMAT_VERSION: u32 = 1;

    /// Create a new empty module for the given app/release.
    pub fn new(app_id: &str, release_version: &str, patch_number: u32) -> Self {
        Self {
            version: Self::FORMAT_VERSION,
            app_id: app_id.to_string(),
            release_version: release_version.to_string(),
            patch_number,
            string_pool: Vec::new(),
            int_pool: Vec::new(),
            double_pool: Vec::new(),
            functions: Vec::new(),
        }
    }

    /// Add a string constant, returning its pool index.
    pub fn add_string(&mut self, value: &str) -> u16 {
        if let Some(idx) = self.string_pool.iter().position(|s| s == value) {
            idx as u16
        } else {
            let idx = self.string_pool.len();
            self.string_pool.push(value.to_string());
            idx as u16
        }
    }

    /// Add an integer constant, returning its pool index.
    pub fn add_int(&mut self, value: i64) -> u16 {
        if let Some(idx) = self.int_pool.iter().position(|&i| i == value) {
            idx as u16
        } else {
            let idx = self.int_pool.len();
            self.int_pool.push(value);
            idx as u16
        }
    }

    /// Add a double constant, returning its pool index.
    pub fn add_double(&mut self, value: f64) -> u16 {
        if let Some(idx) = self
            .double_pool
            .iter()
            .position(|&d| d.to_bits() == value.to_bits())
        {
            idx as u16
        } else {
            let idx = self.double_pool.len();
            self.double_pool.push(value);
            idx as u16
        }
    }

    /// Serialize the module to JSON bytes.
    pub fn to_json_bytes(&self) -> Result<Vec<u8>, serde_json::Error> {
        serde_json::to_vec(self)
    }

    /// Deserialize a module from JSON bytes.
    pub fn from_json_bytes(bytes: &[u8]) -> Result<Self, serde_json::Error> {
        serde_json::from_slice(bytes)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn bytecode_module_roundtrip() {
        let mut module = BytecodeModule::new("test-app", "1.0.0+1", 1);
        let s_idx = module.add_string("hello");
        let i_idx = module.add_int(42);
        let d_idx = module.add_double(3.14);
        module.functions.push(BytecodeFunction {
            name: "greet".to_string(),
            param_count: 1,
            local_count: 2,
            code: vec![0x15, 0x00, 0x00], // LoadString s_idx
        });

        let json = module.to_json_bytes().expect("serialize");
        let restored = BytecodeModule::from_json_bytes(&json).expect("deserialize");

        assert_eq!(restored.version, BytecodeModule::FORMAT_VERSION);
        assert_eq!(restored.string_pool[s_idx as usize], "hello");
        assert_eq!(restored.int_pool[i_idx as usize], 42);
        assert!((restored.double_pool[d_idx as usize] - 3.14).abs() < f64::EPSILON);
        assert_eq!(restored.functions.len(), 1);
        assert_eq!(restored.functions[0].name, "greet");
    }

    #[test]
    fn pool_deduplication() {
        let mut module = BytecodeModule::new("app", "1.0.0+1", 1);
        let first = module.add_string("duplicate");
        let second = module.add_string("duplicate");
        assert_eq!(first, second);
        assert_eq!(module.string_pool.len(), 1);
    }
}
