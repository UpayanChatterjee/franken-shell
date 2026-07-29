import QtQuick

QtObject {
    id: root

    required property var adapter
    readonly property bool available: root.adapter?.overviewAvailable === true
    readonly property bool busy: root.adapter?.overviewBusy === true
    property bool enabled: false
    readonly property string integrationError: String(root.adapter?.overviewLastError ?? "")
    property string lastError: ""

    function activate(monitorId: string, invocationContext): var {
        if (!root.enabled)
            return root.result(true, "");
        if (!root.available) {
            root.lastError = root.integrationError.length > 0 ? root.integrationError : "OVERVIEW_UNAVAILABLE";
            return root.result(false, root.lastError);
        }
        if (root.busy) {
            root.lastError = "OVERVIEW_BUSY";
            return root.result(false, root.lastError);
        }

        const result = root.adapter.requestOverview(monitorId, invocationContext);
        root.lastError = result.accepted ? "" : String(result.errorCode ?? "OVERVIEW_REQUEST_FAILED");
        return root.result(result.accepted === true, root.lastError);
    }
    function result(accepted: bool, errorCode: string): var {
        return Object.freeze({
            "accepted": accepted,
            "errorCode": errorCode
        });
    }
}
