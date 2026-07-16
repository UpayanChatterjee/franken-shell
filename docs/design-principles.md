# Franken Shell — Design Principles

> **Status:** Working design baseline  
> **Applies to:** Shell UI, adopted components, settings, services, and integrations  
> **Related document:** `product-vision.md`

This document defines the rules used to evaluate design and implementation decisions throughout Franken Shell.

A feature should not be accepted merely because it is technically possible or visually attractive. It should support the shell's product vision, preserve interaction consistency, and remain practical to maintain in Quickshell/QML.

---

## 1. Minimal by Default, Comprehensive on Command

The resting shell should expose only information or controls that satisfy at least one of these conditions:

- they are checked frequently;
- they are acted on frequently;
- they communicate an active state that matters now;
- they communicate a fault, interruption, or risk;
- hiding them would make routine use materially slower.

Everything else should live behind a deliberate action.

### Implications

- Normal Wi-Fi and Bluetooth state remain hidden.
- Network failure, connected peripherals, recording, and similar active states may surface contextually.
- Detailed system metrics belong in popovers rather than the bar.
- Comprehensive device controls belong in the control centre.
- Application launching and command execution belong in Vicinae.
- The bar must not become a compressed dashboard.

### Design test

Before adding a persistent element, ask:

> What recurring decision does this help the user make without opening anything?

If the answer is weak, the element should probably be summonable rather than persistent.

---

## 2. Quietly Visible

The shell should be present enough to orient the user without competing with application content.

Quietness is produced through:

- compact dimensions;
- stable placement;
- restrained contrast;
- low motion while idle;
- omission of redundant labels;
- selective use of colour;
- predictable contextual surfacing.

Quietness does not mean low readability. Important state must remain immediately legible.

### Avoid

- constant decorative animation;
- large idle cards or islands;
- multiple indicators describing the same state;
- bright accents on inactive controls;
- dense permanent status rows;
- rapidly shifting layouts.

---

## 3. Restrained at Rest, Expressive in Response

Android Material You Expressive should influence interaction and state changes more strongly than idle layout density.

### At rest

- use compact geometry;
- use restrained colour;
- avoid unnecessary filled containers;
- preserve stable silhouettes;
- keep animation dormant;
- show only the minimum useful text.

### During interaction

- strengthen accent colour;
- expand hit targets where needed;
- use shape changes to communicate selection;
- animate surfaces from their spatial origin;
- make active state unmistakable;
- expose labels and details progressively.

Expressiveness should explain interaction, not decorate inactivity.

---

## 4. Keyboard First, Pointer Complete

Keyboard interaction is the primary efficiency path. Mouse and trackpad interaction must still be comprehensive and intentional.

Every major interactive surface should provide:

- a keyboard shortcut or keyboard-accessible entry point;
- correct focus acquisition;
- visible focus indication;
- arrow-key or directional navigation where appropriate;
- `Enter` or `Space` activation;
- `Escape` dismissal or back navigation;
- pointer activation;
- secondary-click behaviour where useful;
- scroll behaviour where a continuous value or sequence is involved.

### Pointer interaction is not optional

Pointer workflows should not depend entirely on hidden shortcuts or undocumented gestures.

Examples:

- Vicinae has a visible bar entry point.
- The control centre can be dragged from the right edge.
- Workspace numbers are directly clickable.
- Volume can be changed by scrolling over the audio cell.
- Tray applications remain accessible through a tray drawer.

### Trackpad gestures

Gestures should be used only where the action has a clear spatial metaphor.

Good candidates:

- workspace navigation;
- opening or dismissing edge surfaces;
- overview invocation;
- direct manipulation of drawers.

Gestures must not conflict silently with existing Hyprland bindings.

---

## 5. Stable Spatial Grammar

Every major shell function should have a predictable home.

### Default spatial model

- **Left edge:** persistent bar, navigation, immediate status.
- **Right edge:** control centre, notifications, occasional management.
- **Edge-attached popovers:** details originating from bar controls.
- **Centre:** Vicinae command/search surface.
- **Overview layer:** workspace and window navigation through quickshell-overview.

### Rules

- A surface should open from or near the control that invoked it.
- Related details should reuse the same edge and direction.
- Nested control-centre pages should remain inside the drawer.
- Avoid detached popups when an existing surface can host the interaction.
- Do not assign the same feature two equal primary homes.

### Examples

- The calendar belongs to the date/time control, not also as a full control-centre module.
- Wi-Fi management belongs to a control-centre detail page.
- Resource detail belongs to the resource popover.
- Advanced window navigation belongs to quickshell-overview.

---

## 6. Stable Layout Over Maximum Density

A compact UI should not move unpredictably as state changes.

### Rules

- Reserve fixed space for contextual bar indicators.
- Use tabular numerals for changing numeric values.
- Bound the width or height of live metrics.
- Coalesce bursty notifications.
- Preserve scroll position when new notifications arrive.
- Prefer replacement over stacking for repeated system toasts.
- Avoid controls whose size changes with ordinary state updates.

### Example

The persistent download-speed indicator may change from `3K` to `20M`, but its cell must not push adjacent controls.

---

## 7. Encode Meaning Through Shape, Position, and State

Labels should be omitted when stable position, iconography, shape, and value already communicate meaning.

### Appropriate text

- workspace numbers;
- time and date;
- battery percentage;
- download speed;
- exact resource values;
- network names;
- device names;
- notification content.

### Usually unnecessary text

- `RAM`;
- `BAT`;
- `WIFI`;
- `BT`;
- `VOL`;
- `TRAY`.

Tooltips, accessible names, and expanded surfaces should provide descriptive text.

### Caution

Do not turn every metric into the same circular ring. Distinct categories need distinct silhouettes and interaction patterns.

---

## 8. One State, One Primary Representation

Do not use multiple persistent indicators to communicate the same underlying state.

### Examples

- The audio icon changes according to the active output device instead of adding a separate permanent headphone icon.
- A Bluetooth indicator appears only when it conveys information not already represented by the audio item.
- Normal network connectivity is silent; persistent throughput and exceptional connectivity are separate concerns.
- The special-workspace control uses one slot that changes to the active special-workspace icon.

Redundant representation is allowed only when each representation supports a different workflow.

---

## 9. Normal State Is Silent; Exceptions Surface

The shell should distinguish between normal, contextual, exceptional, and critical state.

### Normal

Expected state that does not need persistent emphasis.

Examples:

- internet available;
- Bluetooth enabled with no relevant connected device;
- no notifications requiring action;
- ordinary background activity.

### Contextual

A currently active state worth showing.

Examples:

- connected non-audio Bluetooth device;
- microphone active;
- screen recording active;
- special workspace open;
- file transfer in progress.

### Exceptional

A problem or incomplete state.

Examples:

- no internet;
- pairing failed;
- output device disappeared;
- storage nearly full;
- service unavailable.

### Critical

A state that may bypass Do Not Disturb or fullscreen suppression.

Examples:

- imminent shutdown due to battery;
- severe temperature warning;
- active authentication prompt;
- alarm or timer;
- incoming call;
- destructive operation awaiting confirmation.

---

## 10. Feedback Channels Must Remain Separate

Application notifications, system toasts, and OSDs have different purposes and must not be conflated.

### Application notifications

- originate from applications;
- enter notification history;
- may be grouped;
- respect Do Not Disturb unless critical;
- are silent by default.

### System configuration toasts

- confirm a state change initiated by the user;
- are brief;
- normally do not enter notification history;
- remain visible during Do Not Disturb;
- may provide retry or repair actions on failure.

### OSDs

- communicate continuous direct manipulation;
- update in place;
- disappear quickly;
- do not enter history;
- remain visible during Do Not Disturb.

Initial OSDs:

- volume;
- brightness.

Track changes produce no notification or OSD.

---

## 11. Progressive Disclosure

The shell should reveal complexity in layers.

### Example hierarchy

1. Resting bar value or icon.
2. Tooltip or hover detail.
3. Compact popover.
4. Comprehensive control-centre page.
5. External specialist application for advanced administration.

### Example: networking

1. No icon while connectivity is normal.
2. Persistent throughput value in the bar.
3. Failure indicator if internet is unavailable.
4. Comprehensive Wi-Fi page in the control centre.
5. External network settings for advanced enterprise, routing, or DNS administration.

A feature should not jump directly from a tiny bar control to an unrelated full settings application when an intermediate shell surface would cover common use.

---

## 12. Adopt Good Components Instead of Rebuilding Them

Existing tools should be treated as first-class integrations when they already provide a superior solution.

### Current adopted components

- Caelestia services and dynamic colour generation;
- Vicinae for launch, search, and commands;
- quickshell-overview for visual workspace and window management;
- auto-cpufreq for power policy.

### Integration rules

- use stable public interfaces where possible;
- isolate external dependencies behind small adapters;
- avoid coupling to undocumented internals;
- degrade gracefully when a dependency is unavailable;
- share configuration instead of duplicating it;
- pin and test known-working revisions when required;
- visually adapt without maintaining unnecessary forks.

The shell should own the integration experience, not duplicate the external component's implementation.

---

## 13. Shared Configuration, Never Parallel Truths

Features that refer to the same concept must read from one source of truth.

Shared configuration candidates include:

- numbered workspace groups;
- special workspace names, icons, and Hyprland identifiers;
- bar edge and dimensions;
- colour tokens;
- animation tokens;
- application commands;
- Vicinae entry points;
- system monitor command;
- notification sound rules;
- adopted-component compatibility versions.

### Example

The bar and quickshell-overview must not maintain independent lists of special workspaces.

---

## 14. Configuration Must Preserve Coherence

Configurability is important, but every exposed setting increases maintenance cost and can weaken the design.

A setting should be exposed when:

- users reasonably have different workflows;
- hardware differences require it;
- an external command or application varies;
- accessibility benefits;
- the behaviour is subjective rather than structural.

A setting should not be exposed merely because a QML property exists.

### Good candidates

- bar edge;
- autohide;
- fullscreen reveal policy;
- workspace group size;
- special workspace definitions;
- system monitor command;
- unit convention for throughput;
- gesture bindings;
- notification sound rules;
- control-centre width.

### Poor candidates for the initial release

- arbitrary per-component spacing;
- unrestricted animation tuning;
- independent corner radius for every card;
- user-defined colours that bypass the shared palette;
- free-form reordering of every internal row.

Prefer meaningful presets and semantic options over raw visual parameters.

---

## 15. Hardware and Service Capabilities Are Conditional

The UI must reflect actual capability rather than assuming every machine exposes the same devices or sensors.

### Examples

- CPU and GPU fan speeds may not be available.
- Multiple GPUs may exist.
- Battery charge thresholds may not be supported.
- Brightness may be monitor-specific.
- Bluetooth battery data may be absent.
- Some machines may not use auto-cpufreq.
- A tray may contain no items.
- NetworkManager or PipeWire services may be unavailable.

Unsupported information should normally be omitted rather than displayed as permanent disabled rows.

Errors should state what is unavailable and, where useful, provide a repair path.

---

## 16. Accessibility Is Part of Precision

A precise interface is usable without relying solely on colour, tiny targets, or memory.

Requirements include:

- visible keyboard focus;
- sufficient contrast;
- non-colour state indicators;
- tooltips and accessible names for compact controls;
- pointer targets larger than the visible glyph where possible;
- reduced-motion support;
- readable text scaling;
- no essential action available only through hover;
- no essential action available only through gesture;
- critical states distinguishable without animation.

Material expressiveness must not reduce clarity.

---

## 17. Motion Must Explain Cause and Effect

Motion should communicate:

- where a surface came from;
- what changed;
- which item was selected;
- whether an action succeeded;
- whether a drag crossed an activation threshold.

### Appropriate motion

- control centre following the pointer during edge drag;
- panel expanding from a bar cell;
- workspace group transitioning when crossing from `1–5` to `6–10`;
- active control changing shape;
- toast replacing an earlier toast;
- notification group expanding.

### Inappropriate motion

- perpetual idle pulsing;
- animating every network-speed digit change;
- decorative parallax unrelated to input;
- slow transitions that delay interaction;
- simultaneous motion in unrelated regions.

Input must never wait for animation to finish.

---

## 18. Destructive Actions Need Deliberate Friction

Close, kill, disconnect, forget, logout, reboot, and shutdown do not all require the same confirmation level.

### Suggested hierarchy

- **Immediate:** close ordinary notification, mute stream, disconnect from device.
- **Undo or lightweight confirmation:** forget saved network, clear all notifications.
- **Explicit confirmation:** force-kill application, logout, reboot, shutdown.
- **Stronger warning:** destructive configuration reset or operation with data-loss risk.

The shell should distinguish graceful close from force-kill visually and verbally.

---

## 19. Fullscreen Is an Interruption Boundary

True fullscreen should suppress ordinary shell interruption by default.

### Hidden or withheld

- persistent bar;
- ordinary notification popups;
- accidental right-edge drawer activation;
- non-critical contextual UI.

### Still permitted

- user-triggered OSDs;
- user-triggered configuration toasts;
- critical alerts;
- authentication or confirmation prompts required by the active action.

Maximized windows are not fullscreen and should retain the normal bar.

---

## 20. Multi-Monitor Behaviour Must Be Explicit

Every surface specification must eventually define:

- which monitor owns it;
- whether it appears on all monitors;
- whether it follows focus, pointer, or invocation source;
- how scaling and rotation affect it;
- whether state is shared or per-monitor.

Until a complete multi-monitor policy is written, default behaviour should be conservative and deterministic.

No feature should assume a single monitor internally if avoiding that assumption is reasonably practical.

---

## 21. Performance Is a Product Requirement

The shell should feel immediate and remain lightweight enough for continuous use.

### Rules

- poll slowly while a surface is closed;
- increase update frequency only while detailed monitoring is visible;
- avoid redundant service subscriptions;
- cache stable derived values;
- coalesce high-frequency events;
- load expensive views lazily;
- stop animations and timers when invisible;
- avoid large live previews outside the overview;
- preserve responsiveness when optional services fail.

Visual polish must not come at the cost of frame pacing or input latency.

---

## 22. Graceful Degradation

The shell should remain usable when optional integrations are absent or broken.

Examples:

- Vicinae unavailable → command button shows an actionable error; shell remains running.
- quickshell-overview unavailable → direct workspace switching still works.
- auto-cpufreq unavailable → battery status remains visible; configuration panel explains the missing service.
- sensor unavailable → omit the metric.
- notification sound file missing → notification remains visual.
- system monitor command unavailable → resource popover remains useful.

A missing optional dependency must not crash the main shell.

---

## 23. Prototype the Interaction Before Polishing the Surface

Implementation should validate:

- information hierarchy;
- focus handling;
- opening and dismissal;
- edge drag;
- layout stability;
- service behaviour;
- error states;
- multi-monitor ownership.

Visual polish should follow once the interaction model is proven.

Avoid spending substantial effort on motion, blur, or custom geometry before the feature works reliably.

---

## 24. Every Feature Needs a Scope Boundary

Each feature specification should explicitly state:

- what it owns;
- what it integrates;
- what it delegates;
- what is out of scope for the current phase.

### Example: Wi-Fi page

Owns:

- scan;
- connect;
- disconnect;
- forget;
- hidden network;
- common connection details.

Delegates:

- advanced enterprise certificates;
- custom routes;
- complex DNS;
- low-level interface administration.

This prevents “comprehensive” from turning into indefinite scope.

---

## 25. Decision Checklist

Before accepting a feature or interaction, evaluate it against these questions:

1. Does it support minimal-by-default behaviour?
2. Is its primary home spatially clear?
3. Does it duplicate an existing component?
4. Is there a fast keyboard path?
5. Is there a complete pointer path?
6. Is gesture use optional and conflict-aware?
7. Does the layout remain stable as state changes?
8. Is the normal state quieter than the exceptional state?
9. Does the motion explain cause and effect?
10. Does it work without relying only on colour?
11. Does it adapt to missing hardware or services?
12. Can it degrade without breaking the shell?
13. Is the configuration sourced from one place?
14. Is the first implementation scope bounded?
15. Is the feature worth its persistent visual and maintenance cost?

If several answers are weak, the feature should be redesigned, deferred, or removed.
