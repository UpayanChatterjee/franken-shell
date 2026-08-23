import QtQuick
import Quickshell
import "../../services/telemetry/ThroughputMath.js" as ThroughputMath

Scope {
    id: root

    required property var adapter
    property int base: 1000
    readonly property string formattedDownload: root.adapter?.available === true ? ThroughputMath.compactRate(root.adapter.smoothedDownloadRate, root.unit, root.base, root.zeroFormat) : "–"
    readonly property string formattedTooltip: root.adapter?.available === true ? ThroughputMath.tooltip(root.adapter.smoothedDownloadRate, root.adapter.smoothedUploadRate, root.unit, root.base) : qsTr("Network throughput unavailable")
    readonly property bool samplingHealthy: root.adapter?.available === true && root.adapter?.stale !== true
    property string unit: "bytes"
    property string zeroFormat: "0K"
}
