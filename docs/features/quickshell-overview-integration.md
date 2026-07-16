# Franken Shell — quickshell-overview Integration

> **Path:** `docs/features/quickshell-overview-integration.md`  
> **Status:** Implementation specification  
> **Primary phase:** Phase 7 — Adopted Component Integration  
> **Prerequisites:** Phase 1 — Core Shell Skeleton; Phase 4 — Hyprland Adapter; Phase 6 — Working Daily-Use Prototype  
> **Hardening:** Phase 10 — Multi-Monitor and Gesture Hardening; Phase 11 — Visual Polish and Accessibility  
> **Related documents:** `product-vision.md`, `design-principles.md`, `feature-map.md`, `interaction-language.md`, `visual-language.md`, `architecture.md`, `configuration-model.md`, `implementation-phases.md`, `decisions.md`, `open-questions.md`, `features/bar.md`, `features/workspaces.md`

This document specifies how Franken Shell integrates the adopted `quickshell-overview` workspace and window overview.

It defines the boundary between the main shell and the external overview process, the adapter contract, configuration and theme synchronization, invocation and focus behaviour, compatibility diagnostics, fallback behaviour, test requirements, and the conditions under which deeper integration may later be considered.

The overview is an adopted component, not a feature to be reimplemented inside Franken Shell. Codex must preserve that ownership boundary and must not resolve unresolved upstream, lifecycle, configuration, or multi-monitor questions through implementation convenience.

---

# 1. Product Role

`quickshell-overview` is Franken Shell's visual workspace and window overview layer.

It provides the spatial, preview-oriented workflow that would otherwise require substantial custom work in the main shell:

- workspace previews;
- window previews;
- keyboard and pointer navigation;
- window focusing;
- drag-and-drop between workspaces;
- special-workspace representation;
- close and dismissal behaviour;
- screencopy and preview rendering;
- its own internal layout and interaction implementation.

Franken Shell integrates the overview so that it feels like part of one product while retaining a small and replaceable coupling boundary.

The integration must be:

- optional at runtime;
- isolated from the main shell process initially;
- invoked through one documented adapter path;
- driven from Franken Shell's authoritative workspace configuration;
- synchronized with shared theme roles where upstream permits;
- usable by keyboard and pointer;
- diagnosable when absent, incompatible, or broken;
- incapable of breaking direct workspace switching;
- practical to maintain while both Quickshell and the upstream overview evolve.

The integration is not:

- a second workspace-state owner;
- a replacement for direct numbered or special-workspace switching;
- a reason to duplicate workspace definitions;
- a place to hard-code upstream IPC in bar delegates;
- an excuse to vendor the upstream project immediately;
- an implementation of screencopy inside the Franken Shell process;
- a shell-native window overview rebuilt from scratch.

---

# 2. Settled Requirements

The requirements in this section are settled unless superseded by a later decision.

## 2.1 Adoption and topology

- Franken Shell uses `quickshell-overview` rather than building a new overview.
- The initial integration runs the overview as a separate Quickshell configuration or process.
- The main shell and the overview must be able to fail independently.
- A known-working upstream revision must be pinned and recorded before Phase 7 is accepted.
- The installed or running overview version must be exposed through integration diagnostics where technically possible.
- Vendoring or in-process integration is not part of the initial implementation.
- Long-term vendoring may be revisited only for demonstrated integration, maintenance, performance, startup, or multi-monitor needs.

## 2.2 Ownership boundary

`quickshell-overview` owns:

- visual workspace previews;
- window previews;
- preview capture and texture lifetime;
- screencopy implementation;
- preview navigation;
- window focus interaction inside the overview;
- drag-and-drop of windows between workspaces;
- its internal layout;
- its internal animation and rendering implementation;
- upstream-specific keyboard and Vim-style navigation;
- its internal dismissal behaviour, subject to integration validation.

Franken Shell owns:

- overview enablement;
- invocation requests;
- shared workspace configuration;
- special-workspace definitions;
- integration configuration generation or synchronization;
- theme adaptation;
- compatibility checks;
- process and IPC health reporting;
- cross-surface coordination before invocation;
- monitor invocation context;
- user-facing failure feedback;
- fallback behaviour;
- any explicitly maintained compatibility patches if vendoring is later approved.

## 2.3 One source of truth

- Franken Shell configuration is authoritative for numbered and special workspaces.
- Users must not maintain an independent special-workspace list solely for the overview.
- Stable Franken Shell workspace IDs remain authoritative project identifiers.
- Compositor-facing names are derived from the same validated workspace definitions used by the bar and Hyprland adapter.
- Generated overview configuration is derived output, not an additional user configuration authority.
- Overview-specific generated files must be reproducible from validated Franken Shell configuration.
- Bidirectional competing ownership is forbidden.

## 2.4 Invocation and fallback

- The overview must be invokable through a dedicated keyboard path.
- A pointer path must also exist through a visible shell interaction after the relevant invocation policy is settled.
- The Phase 2/Phase 7 prototype may invoke the overview from activation of the already-active numbered workspace.
- Active-workspace click behaviour remains provisional and must not be hard-coded into delegates.
- Opening the overview closes ordinary bar popovers and the control centre through `SurfaceCoordinator`.
- Direct numbered-workspace switching remains available if the overview is absent, incompatible, busy, or has failed.
- Special-workspace toggling remains available if the overview fails.
- Franken Shell must not silently replace a failed overview with a newly built internal overview.

## 2.5 Visual integration

- The overview should use Franken Shell's wallpaper-derived dynamic colour direction where upstream integration permits.
- Theme adaptation should use semantic roles rather than direct raw wallpaper colours.
- Shared typography, spacing, geometry, focus, and motion direction should be mapped where practical without forcing an unnecessary fork.
- The overview may retain upstream-native geometry or motion where no supported integration mechanism exists.
- Visual differences are acceptable when they preserve maintainability and reliable upstream integration.
- The main shell must remain readable and functional if overview theme synchronization fails.

## 2.6 Interaction preservation

- Existing comprehensive keyboard navigation must be preserved.
- Existing pointer navigation and window dragging must be preserved.
- `Escape` and outside-click dismissal must be tested and remain predictable.
- Essential overview actions must not become gesture-only or pointer-only during adaptation.
- Integration styling must not reduce preview readability, focus visibility, hit targets, or drag affordances.

## 2.7 Failure containment

- Overview absence affects only overview invocation and preview workflows.
- An overview crash must not terminate the main shell.
- Screencopy or preview failure must not crash the main shell.
- Configuration-generation failure must not invalidate the authoritative Franken Shell configuration.
- Theme-generation failure must retain the last valid overview theme output where safe.
- Incompatible overview versions must be reported rather than invoked blindly.

---

# 3. Scope and Component Responsibilities

## 3.1 Integration feature owns

- `OverviewAdapter` state and actions;
- availability and compatibility probing;
- upstream version metadata;
- invocation de-duplication;
- process/IPC request routing;
- structured integration errors;
- generated overview configuration orchestration;
- generated overview theme orchestration;
- synchronization status;
- repair/regenerate actions;
- overview-specific diagnostics;
- overview integration fixtures and smoke tests;
- packaging metadata related to the pinned revision;
- documenting supported upstream combinations.

## 3.2 Integration feature does not own

- workspace state from Hyprland;
- numbered-workspace group calculation;
- special-workspace interaction in the bar;
- direct workspace switching;
- window preview capture;
- thumbnail textures;
- overview view delegates;
- upstream drag-and-drop implementation;
- focused-window action policy;
- global monitor discovery;
- global focus restoration;
- configuration parsing and validation;
- raw dynamic-colour generation;
- generic command execution;
- system package installation.

These belong to the Hyprland service, workspace feature, upstream overview, `MonitorRegistry`, `SurfaceCoordinator`, `ConfigService`, `ThemeManager`, `CommandRegistry`, and packaging layer.

## 3.3 Cross-component flow

Conceptual invocation flow:

```text
Bar / shortcut / Vicinae command
              ↓
WorkspaceController.requestOverview(context)
              ↓
SurfaceCoordinator.prepareExternalMajorSurface("overview")
              ↓
OverviewAdapter.open(context)
              ↓
Documented upstream IPC or process invocation
              ↓
quickshell-overview owns presentation and interaction
```

Conceptual configuration flow:

```text
Validated Franken Shell configuration
              ↓
OverviewConfigMapper
              ↓
OverviewConfigWriter / supported IPC setter
              ↓
Generated overview configuration
```

Conceptual theme flow:

```text
ThemeManager semantic roles
              ↓
OverviewThemeMapper
              ↓
OverviewThemeWriter / supported upstream mechanism
              ↓
Overview theme reload or next launch
```

No bar, workspace, settings, or Vicinae delegate may bypass the adapter and invoke upstream-specific commands directly.

---

# 4. Proposed Repository and QML Structure

The following is implementation guidance, not a requirement to create empty files prematurely.

```text
integrations/overview/
├── OverviewAdapter.qml
├── OverviewCompatibility.qml
├── OverviewProcessController.qml
├── OverviewConfigMapper.qml
├── OverviewConfigWriter.qml
├── OverviewThemeMapper.qml
├── OverviewThemeWriter.qml
├── OverviewError.qml
└── fixtures/
    └── OverviewFixtureAdapter.qml

config/integrations/overview/
├── templates/
└── generated/                  # location subject to final ownership decision

tests/integration/overview/
├── invocation.md
├── compatibility.md
├── configuration-sync.md
├── theme-sync.md
├── screencopy.md
└── multi-monitor.md
```

A compact first implementation may combine several responsibilities inside `OverviewAdapter.qml` and a small helper. Split components when upstream-specific logic, file generation, process lifecycle, or tests justify separate ownership.

## 4.1 `OverviewAdapter`

The adapter is the only integration-facing object consumed by Franken Shell features.

Responsibilities:

- expose normalized integration state;
- accept monitor-aware invocation requests;
- validate whether invocation is currently safe;
- suppress duplicate concurrent requests;
- route invocation through one supported upstream path;
- expose open, close, and toggle actions only where the upstream contract reliably supports them;
- report structured failures;
- request config and theme synchronization;
- expose compatibility and synchronization diagnostics;
- avoid importing upstream view objects into shell feature modules.

Suggested conceptual interface:

```text
provider
configuredEnabled
available
running
busy
compatible
ipcAvailable
expectedRevision
installedRevision
runtimeRevision
configurationSynchronized
themeSynchronized
lastSuccessfulInvocation
lastError
repairHint

open(invocationContext)
toggle(invocationContext)
close()
refreshAvailability()
refreshCompatibility()
regenerateConfiguration()
regenerateTheme()
restartIntegration()
```

Methods that the upstream API cannot reliably support must not be simulated deceptively. For example, do not expose a truthful-looking `close()` state if the integration cannot know whether the overview actually closed.

## 4.2 `OverviewCompatibility`

Responsibilities:

- compare the configured/pinned expected revision with installed or runtime metadata;
- verify required IPC/config capabilities;
- expose compatible, warning, incompatible, and unknown states;
- provide human-readable repair hints;
- centralize upstream-version-specific branches;
- avoid scattering version comparisons across shell QML.

Compatibility states should distinguish:

```text
Unknown
Compatible
CompatibleWithWarnings
Incompatible
Unavailable
ProbeFailed
```

An unknown version is not automatically incompatible, but must not be silently treated as fully supported.

## 4.3 `OverviewProcessController`

Use only if process lifecycle is owned or observed by Franken Shell.

Potential responsibilities:

- detect whether the overview is already running;
- launch through a structured executable-and-arguments command;
- prevent duplicate processes;
- observe exit status where possible;
- request restart;
- expose startup failure separately from IPC failure;
- respect the final startup/supervision decision.

It must not:

- use shell-concatenated command strings;
- kill unrelated Quickshell processes by broad name matching;
- assume Franken Shell always owns the external process;
- silently restart in a crash loop;
- encode a primary supervision strategy before the corresponding decision is made.

## 4.4 `OverviewConfigMapper`

Responsibilities:

- transform validated Franken Shell workspace and overview settings into the upstream schema;
- preserve stable ordering;
- map special-workspace IDs to compositor names;
- map labels and icons only where upstream supports them;
- validate generated rows/columns against the authoritative range;
- report unsupported fields rather than dropping them silently where that would alter behaviour;
- remain deterministic and unit-testable.

The mapper consumes normalized configuration objects, not the raw user file.

## 4.5 `OverviewConfigWriter`

Responsibilities where generated files are selected:

- generate complete candidate output in memory;
- validate candidate syntax where practical;
- write atomically;
- create parent directories safely;
- retain last valid generated output;
- avoid editing unrelated user-owned files destructively;
- record the source schema/project version in generated metadata where supported;
- expose last write time, output path, and error;
- support explicit regenerate/repair.

The exact output path and file format remain unresolved pending upstream research.

## 4.6 `OverviewThemeMapper` and `OverviewThemeWriter`

Responsibilities:

- map Franken Shell semantic theme roles into the subset supported by the overview;
- use the active validated theme, never unvalidated raw palette data;
- preserve contrast for preview labels and focus states;
- generate atomically;
- retain the last valid theme on failure;
- respect reduced-motion or high-contrast settings only where supported;
- expose unsupported visual roles through diagnostics during development.

The writer must not claim exact visual parity when upstream exposes only limited theming controls.

---

# 5. State and Data Requirements

## 5.1 Integration state model

The adapter should expose enough state for invocation, diagnostics, settings, and repair without exposing upstream internals.

Recommended normalized properties:

```text
provider                    # "quickshell-overview"
configuredEnabled           # user/config intent
available                   # executable/config present or reachable
running                     # known process/runtime state, nullable if unknowable
busy                        # invocation/config/theme operation in progress
compatible                  # normalized compatibility outcome
compatibilityState          # detailed enum
ipcAvailable                # required invocation endpoint reachable
expectedRevision
installedRevision
runtimeRevision
configurationSynchronized
themeSynchronized
configurationOutputPath
themeOutputPath
lastProbeAt
lastSuccessfulInvocation
lastSuccessfulConfigSync
lastSuccessfulThemeSync
lastExitCode
lastError
repairHint
```

Properties whose truth cannot be determined must permit `unknown`; do not coerce uncertainty into `false` normal state.

## 5.2 Invocation context

Every invocation request should include normalized context rather than positional assumptions.

Suggested structure:

```text
InvocationContext {
    source              # keyboard, bar, vicinae, gesture, ipc, other
    monitorId?
    screenGeometry?
    focusedWorkspace?
    focusedWindowId?
    pointerPosition?
    requestedMode?      # only if upstream supports modes
    timestamp
}
```

The adapter may reduce this to what upstream actually supports, but must keep the normalized contract so monitor policy can evolve without rewriting callers.

## 5.3 Authoritative workspace input

The mapper consumes:

- numbered minimum;
- numbered maximum;
- group size;
- wrap policy where relevant;
- optional semantic labels;
- configured overview rows and columns;
- whether special workspaces are shown;
- special-workspace stable IDs;
- compositor-facing special-workspace names;
- user-facing labels;
- icon identifiers;
- optional shortcut hints;
- any upstream-supported ordering setting.

It must not derive the special-workspace list independently from current compositor occupancy.

## 5.4 Derived configuration status

Synchronization status should be based on deterministic content identity where practical.

Possible model:

```text
authoritativeConfigRevision
generatedConfigRevision
expectedContentHash
generatedContentHash
configurationSynchronized
```

Exact hashing and metadata format are implementation choices, but the status must be testable and must not rely solely on file modification timestamps.

## 5.5 Theme input

The theme mapper should consume semantic roles such as:

```text
surface.base
surface.raised
surface.overlay
text.primary
text.secondary
accent.primary
accent.container
accent.onContainer
outline.focus
state.hover
state.selected
status.warning
status.critical
```

It may also consume shared typography, radius, spacing, and motion tokens where the upstream configuration supports them.

## 5.6 Error model

Use structured integration errors.

Suggested fields:

```text
code
stage                # probe, launch, ipc, configMap, configWrite, themeMap, themeWrite, runtime
message
technicalDetail
recoverable
repairHint
upstreamVersion
commandId?
exitCode?
timestamp
```

Do not put full arbitrary command output into normal UI. Diagnostics may expose bounded technical detail.

---

# 6. Configuration Requirements

## 6.1 Authoritative configuration section

The integration consumes the existing workspace and integration configuration
model from the typed immutable runtime snapshot published by `ConfigService`.
It does not parse TOML or invoke the Rust helper directly.

Conceptual source:

```toml
[workspaces]
special = []

[workspaces.numbered]
minimum = 1
maximum = 10
groupSize = 5
wrap = false

[workspaces.numbered.semanticLabels]

[workspaces.overview]
provider = "quickshell-overview"
openOnActiveWorkspaceClick = true
rows = 2
columns = 5
showSpecialWorkspaces = true
hideEmptyRows = false

[integrations.overview]
enabled = true
provider = "quickshell-overview"
```

The authoritative user file is
`$XDG_CONFIG_HOME/franken-shell/config.toml` under D-075. The shared
configuration and validation boundary is defined by `docs/decisions.md`,
`docs/configuration-model.md`, and `docs/architecture.md`; this specification
defines only the integration-specific mapping.

## 6.2 Derived output rules

- Generated output must not become independently user-authoritative.
- Generated output should contain a clear generated-file warning where the upstream format permits comments.
- Manual edits to generated output may be overwritten.
- The shell should avoid overwriting a pre-existing user file until ownership and migration rules are explicitly established.
- If an existing upstream configuration is discovered, migration must be deliberate: inspect, back up, map supported values, and report conflicts.
- Unknown upstream fields must not be destroyed merely because Franken Shell does not understand them unless the chosen contract declares the whole generated file shell-owned.
- Ownership mode must be explicit: whole-file generated, generated fragment/import, or IPC-managed state.

## 6.3 Synchronization timing

Configuration synchronization may occur:

- during initial integration setup;
- after a valid relevant config reload;
- through an explicit regenerate action;
- during version migration;
- before invocation only when required and sufficiently cheap.

Do not rewrite generated files on every unrelated shell state change.

Relevant changes include:

- numbered range or layout intent;
- special-workspace definitions;
- overview enablement/provider settings;
- overview-specific rows/columns;
- supported keyboard/layout options;
- theme changes for theme output only.

## 6.4 Invalid configuration

- Invalid candidate Franken Shell configuration never reaches the mapper.
- Last-valid generated overview output remains in place.
- The shell reports the authoritative config error through `ConfigService`.
- The overview adapter does not attempt partial synchronization.
- Existing direct workspace behaviour remains unaffected.

---

# 7. Theme and Visual Integration

## 7.1 Goals

The overview should feel related to Franken Shell without requiring fragile source-level coupling.

Map, where supported:

- dynamic semantic colours;
- background and raised surfaces;
- active workspace selection;
- focused-window selection;
- primary and secondary text;
- focus outlines;
- warning/error state;
- typography family or scale;
- radius and spacing direction;
- reduced-motion preference;
- high-contrast preference.

## 7.2 Limits

- Do not fork merely to match exact bar/control-centre geometry.
- Do not inject unsupported runtime patches into upstream internals.
- Do not reduce preview contrast to match an overly translucent shell surface.
- Do not use broad text replacement or source rewriting as a theme mechanism.
- Do not assume that every Franken Shell visual token has an upstream equivalent.

## 7.3 Atomic theme update

When the shell theme changes:

1. receive the new validated semantic theme;
2. map supported overview values;
3. generate candidate output;
4. validate candidate structure where practical;
5. write atomically;
6. request supported reload, or apply on next overview launch;
7. expose synchronization result.

If any step fails:

- keep the previous valid overview theme;
- mark theme synchronization degraded;
- do not revert the main shell theme;
- expose a bounded repair hint.

## 7.4 Dynamic-theme transition

The exact behaviour while the overview is already open remains upstream-dependent.

Acceptable fallbacks include:

- update immediately if supported without visible breakage;
- apply on next open;
- apply after a controlled overview restart;
- retain current overview theme until close.

The integration must report the chosen behaviour once researched rather than silently flashing or recreating the overview.

---

# 8. Keyboard and Pointer Interactions

## 8.1 Keyboard invocation

- A configurable Hyprland shortcut is the canonical fast invocation path.
- The shortcut should route through the adapter or the documented upstream IPC path selected by the integration.
- If invoked through Franken Shell IPC, the adapter receives the focused-window monitor context.
- Invocation must suppress duplicate concurrent requests.
- A successful invocation should not produce a toast or OSD.
- A failed explicit invocation produces concise actionable feedback.

The exact default key combination belongs in a later bindings document.

## 8.2 Bar invocation

The current prototype direction permits:

- inactive workspace number → direct switch;
- active workspace number → request overview.

This remains unresolved product behaviour.

Implementation requirements:

- route through `WorkspaceController.requestOverview()`;
- do not hard-code an upstream command into the workspace delegate;
- do not open the overview on pointer press before click release;
- prevent duplicate requests during rapid pointer switching;
- keep a small invocation debounce or busy guard inside the controller/adapter rather than altering pointer hit geometry;
- preserve the ability to change active-workspace behaviour later.

## 8.3 Other invocation paths

Potential paths include:

- dedicated shell IPC command;
- Vicinae extension command;
- settings/diagnostics test action;
- later gesture binding;
- optional secondary-click entry point.

All paths must converge on `OverviewAdapter`; no caller owns upstream-specific syntax.

## 8.4 Interaction inside the overview

Franken Shell must preserve upstream-supported:

- arrow and Vim-style movement;
- window focus/activation;
- workspace selection;
- pointer selection;
- drag-and-drop;
- close action where upstream provides it;
- `Escape` dismissal;
- outside-click dismissal where reliable.

Adaptation must not remove keyboard parity for pointer actions.

## 8.5 Pointer drag and window movement

- Window drag-and-drop remains owned by the upstream overview.
- Franken Shell does not intercept or mirror drag state.
- The integration must test that shared special-workspace definitions map to correct drop targets.
- Failed moves must not leave the main shell workspace state fabricated.
- Any upstream limitation should be documented as an integration capability, not patched through bar-side commands during the drag.

---

# 9. Opening, Dismissal, and Focus Behaviour

## 9.1 Pre-open coordination

Before requesting overview open:

1. resolve invocation context through `MonitorRegistry` and the caller;
2. ask `SurfaceCoordinator` to close ordinary shell popovers;
3. close the control centre;
4. close ordinary menus and tray/calendar/resource/audio surfaces;
5. leave critical prompts intact or block overview invocation according to critical-surface policy;
6. issue one adapter invocation request.

The shell should not wait for closing animations to finish before sending the overview request unless the upstream interaction demonstrably requires it.

## 9.2 Focus acquisition

When opened by keyboard:

- the overview must receive keyboard focus;
- typing and navigation must not leak to the previously focused application;
- the initial focused preview should be deterministic according to the overview's supported behaviour;
- focus must be visibly indicated independently of selection colour.

When opened by pointer:

- the pointer-triggered action should activate the overview predictably;
- keyboard focus should transfer when keyboard navigation begins or immediately if required by the upstream window primitive;
- no invisible main-shell item should retain focus.

## 9.3 Dismissal

Supported dismissal should include, where upstream permits:

- `Escape`;
- outside click;
- activating the same toggle shortcut;
- selecting/focusing a window or workspace;
- explicit close IPC.

The adapter must not claim a toggle or close operation if the upstream contract cannot support it reliably.

## 9.4 Focus restoration

After dismissal:

- focus should land on the window selected in the overview when a selection was made;
- if dismissed without selection, focus should return to the previously focused valid application where upstream/Hyprland semantics permit;
- if the previous application disappeared, Hyprland's current valid focus should be accepted;
- Franken Shell must not force focus onto a hidden bar item;
- focus restoration must not activate a stale window identity.

Because the overview is initially a separate process, the exact restoration signal may be owned by upstream or inferred through normalized Hyprland state. Do not introduce polling-heavy focus tracking solely to simulate an exact close event.

## 9.5 Competing major surfaces

- Opening the overview closes the control centre and ordinary bar popovers.
- Opening the control centre or an ordinary shell popover while the overview is open should either first close the overview through supported IPC or be suppressed according to the final major-surface policy.
- Vicinae and overview should not remain as competing primary command/navigation surfaces simultaneously unless explicitly supported and tested.
- Critical authentication, pairing, or system prompts may appear above the overview according to critical-surface policy.

The exact cross-process visibility detection required for reverse coordination remains subject to upstream capability research.

## 9.6 Fullscreen behaviour

Explicit overview invocation during fullscreen is not separately settled in the baseline.

Until resolved:

- do not make accidental pointer invocation possible solely through active-workspace click while the bar is hidden;
- keep the explicit keyboard path behind a centralized policy;
- avoid assuming that fullscreen preview capture is safe;
- test fullscreen windows, games, video, and exclusive input;
- document whether invocation is allowed, suppressed, or configurable before release.

---

# 10. Service and Integration Dependencies

## 10.1 Required shell dependencies

### `WorkspaceController`

Provides the normalized request path and authoritative workspace definitions.

### `HyprlandService` / `WorkspaceModel`

Provides current workspace/window/monitor state to Franken Shell. The overview may have its own upstream Hyprland subscriptions, but Franken Shell must not treat those as authoritative shell state.

### `SurfaceCoordinator`

Closes ordinary shell surfaces before overview invocation and coordinates major-surface policy.

### `MonitorRegistry`

Provides normalized monitor identity, geometry, focused-window monitor, pointer monitor where available, and hotplug events.

### `ConfigService`

Provides validated authoritative workspace and integration settings.

### `ThemeManager`

Provides validated semantic theme tokens.

### `CommandRegistry`

Owns structured process invocation where needed.

### `CapabilityRegistry`

Exposes overview availability and supported operations to other shell features.

### `Diagnostics`

Records compatibility, synchronization, process, and IPC health.

## 10.2 External dependencies

- pinned `quickshell-overview` source/revision;
- compatible Quickshell runtime;
- Hyprland 0.55+ target environment;
- required screencopy/Wayland support;
- documented overview IPC or invocation mechanism;
- upstream configuration and theme format;
- optional process supervision mechanism.

## 10.3 Optional integration dependencies

### Vicinae

May invoke overview through Franken Shell IPC. Vicinae absence does not affect the overview's keyboard or bar paths.

### Caelestia theme source

Provides dynamic source colours through `ThemeManager`. Its failure falls back to the current valid or built-in shell palette.

### Systemd user service or Hyprland autostart

May supervise or start the overview depending on the final lifecycle decision.

## 10.4 Dependency readiness

The adapter must tolerate startup order where:

- Franken Shell starts before the overview;
- the overview starts before Franken Shell;
- theme/config generation completes after the bar is usable;
- overview compatibility probing completes after workspace UI appears;
- the overview becomes available after startup;
- the overview exits while Franken Shell remains running;
- monitor mapping changes after hotplug;
- the dynamic theme changes while the overview is closed or open.

---

# 11. Error and Unavailable States

## 11.1 Integration disabled

- Keep all direct workspace navigation available.
- Do not run availability probes more frequently than needed.
- Hide or disable overview-specific settings/actions according to the invoking surface.
- Active-workspace activation must follow the configured fallback policy rather than appearing broken.
- Diagnostics should report `Disabled`, not `Unavailable`.

## 11.2 Overview not installed or not found

- Direct workspace switching remains functional.
- Explicit invocation produces a concise actionable error.
- The error may offer `Open Details` or setup guidance; it must not offer to build a second overview.
- The bar workspace delegate remains enabled for switching.
- Diagnostics expose the expected revision and missing executable/config condition.

## 11.3 Process not running

Behaviour depends on the final lifecycle policy:

- launch on demand if Franken Shell owns that responsibility;
- request the supervisor to start it;
- report unavailable if another component is expected to own startup.

Do not silently choose one policy before Q-081 and startup/supervision questions are resolved.

## 11.4 IPC unavailable

- Distinguish process-running/IPC-unavailable from process-not-running.
- Do not spawn duplicate processes blindly.
- Retry only through a bounded explicit reconnect policy.
- Expose expected and detected IPC capabilities.
- Preserve direct navigation.

## 11.5 Version mismatch

- Mark integration `CompatibleWithWarnings` or `Incompatible` according to the compatibility matrix.
- Block invocation only when required capabilities are missing or known unsafe.
- Do not compare only human-readable version strings when a commit/revision capability check is available.
- Provide repair guidance such as switching to the pinned revision.
- Never auto-replace user source without explicit packaging/update action.

## 11.6 Configuration out of sync

- Mark configuration synchronization degraded.
- Keep the last valid generated output.
- Do not partially rewrite files.
- Permit direct workspace actions.
- Permit overview invocation only if the stale configuration is known safe; otherwise report why invocation is blocked.
- Offer an explicit regenerate action through diagnostics/settings.

## 11.7 Configuration generation failure

- Retain authoritative Franken Shell config unchanged.
- Retain the previous valid generated overview config.
- Report the mapping or write stage.
- Do not log user secrets; workspace labels are not secret but should still be logged sparingly.
- Do not repeatedly rewrite in a tight loop.

## 11.8 Theme synchronization failure

- Keep the previous valid overview theme.
- Keep the main shell's active theme.
- Mark only the integration theme state degraded.
- Do not block invocation solely for cosmetic mismatch unless the generated output is syntactically unsafe.

## 11.9 Overview crash

- Main shell continues.
- Adapter updates running/health state where observable.
- Direct workspace switching continues.
- Do not restart in an unbounded crash loop.
- Record bounded exit metadata.
- A user-triggered next invocation may retry according to lifecycle policy.

## 11.10 Preview or screencopy failure

- The main shell must not crash.
- If upstream supports a degraded mode, use it only through supported configuration.
- Otherwise show the upstream failure or close cleanly.
- Do not duplicate screencopy in Franken Shell as an emergency fallback.
- Record failure conditions such as monitor, scale, transform, fullscreen, and GPU state without recording window contents.

## 11.11 Invocation already in progress

- Coalesce or ignore duplicate requests.
- Do not queue several launches.
- Expose `busy` only briefly and truthfully.
- A later request may toggle close only if the upstream toggle contract is confirmed.

## 11.12 Monitor removed during invocation

- Resolve a deterministic valid fallback monitor through `MonitorRegistry` if invocation has not yet been issued.
- If the overview is already open, allow upstream/Wayland to reconcile and record any failure.
- Do not retain stale monitor geometry indefinitely.
- Close or cancel shell-owned pending invocation state.

---

# 12. Multi-Monitor Considerations

Final multi-monitor ownership remains unresolved. The integration architecture must nevertheless be monitor-aware from the beginning.

## 12.1 Invocation context policy candidates

Potential final policy:

- keyboard invocation → focused-window monitor;
- pointer/bar invocation → invoking bar's monitor;
- gesture invocation → gesture/input monitor;
- Vicinae invocation → monitor associated with Vicinae or focused window;
- fallback → primary or last valid monitor.

These are candidates, not settled policy.

## 12.2 Required monitor data

Pass or derive:

- stable monitor ID/name;
- logical geometry;
- scale;
- transform/rotation;
- focused status;
- pointer association where known;
- invoking bar/surface monitor;
- current workspace on that monitor where applicable.

Do not pass raw compositor JSON throughout integration code.

## 12.3 Multiple overview instances

The initial product direction implies one logical overview interaction at a time, but upstream capability and final policy must be verified.

Do not assume:

- one process means one monitor surface;
- separate monitor windows are independently invokable;
- all monitors should show duplicate overview surfaces;
- one monitor's preview scale can be reused on another.

## 12.4 Required tests

Test at minimum:

- internal display only;
- external display only;
- two displays with equal scale;
- mixed integer/fractional scale;
- rotated display;
- different resolutions/aspect ratios;
- focused window on each monitor;
- pointer invocation from each monitor;
- monitor hotplug while overview closed;
- monitor hotplug while overview open;
- workspace/window drag across monitor-associated workspace layouts;
- fullscreen on one monitor while another remains non-fullscreen.

## 12.5 Screencopy and GPU considerations

- Test preview stability on the user's hybrid AMD/NVIDIA machine.
- Do not wake a suspended NVIDIA dGPU merely to collect shell-side diagnostics.
- Observe whether upstream preview capture wakes the dGPU and document measured behaviour.
- Test driver mismatch/failure conditions where practical.
- Do not keep duplicate preview textures or screenshots in Franken Shell.

---

# 13. Performance Considerations

## 13.1 Process isolation

The separate-process topology should contain preview crashes and heavy rendering away from the main shell.

Franken Shell should not:

- subscribe to preview frames;
- copy thumbnail textures;
- mirror upstream window models solely for previews;
- poll overview animation state at frame rate;
- keep hidden overview content alive inside the main shell.

## 13.2 Invocation latency

Measure:

- request-to-visible latency when already running;
- cold-start latency;
- config/theme synchronization overhead;
- monitor-selection overhead;
- focus acquisition latency;
- duplicate-request handling.

No exact budget is settled, but invocation should feel immediate enough to serve as a primary navigation workflow.

## 13.3 Probing cadence

- Probe availability at startup and on explicit refresh.
- Re-probe after known process exit or configuration change.
- Avoid frequent filesystem/process polling.
- Use process signals, IPC health, or supervisor state where available.
- Slow periodic health checks may be used only when no event-driven mechanism exists.

## 13.4 Configuration and theme writes

- Debounce relevant config changes.
- Coalesce rapid theme updates, such as wallpaper-generation intermediate states.
- Write only when generated content changes.
- Use atomic replacement.
- Do not block the QML UI thread on file generation or external commands.

## 13.5 Preview performance boundary

Performance inside the overview remains upstream-owned, but Franken Shell integration acceptance must measure:

- frame pacing while opening/closing;
- preview updates during rapid window creation/destruction;
- memory growth across repeated invocations;
- GPU use while closed;
- CPU use while closed;
- behaviour with fullscreen windows;
- mixed-DPI texture behaviour;
- suspended NVIDIA dGPU behaviour;
- recovery after screencopy failure.

## 13.6 Hidden-state resource use

When the overview is closed:

- no shell-side preview polling occurs;
- no shell-side high-frequency timer exists for the integration;
- config/theme generators remain idle;
- compatibility probing remains low frequency;
- upstream closed-state resource use is measured and recorded.

---

# 14. Security, Privacy, and File-Safety Requirements

- Do not log window preview images or pixel data.
- Do not persist screenshots through Franken Shell.
- Do not expose window titles in default logs unless required for a bounded debug mode.
- Do not execute generated shell command strings.
- Invoke executables with structured arguments through `CommandRegistry`.
- Do not overwrite arbitrary paths from user configuration.
- Restrict generated output to approved integration paths.
- Resolve XDG variables through approved path expansion, not arbitrary shell expansion.
- Write atomically and create backups before taking ownership of an existing file.
- Preserve upstream attribution and licence requirements if files or code are copied or vendored later.
- Do not vendor source before recording the revision, licence, local patches, and update strategy.
- Do not allow overview IPC to become a general arbitrary-command endpoint.

---

# 15. Fixtures and Test States

Fixtures must not require a live overview process.

## 15.1 Adapter state fixtures

Provide at least:

1. integration enabled, available, compatible, IPC ready;
2. integration disabled;
3. executable/config absent;
4. process running, IPC unavailable;
5. compatible pinned revision;
6. compatible with warning;
7. incompatible revision;
8. version unknown;
9. availability probe failed;
10. invocation busy;
11. invocation success;
12. invocation failure;
13. process crash after open;
14. config synchronized;
15. config stale;
16. config mapping failure;
17. config write failure;
18. theme synchronized;
19. theme stale;
20. theme mapping failure;
21. theme write failure;
22. repair hint present and absent.

## 15.2 Configuration fixtures

Provide at least:

1. numbered `1–10`, rows `2`, columns `5`;
2. numbered `1–15`;
3. partial final row;
4. group size differing from overview columns;
5. six special workspaces;
6. empty special-workspace list;
7. long labels;
8. missing optional icons;
9. duplicate stable ID rejected by authoritative config;
10. duplicate compositor name rejected or reported;
11. semantic labels enabled;
12. semantic labels absent;
13. special-workspace display disabled;
14. hide-empty-rows true and false;
15. unsupported upstream field mapping;
16. deterministic regeneration with identical input.

## 15.3 Invocation fixtures

Provide at least:

1. keyboard invocation on monitor A;
2. bar invocation on monitor B;
3. Vicinae invocation without monitor context;
4. duplicate requests within debounce/busy window;
5. invocation while a popover is open;
6. invocation while control centre is open;
7. invocation while a critical prompt is open;
8. invocation during true fullscreen;
9. active-workspace click prototype path;
10. overview unavailable fallback;
11. monitor removed before request dispatch;
12. monitor removed after dispatch.

## 15.4 Theme fixtures

Provide at least:

- dark dynamic palette;
- light palette if supported;
- fallback palette;
- high-contrast mode;
- reduced-motion mode;
- missing optional semantic role;
- invalid generated theme candidate;
- rapid wallpaper/theme updates;
- theme change while overview open;
- theme change while overview closed.

## 15.5 Manual upstream smoke tests

Once a revision is pinned, test:

- open through documented IPC;
- close/toggle behaviour;
- keyboard navigation;
- Vim-style navigation where supported;
- pointer focus;
- drag window between numbered workspaces;
- drag window to special workspace;
- close window behaviour where supported;
- `Escape` dismissal;
- outside click;
- rapid window creation/destruction;
- fullscreen preview;
- mixed scale;
- rotation;
- multi-monitor;
- repeated open/close memory use;
- process restart;
- incompatible config;
- screencopy failure.

---

# 16. Implementation Phases

## 16.1 Phase 1 — Core prerequisites

Before overview integration work:

- `ConfigService` exposes validated workspace definitions;
- `ThemeManager` exposes semantic roles;
- `MonitorRegistry` exposes normalized invocation context;
- `SurfaceCoordinator` can close ordinary shell surfaces;
- `CommandRegistry` can run structured asynchronous commands;
- `CapabilityRegistry` and `Diagnostics` exist;
- shell IPC can expose a versioned overview request later.

## 16.2 Phase 2 / Phase 6 — Placeholder boundary

Before the real integration:

- workspace pager uses fixture overview state;
- active-workspace activation routes through a controller policy;
- direct switching works independently;
- invocation failures can be represented without a live upstream component;
- no upstream-specific command exists in workspace delegates.

## 16.3 Phase 7A — Upstream research and pinning

Resolve and document:

- exact repository and revision;
- licence and attribution obligations;
- Quickshell compatibility;
- Hyprland compatibility;
- documented IPC invocation;
- process lifecycle expectations;
- configuration format and supported fields;
- theme mechanism;
- multi-monitor capability;
- screencopy requirements;
- known limitations.

Outputs:

- pinned revision;
- compatibility note/matrix;
- invocation contract;
- config/theme ownership recommendation;
- open-question resolutions or updated unresolved items.

Do not implement speculative command strings before this subphase.

## 16.4 Phase 7B — Adapter and invocation

Implement:

- `OverviewAdapter` fixture and real implementation;
- availability probe;
- compatibility state;
- documented invocation path;
- duplicate-request guard;
- structured errors;
- `SurfaceCoordinator` pre-open coordination;
- direct-switch fallback;
- diagnostic state;
- shell IPC action for overview invocation.

## 16.5 Phase 7C — Shared configuration

After Q-082 is resolved, implement one of:

- generated whole-file config;
- generated imported fragment;
- supported IPC setters;
- another approved one-way mechanism.

Complete:

- deterministic mapper;
- atomic writer or setter adapter;
- synchronization status;
- regeneration action;
- backup/migration policy;
- tests proving the bar and overview consume the same special-workspace definitions.

## 16.6 Phase 7D — Theme integration

Implement the deepest supported non-fork integration:

- semantic role mapping;
- atomic output;
- last-valid fallback;
- theme synchronization diagnostics;
- high-contrast and reduced-motion mapping where supported;
- representative dynamic-theme tests.

Do not fork solely for exact geometry parity.

## 16.7 Phase 7E — Daily-use validation

Validate:

- keyboard and pointer invocation;
- active-workspace prototype path;
- focus acquisition/dismissal;
- direct switching after overview failure;
- special-workspace consistency;
- process restart;
- no duplicate overview processes;
- one full day of use;
- idle and invocation performance measurements.

## 16.8 Phase 10 — Multi-monitor and screencopy hardening

Resolve and implement:

- final invocation monitor policy;
- one versus multiple overview surfaces;
- hotplug behaviour;
- mixed scale;
- rotation;
- fullscreen interactions;
- hybrid-GPU behaviour;
- screencopy failure fallback;
- gesture invocation if later adopted.

## 16.9 Phase 11 — Visual and accessibility polish

Validate:

- theme coherence without a fragile fork;
- focus contrast;
- text scaling;
- high contrast;
- reduced motion;
- preview labels;
- hit targets;
- selection not relying solely on colour;
- motion not delaying interaction.

## 16.10 Phase 12 — Packaging and release hardening

Complete:

- pinned source/revision packaging;
- startup/supervision policy;
- generated config/theme installation paths;
- clean uninstall behaviour;
- update and rollback notes;
- compatibility diagnostics;
- attribution/licence files;
- repair documentation;
- smoke tests against supported Quickshell and Hyprland versions.

---

# 17. Acceptance Criteria

## 17.1 Adapter acceptance

The adapter is accepted when:

- all shell callers use `OverviewAdapter` rather than upstream-specific commands;
- availability, compatibility, IPC, config sync, theme sync, busy, and error states are exposed;
- unknown state is distinguishable from unavailable state;
- invocation requests are de-duplicated;
- errors are structured and actionable;
- the main shell remains usable without the overview;
- no blocking external command runs on the UI thread.

## 17.2 Invocation acceptance

Invocation is accepted when:

- a documented keyboard path opens the overview;
- the selected pointer path opens it after the relevant policy is settled or during the documented prototype;
- ordinary shell popovers and control centre close before opening;
- keyboard focus enters the overview;
- `Escape` and selection dismissal behave predictably;
- repeated rapid requests do not start duplicate processes or windows;
- failed invocation leaves direct switching functional;
- a concise error is shown only for explicit failed user actions.

## 17.3 Shared-configuration acceptance

Configuration integration is accepted when:

- Franken Shell remains the only authoritative workspace configuration;
- numbered range/layout intent is derived correctly;
- special-workspace IDs and compositor names match the bar and Hyprland adapter;
- users do not maintain a second special-workspace list;
- generated output is deterministic;
- writes are atomic;
- existing user-owned files are not destroyed without an explicit ownership/migration decision;
- stale or failed synchronization is visible in diagnostics;
- invalid Franken Shell config does not replace last-valid generated output.

## 17.4 Theme acceptance

Theme integration is accepted when:

- overview colours derive from validated semantic roles;
- focus and preview text remain readable;
- dynamic-theme failure does not affect main-shell theme activation;
- last-valid overview theme remains available;
- supported high-contrast and reduced-motion mappings are applied;
- unsupported parity limits are documented rather than hidden;
- no source-level fork is maintained solely for cosmetic precision.

## 17.5 Reliability acceptance

The integration is accepted for daily use when:

- a known-working revision is pinned;
- compatibility status is visible;
- the overview may crash without crashing Franken Shell;
- direct numbered and special workspace actions continue after failure;
- process restart or later invocation recovers according to policy;
- screencopy failure does not crash the main shell;
- one full day of use has no blocker-level integration issue;
- idle CPU/memory and repeated invocation memory behaviour are recorded.

## 17.6 Multi-monitor acceptance

After the final policy is settled:

- keyboard invocation opens on the documented monitor;
- pointer/bar invocation opens on the documented monitor;
- hotplug is handled deterministically;
- mixed scale and rotation are usable;
- fullscreen on one monitor does not cause undefined placement on another;
- special-workspace and window movement targets remain correct;
- no integration component assumes a single monitor internally;
- preview failure on one monitor does not crash the main shell.

## 17.7 Release acceptance

Before stable release:

- upstream revision and licence are recorded;
- supported Quickshell/Hyprland combinations are documented;
- configuration/theme generation is reproducible;
- update and rollback paths exist;
- uninstall removes generated package-owned integration files without deleting user-owned authoritative config;
- diagnostics identify expected and detected versions;
- repair guidance covers missing, incompatible, unsynchronized, and crashing states.

---

# 18. Unresolved Questions

The following remain unresolved and must not be silently settled during implementation.

## 18.1 Q-081 — Standalone versus vendored long-term

Initial topology is standalone.

Revisit based on measured:

- theme limitations;
- configuration duplication;
- startup latency;
- crashes;
- IPC stability;
- multi-monitor fixes;
- maintenance patch requirements;
- duplicated service/resource cost.

Vendoring requires a new recorded decision. Repository self-containment alone is not sufficient justification.

## 18.2 Q-082 — Shared configuration mechanism

Choose exactly one one-way mechanism:

- generated whole-file overview config;
- generated imported fragment;
- shared imported data file;
- supported IPC setters;
- vendored shared QML module after a later vendoring decision;
- another researched upstream-supported mechanism.

Need to settle:

- output schema;
- output path;
- ownership of existing upstream config;
- preservation of unknown fields;
- reload behaviour;
- failure recovery;
- settings requiring overview restart;
- whether semantic workspace labels affect overview presentation.

## 18.3 Q-083 — Live preview stability

Research and test:

- rapid window changes;
- window close during capture;
- fullscreen windows;
- mixed scale;
- rotation;
- multiple monitors;
- suspended NVIDIA GPU;
- hybrid AMD/NVIDIA rendering;
- repeated open/close resource use;
- capture failure recovery.

Need an explicit fallback if upstream previews crash, leak, or become unusable. The fallback must not be an unplanned Franken Shell screencopy implementation.

## 18.4 Q-084 — Invocation from the bar

Settle:

- whether active-workspace primary click opens overview;
- whether secondary click is preferable;
- keyboard activation parity;
- discoverability;
- accidental activation during rapid workspace switching;
- debounce/busy semantics;
- behaviour while the bar is hidden in fullscreen.

The prototype may use active-workspace primary click through a controller policy.

## 18.5 Exact upstream revision and compatibility contract

Need to decide:

- pinned commit/tag;
- supported minimum revision if any;
- required Quickshell version;
- required Hyprland version;
- capability detection;
- version handshake;
- compatibility matrix ownership;
- update cadence.

## 18.6 Exact IPC and process lifecycle

Need to research:

- documented open/toggle/close endpoints;
- whether invocation starts a process or communicates with a resident process;
- how running state is detected;
- whether Franken Shell, systemd, Hyprland autostart, or upstream owns startup;
- duplicate-instance prevention;
- crash restart policy;
- reload behaviour;
- how to avoid broad process-name matching.

## 18.7 Theme integration depth

Need to determine:

- supported colour fields;
- font support;
- radius/spacing support;
- focus-state customization;
- motion/reduced-motion support;
- live reload;
- whether generated theme files are separate from main config;
- acceptable visual mismatch without a fork.

## 18.8 Opening during fullscreen

Need explicit policy for:

- keyboard invocation during true fullscreen;
- invocation from another monitor while one monitor is fullscreen;
- preview capture of fullscreen games/video;
- exclusive input and focus;
- user-configurable override.

## 18.9 Multi-monitor ownership

Need to settle:

- one global overview versus one per monitor;
- keyboard invocation monitor;
- bar invocation monitor;
- Vicinae invocation monitor;
- gesture invocation monitor;
- behaviour when monitor context cannot be passed upstream;
- hotplug while open;
- special-workspace representation across monitors.

## 18.10 Focus and reverse surface coordination

Need to determine:

- reliable overview-open/closed signal;
- whether Franken Shell may close the overview before opening control centre/Vicinae;
- whether upstream exposes selected-window result;
- exact focus restoration ownership;
- behaviour when the overview crashes while focused.

## 18.11 Cross-cutting blockers

The following broader unresolved items affect complete integration:

- **Q-001:** exact Quickshell baseline;
- **Q-006:** startup and supervision model;
- final monitor identity matching;
- final icon strategy;
- QML/integration test tooling;
- package and rollback strategy.

Adapter interfaces and fixtures may be implemented before these are resolved. Upstream-specific assumptions must not leak into bar or workspace views.

---

# 19. Codex Implementation Guardrails

Codex must not:

- rebuild quickshell-overview in Franken Shell;
- import upstream preview delegates into the main shell during the initial topology;
- vendor the project without a recorded decision;
- maintain separate workspace definitions for the overview;
- treat generated overview files as authoritative user config;
- hard-code speculative IPC, CLI, deeplink, or file paths;
- invoke upstream commands directly from bar/workspace delegates;
- spawn a new process for every invocation without duplicate detection;
- kill broad Quickshell process groups to close the overview;
- poll process lists or files at high frequency;
- duplicate screencopy or preview textures in the main shell;
- wake the NVIDIA GPU through shell-side preview polling;
- block direct workspace switching when integration fails;
- hide version mismatch or synchronization failure behind a normal-looking state;
- overwrite existing user overview configuration before ownership and backup rules are settled;
- apply partial generated configuration after a mapping error;
- revert the main shell theme because overview theming failed;
- fork solely for pixel-perfect geometry;
- remove keyboard or pointer functionality during visual adaptation;
- assume one monitor internally;
- silently decide active-workspace click, fullscreen invocation, startup supervision, or long-term topology;
- log preview images, window contents, or unbounded window-title data;
- run blocking external commands on the QML UI thread.

Codex should:

- begin with a fixture adapter;
- keep all callers behind `OverviewAdapter`;
- keep generated mappings deterministic;
- centralize version-sensitive behaviour;
- use structured commands and errors;
- preserve direct navigation as the fallback;
- add upstream research findings to `decisions.md` or `open-questions.md`;
- measure behaviour before promoting prototype assumptions to accepted requirements;
- preserve upstream attribution and maintain a clear update path.
