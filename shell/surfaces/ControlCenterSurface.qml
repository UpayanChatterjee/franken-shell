pragma ComponentBehavior: Bound

import QtQuick
import "../features/controlcenter" as ControlCenter

Item {
    id: root

    readonly property var content: contentLoader.status === Loader.Ready ? contentLoader.item : null
    required property var contentModel
    readonly property bool contentReady: root.content !== null
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
    required property var revealController
    readonly property real revealProgress: root.revealController?.revealProgress ?? 0
    readonly property bool scrimVisible: root.open && root.revealProgress > 0 && root.controlCenterConfig?.scrim?.enabled !== false
    required property var surfaceCoordinator
    required property var theme
    readonly property bool windowVisible: root.open

    signal fixtureCaptured(string path, bool saved)
    signal headerActionRequested(string actionId, string source)
    signal quickControlActionRequested(string controlId, string action, string source)
    signal sliderActionRequested(string sliderId, int step, string source)

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
        if (root.keyboardActive && root.contentReady)
            root.content.focusInitial();
    }
    function handleEscape(): var {
        settleAnimation.stop();
        if (!root.open || !root.contentReady)
            return root.result(false);
        const wasOpen = root.open;
        const navigationResult = root.content.handleEscape();
        return root.result(navigationResult.handled || wasOpen && !root.open);
    }
    function openPage(pageId: string, invokerFocusId: string, source: string): bool {
        return root.open && root.contentReady && root.content.openPage(pageId, invokerFocusId, source);
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
    function requestQuickControlAction(controlId: string, action: string, source: string): bool {
        return root.open && root.contentReady && root.content.requestQuickControlAction(controlId, action, source);
    }
    function requestSliderStep(sliderId: string, step: int, source: string): bool {
        return root.open && root.contentReady && root.content.requestSliderStep(sliderId, step, source);
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
    function selectTab(tabId: string, source: string): bool {
        return root.open && root.contentReady && root.content.selectTab(tabId, source);
    }
    function summary(): var {
        const contentSummary = root.contentReady ? root.content.summary() : Object.freeze({
            "activePage": "main",
            "activeTab": "notifications",
            "focusedControlId": "",
            "stackDepth": 0
        });
        return Object.freeze({
            "activePage": contentSummary.activePage,
            "activeTab": contentSummary.activeTab,
            "monitorId": root.ownerMonitorId,
            "open": root.open,
            "visible": root.windowVisible,
            "keyboardActive": root.keyboardActive,
            "focusedControlId": contentSummary.focusedControlId,
            "initialFocusActive": contentSummary.focusedControlId === "quick.wifi",
            "navigationStackDepth": contentSummary.stackDepth,
            "revealProgress": root.revealProgress,
            "revealState": root.revealController.state,
            "revealVelocity": root.revealController.velocity,
            "gestureDrawerWidth": root.revealController.drawerWidth,
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
        if (root.owned && !root.hostEnabled) {
            root.surfaceCoordinator.closeMajor("hostUnavailable");
        } else if (root.owned && root.revealController.state === "closed") {
            root.revealController.showOpen();
        } else if (!root.owned) {
            settleAnimation.stop();
            root.revealController.resetClosed();
            if (root.contentReady)
                root.content.resetSession();
        }
    }

    Connections {
        function onSettleRequested(targetProgress) {
            settleAnimation.stop();
            settleAnimation.from = root.revealProgress;
            settleAnimation.to = targetProgress;
            settleAnimation.start();
        }

        target: root.revealController
    }
    NumberAnimation {
        id: settleAnimation

        duration: root.theme?.motion?.durationFast ?? 120
        easing.type: root.theme?.motion?.easingDecelerate ?? Easing.OutCubic
        property: "revealProgress"
        target: root.revealController

        onStopped: {
            if (root.revealController.settling)
                root.revealController.completeSettle();
        }
    }
    Rectangle {
        anchors.fill: parent
        color: {
            const base = root.theme.colors.surfaceScrim;
            return Qt.rgba(base.r, base.g, base.b, base.a * root.revealProgress);
        }
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

        transform: Translate {
            x: drawer.width * (1 - root.revealProgress)
        }

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
        Loader {
            id: contentLoader

            active: root.theme !== null && root.contentModel !== null
            anchors.fill: parent
            anchors.margins: root.theme?.spacing?.space4 ?? 16
            sourceComponent: contentComponent
        }
        Component {
            id: contentComponent

            ControlCenter.ControlCenterContent {
                contentModel: root.contentModel
                focus: root.keyboardActive
                theme: root.theme

                onCloseRequested: root.surfaceCoordinator.closeMajor("escape")
                onHeaderActionRequested: (actionId, source) => root.headerActionRequested(actionId, source)
                onQuickControlActionRequested: (controlId, action, source) => root.quickControlActionRequested(controlId, action, source)
                onSliderActionRequested: (sliderId, step, source) => {
                    root.sliderActionRequested(sliderId, step, source);
                    if (typeof root.contentModel?.requestSliderStep === "function")
                        root.contentModel.requestSliderStep(sliderId, step, source);
                }
            }
        }
        Item {
            // Prototype-only noninteractive background rail; final close-drag
            // initiation geometry remains an open product question.
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.top: parent.top
            enabled: root.revealController.state === "open"
            width: Math.max(12, root.theme?.spacing?.space3 ?? 12)
            z: 1

            DragHandler {
                id: closeDrag

                acceptedButtons: Qt.LeftButton
                dragThreshold: 0
                enabled: parent.enabled
                target: null

                onActiveChanged: {
                    const nowMs = Date.now();
                    if (active)
                        root.revealController.beginCloseDrag(centroid.pressPosition.x, centroid.pressPosition.y, nowMs);
                    else if (root.revealController.state === "pressedOpen" || root.revealController.state === "draggingClosed")
                        root.revealController.release();
                }
                onCanceled: point => {
                    void point;
                    root.revealController.cancelPointerGesture("pointerCancelled");
                }
                onTranslationChanged: delta => {
                    void delta;
                    if (active)
                        root.revealController.updateDrag(centroid.pressPosition.x + activeTranslation.x, centroid.pressPosition.y + activeTranslation.y, Date.now());
                }
            }
        }
    }
}
