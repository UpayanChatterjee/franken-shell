# Franken Shell — Notifications

> **Path:** `docs/features/notifications.md`
> **Status:** Implementation specification
> **Primary phase:** Phase 5 — Notifications and Feedback
> **Host specification:** `control-centre.md`
> **Related specifications:** `osds-and-toasts.md`, `multi-monitor.md`

This document specifies application-notification receipt, policy, popup presentation, grouping, and in-memory history. System toasts and OSDs are separate channels.

---

# 1. Product Role

Notifications preserve application identity, actions, and reviewable history while minimizing interruption. All applications may show popups by default, but DND, fullscreen, grouping, burst coalescing, and maximum stack policy prevent overload.

# 2. Settled Requirements

- Franken Shell owns notification presentation and history within the one main shell instance.
- All applications are popup-eligible by default.
- Notifications group automatically by application.
- There is no global unread count or badge anywhere.
- Ordinary notifications are silent by default.
- Calls, alarms, timers, and conservatively classified critical alerts may use sound.
- DND suppresses ordinary popups and sounds but keeps history.
- DND does not suppress user-triggered toasts/OSDs or failures.
- True fullscreen withholds ordinary popups, keeps history, and does not replay a burst after exit.
- Critical alerts may bypass according to shell policy; application urgency alone is not unquestioned authority.
- While the control centre is open to Notifications, new items update the list without duplicate floating popups.
- Initial history is memory-only and clears on restart.
- Notification bodies are never logged.

# 3. Ownership

Notifications owns server integration, normalized records, app identity, grouping, popup admission, DND/fullscreen policy, timeout, actions, dismiss/clear, in-memory history, progress updates, and sound-rule evaluation.

It does not own:

- system configuration toasts or direct-manipulation OSDs;
- control-centre window/navigation;
- application-specific business meaning;
- arbitrary sound commands;
- persistence before a privacy decision;
- global surface monitor resolution.

# 4. Proposed Structure

```text
services/notifications/
├── NotificationService.qml
├── NotificationPolicy.qml
├── NotificationHistory.qml
└── NotificationSoundService.qml

features/notifications/
├── NotificationController.qml
├── NotificationPopupHost.qml
├── NotificationPopup.qml
├── NotificationHistoryView.qml
├── NotificationGroup.qml
└── fixtures/NotificationFixtureModel.qml
```

`NotificationService` owns protocol/server lifecycle and record receipt. `NotificationPolicy` makes deterministic admission/classification decisions. `NotificationHistory` owns the in-memory collection, while the controller derives groups/popup models. Popup/history views render and request actions only.

# 5. Notification Record and Models

Normalized records require stable internal ID, replacement/protocol ID, application identity/icon, title/body, timestamp, urgency hint, shell classification, category, actions, image/markup capability, progress, resident/persistent hint, popup state, dismissal state, and privacy-safe diagnostics metadata.

Derived models:

- ordered current-session history;
- application groups with local counts;
- popup candidates and visible stack;
- suppressed reasons;
- progress/replacement relationships;
- DND and fullscreen policy state.

Grouping identity must use a deterministic normalized fallback chain once Q-032 is resolved.

# 6. Service and Policy API

```text
receive(protocolNotification)
invokeAction(notificationId, actionId)
dismiss(notificationId)
dismissGroup(groupId)
clearAll()
setDnd(value, origin)
pauseTimeout(notificationId, reason)
resumeTimeout(notificationId, reason)
```

Policy returns:

```text
historyEligible
popupEligible
soundEligible
classification
groupKey
timeout
suppressionReason
criticalBypassReason?
```

Policy is pure/testable where possible. Server lifecycle and side effects remain in services.

# 7. Popup and History Interaction

- Popups stack in a bounded right-side region inset from the control-centre edge activation strip; exact placement remains Q-030.
- Primary action opens the notification/default action when provided.
- Secondary/context action exposes remaining actions where needed.
- Dismiss controls have explicit accessible names.
- Hover or keyboard focus pauses timeout; leaving resumes with sane remaining time.
- Group burst updates may replace/update a visible popup without losing each history record.
- History supports expand/collapse, individual/group dismissal, actions, progress, and clear all.
- Clear all removes ordinary dismissible records while preserving entries whose protocol/progress state requires them to remain. Whether a short history-only undo is offered remains Q-040.
- A deliberate rightward notification swipe/drag dismisses after the shared distance/velocity threshold; the card follows the pointer and snaps back when the gesture is cancelled.
- Keyboard and explicit-dismiss controls provide parity with drag dismissal. Middle-click has no shell-defined dismissal action; scroll remains for history/long content.
- Exact clear-all confirmation/undo presentation remains unresolved and must not imply protocol restoration; the removal semantics above are settled.

Cards expose app, time, classification, actions, dismissal, and group state accessibly. Focus is visible independently of urgency, critical state is not colour-only, and reduced motion preserves arrival/grouping causality without large movement.

# 8. Opening, Dismissal, and Focus

Popup arrival does not steal keyboard focus by default. Explicit action/focus navigation may focus a popup. `Escape` cancels an active swipe/action menu first, then dismisses or returns focus according to the active interaction without closing unrelated major surfaces.

The history view is hosted by the control centre. Its page opening, back stack, and focus restoration follow `control-centre.md`. New records preserve scroll position and may show a local “new items” affordance when the user is scrolled away from the insertion edge.

After invoking an action that does not close its application or surface, focus returns to the notification or history position when still valid; otherwise it returns through `SurfaceCoordinator` to the prior application.

The configurable notification-view shortcut requests the control centre's Notifications view through `SurfaceCoordinator`; it does not create a separate history surface.

# 9. Policy States and Failure Handling

Represent:

- server unavailable, ownership conflict, starting, ready, reconnecting, failed;
- malformed/unsupported content with safe text fallback;
- missing app identity/icon;
- action failed or notification vanished;
- DND/fullscreen/drawer-open suppression;
- popup queue overflow/burst coalescing;
- sound unavailable or invalid rule;
- image load denied/failed.

Receipt/history must continue when popup or sound presentation fails. Markup, images, links, and actions are treated as external content and rendered/invoked safely.

# 10. Critical, Sound, and Privacy Policy

Default critical-bypass categories are those accepted in D-040. Routine calendar reminders/download completions do not bypass. App urgency is only an input.

Sound matching is deterministic, ordered, inspectable, and limited to approved sound-theme events or files. Ordinary default is silent. Notification bodies, actions, arbitrary titles, and image data are not logged. Persistence is forbidden in the initial implementation.

# 11. Multi-Monitor and Fullscreen

Popup ownership is resolved once per admission according to `multi-monitor.md`; the provisional baseline is focused-window monitor. A focus change does not move an already visible popup. Fullscreen is normalized per monitor: ordinary popups are withheld where policy says the target monitor is in true fullscreen, while history remains complete.

Owner removal closes/reassigns visible presentation without losing history or leaving invisible focus. Mirrored displays must not duplicate one notification unless final policy explicitly requires it.

# 12. Performance

Notification receipt and policy are event-driven. Burst processing is coalesced; popup count and retained memory are bounded by validated configuration. Lists use stable keys and delegate reuse. Images decode asynchronously with size limits. Hidden history does not animate or reformat the entire model on every arrival.

# 13. Fixtures

- routine/important/critical and untrusted critical hint;
- one app burst, multiple apps, replacement/progress notification;
- no metadata, long body, markup/image/link, many actions;
- DND, fullscreen, drawer open to Notifications;
- popup stack overflow and user scrolled away from top;
- action success/failure, persistent/resident record;
- server ownership conflict/reload/reconnect;
- focused monitor changes and owner removal.

# 14. Implementation Phases

1. **Phase 3 fixtures:** history host, popup stack, grouping/focus mechanics.
2. **Phase 5 ownership:** verify current daemon, implement one server lifecycle and normalized records.
3. **Phase 5 policy:** DND, fullscreen, critical classification, grouping, bursts, timeouts.
4. **Phase 5 presentation:** popup/history actions, dismissal, stable scrolling, privacy.
5. **Phase 8:** deterministic sound rules.
6. **Phase 10/11:** final monitor ownership, accessibility, performance, polish.

# 15. Acceptance Criteria

- All ordinary applications can produce records and eligible popups.
- No global unread count appears in bar, control centre, tray, or popup host.
- DND/fullscreen suppression preserves history and never replays a burst.
- Drawer-open Notifications suppresses duplicate floating presentation.
- Grouping preserves individual records and actions.
- Pointer swipe, explicit dismissal, and keyboard dismissal produce equivalent history outcomes after their respective confirmation/threshold rules.
- A notification storm cannot fill the whole screen or block the UI.
- Ordinary notifications are silent by default.
- Bodies/secrets are absent from logs and initial history is not persisted.
- Server ownership conflicts are detected and do not create duplicates.
- The notification-view shortcut and control-centre entry point expose the same history model and grouping state.

# 16. Unresolved Questions

- **Q-001, Q-002:** exact Quickshell and retained notification-service baseline.
- **Q-029:** current notification-server ownership and reload migration.
- **Q-030:** popup placement/geometry.
- **Q-031:** timeout policy.
- **Q-032:** grouping identity.
- **Q-033:** burst coalescing semantics.
- **Q-034:** future retention/persistence/privacy.
- **Q-035:** sound rule syntax.
- **Q-036:** critical urgency trust.
- **Q-037:** exact critical thresholds.
- **Q-038:** optional fullscreen-exit summary.
- **Q-039:** action layout.
- **Q-040:** clear-all undo/confirmation.
- **Q-027, Q-028:** notification viewport stickiness, group expansion, scroll position, and reopen restoration inside the control centre.
- **Q-091:** final notification monitor ownership.

# 17. Codex Implementation Guardrails

- Do not run beside another notification server without an explicit migration.
- Do not persist history or log contents.
- Do not merge toasts/OSDs into notification history by default.
- Do not trust arbitrary app urgency to bypass DND/fullscreen.
- Do not create a global unread count.
