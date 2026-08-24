import QtQuick

QtObject {
    id: root

    readonly property var absoluteEndItems: Object.freeze([root.item("vicinae", "command", "⌕", root.vicinaeAdapter?.rootInvocationAvailable === true ? qsTr("Open Vicinae") : qsTr("Vicinae unavailable; activate for details"), root.showVicinae, root.vicinaeAdapter?.rootInvocationAvailable === true ? "neutral" : "warning", "vicinae.menu", qsTr("Vicinae"))])
    property int contextCapacity: 3
    property var contextController: null
    readonly property var contextItems: Object.freeze((root.contextController?.visibleForCapacity(root.contextCapacity) ?? []).map(indicator => root.item("context." + indicator.id, "context", indicator.icon, indicator.accessibleName, true, indicator.severity, "context.summary", qsTr("Context status"), indicator)))
    property var dateTimeController: null
    readonly property var endItems: Object.freeze([root.item("tray", "tray", "", qsTr("System tray"), true, "neutral", "tray.drawer", qsTr("Tray")), root.item("networkSpeed", "metric", "", qsTr("Network throughput"), true, "metric", "", ""), root.item("audio", "audio", "", qsTr("Audio"), true, "neutral", "audio.compact", qsTr("Audio")), root.item("resources", "resource", "", qsTr("Memory usage"), true, "metric", "resources.summary", qsTr("Resources")), root.item("battery", "battery", "", qsTr("Battery"), true, "metric", "power.summary", qsTr("Power")), root.item("dateTime", "dateTime", root.dateTimeController?.timeText ?? "", root.dateTimeController?.accessibleName ?? qsTr("Date and time"), true, "metric", "calendar.local", qsTr("Calendar"))])
    property bool showVicinae: true
    property var vicinaeAdapter: null

    function item(id: string, kind: string, label: string, accessibleName: string, visible: bool, emphasis: string, popoverId: string, popoverTitle: string, payload = null): var {
        return Object.freeze({
            "id": id,
            "kind": kind,
            "label": label,
            "accessibleName": accessibleName,
            "visible": visible,
            "emphasis": emphasis,
            "popoverId": popoverId,
            "popoverTitle": popoverTitle,
            "payload": payload
        });
    }
    function popoverDatum(surfaceId: string): var {
        const items = root.contextItems.concat(root.endItems, root.absoluteEndItems);
        return items.find(item => item.popoverId === surfaceId) ?? null;
    }
}
