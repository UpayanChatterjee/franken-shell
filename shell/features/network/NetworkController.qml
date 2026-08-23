import QtQuick
import Quickshell

Scope {
    id: root

    readonly property var activeConnection: root.adapter?.activeConnection ?? null
    required property var adapter
    readonly property bool available: root.adapter?.available === true
    readonly property string connectivity: root.adapter?.connectivity ?? "unknown"
    readonly property var credentialRequest: state.credentialRequest
    property bool detailVisible: false
    readonly property var ethernetDevices: root.adapter?.ethernetDevices ?? Object.freeze([])
    readonly property string lastError: root.adapter?.lastError ?? ""
    readonly property var operationTasks: root.adapter?.operationTasks ?? Object.freeze([])
    readonly property string quickSummary: root.summaryText()
    readonly property var savedNetworks: root.adapter?.savedNetworks ?? Object.freeze([])
    readonly property string scanState: root.adapter?.scanState ?? "idle"
    readonly property string status: root.adapter?.status ?? "unavailable"
    readonly property var visibleNetworks: root.adapter?.visibleNetworks ?? Object.freeze([])
    readonly property bool wifiEnabled: root.adapter?.wifiEnabled === true
    readonly property bool wifiHardwareAvailable: root.adapter?.wifiHardwareAvailable === true

    function cancelCredential() {
        state.credentialRequest = root.emptyCredentialRequest();
    }
    function cancelTask(taskId: string): var {
        return root.adapter.cancelTask(taskId);
    }
    function connectNetwork(networkId: string): var {
        const network = root.findNetwork(networkId);
        if (network === null)
            return root.result(false, false, "NETWORK_NETWORK_UNAVAILABLE");
        if (network.connected)
            return root.result(false, false, "NETWORK_ALREADY_CONNECTED");
        if (network.known || network.security === "open" || network.security === "owe") {
            const response = root.adapter.connectNetwork(network.id, "");
            return root.result(response.accepted, false, response.errorCode);
        }
        if (["wpaPsk", "wpa2Psk", "sae"].indexOf(network.security) >= 0) {
            state.credentialRequest = Object.freeze({
                "active": true,
                "networkId": network.id,
                "networkName": network.name,
                "security": network.security
            });
            return root.result(true, true, "");
        }
        return root.result(false, false, "NETWORK_SECURITY_UNSUPPORTED");
    }
    function disconnectNetwork(networkId: string): var {
        return root.adapter.disconnectNetwork(networkId);
    }
    function emptyCredentialRequest(): var {
        return Object.freeze({
            "active": false,
            "networkId": "",
            "networkName": "",
            "security": "unknown"
        });
    }
    function findNetwork(networkId: string): var {
        for (const network of root.visibleNetworks.concat(root.savedNetworks)) {
            if (network.id === networkId)
                return network;
        }
        return null;
    }
    function forgetNetwork(networkId: string): var {
        return root.adapter.forgetNetwork(networkId);
    }
    function requestScan(): var {
        return root.adapter.requestScan();
    }
    function result(accepted: bool, promptRequired: bool, errorCode: string): var {
        return Object.freeze({
            "accepted": accepted,
            "promptRequired": promptRequired,
            "errorCode": errorCode
        });
    }
    function submitCredential(credential: string): var {
        const request = state.credentialRequest;
        if (!request.active)
            return root.result(false, false, "NETWORK_CREDENTIAL_REQUEST_UNAVAILABLE");
        if (credential.length === 0)
            return root.result(false, true, "NETWORK_CREDENTIAL_EMPTY");
        state.credentialRequest = root.emptyCredentialRequest();
        const response = root.adapter.connectNetwork(request.networkId, credential);
        return root.result(response.accepted, false, response.errorCode);
    }
    function summaryText(): string {
        if (!root.available)
            return qsTr("Unavailable");
        if (!root.wifiHardwareAvailable)
            return qsTr("No Wi-Fi hardware");
        if (!root.wifiEnabled)
            return qsTr("Off");
        if (root.status === "connecting")
            return qsTr("Connecting…");
        if (root.status === "captive")
            return qsTr("Login required");
        if (root.status === "limited")
            return qsTr("Limited connectivity");
        if (root.activeConnection !== null)
            return root.activeConnection.name.length > 0 ? root.activeConnection.name : qsTr("Connected");
        if (root.scanState === "scanning")
            return qsTr("Scanning…");
        if (root.lastError.length > 0)
            return qsTr("Needs attention");
        return qsTr("Not connected");
    }
    function toggleWifi(): var {
        return root.adapter.setWifiEnabled(!root.wifiEnabled);
    }

    onDetailVisibleChanged: {
        root.adapter.setDetailActive(root.detailVisible);
        if (!root.detailVisible)
            root.cancelCredential();
    }

    QtObject {
        id: state

        property var credentialRequest: root.emptyCredentialRequest()
    }
}
