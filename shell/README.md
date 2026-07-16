# Franken Shell development shell

This directory contains the clean, non-owning Franken Shell bootstrap and the
Phase 1 configuration, monitor-normalization, and command-registry services. It is
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
./dev/franken-shell monitor-registry-check
./dev/franken-shell monitor-registry-test
./dev/franken-shell monitor-diagnostics
./dev/franken-shell monitor-observe
./dev/franken-shell command-registry-check
./dev/franken-shell command-registry-test
./dev/franken-shell command-diagnostics
./dev/franken-shell command-demo
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

## Monitor registry

Phase 1 slice 3A adds one root-owned `MonitorRegistry`. It creates no windows
and makes no Hyprland dispatch calls. The registry coalesces Quickshell screen,
Hyprland monitor/workspace, focused-window, and configuration changes into
stable session records. Consumers use `monitors`, `monitorByRuntimeId()`,
`monitorForScreen()`, `focusedMonitor`, `focusedWindowMonitor`,
`fallbackMonitor`, and `fullscreenOnMonitor()` rather than raw Hyprland IPC
objects.

`runtimeId` values such as `monitor-1` are stable only for the lifetime of one
registry instance and must not be persisted. Persistent configuration matching
may use a composite of connector, make/model, description, and serial where
available, but connector names alone are not treated as permanent hardware
identity. Description remains an exposed matching fact rather than an identity
key by itself. The current schema has no per-monitor rules, so every connected
monitor is configured using the typed global `bar.enabled` and `bar.edge`
defaults. A private provisional bridge recognizes only the documented future
`monitors.default` and ordered `monitors.rules` shape if a later typed
`ConfigService` snapshot exposes it. There is no public mutable rule input and
the Phase 1 schema is unchanged.

Coordinate spaces are explicit:

- `logicalGeometry` is Qt device-independent geometry when a Quickshell screen
  is present, otherwise normalized Hyprland logical geometry;
- `compositorGeometry` is Hyprland logical layout geometry;
- `physicalModeDimensions` is the unscaled monitor-mode size in physical
  pixels and has no global origin;
- `scale` is the compositor scale, while `devicePixelRatio` is Qt's
  physical-to-device-independent ratio.

Hyprland transforms 0 through 7 normalize to named rotation/flipped states.
Odd quarter-turn transforms swap physical axes before logical geometry is
derived. Fullscreen comes only from the active Hyprland workspace's
`hasFullscreen` property; maximization and client geometry are ignored.

Fallback selection is deterministic and session-stable: a compositor primary
fact ranks first where available, followed by configured mapped records, then
other configured records in stable session order. This is a candidate selector
for later coordination, not a final control-centre, notification, popover, or
surface-ownership policy.

`monitor-registry-test` runs fake-screen and fake-Hyprland fixtures without
touching the real display layout. `monitor-diagnostics` returns only normalized
counts, runtime IDs, transforms, mapping health, refresh state, and backend
availability. It omits serials, model descriptions, and raw IPC objects.
`monitor-observe` is optional and read-only; it invokes `hyprctl monitors -j`
and selects a small topology summary without dispatching monitor commands.

## Command registry

Phase 1 slice 3B adds one root-owned `CommandRegistry`. Consumers can only
query stable IDs, check cached availability, execute a configured zero-parameter
command, cancel by request ID, inspect a sanitized request model, or read the
sanitized registry summary. The underlying Quickshell `Process` objects,
resolved executable paths, argument arrays, environment data, and command
output are not exposed. The fixed process-slot type is internal to the QML
module and cannot be instantiated by feature imports.

The registry atomically copies definitions from each active `ConfigService`
snapshot. Running requests keep the executable and argument array copied when
they were accepted; removed or replaced definitions affect only later
requests. Availability refresh uses one asynchronous `/usr/bin/test` probe
requiring a regular executable file over absolute paths or the fixed search
directories `/usr/local/bin`,
`/usr/bin`, and `/bin`. This is a conservative Phase 1 development policy, not
a final packaging decision or a substitute for the user's shell `PATH`. It
does not consult a shell, run the configured command, read `PATH`, or scan the
user's interactive shell environment.
Executable paths support only the configuration model's approved `$HOME`,
`$XDG_CONFIG_HOME`, `$XDG_STATE_HOME`, `$XDG_CACHE_HOME`, and
`$XDG_DATA_HOME` prefixes, with standard XDG fallbacks. Arguments remain
literal; `~`, `$PATH`, `${...}`, globs, and every other expansion form are
rejected or left uninterpreted as appropriate.

Execution uses three fixed process slots, a FIFO queue capped at 32 requests,
and a retained terminal history capped at 256 entries. Each request receives a
collision-free decimal process-lifetime ID and reports queued, starting,
running, completed, failed-to-start, timeout, cancellation, nonzero-exit, and
unavailable states.
Timeout kills the child; cancellation requests termination and escalates to a
kill after a short fixed grace period. Stdout and stderr are drained and
discarded without collection, publication, logging, or changing the command's
exit result. Each internal `Process.command` property is cleared immediately
after QProcess dispatch so Quickshell's failed-to-start fallback warning cannot
print the configured executable or argument array.

The helper rejects `detached = true`, non-empty command `environment` tables,
and every `workingDirectory` field. Tracked detached execution cannot satisfy
the required lifecycle contract, while environment and working-directory
overrides are outside this slice's approved command definition. `timeoutMs` is
copied into each accepted request and enforced by the runtime.

Snapshot replacement invalidates all queued requests from the old generation
with a structured `configurationReplaced` failure. Already-running requests
retain their copied executable, arguments, and timeout until they terminate.

Development commands are:

- `command-registry-check` for focused QML and forbidden-path checks;
- `command-registry-test` for harmless deterministic lifecycle fixtures;
- `command-diagnostics` for the sanitized live summary;
- `command-demo` for the fixed `development.commandDemo` ID only.

`command-demo` refuses to reuse an existing shell, starts a dedicated
`command-demo` mode from the fixed repository fixture, and never accepts an
executable, argument, fixture path, or arbitrary command ID from the caller.
The diagnostics IPC method rejects demo execution in every other mode.

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
