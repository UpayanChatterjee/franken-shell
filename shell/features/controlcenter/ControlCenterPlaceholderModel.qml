import QtQuick

QtObject {
    id: root

    readonly property bool audioAvailable: root.audioController === null ? true : root.audioController.available === true
    property var audioController: null
    readonly property string audioDefaultOutputName: root.audioController === null ? qsTr("Fixture speakers") : String(root.audioController?.defaultOutput?.description ?? root.audioController?.defaultOutput?.name ?? "")
    readonly property int audioPlaybackStreamCount: root.audioController?.playbackStreams?.length ?? 0
    readonly property QtObject bluetooth: QtObject {
        readonly property bool active: root.bluetoothController === null ? true : root.bluetoothController.powered === true
        readonly property bool available: root.bluetoothController === null ? true : root.bluetoothController.available === true
        readonly property bool busy: root.bluetoothController === null ? true : root.bluetoothController.operationTasks?.some(task => task.state === "pending" || task.state === "awaitingInput") === true
        readonly property bool canOpenDetails: true
        readonly property bool canToggle: root.bluetoothController === null ? true : root.bluetoothController.available === true
        readonly property bool enabled: root.bluetoothController === null ? false : root.bluetoothController.available === true
        readonly property string error: root.bluetoothController?.lastError ?? ""
        readonly property string icon: "B"
        readonly property string label: qsTr("Bluetooth")
        readonly property string secondaryText: root.bluetoothController?.quickSummary ?? qsTr("Updating…")
    }
    property var bluetoothController: null
    readonly property QtObject bluetoothPage: QtObject {
        readonly property int availableDeviceCount: root.bluetoothController?.availableDevices?.length ?? 0
        readonly property int connectedDeviceCount: root.bluetoothController?.connectedDevices?.length ?? 0
        readonly property string discoveryState: root.bluetoothController?.discoveryState ?? "idle"
        readonly property int pairedDeviceCount: root.bluetoothController?.pairedDevices?.length ?? 0
        readonly property bool pairingPromptActive: root.bluetoothController?.pairingRequest?.active === true
        readonly property bool powered: root.bluetoothController?.powered === true
        readonly property string status: root.bluetoothController?.status ?? "unavailable"
    }
    readonly property QtObject brightness: QtObject {
        readonly property bool available: root.brightnessAvailable
        readonly property bool enabled: true
        readonly property string icon: "☀"
        readonly property string label: qsTr("Brightness")
        readonly property real value: root.brightnessController?.value ?? 0.64
    }
    readonly property bool brightnessAvailable: root.brightnessController === null ? root.fixtureBrightnessAvailable : root.brightnessController.visible === true
    property var brightnessController: null
    readonly property QtObject doNotDisturb: QtObject {
        readonly property bool active: true
        readonly property bool available: true
        readonly property bool busy: false
        readonly property bool canOpenDetails: false
        readonly property bool canToggle: true
        readonly property bool enabled: true
        readonly property string error: ""
        readonly property string icon: "D"
        readonly property string label: qsTr("Do Not Disturb")
        readonly property string secondaryText: qsTr("On")
    }
    property bool fixtureBrightnessAvailable: true
    readonly property QtObject idleInhibitor: QtObject {
        readonly property bool active: false
        readonly property bool available: true
        readonly property bool busy: false
        readonly property bool canOpenDetails: false
        readonly property bool canToggle: true
        readonly property bool enabled: true
        readonly property string error: ""
        readonly property string icon: "I"
        readonly property string label: qsTr("Keep awake")
        readonly property string secondaryText: qsTr("Off")
    }
    property var networkController: null
    readonly property QtObject networkPage: QtObject {
        readonly property var activeConnection: root.networkController?.activeConnection ?? null
        readonly property int ethernetDeviceCount: root.networkController?.ethernetDevices?.length ?? 0
        readonly property int savedNetworkCount: root.networkController?.savedNetworks?.length ?? 0
        readonly property string scanState: root.networkController?.scanState ?? "idle"
        readonly property string status: root.networkController?.status ?? "unavailable"
        readonly property int visibleNetworkCount: root.networkController?.visibleNetworks?.length ?? 0
    }
    readonly property QtObject nightLight: QtObject {
        readonly property bool active: false
        readonly property bool available: true
        readonly property bool busy: false
        readonly property bool canOpenDetails: false
        readonly property bool canToggle: true
        readonly property bool enabled: true
        readonly property string error: qsTr("Fixture failure")
        readonly property string icon: "N"
        readonly property string label: qsTr("Night Light")
        readonly property string secondaryText: qsTr("Needs attention")
    }
    readonly property int quickControlCount: 5
    readonly property QtObject volume: QtObject {
        readonly property bool available: root.audioAvailable
        readonly property bool enabled: root.audioAvailable && root.audioController?.stale !== true
        readonly property string icon: root.audioController?.outputCategory === "muted" ? "M" : "V"
        readonly property string label: qsTr("Volume")
        readonly property real value: root.audioController?.masterVolume ?? 0.42
    }
    readonly property QtObject wifi: QtObject {
        readonly property bool active: root.networkController?.wifiEnabled === true
        readonly property bool available: root.networkController?.available === true
        readonly property bool busy: root.networkController?.operationTasks?.some(task => task.state === "pending" && task.kind === "wifi") === true
        readonly property bool canOpenDetails: true
        readonly property bool canToggle: root.networkController?.available === true
        readonly property bool enabled: root.networkController?.available === true
        readonly property string error: root.networkController?.lastError ?? ""
        readonly property string icon: "W"
        readonly property string label: qsTr("Wi-Fi")
        readonly property string secondaryText: root.networkController?.quickSummary ?? qsTr("Unavailable")
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
    function requestQuickControlAction(controlId: string, action: string, source: string): bool {
        void source;
        if (controlId === "wifi" && root.networkController !== null) {
            if (action === "details")
                return true;
            if (action === "toggle")
                return root.networkController.toggleWifi().accepted === true;
        }
        if (controlId === "bluetooth" && root.bluetoothController !== null) {
            if (action === "details")
                return true;
            if (action === "toggle")
                return root.bluetoothController.togglePowered().accepted === true;
        }
        return false;
    }
    function requestSliderStep(sliderId: string, step: int, source: string): bool {
        void source;
        if (step === 0)
            return false;
        if (sliderId === "volume" && root.audioAvailable) {
            root.audioController.queueVolumeSteps(step);
            return true;
        }
        if (sliderId === "brightness" && root.brightnessAvailable) {
            root.brightnessController.adjustBySteps(step);
            return true;
        }
        return false;
    }
    function slider(sliderId: string): var {
        if (sliderId === "volume")
            return root.volume;
        if (sliderId === "brightness")
            return root.brightness;
        return null;
    }
}
