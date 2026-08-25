pragma ComponentBehavior: Bound

import QtQuick

import "../controlcenter" as ControlCenter

FocusScope {
    id: root

    readonly property bool canDismiss: !root.protectedOperation
    property var controller: null
    readonly property bool protectedOperation: root.controller?.pairingRequest?.active === true
    required property var theme

    function cancelTask(taskId: string): bool {
        return root.controller?.cancelTask(taskId)?.accepted === true;
    }
    function clearTransient() {
        if (root.protectedOperation)
            root.controller.cancelPairingPrompt();
    }
    function deviceAction(device): var {
        if (device?.connected === true)
            return root.controller.disconnectDevice(String(device.id ?? ""));
        if (device?.paired === true)
            return root.controller.connectDevice(String(device.id ?? ""));
        return root.controller.pairDevice(String(device?.id ?? ""));
    }
    function deviceActionLabel(device): string {
        if (device?.connected === true)
            return qsTr("Disconnect");
        if (device?.paired === true)
            return qsTr("Connect");
        return qsTr("Pair");
    }
    function handleEscape(): bool {
        if (!root.protectedOperation)
            return false;
        root.clearTransient();
        return true;
    }
    function taskIsCancellable(task): bool {
        return ["pending", "awaitingInput"].indexOf(String(task?.state ?? "")) >= 0;
    }

    Flickable {
        id: viewport

        anchors.fill: parent
        boundsBehavior: Flickable.StopAtBounds
        clip: true
        contentHeight: content.implicitHeight
        contentWidth: width
        interactive: contentHeight > height

        Column {
            id: content

            spacing: root.theme.spacing.space3
            width: viewport.width

            Rectangle {
                border.color: root.theme.colors.outlineSubtle
                border.width: root.theme.metrics.outlineWidth
                color: root.theme.colors.surfaceRaised
                height: 88
                radius: root.theme.radius.radiusLarge
                width: parent.width

                Column {
                    anchors.left: parent.left
                    anchors.leftMargin: root.theme.spacing.space3
                    anchors.right: discoveryAction.left
                    anchors.rightMargin: root.theme.spacing.space3
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: root.theme.spacing.space1

                    Text {
                        color: root.theme.colors.textPrimary
                        elide: Text.ElideRight
                        font.family: root.theme.typography.fontFamily
                        font.pixelSize: root.theme.typography.fontSizeLabel
                        font.weight: root.theme.typography.fontWeightMedium
                        text: root.controller?.available === true ? String(root.controller?.quickSummary ?? qsTr("Bluetooth ready")) : qsTr("Bluetooth unavailable")
                        width: parent.width
                    }
                    Text {
                        color: String(root.controller?.lastError ?? "").length > 0 ? root.theme.colors.critical : root.theme.colors.textSecondary
                        elide: Text.ElideRight
                        font.family: root.theme.typography.fontFamily
                        font.pixelSize: root.theme.typography.fontSizeBody
                        text: String(root.controller?.lastError ?? "").length > 0 ? String(root.controller.lastError) : root.controller?.powered === false ? qsTr("Bluetooth is off") : qsTr("Nearby devices update while this page is open.")
                        width: parent.width
                    }
                }
                ControlCenter.ControlCenterActionButton {
                    id: discoveryAction

                    anchors.right: parent.right
                    anchors.rightMargin: root.theme.spacing.space3
                    anchors.verticalCenter: parent.verticalCenter
                    enabled: root.controller?.available === true && root.controller?.powered === true
                    label: root.controller?.discoveryState === "discovering" ? qsTr("Stop") : qsTr("Scan")
                    theme: root.theme

                    onTriggered: source => {
                        void source;
                        if (root.controller?.discoveryState === "discovering")
                            root.controller.stopDiscovery();
                        else
                            root.controller.startDiscovery();
                    }
                }
            }
            Rectangle {
                border.color: root.theme.colors.outlineSubtle
                border.width: root.theme.metrics.outlineWidth
                color: root.theme.colors.accentContainer
                height: pairingContent.implicitHeight + 2 * root.theme.spacing.space3
                radius: root.theme.radius.radiusLarge
                visible: root.protectedOperation
                width: parent.width

                Column {
                    id: pairingContent

                    anchors.left: parent.left
                    anchors.leftMargin: root.theme.spacing.space3
                    anchors.right: parent.right
                    anchors.rightMargin: root.theme.spacing.space3
                    anchors.top: parent.top
                    anchors.topMargin: root.theme.spacing.space3
                    spacing: root.theme.spacing.space2

                    Text {
                        color: root.theme.colors.accentOnContainer
                        font.family: root.theme.typography.fontFamily
                        font.pixelSize: root.theme.typography.fontSizeLabel
                        font.weight: root.theme.typography.fontWeightMedium
                        text: qsTr("Pair with %1").arg(String(root.controller?.pairingRequest?.deviceName ?? ""))
                        width: parent.width
                    }
                    Text {
                        color: root.theme.colors.accentOnContainer
                        font.family: root.theme.typography.fontFamily
                        font.pixelSize: root.theme.typography.fontSizeBody
                        text: root.controller?.pairingRequest?.kind === "confirmation" ? qsTr("Confirm code %1 on both devices.").arg(String(root.controller?.pairingRequest?.displayCode ?? "")) : qsTr("Enter the code shown by the device.")
                        visible: root.controller?.pairingRequest?.kind === "confirmation" || root.controller?.pairingRequest?.kind === "code"
                        width: parent.width
                        wrapMode: Text.Wrap
                    }
                    Rectangle {
                        border.color: pairingCode.activeFocus ? root.theme.colors.outlineFocus : root.theme.colors.outlineSubtle
                        border.width: pairingCode.activeFocus ? root.theme.metrics.focusRingWidth : root.theme.metrics.outlineWidth
                        color: root.theme.colors.surfaceBase
                        height: 40
                        radius: root.theme.radius.radiusMedium
                        visible: root.controller?.pairingRequest?.kind === "code"
                        width: parent.width

                        TextInput {
                            id: pairingCode

                            anchors.fill: parent
                            anchors.leftMargin: root.theme.spacing.space3
                            anchors.rightMargin: root.theme.spacing.space3
                            color: root.theme.colors.textPrimary
                            font.family: root.theme.typography.fontFamily
                            font.pixelSize: root.theme.typography.fontSizeBody
                            selectByMouse: true

                            Keys.onReturnPressed: event => {
                                root.controller.submitPairingCode(text);
                                event.accepted = true;
                            }
                        }
                    }
                    Row {
                        spacing: root.theme.spacing.space2

                        ControlCenter.ControlCenterActionButton {
                            emphasized: true
                            label: root.controller?.pairingRequest?.kind === "confirmation" ? qsTr("Confirm") : qsTr("Submit")
                            theme: root.theme

                            onTriggered: source => {
                                void source;
                                if (root.controller?.pairingRequest?.kind === "confirmation")
                                    root.controller.confirmPairing(true);
                                else
                                    root.controller.submitPairingCode(pairingCode.text);
                            }
                        }
                        ControlCenter.ControlCenterActionButton {
                            label: qsTr("Cancel")
                            theme: root.theme

                            onTriggered: source => {
                                void source;
                                root.clearTransient();
                            }
                        }
                    }
                }
            }
            Rectangle {
                border.color: root.theme.colors.outlineSubtle
                border.width: root.theme.metrics.outlineWidth
                color: root.theme.colors.surfaceOverlay
                height: deviceContent.implicitHeight + 2 * root.theme.spacing.space3
                radius: root.theme.radius.radiusLarge
                width: parent.width

                Column {
                    id: deviceContent

                    anchors.left: parent.left
                    anchors.leftMargin: root.theme.spacing.space3
                    anchors.right: parent.right
                    anchors.rightMargin: root.theme.spacing.space3
                    anchors.top: parent.top
                    anchors.topMargin: root.theme.spacing.space3
                    spacing: root.theme.spacing.space2

                    Text {
                        color: root.theme.colors.textPrimary
                        font.family: root.theme.typography.fontFamily
                        font.pixelSize: root.theme.typography.fontSizeLabel
                        font.weight: root.theme.typography.fontWeightMedium
                        text: qsTr("Devices")
                        width: parent.width
                    }
                    Repeater {
                        model: root.controller?.devices ?? []

                        delegate: Rectangle {
                            id: deviceRow

                            required property var modelData

                            color: deviceRow.modelData?.connected === true ? root.theme.colors.accentContainer : root.theme.colors.surfaceRaised
                            height: 64
                            radius: root.theme.radius.radiusMedium
                            width: deviceContent.width

                            Column {
                                anchors.left: parent.left
                                anchors.leftMargin: root.theme.spacing.space3
                                anchors.right: deviceAction.left
                                anchors.rightMargin: root.theme.spacing.space2
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: root.theme.spacing.space1

                                Text {
                                    color: deviceRow.modelData?.connected === true ? root.theme.colors.accentOnContainer : root.theme.colors.textPrimary
                                    elide: Text.ElideRight
                                    font.family: root.theme.typography.fontFamily
                                    font.pixelSize: root.theme.typography.fontSizeBody
                                    font.weight: root.theme.typography.fontWeightMedium
                                    text: String(deviceRow.modelData?.name ?? qsTr("Unknown device"))
                                    width: parent.width
                                }
                                Text {
                                    color: deviceRow.modelData?.connected === true ? root.theme.colors.accentOnContainer : root.theme.colors.textSecondary
                                    elide: Text.ElideRight
                                    font.family: root.theme.typography.fontFamily
                                    font.pixelSize: root.theme.typography.fontSizeMetricSmall
                                    text: deviceRow.modelData?.connected === true ? qsTr("Connected") : deviceRow.modelData?.paired === true ? qsTr("Paired") : qsTr("Available")
                                    width: parent.width
                                }
                            }
                            ControlCenter.ControlCenterActionButton {
                                id: deviceAction

                                anchors.right: parent.right
                                anchors.rightMargin: root.theme.spacing.space2
                                anchors.verticalCenter: parent.verticalCenter
                                enabled: root.controller?.available === true && root.controller?.powered === true && !root.protectedOperation
                                label: root.deviceActionLabel(deviceRow.modelData)
                                theme: root.theme

                                onTriggered: source => {
                                    void source;
                                    root.deviceAction(deviceRow.modelData);
                                }
                            }
                        }
                    }
                    Text {
                        color: root.theme.colors.textSecondary
                        font.family: root.theme.typography.fontFamily
                        font.pixelSize: root.theme.typography.fontSizeBody
                        text: root.controller?.available === true ? qsTr("No devices reported yet.") : qsTr("The rest of the control centre remains available.")
                        visible: (root.controller?.devices?.length ?? 0) === 0
                        width: parent.width
                    }
                }
            }
            Repeater {
                model: root.controller?.operationTasks ?? []

                delegate: Rectangle {
                    id: taskRow

                    required property var modelData

                    border.color: taskRow.modelData?.state === "failed" ? root.theme.colors.critical : root.theme.colors.outlineSubtle
                    border.width: root.theme.metrics.outlineWidth
                    color: root.theme.colors.surfaceOverlay
                    height: 52
                    radius: root.theme.radius.radiusMedium
                    width: content.width

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: root.theme.spacing.space3
                        anchors.right: cancelTask.left
                        anchors.rightMargin: root.theme.spacing.space2
                        anchors.verticalCenter: parent.verticalCenter
                        color: taskRow.modelData?.state === "failed" ? root.theme.colors.critical : root.theme.colors.textSecondary
                        elide: Text.ElideRight
                        font.family: root.theme.typography.fontFamily
                        font.pixelSize: root.theme.typography.fontSizeBody
                        text: qsTr("%1: %2").arg(String(taskRow.modelData?.kind ?? qsTr("Task"))).arg(String(taskRow.modelData?.state ?? ""))
                    }
                    ControlCenter.ControlCenterActionButton {
                        id: cancelTask

                        anchors.right: parent.right
                        anchors.rightMargin: root.theme.spacing.space2
                        anchors.verticalCenter: parent.verticalCenter
                        enabled: root.taskIsCancellable(taskRow.modelData)
                        label: qsTr("Cancel")
                        theme: root.theme
                        visible: enabled

                        onTriggered: source => {
                            void source;
                            root.cancelTask(String(taskRow.modelData?.taskId ?? ""));
                        }
                    }
                }
            }
        }
    }
}
