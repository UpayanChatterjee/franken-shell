# Franken Shell — Control Centre

> **Path:** `docs/features/control-centre.md`  
> **Status:** Implementation specification  
> **Primary phase:** Phase 3 — Control-Centre Mechanics  
> **Daily-use completion:** Phase 6 — Working Daily-Use Prototype  
> **Related documents:** `product-vision.md`, `design-principles.md`, `feature-map.md`, `interaction-language.md`, `visual-language.md`, `architecture.md`, `configuration-model.md`, `implementation-phases.md`, `decisions.md`, `open-questions.md`

This document specifies Franken Shell's right-edge control centre as a Quickshell/QML feature.

It turns the settled product, interaction, and architecture decisions into an implementation contract while preserving every unresolved control-centre question as an explicit prototype or research item. Codex must not choose a window primitive, final width, drag thresholds, header layout, quick-control geometry, scroll policy, or restoration timeout merely because one option is easiest to implement.

---

# 1. Product Role

The control centre is Franken Shell's hidden right-edge utility drawer for accumulated attention and frequent secondary system controls.

Its purpose is to make ordinary desktop management available without permanently occupying bar space or forcing the user into a full settings application.

The control centre provides the primary shell home for:

- notification history;
- Wi-Fi and Bluetooth quick controls;
- Do Not Disturb;
- Night Light;
- idle inhibition;
- master volume;
- display brightness;
- per-application and per-device audio mixing;
- comprehensive nested Wi-Fi management;
- comprehensive nested Bluetooth management;
- entry points to shell settings and session actions.

The control centre must feel:

- attached to the right edge rather than like an arbitrary floating window;
- dense but readable;
- more opaque than the Illogical Impulse reference;
- immediately usable by keyboard;
- directly manipulable by pointer;
- stable while notifications and device state change;
- independent of optional backend failures;
- visually integrated with the shared Caelestia-derived theme.

It is not:

- a replacement for all system settings;
- a launcher or general command palette;
- a second calendar home;
- a complete hardware administration application;
- a collection of detached Wi-Fi, Bluetooth, and mixer popups;
- a fullscreen mobile-style settings panel;
- the owner of notification, audio, network, Bluetooth, brightness, or session backend logic.

---

# 2. Settled Requirements

The requirements in this section are settled unless a later decision explicitly supersedes them.

## 2.1 Spatial model

- The control centre is attached to the **right edge**.
- It remains right-attached even when the persistent bar is moved to another edge.
- It does not reserve a permanent exclusive zone or permanently reduce application workspace geometry.
- It is a major shell surface coordinated by the shared `SurfaceCoordinator`.
- It uses an opaque or nearly opaque Material surface.
- Decorative blur is optional, subtle, and never required for readability.
- Its prototype width is expected to fall approximately within `380–420` logical pixels, but the exact width remains unresolved.
- Nested pages remain visually and structurally inside the same drawer.
- Network and Bluetooth management must not open as tiny detached popups.

## 2.2 Opening paths

The initial control centre opens through:

- a configurable keyboard shortcut;
- click-and-drag leftward from an invisible activation strip at the extreme right edge.

Additional settled rules:

- hover never opens the control centre;
- a press must begin within the activation strip for pointer drag opening;
- the panel follows pointer movement during a committed drag;
- opening requires horizontal intent plus a distance and/or velocity threshold;
- accidental small or mostly vertical movement must not open the drawer;
- pointer edge activation is disabled during true fullscreen by default;
- explicit keyboard invocation during fullscreen remains an unresolved policy question;
- invoking the control-centre shortcut while it is already open toggles it closed.

A later trackpad gesture may invoke the same reveal model, but gesture support is not required for the first mechanics prototype.

## 2.3 Default view and content hierarchy

The default view is the main control-centre view with:

```text
Control-centre surface
├─ Header / top actions
├─ Quick controls
│  ├─ Wi-Fi
│  ├─ Bluetooth
│  ├─ Do Not Disturb
│  ├─ Night Light
│  └─ Idle inhibitor
├─ Master volume slider
├─ Display brightness slider, when available
├─ Tab row
│  ├─ Notifications
│  └─ Volume Mixer
└─ Active tab content
```

The default selected tab is **Notifications**.

Quick controls and the two primary sliders remain conceptually above the main tabs. Their exact sticky or scrolling behaviour remains unresolved.

The first nested detail pages are:

- Network;
- Bluetooth.

The control centre must also provide entry points to:

- shell settings;
- session and power actions.

The exact header composition and placement of these entry points remain unresolved.

## 2.4 Quick-control behaviour

Initial quick controls are fixed as:

- Wi-Fi;
- Bluetooth;
- Do Not Disturb;
- Night Light;
- idle inhibitor.

Requirements:

- active and inactive state must be visually unmistakable;
- unavailable state must differ from inactive state;
- toggles must support pointer and keyboard activation;
- user-triggered successful state changes produce system configuration toasts;
- user-triggered failures remain visible long enough to understand and may expose Retry or Details;
- Wi-Fi and Bluetooth provide both a toggle action and a detail-navigation action;
- the toggle/detail distinction must have keyboard parity;
- active idle inhibition may also appear contextually in the persistent bar.

The exact split-tile geometry remains unresolved and must be prototyped.

## 2.5 Slider behaviour

The main view always exposes:

- master output volume, when an audio backend is available;
- display brightness, when a controllable brightness target is available.

Requirements:

- pointer drag changes the value;
- scroll while hovered changes the value;
- arrow keys change the value while focused;
- value changes do not close the drawer;
- changes publish to the shared OSD channel;
- repeated changes update one OSD rather than creating a stack;
- DND does not suppress these OSDs;
- unsupported brightness is omitted rather than represented by a permanently dead control;
- backend-specific commands are not issued from slider QML.

## 2.6 Tab and nested-page behaviour

Initial main tabs are:

- Notifications;
- Volume Mixer.

Requirements:

- selecting a tab replaces the active tab body inside the drawer;
- tab focus and tab selection are visually distinct concepts;
- switching tabs may preserve relevant local state, such as mixer scroll position;
- nested pages replace the main view rather than opening another top-level window;
- a nested page provides an explicit back action and page title;
- `Escape` cancels the deepest active operation before navigating back;
- from a nested page, `Escape` returns to the parent main view;
- from the main view, the next `Escape` closes the drawer;
- detail-page focus returns to the control that opened it.

## 2.7 Notification integration

- The control centre is the primary notification-history review surface.
- It defaults to the Notifications tab because notifications are its primary accumulated-attention function.
- Notifications are grouped by application.
- Local group counts are allowed inside the drawer.
- No global unread count or notification badge is shown.
- When the drawer is already open to Notifications, a newly received ordinary notification enters history without also producing a duplicate popup.
- DND preserves notification history.
- Notification ownership, classification, retention, grouping semantics, and action policy belong to the notification feature, not the control-centre host.

## 2.8 Visual requirements

- Use shared semantic theme roles rather than raw wallpaper colours.
- The surface is opaque or almost opaque.
- The attached right edge should use edge-aware corner treatment.
- The drawer should be information-dense without becoming cramped.
- It must not imitate a full-screen mobile control panel.
- Accent is concentrated on active controls, selected tabs, slider fills, progress, and focus.
- Passive icons and labels remain neutral.
- Keyboard focus must remain visible independently of active or selected fill.
- State must not rely only on colour.
- Pointer targets should generally be at least approximately `40–44` logical pixels inside the control centre.
- Live numeric values use tabular numerals where shown.
- Reduced-motion mode preserves hierarchy and state without relying on sliding or morphing animation.

---

# 3. Scope and Ownership

## 3.1 The control-centre feature owns

- the right-edge control-centre view composition;
- the control-centre host contract;
- the invisible edge-activation host contract;
- normalized reveal progress and drawer drag state;
- the main-view layout;
- the internal page stack and tab selection presentation;
- control-centre-specific focus navigation;
- control-centre-specific dismissal requests;
- quick-control visual delegates;
- slider presentation and interaction forwarding;
- page-loading boundaries;
- monitor-bound presentation state;
- fixtures for reveal, focus, unavailable services, and dynamic content;
- diagnostics specific to reveal mechanics, layout, and page loading.

## 3.2 The control-centre feature does not own

- global surface arbitration;
- monitor-selection policy;
- Hyprland fullscreen detection;
- notification-server ownership;
- notification history or retention policy;
- notification grouping semantics;
- PipeWire or WirePlumber acquisition and commands;
- NetworkManager acquisition or secret handling;
- BlueZ acquisition or pairing policy;
- display-backlight commands;
- Night Light backend commands;
- idle-daemon or idle-inhibit backend commands;
- DND policy implementation;
- toast or OSD windows;
- session execution or confirmation policy;
- shell settings persistence;
- privileged operations;
- external advanced-settings application logic.

These responsibilities belong to shared services, feature controllers, integration adapters, `SurfaceCoordinator`, `CommandRegistry`, and later feature specifications.

## 3.3 Child-feature ownership boundaries

The control centre hosts child features but does not absorb them.

### Notifications

The notification feature owns:

- notification data model;
- history;
- grouping;
- dismissal;
- actions;
- progress;
- DND and fullscreen popup policy.

The control centre owns only the drawer viewport, tab placement, focus entry, and integration contract.

### Volume Mixer

The audio feature owns:

- outputs and inputs;
- master volume and mute;
- application streams;
- stream volumes;
- routing where supported;
- error normalization.

The control centre owns only the tab host and lifecycle.

### Network

The network feature owns:

- Wi-Fi state;
- Ethernet state;
- scanning;
- connection tasks;
- credentials flow;
- disconnect and forget actions;
- limited and captive connectivity;
- advanced-settings delegation.

The control centre owns only nested-page navigation and page lifecycle.

### Bluetooth

The Bluetooth feature owns:

- adapter state;
- discovery;
- pairing state machines;
- connect and disconnect tasks;
- device battery;
- prompts;
- error recovery.

The control centre owns only nested-page navigation and page lifecycle.

### Settings and session

Settings and session features own their content and destructive-action policy. The control centre exposes deliberate entry points and forwards opening requests through shared coordination.

---

# 4. Proposed QML Structure

The following structure is implementation guidance. Do not create every file before it has a real responsibility.

```text
surfaces/
├── ControlCenterHost.qml
├── EdgeActivationHost.qml
└── ScrimHost.qml

features/controlcenter/
├── ControlCenterView.qml
├── ControlCenterController.qml
├── ControlCenterRevealController.qml
├── ControlCenterFocusController.qml
├── ControlCenterPageStack.qml
├── ControlCenterMainPage.qml
├── ControlCenterHeader.qml
├── QuickControlsSection.qml
├── QuickControlTile.qml
├── PrimarySlidersSection.qml
├── ControlCenterTabs.qml
├── NotificationsTabHost.qml
├── VolumeMixerTabHost.qml
├── DetailPageFrame.qml
└── fixtures/
    └── ControlCenterFixtureModel.qml
```

The network, Bluetooth, notification, and audio feature implementations should remain in their own feature directories even when rendered inside the control centre.

## 4.1 `ControlCenterHost`

The exact Quickshell window primitive is unresolved and must be selected through a focused prototype.

Candidate strategies include:

- `PanelWindow` configured without a permanent exclusive zone;
- `PopupWindow` where focus and layer behaviour are sufficient;
- another layer-shell or coordinated-window combination supported by the pinned Quickshell baseline.

Required host contract:

```text
monitor
open
revealProgress        // normalized 0.0–1.0
interactionState
width
surfaceRect
scrimRequired
keyboardActive
pointerDragging
fullscreenSuppressed
```

Responsibilities:

- attach to the right edge of one selected monitor;
- avoid reserving permanent application space;
- expose a continuously adjustable reveal transform;
- receive keyboard focus after an opening request commits;
- cooperate with a scrim and outside-click handling;
- remain predictable across open, close, and drag transitions;
- host one internal page stack;
- report windowing limitations to diagnostics;
- avoid backend service imports.

The host must not independently decide which monitor should own the global control centre. That decision belongs to `SurfaceCoordinator` and `MonitorRegistry`.

## 4.2 `EdgeActivationHost`

Responsibilities:

- exist only on monitors eligible for pointer edge activation;
- occupy a narrow configurable logical width at the extreme right edge;
- expose no visible handle;
- ignore hover as an opening trigger;
- begin recognition only when a primary-button press starts inside the strip;
- record initial pointer position and time;
- distinguish mostly horizontal inward motion from mostly vertical motion;
- forward normalized gesture data to `ControlCenterRevealController`;
- remain disabled in normalized true fullscreen unless policy later changes;
- expose a debug visualization in development mode only.

The implementation must be tested for interaction conflicts with:

- browser scrollbars;
- editor minimaps and scrollbars;
- maximized windows;
- drag-and-drop near the right edge;
- mixed monitor scaling;
- adjacent monitors;
- touchpad pointer precision.

Do not assume a consumed pointer press can be returned to the underlying application after intent recognition fails. Verify the actual Wayland/Quickshell behaviour and design the activation width accordingly.

## 4.3 `ControlCenterRevealController`

This controller owns the drawer-specific interaction state machine, but not global surface conflict policy.

Required conceptual states:

```text
Closed
PressedAtEdge
DragIntentDetected
DraggingOpen
SettlingOpen
Open
DraggingClosed
SettlingClosed
```

An explicit `Suppressed` or rejection result may be useful for diagnostics but should not become a visual user-facing state unless needed.

Suggested presentation properties:

```text
state
revealProgress
pointerStart
pointerCurrent
horizontalDistance
verticalDistance
horizontalVelocity
intentAccepted
openingSource       // keyboard, edgeDrag, IPC, pointerAction, futureGesture
closingReason
```

Responsibilities:

- clamp reveal progress to `0.0–1.0`;
- follow the pointer directly after intent is accepted;
- choose settle-open or settle-closed on release;
- cancel safely when monitor or fullscreen state invalidates the interaction;
- avoid concurrent settle and direct-drag animations;
- respect reduced motion for non-direct transitions;
- expose instrumentation for threshold tuning;
- avoid embedding final threshold constants in view delegates.

## 4.4 `ControlCenterController`

This controller presents normalized shell state to the view.

Suggested responsibilities:

- expose active main tab;
- expose internal page stack summary;
- expose quick-control view models;
- expose master volume and brightness view models;
- expose capability and degraded-state summaries;
- request toggle actions through feature controllers;
- request nested-page navigation;
- request settings or session surfaces;
- coordinate recent-state restoration with `SurfaceCoordinator` or a dedicated session-state object;
- expose opening source and initial-focus target;
- publish user-action feedback requests without creating toast or OSD windows.

It must not:

- duplicate authoritative service state;
- run shell commands;
- parse backend-specific enums in delegates;
- keep a second notification history;
- store credentials;
- own long-lived pairing tasks;
- decide global monitor policy.

## 4.5 `ControlCenterPageStack`

The page stack represents navigation state inside one drawer.

Suggested page identifiers:

```text
main
network
bluetooth
```

Future pages may include settings summaries or other utilities only after their product home is settled.

Required behaviour:

- main is the root page;
- child pages are lazily loaded;
- only the active page is interactive;
- pushing a child records the invoking focus target;
- popping restores focus to the invoking control when valid;
- closing the drawer does not preserve unsafe prompts or credentials;
- reopening after a long closure returns to main / Notifications;
- page transitions remain within the drawer geometry;
- a page cannot open a competing top-level control-centre window.

## 4.6 Main-view component contract

The main view should expose clear slots rather than importing child service objects directly:

```text
headerContent
quickControlsModel
volumeControlModel
brightnessControlModel
tabsModel
activeTabContent
```

This allows fixture mode and later component testing without live services.

---

# 5. State and Data Requirements

## 5.1 Surface state

Required normalized surface state includes:

```text
isOpen
revealProgress
interactionState
openingSource
owningMonitorId
fullscreenOnOwningMonitor
scrimVisible
keyboardFocusInside
previouslyFocusedWindow
closeBlockedReason?
```

`revealProgress` is presentation state, not a substitute for `isOpen` or `interactionState`.

A drawer may be visually partially revealed while not yet committed open.

## 5.2 Navigation state

Required navigation state includes:

```text
rootPage = main
pageStack
activeTab
lastFocusedControlByPage
lastScrollPositionByPage
lastInteractionTimestamp
pendingModalOperation?
```

Unsafe transient state must not be restored after closure, including:

- Wi-Fi passwords;
- Bluetooth PIN input;
- authentication text;
- destructive confirmations;
- stale pairing confirmation prompts;
- cancelled connection task UI.

Whether safe state such as active tab, open notification group, or mixer scroll position is restored, and for how long, remains partially unresolved.

## 5.3 Quick-control view model

Each quick control should consume a normalized contract similar to:

```text
id
label
icon
available
enabled
active
busy
error
secondaryText?
hasDetailPage
primaryActionLabel
detailActionLabel?
canToggle
canOpenDetails
```

State meanings:

- `available = false`: capability or backend is absent;
- `enabled = false`: action is currently not permitted;
- `active = true`: represented feature is on or engaged;
- `busy = true`: a user-requested transition is in progress;
- `error`: the latest meaningful operation or service error.

Do not collapse unavailable, disabled, inactive, and failed into one grey appearance.

## 5.4 Required quick-control data

### Wi-Fi

At minimum:

```text
backendAvailable
wifiDeviceAvailable
radioEnabled
activeConnectionName?
connectivityState
busy
lastError?
```

The tile does not own network scanning or credentials.

### Bluetooth

At minimum:

```text
backendAvailable
adapterAvailable
powered
connectedDeviceCount
busy
lastError?
```

The tile does not own discovery or pairing.

### Do Not Disturb

At minimum:

```text
available
active
policySummary?
```

DND is shell-owned policy and should normally be available whenever the notification subsystem is operational. A degraded notification service must be represented explicitly.

### Night Light

At minimum:

```text
backendAvailable
active
scheduled?
currentTemperature?
busy
lastError?
```

The initial tile may expose only active state and toggle action. Schedule and temperature detail are later scope unless separately specified.

### Idle inhibitor

At minimum:

```text
backendAvailable
active
source              // userOverride, application, unknown if normalized later
remainingDuration?
busy
lastError?
```

The initial quick control represents the shell's user-controlled inhibition state. Application-provided inhibitors may require a separate normalized policy rather than being silently toggled off.

## 5.5 Slider view model

Suggested normalized contract:

```text
id
label
icon
available
enabled
value               // normalized 0.0–1.0 for presentation
minimum
maximum
step
muted?
busy
error?
accessibleValueText
```

The controller converts normalized presentation values into backend-specific ranges.

### Volume

Required data:

```text
audioBackendAvailable
value
muted
defaultOutputName?
maximumConfiguredVolume
```

The initial product default is capped at nominal `100%`; amplification policy remains owned by the audio specification.

### Brightness

Required data:

```text
brightnessBackendAvailable
controllableTargetAvailable
value
targetName?
```

If no controllable target exists, omit the slider and allow the layout to reflow intentionally.

## 5.6 Tab host state

### Notifications tab host

Consumes:

```text
notificationGroups
historyAvailable
historyLoading
historyError?
doNotDisturb
canClear
```

Detailed item models and actions belong to `NotificationController`.

### Volume Mixer tab host

Consumes:

```text
audioBackendAvailable
outputs
inputs
applicationStreams
loading
error?
```

Detailed row and routing behaviour belongs to `AudioController`.

## 5.7 Operation-task state

Asynchronous operations must expose explicit task state rather than leaving the view to infer progress.

Conceptual task contract:

```text
id
kind
state               // queued, running, awaitingInput, succeeded, failed, cancelled
progressText?
canCancel
error?
startedAt
```

Used by:

- Wi-Fi radio changes;
- Bluetooth power changes;
- connection and pairing flows;
- Night Light changes;
- idle-inhibitor changes;
- session-opening or settings-opening failures where useful.

The main quick-control tile may show only compact busy/error state while the detail page exposes task depth.

---

# 6. Surface Geometry and Window Behaviour

## 6.1 Right-edge attachment

For a monitor geometry:

```text
monitorLeft
monitorTop
monitorWidth
monitorHeight
```

and resolved drawer width `drawerWidth`, conceptual placement is:

```text
openX   = monitorLeft + monitorWidth - drawerWidth
closedX = monitorLeft + monitorWidth
x       = lerp(closedX, openX, revealProgress)
```

Equivalent implementation may use clipping, translation, or layer-shell margins depending on the chosen Quickshell primitive.

The implementation must:

- remain bounded to the owning monitor;
- not straddle adjacent monitors;
- account for scale and transform through normalized logical geometry;
- keep the attached right edge visually flush;
- use rounded treatment primarily on the inward left corners;
- avoid permanent workspace reservation.

## 6.2 Width

The exact width remains unresolved.

Prototype range:

```text
380–420 logical pixels
```

The width prototype must test:

- long Wi-Fi SSIDs;
- long Bluetooth device names;
- notification titles, bodies, and actions;
- volume-mixer rows;
- text scaling;
- narrow laptop screens;
- vertical monitors;
- mixed scaling;
- translation and locale expansion.

The final implementation should support a validated explicit width or an `auto` policy from shared configuration, but it must impose safe minimum and maximum bounds.

Do not allow a configured width to consume an unreasonable fraction of a narrow monitor without adaptation.

## 6.3 Height and vertical anchoring

The control centre occupies the usable vertical extent of its selected monitor unless a later surface policy introduces safe margins.

It should not automatically avoid the persistent bar unless the chosen monitor geometry and layer-shell model require it. The right-edge drawer and a left-edge bar normally coexist without conflict.

If the bar is configured on the right edge, the control centre still belongs to the right edge. The collision and layering policy must be resolved explicitly rather than silently moving the control centre.

## 6.4 Scrim

The control centre may own or request a scrim through shared surface infrastructure.

Required scrim behaviour:

- covers only the owning monitor unless global policy later says otherwise;
- opacity follows reveal progress during direct manipulation;
- does not appear before drag intent is accepted;
- accepts outside-click dismissal when dismissal is allowed;
- sits below critical prompts and above ordinary application content;
- does not obscure the drawer;
- is disabled or modified when the selected Quickshell window strategy cannot support it reliably, with the limitation documented.

Exact maximum scrim opacity is a theme token or visual prototype decision.

## 6.5 Internal safe area

The drawer should expose internal content insets derived from shared spacing tokens.

Avoid:

- edge-to-edge text against the inward boundary;
- arbitrary per-page padding;
- nested card padding that compounds excessively;
- mobile-scale empty space.

The attached right edge may have smaller visual inset for surface framing, but actionable controls still require adequate hit targets.

---

# 7. Edge-Drag Interaction

## 7.1 Activation zone

Settled requirements:

- extreme right edge;
- invisible;
- no hover activation;
- primary-button press begins recognition;
- pointer reveal suppressed in true fullscreen by default.

Unresolved values:

- activation width;
- minimum movement;
- horizontal intent ratio;
- opening distance threshold;
- opening velocity threshold;
- closing threshold;
- settling duration.

Suggested activation widths to test:

```text
1 logical pixel
2 logical pixels
3–4 logical pixels
```

These are prototype candidates, not accepted defaults.

## 7.2 Recognition sequence

Conceptual sequence:

```text
Closed
  ↓ primary press begins in activation zone
PressedAtEdge
  ↓ horizontal intent accepted
DragIntentDetected
  ↓ direct manipulation
DraggingOpen
  ↓ release
SettlingOpen or SettlingClosed
```

Recognition should consider:

- horizontal displacement;
- vertical displacement;
- horizontal-to-vertical ratio;
- elapsed time;
- inward velocity;
- monitor validity;
- fullscreen suppression;
- whether another critical surface blocks opening.

Mostly vertical motion must not commit to opening.

## 7.3 Direct manipulation

Once intent is accepted:

- drawer position follows pointer displacement without a competing fixed-duration animation;
- reveal progress updates every relevant frame or event;
- scrim opacity follows reveal progress;
- panel content remains clipped to the panel bounds;
- internal controls do not become interactive until opening commits or an intentional interaction threshold is crossed;
- pointer capture and cancellation rules are explicit;
- expensive detail content may remain lazy or visually simplified until opening is committed.

The implementation should favour perceived directness over decorative easing.

## 7.4 Release decision

On release:

- open when reveal distance crosses the configured threshold;
- open when inward velocity crosses the configured threshold even if distance is lower;
- otherwise close;
- use a short settling transition;
- settle from the current visual position;
- never jump to the beginning of an animation;
- do not wait for animation completion before accepting a close request or critical prompt.

Opening and closing threshold symmetry is not assumed; it should be tested.

## 7.5 Drag-to-close

When open:

- an intentional drag toward the right edge may directly manipulate closure;
- small accidental motion snaps back open;
- sufficient distance or outward velocity settles closed;
- child-page state remains stable during the drag;
- unsafe prompts may block or modify drag closure;
- closing after a blocked interaction must not discard credentials or confirmations.

The exact region from which drag-to-close begins is not fully specified. The implementation may prototype dragging from the drawer background or an appropriate noninteractive region, but must not steal slider or list gestures.

## 7.6 Gesture arbitration

The control-centre drawer must not steal:

- vertical scrolling in notifications, mixer, network, or Bluetooth lists;
- horizontal slider manipulation;
- text selection or password-entry interaction;
- application input outside the activation strip before intent is accepted;
- adopted Hyprland trackpad gestures.

A future trackpad gesture should invoke the same normalized reveal controller only after gesture ownership is explicitly configured.

## 7.7 Debug instrumentation

Development mode should optionally expose:

- activation strip bounds;
- pointer start and current point;
- horizontal and vertical displacement;
- current intent ratio;
- velocity;
- reveal progress;
- selected release outcome;
- state-transition log;
- opening monitor.

Debug visuals must never ship enabled by default.

---

# 8. Main View Component Specifications

## 8.1 Header

The header must provide enough structure to identify the current page and expose required top-level entry points.

Settled requirements:

- nested pages show a back action and page title;
- settings and session/power entry points exist somewhere in the control-centre experience;
- header must not become a status dashboard;
- destructive session actions must not execute immediately from a small icon;
- all header actions require keyboard access and accessible names.

Unresolved header content includes:

- whether the main page shows a “Control Centre” title;
- network or connected-device summaries;
- DND state summary;
- settings placement;
- session placement;
- refresh action placement;
- profile/avatar presence;
- whether the main page has no secondary summary.

Codex may create a minimal placeholder header during Phase 3, but must isolate header content so it can change without restructuring the drawer.

## 8.2 Quick-controls section

Required controls and order:

```text
Wi-Fi
Bluetooth
Do Not Disturb
Night Light
Idle inhibitor
```

The exact visual geometry is unresolved.

Candidate layouts to prototype:

- one horizontal row;
- wrapping grid;
- compact icon row with selective labels;
- adaptive geometry based on width.

Requirements independent of layout:

- stable ordering;
- no layout movement when a control becomes busy;
- active state uses an accent container or equivalent strong state;
- inactive state remains neutral;
- unavailable state explains the missing capability;
- busy state prevents duplicate requests where required;
- focus ring remains visible on active tiles;
- labels and tooltips remain clear;
- hit targets do not become tiny to force five controls into one row.

## 8.3 Wi-Fi quick control

Actions:

- toggle Wi-Fi radio;
- open Network detail page.

Interaction contract:

- pointer must expose distinct toggle and detail actions;
- `Space` toggles when the tile or toggle action is focused;
- `Enter` performs the control's defined primary action;
- `Right` or explicit detail action opens Network;
- a running radio change exposes busy state;
- failure produces a system failure toast and inline indication where useful;
- absent Wi-Fi hardware or backend is represented as unavailable, not merely off.

The exact pointer split remains unresolved.

## 8.4 Bluetooth quick control

Actions:

- toggle Bluetooth adapter power;
- open Bluetooth detail page.

Interaction and state rules mirror Wi-Fi where applicable.

Additional rules:

- connected-device count may be secondary text, but the exact tile presentation is not settled;
- adapter absence is different from powered-off state;
- a pairing prompt is not owned by the quick tile;
- a running adapter operation cannot appear frozen.

## 8.5 Do Not Disturb quick control

Primary action:

- toggle DND.

Requirements:

- active state is prominent;
- DND means suppress interruption, not user feedback;
- tile state reflects the authoritative notification policy model;
- toggling produces a system toast;
- notification history remains available;
- OSDs and user-triggered failure feedback remain allowed;
- no separate detail page is required initially.

## 8.6 Night Light quick control

Primary action:

- toggle Night Light.

Requirements:

- use a normalized Night Light adapter;
- show busy and failure state;
- produce a system toast on a user-triggered change;
- no schedule/temperature detail page is required for the first prototype;
- backend absence is explained clearly.

## 8.7 Idle-inhibitor quick control

Primary action:

- toggle the shell-managed idle inhibitor.

Requirements:

- active state is clear;
- user-triggered changes produce a system toast;
- active state may surface in the bar's contextual region;
- the controller must distinguish shell-managed override from application-owned inhibitors if the backend exposes both;
- optional duration selection is later scope;
- backend absence is explained clearly.

## 8.8 Primary sliders section

Order should remain stable:

```text
Master volume
Brightness, when available
```

The section should preserve visual rhythm when brightness is omitted.

Each slider requires:

- leading semantic icon;
- accessible label;
- visible focus state;
- large drag target;
- inactive track and active fill;
- keyboard step adjustment;
- hover-scroll adjustment;
- one updating OSD;
- no drawer dismissal on value change.

Whether numeric percentage is always shown remains a child-feature visual decision. Accessible value text is mandatory.

## 8.9 Tab row

Initial tabs and order:

```text
Notifications
Volume Mixer
```

Pointer:

- primary click selects tab.

Keyboard:

- `Left` and `Right` move between tabs when the tab row owns focus;
- `Enter` or `Space` selects when movement does not auto-select;
- focus enters the active page predictably;
- `Tab` moves between major control groups in reading order.

Tab selection must not reset page scroll or mixer state unnecessarily.

## 8.10 Notifications tab host

The host must provide:

- a viewport for grouped application notifications;
- stable scroll behaviour when new items arrive;
- empty state;
- loading and service-error state;
- clear-all entry point when supported;
- keyboard focus entry;
- no global unread badge.

The detailed notification card, grouping, clear-all, undo, action, progress, and retention rules belong to `docs/features/notifications.md`.

The control-centre host must not log notification content.

## 8.11 Volume Mixer tab host

The host must provide:

- lazy loading;
- output and input device sections as specified by the audio feature;
- per-application rows;
- stable scroll state;
- empty/no-stream state;
- backend unavailable and reconnecting states;
- keyboard focus entry.

The control centre must not create a second audio model separate from the compact audio popover or bar controller.

## 8.12 Network detail page host

The Network page replaces the main drawer content.

The host provides:

- nested page frame;
- back navigation;
- page title;
- page lifecycle and lazy loading;
- focus restoration;
- safe close blocking when a credential prompt requires explicit handling.

Network capabilities and interactions belong to `docs/features/network-and-bluetooth.md`.

## 8.13 Bluetooth detail page host

The Bluetooth page follows the same nested-page host contract.

Pairing prompts and confirmation flows must not be silently dismissed by outside click or drawer close. Their exact critical-surface integration belongs to the Bluetooth and notification/prompt specifications.

## 8.14 Settings entry point

Requirements:

- opens the shell settings surface through shared coordination or configured command;
- does not embed a second settings implementation inside the control centre unless a later decision says so;
- failure is shown as a system error toast;
- opening settings closes or replaces the control centre according to `SurfaceCoordinator` policy.

Exact placement remains unresolved.

## 8.15 Session entry point

Requirements:

- opens a deliberate session surface;
- does not execute shutdown, reboot, or logout immediately;
- delegates confirmation and action execution to the session feature;
- remains keyboard accessible;
- failure is visible and non-destructive.

Exact placement and whether it is Phase 6 or near-term remain partially unresolved.

---

# 9. Keyboard and Pointer Interaction

## 9.1 Keyboard opening

When opened through a keyboard shortcut:

- request the correct monitor from `SurfaceCoordinator`;
- acquire keyboard focus immediately after the surface is ready;
- prevent typing from leaking into the previously focused application;
- show a visible focus indicator;
- choose a deterministic initial focus target;
- store enough prior focus context for restoration.

Default initial focus:

1. a recently focused safe control when reopening within the accepted restoration window;
2. otherwise the first quick control in the main Notifications view.

The exact restoration timeout remains unresolved.

When opening directly to an explicit page through IPC or a future command, focus the first safe actionable control on that page.

## 9.2 Pointer opening

When opened through edge drag:

- do not steal keyboard focus during early uncommitted recognition;
- after opening commits, pointer interaction is immediately available;
- keyboard focus may remain with the previous application until the user begins keyboard navigation, if the chosen Quickshell primitive supports this without input leakage;
- once keyboard navigation begins, establish visible focus inside the drawer;
- preserve the opening monitor as owner for the lifetime of the open drawer unless hotplug invalidates it.

Exact focus semantics for pointer-opened layer-shell windows must be validated in the Quickshell prototype.

## 9.3 Directional navigation

- Quick-control row or grid follows physical arrow direction.
- Disabled and unavailable controls may receive focus only when doing so is necessary to expose an explanation; otherwise skip them.
- Tab row uses `Left` and `Right`.
- Lists use `Up` and `Down`.
- `Right` enters a detail page where spatially appropriate.
- `Left` may return from a detail page when it does not conflict with a child control.
- Sliders use `Left`/`Down` to decrease and `Right`/`Up` to increase.
- `PageUp`, `PageDown`, `Home`, and `End` may be supported where the child feature considers them safe.

## 9.4 Activation keys

- `Enter` invokes the focused control's primary action.
- `Space` toggles focused toggles.
- An explicit detail subcontrol or `Right` opens Wi-Fi/Bluetooth details.
- `Escape` follows deepest-first cancellation and back behaviour.

Do not overload one key with two hidden actions on the same focused target.

## 9.5 Tab traversal

Suggested major traversal order on the main page:

```text
Header actions
→ Quick controls
→ Volume slider
→ Brightness slider, if present
→ Tab row
→ Active tab content
```

The exact header action order follows the eventual header decision.

`Shift+Tab` reverses the sequence.

Arrow navigation is preferred inside groups; `Tab` moves across groups.

## 9.6 Pointer controls

- Primary click performs the visible primary action.
- Secondary click is not required for any essential action.
- Hover may expose tooltip or secondary metadata but not essential controls.
- Sliders support direct drag.
- Lists support scrolling.
- Outside click dismisses only when no protected operation blocks it.
- Quick-control busy state prevents accidental duplicate requests.

## 9.7 Scroll arbitration

- Scroll over volume adjusts volume.
- Scroll over brightness adjusts brightness.
- Scroll over notification, mixer, network, or Bluetooth list scrolls the list.
- A child scrollable item has priority over any drawer-level gesture.
- Drag-to-close must not start from slider manipulation or normal vertical scrolling.
- Rapid slider scrolling updates one OSD.

## 9.8 Accessibility

Every actionable element requires:

- accessible role;
- accessible name;
- current state;
- value text where applicable;
- available/unavailable explanation;
- focus indication;
- keyboard activation.

State must not rely only on colour or animation.

Text scaling must not cause controls to overlap or make the back action unreachable.

Reduced motion must replace nonessential sliding page transitions with immediate or short cross-state changes while keeping direct pointer dragging direct.

---

# 10. Opening, Dismissal, and Focus Behaviour

## 10.1 Surface coordination

All opening and closing requests go through `SurfaceCoordinator`.

Opening the control centre must:

- close any ordinary bar popover;
- close or coordinate with ordinary menus owned by the shell;
- avoid duplicating notifications as popups when Notifications are visible;
- respect critical prompts that may remain above it;
- record the previously focused application;
- resolve one owning monitor.

Opening quickshell-overview or Vicinae should close the control centre unless a later explicit integration policy says otherwise.

## 10.2 Toggle behaviour

- Keyboard shortcut while closed → open.
- Same shortcut while open → close.
- IPC toggle while closed → open on resolved monitor.
- IPC toggle while open → close.
- Explicit `openControlCenter(page)` while already open → navigate to requested page rather than closing.

## 10.3 Outside click

Outside click closes the drawer when:

- the root or ordinary detail page is active;
- no protected operation would be discarded;
- the scrim can receive the event reliably.

Outside click must not silently discard:

- Wi-Fi password entry;
- Bluetooth pairing code or confirmation;
- authentication prompt;
- destructive confirmation;
- unsaved settings draft, if settings later render inside the drawer;
- an operation that explicitly requires cancellation.

For protected state, outside click should be ignored or routed to an explicit discard/cancel flow defined by the child feature.

## 10.4 Escape stack

`Escape` order:

1. cancel an active text edit, menu, confirmation, pairing prompt, or credential prompt where safe;
2. close a child modal owned by the active page;
3. pop the nested detail page to main;
4. close the control centre;
5. restore focus to the previous valid application window.

One `Escape` must not skip all levels.

## 10.5 Back action

The visible back action on a nested page:

- follows the same protected-operation policy as `Escape`;
- returns to main;
- restores focus to the invoking quick control;
- does not close the drawer unless main is already active.

## 10.6 Drag dismissal

Drag-to-close follows the same protected-operation policy as outside click.

If closure is blocked:

- the drawer returns to open state;
- the reason is visible or announced;
- no credential or confirmation is lost;
- no repeated oscillating animation occurs.

## 10.7 Focus restoration

When the drawer closes:

- restore focus to the previously focused application/window;
- if it no longer exists, focus the most recent valid window on the current workspace;
- never leave focus on an invisible QML item;
- clear stale focus references;
- close or detach page-local focus scopes safely.

If another major surface opens immediately, focus transfers to that surface instead of briefly returning to the application.

## 10.8 Fullscreen

Settled:

- pointer edge reveal is suppressed during true fullscreen by default.

Unresolved:

- whether explicit keyboard opening is always allowed, configurable, confirmed, or disabled during fullscreen.

Implementation requirement:

- consume one normalized fullscreen state from the Hyprland adapter;
- do not infer fullscreen independently in the activation host;
- maximized windows are not fullscreen;
- log suppression reason in debug diagnostics without noisy user toasts.

---

# 11. Service and Integration Dependencies

## 11.1 Required core dependencies

### `SurfaceCoordinator`

Provides:

- opening and closing;
- monitor ownership;
- conflict resolution;
- scrim policy;
- focus restoration;
- critical-surface precedence.

### `MonitorRegistry`

Provides:

- connected monitors;
- logical geometry;
- scale;
- transform;
- focused-window monitor;
- pointer/invocation monitor where available;
- per-monitor eligibility.

### `HyprlandService`

Provides:

- normalized true fullscreen state;
- focused monitor and window context required by monitor resolution.

### `ThemeManager`

Provides:

- surface roles;
- text roles;
- accent roles;
- focus roles;
- spacing, radius, and motion tokens;
- reduced-motion and contrast settings.

### `ConfigService`

Provides validated control-centre configuration and retains last valid state on reload failure.

### `CapabilityRegistry`

Provides capability and availability summaries.

### `Diagnostics`

Collects host, drag, page-loading, and backend health errors.

## 11.2 Child feature dependencies

- `NotificationController` and notification history model;
- `AudioController`;
- `NetworkController`;
- `BluetoothController`;
- `BrightnessController`;
- `NightLightController`;
- `IdleInhibitorController`;
- `SessionController` or session-surface adapter;
- settings-opening integration;
- toast publisher;
- OSD publisher.

The control centre should operate in degraded form when one or more of these are unavailable.

## 11.3 External system dependencies

Through adapters only:

- Freedesktop notification protocol clients/server integration;
- PipeWire / WirePlumber;
- NetworkManager or selected backend;
- BlueZ;
- brightness backend;
- selected Night Light implementation;
- idle daemon / Hyprland idle-inhibit integration;
- systemd-logind or configured session backend;
- Polkit or authentication surfaces where child operations require them.

## 11.4 Configuration consumed

Conceptual configuration fields:

```text
controlCenter.enabled
controlCenter.edge                 // initial supported value: right
controlCenter.width
controlCenter.defaultPage          // notifications
controlCenter.restoreLastPageForMs
controlCenter.edgeDrag.enabled
controlCenter.edgeDrag.activationWidth
controlCenter.edgeDrag.minimumDistance
controlCenter.edgeDrag.openThreshold
controlCenter.edgeDrag.velocityThreshold
controlCenter.edgeDrag.horizontalIntentRatio
controlCenter.edgeDrag.allowInFullscreen
controlCenter.quickControls
controlCenter.sliders
controlCenter.tabs
controlCenter.scrim.enabled
controlCenter.scrim.dismissOnClick
```

Important:

- example values in `configuration-model.md` are proposed schema values, not all accepted tuning decisions;
- raw drag thresholds should remain internal or advanced until prototype testing;
- initial settings UI should expose meaningful presets rather than every low-level number;
- control-centre edge remains right in the initial design;
- configuration reload must not interrupt an active protected operation without explicit handling.

## 11.5 IPC contract

Suggested versioned requests:

```text
openControlCenter(monitor?, page?)
closeControlCenter()
toggleControlCenter(monitor?)
openNotifications(monitor?)
openNetworkPage(monitor?)
openBluetoothPage(monitor?)
```

Exact IPC types depend on the pinned Quickshell baseline.

IPC must:

- reject unknown pages cleanly;
- resolve monitor deterministically;
- remain compatible with Vicinae extension commands;
- report structured failure;
- never expose backend-specific command strings.

---

# 12. Error and Unavailable States

## 12.1 General rules

- One backend failure must not prevent the drawer from opening.
- Capability absence and runtime failure are different states.
- Unsupported controls should normally be omitted when their absence is permanent and unsurprising.
- A required control with a temporarily failed backend may remain visible with a clear degraded state.
- Errors should be concise in the main view and expandable through details or diagnostics.
- User-triggered failures should produce an appropriate system failure toast.
- Successful state changes produce brief confirmation toasts.
- Notification bodies, passwords, pairing codes, and secrets must never enter logs.

## 12.2 Host/window failure

If the selected Quickshell window primitive cannot provide required behaviour:

- fail the Phase 3 prototype acceptance gate;
- record the exact limitation;
- test an alternative primitive or coordinated-window strategy;
- do not hide the limitation behind brittle focus hacks without documentation;
- do not proceed to extensive child-feature implementation until opening, closing, focus, and direct manipulation are reliable.

## 12.3 Notification service unavailable

Notifications tab should show:

- clear unavailable or reconnecting state;
- diagnostics or repair entry point where useful;
- no fake empty-history state;
- no global unread count.

Other control-centre functions remain usable.

## 12.4 Audio unavailable

- Hide or disable the volume slider according to whether failure is permanent or transient.
- Volume Mixer tab shows backend unavailable state rather than an empty mixer.
- Other control-centre features remain usable.
- Do not create repeated retry processes from QML delegates.

## 12.5 Brightness unavailable

- Omit brightness slider when no target exists.
- Show a temporary degraded state only when a previously available target disappears during the session.
- Do not reserve permanent empty space.

## 12.6 Network unavailable

Distinguish:

- no NetworkManager/backend;
- no Wi-Fi hardware;
- Wi-Fi radio off;
- network service reconnecting;
- operation failed.

Network detail action may remain available to show explanation and advanced-settings delegation even when the toggle cannot operate.

## 12.7 Bluetooth unavailable

Distinguish:

- no BlueZ/backend;
- no adapter;
- adapter powered off;
- service reconnecting;
- operation failed.

## 12.8 Night Light or idle inhibitor unavailable

- Tile shows unavailable state or is omitted according to capability policy.
- Tooltip or focused help explains the missing service.
- Failure does not affect other quick controls.

## 12.9 Settings or session integration unavailable

- Entry point remains safe.
- Activation produces a compact actionable error.
- No destructive fallback command is assembled in QML.

## 12.10 Page-load failure

A lazily loaded child page may fail independently.

The page frame must provide:

- page title;
- error summary;
- Retry when safe;
- Back action;
- diagnostics reference;
- no crash or blank drawer.

## 12.11 Diagnostics

Record without secrets:

- chosen window primitive;
- window/layer configuration;
- owning monitor;
- open source;
- state-machine transitions in debug mode;
- threshold values used;
- failed page loads;
- focus-acquisition failures;
- outside-click/scrim limitations;
- child capability summaries;
- last successful open and close;
- recoverability.

---

# 13. Multi-Monitor Considerations

## 13.1 Provisional architecture

The architecture may create a `ControlCenterHost`, `EdgeActivationHost`, and `ScrimHost` per eligible monitor, while exposing only one globally open control centre at a time.

The final multi-monitor product policy is unresolved.

Current recommended baseline for later validation:

- one global open control centre;
- pointer drag opens on the monitor where the edge press begins;
- keyboard invocation opens on the focused-window monitor;
- if no focused-window monitor is available, use the configured fallback monitor;
- per-monitor activation hosts exist only where control-centre use is enabled;
- state such as DND is shared globally;
- viewport and focus state may be per monitor or per invocation as explicitly designed.

This remains provisional until `docs/features/multi-monitor.md` is completed.

## 13.2 Ownership resolution

Opening request must resolve one normalized monitor ID before creating or revealing the drawer.

Resolution inputs may include:

- pointer-origin monitor;
- focused-window monitor;
- explicit IPC monitor;
- configured primary/fallback monitor;
- currently open owner.

Do not infer monitor ownership independently in the view.

## 13.3 Adjacent monitors

A right-edge activation strip may coincide with the boundary to another monitor.

Test:

- monitor to the immediate right;
- mismatched vertical alignment;
- different scale factors;
- gaps between monitor geometries;
- pointer crossing between monitors;
- transformed monitors.

The shell must not create an activation zone that makes normal movement to an adjacent monitor unreliable.

If a monitor's right edge is not an outer desktop boundary, product policy may need to disable edge drag there or use another criterion. This is unresolved.

## 13.4 Mixed scale and rotation

Test at minimum:

- scale `1.0`;
- representative fractional scale;
- mixed scales;
- portrait monitor;
- transformed output;
- hotplug while closed;
- hotplug while open;
- owner monitor removal during drag.

Use normalized logical coordinates from `MonitorRegistry`.

## 13.5 Hotplug behaviour

If owner monitor disappears:

- cancel an in-progress drag safely;
- close or migrate the drawer according to one documented policy;
- never leave an invisible focus owner;
- preserve safe global state;
- do not migrate credential or pairing prompts without explicit child-feature support;
- restore focus to a valid remaining window or surface.

Final migration policy is deferred to the multi-monitor specification.

## 13.6 Scrim scope

Initial expectation is a scrim on the owning monitor only.

Global multi-monitor scrim behaviour is not settled and should not be implemented by accident.

---

# 14. Performance Considerations

## 14.1 Highest-priority performance goal

During direct manipulation, drawer position must follow the pointer without visible lag.

The Phase 3 prototype should measure:

- input-to-visual latency;
- frame consistency;
- dropped frames;
- time to first open;
- time to keyboard focus;
- settle animation smoothness;
- effect of scrim and blur;
- effect of lazy page creation.

## 14.2 Lazy loading

Lazily create:

- Notifications tab depth beyond the required initial viewport where feasible;
- Volume Mixer tab;
- Network page;
- Bluetooth page;
- settings/session surfaces;
- expensive device lists.

The drawer shell, quick controls, primary sliders, and tab frame should be ready quickly.

Do not create all child pages at startup merely to avoid a small first-open delay.

## 14.3 Hidden-state work

When closed:

- no drawer animations run;
- no view-specific polling runs;
- list delegates are not continuously updating offscreen;
- notification, audio, network, and Bluetooth services may maintain their own necessary event-driven state;
- high-frequency mixer or scanning updates occur only when the relevant surface is open or operation requires them.

## 14.4 Direct-drag rendering

During drag:

- avoid relayout of the entire content tree on every pointer event;
- animate a transform or clipped surface rather than reconstructing delegates;
- avoid blur if it causes frame instability;
- keep shadow/elevation effects inexpensive;
- coalesce pointer updates only if latency remains imperceptible;
- do not synchronously query services.

## 14.5 List performance

Notification, mixer, network, and Bluetooth lists should use model/delegate patterns that:

- avoid rebuilding the entire model for one item update;
- preserve stable IDs;
- preserve scroll position;
- recycle or lazily instantiate delegates where supported;
- avoid binding loops;
- avoid image decoding on the UI-critical path;
- limit animation for high-frequency updates.

## 14.6 Service operations

- All backend commands are asynchronous.
- No QML delegate blocks on a process or D-Bus call.
- Repeated toggle requests are deduplicated or serialized by controllers.
- Scanning and telemetry rates are reduced when pages are hidden.
- Service reconnect does not require recreating the whole control-centre window.

## 14.7 Theme and motion

- Theme changes apply atomically.
- No flash of unstyled drawer content.
- Reduced motion disables nonessential page and settle animation while preserving direct manipulation.
- High-contrast mode must not add expensive per-frame effects.

## 14.8 Performance acceptance recording

Before daily-use completion, record:

- idle CPU impact with drawer closed;
- memory cost before and after first opening each lazy page;
- open latency;
- drag smoothness on the user's laptop display and external monitor;
- list performance under a large notification history and many audio streams;
- impact of mixed scaling.

Exact numeric budgets should be set after the Quickshell baseline is pinned and measured.

---

# 15. Implementation Phases

## 15.1 Phase 1 — Core shell prerequisites

Required before control-centre work:

- `ConfigService`;
- `ThemeManager`;
- `MonitorRegistry`;
- `SurfaceCoordinator`;
- `CommandRegistry`;
- `CapabilityRegistry`;
- diagnostics;
- fixture mode;
- shell IPC skeleton.

Exit condition:

- a placeholder major surface can open on a resolved monitor, acquire focus, close, and restore focus through shared coordination.

## 15.2 Phase 3 — Control-centre mechanics

Implement only enough content to validate the highest-risk interaction.

Required:

- one candidate control-centre window strategy;
- edge activation host;
- reveal state machine;
- pointer-following direct manipulation;
- settle open/close;
- scrim;
- outside click;
- keyboard opening;
- focus acquisition and restoration;
- internal page stack;
- placeholder header;
- placeholder quick controls;
- placeholder volume and brightness sliders;
- Notifications and Volume Mixer tabs;
- placeholder Network and Bluetooth pages;
- debug threshold visualization.

Critical stop condition:

> Do not proceed into extensive child-feature implementation until edge dragging, focus, outside click, and dismissal are reliable.

## 15.3 Phase 4 — Core adapters

Connect normalized real state incrementally:

- audio;
- brightness;
- network;
- Bluetooth;
- Hyprland fullscreen;
- capability registry.

At this stage:

- quick controls may become functional;
- sliders become functional;
- nested pages may still be basic;
- each adapter must fail independently.

## 15.4 Phase 5 — Notifications and feedback

Integrate:

- notification history;
- grouped Notifications tab;
- DND;
- suppression of duplicate popup while Notifications are visible;
- system toasts for quick-control actions;
- volume and brightness OSDs.

## 15.5 Phase 6 — Daily-use completion

Complete:

- real quick controls;
- real primary sliders;
- Notifications tab;
- functional Volume Mixer tab at initial scope;
- basic Network page;
- basic Bluetooth page;
- settings and session entry-point behaviour appropriate to available features;
- unavailable-state handling;
- daily-use focus and dismissal reliability.

## 15.6 Phase 9 — Settings

Expose meaningful settings such as:

- width or width preset;
- edge-drag enabled;
- edge-drag responsiveness preset;
- fullscreen policy after it is settled;
- quick-control availability/order only if later product decisions permit it;
- text scale and reduced motion.

Avoid exposing every raw threshold initially.

## 15.7 Phase 10 — Multi-monitor and gesture hardening

Complete:

- monitor ownership policy;
- outer-edge policy;
- hotplug;
- mixed scale;
- rotation;
- one-global-drawer behaviour;
- optional trackpad gesture integration;
- conflict detection with Hyprland gestures.

## 15.8 Phase 11 — Visual and accessibility polish

Complete:

- final width;
- header composition;
- quick-control geometry;
- scroll/sticky policy;
- motion tokens;
- edge-aware corners;
- focus audit;
- text scaling;
- high contrast;
- reduced motion;
- wallpaper-set readability testing.

---

# 16. Acceptance Criteria

## 16.1 Phase 3 mechanics acceptance

- Drawer attaches to the right edge of the resolved monitor.
- Drawer does not reserve permanent workspace space.
- A drag beginning outside the activation strip does nothing.
- Hover does not open the drawer.
- Mostly vertical movement does not commit opening.
- Small horizontal movement settles closed.
- Sufficient inward distance or velocity settles open.
- Drawer follows pointer movement without visible lag after intent is accepted.
- Scrim follows reveal progress.
- Dragging back toward the right can close the drawer without conflicting with sliders or list scrolling.
- Keyboard shortcut opens and closes the drawer.
- Drawer acquires keyboard focus reliably when keyboard-opened.
- `Escape` returns from a placeholder detail page before closing the drawer.
- Outside click closes the ordinary main view.
- Focus returns to the previously focused application after close.
- Pointer edge reveal is suppressed in true fullscreen.
- Maximized windows do not trigger fullscreen suppression.
- Opening the drawer closes an open bar popover.
- Window primitive and limitations are documented.

## 16.2 Main-view acceptance

- Main view defaults to Notifications.
- Five settled quick controls are represented in stable order.
- Volume remains available above tabs when audio is supported.
- Brightness appears only when supported.
- Sliders support pointer drag, hover scroll, and keyboard adjustment.
- Slider changes do not close the drawer.
- Notifications and Volume Mixer tabs are keyboard and pointer accessible.
- Focus and selection are visually distinct.
- Nested Network and Bluetooth pages remain inside the drawer.
- Back and `Escape` restore focus to the invoking control.
- Header remains structurally replaceable pending final composition.
- No global notification unread count appears.

## 16.3 Adapter-integration acceptance

- Each backend can fail without preventing the drawer from opening.
- Wi-Fi off, no Wi-Fi hardware, and network backend unavailable are distinct.
- Bluetooth off, no adapter, and Bluetooth backend unavailable are distinct.
- Audio backend absence produces a clear mixer/slider state.
- Brightness absence removes the slider cleanly.
- User-triggered quick-control changes produce system toasts.
- Volume and brightness changes update one OSD.
- No backend-specific command is issued from view QML.
- Long-running operations expose progress and cancellation where supported.
- Secrets and notification content are absent from logs.

## 16.4 Notification integration acceptance

- New notifications enter drawer history.
- Grouping is provided by the notification feature.
- No duplicate ordinary popup appears while the drawer is open to Notifications.
- DND suppresses ordinary popups/sounds but preserves drawer history.
- Notification list retains stable scroll behaviour as new items arrive.
- Empty, loading, unavailable, and failed states are distinct.

## 16.5 Daily-use acceptance

- The drawer can manage ordinary Wi-Fi and Bluetooth tasks without opening a full settings application.
- Per-application audio controls are usable at initial mixer scope.
- All major workflows are usable by keyboard and pointer.
- Protected prompts are not discarded by outside click, drag close, or one `Escape`.
- Reopening follows the documented restoration policy.
- One normal workday produces no blocker-level focus, stuck-surface, accidental-reveal, or gesture-conflict issue.
- Idle resource use with the drawer closed is measured and recorded.

## 16.6 Multi-monitor acceptance

- Pointer invocation opens on the correct monitor according to final policy.
- Keyboard invocation opens on the correct monitor according to final policy.
- Only one global drawer is open.
- Adjacent-monitor boundaries do not make pointer travel unreliable.
- Mixed scaling does not distort width, hit targets, or drag distance.
- Portrait output remains usable.
- Owner-monitor hotplug does not leave invisible focus.

## 16.7 Accessibility and visual acceptance

- Drawer remains readable across representative wallpaper palettes.
- Opaque surface and text contrast remain sufficient.
- Focus is always visible.
- Active state does not rely on colour alone.
- Text scaling does not overlap tiles, sliders, tabs, or back action.
- Reduced motion preserves all interaction meaning.
- Pointer targets meet the intended size range.
- No animation delays input.

---

# 17. Test Fixtures

Fixture mode should provide deterministic scenarios independent of live services.

Minimum fixture scenarios:

1. Drawer closed.
2. Drawer half revealed by drag.
3. Drawer opening by velocity threshold.
4. Drawer snapping closed below threshold.
5. Mostly vertical edge motion rejected.
6. Fullscreen pointer reveal suppressed.
7. Keyboard open on main Notifications view.
8. Reopen with recent focus restoration.
9. Long-closed reopen returning to Notifications.
10. Network nested page.
11. Bluetooth nested page.
12. Protected Wi-Fi password prompt blocking outside close.
13. Protected Bluetooth confirmation blocking drag close.
14. All quick controls inactive.
15. All quick controls active where logically possible.
16. Wi-Fi unavailable.
17. Bluetooth adapter absent.
18. Night Light backend unavailable.
19. Idle inhibitor busy and failed.
20. Audio backend unavailable.
21. Brightness unsupported.
22. Many grouped notifications.
23. No notification history.
24. Notification service reconnecting.
25. Many application audio streams.
26. No active audio streams.
27. Long SSIDs and device names.
28. Large text scale.
29. Reduced motion.
30. High contrast.
31. Narrow monitor.
32. Portrait monitor.
33. Fractional scale.
34. Adjacent monitor on right edge.
35. Owner monitor removed while open.
36. Theme change while open.
37. Configuration reload while open.
38. Child page lazy-load failure.
39. Settings integration unavailable.
40. Session integration unavailable.

Development fixtures should make reveal progress and state transitions directly adjustable.

---

# 18. Unresolved Questions

The following items remain unresolved. Codex must not convert prototype convenience into product policy.

## 18.1 Window primitive

- Which exact Quickshell window primitive or coordinated set best satisfies right-edge attachment, no exclusive zone, focus, direct drag, outside click, scrim, layer ordering, fullscreen policy, and mixed-monitor behaviour?
- Can one window provide both reliable direct manipulation and keyboard focus?
- Is a separate scrim window required?
- How does the choice behave across Quickshell reload?

This is a blocker for completing Phase 3.

## 18.2 Activation width

- Is `1`, `2`, or `3–4` logical pixels reliable?
- How does fractional scaling affect the physical target?
- What happens at an internal monitor boundary?
- How much application input is stolen near browser/editor scrollbars?

## 18.3 Drag thresholds

Need measured values for:

- minimum movement;
- horizontal intent ratio;
- open-distance threshold;
- opening velocity;
- close-distance threshold;
- closing velocity;
- settling duration.

Do opening and closing need asymmetric thresholds?

## 18.4 Keyboard opening during fullscreen

Should explicit keyboard invocation:

- always open;
- require confirmation;
- remain disabled by default;
- be configurable?

Current recommendation in the baseline is to allow explicit keyboard opening, but it is not accepted.

## 18.5 Exact width

- Final logical width within or outside `380–420`?
- Fixed, adaptive, or per-monitor?
- Safe maximum fraction of narrow monitor width?
- How should portrait monitors adapt?

## 18.6 Header content

Which of the following belong in the main header:

- title;
- network summary;
- connected-device summary;
- DND summary;
- settings action;
- session action;
- refresh action;
- avatar/profile;
- no secondary summary?

The header must not become a status dashboard.

## 18.7 Quick-control geometry

- One row, wrapping grid, compact icon row, or adaptive layout?
- Which labels are always visible?
- How should five controls fit without tiny targets?
- How does the layout expand if future controls are added?

## 18.8 Toggle/detail split

For Wi-Fi and Bluetooth:

- main body toggles and chevron opens details;
- icon toggles and body opens details;
- primary click opens details and secondary click toggles;
- another explicit split?

Requirements already settled:

- both actions exist;
- keyboard parity exists;
- no tiny inaccessible target;
- no long-press-only or hover-only essential action.

## 18.9 Main-view scroll behaviour

When notifications are long, do quick controls and sliders:

- remain pinned;
- scroll away;
- collapse into a compact sticky header;
- become sticky only after scrolling?

The baseline only settles that they belong above the tabs conceptually.

## 18.10 State restoration

Need exact policy for:

- active tab;
- last focused control;
- notification scroll position;
- open notification group;
- mixer scroll position;
- selected mixer device;
- nested page;
- safe task state;
- restoration timeout.

Unsafe credentials and confirmations must not be restored.

The `15000 ms` example in configuration is not an accepted decision.

## 18.11 Pointer-open focus

- Should a pointer-opened drawer immediately take keyboard focus?
- Can it remain pointer-active without stealing typing until keyboard navigation begins?
- What does the selected Quickshell primitive permit reliably?

## 18.12 Drag-to-close region

- May dragging start anywhere on noninteractive background?
- Is a dedicated internal region needed?
- How is it distinguished from horizontal child gestures?
- How should it behave while on a nested page?

## 18.13 Session and settings entry points

- Exact location in header or body?
- Is session menu required in the first daily-use prototype or near-term?
- Does opening settings close the drawer or replace its content?

## 18.14 Multi-monitor policy

- Which monitors receive activation hosts?
- Are only outer desktop right edges eligible?
- What happens when another monitor is directly to the right?
- Can each monitor host a dormant control-centre window while only one is open?
- What happens on owner-monitor removal?
- Is scrim per-monitor or global?

## 18.15 Notification/main-view integration

- Exact sticky-scroll relationship between controls and notification history?
- Does opening directly to Notifications restore an expanded group?
- How is clear-all exposed?
- Does clear-all support undo or confirmation?

These detailed policies belong primarily to the notification specification but affect control-centre layout.

## 18.16 Volume Mixer depth

- Which device selectors remain in the main mixer tab versus an audio detail surface?
- How rich is the Phase 6 mixer?
- How does it handle many streams and routing?

These belong primarily to the audio specification.

## 18.17 Trackpad gesture

- Which finger count and direction?
- Does Hyprland or the shell own it?
- Can it directly manipulate reveal progress?
- How are gesture conflicts detected?

This is not a Phase 3 dependency.

---

# 19. Codex Implementation Guardrails

Codex must follow these rules while implementing the control centre:

1. Do not choose the final Quickshell window primitive without a minimal comparative prototype.
2. Do not hard-code accepted status onto example width or drag-threshold values.
3. Do not create hover opening.
4. Do not reserve a permanent exclusive zone.
5. Do not move the control centre away from the right edge because the bar changes edge.
6. Do not implement Network or Bluetooth as detached tiny popups.
7. Do not import backend-specific services directly into quick-control or slider delegates.
8. Do not run `nmcli`, `bluetoothctl`, audio commands, brightness commands, or shell strings from view QML.
9. Do not create a second notification history or audio model inside the control-centre feature.
10. Do not allow one failed backend to prevent the drawer from opening.
11. Do not treat unavailable, inactive, disabled, busy, and failed as the same state.
12. Do not silently discard credentials, pairing prompts, confirmations, or protected operations on outside click, drag close, or `Escape`.
13. Do not let one `Escape` collapse the entire interaction stack.
14. Do not leave focus on an invisible QML item.
15. Do not create all nested pages eagerly at startup.
16. Do not block the UI thread on service calls or process execution.
17. Do not log notification contents, Wi-Fi secrets, pairing codes, or authentication data.
18. Do not add a global notification unread count.
19. Do not turn the header into an unapproved status dashboard.
20. Do not expose tiny toggle/detail hit targets merely to fit five controls in one row.
21. Do not let drawer-level drag handling steal slider or list gestures.
22. Do not infer fullscreen or monitor ownership separately in multiple components.
23. Do not enable pointer edge reveal over true fullscreen by default.
24. Do not assume pointer-open focus behaviour; test it with the chosen Quickshell primitive.
25. Do not proceed past Phase 3 mechanics while direct drag, focus, dismissal, and outside-click behaviour remain unreliable.
26. Record any new product decision in `decisions.md` and any unresolved limitation in `open-questions.md` before relying on it elsewhere.

