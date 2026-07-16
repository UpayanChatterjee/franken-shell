# Franken Shell — Interaction Language

> **Status:** Working design baseline  
> **Purpose:** Define the shared interaction rules for keyboard, mouse, trackpad, touch-like dragging, focus, navigation, dismissal, and feedback  
> **Related documents:** `product-vision.md`, `design-principles.md`, `feature-map.md`

This document defines the interaction grammar used across Franken Shell.

Every feature-specific specification should follow these rules unless it explicitly documents a justified exception. The goal is for the shell to feel predictable even when different surfaces are implemented by different QML modules or adapted from external projects.

---

# 1. Interaction Goals

The shell should feel:

- **fast:** common actions complete with minimal indirection;
- **precise:** the same input produces the same category of result everywhere;
- **discoverable:** pointer users can understand the interface without memorizing all shortcuts;
- **keyboard-first:** all major workflows remain efficient without a pointer;
- **pointer-complete:** mouse and trackpad interaction are not second-class;
- **spatially coherent:** surfaces move from and return to predictable edges;
- **stable:** layouts and focus do not jump unexpectedly;
- **forgiving:** accidental gestures and destructive actions are contained.

---

# 2. Input Priority

The intended priority order is:

1. keyboard;
2. mouse;
3. trackpad gestures.

This is a priority of optimization, not availability.

Every major workflow must have:

- a keyboard path;
- a pointer path;
- an optional gesture path where appropriate.

No essential action may exist only as:

- a hidden gesture;
- a hover-only action;
- a right-click-only action;
- an undocumented shortcut.

---

# 3. Shared Input Vocabulary

## 3.1 Primary click

Primary click should perform the most common direct action.

Examples:

- workspace number → switch workspace;
- audio item → open audio popover;
- resource indicator → open resource popover;
- battery value → open power panel;
- date/time → open calendar;
- tray affordance → open tray drawer;
- Vicinae button → toggle Vicinae;
- notification → focus, expand, or invoke its primary action;
- quick-control main area → toggle state.

Primary click should not open an unrelated settings application when an in-shell surface exists for the common task.

---

## 3.2 Secondary click

Secondary click should expose additional actions, alternative entry points, or context.

Examples:

- Vicinae button → direct-entry shortcut menu;
- active workspace number → focused-window action menu;
- tray item → application-provided context menu;
- notification → optional contextual actions if the protocol does not already expose them visibly;
- quick-control tile → detail page where no split affordance is shown.

Secondary-click actions must also be reachable through keyboard navigation.

Secondary click should not be required for a feature's only meaningful action.

---

## 3.3 Middle click

Middle click should be used only for compact, reversible, high-confidence toggles.

Approved initial examples:

- audio item → mute or unmute;
- tray application → application-defined behaviour where supported;
- quickshell-overview window preview → preserve upstream close behaviour only if clearly indicated and safely implemented.

Avoid assigning destructive or obscure actions to middle click unless inherited from an adopted component and documented.

---

## 3.4 Scroll wheel

Scrolling over a component should manipulate the component itself only when the relationship is obvious.

Approved initial mappings:

- audio item → adjust master volume;
- brightness slider or row → adjust brightness;
- numbered workspace pager → move through numbered workspaces;
- scrollable drawer content → scroll content;
- numeric controls in settings → adjust only when focused or actively hovered.

### Direction

Default convention:

- scroll up → increase or move to previous/higher workspace according to configured workspace direction;
- scroll down → decrease or move to next/lower workspace.

Workspace scroll direction should be configurable because users may conceptualize workspace order differently.

### Guardrails

- Scrolling must not trigger while a nested scrollable surface owns the gesture.
- Continuous values should use sensible increments.
- Rapid wheel input should update one existing OSD rather than create repeated feedback.
- Accidental scroll over the bar should not perform destructive actions.

---

## 3.5 Hover

Hover may provide:

- visual emphasis;
- tooltip;
- larger hit-target indication;
- secondary metadata;
- preview of a safe outcome.

Hover must not be the only way to:

- reveal essential controls;
- read critical state;
- open the control centre;
- dismiss blocking UI;
- perform an important action.

Hover alone should not open major surfaces.

---

## 3.6 Press-and-drag

Press-and-drag is reserved for direct spatial manipulation.

Examples:

- right-edge drag → reveal control centre;
- slider drag → change value;
- quickshell-overview window drag → move between workspaces;
- notification swipe/drag → dismiss;
- drawer drag back to edge → close.

A draggable surface must visually follow the pointer during the gesture.

Do not trigger the final action until the gesture crosses a distance or velocity threshold.

---

# 4. Keyboard Interaction Grammar

## 4.1 Invocation

Every major surface must have a configurable shortcut.

Initial major invocation categories:

- Vicinae root search;
- control centre;
- quickshell-overview;
- calendar;
- notification view;
- audio controls;
- workspace actions;
- shell settings;
- session menu.

Feature-specific default bindings should be proposed in a later Hyprland bindings document. This file defines behaviour, not exact key combinations.

---

## 4.2 Focus acquisition

When a surface opens from a keyboard shortcut:

- it must take keyboard focus immediately;
- the initial focus target must be deterministic;
- focus must be visibly indicated;
- typing must not leak into the previously focused application.

Recommended initial focus:

- Vicinae → delegated to Vicinae;
- control centre → last focused control within the default Notifications view, otherwise first quick control;
- detail page → page title/back target or first actionable control;
- calendar → current day;
- audio popover → master volume;
- resource popover → launch affordance or first row only if rows become interactive;
- tray drawer → first tray item;
- special-workspace selector → active item, otherwise first item;
- focused-window menu → first non-destructive action;
- session menu → lock or cancel-safe entry, not shutdown.

When opened by pointer, the surface should not steal focus unnecessarily from text input unless keyboard interaction begins.

---

## 4.3 Directional navigation

Use directional keys according to visible geometry.

### Vertical lists

- `Up` / `Down` move between items.
- `Left` returns to parent where spatially appropriate.
- `Right` opens details or enters a group.

### Horizontal rows

- `Left` / `Right` move between items.
- `Up` / `Down` move between rows or sections.

### Grids

- arrow keys follow physical placement;
- wrapping should be consistent within a surface;
- disabled or unavailable items should be skipped.

### Sliders

- `Left` / `Down` decrease;
- `Right` / `Up` increase;
- optional larger steps with `PageUp` / `PageDown`;
- `Home` and `End` may move to minimum and maximum where safe.

### Calendar

- arrows move by day;
- week movement follows vertical direction;
- month navigation has dedicated actions;
- `Home` or a visible Today action returns to the current date.

---

## 4.4 Activation

Default activation keys:

- `Enter` → primary action;
- `Space` → toggle when the focused control is a toggle;
- `Right` → enter detail page or expand group where spatially appropriate.

Avoid assigning multiple surprising actions to the same key within one surface.

---

## 4.5 Back and dismissal

`Escape` follows a stack-like rule:

1. cancel an active edit, pairing prompt, menu, or confirmation;
2. close the current nested page and return to its parent;
3. close the current popover or drawer;
4. return focus to the previously focused application.

Examples:

- Wi-Fi password prompt → `Escape` cancels prompt;
- Wi-Fi detail page → next `Escape` returns to control-centre main view;
- control-centre main view → next `Escape` closes drawer.

A surface should not close the entire interaction stack if a nested operation can be safely cancelled first.

---

## 4.6 Focus restoration

When a transient shell surface closes:

- restore focus to the previously focused application or window;
- if the invoking app no longer exists, focus the current Hyprland workspace's most recent valid window;
- do not leave focus on an invisible QML item.

For nested pages, focus should return to the control that opened the child page.

---

## 4.7 Tab traversal

`Tab` and `Shift+Tab` should traverse actionable controls in a logical order.

Tab order should follow:

1. visual reading order;
2. primary tasks before secondary actions;
3. safe actions before destructive actions.

Arrow-key navigation remains preferred within grids and lists; Tab is for moving across control groups.

---

## 4.8 Search and type-ahead

Search fields are appropriate in:

- Wi-Fi network lists;
- Bluetooth device lists;
- shell settings;
- long notification history later;
- tray drawer only if item counts become unusually high.

Vicinae remains the primary general-purpose search and command interface.

Do not add search boxes to small lists merely for visual completeness.

---

# 5. Surface Opening Rules

## 5.1 One primary surface per interaction region

The shell should avoid opening multiple competing major surfaces simultaneously.

Recommended policy:

- opening the control centre closes bar popovers;
- opening a bar popover closes another bar popover;
- opening quickshell-overview closes ordinary popovers and the control centre;
- opening Vicinae closes ordinary shell popovers;
- critical prompts may appear above another surface;
- notification popups should not duplicate notifications already visible in an open control centre.

---

## 5.2 Origin-aware opening

A surface should open from the control or edge that invoked it.

Examples:

- left-edge bar popover expands rightward;
- right-edge bar popover expands leftward if the bar is configured on the right;
- top-edge bar popover expands downward;
- bottom-edge bar popover expands upward;
- control centre always attaches to the right edge in the initial design;
- nested control-centre pages transition horizontally within the drawer.

The implementation should use logical directions:

- start;
- end;
- inward;
- outward;

rather than hard-coding left/right assumptions into every component.

---

## 5.3 Toggle behaviour

Invoking an already open surface through the same control should close it, unless the action has a more useful idempotent meaning.

Examples:

- click audio item while audio popover is open → close;
- press control-centre shortcut while open → close;
- click active special-workspace icon in selector → toggle that special workspace;
- press Vicinae shortcut while open → delegated toggle behaviour.

---

## 5.4 Outside click

Outside click should dismiss:

- popovers;
- menus;
- tray drawer;
- calendar;
- special-workspace selector;
- control centre.

Outside click should not silently discard:

- unsaved configuration edits;
- active password entry;
- destructive confirmation;
- pairing confirmation;
- authentication prompt.

In those cases, prompt to discard or treat outside click as no-op.

---

# 6. Right-Edge Control Centre Drag

## 6.1 Activation zone

The activation strip is invisible and positioned at the extreme right edge of each eligible monitor.

Requirements:

- narrow logical width;
- configurable;
- no visible handle;
- no hover activation;
- pointer press must begin within the zone;
- ordinary movement near the edge must not open the drawer.

---

## 6.2 Intent detection

The shell should recognize horizontal drag intent before committing to drawer interaction.

Suggested state sequence:

1. `Idle`
2. `PressedAtEdge`
3. `DragIntentDetected`
4. `Dragging`
5. `SettlingOpen` or `SettlingClosed`
6. `Open`

Intent detection should consider:

- horizontal distance;
- horizontal-to-vertical movement ratio;
- elapsed time;
- pointer velocity.

Mostly vertical movement should be released back to the application where technically possible.

---

## 6.3 Direct manipulation

While dragging:

- panel position follows the pointer;
- backdrop opacity follows reveal progress;
- expensive internal content may remain simplified until a minimum reveal threshold;
- input should stay responsive;
- no fixed-duration animation should fight the pointer.

---

## 6.4 Release behaviour

On release:

- open if reveal distance crosses threshold;
- open if inward velocity crosses threshold;
- otherwise close;
- use a short settling animation;
- restore full content only once opening is committed.

Thresholds should be tuned through real use rather than assumed from mobile UI conventions.

---

## 6.5 Closing by drag

When open:

- dragging the panel toward the right edge closes it;
- release threshold and velocity rules mirror opening;
- child pages remain intact during the drag;
- accidental small drags should snap back open.

---

## 6.6 Fullscreen policy

Right-edge pointer activation is disabled during true fullscreen by default.

Possible later setting:

- allow reveal over fullscreen.

Keyboard invocation may follow the same default suppression or remain allowed based on explicit user action. The recommended initial policy is:

- pointer edge drag suppressed;
- explicit keyboard shortcut allowed;
- ordinary notifications suppressed;
- user-triggered OSDs and critical alerts allowed.

---

# 7. Trackpad Gesture Principles

Trackpad gestures are a planned enhancement, not a first-prototype dependency.

## 7.1 Candidate gesture categories

- horizontal workspace switching;
- overview reveal;
- control-centre reveal;
- surface dismissal.

## 7.2 Gesture rules

- every gesture must have keyboard and pointer alternatives;
- gesture bindings must be configurable;
- conflicts with Hyprland gestures must be detected or documented;
- the gesture should match the surface's spatial direction;
- continuous gestures should directly manipulate the surface where possible;
- failed recognition should not trigger an unrelated action.

## 7.3 Finger-count strategy

A likely model is:

- three-finger horizontal → Hyprland workspace movement;
- four-finger inward from the right → control centre;
- four-finger upward or another distinct gesture → overview.

This is provisional. Actual support depends on Hyprland and input-stack capabilities.

Do not depend on reliable physical trackpad-edge detection unless verified.

---

# 8. Bar Interaction Rules

## 8.1 Numbered workspace pager

### Primary click

- inactive number → switch directly;
- active number → open quickshell-overview or configured overview action.

### Scroll

- move one numbered workspace at a time;
- update visible group when crossing a group boundary.

### Secondary click

- active workspace → focused-window action menu;
- inactive workspace → optional workspace actions later, but no initial requirement.

### Keyboard

- direct Hyprland number bindings remain primary;
- bar focus allows arrow navigation and activation;
- overview has its own shortcut.

### Resting state

- exactly one group of five;
- no occupancy markers;
- no application icons;
- no active window title.

---

## 8.2 Special-workspace control

### Primary click

Open selector.

### Selector activation

- inactive special workspace → open it;
- active special workspace → close it;
- selector closes after successful activation unless configured otherwise.

### Keyboard

- dedicated Hyprland shortcuts remain primary;
- selector supports arrows and `Enter`;
- `Escape` closes selector.

### Resting icon

- neutral stack when none is open;
- active special-workspace icon when visible.

---

## 8.3 Contextual-status region

Primary click opens the most relevant detail surface for the selected indicator.

When multiple statuses overflow:

- show a stack/overflow affordance;
- open a compact status summary;
- order by urgency.

Contextual indicators must not shift the stable end section.

---

## 8.4 Tray affordance

### Primary click

Open tray drawer.

### Keyboard

Focus first item.

### Tray item interaction

Preserve protocol/application behaviour:

- primary activation;
- context menu;
- scroll where supported.

Do not reinterpret application tray actions globally.

---

## 8.5 Download-speed indicator

### Resting state

Display rounded download speed only.

### Hover/focus

Show tooltip with upload and download values.

### Primary click

No action is required in the first prototype.

A later action may open network details, but this should not duplicate the connectivity exception indicator or control-centre Network page without a clear benefit.

---

## 8.6 Audio item

### Primary click

Open compact audio popover.

### Scroll

Adjust master output volume.

### Middle click

Toggle mute.

### Secondary click

Optional direct output-device menu later.

### Feedback

Volume changes produce one updating OSD.

---

## 8.7 Resource indicator

### Primary click

Open resource popover.

### Popover body click

Launch configured full system monitor.

### Keyboard

Open popover, then expose a visible launch action.

The whole-popover launch behaviour must be discoverable through hover/focus treatment.

---

## 8.8 Battery item

### Primary click

Open auto-cpufreq power panel.

### Resting feedback

- charging accent and restrained animation;
- low and critical semantic states.

### Keyboard

Allow opening panel and navigating controls.

No scroll action in the initial version.

---

## 8.9 Date and time

### Primary click

Open calendar.

### Keyboard

Open calendar and focus current day.

### Secondary click

No initial action.

The date and time act as one combined control.

---

## 8.10 Vicinae entry point

### Primary click

Toggle Vicinae root search.

### Secondary click

Open direct-entry shortcut menu.

### Keyboard

Dedicated shortcut toggles Vicinae.

### Failure

If unavailable:

- show a compact actionable error;
- do not crash or block the shell.

---

# 9. Control Centre Interaction Rules

## 9.1 Default state

The control centre opens to:

- main view;
- Notifications tab;
- quick controls visible;
- volume and brightness sliders visible.

It may temporarily restore last-focused control during a short reopen window, but should return to Notifications after a longer closure.

---

## 9.2 Quick controls

Initial controls:

- Wi-Fi;
- Bluetooth;
- Do Not Disturb;
- Night Light;
- idle inhibitor.

### Split interaction

For controls with detail pages:

- main area → toggle;
- detail affordance → open page.

For keyboard:

- `Space` → toggle;
- `Enter` → primary action;
- `Right` or explicit detail action → open page.

The distinction must be visually clear.

---

## 9.3 Sliders

Master volume and brightness remain visible above the main tabs.

Interaction:

- pointer drag;
- scroll while hovered;
- arrow adjustment when focused;
- mute through audio icon where appropriate;
- continuous OSD update.

Changing a slider should not close the control centre.

---

## 9.4 Tabs

Initial tabs:

- Notifications;
- Volume Mixer.

Keyboard:

- `Left` / `Right` between tabs when tab row is focused;
- optional `Ctrl+Tab` later;
- focus moves into selected page predictably.

Switching tabs preserves relevant local state, such as mixer scroll position.

---

## 9.5 Nested pages

Initial nested pages:

- Network;
- Bluetooth.

Rules:

- replace main drawer content rather than opening detached windows;
- header shows back action and page title;
- quick controls and tabs are hidden while inside the page unless design testing proves a persistent header useful;
- `Escape` returns to main view;
- another `Escape` closes drawer.

---

## 9.6 Network list interactions

- primary click network → connect or open connection flow;
- connected network → show details and disconnect action;
- saved network secondary action → forget;
- secured network → password prompt;
- hidden network → explicit form;
- refresh → rescan;
- keyboard arrows → move through networks;
- `Enter` → connect/open;
- `Escape` → cancel prompt or go back.

Long-running connection attempts must show progress and remain cancellable.

---

## 9.7 Bluetooth interactions

- primary click device → connect, pair, or open device actions;
- connected device → disconnect or details;
- paired device secondary action → forget;
- pairing code → explicit confirmation;
- scanning → visible status;
- audio device → optional set-as-output action.

Bluetooth operations must never appear frozen. Show state transitions and errors.

---

# 10. Notification Interaction Rules

## 10.1 Popup behaviour

- popups appear from the right;
- stack downward;
- remain inset from the extreme edge;
- pause timeout on hover or keyboard focus;
- application actions are visible when provided;
- repeated notifications coalesce;
- popups are silent by default.

When the control centre is already open to Notifications:

- insert notification into history;
- do not show a duplicate popup.

---

## 10.2 Dismissal

Pointer:

- explicit dismiss control;
- drag/swipe toward the right.

Keyboard:

- dedicated dismiss key or focused dismiss action;
- `Delete` may be supported where unambiguous.

Dismissal removes the notification from visible history unless the notification protocol or progress state requires persistence.

---

## 10.3 Grouping

Notifications group by application.

Within a group:

- newest summary is visible;
- group can expand;
- individual notifications remain actionable;
- entire group can be dismissed.

New notifications must not steal scroll position while the user reads older entries.

---

## 10.4 Clear all

Clear all:

- removes ordinary dismissible notifications;
- preserves required persistent/progress entries;
- should provide lightweight undo where practical;
- must not require a destructive modal confirmation.

---

## 10.5 Fullscreen and DND

Ordinary popups:

- suppressed during DND;
- withheld during fullscreen;
- still enter history;
- do not replay as a burst later.

Critical and user-action-related feedback follows policy in `notifications.md`.

---

# 11. Toast and OSD Interaction Rules

## 11.1 System toasts

Toasts confirm discrete state changes.

Rules:

- one compact message;
- brief lifetime;
- repeated category replaces existing toast;
- no history by default;
- visible during DND;
- failure may include Retry or Open Details.

Examples:

- Wi-Fi enabled;
- Bluetooth disabled;
- Night Light enabled;
- output changed;
- power configuration applied.

---

## 11.2 OSDs

OSDs represent continuous values.

Rules:

- one OSD instance per value category;
- update in place;
- visible only while changing and briefly afterward;
- no history;
- no notification sound;
- visible over fullscreen when user-triggered.

Initial categories:

- volume;
- brightness.

No track-change OSD.

---

# 12. Menus, Popovers, and Tooltips

## 12.1 Menus

Menus are appropriate for:

- Vicinae direct entries;
- focused-window actions;
- tray application menus;
- overflow actions;
- optional device actions.

Menus should:

- open adjacent to invoking control;
- support arrows and `Enter`;
- close on outside click or `Escape`;
- avoid deeply nested submenus where a page is clearer.

---

## 12.2 Popovers

Popovers are appropriate for:

- compact audio;
- resources;
- calendar;
- tray;
- power settings if size remains manageable;
- special-workspace selector.

A popover should not become a disguised full-screen settings panel.

If the task needs scanning, authentication, or a long list, prefer a control-centre page.

---

## 12.3 Tooltips

Tooltips should:

- appear after a short delay;
- identify compact icon-only controls;
- show exact values where the bar shows compressed values;
- provide shortcut hints where useful;
- disappear on pointer departure;
- be available through accessible descriptions for keyboard users.

Examples:

- resource ring → `Memory usage: 62%`;
- network speed → `↓ 20M/s  ↑ 3M/s`;
- workspace number → optional semantic label if configured;
- charging battery → `Charging · 87%`.

Tooltips must not contain required controls.

---

# 13. Destructive and Sensitive Actions

## 13.1 Action severity

### Immediate reversible

- mute;
- disconnect;
- dismiss notification;
- toggle quick control.

### Lightweight confirmation or undo

- clear all notifications;
- forget saved network;
- forget Bluetooth device;
- reset a small preference.

### Explicit confirmation

- force-kill window;
- logout;
- reboot;
- shutdown;
- reset shell configuration;
- overwrite power configuration with unsafe values.

---

## 13.2 Confirmation design

Confirmations should:

- state the exact action;
- state meaningful consequence;
- place safe/cancel action first in keyboard order;
- avoid ambiguous labels such as `OK`;
- distinguish graceful close from force-kill;
- not rely only on red colour.

---

## 13.3 Authentication and privileged actions

Privileged actions may require authentication.

Rules:

- keep authentication flow visually distinct;
- never request credentials through a custom insecure text flow when system authentication is available;
- disable unrelated background dismissal while authorization is active;
- explain why privilege is required;
- return to the original task after success.

---

# 14. Error Interaction

Errors should be actionable and local to the failed task.

## 14.1 Transient failure

Examples:

- Bluetooth pairing timeout;
- network connection failed;
- external application failed to launch.

Response:

- keep message visible longer;
- offer Retry or Open Details where useful;
- preserve the rest of the surface.

## 14.2 Missing service

Examples:

- Vicinae unavailable;
- auto-cpufreq not installed;
- Bluetooth adapter absent;
- brightness unsupported.

Response:

- show unavailable state;
- explain briefly;
- provide diagnostics or setup action where appropriate;
- do not crash or leave dead controls.

## 14.3 Configuration failure

- preserve unsaved values;
- show exact field or file problem;
- do not partially apply silently;
- expose logs or details without overwhelming the main interface.

---

# 15. Multi-Monitor Interaction Principles

The complete policy remains open, but all features should follow these preliminary rules.

## 15.1 Pointer invocation

Pointer-opened surfaces appear on the monitor where the pointer action begins.

Examples:

- right-edge drag → drawer on that monitor;
- bar popover → same monitor as the bar control.

## 15.2 Keyboard invocation

Until a final policy is defined, keyboard-opened surfaces should appear on the monitor containing the focused window.

Fallback order:

1. focused-window monitor;
2. pointer monitor;
3. configured primary monitor.

## 15.3 Single-instance major surfaces

Initial recommendation:

- one control centre open globally;
- one overview open globally;
- one Vicinae surface according to Vicinae behaviour;
- notifications appear on one selected active monitor, not duplicated.

## 15.4 Focus restoration

Restore focus to the originating monitor and application where possible.

---

# 16. Accessibility Interaction Rules

- Every icon-only control has an accessible name.
- Every state has a non-colour cue.
- Focus is always visible.
- Pointer hit areas exceed the visible glyph where possible.
- Reduced-motion mode shortens or removes nonessential transitions.
- Continuous animation is not required to understand charging or critical state.
- Keyboard order matches visual order.
- No feature depends solely on hover.
- No feature depends solely on gesture.
- Error text is concise and readable.
- Timeouts pause while content is hovered, focused, or being read where practical.

---

# 17. Performance and Input Responsiveness

- Direct manipulation must update at interactive frame rates.
- Service calls must not block the QML UI thread.
- Long-running operations show progress.
- Repeated input is coalesced.
- Animations do not delay action completion.
- Invisible surfaces stop unnecessary timers.
- Large lists use lazy delegates where appropriate.
- Notification bursts update existing components instead of constructing unbounded popup stacks.
- Sensor refresh rates increase only while detailed surfaces are visible.

---

# 18. Interaction State Model

Each transient surface should expose a clear state model rather than relying on scattered booleans.

Recommended generic states:

```text
Closed
Opening
Open
Navigating
Editing
Confirming
Error
Closing
```

A draggable drawer additionally uses:

```text
PressedAtEdge
Dragging
SettlingOpen
SettlingClosed
```

Operations such as Wi-Fi connection or Bluetooth pairing should use explicit task states:

```text
Idle
Scanning
Connecting
AwaitingInput
Connected
Failed
Cancelling
```

This improves animation, focus, error recovery, and testability.

---

# 19. Acceptance Checklist for Feature Specifications

Every feature specification should answer:

## Invocation

- What keyboard shortcut opens it?
- What pointer action opens it?
- Is there an optional gesture?
- Which monitor owns it?

## Focus

- What receives initial focus?
- How does focus move?
- Where is focus restored?

## Primary actions

- What does primary click do?
- What does `Enter` do?
- Are toggle and detail actions distinct?

## Secondary actions

- Is secondary click used?
- Is middle click used?
- Is scroll used?
- Are all secondary actions keyboard-accessible?

## Dismissal

- What does `Escape` do?
- Does outside click dismiss?
- Can it be dragged closed?
- What happens with unsaved edits?

## Feedback

- Does the action use notification, toast, OSD, inline state, or no feedback?
- Does it respect DND?
- Does it appear during fullscreen?
- Does it enter history?

## Error handling

- What happens if the service is absent?
- What happens if the action fails?
- Is retry available?
- Can the rest of the shell continue?

## Accessibility

- Is the state understandable without colour?
- Are icon-only controls named?
- Is focus visible?
- Is reduced motion supported?

## Performance

- Does the feature poll while hidden?
- Can input block on IPC?
- Are burst events coalesced?

A feature is not interaction-complete until these questions have explicit answers.
