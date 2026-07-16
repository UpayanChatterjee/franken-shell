# Franken Shell — Network and Bluetooth

> **Path:** `docs/features/network-and-bluetooth.md`
> **Status:** Implementation specification
> **Primary phases:** Phase 4 — Core System Adapters; Phase 6 — Working Daily-Use Prototype
> **Host specification:** `control-centre.md`
> **Related specifications:** `bar.md`, `audio.md`, `osds-and-toasts.md`, `multi-monitor.md`

This document specifies normalized network and Bluetooth state, control-centre detail workflows, and connectivity exception presentation. The control centre owns drawer hosting and navigation; these features own their models and operations.

---

# 1. Product Role

Normal connectivity is silent. The shell exposes persistent download throughput separately, surfaces exceptional connectivity contextually, and provides comprehensive Wi-Fi and Bluetooth management as nested control-centre pages.

# 2. Settled Requirements

- No normal Wi-Fi or Ethernet status icon appears in the resting bar.
- Exceptional states distinguish no network, no internet, limited connectivity, and captive portal when reliably known.
- Current download speed remains a bar responsibility; the network adapter supplies normalized counters/state.
- Wi-Fi and Bluetooth quick controls provide both toggle and detail actions.
- Detail workflows remain inside the control centre, not detached tiny popups.
- Wi-Fi supports scan, connect, password prompt, disconnect, forget, hidden network, and basic details.
- Bluetooth supports scan, pair, confirmation/PIN flows, connect, disconnect, forget, and battery where available.
- Advanced administration delegates through `CommandRegistry`.
- Passwords, PINs, and secrets are never persisted in shell configuration or logs.
- Connected audio-device representation belongs to `audio.md`; a separate Bluetooth contextual state appears only when it adds information.
- User-triggered changes publish system toasts. The views never call `nmcli`, `bluetoothctl`, or backend-specific D-Bus methods.

# 3. Ownership

## 3.1 Network owns

- normalized device, radio, connectivity, access-point, saved-network, and connection-task models;
- Wi-Fi scan and connection workflows;
- Ethernet summary/details;
- hidden-network and credential prompt state;
- captive-portal state when supported;
- advanced-settings delegation intent.

## 3.2 Bluetooth owns

- normalized adapter and device models;
- discovery lifecycle;
- pair/connect/disconnect/forget operations;
- protected pairing prompts;
- battery and profile metadata when available;
- non-audio contextual summaries.

## 3.3 Neither feature owns

- control-centre window geometry, page stack, global dismissal, or focus restoration;
- audio routing policy;
- bar layout or throughput formatting;
- browser, settings application, or command execution;
- backend-specific commands in view QML.

# 4. Proposed Structure

```text
services/
├── NetworkService.qml
├── NetworkThroughputService.qml
└── BluetoothService.qml

features/network/
├── NetworkController.qml
├── NetworkPage.qml
├── WifiCredentialPrompt.qml
└── fixtures/NetworkFixtureModel.qml

features/bluetooth/
├── BluetoothController.qml
├── BluetoothPage.qml
├── PairingPrompt.qml
└── fixtures/BluetoothFixtureModel.qml
```

`NetworkService` and `BluetoothService` own backend integration, lifecycle, and raw normalized operations. Feature controllers derive page-ready rows, task policy, and toast requests. Page/prompt views render those models, retain only bounded transient input, and request controller actions.

# 5. State and Models

Network state should distinguish:

```text
serviceLifecycle
networkingEnabled
wifiHardwareAvailable
wifiRadioEnabled
scanState
connectivity: Unknown | Offline | LocalOnly | Limited | CaptivePortal | Internet
activeConnections[]
wifiNetworks[]
savedConnections[]
ethernetDevices[]
operationTasks[]
lastError
```

Wi-Fi entries need stable identity, SSID/display name, strength, security, saved/active flags, hidden flag, last-seen state, and operation availability. Duplicate BSSIDs for one logical network should not create unstable user-facing rows.

Bluetooth state should distinguish:

```text
serviceLifecycle
adapters[]
activeAdapterId
powered
discoveryState
pairedDevices[]
availableDevices[]
pairingRequest
operationTasks[]
lastError
```

Device rows need stable ID, name, class/category, paired/trusted/connected flags, battery if known, audio capability, available profiles, and transition state.

# 6. Controller and Service API

Conceptual network operations:

```text
setNetworkingEnabled(value)
setWifiEnabled(value)
requestScan()
connect(networkId, credentialInput?)
connectHidden(definition, credentialInput?)
disconnect(connectionId)
forget(savedConnectionId)
openCaptivePortal()
openAdvancedSettings()
cancelTask(taskId)
```

Conceptual Bluetooth operations:

```text
setPowered(value)
startDiscovery()
stopDiscovery()
pair(deviceId)
confirmPairing(requestId, accepted)
submitPairingCode(requestId, code)
connect(deviceId, profile?)
disconnect(deviceId)
forget(deviceId)
cancelTask(taskId)
```

Operations expose observable task state rather than forcing views to infer completion. Pairing uses explicit states such as `Pairing`, `AwaitingConfirmation`, `AwaitingCode`, `Connecting`, `Connected`, `Failed`, and `Cancelled`.

# 7. Page and Navigation Behaviour

- Opening a detail action pushes the corresponding page inside the current control centre.
- `Escape` or Back first closes menus/prompts, then returns to the main drawer, then closes the drawer.
- Protected credential or pairing prompts block outside-click/drag dismissal until completed or explicitly cancelled.
- Initial focus follows the control-centre detail-page contract: visible Back/page-header target or first safe actionable control.
- Returning restores focus to the originating quick control.
- Closing clears password/PIN fields and cancels only operations whose backend contract permits cancellation.

When a detail page is opened by keyboard, focus enters its visible Back/page-header target or first safe actionable control according to the control-centre contract. Pointer opening does not steal keyboard focus until keyboard navigation begins.

# 8. Pointer and Keyboard Interaction

- Primary activation on an available Wi-Fi row starts or opens its connection flow; on the active connection it opens details containing an explicit Disconnect action.
- Primary activation on a Bluetooth row starts Pair/Connect as appropriate or opens device actions when more than one safe operation is available.
- Secondary activation may open an action menu; it must not bypass confirmation.
- Middle-click has no default action.
- Scroll moves lists; scrolling over a deliberate toggle does not change it.
- Hover may reveal secondary actions but does not start scanning.
- Drag may scroll lists; device reordering is not supported.
- Keyboard supports arrows, `Home`, `End`, `PageUp`, `PageDown`, activation, context menu, Back, and `Escape`.
- Toggle and detail controls require separate accessible names and adequate targets.
- On a Wi-Fi/Bluetooth quick control, `Space` toggles, `Right` or its explicit detail affordance opens the page, and `Enter` follows the visible primary-action contract.

Signal strength, security, pairing, battery, and failure state require text or shape/icon cues in addition to colour. Long names, text scaling, high contrast, and reduced motion must preserve action targets and row identity.

# 9. Workflow Requirements

## 9.1 Wi-Fi

- Scan on page open only when enabled/configured; rate-limit requests.
- Preserve stable row order while strengths update.
- Secured connections request credentials only when the backend requires them.
- Clear credentials immediately after submission/cancellation.
- Forgetting a saved connection is an explicit secondary/detail action with the shared lightweight confirmation-or-undo policy; it is never the row's immediate primary action.
- Enterprise networks may delegate if safe in-shell support is unavailable.
- Hidden-network creation must validate required fields without storing secrets.
- Ethernet presentation distinguishes active, disconnected/cable absent, disabled, unavailable, and failed states; common Ethernet disconnect/details actions use the same task model where supported.

## 9.2 Bluetooth

- Discovery is bounded and normally active only while the page is visible.
- Pairing codes and confirmations remain protected foreground interactions and use the accepted critical-bypass policy.
- Connecting an audio device does not force output selection unless later policy/configuration says so.
- Forgetting a paired device is an explicit secondary/detail action with the shared lightweight confirmation-or-undo policy.
- Unsupported profile management is explained or delegated.

# 10. Error and Unavailable States

Represent distinctly:

- backend unavailable, starting, reconnecting, degraded, or failed;
- no Wi-Fi hardware versus Wi-Fi radio off;
- no Bluetooth adapter versus adapter powered off;
- empty scan versus scan denied/failed;
- disconnected versus no internet versus captive portal;
- permission denied;
- incorrect password/authentication failure;
- device vanished, operation timed out, pairing rejected, or profile unsupported.

Unavailable capabilities are omitted or explained. Existing safe state may remain visible during reconnect, but stale connection state must not authorize actions. User-requested failures produce one actionable toast and structured diagnostics.

# 11. Dependencies, Security, and Configuration

Dependencies include `SurfaceCoordinator`, control-centre page host, `CapabilityRegistry`, `Diagnostics`, `CommandRegistry`, toast publisher, `MonitorRegistry`, and selected NetworkManager/BlueZ adapters.

The exact Quickshell/native/retained-service choices remain research items. Credentials go directly to the selected secret-agent/backend contract, are redacted from errors, and never enter config, history, fixtures containing real data, or command arguments visible to unrelated processes.

# 12. Multi-Monitor and Performance

Network and Bluetooth state is normally global, while the page belongs to the single owning control centre. Pairing prompts retain their owning monitor until completion or owner removal. Hotplug of displays must not cancel device operations or leave invisible focus.

Prefer events to polling. Throughput uses lightweight bounded sampling. Wi-Fi scans and Bluetooth discovery are on-demand and rate-limited. Hidden pages stop scan timers, animations, and list churn. Large lists use reusable delegates and stable keys.

# 13. Fixtures

- ready internet connection; offline; local-only; limited; captive portal;
- backend absent/reconnecting/permission denied;
- Wi-Fi off; no hardware; empty scan; many duplicate/long SSIDs;
- Ethernet active, cable absent, disabled, and backend failure;
- open, saved secured, hidden, wrong-password, connecting, and cancelled networks;
- no Bluetooth adapter; powered off; empty discovery; many devices;
- paired/disconnected, connecting, connected audio and non-audio devices;
- pairing confirmation, PIN, rejected, timeout, vanished device;
- mixed-scale owner monitor removal during protected prompt.

# 14. Implementation Phases

1. **Phase 3 fixture pages:** nested navigation, focus, protected prompt mechanics.
2. **Phase 4 adapters:** normalized lifecycle/state and mocked operations.
3. **Phase 6 daily use:** required Wi-Fi and Bluetooth workflows plus contextual exceptions/toasts.
4. **Post-prototype/deferred depth:** advanced delegation, enterprise networking, captive-portal refinements, and profile operations only when separately scheduled.
5. **Phase 10/11:** monitor/focus, accessibility, large-list, and visual hardening.

# 15. Acceptance Criteria

- Normal connected Wi-Fi/Ethernet and ordinary Bluetooth state remain absent from the resting bar.
- Wi-Fi fixtures exercise scan, open/secured/hidden connection flows, credential cancellation, disconnect, and forget with observable pending/success/failure states.
- Bluetooth fixtures exercise discovery, pairing code/confirmation, connect, disconnect, forget, and optional battery display with observable transition/failure states.
- Ethernet state is visible in the Network page without creating a permanent resting-bar icon.
- Backend-specific commands are absent from views.
- Password/PIN data is cleared and never logged or persisted.
- Off, absent, empty, disconnected, limited, denied, and failed states are visibly distinct.
- Protected prompts cannot vanish through outside click or drawer drag.
- A focused network/device row retains focus by stable identity across signal/battery updates or moves to the next valid row if removed.
- User-triggered success/failure feedback uses toasts, not application notifications or OSDs.
- Optional backend loss degrades locally and can reconnect without restarting the shell.

# 16. Unresolved Questions

- **Q-001, Q-002:** exact Quickshell capability and retained Caelestia service baseline.
- **Q-050:** network backend choice and completeness.
- **Q-051:** NetworkManager secret-agent handling.
- **Q-052:** captive-portal detection/action.
- **Q-053:** configurable advanced-network application.
- **Q-054:** Bluetooth backend completeness and fallback.
- **Q-055:** Bluetooth audio-output switching policy.
- **Q-056:** non-audio Bluetooth contextual visibility.
- **Q-026:** final split toggle/detail interaction in the control centre.
- **Q-028:** restoration/expiry of Wi-Fi prompts, Bluetooth pairing tasks, and page-local selection after drawer closure.
- **Q-012, Q-013:** throughput units/aggregation and click action remain owned primarily by `bar.md`, but constrain the shared throughput adapter.

# 17. Codex Implementation Guardrails

- Do not model normal connectivity as permanent bar status.
- Do not create detached Wi-Fi/Bluetooth popups.
- Do not store or log credentials or pairing codes.
- Do not duplicate audio-device truth.
- Do not keep scanning merely because the control centre process exists.
