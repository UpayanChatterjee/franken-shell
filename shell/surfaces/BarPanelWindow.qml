import QtQuick
import Quickshell
import Quickshell.Wayland

// qmllint disable uncreatable-type
PanelWindow {
    // qmllint enable uncreatable-type
    id: root

    property var barConfig: null
    readonly property string edge: barSurface.edge
    readonly property alias fixtureModel: barSurface.fixtureModel
    readonly property string inwardDirection: barSurface.inwardDirection
    readonly property bool layoutOverflow: barSurface.layoutOverflow
    property var monitor: null
    readonly property string orientation: barSurface.orientation
    readonly property string ownerMonitorId: barSurface.ownerMonitorId
    property var screenInfo: null
    property var surfaceCoordinator: null
    property var theme: null
    property var workspaceBackend: null
    property var workspaceConfig: null

    signal fixtureCaptured(string path, bool saved)

    function activateFixtureItem(itemId: string, origin: string): var {
        return barSurface.activateFixtureItem(itemId, origin);
    }
    function activateSpecialWorkspaceSelector(origin: string): var {
        return barSurface.activateSpecialWorkspaceSelector(origin);
    }
    function captureFixture(path: string) {
        barSurface.captureFixture(path);
    }
    function dismissPopoverEscape(): var {
        return barSurface.dismissPopoverEscape();
    }
    function dismissPopoverOutside(): var {
        return barSurface.dismissPopoverOutside();
    }
    function layoutSnapshot(): var {
        return barSurface.layoutSnapshot();
    }
    function popoverSummary(): var {
        return barSurface.popoverSummary();
    }
    function summary(): var {
        return barSurface.summary();
    }

    WlrLayershell.namespace: "franken-shell-bar"
    aboveWindows: true
    anchors.bottom: barSurface.vertical || barSurface.edge === "bottom"
    anchors.left: !barSurface.vertical || barSurface.edge === "left"
    anchors.right: !barSurface.vertical || barSurface.edge === "right"
    anchors.top: barSurface.vertical || barSurface.edge === "top"
    color: "transparent"
    exclusiveZone: barSurface.exclusiveZone
    focusable: false
    implicitHeight: barSurface.vertical ? 1 : barSurface.thickness
    implicitWidth: barSurface.vertical ? barSurface.thickness : 1
    reloadableId: "bar-host-" + (root.screenInfo?.name ?? "unresolved")
    screen: root.screenInfo
    visible: barSurface.windowVisible

    BarSurface {
        id: barSurface

        anchors.fill: parent
        barConfig: root.barConfig
        fixtureWindow: false
        monitor: root.monitor
        screenInfo: root.screenInfo
        surfaceCoordinator: root.surfaceCoordinator
        theme: root.theme
        workspaceBackend: root.workspaceBackend
        workspaceConfig: root.workspaceConfig

        onFixtureCaptured: (path, saved) => root.fixtureCaptured(path, saved)
    }
}
