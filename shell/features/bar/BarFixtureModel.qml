import QtQuick

QtObject {
    id: root

    readonly property var absoluteEndItems: Object.freeze([root.item("vicinae", qsTr("V"), qsTr("Fixture Vicinae entry"), true, "accent")])
    readonly property var contextItems: Object.freeze([root.item("context", root.longText ? qsTr("REC") : qsTr("•"), qsTr("Fixture contextual status"), root.scenario !== "normal", "privacy"), root.item("tray", root.longText ? qsTr("TRAY") : qsTr("T"), qsTr("Fixture tray"), !root.missingItems, "neutral")])
    readonly property var endItems: Object.freeze([root.item("networkSpeed", root.longText ? qsTr("999M") : qsTr("3K"), qsTr("Fixture download speed"), true, "metric"), root.item("audio", qsTr("AU"), qsTr("Fixture audio"), true, "neutral"), root.item("resources", root.longText ? qsTr("100") : qsTr("55"), qsTr("Fixture memory usage"), true, "metric"), root.item("battery", root.longText ? qsTr("100") : qsTr("87"), qsTr("Fixture battery"), !root.missingItems, "metric"), root.item("dateTime", root.longText ? qsTr("23:59") : qsTr("12:34"), qsTr("Fixture date and time"), true, "metric")])
    readonly property bool longText: root.scenario === "longText"
    readonly property bool missingItems: root.scenario === "missingItems"
    property string scenario: "normal"
    readonly property var startItems: Object.freeze([root.item("workspaces", qsTr("1–5"), qsTr("Fixture workspace group"), true, "selected"), root.item("specialWorkspaces", qsTr("S"), qsTr("Fixture special workspaces"), !root.missingItems, "neutral")])

    function item(id: string, label: string, accessibleName: string, visible: bool, emphasis: string): var {
        return Object.freeze({
            "id": id,
            "label": label,
            "accessibleName": accessibleName,
            "visible": visible,
            "emphasis": emphasis
        });
    }
}
