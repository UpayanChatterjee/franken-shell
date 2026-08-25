pragma ComponentBehavior: Bound

import QtQuick

import "../controlcenter" as ControlCenter

FocusScope {
    id: root

    readonly property bool canDismiss: !root.protectedOperation
    property var controller: null
    readonly property bool protectedOperation: root.controller?.credentialRequest?.active === true
    required property var theme

    function cancelTask(taskId: string): bool {
        return root.controller?.cancelTask(taskId)?.accepted === true;
    }
    function clearTransient() {
        if (root.protectedOperation)
            root.controller.cancelCredential();
    }
    function handleEscape(): bool {
        if (!root.protectedOperation)
            return false;
        root.controller.cancelCredential();
        return true;
    }
    function networkRows(): var {
        return (root.controller?.visibleNetworks ?? []).concat(root.controller?.savedNetworks ?? []);
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
                    anchors.right: scanAction.left
                    anchors.rightMargin: root.theme.spacing.space3
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: root.theme.spacing.space1

                    Text {
                        color: root.theme.colors.textPrimary
                        elide: Text.ElideRight
                        font.family: root.theme.typography.fontFamily
                        font.pixelSize: root.theme.typography.fontSizeLabel
                        font.weight: root.theme.typography.fontWeightMedium
                        text: root.controller?.available === true ? String(root.controller?.quickSummary ?? qsTr("Network ready")) : qsTr("Network unavailable")
                        width: parent.width
                    }
                    Text {
                        color: String(root.controller?.lastError ?? "").length > 0 ? root.theme.colors.critical : root.theme.colors.textSecondary
                        elide: Text.ElideRight
                        font.family: root.theme.typography.fontFamily
                        font.pixelSize: root.theme.typography.fontSizeBody
                        text: String(root.controller?.lastError ?? "").length > 0 ? String(root.controller.lastError) : root.controller?.wifiHardwareAvailable === false ? qsTr("No Wi-Fi hardware") : root.controller?.wifiEnabled === false ? qsTr("Wi-Fi is off") : qsTr("Choose a network to connect.")
                        width: parent.width
                    }
                }
                ControlCenter.ControlCenterActionButton {
                    id: scanAction

                    anchors.right: parent.right
                    anchors.rightMargin: root.theme.spacing.space3
                    anchors.verticalCenter: parent.verticalCenter
                    enabled: root.controller?.available === true && root.controller?.wifiEnabled === true && root.controller?.scanState !== "scanning"
                    label: root.controller?.scanState === "scanning" ? qsTr("Scanning") : qsTr("Scan")
                    theme: root.theme

                    onTriggered: source => {
                        void source;
                        root.controller.requestScan();
                    }
                }
            }
            Rectangle {
                border.color: root.theme.colors.outlineSubtle
                border.width: root.theme.metrics.outlineWidth
                color: root.theme.colors.accentContainer
                height: credentialContent.implicitHeight + 2 * root.theme.spacing.space3
                radius: root.theme.radius.radiusLarge
                visible: root.protectedOperation
                width: parent.width

                Column {
                    id: credentialContent

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
                        text: qsTr("Password needed for %1").arg(String(root.controller?.credentialRequest?.networkName ?? ""))
                        width: parent.width
                    }
                    Rectangle {
                        border.color: credentialInput.activeFocus ? root.theme.colors.outlineFocus : root.theme.colors.outlineSubtle
                        border.width: credentialInput.activeFocus ? root.theme.metrics.focusRingWidth : root.theme.metrics.outlineWidth
                        color: root.theme.colors.surfaceBase
                        height: 40
                        radius: root.theme.radius.radiusMedium
                        width: parent.width

                        TextInput {
                            id: credentialInput

                            anchors.fill: parent
                            anchors.leftMargin: root.theme.spacing.space3
                            anchors.rightMargin: root.theme.spacing.space3
                            color: root.theme.colors.textPrimary
                            echoMode: TextInput.Password
                            font.family: root.theme.typography.fontFamily
                            font.pixelSize: root.theme.typography.fontSizeBody
                            selectByMouse: true

                            Keys.onReturnPressed: event => {
                                root.controller.submitCredential(text);
                                event.accepted = true;
                            }
                        }
                    }
                    Row {
                        spacing: root.theme.spacing.space2

                        ControlCenter.ControlCenterActionButton {
                            emphasized: true
                            label: qsTr("Connect")
                            theme: root.theme

                            onTriggered: source => {
                                void source;
                                root.controller.submitCredential(credentialInput.text);
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
                height: networkContent.implicitHeight + 2 * root.theme.spacing.space3
                radius: root.theme.radius.radiusLarge
                width: parent.width

                Column {
                    id: networkContent

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
                        text: qsTr("Networks")
                        width: parent.width
                    }
                    Repeater {
                        model: root.networkRows()

                        delegate: Rectangle {
                            id: networkRow

                            required property var modelData

                            color: networkRow.modelData?.connected === true ? root.theme.colors.accentContainer : root.theme.colors.surfaceRaised
                            height: 60
                            radius: root.theme.radius.radiusMedium
                            width: networkContent.width

                            Column {
                                anchors.left: parent.left
                                anchors.leftMargin: root.theme.spacing.space3
                                anchors.right: networkAction.left
                                anchors.rightMargin: root.theme.spacing.space2
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: root.theme.spacing.space1

                                Text {
                                    color: networkRow.modelData?.connected === true ? root.theme.colors.accentOnContainer : root.theme.colors.textPrimary
                                    elide: Text.ElideRight
                                    font.family: root.theme.typography.fontFamily
                                    font.pixelSize: root.theme.typography.fontSizeBody
                                    font.weight: root.theme.typography.fontWeightMedium
                                    text: String(networkRow.modelData?.name ?? qsTr("Unknown network"))
                                    width: parent.width
                                }
                                Text {
                                    color: networkRow.modelData?.connected === true ? root.theme.colors.accentOnContainer : root.theme.colors.textSecondary
                                    elide: Text.ElideRight
                                    font.family: root.theme.typography.fontFamily
                                    font.pixelSize: root.theme.typography.fontSizeMetricSmall
                                    text: networkRow.modelData?.connected === true ? qsTr("Connected") : String(networkRow.modelData?.security ?? qsTr("Unknown security"))
                                    width: parent.width
                                }
                            }
                            ControlCenter.ControlCenterActionButton {
                                id: networkAction

                                anchors.right: parent.right
                                anchors.rightMargin: root.theme.spacing.space2
                                anchors.verticalCenter: parent.verticalCenter
                                enabled: root.controller?.available === true && !root.protectedOperation
                                label: networkRow.modelData?.connected === true ? qsTr("Disconnect") : qsTr("Connect")
                                theme: root.theme

                                onTriggered: source => {
                                    void source;
                                    if (networkRow.modelData?.connected === true)
                                        root.controller.disconnectNetwork(String(networkRow.modelData?.id ?? ""));
                                    else
                                        root.controller.connectNetwork(String(networkRow.modelData?.id ?? ""));
                                }
                            }
                        }
                    }
                    Text {
                        color: root.theme.colors.textSecondary
                        font.family: root.theme.typography.fontFamily
                        font.pixelSize: root.theme.typography.fontSizeBody
                        text: root.controller?.available === true ? qsTr("No networks reported yet.") : qsTr("The rest of the control centre remains available.")
                        visible: root.networkRows().length === 0
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
