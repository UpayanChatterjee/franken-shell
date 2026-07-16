import "MonitorNormalization.js" as MonitorNormalization
import QtQuick
import Quickshell

Scope {
    id: root

    required property var backend
    required property QtObject configService
    readonly property var monitors: controller.publicRecords(root.revision)
    readonly property MonitorRecord focusedMonitor: controller.firstMatching("focused", root.revision)
    readonly property MonitorRecord focusedWindowMonitor: controller.firstMatching("focusedWindowMonitor", root.revision)
    readonly property MonitorRecord fallbackMonitor: controller.selectFallback(root.revision)
    readonly property string lastRefresh: registryState.lastRefresh
    readonly property string lastMappingError: registryState.lastMappingError
    readonly property string backendAvailability: registryState.backendAvailability
    readonly property int revision: registryState.revision

    signal added(MonitorRecord monitor)
    signal updated(MonitorRecord monitor, var changedFields)
    signal removed(string runtimeId, var lastState)

    function monitorByRuntimeId(runtimeId: string) : MonitorRecord {
        return controller.findByRuntimeId(runtimeId);
    }

    function monitorForScreen(screen) : MonitorRecord {
        return controller.findByScreen(screen);
    }

    function fullscreenOnMonitor(runtimeId: string) : bool {
        const monitor = root.monitorByRuntimeId(runtimeId);
        return monitor !== null && monitor.fullscreenActive;
    }

    function requestRefresh() {
        root.backend.requestRefresh();
        refreshTimer.restart();
    }

    function diagnosticsSummary() {
        const records = root.monitors;
        const ambiguous = records.filter(record => record.mappingHealth === "ambiguous").length;
        const unmapped = records.filter(record => record.mappingHealth !== "mapped").length;
        return Object.freeze({
            connectedMonitorCount: records.length,
            mappedMonitorCount: records.filter(record => record.mappingHealth === "mapped").length,
            ambiguousMonitorCount: ambiguous,
            unmappedMonitorCount: unmapped,
            focusedMonitorRuntimeId: root.focusedMonitor?.runtimeId ?? null,
            focusedWindowMonitorRuntimeId: root.focusedWindowMonitor?.runtimeId ?? null,
            fallbackMonitorRuntimeId: root.fallbackMonitor?.runtimeId ?? null,
            transforms: Object.freeze(records.map(record => Object.freeze({
                runtimeId: record.runtimeId,
                transform: record.transform,
                orientation: record.orientation
            }))),
            lastRefresh: root.lastRefresh,
            lastMappingError: root.lastMappingError,
            backendAvailability: root.backendAvailability
        });
    }

    QtObject {
        id: registryState

        property var records: []
        property var identities: ({})
        // Session-local only. Runtime IDs must never be persisted or used as
        // configuration match identifiers.
        property int nextRuntimeId: 1
        property int revision: 0
        property string lastRefresh: ""
        property string lastMappingError: ""
        property string backendAvailability: "unknown"
    }

    QtObject {
        id: controller

        function configurationFacts() {
            const active = root.configService.active;
            const bar = active?.bar ?? null;
            const monitors = active?.monitors ?? null;
            let rules = [];
            if (Array.isArray(monitors?.rules))
                rules = monitors.rules.slice();
            else if (typeof monitors?.rules?.toArray === "function")
                rules = monitors.rules.toArray();
            return {
                barEnabled: bar?.enabled !== false,
                barEdge: typeof bar?.edge === "string" ? bar.edge : "left",
                // These private fields can only be populated by a future typed
                // ConfigService snapshot using the documented monitor schema.
                _provisionalMonitorDefault: monitors?.default ?? null,
                _provisionalMonitorRules: rules
            };
        }

        function publicRecords(revision) {
            void revision;
            return Object.freeze(registryState.records.slice());
        }

        function findByRuntimeId(runtimeId) {
            for (const record of registryState.records) {
                if (record.runtimeId === runtimeId)
                    return record;
            }
            return null;
        }

        function findByScreen(screen) {
            for (const record of registryState.records) {
                const identity = registryState.identities[record.runtimeId];
                if (identity?.screenRef === screen)
                    return record;
            }
            return null;
        }

        function firstMatching(propertyName, revision) {
            void revision;
            for (const record of registryState.records) {
                if (record[propertyName] === true)
                    return record;
            }
            return null;
        }

        function selectFallback(revision) {
            void revision;
            let selected = null;
            for (const record of registryState.records) {
                if (!record.connected)
                    continue;
                if (selected === null || record.fallbackRank < selected.fallbackRank)
                    selected = record;
            }
            return selected;
        }

        function identityMatch(record, candidate, candidateKeyCounts, existingKeyCounts) {
            const identity = registryState.identities[record.runtimeId] ?? {};
            if (candidate._screenRef !== null && identity.screenRef === candidate._screenRef)
                return true;
            if (candidate._hyprlandRef !== null
                    && identity.hyprlandRef === candidate._hyprlandRef)
                return true;
            const oldKeys = identity.identityKeys ?? [];
            for (const key of candidate._identityKeys) {
                if (oldKeys.indexOf(key) >= 0
                        && candidateKeyCounts[key] === 1
                        && existingKeyCounts[key] === 1)
                    return true;
            }
            if (candidate._identityKeys.length === 0 && oldKeys.length === 0
                    && candidate._backendId >= 0
                    && identity.backendId === candidate._backendId
                    && record.connector === candidate.connector)
                return true;
            return false;
        }

        function updateIdentity(record, candidate) {
            registryState.identities[record.runtimeId] = {
                screenRef: candidate._screenRef ?? null,
                hyprlandRef: candidate._hyprlandRef ?? null,
                backendId: candidate._backendId ?? -1,
                identityKeys: Object.freeze((candidate._identityKeys ?? []).slice())
            };
        }

        function refresh() {
            let snapshot;
            try {
                snapshot = root.backend.snapshot();
            } catch (error) {
                registryState.backendAvailability = "unavailable";
                registryState.lastMappingError = "backendSnapshotFailure";
                registryState.lastRefresh = new Date().toISOString();
                Logger.warning("monitors", "snapshot-failed", {
                    category: "backendSnapshotFailure"
                });
                return;
            }

            const normalized = MonitorNormalization.normalize(snapshot, controller.configurationFacts());
            const previous = registryState.records.slice();
            const unmatched = previous.slice();
            const nextRecords = [];
            const additions = [];
            const updates = [];
            const candidateKeyCounts = {};
            const existingKeyCounts = {};

            for (const candidate of normalized.records) {
                for (const key of candidate._identityKeys)
                    candidateKeyCounts[key] = (candidateKeyCounts[key] ?? 0) + 1;
            }
            for (const record of previous) {
                const identity = registryState.identities[record.runtimeId] ?? {};
                for (const key of identity.identityKeys ?? [])
                    existingKeyCounts[key] = (existingKeyCounts[key] ?? 0) + 1;
            }

            for (const candidate of normalized.records) {
                let matched = null;
                for (let index = 0; index < unmatched.length; index++) {
                    if (!controller.identityMatch(
                            unmatched[index],
                            candidate,
                            candidateKeyCounts,
                            existingKeyCounts
                        ))
                        continue;
                    matched = unmatched.splice(index, 1)[0];
                    break;
                }

                if (matched === null) {
                    const state = Object.assign({}, candidate, {
                        runtimeId: "monitor-" + registryState.nextRuntimeId
                    });
                    registryState.nextRuntimeId += 1;
                    matched = monitorRecordComponent.createObject(root, {
                        _initialState: state
                    });
                    additions.push(matched);
                } else {
                    const state = Object.assign({}, candidate, {
                        runtimeId: matched.runtimeId
                    });
                    const changed = matched._apply(state);
                    if (changed.length > 0)
                        updates.push({ record: matched, changed: Object.freeze(changed) });
                }
                controller.updateIdentity(matched, candidate);
                nextRecords.push(matched);
            }

            nextRecords.sort((a, b) => {
                const oldA = previous.indexOf(a);
                const oldB = previous.indexOf(b);
                if (oldA >= 0 && oldB >= 0)
                    return oldA - oldB;
                if (oldA >= 0)
                    return -1;
                if (oldB >= 0)
                    return 1;
                return Number(a.runtimeId.split("-")[1]) - Number(b.runtimeId.split("-")[1]);
            });

            registryState.records = nextRecords;
            registryState.backendAvailability = String(snapshot.backendAvailability ?? root.backend.backendAvailability ?? "unknown");
            registryState.lastMappingError = normalized.mappingErrors.length > 0
                ? normalized.mappingErrors.join(",") : "";
            registryState.lastRefresh = new Date().toISOString();
            registryState.revision += 1;

            for (const record of additions)
                root.added(record);
            for (const update of updates)
                root.updated(update.record, update.changed);
            for (const record of unmatched) {
                const lastState = Object.assign({}, record.sanitizedSnapshot(), {
                    connected: false
                });
                delete registryState.identities[record.runtimeId];
                root.removed(record.runtimeId, Object.freeze(lastState));
                record.destroy();
            }

            Logger.debug("monitors", "registry-refreshed", {
                connected: nextRecords.length,
                mapped: nextRecords.filter(record => record.mappingHealth === "mapped").length,
                degraded: normalized.mappingErrors.length
            });
        }
    }

    Component {
        id: monitorRecordComponent

        MonitorRecord {}
    }

    Timer {
        id: refreshTimer

        interval: 25
        onTriggered: controller.refresh()
    }

    Connections {
        target: root.backend

        function onStateChanged() {
            refreshTimer.restart();
        }
    }

    Connections {
        target: root.configService

        function onActivated(snapshot) {
            void snapshot;
            refreshTimer.restart();
        }
    }

    Component.onCompleted: root.requestRefresh()
}
