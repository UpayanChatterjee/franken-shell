import QtQuick
import Quickshell

Scope {
    id: root

    required property var controlCenterConfig
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
    function requestOpen(origin: string, originControlId: string): var {
        return root.ready ? root.window.requestOpen(origin, originControlId) : root.result(false);
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
            "monitorId": "",
            "open": false,
            "visible": false,
            "keyboardActive": false,
            "initialFocusActive": false,
            "revealProgress": 0,
            "drawerWidth": 0,
            "scrimVisible": false,
            "exclusionMode": "Ignore",
            "exclusiveZone": 0,
            "primitive": "PanelWindow",
            "rightAttached": true
        });
    }

    Loader {
        id: hostLoader

        active: true
        source: Qt.resolvedUrl(root.fixtureWindow ? "ControlCenterFixtureWindow.qml" : "ControlCenterPanelWindow.qml")
    }
    Binding {
        property: "controlCenterConfig"
        target: root.window
        value: root.controlCenterConfig
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
    Connections {
        function onFixtureCaptured(path, saved) {
            root.fixtureCaptured(path, saved);
        }

        target: root.window
    }
}
