# Franken Shell — OSDs and System Toasts

> **Path:** `docs/features/osds-and-toasts.md`
> **Status:** Implementation specification
> **Primary phase:** Phase 5 — Notifications and Feedback
> **Related specifications:** `audio.md`, `network-and-bluetooth.md`, `notifications.md`, `multi-monitor.md`

This document specifies transient shell feedback for direct manipulation and user-triggered system changes. Application notifications remain owned by `notifications.md`.

---

# 1. Product Role

OSDs answer “what value am I changing now?” System toasts answer “did the requested system change succeed?” Both are brief, keyed, non-historical by default, visually distinct from application notifications, and visible during DND when user-triggered.

# 2. Settled Requirements

- Three channels remain distinct: application notifications, system toasts, and OSDs.
- Initial OSDs are volume and brightness.
- Repeated changes update one OSD instance in place.
- Track changes produce no notification or OSD.
- System configuration changes produce brief confirmation toasts.
- Repeated toasts in one category replace/update rather than stack noisily.
- Successful toasts do not enter notification history.
- Failures remain longer and may expose Retry/Open Details.
- DND does not suppress user-triggered OSDs, toasts, or action failures.
- User-triggered OSDs/toasts may appear over true fullscreen.

# 3. Ownership

This feature owns OSD/toast admission, keyed replacement, presentation-ready records, timing, hosts, animation policy, and feedback-specific diagnostics.

It does not own:

- the underlying audio, brightness, network, Bluetooth, power, or other action;
- application notification history/policy;
- deciding action success before the owning controller reports it;
- global monitor resolution;
- arbitrary command retries.

# 4. Proposed Structure

```text
services/feedback/
├── OsdService.qml
└── ToastService.qml

features/feedback/
├── OsdHost.qml
├── OsdView.qml
├── ToastHost.qml
├── ToastView.qml
└── fixtures/FeedbackFixtureModel.qml
```

Originating feature controllers own the system action and publish normalized feedback records. OSD/toast services own keyed replacement and timing. Hosts/views render the resolved record and forward only explicit feedback actions; they never perform the original system mutation.

# 5. Record Contracts

OSD record:

```text
key
kind
value
minimum
maximum
icon
label/accessibilityText
origin
monitorHint?
updatedAt
```

Toast record:

```text
key/category
severity: Success | Info | Warning | Failure
summary
detail?
actions[]
origin
monitorHint?
replacePolicy
timeout
errorReference?
```

User-controlled values are escaped and bounded. Records contain no secrets or raw backend errors intended only for logs.

# 6. Service API

```text
showOsd(record)
updateOsd(key, patch)
dismissOsd(key)
showToast(record)
updateToast(key, patch)
dismissToast(key)
invokeToastAction(key, actionId)
```

Owning controllers publish only after known state transitions or explicit pending/failure milestones. Services resolve replacement and timing, not backend actions.

# 7. Interaction

- OSDs do not take focus and are normally pointer-transparent.
- Toasts do not take focus on arrival.
- Hover/focus may pause a failure toast; routine success toasts need not be interactive.
- Retry/Open Details actions are keyboard reachable and explicitly labeled.
- Primary activation invokes the chosen toast action; secondary/middle-click/scroll/drag have no implicit semantics.
- Dismissal controls appear only where useful and do not create a notification-history record.

OSDs remain glanceable without oversized mobile-style geometry. Toast severity, OSD value, focus, and failure use text/icon/shape cues as well as colour; high contrast and reduced motion preserve timing and meaning.

# 8. Placement, Opening, and Dismissal

Placement and geometry remain prototype questions. Hosts receive one resolved monitor and normalized work area from `MonitorRegistry`. OSD and toast regions must not overlap the control-centre activation edge or obscure each other unpredictably.

Repeated category updates restart/extend timing without spawning parallel cards. Reduced motion uses immediate or simple opacity transitions. On owner removal, close or rehome according to final monitor policy; never leave focus on an invisible toast action.

An action-bearing toast does not steal focus on arrival. Each action must also remain available at the originating focused surface/inline failure state, or the host must expose an explicit documented focus request through `SurfaceCoordinator`. When toast focus is explicitly entered, `Escape` returns focus to the origin; if the origin closes, shared fallback restoration applies.

# 9. State and Failure Handling

- Invalid/out-of-range OSD values are clamped for display and diagnosed.
- Unknown OSD kind uses a safe generic treatment or is rejected.
- Success followed by failure for the same operation replaces the pending/success state.
- Toast action failure updates the existing toast.
- Feedback host failure does not roll back backend state; diagnostics retain the presentation error.
- Permission-denied and action-failure toasts remain distinguishable from ordinary warnings.
- Notification-service failure does not affect OSD/toast delivery.

# 10. Dependencies and Configuration

Dependencies include `SurfaceCoordinator`, `MonitorRegistry`, `ThemeManager`, accessibility state, `Diagnostics`, and feature controllers that publish records.

Configuration may define enabled channels, normalized timeout ranges, reduced motion, and final positions after prototyping. It must not allow arbitrary retry commands or duplicate per-feature feedback settings that conflict with the central policy.

# 11. Multi-Monitor and Fullscreen

Recommended prototype direction: brightness OSD targets the affected monitor when known. Global volume and system-toast ownership follow the provisional policy in `multi-monitor.md`; the final result remains Q-092.

True fullscreen suppresses ordinary application popups, not user-triggered OSDs/toasts. Passive background state changes should not exploit this bypass by mislabeling themselves user-triggered.

# 12. Performance

Reuse a bounded number of host/view instances. Coalesce rapid updates, avoid queue growth, and stop timers on dismissal. OSD value updates must remain smooth under key repeat/wheel input without creating per-event objects or blocking the UI.

# 13. Fixtures

- volume 0/muted/normal/maximum and rapid updates;
- brightness on internal/external monitors;
- repeated keyed success toasts;
- pending→success and pending→failure;
- permission denied, retry success/failure;
- DND and fullscreen;
- notification service unavailable;
- reduced motion, high contrast, long localized text;
- owner monitor removed.

# 14. Implementation Phases

1. **Phase 3 fixtures:** hosts, keyed records, focus-neutral presentation.
2. **Phase 5 OSDs:** volume/brightness update-in-place and fullscreen/DND policy.
3. **Phase 5 toasts:** keyed success/failure with actions.
4. **Phase 6 integration:** network, Bluetooth, Night Light, idle inhibitor, and output publishers.
5. **Phase 8 integration:** power publishers.
6. **Phase 10/11:** final monitor placement, accessibility, motion, and visual polish.

# 15. Acceptance Criteria

- Volume/brightness changes update one OSD rather than stacking.
- Track changes create no feedback.
- A repeated toast with the same replacement key updates the existing record; an unrelated key creates a separate record subject to the host limit.
- DND/fullscreen preserve user-triggered feedback.
- Success toasts and all OSDs stay out of notification history.
- Failure actions are keyboard accessible and update the same toast.
- Action-bearing toasts remain non-focus-stealing on arrival and restore focus after keyboard dismissal/action.
- Every toast action is keyboard-reachable either from the originating inline state or through an explicit toast-focus request.
- Backend state can succeed even if presentation fails; the failure is diagnosed.
- OSD fixtures expose no app identity/history, toast fixtures expose system-action identity without app history, and notification fixtures retain app identity/actions.

# 16. Unresolved Questions

- **Q-041:** OSD placement.
- **Q-042:** OSD geometry/content.
- **Q-043:** toast placement.
- **Q-044:** whether/where failed operations become durable history.
- **Q-092:** final OSD monitor ownership.
- Exact timeout and collision policy among popups, toasts, and OSDs remains a prototype item.

# 17. Codex Implementation Guardrails

- Do not route OSDs/toasts through application notification history.
- Do not let feedback services perform the backend action.
- Do not create one window per input event.
- Do not suppress explicit user feedback merely because DND/fullscreen is active.
