import QtQuick
import Quickshell

Scope {
    id: root

    required property var adapter
    readonly property bool critical: root.thresholdActive && root.adapter.percentage <= root.criticalPercent
    property real criticalPercent: 5
    readonly property string label: root.adapter?.available === true ? String(Math.round(root.adapter.percentage)) + (root.showPercentSign ? "%" : "") : "–"
    readonly property string severity: root.critical ? "critical" : root.warning ? "warning" : root.adapter?.charging === true ? "charging" : "normal"
    property bool showPercentSign: false
    readonly property bool thresholdActive: root.adapter?.available === true && root.adapter.powerSource === "battery" && root.adapter.chargingState === "discharging"
    readonly property bool visible: root.adapter?.available === true || root.adapter?.stale === true && root.adapter?.batteryAvailability === "available"
    readonly property bool warning: root.thresholdActive && !root.critical && root.adapter.percentage <= root.warningPercent
    property real warningPercent: 15
}
