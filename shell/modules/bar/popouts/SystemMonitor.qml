pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.Services
import qs.components
import qs.components.misc
import qs.services

ColumnLayout {
    id: root

    spacing: Tokens.spacing.small

    Ref { service: FanSpeeds }

    // CPU row
    RowLayout {
        spacing: Tokens.spacing.small

        MaterialIcon {
            text: "memory"
            color: Colours.palette.m3primary
        }

        StyledText {
            text: qsTr("CPU")
        }

        Item { Layout.fillWidth: true }

        StyledText {
            text: `${Math.ceil(GlobalConfig.services.useFahrenheitPerformance ? Cpu.temperature * 1.8 + 32 : Cpu.temperature)}°${GlobalConfig.services.useFahrenheitPerformance ? "F" : "C"}`
        }

        MaterialIcon {
            visible: FanSpeeds.cpuFanRpm >= 0
            text: "mode_fan"
            color: Colours.palette.m3onSurfaceVariant
        }

        StyledText {
            visible: FanSpeeds.cpuFanRpm >= 0
            text: `${FanSpeeds.cpuFanRpm} RPM`
        }
    }

    // GPU row
    RowLayout {
        visible: Gpu.type !== Gpu.None
        spacing: Tokens.spacing.small

        MaterialIcon {
            text: "desktop_windows"
            color: Colours.palette.m3secondary
        }

        StyledText {
            text: qsTr("GPU")
        }

        Item { Layout.fillWidth: true }

        StyledText {
            text: `${Math.ceil(GlobalConfig.services.useFahrenheitPerformance ? Gpu.temperature * 1.8 + 32 : Gpu.temperature)}°${GlobalConfig.services.useFahrenheitPerformance ? "F" : "C"}`
        }

        MaterialIcon {
            visible: FanSpeeds.gpuFanRpm >= 0
            text: "mode_fan"
            color: Colours.palette.m3onSurfaceVariant
        }

        StyledText {
            visible: FanSpeeds.gpuFanRpm >= 0
            text: `${FanSpeeds.gpuFanRpm} RPM`
        }
    }
}
