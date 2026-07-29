import QtQuick
import Quickshell

Scope {
    id: root

    required property var capabilityRegistry
    required property var commandRegistry
    readonly property bool configLoaded: root.configService.active !== null
    required property var configService
    readonly property bool coreDegraded: root.configService.health === "degraded" || root.monitorRegistry.lastMappingError.length > 0 || root.themeManager.health === "degraded"
    readonly property bool coreServicesReady: root.configLoaded && root.monitorRegistry.lastRefresh.length > 0 && root.commandRegistry.registryGeneration > 0
    required property var diagnosticRegistry
    required property string mode
    required property var monitorRegistry
    readonly property string requiredFailureCode: root.mode === "readiness-required-failure-test" ? "FIXTURE_REQUIRED_CORE_FAILURE" : ""
    required property bool surfaceReady
    required property var themeManager

    function scheduleSync() {
        syncTimer.restart();
    }

    Component.onCompleted: root.scheduleSync()

    Connections {
        function onActivated() {
            root.scheduleSync();
        }
        function onCandidateRejected() {
            root.scheduleSync();
        }
        function onHealthChanged() {
            root.scheduleSync();
        }
        function onReloadStateChanged() {
            root.scheduleSync();
        }

        target: root.configService
    }
    Connections {
        function onBackendAvailabilityChanged() {
            root.scheduleSync();
        }
        function onLastMappingErrorChanged() {
            root.scheduleSync();
        }
        function onRevisionChanged() {
            root.scheduleSync();
        }

        target: root.monitorRegistry
    }
    Connections {
        function onLastFailureCategoryChanged() {
            root.scheduleSync();
        }
        function onRegistryGenerationChanged() {
            root.scheduleSync();
        }

        target: root.commandRegistry
    }
    Connections {
        function onActivated() {
            root.scheduleSync();
        }
        function onCandidateRejected() {
            root.scheduleSync();
        }
        function onHealthChanged() {
            root.scheduleSync();
        }

        target: root.themeManager
    }
    Timer {
        id: syncTimer

        interval: 0

        onTriggered: controller.sync()
    }
    QtObject {
        id: controller

        readonly property var capabilityIds: Object.freeze(["hasHyprland", "hasVicinae", "hasOverview", "hasBattery", "hasNetworkBackend", "hasBluetoothBackend", "hasAudioBackend"])

        function capabilitySnapshot(): var {
            const healthyFixture = root.mode === "readiness-healthy-test";
            const records = [];
            for (const id of controller.capabilityIds) {
                let state = "unavailable";
                let reason = "adapterNotImplemented";
                let source = "foundation";
                if (healthyFixture) {
                    state = "available";
                    reason = "";
                    source = "fixture";
                } else if (id === "hasHyprland" && root.monitorRegistry.backendAvailability === "available") {
                    state = "available";
                    reason = "";
                    source = "monitorRegistry";
                } else if (id === "hasHyprland") {
                    reason = "backendUnavailable";
                    source = "monitorRegistry";
                }
                records.push({
                    "id": id,
                    "state": state,
                    "required": false,
                    "reason": reason,
                    "source": source
                });
            }
            return records;
        }
        function configErrorCode(): string {
            const errors = root.configService.errors;
            if (Array.isArray(errors) && errors.length > 0 && typeof errors[0].code === "string") {
                return errors[0].code;
            }
            return "CONFIG_DEGRADED";
        }
        function serviceSnapshot(): var {
            const configDegraded = root.configService.health === "degraded";
            const monitorDegraded = root.monitorRegistry.lastMappingError.length > 0;
            const commandReady = root.commandRegistry.registryGeneration > 0;
            return [
                {
                    "name": "capabilities",
                    "availability": "available",
                    "state": root.capabilityRegistry.evaluated ? "ready" : "starting",
                    "lastError": "",
                    "lastSuccess": "",
                    "version": "",
                    "backend": "internal",
                    "recoverable": true,
                    "repairHint": ""
                },
                {
                    "name": "commands",
                    "availability": commandReady ? "available" : "degraded",
                    "state": commandReady ? "ready" : "starting",
                    "lastError": root.commandRegistry.lastFailureCategory,
                    "lastSuccess": root.commandRegistry.lastAvailabilityRefresh,
                    "version": "",
                    "backend": "quickshell-process",
                    "recoverable": true,
                    "repairHint": ""
                },
                {
                    "name": "config",
                    "availability": configDegraded ? "degraded" : "available",
                    "state": configDegraded ? "degraded" : "ready",
                    "lastError": configDegraded ? controller.configErrorCode() : "",
                    "lastSuccess": root.configService.lastSuccessfulValidation,
                    "version": String(root.configService.activeSchemaVersion),
                    "backend": "franken-config-helper",
                    "recoverable": true,
                    "repairHint": configDegraded ? "Correct the configuration and reload it." : ""
                },
                {
                    "name": "monitors",
                    "availability": monitorDegraded ? "degraded" : "available",
                    "state": monitorDegraded ? "degraded" : "ready",
                    "lastError": root.monitorRegistry.lastMappingError,
                    "lastSuccess": root.monitorRegistry.lastRefresh,
                    "version": "",
                    "backend": root.monitorRegistry.backendAvailability,
                    "recoverable": true,
                    "repairHint": monitorDegraded ? "Inspect monitor mapping diagnostics." : ""
                },
                {
                    "name": "theme",
                    "availability": root.themeManager.health === "healthy" ? "available" : "degraded",
                    "state": root.themeManager.health === "healthy" ? "ready" : "degraded",
                    "lastError": root.themeManager.lastError,
                    "lastSuccess": root.themeManager.revision > 0 ? String(root.themeManager.revision) : "builtInFallback",
                    "version": root.themeManager.activeId,
                    "backend": root.themeManager.activeSource,
                    "recoverable": true,
                    "repairHint": root.themeManager.health === "degraded" ? "Keep the active theme and inspect the rejected candidate." : ""
                }
            ];
        }
        function sync() {
            root.capabilityRegistry.replace(controller.capabilitySnapshot());
            root.diagnosticRegistry.replaceServices(controller.serviceSnapshot());
            controller.syncErrors();
        }
        function syncErrors() {
            if (root.requiredFailureCode.length > 0) {
                if (root.diagnosticRegistry.error("core", root.requiredFailureCode) === null) {
                    root.diagnosticRegistry.report({
                        "domain": "core",
                        "code": root.requiredFailureCode,
                        "severity": "critical",
                        "summary": "A required core service failed in the controlled readiness fixture.",
                        "recoverable": false,
                        "repairHint": "Inspect the required-core readiness fixture."
                    });
                }
            } else {
                root.diagnosticRegistry.clearDomain("core");
            }

            if (root.configService.health === "degraded") {
                const code = controller.configErrorCode();
                if (root.diagnosticRegistry.error("config", code) === null) {
                    root.diagnosticRegistry.report({
                        "domain": "config",
                        "code": code,
                        "severity": "error",
                        "summary": "The active configuration is degraded; the last safe snapshot remains active.",
                        "recoverable": true,
                        "repairHint": "Correct the configuration and reload it."
                    });
                }
            } else {
                root.diagnosticRegistry.clearDomain("config");
            }

            if (root.themeManager.health === "degraded") {
                if (root.diagnosticRegistry.error("theme", root.themeManager.lastError) === null) {
                    root.diagnosticRegistry.report({
                        "domain": "theme",
                        "code": root.themeManager.lastError,
                        "severity": "error",
                        "summary": "A theme candidate was rejected; the last valid semantic theme remains active.",
                        "recoverable": true,
                        "repairHint": "Inspect the theme adapter and candidate diagnostics."
                    });
                }
            } else {
                root.diagnosticRegistry.clearDomain("theme");
            }
        }
    }
}
