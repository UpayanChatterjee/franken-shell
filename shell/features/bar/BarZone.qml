pragma ComponentBehavior: Bound

import QtQuick

Item {
    id: root

    property var audioController: null
    required property real cellExtent
    readonly property real contentExtent: root.visibleItemCount > 0 ? root.visibleItemCount * root.cellExtent + (root.visibleItemCount - 1) * root.spacing : 0
    required property var items
    readonly property real mainAxisExtent: root.reservedSlots > 0 ? root.reservedSlots * root.cellExtent + Math.max(0, root.reservedSlots - 1) * root.spacing : root.contentExtent
    required property string monitorId
    property int reservedSlots: 0
    required property real spacing
    required property var surfaceCoordinator
    required property var theme
    required property bool vertical
    readonly property int visibleItemCount: root.items.filter(item => item.visible).length

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
                    datum: modelData
                    extent: root.cellExtent
                    monitorId: root.monitorId
                    surfaceCoordinator: root.surfaceCoordinator
                    theme: root.theme
                    vertical: true
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
                    datum: modelData
                    extent: root.cellExtent
                    monitorId: root.monitorId
                    surfaceCoordinator: root.surfaceCoordinator
                    theme: root.theme
                    vertical: false
                }
            }
        }
    }
}
