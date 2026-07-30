import QtQuick
import "../features/controlcenter" as ControlCenter

Item {
    id: root

    required property var controlCenterConfig
    readonly property real drawerWidth: {
        const configured = root.controlCenterConfig?.width ?? "auto";
        const requested = typeof configured === "number" ? configured : root.theme.metrics.controlCenterWidth;
        return Math.max(1, Math.min(root.width, requested));
    }
    readonly property bool hostEnabled: root.controlCenterConfig?.enabled === true && root.monitor?.connected === true
    readonly property bool keyboardActive: root.owned && root.surfaceCoordinator.activeMajor?.origin === "keyboard"
    required property var monitor
    readonly property bool open: root.hostEnabled && root.owned
    readonly property bool owned: root.surfaceCoordinator?.activeMajorId === "controlCenter" && root.surfaceCoordinator?.activeMajor?.ownerMonitorId === root.ownerMonitorId
    readonly property string ownerMonitorId: root.monitor?.runtimeId ?? ""
    readonly property real revealProgress: root.open ? 1 : 0
    readonly property bool scrimVisible: root.open && root.controlCenterConfig?.scrim?.enabled !== false
    required property var surfaceCoordinator
    required property var theme
    readonly property bool windowVisible: root.open

    signal fixtureCaptured(string path, bool saved)

    function captureFixture(path: string) {
        root.grabToImage(result => {
            root.fixtureCaptured(path, result.saveToFile(path));
        });
    }
    function context(origin: string, originControlId: string): var {
        return {
            "monitorId": root.ownerMonitorId,
            "origin": origin,
            "originControlId": originControlId,
            "previousFocusToken": "",
            "takesFocus": origin === "keyboard"
        };
    }
    function dismissOutside(): var {
        if (!root.open || root.controlCenterConfig?.scrim?.dismissOnClick === false)
            return root.result(false);
        return root.surfaceCoordinator.closeMajor("outsideClick");
    }
    function focusInitial() {
        if (root.keyboardActive)
            placeholder.focusInitial();
    }
    function handleEscape(): var {
        return root.open ? root.surfaceCoordinator.closeMajor("escape") : root.result(false);
    }
    function rejection(errorCode: string): var {
        return Object.freeze({
            "accepted": false,
            "changed": false,
            "errorCode": errorCode
        });
    }
    function requestOpen(origin: string, originControlId: string): var {
        if (!root.hostEnabled)
            return root.rejection("CONTROL_CENTER_HOST_DISABLED");
        return root.surfaceCoordinator.openMajor("controlCenter", root.context(origin, originControlId));
    }
    function requestToggle(origin: string, originControlId: string): var {
        if (!root.owned && !root.hostEnabled)
            return root.rejection("CONTROL_CENTER_HOST_DISABLED");
        return root.surfaceCoordinator.toggleMajor("controlCenter", root.context(origin, originControlId));
    }
    function result(changed: bool): var {
        return Object.freeze({
            "accepted": true,
            "changed": changed,
            "errorCode": ""
        });
    }
    function summary(): var {
        return Object.freeze({
            "monitorId": root.ownerMonitorId,
            "open": root.open,
            "visible": root.windowVisible,
            "keyboardActive": root.keyboardActive,
            "initialFocusActive": placeholder.initialFocusActive,
            "revealProgress": root.revealProgress,
            "drawerWidth": root.drawerWidth,
            "scrimVisible": root.scrimVisible,
            "exclusionMode": "Ignore",
            "exclusiveZone": 0,
            "primitive": "PanelWindow",
            "rightAttached": true
        });
    }

    Keys.onEscapePressed: event => {
        root.handleEscape();
        event.accepted = true;
    }
    onOwnedChanged: {
        if (root.owned && !root.hostEnabled)
            root.surfaceCoordinator.closeMajor("hostUnavailable");
    }

    Rectangle {
        anchors.fill: parent
        color: root.theme.colors.surfaceScrim
        visible: root.scrimVisible

        TapHandler {
            acceptedButtons: Qt.LeftButton

            onTapped: root.dismissOutside()
        }
    }
    FocusScope {
        id: drawer

        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.top: parent.top
        focus: root.keyboardActive
        width: root.drawerWidth

        Rectangle {
            anchors.fill: parent
            border.color: root.theme.colors.outlineSubtle
            border.width: root.theme.metrics.outlineWidth
            bottomRightRadius: 0
            color: Qt.alpha(root.theme.colors.surfaceBase, root.theme.opacity.controlCenter)
            radius: root.theme.radius.radiusLarge
            topRightRadius: 0

            TapHandler {
                acceptedButtons: Qt.LeftButton

                onTapped: eventPoint => {
                    void eventPoint;
                }
            }
        }
        ControlCenter.ControlCenterPlaceholder {
            id: placeholder

            anchors.fill: parent
            focus: root.keyboardActive
            theme: root.theme

            onCloseRequested: root.surfaceCoordinator.closeMajor("requested")
        }
    }
}
