import QtQuick
import Quickshell
import "core" as Core
import "ipc" as Ipc
import "surfaces" as Surfaces
import "services/workspaces" as WorkspaceServices
import "theme" as Theme

ShellRoot {
    id: root

    readonly property string mode: String(Quickshell.env("FRANKEN_SHELL_MODE") ?? "development")
    property bool surfaceInitialized: false
    readonly property bool usesFixtureMonitorBackend: root.mode === "mock" || root.mode === "readiness-healthy-test" || root.mode === "readiness-required-failure-test"

    settings.watchFiles: false

    Component.onCompleted: {
        Core.Logger.info("core", "startup", {
            "mode": root.mode,
            "projectVersion": Core.ProjectInfo.projectVersion,
            "shellDir": Quickshell.shellDir
        });
        Core.Logger.info("config", "built-in-defaults-active", {
            "configPath": configService.authoritativePath,
            "schemaVersion": Core.ProjectInfo.configSchemaVersion
        });
        Core.Logger.info("theme", "fallback-theme-active", {
            "theme": themeManager.activeId,
            "mode": themeManager.activeMode
        });
        root.surfaceInitialized = true;
        Core.Logger.info("surfaces", "diagnostic-surface-ready", {
            "visible": diagnosticSurface.visible
        });
    }

    Core.ConfigHelperClient {
        id: configHelperClient
    }
    Core.ConfigService {
        id: configService

        helperClient: configHelperClient
    }
    Core.UnavailableMonitorBackend {
        id: unavailableMonitorBackend
    }
    Core.FixtureMonitorBackend {
        id: fixtureMonitorBackend
    }
    WorkspaceServices.FixtureWorkspaceAdapter {
        id: fixtureWorkspaceAdapter
    }
    WorkspaceServices.UnavailableWorkspaceAdapter {
        id: unavailableWorkspaceAdapter
    }
    Loader {
        id: monitorBackendLoader

        active: !root.usesFixtureMonitorBackend

        sourceComponent: Component {
            Core.HyprlandMonitorAdapter {
            }
        }
    }
    Core.MonitorRegistry {
        id: monitorRegistry

        backend: root.usesFixtureMonitorBackend ? fixtureMonitorBackend : monitorBackendLoader.status === Loader.Ready ? monitorBackendLoader.item : unavailableMonitorBackend
        configService: configService
    }
    Core.SurfaceCoordinator {
        id: surfaceCoordinator

        monitorRegistry: monitorRegistry
    }
    Core.CommandRegistry {
        id: commandRegistry

        configService: configService
    }
    Core.CapabilityRegistry {
        id: capabilityRegistry
    }
    Core.DiagnosticRegistry {
        id: diagnosticRegistry
    }
    Theme.ThemeManager {
        id: themeManager

        configService: configService
    }
    Surfaces.BarHostSet {
        id: barHosts

        barConfig: configService.active?.bar ?? null
        fixtureWindow: root.usesFixtureMonitorBackend
        monitorRegistry: monitorRegistry
        surfaceCoordinator: surfaceCoordinator
        theme: themeManager.active
        workspaceBackend: root.usesFixtureMonitorBackend ? fixtureWorkspaceAdapter : unavailableWorkspaceAdapter
        workspaceConfig: configService.active?.workspaces ?? null
    }
    Surfaces.ControlCenterHostSet {
        id: controlCenterHosts

        controlCenterConfig: configService.active?.controlCenter ?? null
        fixtureWindow: root.usesFixtureMonitorBackend
        monitorRegistry: monitorRegistry
        surfaceCoordinator: surfaceCoordinator
        theme: themeManager.active
    }
    Core.CoreReadinessCoordinator {
        id: readinessCoordinator

        capabilityRegistry: capabilityRegistry
        commandRegistry: commandRegistry
        configService: configService
        diagnosticRegistry: diagnosticRegistry
        mode: root.mode
        monitorRegistry: monitorRegistry
        surfaceReady: root.surfaceInitialized
        themeManager: themeManager
    }
    Core.ShellState {
        id: shellState

        capabilityRegistry: capabilityRegistry
        configLoaded: readinessCoordinator.configLoaded
        coreDegraded: readinessCoordinator.coreDegraded
        coreServicesReady: readinessCoordinator.coreServicesReady
        requiredFailureCode: readinessCoordinator.requiredFailureCode
        surfacesReady: root.surfaceInitialized
    }
    Core.Diagnostics {
        id: diagnostics

        barHostProvider: barHosts
        capabilityRegistry: capabilityRegistry
        commandRegistry: commandRegistry
        configHelperExecutable: configHelperClient.resolvedHelperExecutable
        configHelperResolution: configHelperClient.resolutionPolicy
        configHelperState: configHelperClient.state
        configService: configService
        controlCenterHostProvider: controlCenterHosts
        diagnosticRegistry: diagnosticRegistry
        mode: root.mode
        monitorRegistry: monitorRegistry
        shellState: shellState
        surfaceCoordinator: surfaceCoordinator
        surfaceVisible: diagnosticSurface.visible
        themeManager: themeManager
    }
    Ipc.ShellIpc {
        configService: configService
        controlCenterHostProvider: controlCenterHosts
        diagnosticsProvider: diagnostics
        surfaceCoordinator: surfaceCoordinator
    }
    Surfaces.DiagnosticSurface {
        id: diagnosticSurface

        mode: root.mode
        startupState: shellState.state
        theme: themeManager.active
    }
    Connections {
        function onStateTransitioned(previousState, currentState) {
            const fields = {
                "previousState": previousState,
                "currentState": currentState,
                "failureCode": shellState.failureCode
            };
            if (currentState === "Failed")
                Core.Logger.error("core", "readiness-transition", fields);
            else
                Core.Logger.info("core", "readiness-transition", fields);
        }

        target: shellState
    }
}
