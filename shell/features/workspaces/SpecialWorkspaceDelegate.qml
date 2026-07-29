import QtQuick

Rectangle {
    id: root

    required property var datum
    required property bool keyboardFocused
    required property var theme

    signal activated

    Accessible.description: root.datum.shortcutHint
    Accessible.name: root.datum.label
    Accessible.role: Accessible.Button
    Accessible.selected: root.datum.visible
    color: root.datum.visible ? root.theme.colors.accentContainer : pointer.hovered ? root.theme.colors.surfaceRaised : "transparent"
    height: root.theme.metrics.barItemExtent
    opacity: root.datum.available ? 1 : 0.55
    radius: root.theme.radius.radiusSmall

    Rectangle {
        anchors.fill: parent
        anchors.margins: root.theme.spacing.space1
        border.color: root.keyboardFocused ? root.theme.colors.outlineFocus : "transparent"
        border.width: root.keyboardFocused ? root.theme.metrics.focusRingWidth : 0
        color: "transparent"
        radius: root.theme.radius.radiusSmall
    }
    Text {
        id: iconText

        anchors.left: parent.left
        anchors.leftMargin: root.theme.spacing.space2
        anchors.verticalCenter: parent.verticalCenter
        color: root.datum.visible ? root.theme.colors.accentOnContainer : root.theme.colors.textSecondary
        font.family: root.theme.typography.fontFamily
        font.pixelSize: root.theme.typography.fontSizeLabel
        font.weight: root.theme.typography.fontWeightSemibold
        text: root.datum.icon.slice(0, 1).toUpperCase()
        width: root.theme.metrics.iconMedium
    }
    Text {
        anchors.left: iconText.right
        anchors.leftMargin: root.theme.spacing.space1
        anchors.right: shortcutText.left
        anchors.rightMargin: root.theme.spacing.space2
        anchors.verticalCenter: parent.verticalCenter
        color: root.datum.available ? root.datum.visible ? root.theme.colors.accentOnContainer : root.theme.colors.textPrimary : root.theme.colors.textDisabled
        elide: Text.ElideRight
        font.family: root.theme.typography.fontFamily
        font.pixelSize: root.theme.typography.fontSizeLabel
        font.weight: root.datum.visible ? root.theme.typography.fontWeightSemibold : root.theme.typography.fontWeightMedium
        text: root.datum.label
    }
    Text {
        id: shortcutText

        anchors.right: parent.right
        anchors.rightMargin: root.theme.spacing.space2
        anchors.verticalCenter: parent.verticalCenter
        color: root.datum.visible ? root.theme.colors.accentOnContainer : root.theme.colors.textSecondary
        font.family: root.theme.typography.fontFamily
        font.pixelSize: root.theme.typography.fontSizeMetricSmall
        text: root.datum.busy ? qsTr("…") : root.datum.shortcutHint
    }
    HoverHandler {
        id: pointer
    }
    TapHandler {
        acceptedButtons: Qt.LeftButton
        enabled: root.datum.available && !root.datum.busy

        onTapped: root.activated()
    }
}
