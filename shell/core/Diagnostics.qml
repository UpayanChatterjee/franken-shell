import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root

    required property string mode
    required property string startupState
    required property bool surfaceVisible
    required property var configService
    required property var monitorRegistry
    required property var commandRegistry
    required property string configHelperState
    required property string configHelperResolution
    required property string configHelperExecutable

    Timer {
        id: reloadTimer

        interval: 0
        onTriggered: Quickshell.reload(false)
    }

    IpcHandler {
        target: "diagnostics"

        function summary(): string {
            const config = root.configService.configurationSummary();
            const monitors = root.monitorRegistry.diagnosticsSummary();
            const commands = root.commandRegistry.registrySummary();
            return JSON.stringify({
                project: ProjectInfo.projectName,
                projectVersion: ProjectInfo.projectVersion,
                mode: root.mode,
                startupState: root.startupState,
                shellPath: ProjectInfo.shellPath,
                configPath: config.authoritativePath,
                surfaceVisible: root.surfaceVisible,
                expectedQuickshellVersion: ProjectInfo.quickshellVersion,
                expectedQuickshellCommit: ProjectInfo.quickshellCommit,
                expectedQuickshellPackage: ProjectInfo.quickshellPackage,
                expectedQtVersion: ProjectInfo.qtVersion,
                testedHyprlandVersion: ProjectInfo.hyprlandVersion,
                hyprlandConfigMode: ProjectInfo.hyprlandConfigMode,
                configSchemaVersion: ProjectInfo.configSchemaVersion,
                configActiveSource: config.activeSource,
                configActiveSchemaVersion: config.activeSchemaVersion,
                configActiveGeneration: config.activeGeneration,
                configHealth: config.health,
                configSourceState: config.sourceState,
                configReloadState: config.reloadState,
                configWarningCount: config.warningCount,
                configErrorCount: config.errorCount,
                configHelperTransportHealth: config.helperTransportHealth,
                configMigratedInMemory: config.migrationInMemory,
                configLastSuccessfulValidation: config.lastSuccessfulValidation,
                configLastRejectedGeneration: config.lastRejectedGeneration,
                configWatchEnabled: config.watchEnabled,
                configActivationSequence: config.activationSequence,
                monitorConnectedCount: monitors.connectedMonitorCount,
                monitorMappedCount: monitors.mappedMonitorCount,
                monitorAmbiguousCount: monitors.ambiguousMonitorCount,
                monitorUnmappedCount: monitors.unmappedMonitorCount,
                monitorFocusedRuntimeId: monitors.focusedMonitorRuntimeId,
                monitorFocusedWindowRuntimeId: monitors.focusedWindowMonitorRuntimeId,
                monitorFallbackRuntimeId: monitors.fallbackMonitorRuntimeId,
                monitorBackendAvailability: monitors.backendAvailability,
                monitorLastRefresh: monitors.lastRefresh,
                monitorLastMappingError: monitors.lastMappingError,
                commandRegisteredCount: commands.registeredCommandCount,
                commandAvailableCount: commands.availableCommandCount,
                commandUnavailableCount: commands.unavailableCommandCount,
                commandActiveRequestCount: commands.activeRequestCount,
                commandQueuedRequestCount: commands.queuedRequestCount,
                commandRetainedRequestCount: commands.retainedRequestCount,
                commandLastRequestId: commands.lastRequestId,
                commandLastFailureCategory: commands.lastFailureCategory,
                commandRegistryGeneration: commands.registryGeneration,
                commandSnapshotSequence: commands.snapshotSequence,
                commandLastAvailabilityRefresh: commands.lastAvailabilityRefresh,
                configHelperProtocolVersion: ProjectInfo.configHelperProtocolVersion,
                configHelperState: root.configHelperState,
                configHelperResolution: root.configHelperResolution,
                configHelperExecutable: root.configHelperExecutable,
                ipcVersion: ProjectInfo.ipcVersion
            });
        }

        function version(): string {
            return JSON.stringify({
                projectVersion: ProjectInfo.projectVersion,
                quickshellVersion: ProjectInfo.quickshellVersion,
                quickshellCommit: ProjectInfo.quickshellCommit,
                quickshellPackage: ProjectInfo.quickshellPackage,
                qtVersion: ProjectInfo.qtVersion,
                hyprlandVersion: ProjectInfo.hyprlandVersion,
                hyprlandConfigMode: ProjectInfo.hyprlandConfigMode
            });
        }

        function configStatus(): string {
            return JSON.stringify(root.configService.configurationSummary());
        }

        function monitorStatus(): string {
            return JSON.stringify(root.monitorRegistry.diagnosticsSummary());
        }

        function commandStatus(): string {
            return JSON.stringify(root.commandRegistry.registrySummary());
        }

        function commandDemo(): string {
            if (root.mode !== "command-demo") {
                return JSON.stringify({
                    state: "unavailable",
                    failureCategory: "commandDemoModeRequired"
                });
            }
            return JSON.stringify(root.commandRegistry.execute("development.commandDemo"));
        }

        function themeStatus(): string {
            return JSON.stringify({
                status: "Ready",
                source: "built-in",
                theme: "FallbackTheme"
            });
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
    }
}
