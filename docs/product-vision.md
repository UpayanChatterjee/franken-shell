# Franken Shell — Product Vision

> **Status:** Working design baseline  
> **Project codename:** `franken-shell`  
> **Target platform:** Hyprland 0.55+ with Lua configuration  
> **Primary UI framework:** Quickshell / QML

## Purpose

Franken Shell is a custom desktop shell built around a heavily modified Caelestia setup. It retains selected Caelestia services and capabilities, adopts proven ideas from Illogical Impulse and ActivSpot, and integrates external tools such as Vicinae and quickshell-overview where they already solve a problem well.

The project is not intended to recreate a complete desktop environment or duplicate applications that already provide a superior experience. Its purpose is to provide a coherent shell layer around Hyprland: persistent status, spatial navigation, notifications, system controls, transient feedback, and focused utility surfaces.

## Vision

Franken Shell should be **minimal by default and comprehensive on command**.

During ordinary work, the shell remains quietly visible and exposes only information that is frequently useful, immediately actionable, or important enough to demand attention. Secondary controls, notification history, device management, and detailed system information remain hidden until deliberately invoked.

The shell should feel like one integrated product rather than a collection of unrelated widgets. Borrowed components and external tools should be adapted to a shared visual, interaction, and configuration language.

The intended experience is:

- **Elegant:** visually cohesive, restrained at rest, and free from unnecessary chrome.
- **Fast:** low-friction access to common actions through stable shortcuts, gestures, and direct manipulation.
- **Precise:** predictable placement, stable layouts, clear state communication, and deliberate motion.

## Core Experience Principles

### Quietly visible

The shell is not invisible, but it does not compete with application content.

Persistent UI should contain only:

- stable navigation;
- essential system status;
- immediately useful controls;
- exceptional or active states that matter now.

Normal connectivity and inactive features should remain silent. Problems, active peripherals, privacy-sensitive states, and user-triggered changes should become visible when relevant.

### Comprehensive on command

Features that are too large or too infrequently used for the resting shell should be available through focused surfaces.

Examples include:

- notification history;
- Wi-Fi network selection and connection;
- Bluetooth pairing and device management;
- per-application audio mixing;
- power-management configuration;
- detailed system statistics;
- workspace and window overview;
- calendar and future agenda integration.

The shell should reduce the need to open a full settings application for routine desktop management without trying to replace every advanced configuration tool.

### Keyboard first, pointer complete

Keyboard interaction has the highest priority, followed closely by mouse and trackpad interaction.

Every major workflow should have:

- a fast keyboard path;
- a discoverable pointer path;
- correct keyboard focus and dismissal behaviour;
- gesture support where a spatial gesture provides a genuine advantage.

Pointer support must not be treated as a fallback. Dragging, scrolling, secondary-click actions, hover feedback, and trackpad gestures should be deliberately designed.

### Stable spatial grammar

The shell uses screen edges consistently:

- **Configured bar edge:** persistent navigation and essential status.
- **Right edge:** control centre, notifications, and occasional system management.
- **Focused edge-attached popovers:** details opened from bar components.
- **Central floating command surface:** Vicinae, as a deliberate exception for search and command execution.

On the default layout:

- the bar hugs the left edge;
- the control centre is dragged in from the right edge;
- the bar can later be configured for any screen edge without changing its conceptual hierarchy.

### Restrained at rest, expressive in response

Android Material You Expressive is the overarching visual influence, but it should not make the resting shell oversized, bubbly, or visually noisy.

At rest:

- geometry is compact;
- passive components have restrained contrast;
- text is omitted where shape, iconography, value, and position are sufficient;
- persistent animation is minimal.

During interaction:

- selected controls gain stronger colour and shape;
- panels expand from their spatial origin;
- motion explains state transitions;
- wallpaper-derived accents become more prominent;
- interaction targets may grow when a surface opens.

## Visual Identity

The shell should use Caelestia's wallpaper-derived dynamic colour system across all relevant surfaces.

The shared visual language should cover:

- semantic colour roles;
- surface and elevation roles;
- typography;
- iconography;
- spacing;
- corner geometry;
- focus, hover, pressed, active, warning, and critical states;
- motion durations and easing;
- opaque and translucent surface rules.

The control centre should be more opaque and readability-focused than the Illogical Impulse reference, while preserving its dense utility-oriented composition.

The shell may be technical and instrument-like where that improves efficiency, but should remain minimal and polished rather than looking like a diagnostic dashboard.

## Product Structure

### Persistent bar

A continuous edge-attached rail containing:

- numbered workspace pager;
- compact special-workspace control;
- fixed contextual-status region;
- collapsed system tray;
- current download-speed indicator;
- audio control;
- compact resource indicator;
- battery percentage and charging treatment;
- combined date and time;
- Vicinae entry point at the absolute end.

The default bar is vertical on the left edge, remains visible with maximized windows, hides in true fullscreen, and supports an optional autohide mode.

### Right-edge control centre

A hidden utility drawer opened by keyboard or by clicking and dragging left from the extreme right edge.

It contains:

- notification history;
- Wi-Fi, Bluetooth, Do Not Disturb, Night Light, and idle-inhibitor controls;
- persistent volume and brightness sliders;
- per-application volume mixer;
- comprehensive Wi-Fi and Bluetooth management pages;
- links to settings and session controls.

It defaults to the Notifications view.

### Command layer

Vicinae is the canonical application launcher and command interface.

It should be treated as a first-class integration rather than recreated in Quickshell. A shell-specific Vicinae extension should expose shell commands and focused entry points.

The shell must remain functional if Vicinae is unavailable; only command-layer actions should degrade.

### Workspace and window overview

`quickshell-overview` is the adopted visual workspace and window overview.

It should be adapted to:

- the shared dynamic colour system;
- the Material You Expressive visual language;
- the shell's workspace configuration;
- the shell's settings and IPC conventions.

The project should pin and test a known-good revision and be prepared to maintain compatibility fixes.

### Focused utility surfaces

Dedicated edge-attached popovers and panels provide depth without bloating the bar.

Initial examples include:

- audio controls;
- resource details;
- auto-cpufreq power configuration;
- calendar;
- tray drawer;
- focused-window actions;
- special-workspace selector.

## Notification and Feedback Model

The shell distinguishes three feedback channels.

### Application notifications

- All applications may show notification popups by default.
- Notifications are silent by default.
- Repeated notifications are grouped by application.
- Notification history lives in the control centre.
- No global unread count or notification badge is shown.
- Optional sounds may later be configured per application or notification-title rule.

### System configuration toasts

User-triggered state changes produce compact transient confirmation toasts, such as:

- Wi-Fi enabled;
- Bluetooth disabled;
- Night Light enabled;
- output device changed;
- auto-cpufreq configuration applied.

Successful confirmation toasts do not enter notification history. Failures may remain longer and provide actions.

### OSDs

Continuous direct manipulation uses dedicated transient OSDs.

Initial OSDs include:

- volume;
- brightness.

Track changes produce neither notifications nor OSDs.

## Do Not Disturb Philosophy

Do Not Disturb suppresses interruption, not feedback.

It suppresses ordinary application popups and sounds while preserving notification history.

It does not suppress:

- user-triggered configuration toasts;
- volume and brightness OSDs;
- failures caused by an action the user just requested;
- critical hardware, safety, security, call, alarm, timer, or authentication events.

Critical bypass rules should be conservative and configurable.

## Adopt, Integrate, Do Not Rebuild

The project should prefer integration over duplication when an existing component already provides a high-quality solution.

Current first-class adopted components:

- **Caelestia services and dynamic colours**
- **Vicinae** for launching, search, and commands
- **quickshell-overview** for visual workspace and window management

Adoption does not mean uncontrolled coupling. Each integration should use a small, stable boundary and degrade gracefully when unavailable.

## Explicit Non-Goals

The initial project is not intended to:

- become a complete replacement for all system settings;
- implement another application launcher alongside Vicinae;
- rebuild quickshell-overview from scratch;
- display every available metric or status persistently;
- imitate Android layouts literally;
- copy Illogical Impulse or Caelestia without adaptation;
- prioritize decorative animation over responsiveness;
- expose advanced network, storage, or hardware administration in the first prototype;
- depend on application icons or active-window titles in the resting bar.

## Success Criteria

The shell is moving in the intended direction when:

1. Normal work is not visually interrupted by unnecessary shell chrome.
2. Frequent keyboard actions are immediate and predictable.
3. Every important workflow is also usable with a mouse.
4. Trackpad gestures enhance navigation without conflicting with Hyprland workspace gestures.
5. The resting bar remains stable when contextual indicators appear.
6. Common network, Bluetooth, audio, notification, and power tasks do not require opening a full settings application.
7. External integrations feel visually and behaviourally native enough to form one product.
8. Fullscreen applications remain free from ordinary interruptions.
9. Wallpaper changes propagate coherently through shell colour roles.
10. The shell remains responsive and understandable even when optional integrations fail.

## Design Motto

> **Minimal by default. Comprehensive on command. Restrained at rest, expressive in response.**
