import QtQuick
import Quickshell

Scope {
    id: root

    readonly property var activeAdapter: root.adapters.length > 0 ? root.adapters[0] : null
    readonly property var adapters: state.adapters
    readonly property bool available: state.connectionState === "ready"
    readonly property var availableDevices: root.devices.filter(device => !device.paired)
    readonly property var connectedDevices: root.devices.filter(device => device.connected)
    readonly property string connectionState: state.connectionState
    readonly property var devices: state.devices
    readonly property string discoveryState: state.discoveryFailed ? "failed" : root.activeAdapter?.discovering === true ? "discovering" : "idle"
    readonly property string lastError: state.lastError
    readonly property var nonAudioConnectedDevices: root.connectedDevices.filter(device => !device.audioCapable)
    readonly property var operationTasks: state.operationTasks
    property int operationTimeoutMs: 30000
    readonly property var pairedDevices: root.devices.filter(device => device.paired)
    readonly property var pairingRequest: state.pairingRequest
    readonly property bool powered: root.activeAdapter?.powered === true
    required property var runtime
    readonly property bool stale: state.stale
    readonly property string status: root.statusName()

    signal stateChanged

    function asArray(value): var {
        if (Array.isArray(value))
            return value;
        if (typeof value?.toArray === "function")
            return value.toArray();
        return [];
    }
    function beginTask(kind: string, targetId: string, desiredValue, response): var {
        if (response?.accepted !== true) {
            state.lastError = String(response?.errorCode ?? "BLUETOOTH_ACTION_FAILED");
            if (kind === "discovery")
                state.discoveryFailed = true;
            root.stateChanged();
            return root.result(false, "", state.lastError);
        }
        const task = Object.freeze({
            "taskId": String(response.taskId ?? ""),
            "kind": kind,
            "targetId": targetId,
            "desiredValue": desiredValue,
            "state": "pending",
            "errorCode": "",
            "deadlineMs": Date.now() + (kind === "pair" ? root.operationTimeoutMs * 4 : root.operationTimeoutMs)
        });
        const retained = state.operationTasks.filter(candidate => candidate.state === "pending" || candidate.state === "awaitingInput" || candidate.kind !== kind || candidate.targetId !== targetId);
        retained.push(task);
        state.operationTasks = Object.freeze(retained.slice(-12));
        state.lastError = "";
        if (kind === "discovery")
            state.discoveryFailed = false;
        root.stateChanged();
        return root.result(true, task.taskId, "");
    }
    function cancelTask(taskId: string): var {
        const task = root.task(taskId);
        if (task === null || ["pending", "awaitingInput"].indexOf(task.state) < 0)
            return root.result(false, "", "BLUETOOTH_TASK_UNAVAILABLE");
        const response = root.runtime.cancelAction(task.taskId, task.kind, task.targetId);
        if (response?.accepted !== true)
            return root.result(false, "", String(response?.errorCode ?? "BLUETOOTH_CANCEL_FAILED"));
        if (state.pairingRequest.taskId === task.taskId)
            state.pairingRequest = root.emptyPairingRequest();
        root.updateTask(task.taskId, "cancelled", "");
        return root.result(true, task.taskId, "");
    }
    function confirmPairing(accepted: bool): var {
        const request = state.pairingRequest;
        if (!request.active || request.kind !== "confirmation")
            return root.result(false, "", "BLUETOOTH_PAIRING_REQUEST_UNAVAILABLE");
        state.pairingRequest = root.emptyPairingRequest();
        const response = root.runtime.respondPairing(request.requestId, accepted, "");
        if (response?.accepted !== true) {
            root.updateTask(request.taskId, "failed", String(response?.errorCode ?? "BLUETOOTH_PAIRING_RESPONSE_FAILED"));
            return root.result(false, "", String(response?.errorCode ?? "BLUETOOTH_PAIRING_RESPONSE_FAILED"));
        }
        root.updateTask(request.taskId, accepted ? "pending" : "cancelled", "");
        return root.result(true, request.taskId, "");
    }
    function connectDevice(deviceId: string): var {
        if (!root.available)
            return root.result(false, "", "BLUETOOTH_BACKEND_DISCONNECTED");
        const device = root.findDevice(deviceId);
        if (device === null)
            return root.result(false, "", "BLUETOOTH_DEVICE_UNAVAILABLE");
        if (device.connected)
            return root.result(false, "", "BLUETOOTH_ALREADY_CONNECTED");
        if (!device.paired)
            return root.result(false, "", "BLUETOOTH_DEVICE_NOT_PAIRED");
        if (root.deviceBusy(deviceId))
            return root.result(false, "", "BLUETOOTH_DEVICE_BUSY");
        return root.beginTask("connect", deviceId, true, root.runtime.connectDevice(deviceId));
    }
    function deviceBusy(deviceId: string): bool {
        return state.operationTasks.some(task => task.targetId === deviceId && ["pending", "awaitingInput"].indexOf(task.state) >= 0);
    }
    function diagnosticsSummary(): var {
        return Object.freeze({
            "available": root.available,
            "connectionState": root.connectionState,
            "stale": root.stale,
            "status": root.status,
            "powered": root.powered,
            "discoveryState": root.discoveryState,
            "adapterCount": root.adapters.length,
            "deviceCount": root.devices.length,
            "pairedDeviceCount": root.pairedDevices.length,
            "connectedDeviceCount": root.connectedDevices.length,
            "availableDeviceCount": root.availableDevices.length,
            "nonAudioConnectedDeviceCount": root.nonAudioConnectedDevices.length,
            "pairingRequestActive": root.pairingRequest.active,
            "pairingRequestKind": root.pairingRequest.active ? root.pairingRequest.kind : "none",
            "pendingTaskCount": root.operationTasks.filter(task => task.state === "pending" || task.state === "awaitingInput").length,
            "lastError": root.lastError
        });
    }
    function disconnectDevice(deviceId: string): var {
        if (!root.available)
            return root.result(false, "", "BLUETOOTH_BACKEND_DISCONNECTED");
        const device = root.findDevice(deviceId);
        if (device === null || !device.connected)
            return root.result(false, "", "BLUETOOTH_CONNECTION_UNAVAILABLE");
        if (root.deviceBusy(deviceId))
            return root.result(false, "", "BLUETOOTH_DEVICE_BUSY");
        return root.beginTask("disconnect", deviceId, false, root.runtime.disconnectDevice(deviceId));
    }
    function emptyPairingRequest(): var {
        return Object.freeze({
            "active": false,
            "taskId": "",
            "requestId": "",
            "deviceId": "",
            "deviceName": "",
            "kind": "none",
            "displayCode": ""
        });
    }
    function expireTasks(nowMs: real) {
        for (const task of state.operationTasks) {
            if (["pending", "awaitingInput"].indexOf(task.state) >= 0 && task.deadlineMs <= nowMs)
                root.handleActionFailed(task.taskId, "BLUETOOTH_OPERATION_TIMEOUT");
        }
    }
    function findAdapter(adapterId: string): var {
        return root.adapters.find(adapter => adapter.id === adapterId) ?? null;
    }
    function findDevice(deviceId: string): var {
        return root.devices.find(device => device.id === deviceId) ?? null;
    }
    function forgetDevice(deviceId: string): var {
        if (!root.available)
            return root.result(false, "", "BLUETOOTH_BACKEND_DISCONNECTED");
        const device = root.findDevice(deviceId);
        if (device === null || !device.paired)
            return root.result(false, "", "BLUETOOTH_PAIRED_DEVICE_UNAVAILABLE");
        if (root.deviceBusy(deviceId))
            return root.result(false, "", "BLUETOOTH_DEVICE_BUSY");
        return root.beginTask("forget", deviceId, false, root.runtime.forgetDevice(deviceId));
    }
    function handleActionFailed(taskId: string, errorCode: string) {
        const task = root.task(taskId);
        if (task === null || ["pending", "awaitingInput"].indexOf(task.state) < 0)
            return;
        const safeCode = String(errorCode || "BLUETOOTH_ACTION_FAILED");
        if (task.kind === "discovery")
            state.discoveryFailed = true;
        if (state.pairingRequest.taskId === taskId)
            state.pairingRequest = root.emptyPairingRequest();
        root.updateTask(taskId, "failed", safeCode);
    }
    function handleConnectionChanged(connected: bool) {
        if (!connected) {
            state.connectionState = state.hasSnapshot ? "reconnecting" : "unavailable";
            state.stale = state.hasSnapshot;
            state.pairingRequest = root.emptyPairingRequest();
            for (const task of state.operationTasks) {
                if (["pending", "awaitingInput"].indexOf(task.state) >= 0)
                    root.updateTask(task.taskId, "failed", "BLUETOOTH_BACKEND_DISCONNECTED");
            }
            root.stateChanged();
            return;
        }
        state.connectionState = "starting";
        state.stale = state.hasSnapshot;
        root.runtime.requestRefresh();
    }
    function handlePairingRequested(taskId: string, requestId: string, deviceId: string, kind: string, displayCode: string) {
        const task = root.task(taskId);
        if (task === null || task.kind !== "pair" || task.state !== "pending")
            return;
        const safeKind = kind === "code" ? "code" : kind === "confirmation" ? "confirmation" : "unsupported";
        if (safeKind === "unsupported") {
            root.handleActionFailed(taskId, "BLUETOOTH_PAIRING_PROMPT_UNSUPPORTED");
            return;
        }
        const device = root.findDevice(deviceId);
        state.pairingRequest = Object.freeze({
            "active": true,
            "taskId": taskId,
            "requestId": requestId,
            "deviceId": deviceId,
            "deviceName": device?.name ?? "",
            "kind": safeKind,
            "displayCode": safeKind === "confirmation" ? String(displayCode) : ""
        });
        root.updateTask(taskId, "awaitingInput", "");
    }
    function normalizeAdapter(candidate): var {
        const devices = [];
        for (const rawDevice of root.asArray(candidate?.devices)) {
            const device = root.normalizeDevice(rawDevice, String(candidate?.id ?? ""));
            if (device !== null)
                devices.push(device);
        }
        return Object.freeze({
            "id": String(candidate?.id ?? ""),
            "name": String(candidate?.name ?? ""),
            "state": String(candidate?.state ?? "unknown"),
            "defaultAdapter": candidate?.defaultAdapter === true,
            "powered": candidate?.powered === true,
            "discovering": candidate?.discovering === true,
            "devices": Object.freeze(devices)
        });
    }
    function normalizeDevice(candidate, adapterId: string): var {
        const id = String(candidate?.id ?? "");
        if (id.length === 0)
            return null;
        const batteryAvailable = candidate?.batteryAvailable === true;
        return Object.freeze({
            "id": id,
            "adapterId": adapterId,
            "address": String(candidate?.address ?? ""),
            "name": String(candidate?.name ?? ""),
            "icon": String(candidate?.icon ?? ""),
            "category": String(candidate?.category ?? "other"),
            "paired": candidate?.paired === true,
            "bonded": candidate?.bonded === true,
            "trusted": candidate?.trusted === true,
            "connected": candidate?.connected === true,
            "pairing": candidate?.pairing === true,
            "batteryAvailable": batteryAvailable,
            "battery": batteryAvailable ? Math.max(0, Math.min(1, Number(candidate?.battery ?? 0))) : -1,
            "audioCapable": candidate?.audioCapable === true,
            "state": String(candidate?.state ?? "unknown")
        });
    }
    function pairDevice(deviceId: string): var {
        if (!root.available || !root.powered)
            return root.result(false, "", "BLUETOOTH_PAIRING_UNAVAILABLE");
        const device = root.findDevice(deviceId);
        if (device === null)
            return root.result(false, "", "BLUETOOTH_DEVICE_UNAVAILABLE");
        if (device.paired)
            return root.result(false, "", "BLUETOOTH_ALREADY_PAIRED");
        if (root.deviceBusy(deviceId))
            return root.result(false, "", "BLUETOOTH_DEVICE_BUSY");
        return root.beginTask("pair", deviceId, true, root.runtime.pairDevice(deviceId));
    }
    function reconcile() {
        if (!root.runtime?.connected)
            return;
        let snapshot;
        try {
            snapshot = root.runtime.snapshot();
        } catch (error) {
            state.connectionState = "degraded";
            state.lastError = "BLUETOOTH_SNAPSHOT_FAILED";
            state.stale = state.hasSnapshot;
            root.stateChanged();
            return;
        }
        const sequence = Number(snapshot?.sequence ?? 0);
        if (sequence < state.lastSequence)
            return;
        const adapters = [];
        for (const candidate of root.asArray(snapshot?.adapters)) {
            const adapter = root.normalizeAdapter(candidate);
            if (adapter.id.length > 0)
                adapters.push(adapter);
        }
        adapters.sort((left, right) => (right.defaultAdapter - left.defaultAdapter) || left.id.localeCompare(right.id));
        const devices = [];
        for (const adapter of adapters)
            devices.push(...adapter.devices);
        const previousOrder = {};
        state.devices.forEach((device, index) => previousOrder[device.id] = index);
        devices.sort((left, right) => {
            const leftOrder = previousOrder[left.id];
            const rightOrder = previousOrder[right.id];
            if (leftOrder !== undefined && rightOrder !== undefined)
                return leftOrder - rightOrder;
            if (leftOrder !== undefined)
                return -1;
            if (rightOrder !== undefined)
                return 1;
            return left.name.localeCompare(right.name);
        });
        state.adapters = Object.freeze(adapters);
        state.devices = Object.freeze(devices);
        state.hasSnapshot = true;
        state.lastSequence = sequence;
        state.connectionState = "ready";
        state.stale = false;
        root.settleTasks();
        if (!state.detailActive && root.activeAdapter?.discovering === true)
            root.stopDiscovery();
        root.stateChanged();
    }
    function result(accepted: bool, taskId: string, errorCode: string): var {
        return Object.freeze({
            "accepted": accepted,
            "taskId": taskId,
            "errorCode": errorCode
        });
    }
    function setDetailActive(active: bool) {
        state.detailActive = active;
        if (!root.available || !root.powered)
            return;
        const discoveryStarting = state.operationTasks.some(task => task.kind === "discovery" && task.desiredValue === true && ["pending", "awaitingInput"].indexOf(task.state) >= 0);
        if (active && root.discoveryState !== "discovering")
            root.startDiscovery();
        else if (!active && (root.discoveryState === "discovering" || discoveryStarting))
            root.stopDiscovery();
    }
    function setPowered(enabled: bool): var {
        if (!root.available || root.activeAdapter === null)
            return root.result(false, "", "BLUETOOTH_ADAPTER_UNAVAILABLE");
        if (root.powered === enabled)
            return root.result(false, "", "BLUETOOTH_NO_CHANGE");
        if (state.operationTasks.some(task => task.kind === "power" && ["pending", "awaitingInput"].indexOf(task.state) >= 0))
            return root.result(false, "", "BLUETOOTH_POWER_IN_PROGRESS");
        return root.beginTask("power", root.activeAdapter.id, enabled, root.runtime.setPowered(root.activeAdapter.id, enabled));
    }
    function settleTasks() {
        for (const task of state.operationTasks) {
            if (task.state !== "pending")
                continue;
            let completed = false;
            if (task.kind === "power")
                completed = root.findAdapter(task.targetId)?.powered === task.desiredValue;
            else if (task.kind === "discovery")
                completed = root.findAdapter(task.targetId)?.discovering === task.desiredValue;
            else {
                const device = root.findDevice(task.targetId);
                if (task.kind === "pair") {
                    if (device === null)
                        root.updateTask(task.taskId, "failed", "BLUETOOTH_DEVICE_VANISHED");
                    else
                        completed = device.paired;
                } else if (task.kind === "connect") {
                    if (device === null)
                        root.updateTask(task.taskId, "failed", "BLUETOOTH_DEVICE_VANISHED");
                    else
                        completed = device.connected;
                } else if (task.kind === "disconnect")
                    completed = device === null || !device.connected;
                else if (task.kind === "forget")
                    completed = device === null || !device.paired;
            }
            if (completed)
                root.updateTask(task.taskId, "completed", "");
        }
    }
    function startDiscovery(): var {
        if (!root.available || !root.powered || root.activeAdapter === null)
            return root.result(false, "", "BLUETOOTH_DISCOVERY_UNAVAILABLE");
        const pending = state.operationTasks.find(task => task.kind === "discovery" && ["pending", "awaitingInput"].indexOf(task.state) >= 0);
        if (pending !== undefined) {
            if (pending.desiredValue === true)
                return root.result(false, "", "BLUETOOTH_DISCOVERY_IN_PROGRESS");
            const response = root.runtime.setDiscovery(root.activeAdapter.id, true);
            if (response?.accepted !== true)
                return root.result(false, "", String(response?.errorCode ?? "BLUETOOTH_DISCOVERY_FAILED"));
            root.updateTask(pending.taskId, "cancelled", "");
            return root.beginTask("discovery", root.activeAdapter.id, true, response);
        }
        if (root.activeAdapter.discovering)
            return root.result(false, "", "BLUETOOTH_NO_CHANGE");
        return root.beginTask("discovery", root.activeAdapter.id, true, root.runtime.setDiscovery(root.activeAdapter.id, true));
    }
    function statusName(): string {
        if (!root.available)
            return "unavailable";
        const latestTask = root.operationTasks[root.operationTasks.length - 1];
        if (latestTask?.state === "awaitingInput")
            return root.pairingRequest.kind === "code" ? "awaitingCode" : "awaitingConfirmation";
        if (latestTask?.state === "pending") {
            if (latestTask.kind === "pair")
                return "pairing";
            if (latestTask.kind === "connect")
                return "connecting";
            if (latestTask.kind === "discovery")
                return "discovering";
            return "changing";
        }
        if (latestTask?.state === "failed")
            return "failed";
        if (!root.powered)
            return "disabled";
        if (root.discoveryState === "discovering")
            return "discovering";
        if (root.connectedDevices.length > 0)
            return "connected";
        return "ready";
    }
    function stopDiscovery(): var {
        if (!root.available || root.activeAdapter === null)
            return root.result(false, "", "BLUETOOTH_ADAPTER_UNAVAILABLE");
        const pending = state.operationTasks.find(task => task.kind === "discovery" && ["pending", "awaitingInput"].indexOf(task.state) >= 0);
        if (pending !== undefined) {
            if (pending.desiredValue === false)
                return root.result(false, "", "BLUETOOTH_DISCOVERY_IN_PROGRESS");
            const response = root.runtime.setDiscovery(root.activeAdapter.id, false);
            if (response?.accepted !== true)
                return root.result(false, "", String(response?.errorCode ?? "BLUETOOTH_DISCOVERY_FAILED"));
            root.updateTask(pending.taskId, "cancelled", "");
            return root.beginTask("discovery", root.activeAdapter.id, false, response);
        }
        if (!root.activeAdapter.discovering)
            return root.result(false, "", "BLUETOOTH_NO_CHANGE");
        return root.beginTask("discovery", root.activeAdapter.id, false, root.runtime.setDiscovery(root.activeAdapter.id, false));
    }
    function submitPairingCode(code: string): var {
        const request = state.pairingRequest;
        if (!request.active || request.kind !== "code")
            return root.result(false, "", "BLUETOOTH_PAIRING_REQUEST_UNAVAILABLE");
        if (code.length === 0)
            return root.result(false, request.taskId, "BLUETOOTH_PAIRING_CODE_EMPTY");
        state.pairingRequest = root.emptyPairingRequest();
        const response = root.runtime.respondPairing(request.requestId, true, code);
        if (response?.accepted !== true) {
            root.updateTask(request.taskId, "failed", String(response?.errorCode ?? "BLUETOOTH_PAIRING_RESPONSE_FAILED"));
            return root.result(false, "", String(response?.errorCode ?? "BLUETOOTH_PAIRING_RESPONSE_FAILED"));
        }
        root.updateTask(request.taskId, "pending", "");
        return root.result(true, request.taskId, "");
    }
    function task(taskId: string): var {
        return state.operationTasks.find(candidate => candidate.taskId === taskId) ?? null;
    }
    function updateTask(taskId: string, taskState: string, errorCode: string) {
        const next = state.operationTasks.map(task => task.taskId === taskId ? Object.freeze({
                "taskId": task.taskId,
                "kind": task.kind,
                "targetId": task.targetId,
                "desiredValue": task.desiredValue,
                "state": taskState,
                "errorCode": errorCode,
                "deadlineMs": task.deadlineMs
            }) : task);
        state.operationTasks = Object.freeze(next);
        if (errorCode.length > 0)
            state.lastError = errorCode;
        root.stateChanged();
    }

    Component.onCompleted: {
        if (root.runtime?.connected)
            root.handleConnectionChanged(true);
    }
    onRuntimeChanged: root.handleConnectionChanged(root.runtime?.connected === true)

    QtObject {
        id: state

        property var adapters: Object.freeze([])
        property string connectionState: "unavailable"
        property bool detailActive: false
        property var devices: Object.freeze([])
        property bool discoveryFailed: false
        property bool hasSnapshot: false
        property string lastError: ""
        property int lastSequence: -1
        property var operationTasks: Object.freeze([])
        property var pairingRequest: root.emptyPairingRequest()
        property bool stale: false
    }
    Connections {
        function onActionFailed(taskId, errorCode) {
            root.handleActionFailed(taskId, errorCode);
        }
        function onConnectionChanged(connected) {
            root.handleConnectionChanged(connected);
        }
        function onPairingRequested(taskId, requestId, deviceId, kind, displayCode) {
            root.handlePairingRequested(taskId, requestId, deviceId, kind, displayCode);
        }
        function onStateChanged() {
            root.reconcile();
        }

        ignoreUnknownSignals: true
        target: root.runtime
    }
    Timer {
        interval: 500
        repeat: true
        running: root.operationTasks.some(task => task.state === "pending" || task.state === "awaitingInput")

        onTriggered: root.expireTasks(Date.now())
    }
}
