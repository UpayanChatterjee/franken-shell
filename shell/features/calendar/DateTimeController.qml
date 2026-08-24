import QtQuick
import Quickshell

Scope {
    id: root

    readonly property string accessibleName: Qt.formatDateTime(root.clockService.now, "dddd, d MMMM yyyy, HH:mm")
    required property var clockService
    readonly property string dateText: root.showDate ? Qt.formatDate(root.clockService.now, root.monthFormat === "numeric" ? "dd/MM" : "d MMM") : ""
    property string monthFormat: "shortText"
    property bool showDate: true
    property string timeFormat: "24h"
    readonly property string timeText: Qt.formatTime(root.clockService.now, root.timeFormat === "12h" ? "h:mm AP" : "HH:mm")
}
