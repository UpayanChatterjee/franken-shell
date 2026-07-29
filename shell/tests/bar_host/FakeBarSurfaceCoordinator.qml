import QtQuick

QtObject {
    id: root

    property var activePopover: null
    readonly property string activePopoverId: root.activePopover?.surfaceId ?? ""
    property int focusAcquisitionCount: 0
    property int focusRestorationCount: 0
    readonly property string owner: "fixture"
    property int revision: 0

    function closePopover(reason: string): var {
        void reason;
        if (root.activePopover === null)
            return root.result(false);
        if (root.activePopover.takesFocus)
            root.focusRestorationCount += 1;
        root.activePopover = null;
        root.revision += 1;
        return root.result(true);
    }
    function openPopover(surfaceId: string, anchorId: string, context): var {
        const changed = root.activePopover === null || root.activePopover.surfaceId !== surfaceId || root.activePopover.anchorId !== anchorId || root.activePopover.ownerMonitorId !== context.monitorId;
        if (!changed)
            return root.result(false);
        root.activePopover = Object.freeze({
            "surfaceId": surfaceId,
            "anchorId": anchorId,
            "ownerMonitorId": context.monitorId,
            "origin": context.origin,
            "takesFocus": context.takesFocus
        });
        if (context.takesFocus)
            root.focusAcquisitionCount += 1;
        root.revision += 1;
        return root.result(true);
    }
    function result(changed: bool): var {
        return Object.freeze({
            "accepted": true,
            "changed": changed,
            "errorCode": "",
            "revision": root.revision
        });
    }
    function togglePopover(surfaceId: string, anchorId: string, context): var {
        if (root.activePopover !== null && root.activePopover.surfaceId === surfaceId && root.activePopover.anchorId === anchorId)
            return root.closePopover("toggle");
        return root.openPopover(surfaceId, anchorId, context);
    }
}
