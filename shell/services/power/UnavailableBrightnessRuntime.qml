import QtQuick
import Quickshell

Scope {
    readonly property bool connected: false

    signal actionFinished(string taskId, bool accepted, string errorCode)
    signal connectionChanged(bool connected)
    signal stateChanged

    function requestRefresh() {
    }
    function setBrightness(targetId: string, rawValue: int): var {
        void targetId;
        void rawValue;
        return Object.freeze({
            "accepted": false,
            "taskId": "",
            "errorCode": "BRIGHTNESS_DISCONNECTED"
        });
    }
    function setConsumerActive(active: bool) {
        void active;
    }
    function snapshot(): var {
        return Object.freeze({
            "sequence": 0,
            "targets": Object.freeze([])
        });
    }
}
