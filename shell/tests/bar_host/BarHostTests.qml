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
                root.check(geometryRight.orientation === "vertical" && geometryRight.inwardDirection === "left", "right-edge abstraction opens inward without rotating delegates");
                root.check(geometryTop.orientation === "horizontal" && geometryTop.inwardDirection === "down", "top-edge abstraction selects a horizontal composition");
                root.check(geometryBottom.orientation === "horizontal" && geometryBottom.inwardDirection === "up", "bottom-edge abstraction selects a horizontal composition");
                console.info("PASS bar-host: monitor ownership, semantic zones, stable geometry, fixtures, fullscreen, and edge abstraction");
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
    WorkspaceServices.FixtureWorkspaceAdapter {
        id: fixtureWorkspaceAdapter
    }
    Surfaces.BarHost {
        id: barHost

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
            if (root.captureIndex === 1)
                barHost.fixtureModel.scenario = "longText";
            else if (root.captureIndex === 2) {
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
