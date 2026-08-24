import QtQuick
import Quickshell

Scope {
    id: root

    readonly property var groups: state.groups
    property int maximumItems: 500
    readonly property var records: state.records
    readonly property int replacedCount: state.replacedCount
    readonly property int trimmedCount: state.trimmedCount

    signal changed

    function groupRecords(records): var {
        const groups = [];
        const indices = {};
        for (const record of records) {
            let index = indices[record.groupKey];
            if (index === undefined) {
                index = groups.length;
                indices[record.groupKey] = index;
                groups.push({
                    "groupKey": record.groupKey,
                    "appName": record.appName,
                    "appIcon": record.appIcon,
                    "records": []
                });
            }
            groups[index].records.push(record);
        }
        return Object.freeze(groups.map(group => Object.freeze({
                "groupKey": group.groupKey,
                "appName": group.appName,
                "appIcon": group.appIcon,
                "count": group.records.length,
                "records": Object.freeze(group.records)
            })));
    }
    function record(internalId: string): var {
        return root.records.find(candidate => candidate.internalId === internalId) ?? null;
    }
    function remove(internalId: string): bool {
        const index = root.records.findIndex(candidate => candidate.internalId === internalId);
        if (index < 0)
            return false;
        const next = Array.from(root.records);
        next.splice(index, 1);
        root.replaceRecords(next);
        return true;
    }
    function replaceRecords(records) {
        state.records = Object.freeze(records);
        state.groups = root.groupRecords(records);
        root.changed();
    }
    function reset() {
        state.records = Object.freeze([]);
        state.groups = Object.freeze([]);
        state.replacedCount = 0;
        state.trimmedCount = 0;
        root.changed();
    }
    function upsert(record): var {
        const next = Array.from(root.records);
        const index = next.findIndex(candidate => candidate.internalId === record.internalId);
        const replaced = index >= 0;
        if (replaced) {
            next[index] = record;
            state.replacedCount += 1;
        } else {
            next.unshift(record);
        }
        const maximum = Math.max(1, root.maximumItems);
        const trimmed = Math.max(0, next.length - maximum);
        if (trimmed > 0) {
            next.splice(maximum, trimmed);
            state.trimmedCount += trimmed;
        }
        root.replaceRecords(next);
        return Object.freeze({
            "replaced": replaced,
            "trimmed": trimmed
        });
    }

    QtObject {
        id: state

        property var groups: Object.freeze([])
        property var records: Object.freeze([])
        property int replacedCount: 0
        property int trimmedCount: 0
    }
}
