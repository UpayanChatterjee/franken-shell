import "../../features/controlcenter" as ControlCenter
import "../control_center_host" as HostFixtures
import QtQuick
import Quickshell

ShellRoot {
    id: root

    property int closeRequestCount: 0
    property int quickActionCount: 0
    property int sliderActionCount: 0
    property int step: 0

    function check(condition: bool, message: string) {
        if (!condition)
            root.fail(message);
    }
    function fail(message: string) {
        console.error("FAIL control-center-navigation-component:", message);
        Qt.exit(1);
        throw new Error(message);
    }
    function runStep() {
        switch (root.step) {
        case 0:
            content.focusInitial();
            root.step = 1;
            stepTimer.restart();
            break;
        case 1:
            {
                const initial = content.summary();
                root.check(initial.activePage === "main" && initial.activeTab === "notifications" && initial.focusedControlId === "quick.wifi", "initial keyboard focus enters the first quick control on Notifications");
                root.check(initial.quickControlCount === 5 && initial.visibleSliderCount === 2, "all injected placeholder controls and sliders are represented");
                root.check(content.quickControlState("wifi") === "unavailable", "unavailable state remains distinct");
                root.check(content.quickControlState("bluetooth") === "busy", "busy state remains distinct");
                root.check(content.quickControlState("nightLight") === "failed", "failed state remains distinct");
                root.check(content.requestQuickControlAction("wifi", "details", "pointer"), "pointer detail action opens Network even when the fixture backend is unavailable");
                root.check(content.activePage === "network", "Network detail replaces the main page");
                root.step = 2;
                stepTimer.restart();
                break;
            }
        case 2:
            {
                const nestedEscape = content.handleEscape();
                root.check(nestedEscape.handled && !nestedEscape.closeRequested && root.closeRequestCount === 0, "first Escape pops the nested page without closing the drawer");
                root.step = 3;
                stepTimer.restart();
                break;
            }
        case 3:
            root.check(content.activePage === "main" && content.activeTab === "notifications" && content.focusedControlId === "quick.wifi", "nested pop restores main Notifications and invoking focus");
            root.check(content.selectTab("volumeMixer", "pointer") && content.activeTab === "volumeMixer", "pointer tab selection replaces the active body");
            root.check(content.requestSliderStep("volume", 1, "keyboard") && root.sliderActionCount === 1, "keyboard slider adjustment is forwarded without closing");
            root.check(!content.requestQuickControlAction("bluetooth", "toggle", "keyboard") && root.quickActionCount === 1, "busy control blocks duplicate keyboard activation");
            root.check(content.requestQuickControlAction("nightLight", "toggle", "keyboard") && root.quickActionCount === 2, "failed placeholder remains independently actionable");
            placeholderModel.fixtureBrightnessAvailable = false;
            root.check(content.summary().visibleSliderCount === 1, "unavailable brightness is omitted and the slider section reflows");
            root.check(content.openPage("bluetooth", "quick.bluetooth", "pointer"), "pointer navigation opens Bluetooth detail");
            content.focus = false;
            content.resetSession();
            root.check(content.activePage === "main" && content.activeTab === "notifications" && content.focusedControlId === "", "close-cycle reset drops page, tab, and focus state");
            root.check(content.handleEscape().closeRequested && root.closeRequestCount === 1, "main-page Escape delegates exactly one drawer close");
            console.info("PASS control-center-navigation-component: injected states, pointer and keyboard actions, nested Escape, focus restoration, slider omission, and safe reset");
            Qt.exit(0);
            break;
        default:
            root.fail("unexpected fixture step");
        }
    }

    Component.onCompleted: stepTimer.start()

    ControlCenter.ControlCenterPlaceholderModel {
        id: placeholderModel
    }
    HostFixtures.FakeControlCenterTheme {
        id: fixtureTheme
    }
    FloatingWindow {
        color: "transparent"
        implicitHeight: 720
        implicitWidth: 400
        visible: true

        ControlCenter.ControlCenterContent {
            id: content

            anchors.fill: parent
            contentModel: placeholderModel
            focus: true
            theme: fixtureTheme

            onCloseRequested: root.closeRequestCount += 1
            onQuickControlActionRequested: (controlId, action, source) => {
                void controlId;
                void action;
                void source;
                root.quickActionCount += 1;
            }
            onSliderActionRequested: (sliderId, step, source) => {
                void sliderId;
                void step;
                void source;
                root.sliderActionCount += 1;
            }
        }
    }
    Timer {
        id: stepTimer

        interval: 20

        onTriggered: root.runStep()
    }
}
