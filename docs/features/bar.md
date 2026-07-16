# Franken Shell — Persistent Bar

> **Path:** `docs/features/bar.md`  
> **Status:** Implementation specification  
> **Primary phase:** Phase 2 — Bar Foundation  
> **Daily-use completion:** Phase 6 — Working Daily-Use Prototype  
> **Related documents:** `product-vision.md`, `design-principles.md`, `feature-map.md`, `interaction-language.md`, `visual-language.md`, `architecture.md`, `configuration-model.md`, `implementation-phases.md`, `decisions.md`, `open-questions.md`

This document specifies the persistent Franken Shell bar as a Quickshell/QML feature.

It converts the settled product and architecture decisions into an implementation contract while keeping unresolved design questions explicit. Codex must not resolve items in the final **Unresolved Questions** section merely because one implementation is easier.

---

# 1. Product Role

The bar is Franken Shell's persistent edge-attached navigation and immediate-status surface.

Its resting purpose is to provide:

- stable numbered-workspace navigation;
- access to configured special workspaces;
- exceptional and currently relevant contextual state;
- access to tray applications without exposing every tray icon;
- persistent download throughput;
- compact audio, resource, battery, date/time, and Vicinae entry points;
- anchors for focused edge-attached popovers.

The bar must remain:

- minimal by default;
- quietly visible during ordinary work;
- stable while values and contextual states change;
- usable by keyboard and pointer;
- capable of all four screen edges;
- responsive even when optional services are missing.

The bar is not a general dashboard. Detailed management belongs in popovers, the control centre, Vicinae, quickshell-overview, or specialist applications.

---

# 2. Settled Requirements

The requirements in this section are settled unless a later decision explicitly supersedes them.

## 2.1 Form and placement

- The bar is one **continuous rail**, not a set of floating islands.
- Default edge is `left`.
- The architecture must support `left`, `right`, `top`, and `bottom`.
- Support for other edges must be orientation-aware; do not implement them by rotating the completed left bar.
- The bar remains visible with tiled windows.
- The bar remains visible with maximized windows.
- The bar hides in true fullscreen.
- Maximized state must never be treated as fullscreen.
- Optional autohide exists, but it is disabled by default.
- Pointer reveal over true fullscreen is disabled by default.
- Prototype thickness is approximately `44–48` logical pixels, with the exact value unresolved.

## 2.2 Resting hierarchy

The logical layout order is fixed for the initial product:

```text
START
├─ Numbered workspace pager
├─ Special-workspace control
├─ Flexible space
├─ Fixed contextual-status region
├─ Collapsed tray
├─ Download speed
├─ Audio
├─ Resource indicator
├─ Battery
├─ Date/time
└─ Vicinae
END
```

Additional rules:

- Vicinae occupies the absolute end.
- Navigation belongs at the start.
- Stable system status and command access belong at the end.
- The contextual region must not move the end-anchored controls.
- Semantic zones are separated primarily by spacing, not a separator between every item.
- Arbitrary user reordering is not part of the initial settings surface.

## 2.3 Persistent content rules

- Numbered workspaces are stable semantic locations.
- Exactly one numbered-workspace group is shown at rest; default group size is five.
- The visible group follows the active numbered workspace.
- Workspace occupancy is not shown.
- Application icons are not shown in the workspace pager or elsewhere in the resting bar, except through the collapsed tray affordance itself.
- Active-window title is not shown permanently.
- All special workspaces share one adaptive bar slot.
- Normal Wi-Fi and Ethernet connectivity are silent.
- Exceptional connectivity is shown through contextual status.
- Current download speed is always shown while the feature is enabled.
- Audio uses one persistent slot whose icon reflects the active output or mute state.
- RAM usage is the persistent resource metric.
- Battery is represented by plain numeric percentage text rather than a permanent battery glyph.
- Date and time form one combined control using 24-hour time by default.
- There is no notification badge or global unread count in the bar.
- Weather is not shown in the bar.

## 2.4 Visual requirements

- The bar uses shared semantic theme tokens, never raw wallpaper colours in feature delegates.
- It is opaque enough to remain legible over any wallpaper.
- Decorative blur is optional and must not be required for readability.
- Passive items use restrained neutral treatment.
- Accent is reserved for selected, active, focused, charging, warning, or otherwise meaningful state.
- Live numeric values use tabular numerals.
- Ordinary value changes must not animate or move neighbouring controls.
- Pointer targets should generally be approximately `36–40` logical pixels even when visible glyphs are smaller.
- Keyboard focus must remain visible independently of selection or active fill.
- Privacy and recording states must not rely on colour alone.
- Reduced-motion mode removes nonessential motion and charging animation while preserving state clarity.

## 2.5 Surface and focus rules

- Bar popovers are owned by the shared `SurfaceCoordinator`.
- Only one bar popover may be open globally at a time.
- Opening the control centre closes bar popovers.
- Opening quickshell-overview closes ordinary bar popovers.
- Opening Vicinae closes ordinary bar popovers.
- A popover opens inward from the configured bar edge.
- `Escape` closes the active popover and restores focus.
- When no child surface is open, `Escape` while the bar itself has keyboard focus returns focus to the previously focused application.
- Feature components request surface changes; they do not directly manage unrelated top-level windows.

---

# 3. Scope and Ownership

## 3.1 The bar feature owns

- creation and layout of the persistent rail content;
- logical start, context, end, and absolute-end zones;
- orientation-aware composition;
- per-monitor bar view instances;
- item hit targets, tooltips, accessible names, and focus order;
- visual representation of normalized controller state;
- forwarding user intent to feature controllers and `SurfaceCoordinator`;
- visibility response to fullscreen and later autohide state;
- anchor geometry exported for popovers;
- fixture models for component and visual testing;
- bar-specific diagnostics such as layout overflow or invalid item contracts.

## 3.2 The bar feature does not own

- Hyprland event acquisition or dispatcher syntax;
- workspace definitions;
- special-workspace persistence;
- network interface sampling;
- connectivity detection;
- PipeWire or WirePlumber state;
- battery acquisition;
- sensor polling;
- StatusNotifierItem protocol handling;
- Vicinae invocation details;
- quickshell-overview implementation;
- notification policy;
- auto-cpufreq configuration;
- calendar data;
- global focus restoration policy;
- global surface conflict policy.

These belong behind shared services, controllers, integrations, and the `SurfaceCoordinator`.

## 3.3 Delegated feature depth

The bar provides entry points, not complete implementations, for:

- special-workspace selector;
- tray drawer;
- compact audio popover;
- resource popover;
- power and auto-cpufreq panel;
- calendar;
- contextual-status summary;
- focused-window actions;
- Vicinae direct-entry menu.

Their internal content is specified in their own feature documents. The bar specification defines only the trigger, anchor, availability, focus handoff, and failure presentation.

---

# 4. Proposed QML Structure

The following structure is implementation guidance, not a requirement to create empty files in advance.

```text
surfaces/
└── BarHost.qml

features/bar/
├── BarView.qml
├── BarController.qml
├── BarLayout.qml
├── BarItemFrame.qml
├── BarFocusController.qml
├── WorkspacePagerItem.qml
├── SpecialWorkspaceItem.qml
├── ContextStatusRegion.qml
├── TrayItem.qml
├── NetworkSpeedItem.qml
├── AudioItem.qml
├── ResourceItem.qml
├── BatteryItem.qml
├── DateTimeItem.qml
├── VicinaeItem.qml
├── formatters/
│   ├── ThroughputFormatter.js
│   ├── PercentageFormatter.js
│   └── DateTimeFormatter.js
└── fixtures/
    └── BarFixtureModel.qml
```

Do not split a small implementation into all of these files merely to match the example. Separate a component when it has an independent responsibility, reusable contract, or meaningful test surface.

## 4.1 `BarHost`

Recommended Quickshell primitive: `PanelWindow`, subject to the pinned Quickshell baseline.

Responsibilities:

- bind to one normalized `MonitorModel`;
- anchor to the configured edge;
- reserve compositor space while persistently shown;
- expose the inward edge and global anchor geometry;
- hide for normalized true-fullscreen state;
- host autohide mechanics later without changing child-item contracts;
- contain no backend-specific service calls;
- remain lightweight enough for one instance per configured monitor.

## 4.2 `BarController`

The controller prepares presentation-ready state from shared models.

Suggested responsibilities:

- derive orientation and logical navigation axis;
- derive active numbered-workspace group;
- expose ordered special-workspace presentation state;
- obtain prioritized contextual indicators from a context-status controller;
- normalize availability and degraded states for each item;
- provide action methods that call feature controllers, adapters, or `SurfaceCoordinator`;
- expose fixed-width formatting values;
- record bar-specific errors without owning service recovery.

It must not duplicate authoritative service state.

## 4.3 `BarLayout`

The layout should model logical zones rather than hard-coded coordinates:

```text
startZone
flexibleSpacer
contextZone
endZone
absoluteEndZone
```

For a vertical bar, logical order maps along the vertical axis. For a horizontal bar, it maps along the horizontal axis.

The layout must:

- keep `absoluteEndZone` at the physical end;
- prevent context-region changes from shifting `endZone`;
- use bounded cells for live metrics;
- expose overflow diagnostics rather than silently clipping interactive items;
- support text scaling within the documented initial range;
- preserve hit targets even when glyphs are visually compact.

## 4.4 Common bar-item contract

Each bar item should expose a common conceptual contract:

```text
id
available
visible
interactive
enabled
status
accessibleName
accessibleDescription
tooltipText
preferredExtent
minimumExtent
focusOrder
primaryAction()
secondaryAction()
middleAction()
scrollAction(delta)
anchorRect
```

Not every item implements every action. Unsupported actions must be absent or no-op without misleading hover or focus treatment.

A component must distinguish:

- **unavailable capability:** backend or hardware does not exist;
- **degraded service:** capability exists but the service currently failed;
- **inactive state:** normal state with no activity;
- **disabled by configuration:** feature intentionally hidden or disabled.

---

# 5. State and Data Requirements

## 5.1 Shared bar state

The bar view needs the following normalized state:

```text
BarState {
    monitor
    edge
    orientation
    thickness
    enabled
    persistentVisible
    fullscreenSuppressed
    autohideEnabled
    autohideState
    keyboardFocused
    activePopoverKind
    activePopoverAnchor
    reducedMotion
    highContrast
    textScale
}
```

`autohideState` may remain a placeholder until Phase 6, but its eventual addition must not require rewriting every item.

## 5.2 Monitor state

Each instance consumes a `MonitorModel` with at least:

```text
id
name
geometry
scale
transform
focused
primary
barEnabled
barEdge
fullscreenWorkspace
```

The bar must not depend only on a raw Qt screen object when Hyprland identity is required.

## 5.3 Fullscreen state

A single normalized Hyprland fullscreen value must drive:

- bar visibility;
- pointer autohide reveal suppression;
- notification popup suppression elsewhere;
- right-edge control-centre reveal suppression elsewhere.

The bar must not run its own independent fullscreen detection.

## 5.4 Item data matrix

| Item | Required normalized data | Primary source/controller |
|---|---|---|
| Workspace pager | active numbered workspace, configured minimum/maximum, group size, overview availability | Hyprland/workspace controller, overview adapter |
| Special workspace | configured definitions, visible special workspace, active icon, action availability | workspace controller |
| Context status | prioritized indicator list, severity, icon, destination, overflow state | context-status controller composed from services |
| Tray | item count, attention summary, availability | tray controller |
| Download speed | raw and smoothed down/up rate, formatted values, sampling health | throughput controller |
| Audio | default output category, volume, mute, output availability | audio controller |
| Resource | memory percent, warning state, service health | resource controller |
| Battery | availability, percentage, charging, warning/critical state, power-panel availability | battery/power controller |
| Date/time | local date/time, locale, format configuration | clock/date-time controller |
| Vicinae | installed/available, invocation state, adapter error | Vicinae adapter |

## 5.5 Stable value formatting

Live metrics must be formatted before reaching visual delegates where practical.

Formatting requirements:

- network: whole-number compact unit, such as `0K`, `3K`, `20M`, `1G`;
- resource: centred whole-number memory percentage;
- battery: whole-number percentage value, with percent sign unresolved;
- time: 24-hour by default;
- date: compact and unambiguous;
- all live numerals: tabular numeral role.

Formatting code should be pure and unit-testable.

---

# 6. Layout and Orientation Behaviour

## 6.1 Logical directions

All layout and popup placement logic should use:

- `start`;
- `end`;
- `inward`;
- `outward`;
- `mainAxis`;
- `crossAxis`.

Avoid scattering direct `left`, `right`, `top`, and `bottom` conditionals across item delegates.

## 6.2 Edge mapping

| Bar edge | Main-axis order | Popover direction | Primary directional keys |
|---|---|---|---|
| Left | top to bottom | right | Up / Down |
| Right | top to bottom | left | Up / Down |
| Top | left to right | down | Left / Right |
| Bottom | left to right | up | Left / Right |

This mapping does not settle exact top/bottom date-time formatting or the final corner treatment.

## 6.3 Stable zones

The start and end zones must not move during ordinary updates.

Required techniques include:

- fixed or bounded metric extents;
- tabular numerals;
- a fixed-capacity contextual region;
- collapsed tray representation;
- no workspace occupancy icons;
- no active-window title;
- no animation of individual throughput digits;
- no dynamic insertion of normal connectivity icons.

Capability changes such as physically removing a battery may legitimately alter the long-term layout. Ordinary state changes must not.

## 6.4 Overflow handling

The bar must not silently clip actionable items.

If content cannot fit:

1. keep the absolute-end Vicinae entry reachable;
2. preserve the designed semantic order;
3. collapse contextual status through its overflow affordance;
4. expose a diagnostic warning;
5. do not invent hidden automatic reordering;
6. do not shrink pointer targets below the supported minimum without an explicit compact-mode decision.

A general compact-mode policy is not yet settled.

---

# 7. Component Specifications

## 7.1 Numbered workspace pager

### Settled presentation

- Show one group of numbered workspaces.
- Default group size is five.
- Group is calculated from the active numbered workspace.
- Examples: active workspace `2` shows `1–5`; active workspace `7` shows `6–10`.
- Active workspace uses a clear selected container.
- Inactive workspaces remain lower emphasis.
- No occupancy markers.
- No application icons.
- No permanent semantic labels; optional labels may appear in tooltips.

### Required state

```text
activeWorkspaceNumber
minimumWorkspaceNumber
maximumWorkspaceNumber
groupSize
visibleNumbers[]
overviewAvailable
overviewError
```

### Pointer interaction

- Primary click on an inactive number switches directly to it.
- Scroll moves one numbered workspace at a time according to configured direction.
- Crossing a group boundary updates the visible group.
- Secondary-click behaviour for the active workspace is reserved for the focused-window-action decision.
- The provisional prototype action for primary click on the active workspace is to request quickshell-overview.

The active-workspace primary action remains an unresolved UX question and must be isolated behind a configurable/controller action rather than hard-coded into the delegate.

### Keyboard interaction

- Direct Hyprland workspace shortcuts remain the fastest path.
- When bar focus is active, arrow keys move among visible workspace numbers along the bar axis.
- `Enter` invokes the same primary action as pointer activation.
- The active item receives initial focus when the pager is entered.
- A group transition must not lose keyboard focus.

### Failure state

If overview is unavailable:

- inactive workspace switching remains functional;
- active-workspace invocation must not crash;
- show a compact actionable failure through the normal integration-error channel;
- do not disable the entire pager.

If Hyprland workspace state is temporarily unavailable:

- do not fabricate an active workspace;
- display a disabled/degraded pager state or last-known-good state with clear diagnostics;
- retry through the Hyprland adapter rather than from the delegate.

## 7.2 Special-workspace control

### Settled presentation

- One persistent slot represents all configured special workspaces.
- Neutral stack glyph when none is visible.
- Configured icon of the visible special workspace when one is open.
- Active numbered workspace remains selected independently.
- Cell extent does not change when the glyph changes.

Initial configured examples are Music, Movies/Anime, Books, Discord, Scratchpad, and Todo, but the control consumes shared configuration rather than hard-coding them.

### Required state

```text
specialWorkspaces[]
visibleSpecialWorkspaceId
activeIcon
selectorAvailable
```

### Interaction

- Primary click opens the special-workspace selector.
- Selector initial focus is the active workspace, otherwise the first configured item.
- Activating an inactive special workspace opens it.
- Activating the currently visible special workspace closes it.
- Selector closes after a successful activation.
- `Escape` closes the selector.
- Dedicated Hyprland bindings remain the fastest path.

### Failure and empty states

- If no special workspaces are configured, hide the item rather than showing a dead stack icon.
- If one configured workspace action fails, keep the selector open long enough to show the error and permit retry.
- Do not maintain a second special-workspace list in the bar.

## 7.3 Flexible space

The flexible spacer separates navigation from contextual and system state.

It must:

- consume remaining main-axis space;
- allow context and end zones to remain anchored;
- not receive keyboard focus;
- not capture pointer input;
- not be replaced by active-window title or decorative content.

## 7.4 Contextual-status region

### Settled behaviour

- The region is fixed-capacity so end controls do not move.
- Normal state remains silent.
- Contextual, exceptional, and critical states may appear.
- Indicators are compact and primarily icon-based.
- Overflow uses a stack/summary affordance.
- Critical state has priority over lower-priority activity.
- State must be distinguishable without relying only on colour.

### Required normalized indicator contract

```text
ContextIndicator {
    id
    category
    severity
    icon
    accessibleName
    tooltip
    active
    persistent
    priority
    destination
    payload
}
```

### Candidate categories, not yet accepted taxonomy

- connectivity failure or captive portal;
- microphone capture;
- camera capture;
- screen recording or sharing;
- idle inhibitor;
- VPN;
- non-audio Bluetooth device;
- transfer activity;
- critical shell or system alert.

The final allowed taxonomy and exact slot count remain unresolved.

### Interaction

- Primary click opens the most relevant detail surface for that indicator.
- Keyboard focus exposes the same action.
- Overflow activation opens a compact status summary ordered by severity and configured priority.
- Indicators must not independently open unrelated top-level windows.

### Error behaviour

A service failure should not automatically become a persistent context indicator unless the taxonomy explicitly admits it. Service health belongs in diagnostics unless it materially affects the user now.

## 7.5 Collapsed tray affordance

### Settled presentation

- One compact affordance represents all tray items.
- Hidden when no tray items exist.
- No persistent tray count.
- No tray application is pinned by default.
- Attention may alter the affordance, but exact semantics are unresolved.

### Required state

```text
trayAvailable
itemCount
hasAttention
attentionSeverity
trayDrawerAvailable
```

### Interaction

- Primary click opens the tray drawer.
- Keyboard opening focuses the first tray item.
- Tray drawer preserves application-provided primary activation, context menu, and scroll behaviour.
- Bar code must not reinterpret individual tray-item semantics.

### Failure state

- If tray service is unavailable, hide the normal affordance or show an explicit degraded state only when diagnostics discoverability requires it.
- Do not reserve an always-visible dead tray cell.
- A tray-menu failure is isolated to that item and reported without closing the entire shell.

Tray drawer geometry, stable ordering, pinning UX, and attention policy remain separate unresolved questions.

## 7.6 Download-speed item

### Settled presentation

- Always show current download speed while enabled.
- Whole numbers only.
- One-letter unit suffix.
- No `/s` in resting text.
- No direction arrow in resting text.
- Tooltip shows both download and upload with arrows and may include `/s`.
- Use fixed extent and tabular numerals.
- Smooth raw samples.
- Do not animate ordinary updates.

### Required state

```text
rawDownloadRate
rawUploadRate
smoothedDownloadRate
smoothedUploadRate
formattedDownload
formattedTooltip
samplingHealthy
```

### Interaction

- Hover or keyboard focus shows the tooltip.
- No primary-click action is required for the first prototype.
- The eventual click destination remains unresolved and must not be invented.

### Failure state

- Temporary counter-read failure shows last-known-good value briefly, then a neutral unavailable representation if failure persists.
- Do not display fabricated `0K` when the service is unavailable.
- Failure should not cause cell width changes.
- Recovery should occur without shell restart.

## 7.7 Audio item

### Settled presentation

Use one semantic icon based on normalized audio state:

- speaker;
- wired headphones;
- Bluetooth headphones or headset;
- HDMI/display audio where supported by icon mapping;
- muted;
- unknown output.

Do not add a second permanent headphone or Bluetooth-audio icon.

### Required state

```text
audioAvailable
currentOutputCategory
currentOutputName
volume
muted
popoverAvailable
lastError
```

### Interaction

- Primary click toggles the compact audio popover.
- Scroll adjusts master output volume using configured step.
- Middle click toggles mute.
- Volume changes publish to the shared OSD channel.
- Repeated wheel events update one OSD instance.
- Keyboard activation opens the popover and focuses master volume.

### Failure state

- If audio backend is unavailable, show an unavailable icon and useful tooltip rather than an ordinary muted icon.
- Scroll and middle click are disabled while unavailable.
- The bar remains usable.

The exact boundary between compact audio popover and control-centre mixer is specified elsewhere and remains partly unresolved.

## 7.8 Resource indicator

### Settled presentation

- Circular progress arc represents RAM usage.
- Whole-number percentage is centred.
- No `RAM` label.
- Warning state may change semantic treatment.
- Ordinary changes do not animate continuously.

### Required state

```text
resourceAvailable
memoryPercent
memoryWarning
memoryCritical
popoverAvailable
systemMonitorAvailable
```

### Interaction

- Primary click toggles the resource popover.
- Keyboard opening provides a visible launch action.
- The resource popover may treat a clearly indicated body click as launching the configured full system monitor.
- The bar item itself does not launch the external monitor directly.

### Failure state

- If memory statistics are unavailable, show an explicit unavailable state rather than a false zero ring.
- Missing detailed sensors do not affect the persistent RAM indicator.
- Missing system-monitor command does not disable the popover.

## 7.9 Battery item

### Settled presentation

- Plain whole-number battery percentage.
- No permanent battery icon.
- Charging uses accent plus restrained, non-flashing treatment.
- Warning and critical states use semantic roles.
- Tabular numerals.
- Primary click opens the power-management surface centred on auto-cpufreq.
- Missing auto-cpufreq does not remove basic battery status.

### Required state

```text
batteryAvailable
percentage
charging
powerSource
warning
critical
powerPanelAvailable
autoCpuFreqAvailable
```

### Interaction

- Primary click toggles the power panel.
- No scroll action in the initial version.
- Keyboard opening focuses the first safe power-panel control.

### Failure and unavailable states

- On systems without a battery, omit the item.
- If battery service fails on a system known to have a battery, show an unavailable state rather than a false percentage.
- If auto-cpufreq is absent, opening the panel still shows battery information and explains the missing integration.

The percent sign and exact charging treatment remain unresolved visual questions.

## 7.10 Date/time item

### Settled presentation

- Date and time are one control.
- Default time format is 24-hour.
- Date remains unambiguous.
- Vertical bars use a compact stacked presentation.
- Horizontal bars use an orientation-specific layout rather than rotated text.
- Current date may use accent.

### Required state

```text
currentDateTime
locale
timeFormat
firstDayOfWeek
showDate
monthFormat
calendarAvailable
```

### Interaction

- Primary click toggles the calendar.
- Keyboard opening focuses the current day.
- No secondary action is required initially.

### Failure state

- Clock display must not depend on calendar-provider availability.
- Google Calendar or other provider failure does not affect the local clock or month calendar.

The exact stacked arrangement, weekday display, and top/bottom formatting remain unresolved.

## 7.11 Vicinae item

### Settled presentation

- Occupies the absolute end.
- Uses a distinct command/search or Vicinae mark adapted to the shared icon system.
- Clearly indicates open state.
- Unavailable state uses warning treatment and tooltip without destabilizing the shell.

### Required state

```text
vicinaeAvailable
vicinaeOpen
rootSearchAvailable
directEntries[]
lastError
```

### Interaction

- Primary click toggles Vicinae root search through `VicinaeAdapter`.
- Secondary click opens the direct-entry menu.
- Keyboard shortcut invocation is handled at shell/Hyprland integration level.
- The bar remains functional when Vicinae is absent.

### Failure state

- Invocation failure produces a compact actionable error or failure toast.
- Do not retry in a tight loop.
- Do not expose adapter-specific command strings in the item delegate.

---

# 8. Keyboard and Pointer Interaction

## 8.1 Focus entry

The shell must expose a configurable command to focus the bar on a chosen monitor. The exact default Hyprland binding belongs in the bindings specification.

When keyboard focus enters the bar:

- focus the active numbered workspace when available;
- otherwise focus the first enabled item in reading order;
- show a visible focus ring;
- prevent typing from leaking into the previously focused application;
- remember the previously focused application for restoration.

## 8.2 Directional navigation

Within the main bar sequence:

- vertical bar: `Up` and `Down` move between focusable items;
- horizontal bar: `Left` and `Right` move between focusable items;
- disabled or unavailable controls are skipped unless they expose an actionable repair path;
- entering a composite item such as the workspace pager uses directional keys consistent with visible geometry;
- `Tab` and `Shift+Tab` move between semantic control groups.

## 8.3 Activation

- `Enter` invokes the focused item's primary action.
- `Space` toggles only where the focused control is semantically a toggle.
- Context-menu keyboard action invokes the secondary action where one exists.
- No essential action may be available only through middle click, right click, hover, or gesture.

## 8.4 Pointer behaviour

- Primary click invokes the most common action.
- Secondary click exposes context or alternate entry points where specified.
- Middle click is limited to compact reversible actions, initially audio mute.
- Scroll affects only components with an obvious continuous or sequential relationship.
- Hover may show tooltip or visual emphasis but does not open major surfaces.
- Pointer targets must not overlap neighbouring actions.

## 8.5 Scroll arbitration

- Workspace scroll affects numbered workspace navigation.
- Audio scroll affects master volume.
- Nested popup content owns its own scrolling once open.
- Scrolling over non-scrollable cells does nothing.
- Rapid scroll coalesces updates and must not create repeated OSD windows.

## 8.6 Accessibility

Every item requires:

- accessible role;
- stable accessible name;
- state description where needed;
- tooltip for compact or icon-only controls;
- non-colour indication of warning, critical, privacy, and unavailable state;
- focus ring visible in dynamic light and dark palettes;
- logical traversal order;
- pointer hit target independent of glyph size.

---

# 9. Opening, Dismissal, and Focus Behaviour

## 9.1 Persistent visibility

The bar itself does not open and close during ordinary persistent mode.

It transitions among:

```text
Visible
FullscreenHidden
AutohideHidden        // Phase 6
AutohideRevealing     // Phase 6
AutohideVisible       // Phase 6
AutohideHiding        // Phase 6
Disabled
```

Fullscreen hiding is settled. Exact autohide state transitions and timing remain unresolved.

## 9.2 Popover opening

A bar item that owns a popover sends a request such as:

```text
SurfaceCoordinator.openPopover(
    kind,
    anchorRect,
    monitor,
    payload
)
```

The request includes:

- semantic kind;
- normalized monitor;
- global or monitor-local anchor rectangle;
- configured bar edge;
- optional payload;
- preferred size and dismissal policy where needed.

The item must not instantiate an unmanaged top-level window.

## 9.3 Pointer-opened surfaces

When opened by pointer:

- surface appears on the invoking bar's monitor;
- it opens inward from the edge;
- it may keep application keyboard focus until the user begins keyboard interaction, where technically reliable;
- clicking outside dismisses ordinary popovers;
- outside click must not discard protected edits, credentials, authentication, pairing prompts, or destructive confirmations.

## 9.4 Keyboard-opened surfaces

When opened through keyboard activation:

- surface takes focus immediately;
- initial focus target is deterministic;
- previously focused application is recorded;
- closing restores focus through the central focus controller.

## 9.5 Toggle and conflict rules

- Invoking the same open popover toggles it closed.
- Opening another bar popover replaces the current one.
- Opening control centre closes the popover.
- Opening overview closes the popover.
- Opening Vicinae closes the popover.
- Critical prompts may appear above an ordinary popover.
- Notification popups are coordinated separately and must not take bar focus unexpectedly.

## 9.6 Autohide and popovers

The architecture must permit a popover to pin its invoking bar visible. Whether all popovers do so, and exact hide timing after dismissal, remain unresolved under Q-016.

Do not hard-code autohide assumptions into each item.

---

# 10. Service and Integration Dependencies

The bar consumes normalized project adapters and controllers only.

## 10.1 Required core dependencies

- `ConfigService`
- `ThemeManager`
- `MonitorRegistry`
- `SurfaceCoordinator`
- project focus controller
- `CapabilityRegistry`
- `Diagnostics`
- clock/date-time service

## 10.2 Feature dependencies

- `HyprlandService` / workspace controller
- `OverviewAdapter`
- special-workspace configuration model
- context-status controller
- `TrayService` / tray controller
- `ThroughputService`
- `NetworkService` for connectivity exceptions
- `AudioService` / audio controller
- `ResourceService`
- `BatteryService`
- `AutoCpuFreqService` for the deeper power surface
- `CalendarService`
- `VicinaeAdapter`
- OSD service for audio feedback
- toast/error channel for user-triggered failures

## 10.3 Integration boundary requirements

- No `hyprctl` calls in QML delegates.
- No direct `nmcli` calls in the bar.
- No direct PipeWire command execution in the bar.
- No direct filesystem polling from visual delegates.
- No raw Vicinae deeplink or command strings in the button.
- No direct auto-cpufreq writes from QML.
- No direct tray-protocol reinterpretation.
- External processes run asynchronously through the command registry or adapters.

## 10.4 Configuration consumed

The authoritative user configuration is TOML at
`$XDG_CONFIG_HOME/franken-shell/config.toml` under D-075. The bar consumes only
the typed immutable runtime snapshot published by `ConfigService`; it does not
parse TOML or invoke the Rust helper directly. The shared boundary is defined
by `docs/decisions.md`, `docs/configuration-model.md`, and
`docs/architecture.md`.

Relevant fields include:

```text
appearance.surfaceOpacity.bar
appearance.blur.enabled
appearance.font.scale
appearance.reducedMotion
appearance.highContrast

bar.enabled
bar.edge
bar.thickness
bar.visibleOn
bar.hideInFullscreen
bar.autohide.*
bar.workspacePager.*
bar.contextRegion.*
bar.networkSpeed.*
bar.battery.*
bar.dateTime.*
bar.vicinae.*

workspaces.numbered.*
workspaces.special[]
workspaces.overview.openOnActiveWorkspaceClick

tray.*
audio.volumeStep
audio.middleClickMute
audio.scrollOnBar
resources.barIndicator.*
monitors.*
```

Invalid configuration must never partially mutate a live bar. The bar rebinds only after `ConfigService` publishes an atomically validated configuration.

---

# 11. Error and Unavailable States

## 11.1 General rules

- Never fabricate normal-looking state when a service is unavailable.
- Never allow one optional integration failure to crash or hide unrelated bar controls.
- Use last-known-good state only for a bounded period and mark it stale when appropriate.
- Recovery occurs through the adapter; delegates do not run retry loops.
- Errors are structured and available in diagnostics.
- Ordinary service-health failures should not flood the contextual region.
- User-triggered action failures may use the shell's failure-toast channel.
- Hidden optional items should not leave unexplained empty focus stops.

## 11.2 Capability absence versus runtime failure

Examples:

- No physical battery: omit battery item.
- Battery present but UPower failed: show degraded battery state.
- No tray items: hide tray affordance.
- Tray protocol service failed: show degraded state only if useful; diagnostics must explain it.
- Vicinae not installed: keep item as an unavailable command entry only if that supports installation/repair discoverability; otherwise follow integration UX decision.
- Overview unavailable: keep workspace switching.
- Missing detailed sensors: RAM ring still works if memory data exists.
- No audio backend: show unavailable audio state, not mute.

## 11.3 Layout stability during failure

Runtime failure must not repeatedly add and remove cells in a way that makes the bar jump.

Prefer:

- preserving the cell with an unavailable state for a known capability that temporarily failed;
- omitting cells only for durable capability absence or explicit configuration;
- applying capability-set changes atomically after hotplug or service discovery settles.

## 11.4 Diagnostics

The bar should report at least:

```text
monitor identity
edge
resolved thickness
visibility state
fullscreen state
autohide state
active popover
focused item
item availability summary
context overflow
layout overflow
last action error
```

Do not log notification contents, credentials, clipboard data, or arbitrary window titles as part of bar diagnostics.

---

# 12. Multi-Monitor Considerations

The final product policy is unresolved, but the implementation must not assume a single monitor.

## 12.1 Provisional architecture

- Create bar instances from normalized configured-monitor models.
- Phase 2 may validate one left-edge bar first.
- Keep state ownership outside individual bar views.
- Pointer-invoked popovers use the invoking bar's monitor.
- Keyboard-invoked surfaces use the focused-window monitor under the provisional global policy.
- Only one bar popover is open globally.
- One global control centre may coexist with multiple bar instances, but opening it closes any bar popover.
- On monitor removal, close its surfaces and restore focus to a valid application.

## 12.2 Shared versus per-monitor state

The following are shared concepts unless later policy says otherwise:

- special-workspace definitions;
- tray item set;
- throughput source;
- audio state;
- battery state;
- date/time;
- Vicinae availability;
- global active popover.

The workspace pager's exact per-monitor presentation remains unresolved. Do not embed the assumption that every bar always shows one global active-workspace group if the underlying Hyprland model can expose monitor-specific active workspaces.

## 12.3 Scale and transform

Test and support:

- scale `1.0`;
- fractional scale;
- mixed scales;
- rotated monitors;
- different bar edges per monitor;
- hotplug;
- monitor identity persistence.

Thickness and hit targets are logical-pixel values and must resolve correctly per monitor.

## 12.4 Monitor-boundary behaviour

On adjacent monitors, an edge bar must bind to the intended monitor boundary without:

- capturing input on the neighbouring monitor;
- placing popovers across the wrong screen;
- reserving space on the wrong output;
- using stale scale or transform values.

---

# 13. Performance Considerations

## 13.1 Event-driven state

Use signals and normalized service models for:

- workspaces;
- special workspaces;
- audio state;
- battery state;
- tray changes;
- connectivity exceptions;
- Vicinae availability;
- fullscreen state.

## 13.2 Allowed continuous polling

Low-frequency polling is acceptable for:

- network throughput;
- RAM usage;
- integration health where no event API exists.

Suggested initial logical intervals from the configuration baseline:

- throughput: approximately `1000 ms`;
- RAM bar indicator: approximately `2000 ms`.

These are starting values, not performance guarantees.

## 13.3 QML responsiveness

- Never block the UI thread on external commands or file reads.
- Keep persistent delegates lightweight.
- Lazy-create popover content.
- Stop hidden animations and timers.
- Do not recreate delegates for every metric update.
- Cache stable icon and formatting results.
- Coalesce rapid scroll and service events.
- Keep charging animation low-frequency and disabled under reduced motion.
- Avoid blur or shader effects that harm frame pacing.

## 13.4 Layout performance

- Prefer stable cell sizes over repeated implicit-size negotiation.
- Do not measure long strings every sample tick.
- Throughput and percentage formatting must not trigger broad layout recalculation.
- Context-status replacement should update existing slots where possible.
- Workspace group transitions should be short and should not animate every ordinary workspace switch with a large movement.

## 13.5 Performance measurements

Record during Phase 6 and hardening:

- idle CPU;
- idle memory;
- wakeups caused by bar polling;
- bar creation latency;
- config/theme reload latency;
- pointer and keyboard response latency;
- frame pacing during workspace-group transitions;
- impact of one bar versus multiple bars.

Exact budgets are not yet settled, but regressions must be measured rather than accepted by visual impression alone.

---

# 14. Implementation Phases

## 14.1 Phase 1 — Core shell skeleton prerequisites

Before the bar feature is considered implementable, provide:

- validated configuration state;
- fallback theme and semantic tokens;
- monitor registry;
- surface coordinator;
- capability registry;
- command registry;
- fixture mode;
- basic focus restoration path;
- normalized fullscreen state or fixture.

## 14.2 Phase 2 — Bar foundation

Implement:

- one monitor-aware `BarHost`;
- first functional left-edge layout;
- logical orientation API from the start;
- semantic zones;
- fixture components for all resting items;
- workspace group calculation and interaction;
- one anchor-aware popover host;
- keyboard focus visuals;
- hide in true fullscreen;
- stable cell geometry.

Explicitly defer:

- real service integration;
- autohide;
- final all-edge polish;
- final multi-monitor product policy;
- detailed visual polish.

## 14.3 Phase 4 — Real adapters

Replace fixtures incrementally with:

- Hyprland workspace and fullscreen state;
- audio state and actions;
- battery state;
- throughput sampling;
- connectivity exceptions;
- Bluetooth context candidates;
- tray state and actions;
- resource summary.

Each adapter must fail independently.

## 14.4 Phase 6 — Daily-use completion

Complete:

- real numbered workspace pager;
- real special-workspace selector;
- contextual-status region;
- collapsed tray and tray drawer;
- persistent download speed;
- audio interactions;
- RAM ring and resource popover;
- battery and power entry point;
- date/time and local calendar;
- Vicinae entry point;
- optional autohide after Q-016 prototype decisions;
- keyboard reveal and pointer reveal for autohide;
- configurable delays;
- one full day of daily-use validation.

## 14.5 Phase 7 — Adopted integrations

Complete:

- quickshell-overview invocation and fallback;
- shared workspace configuration generation;
- Vicinae command mapping and theme integration;
- compatibility diagnostics.

## 14.6 Phase 9 — Settings

Expose only meaningful settings initially:

- edge;
- autohide enablement and settled behaviour;
- fullscreen behaviour;
- workspace group size;
- special-workspace definitions;
- throughput convention;
- monitor enablement;
- text scale;
- reduced motion.

Do not expose arbitrary per-item padding, unrestricted reordering, independent radii, or raw animation curves.

## 14.7 Phase 10 — Multi-monitor and gesture hardening

Finalize:

- which monitors own bars;
- per-monitor workspace-pager policy;
- per-monitor edges;
- hotplug behaviour;
- mixed scale and rotation;
- any trackpad interactions that affect bar reveal or focus;
- final performance measurements.

## 14.8 Phase 11 — Visual polish

Resolve through prototypes:

- exact thickness;
- flush versus inset geometry;
- date/time arrangement;
- battery percent sign;
- charging treatment;
- exact contextual capacity;
- opacity and blur;
- final motion duration;
- icon and font strategy.

---

# 15. Acceptance Criteria

## 15.1 Phase 2 acceptance

The bar foundation is accepted when all of the following pass:

- A left-edge continuous rail renders on the selected monitor.
- Architecture does not require rewriting item delegates to support right, top, and bottom edges later.
- Bar remains visible with a maximized window.
- Bar hides for normalized true fullscreen.
- Workspace `1–5` is shown when workspace `1` is active.
- Workspace `6–10` is shown when workspace `7` is active.
- Workspace occupancy and app icons are absent.
- Active workspace is visibly selected.
- Workspace click, scroll, keyboard focus, and activation work with fixtures.
- Context-region fixture changes do not move the end section.
- Changing throughput fixture values from `3K` to `999M` does not move neighbours.
- Changing battery values from single to triple digits does not move neighbours unexpectedly.
- Only one popover can be open.
- Popover opens inward from the configured edge abstraction.
- `Escape` closes popover and restores focus.
- All interactive items have visible keyboard focus.
- The bar remains usable at the initial supported text-scale range.
- Reduced-motion mode disables nonessential fixture animation.
- No visual delegate performs backend-specific command execution.

## 15.2 Adapter-integration acceptance

- Workspace state tracks Hyprland without treating maximized as fullscreen.
- Hyprland event-stream interruption can recover without shell restart.
- Throughput uses smoothed whole-number compact formatting.
- Tooltip shows both upload and download.
- Audio icon follows normalized output state.
- Audio scroll and middle-click operate through the audio controller and update one OSD.
- RAM ring tracks memory percentage without high-frequency polling.
- Battery absence, battery-service failure, and auto-cpufreq absence are visually distinct.
- Tray hides when empty and remains collapsed with many items.
- Tray application context menus work through the tray service.
- Vicinae failure affects only the Vicinae entry point.
- Overview failure does not prevent direct workspace switching.
- Each adapter can fail independently without crashing the bar.

## 15.3 Daily-use acceptance

- The bar can replace the existing bar for a normal work session.
- Its resting hierarchy matches the settled order exactly.
- Normal network and Bluetooth state remain silent.
- Exceptional connectivity appears contextually.
- Contextual changes do not shift stable controls.
- All main actions are available by both keyboard and pointer.
- Hover is not required for any essential action.
- Fullscreen applications remain free of the bar.
- Maximized applications retain the bar.
- Popovers, overview, control centre, and Vicinae coordinate without overlapping ordinary shell surfaces.
- Focus never remains on an invisible QML item after dismissal or monitor removal.
- Missing optional integrations produce localized, understandable degradation.
- Hidden popovers do not continue detailed sensor polling.
- Idle resource use and wakeups are measured and recorded.
- One full day of use produces no blocker-level bar issue.

## 15.4 All-edge and multi-monitor acceptance

Required before stable release, after the relevant open questions are resolved:

- Left, right, top, and bottom layouts are individually composed and readable.
- Text is not blindly rotated.
- Popovers open inward on every edge.
- Edge-aware corners and attached geometry are correct.
- Fractional scaling does not blur or clip text and arcs.
- Rotated monitors place and scale the bar correctly.
- Hotplug does not crash the shell or leave invisible focus.
- Multiple bar instances do not duplicate global service ownership.
- Pointer-invoked popovers appear on the invoking monitor.
- Workspace-pager presentation follows the final multi-monitor decision.

---

# 16. Test Fixtures

The fixture model should support at least these deterministic scenarios:

1. workspace `1` active;
2. workspace `7` active;
3. no special workspace visible;
4. Music special workspace visible;
5. context region empty;
6. no internet;
7. microphone active;
8. recording active;
9. idle inhibitor active;
10. context overflow;
11. tray empty;
12. many tray items;
13. tray attention;
14. throughput `0K`;
15. throughput `3K`;
16. throughput `999M`;
17. speaker output;
18. wired headphones;
19. Bluetooth headset;
20. audio muted;
21. audio unavailable;
22. RAM `9`, `55`, and `100` percent;
23. battery `7`, `87`, and `100` percent;
24. charging battery;
25. critical battery;
26. no battery;
27. date/time near midnight and month boundary;
28. Vicinae available, open, unavailable, and invocation failure;
29. maximized window;
30. true fullscreen;
31. left, right, top, and bottom edges;
32. text scale minimum and maximum;
33. reduced motion;
34. high contrast;
35. dynamic-theme reload;
36. monitor hotplug simulation;
37. service reconnect while popover is open.

Fixtures must not depend on live system services.

---

# 17. Unresolved Questions

The following questions remain open and must not be silently settled in implementation.

## 17.1 Geometry and visual treatment

- **Q-007:** Exact bar thickness within or around the `44–48` logical-pixel prototype range.
- **Q-008:** Full-height/width flush rail versus inset rail and outer margins.
- **Q-009:** Whether battery resting text includes `%`.
- **Q-010:** Exact charging treatment and reduced-motion equivalent.
- **Q-011:** Exact vertical date/time arrangement, weekday use, and top/bottom layout.
- **Q-098:** Final font family.
- **Q-099:** Final coherent icon strategy.
- **Q-100:** Initial light-mode support scope.
- **Q-101:** Final bar blur policy.
- **Q-102:** Theme-transition behaviour during wallpaper changes.

Prototype values may be used behind centralized tokens, but they must not be recorded as settled decisions without user validation.

## 17.2 Throughput

- **Q-012:** Bytes or bits by default, decimal or binary base, zero format, smoothing, aggregation, VPN/tunnel treatment, and local-only traffic.
- **Q-013:** Primary-click action for persistent download speed.

The current recommendation is bytes per second, base `1000`, whole numbers, and no primary-click action in the first prototype.

## 17.3 Contextual status

- **Q-014:** Exact fixed slot count and overflow threshold.
- **Q-015:** Final indicator taxonomy, priority, persistence, icon, and click destination.
- **Q-049:** Reliable definition of actual microphone capture versus merely unmuted input.
- **Q-056:** Which non-audio Bluetooth devices deserve bar visibility.

The configuration example's `slots: 3` and category priority list are provisional, not settled.

## 17.4 Autohide

- **Q-016:** Reveal gesture, hide delay, keyboard pinning, popover pinning, exclusive-zone behaviour, top/bottom behaviour, accidental reveal prevention, and window-drag interaction.

Autohide is not part of Phase 2 and must remain modular until this is prototyped.

## 17.5 Workspace and focused-window actions

- **Q-017:** Whether primary click on the active workspace opens quickshell-overview.
- **Q-018:** Default focused-window-action entry point.
- **Q-084:** Overview invocation from the bar and accidental activation during rapid workspace switching.

The Phase 2 prototype may use active-workspace primary click to request overview, but the delegate must route through a configurable/controller action so the result can change without layout rewrites.

## 17.6 Tray

- **Q-073:** Tray drawer layout.
- **Q-074:** Stable ordering key.
- **Q-075:** Pinning UX.
- **Q-076:** Attention semantics and protection against noisy applications.

No tray item is pinned by default regardless of the eventual pinning UX.

## 17.7 Multi-monitor

- **Q-088:** Bar on every monitor, primary monitor, or configured monitors, including per-monitor edge.
- **Q-089:** Per-monitor versus global workspace-pager presentation.

The code must support per-monitor instances without claiming that the final user policy is decided.

## 17.8 Configurability

- **Q-105:** Whether users may reorder bar modules.

The initial settings surface must preserve the designed hierarchy and must not expose unrestricted reordering.

## 17.9 Cross-feature questions that block complete bar integration

These are not bar-layout decisions, but they affect whether a bar item can be completed against a real backend:

- **Q-001:** Exact pinned Quickshell baseline and required module availability.
- **Q-002:** Which retained Caelestia services are wrapped, copied, replaced, or removed.
- **Q-045:** Exact scope of the compact audio popover.
- **Q-046:** Reliable output-device icon classification and user overrides.
- **Q-048:** Default volume scroll step.
- **Q-057:** Resource and sensor backend implementation.
- **Q-063:** auto-cpufreq active-configuration resolution.
- **Q-077:** Supported Vicinae invocation API.
- **Q-082:** One-way shared workspace configuration mechanism for quickshell-overview.

Codex may use fixtures and adapter interfaces before these are resolved, but must not lock a backend-specific assumption into the bar view.

---

# 18. Codex Implementation Guardrails

Codex must not:

- replace the continuous rail with independent floating islands;
- add normal Wi-Fi, Ethernet, Bluetooth, weather, unread-count, application-icon, or active-window-title indicators to the resting bar;
- show all special workspaces permanently;
- show workspace occupancy;
- place Vicinae anywhere except the absolute end without a new decision;
- move end controls when contextual state changes;
- call backend commands directly from item delegates;
- create one unmanaged popup window per item;
- hard-code active-workspace overview behaviour so it cannot be changed after prototype testing;
- choose exact thickness, inset geometry, battery suffix, charging animation, contextual slot count, throughput convention, autohide timing, tray layout, or final multi-monitor policy as though settled;
- keep expensive popover polling active while the popover is closed;
- hide failure by displaying plausible but false normal state;
- let optional integration failure crash the bar;
- treat maximized windows as fullscreen;
- make essential actions hover-only, gesture-only, middle-click-only, or secondary-click-only;
- duplicate special-workspace or theme configuration.

When implementation pressure reveals a new product decision, add it to `open-questions.md` or `decisions.md` rather than encoding it invisibly in QML.
