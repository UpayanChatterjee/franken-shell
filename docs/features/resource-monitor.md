# Franken Shell — Resource Monitor

> **Path:** `docs/features/resource-monitor.md`
> **Status:** Implementation specification
> **Primary phase:** Phase 6 — Working Daily-Use Prototype
> **Related specifications:** `bar.md`, `power-and-auto-cpufreq.md`, `osds-and-toasts.md`, `multi-monitor.md`

This document specifies compact telemetry presentation. Backend-specific telemetry remains behind resource, sensor, GPU, and process adapters.

---

# 1. Product Role

The resting bar shows RAM as a compact ring. Primary activation opens an instrument-like resource popover for practical system awareness. A configurable external system monitor owns full process-management depth.

# 2. Settled Requirements

- The persistent indicator is a circular RAM progress arc with centred whole-number percentage and no `RAM` label.
- The popover shows available CPU/GPU usage and temperature, fans, useful clocks, memory/swap, storage, uptime, power profile, and high-usage process.
- Unsupported metrics are omitted, not rendered as permanent dead rows.
- Multiple GPUs are supported conceptually.
- Detailed telemetry updates faster only while the popover is open.
- Clicking the popover body launches the configured external full system monitor.
- Launch failure produces an actionable system failure toast.
- Views do not read `/proc`, `/sys`, vendor commands, or sensor files directly.

# 3. Ownership

The feature owns telemetry normalization, presentation policy, capability-based row composition, RAM ring and popover, external-monitor launch intent, and resource-specific diagnostics.

It does not own:

- a full process manager;
- auto-cpufreq editing;
- critical-alert popup policy or toast/notification hosts;
- hardware-specific paths in views;
- power-profile authority;
- monitor ownership and focus restoration.

# 4. Proposed Structure

```text
services/
├── ResourceService.qml
├── SensorService.qml
├── GpuService.qml
└── ProcessSummaryService.qml

features/resources/
├── ResourceController.qml
├── ResourceIndicator.qml
├── ResourcePopover.qml
├── MetricRow.qml
└── fixtures/ResourceFixtureModel.qml
```

Resource/sensor/GPU/process services own acquisition, source-specific errors, and polling lifecycles. `ResourceController` derives capability-filtered sections and sampling demand. Indicator/popover views render formatted state and request visibility or launch actions.

# 5. State and Data Requirements

Each metric should expose:

```text
id
label
kind
value
unit
formattedValue
available
stale
severity
source
updatedAt
```

The controller derives ordered sections without fabricating absent values. Required model domains:

- memory used/total/percent and swap;
- aggregate/per-logical CPU usage where scope requires;
- zero or more GPU records with stable identity;
- normalized temperature, fan, and clock channels;
- configured filesystem usage;
- uptime and power-profile summary;
- optional top-process summary with bounded metadata.

Sensor discovery maps raw channels to semantic types. Machine-specific overrides may correct mapping but do not replace the general adapter contract.

# 6. Controller and Service API

```text
summaryState
detailedSections[]
setDetailVisible(value)
refresh()
openExternalMonitor(invocationContext)
```

Services expose lifecycle and polling tier independently. `setDetailVisible` raises or lowers sampling without giving the view ownership of timers. External invocation uses `CommandRegistry`.

# 7. Presentation and Interaction

- Primary click on the RAM ring toggles the popover.
- Secondary and middle-click have no settled feature action.
- Scroll has no default action.
- Hover shows exact memory used/total and update age if stale.
- The popover is keyboard navigable; metric rows are normally informational.
- A clearly identified body/action region opens the external monitor; interactive child controls must not trigger it accidentally.
- `Escape` closes and restores focus to the RAM item.
- No metric uses motion merely because its value changes. Tabular numerals and stable row widths prevent jitter.

Keyboard opening focuses the visible external-monitor launch affordance, or the first interactive row only if the final design introduces interactive rows. Pointer opening does not steal keyboard focus until keyboard navigation begins.

Severity uses text/icon/shape as well as colour. The RAM ring has an accessible percentage/name, missing rows do not break reading order, and high contrast or larger text does not turn the popover into an unlabeled chart.

# 8. Opening, Dismissal, and Focus

The resource popover is an ordinary bar popover owned by `SurfaceCoordinator`. It closes on outside click, `Escape`, competing surface opening, or owner-monitor removal. The opening monitor remains owner for its lifetime unless invalidated.

Launching the external monitor first closes the popover and restores or transfers focus according to command-launch policy. Launch failure restores focus and offers Retry/Open Details.

# 9. Loading, Empty, Degraded, and Failure States

- **Initial loading:** skeleton/placeholder rows preserve geometry without fake zeros.
- **Metric unavailable:** omit optional row; explain missing core domains when useful.
- **Sensor permission denied:** show a scoped explanation and diagnostics.
- **Stale:** retain bounded last value with stale treatment and timestamp; do not classify it as current critical state.
- **GPU suspended:** show suspended/unavailable without waking it solely for display.
- **No swap/no fan/no temperature:** omit corresponding rows.
- **External monitor unavailable:** popover remains functional.
- **Adapter failed/reconnecting:** isolate affected section; RAM summary may continue if its source remains healthy.

# 10. Dependencies and Configuration

Dependencies:

- Linux resource/sensor adapters selected after research;
- `CapabilityRegistry`, `Diagnostics`, `ConfigService`;
- `CommandRegistry`, `SurfaceCoordinator`, `MonitorRegistry`;
- power-profile read model and critical-alert publisher where available.

Configuration selects preferred visible metrics, storage mounts, update tiers, sensor overrides, and external monitor command. Preferences are not availability guarantees.

# 11. Multi-Monitor and Performance

Telemetry is machine-global; only popover ownership is monitor-specific. Multiple bars may render the same normalized RAM summary without creating duplicate samplers.

Always-visible RAM and any bar summary use low-frequency sampling. Detailed CPU/GPU/sensor/process sampling activates only while at least one consumer is visible. Reference counting must not leak. Vendor commands are asynchronous, rate-limited, and must not wake a suspended discrete GPU without explicit policy.

# 12. Fixtures

- normal CPU/RAM/storage;
- high memory and swap pressure;
- one GPU, hybrid GPUs, suspended discrete GPU, multiple GPUs;
- missing fans, shared fan, missing temperatures/clocks;
- stale/permission-denied sensor;
- no swap; multiple configured mounts; full filesystem;
- no top process, top CPU, top memory, rapidly changing process;
- external monitor absent/failing;
- popover closed/open sampling transition.

# 13. Implementation Phases

1. **Phase 2 fixture ring:** stable RAM geometry and states.
2. **Phase 4 adapter foundation:** memory/CPU/storage with normalized lifecycle.
3. **Phase 6 popover:** core metrics, capability omission, external monitor action.
4. **Post-prototype/deferred depth:** vendor-specific GPU, sensor, clock, and process-summary backends only when separately scheduled.
5. **Phase 10/11:** multi-monitor consumer sharing, accessibility, and polish.

# 14. Acceptance Criteria

- The resting indicator displays whole-number RAM percentage without a label.
- Opening detail changes polling tier; closing it returns to low-frequency work.
- Missing sensors remove only their rows and do not break the popover.
- A suspended discrete GPU is not awakened solely by routine polling.
- Multiple GPU records remain distinguishable.
- Stale and unavailable values are never presented as current zero values.
- The configured full monitor launches through `CommandRegistry`; failure is actionable.
- One shared service supplies all per-monitor indicator instances.
- Keyboard and pointer users can discover and invoke the external-monitor action without making every informational row clickable.

# 15. Unresolved Questions

- **Q-001, Q-002:** exact Quickshell baseline and retained resource services.
- **Q-057:** sensor/backend implementation.
- **Q-058:** NVIDIA telemetry and suspend-safe behaviour.
- **Q-059:** AMD iGPU telemetry.
- **Q-060:** fan availability and semantic labeling.
- **Q-061:** top-process scope, privacy, update cost, and action.
- **Q-062:** storage/filesystem scope.
- Exact critical temperature/storage thresholds remain **Q-037** and belong to notification policy/configuration.

# 16. Codex Implementation Guardrails

- Do not build a full process manager.
- Do not hard-code one machine’s hwmon paths in feature QML.
- Do not show unavailable metrics as zero.
- Do not duplicate samplers per bar or monitor.
- Do not promote recommendations or example intervals into fixed requirements without measurement.
