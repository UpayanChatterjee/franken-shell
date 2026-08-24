import QtQuick

FocusScope {
    id: root

    required property var controller
    required property bool keyboardOpened
    required property var theme

    implicitHeight: content.implicitHeight + 2 * root.theme.spacing.space3
    implicitWidth: Math.min(root.theme.metrics.popoverMaxWidth, 300)

    Component.onCompleted: {
        if (root.keyboardOpened && monitorAction.visible)
            Qt.callLater(monitorAction.forceActiveFocus);
    }

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
            text: qsTr("Resources")
            width: parent.width
        }
        Text {
            color: root.controller?.available === true ? root.theme.colors.textSecondary : root.theme.colors.warning
            font.family: root.theme.typography.fontFamily
            font.pixelSize: root.theme.typography.fontSizeBody
            text: root.controller?.available === true ? root.controller.memoryDescription : qsTr("Resource telemetry unavailable")
            width: parent.width
            wrapMode: Text.Wrap
        }
        Text {
            color: root.theme.colors.textSecondary
            font.family: root.theme.typography.fontFamily
            font.pixelSize: root.theme.typography.fontSizeBody
            text: root.controller?.cpuPercent >= 0 ? qsTr("CPU  %1%").arg(Math.round(root.controller.cpuPercent)) : qsTr("CPU  collecting…")
            visible: root.controller?.available === true
            width: parent.width
        }
        Text {
            color: root.theme.colors.textSecondary
            font.family: root.theme.typography.fontFamily
            font.pixelSize: root.theme.typography.fontSizeBody
            text: root.controller?.storageDescription ?? ""
            visible: text.length > 0
            width: parent.width
        }
        PopoverAction {
            id: monitorAction

            detail: root.controller?.externalMonitorAvailable === true ? "" : qsTr("Not configured")
            enabled: root.controller?.externalMonitorAvailable === true
            label: qsTr("Open system monitor")
            theme: root.theme
            width: parent.width

            onTriggered: origin => root.controller.openExternalMonitor({
                    "origin": origin
                })
        }
    }
}
