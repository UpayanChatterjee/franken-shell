import "../../features/bluetooth" as BluetoothFeatures
import "../../features/controlcenter" as ControlCenter
import "../../services/bluetooth" as BluetoothServices
import QtQuick
import Quickshell

ShellRoot {
    id: root

    readonly property string audioId: "bluetooth:hci0:AA:BB:CC:DD:EE:01"
    readonly property string contextId: "bluetooth:hci0:AA:BB:CC:DD:EE:03"
    readonly property string inputId: "bluetooth:hci0:AA:BB:CC:DD:EE:02"

    function adapterRecord(powered: bool, discovering: bool, devices): var {
        return Object.freeze({
            "id": "bluetooth:hci0",
            "name": "Host adapter",
            "state": powered ? "enabled" : "disabled",
            "defaultAdapter": true,
            "powered": powered,
            "discovering": discovering,
            "devices": Object.freeze(devices)
        });
    }
    function check(condition: bool, message: string) {
        if (!condition)
            root.fail(message);
    }
    function device(id: string, name: string, category: string, paired: bool, connected: bool, pairing = false, battery = -1): var {
        return Object.freeze({
            "id": id,
            "adapterId": "bluetooth:hci0",
            "address": id.slice(id.lastIndexOf(":") + 1),
            "name": name,
            "icon": category,
            "category": category,
            "paired": paired,
            "bonded": paired,
            "trusted": paired,
            "connected": connected,
            "pairing": pairing,
            "batteryAvailable": battery >= 0,
            "battery": battery,
            "audioCapable": category === "audio",
            "state": connected ? "connected" : "disconnected"
        });
    }
    function fail(message: string) {
        console.error("FAIL bluetooth-adapter:", message);
        Qt.exit(1);
        throw new Error(message);
    }
    function latestTask(): var {
        return adapter.operationTasks[adapter.operationTasks.length - 1];
    }
    function publish(powered: bool, discovering: bool, devices) {
        runtime.adapters = [root.adapterRecord(powered, discovering, devices)];
        runtime.sequence += 1;
        runtime.stateChanged();
    }
    // Fixture objects intentionally cross var boundaries to exercise reload-safe
    // reconstruction and controller ownership.
    // qmllint disable missing-property
    function run() {
        root.check(!adapter.available && adapter.status === "unavailable" && adapter.devices.length === 0, "adapter absence is explicit and does not fabricate devices");

        runtime.setConnected(true);
        root.publish(false, false, []);
        root.check(adapter.available && !adapter.powered && adapter.status === "disabled", "late adapter arrival produces an authoritative powered-off state");
        root.check(!controlCenterModel.bluetooth.active && controlCenterModel.bluetooth.secondaryText === "Off", "quick control consumes normalized powered-off state");

        let response;
        const quickToggleAccepted = controlCenterModel.requestQuickControlAction("bluetooth", "toggle", "fixture");
        root.check(quickToggleAccepted && adapter.status === "changing", "quick-control power toggle routes through the shared controller and exposes a pending task");
        root.publish(true, false, []);
        root.check(root.latestTask().state === "completed" && adapter.status === "ready", "authoritative power state completes the toggle");

        controller.detailVisible = true;
        root.check(root.latestTask().kind === "discovery" && root.latestTask().state === "pending", "opening the Bluetooth page starts bounded discovery");
        controller.detailVisible = false;
        root.check(root.latestTask().desiredValue === false && runtime.lastAction.indexOf("discover-stop:") === 0, "closing during discovery startup supersedes the pending start safely");
        root.publish(true, false, []);
        root.check(root.latestTask().state === "completed", "interrupted discovery settles from authoritative stopped state");
        root.publish(true, true, []);
        root.check(root.latestTask().desiredValue === false && root.latestTask().state === "pending", "a late discovery start is stopped while the detail page remains closed");
        root.publish(true, false, []);
        controller.detailVisible = true;
        root.publish(true, true, []);
        root.check(adapter.discoveryState === "discovering" && root.latestTask().state === "completed", "backend discovery state completes the task");
        controller.detailVisible = false;
        root.publish(true, false, []);
        root.check(adapter.discoveryState === "idle", "closing the Bluetooth page stops discovery");

        runtime.failNextError = "BLUETOOTH_DISCOVERY_DENIED";
        response = controller.startDiscovery();
        root.check(!response.accepted && adapter.discoveryState === "failed" && adapter.lastError === "BLUETOOTH_DISCOVERY_DENIED", "discovery rejection remains distinct from an empty result");
        response = controller.startDiscovery();
        const timedDiscovery = root.latestTask();
        adapter.expireTasks(timedDiscovery.deadlineMs + 1);
        root.check(response.accepted && root.latestTask().state === "failed" && adapter.lastError === "BLUETOOTH_OPERATION_TIMEOUT", "an unobserved backend transition fails instead of remaining frozen");

        const audio = root.device(root.audioId, "Headset", "audio", true, true, false, 0.72);
        const context = root.device(root.contextId, "Keyboard", "input", true, true, false, 0.58);
        const input = root.device(root.inputId, "Gamepad", "input", false, false);
        root.publish(true, false, [input, audio, context]);
        root.check(adapter.pairedDevices.length === 2 && adapter.connectedDevices.length === 2 && adapter.availableDevices.length === 1, "paired, connected, and nearby device models remain distinct");
        root.check(adapter.devices[0].name === "Gamepad" && adapter.devices[1].name === "Headset", "first device snapshot is deterministically ordered");
        root.publish(true, false, [context, audio, input]);
        root.check(adapter.devices[0].name === "Gamepad", "backend order changes preserve stable device row order");
        root.check(adapter.connectedDevices[0].battery === 0.72 && adapter.nonAudioConnectedDevices.length === 1 && controller.quickSummary === "Keyboard", "battery and non-audio context are normalized while audio context remains owned by the audio adapter");

        response = controller.pairDevice(root.inputId);
        root.check(response.accepted && adapter.status === "pairing", "pairing starts an observable task");
        runtime.requestPairing("confirmation", "482913");
        root.check(adapter.status === "awaitingConfirmation" && controller.pairingRequest.active && controller.pairingRequest.displayCode === "482913", "pairing confirmation is explicit foreground state");
        response = controller.confirmPairing(true);
        root.check(response.accepted && !controller.pairingRequest.active, "confirmation clears protected prompt state immediately");
        root.publish(true, false, [root.device(root.inputId, "Gamepad", "input", true, false), audio]);
        root.check(root.latestTask().state === "completed", "authoritative paired state completes pairing");

        response = controller.forgetDevice(root.inputId);
        root.check(response.accepted, "paired device exposes an explicit forget task");
        root.publish(true, false, [audio]);
        root.check(root.latestTask().state === "completed" && adapter.pairedDevices.length === 1, "device disappearance completes forget without destabilizing remaining rows");

        root.publish(true, false, [input, audio]);
        response = controller.pairDevice(root.inputId);
        runtime.requestPairing("code", "");
        const pairingCode = "fixture-pin-7462";
        response = controller.submitPairingCode(pairingCode);
        root.check(response.accepted && runtime.lastPairingCodeLength === pairingCode.length && !controller.pairingRequest.active, "pairing code is forwarded once and cleared immediately");
        const codeTask = root.latestTask();
        runtime.actionFailed(codeTask.taskId, "BLUETOOTH_PAIRING_REJECTED");
        const exposed = JSON.stringify(adapter.diagnosticsSummary()) + JSON.stringify({
            "bluetooth": controlCenterModel.bluetooth,
            "bluetoothPage": controlCenterModel.bluetoothPage,
            "tasks": adapter.operationTasks
        });
        root.check(exposed.indexOf(pairingCode) < 0, "pairing codes never enter diagnostics, task, or control-centre models");

        response = controller.pairDevice(root.inputId);
        runtime.requestPairing("confirmation", "314159");
        const promptReload = freshAdapter.createObject(root, {
            "runtime": runtime
        });
        root.check(promptReload !== null && promptReload["operationTasks"].length === 0 && !promptReload["pairingRequest"].active, "reload reconstruction cannot repeat an active pairing confirmation");
        promptReload.destroy();
        response = controller.confirmPairing(false);
        root.check(response.accepted && root.latestTask().state === "cancelled" && !controller.pairingRequest.active, "pairing rejection is explicit and clears prompt state");

        response = controller.pairDevice(root.inputId);
        const pairingTask = root.latestTask();
        response = controller.cancelTask(pairingTask.taskId);
        root.check(response.accepted && root.latestTask().state === "cancelled" && runtime.lastAction.indexOf("cancel-pair:") === 0, "pairing is explicitly cancellable");

        response = controller.pairDevice(root.inputId);
        root.publish(true, false, [audio]);
        root.check(response.accepted && root.latestTask().state === "failed" && root.latestTask().errorCode === "BLUETOOTH_DEVICE_VANISHED", "device disappearance fails an unsafe pairing task explicitly");
        root.publish(true, false, [input, root.device(root.audioId, "Headset", "audio", true, false, false, 0.72)]);
        response = controller.connectDevice(root.audioId);
        root.check(response.accepted && adapter.status === "connecting", "connection exposes progress without selecting an audio output");
        runtime.failLast("BLUETOOTH_CONNECTION_FAILED");
        root.check(adapter.status === "failed" && adapter.lastError === "BLUETOOTH_CONNECTION_FAILED", "connection failure is structured and local");

        response = controller.pairDevice(root.inputId);
        runtime.setConnected(false);
        root.check(!adapter.available && adapter.connectionState === "reconnecting" && adapter.stale && root.latestTask().state === "failed", "service loss retains stale state and fails unsafe work");
        runtime.adapters = [root.adapterRecord(true, false, [audio])];
        runtime.sequence += 1;
        runtime.setConnected(true);
        root.check(adapter.available && !adapter.stale && adapter.devices.length === 1, "service reconnect replaces stale state without restarting consumers");

        const fresh = freshAdapter.createObject(root, {
            "runtime": runtime
        });
        root.check(fresh !== null && fresh["operationTasks"].length === 0 && !fresh["pairingRequest"].active, "reload reconstruction cannot repeat an unsafe pairing task or prompt");
        fresh.destroy();

        const pageModel = controlCenterModel["bluetoothPage"];
        root.check(pageModel.connectedDeviceCount === adapter.connectedDevices.length && pageModel.status === controller.status, "placeholder Bluetooth page consumes the shared controller");
        console.info("PASS bluetooth-adapter: absence, power, bounded discovery, failure, stable devices, battery, pairing confirmation/code/reject/cancel, secret redaction, forget, audio ownership, reconnect, disappearance, and reload safety");
        Qt.exit(0);
    }

    // qmllint enable missing-property

    Component.onCompleted: Qt.callLater(root.run)

    FakeBluetoothRuntime {
        id: runtime
    }
    BluetoothServices.BluetoothAdapter {
        id: adapter

        runtime: runtime
    }
    BluetoothFeatures.BluetoothController {
        id: controller

        adapter: adapter
    }
    ControlCenter.ControlCenterPlaceholderModel {
        id: controlCenterModel

        bluetoothController: controller
    }
    Component {
        id: freshAdapter

        BluetoothServices.BluetoothAdapter {
        }
    }
}
