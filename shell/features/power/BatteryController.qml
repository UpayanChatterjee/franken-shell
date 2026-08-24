import QtQuick
import Quickshell

Scope {
    id: root

    required property var adapter
    readonly property bool available: root.adapter?.available === true
    readonly property string batteryAvailability: root.adapter?.batteryAvailability ?? "unknown"
    readonly property bool charging: root.adapter?.charging === true
    readonly property string chargingState: root.adapter?.chargingState ?? "unknown"
    readonly property bool critical: root.thresholdActive && root.adapter.percentage <= root.criticalPercent
    property real criticalPercent: 5
    readonly property string label: root.adapter?.available === true ? String(Math.round(root.adapter.percentage)) + (root.showPercentSign ? "%" : "") : "–"
    readonly property real percentage: Number(root.adapter?.percentage ?? -1)
    readonly property string powerSource: root.adapter?.powerSource ?? "unknown"
    readonly property string severity: root.critical ? "critical" : root.warning ? "warning" : root.adapter?.charging === true ? "charging" : "normal"
    property bool showPercentSign: false
    readonly property string stateDescription: root.charging ? qsTr("charging") : root.chargingState === "discharging" ? qsTr("discharging") : root.chargingState === "full" ? qsTr("fully charged") : qsTr("battery")
    readonly property bool thresholdActive: root.adapter?.available === true && root.adapter.powerSource === "battery" && root.adapter.chargingState === "discharging"
    readonly property bool visible: root.adapter?.available === true || root.adapter?.stale === true && root.adapter?.batteryAvailability === "available"
    readonly property bool warning: root.thresholdActive && !root.critical && root.adapter.percentage <= root.warningPercent
    property real warningPercent: 15
}
