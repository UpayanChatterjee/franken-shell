# Franken Shell — Open Questions

> **Status:** Living design backlog  
> **Purpose:** Track unresolved product, interaction, architecture, implementation, and integration questions without silently inventing answers  
> **Related documents:** `product-vision.md`, `design-principles.md`, `feature-map.md`, `architecture.md`, `configuration-model.md`, `implementation-phases.md`, `decisions.md`

This document contains questions that are important enough to affect implementation, but not yet settled enough to become decisions.

Each item should eventually be:

- answered and moved into `decisions.md`;
- converted into a feature specification requirement;
- deferred explicitly;
- or removed if it becomes irrelevant.

Do not let Codex resolve these silently through implementation convenience.

---

# 1. Priority Labels

| Label | Meaning |
|---|---|
| **Blocker** | Must be resolved before the named implementation phase can complete. |
| **High** | Strongly affects architecture, interaction, or maintainability. |
| **Medium** | Important, but can be deferred behind a safe placeholder. |
| **Low** | Polish or preference question that should be resolved through prototyping. |
| **Research** | Requires checking current APIs, capabilities, or upstream behaviour. |
| **Prototype** | Best answered by building and testing alternatives. |

---

# 2. Questions That Block Initial Implementation

## Q-001 — Exact Quickshell baseline

**Status:** Resolved by D-071

**Resolved scope:** Exact Phase 0 development pin

The tested development baseline is Quickshell `0.3.0` at commit
`4df562dfb2475a9057f0f33a8db75808efad8670`, Arch package
`quickshell-git 0.3.0.r15.g4df562d-1`, Qt `6.11.1`, and Hyprland `0.55.4`
using Lua configuration.

The supported minimum and compatibility range were not resolved. They are
tracked by Q-113.

---

## Q-002 — Retained Caelestia service inventory

**Status:** Provisionally resolved by D-072

**Resolved scope:** Audited transitional migration inventory

The complete provisional matrix is maintained in `runtime-dependencies.md`.
It constrains Phase 0 and prevents broad legacy imports, but it does not
permanently settle every dependency.

Remaining capability and ownership research is tracked by Q-114.

---

## Q-003 — Initial source tree migration strategy

**Status:** Resolved by D-073

**Resolved scope:** Main-branch bootstrap and legacy preservation

Main receives a clean bootstrap without a physical legacy source directory.
The customized implementation remains available through Git history,
`design-baseline-v1`, and `legacy/caelestia-custom`. The live user
configuration remains untouched and runnable.

Any later extraction remains subject to the attribution, licensing, dependency,
and ownership review required by D-072 and the repository instructions.

---

## Q-004 — Configuration file format

**Priority:** Blocker  
**Needed by:** Phase 1

Should the authoritative user configuration use:

- JSON;
- JSONC;
- TOML;
- YAML;
- QML singleton properties;
- another structured format?

Evaluation criteria:

- comment support;
- reliable parser availability from Quickshell/QML;
- schema validation;
- round-trip writing by a future settings UI;
- preservation of unknown fields;
- migration support;
- human readability;
- error line/column reporting.

A format should not be selected solely because it is easiest to parse once.

---

## Q-005 — Configuration validation implementation

**Priority:** High, Research  
**Needed by:** Phase 1

How will configuration be validated?

Possible approaches:

- JSON Schema in a helper process;
- native QML/JavaScript validation;
- typed config objects with manual validation;
- small Rust/C++ helper;
- Python utility during development only.

Questions:

- Can validation run without blocking startup?
- Can it provide exact paths and useful errors?
- Can the future settings UI use the same schema?
- How are migrations tested?

---

## Q-006 — Main shell startup and supervision

**Status:** Resolved by D-074

**Resolved scope:** Development topology and production supervisor

Development uses a manually launched, repository-path, non-owning Franken
Shell alongside the normally started Caelestia shell. Production uses one
systemd user service, optionally triggered by Hyprland, with duplicate
protection, bounded `Restart=on-failure`, journal lifecycle logs, and separate
reload/restart operations.

Notification fallback, Mako activation, and persistent SNI-host recovery are
tracked by Q-115.

---

## Q-113 — Supported Quickshell range and compatibility checks

**Priority:** High, Research

**Needed by:** Packaging and compatibility claims

What minimum Quickshell version and compatibility range can Franken Shell
support after testing?

Research:

- test required modules and API behaviour across candidate revisions;
- define compatibility checks and failure diagnostics;
- identify APIs that require revisions newer than the Phase 0 pin;
- produce a small tested compatibility matrix.

The D-071 pin is not evidence of a supported minimum.

---

## Q-114 — Transitional Caelestia capability research

**Priority:** High, Research

**Needed by:** Relevant adapter or migration task

Resolve the provisional inventory items that cannot yet be classified
permanently:

- lock, PAM, and session lifecycle ownership and failure semantics;
- `M3Shapes` packaging, licence, ABI, and replacement implications;
- NetworkManager secret-agent, enterprise Wi-Fi, and captive-portal support;
- Bluetooth PIN/passkey pairing-agent behaviour;
- notification reload and restart semantics;
- tray watcher and item recovery semantics.

Results may revise the provisional matrix only through an approved decision.

---

## Q-115 — Exclusive-service crash fallback and recovery

**Priority:** High, Research

**Needed by:** Production notification/tray ownership

How should production recover exclusive session responsibilities after a crash?

Research:

- whether and when Mako may activate while systemd restarts Franken Shell;
- how notification ownership is handed back without losing or duplicating service;
- whether the persistent SNI host remains necessary;
- how tray items recover across watcher/host loss;
- what ordering and readiness checks belong in the production unit.

This does not block the non-owning Phase 0 bootstrap.

---

# 3. Bar Questions

## Q-007 — Exact bar thickness

**Priority:** Low, Prototype  
**Needed by:** Phase 2 / visual polish

Initial range is approximately `44–48` logical pixels.

Test:

- stacked 24-hour time;
- two- and three-digit values;
- RAM ring readability;
- pointer target size;
- 100%, 999M, and multi-digit workspace values;
- fractional scaling;
- top/bottom layouts.

Decision should come from real screenshots and use, not abstract preference.

---

## Q-008 — Flush versus inset bar

**Priority:** Low, Prototype

Should the bar:

- span the entire screen edge;
- be inset from the top and bottom;
- use small outer margins;
- visually merge with the screen edge?

Questions:

- Does a full-height rail feel too heavy?
- Does an inset rail create awkward maximized-window gaps?
- How does it affect edge-attached popovers?
- How should corners change on each edge?

---

## Q-009 — Battery percent sign

**Priority:** Low, Prototype

Should resting battery display be:

- `87`;
- `87%`?

Criteria:

- ambiguity;
- compactness;
- visual balance beside network speed and RAM;
- accessibility;
- horizontal versus vertical bar layout.

---

## Q-010 — Charging treatment

**Priority:** Low, Prototype

Which charging treatment best fits “quietly visible”?

Candidates:

- accent foreground;
- subtle underline sweep;
- periodic one-pass shimmer;
- small bolt appearing briefly on state change;
- tonal fill;
- no animation, only accent and tooltip.

Requirements:

- no flashing;
- reduced-motion fallback;
- does not reduce number readability;
- visible without relying on colour alone.

---

## Q-011 — Date/time vertical arrangement

**Priority:** Low, Prototype

Possible arrangements:

```text
21
34

16
JUL
```

or:

```text
21
34
16
```

or another compact layout.

Questions:

- Should weekday appear?
- Is month text necessary?
- How should top/bottom bar format differ?
- Should date be shown every day or only on hover in very narrow modes?

---

## Q-012 — Network throughput units

**Priority:** Medium

Should default throughput use:

- bytes per second;
- bits per second?

Related decisions:

- decimal base `1000` or binary base `1024`;
- whether `0K` is preferable to `0`;
- smoothing window;
- interface aggregation;
- VPN/tunnel treatment;
- whether local-only traffic is included.

Current recommendation is bytes per second, decimal units, whole numbers.

---

## Q-013 — Download-speed click action

**Priority:** Low

Should clicking the persistent throughput value:

- do nothing;
- open the Network control-centre page;
- open a compact throughput graph;
- open a network details popover?

The current prototype can leave it noninteractive beyond tooltip.

---

## Q-014 — Exact contextual-region capacity

**Priority:** Medium, Prototype

How many fixed contextual slots should the bar reserve?

Current suggestion: approximately three.

Test states:

- no internet;
- microphone active;
- screen recording active;
- idle inhibitor active;
- non-audio Bluetooth device connected;
- file transfer in progress;
- critical alert.

Questions:

- When should overflow begin?
- Should critical state replace lower-priority slots?
- Does the overflow affordance show a count?
- How much permanent empty space is acceptable?

---

## Q-015 — Contextual indicator taxonomy

**Priority:** Medium

Which states are permitted to surface in the bar?

Candidate list:

- no internet;
- limited/captive connectivity;
- microphone active;
- camera active;
- screen recording;
- screen sharing;
- idle inhibitor;
- VPN active;
- non-audio Bluetooth device;
- file transfer;
- notification requiring immediate action;
- update/reboot required;
- media playback;
- clipboard/sync state.

Each state should justify:

- urgency;
- persistence;
- icon;
- click destination;
- overflow priority.

---

## Q-016 — Bar autohide behaviour

**Priority:** Medium, Prototype  
**Needed by:** Phase 6

Questions:

- Reveal on pointer edge contact or require slight inward movement?
- Should keyboard reveal keep it open until focus leaves?
- What is the hide delay?
- Should popovers pin the bar open?
- Does the reserved workspace area disappear while hidden?
- How does autohide behave on top/bottom bars?
- How is accidental reveal prevented?
- What happens while dragging a window to the bar edge?

---

## Q-017 — Active-workspace click behaviour

**Priority:** Medium

Current direction:

- inactive workspace number → switch;
- active workspace number → open quickshell-overview.

Need to validate:

- Is this discoverable?
- Would primary click on active number feel inconsistent?
- Should overview instead require secondary click?
- Should a small long-press or double-click be avoided?
- How does keyboard activation behave?

---

## Q-018 — Focused-window action entry point

**Priority:** Medium

Possible primary entry points:

- secondary click active workspace;
- dedicated keyboard shortcut;
- menu inside quickshell-overview;
- Vicinae command;
- contextual bar indicator when relevant.

Need to decide the default and whether multiple paths are worthwhile.

---

# 4. Control Centre Questions

## Q-019 — Exact Quickshell window primitive

**Priority:** Blocker, Prototype  
**Needed by:** Phase 3

Which Quickshell window type best supports:

- right-edge attachment;
- no permanent exclusive zone;
- keyboard focus;
- pointer-driven direct reveal;
- outside click;
- scrim;
- layer ordering;
- fullscreen policy;
- multi-monitor placement?

Candidates may include a panel/layer-shell window, popup window, or custom combination.

This must be decided through a minimal prototype.

---

## Q-020 — Edge activation width

**Priority:** Medium, Prototype

What invisible width reliably captures a click-and-drag from the extreme right edge without stealing normal application input?

Test values:

- 1 logical pixel;
- 2 logical pixels;
- 3–4 logical pixels.

Test with:

- browser scrollbars;
- code editors;
- maximized windows;
- mixed scaling;
- multiple monitors;
- touchpad pointer precision.

---

## Q-021 — Control-centre drag thresholds

**Priority:** Medium, Prototype

Need real values for:

- minimum movement;
- horizontal intent ratio;
- open-distance threshold;
- opening velocity;
- closing threshold;
- settling duration.

Create debug visualization during prototype development.

---

## Q-022 — Keyboard opening during fullscreen

**Priority:** Medium

Pointer edge reveal is suppressed in fullscreen.

Should explicit keyboard invocation:

- always open;
- open only after a confirmation;
- remain disabled by default;
- be configurable?

Current recommendation is explicit keyboard opening allowed, but this is not fully settled.

---

## Q-023 — Exact control-centre width

**Priority:** Low, Prototype

Initial range: `380–420` logical pixels.

Test with:

- long Wi-Fi SSIDs;
- Bluetooth device names;
- notification actions;
- volume mixer rows;
- text scaling;
- narrow laptop screens;
- vertical external monitors.

---

## Q-024 — Header content

**Priority:** Medium

What exactly belongs in the control-centre header?

Candidates:

- “Control Centre” title;
- current network summary;
- connected-device summary;
- DND state;
- settings;
- session button;
- refresh action;
- profile/avatar;
- no secondary summary.

The header should not become a status dashboard.

---

## Q-025 — Quick-control tile geometry

**Priority:** Low, Prototype

Should five quick controls appear as:

- one horizontal row;
- wrapping grid;
- compact icon row with selected labels;
- adaptive layout based on width?

Need to balance:

- pointer target size;
- readability;
- density;
- labels;
- future additional controls.

---

## Q-026 — Split toggle/detail interaction

**Priority:** Medium, Prototype

For Wi-Fi and Bluetooth, how should toggle versus detail navigation be represented?

Options:

- main body toggles, small chevron opens detail;
- icon toggles, body opens detail;
- primary click opens detail, secondary click toggles;
- long-press or hover affordance, not recommended.

Need to ensure keyboard parity and avoid tiny targets.

---

## Q-027 — Main-view scroll behaviour

**Priority:** Medium

If notifications are long, do quick controls and sliders:

- remain pinned at top;
- scroll away;
- collapse into a compact header;
- become sticky only after scrolling?

The current design says controls remain above the tabs, but their scroll behaviour is not finalized.

---

## Q-028 — Control-centre state restoration

**Priority:** Low

Current proposal:

- brief reopen restores recent focus/tab;
- longer closure returns to Notifications;
- detail pages do not remain indefinitely.

Need exact timeout and behaviour for:

- scroll position;
- selected mixer device;
- Wi-Fi password prompt;
- Bluetooth pairing task;
- open notification group.

---

# 5. Notification Questions

## Q-029 — Notification server migration

**Priority:** Blocker, Research  
**Needed by:** Phase 5

What notification daemon currently owns the session bus?

Questions:

- Is Caelestia currently acting as notification server?
- Must an existing daemon be disabled?
- How does Quickshell claim server ownership?
- What happens during shell reload?
- How are pending notifications handled during restart?
- Can duplicate ownership be detected cleanly?

---

## Q-030 — Popup placement

**Priority:** Low, Prototype

Should notification popups appear:

- top-right;
- below a fixed margin;
- below the control-centre header area;
- on the focused monitor;
- on pointer monitor?

They must remain inset from the extreme right edge so edge dragging remains available.

Need exact:

- width;
- spacing;
- maximum stack height;
- relationship to OSDs and toasts.

---

## Q-031 — Popup timeout policy

**Priority:** Medium, Prototype

Current rough values:

- routine: 5–7 seconds;
- important: 8–10 seconds;
- critical: persistent.

Need to determine:

- effect of body length;
- action buttons;
- hover/focus pause;
- accessibility multiplier;
- whether a notification with progress times out;
- whether very short “done” notices should disappear faster.

---

## Q-032 — Grouping identity

**Priority:** High

What stable key groups notifications by application?

Possible inputs:

- desktop entry;
- app ID;
- application name;
- D-Bus sender;
- normalized fallback.

Need fallback rules for applications that provide poor metadata.

---

## Q-033 — Burst coalescing semantics

**Priority:** Medium

When multiple notifications from one app arrive rapidly:

- update one popup summary;
- append latest body;
- show “N more”;
- replace only if titles match;
- preserve all in history.

Need separate handling for:

- chat messages;
- download progress;
- repeated errors;
- media notifications;
- background sync.

---

## Q-034 — Notification history retention

**Priority:** Medium, Deferred

Initial history is in memory.

Later decide:

- maximum age;
- maximum count;
- persistence across restart;
- private apps excluded by default;
- encryption;
- clear-history semantics;
- per-app retention;
- progress-notification cleanup.

No persistence should be implemented before this is settled.

---

## Q-035 — Notification sound rule syntax

**Priority:** High, Near-term

Need exact matching model:

- exact app ID;
- exact title;
- case sensitivity;
- glob;
- regular expression;
- category;
- urgency;
- first match wins;
- multiple sounds;
- per-rule DND bypass.

Need a safe preview/test workflow.

---

## Q-036 — Critical urgency trust

**Priority:** High

How should shell policy handle applications that mark ordinary notifications as critical?

Possible policy:

- trusted built-in categories;
- user allowlist;
- app urgency only raises to “important,” not “critical”;
- exact per-app override;
- system-service origin verification.

Avoid allowing any arbitrary app to bypass DND/fullscreen unconditionally.

---

## Q-037 — Critical thresholds

**Priority:** High

Need exact defaults for:

- critical battery;
- warning battery;
- CPU temperature warning/critical;
- GPU temperature warning/critical;
- storage warning/critical;
- filesystem failure;
- recording failure.

Thresholds should consider hardware differences and sensor availability.

---

## Q-038 — Fullscreen summary after exit

**Priority:** Low

Should the shell show a subtle message after exiting fullscreen?

Possible:

```text
Notifications received while fullscreen
```

No count.

Or show nothing and rely entirely on drawer review.

---

## Q-039 — Notification action layout

**Priority:** Low, Prototype

How many actions are shown inline?

Options:

- first two inline, rest in overflow;
- all if space permits;
- primary action plus menu;
- action row only on hover/focus.

Need keyboard accessibility and stable card height.

---

## Q-040 — Clear-all undo

**Priority:** Medium

Can notification clear-all support a short undo?

Questions:

- Does the underlying notification protocol permit restoration?
- Should undo only restore shell history, not notify apps?
- Is that misleading?
- Is a lightweight confirmation better?

---

# 6. OSD and Toast Questions

## Q-041 — OSD placement

**Priority:** Low, Prototype

Candidates:

- screen centre;
- lower centre;
- near the bar edge;
- near the active monitor bottom;
- same side as control centre.

Need to evaluate:

- obstruction;
- games/video;
- visual relationship with bar;
- multi-monitor ownership;
- similarity to notifications.

---

## Q-042 — OSD geometry

**Priority:** Low, Prototype

Should volume/brightness OSD use:

- horizontal pill;
- compact vertical pill;
- icon plus progress bar;
- icon plus numeric value;
- both value and bar?

Need to remain glanceable and not mobile-oversized.

---

## Q-043 — System toast placement

**Priority:** Low

Should system toasts appear:

- below notification popup region;
- near control centre;
- lower-right;
- near the changed control when possible?

They must be visually distinct from application notifications.

---

## Q-044 — Toast history on failure

**Priority:** Medium

When a system operation fails, should it:

- become a normal notification in history;
- remain only as a long-lived toast;
- be inserted into a dedicated recent-errors area;
- appear inline in the originating surface only?

Current direction allows failures to enter history, but exact policy is unsettled.

---

# 7. Audio Questions

## Q-045 — Compact audio popover scope

**Priority:** High  
**Needed by:** Phase 6

What belongs in the bar audio popover versus the control-centre mixer?

Possible popover contents:

- master volume;
- mute;
- current output;
- quick output switcher;
- current input;
- microphone mute;
- media controls;
- no per-app streams.

Need a strict boundary to avoid duplicating the mixer.

---

## Q-046 — Output-device icon classification

**Priority:** Medium, Research

How reliably can PipeWire/WirePlumber metadata distinguish:

- speakers;
- wired headphones;
- Bluetooth headphones;
- headset;
- HDMI/DisplayPort audio;
- USB DAC;
- unknown output?

Need user override mechanism for misclassified devices.

---

## Q-047 — Volume above 100%

**Priority:** Medium

Should the shell support amplification above nominal 100%?

Options:

- never;
- configurable maximum;
- allow only in mixer;
- show warning accent above 100%.

Default should likely remain capped at 100%.

---

## Q-048 — Volume scroll step

**Priority:** Low, Prototype

Possible defaults:

- 2%;
- 3%;
- 5%.

Need to test with mouse wheels and trackpads.

---

## Q-049 — Microphone privacy state

**Priority:** High

When should the bar show microphone activity?

Need distinction between:

- microphone device unmuted;
- application actively recording;
- call using microphone;
- microphone monitor stream;
- permission request.

The contextual indicator should reflect actual active capture where possible.

---

# 8. Network and Bluetooth Questions

## Q-050 — Network backend choice

**Priority:** High, Research  
**Needed by:** Phase 4

Should the shell use:

- Quickshell NetworkManager module directly;
- D-Bus NetworkManager adapter;
- `nmcli` fallback;
- retained Caelestia service?

Need to verify current API completeness for:

- scanning;
- saved networks;
- password prompts;
- hidden networks;
- connection task state;
- captive portal;
- Ethernet details.

---

## Q-051 — Wi-Fi secret-agent handling

**Priority:** High, Research

How should password entry integrate with NetworkManager secrets?

Questions:

- Can Quickshell participate as a secret agent?
- Should a helper use NetworkManager D-Bus?
- Can the shell safely hand credentials to an existing agent?
- How are enterprise networks handled?
- How is cancellation represented?

Do not store credentials in shell config or logs.

---

## Q-052 — Captive portal detection and action

**Priority:** Medium

How should the shell detect captive portals?

Possible behaviour:

- contextual limited-connectivity icon;
- Network page banner;
- “Open login page” action;
- automatic browser launch only after explicit click.

Need a reliable detection source.

---

## Q-053 — Advanced network settings delegation

**Priority:** Medium

Which external application should open for advanced configuration?

Candidates:

- `nm-connection-editor`;
- KDE system settings module;
- GNOME control centre;
- configurable command.

The shell should not assume one desktop environment.

---

## Q-054 — Bluetooth backend completeness

**Priority:** High, Research

Can the chosen Quickshell/BlueZ path handle:

- discovery;
- pairing confirmation;
- PIN entry;
- trust;
- connect;
- disconnect;
- remove;
- battery;
- profiles;
- multiple adapters?

Need a fallback plan for missing operations.

---

## Q-055 — Bluetooth audio output switching

**Priority:** Medium

When a Bluetooth audio device connects:

- should it automatically become output;
- should the shell offer a toast action;
- should it respect current WirePlumber policy;
- should this be configurable per device?

Current default proposal is no forced automatic selection.

---

## Q-056 — Bluetooth device visibility in bar

**Priority:** Medium

Which non-audio connected devices deserve contextual visibility?

Candidates:

- game controller;
- mouse;
- keyboard;
- phone;
- stylus;
- unknown device.

Possibilities:

- show any connected non-audio device;
- show only battery-critical or newly connected device;
- show stack icon if multiple;
- never show ordinary input devices unless state changes.

---

# 9. Resource and Sensor Questions

## Q-057 — Sensor backend implementation

**Priority:** High, Research

How should the shell read:

- CPU temperature;
- GPU temperature;
- fan speed;
- clocks;
- usage;
- storage temperature?

Options:

- `/sys/class/hwmon`;
- procfs/sysfs;
- vendor utilities;
- retained Caelestia service;
- small helper daemon.

Need:

- nonblocking reads;
- hardware portability;
- stable labels;
- low overhead.

---

## Q-058 — NVIDIA telemetry

**Priority:** High, Research

The user's machine has an NVIDIA GPU.

Need to determine:

- reliable commands or APIs for usage, temperature, clock, and fan;
- behaviour when dGPU is suspended;
- avoiding wake-up solely for polling;
- hybrid-GPU detection;
- rate limits;
- failure state during driver mismatch.

The shell must not wake the dGPU continuously just to show zero usage.

---

## Q-059 — AMD iGPU telemetry

**Priority:** Medium, Research

Need equivalent strategy for the Renoir iGPU.

Questions:

- available sysfs/hwmon metrics;
- usage reliability;
- temperature mapping;
- clock values;
- interaction with NVIDIA hybrid mode.

---

## Q-060 — Fan-speed availability

**Priority:** Medium

The requested popover includes CPU and GPU fan speed.

Need to verify whether the laptop exposes:

- one shared system fan;
- separate CPU/GPU fans;
- no fan RPM;
- vendor-specific interfaces.

UI should adapt labels rather than inventing separate fans.

---

## Q-061 — Top-process calculation

**Priority:** Medium

Should the resource popover show:

- top CPU process;
- top memory process;
- both;
- none initially?

Questions:

- update cost;
- process-name privacy;
- click action;
- handling rapidly changing processes.

---

## Q-062 — Storage scope

**Priority:** Medium

Which filesystems should the resource popover show?

Options:

- root only;
- root and home;
- configured mounts;
- aggregate fixed storage;
- removable drives when connected.

Current config proposes root only by default.

---

# 10. Power and auto-cpufreq Questions

## Q-063 — auto-cpufreq active configuration resolution

**Priority:** High, Research

Need to confirm:

- exact config precedence;
- user versus system config support in the installed version;
- daemon reload/apply mechanism;
- statistics interface;
- available fields;
- battery threshold support;
- interaction with system power profiles.

Do not implement the editor from assumed field names.

---

## Q-064 — Privileged helper implementation language

**Priority:** High

Options:

- Rust;
- C++;
- Python;
- shell script with Polkit wrapper, not preferred;
- existing auto-cpufreq CLI only.

Evaluation:

- input validation;
- packaging;
- attack surface;
- maintainability;
- startup overhead;
- atomic writes;
- testability.

---

## Q-065 — Preserve comments and unknown fields

**Priority:** High

When editing auto-cpufreq config, should the helper:

- parse and rewrite while preserving comments;
- update known keys in place;
- generate a shell-managed separate config;
- keep a structured overlay file;
- delegate entirely to auto-cpufreq CLI if available?

The chosen strategy must avoid destroying manual config.

---

## Q-066 — Temporary power overrides

**Priority:** Medium

How should “Automatic / Power Save / Performance” work?

Questions:

- Which auto-cpufreq commands or config changes implement them?
- Are overrides persistent until reboot?
- Do they modify config?
- How does UI show auto mode versus override?
- Can override expire after a duration?

---

## Q-067 — Battery time estimate

**Priority:** Low

Should the power panel show time remaining?

Only if the estimate is sufficiently stable.

Need policy for:

- rapidly changing workloads;
- “calculating” state;
- charging time;
- missing estimate.

---

# 11. Calendar Questions

## Q-068 — Calendar provider architecture

**Priority:** High, Near-term

Confirm provider-neutral model before Google integration.

Need operations for:

- event range query;
- multiple calendars;
- all-day events;
- timed events;
- recurrence;
- time zones;
- sync state;
- create/update/delete;
- offline cache.

---

## Q-069 — Google authentication

**Priority:** High, Research

How will the shell authenticate Google Calendar?

Options may include:

- OAuth desktop flow;
- browser-based authorization;
- external helper;
- existing GNOME/KDE online-account integration;
- a local service.

Need:

- secure token storage;
- refresh;
- revocation;
- account switching;
- headless error recovery.

---

## Q-070 — Credential storage

**Priority:** High

Where should OAuth tokens live?

Candidates:

- Secret Service / libsecret;
- KWallet;
- an encrypted local store;
- external account service.

Plain configuration is forbidden.

---

## Q-071 — Calendar panel information hierarchy

**Priority:** Medium, Prototype

After Google integration, how should month grid and agenda share space?

Options:

- month grid above selected-day agenda;
- side-by-side on wide panel;
- month grid with event dots, agenda as nested page;
- expandable agenda.

Need to preserve compact edge-attached behaviour.

---

## Q-072 — Calendar reminder policy

**Priority:** Medium

Default direction: reminders respect DND.

Need settings for:

- selected calendars bypassing DND;
- event importance;
- reminder sound;
- all-day reminders;
- meeting-start alerts;
- fullscreen behaviour.

---

# 12. Tray Questions

## Q-073 — Exact tray drawer layout

**Priority:** Medium, Prototype

Possible layouts:

- compact icon grid;
- vertical list with title/status;
- grid with tooltip;
- hybrid pinned row plus full list.

Need to support many items without excessive space.

---

## Q-074 — Stable tray ordering

**Priority:** Medium

Possible ordering:

- registration order;
- app name;
- category;
- user-defined stable order;
- recent activity.

Current direction says stable ordering, but exact key is unresolved.

---

## Q-075 — Tray pinning UX

**Priority:** Low, Later

How does a user pin an item?

Options:

- context menu in tray drawer;
- drag to bar;
- settings page;
- Vicinae shell command.

Need handling for unstable application identifiers.

---

## Q-076 — Tray attention semantics

**Priority:** Medium

How should the collapsed affordance react to:

- `NeedsAttention`;
- blinking legacy behaviour;
- unread message status;
- transfer progress;
- application error?

Avoid allowing noisy apps to keep the bar permanently highlighted.

---

# 13. Vicinae Questions

## Q-077 — Exact invocation API

**Priority:** Blocker, Research  
**Needed by:** Phase 7, basic root toggle earlier

Need to verify current Vicinae commands/deeplinks for:

- root search;
- clipboard history;
- file search;
- window search;
- specific extension command;
- theme switching;
- availability/version.

Do not hard-code speculative CLI examples.

---

## Q-078 — Vicinae extension architecture

**Priority:** High

Need to decide:

- extension language/runtime;
- command naming;
- shell IPC client implementation;
- compatibility version handshake;
- error presentation;
- packaging with the shell;
- whether it lives inside or beside the main repository.

---

## Q-079 — Vicinae visual integration depth

**Priority:** Medium

How far should theme integration go without a fork?

Likely available:

- generated colours;
- maybe font/theme settings;
- extension iconography.

Need to accept that geometry and motion may remain Vicinae-native.

---

## Q-080 — Fallback when Vicinae is absent

**Priority:** Medium

Current principle says the shell remains usable, but launcher functionality disappears.

Need exact UX:

- disabled bar button;
- error toast on click;
- setup instructions;
- optional configurable fallback launcher;
- no fallback at all.

Avoid silently building a second launcher.

---

# 14. quickshell-overview Questions

## Q-081 — Standalone versus vendored long-term

**Priority:** Medium

Initial decision: standalone.

Revisit after prototype based on:

- theme limitations;
- configuration duplication;
- startup latency;
- crashes;
- multi-monitor fixes;
- maintenance needs;
- IPC stability.

---

## Q-082 — Shared configuration mechanism

**Priority:** High

How will Franken Shell synchronize:

- numbered grid;
- special workspace names;
- icons;
- theme;
- rows/columns;
- keyboard behaviour?

Options:

- generated overview config;
- shared imported file;
- environment variables;
- IPC setters;
- vendored shared module.

Need one-way ownership from Franken Shell config.

---

## Q-083 — Live preview stability

**Priority:** High, Research

Need to test known risks:

- rapid window changes;
- closing windows during capture;
- fullscreen windows;
- mixed scale;
- rotated monitors;
- suspended NVIDIA GPU;
- multiple monitors.

Define fallback if live previews crash or leak resources.

---

## Q-084 — Overview invocation from bar

**Priority:** Medium, Prototype

Validate active-workspace click behaviour and alternative keyboard/secondary-click paths.

Need to prevent accidental overview opening during rapid pointer workspace switching.

---

# 15. Session and Lock Questions

## Q-085 — Session-surface form

**Priority:** Medium

Should session actions appear as:

- centred modal;
- edge-attached panel;
- full-screen dimmed surface;
- compact confirmation menu?

It should feel coherent without making destructive actions too easy.

---

## Q-086 — Lock implementation ownership

**Priority:** Medium, Deferred

Options:

- retain current lock solution;
- integrate hyprlock;
- custom Quickshell lock;
- another supported locker.

Security and compositor compatibility must be verified before choosing a custom implementation.

---

## Q-087 — Hibernate support

**Priority:** Low, Capability-driven

Should hibernate appear only when system support is detected?

Need reliable capability check and failure handling.

---

# 16. Multi-Monitor Questions

## Q-088 — Bar on all monitors

**Priority:** High  
**Needed by:** Phase 10

Options:

- bar on every monitor;
- bar only on primary;
- bar on configured monitors;
- different bar edge per monitor.

Current architecture supports configured monitors but no default product policy is settled.

---

## Q-089 — Workspace pager per monitor

**Priority:** High

Hyprland workspaces are monitor-associated.

Questions:

- Should each bar show only workspaces relevant to that monitor?
- Should all bars show the global active workspace group?
- How does direct workspace click behave across monitors?
- Does workspace group follow the focused monitor?

The user's semantic workspace model may assume one primary monitor, so multi-monitor behaviour needs careful testing.

---

## Q-090 — Control-centre monitor ownership

**Priority:** High

Provisional:

- edge drag → pointer monitor;
- keyboard → focused-window monitor;
- one global drawer.

Need to test whether one global drawer is confusing when bars exist on multiple displays.

---

## Q-091 — Notification monitor ownership

**Priority:** High

Candidates:

- focused-window monitor;
- pointer monitor;
- primary monitor;
- monitor where originating app window lives;
- configurable.

Need stable behaviour during focus changes.

---

## Q-092 — OSD monitor ownership

**Priority:** Medium

Should OSD appear on:

- focused-window monitor;
- monitor whose brightness changed;
- pointer monitor;
- all monitors for global volume;
- one configured monitor?

Brightness should likely target the affected monitor; volume is global.

---

## Q-093 — Physical outer-edge detection

**Priority:** High, Prototype

On side-by-side monitors, the right edge of the left monitor is not a physical outer edge.

Should control-centre drag activate there?

Likely no.

Need monitor-topology-aware edge eligibility.

---

## Q-094 — Fractional scaling pixel alignment

**Priority:** Medium, Prototype

Need to test:

- outlines;
- one-pixel activation strips;
- icon sharpness;
- progress rings;
- popup placement;
- screenshots/live overview.

---

# 17. Gesture Questions

## Q-095 — Hyprland gesture API and Lua integration

**Priority:** High, Research

Need current Hyprland 0.55+ gesture capabilities in Lua config.

Questions:

- which gestures are compositor-native;
- whether Quickshell can receive continuous gesture progress;
- how conflicts are represented;
- whether shell edge gestures require libinput tooling or another daemon.

---

## Q-096 — Control-centre trackpad gesture

**Priority:** Medium, Prototype

Can the drawer be directly manipulated with a four-finger swipe?

Need:

- progress events;
- cancellation;
- monitor ownership;
- no conflict with workspace gestures;
- disabled fallback if unsupported.

---

## Q-097 — Overview gesture

**Priority:** Low, Prototype

Possible four-finger upward gesture.

Need to decide whether this feels natural beside workspace and control-centre gestures.

---

# 18. Visual Questions

## Q-098 — Font family

**Priority:** Low, Prototype

Need a font that is:

- highly legible at small size;
- variable if possible;
- supports tabular numerals;
- aesthetically compatible with Material You Expressive;
- available or packageable;
- broad enough for user locale needs.

Do not distribute font files through project support channels without checking licensing.

---

## Q-099 — Icon family

**Priority:** Medium, Prototype

Need one coherent icon strategy.

Options:

- Material Symbols;
- Fluent;
- Papirus symbolic;
- custom normalized SVG set;
- Caelestia icon set;
- mixed but normalized semantic wrapper.

Criteria:

- small-size clarity;
- filled/outlined state variants;
- licensing;
- dynamic colour;
- availability;
- app/tray compatibility.

---

## Q-100 — Light mode

**Priority:** Medium

Will dynamic colours support both light and dark shell modes from the start?

Questions:

- automatic mode from wallpaper;
- explicit override;
- contrast validation;
- control-centre opacity;
- tray icons;
- external integration theme sync.

Could be deferred if the first prototype targets dark mode, but tokens must not hard-code it.

---

## Q-101 — Blur policy

**Priority:** Low

Current default is off or very subtle.

Need to decide:

- bar blur;
- popover blur;
- notification blur;
- performance budget;
- fallback when compositor blur is disabled.

---

## Q-102 — Theme transition

**Priority:** Low, Prototype

Need exact behaviour when wallpaper changes:

- instant switch;
- short crossfade;
- staged tonal transition;
- defer while fullscreen;
- update external integrations before or after shell.

Must avoid unreadable intermediate states.

---

# 19. Settings Questions

## Q-103 — Settings surface location

**Priority:** Medium

Should shell settings be:

- a dedicated Quickshell window;
- a nested control-centre page;
- a standalone app;
- Vicinae extension commands plus config editor;
- hybrid?

Because settings can be extensive, a dedicated surface may be clearer than nesting everything in the control centre.

---

## Q-104 — Settings save/apply model

**Priority:** Medium

Which settings:

- apply live;
- require Save;
- require shell surface recreation;
- require full restart;
- require privilege?

Need clear categories and UI.

---

## Q-105 — User-configurable bar order

**Priority:** Low

Should users be allowed to reorder bar modules?

Current design strongly prefers a fixed hierarchy.

Possible compromise:

- allow hiding optional modules;
- allow a few semantic presets;
- no arbitrary drag ordering initially.

---

# 20. Diagnostics and Packaging Questions

## Q-106 — Diagnostic command UX

**Priority:** Medium

Should diagnostics be exposed through:

- shell IPC only;
- `franken-shell doctor` CLI;
- settings page;
- all three using one backend?

A CLI is useful for support and Codex debugging.

---

## Q-107 — Helper and service packaging

**Priority:** High

Need to decide package layout for:

- main QML shell;
- auto-cpufreq helper;
- Polkit policy;
- systemd user service;
- Vicinae extension;
- generated integration templates;
- optional dependencies.

---

## Q-108 — Arch/Garuda package strategy

**Priority:** Medium, Later

Options:

- PKGBUILD in repository;
- AUR package later;
- install script;
- development symlink mode;
- separate `-git` package.

Need clean uninstall and config preservation.

---

## Q-109 — Upgrade rollback

**Priority:** Medium

What happens if a new shell version:

- fails config migration;
- cannot start on current Quickshell;
- breaks overview compatibility;
- introduces helper mismatch?

Need:

- backup;
- previous package;
- last-known-good config;
- clear recovery instructions.

---

# 21. Testing Questions

## Q-110 — QML test framework

**Priority:** High, Research

Which testing tools are practical for:

- pure QML logic;
- singleton services;
- component rendering;
- fixture models;
- IPC;
- screenshots?

Need a test strategy compatible with Quickshell's runtime.

---

## Q-111 — Mock service architecture

**Priority:** High

How should mock mode inject:

- workspaces;
- notifications;
- network;
- Bluetooth;
- audio;
- battery;
- sensors;
- monitors?

Mocks should implement the same adapter contracts.

---

## Q-112 — Visual regression tooling

**Priority:** Low, Later

Need a reproducible method for:

- rendering fixture states;
- screenshot capture;
- comparison tolerances;
- dynamic colour snapshots;
- scale variants.

---

# 22. Questions to Resolve Through User Experience, Not Research

These should be tested in daily use rather than answered from theory:

- final bar thickness;
- final control-centre width;
- date/time arrangement;
- battery percent sign;
- charging animation;
- active-workspace click behaviour;
- number of contextual slots;
- control-centre sticky-header behaviour;
- notification popup timeout;
- OSD placement;
- tray drawer layout;
- volume scroll step;
- quick-control geometry;
- animation durations;
- degree of surface opacity;
- whether bar should be inset.

---

# 23. Questions to Resolve Through Upstream/API Research

These require up-to-date primary-source verification before implementation:

- supported Quickshell range and module/API compatibility evidence under Q-113;
- Hyprland 0.55+ Lua gesture and IPC behaviour;
- Vicinae invocation/deeplink and extension APIs;
- quickshell-overview IPC/config format;
- NetworkManager secret-agent support;
- Quickshell Bluetooth pairing support;
- Quickshell notification server lifecycle;
- Quickshell system tray menu behaviour;
- UPower and brightness module capabilities;
- Polkit integration;
- auto-cpufreq current config and daemon interfaces;
- GPU telemetry sources;
- Google Calendar OAuth requirements.

Research findings should become architecture decisions or feature-spec requirements.

---

# 24. Recommended Resolution Order

Resolve in this order:

## Before Phase 0

Resolved by D-071 through D-074:

1. exact tested development baseline;
2. provisional Caelestia migration inventory;
3. clean main-branch bootstrap strategy;
4. parallel-safe development and production supervision topology.

Q-113 through Q-115 retain follow-up research that does not block the non-owning
Phase 0 bootstrap.

## Before Phase 1

5. configuration format.
6. configuration validation approach.
7. theme source adapter boundary.

## Before Phase 3

8. control-centre window primitive.
9. edge activation feasibility.
10. focus-grab and outside-click behaviour.

## Before Phase 4

11. backend choices for network, Bluetooth, audio, battery, tray, brightness.
12. monitor mapping.
13. sensor strategy.

## Before Phase 5

14. notification server ownership.
15. notification grouping identity.
16. critical trust policy.

## Before Phase 7

17. exact Vicinae APIs.
18. exact quickshell-overview IPC and config sync.

## Before Phase 8

19. auto-cpufreq interfaces and helper design.
20. Google Calendar authentication and secure storage.

## Before Phase 10

21. final multi-monitor ownership policy.
22. gesture capability and conflict model.

---

# 25. Open-Question Resolution Template

When resolving a question, record:

```markdown
## Resolution

**Question:** Q-XXX  
**Date:** YYYY-MM-DD  
**Decision:**  
**Evidence or prototype:**  
**Alternatives rejected:**  
**Consequences:**  
**Documents updated:**  
```

Then:

1. add or update an entry in `decisions.md`;
2. update affected feature specifications;
3. remove or mark the question resolved here;
4. add implementation tasks if needed.

---

# 26. Immediate Questions for the First Codex Session

Before asking Codex to build the first runnable shell, the human should provide or let Codex inspect:

- current Franken Shell project directory;
- current modified Caelestia configuration;
- installed Quickshell version;
- installed Hyprland version;
- current shell launch command;
- current notification daemon ownership;
- desired repository location;
- whether current shell must remain active during development.

The first Codex session should not decide visual details.

Its purpose should be to:

- inspect;
- inventory;
- verify versions;
- propose the minimal bootstrap;
- identify reusable modules;
- avoid modifying the current working shell until a migration plan is approved.
