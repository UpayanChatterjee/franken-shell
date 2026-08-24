import QtQuick
import Quickshell
import "../features/bar" as Bar
import "../features/workspaces" as Workspaces

Item {
    id: root

    property var audioController: null
    required property var barConfig
    property var batteryController: null
    readonly property string edge: geometry.edge
    readonly property int exclusiveZone: geometry.exclusiveZone
    property alias fixtureModel: fixtureState
    required property bool fixtureWindow
    readonly property bool fullscreenSuppressed: root.barConfig?.hideInFullscreen === true && root.monitor?.fullscreenActive === true
    readonly property bool hostEnabled: root.barConfig?.enabled === true && root.monitor?.connected === true && root.monitor?.barEnabled === true
    readonly property string inwardDirection: geometry.inwardDirection
    readonly property bool layoutOverflow: barLayout.layoutOverflow
    readonly property real minimumMainAxisExtent: barLayout.minimumMainAxisExtent + 2 * root.theme.spacing.space1
    required property var monitor
    readonly property string orientation: geometry.orientation
    readonly property string ownerMonitorId: root.monitor?.runtimeId ?? ""
    property var resourceController: null
    required property var screenInfo
    required property var surfaceCoordinator
    required property var theme
    readonly property real thickness: geometry.thickness
    property var throughputController: null
    property var trayController: null
    readonly property bool vertical: geometry.vertical
    readonly property bool windowVisible: root.hostEnabled && !root.fullscreenSuppressed
    required property var workspaceBackend
    required property var workspaceConfig

    signal fixtureCaptured(string path, bool saved)

    function activateFixtureItem(itemId: string, origin: string): var {
        const anchorId = "bar." + itemId + "." + root.safeToken(root.ownerMonitorId);
        const item = barLayout.anchorItem(anchorId);
        return item === null ? Object.freeze({
            "accepted": false,
            "changed": false,
            "errorCode": "FIXTURE_ANCHOR_UNAVAILABLE"
        }) : item.activate(origin);
    }
    function activateSpecialWorkspaceSelector(origin: string): var {
        const anchorId = "bar.special-workspaces." + root.safeToken(root.ownerMonitorId);
        const item = barLayout.anchorItem(anchorId);
        return item === null ? Object.freeze({
            "accepted": false,
            "changed": false,
            "errorCode": "WORKSPACE_SELECTOR_ANCHOR_UNAVAILABLE"
        }) : item.requestSelector(origin);
    }
    function captureFixture(path: string) {
        barLayout.grabToImage(result => {
            root.fixtureCaptured(path, result.saveToFile(path));
        });
    }
    function dismissPopoverEscape(): var {
        return popoverHost.dismissEscape();
    }
    function dismissPopoverOutside(): var {
        return popoverHost.dismissOutside();
    }
    function layoutSnapshot(): var {
        return barLayout.snapshot();
    }
    function popoverSummary(): var {
        return popoverHost.summary();
    }
    function requestAudioMuteToggle(): bool {
        const anchorId = "bar.audio." + root.safeToken(root.ownerMonitorId);
        const item = barLayout.anchorItem(anchorId);
        return item !== null && item.toggleAudioMute();
    }
    function requestAudioVolumeSteps(steps: int): bool {
        const anchorId = "bar.audio." + root.safeToken(root.ownerMonitorId);
        const item = barLayout.anchorItem(anchorId);
        return item !== null && item.queueAudioVolumeSteps(steps);
    }
    function safeToken(value: string): string {
        const sanitized = value.replace(/[^A-Za-z0-9._:-]/g, "_");
        return sanitized.length > 0 ? sanitized : "unresolved";
    }
    function summary(): var {
        const layout = barLayout.snapshot();
        return Object.freeze({
            "monitorId": root.ownerMonitorId,
            "edge": root.edge,
            "orientation": root.orientation,
            "inwardDirection": root.inwardDirection,
            "visible": root.windowVisible,
            "fullscreenSuppressed": root.fullscreenSuppressed,
            "thickness": geometry.thickness,
            "exclusiveZone": root.exclusiveZone,
            "mainAxisStartInset": geometry.mainAxisStartInset,
            "mainAxisEndInset": geometry.mainAxisEndInset,
            "outwardInset": geometry.outwardInset,
            "layoutOverflow": layout.layoutOverflow,
            "contextCapacity": layout.contextCapacity,
            "workspaceStateAvailable": workspaceController.stateAvailable,
            "workspaceActiveNumber": workspaceController.activeNumber,
            "workspaceVisibleNumbers": workspaceController.visibleNumbers,
            "specialWorkspaceCount": specialWorkspaceController.definitionsCount
        });
    }

    Workspaces.ActiveWorkspacePolicy {
        id: activeWorkspacePolicy

        adapter: root.workspaceBackend
        enabled: root.workspaceConfig?.overview?.openOnActiveWorkspaceClick === true
    }
    Workspaces.WorkspaceController {
        id: workspaceController

        activeActivationPolicy: activeWorkspacePolicy
        adapter: root.workspaceBackend
        monitor: root.monitor
        numberedConfig: root.workspaceConfig?.numbered ?? null
        pagerConfig: root.barConfig?.workspacePager ?? null
    }
    Workspaces.SpecialWorkspaceController {
        id: specialWorkspaceController

        adapter: root.workspaceBackend
        definitions: root.workspaceConfig?.special ?? null
        monitor: root.monitor
    }
    Bar.BarGeometry {
        id: geometry

        configuredEdge: root.monitor?.configuredBarEdge ?? root.barConfig?.edge ?? "left"
        configuredThickness: root.barConfig?.thickness ?? "auto"
        persistentVisible: root.windowVisible
        theme: root.theme
    }
    Bar.BarFixtureModel {
        id: fixtureState
    }
    Rectangle {
        anchors.fill: parent
        border.color: root.theme.colors.outlineSubtle
        border.width: root.theme.metrics.outlineWidth
        color: Qt.alpha(root.theme.colors.surfaceBase, root.theme.opacity.bar)

        Bar.BarLayout {
            id: barLayout

            anchors.fill: parent
            anchors.margins: root.theme.spacing.space1
            audioController: root.audioController
            batteryController: root.batteryController
            contextCapacity: Math.max(0, root.barConfig?.contextRegion?.slots ?? 3)
            fixtureModel: fixtureState
            monitorId: root.ownerMonitorId
            resourceController: root.resourceController
            specialWorkspaceController: specialWorkspaceController
            surfaceCoordinator: root.surfaceCoordinator
            theme: root.theme
            throughputController: root.throughputController
            trayController: root.trayController
            vertical: geometry.vertical
            workspaceController: workspaceController
        }
    }
    Bar.PopoverHost {
        id: popoverHost

        anchorResolver: anchorId => barLayout.anchorItem(anchorId)
        edge: root.edge
        fixtureModel: fixtureState
        fixtureWindow: root.fixtureWindow
        monitorId: root.ownerMonitorId
        parentWindow: QsWindow.window
        screenInfo: root.screenInfo
        specialWorkspaceController: specialWorkspaceController
        surfaceCoordinator: root.surfaceCoordinator
        theme: root.theme
        trayController: root.trayController
    }
    Connections {
        function onVisibleChanged() {
            if (root.trayController?.visible === true)
                return;
            const anchorId = "bar.tray." + root.safeToken(root.ownerMonitorId);
            if (root.surfaceCoordinator?.activePopoverId === "tray.drawer" && root.surfaceCoordinator?.activePopover?.anchorId === anchorId)
                root.surfaceCoordinator.originDisappeared(anchorId);
        }

        target: root.trayController
    }
}
