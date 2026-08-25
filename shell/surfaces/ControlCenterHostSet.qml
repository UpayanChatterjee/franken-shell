pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

Scope {
    id: root

    property var audioController: null
    property var bluetoothController: null
    readonly property int bluetoothPageOpenCount: controller.count("bluetooth")
    property var brightnessController: null
    property var commandRegistry: null
    required property var controlCenterConfig
    property var feedbackController: null
    required property bool fixtureWindow
    readonly property int hostCount: hostVariants.instances.length
    required property var monitorRegistry
    property var networkController: null
    readonly property int networkPageOpenCount: controller.count("network")
    property var notificationController: null
    readonly property int notificationViewOpenCount: controller.count("notifications")
    readonly property int openHostCount: controller.count("open")
    readonly property int resolvedHostCount: controller.count("resolved")
    required property var surfaceCoordinator
    required property var theme
    readonly property int visibleScrimCount: controller.count("scrim")

    function requestKeyboardToggle(): var {
        if (root.controlCenterConfig?.enabled !== true)
            return controller.result(false, "CONTROL_CENTER_DISABLED");
        const monitor = root.monitorRegistry.focusedWindowMonitor ?? root.monitorRegistry.focusedMonitor ?? root.monitorRegistry.fallbackMonitor;
        if (monitor === null || monitor.connected !== true)
            return controller.result(false, "SURFACE_MONITOR_UNAVAILABLE");
        return root.surfaceCoordinator.toggleMajor("controlCenter", {
            "monitorId": monitor.runtimeId,
            "origin": "keyboard",
            "originControlId": "shortcut.controlCenter",
            "previousFocusToken": "",
            "takesFocus": true
        });
    }
    function summary(): var {
        const hosts = [];
        for (const instance of hostVariants.instances)
            hosts.push(instance.host.summary());
        return Object.freeze({
            "hostCount": root.hostCount,
            "resolvedHostCount": root.resolvedHostCount,
            "openHostCount": root.openHostCount,
            "visibleScrimCount": root.visibleScrimCount,
            "primitive": "PanelWindow",
            "hosts": Object.freeze(hosts)
        });
    }

    Variants {
        id: hostVariants

        model: Quickshell.screens

        Scope {
            id: instance

            readonly property alias host: controlCenterHost
            required property ShellScreen modelData
            readonly property var monitor: root.monitorRegistry.monitorForScreen(instance.modelData)

            ControlCenterHost {
                id: controlCenterHost

                audioController: root.audioController
                bluetoothController: root.bluetoothController
                brightnessController: root.brightnessController
                commandRegistry: root.commandRegistry
                controlCenterConfig: root.controlCenterConfig
                feedbackController: root.feedbackController
                fixtureWindow: root.fixtureWindow
                monitor: instance.monitor
                networkController: root.networkController
                notificationController: root.notificationController
                screenInfo: instance.modelData
                surfaceCoordinator: root.surfaceCoordinator
                theme: root.theme
            }
        }
    }
    QtObject {
        id: controller

        function count(kind: string): int {
            let total = 0;
            for (const instance of hostVariants.instances) {
                const summary = instance.host.summary();
                if (kind === "resolved" && summary.monitorId.length > 0)
                    total += 1;
                else if (kind === "open" && summary.open)
                    total += 1;
                else if (kind === "scrim" && summary.scrimVisible)
                    total += 1;
                else if (kind === "network" && summary.open && summary.activePage === "network")
                    total += 1;
                else if (kind === "bluetooth" && summary.open && summary.activePage === "bluetooth")
                    total += 1;
                else if (kind === "notifications" && summary.open && summary.activePage === "main" && summary.activeTab === "notifications")
                    total += 1;
            }
            return total;
        }
        function result(accepted: bool, errorCode: string): var {
            return Object.freeze({
                "accepted": accepted,
                "changed": false,
                "errorCode": errorCode,
                "revision": root.surfaceCoordinator.revision ?? 0
            });
        }
    }
}
