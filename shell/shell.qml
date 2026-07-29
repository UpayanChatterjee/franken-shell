import QtQuick
import Quickshell
import "core" as Core
import "surfaces" as Surfaces

ShellRoot {
    id: root

    readonly property string mode: String(Quickshell.env("FRANKEN_SHELL_MODE") ?? "development")
    property string startupState: "Bootstrapping"

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
            "theme": "FallbackTheme"
        });
        root.startupState = "SurfacesReady";
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
    Loader {
        id: monitorBackendLoader

        active: root.mode !== "mock"

        sourceComponent: Component {
            Core.HyprlandMonitorAdapter {
            }
        }
    }
    Core.MonitorRegistry {
        id: monitorRegistry

        backend: monitorBackendLoader.status === Loader.Ready ? monitorBackendLoader.item : unavailableMonitorBackend
        configService: configService
    }
    Core.CommandRegistry {
        id: commandRegistry

        configService: configService
    }
    Core.Diagnostics {
        commandRegistry: commandRegistry
        configHelperExecutable: configHelperClient.resolvedHelperExecutable
        configHelperResolution: configHelperClient.resolutionPolicy
        configHelperState: configHelperClient.state
        configService: configService
        mode: root.mode
        monitorRegistry: monitorRegistry
        startupState: root.startupState
        surfaceVisible: diagnosticSurface.visible
    }
    Surfaces.DiagnosticSurface {
        id: diagnosticSurface

        mode: root.mode
        startupState: root.startupState
    }
}
