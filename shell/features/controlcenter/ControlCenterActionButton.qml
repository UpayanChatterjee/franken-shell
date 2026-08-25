import QtQuick

FocusScope {
    id: root

    property bool emphasized: false
    required property string label
    required property var theme

    signal triggered(string source)

    Accessible.name: root.label
    Accessible.role: Accessible.Button
    activeFocusOnTab: root.enabled
    implicitHeight: 36
    implicitWidth: Math.max(72, labelItem.implicitWidth + 2 * root.theme.spacing.space3)
    opacity: root.enabled ? 1 : 0.58

    Keys.onEnterPressed: event => {
        if (root.enabled)
            root.triggered("keyboard");

        event.accepted = true;
    }
    Keys.onReturnPressed: event => {
        if (root.enabled)
            root.triggered("keyboard");

        event.accepted = true;
    }
    Keys.onSpacePressed: event => {
        if (root.enabled)
            root.triggered("keyboard");

        event.accepted = true;
    }

    Rectangle {
        anchors.fill: parent
        border.color: root.activeFocus ? root.theme.colors.outlineFocus : root.emphasized ? root.theme.colors.accentPrimary : root.theme.colors.outlineSubtle
        border.width: root.activeFocus ? root.theme.metrics.focusRingWidth : root.theme.metrics.outlineWidth
        color: root.emphasized ? root.theme.colors.accentContainer : pointerHover.hovered && root.enabled ? root.theme.colors.surfaceRaised : root.theme.colors.surfaceOverlay
        radius: root.theme.radius.radiusFull

        Text {
            id: labelItem

            anchors.centerIn: parent
            color: root.emphasized ? root.theme.colors.accentOnContainer : root.enabled ? root.theme.colors.textPrimary : root.theme.colors.textDisabled
            elide: Text.ElideRight
            font.family: root.theme.typography.fontFamily
            font.pixelSize: root.theme.typography.fontSizeMetricSmall
            font.weight: root.theme.typography.fontWeightMedium
            text: root.label
        }
        TapHandler {
            acceptedButtons: Qt.LeftButton
            enabled: root.enabled

            onTapped: root.triggered("pointer")
        }
        HoverHandler {
            id: pointerHover

            enabled: root.enabled
        }
    }
}
