pragma ComponentBehavior: Bound

import "../../features/feedback" as FeedbackFeatures
import "../../services/feedback" as FeedbackServices
import QtQuick
import Quickshell

ShellRoot {
    id: root

    property int actionCount: 0
    readonly property string artifactDirectory: String(Quickshell.env("FRANKEN_FEEDBACK_ARTIFACT_DIR") ?? "")

    function capture() {
        if (root.artifactDirectory.length === 0) {
            root.verifyInteractions();
            return;
        }
        fixtureFrame.grabToImage(result => {
            root.check(result.saveToFile(root.artifactDirectory + "/feedback-surfaces.png"), "feedback fixture screenshot is saved");
            root.verifyInteractions();
        });
    }
    function check(condition: bool, message: string) {
        if (!condition)
            root.fail(message);
    }
    function fail(message: string) {
        console.error("FAIL feedback-surfaces:", message);
        Qt.exit(1);
        throw new Error(message);
    }
    function run() {
        osds.show({
            "kind": "volume",
            "value": 0.63,
            "muted": false,
            "ownerMonitorId": "fixture-monitor",
            "timeoutMs": 60000
        });
        toasts.show({
            "key": "network",
            "severity": "success",
            "summary": "Fixture network connected",
            "detail": "A concise system state without application identity.",
            "ownerMonitorId": "fixture-monitor",
            "timeoutMs": 60000
        });
        toasts.show({
            "key": "generic",
            "severity": "failure",
            "summary": "Fixture operation needs attention",
            "detail": "This deliberately long localized-style detail verifies bounded wrapping while preserving explicit Retry and Open details actions. ".repeat(3),
            "actions": [
                {
                    "id": "retry",
                    "label": "Retry"
                },
                {
                    "id": "details",
                    "label": "Open details"
                }
            ],
            "actionsInlineAvailable": true,
            "ownerMonitorId": "fixture-monitor",
            "timeoutMs": 60000
        });
        Qt.callLater(() => Qt.callLater(root.verifyInitial));
    }
    function verifyInitial() {
        root.check(osdHost.visible && osdHost.currentRecord.kind === "volume", "OSD host exposes one current value without application history identity");
        root.check(toastHost.toastCount === 2, "toast host renders a bounded keyed stack independently from the OSD");
        root.check(toastHost.toastModel.every(record => record.appName === undefined && record.internalId === undefined), "system toasts expose no application-notification identity");
        const failure = toastHost.toastItemAt(0);
        root.check(failure !== null && failure.implicitHeight > 100, "long failure content wraps into bounded compact toast geometry");
        toastHost.focusInitial();
        root.check(toastHost.currentIndex === 0, "action-bearing failure toast supports explicit keyboard focus without arrival focus stealing");
        Qt.callLater(root.capture);
    }
    function verifyInteractions() {
        root.check(toasts.invokeAction("generic", "retry").accepted && root.actionCount === 1, "keyboard/pointer action request remains typed and service-owned");
        toasts.show({
            "key": "generic",
            "severity": "success",
            "summary": "Fixture retry completed",
            "ownerMonitorId": "fixture-monitor",
            "timeoutMs": 60000
        });
        root.check(toastHost.toastCount === 2 && toastHost.toastModel[0].severity === "success", "action result updates the same keyed toast instead of adding a card");
        osds.show({
            "kind": "brightness",
            "value": 0.41,
            "ownerMonitorId": "fixture-monitor",
            "timeoutMs": 60000
        });
        root.check(osdHost.currentRecord.kind === "brightness" && osdHost.children.length <= 1, "volume and brightness share one in-place host presentation");

        console.info("PASS feedback-surfaces: distinct OSD/toast geometry, bounded wrapping, action focus, keyed updates, and shared in-place OSD host");
        Qt.exit(0);
    }

    Component.onCompleted: Qt.callLater(root.run)

    FeedbackServices.OsdService {
        id: osds
    }
    FeedbackServices.ToastService {
        id: toasts

        onActionRequested: (key, actionId) => {
            void key;
            void actionId;
            root.actionCount += 1;
        }
    }
    FakeFeedbackTheme {
        id: theme
    }
    FloatingWindow {
        implicitHeight: 520
        implicitWidth: 760
        title: qsTr("Franken Shell feedback surface fixtures")
        visible: true

        Rectangle {
            id: fixtureFrame

            // Fake theme role groups cross a QObject boundary in the fixture.
            // qmllint disable missing-property
            anchors.fill: parent
            color: theme.colors.surfaceBase

            Row {
                anchors.fill: parent
                anchors.margins: 24
                spacing: 32

                Column {
                    spacing: 16
                    width: 320

                    Text {
                        color: theme.colors.textSecondary
                        font.family: theme.typography.fontFamily
                        font.pixelSize: theme.typography.fontSizeLabel
                        text: qsTr("DIRECT MANIPULATION")
                    }
                    FeedbackFeatures.OsdHost {
                        id: osdHost

                        ownerMonitorId: "fixture-monitor"
                        service: osds
                        theme: theme
                    }
                }
                Column {
                    spacing: 16
                    width: 360

                    Text {
                        color: theme.colors.textSecondary
                        font.family: theme.typography.fontFamily
                        font.pixelSize: theme.typography.fontSizeLabel
                        text: qsTr("SYSTEM CONFIGURATION")
                    }
                    FeedbackFeatures.ToastHost {
                        id: toastHost

                        height: 430
                        maximumHeight: height
                        ownerMonitorId: "fixture-monitor"
                        service: toasts
                        theme: theme
                        width: parent.width
                    }
                }
            }
            // qmllint enable missing-property
        }
    }
}
