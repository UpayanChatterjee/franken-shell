# Franken Shell — Decision Log

> **Status:** Living design record  
> **Purpose:** Record settled product, interaction, architecture, and scope decisions together with their rationale and consequences  
> **Related documents:** `product-vision.md`, `design-principles.md`, `feature-map.md`, `architecture.md`, `configuration-model.md`, `implementation-phases.md`

This document records decisions that should not be silently reconsidered during implementation.

Each entry includes:

- **Status**
- **Decision**
- **Rationale**
- **Consequences**
- **Revisit conditions**, where applicable

Statuses:

- **Accepted** — current project baseline;
- **Provisional** — direction accepted, implementation details may change;
- **Deferred** — intentionally postponed;
- **Superseded** — replaced by a later decision.

The log is not a substitute for detailed feature specifications. It records *why* the project is taking a particular direction.

---

# D-001 — Product Identity

**Status:** Accepted

## Decision

Franken Shell will be:

> **Minimal by default, comprehensive on command.**

The resting shell should remain quietly visible and expose only information that is frequently useful, immediately actionable, contextual, exceptional, or critical.

Detailed controls should remain hidden behind deliberate actions.

## Rationale

The user wants a shell that remains unobtrusive during ordinary work but avoids forcing frequent trips to a full settings application.

This balances:

- low visual noise;
- fast access;
- rich functionality;
- sustained daily usability.

## Consequences

- the bar must remain compact;
- normal connectivity should remain silent;
- detailed system management belongs in popovers or the control centre;
- every persistent element requires a strong justification;
- “feature completeness” must not turn the resting shell into a dashboard.

---

# D-002 — Primary Experience Qualities

**Status:** Accepted

## Decision

The shell should optimize for:

1. **Elegant**
2. **Fast**
3. **Precise**

## Rationale

These qualities reflect the intended product character better than “playful,” “dense,” or “decorative.”

## Consequences

- motion must be short and purposeful;
- layouts must remain stable;
- visual language must remain cohesive;
- unnecessary labels, indicators, and cards should be rejected;
- interaction latency is a product concern, not merely an engineering concern.

---

# D-003 — Visual Direction

**Status:** Accepted

## Decision

The shell will use:

- Caelestia’s wallpaper-derived dynamic colour scheme;
- Android Material You Expressive as the overarching visual influence;
- a restrained interpretation while idle;
- stronger shape, colour, and motion primarily during interaction.

## Rationale

This preserves the atmosphere and adaptability of Caelestia while giving the shell a coherent design system.

## Consequences

- the shell should define semantic colour roles;
- raw wallpaper colours should not be used directly across feature files;
- the control centre should remain readable and relatively opaque;
- Material You Expressive must not produce oversized mobile-style layouts;
- adopted components should receive theme integration where practical.

---

# D-004 — Interaction Priority

**Status:** Accepted

## Decision

Input priority is:

1. keyboard;
2. mouse;
3. trackpad gestures.

Every major workflow must have both keyboard and pointer support.

Gestures are an enhancement, not the only path.

## Rationale

The user frequently alternates between keyboard-heavy and mouse-heavy use and wants trackpad gestures to be treated seriously.

## Consequences

- all major surfaces need focus handling;
- pointer access cannot depend only on invisible gestures;
- right-click and scroll actions must have keyboard equivalents;
- gesture conflicts with Hyprland must be documented and configurable.

---

# D-005 — Spatial Model

**Status:** Accepted

## Decision

The shell uses a stable edge-oriented spatial grammar:

- configurable persistent bar edge, default left;
- right edge for control centre and notifications;
- edge-attached popovers for focused details;
- Vicinae as a deliberate central floating command surface;
- quickshell-overview as the visual overview layer.

## Rationale

Stable spatial placement reduces cognitive load and makes keyboard, pointer, and gesture interactions easier to remember.

## Consequences

- control centre remains right-attached even if the bar moves;
- bar popovers open inward from the configured bar edge;
- related functions should not have multiple equal primary homes;
- nested Wi-Fi and Bluetooth pages remain inside the control centre.

---

# D-006 — Persistent Bar Form

**Status:** Accepted

## Decision

The bar will be a **continuous rail**, not separate floating islands.

Default placement is the left edge.

It must be designed for all four edges rather than implemented as a rotated left bar.

## Rationale

A continuous rail better supports a minimal, structural, instrument-like appearance.

Edge configurability is a first-class requirement.

## Consequences

- components need orientation-aware layouts;
- text should not simply rotate;
- edge-aware corner treatment is required;
- bar structure should be expressed in logical start/end directions.

---

# D-007 — Bar Visibility

**Status:** Accepted

## Decision

The bar:

- remains visible with tiled windows;
- remains visible with maximized windows;
- hides in true fullscreen;
- supports optional autohide;
- does not reveal over fullscreen by pointer by default.

## Rationale

The user commonly uses one maximized application per workspace and still wants persistent shell status.

Fullscreen is treated as an interruption boundary.

## Consequences

- maximized and fullscreen state must be distinguished correctly;
- fullscreen suppression should also inform notifications and edge-drag behaviour;
- autohide is configurable rather than the default.

---

# D-008 — Bar Information Hierarchy

**Status:** Accepted

## Decision

The bar’s resting hierarchy is:

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

Vicinae is placed at the absolute end.

## Rationale

Navigation belongs at the start; system status and command access belong at the end.

## Consequences

- contextual status must not shift end-anchored controls;
- bar zones should be grouped by spacing rather than many separators;
- Vicinae is treated as a universal action entry point, not workspace navigation.

---

# D-009 — Numbered Workspace Model

**Status:** Accepted

## Decision

Numbered workspaces are stable semantic locations, not dynamically presented occupied slots.

The resting bar shows one group of five:

- `1–5`;
- `6–10`;
- and so on.

The visible group follows the active numbered workspace.

Occupancy is not shown.

## Rationale

The user remembers applications and tasks spatially, such as:

- workspace 1 for browser;
- workspace 2 for files and terminal;
- workspace 3 for PDF reader;
- workspace 4 for Obsidian.

Occupancy indicators would add little value and visual weight.

## Consequences

- no application icons in the pager;
- no occupied/empty markers;
- workspace numbers remain visible;
- the group size defaults to five;
- switching to workspace 7 changes the visible set to `6–10`.

---

# D-010 — Special Workspace Model

**Status:** Accepted

## Decision

All special workspaces share one persistent bar slot.

The slot:

- shows a neutral stack icon when none is open;
- changes to the active special-workspace icon when one is visible;
- opens a compact selector on primary click.

Initial special workspaces:

- Music;
- Movies/Anime;
- Books;
- Discord;
- Scratchpad;
- Todo.

## Rationale

Showing all six icons permanently would conflict with the minimal bar.

A single adaptive slot preserves semantic visibility without permanent clutter.

## Consequences

- special workspace definitions must be configuration-driven;
- the active numbered workspace remains highlighted underneath;
- keyboard shortcuts remain the fastest path;
- the selector is pointer- and keyboard-accessible.

---

# D-011 — Active Window Title

**Status:** Accepted

## Decision

The active window title will not occupy permanent bar space.

Focused-window metadata and actions will be summonable through a dedicated menu or overview-related interaction.

## Rationale

The user values Caelestia’s focused-window actions but considers the permanent title too space-consuming.

## Consequences

- bar remains compact;
- active workspace number secondary action may open focused-window controls;
- quickshell-overview handles broader visual window navigation;
- focused-window actions remain a separate compact workflow.

---

# D-012 — Workspace Overview Adoption

**Status:** Accepted

## Decision

Use `quickshell-overview` instead of building a new overview.

Initially run it as a separate Quickshell configuration or process.

## Rationale

The user already uses it successfully and considers it good.

It already provides:

- visual previews;
- keyboard and pointer navigation;
- drag-and-drop;
- special-workspace support;
- IPC.

## Consequences

- pin a known-working revision;
- integrate theme and workspace configuration;
- keep direct workspace switching as fallback;
- test screencopy and multi-monitor behaviour;
- consider vendoring only if later integration or maintenance requires it.

---

# D-013 — Application Launcher and Command Interface

**Status:** Accepted

## Decision

Vicinae completely replaces a shell-native launcher and command interface.

Franken Shell will not build a competing launcher.

## Rationale

The user already prefers Vicinae and has written an extension for controlling Caelestia.

Rebuilding a launcher in Quickshell would duplicate a strong existing solution.

## Consequences

- Vicinae becomes a first-class integration;
- the shell includes a visible Vicinae bar entry point;
- a shell-specific Vicinae extension is planned;
- theme and command integration are required;
- the shell must degrade gracefully if Vicinae is absent.

---

# D-014 — Vicinae Coupling Boundary

**Status:** Accepted

## Decision

Vicinae is integral to the product experience but loosely coupled architecturally.

## Rationale

The shell should benefit from Vicinae without depending on undocumented internals or allowing Vicinae failure to stop the shell.

## Consequences

- use a small adapter;
- use supported commands/deeplinks where available;
- expose shell control through versioned IPC;
- do not fork Vicinae merely for exact geometry matching;
- report availability and failures clearly.

---

# D-015 — System Tray Strategy

**Status:** Accepted

## Decision

The system tray is collapsed by default into one affordance.

No tray apps are pinned by default.

A tray drawer contains all items.

## Rationale

The user runs many tray-heavy applications, and showing them all would consume excessive bar space.

## Consequences

- tray affordance hides when empty;
- users may later pin selected items;
- attention states may alter the tray affordance;
- application-provided click, right-click, scroll, and menu semantics must be preserved.

---

# D-016 — Network Status Strategy

**Status:** Accepted

## Decision

Normal connectivity is silent.

Exceptional connectivity appears contextually.

Persistent throughput is represented separately.

## Rationale

The bar should not show a Wi-Fi icon merely to say that normal connectivity exists.

## Consequences

- no Wi-Fi icon while internet works;
- no Ethernet icon while internet works;
- contextual indicator distinguishes no network, no internet, limited connectivity, or captive portal;
- throughput remains always visible.

---

# D-017 — Persistent Network Speed

**Status:** Accepted

## Decision

The bar always shows current download speed.

Format examples:

- `3K`;
- `20M`;
- `1G`.

Rules:

- whole numbers;
- one-letter unit;
- no `/s`;
- no arrow in resting state.

Tooltip shows both:

- `↓ download`;
- `↑ upload`.

## Rationale

The user explicitly wants at least current download speed always visible.

## Consequences

- fixed-size cell and tabular numerals are required;
- values should be smoothed;
- upload remains tooltip-only;
- bytes versus bits remains configurable, with bytes currently preferred.

---

# D-018 — Audio Representation

**Status:** Accepted

## Decision

Use one persistent audio slot.

Its icon changes according to active output:

- speakers;
- wired headphones;
- Bluetooth headphones/headset;
- mute.

Do not add a separate permanent headphone icon.

## Rationale

Multiple icons for sound, headphones, and Bluetooth would duplicate one underlying state.

## Consequences

- output-device metadata must be normalized;
- audio item supports click, scroll, and middle-click;
- non-audio Bluetooth devices may still appear contextually.

---

# D-019 — Resource Indicator

**Status:** Accepted

## Decision

The persistent resource indicator represents RAM usage as:

- circular progress arc;
- centered whole-number percentage;
- no `RAM` label.

## Rationale

The user already uses this compact representation and prefers values without redundant text.

## Consequences

- resource popover opens on click;
- the full system monitor opens when the popover body is clicked;
- other metrics remain inside the popover;
- not every metric should use the same circular visual.

---

# D-020 — Resource Popover Content

**Status:** Accepted

## Decision

The compact resource popover should show, where available:

- CPU usage and temperature;
- GPU usage and temperature;
- CPU/GPU fan speeds;
- CPU/GPU clocks where useful;
- memory and swap;
- storage;
- uptime;
- power profile;
- high-usage process.

## Rationale

The bar remains minimal while still providing immediate access to practical system details.

## Consequences

- unsupported metrics are omitted;
- sensor discovery must be capability-driven;
- multiple GPUs are supported conceptually;
- detailed monitoring updates faster only while the popover is open.

---

# D-021 — Battery Representation

**Status:** Accepted

## Decision

The bar shows battery percentage as plain text.

Charging is communicated through accent and restrained animation rather than a permanent battery icon.

## Rationale

This is more compact and aligns with the rule to avoid labels and redundant glyphs.

## Consequences

- use tabular numerals;
- warning and critical states require semantic treatment;
- exact `%` display remains subject to visual prototype testing;
- charging animation must not flash.

---

# D-022 — Battery Action and auto-cpufreq

**Status:** Accepted

## Decision

Clicking the battery item opens a power-management surface centered on auto-cpufreq configuration.

## Rationale

The user manages battery and CPU policy through auto-cpufreq rather than a generic desktop power-profile UI.

## Consequences

- battery and charger profiles should be editable;
- automatic control and temporary overrides must be clearly distinguished;
- protected writes require a narrow privileged helper;
- missing auto-cpufreq must not remove basic battery status.

---

# D-023 — Date and Time

**Status:** Accepted

## Decision

Date and time are one combined bar control using 24-hour time.

Clicking opens the calendar.

## Rationale

They belong to one temporal workflow and should not consume two independent bar slots.

## Consequences

- vertical layout may use stacked time/date;
- date must remain unambiguous;
- full calendar lives in the dedicated calendar surface, not duplicated in control centre.

---

# D-024 — Calendar Scope

**Status:** Accepted

## Decision

The first calendar version contains only a local month calendar.

Google Calendar integration follows immediately after the working prototype.

## Rationale

This keeps the prototype bounded while acknowledging that agenda integration is a near-term requirement.

## Consequences

- initial calendar has month navigation and selected day;
- do not show a large empty agenda region;
- internal data model should anticipate providers, events, and sync state.

---

# D-025 — Control Centre Role

**Status:** Accepted

## Decision

The control centre is the right-edge utility drawer for:

- notifications;
- quick system controls;
- volume and brightness;
- device management;
- occasional settings actions.

## Rationale

These controls are too useful to bury in a full settings app but too infrequent for the resting bar.

## Consequences

- it defaults to Notifications;
- it contains nested detail pages;
- it should remain dense, readable, and edge-attached;
- full calendar and todo views should not be duplicated there.

---

# D-026 — Control Centre Opening

**Status:** Accepted

## Decision

The control centre opens through:

- keyboard shortcut;
- click-and-drag left from the extreme right edge.

The activation strip is invisible.

No hover opening.

## Rationale

The user explicitly wants a draggable edge drawer inspired by Illogical Impulse.

## Consequences

- implement intent detection;
- require distance and/or velocity threshold;
- suppress accidental activation;
- disable pointer edge reveal in fullscreen by default;
- the drawer follows the pointer during drag.

---

# D-027 — Control Centre Default View

**Status:** Accepted

## Decision

The drawer defaults to the Notifications tab.

## Rationale

Notifications are its primary accumulated-attention function.

## Consequences

- quick controls and sliders remain above tabs;
- reopening may briefly restore recent focus, but long-closed state returns to Notifications;
- nested pages return to the main Notifications view.

---

# D-028 — Control Centre Quick Controls

**Status:** Accepted

## Decision

Initial quick controls are:

- Wi-Fi;
- Bluetooth;
- Do Not Disturb;
- Night Light;
- idle inhibitor.

## Rationale

These are useful enough for regular access but do not belong permanently in the bar.

## Consequences

- Wi-Fi and Bluetooth have both toggle and detail actions;
- user-triggered changes produce system toasts;
- active idle inhibitor may surface in the bar context region.

---

# D-029 — Persistent Control Centre Sliders

**Status:** Accepted

## Decision

Master volume and brightness sliders remain visible above the main control-centre tabs.

## Rationale

They are frequent enough to deserve immediate access regardless of the active drawer tab.

## Consequences

- slider changes do not close the drawer;
- both support pointer, scroll, and keyboard input;
- changes produce OSD feedback.

---

# D-030 — Wi-Fi and Bluetooth Detail Surfaces

**Status:** Accepted

## Decision

Wi-Fi and Bluetooth management use comprehensive nested pages inside the control centre, not tiny detached popups.

## Rationale

Scanning, connection, password entry, pairing, and device lists require more space and clearer state than small popovers provide.

## Consequences

- detail pages replace main drawer content;
- `Escape` returns to parent before closing;
- common daily-use management stays in shell;
- advanced administration may delegate to specialist settings apps.

---

# D-031 — Control Centre Visual Opacity

**Status:** Accepted

## Decision

The control centre uses a more opaque Material surface rather than the highly translucent appearance of the Illogical Impulse reference.

## Rationale

Readability and long-term usability are more important than reproducing the reference literally.

## Consequences

- blur is optional and subtle;
- wallpaper-derived colours still influence surface roles;
- utility density and legibility take priority.

---

# D-032 — Notification Popup Eligibility

**Status:** Accepted

## Decision

All applications may show notification popups by default.

## Rationale

The user explicitly wants popups for all applications.

## Consequences

- burst coalescing is required;
- DND and fullscreen policy must prevent overload;
- per-app suppression may be added later;
- “all apps allowed” does not mean unlimited simultaneous popup cards.

---

# D-033 — Notification Grouping

**Status:** Accepted

## Decision

Notifications are grouped automatically by application.

## Rationale

Messaging and collaboration apps can produce bursts that would otherwise overwhelm the screen and history.

## Consequences

- grouped popup may update in place;
- drawer supports expand/collapse;
- local group counts are allowed;
- global unread counts remain forbidden.

---

# D-034 — No Global Unread Count

**Status:** Accepted

## Decision

There will be no unread notification count or badge anywhere in the shell.

## Rationale

The user prefers opening the drawer to inspect notifications and does not want persistent attention pressure.

## Consequences

- no notification badge in bar;
- no tray-like global count;
- notification groups may still show local item counts within the drawer.

---

# D-035 — Notification Sound Policy

**Status:** Accepted

## Decision

Ordinary notifications are silent by default.

Optional sound may be configured later:

- per application;
- per notification title or title rule.

Calls, alarms, timers, and critical alerts may use sound by default.

## Rationale

The shell should remain quiet while still supporting selective audible attention.

## Consequences

- sound rules require a deterministic matcher;
- arbitrary notification-sound commands are not allowed;
- DND suppresses ordinary sounds;
- visual popup eligibility is independent of sound eligibility.

---

# D-036 — Feedback Channels

**Status:** Accepted

## Decision

Use three distinct channels:

1. application notifications;
2. system configuration toasts;
3. direct-manipulation OSDs.

## Rationale

These events have different persistence, ownership, and interruption semantics.

## Consequences

- configuration toasts do not normally enter notification history;
- OSDs never enter notification history;
- application notifications retain app identity and actions;
- styling must visually distinguish the channels.

---

# D-037 — OSD Scope

**Status:** Accepted

## Decision

Volume and brightness changes use transient OSDs.

Track changes produce no notification and no OSD.

## Rationale

Volume and brightness are continuous direct manipulation.

Track-change feedback would be noisy and redundant.

## Consequences

- one OSD instance updates in place;
- OSDs remain visible during DND;
- user-triggered OSDs may appear over fullscreen.

---

# D-038 — System Toast Scope

**Status:** Accepted

## Decision

All system configuration changes should produce brief confirmation toasts.

Examples:

- Wi-Fi enabled;
- connected to network;
- Bluetooth disabled;
- Night Light enabled;
- audio output changed;
- power configuration applied.

## Rationale

Immediate feedback makes system state changes feel precise and trustworthy.

## Consequences

- repeated category toasts replace each other;
- successful toasts do not enter history;
- failures remain longer and may offer Retry or Open Details.

---

# D-039 — Do Not Disturb Philosophy

**Status:** Accepted

## Decision

Do Not Disturb suppresses interruption, not feedback.

It suppresses:

- ordinary application popups;
- ordinary notification sounds.

It does not suppress:

- OSDs;
- user-triggered configuration toasts;
- failures from user-requested actions;
- conservative critical alerts.

## Rationale

The user should still receive confirmation for actions they intentionally performed.

## Consequences

- notification policy must distinguish source and urgency;
- DND does not mean total silence from the shell;
- critical bypass rules must remain conservative and configurable.

---

# D-040 — Critical Bypass Categories

**Status:** Accepted

## Decision

Default DND/fullscreen bypass includes:

- critically low battery or imminent shutdown;
- severe CPU/GPU temperature;
- serious storage or filesystem failure;
- incoming calls;
- alarms and timers;
- authentication prompts;
- pairing codes and confirmations;
- security/permission prompts requiring immediate action;
- failures from explicit user actions;
- screen recording unexpectedly stopping.

Routine calendar reminders and download completions do not bypass by default.

## Rationale

These categories either protect the system/user, require immediate input, or confirm failure of an action currently in progress.

## Consequences

- app urgency hints cannot be trusted blindly;
- critical classification belongs to shell policy;
- thresholds must eventually be configurable.

---

# D-041 — Fullscreen Notification Policy

**Status:** Accepted

## Decision

Ordinary application popups are withheld during true fullscreen.

They enter history but do not replay as a burst afterward.

Critical alerts and user-triggered OSDs/toasts remain allowed.

## Rationale

Fullscreen is used for games, video, and focused activity.

## Consequences

- fullscreen state must be centralized;
- notification history remains complete;
- a later subtle summary toast may be considered, but no count is required.

---

# D-042 — Architecture: One Main Shell Instance

**Status:** Accepted

## Decision

Franken Shell should normally run as one main Quickshell instance owning:

- bars;
- control centres;
- popovers;
- notifications;
- toasts;
- OSDs;
- shared services;
- settings;
- shell IPC.

## Rationale

A single instance simplifies state ownership, surface coordination, and service subscriptions.

## Consequences

- major feature modules must not create independent global state;
- adopted components may remain separate processes;
- reload must avoid duplicate D-Bus ownership.

---

# D-043 — Service Adapter Boundary

**Status:** Accepted

## Decision

QML feature views must not directly issue backend-specific commands.

System interaction belongs behind normalized adapters.

## Rationale

This improves maintainability, testing, error handling, and resilience to Quickshell or backend changes.

## Consequences

- no `hyprctl` calls in workspace delegates;
- no direct `nmcli` calls in network rows;
- no direct privileged writes from battery panel;
- external commands go through a command registry.

---

# D-044 — One Surface Coordinator

**Status:** Accepted

## Decision

A central `SurfaceCoordinator` owns transient surface visibility, monitor ownership, dismissal, and focus restoration.

## Rationale

Independent surface logic would lead to overlap, focus leaks, and inconsistent closing behaviour.

## Consequences

- opening the control centre closes bar popovers;
- only one bar popover is open at a time;
- overview and Vicinae may close ordinary shell surfaces;
- feature modules request openings rather than managing global windows themselves.

---

# D-045 — Configuration as Single Source of Truth

**Status:** Accepted

## Decision

Franken Shell uses one authoritative user configuration.

Generated Vicinae and quickshell-overview files derive from it.

## Rationale

The same workspaces, commands, and theme values must not be maintained in multiple places.

## Consequences

- workspace definitions are shared;
- special workspace IDs are stable;
- generated files are marked as generated;
- settings UI edits the same schema;
- invalid reloads preserve the active in-memory typed snapshot.

---

# D-046 — Configuration Safety

**Status:** Accepted

## Decision

Configuration changes are parsed, validated, normalized, and applied atomically.

Invalid configuration never partially replaces valid runtime state.

## Rationale

A shell config error should not destroy a running desktop session.

## Consequences

- maintain built-in defaults;
- retain the active valid snapshot across invalid hot reloads;
- provide structured errors;
- support sequential in-memory schema migrations;
- defer source-file writes, backups, and explicit migration writes until separately approved.

---

# D-047 — Privileged Operations

**Status:** Accepted

## Decision

The main shell remains unprivileged.

auto-cpufreq edits use a narrow privileged helper and system authorization.

## Rationale

QML must not become an arbitrary root command execution environment.

## Consequences

- helper exposes explicit operations only;
- writes are atomic;
- paths are fixed or validated;
- no arbitrary command or file write API;
- helper requires separate testing and policy.

---

# D-048 — Notification History Persistence

**Status:** Deferred

## Decision

The first notification history is in memory only.

Persistent notification history is postponed until privacy, retention, and storage decisions are made.

## Rationale

Notification bodies may contain sensitive personal information.

## Consequences

- restart clears history initially;
- notification bodies are not logged;
- persistence requires a later explicit design decision.

---

# D-049 — Multi-Monitor Policy

**Status:** Provisional

## Decision

The implementation should support per-monitor surfaces from the beginning, but the final product policy remains open.

Provisional policy:

- pointer-invoked surfaces use pointer monitor;
- keyboard-invoked surfaces use focused-window monitor;
- one control centre globally;
- notifications on focused monitor;
- OSD on active monitor.

## Rationale

The architecture must not assume one monitor, but detailed ownership should be validated through actual use.

## Consequences

- monitor registry is required early;
- all surface openings carry monitor origin;
- final policy belongs in a dedicated specification.

## Revisit conditions

Revisit during multi-monitor hardening after testing:

- mixed DPI;
- rotated displays;
- monitor hotplug;
- bar on multiple monitors;
- overview limitations.

---

# D-050 — Trackpad Gestures

**Status:** Provisional

## Decision

Trackpad gestures are planned after the core keyboard and pointer workflows work.

Potential model:

- three-finger horizontal for workspaces;
- four-finger left for control centre;
- four-finger up for overview.

## Rationale

Gestures could improve the trackpad experience, but platform capability and conflict behaviour need validation.

## Consequences

- gesture support is not a prototype blocker;
- every gesture has a non-gesture alternative;
- conflict detection with Hyprland is required.

---

# D-051 — Control Centre Window Primitive

**Status:** Deferred

## Decision

The exact Quickshell window primitive for the control centre will be selected through prototype testing.

## Rationale

Focus, layer-shell behaviour, edge drag, outside click, and exclusive-zone interaction may differ between available primitives.

## Consequences

- architecture specifies required behaviour, not a premature type;
- Phase 3 must validate the chosen primitive;
- changing the primitive should not affect feature page implementations.

---

# D-052 — Bar Thickness

**Status:** Provisional

## Decision

Prototype around approximately `44–48` logical pixels.

## Rationale

The bar must fit stacked time, compact metrics, and usable pointer targets without becoming bulky.

## Consequences

- exact value is determined through real prototypes;
- theme metrics must centralize thickness;
- text scaling and all edge orientations must be tested.

---

# D-053 — Control Centre Width

**Status:** Provisional

## Decision

Prototype around approximately `380–420` logical pixels.

## Rationale

The drawer needs enough width for notifications, networks, Bluetooth devices, and mixer rows without becoming a full-screen panel.

## Consequences

- width is centralized in theme/config;
- mixed scaling must be tested;
- exact value remains open to visual validation.

---

# D-054 — Control Centre Calendar Duplication

**Status:** Accepted

## Decision

Do not include a full calendar in the control centre.

## Rationale

The date/time bar item already owns the dedicated calendar surface.

## Consequences

- no duplicate month grid;
- a future compact “upcoming events” summary may link to the calendar panel;
- todo remains in its dedicated special workspace.

---

# D-055 — Weather

**Status:** Accepted

## Decision

Do not show weather in the bar.

No weather feature is required for the initial shell.

## Rationale

The user explicitly does not want weather in the bar, and it does not support the essential-status goal.

## Consequences

- weather is absent from current feature map;
- it should not be added as filler to calendar or control centre.

---

# D-056 — External Full System Monitor

**Status:** Accepted

## Decision

The shell will launch a configurable external system monitor instead of building a complete process manager.

## Rationale

The shell only needs a compact summary; full process-management scope is unnecessary duplication.

## Consequences

- resource popover remains focused;
- system-monitor command is configurable;
- launch failure produces an actionable error.

---

# D-057 — Build Order

**Status:** Accepted

## Decision

Implementation proceeds in this order:

1. project bootstrap;
2. core shell skeleton;
3. bar foundation;
4. control-centre mechanics;
5. system adapters;
6. notifications and feedback;
7. working daily-use prototype;
8. adopted integrations;
9. deeper utilities;
10. settings;
11. multi-monitor and gestures;
12. visual/accessibility polish;
13. packaging.

## Rationale

This validates the riskiest architecture and interaction assumptions before deep feature or visual work.

## Consequences

- edge drag and focus must work before Wi-Fi/Bluetooth UI is fully built;
- mock data is used early;
- visual polish cannot conceal structural problems;
- Codex tasks should remain narrow vertical slices.

---

# D-058 — External Integration Failure Policy

**Status:** Accepted

## Decision

Optional integration failures degrade locally and do not terminate the shell.

## Rationale

The shell must remain usable if Vicinae, overview, auto-cpufreq, sensors, or a specialist app is missing.

## Consequences

- every integration reports availability;
- user-facing failure states are required;
- fallbacks preserve core functionality;
- diagnostics expose missing dependencies.

---

# D-059 — Dynamic Theme Failure Policy

**Status:** Accepted

## Decision

The shell always has a valid fallback palette.

A new dynamic theme activates atomically only after validation.

## Rationale

Wallpaper or colour-generation failure must not leave unreadable or partially themed UI.

## Consequences

- retain last valid theme;
- do not flash unstyled content;
- external integration theme files are generated atomically;
- contrast validation is required.

---

# D-060 — App Icons in Resting Bar

**Status:** Accepted

## Decision

Application icons are excluded from the resting bar.

## Rationale

They add clutter without supporting the user’s workspace memory model.

## Consequences

- no active application icon;
- no per-workspace application icon;
- app icons remain appropriate in notifications, tray, mixer, Vicinae, and overview.

---

# D-061 — Persistent Labels in Bar

**Status:** Accepted

## Decision

Avoid persistent labels where category is already communicated by position, icon, shape, and value.

Examples rejected:

- `RAM 42%`;
- `BAT 87`;
- `WIFI`;
- `BT`.

## Rationale

The user prefers compact representations and wants letters/numbers minimized where unnecessary.

## Consequences

- tooltips and accessible names provide explicit descriptions;
- numeric information remains where useful;
- text remains for time, date, workspace numbers, battery, throughput, and exact values.

---

# D-062 — Normal Bluetooth Visibility

**Status:** Accepted

## Decision

Bluetooth is hidden when no relevant device is connected.

A connected audio device is represented by the audio slot.

A separate Bluetooth contextual indicator appears only when it conveys additional information.

## Rationale

This prevents duplicated state and preserves bar space.

## Consequences

- non-audio devices may surface contextually;
- multiple connected devices may use a stacked state;
- Bluetooth management remains in control centre.

---

# D-063 — Tray Pinning Default

**Status:** Accepted

## Decision

No tray application is pinned by default.

## Rationale

The project should begin from the minimal state and let users promote exceptions intentionally.

## Consequences

- pinning is an optional future capability;
- all tray apps remain accessible through drawer;
- project defaults do not privilege a specific app.

---

# D-064 — User-Triggered Feedback in DND

**Status:** Accepted

## Decision

User-triggered toasts and OSDs remain visible during Do Not Disturb.

## Rationale

A user action still requires confirmation even when unsolicited interruption is suppressed.

## Consequences

- DND policy depends on origin, not only severity;
- action failures may bypass DND;
- ordinary application popups remain suppressed.

---

# D-065 — Notification Popup While Drawer Is Open

**Status:** Accepted

## Decision

When the control centre is already open to notifications, new notifications enter the list without also showing a floating popup.

## Rationale

Showing both would duplicate the same information.

## Consequences

- popup host consults drawer visibility;
- list updates must preserve scroll position;
- new-notification affordance may appear when scrolled away from top.

---

# D-066 — Power/Session Action

**Status:** Accepted

## Decision

The control-centre power icon opens a dedicated session surface rather than immediately shutting down.

## Rationale

Small header controls should not trigger destructive actions directly.

## Consequences

- session menu contains lock, suspend, logout, reboot, and shutdown as supported;
- destructive actions receive explicit confirmation;
- lock/suspend may remain immediate where safe.

---

# D-067 — Lock Screen

**Status:** Deferred

## Decision

Lock-screen redesign is postponed until the shell’s main surfaces are stable.

## Rationale

Security and authentication reliability are more important than early visual integration.

## Consequences

- current lock solution may remain initially;
- lock screen receives a dedicated later specification;
- no implementation assumptions should couple session menu to a custom lock screen yet.

---

# D-068 — Shell Settings Surface

**Status:** Accepted, Near-term

## Decision

A dedicated shell settings surface will be built after the working prototype.

## Rationale

The shell has meaningful configuration needs, but settings UI should not block proving the product.

## Consequences

- manual structured config is acceptable during early development;
- settings UI edits the same schema;
- high-value behavioural settings are prioritized;
- visual micromanagement is not exposed initially.

---

# D-069 — External Command Safety

**Status:** Accepted

## Decision

External commands are represented as executable-plus-argument arrays and launched through one registry.

## Rationale

String-concatenated shell commands create quoting, security, and debugging problems.

## Consequences

- no arbitrary command interpolation;
- command availability and exit status are observable;
- IPC does not expose unrestricted execution.

---

# D-070 — Project Documentation Workflow

**Status:** Accepted

## Decision

Project documentation is written one file at a time and reviewed incrementally before implementation.

## Rationale

This keeps decisions manageable and prevents a large generated specification from hiding contradictions.

## Consequences

- each file becomes a review checkpoint;
- feature specs follow foundation docs;
- implementation begins only after the minimum coherent documentation set exists.

---

# D-071 — Phase 0 Development Baseline

**Status:** Accepted

## Decision

The exact pinned and tested Phase 0 development baseline is:

- Quickshell `0.3.0`;
- Quickshell commit `4df562dfb2475a9057f0f33a8db75808efad8670`;
- Arch package `quickshell-git 0.3.0.r15.g4df562d-1`;
- Qt `6.11.1`;
- Hyprland `0.55.4` using Lua configuration.

This pin is a development baseline, not a minimum supported version.

## Rationale

These versions are installed together and were inspected during the Phase 0 readiness audit. Pinning the complete tested set avoids treating a generic pre-1.0 Quickshell release family as interchangeable.

## Consequences

- Phase 0 records and checks the exact versions above;
- version-sensitive behaviour is evaluated against this baseline;
- the eventual minimum supported version and compatibility range remain unresolved until compatibility testing exists;
- compatibility claims must not be inferred from the development pin.

---

# D-072 — Provisional Caelestia Migration Inventory

**Status:** Accepted

## Decision

The audited Caelestia component matrix in `runtime-dependencies.md` is the provisional migration inventory.

The Phase 0 bootstrap imports no legacy Caelestia presentation modules. Selected installed Caelestia CLI and native modules may remain available during transition, but retained capabilities must be consumed behind Franken Shell adapters.

`Copy and maintain` means eligible for selective extraction after dependency, licence, ownership, and consumer review. It does not authorize immediate or bulk copying.

During parallel development, the running Caelestia shell continues to own notifications, tray watching, lock/session behaviour, and other exclusive session responsibilities.

## Rationale

The current shell mixes presentation, QML services, native modules, external commands, configuration, and exclusive session ownership. A provisional matrix preserves the audit evidence without turning every transitional dependency into a permanent commitment.

## Consequences

- classifications may change through later approved research or implementation evidence;
- broad legacy presentation imports are prohibited in Phase 0;
- retained capabilities cross a Franken Shell adapter boundary;
- unresolved lock, agent, notification, tray, and native-module questions remain tracked in `open-questions.md`.

---

# D-073 — Clean Main-Branch Bootstrap

**Status:** Accepted

## Decision

Franken Shell will begin with a clean Phase 0 bootstrap on the main branch.

The customized Caelestia implementation is preserved through Git history, the `design-baseline-v1` tag, and the `legacy/caelestia-custom` branch. Main will not contain a physical legacy source directory.

The live configuration at `~/.config/quickshell/caelestia` remains untouched and separately runnable throughout early development. Replacing the repository `shell/` implementation is deferred to a later implementation task.

## Rationale

Git already preserves the exact customized tree without duplicating a large legacy directory or making legacy structure part of the new architecture.

## Consequences

- legacy components are inspected or extracted from Git history or the legacy branch;
- extraction remains selective and review-driven;
- the working user shell is not the Phase 0 development target and is not modified by bootstrap work;
- migration and visual redesign are not combined.

---

# D-074 — Development and Production Startup Topology

**Status:** Accepted

## Decision

During development:

- the current Caelestia shell continues to start normally;
- Franken Shell is launched manually from its repository path in a non-owning development mode;
- the development instance must not claim notification, tray-watcher, Polkit-agent, lock, or equivalent exclusive ownership.

For production:

- one systemd user service is the primary supervisor;
- Hyprland may start that service or its target, but must not separately launch Quickshell;
- duplicate-instance protection remains an additional guard;
- the service uses `Restart=on-failure` with a bounded delay;
- service lifecycle logs go to the journal while Quickshell structured logs and crash reports remain available.

Full process restart and in-process reload are distinct documented operations.

## Rationale

Parallel non-owning development protects the working desktop and avoids duplicate session-service ownership. A single production supervisor provides clear process ownership, crash recovery, ordering, and logs.

## Consequences

- Phase 0 must prove parallel-safe non-owning operation;
- development commands must identify the repository path and ownership mode explicitly;
- production startup has one authority even when triggered from Hyprland;
- notification fallback, Mako activation, and persistent SNI-host recovery remain unresolved but do not block the non-owning bootstrap.

---

# D-075 — Authoritative TOML Configuration

**Status:** Accepted

## Decision

Franken Shell's authoritative user configuration is declarative, non-executable
TOML at:

```text
$XDG_CONFIG_HOME/franken-shell/config.toml
```

The source file remains authoritative. Generated caches, normalized
representations, and integration files are derived data and never parallel
sources of truth. QML feature code never parses TOML directly.

Shell operations must not destroy comments or unknown fields. Phase 1 therefore
does not write or patch `config.toml`; unsupported unknown fields may be ignored
by runtime normalization while their source remains untouched.

## Rationale

TOML provides a human-readable, comment-capable, non-executable user format
while allowing parsing and validation to remain outside feature QML.

## Consequences

- Q-004 is resolved;
- actual user-file examples use TOML;
- runtime consumers receive normalized typed configuration snapshots;
- comment-preserving and unknown-field-preserving source edits remain future work;
- generated data must identify itself as derived and reproducible.

---

# D-076 — Versioned Rust Configuration Validation Boundary

**Status:** Accepted

## Decision

Configuration uses a staged architecture:

1. a small versioned Rust helper is the authoritative parser and validator;
2. it parses TOML, performs structural and semantic validation, detects schema
   versions, applies sequential migrations in memory, and emits normalized JSON
   plus structured diagnostics;
3. QML `ConfigService` owns file watching, debounce, asynchronous helper
   invocation, request generations, stale-response rejection, typed immutable
   snapshot construction, atomic snapshot publication, and configuration health;
4. feature controllers and views consume only the active typed snapshot;
5. a future settings UI uses the same validation and migration logic.

The helper protocol is explicitly versioned. Diagnostics support, where
applicable, severity, code, message, configuration path, source file, line,
column, and repair hint.

Built-in defaults activate immediately. A missing user file is a normal
defaults-only state. Invalid hot reloads leave the active snapshot unchanged.
Invalid cold startup uses built-in defaults and marks configuration health
degraded; later successful validation clears that state. Phase 1 has no
persistent last-valid disk cache.

Phase 1 helper scope is limited to parsing, structural validation, semantic
validation, normalized JSON output, structured diagnostics, schema-version
detection, sequential in-memory migrations, and fixture/unit tests. It excludes
source writes or patching, settings UI, comment-preserving edits, CST patching,
automatic migration rewrites, JSON Schema generation, and a persistent
last-valid cache.

## Rationale

This keeps parsing and deterministic validation in a testable native boundary
while keeping QML responsible for lifecycle, publication, and health without
letting feature code consume unvalidated raw data.

## Consequences

- Q-005 is resolved;
- each validation request and response carries a generation identifier;
- stale responses are discarded;
- unknown fields may produce structured warnings and are never destructively rewritten;
- newer schema versions are never destructively rewritten or silently downgraded;
- future source-preserving patch operations can be added without changing the runtime snapshot model;
- JSON Schema remains optional future tooling, not the runtime authority.

---

# Current Accepted Baseline Summary

The implementation should currently assume:

- left continuous bar by default;
- right-edge draggable control centre;
- keyboard first, pointer complete;
- wallpaper-derived Material You Expressive visual system;
- numbered workspaces in fixed groups of five;
- one adaptive special-workspace slot;
- no active app icon or permanent window title;
- collapsed tray;
- persistent download speed;
- adaptive audio icon;
- RAM ring;
- numeric battery;
- combined date/time;
- Vicinae at absolute end;
- Vicinae as launcher and command layer;
- quickshell-overview as visual overview;
- notification popups for all apps;
- silent notifications by default;
- app grouping;
- no unread count;
- system toasts for configuration changes;
- volume/brightness OSDs;
- no track-change feedback;
- DND that suppresses interruption but not user feedback;
- fullscreen suppression for ordinary popups and bar;
- one main Quickshell shell instance;
- adapters for system interaction;
- authoritative TOML configuration with a versioned Rust validation helper;
- atomic typed configuration snapshots owned by `ConfigService`;
- local failure containment;
- exact Phase 0 development pin from D-071;
- clean main-branch bootstrap with the working Caelestia shell preserved separately;
- parallel-safe non-owning development operation;
- one systemd user service as the production supervisor;
- phased implementation with edge-drag validation early.

---

# Decisions Still Expected

The following should receive future entries when resolved:

- final multi-monitor policy;
- final gesture mappings;
- exact Quickshell window primitive for control centre;
- final icon family;
- final font family;
- final bar thickness;
- final control-centre width;
- final `%` display on battery;
- final throughput bytes/bits default;
- exact notification sound matching syntax;
- exact auto-cpufreq helper implementation;
- Google Calendar authentication and token storage;
- notification persistence policy;
- final lock-screen ownership;
- final tray pinning UX;
- final OSD placement;
- final quickshell-overview vendoring decision;
- final post-migration Caelestia dependency inventory;
- supported Quickshell minimum and compatibility range;
- exclusive notification/tray fallback and recovery behaviour;
- exact default Hyprland bindings.
