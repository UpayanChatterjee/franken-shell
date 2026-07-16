pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland

Scope {
    id: root

    readonly property string backendAvailability: Hyprland.monitors.values.length > 0
        ? "available" : Quickshell.screens.length > 0 ? "degraded" : "idle"
    signal stateChanged

    function requestRefresh() {
        // Quickshell 0.3.0 refreshes existing monitor objects but does not create
        // them. Resolve connected screens first so the initial request has
        // objects to populate even when Qt screens win the startup race.
        for (const screen of Quickshell.screens)
            Hyprland.monitorFor(screen);
        Hyprland.refreshMonitors();
        Hyprland.refreshWorkspaces();
        Hyprland.refreshToplevels();
        changeTimer.restart();
    }

    function snapshot() {
        const screens = [];
        for (const screen of Quickshell.screens) {
            screens.push({
                ref: screen,
                mappedMonitorRef: Hyprland.monitorFor(screen),
                name: screen.name,
                model: screen.model,
                serialNumber: screen.serialNumber,
                x: screen.x,
                y: screen.y,
                width: screen.width,
                height: screen.height,
                devicePixelRatio: screen.devicePixelRatio,
                orientation: screen.orientation
            });
        }

        const monitors = [];
        for (const monitor of Hyprland.monitors.values) {
            const workspace = monitor.activeWorkspace;
            monitors.push({
                ref: monitor,
                id: monitor.id,
                name: monitor.name,
                description: monitor.description,
                x: monitor.x,
                y: monitor.y,
                width: monitor.width,
                height: monitor.height,
                scale: monitor.scale,
                focused: monitor.focused,
                raw: monitor.lastIpcObject,
                activeWorkspace: workspace === null ? null : {
                    id: workspace.id,
                    hasFullscreen: workspace.hasFullscreen
                }
            });
        }

        const focused = Hyprland.focusedMonitor;
        const windowMonitor = Hyprland.activeToplevel?.monitor ?? null;
        return {
            screens: screens,
            hyprlandMonitors: monitors,
            focusedMonitorRef: focused,
            focusedMonitorId: focused?.id ?? -1,
            focusedMonitorName: focused?.name ?? "",
            focusedWindowMonitorRef: windowMonitor,
            focusedWindowMonitorId: windowMonitor?.id ?? -1,
            focusedWindowMonitorName: windowMonitor?.name ?? "",
            backendAvailability: root.backendAvailability
        };
    }

    function scheduleChanged() {
        changeTimer.restart();
    }

    Timer {
        id: changeTimer

        interval: 0
        onTriggered: root.stateChanged()
    }

    Connections {
        target: Quickshell

        function onScreensChanged() {
            root.scheduleChanged();
        }
    }

    Connections {
        target: Hyprland

        function onFocusedMonitorChanged() {
            root.scheduleChanged();
        }

        function onActiveToplevelChanged() {
            root.scheduleChanged();
        }

        function onRawEvent(event) {
            const name = String(event?.name ?? "");
            if (name !== "monitoraddedv2" && name !== "monitorremoved"
                    && name !== "moveworkspacev2" && name !== "workspacev2"
                    && name !== "focusedmon" && name !== "fullscreen")
                return;
            Hyprland.refreshMonitors();
            Hyprland.refreshWorkspaces();
            root.scheduleChanged();
        }
    }

    Connections {
        target: Hyprland.monitors

        function onValuesChanged() {
            root.scheduleChanged();
        }
    }

    Connections {
        target: Hyprland.workspaces

        function onValuesChanged() {
            root.scheduleChanged();
        }
    }

    Instantiator {
        model: Hyprland.monitors

        delegate: Connections {
            required property var modelData
            target: modelData

            function onIdChanged() { root.scheduleChanged(); }
            function onNameChanged() { root.scheduleChanged(); }
            function onDescriptionChanged() { root.scheduleChanged(); }
            function onXChanged() { root.scheduleChanged(); }
            function onYChanged() { root.scheduleChanged(); }
            function onWidthChanged() { root.scheduleChanged(); }
            function onHeightChanged() { root.scheduleChanged(); }
            function onScaleChanged() { root.scheduleChanged(); }
            function onLastIpcObjectChanged() { root.scheduleChanged(); }
            function onActiveWorkspaceChanged() { root.scheduleChanged(); }
            function onFocusedChanged() { root.scheduleChanged(); }
        }
    }

    Instantiator {
        model: Hyprland.workspaces

        delegate: Connections {
            required property var modelData
            target: modelData

            function onHasFullscreenChanged() { root.scheduleChanged(); }
            function onMonitorChanged() { root.scheduleChanged(); }
        }
    }

    Component.onCompleted: root.requestRefresh()
}
