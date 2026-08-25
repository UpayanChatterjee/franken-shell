pragma ComponentBehavior: Bound

import QtQuick

import "../controlcenter" as ControlCenter

FocusScope {
    id: root

    property var audioController: null
    readonly property bool available: root.audioController?.available === true
    required property var theme
    readonly property bool usable: root.available && root.audioController?.stale !== true

    signal actionRequested(string actionId, string targetId, real value, string source)

    function outputName(output): string {
        return String(output?.description ?? output?.name ?? qsTr("Unknown output"));
    }
    function streamName(stream): string {
        return String(stream?.applicationName ?? stream?.name ?? stream?.mediaName ?? qsTr("Unknown stream"));
    }

    implicitHeight: Math.max(112, content.implicitHeight)

    Column {
        id: content

        spacing: root.theme.spacing.space3
        width: parent.width

        Rectangle {
            border.color: root.theme.colors.outlineSubtle
            border.width: root.theme.metrics.outlineWidth
            color: root.theme.colors.surfaceRaised
            height: 84
            radius: root.theme.radius.radiusLarge
            width: parent.width

            Column {
                anchors.left: parent.left
                anchors.leftMargin: root.theme.spacing.space3
                anchors.right: muteAction.left
                anchors.rightMargin: root.theme.spacing.space3
                anchors.verticalCenter: parent.verticalCenter
                spacing: root.theme.spacing.space1

                Text {
                    color: root.theme.colors.textPrimary
                    elide: Text.ElideRight
                    font.family: root.theme.typography.fontFamily
                    font.pixelSize: root.theme.typography.fontSizeLabel
                    font.weight: root.theme.typography.fontWeightMedium
                    text: qsTr("Master output")
                    width: parent.width
                }
                Text {
                    color: root.theme.colors.textSecondary
                    elide: Text.ElideRight
                    font.family: root.theme.typography.fontFamily
                    font.pixelSize: root.theme.typography.fontSizeBody
                    text: root.available ? root.outputName(root.audioController?.defaultOutput) : qsTr("PipeWire is unavailable")
                    width: parent.width
                }
            }
            ControlCenter.ControlCenterActionButton {
                id: muteAction

                anchors.right: parent.right
                anchors.rightMargin: root.theme.spacing.space3
                anchors.verticalCenter: parent.verticalCenter
                emphasized: root.audioController?.masterMuted === true
                enabled: root.usable
                label: root.audioController?.masterMuted === true ? qsTr("Unmute") : qsTr("Mute")
                theme: root.theme

                onTriggered: source => root.actionRequested("masterMute", "", 0, source)
            }
        }
        Rectangle {
            border.color: root.theme.colors.outlineSubtle
            border.width: root.theme.metrics.outlineWidth
            color: root.theme.colors.surfaceOverlay
            height: outputContent.implicitHeight + 2 * root.theme.spacing.space3
            radius: root.theme.radius.radiusLarge
            visible: root.available
            width: parent.width

            Column {
                id: outputContent

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
                    text: qsTr("Output device")
                    width: parent.width
                }
                Repeater {
                    model: root.audioController?.outputDevices ?? []

                    delegate: Rectangle {
                        id: outputRow

                        required property var modelData
                        readonly property bool selected: outputRow.modelData?.id === root.audioController?.defaultOutput?.id

                        color: outputRow.selected ? root.theme.colors.accentContainer : root.theme.colors.surfaceRaised
                        height: 48
                        radius: root.theme.radius.radiusMedium
                        width: outputContent.width

                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: root.theme.spacing.space3
                            anchors.right: selectOutput.left
                            anchors.rightMargin: root.theme.spacing.space2
                            anchors.verticalCenter: parent.verticalCenter
                            color: outputRow.selected ? root.theme.colors.accentOnContainer : root.theme.colors.textPrimary
                            elide: Text.ElideRight
                            font.family: root.theme.typography.fontFamily
                            font.pixelSize: root.theme.typography.fontSizeBody
                            text: root.outputName(outputRow.modelData)
                        }
                        ControlCenter.ControlCenterActionButton {
                            id: selectOutput

                            anchors.right: parent.right
                            anchors.rightMargin: root.theme.spacing.space2
                            anchors.verticalCenter: parent.verticalCenter
                            enabled: root.usable && !outputRow.selected
                            label: outputRow.selected ? qsTr("Using") : qsTr("Use")
                            theme: root.theme

                            onTriggered: source => root.actionRequested("defaultOutput", String(outputRow.modelData?.id ?? ""), 0, source)
                        }
                    }
                }
                Text {
                    color: root.theme.colors.textSecondary
                    font.family: root.theme.typography.fontFamily
                    font.pixelSize: root.theme.typography.fontSizeBody
                    text: qsTr("No output devices reported.")
                    visible: (root.audioController?.outputDevices?.length ?? 0) === 0
                    width: parent.width
                }
            }
        }
        Rectangle {
            border.color: root.theme.colors.outlineSubtle
            border.width: root.theme.metrics.outlineWidth
            color: root.theme.colors.surfaceOverlay
            height: inputContent.implicitHeight + 2 * root.theme.spacing.space3
            radius: root.theme.radius.radiusLarge
            visible: root.available
            width: parent.width

            Column {
                id: inputContent

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
                    text: qsTr("Input device")
                    width: parent.width
                }
                Repeater {
                    model: root.audioController?.inputDevices ?? []

                    delegate: Rectangle {
                        id: inputRow

                        required property var modelData
                        readonly property bool selected: inputRow.modelData?.id === root.audioController?.defaultInput?.id

                        color: inputRow.selected ? root.theme.colors.accentContainer : root.theme.colors.surfaceRaised
                        height: 48
                        radius: root.theme.radius.radiusMedium
                        width: inputContent.width

                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: root.theme.spacing.space3
                            anchors.right: selectInput.left
                            anchors.rightMargin: root.theme.spacing.space2
                            anchors.verticalCenter: parent.verticalCenter
                            color: inputRow.selected ? root.theme.colors.accentOnContainer : root.theme.colors.textPrimary
                            elide: Text.ElideRight
                            font.family: root.theme.typography.fontFamily
                            font.pixelSize: root.theme.typography.fontSizeBody
                            text: root.outputName(inputRow.modelData)
                        }
                        ControlCenter.ControlCenterActionButton {
                            id: selectInput

                            anchors.right: parent.right
                            anchors.rightMargin: root.theme.spacing.space2
                            anchors.verticalCenter: parent.verticalCenter
                            enabled: root.usable && !inputRow.selected
                            label: inputRow.selected ? qsTr("Using") : qsTr("Use")
                            theme: root.theme

                            onTriggered: source => root.actionRequested("defaultInput", String(inputRow.modelData?.id ?? ""), 0, source)
                        }
                    }
                }
                Text {
                    color: root.theme.colors.textSecondary
                    font.family: root.theme.typography.fontFamily
                    font.pixelSize: root.theme.typography.fontSizeBody
                    text: qsTr("No input devices reported.")
                    visible: (root.audioController?.inputDevices?.length ?? 0) === 0
                    width: parent.width
                }
            }
        }
        Rectangle {
            border.color: root.theme.colors.outlineSubtle
            border.width: root.theme.metrics.outlineWidth
            color: root.theme.colors.surfaceOverlay
            height: streamContent.implicitHeight + 2 * root.theme.spacing.space3
            radius: root.theme.radius.radiusLarge
            visible: root.available
            width: parent.width

            Column {
                id: streamContent

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
                    text: qsTr("Applications")
                    width: parent.width
                }
                Repeater {
                    model: root.audioController?.playbackStreams ?? []

                    delegate: Column {
                        id: streamRow

                        required property var modelData

                        spacing: root.theme.spacing.space1
                        width: streamContent.width

                        Row {
                            spacing: root.theme.spacing.space2
                            width: parent.width

                            Text {
                                color: root.theme.colors.textPrimary
                                elide: Text.ElideRight
                                font.family: root.theme.typography.fontFamily
                                font.pixelSize: root.theme.typography.fontSizeBody
                                text: root.streamName(streamRow.modelData)
                                width: Math.max(0, parent.width - streamMute.width - parent.spacing)
                            }
                            ControlCenter.ControlCenterActionButton {
                                id: streamMute

                                emphasized: streamRow.modelData?.muted === true
                                enabled: root.usable
                                label: streamRow.modelData?.muted === true ? qsTr("Unmute") : qsTr("Mute")
                                theme: root.theme

                                onTriggered: source => root.actionRequested("streamMute", String(streamRow.modelData?.id ?? ""), streamRow.modelData?.muted === true ? 0 : 1, source)
                            }
                        }
                        ControlCenter.ControlCenterSlider {
                            sliderId: "stream." + String(streamRow.modelData?.id ?? "")
                            sliderModel: ({
                                    "available": true,
                                    "enabled": root.usable,
                                    "label": qsTr("App volume"),
                                    "value": Number(streamRow.modelData?.volume ?? 0)
                                })
                            theme: root.theme
                            width: parent.width

                            onValueRequested: (value, source) => root.actionRequested("streamVolume", String(streamRow.modelData?.id ?? ""), value, source)
                        }
                    }
                }
                Text {
                    color: root.theme.colors.textSecondary
                    font.family: root.theme.typography.fontFamily
                    font.pixelSize: root.theme.typography.fontSizeBody
                    text: qsTr("No applications are playing audio.")
                    visible: (root.audioController?.playbackStreams?.length ?? 0) === 0
                    width: parent.width
                }
            }
        }
    }
}
