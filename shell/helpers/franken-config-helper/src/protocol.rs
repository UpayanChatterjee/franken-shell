use serde::Serialize;
use serde_json::{Map, Value};

use crate::diagnostic::Diagnostic;
use crate::schema::Configuration;

pub const PROTOCOL_VERSION: u32 = 1;
pub const VALIDATE_OPERATION: &str = "validateAndNormalize";

#[derive(Clone, Debug, Eq, PartialEq)]
pub struct Request {
    pub protocol_version: u32,
    pub request_generation: u64,
    pub operation: String,
    pub source_identifier: String,
    pub toml_source: String,
}

#[derive(Clone, Debug, PartialEq, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct Response {
    pub protocol_version: u32,
    pub request_generation: u64,
    pub success: bool,
    pub detected_source_schema_version: Option<u32>,
    pub effective_schema_version: Option<u32>,
    pub migration_occurred: bool,
    pub normalized_configuration: Option<Configuration>,
    pub warnings: Vec<Diagnostic>,
    pub errors: Vec<Diagnostic>,
}

impl Response {
    pub fn protocol_failure(request_generation: u64, errors: Vec<Diagnostic>) -> Self {
        Self {
            protocol_version: PROTOCOL_VERSION,
            request_generation,
            success: false,
            detected_source_schema_version: None,
            effective_schema_version: None,
            migration_occurred: false,
            normalized_configuration: None,
            warnings: Vec::new(),
            errors,
        }
    }
}

pub fn decode_request(input: &str) -> Result<Request, Box<Response>> {
    let value: Value = match serde_json::from_str(input) {
        Ok(value) => value,
        Err(error) => {
            return Err(Box::new(Response::protocol_failure(
                0,
                vec![Diagnostic::protocol_error(
                    "PROTOCOL_INVALID_JSON",
                    "stdin did not contain one valid JSON request",
                    None,
                    Some(error.line()),
                    Some(error.column()),
                    Some("Send one protocol-version-1 JSON object through stdin."),
                )],
            )));
        }
    };

    let Some(object) = value.as_object() else {
        return Err(Box::new(Response::protocol_failure(
            0,
            vec![Diagnostic::protocol_error(
                "PROTOCOL_INVALID_REQUEST",
                "the protocol request must be a JSON object",
                None,
                None,
                None,
                Some("Wrap the request fields in one JSON object."),
            )],
        )));
    };

    let generation = object
        .get("requestGeneration")
        .and_then(Value::as_u64)
        .unwrap_or(0);
    let mut errors = Vec::new();

    let protocol_version = required_u32(
        object,
        "protocolVersion",
        &mut errors,
        "protocolVersion must be a non-negative integer",
    );
    let request_generation = required_u64(
        object,
        "requestGeneration",
        &mut errors,
        "requestGeneration must be a non-negative integer",
    );
    let operation = required_string(
        object,
        "operation",
        &mut errors,
        "operation must be a string",
    );
    let source_identifier = required_string(
        object,
        "sourceIdentifier",
        &mut errors,
        "sourceIdentifier must be a non-empty string",
    );
    let toml_source = required_string(
        object,
        "tomlSource",
        &mut errors,
        "tomlSource must be a string containing the exact TOML source text",
    );

    if let Some(version) = protocol_version {
        if version != PROTOCOL_VERSION {
            errors.push(Diagnostic::protocol_error(
                "PROTOCOL_UNSUPPORTED_VERSION",
                format!(
                    "protocol version {version} is unsupported; this helper supports version {PROTOCOL_VERSION}"
                ),
                Some("protocolVersion"),
                None,
                None,
                Some("Use protocolVersion = 1 or run a matching helper."),
            ));
        }
    }

    if let Some(ref operation) = operation {
        if operation != VALIDATE_OPERATION {
            errors.push(Diagnostic::protocol_error(
                "PROTOCOL_UNSUPPORTED_OPERATION",
                format!("operation {operation:?} is unsupported"),
                Some("operation"),
                None,
                None,
                Some("Use operation = \"validateAndNormalize\"."),
            ));
        }
    }

    if let Some(ref source_identifier) = source_identifier {
        if source_identifier.is_empty() {
            errors.push(Diagnostic::protocol_error(
                "PROTOCOL_INVALID_FIELD",
                "sourceIdentifier must not be empty",
                Some("sourceIdentifier"),
                None,
                None,
                Some("Provide the display path or another stable source identifier."),
            ));
        }
    }

    if !errors.is_empty() {
        return Err(Box::new(Response::protocol_failure(generation, errors)));
    }

    Ok(Request {
        protocol_version: protocol_version.expect("validated protocol version"),
        request_generation: request_generation.expect("validated generation"),
        operation: operation.expect("validated operation"),
        source_identifier: source_identifier.expect("validated source identifier"),
        toml_source: toml_source.expect("validated TOML source"),
    })
}

fn required_u32(
    object: &Map<String, Value>,
    field: &str,
    errors: &mut Vec<Diagnostic>,
    message: &str,
) -> Option<u32> {
    let value = required_u64(object, field, errors, message)?;
    match u32::try_from(value) {
        Ok(value) => Some(value),
        Err(_) => {
            errors.push(Diagnostic::protocol_error(
                "PROTOCOL_INVALID_FIELD",
                message,
                Some(field),
                None,
                None,
                None,
            ));
            None
        }
    }
}

fn required_u64(
    object: &Map<String, Value>,
    field: &str,
    errors: &mut Vec<Diagnostic>,
    message: &str,
) -> Option<u64> {
    match object.get(field) {
        Some(value) => match value.as_u64() {
            Some(value) => Some(value),
            None => {
                errors.push(Diagnostic::protocol_error(
                    "PROTOCOL_INVALID_FIELD",
                    message,
                    Some(field),
                    None,
                    None,
                    None,
                ));
                None
            }
        },
        None => {
            errors.push(Diagnostic::protocol_error(
                "PROTOCOL_MISSING_FIELD",
                format!("required field {field:?} is missing"),
                Some(field),
                None,
                None,
                Some("Include every required protocol field."),
            ));
            None
        }
    }
}

fn required_string(
    object: &Map<String, Value>,
    field: &str,
    errors: &mut Vec<Diagnostic>,
    message: &str,
) -> Option<String> {
    match object.get(field) {
        Some(Value::String(value)) => Some(value.clone()),
        Some(_) => {
            errors.push(Diagnostic::protocol_error(
                "PROTOCOL_INVALID_FIELD",
                message,
                Some(field),
                None,
                None,
                None,
            ));
            None
        }
        None => {
            errors.push(Diagnostic::protocol_error(
                "PROTOCOL_MISSING_FIELD",
                format!("required field {field:?} is missing"),
                Some(field),
                None,
                None,
                Some("Include every required protocol field."),
            ));
            None
        }
    }
}
