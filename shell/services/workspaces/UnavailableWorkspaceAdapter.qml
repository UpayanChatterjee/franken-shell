import QtQuick
import Quickshell

Scope {
    id: root

    readonly property bool available: false
    readonly property bool overviewAvailable: false
    readonly property bool overviewBusy: false
    readonly property string overviewLastError: "OVERVIEW_UNAVAILABLE"

    signal stateChanged

    function activateNumberedWorkspace(number: int, monitorId: string, invocationContext): var {
        void number;
        void monitorId;
        void invocationContext;
        return root.result(false, "WORKSPACE_BACKEND_UNAVAILABLE");
    }
    function activeNumberForMonitor(monitorId: string): int {
        void monitorId;
        return -1;
    }
    function requestOverview(monitorId: string, invocationContext): var {
        void monitorId;
        void invocationContext;
        return root.result(false, "OVERVIEW_UNAVAILABLE");
    }
    function result(accepted: bool, errorCode: string): var {
        return Object.freeze({
            "accepted": accepted,
            "errorCode": errorCode
        });
    }
    function specialSnapshot(monitorId: string): var {
        void monitorId;
        return Object.freeze({
            "stateAvailable": false,
            "visibleIds": Object.freeze([]),
            "unavailableIds": Object.freeze([]),
            "busyId": "",
            "lastError": "WORKSPACE_BACKEND_UNAVAILABLE"
        });
    }
    function toggleSpecialWorkspace(id: string, monitorId: string, invocationContext): var {
        void id;
        void monitorId;
        void invocationContext;
        return root.result(false, "WORKSPACE_BACKEND_UNAVAILABLE");
    }
}
