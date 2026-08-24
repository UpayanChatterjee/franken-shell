import QtQuick

FocusScope {
    id: root

    property string detail: ""
    required property string label
    required property var theme

    signal triggered(string origin)

    Accessible.description: root.detail
    Accessible.name: root.label
    Accessible.role: Accessible.Button
    activeFocusOnTab: root.enabled
    implicitHeight: 42
    opacity: root.enabled ? 1 : 0.5

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
        border.color: root.activeFocus ? root.theme.colors.outlineFocus : root.theme.colors.outlineSubtle
        border.width: root.activeFocus ? root.theme.metrics.focusRingWidth : root.theme.metrics.outlineWidth
        color: pointer.hovered && root.enabled ? root.theme.colors.surfaceRaised : root.theme.colors.surfaceOverlay
        radius: root.theme.radius.radiusSmall
    }
    Text {
        anchors.left: parent.left
        anchors.leftMargin: root.theme.spacing.space3
        anchors.right: parent.right
        anchors.rightMargin: root.theme.spacing.space3
        anchors.verticalCenter: parent.verticalCenter
        color: root.theme.colors.textPrimary
        elide: Text.ElideRight
        font.family: root.theme.typography.fontFamily
        font.pixelSize: root.theme.typography.fontSizeLabel
        text: root.detail.length > 0 ? qsTr("%1  ·  %2").arg(root.label).arg(root.detail) : root.label
    }
    HoverHandler {
        id: pointer
    }
    TapHandler {
        acceptedButtons: Qt.LeftButton
        enabled: root.enabled

        onTapped: root.triggered("pointer")
    }
}
