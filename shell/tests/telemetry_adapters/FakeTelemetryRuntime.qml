import QtQuick
import Quickshell

Scope {
    id: root

    property bool connected: false
    property string cpuText: ""
    property bool detailActive: false
    property var errors: Object.freeze({})
    property string memoryText: ""
    property string networkText: ""
    property int pollIntervalMs: root.detailActive ? 1000 : 2000
    property int refreshCount: 0
    property int sequence: 0
    property string storageText: ""
    property double timestampMs: 0

    signal connectionChanged(bool connected)
    signal stateChanged

    function publish(timestamp, network, memory, cpu, storage, sampleErrors = {}) {
        root.timestampMs = timestamp;
        root.networkText = network;
        root.memoryText = memory;
        root.cpuText = cpu;
        root.storageText = storage;
        root.errors = Object.freeze(sampleErrors);
        root.sequence += 1;
        root.stateChanged();
    }
    function requestRefresh() {
        root.refreshCount += 1;
    }
    function setConnected(value: bool) {
        if (root.connected === value)
            return;
        root.connected = value;
        root.connectionChanged(value);
    }
    function setDetailVisible(value: bool) {
        root.detailActive = value;
    }
    function snapshot(): var {
        return Object.freeze({
            "sequence": root.sequence,
            "timestampMs": root.timestampMs,
            "networkText": root.networkText,
            "memoryText": root.memoryText,
            "cpuText": root.cpuText,
            "storageText": root.storageText,
            "errors": root.errors,
            "pollIntervalMs": root.pollIntervalMs,
            "detailActive": root.detailActive
        });
    }
}
