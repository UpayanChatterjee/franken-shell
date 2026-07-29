import QtQuick
import Quickshell

Scope {
    id: root

    required property var adapter
    readonly property string busyId: controller.snapshot(state.backendRevision).busyId
    required property var definitions
    readonly property int definitionsCount: root.rows.length
    readonly property string lastError: state.localError.length > 0 ? state.localError : controller.snapshot(state.backendRevision).lastError
    required property var monitor
    readonly property string monitorId: String(root.monitor?.runtimeId ?? "")
    readonly property string persistentIcon: controller.persistentIcon(root.rows)
    readonly property string persistentLabel: controller.persistentLabel(root.rows)
    readonly property var rows: controller.rows(state.backendRevision)
    readonly property bool stateAvailable: controller.snapshot(state.backendRevision).stateAvailable
    readonly property var visibleIds: controller.snapshot(state.backendRevision).visibleIds

    signal toggleFailed(string id, string errorCode)
    signal toggleSucceeded(string id)

    function initialFocusIndex(): int {
        const visibleIndex = root.rows.findIndex(row => row.visible);
        return visibleIndex >= 0 ? visibleIndex : root.rows.length > 0 ? 0 : -1;
    }
    function toggle(id: string, invocationContext): var {
        const row = root.rows.find(candidate => candidate.id === id);
        if (!root.stateAvailable)
            return controller.failure(id, "WORKSPACE_STATE_UNAVAILABLE");
        if (row === undefined || !row.available)
            return controller.failure(id, "SPECIAL_WORKSPACE_UNAVAILABLE");

        const result = root.adapter.toggleSpecialWorkspace(id, root.monitorId, invocationContext);
        state.localError = result.accepted ? "" : String(result.errorCode ?? "SPECIAL_WORKSPACE_TOGGLE_FAILED");
        if (result.accepted)
            root.toggleSucceeded(id);
        else
            root.toggleFailed(id, state.localError);
        return controller.result(result.accepted === true, state.localError);
    }

    Connections {
        function onStateChanged() {
            state.backendRevision += 1;
            if (controller.snapshot(state.backendRevision).lastError.length === 0)
                state.localError = "";
        }

        target: root.adapter
    }
    QtObject {
        id: state

        property int backendRevision: 0
        property string localError: ""
    }
    QtObject {
        id: controller

        function definitionsArray(): var {
            if (Array.isArray(root.definitions))
                return Array.from(root.definitions);
            if (typeof root.definitions?.toArray === "function")
                return root.definitions.toArray();
            return [];
        }
        function failure(id: string, errorCode: string): var {
            state.localError = errorCode;
            root.toggleFailed(id, errorCode);
            return controller.result(false, errorCode);
        }
        function persistentIcon(rows): string {
            const visible = rows.filter(row => row.visible);
            return visible.length === 1 ? visible[0].icon : "stack";
        }
        function persistentLabel(rows): string {
            const visible = rows.filter(row => row.visible);
            return visible.length === 1 ? visible[0].label : qsTr("Special workspaces");
        }
        function result(accepted: bool, errorCode: string): var {
            return Object.freeze({
                "accepted": accepted,
                "errorCode": errorCode
            });
        }
        function rows(revision: int): var {
            const snapshot = controller.snapshot(revision);
            const values = controller.definitionsArray().map(definition => Object.freeze({
                    "id": String(definition.id ?? ""),
                    "hyprlandName": String(definition.hyprlandName ?? ""),
                    "label": String(definition.label ?? ""),
                    "icon": String(definition.icon ?? "stack"),
                    "shortcutHint": String(definition.shortcutHint ?? ""),
                    "visible": snapshot.visibleIds.indexOf(definition.id) >= 0,
                    "available": snapshot.stateAvailable && snapshot.unavailableIds.indexOf(definition.id) < 0,
                    "busy": snapshot.busyId === definition.id
                }));
            return Object.freeze(values);
        }
        function snapshot(revision: int): var {
            void revision;
            const candidate = root.adapter?.specialSnapshot(root.monitorId);
            return candidate ?? Object.freeze({
                "stateAvailable": false,
                "visibleIds": Object.freeze([]),
                "unavailableIds": Object.freeze([]),
                "busyId": "",
                "lastError": "WORKSPACE_STATE_UNAVAILABLE"
            });
        }
    }
}
