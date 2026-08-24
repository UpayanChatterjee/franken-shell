import QtQuick
import Quickshell

Scope {
    id: root

    property int failureTimeoutMs: 9000
    property int maximumVisible: 3
    readonly property var records: state.publicRecords
    readonly property int revision: state.revision
    property int successTimeoutMs: 3500

    signal actionRequested(string key, string actionId)
    signal changed

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
        root.replaceRecords(state.records.filter(record => record.pauseReasons.length > 0 || record.deadlineMs > nowMs));
    }
    function invokeAction(key: string, actionId: string): var {
        const record = state.records.find(candidate => candidate.key === key);
        if (record === undefined || !record.actions.some(action => action.id === actionId))
            return root.result(false, false, "TOAST_ACTION_UNAVAILABLE");
        root.actionRequested(key, actionId);
        return root.result(true, false, "");
    }
    function pause(key: string, reason: string, nowMs = Date.now()): bool {
        const index = state.records.findIndex(record => record.key === key);
        if (index < 0)
            return false;
        const record = state.records[index];
        if (record.pauseReasons.indexOf(reason) >= 0)
            return true;
        const next = state.records.slice();
        next[index] = Object.freeze(Object.assign({}, record, {
            "remainingMs": Math.max(1, record.deadlineMs - Number(nowMs)),
            "pauseReasons": Object.freeze(record.pauseReasons.concat([reason]))
        }));
        root.replaceRecords(next);
        return true;
    }
    function replaceRecords(records) {
        const next = Object.freeze(records.slice());
        if (JSON.stringify(next) === JSON.stringify(state.records))
            return;
        state.records = next;
        state.publicRecords = Object.freeze(next.map(record => Object.freeze({
                "instanceId": record.instanceId,
                "key": record.key,
                "severity": record.severity,
                "summary": record.summary,
                "detail": record.detail,
                "actions": record.actions,
                "origin": record.origin,
                "ownerMonitorId": record.ownerMonitorId,
                "ownerReason": record.ownerReason,
                "updatedAtMs": record.updatedAtMs
            })));
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
    function resume(key: string, reason: string, nowMs = Date.now()): bool {
        const index = state.records.findIndex(record => record.key === key);
        if (index < 0)
            return false;
        const record = state.records[index];
        const reasons = record.pauseReasons.filter(candidate => candidate !== reason);
        if (reasons.length === record.pauseReasons.length)
            return true;
        const next = state.records.slice();
        next[index] = Object.freeze(Object.assign({}, record, {
            "deadlineMs": reasons.length === 0 ? Number(nowMs) + record.remainingMs : record.deadlineMs,
            "pauseReasons": Object.freeze(reasons)
        }));
        root.replaceRecords(next);
        return true;
    }
    function show(record, nowMs = Date.now()): var {
        const key = controller.safeToken(record?.key ?? record?.category);
        const allowedKeys = ["network", "bluetooth", "nightLight", "idleInhibitor", "audioOutput", "power", "generic"];
        if (allowedKeys.indexOf(key) < 0)
            return root.result(false, false, "TOAST_KEY_UNSUPPORTED");
        const ownerMonitorId = controller.safeToken(record?.ownerMonitorId);
        if (ownerMonitorId.length === 0)
            return root.result(false, false, "TOAST_MONITOR_INVALID");
        const severity = ["success", "info", "warning", "failure"].indexOf(record?.severity) >= 0 ? record.severity : "info";
        const summary = controller.safeText(record?.summary, 240);
        if (summary.length === 0)
            return root.result(false, false, "TOAST_SUMMARY_EMPTY");
        const actions = controller.actions(record?.actions);
        if (actions.length > 0 && record?.actionsInlineAvailable !== true)
            return root.result(false, false, "TOAST_ACTION_ORIGIN_REQUIRED");
        const existingIndex = state.records.findIndex(candidate => candidate.key === key);
        const existing = existingIndex < 0 ? undefined : state.records[existingIndex];
        state.nextId += existing === undefined ? 1 : 0;
        const timeoutMs = Math.max(500, Math.min(30000, Math.round(Number(record?.timeoutMs ?? (severity === "failure" ? root.failureTimeoutMs : root.successTimeoutMs)))));
        const normalized = Object.freeze({
            "instanceId": existing?.instanceId ?? "toast:session-" + state.nextId,
            "key": key,
            "severity": severity,
            "summary": summary,
            "detail": controller.safeText(record?.detail, 1024),
            "actions": actions,
            "origin": String(record?.origin ?? "user"),
            "ownerMonitorId": existing?.ownerMonitorId ?? ownerMonitorId,
            "ownerReason": existing?.ownerReason ?? String(record?.ownerReason ?? "fallback"),
            "updatedAtMs": Number(nowMs),
            "deadlineMs": Number(nowMs) + timeoutMs,
            "remainingMs": timeoutMs,
            "pauseReasons": existing?.pauseReasons ?? Object.freeze([])
        });
        const next = state.records.slice();
        if (existingIndex < 0)
            next.unshift(normalized);
        else
            next[existingIndex] = normalized;
        root.replaceRecords(next.slice(0, root.maximumVisible));
        return root.result(true, true, "");
    }
    function toastsForMonitor(ownerMonitorId: string): var {
        return root.records.filter(record => record.ownerMonitorId === ownerMonitorId);
    }

    QtObject {
        id: state

        property int nextId: 0
        property var publicRecords: Object.freeze([])
        property var records: Object.freeze([])
        property int revision: 0
    }
    QtObject {
        id: controller

        function actions(value): var {
            if (!Array.isArray(value))
                return Object.freeze([]);
            const actions = [];
            for (const candidate of value.slice(0, 3)) {
                const id = controller.safeToken(candidate?.id);
                const label = controller.safeText(candidate?.label, 80);
                if (id.length > 0 && label.length > 0)
                    actions.push(Object.freeze({
                        "id": id,
                        "label": label
                    }));
            }
            return Object.freeze(actions);
        }
        function safeText(value, maximumLength: int): string {
            return String(value ?? "").replace(/[\u0000-\u001f\u007f]/g, " ").replace(/\s+/g, " ").trim().slice(0, maximumLength);
        }
        function safeToken(value): string {
            const token = String(value ?? "");
            return /^[A-Za-z0-9][A-Za-z0-9._:-]{0,127}$/.test(token) ? token : "";
        }
    }
    Timer {
        interval: 100
        repeat: true
        running: state.records.length > 0

        onTriggered: root.expireDue()
    }
}
