import QtQuick
import Quickshell

Scope {
    id: root

    required property bool fixtureWindow
    required property var monitor
    required property var osdService
    readonly property var osdWindow: osdLoader.status === Loader.Ready ? osdLoader.item : null
    required property var screenInfo
    required property var theme
    required property var toastService
    readonly property var toastWindow: toastLoader.status === Loader.Ready ? toastLoader.item : null

    Component.onCompleted: {
        osdLoader.setSource(Qt.resolvedUrl(root.fixtureWindow ? "OsdFixtureWindow.qml" : "OsdPanelWindow.qml"), {
            "monitor": root.monitor,
            "screenInfo": root.screenInfo,
            "service": root.osdService,
            "theme": root.theme
        });
        toastLoader.setSource(Qt.resolvedUrl(root.fixtureWindow ? "ToastFixtureWindow.qml" : "ToastPanelWindow.qml"), {
            "monitor": root.monitor,
            "screenInfo": root.screenInfo,
            "service": root.toastService,
            "theme": root.theme
        });
    }

    Loader {
        id: osdLoader
    }
    Loader {
        id: toastLoader
    }
    Binding {
        property: "monitor"
        target: root.osdWindow
        value: root.monitor
        when: root.osdWindow !== null
    }
    Binding {
        property: "monitor"
        target: root.toastWindow
        value: root.monitor
        when: root.toastWindow !== null
    }
    Binding {
        property: "screenInfo"
        target: root.osdWindow
        value: root.screenInfo
        when: root.osdWindow !== null
    }
    Binding {
        property: "screenInfo"
        target: root.toastWindow
        value: root.screenInfo
        when: root.toastWindow !== null
    }
    Binding {
        property: "service"
        target: root.osdWindow
        value: root.osdService
        when: root.osdWindow !== null
    }
    Binding {
        property: "service"
        target: root.toastWindow
        value: root.toastService
        when: root.toastWindow !== null
    }
    Binding {
        property: "theme"
        target: root.osdWindow
        value: root.theme
        when: root.osdWindow !== null
    }
    Binding {
        property: "theme"
        target: root.toastWindow
        value: root.theme
        when: root.toastWindow !== null
    }
}
