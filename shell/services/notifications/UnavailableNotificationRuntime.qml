import QtQuick
import Quickshell

Scope {
    id: root

    readonly property bool connected: false
    readonly property string connectionState: "unavailable"
    readonly property bool ownershipAttempted: false
    readonly property bool ownershipConfirmed: false
    readonly property string ownershipState: "notAttempted"

    signal actionFailed(string errorCode)
    signal connectionChanged(bool connected)
    signal notificationClosed(string sourceId, string reason)
    signal notificationReceived(var record)

    function dismiss(sourceId: string): var {
        void sourceId;
        return root.result();
    }
    function invokeAction(sourceId: string, actionId: string): var {
        void sourceId;
        void actionId;
        return root.result();
    }
    function result(): var {
        return Object.freeze({
            "accepted": false,
            "errorCode": "NOTIFICATION_BACKEND_DISCONNECTED"
        });
    }
}
