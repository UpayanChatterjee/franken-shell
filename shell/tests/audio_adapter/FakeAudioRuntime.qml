import QtQuick
import Quickshell

Scope {
    id: root

    readonly property int actionCount: state.actionCount
    property var captureStreams: []
    property bool connected: false
    property string defaultInputId: ""
    property string defaultOutputId: ""
    property string failNextError: ""
    property var inputDevices: []
    readonly property string lastAction: state.lastAction
    property var outputDevices: []
    property var playbackStreams: []
    property int sequence: 1

    signal connectionChanged(bool connected)
    signal stateChanged

    function action(name: string, nodeId: string, value): var {
        state.actionCount += 1;
        state.lastAction = name + ":" + nodeId + ":" + String(value);
        if (!root.connected)
            return root.result(false, "AUDIO_DISCONNECTED");
        if (root.failNextError.length > 0) {
            const errorCode = root.failNextError;
            root.failNextError = "";
            return root.result(false, errorCode);
        }
        return root.result(true, "");
    }
    function moveStream(streamId: string, outputId: string): var {
        return root.action("moveStream", streamId, outputId);
    }
    function requestRefresh() {
        root.stateChanged();
    }
    function result(accepted: bool, errorCode: string): var {
        return Object.freeze({
            "accepted": accepted,
            "errorCode": errorCode
        });
    }
    function selectDefaultInput(nodeId: string): var {
        return root.action("selectDefaultInput", nodeId, true);
    }
    function selectDefaultOutput(nodeId: string): var {
        return root.action("selectDefaultOutput", nodeId, true);
    }
    function setConnected(value: bool) {
        if (root.connected === value)
            return;
        root.connected = value;
        root.connectionChanged(value);
    }
    function setMuted(nodeId: string, muted: bool): var {
        return root.action("setMuted", nodeId, muted);
    }
    function setVolume(nodeId: string, volume: real): var {
        return root.action("setVolume", nodeId, volume);
    }
    function snapshot(): var {
        return Object.freeze({
            "sequence": root.sequence,
            "defaultOutputId": root.defaultOutputId,
            "defaultInputId": root.defaultInputId,
            "outputDevices": Object.freeze(Array.from(root.outputDevices)),
            "inputDevices": Object.freeze(Array.from(root.inputDevices)),
            "playbackStreams": Object.freeze(Array.from(root.playbackStreams)),
            "captureStreams": Object.freeze(Array.from(root.captureStreams))
        });
    }

    QtObject {
        id: state

        property int actionCount: 0
        property string lastAction: ""
    }
}
