import "HyprlandCommandBuilder.js" as Commands
import QtQuick
import Quickshell

Scope {
    id: root

    readonly property bool available: state.connectionState === "ready"
    readonly property string connectionState: state.connectionState
    readonly property var focusedWindow: state.focusedWindow
    readonly property string lastError: state.lastError
    readonly property string lastEventName: state.lastEventName
    readonly property int malformedEventCount: state.malformedEventCount
    required property var monitorRegistry
    readonly property bool overviewAvailable: false
    readonly property bool overviewBusy: false
    readonly property string overviewLastError: "OVERVIEW_UNAVAILABLE"
    required property var runtime
    property var specialDefinitions: root.workspaceConfig?.special ?? []
    readonly property bool stale: state.stale
    readonly property int staleSnapshotCount: state.staleSnapshotCount
    property string testedVersion: ""
    readonly property int unknownEventCount: state.unknownEventCount
    property var workspaceConfig: null
    readonly property var workspaceRecords: state.workspaceRecords

    signal stateChanged

    function activateNumberedWorkspace(number: int, monitorId: string, invocationContext): var {
        void invocationContext;
        if (!root.available)
            return root.dispatchBuilt(null);
        if (root.connectorForMonitorId(monitorId).length === 0)
            return root.result(false, "HYPRLAND_UNKNOWN_MONITOR");
        return root.dispatchBuilt(Commands.activateNumbered(number, root.runtime.usingLua === true));
    }
    function activeNumberForMonitor(monitorId: string): int {
        if (!root.available)
            return -1;
        for (const workspace of state.workspaceRecords) {
            if (!workspace.special && workspace.active && workspace.monitorId === monitorId)
                return workspace.number;
        }
        return -1;
    }
    function asArray(value): var {
        if (Array.isArray(value))
            return value;
        if (typeof value?.toArray === "function")
            return value.toArray();
        return [];
    }
    function closeFocusedWindow(): var {
        return root.dispatchBuilt(Commands.closeWindow(root.focusedAddress(), root.runtime.usingLua === true));
    }
    function connectorForMonitorId(monitorId: string): string {
        for (const monitor of root.asArray(root.monitorRegistry?.monitors)) {
            if (String(monitor?.runtimeId ?? "") === monitorId)
                return String(monitor.connector ?? "");
        }
        return "";
    }
    function diagnosticsSummary(): var {
        const workspaces = root.workspaceRecords.map(workspace => Object.freeze({
                "number": workspace.number,
                "specialId": workspace.specialId,
                "connector": workspace.connector,
                "monitorId": workspace.monitorId,
                "active": workspace.active,
                "urgent": workspace.urgent,
                "hasFullscreen": workspace.hasFullscreen
            }));
        return Object.freeze({
            "available": root.available,
            "connectionState": root.connectionState,
            "stale": root.stale,
            "workspaceCount": root.workspaceRecords.length,
            "workspaces": Object.freeze(workspaces),
            "focusedWindowPresent": root.focusedWindow !== null,
            "usingLua": root.runtime?.usingLua === true,
            "testedVersion": root.testedVersion,
            "malformedEventCount": root.malformedEventCount,
            "staleSnapshotCount": root.staleSnapshotCount,
            "lastEventName": root.lastEventName,
            "unknownEventCount": root.unknownEventCount,
            "lastError": root.lastError
        });
    }
    function dispatchBuilt(command): var {
        if (!root.runtime?.connected) {
            state.lastError = "HYPRLAND_DISCONNECTED";
            return root.result(false, state.lastError);
        }
        if (!command?.accepted) {
            state.lastError = String(command?.errorCode ?? "HYPRLAND_INVALID_COMMAND");
            return root.result(false, state.lastError);
        }
        const dispatched = root.runtime.dispatch(command.request);
        const accepted = dispatched?.accepted === true;
        state.lastError = accepted ? "" : String(dispatched?.errorCode ?? "HYPRLAND_DISPATCH_FAILED");
        return root.result(accepted, state.lastError);
    }
    function focusedAddress(): string {
        return String(state.focusedWindow?.address ?? "");
    }
    function handleConnectionChanged(connected: bool) {
        if (!connected) {
            state.connectionState = "disconnected";
            state.stale = state.workspaceRecords.length > 0 || state.focusedWindow !== null;
            root.stateChanged();
            return;
        }
        state.connectionState = "resynchronizing";
        state.stale = state.workspaceRecords.length > 0 || state.focusedWindow !== null;
        root.runtime.requestRefresh();
    }
    function handleEvent(name: string, data: string) {
        void data;
        state.lastEventName = name;
        if (name.length === 0) {
            state.malformedEventCount += 1;
            root.runtime.requestRefresh();
            return;
        }
        if (root.supportsEvent(name))
            root.runtime.requestRefresh();
        else
            state.unknownEventCount += 1;
    }
    function monitorIdForConnector(connector: string): string {
        for (const monitor of root.asArray(root.monitorRegistry?.monitors)) {
            if (String(monitor?.connector ?? "") === connector)
                return String(monitor.runtimeId ?? "");
        }
        return "";
    }
    function moveFocusedWindowToNumberedWorkspace(number: int, follow: bool): var {
        return root.dispatchBuilt(Commands.moveWindowToNumbered(number, follow, root.focusedAddress(), root.runtime.usingLua === true));
    }
    function moveFocusedWindowToSpecialWorkspace(id: string, follow: bool): var {
        const definition = root.specialDefinition(id);
        if (definition === null)
            return root.result(false, "SPECIAL_WORKSPACE_UNAVAILABLE");
        return root.dispatchBuilt(Commands.moveWindowToSpecial(String(definition.hyprlandName ?? ""), follow, root.focusedAddress(), root.runtime.usingLua === true));
    }
    function normalizedFocusedWindow(candidate): var {
        if (candidate === null || candidate === undefined)
            return null;
        const fullscreenMode = Number(candidate.fullscreenMode ?? 0);
        return Object.freeze({
            "address": String(candidate.address ?? ""),
            "title": String(candidate.title ?? ""),
            "appId": String(candidate.appId ?? ""),
            "windowClass": String(candidate.windowClass ?? ""),
            "pid": Number(candidate.pid ?? -1),
            "workspaceId": Number(candidate.workspaceId ?? -1),
            "workspaceName": String(candidate.workspaceName ?? ""),
            "monitorId": root.monitorIdForConnector(String(candidate.monitorName ?? "")),
            "floating": candidate.floating === true,
            "fullscreen": fullscreenMode === 2,
            "maximized": fullscreenMode === 1,
            "mapped": candidate.mapped !== false
        });
    }
    function normalizedWorkspace(candidate): var {
        const name = String(candidate?.name ?? "");
        const special = name.startsWith("special:");
        const number = special ? -1 : Number(candidate?.id ?? name);
        return Object.freeze({
            "id": Number(candidate?.id ?? -1),
            "name": name,
            "number": Number.isInteger(number) && number > 0 ? number : -1,
            "special": special,
            "specialId": special ? root.stableSpecialId(name) : "",
            "connector": String(candidate?.monitorName ?? ""),
            "monitorId": root.monitorIdForConnector(String(candidate?.monitorName ?? "")),
            "active": candidate?.active === true,
            "focused": candidate?.focused === true,
            "urgent": candidate?.urgent === true,
            "hasFullscreen": candidate?.hasFullscreen === true
        });
    }
    function reconcile() {
        if (!root.runtime?.connected)
            return;
        let snapshot;
        try {
            snapshot = root.runtime.snapshot();
        } catch (error) {
            state.lastError = "HYPRLAND_SNAPSHOT_FAILED";
            state.connectionState = "degraded";
            state.stale = state.workspaceRecords.length > 0 || state.focusedWindow !== null;
            root.stateChanged();
            return;
        }
        const sequence = Number(snapshot?.sequence ?? 0);
        if (sequence < state.lastSequence) {
            state.staleSnapshotCount += 1;
            root.stateChanged();
            return;
        }

        const next = [];
        for (const workspace of root.asArray(snapshot?.workspaces))
            next.push(root.normalizedWorkspace(workspace));
        state.workspaceRecords = Object.freeze(next);
        state.focusedWindow = root.normalizedFocusedWindow(snapshot?.focusedWindow ?? null);
        state.lastSequence = sequence;
        state.lastError = "";
        state.stale = false;
        state.connectionState = "ready";
        root.stateChanged();
    }
    function requestOverview(monitorId: string, invocationContext): var {
        void monitorId;
        void invocationContext;
        return root.result(false, "OVERVIEW_UNAVAILABLE");
    }
    function result(accepted: bool, errorCode: string): var {
        return Object.freeze({
            "accepted": accepted,
            "errorCode": errorCode
        });
    }
    function specialDefinition(id: string): var {
        for (const definition of root.asArray(root.specialDefinitions)) {
            if (String(definition?.id ?? "") === id)
                return definition;
        }
        return null;
    }
    function specialSnapshot(monitorId: string): var {
        const visibleIds = [];
        const unavailableIds = [];
        for (const definition of root.asArray(root.specialDefinitions)) {
            if (typeof definition?.id !== "string" || typeof definition?.hyprlandName !== "string")
                unavailableIds.push(String(definition?.id ?? ""));
        }
        if (root.available) {
            for (const workspace of state.workspaceRecords) {
                if (workspace.special && workspace.active && workspace.monitorId === monitorId && workspace.specialId.length > 0)
                    visibleIds.push(workspace.specialId);
            }
        }
        return Object.freeze({
            "stateAvailable": root.available,
            "visibleIds": Object.freeze(visibleIds),
            "unavailableIds": Object.freeze(unavailableIds),
            "busyId": "",
            "lastError": state.lastError
        });
    }
    function stableSpecialId(compositorName: string): string {
        const name = compositorName.startsWith("special:") ? compositorName.slice("special:".length) : compositorName;
        for (const definition of root.asArray(root.specialDefinitions)) {
            if (String(definition?.hyprlandName ?? "") === name)
                return String(definition.id ?? "");
        }
        return "";
    }
    function supportsEvent(name: string): bool {
        return ["workspace", "workspacev2", "focusedmon", "focusedmonv2", "activespecial", "activespecialv2", "createworkspace", "createworkspacev2", "destroyworkspace", "destroyworkspacev2", "moveworkspace", "moveworkspacev2", "renameworkspace", "urgent", "activewindow", "activewindowv2", "openwindow", "closewindow", "movewindow", "movewindowv2", "changefloatingmode", "fullscreen", "monitoradded", "monitoraddedv2", "monitorremoved", "monitorremovedv2"].indexOf(name) >= 0;
    }
    function toggleFocusedWindowFloating(): var {
        return root.dispatchBuilt(Commands.toggleFloating(root.focusedAddress(), root.runtime.usingLua === true));
    }
    function toggleFocusedWindowFullscreen(): var {
        return root.dispatchBuilt(Commands.toggleFullscreen(root.focusedAddress(), root.runtime.usingLua === true));
    }
    function toggleSpecialWorkspace(id: string, monitorId: string, invocationContext): var {
        void invocationContext;
        if (!root.available)
            return root.dispatchBuilt(null);
        if (root.connectorForMonitorId(monitorId).length === 0)
            return root.result(false, "HYPRLAND_UNKNOWN_MONITOR");
        const definition = root.specialDefinition(id);
        if (definition === null)
            return root.result(false, "SPECIAL_WORKSPACE_UNAVAILABLE");
        return root.dispatchBuilt(Commands.toggleSpecial(String(definition.hyprlandName ?? ""), root.runtime.usingLua === true));
    }

    Component.onCompleted: {
        if (root.runtime?.connected)
            root.handleConnectionChanged(true);
    }
    onRuntimeChanged: root.handleConnectionChanged(root.runtime?.connected === true)

    QtObject {
        id: state

        property string connectionState: "disconnected"
        property var focusedWindow: null
        property string lastError: ""
        property string lastEventName: ""
        property int lastSequence: -1
        property int malformedEventCount: 0
        property bool stale: false
        property int staleSnapshotCount: 0
        property int unknownEventCount: 0
        property var workspaceRecords: Object.freeze([])
    }
    Connections {
        function onConnectionChanged(connected) {
            root.handleConnectionChanged(connected);
        }
        function onEventReceived(name, data) {
            root.handleEvent(name, data);
        }
        function onStateChanged() {
            root.reconcile();
        }

        ignoreUnknownSignals: true
        target: root.runtime
    }
    Connections {
        function onMonitorsChanged() {
            root.reconcile();
        }

        ignoreUnknownSignals: true
        target: root.monitorRegistry
    }
}
