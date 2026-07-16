# Franken Shell — Architecture

> **Status:** Working architecture baseline  
> **Tested Phase 0 compositor:** Hyprland 0.55.4 using Lua configuration
> **Primary UI runtime:** Quickshell / QML  
> **Pinned Phase 0 runtime:** Quickshell 0.3.0 at `4df562dfb2475a9057f0f33a8db75808efad8670`, package `quickshell-git 0.3.0.r15.g4df562d-1`, Qt 6.11.1
> **Related documents:** `product-vision.md`, `design-principles.md`, `feature-map.md`, `interaction-language.md`, `visual-language.md`

This document defines the proposed system architecture for Franken Shell.

It is intended to give Codex and human contributors enough structure to begin implementation without forcing every feature into a premature low-level design.

The architecture prioritizes:

- clear ownership;
- one source of truth;
- replaceable service adapters;
- graceful degradation;
- explicit surface coordination;
- isolation of external integrations;
- responsive QML;
- safe privileged operations;
- compatibility with a fast-moving pre-1.0 Quickshell API.

---

# 1. Architectural Goals

## 1.1 One coherent shell, not one monolithic file

Franken Shell should run as a coherent product, but its implementation must be divided into:

- shell windows and surface hosts;
- feature modules;
- shared UI components;
- state models;
- system-service adapters;
- integration adapters;
- configuration;
- diagnostics.

No major feature should depend directly on another feature's internal QML objects.

---

## 1.2 QML owns presentation; adapters own system interaction

QML components should primarily:

- render state;
- request actions;
- manage local interaction state;
- animate presentation.

System interaction should be centralized behind service adapters.

Examples:

- the bar does not run `hyprctl` directly;
- a Wi-Fi delegate does not spawn `nmcli` itself;
- a battery button does not edit auto-cpufreq configuration directly;
- the Vicinae button does not embed hard-coded deeplink strings;
- notification cards do not own notification-retention policy.

---

## 1.3 Prefer Quickshell-native services, hide them behind project adapters

Current Quickshell releases expose modules for several required domains, including Hyprland, notifications, networking, Bluetooth, PipeWire, system tray, UPower, Polkit, and Wayland services.

These should be preferred where they meet project needs, but feature code should consume Franken Shell adapters rather than importing every Quickshell service directly.

This provides:

- one normalized API;
- easier mocking;
- insulation from Quickshell changes;
- consistent error and availability states;
- fallback implementations where needed.

---

## 1.4 Single source of truth

The same concept must not be independently stored in multiple modules.

Examples:

- one workspace definition model;
- one active surface coordinator;
- one theme token model;
- one notification policy model;
- one monitor registry;
- one command registry;
- one service-health registry.

Feature modules may derive local presentation state but must not create parallel authoritative state.

---

## 1.5 Failure containment

A missing or failing optional integration must affect only its feature.

Examples:

- Vicinae failure does not stop the bar;
- quickshell-overview failure does not stop direct workspace switching;
- missing fan sensors do not stop the resource popover;
- auto-cpufreq absence does not remove battery status;
- Bluetooth absence does not break the control centre;
- dynamic-colour generation failure falls back to the last valid or built-in palette.

---

## 1.6 Version-aware integration

Both Hyprland and Quickshell are actively evolving.

The project should:

- pin known-good versions for development;
- centralize version-sensitive behaviour;
- expose compatibility checks;
- document supported version ranges;
- avoid undocumented APIs where possible;
- maintain migration notes;
- fail with diagnostics rather than undefined behaviour.

Hyprland Lua mode must be detected or assumed only after the compositor adapter verifies it.

The D-071 pin is the exact tested development baseline. It is not the minimum
supported version; support ranges require the compatibility testing tracked by
Q-113.

---

# 2. Runtime Topology

## 2.1 Main shell process

The main Franken Shell should normally run as one Quickshell instance.

It owns:

- bars;
- control centres;
- bar popovers;
- notification popups and history;
- toasts;
- OSDs;
- shared services;
- settings state;
- IPC;
- diagnostics.

Conceptually:

```text
quickshell: franken-shell
│
├── Core services and state
├── Per-monitor shell surfaces
├── Global transient surfaces
├── Feature modules
└── Shell IPC
```

A single main instance avoids duplicated service subscriptions and allows surfaces to coordinate reliably.

### Phase 0 parallel-development topology

During early development, the existing Caelestia shell remains the working
shell and retains notifications, tray watching, lock/session behaviour, and
other exclusive responsibilities.

The Franken Shell development instance is launched manually from its repository
path in a non-owning mode. It must not register a notification server, tray
watcher, Polkit agent, session lock, or equivalent exclusive session owner.
This is a temporary development topology, not the production ownership model.

---

## 2.2 Vicinae process

Vicinae remains an independent external application.

Franken Shell integrates with it through:

- a small command/deeplink adapter;
- availability detection;
- a first-party Vicinae extension;
- generated theme configuration;
- optional status reporting.

The shell must not depend on Vicinae's internal window tree or source layout.

---

## 2.3 quickshell-overview process

### Prototype topology

Run quickshell-overview as a separate Quickshell configuration or process.

Benefits:

- fastest path to a working overview;
- failures are isolated;
- upstream updates can be evaluated independently;
- no immediate need to reconcile internal service models.

Communication uses its documented IPC entry points.

### Later topology

After the main shell is stable, choose one of two supported strategies:

1. continue running a pinned standalone overview; or
2. vendor and integrate its modules into Franken Shell.

Vendoring is justified only if needed for:

- shared settings;
- deeper visual integration;
- startup coordination;
- multi-monitor fixes;
- maintenance patches;
- reduced duplicated service work.

Do not merge it merely to make the repository look self-contained.

---

## 2.4 Privileged helper

A narrowly scoped helper may be required for auto-cpufreq configuration or other privileged system changes.

The helper is not a general shell-command executor.

It should expose only explicit operations such as:

```text
readAutoCpuFreqConfig()
validateAutoCpuFreqConfig(candidate)
writeAutoCpuFreqConfig(candidate)
applyAutoCpuFreqConfig()
restoreAutoCpuFreqBackup()
```

Authorization should use an appropriate system mechanism such as Polkit.

The helper must:

- validate all input;
- use atomic writes;
- reject arbitrary paths;
- reject arbitrary commands;
- provide structured errors;
- preserve backups;
- be separately testable.

---

# 3. Top-Level Layering

The architecture is divided into six layers.

```text
┌─────────────────────────────────────────────────────────────┐
│  UI Surfaces                                                │
│  Bar · Control Centre · Popovers · Notifications · OSDs     │
├─────────────────────────────────────────────────────────────┤
│  Feature Controllers / View Models                          │
│  Workspaces · Audio · Network · Power · Calendar · Tray     │
├─────────────────────────────────────────────────────────────┤
│  Shared Shell State                                         │
│  Surface Coordinator · Config · Theme · Monitor Registry    │
├─────────────────────────────────────────────────────────────┤
│  Service Adapters                                           │
│  Hyprland · Network · Bluetooth · Audio · Power · Sensors   │
├─────────────────────────────────────────────────────────────┤
│  Integration Adapters                                       │
│  Vicinae · quickshell-overview · Caelestia · System Apps    │
├─────────────────────────────────────────────────────────────┤
│  Quickshell / Wayland / D-Bus / System Services             │
└─────────────────────────────────────────────────────────────┘
```

Dependencies should generally point downward.

A lower layer must not import a feature UI component.

---

# 4. Shell Root

## 4.1 Responsibilities

The shell root should construct and own:

- configuration loader;
- theme manager;
- monitor registry;
- surface coordinator;
- notification policy;
- command registry;
- diagnostics registry;
- service adapters;
- per-monitor surface instances;
- shell IPC handler.

The shell root should not contain feature-specific layout code.

---

## 4.2 Startup sequence

Recommended startup order:

1. initialize logging;
2. load built-in defaults;
3. load and validate user configuration;
4. initialize fallback theme;
5. initialize monitor registry;
6. initialize compositor adapter;
7. initialize core services;
8. create persistent bars;
9. register shell IPC;
10. initialize notification server;
11. initialize optional integrations;
12. apply generated dynamic theme when available;
13. report readiness.

A delayed optional service must not block bar creation.

---

## 4.3 Readiness states

Expose startup phases for diagnostics:

```text
Bootstrapping
ConfigLoaded
CoreServicesReady
SurfacesReady
OptionalIntegrationsReady
Degraded
Failed
```

`Degraded` means the shell is usable but one or more optional capabilities are unavailable.

---

# 5. Proposed Repository Layout

```text
franken-shell/
├── shell.qml
├── qmldir
├── README.md
├── LICENSE
│
├── docs/
│   ├── product-vision.md
│   ├── design-principles.md
│   ├── feature-map.md
│   ├── interaction-language.md
│   ├── visual-language.md
│   ├── architecture.md
│   ├── configuration-model.md
│   ├── implementation-phases.md
│   ├── decisions.md
│   ├── open-questions.md
│   └── features/
│
├── config/
│   ├── defaults.json
│   ├── schema.json
│   ├── migrations/
│   └── examples/
│
├── core/
│   ├── ShellState.qml
│   ├── SurfaceCoordinator.qml
│   ├── MonitorRegistry.qml
│   ├── CommandRegistry.qml
│   ├── CapabilityRegistry.qml
│   ├── Diagnostics.qml
│   ├── ErrorModel.qml
│   └── Logging.qml
│
├── theme/
│   ├── Theme.qml
│   ├── ThemeManager.qml
│   ├── ColorRoles.qml
│   ├── Typography.qml
│   ├── Metrics.qml
│   ├── Motion.qml
│   └── fallback/
│
├── services/
│   ├── hyprland/
│   │   ├── HyprlandService.qml
│   │   ├── WorkspaceModel.qml
│   │   ├── WindowModel.qml
│   │   └── HyprlandCommands.qml
│   ├── notifications/
│   │   ├── NotificationService.qml
│   │   ├── NotificationPolicy.qml
│   │   └── NotificationHistory.qml
│   ├── network/
│   │   ├── NetworkService.qml
│   │   └── ThroughputService.qml
│   ├── bluetooth/
│   │   └── BluetoothService.qml
│   ├── audio/
│   │   └── AudioService.qml
│   ├── power/
│   │   ├── BatteryService.qml
│   │   └── AutoCpuFreqService.qml
│   ├── resources/
│   │   ├── ResourceService.qml
│   │   └── SensorService.qml
│   ├── brightness/
│   │   └── BrightnessService.qml
│   ├── tray/
│   │   └── TrayService.qml
│   ├── calendar/
│   │   └── CalendarService.qml
│   └── session/
│       └── SessionService.qml
│
├── integrations/
│   ├── caelestia/
│   │   └── CaelestiaThemeAdapter.qml
│   ├── vicinae/
│   │   ├── VicinaeAdapter.qml
│   │   ├── VicinaeThemeWriter.qml
│   │   └── extension/
│   ├── overview/
│   │   └── OverviewAdapter.qml
│   └── applications/
│       └── ExternalApplicationLauncher.qml
│
├── surfaces/
│   ├── BarHost.qml
│   ├── ControlCenterHost.qml
│   ├── PopoverHost.qml
│   ├── NotificationPopupHost.qml
│   ├── ToastHost.qml
│   ├── OsdHost.qml
│   ├── ScrimHost.qml
│   └── SessionHost.qml
│
├── features/
│   ├── bar/
│   ├── workspaces/
│   ├── controlcenter/
│   ├── notifications/
│   ├── audio/
│   ├── network/
│   ├── bluetooth/
│   ├── resources/
│   ├── power/
│   ├── calendar/
│   ├── tray/
│   ├── osd/
│   └── session/
│
├── components/
│   ├── controls/
│   ├── layout/
│   ├── surfaces/
│   ├── typography/
│   ├── icons/
│   ├── feedback/
│   └── accessibility/
│
├── ipc/
│   ├── ShellIpc.qml
│   └── contracts.md
│
├── helpers/
│   ├── auto-cpufreq-helper/
│   └── scripts/
│
├── tests/
│   ├── unit/
│   ├── component/
│   ├── integration/
│   ├── fixtures/
│   └── manual/
│
└── packaging/
    ├── systemd/
    ├── polkit/
    ├── arch/
    └── install/
```

This tree is a target shape, not a requirement to create empty files immediately.

Create directories only when their first real owner exists.

---

# 6. Core State Objects

## 6.1 `ShellState`

A small global read-only summary of shell state.

Possible properties:

```text
ready
degraded
activeMonitor
focusedWindow
fullscreenActive
doNotDisturb
idleInhibited
currentTheme
activeMajorSurface
```

`ShellState` should aggregate existing models, not become a dumping ground for every feature property.

---

## 6.2 `SurfaceCoordinator`

The authoritative owner of transient surface visibility.

It decides:

- which popover is open;
- whether the control centre is open;
- which monitor owns a surface;
- whether a scrim is required;
- what closes when another surface opens;
- focus restoration;
- nested page stack;
- fullscreen suppression;
- outside-click dismissal.

Suggested conceptual API:

```text
openControlCenter(monitor, page?)
closeControlCenter()
toggleControlCenter(monitor)

openPopover(kind, anchor, monitor, payload?)
closePopover()
closeAllTransientSurfaces()

openSessionSurface(monitor)
openCriticalPrompt(payload)

requestFocusRestore()
```

No feature should independently decide that another major surface must close.

It should request opening through the coordinator.

---

## 6.3 `MonitorRegistry`

Normalizes Quickshell and Hyprland monitor information.

Responsibilities:

- enumerate connected monitors;
- map Quickshell screens to Hyprland monitors;
- track focused-window monitor;
- track pointer monitor where available;
- store per-monitor scale, rotation, geometry, and configured bar edge;
- choose fallback monitor;
- react to hotplug;
- expose monitor ownership decisions.

Suggested model:

```text
MonitorModel {
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
}
```

Do not pass raw monitor JSON throughout the UI.

---

## 6.4 `CommandRegistry`

One registry for commands launched by the shell.

Examples:

```text
vicinae.root
vicinae.clipboard
vicinae.files
vicinae.windows
overview.toggle
systemMonitor.open
settings.open
session.lock
session.logout
session.suspend
session.reboot
session.shutdown
```

Benefits:

- no duplicated command strings;
- availability checks;
- configurable external applications;
- consistent logging;
- safe argument arrays;
- testable invocation.

Commands must be represented as argument arrays, not shell-concatenated strings, whenever possible.

---

## 6.5 `CapabilityRegistry`

Exposes actual system and integration capabilities.

Examples:

```text
hasBattery
hasBrightness
hasBluetoothAdapter
hasWifiDevice
hasAutoCpuFreq
hasVicinae
hasOverview
hasCpuTemperature
hasGpuTemperature
hasCpuFan
hasGpuFan
hasSystemTray
hasPolkitAgent
```

UI should bind to capabilities instead of guessing from platform identity.

---

## 6.6 `Diagnostics`

Central service-health and error registry.

Each adapter reports:

```text
name
availability
state
lastError
lastSuccess
version
backend
recoverable
repairHint
```

Diagnostics should be accessible through:

- shell IPC;
- logs;
- later settings/diagnostics UI.

---

# 7. Configuration Architecture

A dedicated document will define the full schema. Architecturally, configuration should have four layers.

```text
Built-in defaults
        ↓
System/package defaults
        ↓
User configuration
        ↓
Runtime/session overrides
```

## 7.1 Built-in defaults

Always valid and bundled with the shell.

Used when no external file exists.

---

## 7.2 User configuration

Stored under the XDG configuration directory.

Recommended conceptual location:

```text
$XDG_CONFIG_HOME/franken-shell/config.json
```

The final format may be JSON, JSONC, TOML, or a structured QML-readable format, but it must support:

- schema validation;
- version field;
- migrations;
- useful errors;
- atomic writes;
- preservation of unknown future fields where practical.

---

## 7.3 Runtime overrides

Temporary session state such as:

- current DND state;
- idle inhibitor;
- temporarily selected page;
- temporary power override;
- per-session layout measurements.

Runtime overrides should not silently rewrite persistent settings.

---

## 7.4 Configuration ownership

One `ConfigService` should:

- load;
- validate;
- normalize;
- expose typed sections;
- watch for changes;
- reject invalid reloads;
- retain the last valid configuration;
- emit structured change events;
- write settings atomically.

Feature code should not parse configuration files independently.

---

# 8. Theme Architecture

## 8.1 `ThemeManager`

The theme manager receives a raw or generated palette and produces validated semantic roles.

Data flow:

```text
Wallpaper
   ↓
Caelestia colour source
   ↓
CaelestiaThemeAdapter
   ↓
ThemeManager validation and role mapping
   ↓
Theme singleton
   ├── Franken Shell QML
   ├── Vicinae theme writer
   └── quickshell-overview theme adapter
```

---

## 8.2 Atomic theme activation

A new theme should become active only when:

- required roles exist;
- contrast validation passes;
- generated output is complete;
- external theme files can be written safely.

If generation fails:

1. keep the current valid theme;
2. report degraded theme service;
3. use built-in fallback only when no valid theme has ever loaded.

---

## 8.3 Token ownership

`Theme.qml` should expose semantic tokens only.

Feature-specific token mapping can live beside features or under `Theme.components`, but raw wallpaper colours should not be referenced in feature delegates.

---

# 9. Hyprland Adapter

## 9.1 Responsibilities

The Hyprland adapter owns:

- focused monitor;
- active workspace;
- numbered workspaces;
- special workspaces;
- focused window;
- fullscreen state;
- urgent state;
- workspace switching;
- special workspace toggling;
- window actions;
- monitor mapping;
- event normalization;
- dispatcher syntax compatibility.

---

## 9.2 Native Quickshell integration first

Use Quickshell's Hyprland module for state and dispatch where it provides the required information.

Only use raw sockets or external commands for gaps that are:

- documented;
- measured;
- isolated inside the adapter.

Do not mix three different Hyprland access methods across feature files.

---

## 9.3 Lua mode

The supported compositor target is Hyprland 0.55+ using Lua configuration.

The adapter should verify Lua mode where the Quickshell API exposes that state.

Version-sensitive dispatcher formatting belongs inside `HyprlandCommands`, not in the workspace pager or window menu.

---

## 9.4 Workspace definitions

The configuration model defines semantic workspaces.

Example:

```text
numbered:
  groupSize: 5
  range: 1–10

special:
  - id: music
    hyprlandName: music
    icon: music
    shortcutHint: Super+M
  - id: movies
    hyprlandName: movies
    icon: movie
    shortcutHint: Super+A
```

The adapter converts semantic identifiers into Hyprland operations.

---

## 9.5 Fullscreen state

The adapter should expose fullscreen at the workspace/monitor level so that:

- bar visibility;
- notification popup suppression;
- edge-drag suppression;
- OSD exceptions;

use one normalized state.

Maximized state must not be treated as fullscreen.

---

# 10. Surface Architecture

## 10.1 Per-monitor surface set

Each eligible monitor may own:

```text
BarHost
ControlCenterHost
EdgeActivationHost
PopoverHost
ScrimHost
```

Global or selected-monitor surfaces include:

```text
NotificationPopupHost
ToastHost
OsdHost
SessionHost
CriticalPromptHost
```

Whether notifications and OSDs become per-monitor instances is deferred to the multi-monitor specification.

---

## 10.2 Bar host

Candidate Quickshell primitive:

- `PanelWindow`.

Responsibilities:

- reserve compositor space when visible;
- adapt anchors to configured edge;
- hide in fullscreen;
- support optional autohide;
- host orientation-aware bar layout;
- expose anchor geometry for popovers.

The bar should not own service models directly.

It binds to feature controllers.

---

## 10.3 Control-centre host

Candidate Quickshell primitive:

- `PanelWindow`, `PopupWindow`, or another layer-shell window selected after prototype testing.

Requirements:

- attached to right edge;
- does not reserve permanent workspace area;
- supports direct pointer-driven reveal;
- can receive keyboard focus;
- can own a scrim;
- supports one instance per selected monitor;
- closes predictably;
- nests internal pages without new top-level windows.

The exact Quickshell window type should be chosen experimentally based on:

- layer-shell behaviour;
- focus;
- animation;
- exclusive-zone interaction;
- outside-click handling;
- mixed-monitor reliability.

---

## 10.4 Popover host

Use one popover host per bar/monitor rather than one unmanaged top-level window per bar item.

The host receives:

```text
kind
anchorRect
edge
contentComponent
payload
preferredSize
dismissPolicy
```

Benefits:

- one focus and dismissal path;
- consistent placement;
- no overlapping bar popovers;
- common animation;
- common scrim policy;
- easier edge adaptation.

Small menus that require native D-Bus menu semantics may use specialized menu types.

---

## 10.5 Notification popup host

Responsibilities:

- popup queue;
- coalescing;
- application grouping;
- timeout;
- hover/focus pause;
- monitor placement;
- fullscreen/DND policy;
- animation;
- action invocation.

It reads from `NotificationService` and `NotificationPolicy`.

It does not own notification history persistence.

---

## 10.6 Toast host

Owns a small keyed queue.

Toasts should be keyed by category:

```text
network
bluetooth
nightLight
idleInhibitor
audioOutput
power
generic
```

A new toast with the same category replaces or updates the existing one.

---

## 10.7 OSD host

Owns one OSD per category.

Initial categories:

```text
volume
brightness
```

The host accepts value updates and controls timeout.

It must not create a new window or delegate for every key repeat.

---

## 10.8 Lazy creation

Use lazy loading for:

- control-centre detail pages;
- calendar;
- resource popover;
- volume mixer;
- Wi-Fi and Bluetooth lists;
- settings;
- session surface.

Persistent bar delegates and service state remain lightweight.

---

# 11. Feature Controller Pattern

Each nontrivial feature should expose a controller or view model between services and QML views.

Example:

```text
AudioService
    ↓
AudioController
    ├── currentOutputIcon
    ├── currentOutputName
    ├── volume
    ├── muted
    ├── outputDevices
    ├── applicationStreams
    └── actions
        ├── setVolume()
        ├── toggleMute()
        └── selectOutput()
```

The controller may:

- combine multiple service objects;
- expose presentation-ready data;
- enforce feature policy;
- request toasts/OSDs;
- map errors.

It should not contain visual geometry or animation state.

---

# 12. Notification Architecture

## 12.1 `NotificationService`

Owns the Quickshell notification server integration.

Responsibilities:

- receive notifications;
- retain tracked entries;
- normalize app identity;
- expose actions;
- close/dismiss;
- update progress;
- record timestamps;
- produce stable internal IDs.

---

## 12.2 `NotificationPolicy`

Decides:

- popup or history only;
- DND suppression;
- fullscreen suppression;
- critical bypass;
- timeout;
- sound rule;
- grouping key;
- burst coalescing;
- persistence.

Applications' urgency hints are inputs, not unquestioned authority.

---

## 12.3 `NotificationHistory`

Owns current-session history initially.

Near-term persistence should be considered only after defining:

- retention duration;
- privacy;
- maximum size;
- serialization;
- restart behaviour.

Do not persist notification bodies by default before a privacy decision is documented.

---

## 12.4 Sound rules

Future rule model:

```text
rule:
  appId?
  titlePattern?
  urgency?
  sound?
  volume?
  bypassDnd?
```

Matching should be deterministic and inspectable.

Avoid arbitrary executable commands as notification sounds.

---

# 13. Network Architecture

## 13.1 `NetworkService`

Use Quickshell's networking integration where sufficient.

Expose normalized models for:

- connectivity;
- devices;
- Wi-Fi state;
- Ethernet state;
- visible networks;
- saved networks;
- active connection;
- connection progress;
- errors.

Feature UI must not depend on backend-specific enum names.

---

## 13.2 Connection operations

Operations should return observable task objects or explicit state.

Example:

```text
connect(network, credentials)
→ NetworkTask {
    state
    progressText
    error
    canCancel
}
```

This prevents the UI from guessing whether an asynchronous request is still running.

---

## 13.3 Secrets

Wi-Fi credentials:

- must not be logged;
- must not be stored in shell settings;
- should be passed directly to the selected network backend;
- should use secret-agent integration where supported;
- should be cleared from temporary QML state after use.

---

## 13.4 Throughput service

A dedicated lightweight service reads interface counters and calculates:

- download bytes per second;
- upload bytes per second;
- smoothed values;
- active-interface aggregate.

It exposes both raw and formatted values.

Formatting belongs in a formatter/controller, not the low-level counter reader.

---

# 14. Bluetooth Architecture

## 14.1 `BluetoothService`

Use Quickshell's Bluetooth module where sufficient.

Expose:

- adapters;
- powered state;
- scanning state;
- connected devices;
- paired devices;
- available devices;
- device battery if known;
- pair/connect/disconnect/forget actions;
- pairing requests;
- errors.

---

## 14.2 Pairing state machine

Pairing should have explicit states:

```text
Idle
Pairing
AwaitingConfirmation
AwaitingCode
Connecting
Connected
Failed
Cancelled
```

Pairing prompts may be critical interaction surfaces and should not disappear due to an outside click.

---

# 15. Audio Architecture

## 15.1 `AudioService`

Use Quickshell's PipeWire support where possible.

Expose normalized:

- default output;
- default input;
- volume;
- mute;
- output devices;
- input devices;
- application streams;
- stream routing if supported.

---

## 15.2 Output icon mapping

A controller maps device metadata to semantic icons:

```text
speaker
wiredHeadphones
bluetoothHeadphones
headset
hdmi
muted
unknown
```

Do not infer Bluetooth state in the bar independently from the audio service.

---

## 15.3 OSD coupling

Audio actions publish value changes to `OsdService`.

The audio service itself should not instantiate OSD UI.

---

# 16. Power Architecture

## 16.1 `BatteryService`

Use UPower or the Quickshell UPower module where sufficient.

Expose:

- percentage;
- charging state;
- time remaining where credible;
- power source;
- low/critical thresholds;
- battery availability.

Threshold policy belongs in configuration or a power controller.

---

## 16.2 `AutoCpuFreqService`

Responsibilities:

- detect installation and daemon state;
- read current statistics;
- read user/system configuration through approved paths;
- validate editable settings;
- call privileged helper for protected writes;
- apply;
- revert;
- expose supported fields.

The UI should never assume every configuration option exists on every machine.

---

## 16.3 Configuration ownership

Do not silently create a second auto-cpufreq configuration with conflicting priority.

The service must report:

- active config path;
- detected config source;
- values inherited from defaults;
- values explicitly overridden.

---

# 17. Resource and Sensor Architecture

## 17.1 Resource service

Expose low-frequency summary values continuously:

- RAM usage;
- CPU usage;
- storage usage;
- optional basic GPU usage.

Increase polling rate only while the resource popover is open.

---

## 17.2 Sensor service

Normalize sensor discovery.

Expose zero or more sensor channels:

```text
type
device
label
value
unit
available
source
```

Examples:

- CPU package temperature;
- GPU temperature;
- fan speed;
- storage temperature.

Do not hard-code one laptop's hwmon paths.

---

## 17.3 GPU backends

GPU telemetry may require vendor-specific adapters.

Possible architecture:

```text
GpuService
├── Generic DRM/sysfs backend
├── AMD backend
├── NVIDIA backend
└── Null backend
```

Only implement the backends needed for the initial machine first, but keep the interface generic.

External commands must be rate-limited and asynchronous.

---

# 18. Tray Architecture

## 18.1 `TrayService`

Use Quickshell's system tray support.

Expose:

- items;
- status;
- category;
- icon;
- title;
- tooltip;
- activation;
- secondary activation;
- menu;
- scroll.

The tray UI should not reinterpret application-owned semantics.

---

## 18.2 Menu handling

Use Quickshell D-Bus menu facilities for tray menus.

Avoid reconstructing arbitrary application menus manually from strings.

The tray drawer owns layout and focus but delegates item actions to the tray service.

---

# 19. Calendar Architecture

## 19.1 Prototype

The initial calendar service only needs:

- current date/time;
- locale-aware month data;
- selected date;
- month navigation.

No network account or persistence is required.

---

## 19.2 Near-term Google Calendar adapter

Design a provider-neutral interface before adding Google-specific UI.

```text
CalendarProvider
├── accounts
├── calendars
├── eventsForRange(start, end)
├── createEvent(...)
├── updateEvent(...)
├── deleteEvent(...)
└── syncState
```

Then add:

```text
GoogleCalendarProvider
```

This avoids coupling the calendar panel directly to Google API response objects.

Authentication, token storage, and sync must be designed separately.

---

# 20. Vicinae Integration Architecture

## 20.1 `VicinaeAdapter`

Responsibilities:

- detect availability;
- invoke root search;
- invoke configured direct entries;
- report launch failures;
- expose version if available;
- write or switch theme through supported mechanisms.

Conceptual API:

```text
available
toggleRoot()
openClipboard()
openFiles()
openWindows()
openShellCommands()
invoke(commandId)
```

---

## 20.2 First-party extension contract

The Vicinae extension should call Franken Shell through stable shell IPC.

It should not edit shell files directly.

Extension commands may include:

```text
toggle-control-centre
open-notifications
toggle-dnd
toggle-night-light
toggle-idle-inhibitor
switch-workspace
toggle-special-workspace
open-calendar
open-power-panel
open-resource-popover
lock-session
```

The IPC contract must be versioned.

---

# 21. Overview Integration Architecture

## 21.1 `OverviewAdapter`

Responsibilities:

- detect configured overview instance;
- invoke toggle/open/close;
- pass or generate shared configuration where supported;
- report compatibility state;
- launch overview if configured;
- log failures.

---

## 21.2 Shared workspaces

A generated overview configuration may be produced from Franken Shell's workspace model.

Generation must be:

- deterministic;
- atomic;
- documented;
- one-way from the authoritative shell config.

Do not ask users to maintain the same special workspace list in two files.

---

## 21.3 Version pinning

Store a known-compatible revision or package version in project metadata.

Diagnostics should report when the detected overview differs from the tested version.

A mismatch is not automatically fatal, but it should be visible.

---

# 22. Shell IPC

## 22.1 IPC mechanism

Use Quickshell's IPC handler for shell commands where practical.

Expose a compact, stable surface rather than every internal property.

Suggested targets:

```text
shell
controlCenter
notifications
workspaces
audio
power
calendar
diagnostics
theme
```

---

## 22.2 Example commands

```text
shell.toggleSettings()
shell.reloadConfig()
shell.closeTransientSurfaces()

controlCenter.toggle()
controlCenter.openPage("network")
controlCenter.openPage("bluetooth")

notifications.open()
notifications.setDnd(true)
notifications.clearDismissible()

workspaces.switchTo(4)
workspaces.toggleSpecial("music")
workspaces.openOverview()

audio.setVolume(0.5)
audio.toggleMute()

calendar.open()

diagnostics.summary()
```

Exact function signatures must follow Quickshell IPC-supported types.

---

## 22.3 IPC versioning

Expose:

```text
shell.apiVersion
shell.projectVersion
```

The Vicinae extension and helper scripts should verify compatibility.

Breaking IPC changes require:

- version increment;
- migration note;
- temporary compatibility alias where inexpensive.

---

## 22.4 IPC security boundary

Shell IPC is not a privileged API.

It must not expose:

- arbitrary process execution;
- arbitrary file writes;
- raw secrets;
- unrestricted D-Bus calls;
- arbitrary auto-cpufreq content write.

Privileged operations remain behind the narrow helper.

---

# 23. External Process Execution

Use Quickshell process primitives or a centralized launcher adapter.

Rules:

- argument arrays, not shell-concatenated command strings;
- asynchronous execution;
- capture exit status;
- bounded output;
- timeouts where sensible;
- redact secrets;
- start detached only when the child should outlive shell reload/restart;
- no command loops in feature delegates.

Every external command must have:

- owner;
- purpose;
- error path;
- availability check.

---

# 24. Persistence

## 24.1 Persisted settings

Persist:

- explicit user settings;
- workspace definitions;
- commands;
- notification sound rules;
- appearance preferences;
- optional layout preferences.

---

## 24.2 Session state

May persist across shell reload but not necessarily reboot:

- selected control-centre tab;
- temporary page stack;
- recently selected date;
- last valid theme;
- surface geometry cache.

Use Quickshell persistent properties or a small state file where appropriate.

---

## 24.3 Do not persist by default

Do not persist without a specific design decision:

- notification bodies;
- Wi-Fi passwords;
- Bluetooth pairing codes;
- authentication data;
- clipboard contents;
- arbitrary window titles;
- transient errors.

---

# 25. Focus and Input Architecture

## 25.1 Central focus policy

The surface coordinator should track:

- invoking surface;
- invoking monitor;
- previously focused application;
- current focus owner;
- nested focus return target.

Feature modules should request focus; they should not independently guess restoration.

---

## 25.2 Hyprland focus grab

Where appropriate, use Quickshell's Hyprland focus-grab support for shell surfaces that need keyboard focus and outside-click clearing.

This should be wrapped by a project-level focus controller so the exact mechanism can change.

---

## 25.3 Edge drag input

The edge activation host owns a small invisible input region.

It emits normalized events:

```text
edgePress(monitor, position)
edgeDrag(progress, velocity)
edgeRelease(openRequested)
edgeCancel()
```

The control-centre view consumes reveal progress but does not implement pointer-intent detection itself.

---

# 26. Multi-Monitor Architecture

The final product policy remains open, but the code should support per-monitor surfaces from the beginning.

## 26.1 Recommended initial policy

- bar instances on configured monitors;
- edge drag opens control centre on the pointer monitor;
- keyboard invocation opens on focused-window monitor;
- only one control centre open globally;
- one active bar popover globally;
- notifications on focused-window monitor;
- OSD on the active/focused monitor;
- overview delegated to adopted component.

---

## 26.2 Per-monitor object creation

Use a monitor-driven instance pattern such as Quickshell variants or an equivalent model.

Each instance receives a normalized `MonitorModel`, not a raw screen object only.

---

## 26.3 Hotplug

On monitor removal:

- close surfaces owned by that monitor;
- reassign global transient state;
- preserve settings by monitor identity;
- never leave an invisible focused window;
- refresh Hyprland monitor mapping.

---

# 27. Performance Architecture

## 27.1 Event-driven first

Prefer service signals and models to polling.

Polling is acceptable for:

- throughput counters;
- resource metrics;
- sensors;
- external integration health.

---

## 27.2 Polling tiers

Suggested tiers:

### Always-visible low frequency

- RAM;
- download/upload speed;
- battery;
- basic connectivity.

### Surface-open medium frequency

- CPU/GPU usage;
- temperatures;
- fan speeds;
- process summary.

### On-demand

- network scan;
- Bluetooth scan;
- overview screencopy;
- advanced diagnostics.

Exact intervals should be tuned and configurable only when necessary.

---

## 27.3 QML thread safety

- never block the UI thread on a process;
- avoid large synchronous file reads;
- parse bounded data;
- lazy-load long lists;
- debounce configuration reload;
- coalesce notification bursts;
- reuse OSD/toast instances;
- stop hidden timers.

---

## 27.4 Resource budgets

Define measurable budgets later for:

- idle CPU;
- idle memory;
- wakeups;
- control-centre open latency;
- bar reload latency;
- notification popup latency;
- edge-drag frame pacing.

Performance regressions should be tested, not judged only by feel.

---

# 28. Error and Recovery Architecture

## 28.1 Structured error

Use a shared error shape:

```text
domain
code
summary
details
recoverable
retryAction
repairHint
timestamp
```

UI surfaces display `summary` and optionally `repairHint`.

Logs may include `details`.

---

## 28.2 Service lifecycle

Each adapter should support:

```text
Unavailable
Starting
Ready
Degraded
Failed
Reconnecting
Stopped
```

Transient D-Bus or compositor disconnects should trigger bounded reconnection.

Avoid infinite rapid restart loops.

---

## 28.3 Last-known-good state

Use last-known-good state when safe:

- theme;
- configuration;
- static device identity;
- workspace definitions.

Do not use stale state for dangerous operations such as:

- whether a device is still connected;
- whether a privileged config was applied;
- whether a window still exists.

---

# 29. Security and Privacy

## 29.1 Least privilege

The main shell should run unprivileged.

Only narrow operations should request authorization.

---

## 29.2 Secret handling

Never log:

- Wi-Fi passwords;
- authentication tokens;
- pairing codes;
- notification contents by default;
- calendar access tokens;
- clipboard contents.

---

## 29.3 Notification privacy

Before persistent notification history is implemented, define:

- retention;
- storage path;
- encryption expectations;
- exclusion rules;
- private-app rules;
- clear-history behaviour.

Initial prototype history should remain in memory.

---

## 29.4 External content

Notification text, device names, network names, tray tooltips, and calendar titles are untrusted content.

UI must:

- escape markup unless explicitly supported;
- bound text length;
- avoid command interpolation;
- avoid using external text as file paths;
- handle malformed Unicode safely.

---

# 30. Testing Strategy

## 30.1 Unit tests

Test pure logic:

- workspace group calculation;
- speed formatting;
- notification policy;
- DND bypass;
- command construction;
- config validation;
- palette role mapping;
- monitor selection;
- capability logic;
- auto-cpufreq validation.

---

## 30.2 Component tests

Test QML components with fixture models:

- active workspace;
- bar orientation;
- long device names;
- critical battery;
- notification grouping;
- focus states;
- reduced motion;
- light/dark themes;
- missing sensor rows.

---

## 30.3 Integration tests

Test adapters against real or mocked services:

- Hyprland events;
- NetworkManager;
- BlueZ;
- PipeWire;
- UPower;
- system tray;
- notification D-Bus;
- Vicinae command invocation;
- overview IPC;
- Polkit helper.

---

## 30.4 Manual test matrix

At minimum:

- left/right/top/bottom bar;
- maximized versus fullscreen;
- autohide;
- one and multiple monitors;
- fractional scaling;
- rotated monitor;
- Wi-Fi disconnected/limited/connected;
- no Bluetooth adapter;
- multiple audio outputs;
- wired and Bluetooth headphones;
- no battery;
- missing sensors;
- rapid notifications;
- DND;
- fullscreen notification suppression;
- control-centre drag cancel/open/close;
- shell reload while surfaces are open;
- optional integration crash.

---

## 30.5 Snapshot and visual regression

Once visual tokens stabilize, capture representative states:

- resting bar;
- active workspace;
- control centre;
- Wi-Fi page;
- Bluetooth page;
- notification group;
- critical alert;
- resource popover;
- light and dark palettes.

Do not begin visual-regression work before basic layout stabilizes.

---

# 31. Logging and Diagnostics

## 31.1 Log domains

Use named domains:

```text
core
config
theme
surfaces
hyprland
notifications
network
bluetooth
audio
power
resources
tray
vicinae
overview
security
```

---

## 31.2 Log levels

```text
debug
info
warning
error
critical
```

Default user logs should avoid excessive metric spam.

---

## 31.3 Diagnostic IPC

Provide commands such as:

```text
diagnostics.summary()
diagnostics.services()
diagnostics.version()
diagnostics.configStatus()
diagnostics.themeStatus()
```

A later diagnostic UI can consume the same models.

---

# 32. Packaging and Startup

## 32.1 Startup ownership

Production uses one systemd user service as the primary process supervisor.
Hyprland may start that service or its target, but must not also launch the
Quickshell process directly.

The service uses duplicate-instance protection as an additional guard and
`Restart=on-failure` with a bounded delay. Service lifecycle logs go to the
journal; Quickshell structured logs and crash reports remain available.

Development does not start Franken Shell through the production unit while the
working Caelestia shell is active. It uses the non-owning repository-path mode
defined in section 2.1.

---

## 32.2 Reload versus restart

Development should support Quickshell reload.

Production behaviour must distinguish:

- UI/config reload;
- full process restart;
- service adapter reconnect;
- external integration restart.

A reload must not duplicate notification servers, tray watchers, or IPC handlers.

An in-process reload reconstructs or updates the running QML instance while
preserving the Quickshell process. A full restart stops and starts the supervised
process. Commands and diagnostics must name these operations distinctly.

Notification fallback during crashes, Mako activation, and persistent SNI-host
recovery remain unresolved under Q-115.

---

## 32.3 Version metadata

Expose:

- Franken Shell version;
- git revision where available;
- Quickshell version;
- Hyprland version;
- configuration schema version;
- shell IPC version;
- overview compatibility target;
- Vicinae extension version.

---

# 33. Development Sequence Implied by Architecture

## Step 1: Skeleton

Create:

- shell root;
- config defaults and validator;
- theme fallback;
- monitor registry;
- surface coordinator;
- diagnostics;
- IPC skeleton.

No polished feature UI yet.

---

## Step 2: One monitor, one bar

Implement:

- left-edge panel;
- start/end zones;
- workspace pager fixture;
- fixed contextual region;
- dummy status items;
- fullscreen hide;
- focus-safe popover host.

Use mock data before connecting every system service.

---

## Step 3: Control-centre mechanics

Implement:

- right-edge host;
- invisible activation region;
- drag state machine;
- scrim;
- open/close;
- keyboard focus;
- internal page stack;
- placeholder content.

Validate interaction before real Wi-Fi/Bluetooth work.

---

## Step 4: Core adapters

Connect:

- Hyprland;
- notifications;
- audio;
- battery;
- network;
- Bluetooth;
- tray;
- throughput.

Each adapter gets availability and error state.

---

## Step 5: Prototype features

Build:

- real workspace pager;
- special workspace selector;
- notification list/popups;
- OSD/toasts;
- quick controls;
- sliders;
- resource summary;
- battery/calendar;
- tray drawer;
- Vicinae adapter.

---

## Step 6: Adopted integrations

Add:

- quickshell-overview IPC;
- shared overview config;
- Vicinae shell extension;
- Vicinae theme writer;
- auto-cpufreq helper.

---

## Step 7: Multi-monitor and hardening

Add:

- per-monitor surface instances;
- ownership policy;
- hotplug;
- scaling;
- service reconnection;
- performance tests;
- migration and packaging.

---

# 34. Architectural Decision Rules

When implementation presents multiple options, prefer the one that:

1. keeps system access behind an adapter;
2. avoids a second source of truth;
3. uses a documented Quickshell API;
4. keeps the UI thread non-blocking;
5. degrades locally;
6. supports mocking;
7. does not expose arbitrary command execution;
8. works with per-monitor instances;
9. keeps focus ownership explicit;
10. can survive Quickshell API migration with limited changes.

---

# 35. Known Architectural Risks

## Quickshell API churn

Mitigation:

- pin version;
- adapters;
- migration notes;
- avoid undocumented internals.

## Edge-drag reliability

Mitigation:

- prototype before feature work;
- isolate gesture state machine;
- test scrollbars and monitor boundaries;
- configurable activation width.

## Multiple D-Bus service ownership

The shell may become notification server, tray watcher, Polkit agent, or other session service.

Mitigation:

- explicit ownership;
- startup diagnostics;
- no duplicate instance after reload;
- clear failure when another service already owns the bus name.

## quickshell-overview stability

Mitigation:

- separate process initially;
- pin revision;
- fallback direct workspace control;
- targeted tests.

## auto-cpufreq privilege boundary

Mitigation:

- narrow helper;
- Polkit;
- schema validation;
- atomic writes;
- backups.

## Sensor portability

Mitigation:

- capability registry;
- backend abstraction;
- omit unsupported rows;
- no hard-coded paths in UI.

## Multi-monitor focus bugs

Mitigation:

- monitor registry;
- central surface coordinator;
- explicit origin tracking;
- early two-monitor testing.

---

# 36. Architecture Acceptance Criteria

The architectural foundation is ready for feature implementation when:

1. the shell starts with a valid fallback theme even when optional services are absent;
2. configuration loads through one validated service;
3. one bar can be created from a monitor model;
4. the surface coordinator can open and close one popover and the control centre without focus leaks;
5. the right-edge drag state machine works with placeholder content;
6. Hyprland state is available through one adapter;
7. shell IPC reports version and diagnostics;
8. optional integrations have availability states;
9. external commands use the command registry;
10. no feature component runs privileged writes or arbitrary shell commands directly;
11. a service can fail without terminating the shell;
12. mock models can render primary surfaces without a live desktop service.

---

# 37. Items Deferred to Later Documents

The following are intentionally not fully defined here:

- exact configuration schema;
- final default keybindings;
- exact QML window primitive for every surface;
- complete multi-monitor policy;
- detailed feature layouts;
- notification persistence;
- Google authentication;
- systemd unit contents;
- Polkit policy contents;
- exact helper implementation language;
- release packaging;
- final public IPC signatures.

Those decisions belong in:

- `configuration-model.md`;
- `implementation-phases.md`;
- feature specifications;
- packaging documentation;
- explicit architecture decision records.
