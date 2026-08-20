import QtQuick

FocusScope {
    id: root

    readonly property bool actionAllowed: root.controlModel?.available === true && root.controlModel?.enabled === true && root.controlModel?.busy !== true
    required property string controlId
    required property var controlModel
    readonly property string focusId: "quick." + root.controlId
    readonly property string stateName: root.controlModel?.available !== true ? "unavailable" : root.controlModel?.busy === true ? "busy" : String(root.controlModel?.error ?? "").length > 0 ? "failed" : root.controlModel?.active === true ? "active" : "inactive"
    required property var theme

    signal actionRequested(string action, string source)

    function requestAction(action: string, source: string): bool {
        if (action === "details" && root.controlModel?.canOpenDetails === true) {
            root.actionRequested(action, source);
            return true;
        }
        if (action === "toggle" && root.controlModel?.canToggle === true && root.actionAllowed) {
            root.actionRequested(action, source);
            return true;
        }
        return false;
    }

    Accessible.description: root.stateName
    Accessible.name: root.controlModel?.label ?? ""
    Accessible.role: Accessible.Button
    activeFocusOnTab: true
    implicitHeight: 68

    Keys.onEnterPressed: event => {
        root.requestAction("toggle", "keyboard");
        event.accepted = true;
    }
    Keys.onReturnPressed: event => {
        root.requestAction("toggle", "keyboard");
        event.accepted = true;
    }
    Keys.onRightPressed: event => {
        if (root.controlModel?.canOpenDetails === true) {
            root.requestAction("details", "keyboard");
            event.accepted = true;
        }
    }
    Keys.onSpacePressed: event => {
        root.requestAction("toggle", "keyboard");
        event.accepted = true;
    }

    Rectangle {
        anchors.fill: parent
        border.color: root.activeFocus ? root.theme.colors.outlineFocus : root.stateName === "failed" ? root.theme.colors.critical : root.theme.colors.outlineSubtle
        border.width: root.activeFocus ? root.theme.metrics.focusRingWidth : root.theme.metrics.outlineWidth
        color: root.controlModel?.active === true ? root.theme.colors.accentContainer : pointerHover.hovered ? root.theme.colors.surfaceRaised : root.theme.colors.surfaceOverlay
        radius: root.theme.radius.radiusMedium

        TapHandler {
            acceptedButtons: Qt.LeftButton

            onTapped: root.requestAction("toggle", "pointer")
        }
        HoverHandler {
            id: pointerHover
        }
    }
    Column {
        anchors.left: parent.left
        anchors.leftMargin: root.theme.spacing.space3
        anchors.right: details.visible ? details.left : parent.right
        anchors.rightMargin: root.theme.spacing.space3
        anchors.verticalCenter: parent.verticalCenter
        spacing: root.theme.spacing.space1

        Text {
            color: root.controlModel?.active === true ? root.theme.colors.accentOnContainer : root.controlModel?.available === true ? root.theme.colors.textPrimary : root.theme.colors.textDisabled
            elide: Text.ElideRight
            font.family: root.theme.typography.fontFamily
            font.pixelSize: root.theme.typography.fontSizeLabel
            font.weight: root.theme.typography.fontWeightMedium
            text: root.controlModel?.label ?? ""
            width: parent.width
        }
        Text {
            color: root.controlModel?.active === true ? root.theme.colors.accentOnContainer : root.stateName === "failed" ? root.theme.colors.critical : root.theme.colors.textSecondary
            elide: Text.ElideRight
            font.family: root.theme.typography.fontFamily
            font.pixelSize: root.theme.typography.fontSizeMetricSmall
            text: root.controlModel?.secondaryText ?? ""
            width: parent.width
        }
    }
    Item {
        id: details

        Accessible.name: qsTr("Open %1 details").arg(root.controlModel?.label ?? "")
        Accessible.role: Accessible.Button
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.top: parent.top
        visible: root.controlModel?.canOpenDetails === true
        width: 40

        Text {
            anchors.centerIn: parent
            color: root.controlModel?.active === true ? root.theme.colors.accentOnContainer : root.theme.colors.textSecondary
            font.family: root.theme.typography.fontFamily
            font.pixelSize: root.theme.typography.fontSizeBody
            text: "›"
        }
        TapHandler {
            acceptedButtons: Qt.LeftButton

            onTapped: root.requestAction("details", "pointer")
        }
    }
}
