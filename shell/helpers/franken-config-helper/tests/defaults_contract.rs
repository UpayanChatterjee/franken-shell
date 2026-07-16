use std::path::Path;

use franken_config_helper::Configuration;
use serde_json::Value;

#[test]
fn qml_default_resource_matches_rust_schema_defaults() {
    let path = Path::new(env!("CARGO_MANIFEST_DIR"))
        .join("..")
        .join("..")
        .join("core")
        .join("ConfigDefaults.js");
    let source = std::fs::read_to_string(&path).expect("QML defaults resource should be readable");
    let start = source
        .find('{')
        .expect("QML defaults resource should contain a JSON object");
    let end = source
        .rfind('}')
        .expect("QML defaults resource should contain a JSON object");
    let qml_defaults: Value =
        serde_json::from_str(&source[start..=end]).expect("defaults resource should contain JSON");
    let rust_defaults =
        serde_json::to_value(Configuration::default()).expect("Rust defaults should serialize");

    assert_eq!(
        qml_defaults, rust_defaults,
        "Regenerate ConfigDefaults.js from Configuration::default() when schema defaults change"
    );
}
