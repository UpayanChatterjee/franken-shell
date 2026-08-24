import QtQuick
import Quickshell

ShellRoot {
    id: root

    readonly property string privateCanary: "PRIVATE_NOTIFICATION_CANARY_8F4A"
    property int soundRequestCount: 0

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
        console.error("FAIL notification-service:", message);
        Qt.exit(1);
        throw new Error(message);
    }
    function notification(sourceId: string, overrides = ({})): var {
        return Object.freeze(Object.assign({
            "sourceId": sourceId,
            "protocolId": Number(sourceId.replace(/[^0-9]/g, "")) || 1,
            "appName": "Fixture App",
            "appIcon": "image://icon/fixture",
            "desktopEntry": "org.example.Fixture",
            "title": "Synthetic title",
            "body": root.privateCanary,
            "urgency": "normal",
            "category": "im.received",
            "actions": [root.action("default", "Open")],
            "image": "",
            "progress": {
                "active": false
            },
            "resident": true,
            "transient": false,
            "trustedSource": false,
            "expireTimeoutMs": -1,
            "receivedAtMs": 1000
        }, overrides));
    }
    // Dynamic reload harnesses deliberately cross a QObject var boundary.
    // qmllint disable missing-property
    function run() {
        const service = harness.service;
        root.check(!service.available && service.records.length === 0 && service.ownershipState === "notAttempted", "non-owning absence is explicit and content-free");

        runtime.setConnected(true);
        root.check(service.available, "late notification runtime availability is accepted");

        runtime.publish(root.notification("native-1", {
            "actions": [root.action("default", "Open"), root.action("default", "Duplicate"), root.action("", "Missing ID"), root.action("reply", "")]
        }));
        root.check(service.records.length === 1 && service.groups.length === 1 && service.records[0].actions.length === 1, "notification content and malformed actions normalize into one history record");
        const firstId = service.records[0].internalId;
        let response = service.invokeAction(firstId, "default");
        root.check(response.accepted && runtime.lastAction === "action:default:native-1", "notification actions route through the runtime without logging content");

        runtime.publish(root.notification("native-1", {
            "title": "Replacement",
            "progress": {
                "active": true,
                "value": 35,
                "maximum": 100
            },
            "receivedAtMs": 1500
        }));
        root.check(service.records.length === 1 && service.records[0].internalId === firstId && service.records[0].progress.value === 35 && service.records[0].timeoutMs === 0, "replacement and progress update the stable record in place");

        runtime.publish(root.notification("native-2", {
            "receivedAtMs": 2000
        }));
        root.check(service.records.length === 2 && service.groups[0].count === 2 && service.records[0].burstCoalesced, "same-application burst coalescing preserves both history records");

        runtime.publish(root.notification("native-3", {
            "appName": "Second App",
            "desktopEntry": "org.example.Second",
            "receivedAtMs": 2200
        }));
        root.check(service.groups.length === 2, "application grouping preserves distinct normalized groups");
        const secondGroupId = service.records[0].internalId;

        runtime.publish(root.notification("native-3", {
            "transient": true,
            "receivedAtMs": 2300
        }));
        root.check(service.records.find(candidate => candidate.internalId === secondGroupId) === undefined, "transient replacement removes the prior history record instead of retaining stale content");

        service.setDnd(true, "fixture");
        const popupCountBeforeDnd = service.diagnosticsSummary().popupAdmissionCount;
        runtime.publish(root.notification("native-4", {
            "urgency": "critical",
            "receivedAtMs": 3000
        }));
        root.check(service.records[0].classification === "important" && service.records[0].suppressionReason === "dnd" && service.diagnosticsSummary().popupAdmissionCount === popupCountBeforeDnd, "untrusted critical urgency remains history-only during DND");

        runtime.publish(root.notification("native-5", {
            "category": "alarm",
            "trustedSource": true,
            "receivedAtMs": 3200
        }));
        root.check(service.records[0].classification === "critical" && service.records[0].popupEligible && root.soundRequestCount === 1, "trusted critical sound category emits one content-private sound request");

        service.setDnd(false, "fixture");
        service.fullscreen = true;
        runtime.publish(root.notification("native-6", {
            "receivedAtMs": 4000
        }));
        const fullscreenRecord = service.records[0];
        root.check(fullscreenRecord.suppressionReason === "fullscreen", "ordinary fullscreen arrival is retained without popup admission");
        service.fullscreen = false;
        root.check(!fullscreenRecord.popupEligible && service.records[0].internalId === fullscreenRecord.internalId, "fullscreen exit does not replay or rewrite a suppressed arrival");

        const diagnosticsText = JSON.stringify(service.diagnosticsSummary());
        root.check(diagnosticsText.indexOf(root.privateCanary) < 0 && diagnosticsText.indexOf("Synthetic title") < 0 && diagnosticsText.indexOf("Fixture App") < 0, "diagnostics contain counts and lifecycle only, never notification content or app identity");

        response = service.dismiss(firstId);
        root.check(response.accepted && service.records.find(candidate => candidate.internalId === firstId) === undefined, "explicit dismissal removes the tracked history record");

        harness.history.maximumItems = 3;
        for (let index = 10; index < 16; index += 1) {
            runtime.publish(root.notification("native-" + index, {
                "appName": "Retention Fixture",
                "desktopEntry": "org.example.Retention",
                "receivedAtMs": 5000 + index
            }));
        }
        root.check(service.records.length === 3 && harness.history.trimmedCount > 0, "in-memory history retention remains bounded under a notification storm");

        runtime.setConnected(false, "ownershipConflict");
        root.check(!service.available && service.connectionState === "ownershipConflict", "modeled duplicate ownership is explicit and non-operational");
        runtime.setConnected(true);

        reloadRuntime.setConnected(true);
        reloadRuntime.publish(root.notification("reload-native-1"));
        const firstGeneration = reloadHarness.createObject(root, {
            "runtime": reloadRuntime
        });
        reloadRuntime.reemitTracked();
        root.check(firstGeneration !== null && firstGeneration["service"].records.length === 1, "tracked notification is reconstructed once in a fresh generation");
        firstGeneration.destroy();
        const secondGeneration = reloadHarness.createObject(root, {
            "runtime": reloadRuntime
        });
        reloadRuntime.reemitTracked();
        root.check(secondGeneration !== null && secondGeneration["service"].records.length === 1, "reload re-emission does not duplicate history or ownership state");
        secondGeneration.destroy();

        console.info("PASS notification-service: normalization, actions, replacement, progress, grouping, bursts, DND, fullscreen, conservative bypass, close, retention, conflict, reload, and redaction");
        Qt.exit(0);
    }

    // qmllint enable missing-property

    Component.onCompleted: Qt.callLater(root.run)

    FakeNotificationRuntime {
        id: runtime
    }
    NotificationHarness {
        id: harness

        runtime: runtime
    }
    Connections {
        function onSoundRequested(record) {
            void record;
            root.soundRequestCount += 1;
        }

        target: harness.service
    }
    FakeNotificationRuntime {
        id: reloadRuntime
    }
    Component {
        id: reloadHarness

        NotificationHarness {
        }
    }
}
