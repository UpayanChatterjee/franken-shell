pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

Scope {
    id: root

    property var audioController: null
    required property var barConfig
    property var batteryController: null
    property var calendarController: null
    property var contextController: null
    property var dateTimeController: null
    required property bool fixtureWindow
    readonly property int hostCount: hostVariants.instances.length
    required property var monitorRegistry
    readonly property int resolvedHostCount: controller.count("resolved")
    property var resourceController: null
    required property var surfaceCoordinator
    required property var theme
    property var throughputController: null
    property var trayController: null
    property var vicinaeAdapter: null
    readonly property int visibleHostCount: controller.count("visible")
    required property var workspaceBackend
    required property var workspaceConfig

    function requestKeyboardFocus(): var {
        const monitor = root.monitorRegistry.focusedWindowMonitor ?? root.monitorRegistry.focusedMonitor ?? root.monitorRegistry.fallbackMonitor;
        if (monitor === null || monitor.connected !== true)
            return controller.result(false, "SURFACE_MONITOR_UNAVAILABLE");
        for (const instance of hostVariants.instances) {
            if (instance.host.ownerMonitorId === monitor.runtimeId)
                return instance.host.requestKeyboardFocus();
        }
        return controller.result(false, "BAR_HOST_UNAVAILABLE");
    }
    function summary(): var {
        const hosts = [];
        for (const instance of hostVariants.instances)
            hosts.push(instance.host.summary());
        return Object.freeze({
            "hostCount": root.hostCount,
            "resolvedHostCount": root.resolvedHostCount,
            "visibleHostCount": root.visibleHostCount,
            "hosts": Object.freeze(hosts)
        });
    }

    Variants {
        id: hostVariants

        model: Quickshell.screens

        Scope {
            id: instance

            readonly property alias host: barHost
            required property ShellScreen modelData
            readonly property var monitor: root.monitorRegistry.monitorForScreen(instance.modelData)

            BarHost {
                id: barHost

                audioController: root.audioController
                barConfig: root.barConfig
                batteryController: root.batteryController
                calendarController: root.calendarController
                contextController: root.contextController
                dateTimeController: root.dateTimeController
                fixtureWindow: root.fixtureWindow
                monitor: instance.monitor
                resourceController: root.resourceController
                screenInfo: instance.modelData
                surfaceCoordinator: root.surfaceCoordinator
                theme: root.theme
                throughputController: root.throughputController
                trayController: root.trayController
                vicinaeAdapter: root.vicinaeAdapter
                workspaceBackend: root.workspaceBackend
                workspaceConfig: root.workspaceConfig
            }
        }
    }
    QtObject {
        id: controller

        function count(kind: string): int {
            let total = 0;
            for (const instance of hostVariants.instances) {
                if (kind === "resolved" && instance.host.ownerMonitorId.length > 0)
                    total += 1;
                else if (kind === "visible" && instance.host.visible)
                    total += 1;
            }
            return total;
        }
        function result(accepted: bool, errorCode: string): var {
            return Object.freeze({
                "accepted": accepted,
                "errorCode": errorCode
            });
        }
    }
}
