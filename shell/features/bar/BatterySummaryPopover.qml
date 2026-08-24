import QtQuick

FocusScope {
    id: root

    required property var controller
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
            text: qsTr("Power")
            width: parent.width
        }
        Text {
            color: root.controller?.available === true ? root.theme.colors.textSecondary : root.theme.colors.warning
            font.family: root.theme.typography.fontFamily
            font.pixelSize: root.theme.typography.fontSizeBody
            text: root.controller?.available === true ? qsTr("Battery %1% · %2").arg(Math.round(root.controller.percentage)).arg(root.controller.stateDescription) : root.controller?.batteryAvailability === "absent" ? qsTr("No battery detected") : qsTr("Battery state unavailable")
            width: parent.width
            wrapMode: Text.Wrap
        }
        Text {
            color: root.theme.colors.textSecondary
            font.family: root.theme.typography.fontFamily
            font.pixelSize: root.theme.typography.fontSizeBody
            text: qsTr("auto-cpufreq controls are not available yet. Battery status remains independent.")
            width: parent.width
            wrapMode: Text.Wrap
        }
    }
}
