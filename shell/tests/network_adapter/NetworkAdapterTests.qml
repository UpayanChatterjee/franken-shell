import "../../features/controlcenter" as ControlCenter
import "../../features/network" as NetworkFeatures
import "../../services/network" as NetworkServices
import QtQuick
import Quickshell

ShellRoot {
    id: root

    readonly property string openId: "wifi:wlan0:aa:network:Cafe"
    readonly property string savedId: "wifi:wlan0:aa:network:Home"
    readonly property string secureId: "wifi:wlan0:aa:network:Office"

    function check(condition: bool, message: string) {
        if (!condition)
            root.fail(message);
    }
    function device(networks, connected = false): var {
        return Object.freeze({
            "id": "wifi:wlan0:aa",
            "name": "wlan0",
            "address": "aa",
            "type": "wifi",
            "state": connected ? "connected" : "disconnected",
            "connected": connected,
            "hasLink": false,
            "linkSpeedMbps": 0,
            "networks": Object.freeze(networks)
        });
    }
    function ethernet(connected: bool): var {
        return Object.freeze({
            "id": "ethernet:enp1s0:bb",
            "name": "enp1s0",
            "address": "bb",
            "type": "ethernet",
            "state": connected ? "connected" : "disconnected",
            "connected": connected,
            "hasLink": true,
            "linkSpeedMbps": 1000,
            "networks": Object.freeze([root.network("ethernet:enp1s0:bb:network:enp1s0", "enp1s0", "wired", true, connected, true, connected ? "connected" : "disconnected", 1)])
        });
    }
    function fail(message: string) {
        console.error("FAIL network-adapter:", message);
        Qt.exit(1);
        throw new Error(message);
    }
    function latestTask(): var {
        return adapter.operationTasks[adapter.operationTasks.length - 1];
    }
    function network(id: string, name: string, security: string, known: bool, connected: bool, visible: bool, networkState: string, strength: real): var {
        return Object.freeze({
            "id": id,
            "name": name,
            "signalStrength": strength,
            "security": security,
            "known": known,
            "connected": connected,
            "visible": visible,
            "state": networkState
        });
    }
    function publish(networks, connectivity = "offline", ethernetConnected = false) {
        runtime.devices = [root.device(networks, networks.some(network => network.connected)), root.ethernet(ethernetConnected)];
        runtime.connectivity = connectivity;
        runtime.sequence += 1;
        runtime.stateChanged();
    }
    // Runtime-created fixture objects and nested QtObject models intentionally
    // cross a var boundary so reload ownership can be tested.
    // qmllint disable missing-property
    function run() {
        root.check(!adapter.available && adapter.status === "unavailable" && adapter.visibleNetworks.length === 0, "backend absence is explicit and does not fabricate networks");

        runtime.wifiHardwareAvailable = true;
        runtime.wifiEnabled = false;
        runtime.setConnected(true);
        root.check(adapter.available && adapter.connectionState === "ready" && adapter.status === "disabled", "late backend arrival produces a disabled authoritative snapshot");
        const wifiModel = controlCenterModel.quickControl("wifi");
        root.check(wifiModel.available && !wifiModel.active && wifiModel.secondaryText === "Off", "quick control consumes normalized disabled state");

        let response = controller.toggleWifi();
        root.check(response.accepted && adapter.status === "connecting", "Wi-Fi toggle exposes a pending task");
        runtime.wifiEnabled = true;
        runtime.sequence += 1;
        runtime.stateChanged();
        root.check(root.latestTask().state === "completed", "authoritative Wi-Fi radio state completes the toggle task");

        const initial = [root.network(root.secureId, "Office", "wpa2Psk", false, false, true, "disconnected", 0.82), root.network(root.openId, "Cafe", "open", false, false, true, "disconnected", 0.48), root.network(root.savedId, "Home", "wpa2Psk", true, false, false, "disconnected", 0)];
        root.publish(initial);
        root.check(adapter.visibleNetworks.length === 2 && adapter.savedNetworks.length === 1, "visible and saved network models are distinct without duplicating rows");
        root.check(adapter.visibleNetworks[0].name === "Cafe" && adapter.visibleNetworks[1].name === "Office", "first scan uses deterministic name ordering");
        root.publish([initial[0], initial[1], initial[2]]);
        root.check(adapter.visibleNetworks[0].name === "Cafe", "signal and backend order changes preserve stable visible row order");

        controller.detailVisible = true;
        root.check(runtime.scanning && adapter.scanState === "scanning", "opening the Network page enables bounded native scanning");
        controller.detailVisible = false;
        root.check(!runtime.scanning && adapter.scanState === "idle", "closing the Network page stops scan/list activity");
        runtime.failNextError = "NETWORK_SCAN_DENIED";
        response = controller.requestScan();
        root.check(!response.accepted && adapter.scanState === "failed" && adapter.lastError === "NETWORK_SCAN_DENIED", "scan rejection remains distinct from an empty scan");

        response = controller.connectNetwork(root.openId);
        root.check(response.accepted && !response.promptRequired && runtime.lastCredentialLength === 0, "open network connection starts without credentials");
        root.publish([root.network(root.secureId, "Office", "wpa2Psk", false, false, true, "disconnected", 0.82), root.network(root.openId, "Cafe", "open", true, true, true, "connected", 0.48), initial[2]], "internet");
        root.check(adapter.status === "connected" && adapter.activeConnection.id === root.openId && root.latestTask().state === "completed", "connected state completes an open-network task from authoritative data");

        response = controller.disconnectNetwork(root.openId);
        root.check(response.accepted, "connected network exposes disconnect through the controller");
        root.publish(initial);
        root.check(root.latestTask().state === "completed", "disconnect completes only after the connection disappears");

        response = controller.connectNetwork(root.secureId);
        root.check(response.accepted && response.promptRequired && controller.credentialRequest.active, "unknown secured network requests a protected credential flow");
        const secret = "correct-horse-fixture";
        response = controller.submitCredential(secret);
        root.check(response.accepted && !controller.credentialRequest.active && runtime.lastCredentialLength === secret.length, "credential is forwarded once and prompt state clears immediately");
        const exposed = JSON.stringify(adapter.diagnosticsSummary()) + JSON.stringify({
            "credentialRequest": controller.credentialRequest,
            "quickSummary": controller.quickSummary,
            "wifi": controlCenterModel.wifi
        });
        root.check(exposed.indexOf(secret) < 0, "credentials never enter diagnostics or control-centre models");
        const connectTask = root.latestTask();
        response = controller.cancelTask(connectTask.taskId);
        root.check(response.accepted && root.latestTask().state === "cancelled" && runtime.lastAction.indexOf("cancel-connect:") === 0, "in-flight connection is explicitly cancellable");

        response = controller.connectNetwork(root.secureId);
        root.check(response.promptRequired, "secured reconnect starts a fresh credential request");
        controller.cancelCredential();
        root.check(!controller.credentialRequest.active, "credential cancellation clears all prompt metadata");

        root.publish([initial[0], initial[1], initial[2]], "limited");
        root.check(adapter.status === "limited" && controller.quickSummary === "Limited connectivity", "limited connectivity has a distinct state and summary");
        root.publish([initial[0], initial[1], initial[2]], "captive");
        root.check(adapter.status === "captive" && controller.quickSummary === "Login required", "captive portal state is distinct from limited connectivity");

        response = controller.connectNetwork(root.openId);
        root.check(response.accepted, "reconnect task can start after prior terminal tasks");
        runtime.failLast("NETWORK_AUTHENTICATION_TIMEOUT");
        root.check(adapter.status === "failed" && adapter.lastError === "NETWORK_AUTHENTICATION_TIMEOUT", "connection failure is structured and local");

        response = controller.forgetNetwork(root.savedId);
        root.check(response.accepted, "saved connection exposes an explicit forget task");
        root.publish([initial[0], initial[1]]);
        root.check(adapter.savedNetworks.length === 0 && root.latestTask().state === "completed", "forget completion follows authoritative saved-profile removal");
        root.check(adapter.status === "disconnected", "a successful newer operation clears an older failure from aggregate status");

        response = controller.connectNetwork(root.openId);
        root.check(response.accepted, "a pending task exists before backend loss");
        runtime.setConnected(false);
        root.check(!adapter.available && adapter.connectionState === "reconnecting" && adapter.stale && root.latestTask().state === "failed", "backend loss marks retained state stale and fails unsafe work");
        runtime.connectivity = "internet";
        runtime.sequence += 1;
        runtime.setConnected(true);
        root.check(adapter.available && !adapter.stale, "backend reconnect replaces stale state without restarting consumers");

        const fresh = freshAdapter.createObject(root, {
            "runtime": runtime
        });
        root.check(fresh !== null && fresh["operationTasks"].length === 0, "reload reconstruction never restores an unsafe operation task");
        fresh.destroy();

        const pageModel = controlCenterModel["networkPage"];
        root.check(pageModel.visibleNetworkCount === adapter.visibleNetworks.length && pageModel.status === controller.status, "placeholder Network page model consumes the shared controller");
        console.info("PASS network-adapter: absence, late start, disabled radio, stable scan models, scan failure, open/secured connect, secret redaction, cancellation, limited/captive, forget, reconnect, reload safety, and control-centre ownership");
        Qt.exit(0);
    }

    // qmllint enable missing-property

    Component.onCompleted: Qt.callLater(root.run)

    FakeNetworkRuntime {
        id: runtime
    }
    NetworkServices.NetworkAdapter {
        id: adapter

        runtime: runtime
    }
    NetworkFeatures.NetworkController {
        id: controller

        adapter: adapter
    }
    ControlCenter.ControlCenterPlaceholderModel {
        id: controlCenterModel

        networkController: controller
    }
    Component {
        id: freshAdapter

        NetworkServices.NetworkAdapter {
        }
    }
}
