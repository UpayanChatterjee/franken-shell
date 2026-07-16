import QtQuick
import Quickshell
import "../../core/ConfigDefaults.js" as ConfigDefaults

Scope {
    id: root

    readonly property string state: "fake"
    readonly property string resolutionPolicy: "test-fake"
    readonly property string resolvedHelperExecutable: "test-fake"
    property int requestCount: 0
    property var _normalJob: null
    property var _delayedJob: null
    property var _transportFailure: (generation, category) => ({
        generation: generation,
        success: false,
        effectiveSchemaVersion: null,
        migrationOccurred: false,
        normalizedConfiguration: null,
        warnings: [],
        errors: [],
        transportFailure: {
            category: category,
            message: "Controlled transport failure."
        },
        state: category
    })

    signal resultReady(var result)
    signal requestStateChanged(double generation, string state)

    function cancel() {
        // Intentionally does not cancel delayed work. ConfigService must reject
        // stale results independently of the real client's supersession logic.
    }

    function validateAndNormalize(
        generation: double,
        sourceIdentifier: string,
        tomlSource: string
    ) {
        root.requestCount += 1;
        root.requestStateChanged(generation, "running");
        const job = {
            generation: generation,
            sourceIdentifier: sourceIdentifier,
            tomlSource: tomlSource
        };

        if (tomlSource.indexOf("DELAY_OLD") !== -1) {
            root._delayedJob = job;
            delayedTimer.restart();
        } else {
            root._normalJob = job;
            normalTimer.restart();
        }
    }

    function _complete(job) {
        if (job.tomlSource.indexOf("INVALID") !== -1) {
            root._publish({
                generation: job.generation,
                success: false,
                effectiveSchemaVersion: 1,
                migrationOccurred: false,
                normalizedConfiguration: null,
                warnings: [],
                errors: [{
                    severity: "error",
                    code: "CONFIG_FIXTURE_INVALID",
                    message: "Controlled validation failure.",
                    configurationPath: "fixture",
                    source: "fixture",
                    line: 1,
                    column: 1,
                    repairHint: null
                }],
                transportFailure: null,
                state: "helperValidationFailure"
            });
            return;
        }

        if (job.tomlSource.indexOf("UNAVAILABLE") !== -1) {
            root._publish(root._transportFailure(job.generation, "helperUnavailable"));
            return;
        }

        if (job.tomlSource.indexOf("TRANSPORT") !== -1) {
            root._publish(root._transportFailure(job.generation, "unexpectedProcessExit"));
            return;
        }

        if (job.tomlSource.indexOf("MALFORMED_RESULT") !== -1) {
            root._publish({
                generation: job.generation,
                success: true,
                effectiveSchemaVersion: 1,
                migrationOccurred: false,
                normalizedConfiguration: {
                    schemaVersion: 1
                },
                warnings: [],
                errors: [],
                transportFailure: null,
                state: "completed"
            });
            return;
        }

        const normalized = JSON.parse(JSON.stringify(ConfigDefaults.normalized));
        if (job.tomlSource.indexOf("EDGE_RIGHT") !== -1)
            normalized.bar.edge = "right";
        if (job.tomlSource.indexOf("EDGE_BOTTOM") !== -1)
            normalized.bar.edge = "bottom";
        if (job.tomlSource.indexOf("EDGE_TOP") !== -1)
            normalized.bar.edge = "top";
        if (job.tomlSource.indexOf("COMMAND_SECRET") !== -1) {
            normalized.commands.private = {
                executable: "program",
                arguments: ["--token", "fixture-secret"],
                detached: false,
                timeoutMs: 5000,
                environment: {}
            };
        }

        root._publish({
            generation: job.generation,
            success: true,
            effectiveSchemaVersion: 1,
            migrationOccurred: false,
            normalizedConfiguration: normalized,
            warnings: [],
            errors: [],
            transportFailure: null,
            state: "completed"
        });
    }

    function _publish(result) {
        root.requestStateChanged(result.generation, result.state);
        root.resultReady(result);
    }

    Timer {
        id: normalTimer

        interval: 20
        repeat: false
        onTriggered: {
            const job = root._normalJob;
            root._normalJob = null;
            if (job !== null)
                root._complete(job);
        }
    }

    Timer {
        id: delayedTimer

        interval: 650
        repeat: false
        onTriggered: {
            const job = root._delayedJob;
            root._delayedJob = null;
            if (job !== null)
                root._complete(job);
        }
    }
}
