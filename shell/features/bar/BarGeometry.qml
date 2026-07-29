import QtQuick

QtObject {
    id: root

    required property string configuredEdge
    required property var configuredThickness
    readonly property string edge: root.validEdge(root.configuredEdge) ? root.configuredEdge : "left"
    readonly property int exclusiveZone: root.persistentVisible ? Math.ceil(root.thickness) : 0
    readonly property string inwardDirection: root.edge === "left" ? "right" : root.edge === "right" ? "left" : root.edge === "top" ? "down" : "up"
    readonly property real mainAxisEndInset: 0
    readonly property real mainAxisStartInset: 0
    readonly property string orientation: root.vertical ? "vertical" : "horizontal"
    readonly property real outwardInset: 0
    required property bool persistentVisible
    required property var theme
    readonly property real thickness: typeof root.configuredThickness === "number" && root.configuredThickness > 0 ? root.configuredThickness : root.theme.metrics.barThickness
    readonly property bool vertical: root.edge === "left" || root.edge === "right"

    function validEdge(candidate: string): bool {
        return candidate === "left" || candidate === "right" || candidate === "top" || candidate === "bottom";
    }
}
