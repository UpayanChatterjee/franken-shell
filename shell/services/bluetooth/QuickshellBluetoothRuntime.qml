pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Bluetooth

Scope {
    id: root

    readonly property bool connected: Bluetooth.defaultAdapter !== null // qmllint disable unresolved-type

    signal actionFailed(string taskId, string errorCode)
    signal connectionChanged(bool connected)
    signal pairingRequested(string taskId, string requestId, string deviceId, string kind, string displayCode)
    signal stateChanged

    function adapterId(adapter): string {
        return "bluetooth:" + String(adapter.adapterId ?? adapter.dbusPath ?? "unknown");
    }
    function adapterRecord(adapter, defaultAdapter): var {
        const devices = [];
        for (const device of root.asArray(adapter.devices))
            devices.push(root.deviceRecord(adapter, device));
        return Object.freeze({
            "id": root.adapterId(adapter),
            "name": String(adapter.name ?? adapter.adapterId ?? ""),
            "state": root.adapterStateName(adapter.state),
            "defaultAdapter": adapter === defaultAdapter,
            "powered": adapter.enabled === true,
            "discovering": adapter.discovering === true,
            "devices": Object.freeze(devices)
        });
    }
    function adapterStateName(value): string {
        switch (value) {
        case BluetoothAdapterState.Disabled:
            return "disabled";
        case BluetoothAdapterState.Enabled:
            return "enabled";
        case BluetoothAdapterState.Enabling:
            return "enabling";
        case BluetoothAdapterState.Disabling:
            return "disabling";
        case BluetoothAdapterState.Blocked:
            return "blocked";
        default:
            return "unknown";
        }
    }
    function asArray(value): var {
        if (Array.isArray(value))
            return value;
        if (value?.values !== undefined)
            return value.values;
        if (typeof value?.toArray === "function")
            return value.toArray();
        return [];
    }
    function audioCapable(icon: string): bool {
        const value = icon.toLowerCase();
        return value.indexOf("audio") >= 0 || value.indexOf("headset") >= 0 || value.indexOf("headphone") >= 0 || value.indexOf("speaker") >= 0;
    }
    function cancelAction(taskId: string, kind: string, targetId: string): var {
        if (!root.connected)
            return root.result(false, "", "BLUETOOTH_BACKEND_DISCONNECTED");
        if (kind === "pair") {
            const device = root.findDevice(targetId);
            if (device === null)
                return root.result(false, "", "BLUETOOTH_DEVICE_UNAVAILABLE");
            try {
                device.cancelPair();
                delete state.pendingDeviceTasks[targetId];
                return root.result(true, taskId, "");
            } catch (error) {
                return root.result(false, "", "BLUETOOTH_CANCEL_FAILED");
            }
        }
        return root.result(false, "", "BLUETOOTH_TASK_NOT_CANCELLABLE");
    }
    function categoryName(icon: string): string {
        const value = icon.toLowerCase();
        if (root.audioCapable(value))
            return "audio";
        if (value.indexOf("input") >= 0 || value.indexOf("keyboard") >= 0 || value.indexOf("mouse") >= 0 || value.indexOf("game") >= 0)
            return "input";
        if (value.indexOf("phone") >= 0)
            return "phone";
        if (value.indexOf("computer") >= 0)
            return "computer";
        return "other";
    }
    function connectDevice(deviceId: string): var {
        return root.deviceAction("connect", deviceId, device => device.connect());
    }
    function deviceAction(kind: string, deviceId: string, action): var {
        if (!root.connected)
            return root.result(false, "", "BLUETOOTH_BACKEND_DISCONNECTED");
        const device = root.findDevice(deviceId);
        if (device === null)
            return root.result(false, "", "BLUETOOTH_DEVICE_UNAVAILABLE");
        const taskId = root.nextTaskId(kind);
        state.pendingDeviceTasks[deviceId] = Object.freeze({
            "taskId": taskId,
            "kind": kind
        });
        try {
            action(device);
            return root.result(true, taskId, "");
        } catch (error) {
            delete state.pendingDeviceTasks[deviceId];
            return root.result(false, "", "BLUETOOTH_" + kind.toUpperCase() + "_FAILED");
        }
    }
    function deviceId(adapter, device): string {
        return root.adapterId(adapter) + ":" + String(device.address ?? device.dbusPath ?? "unknown");
    }
    function deviceRecord(adapter, device): var {
        const icon = String(device.icon ?? "");
        return Object.freeze({
            "id": root.deviceId(adapter, device),
            "adapterId": root.adapterId(adapter),
            "address": String(device.address ?? ""),
            "name": String(device.name ?? device.deviceName ?? device.address ?? ""),
            "icon": icon,
            "category": root.categoryName(icon),
            "paired": device.paired === true,
            "bonded": device.bonded === true,
            "trusted": device.trusted === true,
            "connected": device.connected === true,
            "pairing": device.pairing === true,
            "batteryAvailable": device.batteryAvailable === true,
            "battery": device.batteryAvailable === true ? Number(device.battery ?? 0) : -1,
            "audioCapable": root.audioCapable(icon),
            "state": root.deviceStateName(device.state)
        });
    }
    function deviceStateName(value): string {
        switch (value) {
        case BluetoothDeviceState.Disconnected:
            return "disconnected";
        case BluetoothDeviceState.Connected:
            return "connected";
        case BluetoothDeviceState.Disconnecting:
            return "disconnecting";
        case BluetoothDeviceState.Connecting:
            return "connecting";
        default:
            return "unknown";
        }
    }
    function disconnectDevice(deviceId: string): var {
        return root.deviceAction("disconnect", deviceId, device => device.disconnect());
    }
    function evaluateDeviceTask(device) {
        const adapter = device.adapter;
        if (adapter === null || adapter === undefined)
            return;
        const id = root.deviceId(adapter, device);
        const task = state.pendingDeviceTasks[id];
        if (task === undefined)
            return;
        let completed = false;
        if (task.kind === "pair")
            completed = device.paired === true;
        else if (task.kind === "connect")
            completed = device.connected === true;
        else if (task.kind === "disconnect")
            completed = device.connected !== true;
        if (completed) {
            delete state.pendingDeviceTasks[id];
            return;
        }
        if (task.kind === "pair" && device.pairing !== true)
            root.failDeviceTask(id, "BLUETOOTH_PAIRING_FAILED");
        else if (task.kind === "connect" && root.deviceStateName(device.state) === "disconnected")
            root.failDeviceTask(id, "BLUETOOTH_CONNECTION_FAILED");
    }
    function failDeviceTask(deviceId: string, errorCode: string) {
        const task = state.pendingDeviceTasks[deviceId];
        if (task === undefined)
            return;
        delete state.pendingDeviceTasks[deviceId];
        root.actionFailed(task.taskId, errorCode);
    }
    function findAdapter(adapterId: string): var {
        for (const adapter of root.asArray(Bluetooth.adapters)) { // qmllint disable unresolved-type
            if (root.adapterId(adapter) === adapterId)
                return adapter;
        }
        return null;
    }
    function findDevice(deviceId: string): var {
        for (const adapter of root.asArray(Bluetooth.adapters)) { // qmllint disable unresolved-type
            for (const device of root.asArray(adapter.devices)) {
                if (root.deviceId(adapter, device) === deviceId)
                    return device;
            }
        }
        return null;
    }
    function forgetDevice(deviceId: string): var {
        return root.deviceAction("forget", deviceId, device => device.forget());
    }
    function nextTaskId(kind: string): string {
        state.nextTask += 1;
        return "bluetooth-native-" + kind + "-" + state.nextTask;
    }
    function pairDevice(deviceId: string): var {
        return root.deviceAction("pair", deviceId, device => device.pair());
    }
    function requestRefresh() {
        if (!root.connected)
            return;
        state.sequence += 1;
        root.stateChanged();
    }
    function respondPairing(requestId: string, accepted: bool, code: string): var {
        void requestId;
        void accepted;
        void code;
        return root.result(false, "", "BLUETOOTH_PAIRING_AGENT_UNAVAILABLE");
    }
    function result(accepted: bool, taskId: string, errorCode: string): var {
        return Object.freeze({
            "accepted": accepted,
            "taskId": taskId,
            "errorCode": errorCode
        });
    }
    function scheduleChanged() {
        modelChanged.restart();
    }
    function setDiscovery(adapterId: string, active: bool): var {
        if (!root.connected)
            return root.result(false, "", "BLUETOOTH_BACKEND_DISCONNECTED");
        const adapter = root.findAdapter(adapterId);
        if (adapter === null)
            return root.result(false, "", "BLUETOOTH_ADAPTER_UNAVAILABLE");
        const taskId = root.nextTaskId("discovery");
        try {
            adapter.discovering = active;
            root.scheduleChanged();
            return root.result(true, taskId, "");
        } catch (error) {
            return root.result(false, "", "BLUETOOTH_DISCOVERY_FAILED");
        }
    }
    function setPowered(adapterId: string, enabled: bool): var {
        if (!root.connected)
            return root.result(false, "", "BLUETOOTH_BACKEND_DISCONNECTED");
        const adapter = root.findAdapter(adapterId);
        if (adapter === null)
            return root.result(false, "", "BLUETOOTH_ADAPTER_UNAVAILABLE");
        if (root.adapterStateName(adapter.state) === "blocked" && enabled)
            return root.result(false, "", "BLUETOOTH_ADAPTER_BLOCKED");
        const taskId = root.nextTaskId("power");
        try {
            adapter.enabled = enabled;
            root.scheduleChanged();
            return root.result(true, taskId, "");
        } catch (error) {
            return root.result(false, "", "BLUETOOTH_POWER_WRITE_FAILED");
        }
    }
    function snapshot(): var {
        const adapters = [];
        const defaultAdapter = Bluetooth.defaultAdapter; // qmllint disable unresolved-type
        for (const adapter of root.asArray(Bluetooth.adapters) // qmllint disable unresolved-type
        )
            adapters.push(root.adapterRecord(adapter, defaultAdapter));
        return Object.freeze({
            "sequence": state.sequence,
            "adapters": Object.freeze(adapters)
        });
    }

    Component.onCompleted: {
        root.connectionChanged(root.connected);
        if (root.connected)
            Qt.callLater(root.requestRefresh);
    }
    onConnectedChanged: {
        root.connectionChanged(root.connected);
        if (root.connected)
            Qt.callLater(root.requestRefresh);
    }

    QtObject {
        id: state

        property int nextTask: 0
        property var pendingDeviceTasks: ({})
        property int sequence: 0
    }
    Timer {
        id: modelChanged

        interval: 0

        onTriggered: root.requestRefresh()
    }
    Connections {
        function onDefaultAdapterChanged() {
            root.scheduleChanged();
        }

        target: Bluetooth
    }
    Connections {
        function onValuesChanged() {
            root.scheduleChanged();
        }

        target: Bluetooth.adapters // qmllint disable unresolved-type
    }
    Instantiator {
        model: Bluetooth.adapters // qmllint disable unresolved-type

        delegate: Scope {
            id: adapterObserver

            required property var modelData

            Connections {
                function onDiscoveringChanged() {
                    root.scheduleChanged();
                }
                function onEnabledChanged() {
                    root.scheduleChanged();
                }
                function onNameChanged() {
                    root.scheduleChanged();
                }
                function onStateChanged() {
                    root.scheduleChanged();
                }

                ignoreUnknownSignals: true
                target: adapterObserver.modelData
            }
            Connections {
                function onValuesChanged() {
                    root.scheduleChanged();
                }

                target: adapterObserver.modelData.devices
            }
            Instantiator {
                model: adapterObserver.modelData.devices

                delegate: Scope {
                    id: deviceObserver

                    required property var modelData

                    Connections {
                        function onBatteryAvailableChanged() {
                            root.scheduleChanged();
                        }
                        function onBatteryChanged() {
                            root.scheduleChanged();
                        }
                        function onConnectedChanged() {
                            root.scheduleChanged();
                            Qt.callLater(() => root.evaluateDeviceTask(deviceObserver.modelData));
                        }
                        function onNameChanged() {
                            root.scheduleChanged();
                        }
                        function onPairedChanged() {
                            root.scheduleChanged();
                            Qt.callLater(() => root.evaluateDeviceTask(deviceObserver.modelData));
                        }
                        function onPairingChanged() {
                            root.scheduleChanged();
                            Qt.callLater(() => root.evaluateDeviceTask(deviceObserver.modelData));
                        }
                        function onStateChanged() {
                            root.scheduleChanged();
                            Qt.callLater(() => root.evaluateDeviceTask(deviceObserver.modelData));
                        }

                        ignoreUnknownSignals: true
                        target: deviceObserver.modelData
                    }
                }
            }
        }
    }
}
