import QtQuick
import Quickshell

Scope {
    id: root

    property var adapters: []
    property bool connected: false
    property string failNextError: ""
    readonly property string lastAction: state.lastAction
    readonly property int lastPairingCodeLength: state.lastPairingCodeLength
    property int sequence: 1

    signal actionFailed(string taskId, string errorCode)
    signal connectionChanged(bool connected)
    signal pairingRequested(string taskId, string requestId, string deviceId, string kind, string displayCode)
    signal stateChanged

    function action(kind: string, targetId: string): var {
        state.lastAction = kind + ":" + targetId;
        if (!root.connected)
            return root.result(false, "", "BLUETOOTH_BACKEND_DISCONNECTED");
        if (root.failNextError.length > 0) {
            const errorCode = root.failNextError;
            root.failNextError = "";
            return root.result(false, "", errorCode);
        }
        state.nextTask += 1;
        state.lastTaskId = "bluetooth-fixture-" + state.nextTask;
        return root.result(true, state.lastTaskId, "");
    }
    function cancelAction(taskId: string, kind: string, targetId: string): var {
        void taskId;
        return root.action("cancel-" + kind, targetId);
    }
    function connectDevice(deviceId: string): var {
        return root.action("connect", deviceId);
    }
    function disconnectDevice(deviceId: string): var {
        return root.action("disconnect", deviceId);
    }
    function failLast(errorCode: string) {
        root.actionFailed(state.lastTaskId, errorCode);
    }
    function forgetDevice(deviceId: string): var {
        return root.action("forget", deviceId);
    }
    function lastTargetId(): string {
        const separator = state.lastAction.indexOf(":");
        return separator < 0 ? "" : state.lastAction.slice(separator + 1);
    }
    function pairDevice(deviceId: string): var {
        return root.action("pair", deviceId);
    }
    function requestPairing(kind: string, displayCode: string) {
        state.nextRequest += 1;
        state.lastRequestId = "pairing-request-" + state.nextRequest;
        root.pairingRequested(state.lastTaskId, state.lastRequestId, root.lastTargetId(), kind, displayCode);
    }
    function requestRefresh() {
        root.stateChanged();
    }
    function respondPairing(requestId: string, accepted: bool, code: string): var {
        state.lastPairingCodeLength = code.length;
        return root.action(accepted ? "pairing-accept" : "pairing-reject", requestId);
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
    function setDiscovery(adapterId: string, active: bool): var {
        return root.action(active ? "discover-start" : "discover-stop", adapterId);
    }
    function setPowered(adapterId: string, enabled: bool): var {
        return root.action(enabled ? "power-on" : "power-off", adapterId);
    }
    function snapshot(): var {
        return Object.freeze({
            "sequence": root.sequence,
            "adapters": Object.freeze(Array.from(root.adapters))
        });
    }

    QtObject {
        id: state

        property string lastAction: ""
        property int lastPairingCodeLength: 0
        property string lastRequestId: ""
        property string lastTaskId: ""
        property int nextRequest: 0
        property int nextTask: 0
    }
}
