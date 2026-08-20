import "AudioOutputClassifier.js" as OutputClassifier
import QtQuick
import Quickshell

Scope {
    id: root

    readonly property string activeCaptureState: root.captureStreams.length === 0 ? "inactive" : "unknown"
    readonly property bool available: state.connectionState === "ready"
    readonly property var captureStreams: state.captureStreams
    readonly property string connectionState: state.connectionState
    readonly property var defaultInput: state.defaultInput
    readonly property var defaultOutput: state.defaultOutput
    readonly property var inputDevices: state.inputDevices
    readonly property string lastError: state.lastError
    readonly property bool masterMuted: root.defaultOutput?.muted ?? false
    readonly property real masterVolume: root.defaultOutput?.volume ?? 0
    readonly property bool microphoneMuted: root.defaultInput?.muted ?? false
    readonly property var operationTasks: Object.freeze([])
    readonly property string outputCategory: root.defaultOutput?.muted === true ? "muted" : OutputClassifier.classify(root.defaultOutput)
    readonly property var outputDevices: state.outputDevices
    readonly property var playbackStreams: state.playbackStreams
    required property var runtime
    readonly property bool stale: state.stale
    readonly property int staleSnapshotCount: state.staleSnapshotCount

    signal stateChanged

    function action(method: string, nodeId: string, value): var {
        if (!root.available) {
            state.lastError = "AUDIO_DISCONNECTED";
            return root.result(false, state.lastError);
        }
        let response;
        try {
            response = root.runtime[method](nodeId, value);
        } catch (error) {
            state.lastError = "AUDIO_ACTION_FAILED";
            return root.result(false, state.lastError);
        }
        const accepted = response?.accepted === true;
        state.lastError = accepted ? "" : String(response?.errorCode ?? "AUDIO_ACTION_FAILED");
        return root.result(accepted, state.lastError);
    }
    function asArray(value): var {
        if (Array.isArray(value))
            return value;
        if (typeof value?.toArray === "function")
            return value.toArray();
        return [];
    }
    function diagnosticsSummary(): var {
        return Object.freeze({
            "available": root.available,
            "connectionState": root.connectionState,
            "stale": root.stale,
            "outputDeviceCount": root.outputDevices.length,
            "inputDeviceCount": root.inputDevices.length,
            "playbackStreamCount": root.playbackStreams.length,
            "captureStreamCount": root.captureStreams.length,
            "activeCaptureState": root.activeCaptureState,
            "defaultOutputPresent": root.defaultOutput !== null,
            "defaultInputPresent": root.defaultInput !== null,
            "outputCategory": root.outputCategory,
            "masterMuted": root.masterMuted,
            "microphoneMuted": root.microphoneMuted,
            "staleSnapshotCount": root.staleSnapshotCount,
            "lastError": root.lastError
        });
    }
    function findRecord(records, id: string): var {
        for (const record of records) {
            if (record.id === id)
                return record;
        }
        return null;
    }
    function handleConnectionChanged(connected: bool) {
        if (!connected) {
            state.connectionState = state.hasReadySnapshot ? "reconnecting" : "unavailable";
            state.stale = state.hasReadySnapshot;
            root.stateChanged();
            return;
        }
        state.connectionState = "starting";
        state.stale = state.hasReadySnapshot;
        root.runtime.requestRefresh();
    }
    function moveStream(streamId: string, outputId: string): var {
        if (root.findRecord(root.playbackStreams.concat(root.captureStreams), streamId) === null)
            return root.result(false, "AUDIO_STREAM_UNAVAILABLE");
        if (root.findRecord(root.outputDevices, outputId) === null)
            return root.result(false, "AUDIO_OUTPUT_UNAVAILABLE");
        return root.action("moveStream", streamId, outputId);
    }
    function normalize(candidate): var {
        return Object.freeze({
            "id": String(candidate?.id ?? ""),
            "name": String(candidate?.name ?? ""),
            "description": String(candidate?.description ?? ""),
            "nickname": String(candidate?.nickname ?? ""),
            "properties": Object.freeze(Object.assign({}, candidate?.properties ?? {})),
            "volume": Math.max(0, Number(candidate?.volume ?? 0)),
            "muted": candidate?.muted === true
        });
    }
    function normalizeList(candidates): var {
        const records = [];
        for (const candidate of root.asArray(candidates)) {
            const record = root.normalize(candidate);
            if (record.id.length > 0)
                records.push(record);
        }
        return Object.freeze(records);
    }
    function reconcile() {
        if (!root.runtime?.connected)
            return;
        let snapshot;
        try {
            snapshot = root.runtime.snapshot();
        } catch (error) {
            state.connectionState = "degraded";
            state.lastError = "AUDIO_SNAPSHOT_FAILED";
            state.stale = state.hasReadySnapshot;
            root.stateChanged();
            return;
        }
        const sequence = Number(snapshot?.sequence ?? 0);
        if (sequence < state.lastSequence) {
            state.staleSnapshotCount += 1;
            root.stateChanged();
            return;
        }

        const outputs = root.normalizeList(snapshot?.outputDevices);
        const inputs = root.normalizeList(snapshot?.inputDevices);
        state.outputDevices = outputs;
        state.inputDevices = inputs;
        state.playbackStreams = root.normalizeList(snapshot?.playbackStreams);
        state.captureStreams = root.normalizeList(snapshot?.captureStreams);
        state.defaultOutput = root.findRecord(outputs, String(snapshot?.defaultOutputId ?? ""));
        state.defaultInput = root.findRecord(inputs, String(snapshot?.defaultInputId ?? ""));
        state.lastSequence = sequence;
        state.lastError = "";
        state.hasReadySnapshot = true;
        state.stale = false;
        state.connectionState = "ready";
        root.stateChanged();
    }
    function result(accepted: bool, errorCode: string): var {
        return Object.freeze({
            "accepted": accepted,
            "errorCode": errorCode
        });
    }
    function selectDefaultInput(nodeId: string): var {
        if (root.findRecord(root.inputDevices, nodeId) === null)
            return root.result(false, "AUDIO_INPUT_UNAVAILABLE");
        return root.action("selectDefaultInput", nodeId, true);
    }
    function selectDefaultOutput(nodeId: string): var {
        if (root.findRecord(root.outputDevices, nodeId) === null)
            return root.result(false, "AUDIO_OUTPUT_UNAVAILABLE");
        return root.action("selectDefaultOutput", nodeId, true);
    }
    function setMasterMuted(muted: bool): var {
        if (root.defaultOutput === null)
            return root.result(false, "AUDIO_OUTPUT_UNAVAILABLE");
        return root.action("setMuted", root.defaultOutput.id, muted);
    }
    function setMasterVolume(volume: real): var {
        if (root.defaultOutput === null)
            return root.result(false, "AUDIO_OUTPUT_UNAVAILABLE");
        return root.action("setVolume", root.defaultOutput.id, volume);
    }
    function setMicrophoneMuted(muted: bool): var {
        if (root.defaultInput === null)
            return root.result(false, "AUDIO_INPUT_UNAVAILABLE");
        return root.action("setMuted", root.defaultInput.id, muted);
    }
    function setStreamMuted(streamId: string, muted: bool): var {
        if (root.findRecord(root.playbackStreams.concat(root.captureStreams), streamId) === null)
            return root.result(false, "AUDIO_STREAM_UNAVAILABLE");
        return root.action("setMuted", streamId, muted);
    }
    function setStreamVolume(streamId: string, volume: real): var {
        if (root.findRecord(root.playbackStreams.concat(root.captureStreams), streamId) === null)
            return root.result(false, "AUDIO_STREAM_UNAVAILABLE");
        return root.action("setVolume", streamId, volume);
    }

    Component.onCompleted: {
        if (root.runtime?.connected)
            root.handleConnectionChanged(true);
    }
    onRuntimeChanged: root.handleConnectionChanged(root.runtime?.connected === true)

    QtObject {
        id: state

        property var captureStreams: Object.freeze([])
        property string connectionState: "unavailable"
        property var defaultInput: null
        property var defaultOutput: null
        property bool hasReadySnapshot: false
        property var inputDevices: Object.freeze([])
        property string lastError: ""
        property int lastSequence: -1
        property var outputDevices: Object.freeze([])
        property var playbackStreams: Object.freeze([])
        property bool stale: false
        property int staleSnapshotCount: 0
    }
    Connections {
        function onConnectionChanged(connected) {
            root.handleConnectionChanged(connected);
        }
        function onStateChanged() {
            root.reconcile();
        }

        ignoreUnknownSignals: true
        target: root.runtime
    }
}
