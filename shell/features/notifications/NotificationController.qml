import QtQuick
import Quickshell

Scope {
    id: root

    property string defaultOwnerMonitorId: ""
    readonly property var historyRows: state.historyRows
    property bool historyVisible: false
    property int maximumVisiblePopups: 4
    property var monitorRegistry: null
    readonly property int popupRevision: state.popupRevision
    readonly property var popups: state.popups
    required property var service

    signal historyRowsAboutToChange
    signal popupExpired(string internalId)
    signal popupQueueChanged

    function admitPopup(record, nowMs = Date.now()) {
        if (root.historyVisible || record?.popupEligible !== true)
            return;
        const now = Number.isFinite(Number(nowMs)) ? Number(nowMs) : Date.now();
        const next = Array.from(root.popups);
        let index = next.findIndex(entry => entry.record.internalId === record.internalId);
        if (index < 0 && record.burstCoalesced === true)
            index = next.findIndex(entry => entry.record.groupKey === record.groupKey);
        const existing = index >= 0 ? next[index] : null;
        const distinctGroupedUpdate = existing !== null && existing.record.internalId !== record.internalId;
        const timeoutMs = Math.max(0, Number(record.timeoutMs ?? 0));
        const entry = Object.freeze({
            "popupId": record.internalId,
            "ownerMonitorId": existing?.ownerMonitorId ?? root.resolveOwnerMonitorId(),
            "record": record,
            "groupCount": existing === null ? 1 : distinctGroupedUpdate ? existing.groupCount + 1 : existing.groupCount
        });
        const timeoutStates = Object.assign({}, state.timeoutStates);
        if (existing !== null)
            delete timeoutStates[existing.popupId];
        timeoutStates[entry.popupId] = {
            "remainingMs": timeoutMs,
            "deadlineMs": timeoutMs > 0 ? now + timeoutMs : 0,
            "pauseReasons": ({})
        };
        state.timeoutStates = timeoutStates;
        if (index >= 0)
            next.splice(index, 1);
        next.unshift(entry);
        if (next.length > root.maximumVisiblePopups)
            next.splice(root.maximumVisiblePopups);
        root.replacePopups(next);
    }
    function clearHistory(): var {
        return root.service.clearAll();
    }
    function clearPresentation() {
        if (root.popups.length === 0)
            return;
        state.timeoutStates = ({});
        root.replacePopups([]);
    }
    function dismissGroup(groupKey: string): var {
        return root.service.dismissGroup(groupKey);
    }
    function dismissPopup(internalId: string): var {
        const response = root.service.dismiss(internalId);
        if (response.accepted)
            root.removePopup(internalId);
        return response;
    }
    function expireDue(nowMs = Date.now()): int {
        const now = Number(nowMs);
        const expired = root.popups.filter(entry => {
            const timeout = state.timeoutStates[entry.popupId];
            return timeout !== undefined && timeout.deadlineMs > 0 && Object.keys(timeout.pauseReasons).length === 0 && timeout.deadlineMs <= now;
        });
        if (expired.length === 0)
            return 0;
        const expiredIds = expired.map(entry => entry.popupId);
        root.replacePopups(root.popups.filter(entry => expiredIds.indexOf(entry.popupId) < 0));
        for (const popupId of expiredIds)
            root.popupExpired(popupId);
        return expiredIds.length;
    }
    function groupExpanded(groupKey: string): bool {
        return state.expandedGroups[groupKey] === true;
    }
    function hasActiveTimeout(): bool {
        return Object.values(state.timeoutStates).some(timeout => timeout.deadlineMs > 0);
    }
    function invokeAction(internalId: string, actionId: string): var {
        return root.service.invokeAction(internalId, actionId);
    }
    function pauseTimeout(internalId: string, reason: string, nowMs = Date.now()): bool {
        const index = root.popups.findIndex(entry => entry.popupId === internalId);
        if (index < 0 || reason.length === 0)
            return false;
        const current = root.popups[index];
        const timeout = state.timeoutStates[current.popupId];
        if (timeout === undefined || timeout.pauseReasons[reason] === true)
            return true;
        const reasons = Object.assign({}, timeout.pauseReasons);
        reasons[reason] = true;
        timeout.remainingMs = timeout.deadlineMs > 0 ? Math.max(1, timeout.deadlineMs - Number(nowMs)) : timeout.remainingMs;
        timeout.deadlineMs = 0;
        timeout.pauseReasons = reasons;
        timeoutTicker.running = root.hasActiveTimeout();
        return true;
    }
    function popupForId(internalId: string): var {
        const entry = root.popups.find(candidate => candidate.popupId === internalId) ?? null;
        if (entry === null)
            return null;
        const timeout = state.timeoutStates[entry.popupId] ?? {
            "remainingMs": 0,
            "deadlineMs": 0,
            "pauseReasons": ({})
        };
        return Object.freeze(Object.assign({}, entry, {
            "remainingMs": timeout.remainingMs,
            "deadlineMs": timeout.deadlineMs,
            "pauseReasons": Object.freeze(Object.assign({}, timeout.pauseReasons))
        }));
    }
    function popupsForMonitor(ownerMonitorId: string): var {
        void root.popupRevision;
        return Object.freeze(root.popups.filter(entry => entry.ownerMonitorId === ownerMonitorId));
    }
    function refreshHistory() {
        const rows = [];
        for (const group of root.service.groups) {
            const expanded = root.groupExpanded(group.groupKey);
            const dismissibleCount = group.records.filter(record => record.dismissible).length;
            rows.push(Object.freeze({
                "rowId": "group:" + group.groupKey,
                "kind": "group",
                "groupKey": group.groupKey,
                "appName": group.appName,
                "appIcon": group.appIcon,
                "count": group.count,
                "expanded": expanded,
                "dismissibleCount": dismissibleCount
            }));
            const visibleRecords = expanded ? group.records : group.records.slice(0, 1);
            for (const record of visibleRecords) {
                rows.push(Object.freeze({
                    "rowId": "record:" + record.internalId,
                    "kind": "record",
                    "groupKey": group.groupKey,
                    "record": record
                }));
            }
        }
        root.historyRowsAboutToChange();
        state.historyRows = Object.freeze(rows);
    }
    function removePopup(internalId: string): bool {
        const removed = root.popups.filter(entry => entry.popupId === internalId || entry.record.internalId === internalId);
        const next = root.popups.filter(entry => entry.popupId !== internalId && entry.record.internalId !== internalId);
        if (next.length === root.popups.length)
            return false;
        const timeoutStates = Object.assign({}, state.timeoutStates);
        for (const entry of removed)
            delete timeoutStates[entry.popupId];
        state.timeoutStates = timeoutStates;
        root.replacePopups(next);
        return true;
    }
    function replacePopups(popups) {
        state.popups = Object.freeze(popups);
        const visibleIds = popups.map(entry => entry.popupId);
        const timeoutStates = Object.assign({}, state.timeoutStates);
        for (const popupId of Object.keys(timeoutStates)) {
            if (visibleIds.indexOf(popupId) < 0)
                delete timeoutStates[popupId];
        }
        state.timeoutStates = timeoutStates;
        state.popupRevision += 1;
        timeoutTicker.running = root.hasActiveTimeout();
        root.popupQueueChanged();
    }
    function resolveOwnerMonitorId(): string {
        const monitor = root.monitorRegistry?.focusedWindowMonitor ?? root.monitorRegistry?.focusedMonitor ?? root.monitorRegistry?.fallbackMonitor ?? null;
        return String(monitor?.runtimeId ?? root.defaultOwnerMonitorId);
    }
    function resumeTimeout(internalId: string, reason: string, nowMs = Date.now()): bool {
        const index = root.popups.findIndex(entry => entry.popupId === internalId);
        if (index < 0 || reason.length === 0)
            return false;
        const current = root.popups[index];
        const timeout = state.timeoutStates[current.popupId];
        if (timeout === undefined || timeout.pauseReasons[reason] !== true)
            return true;
        const reasons = Object.assign({}, timeout.pauseReasons);
        delete reasons[reason];
        timeout.deadlineMs = Object.keys(reasons).length === 0 && timeout.remainingMs > 0 ? Number(nowMs) + timeout.remainingMs : 0;
        timeout.pauseReasons = reasons;
        timeoutTicker.running = root.hasActiveTimeout();
        return true;
    }
    function toggleGroup(groupKey: string): bool {
        const next = Object.assign({}, state.expandedGroups);
        next[groupKey] = next[groupKey] !== true;
        state.expandedGroups = next;
        root.refreshHistory();
        return next[groupKey];
    }

    Component.onCompleted: {
        root.service.notificationViewOpen = root.historyVisible;
        root.refreshHistory();
    }
    onHistoryVisibleChanged: {
        root.service.notificationViewOpen = root.historyVisible;
        if (root.historyVisible) {
            root.clearPresentation();
        } else if (Object.keys(state.expandedGroups).length > 0) {
            state.expandedGroups = ({});
            root.refreshHistory();
        }
    }

    Connections {
        function onNotificationClosed(internalId, reason) {
            void reason;
            root.removePopup(internalId);
            root.refreshHistory();
        }
        function onPopupRequested(record) {
            root.admitPopup(record);
        }
        function onRecordAdmitted(internalId, replaced) {
            void internalId;
            void replaced;
            root.refreshHistory();
        }

        target: root.service
    }
    Connections {
        function onRemoved(runtimeId) {
            const next = root.popups.filter(entry => entry.ownerMonitorId !== runtimeId);
            if (next.length !== root.popups.length)
                root.replacePopups(next);
        }

        ignoreUnknownSignals: true
        target: root.monitorRegistry
    }
    Timer {
        id: timeoutTicker

        interval: 100
        repeat: true
        running: false

        onTriggered: root.expireDue()
    }
    QtObject {
        id: state

        property var expandedGroups: ({})
        property var historyRows: Object.freeze([])
        property int popupRevision: 0
        property var popups: Object.freeze([])
        property var timeoutStates: ({})
    }
}
