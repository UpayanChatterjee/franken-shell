import QtQuick
import Quickshell

Scope {
    id: root

    readonly property bool available: state.connectionState === "ready"
    readonly property string connectionState: state.connectionState
    readonly property bool hasAttention: root.items.some(item => item.status === "needsAttention")
    readonly property var items: state.items
    readonly property string lastError: state.lastError
    readonly property var menuState: state.menuState
    readonly property bool ownershipClaimed: root.runtime?.ownershipClaimed === true
    required property var runtime
    readonly property bool stale: state.stale

    signal stateChanged

    function activate(itemId: string): var {
        return root.forward("activate", itemId, actionId => root.runtime.activate(actionId));
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
    function closeMenu(): var {
        if (!state.menuState.active)
            return root.result(false, "TRAY_MENU_UNAVAILABLE");
        const response = root.runtime.closeMenu();
        if (response?.accepted !== true) {
            state.lastError = String(response?.errorCode ?? "TRAY_MENU_CLOSE_FAILED");
            root.stateChanged();
            return root.result(false, state.lastError);
        }
        state.menuState = root.emptyMenuState();
        root.stateChanged();
        return root.result(true, "");
    }
    function diagnosticsSummary(): var {
        return Object.freeze({
            "available": root.available,
            "connectionState": root.connectionState,
            "stale": root.stale,
            "ownershipClaimed": root.ownershipClaimed,
            "itemCount": root.items.length,
            "attentionItemCount": root.items.filter(item => item.status === "needsAttention").length,
            "menuActive": root.menuState.active,
            "lastError": root.lastError
        });
    }
    function emptyMenuState(): var {
        return Object.freeze({
            "active": false,
            "itemId": ""
        });
    }
    function findItem(itemId: string): var {
        return root.items.find(item => item.stableId === itemId) ?? null;
    }
    function forward(kind: string, itemId: string, action): var {
        if (!root.available)
            return root.result(false, "TRAY_BACKEND_DISCONNECTED");
        const item = root.findItem(itemId);
        if (item === null)
            return root.result(false, "TRAY_ITEM_UNAVAILABLE");
        const actionId = state.actionIds[itemId];
        if (actionId === undefined)
            return root.result(false, "TRAY_ITEM_UNAVAILABLE");
        const response = action(actionId);
        if (response?.accepted !== true) {
            state.lastError = String(response?.errorCode ?? ("TRAY_" + kind.toUpperCase() + "_FAILED"));
            root.stateChanged();
            return root.result(false, state.lastError);
        }
        state.lastError = "";
        root.stateChanged();
        return root.result(true, "");
    }
    function handleConnectionChanged(connected: bool) {
        if (!connected) {
            state.connectionState = state.hasSnapshot ? "reconnecting" : "unavailable";
            state.stale = state.hasSnapshot;
            state.menuState = root.emptyMenuState();
            root.stateChanged();
            return;
        }
        state.connectionState = "starting";
        state.stale = state.hasSnapshot;
        root.runtime.requestRefresh();
    }
    function handleMenuClosed(actionId: string) {
        if (!state.menuState.active)
            return;
        const itemId = Object.keys(state.actionIds).find(candidate => state.actionIds[candidate] === actionId) ?? "";
        if (itemId.length === 0 || itemId === state.menuState.itemId) {
            state.menuState = root.emptyMenuState();
            root.stateChanged();
        }
    }
    function handleMenuOpened(actionId: string) {
        const itemId = Object.keys(state.actionIds).find(candidate => state.actionIds[candidate] === actionId) ?? "";
        if (itemId.length === 0)
            return;
        state.menuState = Object.freeze({
            "active": true,
            "itemId": itemId
        });
        root.stateChanged();
    }
    function normalizeCategory(value): string {
        const candidate = String(value ?? "applicationStatus");
        return ["hardware", "systemServices", "applicationStatus", "communications"].indexOf(candidate) >= 0 ? candidate : "applicationStatus";
    }
    function normalizeItem(candidate, stableId: string): var {
        const title = root.safeText(candidate?.title, 160);
        const tooltipTitle = root.safeText(candidate?.tooltipTitle, 240);
        const tooltipDescription = root.safeText(candidate?.tooltipDescription, 500);
        const onlyMenu = candidate?.onlyMenu === true;
        const hasMenu = candidate?.hasMenu === true;
        return Object.freeze({
            "stableId": stableId,
            "serviceId": root.safeText(candidate?.serviceId ?? candidate?.id, 240),
            "title": title.length > 0 ? title : tooltipTitle.length > 0 ? tooltipTitle : qsTr("Unnamed tray item"),
            "status": root.normalizeStatus(candidate?.status),
            "category": root.normalizeCategory(candidate?.category),
            "icon": root.safeIcon(candidate?.icon),
            "tooltipTitle": tooltipTitle,
            "tooltipDescription": tooltipDescription,
            "menuAvailable": hasMenu,
            "onlyMenu": onlyMenu,
            "availableActions": Object.freeze({
                "activate": !onlyMenu,
                "menu": hasMenu,
                "secondaryActivate": true,
                "scroll": true
            })
        });
    }
    function normalizeStatus(value): string {
        const candidate = String(value ?? "active");
        return ["passive", "active", "needsAttention"].indexOf(candidate) >= 0 ? candidate : "active";
    }
    function openMenu(itemId: string, anchorItem): var {
        if (!root.available)
            return root.result(false, "TRAY_BACKEND_DISCONNECTED");
        const item = root.findItem(itemId);
        if (item === null)
            return root.result(false, "TRAY_ITEM_UNAVAILABLE");
        if (!item.menuAvailable)
            return root.result(false, "TRAY_MENU_UNAVAILABLE");
        const actionId = state.actionIds[itemId];
        const response = root.runtime.openMenu(actionId, anchorItem);
        if (response?.accepted !== true) {
            state.lastError = String(response?.errorCode ?? "TRAY_MENU_OPEN_FAILED");
            root.stateChanged();
            return root.result(false, state.lastError);
        }
        state.menuState = Object.freeze({
            "active": true,
            "itemId": itemId
        });
        state.lastError = "";
        root.stateChanged();
        return root.result(true, "");
    }
    function reconcile() {
        if (!root.runtime?.connected)
            return;
        let snapshot;
        try {
            snapshot = root.runtime.snapshot();
        } catch (error) {
            state.connectionState = "degraded";
            state.lastError = "TRAY_SNAPSHOT_FAILED";
            state.stale = state.hasSnapshot;
            root.stateChanged();
            return;
        }
        const sequence = Number(snapshot?.sequence ?? 0);
        if (sequence < state.lastSequence)
            return;
        const records = [];
        const actionIds = {};
        const usedIds = {};
        for (const candidate of root.asArray(snapshot?.items)) {
            const actionId = String(candidate?.runtimeId ?? "");
            if (actionId.length === 0)
                continue;
            const stableId = root.stableIdFor(candidate, usedIds);
            usedIds[stableId] = true;
            actionIds[stableId] = actionId;
            records.push(root.normalizeItem(candidate, stableId));
        }
        for (const item of records) {
            if (state.order.indexOf(item.stableId) < 0)
                state.order.push(item.stableId);
        }
        records.sort((left, right) => state.order.indexOf(left.stableId) - state.order.indexOf(right.stableId));
        state.actionIds = actionIds;
        state.items = Object.freeze(records);
        state.hasSnapshot = true;
        state.lastSequence = sequence;
        state.connectionState = "ready";
        state.stale = false;
        if (state.menuState.active && root.findItem(state.menuState.itemId) === null) {
            root.runtime.closeMenu();
            state.menuState = root.emptyMenuState();
        }
        root.stateChanged();
    }
    function result(accepted: bool, errorCode: string): var {
        return Object.freeze({
            "accepted": accepted,
            "errorCode": errorCode
        });
    }
    function safeIcon(value): string {
        const icon = String(value ?? "");
        if (icon.length > 2048 || icon.indexOf("\n") >= 0 || icon.indexOf("\r") >= 0)
            return "";
        return icon;
    }
    function safeText(value, maximumLength: int): string {
        return String(value ?? "").replace(/[\u0000-\u001f\u007f]/g, " ").replace(/\s+/g, " ").trim().slice(0, maximumLength);
    }
    function scroll(itemId: string, delta: int, horizontal: bool): var {
        if (delta === 0)
            return root.result(false, "TRAY_SCROLL_EMPTY");
        return root.forward("scroll", itemId, actionId => root.runtime.scroll(actionId, delta, horizontal));
    }
    function secondaryActivate(itemId: string): var {
        return root.forward("secondary_activate", itemId, actionId => root.runtime.secondaryActivate(actionId));
    }
    function stableIdFor(candidate, usedIds): string {
        const actionId = String(candidate?.runtimeId ?? "");
        const existing = state.identities[actionId];
        if (existing !== undefined && usedIds[existing] !== true)
            return existing;
        const rawId = root.safeText(candidate?.id, 160).replace(/[^A-Za-z0-9._:-]/g, "_");
        const base = rawId.length > 0 ? "tray:" + rawId : "tray:session-" + (++state.fallbackId);
        let stableId = base;
        let suffix = 2;
        while (usedIds[stableId] === true) {
            stableId = base + "#" + suffix;
            suffix += 1;
        }
        state.identities[actionId] = stableId;
        return stableId;
    }

    Component.onCompleted: {
        if (root.runtime?.connected)
            root.handleConnectionChanged(true);
    }
    onRuntimeChanged: root.handleConnectionChanged(root.runtime?.connected === true)

    QtObject {
        id: state

        property var actionIds: ({})
        property string connectionState: "unavailable"
        property int fallbackId: 0
        property bool hasSnapshot: false
        property var identities: ({})
        property var items: Object.freeze([])
        property string lastError: ""
        property int lastSequence: -1
        property var menuState: root.emptyMenuState()
        property var order: []
        property bool stale: false
    }
    Connections {
        function onActionFailed(errorCode) {
            state.lastError = String(errorCode || "TRAY_ACTION_FAILED");
            root.stateChanged();
        }
        function onConnectionChanged(connected) {
            root.handleConnectionChanged(connected);
        }
        function onMenuClosed(actionId) {
            root.handleMenuClosed(actionId);
        }
        function onMenuOpened(actionId) {
            root.handleMenuOpened(actionId);
        }
        function onStateChanged() {
            root.reconcile();
        }

        ignoreUnknownSignals: true
        target: root.runtime
    }
}
