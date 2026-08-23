import QtQuick
import Quickshell
import "ResourceMath.js" as ResourceMath

Scope {
    id: root

    readonly property bool available: state.memory !== null && state.consecutiveFailures < root.maximumRetainedFailures
    readonly property string connectionState: !root.runtime?.connected ? (state.memory !== null ? "reconnecting" : "unavailable") : root.available ? (state.stale ? "degraded" : "ready") : "unavailable"
    readonly property real cpuPercent: state.cpuPercent
    readonly property string lastError: state.lastError
    property int maximumRetainedFailures: 2
    readonly property var memory: state.memory
    readonly property real memoryPercent: Number(state.memory?.percent ?? -1)
    required property var runtime
    readonly property bool stale: state.stale
    readonly property var storage: state.storage

    signal stateChanged

    function diagnosticsSummary(): var {
        return Object.freeze({
            "available": root.available,
            "connectionState": root.connectionState,
            "stale": root.stale,
            "memoryPercent": root.memoryPercent,
            "cpuPercent": root.cpuPercent,
            "storageAvailable": root.storage !== null,
            "pollIntervalMs": Number(root.runtime?.pollIntervalMs ?? 0),
            "detailActive": root.runtime?.detailActive === true,
            "lastError": root.lastError
        });
    }
    function handleConnectionChanged(connected: bool) {
        if (!connected) {
            state.stale = state.memory !== null;
            state.lastError = "RESOURCE_DISCONNECTED";
            root.stateChanged();
            return;
        }
        root.runtime.requestRefresh();
    }
    function reconcile() {
        if (!root.runtime?.connected)
            return;
        const snapshot = root.runtime.snapshot();
        const sequence = Number(snapshot?.sequence ?? 0);
        if (sequence <= state.lastSequence)
            return;
        state.lastSequence = sequence;
        const memory = ResourceMath.parseMemory(snapshot?.memoryText ?? "");
        if (memory === null || String(snapshot?.errors?.memory ?? "").length > 0) {
            state.consecutiveFailures += 1;
            state.lastError = String(snapshot?.errors?.memory ?? "MEMORY_UNAVAILABLE");
            state.stale = state.memory !== null;
            root.stateChanged();
            return;
        }
        const cpu = ResourceMath.parseCpu(snapshot?.cpuText ?? "");
        state.cpuPercent = ResourceMath.cpuPercent(state.previousCpu, cpu);
        if (cpu !== null)
            state.previousCpu = cpu;
        state.storage = String(snapshot?.errors?.storage ?? "").length === 0 ? ResourceMath.parseStorage(snapshot?.storageText ?? "") : null;
        state.memory = memory;
        state.consecutiveFailures = 0;
        state.lastError = "";
        state.stale = false;
        root.stateChanged();
    }
    function setDetailVisible(value: bool) {
        if (typeof root.runtime?.setDetailVisible === "function")
            root.runtime.setDetailVisible(value);
    }

    Component.onCompleted: {
        if (root.runtime?.connected)
            root.runtime.requestRefresh();
    }
    onRuntimeChanged: root.handleConnectionChanged(root.runtime?.connected === true)

    QtObject {
        id: state

        property int consecutiveFailures: 0
        property real cpuPercent: -1
        property string lastError: ""
        property int lastSequence: -1
        property var memory: null
        property var previousCpu: null
        property bool stale: false
        property var storage: null
    }
    Connections {
        function onConnectionChanged(connected) {
            root.handleConnectionChanged(connected);
        }
        function onStateChanged() {
            root.reconcile();
        }

        ignoreUnknownSignals: true
        target: root.runtime
    }
}
