import QtQuick
import Quickshell

Scope {
    id: root

    readonly property int actionCount: state.actionCount
    property var activeNumbers: ({})
    property bool available: true
    property int defaultActiveNumber: 1
    property string failNextError: ""
    readonly property string lastAction: state.lastAction
    readonly property int lastNumberTarget: state.lastNumberTarget
    readonly property string lastSpecialTarget: state.lastSpecialTarget
    property bool overviewAvailable: false
    property bool overviewBusy: false
    property bool overviewFailure: false
    readonly property string overviewLastError: root.overviewFailure ? "OVERVIEW_FIXTURE_FAILURE" : root.overviewAvailable ? "" : "OVERVIEW_UNAVAILABLE"
    readonly property int overviewRequestCount: state.overviewRequestCount
    property string specialBusyId: ""
    property var unavailableSpecialIds: []
    property var visibleSpecialIds: ({})

    signal stateChanged

    function activateNumberedWorkspace(number: int, monitorId: string, invocationContext): var {
        void invocationContext;
        if (!root.available)
            return root.result(false, "WORKSPACE_BACKEND_UNAVAILABLE");
        state.actionCount += 1;
        state.lastAction = "activateNumbered";
        state.lastNumberTarget = number;
        const failure = root.consumeFailure();
        if (failure.length > 0)
            return root.result(false, failure);
        const next = Object.assign({}, root.activeNumbers);
        next[monitorId] = number;
        root.activeNumbers = next;
        root.stateChanged();
        return root.result(true, "");
    }
    function activeNumberForMonitor(monitorId: string): int {
        if (!root.available)
            return -1;
        return Number(root.activeNumbers[monitorId] ?? root.defaultActiveNumber);
    }
    function consumeFailure(): string {
        const errorCode = root.failNextError;
        root.failNextError = "";
        return errorCode;
    }
    function requestOverview(monitorId: string, invocationContext): var {
        void monitorId;
        void invocationContext;
        state.overviewRequestCount += 1;
        if (!root.overviewAvailable)
            return root.result(false, "OVERVIEW_UNAVAILABLE");
        if (root.overviewBusy)
            return root.result(false, "OVERVIEW_BUSY");
        if (root.overviewFailure)
            return root.result(false, "OVERVIEW_FIXTURE_FAILURE");
        return root.result(true, "");
    }
    function resetActions() {
        state.actionCount = 0;
        state.lastAction = "";
        state.lastNumberTarget = -1;
        state.lastSpecialTarget = "";
        state.overviewRequestCount = 0;
    }
    function result(accepted: bool, errorCode: string): var {
        return Object.freeze({
            "accepted": accepted,
            "errorCode": errorCode
        });
    }
    function setActiveNumber(monitorId: string, number: int) {
        const next = Object.assign({}, root.activeNumbers);
        next[monitorId] = number;
        root.activeNumbers = next;
        root.stateChanged();
    }
    function setVisibleSpecialIds(monitorId: string, ids) {
        const next = Object.assign({}, root.visibleSpecialIds);
        next[monitorId] = Array.from(ids);
        root.visibleSpecialIds = next;
        root.stateChanged();
    }
    function specialSnapshot(monitorId: string): var {
        return Object.freeze({
            "stateAvailable": root.available,
            "visibleIds": Object.freeze(Array.from(root.visibleSpecialIds[monitorId] ?? [])),
            "unavailableIds": Object.freeze(Array.from(root.unavailableSpecialIds)),
            "busyId": root.specialBusyId,
            "lastError": ""
        });
    }
    function toggleSpecialWorkspace(id: string, monitorId: string, invocationContext): var {
        void invocationContext;
        if (!root.available)
            return root.result(false, "WORKSPACE_BACKEND_UNAVAILABLE");
        if (root.specialBusyId === id)
            return root.result(false, "SPECIAL_WORKSPACE_BUSY");
        state.actionCount += 1;
        state.lastAction = "toggleSpecial";
        state.lastSpecialTarget = id;
        const failure = root.consumeFailure();
        if (failure.length > 0)
            return root.result(false, failure);
        if (root.unavailableSpecialIds.indexOf(id) >= 0)
            return root.result(false, "SPECIAL_WORKSPACE_UNAVAILABLE");

        const visible = Array.from(root.visibleSpecialIds[monitorId] ?? []);
        const index = visible.indexOf(id);
        if (index >= 0)
            visible.splice(index, 1);
        else
            visible.push(id);
        root.setVisibleSpecialIds(monitorId, visible);
        return root.result(true, "");
    }

    QtObject {
        id: state

        property int actionCount: 0
        property string lastAction: ""
        property int lastNumberTarget: -1
        property string lastSpecialTarget: ""
        property int overviewRequestCount: 0
    }
}
