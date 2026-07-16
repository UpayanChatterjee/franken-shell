import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    required property string mode
    required property string startupState
    required property bool surfaceVisible
    required property QtObject configService
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
            const config = configService.configurationSummary();
            return JSON.stringify({
                project: ProjectInfo.projectName,
                projectVersion: ProjectInfo.projectVersion,
                mode: mode,
                startupState: startupState,
                shellPath: ProjectInfo.shellPath,
                configPath: config.authoritativePath,
                surfaceVisible: surfaceVisible,
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
                configHelperProtocolVersion: ProjectInfo.configHelperProtocolVersion,
                configHelperState: configHelperState,
                configHelperResolution: configHelperResolution,
                configHelperExecutable: configHelperExecutable,
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
            return JSON.stringify(configService.configurationSummary());
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
            return configService.requestReload();
        }
    }
}
