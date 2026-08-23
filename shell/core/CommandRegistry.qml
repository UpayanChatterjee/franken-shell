import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root

    readonly property int activeRequestCount: state.activeCount
    readonly property int availableCommandCount: state.availableCount
    property var builtinDefinitions: Object.freeze([])
    required property var configService
    readonly property string lastAvailabilityRefresh: state.lastAvailabilityRefresh
    readonly property string lastFailureCategory: state.lastFailureCategory
    readonly property string lastRequestId: state.lastRequestId
    readonly property int queuedRequestCount: state.queue.length
    readonly property int registeredCommandCount: state.registeredCount
    readonly property int registryGeneration: state.registryGeneration
    readonly property int retainedRequestCount: state.requestOrder.length
    readonly property int snapshotSequence: state.snapshotSequence
    readonly property int unavailableCommandCount: state.unavailableCount

    signal requestFinished(var request)
    signal requestUpdated(var request)
    signal sanitizedLog(var record)

    function _candidatePaths(executable: string): var {
        if (executable.startsWith("/"))
            return [executable];

        return state.executableSearchPaths.map(path => path + "/" + executable);
    }
    function _continueAvailabilityRefresh() {
        if (availabilityProbe.running)
            return;

        while (state.refreshIndex < state.refreshIds.length) {
            const commandId = state.refreshIds[state.refreshIndex];
            const definition = state.commandIndex[commandId];
            if (definition === undefined) {
                state.refreshIndex += 1;
                state.refreshCandidateIndex = 0;
                continue;
            }
            if (definition.definitionFailure.length > 0) {
                root._setAvailability(commandId, false, definition.definitionFailure, "");
                state.refreshIndex += 1;
                state.refreshCandidateIndex = 0;
                continue;
            }

            const candidates = root._candidatePaths(definition.executable);
            if (state.refreshCandidateIndex >= candidates.length) {
                root._setAvailability(commandId, false, "missingExecutable", "");
                state.refreshIndex += 1;
                state.refreshCandidateIndex = 0;
                continue;
            }

            const candidate = candidates[state.refreshCandidateIndex];
            state.probeContext = {
                token: state.refreshToken,
                commandId: commandId,
                candidate: candidate
            };
            state.probeStarted = false;
            availabilityProbe.command = [state.executableProbe, "-f", candidate, "-a", "-x", candidate];
            availabilityProbe.running = true;
            availabilityProbe.command = [];
            return;
        }

        state.lastAvailabilityRefresh = new Date().toISOString();
        state.probeContext = null;
        root._recountAvailability();
        root._log("info", "availability-refreshed", {
            "state": "completed",
            "registeredCommandCount": state.registeredCount,
            "availableCommandCount": state.availableCount,
            "unavailableCommandCount": state.unavailableCount,
            "registryGeneration": state.registryGeneration
        });
    }
    function _createRequest(commandId: string): var {
        state.nextRequestSequence = root._incrementDecimal(state.nextRequestSequence);
        const now = new Date().toISOString();
        const request = {
            requestId: "command-" + state.nextRequestSequence,
            commandId: commandId,
            state: "queued",
            enqueuedAt: now,
            startTimestamp: "",
            finishTimestamp: "",
            exitCode: null,
            exitStatus: "",
            timeoutState: false,
            cancellationState: false,
            failureCategory: "",
            resolvedExecutable: "",
            arguments: [],
            timeoutMs: 0,
            captureOutput: false,
            maximumOutputBytes: 0,
            stdout: "",
            slotIndex: -1
        };
        state.requests[request.requestId] = request;
        state.requestOrder = state.requestOrder.concat([request.requestId]);
        root._pruneHistory();
        return request;
    }
    function _dispatch() {
        let slot = root._freeSlot();
        while (slot !== null && state.queue.length > 0) {
            const requestId = state.queue[0];
            state.queue = state.queue.slice(1);
            const request = state.requests[requestId];
            if (request === undefined || request.state !== "queued") {
                slot = root._freeSlot();
                continue;
            }

            request.slotIndex = slot.slotIndex;
            request.startTimestamp = new Date().toISOString();
            state.activeCount += 1;
            root._transition(request, "starting", "");
            slot.start(request);
            slot = root._freeSlot();
        }
    }
    function _durationMs(request): int {
        if (request.startTimestamp.length === 0)
            return 0;

        const end = request.finishTimestamp.length > 0 ? Date.parse(request.finishTimestamp) : Date.now();
        return Math.max(0, end - Date.parse(request.startTimestamp));
    }
    function _execute(id, runtimeArguments) {
        const commandId = root._safeRequestedId(id);
        const request = root._createRequest(commandId);
        state.lastRequestId = request.requestId;

        if (!root.hasCommand(id)) {
            root._finish(request, "unavailable", "unknownCommand");
            return root._publicRequest(request);
        }

        const definition = state.commandIndex[id];
        const argumentsResult = root._runtimeArguments(definition, runtimeArguments);
        if (!argumentsResult.accepted) {
            root._finish(request, "unavailable", argumentsResult.failureCategory);
            return root._publicRequest(request);
        }
        const availability = state.availability[id];
        if (availability === undefined || availability.available !== true) {
            root._finish(request, "unavailable", availability === undefined ? "availabilityPending" : availability.reason);
            return root._publicRequest(request);
        }
        if (state.queue.length >= state.maxQueuedRequests && root._freeSlot() === null) {
            root._finish(request, "unavailable", "queueFull");
            return root._publicRequest(request);
        }

        request.commandId = id;
        request.resolvedExecutable = availability.resolvedExecutable;
        request.arguments = definition.arguments.slice().concat(argumentsResult.arguments);
        request.timeoutMs = definition.timeoutMs;
        request.captureOutput = definition.captureOutput;
        request.maximumOutputBytes = definition.maximumOutputBytes;
        state.queue = state.queue.concat([request.requestId]);
        root._transition(request, "queued", "");
        root._dispatch();
        return root._publicRequest(request);
    }
    function _expandExecutablePath(executable: string): var {
        const variables = [
            {
                token: "$XDG_CONFIG_HOME",
                value: state.xdgConfigHome
            },
            {
                token: "$XDG_STATE_HOME",
                value: state.xdgStateHome
            },
            {
                token: "$XDG_CACHE_HOME",
                value: state.xdgCacheHome
            },
            {
                token: "$XDG_DATA_HOME",
                value: state.xdgDataHome
            },
            {
                token: "$HOME",
                value: state.homeDirectory
            }
        ];

        for (let index = 0; index < variables.length; ++index) {
            const variable = variables[index];
            if (executable === variable.token || executable.startsWith(variable.token + "/")) {
                if (variable.value.length === 0) {
                    return {
                        value: "",
                        failure: "pathVariableUnavailable"
                    };
                }
                return {
                    value: variable.value + executable.slice(variable.token.length),
                    failure: ""
                };
            }
        }
        if (executable.indexOf("$") >= 0) {
            return {
                value: "",
                failure: "unsupportedPathVariable"
            };
        }
        return {
            value: executable,
            failure: ""
        };
    }
    function _finish(request, terminalState: string, failureCategory: string, releaseSlot = true) {
        if (root._terminalState(request.state))
            return;

        request.finishTimestamp = new Date().toISOString();
        if (failureCategory.length > 0)
            state.lastFailureCategory = failureCategory;
        root._transition(request, terminalState, failureCategory);
        root.requestFinished(root._publicRequest(request));
        if (releaseSlot && request.slotIndex >= 0)
            root._releaseSlot(request);
        root._pruneHistory();
    }
    function _freeSlot() {
        const slots = root._slots();
        for (let index = 0; index < slots.length; ++index) {
            if (!slots[index].occupied)
                return slots[index];
        }
        return null;
    }
    function _handleAvailabilityExit(exitCode: int, exitStatus: int) {
        const context = state.probeContext;
        state.probeContext = null;
        state.probeStarted = false;
        if (context === null || context.token !== state.refreshToken) {
            refreshTimer.restart();
            return;
        }

        if (exitCode === 0 && exitStatus === 0) {
            root._setAvailability(context.commandId, true, "", context.candidate);
            state.refreshIndex += 1;
            state.refreshCandidateIndex = 0;
        } else {
            state.refreshCandidateIndex += 1;
        }
        refreshTimer.restart();
    }
    function _handleAvailabilityRunningChanged() {
        if (availabilityProbe.running || state.probeContext === null || state.probeStarted)
            return;

        const context = state.probeContext;
        state.probeContext = null;
        state.probeStarted = false;
        if (context.token === state.refreshToken) {
            root._setAvailability(context.commandId, false, "availabilityProbeFailed", "");
            state.refreshIndex += 1;
            state.refreshCandidateIndex = 0;
        }
        refreshTimer.restart();
    }
    function _incrementDecimal(value: string): string {
        const digits = value.length > 0 ? value.split("") : ["0"];
        let carry = 1;
        for (let index = digits.length - 1; index >= 0 && carry > 0; --index) {
            const digit = Number(digits[index]) + carry;
            digits[index] = String(digit % 10);
            carry = digit >= 10 ? 1 : 0;
        }
        if (carry > 0)
            digits.unshift("1");
        return digits.join("");
    }
    function _invalidateQueuedRequests() {
        const queued = state.queue.slice();
        state.queue = [];
        for (let index = 0; index < queued.length; ++index) {
            const request = state.requests[queued[index]];
            if (request !== undefined && request.state === "queued")
                root._finish(request, "unavailable", "configurationReplaced");
        }
    }
    function _log(level: string, event: string, fields) {
        const record = Object.freeze(Object.assign({
            "event": event
        }, fields));
        root.sanitizedLog(record);
        Logger.write(level, "commands", event, fields);
    }
    function _normalizeDefinition(source, trusted: bool) {
        if (source === null || typeof source !== "object" || Array.isArray(source))
            return null;

        const id = source.id;
        if (typeof id !== "string" || id.length === 0)
            return null;

        let failure = "";
        const configuredExecutable = typeof source.executable === "string" ? source.executable : "";
        const expandedExecutable = root._expandExecutablePath(configuredExecutable);
        const executable = expandedExecutable.value;
        const argumentsValue = Array.isArray(source.arguments) ? source.arguments : [];
        if (!root._validStableId(id))
            failure = "invalidCommandId";
        else if (expandedExecutable.failure.length > 0)
            failure = expandedExecutable.failure;
        else if (!root._validExecutable(executable))
            failure = "invalidExecutableExpression";
        else if (!argumentsValue.every(argument => typeof argument === "string"))
            failure = "invalidArguments";
        else if (source.detached === true)
            failure = "unsupportedDetachedExecution";
        else if (source.environment !== undefined && (source.environment === null || typeof source.environment !== "object" || Array.isArray(source.environment) || Object.keys(source.environment).length > 0))
            failure = "unsupportedEnvironment";
        else if (source.workingDirectory !== undefined)
            failure = "unsupportedWorkingDirectory";

        return Object.freeze({
            id: id,
            executable: executable,
            arguments: Object.freeze(argumentsValue.slice()),
            timeoutMs: Number.isInteger(source.timeoutMs) && source.timeoutMs > 0 ? source.timeoutMs : state.defaultTimeoutMs,
            runtimeArgumentPolicy: trusted && ["none", "brightnessSet"].indexOf(source.runtimeArgumentPolicy) >= 0 ? source.runtimeArgumentPolicy : "none",
            captureOutput: trusted && source.captureOutput === true,
            maximumOutputBytes: trusted && Number.isInteger(source.maximumOutputBytes) && source.maximumOutputBytes > 0 ? Math.min(source.maximumOutputBytes, state.maximumCapturedOutputBytes) : 0,
            definitionFailure: failure
        });
    }
    function _pruneHistory() {
        if (state.requestOrder.length <= state.maxRetainedRequests)
            return;

        let index = 0;
        while (state.requestOrder.length > state.maxRetainedRequests && index < state.requestOrder.length) {
            const requestId = state.requestOrder[index];
            const request = state.requests[requestId];
            if (request !== undefined && root._terminalState(request.state)) {
                delete state.requests[requestId];
                state.requestOrder = state.requestOrder.slice(0, index).concat(state.requestOrder.slice(index + 1));
            } else {
                index += 1;
            }
        }
    }
    function _publicRequest(request) {
        const publicRequest = {
            requestId: request.requestId,
            commandId: request.commandId,
            state: request.state,
            enqueuedAt: request.enqueuedAt,
            startTimestamp: request.startTimestamp,
            finishTimestamp: request.finishTimestamp,
            exitCode: request.exitCode,
            exitStatus: request.exitStatus,
            timeoutState: request.timeoutState,
            cancellationState: request.cancellationState,
            failureCategory: request.failureCategory,
            durationMs: root._durationMs(request)
        };
        if (request.captureOutput)
            publicRequest.stdout = request.stdout;
        return Object.freeze(publicRequest);
    }
    function _recountAvailability() {
        let available = 0;
        const ids = Object.keys(state.commandIndex);
        for (let index = 0; index < ids.length; ++index) {
            if (state.availability[ids[index]]?.available === true)
                available += 1;
        }
        state.availableCount = available;
        state.unavailableCount = ids.length - available;
    }
    function _releaseSlot(request) {
        if (request.slotIndex < 0)
            return;

        request.slotIndex = -1;
        state.activeCount = Math.max(0, state.activeCount - 1);
    }
    function _replaceSnapshot(snapshot) {
        const configuredDefinitions = snapshot?.commands?.definitions?.toArray?.() ?? [];
        const trustedDefinitions = Array.isArray(root.builtinDefinitions) ? root.builtinDefinitions : [];
        const nextIndex = {};
        const nextAvailability = {};

        for (let index = 0; index < trustedDefinitions.length; ++index) {
            const normalized = root._normalizeDefinition(trustedDefinitions[index], true);
            if (normalized === null)
                continue;

            nextIndex[normalized.id] = normalized;
        }
        for (let index = 0; index < configuredDefinitions.length; ++index) {
            const normalized = root._normalizeDefinition(configuredDefinitions[index], false);
            if (normalized === null || Object.prototype.hasOwnProperty.call(nextIndex, normalized.id))
                continue;

            nextIndex[normalized.id] = normalized;
        }
        const ids = Object.keys(nextIndex);
        for (let index = 0; index < ids.length; ++index) {
            const normalized = nextIndex[ids[index]];

            nextAvailability[normalized.id] = {
                available: false,
                reason: normalized.definitionFailure.length > 0 ? normalized.definitionFailure : "availabilityPending",
                resolvedExecutable: "",
                checkedAt: ""
            };
        }

        state.commandIndex = nextIndex;
        state.availability = nextAvailability;
        state.registeredCount = Object.keys(nextIndex).length;
        state.availableCount = 0;
        state.unavailableCount = state.registeredCount;
        state.registryGeneration += 1;
        state.snapshotSequence = Number(snapshot?.activationSequence ?? snapshot?.requestGeneration ?? 0);
        state.lastAvailabilityRefresh = "";
        state.refreshIds = Object.keys(nextIndex).sort();
        state.refreshIndex = 0;
        state.refreshCandidateIndex = 0;
        state.refreshToken += 1;
        state.probeContext = null;
        root._invalidateQueuedRequests();

        if (availabilityProbe.running && state.probeStarted)
            availabilityProbe.signal(9);
        availabilityRefreshRetry.restart();

        root._log("info", "registry-replaced", {
            "state": "ready",
            "registeredCommandCount": state.registeredCount,
            "registryGeneration": state.registryGeneration,
            "snapshotSequence": state.snapshotSequence
        });
    }
    function _runtimeArguments(definition, runtimeArguments): var {
        const values = Array.isArray(runtimeArguments) ? runtimeArguments : [];
        if (definition.runtimeArgumentPolicy === "none") {
            return {
                accepted: values.length === 0,
                arguments: [],
                failureCategory: values.length === 0 ? "" : "runtimeArgumentsRejected"
            };
        }
        if (definition.runtimeArgumentPolicy === "brightnessSet") {
            const targetId = values[0];
            const rawValue = values[1];
            const valid = values.length === 2 && typeof targetId === "string" && /^[A-Za-z0-9][A-Za-z0-9._:-]{0,254}$/.test(targetId) && typeof rawValue === "string" && /^(0|[1-9][0-9]{0,9})$/.test(rawValue) && Number(rawValue) <= 2147483647;
            return {
                accepted: valid,
                arguments: valid ? [targetId, "set", rawValue] : [],
                failureCategory: valid ? "" : "invalidRuntimeArguments"
            };
        }
        return {
            accepted: false,
            arguments: [],
            failureCategory: "runtimeArgumentsRejected"
        };
    }
    function _safeRequestedId(id): string {
        return typeof id === "string" && root._validStableId(id) ? id : "<invalid>";
    }
    function _setAvailability(commandId: string, available: bool, reason: string, resolvedExecutable: string) {
        if (!Object.prototype.hasOwnProperty.call(state.commandIndex, commandId))
            return;

        const next = Object.assign({}, state.availability);
        next[commandId] = {
            available: available,
            reason: reason,
            resolvedExecutable: resolvedExecutable,
            checkedAt: new Date().toISOString()
        };
        state.availability = next;
        root._recountAvailability();
    }
    function _slotExited(slotIndex: int, requestId: string, exitCode: int, exitStatus: int, suppressionReason: string) {
        const request = state.requests[requestId];
        if (request === undefined || request.slotIndex !== slotIndex)
            return;

        request.exitCode = exitCode;
        request.exitStatus = exitStatus === 0 ? "normalExit" : "crashExit";
        if (!root._terminalState(request.state)) {
            if (exitCode === 0 && exitStatus === 0)
                root._finish(request, "completed", "");
            else
                root._finish(request, "nonZeroExit", exitStatus === 0 ? "nonZeroExit" : "crashExit");
        } else {
            root._releaseSlot(request);
            root.requestUpdated(root._publicRequest(request));
        }
        root._dispatch();
    }
    function _slotFailedToStart(slotIndex: int, requestId: string) {
        const request = state.requests[requestId];
        if (request === undefined || request.slotIndex !== slotIndex)
            return;

        if (!root._terminalState(request.state))
            root._finish(request, "failedToStart", "failedToStart");
        else
            root._releaseSlot(request);
        root._dispatch();
    }
    function _slotStarted(slotIndex: int, requestId: string) {
        const request = state.requests[requestId];
        if (request === undefined || request.slotIndex !== slotIndex || root._terminalState(request.state))
            return;

        root._transition(request, "running", "");
    }
    function _slotStdout(slotIndex: int, requestId: string, output: string) {
        const request = state.requests[requestId];
        if (request === undefined || request.slotIndex !== slotIndex || !request.captureOutput)
            return;
        const remaining = Math.max(0, request.maximumOutputBytes - request.stdout.length);
        if (remaining > 0)
            request.stdout += String(output).slice(0, remaining);
    }
    function _slotStoppedWithoutExit(slotIndex: int, requestId: string) {
        const request = state.requests[requestId];
        if (request === undefined || request.slotIndex !== slotIndex)
            return;

        root._releaseSlot(request);
        root.requestUpdated(root._publicRequest(request));
        root._dispatch();
    }
    function _slotTimedOut(slotIndex: int, requestId: string) {
        const request = state.requests[requestId];
        if (request === undefined || request.slotIndex !== slotIndex || root._terminalState(request.state))
            return;

        request.timeoutState = true;
        root._finish(request, "timedOut", "timeout", false);
    }
    function _slots() {
        return [slot0, slot1, slot2];
    }
    function _terminalState(requestState: string): bool {
        return requestState === "completed" || requestState === "failed" || requestState === "failedToStart" || requestState === "timedOut" || requestState === "cancelled" || requestState === "nonZeroExit" || requestState === "unavailable";
    }
    function _timeoutForRequest(requestId: string): int {
        return state.requests[requestId]?.timeoutMs ?? 0;
    }
    function _transition(request, nextState: string, failureCategory: string) {
        request.state = nextState;
        request.failureCategory = failureCategory;
        const publicRequest = root._publicRequest(request);
        root.requestUpdated(publicRequest);
        root._log(nextState === "failedToStart" || nextState === "timedOut" || nextState === "nonZeroExit" || nextState === "unavailable" ? "warning" : "info", "request-state", {
            "requestId": request.requestId,
            "commandId": request.commandId,
            "state": nextState,
            "durationMs": root._durationMs(request),
            "exitCode": request.exitCode,
            "failureCategory": failureCategory
        });
    }
    function _validExecutable(executable: string): bool {
        if (executable.length === 0 || executable.length > 4096 || executable.startsWith("~") || executable.indexOf("$") >= 0 || executable.indexOf("*") >= 0 || executable.indexOf("?") >= 0 || executable.indexOf("[") >= 0 || executable.indexOf("]") >= 0 || /[\u0000-\u001f\u007f|&;<>\u0060]/.test(executable) || /\s/.test(executable)) {
            return false;
        }
        if (executable.indexOf("/") >= 0 && !executable.startsWith("/"))
            return false;

        return true;
    }
    function _validStableId(id: string): bool {
        return id.length <= 128 && /^[A-Za-z0-9][A-Za-z0-9._-]*$/.test(id);
    }
    function cancel(requestId): bool {
        const request = state.requests[requestId];
        if (request === undefined || root._terminalState(request.state))
            return false;

        if (request.state === "queued") {
            const index = state.queue.indexOf(requestId);
            if (index >= 0) {
                state.queue = state.queue.slice(0, index).concat(state.queue.slice(index + 1));
            }
            request.cancellationState = true;
            root._finish(request, "cancelled", "cancelled");
            root._dispatch();
            return true;
        }

        if (request.slotIndex >= 0) {
            request.cancellationState = true;
            root._finish(request, "cancelled", "cancelled", false);
            root._slots()[request.slotIndex].cancel("cancelled");
            return true;
        }
        return false;
    }
    function commandAvailable(id): bool {
        if (!root.hasCommand(id))
            return false;

        const availability = state.availability[id];
        return availability !== undefined && availability.available === true;
    }
    function execute(id) {
        return root._execute(id, []);
    }
    function executeWithArguments(id, runtimeArguments) {
        return root._execute(id, runtimeArguments);
    }
    function hasCommand(id): bool {
        return typeof id === "string" && Object.prototype.hasOwnProperty.call(state.commandIndex, id);
    }
    function registrySummary() {
        return {
            "registeredCommandCount": root.registeredCommandCount,
            "availableCommandCount": root.availableCommandCount,
            "unavailableCommandCount": root.unavailableCommandCount,
            "activeRequestCount": root.activeRequestCount,
            "queuedRequestCount": root.queuedRequestCount,
            "retainedRequestCount": root.retainedRequestCount,
            "lastRequestId": root.lastRequestId,
            "lastFailureCategory": root.lastFailureCategory,
            "registryGeneration": root.registryGeneration,
            "snapshotSequence": root.snapshotSequence,
            "lastAvailabilityRefresh": root.lastAvailabilityRefresh
        };
    }
    function requestById(requestId) {
        const request = state.requests[requestId];
        return request === undefined ? null : root._publicRequest(request);
    }

    Component.onCompleted: root._replaceSnapshot(root.configService.active)

    Connections {
        function onActivated(snapshot) {
            root._replaceSnapshot(snapshot);
        }

        target: root.configService
    }
    QtObject {
        id: state

        property int activeCount: 0
        property var availability: ({})
        property int availableCount: 0
        property var commandIndex: ({})
        readonly property int defaultTimeoutMs: 5000
        readonly property string executableProbe: "/usr/bin/test"
        readonly property var executableSearchPaths: ["/usr/local/bin", "/usr/bin", "/bin"]
        readonly property string homeDirectory: String(Quickshell.env("HOME") ?? "")
        property string lastAvailabilityRefresh: ""
        property string lastFailureCategory: ""
        property string lastRequestId: ""
        readonly property int maxActiveRequests: 3
        readonly property int maxQueuedRequests: 32
        readonly property int maxRetainedRequests: 256
        readonly property int maximumCapturedOutputBytes: 262144
        property string nextRequestSequence: "0"
        property var probeContext: null
        property bool probeStarted: false
        property var queue: []
        property int refreshCandidateIndex: 0
        property var refreshIds: []
        property int refreshIndex: 0
        property int refreshToken: 0
        property int registeredCount: 0
        property int registryGeneration: 0
        property var requestOrder: []
        property var requests: ({})
        property int snapshotSequence: 0
        property int unavailableCount: 0
        readonly property string xdgCacheHome: {
            const configured = String(Quickshell.env("XDG_CACHE_HOME") ?? "");
            return configured.length > 0 ? configured : (state.homeDirectory.length > 0 ? state.homeDirectory + "/.cache" : "");
        }
        readonly property string xdgConfigHome: {
            const configured = String(Quickshell.env("XDG_CONFIG_HOME") ?? "");
            return configured.length > 0 ? configured : (state.homeDirectory.length > 0 ? state.homeDirectory + "/.config" : "");
        }
        readonly property string xdgDataHome: {
            const configured = String(Quickshell.env("XDG_DATA_HOME") ?? "");
            return configured.length > 0 ? configured : (state.homeDirectory.length > 0 ? state.homeDirectory + "/.local/share" : "");
        }
        readonly property string xdgStateHome: {
            const configured = String(Quickshell.env("XDG_STATE_HOME") ?? "");
            return configured.length > 0 ? configured : (state.homeDirectory.length > 0 ? state.homeDirectory + "/.local/state" : "");
        }
    }
    Timer {
        id: refreshTimer

        interval: 0
        repeat: false

        onTriggered: root._continueAvailabilityRefresh()
    }
    Timer {
        id: availabilityRefreshRetry

        interval: 25
        repeat: false

        onTriggered: {
            if (availabilityProbe.running)
                availabilityRefreshRetry.restart();
            else
                refreshTimer.restart();
        }
    }
    Process {
        id: availabilityProbe

        onExited: (exitCode, exitStatus) => // qmllint disable signal-handler-parameters
            root._handleAvailabilityExit(exitCode, Number(exitStatus))
        onRunningChanged: root._handleAvailabilityRunningChanged()
        onStarted: state.probeStarted = true
    }
    CommandProcessSlot {
        id: slot0

        registry: root
        slotIndex: 0
    }
    CommandProcessSlot {
        id: slot1

        registry: root
        slotIndex: 1
    }
    CommandProcessSlot {
        id: slot2

        registry: root
        slotIndex: 2
    }
}
