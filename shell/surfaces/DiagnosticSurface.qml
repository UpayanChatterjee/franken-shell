import QtQuick
import Quickshell
import "../core" as Core

FloatingWindow {
    id: root

    required property string mode
    required property string startupState
    required property var theme

    color: root.theme.colors.surfaceBase
    implicitHeight: 240
    implicitWidth: root.theme.metrics.popoverMaxWidth
    reloadableId: "phase0-diagnostic-surface"
    title: qsTr("Franken Shell Phase 0")

    mask: Region {
    }

    Rectangle {
        anchors.fill: parent
        border.color: root.theme.colors.outlineStrong
        border.width: root.theme.metrics.outlineWidth
        color: root.theme.colors.surfaceRaised
        radius: root.theme.radius.radiusLarge

        Column {
            anchors.centerIn: parent
            spacing: root.theme.spacing.space2

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                color: root.theme.colors.textPrimary
                font.family: root.theme.typography.fontFamily
                font.pixelSize: root.theme.typography.fontSizeTitle
                font.weight: root.theme.typography.fontWeightSemibold
                text: qsTr("Franken Shell")
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                color: root.theme.colors.accentPrimary
                font.family: root.theme.typography.fontFamily
                font.pixelSize: root.theme.typography.fontSizeLabel
                font.weight: root.theme.typography.fontWeightMedium
                text: qsTr("Phase 0 bootstrap is running")
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                color: root.theme.colors.textSecondary
                font.family: root.theme.typography.fontFamily
                font.pixelSize: root.theme.typography.fontSizeBody
                text: qsTr("Mode: %1").arg(root.mode)
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                color: root.theme.colors.textSecondary
                font.family: root.theme.typography.fontFamily
                font.pixelSize: root.theme.typography.fontSizeBody
                text: qsTr("State: %1").arg(root.startupState)
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                color: root.theme.colors.textSecondary
                font.family: root.theme.typography.fontFamily
                font.pixelSize: root.theme.typography.fontSizeBody
                text: qsTr("Version: %1").arg(Core.ProjectInfo.projectVersion)
            }
        }
    }
}
