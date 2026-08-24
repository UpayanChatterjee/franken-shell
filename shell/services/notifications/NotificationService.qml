import QtQuick
import Quickshell

Scope {
    id: root

    readonly property bool available: state.connectionState === "ready"
    readonly property string connectionState: state.connectionState
    readonly property bool dnd: state.dnd
    property bool fullscreen: false
    readonly property var groups: root.history.groups
    required property var history
    property bool notificationViewOpen: false
    readonly property string ownershipState: String(root.runtime?.ownershipState ?? "unavailable")
    required property var policy
    readonly property var records: root.history.records
    required property var runtime

    signal popupRequested(var record)
    signal recordAdmitted(string internalId, bool replaced)
    signal stateChanged

    function asArray(value): var {
        if (Array.isArray(value))
            return value;
        if (value?.values !== undefined)
            return value.values;
        if (typeof value?.toArray === "function")
            return value.toArray();
        return [];
    }
    function category(value): string {
        return String(value ?? "").trim().toLowerCase().replace(/[^a-z0-9._-]/g, "_").slice(0, 120);
    }
    function clearAll(): var {
        let dismissed = 0;
        let retained = 0;
        let failed = 0;
        for (const record of Array.from(root.records)) {
            if (!record.dismissible) {
                retained += 1;
                continue;
            }
            const response = root.dismiss(record.internalId);
            if (response.accepted)
                dismissed += 1;
            else
                failed += 1;
        }
        return Object.freeze({
            "accepted": failed === 0,
            "dismissed": dismissed,
            "retained": retained,
            "failed": failed,
            "errorCode": failed === 0 ? "" : "NOTIFICATION_CLEAR_PARTIAL"
        });
    }
    function diagnosticsSummary(): var {
        return Object.freeze({
            "available": root.available,
            "connectionState": root.connectionState,
            "ownershipState": root.ownershipState,
            "ownershipAttempted": root.runtime?.ownershipAttempted === true,
            "ownershipConfirmed": root.runtime?.ownershipConfirmed === true,
            "historyCount": root.records.length,
            "groupCount": root.groups.length,
            "dnd": root.dnd,
            "fullscreen": root.fullscreen,
            "receivedCount": state.receivedCount,
            "replacementCount": state.replacementCount,
            "popupAdmissionCount": state.popupAdmissionCount,
            "suppressedCount": state.suppressedCount,
            "burstCoalescedCount": state.burstCoalescedCount,
            "trimmedCount": root.history.trimmedCount,
            "lastError": state.lastError
        });
    }
    function dismiss(internalId: string): var {
        const sourceId = state.sourceIds[internalId];
        if (sourceId === undefined)
            return root.result(false, "NOTIFICATION_UNAVAILABLE");
        const response = root.runtime.dismiss(sourceId);
        if (response?.accepted !== true) {
            state.lastError = String(response?.errorCode ?? "NOTIFICATION_DISMISS_FAILED");
            root.stateChanged();
            return root.result(false, state.lastError);
        }
        root.handleClosed(sourceId, "dismissed");
        return root.result(true, "");
    }
    function dismissGroup(groupKey: string): var {
        const records = root.records.filter(record => record.groupKey === groupKey);
        let failed = 0;
        for (const record of records) {
            if (!root.dismiss(record.internalId).accepted)
                failed += 1;
        }
        return Object.freeze({
            "accepted": failed === 0,
            "dismissed": records.length - failed,
            "failed": failed,
            "errorCode": failed === 0 ? "" : "NOTIFICATION_GROUP_DISMISS_PARTIAL"
        });
    }
    function handleClosed(sourceId: string, reason: string) {
        void reason;
        const internalId = state.internalIds[sourceId];
        if (internalId === undefined)
            return;
        root.history.remove(internalId);
        delete state.internalIds[sourceId];
        delete state.sourceIds[internalId];
        root.stateChanged();
    }
    function handleConnectionChanged(connected: bool) {
        if (connected) {
            state.connectionState = "ready";
            state.lastError = "";
        } else {
            const runtimeState = String(root.runtime?.connectionState ?? "unavailable");
            state.connectionState = runtimeState === "ownershipConflict" ? "ownershipConflict" : state.receivedCount > 0 ? "reconnecting" : "unavailable";
        }
        root.stateChanged();
    }
    function invokeAction(internalId: string, actionId: string): var {
        const sourceId = state.sourceIds[internalId];
        if (sourceId === undefined)
            return root.result(false, "NOTIFICATION_UNAVAILABLE");
        const response = root.runtime.invokeAction(sourceId, actionId);
        if (response?.accepted !== true) {
            state.lastError = String(response?.errorCode ?? "NOTIFICATION_ACTION_FAILED");
            root.stateChanged();
            return root.result(false, state.lastError);
        }
        state.lastError = "";
        root.stateChanged();
        return root.result(true, "");
    }
    function normalizeActions(value): var {
        const actions = [];
        const used = {};
        for (const candidate of root.asArray(value)) {
            const id = root.safeIdentifier(candidate?.id ?? candidate?.identifier, 160);
            const label = root.safeText(candidate?.label ?? candidate?.text, 160);
            if (id.length === 0 || label.length === 0 || used[id] === true)
                continue;
            used[id] = true;
            actions.push(Object.freeze({
                "id": id,
                "label": label
            }));
            if (actions.length >= 24)
                break;
        }
        return Object.freeze(actions);
    }
    function normalizeProgress(value): var {
        const rawValue = Number(value?.value);
        const rawMaximum = Number(value?.maximum ?? 100);
        const indeterminate = value?.indeterminate === true;
        const active = indeterminate || Number.isFinite(rawValue) && rawValue >= 0;
        const maximum = Number.isFinite(rawMaximum) && rawMaximum > 0 ? rawMaximum : 100;
        return Object.freeze({
            "active": active,
            "indeterminate": indeterminate,
            "value": active && !indeterminate ? Math.max(0, Math.min(maximum, rawValue)) : 0,
            "maximum": maximum
        });
    }
    function receive(candidate) {
        if (!root.runtime?.connected)
            return;
        let sourceId = root.safeIdentifier(candidate?.sourceId ?? candidate?.protocolId, 200);
        if (sourceId.length === 0) {
            state.fallbackId += 1;
            sourceId = "notification-source-session-" + state.fallbackId;
        }
        let internalId = state.internalIds[sourceId];
        const replacesExisting = internalId !== undefined;
        if (!replacesExisting) {
            state.nextInternalId += 1;
            internalId = "notification:session-" + state.nextInternalId;
            state.internalIds[sourceId] = internalId;
            state.sourceIds[internalId] = sourceId;
        }
        const existing = root.history.record(internalId);
        const candidateTime = Number(candidate?.receivedAtMs);
        const receivedAtMs = Number.isFinite(candidateTime) && candidateTime >= 0 ? candidateTime : Date.now();
        const progress = root.normalizeProgress(candidate?.progress);
        const base = Object.freeze({
            "internalId": internalId,
            "protocolId": Number(candidate?.protocolId ?? -1),
            "appName": root.safeText(candidate?.appName, 240),
            "appIcon": root.safeIcon(candidate?.appIcon),
            "desktopEntry": root.safeIdentifier(candidate?.desktopEntry, 240),
            "title": root.safeText(candidate?.title ?? candidate?.summary, 512),
            "body": root.safeText(candidate?.body, 8192),
            "urgency": root.urgency(candidate?.urgency),
            "category": root.category(candidate?.category),
            "actions": root.normalizeActions(candidate?.actions),
            "image": root.safeIcon(candidate?.image),
            "progress": progress,
            "resident": candidate?.resident === true,
            "transient": candidate?.transient === true,
            "trustedSource": candidate?.trustedSource === true,
            "expireTimeoutMs": Number(candidate?.expireTimeoutMs ?? -1),
            "receivedAtMs": receivedAtMs,
            "createdAtMs": existing?.createdAtMs ?? receivedAtMs,
            "replacesExisting": replacesExisting
        });
        const decision = root.policy.evaluate(base, {
            "dnd": root.dnd,
            "fullscreen": root.fullscreen,
            "notificationViewOpen": root.notificationViewOpen,
            "lastPopupGroupKey": state.lastPopupGroupKey,
            "lastPopupAtMs": state.lastPopupAtMs
        });
        const record = Object.freeze({
            "internalId": base.internalId,
            "protocolId": base.protocolId,
            "appName": base.appName,
            "appIcon": base.appIcon,
            "desktopEntry": base.desktopEntry,
            "title": base.title,
            "body": base.body,
            "urgency": base.urgency,
            "classification": decision.classification,
            "category": base.category,
            "actions": base.actions,
            "image": base.image,
            "progress": base.progress,
            "resident": base.resident,
            "transient": base.transient,
            "createdAtMs": base.createdAtMs,
            "updatedAtMs": base.receivedAtMs,
            "groupKey": decision.groupKey,
            "historyEligible": decision.historyEligible,
            "popupEligible": decision.popupEligible,
            "soundEligible": decision.soundEligible,
            "suppressionReason": decision.suppressionReason,
            "criticalBypassReason": decision.criticalBypassReason,
            "timeoutMs": decision.timeoutMs,
            "burstCoalesced": decision.burstCoalesced,
            "dismissible": !base.resident && !base.progress.active
        });
        state.receivedCount += 1;
        if (replacesExisting)
            state.replacementCount += 1;
        if (decision.historyEligible)
            root.history.upsert(record);
        else if (replacesExisting)
            root.history.remove(internalId);
        if (decision.popupEligible) {
            state.popupAdmissionCount += 1;
            state.lastPopupGroupKey = decision.groupKey;
            state.lastPopupAtMs = receivedAtMs;
            if (decision.burstCoalesced)
                state.burstCoalescedCount += 1;
            root.popupRequested(record);
        } else {
            state.suppressedCount += 1;
        }
        root.recordAdmitted(internalId, replacesExisting);
        root.stateChanged();
    }
    function result(accepted: bool, errorCode: string): var {
        return Object.freeze({
            "accepted": accepted,
            "errorCode": errorCode
        });
    }
    function safeIcon(value): string {
        const icon = String(value ?? "");
        return icon.length <= 2048 && icon.indexOf("\n") < 0 && icon.indexOf("\r") < 0 ? icon : "";
    }
    function safeIdentifier(value, maximumLength: int): string {
        return root.safeText(value, maximumLength).replace(/[^A-Za-z0-9._:@-]/g, "_");
    }
    function safeText(value, maximumLength: int): string {
        return String(value ?? "").replace(/[\u0000-\u001f\u007f]/g, " ").replace(/\s+/g, " ").trim().slice(0, maximumLength);
    }
    function setDnd(value: bool, origin: string): var {
        void origin;
        if (state.dnd === value)
            return root.result(true, "");
        state.dnd = value;
        root.stateChanged();
        return root.result(true, "");
    }
    function urgency(value): string {
        const candidate = String(value ?? "normal").toLowerCase();
        return ["low", "normal", "critical"].indexOf(candidate) >= 0 ? candidate : "normal";
    }

    Component.onCompleted: root.handleConnectionChanged(root.runtime?.connected === true)
    onRuntimeChanged: root.handleConnectionChanged(root.runtime?.connected === true)

    QtObject {
        id: state

        property int burstCoalescedCount: 0
        property string connectionState: "unavailable"
        property bool dnd: false
        property int fallbackId: 0
        property var internalIds: ({})
        property string lastError: ""
        property int lastPopupAtMs: -1
        property string lastPopupGroupKey: ""
        property int nextInternalId: 0
        property int popupAdmissionCount: 0
        property int receivedCount: 0
        property int replacementCount: 0
        property var sourceIds: ({})
        property int suppressedCount: 0
    }
    Connections {
        function onActionFailed(errorCode) {
            state.lastError = String(errorCode || "NOTIFICATION_ACTION_FAILED");
            root.stateChanged();
        }
        function onConnectionChanged(connected) {
            root.handleConnectionChanged(connected);
        }
        function onNotificationClosed(sourceId, reason) {
            root.handleClosed(sourceId, reason);
        }
        function onNotificationReceived(record) {
            root.receive(record);
        }

        ignoreUnknownSignals: true
        target: root.runtime
    }
}
