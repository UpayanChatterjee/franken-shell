import QtQuick
import Quickshell

Scope {
    id: root

    required property var barConfig
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
    required property ShellScreen screenInfo
    required property var surfaceCoordinator
    required property var theme
    readonly property bool visible: root.window?.visible ?? false
    readonly property real width: root.window?.width ?? 0
    readonly property var window: root.ready ? hostLoader.item : null

    signal fixtureCaptured(string path, bool saved)

    function captureFixture(path: string) {
        if (root.ready)
            root.window.captureFixture(path);
    }
    function layoutSnapshot(): var {
        return root.ready ? root.window.layoutSnapshot() : Object.freeze({});
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
            "contextCapacity": 0
        });
    }

    Loader {
        id: hostLoader

        active: true
        source: Qt.resolvedUrl(root.fixtureWindow ? "BarFixtureWindow.qml" : "BarPanelWindow.qml")
    }
    Binding {
        property: "barConfig"
        target: root.window
        value: root.barConfig
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
