import QtQuick

FocusScope {
    id: root

    readonly property string anchorId: "bar." + root.datum.id + "." + root.safeToken(root.monitorId)
    property var audioController: null
    property var batteryController: null
    required property var datum
    readonly property string effectiveAccessibleName: root.isTray && root.trayController !== null ? root.trayController.accessibleName() : root.isAudio ? root.audioAccessibleName() : root.isBattery ? root.batteryAccessibleName() : root.isNetworkSpeed && root.throughputController !== null ? root.throughputController.formattedTooltip : root.isResources && root.resourceController !== null ? root.resourceController.memoryDescription : root.datum.accessibleName
    readonly property string effectiveEmphasis: root.isTray && root.trayController?.hasAttention === true ? "warning" : root.isBattery && root.batteryController !== null ? root.batteryController.severity : root.datum.emphasis
    readonly property string effectiveLabel: root.isTray && root.trayController !== null ? "T" : root.isAudio ? root.audioLabel() : root.isBattery && root.batteryController !== null ? root.batteryController.label : root.isNetworkSpeed && root.throughputController !== null ? root.throughputController.formattedDownload : root.isResources && root.resourceController !== null ? root.resourceController.label : root.datum.label
    readonly property string effectivePopoverId: root.isTray && root.trayController !== null ? "tray.drawer" : root.datum.popoverId
    readonly property bool effectiveVisible: root.isTray && root.trayController !== null ? root.trayController.visible : root.isBattery && root.batteryController !== null ? root.batteryController.visible : root.datum.visible
    required property real extent
    readonly property bool isAudio: root.datum.id === "audio"
    readonly property bool isBattery: root.datum.id === "battery"
    readonly property bool isNetworkSpeed: root.datum.id === "networkSpeed"
    readonly property bool isResources: root.datum.id === "resources"
    readonly property bool isTray: root.datum.id === "tray"
    required property string monitorId
    readonly property bool popoverOpen: root.effectivePopoverId.length > 0 && root.surfaceCoordinator?.activePopoverId === root.effectivePopoverId && root.surfaceCoordinator?.activePopover?.anchorId === root.anchorId
    property var resourceController: null
    required property var surfaceCoordinator
    required property var theme
    property var throughputController: null
    property var trayController: null
    required property bool vertical

    function activate(origin: string): var {
        if (root.effectivePopoverId.length === 0 || !root.effectiveVisible)
            return Object.freeze({
                "accepted": false,
                "changed": false,
                "errorCode": "FIXTURE_ACTION_UNAVAILABLE"
            });
        return root.surfaceCoordinator.togglePopover(root.effectivePopoverId, root.anchorId, {
            "monitorId": root.monitorId,
            "origin": origin,
            "originControlId": root.anchorId,
            "previousFocusToken": "",
            "takesFocus": origin === "keyboard"
        });
    }
    function audioAccessibleName(): string {
        if (root.audioController?.available !== true)
            return qsTr("Audio unavailable");
        const outputName = String(root.audioController.defaultOutput?.description ?? root.audioController.defaultOutput?.name ?? qsTr("Unknown output"));
        const state = root.audioController.masterMuted ? qsTr("muted") : qsTr("%1 percent").arg(Math.round(root.audioController.masterVolume * 100));
        return qsTr("Audio, %1, %2").arg(outputName).arg(state);
    }
    function audioLabel(): string {
        if (root.audioController?.available !== true)
            return "–";
        switch (root.audioController.outputCategory) {
        case "muted":
            return "M";
        case "speaker":
            return "SP";
        case "wiredHeadphones":
            return "HP";
        case "bluetoothHeadphones":
            return "BT";
        case "headset":
            return "HS";
        case "hdmi":
            return "HD";
        case "usbDac":
            return "US";
        default:
            return "?";
        }
    }
    function batteryAccessibleName(): string {
        if (root.batteryController?.adapter?.available !== true)
            return qsTr("Battery state unavailable");
        const percentage = Math.round(root.batteryController.adapter.percentage);
        const status = root.batteryController.adapter.charging ? qsTr("charging") : root.batteryController.adapter.chargingState === "discharging" ? qsTr("discharging") : qsTr("battery");
        return qsTr("Battery, %1 percent, %2").arg(percentage).arg(status);
    }
    function queueAudioVolumeSteps(steps: int): bool {
        if (!root.isAudio || root.audioController?.available !== true || steps === 0)
            return false;
        root.audioController.queueVolumeSteps(steps);
        return true;
    }
    function safeToken(value: string): string {
        const sanitized = value.replace(/[^A-Za-z0-9._:-]/g, "_");
        return sanitized.length > 0 ? sanitized : "unresolved";
    }
    function toggleAudioMute(): bool {
        if (!root.isAudio || root.audioController?.available !== true)
            return false;
        return root.audioController.toggleMasterMute()?.accepted === true;
    }

    Accessible.name: root.effectiveAccessibleName
    Accessible.role: root.effectivePopoverId.length > 0 ? Accessible.Button : Accessible.StaticText
    activeFocusOnTab: root.effectivePopoverId.length > 0 && root.effectiveVisible
    clip: true
    height: root.vertical ? root.extent : parent.height
    visible: root.effectiveVisible
    width: root.vertical ? parent.width : root.extent

    Keys.onEnterPressed: event => {
        root.activate("keyboard");
        event.accepted = true;
    }
    Keys.onReturnPressed: event => {
        root.activate("keyboard");
        event.accepted = true;
    }
    Keys.onSpacePressed: event => {
        root.activate("keyboard");
        event.accepted = true;
    }

    Rectangle {
        anchors.fill: parent
        color: root.popoverOpen ? root.theme.colors.accentContainer : pointer.hovered && root.effectivePopoverId.length > 0 ? root.theme.colors.surfaceRaised : "transparent"
        radius: root.popoverOpen ? root.theme.radius.radiusFull : root.theme.radius.radiusSmall

        Rectangle {
            anchors.fill: parent
            anchors.margins: root.theme.spacing.space1
            border.color: root.activeFocus ? root.theme.colors.outlineFocus : root.effectiveEmphasis === "privacy" ? root.theme.colors.privacy : root.effectiveEmphasis === "critical" ? root.theme.colors.critical : "transparent"
            border.width: root.activeFocus ? root.theme.metrics.focusRingWidth : root.effectiveEmphasis === "privacy" || root.effectiveEmphasis === "critical" ? root.theme.metrics.outlineWidth : 0
            color: "transparent"
            radius: parent.radius
        }
        Text {
            anchors.fill: parent
            anchors.margins: root.theme.spacing.space1
            color: root.popoverOpen ? root.theme.colors.accentOnContainer : root.effectiveEmphasis === "privacy" ? root.theme.colors.privacy : root.effectiveEmphasis === "critical" ? root.theme.colors.critical : root.effectiveEmphasis === "warning" ? root.theme.colors.warning : root.effectiveEmphasis === "charging" ? root.theme.colors.accentPrimary : root.theme.colors.textPrimary
            elide: Text.ElideRight
            font.family: root.theme.typography.fontFamily
            font.features: ({
                    "tnum": 1
                })
            font.pixelSize: root.datum.emphasis === "metric" || root.isBattery ? root.theme.typography.fontSizeMetricSmall : root.theme.typography.fontSizeLabel
            font.weight: root.popoverOpen ? root.theme.typography.fontWeightSemibold : root.theme.typography.fontWeightMedium
            horizontalAlignment: Text.AlignHCenter
            text: root.effectiveLabel
            verticalAlignment: Text.AlignVCenter
        }
        HoverHandler {
            id: pointer
        }
        TapHandler {
            acceptedButtons: Qt.LeftButton
            enabled: root.effectivePopoverId.length > 0 && root.effectiveVisible

            onTapped: root.activate("pointer")
        }
        TapHandler {
            acceptedButtons: Qt.MiddleButton
            enabled: root.isAudio && root.audioController?.available === true

            onTapped: root.toggleAudioMute()
        }
        WheelHandler {
            enabled: root.isAudio && root.audioController?.available === true

            onWheel: event => {
                root.queueAudioVolumeSteps(event.angleDelta.y > 0 ? 1 : -1);
                event.accepted = true;
            }
        }
    }
}
