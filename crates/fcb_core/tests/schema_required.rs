use fcb_core::manifest::{
    PATCH_MANIFEST_REQUIRED, PATCH_POLICY_REQUIRED, PATCH_SIGNATURE_REQUIRED,
    PAYLOAD_MANIFEST_REQUIRED, RELEASE_MANIFEST_REQUIRED,
};
use serde_json::Value;
use std::fs;

#[test]
fn release_schema_required_matches_manifest_struct() {
    let schema = read_schema("schemas/release_manifest.schema.json");
    assert_required_eq(&schema, RELEASE_MANIFEST_REQUIRED);
}

#[test]
fn patch_schema_required_matches_manifest_structs() {
    let schema = read_schema("schemas/patch_manifest.schema.json");
    assert_required_eq(&schema, PATCH_MANIFEST_REQUIRED);
    assert_required_eq(&schema["properties"]["payload"], PAYLOAD_MANIFEST_REQUIRED);
    assert_required_eq(&schema["properties"]["policy"], PATCH_POLICY_REQUIRED);
    assert_required_eq(&schema["properties"]["signature"], PATCH_SIGNATURE_REQUIRED);
}

fn read_schema(path: &str) -> Value {
    let workspace = std::path::PathBuf::from(env!("CARGO_MANIFEST_DIR"))
        .parent()
        .and_then(|p| p.parent())
        .expect("workspace root")
        .to_path_buf();
    serde_json::from_slice(&fs::read(workspace.join(path)).expect("schema file"))
        .expect("schema json")
}

fn assert_required_eq(schema: &Value, expected: &[&str]) {
    let mut actual = schema["required"]
        .as_array()
        .expect("required array")
        .iter()
        .map(|value| value.as_str().expect("required string"))
        .collect::<Vec<_>>();
    let mut expected = expected.to_vec();
    actual.sort_unstable();
    expected.sort_unstable();
    assert_eq!(actual, expected);
}
