import QtQuick

QtObject {
    id: root

    property var connectedIds: ["monitor-1", "monitor-2"]
    property int revision: 1

    signal removed(string runtimeId, var lastState)

    function monitorByRuntimeId(runtimeId: string): var {
        if (root.connectedIds.indexOf(runtimeId) < 0)
            return null;
        return {
            "runtimeId": runtimeId,
            "connected": true
        };
    }
    function remove(runtimeId: string) {
        const index = root.connectedIds.indexOf(runtimeId);
        if (index < 0)
            return;
        const next = root.connectedIds.slice();
        next.splice(index, 1);
        root.connectedIds = next;
        root.revision += 1;
        root.removed(runtimeId, {
            "runtimeId": runtimeId,
            "connected": false
        });
    }
}
