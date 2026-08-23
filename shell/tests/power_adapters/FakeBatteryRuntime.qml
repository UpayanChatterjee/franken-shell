import QtQuick
import Quickshell

Scope {
    id: root

    property var batteryRecord: null
    property bool connected: false
    property int refreshCount: 0
    property int sequence: 1

    signal connectionChanged(bool connected)
    signal stateChanged

    function requestRefresh() {
        root.refreshCount += 1;
        root.stateChanged();
    }
    function setConnected(value: bool) {
        if (root.connected === value)
            return;
        root.connected = value;
        root.connectionChanged(value);
    }
    function snapshot(): var {
        return Object.freeze({
            "sequence": root.sequence,
            "battery": root.batteryRecord
        });
    }
}
