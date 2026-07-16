# Franken Shell development shell

This directory contains the clean, non-owning Franken Shell bootstrap and the
Phase 1 configuration lifecycle. It is
selected by its explicit repository path and is independent from the live
Caelestia configuration at `~/.config/quickshell/caelestia`.

The bootstrap creates one ordinary, noninteractive diagnostic window. It does
not import or instantiate notification, tray, Polkit, PAM, session-lock,
global-shortcut, session-management, or other exclusive desktop-service APIs.

## Tested baseline

- Quickshell 0.3.0
- Quickshell commit `4df562dfb2475a9057f0f33a8db75808efad8670`
- Arch package `quickshell-git 0.3.0.r15.g4df562d-1`
- Qt 6.11.1
- Hyprland 0.55.4 using Lua configuration

This is the exact tested Phase 0 development baseline, not a minimum supported
version.

## Development interface

Run every command from this directory or invoke the script by absolute path:

```sh
./dev/franken-shell start
./dev/franken-shell mock
./dev/franken-shell stop
./dev/franken-shell restart
./dev/franken-shell reload
./dev/franken-shell config-reload
./dev/franken-shell logs
./dev/franken-shell diagnostics
./dev/franken-shell config-status
./dev/franken-shell verify-baseline
./dev/franken-shell check
./dev/franken-shell config-helper-build
./dev/franken-shell config-helper-test
./dev/franken-shell config-helper-client-test
./dev/franken-shell config-service-check
./dev/franken-shell config-service-test
./dev/franken-shell config-demo helpers/franken-config-helper/tests/fixtures/complete_valid.toml
./dev/franken-shell config-helper-validate-fixture helpers/franken-config-helper/tests/fixtures/complete_valid.toml
printf '%s' '{"protocolVersion":1,"requestGeneration":1,"operation":"validateAndNormalize","sourceIdentifier":"example.toml","tomlSource":"schemaVersion = 1\n"}' \
    | ./dev/franken-shell config-helper-pipe
```

`start` and `mock` use Quickshell's repository-path identity and
`--no-duplicate`. They cannot select, stop, reload, or replace the separately
running `caelestia` configuration.

`reload` requests a Quickshell soft reload and preserves the process where
supported. `config-reload` asks the running `ConfigService` to reread its
current authoritative path without reloading QML. `restart` performs a full
stop and new process launch. These are different lifecycle operations.

## Configuration lifecycle

The authoritative user configuration is:

```text
${XDG_CONFIG_HOME:-$HOME/.config}/franken-shell/config.toml
```

The shell activates a complete typed built-in snapshot before it reads the
user file. A missing file is a normal, healthy defaults-only state and does not
require the Rust helper. The bundled normalized defaults resource is checked by
a Rust contract test against `Configuration::default()` so QML and helper
defaults cannot drift silently.

When a file exists, `ConfigService` watches it with a restartable debounce
(300 ms by default), sends the exact text read by QML to the single root-owned
helper client, constructs a complete candidate snapshot, and swaps the active
snapshot reference once. Unknown fields can produce warnings without blocking
activation. Supported older schemas migrate only in memory; the source file is
not rewritten.

An invalid cold start keeps built-in defaults active and marks configuration
health degraded. An invalid hot reload retains the complete previous active
snapshot and generation. A later valid edit activates a new snapshot and
recovers health. Helper unavailability and transport failure are reported
separately from validation failure. There is no persistent last-valid cache.

Configuration writing, settings drafts, source-preserving patching, and
automatic migration rewrites are not implemented.

Automated tests set `FRANKEN_SHELL_MODE=config-service-test` together with
`FRANKEN_CONFIG_FIXTURE_PATH`; `config-demo` uses the separate explicit
`config-demo` mode. The fixture override is ignored in every other mode, so an
inherited override cannot redirect the ordinary development or production
configuration path. Both modes use temporary paths and never read or watch the
user's live configuration. `config-demo` accepts only a fixture under the
repository helper's `tests/fixtures/` directory, copies it into `/tmp`, and
starts the same non-owning repository-path instance against that copy.

`config-status` exposes a sanitized JSON summary: path, source, schema,
generation, health, reload state, counts, helper transport health, and
migration state. It does not expose TOML text, normalized configuration, or
command arguments.

Phase 1 slice 1 adds the standalone `franken-config-helper` Rust binary under
`helpers/franken-config-helper/`. Phase 1 slice 2A adds one root-owned QML
client for asynchronous protocol invocation and transport validation. It does
not read or watch `config.toml` itself. Phase 1 slice 2B adds the root-owned
`ConfigService`, watched file lifecycle, typed snapshots, atomic publication,
health, diagnostics, and explicit reload.

The QML client resolves the development helper deterministically at:

```text
helpers/franken-config-helper/target/debug/franken-config-helper
```

Build it with `config-helper-build` or run `config-helper-client-test`, which
builds it before exercising the real helper and controlled transport-failure
fixtures. Production installation paths remain a packaging concern.

The client API is `validateAndNormalize(generation, sourceIdentifier,
tomlSource)`. Results are emitted through `resultReady(result)`, while
`requestStateChanged(generation, state)` exposes queued, process, terminal, and
supersession transitions. The client keeps at most one active request and one
replaceable pending request.

## Configuration helper protocol

The helper reads exactly one protocol-version-1 JSON request from stdin and
writes exactly one JSON response to stdout. The initial operation is
`validateAndNormalize`.

```json
{
  "protocolVersion": 1,
  "requestGeneration": 42,
  "operation": "validateAndNormalize",
  "sourceIdentifier": "/display/path/config.toml",
  "tomlSource": "schemaVersion = 1\n"
}
```

Successful responses contain the detected and effective schema versions,
migration status, a normalized typed configuration, warnings, and errors.
Validation failures use the same response shape. Diagnostics include stable
codes, logical configuration paths, source identifiers, and source positions
where available.

The helper never reads the live user configuration itself, writes source TOML,
or requires Python. `config-helper-validate-fixture` uses `jq` only to construct
a development request from a selected fixture.

Quickshell stores its own per-shell logs and runtime state outside this
repository. `logs` reads the log for this repository-path identity only.

## Safety boundary

While the current Caelestia shell is running, Franken Shell must remain in this
non-owning mode. Do not add imports or instances for:

- `org.freedesktop.Notifications` ownership;
- StatusNotifierWatcher or persistent tray-host ownership;
- Polkit agents;
- PAM or session-lock surfaces;
- global shortcuts;
- session-management ownership.

The future production systemd user service is intentionally not included in
Phase 0.
