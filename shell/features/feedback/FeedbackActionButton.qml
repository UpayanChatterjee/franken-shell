import QtQuick

FocusScope {
    id: root

    required property string label
    required property var theme

    signal triggered

    Accessible.name: root.label
    Accessible.role: Accessible.Button
    activeFocusOnTab: true
    implicitHeight: 36
    implicitWidth: Math.max(72, labelItem.implicitWidth + 2 * root.theme.spacing.space3)

    Keys.onEnterPressed: event => {
        root.triggered();
        event.accepted = true;
    }
    Keys.onReturnPressed: event => {
        root.triggered();
        event.accepted = true;
    }
    Keys.onSpacePressed: event => {
        root.triggered();
        event.accepted = true;
    }

    Rectangle {
        anchors.fill: parent
        border.color: root.activeFocus ? root.theme.colors.outlineFocus : root.theme.colors.outlineSubtle
        border.width: root.activeFocus ? root.theme.metrics.focusRingWidth : root.theme.metrics.outlineWidth
        color: pointer.hovered ? root.theme.colors.surfaceOverlay : "transparent"
        radius: root.theme.radius.radiusSmall

        Text {
            id: labelItem

            anchors.centerIn: parent
            color: root.theme.colors.textPrimary
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

            onTapped: root.triggered()
        }
    }
}
