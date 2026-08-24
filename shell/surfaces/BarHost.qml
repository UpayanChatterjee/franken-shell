import QtQuick
import Quickshell

Scope {
    id: root

    property var audioController: null
    required property var barConfig
    property var batteryController: null
    property var calendarController: null
    property var contextController: null
    property var dateTimeController: null
    readonly property string edge: root.window?.edge ?? "left"
    readonly property int exclusiveZone: root.window?.exclusiveZone ?? 0
    readonly property var fixtureModel: root.window?.fixtureModel ?? null
    required property bool fixtureWindow
    readonly property real height: root.window?.height ?? 0
    readonly property string inwardDirection: root.window?.inwardDirection ?? "right"
    readonly property bool layoutOverflow: root.window?.layoutOverflow ?? false
    required property var monitor
    readonly property string orientation: root.window?.orientation ?? "vertical"
    readonly property string ownerMonitorId: root.window?.ownerMonitorId ?? ""
    readonly property bool ready: hostLoader.status === Loader.Ready
    property var resourceController: null
    required property ShellScreen screenInfo
    required property var surfaceCoordinator
    required property var theme
    property var throughputController: null
    property var trayController: null
    property var vicinaeAdapter: null
    readonly property bool visible: root.window?.visible ?? false
    readonly property real width: root.window?.width ?? 0
    readonly property var window: root.ready ? hostLoader.item : null
    required property var workspaceBackend
    required property var workspaceConfig

    signal fixtureCaptured(string path, bool saved)

    function activateFixtureItem(itemId: string, origin: string): var {
        return root.ready ? root.window.activateFixtureItem(itemId, origin) : Object.freeze({
            "accepted": false,
            "changed": false,
            "errorCode": "BAR_HOST_UNAVAILABLE"
        });
    }
    function activateSpecialWorkspaceSelector(origin: string): var {
        return root.ready ? root.window.activateSpecialWorkspaceSelector(origin) : Object.freeze({
            "accepted": false,
            "changed": false,
            "errorCode": "BAR_HOST_UNAVAILABLE"
        });
    }
    function captureFixture(path: string) {
        if (root.ready)
            root.window.captureFixture(path);
    }
    function dismissPopoverEscape(): var {
        return root.ready ? root.window.dismissPopoverEscape() : Object.freeze({
            "accepted": true,
            "changed": false,
            "errorCode": ""
        });
    }
    function dismissPopoverOutside(): var {
        return root.ready ? root.window.dismissPopoverOutside() : Object.freeze({
            "accepted": true,
            "changed": false,
            "errorCode": ""
        });
    }
    function layoutSnapshot(): var {
        return root.ready ? root.window.layoutSnapshot() : Object.freeze({});
    }
    function popoverSummary(): var {
        return root.ready ? root.window.popoverSummary() : Object.freeze({
            "open": false,
            "surfaceId": "",
            "anchorId": "",
            "monitorId": "",
            "edge": root.edge,
            "popupEdge": root.inwardDirection,
            "inwardDirection": root.inwardDirection,
            "keyboardOpened": false,
            "anchorResolved": false
        });
    }
    function requestAudioMuteToggle(): bool {
        return root.ready && root.window.requestAudioMuteToggle();
    }
    function requestAudioVolumeSteps(steps: int): bool {
        return root.ready && root.window.requestAudioVolumeSteps(steps);
    }
    function requestKeyboardFocus(): var {
        return root.ready ? root.window.requestKeyboardFocus() : Object.freeze({
            "accepted": false,
            "errorCode": "BAR_HOST_UNAVAILABLE"
        });
    }
    function summary(): var {
        if (root.ready)
            return root.window.summary();
        return Object.freeze({
            "monitorId": "",
            "edge": "left",
            "orientation": "vertical",
            "inwardDirection": "right",
            "visible": false,
            "fullscreenSuppressed": false,
            "thickness": 0,
            "exclusiveZone": 0,
            "mainAxisStartInset": 0,
            "mainAxisEndInset": 0,
            "outwardInset": 0,
            "layoutOverflow": false,
            "contextCapacity": 0,
            "workspaceStateAvailable": false,
            "workspaceActiveNumber": -1,
            "workspaceVisibleNumbers": Object.freeze([]),
            "specialWorkspaceCount": 0
        });
    }

    Loader {
        id: hostLoader

        active: true

        Component.onCompleted: hostLoader.setSource(Qt.resolvedUrl(root.fixtureWindow ? "BarFixtureWindow.qml" : "BarPanelWindow.qml"), {
            "audioController": root.audioController,
            "barConfig": root.barConfig,
            "batteryController": root.batteryController,
            "calendarController": root.calendarController,
            "contextController": root.contextController,
            "dateTimeController": root.dateTimeController,
            "monitor": root.monitor,
            "resourceController": root.resourceController,
            "screenInfo": root.screenInfo,
            "surfaceCoordinator": root.surfaceCoordinator,
            "theme": root.theme,
            "throughputController": root.throughputController,
            "trayController": root.trayController,
            "vicinaeAdapter": root.vicinaeAdapter,
            "workspaceBackend": root.workspaceBackend,
            "workspaceConfig": root.workspaceConfig
        })
    }
    Binding {
        property: "audioController"
        target: root.window
        value: root.audioController
        when: root.ready
    }
    Binding {
        property: "barConfig"
        target: root.window
        value: root.barConfig
        when: root.ready
    }
    Binding {
        property: "batteryController"
        target: root.window
        value: root.batteryController
        when: root.ready
    }
    Binding {
        property: "calendarController"
        target: root.window
        value: root.calendarController
        when: root.ready
    }
    Binding {
        property: "contextController"
        target: root.window
        value: root.contextController
        when: root.ready
    }
    Binding {
        property: "dateTimeController"
        target: root.window
        value: root.dateTimeController
        when: root.ready
    }
    Binding {
        property: "monitor"
        target: root.window
        value: root.monitor
        when: root.ready
    }
    Binding {
        property: "screenInfo"
        target: root.window
        value: root.screenInfo
        when: root.ready
    }
    Binding {
        property: "resourceController"
        target: root.window
        value: root.resourceController
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
        property: "throughputController"
        target: root.window
        value: root.throughputController
        when: root.ready
    }
    Binding {
        property: "trayController"
        target: root.window
        value: root.trayController
        when: root.ready
    }
    Binding {
        property: "vicinaeAdapter"
        target: root.window
        value: root.vicinaeAdapter
        when: root.ready
    }
    Binding {
        property: "workspaceBackend"
        target: root.window
        value: root.workspaceBackend
        when: root.ready
    }
    Binding {
        property: "workspaceConfig"
        target: root.window
        value: root.workspaceConfig
        when: root.ready
    }
    Connections {
        function onFixtureCaptured(path, saved) {
            root.fixtureCaptured(path, saved);
        }

        target: root.window
    }
}
