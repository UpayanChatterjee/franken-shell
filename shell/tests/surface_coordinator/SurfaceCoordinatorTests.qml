import "../../core" as Core
import QtQuick
import Quickshell

ShellRoot {
    id: root

    property int acquisitionCount: 0
    property var lastAcquisition: null
    property var lastRestoration: null
    property var lastTransfer: null
    property int restorationCount: 0
    property int transferCount: 0

    function check(condition: bool, message: string) {
        if (!condition)
            root.fail(message);
    }
    function context(monitorId: string, origin: string, originControlId: string, previousFocusToken: string, takesFocus: bool): var {
        return {
            "monitorId": monitorId,
            "origin": origin,
            "originControlId": originControlId,
            "previousFocusToken": previousFocusToken,
            "takesFocus": takesFocus
        };
    }
    function fail(message: string) {
        console.error("FAIL surface-coordinator:", message);
        Qt.exit(1);
        throw new Error(message);
    }
    function resetSignals() {
        root.acquisitionCount = 0;
        root.lastAcquisition = null;
        root.restorationCount = 0;
        root.transferCount = 0;
        root.lastRestoration = null;
        root.lastTransfer = null;
    }
    function run() {
        const pointerContext = root.context("monitor-1", "pointer", "bar.audio", "window.application-1", true);
        let result = coordinator.openPopover("audio", "bar.audio", pointerContext);
        root.check(result.accepted && result.changed && coordinator.activePopoverId === "audio", "popover opens on the explicit owner monitor");
        root.check(coordinator.activePopover.ownerMonitorId === "monitor-1" && coordinator.activePopover.origin === "pointer", "popover exposes sanitized ownership");
        root.check(typeof coordinator.activePopover.previousFocusToken === "undefined", "private focus token is not feature-facing");
        root.check(root.acquisitionCount === 1 && root.lastAcquisition.surfaceId === "audio", "focus acquisition is an explicit coordinator handoff");

        const firstRevision = coordinator.revision;
        result = coordinator.openPopover("audio", "bar.audio", pointerContext);
        root.check(result.accepted && !result.changed && coordinator.revision === firstRevision, "identical open is idempotent");

        root.resetSignals();
        result = coordinator.openPopover("network", "bar.network", root.context("monitor-2", "pointer", "bar.network", "window.application-2", true));
        root.check(result.accepted && coordinator.activePopoverId === "network", "another popover replaces the active popover");
        root.check(root.transferCount === 1 && root.restorationCount === 0, "popover replacement transfers focus without an intermediate restoration");
        root.check(root.lastTransfer.fromSurfaceId === "audio" && root.lastTransfer.toSurfaceId === "network", "replacement focus transfer names both surfaces");

        root.resetSignals();
        result = coordinator.handleEscape();
        root.check(result.changed && coordinator.activePopover === null, "Escape closes the active popover");
        root.check(root.restorationCount === 1 && root.lastRestoration.reason === "escape", "Escape requests focus restoration exactly once");
        root.check(root.lastRestoration.originControlId === "bar.network" && root.lastRestoration.previousFocusToken === "window.application-2", "restoration handoff preserves validated candidates");

        result = coordinator.openMajor("controlCenter", root.context("monitor-1", "keyboard", "shortcut.controlCenter", "window.application-1", true));
        root.check(result.accepted && coordinator.activeMajorId === "controlCenter", "major surface opens");
        result = coordinator.openPopover("audio", "bar.audio", pointerContext);
        root.check(!result.accepted && result.errorCode === "SURFACE_MAJOR_ACTIVE" && coordinator.activeMajorId === "controlCenter", "ordinary popover cannot overlap an active major surface");

        root.resetSignals();
        result = coordinator.openMajor("settings", root.context("monitor-2", "ipc", "ipc.settings", "window.application-2", true));
        root.check(result.accepted && coordinator.activeMajorId === "settings", "major surface replacement is deterministic");
        root.check(root.transferCount === 1 && root.restorationCount === 0, "major replacement transfers focus directly");
        result = coordinator.closeMajor("outsideClick");
        root.check(result.changed && coordinator.activeMajor === null && root.restorationCount === 1, "outside click closes and requests restoration");

        result = coordinator.openPopover("calendar", "bar.calendar", root.context("monitor-1", "pointer", "bar.calendar", "window.application-1", true));
        root.resetSignals();
        result = coordinator.originDisappeared("bar.calendar");
        root.check(result.changed && coordinator.activePopover === null, "anchor disappearance closes its popover");
        root.check(root.restorationCount === 1 && !root.lastRestoration.originAvailable && root.lastRestoration.originControlId === "", "disappeared origin is invalidated before restoration");

        result = coordinator.openMajor("controlCenter", root.context("monitor-1", "keyboard", "shortcut.controlCenter", "window.application-1", true));
        result = coordinator.originDisappeared("shortcut.controlCenter");
        root.check(result.changed && coordinator.activeMajorId === "controlCenter", "major surface remains usable when only its origin control disappears");
        root.resetSignals();
        coordinator.closeMajor("requested");
        root.check(root.restorationCount === 1 && !root.lastRestoration.originAvailable, "later major close does not restore to a disappeared control");

        result = coordinator.openPopover("power", "bar.power", root.context("monitor-2", "pointer", "bar.power", "window.application-2", true));
        root.resetSignals();
        monitorRegistry.remove("monitor-2");
        root.check(coordinator.activePopover === null, "owner-monitor removal closes the owned popover");
        root.check(root.restorationCount === 1 && !root.lastRestoration.ownerMonitorAvailable && !root.lastRestoration.originAvailable, "monitor removal invalidates unsafe restoration candidates");

        result = coordinator.openMajor("session", root.context("monitor-1", "system", "", "", false));
        root.check(result.accepted, "non-focus-taking major surface may omit focus tokens");
        root.resetSignals();
        result = coordinator.closeAll("ipc");
        root.check(result.changed && coordinator.activeMajor === null && root.restorationCount === 0, "close-all does not invent restoration for non-focus-taking surfaces");
        result = coordinator.closeAll("ipc");
        root.check(result.accepted && !result.changed, "repeated close-all is idempotent");

        result = coordinator.openMajor("bad monitor", root.context("monitor-1", "keyboard", "", "", true));
        root.check(!result.accepted && result.errorCode === "SURFACE_ID_INVALID", "invalid surface identity is rejected");
        result = coordinator.openMajor("controlCenter", root.context("monitor-missing", "keyboard", "", "", true));
        root.check(!result.accepted && result.errorCode === "SURFACE_MONITOR_UNAVAILABLE", "unavailable monitor is rejected without fallback guessing");
        root.check(coordinator.rejectedRequestCount === 3, "rejections remain observable without altering active state");

        for (let index = 0; index < 20; ++index) {
            const id = "rapid." + index;
            result = coordinator.openPopover(id, "bar.rapid." + index, root.context("monitor-1", "pointer", "bar.rapid." + index, "", false));
            root.check(result.accepted, "rapid popover request " + index + " is accepted");
        }
        root.check(coordinator.activePopoverId === "rapid.19" && coordinator.summary().activeSurfaceCount === 1, "rapid replacement settles on one coherent owner");
        console.info("PASS surface-coordinator: ownership, replacement, dismissal, invalidation, and restoration handoff");
        Qt.quit();
    }

    Component.onCompleted: startTimer.start()

    FakeSurfaceMonitorRegistry {
        id: monitorRegistry
    }
    Core.SurfaceCoordinator {
        id: coordinator

        monitorRegistry: monitorRegistry

        onFocusAcquisitionRequested: context => {
            root.acquisitionCount += 1;
            root.lastAcquisition = context;
        }
        onFocusRestorationRequested: context => {
            root.restorationCount += 1;
            root.lastRestoration = context;
        }
        onFocusTransferRequested: context => {
            root.transferCount += 1;
            root.lastTransfer = context;
        }
    }
    Timer {
        id: startTimer

        interval: 0

        onTriggered: root.run()
    }
}
