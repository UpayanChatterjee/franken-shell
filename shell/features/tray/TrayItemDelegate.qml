import QtQuick

FocusScope {
    id: root

    required property var controller
    required property var datum
    required property int itemIndex
    required property var theme

    signal dismissRequested(string reason)
    signal focused(string itemId, int itemIndex)

    function activatePrimary() {
        root.controller.activate(root.datum.stableId, root);
    }
    function openMenu() {
        root.controller.openMenu(root.datum.stableId, root);
    }
    function statusText(): string {
        if (root.datum.status === "needsAttention")
            return qsTr("needs attention");

        if (root.datum.status === "passive")
            return qsTr("passive");

        return qsTr("active");
    }

    Accessible.description: root.datum.tooltipDescription
    Accessible.name: qsTr("%1, %2").arg(root.datum.title).arg(root.statusText())
    Accessible.role: Accessible.Button
    activeFocusOnTab: true
    implicitHeight: Math.max(root.theme.metrics.barItemExtent, titleLabel.implicitHeight + 2 * root.theme.spacing.space2)
    implicitWidth: 260

    Keys.onEnterPressed: event => {
        root.activatePrimary();
        event.accepted = true;
    }
    Keys.onEscapePressed: event => {
        if (root.controller.menuState.active)
            root.controller.closeMenu();
        else
            root.dismissRequested("escape");
        event.accepted = true;
    }
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Menu || (event.key === Qt.Key_F10 && (event.modifiers & Qt.ShiftModifier))) {
            root.openMenu();
            event.accepted = true;
        }
    }
    Keys.onReturnPressed: event => {
        root.activatePrimary();
        event.accepted = true;
    }
    Keys.onSpacePressed: event => {
        root.activatePrimary();
        event.accepted = true;
    }
    onActiveFocusChanged: {
        if (root.activeFocus)
            root.focused(root.datum.stableId, root.itemIndex);
    }

    Rectangle {
        anchors.fill: parent
        border.color: root.activeFocus ? root.theme.colors.outlineFocus : root.datum.status === "needsAttention" ? root.theme.colors.warning : "transparent"
        border.width: root.activeFocus ? root.theme.metrics.focusRingWidth : root.datum.status === "needsAttention" ? root.theme.metrics.outlineWidth : 0
        color: pointer.hovered ? root.theme.colors.surfaceRaised : "transparent"
        radius: root.theme.radius.radiusSmall

        Image {
            id: iconImage

            anchors.left: parent.left
            anchors.leftMargin: root.theme.spacing.space2
            anchors.verticalCenter: parent.verticalCenter
            fillMode: Image.PreserveAspectFit
            height: root.theme.metrics.iconMedium
            source: root.datum.icon
            sourceSize.height: Math.ceil(height)
            sourceSize.width: Math.ceil(width)
            visible: root.datum.icon.length > 0 && status === Image.Ready
            width: height
        }
        Text {
            anchors.centerIn: iconImage
            color: root.datum.status === "needsAttention" ? root.theme.colors.warning : root.theme.colors.textSecondary
            font.family: root.theme.typography.fontFamily
            font.pixelSize: root.theme.typography.fontSizeLabel
            font.weight: root.theme.typography.fontWeightSemibold
            text: "•"
            visible: !iconImage.visible
        }
        Text {
            id: titleLabel

            anchors.left: iconImage.right
            anchors.leftMargin: root.theme.spacing.space2
            anchors.right: statusMarker.left
            anchors.rightMargin: root.theme.spacing.space2
            anchors.verticalCenter: parent.verticalCenter
            color: root.theme.colors.textPrimary
            elide: Text.ElideRight
            font.family: root.theme.typography.fontFamily
            font.pixelSize: root.theme.typography.fontSizeBody
            font.weight: root.theme.typography.fontWeightMedium
            text: root.datum.title
        }
        Text {
            id: statusMarker

            anchors.right: parent.right
            anchors.rightMargin: root.theme.spacing.space2
            anchors.verticalCenter: parent.verticalCenter
            color: root.datum.status === "needsAttention" ? root.theme.colors.warning : root.theme.colors.textSecondary
            font.family: root.theme.typography.fontFamily
            font.pixelSize: root.theme.typography.fontSizeLabel
            text: root.datum.status === "needsAttention" ? "!" : root.datum.menuAvailable ? "⋮" : ""
        }
        HoverHandler {
            id: pointer
        }
        TapHandler {
            acceptedButtons: Qt.LeftButton

            onTapped: root.activatePrimary()
        }
        TapHandler {
            acceptedButtons: Qt.RightButton
            enabled: root.datum.menuAvailable

            onTapped: root.openMenu()
        }
        TapHandler {
            acceptedButtons: Qt.MiddleButton
            enabled: root.datum.availableActions.secondaryActivate

            onTapped: root.controller.secondaryActivate(root.datum.stableId)
        }
        WheelHandler {
            enabled: root.datum.availableActions.scroll

            onWheel: event => {
                const horizontal = Math.abs(event.angleDelta.x) > Math.abs(event.angleDelta.y);
                const delta = horizontal ? event.angleDelta.x : event.angleDelta.y;
                root.controller.scroll(root.datum.stableId, delta, horizontal);
                event.accepted = true;
            }
        }
    }
}
