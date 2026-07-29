import QtQuick

QtObject {
    id: root

    readonly property var absoluteEndItems: Object.freeze([root.item("vicinae", qsTr("V"), qsTr("Fixture Vicinae entry"), true, "accent", "", "")])
    readonly property var contextItems: Object.freeze([root.item("context", root.localizedValues ? qsTr("AUFN") : root.longText ? qsTr("REC") : qsTr("•"), qsTr("Fixture contextual status"), root.scenario !== "normal", "privacy", "fixture.context", qsTr("Context status")), root.item("tray", root.localizedValues ? qsTr("ABL") : root.longText ? qsTr("TRAY") : qsTr("T"), qsTr("Fixture tray"), !root.missingItems, "neutral", "fixture.tray", qsTr("Tray"))])
    readonly property var endItems: Object.freeze([root.item("networkSpeed", root.localizedValues ? qsTr("999 M") : root.longText ? qsTr("999M") : qsTr("3K"), qsTr("Fixture download speed"), true, "metric", "", ""), root.item("audio", qsTr("AU"), qsTr("Fixture audio"), true, "neutral", "fixture.audio", qsTr("Audio")), root.item("resources", root.localizedValues ? qsTr("100 %") : root.longText ? qsTr("100") : qsTr("55"), qsTr("Fixture memory usage"), true, "metric", "fixture.resources", qsTr("Resources")), root.item("battery", root.localizedValues ? qsTr("100 %") : root.longText ? qsTr("100") : qsTr("87"), qsTr("Fixture battery"), !root.missingItems, "metric", "fixture.battery", qsTr("Battery")), root.item("dateTime", root.localizedValues ? qsTr("23.59") : root.longText ? qsTr("23:59") : qsTr("12:34"), qsTr("Fixture date and time"), true, "metric", "fixture.date-time", qsTr("Date and time"))])
    readonly property bool localizedValues: root.scenario === "localized"
    readonly property bool longText: root.scenario === "longText"
    readonly property bool missingItems: root.scenario === "missingItems"
    property string scenario: "normal"

    function item(id: string, label: string, accessibleName: string, visible: bool, emphasis: string, popoverId: string, popoverTitle: string): var {
        return Object.freeze({
            "id": id,
            "label": label,
            "accessibleName": accessibleName,
            "visible": visible,
            "emphasis": emphasis,
            "popoverId": popoverId,
            "popoverTitle": popoverTitle
        });
    }
    function popoverDatum(surfaceId: string): var {
        const items = root.contextItems.concat(root.endItems, root.absoluteEndItems);
        return items.find(item => item.popoverId === surfaceId) ?? null;
    }
}
