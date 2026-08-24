import "../../features/audio" as AudioFeatures
import "../../services/audio" as AudioServices
import QtQuick
import Quickshell

ShellRoot {
    id: root

    function check(condition: bool, message: string) {
        if (!condition)
            root.fail(message);
    }
    function device(id: string, description: string, properties, volume: real, muted: bool): var {
        return Object.freeze({
            "id": id,
            "name": id,
            "description": description,
            "nickname": "",
            "properties": Object.freeze(properties ?? {}),
            "volume": volume,
            "muted": muted
        });
    }
    function fail(message: string) {
        console.error("FAIL audio-adapter:", message);
        Qt.exit(1);
        throw new Error(message);
    }
    function run() {
        root.check(!adapter.available && adapter.connectionState === "unavailable" && adapter.outputDevices.length === 0, "missing backend starts unavailable without fabricated devices");

        const speakers = root.device("sink-speakers", "Built-in Audio Analog Stereo", {
            "device.form-factor": "speaker"
        }, 0.42, false);
        const headset = root.device("sink-headset", "WH-1000XM Fixture", {
            "device.api": "bluez5",
            "device.form-factor": "headset"
        }, 0.65, false);
        const microphone = root.device("source-mic", "Internal microphone", {
            "device.form-factor": "microphone"
        }, 0.8, true);
        runtime.outputDevices = [speakers, headset];
        runtime.inputDevices = [microphone];
        runtime.defaultOutputId = speakers.id;
        runtime.defaultInputId = microphone.id;
        runtime.playbackStreams = [root.device("stream-music", "Fixture player", {
                "application.name": "Fixture Music"
            }, 0.7, false)];
        runtime.captureStreams = [root.device("stream-call", "Fixture call", {
                "application.name": "Fixture Call"
            }, 1, false)];
        runtime.setConnected(true);

        root.check(adapter.available && adapter.connectionState === "ready" && !adapter.stale, "late backend start publishes an authoritative ready snapshot");
        root.check(adapter.defaultOutput.id === speakers.id && adapter.masterVolume === 0.42 && !adapter.masterMuted, "default output volume and mute are normalized");
        root.check(adapter.defaultInput.id === microphone.id && adapter.microphoneMuted, "default input and microphone mute are normalized");
        root.check(adapter.outputCategory === "speaker", "strong form-factor metadata classifies speakers");
        root.check(adapter.playbackStreams.length === 1 && adapter.captureStreams.length === 1, "application playback and capture streams share the authoritative model");

        runtime.defaultOutputId = headset.id;
        runtime.sequence += 1;
        runtime.stateChanged();
        root.check(adapter.defaultOutput.id === headset.id && adapter.outputCategory === "bluetoothHeadphones", "default replacement and Bluetooth classification update atomically");

        runtime.playbackStreams = [];
        runtime.sequence += 1;
        runtime.stateChanged();
        root.check(adapter.playbackStreams.length === 0, "disappeared streams are removed rather than retained as duplicates");

        let result = controller.setMasterVolume(2);
        root.check(result.accepted && runtime.lastAction === "setVolume:sink-headset:1" && feedback.volumeCount === 1, "controller caps master volume and emits one accepted volume OSD request");
        result = controller.setMasterVolume(-1);
        root.check(result.accepted && runtime.lastAction === "setVolume:sink-headset:0" && feedback.volumeCount === 2, "controller clamps master volume and replaces the volume OSD");
        result = controller.toggleMasterMute();
        root.check(result.accepted && runtime.lastAction === "setMuted:sink-headset:true" && feedback.volumeCount === 3 && feedback.lastMuted, "master mute requests route through the adapter with explicit muted feedback");

        result = controller.selectDefaultOutput(speakers.id);
        root.check(result.accepted && feedback.toastCount === 1 && feedback.lastToastKey === "audioOutput", "accepted output selection publishes one keyed audio-output toast");

        runtime.failNextError = "AUDIO_WRITE_FAILED";
        result = controller.setMasterVolume(0.5);
        root.check(!result.accepted && result.errorCode === "AUDIO_WRITE_FAILED" && adapter.lastError === result.errorCode && feedback.volumeCount === 3, "write failures remain structured and never emit misleading OSD feedback");

        const actionsBeforeScroll = runtime.actionCount;
        controller.queueVolumeSteps(1);
        controller.queueVolumeSteps(1);
        controller.queueVolumeSteps(-1);
        root.check(runtime.actionCount === actionsBeforeScroll, "rapid scroll input waits for the coalescing boundary");
        controller.flushPendingVolume();
        root.check(runtime.actionCount === actionsBeforeScroll + 1 && runtime.lastAction === "setVolume:sink-headset:0.67", "coalesced scroll emits one bounded write using the configured step");

        root.check(controller.outputDevices === adapter.outputDevices && controller.playbackStreams === adapter.playbackStreams, "controller and consumers reference the adapter-owned models instead of copying them");

        runtime.setConnected(false);
        root.check(!adapter.available && adapter.connectionState === "reconnecting" && adapter.stale && adapter.outputDevices.length === 2, "restart retains last-known state only as explicitly stale");
        result = controller.toggleMasterMute();
        root.check(!result.accepted && result.errorCode === "AUDIO_DISCONNECTED", "stale state cannot authorize actions");

        runtime.outputDevices = [root.device("sink-unknown", "Mystery endpoint", {}, 0.3, false)];
        runtime.inputDevices = [];
        runtime.defaultOutputId = "sink-unknown";
        runtime.defaultInputId = "source-missing";
        runtime.sequence += 1;
        runtime.setConnected(true);
        root.check(adapter.available && !adapter.stale && adapter.defaultInput === null, "reconnect drops disappeared default devices without shell restart");
        root.check(adapter.outputCategory === "unknown", "unrecognized output metadata has an explicit fallback category");
        root.check(controller.outputDevices === adapter.outputDevices, "reload keeps one model owner after authoritative replacement");

        result = controller.moveStream("missing-stream", "sink-unknown");
        root.check(!result.accepted && result.errorCode === "AUDIO_STREAM_UNAVAILABLE", "stream actions reject disappeared stream IDs");

        console.info("PASS audio-adapter: absence, late start, normalization, replacement, disappearance, actions, bounds, coalescing, reconnect, fallback, and ownership");
        Qt.exit(0);
    }

    Component.onCompleted: Qt.callLater(root.run)

    FakeAudioRuntime {
        id: runtime
    }
    AudioServices.AudioAdapter {
        id: adapter

        runtime: runtime
    }
    AudioFeatures.AudioController {
        id: controller

        adapter: adapter
        feedbackController: feedback
        maximumVolume: 1
        volumeStep: 0.02
    }
    QtObject {
        id: feedback

        property bool lastMuted: false
        property string lastToastKey: ""
        property int toastCount: 0
        property int volumeCount: 0

        function showToast(record, context): var {
            void context;
            feedback.toastCount += 1;
            feedback.lastToastKey = String(record.key ?? "");
            return Object.freeze({
                "accepted": true,
                "errorCode": ""
            });
        }
        function showVolume(value: real, muted: bool, context): var {
            void value;
            void context;
            feedback.volumeCount += 1;
            feedback.lastMuted = muted;
            return Object.freeze({
                "accepted": true,
                "errorCode": ""
            });
        }
    }
}
