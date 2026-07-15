pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Services.UPower
import Caelestia.Config
import Caelestia.Services
import M3Shapes
import qs.components
import qs.components.controls
import qs.services
import qs.utils

Item {
    id: root

    property color colour: Colours.palette.m3secondary
    readonly property alias items: iconColumn
    readonly property alias sysmon: sysmonLoader
    readonly property alias netspeed: netspeedLoader

    implicitWidth: pill.implicitWidth
    implicitHeight:
        (sysmonLoader.active ? sysmonLoader.implicitHeight + Tokens.spacing.medium / 2 : 0) +
        (netspeedLoader.active ? netspeedLoader.implicitHeight + Tokens.spacing.medium / 2 : 0) +
        pill.implicitHeight

    // System monitor - CPU and RAM usage, bare on the taskbar
    Loader {
        id: sysmonLoader
        active: BarConfig.showCpu || BarConfig.showRam
        asynchronous: true
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter

        sourceComponent: Item {
            implicitWidth: column.implicitWidth
            implicitHeight: column.implicitHeight

            ColumnLayout {
                id: column

                spacing: 0

                CircularProgress {
                    visible: BarConfig.showRam
                    implicitSize: 26
                    value: Memory.percentage
                    strokeWidth: 2
                    fgColour: Colours.palette.m3tertiary

                    Behavior on clampedVal {
                        Anim {}
                    }

                    StyledText {
                        anchors.centerIn: parent
                        text: Math.round(Memory.percentage * 100)
                        font.pixelSize: 10
                        font.bold: true
                        color: Colours.palette.m3tertiary
                    }
                }

                MaterialShape {
                    visible: BarConfig.showCpu
                    implicitSize: 26
                    color: Colours.palette.m3secondaryContainer
                    shape: {
                        if (Cpu.percentage >= 0.8)
                            return MaterialShape.SoftBurst;
                        if (Cpu.percentage >= 0.4)
                            return MaterialShape.Sunny;
                        return MaterialShape.Cookie4Sided;
                    }

                    Behavior on color {
                        CAnim {}
                    }

                    StyledText {
                        anchors.centerIn: parent
                        text: Math.round(Cpu.percentage * 100)
                        font.pixelSize: 10
                        font.bold: true
                        color: Colours.palette.m3primary
                    }
                }
            }

            ServiceRef { service: Cpu }
            ServiceRef { service: Memory }
        }
    }

    // Network speed - bare on the taskbar
    Loader {
        id: netspeedLoader
        active: BarConfig.showUpload || BarConfig.showDownload
        asynchronous: true
        anchors.top: sysmonLoader.active ? sysmonLoader.bottom : parent.top
        anchors.topMargin: sysmonLoader.active ? Tokens.spacing.medium / 2 : 0
        anchors.horizontalCenter: parent.horizontalCenter

        sourceComponent: ColumnLayout {
            spacing: 0

            RowLayout {
                visible: BarConfig.showUpload
                Layout.alignment: Qt.AlignHCenter
                spacing: 0

                StyledText {
                    text: "↑"
                    color: Qt.alpha(root.colour, 0.7)
                }
                StyledText {
                    text: {
                        const speed = NetworkUsage.uploadSpeed ?? 0;
                        if (speed < 1024) return "0";
                        const fmt = NetworkUsage.formatBytes(speed);
                        return fmt ? Math.round(fmt.value) + fmt.unit[0] : "0";
                    }
                    color: Qt.alpha(root.colour, 0.7)
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 11
                    font.bold: true
                }
            }

            RowLayout {
                visible: BarConfig.showDownload
                Layout.alignment: Qt.AlignHCenter
                spacing: 0

                StyledText {
                    text: "↓"
                    color: root.colour
                }
                StyledText {
                    text: {
                        const speed = NetworkUsage.downloadSpeed ?? 0;
                        if (speed < 1024) return "0";
                        const fmt = NetworkUsage.formatBytes(speed);
                        return fmt ? Math.round(fmt.value) + fmt.unit[0] : "0";
                    }
                    color: root.colour
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 11
                    font.bold: true
                }
            }
        }
    }

    Binding {
        target: NetworkUsage
        property: "refCount"
        value: Config.bar.status.showNetwork || BarConfig.showUpload || BarConfig.showDownload ? 1 : 0
    }

    // Pill background with remaining status icons
    StyledRect {
        id: pill

        anchors.top: netspeedLoader.active ? netspeedLoader.bottom : (sysmonLoader.active ? sysmonLoader.bottom : parent.top)
        anchors.topMargin: (netspeedLoader.active || sysmonLoader.active) ? Tokens.spacing.medium / 2 : 0

        color: Colours.tPalette.m3surfaceContainer
        radius: Tokens.rounding.full

        clip: true
        implicitWidth: Tokens.sizes.bar.innerWidth
        implicitHeight: iconColumn.implicitHeight + Tokens.padding.medium * 2 - (Config.bar.status.showLockStatus && !Hypr.capsLock && !Hypr.numLock ? iconColumn.spacing : 0)

        ColumnLayout {
            id: iconColumn

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Tokens.padding.medium

            spacing: Tokens.spacing.medium / 2

            // Lock keys status
            WrappedLoader {
                name: "lockstatus"
                active: Config.bar.status.showLockStatus

                sourceComponent: ColumnLayout {
                    spacing: 0

                    Item {
                        implicitWidth: capslockIcon.implicitWidth
                        implicitHeight: Hypr.capsLock ? capslockIcon.implicitHeight : 0

                        MaterialIcon {
                            id: capslockIcon

                            anchors.centerIn: parent

                            scale: Hypr.capsLock ? 1 : 0.5
                            opacity: Hypr.capsLock ? 1 : 0

                            text: "keyboard_capslock_badge"
                            color: root.colour

                            Behavior on opacity {
                                Anim {
                                    type: Anim.DefaultEffects
                                }
                            }

                            Behavior on scale {
                                Anim {}
                            }
                        }

                        Behavior on implicitHeight {
                            Anim {}
                        }
                    }

                    Item {
                        Layout.topMargin: Hypr.capsLock && Hypr.numLock ? iconColumn.spacing : 0

                        implicitWidth: numlockIcon.implicitWidth
                        implicitHeight: Hypr.numLock ? numlockIcon.implicitHeight : 0

                        MaterialIcon {
                            id: numlockIcon

                            anchors.centerIn: parent

                            scale: Hypr.numLock ? 1 : 0.5
                            opacity: Hypr.numLock ? 1 : 0

                            text: "looks_one"
                            color: root.colour

                            Behavior on opacity {
                                Anim {
                                    type: Anim.DefaultEffects
                                }
                            }

                            Behavior on scale {
                                Anim {}
                            }
                        }

                        Behavior on implicitHeight {
                            Anim {}
                        }
                    }
                }
            }

            // Audio icon
            WrappedLoader {
                name: "audio"
                active: Config.bar.status.showAudio

                sourceComponent: MaterialIcon {
                    animate: true
                    text: Icons.getVolumeIcon(Audio.volume, Audio.muted)
                    color: root.colour
                }
            }

            // Microphone icon
            WrappedLoader {
                name: "audio"
                active: Config.bar.status.showMicrophone

                sourceComponent: MaterialIcon {
                    animate: true
                    text: Icons.getMicVolumeIcon(Audio.sourceVolume, Audio.sourceMuted)
                    color: root.colour
                }
            }

            // Keyboard layout icon
            WrappedLoader {
                name: "kblayout"
                active: Config.bar.status.showKbLayout

                sourceComponent: StyledText {
                    animate: true
                    text: Hypr.kbLayout
                    color: root.colour
                    font: Tokens.font.mono.medium
                }
            }

            // Network icon
            WrappedLoader {
                name: "network"
                active: Config.bar.status.showNetwork && (!Nmcli.activeEthernet || Config.bar.status.showWifi)

                sourceComponent: MaterialIcon {
                    animate: true
                    text: Nmcli.active ? Icons.getNetworkIcon(Nmcli.active.strength ?? 0) : "wifi_off"
                    color: root.colour
                }
            }

            // Ethernet icon
            WrappedLoader {
                name: "ethernet"
                active: Config.bar.status.showNetwork && Nmcli.activeEthernet

                sourceComponent: MaterialIcon {
                    animate: true
                    text: "cable"
                    color: root.colour
                }
            }

            // Bluetooth section
            WrappedLoader {
                Layout.preferredHeight: implicitHeight

                name: "bluetooth"
                active: Config.bar.status.showBluetooth

                sourceComponent: ColumnLayout {
                    spacing: Tokens.spacing.medium / 2

                    // Bluetooth icon
                    MaterialIcon {
                        animate: true
                        text: {
                            if (!Bluetooth.defaultAdapter?.enabled) // qmllint disable unresolved-type
                                return "bluetooth_disabled";
                            if (Bluetooth.devices.values.some(d => d.connected)) // qmllint disable unresolved-type
                                return "bluetooth_connected";
                            return "bluetooth";
                        }
                        color: root.colour
                    }

                    // Connected bluetooth devices
                    Repeater {
                        model: ScriptModel {
                            values: Bluetooth.devices.values.filter(d => d.state !== BluetoothDeviceState.Disconnected) // qmllint disable unresolved-type
                        }

                        MaterialIcon {
                            id: device

                            required property BluetoothDevice modelData

                            animate: true
                            text: Icons.getBluetoothIcon(modelData?.icon)
                            color: root.colour
                            fill: 1

                            SequentialAnimation on opacity {
                                running: device.modelData?.state !== BluetoothDeviceState.Connected // qmllint disable unresolved-type
                                alwaysRunToEnd: true
                                loops: Animation.Infinite

                                Anim {
                                    from: 1
                                    to: 0
                                    duration: Tokens.anim.durations.large
                                    easing: Tokens.anim.standardAccel
                                }
                                Anim {
                                    from: 0
                                    to: 1
                                    duration: Tokens.anim.durations.large
                                    easing: Tokens.anim.standardDecel
                                }
                            }
                        }
                    }
                }

                Behavior on Layout.preferredHeight {
                    Anim {}
                }
            }

            // Battery percentage + charging indicator
            WrappedLoader {
                name: "battery"
                active: Config.bar.status.showBattery

                sourceComponent: ColumnLayout {
                    spacing: 0

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        animate: true
                        text: {
                            if (!UPower.displayDevice.isLaptopBattery) {
                                if (PowerProfiles.profile === PowerProfile.PowerSaver)
                                    return "Eco";
                                if (PowerProfiles.profile === PowerProfile.Performance)
                                    return "Perf";
                                return "Bal";
                            }
                            return Math.round(UPower.displayDevice.percentage * 100);
                        }
                        color: !UPower.onBattery || UPower.displayDevice.percentage > 0.2 ? root.colour : Colours.palette.m3error
                        font: Tokens.font.body.small
                    }

                    Item {
                        Layout.alignment: Qt.AlignHCenter
                        implicitWidth: boltIcon.implicitWidth * 0.5
                        implicitHeight: boltIcon.implicitHeight * 0.5
                        visible: UPower.displayDevice.isLaptopBattery && [UPowerDeviceState.Charging, UPowerDeviceState.FullyCharged, UPowerDeviceState.PendingCharge].includes(UPower.displayDevice.state)

                        MaterialIcon {
                            id: boltIcon
                            anchors.centerIn: parent
                            scale: 0.5
                            animate: true
                            text: "bolt"
                            color: root.colour
                            fill: 1
                        }
                    }
                }
            }
        }
    }

    component WrappedLoader: Loader {
        required property string name

        asynchronous: true
        Layout.alignment: Qt.AlignHCenter
        visible: active
    }
}
