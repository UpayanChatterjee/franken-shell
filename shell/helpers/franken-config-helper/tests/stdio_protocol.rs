use std::io::Write;
use std::process::{Command, Stdio};

use serde_json::{Value, json};

#[test]
fn binary_emits_one_json_response_on_stdout() {
    let request = json!({
        "protocolVersion": 1,
        "requestGeneration": 123,
        "operation": "validateAndNormalize",
        "sourceIdentifier": "stdio.toml",
        "tomlSource": "schemaVersion = 1\n"
    });

    let mut child = Command::new(env!("CARGO_BIN_EXE_franken-config-helper"))
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .stderr(Stdio::piped())
        .spawn()
        .expect("helper should start");
    child
        .stdin
        .as_mut()
        .expect("stdin")
        .write_all(request.to_string().as_bytes())
        .expect("request should write");
    let output = child.wait_with_output().expect("helper should exit");

    assert!(output.status.success());
    assert!(output.stderr.is_empty());
    let stdout = String::from_utf8(output.stdout).expect("UTF-8 stdout");
    assert_eq!(stdout.lines().count(), 1);
    let response: Value = serde_json::from_str(stdout.trim_end()).expect("JSON response");
    assert_eq!(response["requestGeneration"], 123);
    assert_eq!(response["success"], true);
}
