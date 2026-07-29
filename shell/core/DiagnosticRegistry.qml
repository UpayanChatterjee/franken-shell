import QtQuick
import Quickshell

Scope {
    id: root

    readonly property int criticalCount: controller.countSeverity("critical", root.errorRevision)
    readonly property int errorCount: registryState.errors.length
    readonly property int errorRevision: registryState.errorRevision
    readonly property var errors: registryState.errors
    readonly property int recoverableCount: controller.countRecoverable(root.errorRevision)
    readonly property int serviceRevision: registryState.serviceRevision
    readonly property var services: registryState.services

    signal errorReported(var error)
    signal errorsCleared(string domain)
    signal servicesReplaced(int revision)

    function clearDomain(domain: string): bool {
        const next = registryState.errors.filter(record => record.domain !== domain);
        if (next.length === registryState.errors.length)
            return false;
        registryState.errors = controller.deepFreeze(next.map(record => controller.detached(record)));
        registryState.errorRevision += 1;
        root.errorsCleared(domain);
        return true;
    }
    function error(domain: string, code: string): var {
        for (const record of registryState.errors) {
            if (record.domain === domain && record.code === code)
                return controller.detached(record);
        }
        return null;
    }
    function errorsSummary(): var {
        return controller.detached(registryState.errors);
    }
    function replaceServices(candidate): var {
        const normalized = controller.normalizeServices(candidate);
        if (!normalized.accepted)
            return controller.result(false, false, normalized.errorCode, root.serviceRevision);

        const serialized = JSON.stringify(normalized.records);
        if (serialized === registryState.serviceSerialized)
            return controller.result(true, false, "", root.serviceRevision);

        registryState.services = controller.deepFreeze(normalized.records);
        registryState.serviceSerialized = serialized;
        registryState.serviceRevision += 1;
        root.servicesReplaced(registryState.serviceRevision);
        return controller.result(true, true, "", root.serviceRevision);
    }
    function report(candidate): var {
        const normalized = controller.normalizeError(candidate);
        if (!normalized.accepted)
            return controller.result(false, false, normalized.errorCode, root.errorRevision);

        const next = registryState.errors.map(record => controller.detached(record));
        let existingIndex = -1;
        for (let index = 0; index < next.length; ++index) {
            if (next[index].domain === normalized.record.domain && next[index].code === normalized.record.code) {
                existingIndex = index;
                break;
            }
        }

        if (existingIndex >= 0) {
            const previous = next[existingIndex];
            normalized.record.count = previous.count + 1;
            normalized.record.firstSeen = previous.firstSeen;
            next.splice(existingIndex, 1);
        }
        next.push(normalized.record);
        while (next.length > registryState.maxErrors)
            next.shift();

        registryState.errors = controller.deepFreeze(next);
        registryState.errorRevision += 1;
        root.errorReported(controller.detached(normalized.record));
        return controller.result(true, true, "", root.errorRevision);
    }
    function service(name: string): var {
        for (const record of registryState.services) {
            if (record.name === name)
                return controller.detached(record);
        }
        return null;
    }
    function servicesSummary(): var {
        return controller.detached(registryState.services);
    }
    function summary(): var {
        return Object.freeze({
            "serviceRevision": root.serviceRevision,
            "errorRevision": root.errorRevision,
            "serviceCount": registryState.services.length,
            "errorCount": root.errorCount,
            "criticalCount": root.criticalCount,
            "recoverableCount": root.recoverableCount
        });
    }

    QtObject {
        id: registryState

        property int errorRevision: 0
        property var errors: Object.freeze([])
        readonly property int maxErrors: 128
        property int serviceRevision: 0
        property string serviceSerialized: ""
        property var services: Object.freeze([])
    }
    QtObject {
        id: controller

        readonly property var allowedAvailability: Object.freeze(["available", "unavailable", "degraded", "failed"])
        readonly property var allowedServiceStates: Object.freeze(["unavailable", "starting", "ready", "degraded", "failed", "reconnecting", "stopped"])
        readonly property var allowedSeverities: Object.freeze(["warning", "error", "critical"])

        function countRecoverable(revision: int): int {
            void revision;
            return registryState.errors.filter(record => record.recoverable).length;
        }
        function countSeverity(severity: string, revision: int): int {
            void revision;
            return registryState.errors.filter(record => record.severity === severity).length;
        }
        function deepFreeze(value): var {
            if (value === null || typeof value !== "object" || Object.isFrozen(value))
                return value;
            for (const key of Object.keys(value))
                controller.deepFreeze(value[key]);
            return Object.freeze(value);
        }
        function detached(value): var {
            return JSON.parse(JSON.stringify(value));
        }
        function normalizeError(candidate): var {
            if (candidate === null || typeof candidate !== "object" || Array.isArray(candidate))
                return controller.rejection("DIAGNOSTIC_ERROR_INVALID");
            if (typeof candidate.domain !== "string" || !/^[a-z][A-Za-z0-9.-]*$/.test(candidate.domain) || typeof candidate.code !== "string" || !/^[A-Z][A-Z0-9_]*$/.test(candidate.code) || typeof candidate.summary !== "string" || candidate.summary.length === 0 || candidate.summary.length > 512 || controller.allowedSeverities.indexOf(candidate.severity) < 0 || typeof candidate.recoverable !== "boolean") {
                return controller.rejection("DIAGNOSTIC_ERROR_FIELDS_INVALID");
            }

            const now = new Date().toISOString();
            return {
                "accepted": true,
                "errorCode": "",
                "record": {
                    "domain": candidate.domain,
                    "code": candidate.code,
                    "severity": candidate.severity,
                    "summary": candidate.summary,
                    "recoverable": candidate.recoverable,
                    "repairHint": controller.optionalString(candidate.repairHint),
                    "count": 1,
                    "firstSeen": now,
                    "lastSeen": now
                }
            };
        }
        function normalizeServices(candidate): var {
            if (!Array.isArray(candidate))
                return controller.rejection("DIAGNOSTIC_SERVICES_NOT_ARRAY");

            const records = [];
            const names = {};
            for (const source of candidate) {
                if (source === null || typeof source !== "object" || Array.isArray(source))
                    return controller.rejection("DIAGNOSTIC_SERVICE_INVALID");
                if (typeof source.name !== "string" || !/^[a-z][A-Za-z0-9.-]*$/.test(source.name))
                    return controller.rejection("DIAGNOSTIC_SERVICE_NAME_INVALID");
                if (names[source.name] === true)
                    return controller.rejection("DIAGNOSTIC_SERVICE_DUPLICATE");
                if (controller.allowedAvailability.indexOf(source.availability) < 0 || controller.allowedServiceStates.indexOf(source.state) < 0 || typeof source.recoverable !== "boolean") {
                    return controller.rejection("DIAGNOSTIC_SERVICE_STATE_INVALID");
                }
                names[source.name] = true;
                records.push({
                    "name": source.name,
                    "availability": source.availability,
                    "state": source.state,
                    "lastError": controller.optionalString(source.lastError),
                    "lastSuccess": controller.optionalString(source.lastSuccess),
                    "version": controller.optionalString(source.version),
                    "backend": controller.optionalString(source.backend),
                    "recoverable": source.recoverable,
                    "repairHint": controller.optionalString(source.repairHint)
                });
            }
            records.sort((left, right) => left.name.localeCompare(right.name));
            return {
                "accepted": true,
                "errorCode": "",
                "records": records
            };
        }
        function optionalString(value): string {
            return typeof value === "string" ? value : "";
        }
        function rejection(errorCode: string): var {
            return {
                "accepted": false,
                "errorCode": errorCode,
                "records": []
            };
        }
        function result(accepted: bool, changed: bool, errorCode: string, revision: int): var {
            return Object.freeze({
                "accepted": accepted,
                "changed": changed,
                "errorCode": errorCode,
                "revision": revision
            });
        }
    }
}
