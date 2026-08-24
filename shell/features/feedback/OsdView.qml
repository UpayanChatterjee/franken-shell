import QtQuick

Item {
    id: root

    required property var record
    required property var theme

    Accessible.name: qsTr("%1, %2 percent%3").arg(root.record.label).arg(Math.round(root.record.value * 100)).arg(root.record.muted ? qsTr(", muted") : "")
    Accessible.role: Accessible.StaticText
    implicitHeight: 76
    implicitWidth: 300

    Rectangle {
        anchors.fill: parent
        border.color: root.theme.colors.outlineStrong
        border.width: root.theme.metrics.outlineWidth
        color: root.theme.colors.surfacePopup
        opacity: root.theme.opacity.popover
        radius: root.theme.radius.radiusLarge

        Row {
            anchors.fill: parent
            anchors.margins: root.theme.spacing.space3
            spacing: root.theme.spacing.space3

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                color: root.record.muted ? root.theme.colors.critical : root.theme.colors.accentContainer
                height: 44
                radius: root.theme.radius.radiusMedium
                width: 44

                Text {
                    anchors.centerIn: parent
                    color: root.record.muted ? root.theme.colors.surfaceBase : root.theme.colors.accentOnContainer
                    font.family: root.theme.typography.fontFamily
                    font.pixelSize: root.theme.typography.fontSizeSection
                    font.weight: root.theme.typography.fontWeightSemibold
                    text: root.record.kind === "volume" ? root.record.muted ? "M" : "V" : "B"
                }
            }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: root.theme.spacing.space1
                width: Math.max(0, parent.width - 44 - parent.spacing)

                Row {
                    width: parent.width

                    Text {
                        color: root.theme.colors.textPrimary
                        font.family: root.theme.typography.fontFamily
                        font.pixelSize: root.theme.typography.fontSizeLabel
                        font.weight: root.theme.typography.fontWeightMedium
                        text: root.record.muted ? qsTr("Muted") : root.record.label
                        width: Math.max(0, parent.width - valueLabel.width)
                    }
                    Text {
                        id: valueLabel

                        color: root.theme.colors.textPrimary
                        font.family: root.theme.typography.fontFamily
                        font.pixelSize: root.theme.typography.fontSizeMetric
                        font.weight: root.theme.typography.fontWeightSemibold
                        text: Math.round(root.record.value * 100) + "%"
                    }
                }
                Rectangle {
                    color: root.theme.colors.outlineSubtle
                    height: 8
                    radius: root.theme.radius.radiusFull
                    width: parent.width

                    Rectangle {
                        color: root.record.muted ? root.theme.colors.critical : root.theme.colors.accentPrimary
                        height: parent.height
                        radius: parent.radius
                        width: parent.width * root.record.value
                    }
                }
            }
        }
    }
}
