# ADR-001 — Control Centre Window Primitive

**Status:** Accepted

**Date:** 2026-07-30

**Decision:** [D-051](../decisions.md#d-051--control-centre-window-primitive)

## Context

The control centre needs a right-attached, monitor-owned surface that:

- reserves no permanent workspace area;
- can cover the owning monitor with a scrim;
- accepts deterministic keyboard focus;
- supports pointer interaction and outside-click dismissal;
- remains one major surface under `SurfaceCoordinator`;
- can expose direct reveal progress in PR-010;
- behaves predictably with existing panels and across QML reload.

The pinned baseline offers three plausible transports:

- a layer-shell `PanelWindow`;
- an anchored `PopupWindow`;
- a compositor-managed `FloatingWindow`.

## Decision

Use one full-monitor Quickshell `PanelWindow` per eligible monitor. The window:

- anchors to all four monitor edges;
- uses the overlay layer;
- sets `exclusionMode: ExclusionMode.Ignore` and `exclusiveZone: 0`;
- is visible only while `SurfaceCoordinator` grants that monitor ownership;
- contains both the owning-monitor scrim and a right-attached drawer item;
- requests layer-shell keyboard focus only for keyboard-origin opening.

The drawer remains an item within that window. PR-010 will vary the item's
reveal progress without changing the top-level primitive.

Keyboard-origin toggling uses the versioned `shell` IPC operation
`toggleControlCenter`; a compositor shortcut may bind to that stable command.
Pointer callers use the same host API with a pointer origin. The current
prototype does not take keyboard focus on pointer opening. Final pointer-open
focus policy remains Q-018.11 in the feature specification.

The offscreen test harness uses a `FloatingWindow` only as a transport for the
same `ControlCenterSurface`, because Qt's offscreen platform does not provide a
layer-shell backend. It is not the production primitive.

## Alternatives considered

### `PopupWindow`

Rejected for the major host. Its anchor and parent-popup lifecycle fit bar
popovers, but not an independent full-monitor scrim plus a full-height,
directly manipulated drawer. Franken Shell continues to use it for ordinary
anchor-owned bar popovers.

### `FloatingWindow`

Rejected for production. It is a compositor-managed toplevel rather than an
edge-attached layer surface, so placement, layer ordering, monitor coverage,
and outside-click ownership would be less deterministic.

### Multiple production windows

A separate drawer and scrim window were not required by the prototype. One
window gives the coordinator one visibility, focus, and dismissal boundary.
The decision can be revisited if PR-010 demonstrates a layer input-region
limitation that cannot be solved without brittle timing or duplicated state.

## Evidence

Deterministic component fixtures verify:

- pointer and keyboard open/close paths;
- right attachment, ignored exclusion zones, and zero exclusive zone;
- owning-monitor scrim dismissal;
- bar-popover replacement and major-surface arbitration;
- deterministic initial keyboard focus;
- Escape restoration and direct focus transfer;
- no arbitrary timing delays in focus logic.

Offscreen smoke verifies one host before and after soft reload, no duplicate
scrim, and keyboard-origin IPC open/close ownership.

On the accepted Quickshell/Hyprland Wayland baseline, the production prototype:

- negotiated the complete `1920 × 1080` test monitor while other panels held
  exclusive zones;
- reported exactly one open host and one visible scrim;
- focused the deterministic Close control;
- received a real Escape key event, closed through `SurfaceCoordinator`, and
  emitted exactly one restoration request;
- added no QML warning, binding-loop, or component-load error.

Outside-click behaviour is covered by the shared-surface component fixture.
Direct edge dragging and continuous reveal remain the blocking scope of
PR-010.

## Consequences

- Feature pages remain independent of the top-level window type.
- The scrim is initially limited to the owner monitor; final multi-monitor
  scrim policy remains unresolved.
- Pointer opening remains pointer-active without immediately requesting
  keyboard focus; the final transition-to-keyboard policy remains unresolved.
- PR-010 must fail its merge cutoff if direct manipulation exposes a primitive
  limitation; it must not compensate with timing sleeps or parallel ownership.
