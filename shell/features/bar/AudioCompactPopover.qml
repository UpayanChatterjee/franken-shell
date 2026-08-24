import QtQuick

FocusScope {
    id: root

    required property var controller
    required property bool keyboardOpened
    required property var theme

    function adjust(steps: int, origin: string) {
        if (root.controller?.available !== true)
            return;
        root.controller.setMasterVolume(root.controller.masterVolume + steps * root.controller.volumeStep, {
            "origin": origin
        });
    }

    implicitHeight: content.implicitHeight + 2 * root.theme.spacing.space3
    implicitWidth: Math.min(root.theme.metrics.popoverMaxWidth, 300)

    Component.onCompleted: {
        if (root.keyboardOpened)
            Qt.callLater(muteAction.forceActiveFocus);
    }

    Column {
        id: content

        anchors.fill: parent
        anchors.margins: root.theme.spacing.space3
        spacing: root.theme.spacing.space2

        Text {
            color: root.theme.colors.textPrimary
            font.family: root.theme.typography.fontFamily
            font.pixelSize: root.theme.typography.fontSizeTitle
            font.weight: root.theme.typography.fontWeightSemibold
            text: qsTr("Audio")
            width: parent.width
        }
        Text {
            color: root.controller?.available === true ? root.theme.colors.textSecondary : root.theme.colors.warning
            elide: Text.ElideRight
            font.family: root.theme.typography.fontFamily
            font.pixelSize: root.theme.typography.fontSizeBody
            text: root.controller?.available === true ? String(root.controller.defaultOutput?.description ?? root.controller.defaultOutput?.name ?? qsTr("Current output")) : qsTr("Audio service unavailable")
            width: parent.width
        }
        Rectangle {
            color: root.theme.colors.outlineSubtle
            height: 8
            radius: root.theme.radius.radiusFull
            visible: root.controller?.available === true
            width: parent.width

            Rectangle {
                color: root.controller?.masterMuted === true ? root.theme.colors.textDisabled : root.theme.colors.accentPrimary
                height: parent.height
                radius: parent.radius
                width: parent.width * Math.max(0, Math.min(1, root.controller?.masterVolume ?? 0))
            }
            WheelHandler {
                onWheel: event => {
                    root.adjust(event.angleDelta.y > 0 ? 1 : -1, "pointer");
                    event.accepted = true;
                }
            }
        }
        Text {
            color: root.theme.colors.textSecondary
            font.family: root.theme.typography.fontFamily
            font.features: ({
                    "tnum": 1
                })
            font.pixelSize: root.theme.typography.fontSizeMetricSmall
            horizontalAlignment: Text.AlignRight
            text: qsTr("%1%").arg(Math.round((root.controller?.masterVolume ?? 0) * 100))
            visible: root.controller?.available === true
            width: parent.width
        }
        PopoverAction {
            id: muteAction

            detail: root.controller?.masterMuted === true ? qsTr("Muted") : qsTr("On")
            enabled: root.controller?.available === true
            label: qsTr("Output")
            theme: root.theme
            width: parent.width

            Keys.onDownPressed: event => {
                root.adjust(-1, "keyboard");
                event.accepted = true;
            }
            Keys.onLeftPressed: event => {
                root.adjust(-1, "keyboard");
                event.accepted = true;
            }
            Keys.onRightPressed: event => {
                root.adjust(1, "keyboard");
                event.accepted = true;
            }
            Keys.onUpPressed: event => {
                root.adjust(1, "keyboard");
                event.accepted = true;
            }
            onTriggered: origin => root.controller.toggleMasterMute({
                    "origin": origin
                })
        }
    }
}
