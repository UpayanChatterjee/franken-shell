pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

Scope {
    id: root

    readonly property string backendAvailability: root.connected ? Hyprland.monitors.values.length > 0 ? "available" : "degraded" : "unavailable"
    readonly property bool connected: eventSocket.connected
    readonly property bool usingLua: Hyprland.usingLua

    signal connectionChanged(bool connected)
    signal eventReceived(string name, string data)
    signal stateChanged

    function dispatch(request: string): var {
        if (!root.connected)
            return root.result(false, "HYPRLAND_DISCONNECTED");
        if (request.length === 0)
            return root.result(false, "HYPRLAND_INVALID_COMMAND");
        try {
            Hyprland.dispatch(request);
            return root.result(true, "");
        } catch (error) {
            return root.result(false, "HYPRLAND_DISPATCH_FAILED");
        }
    }
    function focusedWindowSnapshot(): var {
        const window = Hyprland.activeToplevel;
        if (window === null)
            return null;
        const raw = window.lastIpcObject ?? {};
        return Object.freeze({
            "address": String(window.address ?? raw.address ?? ""),
            "title": String(window.title ?? raw.title ?? ""),
            "appId": String(raw.initialClass ?? raw.class ?? ""),
            "windowClass": String(raw.class ?? ""),
            "pid": Number(raw.pid ?? -1),
            "workspaceId": Number(window.workspace?.id ?? raw.workspace?.id ?? -1),
            "workspaceName": String(window.workspace?.name ?? raw.workspace?.name ?? ""),
            "monitorName": String(window.monitor?.name ?? ""),
            "floating": raw.floating === true,
            "fullscreenMode": Number(raw.fullscreen ?? 0),
            "mapped": raw.mapped !== false
        });
    }
    function monitorSnapshot(): var {
        const screens = [];
        for (const screen of Quickshell.screens) {
            screens.push({
                "ref": screen,
                "mappedMonitorRef": Hyprland.monitorFor(screen),
                "name": screen.name,
                "model": screen.model,
                "serialNumber": screen.serialNumber,
                "x": screen.x,
                "y": screen.y,
                "width": screen.width,
                "height": screen.height,
                "devicePixelRatio": screen.devicePixelRatio,
                "orientation": screen.orientation
            });
        }

        const monitors = [];
        for (const monitor of Hyprland.monitors.values) {
            const workspace = monitor.activeWorkspace;
            monitors.push({
                "ref": monitor,
                "id": monitor.id,
                "name": monitor.name,
                "description": monitor.description,
                "x": monitor.x,
                "y": monitor.y,
                "width": monitor.width,
                "height": monitor.height,
                "scale": monitor.scale,
                "focused": monitor.focused,
                "raw": monitor.lastIpcObject,
                "activeWorkspace": workspace === null ? null : {
                    "id": workspace.id,
                    "hasFullscreen": workspace.hasFullscreen
                }
            });
        }

        const focusedMonitor = Hyprland.focusedMonitor;
        const windowMonitor = Hyprland.activeToplevel?.monitor ?? null;
        return {
            "screens": screens,
            "hyprlandMonitors": monitors,
            "focusedMonitorRef": focusedMonitor,
            "focusedMonitorId": focusedMonitor?.id ?? -1,
            "focusedMonitorName": focusedMonitor?.name ?? "",
            "focusedWindowMonitorRef": windowMonitor,
            "focusedWindowMonitorId": windowMonitor?.id ?? -1,
            "focusedWindowMonitorName": windowMonitor?.name ?? "",
            "backendAvailability": root.backendAvailability
        };
    }
    function parseEvent(line: string) {
        const separator = line.indexOf(">>");
        if (separator < 1) {
            root.eventReceived("", line);
            return;
        }
        root.eventReceived(line.slice(0, separator), line.slice(separator + 2));
    }
    function requestReconnect() {
        eventSocket.connected = false;
        reconnectTimer.restart();
    }
    function requestRefresh() {
        if (!root.connected)
            return;
        state.sequence += 1;
        for (const screen of Quickshell.screens)
            Hyprland.monitorFor(screen);
        Hyprland.refreshMonitors();
        Hyprland.refreshWorkspaces();
        Hyprland.refreshToplevels();
        refreshSettled.restart();
    }
    function result(accepted: bool, errorCode: string): var {
        return Object.freeze({
            "accepted": accepted,
            "errorCode": errorCode
        });
    }
    function scheduleChanged() {
        modelChanged.restart();
    }
    function snapshot(): var {
        const monitor = root.monitorSnapshot();
        return Object.freeze(Object.assign({}, monitor, {
            "sequence": state.sequence,
            "workspaces": root.workspaceSnapshot(),
            "focusedWindow": root.focusedWindowSnapshot()
        }));
    }
    function visibleSpecialMonitor(workspace): string {
        if (!String(workspace?.name ?? "").startsWith("special:"))
            return "";
        for (const monitor of Hyprland.monitors.values) {
            const special = monitor.lastIpcObject?.specialWorkspace ?? null;
            if (special !== null && (Number(special.id ?? -1) === Number(workspace.id) || String(special.name ?? "") === String(workspace.name)))
                return String(monitor.name ?? "");
        }
        return "";
    }
    function workspaceSnapshot(): var {
        const records = [];
        for (const workspace of Hyprland.workspaces.values) {
            const raw = workspace.lastIpcObject ?? {};
            const visibleSpecialMonitor = root.visibleSpecialMonitor(workspace);
            records.push(Object.freeze({
                "id": workspace.id,
                "name": workspace.name,
                "monitorName": visibleSpecialMonitor.length > 0 ? visibleSpecialMonitor : workspace.monitor?.name ?? String(raw.monitor ?? ""),
                "active": workspace.active || visibleSpecialMonitor.length > 0,
                "focused": workspace.focused,
                "urgent": workspace.urgent,
                "hasFullscreen": workspace.hasFullscreen
            }));
        }
        return Object.freeze(records);
    }

    QtObject {
        id: state

        property int sequence: 0
    }
    Socket {
        id: eventSocket

        connected: true
        path: Hyprland.eventSocketPath

        parser: SplitParser {
            splitMarker: "\n"

            onRead: data => root.parseEvent(data)
        }

        onConnectionStateChanged: {
            root.connectionChanged(eventSocket.connected);
            if (eventSocket.connected)
                Qt.callLater(root.requestRefresh);
            else
                reconnectTimer.restart();
        }
    }
    Timer {
        id: reconnectTimer

        interval: 1000

        onTriggered: eventSocket.connected = true
    }
    Timer {
        id: refreshSettled

        interval: 20

        onTriggered: root.stateChanged()
    }
    Timer {
        id: modelChanged

        interval: 0

        onTriggered: root.stateChanged()
    }
    Connections {
        function onScreensChanged() {
            root.scheduleChanged();
        }

        target: Quickshell
    }
    Connections {
        function onActiveToplevelChanged() {
            root.scheduleChanged();
        }
        function onFocusedMonitorChanged() {
            root.scheduleChanged();
        }
        function onFocusedWorkspaceChanged() {
            root.scheduleChanged();
        }

        target: Hyprland
    }
    Connections {
        function onValuesChanged() {
            root.scheduleChanged();
        }

        target: Hyprland.monitors
    }
    Connections {
        function onValuesChanged() {
            root.scheduleChanged();
        }

        target: Hyprland.workspaces
    }
    Connections {
        function onValuesChanged() {
            root.scheduleChanged();
        }

        target: Hyprland.toplevels
    }
    Instantiator {
        model: Hyprland.monitors

        delegate: Connections {
            required property var modelData

            function onActiveWorkspaceChanged() {
                root.scheduleChanged();
            }
            function onFocusedChanged() {
                root.scheduleChanged();
            }
            function onLastIpcObjectChanged() {
                root.scheduleChanged();
            }

            target: modelData
        }
    }
    Instantiator {
        model: Hyprland.workspaces

        delegate: Connections {
            required property var modelData

            function onActiveChanged() {
                root.scheduleChanged();
            }
            function onFocusedChanged() {
                root.scheduleChanged();
            }
            function onHasFullscreenChanged() {
                root.scheduleChanged();
            }
            function onMonitorChanged() {
                root.scheduleChanged();
            }
            function onUrgentChanged() {
                root.scheduleChanged();
            }

            target: modelData
        }
    }
    Instantiator {
        model: Hyprland.toplevels

        delegate: Connections {
            required property var modelData

            function onActivatedChanged() {
                root.scheduleChanged();
            }
            function onLastIpcObjectChanged() {
                root.scheduleChanged();
            }
            function onMonitorChanged() {
                root.scheduleChanged();
            }
            function onUrgentChanged() {
                root.scheduleChanged();
            }
            function onWorkspaceChanged() {
                root.scheduleChanged();
            }

            target: modelData
        }
    }
}
