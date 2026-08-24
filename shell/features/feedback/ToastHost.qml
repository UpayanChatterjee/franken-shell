pragma ComponentBehavior: Bound

import QtQuick

FocusScope {
    id: root

    readonly property int currentIndex: list.currentIndex
    property real maximumHeight: 480
    required property string ownerMonitorId
    required property var service
    required property var theme
    readonly property int toastCount: list.count
    readonly property var toastModel: {
        void root.service.revision;
        return root.service.toastsForMonitor(root.ownerMonitorId);
    }

    function focusInitial() {
        if (list.count === 0)
            return;
        list.currentIndex = 0;
        // The delegate is statically known to be ToastView.
        // qmllint disable missing-property
        list.itemAtIndex(0)?.focusInitial();
        // qmllint enable missing-property
    }
    function toastItemAt(index: int): var {
        return list.itemAtIndex(index);
    }

    implicitHeight: Math.min(root.maximumHeight, list.contentHeight)
    implicitWidth: 340
    visible: list.count > 0

    ListView {
        id: list

        anchors.fill: parent
        boundsBehavior: Flickable.StopAtBounds
        clip: true
        keyNavigationEnabled: true
        model: root.toastModel
        spacing: root.theme.spacing.space2

        delegate: ToastView {
            required property int index
            required property var modelData

            record: modelData
            service: root.service
            theme: root.theme
            width: list.width

            onFocused: key => {
                void key;
                list.currentIndex = index;
            }
        }
    }
}
