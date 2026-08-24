import QtQuick
import Quickshell

Scope {
    id: root

    property bool connected: false
    property string failNextError: ""
    property var items: []
    readonly property string lastAction: state.lastAction
    property bool menuOpen: false
    readonly property bool ownershipClaimed: false
    property int sequence: 1

    signal actionFailed(string errorCode)
    signal connectionChanged(bool connected)
    signal menuClosed(string runtimeId)
    signal menuOpened(string runtimeId)
    signal stateChanged

    function action(kind: string, runtimeId: string): var {
        state.lastAction = kind + ":" + runtimeId;
        if (!root.connected)
            return root.result(false, "TRAY_BACKEND_DISCONNECTED");
        if (root.failNextError.length > 0) {
            const errorCode = root.failNextError;
            root.failNextError = "";
            return root.result(false, errorCode);
        }
        return root.result(true, "");
    }
    function activate(runtimeId: string): var {
        return root.action("activate", runtimeId);
    }
    function closeMenu(): var {
        if (!root.menuOpen)
            return root.result(false, "TRAY_MENU_UNAVAILABLE");
        const runtimeId = state.activeMenuRuntimeId;
        root.menuOpen = false;
        state.activeMenuRuntimeId = "";
        root.menuClosed(runtimeId);
        return root.result(true, "");
    }
    function openMenu(runtimeId: string, anchorItem): var {
        void anchorItem;
        const response = root.action("menu", runtimeId);
        if (!response.accepted)
            return response;
        root.menuOpen = true;
        state.activeMenuRuntimeId = runtimeId;
        root.menuOpened(runtimeId);
        return response;
    }
    function requestRefresh() {
        root.stateChanged();
    }
    function result(accepted: bool, errorCode: string): var {
        return Object.freeze({
            "accepted": accepted,
            "errorCode": errorCode
        });
    }
    function scroll(runtimeId: string, delta: int, horizontal: bool): var {
        return root.action("scroll-" + delta + "-" + (horizontal ? "horizontal" : "vertical"), runtimeId);
    }
    function secondaryActivate(runtimeId: string): var {
        return root.action("secondary", runtimeId);
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
            "items": Object.freeze(Array.from(root.items))
        });
    }

    QtObject {
        id: state

        property string activeMenuRuntimeId: ""
        property string lastAction: ""
    }
}
