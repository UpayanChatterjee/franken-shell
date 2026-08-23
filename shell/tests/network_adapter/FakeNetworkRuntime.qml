import QtQuick
import Quickshell

Scope {
    id: root

    readonly property int actionCount: state.actionCount
    property bool connected: false
    property string connectivity: "unknown"
    property var devices: []
    property string failNextError: ""
    readonly property string lastAction: state.lastAction
    readonly property int lastCredentialLength: state.lastCredentialLength
    property bool scanning: false
    property int sequence: 1
    property bool wifiEnabled: false
    property bool wifiHardwareAvailable: false

    signal actionFailed(string taskId, string errorCode)
    signal connectionChanged(bool connected)
    signal stateChanged

    function action(kind: string, targetId: string, credentialLength: int): var {
        state.actionCount += 1;
        state.lastAction = kind + ":" + targetId;
        state.lastCredentialLength = credentialLength;
        if (!root.connected)
            return root.result(false, "", "NETWORK_BACKEND_DISCONNECTED");
        if (root.failNextError.length > 0) {
            const errorCode = root.failNextError;
            root.failNextError = "";
            return root.result(false, "", errorCode);
        }
        state.nextTask += 1;
        const taskId = "network-fixture-" + state.nextTask;
        state.lastTaskId = taskId;
        return root.result(true, taskId, "");
    }
    function cancelAction(taskId: string, kind: string, targetId: string): var {
        void taskId;
        return root.action("cancel-" + kind, targetId, 0);
    }
    function connectNetwork(networkId: string, credential: string): var {
        return root.action("connect", networkId, credential.length);
    }
    function disconnectNetwork(networkId: string): var {
        return root.action("disconnect", networkId, 0);
    }
    function failLast(errorCode: string) {
        root.actionFailed(state.lastTaskId, errorCode);
    }
    function forgetNetwork(networkId: string): var {
        return root.action("forget", networkId, 0);
    }
    function requestRefresh() {
        root.stateChanged();
    }
    function requestScan(): var {
        const response = root.action("scan", "wifi", 0);
        if (response.accepted) {
            root.scanning = true;
            root.sequence += 1;
            root.stateChanged();
        }
        return response;
    }
    function result(accepted: bool, taskId: string, errorCode: string): var {
        return Object.freeze({
            "accepted": accepted,
            "taskId": taskId,
            "errorCode": errorCode
        });
    }
    function setConnected(value: bool) {
        if (root.connected === value)
            return;
        root.connected = value;
        root.connectionChanged(value);
    }
    function setScanning(active: bool) {
        root.scanning = active;
        root.sequence += 1;
        root.stateChanged();
    }
    function setWifiEnabled(enabled: bool): var {
        return root.action("wifi", enabled ? "on" : "off", 0);
    }
    function snapshot(): var {
        return Object.freeze({
            "sequence": root.sequence,
            "wifiEnabled": root.wifiEnabled,
            "wifiHardwareAvailable": root.wifiHardwareAvailable,
            "connectivity": root.connectivity,
            "scanning": root.scanning,
            "devices": Object.freeze(Array.from(root.devices))
        });
    }

    QtObject {
        id: state

        property int actionCount: 0
        property string lastAction: ""
        property int lastCredentialLength: 0
        property string lastTaskId: ""
        property int nextTask: 0
    }
}
