# Franken Shell — Session and Lock

> **Path:** `docs/features/session-and-lock.md`
> **Status:** Implementation specification
> **Primary phase:** Phase 6 — Session entry point and safe supported actions; lock redesign deferred
> **Related specifications:** `control-centre.md`, `vicinae-integration.md`, `multi-monitor.md`

This document specifies safe session actions and the boundary to the unresolved lock-screen implementation.

---

# 1. Product Role

The control-centre power icon opens a dedicated session surface. It never performs immediate shutdown. The surface offers supported session actions with deliberate friction. Lock invocation is supported through an adapter, but the lock-screen implementation remains unresolved and may initially retain the current solution.

# 2. Settled Requirements

- The session surface may offer lock, suspend, logout, reboot, shutdown, and hibernate only when supported.
- Lock and suspend may be immediate where safe.
- Logout, reboot, and shutdown require explicit confirmation by default.
- Hibernate is capability-driven.
- Small header controls never directly perform destructive actions.
- Session views use controller/command IDs, not raw shell strings.
- Main shell remains unprivileged.
- Lock-screen redesign is deferred until main surfaces stabilize.
- No custom lock implementation assumptions may be coupled into the session menu.
- Security and authentication reliability take precedence over visual integration.

# 3. Ownership

Session owns action capability presentation, confirmation state, pending task state, action dispatch, and session-specific diagnostics.

The lock integration boundary owns normalized lock availability/invocation and lifecycle observation where available.

This feature does not own:

- the final locker choice, PAM UI, fingerprint, or authentication policy;
- idle-daemon policy;
- direct system commands in QML;
- control-centre hosting;
- compositor/session backend implementation details not verified by research.

# 4. Proposed Structure

```text
services/
├── SessionService.qml
└── LockAdapter.qml

features/session/
├── SessionController.qml
├── SessionSurface.qml
├── SessionAction.qml
├── ConfirmationView.qml
└── fixtures/SessionFixtureModel.qml
```

No custom lock QML structure is specified until Q-086 is resolved.

`SessionService`/`LockAdapter` own capability discovery and backend action execution. `SessionController` owns confirmation policy, pending state, and feedback mapping. Session views render supported actions and request controller operations; they do not execute commands or authenticate.

# 5. State and Service Contract

Expose:

```text
serviceLifecycle
actions[] {
  id
  label
  icon
  available
  requiresConfirmation
  disabledReason
}
confirmationAction?
operationTask?
lockAvailability
lockedState?        // only if reliably observable
lastError
```

Conceptual actions:

```text
request(actionId, invocationContext)
confirm()
cancelConfirmation()
cancelTask() // only where backend supports it
```

Each configured command ID resolves through an internal adapter or `CommandRegistry`; raw configured strings never reach views or shell IPC.

# 6. Interaction

- Control-centre power action opens the session surface.
- Vicinae may request the same versioned open/lock actions.
- The configurable session shortcut requests the same session surface through `SurfaceCoordinator`.
- Arrow keys navigate; activation selects; `Escape` cancels confirmation, returns to parent, or closes.
- Pointer primary activation selects an action; destructive actions transition to confirmation rather than execute.
- Secondary, middle-click, scroll, hover, and drag have no action semantics beyond tooltip/focus presentation.
- Confirmation states name the exact action and provide distinct confirm/cancel targets.
- Repeated activation while an action is pending is ignored or explained.

Destructive actions, confirmation focus, disabled reasons, and pending state must be explicit without colour-only meaning. Large text and keyboard navigation must preserve separation between confirm and cancel; reduced motion never weakens the confirmation step.

# 7. Opening, Dismissal, and Focus

`SurfaceCoordinator` owns visibility, monitor, dismissal, and restoration. The control-centre entry point forwards an opening request; whether the resulting surface is modal, edge-attached, or otherwise hosted remains Q-085.

Outside click may dismiss the initial action list, but not silently confirm or obscure an in-flight destructive request. After cancellation/failure, restore focus to the invoking control. After successful logout/reboot/shutdown, focus restoration is irrelevant; after failed suspend/lock, it remains required.

Keyboard opening focuses lock or another cancel-safe first action, never shutdown/reboot. Pointer opening does not steal keyboard focus until keyboard navigation begins. `Escape` cancels confirmation before closing the surface; outside click is ignored while confirmation, authorization, or another protected operation is active.

# 8. Failure, Permission, and Capability States

Distinct states include:

- session backend unavailable/reconnecting;
- action unsupported;
- hibernate unavailable;
- lock adapter missing;
- permission denied/cancelled;
- action timed out/failed;
- command configured but executable unavailable;
- lock requested but lifecycle not observable.

Unsupported actions are omitted or explained, never left as dead permanent controls. A failure from explicit user action produces a longer-lived system failure toast with details/retry where safe.

# 9. Lock Boundary and Privacy

Until Q-086 is resolved:

- retain the current proven locker where practical;
- expose only a narrow `lock()` adapter contract;
- do not claim Franken Shell owns authentication;
- do not add decorative lock content that weakens privacy;
- do not persist credentials or authentication results;
- do not implement unlock through general shell IPC.

Any future custom lock requires a separate security review, Wayland session-lock compatibility tests, per-output surfaces, authentication-provider design, failure recovery, and prevention of desktop exposure.

# 10. Dependencies and Configuration

Dependencies include the selected session adapter, configured command-registry targets, `CapabilityRegistry`, `Diagnostics`, `SurfaceCoordinator`, `MonitorRegistry`, and toast publisher. Do not assume a logind transport until the retained/native service contract is verified.

Configuration lists desired actions and confirmation policy. Capability normalization may remove unsupported actions. Configuration cannot disable safety checks in the backend or expose arbitrary command interpolation.

# 11. Multi-Monitor and Performance

The session surface is global but appears on one resolved monitor. A future lock typically requires all outputs; that is a separate security surface, not “one session popover per monitor.”

Owner-monitor removal during confirmation moves/closes according to `multi-monitor.md` without executing the action. Service state is event-driven; no hidden high-frequency polling is justified.

# 12. Fixtures

- all actions available; hibernate absent; lock adapter absent;
- destructive confirmation/cancel;
- permission denied, timeout, backend reconnect;
- command missing;
- duplicate activation while pending;
- owner monitor removed during confirmation;
- lock requested with observable/unobservable success.

# 13. Implementation Phases

1. **Phase 3 fixture entry:** safe session navigation, placeholder host, and confirmation mechanics.
2. **Phase 6 daily-use entry point:** expose the supported actions available through the selected existing session/lock adapters, with failure feedback and no lock redesign.
3. **Phase 10:** monitor/focus/hotplug hardening.
4. **Later dedicated lock phase:** resolve Q-086, security design, implementation, and audit.

# 14. Acceptance Criteria

- The control-centre power icon opens a menu/surface and never directly shuts down.
- Destructive actions require explicit confirmation.
- Unsupported actions are omitted/explained; hibernate is capability-driven.
- Views contain no raw session commands.
- Permission denial/failure leaves the shell focused and usable.
- Lock invocation works through the selected adapter when available, without assuming a custom lock.
- Keyboard opening initially focuses a cancel-safe action, and protected confirmation cannot be dismissed accidentally.
- The control-centre entry point and configurable shortcut use the same controller and `SurfaceCoordinator` opening path rather than parallel menus.
- No unlock/credential capability is exposed through general shell IPC.
- Monitor removal during confirmation cannot execute an action.

# 15. Unresolved Questions

- **Q-085:** final session-surface form.
- **Q-086:** lock implementation ownership.
- **Q-087:** hibernate capability/visibility details.
- **Q-001, Q-002:** exact Quickshell/session and retained lock-service baseline where material.
- Exact session backend, action cancellation, and success observation remain research items.

# 16. Codex Implementation Guardrails

- Do not implement a custom lock screen in this task/phase by convenience.
- Do not put destructive actions on a one-click header control.
- Do not expose unlock, passwords, or arbitrary session commands through IPC.
- Do not claim action success without backend evidence appropriate to the action.
