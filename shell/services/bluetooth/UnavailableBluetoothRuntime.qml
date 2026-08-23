import QtQuick
import Quickshell

Scope {
    id: root

    readonly property bool connected: false

    signal actionFailed(string taskId, string errorCode)
    signal connectionChanged(bool connected)
    signal pairingRequested(string taskId, string requestId, string deviceId, string kind, string displayCode)
    signal stateChanged

    function cancelAction(taskId: string, kind: string, targetId: string): var {
        void taskId;
        void kind;
        void targetId;
        return root.result();
    }
    function connectDevice(deviceId: string): var {
        void deviceId;
        return root.result();
    }
    function disconnectDevice(deviceId: string): var {
        void deviceId;
        return root.result();
    }
    function forgetDevice(deviceId: string): var {
        void deviceId;
        return root.result();
    }
    function pairDevice(deviceId: string): var {
        void deviceId;
        return root.result();
    }
    function requestRefresh() {
    }
    function respondPairing(requestId: string, accepted: bool, code: string): var {
        void requestId;
        void accepted;
        void code;
        return root.result();
    }
    function result(): var {
        return Object.freeze({
            "accepted": false,
            "taskId": "",
            "errorCode": "BLUETOOTH_BACKEND_DISCONNECTED"
        });
    }
    function setDiscovery(adapterId: string, active: bool): var {
        void adapterId;
        void active;
        return root.result();
    }
    function setPowered(adapterId: string, enabled: bool): var {
        void adapterId;
        void enabled;
        return root.result();
    }
    function snapshot(): var {
        return Object.freeze({
            "sequence": 0,
            "adapters": Object.freeze([])
        });
    }
}
