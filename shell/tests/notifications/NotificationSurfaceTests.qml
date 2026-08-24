pragma ComponentBehavior: Bound

import "../../features/notifications" as NotificationFeatures
import QtQuick
import Quickshell

ShellRoot {
    id: root

    readonly property string artifactDirectory: String(Quickshell.env("FRANKEN_NOTIFICATION_ARTIFACT_DIR") ?? "")
    property string preservedRowId: ""
    property alias service: harness.service

    function action(id: string, label: string): var {
        return Object.freeze({
            "id": id,
            "label": label
        });
    }
    function captureFixturesThenScroll() {
        if (root.artifactDirectory.length === 0) {
            root.prepareScrollTest();
            return;
        }
        popupFrame.grabToImage(popupResult => {
            root.check(popupResult.saveToFile(root.artifactDirectory + "/popup-stack.png"), "synthetic popup fixture screenshot is saved");
            historyFrame.grabToImage(historyResult => {
                root.check(historyResult.saveToFile(root.artifactDirectory + "/grouped-history.png"), "synthetic grouped-history fixture screenshot is saved");
                root.prepareScrollTest();
            });
        });
    }
    function captureStableAnchor() {
        root.check(history.contentY > 0, "history fixture is reading away from the insertion edge before stability check");
        root.preservedRowId = history.firstVisibleRowId();
        root.check(root.preservedRowId.length > 0, "history exposes a stable visible-row anchor before insertion");
        runtime.publish(root.notification("new-at-top", {
            "appName": "Newest Fixture",
            "receivedAtMs": 3000
        }));
        Qt.callLater(() => Qt.callLater(root.verifyStableAnchor));
    }
    function check(condition: bool, message: string) {
        if (!condition)
            root.fail(message);
    }
    function fail(message: string) {
        console.error("FAIL notification-surfaces:", message);
        Qt.exit(1);
        throw new Error(message);
    }
    function notification(sourceId: string, overrides = ({})): var {
        return Object.freeze(Object.assign({
            "sourceId": sourceId,
            "protocolId": Number(sourceId.replace(/[^0-9]/g, "")) || 1,
            "appName": "Synthetic Application",
            "appIcon": "",
            "desktopEntry": "org.example." + sourceId,
            "title": "Synthetic notification",
            "body": "Fixture-only body text",
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
            "expireTimeoutMs": 60000,
            "receivedAtMs": Date.now()
        }, overrides));
    }
    function populate() {
        runtime.setConnected(true);
        for (let index = 0; index < 10; index += 1) {
            runtime.publish(root.notification("background-" + index, {
                "appName": "Background Fixture " + index,
                "receivedAtMs": 1000 + index
            }));
        }
        runtime.publish(root.notification("action", {
            "appName": "Action Fixture",
            "actions": [root.action("open", "Open"), root.action("reply", "Reply"), root.action("mute", "Mute thread")],
            "receivedAtMs": 2000
        }));
        runtime.publish(root.notification("malformed", {
            "appName": "Fallback Fixture",
            "appIcon": "::not-an-icon::",
            "receivedAtMs": 2100
        }));
        runtime.publish(root.notification("progress", {
            "appName": "Progress Fixture",
            "progress": {
                "active": true,
                "value": 64,
                "maximum": 100
            },
            "receivedAtMs": 2200
        }));
        const longBody = "This is synthetic fixture text used to exercise bounded notification layout and expansion. ".repeat(14);
        runtime.publish(root.notification("group-long-1", {
            "appName": "Grouped Fixture",
            "desktopEntry": "org.example.grouped",
            "body": longBody,
            "receivedAtMs": 2300
        }));
        runtime.publish(root.notification("group-long-2", {
            "appName": "Grouped Fixture",
            "desktopEntry": "org.example.grouped",
            "body": longBody,
            "receivedAtMs": 2400
        }));
    }
    function prepareScrollTest() {
        history.positionRow(10);
        Qt.callLater(root.captureStableAnchor);
    }
    function run() {
        root.populate();
        Qt.callLater(() => Qt.callLater(root.verifyInitial));
    }
    function verifyInitial() {
        root.check(popupHost.popupCount === 4, "representative notification burst remains bounded to four visible popups");
        const grouped = controller.popups.find(entry => entry.record.groupKey === "desktop:org.example.grouped");
        root.check(grouped !== undefined && grouped.groupCount === 2, "same-application burst is represented by one grouped popup");
        root.check(history.itemCount > 20 && history.scrollOverflow, "grouped history uses a bounded reusable scrolling viewport");

        popupHost.focusIndex(1);
        history.focusRow(1);
        root.check(popupHost.currentPopupId.length > 0 && history.currentRowId.length > 0, "popup and history rows are reachable through deterministic keyboard traversal");

        const malformedIndex = popupHost.popupModel.findIndex(entry => entry.record.appName === "Fallback Fixture");
        const malformedCard = popupHost.popupItemAt(malformedIndex);
        root.check(malformedCard !== null && malformedCard.usesIconFallback, "malformed application icon falls back without hiding notification content");
        const groupedIndex = popupHost.popupModel.findIndex(entry => entry.record.appName === "Grouped Fixture");
        const groupedCard = popupHost.popupItemAt(groupedIndex);
        root.check(groupedCard !== null && groupedCard.bodyTruncated, "long popup body remains bounded with an explicit expansion path");

        const collapsedCount = controller.historyRows.length;
        controller.toggleGroup("desktop:org.example.grouped");
        root.check(controller.historyRows.length === collapsedCount + 1, "expanding a group reveals each preserved notification record");

        Qt.callLater(root.captureFixturesThenScroll);
    }
    function verifyInteractions() {
        const swipeCard = popupHost.popupItemAt(0);
        const beforeSwipe = popupHost.popupCount;
        swipeCard.swipeOffset = swipeCard.width * 0.5;
        swipeCard.finishSwipe();
        root.check(popupHost.popupCount === beforeSwipe - 1, "rightward swipe and explicit dismissal share the normalized close path");

        const clearResponse = controller.clearHistory();
        root.check(clearResponse.accepted && clearResponse.retained === 1 && service.records.length === 1 && service.records[0].progress.active, "clear all removes ordinary records while preserving active progress");

        console.info("PASS notification-surfaces: popup bounds, grouping, long content, icon fallback, keyboard traversal, swipe dismissal, scroll stability, screenshots, and clear all");
        Qt.exit(0);
    }
    function verifyStableAnchor() {
        root.check(history.firstVisibleRowId() === root.preservedRowId, "new history insertion preserves the row being read away from the top");
        root.verifyInteractions();
    }

    Component.onCompleted: Qt.callLater(root.run)

    FakeNotificationRuntime {
        id: runtime
    }
    NotificationHarness {
        id: harness

        runtime: runtime
    }
    NotificationFeatures.NotificationController {
        id: controller

        defaultOwnerMonitorId: "fixture-monitor"
        service: harness.service
    }
    FakeNotificationTheme {
        id: theme
    }
    FloatingWindow {
        implicitHeight: 720
        implicitWidth: 860
        title: qsTr("Franken Shell notification surface fixtures")
        visible: true

        Rectangle {
            anchors.fill: parent
            color: "#111318"

            Row {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 20

                // Fake theme role groups cross a QObject boundary in the fixture.
                // qmllint disable missing-property
                Rectangle {
                    id: popupFrame

                    color: "transparent"
                    height: parent.height
                    width: 380

                    NotificationFeatures.NotificationPopupHost {
                        id: popupHost

                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        controller: controller
                        maximumHeight: parent.height
                        ownerMonitorId: "fixture-monitor"
                        theme: theme
                    }
                }
                Rectangle {
                    id: historyFrame

                    color: theme.colors.surfaceRaised
                    height: parent.height
                    radius: theme.radius.radiusMedium
                    width: 420

                    NotificationFeatures.NotificationHistoryView {
                        id: history

                        anchors.fill: parent
                        anchors.margins: theme.spacing.space3
                        controller: controller
                        theme: theme
                    }
                }
                // qmllint enable missing-property
            }
        }
    }
}
