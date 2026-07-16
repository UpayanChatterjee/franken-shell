import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root

    property int timeoutMs: 5000
    property int maxStdoutCharacters: 4194304
    property int maxStderrCharacters: 16384
    property string helperExecutableOverride: ""
    property var helperArguments: []

    readonly property string resolvedHelperExecutable: helperExecutableOverride.length > 0
        ? helperExecutableOverride
        : ProjectInfo.configHelperDevelopmentExecutable.toString()
    readonly property string resolutionPolicy: helperExecutableOverride.length > 0
        ? "override"
        : "development-build"
    readonly property bool busy: root._activeRequest !== null || root._pendingRequest !== null
    readonly property double latestGeneration: root._latestGeneration
    readonly property string state: root._latestState

    signal resultReady(var result)
    signal requestStateChanged(double generation, string state)

    property var _activeRequest: null
    property var _pendingRequest: null
    property double _latestGeneration: -1
    property string _latestState: "idle"
    property bool _processStarted: false
    property bool _terminalResultPublished: false
    property string _suppressionReason: ""
    property string _stdoutText: ""
    property bool _stderrPresent: false
    property int _stderrLength: 0
    property var _decodedResponse: null
    property string _decodeFailureReason: ""

    function validateAndNormalize(
        generation: double,
        sourceIdentifier: string,
        tomlSource: string
    ) {
        if (!root._isNonNegativeInteger(generation)
                || generation <= root._latestGeneration) {
            Logger.warning("config", "helper-request-rejected", {
                generation: generation,
                operation: "validateAndNormalize",
                category: "staleOrDuplicateGeneration"
            });
            root.requestStateChanged(generation, "superseded");
            return;
        }

        const request = {
            generation: generation,
            sourceIdentifier: sourceIdentifier,
            tomlSource: tomlSource,
            enqueuedAt: Date.now(),
            startedAt: 0
        };

        root._latestGeneration = generation;

        if (root._pendingRequest !== null)
            root._setRequestState(root._pendingRequest.generation, "superseded");

        if (root._activeRequest !== null
                && !root._terminalResultPublished
                && root._suppressionReason.length === 0) {
            root._suppressionReason = "superseded";
            root._setRequestState(root._activeRequest.generation, "superseded");
        }

        root._pendingRequest = request;
        root._setRequestState(generation, "queued");
        root._startPendingIfIdle();
    }

    function cancel() {
        if (root._pendingRequest !== null) {
            root._setRequestState(root._pendingRequest.generation, "cancelled");
            root._pendingRequest = null;
        }

        if (root._activeRequest !== null) {
            root._suppressionReason = "cancelled";
            root._setRequestState(root._activeRequest.generation, "cancelled");
            requestTimeout.stop();
            helperProcess.signal(9);
        }
    }

    function _startPendingIfIdle() {
        if (root._activeRequest !== null
                || root._pendingRequest === null
                || helperProcess.running)
            return;

        root._activeRequest = root._pendingRequest;
        root._pendingRequest = null;
        root._activeRequest.startedAt = Date.now();
        root._processStarted = false;
        root._terminalResultPublished = false;
        root._suppressionReason = "";
        root._stdoutText = "";
        root._stderrPresent = false;
        root._stderrLength = 0;
        root._decodedResponse = null;
        root._decodeFailureReason = "";

        const command = [root.resolvedHelperExecutable];
        for (let index = 0; index < root.helperArguments.length; ++index)
            command.push(root.helperArguments[index]);

        root._setRequestState(root._activeRequest.generation, "starting");
        requestTimeout.interval = Math.max(1, root.timeoutMs);
        requestTimeout.restart();
        helperProcess.stdinEnabled = true;
        helperProcess.command = command;
        helperProcess.running = true;
    }

    function _handleStarted() {
        if (root._activeRequest === null)
            return;

        root._processStarted = true;
        root._setRequestState(root._activeRequest.generation, "running");

        const requestPayload = JSON.stringify({
            protocolVersion: ProjectInfo.configHelperProtocolVersion,
            requestGeneration: root._activeRequest.generation,
            operation: "validateAndNormalize",
            sourceIdentifier: root._activeRequest.sourceIdentifier,
            tomlSource: root._activeRequest.tomlSource
        });
        helperProcess.write(requestPayload + "\n");
        helperProcess.stdinEnabled = false;
    }

    function _handleRunningChanged() {
        if (root._activeRequest === null
                || helperProcess.running
                || root._processStarted)
            return;

        requestTimeout.stop();
        const generation = root._activeRequest.generation;
        const result = root._transportFailureResult(
            "helperUnavailable",
            "helperUnavailable",
            "The configuration helper could not be started from the resolved development path.",
            null,
            null
        );

        if (root._suppressionReason.length === 0)
            root._publishResult(result);
        else
            root._logDiscarded(generation, root._suppressionReason);

        root._clearActiveRequest();
        root._startPendingIfIdle();
    }

    function _handleExited(exitCode: int, exitStatus) {
        if (root._activeRequest === null)
            return;

        requestTimeout.stop();
        const generation = root._activeRequest.generation;

        if (root._suppressionReason.length > 0) {
            root._logDiscarded(generation, root._suppressionReason);
            root._clearActiveRequest();
            root._startPendingIfIdle();
            return;
        }

        if (root._terminalResultPublished) {
            root._clearActiveRequest();
            root._startPendingIfIdle();
            return;
        }

        if (exitCode !== 0 || Number(exitStatus) !== 0) {
            root._publishResult(root._transportFailureResult(
                "unexpectedProcessExit",
                "unexpectedProcessExit",
                "The configuration helper exited without a successful transport completion.",
                exitCode,
                Number(exitStatus)
            ));
            root._clearActiveRequest();
            root._startPendingIfIdle();
            return;
        }

        const responseValid = root._decodeProtocolResponse(
            root._stdoutText,
            root._activeRequest.generation
        );
        if (!responseValid) {
            root._publishResult(root._transportFailureResult(
                "invalidProtocolResponse",
                "invalidProtocolResponse",
                root._decodeFailureReason,
                exitCode,
                Number(exitStatus)
            ));
        } else {
            root._publishResult(root._normalizedHelperResult(
                root._decodedResponse,
                exitCode,
                Number(exitStatus)
            ));
        }

        root._clearActiveRequest();
        root._startPendingIfIdle();
    }

    function _handleTimeout() {
        if (root._activeRequest === null)
            return;

        if (root._suppressionReason.length > 0) {
            helperProcess.signal(9);
            return;
        }

        root._terminalResultPublished = true;
        root._publishResult(root._transportFailureResult(
            "timedOut",
            "timeout",
            "The configuration helper did not complete before the request timeout.",
            null,
            null
        ));
        helperProcess.signal(9);
    }

    function _handleOutputData(stream: string, text: string) {
        if (root._activeRequest === null)
            return;

        const limit = stream === "stdout"
            ? root.maxStdoutCharacters
            : root.maxStderrCharacters;
        if (stream === "stdout")
            root._stdoutText = text.slice(0, limit);
        else {
            root._stderrPresent = text.length > 0;
            root._stderrLength = Math.min(text.length, limit);
        }

        if (text.length <= limit || root._terminalResultPublished)
            return;

        if (root._suppressionReason.length > 0) {
            helperProcess.signal(9);
            return;
        }

        root._terminalResultPublished = true;
        root._publishResult(root._transportFailureResult(
            "invalidProtocolResponse",
            "outputLimitExceeded",
            "The configuration helper exceeded the bounded protocol output limit.",
            null,
            null
        ));
        helperProcess.signal(9);
    }

    function _decodeProtocolResponse(stdoutText: string, expectedGeneration: double): bool {
        root._decodedResponse = null;
        root._decodeFailureReason = "";
        const text = stdoutText.trim();
        if (text.length === 0) {
            root._decodeFailureReason = "The helper produced no protocol response on stdout.";
            return false;
        }

        let response;
        try {
            response = JSON.parse(text);
        } catch (error) {
            root._decodeFailureReason = "The helper stdout was not one valid JSON response.";
            return false;
        }

        if (!root._isObject(response)) {
            root._decodeFailureReason = "The helper response must be a JSON object.";
            return false;
        }
        if (!root._isNonNegativeInteger(response.protocolVersion)
                || response.protocolVersion !== ProjectInfo.configHelperProtocolVersion) {
            root._decodeFailureReason = "The helper response protocol version is not supported.";
            return false;
        }
        if (!root._isNonNegativeInteger(response.requestGeneration)
                || response.requestGeneration !== expectedGeneration) {
            root._decodeFailureReason = "The helper response generation does not match the request.";
            return false;
        }
        if (typeof response.success !== "boolean") {
            root._decodeFailureReason = "The helper response success field must be boolean.";
            return false;
        }
        if (!Array.isArray(response.warnings) || !Array.isArray(response.errors)) {
            root._decodeFailureReason =
                "The helper response warnings and errors fields must be arrays.";
            return false;
        }
        if (!root._validDiagnostics(response.warnings, "warning")
                || !root._validDiagnostics(response.errors, "error")) {
            root._decodeFailureReason = "The helper response contains malformed diagnostics.";
            return false;
        }
        if (!root._isNullableVersion(response.detectedSourceSchemaVersion)
                || !root._isNullableVersion(response.effectiveSchemaVersion)) {
            root._decodeFailureReason =
                "The helper response schema-version fields are malformed.";
            return false;
        }
        if (typeof response.migrationOccurred !== "boolean") {
            root._decodeFailureReason = "The helper response migration field must be boolean.";
            return false;
        }

        if (response.success) {
            if (!root._isObject(response.normalizedConfiguration)) {
                root._decodeFailureReason =
                    "A successful helper response must contain normalized configuration.";
                return false;
            }
            if (response.detectedSourceSchemaVersion === null
                    || response.effectiveSchemaVersion === null) {
                root._decodeFailureReason =
                    "A successful helper response must contain schema versions.";
                return false;
            }
            if (response.errors.length !== 0) {
                root._decodeFailureReason =
                    "A successful helper response cannot contain errors.";
                return false;
            }
        } else {
            if (response.normalizedConfiguration !== null) {
                root._decodeFailureReason =
                    "A failed helper response cannot contain normalized configuration.";
                return false;
            }
            if (response.errors.length === 0) {
                root._decodeFailureReason =
                    "A failed helper response must contain structured errors.";
                return false;
            }
        }

        root._decodedResponse = response;
        return true;
    }

    function _validDiagnostics(diagnostics, expectedSeverity: string): bool {
        for (let index = 0; index < diagnostics.length; ++index) {
            const diagnostic = diagnostics[index];
            if (!root._isObject(diagnostic)
                    || diagnostic.severity !== expectedSeverity
                    || typeof diagnostic.code !== "string"
                    || diagnostic.code.length === 0
                    || typeof diagnostic.message !== "string"
                    || typeof diagnostic.source !== "string"
                    || !root._isNullableString(diagnostic.configurationPath)
                    || !root._isNullablePosition(diagnostic.line)
                    || !root._isNullablePosition(diagnostic.column)
                    || !root._isNullableString(diagnostic.repairHint))
                return false;
        }
        return true;
    }

    function _normalizedHelperResult(response, exitCode: int, exitStatus) {
        const state = response.success ? "completed" : "helperValidationFailure";
        return {
            generation: response.requestGeneration,
            success: response.success,
            detectedSchemaVersion: response.detectedSourceSchemaVersion,
            effectiveSchemaVersion: response.effectiveSchemaVersion,
            migrationOccurred: response.migrationOccurred,
            migrationStatus: response.migrationOccurred ? "migratedInMemory" : "notMigrated",
            normalizedConfiguration: response.normalizedConfiguration,
            warnings: response.warnings,
            errors: response.errors,
            transportFailure: null,
            process: root._processInformation(exitCode, exitStatus),
            state: state,
            durationMs: root._durationMs()
        };
    }

    function _transportFailureResult(
        state: string,
        category: string,
        message: string,
        exitCode,
        exitStatus
    ) {
        return {
            generation: root._activeRequest.generation,
            success: false,
            detectedSchemaVersion: null,
            effectiveSchemaVersion: null,
            migrationOccurred: false,
            migrationStatus: "unknown",
            normalizedConfiguration: null,
            warnings: [],
            errors: [],
            transportFailure: {
                category: category,
                message: message,
                helperResolution: root.resolutionPolicy,
                helperExecutable: root.resolvedHelperExecutable,
                exitCode: exitCode,
                exitStatus: exitStatus,
                stderrPresent: root._stderrPresent,
                stderrLength: root._stderrLength
            },
            process: root._processInformation(exitCode, exitStatus),
            state: state,
            durationMs: root._durationMs()
        };
    }

    function _processInformation(exitCode, exitStatus) {
        return {
            exitCode: exitCode,
            exitStatus: exitStatus,
            stderrPresent: root._stderrPresent,
            stderrLength: root._stderrLength
        };
    }

    function _publishResult(result) {
        root._setRequestState(result.generation, result.state);
        const logFields = {
            generation: result.generation,
            operation: "validateAndNormalize",
            state: result.state,
            durationMs: result.durationMs,
            exitCode: result.process.exitCode,
            stderrPresent: result.process.stderrPresent
        };

        if (result.transportFailure !== null) {
            logFields.category = result.transportFailure.category;
            Logger.warning("config", "helper-request-failed", logFields);
        } else {
            logFields.success = result.success;
            Logger.info("config", "helper-request-completed", logFields);
        }

        root.resultReady(result);
    }

    function _setRequestState(generation: double, nextState: string) {
        if (generation === root._latestGeneration)
            root._latestState = nextState;
        Logger.debug("config", "helper-request-state", {
            generation: generation,
            operation: "validateAndNormalize",
            state: nextState
        });
        root.requestStateChanged(generation, nextState);
    }

    function _logDiscarded(generation: double, reason: string) {
        Logger.info("config", "helper-result-discarded", {
            generation: generation,
            operation: "validateAndNormalize",
            state: reason,
            durationMs: root._durationMs()
        });
    }

    function _clearActiveRequest() {
        root._activeRequest = null;
        root._processStarted = false;
        root._terminalResultPublished = false;
        root._suppressionReason = "";
    }

    function _durationMs(): double {
        if (root._activeRequest === null || root._activeRequest.startedAt === 0)
            return 0;
        return Math.max(0, Date.now() - root._activeRequest.startedAt);
    }

    function _isObject(value): bool {
        return value !== null && typeof value === "object" && !Array.isArray(value);
    }

    function _isNonNegativeInteger(value): bool {
        return typeof value === "number"
            && isFinite(value)
            && value >= 0
            && Math.floor(value) === value;
    }

    function _isNullableVersion(value): bool {
        return value === null || root._isNonNegativeInteger(value);
    }

    function _isNullablePosition(value): bool {
        return value === null
            || (root._isNonNegativeInteger(value) && value > 0);
    }

    function _isNullableString(value): bool {
        return value === null || typeof value === "string";
    }

    Timer {
        id: requestTimeout

        repeat: false
        onTriggered: root._handleTimeout()
    }

    Process {
        id: helperProcess

        stdout: StdioCollector {
            id: stdoutCollector

            waitForEnd: false
            onDataChanged: root._handleOutputData("stdout", text)
        }
        stderr: StdioCollector {
            id: stderrCollector

            waitForEnd: false
            onDataChanged: root._handleOutputData("stderr", text)
        }

        onStarted: root._handleStarted()
        onRunningChanged: root._handleRunningChanged()
        onExited: (exitCode, exitStatus) => root._handleExited(exitCode, exitStatus)
    }
}
