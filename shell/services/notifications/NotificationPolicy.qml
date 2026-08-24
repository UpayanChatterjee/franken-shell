import QtQuick

QtObject {
    id: root

    property int burstWindowMs: 2500
    property int importantTimeoutMs: 9000
    property int maximumRequestedTimeoutMs: 120000
    property int minimumRequestedTimeoutMs: 1000
    property int routineTimeoutMs: 6000

    function classification(record): string {
        if (root.criticalBypassReason(record).length > 0)
            return "critical";
        return record?.urgency === "critical" ? "important" : "routine";
    }
    function criticalBypassReason(record): string {
        if (record?.trustedSource !== true)
            return "";
        const category = String(record?.category ?? "");
        const reasons = {
            "alarm": "alarm",
            "authentication": "authentication",
            "call.incoming": "incomingCall",
            "critical.battery": "criticalBattery",
            "critical.storage": "criticalStorage",
            "critical.temperature": "criticalTemperature",
            "pairing.confirmation": "pairingRequests",
            "permission.prompt": "permissionPrompt",
            "recording.failure": "recordingFailure",
            "security.prompt": "securityPrompt",
            "timer": "timer",
            "user-action.failure": "userActionFailure"
        };
        return String(reasons[category] ?? "");
    }
    function evaluate(record, context): var {
        const groupKey = root.groupKey(record);
        const classification = root.classification(record);
        const bypassReason = root.criticalBypassReason(record);
        let suppressionReason = "";
        if (context?.notificationViewOpen === true)
            suppressionReason = "notificationViewOpen";
        else if (context?.dnd === true && bypassReason.length === 0)
            suppressionReason = "dnd";
        else if (context?.fullscreen === true && bypassReason.length === 0)
            suppressionReason = "fullscreen";
        const popupEligible = suppressionReason.length === 0;
        const receivedAtMs = Number(record?.receivedAtMs ?? 0);
        const lastPopupAtMs = Number(context?.lastPopupAtMs ?? -1);
        const burstCoalesced = popupEligible && record?.replacesExisting !== true && groupKey === String(context?.lastPopupGroupKey ?? "") && lastPopupAtMs >= 0 && receivedAtMs >= lastPopupAtMs && receivedAtMs - lastPopupAtMs <= root.burstWindowMs;
        return Object.freeze({
            "historyEligible": record?.transient !== true,
            "popupEligible": popupEligible,
            "soundEligible": bypassReason === "incomingCall" || bypassReason === "alarm" || bypassReason === "timer",
            "classification": classification,
            "groupKey": groupKey,
            "timeoutMs": root.timeoutFor(record, classification),
            "suppressionReason": suppressionReason,
            "criticalBypassReason": bypassReason,
            "burstCoalesced": burstCoalesced
        });
    }
    function groupKey(record): string {
        const desktopEntry = root.safeKey(record?.desktopEntry);
        if (desktopEntry.length > 0)
            return "desktop:" + desktopEntry;
        const appName = root.safeKey(record?.appName);
        if (appName.length > 0)
            return "app:" + appName;
        return "notification:" + root.safeKey(record?.internalId ?? "unknown");
    }
    function safeKey(value): string {
        return String(value ?? "").trim().toLowerCase().replace(/\s+/g, "-").replace(/[^a-z0-9._:-]/g, "_").slice(0, 160);
    }
    function timeoutFor(record, classification: string): int {
        if (record?.resident === true || record?.progress?.active === true || classification === "critical")
            return 0;
        const requested = Number(record?.expireTimeoutMs ?? -1);
        if (requested === 0)
            return 0;
        if (Number.isFinite(requested) && requested > 0)
            return Math.max(root.minimumRequestedTimeoutMs, Math.min(root.maximumRequestedTimeoutMs, Math.round(requested)));
        return classification === "important" ? root.importantTimeoutMs : root.routineTimeoutMs;
    }
}
