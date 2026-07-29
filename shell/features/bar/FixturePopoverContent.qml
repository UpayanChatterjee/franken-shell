import QtQuick

FocusScope {
    id: root

    required property var datum
    required property var theme

    Accessible.name: root.datum?.popoverTitle ?? qsTr("Fixture popover")
    Accessible.role: Accessible.Pane
    activeFocusOnTab: true
    implicitHeight: contentColumn.implicitHeight + 2 * root.theme.spacing.space3
    implicitWidth: Math.min(root.theme.metrics.popoverMaxWidth, 260)

    Column {
        id: contentColumn

        anchors.fill: parent
        anchors.margins: root.theme.spacing.space3
        spacing: root.theme.spacing.space2

        Text {
            color: root.theme.colors.textPrimary
            font.family: root.theme.typography.fontFamily
            font.pixelSize: root.theme.typography.fontSizeSection
            font.weight: root.theme.typography.fontWeightSemibold
            text: root.datum?.popoverTitle ?? qsTr("Fixture")
            width: parent.width
        }
        Text {
            color: root.theme.colors.textSecondary
            font.family: root.theme.typography.fontFamily
            font.pixelSize: root.theme.typography.fontSizeBody
            text: qsTr("Fixture content — real service workflow is deferred.")
            width: parent.width
            wrapMode: Text.Wrap
        }
    }
}
