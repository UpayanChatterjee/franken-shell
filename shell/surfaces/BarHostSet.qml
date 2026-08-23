pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

Scope {
    id: root

    property var audioController: null
    required property var barConfig
    property var batteryController: null
    required property bool fixtureWindow
    readonly property int hostCount: hostVariants.instances.length
    required property var monitorRegistry
    readonly property int resolvedHostCount: controller.count("resolved")
    property var resourceController: null
    required property var surfaceCoordinator
    required property var theme
    property var throughputController: null
    readonly property int visibleHostCount: controller.count("visible")
    required property var workspaceBackend
    required property var workspaceConfig

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
                fixtureWindow: root.fixtureWindow
                monitor: instance.monitor
                resourceController: root.resourceController
                screenInfo: instance.modelData
                surfaceCoordinator: root.surfaceCoordinator
                theme: root.theme
                throughputController: root.throughputController
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
    }
}
