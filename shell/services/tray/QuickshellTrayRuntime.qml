pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.SystemTray as TrayNative

Scope {
    id: root

    // The pinned SystemTray API exposes no watcher/host health property. Loading
    // this runtime is itself the explicit ownership boundary.
    readonly property bool connected: true
    readonly property bool ownershipClaimed: true

    signal actionFailed(string errorCode)
    signal connectionChanged(bool connected)
    signal menuClosed(string runtimeId)
    signal menuOpened(string runtimeId)
    signal stateChanged

    function activate(runtimeId: string): var {
        return root.itemAction("ACTIVATE", runtimeId, item => item.activate());
    }
    function asArray(value): var {
        if (Array.isArray(value))
            return value;
        if (value?.values !== undefined)
            return value.values;
        if (typeof value?.toArray === "function")
            return value.toArray();
        return [];
    }
    function categoryName(value): string {
        switch (value) {
        case TrayNative.Category.Hardware:
            return "hardware";
        case TrayNative.Category.SystemServices:
            return "systemServices";
        case TrayNative.Category.Communications:
            return "communications";
        default:
            return "applicationStatus";
        }
    }
    function closeMenu(): var {
        if (!nativeMenu.visible)
            return root.result(false, "TRAY_MENU_UNAVAILABLE");
        nativeMenu.close();
        return root.result(true, "");
    }
    function findItem(runtimeId: string): var {
        const record = state.identities.find(candidate => candidate.runtimeId === runtimeId);
        return record?.item ?? null;
    }
    function itemAction(kind: string, runtimeId: string, action): var {
        const item = root.findItem(runtimeId);
        if (item === null)
            return root.result(false, "TRAY_ITEM_UNAVAILABLE");
        try {
            action(item);
            return root.result(true, "");
        } catch (error) {
            return root.result(false, "TRAY_" + kind + "_FAILED");
        }
    }
    function itemRecord(item): var {
        return Object.freeze({
            "runtimeId": root.runtimeIdFor(item),
            "serviceId": String(item.id ?? ""),
            "id": String(item.id ?? ""),
            "title": String(item.title ?? ""),
            "status": root.statusName(item.status),
            "category": root.categoryName(item.category),
            "icon": String(item.icon ?? ""),
            "tooltipTitle": String(item.tooltipTitle ?? ""),
            "tooltipDescription": String(item.tooltipDescription ?? ""),
            "hasMenu": item.hasMenu === true,
            "onlyMenu": item.onlyMenu === true
        });
    }
    function openMenu(runtimeId: string, anchorItem): var {
        const item = root.findItem(runtimeId);
        if (item === null)
            return root.result(false, "TRAY_ITEM_UNAVAILABLE");
        if (item.hasMenu !== true || item.menu === null)
            return root.result(false, "TRAY_MENU_UNAVAILABLE");
        if (anchorItem === null || anchorItem === undefined)
            return root.result(false, "TRAY_MENU_ANCHOR_UNAVAILABLE");
        try {
            if (nativeMenu.visible)
                nativeMenu.close();
            nativeMenu.anchor.item = anchorItem;
            nativeMenu.menu = item.menu;
            state.activeMenuRuntimeId = runtimeId;
            nativeMenu.open();
            return root.result(true, "");
        } catch (error) {
            state.activeMenuRuntimeId = "";
            return root.result(false, "TRAY_MENU_OPEN_FAILED");
        }
    }
    function requestRefresh() {
        state.sequence += 1;
        root.stateChanged();
    }
    function result(accepted: bool, errorCode: string): var {
        return Object.freeze({
            "accepted": accepted,
            "errorCode": errorCode
        });
    }
    function runtimeIdFor(item): string {
        const existing = state.identities.find(candidate => candidate.item === item);
        if (existing !== undefined)
            return existing.runtimeId;
        state.nextIdentity += 1;
        const runtimeId = "tray-native-" + state.nextIdentity;
        state.identities.push(Object.freeze({
            "item": item,
            "runtimeId": runtimeId
        }));
        return runtimeId;
    }
    function scheduleChanged() {
        modelChanged.restart();
    }
    function scroll(runtimeId: string, delta: int, horizontal: bool): var {
        return root.itemAction("SCROLL", runtimeId, item => item.scroll(delta, horizontal));
    }
    function secondaryActivate(runtimeId: string): var {
        return root.itemAction("SECONDARY_ACTIVATE", runtimeId, item => item.secondaryActivate());
    }
    function snapshot(): var {
        const items = [];
        for (const item of root.asArray(TrayNative.SystemTray.items))
            items.push(root.itemRecord(item));
        return Object.freeze({
            "sequence": state.sequence,
            "items": Object.freeze(items)
        });
    }
    function statusName(value): string {
        switch (value) {
        case TrayNative.Status.Passive:
            return "passive";
        case TrayNative.Status.NeedsAttention:
            return "needsAttention";
        default:
            return "active";
        }
    }

    Component.onCompleted: {
        root.connectionChanged(true);
        Qt.callLater(root.requestRefresh);
    }

    QtObject {
        id: state

        property string activeMenuRuntimeId: ""
        property var identities: []
        property int nextIdentity: 0
        property int sequence: 0
    }
    Timer {
        id: modelChanged

        interval: 0

        onTriggered: root.requestRefresh()
    }
    QsMenuAnchor {
        id: nativeMenu

        onClosed: {
            const runtimeId = state.activeMenuRuntimeId;
            state.activeMenuRuntimeId = "";
            if (runtimeId.length > 0)
                root.menuClosed(runtimeId);
        }
        onOpened: {
            if (state.activeMenuRuntimeId.length > 0)
                root.menuOpened(state.activeMenuRuntimeId);
        }
    }
    Connections {
        function onValuesChanged() {
            root.scheduleChanged();
        }

        target: TrayNative.SystemTray.items
    }
    Instantiator {
        model: TrayNative.SystemTray.items

        delegate: Scope {
            id: itemObserver

            required property var modelData

            Connections {
                function onCategoryChanged() {
                    root.scheduleChanged();
                }
                function onHasMenuChanged() {
                    root.scheduleChanged();
                }
                function onIconChanged() {
                    root.scheduleChanged();
                }
                function onIdChanged() {
                    root.scheduleChanged();
                }
                function onOnlyMenuChanged() {
                    root.scheduleChanged();
                }
                function onStatusChanged() {
                    root.scheduleChanged();
                }
                function onTitleChanged() {
                    root.scheduleChanged();
                }
                function onTooltipDescriptionChanged() {
                    root.scheduleChanged();
                }
                function onTooltipTitleChanged() {
                    root.scheduleChanged();
                }

                ignoreUnknownSignals: true
                target: itemObserver.modelData
            }
        }
    }
}
