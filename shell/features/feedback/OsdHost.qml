pragma ComponentBehavior: Bound

import QtQuick

Item {
    id: root

    readonly property var currentRecord: {
        void root.service.revision;
        return root.service.currentForMonitor(root.ownerMonitorId);
    }
    required property string ownerMonitorId
    required property var service
    required property var theme

    implicitHeight: loader.item === null ? 0 : (loader.item as Item).implicitHeight
    implicitWidth: loader.item === null ? 0 : (loader.item as Item).implicitWidth
    visible: root.currentRecord !== null

    Loader {
        id: loader

        active: root.currentRecord !== null
        anchors.fill: parent
        sourceComponent: osdComponent
    }
    Component {
        id: osdComponent

        OsdView {
            record: root.currentRecord
            theme: root.theme
        }
    }
}
