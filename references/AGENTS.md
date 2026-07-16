# Reference directory rules

Everything under this directory is read-only.

Do not:

- edit reference source files
- run formatters that modify reference files
- commit inside reference repositories
- copy entire modules into the active shell
- alter references to make integration easier

Reference repositories exist only for inspection, comparison and behavioural
analysis.

Write findings under `references/analyses/` or `docs/`.
