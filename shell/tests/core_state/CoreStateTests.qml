import QtQuick
import Quickshell
import "../../core" as Core

ShellRoot {
    id: root

    function capabilities(state: string, required: bool): var {
        return [
            {
                "id": "hasHyprland",
                "state": state,
                "required": required,
                "reason": state === "available" ? "" : "fixtureUnavailable",
                "source": "fixture"
            },
            {
                "id": "hasOverview",
                "state": state,
                "required": false,
                "reason": state === "available" ? "" : "fixtureUnavailable",
                "source": "fixture"
            }
        ];
    }
    function check(condition: bool, message: string) {
        if (!condition)
            root.fail(message);
    }
    function fail(message: string) {
        console.error("FAIL core-state:", message);
        Qt.exit(1);
    }
    function member(object, key: string): var {
        return object[key];
    }

    Component.onCompleted: {
        root.check(shellState.state === "Bootstrapping", "initial state is Bootstrapping");
        shellState.configLoaded = true;
        root.check(shellState.state === "ConfigLoaded", "configuration advances readiness");
        shellState.coreServicesReady = true;
        root.check(shellState.state === "CoreServicesReady", "core services advance readiness");
        shellState.surfacesReady = true;
        root.check(shellState.state === "SurfacesReady", "surfaces can become ready before capability evaluation");
        root.check(!shellState.ready, "readiness waits for capability evaluation");

        let result = capabilityRegistry.replace(root.capabilities("available", false));
        root.check(result.accepted && result.changed, "healthy capability snapshot activates");
        root.check(shellState.state === "OptionalIntegrationsReady", "all capabilities available is healthy");
        root.check(shellState.ready && !shellState.degraded && !shellState.failed, "healthy readiness flags");
        root.check(capabilityRegistry.availableCount === 2, "available capabilities counted");
        const hyprlandCapability = capabilityRegistry.capability("hasHyprland");
        root.check(root.member(hyprlandCapability, "available"), "capability lookup is typed");

        const capabilityCopy = capabilityRegistry.summary();
        capabilityCopy.capabilities[0].state = "failed";
        root.check(capabilityRegistry.failedCount === 0, "capability summaries are detached");

        const capabilityRevision = capabilityRegistry.revision;
        result = capabilityRegistry.replace(root.capabilities("available", false));
        root.check(result.accepted && !result.changed && capabilityRegistry.revision === capabilityRevision, "equivalent capability reload is stable");
        result = capabilityRegistry.replace([
            {
                "id": "hasHyprland",
                "state": "unknown",
                "required": false
            }
        ]);
        root.check(!result.accepted && result.errorCode === "CAPABILITY_STATE_INVALID", "invalid capability state is rejected");
        root.check(capabilityRegistry.revision === capabilityRevision, "invalid capability reload preserves the active snapshot");

        capabilityRegistry.replace(root.capabilities("unavailable", false));
        root.check(shellState.state === "Degraded" && shellState.ready, "missing optional capabilities produce usable degradation");
        capabilityRegistry.replace(root.capabilities("unavailable", true));
        root.check(shellState.state === "Failed" && shellState.failureCode === "REQUIRED_CAPABILITY_UNAVAILABLE", "missing required capability fails readiness");
        capabilityRegistry.replace(root.capabilities("available", false));
        shellState.requiredFailureCode = "FIXTURE_REQUIRED_CORE_FAILURE";
        root.check(shellState.state === "Failed" && shellState.failureCode === "FIXTURE_REQUIRED_CORE_FAILURE", "required core failure is explicit");
        shellState.requiredFailureCode = "";
        shellState.coreDegraded = true;
        root.check(shellState.state === "Degraded", "degraded core health is aggregated");
        shellState.coreDegraded = false;
        root.check(shellState.state === "OptionalIntegrationsReady", "readiness recovers atomically");

        result = diagnosticRegistry.replaceServices([
            {
                "name": "config",
                "availability": "available",
                "state": "ready",
                "lastError": "",
                "lastSuccess": "fixture",
                "version": "1",
                "backend": "fixture",
                "recoverable": true,
                "repairHint": "",
                "secret": "discarded"
            }
        ]);
        const configService = diagnosticRegistry.service("config");
        root.check(result.accepted && root.member(configService, "state") === "ready", "service health snapshot activates");
        root.check(typeof root.member(configService, "secret") === "undefined", "service diagnostics expose only approved fields");
        const serviceRevision = diagnosticRegistry.serviceRevision;
        result = diagnosticRegistry.replaceServices([
            {
                "name": "config",
                "availability": "available",
                "state": "invented",
                "recoverable": true
            }
        ]);
        root.check(!result.accepted && diagnosticRegistry.serviceRevision === serviceRevision, "invalid service reload preserves the active snapshot");

        const diagnostic = {
            "domain": "config",
            "code": "CONFIG_INVALID",
            "severity": "error",
            "summary": "The fixture configuration is invalid.",
            "recoverable": true,
            "repairHint": "Correct the fixture.",
            "details": "private details",
            "credential": "must not escape"
        };
        diagnosticRegistry.report(diagnostic);
        diagnosticRegistry.report(diagnostic);
        const coalesced = diagnosticRegistry.error("config", "CONFIG_INVALID");
        root.check(root.member(coalesced, "count") === 2, "repeated errors coalesce");
        root.check(typeof root.member(coalesced, "details") === "undefined" && typeof root.member(coalesced, "credential") === "undefined", "error diagnostics redact unapproved fields");
        root.check(diagnosticRegistry.summary().recoverableCount === 1, "diagnostic summary counts recoverable errors");
        result = diagnosticRegistry.report({
            "domain": "config",
            "code": "lowercase",
            "severity": "error",
            "summary": "invalid",
            "recoverable": true
        });
        root.check(!result.accepted && result.errorCode === "DIAGNOSTIC_ERROR_FIELDS_INVALID", "malformed diagnostics are rejected");
        root.check(diagnosticRegistry.clearDomain("config") && diagnosticRegistry.errorCount === 0, "recovered domains clear their active errors");

        for (let index = 0; index < 130; ++index) {
            diagnosticRegistry.report({
                "domain": "fixture",
                "code": "FIXTURE_" + index,
                "severity": index === 129 ? "critical" : "warning",
                "summary": "Bounded fixture error " + index,
                "recoverable": true
            });
        }
        root.check(diagnosticRegistry.errorCount === 128, "diagnostic history remains bounded");
        root.check(diagnosticRegistry.criticalCount === 1, "critical diagnostics remain visible");
        const detachedErrors = diagnosticRegistry.errorsSummary();
        detachedErrors[0].summary = "mutated";
        root.check(diagnosticRegistry.errorsSummary()[0].summary !== "mutated", "diagnostic summaries are detached");

        console.info("PASS core-state: capabilities, diagnostics, and readiness contracts");
        exitTimer.start();
    }

    Core.CapabilityRegistry {
        id: capabilityRegistry
    }
    Core.DiagnosticRegistry {
        id: diagnosticRegistry
    }
    Core.ShellState {
        id: shellState

        capabilityRegistry: capabilityRegistry
    }
    Timer {
        id: exitTimer

        interval: 0

        onTriggered: Qt.quit()
    }
}
