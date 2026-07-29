import QtQuick
import Quickshell

Scope {
    id: root

    readonly property string backendAvailability: "unavailable"

    signal stateChanged

    function requestRefresh() {
    }
    function snapshot() {
        return {
            "screens": [],
            "hyprlandMonitors": [],
            "focusedMonitorRef": null,
            "focusedMonitorId": -1,
            "focusedMonitorName": "",
            "focusedWindowMonitorRef": null,
            "focusedWindowMonitorId": -1,
            "focusedWindowMonitorName": "",
            "backendAvailability": root.backendAvailability
        };
    }
}
