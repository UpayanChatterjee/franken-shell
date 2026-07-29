import QtQuick

Rectangle {
    id: root

    required property var datum
    required property real extent
    required property var theme
    required property bool vertical

    Accessible.name: root.datum.accessibleName
    Accessible.role: Accessible.StaticText
    clip: true
    color: root.datum.emphasis === "selected" ? root.theme.colors.accentContainer : "transparent"
    height: root.vertical ? root.extent : parent.height
    radius: root.datum.emphasis === "selected" ? root.theme.radius.radiusFull : root.theme.radius.radiusSmall
    visible: root.datum.visible
    width: root.vertical ? parent.width : root.extent

    Rectangle {
        anchors.fill: parent
        border.color: root.datum.emphasis === "privacy" ? root.theme.colors.privacy : "transparent"
        border.width: root.datum.emphasis === "privacy" ? root.theme.metrics.outlineWidth : 0
        color: "transparent"
        radius: parent.radius
    }
    Text {
        anchors.fill: parent
        anchors.margins: root.theme.spacing.space1
        color: root.datum.emphasis === "selected" ? root.theme.colors.accentOnContainer : root.datum.emphasis === "privacy" ? root.theme.colors.privacy : root.theme.colors.textPrimary
        elide: Text.ElideRight
        font.family: root.theme.typography.fontFamily
        font.pixelSize: root.datum.emphasis === "metric" ? root.theme.typography.fontSizeMetricSmall : root.theme.typography.fontSizeLabel
        font.weight: root.datum.emphasis === "selected" ? root.theme.typography.fontWeightSemibold : root.theme.typography.fontWeightMedium
        horizontalAlignment: Text.AlignHCenter
        text: root.datum.label
        verticalAlignment: Text.AlignVCenter
    }
}
