import QtQuick
import Quickshell
import "../../services/telemetry/ResourceMath.js" as ResourceMath

Scope {
    id: root

    required property var adapter
    readonly property bool available: root.adapter?.available === true
    property var commandRegistry: null
    readonly property real cpuPercent: Number(root.adapter?.cpuPercent ?? -1)
    property bool detailVisible: false
    readonly property bool externalMonitorAvailable: root.commandRegistry?.commandAvailable("systemMonitor.open") === true
    property var feedbackController: null
    readonly property string label: root.adapter?.available === true ? String(Math.round(root.adapter.memoryPercent)) : "–"
    readonly property string memoryDescription: root.adapter?.available === true && root.adapter?.memory !== null ? qsTr("Memory usage, %1 percent, %2 of %3").arg(Math.round(root.adapter.memoryPercent)).arg(ResourceMath.formatBytes(root.adapter.memory.used)).arg(ResourceMath.formatBytes(root.adapter.memory.total)) : qsTr("Memory usage unavailable")
    readonly property real memoryPercent: Number(root.adapter?.memoryPercent ?? -1)
    readonly property bool stale: root.adapter?.stale === true
    readonly property string storageDescription: root.adapter?.storage !== null ? qsTr("Storage  %1 used of %2").arg(ResourceMath.formatBytes(root.adapter.storage.used)).arg(ResourceMath.formatBytes(root.adapter.storage.total)) : ""
    readonly property bool visible: true

    function openExternalMonitor(context = ({})): var {
        if (!root.externalMonitorAvailable) {
            if (root.feedbackController !== null) {
                root.feedbackController.showToast({
                    "key": "generic",
                    "severity": "failure",
                    "summary": qsTr("System monitor unavailable"),
                    "detail": qsTr("Configure a verified systemMonitor.open command."),
                    "userTriggered": true
                }, context);
            }
            return Object.freeze({
                "accepted": false,
                "errorCode": "SYSTEM_MONITOR_UNAVAILABLE"
            });
        }
        const request = root.commandRegistry.execute("systemMonitor.open");
        const accepted = ["queued", "starting", "running"].indexOf(request?.state ?? "") >= 0;
        return Object.freeze({
            "accepted": accepted,
            "errorCode": accepted ? "" : String(request?.failureCategory ?? "SYSTEM_MONITOR_INVOCATION_FAILED")
        });
    }

    Component.onCompleted: root.adapter.setDetailVisible(root.detailVisible)
    onDetailVisibleChanged: root.adapter.setDetailVisible(root.detailVisible)
}
