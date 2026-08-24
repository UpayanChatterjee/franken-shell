import QtQuick
import Quickshell

Scope {
    id: root

    readonly property string activeCaptureState: root.adapter?.activeCaptureState ?? "inactive"
    required property var adapter
    readonly property bool available: root.adapter?.available === true
    readonly property var captureStreams: root.adapter?.captureStreams ?? Object.freeze([])
    readonly property var defaultInput: root.adapter?.defaultInput ?? null
    readonly property var defaultOutput: root.adapter?.defaultOutput ?? null
    property var feedbackController: null
    readonly property var inputDevices: root.adapter?.inputDevices ?? Object.freeze([])
    readonly property bool masterMuted: root.adapter?.masterMuted ?? false
    readonly property real masterVolume: root.adapter?.masterVolume ?? 0
    property real maximumVolume: 1
    readonly property var operationTasks: root.adapter?.operationTasks ?? Object.freeze([])
    readonly property string outputCategory: root.adapter?.outputCategory ?? "unknown"
    readonly property var outputDevices: root.adapter?.outputDevices ?? Object.freeze([])
    readonly property var playbackStreams: root.adapter?.playbackStreams ?? Object.freeze([])
    readonly property bool stale: root.adapter?.stale ?? false
    property real volumeStep: 0.02

    function adjustMasterVolume(delta: real): var {
        return root.setMasterVolume(root.masterVolume + delta);
    }
    function clampVolume(volume: real): real {
        const bounded = Math.max(0, Math.min(root.maximumVolume, Number(volume)));
        return Math.round(bounded * 100000) / 100000;
    }
    function flushPendingVolume(): var {
        scrollCoalescer.stop();
        const steps = state.pendingVolumeSteps;
        state.pendingVolumeSteps = 0;
        if (steps === 0)
            return root.result(false, "AUDIO_NO_CHANGE");
        return root.adjustMasterVolume(steps * root.volumeStep);
    }
    function moveStream(streamId: string, outputId: string): var {
        return root.adapter.moveStream(streamId, outputId);
    }
    function queueVolumeSteps(steps: int) {
        if (!root.available || steps === 0)
            return;
        state.pendingVolumeSteps += steps;
        scrollCoalescer.restart();
    }
    function result(accepted: bool, errorCode: string): var {
        return Object.freeze({
            "accepted": accepted,
            "errorCode": errorCode
        });
    }
    function selectDefaultInput(nodeId: string): var {
        return root.adapter.selectDefaultInput(nodeId);
    }
    function selectDefaultOutput(nodeId: string, context = ({})): var {
        const response = root.adapter.selectDefaultOutput(nodeId);
        if (response.accepted && root.feedbackController !== null) {
            const output = root.outputDevices.find(candidate => candidate.id === nodeId);
            root.feedbackController.showToast({
                "key": "audioOutput",
                "severity": "success",
                "summary": qsTr("Audio output changed"),
                "detail": String(output?.description || output?.name || ""),
                "userTriggered": true
            }, context);
        }
        return response;
    }
    function setMasterVolume(volume: real, context = ({})): var {
        const bounded = root.clampVolume(volume);
        const response = root.adapter.setMasterVolume(bounded);
        if (response.accepted && root.feedbackController !== null)
            root.feedbackController.showVolume(bounded, root.masterMuted, context);
        return response;
    }
    function setMicrophoneMuted(muted: bool): var {
        return root.adapter.setMicrophoneMuted(muted);
    }
    function setStreamMuted(streamId: string, muted: bool): var {
        return root.adapter.setStreamMuted(streamId, muted);
    }
    function setStreamVolume(streamId: string, volume: real): var {
        return root.adapter.setStreamVolume(streamId, root.clampVolume(volume));
    }
    function toggleMasterMute(context = ({})): var {
        const muted = !root.masterMuted;
        const response = root.adapter.setMasterMuted(muted);
        if (response.accepted && root.feedbackController !== null)
            root.feedbackController.showVolume(root.masterVolume, muted, context);
        return response;
    }

    QtObject {
        id: state

        property int pendingVolumeSteps: 0
    }
    Timer {
        id: scrollCoalescer

        interval: 45

        onTriggered: root.flushPendingVolume()
    }
}
