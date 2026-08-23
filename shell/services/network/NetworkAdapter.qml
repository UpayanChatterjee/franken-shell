import QtQuick
import Quickshell

Scope {
    id: root

    readonly property var activeConnection: root.findConnected(root.devices)
    readonly property bool available: state.connectionState === "ready"
    readonly property string connectionState: state.connectionState
    readonly property string connectivity: state.connectivity
    readonly property var devices: state.devices
    readonly property var ethernetDevices: state.ethernetDevices
    readonly property string lastError: state.lastError
    readonly property var operationTasks: state.operationTasks
    required property var runtime
    readonly property var savedNetworks: state.savedNetworks
    readonly property string scanState: state.scanning ? "scanning" : state.lastScanFailed ? "failed" : "idle"
    readonly property bool stale: state.stale
    readonly property string status: root.statusName()
    readonly property var visibleNetworks: state.visibleNetworks
    readonly property bool wifiEnabled: state.wifiEnabled
    readonly property bool wifiHardwareAvailable: state.wifiHardwareAvailable

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
            state.lastError = String(response?.errorCode ?? "NETWORK_ACTION_FAILED");
            if (kind === "scan")
                state.lastScanFailed = true;
            root.stateChanged();
            return root.result(false, "", state.lastError);
        }
        const task = Object.freeze({
            "taskId": String(response.taskId ?? ""),
            "kind": kind,
            "targetId": targetId,
            "desiredValue": desiredValue,
            "state": "pending",
            "errorCode": ""
        });
        const retained = state.operationTasks.filter(candidate => candidate.state === "pending" || candidate.kind !== kind || candidate.targetId !== targetId);
        retained.push(task);
        state.operationTasks = Object.freeze(retained.slice(-12));
        state.lastError = "";
        if (kind === "scan")
            state.lastScanFailed = false;
        root.stateChanged();
        return root.result(true, task.taskId, "");
    }
    function cancelTask(taskId: string): var {
        const task = root.task(taskId);
        if (task === null || task.state !== "pending")
            return root.result(false, "", "NETWORK_TASK_UNAVAILABLE");
        const response = root.runtime.cancelAction(task.taskId, task.kind, task.targetId);
        if (response?.accepted !== true)
            return root.result(false, "", String(response?.errorCode ?? "NETWORK_CANCEL_FAILED"));
        root.updateTask(task.taskId, "cancelled", "");
        return root.result(true, task.taskId, "");
    }
    function connectNetwork(networkId: string, credential: string): var {
        if (!root.available)
            return root.result(false, "", "NETWORK_BACKEND_DISCONNECTED");
        const network = root.findNetwork(networkId);
        if (network === null)
            return root.result(false, "", "NETWORK_NETWORK_UNAVAILABLE");
        if (network.connected)
            return root.result(false, "", "NETWORK_ALREADY_CONNECTED");
        return root.beginTask("connect", networkId, true, root.runtime.connectNetwork(networkId, credential));
    }
    function diagnosticsSummary(): var {
        return Object.freeze({
            "available": root.available,
            "connectionState": root.connectionState,
            "stale": root.stale,
            "status": root.status,
            "connectivity": root.connectivity,
            "wifiEnabled": root.wifiEnabled,
            "wifiHardwareAvailable": root.wifiHardwareAvailable,
            "scanState": root.scanState,
            "visibleNetworkCount": root.visibleNetworks.length,
            "savedNetworkCount": root.savedNetworks.length,
            "ethernetDeviceCount": root.ethernetDevices.length,
            "activeConnectionPresent": root.activeConnection !== null,
            "pendingTaskCount": root.operationTasks.filter(task => task.state === "pending").length,
            "lastError": root.lastError
        });
    }
    function disconnectNetwork(networkId: string): var {
        if (!root.available)
            return root.result(false, "", "NETWORK_BACKEND_DISCONNECTED");
        const network = root.findNetwork(networkId);
        if (network === null || !network.connected)
            return root.result(false, "", "NETWORK_CONNECTION_UNAVAILABLE");
        return root.beginTask("disconnect", networkId, false, root.runtime.disconnectNetwork(networkId));
    }
    function findConnected(deviceRecords): var {
        for (const device of deviceRecords) {
            for (const network of device.networks) {
                if (network.connected)
                    return network;
            }
        }
        return null;
    }
    function findNetwork(networkId: string): var {
        for (const device of root.devices) {
            for (const network of device.networks) {
                if (network.id === networkId)
                    return network;
            }
        }
        return null;
    }
    function forgetNetwork(networkId: string): var {
        if (!root.available)
            return root.result(false, "", "NETWORK_BACKEND_DISCONNECTED");
        const network = root.findNetwork(networkId);
        if (network === null || !network.known)
            return root.result(false, "", "NETWORK_SAVED_CONNECTION_UNAVAILABLE");
        return root.beginTask("forget", networkId, false, root.runtime.forgetNetwork(networkId));
    }
    function handleActionFailed(taskId: string, errorCode: string) {
        const task = root.task(taskId);
        if (task === null || task.state !== "pending")
            return;
        const safeCode = String(errorCode || "NETWORK_ACTION_FAILED");
        state.lastError = safeCode;
        if (task.kind === "scan")
            state.lastScanFailed = true;
        root.updateTask(taskId, "failed", safeCode);
    }
    function handleConnectionChanged(connected: bool) {
        if (!connected) {
            state.connectionState = state.hasSnapshot ? "reconnecting" : "unavailable";
            state.stale = state.hasSnapshot;
            for (const task of state.operationTasks) {
                if (task.state === "pending")
                    root.updateTask(task.taskId, "failed", "NETWORK_BACKEND_DISCONNECTED");
            }
            root.stateChanged();
            return;
        }
        state.connectionState = "starting";
        state.stale = state.hasSnapshot;
        root.runtime.requestRefresh();
    }
    function normalizeConnectivity(value: string): string {
        if (["offline", "local", "limited", "captive", "internet"].indexOf(value) >= 0)
            return value;
        return "unknown";
    }
    function normalizeDevice(candidate): var {
        const networks = [];
        for (const rawNetwork of root.asArray(candidate?.networks)) {
            const network = root.normalizeNetwork(rawNetwork, String(candidate?.id ?? ""));
            if (network !== null)
                networks.push(network);
        }
        return Object.freeze({
            "id": String(candidate?.id ?? ""),
            "name": String(candidate?.name ?? ""),
            "address": String(candidate?.address ?? ""),
            "type": String(candidate?.type ?? "unknown"),
            "state": String(candidate?.state ?? "unknown"),
            "connected": candidate?.connected === true,
            "hasLink": candidate?.hasLink === true,
            "linkSpeedMbps": Math.max(0, Number(candidate?.linkSpeedMbps ?? 0)),
            "networks": Object.freeze(networks)
        });
    }
    function normalizeNetwork(candidate, deviceId: string): var {
        const id = String(candidate?.id ?? "");
        if (id.length === 0)
            return null;
        return Object.freeze({
            "id": id,
            "deviceId": deviceId,
            "name": String(candidate?.name ?? ""),
            "signalStrength": Math.max(0, Math.min(1, Number(candidate?.signalStrength ?? 0))),
            "security": String(candidate?.security ?? "unknown"),
            "known": candidate?.known === true,
            "connected": candidate?.connected === true,
            "visible": candidate?.visible !== false,
            "state": String(candidate?.state ?? "unknown")
        });
    }
    function reconcile() {
        if (!root.runtime?.connected)
            return;
        let snapshot;
        try {
            snapshot = root.runtime.snapshot();
        } catch (error) {
            state.connectionState = "degraded";
            state.lastError = "NETWORK_SNAPSHOT_FAILED";
            state.stale = state.hasSnapshot;
            root.stateChanged();
            return;
        }
        const sequence = Number(snapshot?.sequence ?? 0);
        if (sequence < state.lastSequence) {
            state.staleSnapshotCount += 1;
            root.stateChanged();
            return;
        }
        const nextDevices = [];
        for (const candidate of root.asArray(snapshot?.devices)) {
            const device = root.normalizeDevice(candidate);
            if (device.id.length > 0)
                nextDevices.push(device);
        }
        nextDevices.sort((left, right) => left.id.localeCompare(right.id));
        const visible = [];
        const saved = [];
        const ethernet = [];
        for (const device of nextDevices) {
            if (device.type === "ethernet")
                ethernet.push(device);
            for (const network of device.networks) {
                if (device.type === "wifi" && network.visible)
                    visible.push(network);
                if (device.type === "wifi" && network.known)
                    saved.push(network);
            }
        }
        const previousOrder = {};
        state.visibleNetworks.forEach((network, index) => previousOrder[network.id] = index);
        visible.sort((left, right) => {
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
        saved.sort((left, right) => left.name.localeCompare(right.name));
        state.devices = Object.freeze(nextDevices);
        state.visibleNetworks = Object.freeze(visible);
        state.savedNetworks = Object.freeze(saved);
        state.ethernetDevices = Object.freeze(ethernet);
        state.wifiEnabled = snapshot?.wifiEnabled === true;
        state.wifiHardwareAvailable = snapshot?.wifiHardwareAvailable === true;
        state.connectivity = root.normalizeConnectivity(String(snapshot?.connectivity ?? "unknown"));
        state.scanning = snapshot?.scanning === true;
        state.hasSnapshot = true;
        state.lastSequence = sequence;
        state.connectionState = "ready";
        state.stale = false;
        root.settleTasks();
        root.stateChanged();
    }
    function requestScan(): var {
        if (!root.available || !root.wifiEnabled || !root.wifiHardwareAvailable)
            return root.result(false, "", "NETWORK_SCAN_UNAVAILABLE");
        return root.beginTask("scan", "wifi", true, root.runtime.requestScan());
    }
    function result(accepted: bool, taskId: string, errorCode: string): var {
        return Object.freeze({
            "accepted": accepted,
            "taskId": taskId,
            "errorCode": errorCode
        });
    }
    function setDetailActive(active: bool) {
        if (typeof root.runtime?.setScanning === "function")
            root.runtime.setScanning(active && root.available && root.wifiEnabled && root.wifiHardwareAvailable);
    }
    function setWifiEnabled(enabled: bool): var {
        if (!root.available)
            return root.result(false, "", "NETWORK_BACKEND_DISCONNECTED");
        if (!root.wifiHardwareAvailable && enabled)
            return root.result(false, "", "NETWORK_WIFI_HARDWARE_DISABLED");
        if (root.wifiEnabled === enabled)
            return root.result(false, "", "NETWORK_NO_CHANGE");
        return root.beginTask("wifi", "wifi", enabled, root.runtime.setWifiEnabled(enabled));
    }
    function settleTasks() {
        for (const task of state.operationTasks) {
            if (task.state !== "pending")
                continue;
            let completed = false;
            if (task.kind === "wifi")
                completed = root.wifiEnabled === task.desiredValue;
            else if (task.kind === "scan")
                completed = state.scanning;
            else {
                const network = root.findNetwork(task.targetId);
                if (task.kind === "connect")
                    completed = network?.connected === true;
                else if (task.kind === "disconnect")
                    completed = network === null || network.connected !== true;
                else if (task.kind === "forget")
                    completed = network === null || network.known !== true;
            }
            if (completed)
                root.updateTask(task.taskId, "completed", "");
        }
    }
    function statusName(): string {
        if (!root.available)
            return "unavailable";
        const pending = root.operationTasks.find(task => task.state === "pending" && task.kind !== "scan");
        if (pending !== undefined)
            return "connecting";
        const latestTask = root.operationTasks[root.operationTasks.length - 1];
        if (latestTask?.state === "failed")
            return "failed";
        if (root.connectivity === "captive")
            return "captive";
        if (root.connectivity === "limited" || root.connectivity === "local")
            return "limited";
        if (root.activeConnection !== null || root.connectivity === "internet")
            return "connected";
        if (state.scanning)
            return "scanning";
        if (!root.wifiEnabled && root.ethernetDevices.every(device => !device.connected))
            return "disabled";
        return "disconnected";
    }
    function task(taskId: string): var {
        for (const candidate of state.operationTasks) {
            if (candidate.taskId === taskId)
                return candidate;
        }
        return null;
    }
    function updateTask(taskId: string, taskState: string, errorCode: string) {
        const next = state.operationTasks.map(task => task.taskId === taskId ? Object.freeze({
                "taskId": task.taskId,
                "kind": task.kind,
                "targetId": task.targetId,
                "desiredValue": task.desiredValue,
                "state": taskState,
                "errorCode": errorCode
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

        property string connectionState: "unavailable"
        property string connectivity: "unknown"
        property var devices: Object.freeze([])
        property var ethernetDevices: Object.freeze([])
        property bool hasSnapshot: false
        property string lastError: ""
        property bool lastScanFailed: false
        property int lastSequence: -1
        property var operationTasks: Object.freeze([])
        property var savedNetworks: Object.freeze([])
        property bool scanning: false
        property bool stale: false
        property int staleSnapshotCount: 0
        property var visibleNetworks: Object.freeze([])
        property bool wifiEnabled: false
        property bool wifiHardwareAvailable: false
    }
    Connections {
        function onActionFailed(taskId, errorCode) {
            root.handleActionFailed(taskId, errorCode);
        }
        function onConnectionChanged(connected) {
            root.handleConnectionChanged(connected);
        }
        function onStateChanged() {
            root.reconcile();
        }

        ignoreUnknownSignals: true
        target: root.runtime
    }
}
