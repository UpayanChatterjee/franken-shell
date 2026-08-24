import QtQuick
import Quickshell

Scope {
    id: root

    required property var commandRegistry
    readonly property var directEntries: root.directEntryIds.filter(commandId => commandId !== "vicinae.root").map(commandId => Object.freeze({
            "id": commandId,
            "label": root.entryLabel(commandId),
            "available": root.enabled && root.commandRegistry?.commandAvailable(commandId) === true
        }))
    property var directEntryIds: Object.freeze([])
    property bool enabled: true
    required property var feedbackController
    readonly property string lastError: state.lastError
    readonly property bool rootInvocationAvailable: root.enabled && root.commandRegistry?.commandAvailable("vicinae.root") === true
    required property var surfaceCoordinator

    function entryLabel(commandId: string): string {
        const token = String(commandId).split(".").pop() ?? commandId;
        return token.length > 0 ? token.charAt(0).toUpperCase() + token.slice(1).replace(/[-_]/g, " ") : qsTr("Vicinae entry");
    }
    function invokeEntry(commandId: string, context = ({})): var {
        if (root.directEntryIds.indexOf(commandId) < 0 || commandId === "vicinae.root" || !root.enabled || root.commandRegistry?.commandAvailable(commandId) !== true) {
            state.lastError = "VICINAE_ENTRY_UNAVAILABLE";
            root.feedbackController.showToast({
                "key": "generic",
                "severity": "failure",
                "summary": qsTr("Vicinae entry unavailable"),
                "userTriggered": true
            }, context);
            return root.result(false, state.lastError);
        }
        root.surfaceCoordinator.closeAll("requested");
        const request = root.commandRegistry.execute(commandId);
        const accepted = ["queued", "starting", "running"].indexOf(request?.state ?? "") >= 0;
        state.lastError = accepted ? "" : String(request?.failureCategory ?? "VICINAE_INVOCATION_REJECTED");
        return root.result(accepted, state.lastError);
    }
    function result(accepted: bool, errorCode: string): var {
        return Object.freeze({
            "accepted": accepted,
            "errorCode": errorCode
        });
    }
    function toggleRoot(context = ({})): var {
        if (!root.enabled || !root.rootInvocationAvailable) {
            state.lastError = root.enabled ? "VICINAE_ROOT_UNAVAILABLE" : "VICINAE_DISABLED";
            root.feedbackController.showToast({
                "key": "generic",
                "severity": "failure",
                "summary": qsTr("Vicinae is unavailable"),
                "detail": qsTr("Configure a verified vicinae.root command to enable this entry."),
                "userTriggered": true
            }, context);
            return root.result(false, state.lastError);
        }
        root.surfaceCoordinator.closeAll("requested");
        const response = root.commandRegistry.execute("vicinae.root");
        if (response === null || response === undefined || response.state === "unavailable") {
            state.lastError = String(response?.failureCategory ?? "VICINAE_INVOCATION_REJECTED");
            root.feedbackController.showToast({
                "key": "generic",
                "severity": "failure",
                "summary": qsTr("Vicinae could not be opened"),
                "userTriggered": true
            }, context);
            return root.result(false, state.lastError);
        }
        state.lastError = "";
        return root.result(true, "");
    }

    QtObject {
        id: state

        property string lastError: ""
    }
}
