pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

Scope {
    id: root

    readonly property bool connected: Pipewire.ready

    signal connectionChanged(bool connected)
    signal stateChanged

    function asArray(value): var {
        if (Array.isArray(value))
            return value;
        if (typeof value?.toArray === "function")
            return value.toArray();
        return [];
    }
    function moveStream(streamId: string, outputId: string): var {
        void streamId;
        void outputId;
        return root.result(false, "AUDIO_ROUTING_UNSUPPORTED");
    }
    function nodeForId(nodeId: string): var {
        for (const node of Pipewire.nodes.values) {
            if (String(node.id) === nodeId)
                return node;
        }
        return null;
    }
    function nodeRecord(node: PwNode): var {
        return Object.freeze({
            "id": String(node.id),
            "name": String(node.name ?? ""),
            "description": String(node.description ?? ""),
            "nickname": String(node.nickname ?? ""),
            "properties": Object.freeze(Object.assign({}, node.properties ?? {})),
            "volume": Math.max(0, Number(node.audio?.volume ?? 0)),
            "muted": node.audio?.muted === true
        });
    }
    function requestRefresh() {
        if (!root.connected)
            return;
        state.sequence += 1;
        root.stateChanged();
    }
    function result(accepted: bool, errorCode: string): var {
        return Object.freeze({
            "accepted": accepted,
            "errorCode": errorCode
        });
    }
    function scheduleChanged() {
        modelChanged.restart();
    }
    function selectDefaultInput(nodeId: string): var {
        if (!root.connected)
            return root.result(false, "AUDIO_DISCONNECTED");
        const node = root.nodeForId(nodeId);
        if (node === null || node.isStream || node.audio === null || node.isSink)
            return root.result(false, "AUDIO_INPUT_UNAVAILABLE");
        try {
            Pipewire.preferredDefaultAudioSource = node;
            return root.result(true, "");
        } catch (error) {
            return root.result(false, "AUDIO_DEFAULT_INPUT_FAILED");
        }
    }
    function selectDefaultOutput(nodeId: string): var {
        if (!root.connected)
            return root.result(false, "AUDIO_DISCONNECTED");
        const node = root.nodeForId(nodeId);
        if (node === null || node.isStream || node.audio === null || !node.isSink)
            return root.result(false, "AUDIO_OUTPUT_UNAVAILABLE");
        try {
            Pipewire.preferredDefaultAudioSink = node;
            return root.result(true, "");
        } catch (error) {
            return root.result(false, "AUDIO_DEFAULT_OUTPUT_FAILED");
        }
    }
    function setMuted(nodeId: string, muted: bool): var {
        if (!root.connected)
            return root.result(false, "AUDIO_DISCONNECTED");
        const node = root.nodeForId(nodeId);
        if (node?.audio === null || node?.audio === undefined)
            return root.result(false, "AUDIO_NODE_UNAVAILABLE");
        try {
            node.audio.muted = muted;
            return root.result(true, "");
        } catch (error) {
            return root.result(false, "AUDIO_MUTE_FAILED");
        }
    }
    function setVolume(nodeId: string, volume: real): var {
        if (!root.connected)
            return root.result(false, "AUDIO_DISCONNECTED");
        const node = root.nodeForId(nodeId);
        if (node?.audio === null || node?.audio === undefined)
            return root.result(false, "AUDIO_NODE_UNAVAILABLE");
        try {
            node.audio.volume = volume;
            return root.result(true, "");
        } catch (error) {
            return root.result(false, "AUDIO_VOLUME_FAILED");
        }
    }
    function snapshot(): var {
        const outputDevices = [];
        const inputDevices = [];
        const playbackStreams = [];
        const captureStreams = [];
        for (const node of Pipewire.nodes.values) {
            if (!node.ready || node.audio === null)
                continue;
            if (!node.isStream) {
                if (node.isSink)
                    outputDevices.push(root.nodeRecord(node));
                else
                    inputDevices.push(root.nodeRecord(node));
            } else if (String(node.properties?.["media.class"] ?? "").toLowerCase().includes("stream/input/audio")) {
                captureStreams.push(root.nodeRecord(node));
            } else {
                playbackStreams.push(root.nodeRecord(node));
            }
        }
        return Object.freeze({
            "sequence": state.sequence,
            "defaultOutputId": Pipewire.defaultAudioSink === null ? "" : String(Pipewire.defaultAudioSink.id),
            "defaultInputId": Pipewire.defaultAudioSource === null ? "" : String(Pipewire.defaultAudioSource.id),
            "outputDevices": Object.freeze(outputDevices),
            "inputDevices": Object.freeze(inputDevices),
            "playbackStreams": Object.freeze(playbackStreams),
            "captureStreams": Object.freeze(captureStreams)
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

        property int sequence: 0
    }
    Timer {
        id: modelChanged

        interval: 0

        onTriggered: root.requestRefresh()
    }
    Connections {
        function onDefaultAudioSinkChanged() {
            root.scheduleChanged();
        }
        function onDefaultAudioSourceChanged() {
            root.scheduleChanged();
        }

        target: Pipewire
    }
    Connections {
        function onValuesChanged() {
            root.scheduleChanged();
        }

        target: Pipewire.nodes
    }
    PwObjectTracker {
        objects: Pipewire.nodes.values

        onObjectsChanged: root.scheduleChanged()
    }
    Instantiator {
        model: Pipewire.nodes

        delegate: Scope {
            id: nodeObserver

            required property PwNode modelData

            Connections {
                function onPropertiesChanged() {
                    root.scheduleChanged();
                }
                function onReadyChanged() {
                    root.scheduleChanged();
                }

                target: nodeObserver.modelData
            }
            Connections {
                function onMutedChanged() {
                    root.scheduleChanged();
                }
                function onVolumesChanged() {
                    root.scheduleChanged();
                }

                target: nodeObserver.modelData.audio
            }
        }
    }
}
