import QtQuick
import Quickshell

Scope {
    readonly property bool connected: false
    readonly property bool detailActive: false
    readonly property int pollIntervalMs: 0

    signal connectionChanged(bool connected)
    signal stateChanged

    function requestRefresh() {
    }
    function setDetailVisible(value: bool) {
    }
    function snapshot(): var {
        return Object.freeze({
            "sequence": 0,
            "timestampMs": 0,
            "networkText": "",
            "memoryText": "",
            "cpuText": "",
            "storageText": "",
            "errors": Object.freeze({
                "network": "TELEMETRY_UNAVAILABLE",
                "memory": "TELEMETRY_UNAVAILABLE",
                "cpu": "TELEMETRY_UNAVAILABLE",
                "storage": "TELEMETRY_UNAVAILABLE"
            }),
            "pollIntervalMs": 0,
            "detailActive": false
        });
    }
}
