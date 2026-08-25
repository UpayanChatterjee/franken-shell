pragma ComponentBehavior: Bound

import "../../features/controlcenter" as ControlCenter
import "../control_center_host" as HostFixtures
import QtQuick
import Quickshell

ShellRoot {
    id: root

    property int step: 0

    function check(condition: bool, message: string) {
        if (!condition)
            root.fail(message);
    }
    function fail(message: string) {
        console.error("FAIL control-center-daily-use:", message);
        Qt.exit(1);
        throw new Error(message);
    }
    function pendingTask(taskId: string, kind: string): var {
        return Object.freeze({
            "taskId": taskId,
            "kind": kind,
            "state": "pending",
            "errorCode": ""
        });
    }
    function result(accepted: bool, errorCode = ""): var {
        return Object.freeze({
            "accepted": accepted,
            "errorCode": errorCode
        });
    }
    function runStep() {
        switch (root.step) {
        case 0:
            {
                root.check(model.quickControlCount === 5, "the stable quick-control set is exposed by the daily-use model");
                root.check(model.quickControl("nightLight").available === false && model.quickControl("idleInhibitor").available === false, "unimplemented Night Light and Keep awake services are truthfully unavailable rather than fabricated");

                fakeAudio.available = false;
                root.check(!model.slider("volume").available && model.quickControl("wifi").available, "audio absence does not disable unrelated connectivity controls");
                fakeAudio.available = true;
                fakeAudio.stale = true;
                root.check(!model.slider("volume").enabled && model.quickControl("bluetooth").available, "stale audio is locally disabled while Bluetooth remains available");
                fakeAudio.stale = false;

                fakeBrightness.visible = false;
                root.check(!model.slider("brightness").available && model.slider("volume").available, "brightness absence does not remove the master-volume path");
                fakeBrightness.visible = true;

                fakeNetwork.available = false;
                root.check(!model.quickControl("wifi").available && model.quickControl("bluetooth").available, "network absence is isolated from Bluetooth");
                fakeNetwork.available = true;
                fakeNetwork.wifiEnabled = false;
                root.check(model.quickControl("wifi").available && !model.quickControl("wifi").active, "a disabled Wi-Fi radio remains distinct from backend absence");
                fakeNetwork.operationTasks = [root.pendingTask("network-busy", "wifi")];
                root.check(model.quickControl("wifi").busy && !model.requestQuickControlAction("wifi", "toggle", "keyboard"), "a busy Wi-Fi operation rejects duplicate keyboard activation");
                fakeNetwork.operationTasks = [];
                fakeNetwork.lastError = "NETWORK_SCAN_DENIED";
                root.check(model.quickControl("wifi").error === "NETWORK_SCAN_DENIED", "network failures remain local to the affected control");
                fakeNetwork.lastError = "";

                fakeBluetooth.available = false;
                root.check(!model.quickControl("bluetooth").available && model.quickControl("wifi").available, "Bluetooth absence is isolated from Wi-Fi");
                fakeBluetooth.available = true;
                fakeBluetooth.operationTasks = [root.pendingTask("bluetooth-busy", "power")];
                root.check(model.quickControl("bluetooth").busy, "Bluetooth pending work is visible from the shared task model");
                fakeBluetooth.operationTasks = [];

                root.check(model.requestQuickControlAction("wifi", "toggle", "pointer", {
                    "monitorId": "fixture-monitor"
                }) && fakeNetwork.toggleCount === 1, "pointer Wi-Fi toggles route through the authoritative network controller");
                root.check(model.requestQuickControlAction("wifi", "toggle", "keyboard", {
                    "monitorId": "fixture-monitor"
                }) && fakeNetwork.toggleCount === 2, "keyboard Wi-Fi toggles share the same controller path");
                root.check(model.requestQuickControlAction("doNotDisturb", "toggle", "pointer") && notificationService.dnd, "Do Not Disturb updates the shared notification service");
                root.check(model.requestQuickControlAction("doNotDisturb", "toggle", "keyboard") && !notificationService.dnd && notificationService.lastOrigin === "keyboard", "Do Not Disturb keeps pointer and keyboard semantics aligned");

                root.check(model.requestSliderValue("volume", 0.73, "pointer", {
                    "monitorId": "fixture-monitor"
                }) && fakeAudio.setMasterCount === 1 && fakeAudio.masterVolume === 0.73, "pointer volume values route to the authoritative audio controller");
                root.check(model.requestSliderStep("brightness", 1, "keyboard", {
                    "monitorId": "fixture-monitor"
                }) && fakeBrightness.setCount === 1 && fakeBrightness.value === 0.55, "keyboard brightness steps route to the authoritative brightness controller");
                root.check(model.requestAudioMixerAction("defaultOutput", "headphones", 0, "pointer", {
                    "monitorId": "fixture-monitor"
                }) && fakeAudio.outputSelectionCount === 1, "output selection uses the same audio controller as master volume");
                root.check(model.requestAudioMixerAction("defaultInput", "microphone", 0, "keyboard", {
                    "monitorId": "fixture-monitor"
                }) && fakeAudio.inputSelectionCount === 1, "input selection uses the same audio controller as the mixer");
                root.check(model.requestAudioMixerAction("streamVolume", "stream-1", 0.31, "keyboard") && fakeAudio.streamVolumeCount === 1, "per-stream mixer volume stays on the shared audio model");
                root.check(model.requestAudioMixerAction("streamMute", "stream-1", 1, "pointer") && fakeAudio.streamMuteCount === 1, "per-stream mute stays on the shared audio model");

                root.check(model.requestHeaderAction("settings", "keyboard", {
                    "monitorId": "fixture-monitor"
                }) && fakeCommands.executeCount === 1, "the settings entry uses a configured stable command contract");
                root.check(!model.requestHeaderAction("session", "pointer", {
                    "monitorId": "fixture-monitor"
                }), "an unconfigured session entry fails locally rather than guessing a command");
                root.check(fakeFeedback.records.length > 0, "user-triggered changes report through the shared feedback coordinator");

                content.focusInitial();
                root.check(content.summary().focusedControlId === "quick.wifi", "the composed content retains deterministic initial keyboard focus");
                root.check(content.selectTab("volumeMixer", "keyboard"), "the mixer tab participates in the shared navigation controller");
                root.step = 1;
                settleTimer.restart();
                break;
            }
        case 1:
            {
                root.check(content.summary().activeTab === "volumeMixer" && content.summary().mixerLoaded && content.summary().mixerHeight >= 112, "the mixer is lazily instantiated with a usable viewport when selected");
                root.check(content.selectTab("notifications", "keyboard"), "the main content can leave a lazy mixer without rebuilding the drawer");
                root.check(content.openPage("network", "quick.wifi", "keyboard"), "the shared content navigates to a practical Network page");
                root.step = 2;
                settleTimer.restart();
                break;
            }
        case 2:
            {
                fakeNetwork.operationTasks = [root.pendingTask("network-task", "connect")];
                root.check(content.detailItem?.pageItem?.cancelTask("network-task") && fakeNetwork.cancelTaskCount === 1, "Network task cancellation routes through the controller from the page");
                fakeNetwork.credentialRequest = {
                    "active": true,
                    "networkId": "secure",
                    "networkName": "Office",
                    "security": "wpa2Psk"
                };
                root.check(!content.canDismiss, "a credential prompt blocks accidental drawer dismissal");
                const promptEscape = content.handleEscape();
                root.check(promptEscape.handled && content.activePage === "network" && fakeNetwork.cancelCredentialCount === 1, "Escape cancels a protected credential prompt before unwinding navigation");
                const pageEscape = content.handleEscape();
                root.check(pageEscape.handled && content.activePage === "main" && content.summary().focusedControlId === "quick.wifi", "the next Escape pops Network and restores the invoking control");
                root.check(content.openPage("bluetooth", "quick.bluetooth", "pointer"), "the shared content navigates to a practical Bluetooth page");
                root.step = 3;
                settleTimer.restart();
                break;
            }
        case 3:
            {
                fakeBluetooth.operationTasks = [root.pendingTask("bluetooth-task", "pair")];
                root.check(content.detailItem?.pageItem?.cancelTask("bluetooth-task") && fakeBluetooth.cancelTaskCount === 1, "Bluetooth task cancellation routes through the controller from the page");
                fakeBluetooth.pairingRequest = {
                    "active": true,
                    "taskId": "pairing-task",
                    "deviceName": "Keyboard",
                    "kind": "confirmation",
                    "displayCode": "482913"
                };
                root.check(!content.canDismiss, "a pairing confirmation blocks accidental drawer dismissal");
                const promptEscape = content.handleEscape();
                root.check(promptEscape.handled && content.activePage === "bluetooth" && fakeBluetooth.cancelPairingCount === 1, "Escape cancels a protected pairing confirmation before leaving Bluetooth");
                root.check(content.handleEscape().handled && content.activePage === "main", "Bluetooth returns through the same nested Escape contract");
                root.check(content.openPage("network", "quick.wifi", "pointer"), "Network can reopen after a protected operation is cancelled");
                root.step = 4;
                settleTimer.restart();
                break;
            }
        case 4:
            {
                fakeNetwork.credentialRequest = {
                    "active": true,
                    "networkId": "secure",
                    "networkName": "Office",
                    "security": "wpa2Psk"
                };
                content.resetSession();
                root.check(content.activePage === "main" && content.activeTab === "notifications" && fakeNetwork.cancelCredentialCount === 2, "close-cycle reset drops nested state and protected credentials");
                root.check(content.openPage("network", "quick.wifi", "pointer"), "the drawer can reopen a Network page after safe reset");
                root.step = 5;
                settleTimer.restart();
                break;
            }
        case 5:
            {
                fakeNetwork.available = false;
                root.check(!model.quickControl("wifi").available && content.activePage === "network", "a network service loss leaves the open drawer and other controls usable");
                fakeNetwork.available = true;
                fakeNetwork.wifiEnabled = true;
                root.check(model.quickControl("wifi").available && model.quickControl("wifi").active && content.activePage === "network", "a service reconnect updates the open page model without reopening the drawer");
                console.info("PASS control-center-daily-use: isolated backend failures, authoritative quick controls/sliders/mixer, stable entry contracts, protected prompts, cancellation, reset, and reconnect");
                Qt.quit();
                break;
            }
        default:
            root.fail("unexpected fixture step");
        }
    }

    Component.onCompleted: settleTimer.start()

    QtObject {
        id: fakeAudio

        property bool available: true
        property var defaultInput: ({
                "id": "microphone",
                "description": "Fixture microphone"
            })
        property var defaultOutput: ({
                "id": "speakers",
                "description": "Fixture speakers"
            })
        property var inputDevices: [
            {
                "id": "microphone",
                "description": "Fixture microphone"
            }
        ]
        property int inputSelectionCount: 0
        property var lastContext: ({})
        property bool masterMuted: false
        property real masterVolume: 0.42
        property string outputCategory: "speaker"
        property var outputDevices: [
            {
                "id": "speakers",
                "description": "Fixture speakers"
            },
            {
                "id": "headphones",
                "description": "Fixture headphones"
            }
        ]
        property int outputSelectionCount: 0
        property var playbackStreams: [
            {
                "id": "stream-1",
                "applicationName": "Fixture player",
                "volume": 0.42,
                "muted": false
            }
        ]
        property int setMasterCount: 0
        property bool stale: false
        property int streamMuteCount: 0
        property int streamVolumeCount: 0
        property real volumeStep: 0.02

        function selectDefaultInput(id, context) {
            inputSelectionCount += 1;
            defaultInput = inputDevices.find(candidate => candidate.id === id) ?? defaultInput;
            lastContext = context;
            return root.result(true);
        }
        function selectDefaultOutput(id, context) {
            outputSelectionCount += 1;
            defaultOutput = outputDevices.find(candidate => candidate.id === id) ?? defaultOutput;
            lastContext = context;
            return root.result(true);
        }
        function setMasterVolume(value, context) {
            masterVolume = Number(value);
            setMasterCount += 1;
            lastContext = context;
            return root.result(true);
        }
        function setStreamMuted(id, muted) {
            void id;
            void muted;
            streamMuteCount += 1;
            return root.result(true);
        }
        function setStreamVolume(id, value) {
            void id;
            void value;
            streamVolumeCount += 1;
            return root.result(true);
        }
        function toggleMasterMute(context) {
            masterMuted = !masterMuted;
            lastContext = context;
            return root.result(true);
        }
    }
    QtObject {
        id: fakeBluetooth

        property bool available: true
        property var availableDevices: []
        property int cancelPairingCount: 0
        property int cancelTaskCount: 0
        property var connectedDevices: []
        property var devices: [
            {
                "id": "keyboard",
                "name": "Keyboard",
                "paired": true,
                "connected": false
            }
        ]
        property string discoveryState: "idle"
        property string lastError: ""
        property var operationTasks: []
        property var pairedDevices: []
        property var pairingRequest: ({
                "active": false
            })
        property bool powered: true
        property string quickSummary: "On"
        property string status: "ready"

        function cancelPairingPrompt() {
            cancelPairingCount += 1;
            pairingRequest = {
                "active": false
            };
            return root.result(true);
        }
        function cancelTask(taskId) {
            void taskId;
            cancelTaskCount += 1;
            return root.result(true);
        }
        function connectDevice(id) {
            void id;
            return root.result(true);
        }
        function disconnectDevice(id) {
            void id;
            return root.result(true);
        }
        function pairDevice(id) {
            void id;
            return root.result(true);
        }
        function startDiscovery() {
            discoveryState = "discovering";
            return root.result(true);
        }
        function stopDiscovery() {
            discoveryState = "idle";
            return root.result(true);
        }
    }
    QtObject {
        id: fakeBrightness

        property real brightnessStep: 0.05
        property int setCount: 0
        property real value: 0.5
        property bool visible: true

        function setValue(nextValue, context) {
            void context;
            value = Number(nextValue);
            setCount += 1;
            return root.result(true);
        }
    }
    QtObject {
        id: fakeCommands

        property int executeCount: 0

        function commandAvailable(id) {
            return id === "settings.open";
        }
        function execute(id) {
            executeCount += 1;
            return {
                "commandId": id,
                "state": "queued"
            };
        }
    }
    QtObject {
        id: fakeFeedback

        property var records: []

        function showToast(record, context) {
            records = records.concat([
                {
                    "record": record,
                    "context": context
                }
            ]);
            return root.result(true);
        }
    }
    QtObject {
        id: fakeNetwork

        property var activeConnection: null
        property bool available: true
        property int cancelCredentialCount: 0
        property int cancelTaskCount: 0
        property var credentialRequest: ({
                "active": false
            })
        property var ethernetDevices: []
        property string lastError: ""
        property var operationTasks: []
        property string quickSummary: "Not connected"
        property var savedNetworks: []
        property string scanState: "idle"
        property int toggleCount: 0
        property var visibleNetworks: [
            {
                "id": "secure",
                "name": "Office",
                "security": "wpa2Psk",
                "connected": false
            }
        ]
        property bool wifiEnabled: true
        property bool wifiHardwareAvailable: true

        function cancelCredential() {
            cancelCredentialCount += 1;
            credentialRequest = {
                "active": false
            };
        }
        function cancelTask(taskId) {
            void taskId;
            cancelTaskCount += 1;
            return root.result(true);
        }
        function connectNetwork(id) {
            credentialRequest = {
                "active": true,
                "networkId": id,
                "networkName": "Office",
                "security": "wpa2Psk"
            };
            return {
                "accepted": true,
                "promptRequired": true,
                "errorCode": ""
            };
        }
        function disconnectNetwork(id) {
            void id;
            return root.result(true);
        }
        function requestScan() {
            scanState = "scanning";
            return root.result(true);
        }
        function submitCredential(value) {
            void value;
            credentialRequest = {
                "active": false
            };
            return {
                "accepted": true,
                "promptRequired": false,
                "errorCode": ""
            };
        }
        function toggleWifi() {
            toggleCount += 1;
            return root.result(true);
        }
    }
    QtObject {
        id: notificationService

        property bool dnd: false
        property string lastOrigin: ""
        property var records: []

        function setDnd(value, origin) {
            dnd = value;
            lastOrigin = origin;
            return root.result(true);
        }
    }
    QtObject {
        id: fakeNotification

        property var historyRows: []
        property var service: notificationService

        signal historyRowsAboutToChange

        function clearHistory() {
            return root.result(true);
        }
    }
    ControlCenter.ControlCenterDailyUseModel {
        id: model

        audioController: fakeAudio
        bluetoothController: fakeBluetooth
        brightnessController: fakeBrightness
        commandRegistry: fakeCommands
        feedbackController: fakeFeedback
        networkController: fakeNetwork
        notificationController: fakeNotification
    }
    HostFixtures.FakeControlCenterTheme {
        id: fixtureTheme
    }
    FloatingWindow {
        color: "transparent"
        implicitHeight: 720
        implicitWidth: 400
        visible: true

        ControlCenter.ControlCenterContent {
            id: content

            anchors.fill: parent
            contentModel: model
            focus: true
            theme: fixtureTheme
        }
    }
    Timer {
        id: settleTimer

        interval: 30

        onTriggered: root.runStep()
    }
}
