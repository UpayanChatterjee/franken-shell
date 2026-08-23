import QtQuick
import Quickshell

Scope {
    readonly property bool connected: false

    signal connectionChanged(bool connected)
    signal stateChanged

    function requestRefresh() {
    }
    function snapshot(): var {
        return Object.freeze({
            "sequence": 0,
            "battery": null
        });
    }
}
