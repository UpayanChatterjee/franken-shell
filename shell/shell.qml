//@ pragma UseQApplication
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import "core" as Core
import "features/audio" as AudioFeatures
import "features/bluetooth" as BluetoothFeatures
import "features/bar" as BarFeatures
import "features/feedback" as FeedbackFeatures
import "features/network" as NetworkFeatures
import "features/notifications" as NotificationFeatures
import "features/power" as PowerFeatures
import "features/telemetry" as TelemetryFeatures
import "features/tray" as TrayFeatures
import "ipc" as Ipc
import "services/audio" as AudioServices
import "services/bluetooth" as BluetoothServices
import "services/feedback" as FeedbackServices
import "services/hyprland" as HyprlandServices
import "services/network" as NetworkServices
import "services/notifications" as NotificationServices
import "services/notifications/NotificationSoundCommandDefinitions.js" as NotificationSoundCommands
import "services/power" as PowerServices
import "services/power/BrightnessCommandDefinitions.js" as BrightnessCommands
import "services/telemetry" as TelemetryServices
import "services/tray" as TrayServices
import "services/telemetry/ResourceCommandDefinitions.js" as ResourceCommands
import "surfaces" as Surfaces
import "services/workspaces" as WorkspaceServices
import "theme" as Theme

ShellRoot {
    id: root

    readonly property var activeBarConfig: configService.active?.bar ?? null
    readonly property var activeIntegrationsConfig: configService.active?.integrations ?? null
    readonly property var activeShellConfig: configService.active?.shell ?? null
    readonly property string mode: String(Quickshell.env("FRANKEN_SHELL_MODE") ?? "development")
    readonly property var networkSpeedConfig: root.activeBarConfig?.networkSpeed ?? null
    readonly property bool notificationOwnershipEnabled: root.mode === "notification-owner-test"
    property bool surfaceInitialized: false
    readonly property bool trayOwnershipEnabled: root.mode === "tray-owner-test"
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
        feedbackController: feedbackController
        maximumVolume: 1
        volumeStep: 0.02
    }
    BluetoothServices.UnavailableBluetoothRuntime {
        id: unavailableBluetoothRuntime
    }
    Loader {
        id: bluetoothRuntimeLoader

        active: !root.usesFixtureMonitorBackend

        sourceComponent: Component {
            BluetoothServices.QuickshellBluetoothRuntime {
            }
        }
    }
    BluetoothServices.BluetoothAdapter {
        id: bluetoothAdapter

        runtime: bluetoothRuntimeLoader.status === Loader.Ready ? bluetoothRuntimeLoader.item : unavailableBluetoothRuntime
    }
    BluetoothFeatures.BluetoothController {
        id: bluetoothController

        adapter: bluetoothAdapter
        detailVisible: controlCenterHosts.bluetoothPageOpenCount > 0
    }
    NetworkServices.UnavailableNetworkRuntime {
        id: unavailableNetworkRuntime
    }
    Loader {
        id: networkRuntimeLoader

        active: !root.usesFixtureMonitorBackend

        sourceComponent: Component {
            NetworkServices.QuickshellNetworkRuntime {
            }
        }
    }
    NetworkServices.NetworkAdapter {
        id: networkAdapter

        runtime: networkRuntimeLoader.status === Loader.Ready ? networkRuntimeLoader.item : unavailableNetworkRuntime
    }
    NetworkFeatures.NetworkController {
        id: networkController

        adapter: networkAdapter
        detailVisible: controlCenterHosts.networkPageOpenCount > 0
    }
    NotificationServices.UnavailableNotificationRuntime {
        id: unavailableNotificationRuntime
    }
    Loader {
        id: notificationRuntimeLoader

        // Q-115 still blocks production ownership. Ordinary development must
        // never instantiate the pinned server because it retries bus ownership.
        active: root.notificationOwnershipEnabled

        sourceComponent: Component {
            NotificationServices.QuickshellNotificationRuntime {
            }
        }
    }
    NotificationServices.NotificationPolicy {
        id: notificationPolicy
    }
    NotificationServices.NotificationHistory {
        id: notificationHistory
    }
    NotificationServices.NotificationService {
        id: notificationService

        fullscreen: hyprlandAdapter.focusedWindow?.fullscreen === true
        history: notificationHistory
        policy: notificationPolicy
        runtime: notificationRuntimeLoader.status === Loader.Ready ? notificationRuntimeLoader.item : unavailableNotificationRuntime
    }
    NotificationServices.NotificationSoundPolicy {
        id: notificationSoundPolicy
    }
    TrayServices.UnavailableTrayRuntime {
        id: unavailableTrayRuntime
    }
    Loader {
        id: trayRuntimeLoader

        // Reserved for a controlled isolated session until Q-115 defines the
        // production watcher/host handoff. Ordinary development stays non-owning.
        active: root.trayOwnershipEnabled

        sourceComponent: Component {
            TrayServices.QuickshellTrayRuntime {
            }
        }
    }
    TrayServices.TrayAdapter {
        id: trayAdapter

        runtime: trayRuntimeLoader.status === Loader.Ready ? trayRuntimeLoader.item : unavailableTrayRuntime
    }
    TrayFeatures.TrayController {
        id: trayController

        adapter: trayAdapter
    }
    Core.SurfaceCoordinator {
        id: surfaceCoordinator

        monitorRegistry: monitorRegistry
    }
    FeedbackServices.OsdService {
        id: osdService
    }
    FeedbackServices.ToastService {
        id: toastService
    }
    FeedbackFeatures.FeedbackController {
        id: feedbackController

        dnd: notificationService.dnd
        fullscreen: hyprlandAdapter.focusedWindow?.fullscreen === true
        osdService: osdService
        surfaceCoordinator: surfaceCoordinator
        toastService: toastService
    }
    NotificationFeatures.NotificationController {
        id: notificationController

        historyVisible: controlCenterHosts.notificationViewOpenCount > 0
        monitorRegistry: monitorRegistry
        service: notificationService
    }
    Core.CommandRegistry {
        id: shellCommandRegistry

        builtinDefinitions: BrightnessCommands.definitions().concat(ResourceCommands.definitions()).concat(NotificationSoundCommands.definitions())
        configService: configService
    }
    Loader {
        id: dailyBarControllers

        active: !root.usesFixtureMonitorBackend

        sourceComponent: Component {
            BarFeatures.DailyBarControllerSet {
                activeBarConfig: root.activeBarConfig
                activeIntegrationsConfig: root.activeIntegrationsConfig
                activeShellConfig: root.activeShellConfig
                commandRegistry: shellCommandRegistry
                feedbackController: feedbackController
                networkController: networkController
                surfaceCoordinator: surfaceCoordinator
            }
        }
    }
    NotificationServices.CommandRegistryNotificationSoundRuntime {
        id: notificationSoundRuntime

        commandRegistry: shellCommandRegistry
    }
    NotificationServices.NotificationSoundService {
        id: notificationSoundService

        notificationService: notificationService
        policy: notificationSoundPolicy
        runtime: notificationSoundRuntime
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
        feedbackController: feedbackController
    }
    TelemetryServices.UnavailableTelemetryRuntime {
        id: unavailableTelemetryRuntime
    }
    Loader {
        id: telemetryRuntimeLoader

        active: !root.usesFixtureMonitorBackend

        sourceComponent: Component {
            TelemetryServices.ProcTelemetryRuntime {
                commandRegistry: shellCommandRegistry
                detailIntervalMs: Math.max(250, Math.floor((root.networkSpeedConfig?.updateIntervalMs ?? 1000) / 2))
                summaryIntervalMs: Math.max(500, root.networkSpeedConfig?.updateIntervalMs ?? 1000)
            }
        }
    }
    TelemetryServices.ThroughputAdapter {
        id: throughputAdapter

        runtime: telemetryRuntimeLoader.status === Loader.Ready ? telemetryRuntimeLoader.item : unavailableTelemetryRuntime
        smoothingWindow: Math.max(1, root.networkSpeedConfig?.smoothingWindow ?? 3)
    }
    TelemetryServices.ResourceSummaryAdapter {
        id: resourceSummaryAdapter

        runtime: telemetryRuntimeLoader.status === Loader.Ready ? telemetryRuntimeLoader.item : unavailableTelemetryRuntime
    }
    TelemetryFeatures.ThroughputController {
        id: throughputController

        adapter: throughputAdapter
        base: root.networkSpeedConfig?.base ?? 1000
        unit: root.networkSpeedConfig?.unit ?? "bytes"
        zeroFormat: root.networkSpeedConfig?.zeroFormat ?? "0K"
    }
    TelemetryFeatures.ResourceSummaryController {
        id: resourceSummaryController

        adapter: resourceSummaryAdapter
        commandRegistry: shellCommandRegistry
        detailVisible: surfaceCoordinator.activePopoverId === "resources.summary"
        feedbackController: feedbackController
    }
    // Loader.item is intentionally dynamic at this lazy fixture boundary.
    // qmllint disable missing-property
    Surfaces.BarHostSet {
        id: barHosts

        audioController: audioController
        barConfig: configService.active?.bar ?? null
        batteryController: root.usesFixtureMonitorBackend ? null : batteryController
        calendarController: dailyBarControllers.item !== null ? dailyBarControllers.item["calendarController"] : null
        contextController: dailyBarControllers.item !== null ? dailyBarControllers.item["contextController"] : null
        dateTimeController: dailyBarControllers.item !== null ? dailyBarControllers.item["dateTimeController"] : null
        fixtureWindow: root.usesFixtureMonitorBackend
        monitorRegistry: monitorRegistry
        resourceController: root.usesFixtureMonitorBackend ? null : resourceSummaryController
        surfaceCoordinator: surfaceCoordinator
        theme: themeManager.active
        throughputController: root.usesFixtureMonitorBackend ? null : throughputController
        trayController: root.usesFixtureMonitorBackend ? null : trayController
        vicinaeAdapter: dailyBarControllers.item !== null ? dailyBarControllers.item["vicinaeAdapter"] : null
        workspaceBackend: root.usesFixtureMonitorBackend ? fixtureWorkspaceAdapter : hyprlandAdapter
        workspaceConfig: configService.active?.workspaces ?? null
    }
    // qmllint enable missing-property
    Surfaces.ControlCenterHostSet {
        id: controlCenterHosts

        audioController: audioController
        bluetoothController: root.usesFixtureMonitorBackend ? null : bluetoothController
        brightnessController: root.usesFixtureMonitorBackend ? null : brightnessController
        commandRegistry: shellCommandRegistry
        controlCenterConfig: configService.active?.controlCenter ?? null
        feedbackController: feedbackController
        fixtureWindow: root.usesFixtureMonitorBackend
        monitorRegistry: monitorRegistry
        networkController: root.usesFixtureMonitorBackend ? null : networkController
        notificationController: notificationController
        surfaceCoordinator: surfaceCoordinator
        theme: themeManager.active
    }
    Surfaces.NotificationPopupHostSet {
        controller: notificationController
        fixtureWindow: root.usesFixtureMonitorBackend
        monitorRegistry: monitorRegistry
        theme: themeManager.active
    }
    Surfaces.FeedbackHostSet {
        fixtureWindow: root.usesFixtureMonitorBackend
        monitorRegistry: monitorRegistry
        osdService: osdService
        theme: themeManager.active
        toastService: toastService
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
        bluetoothProvider: bluetoothAdapter
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
        networkProvider: networkAdapter
        notificationProvider: notificationService
        resourceProvider: resourceSummaryAdapter
        shellState: shellState
        surfaceCoordinator: surfaceCoordinator
        surfaceVisible: diagnosticSurface.visible
        themeManager: themeManager
        throughputProvider: throughputAdapter
        trayProvider: trayAdapter
    }
    Ipc.ShellIpc {
        barHostProvider: barHosts
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
