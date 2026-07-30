import QtQuick

QtObject {
    id: root

    property var monitor: null
    property int revision: 1

    signal removed(string runtimeId, var lastState)

    function monitorByRuntimeId(runtimeId: string): var {
        return root.monitor?.runtimeId === runtimeId ? root.monitor : null;
    }
}
