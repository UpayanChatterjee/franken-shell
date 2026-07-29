import QtQuick

QtObject {
    id: root

    property var activePopover: null
    readonly property string activePopoverId: root.activePopover?.surfaceId ?? ""
    property int closeCount: 0
    property var lastContext: null
    property int openCount: 0
    property int restorationCount: 0

    function closePopover(reason: string): var {
        void reason;
        if (root.activePopover === null)
            return root.result(true, false, "");
        root.activePopover = null;
        root.closeCount += 1;
        root.restorationCount += 1;
        return root.result(true, true, "");
    }
    function removeMonitor(monitorId: string) {
        if (root.activePopover?.ownerMonitorId === monitorId)
            root.closePopover("ownerMonitorRemoved");
    }
    function result(accepted: bool, changed: bool, errorCode: string): var {
        return Object.freeze({
            "accepted": accepted,
            "changed": changed,
            "errorCode": errorCode
        });
    }
    function togglePopover(surfaceId: string, anchorId: string, context): var {
        root.lastContext = context;
        if (root.activePopover?.surfaceId === surfaceId && root.activePopover?.anchorId === anchorId)
            return root.closePopover("toggle");
        root.activePopover = Object.freeze({
            "surfaceId": surfaceId,
            "anchorId": anchorId,
            "ownerMonitorId": context.monitorId
        });
        root.openCount += 1;
        return root.result(true, true, "");
    }
}
