import QtQuick
import Quickshell
import "../../services/telemetry/ResourceMath.js" as ResourceMath

Scope {
    id: root

    required property var adapter
    property bool detailVisible: false
    readonly property string label: root.adapter?.available === true ? String(Math.round(root.adapter.memoryPercent)) : "–"
    readonly property string memoryDescription: root.adapter?.available === true && root.adapter?.memory !== null ? qsTr("Memory usage, %1 percent, %2 of %3").arg(Math.round(root.adapter.memoryPercent)).arg(ResourceMath.formatBytes(root.adapter.memory.used)).arg(ResourceMath.formatBytes(root.adapter.memory.total)) : qsTr("Memory usage unavailable")
    readonly property bool visible: true

    Component.onCompleted: root.adapter.setDetailVisible(root.detailVisible)
    onDetailVisibleChanged: root.adapter.setDetailVisible(root.detailVisible)
}
