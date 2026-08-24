pragma ComponentBehavior: Bound

import QtQuick

FocusScope {
    id: root

    required property var controller
    readonly property int currentIndex: popupList.currentIndex
    readonly property string currentPopupId: popupList.currentIndex >= 0 && popupList.currentIndex < root.popupModel.length ? root.popupModel[popupList.currentIndex].popupId : ""
    property real maximumHeight: 720
    required property string ownerMonitorId
    readonly property int popupCount: popupList.count
    readonly property var popupModel: {
        void root.controller.popupRevision;
        return root.controller.popupsForMonitor(root.ownerMonitorId);
    }
    required property var theme

    function focusIndex(index: int) {
        if (popupList.count === 0)
            return;
        popupList.currentIndex = Math.max(0, Math.min(index, popupList.count - 1));
        const target = popupList.itemAtIndex(popupList.currentIndex);
        if (target !== null)
            target.forceActiveFocus();
    }
    function focusInitial() {
        if (popupList.count === 0)
            return;
        popupList.currentIndex = 0;
        const target = popupList.itemAtIndex(0);
        if (target !== null)
            target.forceActiveFocus();
    }
    function popupItemAt(index: int): var {
        return popupList.itemAtIndex(index);
    }

    implicitHeight: Math.min(root.maximumHeight, popupList.contentHeight)
    implicitWidth: root.theme.metrics.notificationWidth
    visible: root.popupCount > 0

    ListView {
        id: popupList

        anchors.fill: parent
        boundsBehavior: Flickable.StopAtBounds
        clip: true
        keyNavigationEnabled: true
        model: root.popupModel
        spacing: root.theme.spacing.space2

        delegate: NotificationCard {
            required property int index
            required property var modelData

            allowSwipe: true
            compact: true
            controller: root.controller
            presentationCount: modelData.groupCount
            record: modelData.record
            theme: root.theme
            width: popupList.width

            onDismissRequested: (internalId, source) => {
                void source;
                root.controller.dismissPopup(internalId);
            }
            onFocused: internalId => {
                void internalId;
                popupList.currentIndex = index;
            }
            onTimeoutPauseChanged: (internalId, reason, paused) => {
                if (paused)
                    root.controller.pauseTimeout(internalId, reason);
                else
                    root.controller.resumeTimeout(internalId, reason);
            }
        }
    }
}
