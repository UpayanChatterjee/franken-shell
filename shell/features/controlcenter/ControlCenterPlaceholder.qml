import QtQuick

FocusScope {
    id: root

    readonly property bool initialFocusActive: closeControl.activeFocus
    required property var theme

    signal closeRequested

    function focusInitial() {
        closeControl.forceActiveFocus();
    }

    Accessible.name: qsTr("Control centre placeholder")
    Accessible.role: Accessible.Pane

    Column {
        anchors.fill: parent
        anchors.margins: root.theme.spacing.space4
        spacing: root.theme.spacing.space3

        Text {
            color: root.theme.colors.textPrimary
            font.family: root.theme.typography.fontFamily
            font.pixelSize: root.theme.typography.fontSizeTitle
            font.weight: root.theme.typography.fontWeightSemibold
            text: qsTr("Control Centre")
            width: parent.width
        }
        Text {
            color: root.theme.colors.textSecondary
            font.family: root.theme.typography.fontFamily
            font.pixelSize: root.theme.typography.fontSizeBody
            text: qsTr("Host mechanics fixture — feature controls arrive in later PRs.")
            width: parent.width
            wrapMode: Text.Wrap
        }
        FocusScope {
            id: closeControl

            Accessible.name: qsTr("Close control centre")
            Accessible.role: Accessible.Button
            activeFocusOnTab: true
            height: Math.max(44, root.theme?.metrics?.barItemExtent ?? 40)
            width: parent.width

            Keys.onEnterPressed: event => {
                root.closeRequested();
                event.accepted = true;
            }
            Keys.onReturnPressed: event => {
                root.closeRequested();
                event.accepted = true;
            }
            Keys.onSpacePressed: event => {
                root.closeRequested();
                event.accepted = true;
            }

            Rectangle {
                anchors.fill: parent
                border.color: closeControl.activeFocus ? root.theme.colors.outlineFocus : root.theme.colors.outlineSubtle
                border.width: closeControl.activeFocus ? root.theme.metrics.focusRingWidth : root.theme.metrics.outlineWidth
                color: pointer.hovered ? root.theme.colors.surfaceRaised : root.theme.colors.surfaceOverlay
                radius: root.theme.radius.radiusMedium

                Text {
                    anchors.centerIn: parent
                    color: root.theme.colors.textPrimary
                    font.family: root.theme.typography.fontFamily
                    font.pixelSize: root.theme.typography.fontSizeLabel
                    font.weight: root.theme.typography.fontWeightMedium
                    text: qsTr("Close")
                }
                HoverHandler {
                    id: pointer
                }
                TapHandler {
                    acceptedButtons: Qt.LeftButton

                    onTapped: root.closeRequested()
                }
            }
        }
    }
}
