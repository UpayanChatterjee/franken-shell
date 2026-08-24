import QtQuick
import Quickshell

Scope {
    id: root

    readonly property bool connected: false
    readonly property bool ownershipClaimed: false

    signal actionFailed(string errorCode)
    signal connectionChanged(bool connected)
    signal menuClosed(string runtimeId)
    signal menuOpened(string runtimeId)
    signal stateChanged

    function activate(runtimeId: string): var {
        void runtimeId;
        return root.result();
    }
    function closeMenu(): var {
        return root.result();
    }
    function openMenu(runtimeId: string, anchorItem): var {
        void runtimeId;
        void anchorItem;
        return root.result();
    }
    function requestRefresh() {
    }
    function result(): var {
        return Object.freeze({
            "accepted": false,
            "errorCode": "TRAY_BACKEND_DISCONNECTED"
        });
    }
    function scroll(runtimeId: string, delta: int, horizontal: bool): var {
        void runtimeId;
        void delta;
        void horizontal;
        return root.result();
    }
    function secondaryActivate(runtimeId: string): var {
        void runtimeId;
        return root.result();
    }
    function snapshot(): var {
        return Object.freeze({
            "sequence": 0,
            "items": Object.freeze([])
        });
    }
}
