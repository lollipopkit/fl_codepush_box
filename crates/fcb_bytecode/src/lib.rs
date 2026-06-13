//! FCB restricted bytecode compiler and interpreter support.
//!
//! This module implements the Phase C restricted bytecode backend:
//! - A simple register-based bytecode format for annotated Dart functions
//! - A compiler that translates annotated Dart function AST nodes to bytecode
//! - Bytecode payloads that are distributed as patch data (not native code)
//!
//! The bytecode format is intentionally restricted:
//! - Only int, double, bool, String, Null, List, Map literals
//! - if/else, for/while loops
//! - Local variables
//! - Static function calls (to other @hotPatchable functions or core ops)
//! - No closures, no generics, no async/await in Phase C

pub mod compiler;
pub mod format;
pub mod linker;
pub mod opcodes;

pub use format::BytecodeModule;
pub use linker::{function_id, link_programs, LinkOutput, LinkReport, ProgramSpec};
pub use opcodes::OpCode;
