use std::io::{self, Read, Write};

fn main() {
    let mut input = String::new();
    if let Err(error) = io::stdin().read_to_string(&mut input) {
        eprintln!("franken-config-helper: failed to read protocol request: {error}");
        std::process::exit(1);
    }

    let response = franken_config_helper::process_request_json(&input);
    let stdout = io::stdout();
    let mut output = stdout.lock();
    if let Err(error) = serde_json::to_writer(&mut output, &response)
        .and_then(|()| output.write_all(b"\n").map_err(serde_json::Error::io))
    {
        eprintln!("franken-config-helper: failed to write protocol response: {error}");
        std::process::exit(1);
    }
}
