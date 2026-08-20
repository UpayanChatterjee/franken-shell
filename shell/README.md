# Franken Shell development shell

This directory contains the clean, non-owning Franken Shell bootstrap and the
Phase 1 configuration, theme, readiness, surface-coordination,
monitor-normalization, shell-IPC, and command-registry services. It is selected
by its explicit repository path and is independent from the live Caelestia
configuration at
`~/.config/quickshell/caelestia`.

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
./dev/franken-shell mock-healthy
./dev/franken-shell mock-required-failure
./dev/franken-shell stop
./dev/franken-shell restart
./dev/franken-shell reload
./dev/franken-shell config-reload
./dev/franken-shell logs
./dev/franken-shell diagnostics
./dev/franken-shell readiness
./dev/franken-shell capabilities
./dev/franken-shell service-status
./dev/franken-shell errors
./dev/franken-shell theme-status
./dev/franken-shell ipc-version
./dev/franken-shell ipc-diagnostics
./dev/franken-shell close-transients
./dev/franken-shell toggle-control-center
./dev/franken-shell config-status
./dev/franken-shell verify-baseline
./dev/franken-shell check
./dev/franken-shell config-helper-build
./dev/franken-shell config-helper-test
./dev/franken-shell config-helper-client-test
./dev/franken-shell config-snapshot-check
./dev/franken-shell config-snapshot-test
./dev/franken-shell core-state-check
./dev/franken-shell core-state-test
./dev/franken-shell theme-check
./dev/franken-shell theme-test
./dev/franken-shell surface-check
./dev/franken-shell surface-test
./dev/franken-shell shell-ipc-check
./dev/franken-shell shell-ipc-test
./dev/franken-shell bar-host-check
./dev/franken-shell bar-host-test
./dev/franken-shell workspace-check
./dev/franken-shell workspace-test
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

The headless CI smoke runner sets `QS_NO_RELOAD_POPUP=1` so an offscreen soft
reload does not wait for an interactive reload confirmation surface. Ordinary
development commands leave Quickshell's reload UI policy unchanged.

## Core readiness and diagnostics

The root shell owns one `CapabilityRegistry`, one `DiagnosticRegistry`, and one
`ShellState`. Existing services feed a private readiness coordinator; views and
IPC methods consume the resulting snapshots rather than deriving parallel
health state.

Readiness advances through `Bootstrapping`, `ConfigLoaded`,
`CoreServicesReady`, `SurfacesReady`, and `OptionalIntegrationsReady`. Missing
optional capabilities produce a usable `Degraded` state. A required capability
or required-core failure produces `Failed` with a stable failure code.
`readiness` prints the sanitized readiness summary and returns nonzero only for
`Failed`, allowing CI to wait on observable state instead of a fixed sleep.

The initial capability IDs are `hasHyprland`, `hasVicinae`, `hasOverview`,
`hasBattery`, `hasNetworkBackend`, `hasBluetoothBackend`, and
`hasAudioBackend`. Availability is reported truthfully: adapters not yet
implemented remain unavailable. Capability and service snapshots replace
atomically. Structured errors expose only approved fields, coalesce repeated
domain/code pairs, and retain at most 128 active records.

`mock-healthy` and `mock-required-failure` are test-only readiness fixtures.
Ordinary `mock` remains the degraded, all-optional-integrations-missing
scenario. `core-state-test` covers transitions, recovery, atomic replacement,
aggregation, coalescing, redaction, and bounded retention without using live
desktop services.

## Semantic theme lifecycle

The root shell owns one `ThemeManager` and publishes one typed active semantic
snapshot. The snapshot contains colour, typography, spacing, radius, motion,
opacity, and shared metric groups. The diagnostic surface consumes that
snapshot; feature and component code must not import raw palette values.

A built-in dark or light fallback is available before optional services start.
The active typed configuration selects the fallback mode, font scale, surface
opacity, high-contrast roles, and reduced-motion durations. Dynamic mode uses
its configured fallback mode until a dynamic-colour adapter supplies a valid
candidate. Light and animated theme-transition policy remain open product
questions; the current light profile is a contract fixture and supported
explicit fallback, not an automatic mode decision.

`applyCandidate(candidate, source)` is the future adapter boundary. An adapter
must map its raw palette into the complete semantic candidate shape and finish
any external integration file writes before requesting activation. The manager
accepts only complete, typed candidates with required contrast. Rejection
retains the last valid snapshot, degrades the theme service with a stable error
code, and never publishes raw palette or adapter-private fields. This PR does
not implement the Caelestia source adapter or wallpaper generation.

`theme-status` exposes only active identity, mode, source, accessibility flags,
health, last error code, and revision. `theme-test` covers dark, light,
standard-contrast, high-contrast, and reduced-motion fixtures; invalid type,
missing-role, and contrast rejection; rapid replacement; config mapping; and
representative surface instantiation.

## Surface coordination and shell IPC

The root owns one `SurfaceCoordinator`. Callers provide a validated explicit
monitor ID and invocation context; the coordinator does not independently
choose a pointer, keyboard, primary, or fallback-monitor policy while those
product decisions remain unresolved. It owns one major transient and one
ordinary anchored-popover slot. A major opening closes the popover, same-kind
replacement is atomic, a popover is rejected while a major surface is active,
and `Escape` or close-all follows the same centralized path.

Focus-taking requests retain opaque origin-control and previous-application
tokens privately. Opening emits an acquisition handoff, closing emits one
focus-restoration handoff containing candidate validity and topology context,
and replacement emits a direct focus transfer instead of briefly restoring
application focus. This foundation does not select or execute the final
compositor focus target: exact restoration behaviour remains Q-121. Anchor
disappearance closes its popover, and owner monitor removal closes affected
transients while invalidating unsafe focus candidates.

The `shell` IPC target has a version handshake and one strict JSON request
envelope. API version 1 admits only `diagnostics`, `reloadConfig`,
`closeTransients`, and `toggleControlCenter`; unknown fields, payload
expansion, malformed JSON,
unsupported versions, and unknown operations return stable error codes. It
does not expose general command execution, arbitrary paths, backend calls, or
internal properties. `config-reload`, `ipc-diagnostics`, `close-transients`,
and `toggle-control-center` use this contract. The last operation is the stable
keyboard-origin path intended for a compositor-configured shortcut. Soft QML
reload reconstructs one root handler and coordinator; smoke tests call the
target before and after reload to reject duplicate ownership.

`surface-test` covers open, replace, close, `Escape`, anchor disappearance,
monitor removal, rapid requests, and focus handoff. `shell-ipc-test` covers
valid routing, malformed and unsupported requests, payload rejection, and
repeated safe requests.

## Fixture bar host

One `BarHostSet` creates a production `PanelWindow` for each Quickshell screen
and binds it to the corresponding normalized monitor record. Explicit
offscreen fixture modes load a `FloatingWindow` wrapper around the same bar
surface because that platform plugin has no layer-shell backend. The host owns
window geometry only; global services remain rooted once in `shell.qml`. Its
edge model centralizes orientation, inward direction, theme/config thickness,
zero-inset prototype geometry, and exclusive-zone release while
fullscreen-hidden.

The first fixture rail is a continuous semantic layout with start, flexible,
fixed-capacity context, end, and absolute-end zones. Bounded cells and the
flexible spacer keep end controls stable when fixture text changes. The same
cell delegates compose vertically and horizontally without rotating text.
Workspace behavior is controller-driven, and popover-capable fixture cells
route through one anchor-aware host per monitor. Real status adapters,
autohide, final inset geometry, and final thickness remain later roadmap work.

`bar-host-test` instantiates normal, long-text, high-text-scale, missing-item,
localized-value, maximized/fullscreen, and horizontal-edge fixtures. It asserts
protected-zone geometry; shared-host replacement and toggle; pointer and
keyboard dismissal/focus paths; workspace-selector hosting; and inward edge
placement. It writes non-blocking review screenshots when an artifact directory
is provided. `./ci/run bar` promotes this contract to its own blocking CI lane.

## Fixture workspace navigation

The bar start zone now uses controller-driven numbered and special-workspace
components. Numbered groups derive from the typed workspace range and group
size, stay independent of occupancy and application icons, and keep fixed cell
geometry across selected-state changes. Pointer, keyboard, and accumulated
high-resolution scroll input all request actions through the injected workspace
adapter. Active-number activation is a replaceable policy; the current
configuration may request overview, but the delegate does not encode that
choice.

Fixture shell modes inject deterministic workspace state. Normal production
mode intentionally uses an unavailable adapter until the normalized Hyprland
workspace service arrives in PR-012, so it does not fabricate active state or
issue backend commands from views. The special-workspace button opens
`workspace.special-selector` through `SurfaceCoordinator`; its compact selector
component is rendered by the shared popover host with the same focus and
dismissal path as the other bar fixtures. Current single-letter fixture glyphs
are placeholders, not a final icon-system decision.

## Fixture popover host

Each bar monitor owns one `PopoverHost`, while `SurfaceCoordinator` remains the
global authority for which ordinary popover is active. Bar controls expose
stable monitor-qualified anchor IDs; the host resolves the active anchor,
opens inward from the configured edge, and replaces rather than overlaps
content when another anchor is invoked. Generic fixture content deliberately
contains no real service workflows. The special-workspace selector uses the
same host.

Keyboard invocation requests focus and uses the coordinator's restoration path
on Escape. Pointer invocation, toggle, replacement, and outside dismissal share
the same close API. Production uses Quickshell's anchored `PopupWindow`; the
offscreen component harness uses a `FloatingWindow` because Qt's offscreen
platform does not support popup anchoring.

`workspace-test` covers group boundaries and alternate sizes, wrap/no-wrap,
coalesced high-resolution scrolling, active-policy unavailable/busy states,
keyboard focus across group changes, six configured special workspaces,
successful and failed toggles, multiple visible IDs, empty configuration, and
truthful unavailable/out-of-range states.

## Control-centre host primitive

One production `PanelWindow` is instantiated per resolved monitor. It anchors
to the complete monitor on the overlay layer, ignores other surfaces'
exclusive zones, reserves no zone of its own, and contains both the
owner-monitor scrim and right-attached drawer. `SurfaceCoordinator` grants
global ownership to at most one host and closes an ordinary bar popover before
the drawer opens.

Keyboard-origin opening acquires deterministic initial focus; real Wayland and
fixture evidence verifies Escape closure and one restoration handoff. Pointer
origin opening is immediately interactive but does not request keyboard focus
in this prototype. Outside scrim clicks dismiss through the same coordinator.
The injected prototype content owns a main page with five quick-control
placeholders, volume and optional brightness sliders, Notifications and Volume
Mixer tabs, and lazy Network/Bluetooth detail pages. Escape pops a detail page
before closing the drawer and restores focus to its invoker. Any ownership loss
resets to main/Notifications, deliberately dropping nested page, tab, and stale
focus state. The placeholders expose unavailable, busy, failed, active, and
inactive states without importing a backend or executing commands; real
service workflows belong to later roadmap PRs.

A separate invisible `PanelWindow` owns the configured right-edge activation
strip on each eligible monitor. It forwards explicit-time pointer samples to a
pure reveal controller, which discriminates horizontal intent, applies
configured distance and velocity thresholds, and exposes normalized progress.
The drawer transform and scrim alpha consume that progress directly. Release
settles from the current position using shared motion tokens; reversal,
cancellation, fullscreen suppression, and a narrow provisional background
close-drag rail use the same state machine. Q-020 and Q-021 remain open:
prototype activation width and thresholds are typed configuration, not final
product values.

Offscreen tests wrap the shared surface item in a `FloatingWindow`, since that
platform has no layer-shell backend. `control-center-host-test` covers
primitive geometry, pointer/keyboard focus policy, scrim dismissal, Escape,
popover replacement, major arbitration, and partial reveal integration.
`control-center-drag-test` supplies deterministic timestamps for activation
geometry, intent, distance, velocity, reversal, cancellation, fullscreen, and
close-drag cases. Navigation controller and component fixtures cover
keyboard/pointer traversal, independent placeholder states, optional brightness
reflow, detail-page focus restoration, and safe open/close reset behavior.
`./ci/run control-center` is the blocking component lane; smoke also verifies
one host/scrim owner across soft reload.

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

`config-snapshot-test` directly checks the normalized-to-typed projection
boundary: required-field and scalar validation, unknown-field projection,
deterministic command ordering, sanitized diagnostics, deep freezing, and
detached collection access. `config-snapshot-check` runs focused static checks
over the same boundary.

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
