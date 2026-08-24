import QtQuick
import Quickshell

Scope {
    id: root

    property date now: new Date()

    function refresh() {
        root.now = new Date();
        minuteTimer.interval = Math.max(250, 60000 - Date.now() % 60000 + 25);
        minuteTimer.restart();
    }

    Component.onCompleted: root.refresh()

    Timer {
        id: minuteTimer

        repeat: false

        onTriggered: root.refresh()
    }
}
