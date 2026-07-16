import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root

    required property int slotIndex
    required property var registry
    readonly property bool occupied: root._requestId.length > 0
    readonly property string requestId: root._requestId

    property string _requestId: ""
    property bool _started: false
    property string _suppressionReason: ""
    property bool _terminalRequested: false

    function start(request) {
        root._requestId = request.requestId;
        root._started = false;
        root._suppressionReason = "";
        root._terminalRequested = false;
        process.command = [request.resolvedExecutable].concat(request.arguments);
        process.running = true;
        process.command = [];
    }

    function cancel(reason: string) {
        if (!root.occupied || root._terminalRequested)
            return;

        root._terminalRequested = true;
        root._suppressionReason = reason;
        processTimeout.stop();
        if (reason === "cancelled") {
            if (root._started) {
                forceKillTimer.restart();
                process.running = false;
            }
        } else {
            process.signal(9);
        }
    }

    function _clear() {
        processTimeout.stop();
        forceKillTimer.stop();
        process.command = [];
        root._requestId = "";
        root._started = false;
        root._suppressionReason = "";
        root._terminalRequested = false;
    }

    Timer {
        id: processTimeout

        repeat: false
        onTriggered: {
            if (!root.occupied || root._terminalRequested)
                return;

            root.registry._slotTimedOut(root.slotIndex, root._requestId);
            root.cancel("timedOut");
        }
    }

    Timer {
        id: forceKillTimer

        interval: 250
        repeat: false
        onTriggered: {
            if (root.occupied && process.running)
                process.signal(9);
        }
    }

    Process {
        id: process

        stdout: SplitParser {
            splitMarker: ""
        }
        stderr: SplitParser {
            splitMarker: ""
        }

        onStarted: {
            if (!root.occupied)
                return;

            root._started = true;
            if (root._terminalRequested) {
                forceKillTimer.restart();
                process.running = false;
                return;
            }
            root.registry._slotStarted(root.slotIndex, root._requestId);
            const timeoutMs = root.registry._timeoutForRequest(root._requestId);
            if (timeoutMs > 0) {
                processTimeout.interval = timeoutMs;
                processTimeout.restart();
            }
        }
        onRunningChanged: {
            if (!root.occupied || process.running || root._started)
                return;

            const requestId = root._requestId;
            const terminalRequested = root._terminalRequested;
            root._clear();
            if (terminalRequested)
                root.registry._slotStoppedWithoutExit(root.slotIndex, requestId);
            else
                root.registry._slotFailedToStart(root.slotIndex, requestId);
        }
        onExited: (exitCode, exitStatus) => { // qmllint disable signal-handler-parameters
            if (!root.occupied)
                return;

            processTimeout.stop();
            forceKillTimer.stop();
            const requestId = root._requestId;
            const suppressionReason = root._suppressionReason;
            root._clear();
            root.registry._slotExited(
                root.slotIndex,
                requestId,
                exitCode,
                Number(exitStatus),
                suppressionReason
            );
        }
    }
}
