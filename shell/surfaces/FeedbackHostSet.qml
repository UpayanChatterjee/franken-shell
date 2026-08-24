pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

Scope {
    id: root

    required property bool fixtureWindow
    required property var monitorRegistry
    required property var osdService
    required property var theme
    required property var toastService

    Variants {
        model: Quickshell.screens

        FeedbackMonitorHost {
            required property ShellScreen modelData

            fixtureWindow: root.fixtureWindow
            monitor: root.monitorRegistry.monitorForScreen(modelData)
            osdService: root.osdService
            screenInfo: modelData
            theme: root.theme
            toastService: root.toastService
        }
    }
}
