import QtQuick
import Quickshell

FloatingWindow {
    id: root

    property var controlCenterConfig: null
    readonly property int exclusiveZone: 0
    property var monitor: null
    readonly property string ownerMonitorId: controlCenterSurface.ownerMonitorId
    property var screenInfo: null
    property var surfaceCoordinator: null
    property var theme: null

    signal fixtureCaptured(string path, bool saved)

    function captureFixture(path: string) {
        controlCenterSurface.captureFixture(path);
    }
    function dismissOutside(): var {
        return controlCenterSurface.dismissOutside();
    }
    function handleEscape(): var {
        return controlCenterSurface.handleEscape();
    }
    function requestOpen(origin: string, originControlId: string): var {
        return controlCenterSurface.requestOpen(origin, originControlId);
    }
    function requestToggle(origin: string, originControlId: string): var {
        return controlCenterSurface.requestToggle(origin, originControlId);
    }
    function summary(): var {
        return controlCenterSurface.summary();
    }

    color: "transparent"
    implicitHeight: root.screenInfo?.height ?? 720
    implicitWidth: root.screenInfo?.width ?? 1280
    reloadableId: "control-center-fixture-" + (root.screenInfo?.name ?? "unresolved")
    screen: root.screenInfo
    title: qsTr("Franken Shell control centre fixture")
    visible: controlCenterSurface.windowVisible

    onVisibleChanged: {
        if (visible)
            controlCenterSurface.focusInitial();
    }

    ControlCenterSurface {
        id: controlCenterSurface

        anchors.fill: parent
        controlCenterConfig: root.controlCenterConfig
        monitor: root.monitor
        surfaceCoordinator: root.surfaceCoordinator
        theme: root.theme

        onFixtureCaptured: (path, saved) => root.fixtureCaptured(path, saved)
    }
}
