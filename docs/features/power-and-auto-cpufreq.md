# Franken Shell — Power and auto-cpufreq

> **Path:** `docs/features/power-and-auto-cpufreq.md`
> **Status:** Implementation specification
> **Primary phase:** Phase 8 — Power, Calendar, and Deeper Utilities
> **Related specifications:** `bar.md`, `resource-monitor.md`, `notifications.md`, `osds-and-toasts.md`, `session-and-lock.md`

This document specifies the power-management surface opened from the battery item. Generic bar battery rendering remains owned by `bar.md`.

---

# 1. Product Role

The panel explains current battery/charger state and manages supported auto-cpufreq policy. It distinguishes automatic daemon policy, persistent configuration, and temporary overrides without turning QML into a privileged editor.

# 2. Settled Requirements

- Primary activation of the battery item opens this surface.
- Battery status remains useful when auto-cpufreq is absent.
- The surface centres on auto-cpufreq rather than a generic desktop power-profile UI.
- Supported battery and charger settings may include governor, energy-performance preference, turbo, min/max frequency, and charging thresholds.
- Unsupported fields are omitted.
- Draft, save, apply, and revert are distinct states/actions.
- Automatic control and temporary overrides are visibly distinct.
- Protected writes use a narrow privileged helper and system authorization.
- The main shell remains unprivileged and exposes no arbitrary command or file-write API.
- Writes are validated, atomic, backed up where configured, and recoverable.
- A successful applied change produces a system toast; failure remains longer and is actionable.

# 3. Ownership

The feature owns normalized battery/power state used in the panel, auto-cpufreq discovery and configuration presentation, draft validation, helper requests, apply/revert workflow, and feature diagnostics.

It does not own:

- bar battery layout;
- critical-interruption policy;
- session shutdown/suspend actions;
- generic process/resource telemetry;
- Polkit implementation internals;
- arbitrary editing of auto-cpufreq or system files.

# 4. Proposed Structure

```text
services/
├── BatteryService.qml
└── AutoCpuFreqService.qml

features/power/
├── PowerController.qml
├── PowerPopover.qml
├── ProfileEditor.qml
├── OverrideSelector.qml
└── fixtures/PowerFixtureModel.qml

helpers/auto-cpufreq/
└── narrow privileged helper (language unresolved)
```

`BatteryService` and `AutoCpuFreqService` own unprivileged reads and normalized lifecycle/configuration state. `PowerController` owns drafts, validation presentation, operation sequencing, and toast requests. Views render/request actions; only the narrow helper performs approved privileged writes.

# 5. State and Data Requirements

Expose:

```text
batteryAvailability
percentage
chargingState
powerSource
credibleTimeEstimate?
warning/critical policy state
autoCpuFreqLifecycle
daemonState
activeConfigPath
activeConfigSource
supportedFields[]
effectiveBatteryProfile
effectiveChargerProfile
draftProfiles
draftDirty
validationErrors[]
overrideState
operationTask
lastError
```

Each editable field requires stable ID, scope, type, supported range/options, effective value, explicit/inherited source, draft value, and validation result. The UI must not assume field names or semantics before Q-063 research.

# 6. Controller and Helper Contract

Conceptual controller actions:

```text
reload()
setDraft(fieldId, value)
resetDraft()
save()
apply()
revert()
requestOverride(mode)
clearOverride()
```

Conceptual helper operations are allowlisted and typed:

```text
readApprovedConfig(pathId)
writeValidatedConfig(pathId, expectedRevision, structuredPatch)
restoreBackup(pathId, backupId)
requestDaemonApply()
```

The helper validates paths, schema, ranges, ownership, concurrency revision, and output. It never accepts raw shell, arbitrary paths, or opaque file contents from QML.

# 7. Interaction and Editing

- Primary activation opens/toggles the popover through `SurfaceCoordinator`.
- Secondary and middle-click have no initial action.
- Scroll has no initial action.
- Hover shows exact battery/charger, effective-policy, and availability information without changing state.
- Drag has no feature action except direct manipulation of an explicit supported field control.
- Keyboard navigation reaches summary, override choices, profile sections, fields, and actions.
- Changing a field edits a draft only.
- Save/apply operations display pending state and prevent accidental duplicate submission.
- `Escape` closes menus, then enters the explicit cancel/discard flow for a dirty draft according to the unresolved draft policy, then closes only when safe.
- Destructive revert/restore actions require deliberate confirmation where data would be lost.

Inherited, explicit, draft, invalid, pending, and applied states must be distinguishable without colour alone. Every field exposes its unit/range and error association to accessibility tools; reduced motion does not obscure apply progress.

# 8. Opening, Dismissal, and Focus

The panel is an ordinary bar popover. Protected authorization or apply workflows prevent outside-click closure only while dismissal would make the operation ambiguous. Authentication UI is system-owned or separately coordinated; the power view must not collect passwords.

After a successful apply, retain focus in the panel and show effective state. Closing restores focus to the battery item. Owner-monitor removal cancels presentation safely but must not corrupt or duplicate an already submitted helper operation.

Keyboard opening focuses the first safe summary/override control, never a destructive action. Pointer opening does not steal keyboard focus until keyboard navigation begins. `Escape` and outside click follow deepest-first cancellation and must not silently discard a dirty draft, authorization flow, or destructive confirmation.

# 9. Error and Unavailable States

Distinct states include:

- no battery;
- battery available but estimate calculating/unreliable;
- auto-cpufreq absent, disabled, daemon stopped, incompatible, or failed;
- active config source unresolved or multiple conflicting sources;
- unsupported field;
- invalid draft;
- authorization denied/cancelled;
- concurrent external edit;
- write, apply, verification, or rollback failure.

If apply verification fails, preserve/restore the previous valid configuration when possible and report exact structured diagnostics. Never claim success based only on helper exit.

# 10. Dependencies, Security, and Configuration

Dependencies include UPower or selected battery adapter, auto-cpufreq, system authorization, the privileged helper, `CapabilityRegistry`, `Diagnostics`, `ConfigService`, `SurfaceCoordinator`, and toast publisher.

Franken Shell configuration may select approved config preference/paths and whether temporary overrides are exposed. It must not duplicate auto-cpufreq values as another authoritative profile database. Unknown fields/comments require the preservation strategy chosen under Q-065.

# 11. Multi-Monitor and Performance

Power state is global; only the popover has monitor ownership. Multiple battery indicators consume one normalized service. Hotplug must not create parallel helper operations.

Battery and daemon status are event-driven or low-frequency. Configuration parsing occurs on open, explicit refresh, or external change—not per frame. Expensive statistics stop when hidden unless needed for safety policy.

# 12. Fixtures

- battery charging/discharging/full; no battery; estimate calculating;
- auto-cpufreq absent, daemon stopped, ready, incompatible;
- user/system config active and conflicting/unresolved source;
- supported/unsupported fields and inherited/explicit values;
- dirty valid/invalid draft;
- authorization cancel/deny;
- concurrent edit, write failure, apply failure, rollback success/failure;
- automatic, power-save, and performance override presentation.

# 13. Implementation Phases

1. **Phase 6 placeholder:** battery status and missing-auto-cpufreq explanation.
2. **Phase 8 research:** installed-version config precedence, fields, apply interface, and statistics.
3. **Phase 8 editor:** typed draft model and validation with mock helper.
4. **Phase 8 helper:** least-privilege implementation, authorization, atomic write, backup, verification, rollback.
5. **Phase 8 completion:** helper security tests and review before treating privileged writes as daily-use ready.
6. **Phase 10:** monitor/focus and hotplug hardening.
7. **Phase 11:** accessibility and visual polish.
8. **Phase 12:** helper/policy packaging and upgrade compatibility.

# 14. Acceptance Criteria

- Battery information remains available without auto-cpufreq.
- The active configuration path/source is displayed, and every editable value is labeled as explicit or inherited.
- Editing never writes until an explicit save/apply action.
- Unsupported fields do not appear.
- No privileged operation accepts arbitrary paths, commands, or content.
- Invalid drafts and concurrent edits cannot partially replace valid configuration.
- Apply success is verified; failure preserves or restores the last valid state.
- Automatic policy and temporary override state use distinct labels, and an active override exposes its remaining lifetime when the selected backend can report it.
- Secrets/authentication data never enter QML state or logs.
- Keyboard and pointer dismissal cannot silently discard a draft or authorization/confirmation state.

# 15. Unresolved Questions

- **Q-001, Q-002:** exact Quickshell/battery/retained-service baseline.
- **Q-037:** warning and critical threshold defaults.
- **Q-063:** installed auto-cpufreq precedence, fields, statistics, thresholds, and apply mechanism.
- **Q-064:** helper implementation language.
- **Q-065:** comment/unknown-field preservation strategy.
- **Q-066:** temporary override semantics and lifetime.
- **Q-067:** time-estimate quality policy.
- Dirty-draft dismissal and exact authorization-surface coordination remain implementation questions.

# 16. Codex Implementation Guardrails

- Do not infer auto-cpufreq schema from examples.
- Do not write privileged files from QML or `CommandRegistry`.
- Do not create a second authoritative power-profile configuration.
- Do not claim apply success before read-back/verification.
