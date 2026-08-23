import QtQuick
import Quickshell

Scope {
    id: root

    required property var commandRegistry
    readonly property bool connected: root.commandRegistry?.commandAvailable("brightness.discover") === true && root.commandRegistry?.commandAvailable("brightness.set") === true
    property bool consumerActive: false

    signal actionFinished(string taskId, bool accepted, string errorCode)
    signal connectionChanged(bool connected)
    signal stateChanged

    function errorCode(request, fallback: string): string {
        const category = String(request?.failureCategory ?? "");
        return category.length > 0 ? "BRIGHTNESS_" + category.toUpperCase() : fallback;
    }
    function parseTargets(output: string): var {
        const targets = [];
        for (const rawLine of String(output ?? "").split("\n")) {
            const line = rawLine.trim();
            if (line.length === 0)
                continue;
            const fields = line.split(",");
            if (fields.length < 5)
                continue;
            const current = Number(fields[2]);
            const maximum = Number(fields[4]);
            if (!Number.isFinite(current) || !Number.isFinite(maximum) || maximum <= 0)
                continue;
            targets.push(Object.freeze({
                "id": fields[0],
                "name": fields[0],
                "kind": fields[1],
                "minimum": 0,
                "maximum": maximum,
                "current": current
            }));
        }
        return Object.freeze(targets);
    }
    function requestRefresh() {
        if (!root.connected || state.discoveryRequestId.length > 0)
            return;
        const request = root.commandRegistry.execute("brightness.discover");
        if (["queued", "starting", "running"].indexOf(request.state) < 0) {
            state.targets = Object.freeze([]);
            state.sequence += 1;
            root.stateChanged();
            return;
        }
        state.discoveryRequestId = request.requestId;
    }
    function result(accepted: bool, taskId: string, errorCode: string): var {
        return Object.freeze({
            "accepted": accepted,
            "taskId": taskId,
            "errorCode": errorCode
        });
    }
    function setBrightness(targetId: string, rawValue: int): var {
        if (!root.connected)
            return root.result(false, "", "BRIGHTNESS_DISCONNECTED");
        const request = root.commandRegistry.executeWithArguments("brightness.set", [targetId, String(rawValue)]);
        if (["queued", "starting", "running"].indexOf(request.state) < 0)
            return root.result(false, "", root.errorCode(request, "BRIGHTNESS_WRITE_FAILED"));
        state.writeRequests = Object.assign({}, state.writeRequests, {
            [request.requestId]: true
        });
        return root.result(true, request.requestId, "");
    }
    function setConsumerActive(active: bool) {
        root.consumerActive = active;
        if (active && root.connected)
            root.requestRefresh();
    }
    function snapshot(): var {
        return Object.freeze({
            "sequence": state.sequence,
            "targets": state.targets
        });
    }

    Component.onCompleted: {
        if (root.connected)
            Qt.callLater(root.requestRefresh);
    }
    onConnectedChanged: {
        root.connectionChanged(root.connected);
        if (root.connected)
            Qt.callLater(root.requestRefresh);
    }

    QtObject {
        id: state

        property string discoveryRequestId: ""
        property int sequence: 0
        property var targets: Object.freeze([])
        property var writeRequests: ({})
    }
    Timer {
        interval: 5000
        repeat: true
        running: root.consumerActive && root.connected
        triggeredOnStart: false

        onTriggered: root.requestRefresh()
    }
    Connections {
        function onRequestFinished(request) {
            if (request.requestId === state.discoveryRequestId) {
                state.discoveryRequestId = "";
                state.targets = request.state === "completed" ? root.parseTargets(request.stdout) : Object.freeze([]);
                state.sequence += 1;
                root.stateChanged();
                return;
            }
            if (state.writeRequests[request.requestId] !== true)
                return;
            const next = Object.assign({}, state.writeRequests);
            delete next[request.requestId];
            state.writeRequests = next;
            const accepted = request.state === "completed";
            root.actionFinished(request.requestId, accepted, accepted ? "" : root.errorCode(request, "BRIGHTNESS_WRITE_FAILED"));
            if (accepted)
                root.requestRefresh();
        }

        target: root.commandRegistry
    }
}
