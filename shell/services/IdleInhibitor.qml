pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import Quickshell.Wayland
import Caelestia

Singleton {
    id: root

    property alias enabled: props.enabled
    readonly property alias enabledSince: props.enabledSince

    // distinguishes the unplug auto-off from a manual off for the toast
    property bool autoDisabling: false

    onEnabledChanged: {
        if (enabled) {
            props.enabledSince = new Date();
            props.enabledOnBattery = UPower.onBattery;
            Toaster.toast(qsTr("Keep awake enabled"), qsTr("The screen will stay on"), "coffee");
        } else if (autoDisabling) {
            autoDisabling = false;
            Toaster.toast(qsTr("Keep awake disabled"), qsTr("Charger was unplugged"), "power_off");
        } else {
            Toaster.toast(qsTr("Keep awake disabled"), qsTr("Normal power management restored"), "coffee");
        }
    }

    PersistentProperties {
        id: props

        property bool enabled
        property date enabledSince
        property bool enabledOnBattery

        reloadableId: "idleInhibitor"
    }

    Connections {
        function onOnBatteryChanged(): void {
            if (UPower.onBattery && props.enabled && !props.enabledOnBattery) {
                root.autoDisabling = true;
                props.enabled = false;
            }
        }

        target: UPower
    }

    IdleInhibitor {
        enabled: props.enabled
        window: PanelWindow {
            implicitWidth: 0
            implicitHeight: 0
            color: "transparent"
            mask: Region {}
        }
    }

    IpcHandler {
        function isEnabled(): bool {
            return props.enabled;
        }

        function toggle(): void {
            props.enabled = !props.enabled;
        }

        function enable(): void {
            props.enabled = true;
        }

        function disable(): void {
            props.enabled = false;
        }

        target: "idleInhibitor"
    }
}
