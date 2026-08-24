import QtQuick

FocusScope {
    id: root

    property bool emphasized: false
    required property string label
    required property var theme

    signal triggered(string source)

    Accessible.name: root.label
    Accessible.role: Accessible.Button
    activeFocusOnTab: true
    implicitHeight: Math.max(40, labelItem.implicitHeight + 2 * root.theme.spacing.space2)
    implicitWidth: Math.max(72, labelItem.implicitWidth + 2 * root.theme.spacing.space3)

    Keys.onEnterPressed: event => {
        root.triggered("keyboard");
        event.accepted = true;
    }
    Keys.onReturnPressed: event => {
        root.triggered("keyboard");
        event.accepted = true;
    }
    Keys.onSpacePressed: event => {
        root.triggered("keyboard");
        event.accepted = true;
    }

    Rectangle {
        anchors.fill: parent
        border.color: root.activeFocus ? root.theme.colors.outlineFocus : root.emphasized ? root.theme.colors.accentPrimary : root.theme.colors.outlineSubtle
        border.width: root.activeFocus ? root.theme.metrics.focusRingWidth : root.theme.metrics.outlineWidth
        color: root.emphasized ? root.theme.colors.accentContainer : pointer.hovered ? root.theme.colors.surfaceOverlay : "transparent"
        radius: root.theme.radius.radiusSmall

        Text {
            id: labelItem

            anchors.centerIn: parent
            color: root.emphasized ? root.theme.colors.accentOnContainer : root.theme.colors.textPrimary
            elide: Text.ElideRight
            font.family: root.theme.typography.fontFamily
            font.pixelSize: root.theme.typography.fontSizeLabel
            font.weight: root.theme.typography.fontWeightMedium
            text: root.label
            width: Math.min(implicitWidth, parent.width - 2 * root.theme.spacing.space2)
        }
        HoverHandler {
            id: pointer
        }
        TapHandler {
            acceptedButtons: Qt.LeftButton

            onTapped: root.triggered("pointer")
        }
    }
}
