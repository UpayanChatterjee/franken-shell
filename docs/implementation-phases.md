# Franken Shell — Implementation Phases

> **Status:** Working delivery plan  
> **Purpose:** Define the order in which Franken Shell should be built, validated, integrated, and polished  
> **Related documents:** `product-vision.md`, `design-principles.md`, `feature-map.md`, `architecture.md`, `configuration-model.md`

This document converts the product and architecture decisions into a practical implementation sequence.

The phases are intentionally ordered to validate the riskiest interaction and architecture assumptions before investing heavily in visual polish.

The plan assumes:

- Hyprland 0.55+ with Lua configuration;
- Quickshell / QML as the main shell runtime;
- selected Caelestia services retained;
- Vicinae adopted as the command and launcher layer;
- quickshell-overview adopted as the workspace/window overview;
- auto-cpufreq adopted as the power-policy backend;
- a keyboard-first shell with comprehensive pointer support.

---

# 1. Delivery Principles

## 1.1 Validate structure before polish

The first milestone is not a beautiful shell.

It is a shell that:

- starts reliably;
- knows its monitors;
- reads configuration;
- tracks Hyprland state;
- opens and closes surfaces correctly;
- restores focus;
- survives missing optional services;
- can be debugged.

Visual polish should begin only after those foundations work.

---

## 1.2 Build vertical slices

Avoid completing all services first and all UI later.

Each phase should deliver one usable end-to-end slice.

Example:

```text
Hyprland workspace state
    ↓
workspace controller
    ↓
workspace pager
    ↓
click and keyboard interaction
    ↓
error and fallback behaviour
```

A thin working slice reveals architectural problems sooner than isolated components.

---

## 1.3 Keep adopted components separate initially

Vicinae and quickshell-overview should remain separate processes during early implementation.

This reduces:

- initial integration complexity;
- service duplication risk;
- source-merging work;
- crash propagation;
- visual refactoring before core behaviour is stable.

Deep integration can follow once the shell itself is reliable.

---

## 1.4 Use fixtures before every backend exists

The first bar and control-centre prototypes should use fixture models.

Fixtures should represent:

- workspace 1 active;
- workspace 7 active;
- a special workspace open;
- no network;
- connected Bluetooth device;
- recording active;
- battery charging;
- low battery;
- high RAM;
- multiple notifications;
- missing sensors;
- missing optional integrations.

This allows interaction and visual work without blocking on all service adapters.

---

## 1.5 Every phase has exit criteria

A phase is complete only when:

- its acceptance criteria pass;
- known defects are recorded;
- new design decisions are added to `decisions.md`;
- unresolved issues are added to `open-questions.md`;
- the next phase is not forced to compensate for hidden technical debt.

---

# 2. Phase Overview

| Phase | Goal | Outcome |
|---|---|---|
| **0. Project bootstrap** | Create a reproducible development baseline | Repository, version pinning, startup, logging |
| **1. Core shell skeleton** | Prove architecture and monitor-aware surfaces | Config, theme, services, bar/control-centre hosts |
| **2. Bar foundation** | Make the persistent rail usable | Workspace pager, layout zones, placeholder status |
| **3. Control-centre mechanics** | Validate right-edge drawer interaction | Edge drag, focus, navigation stack, placeholder pages |
| **4. Core system adapters** | Connect real desktop state | Hyprland, audio, battery, network, Bluetooth, tray |
| **5. Notifications and feedback** | Make interruption and confirmation coherent | Popups, history, DND, toasts, OSDs |
| **6. Working daily-use prototype** | Replace fixtures with useful shell features | Functional bar and control centre |
| **7. Adopted component integration** | Integrate Vicinae and quickshell-overview properly | Shared commands, theme, workspaces |
| **8. Power, calendar, and deeper utilities** | Complete secondary workflows | auto-cpufreq, calendar, resource details |
| **9. Settings and configuration UI** | Make the shell maintainable without manual edits | Settings app/surface, validation, diagnostics |
| **10. Multi-monitor and gesture hardening** | Make the shell robust across real setups | Ownership policy, hotplug, scale, gestures |
| **11. Visual polish and accessibility** | Apply the final design language | Motion, typography, contrast, reduced motion |
| **12. Packaging and release hardening** | Prepare repeatable installation and maintenance | Packaging, migration, tests, documentation |

Phases may overlap slightly, but the exit criteria should remain sequential.

---

# 3. Phase 0 — Project Bootstrap

## Goal

Create a reproducible project that can launch a minimal Quickshell instance and report useful diagnostics.

## Scope

### Repository setup

Create:

```text
shell.qml
qmldir
README.md
docs/
core/
theme/
services/
surfaces/
features/
components/
tests/
packaging/
```

Do not create every planned file as an empty placeholder.

Create only the initial files needed for startup.

### Version pinning

Record:

- Franken Shell version;
- exact D-071 Quickshell version, commit, and Arch package;
- Qt version;
- tested Hyprland version and Lua configuration mode;
- tested Vicinae version;
- tested quickshell-overview revision;
- configuration schema version;
- IPC version.

The Phase 0 pin is not a minimum supported version. Compatibility range work is
deferred to Q-113.

### Parallel-safe development mode

The current Caelestia shell remains separately runnable and continues to own
notifications, tray watching, Polkit-agent duties, lock/session behaviour, and
other exclusive session responsibilities.

Launch Franken Shell manually from the repository path in a non-owning mode.
The Phase 0 instance must not register notification, tray-watcher, Polkit-agent,
session-lock, or equivalent exclusive ownership.

### Development commands

Provide simple commands for:

- start;
- in-process reload;
- full process restart;
- stop;
- logs;
- validate config;
- run mock mode.

### Logging

Implement minimal structured logging with domains:

- core;
- config;
- theme;
- surfaces.

### Fallback theme

Create a built-in valid palette so startup does not depend on Caelestia.

### Basic diagnostics

Expose:

- project version;
- Quickshell version;
- Hyprland version where available;
- config path;
- startup state.

## Deliverables

- repository skeleton;
- runnable `shell.qml`;
- development README;
- fallback theme;
- version metadata;
- basic logs;
- startup and reload scripts or commands.

## Acceptance criteria

- shell starts with no user configuration;
- shell starts without Caelestia;
- shell can run in parallel with the existing Caelestia shell without claiming exclusive session services;
- shell reload does not create duplicate instances;
- reload and full restart are distinct documented operations;
- logs identify startup success or failure;
- project versions are visible through one diagnostic command;
- invalid initial configuration falls back safely.

## Explicit non-goals

- real bar;
- control centre;
- notifications;
- tray watching;
- Polkit-agent or session-lock ownership;
- system integrations;
- visual polish.

---

# 4. Phase 1 — Core Shell Skeleton

## Goal

Implement the architectural foundation required by every later feature.

## Scope

### Configuration service

Implement:

- built-in defaults;
- user configuration path;
- schema version;
- parsing;
- validation;
- last-valid-state retention;
- hot-reload debounce;
- structured errors.

The first schema can include only:

- shell;
- appearance;
- bar;
- control centre;
- workspaces;
- integrations;
- commands.

### Theme manager

Implement:

- fallback palette;
- semantic colour roles;
- typography tokens;
- spacing tokens;
- radius tokens;
- motion tokens;
- atomic theme update API.

Caelestia integration remains optional at this stage.

### Monitor registry

Implement:

- monitor enumeration;
- geometry;
- scale;
- transform;
- focused monitor;
- configured bar edge;
- hotplug logging.

### Surface coordinator

Implement:

- open and close one popover;
- open and close control centre;
- close all transient surfaces;
- single active major surface;
- focus restoration placeholder;
- monitor ownership.

### Command registry

Implement:

- executable plus arguments;
- availability check;
- asynchronous execution;
- exit status;
- structured failure;
- no shell string concatenation.

### Capability registry

Initial capabilities:

```text
hasHyprland
hasVicinae
hasOverview
hasBattery
hasNetworkBackend
hasBluetoothBackend
hasAudioBackend
```

### IPC skeleton

Expose:

- version;
- reload config;
- close transient surfaces;
- diagnostics summary.

## Deliverables

- `ConfigService`;
- `ThemeManager`;
- `MonitorRegistry`;
- `SurfaceCoordinator`;
- `CommandRegistry`;
- `CapabilityRegistry`;
- shell IPC;
- fixture mode.

## Acceptance criteria

- one shell root owns all core services;
- config reload is atomic;
- theme changes apply through semantic tokens;
- monitor hotplug does not crash the shell;
- command failures are visible in diagnostics;
- one transient surface closes when another opens;
- mock mode works without live system services.

## Risks to validate

- Quickshell singleton patterns;
- reload lifecycle;
- screen-to-Hyprland monitor mapping;
- focus restoration primitives;
- IPC type limitations.

---

# 5. Phase 2 — Bar Foundation

## Goal

Create the persistent edge rail and validate orientation, hierarchy, fullscreen behaviour, and layout stability.

## Scope

### Bar host

Implement a monitor-aware edge-attached window.

Initial target:

- left edge only for first functional pass;
- configurable edge architecture from the start;
- visible with maximized windows;
- hidden in true fullscreen;
- no autohide yet.

### Semantic zones

Implement:

```text
start
flexible space
context region
end
absolute end
```

### Fixture components

Create mock versions of:

- workspace pager;
- special workspace control;
- contextual-status slots;
- tray affordance;
- network speed;
- audio;
- resource ring;
- battery;
- date/time;
- Vicinae button.

### Workspace pager interaction

Using fixture state:

- show `1–5`;
- switch to `6–10` when active workspace becomes 7;
- active item highlight;
- click;
- keyboard focus;
- scroll;
- active workspace click requests overview.

### Popover host

Implement one anchor-aware host.

Use placeholder content for:

- audio;
- resource;
- calendar;
- tray;
- special workspace selector.

### Fullscreen hide

Connect to fixture or initial Hyprland fullscreen state.

## Deliverables

- working left bar;
- stable zones;
- workspace group behaviour;
- orientation-aware component API;
- popover host;
- fullscreen hide;
- keyboard focus visuals.

## Acceptance criteria

- bar remains visible for maximized windows;
- bar hides for true fullscreen;
- workspace group changes correctly;
- contextual slots do not shift the end section;
- changing fixture values from `3K` to `999M` does not move neighbours;
- only one popover is open;
- `Escape` closes popover and restores focus;
- bar survives text scaling at the initial supported range.

## Deferred

- real services;
- autohide;
- all four edges;
- detailed visual polish;
- multi-monitor final policy.

---

# 6. Phase 3 — Control-Centre Mechanics

## Goal

Validate the highest-risk custom interaction: dragging the right-edge control centre into view.

## Scope

### Control-centre host

Implement:

- right-edge-attached surface;
- no permanent exclusive zone;
- keyboard opening;
- pointer opening;
- scrim;
- outside-click dismissal;
- focus acquisition;
- focus restoration.

### Invisible edge activation region

Implement the drag state machine:

```text
Idle
PressedAtEdge
DragIntentDetected
Dragging
SettlingOpen
SettlingClosed
Open
```

### Gesture tuning

Initial parameters:

- narrow activation strip;
- horizontal intent ratio;
- minimum distance;
- open threshold;
- velocity threshold;
- fullscreen suppression.

### Placeholder layout

Build:

- header;
- quick-control row;
- volume slider;
- brightness slider;
- Notifications tab;
- Volume Mixer tab;
- internal page stack;
- placeholder Network page;
- placeholder Bluetooth page.

### Navigation

Implement:

- keyboard tab navigation;
- arrow navigation;
- `Escape` stack behaviour;
- back button;
- click outside;
- drag closed.

### Direct manipulation

Panel and scrim follow pointer reveal progress.

## Deliverables

- control-centre host;
- edge activation host;
- reveal state machine;
- internal navigation stack;
- placeholder content;
- focus and dismissal behaviour.

## Acceptance criteria

- a drag starting outside the activation strip does nothing;
- mostly vertical movement does not open the drawer;
- small horizontal movement snaps closed;
- sufficient distance or velocity opens;
- panel follows pointer without visible lag;
- dragging back closes;
- keyboard shortcut opens the drawer;
- `Escape` returns from detail page before closing drawer;
- pointer edge drag is suppressed in fullscreen;
- explicit keyboard opening follows the documented policy;
- opening control centre closes bar popovers.

## Critical stop condition

Do not continue into extensive feature implementation until edge dragging and focus behaviour feel reliable.

---

# 7. Phase 4 — Core System Adapters

## Goal

Replace fixture state with normalized real desktop services.

## Scope

Implement adapters one at a time.

## 7.1 Hyprland adapter

Required state:

- active workspace;
- workspaces;
- special workspaces;
- focused window;
- focused monitor;
- fullscreen state;
- urgent state.

Required commands:

- switch workspace;
- toggle special workspace;
- close window;
- toggle floating;
- toggle fullscreen;
- move window.

### Exit criteria

- bar workspace pager tracks real Hyprland state;
- maximized is not misclassified as fullscreen;
- special workspace state is reliable;
- reconnect after compositor event-stream interruption.

---

## 7.2 Audio adapter

Required state:

- default output;
- output icon category;
- volume;
- mute;
- output devices;
- input devices;
- application streams.

Required commands:

- set volume;
- toggle mute;
- select output;
- select input;
- set stream volume.

### Exit criteria

- bar icon changes between speakers and headphones;
- scroll adjusts volume;
- middle click mutes;
- no duplicate audio models.

---

## 7.3 Battery adapter

Required state:

- percentage;
- charging;
- time estimate where available;
- low and critical state;
- power source.

### Exit criteria

- bar value updates correctly;
- charging state is distinguishable;
- machine without battery does not show dead UI.

---

## 7.4 Throughput adapter

Required state:

- raw download speed;
- raw upload speed;
- smoothed values;
- formatted values.

### Exit criteria

- whole-number compact formatting;
- tooltip values;
- fixed-width rendering;
- active-interface aggregation works for Wi-Fi and Ethernet.

---

## 7.5 Network adapter

Required state:

- connectivity;
- Wi-Fi enabled;
- Ethernet state;
- active connection;
- visible networks;
- saved networks;
- scanning;
- connection tasks;
- limited/captive-portal state.

### Exit criteria

- failure indicator distinguishes no network and no internet;
- network list updates;
- connection attempts expose progress and errors.

---

## 7.6 Bluetooth adapter

Required state:

- adapter availability;
- power;
- scanning;
- paired devices;
- connected devices;
- battery where available;
- pairing prompts.

### Exit criteria

- absent adapter degrades correctly;
- pairing state is explicit;
- connected non-audio device can surface contextually.

---

## 7.7 Tray adapter

Required state:

- items;
- icons;
- attention status;
- activation;
- menus;
- scroll.

### Exit criteria

- tray affordance hides when empty;
- application context menus work;
- large tray population remains collapsed.

---

## 7.8 Brightness adapter

Required state:

- availability;
- current brightness;
- range;
- monitor or device target.

### Exit criteria

- control omitted if unsupported;
- slider updates correctly;
- no blocking process calls on UI thread.

---

## Deliverables

- normalized adapters;
- capability states;
- errors and reconnect logic;
- fixture and real modes.

## Acceptance criteria

- each adapter can fail independently;
- UI never reads backend-specific state directly;
- secrets are not logged;
- service reconnect does not require full shell restart;
- hidden surfaces do not poll at high frequency.

---

# 8. Phase 5 — Notifications and Feedback

## Goal

Implement the three distinct feedback channels: application notifications, system toasts, and OSDs.

## Scope

## 8.1 Notification service

Implement:

- notification server ownership;
- normalized notification model;
- app identity;
- title/body/actions;
- urgency;
- progress;
- close/dismiss;
- in-memory history.

## 8.2 Notification policy

Implement:

- routine/important/critical classification;
- DND;
- fullscreen suppression;
- conservative critical bypass;
- popup timeout;
- grouping;
- burst coalescing.

## 8.3 Popup host

Implement:

- right-side popup stack;
- edge inset;
- hover/focus timeout pause;
- actions;
- dismissal;
- grouped update;
- maximum visible count.

## 8.4 Notification drawer

Implement:

- group by application;
- expand/collapse;
- individual dismissal;
- group dismissal;
- clear all;
- progress entries;
- stable scroll position.

## 8.5 System toasts

Implement keyed categories:

- network;
- Bluetooth;
- Night Light;
- idle inhibitor;
- audio output;
- power;
- generic success/failure.

## 8.6 OSDs

Implement:

- volume;
- brightness;
- update in place;
- timeout;
- fullscreen visibility;
- DND independence.

## 8.7 Sounds

First prototype behaviour:

- all ordinary notifications silent;
- calls, alarms, timers, and critical alerts may have sound if the event category is reliable;
- no per-app editor yet.

## Deliverables

- notification service;
- policy engine;
- popup UI;
- drawer history;
- DND;
- toasts;
- OSDs.

## Acceptance criteria

- all ordinary apps can produce popups;
- repeated Discord/Slack-style notifications coalesce;
- no unread count appears anywhere;
- opening control centre prevents duplicate popup display;
- DND suppresses ordinary popup and sound but keeps history;
- volume and brightness still show OSD during DND;
- track changes create no popup or OSD;
- ordinary popups are withheld in fullscreen;
- critical alerts remain visible;
- notification burst cannot fill the entire screen;
- notification contents are not logged.

---

# 9. Phase 6 — Working Daily-Use Prototype

## Goal

Produce the first version suitable for regular use.

This is the milestone after which the project can begin replacing the user's current shell incrementally.

## Scope

## 9.1 Real bar contents

Complete:

- numbered workspace pager;
- special-workspace control;
- fixed contextual-status region;
- collapsed tray;
- download speed;
- audio;
- RAM ring;
- battery;
- date/time;
- Vicinae entry point.

## 9.2 Bar visibility

Complete:

- hide in fullscreen;
- visible when maximized;
- optional autohide;
- keyboard reveal;
- pointer reveal;
- configurable delays.

## 9.3 Special workspace selector

Populate from shared config.

Support:

- active icon;
- click toggle;
- keyboard navigation;
- configurable special workspaces.

## 9.4 Resource popover

Initial metrics:

- CPU usage;
- GPU usage where available;
- RAM;
- storage;
- temperatures;
- fan speeds where available;
- uptime.

Click opens configured system monitor.

## 9.5 Calendar

Initial local calendar:

- month grid;
- today;
- previous/next month;
- selected day;
- keyboard navigation.

## 9.6 Tray drawer

Complete:

- stable ordering;
- pointer activation;
- right-click menus;
- keyboard focus;
- no pinned items by default.

## 9.7 Control-centre main view

Complete:

- quick controls;
- volume;
- brightness;
- Notifications;
- Volume Mixer.

## 9.8 Basic network and Bluetooth pages

Wi-Fi:

- scan;
- connect;
- password prompt;
- disconnect;
- forget;
- hidden network;
- basic details.

Bluetooth:

- scan;
- pair;
- connect;
- disconnect;
- forget;
- pairing prompts;
- battery where available.

## Deliverables

A usable shell prototype with daily interactions working end to end.

## Acceptance criteria

- shell can replace the existing bar for a normal work session;
- bar remains stable under dynamic status changes;
- all major surfaces are usable by keyboard and pointer;
- normal network and Bluetooth states stay quiet;
- Wi-Fi and Bluetooth management does not require opening settings for ordinary tasks;
- tray applications remain accessible;
- resource and calendar popovers work;
- no optional integration failure crashes the shell;
- idle CPU and memory are measured and recorded;
- one full day of use produces no blocker-level issue.

## Prototype completion definition

The prototype is considered complete when the user can:

- switch numbered workspaces;
- toggle special workspaces;
- open Vicinae;
- review notifications;
- manage Wi-Fi and Bluetooth;
- adjust audio and brightness;
- view resource state;
- open calendar;
- access tray applications;
- use fullscreen without ordinary shell interruption.

---

# 10. Phase 7 — Adopted Component Integration

## Goal

Make Vicinae and quickshell-overview feel like first-class parts of Franken Shell without recreating them.

## 10.1 Vicinae integration

Implement:

- availability detection;
- root-search toggle;
- direct-entry menu;
- command registry mapping;
- dynamic theme generation;
- version diagnostics;
- launch failure toast.

## 10.2 Vicinae shell extension

Initial commands:

- open control centre;
- open notifications;
- toggle DND;
- toggle Night Light;
- toggle idle inhibitor;
- switch numbered workspace;
- toggle special workspace;
- open calendar;
- open resource popover;
- open power panel;
- lock session.

Use versioned shell IPC.

## 10.3 quickshell-overview integration

Initial strategy:

- keep separate process;
- pin revision;
- toggle through IPC;
- generate shared workspace config;
- generate or map theme;
- open when active workspace number is clicked;
- preserve direct workspace fallback.

## 10.4 Compatibility diagnostics

Report:

- installed version;
- expected version;
- available IPC;
- generated configuration status;
- theme sync status.

## Deliverables

- `VicinaeAdapter`;
- first-party extension;
- Vicinae theme sync;
- `OverviewAdapter`;
- overview config sync;
- compatibility diagnostics.

## Acceptance criteria

- shell has no competing launcher;
- Vicinae bar button and shortcut work;
- right-click direct entries work;
- shell extension controls shell features;
- overview opens through bar and keyboard;
- overview sees the same special workspace definitions;
- failure of either external component degrades locally;
- theme changes reach both integrations.

---

# 11. Phase 8 — Power, Calendar, and Deeper Utilities

## Goal

Complete the important secondary workflows planned immediately after the prototype.

## 11.1 auto-cpufreq panel

Implement:

- installation and daemon detection;
- active config path;
- current battery/charger profile;
- supported settings;
- validation;
- draft/edit/save/apply/revert;
- automatic versus override state;
- privileged helper;
- Polkit authorization;
- backup and rollback.

### Exit criteria

- no arbitrary privileged command execution;
- failed apply leaves previous valid config;
- unsupported settings are omitted;
- user can understand which profile is active.

---

## 11.2 Google Calendar integration

Implement provider-neutral calendar service first.

Then add:

- Google account authentication;
- secure token storage;
- calendar selection;
- event fetch;
- selected-day agenda;
- event colours;
- sync state;
- create/open event;
- error and offline state.

### Exit criteria

- month view works without network;
- event data does not block calendar opening;
- tokens are never stored in plain config;
- calendar provider can be disabled without breaking local calendar.

---

## 11.3 Notification sound rules

Implement:

- per-app match;
- per-title exact match;
- per-title regex or safe pattern;
- sound selection;
- rule ordering;
- preview;
- DND interaction;
- diagnostics for invalid rules.

Default remains silent.

---

## 11.4 Focused-window actions

Implement:

- title and metadata;
- move to workspace;
- move to special workspace;
- toggle floating;
- toggle fullscreen;
- close;
- force-kill confirmation.

## Deliverables

- power panel and helper;
- Google Calendar provider;
- sound-rule engine;
- focused-window actions.

## Acceptance criteria

- power edits are safe and reversible;
- Google Calendar failure does not affect local calendar;
- sound rules are deterministic;
- window close and force-kill are visibly distinct.

---

# 12. Phase 9 — Settings and Configuration UI

## Goal

Allow meaningful shell configuration without hand-editing files, while preserving a coherent product.

## Scope

Initial settings sections:

- General;
- Appearance;
- Bar;
- Workspaces;
- Control Centre;
- Notifications and sounds;
- Gestures;
- Integrations;
- Commands;
- Monitors;
- Accessibility;
- Diagnostics.

## Behaviour

Implement:

- typed draft state;
- validation;
- changed indicators;
- Save;
- Apply;
- Revert;
- reset field;
- reset section;
- restart-required markers;
- backup before destructive reset.

## High-value settings first

Prioritize:

- bar edge;
- autohide;
- fullscreen behaviour;
- workspace group size;
- special workspace definitions;
- system monitor command;
- notification sound rules;
- control-centre width;
- gesture bindings;
- monitor enablement;
- text scale;
- reduced motion.

## Avoid initially

- arbitrary padding;
- per-component colour overrides;
- independent animation curves;
- unrestricted layout reordering;
- raw backend implementation switches without validation.

## Deliverables

- settings surface;
- typed config editor;
- diagnostics view;
- integration health view.

## Acceptance criteria

- settings UI edits the same schema as manual configuration;
- invalid values cannot be applied;
- reset creates backup;
- external command paths are checked;
- configuration changes survive restart;
- restart-required settings are clear;
- no parallel settings database exists.

---

# 13. Phase 10 — Multi-Monitor and Gesture Hardening

## Goal

Make the shell robust on real multi-monitor and trackpad setups.

## 13.1 Multi-monitor policy

Finalize and implement:

- which monitors show bars;
- keyboard-invoked surface monitor;
- pointer-invoked surface monitor;
- notification monitor;
- OSD monitor;
- one global control centre;
- hotplug behaviour;
- per-monitor edge settings.

Recommended baseline:

- bar per configured monitor;
- pointer actions stay on pointer monitor;
- keyboard surfaces use focused-window monitor;
- one control centre globally;
- notifications on focused monitor;
- OSD on active monitor.

## 13.2 Scale and rotation

Test:

- 1.0 scale;
- fractional scale;
- mixed scale;
- portrait display;
- rotated display;
- different refresh rates;
- monitor hotplug;
- monitor sleep/wake.

## 13.3 Trackpad gestures

Implement only after confirming platform support.

Candidate defaults:

- three-finger horizontal → Hyprland workspace navigation;
- four-finger left → control centre;
- four-finger up → overview.

All gestures must:

- be configurable;
- have alternatives;
- avoid conflict;
- expose diagnostics;
- fail safely.

## 13.4 Edge boundaries

Test right-edge drag on:

- external monitor right edge;
- internal boundary between monitors;
- monitor with scrollbar-heavy applications;
- fullscreen application;
- mixed scale.

## Deliverables

- finalized monitor ownership policy;
- per-monitor settings;
- gesture integration;
- hotplug recovery;
- mixed-scale fixes.

## Acceptance criteria

- no invisible focused surface after monitor removal;
- surfaces never appear across monitor boundaries;
- edge drag triggers only on the physical outer edge intended by policy;
- fractional scaling does not blur or clip primary UI;
- rotated monitor layouts remain usable;
- overview remains stable or clearly reports limitations;
- gestures do not steal existing Hyprland actions silently.

---

# 14. Phase 11 — Visual Polish and Accessibility

## Goal

Apply the final shared visual language after interaction and layout are stable.

## Scope

## 14.1 Dynamic colour integration

Complete:

- Caelestia palette adapter;
- semantic role mapping;
- contrast validation;
- atomic theme changes;
- fallback;
- Vicinae theme;
- quickshell-overview theme.

## 14.2 Typography

Finalize:

- font family;
- type scale;
- tabular numerals;
- truncation;
- locale behaviour.

## 14.3 Geometry

Finalize:

- bar thickness;
- control-centre width;
- corner radii;
- popover sizes;
- notification width;
- hit targets.

## 14.4 Motion

Finalize:

- durations;
- easing;
- control-centre settle;
- workspace group transition;
- popup and toast motion;
- OSD motion;
- active shape changes;
- charging treatment;
- theme transition.

## 14.5 Accessibility

Audit:

- keyboard focus;
- contrast;
- non-colour cues;
- target sizes;
- text scaling;
- reduced motion;
- high contrast;
- timeout behaviour;
- screen-reader/accessibility metadata where supported.

## Deliverables

- stable theme tokens;
- component library;
- motion tokens;
- reduced-motion mode;
- accessibility fixes;
- visual regression fixtures.

## Acceptance criteria

- shell remains readable across a representative wallpaper set;
- focus is distinct from selection;
- active state does not rely only on colour;
- text scaling does not break the bar;
- reduced motion preserves meaning;
- animations never delay interaction;
- no high-frequency metric causes visible layout jitter;
- adopted components appear coherent enough without unnecessary forks.

---

# 15. Phase 12 — Packaging and Release Hardening

## Goal

Make the project installable, recoverable, maintainable, and safe to update.

## Scope

## 15.1 Startup packaging

Package and document the approved production startup topology:

- one systemd user service is the primary supervisor;
- Hyprland may start that service or its target, but must not separately launch Quickshell;
- duplicate-instance protection remains an additional guard;
- use `Restart=on-failure` with a bounded delay;
- send service lifecycle logs to the journal while retaining Quickshell structured logs and crash reports;
- document full process restart and in-process reload as different operations.

Resolve Q-115 before production Franken Shell claims notification,
tray-watcher, Polkit-agent, lock, or equivalent exclusive ownership.

## 15.2 Installation

Provide:

- dependency checks;
- Arch/Garuda packaging first;
- config installation;
- Polkit policy;
- helper installation;
- systemd units;
- uninstall path.

## 15.3 Migration

Implement:

- config schema migration;
- generated-file regeneration;
- version compatibility warnings;
- backup;
- rollback notes.

## 15.4 Release diagnostics

Provide one command/report containing:

- project version;
- Quickshell version;
- Hyprland version;
- config status;
- integration status;
- service health;
- expected overview version;
- Vicinae extension version.

## 15.5 Test automation

Automate:

- pure logic tests;
- config validation;
- formatting;
- fixture rendering where possible;
- integration smoke tests;
- package checks.

## 15.6 Documentation

Complete:

- installation;
- first run;
- configuration;
- keybindings;
- architecture;
- troubleshooting;
- contributor guide;
- release notes.

## Deliverables

- package;
- startup units;
- helper and policy;
- migrations;
- release checklist;
- complete documentation.

## Acceptance criteria

- clean install on supported system;
- clean uninstall;
- update preserves user config;
- failed update has rollback instructions;
- startup failure is diagnosable;
- no privileged helper remains after uninstall;
- known compatibility matrix is documented.

---

# 16. Suggested Milestones

## Milestone A — Shell appears

Includes Phases 0–2.

The shell:

- starts;
- shows a left bar;
- renders fixture components;
- handles workspace groups;
- opens placeholder popovers.

This milestone validates repository, theme, config, monitors, and basic surfaces.

---

## Milestone B — Drawer works

Includes Phase 3.

The shell:

- opens the right-edge control centre;
- supports direct drag;
- supports keyboard navigation;
- closes predictably;
- manages focus correctly.

This milestone validates the highest-risk custom interaction.

---

## Milestone C — Real desktop state

Includes Phase 4.

The shell:

- tracks Hyprland;
- controls audio;
- reads battery;
- reads network;
- reads Bluetooth;
- reads tray items;
- reads brightness.

This milestone validates service architecture.

---

## Milestone D — Notification-complete prototype

Includes Phase 5.

The shell:

- receives notifications;
- groups history;
- supports DND;
- shows toasts and OSDs;
- suppresses ordinary fullscreen interruption.

This milestone validates attention management.

---

## Milestone E — Daily-use prototype

Includes Phase 6.

The shell can replace the current bar and control centre for ordinary use.

This is the first major user-facing milestone.

---

## Milestone F — Integrated ecosystem

Includes Phase 7.

Vicinae and quickshell-overview behave as first-class shell components.

---

## Milestone G — Feature-complete beta

Includes Phases 8–10.

Power, calendar, settings, multi-monitor, and gestures are usable.

---

## Milestone H — Release candidate

Includes Phases 11–12.

Visual system, accessibility, packaging, migration, and documentation are complete.

---

# 17. Task Granularity for Codex

Codex tasks should remain narrowly scoped.

Good task:

> Implement a fixture-driven workspace pager that shows workspaces in groups of five, supports active-state highlighting, click switching through an injected controller, and scroll navigation. Do not connect Hyprland yet.

Poor task:

> Build the shell bar.

Each task should include:

- files allowed to change;
- behaviour;
- non-goals;
- interfaces;
- acceptance checks;
- relevant docs;
- expected test or manual verification.

---

# 18. Recommended First Codex Tasks

After the documentation set is complete, begin with tasks in this order.

## Task 1 — Bootstrap runnable shell

Create:

- root QML;
- fallback theme singleton;
- basic log utility;
- one visible test surface;
- development launch command.

## Task 2 — Configuration loader

Create:

- built-in defaults;
- user config lookup;
- parser;
- validation result;
- error logging;
- last-valid retention.

Use a deliberately small schema.

## Task 3 — Monitor registry

Expose:

- screens;
- geometry;
- scale;
- selected/focused monitor placeholder;
- monitor hotplug log.

## Task 4 — Surface coordinator

Support:

- one active popover;
- control-centre open state;
- close all;
- monitor ownership;
- focus restoration placeholder.

## Task 5 — Fixture bar

Implement:

- left edge;
- semantic zones;
- workspace pager fixture;
- status fixture cells;
- fixed context region;
- end-anchored Vicinae fixture.

## Task 6 — Fixture popover host

Open one generic anchored popover from bar items.

## Task 7 — Control-centre drag prototype

Use placeholder content only.

Do not add Wi-Fi, Bluetooth, or notifications yet.

## Task 8 — Hyprland adapter

Replace workspace fixture state only.

This sequence prevents system-service work from obscuring fundamental surface problems.

---

# 19. Definition of Done for an Individual Feature

A feature is done for its current phase when:

## Behaviour

- primary workflow works;
- keyboard and pointer paths work;
- dismissal works;
- error state exists;
- capability absence is handled.

## Architecture

- service access goes through adapter;
- state has one owner;
- no arbitrary process invocation in delegates;
- monitor ownership is explicit;
- feature follows surface coordinator rules.

## Visual

- semantic tokens used;
- active, focus, disabled, warning states exist;
- changing values do not shift layout;
- text scaling is tested.

## Performance

- no UI-thread blocking;
- hidden timers stop or slow down;
- event bursts are coalesced;
- service polling is bounded.

## Safety

- no secrets logged;
- destructive actions have appropriate friction;
- privileged operations use the helper boundary.

## Documentation

- relevant feature spec updated;
- decision log updated;
- open issues recorded;
- manual test steps included.

---

# 20. Deferred Features and Anti-Scope-Creep Rules

The following should not enter the first working prototype unless required by a blocker:

- custom application launcher;
- persistent desktop widgets;
- weather in the bar;
- full Google Calendar integration;
- lock screen redesign;
- arbitrary shell theming editor;
- full system monitor;
- advanced enterprise network configuration;
- persistent notification database;
- custom process manager;
- media lyrics or queue;
- elaborate desktop animations;
- broad plugin system;
- all-distribution packaging;
- touch-screen-first layout;
- every possible sensor backend.

Any proposal to add one must answer:

1. What prototype blocker does it solve?
2. Why can it not wait?
3. Which scheduled task is displaced?
4. What is the maintenance cost?

---

# 21. Risk Register by Phase

## Early architecture risks

- Quickshell API changes;
- focus and outside-click behaviour;
- monitor mapping;
- duplicate D-Bus ownership after reload.

Address in Phases 0–3.

## System integration risks

- backend capability gaps;
- asynchronous task handling;
- Bluetooth pairing;
- tray menu compatibility;
- sensor portability.

Address in Phase 4.

## Attention-management risks

- notification storms;
- incorrect critical bypass;
- fullscreen interruption;
- duplicate notification server ownership.

Address in Phase 5.

## Adoption risks

- Vicinae command changes;
- overview IPC/version mismatch;
- theme sync limitations.

Address in Phase 7.

## Privilege and account risks

- auto-cpufreq writes;
- Polkit;
- Google token storage.

Address in Phase 8.

## Environment risks

- mixed DPI;
- rotated monitors;
- gesture conflicts;
- monitor hotplug.

Address in Phase 10.

---

# 22. Progress Tracking

Maintain a small project-state file:

```text
docs/project-state.md
```

Suggested contents:

```markdown
# Current phase

Phase 2 — Bar Foundation

# Current milestone

Milestone A — Shell appears

# Working features

- Config loader
- Fallback theme
- Monitor registry

# Current task

Fixture workspace pager

# Known blockers

- Focus restoration API not finalized

# Decisions made this week

- Use one PopoverHost per monitor

# Next three tasks

1. Complete workspace scroll
2. Add fixed context region
3. Add generic popover
```

This file should remain concise and current.

Do not use it as a replacement for:

- architecture docs;
- decision log;
- issue tracker;
- detailed feature specs.

---

# 23. Phase-Gate Review Questions

Before moving to the next phase, answer:

1. Did the phase validate its central assumption?
2. Are remaining defects documented?
3. Did any feature bypass the agreed architecture?
4. Is there duplicate state?
5. Are missing-service states visible?
6. Are keyboard and pointer paths both usable?
7. Are focus and dismissal reliable?
8. Are logs useful?
9. Is performance measured where relevant?
10. Did scope expand beyond the phase?
11. Were new decisions written down?
12. Is the next phase still correctly ordered?

A phase should not be declared complete solely because the UI looks finished.

---

# 24. Initial Success Metrics

The project should begin measuring these during prototype development.

## Startup

- time until bar visible;
- time until core services ready;
- degraded startup behaviour.

## Idle

- CPU usage;
- memory usage;
- wakeups;
- service polling frequency.

## Interaction

- control-centre keyboard-open latency;
- edge-drag frame pacing;
- popover-open latency;
- workspace-switch response;
- notification-popup latency.

## Reliability

- successful reload count;
- adapter reconnect success;
- monitor-hotplug recovery;
- integration failure containment.

Exact targets should be set after a baseline build exists.

---

# 25. Final Release Readiness Checklist

A first stable release should not be tagged until:

- working prototype features are complete;
- Vicinae and overview integrations are tested;
- auto-cpufreq helper has a security review;
- configuration migration works;
- multi-monitor policy is documented;
- mixed scaling is tested;
- fullscreen rules are reliable;
- DND and critical bypass are tested;
- notification contents remain private in logs;
- accessibility audit is complete;
- reduced motion works;
- installation and uninstall are documented;
- known compatibility versions are published;
- recovery from broken config is documented;
- release diagnostics can be generated;
- at least one sustained daily-use test period has completed without a blocker.

---

# 26. Immediate Next Step After Documentation

Once the remaining design documents and feature specifications are present, begin **Phase 0** with a single Codex task:

> Create the minimal runnable Franken Shell Quickshell project with a root `shell.qml`, a fallback semantic theme singleton, structured startup logging, version constants, and a simple noninteractive test surface. Run it manually from the repository path in a non-owning mode alongside the existing Caelestia shell. It must not claim notification, tray-watcher, Polkit-agent, session-lock, or equivalent exclusive ownership. Do not implement the real bar, system services, or external integrations. Include a README section with exact development start, in-process reload, full restart, stop, and log commands.

That task establishes the first executable baseline without allowing implementation to jump ahead of the architecture.
