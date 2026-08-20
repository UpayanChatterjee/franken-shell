import QtQuick
import Quickshell

Scope {
    id: root

    property bool connected: false
    property string failNextError: ""
    property var focusedWindowRecord: null
    readonly property string lastRequest: state.lastRequest
    readonly property int refreshCount: state.refreshCount
    property int sequence: 1
    property bool usingLua: true
    property var workspaceRecords: []

    signal connectionChanged(bool connected)
    signal eventReceived(string name, string data)
    signal stateChanged

    function dispatch(request: string): var {
        state.lastRequest = request;
        if (!root.connected)
            return root.result(false, "HYPRLAND_DISCONNECTED");
        if (root.failNextError.length > 0) {
            const errorCode = root.failNextError;
            root.failNextError = "";
            return root.result(false, errorCode);
        }
        return root.result(true, "");
    }
    function emitEvent(name: string, data: string) {
        root.eventReceived(name, data);
    }
    function requestRefresh() {
        state.refreshCount += 1;
        root.stateChanged();
    }
    function result(accepted: bool, errorCode: string): var {
        return Object.freeze({
            "accepted": accepted,
            "errorCode": errorCode
        });
    }
    function setConnected(value: bool) {
        if (root.connected === value)
            return;
        root.connected = value;
        root.connectionChanged(value);
    }
    function snapshot(): var {
        return Object.freeze({
            "sequence": root.sequence,
            "workspaces": Object.freeze(Array.from(root.workspaceRecords)),
            "focusedWindow": root.focusedWindowRecord
        });
    }

    QtObject {
        id: state

        property string lastRequest: ""
        property int refreshCount: 0
    }
}
