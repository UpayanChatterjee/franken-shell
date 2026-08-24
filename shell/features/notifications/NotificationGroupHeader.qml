import QtQuick

FocusScope {
    id: root

    required property var controller
    required property var group
    required property var theme

    signal focused(string rowId)

    Accessible.name: qsTr("%1, %2 notification(s)").arg(root.group.appName || qsTr("Unknown application")).arg(root.group.count)
    Accessible.role: Accessible.Grouping
    activeFocusOnTab: true
    implicitHeight: Math.max(48, heading.implicitHeight + 2 * root.theme.spacing.space2)

    Keys.onEnterPressed: event => {
        root.controller.toggleGroup(root.group.groupKey);
        event.accepted = true;
    }
    Keys.onReturnPressed: event => {
        root.controller.toggleGroup(root.group.groupKey);
        event.accepted = true;
    }
    Keys.onSpacePressed: event => {
        root.controller.toggleGroup(root.group.groupKey);
        event.accepted = true;
    }
    onActiveFocusChanged: {
        if (root.activeFocus)
            root.focused(root.group.rowId);
    }

    Rectangle {
        anchors.fill: parent
        border.color: root.activeFocus ? root.theme.colors.outlineFocus : root.theme.colors.outlineSubtle
        border.width: root.activeFocus ? root.theme.metrics.focusRingWidth : root.theme.metrics.outlineWidth
        color: pointer.hovered ? root.theme.colors.surfaceOverlay : root.theme.colors.surfaceRaised
        radius: root.theme.radius.radiusMedium

        Row {
            anchors.left: parent.left
            anchors.leftMargin: root.theme.spacing.space3
            anchors.right: parent.right
            anchors.rightMargin: root.theme.spacing.space2
            anchors.verticalCenter: parent.verticalCenter
            spacing: root.theme.spacing.space2

            Text {
                id: heading

                color: root.theme.colors.textPrimary
                elide: Text.ElideRight
                font.family: root.theme.typography.fontFamily
                font.pixelSize: root.theme.typography.fontSizeSection
                font.weight: root.theme.typography.fontWeightMedium
                text: root.group.appName || qsTr("Unknown application")
                width: Math.max(0, parent.width - countLabel.width - expandButton.width - clearButton.width - parent.spacing * 3)
            }
            Text {
                id: countLabel

                color: root.theme.colors.textSecondary
                font.family: root.theme.typography.fontFamily
                font.pixelSize: root.theme.typography.fontSizeLabel
                text: String(root.group.count)
            }
            NotificationActionButton {
                id: expandButton

                Accessible.name: root.group.expanded ? qsTr("Collapse notification group") : qsTr("Expand notification group")
                implicitWidth: 40
                label: root.group.expanded ? "⌃" : "⌄"
                theme: root.theme

                onTriggered: source => {
                    void source;
                    root.controller.toggleGroup(root.group.groupKey);
                }
            }
            NotificationActionButton {
                id: clearButton

                Accessible.name: qsTr("Dismiss notification group")
                enabled: root.group.dismissibleCount > 0
                implicitWidth: 40
                label: "×"
                theme: root.theme

                onTriggered: source => {
                    void source;
                    root.controller.dismissGroup(root.group.groupKey);
                }
            }
        }
        HoverHandler {
            id: pointer
        }
        TapHandler {
            acceptedButtons: Qt.LeftButton

            onTapped: root.controller.toggleGroup(root.group.groupKey)
        }
    }
}
