import "../../services/hyprland" as HyprlandServices
import QtQuick
import Quickshell

ShellRoot {
    id: root

    property string phase: "awaitingInitialConnection"
    property int sequenceBeforeReconnect: -1

    function beginWhenConnected() {
        if (!runtime.connected)
            return;
        root.sequenceBeforeReconnect = Number(runtime.snapshot().sequence ?? -1);
        root.phase = "awaitingDisconnect";
        runtime.requestReconnect();
    }
    function fail(message: string) {
        console.error("FAIL hyprland-live-reconnect:", message);
        Qt.exit(1);
    }

    Component.onCompleted: Qt.callLater(root.beginWhenConnected)

    HyprlandServices.QuickshellHyprlandRuntime {
        id: runtime
    }
    Timer {
        interval: 5000
        running: true

        onTriggered: root.fail("event stream did not disconnect and reconnect within the bounded acceptance window")
    }
    Timer {
        interval: 50
        running: true

        onTriggered: root.beginWhenConnected()
    }
    Connections {
        function onConnectionChanged(connected) {
            if (!connected && root.phase === "awaitingDisconnect") {
                root.phase = "awaitingReconnect";
                return;
            }
            if (!connected || root.phase !== "awaitingReconnect")
                return;
            runtime.requestRefresh();
            verification.restart();
        }

        target: runtime
    }
    Timer {
        id: verification

        interval: 100

        onTriggered: {
            const snapshot = runtime.snapshot();
            if (!runtime.connected || Number(snapshot.sequence ?? -1) <= root.sequenceBeforeReconnect) {
                root.fail("reconnected event stream did not complete an authoritative model refresh (before=" + root.sequenceBeforeReconnect + ", after=" + Number(snapshot.sequence ?? -1) + ", connected=" + runtime.connected + ")");
                return;
            }
            console.info("PASS hyprland-live-reconnect: real event socket disconnected, reconnected, and resynchronized without restarting the shell");
            Qt.exit(0);
        }
    }
}
