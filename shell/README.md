# Franken Shell Phase 0

This directory contains the clean, non-owning Franken Shell bootstrap. It is
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
./dev/franken-shell logs
./dev/franken-shell diagnostics
./dev/franken-shell config-status
./dev/franken-shell verify-baseline
./dev/franken-shell check
./dev/franken-shell config-helper-build
./dev/franken-shell config-helper-test
./dev/franken-shell config-helper-validate-fixture helpers/franken-config-helper/tests/fixtures/complete_valid.toml
printf '%s' '{"protocolVersion":1,"requestGeneration":1,"operation":"validateAndNormalize","sourceIdentifier":"example.toml","tomlSource":"schemaVersion = 1\n"}' \
    | ./dev/franken-shell config-helper-pipe
```

`start` and `mock` use Quickshell's repository-path identity and
`--no-duplicate`. They cannot select, stop, reload, or replace the separately
running `caelestia` configuration.

`reload` requests a Quickshell soft reload and preserves the process where
supported. `restart` performs a full stop and new process launch. These are
different lifecycle operations.

The Quickshell bootstrap still has no external user configuration.
`config-status` reports its built-in schema-one defaults. Phase 1 slice 1 adds
the standalone `franken-config-helper` Rust binary under
`helpers/franken-config-helper/`; no QML `ConfigService` invokes it yet.

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
