import QtQuick
import Quickshell

Scope {
    id: root

    readonly property int availableCount: controller.countState("available", root.revision)
    readonly property var capabilities: registryState.records
    readonly property int degradedCount: controller.countState("degraded", root.revision)
    readonly property bool evaluated: registryState.evaluated
    readonly property int failedCount: controller.countState("failed", root.revision)
    readonly property int nonAvailableCount: root.unavailableCount + root.degradedCount + root.failedCount
    readonly property int requiredFailureCount: controller.requiredFailureCount(root.revision)
    readonly property int revision: registryState.revision
    readonly property int unavailableCount: controller.countState("unavailable", root.revision)

    signal replaced(int revision)

    function available(id: string): bool {
        for (const record of registryState.records) {
            if (record.id === id)
                return record.state === "available";
        }
        return false;
    }
    function capability(id: string): var {
        for (const record of registryState.records) {
            if (record.id === id)
                return controller.detached(record);
        }
        return null;
    }
    function replace(candidate): var {
        const normalized = controller.normalize(candidate);
        if (!normalized.accepted) {
            return Object.freeze({
                "accepted": false,
                "changed": false,
                "errorCode": normalized.errorCode,
                "revision": root.revision
            });
        }

        const serialized = JSON.stringify(normalized.records);
        if (registryState.evaluated && serialized === registryState.serialized) {
            return Object.freeze({
                "accepted": true,
                "changed": false,
                "errorCode": "",
                "revision": root.revision
            });
        }

        registryState.records = controller.deepFreeze(normalized.records);
        registryState.serialized = serialized;
        registryState.evaluated = true;
        registryState.revision += 1;
        root.replaced(registryState.revision);
        return Object.freeze({
            "accepted": true,
            "changed": true,
            "errorCode": "",
            "revision": root.revision
        });
    }
    function summary(): var {
        return Object.freeze({
            "evaluated": root.evaluated,
            "revision": root.revision,
            "availableCount": root.availableCount,
            "unavailableCount": root.unavailableCount,
            "degradedCount": root.degradedCount,
            "failedCount": root.failedCount,
            "requiredFailureCount": root.requiredFailureCount,
            "capabilities": controller.detached(registryState.records)
        });
    }

    QtObject {
        id: registryState

        property bool evaluated: false
        property var records: Object.freeze([])
        property int revision: 0
        property string serialized: ""
    }
    QtObject {
        id: controller

        readonly property var allowedStates: Object.freeze(["available", "unavailable", "degraded", "failed"])

        function countState(expectedState: string, revision: int): int {
            void revision;
            let count = 0;
            for (const record of registryState.records) {
                if (record.state === expectedState)
                    count += 1;
            }
            return count;
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
        function normalize(candidate): var {
            if (!Array.isArray(candidate))
                return controller.rejection("CAPABILITY_SNAPSHOT_NOT_ARRAY");

            const records = [];
            const ids = {};
            for (let index = 0; index < candidate.length; ++index) {
                const source = candidate[index];
                if (source === null || typeof source !== "object" || Array.isArray(source))
                    return controller.rejection("CAPABILITY_RECORD_INVALID");

                const id = source.id;
                const state = source.state;
                if (typeof id !== "string" || !/^[a-z][A-Za-z0-9.-]*$/.test(id))
                    return controller.rejection("CAPABILITY_ID_INVALID");
                if (ids[id] === true)
                    return controller.rejection("CAPABILITY_ID_DUPLICATE");
                if (controller.allowedStates.indexOf(state) < 0)
                    return controller.rejection("CAPABILITY_STATE_INVALID");
                if (typeof source.required !== "boolean")
                    return controller.rejection("CAPABILITY_REQUIRED_INVALID");
                if (source.reason !== undefined && typeof source.reason !== "string")
                    return controller.rejection("CAPABILITY_REASON_INVALID");
                if (source.source !== undefined && typeof source.source !== "string")
                    return controller.rejection("CAPABILITY_SOURCE_INVALID");

                ids[id] = true;
                records.push({
                    "id": id,
                    "state": state,
                    "available": state === "available",
                    "required": source.required,
                    "reason": source.reason ?? "",
                    "source": source.source ?? ""
                });
            }
            records.sort((left, right) => left.id.localeCompare(right.id));
            return {
                "accepted": true,
                "errorCode": "",
                "records": records
            };
        }
        function rejection(errorCode: string): var {
            return {
                "accepted": false,
                "errorCode": errorCode,
                "records": []
            };
        }
        function requiredFailureCount(revision: int): int {
            void revision;
            let count = 0;
            for (const record of registryState.records) {
                if (record.required && record.state !== "available")
                    count += 1;
            }
            return count;
        }
    }
}
