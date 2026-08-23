import QtQuick
import Quickshell

Scope {
    id: root

    readonly property bool connected: false

    signal actionFailed(string taskId, string errorCode)
    signal connectionChanged(bool connected)
    signal stateChanged

    function cancelAction(taskId: string, kind: string, targetId: string): var {
        void taskId;
        void kind;
        void targetId;
        return root.result(false, "NETWORK_BACKEND_DISCONNECTED");
    }
    function connectNetwork(networkId: string, credential: string): var {
        void networkId;
        void credential;
        return root.result(false, "NETWORK_BACKEND_DISCONNECTED");
    }
    function disconnectNetwork(networkId: string): var {
        void networkId;
        return root.result(false, "NETWORK_BACKEND_DISCONNECTED");
    }
    function forgetNetwork(networkId: string): var {
        void networkId;
        return root.result(false, "NETWORK_BACKEND_DISCONNECTED");
    }
    function requestRefresh() {
    }
    function requestScan(): var {
        return root.result(false, "NETWORK_BACKEND_DISCONNECTED");
    }
    function result(accepted: bool, errorCode: string): var {
        return Object.freeze({
            "accepted": accepted,
            "taskId": "",
            "errorCode": errorCode
        });
    }
    function setScanning(active: bool) {
        void active;
    }
    function setWifiEnabled(enabled: bool): var {
        void enabled;
        return root.result(false, "NETWORK_BACKEND_DISCONNECTED");
    }
    function snapshot(): var {
        return Object.freeze({
            "sequence": 0,
            "wifiEnabled": false,
            "wifiHardwareAvailable": false,
            "connectivity": "unknown",
            "scanning": false,
            "devices": Object.freeze([])
        });
    }
}
