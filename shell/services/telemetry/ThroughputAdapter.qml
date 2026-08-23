import QtQuick
import Quickshell
import "ThroughputMath.js" as ThroughputMath

Scope {
    id: root

    readonly property int activeInterfaceCount: state.activeInterfaceCount
    readonly property bool available: state.hasValue && state.consecutiveFailures < root.maximumRetainedFailures
    readonly property string connectionState: !root.runtime?.connected ? (state.hasValue ? "reconnecting" : "unavailable") : root.available ? (state.stale ? "degraded" : "ready") : "unavailable"
    readonly property string lastError: state.lastError
    property int maximumRetainedFailures: 2
    readonly property real rawDownloadRate: state.rawDownloadRate
    readonly property real rawUploadRate: state.rawUploadRate
    required property var runtime
    readonly property real smoothedDownloadRate: ThroughputMath.average(state.downloadHistory)
    readonly property real smoothedUploadRate: ThroughputMath.average(state.uploadHistory)
    property int smoothingWindow: 4
    readonly property bool stale: state.stale

    signal stateChanged

    function acceptFailure(errorCode: string) {
        state.consecutiveFailures += 1;
        state.lastError = errorCode;
        state.stale = state.hasValue;
        root.stateChanged();
    }
    function diagnosticsSummary(): var {
        return Object.freeze({
            "available": root.available,
            "connectionState": root.connectionState,
            "stale": root.stale,
            "activeInterfaceCount": root.activeInterfaceCount,
            "rawDownloadRate": root.rawDownloadRate,
            "rawUploadRate": root.rawUploadRate,
            "smoothedDownloadRate": root.smoothedDownloadRate,
            "smoothedUploadRate": root.smoothedUploadRate,
            "pollIntervalMs": Number(root.runtime?.pollIntervalMs ?? 0),
            "detailActive": root.runtime?.detailActive === true,
            "lastError": root.lastError
        });
    }
    function handleConnectionChanged(connected: bool) {
        if (!connected) {
            state.stale = state.hasValue;
            state.lastError = "THROUGHPUT_DISCONNECTED";
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
        const counters = ThroughputMath.parseNetworkCounters(snapshot?.networkText ?? "");
        const names = Object.keys(counters);
        if (String(snapshot?.errors?.network ?? "").length > 0 || names.length === 0) {
            root.acceptFailure(String(snapshot?.errors?.network ?? "NETWORK_COUNTERS_UNAVAILABLE"));
            return;
        }
        const timestamp = Number(snapshot?.timestampMs ?? 0);
        if (state.previousTimestamp > 0) {
            const sample = ThroughputMath.rates(state.previousCounters, counters, timestamp - state.previousTimestamp);
            state.rawDownloadRate = sample.download;
            state.rawUploadRate = sample.upload;
            state.downloadHistory = ThroughputMath.appendBounded(state.downloadHistory, sample.download, root.smoothingWindow);
            state.uploadHistory = ThroughputMath.appendBounded(state.uploadHistory, sample.upload, root.smoothingWindow);
        } else {
            state.downloadHistory = Object.freeze([0]);
            state.uploadHistory = Object.freeze([0]);
        }
        state.previousCounters = counters;
        state.previousTimestamp = timestamp;
        state.activeInterfaceCount = names.length;
        state.consecutiveFailures = 0;
        state.hasValue = true;
        state.lastError = "";
        state.stale = false;
        root.stateChanged();
    }

    Component.onCompleted: {
        if (root.runtime?.connected)
            root.runtime.requestRefresh();
    }
    onRuntimeChanged: root.handleConnectionChanged(root.runtime?.connected === true)

    QtObject {
        id: state

        property int activeInterfaceCount: 0
        property int consecutiveFailures: 0
        property var downloadHistory: Object.freeze([])
        property bool hasValue: false
        property string lastError: ""
        property int lastSequence: -1
        property var previousCounters: Object.freeze({})
        property double previousTimestamp: 0
        property real rawDownloadRate: 0
        property real rawUploadRate: 0
        property bool stale: false
        property var uploadHistory: Object.freeze([])
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
