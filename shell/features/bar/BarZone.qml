pragma ComponentBehavior: Bound

import QtQuick

Item {
    id: root

    property var audioController: null
    property var batteryController: null
    required property real cellExtent
    readonly property real contentExtent: root.visibleItemCount > 0 ? root.visibleItemCount * root.cellExtent + (root.visibleItemCount - 1) * root.spacing : 0
    property var dateTimeController: null
    required property var items
    readonly property real mainAxisExtent: root.reservedSlots > 0 ? root.reservedSlots * root.cellExtent + Math.max(0, root.reservedSlots - 1) * root.spacing : root.contentExtent
    required property string monitorId
    property int reservedSlots: 0
    property var resourceController: null
    required property real spacing
    required property var surfaceCoordinator
    required property var theme
    property var throughputController: null
    property var trayController: null
    required property bool vertical
    property var vicinaeAdapter: null
    readonly property int visibleItemCount: root.items.filter(item => root.itemVisible(item)).length

    // qmllint disable missing-property
    function anchorItem(anchorId: string): var {
        const content = contentLoader.item;
        if (content === null)
            return null;
        for (const item of content["children"]) {
            if (item["anchorId"] === anchorId)
                return item;
        }
        return null;
    }
    function itemVisible(item): bool {
        if (item.id === "tray" && root.trayController !== null)
            return root.trayController.visible;
        return item.id === "battery" && root.batteryController !== null ? root.batteryController.visible : item.visible;
    }

    // qmllint enable missing-property

    implicitHeight: root.vertical ? root.mainAxisExtent : root.theme.metrics.barThickness
    implicitWidth: root.vertical ? root.theme.metrics.barThickness : root.mainAxisExtent

    Loader {
        id: contentLoader

        anchors.fill: parent
        sourceComponent: root.vertical ? verticalContent : horizontalContent
    }
    Component {
        id: verticalContent

        Column {
            spacing: root.spacing
            width: parent.width

            Repeater {
                model: root.items

                delegate: BarFixtureCell {
                    required property var modelData

                    audioController: root.audioController
                    batteryController: root.batteryController
                    dateTimeController: root.dateTimeController
                    datum: modelData
                    extent: root.cellExtent
                    monitorId: root.monitorId
                    resourceController: root.resourceController
                    surfaceCoordinator: root.surfaceCoordinator
                    theme: root.theme
                    throughputController: root.throughputController
                    trayController: root.trayController
                    vertical: true
                    vicinaeAdapter: root.vicinaeAdapter
                }
            }
        }
    }
    Component {
        id: horizontalContent

        Row {
            height: parent.height
            spacing: root.spacing

            Repeater {
                model: root.items

                delegate: BarFixtureCell {
                    required property var modelData

                    audioController: root.audioController
                    batteryController: root.batteryController
                    dateTimeController: root.dateTimeController
                    datum: modelData
                    extent: root.cellExtent
                    monitorId: root.monitorId
                    resourceController: root.resourceController
                    surfaceCoordinator: root.surfaceCoordinator
                    theme: root.theme
                    throughputController: root.throughputController
                    trayController: root.trayController
                    vertical: false
                    vicinaeAdapter: root.vicinaeAdapter
                }
            }
        }
    }
}
