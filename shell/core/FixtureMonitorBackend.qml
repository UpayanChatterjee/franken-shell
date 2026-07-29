import QtQuick
import Quickshell

Scope {
    id: root

    readonly property string backendAvailability: "fixture"

    signal stateChanged

    function requestRefresh() {
        root.stateChanged();
    }
    function snapshot(): var {
        const screens = [];
        const monitors = [];
        for (const screen of Quickshell.screens) {
            const backendId = screens.length;
            screens.push({
                "ref": screen,
                "mappedMonitorRef": screen,
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
            monitors.push({
                "ref": screen,
                "id": backendId,
                "name": screen.name,
                "description": screen.model,
                "x": screen.x,
                "y": screen.y,
                "width": screen.width * screen.devicePixelRatio,
                "height": screen.height * screen.devicePixelRatio,
                "scale": screen.devicePixelRatio,
                "focused": backendId === 0,
                "raw": {
                    "make": "",
                    "model": screen.model,
                    "serial": screen.serialNumber,
                    "primary": backendId === 0
                },
                "activeWorkspace": {
                    "id": 1,
                    "hasFullscreen": false
                }
            });
        }
        return {
            "screens": screens,
            "hyprlandMonitors": monitors,
            "focusedMonitorRef": monitors.length > 0 ? monitors[0].ref : null,
            "focusedMonitorId": monitors.length > 0 ? monitors[0].id : -1,
            "focusedMonitorName": monitors.length > 0 ? monitors[0].name : "",
            "focusedWindowMonitorRef": monitors.length > 0 ? monitors[0].ref : null,
            "focusedWindowMonitorId": monitors.length > 0 ? monitors[0].id : -1,
            "focusedWindowMonitorName": monitors.length > 0 ? monitors[0].name : "",
            "backendAvailability": root.backendAvailability
        };
    }

    Connections {
        function onScreensChanged() {
            root.stateChanged();
        }

        target: Quickshell
    }
}
