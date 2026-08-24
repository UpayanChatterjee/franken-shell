import "../../core" as Core
import "../../features/feedback" as FeedbackFeatures
import "../../services/feedback" as FeedbackServices
import "../../services/notifications" as NotificationServices
import QtQuick
import Quickshell

ShellRoot {
    id: root

    property int actionRequestCount: 0

    function check(condition: bool, message: string) {
        if (!condition)
            root.fail(message);
    }
    function fail(message: string) {
        console.error("FAIL feedback-services:", message);
        Qt.exit(1);
        throw new Error(message);
    }
    function run() {
        const firstVolume = feedback.showVolume(0.2, false, {
            "explicitMonitorId": "monitor-a",
            "origin": "keyboard"
        });
        root.check(firstVolume.accepted && osds.records.length === 1 && osds.records[0].value === 0.2, "volume OSD admits on the explicit monitor");
        for (let index = 1; index <= 50; index += 1) {
            feedback.showVolume(index / 50, false, {
                "explicitMonitorId": "monitor-b",
                "origin": "keyboard"
            });
        }
        root.check(osds.records.length === 1 && osds.records[0].value === 1 && osds.records[0].ownerMonitorId === "monitor-a", "rapid volume updates replace in place without migrating the active owner");
        feedback.showVolume(0.4, true, {});
        root.check(osds.records[0].muted && osds.records[0].value === 0.4, "mute state remains explicit independently of the value");
        root.check(!feedback.showBrightness(0.5, false, {}).accepted && osds.records.length === 1, "unavailable brightness produces no misleading OSD");
        root.check(feedback.showBrightness(2, true, {
            "explicitMonitorId": "monitor-b"
        }).accepted && osds.records.find(record => record.kind === "brightness").value === 1, "brightness uses the affected monitor hint and clamps invalid display values");

        feedback.dnd = true;
        feedback.fullscreen = true;
        const firstToast = feedback.showToast({
            "key": "network",
            "severity": "success",
            "summary": "Synthetic network state",
            "userTriggered": true
        }, {
            "explicitMonitorId": "monitor-a"
        });
        const firstToastId = toasts.records[0].instanceId;
        const replacement = feedback.showToast({
            "key": "network",
            "severity": "failure",
            "summary": "Synthetic network failure",
            "actions": [
                {
                    "id": "retry",
                    "label": "Retry"
                }
            ],
            "actionsInlineAvailable": true,
            "userTriggered": true
        }, {
            "explicitMonitorId": "monitor-b"
        });
        root.check(firstToast.accepted && replacement.accepted && toasts.records.length === 1 && toasts.records[0].instanceId === firstToastId && toasts.records[0].ownerMonitorId === "monitor-a", "same-key toast replaces in place during DND/fullscreen without moving its owner");
        root.check(!feedback.showToast({
            "key": "bluetooth",
            "severity": "success",
            "summary": "Passive state",
            "userTriggered": false
        }, {}).accepted, "passive background state cannot exploit the DND/fullscreen feedback bypass");
        for (const key of ["bluetooth", "nightLight", "idleInhibitor", "audioOutput", "power", "generic"]) {
            root.check(feedback.showToast({
                "key": key,
                "severity": key === "generic" ? "failure" : "success",
                "summary": "Synthetic " + key,
                "userTriggered": true
            }, {}).accepted, "documented toast key is admitted: " + key);
        }
        root.check(toasts.records.length === 3, "unrelated toast categories remain bounded to the host maximum");

        const timeoutNow = Date.now();
        toasts.show({
            "key": "network",
            "severity": "failure",
            "summary": "Synthetic paused failure",
            "ownerMonitorId": "monitor-a",
            "timeoutMs": 1000
        }, timeoutNow);
        root.check(toasts.pause("network", "focus", timeoutNow + 100), "failure toast timeout pauses for explicit focus");
        const pausedInstanceId = toasts.records.find(record => record.key === "network").instanceId;
        toasts.show({
            "key": "network",
            "severity": "failure",
            "summary": "Synthetic paused replacement",
            "ownerMonitorId": "monitor-b",
            "timeoutMs": 1000
        }, timeoutNow + 200);
        toasts.expireDue(timeoutNow + 10000);
        root.check(toasts.records.some(record => record.key === "network" && record.instanceId === pausedInstanceId && record.ownerMonitorId === "monitor-a"), "keyed replacement preserves instance, owner, and active focus pause");
        root.check(toasts.resume("network", "focus", timeoutNow + 10000), "failure toast timeout resumes");
        toasts.expireDue(timeoutNow + 10999);
        root.check(toasts.records.some(record => record.key === "network"), "resumed replacement receives its full restarted timeout");
        toasts.expireDue(timeoutNow + 11001);
        root.check(!toasts.records.some(record => record.key === "network"), "resumed replacement expires after its restarted timeout");

        toasts.show({
            "key": "generic",
            "severity": "failure",
            "summary": "Synthetic action",
            "ownerMonitorId": "monitor-a",
            "actions": [
                {
                    "id": "details",
                    "label": "Open details"
                }
            ],
            "actionsInlineAvailable": true
        });
        root.check(feedback.invokeToastAction("generic", "details").accepted && root.actionRequestCount === 1, "toast action routes as a typed request without performing the backend mutation");
        root.check(!feedback.publishTrackChange().accepted && osds.records.every(record => record.kind !== "track"), "track changes never create OSD or toast feedback");

        const major = coordinator.openMajor("fixture.controlCenter", {
            "origin": "keyboard",
            "takesFocus": true,
            "monitorId": "monitor-a",
            "originControlId": "fixture.origin"
        });
        feedback.showVolume(0.7, false, {});
        feedback.showToast({
            "key": "generic",
            "severity": "success",
            "summary": "Synthetic configuration applied",
            "userTriggered": true
        }, {});
        root.check(major.accepted && coordinator.activeMajorId === "fixture.controlCenter", "focus-neutral feedback does not compete with or close a major surface");

        soundSource.soundRequested({
            "soundEligible": true,
            "criticalBypassReason": "incomingCall"
        });
        soundSource.soundRequested({
            "soundEligible": true,
            "criticalBypassReason": "criticalBattery"
        });
        soundSource.soundRequested({
            "soundEligible": false,
            "criticalBypassReason": ""
        });
        root.check(soundRuntime.events.join(",") === "call,critical" && soundService.playedCount === 2, "only reliable call/alarm/timer/critical sound events reach the fixed runtime");

        monitorRegistry.removed("monitor-a", {});
        root.check(osds.records.every(record => record.ownerMonitorId !== "monitor-a") && toasts.records.every(record => record.ownerMonitorId !== "monitor-a"), "owner removal dismisses transient presentation without touching backend state");

        console.info("PASS feedback-services: keyed replacement, timeout pause, rapid updates, DND/fullscreen policy, unavailable brightness, mute, track suppression, action routing, ownership, and conservative sounds");
        Qt.exit(0);
    }

    Component.onCompleted: Qt.callLater(root.run)

    QtObject {
        id: monitorRegistry

        readonly property var fallbackMonitor: monitorA
        readonly property var focusedMonitor: monitorA
        readonly property var focusedWindowMonitor: monitorA
        property QtObject monitorA: QtObject {
            property bool connected: true
            property string runtimeId: "monitor-a"
        }
        property QtObject monitorB: QtObject {
            property bool connected: true
            property string runtimeId: "monitor-b"
        }
        property int revision: 1

        signal removed(string runtimeId, var lastState)

        function monitorByRuntimeId(runtimeId: string): var {
            return runtimeId === "monitor-a" ? monitorA : runtimeId === "monitor-b" ? monitorB : null;
        }
    }
    Core.SurfaceCoordinator {
        id: coordinator

        monitorRegistry: monitorRegistry
    }
    FeedbackServices.OsdService {
        id: osds
    }
    FeedbackServices.ToastService {
        id: toasts

        onActionRequested: (key, actionId) => {
            void key;
            void actionId;
            root.actionRequestCount += 1;
        }
    }
    FeedbackFeatures.FeedbackController {
        id: feedback

        osdService: osds
        surfaceCoordinator: coordinator
        toastService: toasts
    }
    QtObject {
        id: soundSource

        signal soundRequested(var record)
    }
    QtObject {
        id: soundRuntime

        property var events: []

        function play(eventId: string): var {
            const next = soundRuntime.events.slice();
            next.push(eventId);
            soundRuntime.events = next;
            return Object.freeze({
                "accepted": true,
                "errorCode": ""
            });
        }
    }
    NotificationServices.NotificationSoundPolicy {
        id: soundPolicy
    }
    NotificationServices.NotificationSoundService {
        id: soundService

        notificationService: soundSource
        policy: soundPolicy
        runtime: soundRuntime
    }
}
