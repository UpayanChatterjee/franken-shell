import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root

    required property var barHostProvider
    required property var capabilityRegistry
    required property var commandRegistry
    required property string configHelperExecutable
    required property string configHelperResolution
    required property string configHelperState
    required property var configService
    required property var diagnosticRegistry
    required property string mode
    required property var monitorRegistry
    required property var shellState
    required property var surfaceCoordinator
    required property bool surfaceVisible
    required property var themeManager

    function summaryObject(): var {
        const config = root.configService.configurationSummary();
        const monitors = root.monitorRegistry.diagnosticsSummary();
        const commands = root.commandRegistry.registrySummary();
        const barHosts = root.barHostProvider.summary();
        const capabilities = root.capabilityRegistry.summary();
        const diagnostics = root.diagnosticRegistry.summary();
        const shell = root.shellState.summary();
        const surfaces = root.surfaceCoordinator.summary();
        const theme = root.themeManager.summary();
        return Object.freeze({
            "project": ProjectInfo.projectName,
            "projectVersion": ProjectInfo.projectVersion,
            "mode": root.mode,
            "startupState": shell.state,
            "shellReady": shell.ready,
            "shellDegraded": shell.degraded,
            "shellFailed": shell.failed,
            "shellFailureCode": shell.failureCode,
            "shellPath": ProjectInfo.shellPath,
            "configPath": config.authoritativePath,
            "surfaceVisible": root.surfaceVisible,
            "expectedQuickshellVersion": ProjectInfo.quickshellVersion,
            "expectedQuickshellCommit": ProjectInfo.quickshellCommit,
            "expectedQuickshellPackage": ProjectInfo.quickshellPackage,
            "expectedQtVersion": ProjectInfo.qtVersion,
            "testedHyprlandVersion": ProjectInfo.hyprlandVersion,
            "hyprlandConfigMode": ProjectInfo.hyprlandConfigMode,
            "configSchemaVersion": ProjectInfo.configSchemaVersion,
            "configActiveSource": config.activeSource,
            "configActiveSchemaVersion": config.activeSchemaVersion,
            "configActiveGeneration": config.activeGeneration,
            "configHealth": config.health,
            "configSourceState": config.sourceState,
            "configReloadState": config.reloadState,
            "configWarningCount": config.warningCount,
            "configErrorCount": config.errorCount,
            "configHelperTransportHealth": config.helperTransportHealth,
            "configMigratedInMemory": config.migrationInMemory,
            "configLastSuccessfulValidation": config.lastSuccessfulValidation,
            "configLastRejectedGeneration": config.lastRejectedGeneration,
            "configWatchEnabled": config.watchEnabled,
            "configActivationSequence": config.activationSequence,
            "monitorConnectedCount": monitors.connectedMonitorCount,
            "monitorMappedCount": monitors.mappedMonitorCount,
            "monitorAmbiguousCount": monitors.ambiguousMonitorCount,
            "monitorUnmappedCount": monitors.unmappedMonitorCount,
            "monitorFocusedRuntimeId": monitors.focusedMonitorRuntimeId,
            "monitorFocusedWindowRuntimeId": monitors.focusedWindowMonitorRuntimeId,
            "monitorFallbackRuntimeId": monitors.fallbackMonitorRuntimeId,
            "monitorBackendAvailability": monitors.backendAvailability,
            "monitorLastRefresh": monitors.lastRefresh,
            "monitorLastMappingError": monitors.lastMappingError,
            "commandRegisteredCount": commands.registeredCommandCount,
            "commandAvailableCount": commands.availableCommandCount,
            "commandUnavailableCount": commands.unavailableCommandCount,
            "commandActiveRequestCount": commands.activeRequestCount,
            "commandQueuedRequestCount": commands.queuedRequestCount,
            "commandRetainedRequestCount": commands.retainedRequestCount,
            "commandLastRequestId": commands.lastRequestId,
            "commandLastFailureCategory": commands.lastFailureCategory,
            "commandRegistryGeneration": commands.registryGeneration,
            "commandSnapshotSequence": commands.snapshotSequence,
            "commandLastAvailabilityRefresh": commands.lastAvailabilityRefresh,
            "barHostCount": barHosts.hostCount,
            "barResolvedHostCount": barHosts.resolvedHostCount,
            "barVisibleHostCount": barHosts.visibleHostCount,
            "barHosts": barHosts.hosts,
            "capabilityEvaluated": capabilities.evaluated,
            "capabilityRevision": capabilities.revision,
            "capabilityAvailableCount": capabilities.availableCount,
            "capabilityUnavailableCount": capabilities.unavailableCount,
            "capabilityDegradedCount": capabilities.degradedCount,
            "capabilityFailedCount": capabilities.failedCount,
            "capabilityRequiredFailureCount": capabilities.requiredFailureCount,
            "diagnosticServiceCount": diagnostics.serviceCount,
            "diagnosticErrorCount": diagnostics.errorCount,
            "diagnosticCriticalCount": diagnostics.criticalCount,
            "diagnosticRecoverableCount": diagnostics.recoverableCount,
            "surfaceActiveMajorId": surfaces.activeMajorId,
            "surfaceActiveMajorMonitorId": surfaces.activeMajorMonitorId,
            "surfaceActivePopoverId": surfaces.activePopoverId,
            "surfaceActivePopoverMonitorId": surfaces.activePopoverMonitorId,
            "surfaceActiveCount": surfaces.activeSurfaceCount,
            "surfaceRevision": surfaces.revision,
            "surfaceLastTransition": surfaces.lastTransition,
            "surfaceRestorationRequestCount": surfaces.restorationRequestCount,
            "surfaceRejectedRequestCount": surfaces.rejectedRequestCount,
            "themeActiveId": theme.activeId,
            "themeMode": theme.activeMode,
            "themeSource": theme.activeSource,
            "themeHighContrast": theme.highContrast,
            "themeReducedMotion": theme.reducedMotion,
            "themeHealth": theme.health,
            "themeRevision": theme.revision,
            "configHelperProtocolVersion": ProjectInfo.configHelperProtocolVersion,
            "configHelperState": root.configHelperState,
            "configHelperResolution": root.configHelperResolution,
            "configHelperExecutable": root.configHelperExecutable,
            "ipcVersion": ProjectInfo.ipcVersion
        });
    }

    Timer {
        id: reloadTimer

        interval: 0

        onTriggered: Quickshell.reload(false)
    }
    IpcHandler {
        function capabilities(): string {
            return JSON.stringify(root.capabilityRegistry.summary());
        }
        function commandDemo(): string {
            if (root.mode !== "command-demo") {
                return JSON.stringify({
                    "state": "unavailable",
                    "failureCategory": "commandDemoModeRequired"
                });
            }
            return JSON.stringify(root.commandRegistry.execute("development.commandDemo"));
        }
        function commandStatus(): string {
            return JSON.stringify(root.commandRegistry.registrySummary());
        }
        function configStatus(): string {
            return JSON.stringify(root.configService.configurationSummary());
        }
        function errors(): string {
            return JSON.stringify(root.diagnosticRegistry.errorsSummary());
        }
        function monitorStatus(): string {
            return JSON.stringify(root.monitorRegistry.diagnosticsSummary());
        }
        function readiness(): string {
            return JSON.stringify(root.shellState.summary());
        }
        function reload(): string {
            Logger.info("core", "soft-reload-requested", {});
            reloadTimer.start();
            return "soft reload requested";
        }
        function reloadConfig(): string {
            Logger.info("config", "explicit-reload-requested", {});
            return root.configService.requestReload();
        }
        function services(): string {
            return JSON.stringify(root.diagnosticRegistry.servicesSummary());
        }
        function summary(): string {
            return JSON.stringify(root.summaryObject());
        }
        function themeStatus(): string {
            return JSON.stringify(root.themeManager.summary());
        }
        function version(): string {
            return JSON.stringify({
                "projectVersion": ProjectInfo.projectVersion,
                "quickshellVersion": ProjectInfo.quickshellVersion,
                "quickshellCommit": ProjectInfo.quickshellCommit,
                "quickshellPackage": ProjectInfo.quickshellPackage,
                "qtVersion": ProjectInfo.qtVersion,
                "hyprlandVersion": ProjectInfo.hyprlandVersion,
                "hyprlandConfigMode": ProjectInfo.hyprlandConfigMode
            });
        }

        target: "diagnostics"
    }
}
