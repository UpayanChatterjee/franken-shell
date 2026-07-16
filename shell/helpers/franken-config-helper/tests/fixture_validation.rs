use std::path::Path;

use franken_config_helper::{Configuration, Response, process_request_json};
use serde_json::json;

fn fixture(name: &str) -> String {
    let path = Path::new(env!("CARGO_MANIFEST_DIR"))
        .join("tests")
        .join("fixtures")
        .join(name);
    std::fs::read_to_string(path).expect("fixture should be readable")
}

fn validate(name: &str, generation: u64) -> Response {
    let request = json!({
        "protocolVersion": 1,
        "requestGeneration": generation,
        "operation": "validateAndNormalize",
        "sourceIdentifier": format!("fixture:{name}"),
        "tomlSource": fixture(name)
    });
    process_request_json(&request.to_string())
}

fn has_error(response: &Response, code: &str) -> bool {
    response
        .errors
        .iter()
        .any(|diagnostic| diagnostic.code == code)
}

fn has_warning(response: &Response, code: &str) -> bool {
    response
        .warnings
        .iter()
        .any(|diagnostic| diagnostic.code == code)
}

#[test]
fn missing_optional_sections_resolve_to_defaults() {
    let response = validate("missing_optional.toml", 1);
    assert!(response.success, "{:?}", response.errors);
    assert_eq!(
        response.normalized_configuration,
        Some(Configuration::default())
    );
}

#[test]
fn complete_configuration_is_normalized() {
    let response = validate("complete_valid.toml", 2);
    assert!(response.success, "{:?}", response.errors);
    let config = response.normalized_configuration.expect("configuration");
    assert_eq!(config.schema_version, 1);
    assert_eq!(config.workspaces.special.len(), 2);
    assert_eq!(config.commands["vicinae.root"].arguments, ["toggle"]);
    assert!(!config.commands["vicinae.root"].detached);
    assert!(config.commands["vicinae.root"].environment.is_empty());
}

#[test]
fn malformed_toml_reports_line_and_column() {
    let response = validate("malformed.toml", 3);
    assert!(!response.success);
    let diagnostic = response
        .errors
        .iter()
        .find(|diagnostic| diagnostic.code == "CONFIG_TOML_PARSE_ERROR")
        .expect("parse error");
    assert!(diagnostic.line.is_some());
    assert!(diagnostic.column.is_some());
}

#[test]
fn wrong_field_type_is_rejected() {
    let response = validate("wrong_type.toml", 4);
    assert!(has_error(&response, "CONFIG_WRONG_TYPE"));
    assert_eq!(
        response.errors[0].configuration_path.as_deref(),
        Some("bar.enabled")
    );
}

#[test]
fn invalid_enum_is_rejected() {
    let response = validate("invalid_enum.toml", 5);
    assert!(has_error(&response, "CONFIG_INVALID_ENUM"));
}

#[test]
fn out_of_range_number_is_rejected() {
    let response = validate("out_of_range.toml", 6);
    assert!(has_error(&response, "CONFIG_VALUE_OUT_OF_RANGE"));
}

#[test]
fn semantic_cross_field_failure_is_rejected() {
    let response = validate("semantic_failure.toml", 7);
    assert!(has_error(&response, "CONFIG_WORKSPACE_RANGE_INVALID"));
    assert!(has_error(&response, "CONFIG_WORKSPACE_GROUP_MISMATCH"));
}

#[test]
fn duplicate_stable_id_is_rejected() {
    let response = validate("duplicate_id.toml", 8);
    assert!(has_error(&response, "CONFIG_DUPLICATE_STABLE_ID"));
}

#[test]
fn unknown_fields_warn_and_do_not_enter_normalized_state() {
    let response = validate("unknown_field.toml", 9);
    assert!(response.success, "{:?}", response.errors);
    assert!(has_warning(&response, "CONFIG_UNKNOWN_FIELD"));
    let json = serde_json::to_value(response.normalized_configuration).expect("serialize");
    assert!(json.pointer("/futureTopLevel").is_none());
    assert!(json.pointer("/bar/futureBarField").is_none());
}

#[test]
fn newer_schema_is_rejected_without_downgrade() {
    let response = validate("newer_schema.toml", 10);
    assert!(has_error(&response, "CONFIG_SCHEMA_TOO_NEW"));
    assert_eq!(response.detected_source_schema_version, Some(2));
    assert_eq!(response.effective_schema_version, None);
    assert!(!response.migration_occurred);
}

#[test]
fn older_schema_uses_in_memory_migration() {
    let response = validate("schema_zero.toml", 11);
    assert!(response.success, "{:?}", response.errors);
    assert_eq!(response.detected_source_schema_version, Some(0));
    assert_eq!(response.effective_schema_version, Some(1));
    assert!(response.migration_occurred);
    assert!(has_warning(&response, "CONFIG_MIGRATED_IN_MEMORY"));
    let normalized =
        serde_json::to_value(response.normalized_configuration).expect("serialize configuration");
    assert_eq!(normalized.pointer("/bar/edge"), Some(&json!("right")));
}

#[test]
fn generation_is_preserved_in_success_and_failure() {
    assert_eq!(validate("complete_valid.toml", 901).request_generation, 901);
    assert_eq!(validate("invalid_enum.toml", 902).request_generation, 902);
}

#[test]
fn malformed_protocol_request_is_structured() {
    let response = process_request_json(
        r#"{"protocolVersion":1,"requestGeneration":77,"operation":"validateAndNormalize"}"#,
    );
    assert!(!response.success);
    assert_eq!(response.request_generation, 77);
    assert!(
        response
            .errors
            .iter()
            .all(|diagnostic| diagnostic.code.starts_with("PROTOCOL_"))
    );
}

#[test]
fn normalized_output_is_deterministic() {
    let first = validate("complete_valid.toml", 12);
    let second = validate("complete_valid.toml", 12);
    assert_eq!(
        serde_json::to_string(&first).expect("serialize"),
        serde_json::to_string(&second).expect("serialize")
    );
}

#[test]
fn arbitrary_command_string_is_rejected_structurally() {
    let response = validate("invalid_command_string.toml", 13);
    assert!(has_error(&response, "CONFIG_WRONG_TYPE"));
}

#[test]
fn executable_shell_composition_is_rejected_semantically() {
    let response = validate("unsafe_executable.toml", 14);
    assert!(has_error(&response, "CONFIG_COMMAND_EXECUTABLE_UNSAFE"));
}

#[test]
fn detached_command_execution_is_rejected() {
    let response = validate("unsupported_command_detached.toml", 15);
    assert!(!response.success);
    assert!(has_error(&response, "CONFIG_COMMAND_DETACHED_UNSUPPORTED"));
}

#[test]
fn command_environment_overrides_are_rejected() {
    let response = validate("unsupported_command_environment.toml", 16);
    assert!(!response.success);
    assert!(has_error(
        &response,
        "CONFIG_COMMAND_ENVIRONMENT_UNSUPPORTED"
    ));
}

#[test]
fn command_working_directory_is_rejected_instead_of_ignored() {
    let response = validate("unsupported_command_working_directory.toml", 17);
    assert!(!response.success);
    assert!(has_error(
        &response,
        "CONFIG_COMMAND_WORKING_DIRECTORY_UNSUPPORTED"
    ));
}
