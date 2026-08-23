pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.UPower

Scope {
    id: root

    readonly property bool connected: UPower.displayDevice?.ready === true

    signal connectionChanged(bool connected)
    signal stateChanged

    function chargingState(device): string {
        switch (device?.state) {
        case UPowerDeviceState.Charging:
            return "charging";
        case UPowerDeviceState.Discharging:
            return "discharging";
        case UPowerDeviceState.Empty:
            return "empty";
        case UPowerDeviceState.FullyCharged:
            return "full";
        case UPowerDeviceState.PendingCharge:
            return "pendingCharge";
        case UPowerDeviceState.PendingDischarge:
            return "pendingDischarge";
        default:
            return "unknown";
        }
    }
    function requestRefresh() {
        if (!root.connected)
            return;
        state.sequence += 1;
        root.stateChanged();
    }
    function scheduleChanged() {
        refreshTimer.restart();
    }
    function snapshot(): var {
        const device = UPower.displayDevice;
        if (device === null || device.isPresent !== true || device.isLaptopBattery !== true) {
            return Object.freeze({
                "sequence": state.sequence,
                "battery": null
            });
        }
        const status = root.chargingState(device);
        const estimate = status === "charging" ? Number(device.timeToFull) : status === "discharging" ? Number(device.timeToEmpty) : -1;
        return Object.freeze({
            "sequence": state.sequence,
            "battery": Object.freeze({
                "present": true,
                "percentage": Number(device.percentage) * 100,
                "chargingState": status,
                "powerSource": UPower.onBattery ? "battery" : "linePower",
                "timeEstimateSeconds": estimate,
                "estimateCredible": false
            })
        });
    }

    Component.onCompleted: {
        if (root.connected)
            Qt.callLater(root.requestRefresh);
    }
    onConnectedChanged: {
        root.connectionChanged(root.connected);
        if (root.connected)
            Qt.callLater(root.requestRefresh);
    }

    QtObject {
        id: state

        property int sequence: 0
    }
    Timer {
        id: refreshTimer

        interval: 0

        onTriggered: root.requestRefresh()
    }
    Connections {
        function onOnBatteryChanged() {
            root.scheduleChanged();
        }

        target: UPower
    }
    Connections {
        function onIsLaptopBatteryChanged() {
            root.scheduleChanged();
        }
        function onIsPresentChanged() {
            root.scheduleChanged();
        }
        function onPercentageChanged() {
            root.scheduleChanged();
        }
        function onReadyChanged() {
            root.scheduleChanged();
        }
        function onStateChanged() {
            root.scheduleChanged();
        }
        function onTimeToEmptyChanged() {
            root.scheduleChanged();
        }
        function onTimeToFullChanged() {
            root.scheduleChanged();
        }

        target: UPower.displayDevice
    }
}
