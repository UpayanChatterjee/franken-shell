pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

Scope {
    id: root

    required property var controller
    required property bool fixtureWindow
    required property var monitorRegistry
    required property var theme
    readonly property int visibleHostCount: controllerState.visibleHostCount

    Variants {
        id: hostVariants

        model: Quickshell.screens

        Scope {
            id: instance

            required property ShellScreen modelData
            readonly property var monitor: root.monitorRegistry.monitorForScreen(instance.modelData)
            readonly property var window: windowLoader.status === Loader.Ready ? windowLoader.item : null

            Component.onCompleted: windowLoader.setSource(Qt.resolvedUrl(root.fixtureWindow ? "NotificationPopupFixtureWindow.qml" : "NotificationPopupPanelWindow.qml"), {
                "controller": root.controller,
                "monitor": instance.monitor,
                "screenInfo": instance.modelData,
                "theme": root.theme
            })

            Loader {
                id: windowLoader
            }
            Binding {
                property: "controller"
                target: instance.window
                value: root.controller
                when: instance.window !== null
            }
            Binding {
                property: "monitor"
                target: instance.window
                value: instance.monitor
                when: instance.window !== null
            }
            Binding {
                property: "screenInfo"
                target: instance.window
                value: instance.modelData
                when: instance.window !== null
            }
            Binding {
                property: "theme"
                target: instance.window
                value: root.theme
                when: instance.window !== null
            }
        }
    }
    QtObject {
        id: controllerState

        readonly property int visibleHostCount: {
            void root.controller.popupRevision;
            let total = 0;
            for (const instance of hostVariants.instances) {
                if (root.controller.popupsForMonitor(String(instance.monitor?.runtimeId ?? "")).length > 0)
                    total += 1;
            }
            return total;
        }
    }
}
