import QtQuick

QtObject {
    id: root

    readonly property bool audioAvailable: root.audioController?.available === true
    property var audioController: null
    readonly property string audioDefaultOutputName: String(root.audioController?.defaultOutput?.description ?? root.audioController?.defaultOutput?.name ?? "")
    readonly property int audioPlaybackStreamCount: root.audioController?.playbackStreams?.length ?? 0
    readonly property QtObject bluetooth: QtObject {
        readonly property bool active: root.bluetoothController?.powered === true
        readonly property bool available: root.bluetoothController?.available === true
        readonly property bool busy: root.pendingTask(root.bluetoothController?.operationTasks)
        readonly property bool canOpenDetails: true
        readonly property bool canToggle: available && !busy
        readonly property bool enabled: available
        readonly property string error: String(root.bluetoothController?.lastError ?? "")
        readonly property string icon: "B"
        readonly property string label: qsTr("Bluetooth")
        readonly property string secondaryText: String(root.bluetoothController?.quickSummary ?? qsTr("Unavailable"))
    }
    property var bluetoothController: null
    readonly property QtObject bluetoothPage: QtObject {
        readonly property int availableDeviceCount: root.bluetoothController?.availableDevices?.length ?? 0
        readonly property int connectedDeviceCount: root.bluetoothController?.connectedDevices?.length ?? 0
        readonly property string discoveryState: String(root.bluetoothController?.discoveryState ?? "idle")
        readonly property int pairedDeviceCount: root.bluetoothController?.pairedDevices?.length ?? 0
        readonly property bool pairingPromptActive: root.bluetoothController?.pairingRequest?.active === true
        readonly property bool powered: root.bluetoothController?.powered === true
        readonly property string status: String(root.bluetoothController?.status ?? "unavailable")
    }
    readonly property QtObject brightness: QtObject {
        readonly property bool available: root.brightnessController?.visible === true
        readonly property bool enabled: available
        readonly property string icon: "☀"
        readonly property string label: qsTr("Brightness")
        readonly property real value: root.brightnessController?.value ?? 0
    }
    property var brightnessController: null
    property var commandRegistry: null
    readonly property QtObject doNotDisturb: QtObject {
        readonly property bool active: root.notificationController?.service?.dnd === true
        readonly property bool available: root.notificationController?.service !== null && root.notificationController?.service !== undefined
        readonly property bool busy: false
        readonly property bool canOpenDetails: false
        readonly property bool canToggle: available
        readonly property bool enabled: available
        readonly property string error: ""
        readonly property string icon: "D"
        readonly property string label: qsTr("Do Not Disturb")
        readonly property string secondaryText: active ? qsTr("On") : available ? qsTr("Off") : qsTr("Unavailable")
    }
    property var feedbackController: null
    readonly property QtObject idleInhibitor: QtObject {
        readonly property bool active: false
        readonly property bool available: false
        readonly property bool busy: false
        readonly property bool canOpenDetails: false
        readonly property bool canToggle: false
        readonly property bool enabled: false
        readonly property string error: ""
        readonly property string icon: "I"
        readonly property string label: qsTr("Keep awake")
        readonly property string secondaryText: qsTr("Service unavailable")
    }
    readonly property QtObject network: QtObject {
        readonly property bool active: root.networkController?.wifiEnabled === true
        readonly property bool available: root.networkController?.available === true
        readonly property bool busy: root.pendingTask(root.networkController?.operationTasks)
        readonly property bool canOpenDetails: true
        readonly property bool canToggle: available && root.networkController?.wifiHardwareAvailable === true && !busy
        readonly property bool enabled: available && root.networkController?.wifiHardwareAvailable === true
        readonly property string error: String(root.networkController?.lastError ?? "")
        readonly property string icon: "W"
        readonly property string label: qsTr("Wi-Fi")
        readonly property string secondaryText: String(root.networkController?.quickSummary ?? qsTr("Unavailable"))
    }
    property var networkController: null
    readonly property QtObject networkPage: QtObject {
        readonly property var activeConnection: root.networkController?.activeConnection ?? null
        readonly property int ethernetDeviceCount: root.networkController?.ethernetDevices?.length ?? 0
        readonly property int savedNetworkCount: root.networkController?.savedNetworks?.length ?? 0
        readonly property string scanState: String(root.networkController?.scanState ?? "idle")
        readonly property string status: String(root.networkController?.status ?? "unavailable")
        readonly property int visibleNetworkCount: root.networkController?.visibleNetworks?.length ?? 0
    }
    readonly property QtObject nightLight: QtObject {
        readonly property bool active: false
        readonly property bool available: false
        readonly property bool busy: false
        readonly property bool canOpenDetails: false
        readonly property bool canToggle: false
        readonly property bool enabled: false
        readonly property string error: ""
        readonly property string icon: "N"
        readonly property string label: qsTr("Night Light")
        readonly property string secondaryText: qsTr("Service unavailable")
    }
    property var notificationController: null
    readonly property int quickControlCount: 5
    readonly property QtObject volume: QtObject {
        readonly property bool available: root.audioAvailable
        readonly property bool enabled: available && root.audioController?.stale !== true
        readonly property string icon: root.audioController?.outputCategory === "muted" ? "M" : "V"
        readonly property string label: qsTr("Volume")
        readonly property real value: root.audioController?.masterVolume ?? 0
    }
    readonly property QtObject wifi: root.network

    function accepted(response): bool {
        return response?.accepted === true;
    }
    function actionContext(context, origin: string, originControlId: string): var {
        return Object.assign({}, context ?? {}, {
            "origin": origin,
            "originControlId": originControlId
        });
    }
    function commandIdForHeaderAction(actionId: string): string {
        if (actionId === "settings")
            return "settings.open";
        if (actionId === "session")
            return "session.open";
        return "";
    }
    function headerActionAvailable(actionId: string): bool {
        const commandId = root.commandIdForHeaderAction(actionId);
        return commandId.length > 0 && root.commandRegistry?.commandAvailable(commandId) === true;
    }
    function pendingTask(tasks): bool {
        return Array.isArray(tasks) && tasks.some(task => ["queued", "starting", "running", "pending", "awaitingInput"].indexOf(String(task?.state ?? "")) >= 0);
    }
    function quickControl(controlId: string): var {
        switch (controlId) {
        case "wifi":
            return root.wifi;
        case "bluetooth":
            return root.bluetooth;
        case "doNotDisturb":
            return root.doNotDisturb;
        case "nightLight":
            return root.nightLight;
        case "idleInhibitor":
            return root.idleInhibitor;
        default:
            return null;
        }
    }
    function requestAudioMixerAction(actionId: string, targetId: string, value: real, source: string, context = ({})): bool {
        const actionContext = root.actionContext(context, source, "audio.mixer." + actionId);
        let response = null;
        if (root.audioController === null)
            return false;

        if (actionId === "defaultOutput")
            response = root.audioController.selectDefaultOutput(targetId, actionContext);
        else if (actionId === "defaultInput")
            response = root.audioController.selectDefaultInput(targetId, actionContext);
        else if (actionId === "streamMute")
            response = root.audioController.setStreamMuted(targetId, value > 0.5);
        else if (actionId === "streamVolume")
            response = root.audioController.setStreamVolume(targetId, value);
        else if (actionId === "masterMute")
            response = root.audioController.toggleMasterMute(actionContext);
        else
            return false;
        return root.accepted(response);
    }
    function requestHeaderAction(actionId: string, source: string, context = ({})): bool {
        const commandId = root.commandIdForHeaderAction(actionId);
        const actionContext = root.actionContext(context, source, "header." + actionId);
        if (commandId.length === 0 || root.commandRegistry?.commandAvailable(commandId) !== true) {
            root.showFeedback({
                "key": "generic",
                "severity": "failure",
                "summary": actionId === "settings" ? qsTr("Settings unavailable") : qsTr("Session controls unavailable"),
                "detail": qsTr("Configure the matching command before using this entry."),
                "userTriggered": true
            }, actionContext);
            return false;
        }

        const response = root.commandRegistry.execute(commandId);
        if (response?.state === "unavailable") {
            root.showFeedback({
                "key": "generic",
                "severity": "failure",
                "summary": actionId === "settings" ? qsTr("Settings unavailable") : qsTr("Session controls unavailable"),
                "detail": qsTr("The configured command is currently unavailable."),
                "userTriggered": true
            }, actionContext);
            return false;
        }
        root.showFeedback({
            "key": "generic",
            "severity": "info",
            "summary": actionId === "settings" ? qsTr("Opening settings…") : qsTr("Opening session controls…"),
            "detail": "",
            "userTriggered": true
        }, actionContext);
        return true;
    }
    function requestQuickControlAction(controlId: string, action: string, source: string, context = ({})): bool {
        const actionContext = root.actionContext(context, source, "quick." + controlId);
        const control = root.quickControl(controlId);
        if (action === "details")
            return control?.canOpenDetails === true;

        let response = null;
        if (controlId === "wifi" && action === "toggle" && control?.canToggle === true)
            response = root.networkController.toggleWifi();
        else if (controlId === "bluetooth" && action === "toggle" && control?.canToggle === true)
            response = root.bluetoothController.togglePowered();
        else if (controlId === "doNotDisturb" && action === "toggle" && control?.canToggle === true)
            response = root.notificationController.service.setDnd(control?.active !== true, source);
        else if (controlId === "nightLight" || controlId === "idleInhibitor") {
            root.showFeedback({
                "key": controlId,
                "severity": "failure",
                "summary": controlId === "nightLight" ? qsTr("Night Light unavailable") : qsTr("Keep awake unavailable"),
                "detail": qsTr("This service has not been connected yet."),
                "userTriggered": true
            }, actionContext);
            return false;
        } else {
            return false;
        }

        if (!root.accepted(response)) {
            root.showFeedback({
                "key": controlId === "wifi" ? "network" : controlId,
                "severity": "failure",
                "summary": controlId === "wifi" ? qsTr("Wi-Fi could not change") : controlId === "bluetooth" ? qsTr("Bluetooth could not change") : qsTr("Do Not Disturb could not change"),
                "detail": String(response?.errorCode ?? ""),
                "userTriggered": true
            }, actionContext);
            return false;
        }
        if (controlId === "wifi" || controlId === "bluetooth") {
            root.showFeedback({
                "key": controlId === "wifi" ? "network" : "bluetooth",
                "severity": "info",
                "summary": controlId === "wifi" ? qsTr("Updating Wi-Fi…") : qsTr("Updating Bluetooth…"),
                "detail": "",
                "userTriggered": true
            }, actionContext);
        }
        return true;
    }
    function requestSliderStep(sliderId: string, step: int, source: string, context = ({})): bool {
        const sliderModel = root.slider(sliderId);
        if (sliderModel?.available !== true || sliderModel?.enabled !== true || step === 0)
            return false;
        const delta = sliderId === "volume" ? root.audioController?.volumeStep ?? 0.02 : root.brightnessController?.brightnessStep ?? 0.05;
        return root.requestSliderValue(sliderId, sliderModel.value + step * delta, source, context);
    }
    function requestSliderValue(sliderId: string, value: real, source: string, context = ({})): bool {
        const actionContext = root.actionContext(context, source, "slider." + sliderId);
        const sliderModel = root.slider(sliderId);
        if (sliderId === "volume" && sliderModel?.enabled === true)
            return root.accepted(root.audioController.setMasterVolume(value, actionContext));
        if (sliderId === "brightness" && sliderModel?.enabled === true)
            return root.accepted(root.brightnessController.setValue(value, actionContext));
        return false;
    }
    function showFeedback(record, context) {
        if (root.feedbackController !== null && typeof root.feedbackController.showToast === "function")
            root.feedbackController.showToast(record, context);
    }
    function slider(sliderId: string): var {
        if (sliderId === "volume")
            return root.volume;
        if (sliderId === "brightness")
            return root.brightness;
        return null;
    }
}
