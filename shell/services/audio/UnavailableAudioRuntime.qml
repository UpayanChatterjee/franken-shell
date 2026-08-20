import QtQuick
import Quickshell

Scope {
    readonly property bool connected: false

    signal connectionChanged(bool connected)
    signal stateChanged

    function moveStream(streamId: string, outputId: string): var {
        void streamId;
        void outputId;
        return result();
    }
    function requestRefresh() {
    }
    function result(): var {
        return Object.freeze({
            "accepted": false,
            "errorCode": "AUDIO_DISCONNECTED"
        });
    }
    function selectDefaultInput(nodeId: string): var {
        void nodeId;
        return result();
    }
    function selectDefaultOutput(nodeId: string): var {
        void nodeId;
        return result();
    }
    function setMuted(nodeId: string, muted: bool): var {
        void nodeId;
        void muted;
        return result();
    }
    function setVolume(nodeId: string, volume: real): var {
        void nodeId;
        void volume;
        return result();
    }
    function snapshot(): var {
        return Object.freeze({
            "sequence": 0,
            "defaultOutputId": "",
            "defaultInputId": "",
            "outputDevices": Object.freeze([]),
            "inputDevices": Object.freeze([]),
            "playbackStreams": Object.freeze([]),
            "captureStreams": Object.freeze([])
        });
    }
}
