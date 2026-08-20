import "../../services/hyprland" as HyprlandServices
import QtQuick
import Quickshell

ShellRoot {
    id: root

    readonly property var eventNames: Object.freeze(["workspacev2", "focusedmon", "activespecial", "createworkspacev2", "destroyworkspacev2", "moveworkspacev2", "renameworkspace", "urgent", "activewindowv2", "openwindow", "closewindow", "movewindowv2", "changefloatingmode", "fullscreen", "monitoraddedv2", "monitorremoved"])

    function check(condition: bool, message: string) {
        if (!condition)
            root.fail(message);
    }
    function fail(message: string) {
        console.error("FAIL hyprland-adapter:", message);
        Qt.exit(1);
        throw new Error(message);
    }
    function numberedWorkspace(number: int, monitorName: string, active: bool, urgent: bool): var {
        return Object.freeze({
            "id": number,
            "name": String(number),
            "monitorName": monitorName,
            "active": active,
            "focused": active,
            "urgent": urgent,
            "hasFullscreen": false
        });
    }
    function run() {
        root.check(!adapter.available && adapter.connectionState === "disconnected" && adapter.workspaceRecords.length === 0, "adapter starts unavailable without fabricating compositor state");

        runtime.workspaceRecords = [root.numberedWorkspace(1, "eDP-1", false, false), root.numberedWorkspace(2, "eDP-1", true, false), root.numberedWorkspace(4, "eDP-1", false, true), Object.freeze({
                "id": -98,
                "name": "special:music",
                "monitorName": "eDP-1",
                "active": true,
                "focused": false,
                "urgent": false,
                "hasFullscreen": false
            })];
        runtime.focusedWindowRecord = Object.freeze({
            "address": "0xabc",
            "title": "Fixture window",
            "appId": "org.example.Fixture",
            "windowClass": "fixture",
            "pid": 42,
            "workspaceId": 2,
            "workspaceName": "2",
            "monitorName": "eDP-1",
            "floating": false,
            "fullscreenMode": 1,
            "mapped": true
        });
        runtime.setConnected(true);

        root.check(adapter.available && adapter.connectionState === "ready" && !adapter.stale, "initial connection performs a complete resynchronization");
        root.check(runtime.refreshCount === 1 && adapter.workspaceRecords.length === 4, "initial resynchronization publishes one normalized workspace snapshot");
        root.check(adapter.activeNumberForMonitor("monitor-1") === 2 && adapter.activeNumberForMonitor("monitor-2") === -1, "active numbered state is monitor-aware and never invented");
        root.check(adapter.workspaceRecords.find(record => record.number === 4).urgent, "urgent workspace state remains normalized");
        root.check(JSON.stringify(adapter.specialSnapshot("monitor-1").visibleIds) === JSON.stringify(["music"]), "special workspace compositor name maps to its stable configured ID");
        root.check(adapter.focusedWindow.address === "0xabc" && adapter.focusedWindow.monitorId === "monitor-1" && adapter.focusedWindow.maximized && !adapter.focusedWindow.fullscreen, "focused window is normalized and maximized is not fullscreen");

        const refreshBeforeEvents = runtime.refreshCount;
        for (const eventName of root.eventNames)
            runtime.emitEvent(eventName, "fixture");
        root.check(runtime.refreshCount === refreshBeforeEvents + root.eventNames.length, "every supported event family requests a full authoritative refresh");
        runtime.emitEvent("unknownfutureevent", "fixture");
        root.check(runtime.refreshCount === refreshBeforeEvents + root.eventNames.length && adapter.unknownEventCount === 1 && adapter.lastEventName === "unknownfutureevent", "unknown events are counted without creating refresh storms");
        runtime.emitEvent("", "malformed");
        root.check(adapter.malformedEventCount === 1 && runtime.refreshCount === refreshBeforeEvents + root.eventNames.length + 1, "malformed events are counted and recovered through resynchronization");

        let result = adapter.activateNumberedWorkspace(4, "monitor-1", {
            "source": "fixture"
        });
        root.check(result.accepted && runtime.lastRequest === "hl.dsp.focus({ workspace = \"4\" })", "Lua workspace activation uses a quoted workspace selector at the version-aware command boundary");
        result = adapter.toggleSpecialWorkspace("music", "monitor-1", {
            "source": "fixture"
        });
        root.check(result.accepted && runtime.lastRequest === "hl.dsp.workspace.toggle_special(\"music\")", "Lua special-workspace toggle uses the configured compositor name");
        result = adapter.moveFocusedWindowToNumberedWorkspace(4, false);
        root.check(result.accepted && runtime.lastRequest === "hl.dsp.window.move({ workspace = \"4\", follow = false, window = \"address:0xabc\" })", "focused-window move captures a stable compositor address and quoted workspace selector");
        result = adapter.toggleFocusedWindowFullscreen();
        root.check(result.accepted && runtime.lastRequest === "hl.dsp.window.fullscreen({ mode = \"fullscreen\", action = \"toggle\", window = \"address:0xabc\" })", "fullscreen command explicitly requests true fullscreen rather than maximize");

        runtime.failNextError = "HYPRLAND_DISPATCH_FAILED";
        result = adapter.toggleFocusedWindowFloating();
        root.check(!result.accepted && result.errorCode === "HYPRLAND_DISPATCH_FAILED" && adapter.lastError === result.errorCode, "immediate dispatcher failure is structured and retained");

        runtime.usingLua = false;
        result = adapter.activateNumberedWorkspace(3, "monitor-1", {
            "source": "fixture"
        });
        root.check(result.accepted && runtime.lastRequest === "workspace 3", "legacy workspace syntax remains isolated inside the command boundary");
        result = adapter.toggleSpecialWorkspace("music", "monitor-1", {
            "source": "fixture"
        });
        root.check(result.accepted && runtime.lastRequest === "togglespecialworkspace music", "legacy special-workspace syntax is normalized by the same boundary");

        runtime.setConnected(false);
        root.check(!adapter.available && adapter.connectionState === "disconnected" && adapter.stale && adapter.workspaceRecords.length === 4, "disconnect retains last-known state only as explicitly stale");
        root.check(adapter.activeNumberForMonitor("monitor-1") === -1 && !adapter.specialSnapshot("monitor-1").stateAvailable, "stale state cannot authorize workspace actions");
        result = adapter.activateNumberedWorkspace(1, "monitor-1", {
            "source": "fixture"
        });
        root.check(!result.accepted && result.errorCode === "HYPRLAND_DISCONNECTED", "actions fail closed while the event stream is disconnected");

        runtime.sequence = 2;
        runtime.workspaceRecords = [root.numberedWorkspace(4, "eDP-1", true, false)];
        runtime.focusedWindowRecord = null;
        runtime.setConnected(true);
        root.check(adapter.available && !adapter.stale && adapter.activeNumberForMonitor("monitor-1") === 4 && adapter.focusedWindow === null, "reconnect replaces stale state atomically without shell restart");

        runtime.sequence = 1;
        runtime.workspaceRecords = [root.numberedWorkspace(1, "eDP-1", true, false)];
        runtime.stateChanged();
        root.check(adapter.activeNumberForMonitor("monitor-1") === 4 && adapter.staleSnapshotCount === 1, "out-of-order snapshots cannot overwrite newer compositor state");

        console.info("PASS hyprland-adapter: normalization, events, commands, disconnect, reconnect, malformed input, stale snapshots, and fullscreen semantics");
        Qt.exit(0);
    }

    Component.onCompleted: Qt.callLater(root.run)

    FakeHyprlandRuntime {
        id: runtime
    }
    FakeHyprlandMonitorRegistry {
        id: monitorRegistry
    }
    HyprlandServices.HyprlandAdapter {
        id: adapter

        monitorRegistry: monitorRegistry
        runtime: runtime
        specialDefinitions: Object.freeze([Object.freeze({
                "id": "music",
                "hyprlandName": "music"
            }), Object.freeze({
                "id": "todo",
                "hyprlandName": "todo"
            })])
    }
}
