import QtQuick
import Quickshell

Scope {
    id: root

    property int defaultTimeoutMs: 1600
    readonly property var records: state.records
    readonly property int revision: state.revision

    signal changed

    function currentForMonitor(ownerMonitorId: string): var {
        let current = null;
        for (const record of state.records) {
            if (record.ownerMonitorId === ownerMonitorId && (current === null || record.updatedAtMs > current.updatedAtMs))
                current = record;
        }
        return current;
    }
    function dismiss(key: string): var {
        const next = state.records.filter(record => record.key !== key);
        if (next.length === state.records.length)
            return root.result(true, false, "");
        root.replaceRecords(next);
        return root.result(true, true, "");
    }
    function dismissMonitor(ownerMonitorId: string) {
        root.replaceRecords(state.records.filter(record => record.ownerMonitorId !== ownerMonitorId));
    }
    function expireDue(nowMs = Date.now()) {
        root.replaceRecords(state.records.filter(record => record.deadlineMs > nowMs));
    }
    function replaceRecords(records) {
        const next = Object.freeze(records.slice());
        if (JSON.stringify(next) === JSON.stringify(state.records))
            return;
        state.records = next;
        state.revision += 1;
        root.changed();
    }
    function result(accepted: bool, changed: bool, errorCode: string): var {
        return Object.freeze({
            "accepted": accepted,
            "changed": changed,
            "errorCode": errorCode
        });
    }
    function show(record, nowMs = Date.now()): var {
        const kind = String(record?.kind ?? "");
        if (["volume", "brightness"].indexOf(kind) < 0)
            return root.result(false, false, "OSD_KIND_UNSUPPORTED");
        const ownerMonitorId = String(record?.ownerMonitorId ?? "");
        if (!/^[A-Za-z0-9][A-Za-z0-9._:-]{0,127}$/.test(ownerMonitorId))
            return root.result(false, false, "OSD_MONITOR_INVALID");
        const numericValue = Number(record?.value);
        if (!Number.isFinite(numericValue))
            return root.result(false, false, "OSD_VALUE_INVALID");
        const existing = state.records.find(candidate => candidate.key === kind);
        const value = Math.max(0, Math.min(1, numericValue));
        const timeoutMs = Math.max(250, Math.min(10000, Math.round(Number(record?.timeoutMs ?? root.defaultTimeoutMs))));
        const normalized = Object.freeze({
            "key": kind,
            "kind": kind,
            "value": value,
            "muted": kind === "volume" && record?.muted === true,
            "label": kind === "volume" ? qsTr("Volume") : qsTr("Brightness"),
            "ownerMonitorId": existing?.ownerMonitorId ?? ownerMonitorId,
            "ownerReason": existing?.ownerReason ?? String(record?.ownerReason ?? "fallback"),
            "origin": String(record?.origin ?? "user"),
            "updatedAtMs": Number(nowMs),
            "deadlineMs": Number(nowMs) + timeoutMs
        });
        const next = state.records.filter(candidate => candidate.key !== kind);
        next.push(normalized);
        root.replaceRecords(next);
        return root.result(true, true, numericValue === value ? "" : "OSD_VALUE_CLAMPED");
    }

    QtObject {
        id: state

        property var records: Object.freeze([])
        property int revision: 0
    }
    Timer {
        interval: 100
        repeat: true
        running: state.records.length > 0

        onTriggered: root.expireDue()
    }
}
