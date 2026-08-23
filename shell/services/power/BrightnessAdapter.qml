import QtQuick
import Quickshell

Scope {
    id: root

    readonly property bool available: state.connectionState === "ready" && state.defaultTarget !== null
    readonly property string connectionState: state.connectionState
    readonly property var defaultTarget: state.defaultTarget
    readonly property string lastError: state.lastError
    readonly property var operationTask: state.operationTask
    property string preferredTargetId: ""
    required property var runtime
    readonly property bool stale: state.stale
    readonly property var targets: state.targets
    readonly property real value: root.defaultTarget?.value ?? 0

    signal stateChanged

    function diagnosticsSummary(): var {
        return Object.freeze({
            "available": root.available,
            "connectionState": root.connectionState,
            "stale": root.stale,
            "targetCount": root.targets.length,
            "defaultTargetPresent": root.defaultTarget !== null,
            "operationState": String(root.operationTask?.state ?? "idle"),
            "staleSnapshotCount": state.staleSnapshotCount,
            "lastError": root.lastError
        });
    }
    function findTarget(targetId: string): var {
        for (const target of root.targets) {
            if (target.id === targetId)
                return target;
        }
        return null;
    }
    function handleActionFinished(taskId: string, accepted: bool, errorCode: string) {
        if (String(state.operationTask?.taskId ?? "") !== taskId)
            return;
        state.lastError = accepted ? "" : String(errorCode || "BRIGHTNESS_WRITE_FAILED");
        state.operationTask = Object.freeze({
            "taskId": taskId,
            "state": accepted ? "completed" : "failed",
            "errorCode": state.lastError
        });
        root.stateChanged();
    }
    function handleConnectionChanged(connected: bool) {
        if (!connected) {
            state.connectionState = state.hasSnapshot ? "reconnecting" : "unavailable";
            state.stale = state.targets.length > 0;
            if (state.operationTask?.state === "pending") {
                state.lastError = "BRIGHTNESS_DISCONNECTED";
                state.operationTask = Object.freeze({
                    "taskId": state.operationTask.taskId,
                    "state": "failed",
                    "errorCode": state.lastError
                });
            }
            root.stateChanged();
            return;
        }
        state.connectionState = "starting";
        state.stale = state.targets.length > 0;
        root.runtime.requestRefresh();
    }
    function normalize(candidate): var {
        const minimum = Number(candidate?.minimum ?? 0);
        const maximum = Number(candidate?.maximum ?? 0);
        const current = Number(candidate?.current ?? minimum);
        if (!Number.isFinite(minimum) || !Number.isFinite(maximum) || !Number.isFinite(current) || maximum <= minimum)
            return null;
        const boundedCurrent = Math.max(minimum, Math.min(maximum, current));
        return Object.freeze({
            "id": String(candidate?.id ?? ""),
            "name": String(candidate?.name ?? candidate?.id ?? ""),
            "kind": String(candidate?.kind ?? "unknown"),
            "minimum": minimum,
            "maximum": maximum,
            "current": boundedCurrent,
            "value": (boundedCurrent - minimum) / (maximum - minimum)
        });
    }
    function reconcile() {
        if (!root.runtime?.connected)
            return;
        let snapshot;
        try {
            snapshot = root.runtime.snapshot();
        } catch (error) {
            state.connectionState = "degraded";
            state.lastError = "BRIGHTNESS_SNAPSHOT_FAILED";
            state.stale = state.targets.length > 0;
            root.stateChanged();
            return;
        }
        const sequence = Number(snapshot?.sequence ?? 0);
        if (sequence < state.lastSequence) {
            state.staleSnapshotCount += 1;
            root.stateChanged();
            return;
        }

        const next = [];
        const candidates = Array.isArray(snapshot?.targets) ? snapshot.targets : [];
        for (const candidate of candidates) {
            const target = root.normalize(candidate);
            if (target !== null && target.id.length > 0)
                next.push(target);
        }
        next.sort((left, right) => left.id.localeCompare(right.id));
        state.targets = Object.freeze(next);
        state.defaultTarget = root.findTarget(root.preferredTargetId) ?? (next.length > 0 ? next[0] : null);
        state.hasSnapshot = true;
        state.lastSequence = sequence;
        state.lastError = state.operationTask?.state === "failed" ? state.lastError : "";
        state.connectionState = "ready";
        state.stale = false;
        root.stateChanged();
    }
    function result(accepted: bool, taskId: string, errorCode: string): var {
        return Object.freeze({
            "accepted": accepted,
            "taskId": taskId,
            "errorCode": errorCode
        });
    }
    function setConsumerActive(active: bool) {
        if (typeof root.runtime?.setConsumerActive === "function")
            root.runtime.setConsumerActive(active);
    }
    function setValue(value: real, targetId = ""): var {
        if (!root.available)
            return root.result(false, "", "BRIGHTNESS_DISCONNECTED");
        const target = root.findTarget(targetId.length > 0 ? targetId : root.defaultTarget.id);
        if (target === null)
            return root.result(false, "", "BRIGHTNESS_TARGET_UNAVAILABLE");
        const bounded = Math.max(0, Math.min(1, Number(value)));
        const rawValue = Math.round(target.minimum + bounded * (target.maximum - target.minimum));
        const response = root.runtime.setBrightness(target.id, rawValue);
        if (response?.accepted !== true) {
            state.lastError = String(response?.errorCode ?? "BRIGHTNESS_WRITE_FAILED");
            return root.result(false, "", state.lastError);
        }
        state.lastError = "";
        state.operationTask = Object.freeze({
            "taskId": String(response.taskId ?? ""),
            "state": "pending",
            "errorCode": ""
        });
        root.stateChanged();
        return root.result(true, state.operationTask.taskId, "");
    }

    Component.onCompleted: {
        if (root.runtime?.connected)
            root.handleConnectionChanged(true);
    }
    onPreferredTargetIdChanged: {
        state.defaultTarget = root.findTarget(root.preferredTargetId) ?? (state.targets.length > 0 ? state.targets[0] : null);
        root.stateChanged();
    }
    onRuntimeChanged: root.handleConnectionChanged(root.runtime?.connected === true)

    QtObject {
        id: state

        property string connectionState: "unavailable"
        property var defaultTarget: null
        property bool hasSnapshot: false
        property string lastError: ""
        property int lastSequence: -1
        property var operationTask: Object.freeze({
            "taskId": "",
            "state": "idle",
            "errorCode": ""
        })
        property bool stale: false
        property int staleSnapshotCount: 0
        property var targets: Object.freeze([])
    }
    Connections {
        function onActionFinished(taskId, accepted, errorCode) {
            root.handleActionFinished(taskId, accepted, errorCode);
        }
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
