import QtQuick

FocusScope {
    id: root

    readonly property string focusedControlId: settingsAction.activeFocus ? "header.settings" : sessionAction.activeFocus ? "header.session" : ""
    required property var theme

    signal actionRequested(string actionId, string source)

    implicitHeight: 40

    Text {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        color: root.theme.colors.textPrimary
        font.family: root.theme.typography.fontFamily
        font.pixelSize: root.theme.typography.fontSizeTitle
        font.weight: root.theme.typography.fontWeightSemibold
        text: qsTr("Control Centre")
    }
    Row {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: root.theme.spacing.space2

        FocusScope {
            id: settingsAction

            Accessible.name: qsTr("Open shell settings")
            Accessible.role: Accessible.Button
            activeFocusOnTab: true
            height: 36
            width: 76

            Keys.onEnterPressed: event => {
                root.actionRequested("settings", "keyboard");
                event.accepted = true;
            }
            Keys.onReturnPressed: event => {
                root.actionRequested("settings", "keyboard");
                event.accepted = true;
            }
            Keys.onSpacePressed: event => {
                root.actionRequested("settings", "keyboard");
                event.accepted = true;
            }

            Rectangle {
                anchors.fill: parent
                border.color: settingsAction.activeFocus ? root.theme.colors.outlineFocus : root.theme.colors.outlineSubtle
                border.width: settingsAction.activeFocus ? root.theme.metrics.focusRingWidth : root.theme.metrics.outlineWidth
                color: settingsHover.hovered ? root.theme.colors.surfaceRaised : root.theme.colors.surfaceOverlay
                radius: root.theme.radius.radiusFull

                Text {
                    anchors.centerIn: parent
                    color: root.theme.colors.textPrimary
                    font.family: root.theme.typography.fontFamily
                    font.pixelSize: root.theme.typography.fontSizeMetricSmall
                    text: qsTr("Settings")
                }
                TapHandler {
                    acceptedButtons: Qt.LeftButton

                    onTapped: root.actionRequested("settings", "pointer")
                }
                HoverHandler {
                    id: settingsHover
                }
            }
        }
        FocusScope {
            id: sessionAction

            Accessible.name: qsTr("Open session controls")
            Accessible.role: Accessible.Button
            activeFocusOnTab: true
            height: 36
            width: 64

            Keys.onEnterPressed: event => {
                root.actionRequested("session", "keyboard");
                event.accepted = true;
            }
            Keys.onReturnPressed: event => {
                root.actionRequested("session", "keyboard");
                event.accepted = true;
            }
            Keys.onSpacePressed: event => {
                root.actionRequested("session", "keyboard");
                event.accepted = true;
            }

            Rectangle {
                anchors.fill: parent
                border.color: sessionAction.activeFocus ? root.theme.colors.outlineFocus : root.theme.colors.outlineSubtle
                border.width: sessionAction.activeFocus ? root.theme.metrics.focusRingWidth : root.theme.metrics.outlineWidth
                color: sessionHover.hovered ? root.theme.colors.surfaceRaised : root.theme.colors.surfaceOverlay
                radius: root.theme.radius.radiusFull

                Text {
                    anchors.centerIn: parent
                    color: root.theme.colors.textPrimary
                    font.family: root.theme.typography.fontFamily
                    font.pixelSize: root.theme.typography.fontSizeMetricSmall
                    text: qsTr("Power")
                }
                TapHandler {
                    acceptedButtons: Qt.LeftButton

                    onTapped: root.actionRequested("session", "pointer")
                }
                HoverHandler {
                    id: sessionHover
                }
            }
        }
    }
}
