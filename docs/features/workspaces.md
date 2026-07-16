# Franken Shell — Workspaces and Focused-Window Actions

> **Path:** `docs/features/workspaces.md`  
> **Status:** Implementation specification  
> **Primary phases:** Phase 2 — Bar Foundation; Phase 4 — Core System Adapters  
> **Daily-use completion:** Phase 6 — Working Daily-Use Prototype  
> **Adopted integration:** Phase 7 — quickshell-overview Integration  
> **Focused-window actions:** Phase 8 — Power, Calendar, and Deeper Utilities  
> **Related documents:** `product-vision.md`, `design-principles.md`, `feature-map.md`, `interaction-language.md`, `visual-language.md`, `architecture.md`, `configuration-model.md`, `implementation-phases.md`, `decisions.md`, `open-questions.md`, `features/bar.md`

This document specifies Franken Shell's numbered-workspace navigation, special-workspace access, workspace-facing controller state, quickshell-overview invocation boundary, and focused-window action surface.

It converts settled product and architecture decisions into an implementation contract for Quickshell/QML while keeping unresolved activation, overview, focused-window entry-point, shared-configuration, and multi-monitor questions explicit. Codex must not resolve those questions merely because one interaction or backend path is easier to implement.

---

# 1. Product Role

Workspaces are Franken Shell's primary spatial navigation system.

The feature supports a workflow in which numbered workspaces are stable semantic locations rather than transient occupied slots. The user should be able to remember that a number corresponds to a recurring activity without the shell continually rearranging or decorating that number according to current occupancy.

The workspace feature provides:

- a compact numbered-workspace pager in the persistent bar;
- one adaptive bar control for all configured special workspaces;
- direct keyboard and pointer workspace switching;
- an invocation boundary for the adopted `quickshell-overview` component;
- normalized workspace and focused-window state for shell features;
- a compact, summonable focused-window action surface;
- one authoritative workspace definition model shared with Hyprland integration, Vicinae, quickshell-overview, settings, and diagnostics.

The feature must feel:

- spatially stable;
- immediate;
- keyboard-first;
- pointer-complete;
- quiet at rest;
- independent of workspace occupancy;
- resilient when the overview integration is unavailable;
- practical for Quickshell/QML and Hyprland 0.55+.

The feature is not:

- an application dock;
- a taskbar;
- a window-thumbnail overview implementation;
- a replacement for `quickshell-overview`;
- a place for permanent active-window titles;
- an owner of raw Hyprland dispatcher syntax;
- a second authoritative workspace configuration.

---

# 2. Settled Requirements

The requirements in this section are settled unless a later decision explicitly supersedes them.

## 2.1 Numbered-workspace model

- Numbered workspaces are stable semantic locations.
- Workspace meaning does not depend on whether a workspace is currently occupied.
- The persistent bar displays exactly one contiguous group of numbered workspaces.
- Default group size is `5`.
- Typical visible groups are `1–5`, `6–10`, `11–15`, and so on.
- The visible group follows the active numbered workspace.
- Activating workspace `7`, for example, makes the visible group `6–10`.
- Workspace numbers remain visible even when a workspace is empty.
- Occupancy markers are not shown.
- Application icons are not shown in the pager.
- Active-window title is not shown in the persistent bar.
- Optional semantic labels may appear in tooltips, settings, diagnostics, or expanded surfaces, but not as permanent pager labels.
- The initial default numbered range is configuration-driven; example configuration uses `1–10`.
- The user configuration remains authoritative for minimum, maximum, group size, wrapping policy, and optional semantic labels.

## 2.2 Numbered-workspace actions

- Primary click on an inactive workspace number switches directly to that workspace.
- Scrolling over the pager moves through numbered workspaces one at a time.
- Crossing a group boundary updates the visible group.
- Direct Hyprland number bindings remain the fastest keyboard path.
- The pager itself is keyboard-focusable and supports directional navigation and activation.
- Active-workspace primary-click behaviour is not finally settled.
- The Phase 2 prototype may route active-workspace activation to quickshell-overview.
- That behaviour must be implemented through a controller policy/action rather than hard-coded into the workspace delegate.
- A failed overview invocation must not affect direct numbered-workspace switching.

## 2.3 Special-workspace model

All configured special workspaces share one persistent bar slot.

The slot:

- shows a neutral stack/layered-workspace glyph when no relevant special workspace is visible;
- shows the configured icon of the visible special workspace when one is open;
- opens a compact selector on primary click;
- keeps a stable cell size while its icon changes;
- does not replace or remove the active numbered-workspace highlight.

Initial configured special-workspace concepts are:

- Music;
- Movies/Anime;
- Books;
- Discord;
- Scratchpad;
- Todo.

These examples must come from shared configuration rather than hard-coded QML.

Each special workspace has:

- a stable Franken Shell `id`;
- a compositor-facing `hyprlandName`;
- a user-facing label;
- an icon identifier;
- an optional shortcut hint;
- an optional default-application hint.

The stable `id`, not the label, is the project-level identifier.

## 2.4 Special-workspace actions

- Primary click on the persistent special-workspace slot opens the selector.
- The selector contains all configured special workspaces.
- Activating an inactive special workspace opens/toggles it through the Hyprland adapter.
- Activating the currently visible special workspace closes/toggles it.
- The selector closes after a successful activation.
- `Escape` closes the selector.
- Dedicated Hyprland shortcuts remain the fastest path.
- The selector is fully usable by keyboard and pointer.
- The initial focus target is the visible special workspace; if none is visible, it is the first configured entry.

## 2.5 Workspace overview boundary

- Franken Shell adopts `quickshell-overview` rather than implementing a new visual overview.
- The overview initially runs as a separate Quickshell configuration or process.
- Franken Shell owns invocation, shared configuration, theme integration, compatibility checks, failure handling, and fallback behaviour.
- `quickshell-overview` owns visual previews, window previews, preview navigation, drag-and-drop, and its internal screencopy implementation.
- Direct workspace switching remains functional if the overview is absent, incompatible, or has failed.
- Opening the overview closes ordinary shell popovers and the control centre through `SurfaceCoordinator`.
- The overview must eventually consume the same numbered- and special-workspace definitions as the bar.
- Users must not maintain an independent special-workspace list for the overview.
- The exact one-way synchronization mechanism remains unresolved.

## 2.6 Focused-window information and actions

- The active/focused window title does not occupy permanent bar space.
- Focused-window metadata and controls are exposed only through a summonable action surface or adopted overview path.
- The initial action set is configuration-driven and may include:
  - move to numbered workspace;
  - move to special workspace;
  - toggle floating;
  - toggle fullscreen;
  - close gracefully;
  - force-kill.
- Graceful close and force-kill must remain visibly and behaviourally distinct.
- Force-kill requires explicit confirmation and destructive styling.
- Window actions are sent through normalized Hyprland commands, never directly from view delegates.
- The default entry point for focused-window actions remains unresolved.
- Candidate entry points may coexist later, but implementation must not silently declare one as the canonical path.

## 2.7 Shared interaction and visual rules

- Every major action has both a keyboard and pointer path.
- Hover may expose tooltips or semantic labels but must not be required for core operation.
- Keyboard focus is visible independently of the active-workspace selected state.
- The active workspace uses a strong selected container or equivalent Material state.
- Inactive workspace numbers remain lower emphasis.
- Workspace group transitions are short and directional.
- Ordinary switching inside one visible group must not produce large decorative movement.
- Reduced-motion mode removes or simplifies group-transition animation without hiding state changes.
- Workspace delegates use stable geometry; selected-state changes must not move neighbouring items.
- Pointer hit targets follow the bar's approximate `36–40` logical-pixel target guidance even when the visible number or icon is smaller.
- Workspace state must never rely on colour alone.
- The feature consumes shared semantic theme roles rather than raw wallpaper colours.

---

# 3. Scope and Ownership

## 3.1 The workspace feature owns

- presentation-ready numbered-workspace models;
- visible-group derivation;
- numbered pager interaction policy;
- special-workspace selector presentation;
- special-workspace interaction policy;
- focused-window action presentation and safety policy;
- workspace-facing controller methods;
- mapping configuration definitions to presentation models;
- requesting overview invocation through `OverviewAdapter`;
- requesting workspace/window actions through the Hyprland adapter;
- workspace-specific fixtures and tests;
- workspace-specific diagnostics such as invalid definitions or out-of-range compositor state.

## 3.2 The workspace feature does not own

- raw Hyprland events;
- raw Hyprland dispatcher strings;
- socket reconnection details;
- Quickshell Hyprland API compatibility branches;
- monitor discovery;
- global fullscreen policy;
- global surface visibility and focus restoration;
- `quickshell-overview` preview capture or layout implementation;
- Vicinae command UI;
- persistent configuration parsing or validation;
- external application launching;
- active-window process termination implementation;
- notification or toast windows.

These responsibilities belong to `HyprlandService`, `WorkspaceModel`, `WindowModel`, `HyprlandCommands`, `MonitorRegistry`, `SurfaceCoordinator`, `OverviewAdapter`, `VicinaeAdapter`, `ConfigService`, `CommandRegistry`, and shared feedback services.

## 3.3 Cross-feature ownership boundary

The workspace feature may expose normalized actions such as:

```text
activateNumberedWorkspace(number, invocationContext)
toggleSpecialWorkspace(id, invocationContext)
requestOverview(invocationContext)
requestFocusedWindowActions(invocationContext)
moveFocusedWindowToNumberedWorkspace(number)
moveFocusedWindowToSpecialWorkspace(id)
toggleFocusedWindowFloating()
toggleFocusedWindowFullscreen()
closeFocusedWindow()
requestKillFocusedWindow()
```

It must not know how those actions are encoded for a particular Hyprland version.

---

# 4. Proposed QML Structure

The following structure is implementation guidance, not a requirement to create empty files in advance.

```text
services/hyprland/
├── HyprlandService.qml
├── WorkspaceModel.qml
├── WindowModel.qml
└── HyprlandCommands.qml

features/workspaces/
├── WorkspaceController.qml
├── NumberedWorkspacePager.qml
├── WorkspaceNumberDelegate.qml
├── SpecialWorkspaceController.qml
├── SpecialWorkspaceButton.qml
├── SpecialWorkspaceSelector.qml
├── SpecialWorkspaceDelegate.qml
├── FocusedWindowController.qml
├── FocusedWindowActions.qml
├── WorkspaceTargetPicker.qml
├── SpecialWorkspaceTargetPicker.qml
└── fixtures/
    ├── WorkspaceFixtureModel.qml
    └── FocusedWindowFixtureModel.qml

integrations/overview/
└── OverviewAdapter.qml
```

Do not split a compact implementation into every file merely to match this shape. Separate components when they have independent responsibilities, meaningful tests, or reuse across surfaces.

## 4.1 `WorkspaceController`

The controller bridges normalized Hyprland/configuration state and workspace views.

Responsibilities:

- expose the configured numbered workspace range;
- expose the active numbered workspace for a selected monitor context;
- derive the visible numbered group;
- expose semantic labels without making them permanent bar text;
- expose switch and scroll actions;
- expose active-workspace activation policy;
- expose overview capability and failure state;
- coalesce rapid scroll requests where appropriate;
- report invalid or inconsistent workspace configuration;
- avoid duplicating authoritative Hyprland state.

Suggested conceptual interface:

```text
minimumNumber
maximumNumber
groupSize
wrapEnabled
scrollEnabled
scrollDirection
activeNumber
visibleNumbers[]
activeNumberInConfiguredRange
stateAvailable
overviewAvailable
overviewBusy
overviewLastError

activateNumber(number, invocationContext)
activateFocusedNumber(invocationContext)
step(delta, invocationContext)
requestOverview(invocationContext)
```

## 4.2 `NumberedWorkspacePager`

Responsibilities:

- render one visible group;
- bind selected state to normalized active workspace;
- expose orientation-aware keyboard and pointer navigation;
- preserve focus across group changes;
- render optional semantic labels through tooltip/accessibility metadata;
- never inspect raw Hyprland objects;
- never infer occupancy styling;
- never launch external commands directly.

## 4.3 `SpecialWorkspaceController`

Responsibilities:

- expose configured special-workspace definitions in stable order;
- map each definition to normalized visibility and availability state;
- derive the persistent button's neutral or active icon;
- expose monitor-aware visibility where available;
- invoke toggle operations through `HyprlandCommands`/adapter;
- track operation-in-progress and structured errors;
- provide selector focus target.

Suggested conceptual interface:

```text
definitions[]
visibleIds[]
visibleIdForMonitor
persistentIcon
persistentLabel
stateAvailable
operationInProgress
lastError

toggle(id, invocationContext)
```

## 4.4 `SpecialWorkspaceSelector`

Responsibilities:

- render configured label, icon, shortcut hint, and current visibility state;
- support bar-edge-aware placement through the shared popover host;
- support pointer activation and directional keyboard navigation;
- distinguish visible, hidden, unavailable, focused, and operation-in-progress states;
- close only after success or explicit dismissal;
- leave a failed operation visible with an understandable error path.

The selector must not launch the configured `defaultApplication` merely because the workspace is empty. `defaultApplication` is an informational/integration hint, not an automatic occupancy policy.

## 4.5 `FocusedWindowController`

Responsibilities:

- expose normalized focused-window metadata;
- determine capability of each configured action;
- expose enabled, unavailable, busy, and destructive action state;
- construct numbered and special workspace target models from authoritative configuration;
- issue actions through normalized Hyprland commands;
- require confirmation before force-kill;
- distinguish operation failures from absence of a focused window;
- prevent actions from accidentally targeting a stale window after focus changes.

A destructive operation should bind to a stable focused-window identity captured when the surface opens, then verify that identity before execution where the backend allows.

Suggested conceptual interface:

```text
windowAvailable
windowId
title
appId
windowClass
workspaceId
workspaceName
monitorId
floating
fullscreen
actions[]
actionBusy
lastError

moveToNumberedWorkspace(number)
moveToSpecialWorkspace(id)
toggleFloating()
toggleFullscreen()
closeGracefully()
requestKillConfirmation()
confirmKill(expectedWindowId)
```

## 4.6 `FocusedWindowActions`

Responsibilities:

- provide compact metadata and configured actions;
- keep safe actions before destructive actions in focus order;
- expose target pickers as nested pages or menus within the same transient interaction stack;
- show a clear confirmation for force-kill;
- use `Escape` to unwind target selection or confirmation before closing the surface;
- return focus to the invocation source after dismissal.

The exact surface form and primary entry point remain unresolved. The component contract should therefore be reusable from:

- a bar-anchored popover;
- a keyboard-invoked compact surface;
- an overview integration hook;
- a Vicinae command action.

---

# 5. State and Data Requirements

## 5.1 Authoritative configuration state

The feature consumes the resolved `workspaces` configuration section.

Conceptual numbered configuration:

```text
NumberedWorkspaceConfig {
    minimum: int
    maximum: int
    groupSize: int
    wrap: bool
    semanticLabels: map<int, string>
}
```

Conceptual special-workspace configuration:

```text
SpecialWorkspaceDefinition {
    id: string
    hyprlandName: string
    label: string
    icon: string
    shortcutHint?: string
    defaultApplication?: string
}
```

Conceptual overview configuration:

```text
OverviewWorkspaceConfig {
    provider: string
    openOnActiveWorkspaceClick: bool
    rows: int
    columns: int
    showSpecialWorkspaces: bool
    hideEmptyRows: bool
}
```

Conceptual focused-window action configuration:

```text
FocusedWindowActionConfig {
    enabled: bool
    actions: string[]
}
```

The authoritative user configuration is TOML at
`$XDG_CONFIG_HOME/franken-shell/config.toml` under D-075. Workspace feature
code consumes only the typed immutable runtime snapshot published by
`ConfigService`; it does not parse TOML or invoke the Rust helper directly.
The shared boundary is defined by `docs/decisions.md`,
`docs/configuration-model.md`, and `docs/architecture.md`.

## 5.2 Configuration validation

Validation must reject or clearly report:

- numbered `minimum` greater than `maximum`;
- non-positive group size;
- group size outside the supported schema range;
- duplicate special-workspace `id` values;
- duplicate or ambiguous `hyprlandName` values;
- empty stable IDs;
- missing required label or icon values;
- unknown focused-window action identifiers;
- overview rows/columns that cannot represent the intended configured grid, where the chosen integration requires a fixed grid;
- configuration changes that would create inconsistent generated overview state.

An invalid reload must retain the previous valid workspace configuration atomically.

## 5.3 Normalized numbered workspace state

The Hyprland adapter should expose normalized workspace records rather than raw protocol objects.

Conceptual record:

```text
NumberedWorkspaceState {
    number: int
    name: string
    monitorId?: string
    active: bool
    focused: bool
    urgent: bool
    available: bool
}
```

The pager does not require occupancy to render its resting state. Occupancy may remain available to other features or diagnostics but must not become a pager decoration.

## 5.4 Visible-group derivation

For a valid active numbered workspace inside the configured range, the visible group should be derived deterministically from:

```text
minimum
maximum
groupSize
activeNumber
```

The derivation should:

- start on a stable group boundary relative to `minimum`;
- preserve configured ordering;
- truncate the final group at `maximum` where required;
- avoid implicit dependence on occupied workspace data;
- produce identical results in fixture and live modes.

The controller, not the view delegate, owns this calculation.

If Hyprland reports an active numbered workspace outside the configured range, the feature must not silently clamp it to a different active number. It should preserve truthful state, report the mismatch through diagnostics, and use a clearly documented fallback presentation. The exact final fallback presentation may be refined during implementation, but fabricated state is forbidden.

## 5.5 Scroll and command task state

Workspace switching can be asynchronous from the view's perspective even when Hyprland dispatch is fast.

Suggested task state:

```text
WorkspaceActionTask {
    id
    type
    target
    state: Idle | Requested | Dispatched | Confirmed | Failed | Cancelled
    error
    invocationSource
}
```

The UI must not queue unlimited workspace actions during rapid wheel input. The controller may coalesce intermediate requests while preserving the most recent intended target.

## 5.6 Special-workspace runtime state

Special-workspace state should support more than one visible ID internally even if the first single-monitor bar usually presents one active icon.

Conceptual record:

```text
SpecialWorkspaceState {
    id: string
    hyprlandName: string
    monitorId?: string
    visible: bool
    active: bool
    urgent: bool
    available: bool
}
```

This prevents the service model from assuming that only one special workspace can ever be visible across a multi-monitor session.

The persistent slot's final multi-monitor selection policy remains unresolved.

## 5.7 Focused-window state

Conceptual normalized state:

```text
FocusedWindowState {
    id
    title
    appId
    windowClass
    pid?
    workspaceNumber?
    specialWorkspaceId?
    monitorId?
    floating
    fullscreen
    mapped
    closing
}
```

The view must not retain a stale process identifier as the sole action target. Use the strongest stable compositor/window identity available through the selected adapter.

## 5.8 Derived presentation state

Controllers may expose:

- visible group numbers;
- selected/focused/urgent presentation roles;
- optional tooltip text;
- special-workspace persistent icon;
- special-workspace selector rows;
- action availability;
- overview integration health;
- busy and failure messages.

Controllers must not become alternate authoritative stores for workspace definitions or compositor state.

---

# 6. Numbered Workspace Pager

## 6.1 Presentation

The resting pager shows one compact group of numeric delegates.

Requirements:

- numbers are always visible for the current group;
- selected state is visually unmistakable;
- focus state remains distinguishable from selected state;
- inactive numbers use restrained contrast;
- no occupancy dots, bars, app icons, previews, or window counts;
- no permanent active-window metadata;
- cell geometry does not change when selected;
- semantic labels appear only as secondary metadata such as tooltips or accessibility descriptions;
- horizontal and vertical bar orientations use appropriate layout rather than rotated text.

## 6.2 Group transition

A group transition occurs only when the active target crosses a group boundary or configuration changes.

Requirements:

- movement direction reflects logical workspace direction;
- the transition is short and does not delay command execution;
- focus follows the intended target;
- delegates must not briefly show a fabricated active number;
- reduced-motion mode uses immediate replacement or a minimal fade;
- ordinary switching within one group should update selection without a large group animation.

## 6.3 Pointer interaction

### Inactive workspace number

Primary click:

1. request direct workspace activation through `WorkspaceController`;
2. do not wait for animation before dispatching;
3. update selected state when normalized compositor state confirms the change;
4. expose a structured failure if dispatch fails.

### Active workspace number

The final primary action remains unresolved.

Prototype behaviour may request overview invocation, but:

- it must route through `activateFocusedNumber()` or an equivalent policy method;
- it must not be encoded inside the delegate;
- it must be possible to change to no-op, secondary-click overview, or another settled action without replacing the pager component;
- repeated clicks during an overview launch must not spawn duplicate overview processes;
- accidental overview opening during rapid workspace switching must be tested.

### Secondary click

Secondary-click behaviour on the active workspace is reserved as a candidate focused-window-action entry point.

Until Q-018 is settled:

- the view may expose the event to the controller;
- the prototype may leave it unassigned or route it to a fixture action;
- it must not silently become the only path to focused-window controls.

Secondary click on an inactive workspace has no required initial action.

### Scroll

- Scroll moves one numbered workspace per normalized step.
- Direction follows configured workspace scroll policy.
- Wrapping follows configured `wrap` behaviour.
- Scroll does not act while a child popover or nested scroll surface owns the pointer event.
- High-resolution trackpad wheel input must be accumulated into intentional steps rather than dispatching one workspace command per tiny delta.
- Rapid input may coalesce intermediate commands.
- Scrolling never opens the overview.

## 6.4 Keyboard interaction

- Direct compositor workspace shortcuts remain available independently of bar focus.
- Entering the pager focuses the active visible number when possible.
- Directional keys move according to the visible bar axis.
- `Enter` invokes the same primary action policy as pointer activation.
- `Space` may invoke activation only if it remains consistent with the selected control semantics; it must not silently differ from `Enter`.
- Group changes preserve a valid focused item.
- `Tab` leaves the pager for the next bar control.
- `Shift+Tab` returns to the preceding bar region.
- `Escape` leaves bar focus or closes the current workspace child surface according to the shared focus stack.

## 6.5 Tooltip and accessibility metadata

Each workspace number should provide:

- accessible role and name;
- number;
- selected/active state;
- optional semantic label;
- unavailable/degraded state where relevant;
- a hint for the active-workspace action only after that action is settled or configured.

Do not advertise provisional behaviour as permanent help text.

## 6.6 Urgency

Hyprland urgent state may be available to the workspace model.

The baseline documents do not settle an urgent-workspace visual treatment in the resting pager. Therefore:

- the adapter may expose urgency;
- the controller may preserve it;
- Codex must not add a prominent permanent urgent marker without a documented design decision;
- a restrained prototype may be explored only if recorded as provisional and tested against the quiet-bar principle.

## 6.7 Degraded state

If workspace state is temporarily unavailable:

- do not invent an active workspace;
- keep the last-known-good group only if it is clearly represented as stale/degraded;
- otherwise render a disabled neutral pager state;
- preserve keyboard focus safety;
- retry through the service adapter;
- report backend health through diagnostics;
- do not run `hyprctl` from each delegate as a fallback.

---

# 7. Special Workspace Control and Selector

## 7.1 Persistent control presentation

The persistent bar control occupies one fixed cell.

States:

```text
NoneVisible
OneRelevantVisible
MultipleVisibleAcrossSession
Unavailable
OperationInProgress
Error
```

Settled presentation:

- `NoneVisible` uses a neutral stack/layer glyph;
- a visible special workspace uses its configured icon;
- icon substitution does not change cell extent;
- active numbered workspace remains selected separately;
- selected/focused state uses bar semantic tokens;
- no permanent text label is required in the bar.

The exact persistent representation when multiple special workspaces are visible across monitors is unresolved.

## 7.2 Persistent control interaction

- Primary click toggles the selector surface, not a hard-coded special workspace.
- Reinvoking the open selector through the same control closes it.
- Keyboard activation opens the selector and focuses the current visible item or first configured item.
- Hover/focus may show the current visible workspace label or “Special workspaces.”
- No middle-click action is required initially.
- No scroll action is required initially.

## 7.3 Selector layout

The selector is a compact edge-attached popover hosted through `SurfaceCoordinator` and the shared popover host.

Each row or tile should expose:

- configured icon;
- label;
- shortcut hint when present;
- visible/hidden state;
- focus state;
- operation-in-progress state;
- availability/error state.

The selector should use a compact list or small grid appropriate to the bar orientation and item count. The exact list-versus-grid layout may be selected during component implementation as long as it remains compact, keyboard coherent, and does not contradict a settled decision.

## 7.4 Selector pointer interaction

Primary activation on an item:

- toggles the corresponding Hyprland special workspace;
- shows an in-progress state until the request is dispatched/confirmed;
- closes the selector after success;
- stays open on failure and exposes the failure;
- does not launch `defaultApplication` automatically.

Secondary click has no required initial action.

## 7.5 Selector keyboard interaction

- Initial focus: visible item, otherwise first item.
- Arrow keys follow visible geometry.
- `Enter` activates the focused item.
- `Escape` closes the selector.
- `Tab` and `Shift+Tab` follow logical focus order without trapping focus.
- Focus returns to the persistent special-workspace control when the selector closes.

## 7.6 Empty configuration

If no special workspaces are configured:

- the persistent special-workspace bar control should normally be omitted rather than shown as a permanently dead slot;
- bar layout remains stable according to capability/configuration changes, not transient state;
- diagnostics should report that the special-workspace list is empty only when useful, not as an error by default;
- generated overview/Vicinae configuration must use the same empty model.

## 7.7 Invalid definition

An invalid special-workspace definition must not partially enter the live model.

If the entire candidate configuration is invalid:

- retain the previous valid workspace model;
- expose the exact invalid path through configuration diagnostics;
- do not create a selector row with missing identity or command target.

## 7.8 Backend failure

If one configured special workspace cannot be resolved or toggled:

- preserve other valid entries;
- mark the affected entry unavailable or failed;
- provide a concise reason where known;
- do not disable the numbered pager;
- do not restart the entire shell.

---

# 8. Focused-Window Actions

## 8.1 Product boundary

Focused-window actions preserve useful Caelestia-style window management without allocating permanent bar space to a title or window controls.

The feature is near-term rather than required for the first bar foundation.

The action surface should remain compact and task-oriented. Broader visual navigation remains the responsibility of quickshell-overview.

## 8.2 Metadata

The summonable surface may show:

- window title;
- application identity/class where available;
- current numbered or special workspace;
- floating state;
- fullscreen state.

Metadata should be concise. The action surface must not become a full window inspector.

## 8.3 Initial action set

The configured action list may contain:

```text
moveToWorkspace
moveToSpecialWorkspace
toggleFloating
toggleFullscreen
close
kill
```

Unknown actions are rejected during configuration validation.

## 8.4 Move to numbered workspace

- Opens a target picker based on authoritative numbered workspace configuration.
- Shows workspace numbers and optional semantic labels.
- Does not filter out empty workspaces.
- Does not substitute application icons.
- Dispatches through the Hyprland adapter.
- Keeps the focused-window target identity stable for the duration of the operation.
- On success, closes the target picker and action surface unless later interaction testing settles a different workflow.
- On failure, remains open and displays the error.

## 8.5 Move to special workspace

- Opens a target picker based on authoritative special-workspace definitions.
- Uses stable `id` values internally and `hyprlandName` only at the adapter boundary.
- Shows configured label and icon.
- Does not assume the configured `defaultApplication` is the only valid window for that special workspace.
- Dispatches through normalized Hyprland commands.

## 8.6 Toggle floating

- Immediate, reversible action.
- Uses current normalized state to communicate expected result.
- Does not require confirmation.
- Reports failure through the action surface or system failure feedback channel.

## 8.7 Toggle fullscreen

- Immediate, reversible action.
- Must use the same normalized fullscreen semantics used elsewhere in the shell.
- The shell must distinguish fullscreen from maximized state.
- The action surface may disappear as a consequence of entering fullscreen according to global surface policy; it must not leave invisible focus behind.

## 8.8 Graceful close

- Clearly labelled as a normal close operation.
- Does not require confirmation for an ordinary window.
- Must not be visually conflated with force-kill.
- Targets the captured focused-window identity.
- Surface closes when the target window disappears or the action succeeds.

## 8.9 Force-kill

- Uses explicit destructive styling.
- Requires confirmation.
- Confirmation text identifies the target window/application where available.
- Confirmation captures and verifies the target identity.
- `Escape` cancels confirmation before closing the broader action surface.
- A changed or missing target invalidates the confirmation rather than killing a newly focused window.
- The action must never be assigned to middle click or a single unconfirmed compact icon.

## 8.10 Entry points

Candidate entry points are:

- secondary click on the active workspace number;
- a dedicated keyboard shortcut;
- an action inside quickshell-overview;
- a Vicinae shell command;
- a contextual bar indicator in a future justified case.

The default and multiplicity remain unresolved.

Implementation requirements:

- keep the action surface invocation API independent of one source;
- store invocation context for focus restoration and monitor ownership;
- do not make secondary click the only meaningful path;
- do not require quickshell-overview to be running for keyboard or Vicinae invocation;
- do not create a permanent active-window bar control.

## 8.11 No focused window

When no valid focused application window exists:

- do not display stale metadata;
- disable or omit action controls;
- provide a concise “No focused window” state when the surface is explicitly invoked;
- allow safe dismissal;
- do not treat the shell's own transient window as the target.

## 8.12 Focus changes while open

The final live-follow versus captured-target policy is not explicitly settled.

Safe implementation baseline:

- capture the intended target when the action surface opens;
- visibly update or invalidate the surface if that target disappears;
- never retarget a destructive confirmation merely because compositor focus changes;
- record any live-follow behaviour as an explicit decision before enabling it.

---

# 9. quickshell-overview Integration Boundary

This section defines only the workspace feature's contract with the overview. The full integration belongs in `docs/features/quickshell-overview-integration.md`.

## 9.1 Required adapter contract

Conceptual `OverviewAdapter` state:

```text
provider
enabled
available
running
busy
compatible
expectedVersion
installedVersion
ipcAvailable
configurationSynchronized
themeSynchronized
lastError
repairHint
```

Conceptual actions:

```text
toggle(monitorContext?)
open(monitorContext?)
close()
regenerateConfiguration()
refreshCompatibility()
```

## 9.2 Invocation

When workspace UI requests the overview:

1. `SurfaceCoordinator` closes ordinary shell popovers and the control centre;
2. `OverviewAdapter` verifies availability/compatibility sufficiently for invocation;
3. the adapter invokes one documented IPC or command path;
4. duplicate concurrent launch requests are suppressed;
5. failures are returned as structured integration errors;
6. direct workspace navigation remains unaffected.

## 9.3 Configuration ownership

Franken Shell configuration is authoritative for:

- numbered range/grid intent;
- group size where relevant;
- special workspace IDs and compositor names;
- labels and icons;
- theme roles;
- selected overview settings represented in the shared schema.

The overview must receive derived/generated state from this source.

The exact mechanism remains unresolved:

- generated overview configuration;
- imported shared file;
- IPC setters;
- a vendored shared QML module;
- another one-way adapter mechanism.

Bidirectional competing ownership is forbidden.

## 9.4 Failure fallback

If overview invocation fails:

- show a concise actionable integration failure;
- keep the pager usable;
- keep special workspace toggling usable;
- do not retry in a tight loop;
- expose diagnostics and repair hint where available;
- do not silently replace the overview with a newly built shell overview.

## 9.5 Preview performance boundary

The main workspace feature must not:

- subscribe to screencopy previews;
- keep hidden preview textures alive;
- poll window thumbnails;
- duplicate quickshell-overview's window model solely for visual previews.

Preview stability, GPU interaction, mixed scaling, and suspended NVIDIA behaviour belong to the overview integration specification and research backlog.

---

# 10. Opening, Dismissal, and Focus Behaviour

## 10.1 Numbered pager

The pager is part of the persistent bar rather than a transient surface.

When keyboard focus enters it:

- focus the active visible number when possible;
- otherwise focus the nearest valid visible number;
- render visible focus independent of selected state;
- preserve focus through group updates.

`Escape` with no workspace child surface open returns focus to the previously focused application according to shared bar behaviour.

## 10.2 Special-workspace selector

Opening:

- request a popover through `SurfaceCoordinator`;
- supply the bar-item anchor, monitor, configured edge, and selector payload;
- close any other ordinary bar popover;
- acquire keyboard focus immediately when keyboard-invoked;
- avoid unnecessary focus stealing when pointer-invoked until keyboard interaction begins, where technically practical.

Dismissal:

- `Escape`;
- outside click;
- reactivation of the persistent control;
- successful workspace toggle;
- opening another major shell surface.

Focus restoration:

- return to the persistent special-workspace control when appropriate;
- otherwise restore the previously focused application through `SurfaceCoordinator`.

## 10.3 Focused-window action surface

Opening:

- invoked through a generic controller method with source and monitor context;
- captures the focused-window target;
- keyboard invocation focuses the first safe, non-destructive action;
- pointer invocation focuses the surface only when keyboard interaction begins where possible.

Nested order:

```text
Focused-window actions
└─ Workspace target picker or special-workspace target picker
   └─ Optional confirmation/error state
```

`Escape` unwinds the deepest state first.

Outside click:

- may dismiss the ordinary action menu and target pickers;
- must not confirm force-kill;
- during force-kill confirmation, outside click should cancel or no-op according to the shared destructive-dialog policy, never execute.

## 10.4 Overview opening

Opening overview:

- closes ordinary workspace popovers and the control centre;
- delegates focus to quickshell-overview;
- does not leave bar keyboard focus active behind the overview;
- restores normal application focus according to overview/Hyprland behaviour when it closes.

Exact cross-process focus restoration must be tested against the pinned overview revision.

---

# 11. Service and Integration Dependencies

## 11.1 Required core dependencies

### `ConfigService`

Provides:

- typed numbered workspace configuration;
- typed special-workspace definitions;
- overview integration settings;
- focused-window action configuration;
- atomic reload and last-valid retention.

### `HyprlandService`

Provides normalized compositor connection and event state.

### `WorkspaceModel`

Provides:

- numbered workspaces;
- active workspaces by monitor;
- special-workspace visibility;
- urgent state where available;
- reconnect-aware updates.

### `WindowModel`

Provides:

- focused-window identity and metadata;
- floating/fullscreen state;
- window disappearance/change events.

### `HyprlandCommands`

Provides version-aware operations for:

- activate numbered workspace;
- toggle special workspace;
- move window to workspace;
- move window to special workspace;
- toggle floating;
- toggle fullscreen;
- close;
- kill.

No view imports raw dispatcher syntax.

### `SurfaceCoordinator`

Owns:

- special selector visibility;
- focused-window surface visibility;
- cross-surface closing;
- monitor ownership;
- focus restoration.

### `MonitorRegistry`

Provides normalized monitor identities and invocation context.

### `ThemeManager`

Provides semantic visual tokens.

### `Diagnostics`

Records service health, invalid definitions, failed commands, and integration status.

## 11.2 Required adopted integration

### `OverviewAdapter`

Required for active-workspace overview invocation and explicit overview commands.

The workspace pager remains useful without it.

## 11.3 Optional integration dependencies

### `VicinaeAdapter`

May expose workspace switching, special-workspace toggles, overview invocation, and focused-window actions through a first-party extension.

Vicinae absence must not affect bar interactions.

### Toast/error feedback service

May present concise failures for explicit user actions.

Routine successful workspace switching should not create toasts or OSDs.

## 11.4 Dependency readiness

Workspace views must tolerate initialization order where:

- configuration exists before Hyprland is connected;
- bar renders before overview compatibility checks complete;
- overview becomes available after shell startup;
- focused-window metadata is absent temporarily;
- monitor mapping changes after hotplug.

---

# 12. Error and Unavailable States

## 12.1 Hyprland unavailable at startup

- Render workspace navigation in a clearly degraded, non-fabricated state.
- Do not dispatch direct `hyprctl` commands from the UI as an emergency workaround.
- Retry through the adapter's reconnect policy.
- Preserve validated configuration models.
- Expose a diagnostic error and repair hint where possible.
- Other bar features continue running.

## 12.2 Hyprland connection lost during use

- Keep the last-known-good visual state only if marked stale/degraded.
- Disable actions that cannot safely be dispatched.
- Do not clear configuration-defined workspace labels or selector entries.
- Reconcile state after reconnection.
- Avoid replaying stale queued actions automatically unless the action task explicitly remains valid.

## 12.3 Workspace switch failure

- Return focus safely.
- Keep the truthful active workspace selected.
- Expose a concise failure through the originating surface or feedback channel.
- Log structured command metadata without leaking unrelated application data.
- Do not repeatedly retry without user intent.

## 12.4 Overview unavailable

- Direct numbered switching continues.
- Special-workspace selector continues.
- Active-workspace overview request produces a concise actionable failure.
- Capability state and version mismatch are visible in diagnostics.
- Do not disable the active workspace number itself.

## 12.5 Overview configuration out of sync

- Mark the integration degraded.
- Do not overwrite user files destructively without the defined generator/ownership contract.
- Permit direct workspace use.
- Offer a regenerate/repair action only through the integration layer.

## 12.6 Empty special-workspace list

- Omit the persistent special-workspace control.
- Do not reserve a decorative empty selector slot.
- Keep generated integrations consistent with the empty list.

## 12.7 Focused window disappears

- Invalidate pending actions for that identity.
- Close or transition the action surface to a concise unavailable state.
- Cancel destructive confirmation.
- Never retarget kill/close to the newly focused window automatically.

## 12.8 Unsupported focused-window action

- Omit the action when capability is definitively absent.
- Disable with explanation only when the distinction is useful to the user.
- Do not expose raw backend failure codes in the primary UI.
- Preserve other supported actions.

## 12.9 Invalid icon

- Use a neutral fallback icon for display only if the definition otherwise remains valid.
- Report the missing icon through diagnostics.
- Do not replace the stable workspace identity.
- Configuration validation policy may choose to reject unknown icon IDs once the icon registry is finalized.

## 12.10 Invalid active workspace range

If compositor state falls outside configured numbered range:

- do not clamp the active number;
- expose a mismatch diagnostic;
- use a safe truthful fallback presentation;
- do not rewrite configuration automatically;
- do not hide the fact that an externally created workspace exists.

The final visual fallback should be tested and documented before release.

---

# 13. Multi-Monitor Considerations

Final multi-monitor workspace policy is unresolved. The implementation must remain monitor-aware without claiming that the product policy is settled.

## 13.1 Required internal model

- Workspace state includes monitor association where Hyprland provides it.
- `WorkspaceController` accepts a monitor context rather than assuming one global bar.
- Special-workspace visibility can be represented per monitor.
- Focused-window state includes monitor identity where available.
- Invocation context records pointer, bar, or focused-window monitor.
- No feature hard-codes `eDP-1`, `DP-1`, primary monitor, or one display geometry.

## 13.2 Open pager policies

Possible final policies include:

- each bar follows the active workspace on its own monitor;
- all bars show the globally focused workspace group;
- only one configured monitor shows workspace navigation;
- direct workspace click moves focus to or activates the target's associated monitor;
- configured semantic workspaces remain global while active presentation is monitor-local.

No one of these is settled.

## 13.3 Safe implementation direction

Until Q-089 is resolved:

- keep per-monitor inputs in the controller and view contract;
- avoid storing one global `activeWorkspaceNumber` inside the pager component;
- allow fixture testing of different active workspace groups on two monitors;
- isolate click-routing policy behind the controller;
- do not duplicate authoritative workspace definitions per monitor.

## 13.4 Special workspaces across monitors

The internal model must support:

- none visible;
- one visible on the invoking monitor;
- one visible on another monitor;
- multiple visible special workspaces across the session, if Hyprland permits that state.

The persistent icon-selection policy for multiple visible special workspaces remains unresolved.

## 13.5 Focused-window action monitor

Provisional ownership principles from the wider architecture suggest:

- pointer invocation uses the source bar/pointer monitor;
- keyboard invocation uses the focused-window monitor;
- one action surface operates on the captured focused window.

These must be validated during Phase 10 and not presented as final policy until settled.

## 13.6 Hotplug

On monitor removal:

- invalidate or remap monitor-specific controller contexts;
- close transient workspace surfaces owned by the removed monitor;
- preserve global configuration;
- reconcile Hyprland workspace-to-monitor state;
- avoid dispatching an action using a stale monitor identity;
- restore focus to a valid remaining window.

## 13.7 Scaling and rotation

- Pager text remains upright and readable.
- Orientation follows the configured bar edge, not monitor transform alone.
- Pointer targets remain logical-size consistent under fractional scaling.
- Popover anchor geometry uses normalized logical coordinates.
- Mixed scale must not cause duplicate or missing activation targets.

---

# 14. Performance Considerations

## 14.1 Event-driven state

Workspace and focused-window state must be event-driven through the Hyprland adapter.

Do not poll:

- active workspace;
- focused window;
- special-workspace visibility;
- floating/fullscreen state;
- monitor association;

with recurring external commands when a normalized event source is available.

## 14.2 Persistent delegate cost

- Number delegates remain lightweight.
- Do not create window models or preview textures per workspace number.
- Do not measure optional semantic labels on every frame.
- Cache stable icon resolution for special-workspace entries.
- Selected/focus changes should update properties rather than recreate the whole pager.
- Hidden selector and focused-window surfaces should be lazy-created.

## 14.3 Rapid workspace switching

- Coalesce high-resolution wheel events into intentional steps.
- Avoid unbounded command queues.
- Preserve the final user target.
- Do not run a large group transition for each intermediate state.
- Ensure state updates arriving out of order cannot visually select the wrong final workspace.
- Prevent repeated active-workspace clicks from spawning duplicate overview invocations.

## 14.4 Configuration reload

- Rebuild derived workspace models atomically.
- Reuse unchanged delegates where practical.
- Preserve focus if the focused workspace definition remains valid.
- Close a selector safely if its target definition is removed.
- Cancel or invalidate focused-window target pickers if their target list changes incompatibly.

## 14.5 Overview boundary

- No overview preview work occurs in the main shell while the overview is closed.
- Overview health checks are rate-limited.
- Configuration generation is triggered by relevant changes, not every workspace event.
- A failed overview process does not cause a tight restart loop.

## 14.6 Command responsiveness

- Workspace dispatch must not block the QML UI thread.
- External fallback commands, if required by a documented adapter gap, run asynchronously.
- Command results are structured.
- UI feedback appears immediately as pressed/busy state without pretending the compositor has confirmed the change.

## 14.7 Measurements

Record during daily-use and hardening phases:

- pointer-to-dispatch latency;
- key-to-dispatch latency;
- compositor-event-to-selected-state latency;
- frame pacing during group transitions;
- scroll coalescing behaviour;
- memory impact of multiple bar pagers;
- overview invocation latency;
- adapter reconnect time;
- hotplug reconciliation time.

Exact budgets are not yet settled, but regressions must be measured.

---

# 15. Implementation Phases

## 15.1 Phase 1 — Core prerequisites

Before workspace UI is connected to real state, provide:

- validated configuration service;
- typed workspace configuration objects;
- fallback theme tokens;
- monitor registry;
- surface coordinator;
- capability and diagnostics registries;
- fixture mode;
- initial overview capability placeholder;
- focus restoration path.

## 15.2 Phase 2 — Fixture numbered pager

Implement:

- fixture-driven numbered workspace state;
- group derivation;
- `1–5` and `6–10` transitions;
- selected state;
- pointer click;
- scroll stepping;
- keyboard focus and activation;
- active-workspace activation policy hook;
- orientation-aware pager API;
- no occupancy or app icons.

Implement a placeholder special-workspace button and selector using shared popover mechanics.

Explicitly defer:

- live Hyprland integration;
- final active-workspace click decision;
- final multi-monitor policy;
- focused-window actions;
- complete overview integration;
- final animation polish.

## 15.3 Phase 4 — Hyprland vertical slice

Implement live:

- active numbered workspace;
- workspace activation;
- special-workspace visibility;
- special-workspace toggling;
- focused window;
- floating/fullscreen state;
- monitor association;
- reconnect handling;
- structured command failures.

Exit criteria:

- pager follows real Hyprland state;
- special selector toggles real special workspaces;
- maximized state is not confused with fullscreen;
- service interruption recovers without shell restart;
- views contain no raw `hyprctl` calls.

## 15.4 Phase 6 — Daily-use workspace completion

Complete:

- real numbered pager in the bar;
- real special-workspace control and selector;
- configuration reload handling;
- keyboard and pointer parity;
- semantic tooltips;
- degraded states;
- one-day usage validation;
- multi-monitor-aware interfaces even if final policy remains provisional.

The shell must be usable for direct workspace navigation even before overview integration is complete.

## 15.5 Phase 7 — Overview integration

Complete:

- pinned overview revision;
- documented invocation path;
- shared/generated workspace configuration;
- theme synchronization;
- overview availability diagnostics;
- active-workspace prototype invocation;
- direct-switching fallback;
- multi-monitor and screencopy compatibility tests.

Do not finalize active-workspace click behaviour solely because the prototype supports it.

## 15.6 Phase 8 — Focused-window actions

Implement:

- reusable focused-window action surface;
- configured action list;
- target pickers;
- graceful close;
- force-kill confirmation;
- structured failure handling;
- keyboard shortcut path;
- one or more integration entry points after Q-018 is settled.

## 15.7 Phase 9 — Settings

Expose meaningful workspace settings:

- numbered minimum and maximum where supported;
- group size;
- wrap policy;
- semantic labels;
- special-workspace definitions;
- overview enablement/provider settings represented in the shared schema;
- focused-window action enablement and action list.

The settings UI must edit the same authoritative schema.

Do not expose:

- occupancy markers;
- app icons in the pager;
- permanent window title;
- arbitrary per-workspace delegate geometry;
- a second overview-only special-workspace list.

## 15.8 Phase 10 — Multi-monitor and gesture hardening

Resolve and implement:

- per-monitor versus global pager presentation;
- bar ownership by monitor;
- special-workspace icon choice with multiple visible states;
- direct click routing across monitors;
- overview invocation monitor;
- focused-window action monitor;
- hotplug;
- mixed scale and rotation;
- gesture conflicts and workspace-swipe ownership.

## 15.9 Phase 11 — Visual and accessibility polish

Validate:

- group-transition motion;
- reduced motion;
- focus visibility;
- text scaling;
- semantic label tooltips;
- icon consistency;
- high contrast;
- urgent-state policy if later accepted;
- pointer target sizing on all bar orientations.

---

# 16. Fixtures and Test States

Fixtures must not depend on live Hyprland, overview, or Vicinae services.

## 16.1 Numbered workspace fixtures

Provide at least:

1. minimum `1`, maximum `10`, group size `5`, active `1`;
2. active `5`;
3. active `6`;
4. active `7`;
5. active `10`;
6. range `1–15`, active `11`;
7. partial final group such as maximum `12`, active `11`;
8. group size `3`;
9. group size `10`;
10. wrapping disabled at minimum;
11. wrapping disabled at maximum;
12. wrapping enabled at both ends;
13. semantic labels present;
14. no semantic labels;
15. state unavailable;
16. reconnect after unavailable;
17. active number outside configured range;
18. rapid scroll sequence;
19. active-workspace overview available;
20. active-workspace overview unavailable;
21. overview invocation busy;
22. overview invocation failure.

## 16.2 Special-workspace fixtures

Provide at least:

1. six configured entries, none visible;
2. Music visible;
3. Scratchpad visible;
4. operation in progress;
5. one toggle failure;
6. one unavailable definition;
7. empty configuration;
8. invalid candidate configuration while last valid remains active;
9. long labels;
10. missing optional shortcut hints;
11. fallback icon;
12. multiple visible IDs across two monitor contexts;
13. monitor hotplug while selector is open.

## 16.3 Focused-window fixtures

Provide at least:

1. normal tiled window;
2. floating window;
3. fullscreen window;
4. long title;
5. missing title/app metadata;
6. no focused window;
7. target disappears while menu is open;
8. target disappears during kill confirmation;
9. move-to-numbered success;
10. move-to-numbered failure;
11. move-to-special success;
12. toggle floating failure;
13. graceful close;
14. force-kill confirmation cancelled;
15. force-kill confirmed;
16. unsupported action omitted;
17. configuration reload removes an action while surface is open.

## 16.4 Presentation fixtures

Test:

- left, right, top, and bottom bar edges;
- minimum and maximum supported text scale;
- reduced motion;
- high contrast;
- fallback theme;
- dynamic theme transition;
- fractional scale;
- rotated monitor;
- two bars with different monitor-local workspace states;
- keyboard-only traversal;
- pointer-only operation.

---

# 17. Acceptance Criteria

## 17.1 Phase 2 acceptance

The fixture workspace foundation is accepted when:

- active workspace `1` shows group `1–5`;
- active workspace `5` still shows `1–5`;
- active workspace `6` shows `6–10`;
- active workspace `7` shows `6–10`;
- no occupancy marker appears;
- no application icon appears;
- selected state does not change delegate size;
- inactive fixture number activation invokes the injected controller;
- scroll moves one normalized step;
- rapid high-resolution scroll does not dispatch unlimited commands;
- keyboard focus enters on the active number;
- arrow navigation follows pager geometry;
- group change preserves valid focus;
- active-workspace activation is routed through a replaceable policy hook;
- overview failure does not disable the pager;
- special-workspace fixture selector opens, navigates, toggles, and dismisses;
- `Escape` restores focus correctly.

## 17.2 Phase 4 live-adapter acceptance

The live workspace integration is accepted when:

- pager selection follows real Hyprland workspace changes;
- clicking an inactive workspace switches to it;
- direct compositor shortcuts update the pager immediately through events;
- special-workspace selector reflects real visibility;
- toggling an active special workspace closes it;
- adapter reconnect restores truthful state without shell restart;
- maximized windows do not trigger fullscreen workspace policy;
- no workspace view issues raw Hyprland commands;
- invalid configuration reload retains the previous valid model;
- command failures are structured and locally contained.

## 17.3 Phase 6 daily-use acceptance

The daily-use workspace feature is accepted when:

- numbered and special workspace navigation can replace the current shell's equivalent workflow for a normal session;
- pointer and keyboard paths are both practical;
- the pager remains stable through rapid switching;
- the special control remains one persistent slot;
- semantic definitions are shared from one configuration model;
- optional integration failures do not block navigation;
- one full day of use produces no blocker-level workspace issue;
- idle resource use and interaction latency are recorded.

## 17.4 Phase 7 overview acceptance

Overview integration is accepted when:

- a known-working revision is pinned;
- invocation uses a documented adapter path;
- shell surfaces close before overview opens;
- overview consumes derived shared workspace definitions;
- special workspace definitions match the bar;
- active-workspace prototype invocation does not create duplicate processes;
- overview failure produces an actionable local error;
- direct numbered and special workspace operations continue after failure;
- mixed-scale and multi-monitor behaviour is tested;
- screencopy failure does not crash the main shell.

## 17.5 Focused-window action acceptance

Focused-window actions are accepted when:

- no permanent title is added to the bar;
- the action surface opens through the settled invocation path or paths;
- initial focus lands on a safe action;
- move target lists come from authoritative configuration;
- floating and fullscreen actions use normalized state;
- graceful close and force-kill are distinct;
- force-kill requires confirmation;
- a target disappearing invalidates destructive confirmation;
- `Escape` unwinds nested pickers and confirmation correctly;
- no action retargets silently to a newly focused window;
- failures are understandable and do not crash the shell.

## 17.6 Multi-monitor hardening acceptance

After final policy is settled:

- each bar presents the intended monitor-specific or global group consistently;
- direct workspace click routing is deterministic;
- special-workspace icon policy is deterministic with multiple visible states;
- pointer and keyboard invocation choose the documented monitor;
- hotplug closes or remaps transient surfaces safely;
- mixed scale and rotation preserve readability and hit targets;
- no component assumes a single monitor internally.

---

# 18. Unresolved Questions

The following questions remain open and must not be silently settled during implementation.

## 18.1 Active-workspace activation

- **Q-017:** Whether primary click on the active workspace opens quickshell-overview.
- Is that behaviour discoverable?
- Does it feel inconsistent with inactive-number direct switching?
- Should overview instead use secondary click?
- Should keyboard `Enter` on the active number perform the same action?
- How should accidental activation be prevented during rapid pointer switching?

The Phase 2 prototype may request overview, but the action must remain a controller policy.

## 18.2 Focused-window action entry point

- **Q-018:** Which path is the default focused-window-action entry point?
- Secondary click on active workspace?
- Dedicated keyboard shortcut?
- quickshell-overview action?
- Vicinae command?
- More than one path?

No right-click-only design is acceptable for the only meaningful path.

## 18.3 Overview invocation and configuration

- **Q-082:** Exact one-way shared-configuration mechanism for quickshell-overview.
- **Q-083:** Live preview stability under rapid changes, fullscreen, mixed scale, rotation, multiple monitors, and suspended NVIDIA GPU.
- **Q-084:** Overview invocation from the bar and accidental activation prevention.
- Exact pinned overview revision.
- Exact IPC contract and compatibility detection.
- Whether standalone or vendored topology remains the long-term strategy.

## 18.4 Numbered-range mismatch fallback

The baseline forbids fabricated state but does not settle the final visual presentation when Hyprland activates a numbered workspace outside the configured range.

Prototype and document options before release.

## 18.5 Urgent workspace treatment

The adapter may expose urgency, but no resting-pager visual policy is settled.

Do not add a prominent urgency marker without a new decision.

## 18.6 Multiple special workspaces across monitors

- Which icon should a bar show if multiple special workspaces are visible across the session?
- Should each bar show only its monitor-local special workspace?
- Should an overflow/stack state appear?
- How should keyboard selector focus choose among multiple visible entries?

## 18.7 Multi-monitor workspace pager

- **Q-088:** Which monitors show bars.
- **Q-089:** Whether each pager is monitor-local or all bars follow global focus.
- How does clicking a workspace associated with another monitor behave?
- Does the visible group follow the focused monitor, invoking bar, or globally active workspace?
- How does the user's semantic workspace model translate to multi-monitor use?

## 18.8 Focused-window target lifetime

The safe baseline captures a target and refuses destructive retargeting, but the final live-follow behaviour for non-destructive metadata/actions remains to be tested.

## 18.9 Selector layout polish

List versus compact grid and exact geometry are not explicitly settled. The implementation may prototype a practical layout but must preserve keyboard coherence, compactness, and bar-edge attachment.

## 18.10 Cross-cutting blockers

The following broader unresolved items affect complete implementation:

- **Q-001:** Exact Quickshell baseline and Hyprland module capabilities.
- **Q-002:** Retained Caelestia service inventory.
- startup/supervision and reload behaviour;
- final icon strategy;
- final multi-monitor policy;
- exact gesture ownership with Hyprland.

Fixtures and normalized adapter contracts may be implemented before these are resolved. Backend-specific assumptions must not leak into workspace views.

---

# 19. Codex Implementation Guardrails

Codex must not:

- show workspace occupancy;
- add application icons to the numbered pager;
- add a permanent active-window title;
- show all special-workspace icons permanently in the bar;
- make labels stable identifiers;
- maintain separate special-workspace lists for the bar and overview;
- call `hyprctl` directly from QML delegates;
- hard-code Hyprland dispatcher syntax in feature views;
- rebuild quickshell-overview inside Franken Shell;
- disable direct switching when overview fails;
- hard-code active-workspace click behaviour into the delegate;
- make secondary click the only focused-window-action path;
- force-kill without confirmation;
- retarget a destructive action to whichever window becomes focused later;
- assume only one monitor in service or controller models;
- infer final multi-monitor policy from implementation convenience;
- auto-launch a special workspace's `defaultApplication` merely because the workspace is empty;
- add unapproved urgency or occupancy decorations;
- use blocking external commands on the UI thread;
- create parallel authoritative workspace state in the bar, overview adapter, Vicinae extension, or settings UI.

Codex should:

- begin with fixtures;
- keep workspace calculations deterministic and testable;
- keep views backend-agnostic;
- route all commands through normalized adapters;
- preserve direct navigation as the fallback path;
- record prototype decisions before promoting them to settled behaviour;
- add new decisions to `decisions.md` and unresolved findings to `open-questions.md` rather than silently encoding them.
