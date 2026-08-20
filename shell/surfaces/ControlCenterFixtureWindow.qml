import QtQuick
import Quickshell

FloatingWindow {
    id: root

    property var contentModel: null
    property var controlCenterConfig: null
    readonly property real drawerWidth: controlCenterSurface.drawerWidth
    readonly property int exclusiveZone: 0
    property var monitor: null
    readonly property string ownerMonitorId: controlCenterSurface.ownerMonitorId
    property var revealController: null
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
    function openPage(pageId: string, invokerFocusId: string, source: string): bool {
        return controlCenterSurface.openPage(pageId, invokerFocusId, source);
    }
    function requestOpen(origin: string, originControlId: string): var {
        return controlCenterSurface.requestOpen(origin, originControlId);
    }
    function requestQuickControlAction(controlId: string, action: string, source: string): bool {
        return controlCenterSurface.requestQuickControlAction(controlId, action, source);
    }
    function requestSliderStep(sliderId: string, step: int, source: string): bool {
        return controlCenterSurface.requestSliderStep(sliderId, step, source);
    }
    function requestToggle(origin: string, originControlId: string): var {
        return controlCenterSurface.requestToggle(origin, originControlId);
    }
    function selectTab(tabId: string, source: string): bool {
        return controlCenterSurface.selectTab(tabId, source);
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
        contentModel: root.contentModel
        controlCenterConfig: root.controlCenterConfig
        monitor: root.monitor
        revealController: root.revealController
        surfaceCoordinator: root.surfaceCoordinator
        theme: root.theme

        onFixtureCaptured: (path, saved) => root.fixtureCaptured(path, saved)
    }
}
