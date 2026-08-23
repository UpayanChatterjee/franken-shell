import QtQuick
import Quickshell

Scope {
    id: root

    readonly property var activeAdapter: root.adapter?.activeAdapter ?? null
    required property var adapter
    readonly property string audioRoutingOwner: "audioAdapter"
    readonly property bool available: root.adapter?.available === true
    readonly property var availableDevices: root.adapter?.availableDevices ?? Object.freeze([])
    readonly property var connectedDevices: root.adapter?.connectedDevices ?? Object.freeze([])
    property bool detailVisible: false
    readonly property var devices: root.adapter?.devices ?? Object.freeze([])
    readonly property string discoveryState: root.adapter?.discoveryState ?? "idle"
    readonly property string lastError: root.adapter?.lastError ?? ""
    readonly property var nonAudioConnectedDevices: root.adapter?.nonAudioConnectedDevices ?? Object.freeze([])
    readonly property var operationTasks: root.adapter?.operationTasks ?? Object.freeze([])
    readonly property var pairedDevices: root.adapter?.pairedDevices ?? Object.freeze([])
    readonly property var pairingRequest: root.adapter?.pairingRequest ?? Object.freeze({
        "active": false
    })
    readonly property bool powered: root.adapter?.powered === true
    readonly property string quickSummary: root.summaryText()
    readonly property string status: root.adapter?.status ?? "unavailable"

    function cancelPairingPrompt(): var {
        if (!root.pairingRequest.active)
            return root.result(false, "BLUETOOTH_PAIRING_REQUEST_UNAVAILABLE");
        return root.cancelTask(root.pairingRequest.taskId);
    }
    function cancelTask(taskId: string): var {
        return root.adapter.cancelTask(taskId);
    }
    function confirmPairing(accepted: bool): var {
        return root.adapter.confirmPairing(accepted);
    }
    function connectDevice(deviceId: string): var {
        return root.adapter.connectDevice(deviceId);
    }
    function disconnectDevice(deviceId: string): var {
        return root.adapter.disconnectDevice(deviceId);
    }
    function forgetDevice(deviceId: string): var {
        return root.adapter.forgetDevice(deviceId);
    }
    function pairDevice(deviceId: string): var {
        return root.adapter.pairDevice(deviceId);
    }
    function result(accepted: bool, errorCode: string): var {
        return Object.freeze({
            "accepted": accepted,
            "errorCode": errorCode
        });
    }
    function startDiscovery(): var {
        return root.adapter.startDiscovery();
    }
    function stopDiscovery(): var {
        return root.adapter.stopDiscovery();
    }
    function submitPairingCode(code: string): var {
        return root.adapter.submitPairingCode(code);
    }
    function summaryText(): string {
        if (!root.available)
            return qsTr("Unavailable");
        if (!root.powered)
            return qsTr("Off");
        if (root.status === "awaitingConfirmation" || root.status === "awaitingCode")
            return qsTr("Pairing needs attention");
        if (root.status === "pairing")
            return qsTr("Pairing…");
        if (root.status === "connecting")
            return qsTr("Connecting…");
        if (root.nonAudioConnectedDevices.length === 1)
            return root.nonAudioConnectedDevices[0].name;
        if (root.nonAudioConnectedDevices.length > 1)
            return qsTr("%1 devices connected").arg(root.nonAudioConnectedDevices.length);
        if (root.discoveryState === "discovering")
            return qsTr("Discovering…");
        if (root.lastError.length > 0)
            return qsTr("Needs attention");
        return qsTr("On");
    }
    function togglePowered(): var {
        return root.adapter.setPowered(!root.powered);
    }

    Component.onCompleted: root.adapter.setDetailActive(root.detailVisible)
    onAvailableChanged: {
        if (root.available && root.detailVisible)
            root.adapter.setDetailActive(true);
    }
    onDetailVisibleChanged: root.adapter.setDetailActive(root.detailVisible)
    onPoweredChanged: {
        if (root.powered && root.detailVisible)
            root.adapter.setDetailActive(true);
    }
}
