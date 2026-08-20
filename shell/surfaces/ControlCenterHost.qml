import QtQuick
import Quickshell
import "../features/controlcenter" as ControlCenter

Scope {
    id: root

    property var contentModel: null
    required property var controlCenterConfig
    readonly property var effectiveContentModel: root.contentModel ?? placeholderModel
    required property bool fixtureWindow
    required property var monitor
    readonly property string ownerMonitorId: root.window?.ownerMonitorId ?? ""
    readonly property bool ready: hostLoader.status === Loader.Ready
    required property ShellScreen screenInfo
    required property var surfaceCoordinator
    required property var theme
    readonly property bool visible: root.window?.visible ?? false
    readonly property var window: root.ready ? hostLoader.item : null

    signal fixtureCaptured(string path, bool saved)

    function captureFixture(path: string) {
        if (root.ready)
            root.window.captureFixture(path);
    }
    function dismissOutside(): var {
        return root.ready ? root.window.dismissOutside() : root.result(false);
    }
    function handleEscape(): var {
        return root.ready ? root.window.handleEscape() : root.result(false);
    }
    function requestCloseDragPress(x: real, y: real, nowMs: real): bool {
        return revealController.beginCloseDrag(x, y, nowMs);
    }
    function requestDragCancel(reason: string): bool {
        return revealController.cancel(reason);
    }
    function requestDragRelease(): bool {
        return revealController.release();
    }
    function requestDragUpdate(x: real, y: real, nowMs: real): bool {
        return revealController.updateDrag(x, y, nowMs);
    }
    function requestEdgePress(x: real, y: real, surfaceWidth: real, nowMs: real): bool {
        return revealController.beginEdgePress(x, y, surfaceWidth, root.monitor?.fullscreenActive === true, root.controlCenterConfig?.edgeDrag?.allowInFullscreen === true, nowMs);
    }
    function requestOpen(origin: string, originControlId: string): var {
        return root.ready ? root.window.requestOpen(origin, originControlId) : root.result(false);
    }
    function requestPage(pageId: string, invokerFocusId: string, source: string): bool {
        return root.ready ? root.window.openPage(pageId, invokerFocusId, source) : false;
    }
    function requestQuickControlAction(controlId: string, action: string, source: string): bool {
        return root.ready ? root.window.requestQuickControlAction(controlId, action, source) : false;
    }
    function requestSelectTab(tabId: string, source: string): bool {
        return root.ready ? root.window.selectTab(tabId, source) : false;
    }
    function requestSliderStep(sliderId: string, step: int, source: string): bool {
        return root.ready ? root.window.requestSliderStep(sliderId, step, source) : false;
    }
    function requestToggle(origin: string, originControlId: string): var {
        return root.ready ? root.window.requestToggle(origin, originControlId) : root.result(false);
    }
    function result(changed: bool): var {
        return Object.freeze({
            "accepted": false,
            "changed": changed,
            "errorCode": "CONTROL_CENTER_HOST_UNAVAILABLE"
        });
    }
    function summary(): var {
        return root.ready ? root.window.summary() : Object.freeze({
            "activePage": "main",
            "activeTab": "notifications",
            "monitorId": "",
            "open": false,
            "visible": false,
            "keyboardActive": false,
            "focusedControlId": "",
            "initialFocusActive": false,
            "navigationStackDepth": 0,
            "revealProgress": 0,
            "revealState": "closed",
            "revealVelocity": 0,
            "gestureDrawerWidth": 0,
            "drawerWidth": 0,
            "scrimVisible": false,
            "exclusionMode": "Ignore",
            "exclusiveZone": 0,
            "primitive": "PanelWindow",
            "rightAttached": true
        });
    }

    ControlCenter.ControlCenterRevealController {
        id: revealController

        activationWidth: root.controlCenterConfig?.edgeDrag?.activationWidth ?? 2
        drawerWidth: {
            const configured = root.controlCenterConfig?.width ?? "auto";
            const requested = typeof configured === "number" ? configured : root.theme?.metrics?.controlCenterWidth ?? 400;
            return Math.max(1, Math.min(root.screenInfo?.width ?? requested, requested));
        }
        enabled: root.controlCenterConfig?.enabled === true && root.controlCenterConfig?.edgeDrag?.enabled === true && root.monitor?.connected === true
        horizontalIntentRatio: root.controlCenterConfig?.edgeDrag?.horizontalIntentRatio ?? 1.5
        minimumDistance: root.controlCenterConfig?.edgeDrag?.minimumDistance ?? 24
        openThreshold: root.controlCenterConfig?.edgeDrag?.openThreshold ?? 0.35
        velocityThreshold: root.controlCenterConfig?.edgeDrag?.velocityThreshold ?? 900

        onCloseRequested: reason => {
            if (root.surfaceCoordinator?.activeMajorId === "controlCenter" && root.surfaceCoordinator?.activeMajor?.ownerMonitorId === root.monitor?.runtimeId)
                root.surfaceCoordinator.closeMajor(reason);
        }
        onOpenRequested: {
            const result = root.surfaceCoordinator.openMajor("controlCenter", {
                "monitorId": root.monitor?.runtimeId ?? "",
                "origin": "pointer",
                "originControlId": "edge.controlCenter",
                "previousFocusToken": "",
                "takesFocus": false
            });
            if (!result.accepted)
                revealController.cancel("surfaceRejected");
        }
    }
    ControlCenter.ControlCenterPlaceholderModel {
        id: placeholderModel
    }
    Loader {
        id: hostLoader

        active: true
        source: Qt.resolvedUrl(root.fixtureWindow ? "ControlCenterFixtureWindow.qml" : "ControlCenterPanelWindow.qml")
    }
    Loader {
        id: edgeHostLoader

        active: !root.fixtureWindow
        source: Qt.resolvedUrl("ControlCenterEdgeActivationWindow.qml")
    }
    Binding {
        property: "controlCenterConfig"
        target: root.window
        value: root.controlCenterConfig
        when: root.ready
    }
    Binding {
        property: "contentModel"
        target: root.window
        value: root.effectiveContentModel
        when: root.ready
    }
    Binding {
        property: "monitor"
        target: root.window
        value: root.monitor
        when: root.ready
    }
    Binding {
        property: "revealController"
        target: root.window
        value: revealController
        when: root.ready
    }
    Binding {
        property: "screenInfo"
        target: root.window
        value: root.screenInfo
        when: root.ready
    }
    Binding {
        property: "surfaceCoordinator"
        target: root.window
        value: root.surfaceCoordinator
        when: root.ready
    }
    Binding {
        property: "theme"
        target: root.window
        value: root.theme
        when: root.ready
    }
    Binding {
        property: "controlCenterConfig"
        target: edgeHostLoader.item
        value: root.controlCenterConfig
        when: edgeHostLoader.status === Loader.Ready
    }
    Binding {
        property: "monitor"
        target: edgeHostLoader.item
        value: root.monitor
        when: edgeHostLoader.status === Loader.Ready
    }
    Binding {
        property: "revealController"
        target: edgeHostLoader.item
        value: revealController
        when: edgeHostLoader.status === Loader.Ready
    }
    Binding {
        property: "screenInfo"
        target: edgeHostLoader.item
        value: root.screenInfo
        when: edgeHostLoader.status === Loader.Ready
    }
    Connections {
        function onFixtureCaptured(path, saved) {
            root.fixtureCaptured(path, saved);
        }

        target: root.window
    }
    Connections {
        function onFullscreenActiveChanged() {
            if (root.monitor?.fullscreenActive === true && root.controlCenterConfig?.edgeDrag?.allowInFullscreen !== true)
                revealController.cancel("fullscreenSuppressed");
        }

        target: root.monitor
    }
}
