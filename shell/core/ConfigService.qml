import "ConfigDefaults.js" as ConfigDefaults
import "ConfigPathResolver.js" as ConfigPathResolver
import "ConfigSnapshotBuilder.js" as ConfigSnapshotBuilder
import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root

    required property QtObject helperClient
    readonly property string _runtimeMode: String(Quickshell.env("FRANKEN_SHELL_MODE") ?? "")
    readonly property bool _fixtureOverrideAllowed: root._runtimeMode === "config-demo" || root._runtimeMode === "config-service-test"
    readonly property string authoritativePath: ConfigPathResolver.resolve(String(Quickshell.env("XDG_CONFIG_HOME") ?? ""), String(Quickshell.env("HOME") ?? ""), String(Quickshell.env("FRANKEN_CONFIG_FIXTURE_PATH") ?? ""), root._fixtureOverrideAllowed)
    readonly property ConfigSnapshot active: activeStorage.value
    readonly property string activeSource: active === null ? "none" : active.source
    readonly property int activeSchemaVersion: active === null ? 0 : active.schemaVersion
    readonly property double activeGeneration: active === null ? -1 : active.requestGeneration
    readonly property bool migrationInMemory: active !== null && active.migratedInMemory
    readonly property bool watchEnabled: active === null || active.shell.reload.watchConfig
    readonly property int warningCount: state.warnings.length
    readonly property int errorCount: state.errors.length
    readonly property string health: state.health
    readonly property string sourceState: state.sourceState
    readonly property string reloadState: state.reloadState
    readonly property string helperTransportHealth: state.helperTransportHealth
    readonly property string lastSuccessfulValidation: state.lastSuccessfulValidation
    readonly property double lastRejectedGeneration: state.lastRejectedGeneration
    readonly property var warnings: state.warnings
    readonly property var errors: state.errors
    readonly property int activationSequence: state.activationSequence

    signal activated(var snapshot)
    signal candidateRejected(double generation, string category)

    function requestReload() : string {
        controller._scheduleRead(0, "explicit");
        return "configuration reload requested";
    }

    function configurationSummary() {
        return {
            "apiVersion": ProjectInfo.ipcVersion,
            "activeSource": root.activeSource,
            "authoritativePath": root.authoritativePath,
            "activeSchemaVersion": root.activeSchemaVersion,
            "activeGeneration": root.activeGeneration,
            "health": root.health,
            "sourceState": root.sourceState,
            "reloadState": root.reloadState,
            "lastSuccessfulValidation": root.lastSuccessfulValidation,
            "lastRejectedGeneration": root.lastRejectedGeneration,
            "warningCount": root.warningCount,
            "errorCount": root.errorCount,
            "helperTransportHealth": root.helperTransportHealth,
            "migrationInMemory": root.migrationInMemory,
            "watchEnabled": root.watchEnabled,
            "activationSequence": root.activationSequence
        };
    }

    Component.onCompleted: {
        state.helperClient = root.helperClient;
        root.helperClient = null;
        const defaults = controller._createSnapshot(ConfigDefaults.normalized, 0, "builtInDefaults", "defaultsOnly", false, ConfigSnapshotBuilder.deepFreeze([]));
        controller._publish(defaults);
        state.sourceRevision = 1;
        state.initialized = true;
        if (root.authoritativePath.length === 0) {
            controller._rejectWithoutCandidate("pathResolutionFailure", "The configuration path could not be resolved because HOME is unavailable.");
        } else {
            state.readRequested = true;
            state.readInFlight = true;
            state.readRevision = state.sourceRevision;
            state.pendingReloadReason = "initial";
            state.reloadState = "loading";
        }
    }

    QtObject {
        id: state

        property QtObject helperClient: root.helperClient
        property string health: "healthy"
        property string sourceState: "defaultsOnly"
        property string reloadState: "initializing"
        property string helperTransportHealth: "unknown"
        property string lastSuccessfulValidation: ""
        property double lastRejectedGeneration: -1
        property var warnings: ConfigSnapshotBuilder.deepFreeze([])
        property var errors: ConfigSnapshotBuilder.deepFreeze([])
        property int activationSequence: 0
        property double latestIssuedGeneration: 0
        property double candidateGeneration: -1
        property int candidateRevision: -1
        property string candidateSourceText: ""
        property string lastCompletedSourceText: ""
        property int sourceRevision: 0
        property bool readRequested: false
        property bool readInFlight: false
        property bool readAfterCurrent: false
        property int readRevision: -1
        property string pendingReloadReason: ""
        property bool initialized: false
        property var localDiagnostic: (code, message) => {
            return ({
                "severity": "error",
                "code": code,
                "message": message,
                "configurationPath": null,
                "source": root.authoritativePath,
                "line": null,
                "column": null,
                "repairHint": null
            });
        }
    }

    QtObject {
        id: controller

        function _scheduleRead(delayMs: int, reason: string) {
            state.sourceRevision += 1;
            state.candidateGeneration = -1;
            state.candidateRevision = -1;
            state.candidateSourceText = "";
            state.helperClient.cancel();
            state.pendingReloadReason = reason;
            state.reloadState = state.health === "degraded" ? "recovering" : "debouncing";
            reloadTimer.interval = Math.max(0, delayMs);
            reloadTimer.restart();
        }

        function _beginRead() {
            if (root.authoritativePath.length === 0) {
                controller._rejectWithoutCandidate("pathResolutionFailure", "The configuration path could not be resolved because HOME is unavailable.");
                return ;
            }
            if (state.readInFlight) {
                state.readAfterCurrent = true;
                return ;
            }
            state.readRequested = true;
            state.readInFlight = true;
            state.readRevision = state.sourceRevision;
            state.reloadState = "loading";
            configFile.reload();
        }

        function _handleFileLoaded(sourceText: string) {
            if (!state.readRequested)
                return ;

            const completedRevision = state.readRevision;
            state.readRequested = false;
            state.readInFlight = false;
            state.readRevision = -1;
            if (completedRevision !== state.sourceRevision) {
                if (state.readAfterCurrent) {
                    state.readAfterCurrent = false;
                    reloadTimer.interval = 0;
                    reloadTimer.restart();
                }
                return ;
            }
            const reason = state.pendingReloadReason;
            state.pendingReloadReason = "";
            if (reason === "watch" && sourceText === state.lastCompletedSourceText) {
                state.reloadState = "idle";
                return ;
            }
            const generation = controller._nextGeneration();
            state.candidateGeneration = generation;
            state.candidateRevision = state.sourceRevision;
            state.candidateSourceText = sourceText;
            state.sourceState = state.health === "degraded" ? "recovering" : "validating";
            state.reloadState = "validating";
            state.helperClient.validateAndNormalize(generation, root.authoritativePath, sourceText);
        }

        function _handleFileFailure(error) {
            if (!state.readRequested)
                return ;

            const completedRevision = state.readRevision;
            state.readRequested = false;
            state.readInFlight = false;
            state.readRevision = -1;
            if (completedRevision !== state.sourceRevision) {
                if (state.readAfterCurrent) {
                    state.readAfterCurrent = false;
                    reloadTimer.interval = 0;
                    reloadTimer.restart();
                }
                return ;
            }
            if (error === FileViewError.FileNotFound) {
                controller._handleMissingFile();
                return ;
            }
            controller._rejectWithoutCandidate("fileReadFailure", "The configuration file could not be read: " + FileViewError.toString(error));
        }

        function _handleMissingFile() {
            state.candidateGeneration = -1;
            state.candidateRevision = -1;
            state.candidateSourceText = "";
            state.lastCompletedSourceText = "";
            state.warnings = ConfigSnapshotBuilder.deepFreeze([]);
            state.errors = ConfigSnapshotBuilder.deepFreeze([]);
            state.health = "healthy";
            state.sourceState = "defaultsOnly";
            state.reloadState = "idle";
            state.helperTransportHealth = "notRequired";
            if (root.active !== null && root.active.source === "userFile") {
                const generation = controller._nextGeneration();
                const candidate = controller._createSnapshot(ConfigDefaults.normalized, generation, "builtInDefaults", "defaultsOnly", false, []);
                controller._publish(candidate);
            }
        }

        function _handleHelperResult(result) {
            if (!controller._isObject(result) || !controller._isNonNegativeInteger(result.generation) || result.generation !== state.candidateGeneration || state.candidateRevision !== state.sourceRevision) {
                Logger.info("config", "service-result-discarded", {
                    "generation": controller._isObject(result) ? result.generation : null,
                    "expectedGeneration": state.candidateGeneration,
                    "sourceRevision": state.sourceRevision,
                    "candidateRevision": state.candidateRevision
                });
                return ;
            }
            const generation = result.generation;
            state.lastCompletedSourceText = state.candidateSourceText;
            state.candidateGeneration = -1;
            state.candidateRevision = -1;
            state.candidateSourceText = "";
            if (typeof result.success !== "boolean" || !Array.isArray(result.warnings) || !Array.isArray(result.errors)) {
                controller._rejectCandidate(generation, "malformedHelperResult", [], [state.localDiagnostic("CONFIG_HELPER_RESULT_MALFORMED", "The helper client emitted a malformed result envelope.")], "healthy");
                return ;
            }
            if (result.transportFailure !== null) {
                const category = controller._isObject(result.transportFailure) && typeof result.transportFailure.category === "string" ? result.transportFailure.category : "transportFailure";
                controller._rejectCandidate(generation, category, [], [state.localDiagnostic("CONFIG_HELPER_TRANSPORT_FAILURE", "Configuration validation could not complete because the helper transport failed.")], category === "helperUnavailable" ? "unavailable" : "failed");
                return ;
            }
            let candidateWarnings;
            let candidateErrors;
            try {
                candidateWarnings = ConfigSnapshotBuilder.sanitizeDiagnostics(result.warnings);
                candidateErrors = ConfigSnapshotBuilder.sanitizeDiagnostics(result.errors);
            } catch (error) {
                controller._rejectCandidate(generation, "malformedDiagnostics", [], [state.localDiagnostic("CONFIG_HELPER_DIAGNOSTICS_MALFORMED", "The helper client emitted malformed configuration diagnostics.")], "healthy");
                return ;
            }
            if (!result.success) {
                controller._rejectCandidate(generation, "validationFailure", candidateWarnings, candidateErrors, "healthy");
                return ;
            }
            if (!controller._isNonNegativeInteger(result.effectiveSchemaVersion) || result.effectiveSchemaVersion !== ProjectInfo.configSchemaVersion || typeof result.migrationOccurred !== "boolean") {
                controller._rejectCandidate(generation, "malformedHelperResult", candidateWarnings, [state.localDiagnostic("CONFIG_HELPER_RESULT_MALFORMED", "The helper result contained invalid schema or migration metadata.")], "healthy");
                return ;
            }
            let candidate;
            try {
                candidate = controller._createSnapshot(result.normalizedConfiguration, generation, "userFile", result.migrationOccurred ? "migratedInMemory" : "valid", result.migrationOccurred, candidateWarnings);
            } catch (error) {
                controller._rejectCandidate(generation, "candidateConstructionFailure", candidateWarnings, [state.localDiagnostic("CONFIG_SNAPSHOT_INVALID", "The normalized configuration could not form a complete typed snapshot.")], "healthy");
                return ;
            }
            state.warnings = candidateWarnings;
            state.errors = ConfigSnapshotBuilder.deepFreeze([]);
            state.health = "healthy";
            state.sourceState = result.migrationOccurred ? "migratedInMemory" : "valid";
            state.reloadState = "idle";
            state.helperTransportHealth = "healthy";
            state.lastSuccessfulValidation = new Date().toISOString();
            controller._publish(candidate);
        }

        function _createSnapshot(normalized, generation: double, source: string, sourceState: string, migratedInMemory: bool, snapshotWarnings) : ConfigSnapshot {
            const canonical = ConfigSnapshotBuilder.build(normalized);
            const nextSequence = state.activationSequence + 1;
            const candidate = snapshotComponent.createObject(root, {
                "_source": canonical,
                "_metadata": ConfigSnapshotBuilder.deepFreeze({
                    "requestGeneration": generation,
                    "source": source,
                    "sourceState": sourceState,
                    "migratedInMemory": migratedInMemory,
                    "warnings": snapshotWarnings,
                    "activationSequence": nextSequence,
                    "activatedAt": new Date().toISOString()
                })
            });
            if (candidate === null || candidate.schemaVersion !== ProjectInfo.configSchemaVersion || candidate.shell === null || candidate.appearance === null || candidate.bar === null || candidate.controlCenter === null || candidate.workspaces === null || candidate.integrations === null || candidate.commands === null) {
                if (candidate !== null)
                    candidate.destroy();

                throw new Error("typed snapshot construction failed");
            }
            return candidate;
        }

        function _publish(candidate: ConfigSnapshot) {
            const previous = activeStorage.value;
            activeStorage.value = candidate;
            state.activationSequence = candidate.activationSequence;
            root.activated(candidate);
            Logger.info("config", "snapshot-activated", {
                "generation": candidate.requestGeneration,
                "source": candidate.source,
                "schemaVersion": candidate.schemaVersion,
                "migratedInMemory": candidate.migratedInMemory,
                "warningCount": candidate.warnings.count,
                "activationSequence": candidate.activationSequence
            });
            if (previous !== null)
                previous.destroy();

        }

        function _rejectCandidate(generation: double, category: string, candidateWarnings, candidateErrors, transportHealth: string) {
            state.warnings = ConfigSnapshotBuilder.deepFreeze(candidateWarnings);
            state.errors = ConfigSnapshotBuilder.deepFreeze(candidateErrors);
            state.lastRejectedGeneration = generation;
            state.health = "degraded";
            if (root.active !== null && root.active.source === "userFile")
                state.sourceState = "previousValidRetained";
            else if (category === "validationFailure")
                state.sourceState = "invalidColdStart";
            else
                state.sourceState = category;
            state.reloadState = "idle";
            state.helperTransportHealth = transportHealth;
            root.candidateRejected(generation, category);
            Logger.warning("config", "candidate-rejected", {
                "generation": generation,
                "category": category,
                "retainedGeneration": root.activeGeneration,
                "warningCount": root.warningCount,
                "errorCount": root.errorCount
            });
        }

        function _rejectWithoutCandidate(category: string, message: string) {
            state.health = "degraded";
            state.sourceState = category;
            state.reloadState = "idle";
            state.errors = ConfigSnapshotBuilder.deepFreeze([state.localDiagnostic("CONFIG_FILE_LIFECYCLE_FAILURE", message)]);
            Logger.warning("config", "file-lifecycle-failed", {
                "category": category,
                "retainedGeneration": root.activeGeneration
            });
        }

        function _nextGeneration() : double {
            state.latestIssuedGeneration += 1;
            return state.latestIssuedGeneration;
        }

        function _isObject(value) : bool {
            return value !== null && typeof value === "object" && !Array.isArray(value);
        }

        function _isNonNegativeInteger(value) : bool {
            return typeof value === "number" && isFinite(value) && value >= 0 && Math.floor(value) === value;
        }

    }

    Component {
        id: snapshotComponent

        ConfigSnapshot {
        }

    }

    QtObject {
        id: activeStorage

        property ConfigSnapshot value: null
    }

    Timer {
        id: reloadTimer

        repeat: false
        onTriggered: controller._beginRead()
    }

    FileView {
        id: configFile

        path: state.initialized ? root.authoritativePath : ""
        preload: true
        printErrors: false
        watchChanges: root.watchEnabled
        onLoaded: controller._handleFileLoaded(text())
        onLoadFailed: (error) => {
            return controller._handleFileFailure(error);
        }
        onFileChanged: {
            if (root.watchEnabled)
                controller._scheduleRead(Math.max(1, root.active.shell.reload.debounceMs), "watch");

        }
    }

    FileView {
        id: configWatchAnchor

        path: state.initialized && root.watchEnabled ? ConfigPathResolver.watchAnchor(root.authoritativePath) : ""
        preload: false
        printErrors: false
        watchChanges: root.watchEnabled
        onFileChanged: controller._scheduleRead(Math.max(1, root.active.shell.reload.debounceMs), "watch")
    }

    Connections {
        function onResultReady(result) {
            controller._handleHelperResult(result);
        }

        target: state.helperClient
    }

}
