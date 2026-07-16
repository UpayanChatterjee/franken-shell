import "../../core" as Core
import QtQuick
import Quickshell

ShellRoot {
    id: root

    property int step: 0
    property var waitCondition: null
    property var waitCallback: null
    property double waitDeadline: 0
    property var rapidRequestIds: []
    property var runningRequestIds: []
    property string preservedRequestId: ""
    property int generationBeforeReplacement: 0
    property var sanitizedRecords: []
    property var terminalCounts: ({})
    property var replacementReentrantRequest: null
    readonly property string fixtureDirectory: Quickshell.shellDir + "/tests/command_registry/fixtures"
    readonly property string successExecutable: root.fixtureDirectory + "/success"
    readonly property string nonZeroExecutable: root.fixtureDirectory + "/nonzero"
    readonly property string slowExecutable: root.fixtureDirectory + "/slow"
    readonly property string argumentsExecutable: root.fixtureDirectory + "/arguments"
    readonly property string failedStartExecutable: root.fixtureDirectory + "/failed-start"
    readonly property string stderrZeroExecutable: root.fixtureDirectory + "/stderr-zero"
    readonly property string verboseExecutable: root.fixtureDirectory + "/verbose"
    readonly property string homeDirectory: String(Quickshell.env("HOME") ?? "")
    readonly property string homeExpandedSuccess: "$HOME" + root.successExecutable.slice(root.homeDirectory.length)

    function fail(message: string) {
        console.error("FAIL command-registry:", message);
        Qt.exit(1);
        throw new Error(message);
    }

    function check(condition: bool, message: string) {
        if (!condition)
            root.fail(message);
    }

    function pass(name: string) {
        console.info("PASS command-registry:", name);
    }

    function definition(id: string, executable: string, arguments = [], timeoutMs = 1000) {
        return {
            id: id,
            executable: executable,
            arguments: arguments,
            detached: false,
            timeoutMs: timeoutMs,
            environment: {}
        };
    }

    function expectedXdg(variable: string, fallbackSuffix: string): string {
        const configured = String(Quickshell.env(variable) ?? "");
        return (configured.length > 0 ? configured : root.homeDirectory + fallbackSuffix) + "/probe";
    }

    function replace(definitions, callback) {
        fakeConfig.replaceDefinitions(definitions);
        root.waitUntil(
            () => registry.lastAvailabilityRefresh.length > 0,
            callback,
            3000
        );
    }

    function waitUntil(condition, callback, timeoutMs: int) {
        root.waitCondition = condition;
        root.waitCallback = callback;
        root.waitDeadline = Date.now() + timeoutMs;
        waitTimer.restart();
    }

    function waitForRequest(requestId: string, states, callback, timeoutMs = 4000) {
        root.waitUntil(() => {
            const request = registry.requestById(requestId);
            return request !== null && states.indexOf(request.state) >= 0;
        }, callback, timeoutMs);
    }

    function next() {
        root.step += 1;
        actionTimer.restart();
    }

    function baseDefinitions() {
        return [
            root.definition("fixture.success", root.successExecutable),
            root.definition("fixture.missing", root.fixtureDirectory + "/does-not-exist"),
            root.definition("fixture.nonzero", root.nonZeroExecutable),
            root.definition("fixture.timeout", root.slowExecutable, ["1", "0"], 60),
            root.definition("fixture.cancel", root.slowExecutable, ["2", "0"], 3000),
            root.definition("fixture.arguments", root.argumentsExecutable, ["alpha beta", "literal|pipe"]),
            root.definition("fixture.failedStart", root.failedStartExecutable),
            root.definition("fixture.shellString", "/bin/sh -c", ["touch", "/tmp/not-created"]),
            root.definition("fixture.expanded", root.homeExpandedSuccess),
            root.definition("fixture.unsupportedVariable", "$PATH/not-allowed")
        ];
    }

    function runStep() {
        switch (root.step) {
        case 0:
            root.replace(root.baseDefinitions(), () => {
                root.check(registry.registeredCommandCount === 10, "registered count");
                root.check(registry.hasCommand("fixture.success"), "registered lookup");
                root.check(registry.commandAvailable("fixture.success"), "available command");
                root.check(!registry.commandAvailable("fixture.missing"), "missing unavailable");
                root.check(registry.commandAvailable("fixture.expanded"), "approved HOME expansion");
                root.check(!registry.commandAvailable("fixture.unsupportedVariable"), "unapproved variable rejected");
                root.check(registry._expandExecutablePath("$HOME/probe").value === root.homeDirectory + "/probe", "HOME allowlist expansion");
                root.check(registry._expandExecutablePath("$XDG_CONFIG_HOME/probe").value === root.expectedXdg("XDG_CONFIG_HOME", "/.config"), "XDG config expansion");
                root.check(registry._expandExecutablePath("$XDG_STATE_HOME/probe").value === root.expectedXdg("XDG_STATE_HOME", "/.local/state"), "XDG state expansion");
                root.check(registry._expandExecutablePath("$XDG_CACHE_HOME/probe").value === root.expectedXdg("XDG_CACHE_HOME", "/.cache"), "XDG cache expansion");
                root.check(registry._expandExecutablePath("$XDG_DATA_HOME/probe").value === root.expectedXdg("XDG_DATA_HOME", "/.local/share"), "XDG data expansion");
                root.check(registry._expandExecutablePath("${HOME}/probe").failure === "unsupportedPathVariable", "braced variable rejected");
                root.check(!registry._validExecutable("~/probe"), "tilde expansion rejected");
                root.check(!registry._validExecutable("/tmp/franken-*"), "glob expansion rejected");
                root.check(!registry._validExecutable("/tmp/$(franken)"), "command substitution rejected");
                const unsupported = registry.execute("fixture.unsupportedVariable");
                root.check(unsupported.failureCategory === "unsupportedPathVariable", "unapproved variable category");
                root.pass("registered availability and exact path-variable allowlist");
                root.next();
            });
            break;
        case 1: {
            const request = registry.execute("fixture.unknown");
            root.check(request.state === "unavailable", "unknown state");
            root.check(request.failureCategory === "unknownCommand", "unknown category");
            root.pass("unknown command ID");
            root.next();
            break;
        }
        case 2: {
            const request = registry.execute("fixture.missing");
            root.check(request.state === "unavailable", "missing state");
            root.check(request.failureCategory === "missingExecutable", "missing category");
            root.pass("missing executable");
            root.next();
            break;
        }
        case 3: {
            const request = registry.execute("fixture.success");
            root.waitForRequest(request.requestId, ["completed"], () => {
                const completed = registry.requestById(request.requestId);
                root.check(completed.exitCode === 0, "zero exit code");
                root.check(completed.exitStatus === "normalExit", "normal exit status");
                root.pass("successful zero exit");
                root.next();
            });
            break;
        }
        case 4: {
            const request = registry.execute("fixture.nonzero");
            root.waitForRequest(request.requestId, ["nonZeroExit"], () => {
                const completed = registry.requestById(request.requestId);
                root.check(completed.exitCode === 23, "nonzero code");
                root.check(completed.failureCategory === "nonZeroExit", "nonzero category");
                root.pass("nonzero exit");
                root.next();
            });
            break;
        }
        case 5: {
            const request = registry.execute("fixture.timeout");
            root.waitForRequest(request.requestId, ["timedOut"], () => {
                const completed = registry.requestById(request.requestId);
                root.check(completed.timeoutState, "timeout flag");
                root.check(completed.failureCategory === "timeout", "timeout category");
                root.waitUntil(() => registry.activeRequestCount === 0, () => {
                    root.pass("timeout");
                    root.next();
                }, 3000);
            });
            break;
        }
        case 6:
            root.runningRequestIds = [
                registry.execute("fixture.cancel").requestId,
                registry.execute("fixture.cancel").requestId,
                registry.execute("fixture.cancel").requestId
            ];
            root.waitUntil(() => registry.activeRequestCount === 3, () => {
                const queued = registry.execute("fixture.cancel");
                root.check(registry.requestById(queued.requestId).state === "queued", "request queued");
                root.check(registry.cancel(queued.requestId), "queued cancellation accepted");
                root.check(registry.requestById(queued.requestId).state === "cancelled", "queued cancelled");
                root.check(root.terminalCounts[queued.requestId] === 1, "queued cancellation finished exactly once");
                for (let index = 0; index < root.runningRequestIds.length; ++index)
                    registry.cancel(root.runningRequestIds[index]);
                root.waitUntil(() => registry.activeRequestCount === 0 && registry.queuedRequestCount === 0, () => {
                    for (let index = 0; index < root.runningRequestIds.length; ++index)
                        root.check(root.terminalCounts[root.runningRequestIds[index]] === 1, "running cancellation finished exactly once");
                    root.pass("cancellation before start and queue cleanup");
                    root.next();
                }, 4000);
            }, 3000);
            break;
        case 7: {
            const request = registry.execute("fixture.cancel");
            root.waitForRequest(request.requestId, ["running"], () => {
                root.check(registry.cancel(request.requestId), "running cancellation accepted");
                root.check(registry.requestById(request.requestId).state === "cancelled", "running cancelled");
                root.waitUntil(() => registry.activeRequestCount === 0, () => {
                    root.check(root.terminalCounts[request.requestId] === 1, "running cancellation emitted one terminal event");
                    root.pass("cancellation while running");
                    root.next();
                }, 4000);
            });
            break;
        }
        case 8:
            root.rapidRequestIds = [];
            for (let index = 0; index < 48; ++index)
                root.rapidRequestIds.push(registry.execute("fixture.cancel").requestId);
            root.check(registry.activeRequestCount === 3, "active concurrency bound");
            root.check(registry.queuedRequestCount <= 32, "queue bound");
            root.check(new Set(root.rapidRequestIds).size === root.rapidRequestIds.length, "rapid IDs unique");
            for (let index = 0; index < root.rapidRequestIds.length; ++index)
                registry.cancel(root.rapidRequestIds[index]);
            root.waitUntil(() => registry.activeRequestCount === 0 && registry.queuedRequestCount === 0, () => {
                root.check(registry.activeRequestCount === 0, "active cleanup");
                root.check(registry.queuedRequestCount === 0, "queue cleanup");
                for (let index = 0; index < root.rapidRequestIds.length; ++index)
                    root.check(root.terminalCounts[root.rapidRequestIds[index]] === 1, "rapid request finished exactly once");
                root.pass("bounded concurrency, repeated rapid execution, cleanup, and request-ID uniqueness");
                root.next();
            }, 5000);
            break;
        case 9:
            root.replace([
                root.definition("fixture.preserved", root.slowExecutable, ["0.25", "0"], 2000)
            ], () => {
                root.generationBeforeReplacement = registry.registryGeneration;
                const request = registry.execute("fixture.preserved");
                root.preservedRequestId = request.requestId;
                root.waitForRequest(request.requestId, ["running"], () => {
                    fakeConfig.replaceDefinitions([
                        root.definition("fixture.preserved", root.nonZeroExecutable)
                    ]);
                    root.waitUntil(() => registry.lastAvailabilityRefresh.length > 0
                        && registry.registryGeneration > root.generationBeforeReplacement, () => {
                        root.waitForRequest(root.preservedRequestId, ["completed"], () => {
                            const preserved = registry.requestById(root.preservedRequestId);
                            root.check(preserved.exitCode === 0, "running request kept original definition");
                            const replacement = registry.execute("fixture.preserved");
                            root.waitForRequest(replacement.requestId, ["nonZeroExit"], () => {
                                root.check(registry.requestById(replacement.requestId).exitCode === 23, "new request used replacement definition");
                                root.pass("snapshot replacement and running definition preservation");
                                root.next();
                            });
                        });
                    }, 3000);
                });
            });
            break;
        case 10:
            root.replace([], () => {
                root.check(!registry.hasCommand("fixture.preserved"), "removed lookup");
                const request = registry.execute("fixture.preserved");
                root.check(request.state === "unavailable", "removed execution unavailable");
                root.check(request.failureCategory === "unknownCommand", "removed category");
                root.pass("removed command cannot be newly executed");
                root.next();
            });
            break;
        case 11:
            root.replace([
                root.definition("fixture.refresh", root.fixtureDirectory + "/missing-refresh")
            ], () => {
                root.check(!registry.commandAvailable("fixture.refresh"), "initial refresh unavailable");
                const previousGeneration = registry.registryGeneration;
                fakeConfig.replaceDefinitions([
                    root.definition("fixture.refresh", root.successExecutable)
                ]);
                root.waitUntil(() => registry.lastAvailabilityRefresh.length > 0
                    && registry.registryGeneration > previousGeneration, () => {
                    root.check(registry.commandAvailable("fixture.refresh"), "replacement refresh available");
                    root.pass("availability cache refresh");
                    root.next();
                }, 3000);
            });
            break;
        case 12:
            root.replace([
                root.definition("fixture.failedStart", root.failedStartExecutable)
            ], () => {
                root.check(registry.commandAvailable("fixture.failedStart"), "failed-start fixture passes file probe");
                const request = registry.execute("fixture.failedStart");
                root.waitForRequest(request.requestId, ["failedToStart"], () => {
                    root.check(registry.requestById(request.requestId).failureCategory === "failedToStart", "failed-start fallback category");
                    root.pass("failed-to-start fallback");
                    root.next();
                });
            });
            break;
        case 13:
            root.replace([
                root.definition("fixture.shellString", "/bin/sh -c", ["touch", "/tmp/not-created"])
            ], () => {
                root.check(!registry.commandAvailable("fixture.shellString"), "shell expression unavailable");
                const request = registry.execute("fixture.shellString");
                root.check(request.failureCategory === "invalidExecutableExpression", "shell expression rejected");
                root.check(request.state === "unavailable", "shell expression never executed");
                root.pass("no shell-string execution");
                root.next();
            });
            break;
        case 14:
            root.replace([
                root.definition("fixture.arguments", root.argumentsExecutable, ["alpha beta", "literal|pipe", "$HOME"])
            ], () => {
                const request = registry.execute("fixture.arguments");
                root.waitForRequest(request.requestId, ["completed"], () => {
                    root.check(registry.requestById(request.requestId).exitCode === 0, "arguments remained distinct");
                    root.pass("arguments passed as distinct entries");
                    root.next();
                });
            });
            break;
        case 15:
            root.sanitizedRecords = [];
            root.replace([
                root.definition("fixture.private", root.successExecutable, ["--token", "fixture-secret"])
            ], () => {
                const request = registry.execute("fixture.private");
                root.waitForRequest(request.requestId, ["completed"], () => {
                    const diagnosticText = JSON.stringify(registry.registrySummary());
                    const requestText = JSON.stringify(registry.requestById(request.requestId));
                    const logText = JSON.stringify(root.sanitizedRecords);
                    root.check(diagnosticText.indexOf("fixture-secret") === -1, "diagnostics omit arguments");
                    root.check(diagnosticText.indexOf(root.successExecutable) === -1, "diagnostics omit executable");
                    root.check(requestText.indexOf("fixture-secret") === -1, "request model omits arguments");
                    root.check(logText.indexOf("fixture-secret") === -1, "logs omit arguments");
                    root.check(logText.indexOf(root.successExecutable) === -1, "logs omit executable");
                    root.check(registry.registrySummary().lastRequestId === request.requestId, "last request diagnostic");
                    root.pass("sanitized diagnostics and logs");
                    root.next();
                });
            });
            break;
        case 16:
            root.replace([
                root.definition("fixture.stderrZero", root.stderrZeroExecutable)
            ], () => {
                const request = registry.execute("fixture.stderrZero");
                root.waitForRequest(request.requestId, ["completed"], () => {
                    const completed = registry.requestById(request.requestId);
                    root.check(completed.exitCode === 0, "stderr zero exit code");
                    root.check(completed.failureCategory === "", "stderr did not create failure");
                    root.pass("zero exit is not reclassified by stderr");
                    root.next();
                });
            });
            break;
        case 17:
            root.replace([
                root.definition("fixture.verbose", root.verboseExecutable)
            ], () => {
                const request = registry.execute("fixture.verbose");
                root.waitForRequest(request.requestId, ["completed"], () => {
                    root.check(registry.requestById(request.requestId).exitCode === 0, "verbose output preserved result");
                    root.pass("verbose private output is drained and discarded");
                    root.next();
                });
            });
            break;
        case 18:
            root.replace([
                Object.assign(root.definition("fixture.detached", root.successExecutable), {
                    detached: true
                }),
                Object.assign(root.definition("fixture.environment", root.successExecutable), {
                    environment: {
                        FRANKEN_SECRET: "not-exposed"
                    }
                }),
                Object.assign(root.definition("fixture.workingDirectory", root.successExecutable), {
                    workingDirectory: "/tmp"
                })
            ], () => {
                root.check(registry.execute("fixture.detached").failureCategory === "unsupportedDetachedExecution", "detached runtime defense");
                root.check(registry.execute("fixture.environment").failureCategory === "unsupportedEnvironment", "environment runtime defense");
                root.check(registry.execute("fixture.workingDirectory").failureCategory === "unsupportedWorkingDirectory", "working-directory runtime defense");
                const diagnostics = JSON.stringify(registry.registrySummary());
                const logs = JSON.stringify(root.sanitizedRecords);
                root.check(diagnostics.indexOf("not-exposed") === -1, "unsupported environment omitted from diagnostics");
                root.check(logs.indexOf("not-exposed") === -1, "unsupported environment omitted from logs");
                root.pass("unsupported command fields are explicit and sanitized");
                root.next();
            });
            break;
        case 19:
            root.replace([
                root.definition("fixture.queuedReplacement", root.slowExecutable, ["2", "0"], 3000)
            ], () => {
                const activeIds = [
                    registry.execute("fixture.queuedReplacement").requestId,
                    registry.execute("fixture.queuedReplacement").requestId,
                    registry.execute("fixture.queuedReplacement").requestId
                ];
                root.waitUntil(() => registry.activeRequestCount === 3, () => {
                    const queued = registry.execute("fixture.queuedReplacement");
                    root.check(registry.requestById(queued.requestId).state === "queued", "replacement fixture queued");
                    const previousGeneration = registry.registryGeneration;
                    fakeConfig.replaceDefinitions([]);
                    root.waitUntil(() => registry.registryGeneration > previousGeneration
                        && registry.lastAvailabilityRefresh.length > 0, () => {
                        const invalidated = registry.requestById(queued.requestId);
                        root.check(invalidated.state === "unavailable", "old queued request invalidated");
                        root.check(invalidated.failureCategory === "configurationReplaced", "old queued replacement category");
                        root.check(invalidated.startTimestamp === "", "old queued request never started");
                        root.check(root.terminalCounts[queued.requestId] === 1, "invalidated queue request finished once");
                        root.check(root.replacementReentrantRequest !== null, "replacement terminal callback ran");
                        root.check(root.replacementReentrantRequest.state === "unavailable", "replacement callback could not queue removed command");
                        root.check(root.replacementReentrantRequest.failureCategory === "unknownCommand", "replacement callback saw new registry index");
                        for (let index = 0; index < activeIds.length; ++index)
                            registry.cancel(activeIds[index]);
                        root.waitUntil(() => registry.activeRequestCount === 0
                            && registry.queuedRequestCount === 0, () => {
                            root.pass("snapshot replacement cannot start stale queued definitions");
                            root.next();
                        }, 4000);
                    }, 3000);
                }, 3000);
            });
            break;
        case 20: {
            const requestIds = [];
            for (let index = 0; index < 260; ++index)
                requestIds.push(registry.execute("fixture.retained." + index).requestId);
            root.check(registry.retainedRequestCount === 256, "retained request limit");
            root.check(registry.requestById(requestIds[0]) === null, "oldest terminal request pruned");
            root.check(registry.requestById(requestIds[requestIds.length - 1]) !== null, "newest terminal request retained");
            root.check(new Set(requestIds).size === requestIds.length, "retained-limit IDs unique");
            root.check(registry._incrementDecimal("999999999999999999999999") === "1000000000000000000000000", "decimal request sequence has no numeric precision rollover");
            root.pass("deterministic retained history and process-lifetime request IDs");
            root.next();
            break;
        }
        default:
            console.info("PASS command-registry: all fixtures");
            Qt.quit();
        }
    }

    Component.onCompleted: actionTimer.restart()

    FakeCommandConfigService {
        id: fakeConfig
    }

    Core.CommandRegistry {
        id: registry

        configService: fakeConfig
        onSanitizedLog: record => root.sanitizedRecords.push(record)
        onRequestFinished: request => {
            root.terminalCounts[request.requestId] =
                (root.terminalCounts[request.requestId] ?? 0) + 1;
            if (request.commandId === "fixture.queuedReplacement"
                    && request.failureCategory === "configurationReplaced") {
                root.replacementReentrantRequest =
                    registry.execute("fixture.queuedReplacement");
            }
        }
    }

    Timer {
        id: actionTimer

        interval: 0
        repeat: false
        onTriggered: root.runStep()
    }

    Timer {
        id: waitTimer

        interval: 10
        repeat: false
        onTriggered: {
            if (root.waitCondition !== null && root.waitCondition()) {
                const callback = root.waitCallback;
                root.waitCondition = null;
                root.waitCallback = null;
                callback();
            } else if (Date.now() >= root.waitDeadline) {
                root.fail("timed out at step " + root.step);
            } else {
                waitTimer.restart();
            }
        }
    }
}
