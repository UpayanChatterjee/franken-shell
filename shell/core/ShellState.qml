import QtQuick
import Quickshell

Scope {
    id: root

    required property var capabilityRegistry
    property bool configLoaded: false
    property bool coreDegraded: false
    property bool coreServicesReady: false
    readonly property bool degraded: root.state === "Degraded"
    readonly property bool failed: root.state === "Failed"
    readonly property string failureCode: root.failed ? (root.requiredFailureCode.length > 0 ? root.requiredFailureCode : "REQUIRED_CAPABILITY_UNAVAILABLE") : ""
    readonly property bool ready: root.state === "OptionalIntegrationsReady" || root.state === "Degraded"
    property string requiredFailureCode: ""
    readonly property string state: controller.resolve(root.capabilityRegistry.revision)
    property bool surfacesReady: false

    signal stateTransitioned(string previousState, string currentState)

    function summary(): var {
        return Object.freeze({
            "state": root.state,
            "ready": root.ready,
            "degraded": root.degraded,
            "failed": root.failed,
            "failureCode": root.failureCode,
            "configLoaded": root.configLoaded,
            "coreServicesReady": root.coreServicesReady,
            "surfacesReady": root.surfacesReady,
            "capabilitiesEvaluated": root.capabilityRegistry.evaluated
        });
    }

    onStateChanged: {
        const previous = stateStorage.previousState;
        stateStorage.previousState = root.state;
        if (previous.length > 0 && previous !== root.state)
            root.stateTransitioned(previous, root.state);
    }

    QtObject {
        id: stateStorage

        property string previousState: ""
    }
    QtObject {
        id: controller

        function resolve(capabilityRevision: int): string {
            void capabilityRevision;
            if (root.requiredFailureCode.length > 0 || root.capabilityRegistry.requiredFailureCount > 0) {
                return "Failed";
            }
            if (!root.configLoaded)
                return "Bootstrapping";
            if (!root.coreServicesReady)
                return "ConfigLoaded";
            if (!root.surfacesReady)
                return "CoreServicesReady";
            if (!root.capabilityRegistry.evaluated)
                return "SurfacesReady";
            if (root.coreDegraded || root.capabilityRegistry.nonAvailableCount > 0)
                return "Degraded";
            return "OptionalIntegrationsReady";
        }
    }
}
