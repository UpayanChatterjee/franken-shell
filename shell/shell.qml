import QtQuick
import Quickshell
import "core" as Core
import "surfaces" as Surfaces

ShellRoot {
    id: root

    property string startupState: "Bootstrapping"
    readonly property string mode: String(Quickshell.env("FRANKEN_SHELL_MODE") ?? "development")

    settings.watchFiles: false

    Core.ConfigHelperClient {
        id: configHelperClient
    }

    Core.Diagnostics {
        mode: root.mode
        startupState: root.startupState
        surfaceVisible: diagnosticSurface.visible
        configHelperState: configHelperClient.state
        configHelperResolution: configHelperClient.resolutionPolicy
        configHelperExecutable: configHelperClient.resolvedHelperExecutable
    }

    Surfaces.DiagnosticSurface {
        id: diagnosticSurface

        mode: root.mode
        startupState: root.startupState
    }

    Component.onCompleted: {
        Core.Logger.info("core", "startup", {
            mode: root.mode,
            projectVersion: Core.ProjectInfo.projectVersion,
            shellDir: Quickshell.shellDir
        });
        Core.Logger.info("config", "built-in-defaults-active", {
            configPath: Core.ProjectInfo.configPath,
            schemaVersion: Core.ProjectInfo.configSchemaVersion
        });
        Core.Logger.info("theme", "fallback-theme-active", {
            theme: "FallbackTheme"
        });
        root.startupState = "SurfacesReady";
        Core.Logger.info("surfaces", "diagnostic-surface-ready", {
            visible: diagnosticSurface.visible
        });
    }
}
