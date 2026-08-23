import QtQuick
import Quickshell

Scope {
    id: root

    property bool connected: false
    property bool consumerActive: false
    readonly property int lastRawValue: state.lastRawValue
    readonly property string lastTargetId: state.lastTargetId
    property int refreshCount: 0
    property int sequence: 1
    property var targetRecords: []
    readonly property int writeCount: state.writeCount

    signal actionFinished(string taskId, bool accepted, string errorCode)
    signal connectionChanged(bool connected)
    signal stateChanged

    function completeAction(accepted: bool, errorCode: string) {
        if (state.pendingTaskId.length === 0)
            return;
        const taskId = state.pendingTaskId;
        state.pendingTaskId = "";
        root.actionFinished(taskId, accepted, errorCode);
    }
    function requestRefresh() {
        root.refreshCount += 1;
        root.stateChanged();
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
        state.writeCount += 1;
        state.lastTargetId = targetId;
        state.lastRawValue = rawValue;
        state.nextTask += 1;
        state.pendingTaskId = "brightness-fixture-" + state.nextTask;
        return root.result(true, state.pendingTaskId, "");
    }
    function setConnected(value: bool) {
        if (root.connected === value)
            return;
        root.connected = value;
        root.connectionChanged(value);
    }
    function setConsumerActive(value: bool) {
        root.consumerActive = value;
    }
    function snapshot(): var {
        return Object.freeze({
            "sequence": root.sequence,
            "targets": Object.freeze(Array.from(root.targetRecords))
        });
    }

    QtObject {
        id: state

        property int lastRawValue: -1
        property string lastTargetId: ""
        property int nextTask: 0
        property string pendingTaskId: ""
        property int writeCount: 0
    }
}
