# Franken Shell — Audio

> **Path:** `docs/features/audio.md`
> **Status:** Implementation specification
> **Primary phases:** Phase 4 — Core System Adapters; Phase 6 — Working Daily-Use Prototype
> **Related specifications:** `bar.md`, `control-centre.md`, `osds-and-toasts.md`, `network-and-bluetooth.md`, `multi-monitor.md`

This document specifies audio state and actions. OSD presentation belongs to `osds-and-toasts.md`; control-centre hosting belongs to `control-centre.md`.

---

# 1. Product Role

Audio uses one persistent bar slot for immediate output identity, mute, and volume access, plus a compact bar popover and a deeper control-centre mixer. It must preserve one authoritative PipeWire/WirePlumber-derived model.

# 2. Settled Requirements

- The bar has one audio slot, never separate permanent sound/headphone/Bluetooth icons.
- Its icon reflects speakers, wired headphones, Bluetooth headphones/headset, mute, or another normalized output class.
- Primary click opens the compact audio popover.
- Middle-click toggles master mute.
- Scroll changes master output volume.
- The control centre keeps master volume visible and hosts per-application mixing.
- User-triggered volume changes publish one updating OSD.
- Audio-output changes publish a system toast.
- Track changes produce neither notification nor OSD.
- Views never call PipeWire commands or construct backend-specific node operations.

# 3. Ownership

Audio owns normalized outputs, inputs, streams, volumes, mute, default selection, supported routing actions, icon classification, and action-to-feedback requests.

It does not own:

- OSD/toast windows;
- MPRIS media controls or track feedback;
- Bluetooth discovery/pairing;
- control-centre geometry/navigation;
- microphone privacy policy outside the audio-derived capture signal;
- backend command execution from views.

# 4. Proposed Structure

```text
services/AudioService.qml
features/audio/
├── AudioController.qml
├── AudioPopover.qml
├── AudioMixerView.qml
├── AudioDeviceSelector.qml
├── AudioIconClassifier.qml
└── fixtures/AudioFixtureModel.qml
```

`AudioService` owns PipeWire/WirePlumber integration and normalized device/stream state. `AudioController` owns presentation policy, classification, clamping, task/error mapping, and feedback requests. Bar, popover, and mixer views render the same controller/service state and request actions.

# 5. State and Models

Expose:

```text
serviceLifecycle
defaultOutput
defaultInput
outputDevices[]
inputDevices[]
playbackStreams[]
captureStreams[]
masterVolume
masterMuted
microphoneMuted
activeCaptureState
operationTasks[]
lastError
```

Devices need stable ID, display name, semantic class, transport, availability, default/active flags, volume/mute where supported, and profiles/routes when exposed. Streams need stable ID, application identity/icon, role, target device, volume/mute, activity, and capabilities.

Do not infer Bluetooth status independently; consume normalized device metadata. Unknown devices receive an explicit fallback icon and accessible name.

# 6. Controller API

```text
setMasterVolume(value, origin)
adjustMasterVolume(delta, origin)
toggleMasterMute(origin)
selectDefaultOutput(deviceId, origin)
selectDefaultInput(deviceId, origin)
setMicrophoneMuted(value, origin)
setStreamVolume(streamId, value, origin)
setStreamMuted(streamId, value, origin)
moveStream(streamId, outputId, origin)
```

All values are clamped by validated configuration and backend capability. Actions expose pending/failure state and publish feedback through dedicated services.

# 7. Compact Popover and Mixer Boundary

The compact popover must remain a fast path. Until Q-045 is resolved, the safe fixture baseline is master volume, mute, and current-output summary. A quick output switcher, input selection, and microphone mute remain prototype choices. Per-application streams belong in the control-centre mixer.

The mixer may show output/input selectors and application streams supported by the adapter. It must not duplicate independent models or imply routing support that the backend cannot provide.

# 8. Interaction

- Bar primary click toggles the audio popover through `SurfaceCoordinator`.
- Bar middle-click toggles mute and shows the volume OSD.
- Bar scroll adjusts by the configured unresolved step; acceleration must not cause unexpected jumps.
- Secondary click has no settled default; do not invent a mixer shortcut.
- Hover shows output name, exact volume, and mute state.
- Popover sliders support pointer drag, wheel, arrows, `PageUp`/`PageDown`, `Home`/`End` where appropriate.
- Device rows activate by click or keyboard; secondary menus expose only supported actions.
- `Escape` closes menus, then popover; focus returns to the bar item.
- The configurable audio-controls keyboard path uses the same controller state/actions as bar activation; the exact binding is defined later.

Volume, mute, default-device, capture, focus, and unavailable states use shared semantic tokens and remain distinguishable without colour. Numeric values use tabular figures; reduced motion removes decorative transitions without hiding feedback.

# 9. Opening, Dismissal, and Focus

Only one bar popover is globally open. Opening audio closes another bar popover; control centre, Vicinae, or overview closes it. `SurfaceCoordinator` resolves pointer/keyboard ownership from the invocation context and normalized `MonitorRegistry` data.

An in-progress slider movement may complete before dismissal. Device selection does not close the host unless specified by the final prototype. Failure restores useful focus and leaves current device state visible.

Keyboard opening focuses master volume deterministically. Pointer opening does not steal keyboard focus until keyboard interaction begins. Outside click closes ordinary popover state but must not interrupt an operation that requires explicit cancellation.

# 10. Error and Unavailable States

Distinguish:

- backend unavailable/starting/reconnecting/failed;
- no default output;
- output removed during use;
- no active application streams;
- unsupported stream routing;
- permission or policy denial;
- stale device metadata and unknown classification;
- action failure or timeout.

When audio is wholly unsupported, dependent controls are omitted or explain unavailability. Last-known device names may be shown for context during reconnect but cannot be used as proof that an action succeeded.

# 11. Dependencies and Configuration

Dependencies:

- selected PipeWire/WirePlumber adapter;
- `CapabilityRegistry`, `Diagnostics`, `ConfigService`;
- `SurfaceCoordinator`, `MonitorRegistry`;
- OSD and toast publishers.

Default maximum volume is `1.0`; values above nominal require explicit opt-in. Device-class override rules may correct misclassification. Configuration remains authoritative and normalized.

# 12. Multi-Monitor and Performance

Master volume is global unless the backend exposes otherwise. Popover ownership is per invocation. Brightness-style per-monitor targeting must not be copied into volume semantics. Device removal or monitor hotplug must not leave a focused invisible popover.

PipeWire events should drive state. Avoid high-frequency polling. Coalesce rapid wheel/key changes into one OSD, throttle writes where needed, and lazy-load long stream lists. Hidden mixer delegates do no animation or metering unless explicitly visible.

# 13. Fixtures

- speakers, wired headphones, Bluetooth headset, HDMI, USB DAC, unknown output;
- muted, 0%, 100%, configured over-100 state;
- multiple outputs and output removed during selection;
- no streams, many streams, duplicate app names, routing unsupported;
- backend starting/reconnecting/failed;
- active capture, merely unmuted microphone, microphone muted;
- rapid scroll/keyboard changes and action failure.

# 14. Implementation Phases

1. **Phase 2 bar fixture:** audio item states, bar interaction forwarding, and popover anchor.
2. **Phase 3 control-centre fixture:** master slider and mixer-host structure with mock streams.
3. **Phase 4 adapter:** normalized PipeWire devices, streams, volume, mute, and defaults.
4. **Phase 5 feedback:** keyed volume OSD and output-change toast.
5. **Phase 6 daily use:** compact popover and per-application mixer.
6. **Phase 10/11:** monitor/focus, large-list, accessibility, and polish hardening.

# 15. Acceptance Criteria

- One bar slot represents the active output or mute state without duplicate Bluetooth audio status.
- Scroll and middle-click alter master audio through the controller and update one OSD.
- Output selection changes authoritative backend state and produces one toast.
- Per-application controls use the same service model as the bar/popover.
- Backend reconnection repopulates audio state without a shell restart; removing the default device clears/reselects state through the adapter without leaving stale controls enabled.
- An unclassified device remains selectable and uses the explicit unknown-output fallback icon/name.
- No view contains backend-specific commands.
- Keyboard users can reach, adjust, select, dismiss, and regain focus.
- Keyboard opening focuses master volume, and outside-click/`Escape` dismissal restores the correct prior target.

# 16. Unresolved Questions

- **Q-001, Q-002:** exact Quickshell and retained audio-service baseline.
- **Q-045:** final compact-popover scope.
- **Q-046:** reliable output classification and override matching.
- **Q-047:** amplification above 100%.
- **Q-048:** final volume scroll step.
- **Q-049:** exact microphone active-capture semantics.
- **Q-028:** control-centre mixer selection and scroll restoration after closure.
- The mixer’s final device-selector/routing depth remains coordinated with the control-centre specification.

# 17. Codex Implementation Guardrails

- Do not create separate audio models for bar, popover, and mixer.
- Do not equate “microphone unmuted” with “actively recording.”
- Do not put per-app mixing into the compact popover.
- Do not instantiate OSD UI from the audio service.
