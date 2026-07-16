# Franken Shell — Multi-Monitor Policy

> **Path:** `docs/features/multi-monitor.md`
> **Status:** Cross-cutting implementation specification
> **Primary phase:** Phase 10 — Multi-Monitor and Gesture Hardening
> **Related specifications:** all feature specifications under `docs/features/`

This document centralizes monitor identity, geometry, ownership, hotplug, focus restoration, and test policy. D-049 is provisional: the recommended initial direction below is not a final product decision.

---

# 1. Product Role

Franken Shell must behave as one coherent shell across changing output topologies. Feature views receive normalized monitor state and explicit ownership; they do not join raw Quickshell screens to compositor outputs independently.

# 2. Authority and Status

Settled architecture:

- one main shell instance;
- one `MonitorRegistry`;
- one `SurfaceCoordinator`;
- one ordinary bar popover open globally;
- per-monitor-capable surface construction;
- all opening requests carry monitor origin;
- monitor removal never leaves invisible focus;
- configuration is authoritative and monitor overrides are normalized.

Recommended prototype baseline, still provisional:

- bars on configured monitors;
- pointer-invoked surfaces use pointer/origin monitor;
- keyboard-invoked surfaces use focused-window monitor;
- one control centre open globally;
- notifications use focused-window monitor;
- OSDs use active/focused monitor, with brightness targeting the affected display;
- final policy is validated during Phase 10.

# 3. Scope and Ownership

This specification owns cross-feature rules for:

- monitor identity and normalization;
- geometry, scale, transform, mirroring, and work areas;
- surface owner resolution and fallback;
- global versus per-monitor surface uniqueness;
- per-monitor fullscreen/workspace/focused-window semantics;
- hotplug, docking, lid, sleep/wake, and focus restoration;
- performance/test requirements.

It does not own individual feature content, compositor commands, display configuration editing, or adopted overview internals.

# 4. Monitor Identity and Normalization

`MonitorRegistry` exposes stable session IDs and best-available persistent matching fields:

```text
id
connectorName
description
make
model
serial
logicalGeometry
physicalSize
scale
transform
refreshRate
enabled
primary/configuredFallback
mirroredGroupId?
quickshellScreenRef
compositorMonitorRef
```

Rules:

- Raw connector name must not be assumed stable across every dock/topology; configured name matching remains supported, while stronger identity fields are preferred when reliable.
- Persistent matching may use name, description, make, model, and serial as configured.
- Duplicate or missing serials and unstable connector names produce deterministic session IDs plus diagnostics.
- Matching confidence/source is inspectable.
- A raw screen/compositor object never becomes a feature’s authoritative key.
- Identity changes during one hotplug transaction are reconciled before surfaces are recreated where possible.

# 5. Coordinates, Scale, Rotation, and Mirroring

The registry supplies normalized logical geometry and conversion helpers between global logical, monitor-local logical, and backend coordinate spaces.

Requirements:

- Mixed integer and fractional scale must not double-apply scaling.
- Anchor placement and hit testing use logical coordinates; backend calls use explicit conversion.
- Rotation/transform is represented, not inferred from width/height alone.
- Popup inward direction follows the configured logical bar edge after transform.
- One-pixel visual lines and activation regions use scale-aware alignment without assuming one physical pixel equals one logical pixel.
- Mirrored outputs are represented as a group. A global event must not produce duplicate popups/OSDs merely because two output objects show the same desktop.
- The final choice of one presentation member for a mirrored group remains policy, not an implementation accident.
- Per-monitor text scale, high-contrast, focus rings, and pointer targets remain logically consistent across mixed scales and transforms.

# 6. Bar-Per-Monitor Policy

Final default is unresolved under Q-088. The implementation supports:

- enabled/disabled bar per matched monitor;
- per-monitor edge override;
- one bar view instance per eligible normalized monitor;
- shared global services/controllers;
- monitor-local anchors, fullscreen visibility, focus state, and workspace presentation inputs.

No bar instance may create duplicate tray, notification, audio, resource, network, or other service authorities.

# 7. Global and Per-Monitor Surfaces

Per-monitor hosts may exist dormant, but visibility uniqueness is global where specified:

| Surface | Prototype ownership/uniqueness |
|---|---|
| Bar | Per configured monitor |
| Ordinary bar popover | One globally; anchored to invoking bar |
| Control centre | One globally; host on resolved eligible monitor |
| Notification popup stack | One logical stack per admitted target policy; final number unresolved |
| Toast host | Resolved per event; bounded globally |
| OSD host | Resolved per event; one keyed OSD per semantic control |
| Vicinae | External major surface with invocation origin |
| quickshell-overview | Delegated; adapter passes invocation context where supported |
| Session surface | One globally |
| Lock | Security-global; Q-086 decides implementation, which must prevent any output from exposing the session |

Feature modules request openings. Only `SurfaceCoordinator` arbitrates conflicts, migration, dismissal, and focus.

# 8. Ownership Resolution

Every invocation context may contain:

```text
explicitMonitorId?
pointerMonitorId?
sourceSurfaceMonitorId?
focusedWindowMonitorId?
activeWorkspaceMonitorId?
configuredFallbackMonitorId?
timestamp
origin: Pointer | Keyboard | IPC | System | Backend
```

`MonitorRegistry` supplies normalized topology and candidate information. `SurfaceCoordinator`, using the configured/provisional ownership policy, resolves and freezes the owning monitor for a surface lifetime. Feature views and controllers do not select monitors independently.

Recommended prototype resolution:

- pointer/bar click/edge drag: explicit pointer or source-surface monitor;
- keyboard: focused-window monitor, then pointer monitor, then configured fallback/primary;
- IPC: explicit validated monitor, otherwise the relevant keyboard or system-event policy;
- brightness OSD: affected monitor when the adapter identifies one;
- notification: focused-window monitor at admission;
- global volume OSD/system toast: active/focused monitor as a prototype direction;
- if unresolved: configured fallback, then compositor primary, then first eligible normalized monitor.

The resolver returns one ID plus reason/fallback path. Views never duplicate this logic.

# 9. Control Centre and Popover Anchoring

- Under the recommended prototype policy, only one control centre is open globally; final host/ownership policy remains Q-090.
- Pointer edge drag owns the monitor where the qualifying press begins.
- Keyboard opening uses the resolved keyboard policy.
- Internal monitor boundaries are not assumed to be physical outer edges. Edge activation eligibility uses normalized topology.
- A right edge adjacent to another monitor must not steal normal cross-monitor pointer travel.
- A popover anchors to the exact invoking bar item and monitor-local work area.
- If an anchor disappears or moves during configuration reload, close safely or recompute only when the result remains unambiguous.
- Focus returns to the invoking item/application, not a similarly named item on another bar.

# 10. Focused Window, Workspace, and Fullscreen Semantics

`MonitorRegistry`/Hyprland adapter exposes:

- focused window and its monitor;
- focused/active monitor where the compositor distinguishes them;
- active workspace per monitor;
- workspace-to-monitor association;
- true-fullscreen state per monitor.

Rules:

- Maximized is never fullscreen.
- Bar visibility responds to fullscreen on that bar’s monitor only.
- Ordinary notification suppression evaluates the resolved target monitor’s fullscreen state.
- Focus changes after a surface opens do not silently migrate it.
- Workspace pager policy per monitor remains Q-089. No feature may assume the global active workspace group is correct for every bar.
- Focused-window actions retain a validated window identity and monitor, and fail safely if the target moves/disappears.

# 11. Notification and OSD Placement

Notification policy is provisional under Q-091. Admission resolves and freezes the target monitor for that popup lifetime. A later focus change affects only later notifications.

Recommended OSD prototype policy, provisional under Q-092:

- display brightness targets the affected display;
- global volume uses the resolved active/focused monitor;
- never duplicate a global OSD on all monitors by default;
- user-triggered fullscreen bypass applies only to the target host.

Toast placement follows the operation’s invocation monitor when known, then the same fallback resolver.

# 12. Hotplug, Removal, Lid, and Docking

Recommended topology-processing contract, not a settled implementation sequence:

1. mark affected monitors changing;
2. reconcile identities and geometry;
3. suspend new ambiguous openings;
4. close or migrate transient surfaces;
5. recreate/rebind per-monitor hosts;
6. restore eligible focus and publish diagnostics.

On owner removal:

- close pointer-anchored popovers whose anchor no longer exists;
- move a global control/session surface only if safe and policy permits; otherwise close;
- retain notification history and backend operations;
- rehome or dismiss popups/OSDs according to final policy;
- never execute a pending destructive action;
- never leave an invisible focused window.

Laptop lid close/open and docking may rename connectors, change primary/fallback, alter scale, and reorder outputs. Stored rules are matched by best available identity, not array index. Sleep/wake must tolerate temporarily empty monitor sets.

# 13. Fallback and Degraded States

Handle:

- no compositor monitor match for a Quickshell screen;
- compositor monitor without renderable screen;
- duplicate connector/EDID identity;
- invalid configured monitor rule;
- no eligible monitor for a requested surface;
- monitor disappearing during drag, authentication, pairing, or confirmation;
- transform/geometry temporarily unknown;
- mirror-group ambiguity.

Core shell state remains alive. Unsafe openings fail with a scoped explanation. Diagnostics include candidate monitors, match confidence, resolver reason, and topology revision without leaking window titles.

# 14. Focus Restoration

For every focus-taking surface, `SurfaceCoordinator` records:

```text
surfaceId
ownerMonitorId
invokingSurface/item?
previousApplication/window token?
topologyRevision
fallback focus target
```

Restoration order:

1. still-valid invoking control;
2. still-valid previous application/window;
3. compositor focus fallback on the resolved surviving monitor;
4. release shell focus explicitly.

Nested surfaces restore to their parent before application focus. Monitor removal invalidates stale targets and uses the recorded fallback; it never focuses an invisible dormant host.

# 15. Configuration

Monitor configuration supports default policy plus ordered match rules using stable fields where available. It may control bar eligibility/edge and control-centre eligibility. Global policy fields such as keyboard/notification/OSD ownership remain provisional until accepted.

Invalid/ambiguous rules preserve last valid configuration and create structured errors. Configuration must not store runtime array indices or duplicate authoritative compositor layout.

# 16. Performance

- One registry subscription normalizes compositor/screen events.
- Geometry and matching recompute only on relevant events, debounced as one topology transaction.
- Per-monitor views share global services.
- Dormant control-centre/popover hosts are lightweight; expensive pages remain lazy.
- Hidden monitors/surfaces do no high-frequency presentation work.
- Mixed-refresh monitors must not force global animation at the highest refresh rate unnecessarily.
- Hotplug and scale changes must avoid repeated create/destroy loops.

# 17. Test Matrix

Required automated/fixture and manual cases:

- one laptop display;
- two side-by-side displays in both orders;
- stacked displays and gaps;
- three monitors;
- internal boundary versus physical outer edge;
- scale 1.0, representative fractional scale, mixed scales;
- portrait and rotated transforms;
- different refresh rates;
- mirrored displays;
- duplicate/missing serial and unstable connector name;
- dock/undock and lid close/open;
- monitor sleep/wake;
- primary/fallback removal;
- owner removal while popover/control centre/notification/OSD/session confirmation is active;
- pointer invocation on each monitor;
- keyboard invocation with focused window on each monitor and with no focused window;
- workspace/focused-window movement between monitors;
- fullscreen on one monitor while another remains normal;
- bar on all, one, and configured subsets;
- overview/Vicinae invocation with monitor context.

# 18. Implementation Phases

1. **Phase 1:** normalized registry IDs, lifecycle, geometry, and fixture topology.
2. **Phases 2–6:** carry invocation context through all surfaces; use one-monitor-safe fallback while policy is provisional.
3. **Phase 7:** pass invocation context to Vicinae and quickshell-overview where supported.
4. **Phase 8:** pass context to power, calendar, and other deeper utilities.
5. **Phase 10A:** identity reconciliation, configured bars, pointer/keyboard resolver, and trial of the recommended one-control-centre policy.
6. **Phase 10B:** fractional scale, rotation, physical-edge detection, fullscreen/workspace semantics.
7. **Phase 10C:** hotplug, mirror, lid/dock, focus restoration, notification/OSD policy trials.
8. **Phase 11:** accessibility, visual, and mixed-scale polish.
9. **Phase 12:** packaging/topology diagnostics and accepted-policy documentation.

# 19. Acceptance Criteria

- Every feature opening request carries an origin; `SurfaceCoordinator` resolves ownership using normalized `MonitorRegistry` state and records the resolution reason.
- Raw connector joins and coordinate conversion are absent from feature views.
- Bars can be enabled per normalized monitor without duplicate global services.
- Under the active provisional policy, one control centre is globally visible; one ordinary bar popover remains globally enforced by the accepted surface-coordination rule.
- Pointer and keyboard invocation follow the configured or active prototype policy and report the resolution reason.
- True fullscreen is per monitor; maximized windows do not hide bars or suppress popups.
- Fractional scale, rotation, and mixed scale preserve anchors and hit targets.
- Ordinary pointer travel can cross an internal monitor boundary without opening the control centre unless the final qualifying gesture is deliberately performed.
- Owner removal cannot leave invisible focus, execute a destructive action, or lose notification history.
- One admitted global feedback event does not produce duplicate presentation solely because outputs are mirrored.
- Dock/lid transitions preserve valid monitor rules where identity permits and degrade clearly otherwise.

# 20. Unresolved Questions

- **Q-001:** exact Quickshell monitor/screen APIs.
- **Q-088:** default bar-on-monitor policy.
- **Q-089:** workspace pager semantics per monitor.
- **Q-090:** final control-centre ownership/host policy.
- **Q-091:** notification monitor ownership.
- **Q-092:** OSD monitor ownership.
- **Q-093:** physical outer-edge eligibility details.
- **Q-094:** fractional-scale pixel alignment.
- Final mirrored-display presentation member, duplicate-identity persistence, hotplug migration versus closure, notification stack count, scrim scope, and keyboard invocation with no focused window remain unresolved.

# 21. Codex Implementation Guardrails

- Treat the recommended direction as a prototype baseline, not an accepted final product decision.
- Do not resolve monitor ownership independently in feature controllers/views.
- Do not key persistent settings only by connector name or array index.
- Do not duplicate global services per monitor.
- Do not migrate an open surface after focus changes unless hotplug/final policy explicitly requires it.
- Do not leave a focus-taking dormant host active after owner removal.
