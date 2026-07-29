import QtQuick

FocusScope {
    id: root

    readonly property string anchorId: "bar." + root.datum.id + "." + root.safeToken(root.monitorId)
    required property var datum
    required property real extent
    required property string monitorId
    readonly property bool popoverOpen: root.datum.popoverId.length > 0 && root.surfaceCoordinator?.activePopoverId === root.datum.popoverId && root.surfaceCoordinator?.activePopover?.anchorId === root.anchorId
    required property var surfaceCoordinator
    required property var theme
    required property bool vertical

    function activate(origin: string): var {
        if (root.datum.popoverId.length === 0)
            return Object.freeze({
                "accepted": false,
                "changed": false,
                "errorCode": "FIXTURE_ACTION_UNAVAILABLE"
            });
        return root.surfaceCoordinator.togglePopover(root.datum.popoverId, root.anchorId, {
            "monitorId": root.monitorId,
            "origin": origin,
            "originControlId": root.anchorId,
            "previousFocusToken": "",
            "takesFocus": origin === "keyboard"
        });
    }
    function safeToken(value: string): string {
        const sanitized = value.replace(/[^A-Za-z0-9._:-]/g, "_");
        return sanitized.length > 0 ? sanitized : "unresolved";
    }

    Accessible.name: root.datum.accessibleName
    Accessible.role: root.datum.popoverId.length > 0 ? Accessible.Button : Accessible.StaticText
    activeFocusOnTab: root.datum.popoverId.length > 0
    clip: true
    height: root.vertical ? root.extent : parent.height
    visible: root.datum.visible
    width: root.vertical ? parent.width : root.extent

    Keys.onEnterPressed: event => {
        root.activate("keyboard");
        event.accepted = true;
    }
    Keys.onReturnPressed: event => {
        root.activate("keyboard");
        event.accepted = true;
    }
    Keys.onSpacePressed: event => {
        root.activate("keyboard");
        event.accepted = true;
    }

    Rectangle {
        anchors.fill: parent
        color: root.popoverOpen ? root.theme.colors.accentContainer : pointer.hovered && root.datum.popoverId.length > 0 ? root.theme.colors.surfaceRaised : "transparent"
        radius: root.popoverOpen ? root.theme.radius.radiusFull : root.theme.radius.radiusSmall

        Rectangle {
            anchors.fill: parent
            anchors.margins: root.theme.spacing.space1
            border.color: root.activeFocus ? root.theme.colors.outlineFocus : root.datum.emphasis === "privacy" ? root.theme.colors.privacy : "transparent"
            border.width: root.activeFocus ? root.theme.metrics.focusRingWidth : root.datum.emphasis === "privacy" ? root.theme.metrics.outlineWidth : 0
            color: "transparent"
            radius: parent.radius
        }
        Text {
            anchors.fill: parent
            anchors.margins: root.theme.spacing.space1
            color: root.popoverOpen ? root.theme.colors.accentOnContainer : root.datum.emphasis === "privacy" ? root.theme.colors.privacy : root.theme.colors.textPrimary
            elide: Text.ElideRight
            font.family: root.theme.typography.fontFamily
            font.features: ({
                    "tnum": 1
                })
            font.pixelSize: root.datum.emphasis === "metric" ? root.theme.typography.fontSizeMetricSmall : root.theme.typography.fontSizeLabel
            font.weight: root.popoverOpen ? root.theme.typography.fontWeightSemibold : root.theme.typography.fontWeightMedium
            horizontalAlignment: Text.AlignHCenter
            text: root.datum.label
            verticalAlignment: Text.AlignVCenter
        }
        HoverHandler {
            id: pointer
        }
        TapHandler {
            acceptedButtons: Qt.LeftButton
            enabled: root.datum.popoverId.length > 0

            onTapped: root.activate("pointer")
        }
    }
}
