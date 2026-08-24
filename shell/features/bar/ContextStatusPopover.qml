pragma ComponentBehavior: Bound

import QtQuick

FocusScope {
    id: root

    required property var controller
    readonly property var items: root.controller?.indicators ?? Object.freeze([])
    required property var theme

    implicitHeight: content.implicitHeight + 2 * root.theme.spacing.space3
    implicitWidth: Math.min(root.theme.metrics.popoverMaxWidth, 300)

    Column {
        id: content

        anchors.fill: parent
        anchors.margins: root.theme.spacing.space3
        spacing: root.theme.spacing.space2

        Text {
            color: root.theme.colors.textPrimary
            font.family: root.theme.typography.fontFamily
            font.pixelSize: root.theme.typography.fontSizeTitle
            font.weight: root.theme.typography.fontWeightSemibold
            text: qsTr("System status")
            width: parent.width
        }
        Repeater {
            model: root.items

            delegate: Text {
                required property var modelData

                color: modelData.severity === "critical" ? root.theme.colors.critical : modelData.severity === "warning" ? root.theme.colors.warning : root.theme.colors.textSecondary
                font.family: root.theme.typography.fontFamily
                font.pixelSize: root.theme.typography.fontSizeBody
                text: modelData.tooltip
                width: content.width
                wrapMode: Text.Wrap
            }
        }
    }
}
