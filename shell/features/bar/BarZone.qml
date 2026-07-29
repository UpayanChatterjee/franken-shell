pragma ComponentBehavior: Bound

import QtQuick

Item {
    id: root

    required property real cellExtent
    readonly property real contentExtent: root.visibleItemCount > 0 ? root.visibleItemCount * root.cellExtent + (root.visibleItemCount - 1) * root.spacing : 0
    required property var items
    readonly property real mainAxisExtent: root.reservedSlots > 0 ? root.reservedSlots * root.cellExtent + Math.max(0, root.reservedSlots - 1) * root.spacing : root.contentExtent
    property int reservedSlots: 0
    required property real spacing
    required property var theme
    required property bool vertical
    readonly property int visibleItemCount: root.items.filter(item => item.visible).length

    implicitHeight: root.vertical ? root.mainAxisExtent : root.theme.metrics.barThickness
    implicitWidth: root.vertical ? root.theme.metrics.barThickness : root.mainAxisExtent

    Loader {
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

                    datum: modelData
                    extent: root.cellExtent
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

                    datum: modelData
                    extent: root.cellExtent
                    theme: root.theme
                    vertical: false
                }
            }
        }
    }
}
