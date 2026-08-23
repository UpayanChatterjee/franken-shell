import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root

    property var audioProvider: null
    required property var barHostProvider
    property var batteryProvider: null
    property var bluetoothProvider: null
    property var brightnessProvider: null
    required property var capabilityRegistry
    required property var commandRegistry
    required property string configHelperExecutable
    required property string configHelperResolution
    required property string configHelperState
    required property var configService
    required property var controlCenterHostProvider
    required property var diagnosticRegistry
    property var hyprlandProvider: null
    required property string mode
    required property var monitorRegistry
    property var networkProvider: null
    property var resourceProvider: null
    required property var shellState
    required property var surfaceCoordinator
    required property bool surfaceVisible
    required property var themeManager
    property var throughputProvider: null

    function summaryObject(): var {
        const bluetooth = root.bluetoothProvider?.diagnosticsSummary?.() ?? {};
        const config = root.configService.configurationSummary();
        const monitors = root.monitorRegistry.diagnosticsSummary();
        const network = root.networkProvider?.diagnosticsSummary?.() ?? {};
        const commands = root.commandRegistry.registrySummary();
        const controlCenterHosts = root.controlCenterHostProvider.summary();
        const barHosts = root.barHostProvider.summary();
        const capabilities = root.capabilityRegistry.summary();
        const diagnostics = root.diagnosticRegistry.summary();
        const audio = root.audioProvider?.diagnosticsSummary?.() ?? {};
        const battery = root.batteryProvider?.diagnosticsSummary?.() ?? {};
        const brightness = root.brightnessProvider?.diagnosticsSummary?.() ?? {};
        const hyprland = root.hyprlandProvider?.diagnosticsSummary?.() ?? {};
        const resource = root.resourceProvider?.diagnosticsSummary?.() ?? {};
        const shell = root.shellState.summary();
        const surfaces = root.surfaceCoordinator.summary();
        const theme = root.themeManager.summary();
        const throughput = root.throughputProvider?.diagnosticsSummary?.() ?? {};
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
            "bluetoothAvailable": bluetooth.available === true,
            "bluetoothConnectionState": String(bluetooth.connectionState ?? "unavailable"),
            "bluetoothStateStale": bluetooth.stale === true,
            "bluetoothStatus": String(bluetooth.status ?? "unavailable"),
            "bluetoothPowered": bluetooth.powered === true,
            "bluetoothDiscoveryState": String(bluetooth.discoveryState ?? "idle"),
            "bluetoothAdapterCount": Number(bluetooth.adapterCount ?? 0),
            "bluetoothDeviceCount": Number(bluetooth.deviceCount ?? 0),
            "bluetoothPairedDeviceCount": Number(bluetooth.pairedDeviceCount ?? 0),
            "bluetoothConnectedDeviceCount": Number(bluetooth.connectedDeviceCount ?? 0),
            "bluetoothAvailableDeviceCount": Number(bluetooth.availableDeviceCount ?? 0),
            "bluetoothNonAudioConnectedDeviceCount": Number(bluetooth.nonAudioConnectedDeviceCount ?? 0),
            "bluetoothPairingRequestActive": bluetooth.pairingRequestActive === true,
            "bluetoothPairingRequestKind": String(bluetooth.pairingRequestKind ?? "none"),
            "bluetoothPendingTaskCount": Number(bluetooth.pendingTaskCount ?? 0),
            "bluetoothLastError": String(bluetooth.lastError ?? ""),
            "networkAvailable": network.available === true,
            "networkConnectionState": String(network.connectionState ?? "unavailable"),
            "networkStateStale": network.stale === true,
            "networkStatus": String(network.status ?? "unavailable"),
            "networkConnectivity": String(network.connectivity ?? "unknown"),
            "networkWifiEnabled": network.wifiEnabled === true,
            "networkWifiHardwareAvailable": network.wifiHardwareAvailable === true,
            "networkScanState": String(network.scanState ?? "idle"),
            "networkVisibleCount": Number(network.visibleNetworkCount ?? 0),
            "networkSavedCount": Number(network.savedNetworkCount ?? 0),
            "networkEthernetCount": Number(network.ethernetDeviceCount ?? 0),
            "networkActiveConnectionPresent": network.activeConnectionPresent === true,
            "networkPendingTaskCount": Number(network.pendingTaskCount ?? 0),
            "networkLastError": String(network.lastError ?? ""),
            "hyprlandAvailable": hyprland.available === true,
            "hyprlandConnectionState": String(hyprland.connectionState ?? "unavailable"),
            "hyprlandStateStale": hyprland.stale === true,
            "hyprlandWorkspaceCount": Number(hyprland.workspaceCount ?? 0),
            "hyprlandFocusedWindowPresent": hyprland.focusedWindowPresent === true,
            "hyprlandUsingLua": hyprland.usingLua === true,
            "hyprlandTestedVersion": String(hyprland.testedVersion ?? ""),
            "hyprlandMalformedEventCount": Number(hyprland.malformedEventCount ?? 0),
            "hyprlandStaleSnapshotCount": Number(hyprland.staleSnapshotCount ?? 0),
            "hyprlandLastEventName": String(hyprland.lastEventName ?? ""),
            "hyprlandUnknownEventCount": Number(hyprland.unknownEventCount ?? 0),
            "hyprlandLastError": String(hyprland.lastError ?? ""),
            "audioAvailable": audio.available === true,
            "audioConnectionState": String(audio.connectionState ?? "unavailable"),
            "audioStateStale": audio.stale === true,
            "audioOutputDeviceCount": Number(audio.outputDeviceCount ?? 0),
            "audioInputDeviceCount": Number(audio.inputDeviceCount ?? 0),
            "audioPlaybackStreamCount": Number(audio.playbackStreamCount ?? 0),
            "audioCaptureStreamCount": Number(audio.captureStreamCount ?? 0),
            "audioActiveCaptureState": String(audio.activeCaptureState ?? "unknown"),
            "audioDefaultOutputPresent": audio.defaultOutputPresent === true,
            "audioDefaultInputPresent": audio.defaultInputPresent === true,
            "audioOutputCategory": String(audio.outputCategory ?? "unknown"),
            "audioMasterMuted": audio.masterMuted === true,
            "audioMicrophoneMuted": audio.microphoneMuted === true,
            "audioLastError": String(audio.lastError ?? ""),
            "batteryAvailable": battery.available === true,
            "batteryServiceAvailability": String(battery.serviceAvailability ?? "unavailable"),
            "batteryAvailability": String(battery.batteryAvailability ?? "unknown"),
            "batteryStateStale": battery.stale === true,
            "batteryPercentage": Number(battery.percentage ?? -1),
            "batteryChargingState": String(battery.chargingState ?? "unknown"),
            "batteryPowerSource": String(battery.powerSource ?? "unknown"),
            "batteryTimeEstimateState": String(battery.timeEstimateState ?? "unavailable"),
            "batteryLastError": String(battery.lastError ?? ""),
            "brightnessAvailable": brightness.available === true,
            "brightnessConnectionState": String(brightness.connectionState ?? "unavailable"),
            "brightnessStateStale": brightness.stale === true,
            "brightnessTargetCount": Number(brightness.targetCount ?? 0),
            "brightnessDefaultTargetPresent": brightness.defaultTargetPresent === true,
            "brightnessOperationState": String(brightness.operationState ?? "idle"),
            "brightnessLastError": String(brightness.lastError ?? ""),
            "throughputAvailable": throughput.available === true,
            "throughputConnectionState": String(throughput.connectionState ?? "unavailable"),
            "throughputStateStale": throughput.stale === true,
            "throughputActiveInterfaceCount": Number(throughput.activeInterfaceCount ?? 0),
            "throughputRawDownloadRate": Number(throughput.rawDownloadRate ?? 0),
            "throughputRawUploadRate": Number(throughput.rawUploadRate ?? 0),
            "throughputSmoothedDownloadRate": Number(throughput.smoothedDownloadRate ?? 0),
            "throughputSmoothedUploadRate": Number(throughput.smoothedUploadRate ?? 0),
            "throughputLastError": String(throughput.lastError ?? ""),
            "resourceAvailable": resource.available === true,
            "resourceConnectionState": String(resource.connectionState ?? "unavailable"),
            "resourceStateStale": resource.stale === true,
            "resourceMemoryPercent": Number(resource.memoryPercent ?? -1),
            "resourceCpuPercent": Number(resource.cpuPercent ?? -1),
            "resourceStorageAvailable": resource.storageAvailable === true,
            "resourcePollIntervalMs": Number(resource.pollIntervalMs ?? 0),
            "resourceDetailActive": resource.detailActive === true,
            "resourceLastError": String(resource.lastError ?? ""),
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
            "controlCenterHostCount": controlCenterHosts.hostCount,
            "controlCenterResolvedHostCount": controlCenterHosts.resolvedHostCount,
            "controlCenterOpenHostCount": controlCenterHosts.openHostCount,
            "controlCenterVisibleScrimCount": controlCenterHosts.visibleScrimCount,
            "controlCenterPrimitive": controlCenterHosts.primitive,
            "controlCenterHosts": controlCenterHosts.hosts,
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
        function audioStatus(): string {
            return JSON.stringify(root.audioProvider?.diagnosticsSummary?.() ?? {
                "available": false,
                "connectionState": "unavailable"
            });
        }
        function bluetoothStatus(): string {
            return JSON.stringify(root.bluetoothProvider?.diagnosticsSummary?.() ?? {
                "available": false,
                "connectionState": "unavailable"
            });
        }
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
        function hyprlandStatus(): string {
            return JSON.stringify(root.hyprlandProvider?.diagnosticsSummary?.() ?? {
                "available": false,
                "connectionState": "unavailable"
            });
        }
        function monitorStatus(): string {
            return JSON.stringify(root.monitorRegistry.diagnosticsSummary());
        }
        function networkStatus(): string {
            return JSON.stringify(root.networkProvider?.diagnosticsSummary?.() ?? {
                "available": false,
                "connectionState": "unavailable"
            });
        }
        function powerStatus(): string {
            return JSON.stringify({
                "battery": root.batteryProvider?.diagnosticsSummary?.() ?? {
                    "available": false,
                    "serviceAvailability": "unavailable"
                },
                "brightness": root.brightnessProvider?.diagnosticsSummary?.() ?? {
                    "available": false,
                    "connectionState": "unavailable"
                }
            });
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
        function telemetryStatus(): string {
            return JSON.stringify({
                "throughput": root.throughputProvider?.diagnosticsSummary?.() ?? {
                    "available": false,
                    "connectionState": "unavailable"
                },
                "resources": root.resourceProvider?.diagnosticsSummary?.() ?? {
                    "available": false,
                    "connectionState": "unavailable"
                }
            });
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
