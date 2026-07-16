mod diagnostic;
mod migration;
mod parser;
mod protocol;
mod schema;

pub use diagnostic::{Diagnostic, Severity};
pub use protocol::{PROTOCOL_VERSION, Response};
pub use schema::{CURRENT_SCHEMA_VERSION, Configuration};

pub fn process_request_json(input: &str) -> Response {
    let request = match protocol::decode_request(input) {
        Ok(request) => request,
        Err(response) => return *response,
    };

    debug_assert_eq!(request.protocol_version, PROTOCOL_VERSION);
    debug_assert_eq!(request.operation, protocol::VALIDATE_OPERATION);

    let result = parser::validate_and_normalize(&request.source_identifier, &request.toml_source);
    Response {
        protocol_version: PROTOCOL_VERSION,
        request_generation: request.request_generation,
        success: result.errors.is_empty(),
        detected_source_schema_version: result.detected_source_schema_version,
        effective_schema_version: result.effective_schema_version,
        migration_occurred: result.migration_occurred,
        normalized_configuration: result.normalized_configuration,
        warnings: result.warnings,
        errors: result.errors,
    }
}

#[cfg(test)]
mod tests {
    use serde_json::json;

    use super::process_request_json;

    #[test]
    fn preserves_generation_for_valid_requests() {
        let request = json!({
            "protocolVersion": 1,
            "requestGeneration": 42,
            "operation": "validateAndNormalize",
            "sourceIdentifier": "fixture.toml",
            "tomlSource": "schemaVersion = 1\n"
        });
        let response = process_request_json(&request.to_string());
        assert!(response.success);
        assert_eq!(response.request_generation, 42);
    }

    #[test]
    fn malformed_protocol_is_a_protocol_response() {
        let response = process_request_json("{");
        assert!(!response.success);
        assert_eq!(response.protocol_version, 1);
        assert_eq!(response.request_generation, 0);
        assert_eq!(response.errors[0].code, "PROTOCOL_INVALID_JSON");
    }
}
