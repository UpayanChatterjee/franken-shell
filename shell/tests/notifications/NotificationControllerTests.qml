import "../../features/notifications" as NotificationFeatures
import QtQuick
import Quickshell

ShellRoot {
    id: root

    property alias service: harness.service

    function action(id: string, label: string): var {
        return Object.freeze({
            "id": id,
            "label": label
        });
    }
    function check(condition: bool, message: string) {
        if (!condition)
            root.fail(message);
    }
    function fail(message: string) {
        console.error("FAIL notification-controller:", message);
        Qt.exit(1);
        throw new Error(message);
    }
    function notification(sourceId: string, overrides = ({})): var {
        return Object.freeze(Object.assign({
            "sourceId": sourceId,
            "protocolId": Number(sourceId.replace(/[^0-9]/g, "")) || 1,
            "appName": "Synthetic App",
            "appIcon": "",
            "desktopEntry": "org.example." + sourceId,
            "title": "Synthetic event",
            "body": "Fixture-only content",
            "urgency": "normal",
            "category": "im.received",
            "actions": [root.action("default", "Open")],
            "image": "",
            "progress": {
                "active": false
            },
            "resident": false,
            "transient": false,
            "trustedSource": false,
            "expireTimeoutMs": 1000,
            "receivedAtMs": Date.now()
        }, overrides));
    }
    function run() {
        runtime.setConnected(true);

        runtime.publish(root.notification("group-1", {
            "desktopEntry": "org.example.group",
            "receivedAtMs": 1000
        }));
        runtime.publish(root.notification("group-2", {
            "desktopEntry": "org.example.group",
            "receivedAtMs": 1200
        }));
        root.check(controller.popups.length === 1 && controller.popups[0].groupCount === 2 && controller.popups[0].record.internalId !== "", "same-group burst updates one popup presentation while preserving stable record identity");
        root.check(service.records.length === 2, "grouped popup presentation preserves both history records");

        for (let index = 3; index < 9; index += 1) {
            runtime.publish(root.notification("stack-" + index, {
                "receivedAtMs": 2000 + index
            }));
        }
        root.check(controller.popups.length === 4, "popup presentation remains bounded at the candidate maximum");

        const timeoutId = controller.popups[0].popupId;
        const now = Date.now();
        root.check(controller.pauseTimeout(timeoutId, "hover", now), "hover pause is accepted for a visible popup");
        controller.expireDue(now + 100000);
        root.check(controller.popupForId(timeoutId) !== null, "paused popup does not expire");
        const paused = controller.popupForId(timeoutId);
        controller.resumeTimeout(timeoutId, "hover", now + 100000);
        controller.expireDue(now + 100000 + paused.remainingMs - 1);
        root.check(controller.popupForId(timeoutId) !== null, "resumed popup preserves sane remaining time");
        controller.expireDue(now + 100000 + paused.remainingMs + 1);
        root.check(controller.popupForId(timeoutId) === null, "resumed popup expires after its remaining time");

        controller.historyVisible = true;
        const popupCountBeforeHistory = controller.popups.length;
        runtime.publish(root.notification("history-visible"));
        root.check(controller.popups.length === popupCountBeforeHistory && service.records.some(record => record.title === "Synthetic event"), "open notification history preserves receipt without duplicate popup presentation");
        controller.historyVisible = false;

        runtime.publish(root.notification("action-target"));
        const actionId = service.records[0].internalId;
        const response = controller.invokeAction(actionId, "default");
        root.check(response.accepted && runtime.lastAction.indexOf("action:default:") === 0 && service.records.find(record => record.internalId === actionId) === undefined, "keyboard/pointer action path routes through the normalized service and closes a non-resident record");

        runtime.publish(root.notification("group-dismiss-1", {
            "desktopEntry": "org.example.dismiss"
        }));
        runtime.publish(root.notification("group-dismiss-2", {
            "desktopEntry": "org.example.dismiss"
        }));
        const dismissGroupKey = service.records[0].groupKey;
        root.check(controller.dismissGroup(dismissGroupKey).accepted && service.records.every(record => record.groupKey !== dismissGroupKey), "group dismissal removes every dismissible record in one application group");

        runtime.publish(root.notification("retained-ordinary", {
            "desktopEntry": "org.example.retained"
        }));
        runtime.publish(root.notification("retained-progress", {
            "desktopEntry": "org.example.retained",
            "progress": {
                "active": true,
                "value": 42,
                "maximum": 100
            }
        }));
        const retainedGroupKey = service.records[0].groupKey;
        const retainedResponse = controller.dismissGroup(retainedGroupKey);
        root.check(retainedResponse.accepted && retainedResponse.dismissed === 1 && retainedResponse.retained === 1 && service.records.filter(record => record.groupKey === retainedGroupKey).length === 1, "group dismissal preserves a protocol/progress record while removing its ordinary sibling");
        const clearResponse = controller.clearHistory();
        root.check(clearResponse.accepted && clearResponse.retained === 1 && service.records.length === 1 && service.records[0].progress.active, "clear all preserves the active progress record without claiming protocol restoration");

        const retainedPopup = controller.popups.find(entry => entry.record.progress.active);
        monitorRegistry.focusedWindowMonitor = Object.freeze({
            "runtimeId": "second-monitor"
        });
        root.check(retainedPopup !== undefined && retainedPopup.ownerMonitorId === "fixture-monitor", "focus change does not move an already admitted popup between monitors");
        runtime.publish(root.notification("second-monitor-record"));
        root.check(controller.popups[0].ownerMonitorId === "second-monitor", "new popup admission captures the current focused-window monitor");
        monitorRegistry.removed("second-monitor");
        root.check(controller.popups.every(entry => entry.ownerMonitorId !== "second-monitor") && service.records.some(record => record.progress.active), "owner removal closes only presentation and preserves notification history");

        console.info("PASS notification-controller: bounded stack, timeout pause/resume, group replacement, action/dismissal, clear-all retention, and no-duplicate history rule");
        Qt.exit(0);
    }

    Component.onCompleted: Qt.callLater(root.run)

    FakeNotificationRuntime {
        id: runtime
    }
    NotificationHarness {
        id: harness

        runtime: runtime
    }
    QtObject {
        id: monitorRegistry

        property var fallbackMonitor: null
        property var focusedMonitor: null
        property var focusedWindowMonitor: Object.freeze({
            "runtimeId": "fixture-monitor"
        })

        signal removed(string runtimeId)
    }
    NotificationFeatures.NotificationController {
        id: controller

        defaultOwnerMonitorId: "fixture-monitor"
        monitorRegistry: monitorRegistry
        service: harness.service
    }
}
