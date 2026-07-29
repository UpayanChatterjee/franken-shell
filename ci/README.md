# Repository CI entry points

The `ci/` commands are the canonical local and GitHub Actions interface. Run
them from any directory inside the checkout.

```sh
./ci/bootstrap-tools
./ci/run hygiene
./ci/run format
./ci/run lint
./ci/run unit
./ci/run smoke
```

`./ci/run all` executes the complete sequence and stores redacted logs under
`.ci-artifacts/`. `./ci/collect-diagnostics <label>` adds tool versions, Git
state, process state, and Quickshell instance information without copying the
user configuration, environment, notification content, or credentials.

## What each task owns

- `hygiene`: repository-wide conflict, path, executable-bit, JSON, secret, and
  diff checks;
- `format`: Rust, shell, QML, Markdown, JSON, YAML, and CSS formatting;
- `lint`: Rust Clippy, ShellCheck, qmllint, markdownlint, actionlint, and
  workflow-permission policy;
- `unit`: Rust contracts plus direct typed-snapshot, configuration lifecycle,
  capability/diagnostic/readiness, semantic-theme, surface-coordinator,
  versioned-shell-IPC, monitor-aware bar-host geometry, monitor-registry,
  command-registry, and helper-client fixture suites;
- `smoke`: isolated, offscreen, non-owning healthy, degraded, and
  required-core-failure startup, duplicate-start rejection, soft reload,
  readiness, theme-health, shell-IPC malformed/version/reload safety, warning
  policy, one fixture BarHost before/after reload, and process teardown.

The unit lane captures normal, long-text, high-text-scale, and missing-item bar
fixtures. GitHub uploads these PNGs as a non-blocking review artifact; they are
evidence for layout review rather than approved visual-regression baselines.

Lua routing is active but currently has no project files to inspect. The first
PR that adds Lua must also provide the pinned StyLua and Selene installations,
configuration, and tests required by the roadmap's new-language rule.

Unit task output is retained under `.ci-artifacts/unit/`, including the
individual fixture log that failed. Smoke evidence is retained under
`.ci-artifacts/smoke/`, including readiness summaries, instance records,
Quickshell logs, and observed child process IDs.

`ci/baselines/smoke-known.txt` contains the one accepted warning produced by
Qt's offscreen platform plugin when Quickshell attempts to set a window mask.
The separate `smoke-required-failure-known.txt` baseline admits only the
intentional structured readiness-transition error from the required-core
failure fixture. All other smoke warnings, errors, binding loops, and
component-load failures are rejected.

## Existing-debt baselines

Files under `ci/baselines/` record only problems present before PR-001. Format
and shell-lint baselines use file hashes, so modifying a non-compliant file
invalidates its exception. The qmllint baseline records warning category
counts per file. New debt fails immediately.

The engineering roadmap is intentionally excluded from Prettier and
markdownlint. Its large fixed-width ledger is optimized for narrow status
changes; automatic table reflow would make every bookkeeping PR difficult to
review.

## CI environments

The pinned lane uses the Arch Linux repository snapshot from 2026-07-01 and
builds the repository-owned `quickshell-git` package at the exact D-071 commit,
then checks the accepted Quickshell 0.3.0, Qt 6.11.1, and Hyprland 0.55.4
versions. The rolling Arch lane installs the current repository packages. Both
use Rust 1.85.0, Node 24, and the repository lockfiles.

The pinned package recipe is adapted from the AUR `quickshell-git` recipe at
commit `2494139bce7b7fc71372da00b68fb745a2c72d90`. It deliberately fixes both
the source revision and package version instead of following the AUR branch.
GitHub Actions caches the resulting package by Arch snapshot, runner
architecture, and PKGBUILD content. The first run for a new key builds from
source; later pinned runs install the cached package directly.
