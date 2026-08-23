pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import "core" as Core
import "features/audio" as AudioFeatures
import "features/power" as PowerFeatures
import "ipc" as Ipc
import "services/audio" as AudioServices
import "services/hyprland" as HyprlandServices
import "services/power" as PowerServices
import "services/power/BrightnessCommandDefinitions.js" as BrightnessCommands
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
            HyprlandServices.QuickshellHyprlandRuntime {
            }
        }
    }
    Core.MonitorRegistry {
        id: monitorRegistry

        backend: root.usesFixtureMonitorBackend ? fixtureMonitorBackend : monitorBackendLoader.status === Loader.Ready ? monitorBackendLoader.item : unavailableMonitorBackend
        configService: configService
    }
    HyprlandServices.HyprlandAdapter {
        id: hyprlandAdapter

        monitorRegistry: monitorRegistry
        runtime: monitorBackendLoader.status === Loader.Ready ? monitorBackendLoader.item : unavailableWorkspaceAdapter
        testedVersion: Core.ProjectInfo.hyprlandVersion
        workspaceConfig: configService.active?.workspaces ?? null
    }
    AudioServices.UnavailableAudioRuntime {
        id: unavailableAudioRuntime
    }
    Loader {
        id: audioRuntimeLoader

        active: !root.usesFixtureMonitorBackend

        sourceComponent: Component {
            AudioServices.QuickshellPipewireRuntime {
            }
        }
    }
    AudioServices.AudioAdapter {
        id: audioAdapter

        runtime: audioRuntimeLoader.status === Loader.Ready ? audioRuntimeLoader.item : unavailableAudioRuntime
    }
    AudioFeatures.AudioController {
        id: audioController

        adapter: audioAdapter
        maximumVolume: 1
        volumeStep: 0.02
    }
    Core.SurfaceCoordinator {
        id: surfaceCoordinator

        monitorRegistry: monitorRegistry
    }
    Core.CommandRegistry {
        id: shellCommandRegistry

        builtinDefinitions: BrightnessCommands.definitions()
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
    PowerServices.UnavailableBatteryRuntime {
        id: unavailableBatteryRuntime
    }
    Loader {
        id: batteryRuntimeLoader

        active: !root.usesFixtureMonitorBackend

        sourceComponent: Component {
            PowerServices.QuickshellUPowerRuntime {
            }
        }
    }
    PowerServices.BatteryAdapter {
        id: batteryAdapter

        runtime: batteryRuntimeLoader.status === Loader.Ready ? batteryRuntimeLoader.item : unavailableBatteryRuntime
    }
    PowerFeatures.BatteryController {
        id: batteryController

        adapter: batteryAdapter
    }
    PowerServices.UnavailableBrightnessRuntime {
        id: unavailableBrightnessRuntime
    }
    Loader {
        id: brightnessRuntimeLoader

        active: !root.usesFixtureMonitorBackend

        sourceComponent: Component {
            PowerServices.CommandRegistryBrightnessRuntime {
                commandRegistry: shellCommandRegistry
            }
        }
    }
    PowerServices.BrightnessAdapter {
        id: brightnessAdapter

        runtime: brightnessRuntimeLoader.status === Loader.Ready ? brightnessRuntimeLoader.item : unavailableBrightnessRuntime
    }
    PowerFeatures.BrightnessController {
        id: brightnessController

        adapter: brightnessAdapter
        consumerActive: controlCenterHosts.openHostCount > 0
    }
    Surfaces.BarHostSet {
        id: barHosts

        audioController: audioController
        barConfig: configService.active?.bar ?? null
        batteryController: root.usesFixtureMonitorBackend ? null : batteryController
        fixtureWindow: root.usesFixtureMonitorBackend
        monitorRegistry: monitorRegistry
        surfaceCoordinator: surfaceCoordinator
        theme: themeManager.active
        workspaceBackend: root.usesFixtureMonitorBackend ? fixtureWorkspaceAdapter : hyprlandAdapter
        workspaceConfig: configService.active?.workspaces ?? null
    }
    Surfaces.ControlCenterHostSet {
        id: controlCenterHosts

        audioController: audioController
        brightnessController: root.usesFixtureMonitorBackend ? null : brightnessController
        controlCenterConfig: configService.active?.controlCenter ?? null
        fixtureWindow: root.usesFixtureMonitorBackend
        monitorRegistry: monitorRegistry
        surfaceCoordinator: surfaceCoordinator
        theme: themeManager.active
    }
    Core.CoreReadinessCoordinator {
        id: readinessCoordinator

        capabilityRegistry: capabilityRegistry
        commandRegistry: shellCommandRegistry
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

        audioProvider: audioAdapter
        barHostProvider: barHosts
        batteryProvider: batteryAdapter
        brightnessProvider: brightnessAdapter
        capabilityRegistry: capabilityRegistry
        commandRegistry: shellCommandRegistry
        configHelperExecutable: configHelperClient.resolvedHelperExecutable
        configHelperResolution: configHelperClient.resolutionPolicy
        configHelperState: configHelperClient.state
        configService: configService
        controlCenterHostProvider: controlCenterHosts
        diagnosticRegistry: diagnosticRegistry
        hyprlandProvider: hyprlandAdapter
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
