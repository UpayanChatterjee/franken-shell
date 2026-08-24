pragma ComponentBehavior: Bound

import QtQuick

FocusScope {
    id: root

    required property var record
    required property var service
    required property var theme

    signal focused(string key)

    function focusInitial() {
        if (actions.count > 0)
            actions.itemAt(0)?.forceActiveFocus();
        else
            root.forceActiveFocus();
    }

    Accessible.name: root.record.summary
    Accessible.role: Accessible.AlertMessage
    activeFocusOnTab: true
    implicitHeight: content.implicitHeight + 2 * root.theme.spacing.space3
    implicitWidth: 340

    Keys.onDeletePressed: event => {
        root.service.dismiss(root.record.key);
        event.accepted = true;
    }
    onActiveFocusChanged: {
        const focusedNow = root.activeFocus;
        Qt.callLater(() => {
            if (focusedNow) {
                root.service.pause(root.record.key, "focus");
                root.focused(root.record.key);
            } else {
                root.service.resume(root.record.key, "focus");
            }
        });
    }

    Rectangle {
        anchors.fill: parent
        border.color: root.activeFocus ? root.theme.colors.outlineFocus : root.record.severity === "failure" ? root.theme.colors.critical : root.theme.colors.outlineStrong
        border.width: root.activeFocus ? root.theme.metrics.focusRingWidth : root.theme.metrics.outlineWidth
        color: root.theme.colors.surfacePopup
        opacity: root.theme.opacity.popover
        radius: root.theme.radius.radiusMedium

        Column {
            id: content

            anchors.left: parent.left
            anchors.leftMargin: root.theme.spacing.space3
            anchors.right: parent.right
            anchors.rightMargin: root.theme.spacing.space3
            anchors.verticalCenter: parent.verticalCenter
            spacing: root.theme.spacing.space2

            Row {
                spacing: root.theme.spacing.space2
                width: parent.width

                Rectangle {
                    color: root.record.severity === "failure" ? root.theme.colors.critical : root.record.severity === "warning" ? root.theme.colors.warning : root.theme.colors.success
                    height: 10
                    radius: 5
                    width: 10
                }
                Text {
                    color: root.theme.colors.textPrimary
                    elide: Text.ElideRight
                    font.family: root.theme.typography.fontFamily
                    font.pixelSize: root.theme.typography.fontSizeBody
                    font.weight: root.theme.typography.fontWeightMedium
                    text: root.record.summary
                    width: Math.max(0, parent.width - 10 - closeButton.width - parent.spacing * 2)
                }
                FeedbackActionButton {
                    id: closeButton

                    Accessible.name: qsTr("Dismiss system toast")
                    implicitWidth: 36
                    label: "×"
                    theme: root.theme

                    onTriggered: root.service.dismiss(root.record.key)
                }
            }
            Text {
                color: root.theme.colors.textSecondary
                font.family: root.theme.typography.fontFamily
                font.pixelSize: root.theme.typography.fontSizeLabel
                text: root.record.detail
                visible: text.length > 0
                width: parent.width
                wrapMode: Text.Wrap
            }
            Row {
                spacing: root.theme.spacing.space2
                visible: actions.count > 0

                Repeater {
                    id: actions

                    model: root.record.actions

                    delegate: FeedbackActionButton {
                        required property var modelData

                        label: modelData.label
                        theme: root.theme

                        onTriggered: root.service.invokeAction(root.record.key, modelData.id)
                    }
                }
            }
        }
        HoverHandler {
            id: pointer

            onHoveredChanged: {
                if (hovered)
                    root.service.pause(root.record.key, "hover");
                else
                    root.service.resume(root.record.key, "hover");
            }
        }
    }
}
