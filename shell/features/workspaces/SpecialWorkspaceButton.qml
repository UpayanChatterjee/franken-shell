import QtQuick

FocusScope {
    id: root

    readonly property string anchorId: "bar.special-workspaces." + root.safeToken(root.controller.monitorId)
    required property var controller
    readonly property real extent: root.theme.metrics.barItemExtent
    readonly property bool selectorOpen: root.surfaceCoordinator?.activePopoverId === "workspace.special-selector" && root.surfaceCoordinator?.activePopover?.ownerMonitorId === root.controller.monitorId
    required property var surfaceCoordinator
    required property var theme
    required property bool vertical

    signal selectorRequested(string origin)

    function requestSelector(origin: string): var {
        root.selectorRequested(origin);
        return root.surfaceCoordinator.togglePopover("workspace.special-selector", root.anchorId, {
            "monitorId": root.controller.monitorId,
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

    Accessible.name: root.controller.persistentLabel
    Accessible.role: Accessible.Button
    activeFocusOnTab: true
    height: root.vertical ? root.extent : parent.height
    implicitHeight: root.vertical ? root.extent : root.theme.metrics.barThickness
    implicitWidth: root.vertical ? root.theme.metrics.barThickness : root.extent
    visible: root.controller.definitionsCount > 0
    width: root.vertical ? parent.width : root.extent

    Keys.onEnterPressed: event => {
        root.requestSelector("keyboard");
        event.accepted = true;
    }
    Keys.onReturnPressed: event => {
        root.requestSelector("keyboard");
        event.accepted = true;
    }
    Keys.onSpacePressed: event => {
        root.requestSelector("keyboard");
        event.accepted = true;
    }

    Rectangle {
        anchors.fill: parent
        color: root.selectorOpen || root.controller.visibleIds.length > 0 ? root.theme.colors.accentContainer : pointer.hovered ? root.theme.colors.surfaceRaised : "transparent"
        opacity: root.controller.stateAvailable ? 1 : 0.55
        radius: root.theme.radius.radiusFull

        Rectangle {
            anchors.fill: parent
            anchors.margins: root.theme.spacing.space1
            border.color: root.activeFocus ? root.theme.colors.outlineFocus : "transparent"
            border.width: root.activeFocus ? root.theme.metrics.focusRingWidth : 0
            color: "transparent"
            radius: root.theme.radius.radiusFull
        }
        Text {
            anchors.centerIn: parent
            color: root.selectorOpen || root.controller.visibleIds.length > 0 ? root.theme.colors.accentOnContainer : root.controller.stateAvailable ? root.theme.colors.textPrimary : root.theme.colors.textDisabled
            font.family: root.theme.typography.fontFamily
            font.pixelSize: root.theme.typography.fontSizeLabel
            font.weight: root.theme.typography.fontWeightSemibold
            text: root.controller.persistentIcon === "stack" ? qsTr("S") : root.controller.persistentIcon.slice(0, 1).toUpperCase()
        }
        HoverHandler {
            id: pointer
        }
        TapHandler {
            acceptedButtons: Qt.LeftButton

            onTapped: root.requestSelector("pointer")
        }
    }
}
