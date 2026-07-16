# Franken Shell — Visual Language

> **Status:** Working design baseline  
> **Purpose:** Define the shell-wide visual system for colour, typography, geometry, spacing, iconography, surfaces, state, and motion  
> **Related documents:** `product-vision.md`, `design-principles.md`, `feature-map.md`, `interaction-language.md`

This document translates Franken Shell's product direction into a reusable visual language.

The shell should feel like one product even when some features are adapted from Caelestia, Illogical Impulse, ActivSpot, Vicinae, or quickshell-overview.

The intended character is:

- elegant;
- fast;
- precise;
- minimal at rest;
- expressive in response;
- technical where useful;
- warm enough to avoid feeling sterile.

The visual system should be implemented as shared semantic tokens rather than one-off values scattered across QML files.

---

# 1. Visual Thesis

Franken Shell uses a restrained interpretation of Android Material You Expressive, driven by Caelestia's wallpaper-derived dynamic colours.

The shell should not imitate Android literally.

It should borrow:

- semantic colour roles;
- expressive shape changes;
- responsive motion;
- strong selected states;
- clear tonal hierarchy;
- large enough interaction targets;
- progressive disclosure.

It should reject:

- oversized mobile cards;
- excessive padding;
- constant morphing;
- decorative animations while idle;
- giant typography;
- redundant labels;
- bubbly geometry on every element;
- excessive translucency that harms readability.

The governing rule is:

> **Restrained at rest, expressive in response.**

---

# 2. Design-System Architecture

The visual system should be split into five layers.

## 2.1 Source palette

Generated from the wallpaper through retained Caelestia colour services.

This layer contains raw tonal values but should not be consumed directly by most components.

Example conceptual families:

```text
primary
secondary
tertiary
neutral
neutralVariant
error
success
warning
```

Each family may expose tonal steps.

---

## 2.2 Semantic colour roles

Components consume semantic roles such as:

```text
surface.base
surface.raised
surface.overlay
surface.popup
surface.scrim

text.primary
text.secondary
text.disabled
text.onAccent
text.warning
text.critical

accent.primary
accent.secondary
accent.tertiary
accent.container
accent.onContainer

outline.subtle
outline.strong
outline.focus

state.hover
state.pressed
state.selected
state.disabled

status.success
status.warning
status.critical
status.information
status.recording
status.privacy
```

The role names should remain stable even when the palette-generation implementation changes.

---

## 2.3 Component tokens

Components may define local semantic mappings, for example:

```text
bar.background
bar.itemForeground
bar.itemForegroundActive
bar.activeContainer

notification.background
notification.urgentBackground
notification.actionForeground

slider.track
slider.fill
slider.thumb

workspace.foreground
workspace.activeForeground
workspace.activeContainer
```

Component tokens must derive from shell-level semantic roles rather than raw palette values.

---

## 2.4 State tokens

Shared states include:

- resting;
- hover;
- keyboard focus;
- pressed;
- selected;
- active;
- disabled;
- warning;
- critical;
- recording;
- privacy-sensitive;
- disconnected;
- unavailable.

The same state should look recognizably related across different components.

---

## 2.5 User and accessibility overrides

Supported overrides should include:

- reduced motion;
- higher contrast;
- text scaling;
- larger pointer targets;
- optional opacity preference;
- light/dark mode if the dynamic palette supports both.

User overrides should operate through semantic tokens, not component-by-component patches.

---

# 3. Colour System

## 3.1 Wallpaper-derived colour source

Wallpaper-derived colours are central to the shell's identity.

A wallpaper change should update:

- bar;
- control centre;
- popovers;
- notifications;
- toasts;
- OSDs;
- quickshell-overview;
- Vicinae theme;
- future session and lock surfaces.

### Requirements

- always provide a fallback palette;
- validate contrast before exposing generated colours;
- do not use the most saturated wallpaper colour everywhere;
- keep passive surfaces quieter than active controls;
- ensure critical and warning colours remain semantically recognizable;
- avoid text colours that shift too close to their background;
- theme changes must not produce a flash of unstyled content.

---

## 3.2 Tonal hierarchy

The shell should primarily use tonal differences rather than borders around every component.

Recommended hierarchy:

### Base surface

Used for:

- persistent bar;
- large control-centre background;
- stable structural surfaces.

Characteristics:

- opaque or nearly opaque;
- low visual noise;
- strong readability;
- wallpaper-influenced but not wallpaper-transparent.

### Raised surface

Used for:

- cards within the control centre;
- notification groups;
- selected detail regions;
- nested controls.

Characteristics:

- modest tonal separation;
- no strong floating shadow required;
- may use a subtle outline.

### Popup surface

Used for:

- menus;
- tooltips;
- tray drawer;
- compact popovers;
- shortcut menus.

Characteristics:

- stronger separation from application content;
- readable on arbitrary backgrounds;
- modest elevation treatment.

### Interactive accent container

Used for:

- selected workspace;
- active quick control;
- active tab;
- current special workspace;
- focused primary action;
- slider fill.

Characteristics:

- more expressive colour;
- restrained area;
- strong on-container contrast.

---

## 3.3 Opaque versus translucent surfaces

The control centre should favour an opaque Material surface.

Recommended policy:

- control centre: opaque or almost opaque;
- notification cards: opaque;
- bar: opaque enough to remain legible over every wallpaper;
- popovers: opaque or lightly translucent;
- tooltip: opaque;
- scrim: translucent;
- decorative blur: optional and subtle.

Blur should never be required to make text readable.

A surface should not become transparent merely because the compositor supports blur.

---

## 3.4 Accent distribution

Accent colour should primarily appear on:

- selected workspace;
- active special workspace;
- active quick controls;
- slider fills;
- keyboard focus;
- active tab;
- current date;
- actionable notification controls;
- charging state;
- important progress.

Passive text and icons should remain neutral.

Do not apply accent colour to every icon at rest.

---

## 3.5 Status colours

Status colour should be semantic and sparse.

### Success

Use for:

- successful connection;
- completed user action;
- healthy service state when explicitly displayed.

### Warning

Use for:

- low battery;
- high temperature;
- nearly full storage;
- degraded connectivity;
- action requiring attention but not immediate interruption.

### Critical

Use for:

- imminent shutdown;
- severe temperature;
- failed destructive operation;
- critical storage or hardware failure;
- urgent authentication/security state.

### Recording/privacy

Use a dedicated role for:

- microphone active;
- camera active;
- screen recording;
- screen sharing.

This state must not rely on colour alone. Include a distinct glyph or shape.

---

## 3.6 Focus colour

Keyboard focus should have a dedicated role that remains visible against both neutral and accented containers.

Focus should not be represented solely by the same fill used for selection.

Recommended focus treatment:

- outer focus ring;
- subtle shape expansion;
- stronger outline;
- optional slight elevation.

The focus ring must remain visible in both light and dark palettes.

---

# 4. Surface Model

## 4.1 Persistent bar

The bar is a continuous rail, not a chain of unrelated floating islands.

### Visual characteristics

- edge-attached;
- compact;
- stable;
- subtle tonal separation from application content;
- minimal internal separators;
- grouped through spacing;
- active states use local shape and colour;
- no permanent drop shadow unless needed for contrast.

### Default width

Use approximately `44–48` logical pixels as an initial prototype range.

The final width should be selected after testing:

- stacked time;
- two- and three-digit values;
- icon touch targets;
- vertical workspace pager;
- scaled displays.

### Orientation

The visual system must support:

- left;
- right;
- top;
- bottom.

Components should adapt layout rather than merely rotate text blindly.

---

## 4.2 Control centre

The control centre is a dense but readable edge-attached utility drawer.

### Visual characteristics

- right-edge attached;
- opaque;
- more spacious than the bar;
- information-dense without feeling cramped;
- stronger hierarchy than a flat settings list;
- nested pages remain visually inside the same surface;
- large enough for pointer use;
- not a full-screen mobile panel.

### Initial width

Use approximately `380–420` logical pixels as a prototype range.

The final width should consider:

- notification text;
- Wi-Fi names;
- Bluetooth device rows;
- sliders;
- per-application mixer controls;
- scaled displays.

---

## 4.3 Popovers

Popovers should appear connected to the invoking control.

### Characteristics

- edge-oriented corner treatment;
- compact;
- strong readability;
- no excessive card nesting;
- one obvious primary purpose;
- size derived from content within bounded limits.

Examples:

- resource popover;
- calendar;
- audio controls;
- special-workspace selector;
- Vicinae shortcut menu;
- tray drawer.

---

## 4.4 Notifications

Application notifications should use a compact card language.

### Characteristics

- app identity clearly visible;
- title stronger than body;
- actions obvious but not oversized;
- urgent state stronger than ordinary state;
- grouped notifications visually connected;
- progress state distinct;
- popup stack does not resemble floating mobile bubbles.

Cards should preserve readable line lengths and clip or expand predictably.

---

## 4.5 Toasts

System toasts are smaller and simpler than notifications.

### Structure

```text
icon  concise state label
```

Optional:

- Retry;
- Open Details.

Toasts should not visually resemble application notifications enough to imply history or app ownership.

---

## 4.6 OSDs

OSDs should be highly glanceable.

### Characteristics

- icon;
- value or compact slider;
- strong contrast;
- minimal text;
- one category at a time;
- fixed placement;
- no card stack;
- no app identity.

Volume and brightness OSDs should share geometry but use distinct icons.

---

# 5. Geometry and Shape

## 5.1 Corner system

Use a small number of shared corner-radius tokens.

Recommended starting set:

```text
radius.none
radius.small
radius.medium
radius.large
radius.full
```

Possible initial logical values:

```text
small  = 6
medium = 10
large  = 16
full   = height / 2
```

These are prototype values, not immutable requirements.

### Usage

- bar outer edge: edge-aware medium or large radius only where not flush;
- compact buttons: small or full;
- active workspace: full/pill;
- notification cards: medium;
- control centre: large on inward-facing corners, none on screen-attached edge;
- menus/popovers: medium or large;
- OSD: full or large depending on form.

Avoid assigning unique radii to every component.

---

## 5.2 Edge-aware corners

Attached surfaces should visually acknowledge the screen edge.

Examples:

- right-edge control centre: right corners flush or minimally rounded; left corners rounded;
- left-edge bar: left corners flush; right corners rounded if the bar is inset vertically;
- bottom popover: outer/inward corners rounded according to attachment.

Corner logic should derive from edge orientation.

---

## 5.3 Active shape transformation

Material You Expressive influence should appear through controlled shape changes.

Examples:

- inactive workspace number → minimal cell;
- active workspace → filled pill;
- inactive quick control → compact neutral tile;
- active quick control → stronger filled container;
- focused button → slight expansion or outline;
- charging battery text → accent underline or contained shimmer.

Shape changes should not cause surrounding layout to move.

---

## 5.4 Hit targets

Visible glyphs may remain compact, but pointer targets should be larger.

Recommended minimum target:

- approximately `36–40` logical pixels for bar items;
- approximately `40–44` logical pixels for control-centre controls.

Targets may overlap visually empty padding but must not overlap neighbouring actions.

---

# 6. Spacing System

Use a shared spacing scale.

Recommended starting tokens:

```text
space.1 = 4
space.2 = 8
space.3 = 12
space.4 = 16
space.5 = 20
space.6 = 24
space.8 = 32
```

Avoid arbitrary values unless required for alignment.

## 6.1 Bar spacing

Use:

- tight spacing within one control;
- moderate spacing between related controls;
- larger gaps between semantic zones;
- fixed reserved region for contextual states.

Do not rely on separators between every element.

## 6.2 Control-centre spacing

Use:

- compact rows;
- clear section gaps;
- limited card padding;
- enough breathing room for pointer targets;
- consistent alignment of icons, labels, values, and affordances.

## 6.3 Notification spacing

Use:

- app identity and timestamp in a compact header;
- title/body grouping;
- consistent action spacing;
- smaller gaps inside groups than between application groups.

---

# 7. Typography

## 7.1 General character

Typography should be modern, compact, and highly legible.

Prefer:

- a clean variable sans font where available;
- tabular numerals for live metrics;
- clear differentiation between title, body, metadata, and numeric status;
- moderate weights rather than excessive size.

The font should support:

- Latin text;
- symbols used by the shell;
- locale expansion;
- numeric readability at small sizes.

The exact font family should remain configurable or selected later.

---

## 7.2 Type roles

Recommended semantic roles:

```text
type.display
type.title
type.section
type.body
type.label
type.metadata
type.metric
type.metricSmall
```

### Display

Use sparingly:

- large date in calendar;
- lock screen later.

### Title

Use for:

- panel title;
- detail page title;
- notification title;
- device/network name.

### Section

Use for:

- Notifications;
- Connected devices;
- Available networks;
- CPU/GPU sections.

### Body

Use for:

- notification body;
- explanatory text;
- detail values.

### Label

Use for:

- buttons;
- quick controls;
- menu items.

### Metadata

Use for:

- time;
- signal quality;
- connection details;
- secondary status.

### Metric

Use for:

- RAM percentage;
- battery percentage;
- network speed;
- OSD value;
- temperatures.

---

## 7.3 Numeric typography

Live values must use tabular numerals.

Applies to:

- network throughput;
- battery percentage;
- RAM;
- CPU/GPU usage;
- temperature;
- time;
- storage;
- volume;
- brightness.

This prevents layout jitter.

---

## 7.4 Bar text

Bar text should be used only where the information itself is textual or numeric.

Approved examples:

- workspace numbers;
- time;
- date;
- battery percentage;
- RAM percentage;
- network speed.

Avoid labels such as:

- RAM;
- BAT;
- WIFI;
- BT;
- VOL.

---

## 7.5 Truncation

Use predictable truncation:

- notification body → bounded lines with expansion path;
- window title → ellipsis in focused-window surface;
- network/device names → single-line ellipsis where required;
- tray tooltip → allow more detail;
- calendar event title later → ellipsis with full detail on selection.

Never truncate critical warnings without an expansion path.

---

# 8. Iconography

## 8.1 Icon style

Use one coherent icon family or normalize mixed sources.

Characteristics:

- simple;
- legible at small size;
- consistent stroke/fill weight;
- no ornamental detail;
- good optical centring;
- works in monochrome.

Avoid mixing:

- thin outline icons;
- heavy filled icons;
- skeuomorphic app-like icons;
- inconsistent corner language.

---

## 8.2 State through icon substitution

Use icon substitution when one stable slot can express changing context.

Examples:

- audio output: speaker / headphones / Bluetooth headset / mute;
- special workspace: neutral stack / active workspace icon;
- connectivity failure: disconnected / limited / captive portal;
- microphone: inactive hidden / active visible;
- recording: inactive hidden / active visible.

---

## 8.3 Badges

Avoid global unread badges.

Badges may be used locally for:

- notification group item count;
- multiple connected devices;
- overflow count inside a detail surface;
- progress state where value is useful.

Do not place a permanent notification count in the bar.

---

## 8.4 App icons

App icons are appropriate in:

- notifications;
- tray drawer;
- volume mixer;
- quickshell-overview;
- Vicinae.

They are not appropriate in:

- resting workspace pager;
- active-window bar item;
- general system-status controls.

---

# 9. Component Visual Rules

## 9.1 Numbered workspace pager

### Resting

- five compact numbers;
- inactive values low emphasis;
- active value inside a filled pill or expressive container;
- no occupancy markers;
- no app icons.

### Group transition

Crossing from `1–5` to `6–10` should use a short directional transition.

Do not animate every workspace switch with a large movement.

---

## 9.2 Special-workspace control

### Neutral

- layered-workspace or stack glyph;
- passive foreground.

### Active

- configured workspace icon;
- accent container or active foreground;
- optionally a subtle shape change.

The active icon should not cause the cell size to change.

---

## 9.3 Contextual-status region

- fixed reserved area;
- compact icon-only states;
- critical status receives stronger colour and optional contained pulse;
- overflow uses a stack motif;
- no layout shifting.

---

## 9.4 Tray affordance

- stacked or overlapping icon motif;
- hidden when no tray items exist;
- urgent state changes foreground or container;
- no persistent item count by default.

---

## 9.5 Download-speed indicator

- whole number;
- one-letter unit;
- tabular numerals;
- fixed-width cell;
- no arrow in resting state;
- no animation on ordinary value updates.

Tooltip:

```text
↓ 20M/s   ↑ 3M/s
```

---

## 9.6 Audio control

- icon reflects active output;
- mute state unmistakable;
- active popover state may use accent container;
- volume changes use OSD, not changing bar text.

---

## 9.7 Resource indicator

- circular progress arc;
- centred whole-number RAM percentage;
- no label;
- arc remains readable at small scale;
- warning state may change arc colour;
- avoid constant animated arc movement.

---

## 9.8 Battery value

- plain numeric percentage;
- tabular numerals;
- charging communicated by accent and restrained animation;
- warning/critical state semantically stronger;
- no mandatory battery icon.

Possible charging treatments:

- subtle underline sweep;
- slow tonal fill;
- periodic one-pass shimmer;
- small nonpersistent bolt accent.

Avoid flashing.

---

## 9.9 Date and time

Vertical bar may use stacked values.

Example:

```text
21
34

16
JUL
```

The exact arrangement should be tested against the selected bar width.

Rules:

- 24-hour time;
- one combined control;
- date remains unambiguous;
- month text is acceptable;
- use tabular numerals.

---

## 9.10 Vicinae entry point

- distinct command/search symbol or Vicinae mark;
- visually belongs to the shell;
- placed at absolute end;
- active/open state clearly indicated;
- unavailable state uses warning treatment and tooltip.

---

## 9.11 Quick-control tiles

Quick controls should be compact and stateful.

### Inactive

- neutral surface;
- neutral foreground;
- optional secondary state text.

### Active

- accent container;
- high-contrast foreground;
- label remains readable;
- optional expressive shape change.

### Detail affordance

Wi-Fi and Bluetooth should visibly distinguish:

- toggle area;
- detail-navigation area.

Do not make the split so small that pointer use becomes error-prone.

---

## 9.12 Sliders

Slider structure:

- leading icon;
- filled track;
- thumb or expressive endpoint;
- optional numeric value only where useful.

Rules:

- strong active fill;
- neutral inactive track;
- large enough drag target;
- keyboard focus visible;
- disabled state clearly distinct;
- volume and brightness share geometry.

---

## 9.13 Notification cards

Recommended structure:

```text
app icon  app name                 time
          title
          body
          actions
```

Rules:

- title stronger than body;
- metadata quieter;
- urgent state uses stronger container or edge marker;
- progress notification shows progress clearly;
- grouped cards share visual container or connector;
- dismiss control visible on hover/focus and available to keyboard;
- no unread dot.

---

## 9.14 Volume mixer rows

Each row may contain:

- app/device icon;
- app/device name;
- slider;
- mute action;
- optional output routing detail.

Rows should remain compact enough to show multiple applications without scrolling excessively.

---

## 9.15 Network and Bluetooth rows

Rows should communicate:

- identity;
- current state;
- signal/battery where available;
- action affordance;
- progress;
- error.

Use text where names matter. Do not reduce network/device lists to icons only.

---

## 9.16 Calendar

The prototype calendar should visually prioritize:

- current month;
- current day;
- selected day;
- clear week grid;
- simple navigation.

Do not reserve a large empty agenda area before event integration exists.

Future event colours should map through semantic calendar roles rather than arbitrary saturated colours.

---

# 10. Motion System

## 10.1 Motion goals

Motion should explain:

- origin;
- destination;
- selection;
- hierarchy;
- completion;
- drag threshold;
- state replacement.

Motion should not:

- delay input;
- decorate idle state;
- animate high-frequency metrics;
- run when invisible;
- compete across multiple regions.

---

## 10.2 Motion tokens

Use shared tokens such as:

```text
motion.instant
motion.fast
motion.standard
motion.slow

easing.standard
easing.emphasized
easing.decelerate
easing.accelerate
easing.linear
```

Recommended prototype ranges:

```text
instant  = 0–80 ms
fast     = 100–160 ms
standard = 180–240 ms
slow     = 280–360 ms
```

Exact values should be tuned after implementation.

---

## 10.3 Recommended motion mapping

### Hover/focus

- instant or fast;
- opacity, outline, or small shape response.

### Button press

- instant;
- slight scale or tonal compression;
- must not shift layout.

### Popover open/close

- fast or standard;
- move and fade from invoking edge.

### Control centre settle

- standard;
- direct manipulation while dragging;
- easing only after release.

### Notification popup

- standard entry;
- fast dismissal;
- burst replacement avoids full exit/re-entry.

### Workspace group change

- fast directional slide or crossfade;
- active item remains clear.

### Toast

- fast entry;
- standard hold;
- fast replacement.

### OSD

- fast appearance;
- no re-entry on every update;
- short fade after input ends.

### Theme change

- slow but bounded;
- avoid animating every raw colour independently;
- prevent unreadable intermediate states.

---

## 10.4 Reduced motion

Reduced-motion mode should:

- remove scale and morph effects;
- replace movement with short fades;
- disable charging shimmer;
- reduce theme-transition animation;
- keep state changes immediate;
- preserve direct manipulation feedback.

Critical state must remain understandable without pulsing.

---

# 11. Elevation, Outline, and Shadow

Wayland compositing and wallpaper variation make strong shadows unreliable as the primary separator.

Recommended priority:

1. tonal separation;
2. outline;
3. subtle shadow where useful.

## 11.1 Outlines

Use:

- subtle outline for neutral card boundaries;
- strong outline for keyboard focus;
- semantic outline for warning/critical state;
- no outline around every bar cell.

## 11.2 Shadows

Use sparingly for:

- detached popup;
- tooltip;
- notification popup;
- OSD.

Avoid heavy shadows on edge-attached control centre and bar.

---

# 12. Backdrops and Scrims

Use a scrim when a major surface needs clear modal separation.

Examples:

- control centre;
- session menu;
- destructive confirmation;
- overview, depending on adopted design.

Scrim characteristics:

- low-opacity neutral or wallpaper-derived darkening;
- click target for dismissal where safe;
- reduced or absent behind small popovers;
- no blur requirement.

The scrim must not make multi-monitor ownership ambiguous.

---

# 13. Light and Dark Modes

The initial shell may follow the generated Caelestia mode, but the token system should support both light and dark palettes.

Requirements:

- all semantic roles defined in both modes;
- warning and critical colours retain contrast;
- transparent surfaces remain readable;
- focus rings remain visible;
- app icons and tray icons are normalized where possible;
- user override may be added later.

Do not hard-code assumptions that all wallpapers produce a dark shell.

---

# 14. Dynamic Theme Transition

When wallpaper colours change:

1. generate and validate the new semantic palette;
2. keep the old palette active until the new one is complete;
3. update shell consumers atomically;
4. notify adopted components;
5. fall back safely if generation fails.

Consumers include:

- QML theme service;
- Vicinae theme file or command;
- quickshell-overview adapter;
- any generated CSS or configuration later.

Avoid partial updates where different surfaces briefly use different palettes.

---

# 15. External Component Adaptation

## 15.1 Vicinae

Vicinae should share:

- wallpaper-derived palette;
- broad typography mood where configurable;
- icon conventions where extension UI permits;
- shell command naming.

Do not fork Vicinae solely to reproduce every QML geometry or motion token.

Its central floating form is a deliberate exception to the shell's edge-attached spatial grammar.

---

## 15.2 quickshell-overview

quickshell-overview should be adapted to:

- shared palette;
- shared workspace definitions;
- shared spacing and corner tokens;
- shared focus treatment;
- shared motion durations where practical.

Preserve its core interaction strengths.

Do not degrade keyboard or drag-and-drop functionality for visual consistency.

---

## 15.3 Caelestia services

Retained Caelestia services should expose normalized data or colour roles to Franken Shell.

Avoid importing Caelestia-specific visual assumptions directly into every component.

---

# 16. Responsive and Edge-Adaptive Layout

The bar may hug any screen edge.

Components must define separate layout strategies where necessary.

## 16.1 Vertical bar

Appropriate patterns:

- stacked time;
- vertical workspace numbers;
- icon-first controls;
- compact numeric cells;
- popovers opening inward horizontally.

## 16.2 Horizontal bar

Appropriate patterns:

- inline time and date;
- horizontal workspace sequence;
- inline metrics;
- popovers opening inward vertically.

## 16.3 Do not rotate blindly

Avoid:

- rotated text for time or labels;
- rotated progress indicators that become hard to read;
- unchanged vertical spacing on horizontal bars.

Each component should have an orientation-aware delegate or layout.

---

# 17. Multi-Monitor Visual Rules

The complete ownership policy remains open, but visuals should support:

- per-monitor scaling;
- fractional scale;
- mixed orientation;
- edge-specific corner treatment;
- consistent logical size;
- no half-pixel borders where possible;
- popup placement within monitor bounds;
- notification and OSD ownership on one monitor only.

Testing must include rotated and differently scaled monitors.

---

# 18. Accessibility and Contrast

## 18.1 Contrast

All generated palette combinations must be contrast-checked.

Particular attention:

- small bar metrics;
- accent text on accent containers;
- disabled text;
- notification metadata;
- warning/critical text;
- focus outlines;
- translucent popup backgrounds.

## 18.2 Non-colour cues

Use:

- glyph changes;
- labels;
- outlines;
- shape;
- pattern or position;
- animation only as supplemental feedback.

Examples:

- mute uses mute glyph, not only red colour;
- charging uses animation or accent treatment plus tooltip;
- recording uses recording glyph;
- no internet uses disconnected glyph.

## 18.3 Text scaling

Components should tolerate moderate text scaling without:

- clipping;
- losing controls;
- overlapping icons;
- breaking fixed bar cells.

Where space is constrained, switch layout rather than shrink text below legibility.

---

# 19. Performance Rules for Visuals

- stop animations when hidden;
- avoid animating high-frequency numeric changes;
- avoid large blur regions;
- lazy-load detail pages;
- reuse delegates for long lists;
- avoid full-window shader effects in the prototype;
- cache icon lookups;
- update sensor visuals at conservative rates;
- simplify control-centre content during active edge drag if necessary;
- do not animate every colour independently during theme changes.

---

# 20. Token Naming Recommendation

A possible QML token hierarchy:

```text
Theme.colors.*
Theme.type.*
Theme.spacing.*
Theme.radius.*
Theme.motion.*
Theme.outline.*
Theme.elevation.*
Theme.opacity.*
Theme.metrics.*
```

Example usage:

```qml
Rectangle {
    radius: Theme.radius.medium
    color: Theme.colors.surfaceRaised
    border.color: activeFocus
        ? Theme.colors.outlineFocus
        : Theme.colors.outlineSubtle
}
```

Component-specific mappings may live under:

```text
Theme.components.bar.*
Theme.components.notification.*
Theme.components.controlCenter.*
Theme.components.workspace.*
```

Avoid copying raw values into component files.

---

# 21. Initial Prototype Token Set

The first implementation should define at least:

## Colours

```text
surfaceBase
surfaceRaised
surfaceOverlay
surfacePopup
surfaceScrim

textPrimary
textSecondary
textDisabled
textOnAccent

accentPrimary
accentContainer
accentOnContainer

outlineSubtle
outlineStrong
outlineFocus

success
warning
critical
privacy
```

## Spacing

```text
space1
space2
space3
space4
space5
space6
space8
```

## Radius

```text
radiusSmall
radiusMedium
radiusLarge
radiusFull
```

## Typography

```text
fontFamily
fontSizeMetricSmall
fontSizeMetric
fontSizeLabel
fontSizeBody
fontSizeSection
fontSizeTitle

fontWeightRegular
fontWeightMedium
fontWeightSemibold
```

## Motion

```text
durationInstant
durationFast
durationStandard
durationSlow

easingStandard
easingEmphasized
easingDecelerate
easingAccelerate
```

## Metrics

```text
barThickness
barItemExtent
controlCenterWidth
popoverMaxWidth
notificationWidth
iconSmall
iconMedium
iconLarge
focusRingWidth
outlineWidth
```

---

# 22. Visual Acceptance Checklist

Before considering a component visually complete, verify:

1. Does it use semantic tokens instead of raw colours?
2. Is it quieter at rest than when active?
3. Is its active state unmistakable?
4. Is keyboard focus distinct from selection?
5. Does it remain readable on light and dark wallpaper-derived palettes?
6. Does it avoid redundant labels?
7. Does it use tabular numerals for changing values?
8. Does its size remain stable as values change?
9. Does it adapt to vertical and horizontal bar orientation?
10. Is the pointer hit target large enough?
11. Is state understandable without colour?
12. Does reduced motion preserve meaning?
13. Does animation explain cause and effect?
14. Does the component remain legible with text scaling?
15. Does it visually belong to the same shell as the control centre and notifications?
16. Does it avoid excessive blur, shadow, or card nesting?
17. Does it retain usability when a dynamic colour source fails?
18. Does it avoid duplicating visual emphasis already used by another state?

---

# 23. Open Visual Questions

The following should be resolved through prototypes rather than decided abstractly:

- final font family;
- exact bar thickness;
- exact control-centre width;
- whether the bar is fully flush or slightly inset along its long axis;
- exact active-workspace shape;
- exact date/time arrangement;
- whether battery percentage includes `%`;
- exact charging animation;
- OSD placement;
- notification popup width;
- degree of control-centre opacity;
- whether popovers use subtle blur;
- exact icon family;
- theme transition duration;
- light-mode behaviour;
- quickshell-overview adaptation depth;
- Vicinae theme mapping;
- high-contrast mode;
- final corner-radius scale.

These decisions should be made after real QML prototypes are tested on the user's actual display and wallpaper set.
