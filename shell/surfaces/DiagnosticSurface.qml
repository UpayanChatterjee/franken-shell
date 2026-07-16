import QtQuick
import Quickshell
import "../core" as Core
import "../theme" as Theme

FloatingWindow {
    required property string mode
    required property string startupState

    reloadableId: "phase0-diagnostic-surface"
    title: qsTr("Franken Shell Phase 0")
    implicitWidth: 440
    implicitHeight: 240
    color: Theme.FallbackTheme.background
    mask: Region {}

    Rectangle {
        anchors.fill: parent
        color: Theme.FallbackTheme.surface
        border.color: Theme.FallbackTheme.outline
        radius: Theme.FallbackTheme.radiusMedium

        Column {
            anchors.centerIn: parent
            spacing: Theme.FallbackTheme.spacingSmall

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                color: Theme.FallbackTheme.primaryText
                font.bold: true
                font.pixelSize: 24
                text: qsTr("Franken Shell")
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                color: Theme.FallbackTheme.accent
                font.pixelSize: 15
                text: qsTr("Phase 0 bootstrap is running")
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                color: Theme.FallbackTheme.secondaryText
                text: qsTr("Mode: %1").arg(mode)
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                color: Theme.FallbackTheme.secondaryText
                text: qsTr("State: %1").arg(startupState)
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                color: Theme.FallbackTheme.secondaryText
                text: qsTr("Version: %1").arg(Core.ProjectInfo.projectVersion)
            }
        }
    }
}
