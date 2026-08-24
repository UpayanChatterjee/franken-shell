import QtQuick
import Quickshell

Scope {
    id: root

    required property var adapter
    readonly property bool available: root.adapter?.available === true
    readonly property string connectionState: root.adapter?.connectionState ?? "unavailable"
    readonly property bool hasAttention: root.adapter?.hasAttention === true
    readonly property var items: root.adapter?.items ?? Object.freeze([])
    readonly property string lastError: root.adapter?.lastError ?? ""
    readonly property var menuState: root.adapter?.menuState ?? Object.freeze({
        "active": false,
        "itemId": ""
    })
    readonly property bool visible: root.available && root.items.length > 0

    function accessibleName(): string {
        return root.hasAttention ? qsTr("System tray, attention requested") : qsTr("System tray");
    }
    function activate(itemId: string, anchorItem): var {
        const item = root.items.find(candidate => candidate.stableId === itemId);
        if (item === undefined)
            return root.result(false, "TRAY_ITEM_UNAVAILABLE");
        return item.onlyMenu ? root.openMenu(itemId, anchorItem) : root.adapter.activate(itemId);
    }
    function closeMenu(): var {
        return root.adapter.closeMenu();
    }
    function openMenu(itemId: string, anchorItem): var {
        return root.adapter.openMenu(itemId, anchorItem);
    }
    function result(accepted: bool, errorCode: string): var {
        return Object.freeze({
            "accepted": accepted,
            "errorCode": errorCode
        });
    }
    function scroll(itemId: string, delta: int, horizontal: bool): var {
        return root.adapter.scroll(itemId, delta, horizontal);
    }
    function secondaryActivate(itemId: string): var {
        return root.adapter.secondaryActivate(itemId);
    }
    function tooltip(): string {
        return root.hasAttention ? qsTr("System tray · an item needs attention") : qsTr("System tray");
    }
}
