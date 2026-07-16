use std::ops::Range;

use serde::Serialize;

#[derive(Clone, Copy, Debug, Eq, PartialEq, Serialize)]
#[serde(rename_all = "lowercase")]
pub enum Severity {
    Warning,
    Error,
}

#[derive(Clone, Debug, Eq, PartialEq, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct Diagnostic {
    pub severity: Severity,
    pub code: String,
    pub message: String,
    pub configuration_path: Option<String>,
    pub source: String,
    pub line: Option<usize>,
    pub column: Option<usize>,
    pub repair_hint: Option<String>,
}

pub struct SourceSpan<'a> {
    pub identifier: &'a str,
    pub text: &'a str,
    pub span: Option<Range<usize>>,
}

impl Diagnostic {
    pub fn protocol_error(
        code: impl Into<String>,
        message: impl Into<String>,
        path: Option<&str>,
        line: Option<usize>,
        column: Option<usize>,
        hint: Option<&str>,
    ) -> Self {
        Self {
            severity: Severity::Error,
            code: code.into(),
            message: message.into(),
            configuration_path: path.map(str::to_owned),
            source: "<stdin>".to_owned(),
            line,
            column,
            repair_hint: hint.map(str::to_owned),
        }
    }

    pub fn from_span(
        severity: Severity,
        code: impl Into<String>,
        message: impl Into<String>,
        path: Option<&str>,
        source: SourceSpan<'_>,
        hint: Option<&str>,
    ) -> Self {
        let (line, column) = source
            .span
            .map(|range| line_column(source.text, range.start))
            .map_or((None, None), |(line, column)| (Some(line), Some(column)));

        Self {
            severity,
            code: code.into(),
            message: message.into(),
            configuration_path: path.map(str::to_owned),
            source: source.identifier.to_owned(),
            line,
            column,
            repair_hint: hint.map(str::to_owned),
        }
    }
}

fn line_column(source: &str, byte_offset: usize) -> (usize, usize) {
    let offset = byte_offset.min(source.len());
    let prefix = &source[..offset];
    let line = prefix.bytes().filter(|byte| *byte == b'\n').count() + 1;
    let column = prefix
        .rsplit_once('\n')
        .map_or(prefix, |(_, remainder)| remainder)
        .chars()
        .count()
        + 1;
    (line, column)
}

#[cfg(test)]
mod tests {
    use super::line_column;

    #[test]
    fn converts_byte_offsets_to_one_based_positions() {
        assert_eq!(line_column("one\ntwø\n", 0), (1, 1));
        assert_eq!(line_column("one\ntwø\n", 4), (2, 1));
        assert_eq!(line_column("one\ntwø\n", 8), (2, 4));
    }
}
