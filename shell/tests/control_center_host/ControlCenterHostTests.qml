import "../../core" as Core
import "../../surfaces" as Surfaces
import QtQuick
import Quickshell

ShellRoot {
    id: root

    property int acquisitionCount: 0
    property string artifactDirectory: String(Quickshell.env("FRANKEN_SHELL_ARTIFACT_DIR") ?? "")
    property int captureCount: 0
    property int restorationCount: 0
    property int step: 0
    property int transferCount: 0

    function check(condition: bool, message: string) {
        if (!condition)
            root.fail(message);
    }
    function context(origin: string, controlId: string, takesFocus: bool): var {
        return {
            "monitorId": fixtureMonitor.runtimeId,
            "origin": origin,
            "originControlId": controlId,
            "previousFocusToken": "",
            "takesFocus": takesFocus
        };
    }
    function fail(message: string) {
        console.error("FAIL control-center-host:", message);
        host.captureFixture(root.artifactDirectory + "/failure.png");
        Qt.exit(1);
        throw new Error(message);
    }
    function runStep() {
        switch (root.step) {
        case 0:
            {
                root.check(root.artifactDirectory.length > 0, "fixture artifact directory is configured");
                root.check(host.ready && !host.visible, "closed host is instantiated once without a visible surface");
                const closed = host.summary();
                root.check(closed.primitive === "PanelWindow" && closed.rightAttached && closed.exclusionMode === "Ignore" && closed.exclusiveZone === 0, "selected primitive contract is right-attached, non-reserving, and ignores existing exclusive zones");
                root.check(closed.gestureDrawerWidth === 400, "closed host keeps stable configured gesture geometry before its window is mapped");
                let result = coordinator.openPopover("fixture.audio", "bar.audio.fixture-monitor-1", root.context("pointer", "bar.audio.fixture-monitor-1", false));
                root.check(result.accepted && coordinator.activePopoverId === "fixture.audio", "fixture popover is active before major opening");
                result = host.requestOpen("pointer", "fixture.controlCenterButton");
                root.check(result.accepted && result.changed, "pointer action opens the control centre");
                root.step = 1;
                settleTimer.restart();
                break;
            }
        case 1:
            {
                const opened = host.summary();
                root.check(host.visible && opened.open && opened.scrimVisible && opened.revealProgress === 1, "pointer opening presents drawer and owning-monitor scrim");
                root.check(!opened.keyboardActive && !opened.initialFocusActive && root.acquisitionCount === 0, "pointer opening does not steal keyboard focus");
                root.check(coordinator.activeMajorId === "controlCenter" && coordinator.activePopover === null, "major opening closes the ordinary bar popover");
                root.check(opened.drawerWidth === 400 && opened.monitorId === fixtureMonitor.runtimeId, "fixture uses the theme width and resolved monitor");
                host.captureFixture(root.artifactDirectory + "/pointer-open.png");
                break;
            }
        case 2:
            {
                let result = host.dismissOutside();
                root.check(result.accepted && result.changed && !host.summary().open, "scrim outside click dismisses the ordinary pointer-opened drawer");
                root.check(root.restorationCount === 0, "non-focus-taking pointer path does not invent focus restoration");
                result = host.requestOpen("keyboard", "shortcut.controlCenter");
                root.check(result.accepted && result.changed, "keyboard request opens the drawer");
                root.step = 3;
                settleTimer.restart();
                break;
            }
        case 3:
            {
                const opened = host.summary();
                root.check(opened.open && opened.keyboardActive && opened.initialFocusActive && root.acquisitionCount === 1, "keyboard opening acquires deterministic initial focus through the coordinator");
                root.check(opened.activePage === "main" && opened.activeTab === "notifications" && opened.focusedControlId === "quick.wifi", "keyboard opening enters main Notifications at the first quick control");
                root.check(host.requestSelectTab("volumeMixer", "keyboard") && host.summary().activeTab === "volumeMixer", "host forwards tab navigation into the tested content controller");
                root.check(host.requestPage("network", "quick.wifi", "keyboard"), "host opens the nested Network page");
                root.check(host.summary().activePage === "network" && host.summary().navigationStackDepth === 1, "nested page stays inside the owned drawer");
                const result = host.handleEscape();
                root.check(result.accepted && result.changed && host.summary().open && host.summary().activePage === "main" && host.summary().activeTab === "notifications", "first Escape pops one nested level without closing the drawer");
                root.step = 6;
                settleTimer.restart();
                break;
            }
        case 4:
            {
                root.check(host.requestPage("bluetooth", "quick.bluetooth", "pointer"), "pointer navigation opens the nested Bluetooth page");
                let result = host.dismissOutside();
                root.check(result.accepted && result.changed && !host.summary().open, "outside click closes an ordinary nested page and drawer together");
                root.check(root.restorationCount === 1, "nested outside dismissal requests one focus restoration");
                result = host.requestOpen("keyboard", "shortcut.controlCenter");
                root.check(result.accepted && result.changed, "drawer reopens after nested outside dismissal");
                root.step = 7;
                settleTimer.restart();
                break;
            }
        case 6:
            root.check(host.summary().focusedControlId === "quick.wifi", "nested Escape restores focus to the invoking quick control");
            host.captureFixture(root.artifactDirectory + "/keyboard-open.png");
            break;
        case 7:
            {
                const reopened = host.summary();
                root.check(reopened.open && reopened.activePage === "main" && reopened.activeTab === "notifications" && reopened.focusedControlId === "quick.wifi", "open-close cycle drops nested, tab, and stale focus state");
                root.check(host.requestPage("network", "quick.wifi", "keyboard"), "drawer opens a nested page before close-drag dismissal");
                root.check(host.requestCloseDragPress(600, 200, 0), "open nested drawer accepts close-drag press");
                root.check(host.requestDragUpdate(760, 202, 200), "host forwards committed outward close-drag intent");
                root.check(!host.requestDragRelease(), "sufficient outward distance selects closed settle");
                root.step = 8;
                settleTimer.restart();
                break;
            }
        case 8:
            {
                const closed = host.summary();
                root.check(!closed.open && closed.revealProgress === 0, "close drag dismisses a nested page and releases drawer ownership");
                root.check(closed.activePage === "main" && closed.activeTab === "notifications" && closed.navigationStackDepth === 0, "close drag discards nested and tab state at the restoration boundary");
                const result = host.requestOpen("keyboard", "shortcut.controlCenter");
                root.check(result.accepted && result.changed, "drawer reopens after nested close-drag dismissal");
                root.step = 9;
                settleTimer.restart();
                break;
            }
        case 9:
            {
                const reopened = host.summary();
                root.check(reopened.open && reopened.activePage === "main" && reopened.activeTab === "notifications" && reopened.focusedControlId === "quick.wifi", "reopen after close drag restores the safe main-page focus state");
                let result = host.handleEscape();
                root.check(result.accepted && result.changed && !host.summary().open, "Escape closes the main drawer after nested state has unwound");
                root.check(root.restorationCount === 3, "close drag and main Escape each request one focus restoration");
                result = host.requestToggle("keyboard", "shortcut.controlCenter");
                root.check(result.accepted && result.changed && host.summary().open, "keyboard toggle reopens the drawer");
                result = host.requestToggle("keyboard", "shortcut.controlCenter");
                root.check(result.accepted && result.changed && !host.summary().open, "same keyboard shortcut toggles the drawer closed");
                result = host.requestOpen("keyboard", "shortcut.controlCenter");
                root.check(result.accepted && result.changed, "drawer reopens for major-surface arbitration");
                result = coordinator.openMajor("settings", root.context("ipc", "ipc.settings", true));
                root.check(result.accepted && coordinator.activeMajorId === "settings" && !host.summary().open, "another major surface replaces and hides the control centre");
                root.check(root.transferCount === 1, "major replacement transfers focus without restoring through the application");
                coordinator.closeMajor("requested");
                root.check(host.requestEdgePress(1279, 240, 1280, 0), "eligible monitor edge accepts a pointer press");
                root.check(host.requestDragUpdate(1119, 244, 240), "host forwards committed horizontal drag intent");
                const dragged = host.summary();
                root.check(dragged.open && dragged.scrimVisible && dragged.revealProgress === 0.4, "committed edge drag owns the major surface and directly reveals drawer and scrim");
                root.check(host.requestDragRelease(), "distance threshold selects open settle from the last committed pointer sample");
                root.step = 5;
                settleTimer.restart();
                break;
            }
        case 5:
            {
                root.check(host.summary().open && host.summary().revealProgress === 1, "edge drag settles fully open");
                host.dismissOutside();
                fixtureMonitor.fullscreenActive = true;
                root.check(!host.requestEdgePress(1279, 240, 1280, 500), "normalized true fullscreen suppresses pointer activation");
                fixtureMonitor.fullscreenActive = false;
                console.info("PASS control-center-host: primitive, ownership, navigation, scrim, focus, dismissal, toggle, arbitration, and direct edge reveal");
                Qt.quit();
                break;
            }
        default:
            root.fail("unexpected fixture step");
        }
    }

    Component.onCompleted: settleTimer.start()

    FakeControlCenterConfig {
        id: fixtureConfig
    }
    FakeControlCenterMonitor {
        id: fixtureMonitor
    }
    FakeControlCenterMonitorRegistry {
        id: monitorRegistry

        monitor: fixtureMonitor
    }
    FakeControlCenterTheme {
        id: fixtureTheme
    }
    Core.SurfaceCoordinator {
        id: coordinator

        monitorRegistry: monitorRegistry

        onFocusAcquisitionRequested: context => {
            void context;
            root.acquisitionCount += 1;
        }
        onFocusRestorationRequested: context => {
            void context;
            root.restorationCount += 1;
        }
        onFocusTransferRequested: context => {
            void context;
            root.transferCount += 1;
        }
    }
    Surfaces.ControlCenterHost {
        id: host

        controlCenterConfig: fixtureConfig
        fixtureWindow: true
        monitor: fixtureMonitor
        screenInfo: Quickshell.screens[0]
        surfaceCoordinator: coordinator
        theme: fixtureTheme

        onFixtureCaptured: (path, saved) => {
            root.check(saved, "fixture screenshot saved: " + path);
            root.captureCount += 1;
            root.step = root.captureCount === 1 ? 2 : 4;
            settleTimer.restart();
        }
    }
    Timer {
        id: settleTimer

        interval: 50

        onTriggered: root.runStep()
    }
}
