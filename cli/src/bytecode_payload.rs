use fcb_bytecode::format::{BytecodeModule, BINARY_MAGIC};
use fcb_core::Result;

pub(crate) fn read_bytecode_module(bytes: &[u8]) -> Result<BytecodeModule> {
    BytecodeModule::from_slice(bytes)
}

pub(crate) fn validate_compiled_bytecode_payload(bytes: &[u8]) -> Result<Vec<u8>> {
    let module = BytecodeModule::from_slice(bytes)?;
    if bytes.starts_with(BINARY_MAGIC) {
        Ok(bytes.to_vec())
    } else {
        module.to_vec()
    }
}
