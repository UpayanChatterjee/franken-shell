# Franken Shell — Feature Map

> **Status:** Working design baseline  
> **Purpose:** Define the shell's major features, ownership boundaries, dependencies, and implementation status  
> **Related documents:** `product-vision.md`, `design-principles.md`

This document is the top-level inventory of Franken Shell.

It answers four questions for every major feature:

1. What user problem does it solve?
2. Which part of the system owns it?
3. Which external services or adopted components does it depend on?
4. Is it part of the first prototype, a near-term follow-up, or a later phase?

The feature map is intentionally broader than the first implementation phase. Feature-specific behaviour belongs in `docs/features/`.

---

## Status Labels

| Label | Meaning |
|---|---|
| **Defined** | Product and interaction direction is substantially decided. |
| **Partially defined** | Core direction is known, but some behaviour remains open. |
| **Adopted** | Existing software will be integrated rather than rebuilt. |
| **Prototype** | Required for the first usable shell prototype. |
| **Near-term** | Planned immediately after the prototype. |
| **Later** | Useful, but not required to validate the core shell. |
| **Open** | Important design decisions remain unresolved. |

---

# 1. Shell Composition

## 1.1 Persistent edge bar

**Status:** Defined, Prototype

A continuous rail attached to a configurable screen edge.

Default placement:

- left edge;
- visible with tiled and maximized windows;
- hidden in true fullscreen;
- optional autohide mode.

Primary responsibilities:

- numbered workspace navigation;
- special-workspace access;
- essential system status;
- contextual and exceptional indicators;
- collapsed system tray;
- focused entry points into deeper surfaces;
- Vicinae access.

The resting bar must remain compact, stable, and quietly visible.

### Resting contents

From the start edge to the absolute end:

1. numbered workspace pager;
2. special-workspace control;
3. flexible space;
4. fixed contextual-status region;
5. collapsed tray affordance;
6. persistent download-speed indicator;
7. audio/output control;
8. compact resource indicator;
9. battery percentage and charging treatment;
10. combined date and time;
11. Vicinae entry point.

### Dependencies

- Hyprland workspace and fullscreen state;
- network throughput source;
- audio service;
- hardware and sensor service;
- battery service;
- system tray / StatusNotifierItem service;
- shell settings;
- Vicinae integration.

### Owned by

Franken Shell.

### Detailed specification

`docs/features/bar.md`

---

## 1.2 Right-edge control centre

**Status:** Defined, Prototype

A hidden utility drawer for notifications and secondary system controls.

It opens through:

- a dedicated keyboard shortcut;
- pointer drag from the extreme right edge toward the left;
- later, an optional trackpad gesture.

It defaults to the Notifications view.

### Primary contents

- header;
- quick controls;
- master volume slider;
- display brightness slider;
- Notifications tab;
- Volume Mixer tab;
- nested Wi-Fi page;
- nested Bluetooth page;
- settings entry point;
- session/power entry point.

### Quick controls

Initial set:

- Wi-Fi;
- Bluetooth;
- Do Not Disturb;
- Night Light;
- idle inhibitor.

### Dependencies

- notification server;
- NetworkManager or equivalent adapter;
- BlueZ or equivalent adapter;
- PipeWire audio service;
- display brightness service;
- Hyprland idle-inhibit integration;
- session actions;
- shell settings.

### Owned by

Franken Shell.

### Detailed specification

`docs/features/control-centre.md`

---

## 1.3 Focused edge-attached popovers

**Status:** Partially defined, Prototype

Compact surfaces opened from persistent bar controls.

Initial popovers:

- audio;
- resources;
- power and auto-cpufreq;
- calendar;
- tray;
- special-workspace selector;
- contextual-status details.

Popovers should provide enough depth for common actions without becoming full settings pages.

### Rules

- open from the invoking control's edge;
- remain visually attached to the configured bar edge;
- close with `Escape`, outside click, or toggle action;
- support keyboard focus and pointer interaction;
- avoid duplicating full control-centre pages unnecessarily.

### Owned by

Franken Shell.

---

# 2. Navigation and Workspace Features

## 2.1 Numbered workspace pager

**Status:** Defined, Prototype

A compact fixed-size pager showing numbered workspaces in groups of five.

Examples:

- `1–5`;
- `6–10`;
- `11–15`.

The displayed group follows the active numbered workspace.

### Behaviour

- clicking a number switches to it;
- scrolling moves through numbered workspaces;
- crossing a group boundary changes the visible group;
- occupancy is not shown in the resting bar;
- application icons are not shown;
- active workspace is clearly highlighted;
- numbered workspace meaning remains stable.

This supports the user's spatial-semantic workflow, where workspace numbers correspond to remembered roles and applications.

### Dependencies

- Hyprland workspace state;
- shared workspace configuration.

### Owned by

Franken Shell.

### Detailed specification

`docs/features/workspaces.md`

---

## 2.2 Special-workspace control

**Status:** Defined, Prototype

One persistent bar slot represents all configured special workspaces.

Initial special workspaces:

- Music;
- Movies/Anime;
- Books;
- Discord;
- Scratchpad;
- Todo.

### Resting behaviour

- neutral icon when no special workspace is open;
- active special workspace icon when one is visible.

### Expanded behaviour

Primary click opens a compact selector containing all configured special workspaces.

Keyboard bindings such as `Super+M`, `Super+A`, `Super+B`, `Super+D`, `Super+S`, and `Super+T` remain the fastest path.

### Configuration

Special workspaces must be defined once and shared by:

- the bar;
- quickshell-overview;
- Hyprland integration;
- settings;
- Vicinae shell commands.

### Owned by

Franken Shell.

### Detailed specification

`docs/features/workspaces.md`

---

## 2.3 Workspace and window overview

**Status:** Adopted, Near-term prototype integration

Use `quickshell-overview` instead of building a new overview.

### Expected capabilities

- visual workspace previews;
- window previews;
- pointer window focusing;
- drag-and-drop windows between workspaces;
- keyboard and Vim-style navigation;
- special-workspace support;
- close-on-outside-click and `Escape`;
- IPC invocation.

### Adaptation requirements

- use the shell's shared dynamic colour tokens;
- use shared typography, spacing, geometry, and motion tokens;
- read the shared workspace configuration;
- expose shell-compatible IPC;
- preserve comprehensive keyboard and pointer interaction;
- support the fixed semantic workspace layout;
- test screencopy stability;
- test multi-monitor scaling and rotation.

### Ownership boundary

`quickshell-overview` owns the visual overview implementation.

Franken Shell owns:

- invocation;
- shared configuration;
- theme integration;
- compatibility testing;
- fallback behaviour;
- any vendored maintenance patches.

### Fallback

Direct workspace switching must remain functional if the overview fails.

### Detailed specification

`docs/features/quickshell-overview-integration.md`

---

## 2.4 Focused-window actions

**Status:** Partially defined, Near-term

A compact action surface for the currently focused window.

Potential actions:

- move to numbered workspace;
- move to special workspace;
- toggle floating;
- toggle fullscreen;
- close gracefully;
- force-kill with explicit destructive treatment.

The active window title should not occupy permanent bar space.

### Candidate entry points

- secondary click on the active workspace number;
- keyboard shortcut;
- action inside quickshell-overview;
- Vicinae shell command.

### Owned by

Franken Shell, using Hyprland commands.

### Detailed specification

`docs/features/workspaces.md`

---

# 3. Command and Search Layer

## 3.1 Vicinae integration

**Status:** Adopted, Prototype

Vicinae is the canonical application launcher and command interface.

Franken Shell must not implement a competing launcher.

### Responsibilities delegated to Vicinae

- application launching;
- root search;
- clipboard history;
- file search;
- calculations and utilities;
- window search where suitable;
- shell command discovery;
- extension-based workflows.

### Shell integration

The bar contains a Vicinae entry point at the absolute end.

Interactions:

- primary click toggles Vicinae root search;
- secondary click opens a compact shortcut menu;
- keyboard shortcuts invoke Vicinae or specific commands directly.

Initial secondary-click shortcuts:

- root search;
- clipboard history;
- window search;
- file search;
- shell controls.

### Shell extension

A first-party Vicinae extension should expose:

- control-centre actions;
- workspace switching;
- special-workspace toggles;
- notification actions;
- power/session commands;
- shell settings entry points;
- other high-value shell commands.

### Ownership boundary

Vicinae owns search, command UI, and extension runtime.

Franken Shell owns:

- integration adapter;
- theme generation;
- shell extension commands;
- availability detection;
- user-facing failure state.

### Fallback

The shell must continue running if Vicinae is unavailable.

### Detailed specification

`docs/features/vicinae-integration.md`

---

# 4. System Status and Controls

## 4.1 Network throughput indicator

**Status:** Defined, Prototype

An always-visible bar item showing current download speed.

### Resting format

Examples:

- `0K`;
- `3K`;
- `20M`;
- `1G`.

Rules:

- whole numbers only;
- one-letter unit suffix;
- no `/s`;
- no direction arrow in the resting bar;
- fixed-size cell;
- tabular numerals;
- smoothed update cadence.

### Tooltip

Show both directions with arrows:

- `↓ 20M/s`;
- `↑ 3M/s`.

Upload speed is not shown persistently.

### Open decision

Whether values use bytes per second or bits per second should be configurable, with bytes per second as the likely default.

### Dependencies

- network interface statistics;
- active-interface aggregation logic.

### Owned by

Franken Shell.

### Detailed specification

`docs/features/bar.md`

---

## 4.2 Connectivity exception indicator

**Status:** Defined, Prototype

Normal connectivity is silent.

A contextual icon appears only for exceptional states such as:

- no network connection;
- local connection without internet;
- captive portal;
- limited connectivity.

This indicator is separate from the persistent throughput value.

### Owned by

Franken Shell.

---

## 4.3 Wi-Fi management

**Status:** Defined, Prototype

A comprehensive nested page inside the control centre.

### Initial capabilities

- enable and disable Wi-Fi;
- show active connection;
- scan available networks;
- connect to open and secured networks;
- password entry;
- hidden network connection;
- disconnect;
- forget saved network;
- refresh scanning;
- show signal, security, band, IP address, and link speed;
- distinguish disconnected, limited, captive-portal, and connected states;
- show Ethernet state in the same broader network section.

### Delegated advanced configuration

- advanced enterprise certificates;
- custom routing;
- complex DNS;
- low-level interface administration.

### Dependencies

- NetworkManager adapter or equivalent.

### Owned by

Franken Shell UI and integration service.

### Detailed specification

`docs/features/network-and-bluetooth.md`

---

## 4.4 Bluetooth management

**Status:** Defined, Prototype

A comprehensive nested page inside the control centre.

### Initial capabilities

- enable and disable Bluetooth;
- scan;
- show connected devices;
- show nearby devices;
- show previously paired devices;
- pair;
- connect;
- disconnect;
- forget;
- handle pairing codes and confirmations;
- expose battery level where available;
- show device type and connection state;
- provide clear progress and failure states.

Audio devices may offer an action to make the device the active output.

### Dependencies

- BlueZ adapter or equivalent;
- audio service for output switching.

### Owned by

Franken Shell UI and integration service.

### Detailed specification

`docs/features/network-and-bluetooth.md`

---

## 4.5 Audio control

**Status:** Partially defined, Prototype

The bar contains one persistent audio item.

Its glyph changes according to current output:

- speakers;
- wired headphones;
- Bluetooth headset/headphones;
- muted state.

This avoids separate permanent sound, headphone, and redundant Bluetooth indicators.

### Fast interactions

- primary click opens compact audio controls;
- scroll changes master volume;
- middle click toggles mute;
- keyboard access opens and navigates the same controls.

### Control-centre depth

The Volume Mixer tab provides:

- output-device selection;
- input-device selection;
- master output;
- per-application volume;
- per-stream mute;
- microphone level and mute.

### Dependencies

- PipeWire / WirePlumber adapter.

### Owned by

Franken Shell.

### Detailed specification

`docs/features/audio.md`

---

## 4.6 Display brightness

**Status:** Defined, Prototype

A persistent slider inside the control centre.

### Behaviour

- pointer drag;
- scroll while hovered;
- keyboard adjustment;
- brightness OSD during change;
- support for conditional monitor capability.

### Later considerations

- per-monitor brightness;
- external DDC/CI displays;
- keyboard backlight as a separate control.

### Owned by

Franken Shell.

---

## 4.7 Night Light

**Status:** Defined, Prototype

A control-centre quick control.

### Behaviour

- main action toggles;
- detail action may later expose temperature and schedule;
- user-triggered changes produce a system toast.

### Dependencies

Hyprland-compatible colour-temperature service selected during architecture work.

### Owned by

Franken Shell integration.

---

## 4.8 Idle inhibitor

**Status:** Defined, Prototype

A control-centre quick control for temporarily preventing idle actions.

### Behaviour

- clear active state;
- user-triggered toast;
- contextual bar indicator when active;
- optional duration selection later.

### Dependencies

- Hyprland idle-inhibit mechanism;
- idle daemon integration.

### Owned by

Franken Shell.

---

## 4.9 Do Not Disturb

**Status:** Defined, Prototype

A control-centre quick control.

### Behaviour

- suppress ordinary notification popups and sounds;
- preserve notification history;
- do not suppress OSDs;
- do not suppress user-triggered configuration toasts;
- allow conservative critical-event bypass;
- show clear active state.

### Owned by

Franken Shell notification service.

---

# 5. Resource and Power Features

## 5.1 Resource indicator

**Status:** Defined, Prototype

A compact always-visible RAM indicator using a circular progress arc and centred numeric percentage.

No permanent `RAM` label.

### Interaction

Primary click opens a compact resource popover.

### Dependencies

- memory statistics service.

### Owned by

Franken Shell.

---

## 5.2 Resource popover

**Status:** Defined, Prototype

A compact instrument-like system summary.

### Initial metrics

- CPU usage;
- CPU temperature;
- CPU fan speed where available;
- CPU clock where useful;
- GPU usage;
- GPU temperature;
- GPU fan speed where available;
- multiple GPU support;
- memory used and total;
- swap used and total;
- storage used and free;
- uptime;
- current power profile;
- highest-usage process where practical.

Unsupported metrics should be omitted.

### Interaction

Clicking the popover body launches the configured full system monitor.

### Dependencies

- Linux system statistics;
- hwmon or equivalent sensor access;
- GPU-specific telemetry;
- configured system monitor command.

### Owned by

Franken Shell.

### Detailed specification

`docs/features/resource-monitor.md`

---

## 5.3 Battery indicator

**Status:** Defined, Prototype

Always-visible numeric battery percentage.

### Resting behaviour

- plain numeric value;
- optional `%` based on visual testing;
- charging communicated through accent and restrained animation;
- warning and critical states use semantic treatment;
- no permanent battery glyph required.

### Interaction

Primary click opens the power and auto-cpufreq panel.

### Dependencies

- UPower or equivalent battery source.

### Owned by

Franken Shell.

---

## 5.4 auto-cpufreq management

**Status:** Partially defined, Near-term

An edge-attached power-management panel opened from the battery item.

### Initial responsibilities

- show current battery/charger state;
- show active auto-cpufreq profile;
- expose supported battery and charger configuration;
- governor;
- energy-performance preference;
- turbo policy;
- min/max frequency where supported;
- charging thresholds where supported;
- save, apply, and revert;
- clearly distinguish automatic behaviour from overrides.

### Safety requirements

- validate values;
- write atomically;
- preserve unknown configuration where practical;
- use a narrow privileged helper where required;
- surface apply failures;
- never write arbitrary privileged files directly from QML.

### Fallback

If auto-cpufreq is unavailable:

- battery status remains functional;
- panel explains the missing service;
- optional installation or documentation action may be offered later.

### Dependencies

- auto-cpufreq;
- privileged helper design;
- battery service.

### Owned by

Franken Shell integration and helper.

### Detailed specification

`docs/features/power-and-auto-cpufreq.md`

---

# 6. Time and Calendar

## 6.1 Combined date and time

**Status:** Defined, Prototype

One combined bar control.

### Resting behaviour

- 24-hour time;
- compact stacked presentation on a vertical bar;
- date included;
- full month name not required;
- format adapts by bar orientation.

### Interaction

Primary click opens the calendar panel.

### Owned by

Franken Shell.

---

## 6.2 Calendar panel

**Status:** Partially defined, Prototype

Initial version contains only a local calendar interface.

### Initial capabilities

- current full date;
- month grid;
- previous and next month;
- Today action;
- selected-day state;
- keyboard navigation;
- pointer navigation.

The prototype should not show a permanently empty event area.

### Near-term extension

Google Calendar integration immediately after the working prototype.

The component and data model should anticipate:

- multiple calendars;
- event colours;
- all-day and timed events;
- selected-day agenda;
- account and sync state;
- opening and creating events.

### Owned by

Franken Shell.

### Detailed specification

`docs/features/calendar.md`

---

# 7. Notifications and Feedback

## 7.1 Notification server and history

**Status:** Defined, Prototype

Franken Shell owns notification presentation and history.

### Behaviour

- all applications may show popups by default;
- notifications are silent by default;
- grouped by application;
- burst notifications coalesce;
- actions are supported;
- individual and group dismissal;
- clear all non-persistent notifications;
- progress notifications;
- no global unread count;
- no bar badge;
- history appears in the control centre;
- opening the drawer is the review mechanism.

### Sound rules

Near-term support for optional sound rules:

- per application;
- per notification title or title pattern;
- incoming calls, alarms, timers, and critical alerts may use sound by default.

### Owned by

Franken Shell.

### Detailed specification

`docs/features/notifications.md`

---

## 7.2 Notification popups

**Status:** Defined, Prototype

Application popups emerge from the right side and remain slightly inset from the edge-drag activation zone.

### Behaviour

- stack downward;
- pause timeout on hover or focus;
- support actions;
- support dismissal;
- grouped burst updates replace existing cards;
- no duplicate popup while the control centre is already open;
- ordinary popups respect Do Not Disturb and fullscreen suppression.

### Fullscreen

- ordinary popups are withheld;
- history is preserved;
- withheld notifications do not replay as a burst;
- a subtle summary may be considered later.

### Owned by

Franken Shell.

---

## 7.3 System configuration toasts

**Status:** Defined, Prototype

Compact confirmation feedback for user-triggered state changes.

Examples:

- Wi-Fi enabled;
- connected to network;
- Bluetooth disabled;
- Night Light enabled;
- output changed;
- power configuration applied.

### Behaviour

- brief;
- update or replace when repeated;
- do not normally enter notification history;
- remain visible during Do Not Disturb;
- failures remain longer and may offer actions.

### Owned by

Franken Shell.

### Detailed specification

`docs/features/osds-and-toasts.md`

---

## 7.4 OSDs

**Status:** Defined, Prototype

Transient direct-manipulation feedback.

Initial OSDs:

- volume;
- brightness.

Potential later OSDs:

- microphone;
- keyboard backlight;
- per-monitor brightness;
- touchpad state.

### Behaviour

- update in place;
- disappear quickly;
- do not enter history;
- remain visible during Do Not Disturb;
- visible over fullscreen when triggered by the user.

Track changes produce no notification or OSD.

### Owned by

Franken Shell.

### Detailed specification

`docs/features/osds-and-toasts.md`

---

## 7.5 Critical-interruption policy

**Status:** Defined, Prototype

Conservative categories may bypass Do Not Disturb and fullscreen suppression.

### Default bypass categories

- critically low battery or imminent shutdown;
- severe CPU/GPU temperature;
- serious filesystem or storage failure;
- incoming voice/video call;
- alarms and timers;
- authentication prompts;
- pairing codes and confirmations;
- security or permission prompts requiring immediate input;
- failure of an operation explicitly initiated by the user;
- screen recording unexpectedly stopped.

### Respect Do Not Disturb by default

- ordinary messages;
- routine calendar reminders;
- completed downloads and transfers;
- ordinary application updates;
- non-critical low-battery warning.

### Owned by

Franken Shell notification policy.

---

# 8. System Tray

## 8.1 Collapsed tray affordance

**Status:** Defined, Prototype

The bar shows one compact tray affordance when tray items exist.

No tray application is pinned by default.

### Visual direction

A stacked or overlapping icon motif representing multiple contained applications.

### Behaviour

- primary click opens tray drawer;
- keyboard-accessible;
- urgent state may alter the affordance;
- exact tray count is not shown persistently;
- fixed layout prevents tray population from expanding the bar.

### Owned by

Franken Shell.

---

## 8.2 Tray drawer

**Status:** Partially defined, Prototype

An edge-attached drawer or popover containing all StatusNotifierItem entries.

### Required behaviour

- left-click;
- right-click;
- scroll;
- keyboard navigation;
- close with `Escape`;
- outside-click dismissal;
- stable ordering;
- icon pinning support later.

### Near-term

- optional user-pinned tray items;
- per-item attention handling;
- configurable ordering.

### Dependencies

- StatusNotifierWatcher / StatusNotifierItem implementation;
- menu protocol support.

### Owned by

Franken Shell.

### Detailed specification

`docs/features/tray.md`

---

# 9. Session, Lock, and Security

## 9.1 Session menu

**Status:** Partially defined, Prototype or near-term

Opened from the control-centre power action.

Potential actions:

- lock;
- logout;
- suspend;
- hibernate where supported;
- reboot;
- shutdown.

### Requirements

- keyboard navigation;
- explicit destructive confirmation where appropriate;
- clear distinction between suspend and logout;
- no immediate shutdown from a small header icon;
- consistent shell styling.

### Owned by

Franken Shell, delegating actions to system services.

### Detailed specification

`docs/features/session-and-lock.md`

---

## 9.2 Lock screen

**Status:** Open, Later

The lock screen should eventually share:

- dynamic colour roles;
- typography;
- date/time treatment;
- notification privacy rules;
- authentication feedback.

Security and reliability take priority over visual experimentation.

A separate design pass is required before implementation.

### Owned by

To be decided.

---

# 10. Settings and Configuration

## 10.1 Shell settings surface

**Status:** Open, Near-term

A dedicated settings interface for meaningful shell configuration.

### Likely sections

- bar;
- workspaces;
- gestures;
- notifications and sounds;
- appearance;
- control centre;
- commands and external applications;
- integrations;
- multi-monitor;
- accessibility;
- diagnostics.

### Initial configuration priorities

- bar edge;
- autohide;
- fullscreen reveal policy;
- workspace group size;
- special-workspace definitions;
- system monitor command;
- Vicinae commands;
- throughput unit convention;
- gesture bindings;
- notification sound rules;
- control-centre width.

### Owned by

Franken Shell.

### Detailed specification

`docs/configuration-model.md`

---

## 10.2 Shared configuration model

**Status:** Required, Prototype architecture

One source of truth for all shared concepts.

### Must be shared across components

- workspace definitions;
- special workspace definitions;
- bar orientation and dimensions;
- theme tokens;
- motion tokens;
- application commands;
- adopted-component versions;
- system service choices;
- notification policy;
- sound rules;
- hardware capability state.

### Owned by

Franken Shell core.

---

# 11. Visual System

## 11.1 Dynamic wallpaper-derived colours

**Status:** Defined, Prototype

Caelestia's dynamic colour system is the colour source for all relevant shell surfaces.

### Required consumers

- bar;
- control centre;
- popovers;
- notifications;
- toasts;
- OSDs;
- quickshell-overview;
- Vicinae theme;
- future lock and session surfaces.

### Requirements

- semantic roles, not raw colours;
- smooth and safe theme transition;
- readable contrast;
- fallback palette;
- integration failure must not break the shell.

### Owned by

Franken Shell theme service, using selected Caelestia services.

---

## 11.2 Material You Expressive component language

**Status:** Partially defined, Prototype foundation

Shared rules for:

- spacing;
- typography;
- icon sizes;
- corner geometry;
- focus;
- hover;
- pressed state;
- active state;
- warning and critical state;
- surface opacity;
- motion.

### Interpretation

- compact while idle;
- more expressive while active;
- opaque and readable control centre;
- restrained animation;
- no literal mobile layout copying.

### Owned by

Franken Shell design system.

### Detailed specification

`docs/visual-language.md`

---

## 11.3 Motion system

**Status:** Partially defined, Near-term polish

Shared durations and easing for:

- edge drawer;
- popovers;
- workspace group changes;
- notification entry and dismissal;
- toast replacement;
- control selection;
- OSD appearance;
- theme transition.

### Requirements

- input never waits for animation;
- reduced-motion mode;
- no perpetual decorative motion;
- direct manipulation tracks pointer position.

### Owned by

Franken Shell design system.

---

# 12. Input and Gesture System

## 12.1 Keyboard interaction language

**Status:** Defined in principle, Prototype requirement

All major surfaces need:

- invocation shortcut;
- focus acquisition;
- directional navigation;
- activation;
- back and dismissal;
- visible focus;
- shortcut conflict documentation.

### Owned by

Franken Shell.

### Detailed specification

`docs/interaction-language.md`

---

## 12.2 Mouse interaction language

**Status:** Defined in principle, Prototype requirement

Common patterns:

- primary click for direct action;
- secondary click for additional actions;
- middle click for concise toggles where established;
- scroll for continuous values or ordered navigation;
- click outside to dismiss;
- drag for direct manipulation;
- hover for tooltip, not essential action.

### Owned by

Franken Shell.

---

## 12.3 Trackpad gestures

**Status:** Open, Near-term

Potential gestures:

- workspace navigation;
- control-centre reveal;
- overview invocation;
- panel dismissal.

### Requirements

- avoid conflict with Hyprland workspace gestures;
- every gesture has a non-gesture alternative;
- configurable;
- test reliability before making default;
- do not assume physical trackpad-edge detection is available.

### Owned by

Franken Shell and Hyprland configuration integration.

---

## 12.4 Right-edge drag layer

**Status:** Defined, Prototype

An invisible activation strip at the extreme right edge.

### Behaviour

- pointer down near edge;
- horizontal drag intent detection;
- drawer follows pointer;
- threshold and velocity determine snap open or closed;
- tiny movements ignored;
- suppressed in fullscreen by default;
- no visible handle;
- no hover activation.

### Owned by

Franken Shell.

---

# 13. Multi-Monitor Support

## 13.1 Bar ownership

**Status:** Open

Decisions still required:

- bar on every monitor or selected monitor;
- per-monitor or global workspace state;
- primary-monitor fallback;
- orientation per monitor;
- behaviour on hotplug.

---

## 13.2 Control-centre ownership

**Status:** Open

Possible policies:

- open on monitor where invoked;
- open on pointer monitor for edge drag;
- open on focused-window monitor for keyboard;
- one global drawer at a time.

---

## 13.3 Notifications and OSD ownership

**Status:** Open

Possible policies:

- notification popup on focused monitor;
- OSD on monitor where input originated;
- critical alert on active monitor;
- avoid duplicate presentation.

---

## 13.4 Scaling and rotation

**Status:** Open, Required before stable release

Must test:

- mixed DPI;
- fractional scaling;
- rotated monitors;
- different bar edges per monitor;
- quickshell-overview screencopy;
- panel placement at monitor boundaries.

### Detailed specification

`docs/features/multi-monitor.md`

---

# 14. External Integrations

## 14.1 Caelestia

**Status:** Adopted, Prototype

Retain selected services and capabilities rather than the entire shell.

Likely retained areas:

- wallpaper-derived dynamic colours;
- useful system services already proven in the current setup;
- selected data providers and utilities.

Exact retained modules must be inventoried before implementation.

---

## 14.2 Vicinae

**Status:** Adopted, Prototype

See Section 3.1.

---

## 14.3 quickshell-overview

**Status:** Adopted, Near-term prototype integration

See Section 2.3.

---

## 14.4 auto-cpufreq

**Status:** Adopted, Near-term

See Section 5.4.

---

## 14.5 Hyprland 0.55+ Lua configuration

**Status:** Required compatibility target

The shell and accompanying configuration examples must target Hyprland 0.55+ and Lua-based configuration.

### Requirements

- document expected bindings;
- avoid obsolete configuration syntax;
- isolate version-sensitive IPC;
- test workspace and fullscreen state;
- integrate special workspaces;
- support overview and gesture bindings.

---

## 14.6 System monitor

**Status:** Configurable external application

The resource popover launches a user-configurable full system monitor.

The shell should not build a complete process-management application in the initial scope.

---

# 15. Diagnostics and Reliability

## 15.1 Integration health

**Status:** Near-term

A diagnostics surface or command should report availability of:

- Vicinae;
- quickshell-overview;
- NetworkManager;
- BlueZ;
- PipeWire / WirePlumber;
- auto-cpufreq;
- battery source;
- brightness controls;
- sensor sources;
- tray watcher;
- notification service;
- dynamic colour source.

### Behaviour

- human-readable status;
- actionable failure messages;
- no crash due to missing optional service.

---

## 15.2 Logging

**Status:** Prototype architecture requirement

Structured logs should cover:

- service startup;
- external command failures;
- IPC failures;
- configuration parse errors;
- permission problems;
- sensor failures;
- notification handling;
- edge-drag state errors.

Logs must not expose notification contents or secrets by default.

---

## 15.3 Graceful degradation

**Status:** Required everywhere

Examples:

- no Vicinae → show command-layer error only;
- no overview → direct workspace switching remains;
- no auto-cpufreq → battery status remains;
- no fan sensor → omit fan row;
- no tray items → hide tray affordance;
- no Bluetooth adapter → hide or disable relevant controls with explanation;
- no brightness control → omit brightness slider;
- theme source failure → use fallback palette.

---

# 16. Implementation Priority Summary

## Phase A — Shell skeleton

**Goal:** Prove structure, configuration, services, and input.

Includes:

- process and module structure;
- shared configuration;
- theme token service;
- Hyprland adapter;
- bar window;
- control-centre window;
- basic edge drag;
- keyboard focus and dismissal;
- diagnostics foundation.

---

## Phase B — Working prototype

**Goal:** Produce a shell usable for daily basic operation.

Includes:

- workspace pager;
- special-workspace control;
- download-speed indicator;
- audio item;
- resource ring and popover;
- battery and calendar controls;
- Vicinae integration;
- collapsed tray;
- control-centre shell;
- quick controls;
- volume and brightness;
- notifications;
- toasts and OSDs;
- basic Wi-Fi and Bluetooth pages;
- DND;
- fullscreen rules.

---

## Phase C — Adopted-component integration

**Goal:** Replace temporary gaps with first-class integrations.

Includes:

- quickshell-overview integration;
- shared workspace configuration;
- Vicinae shell extension;
- Vicinae dynamic theme;
- auto-cpufreq management;
- external system monitor launch;
- better tray menu handling.

---

## Phase D — Near-term expansion

**Goal:** Complete the planned daily-use experience.

Includes:

- Google Calendar integration;
- notification sound rules;
- richer volume mixer;
- focused-window actions;
- session menu;
- settings surface;
- gesture configuration;
- integration health UI;
- multi-monitor policy and testing.

---

## Phase E — Stability and polish

**Goal:** Make the shell maintainable and release-ready.

Includes:

- motion tokens;
- reduced motion;
- accessibility audit;
- mixed-DPI testing;
- rotated-monitor testing;
- failure-state testing;
- performance profiling;
- service reconnection;
- migration strategy;
- compatibility pinning;
- documentation.

---

# 17. Feature Ownership Matrix

| Feature | Franken Shell | External component/service |
|---|---:|---|
| Persistent bar | Owns | Hyprland and system data |
| Control centre | Owns | Network, Bluetooth, audio, display services |
| Notifications | Owns presentation and policy | Freedesktop notification clients |
| Application launcher | Integrates | Vicinae owns implementation |
| Command interface | Integrates and extends | Vicinae owns UI/runtime |
| Workspace overview | Integrates and adapts | quickshell-overview owns base implementation |
| Dynamic colours | Integrates and normalizes | Selected Caelestia services |
| Power policy | Integrates and configures | auto-cpufreq |
| Full system monitor | Launches | User-configured application |
| Workspace switching | Owns UI and commands | Hyprland |
| Special workspaces | Owns shared definitions | Hyprland |
| Wi-Fi UI | Owns | NetworkManager or selected backend |
| Bluetooth UI | Owns | BlueZ |
| Audio UI | Owns | PipeWire / WirePlumber |
| Tray UI | Owns | StatusNotifierItem clients |
| Calendar UI | Owns | Local date service; Google later |
| Lock screen | Undecided | To be selected |
| Session actions | Owns UI | systemd-logind or selected backend |

---

# 18. Open Feature Areas

The following areas require dedicated design work before they are implementation-complete:

- exact bar geometry for all four edges;
- multi-monitor ownership rules;
- complete trackpad gesture vocabulary;
- session and lock surfaces;
- exact tray drawer layout;
- full audio popover and mixer semantics;
- notification history retention;
- sound rule matching syntax;
- Google Calendar account and authentication architecture;
- auto-cpufreq privileged helper design;
- shell settings information architecture;
- retained Caelestia service inventory;
- exact quickshell-overview adoption strategy;
- active-window action set;
- critical alert thresholds;
- throughput byte/bit convention;
- monitor-specific brightness;
- network captive-portal handling;
- fallback launcher policy, if any.

These should remain visible in `open-questions.md` rather than being silently improvised during implementation.
