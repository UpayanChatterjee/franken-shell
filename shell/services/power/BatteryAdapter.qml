import QtQuick
import Quickshell

Scope {
    id: root

    readonly property bool available: state.serviceAvailability === "ready" && state.batteryAvailability === "available"
    readonly property string batteryAvailability: state.batteryAvailability
    readonly property bool charging: root.chargingState === "charging" || root.chargingState === "pendingCharge"
    readonly property string chargingState: state.chargingState
    readonly property real percentage: state.percentage
    readonly property string powerSource: state.powerSource
    required property var runtime
    readonly property string serviceAvailability: state.serviceAvailability
    readonly property bool stale: state.stale
    readonly property real timeEstimateSeconds: state.timeEstimateSeconds
    readonly property string timeEstimateState: state.timeEstimateState

    signal stateChanged

    function diagnosticsSummary(): var {
        return Object.freeze({
            "serviceAvailability": root.serviceAvailability,
            "batteryAvailability": root.batteryAvailability,
            "available": root.available,
            "stale": root.stale,
            "percentage": root.available ? root.percentage : -1,
            "chargingState": root.chargingState,
            "powerSource": root.powerSource,
            "timeEstimateState": root.timeEstimateState,
            "staleSnapshotCount": state.staleSnapshotCount,
            "lastError": state.lastError
        });
    }
    function handleConnectionChanged(connected: bool) {
        if (!connected) {
            state.serviceAvailability = state.hasSnapshot ? "reconnecting" : "unavailable";
            state.stale = state.hasBatterySnapshot;
            root.stateChanged();
            return;
        }
        state.serviceAvailability = "starting";
        state.stale = state.hasBatterySnapshot;
        root.runtime.requestRefresh();
    }
    function normalizeChargingState(value: string): string {
        const stateName = String(value ?? "unknown");
        if (stateName === "fullyCharged")
            return "full";
        if (["charging", "discharging", "empty", "full", "pendingCharge", "pendingDischarge"].indexOf(stateName) >= 0)
            return stateName;
        return "unknown";
    }
    function reconcile() {
        if (!root.runtime?.connected)
            return;
        let snapshot;
        try {
            snapshot = root.runtime.snapshot();
        } catch (error) {
            state.serviceAvailability = "degraded";
            state.lastError = "BATTERY_SNAPSHOT_FAILED";
            state.stale = state.hasBatterySnapshot;
            root.stateChanged();
            return;
        }
        const sequence = Number(snapshot?.sequence ?? 0);
        if (sequence < state.lastSequence) {
            state.staleSnapshotCount += 1;
            root.stateChanged();
            return;
        }

        const battery = snapshot?.battery ?? null;
        state.lastSequence = sequence;
        state.hasSnapshot = true;
        state.lastError = "";
        state.serviceAvailability = "ready";
        state.stale = false;
        if (battery === null || battery.present !== true) {
            state.batteryAvailability = "absent";
            state.hasBatterySnapshot = false;
            state.percentage = -1;
            state.chargingState = "unknown";
            state.powerSource = "unknown";
            state.timeEstimateSeconds = -1;
            state.timeEstimateState = "unavailable";
            root.stateChanged();
            return;
        }

        state.batteryAvailability = "available";
        state.hasBatterySnapshot = true;
        state.percentage = Math.max(0, Math.min(100, Number(battery.percentage ?? 0)));
        state.chargingState = root.normalizeChargingState(String(battery.chargingState ?? "unknown"));
        state.powerSource = battery.powerSource === "battery" ? "battery" : battery.powerSource === "linePower" ? "linePower" : "unknown";
        const estimate = Number(battery.timeEstimateSeconds ?? -1);
        if (battery.estimateCredible === true && Number.isFinite(estimate) && estimate > 0) {
            state.timeEstimateSeconds = estimate;
            state.timeEstimateState = "credible";
        } else {
            state.timeEstimateSeconds = -1;
            state.timeEstimateState = "unavailable";
        }
        root.stateChanged();
    }

    Component.onCompleted: {
        if (root.runtime?.connected)
            root.handleConnectionChanged(true);
    }
    onRuntimeChanged: root.handleConnectionChanged(root.runtime?.connected === true)

    QtObject {
        id: state

        property string batteryAvailability: "unknown"
        property string chargingState: "unknown"
        property bool hasBatterySnapshot: false
        property bool hasSnapshot: false
        property string lastError: ""
        property int lastSequence: -1
        property real percentage: -1
        property string powerSource: "unknown"
        property string serviceAvailability: "unavailable"
        property bool stale: false
        property int staleSnapshotCount: 0
        property real timeEstimateSeconds: -1
        property string timeEstimateState: "unavailable"
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
