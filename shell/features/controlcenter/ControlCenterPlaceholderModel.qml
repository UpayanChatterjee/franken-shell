import QtQuick

QtObject {
    id: root

    readonly property bool audioAvailable: root.audioController === null ? true : root.audioController.available === true
    property var audioController: null
    readonly property string audioDefaultOutputName: root.audioController === null ? qsTr("Fixture speakers") : String(root.audioController?.defaultOutput?.description ?? root.audioController?.defaultOutput?.name ?? "")
    readonly property int audioPlaybackStreamCount: root.audioController?.playbackStreams?.length ?? 0
    readonly property QtObject bluetooth: QtObject {
        readonly property bool active: true
        readonly property bool available: true
        readonly property bool busy: true
        readonly property bool canOpenDetails: true
        readonly property bool canToggle: true
        readonly property bool enabled: false
        readonly property string error: ""
        readonly property string icon: "B"
        readonly property string label: qsTr("Bluetooth")
        readonly property string secondaryText: qsTr("Updating…")
    }
    readonly property QtObject brightness: QtObject {
        readonly property bool available: root.brightnessAvailable
        readonly property bool enabled: true
        readonly property string icon: "☀"
        readonly property string label: qsTr("Brightness")
        readonly property real value: 0.64
    }
    property bool brightnessAvailable: true
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
        readonly property bool active: false
        readonly property bool available: false
        readonly property bool busy: false
        readonly property bool canOpenDetails: true
        readonly property bool canToggle: true
        readonly property bool enabled: false
        readonly property string error: ""
        readonly property string icon: "W"
        readonly property string label: qsTr("Wi-Fi")
        readonly property string secondaryText: qsTr("Unavailable")
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
    function requestSliderStep(sliderId: string, step: int, source: string): bool {
        void source;
        if (sliderId !== "volume" || !root.audioAvailable || step === 0)
            return false;
        root.audioController.queueVolumeSteps(step);
        return true;
    }
    function slider(sliderId: string): var {
        if (sliderId === "volume")
            return root.volume;
        if (sliderId === "brightness")
            return root.brightness;
        return null;
    }
}
