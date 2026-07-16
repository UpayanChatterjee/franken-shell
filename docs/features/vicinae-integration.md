# Franken Shell — Vicinae Integration

> **Path:** `docs/features/vicinae-integration.md`
> **Status:** Implementation specification
> **Primary phase:** Phase 7 — Adopted Component Integration
> **Related specifications:** `bar.md`, `control-centre.md`, `workspaces.md`, `calendar.md`, `resource-monitor.md`, `power-and-auto-cpufreq.md`, `session-and-lock.md`, `multi-monitor.md`

This document specifies the command-layer integration between Franken Shell and Vicinae. Vicinae is the launcher and command interface; Franken Shell must not build a competing launcher.

---

# 1. Product Role

Vicinae provides root search, application launching, search domains, and extension commands. Franken Shell provides a visible bar entry point, normalized invocation, theme/configuration derivation, diagnostics, and versioned shell IPC for a first-party extension.

The integration is first-class in the product experience and optional at runtime. Its absence must not stop the bar, control centre, workspaces, or other shell services.

# 2. Settled Requirements

- Vicinae completely replaces a shell-native launcher and command interface.
- The resting bar ends with a visible Vicinae entry point.
- Primary activation requests Vicinae's root-search toggle through the adapter; the exact supported invocation remains Q-077.
- Secondary activation opens configured direct entries such as clipboard, windows, files, and shell commands.
- Exact commands, deep links, and extension APIs must be researched before implementation.
- Supported public interfaces are preferred; Franken Shell must not depend on undocumented Vicinae internals.
- The shell remains one main Quickshell instance; Vicinae remains a separate process.
- The adapter uses `CommandRegistry`, `CapabilityRegistry`, `Diagnostics`, and `SurfaceCoordinator`.
- Franken Shell configuration is authoritative. Generated Vicinae theme or command data is derived, marked as generated, validated, and written atomically.
- The first-party extension controls Franken Shell through versioned shell IPC and never edits shell files directly.
- Geometry and motion may remain Vicinae-native. Exact visual matching is not a reason to fork Vicinae.
- Failure is local and produces an actionable toast or explanation; it never triggers creation of a fallback launcher.

# 3. Scope and Ownership

## 3.1 This feature owns

- Vicinae availability and version probing;
- conceptual root and direct-entry invocation;
- the bar item's invocation controller and direct-entry model;
- the opening request, invocation context, and adapter-side handoff state consumed by `SurfaceCoordinator`;
- generated theme/configuration output owned by Franken Shell;
- shell IPC compatibility exposed to the first-party extension;
- integration health and repair diagnostics.

## 3.2 This feature does not own

- application discovery, ranking, search UI, clipboard history, file search, or window search;
- workspace, control-centre, notification, calendar, power, resource, or session state;
- raw external command execution from QML views;
- a second configuration source inside the extension;
- Vicinae process internals or unsupported geometry customization.
- global surface conflict resolution, monitor ownership, dismissal, or focus restoration policy.

# 4. Proposed Structure

```text
integrations/vicinae/
├── VicinaeAdapter.qml
├── VicinaeCompatibility.qml
├── VicinaeConfigMapper.qml
├── VicinaeThemeMapper.qml
├── VicinaeDirectEntryModel.qml
└── fixtures/VicinaeFixtureModel.qml

features/bar/
└── VicinaeItem.qml
```

Create only the separation justified by the final implementation. Views render normalized state and request adapter actions.

`VicinaeAdapter` owns probing and supported external invocation through `CommandRegistry`; the integration controller prepares bar/menu state and requests coordination; the bar/menu views only render and forward intent.

# 5. State and Adapter Contract

The controller should expose presentation-ready state:

```text
enabled
availability: Disabled | Probing | Ready | Degraded | Unavailable | Failed
installedVersion
expectedVersion
compatible
rootInvocationAvailable
directEntries[]
extensionAvailable
ipcVersion
themeSyncState
configSyncState
lastError
```

Each direct entry requires a stable ID, localized label, icon, availability, and command-registry target. Suggested conceptual actions:

```text
toggleRoot(invocationContext)
invokeEntry(entryId, invocationContext)
probe()
regenerateDerivedFiles()
```

The exact CLI/deep-link strings are not part of this contract until Q-077 is resolved.

# 6. First-Party Extension Contract

The extension may request:

- open or toggle the control centre;
- open Notifications;
- toggle DND, Night Light, or idle inhibitor;
- switch numbered or toggle special workspaces;
- open calendar, resources, or power;
- lock the session.

Requests carry an IPC version, action ID, optional normalized monitor ID, and bounded typed arguments. The shell validates every action and returns structured success or error data. The IPC must not expose arbitrary commands, file writes, notification contents, secrets, or unrestricted backend access.

# 7. Interaction

- Primary click, bar keyboard activation, or the configurable Vicinae shortcut requests the same root-search toggle action.
- Secondary click opens the shell-owned direct-entry menu.
- Middle-click has no default action.
- Scroll has no default action.
- Hover shows a tooltip and may pre-highlight; it must not launch or probe repeatedly.
- Drag has no feature action.
- The direct-entry menu supports arrows, `Home`, `End`, activation, type-ahead where practical, and `Escape`.
- Unsupported entries are omitted; temporarily failed entries may remain with an explanation and Retry.

The bar item and menu use shared semantic tokens, visible keyboard focus, accessible names, and reduced-motion-safe transitions. Availability and failure must not rely on colour alone.

# 8. Opening, Dismissal, and Focus

Before invocation, `SurfaceCoordinator` closes ordinary bar popovers and the control centre, records the source monitor and prior application focus, and marks Vicinae as the competing major surface.

Repeated activation follows the verified Vicinae toggle semantics. The shell must not guess whether an unsupported invocation is open. When Vicinae closes, focus restoration follows the shared coordinator contract where observable; otherwise the adapter records that restoration is delegated to Vicinae/compositor behaviour.

Whether invocation is allowed during true fullscreen remains unresolved. Failure to open must restore focus and show one keyed failure toast.

Keyboard focus acquisition and initial selection inside Vicinae are delegated to Vicinae. Pointer invocation must not leave an invisible Franken Shell menu focused after handoff. `Escape` and outside-click dismissal of Vicinae itself remain Vicinae-owned; the shell owns dismissal only for its direct-entry menu.

The direct-entry menu closes on outside click or `Escape` and restores focus to the Vicinae bar item. Activating an entry closes the menu before handoff unless the verified Vicinae interface requires another observable sequence.

# 9. Dependencies and Configuration

Required shell dependencies:

- `SurfaceCoordinator`, `MonitorRegistry`, `CommandRegistry`;
- `CapabilityRegistry`, `Diagnostics`, `ConfigService`, `ThemeManager`;
- versioned shell IPC and feature controllers called by the extension.

Configuration may enable integration, theme sync, extension support, and an ordered direct-entry menu. Command examples in `configuration-model.md` are placeholders, not verified APIs.

# 10. Error and Unavailable States

- **Disabled:** invocation is unavailable and diagnostics remain inspectable. Whether the configured bar affordance is omitted or retained with explanation is part of Q-080.
- **Executable absent:** activation explains that Vicinae is unavailable; no replacement launcher appears.
- **Version unknown or mismatched:** safe supported actions may remain; incompatible actions are disabled with details.
- **Invocation failure or timeout:** restore focus, retain shell usability, and show Retry/Open Details.
- **Extension absent or IPC mismatch:** root search remains usable; extension-only commands are unavailable.
- **Theme/config generation failure:** retain the last valid generated output and shell theme.
- **Vicinae crash:** clear in-flight state without closing unrelated shell surfaces.

# 11. Multi-Monitor and Performance

Invocation carries an explicit origin. `SurfaceCoordinator` resolves ownership using normalized `MonitorRegistry` data and the active policy in `multi-monitor.md`; the feature view does not choose a monitor.

Probing must be bounded and cached. Do not poll per frame or on hover. Regenerate derived files only when relevant validated configuration or theme values change, with debouncing and atomic replacement.

# 12. Fixtures

- ready compatible installation;
- absent executable;
- incompatible/unknown version;
- root available but direct entry unavailable;
- extension missing and IPC mismatch;
- invocation timeout/failure;
- theme generation failure with last-known-good output;
- pointer and keyboard invocation on different monitors;
- true-fullscreen invocation request.

# 13. Implementation Phases

1. **Phase 2 placeholder:** fixture-driven bar item and adapter boundary; no speculative commands.
2. **Phase 6 daily-use entry:** the bar item exposes unavailable/placeholder state without creating a competing launcher.
3. **Phase 7 research:** resolve supported APIs, pin compatibility, and define process/IPC lifecycle.
4. **Phase 7 integration:** root invocation, direct entries, diagnostics, and local failure handling.
5. **Phase 7 extension/theme:** versioned extension commands and atomic theme/config derivation.
6. **Phase 10/11 hardening:** final monitor ownership, focus restoration, accessibility, and visual polish.
7. **Phase 12:** packaging, extension installation, upgrade, and rollback checks.

# 14. Acceptance Criteria

- No shell-native launcher or command search is introduced.
- Root search works through a verified supported Vicinae interface.
- Bar activation and the configurable shortcut request the same adapter action.
- Secondary activation exposes only configured, available direct entries.
- Opening Vicinae closes conflicting ordinary shell surfaces.
- Closing the direct-entry menu restores focus to the invoking bar item; failed Vicinae handoff restores the previous application focus.
- With Vicinae absent, crashed, or incompatible, the bar, control centre, workspace actions, and diagnostics remain operable.
- The extension controls only versioned allowlisted shell actions.
- Generated data is one-way from Franken Shell configuration and updates atomically.
- Invocation and failure states are keyboard accessible and diagnostically visible.
- Pointer and keyboard requests carry a normalized monitor origin.

# 15. Unresolved Questions

- **Q-001:** exact Quickshell baseline where it affects IPC/process facilities.
- **Q-077:** exact supported Vicinae invocation, deep-link, version, and theme APIs.
- **Q-078:** extension runtime, packaging, command names, IPC client, and handshake.
- **Q-079:** visual integration depth without a fork.
- **Q-080:** exact absent-Vicinae UX; no option may become a competing launcher.
- Exact process lifecycle, close observability, fullscreen policy, and final multi-monitor ownership remain implementation questions.

# 16. Codex Implementation Guardrails

- Do not hard-code placeholder commands from `configuration-model.md`.
- Do not implement launcher/search providers in QML.
- Do not let the extension edit shell configuration or call arbitrary commands.
- Do not fork Vicinae for geometry parity.
- Do not let integration failure block shell startup.
