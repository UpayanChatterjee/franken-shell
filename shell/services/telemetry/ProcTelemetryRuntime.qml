import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root

    required property var commandRegistry
    readonly property bool connected: true
    readonly property bool detailActive: state.detailVisible
    property int detailIntervalMs: 1000
    readonly property int pollIntervalMs: root.detailActive ? root.detailIntervalMs : root.summaryIntervalMs
    property int storageIntervalMs: 30000
    property int summaryIntervalMs: 2000

    signal connectionChanged(bool connected)
    signal stateChanged

    function acceptFile(kind: string, text: string, errorCode: string) {
        if (!state.inFlight || state.pending[kind] !== true)
            return;
        state.pending = Object.assign({}, state.pending, {
            [kind]: false
        });
        state.contents = Object.assign({}, state.contents, {
            [kind]: text
        });
        state.errors = Object.assign({}, state.errors, {
            [kind]: errorCode
        });
        if (kind === "storage" && errorCode !== "STORAGE_COMMAND_UNAVAILABLE")
            state.lastStorageTimestampMs = Date.now();
        root.completeIfReady();
    }
    function completeIfReady() {
        if (!state.inFlight || Object.values(state.pending).some(value => value === true))
            return;
        state.inFlight = false;
        state.sequence += 1;
        state.timestampMs = Date.now();
        root.stateChanged();
    }
    function requestRefresh() {
        if (state.inFlight)
            return;
        const previousStorage = String(state.contents.storage ?? "");
        const previousStorageError = String(state.errors.storage ?? "");
        const sampleStorage = state.lastStorageTimestampMs <= 0 || Date.now() - state.lastStorageTimestampMs >= root.storageIntervalMs;
        state.inFlight = true;
        state.pending = ({
                "network": true,
                "memory": true,
                "cpu": true,
                "storage": sampleStorage
            });
        state.contents = ({
                "network": "",
                "memory": "",
                "cpu": "",
                "storage": previousStorage
            });
        state.errors = ({
                "network": "",
                "memory": "",
                "cpu": "",
                "storage": previousStorageError
            });

        networkFile.reload();
        memoryFile.reload();
        cpuFile.reload();

        if (!sampleStorage) {
            root.completeIfReady();
            return;
        }
        if (root.commandRegistry?.commandAvailable("resource.storage-root") !== true) {
            root.acceptFile("storage", "", "STORAGE_COMMAND_UNAVAILABLE");
            return;
        }
        const request = root.commandRegistry.execute("resource.storage-root");
        if (["queued", "starting", "running"].indexOf(request.state) < 0) {
            root.acceptFile("storage", "", "STORAGE_SAMPLE_FAILED");
            return;
        }
        state.storageRequestId = request.requestId;
    }
    function setDetailVisible(value: bool) {
        const next = value === true;
        if (state.detailVisible === next)
            return;
        state.detailVisible = next;
        pollTimer.restart();
        Qt.callLater(root.requestRefresh);
    }
    function snapshot(): var {
        return Object.freeze({
            "sequence": state.sequence,
            "timestampMs": state.timestampMs,
            "networkText": state.contents.network,
            "memoryText": state.contents.memory,
            "cpuText": state.contents.cpu,
            "storageText": state.contents.storage,
            "errors": Object.freeze(Object.assign({}, state.errors)),
            "pollIntervalMs": root.pollIntervalMs,
            "detailActive": root.detailActive
        });
    }

    Component.onCompleted: Qt.callLater(root.requestRefresh)

    QtObject {
        id: state

        property var contents: ({})
        property bool detailVisible: false
        property var errors: ({})
        property bool inFlight: false
        property double lastStorageTimestampMs: 0
        property var pending: ({})
        property int sequence: 0
        property string storageRequestId: ""
        property double timestampMs: 0
    }
    FileView {
        id: networkFile

        path: "/proc/net/dev"
        preload: true
        printErrors: false

        onLoadFailed: error => root.acceptFile("network", "", "NETWORK_READ_FAILED_" + error)
        onLoaded: root.acceptFile("network", text(), "")
    }
    FileView {
        id: memoryFile

        path: "/proc/meminfo"
        preload: true
        printErrors: false

        onLoadFailed: error => root.acceptFile("memory", "", "MEMORY_READ_FAILED_" + error)
        onLoaded: root.acceptFile("memory", text(), "")
    }
    FileView {
        id: cpuFile

        path: "/proc/stat"
        preload: true
        printErrors: false

        onLoadFailed: error => root.acceptFile("cpu", "", "CPU_READ_FAILED_" + error)
        onLoaded: root.acceptFile("cpu", text(), "")
    }
    Timer {
        id: pollTimer

        interval: Math.max(250, root.pollIntervalMs)
        repeat: true
        running: true

        onTriggered: root.requestRefresh()
    }
    Connections {
        function onRequestFinished(request) {
            if (request.requestId !== state.storageRequestId)
                return;
            state.storageRequestId = "";
            const accepted = request.state === "completed";
            root.acceptFile("storage", accepted ? request.stdout : "", accepted ? "" : "STORAGE_SAMPLE_FAILED");
        }

        target: root.commandRegistry
    }
}
