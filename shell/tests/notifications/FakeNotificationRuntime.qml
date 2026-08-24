import QtQuick
import Quickshell

Scope {
    id: root

    property bool connected: false
    property string connectionState: "unavailable"
    property string failNextError: ""
    readonly property string lastAction: state.lastAction
    property bool ownershipAttempted: false
    property bool ownershipConfirmed: false
    property string ownershipState: "notAttempted"

    signal actionFailed(string errorCode)
    signal connectionChanged(bool connected)
    signal notificationClosed(string sourceId, string reason)
    signal notificationReceived(var record)

    function asArray(value): var {
        return Array.isArray(value) ? value : [];
    }
    function consumeFailure(): var {
        const errorCode = root.failNextError;
        root.failNextError = "";
        return root.result(false, errorCode);
    }
    function dismiss(sourceId: string): var {
        if (!root.connected)
            return root.result(false, "NOTIFICATION_BACKEND_DISCONNECTED");
        if (root.failNextError.length > 0)
            return root.consumeFailure();
        if (state.records[sourceId] === undefined)
            return root.result(false, "NOTIFICATION_UNAVAILABLE");
        delete state.records[sourceId];
        state.lastAction = "dismiss:" + sourceId;
        root.notificationClosed(sourceId, "dismissed");
        return root.result(true, "");
    }
    function invokeAction(sourceId: string, actionId: string): var {
        if (!root.connected)
            return root.result(false, "NOTIFICATION_BACKEND_DISCONNECTED");
        if (root.failNextError.length > 0)
            return root.consumeFailure();
        const record = state.records[sourceId];
        if (record === undefined)
            return root.result(false, "NOTIFICATION_UNAVAILABLE");
        const action = root.asArray(record.actions).find(candidate => String(candidate?.id ?? candidate?.identifier ?? "") === actionId);
        if (action === undefined)
            return root.result(false, "NOTIFICATION_ACTION_UNAVAILABLE");
        state.lastAction = "action:" + actionId + ":" + sourceId;
        if (record.resident !== true) {
            delete state.records[sourceId];
            root.notificationClosed(sourceId, "dismissed");
        }
        return root.result(true, "");
    }
    function publish(record) {
        const sourceId = String(record?.sourceId ?? "");
        if (sourceId.length === 0)
            return;
        state.records[sourceId] = record;
        root.notificationReceived(record);
    }
    function reemitTracked() {
        for (const sourceId of Object.keys(state.records))
            root.notificationReceived(state.records[sourceId]);
    }
    function reset() {
        state.records = ({});
        state.lastAction = "";
    }
    function result(accepted: bool, errorCode: string): var {
        return Object.freeze({
            "accepted": accepted,
            "errorCode": errorCode
        });
    }
    function setConnected(value: bool, nextState = "") {
        root.connected = value;
        root.connectionState = nextState.length > 0 ? nextState : value ? "ready" : "unavailable";
        root.connectionChanged(value);
    }

    QtObject {
        id: state

        property string lastAction: ""
        property var records: ({})
    }
}
