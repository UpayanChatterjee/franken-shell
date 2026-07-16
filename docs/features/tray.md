# Franken Shell — System Tray

> **Path:** `docs/features/tray.md`
> **Status:** Implementation specification
> **Primary phases:** Phase 4 — Core System Adapters; Phase 6 — Working Daily-Use Prototype
> **Related specifications:** `bar.md`, `multi-monitor.md`

This document specifies collapsed StatusNotifierItem access and tray interaction. Application-specific behaviour remains owned by each tray item.

---

# 1. Product Role

The tray keeps tray-heavy applications accessible without letting their population expand the resting bar. One affordance opens a focused drawer containing all items.

# 2. Settled Requirements

- The tray is collapsed by default into one bar affordance.
- No application is pinned by default.
- The affordance hides when empty.
- The collapsed affordance shows no persistent tray-item count.
- All items remain available in the drawer.
- Application-provided activation, secondary activation, scroll, status, tooltip, and menu semantics are preserved.
- Attention may alter the collapsed affordance, but noisy applications must not keep the bar permanently over-emphasized.
- Optional pinning is later scope and must use stable identifiers.
- Tray protocol handling is adapter-owned; views do not reconstruct application menus.

# 3. Ownership

Tray owns normalized item enumeration, stable presentation ordering, collapsed aggregate state, drawer layout/focus, protocol-action forwarding, and tray diagnostics.

It does not own:

- application-specific action meaning;
- unread notification state;
- custom menu interpretation;
- global bar layout;
- a replacement settings UI for tray applications;
- backend-specific D-Bus calls from delegates.

# 4. Proposed Structure

```text
services/TrayService.qml
features/tray/
├── TrayController.qml
├── TrayAffordance.qml
├── TrayPopover.qml
├── TrayItemDelegate.qml
└── fixtures/TrayFixtureModel.qml
```

`TrayService` owns StatusNotifierItem/menu protocol objects and action forwarding. `TrayController` derives aggregate attention, stable session ordering, capability, and focus-safe presentation state. Affordance/item/menu views render and request protocol actions.

# 5. State and Adapter Contract

Each item exposes:

```text
stableId
serviceId
title
status: Passive | Active | NeedsAttention
category
icon
attentionIcon?
tooltip
menuAvailable
scrollAvailable
availableActions
```

Controller state includes item list, ordered visible list, empty/attention summary, menu task, service lifecycle, and last error.

Conceptual actions:

```text
activate(itemId, position?)
secondaryActivate(itemId, position?)
scroll(itemId, delta, orientation)
openMenu(itemId, anchor)
closeMenu()
```

Use Quickshell/system D-Bus menu facilities where supported.

# 6. Drawer Presentation and Interaction

- Primary activation of the collapsed affordance toggles the tray popover.
- Secondary and middle-click on the aggregate affordance have no settled action.
- Scroll over the aggregate affordance has no default item target and therefore no action.
- Hover provides “System tray” and attention summary without a count.
- Item primary, secondary, middle-click, and scroll events are forwarded only when supported by that item/protocol.
- Keyboard navigation reaches every item, exposes accessible name/status, activates the primary action, and opens the context menu.
- Drag-to-pin/reorder is not part of initial scope.
- Tooltips must not expose raw protocol markup unsafely.

Keyboard opening focuses the first tray item; if the model is empty during the opening transition, focus remains on the aggregate trigger and the popover closes. Pointer opening does not steal keyboard focus until keyboard navigation begins.

The aggregate affordance and each item expose title/status without requiring icon recognition. Keyboard focus is visible independently of attention, and high contrast/text scaling do not collapse menu or item targets.

# 7. Opening, Menus, Dismissal, and Focus

The tray popover is an ordinary bar popover owned by `SurfaceCoordinator`. Opening it closes another bar popover. Opening an item menu creates nested focus/escape state:

1. `Escape` closes the application menu;
2. next `Escape` closes the tray popover;
3. focus returns to the aggregate affordance.

Outside click closes the deepest dismissible layer. Menu activation that opens an application may close the popover according to protocol/user-observed behaviour, but must not invalidate the item action.

# 8. Loading, Empty, and Failure States

- Empty tray hides the affordance and closes an open empty popover.
- Service starting/reconnecting may preserve stable last-known item shells briefly but must not forward actions to stale objects.
- Invalid icon uses a fallback without dropping the item.
- Menu unsupported/failed is distinct from item activation failure.
- Complete tray capability absence omits the affordance; runtime service failure after availability was established uses a scoped degraded explanation and diagnostics.
- Item disappearance while focused moves focus predictably to the next item or aggregate trigger.
- Duplicate/unstable identifiers are diagnosed and receive session-stable fallback IDs without pretending they are suitable for persistence.

# 9. Dependencies and Configuration

Dependencies include Quickshell system tray and D-Bus menu support or selected adapter, `CapabilityRegistry`, `Diagnostics`, `ConfigService`, `SurfaceCoordinator`, and `MonitorRegistry`.

Configuration owns enabled state, hide-when-empty, stable ordering mode, future pin list, and bounded attention treatment. No project-default pins are allowed.

# 10. Multi-Monitor and Performance

Tray item state is global. Multiple bars must not register multiple watchers or duplicate application items. The drawer opens on the invoking bar monitor; only one ordinary bar popover is open globally.

Enumeration is event-driven. Icons are cached/bounded. Menu models load lazily when opened. Hidden drawers do not animate or repeatedly sort. Stable ordering prevents movement when status changes.

# 11. Fixtures

- empty, one item, many items;
- passive/active/attention items;
- missing/broken icons, long titles/tooltips;
- primary/secondary/scroll/menu-capable combinations;
- nested and disabled menu entries;
- service reconnect and item disappearance while focused/menu open;
- duplicate/unstable identifiers;
- multiple bars invoking one global tray model.

# 12. Implementation Phases

1. **Phase 2 fixture affordance/popover:** empty, many-item, focus and menu layers.
2. **Phase 4 adapter:** normalized StatusNotifierItem and menu contracts.
3. **Phase 6 daily use:** stable ordering and pointer/keyboard-complete drawer.
4. **Later:** pinning UX and refined attention policy after Q-073–Q-076.
5. **Phase 10/11:** monitor/focus, accessibility, and visual hardening.

# 13. Acceptance Criteria

- Empty tray consumes no resting bar slot.
- Any tray population remains represented by one aggregate affordance.
- Every item remains reachable by keyboard and pointer.
- Supported application click, secondary, scroll, and menu behaviour is forwarded.
- Supported application-defined middle-click behaviour is forwarded without assigning shell-global semantics.
- Closing an item menu restores focus to its item when present; closing the tray restores focus to the aggregate affordance or prior application according to the opening path.
- While Q-074 remains unresolved, non-ordering property updates preserve visible row order and focus; removal moves focus to the next valid item.
- One service model feeds all monitor bars.
- No application is pinned by default, and tray attention never creates a shell-global unread count.

# 14. Unresolved Questions

- **Q-001, Q-002:** exact Quickshell tray capability and retained service.
- **Q-073:** final drawer layout.
- **Q-074:** exact stable ordering key.
- **Q-075:** later pinning UX and unstable identifiers.
- **Q-076:** aggregate attention semantics and duration.
- Exact middle-click compatibility and menu-close behaviour require protocol/upstream verification.

# 15. Codex Implementation Guardrails

- Do not render all tray icons in the resting bar.
- Do not reinterpret application-owned actions or menus.
- Do not create one watcher/model per monitor.
- Do not introduce default pins or a notification-like count.
