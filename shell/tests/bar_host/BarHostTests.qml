import "../../features/bar" as Bar
import "../../services/workspaces" as WorkspaceServices
import "../../surfaces" as Surfaces
import QtQuick
import Quickshell

ShellRoot {
    id: root

    property string artifactDirectory: String(Quickshell.env("FRANKEN_SHELL_ARTIFACT_DIR") ?? "")
    property int captureIndex: 0
    property var normalLayout: null

    function check(condition: bool, message: string) {
        if (!condition)
            root.fail(message);
    }
    function fail(message: string) {
        console.error("FAIL bar-host:", message);
        Qt.exit(1);
        throw new Error(message);
    }
    function requestCapture() {
        const names = ["normal", "long-text", "high-text-scale", "missing-items"];
        barHost.captureFixture(root.artifactDirectory + "/" + names[root.captureIndex] + ".png");
    }
    function runStep() {
        switch (root.captureIndex) {
        case 0:
            {
                root.check(root.artifactDirectory.length > 0, "fixture artifact directory is configured");
                root.check(barHost.visible && barHost.width > 0 && barHost.height > 0, "left bar host instantiates on the selected screen");
                const summary = barHost.summary();
                root.check(summary.monitorId === "fixture-monitor-1" && summary.edge === "left" && summary.orientation === "vertical", "host ownership and orientation derive from the monitor model");
                root.check(summary.inwardDirection === "right" && summary.thickness === 48 && summary.exclusiveZone === 48, "central geometry resolves inward direction, token thickness, and exclusion");
                root.check(summary.mainAxisStartInset === 0 && summary.mainAxisEndInset === 0 && summary.outwardInset === 0, "prototype insets remain centralized and explicit");
                root.normalLayout = barHost.layoutSnapshot();
                root.check(!root.normalLayout.layoutOverflow && root.normalLayout.contextCapacity === 3, "normal fixture fits with the configured provisional contextual capacity");
                root.requestCapture();
                break;
            }
        case 1:
            {
                const layout = barHost.layoutSnapshot();
                root.check(layout.endPosition === root.normalLayout.endPosition && layout.absoluteEndPosition === root.normalLayout.absoluteEndPosition, "long changing values do not move protected end zones");
                root.requestCapture();
                break;
            }
        case 2:
            {
                const layout = barHost.layoutSnapshot();
                root.check(layout.endPosition === root.normalLayout.endPosition && layout.absoluteEndPosition === root.normalLayout.absoluteEndPosition, "high text scale does not move protected end zones");
                root.check(!layout.layoutOverflow, "high-text-scale fixture remains within the supported host extent");
                root.requestCapture();
                break;
            }
        case 3:
            {
                const layout = barHost.layoutSnapshot();
                root.check(layout.absoluteEndPosition === root.normalLayout.absoluteEndPosition, "missing optional items cannot displace the absolute-end entry");
                root.requestCapture();
                break;
            }
        case 4:
            {
                fakeMonitor.configuredBarEdge = "top";
                root.captureIndex = 5;
                settleTimer.restart();
                break;
            }
        case 5:
            {
                const layout = barHost.layoutSnapshot();
                root.check(barHost.orientation === "horizontal" && barHost.inwardDirection === "down", "the same fixture delegates compose horizontally for a top edge");
                root.check(!layout.vertical, "top-edge layout uses the horizontal axis without rotating text");
                fakeMonitor.configuredBarEdge = "left";
                fakeMonitor.fullscreenActive = true;
                root.captureIndex = 6;
                settleTimer.restart();
                break;
            }
        case 6:
            {
                root.check(!barHost.visible && barHost.exclusiveZone === 0, "true fullscreen hides the host and releases its exclusive zone");
                fakeMonitor.fullscreenActive = false;
                fakeMonitor.maximizedActive = true;
                root.captureIndex = 7;
                settleTimer.restart();
                break;
            }
        case 7:
            {
                root.check(barHost.visible && barHost.exclusiveZone === 48, "maximized state keeps the bar visible and reserved");
                barHost.fixtureModel.scenario = "localized";
                root.captureIndex = 8;
                settleTimer.restart();
                break;
            }
        case 8:
            {
                const layout = barHost.layoutSnapshot();
                root.check(layout.endPosition === root.normalLayout.endPosition && layout.absoluteEndPosition === root.normalLayout.absoluteEndPosition, "localized fixture values do not move protected neighbours");
                let result = barHost.activateFixtureItem("audio", "pointer");
                root.check(result.accepted && result.changed, "pointer activation opens a fixture popover");
                root.captureIndex = 9;
                settleTimer.restart();
                break;
            }
        case 9:
            {
                let popover = barHost.popoverSummary();
                root.check(popover.open && popover.surfaceId === "fixture.audio" && popover.anchorResolved, "popover host resolves the invoking audio anchor");
                root.check(popover.edge === "left" && popover.popupEdge === "right" && popover.inwardDirection === "right", "left-edge popover opens inward");
                let result = barHost.activateFixtureItem("resources", "pointer");
                root.check(result.accepted && result.changed, "opening another anchor replaces the active popover");
                root.captureIndex = 10;
                settleTimer.restart();
                break;
            }
        case 10:
            {
                let popover = barHost.popoverSummary();
                root.check(popover.open && popover.surfaceId === "fixture.resources", "only the replacement popover remains open");
                let result = barHost.dismissPopoverOutside();
                root.check(result.accepted && result.changed && !barHost.popoverSummary().open, "outside pointer dismissal closes the popover");
                result = barHost.activateFixtureItem("audio", "keyboard");
                root.check(result.accepted && result.changed, "keyboard activation opens the fixture popover");
                root.captureIndex = 11;
                settleTimer.restart();
                break;
            }
        case 11:
            {
                const popover = barHost.popoverSummary();
                root.check(popover.open && popover.keyboardOpened && fakeSurfaceCoordinator.focusAcquisitionCount === 1, "keyboard opening requests focus with a deterministic content target");
                const result = barHost.dismissPopoverEscape();
                root.check(result.accepted && result.changed && fakeSurfaceCoordinator.focusRestorationCount === 1, "Escape closes and restores the keyboard invocation focus path");
                fakeMonitor.configuredBarEdge = "top";
                root.captureIndex = 12;
                settleTimer.restart();
                break;
            }
        case 12:
            {
                let result = barHost.activateFixtureItem("audio", "pointer");
                root.check(result.accepted && result.changed, "top-edge fixture anchor remains interactive");
                root.captureIndex = 13;
                settleTimer.restart();
                break;
            }
        case 13:
            {
                const popover = barHost.popoverSummary();
                root.check(popover.open && popover.edge === "top" && popover.popupEdge === "bottom" && popover.inwardDirection === "down", "top-edge popover opens inward without rotating content");
                let result = barHost.activateFixtureItem("audio", "pointer");
                root.check(result.accepted && result.changed && !barHost.popoverSummary().open, "invoking the same anchor toggles its popover closed");
                result = barHost.activateSpecialWorkspaceSelector("pointer");
                root.check(result.accepted && result.changed, "special-workspace selector requests the shared host");
                root.captureIndex = 14;
                settleTimer.restart();
                break;
            }
        case 14:
            {
                const popover = barHost.popoverSummary();
                root.check(popover.open && popover.surfaceId === "workspace.special-selector" && popover.anchorResolved, "shared host resolves and renders the special-workspace selector anchor");
                barHost.dismissPopoverOutside();
                root.check(geometryRight.orientation === "vertical" && geometryRight.inwardDirection === "left", "right-edge abstraction opens inward without rotating delegates");
                root.check(geometryTop.orientation === "horizontal" && geometryTop.inwardDirection === "down", "top-edge abstraction selects a horizontal composition");
                root.check(geometryBottom.orientation === "horizontal" && geometryBottom.inwardDirection === "up", "bottom-edge abstraction selects a horizontal composition");
                root.check(barHost.requestAudioVolumeSteps(2) && fakeAudioController.pendingSteps === 2, "bar wheel requests are routed through the shared audio controller");
                root.check(barHost.requestAudioMuteToggle() && fakeAudioController.toggleCount === 1, "bar middle-click mute is routed through the shared audio controller");
                console.info("PASS bar-host: monitor ownership, stable fixture cells, audio interactions, normalized fullscreen, anchor-aware popovers, dismissal, focus, and edge abstraction");
                Qt.quit();
                break;
            }
        default:
            root.fail("unexpected fixture step");
        }
    }

    Component.onCompleted: settleTimer.start()

    FakeBarConfig {
        id: fakeBarConfig
    }
    FakeBarMonitor {
        id: fakeMonitor
    }
    FakeBarSurfaceCoordinator {
        id: fakeSurfaceCoordinator
    }
    FakeBarTheme {
        id: fakeTheme
    }
    FakeWorkspaceConfig {
        id: fakeWorkspaceConfig
    }
    QtObject {
        id: fakeAudioController

        property bool available: true
        property var defaultOutput: Object.freeze({
            "id": "fixture-output",
            "name": "Fixture output",
            "description": "Fixture speakers"
        })
        property bool masterMuted: false
        property real masterVolume: 0.42
        property string outputCategory: "speaker"
        property int pendingSteps: 0
        property int toggleCount: 0

        function queueVolumeSteps(steps: int) {
            fakeAudioController.pendingSteps += steps;
        }
        function toggleMasterMute(): var {
            fakeAudioController.toggleCount += 1;
            return Object.freeze({
                "accepted": true,
                "errorCode": ""
            });
        }
    }
    WorkspaceServices.FixtureWorkspaceAdapter {
        id: fixtureWorkspaceAdapter
    }
    Surfaces.BarHost {
        id: barHost

        audioController: fakeAudioController
        barConfig: fakeBarConfig
        fixtureWindow: true
        monitor: fakeMonitor
        screenInfo: Quickshell.screens[0]
        surfaceCoordinator: fakeSurfaceCoordinator
        theme: fakeTheme
        workspaceBackend: fixtureWorkspaceAdapter
        workspaceConfig: fakeWorkspaceConfig

        onFixtureCaptured: (path, saved) => {
            root.check(saved, "fixture screenshot saved: " + path);
            root.captureIndex += 1;
            if (root.captureIndex === 1) {
                barHost.fixtureModel.scenario = "longText";
            } else if (root.captureIndex === 2) {
                barHost.fixtureModel.scenario = "highTextScale";
                fakeTheme.fontScale = 1.5;
            } else if (root.captureIndex === 3) {
                barHost.fixtureModel.scenario = "missingItems";
                fakeTheme.fontScale = 1;
            }
            settleTimer.restart();
        }
    }
    Bar.BarGeometry {
        id: geometryRight

        configuredEdge: "right"
        configuredThickness: "auto"
        persistentVisible: true
        theme: fakeTheme
    }
    Bar.BarGeometry {
        id: geometryTop

        configuredEdge: "top"
        configuredThickness: "auto"
        persistentVisible: true
        theme: fakeTheme
    }
    Bar.BarGeometry {
        id: geometryBottom

        configuredEdge: "bottom"
        configuredThickness: "auto"
        persistentVisible: true
        theme: fakeTheme
    }
    Timer {
        id: settleTimer

        interval: 50

        onTriggered: root.runStep()
    }
}
