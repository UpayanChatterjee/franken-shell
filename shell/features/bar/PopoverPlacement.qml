import QtQuick

QtObject {
    id: root

    required property string edge
    readonly property string inwardDirection: {
        switch (root.normalizedEdge) {
        case "right":
            return "left";
        case "top":
            return "down";
        case "bottom":
            return "up";
        default:
            return "right";
        }
    }
    readonly property string normalizedEdge: ["left", "right", "top", "bottom"].indexOf(root.edge) >= 0 ? root.edge : "left"
    readonly property string popupEdge: {
        switch (root.normalizedEdge) {
        case "right":
            return "left";
        case "top":
            return "bottom";
        case "bottom":
            return "top";
        default:
            return "right";
        }
    }
}
