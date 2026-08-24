import QtQuick
import Quickshell

Scope {
    id: root

    property var fixtureIndicators: Object.freeze([])
    readonly property var indicators: controller.indicators()
    property var networkController: null

    function visibleForCapacity(capacity: int): var {
        const bounded = Math.max(0, capacity);
        if (root.indicators.length <= bounded)
            return root.indicators;
        if (bounded === 0)
            return Object.freeze([]);
        const visible = root.indicators.slice(0, Math.max(0, bounded - 1));
        visible.push(Object.freeze({
            "id": "overflow",
            "category": "overflow",
            "severity": root.indicators[0]?.severity ?? "info",
            "icon": "+",
            "accessibleName": qsTr("More contextual system states"),
            "tooltip": qsTr("%1 additional system states").arg(root.indicators.length - visible.length),
            "priority": -1,
            "destination": "contextSummary"
        }));
        return Object.freeze(visible);
    }

    QtObject {
        id: controller

        function indicators(): var {
            const records = [];
            const network = controller.networkIndicator();
            if (network !== null)
                records.push(network);
            for (const candidate of root.fixtureIndicators) {
                if (candidate !== null && typeof candidate === "object")
                    records.push(candidate);
            }
            records.sort((left, right) => Number(right.priority ?? 0) - Number(left.priority ?? 0) || String(left.id ?? "").localeCompare(String(right.id ?? "")));
            return Object.freeze(records);
        }
        function networkIndicator(): var {
            if (root.networkController === null || root.networkController === undefined)
                return null;
            if (root.networkController.available !== true) {
                if (String(root.networkController.lastError ?? "").length === 0)
                    return null;
                return Object.freeze({
                    "id": "network",
                    "category": "connectivity",
                    "severity": "warning",
                    "icon": "?",
                    "accessibleName": qsTr("Network status unavailable"),
                    "tooltip": qsTr("Network status could not be read"),
                    "priority": 70,
                    "destination": "network"
                });
            }
            const connectivity = String(root.networkController.connectivity ?? "unknown");
            const status = String(root.networkController.status ?? "unknown");
            if (connectivity === "internet" && ["limited", "captive"].indexOf(status) < 0)
                return null;
            if (connectivity === "unknown" && ["limited", "captive"].indexOf(status) < 0)
                return null;
            const captive = connectivity === "captive" || status === "captive";
            const limited = connectivity === "limited" || connectivity === "local" || status === "limited";
            return Object.freeze({
                "id": "network",
                "category": "connectivity",
                "severity": captive ? "critical" : "warning",
                "icon": captive ? "!" : "×",
                "accessibleName": captive ? qsTr("Network login required") : limited ? qsTr("Limited network connectivity") : qsTr("Network offline"),
                "tooltip": captive ? qsTr("Network login is required") : limited ? qsTr("Network connectivity is limited") : qsTr("No internet connection"),
                "priority": captive ? 100 : 80,
                "destination": "network"
            });
        }
    }
}
