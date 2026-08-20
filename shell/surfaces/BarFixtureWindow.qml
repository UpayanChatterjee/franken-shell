import QtQuick
import Quickshell

FloatingWindow {
    id: root

    property var audioController: null
    property var barConfig: null
    readonly property string edge: barSurface.edge
    readonly property int exclusiveZone: barSurface.exclusiveZone
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
    function requestAudioMuteToggle(): bool {
        return barSurface.requestAudioMuteToggle();
    }
    function requestAudioVolumeSteps(steps: int): bool {
        return barSurface.requestAudioVolumeSteps(steps);
    }
    function summary(): var {
        return barSurface.summary();
    }

    color: "transparent"
    implicitHeight: barSurface.vertical ? Math.max(root.screenInfo?.height ?? 720, barSurface.minimumMainAxisExtent) : barSurface.thickness
    implicitWidth: barSurface.vertical ? barSurface.thickness : Math.max(root.screenInfo?.width ?? 1280, barSurface.minimumMainAxisExtent)
    reloadableId: "bar-fixture-host-" + (root.screenInfo?.name ?? "unresolved")
    screen: root.screenInfo
    title: qsTr("Franken Shell fixture bar")
    visible: barSurface.windowVisible

    BarSurface {
        id: barSurface

        anchors.fill: parent
        audioController: root.audioController
        barConfig: root.barConfig
        fixtureWindow: true
        monitor: root.monitor
        screenInfo: root.screenInfo
        surfaceCoordinator: root.surfaceCoordinator
        theme: root.theme
        workspaceBackend: root.workspaceBackend
        workspaceConfig: root.workspaceConfig

        onFixtureCaptured: (path, saved) => root.fixtureCaptured(path, saved)
    }
}
