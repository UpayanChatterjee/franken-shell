pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Networking

Scope {
    id: root

    readonly property bool connected: Networking.backend === NetworkBackendType.NetworkManager

    signal actionFailed(string taskId, string errorCode)
    signal connectionChanged(bool connected)
    signal stateChanged

    function asArray(value): var {
        if (Array.isArray(value))
            return value;
        if (value?.values !== undefined)
            return value.values;
        if (typeof value?.toArray === "function")
            return value.toArray();
        return [];
    }
    function cancelAction(taskId: string, kind: string, targetId: string): var {
        if (!root.connected)
            return root.result(false, "", "NETWORK_BACKEND_DISCONNECTED");
        if (kind === "scan") {
            root.setScanning(false);
            return root.result(true, taskId, "");
        }
        if (kind === "connect" || kind === "disconnect") {
            const network = root.findNetwork(targetId);
            if (network === null)
                return root.result(false, "", "NETWORK_NETWORK_UNAVAILABLE");
            try {
                network.device.disconnect();
                delete state.pendingNetworkTasks[targetId];
                return root.result(true, taskId, "");
            } catch (error) {
                return root.result(false, "", "NETWORK_CANCEL_FAILED");
            }
        }
        return root.result(false, "", "NETWORK_TASK_NOT_CANCELLABLE");
    }
    function connectNetwork(networkId: string, credential: string): var {
        if (!root.connected)
            return root.result(false, "", "NETWORK_BACKEND_DISCONNECTED");
        const network = root.findNetwork(networkId);
        if (network === null)
            return root.result(false, "", "NETWORK_NETWORK_UNAVAILABLE");
        const taskId = root.nextTaskId("connect");
        state.pendingNetworkTasks[networkId] = taskId;
        try {
            if (credential.length > 0)
                network.connectWithPsk(credential);
            else
                network.connect();
            return root.result(true, taskId, "");
        } catch (error) {
            delete state.pendingNetworkTasks[networkId];
            return root.result(false, "", "NETWORK_CONNECT_FAILED");
        }
    }
    function connectivityName(value): string {
        switch (value) {
        case NetworkConnectivity.None:
            return "offline";
        case NetworkConnectivity.Portal:
            return "captive";
        case NetworkConnectivity.Limited:
            return "limited";
        case NetworkConnectivity.Full:
            return "internet";
        default:
            return "unknown";
        }
    }
    function deviceId(device): string {
        return root.deviceTypeName(device.type) + ":" + String(device.name ?? "") + ":" + String(device.address ?? "");
    }
    function deviceRecord(device): var {
        const networks = [];
        if (device.type === DeviceType.Wifi) {
            for (const network of root.asArray(device.networks))
                networks.push(root.networkRecord(device, network, true));
        } else if (device.type === DeviceType.Wired && device.network !== null) {
            networks.push(root.networkRecord(device, device.network, device.hasLink === true));
        }
        return Object.freeze({
            "id": root.deviceId(device),
            "name": String(device.name ?? ""),
            "address": String(device.address ?? ""),
            "type": root.deviceTypeName(device.type),
            "state": root.stateName(device.state),
            "connected": device.connected === true,
            "hasLink": device.type === DeviceType.Wired && device.hasLink === true,
            "linkSpeedMbps": device.type === DeviceType.Wired ? Number(device.linkSpeed ?? 0) : 0,
            "networks": Object.freeze(networks)
        });
    }
    function deviceTypeName(value): string {
        if (value === DeviceType.Wifi)
            return "wifi";
        if (value === DeviceType.Wired)
            return "ethernet";
        return "unknown";
    }
    function disconnectNetwork(networkId: string): var {
        if (!root.connected)
            return root.result(false, "", "NETWORK_BACKEND_DISCONNECTED");
        const network = root.findNetwork(networkId);
        if (network === null)
            return root.result(false, "", "NETWORK_NETWORK_UNAVAILABLE");
        const taskId = root.nextTaskId("disconnect");
        state.pendingNetworkTasks[networkId] = taskId;
        try {
            network.disconnect();
            return root.result(true, taskId, "");
        } catch (error) {
            delete state.pendingNetworkTasks[networkId];
            return root.result(false, "", "NETWORK_DISCONNECT_FAILED");
        }
    }
    function failureCode(reason): string {
        switch (reason) {
        case ConnectionFailReason.NoSecrets:
            return "NETWORK_CREDENTIALS_REQUIRED";
        case ConnectionFailReason.WifiAuthTimeout:
            return "NETWORK_AUTHENTICATION_TIMEOUT";
        case ConnectionFailReason.WifiNetworkLost:
            return "NETWORK_NETWORK_LOST";
        case ConnectionFailReason.WifiClientDisconnected:
            return "NETWORK_CLIENT_DISCONNECTED";
        case ConnectionFailReason.WifiClientFailed:
            return "NETWORK_CLIENT_FAILED";
        default:
            return "NETWORK_CONNECT_FAILED";
        }
    }
    function findNetwork(networkId: string): var {
        for (const device of root.asArray(Networking.devices)) {
            if (device.type === DeviceType.Wifi) {
                for (const network of root.asArray(device.networks)) {
                    if (root.networkId(device, network) === networkId)
                        return network;
                }
            } else if (device.type === DeviceType.Wired && device.network !== null && root.networkId(device, device.network) === networkId) {
                return device.network;
            }
        }
        return null;
    }
    function forgetNetwork(networkId: string): var {
        if (!root.connected)
            return root.result(false, "", "NETWORK_BACKEND_DISCONNECTED");
        const network = root.findNetwork(networkId);
        if (network === null)
            return root.result(false, "", "NETWORK_NETWORK_UNAVAILABLE");
        const taskId = root.nextTaskId("forget");
        state.pendingNetworkTasks[networkId] = taskId;
        try {
            network.forget();
            return root.result(true, taskId, "");
        } catch (error) {
            delete state.pendingNetworkTasks[networkId];
            return root.result(false, "", "NETWORK_FORGET_FAILED");
        }
    }
    function handleNetworkFailure(device, network, reason) {
        const id = root.networkId(device, network);
        const taskId = String(state.pendingNetworkTasks[id] ?? "");
        if (taskId.length === 0)
            return;
        delete state.pendingNetworkTasks[id];
        root.actionFailed(taskId, root.failureCode(reason));
    }
    function networkId(device, network): string {
        return root.deviceId(device) + ":network:" + String(network.name ?? "");
    }
    function networkRecord(device, network, visible: bool): var {
        return Object.freeze({
            "id": root.networkId(device, network),
            "name": String(network.name ?? device.name ?? ""),
            "signalStrength": device.type === DeviceType.Wifi ? Number(network.signalStrength ?? 0) : 1,
            "security": device.type === DeviceType.Wifi ? root.securityName(network.security) : "wired",
            "known": network.known === true,
            "connected": network.connected === true,
            "visible": visible || network.known === true || network.connected === true,
            "state": root.stateName(network.state)
        });
    }
    function nextTaskId(kind: string): string {
        state.nextTask += 1;
        return "network-native-" + kind + "-" + state.nextTask;
    }
    function requestRefresh() {
        if (!root.connected)
            return;
        state.sequence += 1;
        root.stateChanged();
    }
    function requestScan(): var {
        if (!root.connected)
            return root.result(false, "", "NETWORK_BACKEND_DISCONNECTED");
        const taskId = root.nextTaskId("scan");
        try {
            root.setScanning(true);
            return root.result(true, taskId, "");
        } catch (error) {
            return root.result(false, "", "NETWORK_SCAN_FAILED");
        }
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
    function securityName(value): string {
        switch (value) {
        case WifiSecurityType.Open:
            return "open";
        case WifiSecurityType.WpaPsk:
            return "wpaPsk";
        case WifiSecurityType.Wpa2Psk:
            return "wpa2Psk";
        case WifiSecurityType.Sae:
            return "sae";
        case WifiSecurityType.Owe:
            return "owe";
        case WifiSecurityType.WpaEap:
            return "wpaEap";
        case WifiSecurityType.Wpa2Eap:
            return "wpa2Eap";
        case WifiSecurityType.StaticWep:
            return "staticWep";
        case WifiSecurityType.DynamicWep:
            return "dynamicWep";
        case WifiSecurityType.Leap:
            return "leap";
        default:
            return "unknown";
        }
    }
    function setScanning(active: bool) {
        if (!root.connected)
            return;
        for (const device of root.asArray(Networking.devices)) {
            if (device.type === DeviceType.Wifi)
                device.scannerEnabled = active;
        }
        root.scheduleChanged();
    }
    function setWifiEnabled(enabled: bool): var {
        if (!root.connected)
            return root.result(false, "", "NETWORK_BACKEND_DISCONNECTED");
        const taskId = root.nextTaskId("wifi");
        try {
            Networking.wifiEnabled = enabled;
            root.scheduleChanged();
            return root.result(true, taskId, "");
        } catch (error) {
            return root.result(false, "", "NETWORK_WIFI_WRITE_FAILED");
        }
    }
    function snapshot(): var {
        const devices = [];
        let scanning = false;
        for (const device of root.asArray(Networking.devices)) {
            devices.push(root.deviceRecord(device));
            if (device.type === DeviceType.Wifi && device.scannerEnabled === true)
                scanning = true;
        }
        return Object.freeze({
            "sequence": state.sequence,
            "wifiEnabled": Networking.wifiEnabled === true,
            "wifiHardwareAvailable": Networking.wifiHardwareEnabled === true,
            "connectivity": root.connectivityName(Networking.connectivity),
            "scanning": scanning,
            "devices": Object.freeze(devices)
        });
    }
    function stateName(value): string {
        switch (value) {
        case ConnectionState.Connecting:
            return "connecting";
        case ConnectionState.Connected:
            return "connected";
        case ConnectionState.Disconnecting:
            return "disconnecting";
        case ConnectionState.Disconnected:
            return "disconnected";
        default:
            return "unknown";
        }
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
        property var pendingNetworkTasks: ({})
        property int sequence: 0
    }
    Timer {
        id: modelChanged

        interval: 0

        onTriggered: root.requestRefresh()
    }
    Connections {
        function onConnectivityChanged() {
            root.scheduleChanged();
        }
        function onWifiEnabledChanged() {
            root.scheduleChanged();
        }
        function onWifiHardwareEnabledChanged() {
            root.scheduleChanged();
        }

        target: Networking
    }
    Connections {
        function onValuesChanged() {
            root.scheduleChanged();
        }

        target: Networking.devices
    }
    Instantiator {
        model: Networking.devices

        delegate: Scope {
            id: deviceObserver

            required property var modelData

            Connections {
                function onConnectedChanged() {
                    root.scheduleChanged();
                }
                function onNetworkChanged() {
                    root.scheduleChanged();
                }
                function onScannerEnabledChanged() {
                    root.scheduleChanged();
                }
                function onStateChanged() {
                    root.scheduleChanged();
                }

                ignoreUnknownSignals: true
                target: deviceObserver.modelData
            }
            Connections {
                function onValuesChanged() {
                    root.scheduleChanged();
                }

                target: deviceObserver.modelData.networks
            }
            Instantiator {
                model: deviceObserver.modelData.networks

                delegate: Scope {
                    id: networkObserver

                    required property var modelData

                    Connections {
                        function onConnectedChanged() {
                            root.scheduleChanged();
                        }
                        function onConnectionFailed(reason) {
                            root.handleNetworkFailure(deviceObserver.modelData, networkObserver.modelData, reason);
                        }
                        function onKnownChanged() {
                            root.scheduleChanged();
                        }
                        function onNameChanged() {
                            root.scheduleChanged();
                        }
                        function onSecurityChanged() {
                            root.scheduleChanged();
                        }
                        function onSignalStrengthChanged() {
                            root.scheduleChanged();
                        }
                        function onStateChanged() {
                            root.scheduleChanged();
                        }

                        ignoreUnknownSignals: true
                        target: networkObserver.modelData
                    }
                }
            }
        }
    }
}
