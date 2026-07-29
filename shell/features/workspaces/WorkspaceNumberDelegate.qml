import QtQuick

Rectangle {
    id: root

    required property bool active
    required property real extent
    required property bool keyboardFocused
    required property int number
    required property string semanticLabel
    required property bool stateAvailable
    required property var theme
    required property bool vertical

    signal activated(string source)

    Accessible.description: root.semanticLabel
    Accessible.name: root.semanticLabel.length > 0 ? qsTr("Workspace %1, %2").arg(root.number).arg(root.semanticLabel) : qsTr("Workspace %1").arg(root.number)
    Accessible.role: Accessible.Button
    Accessible.selected: root.active
    clip: true
    color: root.active ? root.theme.colors.accentContainer : pointer.hovered ? root.theme.colors.surfaceRaised : "transparent"
    height: root.vertical ? root.extent : parent.height
    opacity: root.stateAvailable ? 1 : 0.55
    radius: root.theme.radius.radiusFull
    width: root.vertical ? parent.width : root.extent

    Rectangle {
        anchors.fill: parent
        anchors.margins: root.theme.spacing.space1
        border.color: root.keyboardFocused ? root.theme.colors.outlineFocus : "transparent"
        border.width: root.keyboardFocused ? root.theme.metrics.focusRingWidth : 0
        color: "transparent"
        radius: root.theme.radius.radiusFull
    }
    Text {
        anchors.centerIn: parent
        color: root.active ? root.theme.colors.accentOnContainer : root.stateAvailable ? root.theme.colors.textPrimary : root.theme.colors.textDisabled
        font.family: root.theme.typography.fontFamily
        font.pixelSize: root.theme.typography.fontSizeLabel
        font.weight: root.active ? root.theme.typography.fontWeightSemibold : root.theme.typography.fontWeightMedium
        text: root.number
    }
    HoverHandler {
        id: pointer
    }
    TapHandler {
        acceptedButtons: Qt.LeftButton
        enabled: root.stateAvailable

        onTapped: root.activated("pointer")
    }
}
