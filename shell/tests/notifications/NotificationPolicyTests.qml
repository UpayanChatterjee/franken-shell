import "../../services/notifications" as NotificationServices
import QtQuick
import Quickshell

ShellRoot {
    id: root

    function check(condition: bool, message: string) {
        if (!condition)
            root.fail(message);
    }
    function context(overrides = ({})): var {
        return Object.assign({
            "dnd": false,
            "fullscreen": false,
            "notificationViewOpen": false,
            "lastPopupGroupKey": "",
            "lastPopupAtMs": -1
        }, overrides);
    }
    function fail(message: string) {
        console.error("FAIL notification-policy:", message);
        Qt.exit(1);
        throw new Error(message);
    }
    function record(overrides = ({})): var {
        return Object.assign({
            "internalId": "notification:session-1",
            "desktopEntry": "org.example.Chat",
            "appName": "Example Chat",
            "urgency": "normal",
            "category": "im.received",
            "trustedSource": false,
            "transient": false,
            "resident": false,
            "expireTimeoutMs": -1,
            "receivedAtMs": 10000,
            "replacesExisting": false,
            "progress": {
                "active": false
            }
        }, overrides);
    }
    function run() {
        let decision = policy.evaluate(root.record(), root.context());
        root.check(decision.historyEligible && decision.popupEligible && decision.classification === "routine" && decision.timeoutMs === 6000, "ordinary application notifications enter history and remain popup eligible by default");
        root.check(decision.groupKey === "desktop:org.example.chat", "desktop entry is the first provisional grouping key");

        decision = policy.evaluate(root.record({
            "desktopEntry": "",
            "appName": "Fallback App"
        }), root.context());
        root.check(decision.groupKey === "app:fallback-app", "application name is the deterministic second grouping key");
        decision = policy.evaluate(root.record({
            "desktopEntry": "",
            "appName": "",
            "internalId": "notification:session-9"
        }), root.context());
        root.check(decision.groupKey === "notification:notification:session-9", "missing identity remains isolated by stable internal ID");

        decision = policy.evaluate(root.record({
            "urgency": "critical"
        }), root.context({
            "dnd": true
        }));
        root.check(decision.classification === "important" && !decision.popupEligible && decision.suppressionReason === "dnd" && decision.criticalBypassReason === "", "untrusted critical urgency cannot bypass DND");

        const trustedAlarm = root.record({
            "category": "alarm",
            "trustedSource": true
        });
        decision = policy.evaluate(trustedAlarm, root.context({
            "dnd": true,
            "fullscreen": true
        }));
        root.check(decision.classification === "critical" && decision.popupEligible && decision.soundEligible && decision.timeoutMs === 0 && decision.criticalBypassReason === "alarm", "trusted alarm category conservatively bypasses DND and fullscreen");

        decision = policy.evaluate(root.record({
            "category": "critical.battery",
            "trustedSource": true
        }), root.context({
            "dnd": true
        }));
        root.check(decision.soundEligible && decision.criticalBypassReason === "criticalBattery", "reliably classified critical system alerts are sound eligible during DND");
        decision = policy.evaluate(root.record({
            "category": "authentication",
            "trustedSource": true
        }), root.context({
            "dnd": true
        }));
        root.check(decision.popupEligible && !decision.soundEligible, "interactive critical prompts may bypass visually without inventing a sound category");

        decision = policy.evaluate(trustedAlarm, root.context({
            "notificationViewOpen": true
        }));
        root.check(!decision.popupEligible && decision.suppressionReason === "notificationViewOpen", "open notification history suppresses even a duplicate critical popup");

        decision = policy.evaluate(root.record(), root.context({
            "fullscreen": true
        }));
        root.check(!decision.popupEligible && decision.suppressionReason === "fullscreen", "true fullscreen withholds ordinary popups");

        decision = policy.evaluate(root.record({
            "transient": true
        }), root.context());
        root.check(!decision.historyEligible && decision.popupEligible, "transient protocol records skip history without losing popup eligibility");

        decision = policy.evaluate(root.record({
            "expireTimeoutMs": 250
        }), root.context());
        root.check(decision.timeoutMs === 1000, "requested popup timeout is bounded to a safe minimum");
        decision = policy.evaluate(root.record({
            "progress": {
                "active": true
            }
        }), root.context());
        root.check(decision.timeoutMs === 0, "active progress does not time out in the provisional policy");

        const groupKey = policy.groupKey(root.record());
        decision = policy.evaluate(root.record({
            "receivedAtMs": 12000
        }), root.context({
            "lastPopupGroupKey": groupKey,
            "lastPopupAtMs": 10000
        }));
        root.check(decision.burstCoalesced, "same-group arrivals inside the candidate burst window coalesce presentation only");
        decision = policy.evaluate(root.record({
            "receivedAtMs": 13000
        }), root.context({
            "lastPopupGroupKey": groupKey,
            "lastPopupAtMs": 10000
        }));
        root.check(!decision.burstCoalesced, "arrivals outside the candidate burst window remain separate presentations");

        console.info("PASS notification-policy: grouping fallback, routine/important/critical classification, DND, fullscreen, drawer suppression, timeouts, conservative bypass, and burst coalescing");
        Qt.exit(0);
    }

    Component.onCompleted: Qt.callLater(root.run)

    NotificationServices.NotificationPolicy {
        id: policy
    }
}
